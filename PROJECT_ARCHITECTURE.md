# 项目架构文档

## 1. 项目概述

本项目是一个暗黑风格的 3D 三消战斗原型，游戏名为“符石生存者”。玩家在 9x9 棋盘中交换符石形成三消，消除结果会对附近怪物造成伤害，并可生成激光、炮台、导弹井、炸弹等道具。怪物会在玩家有效行动后逼近主角并攻击。项目同时包含：

- 3D 地牢棋盘、主角、怪物、符石和道具模型展示
- NanoVG HUD、排行榜、提示文本、血条和特效覆盖层
- 三消判定、连锁掉落、怪物回合、道具触发
- TapTap 云排行榜读写

代码入口位于 `scripts/main.lua`，实际游戏逻辑拆分在 `scripts/Game/` 目录。

## 2. 目录结构

```text
scripts/
├── main.lua                    # UrhoX 事件入口，转发到 Game.Loader 返回的上下文
└── Game/
    ├── Context.lua             # 全局游戏上下文表，模块共享同一 _ENV
    ├── Loader.lua              # 模块加载顺序与上下文导出
    ├── Config.lua              # 游戏数值、棋盘、3D 视觉配置
    ├── State.lua               # 运行时状态变量集中定义
    ├── Utils.lua               # 通用数学、布局、坐标、特效辅助函数
    ├── BoardCombat.lua         # 棋盘、三消、怪物、道具和战斗规则
    ├── Leaderboard.lua         # TapTap 云排行榜与用户数据
    ├── Scene3D.lua             # 3D 场景、模型、棋盘映射和 3D 同步
    ├── AnimationInput.lua      # 输入处理、动画状态机、Update 主循环
    ├── Renderer.lua            # NanoVG HUD、2D 覆盖层和特效绘制
    └── Lifecycle.lua           # Start/Stop 生命周期与事件订阅
```

## 3. 模块职责

### 3.1 `scripts/main.lua`

职责：UrhoX 全局事件转发层。

- 加载 `Game.Loader`
- 将 `Start`、`Stop`、`Update`、鼠标、触摸、键盘、屏幕变化、NanoVG 渲染事件转发给游戏上下文
- 本文件不持有游戏状态，只作为入口适配层

关键位置：`scripts/main.lua:3`

### 3.2 `Game.Context`

职责：共享上下文容器。

- 返回一个 `Context` 表
- 通过 `setmetatable(Context, { __index = _G })` 让模块既能访问共享状态，也能访问引擎全局对象
- 后续模块都使用 `local _ENV = G` 将函数和变量注册到同一上下文中

关键位置：`scripts/Game/Context.lua:1`

### 3.3 `Game.Loader`

职责：按固定顺序加载模块。

加载顺序：

1. `Config`
2. `State`
3. `Utils`
4. `BoardCombat`
5. `Leaderboard`
6. `Scene3D`
7. `AnimationInput`
8. `Renderer`
9. `Lifecycle`

这个顺序保证配置先初始化，状态变量可用，工具函数先于战斗和渲染模块加载，生命周期最后绑定所有函数。

关键位置：`scripts/Game/Loader.lua:1`

### 3.4 `Game.Config`

职责：集中配置游戏数值和 3D 表现参数。

主要内容：

- 棋盘规模：`boardSize = 9`
- 符石类型数：`gemTypes = 5`
- 主角和怪物生命、攻击、波次成长
- 三消、连锁、掉落、交换动画时间
- 道具伤害、持续回合、半径
- 3D 单元格尺寸、相机位置、地板高度、角色/怪物/道具模型配置
- 符石颜色表 `GEM_COLORS`

近期镜头拉远配置位于 `scripts/Game/Config.lua:42`。

### 3.5 `Game.State`

职责：集中定义运行时状态。

主要状态分组：

- NanoVG 状态：`vg_`、`fontId_`、`trapImage_`
- 3D 场景状态：`scene3D_`、`camera3D_`、`boardRoot3D_`、模型节点缓存
- 屏幕布局状态：`physW_`、`physH_`、`dpr_`、`screenW_`、`screenH_`、`boardX_`、`boardY_`、`tile_`
- 棋盘与角色：`board_`、`hero_`、`monsters_`
- 道具与特效：`traps_`、`missileSilos_`、`laserBeams_`、`bombExplosions_`、`cannonShells_`、`missiles_`、`itemTriggerEffects_`
- 游戏流程：`score_`、`moves_`、`wave_`、`gameState_`、`isAnimating_`、`currentAnim_`
- 排行榜：`leaderboard_`

关键位置：`scripts/Game/State.lua:1`

### 3.6 `Game.Utils`

职责：通用辅助函数。

主要功能：

- 数学工具：`Clamp`、`Abs`、`Lerp`、`EaseInOut`、`EaseOutBack`
- 棋盘坐标：`CellKey`、`IsValidCell`、`CellCenter`、`CellTopLeft`
- 布局计算：`RecalcLayout`
- 视觉反馈：`AddFloatText`、`AddParticles`、`AddItemTriggerEffect`
- HUD 消息：`SetMessage`

关键位置：`scripts/Game/Utils.lua:35`、`scripts/Game/Utils.lua:114`

### 3.7 `Game.BoardCombat`

职责：核心玩法规则。

覆盖内容：

- 棋盘生成与补充：`FillNewBoard`、`FillGemAt`、`DropAndRefillBoard`
- 阻挡规则：主角、怪物、陷阱、导弹井所在格不可交换
- 三消检测：横向、纵向、L/T 形、2x2 方块特殊形状
- 特殊道具生成：激光、炮台、导弹井、炸弹
- 道具触发：激光打行/列，炸弹范围伤害，炮台自动攻击，导弹井追踪攻击
- 怪物逻辑：生成、寻路、移动、攻击、死亡、波次推进
- 分数和击杀奖励
- 棋盘可行动提示与无解重排

关键函数：

- `ResetGame`：初始化整局游戏，位置 `scripts/Game/BoardCombat.lua:128`
- `FindMatches`：扫描三消与特殊形状，位置 `scripts/Game/BoardCombat.lua:521`
- `ApplyMatchDamage`：应用消除伤害并生成道具，位置 `scripts/Game/BoardCombat.lua:762`
- `MonsterTurn`：怪物回合主流程，位置 `scripts/Game/BoardCombat.lua:1229`

### 3.8 `Game.Scene3D`

职责：3D 场景创建与同步。

主要功能：

- 创建场景、相机、灯光组、地牢地板与围墙
- 创建 3D 符石网格、主角、怪物、道具节点
- 将棋盘坐标转换为世界坐标：`BoardToWorld`
- 将 3D 点击射线转换回棋盘格：`ScreenToBoardCell3D`
- 根据 `board_`、`hero_`、`monsters_`、`traps_`、`missileSilos_` 同步 3D 节点
- 更新交换、消除、掉落、怪物移动等 3D 动画表现
- 为主角和怪物创建 3D 血量显示组件

关键函数：

- `CreateScene3D`：创建 3D 根场景，位置 `scripts/Game/Scene3D.lua:50`
- `BoardToWorld`：棋盘格转世界坐标，位置 `scripts/Game/Scene3D.lua:39`
- `UpdateScene3D`：每帧同步 3D 表现，位置 `scripts/Game/Scene3D.lua:555`
- `ScreenToBoardCell3D`：3D 射线拾取棋盘格，位置 `scripts/Game/Scene3D.lua:569`

### 3.9 `Game.AnimationInput`

职责：输入、动画推进和每帧主循环。

主要功能：

- 交换动画：`StartSwapAnimation`、`StartSwapBackAnimation`
- 清除动画：`StartClearAnimation`
- 掉落动画：`StartDropAnimation`、`StartEnemyDropAnimation`
- 动画完成后的状态切换：从交换到消除，从消除到掉落，从掉落到怪物回合
- 鼠标、触摸、键盘输入处理
- 每帧更新特效生命周期
- 每帧调用自动瞄准、动画、3D 场景同步

关键函数：

- `HandleUpdate`：主 Update 循环，位置 `scripts/Game/AnimationInput.lua:330`
- `UpdateAnimation`：动画状态机，位置 `scripts/Game/AnimationInput.lua:107`
- `TrySwap`：玩家交换尝试，位置 `scripts/Game/AnimationInput.lua:151`
- `ScreenToCell`：输入坐标转棋盘格，位置 `scripts/Game/AnimationInput.lua:177`

### 3.10 `Game.Renderer`

职责：NanoVG 2D 覆盖层绘制。

主要绘制内容：

- 棋盘备用 2D 表现：符石、怪物、主角、选中框、提示格
- 道具图标、道具说明面板
- 激光、炸弹、炮弹、导弹、粒子、浮字等特效
- 顶部 HUD：标题、主角生命、波次、分数、步数
- 底部 Tips 半透明底板
- 右侧排行榜面板
- 怪物头顶 UI 血条
- Game Over 面板

当前项目实际以 3D 场景为主，NanoVG 主要作为 HUD 和特效覆盖层。

关键函数：

- `HandleNanoVGRender`：NanoVG 绘制入口，位置 `scripts/Game/Renderer.lua:1016`
- `DrawHud`：顶部/底部 HUD，位置 `scripts/Game/Renderer.lua:959`
- `DrawMonsterHealthBars`：怪物头顶 UI 血条，位置 `scripts/Game/Renderer.lua:898`
- `DrawItemTriggerEffects`：道具触发特效，位置 `scripts/Game/Renderer.lua:906`

### 3.11 `Game.Leaderboard`

职责：TapTap 云排行榜。

主要功能：

- 检查云服务是否可用
- 获取当前用户昵称
- 提交最高分和游玩次数
- 获取玩家自身排名
- 获取排行榜前 10 名
- 控制排行榜面板显示/隐藏

关键函数：

- `InitTapTapServices`：初始化云服务，位置 `scripts/Game/Leaderboard.lua:11`
- `SubmitScoreToLeaderboard`：结算提交分数，位置 `scripts/Game/Leaderboard.lua:45`
- `RefreshLeaderboard`：刷新排行榜，位置 `scripts/Game/Leaderboard.lua:96`

### 3.12 `Game.Lifecycle`

职责：生命周期和事件订阅。

`Start` 中执行：

1. 设置窗口标题和鼠标模式
2. 计算布局
3. 创建 3D 场景
4. 创建 NanoVG 上下文和字体
5. 加载道具贴图
6. 重置游戏
7. 同步 3D 场景
8. 初始化 TapTap 服务
9. 订阅 Update、输入、屏幕变化、NanoVGRender 等事件

`Stop` 中释放 NanoVG 和 3D 场景对象。

关键位置：`scripts/Game/Lifecycle.lua:4`

## 4. 模块依赖关系

```text
main.lua
  └── Game.Loader
        ├── Game.Context
        ├── Game.Config
        ├── Game.State
        ├── Game.Utils
        ├── Game.BoardCombat
        ├── Game.Leaderboard
        ├── Game.Scene3D
        ├── Game.AnimationInput
        ├── Game.Renderer
        └── Game.Lifecycle
```

所有 `Game/*` 模块通过同一个 `Context` 表共享函数和状态，形成“模块化文件 + 共享游戏上下文”的结构。模块之间不是通过显式 return API 互相调用，而是通过 `_ENV = G` 将函数放入共享环境。

典型跨模块调用：

- `AnimationInput.TrySwap` 调用 `BoardCombat.FindMatches`、`BoardCombat.DropAndRefillBoard`
- `BoardCombat.ApplyMatchDamage` 调用 `Utils.AddParticles`、`Utils.AddFloatText`、`Scene3D` 中注册的动画回调
- `AnimationInput.HandleUpdate` 调用 `BoardCombat.UpdateAutoAimTargets`、`Scene3D.UpdateScene3D`
- `Renderer.HandleNanoVGRender` 读取 `State` 中的棋盘、怪物、特效、排行榜状态进行绘制
- `Lifecycle.Start` 串联初始化所有模块

## 5. 核心数据流

### 5.1 启动流程

```text
Start
  ├── RecalcLayout
  ├── CreateScene3D
  ├── nvgCreate / 字体加载 / 贴图加载
  ├── ResetGame
  │   ├── FillNewBoard
  │   ├── SpawnMonsters
  │   ├── EnsureBoardHasMove
  │   └── SyncScene3D
  ├── InitTapTapServices
  └── SubscribeToEvent
```

### 5.2 玩家交换流程

```text
鼠标/触摸输入
  └── ScreenToCell
        ├── 优先使用 3D 射线拾取 ScreenToBoardCell3D
        └── 失败时使用 2D HUD 棋盘坐标兜底
  └── TrySwap
        ├── 检查格子是否相邻、是否被角色/怪物/道具占据
        ├── SwapCells
        └── StartSwapAnimation
```

### 5.3 三消与连锁流程

```text
UpdateAnimation(swap 完成)
  ├── FindMatches
  ├── 有匹配：StartClearAnimation
  └── 无匹配：StartSwapBackAnimation

UpdateAnimation(clear 完成)
  ├── ApplyMatchDamage
  │   ├── SpawnSpecialTraps
  │   ├── 对范围内怪物扣血
  │   ├── 添加粒子/浮字/匹配特效
  │   └── RemoveDeadMonsters
  ├── 清空匹配格
  └── DropAndRefillBoard → StartDropAnimation

UpdateAnimation(drop 完成)
  ├── 若还有匹配且未超连锁上限：继续 StartClearAnimation
  └── 否则 FinishPlayerMove → MonsterTurn
```

### 5.4 怪物回合流程

```text
MonsterTurn
  ├── turnId_ + 1
  ├── FireMissileSilos
  ├── FireTurrets
  ├── CheckTriggeredTraps
  ├── 每个怪物：
  │   ├── 若邻近主角则计入攻击者
  │   └── 否则寻路移动 TryMoveMonster
  ├── 攻击主角 DamageHero
  └── EnsureBoardStable / EnsureBoardHasMove
```

### 5.5 每帧更新流程

```text
HandleUpdate
  ├── time_ += timeStep
  ├── UpdateAutoAimTargets
  ├── UpdateEffects
  ├── UpdateAnimation
  └── UpdateScene3D
```

### 5.6 渲染流程

```text
3D Viewport
  └── Scene3D 中的相机渲染地牢、符石、主角、怪物、道具

NanoVGRender
  ├── DrawItemTriggerEffects
  ├── DrawEffects
  ├── DrawMonsterHealthBars
  ├── DrawHud
  └── DrawGameOver
```

## 6. 核心状态说明

| 状态 | 类型/结构 | 作用 |
|------|-----------|------|
| `board_` | 2D table | 9x9 棋盘符石类型，0 表示空或被角色/道具占据 |
| `hero_` | table | 主角格子坐标、生命值 |
| `monsters_` | array | 怪物列表，包含格子坐标、生命、攻击、动画闪烁 |
| `traps_` | array | 激光、炮台、炸弹等陷阱道具 |
| `missileSilos_` | array | 导弹井道具，独立于 `traps_` 管理 |
| `currentAnim_` | table/nil | 当前棋盘动画，`kind` 可为 `swap`、`clear`、`drop`、`enemyDrop` |
| `isAnimating_` | boolean | 是否正在播放棋盘动画，阻止输入打断 |
| `laserBeams_` / `bombExplosions_` / `cannonShells_` / `missiles_` | array | 各类战斗视觉特效 |
| `itemTriggerEffects_` | array | 道具触发时的通用 UI 动画特效 |
| `leaderboard_` | table | 排行榜可见性、状态、条目、玩家排名 |
| `monsterNodes3D_` | array | 怪物 3D 节点缓存，与 `monsters_` 按索引对应 |
| `itemNodes3D_` | array | 道具 3D 节点缓存，由道具签名变化触发重建 |

## 7. 坐标系统

项目同时维护棋盘坐标、3D 世界坐标、屏幕逻辑坐标。

### 7.1 棋盘坐标

- `row`、`col` 从 1 开始
- 棋盘大小由 `BOARD_SIZE` 决定，当前为 9
- `board_[row][col]` 保存符石类型

### 7.2 3D 世界坐标

`BoardToWorld(row, col)` 将棋盘坐标映射到 3D 地牢平面：

- X 轴随列变化
- Z 轴随行变化
- Y 使用 `CONFIG.visual3D.floorY`

### 7.3 屏幕坐标

- `RecalcLayout` 根据物理分辨率和 DPR 计算逻辑分辨率
- NanoVG 使用逻辑分辨率绘制
- 输入坐标先除以 `dpr_`，或通过 3D 相机射线换算成棋盘格

## 8. 道具系统

### 8.1 生成规则

- 直线 4 消：生成横向/纵向激光
- 直线 5 消：生成导弹井
- 大于 5 连：同时生成激光和导弹井
- L/T 形 5 消：生成炸弹
- 2x2 方块 4 消：生成炮台

### 8.2 道具表现

| 道具 | 数据容器 | 触发方式 | 主要效果 |
|------|----------|----------|----------|
| 激光 | `traps_` | 怪物进入同行/同列 | 对目标造成激光伤害，绘制光束 |
| 炮台 | `traps_` | 每个怪物回合自动开火 | 瞄准最近怪物，发射炮弹 |
| 炸弹 | `traps_` | 怪物进入范围 | 范围爆炸伤害 |
| 导弹井 | `missileSilos_` | 每个怪物回合自动发射 | 追踪目标，发射导弹 |

通用触发动画由 `AddItemTriggerEffect` 写入 `itemTriggerEffects_`，再由 `DrawItemTriggerEffects` 绘制。

## 9. 渲染架构

项目采用“3D 主场景 + NanoVG 覆盖层”的渲染结构。

### 9.1 3D 主场景

负责：

- 地牢地板和墙体
- 3D 符石方块
- 主角圆柱体
- 怪物圆柱体
- 道具模型
- 3D 节点动画

### 9.2 NanoVG 覆盖层

负责：

- HUD 文本和面板
- 主角顶部生命条
- 底部 Tips 面板
- 右侧排行榜
- 怪物头顶 UI 血条
- 浮字、粒子、道具触发线条动画
- Game Over 遮罩

这种结构让核心棋盘有 3D 空间感，同时让 UI 保持清晰可读。

## 10. 扩展建议

### 10.1 新增道具

建议修改位置：

1. 在 `Config.lua` 添加数值配置
2. 在 `BoardCombat.lua` 的特殊匹配检测中添加生成规则
3. 在 `AddTrap` 或新增容器中维护道具状态
4. 在 `Scene3D.lua` 添加 3D 模型表现
5. 在 `Renderer.lua` 添加 HUD/触发特效表现
6. 在 `UpdateEffects` 中维护生命周期

### 10.2 新增怪物类型

建议修改位置：

1. 在 `SpawnMonsters` 中为怪物增加 `kind` 字段
2. 在 `MonsterTurn` 或 `TryMoveMonster` 中按 `kind` 分发 AI
3. 在 `Scene3D.EnsureMonsterNodes3D` 中按类型选择模型/材质
4. 在 `Renderer.DrawMonsterHealthBar` 或特效层增加差异化表现

### 10.3 调整视觉布局

建议优先修改：

- 3D 镜头：`Config.lua` 的 `visual3D.cameraPosition` 和 `cameraTarget`
- 棋盘大小：`Config.lua` 的 `visual3D.cellSize`
- HUD 面板：`Renderer.lua` 的 `DrawHud`
- 屏幕适配：`Utils.lua` 的 `RecalcLayout`

### 10.4 拆分建议

当前 `BoardCombat.lua` 和 `Renderer.lua` 体量较大。若继续扩展，可考虑拆分为：

```text
Game/Board/
├── BoardState.lua
├── MatchFinder.lua
├── DropRefill.lua
└── HintSolver.lua

Game/Combat/
├── MonsterAI.lua
├── Damage.lua
└── Items.lua

Game/Render/
├── HudRenderer.lua
├── BoardOverlayRenderer.lua
├── EffectRenderer.lua
└── LeaderboardRenderer.lua
```

这样可以降低单文件复杂度，方便后续多人协作和功能迭代。
