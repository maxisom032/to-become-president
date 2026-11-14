extends Control

var glyph: String
var ink: Color:
	set(value):
		ink = value
		queue_redraw()

func _init(symbol: String, tint: Color, extent := 20.0) -> void:
	glyph = symbol
	ink = tint
	custom_minimum_size = Vector2(extent, extent)
	size_flags_horizontal = SIZE_SHRINK_CENTER
	size_flags_vertical = SIZE_SHRINK_CENTER
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var scale_factor := minf(size.x, size.y) / 24.0
	var icon_size := Vector2.ONE * 24.0 * scale_factor
	draw_set_transform((size - icon_size) * 0.5, 0.0, Vector2.ONE * scale_factor)
	match glyph:
		"office":
			draw_arc(Vector2(9, 7), 3, 0, TAU, 24, ink, 1.8, true)
			stroke([Vector2(2, 21), Vector2(2, 17), Vector2(5, 14), Vector2(13, 14), Vector2(16, 17), Vector2(16, 21)])
			draw_arc(Vector2(17, 8), 2.5, -1.7, 1.7, 18, ink, 1.8, true)
			stroke([Vector2(18, 14), Vector2(21, 16), Vector2(22, 20)])
		"press":
			outline(Rect2(3, 4, 18, 16))
			draw_rect(Rect2(6, 7, 4, 4), ink)
			line(Vector2(13, 8), Vector2(18, 8))
			line(Vector2(13, 11), Vector2(18, 11))
			line(Vector2(6, 15), Vector2(18, 15))
			line(Vector2(6, 17), Vector2(16, 17))
		"stats":
			stroke([Vector2(2, 9), Vector2(12, 3), Vector2(22, 9), Vector2(2, 9)])
			for x in [5, 12, 19]:
				line(Vector2(x, 12), Vector2(x, 18))
			line(Vector2(3, 21), Vector2(21, 21))
		"paper":
			stroke([Vector2(3, 20), Vector2(3, 5), Vector2(10, 5), Vector2(13, 8), Vector2(21, 8), Vector2(21, 20), Vector2(3, 20)])
			line(Vector2(6, 12), Vector2(18, 12))
			line(Vector2(6, 15), Vector2(15, 15))
		"archive":
			outline(Rect2(3, 4, 18, 5))
			stroke([Vector2(5, 10), Vector2(5, 21), Vector2(19, 21), Vector2(19, 10)])
			line(Vector2(9, 13), Vector2(15, 13))
		"chart":
			stroke([Vector2(3, 3), Vector2(3, 21), Vector2(22, 21)])
			draw_rect(Rect2(7, 13, 3, 5), ink)
			draw_rect(Rect2(12, 9, 3, 9), ink)
			draw_rect(Rect2(17, 5, 3, 13), ink)
		"money":
			outline(Rect2(2, 6, 20, 12))
			draw_arc(Vector2(12, 12), 3, 0, TAU, 24, ink, 1.8, true)
			line(Vector2(4, 12), Vector2(6, 12))
			line(Vector2(18, 12), Vector2(20, 12))
		"banknote":
			draw_colored_polygon(PackedVector2Array([Vector2(1, 7), Vector2(21, 4), Vector2(24, 17), Vector2(4, 21)]), Color("#164b38"))
			draw_colored_polygon(PackedVector2Array([Vector2(2, 7), Vector2(21, 4), Vector2(23, 15), Vector2(4, 19)]), Color("#4bbd80"))
			draw_polyline(PackedVector2Array([Vector2(5, 9), Vector2(19, 6.5), Vector2(20.5, 13.5), Vector2(6, 16.5), Vector2(5, 9)]), Color("#ccf1a0"), 1.15, true)
			draw_circle(Vector2(12.5, 11.8), 3.0, Color("#1d6348"), true, -1, true)
			draw_circle(Vector2(12.5, 11.8), 1.45, Color("#e0f49a"), true, -1, true)
		"influence_seal":
			draw_circle(Vector2(12, 13), 10.2, Color("#70211f"), true, -1, true)
			draw_circle(Vector2(12, 11.8), 9.5, Color("#b74438"), true, -1, true)
			draw_arc(Vector2(12, 11.8), 7.7, 0, TAU, 32, Color("#ffb788"), 1.05, true)
			var gold := Color("#fff0c5")
			draw_rect(Rect2(7.3, 12.4, 2.2, 3.7), gold)
			draw_rect(Rect2(10.9, 10.5, 2.2, 5.6), gold)
			draw_rect(Rect2(14.5, 7.8, 2.2, 8.3), gold)
		"phone":
			draw_polyline(PackedVector2Array([Vector2(5, 4), Vector2(5, 9), Vector2(8, 14), Vector2(12, 18), Vector2(17, 20), Vector2(20, 19)]), ink, 3.0, true)
			draw_line(Vector2(5, 4), Vector2(8, 7), ink, 4, true)
			draw_line(Vector2(17, 16), Vector2(20, 19), ink, 4, true)
		"bell":
			stroke([Vector2(5, 17), Vector2(7, 14), Vector2(7, 9), Vector2(9, 5), Vector2(15, 5), Vector2(17, 9), Vector2(17, 14), Vector2(19, 17), Vector2(5, 17)])
			draw_arc(Vector2(12, 18), 2.5, 0, PI, 12, ink, 1.5, true)
		"goal":
			draw_arc(Vector2(12, 12), 9, 0, TAU, 32, ink, 1.8, true)
			draw_arc(Vector2(12, 12), 5, 0, TAU, 24, ink, 1.8, true)
			draw_circle(Vector2(12, 12), 1.7, ink, true, -1, true)
		"clock":
			draw_arc(Vector2(12, 12), 9, 0, TAU, 32, ink, 1.8, true)
			stroke([Vector2(12, 6), Vector2(12, 12), Vector2(16, 14)])
		"risk":
			stroke([Vector2(12, 3), Vector2(22, 20), Vector2(2, 20), Vector2(12, 3)])
			line(Vector2(12, 9), Vector2(12, 13))
			draw_circle(Vector2(12, 16), 1, ink, true, -1, true)
		"check":
			stroke([Vector2(4, 12), Vector2(10, 18), Vector2(20, 6)], 2.5)
		"up":
			stroke([Vector2(4, 17), Vector2(9, 12), Vector2(13, 15), Vector2(20, 7)])
			stroke([Vector2(14, 7), Vector2(20, 7), Vector2(20, 13)])
		"star":
			draw_star(Vector2(12, 12), 10, ink)
		"next":
			stroke([Vector2(9, 5), Vector2(16, 12), Vector2(9, 19)], 2.4)
		"back":
			stroke([Vector2(15, 5), Vector2(8, 12), Vector2(15, 19)], 2.4)
		"menu":
			for y in [6, 12, 18]:
				line(Vector2(4, y), Vector2(20, y))
		"settings":
			var center := Vector2(12, 12)
			draw_arc(center, 6.2, 0, TAU, 32, ink, 2.0, true)
			draw_arc(center, 2.1, 0, TAU, 18, ink, 1.6, true)
			for tooth in 8:
				var direction := Vector2.from_angle(tooth * TAU / 8.0)
				draw_line(center + direction * 6.1, center + direction * 9.1, ink, 2.5, true)

func line(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, ink, 1.8, true)

func draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var angle := -PI / 2.0 + index * TAU / 10.0
		var distance := radius if index % 2 == 0 else radius * 0.46
		points.append(center + Vector2.from_angle(angle) * distance)
	draw_colored_polygon(points, color)

func outline(rect: Rect2) -> void:
	draw_rect(rect, ink, false, 1.8, true)

func stroke(points: PackedVector2Array, width := 1.8) -> void:
	draw_polyline(points, ink, width, true)
