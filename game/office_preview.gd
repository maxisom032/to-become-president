extends Control

const OfficeRoom := preload("res://game/office_room.gd")
var office: Control

func _ready() -> void:
	office = OfficeRoom.new()
	add_child(office)
	office.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -82
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var title := Label.new()
	title.text = "ПРОСМОТР ОФОРМЛЕНИЯ • БЕЗ ГЕЙМПЛЕЯ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	stack.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(row)
	for index in 4:
		var button := Button.new()
		button.text = "Вариант %d" % (index + 1)
		button.custom_minimum_size = Vector2(96, 42)
		button.pressed.connect(office.set_style.bind(index))
		row.add_child(button)
