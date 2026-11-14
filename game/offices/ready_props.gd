extends RefCounted

static func place(room: Node3D, id: String, at: Vector3, height: float, angle: float=0.0) -> Node3D:
	var scene: PackedScene = load("res://game/offices/assets/kenney/"+id+".glb")
	var root := Node3D.new()
	room.add_child(root)
	var model: Node3D = scene.instantiate()
	root.add_child(model)
	var bounds := AABB()
	var first := true
	for node in model.find_children("*","MeshInstance3D",true,false):
		for surface_index in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(surface_index)
			if original == null:
				continue
			var key := original.resource_name.to_lower()
			var replacement: Material = room.material("#8e6c4d",0)
			if "plant" in key:
				replacement=room.material("#677c4e")
			elif "carpet" in key:
				replacement=room.material("#45605b",7)
			elif "wood" in key and "plant" not in id.to_lower():
				replacement=room.material("#76553b",1)
			node.set_surface_override_material(surface_index,replacement)
		var box: AABB = (model.global_transform.affine_inverse()*node.global_transform)*node.get_aabb()
		bounds = box if first else bounds.merge(box)
		first=false
	var factor := height/maxf(bounds.size.y,0.01)
	model.scale=Vector3.ONE*factor
	model.position=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)*factor
	root.position=at
	root.rotation.y=angle
	return root
