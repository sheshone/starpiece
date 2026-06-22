# 文案与数值调整索引

## 一、主要数值

所有核心玩法数值集中在：

```text
scripts/data/game_definitions.gd
```

### 神祇经济与升级

| 配置键 | 用途 |
|---|---|
| `attack_deity_cost` | 攻击神祇价格 |
| `resource_deity_cost` | 资源神祇价格 |
| `deity_upgrade_cost_by_level` | 升到 2、3 级的价格 |
| `deity_level_damage_multiplier` | 各等级攻击倍率 |
| `deity_level_amount_multiplier` | 各等级生产倍率 |
| `deity_level_hp_multiplier` | 各等级生命倍率 |
| `deity_level_special_multiplier` | 各等级特殊能力倍率 |
| `deity_level_interval_multiplier` | 各等级攻击/生产间隔倍率 |
| `deity_level_range_bonus` | 各等级攻击射程增加值 |
| `mountain_deity_level_range_bonus` | 山岳攻击神额外等级射程 |

### 神域面积

| 配置键 | 默认值 | 用途 |
|---|---:|---|
| `domain_area_step_to_six` | 0.20 | 1～6 格时每增加一格的倍率 |
| `domain_area_step_after_six` | 0.05 | 6 格后每增加一格的倍率 |

计算函数位于：

```text
scripts/map/grid_map.gd -> domain_area_multiplier()
```

### 神域共鸣

| 配置键 | 用途 |
|---|---|
| `plain_resonance_interval_multiplier` | 平原共鸣的工作间隔倍率 |
| `mountain_resonance_range_bonus` | 山地共鸣增加的攻击射程 |
| `mountain_resonance_resource_bonus` | 山地共鸣增加的基础产量 |
| `river_resonance_trigger_reduction` | 河流共鸣减少的特殊触发次数 |
| `forest_resonance_hp_multiplier` | 森林共鸣生命倍率 |
| `forest_resonance_heal_shield_multiplier` | 森林共鸣治疗与护盾倍率 |
| `deity_migration_cost` | 每次迁移神祇的固定神力费用 |
| `resource_effect_range` | 资源神点击后显示的效果范围 |
| `attack_range_tolerance` | 攻击边缘判定宽容值 |

神域相邻、神祇相邻判定集中在：

```text
scripts/map/grid_map.gd -> deity_domain_context()
scripts/map/grid_map.gd -> deity_stats()
```

### 特殊攻击与特殊生产

| 配置键 | 用途 |
|---|---|
| `special_trigger_every` | 默认每几次普通工作触发特殊效果 |
| `mountain_special_splash_multiplier` | 山地特殊攻击溅射倍率 |
| `river_special_extra_chains` | 河流特殊攻击额外弹射次数 |
| `forest_special_slow_duration` | 森林特殊攻击额外减速时间 |
| `forest_special_self_heal_ratio` | 森林攻击神特殊攻击自愈比例 |
| `forest_bloom_heal_ratio` | 生命绽放治疗比例 |
| `forest_bloom_shield_cap_ratio` | 临时护盾上限比例 |

对应行为位于：

```text
scripts/map/grid_map.gd -> _attack_with_deity()
scripts/map/grid_map.gd -> _produce_with_deity()
scripts/map/grid_map.gd -> _forest_life_bloom()
```

### 敌人、核心、污染与地图

仍全部位于 `GameDefinitions.BALANCE`：

- `enemy_*`：敌人生命、攻击、速度和生成。
- `enemy_core_*`：外围核心生命、奖励、激活和预警。
- `map_enemy_core_count`：图 1～图 6 的敌方核心数量。
- `map_anchor_count`：图 1～图 6 的必需锚点数量。
- `terrain_path_cost`：敌人加权寻路和移动耗时。默认平原 `0.8`、混沌 `1.0`、森林 `1.4`、河流 `2.2`；山脉在代码中固定为不可通行。
- `cell_pollution_limit`：污染上限。
- `terrain_card_cost_by_size`：地块价格。
- `combat_base_income`：每轮核心基础神力。
- `score_weights`：结算分数。

寻路和建设阶段路线预览位于：

```text
scripts/map/grid_map.gd -> _weighted_path()
scripts/map/grid_map.gd -> _draw_preview_routes()
```

## 二、主要文案

| 文案类别 | 文件 |
|---|---|
| 地形名、神祇名、祝福、成就 | `scripts/data/game_definitions.gd` |
| 主页、统计、排行、星球、设置、图鉴 | `scripts/ui/start_screen.gd` |
| 局内悬停、升级、设置、结算、失败、祝福 | `scripts/ui/game_ui.gd` |
| 新手引导、阶段提示、购买和放置提示 | `scripts/game.gd` |
| 神祇功能、敌人信息、核心摧毁提示 | `scripts/map/grid_map.gd` |
| 商店按钮和空位提示 | `scripts/ui/hand_ui.gd` |

快速查找全部中文字符串：

```powershell
rg -n '"[^"]*[\p{Han}][^"]*"' scripts
```

## 三、界面与素材接口

所有图片、动画和音效路径集中在：

```text
scripts/autoload/asset_catalog.gd
```

字体接口：

```text
assets/fonts/game_font.ttf
```

缺失素材清单见：

```text
MISSING_ASSETS.md
```

### 星球历史与页面布局

- 星球历史存档：`scripts/autoload/progress_manager.gd`
  - `current_planet_faces`：当前星球已完成的地图面。
  - `planet_history`：历史星球；当前限制为 9 颗历史星球加 1 颗当前星球。
- 可旋转立方体：`scripts/ui/planet_cube_view.gd`
- 主页纸张、图鉴分页和星球切换：`scripts/ui/start_screen.gd`
- 局内纸张提示、升级窗口和设置：`scripts/ui/game_ui.gd`
