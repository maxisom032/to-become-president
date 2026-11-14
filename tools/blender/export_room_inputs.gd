extends SceneTree

const Room := preload("res://game/offices/office_scene.gd")
const Baked := preload("res://game/offices/baked_interior.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room := Room.new()
	room.set_meta("export_for_bake",true)
	root.add_child(room)
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/lighting-input"))
	for rank_value in 6:
		room.build(rank_value)
		var snapshot := Node3D.new()
		root.add_child(snapshot)
		for source_root in Baked.roots(room):
			var meshes: Array = [source_root] if source_root is MeshInstance3D else source_root.find_children("*","MeshInstance3D",true,false)
			for source in meshes:
				var mesh := MeshInstance3D.new()
				mesh.mesh=source.mesh
				mesh.transform=source.global_transform
				for i in source.mesh.get_surface_count():
					var original: Material = source.get_active_material(i)
					var mat := StandardMaterial3D.new()
					if original is ShaderMaterial:
						mat.albedo_color=original.get_shader_parameter("tint")
						mat.resource_name="painted-"+str(original.get_shader_parameter("surface_kind"))+"-wallpaper"+str(original.get_shader_parameter("wallpaper"))
					else:
						mat=original.duplicate()
					mesh.set_surface_override_material(i,mat)
				snapshot.add_child(mesh)
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var error := doc.append_from_scene(snapshot,state)
		if error==OK:
			error=doc.write_to_filesystem(state,"res://build/lighting-input/room-%02d.glb" % (rank_value+1))
		if error!=OK:
			push_error("Room export failed "+str(error))
			quit(1)
			return
		print("Exported room ",rank_value+1)
		snapshot.queue_free()
		await process_frame
	var snapshots := {}
	for index in 6:
		snapshots[str(index+1)]=FileAccess.get_sha256("res://build/lighting-input/room-%02d.glb" % (index+1))
	var stamp := FileAccess.open("res://build/lighting-input/source-state.json",FileAccess.WRITE)
	stamp.store_string(JSON.stringify({"source_hashes":Baked.source_state(),"snapshot_hashes":snapshots},"\t"))
	stamp.close()
	room.queue_free()
	await process_frame
	quit(0)
