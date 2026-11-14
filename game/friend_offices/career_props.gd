extends RefCounted
## Six furnishing sets, sharing the seated camera and interaction positions.
var s

func _init(stage) -> void:
	s = stage

func build(parent: Node3D, level: int) -> void:
	var metal = s.solid(Color(["#6b6c60", "#8b8269", "#b29755", "#c9a563", "#d3ad61", "#e6bc68"][level]), 0.65, 0.31)
	var finish = s.solid(Color(["#393e36", "#5b5547", "#295447", "#233d48", "#333338", "#234c40"][level]), 0.12, 0.34)
	var cream = s.solid(Color("#f2dba9"), 0.0, 0.8, true)
	clock(parent, level, metal, finish)
	lamp(parent, level, metal, finish, cream)
	phone(parent, level, metal, finish)
	pen_cup(parent, level, metal, finish)
	door(parent, level, metal)
	if level < 2:
		wall_organizer(parent, level, metal)

func group(parent: Node3D, label: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = label
	parent.add_child(node)
	node.position = at
	return node

func clock(parent: Node3D, level: int, metal: Material, finish: Material) -> void:
	var at := Vector3(-1.43, 3.0, -3.04) if level < 3 else Vector3(0, 3.0, -3.0)
	var node := group(parent, "CareerClock", at)
	var radius: float = [0.18, 0.19, 0.205, 0.20, 0.215, 0.222][level]
	if level == 1:
		s.block(node, Vector3(0, 0, -0.02), Vector3(0.445, 0.44, 0.065), s.surface_material(Color("#7c5b39"), 0))
	if level >= 3:
		s.block(node, Vector3(0, 0, -0.025), Vector3(0.47, 0.46, 0.065), finish)
		s.frame_molding(node, Vector3(0, 0, 0.015), Vector2(0.43, 0.42), 0.011, metal)
	var rim = s.rod(node, Vector3.ZERO, radius, radius, 0.06, metal)
	rim.rotation.x = PI / 2
	var face_color := Color("#f0e4c6") if level < 4 else Color("#d9c295")
	var face = s.rod(node, Vector3(0, 0, 0.037), radius - 0.025, radius - 0.025, 0.02, s.solid(face_color))
	face.rotation.x = PI / 2
	var ink = s.solid(Color("#453b2c"))
	for i in 12:
		var angle := i * TAU / 12
		var tick = s.block(node, Vector3(sin(angle) * (radius - 0.052), cos(angle) * (radius - 0.052), 0.052), Vector3(0.009, 0.022, 0.005), ink)
		tick.rotation.z = -angle
	if level >= 2:
		for i in 4:
			var numeral: String = ["XII", "III", "VI", "IX"][i]
			var angle := i * PI / 2
			var text = s.door_sign(node, numeral, Vector3(sin(angle) * 0.105, cos(angle) * 0.105, 0.057))
			text.pixel_size = 0.00058
	for spec in [Vector3(-0.021, 0.026, 0.065), Vector3(0.043, 0.004, 0.067)]:
		var hand = s.block(node, spec, Vector3(0.011, 0.081, 0.006), ink)
		hand.rotation.z = 0.65 if spec.x < 0 else -1.47
	if level >= 4:
		for side in [-1, 1]:
			s.block(node, Vector3(side * 0.217, 0, 0.027), Vector3(0.015, 0.33, 0.02), metal)

func lamp(parent: Node3D, level: int, metal: Material, finish: Material, cream: Material) -> void:
	var node := group(parent, "CareerLamp", Vector3(-0.81, 1.086, 1.77))
	s.rod(node, Vector3(0, 0.022, 0), 0.15, 0.175, 0.044, finish if level == 0 else metal)
	if level > 0:
		s.rod(node, Vector3(0, 0.052, 0), 0.118, 0.15, 0.022, finish)
	var height := 0.42 + level * 0.019
	s.rod(node, Vector3(0, height / 2, 0), 0.019, 0.028, height, metal)
	if level == 0:
		s.dome(node, Vector3(0, height, 0), 0.24, 0.15, finish)
	elif level == 1:
		s.dome(node, Vector3(0, height, 0), 0.25, 0.11, s.solid(Color("#69714c"))).scale = Vector3(1.15, 1, 0.8)
		s.rod(node, Vector3(0, 0.14, 0), 0.035, 0.045, 0.16, metal)
	elif level in [2, 4, 5]:
		# Broad green banker's shade, progressively richer fittings.
		var shade = s.dome(node, Vector3(0, height, 0), 0.265, 0.145, finish)
		shade.scale = Vector3(1.22, 0.9, 0.7)
		for side in [-1, 1]:
			s.rod(node, Vector3(side * 0.23, height - 0.055, 0), 0.015, 0.015, 0.12, metal)
		if level >= 4:
			s.rod(node, Vector3(0, 0.11, 0), 0.05, 0.06, 0.095, metal)
			s.cup_rim(node, 0.075, 0.136, 0.006, metal)
		if level == 5:
			for i in 12:
				var angle := TAU * i / 12
				s.rod(node, Vector3(sin(angle) * 0.12, 0.045, cos(angle) * 0.12), 0.005, 0.005, 0.023, metal)
			for side in [-1, 1]:
				s.block(node, Vector3(side * 0.23, height - 0.02, 0), Vector3(0.026, 0.024, 0.24), metal)
	else:
		s.rod(node, Vector3(0, height + 0.07, 0), 0.13, 0.245, 0.21, s.solid(Color("#d1b884")))
		s.cup_rim(node, height - 0.03, 0.242, 0.007, metal)
	var glow = s.rod(node, Vector3(0, height - 0.015, 0), 0.225, 0.23, 0.008, cream)
	if level in [2, 4, 5]: glow.scale = Vector3(1.2, 1, 0.7)

func phone(parent: Node3D, level: int, metal: Material, finish: Material) -> void:
	var node := group(parent, "CareerPhone", s.PHONE_POSITION)
	node.rotation.y = -0.18
	var housing = s.solid(Color(["#31362f", "#a59b7e", "#d2bd93", "#243f48", "#303432", "#e4d0a5"][level]), 0.09, 0.38)
	s.block(node, Vector3(0, 0.03, 0), Vector3(0.35, 0.06, 0.31), housing)
	if level > 0:
		s.block(node, Vector3(0, 0.012, 0), Vector3(0.36, 0.014, 0.32), metal)
	var panel := group(node, "DialPanel", Vector3(0, 0.071, 0.031))
	panel.rotation.x = deg_to_rad(12)
	s.block(panel, Vector3.ZERO, Vector3(0.295, 0.035, 0.20), housing)
	if level < 3:
		s.rod(panel, Vector3(0, 0.025, 0.005), 0.081, 0.084, 0.018, metal)
		for i in 10:
			var angle := TAU * i / 10
			s.rod(panel, Vector3(sin(angle) * 0.058, 0.038, cos(angle) * 0.058 + 0.005), 0.010, 0.010, 0.008, finish)
	else:
		for row in 4:
			for col in 3:
				s.block(panel, Vector3((col - 1) * 0.044, 0.025, (row - 1.5) * 0.035 + 0.015), Vector3(0.032, 0.017, 0.026), metal if level == 5 else s.solid(Color("#d2c19b")))
		if level >= 4:
			s.block(panel, Vector3(0, 0.023, -0.072), Vector3(0.139, 0.008, 0.026), s.solid(Color("#182d28")))
			for side in [-1, 1]:
				s.block(panel, Vector3(side * 0.112, 0.025, 0.025), Vector3(0.023, 0.01, 0.075), metal)
	var receiver := group(node, "Receiver", Vector3(0, 0.112, -0.108))
	s.block(receiver, Vector3(0, 0.027, 0), Vector3(0.255, 0.045, 0.052), housing)
	for side in [-1, 1]:
		s.rod(receiver, Vector3(side * 0.124, 0, 0), 0.05, 0.056, 0.075, housing)
		if level > 1: s.rod(receiver, Vector3(side * 0.124, -0.027, 0), 0.055, 0.055, 0.009, metal)
	# Coiled cord is solid geometry, visible from the seated camera.
	for i in 16:
		var coil := TorusMesh.new()
		coil.inner_radius = 0.010
		coil.outer_radius = 0.016
		coil.rings = 12
		coil.ring_segments = 6
		var part = s.prop(node, Vector3(-0.20, 0.075 - i * 0.002, -0.09 + i * 0.011), coil, finish)
		part.rotation.x = PI / 2

func pen_cup(parent: Node3D, level: int, metal: Material, finish: Material) -> void:
	var node := group(parent, "CareerPenCup", Vector3(0.70, 1.089, 1.72))
	var height := 0.265 + level * 0.01
	var body = s.surface_material(Color(["#777961", "#685640", "#365846", "#294653", "#333734", "#224a3d"][level]), 0)
	s.rod(node, Vector3(0, 0.015, 0), 0.105, 0.12, 0.03, metal if level > 1 else finish)
	if level in [1, 3]:
		for side in [-1, 1]:
			s.block(node, Vector3(side * 0.115, height / 2 + 0.02, 0), Vector3(0.018, height, 0.24), body)
			s.block(node, Vector3(0, height / 2 + 0.02, side * 0.115), Vector3(0.23, height, 0.018), body)
			if level == 3:
				s.block(node, Vector3(side * 0.115, height + 0.02, 0), Vector3(0.02, 0.012, 0.24), metal)
				s.block(node, Vector3(0, height + 0.02, side * 0.115), Vector3(0.23, 0.012, 0.02), metal)
	else:
		s.open_cylinder(node, Vector3(0, height / 2 + 0.02, 0), 0.126, 0.105, height, body)
		s.cup_rim(node, height + 0.02, 0.126, 0.006, metal)
	if level > 1:
		s.cup_rim(node, 0.04, 0.109, 0.006, metal)
		for side in [-1, 1]:
			s.block(node, Vector3(side * 0.065, height * 0.53, 0.109), Vector3(0.007, height * 0.62, 0.01), metal)
	if level > 3:
		var badge = s.block(node, Vector3(0, height * 0.58, 0.126), Vector3(0.045, 0.045, 0.012), metal)
		badge.rotation.z = PI / 4
	if level == 5:
		s.rod(node, Vector3(0, 0.008, 0), 0.145, 0.15, 0.016, s.solid(Color("#282c27"), 0.1, 0.24))
	for i in 4:
		var pen: Node3D
		if level < 2:
			pen = s.make_pencil(node, 0.43 + i * 0.025, s.solid(Color(["#bd793b", "#9a5040", "#807345", "#4f6765"][i])), s.solid(Color("#e3ba83")), finish)
		else:
			pen = s.make_pen(node, 0.43 + i * 0.025, finish, metal, s.solid(Color("#282a23")))
		pen.position = Vector3((i % 2 - 0.5) * 0.075, 0.04, (i / 2 - 0.5) * 0.06)
		pen.rotation_degrees = Vector3(-6 + i * 5, i * 24, -12 + i * 8)

func door(parent: Node3D, level: int, metal: Material) -> void:
	var leaf := group(s.doors.press, "CareerDoor%d" % level, Vector3.ZERO)
	s.career_doors.append(leaf)
	leaf.visible = level == 0
	if level < 1: return
	var edge = metal if level >= 3 else s.trim_material
	for y in [0.57, 1.54]:
		s.frame_molding(leaf, Vector3(0.54, y, 0.13), Vector2(0.71, 0.58 if y < 1 else 0.72), 0.009 + level * 0.002, edge)
	if level >= 2:
		for side in [-1, 1]:
			s.block(parent, Vector3(side * 0.67, 1.23, -2.87), Vector3(0.013, 2.37, 0.02), metal)
	if level >= 4:
		for side in [-1, 1]:
			s.block(parent, Vector3(side * 0.73, 1.25, -2.91), Vector3(0.10, 2.5, 0.11), s.door_material)
			for dx in [-0.026, 0.026]:
				s.block(parent, Vector3(side * 0.73 + dx, 1.25, -2.84), Vector3(0.009, 2.32, 0.018), metal)
	if level == 5:
		s.block(parent, Vector3(0, 2.59, -2.85), Vector3(1.66, 0.045, 0.16), metal)
		for side in [-1, 1]:
			var corner = s.block(leaf, Vector3(0.54 + side * 0.27, 1.8, 0.15), Vector3(0.06, 0.06, 0.02), metal)
			corner.rotation.z = PI / 4

func wall_organizer(parent: Node3D, level: int, metal: Material) -> void:
	var board := group(parent, "WallNoticeBoard", Vector3(-1.48, 1.9, -3.0))
	s.block(board, Vector3.ZERO, Vector3(1.08, 0.78, 0.055), s.trim_material)
	s.block(board, Vector3(0, 0, 0.035), Vector3(0.99, 0.69, 0.02), s.surface_material(Color("#99734e"), 0))
	for i in 5:
		var at := Vector3(-0.33 + (i % 3) * 0.32, 0.15 - (i / 3) * 0.31, 0.051)
		s.block(board, at, Vector3(0.23, 0.25, 0.007), s.solid(Color("#e7d7ad")))
		for line in 4:
			s.block(board, at + Vector3(0, 0.055 - line * 0.034, 0.006), Vector3(0.15 if line < 3 else 0.08, 0.006, 0.003), s.solid(Color("#9a8466")))
		var pin = s.rod(board, at + Vector3(0, 0.099, 0.009), 0.011, 0.011, 0.01, metal)
		pin.rotation.x = PI / 2
	var calendar := group(parent, "WallCalendar", Vector3(0.99, 1.94, -2.99))
	if level == 1:
		s.block(calendar, Vector3(0, 0, -0.025), Vector3(0.44, 0.62, 0.05), s.trim_material)
		for x in [-0.1, 0.1]:
			s.block(calendar, Vector3(x, 0.28, 0.039), Vector3(0.025, 0.045, 0.015), metal)
	s.block(calendar, Vector3.ZERO, Vector3(0.38, 0.56, 0.035), s.solid(Color("#e5d5b0")))
	s.block(calendar, Vector3(0, 0.235, 0.022), Vector3(0.38, 0.09, 0.02), s.solid(Color("#83503b")))
	var heading = s.door_sign(calendar, "НОЯБРЬ", Vector3(0, 0.23, 0.039))
	heading.pixel_size = 0.00092
	for row in 5:
		for col in 7:
			s.block(calendar, Vector3((col - 3) * 0.043, 0.13 - row * 0.068, 0.024), Vector3(0.018, 0.021, 0.004), s.solid(Color("#856d4f")))
