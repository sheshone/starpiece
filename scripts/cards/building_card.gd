class_name BuildingCard
extends CardBase

@export var building_id: String = ""
@export var allowed_terrain: TerrainType = TerrainType.PLAIN
@export var color: Color = Color.YELLOW
@export var cost_food: int = 0
@export var cost_wood: int = 0
@export var max_hp: int = 1

func _init() -> void:
	card_type = CardType.BUILDING
