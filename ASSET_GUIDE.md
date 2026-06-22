# 拼图神祇塔防：美术与音效接入规范

> 当前玩法文案与数值调整位置统一索引见 `TUNING_GUIDE.md`。本文件主要负责素材路径与规格；若旧玩法描述与索引冲突，以代码和 `TUNING_GUIDE.md` 为准。

> 只需要查看当前尚未提供的资源时，请直接阅读 `MISSING_ASSETS.md`。本文件保留完整接入规范。

## 1. 加载与回退规则

- 所有正式资源路径集中在 `scripts/autoload/asset_catalog.gd`。
- 表现层通过 `AssetCatalog.texture()`、`animation()`、`audio()` 获取资源。
- 图片缺失时继续使用现有程序绘制的色块、圆形、文字和线条占位。
- 动画资源缺失时使用静态贴图；静态贴图也缺失时使用程序占位。
- 音效缺失时 `AudioManager` 静默跳过，不报错、不阻断玩法。
- 替换素材时优先保持下表文件名不变；放入对应目录后 Godot 会自动导入。

## 2. 命名规范

- 全部使用小写英文、数字和下划线：`category_role_variant_state.ext`。
- 不使用空格、中文文件名或大小写混合。
- 静态图片用 `.png`，有损大背景可用 `.webp`。
- 短音效优先 `.wav`；较长音效或环境声用 `.ogg`。
- Godot 动画资源统一保存为 `*_frames.tres`，源序列帧保存在对应 `assets/art` 目录。
- 透明对象四周保留 4～8 像素安全边距，避免导入过滤后切边。

## 3. 目录结构

```text
assets/
  art/
    terrain/                 地形、虚空、污染覆盖层
    deities/attack/          四种攻击神祇形态
    deities/resource/        四种资源神祇形态
    enemies/                 敌人静态图和源序列帧
    core/                    中央核心
    cards/                   商店卡框
    effects/                 预览、弹道、命中、污染、崩塌
    ui/                      操作图标与可选按钮皮肤
  animations/
    terrain/                 虚空/混沌呼吸动画
    deities/attack/          攻击神祇 SpriteFrames .tres
    deities/resource/        资源神祇 SpriteFrames .tres
    enemies/                 敌人 SpriteFrames .tres
    core/                    核心 SpriteFrames .tres
    effects/                 特效 SpriteFrames .tres
    ui/                      生命、神力、地图框、背景动画
  audio/
    sfx/                     游戏短音效
    music/                   菜单、建设、战斗循环音乐
```

## 4. 图片资源清单

地图实际显示格约为 54×54。建议源文件使用 128×128，以便以后放大和制作高清导出。

| 资源 | 用途 | 格式 | 建议尺寸 | 透明 | 文件名与路径 |
|---|---|---|---:|:---:|---|
| 平原 | 地图格底图 | PNG | 128×128 | 否 | `assets/art/terrain/terrain_plain.png` |
| 森林 | 地图格底图 | PNG | 128×128 | 否 | `assets/art/terrain/terrain_forest.png` |
| 山地 | 地图格底图 | PNG | 128×128 | 否 | `assets/art/terrain/terrain_mountain.png` |
| 河流 | 地图格底图 | PNG | 128×128 | 否 | `assets/art/terrain/terrain_river.png` |
| 虚空 | 未填充地图格 | PNG/WebP | 128×128 | 否 | `assets/art/terrain/terrain_void.png` |
| 污染覆盖 | 叠加在有污染的格子上 | PNG | 128×128 | 是 | `assets/art/terrain/terrain_pollution_overlay.png` |
| 合法预览 | 合法拼图位置提示 | PNG | 128×128 | 是 | `assets/art/effects/preview_valid.png` |
| 非法预览 | 非法拼图位置提示 | PNG | 128×128 | 是 | `assets/art/effects/preview_invalid.png` |
| 原野攻击神 | 平原攻击形态 | PNG | 128×128 | 是 | `assets/art/deities/attack/deity_attack_plain.png` |
| 森境攻击神 | 森林攻击形态 | PNG | 128×128 | 是 | `assets/art/deities/attack/deity_attack_forest.png` |
| 山岳攻击神 | 山地攻击形态 | PNG | 128×128 | 是 | `assets/art/deities/attack/deity_attack_mountain.png` |
| 川流攻击神 | 河流攻击形态 | PNG | 128×128 | 是 | `assets/art/deities/attack/deity_attack_river.png` |
| 原野资源神 | 平原资源形态 | PNG | 128×128 | 是 | `assets/art/deities/resource/deity_resource_plain.png` |
| 森境资源神 | 森林资源形态 | PNG | 128×128 | 是 | `assets/art/deities/resource/deity_resource_forest.png` |
| 山岳资源神 | 山地资源形态 | PNG | 128×128 | 是 | `assets/art/deities/resource/deity_resource_mountain.png` |
| 川流资源神 | 河流资源形态 | PNG | 128×128 | 是 | `assets/art/deities/resource/deity_resource_river.png` |
| 当前敌人 | 当前侵蚀体 | PNG | 128×128 | 是 | `assets/art/enemies/enemy_default.png` |
| 中央核心 | 核心地图对象 | PNG | 160×160 | 是 | `assets/art/core/core.png` |
| 地块卡框 | 商店卡牌透明装饰框 | PNG | 300×250 | 是 | `assets/art/cards/card_frame_terrain.png` |
| 普通弹道 | 默认攻击飞行物 | PNG | 64×32 | 是 | `assets/art/effects/projectile_default.png` |
| 命中特效 | 普通命中闪光 | PNG | 128×128 | 是 | `assets/art/effects/hit_default.png` |
| 污染增长 | 污染增加瞬间效果 | PNG/序列帧 | 128×128 | 是 | `assets/art/effects/pollution_growth.png` |
| 格子崩塌 | 格子变回虚空的效果 | PNG/序列帧 | 192×192 | 是 | `assets/art/effects/cell_collapse.png` |
| 地图装饰框 | 包围左侧地图区域 | PNG/WebP | 1000×1000 | 是 | `assets/art/ui/map_frame.png` |
| 游戏动态背景静态回退 | 局内全屏背景 | WebP/PNG | 1920×1080 | 否 | `assets/art/ui/game_background.png` |
### 当前卡牌插画方案

商店会优先使用四张专用卡牌插画，并叠加 `card_frame_terrain.png`、名称条与价格：

| 地形 | 卡牌插画路径 |
|---|---|
| 平原 | `assets/art/cards/card_art_plain.png` |
| 森林 | `assets/art/cards/card_art_forest.png` |
| 山地 | `assets/art/cards/card_art_mountain.png` |
| 河流 | `assets/art/cards/card_art_river.png` |

专用插画缺失时自动回退到对应地形贴图。卡牌悬停时会平滑放大、轻微倾斜并提高显示层级。

当前卡框源文件为 300×250。透明边缘内的安全显示区约为：

```text
x：20～280
y：30～230
```

代码会将插画限制在该区域内，不再铺满透明外沿。卡牌名称只显示地形名，价格使用“数值＋神力图标”，形状使用右上角小图标。
当前界面已隐藏卡牌上的地形文字，地形由插画辨识；悬停信息仍会显示完整卡牌名称。

### 操作图标与按钮皮肤

现有刷新、锁定图标已经接入。下列资源均为可选：缺失时按钮会继续显示文字或使用 Godot 默认皮肤。

| 资源 | 用途 | 格式 | 建议尺寸 | 透明 | 路径 |
|---|---|---|---:|:---:|---|
| 解锁图标 | 商店解锁状态 | PNG/SVG | 64×64 | 是 | `assets/art/ui/icon_unlock.png` |
| 时间流动图标 | 右侧大型时间流动按钮 | PNG/SVG | 128×128 | 是 | `assets/art/ui/icon_time_flow.png` |
| 开始图标 | 开始页面按钮 | PNG/SVG | 96×96 | 是 | `assets/art/ui/icon_start.png` |
| 帮助图标 | 游戏帮助按钮 | PNG/SVG | 64×64 | 是 | `assets/art/ui/icon_help.png` |
| 攻击神祇图标 | 可选通用攻击神图标 | PNG/SVG | 96×96 | 是 | `assets/art/ui/icon_attack_deity.png` |
| 资源神祇图标 | 可选通用资源神图标 | PNG/SVG | 96×96 | 是 | `assets/art/ui/icon_resource_deity.png` |
| 商店空位图 | 替代“已购”文字，表示该位置已购买 | PNG/SVG | 150×125 | 是 | `assets/art/ui/shop_slot_empty.png` |
| 普通按钮皮肤 | 默认按钮背景 | PNG | 256×96 | 是 | `assets/art/ui/button_normal.png` |
| 悬停按钮皮肤 | 鼠标悬停背景 | PNG | 256×96 | 是 | `assets/art/ui/button_hover.png` |
| 按下按钮皮肤 | 按下状态背景 | PNG | 256×96 | 是 | `assets/art/ui/button_pressed.png` |
| 禁用按钮皮肤 | 不可用状态背景 | PNG | 256×96 | 是 | `assets/art/ui/button_disabled.png` |

按钮皮肤建议制作成可九宫格拉伸的边框，四周至少保留 12 像素稳定边缘。
开始、帮助、时间流动和神祇安置按钮会直接使用图标，不使用按钮底图；辉光按照图片透明区域的真实轮廓生成，不再显示矩形光框。
刷新与锁定仍使用四态按钮底图，保持商店操作区的按钮感。
开始与帮助按钮使用 156×156 显示盒；时间流动使用 124×124，并贴近地图右侧。
开始页面暂不显示游戏标题，开始与帮助图标并排居中显示。
神祇安置按钮使用 `icon_attack_deity.png` 和 `icon_resource_deity.png`，具体地形形态与能力通过悬停说明展示。
卡牌形状固定由程序小方格绘制，不再需要额外形状图标。

## 5. 动画资源清单

推荐每帧 128×128，6～12 FPS；崩塌和命中特效可使用 12～18 FPS。源序列帧使用：

```text
object_variant_idle_00.png
object_variant_idle_01.png
object_variant_attack_00.png
```

在 Godot 中建立 `SpriteFrames` 后保存到以下路径：

| 动画 | 推荐内容 | SpriteFrames 路径 |
|---|---|---|
| 八种神祇形态 | `idle`，攻击神可加 `attack`，资源神可加 `produce` | `assets/animations/deities/{attack|resource}/deity_{role}_{terrain}_frames.tres` |
| 当前敌人 | `move`、`attack`、`death` | `assets/animations/enemies/enemy_default_frames.tres` |
| 中央核心 | `idle`、`hit`、`destroyed` | `assets/animations/core/core_frames.tres` |
| 污染增长 | 一次性 `default` | `assets/animations/effects/pollution_growth_frames.tres` |
| 格子崩塌 | 一次性 `default` | `assets/animations/effects/cell_collapse_frames.tres` |
| 虚空/混沌 | 循环 `idle`，缓慢呼吸、星尘或旋涡 | `assets/animations/terrain/terrain_void_frames.tres` |
| 生命图标 | 循环 `idle`，轻微心跳或光泽流动 | `assets/animations/ui/icon_core_hp_frames.tres` |
| 神力图标 | 循环 `idle`，能量旋转或亮度脉冲 | `assets/animations/ui/icon_divine_power_frames.tres` |
| 地图装饰框 | 循环 `idle`，边缘符文或微光流动 | `assets/animations/ui/map_frame_frames.tres` |
| 游戏背景 | 循环 `idle`，云雾、星尘或能量缓慢漂移 | `assets/animations/ui/game_background_frames.tres` |

动画路径已经登记在 `AssetCatalog.ANIMATION_PATHS`。神祇、虚空、生命、神力、地图框和背景会直接读取这些动画；资源缺失时分别回退到静态贴图和程序呼吸。

当前表现规则：

- 神祇显示尺寸约为地块的 133%，允许越过所属格边缘。
- 神祇按距离核心由近到远绘制，距离核心越远越靠前。
- 神祇静态回退会轻微呼吸，并使用无描边、半透明的双层圣光。
- 核心显示约为地块的 125%～134%，使用金色与青色半透明圣光呼吸，不再绘制暗红方形底图。
- 核心、神祇和敌人不再显示血条；受伤越重，红色侵蚀叠加越明显，主体透明度会轻微降低。
- 敌人显示尺寸约为地块的 122%～130%，使用无描边的红紫色半透明侵蚀光圈。
- 敌人逻辑仍按格结算，但画面会在两格之间平滑移动；存在 `move` 动画时会同时播放移动帧。
- 混沌格静态回退会进行约 91%～103.5% 的异步缩放，并产生紫青色亮度脉冲。

## 6. 音效资源清单

短音效推荐 WAV、48 kHz、16/24-bit、单声道；超过约 2 秒的声音推荐 OGG、48 kHz。所有音效峰值建议控制在 -1 dBFS 以下。

| 音效 | 用途 | 建议时长 | 格式 | 路径 |
|---|---|---:|---|---|
| 购买 | 从商店购买地块 | 0.15～0.5 s | WAV/OGG | `assets/audio/sfx/sfx_purchase.ogg` |
| 放置 | 地块或神祇落位 | 0.2～0.7 s | WAV/OGG | `assets/audio/sfx/sfx_place.ogg` |
| 刷新 | 免费刷新商店 | 0.3～0.8 s | WAV/OGG | `assets/audio/sfx/sfx_refresh.ogg` |
| 攻击 | 神祇发射攻击 | 0.1～0.5 s | WAV | `assets/audio/sfx/sfx_attack.ogg` |
| 命中 | 弹道击中敌人 | 0.1～0.5 s | WAV | `assets/audio/sfx/sfx_hit.ogg` |
| 资源产出 | 资源神祇生产神力 | 0.2～0.7 s | WAV/OGG | `assets/audio/sfx/sfx_resource_produce.ogg` |
| 敌人死亡 | 侵蚀体消失 | 0.3～0.9 s | WAV/OGG | `assets/audio/sfx/sfx_enemy_death.ogg` |
| 污染增加 | 格子污染 +1 | 0.2～0.8 s | WAV/OGG | `assets/audio/sfx/sfx_pollution_growth.ogg` |
| 格子崩塌 | 污染满后格子毁坏 | 0.5～1.5 s | OGG | `assets/audio/sfx/sfx_cell_collapse.ogg` |
| 建设阶段 | 进入建设阶段 | 0.5～1.5 s | OGG | `assets/audio/sfx/sfx_phase_build.ogg` |
| 战斗阶段 | 进入自动战斗 | 0.5～1.5 s | OGG | `assets/audio/sfx/sfx_phase_combat.ogg` |

### 细分音效接口

以下文件目前尚未放入。缺失时会自动回退到现有通用音效，不会静音或报错。

| 类别 | 文件 |
|---|---|
| 四种地块放置 | `sfx_place_terrain_plain.ogg`、`sfx_place_terrain_forest.ogg`、`sfx_place_terrain_mountain.ogg`、`sfx_place_terrain_river.ogg` |
| 四种攻击神安置 | `sfx_place_deity_attack_plain.ogg`、`sfx_place_deity_attack_forest.ogg`、`sfx_place_deity_attack_mountain.ogg`、`sfx_place_deity_attack_river.ogg` |
| 四种资源神安置 | `sfx_place_deity_resource_plain.ogg`、`sfx_place_deity_resource_forest.ogg`、`sfx_place_deity_resource_mountain.ogg`、`sfx_place_deity_resource_river.ogg` |
| 四种攻击形态攻击 | `sfx_attack_deity_plain.ogg`、`sfx_attack_deity_forest.ogg`、`sfx_attack_deity_mountain.ogg`、`sfx_attack_deity_river.ogg` |
| 四种资源形态生产 | `sfx_produce_deity_plain.ogg`、`sfx_produce_deity_forest.ogg`、`sfx_produce_deity_mountain.ogg`、`sfx_produce_deity_river.ogg` |
| 按钮点击 | `sfx_button_start.ogg`、`sfx_button_help.ogg`、`sfx_button_time_flow.ogg`、`sfx_button_refresh.ogg`、`sfx_button_lock.ogg`、`sfx_button_unlock.ogg`、`sfx_button_card_purchase.ogg` |

全部放在 `assets/audio/sfx/`。建议：

- 按钮：0.08～0.3 秒，轻、清晰，不要抢过音乐。
- 地块放置：0.2～0.7 秒；平原柔和、森林木叶、山地石质、河流水声。
- 神祇安置：0.4～1.0 秒；攻击神更锐利，资源神更温和。
- 神祇攻击：0.1～0.5 秒，并控制响度，避免多个塔同时攻击时刺耳。
- 资源生产：0.15～0.5 秒，建议比攻击音效低约 3～6 dB。

### 背景音乐

背景音乐已经接入，文件缺失时静默播放为空，不影响游戏。

| 音乐 | 使用场景 | 建议时长 | 格式 | 循环 | 路径 |
|---|---|---:|---|:---:|---|
| 菜单音乐 | 开始页面与帮助页面 | 60～120 s | OGG Vorbis | 是 | `assets/audio/music/music_menu.ogg` |
| 建设音乐 | 地块购买、拼接与神祇规划 | 90～180 s | OGG Vorbis | 是 | `assets/audio/music/music_build.ogg` |
| 战斗音乐 | 时间流动与自动塔防 | 90～180 s | OGG Vorbis | 是 | `assets/audio/music/music_combat.ogg` |

建议规格：

- 48 kHz、立体声、OGG Vorbis，质量约 5～7。
- 首尾需要无爆音、可无缝循环；在 Godot 导入设置中开启 Loop。
- 菜单音乐宜空灵克制；建设音乐宜舒缓、有空间感；战斗音乐提高节奏但避免过度激烈。
- 三首音乐尽量保持相近的整体响度，建议综合响度约 -16 LUFS，峰值不超过 -1 dBFS。
- 不建议把旋律做得太密，因为攻击、命中和资源产出音效会频繁叠加。
- 菜单、建设和战斗音乐会分别记录自己的播放位置；离开阶段后再次返回，会从该音乐上次的断点继续播放。

## 7. 推荐制作顺序

1. 四张地形、虚空和污染覆盖层。
2. 八种神祇静态图。
3. 当前敌人与中央核心。
4. 弹道、命中、污染增长和格子崩塌。
5. 先完成购买、放置、攻击、命中、资源产出五个高频音效。
6. 最后制作动画和其余反馈音效。

先放静态图就能立即替换程序占位；动画可以后补，不要求一次完成整套。

## 8. 当前已放入素材的使用状态

- 已使用：四种地形、虚空、污染覆盖、八种神祇、敌人、核心、预览、弹道、命中、污染增长、格子崩塌。
- 已使用音效：购买、放置、刷新、攻击、命中、资源产出、敌人死亡、污染增长、建设阶段、战斗阶段。
- 已放入并接入：菜单、建设、战斗三首循环背景音乐。
- 已放入并接入：`assets/audio/sfx/sfx_cell_collapse.ogg`。
- 当前不再需要：阶段横幅图片。
- 已使用：`icon_refresh.png`、`icon_lock.png` 和 `card_frame_terrain.png`。
- 已使用：`icon_divine_power.png`、`icon_core_hp.png`、`icon_refresh.png`、`icon_lock.png`。
- 当前暂未使用：`icon_shaping.png`，等级系统已移除，可以删除或保留备用。
- 已使用：`icon_unlock.png`、`icon_time_flow.png`、`icon_start.png`、`icon_help.png`、`icon_attack_deity.png`、`icon_resource_deity.png`。
- 已使用：`shop_slot_empty.png` 替代“已购”文字；商店标题图已从界面移除。
- 已放入四态按钮皮肤；当前仅供文字按钮使用，纯图标按钮不铺按钮底图。
- 卡牌形状由程序方格绘制，当前效果保留，不再需要五张拼图形状图标。
- 当前仍缺少：`map_frame.png`、`game_background.png`。缺失时继续使用程序背景，不影响运行。
- 当前动画目录只有说明文件，尚未制作任何 `SpriteFrames .tres`。
- 优先动画：生命图标、神力图标、八种神祇、虚空/混沌。
- 后续动画：敌人、核心、地图框、动态背景、命中、污染和崩塌。
- 所有上述细分音效目前均缺失，会回退到已有购买、放置、刷新、攻击和资源产出音效。
- 所有纯图标按钮和状态图标均提供鼠标悬停说明。
- 纯图标按钮直接显示图标，并使用程序悬停辉光和按压缩放反馈；文字按钮可使用四态按钮皮肤。
- 卡牌悬停描边沿 `card_frame_terrain.png` 的透明像素轮廓生成，不再绘制矩形外框。
- 商店控制区和已购空位不使用 Godot 默认面板底色，只显示素材本身。
- 游戏背景使用已有四种地形贴图制作低透明拼贴，并在地图区域增加暗色遮罩，减少纯黑空白但不干扰棋盘识别。
- 核心生命与神力状态卡可悬停查看其用途、消耗与失败条件。
- 核心生命与神力已合并到左上同一状态条，并删除状态面板底色。
- 生命与神力图标不再缩放抖动，仅保留较快的亮度脉冲。
- 刷新与锁定按钮使用 54×54 方形布局；神祇安置按钮使用 92×92 方形布局。
- 地形贴图会在地图格上进行 0°/90°/180°/270° 随机旋转，以降低重复感。
- 虚空/混沌地块也会独立随机旋转；被污染摧毁后会重新随机一个朝向。

## 9. 当前查看操作

- F11：切换全屏/窗口模式。
- 地图使用固定放大比例，不再响应鼠标滚轮缩放。
- 地图固定比例提高到约 152%，位置向左上收紧。
- 商店与时间流动按钮统一布置在地图右侧，左侧地图保持较大显示面积。
- 五张卡牌、商店标题、刷新、锁定和时间流动位于同一条右侧操作列；三个主要操作按钮集中在右下。
- 右侧操作列移动到距离地图约 70 像素的位置，卡牌间距约 132 像素，刷新、锁定和时间流动紧接在卡牌下方。
- 右侧操作列整体向下对齐地图顶部，避免标题和首张卡牌贴住画布边缘。
- 地图与右侧商店作为一个整体按 1440×1000 画布居中，避免视觉重心偏向左侧。
- 神祇、地块和商店卡牌信息通过鼠标悬停显示。
- 敌人也支持悬停信息，显示生命、攻击、所在地形、污染和减速状态。
- 地图上不直接绘制污染数字；地块、神祇或敌人的悬停信息会显示当前格污染值。
- 虚空/混沌贴图会降低饱和感；每个有效地形格会缓慢产生少量环境粒子，粒子由程序绘制，不需要额外素材。
- 平原显示横向清风细线，河流显示持续流动的水光，森林显示缓慢摇曳的新芽；山地保持静止，强调厚重感。
