extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://game/offices/workplace.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	if not ui.office.has_method("focus_folder"):
		check(false, "Folder camera and hinge sequence is not implemented")
		quit(1)
		return
	for name in ["walnut", "plaster", "fabric", "district_map"]:
		check(FileAccess.file_exists("res://game/offices/assets/textures/%s.png" % name), "Missing real texture: " + name)
	for rank_value in 6:
		ui.select_rank(rank_value)
		await process_frame
		check(ui.office.windows.size() > 0, "No animated window in rank %d" % rank_value)
	ui.select_rank(2)
	await process_frame
	var home: Transform3D = ui.office.camera.transform
	ui.open_interaction("folder")
	check(not ui.modal.visible, "Reader appeared before camera movement")
	await create_timer(1.1).timeout
	check(ui.modal.visible, "Reader did not appear after folder opening")
	check(ui.office.folder_hinge.rotation.z > 1.5, "Cover is not physically open")
	check(ui.office.camera.position.distance_to(home.origin) > 0.4, "Camera did not approach folder")
	ui.close_panel()
	await create_timer(0.85).timeout
	check(ui.office.folder_hinge.rotation.z < 0.03, "Cover did not close")
	check(ui.office.camera.transform.is_equal_approx(home), "Camera did not return to desk")
	# Closing another panel while the camera returns must not stop that return.
	ui.open_interaction("folder")
	await create_timer(1.1).timeout
	ui.close_panel()
	await create_timer(0.20).timeout
	ui.open_interaction("phone")
	await create_timer(0.05).timeout
	ui.close_panel()
	await create_timer(0.9).timeout
	check(ui.office.camera.transform.is_equal_approx(home), "Quick phone close interrupted camera return")
	check(is_equal_approx(ui.office.camera.fov, 66.0), "Quick phone close left zoom stuck")
	ui.open_interaction("folder")
	ui.select_rank(5)
	await create_timer(1.0).timeout
	check(ui.active_panel.is_empty() and not ui.modal.visible, "Cancelled folder transition reopened reader")
	var window = ui.office.windows[0]
	var old_position: Vector3 = window.car.position
	window._process(0.5)
	check(window.car.position.distance_to(old_position) > 0.001, "Traffic outside the window does not move")
	ui.queue_free()
	await process_frame
	print("Polish tests: %d failures" % failures)
	quit(1 if failures else 0)
