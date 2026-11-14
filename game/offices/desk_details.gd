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
	base.rotation.y = 0.12
	room.add_child(base)
	var kraft = room.material("#ad855a",0)
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
	room.box(hinge,Vector3(0.385,0.009,-0.05),Vector3(0.40,0.002,0.25),room.material("#ddc494",0))
	lettering(room,hinge,"ДЕЛО № 001",Vector3(0.385,0.013,-0.07),0.00067)
	lettering(room,hinge,"АППАРАТ ПАРТИИ",Vector3(0.385,0.013,0.035),0.00038)
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
	preload("res://game/offices/crafted_props.gd").place(room,"phone",at)

static func lamp(room: Node3D, at: Vector3) -> void:
	preload("res://game/offices/crafted_props.gd").place(room,"lamp",at)
	var glow := OmniLight3D.new()
	glow.position=at+Vector3(0,0.32,0)
	glow.light_color=Color("#ffdba0")
	glow.light_energy=0.18
	glow.omni_range=1.5
	room.add_child(glow)

static func extras(room: Node3D, desk_at: Vector3, index: int) -> void:
	var brass = room.material("#b59961")
	var props := preload("res://game/offices/ready_props.gd")
	props.place(room,"cup-tea",desk_at+Vector3(0.88,0.95,0.05),0.18,-0.4)
	var holder := desk_at+Vector3(0.16,1.055,-0.72)
	preload("res://game/offices/crafted_props.gd").place(room,"holder",holder-Vector3(0,0.105,0))
	for i in 5:
		var pen = room.cylinder(room,holder+Vector3(sin(i*2.0)*0.035,0.12,cos(i*2.0)*0.035),0.007,0.3+i*0.012,room.material(["#b99650","#8a493a","#364d63"][i%3]))
		pen.rotation.z=(i-2)*0.09
		pen.rotation.x=(i%2)*0.1
	# Felt edge binding and several loose documents add table scale.
	for side in [-1,1]:
		room.box(room,desk_at+Vector3(side*0.88,0.949,0.04),Vector3(0.009,0.003,1.26),brass)
		room.box(room,desk_at+Vector3(0,0.949,0.04+side*0.63),Vector3(1.76,0.003,0.009),brass)
	props.place(room,"books",desk_at+Vector3(-0.86,0.95,0.09),0.12,-0.1)
	var stamp := desk_at+Vector3(-0.58,0.97,0.59)
	room.cylinder(room,stamp,0.075,0.035,room.material("#ba9652"))
	room.cylinder(room,stamp+Vector3(0,0.07,0),0.035,0.12,room.material("#633b28",1))
	room.cylinder(room,stamp+Vector3(0,0.13,0),0.055,0.035,room.material("#633b28",1))

static func plant(room: Node3D, at: Vector3, scale_value: float) -> void:
	preload("res://game/offices/ready_props.gd").place(room,"plantSmall3" if scale_value<1.0 else "pottedPlant",at,scale_value*0.85)
