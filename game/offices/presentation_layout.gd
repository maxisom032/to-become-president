extends RefCounted

# UI density is independent of the full-resolution 3D viewport.
static func apply(ui: Control) -> void:
	if ui.hud_layer == null:
		return
	var density := clampf(minf(ui.size.x / 480.0, ui.size.y / 800.0), 1.0, 2.5)
	ui.hud_layer.scale = Vector2.ONE * density
	ui.hud_layer.size = ui.size / density
	for selector in [ui.rank_select,ui.party_select]:
		selector.get_popup().content_scale_factor = density
	var area: Vector2 = ui.hud_layer.size
	var wide := area.x >= 850.0 and area.x > area.y
	var edge := 20.0 if wide else 12.0
	ui.scene_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not wide and ui.active_panel != "folder":
		ui.scene_container.offset_top = 166.0*density
		ui.scene_container.offset_bottom = -112.0*density
	ui.hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui.hud.position = Vector2(edge, edge)
	ui.hud.size = Vector2(354.0 if wide else area.x - edge * 2.0, 0)
	ui.footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	var foot_width := 580.0 if wide else area.x - edge * 2.0
	ui.footer.position = Vector2((area.x-foot_width)/2.0, area.y-92.0-edge)
	ui.footer.size = Vector2(foot_width,92.0)
	ui.screen_button.visible = wide
	ui.screen_button.position = Vector2(area.x-166.0-edge,edge)
	ui.screen_button.size = Vector2(166.0,42.0)
	var folder: bool = ui.active_panel == "folder"
	var panel_width := minf(432.0,area.x-edge*2.0)
	var left: int = int(area.x-panel_width-edge) if wide else int(edge)
	var right: int = int(edge)
	var top: int = int(maxf(edge,area.y*0.40)) if folder and not wide else int(edge+60.0 if wide else edge+140.0)
	var bottom: int = int(edge if folder or wide else edge+60.0)
	if area.y-float(top+bottom) < 290.0:
		top = int(edge+30.0)
		bottom = int(edge)
	ui.modal_margin.add_theme_constant_override("margin_left",left)
	ui.modal_margin.add_theme_constant_override("margin_right",right)
	ui.modal_margin.add_theme_constant_override("margin_top",top)
	ui.modal_margin.add_theme_constant_override("margin_bottom",bottom)
	ui.modal_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ui.reader_scroll.custom_minimum_size.y = minf(350.0 if wide else 270.0,maxf(150.0,area.y-top-bottom-90.0))
	ui.reader_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not ui.office.folder_focused and (ui.office.focus_motion == null or not ui.office.focus_motion.is_running()):
		ui.office.camera.fov=ui.office.desk_fov()
