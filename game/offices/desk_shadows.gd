extends RefCounted

static func add(room: Node3D, at: Vector3) -> void:
	var group := Node3D.new()
	group.name="DeskContactShadows"
	group.set_meta("dynamic_detail",true)
	room.add_child(group)
	for spec in [
		[Vector2(-0.03,0.14),Vector2(1.02,1.10),0.30],
		[Vector2(0.62,-0.20),Vector2(0.58,0.53),0.28],
		[Vector2(-0.67,-0.43),Vector2(0.39,0.35),0.24],
		[Vector2(0.16,-0.72),Vector2(0.23,0.22),0.22]]:
		var plane := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size=spec[1]
		plane.mesh=quad
		plane.position=at+Vector3(spec[0].x,0.954,spec[0].y)
		plane.rotation.x=-PI/2
		plane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader=preload("res://game/offices/contact_shadow.gdshader")
		mat.set_shader_parameter("opacity",spec[2])
		plane.material_override=mat
		group.add_child(plane)
