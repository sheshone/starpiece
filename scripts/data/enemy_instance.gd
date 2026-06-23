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
@export var attack_range: int = 1
@export var terrain_profile: String = "normal"
@export var visual_animation: String = "move"
@export var visual_animation_started_at: float = 0.0
@export var visual_animation_duration: float = 0.0
@export var last_grid_pos: Vector2i = Vector2i(-1, -1)
@export var river_region_id: int = -1
@export var river_cooldown: float = 0.0
@export var forest_region_id: int = -1
@export var confusion_time: float = 0.0
@export var confusion_steps: int = 0
@export var confusion_previous: Vector2i = Vector2i(-1, -1)
@export var wander_origin: Vector2i = Vector2i(-1, -1)
@export var wander_target: Vector2i = Vector2i(-1, -1)
@export var wander_returning: bool = false
@export var wander_round_trips: int = 0
@export var slow_stacks: int = 0
@export var slow_strength_multiplier: float = 1.0
@export var freeze_time: float = 0.0
@export var vulnerable_time: float = 0.0
@export var poison_stacks: int = 0
@export var poison_time: float = 0.0
@export var poison_tick_timer: float = 0.0
@export var poison_damage_multiplier: float = 1.0
@export var poison_spreads: bool = false
@export var silence_time: float = 0.0
@export var charmed_time: float = 0.0


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
	match archetype:
		"swift":
			return "迅行侵蚀体"
		"brute":
			return "重甲侵蚀体"
		"ranged":
			return "远噬侵蚀体"
		"flying":
			return "飞行侵蚀体"
		"swimmer":
			return "洄游侵蚀体"
		"forester":
			return "穿林侵蚀体"
		_:
			return "侵蚀体"
