extends RefCounted
## Render-only proposal; the running preview does not load this script.
var s

func _init(stage) -> void:
	s = stage

func apply() -> void:
	for child in s.room.get_children():
		if child is Node3D and child.position.is_equal_approx(Vector3(0.64, 1.10, 2.48)):
			child.hide()
		if child is Node3D and child.position.is_equal_approx(Vector3(-0.62, 1.089, 2.22)):
			child.position = Vector3(-0.66, 1.089, 2.52)
	# Bring the existing Prefect inbox back toward the lamp.
	for child in s.rank_rooms[1].get_children():
		if child.position.x < -0.45 and child.position.x > -1.0 and child.position.y > 1.10 and child.position.y < 1.21 and child.position.z > 2.30 and child.position.z < 2.8:
			child.position += Vector3(-0.04, 0, -0.35)
	# Hide the old high wall caption, without touching the pendant lights.
	for child in s.rank_rooms[2].get_children():
		if child.position.x > 1.2 and child.position.y > 2.7 and child.position.z < -2.99:
			child.hide()
	for child in s.rank_rooms[3].get_children():
		if child.position.x > 1.2 and child.position.y > 2.7 and child.position.z < -2.9:
			child.hide()
	for level in [3, 4, 5]:
		var parent: Node3D = s.career_rooms[level]
		medallion(parent, level)
		if level < 4: continue
		var award_x := -1.47 if level == 4 else 1.47
		# Existing certificate is a group of flat meshes, all at this wall bay.
		for child in parent.get_children():
			if absf(child.position.x - award_x) < 0.1 and child.position.y > 1.1 and child.position.y < 2.65:
				child.hide()
		if level == 4:
			award(parent, Vector3(-1.47, 2.19, -2.94), Vector2(0.82, 0.43), "БЛАГОДАРНОСТЬ", false)
			award(parent, Vector3(-1.47, 1.58, -2.94), Vector2(0.82, 0.43), "НАГРАДНОЙ ЛИСТ", false)
		else:
			award(parent, Vector3(1.47, 1.88, -2.90), Vector2(1.12, 1.32), "ПОЧЁТНАЯ ГРАМОТА", true)
		important_papers(parent, level)
		water_set(parent, Vector3(-1.47, 0.85 if level == 4 else 0.81, -2.46), level)

func award(parent: Node3D, at: Vector3, dims: Vector2, title: String, premium: bool) -> void:
	var gold = s.solid(Color("#c9a05a"), 0.6, 0.35)
	var ink = s.solid(Color("#6c4d36"))
	s.block(parent, at, Vector3(dims.x + 0.12, dims.y + 0.12, 0.07), s.door_material)
	s.frame_molding(parent, at + Vector3(0, 0, 0.047), dims + Vector2(0.065, 0.065), 0.023 if premium else 0.012, gold)
	s.block(parent, at + Vector3(0, 0, 0.045), Vector3(dims.x, dims.y, 0.012), s.solid(Color("#e8d4a6")))
	s.frame_molding(parent, at + Vector3(0, 0, 0.057), dims * 0.94, 0.004, ink)
	var heading = s.door_sign(parent, title, at + Vector3(0, dims.y * 0.33, 0.069))
	heading.pixel_size = dims.x * 0.80 / (title.length() * 28.0)
	for row in 6:
		s.block(parent, at + Vector3(0, dims.y * 0.19 - row * dims.y * 0.067, 0.062), Vector3(dims.x * (0.70 if row < 5 else 0.48), 0.004, 0.002), ink)
	var seal = s.rod(parent, at + Vector3(-dims.x * 0.27, -dims.y * 0.33, 0.067), dims.x * 0.048, dims.x * 0.048, 0.008, gold)
	seal.rotation.x = PI / 2
	signature(parent, at + Vector3(dims.x * 0.18, -dims.y * 0.32, 0.069), dims.x * 0.28, ink)
	if premium:
		signature(parent, at + Vector3(-dims.x * 0.12, -dims.y * 0.37, 0.070), dims.x * 0.23, ink)
		var caption = s.door_sign(parent, "За выдающийся вклад", at + Vector3(0, -dims.y * 0.045, 0.069))
		caption.pixel_size = 0.00083

func signature(parent: Node3D, at: Vector3, width: float, ink: Material) -> void:
	var points: Array[Vector2] = []
	for i in 32:
		var t := i / 31.0
		points.append(Vector2((t - 0.5) * width + sin(t * TAU * 4) * width * 0.065, sin(t * TAU * 4) * width * (0.16 - t * 0.08) + t * width * 0.07))
	points.append(Vector2(-width * 0.46, -width * 0.055))
	points.append(Vector2(width * 0.6, -width * 0.015))
	for i in points.size() - 1:
		var start := points[i]
		var end := points[i + 1]
		var line = s.block(parent, at + Vector3((start.x + end.x) / 2, (start.y + end.y) / 2, 0), Vector3(start.distance_to(end), 0.0035, 0.002), ink)
		line.rotation.z = (end - start).angle()

func medallion(parent: Node3D, level: int) -> void:
	var at := Vector3(1.56, 2.96, -2.94)
	var gold = s.solid(Color("#be9652"), 0.6, 0.4)
	var disk = s.rod(parent, at, 0.17, 0.17, 0.025, s.door_material)
	disk.rotation.x = PI / 2
	for side in [-1, 1]:
		for i in 7:
			var angle := -1.25 + i * 0.34
			var leaf = s.block(parent, at + Vector3(side * cos(angle) * 0.145, sin(angle) * 0.145, 0.025), Vector3(0.055, 0.022, 0.007), gold)
			leaf.rotation.z = side * (angle + 0.6)
	var emblem = s.block(parent, at + Vector3(0, 0, 0.027), Vector3(0.082, 0.082, 0.008), gold)
	emblem.rotation.z = PI / 4
	if level == 5:
		s.frame_molding(parent, at + Vector3(0, 0, 0.003), Vector2(0.42, 0.42), 0.009, gold)

func important_papers(parent: Node3D, level: int) -> void:
	var tray := Node3D.new()
	tray.name = "ProposedInbox"
	parent.add_child(tray)
	tray.position = Vector3(-0.04, 0, -0.35)
	parent = tray
	var gold = s.solid(Color("#b89757"), 0.6, 0.35)
	s.build_mail_tray(parent, gold)
	var at := Vector3(-0.70, 1.184, 2.49)
	var paper = s.solid(Color("#ead8ad"))
	s.block(parent, at, Vector3(0.26, 0.008, 0.19), paper)
	if level == 4:
		var seal = s.rod(parent, at + Vector3(0.02, 0.011, 0), 0.026, 0.026, 0.009, s.solid(Color("#8c352e")))
		seal.rotation.y = 0.1
		var ribbon = s.block(parent, at + Vector3(0.02, 0.006, 0), Vector3(0.024, 0.004, 0.19), s.solid(Color("#8c352e")))
		ribbon.rotation.y = 0.06
	else:
		for row in 4:
			s.block(parent, at + Vector3(0, 0.008, -0.05 + row * 0.025), Vector3(0.17, 0.002, 0.003), gold)
		var pen: Node3D = s.make_pen(parent, 0.26, s.solid(Color("#283b33")), gold, s.solid(Color("#292820")))
		pen.position = at + Vector3(0.10, 0.023, -0.08)
		pen.rotation_degrees = Vector3(90, 0, -13)

func water_set(parent: Node3D, at: Vector3, level: int) -> void:
	var glass = s.solid(Color("#8da79c"), 0.12, 0.22)
	var water = s.solid(Color("#597f7a"), 0.04, 0.3)
	var gold = s.solid(Color("#c1a15f"), 0.65, 0.3)
	s.rod(parent, at, 0.20, 0.21, 0.018, gold)
	s.rod(parent, at + Vector3(-0.06, 0.12, 0), 0.065, 0.072, 0.22, glass)
	s.rod(parent, at + Vector3(-0.06, 0.255, 0), 0.028, 0.065, 0.055, glass)
	s.rod(parent, at + Vector3(-0.06, 0.31, 0), 0.028, 0.028, 0.06, glass)
	s.rod(parent, at + Vector3(-0.06, 0.35, 0), 0.036, 0.032, 0.023, gold)
	s.rod(parent, at + Vector3(0.105, 0.06, 0.04), 0.047, 0.035, 0.11, water)
	s.rod(parent, at + Vector3(0.105, 0.118, 0.04), 0.048, 0.048, 0.008, glass)
	if level == 5:
		for dx in [-0.10, -0.06, -0.02]:
			s.block(parent, at + Vector3(dx, 0.13, 0.067), Vector3(0.006, 0.17, 0.006), s.solid(Color("#cfddd3"), 0.15, 0.25))
