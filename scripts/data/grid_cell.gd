class_name GridCellData
extends Resource

@export var terrain: int = GameDefinitions.TerrainType.NONE
@export var pollution: int = 0
@export var piece_id: int = -1
@export var visual_rotation: int = 0
@export var deity: Resource
@export var enemy: Resource
@export var enemy_stack: Array[Resource] = []
@export var anchor_terrain: int = GameDefinitions.TerrainType.NONE
@export var anchor_reward_claimed: bool = false
@export var was_collapsed: bool = false
