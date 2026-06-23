extends Node

signal stats_changed
signal achievement_unlocked(id: String, title: String)

const SAVE_PATH := "user://progress.json"

var current_map: int = 1
var selected_blessing: String = ""
var run_started_msec: int = 0
var map_started_msec: int = 0
var stats: Dictionary = {}
var records: Dictionary = {}
var achievements: Dictionary = {}
var settings: Dictionary = {
	"music_enabled": true,
	"music_volume": 0.65,
}
var completed_maps: int = 0
var lifetime_stats: Dictionary = {}
var current_planet_faces: Dictionary = {}
var planet_history: Array = []
var run_checkpoint: Dictionary = {}

const MAX_MAPS := 6


func _ready() -> void:
	_load_save()


func begin_run() -> void:
	_archive_current_planet()
	run_checkpoint.clear()
	current_map = 1
	selected_blessing = ""
	completed_maps = 0
	current_planet_faces = {}
	run_started_msec = Time.get_ticks_msec()
	map_started_msec = run_started_msec
	stats = {
		"combat_round": 1,
		"base_income": 0.0,
		"resource_income_round": 0.0,
		"resource_income_total": 0.0,
		"enemy_spawned": 0,
		"enemy_killed": 0,
		"pollution_events": 0,
		"collapsed_cells": 0,
		"rebuilt_cells": 0,
		"shop_refreshes": 0,
		"deities_upgraded": 0,
		"map_1_time": 0.0,
		"map_2_time": 0.0,
	}
	stats_changed.emit()
	_save()


func begin_map(map_index: int) -> void:
	current_map = map_index
	map_started_msec = Time.get_ticks_msec()
	stats.resource_income_round = 0.0
	stats_changed.emit()


func add_stat(key: String, amount: float = 1.0) -> void:
	stats[key] = float(stats.get(key, 0.0)) + amount
	lifetime_stats[key] = float(lifetime_stats.get(key, 0.0)) + amount
	stats_changed.emit()


func set_stat(key: String, value: Variant) -> void:
	stats[key] = value
	stats_changed.emit()


func map_elapsed_seconds() -> float:
	return float(Time.get_ticks_msec() - map_started_msec) / 1000.0


func run_elapsed_seconds() -> float:
	return float(Time.get_ticks_msec() - run_started_msec) / 1000.0


func blessing_choices() -> Array[String]:
	var ids: Array[String] = []
	for key in GameDefinitions.BLESSINGS.keys():
		ids.append(str(key))
	ids.shuffle()
	return ids.slice(0, mini(3, ids.size()))


func blessing_value(key: String, fallback: float = 0.0) -> float:
	if selected_blessing.is_empty():
		return fallback
	var blessing: Dictionary = GameDefinitions.BLESSINGS.get(selected_blessing, {})
	return float(blessing.get(key, fallback))


func choose_blessing(id: String) -> void:
	selected_blessing = id
	stats_changed.emit()


func calculate_score(map_index: int, snapshot: Dictionary) -> int:
	var weights: Dictionary = GameDefinitions.BALANCE.score_weights
	var score := int(weights.base_map_score)
	score += int(snapshot.get("core_hp", 0)) * int(weights.core_hp)
	score -= int(snapshot.get("collapsed_cells", 0)) * int(weights.collapse_penalty)
	score -= int(float(snapshot.get("time", 0.0)) * float(weights.time_penalty_per_second))
	if int(snapshot.get("anchors", 0)) > 0:
		score += int(snapshot.get("anchors", 0)) * int(weights.anchor)
	score += int(float(snapshot.get("resource", 0.0)) * float(weights.resource))
	return maxi(0, score)


func register_map_result(map_index: int, snapshot: Dictionary) -> Dictionary:
	var score := calculate_score(map_index, snapshot)
	var key := "map_%d" % map_index
	var previous: Dictionary = records.get(key, {})
	var best_changed := false
	best_changed = _record_min(previous, "fastest_time", float(snapshot.time)) or best_changed
	best_changed = _record_max(previous, "highest_core_hp", int(snapshot.core_hp)) or best_changed
	best_changed = _record_min(previous, "fewest_collapses", int(snapshot.collapsed_cells)) or best_changed
	best_changed = _record_min(previous, "fewest_attack_deities", int(snapshot.attack_deities)) or best_changed
	best_changed = _record_min(previous, "fewest_resource_deities", int(snapshot.resource_deities)) or best_changed
	best_changed = _record_max(previous, "highest_score", score) or best_changed
	previous["terrain_snapshot"] = snapshot.get("terrain_snapshot", [])
	records[key] = previous
	current_planet_faces[str(map_index)] = snapshot.get("terrain_snapshot", [])
	completed_maps = maxi(completed_maps, map_index)
	if map_index == MAX_MAPS:
		var total_time := run_elapsed_seconds()
		var total_score := score
		for index in range(1, MAX_MAPS):
			total_score += int(stats.get("map_%d_score" % index, 0))
		best_changed = _record_min(records, "run_fastest_time", total_time) or best_changed
		best_changed = _record_max(records, "run_highest_score", total_score) or best_changed
		unlock("planet_born")
	stats["map_%d_score" % map_index] = score
	stats["map_%d_time" % map_index] = float(snapshot.time)
	_evaluate_achievements(map_index, snapshot)
	_save()
	return {"score": score, "best_changed": best_changed}


func _archive_current_planet() -> void:
	if current_planet_faces.is_empty():
		return
	planet_history.append({
		"created_unix": Time.get_unix_time_from_system(),
		"completed_faces": completed_maps,
		"faces": current_planet_faces.duplicate(true),
	})
	# 历史最多保留 9 颗，加上正在形成的当前星球，总计最多显示 10 颗。
	while planet_history.size() > 9:
		planet_history.pop_front()


func save_current_run() -> void:
	_save()


func store_run_checkpoint(checkpoint: Dictionary) -> void:
	run_checkpoint = checkpoint.duplicate(true)
	_save()


func clear_run_checkpoint() -> void:
	run_checkpoint.clear()
	_save()


func unlock(id: String) -> void:
	if bool(achievements.get(id, false)):
		return
	achievements[id] = true
	var data: Dictionary = GameDefinitions.ACHIEVEMENTS.get(id, {})
	achievement_unlocked.emit(id, str(data.get("title", id)))
	_save()


func _evaluate_achievements(map_index: int, snapshot: Dictionary) -> void:
	if map_index == 1 and int(snapshot.resource_deities) == 0:
		unlock("self_sufficient")
	if int(snapshot.collapsed_cells) == 0:
		unlock("no_land_lost")
	if int(stats.get("rebuilt_cells", 0)) >= 10:
		unlock("rebuilder")
	if int(snapshot.level_2_deities) >= 3:
		unlock("deity_refinement")
	if map_index == 1 and int(snapshot.shop_refreshes) <= int(GameDefinitions.BALANCE.achievement_refresh_limit):
		unlock("frugal")
	if map_index == 1 and int(snapshot.attack_deities) <= 1:
		unlock("one_god_land")
	if int(snapshot.anchors) >= 4:
		unlock("four_anchors")


func _record_min(target: Dictionary, key: String, value: float) -> bool:
	if not target.has(key) or value < float(target[key]):
		target[key] = value
		return true
	return false


func _record_max(target: Dictionary, key: String, value: float) -> bool:
	if not target.has(key) or value > float(target[key]):
		target[key] = value
		return true
	return false


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"records": records,
			"achievements": achievements,
			"settings": settings,
			"completed_maps": completed_maps,
			"lifetime_stats": lifetime_stats,
			"current_planet_faces": current_planet_faces,
			"planet_history": planet_history,
			"run_checkpoint": run_checkpoint,
		}))


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		records = (parsed as Dictionary).get("records", {})
		achievements = (parsed as Dictionary).get("achievements", {})
		settings = (parsed as Dictionary).get("settings", settings)
		completed_maps = int((parsed as Dictionary).get("completed_maps", 0))
		lifetime_stats = (parsed as Dictionary).get("lifetime_stats", {})
		current_planet_faces = (parsed as Dictionary).get("current_planet_faces", {})
		planet_history = (parsed as Dictionary).get("planet_history", [])
		run_checkpoint = (parsed as Dictionary).get("run_checkpoint", {})
