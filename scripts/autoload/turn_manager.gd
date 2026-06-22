extends Node

enum Phase { BUILD, COMBAT, GAME_OVER }

signal phase_changed(new_phase: Phase)
signal build_started
signal combat_started(duration: float)
signal combat_ended(round_number: int)
signal combat_time_changed(remaining: float)

@export var combat_duration: float = 12.0

var current_phase: Phase = Phase.BUILD
var combat_time_remaining: float = 0.0
func _process(delta: float) -> void:
	if current_phase != Phase.COMBAT or not GameManager.is_game_running:
		return
	combat_time_remaining = maxf(0.0, combat_time_remaining - delta)
	combat_time_changed.emit(combat_time_remaining)
	if combat_time_remaining <= 0.0:
		if (
			GameManager.scene_root
			and GameManager.scene_root.has_method("can_end_combat")
			and not bool(GameManager.scene_root.call("can_end_combat"))
		):
			return
		combat_ended.emit(GameManager.current_round)
		GameManager.current_round += 1
		enter_build_phase()


func start_game_loop() -> void:
	enter_build_phase()


func enter_build_phase() -> void:
	current_phase = Phase.BUILD
	get_tree().paused = false
	phase_changed.emit(current_phase)
	build_started.emit()


func start_combat() -> bool:
	if current_phase != Phase.BUILD:
		return false
	current_phase = Phase.COMBAT
	combat_time_remaining = combat_duration
	phase_changed.emit(current_phase)
	combat_started.emit(combat_duration)
	combat_time_changed.emit(combat_time_remaining)
	return true


func finish_game() -> void:
	current_phase = Phase.GAME_OVER
	phase_changed.emit(current_phase)
