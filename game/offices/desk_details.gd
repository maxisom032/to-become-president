extends RefCounted
const Catalog := preload("res://game/offices/office_catalog.gd")

static func lettering(room: Node3D, parent: Node3D, value: String, at: Vector3, scale_value: float = 0.001) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.font = preload("res://game/art/fonts/PTSerif-Bold.ttf")
	label.font_size = 40
	label.pixel_size = scale_value
	label.outline_size = 0
	label.modulate = Color("#463d31")
	label.position = at
	label.rotation.x = -PI/2.0
	parent.add_child(label)
	return label

static func folder(room: Node3D, at: Vector3) -> Node3D:
	var base := Node3D.new()
	base.position = at
	base.rotation.y = -0.045
	room.add_child(base)
	var kraft = room.material("#ab794c", 0) if room.room_index < 2 else room.material("#633d34" if room.room_index<5 else "#344d55",7)
	room.box(base,Vector3(0,-0.016,0),Vector3(0.77,0.025,0.87),kraft)
	for i in 6:
		room.box(base,Vector3(sin(i*2.0)*0.008,i*0.006,0),Vector3(0.69,0.004,0.8),room.material("#ecdfbc",0))
	for i in 8:
		room.box(base,Vector3(0.03,0.04,-0.21+i*0.045),Vector3(0.43 if i<7 else 0.26,0.002,0.003),room.material("#a3916e"))
	lettering(room,base,"СЛУЖЕБНАЯ ЗАПИСКА",Vector3(0.02,0.043,-0.31),0.00045)
	for i in 3:
		room.box(base,Vector3(0.37,0.009+i*0.007,-0.24+i*0.14),Vector3(0.1,0.01,0.09),room.material(["#a44a3b","#bfa064","#496b67"][i]))
	var hinge := Node3D.new()
	hinge.name = "FolderCoverHinge"
	hinge.position = Vector3(-0.385,0.052,0)
	base.add_child(hinge)
	room.box(hinge,Vector3(0.385,0,0),Vector3(0.77,0.012,0.87),kraft)
	if room.room_index >= 2:
		for side in [-1,1]:
			room.box(hinge,Vector3(0.385+side*0.35,0.009,0),Vector3(0.003,0.002,0.8),room.material("#b8985a"))
			room.box(hinge,Vector3(0.385,0.009,side*0.4),Vector3(0.7,0.002,0.003),room.material("#b8985a"))
	room.box(hinge,Vector3(0.385,0.009,-0.05),Vector3(0.55,0.002,0.31),room.material("#ddc494",0))
	lettering(room,hinge,"РАБОЧЕЕ ДЕЛО",Vector3(0.385,0.013,-0.07),0.00072)
	lettering(room,hinge,"АППАРАТ ПАРТИИ  /  001",Vector3(0.385,0.013,0.035),0.00038)
	for z in [-0.24,0.24]:
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.018
		ring_mesh.outer_radius = 0.027
		ring_mesh.rings = 12
		ring_mesh.ring_segments = 8
		var ring := MeshInstance3D.new()
		ring.mesh = ring_mesh
		ring.material_override = room.material("#aa956a")
		ring.position = Vector3(-0.325,0.037,z)
		ring.rotation.x = PI/2.0
		base.add_child(ring)
	return hinge

static func phone(room: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = 0.1
	room.add_child(root)
	var ivory = room.material("#d8c9a5")
	var dark = room.material("#344746")
	room.box(root,Vector3(0,0,0),Vector3(0.39,0.1,0.36),ivory)
	var slope = room.box(root,Vector3(0,0.068,0.03),Vector3(0.35,0.05,0.28),ivory)
	slope.rotation.x = -0.14
	room.box(root,Vector3(0,0.11,-0.12),Vector3(0.28,0.04,0.1),dark)
	# Curved handset assembled from rounded earpieces and a narrow bridge.
	for x in [-0.17,0.17]:
		var cap = room.cylinder(root,Vector3(x,0.145,-0.12),0.063,0.055,ivory)
		cap.rotation.z = PI/2.0
	room.box(root,Vector3(0,0.17,-0.12),Vector3(0.3,0.055,0.065),ivory)
	for z in 4:
		for x in 3:
			room.box(root,Vector3(-0.075+x*0.075,0.109+z*0.006,-0.025+z*0.055),Vector3(0.048,0.022,0.036),room.material("#59645b"))
	for i in 16:
		var p := Vector3(-0.23+sin(i*1.8)*0.017,0.015-i*0.003,-0.12+i*0.014)
		room.cylinder(root,p,0.009,0.014,dark).rotation.x = PI/2.0

static func lamp(room: Node3D, at: Vector3) -> void:
	var brass = room.material("#ba9652")
	room.cylinder(room,at,0.13,0.026,brass)
	room.cylinder(room,at+Vector3(0,0.027,0),0.105,0.024,brass)
	room.cylinder(room,at+Vector3(0,0.21,0),0.014,0.38,brass)
	room.cylinder(room,at+Vector3(0,0.37,0),0.033,0.04,brass)
	var shade := SurfaceTool.new()
	shade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in 20:
		var a := PI*segment/20.0
		var b := PI*(segment+1)/20.0
		var points := [Vector3(-0.24,sin(a)*0.13,cos(a)*0.13),Vector3(0.24,sin(a)*0.13,cos(a)*0.13),Vector3(0.24,sin(b)*0.13,cos(b)*0.13),Vector3(-0.24,sin(b)*0.13,cos(b)*0.13)]
		for j in [0,2,1,0,3,2]:
			var p: Vector3 = points[j]
			shade.set_normal(Vector3(0,p.y,p.z).normalized())
			shade.add_vertex(p)
	var hood := MeshInstance3D.new()
	hood.mesh=shade.commit()
	hood.position=at+Vector3(0,0.39,0)
	var glass := StandardMaterial3D.new()
	glass.albedo_color=Color("#2e5544" if room.room_index<4 else "#b38b46")
	glass.roughness=0.22
	glass.metallic=0.12
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	hood.material_override=glass
	room.add_child(hood)
	room.box(room,at+Vector3(0,0.388,0),Vector3(0.47,0.013,0.24),room.material("#e1c78b"))
	var glow := OmniLight3D.new()
	glow.position=at+Vector3(0,0.31,-0.01)
	glow.light_color=Color("#ffd18b")
	glow.light_energy=0.15
	glow.omni_range=1.4
	room.add_child(glow)

static func extras(room: Node3D, desk_at: Vector3, index: int) -> void:
	var brass = room.material("#b59961")
	var props := preload("res://game/offices/ready_props.gd")
	props.place(room,"cup-tea",desk_at+Vector3(0.65,0.95,0.22),0.18,-0.4)
	var holder := desk_at+Vector3(0.16,1.055,-0.72)
	room.cylinder(room,holder,0.067,0.21,room.material("#355e58"))
	room.cylinder(room,holder+Vector3(0,0.108,0),0.057,0.006,room.material("#233d38"))
	for i in 5:
		var pen = room.cylinder(room,holder+Vector3(sin(i*2.0)*0.035,0.12,cos(i*2.0)*0.035),0.007,0.3+i*0.012,room.material(["#b99650","#8a493a","#364d63"][i%3]))
		pen.rotation.z=(i-2)*0.09
		pen.rotation.x=(i%2)*0.1
	# Felt edge binding and several loose documents add table scale.
	for side in [-1,1]:
		room.box(room,desk_at+Vector3(side*0.78,0.949,0.25),Vector3(0.009,0.003,1.66),brass)
		room.box(room,desk_at+Vector3(0,0.949,0.25+side*0.82),Vector3(1.56,0.003,0.009),brass)
	props.place(room,"books",desk_at+Vector3(-0.75,0.95,0.28),0.12,-0.1)
	# Back wall relief, a practical notice board, and plants vary by rank.
	var spec: Dictionary = Catalog.ROOMS[index]
	var back: float = spec.back
	var dx: float = [0.15,1.0,2.15,3.6,-3.8,5.5][index]
	for side in [-1,1]:
		var edge := -float(spec.width)/2.0 if side<0 else float(spec.width)/2.0
		var inner := dx-0.65 if side<0 else dx+0.65
		room.box(room,Vector3((edge+inner)/2.0,0.42,back+0.1),Vector3(absf(edge-inner),0.84,0.08),room.material("#713e34",0) if index==1 else room.material("#765739",1))
		room.box(room,Vector3((edge+inner)/2.0,0.87,back+0.14),Vector3(absf(edge-inner),0.055,0.13),brass)
	plant(room,Vector3(-1.1,0.95,0.9),0.45)
	if index>0:
		plant(room,Vector3(-float(spec.width)/2.0+0.48,0,back+0.65),1.25)

static func plant(room: Node3D, at: Vector3, scale_value: float) -> void:
	preload("res://game/offices/ready_props.gd").place(room,"plantSmall3" if scale_value<1.0 else "pottedPlant",at,scale_value*0.85)
