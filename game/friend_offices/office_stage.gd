extends Control

signal interacted(id: String)

const SURFACE := preload("res://game/friend_offices/office_surface.gdshader")
const Icon := preload("res://game/friend_offices/ui_icon.gd")
const ButtonFeedback := preload("res://game/friend_offices/button_feedback.gd")
const SIGN_FONT := preload("res://game/art/fonts/PTSerif-Bold.ttf")
const CASE_COVER := preload("res://game/friend_offices/assets/case-cover.jpg")
const PHONE_RING = null
const FOLDER_SIZE := Vector2(0.83, 0.91)
const PHONE_POSITION := Vector3(0.73, 1.10, 2.105)
const DOOR_NAMES := {"press": "ВЫХОД"}
const DOOR_IDS := ["press"]
const BRASS := Color("#cd9449")
const CREAM := Color("#f1deaa")
const DARK_WOOD := Color("#502c1d")
const BLACK := Color("#171a19")
const CAMERA_POSITION := Vector3(0, 2.86, 5.4)
const CAMERA_TARGET := Vector3(0, 1.34, -1.8)
const MAX_RENDER_PIXELS := 4_800_000.0

var view: SubViewport
var camera: Camera3D
var room: Node3D
var hotspots := {}
var badges := {}
var doors := {}
var plaques := {}
var paper: Node3D
var paper_cover: Node3D
var paper_number: Label3D
var paper_origin: Vector3
var visitor: Sprite3D
var wall_material: ShaderMaterial
var desk_material: ShaderMaterial
var trim_material: ShaderMaterial
var door_material: ShaderMaterial
var door_inset_material: ShaderMaterial
var carpet_material: ShaderMaterial
var rank_rooms: Array[Node3D] = []
var upgrades: Dictionary[Node3D, int] = {}
var room_environment: Environment
var wall_clock: Node3D
var rank := -1
var current_pose := ""
var current_speaker := ""
var motion: Tween
var attention: Tween
var phone_signal: Control
var phone_audio: AudioStreamPlayer
var interaction_pending := false
var transition_speed := 1.0
var career_rooms: Array[Node3D] = []
var career_level := 0
var career_doors: Array[Node3D] = []

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	view = SubViewport.new()
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	var surface := TextureRect.new()
	surface.texture = view.get_texture()
	surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	surface.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	room = Node3D.new()
	view.add_child(room)
	build_room()
	for id in DOOR_IDS + ["paper", "phone"]:
		var button := ButtonFeedback.new()
		button.name = "Room_" + id
		button.focus_mode = FOCUS_ALL
		button.flat = true
		button.tooltip_text = {"paper": "Открыть дело", "phone": "Ответить на звонок"}.get(id, str(DOOR_NAMES.get(id, "")).capitalize())
		button.pressed.connect(confirm_interaction.bind(button, id))
		add_child(button)
		hotspots[id] = button
		if id == "paper" or id == "phone":
			var focus := plaque_style(Color.TRANSPARENT, Color("#f1c675"))
			focus.set_border_width_all(2)
			focus.shadow_color = Color.TRANSPARENT
			button.add_theme_stylebox_override("focus", focus)
			if id == "phone":
				build_phone_signal(button)
			continue
		var badge := Panel.new()
		badge.mouse_filter = MOUSE_FILTER_IGNORE
		button.add_child(badge)
		button.artwork = badge
		var contents := VBoxContainer.new()
		contents.alignment = BoxContainer.ALIGNMENT_CENTER
		contents.add_theme_constant_override("separation", 1)
		contents.mouse_filter = MOUSE_FILTER_IGNORE
		badge.add_child(contents)
		contents.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		var symbol := Icon.new(id, CREAM, 22)
		contents.add_child(symbol)
		var caption := Label.new()
		caption.text = DOOR_NAMES[id]
		caption.mouse_filter = MOUSE_FILTER_IGNORE
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 12)
		contents.add_child(caption)
		var marker := PanelContainer.new()
		marker.mouse_filter = MOUSE_FILTER_IGNORE
		var seal := plaque_style(Color("#f3ca72"), Color("#fff0c6"))
		seal.set_corner_radius_all(10)
		seal.border_width_bottom = 1
		marker.add_theme_stylebox_override("panel", seal)
		marker.add_child(Icon.new("star", Color("#513015"), 17))
		badge.add_child(marker)
		marker.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
		marker.position += Vector2(-9, -7)
		marker.hide()
		badges[id] = {"plate": badge, "caption": caption, "symbol": symbol, "marker": marker}
		button.mouse_entered.connect(func() -> void: badge.modulate = Color(1.15, 1.12, 1.05))
		button.mouse_exited.connect(func() -> void: badge.modulate = Color.WHITE)
	resized.connect(update_render_size)
	get_window().size_changed.connect(update_render_size)
	view.size_changed.connect(update_projection)
	phone_audio = AudioStreamPlayer.new()
	phone_audio.stream = PHONE_RING
	phone_audio.volume_db = -19
	add_child(phone_audio)
	phone_audio.finished.connect(func() -> void:
		if phone_signal.is_visible_in_tree():
			phone_audio.play()
	)
	set_rank(0)
	update_render_size()

func confirm_interaction(button: ButtonFeedback, id: String) -> void:
	if interaction_pending:
		return
	interaction_pending = true
	button.play_confirmation()
	get_tree().create_timer(0.12).timeout.connect(func() -> void:
		interaction_pending = false
		if button.visible:
			interacted.emit(id)
	)

func update_render_size() -> void:
	if view == null or size.x < 2 or size.y < 2:
		return
	# The 2D interface uses logical coordinates. The room needs one sample per
	# output pixel before MSAA, even when the interface is scaled up for Retina.
	var pixels := size * get_viewport().get_final_transform().get_scale()
	var reduction := minf(1.0, sqrt(MAX_RENDER_PIXELS / (pixels.x * pixels.y)))
	var target := Vector2i((pixels * reduction).round()).max(Vector2i(2, 2))
	if view.size != target:
		view.size = target
	update_projection()
	refresh_room()

func refresh_room() -> void:
	if motion == null or not motion.is_running():
		view.render_target_update_mode = SubViewport.UPDATE_ONCE

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(view):
		update_render_size()

func set_active(id: String, playable: bool) -> void:
	if attention != null and attention.is_running():
		attention.kill()
	var ringing := id == "phone" and playable
	phone_signal.visible = ringing
	if ringing:
		phone_signal.modulate.a = 1.0
		if not phone_audio.playing:
			phone_audio.play()
		attention = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		attention.tween_property(phone_signal, "modulate:a", 0.58, 0.37)
		attention.tween_property(phone_signal, "modulate:a", 1.0, 0.37)
	elif phone_audio.playing:
		phone_audio.stop()
	for key in hotspots:
		var button: Button = hotspots[key]
		button.visible = ringing if key == "phone" else playable
		if key == "paper" or key == "phone":
			continue
		var highlighted: bool = key == id and playable
		var plate_colors := ["#e5c994", "#dcb877", "#a77d48", "#6c4931"]
		var rim_colors := ["#bf914e", "#c29551", "#d0a35e", "#c9a264"]
		var background := Color("#873725") if highlighted else Color(plate_colors[rank])
		var ink := Color("#fff1ca") if highlighted or rank == 3 else Color("#342419")
		var badge: Dictionary = badges[key]
		badge["caption"].add_theme_color_override("font_color", ink)
		badge["symbol"].ink = ink
		var style := plaque_style(background, Color("#f1c675") if highlighted else Color(rim_colors[rank]))
		if highlighted:
			style.shadow_color = Color("#f6bc5b65")
			style.shadow_size = 8
		badge["plate"].add_theme_stylebox_override("panel", style)
		var marker: PanelContainer = badge["marker"]
		marker.visible = highlighted
		marker.modulate.a = 1.0
		if highlighted:
			attention = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
			attention.tween_property(marker, "modulate:a", 0.62, 0.65)
			attention.tween_property(marker, "modulate:a", 1.0, 0.65)
		button.add_theme_stylebox_override("focus", plaque_style(Color.TRANSPARENT, CREAM))
		if plaques.has(key):
			var sign: Label3D = plaques[key]
			sign.visible = not playable
	refresh_room()

func build_phone_signal(button: Button) -> void:
	phone_signal = Control.new()
	phone_signal.mouse_filter = MOUSE_FILTER_IGNORE
	button.add_child(phone_signal)
	phone_signal.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	phone_signal.resized.connect(phone_signal.queue_redraw)
	phone_signal.draw.connect(func() -> void:
		var center := phone_signal.size / 2.0
		var gold := Color("#ffce6c")
		phone_signal.draw_set_transform(center + Vector2(0, 12), 0.0, Vector2(1.0, 0.42))
		phone_signal.draw_arc(Vector2.ZERO, 32, 0, TAU, 48, Color("#f1a54278"), 5, true)
		phone_signal.draw_arc(Vector2.ZERO, 32, 0, TAU, 48, gold, 1.6, true)
		phone_signal.draw_set_transform(center - Vector2(0, 9))
		for radius in [24.0, 32.0]:
			phone_signal.draw_arc(Vector2.ZERO, radius, -2.97, -2.40, 14, gold, 1.9, true)
			phone_signal.draw_arc(Vector2.ZERO, radius, -0.74, -0.17, 14, gold, 1.9, true)
	)

func set_case_number(number: int) -> void:
	paper_number.text = "№ %03d" % number
	hotspots["paper"].tooltip_text = "Открыть дело " + paper_number.text
	refresh_room()

func set_rank(level: int) -> void:
	if rank == level:
		return
	rank = level
	var walls := ["#285054", "#596347", "#253e5b", "#653542"]
	var desks := ["#785339", "#9b693a", "#503a2c", "#3f2824"]
	var trims := ["#694832", "#715030", "#3c2a25", "#322320"]
	var doors_oak := ["#8b5839", "#765133", "#4b3226", "#35241f"]
	var panels := ["#69432d", "#573824", "#35221a", "#251917"]
	var carpets := ["#743a30", "#6b5438", "#264858", "#753341"]
	wall_material.set_shader_parameter("tint", Color(walls[rank]))
	wall_material.set_shader_parameter("wallpaper", rank)
	desk_material.set_shader_parameter("tint", Color(desks[rank]))
	trim_material.set_shader_parameter("tint", Color(trims[rank]))
	door_material.set_shader_parameter("tint", Color(doors_oak[rank]))
	door_inset_material.set_shader_parameter("tint", Color(panels[rank]))
	carpet_material.set_shader_parameter("tint", Color(carpets[rank]))
	room_environment.ambient_light_color = Color(["#e2e2e0", "#fff2db", "#dae6ff", "#ffded0"][rank])
	if is_instance_valid(wall_clock): wall_clock.visible = true
	for index in rank_rooms.size():
		rank_rooms[index].visible = index == rank
	for decoration in upgrades:
		decoration.visible = rank >= upgrades[decoration]
	refresh_room()

func upgrade(parent: Node3D, level: int) -> Node3D:
	var decoration := Node3D.new()
	parent.add_child(decoration)
	upgrades[decoration] = level
	return decoration

func set_pose(id: String, speaker: String) -> Tween:
	if current_pose == id and current_speaker == speaker:
		return motion if motion != null and motion.is_running() else null
	var closing_case := current_pose == "paper" and id != "paper"
	current_pose = id
	current_speaker = speaker
	if motion != null and motion.is_running():
		motion.kill()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	motion = create_tween().set_speed_scale(transition_speed).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for key in doors:
		motion.tween_property(doors[key], "rotation:y", deg_to_rad(-99.0) if key == id else 0.0, 0.39)
	var paper_open := id == "paper"
	var eye := CAMERA_POSITION
	var focus := CAMERA_TARGET
	if id == "title":
		eye = Vector3(0.13, 2.68, 5.10)
		focus = Vector3(0, 1.33, -2.0)
	elif paper_open:
		eye = paper_origin + Vector3(0.21, 1.93, 1.22)
		focus = paper_origin + Vector3(-0.05, 0.02, -0.04)
		var open_cover := motion.tween_property(paper_cover, "rotation:z", deg_to_rad(117.0), 0.31)
		open_cover.set_delay(0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif closing_case:
		motion.tween_property(paper_cover, "rotation:z", 0.0, 0.24)
	if doors.has(id):
		var x := door_x(id)
		eye = Vector3(x * 0.72, 2.10, 2.95 if speaker.is_empty() else 0.20)
		focus = Vector3(x * 0.94, 1.48 if speaker.is_empty() else 1.16, -3.20)
	var start := camera.transform
	var destination := Transform3D(Basis.IDENTITY, eye).looking_at(focus)
	var camera_move := motion.tween_method(func(weight: float) -> void:
		camera.transform = start.interpolate_with(destination, weight)
		if id.is_empty():
			update_projection()
	, 0.0, 1.0, 0.52 if paper_open else 0.45)
	if paper_open:
		camera_move.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	elif closing_case:
		camera_move.set_delay(0.12)
	if speaker.is_empty():
		if visitor.visible:
			motion.tween_property(visitor, "modulate:a", 0.0, 0.16)
	motion.finished.connect(func() -> void:
		visitor.visible = not speaker.is_empty()
		update_projection()
		view.render_target_update_mode = SubViewport.UPDATE_ONCE
	)
	return motion

func case_screen_center() -> Vector2:
	return global_position + room_to_ui(paper.to_global(Vector3(0, 0.024, 0)))

func door_x(id: String) -> float:
	return 0.0

func update_projection() -> void:
	if camera == null or view.size.x <= 0 or view.size.y <= 0:
		return
	var aspect := float(view.size.x) / view.size.y
	camera.fov = clampf(rad_to_deg(2.0 * atan(0.264 / aspect)), 43.0, 67.0)
	for index in DOOR_IDS.size():
		var id: String = DOOR_IDS[index]
		var x := door_x(id)
		var top_left := room_to_ui(Vector3(x - 0.59, 2.42, -3.07))
		var bottom_right := room_to_ui(Vector3(x + 0.59, 0.02, -3.07))
		place_hotspot(id, Rect2(top_left, bottom_right - top_left), Vector3(x, 1.77, -3.07), Vector2(85, 55))
	var paper_button: Button = hotspots.get("paper")
	if paper_button != null:
		var area := Rect2(room_to_ui(paper.global_position), Vector2.ZERO)
		for x in [-0.5, 0.5]:
			for z in [-0.5, 0.5]:
				var corner := paper.to_global(Vector3(x * FOLDER_SIZE.x, 0.018, z * FOLDER_SIZE.y))
				area = area.expand(room_to_ui(corner))
		area = area.grow(8)
		paper_button.position = area.position
		paper_button.size = area.size
	var phone_button: Button = hotspots.get("phone")
	if phone_button != null:
		phone_button.size = Vector2(68, 57)
		var center := room_to_ui(PHONE_POSITION + Vector3(0, 0.10, 0))
		phone_button.position = center - phone_button.size / 2.0

func place_hotspot(id: String, area: Rect2, anchor: Vector3, dimensions: Vector2) -> void:
	var button: Button = hotspots.get(id)
	if button == null:
		return
	var badge: Panel = badges[id]["plate"]
	button.position = area.position
	button.size = area.size
	badge.size = dimensions
	badge.position = room_to_ui(anchor) - button.position - dimensions / 2.0

func room_to_ui(point: Vector3) -> Vector2:
	return camera.unproject_position(point) * size / Vector2(view.size)

func plaque_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	return style

func build_room() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	room_environment = env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#18272b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e2e2e0")
	env.ambient_light_energy = 0.53
	world.environment = env
	room.add_child(world)
	camera = Camera3D.new()
	room.add_child(camera)
	camera.position = CAMERA_POSITION
	camera.look_at(CAMERA_TARGET)
	camera.current = true

	wall_material = surface_material(Color.WHITE, 2)
	desk_material = surface_material(Color.WHITE, 3)
	trim_material = surface_material(Color.WHITE, 1)
	door_material = surface_material(Color.WHITE, 4)
	door_inset_material = surface_material(Color.WHITE, 4)
	carpet_material = surface_material(Color.WHITE, 0)
	var wood := surface_material(DARK_WOOD, 1)
	var floor_material := surface_material(Color("#534135"), 3)
	var dark := solid(BLACK)
	var brass := solid(BRASS, 0.28, 0.48)
	var light := solid(Color("#ffcf7e"), 0, 0.65, true)
	var rail := solid(Color("#a37845"))
	block(room, Vector3(0, -0.09, 0.0), Vector3(9.0, 0.18, 13.0), floor_material)
	var plaster := surface_material(Color("#2f3532"), 0)
	block(room, Vector3(0, 3.58, -0.3), Vector3(9.0, 0.2, 12.0), plaster)
	for z in [-2.75, -1.0, 0.8, 2.6]:
		block(room, Vector3(0, 3.47, z), Vector3(6.60, 0.10, 0.14), wood)
	for side in [-1, 1]:
		block(room, Vector3(side * 3.31, 1.76, -0.25), Vector3(0.16, 3.55, 8.0), wall_material)
		block(room, Vector3(side * 3.21, 0.15, -0.25), Vector3(0.11, 0.3, 8.0), trim_material)
	block(room, Vector3(0, 3.02, -3.24), Vector3(6.6, 1.09, 0.32), wall_material)
	for x in [-1.94, 1.94]:
		var width := 2.72
		block(room, Vector3(x, 1.23, -3.24), Vector3(width, 2.49, 0.32), wall_material)
		block(room, Vector3(x, 0.17, -3.05), Vector3(width, 0.29, 0.09), trim_material)
	block(room, Vector3(0, 3.34, -3.02), Vector3(6.6, 0.16, 0.13), trim_material)
	block(room, Vector3(0, 3.47, -2.03), Vector3(6.6, 0.16, 0.22), wood)
	for level in 4:
		var furnishings := Node3D.new()
		furnishings.name = "OfficeRank%d" % level
		room.add_child(furnishings)
		rank_rooms.append(furnishings)
	build_rank_details(wood, brass, dark)
	block(room, Vector3(0, 2.69, -3.02), Vector3(4.26, 0.05, 0.13), trim_material)

	var void_material := solid(Color("#100c0c"))
	void_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	block(room, Vector3(0, 1.28, -4.10), Vector3(7.0, 2.61, 0.06), void_material)
	block(room, Vector3(0, 0, -3.64), Vector3(7.0, 0.021, 0.91), void_material)
	for index in DOOR_IDS.size():
		build_door(DOOR_IDS[index], door_x(DOOR_IDS[index]), wood, brass)
	visitor = Sprite3D.new()
	visitor.shaded = false
	visitor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visitor.visible = false
	room.add_child(visitor)

	block(room, Vector3(0, 0.014, -1.25), Vector3(1.57, 0.029, 3.45), carpet_material)
	for side in [-1, 1]:
		block(room, Vector3(side * 0.68, 0.032, -1.25), Vector3(0.025, 0.009, 3.26), rail)
		block(room, Vector3(0, 0.032, -1.25 + side * 1.60), Vector3(1.36, 0.009, 0.028), rail)
	for z in [-2.47, -1.87, -1.27, -0.67, -0.07]:
		var motif := block(room, Vector3(0, 0.033, z), Vector3(0.28, 0.009, 0.28), rail)
		motif.rotation.y = PI / 4.0

	# Ceiling pendant and shaded fill separate the foreground from the doors.
	light_at(Vector3(0, 2.76, -1.52), Color("#ffbd75"), 1.31, 6.3, true)
	light_at(Vector3(-2.8, 3.0, -1.72), Color("#a1d6f0"), 0.76, 4.2)
	light_at(Vector3(0.90, 3.05, 2.38), Color("#ffe2c3"), 0.47, 6.6)
	build_pendant(rank_rooms[0], 0.0, 2.99, 0.31, dark, trim_material, light)
	build_pendant(rank_rooms[1], 0.0, 3.04, 0.30, brass, door_material, light)
	for level in [2, 3]:
		for x in [-1.42, 1.42]:
			build_pendant(rank_rooms[level], x, 3.12, 0.20 if level == 2 else 0.24, brass, door_inset_material, light)
		var ceiling := rank_rooms[level]
		for x in [-1.63, 0.0, 1.63]:
			block(ceiling, Vector3(x, 3.447, -1.4), Vector3(0.13, 0.105, 4.14), trim_material)
			if level == 3:
				block(ceiling, Vector3(x, 3.39, -1.4), Vector3(0.019, 0.013, 4.05), brass)

	build_desk(wood, brass, light, dark)
	build_career_contrast(wood,brass,dark)

func build_pendant(parent: Node3D, x: float, height: float, radius: float, metal: Material, shade: Material, light: Material) -> void:
	var cord_height := 3.50 - height
	var cord := rod(parent, Vector3(x, height + cord_height * 0.5, -1.85), 0.018, 0.018, cord_height, metal)
	cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pendant := dome(parent, Vector3(x, height, -1.85), radius, radius * 0.61, shade)
	pendant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bulb := rod(parent, Vector3(x, height - 0.009, -1.85), radius * 0.94, radius * 0.95, 0.018, light)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func build_door(id: String, x: float, wood: Material, brass: Material) -> void:
	for side in [-1, 1]:
		block(room, Vector3(x + side * 0.61, 1.22, -3.00), Vector3(0.13, 2.44, 0.16), trim_material)
		block(room, Vector3(x + side * 0.57, 1.22, -2.99), Vector3(0.03, 2.41, 0.17), wood)
		block(room, Vector3(x + side * 0.65, 1.23, -2.908), Vector3(0.024, 2.40, 0.031), wood)
	block(room, Vector3(x, 2.45, -3.00), Vector3(1.35, 0.15, 0.19), trim_material)
	block(room, Vector3(x, 2.51, -2.89), Vector3(1.39, 0.034, 0.07), wood)
	block(room, Vector3(x, 0.025, -3.02), Vector3(1.21, 0.05, 0.22), brass)
	var pivot := Node3D.new()
	room.add_child(pivot)
	pivot.position = Vector3(x - 0.54, 0.025, -3.10)
	doors[id] = pivot
	block(pivot, Vector3(0.54, 1.16, 0), Vector3(1.08, 2.31, 0.1), door_material)
	for position in [Vector2(0.57, 0.72), Vector2(1.54, 0.88)]:
		for face in [-1.0, 1.0]:
			block(pivot, Vector3(0.54, position.x, face * 0.054), Vector3(0.83, position.y, 0.032), door_inset_material)
			block(pivot, Vector3(0.54, position.x, face * 0.077), Vector3(0.74, position.y - 0.11, 0.025), door_material)
	block(pivot, Vector3(0.93, 0.96, 0.07), Vector3(0.088, 0.17, 0.028), brass)
	var handle := rod(pivot, Vector3(0.93, 1.00, 0.116), 0.044, 0.055, 0.065, brass)
	handle.rotation.x = PI / 2.0
	var casing := upgrade(room, 1)
	block(casing, Vector3(x, 2.56, -2.927), Vector3(1.32, 0.074, 0.12), door_inset_material)
	block(casing, Vector3(x, 2.604, -2.891), Vector3(1.40, 0.026, 0.098), door_material)
	var hardwood := upgrade(pivot, 2)
	for y in [0.57, 1.54]:
		var panel_height := 0.69 if y < 1.0 else 0.85
		frame_molding(hardwood, Vector3(0.54, y, 0.099), Vector2(0.79, panel_height), 0.024, door_inset_material)
	block(hardwood, Vector3(0.54, 1.033, 0.072), Vector3(0.99, 0.042, 0.045), door_inset_material)
	var carved := upgrade(pivot, 3)
	frame_molding(carved, Vector3(0.54, 0.57, 0.106), Vector2(0.67, 0.54), 0.011, brass)
	for flute in 3:
		block(carved, Vector3(0.42 + flute * 0.12, 0.57, 0.097), Vector3(0.017, 0.36, 0.023), door_inset_material)

func frame_molding(parent: Node3D, center: Vector3, extents: Vector2, thickness: float, material: Material) -> void:
	for side in [-1, 1]:
		block(parent, center + Vector3(side * extents.x / 2.0, 0, 0), Vector3(thickness, extents.y, 0.025), material)
		block(parent, center + Vector3(0, side * extents.y / 2.0, 0), Vector3(extents.x + thickness, thickness, 0.025), material)

func door_sign(pivot: Node3D, title: String, at: Vector3) -> Label3D:
	var sign := Label3D.new()
	sign.text = title
	sign.font = SIGN_FONT
	sign.font_size = 42
	sign.pixel_size = 0.00163
	sign.outline_size = 0
	sign.modulate = Color("#3d2a1d")
	pivot.add_child(sign)
	sign.position = at
	return sign

func build_desk(wood: Material, brass: Material, light: Material, dark: Material) -> void:
	for level in rank_rooms.size():
		build_desk_furniture(rank_rooms[level], level, brass, light, dark)
	light_at(Vector3(-0.81, 1.47, 1.80), Color("#ffd092"), 0.64, 2.0)
	build_desk_accessories(wood, brass, dark)
	var red := solid(Color("#a33f2d"))
	var marker := rod(room, Vector3(0.54, 1.087, 2.31), 0.017, 0.017, 0.43, red)
	marker.rotation_degrees = Vector3(89, 0, 65)
	var sheets := [
		solid(Color("#d6bf94")), solid(Color("#ead5ad")), solid(Color("#f7e5bd")),
	]
	for i in 9:
		var sheet := block(room, Vector3(0.025 + sin(i * 4.0) * 0.028, 1.094 + i * 0.009, 2.05 + cos(i * 3.2) * 0.027), Vector3(0.78, 0.011, 0.85), sheets[i % sheets.size()])
		sheet.rotation.y = sin(i * 5.0) * 0.09
	build_case_folder(red)

func build_desk_furniture(parent: Node3D, level: int, brass: Material, light: Material, dark: Material) -> void:
	var width: float = [2.92, 3.14, 3.48, 3.73][level]
	var front: float = [2.76, 2.82, 2.95, 3.02][level]
	var rear := 1.39
	var depth := front - rear
	var center := (front + rear) / 2.0
	var edge := trim_material if level < 2 else door_inset_material
	block(parent, Vector3(0, 1.017, center), Vector3(width, 0.111, depth), desk_material)
	block(parent, Vector3(0, 0.949, center), Vector3(width - 0.035, 0.032, depth - 0.025), edge)
	block(parent, Vector3(0, 0.86, center), Vector3(width - 0.18, 0.16, depth - 0.16), door_material)
	var rail := brass if level > 0 else trim_material
	block(parent, Vector3(0, 0.987, front + 0.009), Vector3(width - 0.025, 0.018, 0.027), rail)
	for side in [-1.0, 1.0]:
		var x: float = side * (width * 0.5 - 0.34)
		var pedestal := 0.26 + level * 0.09
		block(parent, Vector3(x, 0.41, center), Vector3(pedestal, 0.82, depth - 0.24), door_material)
		block(parent, Vector3(x, 0.048, center), Vector3(pedestal + 0.10, 0.096, depth - 0.19), edge)
		for row in 2:
			var y := 0.45 + row * 0.22
			block(parent, Vector3(x, y, front - 0.104), Vector3(pedestal - 0.027, 0.18, 0.04), edge)
			block(parent, Vector3(x, y, front - 0.078), Vector3(0.105, 0.021, 0.025), rail)
		if level >= 2:
			block(parent, Vector3(side * (width * 0.5 - 0.065), 0.46, front - 0.12), Vector3(0.11, 0.81, 0.11), edge)
	var felt_colors := ["#2e4a42", "#484c2b", "#26394a", "#201d1b"]
	var blotter := surface_material(Color(felt_colors[level]), 0)
	var blotter_size: Vector2 = [Vector2(1.62, 1.05), Vector2(2.11, 1.11), Vector2(2.46, 1.22), Vector2(2.83, 1.32)][level]
	block(parent, Vector3(0.08, 1.08, 2.16), Vector3(blotter_size.x, 0.017, blotter_size.y), blotter)
	var piping := solid(Color(["#5f6247", "#b58d51", "#a88550", "#b88d50"][level]))
	for side in [-1.0, 1.0]:
		block(parent, Vector3(0.08 + side * (blotter_size.x * 0.5 - 0.024), 1.09, 2.16), Vector3(0.011, 0.003, blotter_size.y - 0.04), piping)
		block(parent, Vector3(0.08, 1.09, 2.16 + side * (blotter_size.y * 0.5 - 0.022)), Vector3(blotter_size.x - 0.04, 0.003, 0.011), piping)
	if level >= 2:
		for x in [-0.64, 0.0, 0.64]:
			frame_molding(parent, Vector3(x, 0.852, front - 0.055), Vector2(0.48, 0.109), 0.012, rail)


func build_case_folder(tab_material: Material) -> void:
	paper = Node3D.new()
	paper.name = "CaseFolder"
	room.add_child(paper)
	paper_origin = Vector3(0.025, 1.179, 2.05)
	paper.position = paper_origin
	paper.rotation.y = 0.08
	var kraft := surface_material(Color("#9e6947"), 0)
	block(paper, Vector3(0, -0.018, 0), Vector3(FOLDER_SIZE.x, 0.014, FOLDER_SIZE.y), kraft)
	var sheet := surface_material(Color("#c8ae82"), 0)
	block(paper, Vector3(0.014, -0.006, 0.008), Vector3(0.746, 0.011, 0.839), sheet)
	var rules := solid(Color("#a48b68"))
	block(paper, Vector3(-0.30, 0.001, 0), Vector3(0.005, 0.002, 0.77), rules)
	for line in 7:
		var width := 0.52 if line < 6 else 0.34
		block(paper, Vector3(-0.27 + width / 2.0, 0.001, -0.18 + line * 0.064), Vector3(width, 0.002, 0.004), rules)
	block(paper, Vector3(-0.19, 0.001, -0.30), Vector3(0.16, 0.002, 0.027), tab_material)
	block(paper, Vector3(0.410, -0.012, -0.275), Vector3(0.086, 0.015, 0.133), tab_material)

	paper_cover = Node3D.new()
	paper_cover.name = "CoverHinge"
	paper.add_child(paper_cover)
	var half_width := FOLDER_SIZE.x / 2.0
	paper_cover.position.x = -half_width
	var cover_center := Vector3(half_width, 0, 0)
	block(paper_cover, cover_center + Vector3(0, 0.005, 0), Vector3(FOLDER_SIZE.x, 0.013, FOLDER_SIZE.y), kraft)
	var front := PlaneMesh.new()
	front.size = FOLDER_SIZE
	var print := solid(Color.WHITE, 0.0, 0.95)
	print.albedo_texture = CASE_COVER
	prop(paper_cover, cover_center + Vector3(0, 0.012, 0), front, print)
	block(paper, Vector3(-half_width + 0.008, -0.007, 0), Vector3(0.018, 0.024, 0.899), kraft)
	paper_number = Label3D.new()
	paper_number.font = SIGN_FONT
	paper_number.font_size = 68
	paper_number.pixel_size = 0.00215
	paper_number.modulate = Color("#332017")
	paper_number.outline_size = 0
	paper_cover.add_child(paper_number)
	paper_number.position = cover_center + Vector3(0, 0.015, -0.054)
	paper_number.rotation.x = -PI / 2.0

func open_cylinder(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, material: Material) -> void:
	var shell := CylinderMesh.new()
	shell.top_radius = top
	shell.bottom_radius = bottom
	shell.height = height
	shell.radial_segments = 48
	shell.rings = 0
	shell.cap_top = false
	shell.cap_bottom = false
	prop(parent, at, shell, material)

func cup_rim(parent: Node3D, y: float, radius: float, thickness: float, material: Material) -> void:
	var rim := TorusMesh.new()
	rim.inner_radius = radius - thickness
	rim.outer_radius = radius + thickness
	rim.rings = 48
	rim.ring_segments = 10
	prop(parent, Vector3(0, y, 0), rim, material)

func make_pen(parent: Node3D, length: float, lacquer: Material, brass: Material, dark: Material) -> Node3D:
	var pen := Node3D.new()
	parent.add_child(pen)
	var cap_base := length - 0.138
	rod(pen, Vector3(0, cap_base * 0.5, 0), 0.015, 0.011, cap_base, lacquer)
	rod(pen, Vector3(0, length - 0.068, 0), 0.018, 0.019, 0.136, lacquer)
	rod(pen, Vector3(0, cap_base + 0.012, 0), 0.020, 0.020, 0.010, brass)
	rod(pen, Vector3(0, length - 0.007, 0), 0.014, 0.018, 0.014, brass)
	rod(pen, Vector3(0, length + 0.003, 0), 0.010, 0.013, 0.006, dark)
	var clip := block(pen, Vector3(0, length - 0.054, 0.023), Vector3(0.009, 0.085, 0.008), brass)
	clip.rotation.x = -0.035
	return pen

func make_pencil(parent: Node3D, length: float, paint: Material, cedar: Material, graphite: Material) -> Node3D:
	var pencil := Node3D.new()
	parent.add_child(pencil)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.013
	barrel.bottom_radius = 0.013
	barrel.radial_segments = 6
	barrel.height = length - 0.057
	prop(pencil, Vector3(0, barrel.height * 0.5, 0), barrel, paint)
	rod(pencil, Vector3(0, length - 0.035, 0), 0.004, 0.013, 0.044, cedar)
	rod(pencil, Vector3(0, length - 0.006, 0), 0.0008, 0.0045, 0.014, graphite)
	return pencil

func build_desk_accessories(wood: Material, brass: Material, dark: Material) -> void:
	var stamp := Node3D.new()
	room.add_child(stamp)
	stamp.position = Vector3(-0.62, 1.089, 2.22)
	var lacquer := solid(Color("#742f28"), 0.14, 0.38)
	rod(stamp, Vector3(0, 0.022, 0), 0.095, 0.103, 0.044, dark)
	rod(stamp, Vector3(0, 0.052, 0), 0.078, 0.090, 0.023, brass)
	rod(stamp, Vector3(0, 0.096, 0), 0.033, 0.047, 0.074, wood)
	dome(stamp, Vector3(0, 0.142, 0), 0.061, 0.054, lacquer)
	rod(stamp, Vector3(0, 0.139, 0), 0.060, 0.047, 0.024, lacquer)

	var notebook := Node3D.new()
	room.add_child(notebook)
	notebook.position = Vector3(0.64, 1.10, 2.48)
	notebook.rotation.y = -0.20
	var cover := surface_material(Color("#784139"), 0)
	var pages := surface_material(Color("#d8c19b"), 0)
	block(notebook, Vector3.ZERO, Vector3(0.40, 0.024, 0.30), cover)
	block(notebook, Vector3(0, 0.025, 0), Vector3(0.382, 0.043, 0.282), pages)
	block(notebook, Vector3(0, 0.049, 0), Vector3(0.40, 0.016, 0.30), cover)
	block(notebook, Vector3(-0.184, 0.022, 0), Vector3(0.034, 0.069, 0.30), lacquer)
	block(notebook, Vector3(0.107, 0.025, 0.16), Vector3(0.024, 0.007, 0.089), solid(Color("#ba8a47")))
	block(notebook, Vector3(0.016, 0.060, 0), Vector3(0.17, 0.005, 0.067), brass)
	for y in [0.016, 0.024, 0.033]:
		block(notebook, Vector3(0.009, y, 0.141), Vector3(0.347, 0.0015, 0.002), solid(Color("#9a7d5a")))

func build_rank_details(wood: Material, brass: Material, dark: Material) -> void:
	var starter := rank_rooms[0]

	var coordinator := rank_rooms[1]
	build_district_map(coordinator, wood, brass)
	build_mail_tray(coordinator, brass)

	var paneling := upgrade(room, 2)
	for x in [-2.13, -0.714, 0.714, 2.13]:
		block(paneling, Vector3(x, 1.32, -3.032), Vector3(0.135, 2.6, 0.094), trim_material)
		block(paneling, Vector3(x, 1.33, -2.973), Vector3(0.025, 2.52, 0.014), door_inset_material)
	block(paneling, Vector3(0, 2.66, -3.02), Vector3(4.36, 0.057, 0.115), trim_material)
	build_wall_sconce(paneling, -1.04, brass)
	build_wall_sconce(paneling, 1.04, brass)

	var council := rank_rooms[2]
	var council_plate := Vector3(1.56, 2.94, -3.02)
	block(council, council_plate, Vector3(0.60, 0.23, 0.031), wood)
	frame_molding(council, council_plate + Vector3(0, 0, 0.023), Vector2(0.55, 0.18), 0.008, brass)
	var caption := door_sign(council, "СОВЕТ ПАРТИИ", council_plate + Vector3(0, 0, 0.04))
	caption.modulate = CREAM
	caption.pixel_size = 0.00092

	var campaign_hq := rank_rooms[3]
	for side in [-1.0, 1.0]:
		build_banner(campaign_hq, side * 1.53, brass, side > 0)

func build_district_map(parent: Node3D, wood: Material, brass: Material) -> void:
	var center := Vector3(1.38, 2.95, -3.02)
	block(parent, center, Vector3(0.94, 0.41, 0.05), wood)
	block(parent, center + Vector3(0, 0, 0.028), Vector3(0.87, 0.35, 0.018), solid(Color("#bfa873")))
	frame_molding(parent, center + Vector3(0, 0, 0.04), Vector2(0.91, 0.38), 0.014, brass)
	var river := solid(Color("#526b68"))
	for i in 4:
		var section := block(parent, center + Vector3(-0.31 + i * 0.20, -0.058 + i * 0.029, 0.04), Vector3(0.23, 0.021, 0.006), river)
		section.rotation.z = 0.15
	var marker := solid(Color("#853d34"))
	for offset in [Vector2(-0.24, 0.04), Vector2(0.10, -0.07), Vector2(0.28, 0.095)]:
		var dot := rod(parent, center + Vector3(offset.x, offset.y, 0.048), 0.02, 0.02, 0.009, marker)
		dot.rotation.x = PI / 2.0

func build_mail_tray(parent: Node3D, brass: Material) -> void:
	var center := Vector3(-0.70, 1.114, 2.51)
	block(parent, center, Vector3(0.37, 0.034, 0.31), door_material)
	for side in [-1.0, 1.0]:
		block(parent, center + Vector3(side * 0.176, 0.029, 0), Vector3(0.025, 0.06, 0.31), trim_material)
	block(parent, center + Vector3(0, 0.025, 0.144), Vector3(0.35, 0.039, 0.022), trim_material)
	block(parent, center + Vector3(0, 0.028, 0.157), Vector3(0.11, 0.018, 0.009), brass)
	var paper_stock := solid(Color("#d7c39a"))
	for sheet in 3:
		var note := block(parent, center + Vector3(0, 0.019 + sheet * 0.009, -0.02), Vector3(0.29, 0.008, 0.23), paper_stock)
		note.rotation.y = -0.08 + sheet * 0.04

func build_wall_sconce(parent: Node3D, x: float, brass: Material) -> void:
	block(parent, Vector3(x, 2.93, -3.011), Vector3(0.104, 0.265, 0.045), brass)
	block(parent, Vector3(x, 2.859, -2.93), Vector3(0.033, 0.035, 0.135), brass)
	var shade := solid(Color("#f0c487"), 0.0, 0.65, true)
	rod(parent, Vector3(x, 2.966, -2.875), 0.095, 0.061, 0.145, shade)
	rod(parent, Vector3(x, 3.042, -2.875), 0.092, 0.097, 0.012, brass)

func build_wall_crest(parent: Node3D, brass: Material, color: Color) -> void:
	var center := Vector3(0, 2.97, -3.005)
	var rim := rod(parent, center, 0.178, 0.182, 0.041, brass)
	rim.rotation.x = PI / 2.0
	var field := rod(parent, center + Vector3(0, 0, 0.026), 0.147, 0.147, 0.018, solid(color))
	field.rotation.x = PI / 2.0
	for i in 3:
		block(parent, center + Vector3((i - 1) * 0.047, -0.014, 0.039), Vector3(0.02, 0.087, 0.009), brass)
	block(parent, center + Vector3(0, -0.069, 0.039), Vector3(0.165, 0.014, 0.009), brass)
	for side in [-1.0, 1.0]:
		var roof := block(parent, center + Vector3(side * 0.042, 0.064, 0.039), Vector3(0.105, 0.016, 0.009), brass)
		roof.rotation.z = -side * 0.43

func build_banner(parent: Node3D, x: float, brass: Material, blue: bool) -> void:
	var cloth := surface_material(Color("#294954") if blue else Color("#7f3c45"), 0)
	block(parent, Vector3(x, 2.948, -2.975), Vector3(0.41, 0.46, 0.017), cloth)
	block(parent, Vector3(x, 3.194, -2.962), Vector3(0.51, 0.027, 0.031), brass)
	frame_molding(parent, Vector3(x, 2.948, -2.961), Vector2(0.35, 0.397), 0.009, brass)
	var emblem := block(parent, Vector3(x, 2.95, -2.944), Vector3(0.14, 0.14, 0.006), brass)
	emblem.rotation.z = PI / 4.0
	var field := block(parent, Vector3(x, 2.95, -2.939), Vector3(0.096, 0.096, 0.005), cloth)
	field.rotation.z = PI / 4.0

func surface_material(tint: Color, finish: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("finish", finish)
	return material

func solid(tint: Color, metallic := 0.0, roughness := 0.8, luminous := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = luminous
	if luminous:
		material.emission = tint
		material.emission_energy_multiplier = 0.7
	return material

func block(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return prop(parent, at, mesh, material)

func rod(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 40
	mesh.rings = 1
	return prop(parent, at, mesh, material)

func dome(parent: Node3D, at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height * 2.0
	mesh.is_hemisphere = true
	mesh.radial_segments = 48
	mesh.rings = 16
	return prop(parent, at, mesh, material)

func prop(parent: Node3D, at: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	object.mesh = mesh
	object.material_override = material
	parent.add_child(object)
	object.position = at
	return object

func light_at(at: Vector3, color: Color, energy: float, reach: float, shadows := false) -> void:
	var lamp := OmniLight3D.new()
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = reach
	lamp.shadow_enabled = shadows
	room.add_child(lamp)
	lamp.position = at


# Six career steps use the original four material sets, plus distinct furnishings.
func set_career_level(level: int) -> void:
	career_level=clampi(level,0,5)
	var style: int = [0,0,1,2,2,3][career_level]
	rank=-1
	set_rank(style)
	if career_level==0:
		wall_material.set_shader_parameter("tint",Color("#777d6d"))
		desk_material.set_shader_parameter("tint",Color("#76593f"))
		wall_material.set_shader_parameter("wallpaper",0)
	elif career_level==5:
		wall_material.set_shader_parameter("tint",Color("#64333c"))
	wall_clock=career_rooms[career_level].get_node("CareerClock")
	wall_clock.visible=true
	for i in career_doors.size():
		career_doors[i].visible=i==career_level
	for i in career_rooms.size():
		career_rooms[i].visible=i==career_level
	set_active("",true)
	refresh_room()

func build_career_contrast(wood: Material, brass: Material, dark: Material) -> void:
	var props = preload("res://game/friend_offices/career_props.gd").new(self)
	for level in 6:
		var root := Node3D.new()
		root.name="CareerDressing%d" % level
		root.visible=level==0
		room.add_child(root)
		career_rooms.append(root)
		props.build(root,level)
		if level==0: wall_clock=root.get_node("CareerClock")
		match level:
			0:
				framed_art(root,Vector3(1.64,1.96,-3.0),Vector2(0.62,0.47),wood,dark,2)
				for x in [-1.45,1.45]:
					modest_workplace(root,Vector3(x,0,-1.65),wood,dark)
					for i in 2:
						block(root,Vector3(x+0.5,0.17+i*0.31,-2.7),Vector3(0.42,0.3,0.36),surface_material(Color("#967b53"),0))
			1:
				framed_art(root,Vector3(1.65,2.09,-3.0),Vector2(0.65,0.52),wood,brass,3)
				modest_workplace(root,Vector3(-1.75,0,-1.9),wood,dark)
				drawer_chest(root,Vector3(1.45,0,-2.7),1.1,1.45,wood,brass)
			2:
				drawer_chest(root,Vector3(-1.45,0,-2.7),1.15,1.05,wood,brass)
				framed_art(root,Vector3(-1.45,1.98,-3.0),Vector2(1.0,0.7),wood,brass,4)
				drawer_chest(root,Vector3(1.45,0,-2.7),1.15,1.05,wood,brass)
				framed_art(root,Vector3(1.45,1.98,-3.0),Vector2(0.85,0.7),wood,brass,1)
			3:
				bookcase_career(root,Vector3(-1.6,0,-2.83),1.05,wood,brass)
				drawer_chest(root,Vector3(1.45,0,-2.7),1.15,0.8,wood,brass)
				framed_art(root,Vector3(1.45,1.8,-3.0),Vector2(1.04,1.1),wood,brass,5)
			4:
				for x in [-1.47,1.47]:
					drawer_chest(root,Vector3(x,0,-2.75),1.15,0.82,wood,brass)
					framed_art(root,Vector3(x,1.85,-3.0),Vector2(1.07,1.25),wood,brass,1 if x<0 else 6)
				for x in [-2.12,2.12]:
					block(root,Vector3(x,1.3,-2.98),Vector3(0.15,2.6,0.12),wood)
					for dx in [-0.04,0.04]:
						block(root,Vector3(x+dx,1.3,-2.9),Vector3(0.012,2.4,0.02),brass)
			5:
				for x in [-1.47,1.47]:
					drawer_chest(root,Vector3(x,0,-2.75),1.25,0.78,door_material,brass)
					framed_art(root,Vector3(x,1.88,-2.96),Vector2(1.12,1.32),door_material,brass,7 if x<0 else 1)
				for x in [-2.2,-0.78,0.78,2.2]:
					block(root,Vector3(x,1.34,-2.94),Vector3(0.085,2.64,0.12),brass)
					block(root,Vector3(x,1.34,-2.86),Vector3(0.042,2.49,0.035),door_inset_material)
				grand_chandelier(root,brass)
				for y in [2.66,3.27]:
					block(root,Vector3(0,y,-2.88),Vector3(4.5,0.025,0.045),brass)

func modest_workplace(parent: Node3D, at: Vector3, wood: Material, dark: Material) -> void:
	block(parent,at+Vector3(0,0.77,0),Vector3(1.12,0.075,0.74),wood)
	for x in [-0.45,0.45]:
		block(parent,at+Vector3(x,0.37,0),Vector3(0.065,0.74,0.62),dark)
	var paper_mat := solid(Color("#c7b58b"))
	for i in 3:
		block(parent,at+Vector3(-0.13,0.817+i*0.007,-0.03),Vector3(0.31,0.007,0.37),paper_mat)
	block(parent,at+Vector3(0.35,0.93,-0.20),Vector3(0.30,0.2,0.22),surface_material(Color("#85744e"),0))
	block(parent,at+Vector3(0,0.46,0.65),Vector3(0.49,0.06,0.45),wood)
	block(parent,at+Vector3(0,0.77,0.83),Vector3(0.49,0.47,0.055),wood)
	for x in [-0.19,0.19]:
		for z in [0.46,0.82]:
			block(parent,at+Vector3(x,0.22,z),Vector3(0.045,0.44,0.045),wood)

func drawer_chest(parent: Node3D, at: Vector3, width: float, height: float, wood: Material, brass: Material) -> void:
	block(parent,at+Vector3(0,height/2,0),Vector3(width,height,0.55),wood)
	block(parent,at+Vector3(0,height+0.015,0),Vector3(width+0.07,0.06,0.62),wood)
	for i in 3:
		var y := 0.09+(height-0.12)*(i+0.5)/3
		block(parent,at+Vector3(0,y,0.29),Vector3(width-0.075,(height-0.23)/3,0.045),door_inset_material)
		block(parent,at+Vector3(0,y,0.322),Vector3(width-0.13,(height-0.32)/3,0.025),wood)
		block(parent,at+Vector3(0,y,0.355),Vector3(0.16,0.022,0.032),brass)

func bookcase_career(parent: Node3D, at: Vector3, width: float, wood: Material, brass: Material) -> void:
	block(parent,at+Vector3(0,1.25,0),Vector3(width,2.5,0.2),door_inset_material)
	for side in [-1,1]:
		block(parent,at+Vector3(side*width/2,1.25,0.08),Vector3(0.09,2.5,0.38),wood)
	for row in 5:
		var y := 0.12+row*0.5
		block(parent,at+Vector3(0,y,0.09),Vector3(width+0.10,0.065,0.4),wood)
		for i in 5:
			var x := -width*0.37+i*width*0.18
			block(parent,at+Vector3(x,y+0.20,0.12),Vector3(width*0.13,0.32,0.23),solid(Color(["#5b6550","#875544","#ad9866"][i%3])))
			for dy in [-0.10,0.10]:
				block(parent,at+Vector3(x,y+0.20+dy,0.242),Vector3(width*0.12,0.008,0.009),brass)

func framed_art(parent: Node3D, at: Vector3, dimensions: Vector2, wood: Material, brass: Material, type: int) -> void:
	if type>=5:
		frame_molding(parent,at+Vector3(0,0,0.042),dimensions+Vector2(0.16,0.16),0.027,brass)
	block(parent,at,Vector3(dimensions.x+0.12,dimensions.y+0.12,0.085),wood)
	frame_molding(parent,at+Vector3(0,0,0.055),dimensions+Vector2(0.04,0.04),0.018,brass)
	block(parent,at+Vector3(0,0,0.052),Vector3(dimensions.x,dimensions.y,0.018),solid(Color("#c6b78e")))
	if type!=1:
		var quad := QuadMesh.new()
		quad.size=dimensions*0.88
		var mat := StandardMaterial3D.new()
		var image: Texture2D = load("res://game/offices/assets/views/american-%02d.png" % clampi(type-1,1,6))
		mat.albedo_texture=image
		mat.albedo_color=Color(0.72,0.68,0.60)
		var source_ratio := float(image.get_width())/image.get_height()
		var target_ratio := dimensions.x/dimensions.y
		if target_ratio<source_ratio:
			mat.uv1_scale.x=target_ratio/source_ratio
			mat.uv1_offset.x=(1-mat.uv1_scale.x)/2
		else:
			mat.uv1_scale.y=source_ratio/target_ratio
			mat.uv1_offset.y=(1-mat.uv1_scale.y)/2
		mat.roughness=1
		var art := MeshInstance3D.new()
		art.mesh=quad
		art.material_override=mat
		parent.add_child(art)
		art.position=at+Vector3(0,0,0.067)
	else:
		var title := Label3D.new()
		title.text="БЛАГОДАРНОСТЬ"
		title.font=SIGN_FONT
		title.font_size=36
		title.pixel_size=minf(0.0018,dimensions.x/320)
		title.outline_size=0
		title.modulate=Color("#66482f")
		title.position=at+Vector3(0,dimensions.y*0.34,0.075)
		parent.add_child(title)
		var gold := solid(Color("#9b7948"))
		for i in 7:
			block(parent,at+Vector3(0,dimensions.y*0.24-i*dimensions.y*0.064,0.068),Vector3(dimensions.x*(0.68 if i<6 else 0.40),0.006,0.006),gold)
		var seal := rod(parent,at+Vector3(0,-dimensions.y*0.32,0.075),0.075,0.075,0.012,brass)
		seal.rotation.x=PI/2

func grand_chandelier(parent: Node3D, brass: Material) -> void:
	var first := parent.get_child_count()
	var at := Vector3(0,3.32,0.0)
	rod(parent,at+Vector3(0,0.12,0),0.018,0.018,0.24,brass)
	var crystal := solid(Color("#ebd5a0"),0.08,0.35,true)
	for ring in 2:
		var radius := 0.23+ring*0.14
		for i in 8:
			var angle := TAU*i/8
			var p := at+Vector3(cos(angle)*radius,-ring*0.12,sin(angle)*radius)
			rod(parent,p,0.032,0.024,0.14,crystal)
			block(parent,(at+p)/2,Vector3(radius,0.014,0.018),brass).rotation.y=-angle

	for i in range(first,parent.get_child_count()):
		var detail: Node3D = parent.get_child(i)
		if detail is MeshInstance3D:
			detail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
