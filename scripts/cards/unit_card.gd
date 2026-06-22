class_name UnitCard
extends CardBase

# 旧版兼容资源。普通单位不再进入普通牌库，运行时使用 UnitInstance。
@export var cost_food: int = 0
@export var cost_wood: int = 0
@export var hp: int = 3
@export var atk: int = 1
@export var color: Color = Color.RED

func _init() -> void:
	card_type = CardType.ACTION
