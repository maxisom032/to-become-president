extends RefCounted
const Accents := preload("res://game/offices/interior_accents.gd")

# One composition, six rooms. Distant objects stay inexpensive solid geometry;
# the window is an illustrated vista behind real mullions and a corner return.
static func build(room: Node3D, rank_value: int) -> void:
	var spec: Dictionary = room.Catalog.ROOMS[rank_value]
	var width: float = spec.width
	var back: float = spec.back
	var height: float = spec.height
	var wood = room.material(["#96643c","#90613b","#775334","#715033","#735030","#684128"][rank_value],1)
	var gold = room.material("#ba9652")
	var wall = room.material(spec.wall,2)
	var cream = room.material("#d5c29a",0)
	var left := -2.45 if rank_value>=4 else -width/2
	var right := width/2
	var depth := 4.2-back
	room.box(room,Vector3((left+right)/2,-0.08,(back+4.2)/2),Vector3(right-left,0.16,depth),room.material("#a77b4d",5))
	room.box(room,Vector3((left+right)/2,height,(back+4.2)/2),Vector3(right-left,0.12,depth),cream)
	for side_x in [left,right]:
		if rank_value>=4 and side_x==left:
			room.box(room,Vector3(left,height/2,(back+1.8+4.2)/2),Vector3(0.12,height,4.2-back-1.8),wall)
			for limits in [Vector2(0,0.8),Vector2(2.9,height)]:
				room.box(room,Vector3(left,(limits.x+limits.y)/2,back+0.9),Vector3(0.12,limits.y-limits.x,1.8),wall)
		else:
			room.box(room,Vector3(side_x,height/2,(back+4.2)/2),Vector3(0.12,height,depth),wall)
		for y in [0.12,0.72,height-0.16]:
			room.box(room,Vector3(side_x+(0.08 if side_x<0 else -0.08),y,(back+4.2)/2),Vector3(0.16,0.07,depth),wood)
	# Increasing real door dimensions compensate for the modest increase in distance.
	var factor := (5.4-back)/8.8
	var door_x := 0.32*factor
	var door_w := 1.16*factor
	var door_h := 2.55*factor
	var opening_left := door_x-door_w/2
	var opening_right := door_x+door_w/2
	var glass_right := -0.95
	var glass_left := left+0.06
	var glass_bottom := 0.8
	var glass_top := 2.9
	if rank_value < 4:
		wall_segment(room,left,opening_left,0,height,back,wall)
	else:
		wall_segment(room,glass_right,opening_left,0,height,back,wall)
		wall_segment(room,left,glass_left,0,height,back,wall)
		wall_segment(room,glass_left,glass_right,0,glass_bottom,back,wood)
		wall_segment(room,glass_left,glass_right,glass_top,height,back,wall)
		corner_window(room,Vector3((glass_left+glass_right)/2,(glass_top+glass_bottom)/2,back+0.08),Vector2(glass_right-glass_left,glass_top-glass_bottom))
	wall_segment(room,opening_right,width/2,0,height,back,wall)
	wall_segment(room,opening_left,opening_right,door_h,height,back,wall)
	door(room,Vector3(door_x,0,back+0.12),factor,wood,gold,rank_value)
	# Baseboards and wainscoting leave both the door and glazing unobstructed.
	for edges in [Vector2(left,opening_left-0.08),Vector2(opening_right+0.08,width/2)]:
		wall_segment(room,edges.x,edges.y,0,0.72,back+0.11,wood)
		wall_segment(room,edges.x,edges.y,0.74,0.79,back+0.16,wood)
		for x in range(int(edges.x*10)+3,int(edges.y*10),5):
			room.box(room,Vector3(x/10.0,0.36,back+0.18),Vector3(0.025,0.60,0.025),gold if rank_value>2 else wood)
	for y in [height-0.12,height-0.22]:
		room.box(room,Vector3(0,y,back+0.13),Vector3(width,0.065,0.16),cream if rank_value<4 else gold)
	preload("res://game/offices/room_refinements.gd").rug(room,rank_value,back)
	ceiling(room,rank_value,width,back,height,wood,gold)
	match rank_value:
		0:
			for side in [-1,1]:
				room.build_desk(Vector3(side*1.95,0,-1.65),wood,0)
				room.chair(Vector3(side*1.95,0,-0.85))
				room.box(room,Vector3(side*1.22,0.72,-1.25),Vector3(0.08,1.44,1.85),room.material("#6d7b64",6))
			room.RoomDressing.notice_board(room,Vector3(-1.25,1.85,back+0.16),1.05)
			cabinet(room,Vector3(2.15,0,back+0.4),1.1,0.8,wood,3)
		1:
			cabinet(room,Vector3(-1.65,0,back+0.4),1.9,0.9,wood,3)
			room.RoomDressing.notice_board(room,Vector3(-1.65,1.9,back+0.16),1.0)
			cabinet(room,Vector3(1.85,0,back+0.38),0.7,1.55,room.material("#777751"),4)
			room.chair(Vector3(1.7,0,-1.5))
		2:
			bookcase(room,Vector3(-1.8,0,back+0.32),1.35,wood)
			room.ReadyProps.place(room,"polyhaven-armchair",Vector3(-1.65,0,-1.9),1.0,0.0)
			room.ReadyProps.place(room,"polyhaven-armchair",Vector3(1.85,0,-1.9),1.0,0.0)
			cabinet(room,Vector3(2.1,0,back+0.4),1.5,0.85,wood,2)
			picture(room,Vector3(2.1,1.9,back+0.2),Vector2(1.05,0.75),wood)
		3:
			bookcase(room,Vector3(-2.65,0,back+0.32),1.1,wood)
			room.meeting_table(Vector3(-1.75,0,-2.3),wood,1.6)
			cabinet(room,Vector3(2.35,0,back+0.4),1.65,0.85,wood,2)
			picture(room,Vector3(-1.25,2.0,back+0.2),Vector2(0.9,0.8),wood)
			picture(room,Vector3(2.35,1.95,back+0.2),Vector2(0.85,0.9),wood)
		4,5:
			bookcase(room,Vector3(2.7,0,back+0.35),1.5,wood)
			if rank_value==5:
				room.ReadyProps.place(room,"polyhaven-sofa",Vector3(-1.45,0,back+1.0),0.85,0.0)
			else:
				for chair_x in [-1.95,-0.85]:
					room.ReadyProps.place(room,"polyhaven-armchair",Vector3(chair_x,0,back+1.2),0.82,0.12 if chair_x< -1 else -0.12)
			room.box(room,Vector3(-1.45,0.45,back+2.25),Vector3(0.95,0.08,0.5),wood)
			room.cylinder(room,Vector3(-1.45,0.225,back+2.25),0.1,0.45,gold)
			if rank_value==5:
				# Stepped, geometric architectural details instead of dense ornament.
				for side in [-1,1]:
					for step in 3:
						room.box(room,Vector3(door_x+side*(0.89+step*0.12),1.7,back+0.18),Vector3(0.035,3.1-step*0.2,0.055),gold)
	if rank_value>=2:
		for x in [-0.85,1.4]:
			Accents.sconce(room,Vector3(x*factor,2.15*factor,back+0.24))
	if rank_value>=3:
		for x in [-width/2+0.25,width/2-0.25]:
			Accents.fluted_pilaster(room,Vector3(x,0,back+0.15),height-0.25,wood)
	room.DeskDetails.plant(room,Vector3(width/2-0.55,0,back+0.85),1.1)
	if rank_value<2:
		room.RoomDressing.clock(room,Vector3(1.7,2.55,back+0.2))

static func wall_segment(room: Node3D, left: float, right: float, bottom: float, top: float, z: float, mat: Material) -> void:
	if right-left>0.005 and top-bottom>0.005:
		room.box(room,Vector3((left+right)/2,(bottom+top)/2,z),Vector3(right-left,top-bottom,0.12),mat)

static func door(room: Node3D, at: Vector3, factor: float, wood: Material, gold: Material, rank_value: int) -> void:
	var start: int = room.get_child_count()
	room.build_door(at,wood,wood)
	# build_door owns the animated hinge and picking target; scale its entire assembly.
	var scale_value := Vector3(factor,2.55/2.3*factor,factor)
	for i in range(start,room.get_child_count()):
		var child: Node3D = room.get_child(i)
		child.position=at+(child.position-at)*scale_value
		child.scale=scale_value
	room.door_bounds=AABB(at+Vector3(-0.54*factor,0,0),Vector3(1.08*factor,2.24*scale_value.y,0.08))
	if rank_value>=2:
		for side in [-1,1]:
			room.box(room,at+Vector3(side*0.73*factor,1.32*scale_value.y,0.02),Vector3(0.1*factor,2.72*scale_value.y,0.16),wood)
		room.box(room,at+Vector3(0,2.69*scale_value.y,0.02),Vector3(1.75*factor,0.11,0.22),wood)
		room.box(room,at+Vector3(0,2.79*scale_value.y,0.04),Vector3(1.88*factor,0.055,0.25),gold if rank_value>=4 else wood)

static func cabinet(room: Node3D, at: Vector3, width: float, height: float, wood: Material, drawers: int) -> void:
	room.box(room,at+Vector3(0,height/2,0),Vector3(width,height,0.55),wood)
	room.box(room,at+Vector3(0,height,0),Vector3(width+0.08,0.065,0.63),wood)
	for i in drawers:
		var y := 0.12+(height-0.16)*(i+0.5)/drawers
		var panel_h := (height-0.22)/drawers
		room.box(room,at+Vector3(0,y,0.285),Vector3(width-0.065,panel_h+0.025,0.022),room.material("#413424"))
		room.box(room,at+Vector3(0,y,0.31),Vector3(width-0.10,panel_h,0.04),wood)
		room.box(room,at+Vector3(0,y+panel_h*0.18,0.337),Vector3(0.16,0.065,0.012),room.material("#ba9652"))
		room.box(room,at+Vector3(0,y+panel_h*0.18,0.346),Vector3(0.125,0.038,0.005),room.material("#d8c7a2"))
		for x in [-0.07,0.07]:
			room.box(room,at+Vector3(x,y-0.025,0.35),Vector3(0.025,0.04,0.035),room.material("#ba9652"))
		room.box(room,at+Vector3(0,y-0.025,0.37),Vector3(0.18,0.025,0.04),room.material("#ba9652"))

static func bookcase(room: Node3D, at: Vector3, width: float, wood: Material) -> void:
	room.box(room,at+Vector3(0,1.3,-0.12),Vector3(width,2.6,0.1),wood)
	room.shelf(at,width)
	for y in [0.05,2.52,2.61]:
		room.box(room,at+Vector3(0,y,0),Vector3(width+0.15,0.08,0.48),wood)

static func picture(room: Node3D, at: Vector3, dimensions: Vector2, wood: Material) -> void:
	room.box(room,at,Vector3(dimensions.x+0.1,dimensions.y+0.1,0.07),wood)
	room.box(room,at+Vector3(0,0,0.045),Vector3(dimensions.x,dimensions.y,0.02),room.material("#cbbd92",0))
	# A small architectural print: shallow relief, readable even on a phone.
	room.box(room,at+Vector3(0,-0.09,0.065),Vector3(dimensions.x*0.65,0.045,0.01),room.material("#9b8355"))
	for x in [-0.24,-0.12,0.0,0.12,0.24]:
		room.box(room,at+Vector3(x*dimensions.x,0.025,0.064),Vector3(0.035,dimensions.y*0.26,0.01),room.material("#9b8355"))
	room.box(room,at+Vector3(0,dimensions.y*0.19,0.064),Vector3(dimensions.x*0.7,0.04,0.01),room.material("#9b8355"))

static func ceiling(room: Node3D, rank_value: int, width: float, back: float, height: float, wood: Material, gold: Material) -> void:
	var glow := StandardMaterial3D.new()
	glow.albedo_color=Color("#f5d9a0")
	glow.emission_enabled=true
	glow.emission=Color("#ffcf83")
	glow.emission_energy_multiplier=0.12
	for z in [-0.4,back+0.4]:
		room.box(room,Vector3(0,height-0.12,z),Vector3(width,0.16,0.16),wood)
	if rank_value>=4:
		for x in [-2.5,-1.25,1.25,2.5]:
			room.box(room,Vector3(x,height-0.1,(back+3)/2),Vector3(0.13,0.15,3-back),wood)
	var at := Vector3(0,height-0.40,back+1.7)
	room.cylinder(room,at+Vector3(0,0.4,0),0.02,0.8,gold)
	room.cylinder(room,Vector3(0,height-0.08,at.z),0.13,0.06,gold)
	if rank_value<2:
		var cap = room.cylinder(room,at,0.38,0.14,room.material("#69704a") if rank_value==1 else gold)
		var mesh: CylinderMesh = cap.mesh
		mesh.top_radius=0.16
		room.cylinder(room,at+Vector3(0,-0.08,0),0.35,0.025,glow)
	elif rank_value<5:
		var radius := 0.44+rank_value*0.025
		room.cylinder(room,at,radius,0.2,glow)
		for y in [-0.12,0.12]:
			room.cylinder(room,at+Vector3(0,y,0),radius+0.025,0.035,gold)
		for i in 8:
			var a := TAU*i/8
			room.box(room,at+Vector3(cos(a)*radius,0,sin(a)*radius),Vector3(0.014,0.25,0.014),gold)
	else:
		room.box(room,at,Vector3(1.55,0.035,0.04),gold)
		for x in [-0.67,0,0.67]:
			room.cylinder(room,at+Vector3(x,-0.13,0),0.17,0.38,glow)
			for y in [-0.34,0.08]:
				room.cylinder(room,at+Vector3(x,y,0),0.19,0.035,gold)
	var light := OmniLight3D.new()
	light.position=at+Vector3(0,-0.25,0)
	light.light_color=Color("#ffdea2")
	light.light_energy=0.35
	light.omni_range=7
	room.add_child(light)

static func corner_window(room: Node3D, at: Vector3, dimensions: Vector2) -> void:
	# One L-shaped glazing assembly. The return uses another portion of the vista,
	# rather than repeating a second complete framed picture on the back wall.
	var root := Node3D.new()
	root.name="CornerGlazing"
	room.add_child(root)
	room.back_window(at,dimensions.x,dimensions.y)
	var view: Node3D = room.windows[-1]
	var return_view = room.WindowView.new()
	root.add_child(return_view)
	return_view.position=at+Vector3(-dimensions.x/2+0.035,0,0.9)
	return_view.rotation.y=PI/2
	return_view.setup(room,Vector2(1.8,dimensions.y))
	# Split one continuous panorama at the physical corner. Do not repeat a whole
	# centered image on both faces of the glazing.
	var front_plane: MeshInstance3D = view.get_node("PaintedExterior")
	var side_plane: MeshInstance3D = return_view.get_node("PaintedExterior")
	var front_mat: StandardMaterial3D = front_plane.material_override
	var side_mat: StandardMaterial3D = side_plane.material_override
	var total := dimensions.x+1.8
	var source_ratio := float(front_mat.albedo_texture.get_width())/front_mat.albedo_texture.get_height()
	var crop_x := minf(1.0,total/dimensions.y/source_ratio)
	var crop_y := minf(1.0,source_ratio/(total/dimensions.y))
	var offset := (1.0-crop_x)/2.0
	side_mat.uv1_scale=Vector3(crop_x*1.8/total,crop_y,1)
	side_mat.uv1_offset=Vector3(offset,(1.0-crop_y)*0.42,0)
	front_mat.uv1_scale=Vector3(crop_x*dimensions.x/total,crop_y,1)
	front_mat.uv1_offset=Vector3(offset+crop_x*1.8/total,(1.0-crop_y)*0.42,0)

	var frame = room.material("#655537",1)
	for z in [0.03,0.9,1.8]:
		room.box(room,at+Vector3(-dimensions.x/2+0.12,0,z),Vector3(0.09,dimensions.y+0.15,0.07),frame)
	for y in [-dimensions.y/2,dimensions.y*0.16,dimensions.y/2]:
		room.box(room,at+Vector3(-dimensions.x/2+0.12,y,0.9),Vector3(0.12,0.065,1.9),frame)
	view.set_meta("corner",true)

