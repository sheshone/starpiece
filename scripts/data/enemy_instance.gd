class_name EnemyInstance
extends Resource

@export var hp: int = 1
@export var max_hp: int = 1
@export var attack: int = 1
@export var move_timer: float = 0.0
@export var slow_timer: float = 0.0
@export var visual_from: Vector2 = Vector2.ZERO
@export var visual_to: Vector2 = Vector2.ZERO
@export var visual_progress: float = 1.0
@export var visual_duration: float = 0.28
@export var speed_multiplier: float = 1.0
@export var archetype: String = "normal"
@export var visual_animation: String = "move"
@export var visual_animation_started_at: float = 0.0
@export var visual_animation_duration: float = 0.0


static func create(round_number: int) -> EnemyInstance:
	var result := EnemyInstance.new()
	result.max_hp = maxi(1, roundi(
		float(GameDefinitions.BALANCE.enemy_base_hp)
		+ float(round_number - 1) * float(GameDefinitions.BALANCE.enemy_hp_per_round)
	))
	result.hp = result.max_hp
	result.attack = maxi(1, roundi(
		float(GameDefinitions.BALANCE.enemy_base_attack)
		+ float(round_number - 1) * float(GameDefinitions.BALANCE.enemy_attack_per_round)
	))
	return result

func display_name() -> String:
	return "侵蚀体"
