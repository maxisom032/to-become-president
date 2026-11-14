extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func folder_signature(hinge: Node3D) -> String:
	var result := ""
	for node in hinge.get_parent().find_children("*","MeshInstance3D",true,false):
		result+=str(node.transform)+str(node.mesh.get_aabb())
		var mat: Material = node.material_override
		result+=str(mat.get_shader_parameter("tint")) if mat is ShaderMaterial else str(mat.albedo_color)
	return result

func projected_door(room: Node3D) -> Rect2:
	var bounds: AABB = room.door_bounds
	var corner: Vector2 = room.camera.unproject_position(bounds.position)
	var opposite: Vector2 = room.camera.unproject_position(bounds.position+bounds.size)
	return Rect2(corner,opposite-corner).abs()

func run() -> void:
	root.size=Vector2i(393,852)
	var ui = load("res://game/offices/workplace.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	await process_frame
	var baseline := Rect2()
	var folder := ""
	var camera_home := Transform3D.IDENTITY
	var total_before := 0
	var total_after := 0
	for rank_value in 6:
		ui.select_rank(rank_value)
		await process_frame
		await physics_frame
		var room: Node3D = ui.office
		var door := projected_door(room)
		if rank_value==0:
			baseline=door
			folder=folder_signature(room.folder_hinge)
			camera_home=room.camera.transform
		check(room.camera.transform.is_equal_approx(camera_home),"Desk camera changed at rank %d" % rank_value)
		check(absf(door.get_center().y-baseline.get_center().y)<32.0,"Door moved too far vertically")
		check(absf(door.get_center().x-baseline.get_center().x)<2.0,"Door shifted horizontally")
		check(absf(door.size.x/baseline.size.x-1)<0.03,"Door screen width changed")
		check(absf(door.size.y/baseline.size.y-1)<0.06,"Door screen height changed")
		check(Rect2(Vector2.ZERO,Vector2(ui.scene_viewport.size)).encloses(door),"Door does not fit scene")
		check(room.door_hinge.find_children("*","Label3D",true,false).is_empty(),"Door must have no text")
		check(folder_signature(room.folder_hinge)==folder,"Folder appearance changes with rank")
		check(room.windows.size()==(0 if rank_value<4 else 1),"Unexpected window count")
		if rank_value>=4:
			check(room.windows[0].get_meta("corner",false),"Late window is not corner glazing")
		var phone: Node3D = room.get_node("DeskTelephone")
		check(phone.get_meta("finish_level")==rank_value,"Wrong phone variant")
		check(room.get_node("PencilHolder").get_meta("finish_level")==rank_value,"Wrong pencil holder variant")
		check(room.has_node("BakedRoom"),"Missing or stale baked room")
		check(room.get_node("BankerLamp").get_meta("finish_level")==rank_value,"Wrong lamp variant")
		for id in ["folder","phone","agenda","door"]:
			check(room.pick_object(room.screen_position(id))==id,"Unreachable interaction: "+id)
		var before: int = room.get_meta("static_meshes_before")
		var after: int = room.get_meta("static_meshes_after")
		check(after<float(before)*0.5,"Static batching did not reduce room draw calls")
		total_before+=before
		total_after+=after
		room.animate_door(true)
		await create_timer(0.4).timeout
		check(room.door_hinge.rotation.y < -1.4,"Door no longer opens")
		print("Rank %d door: %s; static meshes %d -> %d" % [rank_value+1,door,before,after])
	print("Career interiors: %d checks, %d failures. Static meshes across six rooms: %d -> %d" % [checks,failures,total_before,total_after])
	ui.queue_free()
	await process_frame
	quit(1 if failures else 0)
