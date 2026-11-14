extends RefCounted

static func place(room: Node3D, kind: String, at: Vector3) -> Node3D:
	var path := "res://game/offices/assets/crafted/%s-%02d.gltf" % [kind,room.room_index+1]
	var packed: PackedScene = load(path)
	var model: Node3D = packed.instantiate()
	model.name = "DeskTelephone" if kind=="phone" else ("BankerLamp" if kind=="lamp" else "PencilHolder")
	model.position=at
	model.set_meta("finish_level",room.room_index)
	room.add_child(model)
	return model
