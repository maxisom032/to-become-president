extends SceneTree
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(414,780)
	var ui=load("res://game/friend_offices/preview.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	var signatures := {}
	for rank_value in 6:
		ui.select_rank(rank_value)
		await create_timer(0.6).timeout
		var stage: Control = ui.stage
		check(stage.doors.size()==1 and stage.doors.has("press"),"Only central door must remain")
		check(not stage.hotspots.has("office") and not stage.hotspots.has("stats"),"Side-door hotspots remain")
		check(stage.camera.position.is_equal_approx(stage.CAMERA_POSITION),"Original seated camera changed")
		check(stage.paper.position.is_equal_approx(stage.paper_origin),"Original folder changed position")
		check(stage.career_rooms.size()==6,"Six career dressings required")
		var visible_count := 0
		for node in stage.career_rooms:
			if node.visible:visible_count+=1
		check(visible_count==1,"Overlapping stage decorations")
		var current: Node3D = stage.career_rooms[rank_value]
		signatures[str(current.get_child_count())+str(rank_value)]=true
		check(current.get_child_count()>0,"Empty career dressing")
		check(stage.wall_clock.is_visible_in_tree(),"Clock must be visible at every career rank")
		check(stage.wall_clock.position.y-0.205>2.715,"Clock overlaps horizontal molding")
		check(stage.wall_clock.position.y+0.205<3.26,"Clock overlaps top molding")
		for item in ["CareerLamp","CareerPhone","CareerPenCup"]:
			check(current.has_node(item),"Missing per-rank furnishing: "+item)
		check(current.has_node("WallCalendar")== (rank_value<2),"Calendar belongs in first two offices")
		if rank_value<2:
			check(current.get_node("WallNoticeBoard").position.y<2.3,"Notice board must be below the high wall band")
		check(stage.view.size.x>=414,"Room is rendered below native resolution")
		ui.open_item("paper")
		await create_timer(0.7).timeout
		check(stage.paper_cover.rotation.z>1.5,"Folder does not open")
		ui.open_item("")
		await create_timer(0.7).timeout
		check(absf(stage.paper_cover.rotation.z)<0.01,"Folder does not close")
		ui.open_item("press")
		await create_timer(0.6).timeout
		check(stage.doors.press.rotation.y < -1.5,"Central door does not open")
		ui.open_item("")
		await create_timer(0.6).timeout
	check(signatures.size()==6,"Missing career stage")
	for dimensions in [Vector2i(360,640),Vector2i(1080,2340),Vector2i(1280,800)]:
		root.size=dimensions
		for frame in 4:
			await process_frame
		ui.stage.update_render_size()
		await process_frame
		check(ui.stage.view.size==dimensions,"Room resolution does not match resized window")
		for id in ["paper","press"]:
			var button: Button = ui.stage.hotspots[id]
			check(Rect2(Vector2.ZERO,ui.stage.size).has_point(button.position+button.size/2),"Interaction moved outside resized view")
	print("Friend base: %d checks, %d failures" % [checks,failures])
	ui.queue_free()
	await process_frame
	quit(1 if failures else 0)
