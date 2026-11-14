extends SceneTree

func _initialize() -> void:
	call_deferred("capture")
func shot(path: String) -> void:
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png("res://build/previews/"+path+".png")
	if error != OK:
		push_error("Capture failed: "+path)
		quit(1)
	print(path, " ", image.get_size())
func capture() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,800)
	var ui=load("res://game/offices/workplace.tscn").instantiate()
	root.add_child(ui)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews"))
	for format_value in ["desktop","phone"]:
		root.size=Vector2i(1280,800) if format_value=="desktop" else Vector2i(393,852)
		for index in 6:
			ui.select_rank(index)
			await shot("painted-%s-%d" % [format_value,index+1])
	ui.select_rank(2)
	ui.open_interaction("folder")
	await create_timer(1.2).timeout
	await shot("painted-phone-folder")
	root.size=Vector2i(1280,800)
	await shot("painted-desktop-folder")
	ui.close_panel()
	await create_timer(0.9).timeout
	root.size=Vector2i(1920,1080)
	await shot("painted-desktop-1080p")
	root.size=Vector2i(1080,2340)
	await shot("painted-phone-highdpi")
	ui.party_select.show_popup()
	await shot("painted-phone-highdpi-menu")
	ui.party_select.get_popup().hide()
	ui.queue_free()
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	quit(0)
