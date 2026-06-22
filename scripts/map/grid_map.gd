class_name GameMap
extends Node2D

signal placement_finished(success: bool)
signal board_changed
signal attack_visual_requested(
	from: Vector2i,
	to: Vector2i,
	color: Color,
	damage: int,
	effect_profile: String
)
signal terrain_selected(grid_pos: Vector2i)
signal deity_selected(grid_pos: Vector2i)
signal terrain_hovered(grid_pos: Vector2i)
signal enemy_hovered(grid_pos: Vector2i)
signal enemy_selected(grid_pos: Vector2i)
signal core_hovered
signal core_selected
signal map_hover_exited
signal selection_cleared
signal cell_destroyed(grid_pos: Vector2i)
signal map_completed
signal enemy_core_destroyed(grid_pos: Vector2i)

const CELL_SIZE := 54
const GRID_W := 11
const GRID_H := 11
const ORTHOGONAL := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
var cells: Array[GridCellData] = []
var pieces: Dictionary = {}
var core_pos := Vector2i(GRID_W / 2, GRID_H / 2)
var next_piece_id: int = 1

var preview_terrain: TerrainCard
var preview_deity_type: int = -1
var preview_pos := Vector2i(-1, -1)
var preview_rotation: int = 0
var hover_pos := Vector2i(-1, -1)
var selected_pos := Vector2i(-1, -1)
var migration_source := Vector2i(-1, -1)
var migration_selecting_source: bool = false
var range_reveal_started_at: float = 0.0
var preview_route_cache_key: String = ""
var preview_route_cache: Array[Dictionary] = []

var spawn_timer: float = 0.0
var pulse_time: float = 0.0
var completion_emitted: bool = false
var enemy_death_sfx_step: int = 0
var enemy_cores: Dictionary = {}
var enemy_core_activation_order: Array[int] = []
var pending_spawn_core := Vector2i(-1, -1)
var spawn_warning_time: float = 0.0
var spawn_warning_sequence: int = 0

const ENEMY_CORE_POSITIONS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(5, 0),
	Vector2i(10, 0),
	Vector2i(10, 5),
	Vector2i(10, 10),
	Vector2i(5, 10),
	Vector2i(0, 10),
	Vector2i(0, 5),
]
const ENEMY_CORE_PROGRESSION_ORDER: Array[int] = [1, 3, 5, 7, 0, 2, 4, 6]


func _ready() -> void:
	reset_board()
	set_process(true)


func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()


func reset_board() -> void:
	cells.clear()
	pieces.clear()
	next_piece_id = 1
	for _i in range(GRID_W * GRID_H):
		var cell := GridCellData.new()
		cell.visual_rotation = GameManager.rng.randi_range(0, 3)
		cells.append(cell)
	selected_pos = Vector2i(-1, -1)
	completion_emitted = false
	pending_spawn_core = Vector2i(-1, -1)
	spawn_warning_time = 0.0
	spawn_warning_sequence = 0
	_setup_enemy_cores()
	if required_anchor_count() > 0:
		_setup_anchors()
	clear_preview()
	board_changed.emit()
	queue_redraw()


func _setup_enemy_cores() -> void:
	enemy_cores.clear()
	enemy_core_activation_order.clear()
	var counts: Dictionary = GameDefinitions.BALANCE.map_enemy_core_count
	var core_count := clampi(
		int(counts.get(ProgressManager.current_map, ENEMY_CORE_POSITIONS.size())),
		1,
		ENEMY_CORE_POSITIONS.size()
	)
	var selected_indices: Array[int] = []
	for slot in range(core_count):
		selected_indices.append(ENEMY_CORE_PROGRESSION_ORDER[slot])
	for index in selected_indices:
		enemy_core_activation_order.append(index)
	enemy_core_activation_order.shuffle()
	var initial_active := int(GameDefinitions.BALANCE.enemy_core_initial_active)
	for index in selected_indices:
		var pos := ENEMY_CORE_POSITIONS[index]
		enemy_cores[pos] = {
			"hp": int(GameDefinitions.BALANCE.enemy_core_hp),
			"max_hp": int(GameDefinitions.BALANCE.enemy_core_hp),
			"active": enemy_core_activation_order.find(index) < initial_active,
			"index": index,
		}


func is_enemy_core(pos: Vector2i) -> bool:
	if not enemy_cores.has(pos):
		return false
	return int((enemy_cores[pos] as Dictionary).get("hp", 0)) > 0


func living_enemy_core_count() -> int:
	var count := 0
	for data in enemy_cores.values():
		if int((data as Dictionary).get("hp", 0)) > 0:
			count += 1
	return count


func destroyed_enemy_core_count() -> int:
	return enemy_cores.size() - living_enemy_core_count()


func reset_combat_timers() -> void:
	spawn_timer = float(GameDefinitions.BALANCE.enemy_first_warning_delay)
	if pending_spawn_core == Vector2i(-1, -1):
		prepare_build_spawn_warning()
	for cell in cells:
		var deity := cell.deity as DeityInstance
		if deity:
			deity.action_timer = minf(deity.action_timer, 0.5)


func reset_enemy_death_sfx_sequence() -> void:
	enemy_death_sfx_step = 0


func index_of(pos: Vector2i) -> int:
	return pos.y * GRID_W + pos.x


func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_W and pos.y >= 0 and pos.y < GRID_H


func get_cell(pos: Vector2i) -> GridCellData:
	if not is_in_bounds(pos):
		return null
	return cells[index_of(pos)]


func neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in ORTHOGONAL:
		var next: Vector2i = pos + offset
		if is_in_bounds(next):
			result.append(next)
	return result


func terrain_region(start: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not is_in_bounds(start):
		return result
	var terrain := get_cell(start).terrain
	if terrain == GameDefinitions.TerrainType.NONE:
		return result
	var frontier: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		result.append(current)
		for adjacent in neighbors(current):
			if visited.has(adjacent) or get_cell(adjacent).terrain != terrain:
				continue
			visited[adjacent] = true
			frontier.append(adjacent)
	return result


func region_deity_count(start: Vector2i) -> int:
	var count := 0
	for pos in terrain_region(start):
		if get_cell(pos).deity:
			count += 1
	return count


func region_deity_position(start: Vector2i) -> Vector2i:
	for pos in terrain_region(start):
		if get_cell(pos).deity:
			return pos
	return Vector2i(-1, -1)


func _connected_deities_after_placement(
	positions: Array[Vector2i],
	terrain: int
) -> int:
	var new_positions: Dictionary = {}
	for pos in positions:
		new_positions[pos] = true
	var visited: Dictionary = {}
	var deity_count := 0
	for pos in positions:
		for adjacent in neighbors(pos):
			if (
				new_positions.has(adjacent)
				or visited.has(adjacent)
				or get_cell(adjacent).terrain != terrain
			):
				continue
			var frontier: Array[Vector2i] = [adjacent]
			visited[adjacent] = true
			while not frontier.is_empty():
				var current: Vector2i = frontier.pop_front()
				if get_cell(current).deity:
					deity_count += 1
				for next in neighbors(current):
					if (
						not visited.has(next)
						and not new_positions.has(next)
						and get_cell(next).terrain == terrain
					):
						visited[next] = true
						frontier.append(next)
	return deity_count


func grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)


func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))


func begin_terrain_placement(card: TerrainCard) -> void:
	clear_preview()
	preview_terrain = card
	preview_pos = core_pos + Vector2i.RIGHT
	preview_route_cache_key = ""
	queue_redraw()


func can_place_terrain(card: TerrainCard, anchor: Vector2i, rotation: int) -> bool:
	if not card:
		return false
	var positions: Array[Vector2i] = []
	var touches_map := false
	for offset in card.rotated_shape(rotation):
		var pos := anchor + offset
		if not is_in_bounds(pos) or pos == core_pos or is_enemy_core(pos):
			return false
		var cell := get_cell(pos)
		if (
			cell.anchor_terrain != GameDefinitions.TerrainType.NONE
			and cell.anchor_terrain != card.terrain_type
		):
			return false
		if cell.piece_id >= 0 or cell.deity:
			return false
		positions.append(pos)
	for pos in positions:
		for adjacent in neighbors(pos):
			if adjacent == core_pos or get_cell(adjacent).piece_id >= 0:
				touches_map = true
				break
	if not touches_map or _connected_deities_after_placement(positions, card.terrain_type) > 1:
		return false
	if card.terrain_type == GameDefinitions.TerrainType.MOUNTAIN:
		for enemy_core_pos in enemy_cores:
			var data: Dictionary = enemy_cores[enemy_core_pos]
			if int(data.hp) > 0 and not _enemy_core_has_path(enemy_core_pos, positions):
				return false
	return true


func _enemy_core_has_path(start: Vector2i, prospective_mountains: Array[Vector2i] = []) -> bool:
	var overrides: Dictionary = {}
	for pos in prospective_mountains:
		overrides[pos] = GameDefinitions.TerrainType.MOUNTAIN
	return _weighted_path(start, false, overrides, true, true).size() >= 2


func place_preview_terrain() -> bool:
	if (
		TurnManager.current_phase != TurnManager.Phase.BUILD
		or not preview_terrain
		or not can_place_terrain(preview_terrain, preview_pos, preview_rotation)
	):
		GameManager.reject_action("拼图必须在边界内、避开核心和已有拼图，并与地图四向相邻")
		return false
	var piece := MapPieceInstance.new()
	piece.piece_id = next_piece_id
	piece.terrain_type = preview_terrain.terrain_type
	for offset in preview_terrain.rotated_shape(preview_rotation):
		var pos := preview_pos + offset
		piece.cells.append(pos)
		var cell := get_cell(pos)
		if cell.was_collapsed:
			ProgressManager.add_stat("rebuilt_cells")
			cell.was_collapsed = false
		cell.terrain = preview_terrain.terrain_type
		cell.pollution = 0
		cell.piece_id = piece.piece_id
		cell.visual_rotation = 0
		if cell.enemy:
			# 新拼图不会抹掉敌人；敌人继续占据该格并可在死亡时污染它。
			pass
		_activate_anchor_if_needed(pos)
	pieces[piece.piece_id] = piece
	next_piece_id += 1
	preview_terrain = null
	preview_rotation = 0
	recalculate_all_deities()
	board_changed.emit()
	placement_finished.emit(true)
	queue_redraw()
	_check_victory()
	return true


func _setup_anchors() -> void:
	var anchors := [
		{"pos": Vector2i(2, 2), "terrain": GameDefinitions.TerrainType.PLAIN},
		{"pos": Vector2i(8, 2), "terrain": GameDefinitions.TerrainType.MOUNTAIN},
		{"pos": Vector2i(2, 8), "terrain": GameDefinitions.TerrainType.RIVER},
		{"pos": Vector2i(8, 8), "terrain": GameDefinitions.TerrainType.FOREST},
	]
	for index in range(required_anchor_count()):
		var anchor: Dictionary = anchors[index]
		var pos: Vector2i = anchor.pos
		var cell := get_cell(pos)
		cell.anchor_terrain = int(anchor.terrain)
		cell.anchor_reward_claimed = false


func required_anchor_count() -> int:
	var counts: Dictionary = GameDefinitions.BALANCE.map_anchor_count
	return clampi(int(counts.get(ProgressManager.current_map, 0)), 0, 4)


func _activate_anchor_if_needed(pos: Vector2i) -> void:
	var cell := get_cell(pos)
	if (
		not cell
		or cell.anchor_terrain == GameDefinitions.TerrainType.NONE
		or cell.terrain != cell.anchor_terrain
		or cell.anchor_reward_claimed
	):
		return
	cell.anchor_reward_claimed = true
	match cell.anchor_terrain:
		GameDefinitions.TerrainType.PLAIN:
			for deity_pos in get_all_deity_positions():
				var deity := get_cell(deity_pos).deity as DeityInstance
				if deity:
					deity.action_timer *= float(GameDefinitions.BALANCE.anchor_plain_speed_multiplier)
			GameManager.post_message("平原锚点：所有神祇立即加速")
		GameDefinitions.TerrainType.MOUNTAIN:
			GameManager.heal_core(int(GameDefinitions.BALANCE.anchor_mountain_core_heal))
			GameManager.post_message("山地锚点：核心恢复生命")
		GameDefinitions.TerrainType.RIVER:
			if GameManager.scene_root:
				GameManager.scene_root.grant_free_refresh()
			GameManager.post_message("河流锚点：获得免费刷新")
		GameDefinitions.TerrainType.FOREST:
			for deity_pos in get_all_deity_positions():
				var deity := get_cell(deity_pos).deity as DeityInstance
				if deity:
					deity.hp = mini(deity.max_hp, deity.hp + int(GameDefinitions.BALANCE.anchor_forest_heal))
			GameManager.post_message("森林锚点：治疗所有神祇")


func get_all_deity_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			if get_cell(pos).deity:
				result.append(pos)
	return result


func activated_anchor_count() -> int:
	var count := 0
	for cell in cells:
		if (
			cell.anchor_terrain != GameDefinitions.TerrainType.NONE
			and cell.terrain == cell.anchor_terrain
		):
			count += 1
	return count


func deity_form_name(pos: Vector2i, deity_type: int) -> String:
	var cell := get_cell(pos)
	if not cell or cell.terrain == GameDefinitions.TerrainType.NONE:
		return GameDefinitions.DEITY_NAMES[deity_type]
	var forms: Dictionary = GameDefinitions.DEITY_FORM_NAMES.get(cell.terrain, {})
	return str(forms.get(deity_type, GameDefinitions.DEITY_NAMES[deity_type]))


func can_place_deity(deity_type: int, pos: Vector2i) -> bool:
	if deity_type < 0 or not is_in_bounds(pos) or pos == core_pos:
		return false
	var cell := get_cell(pos)
	return (
		cell.piece_id >= 0
		and not cell.deity
		and not cell.enemy
		and region_deity_count(pos) == 0
	)


func deity_purchase_cost(deity_type: int) -> float:
	var cost := (
		float(GameDefinitions.BALANCE.attack_deity_cost)
		if deity_type == GameDefinitions.DeityType.ATTACK
		else float(GameDefinitions.BALANCE.resource_deity_cost)
	)
	if GameManager.scene_root and GameManager.scene_root.has_method("deity_cost_modifier"):
		cost += float(GameManager.scene_root.deity_cost_modifier(deity_type))
	return maxf(0.0, cost)


func resource_deity_refund(pos: Vector2i) -> float:
	return 0.0


func purchase_and_place_deity(pos: Vector2i, deity_type: int) -> bool:
	if TurnManager.current_phase != TurnManager.Phase.BUILD or not can_place_deity(deity_type, pos):
		GameManager.reject_action("该地块当前不能安置神祇")
		return false
	var cost := deity_purchase_cost(deity_type)
	if not ResourceManager.spend(cost):
		GameManager.reject_action("神力不足，需要 %.1f" % cost)
		return false
	preview_deity_type = deity_type
	var placed := place_deity(pos)
	if not placed:
		ResourceManager.add_divine_power(cost)
	return placed


func place_deity(pos: Vector2i) -> bool:
	if not can_place_deity(preview_deity_type, pos):
		GameManager.reject_action("神祇只能放在无敌人、无神祇的已有地形上")
		return false
	var deity := DeityInstance.create(preview_deity_type)
	get_cell(pos).deity = deity
	_recalculate_deity(pos)
	deity.hp = deity.max_hp
	selected_pos = pos
	preview_deity_type = -1
	board_changed.emit()
	placement_finished.emit(true)
	queue_redraw()
	return true


func clear_preview() -> void:
	preview_terrain = null
	preview_deity_type = -1
	preview_rotation = 0
	preview_route_cache_key = ""
	preview_route_cache.clear()
	migration_source = Vector2i(-1, -1)
	migration_selecting_source = false
	queue_redraw()


func begin_deity_migration_selection() -> void:
	if TurnManager.current_phase != TurnManager.Phase.BUILD:
		GameManager.reject_action("战斗阶段不能迁移神祇")
		return
	clear_preview()
	migration_selecting_source = true
	GameManager.post_message("请选择一座需要迁移的神祇")


func begin_deity_migration(pos: Vector2i) -> bool:
	if TurnManager.current_phase != TurnManager.Phase.BUILD:
		GameManager.reject_action("战斗阶段不能迁移神祇")
		return false
	if not is_in_bounds(pos) or not get_cell(pos).deity:
		return false
	clear_preview()
	migration_source = pos
	migration_selecting_source = false
	selected_pos = pos
	GameManager.post_message("选择同一神域中的空格完成迁移")
	queue_redraw()
	return true


func can_migrate_deity_to(target: Vector2i) -> bool:
	if (
		TurnManager.current_phase != TurnManager.Phase.BUILD
		or migration_source == Vector2i(-1, -1)
		or target == migration_source
		or not is_in_bounds(target)
	):
		return false
	var source_cell := get_cell(migration_source)
	var target_cell := get_cell(target)
	return (
		source_cell
		and source_cell.deity
		and target in terrain_region(migration_source)
		and not target_cell.deity
		and not target_cell.enemy
	)


func migrate_deity(target: Vector2i) -> bool:
	if not can_migrate_deity_to(target):
		GameManager.reject_action("只能迁移到同一连通神域中的空格")
		return false
	var cost := float(GameDefinitions.BALANCE.deity_migration_cost)
	if not ResourceManager.spend(cost):
		GameManager.reject_action("迁移需要 %.1f 神力" % cost)
		return false
	var deity := get_cell(migration_source).deity as DeityInstance
	get_cell(migration_source).deity = null
	get_cell(target).deity = deity
	migration_source = Vector2i(-1, -1)
	selected_pos = target
	recalculate_all_deities()
	deity_selected.emit(target)
	board_changed.emit()
	GameManager.post_message("神祇已迁移，保留等级、生命与充能")
	queue_redraw()
	return true


func fill_ratio() -> float:
	var filled := 0
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			if pos != core_pos and get_cell(pos).piece_id >= 0:
				filled += 1
	return float(filled) / float(GRID_W * GRID_H - 1)


func surrounding_terrain_counts(pos: Vector2i) -> Dictionary:
	var counts := {"plain": 0, "mountain": 0, "river": 0, "forest": 0}
	var context := deity_domain_context(pos)
	var resonances: Dictionary = context.get("resonances", {})
	counts.plain = 1 if bool(resonances.get(GameDefinitions.TerrainType.PLAIN, false)) else 0
	counts.mountain = 1 if bool(resonances.get(GameDefinitions.TerrainType.MOUNTAIN, false)) else 0
	counts.river = 1 if bool(resonances.get(GameDefinitions.TerrainType.RIVER, false)) else 0
	counts.forest = 1 if bool(resonances.get(GameDefinitions.TerrainType.FOREST, false)) else 0
	return counts


func domain_area_multiplier(area: int) -> float:
	if area <= 1:
		return 1.0
	if area <= 6:
		return 1.0 + float(area - 1) * float(GameDefinitions.BALANCE.domain_area_step_to_six)
	return 2.0 + float(area - 6) * float(GameDefinitions.BALANCE.domain_area_step_after_six)


func deity_domain_context(pos: Vector2i) -> Dictionary:
	var own_region := terrain_region(pos)
	var resonances: Dictionary = {}
	var adjacent_deities: Array[Vector2i] = []
	var visited_regions: Dictionary = {}
	for own_cell in own_region:
		for adjacent in neighbors(own_cell):
			if adjacent in own_region:
				continue
			var adjacent_cell := get_cell(adjacent)
			if not adjacent_cell or adjacent_cell.terrain == GameDefinitions.TerrainType.NONE:
				continue
			var region := terrain_region(adjacent)
			if region.is_empty():
				continue
			var region_index := GRID_W * GRID_H
			for region_cell in region:
				region_index = mini(region_index, index_of(region_cell))
			var region_key := str(region_index)
			if visited_regions.has(region_key):
				continue
			visited_regions[region_key] = true
			var provider_pos := region_deity_position(adjacent)
			if provider_pos == Vector2i(-1, -1):
				continue
			var provider := get_cell(provider_pos).deity as DeityInstance
			if not provider:
				continue
			adjacent_deities.append(provider_pos)
			if region.size() >= 2:
				resonances[adjacent_cell.terrain] = true
	return {
		"area": own_region.size(),
		"area_multiplier": domain_area_multiplier(own_region.size()),
		"resonances": resonances,
		"adjacent_deities": adjacent_deities,
	}


func deity_stats(pos: Vector2i) -> Dictionary:
	var cell := get_cell(pos)
	var deity := cell.deity as DeityInstance if cell else null
	if not deity:
		return {}
	var context := deity_domain_context(pos)
	var resonances: Dictionary = context.resonances
	var area_multiplier := float(context.area_multiplier)
	var level_damage: Dictionary = GameDefinitions.BALANCE.deity_level_damage_multiplier
	var level_amount: Dictionary = GameDefinitions.BALANCE.deity_level_amount_multiplier
	var level_hp: Dictionary = GameDefinitions.BALANCE.deity_level_hp_multiplier
	var level_special: Dictionary = GameDefinitions.BALANCE.deity_level_special_multiplier
	var level_interval: Dictionary = GameDefinitions.BALANCE.deity_level_interval_multiplier
	var level_range: Dictionary = GameDefinitions.BALANCE.deity_level_range_bonus
	var result := {
		"terrain": cell.terrain,
		"counts": surrounding_terrain_counts(pos),
		"area": int(context.area),
		"area_multiplier": area_multiplier,
		"resonances": resonances,
		"max_hp": roundi(
			float(GameDefinitions.BALANCE.deity_base_hp)
			* float(level_hp.get(deity.level, 1.0))
		),
		"special_multiplier": float(level_special.get(deity.level, 1.0)),
		"special_every": int(GameDefinitions.BALANCE.special_trigger_every),
		"heal_shield_multiplier": 1.0,
		"damage_reduction": 0.0,
	}
	if deity.deity_type == GameDefinitions.DeityType.ATTACK:
		result.max_hp += roundi(ProgressManager.blessing_value("attack_hp"))
	if bool(resonances.get(GameDefinitions.TerrainType.FOREST, false)):
		result.max_hp = roundi(float(result.max_hp) * float(GameDefinitions.BALANCE.forest_resonance_hp_multiplier))
		result.heal_shield_multiplier = float(GameDefinitions.BALANCE.forest_resonance_heal_shield_multiplier)
	if bool(resonances.get(GameDefinitions.TerrainType.RIVER, false)):
		result.special_every = maxi(
			1,
			int(result.special_every) - int(GameDefinitions.BALANCE.river_resonance_trigger_reduction)
		)
	if deity.deity_type == GameDefinitions.DeityType.ATTACK:
		result.range = (
			float(GameDefinitions.BALANCE.attack_base_range)
			+ float(level_range.get(deity.level, 0.0))
		)
		if cell.terrain == GameDefinitions.TerrainType.MOUNTAIN:
			var mountain_level_range: Dictionary = (
				GameDefinitions.BALANCE.mountain_deity_level_range_bonus
			)
			result.range += float(mountain_level_range.get(deity.level, 0.0))
		if bool(resonances.get(GameDefinitions.TerrainType.MOUNTAIN, false)):
			result.range += float(GameDefinitions.BALANCE.mountain_resonance_range_bonus)
		result.interval = (
			float(GameDefinitions.BALANCE.attack_base_interval)
			* float(level_interval.get(deity.level, 1.0))
		)
		if bool(resonances.get(GameDefinitions.TerrainType.PLAIN, false)):
			result.interval *= float(GameDefinitions.BALANCE.plain_resonance_interval_multiplier)
		result.interval = maxf(
			float(GameDefinitions.BALANCE.minimum_attack_interval),
			float(result.interval)
		)
		result.damage = roundi(
			float(GameDefinitions.BALANCE.attack_base_damage)
			* area_multiplier
			* float(level_damage.get(deity.level, 1.0))
		)
	else:
		result.amount = (
			float(GameDefinitions.BALANCE.resource_base_amount)
			* area_multiplier
			* float(level_amount.get(deity.level, 1.0))
		)
		result.interval = (
			float(GameDefinitions.BALANCE.resource_base_interval)
			* float(level_interval.get(deity.level, 1.0))
		)
		if cell.terrain == GameDefinitions.TerrainType.PLAIN:
			result.interval *= float(GameDefinitions.BALANCE.resource_plain_interval_multiplier)
		elif cell.terrain == GameDefinitions.TerrainType.MOUNTAIN:
			result.interval *= float(GameDefinitions.BALANCE.resource_mountain_interval_multiplier)
			result.amount *= float(GameDefinitions.BALANCE.resource_mountain_base_amount_multiplier)
		if bool(resonances.get(GameDefinitions.TerrainType.PLAIN, false)):
			result.interval *= float(GameDefinitions.BALANCE.plain_resonance_interval_multiplier)
		if bool(resonances.get(GameDefinitions.TerrainType.MOUNTAIN, false)):
			result.amount += float(GameDefinitions.BALANCE.mountain_resonance_resource_bonus)
		result.interval = maxf(0.5, float(result.interval))
		if ProgressManager.blessing_value("resource_speed") > 0.0:
			result.interval *= 1.0 - ProgressManager.blessing_value("resource_speed")
	return result


func deity_upgrade_cost(current_level: int = 1) -> float:
	var costs: Dictionary = GameDefinitions.BALANCE.deity_upgrade_cost_by_level
	var cost := float(costs.get(current_level + 1, 0.0))
	return cost * (1.0 - ProgressManager.blessing_value("upgrade_discount"))


func upgrade_deity(pos: Vector2i) -> bool:
	if TurnManager.current_phase != TurnManager.Phase.BUILD:
		return false
	var deity := get_cell(pos).deity as DeityInstance
	if not deity or deity.level >= 3 or not ResourceManager.spend(deity_upgrade_cost(deity.level)):
		return false
	deity.level += 1
	_recalculate_deity(pos)
	deity.hp = deity.max_hp
	ProgressManager.add_stat("deities_upgraded")
	board_changed.emit()
	queue_redraw()
	return true


func deity_removal_cost() -> float:
	return float(GameDefinitions.BALANCE.deity_removal_cost)


func remove_deity(pos: Vector2i) -> bool:
	if TurnManager.current_phase != TurnManager.Phase.BUILD:
		GameManager.reject_action("战斗阶段不能移除神祇")
		return false
	if not is_in_bounds(pos) or not get_cell(pos).deity:
		return false
	var cost := deity_removal_cost()
	if not ResourceManager.spend(cost):
		GameManager.reject_action("移除需要 %.1f 神力" % cost)
		return false
	get_cell(pos).deity = null
	selected_pos = Vector2i(-1, -1)
	recalculate_all_deities()
	board_changed.emit()
	selection_cleared.emit()
	GameManager.post_message("神祇已移除")
	queue_redraw()
	return true


func _recalculate_deity(pos: Vector2i) -> void:
	var deity := get_cell(pos).deity as DeityInstance
	if not deity:
		return
	var stats := deity_stats(pos)
	var counts: Dictionary = stats.get("counts", {})
	if (
		int(counts.get("plain", 0)) > 0
		and int(counts.get("forest", 0)) > 0
		and int(counts.get("mountain", 0)) > 0
		and int(counts.get("river", 0)) > 0
	):
		ProgressManager.unlock("four_terrain")
	deity.max_hp = int(stats.max_hp)
	deity.hp = mini(deity.hp, deity.max_hp)


func recalculate_all_deities() -> void:
	for y in range(GRID_H):
		for x in range(GRID_W):
			_recalculate_deity(Vector2i(x, y))


func tick_combat(delta: float) -> void:
	if TurnManager.current_phase != TurnManager.Phase.COMBAT or not GameManager.is_game_running:
		return
	_update_enemy_core_activation()
	if pending_spawn_core != Vector2i(-1, -1):
		spawn_warning_time -= delta
		if spawn_warning_time <= 0.0:
			_spawn_from_enemy_core(pending_spawn_core)
			pending_spawn_core = Vector2i(-1, -1)
	if TurnManager.combat_time_remaining > 0.0:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and pending_spawn_core == Vector2i(-1, -1):
			_begin_spawn_warning()
			spawn_timer = _spawn_interval()
	_tick_deities(delta)
	_tick_enemies(delta)


func has_pending_spawn() -> bool:
	return pending_spawn_core != Vector2i(-1, -1)


func _spawn_interval() -> float:
	var interval := float(GameDefinitions.BALANCE.enemy_base_spawn_interval)
	interval *= 1.0 - float(GameManager.current_round - 1) * float(GameDefinitions.BALANCE.enemy_spawn_round_scale)
	interval *= 1.0 - fill_ratio() * float(GameDefinitions.BALANCE.enemy_spawn_fill_scale)
	var stage := _threat_stage()
	if stage == 1:
		interval *= float(GameDefinitions.BALANCE.enemy_mid_spawn_multiplier)
	elif stage >= 2:
		interval *= float(GameDefinitions.BALANCE.enemy_late_spawn_multiplier)
	if ProgressManager.current_map == 2:
		interval /= float(GameDefinitions.BALANCE.map_2_enemy_multiplier)
	interval *= 1.0 + float(destroyed_enemy_core_count()) * float(
		GameDefinitions.BALANCE.enemy_core_pressure_reduction
	)
	return maxf(float(GameDefinitions.BALANCE.enemy_min_spawn_interval), interval)


func _update_enemy_core_activation() -> void:
	var target_active := int(GameDefinitions.BALANCE.enemy_core_initial_active)
	var stage := _threat_stage()
	if stage == 1:
		target_active = int(GameDefinitions.BALANCE.enemy_core_mid_active)
	elif stage >= 2:
		target_active = int(GameDefinitions.BALANCE.enemy_core_late_active)
	for data in enemy_cores.values():
		var core_data := data as Dictionary
		var activation_rank := enemy_core_activation_order.find(int(core_data.index))
		core_data.active = activation_rank >= 0 and activation_rank < target_active and int(core_data.hp) > 0


func _begin_spawn_warning() -> bool:
	var candidates: Array[Vector2i] = []
	for pos in enemy_cores:
		var data: Dictionary = enemy_cores[pos]
		if bool(data.active) and int(data.hp) > 0 and _spawn_cell_for_core(pos) != Vector2i(-1, -1):
			candidates.append(pos)
	if candidates.is_empty():
		return false
	pending_spawn_core = candidates[GameManager.rng.randi_range(0, candidates.size() - 1)]
	spawn_warning_time = float(GameDefinitions.BALANCE.enemy_core_warning_time)
	spawn_warning_sequence += 1
	queue_redraw()
	return true


func prepare_build_spawn_warning() -> void:
	_update_enemy_core_activation()
	if pending_spawn_core == Vector2i(-1, -1):
		_begin_spawn_warning()
	else:
		spawn_warning_time = float(GameDefinitions.BALANCE.enemy_core_warning_time)
	queue_redraw()


func _enemy_core_direction_name(pos: Vector2i) -> String:
	var horizontal := "左" if pos.x < core_pos.x else ("右" if pos.x > core_pos.x else "")
	var vertical := "上" if pos.y < core_pos.y else ("下" if pos.y > core_pos.y else "")
	return "%s%s" % [horizontal, vertical]


func _spawn_cell_for_core(enemy_core_pos: Vector2i) -> Vector2i:
	var direction := Vector2i(
		signi(core_pos.x - enemy_core_pos.x),
		signi(core_pos.y - enemy_core_pos.y)
	)
	var candidates: Array[Vector2i] = []
	if direction.x != 0:
		candidates.append(enemy_core_pos + Vector2i(direction.x, 0))
	if direction.y != 0:
		candidates.append(enemy_core_pos + Vector2i(0, direction.y))
	if direction.x != 0 and direction.y != 0:
		candidates.append(enemy_core_pos + direction)
	for pos in candidates:
		if not is_in_bounds(pos) or is_enemy_core(pos):
			continue
		var cell := get_cell(pos)
		if not cell.enemy and not cell.deity and cell.terrain != GameDefinitions.TerrainType.MOUNTAIN:
			return pos
	return Vector2i(-1, -1)


func _spawn_from_enemy_core(enemy_core_pos: Vector2i) -> bool:
	var pos := _spawn_cell_for_core(enemy_core_pos)
	if pos == Vector2i(-1, -1):
		return false
	var cell := get_cell(pos)
	var stage := _threat_stage()
	var enemy := EnemyInstance.create(GameManager.current_round)
	var hp_multiplier := 1.0
	var attack_multiplier := 1.0
	if stage == 1:
		hp_multiplier = float(GameDefinitions.BALANCE.enemy_mid_hp_multiplier)
		attack_multiplier = float(GameDefinitions.BALANCE.enemy_mid_attack_multiplier)
	elif stage >= 2:
		hp_multiplier = float(GameDefinitions.BALANCE.enemy_late_hp_multiplier)
		attack_multiplier = float(GameDefinitions.BALANCE.enemy_late_attack_multiplier)
	if ProgressManager.current_map == 2:
		hp_multiplier *= float(GameDefinitions.BALANCE.map_2_enemy_multiplier)
		attack_multiplier *= float(GameDefinitions.BALANCE.map_2_enemy_multiplier)
	if stage >= 1:
		var archetype_roll := GameManager.rng.randf()
		if archetype_roll < 0.24:
			enemy.archetype = "swift"
			enemy.speed_multiplier = float(GameDefinitions.BALANCE.enemy_swift_speed_multiplier)
			hp_multiplier *= float(GameDefinitions.BALANCE.enemy_swift_hp_multiplier)
		elif archetype_roll > 0.78:
			enemy.archetype = "brute"
			enemy.speed_multiplier = float(GameDefinitions.BALANCE.enemy_brute_speed_multiplier)
			hp_multiplier *= float(GameDefinitions.BALANCE.enemy_brute_hp_multiplier)
	enemy.max_hp = maxi(1, roundi(float(enemy.max_hp) * hp_multiplier))
	enemy.hp = enemy.max_hp
	enemy.attack = maxi(1, roundi(float(enemy.attack) * attack_multiplier))
	enemy.visual_from = Vector2(pos)
	enemy.visual_to = Vector2(pos)
	enemy.visual_progress = 1.0
	cell.enemy = enemy
	ProgressManager.add_stat("enemy_spawned")
	board_changed.emit()
	return true


func _threat_stage() -> int:
	var mid := float(GameDefinitions.BALANCE.enemy_mid_fill)
	var late := float(GameDefinitions.BALANCE.enemy_late_fill)
	if ProgressManager.current_map == 2:
		mid = float(GameDefinitions.BALANCE.map_2_mid_fill)
		late = float(GameDefinitions.BALANCE.map_2_late_fill)
	if fill_ratio() >= late:
		return 2
	if fill_ratio() >= mid:
		return 1
	return 0


func _tick_deities(delta: float) -> void:
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			var deity := get_cell(pos).deity as DeityInstance
			if not deity:
				continue
			_recalculate_deity(pos)
			deity.action_timer -= delta
			if deity.action_timer > 0.0:
				continue
			var stats := deity_stats(pos)
			if deity.deity_type == GameDefinitions.DeityType.ATTACK:
				deity.action_timer = float(stats.interval)
				_attack_with_deity(pos, deity, stats)
			else:
				deity.action_timer = float(stats.interval)
				_produce_with_deity(pos, deity, stats)


func _attack_with_deity(pos: Vector2i, deity: DeityInstance, stats: Dictionary) -> void:
	var terrain := get_cell(pos).terrain
	var target := (
		_farthest_enemy(pos, float(stats.range))
		if terrain == GameDefinitions.TerrainType.MOUNTAIN
		else _nearest_enemy(pos, float(stats.range))
	)
	if target == Vector2i(-1, -1):
		var core_target := _nearest_enemy_core(pos, float(stats.range))
		if core_target != Vector2i(-1, -1):
			_play_deity_action_animation(deity, "attack", 0.5)
			_attack_enemy_core(pos, core_target, int(stats.damage))
		return
	_play_deity_action_animation(deity, "attack", 0.5)
	deity.attack_count += 1
	var special := deity.attack_count % int(stats.special_every) == 0
	var special_multiplier := float(stats.special_multiplier) if special else 1.0
	AudioManager.play_sfx_first([
		"attack_deity_%s" % AssetCatalog.terrain_suffix(terrain),
		"attack",
	], -3.0)
	var effect_profile := "deity_%s" % AssetCatalog.terrain_suffix(terrain)
	_damage_enemy(target, int(stats.damage), pos, Color("ffd76a"), effect_profile)
	match terrain:
		GameDefinitions.TerrainType.PLAIN:
			if special:
				_damage_enemy(
					target,
					maxi(1, roundi(float(stats.damage) * 0.7 * special_multiplier)),
					pos,
					Color("fff0a0"),
					effect_profile
				)
		GameDefinitions.TerrainType.MOUNTAIN:
			var splash_damage := roundi(float(stats.damage) * 0.55)
			if special:
				splash_damage = roundi(
					float(splash_damage)
					* float(GameDefinitions.BALANCE.mountain_special_splash_multiplier)
					* special_multiplier
				)
			for enemy_pos in get_all_enemy_positions():
				if enemy_pos != target and _manhattan(enemy_pos, target) <= int(GameDefinitions.BALANCE.mountain_splash_radius):
					_damage_enemy(
						enemy_pos,
						splash_damage,
						target,
						Color("e7b879"),
						"deity_mountain_splash"
					)
		GameDefinitions.TerrainType.RIVER:
			var excluded: Array = [target]
			var chain_source := target
			var chain_count := 1
			if special:
				chain_count += int(GameDefinitions.BALANCE.river_special_extra_chains)
			for _chain_index in range(chain_count):
				var chain := _nearest_enemy(
					chain_source,
					float(GameDefinitions.BALANCE.river_chain_range),
					excluded
				)
				if chain == Vector2i(-1, -1):
					break
				_damage_enemy(
					chain,
					maxi(1, roundi(float(stats.damage) * (0.75 if not special else special_multiplier))),
					chain_source,
					Color("70cfff"),
					"deity_river_chain"
				)
				excluded.append(chain)
				chain_source = chain
		GameDefinitions.TerrainType.FOREST:
			var enemy := get_cell(target).enemy as EnemyInstance
			if enemy:
				var duration := float(GameDefinitions.BALANCE.forest_slow_duration)
				if special:
					duration += (
						float(GameDefinitions.BALANCE.forest_special_slow_duration)
						* special_multiplier
					)
				enemy.slow_timer = maxf(enemy.slow_timer, duration)
				_spawn_catalog_effect("status_deity_forest_slow", target, 0.6)
			if special:
				_heal_deity(
					pos,
					float(deity.max_hp)
					* float(GameDefinitions.BALANCE.forest_special_self_heal_ratio)
					* special_multiplier
				)


func _farthest_enemy(origin: Vector2i, max_range: float) -> Vector2i:
	var dangerous := Vector2i(-1, -1)
	var dangerous_core_distance := 9999
	var farthest := Vector2i(-1, -1)
	var farthest_distance := -1
	for pos in get_all_enemy_positions():
		var distance := _manhattan(origin, pos)
		if float(distance) > max_range + float(GameDefinitions.BALANCE.attack_range_tolerance):
			continue
		var core_distance := _manhattan(pos, core_pos)
		if (
			core_distance <= int(GameDefinitions.BALANCE.core_danger_range)
			and core_distance < dangerous_core_distance
		):
			dangerous = pos
			dangerous_core_distance = core_distance
		if distance > farthest_distance:
			farthest = pos
			farthest_distance = distance
	return dangerous if dangerous != Vector2i(-1, -1) else farthest


func _nearest_enemy_core(origin: Vector2i, max_range: float) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for pos in enemy_cores:
		var data: Dictionary = enemy_cores[pos]
		if int(data.hp) <= 0 or not bool(data.active):
			continue
		var distance := float(_manhattan(origin, pos))
		if (
			distance <= max_range + float(GameDefinitions.BALANCE.attack_range_tolerance)
			and distance < best_distance
		):
			best = pos
			best_distance = distance
	return best


func _attack_enemy_core(source: Vector2i, target: Vector2i, damage: int) -> void:
	var data: Dictionary = enemy_cores.get(target, {})
	if data.is_empty() or int(data.hp) <= 0 or not bool(data.active):
		return
	var terrain := get_cell(source).terrain
	var profile := "deity_%s" % AssetCatalog.terrain_suffix(terrain)
	AudioManager.play_sfx_first(["attack_deity_%s" % AssetCatalog.terrain_suffix(terrain), "attack"], -3.0)
	attack_visual_requested.emit(source, target, Color("ffb64d"), damage, profile)
	data.hp = maxi(0, int(data.hp) - damage)
	if int(data.hp) <= 0:
		data.active = false
		ResourceManager.add_divine_power(float(GameDefinitions.BALANCE.enemy_core_reward))
		enemy_core_destroyed.emit(target)
		if AssetCatalog.texture("enemy_core_explosion") or AssetCatalog.animation("enemy_core_explosion"):
			_spawn_catalog_effect("enemy_core_explosion", target, 1.0)
		else:
			_spawn_catalog_effect("cell_collapse", target, 1.0)
		GameManager.post_message(
			"敌方核心已摧毁：该方向停止出怪，获得 %.1f 神力"
			% float(GameDefinitions.BALANCE.enemy_core_reward)
		)
	board_changed.emit()
	queue_redraw()
	_check_victory()


func _produce_with_deity(pos: Vector2i, deity: DeityInstance, stats: Dictionary) -> void:
	_play_deity_action_animation(deity, "produce", 0.65)
	var produced := float(stats.amount)
	ResourceManager.add_divine_power(produced)
	ProgressManager.add_stat("resource_income_round", produced)
	ProgressManager.add_stat("resource_income_total", produced)
	var terrain := get_cell(pos).terrain
	AudioManager.play_sfx_first([
		"produce_deity_%s" % AssetCatalog.terrain_suffix(terrain),
		"resource_produce",
	], -5.0)
	deity.production_count += 1
	if deity.production_count % int(stats.special_every) != 0:
		return
	var special_multiplier := float(stats.special_multiplier)
	match terrain:
		GameDefinitions.TerrainType.PLAIN:
			var bonus := produced * special_multiplier
			ResourceManager.add_divine_power(bonus)
			ProgressManager.add_stat("resource_income_round", bonus)
			ProgressManager.add_stat("resource_income_total", bonus)
		GameDefinitions.TerrainType.MOUNTAIN:
			var bonus := produced * 0.5 * special_multiplier
			ResourceManager.add_divine_power(bonus)
			ProgressManager.add_stat("resource_income_round", bonus)
			ProgressManager.add_stat("resource_income_total", bonus)
		GameDefinitions.TerrainType.RIVER:
			if GameManager.scene_root and GameManager.scene_root.has_method("grant_free_refresh"):
				GameManager.scene_root.grant_free_refresh()
		GameDefinitions.TerrainType.FOREST:
			_forest_life_bloom(pos, special_multiplier)


func _play_deity_action_animation(
	deity: DeityInstance,
	animation_name: String,
	duration: float
) -> void:
	deity.visual_animation = animation_name
	deity.visual_animation_started_at = pulse_time
	deity.visual_animation_duration = duration


func _forest_life_bloom(origin: Vector2i, special_multiplier: float) -> void:
	var targets: Dictionary = {origin: true}
	var context := deity_domain_context(origin)
	for target in context.adjacent_deities:
		targets[target] = true
	for target in targets:
		var deity := get_cell(target).deity as DeityInstance
		if not deity:
			continue
		var stats := deity_stats(target)
		var heal := (
			float(deity.max_hp)
			* float(GameDefinitions.BALANCE.forest_bloom_heal_ratio)
			* float(stats.heal_shield_multiplier)
			* special_multiplier
		)
		_heal_deity(target, heal, true)


func _heal_deity(pos: Vector2i, amount: float, overflow_to_shield: bool = false) -> void:
	var deity := get_cell(pos).deity as DeityInstance
	if not deity:
		return
	var missing := maxi(0, deity.max_hp - deity.hp)
	var healed := mini(missing, roundi(amount))
	deity.hp += healed
	if not overflow_to_shield:
		return
	var overflow := maxf(0.0, amount - float(healed))
	var shield_cap := (
		float(deity.max_hp)
		* float(GameDefinitions.BALANCE.forest_bloom_shield_cap_ratio)
		* float(deity_stats(pos).heal_shield_multiplier)
	)
	deity.shield = minf(shield_cap, deity.shield + overflow)


func _tick_enemies(delta: float) -> void:
	var positions := get_all_enemy_positions()
	for original in positions:
		var cell := get_cell(original)
		var enemy := cell.enemy as EnemyInstance if cell else null
		if not enemy:
			continue
		enemy.visual_progress = minf(
			1.0,
			enemy.visual_progress + delta / maxf(0.05, enemy.visual_duration)
		)
		enemy.slow_timer = maxf(0.0, enemy.slow_timer - delta)
		enemy.move_timer -= delta
		if enemy.move_timer > 0.0:
			continue
		var multiplier := float(GameDefinitions.BALANCE.forest_slow_multiplier) if enemy.slow_timer > 0.0 else 1.0
		multiplier *= _terrain_path_cost(cell.terrain)
		enemy.move_timer = (
			float(GameDefinitions.BALANCE.enemy_move_interval)
			* multiplier
			* enemy.speed_multiplier
		)
		_enemy_step(original, enemy)


func _enemy_step(origin: Vector2i, enemy: EnemyInstance) -> void:
	for adjacent in neighbors(origin):
		if adjacent == core_pos:
			AudioManager.play_sfx("attack", -3.0, 0.85)
			AudioManager.play_sfx("hit", -3.0, 0.85)
			GameManager.damage_core(enemy.attack)
			get_cell(origin).enemy = null
			_pollute_at(origin)
			board_changed.emit()
			return
		var deity := get_cell(adjacent).deity as DeityInstance
		if deity:
			_play_enemy_action_animation(enemy, "attack", 0.5)
			AudioManager.play_sfx("attack", -3.0, 0.85)
			AudioManager.play_sfx("hit", -3.0, 0.85)
			attack_visual_requested.emit(origin, adjacent, Color("ff6b62"), enemy.attack, "enemy")
			_damage_deity(adjacent, enemy.attack)
			if deity.hp <= 0:
				get_cell(adjacent).deity = null
			board_changed.emit()
			return
	var path := _path_to_core_or_blocker(origin)
	if path.size() < 2:
		return
	var next: Vector2i = path[1]
	if next == core_pos:
		AudioManager.play_sfx("attack", -3.0, 0.85)
		AudioManager.play_sfx("hit", -3.0, 0.85)
		GameManager.damage_core(enemy.attack)
		get_cell(origin).enemy = null
		_pollute_at(origin)
	elif get_cell(next).deity:
		_play_enemy_action_animation(enemy, "attack", 0.5)
		AudioManager.play_sfx("attack", -3.0, 0.85)
		AudioManager.play_sfx("hit", -3.0, 0.85)
		attack_visual_requested.emit(origin, next, Color("ff6b62"), enemy.attack, "enemy")
		var blocker := get_cell(next).deity as DeityInstance
		_damage_deity(next, enemy.attack)
		if blocker.hp <= 0:
			get_cell(next).deity = null
	else:
		get_cell(origin).enemy = null
		get_cell(next).enemy = enemy
		enemy.visual_from = Vector2(origin)
		enemy.visual_to = Vector2(next)
		enemy.visual_progress = 0.0
		enemy.visual_duration = minf(
			0.42,
			maxf(0.16, float(GameDefinitions.BALANCE.enemy_move_interval) * 0.72)
		)
	board_changed.emit()


func _damage_deity(pos: Vector2i, raw_damage: int) -> void:
	var deity := get_cell(pos).deity as DeityInstance
	if not deity:
		return
	var stats := deity_stats(pos)
	var damage := float(raw_damage) * (1.0 - float(stats.get("damage_reduction", 0.0)))
	if deity.shield > 0.0:
		var absorbed := minf(deity.shield, damage)
		deity.shield -= absorbed
		damage -= absorbed
	if damage > 0.0:
		deity.hp -= maxi(1, roundi(damage))


func _play_enemy_action_animation(
	enemy: EnemyInstance,
	animation_name: String,
	duration: float
) -> void:
	enemy.visual_animation = animation_name
	enemy.visual_animation_started_at = pulse_time
	enemy.visual_animation_duration = duration


func _path_to_core_or_blocker(start: Vector2i) -> Array[Vector2i]:
	var core_path := _weighted_path(start, false)
	if core_path.size() >= 2:
		return core_path
	return _weighted_path(start, true)


func _weighted_path(
	start: Vector2i,
	stop_at_deity: bool,
	terrain_overrides: Dictionary = {},
	ignore_enemies: bool = false,
	ignore_deities: bool = false
) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start]
	var parent: Dictionary = {}
	var distance: Dictionary = {start: 0.0}
	var settled: Dictionary = {}
	var goal := Vector2i(-1, -1)
	while not frontier.is_empty():
		var best_index := 0
		for index in range(1, frontier.size()):
			if float(distance[frontier[index]]) < float(distance[frontier[best_index]]):
				best_index = index
		var current: Vector2i = frontier.pop_at(best_index)
		if settled.has(current):
			continue
		settled[current] = true
		if current == core_pos or (stop_at_deity and current != start and get_cell(current).deity):
			goal = current
			break
		for next in neighbors(current):
			if settled.has(next):
				continue
			if next != core_pos and is_enemy_core(next) and next != start:
				continue
			var cell := get_cell(next)
			var terrain := _terrain_for_path(next, terrain_overrides)
			if terrain == GameDefinitions.TerrainType.MOUNTAIN:
				continue
			if not ignore_enemies and cell.enemy and next != start:
				continue
			if cell.deity and not stop_at_deity and not ignore_deities:
				continue
			var next_distance := float(distance[current]) + _terrain_path_cost(terrain)
			if not distance.has(next) or next_distance < float(distance[next]):
				distance[next] = next_distance
				parent[next] = current
				if not frontier.has(next):
					frontier.append(next)
	if goal == Vector2i(-1, -1):
		return [start]
	var path: Array[Vector2i] = [goal]
	var cursor := goal
	while cursor != start:
		cursor = parent[cursor]
		path.push_front(cursor)
	return path


func _terrain_for_path(pos: Vector2i, terrain_overrides: Dictionary = {}) -> int:
	if pos == core_pos:
		return GameDefinitions.TerrainType.PLAIN
	if terrain_overrides.has(pos):
		return int(terrain_overrides[pos])
	var cell := get_cell(pos)
	return cell.terrain if cell else GameDefinitions.TerrainType.NONE


func _terrain_path_cost(terrain: int) -> float:
	if terrain == GameDefinitions.TerrainType.MOUNTAIN:
		return INF
	var costs: Dictionary = GameDefinitions.BALANCE.terrain_path_cost
	return float(costs.get(terrain, 1.0))


func _path_total_cost(path: Array, terrain_overrides: Dictionary = {}) -> float:
	if path.size() <= 1:
		return INF
	var total := 0.0
	for index in range(1, path.size()):
		total += _terrain_path_cost(_terrain_for_path(path[index], terrain_overrides))
	return total


func get_all_enemy_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			if get_cell(pos).enemy:
				result.append(pos)
	return result


func enemy_description(pos: Vector2i) -> String:
	var cell := get_cell(pos)
	var enemy := cell.enemy as EnemyInstance if cell else null
	if not enemy:
		return ""
	var terrain_name: String = str(GameDefinitions.TERRAIN_NAMES.get(cell.terrain, "虚空"))
	var movement_state: String = (
		"受到减速，移动间隔延长"
		if enemy.slow_timer > 0.0
		else "正常向中央核心移动"
	)
	return "生命：%d / %d\n攻击：%d\n所在位置：%s\n污染：%d / %d\n状态：%s\n\n接近核心或神祇后会发动攻击；死亡时污染当前有效地形格。" % [
		enemy.hp,
		enemy.max_hp,
		enemy.attack,
		terrain_name,
		cell.pollution,
		int(GameDefinitions.BALANCE.cell_pollution_limit),
		movement_state,
	]


func _nearest_enemy(origin: Vector2i, max_range: float, excluded: Array = []) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_core_distance := 9999
	for pos in get_all_enemy_positions():
		if (
			pos in excluded
			or float(_manhattan(origin, pos))
				> max_range + float(GameDefinitions.BALANCE.attack_range_tolerance)
		):
			continue
		var core_distance := _manhattan(pos, core_pos)
		if core_distance < best_core_distance:
			best = pos
			best_core_distance = core_distance
	return best


func _damage_enemy(
	target: Vector2i,
	damage: int,
	source: Vector2i,
	color: Color,
	effect_profile: String
) -> void:
	var enemy := get_cell(target).enemy as EnemyInstance
	if not enemy:
		return
	attack_visual_requested.emit(source, target, color, damage, effect_profile)
	AudioManager.play_sfx("hit", -4.0)
	enemy.hp -= damage
	if enemy.hp <= 0:
		get_cell(target).enemy = null
		_play_enemy_death(true)
		_pollute_at(target)
	board_changed.emit()


func _pollute_at(pos: Vector2i) -> void:
	var cell := get_cell(pos)
	if not cell or cell.terrain == GameDefinitions.TerrainType.NONE:
		return
	cell.pollution += 1
	ProgressManager.add_stat("pollution_events")
	AudioManager.play_sfx("pollution_growth", -3.0)
	_spawn_catalog_effect("pollution_growth", pos, 0.65)
	var limit := pollution_limit()
	GameManager.post_message("格子污染：%d/%d" % [cell.pollution, limit])
	if cell.pollution >= limit:
		_destroy_cell(pos)


func _destroy_cell(pos: Vector2i) -> void:
	var cell := get_cell(pos)
	if not cell or cell.terrain == GameDefinitions.TerrainType.NONE:
		return
	cell.terrain = GameDefinitions.TerrainType.NONE
	cell.pollution = 0
	cell.piece_id = -1
	cell.visual_rotation = GameManager.rng.randi_range(0, 3)
	cell.deity = null
	cell.was_collapsed = true
	ProgressManager.add_stat("collapsed_cells")
	recalculate_all_deities()
	cell_destroyed.emit(pos)
	AudioManager.play_sfx("cell_collapse", -1.0)
	_spawn_catalog_effect("cell_collapse", pos, 0.9)
	GameManager.post_message("污染失控，该格已崩解为虚空")
	board_changed.emit()


func pollution_limit() -> int:
	return int(GameDefinitions.BALANCE.cell_pollution_limit) + roundi(
		ProgressManager.blessing_value("pollution_limit")
	)


func _play_enemy_death(count_as_kill: bool) -> void:
	if not count_as_kill:
		return
	ProgressManager.add_stat("enemy_killed")
	enemy_death_sfx_step = mini(7, enemy_death_sfx_step + 1)
	AudioManager.play_sfx_first(
		["enemy_death_%d" % enemy_death_sfx_step, "enemy_death"],
		-2.0
	)


func deity_ability_description(deity_type: int, terrain: int) -> String:
	if deity_type == GameDefinitions.DeityType.ATTACK:
		match terrain:
			GameDefinitions.TerrainType.PLAIN:
				return "能力：连续直射。稳定攻击单个目标。"
			GameDefinitions.TerrainType.MOUNTAIN:
				return "能力：崩岩投射。命中时对目标附近敌人造成范围伤害。"
			GameDefinitions.TerrainType.RIVER:
				return "能力：回澜弹射。命中后额外弹向附近另一名敌人。"
			GameDefinitions.TerrainType.FOREST:
				return "能力：荆蔓追猎。命中后使敌人短时间减速。"
	else:
		match terrain:
			GameDefinitions.TerrainType.PLAIN:
				return "能力：丰穗循环。以较短间隔稳定生产神力。"
			GameDefinitions.TerrainType.MOUNTAIN:
				return "能力：山岳蕴藏。生产较慢，但每次获得更多神力。"
			GameDefinitions.TerrainType.RIVER:
				return "能力：涌泉循环。正常生产，并周期性积蓄免费刷新。"
			GameDefinitions.TerrainType.FOREST:
				return "能力：生息滋养。正常生产，并周期性治疗周围受伤神祇。"
	return ""


func selected_deity_description(pos: Vector2i) -> String:
	var cell := get_cell(pos)
	var deity := cell.deity as DeityInstance if cell else null
	if not deity:
		return ""
	var stats := deity_stats(pos)
	if stats.is_empty():
		return ""
	var function_text := ""
	if deity.deity_type == GameDefinitions.DeityType.ATTACK:
		match cell.terrain:
			GameDefinitions.TerrainType.PLAIN:
				function_text = "持续快速攻击单个目标。"
			GameDefinitions.TerrainType.FOREST:
				function_text = "攻击会使敌人减速。"
			GameDefinitions.TerrainType.MOUNTAIN:
				function_text = "攻击命中后会对附近敌人造成溅射伤害。"
			GameDefinitions.TerrainType.RIVER:
				function_text = "攻击命中后会继续弹射到附近敌人。"
		return "等级：%d\n功能：%s\n\n生命：%d / %d\n伤害：%d\n射程：%.1f 格\n攻击间隔：%.2f 秒" % [
			deity.level,
			function_text,
			deity.hp,
			deity.max_hp,
			int(stats.damage),
			float(stats.range),
			float(stats.interval),
		]
	match cell.terrain:
		GameDefinitions.TerrainType.PLAIN:
			function_text = "以更短间隔持续生产神力。"
		GameDefinitions.TerrainType.FOREST:
			function_text = "生产神力，并周期性治疗附近神祇。"
		GameDefinitions.TerrainType.MOUNTAIN:
			function_text = "生产速度较慢，但单次产量较高。"
		GameDefinitions.TerrainType.RIVER:
			function_text = "生产神力，并周期性提供免费商店刷新。"
	return "等级：%d\n功能：%s\n\n生命：%d / %d\n单次产量：%.2f\n生产间隔：%.2f 秒" % [
		deity.level,
		function_text,
		deity.hp,
		deity.max_hp,
		float(stats.amount),
		float(stats.interval),
	]
func deity_function_description(pos: Vector2i) -> String:
	var cell := get_cell(pos)
	var deity := cell.deity as DeityInstance if cell else null
	if not deity:
		return ""
	if deity.deity_type == GameDefinitions.DeityType.ATTACK:
		match cell.terrain:
			GameDefinitions.TerrainType.PLAIN:
				return "快速直射；特殊攻击进行连续射击。"
			GameDefinitions.TerrainType.FOREST:
				return "追踪并减速；特殊攻击强化减速并自愈。"
			GameDefinitions.TerrainType.MOUNTAIN:
				return "远程抛射并溅射；优先处理远处或危险目标。"
			GameDefinitions.TerrainType.RIVER:
				return "攻击会弹射；特殊攻击增加弹射次数。"
	match cell.terrain:
		GameDefinitions.TerrainType.PLAIN:
			return "基础生产较快；特殊生产额外产出一次。"
		GameDefinitions.TerrainType.FOREST:
			return "特殊生产释放生命绽放，治疗并提供护盾。"
		GameDefinitions.TerrainType.MOUNTAIN:
			return "生产较慢、单次产量较高；特殊生产额外产出。"
		GameDefinitions.TerrainType.RIVER:
			return "特殊生产提供一次免费商店刷新。"
	return ""


func terrain_deity_preview(pos: Vector2i, deity_type: int) -> String:
	var cell := get_cell(pos)
	if not cell or cell.terrain == GameDefinitions.TerrainType.NONE:
		return ""
	return deity_form_name(pos, deity_type)


func _check_victory() -> void:
	if (
		completion_emitted
		or fill_ratio() < 0.999
		or living_enemy_core_count() > 0
		or GameManager.core_hp <= 0
	):
		return
	if activated_anchor_count() < required_anchor_count():
		GameManager.post_message(
			"地图已填满，但仍有 %d 个地形锚点尚未激活"
			% (required_anchor_count() - activated_anchor_count())
		)
		return
	completion_emitted = true
	map_completed.emit()


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_game_running:
		return
	if event is InputEventMouseMotion:
		var local_mouse := get_local_mouse_position()
		var visual_enemy := _enemy_at_visual_position(local_mouse)
		var new_hover := visual_enemy if visual_enemy != Vector2i(-1, -1) else world_to_grid(local_mouse)
		if new_hover != hover_pos:
			hover_pos = new_hover
			if (
				is_in_bounds(hover_pos)
				and not preview_terrain
			):
				if get_cell(hover_pos).enemy:
					enemy_hovered.emit(hover_pos)
				elif hover_pos == core_pos:
					core_hovered.emit()
				elif get_cell(hover_pos).piece_id >= 0:
					terrain_hovered.emit(hover_pos)
				else:
					map_hover_exited.emit()
			else:
				map_hover_exited.emit()
		preview_pos = hover_pos
		queue_redraw()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and preview_terrain:
			preview_rotation = (preview_rotation + 1) % 4
			queue_redraw()
		elif event.keycode == KEY_F11:
			_toggle_fullscreen()
		elif event.keycode == KEY_ESCAPE:
			if preview_terrain and GameManager.scene_root and GameManager.scene_root.has_method("cancel_active_tile_purchase"):
				GameManager.scene_root.cancel_active_tile_purchase()
			else:
				clear_preview()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
		and event.pressed
	):
		if preview_terrain and GameManager.scene_root and GameManager.scene_root.has_method("cancel_active_tile_purchase"):
			GameManager.scene_root.cancel_active_tile_purchase()
		else:
			clear_preview()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		var visual_enemy := _enemy_at_visual_position(get_local_mouse_position())
		_handle_click(
			visual_enemy
			if visual_enemy != Vector2i(-1, -1)
			else world_to_grid(get_local_mouse_position())
		)


func _enemy_at_visual_position(local_position: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for pos in get_all_enemy_positions():
		var enemy := get_cell(pos).enemy as EnemyInstance
		if not enemy:
			continue
		var visual_grid := enemy.visual_from.lerp(enemy.visual_to, _smoothstep(enemy.visual_progress))
		var center := visual_grid * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5
		var distance := center.distance_to(local_position)
		if distance <= CELL_SIZE * 0.58 and distance < best_distance:
			best = pos
			best_distance = distance
	return best


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		else DisplayServer.WINDOW_MODE_FULLSCREEN
	)


func _handle_click(pos: Vector2i) -> void:
	if not is_in_bounds(pos):
		return
	if pos == core_pos:
		selected_pos = pos
		core_selected.emit()
		queue_redraw()
		return
	if get_cell(pos).enemy:
		selected_pos = pos
		range_reveal_started_at = pulse_time
		enemy_selected.emit(pos)
		enemy_hovered.emit(pos)
		queue_redraw()
		return
	if migration_selecting_source:
		if get_cell(pos).deity:
			begin_deity_migration(pos)
		else:
			GameManager.reject_action("请先选择一座已有神祇")
		return
	if migration_source != Vector2i(-1, -1):
		if migrate_deity(pos):
			return
		if pos == migration_source:
			migration_source = Vector2i(-1, -1)
			queue_redraw()
		return
	if (
		not preview_terrain
		and preview_deity_type < 0
		and pos != core_pos
		and get_cell(pos).piece_id < 0
	):
		selected_pos = Vector2i(-1, -1)
		selection_cleared.emit()
		map_hover_exited.emit()
		queue_redraw()
		return
	if TurnManager.current_phase == TurnManager.Phase.BUILD:
		if preview_terrain:
			if get_cell(pos).piece_id >= 0:
				if GameManager.scene_root and GameManager.scene_root.has_method("cancel_active_tile_purchase"):
					GameManager.scene_root.cancel_active_tile_purchase()
			else:
				place_preview_terrain()
				return
		if preview_deity_type >= 0:
			place_deity(pos)
			return
	if get_cell(pos).deity:
		selected_pos = pos
		range_reveal_started_at = pulse_time
		deity_selected.emit(pos)
		queue_redraw()
		return
	elif TurnManager.current_phase == TurnManager.Phase.BUILD and get_cell(pos).piece_id >= 0:
		var existing_deity_pos := region_deity_position(pos)
		if existing_deity_pos != Vector2i(-1, -1):
			selected_pos = existing_deity_pos
			deity_selected.emit(existing_deity_pos)
		else:
			selected_pos = pos
			terrain_selected.emit(pos)
		queue_redraw()


func _draw() -> void:
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			var cell := get_cell(pos)
			var rect := Rect2(grid_to_world(pos), Vector2(CELL_SIZE, CELL_SIZE))
			draw_rect(rect, GameDefinitions.TERRAIN_COLORS[cell.terrain])
			var terrain_modulate := (
				Color(0.68, 0.72, 0.76, 0.82)
				if cell.terrain == GameDefinitions.TerrainType.NONE
				else Color.WHITE
			)
			if cell.terrain == GameDefinitions.TerrainType.NONE:
				_draw_void_cell(pos, rect, terrain_modulate)
				if cell.anchor_terrain != GameDefinitions.TerrainType.NONE:
					_draw_anchor(rect, cell.anchor_terrain)
			else:
				_draw_catalog_texture(
					AssetCatalog.terrain_texture_key(cell.terrain),
					rect,
					0.0,
					terrain_modulate
				)
			if cell.terrain == GameDefinitions.TerrainType.NONE:
				draw_rect(rect, Color(0.16, 0.18, 0.22, 0.28))
			_draw_domain_outer_edges(pos, rect, cell.terrain)
			if cell.terrain != GameDefinitions.TerrainType.NONE:
				_draw_terrain_particles(pos, rect, cell.terrain)
			if cell.pollution > 0:
				var pollution_key := "pollution_stage_%d" % mini(cell.pollution, 2)
				if not AssetCatalog.texture(pollution_key) and not AssetCatalog.animation(pollution_key):
					pollution_key = "terrain_pollution"
				_draw_animated_or_texture(
					pollution_key,
					rect,
					"idle",
					Color.WHITE
				)
	_draw_enemy_cores()
	_draw_core()
	_draw_entities()
	_draw_preview()
	_draw_preview_routes()
	_draw_focus_desaturation()
	_draw_selected_attack_range()
	_draw_migration_targets()
	if selected_pos != Vector2i(-1, -1):
		var selection_cells: Array[Vector2i] = []
		if get_cell(selected_pos).deity and migration_source == Vector2i(-1, -1):
			selection_cells.assign(terrain_region(selected_pos))
		else:
			selection_cells.append(selected_pos)
		for region_pos in selection_cells:
			var selected_rect := Rect2(
				grid_to_world(region_pos) + Vector2(2, 2),
				Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
			)
			_draw_selection_marker(selected_rect)


func _draw_domain_outer_edges(pos: Vector2i, rect: Rect2, terrain: int) -> void:
	if terrain == GameDefinitions.TerrainType.NONE:
		draw_rect(rect.grow(-1.0), Color("353945"), false, 1.0)
		return
	var outline := Color(0.09, 0.11, 0.12, 0.46)
	var sides := [
		[Vector2i.UP, rect.position, Vector2(rect.end.x, rect.position.y)],
		[Vector2i.DOWN, Vector2(rect.position.x, rect.end.y), rect.end],
		[Vector2i.LEFT, rect.position, Vector2(rect.position.x, rect.end.y)],
		[Vector2i.RIGHT, Vector2(rect.end.x, rect.position.y), rect.end],
	]
	for side in sides:
		var adjacent: Vector2i = pos + Vector2i(side[0])
		if not is_in_bounds(adjacent) or get_cell(adjacent).terrain != terrain:
			draw_line(Vector2(side[1]), Vector2(side[2]), outline, 1.5, true)


func _draw_focus_desaturation() -> void:
	if selected_pos == Vector2i(-1, -1) or not is_in_bounds(selected_pos):
		return
	var cell := get_cell(selected_pos)
	if not cell.deity and not cell.enemy:
		return
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(GRID_W * CELL_SIZE, GRID_H * CELL_SIZE)),
		Color(0.16, 0.17, 0.19, 0.36)
	)
	if cell.deity:
		var rect := Rect2(grid_to_world(selected_pos) + Vector2.ONE, Vector2(CELL_SIZE - 2, CELL_SIZE - 2))
		_draw_deity(cell.deity as DeityInstance, cell.terrain, rect, selected_pos)
	elif cell.enemy:
		var enemy := cell.enemy as EnemyInstance
		var visual_grid := enemy.visual_from.lerp(enemy.visual_to, _smoothstep(enemy.visual_progress))
		var enemy_rect := Rect2(
			visual_grid * CELL_SIZE + Vector2.ONE,
			Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
		)
		_draw_enemy(enemy, enemy_rect)


func _draw_migration_targets() -> void:
	if migration_source == Vector2i(-1, -1):
		return
	for pos in terrain_region(migration_source):
		if pos == migration_source or get_cell(pos).deity or get_cell(pos).enemy:
			continue
		var rect := Rect2(grid_to_world(pos) + Vector2(6, 6), Vector2(CELL_SIZE - 12, CELL_SIZE - 12))
		var pulse := 0.2 + (sin(pulse_time * 4.0 + float(index_of(pos))) + 1.0) * 0.08
		draw_circle(rect.get_center(), rect.size.x * 0.42, Color(0.3, 0.9, 1.0, pulse))
		draw_arc(rect.get_center(), rect.size.x * 0.44, 0.0, TAU, 32, Color(0.7, 0.95, 1.0, 0.82), 2.0)


func _draw_enemy_cores() -> void:
	for pos in enemy_cores:
		var data: Dictionary = enemy_cores[pos]
		if int(data.hp) <= 0:
			continue
		var rect := Rect2(grid_to_world(pos) + Vector2(3, 3), Vector2(CELL_SIZE - 6, CELL_SIZE - 6))
		var active: bool = bool(data.active)
		var warning: bool = pos == pending_spawn_core
		var pulse := (sin(pulse_time * (8.0 if warning else 2.2) + float(data.index)) + 1.0) * 0.5
		var breath_scale := lerpf(0.94, 1.08, pulse) if active else lerpf(0.97, 1.02, pulse)
		var breath_size := rect.size * breath_scale
		rect = Rect2(rect.get_center() - breath_size * 0.5, breath_size)
		var color := Color(1.0, 0.12, 0.15, 0.88 if active else 0.42)
		if warning:
			color = Color(1.0, 0.04, 0.04, 0.75 + pulse * 0.25)
			draw_circle(rect.get_center(), 29.0 + pulse * 5.0, Color(1.0, 0.05, 0.05, 0.14))
		var core_texture := AssetCatalog.texture("enemy_core")
		if core_texture:
			_draw_catalog_texture(
				"enemy_core",
				rect,
				Vector2(core_pos - pos).angle() + PI * 0.5,
				Color(1, 1, 1, 1.0 if active else 0.58)
			)
		else:
			draw_circle(rect.get_center(), 19.0, Color(0.18, 0.02, 0.08, 0.94))
			draw_arc(rect.get_center(), 21.0, 0.0, TAU, 32, color, 3.0)
			draw_circle(rect.get_center(), 8.0 + pulse * 2.0, color)
		if warning:
			var direction := Vector2(core_pos - pos).normalized()
			var tip := rect.get_center() + direction * 31.0
			var warning_texture := AssetCatalog.texture("enemy_spawn_warning")
			if warning_texture:
				var warning_rect := Rect2(tip - Vector2(15, 15), Vector2(30, 30))
				_draw_catalog_texture(
					"enemy_spawn_warning",
					warning_rect,
					direction.angle(),
					Color.WHITE
				)
			else:
				draw_colored_polygon(
					PackedVector2Array([
						tip,
						tip - direction.rotated(0.55) * 12.0,
						tip - direction.rotated(-0.55) * 12.0,
					]),
					Color(1.0, 0.12, 0.08, 0.92)
				)
		_draw_health_bar(rect.get_center() + Vector2(0, 24), int(data.hp), int(data.max_hp), 38.0)


func _draw_selected_attack_range() -> void:
	if selected_pos == Vector2i(-1, -1):
		return
	var selected_cell := get_cell(selected_pos)
	var deity := selected_cell.deity as DeityInstance
	var enemy := selected_cell.enemy as EnemyInstance
	if not deity and not enemy:
		return
	var attack_range := (
		float(deity_stats(selected_pos).range)
			+ float(GameDefinitions.BALANCE.attack_range_tolerance)
		if deity and deity.deity_type == GameDefinitions.DeityType.ATTACK
		else (
			float(GameDefinitions.BALANCE.resource_effect_range)
			if deity
			else 1.0
		)
	)
	var reveal := clampf((pulse_time - range_reveal_started_at) / 0.34, 0.0, 1.0)
	reveal = smoothstep(0.0, 1.0, reveal)
	var center := grid_to_world(selected_pos) + Vector2.ONE * CELL_SIZE * 0.5
	var visual_radius := (attack_range + 0.45) * CELL_SIZE * reveal
	var range_color := (
		Color(1.0, 0.72, 0.18, 0.13)
		if deity and deity.deity_type == GameDefinitions.DeityType.ATTACK
		else (
			Color(0.25, 0.92, 0.72, 0.13)
			if deity
			else Color(0.95, 0.18, 0.24, 0.14)
		)
	)
	if visual_radius > 1.0:
		var diamond := PackedVector2Array([
			center + Vector2(0, -visual_radius),
			center + Vector2(visual_radius, 0),
			center + Vector2(0, visual_radius),
			center + Vector2(-visual_radius, 0),
		])
		draw_colored_polygon(diamond, Color(range_color, range_color.a * 0.55))
		draw_polyline(
			PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
			Color(range_color, 0.62),
			2.0,
			true
		)
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			var distance := float(_manhattan(selected_pos, pos))
			if distance > attack_range:
				continue
			var cell_reveal := clampf(attack_range * reveal - distance + 0.72, 0.0, 1.0)
			if cell_reveal <= 0.0:
				continue
			var rect := Rect2(grid_to_world(pos) + Vector2(3, 3), Vector2(CELL_SIZE - 6, CELL_SIZE - 6))
			var color := Color(range_color, range_color.a * cell_reveal)
			draw_rect(rect, color)
			draw_rect(rect, Color(color, 0.55 * cell_reveal), false, 1.4)


func _draw_preview_routes() -> void:
	if (
		TurnManager.current_phase != TurnManager.Phase.BUILD
		or not preview_terrain
		or not is_in_bounds(preview_pos)
	):
		return
	var cache_key := "%d:%d:%d:%d" % [
		preview_terrain.terrain_type,
		preview_pos.x,
		preview_pos.y,
		preview_rotation,
	]
	if cache_key != preview_route_cache_key:
		_rebuild_preview_route_cache(cache_key)
	var overrides := _preview_terrain_overrides()
	for entry in preview_route_cache:
		var enemy_core_pos: Vector2i = entry.core_pos
		var before_path: Array = entry.before_path
		var after_path: Array = entry.after_path
		_draw_route_path(before_path, {}, Color(0.54, 0.57, 0.66, 0.24), false)
		if after_path.size() >= 2:
			_draw_route_path(after_path, overrides, Color.WHITE, true)
		_draw_route_time_change(enemy_core_pos, before_path, after_path, overrides)


func _rebuild_preview_route_cache(cache_key: String) -> void:
	preview_route_cache_key = cache_key
	preview_route_cache.clear()
	var overrides := _preview_terrain_overrides()
	for enemy_core_pos in enemy_cores:
		var data: Dictionary = enemy_cores[enemy_core_pos]
		if int(data.hp) <= 0:
			continue
		preview_route_cache.append({
			"core_pos": enemy_core_pos,
			"before_path": _weighted_path(enemy_core_pos, false, {}, true, true),
			"after_path": _weighted_path(enemy_core_pos, false, overrides, true, true),
		})


func _preview_terrain_overrides() -> Dictionary:
	var result: Dictionary = {}
	if not preview_terrain:
		return result
	for offset in preview_terrain.rotated_shape(preview_rotation):
		var pos := preview_pos + offset
		if is_in_bounds(pos) and pos != core_pos and not is_enemy_core(pos):
			result[pos] = preview_terrain.terrain_type
	return result


func _draw_route_path(
	path: Array,
	terrain_overrides: Dictionary,
	base_color: Color,
	emphasized: bool
) -> void:
	if path.size() < 2:
		return
	if emphasized:
		var start_center := grid_to_world(path[0]) + Vector2.ONE * CELL_SIZE * 0.5
		draw_circle(start_center, 4.5, Color(0.95, 0.18, 0.22, 0.9))
	for index in range(path.size() - 1):
		var from := grid_to_world(path[index]) + Vector2.ONE * CELL_SIZE * 0.5
		var to := grid_to_world(path[index + 1]) + Vector2.ONE * CELL_SIZE * 0.5
		var terrain := _terrain_for_path(path[index + 1], terrain_overrides)
		var segment_color := base_color
		if emphasized:
			match terrain:
				GameDefinitions.TerrainType.PLAIN:
					segment_color = Color(1.0, 0.88, 0.38, 0.9)
				GameDefinitions.TerrainType.FOREST:
					segment_color = Color(0.42, 0.86, 0.46, 0.78)
				GameDefinitions.TerrainType.RIVER:
					segment_color = Color(0.34, 0.78, 1.0, 0.74)
				GameDefinitions.TerrainType.NONE:
					segment_color = Color(0.63, 0.46, 0.86, 0.56)
		draw_line(from, to, segment_color, 3.0 if emphasized else 1.3, true)
		if emphasized:
			var waypoint_rect := Rect2(to - Vector2(5, 5), Vector2(10, 10))
			if path[index + 1] == core_pos:
				draw_circle(to, 6.5, Color(0.34, 0.01, 0.025, 0.92))
				draw_circle(to, 4.5, Color(1.0, 0.12, 0.16, 0.98))
			else:
				_draw_catalog_texture(
					AssetCatalog.terrain_texture_key(terrain),
					waypoint_rect,
					0.0,
					Color(1, 1, 1, 0.92)
				)
			_draw_route_arrow(from, to, segment_color)
			if terrain in [
				GameDefinitions.TerrainType.FOREST,
				GameDefinitions.TerrainType.RIVER,
			]:
				var icon_center := from.lerp(to, 0.5) + Vector2(0, -9)
				var icon_rect := Rect2(icon_center - Vector2(7, 7), Vector2(14, 14))
				_draw_catalog_texture(
					AssetCatalog.terrain_texture_key(terrain),
					icon_rect,
					0.0,
					Color(1, 1, 1, 0.88)
				)


func _draw_route_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	var direction := (to - from).normalized()
	if direction.is_zero_approx():
		return
	var tip := from.lerp(to, 0.68)
	var side := direction.orthogonal()
	draw_colored_polygon(
		PackedVector2Array([
			tip + direction * 5.5,
			tip - direction * 4.5 + side * 4.0,
			tip - direction * 4.5 - side * 4.0,
		]),
		color
	)


func _draw_route_time_change(
	enemy_core_pos: Vector2i,
	before_path: Array,
	after_path: Array,
	terrain_overrides: Dictionary
) -> void:
	var before_cost := _path_total_cost(before_path)
	var after_cost := _path_total_cost(after_path, terrain_overrides)
	var base_interval := float(GameDefinitions.BALANCE.enemy_move_interval)
	var before_text := (
		"阻断"
		if is_inf(before_cost)
		else "%.1fs" % (before_cost * base_interval)
	)
	var after_text := (
		"阻断"
		if is_inf(after_cost)
		else "%.1fs" % (after_cost * base_interval)
	)
	var center := grid_to_world(enemy_core_pos) + Vector2.ONE * CELL_SIZE * 0.5
	var label_rect := Rect2(center + Vector2(-40, 25), Vector2(80, 20))
	draw_rect(label_rect, Color(0.035, 0.045, 0.075, 0.82))
	draw_string(
		ThemeDB.fallback_font,
		label_rect.position + Vector2(3, 14),
		"%s → %s" % [before_text, after_text],
		HORIZONTAL_ALIGNMENT_CENTER,
		label_rect.size.x - 6,
		12,
		Color(0.94, 0.92, 0.78, 0.96)
	)


func _draw_anchor(rect: Rect2, terrain: int) -> void:
	var color: Color = GameDefinitions.TERRAIN_COLORS[terrain]
	var center := rect.get_center()
	var pulse := 0.72 + sin(pulse_time * 2.1 + float(terrain)) * 0.12
	draw_circle(center, 17.0, Color(color, 0.16))
	draw_arc(center, 19.0, 0.0, TAU, 32, Color(color, pulse), 2.2)
	var texture := AssetCatalog.texture(AssetCatalog.terrain_texture_key(terrain))
	if texture:
		draw_texture_rect(texture, Rect2(center - Vector2(12, 12), Vector2(24, 24)), false, Color(1, 1, 1, 0.72))


func _draw_void_cell(pos: Vector2i, rect: Rect2, base_modulate: Color) -> void:
	var phase := pulse_time * 0.72 + float(pos.x * 5 + pos.y * 7) * 0.41
	var breath := (sin(phase) + 1.0) * 0.5
	var scale_amount := lerpf(0.91, 1.035, breath)
	var breathe_size := rect.size * scale_amount
	var breathe_rect := Rect2(rect.get_center() - breathe_size * 0.5, breathe_size)
	var tint := base_modulate.lerp(Color(0.72, 0.48, 0.92, 0.96), breath * 0.34)
	tint.a = lerpf(0.68, 0.96, breath)
	if AssetCatalog.animation("terrain_void"):
		_draw_animated_or_texture("terrain_void", breathe_rect, "idle", tint)
	else:
		_draw_catalog_texture(
			"terrain_void",
			breathe_rect,
			float(get_cell(pos).visual_rotation) * PI * 0.5,
			tint
		)
	draw_circle(
		rect.get_center(),
		lerpf(8.0, 20.0, breath),
		Color(0.38, 0.18, 0.55, 0.05 + breath * 0.08)
	)


func _draw_entities() -> void:
	var entries: Array[Dictionary] = []
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			var cell := get_cell(pos)
			var distance := Vector2(pos - core_pos).length()
			if cell.deity:
				entries.append({
					"kind": "deity",
					"distance": distance,
					"pos": pos,
					"cell": cell,
				})
			if cell.enemy:
				entries.append({
					"kind": "enemy",
					"distance": distance + 0.01,
					"pos": pos,
					"cell": cell,
				})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.distance) < float(b.distance)
	)
	for entry in entries:
		var pos: Vector2i = entry.pos
		var cell := entry.cell as GridCellData
		var rect := Rect2(grid_to_world(pos) + Vector2.ONE, Vector2(CELL_SIZE - 2, CELL_SIZE - 2))
		if entry.kind == "deity":
			_draw_deity(cell.deity as DeityInstance, cell.terrain, rect, pos)
		else:
			var enemy := cell.enemy as EnemyInstance
			var visual_grid := enemy.visual_from.lerp(enemy.visual_to, _smoothstep(enemy.visual_progress))
			var visual_rect := Rect2(
				visual_grid * CELL_SIZE + Vector2.ONE,
				Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
			)
			_draw_enemy(enemy, visual_rect)


func _smoothstep(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _draw_terrain_particles(pos: Vector2i, rect: Rect2, terrain: int) -> void:
	match terrain:
		GameDefinitions.TerrainType.PLAIN:
			_draw_plain_wind(pos, rect)
		GameDefinitions.TerrainType.FOREST:
			_draw_forest_growth(pos, rect)
		GameDefinitions.TerrainType.RIVER:
			_draw_river_flow(pos, rect)
		_:
			pass


func _draw_plain_wind(pos: Vector2i, rect: Rect2) -> void:
	var seed := float(pos.x * 19 + pos.y * 37)
	for index in range(2):
		var progress := fposmod(pulse_time * (0.13 + index * 0.025) + seed * 0.037, 1.0)
		var y := rect.position.y + 14.0 + fposmod(seed * 3.1 + index * 17.0, rect.size.y - 28.0)
		var x := rect.position.x - 14.0 + progress * (rect.size.x + 28.0)
		var color := Color(0.88, 1.0, 0.77, sin(progress * PI) * 0.3)
		draw_line(Vector2(x - 13.0, y), Vector2(x + 13.0, y - 3.0), color, 1.7)


func _draw_river_flow(pos: Vector2i, rect: Rect2) -> void:
	var seed := float(pos.x * 23 + pos.y * 11)
	for index in range(3):
		var progress := fposmod(pulse_time * 0.18 + seed * 0.043 + index * 0.31, 1.0)
		var y := rect.position.y + 7.0 + progress * (rect.size.y - 14.0)
		var sway := sin(pulse_time * 1.2 + seed + index) * 4.0
		var color := Color(0.66, 0.93, 1.0, sin(progress * PI) * 0.28)
		draw_line(
			Vector2(rect.position.x + 8.0 + sway, y),
			Vector2(rect.end.x - 8.0 + sway, y - 5.0),
			color,
			2.0
		)


func _draw_forest_growth(pos: Vector2i, rect: Rect2) -> void:
	var seed := float(pos.x * 29 + pos.y * 13)
	for index in range(3):
		var phase := pulse_time * (0.65 + index * 0.08) + seed + index * 2.1
		var base := rect.position + Vector2(
			10.0 + fposmod(seed * 4.7 + index * 15.0, rect.size.x - 20.0),
			rect.size.y - 8.0 - index * 6.0
		)
		var tip := base + Vector2(sin(phase) * 4.0, -9.0 - index * 2.0)
		var color := Color(0.48, 0.92, 0.48, 0.18 + sin(phase) * 0.04)
		draw_line(base, tip, color, 1.9)
		draw_circle(tip, 2.6 + index * 0.35, color)


func _draw_selection_marker(rect: Rect2) -> void:
	var glow := Color(0.55, 0.9, 1.0, 0.16 + sin(pulse_time * 4.0) * 0.04)
	draw_rect(rect.grow(-3), glow)
	var color := Color("9cecff")
	var corner := 11.0
	var width := 2.5
	draw_line(rect.position, rect.position + Vector2(corner, 0), color, width)
	draw_line(rect.position, rect.position + Vector2(0, corner), color, width)
	draw_line(rect.end, rect.end - Vector2(corner, 0), color, width)
	draw_line(rect.end, rect.end - Vector2(0, corner), color, width)
	var top_right := Vector2(rect.end.x, rect.position.y)
	draw_line(top_right, top_right + Vector2(-corner, 0), color, width)
	draw_line(top_right, top_right + Vector2(0, corner), color, width)
	var bottom_left := Vector2(rect.position.x, rect.end.y)
	draw_line(bottom_left, bottom_left + Vector2(corner, 0), color, width)
	draw_line(bottom_left, bottom_left + Vector2(0, -corner), color, width)


func _draw_core() -> void:
	var rect := Rect2(grid_to_world(core_pos) + Vector2(2, 2), Vector2(CELL_SIZE - 4, CELL_SIZE - 4))
	var wave := (sin(pulse_time * 1.7) + 1.0) * 0.5
	var aura_outer := Color(0.95, 0.72, 0.28, 0.07 + wave * 0.05)
	var aura_inner := Color(0.48, 0.86, 1.0, 0.045 + wave * 0.035)
	draw_circle(rect.get_center(), rect.size.x * lerpf(0.57, 0.66, wave), aura_outer)
	draw_circle(rect.get_center(), rect.size.x * lerpf(0.43, 0.50, wave), aura_inner)
	var core_scale := lerpf(1.25, 1.34, wave)
	var core_size := rect.size * core_scale
	var core_rect := Rect2(rect.get_center() - core_size * 0.5, core_size)
	var damage := _damage_ratio(GameManager.core_hp, GameManager.core_max_hp)
	_draw_animated_or_texture("core", core_rect, "idle", _damage_modulate(damage, 0.97))
	_draw_damage_overlay(core_rect, damage)
	_draw_health_bar(rect.get_center() + Vector2(0, 31), GameManager.core_hp, GameManager.core_max_hp, 48.0)


func _draw_deity(
	deity: DeityInstance,
	terrain: int,
	rect: Rect2,
	grid_pos: Vector2i
) -> void:
	var texture_key := AssetCatalog.deity_texture_key(deity.deity_type, terrain)
	var role_color := Color("ffb83e") if deity.deity_type == GameDefinitions.DeityType.ATTACK else Color("4ee4d0")
	if AssetCatalog.texture(texture_key) or AssetCatalog.animation(texture_key):
		var aura_color := role_color
		var domain_size := terrain_region(grid_pos).size()
		var domain_strength := clampf(float(domain_size - 1) / 8.0, 0.0, 1.0)
		var level_strength := float(deity.level - 1) / 2.0
		aura_color.a = 0.08 + domain_strength * 0.10 + level_strength * 0.08
		draw_circle(rect.get_center(), rect.size.x * (0.58 + domain_strength * 0.16), aura_color)
		draw_circle(
			rect.get_center(),
			rect.size.x * (0.41 + domain_strength * 0.09),
			Color(1.0, 1.0, 0.92, 0.045 + domain_strength * 0.055)
		)
		var breathe := 1.0 + sin(
			pulse_time * 1.35 + float(rect.position.x + rect.position.y) * 0.02
		) * 0.035
		var deity_size := rect.size * (1.33 + float(deity.level - 1) * 0.055) * breathe
		var deity_rect := Rect2(rect.get_center() - deity_size * 0.5, deity_size)
		var damage := _damage_ratio(deity.hp, deity.max_hp)
		var visual_animation := deity.visual_animation
		var animation_elapsed := pulse_time - deity.visual_animation_started_at
		if animation_elapsed >= deity.visual_animation_duration:
			visual_animation = "idle"
			animation_elapsed = pulse_time
		var flip_h := false
		if deity.deity_type == GameDefinitions.DeityType.ATTACK:
			var target := _nearest_enemy(grid_pos, float(deity_stats(grid_pos).range))
			if target == Vector2i(-1, -1):
				target = _nearest_enemy_core(grid_pos, float(deity_stats(grid_pos).range))
			flip_h = target != Vector2i(-1, -1) and target.x > grid_pos.x
		_draw_animated_or_texture(
			texture_key,
			deity_rect,
			visual_animation,
			_damage_modulate(damage, 0.96),
			flip_h,
			animation_elapsed
		)
		_draw_damage_overlay(deity_rect, damage)
		_draw_deity_level_visual(rect.get_center(), rect.size.x, deity.level, role_color)
		_draw_health_bar(rect.get_center() + Vector2(0, 27), deity.hp, deity.max_hp, 40.0)
		return
	var color := Color("f2b84b") if deity.deity_type == GameDefinitions.DeityType.ATTACK else Color("72e0ca")
	draw_circle(rect.get_center(), 18.0, Color("171922"))
	draw_circle(rect.get_center(), 15.0, color)
	draw_circle(rect.get_center(), 18.0, Color.WHITE, false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3, 11), "神%d" % deity.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	_draw_deity_level_visual(rect.get_center(), rect.size.x, deity.level, color)


func _draw_deity_level_visual(center: Vector2, cell_width: float, level: int, role_color: Color) -> void:
	if level <= 1:
		return
	var ring_color := role_color.lightened(0.28)
	ring_color.a = 0.42 if level == 2 else 0.65
	var ring_radius := cell_width * (0.58 if level == 2 else 0.64)
	draw_arc(center, ring_radius, 0.0, TAU, 48, ring_color, 1.8 if level == 2 else 2.8)
	var marker_count := level - 1
	for index in range(marker_count):
		var angle := -PI * 0.5 + (float(index) - float(marker_count - 1) * 0.5) * 0.42
		var marker_center := center + Vector2.from_angle(angle) * ring_radius
		draw_circle(marker_center, 3.8 if level == 2 else 4.8, Color(1.0, 0.9, 0.48, 0.95))


func _draw_enemy(enemy: EnemyInstance, rect: Rect2) -> void:
	if AssetCatalog.texture("enemy_default") or AssetCatalog.animation("enemy_default"):
		var wave := (sin(pulse_time * 1.55 + rect.position.x * 0.025) + 1.0) * 0.5
		draw_circle(
			rect.get_center(),
			rect.size.x * lerpf(0.54, 0.61, wave),
			Color(0.72, 0.10, 0.28, 0.09)
		)
		draw_circle(
			rect.get_center(),
			rect.size.x * lerpf(0.40, 0.46, wave),
			Color(0.35, 0.08, 0.48, 0.055)
		)
		var enemy_size := rect.size * lerpf(1.22, 1.30, wave)
		var enemy_rect := Rect2(rect.get_center() - enemy_size * 0.5, enemy_size)
		var damage := _damage_ratio(enemy.hp, enemy.max_hp)
		var flip_h := enemy.visual_to.x > enemy.visual_from.x
		var visual_animation := enemy.visual_animation
		var animation_elapsed := pulse_time - enemy.visual_animation_started_at
		if animation_elapsed >= enemy.visual_animation_duration:
			visual_animation = "move"
			animation_elapsed = pulse_time
		_draw_animated_or_texture(
			"enemy_default",
			enemy_rect,
			visual_animation,
			_damage_modulate(damage),
			flip_h,
			animation_elapsed
		)
		_draw_damage_overlay(enemy_rect, damage)
		_draw_health_bar(rect.get_center() + Vector2(0, 27), enemy.hp, enemy.max_hp, 38.0)
		return
	var pulse := (sin(pulse_time * 5.0) + 1.0) * 0.5
	draw_circle(rect.get_center(), 20.0 + pulse * 2.0, Color(0.95, 0.15, 0.22, 0.2))
	draw_circle(rect.get_center(), 15.0, Color("d94c62"))
	draw_line(rect.get_center() - Vector2(7, 7), rect.get_center() + Vector2(7, 7), Color.WHITE, 2.0)
	draw_line(rect.get_center() + Vector2(7, -7), rect.get_center() + Vector2(-7, 7), Color.WHITE, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3, 11), "敌%d" % enemy.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)


func _draw_preview() -> void:
	if preview_terrain:
		var valid := can_place_terrain(preview_terrain, preview_pos, preview_rotation)
		for offset in preview_terrain.rotated_shape(preview_rotation):
			var pos := preview_pos + offset
			if not is_in_bounds(pos):
				continue
			var rect := Rect2(grid_to_world(pos) + Vector2(2, 2), Vector2(CELL_SIZE - 4, CELL_SIZE - 4))
			var color := preview_terrain.color
			color.a = 0.72
			draw_rect(rect, color)
			_draw_catalog_texture(AssetCatalog.terrain_texture_key(preview_terrain.terrain_type), rect)
			draw_rect(rect, Color("78e091") if valid else Color("ef6262"), false, 3.0)
			_draw_catalog_texture("preview_valid" if valid else "preview_invalid", rect)
	elif preview_deity_type >= 0 and is_in_bounds(preview_pos):
		var rect := Rect2(grid_to_world(preview_pos) + Vector2(4, 4), Vector2(CELL_SIZE - 8, CELL_SIZE - 8))
		draw_rect(rect, Color(0.9, 0.75, 0.25, 0.45))
		draw_rect(rect, Color("78e091") if can_place_deity(preview_deity_type, preview_pos) else Color("ef6262"), false, 3.0)


func _draw_catalog_texture(
	key: String,
	rect: Rect2,
	rotation: float = 0.0,
	modulate: Color = Color.WHITE
) -> void:
	var texture := AssetCatalog.texture(key)
	if texture:
		if is_zero_approx(rotation):
			draw_texture_rect(texture, rect, false, modulate)
			return
		var center := rect.get_center()
		draw_set_transform(center, rotation)
		draw_texture_rect(texture, Rect2(-rect.size * 0.5, rect.size), false, modulate)
		draw_set_transform(Vector2.ZERO, 0.0)


func _draw_animated_or_texture(
	key: String,
	rect: Rect2,
	preferred_animation: String = "idle",
	modulate: Color = Color.WHITE,
	flip_h: bool = false,
	animation_time: float = -1.0
) -> void:
	var frames := AssetCatalog.animation(key)
	if frames:
		var animation_name := StringName(preferred_animation)
		if not frames.has_animation(animation_name):
			animation_name = &"default"
		if frames.has_animation(animation_name):
			var count := frames.get_frame_count(animation_name)
			if count > 0:
				var fps := maxf(1.0, frames.get_animation_speed(animation_name))
				var elapsed := pulse_time if animation_time < 0.0 else animation_time
				var frame_index := 0
				if frames.get_animation_loop(animation_name):
					frame_index = int(elapsed * fps) % count
				else:
					frame_index = mini(count - 1, int(elapsed * fps))
				var frame_texture := frames.get_frame_texture(animation_name, frame_index)
				if frame_texture:
					_draw_texture_with_flip(frame_texture, rect, modulate, flip_h)
					return
	var texture := AssetCatalog.texture(key)
	if texture:
		_draw_texture_with_flip(texture, rect, modulate, flip_h)


func _draw_texture_with_flip(
	texture: Texture2D,
	rect: Rect2,
	modulate: Color,
	flip_h: bool
) -> void:
	if not flip_h:
		draw_texture_rect(texture, rect, false, modulate)
		return
	draw_set_transform(rect.get_center(), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(texture, Rect2(-rect.size * 0.5, rect.size), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _damage_ratio(hp: int, max_hp: int) -> float:
	if max_hp <= 0:
		return 0.0
	return 1.0 - clampf(float(hp) / float(max_hp), 0.0, 1.0)


func _damage_modulate(damage: float, base_alpha: float = 1.0) -> Color:
	return Color(
		1.0,
		1.0 - damage * 0.58,
		1.0 - damage * 0.65,
		base_alpha * (1.0 - damage * 0.28)
	)


func _draw_damage_overlay(rect: Rect2, damage: float) -> void:
	if damage <= 0.01:
		return
	draw_circle(
		rect.get_center(),
		rect.size.x * lerpf(0.25, 0.48, damage),
		Color(0.9, 0.05, 0.08, damage * 0.18)
	)


func _draw_health_bar(center: Vector2, hp: int, max_hp: int, width: float) -> void:
	if max_hp <= 0:
		return
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var background := Rect2(center - Vector2(width * 0.5, 3.0), Vector2(width, 6.0))
	draw_rect(background, Color(0.03, 0.025, 0.03, 0.82))
	var fill := background.grow(-1.0)
	fill.size.x *= ratio
	draw_rect(fill, Color(0.84, 0.16, 0.2, 0.94))
	draw_rect(background, Color(0.42, 0.22, 0.16, 0.86), false, 1.0)


func _spawn_catalog_effect(key: String, pos: Vector2i, lifetime: float) -> void:
	var center := grid_to_world(pos) + Vector2.ONE * CELL_SIZE * 0.5
	var frames := AssetCatalog.animation(key)
	if frames:
		var animated := AnimatedSprite2D.new()
		animated.sprite_frames = frames
		animated.position = center
		animated.z_index = 40
		add_child(animated)
		var animation_name := &"default"
		if not frames.has_animation(animation_name):
			var names := frames.get_animation_names()
			if not names.is_empty():
				animation_name = names[0]
		animated.play(animation_name)
		get_tree().create_timer(lifetime).timeout.connect(animated.queue_free)
		return
	var texture := AssetCatalog.texture(key)
	if texture:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = center
		sprite.z_index = 40
		add_child(sprite)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(1.35, 1.35), lifetime)
		tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
		tween.chain().tween_callback(sprite.queue_free)
