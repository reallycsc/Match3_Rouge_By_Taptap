local G = require "Game.Context"
local _ENV = G

local NUMBER_CONFIG_FIELDS = {
    { key = "boardSize", label = "棋盘尺寸", min = 5, max = 11, step = 1 },
    { key = "gemTypes", label = "符文种类", min = 3, max = 5, step = 1 },
    { key = "heroMaxHp", label = "玩家生命", min = 5, max = 99, step = 1 },
    { key = "baseMonsterHp", label = "怪物基础生命", min = 1, max = 50, step = 1 },
    { key = "monsterCount", label = "初始怪物数", min = 1, max = 12, step = 1 },
    { key = "monsterMaxCount", label = "怪物数量上限", min = 1, max = 20, step = 1 },
    { key = "monsterWaveHpBonus", label = "每波生命加成", min = 0, max = 20, step = 1 },
    { key = "monsterAttackBase", label = "怪物攻击", min = 0, max = 20, step = 1 },
    { key = "maxMonsterAttackersPerTurn", label = "每回合攻击怪物上限", min = 1, max = 12, step = 1 },
    { key = "monsterAttackPerWave", label = "波次攻击加成周期", min = 1, max = 20, step = 1 },
    { key = "matchDamageRadius", label = "消除伤害半径", min = 0, max = 3, step = 1 },
    { key = "scorePerGem", label = "单符文分数", min = 0, max = 999, step = 5 },
    { key = "killScore", label = "击杀分数", min = 0, max = 9999, step = 10 },
    { key = "killScorePerWave", label = "每波击杀分数加成", min = 0, max = 999, step = 5 },
    { key = "heroHealPerWave", label = "每波治疗", min = 0, max = 50, step = 1 },
    { key = "maxCascadeCombo", label = "最大连锁", min = 1, max = 20, step = 1 },
    { key = "swapDuration", label = "交换动画秒", min = 0.05, max = 1.0, step = 0.01 },
    { key = "clearDuration", label = "消除动画秒", min = 0.05, max = 1.0, step = 0.01 },
    { key = "dropDuration", label = "下落动画秒", min = 0.05, max = 1.0, step = 0.01 },
    { key = "laserDamage", label = "激光伤害", min = 0, max = 50, step = 1 },
    { key = "turretDamage", label = "炮台伤害", min = 0, max = 50, step = 1 },
    { key = "turretTurns", label = "炮台回合", min = 1, max = 20, step = 1 },
    { key = "bombDamage", label = "炸弹伤害", min = 0, max = 50, step = 1 },
    { key = "bombRadius", label = "炸弹半径", min = 1, max = 4, step = 1 },
    { key = "missileDamage", label = "导弹伤害", min = 0, max = 50, step = 1 },
    { key = "missileSiloTurns", label = "导弹井回合", min = 1, max = 20, step = 1 },
    { key = "missilesPerSiloTurn", label = "每回合导弹数", min = 1, max = 5, step = 1 },
}

function OpenNumberConfig()
    numberConfig_.visible = true
    numberConfig_.draft = {}
    numberConfig_.fields = NUMBER_CONFIG_FIELDS
    numberConfig_.rects = {}
    for _, field in ipairs(NUMBER_CONFIG_FIELDS) do
        numberConfig_.draft[field.key] = CONFIG[field.key]
    end
end

function CloseNumberConfig()
    numberConfig_.visible = false
end

function AdjustNumberConfigField(index, direction)
    local field = numberConfig_.fields[index]
    if field == nil then return end
    local current = numberConfig_.draft[field.key] or CONFIG[field.key] or 0
    local value = current + (field.step or 1) * direction
    value = Clamp(value, field.min, field.max)
    if (field.step or 1) >= 1 then value = math.floor(value + 0.5) end
    numberConfig_.draft[field.key] = value
end

function SaveNumberConfig()
    local data = {}
    for _, field in ipairs(NUMBER_CONFIG_FIELDS) do
        data[field.key] = CONFIG[field.key]
    end
    local file = File("number_config.json", FILE_WRITE)
    if file ~= nil and file:IsOpen() then
        file:WriteString(cjson.encode(data))
        file:Close()
        print("Saved number_config.json")
    else
        print("Failed to save number_config.json")
    end
end

function ApplyNumberConfig()
    for _, field in ipairs(numberConfig_.fields) do
        CONFIG[field.key] = numberConfig_.draft[field.key]
    end
    SaveNumberConfig()
    ApplyConfigGlobals()
    CloseNumberConfig()
    RecalcLayout()
    ResetGame()
    SetMessage("数值配置已应用，游戏已重新开始", 2.4)
end

function Clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function Abs(value)
    if value < 0 then return -value end
    return value
end

function CellKey(row, col)
    return row .. ":" .. col
end

function IsValidCell(row, col)
    return row >= 1 and row <= BOARD_SIZE and col >= 1 and col <= BOARD_SIZE
end

function IsAdjacent(a, b)
    return Abs(a.row - b.row) + Abs(a.col - b.col) == 1
end

function IsNearCell(aRow, aCol, bRow, bCol, radius)
    return Abs(aRow - bRow) <= radius and Abs(aCol - bCol) <= radius
end

function IsInCrossRange(aRow, aCol, bRow, bCol, radius)
    return Abs(aRow - bRow) + Abs(aCol - bCol) <= radius
end

function RecalcLayout()
    local graphics = GetGraphics()
    physW_ = graphics:GetWidth()
    physH_ = graphics:GetHeight()
    dpr_ = graphics:GetDPR()
    if dpr_ <= 0 then dpr_ = 1.0 end
    screenW_ = physW_ / dpr_
    screenH_ = physH_ / dpr_

    gap_ = Clamp(math.floor(math.min(screenW_, screenH_) * 0.008), 4, 8)
    local maxBoardW = screenW_ - 36
    local maxBoardH = screenH_ - 188
    boardPixels_ = math.floor(math.min(maxBoardW, maxBoardH))
    boardPixels_ = Clamp(boardPixels_, 320, 660)
    tile_ = math.floor((boardPixels_ - gap_ * (BOARD_SIZE - 1)) / BOARD_SIZE)
    boardPixels_ = tile_ * BOARD_SIZE + gap_ * (BOARD_SIZE - 1)
    boardX_ = (screenW_ - boardPixels_) * 0.5
    boardY_ = math.max(102, (screenH_ - boardPixels_) * 0.5 + 24)
end

function CellCenter(row, col)
    local x = boardX_ + (col - 1) * (tile_ + gap_) + tile_ * 0.5
    local y = boardY_ + (row - 1) * (tile_ + gap_) + tile_ * 0.5
    return x, y
end

function CellTopLeft(row, col)
    local x = boardX_ + (col - 1) * (tile_ + gap_)
    local y = boardY_ + (row - 1) * (tile_ + gap_)
    return x, y
end

function Lerp(a, b, t)
    return a + (b - a) * t
end

function EaseInOut(t)
    t = Clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

function EaseOutCubic(t)
    t = Clamp(t, 0, 1)
    local inv = 1 - t
    return 1 - inv * inv * inv
end

function EaseOutBack(t)
    t = Clamp(t, 0, 1)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) * (t - 1) * (t - 1) + c1 * (t - 1) * (t - 1)
end

function AddFloatText(row, col, text, color)
    local x, y = CellCenter(row, col)
    table.insert(floatTexts_, {
        x = x,
        y = y - tile_ * 0.2,
        text = text,
        color = color,
        life = 1.0,
        maxLife = 1.0,
        vy = -38,
    })
end

function AddParticles(row, col, color, count)
    local x, y = CellCenter(row, col)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 35 + math.random() * 95
        table.insert(particles_, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.42 + math.random() * 0.35,
            maxLife = 0.8,
            size = 2 + math.random() * 3,
            color = color,
        })
    end
end

function AddHeroDamageHudParticles(amount)
    local panelW = math.min(boardPixels_ + 24, screenW_ - 28)
    local panelX = (screenW_ - panelW) * 0.5
    local hpW = math.min(240, panelW * 0.45)
    local hpX = panelX + (panelW - hpW) * 0.5
    local hpY = 93
    local count = math.max(10, (amount or 1) * 8)
    for i = 1, count do
        table.insert(hudDamageParticles_, {
            x = hpX + math.random() * hpW,
            y = hpY + 4 + math.random() * 6,
            vx = (math.random() - 0.5) * 34,
            vy = 45 + math.random() * 105,
            life = 0.55 + math.random() * 0.25,
            maxLife = 0.8,
            size = 2 + math.random() * 3,
        })
    end
end

function AddItemTriggerEffect(kind, row, col, targetRow, targetCol)
    local x, y = CellCenter(row, col)
    local tx, ty = CellCenter(targetRow or row, targetCol or col)
    table.insert(itemTriggerEffects_, {
        kind = kind,
        row = row,
        col = col,
        targetRow = targetRow or row,
        targetCol = targetCol or col,
        x = x,
        y = y,
        tx = tx,
        ty = ty,
        life = 0.62,
        maxLife = 0.62,
    })
end

function PointInRect(x, y, rect)
    return rect ~= nil
        and x >= rect.x and y >= rect.y
        and x <= rect.x + rect.w and y <= rect.y + rect.h
end

function ClampOperationLogOffset()
    local rect = operationLogRect_
    if rect == nil then
        operationLogOffset_ = 0
        return
    end
    local maxRows = math.max(1, math.floor((rect.h - 68) / 21))
    local maxOffset = math.max(0, (operationLogDisplayRowCount_ or #operationLog_) - maxRows)
    operationLogOffset_ = Clamp(operationLogOffset_ or 0, 0, maxOffset)
end

function StartOperationLogDrag(y)
    operationLogDragging_ = true
    operationLogDragLastY_ = y
    uiPressConsumed_ = true
end

function UpdateOperationLogDrag(inputY)
    if not operationLogDragging_ then return false end
    local y = inputY / dpr_
    local dy = y - operationLogDragLastY_
    operationLogDragLastY_ = y
    if math.abs(dy) >= 8 then
        operationLogOffset_ = (operationLogOffset_ or 0) - math.floor(dy / 8)
        ClampOperationLogOffset()
    end
    return true
end

function StopOperationLogDrag()
    operationLogDragging_ = false
end

function HandleUiPress(inputX, inputY)
    local x = inputX / dpr_
    local y = inputY / dpr_
    uiPressConsumed_ = false

    if numberConfig_.visible then
        if PointInRect(x, y, numberConfig_.closeRect) then
            CloseNumberConfig()
            uiPressConsumed_ = true
            return true
        end
        if PointInRect(x, y, numberConfig_.confirmRect) then
            ApplyNumberConfig()
            uiPressConsumed_ = true
            return true
        end
        for index, rects in ipairs(numberConfig_.rects or {}) do
            if PointInRect(x, y, rects.minus) then
                AdjustNumberConfigField(index, -1)
                uiPressConsumed_ = true
                return true
            end
            if PointInRect(x, y, rects.plus) then
                AdjustNumberConfigField(index, 1)
                uiPressConsumed_ = true
                return true
            end
        end
        uiPressConsumed_ = true
        return true
    end

    if roguelike_ ~= nil and roguelike_.rewardVisible then
        uiPressConsumed_ = true
        return HandleRogueRewardPress(x, y)
    end

    if leaderboard_.visible then
        if PointInRect(x, y, leaderboardCloseRect_) then
            ToggleLeaderboard()
            uiPressConsumed_ = true
            return true
        end
        if not PointInRect(x, y, leaderboardPopupRect_) then
            ToggleLeaderboard()
            uiPressConsumed_ = true
            return true
        end
        uiPressConsumed_ = true
        return true
    end

    if PointInRect(x, y, leaderboardButtonRect_) then
        ToggleLeaderboard()
        uiPressConsumed_ = true
        return true
    end

    if PointInRect(x, y, actionLogButtonRect_) then
        operationLogVisible_ = not operationLogVisible_
        uiPressConsumed_ = true
        return true
    end

    if PointInRect(x, y, configButtonRect_) then
        OpenNumberConfig()
        uiPressConsumed_ = true
        return true
    end

    if PointInRect(x, y, testUnlockButtonRect_) then
        UnlockAllTestRelics()
        uiPressConsumed_ = true
        return true
    end

    if PointInRect(x, y, operationLogRect_) then
        StartOperationLogDrag(y)
        return true
    end

    return false
end

function AddOperationLog(text)
    if text == nil or text == "" then return end
    table.insert(operationLog_, 1, {
        text = text,
        time = time_ or 0,
    })
    while #operationLog_ > 80 do
        table.remove(operationLog_)
    end
end

function SetMessage(text, seconds)
    message_ = text
    messageTimer_ = seconds or 2.2
end
