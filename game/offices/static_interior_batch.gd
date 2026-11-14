extends RefCounted

# Only direct, static room meshes. Animated folder/door hierarchies and clickable
# areas stay independent. Grouping by material cuts hundreds of small draw calls.
static func combine(room: Node3D) -> void:
	var groups: Dictionary = {}
	var source_count := 0
	for child in room.get_children():
		if not child is MeshInstance3D or child.has_meta("finish_level"):
			continue
		var mesh_node: MeshInstance3D = child
		if mesh_node.material_override == null or mesh_node.mesh == null:
			continue
		if mesh_node.mesh.get_surface_count()!=1:
			continue
		var mat: Material = mesh_node.material_override
		if not groups.has(mat):
			groups[mat]=[]
		groups[mat].append(mesh_node)
		source_count+=1
	var batch_count := 0
	for mat in groups:
		var nodes: Array = groups[mat]
		if nodes.size()<2:
			batch_count+=1
			continue
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for node in nodes:
			tool.append_from(node.mesh,0,node.transform)
		var batch := MeshInstance3D.new()
		batch.name="StaticInteriorBatch"
		batch.mesh=tool.commit()
		batch.material_override=mat
		room.add_child(batch)
		for node in nodes:
			room.remove_child(node)
			node.queue_free()
		batch_count+=1
	room.set_meta("static_meshes_before",source_count)
	room.set_meta("static_meshes_after",batch_count)
