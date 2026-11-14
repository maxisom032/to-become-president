extends Control

const Stage := preload("res://game/friend_offices/office_stage.gd")
const NAMES := ["Референт","Легат","Префект","Консул","Архонт","Первый архонт"]
var stage: Control
var selector: OptionButton
var hint: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var theme_value := Theme.new()
	theme_value.default_font=preload("res://game/art/fonts/PTSerif-Regular.ttf")
	theme_value.default_font_size=16
	for state in ["normal","hover","pressed","focus"]:
		var button_style := panel_style()
		button_style.bg_color=Color("#873e30" if state=="normal" else "#a15b3f")
		theme_value.set_stylebox(state,"Button",button_style)
		theme_value.set_color("font_color","Button",Color("#f1deaa"))
		var selector_style := panel_style()
		selector_style.bg_color=Color("#dfc58f")
		theme_value.set_stylebox(state,"OptionButton",selector_style)
		theme_value.set_color("font_color","OptionButton",Color("#4b3423"))
	theme=theme_value
	stage=Stage.new()
	add_child(stage)
	stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var header := PanelContainer.new()
	add_child(header)
	header.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	header.offset_left=9
	header.offset_top=8
	header.offset_right=-9
	header.add_theme_stylebox_override("panel",panel_style())
	var column := VBoxContainer.new()
	header.add_child(column)
	var title := Label.new()
	title.text="Кабинеты · новая визуальная основа"
	title.add_theme_color_override("font_color",Color("#4b3423"))
	title.add_theme_font_size_override("font_size",15)
	column.add_child(title)
	selector=OptionButton.new()
	for title_value in NAMES:
		selector.add_item(title_value)
	selector.custom_minimum_size.y=31
	selector.item_selected.connect(select_rank)
	column.add_child(selector)
	var footer := PanelContainer.new()
	add_child(footer)
	footer.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	footer.offset_left=9
	footer.offset_right=-9
	footer.offset_top=-74
	footer.offset_bottom=-8
	footer.add_theme_stylebox_override("panel",panel_style())
	var foot := VBoxContainer.new()
	footer.add_child(foot)
	hint=Label.new()
	hint.text="Папка и дверь открываются нажатием"
	hint.add_theme_font_size_override("font_size",14)
	hint.add_theme_color_override("font_color",Color("#4b3423"))
	foot.add_child(hint)
	var row := HBoxContainer.new()
	foot.add_child(row)
	for item in [["Папка","paper"],["К столу",""],["Дверь","press"]]:
		var button := Button.new()
		button.text=item[0]
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		button.custom_minimum_size.y=32
		button.pressed.connect(open_item.bind(item[1]))
		row.add_child(button)
	stage.interacted.connect(open_item)
	select_rank(0)

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=Color("#e8d4a9")
	style.border_color=Color("#977342")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left=9
	style.content_margin_right=9
	style.content_margin_top=5
	style.content_margin_bottom=5
	return style

func select_rank(index: int) -> void:
	selector.select(index)
	stage.set_pose("","")
	stage.set_career_level(index)

func open_item(id: String) -> void:
	stage.set_pose(id,"")
	hint.text="Открыто дело" if id=="paper" else ("Выход из кабинета" if id=="press" else "Папка и дверь открываются нажатием")
