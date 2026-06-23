class_name GameUI
extends Control

const AnimatedAssetRectScript := preload("res://scripts/ui/animated_asset_rect.gd")

signal continue_requested
signal blessing_selected(id: String)
signal menu_requested

var start_button: Button
var status_row: HBoxContainer
var core_status: Control
var core_value: Label
var power_status: Control
var power_value: Label

var deity_popup: PanelContainer
var deity_content_margin: MarginContainer
var deity_content: VBoxContainer
var popup_position := Vector2i(-1, -1)
var popup_title: Label
var attack_preview: Label
var resource_preview: Label
var attack_choice_button: Button
var resource_choice_button: Button
var deity_button_row: HBoxContainer
var deity_separator: HSeparator
var upgrade_button: Button
var upgrade_button_center: CenterContainer
var migrate_button: Button
var remove_button: Button
var large_skill_button: Button
var upgrade_cost_label: Label
var remove_cost_label: Label
var upgrade_preview: Label
var popup_interactive: bool = false
var card_hover_popup: PanelContainer
var card_hover_title: Label
var card_hover_body: Label
var debug_panel: PanelContainer
var debug_label: Label
var result_overlay: PanelContainer
var result_modal_blocker: ColorRect
var core_info_popup: PanelContainer
var core_info_label: Label
var tutorial_panel: PanelContainer
var tutorial_label: Label
var tutorial_hide_serial: int = 0
var tutorial_continue_button: Button
var tutorial_highlight: PanelContainer
var tutorial_previous_pause: bool = false
var tutorial_previous_time_scale: float = 1.0
var tutorial_active_pause: bool = false
var tutorial_highlight_tween: Tween
var menu_button: Button
var main_menu_button: Button
var quit_desktop_button: Button
var cheat_panel: PanelContainer
var deity_stat_row: HBoxContainer
var settings_panel: PanelContainer
var tactical_panel: Control
var tactical_title: Label
var tactical_label: Label
var tactical_stat_row: HBoxContainer


func _ready() -> void:
	theme = AssetCatalog.interface_theme()
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_edge_hud()
	_create_deity_popup()
	_create_core_info_popup()
	_create_card_hover_popup()
	_create_debug_panel()
	_create_tutorial_panel()
	_create_cheat_panel()
	_create_settings_panel()
	_create_tactical_panel()

	TurnManager.phase_changed.connect(_on_state_changed)
	TurnManager.combat_time_changed.connect(_on_combat_time_changed)
	GameManager.state_changed.connect(_on_state_changed)
	ResourceManager.resources_changed.connect(_on_state_changed)
	CardManager.shop_changed.connect(_on_state_changed)
	TutorialManager.tutorial_requested.connect(show_tutorial_step)
	TutorialManager.tutorial_cleared.connect(hide_tutorial)
	GameManager.game_started.connect(_connect_map)
	var hand := get_node_or_null("../HandUI") as HandUI
	if hand:
		hand.shop_card_hovered.connect(_show_shop_card_info)
		hand.shop_card_unhovered.connect(_hide_shop_card_info)
	_connect_map()
	_refresh_view()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and event.keycode == KEY_ESCAPE and settings_panel and settings_panel.visible:
		_toggle_settings()
		get_viewport().set_input_as_handled()
		return
	if event.pressed and event.keycode == KEY_F3:
		debug_panel.visible = not debug_panel.visible
		_refresh_debug_panel()
	if event.pressed and event.keycode == KEY_F4:
		cheat_panel.visible = not cheat_panel.visible
		if cheat_panel.visible:
			cheat_panel.move_to_front()


func _build_edge_hud() -> void:
	status_row = HBoxContainer.new()
	status_row.position = Vector2(4, 48)
	status_row.size = Vector2(304, 60)
	status_row.add_theme_constant_override("separation", 4)
	add_child(status_row)
	core_status = _make_icon_status(
		status_row,
		"icon_core_hp",
		"核心生命\n敌人抵达核心时会造成伤害。\n生命降到 0 时本局失败。"
	)
	core_value = core_status.get_node("Row/Value") as Label
	power_status = _make_icon_status(
		status_row,
		"icon_divine_power",
		"神力\n用于购买地块和安置神祇。\n资源神祇会持续生产神力；河流邻域可降低资源神祇的实际安置费用。"
	)
	power_value = power_status.get_node("Row/Value") as Label
	status_row.move_child(core_status, status_row.get_child_count() - 1)

	start_button = _make_button("时间流动", self, _start_combat)
	start_button.position = Vector2(1578, 410)
	start_button.size = Vector2(180, 180)
	start_button.custom_minimum_size = Vector2(180, 180)
	start_button.set_meta("persistent_icon_outline", true)
	start_button.tooltip_text = "时间流动：进入自动战斗阶段"
	AssetCatalog.apply_button_visual(start_button, "icon_time_flow", true)
	start_button.pivot_offset = start_button.size * 0.5
	var flow_tween := create_tween().set_loops()
	flow_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flow_tween.tween_interval(1.15)
	flow_tween.tween_property(start_button, "scale", Vector2(1.055, 1.055), 0.13)
	flow_tween.tween_property(start_button, "scale", Vector2.ONE, 0.17)
	flow_tween.tween_interval(0.08)
	flow_tween.tween_property(start_button, "scale", Vector2(1.035, 1.035), 0.1)
	flow_tween.tween_property(start_button, "scale", Vector2.ONE, 0.16)
	menu_button = _make_button("设置", self, _toggle_settings)
	menu_button.position = Vector2(1410, 24)
	menu_button.size = Vector2(72, 72)
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_button.tooltip_text = "设置"
	AssetCatalog.apply_button_visual(
		menu_button,
		"button_settings" if AssetCatalog.texture("button_settings") else "icon_settings",
		true
	)
	main_menu_button = _make_button("返回主菜单", self, _top_right_secondary_action)
	main_menu_button.position = Vector2(1410, 104)
	main_menu_button.size = Vector2(72, 72)
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.tooltip_text = "返回主菜单"
	AssetCatalog.apply_button_visual(
		main_menu_button,
		"button_main_menu" if AssetCatalog.texture("button_main_menu") else "icon_menu",
		true
	)
	quit_desktop_button = _make_button("退出到桌面", self, _quit_to_desktop)
	quit_desktop_button.position = Vector2(1804, 20)
	quit_desktop_button.size = Vector2(96, 96)
	quit_desktop_button.custom_minimum_size = Vector2(96, 96)
	quit_desktop_button.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_desktop_button.z_index = 170
	quit_desktop_button.tooltip_text = "退出到桌面"
	AssetCatalog.apply_button_visual(
		quit_desktop_button,
		"button_quit" if AssetCatalog.texture("button_quit") else "icon_menu",
		true
	)


func _make_icon_status(parent: Control, icon_key: String, explanation: String) -> Control:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(150, 56)
	panel.tooltip_text = explanation
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var icon := AnimatedAssetRectScript.new()
	icon.custom_minimum_size = Vector2(46, 46)
	icon.configure(icon_key)
	icon.pivot_offset = Vector2(23, 23)
	row.add_child(icon)
	var value := Label.new()
	value.name = "Value"
	value.add_theme_font_size_override("font_size", 21)
	value.custom_minimum_size = Vector2(72, 38)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.035, 0.055, 0.08, 0.62)
	pill.set_corner_radius_all(19)
	pill.content_margin_left = 12.0
	pill.content_margin_right = 12.0
	value.add_theme_stylebox_override("normal", pill)
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value)
	return panel


func _connect_map() -> void:
	var map := _get_map()
	if map and not map.terrain_selected.is_connected(_show_terrain_deities):
		map.terrain_selected.connect(_show_terrain_deities)
		map.deity_selected.connect(_show_selected_deity)
		map.terrain_hovered.connect(_show_hovered_cell)
		map.enemy_hovered.connect(_show_enemy_info)
		map.enemy_selected.connect(_show_selected_enemy_info)
		map.core_hovered.connect(_show_core_info)
		map.core_selected.connect(_show_selected_core_info)
		map.map_hover_exited.connect(_hide_terrain_popup)
		map.selection_cleared.connect(_clear_selection_popup)


func _get_map() -> GameMap:
	var candidate: Variant = GameManager.grid_map_ref
	if not is_instance_valid(candidate):
		return null
	return candidate as GameMap


func _make_button(text: String, parent: Node, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _make_power_cost_row(value_label: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.texture = AssetCatalog.texture("icon_divine_power")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	row.add_child(value_label)
	return row


func _apply_dark_info_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.06, 0.91)
	style.border_color = Color(0.43, 0.27, 0.17, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)


func _start_combat() -> void:
	AudioManager.play_sfx_first(["button_time_flow", "refresh"], -2.0)
	if GameManager.scene_root:
		GameManager.scene_root.start_combat()


func _create_deity_popup() -> void:
	deity_popup = PanelContainer.new()
	deity_popup.visible = false
	deity_popup.z_index = 100
	deity_popup.custom_minimum_size = Vector2(350, 260)
	deity_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AssetCatalog.apply_panel_background(deity_popup, "stats_background")
	add_child(deity_popup)
	deity_content_margin = MarginContainer.new()
	deity_popup.add_child(deity_content_margin)
	deity_content = VBoxContainer.new()
	deity_content.add_theme_constant_override("separation", 7)
	deity_content_margin.add_child(deity_content)

	popup_title = Label.new()
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_title.custom_minimum_size = Vector2(250, 30)
	popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_title.add_theme_font_size_override("font_size", 18)
	popup_title.add_theme_color_override("font_color", Color("4b2d1a"))
	deity_content.add_child(popup_title)
	deity_button_row = HBoxContainer.new()
	deity_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	deity_button_row.add_theme_constant_override("separation", 12)
	deity_content.add_child(deity_button_row)
	attack_choice_button = _make_button("安置攻击神祇", deity_button_row, _purchase_attack_deity)
	attack_choice_button.custom_minimum_size = Vector2(88, 88)
	attack_preview = Label.new()
	attack_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	attack_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	attack_preview.custom_minimum_size = Vector2(250, 34)
	attack_preview.add_theme_color_override("font_color", Color("4b2d1a"))
	deity_content.add_child(attack_preview)
	deity_separator = HSeparator.new()
	deity_content.add_child(deity_separator)
	resource_choice_button = _make_button("安置资源神祇", deity_button_row, _purchase_resource_deity)
	resource_choice_button.custom_minimum_size = Vector2(88, 88)
	resource_preview = Label.new()
	resource_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_preview.add_theme_color_override("font_color", Color("4b2d1a"))
	deity_content.add_child(resource_preview)
	upgrade_preview = Label.new()
	upgrade_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	upgrade_preview.custom_minimum_size = Vector2(250, 76)
	upgrade_preview.add_theme_font_size_override("font_size", 14)
	upgrade_preview.add_theme_color_override("font_color", Color("4b2d1a"))
	upgrade_preview.visible = false
	deity_content.add_child(upgrade_preview)
	upgrade_button_center = CenterContainer.new()
	upgrade_button_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button_center.visible = false
	deity_content.add_child(upgrade_button_center)
	var deity_action_row := HBoxContainer.new()
	deity_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	deity_action_row.add_theme_constant_override("separation", 22)
	upgrade_button_center.add_child(deity_action_row)
	var upgrade_action := VBoxContainer.new()
	upgrade_action.alignment = BoxContainer.ALIGNMENT_CENTER
	deity_action_row.add_child(upgrade_action)
	upgrade_button = _make_button("升级", upgrade_action, _upgrade_selected_deity)
	upgrade_button.visible = false
	upgrade_button.custom_minimum_size = Vector2(86, 86)
	upgrade_button.set_meta("persistent_icon_outline", true)
	AssetCatalog.apply_button_visual(upgrade_button, "action_upgrade", true, true)
	upgrade_cost_label = Label.new()
	upgrade_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_cost_label.add_theme_font_size_override("font_size", 13)
	upgrade_cost_label.add_theme_color_override("font_color", Color("f2dfbf"))
	upgrade_action.add_child(_make_power_cost_row(upgrade_cost_label))
	var remove_action := VBoxContainer.new()
	remove_action.alignment = BoxContainer.ALIGNMENT_CENTER
	deity_action_row.add_child(remove_action)
	remove_button = _make_button("移除", remove_action, _remove_selected_deity)
	remove_button.visible = false
	remove_button.custom_minimum_size = Vector2(86, 86)
	remove_button.set_meta("persistent_icon_outline", true)
	AssetCatalog.apply_button_visual(remove_button, "action_remove", true, true)
	remove_cost_label = Label.new()
	remove_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remove_cost_label.add_theme_font_size_override("font_size", 13)
	remove_cost_label.add_theme_color_override("font_color", Color("f2dfbf"))
	remove_action.add_child(_make_power_cost_row(remove_cost_label))
	var large_action := VBoxContainer.new()
	large_action.alignment = BoxContainer.ALIGNMENT_CENTER
	deity_action_row.add_child(large_action)
	large_skill_button = _make_button("神域技能", large_action, _activate_selected_large_skill)
	large_skill_button.visible = false
	large_skill_button.custom_minimum_size = Vector2(86, 86)
	AssetCatalog.apply_button_visual(large_skill_button, "icon_attack", true, true)
	# 迁移入口只保留在右侧操作区；这里保留隐藏引用，兼容旧状态清理代码。
	migrate_button = Button.new()
	migrate_button.visible = false
	deity_stat_row = HBoxContainer.new()
	deity_stat_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	deity_stat_row.add_theme_constant_override("separation", 4)
	deity_content.add_child(deity_stat_row)
	deity_content.move_child(deity_stat_row, upgrade_preview.get_index())
	_set_deity_popup_paper_mode()


func _set_deity_popup_paper_mode() -> void:
	_apply_dark_info_panel(deity_popup)
	deity_content_margin.add_theme_constant_override("margin_left", 48)
	deity_content_margin.add_theme_constant_override("margin_right", 20)
	deity_content_margin.add_theme_constant_override("margin_top", 18)
	deity_content_margin.add_theme_constant_override("margin_bottom", 16)
	deity_content.alignment = BoxContainer.ALIGNMENT_BEGIN
	deity_stat_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_title.visible = true
	popup_title.add_theme_color_override("font_color", Color("f3dfb7"))
	attack_preview.add_theme_color_override("font_color", Color("e8d7bd"))
	resource_preview.add_theme_color_override("font_color", Color("e8d7bd"))
	upgrade_preview.add_theme_color_override("font_color", Color("e8d7bd"))


func _set_deity_popup_placement_mode() -> void:
	var dark := StyleBoxFlat.new()
	dark.bg_color = Color(0.035, 0.05, 0.075, 0.86)
	dark.border_color = Color(0.63, 0.75, 0.86, 0.48)
	dark.set_border_width_all(1)
	dark.set_corner_radius_all(12)
	dark.content_margin_left = 12
	dark.content_margin_right = 12
	dark.content_margin_top = 10
	dark.content_margin_bottom = 10
	deity_popup.add_theme_stylebox_override("panel", dark)
	deity_content_margin.add_theme_constant_override("margin_left", 8)
	deity_content_margin.add_theme_constant_override("margin_right", 8)
	deity_content_margin.add_theme_constant_override("margin_top", 6)
	deity_content_margin.add_theme_constant_override("margin_bottom", 6)
	popup_title.visible = false


func _create_card_hover_popup() -> void:
	card_hover_popup = PanelContainer.new()
	card_hover_popup.visible = false
	card_hover_popup.z_index = 110
	card_hover_popup.custom_minimum_size = Vector2(190, 58)
	card_hover_popup.size = Vector2(190, 58)
	card_hover_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AssetCatalog.apply_panel_background(card_hover_popup, "stats_background")
	add_child(card_hover_popup)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 7)
	card_hover_popup.add_child(content)
	card_hover_title = Label.new()
	card_hover_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_hover_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_hover_title.custom_minimum_size = Vector2(150, 32)
	card_hover_title.add_theme_font_size_override("font_size", 16)
	card_hover_title.add_theme_color_override("font_color", Color("4b2d1a"))
	content.add_child(card_hover_title)
	card_hover_body = Label.new()
	card_hover_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_hover_body.add_theme_color_override("font_color", Color("4b2d1a"))
	content.add_child(card_hover_body)


func _create_core_info_popup() -> void:
	core_info_popup = PanelContainer.new()
	core_info_popup.visible = false
	core_info_popup.z_index = 105
	core_info_popup.custom_minimum_size = Vector2(120, 48)
	core_info_popup.size = Vector2(120, 48)
	core_info_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_dark_info_panel(core_info_popup)
	add_child(core_info_popup)
	var core_margin := MarginContainer.new()
	core_margin.add_theme_constant_override("margin_left", 0)
	core_margin.add_theme_constant_override("margin_right", 0)
	core_margin.add_theme_constant_override("margin_top", 0)
	core_margin.add_theme_constant_override("margin_bottom", 0)
	core_info_popup.add_child(core_margin)
	core_info_label = Label.new()
	core_info_label.custom_minimum_size = Vector2(100, 28)
	core_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	core_info_label.add_theme_font_size_override("font_size", 15)
	core_info_label.add_theme_color_override("font_color", Color("eadbc4"))
	core_margin.add_child(core_info_label)


func _show_shop_card_info(card: CardBase, global_rect: Rect2) -> void:
	card_hover_popup.visible = false
	card_hover_title.text = card.card_name
	card_hover_body.text = ""
	card_hover_body.visible = false
	card_hover_popup.position = Vector2(
		clampf(
			global_rect.get_center().x - card_hover_popup.custom_minimum_size.x * 0.5,
			8.0,
			get_viewport_rect().size.x - card_hover_popup.custom_minimum_size.x - 8.0
		),
		clampf(
			global_rect.position.y - card_hover_popup.custom_minimum_size.y - 6.0,
			4.0,
			get_viewport_rect().size.y - card_hover_popup.custom_minimum_size.y - 8.0
		)
	)
	card_hover_popup.visible = true


func _hide_shop_card_info() -> void:
	card_hover_popup.visible = false


func _hide_terrain_popup() -> void:
	core_info_popup.visible = false
	if deity_popup.visible and not popup_interactive:
		deity_popup.visible = false


func _clear_selection_popup() -> void:
	core_info_popup.visible = false
	popup_interactive = false
	popup_position = Vector2i(-1, -1)
	deity_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deity_popup.visible = false


func _show_deity(pos: Vector2i, reveal: bool = true) -> void:
	_set_deity_popup_paper_mode()
	core_info_popup.visible = false
	if popup_interactive:
		return
	var map := _get_map()
	if not map:
		return
	popup_position = pos
	popup_title.text = map.deity_form_name(pos, (map.get_cell(pos).deity as DeityInstance).deity_type)
	attack_preview.text = ""
	deity_stat_row.visible = false
	# Keep the panel concise: only function and final attributes are shown.
	resource_preview.text = ""
	attack_choice_button.visible = false
	resource_choice_button.visible = false
	deity_button_row.visible = false
	attack_preview.visible = false
	resource_preview.visible = false
	deity_separator.visible = false
	upgrade_preview.visible = false
	upgrade_button.visible = false
	remove_button.visible = false
	large_skill_button.visible = false
	migrate_button.visible = false
	upgrade_button_center.visible = false
	migrate_button.visible = false
	popup_interactive = false
	deity_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deity_popup.custom_minimum_size = Vector2(220, 64)
	deity_popup.reset_size()
	_position_popup(pos)
	if reveal:
		_reveal_deity_popup()
	return
	attack_preview.text = (
		"神域规模：%d 格\n仅计算上下左右连通的同类地形；同一神域最多一座神祇。\n\n%s"
		% [map.terrain_region(pos).size(), map.selected_deity_description(pos)]
	)
	resource_preview.text = ""
	attack_choice_button.visible = false
	resource_choice_button.visible = false
	deity_button_row.visible = false
	attack_preview.visible = true
	resource_preview.visible = false
	deity_separator.visible = false
	upgrade_preview.visible = false
	upgrade_button.visible = false
	remove_button.visible = false
	large_skill_button.visible = false
	migrate_button.visible = false
	popup_interactive = false
	deity_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deity_popup.custom_minimum_size = Vector2(460, 390)
	deity_popup.reset_size()
	_position_popup(pos)
	deity_popup.visible = true


func _show_selected_deity(pos: Vector2i) -> void:
	popup_interactive = false
	_show_deity(pos, false)
	var map := _get_map()
	var deity := map.get_cell(pos).deity as DeityInstance if map else null
	if not map or not deity:
		return
	_update_tactical_deity(pos)
	if ProgressManager.current_map == 0:
		deity_popup.visible = false
		popup_interactive = false
		return
	_set_deity_popup_placement_mode()
	upgrade_button_center.visible = true
	popup_interactive = true
	deity_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_title.visible = false
	attack_preview.visible = false
	resource_preview.visible = false
	deity_stat_row.visible = false
	upgrade_preview.visible = false
	deity_button_row.visible = false
	deity_separator.visible = false
	var can_operate := TurnManager.current_phase == TurnManager.Phase.BUILD
	var upgrade_cost := map.deity_upgrade_cost(deity.level)
	upgrade_button.visible = can_operate
	upgrade_button.disabled = deity.level >= 3 or not ResourceManager.can_afford(upgrade_cost)
	upgrade_button.tooltip_text = (
		"已达到最高等级"
		if deity.level >= 3
		else "升级到 %d 级" % (deity.level + 1)
	)
	upgrade_cost_label.text = "已满级" if deity.level >= 3 else "%.1f" % upgrade_cost
	remove_button.visible = can_operate
	var removal_cost := map.deity_removal_cost()
	remove_button.disabled = not ResourceManager.can_afford(removal_cost)
	remove_button.tooltip_text = "移除该神祇"
	remove_cost_label.text = "%.1f" % removal_cost
	var large_ready := (
		map.terrain_region(pos).size() >= int(GameDefinitions.BALANCE.large_domain_threshold)
	)
	var in_combat := TurnManager.current_phase == TurnManager.Phase.COMBAT
	upgrade_button.visible = can_operate and ProgressManager.current_map != 0
	remove_button.visible = can_operate and ProgressManager.current_map != 0
	large_skill_button.visible = in_combat and large_ready and ProgressManager.current_map != 0
	large_skill_button.disabled = not map.can_activate_large_domain_skill(pos)
	large_skill_button.tooltip_text = (
		"%s：本战斗阶段可发动一次" % map.large_domain_skill_name(pos)
		if large_ready
		else "神域达到%d格后解锁" % int(GameDefinitions.BALANCE.large_domain_threshold)
	)
	migrate_button.visible = false
	if in_combat and not large_ready:
		deity_popup.visible = false
		popup_interactive = false
		return
	deity_popup.custom_minimum_size = (
		Vector2(140, 132)
		if in_combat
		else Vector2(230, 132)
	)
	deity_popup.reset_size()
	_position_popup(pos)
	_reveal_deity_popup()
	if (
		ProgressManager.current_map != 0
		and can_operate
		and deity.level < 3
		and ResourceManager.can_afford(upgrade_cost)
	):
		var tutorial_delay := create_tween()
		tutorial_delay.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tutorial_delay.tween_interval(0.24)
		tutorial_delay.tween_callback(_trigger_deity_operation_tutorial.bind(pos))


func _trigger_deity_operation_tutorial(pos: Vector2i) -> void:
	if deity_popup.visible and popup_position == pos:
		TutorialManager.trigger("deity_operation_opened", {"pos": pos})


func _activate_selected_large_skill() -> void:
	var map := _get_map()
	if not map or popup_position == Vector2i(-1, -1):
		return
	if map.activate_large_domain_skill(popup_position):
		_show_selected_deity(popup_position)


func _migrate_selected_deity() -> void:
	var map := _get_map()
	if not map or popup_position == Vector2i(-1, -1):
		return
	if map.begin_deity_migration(popup_position):
		deity_popup.visible = false
		popup_interactive = false


func _reveal_deity_popup() -> void:
	deity_popup.visible = true
	deity_popup.pivot_offset = deity_popup.size * 0.5
	deity_popup.scale = Vector2(0.9, 0.78)
	deity_popup.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(deity_popup, "scale", Vector2.ONE, 0.2)
	tween.tween_property(deity_popup, "modulate:a", 1.0, 0.14)


func _upgrade_selected_deity() -> void:
	var map := _get_map()
	if not map or popup_position == Vector2i(-1, -1):
		return
	if map.upgrade_deity(popup_position):
		var deity := map.get_cell(popup_position).deity as DeityInstance
		GameManager.post_message("神祇已提升至 %d 级" % deity.level)
		_show_selected_deity(popup_position)


func _remove_selected_deity() -> void:
	var map := _get_map()
	if not map or popup_position == Vector2i(-1, -1):
		return
	if map.remove_deity(popup_position):
		deity_popup.visible = false
		popup_interactive = false
		_set_tactical_info("资讯", "点击神祇、敌人或核心查看详细信息。")


func _show_hovered_cell(pos: Vector2i) -> void:
	if popup_interactive:
		return
	var map := _get_map()
	if not map:
		return
	if map.get_cell(pos).deity:
		_show_deity(pos)
	elif map.region_deity_count(pos) > 0:
		var deity_pos := map.region_deity_position(pos)
		if deity_pos != Vector2i(-1, -1):
			_show_deity(deity_pos)
	else:
		_show_terrain_info(pos)


func _show_enemy_info(pos: Vector2i) -> void:
	_set_deity_popup_paper_mode()
	core_info_popup.visible = false
	if popup_interactive:
		return
	var map := _get_map()
	if not map:
		return
	upgrade_preview.visible = false
	upgrade_button.visible = false
	remove_button.visible = false
	large_skill_button.visible = false
	migrate_button.visible = false
	upgrade_button_center.visible = false
	deity_stat_row.visible = false
	var description := map.enemy_description(pos)
	if description.is_empty():
		deity_popup.visible = false
		return
	popup_position = pos
	popup_title.text = "侵蚀体"
	attack_preview.text = ""
	resource_preview.text = ""
	attack_preview.visible = false
	resource_preview.visible = false
	deity_separator.visible = false
	attack_choice_button.visible = false
	resource_choice_button.visible = false
	deity_button_row.visible = false
	popup_interactive = false
	deity_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deity_popup.custom_minimum_size = Vector2(190, 64)
	deity_popup.size = Vector2(190, 64)
	deity_popup.visible = true
	_position_popup(pos)
	return


func _show_selected_enemy_info(pos: Vector2i) -> void:
	popup_interactive = false
	_show_enemy_info(pos)
	popup_interactive = true
	deity_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var map := _get_map()
	if map and tactical_label:
		_set_tactical_info("侵蚀体", map.enemy_description(pos))


func _show_core_info() -> void:
	if popup_interactive:
		return
	deity_popup.visible = false
	var compact_map := _get_map()
	if not compact_map:
		core_info_popup.visible = false
		return
	core_info_label.text = "中央核心"
	var hover_anchor := compact_map.to_global(
		compact_map.grid_to_world(compact_map.core_pos)
		+ Vector2(compact_map.CELL_SIZE + 18, 12)
	)
	var hover_viewport := get_viewport_rect().size
	core_info_popup.position = Vector2(
		clampf(hover_anchor.x, 8.0, hover_viewport.x - 128.0),
		clampf(hover_anchor.y, 8.0, hover_viewport.y - 56.0)
	)
	core_info_popup.size = Vector2(120, 48)
	core_info_popup.visible = true
	return
	core_info_label.text = "中央核心\n生命：%d / %d\n\n敌人抵达后会攻击核心并消失。核心生命降到 0 时本局失败。" % [
		GameManager.core_hp,
		GameManager.core_max_hp,
	]
	var compact_anchor := compact_map.to_global(
		compact_map.grid_to_world(compact_map.core_pos)
		+ Vector2(compact_map.CELL_SIZE + 30, 20)
	)
	var compact_viewport := get_viewport_rect().size
	core_info_popup.position = Vector2(
		clampf(compact_anchor.x, 8.0, compact_viewport.x - 368.0),
		clampf(compact_anchor.y, 8.0, compact_viewport.y - 188.0)
	)
	core_info_popup.size = Vector2(360, 180)
	core_info_popup.visible = true
	if tactical_label:
		tactical_label.text = "中央核心\n生命 %d / %d\n神力 %.1f" % [
			GameManager.core_hp,
			GameManager.core_max_hp,
			ResourceManager.divine_power,
		]
	return
	upgrade_preview.visible = false
	upgrade_button.visible = false
	remove_button.visible = false
	deity_popup.visible = false
	upgrade_button_center.visible = false
	popup_position = Vector2i(-1, -1)
	popup_title.text = "中央核心"
	attack_preview.text = "生命：%d / %d\n敌人接近后会攻击核心并消失；若它原本站在有效地形上，该格会增加污染。" % [
		GameManager.core_hp,
		GameManager.core_max_hp,
	]
	resource_preview.text = ""
	attack_preview.visible = true
	resource_preview.visible = false
	deity_separator.visible = false
	attack_choice_button.visible = false
	resource_choice_button.visible = false
	deity_button_row.visible = false
	popup_interactive = false
	deity_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deity_popup.custom_minimum_size = Vector2(360, 150)
	deity_popup.size = Vector2(360, 150)
	deity_popup.reset_size()
	var map := _get_map()
	if not map or attack_preview.text.is_empty():
		deity_popup.visible = false
		return
	call_deferred("_finish_show_core_info", map.core_pos)


func _show_selected_core_info() -> void:
	popup_interactive = false
	_show_core_info()
	popup_interactive = true
	if tactical_label:
		_set_tactical_info(
			"中央核心",
			"敌人抵达后会攻击核心；生命降到 0 时本局失败。"
		)
		_add_icon_stat(
			tactical_stat_row,
			"icon_core_hp",
			"icon_core_hp",
			"%d/%d" % [GameManager.core_hp, GameManager.core_max_hp],
			"生命"
		)
		_add_icon_stat(
			tactical_stat_row,
			"icon_divine_power",
			"icon_divine_power",
			"%.1f" % ResourceManager.divine_power,
			"神力"
		)


func _finish_show_core_info(core_position: Vector2i) -> void:
	if popup_interactive or attack_preview.text.is_empty():
		return
	deity_popup.size = Vector2(360, 150)
	deity_popup.visible = true
	_position_popup(core_position)


func _show_terrain_info(pos: Vector2i) -> void:
	if popup_interactive:
		return
	var map := _get_map()
	if not map:
		return
	deity_popup.visible = false
	core_info_label.text = "%s地块" % GameDefinitions.TERRAIN_NAMES[map.get_cell(pos).terrain]
	var anchor := map.to_global(
		map.grid_to_world(pos) + Vector2(map.CELL_SIZE + 12, 8)
	)
	var viewport_size := get_viewport_rect().size
	core_info_popup.position = Vector2(
		clampf(anchor.x, 8.0, viewport_size.x - 128.0),
		clampf(anchor.y, 8.0, viewport_size.y - 56.0)
	)
	core_info_popup.size = Vector2(120, 48)
	core_info_popup.visible = true
	return
	upgrade_preview.visible = false
	upgrade_button.visible = false
	remove_button.visible = false
	large_skill_button.visible = false
	migrate_button.visible = false
	upgrade_button_center.visible = false
	deity_stat_row.visible = false
	popup_position = pos
	popup_title.text = "%s地块" % GameDefinitions.TERRAIN_NAMES[map.get_cell(pos).terrain]
	attack_preview.text = ""
	resource_preview.text = ""
	attack_preview.visible = false
	resource_preview.visible = false
	deity_separator.visible = false
	attack_choice_button.visible = false
	resource_choice_button.visible = false
	deity_button_row.visible = false
	popup_interactive = false
	deity_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deity_popup.custom_minimum_size = Vector2(190, 64)
	deity_popup.reset_size()
	_position_popup(pos)
	deity_popup.visible = true


func _show_terrain_deities(pos: Vector2i) -> void:
	_set_deity_popup_placement_mode()
	core_info_popup.visible = false
	var map := _get_map()
	if not map:
		return
	var existing_deity_pos := map.region_deity_position(pos)
	if existing_deity_pos != Vector2i(-1, -1):
		deity_popup.visible = false
		popup_interactive = false
		_update_tactical_deity(existing_deity_pos)
		return
	upgrade_preview.visible = false
	upgrade_button.visible = false
	remove_button.visible = false
	large_skill_button.visible = false
	migrate_button.visible = false
	upgrade_button_center.visible = false
	deity_stat_row.visible = false
	popup_position = pos
	popup_title.text = "在%s地块安置神祇" % GameDefinitions.TERRAIN_NAMES[map.get_cell(pos).terrain]
	popup_title.text = ""
	attack_preview.visible = false
	resource_preview.visible = false
	deity_separator.visible = false
	attack_choice_button.visible = true
	resource_choice_button.visible = ProgressManager.current_map != 0
	deity_button_row.visible = true
	attack_choice_button.text = "安置 %s" % map.deity_form_name(pos, GameDefinitions.DeityType.ATTACK)
	resource_choice_button.text = "安置 %s" % map.deity_form_name(pos, GameDefinitions.DeityType.RESOURCE)
	var terrain := map.get_cell(pos).terrain
	attack_choice_button.tooltip_text = "%s\n%s" % [
		attack_choice_button.text,
		map.deity_ability_description(GameDefinitions.DeityType.ATTACK, terrain),
	]
	resource_choice_button.tooltip_text = "%s\n%s" % [
		resource_choice_button.text,
		map.deity_ability_description(GameDefinitions.DeityType.RESOURCE, terrain),
	]
	AssetCatalog.apply_button_visual(attack_choice_button, "icon_attack_deity", true)
	AssetCatalog.apply_button_visual(resource_choice_button, "icon_resource_deity", true)
	attack_choice_button.disabled = (
		not map.can_place_deity(GameDefinitions.DeityType.ATTACK, pos)
		or not ResourceManager.can_afford(map.deity_purchase_cost(GameDefinitions.DeityType.ATTACK))
	)
	resource_choice_button.disabled = (
		not map.can_place_deity(GameDefinitions.DeityType.RESOURCE, pos)
		or not ResourceManager.can_afford(map.deity_purchase_cost(GameDefinitions.DeityType.RESOURCE))
	)
	_set_tactical_info(
		"%s神域" % GameDefinitions.TERRAIN_NAMES[terrain],
		map.terrain_domain_description(pos)
	)
	popup_interactive = true
	deity_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	deity_popup.custom_minimum_size = Vector2(230, 120)
	deity_popup.reset_size()
	_position_deity_choice_popup(pos)
	deity_popup.visible = true


func _position_deity_choice_popup(pos: Vector2i) -> void:
	var map := _get_map()
	var cell_center := map.to_global(
		map.grid_to_world(pos) + Vector2.ONE * float(map.CELL_SIZE) * 0.5
	)
	var viewport_size := get_viewport_rect().size
	var target := Vector2(
		cell_center.x - deity_popup.size.x * 0.5,
		cell_center.y - deity_popup.size.y - 18.0
	)
	deity_popup.position = Vector2(
		clampf(target.x, 8.0, viewport_size.x - deity_popup.size.x - 8.0),
		clampf(target.y, 8.0, viewport_size.y - deity_popup.size.y - 8.0)
	)


func _position_popup(pos: Vector2i) -> void:
	var map := _get_map()
	var anchor := map.to_global(map.grid_to_world(pos) + Vector2(map.CELL_SIZE + 8, -20))
	var viewport_size := get_viewport_rect().size
	deity_popup.position = Vector2(
		clampf(anchor.x, 8.0, viewport_size.x - deity_popup.size.x - 8.0),
		clampf(anchor.y, 8.0, viewport_size.y - deity_popup.size.y - 8.0)
	)


func _purchase_attack_deity() -> void:
	_purchase_deity(GameDefinitions.DeityType.ATTACK)


func _purchase_resource_deity() -> void:
	_purchase_deity(GameDefinitions.DeityType.RESOURCE)


func _purchase_deity(deity_type: int) -> void:
	if popup_position == Vector2i(-1, -1) or not GameManager.scene_root:
		return
	GameManager.scene_root.purchase_deity_at(popup_position, deity_type)
	deity_popup.visible = false
	popup_interactive = false


func _on_state_changed(_value: Variant = null) -> void:
	_refresh_view()


func _on_combat_time_changed(_remaining: float) -> void:
	_refresh_view()


func _refresh_view() -> void:
	if not start_button:
		return
	core_value.text = "%d / %d" % [GameManager.core_hp, GameManager.core_max_hp]
	power_value.text = "%.1f" % ResourceManager.divine_power
	var build := TurnManager.current_phase == TurnManager.Phase.BUILD
	start_button.disabled = not build
	if debug_panel and debug_panel.visible:
		_refresh_debug_panel()


func _create_debug_panel() -> void:
	debug_panel = PanelContainer.new()
	debug_panel.visible = false
	debug_panel.position = Vector2(12, 92)
	debug_panel.size = Vector2(340, 460)
	debug_panel.z_index = 180
	add_child(debug_panel)
	debug_label = Label.new()
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_panel.add_child(debug_label)


func _create_tutorial_panel() -> void:
	tutorial_highlight = PanelContainer.new()
	tutorial_highlight.visible = false
	tutorial_highlight.z_index = 174
	tutorial_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_highlight.process_mode = Node.PROCESS_MODE_ALWAYS
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(1.0, 0.86, 0.35, 0.08)
	highlight_style.border_color = Color(1.0, 0.92, 0.58, 0.92)
	highlight_style.set_border_width_all(4)
	highlight_style.set_corner_radius_all(18)
	tutorial_highlight.add_theme_stylebox_override("panel", highlight_style)
	add_child(tutorial_highlight)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.visible = false
	tutorial_panel.position = Vector2(366, 76)
	tutorial_panel.size = Vector2(470, 138)
	tutorial_panel.z_index = 175
	tutorial_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var transparent := StyleBoxFlat.new()
	transparent.bg_color = Color(0.025, 0.04, 0.06, 0.58)
	transparent.border_color = Color(0.72, 0.52, 0.30, 0.82)
	transparent.set_border_width_all(2)
	transparent.set_corner_radius_all(16)
	tutorial_panel.add_theme_stylebox_override("panel", transparent)
	add_child(tutorial_panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 8)
	tutorial_panel.add_child(stack)
	var safe_area := MarginContainer.new()
	safe_area.add_theme_constant_override("margin_left", 16)
	safe_area.add_theme_constant_override("margin_right", 16)
	safe_area.add_theme_constant_override("margin_top", 10)
	safe_area.add_theme_constant_override("margin_bottom", 10)
	stack.add_child(safe_area)
	tutorial_label = Label.new()
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_label.add_theme_font_size_override("font_size", 20)
	tutorial_label.add_theme_color_override("font_color", Color("f0e5d0"))
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safe_area.add_child(tutorial_label)
	tutorial_continue_button = Button.new()
	tutorial_continue_button.text = "继续"
	tutorial_continue_button.custom_minimum_size = Vector2(120, 36)
	tutorial_continue_button.visible = false
	tutorial_continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial_continue_button.pressed.connect(_dismiss_tutorial)
	AssetCatalog.apply_button_visual(tutorial_continue_button)
	stack.add_child(tutorial_continue_button)


func _create_cheat_panel() -> void:
	cheat_panel = PanelContainer.new()
	cheat_panel.visible = false
	cheat_panel.position = Vector2(20, 590)
	cheat_panel.size = Vector2(310, 430)
	cheat_panel.z_index = 1000
	cheat_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	cheat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cheat_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	cheat_panel.add_child(content)
	var title := Label.new()
	title.text = "作弊接口（F4）"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var actions := [
		["获得一次刷新", "cheat_grant_refresh"],
		["清除新手教程记录", "cheat_reset_tutorial"],
		["增加 25 神力", "cheat_add_power"],
		["恢复核心生命", "cheat_heal_core"],
		["摧毁敌方核心", "cheat_destroy_enemy_cores"],
		["填满地图", "cheat_fill_map"],
	]
	for entry in actions:
		var method_name := str(entry[1])
		var button := Button.new()
		button.text = str(entry[0])
		button.pressed.connect(_run_cheat.bind(method_name))
		AssetCatalog.apply_button_visual(button)
		content.add_child(button)


func _create_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.position = Vector2(710, 220)
	settings_panel.size = Vector2(500, 520)
	settings_panel.z_index = 195
	settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	AssetCatalog.apply_panel_background(settings_panel, "settings_background")
	add_child(settings_panel)
	var readability := ColorRect.new()
	readability.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	readability.color = Color(0, 0, 0, 0)
	readability.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.add_child(readability)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 72.0
	content.offset_right = -72.0
	content.offset_top = 82.0
	content.offset_bottom = -70.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	settings_panel.add_child(content)
	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("4b2d1a"))
	content.add_child(title)
	var audio_row := HBoxContainer.new()
	audio_row.alignment = BoxContainer.ALIGNMENT_CENTER
	audio_row.add_theme_constant_override("separation", 22)
	content.add_child(audio_row)
	var music_toggle := Button.new()
	music_toggle.text = "游戏音乐"
	music_toggle.custom_minimum_size = Vector2(72, 72)
	AssetCatalog.apply_button_visual(
		music_toggle,
		"icon_music" if AudioManager.music_enabled else "icon_no_music",
		true
	)
	music_toggle.pressed.connect(func() -> void:
		AudioManager.set_music_enabled(not AudioManager.music_enabled)
		_rebuild_settings_music_icon(music_toggle)
	)
	audio_row.add_child(music_toggle)
	var volume_icon := TextureRect.new()
	volume_icon.custom_minimum_size = Vector2(72, 72)
	volume_icon.texture = AssetCatalog.texture("icon_volume")
	volume_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	volume_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	volume_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	audio_row.add_child(volume_icon)
	var volume := HSlider.new()
	volume.custom_minimum_size = Vector2(220, 32)
	volume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volume.min_value = 0.0
	volume.max_value = 100.0
	volume.value = AudioManager.music_volume_percent * 100.0
	volume.value_changed.connect(func(value: float) -> void:
		AudioManager.set_music_volume(value / 100.0)
	)
	content.add_child(volume)
	var fullscreen_button := Button.new()
	fullscreen_button.text = "全屏"
	fullscreen_button.custom_minimum_size = Vector2(150, 42)
	AssetCatalog.apply_button_visual(fullscreen_button)
	fullscreen_button.pressed.connect(func() -> void:
		_toggle_fullscreen_from_settings()
		fullscreen_button.text = "窗口" if _is_fullscreen() else "全屏"
	)
	fullscreen_button.text = "窗口" if _is_fullscreen() else "全屏"
	content.add_child(fullscreen_button)
	var save_button := Button.new()
	save_button.text = "存档"
	save_button.custom_minimum_size = Vector2(150, 42)
	AssetCatalog.apply_button_visual(save_button)
	save_button.pressed.connect(func() -> void:
		if GameManager.scene_root and GameManager.scene_root.has_method("_save_checkpoint_if_possible"):
			GameManager.scene_root.call("_save_checkpoint_if_possible")
		ProgressManager.save_current_run()
		GameManager.post_message("进度已保存")
	)
	content.add_child(save_button)
	var quit_button := Button.new()
	quit_button.text = "退出到桌面"
	quit_button.tooltip_text = "退出到桌面"
	quit_button.custom_minimum_size = Vector2(150, 42)
	quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	AssetCatalog.apply_button_visual(
		quit_button,
		"button_quit" if AssetCatalog.texture("button_quit") else "icon_menu",
		true
	)
	quit_button.pressed.connect(_quit_to_desktop)
	content.add_child(quit_button)


func _create_tactical_panel() -> void:
	tactical_panel = Control.new()
	tactical_panel.position = Vector2(-12, 205)
	tactical_panel.size = Vector2(380, 570)
	tactical_panel.z_index = 80
	add_child(tactical_panel)
	var board := TextureRect.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.texture = AssetCatalog.texture("board")
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tactical_panel.add_child(board)
	status_row.position = Vector2(-8, 125)
	status_row.size = Vector2(304, 58)
	status_row.z_index = 82
	var title_paper := PanelContainer.new()
	title_paper.position = Vector2(78, 62)
	title_paper.size = Vector2(224, 66)
	title_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AssetCatalog.apply_panel_background(title_paper, "stats_background")
	tactical_panel.add_child(title_paper)
	tactical_title = Label.new()
	tactical_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tactical_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tactical_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tactical_title.add_theme_font_size_override("font_size", 18)
	tactical_title.add_theme_color_override("font_color", Color("4b2d1a"))
	tactical_title.text = "资讯"
	title_paper.add_child(tactical_title)
	tactical_stat_row = HBoxContainer.new()
	tactical_stat_row.position = Vector2(72, 142)
	tactical_stat_row.size = Vector2(236, 72)
	tactical_stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tactical_stat_row.add_theme_constant_override("separation", 2)
	tactical_stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tactical_panel.add_child(tactical_stat_row)
	var margin := MarginContainer.new()
	margin.position = Vector2(72, 222)
	margin.size = Vector2(236, 230)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tactical_panel.add_child(margin)
	tactical_label = Label.new()
	tactical_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tactical_label.add_theme_font_size_override("font_size", 14)
	tactical_label.add_theme_color_override("font_color", Color("ead9bc"))
	tactical_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tactical_label.text = "点击神祇、敌人或核心查看详细信息。"
	margin.add_child(tactical_label)


func _set_tactical_info(title: String, body: String) -> void:
	if tactical_title:
		tactical_title.text = title
	if tactical_label:
		tactical_label.text = body
	if tactical_stat_row:
		for child in tactical_stat_row.get_children():
			child.queue_free()


func _update_tactical_deity(pos: Vector2i) -> void:
	var map := _get_map()
	if not map or not tactical_label:
		return
	var deity := map.get_cell(pos).deity as DeityInstance
	if not deity:
		return
	var detail_context := map.deity_domain_context(pos)
	var detail_area := int(detail_context.get("area", 1))
	var threshold := int(GameDefinitions.BALANCE.large_domain_threshold)
	var detail_area_text := "神域还很小" if detail_area < threshold else "神域很大"
	var detail_stats := map.deity_stats(pos)
	var function_text := map.deity_function_description(pos)
	_set_tactical_info(
		map.deity_form_name(pos, deity.deity_type),
		"%s\n\n%s（%d格）\n\n已获得：%s\n\n主动技能：%s" % [
			function_text,
			detail_area_text,
			detail_area,
			map.deity_active_effects_description(pos),
			map.large_domain_skill_description(pos),
		]
	)
	_add_icon_stat(tactical_stat_row, "icon_level", "icon_shaping", str(deity.level), "等级")
	_add_icon_stat(tactical_stat_row, "icon_core_hp", "icon_core_hp", "%d/%d" % [deity.hp, deity.max_hp], "生命")
	if deity.deity_type == GameDefinitions.DeityType.ATTACK:
		_add_icon_stat(tactical_stat_row, "icon_damage", "icon_attack_deity", str(int(detail_stats.damage)), "伤害")
		_add_icon_stat(tactical_stat_row, "icon_range", "icon_attack_deity", "%.1f" % float(detail_stats.range), "射程")
	else:
		match map.get_cell(pos).terrain:
			GameDefinitions.TerrainType.PLAIN:
				_add_icon_stat(tactical_stat_row, "icon_core_hp", "icon_resource_deity", "%.2f" % float(detail_stats.amount), "治疗")
			GameDefinitions.TerrainType.MOUNTAIN:
				_add_icon_stat(tactical_stat_row, "icon_damage", "icon_attack_deity", "%.2f" % float(detail_stats.amount), "凝滞伤害")
			GameDefinitions.TerrainType.RIVER:
				_add_icon_stat(tactical_stat_row, "icon_range", "icon_resource_deity", "%.1f" % float(detail_stats.range), "控制范围")
			GameDefinitions.TerrainType.FOREST:
				_add_icon_stat(tactical_stat_row, "icon_production", "icon_resource_deity", "%.2f" % float(detail_stats.amount), "产量")


func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	get_tree().paused = settings_panel.visible
	_refresh_top_right_secondary_button()


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _toggle_fullscreen_from_settings() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED
		if _is_fullscreen()
		else DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _top_right_secondary_action() -> void:
	if settings_panel.visible:
		_toggle_settings()
	else:
		_request_main_menu()


func _refresh_top_right_secondary_button() -> void:
	if not is_instance_valid(main_menu_button):
		return
	if settings_panel.visible:
		main_menu_button.tooltip_text = "继续游戏"
		main_menu_button.icon = AssetCatalog.texture(
			"button_home_start" if AssetCatalog.texture("button_home_start") else "icon_start"
		)
	else:
		main_menu_button.tooltip_text = "返回主菜单"
		main_menu_button.icon = AssetCatalog.texture(
			"button_main_menu" if AssetCatalog.texture("button_main_menu") else "icon_menu"
		)


func _rebuild_settings_music_icon(button: Button) -> void:
	button.icon = AssetCatalog.texture("icon_music" if AudioManager.music_enabled else "icon_no_music")


func _request_main_menu() -> void:
	get_tree().paused = false
	menu_requested.emit()


func _quit_to_desktop() -> void:
	get_tree().paused = false
	ProgressManager.save_current_run()
	get_tree().quit()


func _run_cheat(method_name: String) -> void:
	if GameManager.scene_root and GameManager.scene_root.has_method(method_name):
		GameManager.scene_root.call(method_name)


func _rebuild_deity_stat_icons(pos: Vector2i) -> void:
	for child in deity_stat_row.get_children():
		child.queue_free()
	var map := _get_map()
	if not map:
		return
	var deity := map.get_cell(pos).deity as DeityInstance
	var stats := map.deity_stats(pos)
	_add_icon_stat(deity_stat_row, "icon_level", "icon_shaping", str(deity.level), "等级")
	_add_icon_stat(deity_stat_row, "icon_core_hp", "icon_core_hp", "%d/%d" % [deity.hp, deity.max_hp], "生命")
	if deity.deity_type == GameDefinitions.DeityType.ATTACK:
		_add_icon_stat(deity_stat_row, "icon_damage", "icon_attack_deity", str(int(stats.damage)), "伤害")
		_add_icon_stat(deity_stat_row, "icon_range", "icon_attack_deity", "%.1f" % float(stats.range), "射程")
		_add_icon_stat(deity_stat_row, "icon_speed", "icon_time_flow", "%.2f" % float(stats.interval), "攻击间隔")
	else:
		_add_icon_stat(deity_stat_row, "icon_production", "icon_resource_deity", "%.2f" % float(stats.amount), "产量")
		_add_icon_stat(deity_stat_row, "icon_speed", "icon_time_flow", "%.2f" % float(stats.interval), "生产间隔")


func _add_icon_stat(
	parent: HBoxContainer,
	icon_key: String,
	fallback_key: String,
	value: String,
	tooltip: String
) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(52, 66)
	box.tooltip_text = tooltip
	var icon_back := PanelContainer.new()
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0.025, 0.03, 0.04, 0.78)
	icon_style.border_color = Color(0.36, 0.21, 0.13, 0.95)
	icon_style.set_border_width_all(2)
	icon_style.set_corner_radius_all(8)
	icon_back.add_theme_stylebox_override("panel", icon_style)
	box.add_child(icon_back)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(34, 34)
	icon.texture = AssetCatalog.texture_or(icon_key, fallback_key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_back.add_child(icon)
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("f0dfc5"))
	box.add_child(label)
	parent.add_child(box)


func show_tutorial(text: String) -> void:
	tutorial_label.text = text
	tutorial_panel.visible = true


func show_tutorial_step(step: Dictionary) -> void:
	_restore_tutorial_time_state()
	tutorial_hide_serial += 1
	var serial := tutorial_hide_serial
	show_tutorial(str(step.get("text", "")))
	_show_tutorial_highlight(step)
	tutorial_previous_pause = get_tree().paused
	tutorial_previous_time_scale = Engine.time_scale
	tutorial_active_pause = bool(step.get("pause", false))
	var slow_motion := float(step.get("slow_motion", 1.0))
	if slow_motion > 0.0 and slow_motion < 1.0:
		Engine.time_scale = slow_motion
	tutorial_continue_button.visible = tutorial_active_pause
	if tutorial_active_pause:
		get_tree().paused = true
		return
	var duration := float(step.get("duration", 0.0))
	if duration > 0.0:
		var tween := create_tween()
		tween.tween_interval(duration)
		tween.tween_callback(func() -> void:
			if serial == tutorial_hide_serial:
				TutorialManager.complete_active()
		)


func hide_tutorial() -> void:
	tutorial_hide_serial += 1
	tutorial_panel.visible = false
	if tutorial_continue_button:
		tutorial_continue_button.visible = false
	if tutorial_highlight:
		tutorial_highlight.visible = false
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():
		tutorial_highlight_tween.kill()
	_restore_tutorial_time_state()


func _dismiss_tutorial() -> void:
	TutorialManager.complete_active()


func _restore_tutorial_time_state() -> void:
	if tutorial_active_pause:
		get_tree().paused = tutorial_previous_pause
		tutorial_active_pause = false
	Engine.time_scale = tutorial_previous_time_scale


func _show_tutorial_highlight(step: Dictionary) -> void:
	if not tutorial_highlight:
		return
	var rect := _tutorial_rect_for_step(step)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		tutorial_highlight.visible = false
		return
	var local_pos := get_global_transform().affine_inverse() * rect.position
	tutorial_highlight.position = local_pos - Vector2(8, 8)
	tutorial_highlight.size = rect.size + Vector2(16, 16)
	tutorial_highlight.pivot_offset = tutorial_highlight.size * 0.5
	tutorial_highlight.visible = true
	tutorial_highlight.modulate.a = 0.96
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():
		tutorial_highlight_tween.kill()
	tutorial_highlight_tween = create_tween().set_loops()
	tutorial_highlight_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tutorial_highlight_tween.tween_property(tutorial_highlight, "scale", Vector2(1.035, 1.035), 0.55)
	tutorial_highlight_tween.tween_property(tutorial_highlight, "scale", Vector2.ONE, 0.55)


func _tutorial_rect_for_step(step: Dictionary) -> Rect2:
	var highlights: Array = step.get("highlight", [])
	var key := str(highlights[0]) if not highlights.is_empty() else ""
	var payload: Dictionary = step.get("payload", {})
	match key:
		"time_button":
			return _global_rect_for_control(start_button)
		"upgrade_button":
			return _global_rect_for_control(upgrade_button)
		"remove_button":
			return _global_rect_for_control(remove_button)
		"large_skill_button":
			return _global_rect_for_control(large_skill_button)
		"migration_button":
			return _hand_tutorial_rect("migration_button")
		"shop_card":
			return _hand_tutorial_rect("shop_card")
		"shop":
			return _shop_highlight_rect()
		"operation_buttons":
			return _combined_control_rect([upgrade_button, remove_button])
		"resource":
			return _global_rect_for_control(power_status)
		"core":
			return _cell_highlight_rect(_get_map().core_pos if _get_map() else Vector2i(-1, -1), 1.45)
		"enemy_core":
			if payload.has("pos"):
				return _cell_highlight_rect(payload.get("pos"), 1.35)
			return _first_enemy_core_rect()
		"domain":
			if payload.has("pos"):
				return _domain_highlight_rect(payload.get("pos"))
			return _map_highlight_rect()
		"placement_cells":
			return _placement_highlight_rect()
		"deity", "enemy", "cell", "map":
			if payload.has("pos"):
				return _cell_highlight_rect(payload.get("pos"), 1.25)
			return _map_highlight_rect()
		_:
			if payload.has("pos"):
				return _cell_highlight_rect(payload.get("pos"), 1.2)
			return _map_highlight_rect()


func _global_rect_for_control(control: Control) -> Rect2:
	if not is_instance_valid(control) or not control.visible:
		return Rect2()
	return Rect2(control.global_position, control.size)


func _cell_highlight_rect(pos_value: Variant, scale_factor: float = 1.0) -> Rect2:
	var map := _get_map()
	if not map:
		return Rect2()
	var pos := pos_value as Vector2i
	if pos == null or not map.is_in_bounds(pos):
		return Rect2()
	var top_left := map.to_global(map.grid_to_world(pos))
	var cell_scale := map.get_global_transform().get_scale()
	var size := Vector2(map.CELL_SIZE * absf(cell_scale.x), map.CELL_SIZE * absf(cell_scale.y)) * scale_factor
	return Rect2(top_left + (Vector2(map.CELL_SIZE, map.CELL_SIZE) * cell_scale - size) * 0.5, size)


func _map_highlight_rect() -> Rect2:
	var map := _get_map()
	if not map:
		return Rect2()
	var top_left := map.to_global(map.grid_to_world(Vector2i.ZERO))
	var bottom_right := map.to_global(map.grid_to_world(Vector2i(map.GRID_W, map.GRID_H)))
	return Rect2(top_left, bottom_right - top_left)


func _shop_highlight_rect() -> Rect2:
	var hand := get_node_or_null("../HandUI") as Control
	if hand and hand.visible:
		return Rect2(hand.global_position, hand.size)
	return Rect2(Vector2(1380, 110), Vector2(320, 740))


func _hand_tutorial_rect(kind: String) -> Rect2:
	var hand := get_node_or_null("../HandUI") as HandUI
	if hand:
		return hand.tutorial_rect(kind)
	return Rect2()


func _combined_control_rect(controls: Array) -> Rect2:
	var result := Rect2()
	for control_variant in controls:
		var control := control_variant as Control
		var rect := _global_rect_for_control(control)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		result = rect if result.size == Vector2.ZERO else result.merge(rect)
	return result


func _domain_highlight_rect(pos_value: Variant) -> Rect2:
	var map := _get_map()
	if not map:
		return Rect2()
	var pos: Vector2i = pos_value
	if not map.is_in_bounds(pos):
		return Rect2()
	var result := Rect2()
	for region_pos in map.terrain_region(pos):
		var rect := _cell_highlight_rect(region_pos, 1.02)
		result = rect if result.size == Vector2.ZERO else result.merge(rect)
	return result


func _placement_highlight_rect() -> Rect2:
	var map := _get_map()
	if not map or not map.preview_terrain:
		return _map_highlight_rect()
	var result := Rect2()
	for offset in map.preview_terrain.rotated_shape(map.preview_rotation):
		var rect := _cell_highlight_rect(map.preview_pos + offset, 1.08)
		result = rect if result.size == Vector2.ZERO else result.merge(rect)
	return result


func _first_enemy_core_rect() -> Rect2:
	var map := _get_map()
	if not map:
		return Rect2()
	for pos in map.enemy_cores:
		return _cell_highlight_rect(pos, 1.35)
	return Rect2()


func hide_result_overlay() -> void:
	if result_overlay and is_instance_valid(result_overlay):
		result_overlay.visible = false
		result_overlay.queue_free()
	result_overlay = null
	if result_modal_blocker and is_instance_valid(result_modal_blocker):
		result_modal_blocker.queue_free()
	result_modal_blocker = null


func _begin_result_modal() -> void:
	deity_popup.visible = false
	card_hover_popup.visible = false
	core_info_popup.visible = false
	if result_modal_blocker and is_instance_valid(result_modal_blocker):
		result_modal_blocker.queue_free()
	result_modal_blocker = ColorRect.new()
	result_modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_modal_blocker.color = Color(0, 0, 0, 0.18)
	result_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	result_modal_blocker.z_index = 189
	add_child(result_modal_blocker)


func _refresh_debug_panel() -> void:
	var map := _get_map()
	if not map:
		return
	var attack_count := 0
	var resource_count := 0
	var level_1 := 0
	var level_2 := 0
	var level_3 := 0
	for pos in map.get_all_deity_positions():
		var deity := map.get_cell(pos).deity as DeityInstance
		if deity.deity_type == GameDefinitions.DeityType.ATTACK:
			attack_count += 1
		else:
			resource_count += 1
		if deity.level >= 3:
			level_3 += 1
		elif deity.level >= 2:
			level_2 += 1
		else:
			level_1 += 1
	debug_label.text = (
		"调试统计（F3）\n"
		+ "地图：%d　战斗轮数：%d\n"
		+ "填充率：%.1f%%　当前神力：%.1f\n"
		+ "每轮基础收入：%.1f　资源神本轮：%.2f\n"
		+ "资源神累计：%.2f\n"
		+ "攻击神：%d　资源神：%d\n"
		+ "1级：%d　2级：%d　3级：%d\n"
		+ "当前敌人：%d　累计生成：%d　累计击杀：%d\n"
		+ "污染次数：%d　崩塌格：%d\n"
		+ "商店刷新：%d　游戏时间：%.1f 秒\n"
		+ "核心生命：%d / %d"
	) % [
		ProgressManager.current_map,
		GameManager.current_round,
		map.fill_ratio() * 100.0,
		ResourceManager.divine_power,
		float(GameDefinitions.BALANCE.combat_base_income),
		float(ProgressManager.stats.get("resource_income_round", 0.0)),
		float(ProgressManager.stats.get("resource_income_total", 0.0)),
		attack_count,
		resource_count,
		level_1,
		level_2,
		level_3,
		map.get_all_enemy_positions().size(),
		int(ProgressManager.stats.get("enemy_spawned", 0)),
		int(ProgressManager.stats.get("enemy_killed", 0)),
		int(ProgressManager.stats.get("pollution_events", 0)),
		int(ProgressManager.stats.get("collapsed_cells", 0)),
		int(ProgressManager.stats.get("shop_refreshes", 0)),
		ProgressManager.run_elapsed_seconds(),
		GameManager.core_hp,
		GameManager.core_max_hp,
	]


func show_map_result(snapshot: Dictionary, result: Dictionary, final_map: bool) -> void:
	_clear_result_overlay()
	_begin_result_modal()
	result_overlay = PanelContainer.new()
	result_overlay.position = Vector2(470, 150)
	result_overlay.size = Vector2(660, 700)
	result_overlay.z_index = 190
	AssetCatalog.apply_panel_background(result_overlay, "result_background")
	add_child(result_overlay)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	result_overlay.add_child(content)
	var title := Label.new()
	title.text = "六面地图全部完成" if final_map else "第 %d 张地图完成" % ProgressManager.current_map
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("342115"))
	content.add_child(title)
	var body := Label.new()
	body.text = (
		"通关时间：%.1f 秒\n核心剩余生命：%d\n剩余神力：%.1f\n"
		+ "攻击神祇：%d　资源神祇：%d\n升级神祇：%d\n"
		+ "商店刷新：%d　污染崩塌：%d\n本局分数：%d\n%s"
	) % [
		float(snapshot.time),
		int(snapshot.core_hp),
		float(snapshot.resource),
		int(snapshot.attack_deities),
		int(snapshot.resource_deities),
		int(snapshot.level_2_deities),
		int(snapshot.shop_refreshes),
		int(snapshot.collapsed_cells),
		int(result.score),
		"刷新本地最佳记录" if bool(result.best_changed) else "",
	]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Color("3c2819"))
	content.add_child(body)
	if not final_map:
		var next := Button.new()
		next.text = "继续前往图%d" % (ProgressManager.current_map + 1)
		next.custom_minimum_size = Vector2(112, 112)
		next.pressed.connect(func() -> void: continue_requested.emit())
		AssetCatalog.apply_button_visual(
			next,
			"button_continue" if AssetCatalog.texture("button_continue") else "icon_time_flow",
			AssetCatalog.texture("button_continue") != null
		)
		content.add_child(next)
	var menu := Button.new()
	menu.text = "返回主菜单"
	menu.custom_minimum_size = Vector2(112, 112)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	AssetCatalog.apply_button_visual(
		menu,
		"button_main_menu" if AssetCatalog.texture("button_main_menu") else "icon_menu",
		AssetCatalog.texture("button_main_menu") != null
	)
	content.add_child(menu)
	result_overlay.modulate.a = 0.0
	result_overlay.scale = Vector2(0.96, 0.96)
	result_overlay.pivot_offset = result_overlay.size * 0.5
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(result_overlay, "modulate:a", 1.0, 0.22)
	reveal.tween_property(result_overlay, "scale", Vector2.ONE, 0.26)


func show_failure() -> void:
	_clear_result_overlay()
	_begin_result_modal()
	result_overlay = PanelContainer.new()
	result_overlay.position = Vector2(520, 310)
	result_overlay.size = Vector2(560, 380)
	result_overlay.z_index = 190
	AssetCatalog.apply_panel_background(result_overlay, "failure_background")
	add_child(result_overlay)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	result_overlay.add_child(content)
	var title := Label.new()
	title.text = "中央核心已被摧毁"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	content.add_child(title)
	var description := Label.new()
	description.text = "本次探索结束。你可以返回主菜单重新开始。"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 19)
	content.add_child(description)
	var menu := Button.new()
	menu.text = "返回主菜单"
	menu.custom_minimum_size = Vector2(112, 112)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	AssetCatalog.apply_button_visual(
		menu,
		"button_main_menu" if AssetCatalog.texture("button_main_menu") else "icon_menu",
		AssetCatalog.texture("button_main_menu") != null
	)
	content.add_child(menu)


func show_blessing_choices(ids: Array[String]) -> void:
	_clear_result_overlay()
	_begin_result_modal()
	result_overlay = PanelContainer.new()
	result_overlay.position = Vector2(350, 275)
	result_overlay.size = Vector2(900, 500)
	result_overlay.z_index = 190
	result_overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(result_overlay)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	result_overlay.add_child(root)
	var title := Label.new()
	title.text = "选择一个祝福带入图%d" % (ProgressManager.current_map + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.custom_minimum_size = Vector2(816, 280)
	root.add_child(row)
	for option_index in range(ids.size()):
		var id := ids[option_index]
		var choice_id := id
		var data: Dictionary = GameDefinitions.BLESSINGS[choice_id]
		var button := Button.new()
		button.text = "%s\n\n%s" % [str(data.title), str(data.description)]
		button.custom_minimum_size = Vector2(260, 280)
		button.size = Vector2(260, 280)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_FILL
		button.size_flags_stretch_ratio = 1.0
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func() -> void:
			if result_overlay:
				result_overlay.visible = false
			blessing_selected.emit(choice_id)
		)
		var blessing_button_key := "button_blessing_%d" % (option_index + 1)
		if AssetCatalog.texture(blessing_button_key):
			AssetCatalog.apply_button_background(button, blessing_button_key)
		else:
			AssetCatalog.apply_button_visual(button)
		row.add_child(button)


func _clear_result_overlay() -> void:
	if result_overlay and is_instance_valid(result_overlay):
		result_overlay.queue_free()
	result_overlay = null
	if result_modal_blocker and is_instance_valid(result_modal_blocker):
		result_modal_blocker.queue_free()
	result_modal_blocker = null
