class_name CardBase
extends Resource

enum CardType { TERRAIN, BUILDING, ACTION }
enum TerrainType { NONE, PLAIN, FOREST, MOUNTAIN, RIVER }

@export var card_name: String = ""
@export var card_type: CardType = CardType.TERRAIN
@export var description: String = ""
@export var divine_power_cost: float = 0.0
# 表现资源接口：玩法代码不依赖具体贴图或动画。
@export var texture_path: String = ""
@export var animation_set: String = ""
