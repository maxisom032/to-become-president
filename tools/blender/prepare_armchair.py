"""Prepare the CC0 Poly Haven chair for the game's stylized, baked rooms."""
import bpy
import sys
import math
from pathlib import Path

ROOT=Path(sys.argv[sys.argv.index('--')+1]).resolve()
asset=sys.argv[sys.argv.index('--')+2] if len(sys.argv)>sys.argv.index('--')+2 else 'armchair'
source=next((ROOT/'tools/blender/external'/asset).rglob('*.blend'))
bpy.ops.wm.open_mainfile(filepath=str(source),use_scripts=False)
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
print('CHAIR OBJECTS',[(o.name,len(o.data.polygons)) for o in meshes],flush=True)
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes:obj.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.object.join();obj=bpy.context.object;obj.name='PolyHaven'+asset.title()
bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
for mod in list(obj.modifiers):
 if mod.type=='SUBSURF':obj.modifiers.remove(mod)
 else:
  try:bpy.ops.object.modifier_apply(modifier=mod.name)
  except RuntimeError:pass
# Keep scanned carving and upholstery silhouette while replacing photoreal wear
# with restrained, game-style materials. Existing UVs and normals are retained.
for mat in obj.data.materials:
 if not mat:continue
 name=mat.name.lower()
 print('CHAIR MATERIAL',mat.name,flush=True)
 mat.use_nodes=True
 shader=mat.node_tree.nodes.get('Principled BSDF')
 if not shader:continue
 for link in list(mat.node_tree.links):
  if link.to_node==shader:mat.node_tree.links.remove(link)
 is_fabric=any(w in name for w in ['cloth','fabric','seat','leather','cushion'])
 # The original asset can use a single textured material, in which case a
 # softened diffuse map is retained rather than losing the upholstery split.
 shader.inputs['Roughness'].default_value=.7 if is_fabric else .42
 shader.inputs['Metallic'].default_value=0
 if len(obj.data.materials)>1:
  shader.inputs['Base Color'].default_value=(.08,.15,.10,1) if is_fabric else (.19,.095,.04,1)
 else:
  images=[n for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image and any(w in n.image.name.lower() for w in ['diff','color','albedo'])]
  if images:mat.node_tree.links.new(images[0].outputs['Color'],shader.inputs['Base Color'])
  else:shader.inputs['Base Color'].default_value=(.22,.17,.1,1)
out=ROOT/'game/offices/assets/polyhaven';out.mkdir(exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(out/(asset+'.gltf')),export_format='GLTF_SEPARATE',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
print('CHAIR READY',len(obj.data.polygons),flush=True)
