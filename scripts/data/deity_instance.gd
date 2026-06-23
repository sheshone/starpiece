class_name DeityInstance
extends Resource

@export var deity_type: int = GameDefinitions.DeityType.ATTACK
@export var hp: int = 1
@export var max_hp: int = 1
@export var action_timer: float = 0.0
@export var production_count: int = 0
@export var attack_count: int = 0
@export var shield: float = 0.0
@export var level: int = 1
@export var visual_animation: String = "idle"
@export var visual_animation_started_at: float = 0.0
@export var visual_animation_duration: float = 0.0
@export var tracked_target: Vector2i = Vector2i(-1, -1)
@export var target_stacks: int = 0
@export var target_idle_time: float = 0.0
@export var large_skill_used: bool = false
@export var large_skill_time: float = 0.0
@export var combat_interest_base: float = 0.0


static func create(type: int) -> DeityInstance:
	var result := DeityInstance.new()
	result.deity_type = type
	result.max_hp = int(GameDefinitions.BALANCE.deity_base_hp)
	result.hp = result.max_hp
	return result
