extends RefCounted

static func rug(room: Node3D, rank_value: int, back: float) -> void:
	var runner := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size=Vector2(1.55,absf(back)+0.05)
	runner.mesh=mesh
	runner.position=Vector3(0.12,0.032,(back-0.15)/2)
	runner.rotation.x=-PI/2
	var mat := StandardMaterial3D.new()
	mat.albedo_texture=load("res://game/offices/assets/rugs/runner-%02d.svg" % (rank_value+1))
	mat.roughness=0.96
	runner.material_override=mat
	room.add_child(runner)
