class_name Enemy
extends Node2D

const CELL_SIZE: int = 48

@export var enemy_name: String = "Slime"
@export var hp: int = 3
@export var atk: int = 1
@export var move_speed: int = 1
@export var color: Color = Color.ORANGE

var grid_position: Vector2i = Vector2i.ZERO
var _flash_timer: float = 0.0
var _is_acting: bool = false
var _is_hit: bool = false
var _hit_flash_timer: float = 0.0
var _dmg_taken: int = 0
var _is_dead: bool = false


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if _is_dead:
		return
	var r: float = CELL_SIZE / 2.0 - 2.0
	var center: Vector2 = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
	var draw_color: Color = color
	var hp_str: String = "HP:%d" % hp
	if _is_hit:
		draw_color = Color(1.0, 0.2, 0.2)
		hp_str = "HP:%d(-%d)" % [max(0, hp + _dmg_taken), _dmg_taken]
	elif _is_acting:
		draw_color = Color.WHITE if int(_flash_timer * 10.0) % 2 == 0 else color
	draw_circle(center, r, draw_color)
	if _is_hit:
		var pad: float = 6.0
		draw_line(center + Vector2(-r + pad, -r + pad), center + Vector2(r - pad, r - pad), Color.BLACK, 2.0)
		draw_line(center + Vector2(r - pad, -r + pad), center + Vector2(-r + pad, r - pad), Color.BLACK, 2.0)
	draw_circle(center, r, Color.BLACK, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 10.0, center.y - CELL_SIZE / 2.0 - 4.0),
		hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 10.0, center.y + 4.0),
		enemy_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)


func _process(delta: float) -> void:
	if _is_dead:
		return
	var needs_redraw: bool = false
	if _is_acting:
		_flash_timer += delta
		if _flash_timer > 0.8:
			_is_acting = false
			_flash_timer = 0.0
		needs_redraw = true
	if _is_hit:
		_hit_flash_timer += delta
		if _hit_flash_timer > 0.5:
			_is_hit = false
			_hit_flash_timer = 0.0
			_dmg_taken = 0
		needs_redraw = true
	if needs_redraw:
		queue_redraw()


# 返回 true 表示攻击到了玩家领地。
func take_action() -> bool:
	if _is_dead:
		return false
	_is_acting = true
	_flash_timer = 0.0
	# 先检查相邻格：如果相邻格有己方单位，先攻击单位
	var grid_map_node: Node2D = EnemyManager.get_grid_map_ref() as Node2D
	if grid_map_node:
		for nb in _neighbors(grid_position):
			if EnemyManager.is_cell_owned(nb):
				var cell: Dictionary = grid_map_node.get_cell(nb)
				if not cell.is_empty() and cell.get("unit") != null:
					var defender: UnitCard = cell["unit"] as UnitCard
					if defender and defender.hp > 0:
						defender.hp -= atk
						if defender.hp <= 0:
							cell["unit"] = null
						else:
							cell["unit"] = defender
						grid_map_node.queue_redraw()
						return true
	var target: Vector2i = _find_nearest_player_cell()
	if target == Vector2i(-1, -1):
		return false
	var path: Array = _bfs_path(grid_position, target)
	if path.size() <= 1:
		return _attack_core()
	var steps: int = mini(move_speed, path.size() - 1)
	var new_pos: Vector2i = grid_position
	for _i in range(steps):
		if path.size() > 1:
			path.pop_front()
			new_pos = path[0]
	grid_position = new_pos
	return _attack_core()


func _find_nearest_player_cell() -> Vector2i:
	var grid_map_node: Node2D = EnemyManager.get_grid_map_ref() as Node2D
	if not grid_map_node:
		return Vector2i(-1, -1)
	var owned: Array = grid_map_node.get_owned_cells()
	if owned.is_empty():
		return Vector2i(-1, -1)
	var best: Vector2i = Vector2i(-1, -1)
	var best_dist: int = 9999
	for c in owned:
		var cx: int = c.x if c is Vector2i else 0
		var cy: int = c.y if c is Vector2i else 0
		var d: int = abs(cx - grid_position.x) + abs(cy - grid_position.y)
		if d < best_dist:
			best_dist = d
			best = c
	return best


func _bfs_path(start: Vector2i, target: Vector2i) -> Array:
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited["%d,%d" % [start.x, start.y]] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == target:
			var path: Array[Vector2i] = [cur]
			var key: String = "%d,%d" % [cur.x, cur.y]
			while parent.has(key):
				var p: Vector2i = parent[key]
				path.push_front(p)
				key = "%d,%d" % [p.x, p.y]
			return path
		for nb in _neighbors(cur):
			var key: String = "%d,%d" % [nb.x, nb.y]
			if visited.has(key):
				continue
			if not EnemyManager.is_in_bounds(nb):
				continue
			if nb == target:
				visited[key] = true
				parent[key] = cur
				queue.append(nb)
				continue
			if EnemyManager.is_cell_owned(nb):
				# 领地格可以通行
				visited[key] = true
				parent[key] = cur
				queue.append(nb)
				continue
			visited[key] = true
			parent[key] = cur
			queue.append(nb)
	return [start]


# 只有与主城核心格子相邻时才攻击主城。
func _attack_core() -> bool:
	if _is_dead:
		return false
	var grid_map_node: Node2D = EnemyManager.get_grid_map_ref() as Node2D
	if not grid_map_node:
		return false
	# 主城核心位置 (GRID_W/2, GRID_H/2)
	var castle_pos: Vector2i = Vector2i(grid_map_node.GRID_W / 2, grid_map_node.GRID_H / 2)
	for nb in _neighbors(grid_position):
		if nb == castle_pos:
			GameManager.main_castle_hp -= atk
			if GameManager.main_castle_hp <= 0:
				GameManager.main_castle_hp = 0
				GameManager.end_game(false)
			return true
	return false


func _neighbors(gp: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(gp.x + 1, gp.y),
		Vector2i(gp.x - 1, gp.y),
		Vector2i(gp.x, gp.y + 1),
		Vector2i(gp.x, gp.y - 1),
	]


func take_damage(dmg: int) -> void:
	if _is_dead:
		return
	_dmg_taken = dmg
	hp -= dmg
	_is_hit = true
	_hit_flash_timer = 0.0
	queue_redraw()
	if hp <= 0:
		_is_dead = true
		queue_redraw()
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self):
			EnemyManager.remove_enemy(self)
