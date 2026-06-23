extends Node

# 所有正式素材路径集中在这里。文件缺失时返回 null，由表现层继续使用程序绘制占位。
const TEXTURE_PATHS := {
	"terrain_plain": "res://assets/art/terrain/terrain_plain.png",
	"terrain_forest": "res://assets/art/terrain/terrain_forest.png",
	"terrain_mountain": "res://assets/art/terrain/terrain_mountain.png",
	"terrain_river": "res://assets/art/terrain/terrain_river.png",
	"terrain_void": "res://assets/art/terrain/terrain_void.png",
	"terrain_pollution": "res://assets/art/terrain/terrain_pollution_overlay.png",
	"pollution_stage_1": "res://assets/art/terrain/terrain_pollution_stage_1.png",
	"pollution_stage_2": "res://assets/art/terrain/terrain_pollution_stage_2.png",
	"preview_valid": "res://assets/art/effects/preview_valid.png",
	"preview_invalid": "res://assets/art/effects/preview_invalid.png",
	"deity_attack_plain": "res://assets/art/deities/attack/deity_attack_plain.png",
	"deity_attack_forest": "res://assets/art/deities/attack/deity_attack_forest.png",
	"deity_attack_mountain": "res://assets/art/deities/attack/deity_attack_mountain.png",
	"deity_attack_river": "res://assets/art/deities/attack/deity_attack_river.png",
	"deity_resource_plain": "res://assets/art/deities/resource/deity_resource_plain.png",
	"deity_resource_forest": "res://assets/art/deities/resource/deity_resource_forest.png",
	"deity_resource_mountain": "res://assets/art/deities/resource/deity_resource_mountain.png",
	"deity_resource_river": "res://assets/art/deities/resource/deity_resource_river.png",
	"enemy_default": "res://assets/art/enemies/enemy_default.png",
	"enemy_core": "res://assets/art/enemies/enemy_core.png",
	"enemy_core_explosion": "res://assets/art/enemies/enemy_core_explosion.png",
	"enemy_spawn_warning": "res://assets/art/enemies/enemy_spawn_warning.png",
	"core": "res://assets/art/core/core.png",
	"card_frame_terrain": "res://assets/art/cards/card_frame_terrain.png",
	"card_art_plain": "res://assets/art/cards/card_art_plain.png",
	"card_art_forest": "res://assets/art/cards/card_art_forest.png",
	"card_art_mountain": "res://assets/art/cards/card_art_mountain.png",
	"card_art_river": "res://assets/art/cards/card_art_river.png",
	"projectile_default": "res://assets/art/effects/projectile_default.png",
	"hit_default": "res://assets/art/effects/hit_default.png",
	"projectile_deity_plain": "res://assets/art/effects/projectile_deity_plain.png",
	"projectile_deity_forest": "res://assets/art/effects/projectile_deity_forest.png",
	"projectile_deity_mountain": "res://assets/art/effects/projectile_deity_mountain.png",
	"projectile_deity_river": "res://assets/art/effects/projectile_deity_river.png",
	"projectile_enemy": "res://assets/art/effects/projectile_enemy.png",
	"projectile_deity_mountain_splash": "res://assets/art/effects/projectile_deity_mountain_splash.png",
	"projectile_deity_river_chain": "res://assets/art/effects/projectile_deity_river_chain.png",
	"hit_deity_plain": "res://assets/art/effects/hit_deity_plain.png",
	"hit_deity_forest": "res://assets/art/effects/hit_deity_forest.png",
	"hit_deity_mountain": "res://assets/art/effects/hit_deity_mountain.png",
	"hit_deity_river": "res://assets/art/effects/hit_deity_river.png",
	"hit_enemy": "res://assets/art/effects/hit_enemy.png",
	"hit_deity_mountain_splash": "res://assets/art/effects/hit_deity_mountain_splash.png",
	"hit_deity_river_chain": "res://assets/art/effects/hit_deity_river_chain.png",
	"status_deity_forest_slow": "res://assets/art/effects/status_deity_forest_slow.png",
	"muzzle_deity_plain": "res://assets/art/effects/muzzle_deity_plain.png",
	"muzzle_deity_forest": "res://assets/art/effects/muzzle_deity_forest.png",
	"muzzle_deity_mountain": "res://assets/art/effects/muzzle_deity_mountain.png",
	"muzzle_deity_river": "res://assets/art/effects/muzzle_deity_river.png",
	"muzzle_enemy": "res://assets/art/effects/muzzle_enemy.png",
	"pollution_growth": "res://assets/art/effects/pollution_growth.png",
	"cell_collapse": "res://assets/art/effects/cell_collapse.png",
	"icon_divine_power": "res://assets/art/ui/icon_divine_power.png",
	"icon_core_hp": "res://assets/art/ui/icon_core_hp.png",
	"icon_refresh": "res://assets/art/ui/icon_refresh.png",
	"icon_move": "res://assets/art/ui/icon_move.png",
	"icon_remove": "res://assets/art/ui/icon_remove.png",
	"action_upgrade": "res://assets/art/ui/upgrade.png",
	"action_move": "res://assets/art/ui/move.png",
	"action_remove": "res://assets/art/ui/remove.png",
	"icon_lock": "res://assets/art/ui/icon_lock.png",
	"icon_unlock": "res://assets/art/ui/icon_unlock.png",
	"icon_time_flow": "res://assets/art/ui/icon_time_flow.png",
	"icon_start": "res://assets/art/ui/icon_start.png",
	"icon_help": "res://assets/art/ui/icon_help.png",
	"icon_attack_deity": "res://assets/art/ui/icon_attack_deity.png",
	"icon_resource_deity": "res://assets/art/ui/icon_resource_deity.png",
	"icon_damage": "res://assets/art/ui/icon_damage.png",
	"icon_price": "res://assets/art/ui/icon_price.png",
	"icon_range": "res://assets/art/ui/icon_range.png",
	"icon_speed": "res://assets/art/ui/icon_speed.png",
	"icon_production": "res://assets/art/ui/icon_production.png",
	"icon_level": "res://assets/art/ui/icon_level.png",
	"icon_attack": "res://assets/art/ui/icon_attack.png",
	"icon_pollution": "res://assets/art/ui/icon_pollution.png",
	"icon_map_fill": "res://assets/art/ui/icon_map_fill.png",
	"icon_enemy_core": "res://assets/art/ui/icon_enemy_core.png",
	"icon_victory": "res://assets/art/ui/icon_victory.png",
	"icon_menu": "res://assets/art/ui/icon_menu.png",
	"icon_stats": "res://assets/art/ui/icon_stats.png",
	"icon_leaderboard": "res://assets/art/ui/icon_leaderboard.png",
	"icon_planet": "res://assets/art/ui/icon_planet.png",
	"icon_settings": "res://assets/art/ui/icon_settings.png",
	"icon_codex": "res://assets/art/ui/icon_codex.png",
	"icon_cheat": "res://assets/art/ui/icon_cheat.png",
	"icon_map_1": "res://assets/art/ui/icon_map_1.png",
	"icon_map_2": "res://assets/art/ui/icon_map_2.png",
	"icon_map_3": "res://assets/art/ui/icon_map_3.png",
	"icon_map_4": "res://assets/art/ui/icon_map_4.png",
	"icon_map_5": "res://assets/art/ui/icon_map_5.png",
	"icon_map_6": "res://assets/art/ui/icon_map_6.png",
	"shop_slot_empty": "res://assets/art/ui/shop_slot_empty.png",
	"button_normal": "res://assets/art/ui/button_normal.png",
	"button_hover": "res://assets/art/ui/button_hover.png",
	"button_pressed": "res://assets/art/ui/button_pressed.png",
	"button_disabled": "res://assets/art/ui/button_disabled.png",
	"map_frame": "res://assets/art/ui/map_frame.png",
	"game_background": "res://assets/art/ui/game_background.png",
	"menu_background": "res://assets/art/ui/menu_background.png",
	"game_title": "res://assets/art/ui/game_title.png",
	"help_background": "res://assets/art/ui/help_background.png",
	"stats_background": "res://assets/art/ui/stats_background.png",
	"leaderboard_background": "res://assets/art/ui/leaderboard_background.png",
	"planet_background": "res://assets/art/ui/planet_background.png",
	"codex_background": "res://assets/art/ui/codex_background.png",
	"settings_background": "res://assets/art/ui/settings_background.png",
	"result_background": "res://assets/art/ui/result_background.png",
	"failure_background": "res://assets/art/ui/failure_background.png",
	"blessing_background": "res://assets/art/ui/blessing_background.png",
	"button_home_start": "res://assets/art/ui/button_home_start.png",
	"button_home_help": "res://assets/art/ui/button_home_help.png",
	"button_home_stats": "res://assets/art/ui/button_home_stats.png",
	"button_home_leaderboard": "res://assets/art/ui/button_home_leaderboard.png",
	"button_home_planet": "res://assets/art/ui/button_home_planet.png",
	"button_home_codex": "res://assets/art/ui/button_home_codex.png",
	"button_settings": "res://assets/art/ui/button_settings.png",
	"button_back": "res://assets/art/ui/button_back.png",
	"button_main_menu": "res://assets/art/ui/button_main_menu.png",
	"button_quit": "res://assets/art/ui/quit.png",
	"button_continue": "res://assets/art/ui/button_continue.png",
	"button_blessing_1": "res://assets/art/ui/button_blessing_1.png",
	"button_blessing_2": "res://assets/art/ui/button_blessing_2.png",
	"button_blessing_3": "res://assets/art/ui/button_blessing_3.png",
	"icon_music": "res://assets/art/ui/music.png",
	"icon_no_music": "res://assets/art/ui/nomusic.png",
	"icon_volume": "res://assets/art/ui/volumn.png",
	"board": "res://assets/art/ui/board.png",
}

const FONT_PATH := "res://assets/fonts/game_font.ttf"

const AUDIO_PATHS := {
	"purchase": "res://assets/audio/sfx/sfx_purchase.ogg",
	"place": "res://assets/audio/sfx/sfx_place.ogg",
	"refresh": "res://assets/audio/sfx/sfx_refresh.ogg",
	"attack": "res://assets/audio/sfx/sfx_attack.ogg",
	"hit": "res://assets/audio/sfx/sfx_hit.ogg",
	"resource_produce": "res://assets/audio/sfx/sfx_resource_produce.ogg",
	"enemy_death": "res://assets/audio/sfx/sfx_enemy_death.ogg",
	"pollution_growth": "res://assets/audio/sfx/sfx_pollution_growth.ogg",
	"cell_collapse": "res://assets/audio/sfx/sfx_cell_collapse.ogg",
	"phase_build": "res://assets/audio/sfx/sfx_phase_build.ogg",
	"phase_combat": "res://assets/audio/sfx/sfx_phase_combat.ogg",
	"place_terrain_plain": "res://assets/audio/sfx/sfx_place_terrain_plain.ogg",
	"place_terrain_forest": "res://assets/audio/sfx/sfx_place_terrain_forest.ogg",
	"place_terrain_mountain": "res://assets/audio/sfx/sfx_place_terrain_mountain.ogg",
	"place_terrain_river": "res://assets/audio/sfx/sfx_place_terrain_river.ogg",
	"place_deity_attack_plain": "res://assets/audio/sfx/sfx_place_deity_attack_plain.ogg",
	"place_deity_attack_forest": "res://assets/audio/sfx/sfx_place_deity_attack_forest.ogg",
	"place_deity_attack_mountain": "res://assets/audio/sfx/sfx_place_deity_attack_mountain.ogg",
	"place_deity_attack_river": "res://assets/audio/sfx/sfx_place_deity_attack_river.ogg",
	"place_deity_resource_plain": "res://assets/audio/sfx/sfx_place_deity_resource_plain.ogg",
	"place_deity_resource_forest": "res://assets/audio/sfx/sfx_place_deity_resource_forest.ogg",
	"place_deity_resource_mountain": "res://assets/audio/sfx/sfx_place_deity_resource_mountain.ogg",
	"place_deity_resource_river": "res://assets/audio/sfx/sfx_place_deity_resource_river.ogg",
	"attack_deity_plain": "res://assets/audio/sfx/sfx_attack_deity_plain.ogg",
	"attack_deity_forest": "res://assets/audio/sfx/sfx_attack_deity_forest.ogg",
	"attack_deity_mountain": "res://assets/audio/sfx/sfx_attack_deity_mountain.ogg",
	"attack_deity_river": "res://assets/audio/sfx/sfx_attack_deity_river.ogg",
	"produce_deity_plain": "res://assets/audio/sfx/sfx_produce_deity_plain.ogg",
	"produce_deity_forest": "res://assets/audio/sfx/sfx_produce_deity_forest.ogg",
	"produce_deity_mountain": "res://assets/audio/sfx/sfx_produce_deity_mountain.ogg",
	"produce_deity_river": "res://assets/audio/sfx/sfx_produce_deity_river.ogg",
	"button_start": "res://assets/audio/sfx/sfx_button_start.ogg",
	"button_help": "res://assets/audio/sfx/sfx_button_help.ogg",
	"button_time_flow": "res://assets/audio/sfx/sfx_button_time_flow.ogg",
	"button_refresh": "res://assets/audio/sfx/sfx_button_refresh.ogg",
	"button_lock": "res://assets/audio/sfx/sfx_button_lock.ogg",
	"button_unlock": "res://assets/audio/sfx/sfx_button_unlock.ogg",
	"button_card_purchase": "res://assets/audio/sfx/sfx_button_card_purchase.ogg",
	"button_hover": "res://assets/audio/sfx/sfx_button_hover.ogg",
	"enemy_death_1": "res://assets/audio/sfx/sfx_enemy_death_1.ogg",
	"enemy_death_2": "res://assets/audio/sfx/sfx_enemy_death_2.ogg",
	"enemy_death_3": "res://assets/audio/sfx/sfx_enemy_death_3.ogg",
	"enemy_death_4": "res://assets/audio/sfx/sfx_enemy_death_4.ogg",
	"enemy_death_5": "res://assets/audio/sfx/sfx_enemy_death_5.ogg",
	"enemy_death_6": "res://assets/audio/sfx/sfx_enemy_death_6.ogg",
	"enemy_death_7": "res://assets/audio/sfx/sfx_enemy_death_7.ogg",
	"music_menu": "res://assets/audio/music/music_menu.ogg",
	"music_build": "res://assets/audio/music/music_build.ogg",
	"music_combat": "res://assets/audio/music/music_combat.ogg",
}

const ANIMATION_PATHS := {
	"deity_attack_plain": "res://assets/animations/deities/attack/deity_attack_plain_frames.tres",
	"deity_attack_forest": "res://assets/animations/deities/attack/deity_attack_forest_frames.tres",
	"deity_attack_mountain": "res://assets/animations/deities/attack/deity_attack_mountain_frames.tres",
	"deity_attack_river": "res://assets/animations/deities/attack/deity_attack_river_frames.tres",
	"deity_resource_plain": "res://assets/animations/deities/resource/deity_resource_plain_frames.tres",
	"deity_resource_forest": "res://assets/animations/deities/resource/deity_resource_forest_frames.tres",
	"deity_resource_mountain": "res://assets/animations/deities/resource/deity_resource_mountain_frames.tres",
	"deity_resource_river": "res://assets/animations/deities/resource/deity_resource_river_frames.tres",
	"enemy_default": "res://assets/animations/enemies/enemy_default_frames.tres",
	"enemy_core": "res://assets/animations/enemies/enemy_core_frames.tres",
	"enemy_core_explosion": "res://assets/animations/effects/enemy_core_explosion_frames.tres",
	"enemy_spawn_warning": "res://assets/animations/effects/enemy_spawn_warning_frames.tres",
	"core": "res://assets/animations/core/core_frames.tres",
	"pollution_growth": "res://assets/animations/effects/pollution_growth_frames.tres",
	"pollution_stage_1": "res://assets/animations/effects/pollution_stage_1_frames.tres",
	"pollution_stage_2": "res://assets/animations/effects/pollution_stage_2_frames.tres",
	"projectile_deity_plain": "res://assets/animations/effects/projectile_deity_plain_frames.tres",
	"projectile_deity_forest": "res://assets/animations/effects/projectile_deity_forest_frames.tres",
	"projectile_deity_mountain": "res://assets/animations/effects/projectile_deity_mountain_frames.tres",
	"projectile_deity_river": "res://assets/animations/effects/projectile_deity_river_frames.tres",
	"projectile_enemy": "res://assets/animations/effects/projectile_enemy_frames.tres",
	"projectile_deity_mountain_splash": "res://assets/animations/effects/projectile_deity_mountain_splash_frames.tres",
	"projectile_deity_river_chain": "res://assets/animations/effects/projectile_deity_river_chain_frames.tres",
	"hit_deity_plain": "res://assets/animations/effects/hit_deity_plain_frames.tres",
	"hit_deity_forest": "res://assets/animations/effects/hit_deity_forest_frames.tres",
	"hit_deity_mountain": "res://assets/animations/effects/hit_deity_mountain_frames.tres",
	"hit_deity_river": "res://assets/animations/effects/hit_deity_river_frames.tres",
	"hit_enemy": "res://assets/animations/effects/hit_enemy_frames.tres",
	"hit_deity_mountain_splash": "res://assets/animations/effects/hit_deity_mountain_splash_frames.tres",
	"hit_deity_river_chain": "res://assets/animations/effects/hit_deity_river_chain_frames.tres",
	"status_deity_forest_slow": "res://assets/animations/effects/status_deity_forest_slow_frames.tres",
	"muzzle_deity_plain": "res://assets/animations/effects/muzzle_deity_plain_frames.tres",
	"muzzle_deity_forest": "res://assets/animations/effects/muzzle_deity_forest_frames.tres",
	"muzzle_deity_mountain": "res://assets/animations/effects/muzzle_deity_mountain_frames.tres",
	"muzzle_deity_river": "res://assets/animations/effects/muzzle_deity_river_frames.tres",
	"muzzle_enemy": "res://assets/animations/effects/muzzle_enemy_frames.tres",
	"cell_collapse": "res://assets/animations/effects/cell_collapse_frames.tres",
	"terrain_void": "res://assets/animations/terrain/terrain_void_frames.tres",
	"icon_core_hp": "res://assets/animations/ui/icon_core_hp_frames.tres",
	"icon_divine_power": "res://assets/animations/ui/icon_divine_power_frames.tres",
	"map_frame": "res://assets/animations/ui/map_frame_frames.tres",
	"game_background": "res://assets/animations/ui/game_background_frames.tres",
}

var _texture_cache: Dictionary = {}
var _audio_cache: Dictionary = {}
var _animation_cache: Dictionary = {}
var _interface_theme: Theme


func texture(key: String) -> Texture2D:
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D
	var path := str(TEXTURE_PATHS.get(key, ""))
	var result: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		result = load(path) as Texture2D
	_texture_cache[key] = result
	return result


func texture_or(key: String, fallback_key: String) -> Texture2D:
	var result := texture(key)
	return result if result else texture(fallback_key)


func interface_theme() -> Theme:
	if _interface_theme:
		return _interface_theme
	var result := Theme.new()
	if ResourceLoader.exists(FONT_PATH):
		result.default_font = load(FONT_PATH) as Font
	result.default_font_size = 18
	_interface_theme = result
	return result


func audio(key: String) -> AudioStream:
	if _audio_cache.has(key):
		return _audio_cache[key] as AudioStream
	var path := str(AUDIO_PATHS.get(key, ""))
	var result: AudioStream = null
	if not path.is_empty() and ResourceLoader.exists(path):
		result = load(path) as AudioStream
	_audio_cache[key] = result
	return result


func animation(key: String) -> SpriteFrames:
	if _animation_cache.has(key):
		return _animation_cache[key] as SpriteFrames
	var path := str(ANIMATION_PATHS.get(key, ""))
	var result: SpriteFrames = null
	if not path.is_empty() and ResourceLoader.exists(path):
		result = load(path) as SpriteFrames
	_animation_cache[key] = result
	return result


func terrain_texture_key(terrain: int) -> String:
	match terrain:
		GameDefinitions.TerrainType.PLAIN: return "terrain_plain"
		GameDefinitions.TerrainType.FOREST: return "terrain_forest"
		GameDefinitions.TerrainType.MOUNTAIN: return "terrain_mountain"
		GameDefinitions.TerrainType.RIVER: return "terrain_river"
		_: return "terrain_void"


func card_art_texture_key(terrain: int) -> String:
	match terrain:
		GameDefinitions.TerrainType.PLAIN: return "card_art_plain"
		GameDefinitions.TerrainType.FOREST: return "card_art_forest"
		GameDefinitions.TerrainType.MOUNTAIN: return "card_art_mountain"
		GameDefinitions.TerrainType.RIVER: return "card_art_river"
		_: return ""


func shape_icon_key(shape: Array[Vector2i]) -> String:
	if shape.size() == 1:
		return "shape_single"
	if shape.size() == 2:
		return "shape_domino"
	if shape.size() == 4:
		return "shape_square_four"
	if shape.size() == 3:
		var same_x := shape.all(func(cell: Vector2i) -> bool: return cell.x == shape[0].x)
		var same_y := shape.all(func(cell: Vector2i) -> bool: return cell.y == shape[0].y)
		return "shape_line_three" if same_x or same_y else "shape_l_three"
	return ""


func deity_texture_key(deity_type: int, terrain: int) -> String:
	var role := "attack" if deity_type == GameDefinitions.DeityType.ATTACK else "resource"
	var terrain_name := "plain"
	match terrain:
		GameDefinitions.TerrainType.FOREST: terrain_name = "forest"
		GameDefinitions.TerrainType.MOUNTAIN: terrain_name = "mountain"
		GameDefinitions.TerrainType.RIVER: terrain_name = "river"
	return "deity_%s_%s" % [role, terrain_name]


func terrain_suffix(terrain: int) -> String:
	match terrain:
		GameDefinitions.TerrainType.PLAIN: return "plain"
		GameDefinitions.TerrainType.FOREST: return "forest"
		GameDefinitions.TerrainType.MOUNTAIN: return "mountain"
		GameDefinitions.TerrainType.RIVER: return "river"
		_: return "void"


func apply_button_visual(
	button: Button,
	icon_key: String = "",
	hide_text_with_icon: bool = false,
	icon_only: bool = true
) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 14)
	if not button.has_meta("hover_sfx_connected"):
		button.set_meta("hover_sfx_connected", true)
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				AudioManager.play_sfx("button_hover", -8.0)
		)
	if not button.has_meta("fallback_click_sfx_connected"):
		button.set_meta("fallback_click_sfx_connected", true)
		button.pressed.connect(func() -> void:
			AudioManager.call_deferred("play_button_fallback")
		)
	var icon_texture := texture(icon_key)
	if icon_texture:
		button.icon = icon_texture
		button.expand_icon = true
		if hide_text_with_icon:
			button.tooltip_text = button.text
			button.text = ""
	if hide_text_with_icon and icon_texture and icon_only:
		_apply_icon_button_style(button)
		_apply_alpha_icon_glow(button)
		_connect_button_motion(button)
		return
	var custom_skin_found := false
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := texture("button_%s" % state)
		if not skin:
			continue
		custom_skin_found = true
		var style := StyleBoxTexture.new()
		style.texture = skin
		style.texture_margin_left = 12.0
		style.texture_margin_right = 12.0
		style.texture_margin_top = 12.0
		style.texture_margin_bottom = 12.0
		button.add_theme_stylebox_override(state, style)
	if not custom_skin_found:
		_apply_default_button_glow(button)
	_connect_button_motion(button)


func apply_panel_background(panel: PanelContainer, texture_key: String) -> void:
	var background := texture(texture_key)
	if background:
		var style := StyleBoxTexture.new()
		style.texture = background
		style.texture_margin_left = 24.0
		style.texture_margin_right = 24.0
		style.texture_margin_top = 24.0
		style.texture_margin_bottom = 24.0
		panel.add_theme_stylebox_override("panel", style)
		return
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.055, 0.075, 0.11, 0.97)
	fallback.border_color = Color("657b96")
	fallback.set_border_width_all(2)
	fallback.set_corner_radius_all(12)
	fallback.content_margin_left = 24.0
	fallback.content_margin_right = 24.0
	fallback.content_margin_top = 20.0
	fallback.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", fallback)


func apply_button_background(button: Button, texture_key: String) -> void:
	var background := texture(texture_key)
	if not background:
		apply_button_visual(button)
		return
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = background
		style.texture_margin_left = 28.0
		style.texture_margin_right = 28.0
		style.texture_margin_top = 28.0
		style.texture_margin_bottom = 28.0
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_hover_color", Color("fff2bd"))
	button.add_theme_color_override("font_pressed_color", Color("ffe38a"))
	if not button.has_meta("hover_sfx_connected"):
		button.set_meta("hover_sfx_connected", true)
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				AudioManager.play_sfx("button_hover", -8.0)
		)
	if not button.has_meta("fallback_click_sfx_connected"):
		button.set_meta("fallback_click_sfx_connected", true)
		button.pressed.connect(func() -> void:
			AudioManager.call_deferred("play_button_fallback")
		)
	_connect_button_motion(button)


func _apply_icon_button_style(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_color_override("icon_normal_color", Color(0.82, 0.84, 0.82, 0.92))
	button.add_theme_color_override("icon_hover_color", Color(0.96, 0.95, 0.88))
	button.add_theme_color_override("icon_pressed_color", Color("fff0a8"))
	button.add_theme_color_override("icon_disabled_color", Color(0.55, 0.58, 0.62, 0.6))


func _apply_alpha_icon_glow(button: Button) -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.45, 0.9, 1.0, 0.9);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 px = TEXTURE_PIXEL_SIZE * 3.0;
	float around = 0.0;
	around = max(around, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	around = max(around, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
	around = max(around, texture(TEXTURE, UV + px).a);
	around = max(around, texture(TEXTURE, UV - px).a);
	around = max(around, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	around = max(around, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	float outline = max(0.0, around - base.a) * glow_strength;
	vec3 brightened = base.rgb + glow_color.rgb * outline;
	COLOR = vec4(brightened, max(base.a, outline * glow_color.a));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var idle_glow := 0.48 if button.has_meta("persistent_icon_outline") else 0.0
	material.set_shader_parameter("glow_strength", idle_glow)
	if button.has_meta("persistent_icon_outline"):
		material.set_shader_parameter("glow_color", Color(0.78, 0.9, 0.86, 0.72))
	button.material = material
	button.mouse_entered.connect(func() -> void:
		material.set_shader_parameter("glow_strength", 1.15)
	)
	button.mouse_exited.connect(func() -> void:
		material.set_shader_parameter("glow_strength", idle_glow)
	)
	button.button_down.connect(func() -> void:
		material.set_shader_parameter("glow_strength", 1.65)
		material.set_shader_parameter("glow_color", Color("ffe27a"))
	)
	button.button_up.connect(func() -> void:
		material.set_shader_parameter("glow_strength", 1.15 if button.is_hovered() else idle_glow)
		material.set_shader_parameter("glow_color", Color("73e6ff"))
	)


func _apply_default_button_glow(button: Button) -> void:
	var normal := _make_button_style(
		Color("202936e8"), Color("53677d"), Color(0.05, 0.08, 0.12, 0.72), 5
	)
	var hover := _make_button_style(
		Color("2b3b4fe8"), Color("8fdcff"), Color(0.2, 0.75, 1.0, 0.58), 11
	)
	var pressed := _make_button_style(
		Color("182532f2"), Color("ffe08a"), Color(1.0, 0.72, 0.2, 0.44), 6
	)
	var disabled := _make_button_style(
		Color("1b2028b8"), Color("39424d"), Color(0, 0, 0, 0.35), 3
	)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("edf7ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("fff2bd"))
	button.add_theme_color_override("icon_normal_color", Color("eaf7ff"))
	button.add_theme_color_override("icon_hover_color", Color.WHITE)
	button.add_theme_color_override("icon_pressed_color", Color("fff0ae"))


func _make_button_style(
	background: Color,
	border: Color,
	shadow: Color,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _connect_button_motion(button: Button) -> void:
	if button.has_meta("motion_connected"):
		return
	button.set_meta("motion_connected", true)
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.mouse_entered.connect(func() -> void:
		if button.disabled:
			return
		button.z_index = 20
		button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
			.tween_property(button, "scale", Vector2(1.045, 1.045), 0.12)
	)
	button.mouse_exited.connect(func() -> void:
		button.z_index = 0
		button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
			.tween_property(button, "scale", Vector2.ONE, 0.12)
	)
	button.button_down.connect(func() -> void:
		button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
			.tween_property(button, "scale", Vector2(0.96, 0.96), 0.06)
	)
	button.button_up.connect(func() -> void:
		var target_scale := Vector2(1.045, 1.045) if button.is_hovered() else Vector2.ONE
		button.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.tween_property(button, "scale", target_scale, 0.12)
	)
