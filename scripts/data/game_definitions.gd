class_name GameDefinitions
extends RefCounted

enum TerrainType { NONE, PLAIN, FOREST, MOUNTAIN, RIVER }
enum DeityType { ATTACK, RESOURCE }

const TERRAIN_NAMES := {
	TerrainType.NONE: "虚空",
	TerrainType.PLAIN: "平原",
	TerrainType.FOREST: "森林",
	TerrainType.MOUNTAIN: "山地",
	TerrainType.RIVER: "河流",
}

const TERRAIN_COLORS := {
	TerrainType.NONE: Color("171922"),
	TerrainType.PLAIN: Color("7c9b58"),
	TerrainType.FOREST: Color("315f3c"),
	TerrainType.MOUNTAIN: Color("77716b"),
	TerrainType.RIVER: Color("3f7fa5"),
}

const DEITY_NAMES := {
	DeityType.ATTACK: "攻击神祇",
	DeityType.RESOURCE: "资源神祇",
}

const DEITY_FORM_NAMES := {
	TerrainType.PLAIN: {
		DeityType.ATTACK: "原野·逐风神",
		DeityType.RESOURCE: "原野·丰穗神",
	},
	TerrainType.FOREST: {
		DeityType.ATTACK: "森境·荆猎神",
		DeityType.RESOURCE: "森境·生息神",
	},
	TerrainType.MOUNTAIN: {
		DeityType.ATTACK: "山岳·崩岩神",
		DeityType.RESOURCE: "山岳·蕴藏神",
	},
	TerrainType.RIVER: {
		DeityType.ATTACK: "川流·回澜神",
		DeityType.RESOURCE: "川流·涌泉神",
	},
}

# 首版所有可调数值集中在这里。
const BALANCE := {
	# ── 地图与基础经济 ─────────────────────────────────────────────
	# 单格污染达到该值时立即崩塌。祝福可以在此基础上额外增加上限。
	"cell_pollution_limit": 3,
	# 计算开局资源时额外预留的神力，目的是建造基础组合后仍能继续操作。
	"starting_reserve_after_opening": 1.0,
	# 每个战斗阶段完全结束后，由中央核心固定发放的神力。
	"combat_base_income": 4.0,
	# 键是“升级后的等级”，值是从前一级升到该等级的基础费用。
	"deity_upgrade_cost_by_level": {2: 4.0, 3: 7.0},
	# 祝福所使用的默认升级折扣比例；0.25 表示降低25%。
	"upgrade_cost_discount": 0.25,

	# ── 神祇等级成长 ───────────────────────────────────────────────
	# 攻击神基础伤害的等级倍率；神域面积倍率会与它相乘。
	"deity_level_damage_multiplier": {1: 1.0, 2: 1.5, 3: 2.15},
	# 资源神基础单次产量的等级倍率；神域面积倍率会与它相乘。
	"deity_level_amount_multiplier": {1: 1.0, 2: 1.45, 3: 2.0},
	# 所有神祇最大生命的等级倍率。
	"deity_level_hp_multiplier": {1: 1.0, 2: 1.35, 3: 1.8},
	# 地形特殊攻击、特殊生产、治疗等效果的等级倍率。
	"deity_level_special_multiplier": {1: 1.0, 2: 1.3, 3: 1.65},
	# 攻击/生产间隔倍率；数值越小，行动越快。
	"deity_level_interval_multiplier": {1: 1.0, 2: 0.88, 3: 0.74},
	# 所有攻击神升级后直接增加的射程格数。
	"deity_level_range_bonus": {1: 0.0, 2: 1.5, 3: 3.0},
	# 山地攻击神在通用升级射程之外额外获得的射程。
	"mountain_deity_level_range_bonus": {1: 0.0, 2: 0.75, 3: 1.5},

	# ── 建造与卡牌费用 ─────────────────────────────────────────────
	# 地块卡按照所含格数定价，键为格数。
	"terrain_card_cost_by_size": {
		1: 1.0,
		2: 1.5,
		3: 2.0,
		4: 2.5,
	},
	# 建造一座1级攻击神的基础费用。
	"attack_deity_cost": 5.0,
	# 建造一座1级资源神的基础费用。
	"resource_deity_cost": 4.0,

	# ── 神祇基础属性与神域面积 ─────────────────────────────────────
	# 1级神祇的基础最大生命。
	"deity_base_hp": 8,
	# 1级攻击神、1格神域时的基础伤害。
	"attack_base_damage": 2,
	# 1级攻击神的基础曼哈顿射程。
	"attack_base_range": 2,
	# 1级攻击神的基础攻击间隔（秒）。
	"attack_base_interval": 1.35,
	# 神域面积2至6格时，每增加一格增加的核心属性倍率。
	"domain_area_step_to_six": 0.2,
	# 神域超过6格后，每增加一格增加的核心属性倍率。
	"domain_area_step_after_six": 0.05,

	# ── 相邻神域共鸣 ───────────────────────────────────────────────
	# 平原共鸣对基础攻击/生产间隔的乘数；0.82代表缩短18%。
	"plain_resonance_interval_multiplier": 0.82,
	# 山地共鸣给予攻击神的额外射程。
	"mountain_resonance_range_bonus": 0.75,
	# 山地共鸣给予资源神的单次固定额外产量。
	"mountain_resonance_resource_bonus": 0.2,
	# 河流共鸣减少多少次普通行动即可触发一次特殊能力。
	"river_resonance_trigger_reduction": 1,
	# 森林共鸣对最大生命的倍率。
	"forest_resonance_hp_multiplier": 1.15,
	# 森林共鸣对治疗量和护盾量的倍率。
	"forest_resonance_heal_shield_multiplier": 1.2,

	# ── 迁移、范围和攻击判定 ───────────────────────────────────────
	# 每次在同一神域内迁移神祇所消耗的固定神力。
	"deity_migration_cost": 1.5,
	# 点击资源神时用于展示治疗/生产影响范围的格数。
	"resource_effect_range": 2.0,
	# 攻击目标判定额外放宽的格数，也同步体现在范围预览中。
	"attack_range_tolerance": 1.0,
	# 任何加速效果都不能让攻击间隔低于该秒数。
	"minimum_attack_interval": 0.25,

	# ── 四类攻击神特殊能力 ─────────────────────────────────────────
	# 山地攻击命中后，对目标周围多少格造成溅射。
	"mountain_splash_radius": 1,
	# 山地特殊攻击对溅射伤害/效果的倍率。
	"mountain_special_splash_multiplier": 1.35,
	# 敌人距离中央核心不超过该格数时，被山地神视为危险目标。
	"core_danger_range": 2,
	# 河流弹射寻找下一目标时允许的最大距离。
	"river_chain_range": 2,
	# 河流特殊攻击额外增加的弹射次数。
	"river_special_extra_chains": 1,
	# 森林普通攻击施加减速的持续时间（秒）。
	"forest_slow_duration": 1.6,
	# 敌人被减速时移动间隔乘数；越大越慢。
	"forest_slow_multiplier": 1.7,
	# 森林特殊攻击额外增加的减速持续时间。
	"forest_special_slow_duration": 1.0,
	# 森林特殊攻击为自身恢复的最大生命比例。
	"forest_special_self_heal_ratio": 0.08,

	# ── 四类资源神生产与特殊能力 ───────────────────────────────────
	# 1级资源神、1格神域的基础单次产量。
	"resource_base_amount": 0.5,
	# 1级资源神的基础生产间隔（秒）。
	"resource_base_interval": 4.5,
	# 平原资源神的生产间隔倍率。
	"resource_plain_interval_multiplier": 0.86,
	# 山地资源神的生产间隔倍率；大于1表示更慢。
	"resource_mountain_interval_multiplier": 1.2,
	# 山地资源神的基础单次产量倍率。
	"resource_mountain_base_amount_multiplier": 1.25,
	# 默认每进行多少次普通攻击/生产触发一次特殊能力。
	"special_trigger_every": 4,
	# 森林生命绽放治疗目标最大生命的比例。
	"forest_bloom_heal_ratio": 0.2,
	# 森林生命绽放产生的护盾最多占目标最大生命的比例。
	"forest_bloom_shield_cap_ratio": 0.15,

	# ── 敌人基础成长与生成频率 ─────────────────────────────────────
	# 第一轮普通敌人的基础生命。
	"enemy_base_hp": 2,
	# 每增加一轮，敌人基础生命增加的数值。
	"enemy_hp_per_round": 0.45,
	# 第一轮普通敌人的基础攻击。
	"enemy_base_attack": 1,
	# 每增加一轮，敌人基础攻击增加的数值。
	"enemy_attack_per_round": 0.12,
	# 前期两个出怪预告开始之间的基础间隔。
	"enemy_base_spawn_interval": 4.1,
	# 无论难度多高，出怪间隔都不会低于该值。
	"enemy_min_spawn_interval": 0.75,
	# 每轮使生成间隔减少的比例。
	"enemy_spawn_round_scale": 0.07,
	# 地图填充率对生成间隔的最大压缩比例。
	"enemy_spawn_fill_scale": 0.38,
	# 普通敌人在无地形修正时的移动间隔。
	"enemy_move_interval": 0.72,

	# ── 敌人寻路代价 ───────────────────────────────────────────────
	# 数值越低越偏好；山地未列入字典，因为代码直接判定为不可通行。
	"terrain_path_cost": {
		TerrainType.NONE: 1.0,
		TerrainType.PLAIN: 0.8,
		TerrainType.FOREST: 1.4,
		TerrainType.RIVER: 2.2,
	},

	# ── 敌方核心与阶段激活 ─────────────────────────────────────────
	# 每座敌方核心的最大生命。
	"enemy_core_hp": 18,
	# 摧毁一座敌方核心立即获得的神力。
	"enemy_core_reward": 2.0,
	# 红色出怪预告从出现到敌人实际生成的时间。
	"enemy_core_warning_time": 3.4,
	# 战斗开始后第一次开始预告前的延迟。
	"enemy_first_warning_delay": 0.1,
	# 前期、中期、后期最多同时激活的敌方核心数量。
	"enemy_core_initial_active": 2,
	"enemy_core_mid_active": 5,
	"enemy_core_late_active": 8,
	# 每张地图固定放置的敌方核心数量。
	"map_enemy_core_count": {1: 4, 2: 5, 3: 6, 4: 7, 5: 8, 6: 8},
	# 每张地图要求激活的地形锚点数量。
	"map_anchor_count": {1: 0, 2: 2, 3: 3, 4: 4, 5: 4, 6: 4},
	# 每摧毁一座敌方核心后，剩余核心生成间隔增加的比例。
	"enemy_core_pressure_reduction": 0.07,

	# ── 前中后期难度曲线 ───────────────────────────────────────────
	# 地图填充率达到这些值后进入中期/后期。
	"enemy_mid_fill": 0.34,
	"enemy_late_fill": 0.67,
	# 中期/后期敌人生命倍率。
	"enemy_mid_hp_multiplier": 1.35,
	"enemy_late_hp_multiplier": 1.9,
	# 中期/后期敌人攻击倍率。
	"enemy_mid_attack_multiplier": 1.2,
	"enemy_late_attack_multiplier": 1.55,
	# 中期/后期生成间隔倍率；越小生成越快。
	"enemy_mid_spawn_multiplier": 0.82,
	"enemy_late_spawn_multiplier": 0.58,
	# 快速型敌人的速度与生命倍率。
	"enemy_swift_speed_multiplier": 0.72,
	"enemy_swift_hp_multiplier": 0.78,
	# 重装型敌人的速度与生命倍率。
	"enemy_brute_speed_multiplier": 1.28,
	"enemy_brute_hp_multiplier": 1.65,

	# ── 第二张地图额外难度 ─────────────────────────────────────────
	# 第二图敌人生命、攻击与生成速度的整体倍率。
	"map_2_enemy_multiplier": 1.18,
	# 第二图更早进入中期和后期的填充率阈值。
	"map_2_mid_fill": 0.26,
	"map_2_late_fill": 0.58,

	# ── 地形锚点奖励 ───────────────────────────────────────────────
	# 平原锚点加速的设计持续时间；当前即时作用于行动计时器。
	"anchor_plain_boost_duration": 8.0,
	# 平原锚点触发时，现有神祇行动计时器乘以该值。
	"anchor_plain_speed_multiplier": 0.72,
	# 山地锚点恢复的中央核心生命。
	"anchor_mountain_core_heal": 8,
	# 森林锚点恢复每座现存神祇的生命。
	"anchor_forest_heal": 4,

	# ── 结算分数 ───────────────────────────────────────────────────
	"score_weights": {
		# 完成一张地图的固定基础分。
		"base_map_score": 1000,
		# 每点核心剩余生命提供的分数。
		"core_hp": 18,
		# 每个污染崩塌格扣除的分数。
		"collapse_penalty": 80,
		# 每经过一秒扣除的分数。
		"time_penalty_per_second": 1.2,
		# 每激活一个锚点提供的分数。
		"anchor": 180,
		# 每点剩余神力提供的少量分数。
		"resource": 2.0,
	},
	# “精打细算”成就允许的最大商店刷新次数。
	"achievement_refresh_limit": 4,
}

const BLESSINGS := {
	# 第二图开局额外获得3神力；只影响选择祝福后的连续流程。
	"initial_resource": {"title": "丰饶余烬", "description": "第二张地图初始神力 +3。", "initial_resource": 3.0},
	# 进入下一图时，中央核心最大生命和当前生命都额外增加8。
	"core_health": {"title": "不灭核心", "description": "核心最大生命 +8。", "core_max_hp": 8.0},
	# 本张地图第一座攻击神的最终建造费用减少2，最低不会低于0。
	"first_attack_discount": {"title": "锋芒初显", "description": "第一座攻击神祇费用降低 2。", "first_attack_discount": 2.0},
	# 本张地图第一座资源神的最终建造费用减少1.5。
	"first_resource_discount": {"title": "丰收先声", "description": "第一座资源神祇费用降低 1.5。", "first_resource_discount": 1.5},
	# 每次进入建设阶段时至少补充1次免费刷新机会。
	"free_refresh": {"title": "商旅眷顾", "description": "每个建设阶段第一次刷新免费。", "build_free_refresh": 1.0},
	# 所有升级费用乘以0.75；与基础配置中的升级折扣采用同一比例语义。
	"upgrade_discount": {"title": "神性精炼", "description": "所有神祇升级费用降低 25%。", "upgrade_discount": 0.25},
	# 每格污染崩塌阈值在基础值之上增加1。
	"pollution_limit": {"title": "坚韧大地", "description": "所有格子的污染上限 +1。", "pollution_limit": 1.0},
	# 下一张地图开局自动获得一张随机地形的两格免费地块。
	"random_domino": {"title": "塑界赠礼", "description": "第二张地图开局获得一张随机两格地块。", "random_domino": 1.0},
	# 所有攻击神在等级和共鸣倍率计算前，基础最大生命额外增加3。
	"attack_health": {"title": "战神护佑", "description": "攻击神祇基础生命提高 3。", "attack_hp": 3.0},
	# 所有资源神最终生产间隔再缩短10%。
	"resource_speed": {"title": "丰饶脉动", "description": "资源神祇生产间隔缩短 10%。", "resource_speed": 0.1},
}

const ACHIEVEMENTS := {
	# 以下项目只有文案；实际判定条件位于 ProgressManager._evaluate_achievements。
	"self_sufficient": {"title": "自给自足", "description": "不建造资源神祇完成第一张地图。"},
	"no_land_lost": {"title": "寸土不失", "description": "没有格子因污染崩塌并完成一张地图。"},
	"rebuilder": {"title": "重建者", "description": "单局重新填补至少 10 个崩塌格子并获胜。"},
	"four_terrain": {"title": "四域共鸣", "description": "一座神祇同时获得四种相邻神域共鸣。"},
	"deity_refinement": {"title": "神祇精炼", "description": "单局将至少三座神祇升级过至少一次。"},
	"frugal": {"title": "精打细算", "description": "使用较少刷新次数完成第一张地图。"},
	"one_god_land": {"title": "无神之地", "description": "只使用一座攻击神祇完成第一张地图。"},
	"four_anchors": {"title": "四锚归位", "description": "在第二张地图激活全部四个地形锚点。"},
	"planet_born": {"title": "星球初成", "description": "连续完成第一张和第二张地图。"},
}
