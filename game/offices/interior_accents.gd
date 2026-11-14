extends RefCounted

static func sconce(room: Node3D, at: Vector3) -> void:
	var brass = room.material("#ba9652")
	room.box(room,at,Vector3(0.13,0.3,0.06),brass)
	room.box(room,at+Vector3(0,-0.07,0.11),Vector3(0.04,0.04,0.23),brass)
	var shade = room.cylinder(room,at+Vector3(0,0.065,0.23),0.1,0.19,room.material("#e3c694"))
	var mesh: CylinderMesh = shade.mesh
	mesh.top_radius=0.075
	room.cylinder(room,at+Vector3(0,-0.04,0.23),0.105,0.018,brass)
	var light := OmniLight3D.new()
	light.position=at+Vector3(0,0.08,0.35)
	light.light_color=Color("#ffcc82")
	light.light_energy=0.32
	light.omni_range=1.8
	room.add_child(light)

static func sofa(room: Node3D, at: Vector3, wood: Material) -> void:
	var leather = room.material("#6d4934",7)
	room.box(room,at+Vector3(0,0.24,0),Vector3(1.65,0.2,0.68),wood)
	for x in [-0.73,0.73]:
		for z in [-0.23,0.23]:
			room.box(room,at+Vector3(x,0.12,z),Vector3(0.09,0.24,0.09),wood)
	for x in [-0.45,0,0.45]:
		room.box(room,at+Vector3(x,0.43,0.03),Vector3(0.43,0.16,0.57),leather)
		var cushion = room.box(room,at+Vector3(x,0.73,-0.24),Vector3(0.43,0.58,0.17),leather)
		cushion.rotation.x=-0.1
		for y in [0.62,0.81]:
			room.box(room,at+Vector3(x,y,-0.137),Vector3(0.018,0.018,0.014),wood)
	for x in [-0.77,0.77]:
		room.box(room,at+Vector3(x,0.59,0),Vector3(0.16,0.44,0.7),leather)

static func fluted_pilaster(room: Node3D, at: Vector3, height: float, wood: Material) -> void:
	room.box(room,at+Vector3(0,height/2,0),Vector3(0.24,height,0.1),wood)
	for x in [-0.065,0,0.065]:
		room.box(room,at+Vector3(x,height/2,0.059),Vector3(0.018,height-0.3,0.025),room.material("#b59961"))
	for y in [0.09,height-0.08]:
		room.box(room,at+Vector3(0,y,0),Vector3(0.32,0.13,0.16),wood)
