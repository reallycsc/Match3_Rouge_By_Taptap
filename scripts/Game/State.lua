local G = require "Game.Context"
local _ENV = G

---@type Object
vg_ = nil
fontId_ = -1
trapImage_ = -1

---@type Scene
scene3D_ = nil
---@type Node
cameraNode3D_ = nil
---@type Camera
camera3D_ = nil
cameraZoom3D_ = 1.0
cameraZoomTarget3D_ = 1.0
meowClearSound_ = nil
meowSoundSource_ = nil
---@type Node
boardRoot3D_ = nil
---@type Node
roomNode3D_ = nil
---@type Node
sceneLightNode3D_ = nil
---@type Node
heroNode3D_ = nil
---@type Node
heroArrowNode3D_ = nil
---@type StaticModel|AnimatedModel
heroModel3D_ = nil
heroAnimController3D_ = nil
heroCurrentAnim3D_ = nil
---@type Material
selectionMaterial3D_ = nil
---@type Material
heroMarkerMaterial3D_ = nil
runeNodes3D_ = {}
runeModels3D_ = {}
runeIconNodes3D_ = {}
monsterNodes3D_ = {}
itemNodes3D_ = {}
bombWarningNodes3D_ = {}
itemSignature3D_ = nil
cellMarkers3D_ = {}
materials3D_ = {}

physW_ = 1280
physH_ = 720
dpr_ = 1.0
screenW_ = 1280
screenH_ = 720
boardX_ = 0
boardY_ = 0
boardPixels_ = 560
tile_ = 64
gap_ = 6

board_ = {}
HasMonsterAt = nil
selected_ = nil
lastTapCell_ = nil
hero_ = { row = 5, col = 5, hp = CONFIG.heroMaxHp, maxHp = CONFIG.heroMaxHp, hpBuffer = CONFIG.heroMaxHp }
monsters_ = {}
traps_ = {}
floatTexts_ = {}
particles_ = {}
hudDamageParticles_ = {}
matchEffects_ = {}
laserBeams_ = {}
bombExplosions_ = {}
cannonShells_ = {}
missileSilos_ = {}
missileLaunches_ = {}
missiles_ = {}
itemTriggerEffects_ = {}
monsterMoves_ = {}
monsterDeathBursts3D_ = {}
time_ = 0
score_ = 0
moves_ = 0
wave_ = 1
gameState_ = "playing"
message_ = "交换相邻符石；三消会伤害消除格周围 1 格的怪物"
messageTimer_ = 4.0
screenShake_ = 0
isAnimating_ = false
currentAnim_ = nil
pendingMove_ = false
pendingMonsterTurn_ = false
waitingMonsterTurnBanner_ = false
pendingItemBoardRefill_ = false
lastSwapDropDir_ = { row = 1, col = 0 }
pendingHeroDrop_ = nil
dropHeroMoved_ = false
isItemTurnResolving_ = false
dragStart_ = nil
dragTriggered_ = false
restartCount_ = 0
hintCells_ = {}
hintScore_ = 0
shuffleCount_ = 0
turnId_ = 0
pendingRogueReward_ = false
playerTurnActive_ = false
playerTurnTimer_ = 0
playerTurnManualClearCount_ = 0
pendingPlayerTurnTimerAfterRender_ = false
startGamePromptVisible_ = false
startGameButtonRect_ = nil
activeRuneDrops_ = {}
currentTurnText_ = "玩家回合"
currentTurnKind_ = "player"
turnBanner_ = nil
turnBannerQueue_ = {}
roguelike_ = nil

leaderboard_ = {
    userId = nil,
    nickname = "未登录",
    status = "正在连接 TapTap...",
    entries = {},
    myRank = nil,
    myBest = 0,
    visible = false,
    loading = false,
}

leaderboardButtonRect_ = nil
actionLogButtonRect_ = nil
configButtonRect_ = nil
testUnlockButtonRect_ = nil
leaderboardPopupRect_ = nil
leaderboardCloseRect_ = nil
uiPressConsumed_ = false

operationLog_ = {}
operationLogVisible_ = false
operationLogAnim_ = 0
operationLogRect_ = nil
operationLogOffset_ = 0
operationLogDisplayRowCount_ = 0
operationLogDragging_ = false
operationLogDragLastY_ = 0

numberConfig_ = {
    visible = false,
    draft = {},
    fields = {},
    rects = {},
    confirmRect = nil,
    closeRect = nil,
}
