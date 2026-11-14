extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(414, 780)
	var ui = load("res://game/offices/workplace.tscn").instantiate()
	root.add_child(ui)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews"))
	for index in 6:
		ui.select_rank(index)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://build/previews/room-%d.png" % (index + 1))
		if result != OK:
			quit(1)
			return
	ui.open_interaction("door")
	for frame in 25:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/previews/door-panel.png")
	ui.close_panel()
	ui.select_rank(2)
	ui.open_interaction("folder")
	await create_timer(1.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/previews/folder-open.png")
	ui.close_panel()
	await create_timer(0.85).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/previews/folder-returned.png")
	print("Captured six rooms and door interaction")
	quit(0)
