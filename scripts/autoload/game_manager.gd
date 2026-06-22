extends Node

signal game_started
signal game_over(victory: bool)
signal state_changed
signal message_posted(text: String)
signal invalid_action(text: String)
signal terrain_choices_offered(cards: Array)
signal terrain_choices_cleared

var is_game_running: bool = false
var current_round: int = 1
var core_hp: int = 30
var core_max_hp: int = 30
var terrain_choices: Array[TerrainCard] = []
var grid_map_ref: Variant = null
var scene_root: Variant = null
var rng := RandomNumberGenerator.new()


func start_game() -> void:
	rng.randomize()
	current_round = 1
	core_max_hp = 30
	core_hp = core_max_hp
	terrain_choices.clear()
	is_game_running = true
	CardManager.reset()
	game_started.emit()
	state_changed.emit()


func end_game(victory: bool) -> void:
	if not is_game_running:
		return
	is_game_running = false
	TurnManager.finish_game()
	game_over.emit(victory)
	state_changed.emit()


func damage_core(amount: int) -> void:
	core_hp = maxi(0, core_hp - amount)
	post_message("核心受到 %d 点伤害" % amount)
	if core_hp <= 0:
		end_game(false)
	state_changed.emit()


func heal_core(amount: int) -> void:
	core_hp = mini(core_max_hp, core_hp + amount)
	state_changed.emit()


func post_message(text: String) -> void:
	message_posted.emit(text)


func reject_action(text: String) -> void:
	message_posted.emit(text)
	invalid_action.emit(text)


func offer_terrain_choices(cards: Array[TerrainCard]) -> void:
	terrain_choices.assign(cards)
	terrain_choices_offered.emit(terrain_choices)


func clear_terrain_choices() -> void:
	terrain_choices.clear()
	terrain_choices_cleared.emit()
