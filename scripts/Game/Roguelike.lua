local G = require "Game.Context"
local _ENV = G
---@diagnostic disable: undefined-global

ROGUE_OPTION_POOL = {
    {
        id = "relic_laser_core",
        type = "relic",
        relicId = "laser_core",
        title = "遗物：裂隙激光核",
        subtitle = "解锁激光",
        description = "横向或纵向 4 消可生成持久激光，再次点击或交换后向两侧发射。",
        rarity = "遗物",
    },
    {
        id = "relic_turret_contract",
        type = "relic",
        relicId = "turret_contract",
        title = "遗物：黄铜炮台契约",
        subtitle = "解锁炮台",
        description = "2x2 方块 4 消可部署炮台，每回合自动攻击最近怪物。",
        rarity = "遗物",
    },
    {
        id = "relic_missile_manual",
        type = "relic",
        relicId = "missile_manual",
        title = "遗物：导弹井图纸",
        subtitle = "解锁导弹井",
        description = "直线 5 消可部署导弹井，持续发射追踪导弹。",
        rarity = "遗物",
    },
    {
        id = "relic_bomb_sigil",
        type = "relic",
        relicId = "bomb_sigil",
        title = "遗物：爆裂符印",
        subtitle = "解锁炸弹",
        description = "L/T 形 5 消可部署持久炸弹，再次点击或交换后爆破 3x3 范围。",
        rarity = "遗物",
    },
    {
        id = "relic_gravity_compass",
        type = "relic",
        relicId = "gravity_compass",
        title = "遗物：重力罗盘",
        subtitle = "解锁方向坠落",
        description = "符石按本次交换方向坠落，主角也会随坠落方向移动。",
        rarity = "遗物",
    },
    {
        id = "buff_max_hp",
        type = "buff",
        buffKey = "maxHpBonus",
        amount = 4,
        title = "祝福：坚韧血脉",
        subtitle = "最大生命 +4",
        description = "立即提升最大生命并治疗 4 点生命。",
        rarity = "BUFF",
    },
    {
        id = "buff_match_damage",
        type = "buff",
        buffKey = "matchDamageBonus",
        amount = 1,
        title = "祝福：碎石回响",
        subtitle = "消除伤害 +1",
        description = "每次三消波及怪物时，额外造成 1 点伤害。",
        rarity = "BUFF",
    },
    {
        id = "buff_item_damage",
        type = "buff",
        buffKey = "itemDamageBonus",
        amount = 1,
        title = "祝福：工匠火药",
        subtitle = "道具伤害 +1",
        description = "激光、炮台、导弹和炸弹的伤害提高 1 点。",
        rarity = "BUFF",
    },
    {
        id = "buff_wave_heal",
        type = "buff",
        buffKey = "waveHealBonus",
        amount = 2,
        title = "祝福：战后喘息",
        subtitle = "每波治疗 +2",
        description = "选择奖励进入下一波时，额外恢复 2 点生命。",
        rarity = "BUFF",
    },
    {
        id = "item_heal_potion",
        type = "item",
        itemId = "heal_potion",
        title = "消耗品：生命药剂",
        subtitle = "立即治疗 8 点",
        description = "立刻恢复 8 点生命，不超过最大生命。",
        rarity = "道具",
    },
    {
        id = "item_battle_repair",
        type = "item",
        itemId = "battle_repair",
        title = "消耗品：战场整备",
        subtitle = "修复棋盘",
        description = "清除当前残留道具和空位，并重排棋盘。",
        rarity = "道具",
    },
}

local RELIC_LABELS = {
    laser_core = "裂隙激光核",
    turret_contract = "黄铜炮台契约",
    missile_manual = "导弹井图纸",
    bomb_sigil = "爆裂符印",
    gravity_compass = "重力罗盘",
}

local SPECIAL_RELICS = {
    laserH = "laser_core",
    laserV = "laser_core",
    turret = "turret_contract",
    missileSilo = "missile_manual",
    bomb = "bomb_sigil",
}

function UnlockAllTestRelics()
    EnsureRoguelikeState()
    local relicIds = {
        "laser_core",
        "turret_contract",
        "missile_manual",
        "bomb_sigil",
        "gravity_compass",
    }
    for _, relicId in ipairs(relicIds) do
        if not roguelike_.relics[relicId] then
            roguelike_.relics[relicId] = true
            table.insert(roguelike_.relicOrder, relicId)
        end
    end
    SetMessage("测试：已解锁所有道具遗物", 2.2)
    AddOperationLog("测试按钮：解锁激光、炮台、导弹井、炸弹和重力罗盘")
    print("Test unlock all relics")
end

function ResetRoguelikeState()
    roguelike_ = {
        relics = {},
        relicOrder = {},
        buffs = {
            maxHpBonus = 0,
            matchDamageBonus = 0,
            itemDamageBonus = 0,
            waveHealBonus = 0,
        },
        rewardOptions = {},
        rewardVisible = false,
        rewardWave = 0,
        rewardOptionRects = {},
        rewardPanelRect = nil,
        pickCount = 0,
    }
end

function EnsureRoguelikeState()
    if roguelike_ == nil then
        ResetRoguelikeState()
    end
end

function HasRelic(relicId)
    EnsureRoguelikeState()
    return roguelike_.relics[relicId] == true
end

function GetRelicLabel(relicId)
    return RELIC_LABELS[relicId] or tostring(relicId or "未知遗物")
end

function GetRogueBuff(key)
    EnsureRoguelikeState()
    return roguelike_.buffs[key] or 0
end

function GetRogueItemDamage(baseDamage)
    return (baseDamage or 0) + GetRogueBuff("itemDamageBonus")
end

function IsSpecialUnlocked(kind)
    local relicId = SPECIAL_RELICS[kind]
    if relicId == nil then return true end
    return HasRelic(relicId)
end

function IsDirectionalDropUnlocked()
    return HasRelic("gravity_compass")
end

function GetSpecialLockedMessage(kind)
    local relicId = SPECIAL_RELICS[kind]
    if relicId == nil then return nil end
    return "需要遗物「" .. GetRelicLabel(relicId) .. "」"
end

function IsRogueOptionAvailable(option)
    if option == nil then return false end
    if option.type == "relic" then
        return not HasRelic(option.relicId)
    end
    return true
end

function ShuffleRogueOptions(options)
    for i = #options, 2, -1 do
        local j = math.random(1, i)
        options[i], options[j] = options[j], options[i]
    end
end

function BuildRogueRewardOptions()
    EnsureRoguelikeState()
    local candidates = {}
    for _, option in ipairs(ROGUE_OPTION_POOL) do
        if IsRogueOptionAvailable(option) then
            table.insert(candidates, option)
        end
    end
    ShuffleRogueOptions(candidates)

    local result = {}
    for i = 1, math.min(3, #candidates) do
        table.insert(result, candidates[i])
    end
    return result
end

function BeginRogueReward()
    EnsureRoguelikeState()
    roguelike_.rewardOptions = BuildRogueRewardOptions()
    roguelike_.rewardVisible = #roguelike_.rewardOptions > 0
    roguelike_.rewardWave = wave_
    roguelike_.rewardOptionRects = {}
    roguelike_.rewardPanelRect = nil

    if roguelike_.rewardVisible then
        gameState_ = "reward"
        SetMessage("第 " .. tostring(wave_) .. " 波结束：选择一个奖励", 99)
        AddOperationLog("波次奖励：第 " .. tostring(wave_) .. " 波结束，等待选择奖励")
        print("Rogue reward opened: wave=" .. tostring(wave_) .. ", options=" .. tostring(#roguelike_.rewardOptions))
    else
        StartNextWaveAfterReward()
    end
end

function ApplyRogueBuff(option)
    local key = option.buffKey
    local amount = option.amount or 0
    roguelike_.buffs[key] = (roguelike_.buffs[key] or 0) + amount
    if key == "maxHpBonus" then
        hero_.maxHp = hero_.maxHp + amount
        hero_.hp = Clamp(hero_.hp + amount, 0, hero_.maxHp)
        hero_.hpBuffer = hero_.hp
    end
end

function ApplyRogueItem(option)
    if option.itemId == "heal_potion" then
        hero_.hp = Clamp(hero_.hp + 8, 0, hero_.maxHp)
        hero_.hpBuffer = hero_.hp
    elseif option.itemId == "battle_repair" then
        traps_ = {}
        missileSilos_ = {}
        FillNewBoard()
        ClearActorCells()
        EnsureBoardHasMove()
        SyncScene3D()
    end
end

function ApplyRogueRewardOption(index)
    EnsureRoguelikeState()
    if not roguelike_.rewardVisible then return false end
    local option = roguelike_.rewardOptions[index]
    if option == nil then return false end

    if option.type == "relic" then
        roguelike_.relics[option.relicId] = true
        table.insert(roguelike_.relicOrder, option.relicId)
    elseif option.type == "buff" then
        ApplyRogueBuff(option)
    elseif option.type == "item" then
        ApplyRogueItem(option)
    end

    roguelike_.pickCount = (roguelike_.pickCount or 0) + 1
    AddOperationLog("选择奖励：" .. option.title .. " - " .. option.subtitle)
    SetMessage("获得「" .. option.title .. "」。新的恶魔潮涌入棋盘", 2.5)
    print("Rogue option picked: " .. tostring(option.id))

    roguelike_.rewardVisible = false
    roguelike_.rewardOptions = {}
    roguelike_.rewardOptionRects = {}
    roguelike_.rewardPanelRect = nil
    StartNextWaveAfterReward()
    return true
end

function StartNextWaveAfterReward()
    gameState_ = "playing"
    wave_ = wave_ + 1
    local heal = CONFIG.heroHealPerWave + GetRogueBuff("waveHealBonus")
    hero_.hpBuffer = Clamp(hero_.hp + heal, 0, hero_.maxHp)
    hero_.hp = hero_.hpBuffer
    SpawnMonsters()
    SetMessage("新的恶魔潮涌入棋盘。主角恢复 " .. tostring(heal) .. " 点生命", 2.5)
    AddOperationLog("进入第 " .. tostring(wave_) .. " 波，恢复 " .. tostring(heal) .. " 点生命")
    ShowTurnBanner("玩家回合", "player")
    print("Next wave after reward: " .. tostring(wave_) .. ", monsters=" .. tostring(#monsters_))
end

function GetRogueRewardOptionAt(x, y)
    EnsureRoguelikeState()
    if not roguelike_.rewardVisible then return nil end
    for index, rect in ipairs(roguelike_.rewardOptionRects or {}) do
        if PointInRect(x, y, rect) then
            return index
        end
    end
    return nil
end

function HandleRogueRewardPress(x, y)
    local index = GetRogueRewardOptionAt(x, y)
    if index == nil then
        return roguelike_ ~= nil and roguelike_.rewardVisible == true
    end
    ApplyRogueRewardOption(index)
    return true
end

function GetRelicSummaryText()
    EnsureRoguelikeState()
    if #roguelike_.relicOrder == 0 then
        return "遗物：无"
    end
    local names = {}
    for _, relicId in ipairs(roguelike_.relicOrder) do
        table.insert(names, GetRelicLabel(relicId))
    end
    return "遗物：" .. table.concat(names, "、")
end
