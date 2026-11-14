extends SceneTree
const OUT := "res://design/desk-awards-proposal/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(414, 780)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var ui = load("res://game/friend_offices/preview.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	preload("res://game/friend_offices/proposals/desk_awards.gd").new(ui.stage).apply()
	for index in [2, 3, 4, 5]:
		ui.select_rank(index)
		ui.hint.text = "Пробный вариант · для обсуждения"
		await create_timer(0.8).timeout
		ui.stage.refresh_room()
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "office-%02d.png" % (index + 1))
		print("Captured proposal ", index + 1)
	ui.queue_free()
	await process_frame
	quit()
