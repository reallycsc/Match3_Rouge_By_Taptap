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
---@type Node
boardRoot3D_ = nil
---@type Node
roomNode3D_ = nil
---@type Node
heroNode3D_ = nil
---@type StaticModel
heroModel3D_ = nil
---@type Material
selectionMaterial3D_ = nil
---@type Material
heroMarkerMaterial3D_ = nil
heroHealthDisplay3D_ = nil
runeNodes3D_ = {}
runeModels3D_ = {}
runeIconNodes3D_ = {}
monsterNodes3D_ = {}
itemNodes3D_ = {}
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
hero_ = { row = 5, col = 5, hp = CONFIG.heroMaxHp, maxHp = CONFIG.heroMaxHp }
monsters_ = {}
traps_ = {}
floatTexts_ = {}
particles_ = {}
matchEffects_ = {}
laserBeams_ = {}
bombExplosions_ = {}
cannonShells_ = {}
missileSilos_ = {}
missileLaunches_ = {}
missiles_ = {}
itemTriggerEffects_ = {}
monsterMoves_ = {}
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
dragStart_ = nil
dragTriggered_ = false
restartCount_ = 0
hintCells_ = {}
hintScore_ = 0
shuffleCount_ = 0
turnId_ = 0

leaderboard_ = {
    userId = nil,
    nickname = "未登录",
    status = "正在连接 TapTap...",
    entries = {},
    myRank = nil,
    myBest = 0,
    visible = true,
    loading = false,
}
