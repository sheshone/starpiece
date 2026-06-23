class_name StartScreen
extends Control

signal start_requested
signal load_requested

const MenuAmbientScript := preload("res://scripts/ui/menu_ambient.gd")
const AttentionRingScript := preload("res://scripts/ui/attention_ring.gd")

var help_panel: PanelContainer
var achievements_panel: PanelContainer
var home_overlay: PanelContainer
var home_modal_blocker: ColorRect
var help_modal_blocker: ColorRect
var home_close_button: Button
var help_close_button: Button
var primary_start_button: Button
var primary_help_button: Button
var tutorial_ring: Control


func _ready() -> void:
	theme = AssetCatalog.interface_theme()
	AudioManager.play_music("music_menu", -7.0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_background()
	var ambient := MenuAmbientScript.new()
	add_child(ambient)
	_build_menu()
	_create_help_panel()
	_create_home_overlay()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.keycode != KEY_ESCAPE:
		return
	if help_panel and help_panel.visible:
		help_panel.visible = false
		help_modal_blocker.visible = false
		help_close_button.visible = false
		get_viewport().set_input_as_handled()
	elif home_overlay and home_overlay.visible:
		home_overlay.visible = false
		home_modal_blocker.visible = false
		if is_instance_valid(home_close_button):
			home_close_button.queue_free()
		get_viewport().set_input_as_handled()


func _build_background() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = AssetCatalog.texture("menu_background")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	if not backdrop.texture:
		var fallback := ColorRect.new()
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.color = Color("0b0e14")
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(fallback)


func _build_menu() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(820, 500)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)

	var title := TextureRect.new()
	title.custom_minimum_size = Vector2(780, 220)
	title.texture = AssetCatalog.texture("game_title")
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.pivot_offset = Vector2(390, 110)
	column.add_child(title)
	var title_tween := create_tween().set_loops()
	title_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	title_tween.tween_interval(1.5)
	title_tween.tween_property(title, "scale", Vector2(1.018, 1.018), 0.10)
	title_tween.parallel().tween_property(title, "modulate", Color(1.04, 1.025, 0.95), 0.10)
	title_tween.tween_property(title, "scale", Vector2.ONE, 0.12)
	title_tween.parallel().tween_property(title, "modulate", Color.WHITE, 0.12)
	title_tween.tween_interval(0.08)
	title_tween.tween_property(title, "scale", Vector2(1.012, 1.012), 0.09)
	title_tween.tween_property(title, "scale", Vector2.ONE, 0.14)

	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 32)
	column.add_child(content)

	var start_button := _icon_button("开始游戏", "icon_start", Vector2(176, 176))
	primary_start_button = start_button
	start_button.pressed.connect(func() -> void:
		AudioManager.play_sfx_first(["button_start", "purchase"], -2.0)
		AudioManager.stop_music()
		start_requested.emit()
		queue_free()
	)
	content.add_child(start_button)

	var help_button := _icon_button("游戏帮助", "icon_help", Vector2(176, 176))
	primary_help_button = help_button
	help_button.pressed.connect(func() -> void:
		AudioManager.play_sfx_first(["button_help", "refresh"], -4.0)
		help_modal_blocker.visible = true
		help_panel.visible = true
		help_close_button.visible = true
		_move_tutorial_ring(primary_start_button)
		help_panel.modulate.a = 0.0
		help_panel.scale = Vector2(0.96, 0.96)
		help_panel.pivot_offset = help_panel.size * 0.5
		var help_reveal := create_tween().set_parallel(true)
		help_reveal.tween_property(help_panel, "modulate:a", 1.0, 0.2)
		help_reveal.tween_property(help_panel, "scale", Vector2.ONE, 0.24)
	)
	content.add_child(help_button)
	_move_tutorial_ring(primary_help_button)

	var left_footer := HBoxContainer.new()
	left_footer.position = Vector2(60, 875)
	left_footer.add_theme_constant_override("separation", 14)
	add_child(left_footer)
	_add_home_page_button(left_footer, "本地统计", "button_home_stats", "icon_stats", "stats")
	_add_home_page_button(left_footer, "本地排行", "button_home_leaderboard", "icon_leaderboard", "leaderboard")

	var center_footer := HBoxContainer.new()
	center_footer.position = Vector2(860, 875)
	center_footer.add_theme_constant_override("separation", 14)
	add_child(center_footer)
	_add_home_page_button(center_footer, "设置", "button_settings", "icon_settings", "settings")

	_add_home_quit_button(center_footer)

	var right_footer := HBoxContainer.new()
	right_footer.position = Vector2(1660, 875)
	right_footer.add_theme_constant_override("separation", 14)
	add_child(right_footer)
	_add_home_page_button(right_footer, "图鉴", "button_home_codex", "icon_codex", "codex")
	_add_home_page_button(right_footer, "存档", "button_home_planet", "icon_planet", "planet")



func _icon_button(
	tooltip: String,
	icon_key: String,
	button_size: Vector2,
	fallback_icon_key: String = ""
) -> Button:
	var button := Button.new()
	button.text = tooltip
	button.tooltip_text = tooltip
	button.custom_minimum_size = button_size
	var resolved_icon := icon_key if AssetCatalog.texture(icon_key) else fallback_icon_key
	AssetCatalog.apply_button_visual(button, resolved_icon, true)
	return button


func _add_home_page_button(
	parent: Control,
	tooltip: String,
	icon_key: String,
	fallback_key: String,
	page: String
) -> void:
	var button := _icon_button(tooltip, icon_key, Vector2(92, 92), fallback_key)
	button.pressed.connect(_show_home_page.bind(page))
	parent.add_child(button)


func _add_home_quit_button(parent: Control) -> void:
	var button := _icon_button("退出游戏", "button_main_menu", Vector2(92, 92), "icon_menu")
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx_first(["button_help", "refresh"], -4.0)
		get_tree().quit()
	)
	parent.add_child(button)


func _create_home_overlay() -> void:
	home_modal_blocker = ColorRect.new()
	home_modal_blocker.visible = false
	home_modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_modal_blocker.color = Color(0, 0, 0, 0.28)
	home_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	home_modal_blocker.z_index = 19
	add_child(home_modal_blocker)
	home_overlay = PanelContainer.new()
	home_overlay.visible = false
	home_overlay.position = Vector2(490, 100)
	home_overlay.size = Vector2(940, 800)
	home_overlay.z_index = 20
	AssetCatalog.apply_panel_background(home_overlay, "stats_background")
	add_child(home_overlay)


func _show_home_page(page: String) -> void:
	if is_instance_valid(home_close_button):
		home_close_button.queue_free()
	for child in home_overlay.get_children():
		child.queue_free()
	var readability := ColorRect.new()
	readability.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	readability.color = Color(0, 0, 0, 0)
	readability.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_overlay.add_child(readability)
	var safe_area := MarginContainer.new()
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var left_margin := 138 if page == "codex" else (132 if page == "planet" else 92)
	var right_margin := 138 if page == "codex" else (70 if page == "planet" else 92)
	safe_area.add_theme_constant_override("margin_left", left_margin)
	safe_area.add_theme_constant_override("margin_right", right_margin)
	safe_area.add_theme_constant_override("margin_top", 70 if page == "codex" else 94)
	safe_area.add_theme_constant_override("margin_bottom", 84)
	home_overlay.add_child(safe_area)
	var root := VBoxContainer.new()
	root.alignment = (
		BoxContainer.ALIGNMENT_BEGIN
		if page == "codex"
		else BoxContainer.ALIGNMENT_CENTER
	)
	root.add_theme_constant_override("separation", 14)
	safe_area.add_child(root)
	var background_key := "stats_background" if page == "leaderboard" else "%s_background" % page
	AssetCatalog.apply_panel_background(home_overlay, background_key)
	match page:
		"stats": _build_stats_page(root)
		"leaderboard": _build_leaderboard_page(root)
		"planet": _build_planet_page(root)
		"settings": _build_home_settings_page(root)
		"codex": _build_codex_page(root)
	var close := Button.new()
	close.text = "返回"
	close.position = Vector2(1600, 20)
	close.size = Vector2(96, 96)
	close.custom_minimum_size = Vector2(96, 96)
	close.z_index = 22
	close.pressed.connect(func() -> void:
		home_overlay.visible = false
		home_modal_blocker.visible = false
		if is_instance_valid(home_close_button):
			home_close_button.queue_free()
	)
	AssetCatalog.apply_button_visual(
		close,
		"button_back" if AssetCatalog.texture("button_back") else "icon_menu",
		AssetCatalog.texture("button_back") != null
	)
	add_child(close)
	home_close_button = close
	home_modal_blocker.visible = true
	home_overlay.visible = true
	home_overlay.modulate.a = 0.0
	home_overlay.scale = Vector2(0.96, 0.96)
	home_overlay.pivot_offset = home_overlay.size * 0.5
	var reveal := create_tween().set_parallel(true)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(home_overlay, "modulate:a", 1.0, 0.2)
	reveal.tween_property(home_overlay, "scale", Vector2.ONE, 0.24)


func _move_tutorial_ring(button: Button) -> void:
	if is_instance_valid(tutorial_ring):
		tutorial_ring.queue_free()
	tutorial_ring = AttentionRingScript.new()
	tutorial_ring.position = Vector2(-14, -14)
	tutorial_ring.size = button.custom_minimum_size + Vector2(28, 28)
	tutorial_ring.z_index = -1
	button.add_child(tutorial_ring)


func _page_title(parent: VBoxContainer, text: String) -> void:
	var title := Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("4a2d18"))
	parent.add_child(title)


func _build_stats_page(parent: VBoxContainer) -> void:
	_page_title(parent, "本地数据统计")
	var label := Label.new()
	label.text = (
		"已完成地图面：%d / %d\n"
		+ "本次累计击杀：%d\n累计资源神产出：%.2f\n"
		+ "累计污染：%d\n累计崩塌：%d\n累计刷新：%d"
	) % [
		ProgressManager.completed_maps,
		ProgressManager.MAX_MAPS,
		int(ProgressManager.lifetime_stats.get("enemy_killed", 0)),
		float(ProgressManager.lifetime_stats.get("resource_income_total", 0.0)),
		int(ProgressManager.lifetime_stats.get("pollution_events", 0)),
		int(ProgressManager.lifetime_stats.get("collapsed_cells", 0)),
		int(ProgressManager.lifetime_stats.get("shop_refreshes", 0)),
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("4b2d1a"))
	parent.add_child(label)


func _build_leaderboard_page(parent: VBoxContainer) -> void:
	_page_title(parent, "本地排行榜")
	var text: Array[String] = []
	for index in range(1, ProgressManager.MAX_MAPS + 1):
		var record: Dictionary = ProgressManager.records.get("map_%d" % index, {})
		text.append("图%d　最高分 %d　最快 %.1f 秒" % [
			index,
			int(record.get("highest_score", 0)),
			float(record.get("fastest_time", 0.0)),
		])
	var label := Label.new()
	label.text = "\n".join(text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color("4b2d1a"))
	parent.add_child(label)


func _build_planet_page(parent: VBoxContainer) -> void:
	_page_title(parent, "??")
	var save_heading := parent.get_child(parent.get_child_count() - 1) as Label
	save_heading.add_theme_color_override("font_color", Color("f4dfb1"))
	save_heading.add_theme_color_override("font_outline_color", Color(0.06, 0.035, 0.025, 0.96))
	save_heading.add_theme_constant_override("outline_size", 5)

	var intro := Label.new()
	intro.text = "??????????????????????????"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 17)
	intro.add_theme_color_override("font_color", Color("ead6ab"))
	intro.add_theme_color_override("font_outline_color", Color(0.04, 0.025, 0.02, 0.96))
	intro.add_theme_constant_override("outline_size", 4)
	parent.add_child(intro)

	var summary := Label.new()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 18)
	summary.add_theme_color_override("font_color", Color("f2ddb0"))
	summary.add_theme_color_override("font_outline_color", Color(0.04, 0.025, 0.02, 0.96))
	summary.add_theme_constant_override("outline_size", 5)
	var checkpoint_text := "?????????" if not ProgressManager.run_checkpoint.is_empty() else "??????????"
	summary.text = "%s
??????%d / %d
?????%d ?" % [
		checkpoint_text,
		ProgressManager.completed_maps,
		ProgressManager.MAX_MAPS,
		ProgressManager.planet_history.size(),
	]
	parent.add_child(summary)

	var list := Label.new()
	list.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_theme_font_size_override("font_size", 15)
	list.add_theme_color_override("font_color", Color("51321d"))
	var lines: Array[String] = []
	for map_index in range(1, ProgressManager.MAX_MAPS + 1):
		var record: Dictionary = ProgressManager.records.get("map_%d" % map_index, {})
		if record.is_empty():
			lines.append("?%d??????" % map_index)
		else:
			lines.append("?%d????? %d??? %.1f ?" % [
				map_index,
				int(record.get("highest_score", 0)),
				float(record.get("fastest_time", 0.0)),
			])
	list.text = "
".join(lines)
	parent.add_child(list)

	if not ProgressManager.run_checkpoint.is_empty():
		var continue_button := Button.new()
		continue_button.text = "??????"
		continue_button.custom_minimum_size = Vector2(190, 48)
		AssetCatalog.apply_button_visual(continue_button)
		continue_button.pressed.connect(func() -> void:
			AudioManager.play_sfx_first(["button_start", "purchase"], -2.0)
			AudioManager.stop_music()
			load_requested.emit()
			queue_free()
		)
		parent.add_child(continue_button)


func _build_home_settings_page(parent: VBoxContainer) -> void:
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(1, 28)
	parent.add_child(top_spacer)
	_page_title(parent, "设置")
	var music := Button.new()
	music.text = "游戏音乐"
	music.custom_minimum_size = Vector2(96, 96)
	var music_key := "icon_music" if AudioManager.music_enabled else "icon_no_music"
	AssetCatalog.apply_button_visual(music, music_key, true)
	music.pressed.connect(func() -> void:
		AudioManager.set_music_enabled(not AudioManager.music_enabled)
		_show_home_page("settings")
	)
	parent.add_child(music)
	var volume_icon := TextureRect.new()
	volume_icon.custom_minimum_size = Vector2(64, 64)
	volume_icon.texture = AssetCatalog.texture("icon_volume")
	volume_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	volume_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	volume_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(volume_icon)
	var volume := HSlider.new()
	volume.custom_minimum_size = Vector2(230, 34)
	volume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volume.min_value = 0.0
	volume.max_value = 100.0
	volume.value = AudioManager.music_volume_percent * 100.0
	volume.value_changed.connect(func(value: float) -> void:
		AudioManager.set_music_volume(value / 100.0)
	)
	parent.add_child(volume)
	var fullscreen := Button.new()
	fullscreen.custom_minimum_size = Vector2(150, 42)
	fullscreen.text = "窗口" if _is_fullscreen() else "全屏"
	AssetCatalog.apply_button_visual(fullscreen)
	fullscreen.pressed.connect(func() -> void:
		_toggle_fullscreen()
		fullscreen.text = "窗口" if _is_fullscreen() else "全屏"
	)
	parent.add_child(fullscreen)
	var quit := Button.new()
	quit.text = "退出到桌面"
	quit.custom_minimum_size = Vector2(150, 42)
	AssetCatalog.apply_button_visual(quit)
	quit.pressed.connect(func() -> void:
		AudioManager.play_sfx_first(["button_help", "refresh"], -4.0)
		get_tree().quit()
	)
	parent.add_child(quit)


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED
		if _is_fullscreen()
		else DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _build_codex_page(parent: VBoxContainer) -> void:
	_page_title(parent, "图鉴")
	var codex_heading := parent.get_child(parent.get_child_count() - 1) as Label
	codex_heading.add_theme_color_override("font_color", Color("f3dfb7"))
	var heading_spacer := Control.new()
	heading_spacer.custom_minimum_size = Vector2(1, 4)
	parent.add_child(heading_spacer)
	var terrains := [
		GameDefinitions.TerrainType.PLAIN,
		GameDefinitions.TerrainType.FOREST,
		GameDefinitions.TerrainType.MOUNTAIN,
		GameDefinitions.TerrainType.RIVER,
	]
	var page_host := Control.new()
	page_host.custom_minimum_size = Vector2(660, 390)
	parent.add_child(page_host)
	var pages: Array[Control] = []
	for terrain in terrains:
		var page := HBoxContainer.new()
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page.add_theme_constant_override("separation", 42)
		page.visible = false
		page_host.add_child(page)
		_build_codex_column(page, terrain, GameDefinitions.DeityType.ATTACK)
		_build_codex_column(page, terrain, GameDefinitions.DeityType.RESOURCE)
		pages.append(page)
	var glossary_page := Control.new()
	glossary_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glossary_page.visible = false
	page_host.add_child(glossary_page)
	var glossary_title := Label.new()
	glossary_title.text = "名词与机制"
	glossary_title.position = Vector2(132, 52)
	glossary_title.size = Vector2(151, 32)
	glossary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	glossary_title.add_theme_font_size_override("font_size", 22)
	glossary_title.add_theme_color_override("font_color", Color("51321d"))
	glossary_page.add_child(glossary_title)
	var left_glossary := Label.new()
	left_glossary.position = Vector2(132, 88)
	left_glossary.size = Vector2(151, 175)
	left_glossary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_glossary.add_theme_font_size_override("font_size", 13)
	left_glossary.add_theme_color_override("font_color", Color("51321d"))
	left_glossary.text = (
		"神域\n上下左右连通的同类地形；一片神域只能拥有一座神祇。\n\n"
		+ "神域面积\n提高攻击神基础伤害，或资源神基础产量。\n\n"
		+ "神域共鸣\n相邻有效神域提供对应地形加成。"
	)
	glossary_page.add_child(left_glossary)
	var right_glossary := Label.new()
	right_glossary.position = Vector2(377, 88)
	right_glossary.size = Vector2(151, 175)
	right_glossary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_glossary.add_theme_font_size_override("font_size", 13)
	right_glossary.add_theme_color_override("font_color", Color("51321d"))
	right_glossary.text = (
		"特殊充能\n普通攻击或生产累计到指定次数后触发特殊能力。\n\n"
		+ "污染\n累积到上限会令地块崩塌。\n\n"
		+ "迁移\n建设阶段在同一神域内移动神祇，并保留全部状态。"
	)
	glossary_page.add_child(right_glossary)
	pages.append(glossary_page)
	var enemy_page := Control.new()
	enemy_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enemy_page.visible = false
	page_host.add_child(enemy_page)
	_build_enemy_codex_page(enemy_page)
	pages.append(enemy_page)
	var navigation_spacer := Control.new()
	navigation_spacer.custom_minimum_size = Vector2(1, 16)
	parent.add_child(navigation_spacer)
	var state := {"index": 0}
	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 22)
	parent.add_child(navigation)
	var previous := Button.new()
	previous.text = "上一页"
	previous.custom_minimum_size = Vector2(104, 40)
	AssetCatalog.apply_button_visual(previous)
	navigation.add_child(previous)
	var page_spacer := Control.new()
	page_spacer.custom_minimum_size = Vector2(64, 40)
	navigation.add_child(page_spacer)
	var next := Button.new()
	next.text = "下一页"
	next.custom_minimum_size = Vector2(104, 40)
	AssetCatalog.apply_button_visual(next)
	navigation.add_child(next)
	var refresh_page := func() -> void:
		for index in range(pages.size()):
			pages[index].visible = index == int(state.index)
		previous.disabled = int(state.index) <= 0
		next.disabled = int(state.index) >= pages.size() - 1
	previous.pressed.connect(func() -> void:
		state.index = maxi(0, int(state.index) - 1)
		refresh_page.call()
	)
	next.pressed.connect(func() -> void:
		state.index = mini(pages.size() - 1, int(state.index) + 1)
		refresh_page.call()
	)
	refresh_page.call()


func _build_enemy_codex_page(parent: Control) -> void:
	var title := Label.new()
	title.text = "敌人类型"
	title.position = Vector2(132, 42)
	title.size = Vector2(420, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("51321d"))
	parent.add_child(title)

	var left := Label.new()
	left.position = Vector2(132, 84)
	left.size = Vector2(230, 235)
	left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_theme_font_size_override("font_size", 13)
	left.add_theme_color_override("font_color", Color("51321d"))
	left.text = (
		"普通敌人：基础侵蚀体，沿路线靠近中央核心。\n\n"
		+ "疾行敌人：生命较低但移动更快，适合用减速和范围攻击拦截。\n\n"
		+ "重甲敌人：生命更高，移动较慢，需要更强火力或更大的神域加成。\n\n"
		+ "远程敌人：接近神祇或核心前就能发起攻击，优先处理。"
	)
	parent.add_child(left)

	var right := Label.new()
	right.position = Vector2(392, 84)
	right.size = Vector2(230, 235)
	right.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_theme_font_size_override("font_size", 13)
	right.add_theme_color_override("font_color", Color("51321d"))
	right.text = (
		"飞行敌人：更少受到地形通行影响，会用更直接的路线压迫核心。\n\n"
		+ "游泳敌人：更适应河流，不会像普通敌人那样明显回避水域。\n\n"
		+ "穿林敌人：更适应森林路线，森林不再能有效拖慢它。\n\n"
		+ "敌方核心：出怪源头。周围被非混沌地形围满后，攻击神祇才会攻击它。"
	)
	parent.add_child(right)


func _build_codex_column(parent: HBoxContainer, terrain: int, role: int) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(288, 335)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(1, 0)
	column.add_child(top_spacer)
	var title := Label.new()
	title.text = str(GameDefinitions.REWORKED_DEITY_FORM_NAMES[terrain][role])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("442612"))
	column.add_child(title)
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(104, 104)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.texture = AssetCatalog.texture(AssetCatalog.deity_texture_key(role, terrain))
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(image)
	var text_margin := MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 76)
	text_margin.add_theme_constant_override("margin_right", 0)
	column.add_child(text_margin)
	var text := Label.new()
	text.custom_minimum_size = Vector2(190, 188)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_color", Color("51321d"))
	text.text = "%s\n\n%s\n\n主动技能：%s" % [
		"普通属性只由升级提高；神域面积达到阈值后解锁主动技能。",
		_codex_bonus_text(terrain, role),
		_codex_large_skill_text(terrain, role),
	]
	text_margin.add_child(text)


func _codex_large_skill_text(terrain: int, role: int) -> String:
	match terrain:
		GameDefinitions.TerrainType.PLAIN:
			return (
				"一望无垠——整片平原暂时成为攻击起点。"
				if role == GameDefinitions.DeityType.ATTACK
				else "一望无垠——整片平原暂时成为治疗起点。"
			)
		GameDefinitions.TerrainType.MOUNTAIN:
			return "地壳隆起——周围合法地形暂时变为山地。"
		GameDefinitions.TerrainType.RIVER:
			return "洪流——河流向外扩展并淹没或重伤敌人。"
		GameDefinitions.TerrainType.FOREST:
			return "迷林徘徊——森林内敌人每步随机改向，撞上硬障碍后反弹。"
	return ""


func _codex_bonus_text(terrain: int, role: int) -> String:
	match terrain:
		GameDefinitions.TerrainType.PLAIN:
			return (
				"疾野神：高速单体攻击。\n邻接山地：同目标连射逐渐增伤。\n邻接河流：同目标连射逐渐加速。\n邻接森林：新目标首击造成三倍伤害。"
				if role == GameDefinitions.DeityType.ATTACK
				else "盎然神：优先治疗生命比例最低的友军。\n邻接山地：治疗附加护盾。\n邻接河流：治疗向附近友军扩散。\n邻接森林：治疗附加短暂减伤。"
			)
		GameDefinitions.TerrainType.FOREST:
			return (
				"蛊郁神：直接攻击并施加持续中毒。\n邻接平原：中毒可以叠层。\n邻接山地：每层毒伤提高。\n邻接河流：中毒敌人死亡时传播毒素。"
				if role == GameDefinitions.DeityType.ATTACK
				else "丰饶神：周期生产神力。\n邻接平原：战斗结束结算有限利息。\n邻接山地：敌人有其他路线时尽量绕开。\n邻接河流：生产时可能获得免费刷新。"
			)
		GameDefinitions.TerrainType.MOUNTAIN:
			return (
				"轰爆神：优先炮击远处或危险目标并造成范围伤害。\n每邻接一种平原、河流或森林神域，爆炸范围扩大一次。"
				if role == GameDefinitions.DeityType.ATTACK
				else "泞滞神：周期攻击并使敌人减速。\n邻接平原：减速叠层后冻结。\n邻接河流：单层减速增强。\n邻接森林：减速同时附加易伤。"
			)
		GameDefinitions.TerrainType.RIVER:
			return (
				"澜沧神：攻击命中后在敌人之间弹射。\n邻接平原：弹射搜索距离增加。\n邻接山地：一次命中分裂到更多敌人。\n邻接森林：总弹射次数增加。"
				if role == GameDefinitions.DeityType.ATTACK
				else "漩涡神：周期吸引附近敌人。\n邻接平原：可能短暂策反普通敌人。\n邻接山地：可能将敌人向外抛离。\n邻接森林：可能使敌人沉默。"
			)
	return ""


func _create_help_panel() -> void:
	help_modal_blocker = ColorRect.new()
	help_modal_blocker.visible = false
	help_modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_modal_blocker.color = Color(0, 0, 0, 0.28)
	help_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	help_modal_blocker.z_index = 9
	add_child(help_modal_blocker)
	help_panel = PanelContainer.new()
	help_panel.visible = false
	help_panel.position = Vector2(390, 70)
	help_panel.size = Vector2(1140, 850)
	help_panel.z_index = 10
	AssetCatalog.apply_panel_background(help_panel, "help_background")
	add_child(help_panel)
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	help_panel.add_child(root)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var close := Button.new()
	close.text = "返回"
	close.position = Vector2(1600, 20)
	close.size = Vector2(96, 96)
	close.custom_minimum_size = Vector2(96, 96)
	close.visible = false
	close.z_index = 12
	close.pressed.connect(func() -> void:
		help_panel.visible = false
		help_modal_blocker.visible = false
		close.visible = false
	)
	AssetCatalog.apply_button_visual(
		close,
		"button_back" if AssetCatalog.texture("button_back") else "icon_menu",
		AssetCatalog.texture("button_back") != null
	)
	add_child(close)
	help_close_button = close


func _add_help_section(parent: VBoxContainer, heading: String, text: String) -> void:
	var label := Label.new()
	label.text = "%s\n%s" % [heading, text]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)


func _add_terrain_row(parent: VBoxContainer, texture_key: String, heading: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(96, 96)
	image.texture = AssetCatalog.texture(texture_key)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(image)
	var label := Label.new()
	label.text = "%s\n%s" % [heading, text]
	label.custom_minimum_size = Vector2(920, 96)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)


func _create_achievements_panel() -> void:
	achievements_panel = PanelContainer.new()
	achievements_panel.visible = false
	achievements_panel.position = Vector2(370, 120)
	achievements_panel.size = Vector2(700, 750)
	achievements_panel.z_index = 11
	add_child(achievements_panel)
	_refresh_achievements()


func _refresh_achievements() -> void:
	if not achievements_panel:
		return
	for child in achievements_panel.get_children():
		child.queue_free()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	achievements_panel.add_child(root)
	var title := Label.new()
	title.text = "本地成就"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)
	for id in GameDefinitions.ACHIEVEMENTS:
		var data: Dictionary = GameDefinitions.ACHIEVEMENTS[id]
		var unlocked := bool(ProgressManager.achievements.get(id, false))
		var label := Label.new()
		label.text = "%s %s\n%s" % [
			"◆" if unlocked else "◇",
			str(data.title),
			str(data.description),
		]
		label.modulate = Color.WHITE if unlocked else Color(0.62, 0.65, 0.7)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(label)
	var close := Button.new()
	close.text = "返回"
	close.pressed.connect(func() -> void: achievements_panel.visible = false)
	AssetCatalog.apply_button_visual(close)
	root.add_child(close)
