extends Node3D

const VIEWS := [
	"res://game/offices/assets/views/american-01.png",
	"res://game/offices/assets/views/american-02.png",
	"res://game/offices/assets/views/american-03.png",
	"res://game/offices/assets/views/american-04.png",
	"res://game/offices/assets/views/american-05.png",
	"res://game/offices/assets/views/american-06.png",
]
var width := 2.0
var height := 1.8
var view_path := ""

func setup(owner_room: Node3D, dimensions: Vector2) -> void:
	width = dimensions.x
	height = dimensions.y
	var texture: Texture2D = load(VIEWS[owner_room.room_index])
	view_path = texture.resource_path
	var mesh := QuadMesh.new()
	mesh.size = dimensions
	var plane := MeshInstance3D.new()
	plane.name = "PaintedExterior"
	plane.mesh = mesh
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Crop rather than stretch: buildings keep their proportions in narrow windows.
	var source_ratio := float(texture.get_width())/float(texture.get_height())
	var target_ratio := width/height
	if target_ratio < source_ratio:
		mat.uv1_scale.x = target_ratio/source_ratio
		mat.uv1_offset.x = (1.0-mat.uv1_scale.x)*0.5
	else:
		mat.uv1_scale.y = source_ratio/target_ratio
		mat.uv1_offset.y = (1.0-mat.uv1_scale.y)*0.42
	plane.material_override = mat
	plane.position.z = 0.09
	add_child(plane)
