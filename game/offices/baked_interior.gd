extends RefCounted

const SOURCES := ["game/offices/office_scene.gd","game/offices/career_interior.gd","game/offices/interior_accents.gd","game/offices/desk_details.gd","game/offices/ready_props.gd","game/offices/beveled_mesh.gd","game/offices/office_catalog.gd","tools/blender/export_room_inputs.gd","tools/blender/bake_rooms.py"]

static func asset_hashes(result: Dictionary, directory: String) -> void:
	for file in DirAccess.get_files_at("res://"+directory):
		if file.get_extension().to_lower() in ["glb","gltf","bin","png","jpg","jpeg","exr"]:
			var path := directory+"/"+file
			result[path]=FileAccess.get_sha256("res://"+path)
	for folder in DirAccess.get_directories_at("res://"+directory):
		asset_hashes(result,directory+"/"+folder)

static func source_state() -> Dictionary:
	var result := {}
	for path in SOURCES:
		result[path]=FileAccess.get_sha256("res://"+path)
	asset_hashes(result,"game/offices/assets/kenney")
	asset_hashes(result,"game/offices/assets/polyhaven")
	return result

static func is_current() -> bool:
	var path := "res://game/offices/assets/baked-rooms/manifest.json"
	if not FileAccess.file_exists(path):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	# Exported builds may contain compiled scripts and imported-only assets. The
	# source hash gate belongs to authoring; exported packages use the validated bake.
	return data is Dictionary and (not OS.has_feature("editor") or data.get("source_hashes",{})==source_state())

static func roots(room: Node3D) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in room.get_children():
		if not child is Node3D or child is Camera3D or child is Light3D or child is CollisionObject3D:
			continue
		if child==room.door_hinge or child.is_ancestor_of(room.folder_hinge):
			continue
		if child.has_meta("finish_level") or child.has_meta("dynamic_detail") or child.get_script()!=null or child.name=="CornerGlazing":
			continue
		if child is MeshInstance3D or not child.find_children("*","MeshInstance3D",true,false).is_empty():
			result.append(child)
	return result

static func apply(room: Node3D) -> void:
	if room.has_meta("export_for_bake"):
		return
	if not is_current():
		return
	var path := "res://game/offices/assets/baked-rooms/room-%02d.gltf" % (room.room_index+1)
	if not ResourceLoader.exists(path):
		return
	var packed: PackedScene = load(path)
	var model: Node3D = packed.instantiate()
	model.name="BakedRoom"
	for child in roots(room):
		room.remove_child(child)
		child.queue_free()
	room.add_child(model)
	# The room atlas already includes diffuse lighting. Only specular props and
	# moving objects keep using the realtime lights.
	var meshes: Array = [model] if model is MeshInstance3D else model.find_children("*","MeshInstance3D",true,false)
	for mesh in meshes:
		for i in mesh.mesh.get_surface_count():
			var mat: StandardMaterial3D = mesh.mesh.surface_get_material(i).duplicate()
			mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh.set_surface_override_material(i,mat)
