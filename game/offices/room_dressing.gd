extends RefCounted

static func clock(room: Node3D, at: Vector3) -> void:
	var rim=room.cylinder(room,at,0.16,0.035,room.material("#ba9652"))
	rim.rotation.x=PI/2.0
	room.cylinder(room,at+Vector3(0,0,0.022),0.14,0.012,room.material("#e4c894")).rotation.x=PI/2.0
	room.box(room,at+Vector3(0.035,0.0,0.035),Vector3(0.08,0.009,0.008),room.material("#4c3523"))
	room.box(room,at+Vector3(0,0.05,0.035),Vector3(0.009,0.1,0.008),room.material("#4c3523"))

static func add_details(room: Node3D, spec: Dictionary, rank_value: int) -> void:
	var width: float = spec.width
	var back: float = spec.back
	var height: float = spec.height
	var depth := 4.2-back
	var cornice = room.material("#cbb993",0)
	var wood = room.material("#725039",1)
	for side in [-1,1]:
		for y in [0.08,0.87]:
			room.box(room,Vector3(side*(width/2.0-0.09),y,(back+4.2)/2.0),Vector3(0.1,0.07,depth),wood)
		for row in 2:
			room.box(room,Vector3(side*(width/2.0-0.1),height-0.06-row*0.08,(back+4.2)/2.0),Vector3(0.12+row*0.04,0.06,depth),cornice)
	for row in 2:
		room.box(room,Vector3(0,height-0.06-row*0.08,back+0.1),Vector3(width,0.06,0.12+row*0.04),cornice)
	var door_x: float = [0.15,1.0,2.15,3.6,-3.8,5.5][rank_value]
	for i in int(width/0.38):
		var x := -width/2.0+0.2+i*0.38
		if absf(x-door_x) > 0.7:
			room.box(room,Vector3(x,0.42,back+0.153),Vector3(0.012,0.73,0.012),room.material("#b3915c" if rank_value>1 else "#655b47"))
	if rank_value == 0:
		# The first office reads as an older shared institution, like concept 1.
		for z in [-1.0,-3.8,-6.4]:
			room.box(room,Vector3(0,height-0.16,z),Vector3(width,0.22,0.16),room.material("#7f7965",0))
		for x in [-3.7,3.7]:
			var pipe = room.cylinder(room,Vector3(x,height-0.3,-1.2),0.07,9.0,room.material("#8b4836"))
			pipe.rotation.x = PI/2.0
		for side in [-1,1]:
			for z in [-2.0,-5.2]:
				room.box(room,Vector3(side*4.4,height/2.0,z),Vector3(0.33,height,0.33),room.material("#a99e81",0))
		for y in [0.35,0.64,0.93]:
			room.box(room,Vector3(2.4,y,0.242),Vector3(0.67,0.22,0.035),room.material("#a49f89",0))
			room.box(room,Vector3(2.4,y+0.03,0.275),Vector3(0.19,0.026,0.035),room.material("#4c5650"))

	elif rank_value >= 2:
		# Panel joints and recessed side-wall moulding use very simple geometry.
		for z in range(int(back)+1,3,2):
			for side in [-1,1]:
				room.box(room,Vector3(side*(width/2.0-0.075),height/2.0,z),Vector3(0.035,height-0.45,0.035),room.material(spec.wall,0))

static func notice_board(room: Node3D, at: Vector3, width: float) -> void:
	room.box(room,at,Vector3(width+0.07,0.61,0.045),room.material("#795735",1))
	room.box(room,at+Vector3(0,0,0.027),Vector3(width,0.54,0.012),room.material("#a68e5d",0))
	for i in 4:
		var x := -width*0.23+(i%2)*width*0.45
		var y := 0.13-float(i/2)*0.25
		var paper = room.box(room,at+Vector3(x,y,0.04),Vector3(width*0.36,0.19,0.005),room.material("#dfcda2",0))
		paper.rotation.z = -0.03+i*0.02
		room.cylinder(room,at+Vector3(x,y+0.08,0.047),0.008,0.007,room.material("#813f34")).rotation.x=PI/2.0
		for line in 4:
			room.box(room,at+Vector3(x,y+0.05-line*0.026,0.046),Vector3(width*0.25,0.003,0.002),room.material("#9b8966"))

static func chandelier(room: Node3D, at: Vector3, ceiling: float, rank_value: int) -> void:
	var brass=room.material("#ba9652")
	room.cylinder(room,Vector3(at.x,(ceiling+at.y)/2.0,at.z),0.015,ceiling-at.y,brass)
	for tier in (2 if rank_value>=4 else 1):
		var radius := 0.5+(rank_value-3)*0.18-tier*0.18
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius=radius-0.025
		mesh.outer_radius=radius+0.025
		mesh.rings=32
		mesh.ring_segments=8
		ring.mesh=mesh
		ring.material_override=brass
		ring.position=at+Vector3(0,tier*0.32,0)
		room.add_child(ring)
		for i in 6:
			var angle := TAU*i/6.0
			var p := ring.position+Vector3(cos(angle)*radius,0.07,sin(angle)*radius)
			room.cylinder(room,p,0.07,0.17,room.material("#e8d4a7"))
