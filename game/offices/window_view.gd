extends Node3D

var width := 2.0
var height := 1.8
var car: Node3D
var clouds: Array[Node3D] = []
var time := 0.0
var builder: Node3D

func setup(owner_room: Node3D, dimensions: Vector2) -> void:
	builder = owner_room
	width = dimensions.x
	height = dimensions.y
	var sky := StandardMaterial3D.new()
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky.albedo_color = Color("#adc8c9")
	var backdrop = builder.box(self, Vector3(0,0,-0.02),Vector3(width,height,0.025),sky)
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 7:
		var bw := width * (0.1 + (i % 3) * 0.015)
		var bh := height * (0.27 + (i * 3 % 5) * 0.07)
		var x := -width*0.44 + i*width*0.145
		var y := -height/2.0 + bh/2.0 + height*0.12
		var facade = builder.material(["#b09d7e","#a4a896","#8d9a99"][i%3])
		builder.box(self, Vector3(x,y,0.055),Vector3(bw,bh,0.12),facade)
		builder.box(self,Vector3(x,y+bh/2.0,0.075),Vector3(bw+0.03,0.025,0.14),builder.material("#d1c1a0"))
		for floor_index in 3:
			for column in 2:
				builder.box(self,Vector3(x-bw*0.23+column*bw*0.46,y-bh*0.3+floor_index*bh*0.28,0.123),Vector3(bw*0.18,bh*0.13,0.012),builder.material("#52676c"))
	var road = builder.box(self,Vector3(0,-height*0.43,0.13),Vector3(width,height*0.12,0.06),builder.material("#7b8783"))
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius=width*0.075
	dome_mesh.height=width*0.15
	dome_mesh.radial_segments=20
	dome_mesh.rings=10
	var dome := MeshInstance3D.new()
	dome.mesh=dome_mesh
	dome.material_override=builder.material("#cbbf9f")
	dome.position=Vector3(0,height*0.17,0.07)
	dome.scale=Vector3(1,0.7,0.6)
	add_child(dome)
	builder.box(self,Vector3(0,height*0.1,0.1),Vector3(width*0.18,height*0.1,0.1),builder.material("#cbbf9f"))
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	car = Node3D.new()
	add_child(car)
	builder.box(car,Vector3.ZERO,Vector3(width*0.095,height*0.035,0.04),builder.material("#8c493c"))
	builder.box(car,Vector3(0,height*0.026,0),Vector3(width*0.05,height*0.025,0.035),builder.material("#405963"))
	for i in 2:
		var cloud := Node3D.new()
		cloud.position = Vector3(width*(-0.25+i*0.45),height*(0.28+i*0.08),0.03)
		add_child(cloud)
		for j in 3:
			var mesh := SphereMesh.new()
			mesh.radius = width*0.045
			mesh.height = width*0.09
			mesh.radial_segments = 12
			mesh.rings = 6
			var puff := MeshInstance3D.new()
			puff.mesh = mesh
			puff.material_override = builder.material("#e5e2ce")
			puff.scale = Vector3(1.5,0.5,0.25)
			puff.position.x = (j-1)*width*0.055
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(puff)
		clouds.append(cloud)
	_process(0.0)

func _process(delta: float) -> void:
	time += delta
	if car != null:
		car.position = Vector3((fposmod(time*0.12,1.0)-0.5)*width*0.83,-height*0.42,0.19)
	for i in clouds.size():
		clouds[i].position.x = sin(time*0.025+i*2.0)*width*0.28
