# 当前仍需制作的资源

这份文件只列出磁盘中目前确实不存在的资源。现有开始页、帮助页、各页面底图、主页按钮、音乐图标、敌方核心、警告箭头和攻击静态特效均已接入。

## 1. 游戏字体

```text
assets/fonts/game_font.ttf
```

- 推荐使用具有中文字符的奇幻、圆润或略带碑刻感字体。
- 必须允许项目内嵌和发布。
- 缺失时自动使用 Godot 默认字体。

## 2. 尚缺少的功能图标

目录：`assets/art/ui/`，建议 64×64，透明 PNG。

```text
icon_price.png
icon_map_fill.png
icon_enemy_core.png
icon_victory.png
icon_cheat.png
icon_map_1.png
icon_map_2.png
icon_map_3.png
icon_map_4.png
icon_map_5.png
icon_map_6.png
icon_move.png
```

- `icon_map_1`～`icon_map_6` 用于尚未生成真实地图缩略图时的立方星球占位。
- 完成地图后，星球页面会优先显示该局真实地形缩略图。
- 图标缺失时继续复用现有神力、攻击、星球等图标。
- `icon_move.png` 用于神祇迁移，建议表现为弧形足迹、传送箭头或位置交换。

### 祝福三选一按钮（可后补）

目录：`assets/art/ui/`

```text
button_blessing_1.png
button_blessing_2.png
button_blessing_3.png
```

- 建议尺寸约 520×560，透明 PNG，三个按钮保持同一视觉体系。
- 图片作为每张祝福卡的按钮装饰，中央需为标题和两三行说明留出清晰区域。
- 缺失时继续使用现有通用按钮皮肤；祝福界面不再额外铺整块底图。

## 3. 动画需要交付什么

你只需要制作连续 PNG 帧，不需要手写 `.tres`。例如：

```text
deity_attack_plain_idle_00.png
deity_attack_plain_idle_01.png
deity_attack_plain_attack_00.png
deity_attack_plain_attack_01.png
```

PNG 做完后，需要在 Godot 的 `SpriteFrames` 编辑器中组装一次：

1. 新建动画名，如 `idle`、`attack`。
2. 拖入连续 PNG 帧。
3. 设置 FPS 与循环。
4. 保存到指定 `*_frames.tres` 路径。

| 对象 | 动画 | 建议帧数 | FPS | 循环 |
|---|---|---:|---:|:---:|
| 神祇 | `idle` | 6～8 | 6～8 | 是 |
| 攻击神祇 | `attack` | 5～7 | 10～14 | 否 |
| 资源神祇 | `produce` | 5～7 | 8～12 | 否 |
| 敌人 | `move` | 6～8 | 8～12 | 是 |
| 敌人 | `attack` | 5～7 | 10～14 | 否 |
| 敌人 | `death` | 7～10 | 12～16 | 否 |
| 玩家核心/敌方核心 | `idle` | 6～8 | 5～8 | 是 |
| 核心 | `hit`、`destroyed` | 5～10 | 12～16 | 否 |
| 混沌格 | `idle` | 8～12 | 5～8 | 是 |
| 生命/神力图标 | `idle` | 6～8 | 8～12 | 是 |
| 地图框/背景 | `idle` | 8～16 | 4～8 | 是 |
| 起手、命中、状态特效 | `default` | 5～9 | 12～18 | 否 |
| 弹道 | `move` | 4～8 | 10～16 | 是 |

## 4. 已完成的神祇与敌人动画

```text
assets/animations/deities/attack/deity_attack_plain_frames.tres
assets/animations/deities/attack/deity_attack_forest_frames.tres
assets/animations/deities/attack/deity_attack_mountain_frames.tres
assets/animations/deities/attack/deity_attack_river_frames.tres
assets/animations/deities/resource/deity_resource_plain_frames.tres
assets/animations/deities/resource/deity_resource_forest_frames.tres
assets/animations/deities/resource/deity_resource_mountain_frames.tres
assets/animations/deities/resource/deity_resource_river_frames.tres
assets/animations/enemies/enemy_default_frames.tres
```

四种攻击神的 `idle/attack`、四种资源神的 `idle/produce`、敌人的 `move/attack` 均已批量组装并接入。

以后新增或替换规范命名的帧，可运行：

```text
res://tools/build_spriteframes.gd
```

重新生成所有现有神祇与敌人动画资源。

## 5. 仍缺少的核心与环境动画

```text
assets/animations/enemies/enemy_core_frames.tres
assets/animations/core/core_frames.tres
assets/animations/terrain/terrain_void_frames.tres
```

### UI、地图框与背景

```text
assets/animations/ui/icon_core_hp_frames.tres
assets/animations/ui/icon_divine_power_frames.tres
assets/animations/ui/map_frame_frames.tres
assets/animations/ui/game_background_frames.tres
```

## 6. 分类攻击动画（可最后制作）

静态图已经存在，只缺动画版：

```text
assets/animations/effects/muzzle_deity_plain_frames.tres
assets/animations/effects/muzzle_deity_forest_frames.tres
assets/animations/effects/muzzle_deity_mountain_frames.tres
assets/animations/effects/muzzle_deity_river_frames.tres
assets/animations/effects/muzzle_enemy_frames.tres

assets/animations/effects/projectile_deity_plain_frames.tres
assets/animations/effects/projectile_deity_forest_frames.tres
assets/animations/effects/projectile_deity_mountain_frames.tres
assets/animations/effects/projectile_deity_river_frames.tres
assets/animations/effects/projectile_enemy_frames.tres
assets/animations/effects/projectile_deity_mountain_splash_frames.tres
assets/animations/effects/projectile_deity_river_chain_frames.tres

assets/animations/effects/hit_deity_plain_frames.tres
assets/animations/effects/hit_deity_forest_frames.tres
assets/animations/effects/hit_deity_mountain_frames.tres
assets/animations/effects/hit_deity_river_frames.tres
assets/animations/effects/hit_enemy_frames.tres
assets/animations/effects/hit_deity_mountain_splash_frames.tres
assets/animations/effects/hit_deity_river_chain_frames.tres
assets/animations/effects/status_deity_forest_slow_frames.tres
```

## 7. 当前不需要制作

- 第三阶段污染贴图。
- 拼图形状图标。
- 商店标题图片。
- 阶段横幅图片。
- 塑地等级图标。
