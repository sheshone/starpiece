class_name TerrainCard
extends CardBase

# 地形牌使用相对坐标定义形状，(0,0) 为锚点。
@export var shape: Array[Vector2i] = [Vector2i(0, 0)]
@export var terrain_type: TerrainType = TerrainType.PLAIN
@export var color: Color = Color.GREEN

func _init() -> void:
	card_type = CardType.TERRAIN

func rotated_shape(times: int = 1) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in shape:
		var v: Vector2i = coord
		for _i in range(times % 4):
			v = Vector2i(-v.y, v.x)
		result.append(v)
	return result

func threat_value() -> int:
	return 1 if shape.size() == 1 else 2
