"""Blender background authoring: game-sized meshes with a shared baked color/AO atlas.

Run: blender --background --python tools/blender/build_desk_assets.py -- PROJECT_ROOT
The .blend is the editable source; exported glTFs share one 2048px PNG.
"""
import bpy
import bmesh
import math
import sys
import json
import numpy as np
from pathlib import Path
from mathutils import Vector

ROOT = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
OUT = ROOT / 'game/offices/assets/crafted'
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 2048
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.device = 'CPU'
scene.render.bake.margin = 10
scene.world.use_nodes = True
scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value = (1, 1, 1, 1)
parts = []
assets = []
materials = {}

def xyz(p):
    return (p[0], -p[2], p[1])

def rgba(value):
    c = tuple(int(value[i:i+2], 16)/255 for i in (1,3,5))
    return tuple(v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in c)+(1,)

def material(name, color, metal=0, rough=.38):
    if name in materials:
        return materials[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = rgba(color)
    shader.inputs['Metallic'].default_value = metal
    shader.inputs['Roughness'].default_value = rough
    mat.diffuse_color = rgba(color)
    materials[name] = mat
    return mat

gold = material('Satin brass', '#b99852', .28, .44)
ivory = material('Warm ivory keys', '#d6caa7', .02, .34)
dark = material('Cord rubber', '#26352d', 0, .63)
paper = material('Label ivory', '#d9cba5', 0, .8)

def finish(obj, mat, bevel=0):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if bevel:
        mod = obj.modifiers.new('Rounded manufactured edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.set_sharp_from_angle(angle=math.radians(55))
    for poly in obj.data.polygons:
        poly.use_smooth = True
    mod = obj.modifiers.new('Face weighted normals', 'WEIGHTED_NORMAL')
    mod.keep_sharp = True
    mod.weight = 40
    bpy.ops.object.modifier_apply(modifier=mod.name)
    parts.append(obj)
    obj.select_set(False)
    return obj

def box(at, dims, mat, bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(at))
    obj = bpy.context.object
    obj.dimensions = (dims[0], dims[2], dims[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, mat, min(bevel, min(dims)*.42))

def cylinder(at, radius, height, mat, vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=height, location=xyz(at))
    return finish(bpy.context.object, mat, min(.003, height*.2))

def tube(points, radius, mat, resolution=3):
    curve = bpy.data.curves.new('Swept curved detail', 'CURVE')
    curve.dimensions = '3D'
    curve.resolution_u = resolution
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    curve.use_fill_caps = True
    spline = curve.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for p, at in zip(spline.bezier_points, points):
        p.co = xyz(at)
        p.handle_left_type = 'AUTO'
        p.handle_right_type = 'AUTO'
    obj = bpy.data.objects.new('Curved detail', curve)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    return finish(obj, mat)

def lathe(profile, mat, segments=40):
    verts = [(r*math.cos(i*math.tau/segments), r*math.sin(i*math.tau/segments), z)
             for z,r in profile for i in range(segments)]
    faces = []
    for j in range(len(profile)-1):
        for i in range(segments):
            a=j*segments+i; b=j*segments+(i+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces += [tuple(reversed(range(segments))), tuple(range((len(profile)-1)*segments,len(profile)*segments))]
    mesh = bpy.data.meshes.new('Turned profile')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new('Turned profile', mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj,mat)

def start_asset():
    parts.clear()
    bpy.ops.object.select_all(action='DESELECT')

def end_asset(name, rank):
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name=name
    # Move vertices, keeping asset origin at its placement pivot.
    offset=Vector((rank*1.5, {'phone':0,'lamp':2,'holder':4}[name.split('-')[0]], 0))
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    obj.location+=offset
    assets.append((obj,offset))
    obj.select_set(False)

phone_colors=['#dfd4b7','#e3d8bd','#e7dcc3','#e3d5b8','#e8dec7','#eee3cb']
lamp_colors=['#63734c','#3f6746','#245c42','#174d3d','#204634','#5a302c']

for rank in range(6):
    start_asset()
    body=material(f'Phone enamel {rank}',phone_colors[rank],0,.48)
    # One wedge: high at cradle, low at player-facing front.
    verts=[xyz((x,h,z)) for h in [-.035,0] for z in [-.19,.19] for x in [-.215,.215]]
    for i in range(4,8):
        x,y,z=verts[i]; verts[i]=(x,y,.105+.16*y)
    faces=[(0,2,3,1),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5),(4,5,7,6)]
    mesh=bpy.data.meshes.new('Single sloping telephone casing')
    mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new('Telephone casing',mesh);bpy.context.collection.objects.link(obj)
    finish(obj,body,.02)
    box((0,-.037,0),(.40,.012,.36),dark,.006)
    for x in [-.153,.153]:
        box((x,.145,-.128),(.085,.039,.096),body,.014)
        box((x,.166,-.128),(.069,.01,.078),dark,.004)
        box((x,.200,-.128),(.113,.073,.118),body,.03)
    tube([(-.153,.202,-.128),(-.103,.224,-.128),(0,.234,-.128),(.103,.224,-.128),(.153,.202,-.128)],.032,body,5)
    inset=box((0,.101,.067),(.251,.008,.22),material('Keypad inset','#b7b19c',0,.6),.008)
    inset.rotation_euler.x=math.atan(.16)
    for row in range(4):
        for col in range(3):
            x=(col-1)*.073; z=-.01+row*.048
            key=box((x,.119-.16*z,z),(.054,.018,.034),ivory,.006)
            key.rotation_euler.x=math.atan(.16)
            marking=box((x,.129-.16*z,z),(.012,.0015,.003),dark,.0004)
            marking.rotation_euler.x=math.atan(.16)
    if rank>=3:
        box((0,.119,-.061),(.17,.006,.025),gold,.004)
        box((0,.123,-.061),(.145,.003,.016),material('Smoked green display','#9dad8d',.05,.3),.002)
        for i in range(4):
            box((-.05+i*.033,.125,-.061),(.018,.001,.0025),dark,.0005)
    cord=[]
    for i in range(100):
        t=i/99
        cord.append((-.235+math.cos(t*math.tau*14)*.008,.04+math.sin(t*math.tau*14)*.008,-.13+t*.3))
    tube([(-.21,.20,-.128),(-.24,.15,-.135),(-.235,.04,-.13)],.004,dark,3)
    tube(cord,.0035,dark,1)
    end_asset(f'phone-{rank+1:02}',rank)

    start_asset()
    shade_mat=material(f'Lamp fired enamel {rank}',lamp_colors[rank],.03,.44)
    lathe([(0,.10),(.008,.125),(.018,.13),(.027,.12),(.038,.092),(.048,.075),(.053,.07)],gold if rank>0 else material('Aged brass','#96804d',.55,.36))
    if rank>=2:
        cylinder((0,.047,0),.077,.015,material('Green stone','#254a36',.07,.31))
    lathe([(.05,.027),(.064,.025),(.08,.014),(.29,.014),(.303,.023),(.32,.023),(.33,.015),(.36,.015)],gold,24)
    if rank<4:
        width=[.175,.195,.22,.235][rank]
        # Supporting yoke joins both sides of the substantial enamel shade.
        tube([(-width-.010,.405,0),(-width-.010,.32,0),(0,.30,0),(width+.010,.32,0),(width+.010,.405,0)],.007,gold)
        verts=[];faces=[]
        for x in [-width,width]:
            for i in range(25):
                a=math.pi*i/24
                verts.append(xyz((x,.39+math.sin(a)*.13,math.cos(a)*.13)))
        for i in range(24): faces.append((i,i+1,26+i,25+i))
        faces.extend([tuple(reversed(range(25))),tuple(range(25,50))])
        mesh=bpy.data.meshes.new('Curved enamel shell');mesh.from_pydata(verts,[],faces);mesh.update()
        obj=bpy.data.objects.new('Curved enamel shade',mesh);bpy.context.collection.objects.link(obj)
        finish(obj,shade_mat,.003)
        box((0,.389,0),(width*2,.012,.235),ivory,.005)
        if rank>=2:
            for x in [-width-.004,width+.004]:
                tube([(x,.39,.129),(x,.48,.09),(x,.52,0),(x,.48,-.09),(x,.39,-.129)],.004,gold)
    else:
        fabric=material(f'Woven warm shade {rank}',['#cdb686','#ddd1b0'][rank-4],0,.8)
        if rank==4:
            profile=[(.305,.18),(.315,.18),(.475,.102),(.485,.10),(.485,.094),(.475,.096),(.315,.174),(.305,.174)]
        else:
            profile=[(.30,.19),(.315,.194),(.34,.18),(.46,.117),(.49,.11),(.49,.104),(.46,.111),(.34,.174),(.315,.188),(.30,.184)]
        lathe(profile,fabric,48)
        for y,r in [(profile[0][0],profile[0][1]),(profile[3][0],profile[3][1])]:
            lathe([(y-.003,r),(y+.003,r),(y+.003,r-.005),(y-.003,r-.005),(y-.003,r)],gold,48)
        cylinder((0,.508,0),.015,.020,gold,24)
    tube([(.12,.025,.02),(.105,.06,.03),(.10,.10,.035)],.0025,gold,2)
    end_asset(f'lamp-{rank+1:02}',rank)

    start_asset()
    cup=material(f'Pen holder finish {rank}',lamp_colors[rank] if rank<5 else '#443128',.04,.4)
    profile=[(0,.06),(.007,.071),(.017,.068),(.19,.068),(.205,.066),(.205,.057),(.025,.057),(.018,.05)]
    lathe(profile,cup,40)
    if rank>=1:
        for y in [.016,.2]:
            lathe([(y-.004,.061),(y-.004,.070),(y+.004,.070),(y+.004,.061),(y-.004,.061)],gold,40)
    if rank>=3:
        for i in range(16):
            a=math.tau*i/16
            cylinder((math.cos(a)*.067,.11,math.sin(a)*.067),.002,.16,gold,8)
    end_asset(f'holder-{rank+1:02}',rank)

# UVs are packed jointly, producing one atlas shared by all eighteen game assets.
for obj,_ in assets: obj.select_set(True)
bpy.context.view_layer.objects.active=assets[0][0]
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.008)
bpy.ops.object.mode_set(mode='OBJECT')
color=bpy.data.images.new('desk-color-source',width=SIZE,height=SIZE,alpha=False)
ao=bpy.data.images.new('desk-occlusion',width=SIZE,height=SIZE,alpha=False)
ao.colorspace_settings.name='Non-Color'
old_outputs=[]
for mat in materials.values():
    nodes=mat.node_tree.nodes; links=mat.node_tree.links
    shader=nodes.get('Principled BSDF'); output=nodes.get('Material Output')
    emit=nodes.new('ShaderNodeEmission')
    emit.inputs['Color'].default_value=shader.inputs['Base Color'].default_value
    links.new(emit.outputs[0],output.inputs['Surface'])
    tex=nodes.new('ShaderNodeTexImage');tex.image=color;nodes.active=tex
    old_outputs.append((mat,shader,output,emit,tex))
bpy.ops.object.bake(type='EMIT')
for mat,shader,output,emit,tex in old_outputs:
    tex.image=ao
    mat.node_tree.nodes.active=tex
bpy.ops.object.bake(type='AO')
base=np.empty(SIZE*SIZE*4,dtype=np.float32);occ=np.empty_like(base)
color.pixels.foreach_get(base);ao.pixels.foreach_get(occ)
base=base.reshape(-1,4);occ=occ.reshape(-1,4)
base[:,:3]*=.88+.12*np.clip(occ[:,:3],0,1)
base[:,3]=1
atlas=bpy.data.images.new('desk-baked-color-ao',width=SIZE,height=SIZE,alpha=False)
atlas.pixels.foreach_set(base.reshape(-1))
atlas.filepath_raw=str(OUT/'desk-baked-color-ao.png');atlas.file_format='PNG';atlas.save()
ao.filepath_raw=str(OUT/'desk-ao-source.png');ao.file_format='PNG';ao.save()
for mat,shader,output,emit,tex in old_outputs:
    mat.node_tree.links.new(shader.outputs[0],output.inputs['Surface'])
    tex.image=atlas
    mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    mat.node_tree.nodes.remove(emit)

bpy.ops.object.select_all(action='DESELECT')
report=[]
for obj,offset in assets:
    obj.location-=offset
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/(obj.name+'.gltf')),export_format='GLTF_SEPARATE',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
    report.append({'name':obj.name,'triangles':triangles,'atlas':'desk-baked-color-ao.png','source':'Original Blender geometry, project-owned','bake':'Cycles 24 samples, color + AO','uv':'joint non-overlapping smart projection'})
    obj.select_set(False)
    obj.location+=offset

(OUT/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'tools/blender/desk-assets.blend'))
print('DESK ASSETS COMPLETE',len(report),'assets,',sum(r['triangles'] for r in report),'triangles total')
