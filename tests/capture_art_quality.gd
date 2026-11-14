extends SceneTree

# Actual GPU frames, without UI, at a phone-shaped high-resolution viewport.
# Desktop timings are recorded separately from any mobile performance claim.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1080,2340)
	var ui=load("res://game/offices/workplace.tscn").instantiate()
	root.add_child(ui)
	var folder := "res://build/previews/clean/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var results := []
	for index in 6:
		ui.select_rank(index)
		for i in 25:
			await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = ui.scene_viewport.get_texture().get_image()
		var error := image.save_png(folder+"office-%02d.png" % (index+1))
		if error!=OK:
			push_error("Could not save clean GPU frame")
			quit(1)
			return
		var times: Array[float] = []
		var previous := Time.get_ticks_usec()
		for i in 45:
			await process_frame
			var now := Time.get_ticks_usec()
			times.append((now-previous)/1000.0)
			previous=now
		times.sort()
		var row := {
			"rank": index+1,
			"scene_pixels": str(image.get_size()),
			"median_frame_ms_windows": times[times.size()/2],
			"draw_calls_all_viewports": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			"triangles_all_viewports": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			"texture_memory_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),
			"baked_room": ui.office.has_node("BakedRoom")
		}
		results.append(row)
		print(JSON.stringify(row))
	var report := FileAccess.open(folder+"desktop-render-metrics.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"platform":"Windows Vulkan Forward+, RTX3060Ti, not physical mobile","results":results},"\t"))
	report.close()
	ui.queue_free()
	for i in 4:
		await process_frame
	quit(0)
