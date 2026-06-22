class_name PieceShapeConfig
extends RefCounted

const SHAPE_NAMES := ["孤星", "双联", "长径", "曲尺", "方庭"]
const SHAPES := [
	[Vector2i.ZERO],
	[Vector2i.ZERO, Vector2i.RIGHT],
	[Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0)],
	[Vector2i.ZERO, Vector2i.RIGHT, Vector2i(0, 1)],
	[Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE],
]

# 固定非均匀概率：保留小地块，同时让中型地块更常见。
const SHAPE_WEIGHTS := [25, 30, 20, 15, 10]


static func probability_text() -> String:
	var lines: Array[String] = []
	for i in range(SHAPE_NAMES.size()):
		lines.append("%s %d%%" % [SHAPE_NAMES[i], SHAPE_WEIGHTS[i]])
	return "　".join(lines)
