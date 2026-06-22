class_name StartScreen
extends Control

signal start_requested

const PlanetCubeViewScript := preload("res://scripts/ui/planet_cube_view.gd")
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
	left_footer.position = Vector2(34, 875)
	left_footer.add_theme_constant_override("separation", 14)
	add_child(left_footer)
	_add_home_page_button(left_footer, "本地统计", "button_home_stats", "icon_stats", "stats")
	_add_home_page_button(left_footer, "本地排行", "button_home_leaderboard", "icon_leaderboard", "leaderboard")

	var center_footer := HBoxContainer.new()
	center_footer.position = Vector2(754, 875)
	add_child(center_footer)
	_add_home_page_button(center_footer, "设置", "button_settings", "icon_settings", "settings")

	var right_footer := HBoxContainer.new()
	right_footer.position = Vector2(1370, 875)
	right_footer.add_theme_constant_override("separation", 14)
	add_child(right_footer)
	_add_home_page_button(right_footer, "图鉴", "button_home_codex", "icon_codex", "codex")
	_add_home_page_button(right_footer, "星球", "button_home_planet", "icon_planet", "planet")



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
	home_overlay.position = Vector2(330, 100)
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
	safe_area.add_theme_constant_override("margin_top", 94)
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
	close.position = Vector2(1480, 20)
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
	_page_title(parent, "形成中的立方星球")
	var planet_heading := parent.get_child(parent.get_child_count() - 1) as Label
	planet_heading.add_theme_color_override("font_color", Color("f4dfb1"))
	planet_heading.add_theme_color_override("font_outline_color", Color(0.06, 0.035, 0.025, 0.96))
	planet_heading.add_theme_constant_override("outline_size", 5)
	var planets: Array = ProgressManager.planet_history.duplicate(true)
	var current_faces := ProgressManager.current_planet_faces.duplicate(true)
	if current_faces.is_empty():
		for face_index in range(1, ProgressManager.MAX_MAPS + 1):
			var record: Dictionary = ProgressManager.records.get("map_%d" % face_index, {})
			var snapshot: Array = record.get("terrain_snapshot", [])
			if snapshot.size() == 121:
				current_faces[str(face_index)] = snapshot
	planets.append({
		"completed_faces": ProgressManager.completed_maps,
		"faces": current_faces,
		"current": true,
	})
	var state := {"index": planets.size() - 1}
	var cube := PlanetCubeViewScript.new()
	parent.add_child(cube)
	var planet_title := Label.new()
	planet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	planet_title.add_theme_font_size_override("font_size", 18)
	planet_title.add_theme_color_override("font_color", Color("f2ddb0"))
	planet_title.add_theme_color_override("font_outline_color", Color(0.04, 0.025, 0.02, 0.96))
	planet_title.add_theme_constant_override("outline_size", 5)
	parent.add_child(planet_title)
	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 20)
	parent.add_child(navigation)
	var previous := Button.new()
	previous.text = "上一颗"
	previous.custom_minimum_size = Vector2(112, 42)
	AssetCatalog.apply_button_visual(previous)
	navigation.add_child(previous)
	var next := Button.new()
	next.text = "下一颗"
	next.custom_minimum_size = Vector2(112, 42)
	AssetCatalog.apply_button_visual(next)
	navigation.add_child(next)
	var refresh_planet := func() -> void:
		var planet: Dictionary = planets[int(state.index)]
		var face_dictionary: Dictionary = planet.get("faces", {})
		var faces: Array = []
		for face_index in range(1, ProgressManager.MAX_MAPS + 1):
			faces.append(face_dictionary.get(str(face_index), []))
		cube.set_snapshots(faces)
		var current_suffix := "（当前）" if bool(planet.get("current", false)) else ""
		planet_title.text = "星球 %d / %d%s　已完成 %d 面" % [
			int(state.index) + 1,
			planets.size(),
			current_suffix,
			int(planet.get("completed_faces", 0)),
		]
		previous.disabled = int(state.index) <= 0
		next.disabled = int(state.index) >= planets.size() - 1
	previous.pressed.connect(func() -> void:
		state.index = maxi(0, int(state.index) - 1)
		refresh_planet.call()
	)
	next.pressed.connect(func() -> void:
		state.index = mini(planets.size() - 1, int(state.index) + 1)
		refresh_planet.call()
	)
	refresh_planet.call()
	var hint := Label.new()
	hint.text = "拖动立方体旋转；完成的地图会成为星球表面。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color("ead6ab"))
	hint.add_theme_color_override("font_outline_color", Color(0.04, 0.025, 0.02, 0.96))
	hint.add_theme_constant_override("outline_size", 4)
	parent.add_child(hint)
	var status := Label.new()
	status.text = "六面已闭合，星球形成。" if ProgressManager.completed_maps >= 6 else "完成六张地图后形成完整立方星球。"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", Color("ead6ab"))
	status.add_theme_color_override("font_outline_color", Color(0.04, 0.025, 0.02, 0.96))
	status.add_theme_constant_override("outline_size", 4)
	parent.add_child(status)


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


func _build_codex_page(parent: VBoxContainer) -> void:
	_page_title(parent, "图鉴")
	var codex_heading := parent.get_child(parent.get_child_count() - 1) as Label
	codex_heading.add_theme_color_override("font_color", Color("f3dfb7"))
	var heading_spacer := Control.new()
	heading_spacer.custom_minimum_size = Vector2(1, 16)
	parent.add_child(heading_spacer)
	var terrains := [
		GameDefinitions.TerrainType.PLAIN,
		GameDefinitions.TerrainType.FOREST,
		GameDefinitions.TerrainType.MOUNTAIN,
		GameDefinitions.TerrainType.RIVER,
	]
	var page_host := Control.new()
	page_host.custom_minimum_size = Vector2(660, 350)
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


func _build_codex_column(parent: HBoxContainer, terrain: int, role: int) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(288, 335)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(1, 8)
	column.add_child(top_spacer)
	var title := Label.new()
	title.text = str(GameDefinitions.DEITY_FORM_NAMES[terrain][role])
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
	text_margin.add_theme_constant_override("margin_left", 52)
	text_margin.add_theme_constant_override("margin_right", 6)
	column.add_child(text_margin)
	var text := Label.new()
	text.custom_minimum_size = Vector2(218, 188)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_color", Color("51321d"))
	text.text = "%s\n\n%s\n\n迁移：建设阶段可在同一神域内移动并保留状态。" % [
		"神域面积提高基础伤害。" if role == GameDefinitions.DeityType.ATTACK else "神域面积提高基础神力产量。",
		_codex_bonus_text(terrain, role),
	]
	text_margin.add_child(text)


func _codex_bonus_text(terrain: int, role: int) -> String:
	match terrain:
		GameDefinitions.TerrainType.PLAIN:
			return (
				"功能：快速直线攻击；特殊攻击进行连续射击。\n共鸣：相邻且拥有存活神祇、面积至少 2 格的平原神域，使基础攻击间隔缩短。"
				if role == GameDefinitions.DeityType.ATTACK
				else "功能：基础生产较快；特殊生产额外进行一次基础生产。\n共鸣：相邻有效平原神域使基础生产间隔缩短。"
			)
		GameDefinitions.TerrainType.FOREST:
			return (
				"功能：追踪攻击并减速；特殊攻击强化减速并自愈一次。\n共鸣：相邻有效森林神域提高最大生命、治疗与护盾效果。"
				if role == GameDefinitions.DeityType.ATTACK
				else "功能：特殊生产释放生命绽放，治疗相邻神域神祇，溢出治疗转为有限护盾。\n共鸣：相邻有效森林神域提高最大生命、治疗与护盾效果。"
			)
		GameDefinitions.TerrainType.MOUNTAIN:
			return (
				"功能：优先炮击射程内最远目标，危险敌人优先；抛物线弹道并造成溅射。\n共鸣：相邻有效山地神域提高攻击射程。"
				if role == GameDefinitions.DeityType.ATTACK
				else "功能：生产较慢、单次产量较高；特殊生产获得额外神力。\n共鸣：相邻有效山地神域提高单次基础产量。"
			)
		GameDefinitions.TerrainType.RIVER:
			return (
				"功能：攻击弹射；特殊攻击增加弹射次数。\n共鸣：相邻有效河流神域减少特殊攻击所需普通攻击次数。"
				if role == GameDefinitions.DeityType.ATTACK
				else "功能：特殊生产获得一次免费商店刷新。\n共鸣：相邻有效河流神域减少特殊生产所需次数；不再返还建造神力。"
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
	help_panel.position = Vector2(230, 70)
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
	close.position = Vector2(1480, 20)
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
