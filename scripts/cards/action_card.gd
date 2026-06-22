class_name ActionCard
extends CardBase

@export var action_id: String = ""
@export var cost_food: int = 0
@export var cost_wood: int = 0

func _init() -> void:
	card_type = CardType.ACTION
