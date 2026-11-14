extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(ui: Control, name_value: String) -> void:
	for frame in 8:
		await process_frame
	ui.stage.refresh_room()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://build/previews/friend-base/"+name_value+".png")
	print("Captured ",name_value)

func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(414,780)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews/friend-base"))
	var ui=load("res://game/friend_offices/preview.tscn").instantiate()
	root.add_child(ui)
	for index in 6:
		ui.select_rank(index)
		await create_timer(0.65).timeout
		await shot(ui,"office-%02d" % (index+1))
	ui.open_item("paper")
	await create_timer(0.9).timeout
	await shot(ui,"folder")
	ui.open_item("")
	await create_timer(0.9).timeout
	ui.open_item("press")
	await create_timer(0.7).timeout
	await shot(ui,"door")
	ui.queue_free()
	await process_frame
	quit()
