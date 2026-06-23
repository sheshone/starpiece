extends Node2D

@onready var grid_map: GameMap = $GameMap
@onready var start_screen: StartScreen = $UICanvas/StartScreen
@onready var game_ui: GameUI = $UICanvas/GameUI
@onready var hand_ui: HandUI = $UICanvas/HandUI
@onready var map_frame: Control = $MapFrameOverlay

var free_refreshes: int = 0
var active_tile_card: TerrainCard
var active_tile_shop_index: int = -1
var built_attack_deities: int = 0
var built_resource_deities: int = 0
var tutorial_step: int = 0


func _ready() -> void:
	GameManager.grid_map_ref = grid_map
	GameManager.scene_root = self
	grid_map.reset_board()
	grid_map.attack_visual_requested.connect(_on_attack_visual_requested)
	grid_map.placement_finished.connect(_on_placement_finished)
	grid_map.map_completed.connect(_on_map_completed)
	grid_map.enemy_core_destroyed.connect(_on_enemy_core_destroyed)
	grid_map.board_changed.connect(_save_checkpoint_if_possible)
	TurnManager.build_started.connect(_on_build_started)
	TurnManager.combat_started.connect(_on_combat_started)
	TurnManager.combat_ended.connect(_on_combat_ended)
	start_screen.start_requested.connect(_start_new_game)
	start_screen.load_requested.connect(_load_saved_game)
	game_ui.continue_requested.connect(_show_blessings)
	game_ui.blessing_selected.connect(_start_second_map)
	game_ui.menu_requested.connect(_return_to_menu)
	ProgressManager.achievement_unlocked.connect(
		func(_id: String, title: String) -> void:
			GameManager.post_message("成就解锁：%s" % title)
	)
	GameManager.game_over.connect(_on_game_over)
	grid_map.modulate.a = 0.0
	map_frame.modulate.a = 0.0
	game_ui.modulate.a = 0.0
	hand_ui.modulate.a = 0.0


func _exit_tree() -> void:
	if GameManager.grid_map_ref == grid_map:
		GameManager.grid_map_ref = null
	if GameManager.scene_root == self:
		GameManager.scene_root = null


func _start_new_game() -> void:
	ProgressManager.begin_run()
	ProgressManager.begin_map(1)
	ResourceManager.reset()
	built_attack_deities = 0
	built_resource_deities = 0
	grid_map.reset_board()
	GameManager.start_game()
	AudioManager.play_music("music_build", -9.0)
	TurnManager.start_game_loop()
	_reveal_gameplay()
	tutorial_step = 0
	game_ui.show_tutorial(
		"目标：摧毁外围 %d 个敌方核心，再用地块填满所有可用位置。先从右侧购买地块。"
		% grid_map.enemy_cores.size()
	)


func _process(delta: float) -> void:
	if TurnManager.current_phase == TurnManager.Phase.COMBAT:
		grid_map.tick_combat(delta)


func _on_build_started() -> void:
	if not GameManager.is_game_running:
		return
	grid_map.reset_enemy_death_sfx_sequence()
	AudioManager.play_sfx("phase_build")
	AudioManager.play_music("music_build", -9.0)
	grid_map.clear_preview()
	grid_map.prepare_build_spawn_warning()
	CardManager.begin_build_phase()
	if ProgressManager.blessing_value("build_free_refresh") > 0.0:
		free_refreshes = maxi(free_refreshes, 1)
	_save_checkpoint_if_possible()
	GameManager.post_message("建设阶段：购买地块、规划地形并安置神祇")


func _save_checkpoint_if_possible() -> void:
	if (
		not GameManager.is_game_running
		or TurnManager.current_phase != TurnManager.Phase.BUILD
		or not is_instance_valid(grid_map)
	):
		return
	ProgressManager.store_run_checkpoint({
		"map": ProgressManager.current_map,
		"round": GameManager.current_round,
		"core_hp": GameManager.core_hp,
		"core_max_hp": GameManager.core_max_hp,
		"divine_power": ResourceManager.divine_power,
		"free_refreshes": free_refreshes,
		"built_attack_deities": built_attack_deities,
		"built_resource_deities": built_resource_deities,
		"selected_blessing": ProgressManager.selected_blessing,
		"stats": ProgressManager.stats.duplicate(true),
		"run_elapsed": ProgressManager.run_elapsed_seconds(),
		"map_elapsed": ProgressManager.map_elapsed_seconds(),
		"map_state": grid_map.serialize_state(),
	})


func _load_saved_game() -> void:
	var checkpoint := ProgressManager.run_checkpoint.duplicate(true)
	if checkpoint.is_empty():
		return
	ProgressManager.current_map = int(checkpoint.get("map", 1))
	ProgressManager.selected_blessing = str(checkpoint.get("selected_blessing", ""))
	ProgressManager.stats = (checkpoint.get("stats", {}) as Dictionary).duplicate(true)
	var now := Time.get_ticks_msec()
	ProgressManager.run_started_msec = now - roundi(float(checkpoint.get("run_elapsed", 0.0)) * 1000.0)
	ProgressManager.map_started_msec = now - roundi(float(checkpoint.get("map_elapsed", 0.0)) * 1000.0)
	GameManager.start_game()
	GameManager.current_round = int(checkpoint.get("round", 1))
	GameManager.core_max_hp = int(checkpoint.get("core_max_hp", 30))
	GameManager.core_hp = int(checkpoint.get("core_hp", GameManager.core_max_hp))
	ResourceManager.divine_power = float(checkpoint.get("divine_power", 0.0))
	ResourceManager.resources_changed.emit()
	free_refreshes = int(checkpoint.get("free_refreshes", 0))
	built_attack_deities = int(checkpoint.get("built_attack_deities", 0))
	built_resource_deities = int(checkpoint.get("built_resource_deities", 0))
	var map_state: Dictionary = checkpoint.get("map_state", {})
	if not grid_map.restore_state(map_state):
		_start_new_game()
		return
	AudioManager.play_music("music_build", -9.0)
	TurnManager.enter_build_phase()
	_reveal_gameplay()
	GameManager.state_changed.emit()


func purchase_shop_card(index: int) -> void:
	cancel_active_tile_purchase()
	var card := CardManager.purchase_shop_card(index)
	if not card:
		GameManager.reject_action("无法购买：商店位置为空、神力不足或当前不是建设阶段")
		return
	AudioManager.play_sfx_first(["button_card_purchase", "purchase"])
	active_tile_card = card
	active_tile_shop_index = index
	grid_map.begin_terrain_placement(card)
	GameManager.state_changed.emit()
	if tutorial_step == 0:
		tutorial_step = 1
		game_ui.show_tutorial("把地块放到中央核心旁边；按 R 旋转。最终需要把敌方核心被摧毁后留下的方向也连接填满。")
	GameManager.post_message("已购买%s：R 旋转，左键立即放置" % card.card_name)


func refresh_shop() -> void:
	if TurnManager.current_phase != TurnManager.Phase.BUILD:
		GameManager.reject_action("只能在建设阶段刷新商店")
		return
	if free_refreshes <= 0:
		GameManager.reject_action("当前没有免费刷新次数")
		return
	cancel_active_tile_purchase()
	free_refreshes -= 1
	CardManager.refresh_shop()
	ProgressManager.add_stat("shop_refreshes")
	AudioManager.play_sfx_first(["button_refresh", "refresh"])
	GameManager.post_message("使用免费次数刷新了五格商店")
	GameManager.state_changed.emit()


func grant_free_refresh() -> void:
	free_refreshes += 1
	GameManager.post_message("河流资源形态积蓄了一次免费刷新")
	GameManager.state_changed.emit()


func start_combat() -> void:
	cancel_active_tile_purchase()
	if TurnManager.start_combat():
		grid_map.clear_preview()
		if tutorial_step == 3:
			tutorial_step = 4
			game_ui.hide_tutorial()


func _on_placement_finished(success: bool) -> void:
	if success:
		var placed_card := active_tile_card
		active_tile_card = null
		active_tile_shop_index = -1
		if placed_card:
			var terrain_key := AssetCatalog.terrain_suffix(placed_card.terrain_type)
			AudioManager.play_sfx_first(["place_terrain_%s" % terrain_key, "place"])
			if tutorial_step == 1:
				tutorial_step = 2
				game_ui.show_tutorial("新手引导 3/4：点击刚放下的神域，选择一座神祇。")
		else:
			AudioManager.play_sfx("place")
		GameManager.post_message("放置完成，可继续购买地块或点击地块召请神祇")
		GameManager.state_changed.emit()


func purchase_deity_at(pos: Vector2i, deity_type: int) -> void:
	var terrain := grid_map.get_cell(pos).terrain
	if grid_map.purchase_and_place_deity(pos, deity_type):
		if deity_type == GameDefinitions.DeityType.ATTACK:
			built_attack_deities += 1
		else:
			built_resource_deities += 1
		var role := "attack" if deity_type == GameDefinitions.DeityType.ATTACK else "resource"
		AudioManager.play_sfx_first([
			"place_deity_%s_%s" % [role, AssetCatalog.terrain_suffix(terrain)],
			"place",
		])
		if tutorial_step == 2:
			tutorial_step = 3
			game_ui.show_tutorial("新手引导 4/4：点击右下角时间流动，开始自动战斗。")
		GameManager.post_message("%s已安置" % grid_map.deity_form_name(pos, deity_type))


func cancel_active_tile_purchase() -> void:
	if not active_tile_card:
		return
	if CardManager.return_shop_card(active_tile_shop_index, active_tile_card):
		ResourceManager.add_divine_power(active_tile_card.divine_power_cost)
		GameManager.post_message("%s已退回商店" % active_tile_card.card_name)
	active_tile_card = null
	active_tile_shop_index = -1
	grid_map.clear_preview()


func _on_combat_started(_duration: float) -> void:
	ProgressManager.set_stat("resource_income_round", 0.0)
	grid_map.reset_combat_timers()
	AudioManager.play_sfx("phase_combat")
	AudioManager.play_music("music_combat", -8.0)
	GameManager.post_message("自动战斗开始：敌人与神祇将自行行动")


func _on_combat_ended(_round_number: int) -> void:
	var income := float(GameDefinitions.BALANCE.combat_base_income)
	ResourceManager.add_divine_power(income)
	ProgressManager.add_stat("base_income", income)
	var interest := grid_map.collect_abundance_interest()
	grid_map.reset_large_domain_state()
	if interest > 0.0:
		GameManager.post_message("丰饶神利息：+%.1f 神力" % interest)
	GameManager.post_message("中央核心稳定产出 %.1f 神力" % income)


func can_end_combat() -> bool:
	return grid_map.get_all_enemy_positions().is_empty() and not grid_map.has_pending_spawn()


func begin_deity_migration(pos: Vector2i) -> void:
	grid_map.begin_deity_migration(pos)


func begin_deity_migration_selection() -> void:
	grid_map.begin_deity_migration_selection()


func _reveal_gameplay() -> void:
	var map_target_scale := grid_map.scale
	grid_map.scale = map_target_scale * 0.86
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(grid_map, "modulate:a", 1.0, 0.55)
	tween.parallel().tween_property(grid_map, "scale", map_target_scale, 0.7)
	tween.parallel().tween_property(map_frame, "modulate:a", 1.0, 0.65)
	tween.tween_interval(0.12)
	tween.tween_property(game_ui, "modulate:a", 1.0, 0.32)
	tween.parallel().tween_property(hand_ui, "modulate:a", 1.0, 0.32)


func _on_map_completed() -> void:
	TurnManager.finish_game()
	ProgressManager.clear_run_checkpoint()
	var snapshot := _build_result_snapshot()
	var result := ProgressManager.register_map_result(ProgressManager.current_map, snapshot)
	game_ui.show_map_result(
		snapshot,
		result,
		ProgressManager.current_map == ProgressManager.MAX_MAPS
	)
	if ProgressManager.current_map == ProgressManager.MAX_MAPS:
		GameManager.is_game_running = false


func _on_game_over(victory: bool) -> void:
	ProgressManager.save_current_run()
	if victory:
		return
	ProgressManager.clear_run_checkpoint()
	game_ui.show_failure()


func _build_result_snapshot() -> Dictionary:
	var attack_count := 0
	var resource_count := 0
	var upgraded_count := 0
	for pos in grid_map.get_all_deity_positions():
		var deity := grid_map.get_cell(pos).deity as DeityInstance
		if deity.deity_type == GameDefinitions.DeityType.ATTACK:
			attack_count += 1
		else:
			resource_count += 1
		if deity.level >= 2:
			upgraded_count += 1
	var terrain_snapshot: Array[int] = []
	for y in range(grid_map.GRID_H):
		for x in range(grid_map.GRID_W):
			terrain_snapshot.append(grid_map.get_cell(Vector2i(x, y)).terrain)
	return {
		"time": ProgressManager.map_elapsed_seconds(),
		"core_hp": GameManager.core_hp,
		"resource": ResourceManager.divine_power,
		"attack_deities": attack_count,
		"resource_deities": resource_count,
		"level_2_deities": upgraded_count,
		"shop_refreshes": int(ProgressManager.stats.get("shop_refreshes", 0)),
		"collapsed_cells": int(ProgressManager.stats.get("collapsed_cells", 0)),
		"anchors": grid_map.activated_anchor_count(),
		"terrain_snapshot": terrain_snapshot,
	}


func _show_blessings() -> void:
	game_ui.show_blessing_choices(ProgressManager.blessing_choices())


func _start_second_map(id: String) -> void:
	game_ui.hide_result_overlay()
	ProgressManager.choose_blessing(id)
	var next_map := mini(ProgressManager.MAX_MAPS, ProgressManager.current_map + 1)
	ProgressManager.begin_map(next_map)
	GameManager.current_round = 1
	GameManager.core_max_hp = 30 + roundi(ProgressManager.blessing_value("core_max_hp"))
	GameManager.core_hp = GameManager.core_max_hp
	GameManager.is_game_running = true
	free_refreshes = 0
	built_attack_deities = 0
	built_resource_deities = 0
	CardManager.reset()
	ResourceManager.reset()
	grid_map.reset_board()
	TurnManager.start_game_loop()
	if ProgressManager.blessing_value("random_domino") > 0.0:
		_grant_random_domino()
	GameManager.state_changed.emit()


func cheat_add_power() -> void:
	ResourceManager.add_divine_power(25.0)


func cheat_heal_core() -> void:
	GameManager.core_hp = GameManager.core_max_hp
	GameManager.state_changed.emit()


func cheat_destroy_enemy_cores() -> void:
	for pos in grid_map.enemy_cores:
		var data: Dictionary = grid_map.enemy_cores[pos]
		data.hp = 0
		data.active = false
	grid_map.queue_redraw()


func cheat_fill_map() -> void:
	for y in range(grid_map.GRID_H):
		for x in range(grid_map.GRID_W):
			var pos := Vector2i(x, y)
			if pos == grid_map.core_pos or grid_map.is_enemy_core_slot(pos):
				continue
			var cell := grid_map.get_cell(pos)
			if cell.terrain == GameDefinitions.TerrainType.NONE:
				cell.terrain = (
					cell.anchor_terrain
					if cell.anchor_terrain != GameDefinitions.TerrainType.NONE
					else GameDefinitions.TerrainType.PLAIN
				)
				cell.piece_id = grid_map.next_piece_id
				grid_map.next_piece_id += 1
				cell.pollution = 0
				cell.visual_rotation = 0
				grid_map._activate_anchor_if_needed(pos)
	grid_map.recalculate_all_deities()
	grid_map.board_changed.emit()
	grid_map.queue_redraw()
	grid_map._check_victory()


func deity_cost_modifier(_deity_type: int) -> float:
	return 0.0


func _grant_random_domino() -> void:
	var card := TerrainCard.new()
	card.shape.assign(PieceShapeConfig.SHAPES[1])
	card.terrain_type = GameManager.rng.randi_range(
		GameDefinitions.TerrainType.PLAIN,
		GameDefinitions.TerrainType.RIVER
	)
	card.card_name = "祝福赠予的两格地块"
	card.divine_power_cost = 0.0
	card.color = GameDefinitions.TERRAIN_COLORS[card.terrain_type]
	active_tile_card = card
	active_tile_shop_index = -1
	grid_map.begin_terrain_placement(card)
	GameManager.post_message("祝福赠予了一张免费两格地块")


func _return_to_menu() -> void:
	get_tree().reload_current_scene()


func _on_enemy_core_destroyed(_pos: Vector2i) -> void:
	var original := position
	var tween := create_tween()
	for offset in [Vector2(8, 0), Vector2(-7, 5), Vector2(5, -6), Vector2.ZERO]:
		tween.tween_property(self, "position", original + offset, 0.045)
	tween.tween_property(self, "position", original, 0.06)


func _on_attack_visual_requested(
	from: Vector2i,
	to: Vector2i,
	color: Color,
	damage: int,
	effect_profile: String
) -> void:
	var start := grid_map.to_global(grid_map.grid_to_world(from) + Vector2.ONE * grid_map.CELL_SIZE * 0.5)
	var finish := grid_map.to_global(grid_map.grid_to_world(to) + Vector2.ONE * grid_map.CELL_SIZE * 0.5)
	_spawn_attack_start_effect(start, color, effect_profile)
	var projectile_key := "projectile_%s" % effect_profile
	var projectile: Node2D
	var projectile_frames := AssetCatalog.animation(projectile_key)
	if projectile_frames:
		var animated := AnimatedSprite2D.new()
		animated.sprite_frames = projectile_frames
		var animation_name := &"move"
		if not projectile_frames.has_animation(animation_name):
			animation_name = &"default"
		if projectile_frames.has_animation(animation_name):
			animated.play(animation_name)
		projectile = animated
	else:
		var projectile_texture := AssetCatalog.texture(projectile_key)
		if not projectile_texture:
			projectile_texture = AssetCatalog.texture("projectile_default")
		if projectile_texture:
			var sprite := Sprite2D.new()
			sprite.texture = projectile_texture
			projectile = sprite
	if projectile:
		projectile.modulate = color
	else:
		var polygon := Polygon2D.new()
		polygon.polygon = PackedVector2Array([
			Vector2(-8, -3), Vector2(7, -3), Vector2(11, 0),
			Vector2(7, 3), Vector2(-8, 3),
		])
		polygon.color = color
		projectile = polygon
	projectile.position = start
	projectile.rotation = (finish - start).angle()
	projectile.z_index = 50
	add_child(projectile)
	var tween := create_tween()
	if effect_profile == "deity_mountain":
		var arc_height := maxf(46.0, start.distance_to(finish) * 0.22)
		tween.tween_method(func(progress: float) -> void:
			if not is_instance_valid(projectile):
				return
			var linear := start.lerp(finish, progress)
			projectile.position = linear + Vector2(0.0, -sin(progress * PI) * arc_height)
		, 0.0, 1.0, 0.32)
	else:
		tween.tween_property(projectile, "position", finish, 0.18)
	await tween.finished
	if is_instance_valid(projectile):
		projectile.queue_free()
	_spawn_hit_effect(finish, color, damage, effect_profile)


func _spawn_attack_start_effect(position: Vector2, color: Color, effect_profile: String) -> void:
	var effect_key := "muzzle_%s" % effect_profile
	var frames := AssetCatalog.animation(effect_key)
	if frames:
		var animated := AnimatedSprite2D.new()
		animated.sprite_frames = frames
		animated.position = position
		animated.modulate = color
		animated.z_index = 49
		add_child(animated)
		var animation_name := &"default"
		if not frames.has_animation(animation_name):
			var names := frames.get_animation_names()
			if not names.is_empty():
				animation_name = names[0]
		animated.play(animation_name)
		get_tree().create_timer(0.4).timeout.connect(animated.queue_free)
		return
	var texture := AssetCatalog.texture(effect_key)
	if not texture:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.modulate = color
	sprite.z_index = 49
	add_child(sprite)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.35, 1.35), 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(sprite.queue_free)


func _spawn_hit_effect(
	position: Vector2,
	color: Color,
	_damage: int,
	effect_profile: String
) -> void:
	var hit_key := "hit_%s" % effect_profile
	var hit_frames := AssetCatalog.animation(hit_key)
	if hit_frames:
		var animated_hit := AnimatedSprite2D.new()
		animated_hit.sprite_frames = hit_frames
		animated_hit.position = position
		animated_hit.modulate = color
		animated_hit.z_index = 51
		add_child(animated_hit)
		var animation_name := &"default"
		if not hit_frames.has_animation(animation_name):
			var names := hit_frames.get_animation_names()
			if not names.is_empty():
				animation_name = names[0]
		animated_hit.play(animation_name)
		get_tree().create_timer(0.45).timeout.connect(animated_hit.queue_free)
	else:
		var hit_texture := AssetCatalog.texture(hit_key)
		if not hit_texture:
			hit_texture = AssetCatalog.texture("hit_default")
		if not hit_texture:
			return
		var hit := Sprite2D.new()
		hit.texture = hit_texture
		hit.modulate = color
		hit.position = position
		hit.z_index = 51
		add_child(hit)
		var hit_tween := create_tween().set_parallel(true)
		hit_tween.tween_property(hit, "scale", Vector2(1.5, 1.5), 0.35)
		hit_tween.tween_property(hit, "modulate:a", 0.0, 0.35)
		hit_tween.chain().tween_callback(hit.queue_free)
