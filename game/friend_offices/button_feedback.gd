extends Button

var artwork: Control
var surface_material: ShaderMaterial
var motion: Tween
var pressure := 0.0
var confirmed := false

func _ready() -> void:
	button_down.connect(func() -> void: move_to(1.0, 0.065))
	button_up.connect(func() -> void:
		if not confirmed:
			move_to(0.0, 0.12)
	)
	draw.connect(func() -> void:
		if surface_material != null:
			surface_material.set_shader_parameter("hovered", get_draw_mode() == DRAW_HOVER)
	)

func play_confirmation() -> void:
	confirmed = true
	stop_motion()
	motion = create_tween()
	motion.tween_method(apply_pressure, pressure, maxf(pressure, 0.78), 0.025)
	motion.tween_method(apply_pressure, maxf(pressure, 0.78), 0.0, 0.115).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion.finished.connect(func() -> void: confirmed = false)

func move_to(target: float, duration: float) -> void:
	if confirmed:
		return
	stop_motion()
	motion = create_tween()
	motion.tween_method(apply_pressure, pressure, target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func stop_motion() -> void:
	if motion != null:
		motion.kill()

func apply_pressure(value: float) -> void:
	pressure = value
	if surface_material != null:
		surface_material.set_shader_parameter("pressure", clampf(value, 0.0, 1.0))
	else:
		self_modulate = Color.WHITE.lerp(Color("#c7ae8a"), clampf(value, 0.0, 1.0))
	if is_instance_valid(artwork):
		artwork.pivot_offset = artwork.size * 0.5
		artwork.scale = Vector2(1.0 - value * 0.014, 1.0 - value * 0.055)
