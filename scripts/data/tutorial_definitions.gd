class_name TutorialDefinitions
extends RefCounted

# 触发式新手引导数据。
# 不做独立教程模式；提示直接融入前期关卡。
# 所有提示默认不暂停游戏，只作为右上角浮层与高亮出现。

const DEITY_ATTACK := 0
const DEITY_RESOURCE := 1
const TERRAIN_PLAIN := 1
const TERRAIN_FOREST := 2
const TERRAIN_MOUNTAIN := 3
const TERRAIN_RIVER := 4

const DEFAULT_DURATION := 5.2


static func step(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result["pause"] = false
	result["non_blocking"] = true
	if not result.has("duration"):
		result["duration"] = DEFAULT_DURATION
	if not result.has("once"):
		result["once"] = true
	return result


static var STEPS: Array[Dictionary] = [
	step({
		"id": "prologue_start",
		"map": 0,
		"trigger": "level_started",
		"text": "欢迎来到拼星！看到这些格子了吗？点击格子，安置神祇！",
		"highlight": ["domain"],
	}),
	step({
		"id": "prologue_deity_ready",
		"map": 0,
		"trigger": "deity_built",
		"terrain": TERRAIN_PLAIN,
		"deity_type": DEITY_ATTACK,
		"text": "你成功安置了一位疾野神！祂会守护你的核心。",
		"highlight": ["deity"],
	}),
	step({
		"id": "prologue_enemy_core_unsealed",
		"map": 0,
		"trigger": "prologue_enemy_core_unsealed",
		"text": "敌人的核心还没有被包围。敌方核心被围起来时，才会被神祇攻击！",
		"highlight": ["enemy_core"],
	}),
	step({
		"id": "prologue_buy_tile",
		"map": 0,
		"trigger": "prologue_buy_tile",
		"text": "消耗神力来购买并放置地块吧！把敌人的核心围起来。你的地块必须挨着已有领地。",
		"highlight": ["shop_card"],
	}),
	step({
		"id": "first_card_purchased",
		"trigger": "terrain_card_purchased",
		"text": "把地块放在发光的合法位置。地块必须上下左右连接核心或已有领地。",
		"highlight": ["placement_cells"],
	}),
	step({
		"id": "prologue_tile_placed",
		"map": 0,
		"trigger": "prologue_tile_placed",
		"text": "缺口已经补好，现在让时间流动起来吧！",
		"highlight": ["time_button"],
	}),
	step({
		"id": "prologue_combat_started",
		"map": 0,
		"trigger": "combat_started",
		"text": "敌方将向核心推进。摧毁全部敌方核心即可获胜；中央核心生命归零则失败。",
		"highlight": ["enemy_core"],
	}),
	step({
		"id": "chapter_1_start",
		"map": 1,
		"trigger": "level_started",
		"text": "现在准备摧毁所有核心吧。",
		"highlight": ["enemy_core"],
	}),
	step({
		"id": "enemy_spawned_first",
		"trigger": "enemy_spawned",
		"text": "敌人会从敌方核心出现，并向中央核心推进。",
		"highlight": ["enemy"],
		"duration": 3.6,
	}),
	step({
		"id": "enemy_core_attackable_first",
		"trigger": "enemy_core_attackable",
		"text": "敌方核心已被地形包围，现在可以攻击它了。",
		"highlight": ["enemy_core"],
	}),
	step({
		"id": "enemy_core_damaged_first",
		"trigger": "enemy_core_damaged",
		"text": "继续进攻，摧毁它！",
		"highlight": ["enemy_core"],
		"duration": 3.0,
	}),
	step({
		"id": "enemy_core_destroyed_first",
		"trigger": "enemy_core_destroyed",
		"text": "敌方核心已摧毁，这个方向的压力会减弱。",
		"highlight": ["enemy_core"],
		"duration": 3.6,
	}),
	step({
		"id": "divine_power_first_gain",
		"trigger": "resource_gained",
		"text": "神力用于购买地块、升级和迁移神祇。中央核心每回合都会提供基础神力。",
		"highlight": ["resource"],
		"duration": 4.0,
	}),
	step({
		"id": "divine_power_not_enough",
		"trigger": "resource_insufficient",
		"text": "神力不足。继续战斗，或建造丰饶神获得更多神力。",
		"highlight": ["resource"],
		"duration": 3.5,
	}),
	step({
		"id": "swift_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_PLAIN,
		"deity_type": DEITY_ATTACK,
		"text": "疾野神：高速单体攻击。",
		"highlight": ["deity"],
	}),
	step({
		"id": "vitality_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_PLAIN,
		"deity_type": DEITY_RESOURCE,
		"text": "盎然神：持续治疗受伤友军。",
		"highlight": ["deity"],
	}),
	step({
		"id": "bombard_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_MOUNTAIN,
		"deity_type": DEITY_ATTACK,
		"text": "轰爆神：远程范围伤害。",
		"highlight": ["deity"],
	}),
	step({
		"id": "stagnation_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_MOUNTAIN,
		"deity_type": DEITY_RESOURCE,
		"text": "泞滞神：削弱并控制敌人。",
		"highlight": ["deity"],
	}),
	step({
		"id": "shard_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_RIVER,
		"deity_type": DEITY_ATTACK,
		"text": "澜沧神：攻击会在多个目标间传播。",
		"highlight": ["deity"],
	}),
	step({
		"id": "vortex_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_RIVER,
		"deity_type": DEITY_RESOURCE,
		"text": "漩涡神：改变敌人的位置与状态。",
		"highlight": ["deity"],
	}),
	step({
		"id": "poison_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_FOREST,
		"deity_type": DEITY_ATTACK,
		"text": "蛊郁神：持续施加毒素。",
		"highlight": ["deity"],
	}),
	step({
		"id": "abundance_god_built",
		"trigger": "deity_built",
		"terrain": TERRAIN_FOREST,
		"deity_type": DEITY_RESOURCE,
		"text": "丰饶神：持续产生神力。",
		"highlight": ["deity"],
	}),
	step({
		"id": "deity_operations_first",
		"trigger": "deity_operation_opened",
		"text": "点击神祇可以查看信息。升级会强化能力，移除会释放神域位置但不返还资源。",
		"highlight": ["operation_buttons"],
	}),
	step({
		"id": "deity_upgraded_first",
		"trigger": "deity_upgraded",
		"text": "升级完成。等级越高，能力越强。",
		"highlight": ["deity"],
		"duration": 3.4,
	}),
	step({
		"id": "migration_available_first",
		"trigger": "migration_available",
		"text": "神域较大时可以迁移神祇。迁移只能移动到同一片神域内的空格。",
		"highlight": ["migration_button"],
	}),
	step({
		"id": "deity_migrated_first",
		"trigger": "deity_migrated",
		"text": "迁移不会损失等级、生命与充能。",
		"highlight": ["deity"],
		"duration": 3.4,
	}),
	step({
		"id": "deity_removed_first",
		"trigger": "deity_removed",
		"text": "神祇已移除，这片神域可以重新安置神祇。",
		"highlight": ["domain"],
		"duration": 3.4,
	}),
	step({
		"id": "domain_adjacency_first",
		"trigger": "domain_adjacency_created",
		"text": "相邻神域会改变神祇技能效果。",
		"highlight": ["domain"],
	}),
	step({
		"id": "large_domain_ready_first",
		"trigger": "large_domain_ready",
		"text": "大型神域已形成。战斗中点击神祇，可以释放主动技能。",
		"highlight": ["domain"],
	}),
	step({
		"id": "large_skill_button_first",
		"trigger": "large_skill_button_visible",
		"text": "点击主动技能按钮，释放这片大型神域的能力。",
		"highlight": ["large_skill_button"],
	}),
	step({
		"id": "large_skill_used_first",
		"trigger": "large_skill_used",
		"text": "主动技能已发动；每场战斗只能使用一次。",
		"highlight": ["domain"],
		"slow_motion": 0.5,
		"duration": 3.0,
	}),
	step({
		"id": "pollution_first",
		"trigger": "pollution_created",
		"text": "敌人在地形上死亡会留下污染。污染满后，地块会崩塌回混沌。",
		"highlight": ["cell"],
	}),
	step({
		"id": "river_push_first",
		"trigger": "enemy_entered_river",
		"text": "敌人进入河流后，会被水流冲向岸边。",
		"highlight": ["enemy"],
		"slow_motion": 0.5,
		"duration": 3.5,
	}),
	step({
		"id": "forest_confusion_first",
		"trigger": "enemy_entered_forest",
		"text": "敌人进入森林后，会在林中迷失方向。",
		"highlight": ["enemy"],
		"slow_motion": 0.5,
		"duration": 3.5,
	}),
	step({
		"id": "chapter_2_start",
		"map": 2,
		"trigger": "level_started",
		"text": "新地形：山地。山地会阻挡敌人，但不能封死路线。",
		"highlight": ["map"],
	}),
	step({
		"id": "chapter_3_start",
		"map": 3,
		"trigger": "level_started",
		"text": "新地形：河流。用河流把敌人冲送到火力区。",
		"highlight": ["map"],
	}),
	step({
		"id": "chapter_4_start",
		"map": 4,
		"trigger": "level_started",
		"text": "新地形：森林。森林能拖延敌人，也会解锁丰饶神。",
		"highlight": ["map"],
	}),
	step({
		"id": "chapter_5_start",
		"map": 5,
		"trigger": "level_started",
		"text": "不同神域相邻后，神祇会获得新的技能变化。",
		"highlight": ["domain"],
	}),
	step({
		"id": "chapter_6_start",
		"map": 6,
		"trigger": "level_started",
		"text": "把神域扩张到 6 格，尝试发动主动技能。",
		"highlight": ["domain"],
	}),
]
