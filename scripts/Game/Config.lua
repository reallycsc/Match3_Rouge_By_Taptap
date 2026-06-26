local G = require "Game.Context"
local _ENV = G

-- 暗黑破坏神风格三消战斗原型
-- 玩法：交换相邻符石形成三消；被消除格周围 1 格内的怪物会受到伤害。
-- 主角和怪物都位于棋盘格内，怪物会在玩家有效行动后逼近并攻击主角。

CONFIG = {
    title = "符石生存者",
    boardSize = 9,
    gemTypes = 5,
    heroMaxHp = 24,
    baseMonsterHp = 4,
    monsterCount = 5,
    monsterMaxCount = 8,
    monsterWaveHpBonus = 1,
    monsterAttackBase = 1,
    monsterAttackPerWave = 3,
    matchDamageRadius = 1,
    scorePerGem = 10,
    killScore = 120,
    killScorePerWave = 20,
    heroHealPerWave = 5,
    maxCascadeCombo = 8,
    swapDuration = 0.16,
    clearDuration = 0.22,
    dropDuration = 0.26,
    laserDamage = 4,
    laserTurns = 3,
    turretDamage = 1,
    turretTurns = 3,
    bombDamage = 5,
    bombRadius = 1,
    bombTurns = 3,
    missileDamage = 2,
    missileSiloTurns = 3,
    missilesPerSiloTurn = 1,
    trapImagePath = "Textures/trap_base.jpg",
    visual3D = {
        cellSize = 1.2,
        floorY = 0.0,
        runeHeight = 0.26,
        cameraPosition = Vector3(0, 18.5, -8.2),
        cameraTarget = Vector3(0, 0, 0),
        lightGroup = "LightGroup/Daytime.xml",
        room = {
            model = "Models/Box.mdl",
            materials = {},
            sourceSize = Vector3(1.0, 1.0, 1.0),
            thickness = 0.08,
        },
        hero = {
            model = "Models/Cylinder.mdl",
            materials = {},
            scale = 0.72,
            yaw = 0,
        },
        monster = {
            model = "Models/Cylinder.mdl",
            materials = {},
            scale = 0.72,
            yaw = 0,
            moveAnimation = "",
            attackAnimation = "",
        },
        itemModels = {
            laser = { model = "Models/Box.mdl" },
            turret = { model = "Models/Cylinder.mdl" },
            missile = { model = "Models/Cone.mdl" },
            bomb = { model = "Models/Sphere.mdl" },
        },
    },
}

BOARD_SIZE = CONFIG.boardSize
GEM_TYPES = CONFIG.gemTypes
MATCH_DAMAGE_RADIUS = CONFIG.matchDamageRadius
SWAP_DURATION = CONFIG.swapDuration
CLEAR_DURATION = CONFIG.clearDuration
DROP_DURATION = CONFIG.dropDuration
MAX_CASCADE_COMBO = CONFIG.maxCascadeCombo

GEM_COLORS = {
    { 208, 38, 54, 255 },
    { 226, 214, 180, 255 },
    { 54, 190, 88, 255 },
    { 70, 176, 230, 255 },
    { 162, 78, 220, 255 },
}
