extends SceneTree

var failed := 0
var passed := 0

func check(ok: bool, description: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Headless windows default to 64x64 when virtual stretching is disabled.
	root.size = Vector2i(1280,800)
	if not FileAccess.file_exists("res://game/offices/workplace.tscn"):
		push_error("Interactive workplaces scene does not exist yet")
		quit(1)
		return
	var packed = load("res://game/offices/workplace.tscn")
	if packed == null:
		quit(1)
		return
	var ui = packed.instantiate()
	root.add_child(ui)
	await process_frame
	await physics_frame
	var signatures := {}
	for rank_index in 6:
		ui.select_rank(rank_index)
		await process_frame
		await physics_frame
		var room = ui.office
		signatures[room.layout_signature] = true
		for id in ["door", "folder", "phone", "agenda"]:
			var point: Vector2 = room.screen_position(id)
			check(Rect2(Vector2.ZERO, Vector2(room.get_viewport().size)).has_point(point), "Offscreen %s in rank %d" % [id, rank_index])
			check(room.pick_object(point) == id, "Cannot click %s in rank %d" % [id, rank_index])
			ui.open_interaction(id)
			check(ui.active_panel == id, "Cannot open %s" % id)
			ui.close_panel()
			check(ui.active_panel.is_empty(), "Cannot close panel")
	check(signatures.size() == 6, "Six distinct layouts required")
	for window_size in [Vector2i(360, 640), Vector2i(414, 780)]:
		root.size = window_size
		await process_frame
		await process_frame
		for rank_value in 6:
			ui.select_rank(rank_value)
			await physics_frame
			for id in ["door", "folder", "phone", "agenda"]:
				var point: Vector2 = ui.office.screen_position(id)
				check(Rect2(Vector2.ZERO, Vector2(ui.office.get_viewport().size)).has_point(point), "Offscreen %s at %s" % [id, window_size])
				var click := InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = true
				click.position = ui.scene_to_ui(point)
				ui._gui_input(click)
				check(ui.active_panel == id, "Scene click did not open %s at %s" % [id, window_size])
				ui.close_panel()
	var profile_script = load("res://game/offices/profile.gd")
	var names := {}
	for seed_value in 50:
		var profile = profile_script.new(seed_value)
		check(profile.full_name.split(" ").size() == 2, "Generated name requires first and last name")
		names[profile.full_name] = true
	check(names.size() > 20, "Name generation lacks variety")
	ui.queue_free()
	await process_frame
	print("Workplaces: %d checks passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
