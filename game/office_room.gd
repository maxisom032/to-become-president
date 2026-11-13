extends Control

# Visual room geometry adapted from arseniy3291/to-become-president cb5698a.
# No campaign rules, events, character sprites or gameplay interactions are included.
const SURFACE := preload("res://game/office_surface.gdshader")
const SIGN_FONT := preload("res://game/art/fonts/PTSerif-Bold.ttf")
const CASE_COVER := preload("res://game/art/office/case-cover.jpg")
const FOLDER_SIZE := Vector2(0.83, 0.91)
const DOOR_NAMES := {"office": "КОЛЛЕГИ", "press": "ПРЕССА", "stats": "СОВЕТ"}
const DOOR_IDS := ["office", "press", "stats"]
const BRASS := Color("#cd9449")
const CREAM := Color("#f1deaa")
const PHONE_POSITION := Vector3(0.73, 1.10, 2.105)
const DARK_WOOD := Color("#502c1d")
const BLACK := Color("#171a19")
const CAMERA_POSITION := Vector3(0, 2.86, 5.4)
const CAMERA_TARGET := Vector3(0, 1.34, -1.8)
var view: SubViewport
var camera: Camera3D
var room: Node3D
var doors := {}
var plaques := {}
var paper: Node3D
var paper_cover: Node3D
var paper_number: Label3D
var paper_origin: Vector3
var wall_material: ShaderMaterial
var desk_material: ShaderMaterial
var trim_material: ShaderMaterial
var door_material: ShaderMaterial
var door_inset_material: ShaderMaterial
var carpet_material: ShaderMaterial
var style_rooms: Array[Node3D] = []
var upgrades: Dictionary[Node3D, int] = {}
var room_environment: Environment
var wall_clock: Node3D
var style_index := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	view = SubViewport.new()
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	var surface := TextureRect.new()
	surface.texture = view.get_texture()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(surface)
	room = Node3D.new()
	view.add_child(room)
	build_room()
	paper_number.text = "№ 001"
	set_style(0)
	resized.connect(update_render_size)
	update_render_size()

func update_render_size() -> void:
	if view == null or size.x < 2 or size.y < 2:
		return
	view.size = Vector2i(size.round()).max(Vector2i(2, 2))
	var aspect := float(view.size.x) / view.size.y
	camera.fov = clampf(rad_to_deg(2.0 * atan(0.264 / aspect)), 43.0, 67.0)
	refresh_room()

func refresh_room() -> void:
	if view != null:
		view.render_target_update_mode = SubViewport.UPDATE_ONCE

func set_style(level: int) -> void:
	if style_index == level:
		return
	style_index = level
	var walls := ["#285054", "#596347", "#253e5b", "#653542"]
	var desks := ["#785339", "#9b693a", "#503a2c", "#3f2824"]
	var trims := ["#694832", "#715030", "#3c2a25", "#322320"]
	var doors_oak := ["#8b5839", "#765133", "#4b3226", "#35241f"]
	var panels := ["#69432d", "#573824", "#35221a", "#251917"]
	var carpets := ["#743a30", "#6b5438", "#264858", "#753341"]
	wall_material.set_shader_parameter("tint", Color(walls[style_index]))
	wall_material.set_shader_parameter("wallpaper", style_index)
	desk_material.set_shader_parameter("tint", Color(desks[style_index]))
	trim_material.set_shader_parameter("tint", Color(trims[style_index]))
	door_material.set_shader_parameter("tint", Color(doors_oak[style_index]))
	door_inset_material.set_shader_parameter("tint", Color(panels[style_index]))
	carpet_material.set_shader_parameter("tint", Color(carpets[style_index]))
	room_environment.ambient_light_color = Color(["#e2e2e0", "#fff2db", "#dae6ff", "#ffded0"][style_index])
	wall_clock.visible = style_index < 3
	for index in style_rooms.size():
		style_rooms[index].visible = index == style_index
	for decoration in upgrades:
		decoration.visible = style_index >= upgrades[decoration]
	refresh_room()

func upgrade(parent: Node3D, level: int) -> Node3D:
	var decoration := Node3D.new()
	parent.add_child(decoration)
	upgrades[decoration] = level
	return decoration

func build_room() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	room_environment = env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#18272b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e2e2e0")
	env.ambient_light_energy = 0.53
	world.environment = env
	room.add_child(world)
	camera = Camera3D.new()
	room.add_child(camera)
	camera.position = CAMERA_POSITION
	camera.look_at(CAMERA_TARGET)
	camera.current = true

	wall_material = surface_material(Color.WHITE, 2)
	desk_material = surface_material(Color.WHITE, 3)
	trim_material = surface_material(Color.WHITE, 1)
	door_material = surface_material(Color.WHITE, 4)
	door_inset_material = surface_material(Color.WHITE, 4)
	carpet_material = surface_material(Color.WHITE, 0)
	var wood := surface_material(DARK_WOOD, 1)
	var floor_material := surface_material(Color("#534135"), 3)
	var dark := solid(BLACK)
	var brass := solid(BRASS, 0.28, 0.48)
	var light := solid(Color("#ffcf7e"), 0, 0.65, true)
	var rail := solid(Color("#a37845"))
	block(room, Vector3(0, -0.09, 0.0), Vector3(9.0, 0.18, 13.0), floor_material)
	var plaster := surface_material(Color("#2f3532"), 0)
	block(room, Vector3(0, 3.58, -0.3), Vector3(9.0, 0.2, 12.0), plaster)
	for z in [-2.75, -1.0, 0.8, 2.6]:
		block(room, Vector3(0, 3.47, z), Vector3(6.60, 0.10, 0.14), wood)
	for side in [-1, 1]:
		block(room, Vector3(side * 3.31, 1.76, -0.25), Vector3(0.16, 3.55, 8.0), wall_material)
		block(room, Vector3(side * 3.21, 0.15, -0.25), Vector3(0.11, 0.3, 8.0), trim_material)
	block(room, Vector3(0, 3.02, -3.24), Vector3(6.6, 1.09, 0.32), wall_material)
	for x in [-2.80, -0.715, 0.715, 2.80]:
		var width := 1.54 if absf(x) > 1.0 else 0.28
		block(room, Vector3(x, 1.23, -3.24), Vector3(width, 2.49, 0.32), wall_material)
		block(room, Vector3(x, 0.17, -3.05), Vector3(width, 0.29, 0.09), trim_material)
	block(room, Vector3(0, 3.34, -3.02), Vector3(6.6, 0.16, 0.13), trim_material)
	block(room, Vector3(0, 3.47, -2.03), Vector3(6.6, 0.16, 0.22), wood)
	for level in 4:
		var furnishings := Node3D.new()
		furnishings.name = "OfficeRank%d" % level
		room.add_child(furnishings)
		style_rooms.append(furnishings)
	build_clock(wood, brass)
	build_notice_board(style_rooms[0], wood, brass)
	build_style_details(wood, brass, dark)
	block(room, Vector3(0, 2.69, -3.02), Vector3(4.26, 0.05, 0.13), trim_material)

	var void_material := solid(Color("#100c0c"))
	void_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	block(room, Vector3(0, 1.28, -4.10), Vector3(7.0, 2.61, 0.06), void_material)
	block(room, Vector3(0, 0, -3.64), Vector3(7.0, 0.021, 0.91), void_material)
	for index in DOOR_IDS.size():
		build_door(DOOR_IDS[index], (index - 1) * 1.43, wood, brass)

	block(room, Vector3(0, 0.014, -1.25), Vector3(1.57, 0.029, 3.45), carpet_material)
	for side in [-1, 1]:
		block(room, Vector3(side * 0.68, 0.032, -1.25), Vector3(0.025, 0.009, 3.26), rail)
		block(room, Vector3(0, 0.032, -1.25 + side * 1.60), Vector3(1.36, 0.009, 0.028), rail)
	for z in [-2.47, -1.87, -1.27, -0.67, -0.07]:
		var motif := block(room, Vector3(0, 0.033, z), Vector3(0.28, 0.009, 0.28), rail)
		motif.rotation.y = PI / 4.0

	# Ceiling pendant and shaded fill separate the foreground from the doors.
	light_at(Vector3(0, 2.76, -1.52), Color("#ffbd75"), 1.31, 6.3, true)
	light_at(Vector3(-2.8, 3.0, -1.72), Color("#a1d6f0"), 0.76, 4.2)
	light_at(Vector3(0.90, 3.05, 2.38), Color("#ffe2c3"), 0.47, 6.6)
	build_pendant(style_rooms[0], 0.0, 2.99, 0.31, dark, trim_material, light)
	build_pendant(style_rooms[1], 0.0, 3.04, 0.30, brass, door_material, light)
	for level in [2, 3]:
		for x in [-1.42, 1.42]:
			build_pendant(style_rooms[level], x, 3.12, 0.20 if level == 2 else 0.24, brass, door_inset_material, light)
		var ceiling := style_rooms[level]
		for x in [-1.63, 0.0, 1.63]:
			block(ceiling, Vector3(x, 3.447, -1.4), Vector3(0.13, 0.105, 4.14), trim_material)
			if level == 3:
				block(ceiling, Vector3(x, 3.39, -1.4), Vector3(0.019, 0.013, 4.05), brass)

	build_desk(wood, brass, light, dark)

func build_clock(wood: Material, brass: Material) -> void:
	var clock := Node3D.new()
	wall_clock = clock
	room.add_child(clock)
	clock.position = Vector3(-1.43, 2.83, -3.04)
	var rim := rod(clock, Vector3.ZERO, 0.20, 0.205, 0.10, wood)
	rim.rotation.x = PI / 2.0
	var face := rod(clock, Vector3(0, 0, 0.055), 0.164, 0.166, 0.022, brass)
	face.rotation.x = PI / 2.0
	for mark in 12:
		var angle := mark * TAU / 12.0
		var tick := block(clock, Vector3(sin(angle) * 0.131, cos(angle) * 0.131, 0.069), Vector3(0.012, 0.021, 0.008), wood)
		tick.rotation.z = -angle
	var hour := block(clock, Vector3(-0.024, 0.030, 0.079), Vector3(0.015, 0.075, 0.009), wood)
	hour.rotation.z = 0.70
	var minute := block(clock, Vector3(0.054, 0.008, 0.079), Vector3(0.012, 0.111, 0.009), wood)
	minute.rotation.z = -1.43

func build_pendant(parent: Node3D, x: float, height: float, radius: float, metal: Material, shade: Material, light: Material) -> void:
	var cord_height := 3.50 - height
	var cord := rod(parent, Vector3(x, height + cord_height * 0.5, -1.85), 0.018, 0.018, cord_height, metal)
	cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pendant := dome(parent, Vector3(x, height, -1.85), radius, radius * 0.61, shade)
	pendant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bulb := rod(parent, Vector3(x, height - 0.009, -1.85), radius * 0.94, radius * 0.95, 0.018, light)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func build_notice_board(parent: Node3D, wood: Material, brass: Material) -> void:
	var board := Node3D.new()
	parent.add_child(board)
	board.position = Vector3(1.36, 2.93, -3.02)
	var cork := surface_material(Color("#8e6040"), 0)
	block(board, Vector3.ZERO, Vector3(0.87, 0.40, 0.045), wood)
	block(board, Vector3(0, 0, 0.027), Vector3(0.79, 0.33, 0.022), cork)
	for side in [-1, 1]:
		block(board, Vector3(0, side * 0.172, 0.049), Vector3(0.84, 0.024, 0.016), trim_material)
		block(board, Vector3(side * 0.407, 0, 0.049), Vector3(0.025, 0.36, 0.016), trim_material)
	var ink := solid(Color("#9a7a59"))
	var red := solid(Color("#9b4334"))
	for index in 3:
		var note := Node3D.new()
		board.add_child(note)
		note.position = Vector3((index - 1) * 0.235, 0.012 - (index % 2) * 0.049, 0.047)
		note.rotation.z = [-0.09, 0.06, -0.04][index]
		block(note, Vector3.ZERO, Vector3(0.205, 0.21, 0.008), solid(Color("#dbc28e") if index == 1 else Color("#eedab5")))
		var pin := rod(note, Vector3(0, 0.076, 0.014), 0.013, 0.014, 0.015, red if index == 1 else brass)
		pin.rotation.x = PI / 2.0
		for line in 3:
			block(note, Vector3(-0.007 * line, 0.031 - line * 0.036, 0.006), Vector3(0.13 - line * 0.024, 0.009, 0.003), ink)

func build_door(id: String, x: float, wood: Material, brass: Material) -> void:
	for side in [-1, 1]:
		block(room, Vector3(x + side * 0.61, 1.22, -3.00), Vector3(0.13, 2.44, 0.16), trim_material)
		block(room, Vector3(x + side * 0.57, 1.22, -2.99), Vector3(0.03, 2.41, 0.17), wood)
		block(room, Vector3(x + side * 0.65, 1.23, -2.908), Vector3(0.024, 2.40, 0.031), wood)
	block(room, Vector3(x, 2.45, -3.00), Vector3(1.35, 0.15, 0.19), trim_material)
	block(room, Vector3(x, 2.51, -2.89), Vector3(1.39, 0.034, 0.07), wood)
	block(room, Vector3(x, 0.025, -3.02), Vector3(1.21, 0.05, 0.22), brass)
	var pivot := Node3D.new()
	room.add_child(pivot)
	pivot.position = Vector3(x - 0.54, 0.025, -3.10)
	doors[id] = pivot
	block(pivot, Vector3(0.54, 1.16, 0), Vector3(1.08, 2.31, 0.1), door_material)
	for position in [Vector2(0.57, 0.72), Vector2(1.54, 0.88)]:
		for face in [-1.0, 1.0]:
			block(pivot, Vector3(0.54, position.x, face * 0.054), Vector3(0.83, position.y, 0.032), door_inset_material)
			block(pivot, Vector3(0.54, position.x, face * 0.077), Vector3(0.74, position.y - 0.11, 0.025), door_material)
	block(pivot, Vector3(0.93, 0.96, 0.07), Vector3(0.088, 0.17, 0.028), brass)
	var handle := rod(pivot, Vector3(0.93, 1.00, 0.116), 0.044, 0.055, 0.065, brass)
	handle.rotation.x = PI / 2.0
	block(pivot, Vector3(0.54, 1.75, 0.10), Vector3(0.76, 0.26, 0.043), wood)
	block(pivot, Vector3(0.54, 1.75, 0.126), Vector3(0.70, 0.21, 0.020), brass)
	var sign := door_sign(pivot, DOOR_NAMES[id], Vector3(0.54, 1.75, 0.139))
	plaques[id] = sign
	block(pivot, Vector3(0.54, 1.75, -0.091), Vector3(0.63, 0.19, 0.024), brass)
	var inside_sign := door_sign(pivot, DOOR_NAMES[id], Vector3(0.54, 1.75, -0.107))
	inside_sign.rotate_y(PI)
	var casing := upgrade(room, 1)
	block(casing, Vector3(x, 2.56, -2.927), Vector3(1.32, 0.074, 0.12), door_inset_material)
	block(casing, Vector3(x, 2.604, -2.891), Vector3(1.40, 0.026, 0.098), door_material)
	var hardwood := upgrade(pivot, 2)
	for y in [0.57, 1.54]:
		var panel_height := 0.69 if y < 1.0 else 0.85
		frame_molding(hardwood, Vector3(0.54, y, 0.099), Vector2(0.79, panel_height), 0.024, door_inset_material)
	block(hardwood, Vector3(0.54, 1.033, 0.072), Vector3(0.99, 0.042, 0.045), door_inset_material)
	var carved := upgrade(pivot, 3)
	frame_molding(carved, Vector3(0.54, 0.57, 0.106), Vector2(0.67, 0.54), 0.011, brass)
	for flute in 3:
		block(carved, Vector3(0.42 + flute * 0.12, 0.57, 0.097), Vector3(0.017, 0.36, 0.023), door_inset_material)

func frame_molding(parent: Node3D, center: Vector3, extents: Vector2, thickness: float, material: Material) -> void:
	for side in [-1, 1]:
		block(parent, center + Vector3(side * extents.x / 2.0, 0, 0), Vector3(thickness, extents.y, 0.025), material)
		block(parent, center + Vector3(0, side * extents.y / 2.0, 0), Vector3(extents.x + thickness, thickness, 0.025), material)

func door_sign(pivot: Node3D, title: String, at: Vector3) -> Label3D:
	var sign := Label3D.new()
	sign.text = title
	sign.font = SIGN_FONT
	sign.font_size = 42
	sign.pixel_size = 0.00163
	sign.outline_size = 0
	sign.modulate = Color("#3d2a1d")
	pivot.add_child(sign)
	sign.position = at
	return sign

func build_desk(wood: Material, brass: Material, light: Material, dark: Material) -> void:
	for level in style_rooms.size():
		build_desk_furniture(style_rooms[level], level, brass, light, dark)
	light_at(Vector3(-0.81, 1.47, 1.80), Color("#ffd092"), 0.64, 2.0)
	build_pen_cup(brass, dark)
	build_desk_accessories(wood, brass, dark)
	var red := solid(Color("#a33f2d"))
	var marker := rod(room, Vector3(0.54, 1.087, 2.31), 0.017, 0.017, 0.43, red)
	marker.rotation_degrees = Vector3(89, 0, 65)
	var sheets := [
		solid(Color("#d6bf94")), solid(Color("#ead5ad")), solid(Color("#f7e5bd")),
	]
	for i in 9:
		var sheet := block(room, Vector3(0.025 + sin(i * 4.0) * 0.028, 1.094 + i * 0.009, 2.05 + cos(i * 3.2) * 0.027), Vector3(0.78, 0.011, 0.85), sheets[i % sheets.size()])
		sheet.rotation.y = sin(i * 5.0) * 0.09
	build_case_folder(red)

func build_desk_furniture(parent: Node3D, level: int, brass: Material, light: Material, dark: Material) -> void:
	var width: float = [2.92, 3.14, 3.48, 3.73][level]
	var front: float = [2.76, 2.82, 2.95, 3.02][level]
	var rear := 1.39
	var depth := front - rear
	var center := (front + rear) / 2.0
	var edge := trim_material if level < 2 else door_inset_material
	block(parent, Vector3(0, 1.017, center), Vector3(width, 0.111, depth), desk_material)
	block(parent, Vector3(0, 0.949, center), Vector3(width - 0.035, 0.032, depth - 0.025), edge)
	block(parent, Vector3(0, 0.86, center), Vector3(width - 0.18, 0.16, depth - 0.16), door_material)
	var rail := brass if level > 0 else trim_material
	block(parent, Vector3(0, 0.987, front + 0.009), Vector3(width - 0.025, 0.018, 0.027), rail)
	for side in [-1.0, 1.0]:
		var x: float = side * (width * 0.5 - 0.34)
		var pedestal := 0.26 + level * 0.09
		block(parent, Vector3(x, 0.41, center), Vector3(pedestal, 0.82, depth - 0.24), door_material)
		block(parent, Vector3(x, 0.048, center), Vector3(pedestal + 0.10, 0.096, depth - 0.19), edge)
		for row in 2:
			var y := 0.45 + row * 0.22
			block(parent, Vector3(x, y, front - 0.104), Vector3(pedestal - 0.027, 0.18, 0.04), edge)
			block(parent, Vector3(x, y, front - 0.078), Vector3(0.105, 0.021, 0.025), rail)
		if level >= 2:
			block(parent, Vector3(side * (width * 0.5 - 0.065), 0.46, front - 0.12), Vector3(0.11, 0.81, 0.11), edge)
	var felt_colors := ["#2e4a42", "#484c2b", "#26394a", "#201d1b"]
	var blotter := surface_material(Color(felt_colors[level]), 0)
	var blotter_size: Vector2 = [Vector2(1.62, 1.05), Vector2(2.11, 1.11), Vector2(2.46, 1.22), Vector2(2.83, 1.32)][level]
	block(parent, Vector3(0.08, 1.08, 2.16), Vector3(blotter_size.x, 0.017, blotter_size.y), blotter)
	var piping := solid(Color(["#5f6247", "#b58d51", "#a88550", "#b88d50"][level]))
	for side in [-1.0, 1.0]:
		block(parent, Vector3(0.08 + side * (blotter_size.x * 0.5 - 0.024), 1.09, 2.16), Vector3(0.011, 0.003, blotter_size.y - 0.04), piping)
		block(parent, Vector3(0.08, 1.09, 2.16 + side * (blotter_size.y * 0.5 - 0.022)), Vector3(blotter_size.x - 0.04, 0.003, 0.011), piping)
	if level >= 2:
		for x in [-0.64, 0.0, 0.64]:
			frame_molding(parent, Vector3(x, 0.852, front - 0.055), Vector2(0.48, 0.109), 0.012, rail)
	build_style_lamp(parent, level, brass, light, dark)

func build_style_lamp(parent: Node3D, level: int, brass: Material, light: Material, dark: Material) -> void:
	var lamp := Node3D.new()
	parent.add_child(lamp)
	lamp.position = Vector3(-0.81, 1.086, 1.77)
	rod(lamp, Vector3(0, 0.025, 0), 0.164, 0.19, 0.050, brass if level > 0 else dark)
	rod(lamp, Vector3(0, 0.26, 0), 0.023, 0.034, 0.45, brass)
	var lacquer := solid(Color(["#9a733a", "#28654b", "#e5c699", "#723b40"][level]), 0.15, 0.51)
	var shade: MeshInstance3D
	if level <= 1:
		shade = dome(lamp, Vector3(0, 0.442, 0), 0.265, 0.17, lacquer)
	else:
		shade = rod(lamp, Vector3(0, 0.533, 0), 0.13, 0.248, 0.21, lacquer)
		rod(lamp, Vector3(0, 0.64, 0), 0.128, 0.134, 0.012, brass)
	var glow := rod(lamp, Vector3(0, 0.429, 0), 0.245, 0.249, 0.015, light)
	if level == 1:
		shade.scale = Vector3(1.22, 0.84, 0.66)
		glow.scale = Vector3(1.22, 1, 0.66)
	if level >= 2:
		cup_rim(lamp, 0.425, 0.247, 0.006, brass)

func build_case_folder(tab_material: Material) -> void:
	paper = Node3D.new()
	paper.name = "CaseFolder"
	room.add_child(paper)
	paper_origin = Vector3(0.025, 1.179, 2.05)
	paper.position = paper_origin
	paper.rotation.y = 0.08
	var kraft := surface_material(Color("#9e6947"), 0)
	block(paper, Vector3(0, -0.018, 0), Vector3(FOLDER_SIZE.x, 0.014, FOLDER_SIZE.y), kraft)
	var sheet := surface_material(Color("#c8ae82"), 0)
	block(paper, Vector3(0.014, -0.006, 0.008), Vector3(0.746, 0.011, 0.839), sheet)
	var rules := solid(Color("#a48b68"))
	block(paper, Vector3(-0.30, 0.001, 0), Vector3(0.005, 0.002, 0.77), rules)
	for line in 7:
		var width := 0.52 if line < 6 else 0.34
		block(paper, Vector3(-0.27 + width / 2.0, 0.001, -0.18 + line * 0.064), Vector3(width, 0.002, 0.004), rules)
	block(paper, Vector3(-0.19, 0.001, -0.30), Vector3(0.16, 0.002, 0.027), tab_material)
	block(paper, Vector3(0.410, -0.012, -0.275), Vector3(0.086, 0.015, 0.133), tab_material)

	paper_cover = Node3D.new()
	paper_cover.name = "CoverHinge"
	paper.add_child(paper_cover)
	var half_width := FOLDER_SIZE.x / 2.0
	paper_cover.position.x = -half_width
	var cover_center := Vector3(half_width, 0, 0)
	block(paper_cover, cover_center + Vector3(0, 0.005, 0), Vector3(FOLDER_SIZE.x, 0.013, FOLDER_SIZE.y), kraft)
	var front := PlaneMesh.new()
	front.size = FOLDER_SIZE
	var print := solid(Color.WHITE, 0.0, 0.95)
	print.albedo_texture = CASE_COVER
	prop(paper_cover, cover_center + Vector3(0, 0.012, 0), front, print)
	block(paper, Vector3(-half_width + 0.008, -0.007, 0), Vector3(0.018, 0.024, 0.899), kraft)
	paper_number = Label3D.new()
	paper_number.font = SIGN_FONT
	paper_number.font_size = 68
	paper_number.pixel_size = 0.00215
	paper_number.modulate = Color("#332017")
	paper_number.outline_size = 0
	paper_cover.add_child(paper_number)
	paper_number.position = cover_center + Vector3(0, 0.015, -0.054)
	paper_number.rotation.x = -PI / 2.0

func build_pen_cup(brass: Material, dark: Material) -> void:
	var cup := Node3D.new()
	cup.name = "PenCup"
	room.add_child(cup)
	cup.position = Vector3(0.70, 1.089, 1.72)
	var enamel := solid(Color("#244b48"), 0.18, 0.36)
	var liner := solid(Color("#1c2c2a"), 0.0, 0.58)
	liner.cull_mode = BaseMaterial3D.CULL_FRONT
	rod(cup, Vector3(0, 0.021, 0), 0.124, 0.14, 0.042, dark)
	rod(cup, Vector3(0, 0.039, 0), 0.127, 0.131, 0.017, brass)
	rod(cup, Vector3(0, 0.063, 0), 0.117, 0.118, 0.017, dark)
	open_cylinder(cup, Vector3(0, 0.193, 0), 0.155, 0.125, 0.303, enamel)
	open_cylinder(cup, Vector3(0, 0.195, 0), 0.145, 0.114, 0.302, liner)
	cup_rim(cup, 0.344, 0.156, 0.009, brass)
	cup_rim(cup, 0.302, 0.151, 0.0025, brass)
	var medallion := rod(cup, Vector3(0, 0.19, 0.141), 0.050, 0.053, 0.014, brass)
	medallion.rotation.x = PI / 2.0
	var insert := rod(cup, Vector3(0, 0.19, 0.151), 0.041, 0.041, 0.009, enamel)
	insert.rotation.x = PI / 2.0
	var mark := block(cup, Vector3(0, 0.19, 0.159), Vector3(0.033, 0.033, 0.006), brass)
	mark.rotation.z = PI / 4.0

	var pens := [
		[Vector3(-0.046, 0.065, 0.018), Vector3(-8, 22, 14), 0.47, "#893c33"],
		[Vector3(0.036, 0.067, -0.022), Vector3(-12, -24, -12), 0.52, "#304b68"],
		[Vector3(0.022, 0.065, 0.042), Vector3(12, 18, -7), 0.43, "#b79568"],
	]
	for spec in pens:
		var pen := make_pen(cup, spec[2], solid(Color(spec[3]), 0.12, 0.32), brass, dark)
		pen.position = spec[0]
		pen.rotation_degrees = spec[1]
	var cedar := solid(Color("#e8be82"))
	var pencil := make_pencil(cup, 0.51, solid(Color("#d9a144")), cedar, dark)
	pencil.position = Vector3(-0.013, 0.064, -0.055)
	pencil.rotation_degrees = Vector3(-9, 0, 2)
	var spare := make_pencil(cup, 0.44, solid(Color("#b85d4a")), cedar, dark)
	spare.position = Vector3(0.052, 0.064, 0.016)
	spare.rotation_degrees = Vector3(8, 16, -12)

func open_cylinder(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, material: Material) -> void:
	var shell := CylinderMesh.new()
	shell.top_radius = top
	shell.bottom_radius = bottom
	shell.height = height
	shell.radial_segments = 48
	shell.rings = 0
	shell.cap_top = false
	shell.cap_bottom = false
	prop(parent, at, shell, material)

func cup_rim(parent: Node3D, y: float, radius: float, thickness: float, material: Material) -> void:
	var rim := TorusMesh.new()
	rim.inner_radius = radius - thickness
	rim.outer_radius = radius + thickness
	rim.rings = 48
	rim.ring_segments = 10
	prop(parent, Vector3(0, y, 0), rim, material)

func make_pen(parent: Node3D, length: float, lacquer: Material, brass: Material, dark: Material) -> Node3D:
	var pen := Node3D.new()
	parent.add_child(pen)
	var cap_base := length - 0.138
	rod(pen, Vector3(0, cap_base * 0.5, 0), 0.015, 0.011, cap_base, lacquer)
	rod(pen, Vector3(0, length - 0.068, 0), 0.018, 0.019, 0.136, lacquer)
	rod(pen, Vector3(0, cap_base + 0.012, 0), 0.020, 0.020, 0.010, brass)
	rod(pen, Vector3(0, length - 0.007, 0), 0.014, 0.018, 0.014, brass)
	rod(pen, Vector3(0, length + 0.003, 0), 0.010, 0.013, 0.006, dark)
	var clip := block(pen, Vector3(0, length - 0.054, 0.023), Vector3(0.009, 0.085, 0.008), brass)
	clip.rotation.x = -0.035
	return pen

func make_pencil(parent: Node3D, length: float, paint: Material, cedar: Material, graphite: Material) -> Node3D:
	var pencil := Node3D.new()
	parent.add_child(pencil)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.013
	barrel.bottom_radius = 0.013
	barrel.radial_segments = 6
	barrel.height = length - 0.057
	prop(pencil, Vector3(0, barrel.height * 0.5, 0), barrel, paint)
	rod(pencil, Vector3(0, length - 0.035, 0), 0.004, 0.013, 0.044, cedar)
	rod(pencil, Vector3(0, length - 0.006, 0), 0.0008, 0.0045, 0.014, graphite)
	return pencil

func build_desk_accessories(wood: Material, brass: Material, dark: Material) -> void:
	var stamp := Node3D.new()
	room.add_child(stamp)
	stamp.position = Vector3(-0.62, 1.089, 2.22)
	var lacquer := solid(Color("#742f28"), 0.14, 0.38)
	rod(stamp, Vector3(0, 0.022, 0), 0.095, 0.103, 0.044, dark)
	rod(stamp, Vector3(0, 0.052, 0), 0.078, 0.090, 0.023, brass)
	rod(stamp, Vector3(0, 0.096, 0), 0.033, 0.047, 0.074, wood)
	dome(stamp, Vector3(0, 0.142, 0), 0.061, 0.054, lacquer)
	rod(stamp, Vector3(0, 0.139, 0), 0.060, 0.047, 0.024, lacquer)

	var notebook := Node3D.new()
	room.add_child(notebook)
	notebook.position = Vector3(0.64, 1.10, 2.48)
	notebook.rotation.y = -0.20
	var cover := surface_material(Color("#784139"), 0)
	var pages := surface_material(Color("#d8c19b"), 0)
	block(notebook, Vector3.ZERO, Vector3(0.40, 0.024, 0.30), cover)
	block(notebook, Vector3(0, 0.025, 0), Vector3(0.382, 0.043, 0.282), pages)
	block(notebook, Vector3(0, 0.049, 0), Vector3(0.40, 0.016, 0.30), cover)
	block(notebook, Vector3(-0.184, 0.022, 0), Vector3(0.034, 0.069, 0.30), lacquer)
	block(notebook, Vector3(0.107, 0.025, 0.16), Vector3(0.024, 0.007, 0.089), solid(Color("#ba8a47")))
	block(notebook, Vector3(0.016, 0.060, 0), Vector3(0.17, 0.005, 0.067), brass)
	for y in [0.016, 0.024, 0.033]:
		block(notebook, Vector3(0.009, y, 0.141), Vector3(0.347, 0.0015, 0.002), solid(Color("#9a7d5a")))

func build_style_details(wood: Material, brass: Material, dark: Material) -> void:
	var starter := style_rooms[0]
	build_desk_phone(starter, brass, dark)
	var calendar := Vector3(-0.67, 2.94, -3.02)
	block(starter, calendar, Vector3(0.19, 0.24, 0.025), solid(Color("#dfc9a0")))
	block(starter, calendar + Vector3(0, 0.094, 0.017), Vector3(0.19, 0.045, 0.012), solid(Color("#824332")))
	door_sign(starter, "ПН", calendar + Vector3(0, -0.01, 0.015)).pixel_size = 0.00142

	var coordinator := style_rooms[1]
	build_desk_phone(coordinator, brass, solid(Color("#30594e"), 0.14, 0.42))
	build_district_map(coordinator, wood, brass)
	build_mail_tray(coordinator, brass)

	var paneling := upgrade(room, 2)
	for x in [-2.13, -0.714, 0.714, 2.13]:
		block(paneling, Vector3(x, 1.32, -3.032), Vector3(0.135, 2.6, 0.094), trim_material)
		block(paneling, Vector3(x, 1.33, -2.973), Vector3(0.025, 2.52, 0.014), door_inset_material)
	block(paneling, Vector3(0, 2.66, -3.02), Vector3(4.36, 0.057, 0.115), trim_material)
	build_wall_sconce(paneling, -1.04, brass)
	build_wall_sconce(paneling, 1.04, brass)

	var council := style_rooms[2]
	build_wall_crest(council, brass, Color("#2e5367"))
	build_desk_phone(council, brass, dark)
	var council_plate := Vector3(1.56, 2.94, -3.02)
	block(council, council_plate, Vector3(0.60, 0.23, 0.031), wood)
	frame_molding(council, council_plate + Vector3(0, 0, 0.023), Vector2(0.55, 0.18), 0.008, brass)
	var caption := door_sign(council, "СОВЕТ ПАРТИИ", council_plate + Vector3(0, 0, 0.04))
	caption.modulate = CREAM
	caption.pixel_size = 0.00092

	var campaign_hq := style_rooms[3]
	build_wall_crest(campaign_hq, brass, Color("#732f39"))
	for side in [-1.0, 1.0]:
		build_banner(campaign_hq, side * 1.53, brass, side > 0)
	var stand := Vector3(-0.17, 1.128, 2.68)
	block(campaign_hq, stand, Vector3(0.46, 0.085, 0.10), door_material)
	block(campaign_hq, stand + Vector3(0, 0.01, 0.053), Vector3(0.40, 0.057, 0.012), brass)
	var plate := door_sign(campaign_hq, "ШТАБ КАМПАНИИ", stand + Vector3(0, 0.01, 0.062))
	plate.pixel_size = 0.00070
	build_desk_phone(campaign_hq, brass, solid(Color("#672f35"), 0.17, 0.39))

func build_district_map(parent: Node3D, wood: Material, brass: Material) -> void:
	var center := Vector3(1.38, 2.95, -3.02)
	block(parent, center, Vector3(0.94, 0.41, 0.05), wood)
	block(parent, center + Vector3(0, 0, 0.028), Vector3(0.87, 0.35, 0.018), solid(Color("#bfa873")))
	frame_molding(parent, center + Vector3(0, 0, 0.04), Vector2(0.91, 0.38), 0.014, brass)
	var river := solid(Color("#526b68"))
	for i in 4:
		var section := block(parent, center + Vector3(-0.31 + i * 0.20, -0.058 + i * 0.029, 0.04), Vector3(0.23, 0.021, 0.006), river)
		section.rotation.z = 0.15
	var marker := solid(Color("#853d34"))
	for offset in [Vector2(-0.24, 0.04), Vector2(0.10, -0.07), Vector2(0.28, 0.095)]:
		var dot := rod(parent, center + Vector3(offset.x, offset.y, 0.048), 0.02, 0.02, 0.009, marker)
		dot.rotation.x = PI / 2.0

func build_mail_tray(parent: Node3D, brass: Material) -> void:
	var center := Vector3(-0.70, 1.114, 2.51)
	block(parent, center, Vector3(0.37, 0.034, 0.31), door_material)
	for side in [-1.0, 1.0]:
		block(parent, center + Vector3(side * 0.176, 0.029, 0), Vector3(0.025, 0.06, 0.31), trim_material)
	block(parent, center + Vector3(0, 0.025, 0.144), Vector3(0.35, 0.039, 0.022), trim_material)
	block(parent, center + Vector3(0, 0.028, 0.157), Vector3(0.11, 0.018, 0.009), brass)
	var paper_stock := solid(Color("#d7c39a"))
	for sheet in 3:
		var note := block(parent, center + Vector3(0, 0.019 + sheet * 0.009, -0.02), Vector3(0.29, 0.008, 0.23), paper_stock)
		note.rotation.y = -0.08 + sheet * 0.04

func build_wall_sconce(parent: Node3D, x: float, brass: Material) -> void:
	block(parent, Vector3(x, 2.93, -3.011), Vector3(0.104, 0.265, 0.045), brass)
	block(parent, Vector3(x, 2.859, -2.93), Vector3(0.033, 0.035, 0.135), brass)
	var shade := solid(Color("#f0c487"), 0.0, 0.65, true)
	rod(parent, Vector3(x, 2.966, -2.875), 0.095, 0.061, 0.145, shade)
	rod(parent, Vector3(x, 3.042, -2.875), 0.092, 0.097, 0.012, brass)

func build_wall_crest(parent: Node3D, brass: Material, color: Color) -> void:
	var center := Vector3(0, 2.97, -3.005)
	var rim := rod(parent, center, 0.178, 0.182, 0.041, brass)
	rim.rotation.x = PI / 2.0
	var field := rod(parent, center + Vector3(0, 0, 0.026), 0.147, 0.147, 0.018, solid(color))
	field.rotation.x = PI / 2.0
	for i in 3:
		block(parent, center + Vector3((i - 1) * 0.047, -0.014, 0.039), Vector3(0.02, 0.087, 0.009), brass)
	block(parent, center + Vector3(0, -0.069, 0.039), Vector3(0.165, 0.014, 0.009), brass)
	for side in [-1.0, 1.0]:
		var roof := block(parent, center + Vector3(side * 0.042, 0.064, 0.039), Vector3(0.105, 0.016, 0.009), brass)
		roof.rotation.z = -side * 0.43

func build_banner(parent: Node3D, x: float, brass: Material, blue: bool) -> void:
	var cloth := surface_material(Color("#294954") if blue else Color("#7f3c45"), 0)
	block(parent, Vector3(x, 2.948, -2.975), Vector3(0.41, 0.46, 0.017), cloth)
	block(parent, Vector3(x, 3.194, -2.962), Vector3(0.51, 0.027, 0.031), brass)
	frame_molding(parent, Vector3(x, 2.948, -2.961), Vector2(0.35, 0.397), 0.009, brass)
	var emblem := block(parent, Vector3(x, 2.95, -2.944), Vector3(0.14, 0.14, 0.006), brass)
	emblem.rotation.z = PI / 4.0
	var field := block(parent, Vector3(x, 2.95, -2.939), Vector3(0.096, 0.096, 0.005), cloth)
	field.rotation.z = PI / 4.0

func build_desk_phone(parent: Node3D, brass: Material, housing: Material) -> void:
	var phone := Node3D.new()
	parent.add_child(phone)
	phone.position = PHONE_POSITION
	phone.rotation.y = -0.18
	block(phone, Vector3(0, 0.035, 0), Vector3(0.33, 0.07, 0.29), housing)
	var dial := Vector3(0, 0.073, 0.035)
	rod(phone, dial, 0.085, 0.09, 0.017, brass)
	for hole in 8:
		var angle := hole * TAU / 8.0
		rod(phone, dial + Vector3(sin(angle) * 0.062, 0.011, cos(angle) * 0.062), 0.011, 0.011, 0.006, housing)
	block(phone, Vector3(0, 0.089, -0.092), Vector3(0.27, 0.045, 0.047), housing)
	for side in [-1.0, 1.0]:
		rod(phone, Vector3(side * 0.115, 0.092, -0.088), 0.049, 0.044, 0.068, housing)

func surface_material(tint: Color, finish: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("finish", finish)
	return material

func solid(tint: Color, metallic := 0.0, roughness := 0.8, luminous := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = luminous
	if luminous:
		material.emission = tint
		material.emission_energy_multiplier = 0.7
	return material

func block(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return prop(parent, at, mesh, material)

func rod(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 40
	mesh.rings = 1
	return prop(parent, at, mesh, material)

func dome(parent: Node3D, at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height * 2.0
	mesh.is_hemisphere = true
	mesh.radial_segments = 48
	mesh.rings = 16
	return prop(parent, at, mesh, material)

func prop(parent: Node3D, at: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	object.mesh = mesh
	object.material_override = material
	parent.add_child(object)
	object.position = at
	return object

func light_at(at: Vector3, color: Color, energy: float, reach: float, shadows := false) -> void:
	var lamp := OmniLight3D.new()
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = reach
	lamp.shadow_enabled = shadows
	room.add_child(lamp)
	lamp.position = at
