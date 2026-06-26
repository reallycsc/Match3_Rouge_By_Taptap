local G = require "Game.Context"
local _ENV = G

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

function SetMessage(text, seconds)
    message_ = text
    messageTimer_ = seconds or 2.2
end
