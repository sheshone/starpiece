# 游戏规则与数值调整总表

## 关卡锚点数量

配置位置：`GameDefinitions.BALANCE.map_anchor_count`

当前逐关数量：`0 / 2 / 4 / 6 / 8 / 10`。

这份文件用于集中查看规则和数值。真正运行时读取的数值位于：

```text
scripts/data/game_definitions.gd
```

调整本文件后，需要把同名键同步到 `GameDefinitions.BALANCE`。键名已经在每项后标出，避免在多个脚本中查找。

## 1. 一局的循环

1. 建设阶段购买并放置地块。
2. 每片上下左右连通的同类地形称为一个神域。
3. 一片神域最多拥有一座神祇。
4. 建设阶段可以建造、升级或迁移神祇。
5. 点击时间流动进入战斗阶段。
6. 战斗计时结束后停止安排新敌人，但必须消灭场上敌人和已经预告的敌人，才会返回建设阶段。
7. 摧毁所有敌方核心并填满地图后胜利。

## 2. 初始经济与费用

| 项目 | 配置键 | 当前值 |
|---|---|---:|
| 战斗结束核心收入 | `combat_base_income` | 4.0 |
| 攻击神建造费用 | `attack_deity_cost` | 5.0 |
| 资源神建造费用 | `resource_deity_cost` | 4.0 |
| 迁移一次的费用 | `deity_migration_cost` | 1.5 |
| 2级升级费用 | `deity_upgrade_cost_by_level[2]` | 4.0 |
| 3级升级费用 | `deity_upgrade_cost_by_level[3]` | 7.0 |

地块价格由格数决定：

| 格数 | 配置键 | 费用 |
|---:|---|---:|
| 1 | `terrain_card_cost_by_size[1]` | 1.0 |
| 2 | `terrain_card_cost_by_size[2]` | 1.5 |
| 3 | `terrain_card_cost_by_size[3]` | 2.0 |
| 4 | `terrain_card_cost_by_size[4]` | 2.5 |

## 3. 神域规则

- 只计算上下左右连通，斜角不连通。
- 一片神域只能拥有一座神祇。
- 新地块若同时连接两个已经拥有神祇的同类神域，则该放置无效。
- 神域被污染分割后，每个新区域重新计算归属与面积。
- 神祇脚下格子崩塌时，神祇死亡。
- 神域之间的地形共鸣保留；旧的“攻击神和资源神互相相邻奖励”已经删除。

### 面积倍率

配置键：

```text
domain_area_step_to_six
domain_area_step_after_six
```

| 面积 | 核心属性倍率 |
|---:|---:|
| 1 | ×1.00 |
| 2 | ×1.20 |
| 3 | ×1.40 |
| 4 | ×1.60 |
| 5 | ×1.80 |
| 6 | ×2.00 |
| 7以后 | 每格再增加 ×0.05 |

面积只提高：

- 攻击神基础伤害。
- 资源神基础产量。

不提高攻击速度、射程、生命或特殊能力强度。

## 4. 神祇迁移

建设阶段点击已有神祇后选择迁移：

- 只能移动到同一连通神域中的空格。
- 目标格不能有敌人或其他神祇。
- 每次迁移消耗 `deity_migration_cost`。
- 神祇类型、等级、当前生命、护盾、攻击充能和生产充能全部保留。
- 战斗阶段不能迁移。

## 5. 基础属性

| 项目 | 配置键 | 当前值 |
|---|---|---:|
| 神祇基础生命 | `deity_base_hp` | 8 |
| 攻击神基础伤害 | `attack_base_damage` | 2 |
| 攻击神基础射程 | `attack_base_range` | 2 |
| 攻击间隔 | `attack_base_interval` | 1.35秒 |
| 资源神基础产量 | `resource_base_amount` | 0.5 |
| 资源神生产间隔 | `resource_base_interval` | 4.5秒 |
| 资源效果显示范围 | `resource_effect_range` | 2格 |
| 攻击边缘判定宽容值 | `attack_range_tolerance` | 1.0格 |

## 6. 等级倍率

| 等级 | 伤害 | 产量 | 生命 | 特殊效果 | 工作间隔 |
|---:|---:|---:|---:|---:|---:|
| 1 | ×1.00 | ×1.00 | ×1.00 | ×1.00 | ×1.00 |
| 2 | ×1.50 | ×1.45 | ×1.35 | ×1.30 | ×0.88 |
| 3 | ×2.15 | ×2.00 | ×1.80 | ×1.65 | ×0.74 |

攻击神升级射程：

| 等级 | 通用射程增加 | 山岳攻击神额外增加 |
|---:|---:|---:|
| 1 | +0 | +0 |
| 2 | +1.5 格 | +0.75 格 |
| 3 | +3.0 格 | +1.5 格 |

配置键：

```text
deity_level_damage_multiplier
deity_level_amount_multiplier
deity_level_hp_multiplier
deity_level_special_multiplier
deity_level_interval_multiplier
deity_level_range_bonus
mountain_deity_level_range_bonus
```

## 6.1 迁移与移除

- 迁移仅能从右侧迁移按钮进入，只允许建设阶段操作。
- 迁移目标必须是同一连通神域中的空格，等级、生命与充能全部保留。
- 点击已有神祇时，单位旁只显示“升级”和“移除”。
- 移除仅能从神祇旁的移除按钮执行，建设阶段可用，默认消耗 1 神力。
- 移除不会返还建造、升级或迁移费用。

配置键：

```text
deity_migration_cost
deity_removal_cost
```

## 7. 地形共鸣

只有面积至少2格、拥有存活神祇的相邻神域才能提供共鸣。同一种共鸣最多计算一次。

- 平原：缩短基础攻击或生产间隔。
- 山地：攻击神增加射程；资源神增加单次产量。
- 河流：减少特殊能力所需的普通行动次数。
- 森林：增加最大生命、治疗和护盾效果。

对应配置：

```text
plain_resonance_interval_multiplier
mountain_resonance_range_bonus
mountain_resonance_resource_bonus
river_resonance_trigger_reduction
forest_resonance_hp_multiplier
forest_resonance_heal_shield_multiplier
```

## 8. 八座神祇关键词

| 地形 | 攻击神 | 资源神 |
|---|---|---|
| 平原 | 快速直射、连续射击 | 高频生产、额外生产 |
| 山地 | 远程炮击、范围伤害 | 慢速高产、额外神力 |
| 河流 | 弹射、更多连锁 | 正常生产、免费刷新 |
| 森林 | 追踪、减速、自愈 | 生命绽放、治疗、护盾 |

## 9. 敌人与波次

| 项目 | 配置键 | 当前值 |
|---|---|---:|
| 敌人基础生命 | `enemy_base_hp` | 2 |
| 每轮生命成长 | `enemy_hp_per_round` | 0.45 |
| 基础攻击 | `enemy_base_attack` | 1 |
| 每轮攻击成长 | `enemy_attack_per_round` | 0.12 |
| 基础生成间隔 | `enemy_base_spawn_interval` | 4.1秒 |
| 最短生成间隔 | `enemy_min_spawn_interval` | 0.75秒 |
| 移动间隔 | `enemy_move_interval` | 0.72秒 |
| 出怪预告时间 | `enemy_core_warning_time` | 3.4秒 |

寻路代价：

| 地形 | 代价 |
|---|---:|
| 平原 | 0.8 |
| 森林 | 1.4 |
| 河流 | 2.2 |
| 山地 | 不可通行 |
| 混沌 | 1.0 |

## 10. 污染

- 污染上限：`cell_pollution_limit`，当前3。
- 敌人死亡或抵达核心时会污染格子。
- 达到上限后格子崩塌。
- 崩塌会立即重新计算神域面积、共鸣、路线和神祇属性。

## 11. 界面与交互

- 敌人的点击判定优先于地块。
- 建设和战斗阶段都能点击敌人或神祇查看面板与范围。
- 查看单位时，其余地图降低明度，范围从单位向外展开。
- 攻击神显示攻击范围；资源神显示效果范围；敌人显示近战威胁范围。
- 卡牌购买后先在原位置虚化，地块放置完成后才显示已购买空位。
- 时间流动按钮使用双拍心跳动画。
- `F3`：调试统计。
- `F4`：作弊面板。

## 12. 数值页面构成

左下战术面板按以下顺序显示：

1. 当前对象名称。
2. 等级与生命。
3. 神域面积的模糊描述：不大、比较大、很大。
4. 相邻朋友数量的模糊描述：没有、一个、一些、许多。
5. 单位功能关键词。

详细精确数值仍保留在点击后的单位详情和调试面板中。

## 13. 其余配置的逐项说明

以下配置同样位于 `GameDefinitions.BALANCE`，代码旁已加入中文注释。

### 敌人类型与阶段倍率

| 配置键 | 当前值 | 说明 |
|---|---:|---|
| `enemy_mid_fill` | 0.34 | 地图填充率达到34%后进入中期 |
| `enemy_late_fill` | 0.67 | 地图填充率达到67%后进入后期 |
| `enemy_mid_hp_multiplier` | 1.35 | 中期敌人生命倍率 |
| `enemy_late_hp_multiplier` | 1.90 | 后期敌人生命倍率 |
| `enemy_mid_attack_multiplier` | 1.20 | 中期敌人攻击倍率 |
| `enemy_late_attack_multiplier` | 1.55 | 后期敌人攻击倍率 |
| `enemy_mid_spawn_multiplier` | 0.82 | 中期出怪间隔倍率，越小越快 |
| `enemy_late_spawn_multiplier` | 0.58 | 后期出怪间隔倍率 |
| `enemy_swift_speed_multiplier` | 0.72 | 快速敌人的移动间隔倍率 |
| `enemy_swift_hp_multiplier` | 0.78 | 快速敌人的生命倍率 |
| `enemy_brute_speed_multiplier` | 1.28 | 重装敌人的移动间隔倍率 |
| `enemy_brute_hp_multiplier` | 1.65 | 重装敌人的生命倍率 |

### 敌方核心

| 配置键 | 当前值 | 说明 |
|---|---:|---|
| `enemy_core_hp` | 18 | 每座敌方核心最大生命 |
| `enemy_core_reward` | 2.0 | 摧毁核心立即获得的神力 |
| `enemy_first_warning_delay` | 0.1秒 | 战斗开始后第一次预告的等待时间 |
| `enemy_core_initial_active` | 2 | 前期最多激活的敌方核心 |
| `enemy_core_mid_active` | 5 | 中期最多激活的敌方核心 |
| `enemy_core_late_active` | 8 | 后期最多激活的敌方核心 |
| `enemy_core_pressure_reduction` | 0.07 | 每摧毁一座核心后，剩余出怪间隔增加7% |

各地图敌方核心数量：

```text
map_enemy_core_count = {1:4, 2:5, 3:6, 4:7, 5:8, 6:8}
```

各地图锚点数量：

```text
map_anchor_count = {1:0, 2:2, 3:4, 4:6, 5:8, 6:10}
```

### 第二张地图

| 配置键 | 当前值 | 说明 |
|---|---:|---|
| `map_2_enemy_multiplier` | 1.18 | 第二图敌人生命、攻击和生成压力的整体倍率 |
| `map_2_mid_fill` | 0.26 | 第二图进入中期的填充率 |
| `map_2_late_fill` | 0.58 | 第二图进入后期的填充率 |

### 锚点奖励

| 配置键 | 当前值 | 说明 |
|---|---:|---|
| `anchor_plain_boost_duration` | 8秒 | 平原加速效果的设计持续时间 |
| `anchor_plain_speed_multiplier` | 0.72 | 激活时现有行动计时器乘数 |
| `anchor_mountain_core_heal` | 8 | 山地锚点恢复核心生命 |
| `anchor_forest_heal` | 4 | 森林锚点恢复每座神祇生命 |

### 分数

| 配置键 | 当前值 | 说明 |
|---|---:|---|
| `base_map_score` | 1000 | 完成地图基础分 |
| `core_hp` | 18 | 每点剩余核心生命得分 |
| `collapse_penalty` | 80 | 每个崩塌格扣分 |
| `time_penalty_per_second` | 1.2 | 每秒通关时间扣分 |
| `anchor` | 180 | 每个已激活锚点得分 |
| `resource` | 2.0 | 每点剩余神力的少量得分 |
| `achievement_refresh_limit` | 4 | “精打细算”允许的最大刷新次数 |

## 14. 初始神力计算

开局神力没有在多个脚本写死，而是由下式计算：

```text
攻击神费用
+ 资源神费用
+ 最便宜的一格地块费用
+ 开局预留神力
```

当前为：

```text
5 + 4 + 1 + 1 = 11 神力
```

对应代码位于：

```text
scripts/autoload/resource_manager.gd
```

因此修改神祇或地块费用后，开局神力会自动同步变化。
