extends SceneTree

var failures := 0
var checks := 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for frame in 4:
		await process_frame
	await physics_frame
func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 800)
	var ui = load("res://game/offices/workplace.tscn").instantiate()
	root.add_child(ui)
	await settle()
	if not ui.has_method("apply_layout"):
		check(false, "Responsive native-resolution presentation not implemented")
		quit(1)
		return
	var home: Transform3D = ui.office.camera.transform
	var fov: float = ui.office.camera.fov
	var views := {}
	var last_window_area := 0.0
	for rank_value in 6:
		ui.select_rank(rank_value)
		await settle()
		check(ui.office.camera.transform.is_equal_approx(home), "Camera turns relative to desk at rank %d" % rank_value)
		check(is_equal_approx(ui.office.camera.fov, fov), "Desk zoom changes with rank")
		var vista: String = ui.office.windows[0].view_path
		check(ui.office.windows.size()==1,"Exactly one window required")
		var window_area: float = ui.office.windows[0].width*ui.office.windows[0].height
		check(window_area>last_window_area,"Window must grow with rank")
		last_window_area=window_area
		views[vista] = true
		check(FileAccess.file_exists(vista), "Missing painted view")
	check(views.size() == 6, "Every career workplace needs its own exterior")
	for dims in [Vector2i(360,640), Vector2i(414,896), Vector2i(1280,720), Vector2i(1920,1080), Vector2i(2560,1080)]:
		root.size = dims
		await settle()
		check(ui.scene_viewport.size == Vector2i(ui.scene_container.size), "3D viewport is not native resolution at %s: %s" % [dims,ui.scene_viewport.size])
		for rank_value in 6:
			ui.select_rank(rank_value)
			await settle()
			for id in ["folder","phone","agenda","door"]:
				var point: Vector2 = ui.office.screen_position(id)
				check(Rect2(Vector2(8,8),Vector2(ui.scene_viewport.size)-Vector2(16,16)).has_point(point), "%s clipped at %s rank %d" % [id,dims,rank_value])
				check(ui.office.pick_object(point) == id, "Ray selection failed after resize")
			for point in ui.office.desk_markers.values():
				var projected: Vector2 = ui.office.camera.unproject_position(point)
				check(Rect2(Vector2(5,5),Vector2(ui.scene_viewport.size)-Vector2(10,10)).has_point(projected), "Desk prop cropped at %s rank %d" % [dims,rank_value])
		ui.open_interaction("phone")
		await settle()
		for b in ui.modal.find_children("*","Button",true,false):
			if b.text == "К столу":
				check(Rect2(Vector2.ZERO,Vector2(dims)).encloses(b.get_global_rect()), "Close button outside screen")
		ui.close_panel()
	ui.open_interaction("folder")
	await create_timer(1.1).timeout
	root.size = Vector2i(360,640)
	await settle()
	check(ui.modal.visible, "Resizing closed the open folder")
	ui.close_panel()
	await create_timer(0.85).timeout
	check(ui.office.camera.transform.is_equal_approx(home), "Resize broke folder return")
	print("Presentation: %d checks, %d failures" % [checks,failures])
	ui.queue_free()
	await process_frame
	quit(1 if failures else 0)
