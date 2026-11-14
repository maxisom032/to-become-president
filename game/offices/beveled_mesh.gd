extends RefCounted

static var cache: Dictionary = {}

static func create(dimensions: Vector3) -> ArrayMesh:
	var key := str(dimensions)
	if cache.has(key):
		return cache[key]
	var h := dimensions / 2.0
	var bevel := minf(0.028, minf(h.x, minf(h.y, h.z)) * 0.28)
	var inner := h - Vector3.ONE * bevel
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in 3:
		var b := (axis + 1) % 3
		var c := (axis + 2) % 3
		for sign_value in [-1.0, 1.0]:
			var points: Array[Vector3] = []
			for pair in [Vector2(-1,-1), Vector2(1,-1), Vector2(1,1), Vector2(-1,1)]:
				var p := Vector3.ZERO
				p[axis] = sign_value * h[axis]
				p[b] = pair.x * inner[b]
				p[c] = pair.y * inner[c]
				points.append(p)
			face(st, points)
		for sb in [-1.0, 1.0]:
			for sc in [-1.0, 1.0]:
				var points: Array[Vector3] = []
				for endpoint in [-1.0, 1.0]:
					var p := Vector3.ZERO
					p[axis] = endpoint * inner[axis]
					p[b] = sb * h[b]
					p[c] = sc * inner[c]
					points.append(p)
				for endpoint in [1.0, -1.0]:
					var p := Vector3.ZERO
					p[axis] = endpoint * inner[axis]
					p[b] = sb * inner[b]
					p[c] = sc * h[c]
					points.append(p)
				face(st, points)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				face(st, [Vector3(sx*h.x,sy*inner.y,sz*inner.z), Vector3(sx*inner.x,sy*h.y,sz*inner.z), Vector3(sx*inner.x,sy*inner.y,sz*h.z)])
	st.generate_tangents()
	var result := st.commit()
	cache[key] = result
	return result

static func face(st: SurfaceTool, points: Array[Vector3]) -> void:
	var normal := (points[1]-points[0]).cross(points[2]-points[0]).normalized()
	var center := Vector3.ZERO
	for p in points:
		center += p
	if normal.dot(center) < 0:
		points.reverse()
		normal = -normal
	for i in range(1, points.size()-1):
		# Godot front faces use clockwise winding.
		for p in [points[0], points[i+1], points[i]]:
			st.set_normal(normal)
			st.set_uv(Vector2(p.x, p.z) if absf(normal.y) > 0.5 else Vector2(p.x if absf(normal.z) > 0.5 else p.z, p.y))
			st.add_vertex(p)
