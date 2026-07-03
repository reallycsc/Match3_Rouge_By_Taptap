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
    monsterCountIncreasePerWave = 0.75,
    monsterMaxCount = 8,
    monsterWaveHpBonus = 1,
    monsterAttackBase = 1,
    maxMonsterAttackersPerTurn = 3,
    monsterAttackPerWave = 3,
    matchDamageRadius = 1,
    scorePerGem = 10,
    killScore = 120,
    killScorePerWave = 20,
    heroHealPerWave = 5,
    maxCascadeCombo = 8,
    playerTurnDuration = 2.0,
    swapDuration = 0.16,
    clearDuration = 0.22,
    dropDuration = 0.26,
    laserDamage = 3,
    turretDamage = 1,
    turretTurns = 3,
    bombDamage = 3,
    bombRadius = 1,
    missileDamage = 2,
    missileSiloTurns = 3,
    missilesPerSiloTurn = 1,
    trapImagePath = "",
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
            model = "Meshes/character-male-d.mdl",
            materials = { "Materials/character-male-d_00_colormap.xml" },
            scale = 1.65,
            yaw = 0,
            animations = {
                static = "Animations/character-male-d/static.ani",
                idle = "Animations/character-male-d/idle.ani",
                walk = "Animations/character-male-d/walk.ani",
                sprint = "Animations/character-male-d/sprint.ani",
                jump = "Animations/character-male-d/jump.ani",
                fall = "Animations/character-male-d/fall.ani",
                crouch = "Animations/character-male-d/crouch.ani",
                sit = "Animations/character-male-d/sit.ani",
                drive = "Animations/character-male-d/drive.ani",
                die = "Animations/character-male-d/die.ani",
                pickUp = "Animations/character-male-d/pick-up.ani",
                emoteYes = "Animations/character-male-d/emote-yes.ani",
                emoteNo = "Animations/character-male-d/emote-no.ani",
                holdingRight = "Animations/character-male-d/holding-right.ani",
                holdingLeft = "Animations/character-male-d/holding-left.ani",
                holdingBoth = "Animations/character-male-d/holding-both.ani",
                holdingRightShoot = "Animations/character-male-d/holding-right-shoot.ani",
                holdingLeftShoot = "Animations/character-male-d/holding-left-shoot.ani",
                holdingBothShoot = "Animations/character-male-d/holding-both-shoot.ani",
                attack = "Animations/character-male-d/attack-melee-right.ani",
                attackMeleeRight = "Animations/character-male-d/attack-melee-right.ani",
                attackMeleeLeft = "Animations/character-male-d/attack-melee-left.ani",
                attackKickRight = "Animations/character-male-d/attack-kick-right.ani",
                attackKickLeft = "Animations/character-male-d/attack-kick-left.ani",
                interactRight = "Animations/character-male-d/interact-right.ani",
                interactLeft = "Animations/character-male-d/interact-left.ani",
                wheelchairSit = "Animations/character-male-d/wheelchair-sit.ani",
                wheelchairLookLeft = "Animations/character-male-d/wheelchair-look-left.ani",
                wheelchairLookRight = "Animations/character-male-d/wheelchair-look-right.ani",
                wheelchairMoveForward = "Animations/character-male-d/wheelchair-move-forward.ani",
                wheelchairMoveBack = "Animations/character-male-d/wheelchair-move-back.ani",
                wheelchairMoveLeft = "Animations/character-male-d/wheelchair-move-left.ani",
                wheelchairMoveRight = "Animations/character-male-d/wheelchair-move-right.ani",
            },
        },
        monster = {
            model = "Meshes/character-orc.mdl",
            materials = { "Materials/character-orc_00_colormap.xml" },
            scale = 1.65,
            yaw = 0,
            animations = {
                static = "Animations/character-orc/static.ani",
                idle = "Animations/character-orc/idle.ani",
                walk = "Animations/character-orc/walk.ani",
                sprint = "Animations/character-orc/sprint.ani",
                jump = "Animations/character-orc/jump.ani",
                fall = "Animations/character-orc/fall.ani",
                crouch = "Animations/character-orc/crouch.ani",
                sit = "Animations/character-orc/sit.ani",
                drive = "Animations/character-orc/drive.ani",
                die = "Animations/character-orc/die.ani",
                pickUp = "Animations/character-orc/pick-up.ani",
                emoteYes = "Animations/character-orc/emote-yes.ani",
                emoteNo = "Animations/character-orc/emote-no.ani",
                holdingRight = "Animations/character-orc/holding-right.ani",
                holdingLeft = "Animations/character-orc/holding-left.ani",
                holdingBoth = "Animations/character-orc/holding-both.ani",
                holdingRightShoot = "Animations/character-orc/holding-right-shoot.ani",
                holdingLeftShoot = "Animations/character-orc/holding-left-shoot.ani",
                holdingBothShoot = "Animations/character-orc/holding-both-shoot.ani",
                attack = "Animations/character-orc/attack-melee-right.ani",
                attackMeleeRight = "Animations/character-orc/attack-melee-right.ani",
                attackMeleeLeft = "Animations/character-orc/attack-melee-left.ani",
                attackKickRight = "Animations/character-orc/attack-kick-right.ani",
                attackKickLeft = "Animations/character-orc/attack-kick-left.ani",
                interactRight = "Animations/character-orc/interact-right.ani",
                interactLeft = "Animations/character-orc/interact-left.ani",
                wheelchairSit = "Animations/character-orc/wheelchair-sit.ani",
                wheelchairLookLeft = "Animations/character-orc/wheelchair-look-left.ani",
                wheelchairLookRight = "Animations/character-orc/wheelchair-look-right.ani",
                wheelchairMoveForward = "Animations/character-orc/wheelchair-move-forward.ani",
                wheelchairMoveBack = "Animations/character-orc/wheelchair-move-back.ani",
                wheelchairMoveLeft = "Animations/character-orc/wheelchair-move-left.ani",
                wheelchairMoveRight = "Animations/character-orc/wheelchair-move-right.ani",
            },
            moveAnimation = "Animations/character-orc/walk.ani",
            attackAnimation = "Animations/character-orc/attack-melee-right.ani",
        },
        itemModels = {
            laser = { model = "Models/Box.mdl" },
            turret = { model = "Models/Cylinder.mdl" },
            missile = { model = "Models/Cone.mdl" },
            bomb = { model = "Models/Sphere.mdl" },
        },
    },
}

function LoadSavedNumberConfig()
    if fileSystem == nil or not fileSystem:FileExists("number_config.json") then return end
    local file = File("number_config.json", FILE_READ)
    if file == nil or not file:IsOpen() then return end
    local content = file:ReadString()
    file:Close()
    local ok, data = pcall(cjson.decode, content)
    if not ok or type(data) ~= "table" then
        print("Failed to load number_config.json")
        return
    end
    for key, value in pairs(data) do
        if CONFIG[key] ~= nil and type(CONFIG[key]) == "number" and type(value) == "number" then
            CONFIG[key] = value
        end
    end
    print("Loaded number_config.json")
end

LoadSavedNumberConfig()

function ApplyConfigGlobals()
    BOARD_SIZE = CONFIG.boardSize
    GEM_TYPES = CONFIG.gemTypes
    MATCH_DAMAGE_RADIUS = CONFIG.matchDamageRadius
    SWAP_DURATION = CONFIG.swapDuration
    CLEAR_DURATION = CONFIG.clearDuration
    DROP_DURATION = CONFIG.dropDuration
    MAX_CASCADE_COMBO = CONFIG.maxCascadeCombo
end

ApplyConfigGlobals()

GEM_COLORS = {
    { 208, 38, 54, 255 },
    { 226, 214, 180, 255 },
    { 54, 190, 88, 255 },
    { 70, 176, 230, 255 },
    { 162, 78, 220, 255 },
}
