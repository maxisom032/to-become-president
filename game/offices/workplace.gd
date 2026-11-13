extends Control

const OfficeScene := preload("res://game/offices/office_scene.gd")
const Catalog := preload("res://game/offices/office_catalog.gd")
const Profile := preload("res://game/offices/profile.gd")
var office: Node3D
var profile = Profile.new()
var rank_index := 0
var active_panel := ""
var modal: Control
var sheet: VBoxContainer
var header_name: Label
var location_label: Label
var hint: Label
var rank_select: OptionButton
var party_select: OptionButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(414, 780)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.own_world_3d = true
	container.add_child(viewport)
	office = OfficeScene.new()
	viewport.add_child(office)
	build_interface()
	select_rank(0)

func surface(color: String, border: String = "#a5916e") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func text(parent: Node, value: String, font_size: int = 17, color: String = "#293d3e") -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(color))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func button(parent: Node, title: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = title
	item.custom_minimum_size.y = 44
	item.add_theme_font_size_override("font_size", 16)
	item.add_theme_color_override("font_color", Color("#f3e6c8"))
	item.add_theme_stylebox_override("normal", surface("#3d5f5b", "#6c8174"))
	item.add_theme_stylebox_override("hover", surface("#52766b"))
	item.add_theme_stylebox_override("pressed", surface("#294843"))
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

func build_interface() -> void:
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", surface("#f0e3c7"))
	add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 10
	top.offset_right = -10
	top.offset_top = 10
	var top_style := surface("#f0e3c7")
	top_style.content_margin_top = 6
	top_style.content_margin_bottom = 6
	top.add_theme_stylebox_override("panel", top_style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	top.add_child(column)
	header_name = text(column, profile.full_name, 18)
	location_label = text(column, "", 14, "#6c6757")
	location_label.hide()
	var row := HBoxContainer.new()
	column.add_child(row)
	rank_select = OptionButton.new()
	rank_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_select.custom_minimum_size.y = 38
	for spec in Catalog.ROOMS:
		rank_select.add_item(spec.rank)
	rank_select.item_selected.connect(select_rank)
	row.add_child(rank_select)
	var rename := button(row, "Новое имя", new_profile)
	rename.custom_minimum_size.y = 32
	party_select = OptionButton.new()
	party_select.custom_minimum_size.y = 30
	party_select.add_theme_font_size_override("font_size", 15)
	for party in Catalog.PARTIES:
		party_select.add_item(party)
	column.add_child(party_select)
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", surface("#243e3c", "#7e927e"))
	add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 10
	bottom.offset_right = -10
	bottom.offset_top = -78
	var bottom_column := VBoxContainer.new()
	bottom_column.add_theme_constant_override("separation", 4)
	bottom.add_child(bottom_column)
	hint = text(bottom_column, "Нажми на папку, телефон, ежедневник или дверь", 14, "#f0e2c2")
	var access := HBoxContainer.new()
	access.add_theme_constant_override("separation", 4)
	bottom_column.add_child(access)
	for entry in [["folder", "Папка"], ["phone", "Телефон"], ["agenda", "Люди"], ["door", "Дверь"]]:
		var item := button(access, entry[1], open_interaction.bind(entry[0]))
		item.custom_minimum_size.y = 30
		item.add_theme_font_size_override("font_size", 13)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal = Control.new()
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.08, 0.09, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	modal.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 185)
	margin.add_theme_constant_override("margin_bottom", 90)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", surface("#f1e6ce"))
	margin.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 330
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	sheet = VBoxContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_theme_constant_override("separation", 10)
	scroll.add_child(sheet)
	modal.hide()

func new_profile() -> void:
	profile = Profile.new()
	header_name.text = profile.full_name

func select_rank(index: int) -> void:
	rank_index = clampi(index, 0, 5)
	close_panel()
	office.build(rank_index)
	if rank_select != null:
		rank_select.select(rank_index)
		location_label.text = Catalog.ROOMS[rank_index].title + " • прототип 3D-кабинетов"

func _gui_input(event: InputEvent) -> void:
	if not active_panel.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var id: String = office.pick_object(event.position)
		if not id.is_empty():
			open_interaction(id)
	if event is InputEventScreenTouch and event.pressed:
		var id: String = office.pick_object(event.position)
		if not id.is_empty():
			open_interaction(id)
	if event is InputEventMouseMotion:
		var id: String = office.pick_object(event.position)
		var titles := {"folder": "Папка • поручение и биография", "phone": "Телефон • связаться с помощником", "agenda": "Ежедневник • доступные люди", "door": "Дверь • дела вне кабинета"}
		hint.text = titles.get(id, "Нажми на папку, телефон, ежедневник или дверь")
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not id.is_empty() else Control.CURSOR_ARROW

func clear_sheet(title: String) -> void:
	for child in sheet.get_children():
		sheet.remove_child(child)
		child.queue_free()
	text(sheet, title, 25)

func open_interaction(id: String) -> void:
	if id not in ["folder", "phone", "agenda", "door"]:
		return
	active_panel = id
	modal.show()
	match id:
		"folder":
			clear_sheet("Рабочая папка")
			text(sheet, "Поручения, биография и обязательства")
			button(sheet, "Текущее поручение", show_task)
			button(sheet, "Биография героя", show_biography)
			button(sheet, "Обязательства", show_obligations)
		"phone":
			clear_sheet(profile.companion.name)
			text(sheet, "«Освоился? Если нужна помощь — я на связи. Что у тебя?»" if rank_index < 2 else "«Давно не созванивались. Как ты там? Старое отделение тебя помнит.»")
			button(sheet, "Обсудить ближайшее поручение", show_task)
			button(sheet, "Спросить, как дела", companion_reply)
		"agenda":
			show_contacts()
		"door":
			office.animate_door(true)
			clear_sheet("Дела вне кабинета")
			text(sheet, "Куда направишься?")
			button(sheet, "Встреча с коллегами", show_contacts)
			button(sheet, "Выступление перед жителями", show_public_meeting)
			button(sheet, "Обсудить инициативу", show_initiative)
	if id != "agenda":
		button(sheet, "Вернуться к столу", close_panel)

func show_task() -> void:
	clear_sheet("Первое знакомство")
	text(sheet, "В отделении готовят встречу с жителями. Нужно решить, с чего начать: выслушать команду или сначала собрать вопросы людей.")
	button(sheet, "Поговорить с командой", task_result.bind("Коллеги объяснили, какие обещания уже даны. Теперь ты знаешь, о чём жители спросят в первую очередь."))
	button(sheet, "Собрать вопросы жителей", task_result.bind("Ты записал вопросы жителей. На встрече можно начать с того, что волнует их самих."))
	text(sheet, "Пробная сцена взаимодействия. Полная кампания и численные последствия ещё не подключены.", 13, "#786e59")
	button(sheet, "Вернуться к столу", close_panel)

func task_result(result: String) -> void:
	clear_sheet("Решение принято")
	text(sheet, result)
	button(sheet, "К столу", close_panel)

func show_biography() -> void:
	clear_sheet(profile.full_name)
	text(sheet, Catalog.ROOMS[rank_index].rank)
	text(sheet, "Партия: " + Catalog.PARTIES[party_select.selected])
	text(sheet, "Постоянный контакт: " + str(profile.companion.name))
	button(sheet, "К столу", close_panel)

func show_obligations() -> void:
	clear_sheet("Обязательства")
	text(sheet, "В этой демонстрации незакрытых обещаний пока нет.")
	button(sheet, "К столу", close_panel)

func companion_reply() -> void:
	clear_sheet(profile.companion.name)
	text(sheet, "«Работы хватает. Но хорошо, что ты спросил. Как-нибудь зайди без повестки — просто поговорить.»")
	button(sheet, "К столу", close_panel)

func show_contacts() -> void:
	clear_sheet("Люди рядом")
	for person in Catalog.ROOMS[rank_index].people:
		button(sheet, person, contact_scene.bind(person))
	button(sheet, "К столу", close_panel)

func contact_scene(person: String) -> void:
	clear_sheet(person)
	text(sheet, "«Прежде чем обещать результат, давай разберёмся, что мы можем сделать.»")
	button(sheet, "Обсудить встречу с жителями", show_task)
	button(sheet, "Вернуться к столу", close_panel)

func show_public_meeting() -> void:
	clear_sheet("Встреча с жителями")
	text(sheet, "В зале уже ждут. Тебе дают слово: с чего начнёшь разговор?")
	button(sheet, "Спросить о проблемах района", task_result.bind("Люди начали рассказывать о своих проблемах. Получился разговор, а не заученная речь."))
	button(sheet, "Представить план отделения", task_result.bind("Ты изложил план. Теперь жители хотят услышать, какие из обещаний будут выполнены первыми."))
	button(sheet, "К столу", close_panel)

func show_initiative() -> void:
	clear_sheet("Обсуждение инициативы")
	text(sheet, "Команда предлагает начать с районных встреч: сначала узнать запросы, затем выбирать содержание и бюджет проекта.")
	button(sheet, "Подготовить вопросы", show_task)
	button(sheet, "К столу", close_panel)

func close_panel() -> void:
	active_panel = ""
	if modal != null:
		modal.hide()
	if office != null and office.door_hinge != null and office.opened:
		office.animate_door(false)
