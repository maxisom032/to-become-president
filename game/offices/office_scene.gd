extends Node3D

const Catalog := preload("res://game/offices/office_catalog.gd")
const PaintedSurface := preload("res://game/offices/surface_material.gdshader")
const BeveledMesh := preload("res://game/offices/beveled_mesh.gd")
const DeskDetails := preload("res://game/offices/desk_details.gd")
const WindowView := preload("res://game/offices/window_view.gd")
const ReadyProps := preload("res://game/offices/ready_props.gd")
const RoomDressing := preload("res://game/offices/room_dressing.gd")
const WoodTexture := preload("res://game/offices/assets/textures/oak-painted.png")
const WallTexture := preload("res://game/offices/assets/textures/plaster-painted.png")
const LeatherTexture := preload("res://game/offices/assets/textures/leather-painted.png")
const FabricTexture := preload("res://game/offices/assets/textures/fabric.png")
const MapTexture := preload("res://game/offices/assets/textures/district_map.png")
var camera: Camera3D
var layout_signature := ""
var targets: Dictionary = {}
var door_hinge: Node3D
var opened := false
var moving: Tween
var mats: Dictionary = {}
var windows: Array[Node3D] = []
var folder_hinge: Node3D
var folder_center := Vector3.ZERO
var resting_camera := Transform3D.IDENTITY
var focus_motion: Tween
var folder_focused := false
var room_index := 0
var desk_markers: Dictionary = {}
const DESK_FOV := 42.0

func desk_fov() -> float:
	var dimensions := get_viewport().get_visible_rect().size
	var ratio := dimensions.x/maxf(dimensions.y,1.0)
	return maxf(DESK_FOV,rad_to_deg(2.0*atan(tan(deg_to_rad(45.0)/2.0)*ratio)))

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "SeatedCamera"
	add_child(camera)
	camera.position = Vector3(0, 1.65, 4.1)
	camera.look_at(Vector3(0, 1.04, -2.7))
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = desk_fov()
	camera.current = true
	build(0)

func material(color: String, finish: int = -1) -> Material:
	var key := color + str(finish)
	if mats.has(key):
		return mats[key]
	var result: Material
	if finish >= 0:
		var painted := ShaderMaterial.new()
		painted.shader = PaintedSurface
		painted.set_shader_parameter("tint", Color(color))
		painted.set_shader_parameter("wallpaper", min(room_index,3) if finish==2 else 0)
		var kind := 1 if finish in [1,3,4] else (2 if finish == 5 else (3 if finish == 6 else (4 if finish == 7 else 0)))
		painted.set_shader_parameter("surface_kind", kind)
		painted.set_shader_parameter("surface_tex", WoodTexture if kind in [1,2] else (FabricTexture if kind == 3 else (LeatherTexture if kind == 4 else WallTexture)))
		result = painted
	else:
		var plain := StandardMaterial3D.new()
		plain.albedo_color = Color(color)
		plain.roughness = 0.48
		if color in ["#ba9652","#b59961","#c2a36c","#aa956a"]:
			plain.metallic = 0.65
			plain.roughness = 0.28
		result = plain
	mats[key] = result
	return result

func box(parent: Node3D, at: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = BeveledMesh.create(dimensions)
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = mat
	parent.add_child(node)
	return node

func build(index: int) -> void:
	room_index = clampi(index,0,5)
	desk_markers.clear()
	if focus_motion != null:
		focus_motion.kill()
	folder_focused = false
	windows.clear()
	folder_hinge = null
	if moving != null:
		moving.kill()
	for child in get_children():
		if child != camera:
			remove_child(child)
			child.queue_free()
	targets.clear()
	opened = false
	var spec: Dictionary = Catalog.ROOMS[clampi(index, 0, 5)]
	camera.position = Vector3(0, 2.25, 4.25)
	camera.fov = desk_fov()
	camera.look_at(Vector3(0, 1.5, -0.5))
	resting_camera = camera.transform
	layout_signature = spec.layout
	var width: float = spec.width
	var back: float = spec.back
	var height: float = spec.height
	var wall := material(spec.wall, 2)
	var wood := material("#805a3c" if index < 3 else "#624331", 3)
	var trim := material("#c5b38e" if index < 2 else "#a28052", 1)
	var floor_mat := material("#a48b6a" if index < 2 else "#9e7e57", 5)
	var floor_depth := 4.2 - back
	box(self, Vector3(0, -0.08, (back + 4.2) / 2.0), Vector3(width, 0.16, floor_depth), floor_mat)
	box(self, Vector3(0, height, (back + 4.2) / 2.0), Vector3(width, 0.12, floor_depth), material("#c9c4ae",0))
	for side in [-1, 1]:
		box(self, Vector3(side * width / 2.0, height / 2.0, (back + 4.2) / 2.0), Vector3(0.12, height, floor_depth), wall)
		box(self, Vector3(side * (width / 2.0 - 0.08), 0.16, (back + 4.2) / 2.0), Vector3(0.08, 0.25, floor_depth), trim)
	# The back wall has an actual opening, not a door painted on a solid wall.
	var door_x: float = [0.15, 1.0, 2.15, 3.6, -3.8, 5.5][clampi(index, 0, 5)]
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
		box(self, Vector3(-0.2, 0.015, -1.8), Vector3(3.4, 0.02, 4.2), material("#69534a" if index < 4 else "#40575a", 6))
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
	var window_sizes := [Vector2(1.35,0.78),Vector2(1.45,0.9),Vector2(2.6,1.8),Vector2(4.2,2.6),Vector2(6.0,3.2),Vector2(8.2,4.0)]
	var window_size: Vector2 = window_sizes[index]
	var window_x: float = [-1.4,-0.8,-1.35,-0.8,2.0,-0.7][index]
	if index > 0:
		back_window(Vector3(window_x,1.0+window_size.y/2.0,back+0.1),window_size.x,window_size.y)
	DeskDetails.extras(self, Vector3(0,0,1.72), index)
	RoomDressing.add_details(self,spec,index)
	RoomDressing.clock(self,Vector3(door_x-0.95,2.5,back+0.23))
	if index>=3:
		RoomDressing.chandelier(self,Vector3(0,2.65,back+2.0),height,index)

func build_lighting(index: int, height: float, back: float) -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#344653")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#ffe9ca")
	env.ambient_light_energy = 0.52
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.ssao_enabled = true
	env.ssao_radius = 0.55
	env.ssao_intensity = 1.7
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#ffe4b6")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 1.7, 1.0)
	fill.omni_range = 10.0
	fill.light_color = Color("#ffe4b8")
	fill.light_energy = 0.32
	add_child(fill)
	var desk_key := OmniLight3D.new()
	desk_key.position=Vector3(-1.3,2.25,2.4)
	desk_key.light_color=Color("#ffe4bd")
	desk_key.light_energy=1.1
	desk_key.omni_range=6.0
	desk_key.shadow_enabled=true
	add_child(desk_key)
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
		for side in [-1,1]:
			box(door_hinge,Vector3(0.54+side*0.4,y,0.083),Vector3(0.025,0.76,0.018),trim)
			box(door_hinge,Vector3(0.54,y+side*0.38,0.083),Vector3(0.8,0.025,0.018),trim)
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
	var width := 2.5 if interactive else 1.45
	if index >= 4 and interactive:
		width = 2.8
	box(desk, Vector3(0, 0.87, 0), Vector3(width, 0.12, 3.6 if interactive else 1.22), wood)
	if interactive:
		box(desk, Vector3(0, 0.817, 0), Vector3(width - 0.06, 0.045, 3.54), material("#b69868", 1))
	for x in [-width / 2.0 + 0.13, width / 2.0 - 0.13]:
		box(desk, Vector3(x, 0.42, 0), Vector3(0.16, 0.84, 1.05), wood)
	box(desk, Vector3(0, 0.48, -0.43), Vector3(width - 0.25, 0.45, 0.07), wood)
	box(desk, Vector3(0, 0.937, 0.25), Vector3(1.85 if interactive else width*0.75, 0.014, 2.1 if interactive else 0.9), material("#394b4c" if index < 3 else "#623e3c", 7 if interactive and index>0 else 6))
	if not interactive:
		box(desk, Vector3(0, 1.15, -0.22), Vector3(0.55, 0.35, 0.05), material("#333e40"))
		cylinder(desk, Vector3(0, 0.96, -0.22), 0.11, 0.04, material("#333e40"))
		return
	# These are solid meshes with independent 3D click targets.
	folder_center = at + Vector3(-0.03, 0.96, 0.14)
	folder_hinge = DeskDetails.folder(self, folder_center)
	target("folder", folder_center + Vector3(0,0.05,0), Vector3(0.82,0.15,0.91))
	var phone_at := at + Vector3(-0.52, 1.005, -0.4)
	DeskDetails.phone(self, phone_at)
	target("phone", phone_at + Vector3(0,0.06,0), Vector3(0.47,0.28,0.4))
	var planner_at := at + Vector3(0.57, 0.99, -0.08)
	box(self, planner_at, Vector3(0.32, 0.06, 0.28), material("#35556a"))
	box(self, planner_at + Vector3(0, 0.035, 0), Vector3(0.27, 0.01, 0.22), material("#dfd0ae"))
	target("agenda", planner_at + Vector3(0, 0.03, 0), Vector3(0.38, 0.16, 0.34))
	lamp_prop(at + Vector3(0.69, 0.95, -0.4))
	desk_markers["lamp_left"] = at+Vector3(0.45,1.36,-0.4)
	desk_markers["lamp_right"] = at+Vector3(0.93,1.36,-0.4)
	desk_markers["phone_left"] = phone_at+Vector3(-0.24,0.0,0.0)
	if index >= 4:
		box(self, at + Vector3(-1.55, 0.84, -0.7), Vector3(0.8, 0.12, 2.1), wood)

func lamp_prop(at: Vector3) -> void:
	DeskDetails.lamp(self,at)

func chair(at: Vector3, color: String = "#704d43", angle: float = 0.0) -> void:
	ReadyProps.place(self,"chairCushion",at,0.9,angle)

func shelf(at: Vector3, width: float = 1.2) -> void:
	var wood := material("#805e40", 1)
	for x in [-width / 2.0, width / 2.0]:
		box(self, at + Vector3(x, 1.15, 0), Vector3(0.09, 2.3, 0.4), wood)
	for row in 5:
		box(self, at + Vector3(0, 0.12 + row * 0.5, 0), Vector3(width, 0.065, 0.4), wood)
		for book in 6:
			var color: String = ["#8b5345", "#c5ae73", "#425a60", "#746f49"][book % 4]
			box(self, at + Vector3(-width * 0.4 + book * width * 0.14, 0.32 + row * 0.5, 0.02), Vector3(width * 0.105, 0.28 + (book % 3) * 0.04, 0.22), material(color))
			for band_y in [-0.07,0.07]:
				box(self,at+Vector3(-width*0.4+book*width*0.14,0.32+row*0.5+band_y,0.135),Vector3(width*0.08,0.009,0.005),material("#c2ad7a"))

func back_window(at: Vector3, width: float, height: float) -> void:
	var view := WindowView.new()
	view.position = at
	add_child(view)
	view.setup(self, Vector2(width,height))
	windows.append(view)
	var dark_frame := material("#37483f",1)
	for x in [-width/2.0,width/2.0]:
		box(self,at+Vector3(x,0,0.18),Vector3(0.13,height+0.18,0.28),material("#a58d64",1))
	for y in [-height/2.0,0.0,height/2.0]:
		box(self, at+Vector3(0,y,0.26),Vector3(width+0.14,0.05,0.14),dark_frame)
	for x in [-width/2.0,-width/6.0,width/6.0,width/2.0]:
		box(self,at+Vector3(x,0,0.26),Vector3(0.045,height,0.14),dark_frame)
	box(self,at+Vector3(0,-height/2.0-0.06,0.3),Vector3(width+0.25,0.1,0.38),material("#b59f78",1))
	var key := SpotLight3D.new()
	key.position=at+Vector3(-width*0.25,height*0.3,0.45)
	key.light_color=Color("#ffe2b0")
	key.light_energy=0.45
	key.light_specular=0.25
	key.spot_range=12.0
	key.spot_angle=52
	key.spot_attenuation=0.4
	key.shadow_enabled=true
	add_child(key)
	key.look_at(Vector3(0,0.8,1.7))

func wall_map(at: Vector3, width: float = 1.6) -> void:
	box(self,at,Vector3(width+0.14,1.04,0.08),material("#735239",1))
	var mesh := QuadMesh.new()
	mesh.size=Vector2(width,0.9)
	var poster := MeshInstance3D.new()
	poster.mesh=mesh
	poster.position=at+Vector3(0,0,0.055)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture=MapTexture
	mat.roughness=1.0
	poster.material_override=mat
	add_child(poster)

func window_left(width: float, back: float, height: float = 2.6) -> void:
	var view := WindowView.new()
	view.position=Vector3(-width/2.0+0.11,height/2.0+0.45,back/2.0)
	view.rotation.y=PI/2.0
	add_child(view)
	view.setup(self, Vector2(absf(back)*0.65,height))
	windows.append(view)
	for i in 5:
		box(view,Vector3(-view.width/2.0+i*view.width/4.0,0,0.26),Vector3(0.05,height,0.12),material("#37483f",1))
	for y in [-height/2.0,0.0,height/2.0]:
		box(view,Vector3(0,y,0.26),Vector3(view.width+0.1,0.06,0.12),material("#37483f",1))

func meeting_table(at: Vector3, wood: Material, length: float = 2.4) -> void:
	box(self, at + Vector3(0, 0.78, 0), Vector3(1.1, 0.09, length), wood)
	for z in [-length * 0.3, length * 0.3]:
		box(self, at + Vector3(0, 0.38, z), Vector3(0.55, 0.76, 0.12), wood)
		chair(at + Vector3(-0.95, 0, z), "#4e6264", -PI / 2.0)
		chair(at + Vector3(0.95, 0, z), "#4e6264", PI / 2.0)

func build_hall(wood: Material, trim: Material) -> void:
	var fabric := material("#778579", 6)
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

func build_shared(wood: Material, back: float) -> void:
	build_desk(Vector3(-1.25, 0, -1.65), wood, 1)
	chair(Vector3(-1.25, 0, -0.8))
	box(self, Vector3(-2.02, 0.8, back + 0.4), Vector3(0.45, 1.6, 0.55), material("#7b8175"))
	for y in [0.4, 0.9, 1.4]:
		box(self, Vector3(-1.7, y, back + 0.7), Vector3(0.5, 0.03, 0.04), material("#b9b7a4"))
	for i in 3:
		box(self, Vector3(-0.55, 0.18 + i * 0.35, back + 0.5), Vector3(0.6, 0.32, 0.5), material("#a78c5d"))
	wall_map(Vector3(1.95, 1.5, back + 0.1), 0.5)

func build_regional(wood: Material, back: float, width: float) -> void:
	shelf(Vector3(0.7, 0, back + 0.32), 0.8)
	chair(Vector3(-1.25, 0, -0.6), "#536d62", PI)
	box(self, Vector3(-1.35, 0.4, back + 0.35), Vector3(2.3, 0.8, 0.5), wood)

func build_council(wood: Material, back: float, width: float) -> void:
	meeting_table(Vector3(-1.4, 0, -2.3), wood)
	shelf(Vector3(-4.2, 0, back + 0.32), 0.8)
	wall_map(Vector3(2.0, 1.8, back + 0.1), 0.7)

func build_reception(wood: Material, back: float, width: float) -> void:
	chair(Vector3(-1.6, 0, -2.6), "#69745b", -PI / 2.0)
	chair(Vector3(-1.6, 0, -4.0), "#69745b", -PI / 2.0)
	box(self, Vector3(-1.9, 0.48, -3.5), Vector3(0.9, 0.08, 1.25), wood)
	box(self, Vector3(-1.9, 0.23, -3.5), Vector3(0.2, 0.46, 0.75), wood)
	build_desk(Vector3(3.3, 0, -3.7), wood, 4)
	shelf(Vector3(-5.1, 0, back + 0.35), 1.2)

func build_leader(wood: Material, back: float, width: float) -> void:
	meeting_table(Vector3(-1.4, 0, -4.25), wood, 3.1)
	box(self, Vector3(-0.65, 0.35, back + 0.35), Vector3(2.0, 0.7, 0.6), wood)
	for x in [-2.4, 0.0, 2.4]:
		box(self, Vector3(x, 3.85, -2.6), Vector3(0.12, 0.13, 7.6), material("#ac9668"))

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


func focus_folder() -> Tween:
	if focus_motion != null:
		focus_motion.kill()
	folder_focused=true
	var eye := folder_center+Vector3(0.15,1.34,1.16)
	var destination := Transform3D(Basis.IDENTITY,eye).looking_at(folder_center+Vector3(0.0,0.02,0))
	var start := camera.transform
	focus_motion=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	focus_motion.tween_method(func(weight:float)->void: camera.transform=start.interpolate_with(destination,weight),0.0,1.0,0.55)
	focus_motion.tween_property(camera,"fov",48.0,0.55)
	focus_motion.tween_property(folder_hinge,"rotation:z",deg_to_rad(155),0.38).set_delay(0.42)
	return focus_motion

func return_to_desk() -> void:
	if not folder_focused:
		return
	if focus_motion != null:
		focus_motion.kill()
	folder_focused=false
	var start := camera.transform
	focus_motion=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	focus_motion.tween_property(folder_hinge,"rotation:z",0.0,0.28)
	focus_motion.tween_method(func(weight:float)->void: camera.transform=start.interpolate_with(resting_camera,weight),0.0,1.0,0.5).set_delay(0.18)
	focus_motion.tween_property(camera,"fov",desk_fov(),0.5).set_delay(0.18)
