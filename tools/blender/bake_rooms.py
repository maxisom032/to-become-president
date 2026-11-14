"""Bake actual Godot room geometry in Cycles; keep animated props outside the bake.
blender --background --python tools/blender/bake_rooms.py -- PROJECT_ROOT [FIRST] [LAST]
"""
import bpy
import math
import json
import sys
from pathlib import Path
from mathutils import Vector

args=sys.argv[sys.argv.index('--')+1:]
ROOT=Path(args[0]).resolve()
FIRST=int(args[1]) if len(args)>1 else 1
LAST=int(args[2]) if len(args)>2 else 6
OUT=ROOT/'game/offices/assets/baked-rooms'
OUT.mkdir(exist_ok=True,parents=True)
source_state=json.loads((ROOT/'build/lighting-input/source-state.json').read_text(encoding='utf-8'))
if FIRST!=1 or LAST!=6:
    manifest_path=OUT/'manifest.json'
    if not manifest_path.exists():raise RuntimeError('Full six-room bake required before a partial update')
    previous=json.loads(manifest_path.read_text(encoding='utf-8'))
    if previous.get('source_hashes',{}).get('tools/blender/bake_rooms.py')!=source_state['source_hashes']['tools/blender/bake_rooms.py']:
        raise RuntimeError('Bake settings changed: rebuild all six rooms')
    for other in range(1,7):
        if not FIRST<=other<=LAST and previous.get('snapshot_hashes',{}).get(str(other))!=source_state.get('snapshot_hashes',{}).get(str(other)):
            raise RuntimeError(f'Room {other} geometry changed: rebuild all six rooms')

HEIGHTS=[3.2,3.3,3.6,3.9,4.2,4.5]
BACKS=[-3.4,-3.6,-3.9,-4.2,-4.6,-5]

def xyz(p): return (p[0],-p[2],p[1])

def area(name,position,target,power,size,color):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;data.color=color
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    obj.location=xyz(position)
    obj.rotation_euler=(Vector(xyz(target))-obj.location).to_track_quat('-Z','Y').to_euler()

def prepare_material(mat):
    if not mat.use_nodes: return
    shader=mat.node_tree.nodes.get('Principled BSDF')
    if not shader: return
    shader.inputs['Metallic'].default_value=0
    shader.inputs['Roughness'].default_value=.85
    if not mat.name.startswith('painted-'): return
    nodes=mat.node_tree.nodes;links=mat.node_tree.links
    base=tuple(shader.inputs['Base Color'].default_value)
    geo=nodes.new('ShaderNodeNewGeometry')
    noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=28
    noise.inputs['Detail'].default_value=2
    links.new(geo.outputs['Position'],noise.inputs['Vector'])
    wood_kind=mat.name.startswith('painted-1-') or mat.name.startswith('painted-2-')
    if wood_kind:
        mapping=nodes.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY'
        mapping.inputs[1].default_value=(1,28,4)
        links.new(geo.outputs['Position'],mapping.inputs[0]);links.new(mapping.outputs[0],noise.inputs['Vector'])
        noise.inputs['Scale'].default_value=2.4
    ramp=nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color=tuple(v*(.67 if wood_kind else .88) for v in base[:3])+(1,)
    ramp.color_ramp.elements[1].color=tuple(min(1,v*(1.3 if wood_kind else 1.08)) for v in base[:3])+(1,)
    links.new(noise.outputs['Fac'],ramp.inputs['Fac'])
    links.new(ramp.outputs['Color'],shader.inputs['Base Color'])
    if '-wallpaper' in mat.name and mat.name.split('-wallpaper')[1][0]!='0':
        wave=nodes.new('ShaderNodeTexWave');wave.bands_direction='X';wave.inputs['Scale'].default_value=2.8
        links.new(geo.outputs['Position'],wave.inputs['Vector'])
        stripe=nodes.new('ShaderNodeMixRGB');stripe.blend_type='MULTIPLY';stripe.inputs[0].default_value=.12
        links.new(ramp.outputs['Color'],stripe.inputs[1]);links.new(wave.outputs['Color'],stripe.inputs[2])
        links.new(stripe.outputs[0],shader.inputs['Base Color'])

for rank in range(FIRST,LAST+1):
    print('BAKE ROOM START',rank,flush=True)
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for m in list(bpy.data.materials):
        if m.users==0:bpy.data.materials.remove(m)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/f'build/lighting-input/room-{rank:02}.glb'))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in meshes:
        for slot in o.material_slots:
            if slot.material:prepare_material(slot.material)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join()
    obj=bpy.context.object;obj.name=f'room-{rank:02}'
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    original_uv_name=obj.data.uv_layers.active.name if obj.data.uv_layers.active else ''
    obj.data.uv_layers.new(name='BakeAtlas')
    obj.data.uv_layers.active_index=len(obj.data.uv_layers)-1
    if original_uv_name:obj.data.uv_layers[original_uv_name].active_render=True
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.006)
    bpy.ops.object.mode_set(mode='OBJECT')
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=64
    scene.cycles.max_bounces=5
    scene.cycles.diffuse_bounces=4
    scene.render.bake.margin=12
    scene.render.bake.use_pass_direct=True;scene.render.bake.use_pass_indirect=True
    scene.render.bake.use_pass_diffuse=True;scene.render.bake.use_pass_glossy=False
    scene.render.bake.use_pass_transmission=False
    scene.world.use_nodes=True
    scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.85,.9,1,1)
    scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.12
    try:
        prefs=bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type='OPTIX';prefs.get_devices()
        found=False
        for device in prefs.devices:
            device.use=device.type=='OPTIX';found=found or device.use
        scene.cycles.device='GPU' if found else 'CPU'
    except Exception as error:
        print('GPU fallback',error,flush=True);scene.cycles.device='CPU'
    height=HEIGHTS[rank-1];back=BACKS[rank-1]
    area('Soft desk-side key',(-1.5,2.9,2.7),(0,1.0,-1.3),350,2.0,(1,.79,.53))
    area('Broad front fill',(1.0,2.8,3.3),(0,1.4,back),130,2.5,(1,.88,.71))
    area('Pendant diffuse',(0,height-.55,back+1.7),(0,0,back+1.7),120,.8,(1,.76,.42))
    if rank>=5:
        area('Window daylight',(-2.3,2.1,back+.8),(0,1,-1.2),160,1.8,(.77,.87,1))
    image=bpy.data.images.new(f'room-{rank:02}-light-color',width=2048,height=2048,alpha=False,float_buffer=False)
    for slot in obj.material_slots:
        mat=slot.material
        if mat:
            tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;mat.node_tree.nodes.active=tex
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
    bpy.ops.object.bake(type='COMBINED',uv_layer='BakeAtlas')
    # Retain source UVs during baking (Kenney palette textures), then make the
    # baked atlas the sole UV set used by the exported one-material room.
    if original_uv_name:
        original_uv=obj.data.uv_layers[original_uv_name]
        bake_uv=obj.data.uv_layers['BakeAtlas']
        coordinates=[tuple(v.uv) for v in bake_uv.data]
        for target,coord in zip(original_uv.data,coordinates):target.uv=coord
        obj.data.uv_layers.remove(obj.data.uv_layers['BakeAtlas'])
        obj.data.uv_layers.active_index=0
        obj.data.uv_layers[0].active_render=True
    image.filepath_raw=str(OUT/f'room-{rank:02}-light-color.png');image.file_format='PNG';image.save()
    # One material/one texture for the baked static room. Lights are not exported.
    mat=bpy.data.materials.new(f'Baked room {rank:02}');mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF');shader.inputs['Roughness'].default_value=1
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
    mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    obj.data.materials.clear();obj.data.materials.append(mat)
    for face in obj.data.polygons:face.material_index=0
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'room-{rank:02}.gltf'),export_format='GLTF_SEPARATE',use_selection=True,export_yup=True,export_animations=False,export_lights=False,export_cameras=False)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'tools/blender/room-{rank:02}.blend'))
    print('BAKE ROOM COMPLETE',rank,len(obj.data.polygons),'faces',flush=True)

(OUT/'README.md').write_text('''# Запечённые помещения

Созданы в Blender Cycles из фактической статичной геометрии Godot. Запечены базовый цвет, прямой и рассеянный свет, мягкие тени (Combined без зеркального вклада), 64 samples, по одной 2048px карте на комнату. Дверь, открывающаяся папка и настольные Blender-модели в этот световой атлас не входят. Экспорт glTF, отображение статичного интерьера unshaded, поэтому свет не умножается в движке повторно.

Источник: tools/blender/export_room_inputs.gd → build/lighting-input/, затем tools/blender/bake_rooms.py. Редактируемые источники tools/blender/room-01.blend…room-06.blend. Исходные CC0-ассеты Kenney сохраняют свои лицензии, собственная геометрия и карты принадлежат проекту. После изменения статичной геометрии или света нужно повторное запекание; при удалении экспортов есть процедурный вариант помещения. Физический мобильный FPS отдельно не проверялся.
''',encoding='utf-8')

source_state=json.loads((ROOT/'build/lighting-input/source-state.json').read_text(encoding='utf-8'))
source_state.update({'bake':'Cycles Combined diffuse direct + indirect, 64 samples, 2048px', 'rooms':6, 'source':'Actual Godot geometry + original geometry + CC0 Kenney/Poly Haven'})
(OUT/'manifest.json').write_text(json.dumps(source_state,indent=2),encoding='utf-8')
