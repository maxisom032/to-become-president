extends Node3D

const Catalog := preload("res://game/offices/office_catalog.gd")
const SURFACE := preload("res://game/office_surface.gdshader")
var camera: Camera3D
var layout_signature := ""
var targets: Dictionary = {}
var door_hinge: Node3D
var opened := false
var moving: Tween
var mats: Dictionary = {}

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "SeatedCamera"
	add_child(camera)
	camera.position = Vector3(0, 1.65, 4.1)
	camera.look_at(Vector3(0, 1.04, -2.7))
	camera.fov = 74.0
	camera.current = true
	build(0)

func material(color: String, finish: int = -1) -> Material:
	var key := color + str(finish)
	if mats.has(key):
		return mats[key]
	var result: Material
	if finish >= 0:
		var painted := ShaderMaterial.new()
		painted.shader = SURFACE
		painted.set_shader_parameter("tint", Color(color))
		painted.set_shader_parameter("finish", finish)
		result = painted
	else:
		var plain := StandardMaterial3D.new()
		plain.albedo_color = Color(color)
		plain.roughness = 0.84
		result = plain
	mats[key] = result
	return result

func box(parent: Node3D, at: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = mat
	parent.add_child(node)
	return node

func build(index: int) -> void:
	if moving != null:
		moving.kill()
	for child in get_children():
		if child != camera:
			remove_child(child)
			child.queue_free()
	targets.clear()
	opened = false
	var spec: Dictionary = Catalog.ROOMS[clampi(index, 0, 5)]
	var focus_x: float = [0.0, -0.1, -0.4, -0.6, 0.7, -0.1][clampi(index, 0, 5)]
	camera.look_at(Vector3(focus_x, 1.04, -2.7))
	layout_signature = spec.layout
	var width: float = spec.width
	var back: float = spec.back
	var height: float = spec.height
	var wall := material(spec.wall, 2)
	var wood := material("#805a3c" if index < 3 else "#624331", 3)
	var trim := material("#c5b38e" if index < 2 else "#a28052", 1)
	var floor_mat := material("#74695a" if index < 2 else "#77624b", 3)
	var floor_depth := 4.2 - back
	box(self, Vector3(0, -0.08, (back + 4.2) / 2.0), Vector3(width, 0.16, floor_depth), floor_mat)
	box(self, Vector3(0, height, (back + 4.2) / 2.0), Vector3(width, 0.12, floor_depth), material("#c9c4ae"))
	for side in [-1, 1]:
		box(self, Vector3(side * width / 2.0, height / 2.0, (back + 4.2) / 2.0), Vector3(0.12, height, floor_depth), wall)
		box(self, Vector3(side * (width / 2.0 - 0.08), 0.16, (back + 4.2) / 2.0), Vector3(0.08, 0.25, floor_depth), trim)
	# The back wall has an actual opening, not a door painted on a solid wall.
	var door_x: float = [0.15, 1.0, 2.15, 2.25, -1.0, 2.75][clampi(index, 0, 5)]
	var door_width := 1.08
	var left_edge := door_x - door_width / 2.0
	var right_edge := door_x + door_width / 2.0
	box(self, Vector3((-width / 2.0 + left_edge) / 2.0, height / 2.0, back), Vector3(left_edge + width / 2.0, height, 0.14), wall)
	box(self, Vector3((right_edge + width / 2.0) / 2.0, height / 2.0, back), Vector3(width / 2.0 - right_edge, height, 0.14), wall)
	box(self, Vector3(door_x, (height + 2.3) / 2.0, back), Vector3(door_width, height - 2.3, 0.14), wall)
	build_door(Vector3(door_x, 0, back + 0.09), wood, trim)
	build_lighting(index, height, back)
	build_desk(Vector3(0, 0, 1.72), wood, index, true)
	if index >= 2:
		box(self, Vector3(-0.2, 0.015, -1.8), Vector3(3.4, 0.02, 4.2), material("#69534a" if index < 4 else "#40575a"))
	match index:
		0:
			build_hall(wood, trim)
		1:
			build_shared(wood, back)
		2:
			build_regional(wood, back, width)
		3:
			build_council(wood, back, width)
		4:
			build_reception(wood, back, width)
		5:
			build_leader(wood, back, width)

func build_lighting(index: int, height: float, back: float) -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#344653")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#dce4e3")
	env.ambient_light_energy = 0.6
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#ffe4b6")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, height - 0.4, -0.5)
	fill.omni_range = 10.0
	fill.light_color = Color("#ffe4b8")
	fill.light_energy = 0.8
	add_child(fill)
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color("#fff3cb")
	lamp.emission_enabled = true
	lamp.emission = Color("#fff3cb")
	if index == 0:
		for z in [1.0, -1.7, -4.3, back + 1.0]:
			box(self, Vector3(0, height - 0.12, z), Vector3(1.5, 0.1, 0.35), lamp)
	else:
		cylinder(self, Vector3(0, height - 0.3, -0.8), 0.35 if index < 3 else 0.5, 0.15, material("#bba16d"))
		cylinder(self, Vector3(0, height - 0.39, -0.8), 0.3 if index < 3 else 0.45, 0.025, lamp)

func build_door(at: Vector3, wood: Material, trim: Material) -> void:
	box(self, at + Vector3(-0.61, 1.18, 0), Vector3(0.12, 2.48, 0.18), trim)
	box(self, at + Vector3(0.61, 1.18, 0), Vector3(0.12, 2.48, 0.18), trim)
	box(self, at + Vector3(0, 2.37, 0), Vector3(1.34, 0.13, 0.18), trim)
	door_hinge = Node3D.new()
	door_hinge.position = at + Vector3(-0.54, 0, 0)
	add_child(door_hinge)
	box(door_hinge, Vector3(0.54, 1.12, 0), Vector3(1.08, 2.24, 0.08), wood)
	for y in [0.62, 1.65]:
		box(door_hinge, Vector3(0.54, y, 0.052), Vector3(0.84, 0.8, 0.045), material("#73533a", 1))
	box(door_hinge, Vector3(0.94, 1.08, 0.1), Vector3(0.19, 0.045, 0.055), material("#c2a36c"))
	box(door_hinge, Vector3(0.54, 1.76, 0.09), Vector3(0.56, 0.2, 0.025), material("#d4c28c"))
	var label := Label3D.new()
	label.text = "ВЫХОД"
	label.font_size = 48
	label.pixel_size = 0.0017
	label.outline_size = 0
	label.modulate = Color("#2d3c3b")
	label.position = Vector3(0.54, 1.76, 0.11)
	door_hinge.add_child(label)
	target("door", at + Vector3(0, 1.3, 0.16), Vector3(1.1, 2.15, 0.2))
	# Hall/reception behind the opening remains visible when the door swings.
	box(self, at + Vector3(0, 1.3, -1.5), Vector3(2.4, 2.6, 0.12), material("#b1ac96", 2))
	box(self, at + Vector3(0, -0.01, -0.7), Vector3(2.4, 0.08, 1.6), material("#7a6d59", 3))

func build_desk(at: Vector3, wood: Material, index: int, interactive: bool = false) -> void:
	var desk := Node3D.new()
	desk.position = at
	add_child(desk)
	var width := 2.15 if interactive else 1.45
	if index >= 4 and interactive:
		width = 2.8
	box(desk, Vector3(0, 0.87, 0), Vector3(width, 0.12, 2.4 if interactive else 1.22), wood)
	if interactive:
		box(desk, Vector3(0, 0.817, 0), Vector3(width - 0.06, 0.045, 2.34), material("#b69868", 1))
	for x in [-width / 2.0 + 0.13, width / 2.0 - 0.13]:
		box(desk, Vector3(x, 0.42, 0), Vector3(0.16, 0.84, 1.05), wood)
	box(desk, Vector3(0, 0.48, -0.43), Vector3(width - 0.25, 0.45, 0.07), wood)
	box(desk, Vector3(0, 0.937, 0.25), Vector3(width * 0.75, 0.014, 1.75 if interactive else 0.9), material("#394b4c" if index < 3 else "#623e3c"))
	if not interactive:
		box(desk, Vector3(0, 1.15, -0.22), Vector3(0.55, 0.35, 0.05), material("#333e40"))
		cylinder(desk, Vector3(0, 0.96, -0.22), 0.11, 0.04, material("#333e40"))
		return
	# These are solid meshes with independent 3D click targets.
	var folder_at := at + Vector3(-0.07, 0.964, 0.12)
	box(self, folder_at, Vector3(0.55, 0.035, 0.42), material("#b28b54"))
	box(self, folder_at + Vector3(0.01, 0.025, 0.01), Vector3(0.49, 0.018, 0.35), material("#eadcbb"))
	box(self, folder_at + Vector3(0.0, 0.039, -0.02), Vector3(0.55, 0.012, 0.42), material("#af754b"))
	box(self, folder_at + Vector3(0.12, 0.05, -0.13), Vector3(0.18, 0.008, 0.07), material("#d4b66c"))
	for line in 3:
		box(self, folder_at + Vector3(-0.05, 0.049, -0.03 + line * 0.035), Vector3(0.23, 0.003, 0.008), material("#654e39"))
	target("folder", folder_at + Vector3(0, 0.04, 0), Vector3(0.61, 0.14, 0.47))
	var phone_at := at + Vector3(-0.34, 1.005, -0.4)
	box(self, phone_at, Vector3(0.34, 0.13, 0.32), material("#ddd0ae"))
	box(self, phone_at + Vector3(0, 0.11, -0.08), Vector3(0.43, 0.075, 0.12), material("#d2c5a2"))
	for x in 3:
		for z in 3:
			box(self, phone_at + Vector3(-0.07 + x * 0.07, 0.072, -0.025 + z * 0.06), Vector3(0.045, 0.015, 0.04), material("#5d6560"))
	target("phone", phone_at + Vector3(0, 0.06, 0), Vector3(0.47, 0.28, 0.4))
	var planner_at := at + Vector3(0.35, 0.99, -0.38)
	box(self, planner_at, Vector3(0.32, 0.06, 0.28), material("#35556a"))
	box(self, planner_at + Vector3(0, 0.035, 0), Vector3(0.27, 0.01, 0.22), material("#dfd0ae"))
	target("agenda", planner_at + Vector3(0, 0.03, 0), Vector3(0.38, 0.16, 0.34))
	lamp_prop(at + Vector3(0.87, 0.95, -0.4))
	if index >= 4:
		box(self, at + Vector3(-1.55, 0.84, -0.7), Vector3(0.8, 0.12, 2.1), wood)

func lamp_prop(at: Vector3) -> void:
	var brass := material("#ba9652")
	cylinder(self, at, 0.12, 0.035, brass)
	cylinder(self, at + Vector3(0, 0.2, 0), 0.018, 0.4, brass)
	var shade := CylinderMesh.new()
	shade.top_radius = 0.12
	shade.bottom_radius = 0.23
	shade.height = 0.14
	var node := MeshInstance3D.new()
	node.mesh = shade
	node.material_override = material("#c99f54")
	node.position = at + Vector3(0, 0.41, 0)
	add_child(node)

func chair(at: Vector3, color: String = "#704d43", angle: float = 0.0) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = angle
	add_child(root)
	var upholstery := material(color)
	var frame := material("#63533f", 1)
	box(root, Vector3(0, 0.47, 0), Vector3(0.55, 0.12, 0.55), upholstery)
	box(root, Vector3(0, 0.85, 0.23), Vector3(0.55, 0.7, 0.09), upholstery)
	for x in [-0.22, 0.22]:
		for z in [-0.2, 0.2]:
			box(root, Vector3(x, 0.23, z), Vector3(0.05, 0.46, 0.05), frame)
		box(root, Vector3(x * 1.3, 0.7, 0), Vector3(0.07, 0.06, 0.6), frame)

func shelf(at: Vector3, width: float = 1.2) -> void:
	var wood := material("#805e40", 1)
	for x in [-width / 2.0, width / 2.0]:
		box(self, at + Vector3(x, 1.15, 0), Vector3(0.09, 2.3, 0.4), wood)
	for row in 5:
		box(self, at + Vector3(0, 0.12 + row * 0.5, 0), Vector3(width, 0.065, 0.4), wood)
		for book in 6:
			var color: String = ["#8b5345", "#c5ae73", "#425a60", "#746f49"][book % 4]
			box(self, at + Vector3(-width * 0.4 + book * width * 0.14, 0.32 + row * 0.5, 0.02), Vector3(width * 0.105, 0.28 + (book % 3) * 0.04, 0.22), material(color))

func back_window(at: Vector3, width: float, height: float) -> void:
	var sky := StandardMaterial3D.new()
	sky.albedo_color = Color("#a7c7cc")
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box(self, at, Vector3(width, height, 0.03), sky)
	for i in 8:
		var h := 0.25 + (i * 3 % 5) * 0.13
		box(self, at + Vector3(-width * 0.43 + i * width * 0.12, -height / 2.0 + h / 2.0 + 0.1, 0.03), Vector3(width * 0.085, h, 0.06), material("#819799"))
	for y in [-height / 2.0, 0.0, height / 2.0]:
		box(self, at + Vector3(0, y, 0.08), Vector3(width + 0.1, 0.065, 0.12), material("#d1c2a3"))
	for x in [-width / 2.0, -width / 6.0, width / 6.0, width / 2.0]:
		box(self, at + Vector3(x, 0, 0.08), Vector3(0.06, height, 0.12), material("#d1c2a3"))

func wall_map(at: Vector3, width: float = 1.6) -> void:
	box(self, at, Vector3(width + 0.12, 1.0, 0.08), material("#735239", 1))
	box(self, at + Vector3(0, 0, 0.05), Vector3(width, 0.88, 0.02), material("#c7ba91"))
	for i in 7:
		var x := -width * 0.35 + i * width * 0.11
		var patch := box(self, at + Vector3(x, sin(i * 2.0) * 0.2, 0.075), Vector3(width * 0.17, 0.22, 0.01), material(["#8d9b77", "#b1a178", "#81978b"][i % 3]))
		patch.rotation.z = i * 0.4

func window_left(width: float, back: float, height: float = 2.6) -> void:
	# Painted sky and modelled skyline sit in a recessed window assembly.
	var x := -width / 2.0 + 0.1
	var z := back / 2.0
	var sky := StandardMaterial3D.new()
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky.albedo_color = Color("#a2c8d3")
	box(self, Vector3(x + 0.025, height / 2.0 + 0.45, z), Vector3(0.03, height, absf(back) * 0.65), sky)
	for i in 9:
		var tower_height := 0.3 + (i * 7 % 5) * 0.17
		box(self, Vector3(x + 0.052, 0.9 + tower_height / 2.0, z - 1.2 + i * 0.3), Vector3(0.04, tower_height, 0.22), material("#81999d"))
	for y in [0.45, height + 0.45]:
		box(self, Vector3(x + 0.08, y, z), Vector3(0.12, 0.1, absf(back) * 0.65 + 0.1), material("#465353"))
	for i in 5:
		box(self, Vector3(x + 0.09, height / 2.0 + 0.45, z - absf(back) * 0.325 + i * absf(back) * 0.1625), Vector3(0.14, height, 0.06), material("#465353"))

func meeting_table(at: Vector3, wood: Material, length: float = 2.4) -> void:
	box(self, at + Vector3(0, 0.78, 0), Vector3(1.1, 0.09, length), wood)
	for z in [-length * 0.3, length * 0.3]:
		box(self, at + Vector3(0, 0.38, z), Vector3(0.55, 0.76, 0.12), wood)
		chair(at + Vector3(-0.95, 0, z), "#4e6264", -PI / 2.0)
		chair(at + Vector3(0.95, 0, z), "#4e6264", PI / 2.0)

func build_hall(wood: Material, trim: Material) -> void:
	var fabric := material("#778579")
	for x in [-1.18, 1.18]:
		box(self, Vector3(x, 0.66, 1.4), Vector3(0.07, 1.32, 2.6), fabric)
	box(self, Vector3(0, 0.46, 0.18), Vector3(2.35, 0.92, 0.07), fabric)
	for z in [-1.4, -3.6, -5.8]:
		for x in [-1.95, 1.95]:
			build_desk(Vector3(x, 0, z), wood, 0)
			chair(Vector3(x, 0, z + 0.75), "#525f60")
			box(self, Vector3(x - 0.9, 0.64, z), Vector3(0.06, 1.28, 1.9), fabric)
	for x in [-4.9, -2.0, 2.0, 4.9]:
		box(self, Vector3(x, 1.65, -6.8), Vector3(0.18, 3.3, 0.18), trim)
	box(self, Vector3(2.4, 0.6, -0.1), Vector3(0.8, 1.2, 0.65), material("#c2bca9"))
	box(self, Vector3(2.4, 1.24, -0.1), Vector3(0.8, 0.1, 0.65), material("#46504b"))
	back_window(Vector3(-2.65, 1.8, -7.05), 2.5, 1.7)
	back_window(Vector3(2.75, 1.8, -7.05), 2.2, 1.7)

func build_shared(wood: Material, back: float) -> void:
	back_window(Vector3(-0.7, 2.25, back + 0.1), 1.3, 0.55)
	build_desk(Vector3(-1.25, 0, -1.65), wood, 1)
	chair(Vector3(-1.25, 0, -0.8))
	box(self, Vector3(-1.7, 0.95, back + 0.4), Vector3(0.65, 1.9, 0.55), material("#7b8175"))
	for y in [0.4, 0.9, 1.4]:
		box(self, Vector3(-1.7, y, back + 0.7), Vector3(0.5, 0.03, 0.04), material("#b9b7a4"))
	for i in 3:
		box(self, Vector3(-0.55, 0.18 + i * 0.35, back + 0.5), Vector3(0.6, 0.32, 0.5), material("#a78c5d"))
	wall_map(Vector3(-0.5, 1.25, back + 0.1), 1.0)

func build_regional(wood: Material, back: float, width: float) -> void:
	window_left(width, back)
	back_window(Vector3(-1.35, 1.75, back + 0.1), 2.3, 2.0)
	shelf(Vector3(0.45, 0, back + 0.32), 0.8)
	chair(Vector3(-1.25, 0, -0.6), "#536d62", PI)
	box(self, Vector3(-1.35, 0.4, back + 0.35), Vector3(2.3, 0.8, 0.5), wood)

func build_council(wood: Material, back: float, width: float) -> void:
	window_left(width, back, 2.8)
	meeting_table(Vector3(-1.4, 0, -2.3), wood)
	shelf(Vector3(-2.8, 0, back + 0.32), 1.8)
	wall_map(Vector3(-0.7, 1.8, back + 0.1), 1.7)
	# Slender glass-room mullions distinguish the council architecture.
	for z in [-1.0, -2.8, -4.6]:
		box(self, Vector3(3.85, 1.6, z), Vector3(0.065, 3.2, 0.065), material("#869793"))

func build_reception(wood: Material, back: float, width: float) -> void:
	window_left(width, back, 3.0)
	back_window(Vector3(1.9, 1.95, back + 0.1), 2.5, 2.3)
	chair(Vector3(-1.6, 0, -2.6), "#69745b", -PI / 2.0)
	chair(Vector3(-1.6, 0, -4.0), "#69745b", -PI / 2.0)
	box(self, Vector3(-1.9, 0.48, -3.5), Vector3(0.9, 0.08, 1.25), wood)
	box(self, Vector3(-1.9, 0.23, -3.5), Vector3(0.2, 0.46, 0.75), wood)
	# A separate reception office beyond a large glazed inner opening.
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.6, 0.78, 0.78, 0.13)
	box(self, Vector3(1.9, 1.2, -3.0), Vector3(0.025, 2.4, 2.8), glass)
	for z in [-4.4, -3.0, -1.6]:
		box(self, Vector3(1.9, 1.25, z), Vector3(0.07, 2.5, 0.07), material("#a2a895"))
	build_desk(Vector3(2.65, 0, -4.5), wood, 4)
	shelf(Vector3(-2.7, 0, back + 0.35), 1.4)

func build_leader(wood: Material, back: float, width: float) -> void:
	window_left(width, back, 3.35)
	meeting_table(Vector3(-1.4, 0, -4.25), wood, 3.1)
	box(self, Vector3(-0.65, 0.35, back + 0.35), Vector3(2.0, 0.7, 0.6), wood)
	back_window(Vector3(-1.4, 2.0, back + 0.1), 4.5, 2.9)
	for x in [-2.4, 0.0, 2.4]:
		box(self, Vector3(x, 3.85, -2.6), Vector3(0.12, 0.13, 7.6), material("#ac9668"))
	# A second bank of tall glazing gives a distinct corner-office footprint.
	var sky := StandardMaterial3D.new()
	sky.albedo_color = Color("#9dbec9")
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box(self, Vector3(4.5, 2.0, back + 0.1), Vector3(0.85, 3.0, 0.025), sky)
	for x in [4.1, 4.9]:
		box(self, Vector3(x, 2.0, back + 0.15), Vector3(0.06, 3.1, 0.06), material("#43545b"))

func target(id: String, center: Vector3, dimensions: Vector3) -> void:
	var area := Area3D.new()
	area.name = "Target_" + id
	area.position = center
	area.collision_layer = 1
	area.collision_mask = 0
	area.set_meta("interaction_id", id)
	var shape := CollisionShape3D.new()
	var volume := BoxShape3D.new()
	volume.size = dimensions
	shape.shape = volume
	area.add_child(shape)
	add_child(area)
	targets[id] = area

func screen_position(id: String) -> Vector2:
	if not targets.has(id):
		return Vector2(-100, -100)
	return camera.unproject_position(targets[id].global_position)

func pick_object(screen: Vector2) -> String:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 50.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	return str(hit.collider.get_meta("interaction_id", ""))

func animate_door(open: bool) -> void:
	opened = open
	if moving != null:
		moving.kill()
	moving = create_tween()
	moving.tween_property(door_hinge, "rotation:y", deg_to_rad(-88.0) if open else 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
