# EnemyManager：保留旧场景兼容接口。新原型敌人状态由 GameMap 管理。
extends Node

signal enemies_spawned


var enemies: Array = []
var spawn_points: Array[Vector2i] = []
var grid_map_ref: Node2D = null


func init_spawn_points(grid_size: Vector2i) -> void:
	spawn_points.clear()
	var w: int = grid_size.x
	var h: int = grid_size.y
	for x in range(w):
		spawn_points.append(Vector2i(x, 0))
		spawn_points.append(Vector2i(x, h - 1))
	for y in range(1, h - 1):
		spawn_points.append(Vector2i(0, y))
		spawn_points.append(Vector2i(w - 1, y))


func spawn_enemy(enemy_scene: PackedScene, at_pos: Vector2i) -> Enemy:
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	enemy.grid_position = at_pos
	enemies.append(enemy)
	enemies_spawned.emit()
	return enemy


func remove_enemy(enemy: Enemy) -> void:
	enemies.erase(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()

func remove_all_enemies() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()


func get_enemy_at(pos: Vector2i) -> Enemy:
	for e in enemies:
		if e.grid_position == pos and is_instance_valid(e) and not e._is_dead:
			return e
	return null


func do_all_enemy_actions() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.take_action()


# 以下方法仅供旧 Enemy 场景兼容使用。
func get_grid_map_ref() -> Node2D:
	return grid_map_ref


func is_in_bounds(gp: Vector2i) -> bool:
	if grid_map_ref:
		return grid_map_ref.is_in_bounds(gp)
	return false


func is_cell_owned(gp: Vector2i) -> bool:
	if grid_map_ref:
		return grid_map_ref.is_cell_owned(gp)
	return false
