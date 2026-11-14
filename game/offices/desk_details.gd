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
	var kraft = room.material("#ab794c", 0)
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

static func extras(room: Node3D, desk_at: Vector3, index: int) -> void:
	var brass = room.material("#b59961")
	# A thick enamel cup, rim, coffee surface and a real torus handle.
	var cup := desk_at+Vector3(0.65,1.05,0.22)
	room.cylinder(room,cup,0.09,0.2,room.material("#854a3d"))
	room.cylinder(room,cup+Vector3(0,0.102,0),0.08,0.008,room.material("#3c2d25"))
	var handle := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius=0.047
	torus.outer_radius=0.065
	torus.rings=16
	torus.ring_segments=8
	handle.mesh=torus
	handle.material_override=room.material("#854a3d")
	handle.position=cup+Vector3(0.09,0,0)
	handle.rotation.x=PI/2.0
	room.add_child(handle)
	var holder := desk_at+Vector3(0.75,1.055,-0.5)
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
	for i in 3:
		var page = room.box(room,desk_at+Vector3(-0.68+i*0.012,0.951+i*0.004,0.28),Vector3(0.25,0.003,0.37),room.material("#dacbaa",0))
		page.rotation.y = -0.14+i*0.03
	# Back wall relief, a practical notice board, and plants vary by rank.
	var spec: Dictionary = Catalog.ROOMS[index]
	var back: float = spec.back
	var dx: float = [0.15,1.0,2.15,2.25,-1.0,2.75][index]
	for side in [-1,1]:
		var edge := -float(spec.width)/2.0 if side<0 else float(spec.width)/2.0
		var inner := dx-0.65 if side<0 else dx+0.65
		room.box(room,Vector3((edge+inner)/2.0,0.42,back+0.1),Vector3(absf(edge-inner),0.84,0.08),room.material("#765739",1))
		room.box(room,Vector3((edge+inner)/2.0,0.87,back+0.14),Vector3(absf(edge-inner),0.055,0.13),brass)
	plant(room,Vector3(-1.1,0.95,0.9),0.45)
	if index>0:
		plant(room,Vector3(-float(spec.width)/2.0+0.48,0,back+0.65),1.25)

static func plant(room: Node3D, at: Vector3, scale_value: float) -> void:
	var root := Node3D.new()
	root.position=at
	root.scale=Vector3.ONE*scale_value
	room.add_child(root)
	room.cylinder(root,Vector3(0,0.15,0),0.16,0.3,room.material("#aa7656"))
	room.cylinder(root,Vector3(0,0.305,0),0.145,0.008,room.material("#44372a"))
	for i in 9:
		var angle := i*2.4
		var stem = room.cylinder(root,Vector3(sin(angle)*0.07,0.54,cos(angle)*0.07),0.007,0.5,room.material("#4b6142"))
		stem.rotation.z=sin(angle)*0.23
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radius=0.12
		leaf_mesh.height=0.24
		leaf_mesh.radial_segments=10
		leaf_mesh.rings=6
		var leaf := MeshInstance3D.new()
		leaf.mesh=leaf_mesh
		leaf.material_override=room.material(["#536e42","#738149","#3e5b43"][i%3])
		leaf.position=Vector3(sin(angle)*0.17,0.65+(i%3)*0.08,cos(angle)*0.17)
		leaf.scale=Vector3(1.0,0.32,1.8)
		leaf.rotation_degrees=Vector3(15+i*8,i*137,20)
		root.add_child(leaf)
