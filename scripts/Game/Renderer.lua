local G = require "Game.Context"
local _ENV = G
---@diagnostic disable: undefined-global

function DrawText(ctx, x, y, size, text, color, align)
    if fontId_ ~= -1 then
        nvgFontFaceId(ctx, fontId_)
    else
        nvgFontFace(ctx, "sans")
    end
    nvgFontSize(ctx, size)
    nvgTextAlign(ctx, align or (NVG_ALIGN_LEFT + NVG_ALIGN_TOP))
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], color[4] or 255))
    nvgText(ctx, x, y, text, nil)
end

function DrawRoundedPanel(ctx, x, y, w, h, color, borderColor)
    nvgBeginPath(ctx)
    nvgRect(ctx, x + 4, y + 4, w, h)
    nvgFillColor(ctx, nvgRGBA(10, 10, 26, math.min(220, color[4] or 204)))
    nvgFill(ctx)

    nvgBeginPath(ctx)
    nvgRect(ctx, x, y, w, h)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], color[4] or 255))
    nvgFill(ctx)

    nvgBeginPath(ctx)
    nvgRect(ctx, x, y, w, h)
    local stroke = borderColor or { 58, 58, 106, 255 }
    nvgStrokeColor(ctx, nvgRGBA(stroke[1], stroke[2], stroke[3], stroke[4] or 255))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)

    nvgBeginPath(ctx)
    nvgMoveTo(ctx, x + 2, y + 2)
    nvgLineTo(ctx, x + w - 2, y + 2)
    nvgStrokeColor(ctx, nvgRGBA(255, 255, 255, 36))
    nvgStrokeWidth(ctx, 1)
    nvgStroke(ctx)
end

function DrawBackground(ctx)
    local bg = nvgLinearGradient(ctx, 0, 0, 0, screenH_, nvgRGBA(13, 8, 10, 255), nvgRGBA(37, 11, 14, 255))
    nvgBeginPath(ctx)
    nvgRect(ctx, 0, 0, screenW_, screenH_)
    nvgFillPaint(ctx, bg)
    nvgFill(ctx)

    for i = 1, 20 do
        local x = (i * 83 + time_ * 9) % (screenW_ + 120) - 60
        local y = 70 + ((i * 97) % math.max(100, screenH_ - 120))
        local alpha = 18 + math.floor(12 * math.sin(time_ * 1.7 + i))
        nvgBeginPath(ctx)
        nvgCircle(ctx, x, y, 2 + (i % 4))
        nvgFillColor(ctx, nvgRGBA(160, 54, 28, alpha))
        nvgFill(ctx)
    end
end

function DrawGemSlot(ctx, x, y, alpha)
    alpha = alpha or 1.0
    local slotAlpha = math.floor(240 * alpha)
    local slot = nvgLinearGradient(ctx, x, y, x, y + tile_, nvgRGBA(42, 30, 30, slotAlpha), nvgRGBA(16, 13, 14, math.floor(245 * alpha)))
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, tile_, tile_, 9)
    nvgFillPaint(ctx, slot)
    nvgFill(ctx)

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x + 1, y + 1, tile_ - 2, tile_ - 2, 8)
    nvgStrokeColor(ctx, nvgRGBA(105, 74, 54, math.floor(150 * alpha)))
    nvgStrokeWidth(ctx, 1.4)
    nvgStroke(ctx)
end

function DrawGemSymbol(ctx, row, col, gemType, overrideX, overrideY, alphaMul, scaleMul)
    local x = overrideX or (boardX_ + (col - 1) * (tile_ + gap_))
    local y = overrideY or (boardY_ + (row - 1) * (tile_ + gap_))
    local alpha = alphaMul or 1.0
    local scale = scaleMul or 1.0
    local color = GEM_COLORS[gemType]
    local cx = x + tile_ * 0.5
    local cy = y + tile_ * 0.5
    local r = tile_ * 0.32 * scale

    local glow = nvgRadialGradient(ctx, cx, cy, r * 0.15, r * 1.3,
        nvgRGBA(color[1], color[2], color[3], math.floor(165 * alpha)), nvgRGBA(color[1], color[2], color[3], 0))
    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, cy, r * 1.35)
    nvgFillPaint(ctx, glow)
    nvgFill(ctx)

    nvgBeginPath(ctx)
    if gemType == 1 then
        nvgMoveTo(ctx, cx, cy - r)
        nvgLineTo(ctx, cx + r * 0.82, cy)
        nvgLineTo(ctx, cx, cy + r)
        nvgLineTo(ctx, cx - r * 0.82, cy)
        nvgClosePath(ctx)
    elseif gemType == 2 then
        nvgCircle(ctx, cx, cy, r * 0.86)
    elseif gemType == 3 then
        nvgMoveTo(ctx, cx, cy - r)
        nvgLineTo(ctx, cx + r, cy + r * 0.75)
        nvgLineTo(ctx, cx - r, cy + r * 0.75)
        nvgClosePath(ctx)
    elseif gemType == 4 then
        nvgMoveTo(ctx, cx, cy - r)
        nvgLineTo(ctx, cx + r, cy - r * 0.1)
        nvgLineTo(ctx, cx + r * 0.46, cy + r)
        nvgLineTo(ctx, cx - r * 0.46, cy + r)
        nvgLineTo(ctx, cx - r, cy - r * 0.1)
        nvgClosePath(ctx)
    else
        for i = 1, 5 do
            local angle = -math.pi * 0.5 + (i - 1) * math.pi * 2 / 5
            local px = cx + math.cos(angle) * r
            local py = cy + math.sin(angle) * r
            if i == 1 then nvgMoveTo(ctx, px, py) else nvgLineTo(ctx, px, py) end
        end
        nvgClosePath(ctx)
    end

    local gemPaint = nvgLinearGradient(ctx, cx - r, cy - r, cx + r, cy + r,
        nvgRGBA(255, 255, 255, math.floor(95 * alpha)), nvgRGBA(color[1], color[2], color[3], math.floor(255 * alpha)))
    nvgFillPaint(ctx, gemPaint)
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(255, 230, 190, math.floor(160 * alpha)))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)

end

function DrawGem(ctx, row, col, gemType, overrideX, overrideY, alphaMul, scaleMul)
    local x = overrideX or (boardX_ + (col - 1) * (tile_ + gap_))
    local y = overrideY or (boardY_ + (row - 1) * (tile_ + gap_))
    DrawGemSlot(ctx, x, y, alphaMul or 1.0)
    DrawGemSymbol(ctx, row, col, gemType, x, y, alphaMul, scaleMul)
end

function DrawSelection(ctx)
    if selected_ == nil then return end
    local x = boardX_ + (selected_.col - 1) * (tile_ + gap_)
    local y = boardY_ + (selected_.row - 1) * (tile_ + gap_)
    local pulse = 0.5 + 0.5 * math.sin(time_ * 8)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x - 3, y - 3, tile_ + 6, tile_ + 6, 11)
    nvgStrokeColor(ctx, nvgRGBA(255, 214, 80, math.floor(160 + pulse * 90)))
    nvgStrokeWidth(ctx, 3)
    nvgStroke(ctx)
end

function DrawHero(ctx)
    local cx, cy = CellCenter(hero_.row, hero_.col)
    local pulse = 0.5 + 0.5 * math.sin(time_ * 5)
    local r = tile_ * 0.34

    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, cy, r * (1.35 + pulse * 0.08))
    nvgFillColor(ctx, nvgRGBA(255, 190, 58, 40))
    nvgFill(ctx)

    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, cy - r * 0.15, r * 0.62)
    nvgFillColor(ctx, nvgRGBA(42, 42, 50, 255))
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(245, 195, 80, 255))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)

    nvgBeginPath(ctx)
    nvgMoveTo(ctx, cx - r * 0.95, cy + r * 0.95)
    nvgLineTo(ctx, cx, cy + r * 0.15)
    nvgLineTo(ctx, cx + r * 0.95, cy + r * 0.95)
    nvgClosePath(ctx)
    nvgFillColor(ctx, nvgRGBA(34, 45, 78, 245))
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(245, 195, 80, 230))
    nvgStrokeWidth(ctx, 1.8)
    nvgStroke(ctx)

    DrawText(ctx, cx, cy - r * 0.16, tile_ * 0.3, "主", { 255, 224, 130, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
end

function DrawMonsterAt(ctx, monster, cx, cy)
    local r = tile_ * 0.32
    local hurt = 1.0 - Clamp(monster.hp / monster.maxHp, 0, 1)
    local pulse = 0.5 + 0.5 * math.sin(time_ * 6 + monster.pulse)

    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, cy, r * (1.24 + pulse * 0.08))
    nvgFillColor(ctx, nvgRGBA(190, 22, 18, 45 + math.floor(hurt * 70)))
    nvgFill(ctx)

    nvgBeginPath(ctx)
    nvgMoveTo(ctx, cx - r * 0.9, cy - r * 0.2)
    nvgLineTo(ctx, cx - r * 1.35, cy - r * 0.95)
    nvgLineTo(ctx, cx - r * 0.25, cy - r * 0.7)
    nvgMoveTo(ctx, cx + r * 0.9, cy - r * 0.2)
    nvgLineTo(ctx, cx + r * 1.35, cy - r * 0.95)
    nvgLineTo(ctx, cx + r * 0.25, cy - r * 0.7)
    nvgStrokeColor(ctx, nvgRGBA(110, 18, 16, 255))
    nvgStrokeWidth(ctx, 4)
    nvgStroke(ctx)

    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, cy, r * 0.82)
    nvgFillColor(ctx, nvgRGBA(102 + math.floor(hurt * 80), 20, 24, 255))
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(255, 82, 55, 230))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)

    nvgBeginPath(ctx)
    nvgCircle(ctx, cx - r * 0.28, cy - r * 0.12, r * 0.13)
    nvgCircle(ctx, cx + r * 0.28, cy - r * 0.12, r * 0.13)
    nvgFillColor(ctx, nvgRGBA(255, 198, 60, 255))
    nvgFill(ctx)

end

function DrawMonster(ctx, monster)
    local cx, cy = CellCenter(monster.row, monster.col)
    DrawMonsterAt(ctx, monster, cx, cy)
end

function IsCellHiddenByAnimation(row, col)
    for _, move in ipairs(monsterMoves_) do
        if row == move.fromRow and col == move.fromCol then return true end
        if row == move.toRow and col == move.toCol then return true end
    end

    local anim = currentAnim_
    if anim == nil then return false end

    if anim.kind == "swap" or anim.kind == "itemSwapTrigger" then
        return (row == anim.a.row and col == anim.a.col) or (row == anim.b.row and col == anim.b.col)
    elseif anim.kind == "clear" then
        for _, cell in ipairs(anim.matches) do
            if row == cell.row and col == cell.col then return true end
        end
    elseif anim.kind == "drop" or anim.kind == "enemyDrop" then
        for _, drop in ipairs(anim.drops) do
            if row == drop.toRow and col == drop.toCol then return true end
        end
    end

    return false
end

function DrawAnimatedGems(ctx)
    local anim = currentAnim_
    if anim == nil then return end
    local t = Clamp(anim.elapsed / anim.duration, 0, 1)

    if anim.kind == "swap" then
        local eased = EaseInOut(t)
        local ax, ay = CellTopLeft(anim.a.row, anim.a.col)
        local bx, by = CellTopLeft(anim.b.row, anim.b.col)
        if anim.reverse then eased = 1 - eased end
        DrawGem(ctx, anim.a.row, anim.a.col, anim.typeB, Lerp(ax, bx, eased), Lerp(ay, by, eased), 1.0, 1.06)
        DrawGem(ctx, anim.b.row, anim.b.col, anim.typeA, Lerp(bx, ax, eased), Lerp(by, ay, eased), 1.0, 1.06)
    elseif anim.kind == "itemSwapTrigger" then
        local eased = EaseInOut(t)
        local ax, ay = CellCenter(anim.a.row, anim.a.col)
        local bx, by = CellCenter(anim.b.row, anim.b.col)
        if anim.objA.kind == "gem" then
            local x, y = CellTopLeft(anim.b.row, anim.b.col)
            local tx, ty = CellTopLeft(anim.a.row, anim.a.col)
            DrawGem(ctx, anim.a.row, anim.a.col, anim.objA.gemType, Lerp(tx, x, eased), Lerp(ty, y, eased), 1.0, 1.06)
        elseif anim.objA.kind == "trap" then
            DrawTrapIconAt(ctx, anim.objA.ref.kind, Lerp(ax, bx, eased), Lerp(ay, by, eased), 1.06, 1.0)
        end
        if anim.objB.kind == "gem" then
            local x, y = CellTopLeft(anim.a.row, anim.a.col)
            local tx, ty = CellTopLeft(anim.b.row, anim.b.col)
            DrawGem(ctx, anim.b.row, anim.b.col, anim.objB.gemType, Lerp(tx, x, eased), Lerp(ty, y, eased), 1.0, 1.06)
        elseif anim.objB.kind == "trap" then
            DrawTrapIconAt(ctx, anim.objB.ref.kind, Lerp(bx, ax, eased), Lerp(by, ay, eased), 1.06, 1.0)
        end
    elseif anim.kind == "clear" then
        local pulse = math.sin(t * math.pi)
        for _, cell in ipairs(anim.matches) do
            local x, y = CellTopLeft(cell.row, cell.col)
            DrawGem(ctx, cell.row, cell.col, cell.type, x, y, 1 - t * 0.85, 1.0 + pulse * 0.35)
        end
    elseif anim.kind == "drop" or anim.kind == "enemyDrop" then
        local eased = EaseOutBack(t)
        for _, drop in ipairs(anim.drops) do
            local fromX, fromY = CellTopLeft(drop.fromRow, drop.fromCol)
            local toX, toY = CellTopLeft(drop.toRow, drop.toCol)
            DrawGem(ctx, drop.toRow, drop.toCol, drop.type, Lerp(fromX, toX, eased), Lerp(fromY, toY, eased), 1.0, 1.0)
        end
    end
end

function DrawAnimatedMonsterMoves(ctx)
    for _, move in ipairs(monsterMoves_) do
        local t = 1 - Clamp(move.life / move.maxLife, 0, 1)
        local eased = EaseInOut(t)
        local fromX, fromY = CellCenter(move.fromRow, move.fromCol)
        local toX, toY = CellCenter(move.toRow, move.toCol)
        DrawMonsterAt(ctx, move.monster, Lerp(fromX, toX, eased), Lerp(fromY, toY, eased))
    end
end

function DrawLaserBeams(ctx)
    for _, beam in ipairs(laserBeams_) do
        local sx, sy = CellCenter(beam.row, beam.col)
        local tx, ty = CellCenter(beam.targetRow, beam.targetCol)
        local t = Clamp(beam.life / beam.maxLife, 0, 1)
        local progress = 1 - t
        local alpha = math.floor(255 * t)
        local x1, y1, x2, y2 = sx, sy, sx, sy
        if beam.kind == "laserH" then
            x1 = Lerp(sx, boardX_, progress)
            x2 = Lerp(sx, boardX_ + boardPixels_, progress)
        else
            y1 = Lerp(sy, boardY_, progress)
            y2 = Lerp(sy, boardY_ + boardPixels_, progress)
        end

        local glowWidth = 14 + math.sin(progress * math.pi) * 8
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, x1, y1)
        nvgLineTo(ctx, x2, y2)
        nvgStrokeColor(ctx, nvgRGBA(255, 32, 28, math.floor(alpha * 0.24)))
        nvgStrokeWidth(ctx, glowWidth)
        nvgStroke(ctx)

        nvgBeginPath(ctx)
        nvgMoveTo(ctx, x1, y1)
        nvgLineTo(ctx, x2, y2)
        nvgStrokeColor(ctx, nvgRGBA(255, 20, 16, alpha))
        nvgStrokeWidth(ctx, 6)
        nvgStroke(ctx)

        nvgBeginPath(ctx)
        nvgMoveTo(ctx, x1, y1)
        nvgLineTo(ctx, x2, y2)
        nvgStrokeColor(ctx, nvgRGBA(255, 214, 180, math.floor(alpha * 0.88)))
        nvgStrokeWidth(ctx, 1.8)
        nvgStroke(ctx)

        if progress > 0.72 then
            nvgBeginPath(ctx)
            nvgCircle(ctx, tx, ty, tile_ * (0.28 + progress * 0.2))
            nvgStrokeColor(ctx, nvgRGBA(255, 50, 38, alpha))
            nvgStrokeWidth(ctx, 4)
            nvgStroke(ctx)
        end
    end
end

function DrawBombExplosions(ctx)
    for _, explosion in ipairs(bombExplosions_) do
        local t = Clamp(explosion.life / explosion.maxLife, 0, 1)
        local progress = 1 - t
        local alpha = math.floor(230 * t)
        local radius = tile_ * (0.35 + progress * 1.65)

        local glow = nvgRadialGradient(ctx, explosion.x, explosion.y, radius * 0.08, radius,
            nvgRGBA(255, 196, 82, math.floor(180 * t)), nvgRGBA(255, 48, 28, 0))
        nvgBeginPath(ctx)
        nvgCircle(ctx, explosion.x, explosion.y, radius)
        nvgFillPaint(ctx, glow)
        nvgFill(ctx)

        nvgBeginPath(ctx)
        nvgCircle(ctx, explosion.x, explosion.y, radius * 0.72)
        nvgStrokeColor(ctx, nvgRGBA(255, 86, 36, alpha))
        nvgStrokeWidth(ctx, 4)
        nvgStroke(ctx)

        nvgBeginPath(ctx)
        for i = 1, 10 do
            local angle = time_ * 2.5 + i * math.pi * 2 / 10
            local inner = radius * 0.18
            local outer = radius * (0.55 + 0.18 * math.sin(progress * math.pi + i))
            nvgMoveTo(ctx, explosion.x + math.cos(angle) * inner, explosion.y + math.sin(angle) * inner)
            nvgLineTo(ctx, explosion.x + math.cos(angle) * outer, explosion.y + math.sin(angle) * outer)
        end
        nvgStrokeColor(ctx, nvgRGBA(255, 222, 120, math.floor(210 * t)))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)
    end
end

function DrawLaserAimLine(ctx, trap)
    local cx, cy = CellCenter(trap.row, trap.col)
    local pulse = 0.5 + 0.5 * math.sin(time_ * 8.5)
    local alpha = 92 + math.floor(pulse * 80)
    local targetAlpha = trap.targetRow ~= nil and 235 or 135

    nvgBeginPath(ctx)
    if trap.kind == "laserH" then
        nvgMoveTo(ctx, boardX_, cy)
        nvgLineTo(ctx, boardX_ + boardPixels_, cy)
    else
        nvgMoveTo(ctx, cx, boardY_)
        nvgLineTo(ctx, cx, boardY_ + boardPixels_)
    end
    nvgStrokeColor(ctx, nvgRGBA(255, 64, 56, alpha))
    nvgStrokeWidth(ctx, 1.4 + pulse * 1.3)
    nvgStroke(ctx)

    nvgBeginPath(ctx)
    if trap.kind == "laserH" then
        nvgMoveTo(ctx, boardX_, cy - 5)
        nvgLineTo(ctx, boardX_ + boardPixels_, cy - 5)
        nvgMoveTo(ctx, boardX_, cy + 5)
        nvgLineTo(ctx, boardX_ + boardPixels_, cy + 5)
    else
        nvgMoveTo(ctx, cx - 5, boardY_)
        nvgLineTo(ctx, cx - 5, boardY_ + boardPixels_)
        nvgMoveTo(ctx, cx + 5, boardY_)
        nvgLineTo(ctx, cx + 5, boardY_ + boardPixels_)
    end
    nvgStrokeColor(ctx, nvgRGBA(255, 36, 32, math.floor(alpha * 0.38)))
    nvgStrokeWidth(ctx, 1.0)
    nvgStroke(ctx)

    if trap.targetRow ~= nil and trap.targetCol ~= nil then
        local tx, ty = CellCenter(trap.targetRow, trap.targetCol)
        nvgBeginPath(ctx)
        nvgCircle(ctx, tx, ty, tile_ * (0.24 + pulse * 0.06))
        nvgStrokeColor(ctx, nvgRGBA(255, 58, 42, targetAlpha))
        nvgStrokeWidth(ctx, 2.2)
        nvgStroke(ctx)
    end
end

function DrawAimLine(ctx, fromRow, fromCol, targetRow, targetCol, color)
    if targetRow == nil or targetCol == nil then return end
    local sx, sy = CellCenter(fromRow, fromCol)
    local tx, ty = CellCenter(targetRow, targetCol)
    local pulse = 0.5 + 0.5 * math.sin(time_ * 7)
    local alpha = math.floor((95 + pulse * 80) * (color[4] or 1))

    nvgBeginPath(ctx)
    nvgMoveTo(ctx, sx, sy)
    nvgLineTo(ctx, tx, ty)
    nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha))
    nvgStrokeWidth(ctx, 1.8 + pulse * 0.9)
    nvgStroke(ctx)

    nvgBeginPath(ctx)
    nvgCircle(ctx, tx, ty, tile_ * (0.18 + pulse * 0.05))
    nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], math.floor(alpha * 0.9)))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)
end

function DrawAutoAimLines(ctx)
    for _, trap in ipairs(traps_) do
        if trap.kind == "laserH" or trap.kind == "laserV" then
            DrawLaserAimLine(ctx, trap)
        elseif trap.kind == "turret" then
            DrawAimLine(ctx, trap.row, trap.col, trap.targetRow, trap.targetCol, { 255, 214, 92, 1.0 })
        end
    end
    for _, silo in ipairs(missileSilos_) do
        DrawAimLine(ctx, silo.row, silo.col, silo.targetRow, silo.targetCol, { 255, 126, 50, 1.0 })
    end
end

function DrawTurnBadge(ctx, cx, cy, turns, alphaMul)
    local alpha = alphaMul or 1.0
    local badgeY = cy - tile_ * 0.36
    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, badgeY, tile_ * 0.17)
    nvgFillColor(ctx, nvgRGBA(38, 25, 14, math.floor(230 * alpha)))
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(255, 218, 112, math.floor(220 * alpha)))
    nvgStrokeWidth(ctx, 1.4)
    nvgStroke(ctx)
    DrawText(ctx, cx, badgeY, tile_ * 0.2, tostring(turns or 0), { 255, 238, 150, math.floor(255 * alpha) }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
end

function DrawMissileSilos(ctx)
    for _, silo in ipairs(missileSilos_) do
        local cx, cy = CellCenter(silo.row, silo.col)
        local appear = Clamp((silo.age or 0) / 0.22, 0, 1)
        local pulse = 0.5 + 0.5 * math.sin(time_ * 5.5)
        local r = tile_ * (0.22 + pulse * 0.04) * appear

        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, tile_ * 0.42 * appear)
        nvgFillColor(ctx, nvgRGBA(60, 54, 48, math.floor(220 * appear)))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 216, 110, math.floor((190 + pulse * 45) * appear)))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)

        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, r)
        nvgFillColor(ctx, nvgRGBA(255, 132, 48, math.floor((130 + pulse * 70) * appear)))
        nvgFill(ctx)
        DrawTurnBadge(ctx, cx, cy, silo.turnsLeft or 0, appear)
    end
end

function DrawMissileLaunches(ctx)
    for _, launch in ipairs(missileLaunches_) do
        local t = Clamp(launch.life / launch.maxLife, 0, 1)
        local progress = 1 - t
        local radius = tile_ * (0.16 + progress * 0.34)
        local glow = nvgRadialGradient(ctx, launch.x, launch.y, radius * 0.1, radius,
            nvgRGBA(255, 224, 108, math.floor(210 * t)), nvgRGBA(255, 80, 24, 0))
        nvgBeginPath(ctx)
        nvgCircle(ctx, launch.x, launch.y, radius)
        nvgFillPaint(ctx, glow)
        nvgFill(ctx)
    end
end

function DrawMissiles(ctx)
    for _, missile in ipairs(missiles_) do
        local t = Clamp(missile.life / missile.maxLife, 0, 1)
        local alphaMul = missile.alpha or 1
        local progress = 1 - t
        local scale = missile.scale or 1
        local tailX = Lerp(missile.fromX, missile.x, 0.68)
        local tailY = Lerp(missile.fromY, missile.y, 0.68)

        nvgBeginPath(ctx)
        nvgMoveTo(ctx, tailX, tailY)
        nvgLineTo(ctx, missile.x, missile.y)
        nvgStrokeColor(ctx, nvgRGBA(255, 154, 62, math.floor(235 * t * alphaMul)))
        nvgStrokeWidth(ctx, 2.2 * scale)
        nvgStroke(ctx)

        nvgBeginPath(ctx)
        nvgCircle(ctx, missile.x, missile.y, tile_ * (0.08 + progress * 0.025) * scale)
        nvgFillColor(ctx, nvgRGBA(255, 236, 145, math.floor(255 * t * alphaMul)))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 84, 34, math.floor(230 * t * alphaMul)))
        nvgStrokeWidth(ctx, 1.5 * scale)
        nvgStroke(ctx)
    end
end

function DrawCannonShells(ctx)
    for _, shell in ipairs(cannonShells_) do
        local t = Clamp(shell.life / shell.maxLife, 0, 1)
        local radius = tile_ * (0.09 + (1 - t) * 0.03)
        nvgBeginPath(ctx)
        nvgCircle(ctx, shell.x, shell.y, radius * 2.2)
        nvgFillColor(ctx, nvgRGBA(255, 130, 52, math.floor(55 * t)))
        nvgFill(ctx)
        nvgBeginPath(ctx)
        nvgCircle(ctx, shell.x, shell.y, radius)
        nvgFillColor(ctx, nvgRGBA(255, 210, 98, math.floor(245 * t)))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(130, 52, 24, math.floor(210 * t)))
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
    end
end

function DrawTrapImage(ctx, x, y, w, h, alpha, tint)
    if trapImage_ ~= -1 then
        local paint = nil
        if tint then
            paint = nvgImagePatternTinted(ctx, x, y, w, h, 0, trapImage_, nvgRGBA(tint[1], tint[2], tint[3], tint[4] or 255))
        else
            paint = nvgImagePattern(ctx, x, y, w, h, 0, trapImage_, alpha or 1.0)
        end
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x, y, w, h, 8)
        nvgFillPaint(ctx, paint)
        nvgFill(ctx)
    else
        local fill = nvgLinearGradient(ctx, x, y, x + w, y + h, nvgRGBA(80, 55, 36, 180), nvgRGBA(20, 26, 36, 160))
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x, y, w, h, 8)
        nvgFillPaint(ctx, fill)
        nvgFill(ctx)
    end
end

function GetTrapRect(trap, inset)
    local minRow = trap.minRow or trap.row
    local maxRow = trap.maxRow or trap.row
    local minCol = trap.minCol or trap.col
    local maxCol = trap.maxCol or trap.col
    local x, y = CellTopLeft(minRow, minCol)
    local w = (maxCol - minCol + 1) * tile_ + (maxCol - minCol) * gap_
    local h = (maxRow - minRow + 1) * tile_ + (maxRow - minRow) * gap_
    local pad = inset or 2
    return x + pad, y + pad, w - pad * 2, h - pad * 2
end

function DrawTrapIconAt(ctx, kind, cx, cy, scale, alpha)
    local alphaMul = alpha or 1.0
    local iconSize = tile_ * 0.82 * (scale or 1.0)
    local x = cx - iconSize * 0.5
    local y = cy - iconSize * 0.5
    if kind == "laserH" or kind == "laserV" then
        DrawTrapImage(ctx, x, y, iconSize, iconSize, 0.7 * alphaMul, { 80, 225, 255, math.floor(185 * alphaMul) })
        nvgBeginPath(ctx)
        if kind == "laserH" then
            nvgRect(ctx, cx - iconSize * 0.36, cy - 1.5, iconSize * 0.72, 3)
        else
            nvgRect(ctx, cx - 1.5, cy - iconSize * 0.36, 3, iconSize * 0.72)
        end
        nvgFillColor(ctx, nvgRGBA(80, 230, 255, math.floor(190 * alphaMul)))
        nvgFill(ctx)
        DrawText(ctx, cx, cy, tile_ * 0.22 * (scale or 1.0), "激", { 185, 245, 255, math.floor(255 * alphaMul) }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    elseif kind == "bomb" then
        DrawTrapImage(ctx, x, y, iconSize, iconSize, 0.8 * alphaMul, { 255, 116, 72, math.floor(190 * alphaMul) })
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, iconSize * 0.5)
        nvgStrokeColor(ctx, nvgRGBA(255, 176, 90, math.floor(210 * alphaMul)))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)
        DrawText(ctx, cx, cy, tile_ * 0.22 * (scale or 1.0), "爆", { 255, 238, 180, math.floor(255 * alphaMul) }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    end
end

function DrawTrapBase(ctx, trap)
    local pulse = 0.5 + 0.5 * math.sin(time_ * 5)
    local cx, cy = CellCenter(trap.row, trap.col)
    local iconSize = tile_ * 0.82
    local x = cx - iconSize * 0.5
    local y = cy - iconSize * 0.5

    if trap.kind == "laserH" or trap.kind == "laserV" then
        DrawTrapImage(ctx, x, y, iconSize, iconSize, 0.7, { 80, 225, 255, 120 + math.floor(pulse * 50) })
    elseif trap.kind == "turret" then
        DrawTrapImage(ctx, x, y, iconSize, iconSize, 0.8, { 255, 201, 96, 145 + math.floor(pulse * 45) })
    elseif trap.kind == "bomb" then
        DrawTrapImage(ctx, x, y, iconSize, iconSize, 0.8, { 255, 116, 72, 145 + math.floor(pulse * 45) })
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, iconSize * 0.5)
        nvgStrokeColor(ctx, nvgRGBA(255, 176, 90, 160 + math.floor(pulse * 70)))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)
    end
end

function DrawTrapOverlay(ctx, trap)
    local cx, cy = CellCenter(trap.row, trap.col)
    local r = tile_ * 0.34
    local pulse = 0.5 + 0.5 * math.sin(time_ * 5)

    if trap.kind == "laserH" or trap.kind == "laserV" then
        nvgBeginPath(ctx)
        if trap.kind == "laserH" then
            nvgRect(ctx, boardX_, cy - 1.4, boardPixels_, 2.8)
        else
            nvgRect(ctx, cx - 1.4, boardY_, 2.8, boardPixels_)
        end
        nvgFillColor(ctx, nvgRGBA(80, 230, 255, 54 + math.floor(pulse * 34)))
        nvgFill(ctx)
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, r * 0.58)
        nvgStrokeColor(ctx, nvgRGBA(80, 230, 255, 210))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)
        DrawText(ctx, cx, cy, tile_ * 0.22, "激", { 185, 245, 255, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    elseif trap.kind == "turret" then
        local barrelLength = tile_ * 0.38
        local barrelWidth = math.max(5, tile_ * 0.11)
        local angle = trap.angle or -math.pi * 0.5
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, tile_ * 0.23)
        nvgFillColor(ctx, nvgRGBA(106, 84, 54, 225))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 214, 120, 220))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)

        nvgSave(ctx)
        nvgTranslate(ctx, cx, cy)
        nvgRotate(ctx, angle)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, 0, -barrelWidth * 0.5, barrelLength, barrelWidth, barrelWidth * 0.4)
        nvgFillColor(ctx, nvgRGBA(72, 64, 56, 240))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 204, 92, 220))
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
        nvgRestore(ctx)

        DrawTurnBadge(ctx, cx, cy, trap.turns or 0)
    elseif trap.kind == "bomb" then
        local warnAlpha = 22 + math.floor(pulse * 58)
        local strokeAlpha = 96 + math.floor(pulse * 110)
        local expand = tile_ * (0.04 + pulse * 0.05)
        local x = cx - tile_ * 1.5 - expand
        local y = cy - tile_ * 1.5 - expand
        local size = tile_ * 3 + expand * 2
        local glow = nvgRadialGradient(ctx, cx, cy, tile_ * 0.45, tile_ * (2.0 + pulse * 0.35),
            nvgRGBA(255, 112, 58, warnAlpha), nvgRGBA(255, 40, 24, 0))
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x, y, size, size, 10 + pulse * 6)
        nvgFillPaint(ctx, glow)
        nvgFill(ctx)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x, y, size, size, 10 + pulse * 6)
        nvgFillColor(ctx, nvgRGBA(255, 78, 52, warnAlpha))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 176, 90, strokeAlpha))
        nvgStrokeWidth(ctx, 1.6 + pulse * 1.8)
        nvgStroke(ctx)
        DrawText(ctx, cx + 2, cy + 2, tile_ * 0.22, "爆", { 0, 0, 0, 150 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        DrawText(ctx, cx, cy, tile_ * 0.22, "爆", { 255, 238, 180, 240 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    end
end

function DrawTrap(ctx, trap)
    DrawTrapOverlay(ctx, trap)
end

function DrawGemSlots(ctx)
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local x, y = CellTopLeft(row, col)
            DrawGemSlot(ctx, x, y, 1.0)
        end
    end
end

function DrawBestMoveHint(ctx)
    if isAnimating_ or gameState_ ~= "playing" or hintScore_ <= 0 then return end
    local pulse = 0.5 + 0.5 * math.sin(time_ * 2.4)
    local alpha = math.floor(58 + pulse * 82)
    local scale = 1.0 + pulse * 0.08

    for key, enabled in pairs(hintCells_) do
        if enabled then
            local sep = string.find(key, ":")
            if sep then
                local row = tonumber(string.sub(key, 1, sep - 1))
                local col = tonumber(string.sub(key, sep + 1))
                if row and col and board_[row] and board_[row][col] ~= 0 and not IsCellHiddenByAnimation(row, col) then
                    local cx, cy = CellCenter(row, col)
                    local r = tile_ * 0.46 * scale
                    local glow = nvgRadialGradient(ctx, cx, cy, r * 0.28, r * 1.45,
                        nvgRGBA(255, 226, 108, alpha), nvgRGBA(255, 226, 108, 0))
                    nvgBeginPath(ctx)
                    nvgCircle(ctx, cx, cy, r * 1.45)
                    nvgFillPaint(ctx, glow)
                    nvgFill(ctx)

                    nvgBeginPath(ctx)
                    nvgRoundedRect(ctx, cx - tile_ * 0.44 * scale, cy - tile_ * 0.44 * scale,
                        tile_ * 0.88 * scale, tile_ * 0.88 * scale, 10)
                    nvgStrokeColor(ctx, nvgRGBA(255, 230, 120, alpha + 60))
                    nvgStrokeWidth(ctx, 2.2 + pulse * 1.4)
                    nvgStroke(ctx)
                end
            end
        end
    end
end

function DrawStaticGemSymbols(ctx)
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            if board_[row][col] ~= 0 and not IsCellHiddenByAnimation(row, col) then
                DrawGemSymbol(ctx, row, col, board_[row][col])
            end
        end
    end
end

function IsMonsterAnimating(monster)
    for _, move in ipairs(monsterMoves_) do
        if move.monster == monster then return true end
    end
    return false
end

function DrawBoard(ctx)
    local shakeX = 0
    local shakeY = 0
    if screenShake_ > 0 then
        shakeX = math.sin(time_ * 70) * screenShake_ * 0.45
        shakeY = math.cos(time_ * 60) * screenShake_ * 0.35
    end

    nvgSave(ctx)
    nvgTranslate(ctx, shakeX, shakeY)

    DrawRoundedPanel(ctx, boardX_ - 12, boardY_ - 12, boardPixels_ + 24, boardPixels_ + 24,
        { 18, 12, 13, 230 }, { 117, 74, 42, 230 })

    -- 伤害范围示意：每个被消除格会以自身为中心，影响周围 3x3 格：
    -- [x][x][x]
    -- [x][消][x]
    -- [x][x][x]
    DrawGemSlots(ctx)
    DrawBestMoveHint(ctx)

    for _, trap in ipairs(traps_) do
        if not IsCellHiddenByAnimation(trap.row, trap.col) then
            DrawTrapBase(ctx, trap)
        end
    end

    DrawAutoAimLines(ctx)

    DrawStaticGemSymbols(ctx)

    DrawAnimatedGems(ctx)

    for _, trap in ipairs(traps_) do
        if not IsCellHiddenByAnimation(trap.row, trap.col) then
            DrawTrap(ctx, trap)
        end
    end
    DrawLaserBeams(ctx)
    DrawBombExplosions(ctx)
    DrawMissileSilos(ctx)
    DrawMissileLaunches(ctx)
    DrawMissiles(ctx)
    DrawCannonShells(ctx)

    for _, effect in ipairs(matchEffects_) do
        local cx, cy = CellCenter(effect.row, effect.col)
        local t = effect.life / effect.maxLife
        local color = GEM_COLORS[effect.type]
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, tile_ * (0.25 + (1 - t) * 0.55))
        nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], math.floor(t * 180)))
        nvgStrokeWidth(ctx, 3)
        nvgStroke(ctx)
    end

    DrawSelection(ctx)

    for _, monster in ipairs(monsters_) do
        if not IsMonsterAnimating(monster) then
            DrawMonster(ctx, monster)
        end
    end
    DrawAnimatedMonsterMoves(ctx)
    DrawHero(ctx)

    nvgRestore(ctx)
end

function DrawEffects(ctx)
    for _, p in ipairs(particles_) do
        local alpha = math.floor(Clamp(p.life / p.maxLife, 0, 1) * (p.color[4] or 255))
        nvgBeginPath(ctx)
        nvgCircle(ctx, p.x, p.y, p.size)
        nvgFillColor(ctx, nvgRGBA(p.color[1], p.color[2], p.color[3], alpha))
        nvgFill(ctx)
    end

    for _, item in ipairs(floatTexts_) do
        local alpha = math.floor(Clamp(item.life / item.maxLife, 0, 1) * (item.color[4] or 255))
        DrawText(ctx, item.x + 2, item.y + 2, 20, item.text, { 0, 0, 0, math.floor(alpha * 0.6) }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        DrawText(ctx, item.x, item.y, 20, item.text, { item.color[1], item.color[2], item.color[3], alpha }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    end
end

function DrawToolInfoIcon(ctx, cx, cy, kind)
    local r = 13
    local pulse = 0.5 + 0.5 * math.sin(time_ * 5)
    if kind == "laser" then
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, cx - r, cy - r, r * 2, r * 2, 6)
        nvgFillColor(ctx, nvgRGBA(28, 62, 74, 235))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(90, 230, 255, 210))
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, cx - r * 0.65, cy)
        nvgLineTo(ctx, cx + r * 0.65, cy)
        nvgStrokeColor(ctx, nvgRGBA(120, 240, 255, 210 + math.floor(pulse * 35)))
        nvgStrokeWidth(ctx, 3)
        nvgStroke(ctx)
    elseif kind == "turret" then
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, r)
        nvgFillColor(ctx, nvgRGBA(88, 68, 42, 235))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 214, 112, 220))
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, cx, cy - 3, r * 0.88, 6, 3)
        nvgFillColor(ctx, nvgRGBA(58, 52, 46, 245))
        nvgFill(ctx)
    elseif kind == "missile" then
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy, r)
        nvgFillColor(ctx, nvgRGBA(70, 54, 40, 235))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 194, 82, 220))
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, cx, cy - r * 0.72)
        nvgLineTo(ctx, cx + r * 0.45, cy + r * 0.5)
        nvgLineTo(ctx, cx - r * 0.45, cy + r * 0.5)
        nvgClosePath(ctx)
        nvgFillColor(ctx, nvgRGBA(255, 132, 48, 230))
        nvgFill(ctx)
    elseif kind == "bomb" then
        nvgBeginPath(ctx)
        nvgCircle(ctx, cx, cy + 2, r * 0.86)
        nvgFillColor(ctx, nvgRGBA(132, 44, 34, 238))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 148, 72, 220))
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, cx + r * 0.2, cy - r * 0.7)
        nvgLineTo(ctx, cx + r * 0.68, cy - r * 1.05)
        nvgStrokeColor(ctx, nvgRGBA(255, 218, 118, 230))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)
    end
end

function DrawToolInfoPanel(ctx)
    local panelW = math.min(245, math.max(178, boardX_ - 24))
    if boardX_ < 190 then
        panelW = 172
    end
    local x = 14
    local y = boardY_
    local rowH = 76
    local panelH = 42 + rowH * 4

    DrawRoundedPanel(ctx, x, y, panelW, panelH, { 27, 27, 58, 236 }, { 33, 189, 174, 230 })
    DrawText(ctx, x + panelW * 0.5, y + 14, 17, "遗物解锁效果", { 33, 189, 174, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, x + panelW * 0.5, y + 35, 11, "波次奖励获得遗物后生效", { 160, 160, 192, 230 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local items = {
        { kind = "laser", relicId = "laser_core", title = "激光", rule = "横/纵4消", damage = "主动伤害 " .. tostring(CONFIG.laserDamage), desc = "持久存在，再次点击/交换后触发" },
        { kind = "turret", relicId = "turret_contract", title = "炮台", rule = "方块4消", damage = "每回合 " .. tostring(CONFIG.turretDamage), desc = "持续" .. tostring(CONFIG.turretTurns) .. "回合瞄准最近怪物" },
        { kind = "missile", relicId = "missile_manual", title = "导弹井", rule = "直线5消", damage = "每回合 1枚*" .. tostring(CONFIG.missileDamage), desc = "存在" .. tostring(CONFIG.missileSiloTurns) .. "回合追踪目标" },
        { kind = "bomb", relicId = "bomb_sigil", title = "炸弹", rule = "L/T5消", damage = "主动伤害 " .. tostring(CONFIG.bombDamage), desc = "持久存在，再次点击/交换后触发" },
    }

    for index, item in ipairs(items) do
        local itemY = y + 54 + (index - 1) * rowH
        local iconX = x + 27
        local textX = x + 50
        local unlocked = HasRelic(item.relicId)
        local stateText = unlocked and "已解锁" or "未解锁"
        local titleColor = unlocked and { 255, 232, 178, 255 } or { 142, 142, 165, 230 }
        local detailColor = unlocked and { 255, 176, 100, 245 } or { 118, 118, 138, 220 }
        DrawToolInfoIcon(ctx, iconX, itemY + 22, item.kind)
        DrawText(ctx, textX, itemY, 14, item.title .. "  " .. stateText, titleColor, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        DrawText(ctx, textX, itemY + 20, 12, item.rule .. " / " .. item.damage, detailColor, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        DrawText(ctx, textX, itemY + 38, 11, item.desc, { 205, 178, 150, unlocked and 225 or 125 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    end
end

function DrawLeaderboardButton(ctx)
    local btnW = 132
    local btnH = 40
    local x = screenW_ - btnW - 14
    local y = 14
    leaderboardButtonRect_ = { x = x, y = y, w = btnW, h = btnH }
    DrawRoundedPanel(ctx, x, y, btnW, btnH, { 27, 27, 58, 232 }, { 108, 92, 231, 230 })
    local label = leaderboard_.visible and "关闭排行" or "排行榜"
    DrawText(ctx, x + btnW * 0.5, y + 12, 15, label, { 33, 189, 174, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
end

function DrawActionLogButton(ctx)
    local btnW = 132
    local btnH = 34
    local x = screenW_ - btnW - 14
    local y = 100
    actionLogButtonRect_ = { x = x, y = y, w = btnW, h = btnH }
    DrawRoundedPanel(ctx, x, y, btnW, btnH, { 28, 33, 54, 232 }, { 255, 176, 70, 225 })
    local label = operationLogVisible_ and "关闭记录" or "行动记录"
    DrawText(ctx, x + btnW * 0.5, y + 9, 13, label, { 255, 220, 130, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
end

function DrawConfigButton(ctx)
    local btnW = 132
    local btnH = 34
    local x = screenW_ - btnW - 14
    local y = 140
    configButtonRect_ = { x = x, y = y, w = btnW, h = btnH }
    DrawRoundedPanel(ctx, x, y, btnW, btnH, { 30, 38, 58, 232 }, { 80, 230, 255, 220 })
    DrawText(ctx, x + btnW * 0.5, y + 9, 13, "数值配置", { 160, 245, 255, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
end

function DrawTestUnlockButton(ctx)
    local btnW = 132
    local btnH = 34
    local x = screenW_ - btnW - 14
    local y = 180
    testUnlockButtonRect_ = { x = x, y = y, w = btnW, h = btnH }
    DrawRoundedPanel(ctx, x, y, btnW, btnH, { 42, 30, 54, 232 }, { 255, 176, 70, 225 })
    DrawText(ctx, x + btnW * 0.5, y + 9, 13, "解锁道具", { 255, 220, 130, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
end

function WrapTextByChars(text, maxChars)
    local lines = {}
    local current = ""
    local currentCount = 0
    local limit = math.max(1, maxChars or 20)
    for _, code in utf8.codes(tostring(text or "")) do
        local char = utf8.char(code)
        current = current .. char
        currentCount = currentCount + 1
        if currentCount >= limit then
            table.insert(lines, current)
            current = ""
            currentCount = 0
        end
    end
    if current ~= "" or #lines == 0 then
        table.insert(lines, current)
    end
    return lines
end

function BuildOperationLogDisplayRows(maxChars)
    local rows = {}
    for index, item in ipairs(operationLog_) do
        local lines = WrapTextByChars(item.text or "", maxChars)
        for lineIndex, line in ipairs(lines) do
            table.insert(rows, {
                sourceIndex = index,
                text = line,
                firstLine = lineIndex == 1,
            })
        end
    end
    return rows
end

function DrawOperationLogPanel(ctx)
    if operationLogAnim_ <= 0.01 then
        operationLogRect_ = nil
        return
    end
    local panelW = math.min(292, math.max(210, screenW_ - (boardX_ + boardPixels_) - 28))
    local targetX = screenW_ - panelW - 14
    local x = Lerp(screenW_ + 12, targetX, EaseOutCubic(operationLogAnim_))
    local maxH = math.max(150, screenH_ - 58)
    local panelH = math.min(math.max(230, boardPixels_ - 54), maxH)
    local y = boardY_ + (boardPixels_ - panelH) * 0.5
    y = Clamp(y, 64, screenH_ - panelH - 14)
    operationLogRect_ = { x = x, y = y, w = panelW, h = panelH }
    ClampOperationLogOffset()

    DrawRoundedPanel(ctx, x, y, panelW, panelH, { 22, 24, 48, 236 }, { 255, 176, 70, 215 })
    DrawText(ctx, x + panelW * 0.5, y + 12, 16, "行动记录", { 255, 205, 112, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, x + panelW * 0.5, y + 34, 11, "上下拖动查看历史", { 176, 166, 194, 225 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local rowY = y + 58
    local rowH = 21
    local maxRows = math.max(1, math.floor((panelH - 68) / rowH))
    local maxChars = math.max(8, math.floor((panelW - 64) / 11))
    local displayRows = BuildOperationLogDisplayRows(maxChars)
    operationLogDisplayRowCount_ = #displayRows
    ClampOperationLogOffset()
    local offset = operationLogOffset_ or 0
    for row = 1, maxRows do
        local index = row + offset
        local display = displayRows[index]
        local alpha = display and 235 or 90
        local bgAlpha = display and display.sourceIndex % 2 == 0 and 18 or 8
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x + 10, rowY - 3, panelW - 20, rowH - 3, 5)
        nvgFillColor(ctx, nvgRGBA(255, 215, 120, bgAlpha))
        nvgFill(ctx)
        if display ~= nil then
            local prefix = display.firstLine and string.format("%02d", display.sourceIndex) or "  "
            DrawText(ctx, x + 18, rowY, 11, prefix, { 255, 176, 90, alpha }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
            DrawText(ctx, x + 46, rowY, 11, display.text, { 226, 215, 196, alpha }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        end
        rowY = rowY + rowH
    end

    if #displayRows > maxRows then
        local trackX = x + panelW - 11
        local trackY = y + 58
        local trackH = panelH - 72
        local maxOffset = math.max(1, #displayRows - maxRows)
        local thumbH = math.max(24, trackH * maxRows / #displayRows)
        local thumbY = trackY + (trackH - thumbH) * Clamp(offset / maxOffset, 0, 1)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, trackX, trackY, 4, trackH, 2)
        nvgFillColor(ctx, nvgRGBA(255, 255, 255, 34))
        nvgFill(ctx)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, trackX, thumbY, 4, thumbH, 2)
        nvgFillColor(ctx, nvgRGBA(255, 205, 112, 190))
        nvgFill(ctx)
    end
end

function DrawLeaderboardPopup(ctx)
    if not leaderboard_.visible then
        leaderboardPopupRect_ = nil
        leaderboardCloseRect_ = nil
        return
    end

    nvgBeginPath(ctx)
    nvgRect(ctx, 0, 0, screenW_, screenH_)
    nvgFillColor(ctx, nvgRGBA(0, 0, 0, 132))
    nvgFill(ctx)

    local panelW = math.min(460, screenW_ - 42)
    local panelH = math.min(430, screenH_ - 58)
    local x = (screenW_ - panelW) * 0.5
    local y = (screenH_ - panelH) * 0.5
    leaderboardPopupRect_ = { x = x, y = y, w = panelW, h = panelH }
    leaderboardCloseRect_ = { x = x + panelW - 44, y = y + 10, w = 30, h = 30 }

    DrawRoundedPanel(ctx, x, y, panelW, panelH, { 27, 27, 58, 246 }, { 108, 92, 231, 240 })
    DrawText(ctx, x + panelW * 0.5, y + 16, 22, "TapTap 排行榜", { 33, 189, 174, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, leaderboardCloseRect_.x, leaderboardCloseRect_.y, leaderboardCloseRect_.w, leaderboardCloseRect_.h, 6)
    nvgFillColor(ctx, nvgRGBA(60, 42, 72, 235))
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(190, 126, 220, 220))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)
    DrawText(ctx, leaderboardCloseRect_.x + 15, leaderboardCloseRect_.y + 15, 16, "×", { 245, 220, 255, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)

    local userText = leaderboard_.nickname or "TapTap玩家"
    if leaderboard_.myRank then
        userText = userText .. "  #" .. tostring(leaderboard_.myRank)
    end
    DrawText(ctx, x + 24, y + 58, 13, userText, { 235, 208, 166, 245 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    DrawText(ctx, x + 24, y + 80, 12, leaderboard_.status or "", { 178, 152, 126, 230 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    DrawText(ctx, x + panelW - 24, y + 80, 12, "按 L 或点击 × 关闭", { 160, 160, 192, 225 }, NVG_ALIGN_RIGHT + NVG_ALIGN_TOP)

    local startY = y + 112
    local rowH = 29
    local maxRows = math.min(10, math.floor((panelH - 130) / rowH))
    for index = 1, maxRows do
        local entry = leaderboard_.entries[index]
        local rowY = startY + (index - 1) * rowH
        local bgAlpha = entry and entry.isMe and 82 or (index % 2 == 0 and 30 or 14)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x + 18, rowY - 3, panelW - 36, rowH - 4, 7)
        nvgFillColor(ctx, nvgRGBA(255, 200, 92, bgAlpha))
        nvgFill(ctx)

        if entry then
            DrawText(ctx, x + 30, rowY, 13, "#" .. tostring(entry.rank), { 255, 216, 120, 250 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
            local name = entry.nickname or "TapTap玩家"
            if string.len(name) > 24 then
                name = string.sub(name, 1, 24) .. "..."
            end
            DrawText(ctx, x + 82, rowY, 13, name, { 230, 210, 184, 250 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
            DrawText(ctx, x + panelW - 30, rowY, 13, tostring(entry.score), { 255, 176, 100, 250 }, NVG_ALIGN_RIGHT + NVG_ALIGN_TOP)
        else
            DrawText(ctx, x + 30, rowY, 13, "#" .. tostring(index), { 110, 92, 78, 170 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        end
    end
end

function BoardHudPoint3D(row, col, height)
    if WorldToHudPoint3D == nil then return nil end
    local pos = BoardToWorld(row, col)
    return WorldToHudPoint3D(Vector3(pos.x, CONFIG.visual3D.floorY + (height or 0.35), pos.z))
end

function ItemHudPoint3D(row, col, height)
    return BoardHudPoint3D(row, col, height or 0.95)
end

function DrawItemTurnBadgeUI(ctx, row, col, turns, color)
    local p = ItemHudPoint3D(row, col, 1.08)
    if p == nil then return end
    local r = 14
    nvgBeginPath(ctx)
    nvgCircle(ctx, p.x, p.y, r + 3)
    nvgFillColor(ctx, nvgRGBA(10, 6, 4, 185))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgCircle(ctx, p.x, p.y, r)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], 225))
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(255, 236, 154, 235))
    nvgStrokeWidth(ctx, 1.7)
    nvgStroke(ctx)
    DrawText(ctx, p.x, p.y, 18, tostring(math.max(0, turns or 0)), { 40, 20, 8, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
end

function DrawItemTurnBadgesUI(ctx)
    for _, trap in ipairs(traps_) do
        if trap.turns ~= nil then
            local color = { 255, 207, 92 }
            DrawItemTurnBadgeUI(ctx, trap.row, trap.col, trap.turns, color)
        end
    end
    for _, silo in ipairs(missileSilos_) do
        DrawItemTurnBadgeUI(ctx, silo.row, silo.col, silo.turnsLeft or 0, { 255, 138, 50 })
    end
end

function DrawItemAimLineUI(ctx, fromRow, fromCol, targetRow, targetCol, color)
    local from = ItemHudPoint3D(fromRow, fromCol, 0.62)
    if from == nil then return end
    local target = nil
    if targetRow ~= nil and targetCol ~= nil then
        target = BoardHudPoint3D(targetRow, targetCol, 0.36)
    end
    if target == nil then return end
    local pulse = 0.5 + 0.5 * math.sin(time_ * 7.5)
    local alpha = math.floor(150 + pulse * 90)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, from.x, from.y)
    nvgLineTo(ctx, target.x, target.y)
    nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], math.floor(alpha * 0.32)))
    nvgStrokeWidth(ctx, 7.0)
    nvgStroke(ctx)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, from.x, from.y)
    nvgLineTo(ctx, target.x, target.y)
    nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha))
    nvgStrokeWidth(ctx, 2.4 + pulse * 1.2)
    nvgStroke(ctx)
    nvgBeginPath(ctx)
    nvgCircle(ctx, target.x, target.y, 10 + pulse * 4)
    nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)
end

function DrawLaserAimLineUI(ctx, trap)
    local startPoint = nil
    local endPoint = nil
    if trap.kind == "laserH" then
        startPoint = BoardHudPoint3D(trap.row, 1, CONFIG.visual3D.runeHeight * 0.72)
        endPoint = BoardHudPoint3D(trap.row, BOARD_SIZE, CONFIG.visual3D.runeHeight * 0.72)
    else
        startPoint = BoardHudPoint3D(1, trap.col, CONFIG.visual3D.runeHeight * 0.72)
        endPoint = BoardHudPoint3D(BOARD_SIZE, trap.col, CONFIG.visual3D.runeHeight * 0.72)
    end
    if startPoint == nil or endPoint == nil then return end
    local pulse = 0.5 + 0.5 * math.sin(time_ * 8.5)
    local alpha = math.floor(155 + pulse * 85)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, startPoint.x, startPoint.y)
    nvgLineTo(ctx, endPoint.x, endPoint.y)
    nvgStrokeColor(ctx, nvgRGBA(64, 210, 255, math.floor(alpha * 0.32)))
    nvgStrokeWidth(ctx, 7.0)
    nvgStroke(ctx)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, startPoint.x, startPoint.y)
    nvgLineTo(ctx, endPoint.x, endPoint.y)
    nvgStrokeColor(ctx, nvgRGBA(64, 210, 255, alpha))
    nvgStrokeWidth(ctx, 2.2 + pulse * 1.4)
    nvgStroke(ctx)
    if trap.targetRow ~= nil and trap.targetCol ~= nil then
        local target = BoardHudPoint3D(trap.targetRow, trap.targetCol, CONFIG.visual3D.runeHeight * 0.72)
        if target ~= nil then
            nvgBeginPath(ctx)
            nvgCircle(ctx, target.x, target.y, 12 + pulse * 5)
            nvgStrokeColor(ctx, nvgRGBA(96, 235, 255, 235))
            nvgStrokeWidth(ctx, 2.4)
            nvgStroke(ctx)
        end
    end
end

function DrawBombWarningAreasUI(ctx)
    for _, trap in ipairs(traps_) do
        if trap.kind == "bomb" then
            local points = {}
            for row = trap.row - CONFIG.bombRadius, trap.row + CONFIG.bombRadius do
                for col = trap.col - CONFIG.bombRadius, trap.col + CONFIG.bombRadius do
                    if IsValidCell(row, col) then
                        local p = BoardHudPoint3D(row, col, CONFIG.visual3D.runeHeight * 0.2)
                        if p ~= nil then
                            table.insert(points, p)
                        end
                    end
                end
            end
            local pulse = 0.5 + 0.5 * math.sin(time_ * 5.2)
            for _, p in ipairs(points) do
                nvgBeginPath(ctx)
                nvgRoundedRect(ctx, p.x - 23, p.y - 15, 46, 30, 5)
                nvgFillColor(ctx, nvgRGBA(255, 42, 32, 38 + math.floor(pulse * 34)))
                nvgFill(ctx)
                nvgStrokeColor(ctx, nvgRGBA(255, 70, 44, 100 + math.floor(pulse * 80)))
                nvgStrokeWidth(ctx, 1.5)
                nvgStroke(ctx)
            end
        end
    end
end

function DrawItemAimLinesUI(ctx)
    for _, trap in ipairs(traps_) do
        if trap.kind == "laserH" or trap.kind == "laserV" then
            DrawLaserAimLineUI(ctx, trap)
        elseif trap.kind == "turret" then
            DrawItemAimLineUI(ctx, trap.row, trap.col, trap.targetRow, trap.targetCol, { 255, 218, 86 })
        end
    end
end

function DrawMonsterHealthBar(ctx, monster, entry)
    if camera3D_ == nil or entry == nil or entry.node == nil then return end
    local worldPos = entry.node.worldPosition + Vector3(0, 1.05, 0)
    local screenPos = camera3D_:WorldToScreenPoint(worldPos)
    if screenPos.x < -0.1 or screenPos.x > 1.1 or screenPos.y < -0.1 or screenPos.y > 1.1 then return end

    local rate = Clamp(monster.hp / math.max(1, monster.maxHp), 0, 1)
    local bufferRate = Clamp((monster.hpBuffer or monster.hp) / math.max(1, monster.maxHp), 0, 1)
    local barW = Clamp(64 / math.max(0.65, dpr_), 44, 76)
    local barH = 8
    local x = screenPos.x * screenW_ - barW * 0.5
    local y = screenPos.y * screenH_ - 18

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x - 2, y - 2, barW + 4, barH + 4, 5)
    nvgFillColor(ctx, nvgRGBA(12, 8, 8, 190))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, barW, barH, 4)
    nvgFillColor(ctx, nvgRGBA(45, 14, 14, 235))
    nvgFill(ctx)
    if bufferRate > rate then
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x, y, barW * bufferRate, barH, 4)
        nvgFillColor(ctx, nvgRGBA(255, 186, 70, 210))
        nvgFill(ctx)
    end
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, barW * rate, barH, 4)
    nvgFillColor(ctx, nvgRGBA(235, 48, 42, 245))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, barW, barH, 4)
    nvgStrokeColor(ctx, nvgRGBA(255, 190, 120, 210))
    nvgStrokeWidth(ctx, 1.2)
    nvgStroke(ctx)
end

function GetHeroHealthSegments(maxHp)
    local baseHp = math.max(1, CONFIG.heroMaxHp or 24)
    local ratio = Clamp((maxHp or baseHp) / baseHp, 1, 2)
    return math.floor(5 + (ratio - 1) * 5 + 0.5)
end

function DrawHeroHealthBar(ctx)
    if camera3D_ == nil or heroNode3D_ == nil or hero_ == nil then return end
    local worldPos = heroNode3D_.worldPosition + Vector3(0, 2.35, 0)
    local screenPos = camera3D_:WorldToScreenPoint(worldPos)
    if screenPos.x < -0.1 or screenPos.x > 1.1 or screenPos.y < -0.1 or screenPos.y > 1.1 then return end

    local maxHp = math.max(1, hero_.maxHp or 1)
    local rate = Clamp(hero_.hp / maxHp, 0, 1)
    local bufferRate = Clamp((hero_.hpBuffer or hero_.hp) / maxHp, 0, 1)
    local barW = Clamp(92 / math.max(0.65, dpr_), 64, 112)
    local barH = 10
    local x = screenPos.x * screenW_ - barW * 0.5
    local y = screenPos.y * screenH_ - 18

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x - 2, y - 2, barW + 4, barH + 4, 6)
    nvgFillColor(ctx, nvgRGBA(6, 18, 10, 205))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, barW, barH, 5)
    nvgFillColor(ctx, nvgRGBA(18, 42, 24, 238))
    nvgFill(ctx)
    if bufferRate > rate then
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x, y, barW * bufferRate, barH, 5)
        nvgFillColor(ctx, nvgRGBA(170, 238, 98, 195))
        nvgFill(ctx)
    end
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, barW * rate, barH, 5)
    nvgFillColor(ctx, nvgRGBA(64, 224, 98, 248))
    nvgFill(ctx)

    local segments = GetHeroHealthSegments(maxHp)
    for i = 1, segments - 1 do
        local sx = x + barW * i / segments
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, sx, y + 1)
        nvgLineTo(ctx, sx, y + barH - 1)
        nvgStrokeColor(ctx, nvgRGBA(4, 24, 10, 150))
        nvgStrokeWidth(ctx, 1)
        nvgStroke(ctx)
    end

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, barW, barH, 5)
    nvgStrokeColor(ctx, nvgRGBA(180, 255, 165, 225))
    nvgStrokeWidth(ctx, 1.3)
    nvgStroke(ctx)
end

function DrawMonsterHealthBars(ctx)
    for index, monster in ipairs(monsters_) do
        if monster.hp > 0 then
            DrawMonsterHealthBar(ctx, monster, monsterNodes3D_[index])
        end
    end
end

function ResolveItemEffectPoints(effect)
    if effect == nil then return nil, nil, nil end
    local height = CONFIG.visual3D.runeHeight * 0.72
    if effect.kind == "laserH" then
        return BoardHudPoint3D(effect.row, 1, height), BoardHudPoint3D(effect.row, BOARD_SIZE, height), BoardHudPoint3D(effect.targetRow, effect.targetCol, height)
    elseif effect.kind == "laserV" then
        return BoardHudPoint3D(1, effect.col, height), BoardHudPoint3D(BOARD_SIZE, effect.col, height), BoardHudPoint3D(effect.targetRow, effect.targetCol, height)
    elseif effect.kind == "turret" then
        return ItemHudPoint3D(effect.row, effect.col, 0.62), BoardHudPoint3D(effect.targetRow, effect.targetCol, 0.36), BoardHudPoint3D(effect.targetRow, effect.targetCol, 0.36)
    elseif effect.kind == "missile" or effect.kind == "missileSilo" then
        return ItemHudPoint3D(effect.row, effect.col, 0.62), BoardHudPoint3D(effect.targetRow, effect.targetCol, 0.36), BoardHudPoint3D(effect.targetRow, effect.targetCol, 0.36)
    end
    local fallbackFrom = { x = effect.x, y = effect.y }
    local fallbackTo = { x = effect.tx, y = effect.ty }
    return fallbackFrom, fallbackTo, fallbackTo
end

function DrawItemTriggerEffects(ctx)
    for _, effect in ipairs(itemTriggerEffects_) do
        local t = Clamp(effect.life / effect.maxLife, 0, 1)
        local progress = 1 - t
        local alpha = math.floor(230 * t)
        local pulse = math.sin(progress * math.pi)
        local color = { 255, 210, 92, alpha }
        if effect.kind == "laserH" or effect.kind == "laserV" then
            color = { 255, 32, 28, alpha }
        elseif effect.kind == "turret" then
            color = { 255, 214, 106, alpha }
        elseif effect.kind == "missile" or effect.kind == "missileSilo" then
            color = { 255, 136, 48, alpha }
        elseif effect.kind == "bomb" then
            color = { 255, 82, 46, alpha }
        end

        local from, to, target = ResolveItemEffectPoints(effect)
        if from ~= nil and to ~= nil then
            local ringR = tile_ * (0.28 + progress * 0.58)
            nvgBeginPath(ctx)
            nvgCircle(ctx, from.x, from.y, ringR)
            nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], color[4]))
            nvgStrokeWidth(ctx, 2.5 + pulse * 2.2)
            nvgStroke(ctx)

            if effect.kind == "bomb" then
                for i = 1, 12 do
                    local angle = i * math.pi * 2 / 12 + progress * 1.8
                    local inner = tile_ * 0.22
                    local outer = tile_ * (0.74 + progress * 0.65)
                    nvgBeginPath(ctx)
                    nvgMoveTo(ctx, from.x + math.cos(angle) * inner, from.y + math.sin(angle) * inner)
                    nvgLineTo(ctx, from.x + math.cos(angle) * outer, from.y + math.sin(angle) * outer)
                    nvgStrokeColor(ctx, nvgRGBA(255, 190, 78, math.floor(alpha * 0.82)))
                    nvgStrokeWidth(ctx, 2)
                    nvgStroke(ctx)
                end
            else
                local headX = Lerp(from.x, to.x, progress)
                local headY = Lerp(from.y, to.y, progress)
                local width = effect.kind == "turret" and 3.5 or ((effect.kind == "laserH" or effect.kind == "laserV") and 5.2 or 2.4)
                nvgBeginPath(ctx)
                nvgMoveTo(ctx, from.x, from.y)
                nvgLineTo(ctx, headX, headY)
                nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], math.floor(alpha * 0.72)))
                nvgStrokeWidth(ctx, width)
                nvgStroke(ctx)
                nvgBeginPath(ctx)
                nvgCircle(ctx, headX, headY, tile_ * (0.11 + pulse * 0.13))
                nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha))
                nvgFill(ctx)
                if target ~= nil and (effect.kind == "laserH" or effect.kind == "laserV") then
                    nvgBeginPath(ctx)
                    nvgCircle(ctx, target.x, target.y, 12 + pulse * 5)
                    nvgStrokeColor(ctx, nvgRGBA(255, 38, 30, math.floor(alpha * 0.95)))
                    nvgStrokeWidth(ctx, 2.4)
                    nvgStroke(ctx)
                end
            end
        end
    end
end

function DrawHudDamageParticles(ctx)
    for _, p in ipairs(hudDamageParticles_) do
        local alpha = math.floor(Clamp(p.life / p.maxLife, 0, 1) * 230)
        nvgBeginPath(ctx)
        nvgCircle(ctx, p.x, p.y, p.size)
        nvgFillColor(ctx, nvgRGBA(235, 28, 36, alpha))
        nvgFill(ctx)
    end
end

function DrawHud(ctx)
    local panelW = math.min(boardPixels_ + 24, screenW_ - 28)
    local panelX = (screenW_ - panelW) * 0.5
    local panelY = 8
    DrawRoundedPanel(ctx, panelX, panelY, panelW, 38, { 27, 27, 58, 230 }, { 33, 189, 174, 210 })

    local hpRate = Clamp(hero_.hp / hero_.maxHp, 0, 1)
    local hpBufferRate = Clamp((hero_.hpBuffer or hero_.hp) / hero_.maxHp, 0, 1)
    local hpW = math.min(280, panelW * 0.48)
    local hpH = 16
    local hpX = panelX + (panelW - hpW) * 0.5
    local hpY = panelY + 11
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, hpX - 2, hpY - 2, hpW + 4, hpH + 4, 5)
    nvgFillColor(ctx, nvgRGBA(8, 7, 16, 255))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, hpX, hpY, hpW, hpH, 4)
    nvgFillColor(ctx, nvgRGBA(18, 42, 24, 255))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, hpX, hpY, hpW * hpBufferRate, hpH, 4)
    nvgFillColor(ctx, nvgRGBA(170, 238, 98, 215))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, hpX, hpY, hpW * hpRate, hpH, 4)
    nvgFillColor(ctx, nvgRGBA(64, 224, 98, 255))
    nvgFill(ctx)
    local hpSegments = GetHeroHealthSegments(hero_.maxHp)
    for i = 1, hpSegments - 1 do
        local sx = hpX + hpW * i / hpSegments
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, sx, hpY + 1)
        nvgLineTo(ctx, sx, hpY + hpH - 1)
        nvgStrokeColor(ctx, nvgRGBA(4, 24, 10, 145))
        nvgStrokeWidth(ctx, 1)
        nvgStroke(ctx)
    end
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, hpX, hpY, hpW, hpH, 4)
    nvgStrokeColor(ctx, nvgRGBA(180, 255, 165, 185))
    nvgStrokeWidth(ctx, 1.4)
    nvgStroke(ctx)
    DrawText(ctx, panelX + 58, panelY + 10, 14, "波次 " .. tostring(wave_), { 33, 189, 174, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, screenW_ * 0.5, hpY + hpH * 0.5, 12, "生命 " .. tostring(hero_.hp) .. "/" .. tostring(hero_.maxHp), { 240, 240, 240, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    DrawText(ctx, panelX + panelW - 66, panelY + 10, 14, "分数 " .. tostring(score_), { 255, 217, 61, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local hintAlpha = messageTimer_ > 0 and 235 or 170
    local tipText = message_ or ""
    local tipW = math.min(screenW_ - 32, math.max(boardPixels_ * 0.72, 360))
    local tipH = 34
    local tipX = (screenW_ - tipW) * 0.5
    local tipY = boardY_ + boardPixels_ + 16
    if tipY + tipH > screenH_ - 10 then
        tipY = screenH_ - tipH - 10
    end
    DrawRoundedPanel(ctx, tipX, tipY, tipW, tipH, { 15, 15, 35, messageTimer_ > 0 and 215 or 150 }, { 33, 189, 174, messageTimer_ > 0 and 150 or 80 })
    DrawText(ctx, screenW_ * 0.5, tipY + tipH * 0.5, 14, tipText, { 242, 218, 178, hintAlpha }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    local relicText = GetRelicSummaryText()
    DrawText(ctx, panelX + panelW * 0.5, panelY + 47, 11, relicText, { 190, 176, 220, 215 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawToolInfoPanel(ctx)
    DrawLeaderboardButton(ctx)
    DrawActionLogButton(ctx)
    DrawConfigButton(ctx)
    DrawTestUnlockButton(ctx)
    DrawOperationLogPanel(ctx)
end

function DrawRogueRewardPopup(ctx)
    if roguelike_ == nil or not roguelike_.rewardVisible then return end
    nvgBeginPath(ctx)
    nvgRect(ctx, 0, 0, screenW_, screenH_)
    nvgFillColor(ctx, nvgRGBA(0, 0, 0, 168))
    nvgFill(ctx)

    local panelW = math.min(760, screenW_ - 42)
    local panelH = math.min(430, screenH_ - 48)
    local x = (screenW_ - panelW) * 0.5
    local y = (screenH_ - panelH) * 0.5
    roguelike_.rewardPanelRect = { x = x, y = y, w = panelW, h = panelH }
    roguelike_.rewardOptionRects = {}

    DrawRoundedPanel(ctx, x, y, panelW, panelH, { 25, 20, 45, 248 }, { 255, 196, 82, 240 })
    DrawText(ctx, screenW_ * 0.5, y + 22, 28, "波次奖励", { 255, 220, 128, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, screenW_ * 0.5, y + 61, 14, "选择 1 个奖励后进入下一波", { 205, 190, 220, 235 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local count = #roguelike_.rewardOptions
    local gap = 16
    local cardW = (panelW - 48 - gap * math.max(0, count - 1)) / math.max(1, count)
    local cardH = panelH - 128
    local cardY = y + 98

    for index, option in ipairs(roguelike_.rewardOptions) do
        local cardX = x + 24 + (index - 1) * (cardW + gap)
        local rect = { x = cardX, y = cardY, w = cardW, h = cardH }
        roguelike_.rewardOptionRects[index] = rect

        local border = { 112, 220, 255, 230 }
        local tagColor = { 112, 220, 255, 255 }
        if option.type == "relic" then
            border = { 255, 196, 82, 240 }
            tagColor = { 255, 220, 128, 255 }
        elseif option.type == "buff" then
            border = { 108, 210, 126, 230 }
            tagColor = { 134, 238, 156, 255 }
        else
            border = { 166, 132, 255, 230 }
            tagColor = { 190, 162, 255, 255 }
        end

        DrawRoundedPanel(ctx, cardX, cardY, cardW, cardH, { 35, 32, 62, 242 }, border)
        DrawText(ctx, cardX + cardW * 0.5, cardY + 16, 13, option.rarity or option.type, tagColor, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        DrawText(ctx, cardX + cardW * 0.5, cardY + 48, 17, option.title or "奖励", { 255, 238, 200, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        DrawText(ctx, cardX + cardW * 0.5, cardY + 82, 14, option.subtitle or "", { 255, 178, 104, 245 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

        local lines = WrapTextByChars(option.description or "", math.max(8, math.floor((cardW - 28) / 13)))
        local textY = cardY + 126
        for lineIndex, line in ipairs(lines) do
            if lineIndex > 5 then break end
            DrawText(ctx, cardX + cardW * 0.5, textY, 12, line, { 214, 204, 224, 235 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
            textY = textY + 22
        end

        local btnW = math.min(150, cardW - 34)
        local btnH = 34
        local btnX = cardX + (cardW - btnW) * 0.5
        local btnY = cardY + cardH - 52
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, btnX, btnY, btnW, btnH, 8)
        nvgFillColor(ctx, nvgRGBA(tagColor[1], tagColor[2], tagColor[3], 216))
        nvgFill(ctx)
        nvgStrokeColor(ctx, nvgRGBA(255, 255, 255, 95))
        nvgStrokeWidth(ctx, 1.2)
        nvgStroke(ctx)
        DrawText(ctx, btnX + btnW * 0.5, btnY + btnH * 0.5, 15, "选择", { 18, 14, 24, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    end
end

function DrawTurnBanner(ctx)
    if turnBanner_ == nil then return end
    local maxLife = math.max(0.001, turnBanner_.maxLife or 1.28)
    local elapsed = maxLife - (turnBanner_.life or 0)
    local t = Clamp(elapsed / maxLife, 0, 1)
    local enterT = Clamp(t / 0.28, 0, 1)
    local exitT = Clamp((t - 0.62) / 0.38, 0, 1)
    local easedIn = EaseOutCubic(enterT)
    local easedOut = exitT * exitT * (3 - 2 * exitT)

    local y = screenH_ * 0.28
    local x = Lerp(-screenW_ * 0.32, screenW_ * 0.5, easedIn)
    x = Lerp(x, screenW_ * 1.32, easedOut)
    local alpha = math.floor(255 * Clamp(math.min(enterT * 1.4, (1 - exitT) * 1.35), 0, 1))
    if alpha <= 0 then return end

    local isMonster = turnBanner_.kind == "monster"
    local mainColor = isMonster and { 255, 86, 72, alpha } or { 90, 230, 255, alpha }
    local glowColor = isMonster and { 255, 44, 36, math.floor(alpha * 0.34) } or { 33, 189, 174, math.floor(alpha * 0.34) }
    local panelColor = isMonster and { 56, 18, 28, math.floor(alpha * 0.76) } or { 18, 38, 58, math.floor(alpha * 0.76) }
    local panelW = math.min(360, screenW_ * 0.54)
    local panelH = 72

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x - panelW * 0.5, y - panelH * 0.5, panelW, panelH, 16)
    nvgFillColor(ctx, nvgRGBA(panelColor[1], panelColor[2], panelColor[3], panelColor[4]))
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(mainColor[1], mainColor[2], mainColor[3], math.floor(alpha * 0.62)))
    nvgStrokeWidth(ctx, 2.4)
    nvgStroke(ctx)

    local glow = nvgLinearGradient(ctx, x - panelW * 0.5, y, x + panelW * 0.5, y,
        nvgRGBA(glowColor[1], glowColor[2], glowColor[3], 0),
        nvgRGBA(glowColor[1], glowColor[2], glowColor[3], glowColor[4]))
    nvgBeginPath(ctx)
    nvgRect(ctx, x - panelW * 0.58, y - panelH * 0.72, panelW * 1.16, panelH * 1.44)
    nvgFillPaint(ctx, glow)
    nvgFill(ctx)

    DrawText(ctx, x + 3, y + 3, 34, turnBanner_.text or "", { 0, 0, 0, math.floor(alpha * 0.62) }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    DrawText(ctx, x, y, 34, turnBanner_.text or "", mainColor, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
end

function DrawNumberConfigPopup(ctx)
    if not numberConfig_.visible then return end
    nvgBeginPath(ctx)
    nvgRect(ctx, 0, 0, screenW_, screenH_)
    nvgFillColor(ctx, nvgRGBA(0, 0, 0, 145))
    nvgFill(ctx)

    local panelW = math.min(720, screenW_ - 46)
    local panelH = math.min(620, screenH_ - 46)
    local x = (screenW_ - panelW) * 0.5
    local y = (screenH_ - panelH) * 0.5
    DrawRoundedPanel(ctx, x, y, panelW, panelH, { 22, 26, 48, 248 }, { 80, 230, 255, 235 })
    DrawText(ctx, x + panelW * 0.5, y + 16, 24, "数值配置", { 160, 245, 255, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, x + panelW * 0.5, y + 48, 12, "点击 +/- 调节，确定后重新开始游戏", { 210, 220, 230, 230 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    numberConfig_.closeRect = { x = x + panelW - 44, y = y + 12, w = 30, h = 30 }
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, numberConfig_.closeRect.x, numberConfig_.closeRect.y, 30, 30, 6)
    nvgFillColor(ctx, nvgRGBA(58, 42, 66, 235))
    nvgFill(ctx)
    DrawText(ctx, numberConfig_.closeRect.x + 15, numberConfig_.closeRect.y + 15, 18, "×", { 255, 205, 220, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)

    numberConfig_.rects = {}
    local cols = panelW >= 620 and 2 or 1
    local listY = y + 78
    local rowH = 32
    local colW = (panelW - 42) / cols
    local fields = numberConfig_.fields or {}
    local maxRows = math.floor((panelH - 148) / rowH)
    for index, field in ipairs(fields) do
        local col = ((index - 1) % cols)
        local row = math.floor((index - 1) / cols)
        if row >= maxRows then break end
        local fx = x + 20 + col * colW
        local fy = listY + row * rowH
        local minus = { x = fx + colW - 122, y = fy + 3, w = 24, h = 24 }
        local plus = { x = fx + colW - 30, y = fy + 3, w = 24, h = 24 }
        numberConfig_.rects[index] = { minus = minus, plus = plus }
        DrawText(ctx, fx, fy + 7, 12, field.label, { 232, 230, 218, 245 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, minus.x, minus.y, minus.w, minus.h, 5)
        nvgFillColor(ctx, nvgRGBA(86, 58, 72, 235))
        nvgFill(ctx)
        DrawText(ctx, minus.x + 12, minus.y + 12, 16, "-", { 255, 220, 180, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        local valueText = tostring(numberConfig_.draft[field.key] or 0)
        DrawText(ctx, fx + colW - 72, fy + 7, 12, valueText, { 160, 245, 255, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, plus.x, plus.y, plus.w, plus.h, 5)
        nvgFillColor(ctx, nvgRGBA(58, 86, 72, 235))
        nvgFill(ctx)
        DrawText(ctx, plus.x + 12, plus.y + 12, 16, "+", { 210, 255, 210, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    end

    numberConfig_.confirmRect = { x = x + panelW * 0.5 - 82, y = y + panelH - 54, w = 164, h = 38 }
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, numberConfig_.confirmRect.x, numberConfig_.confirmRect.y, numberConfig_.confirmRect.w, numberConfig_.confirmRect.h, 8)
    nvgFillColor(ctx, nvgRGBA(80, 210, 160, 235))
    nvgFill(ctx)
    DrawText(ctx, x + panelW * 0.5, numberConfig_.confirmRect.y + 19, 16, "确定并重开", { 12, 28, 28, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
end

function DrawGameOver(ctx)
    if gameState_ ~= "gameover" then return end
    nvgBeginPath(ctx)
    nvgRect(ctx, 0, 0, screenW_, screenH_)
    nvgFillColor(ctx, nvgRGBA(0, 0, 0, 155))
    nvgFill(ctx)

    local w = math.min(430, screenW_ - 42)
    local h = 210
    local x = (screenW_ - w) * 0.5
    local y = (screenH_ - h) * 0.5
    DrawRoundedPanel(ctx, x, y, w, h, { 25, 14, 16, 245 }, { 190, 74, 44, 240 })
    DrawText(ctx, screenW_ * 0.5, y + 35, 34, "猎魔失败", { 255, 90, 70, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, screenW_ * 0.5, y + 88, 18, "最终分数：" .. tostring(score_) .. "    到达波次：" .. tostring(wave_), { 235, 215, 184, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, screenW_ * 0.5, y + 134, 16, "按 R 或点击棋盘重新开始", { 255, 215, 130, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
end

function HandleNanoVGRender(eventType, eventData)
    if vg_ == nil then return end
    nvgBeginFrame(vg_, screenW_, screenH_, dpr_)
    DrawItemAimLinesUI(vg_)
    DrawItemTriggerEffects(vg_)
    DrawCannonShells(vg_)
    DrawEffects(vg_)
    DrawHeroHealthBar(vg_)
    DrawMonsterHealthBars(vg_)
    DrawItemTurnBadgesUI(vg_)
    DrawHud(vg_)
    DrawHudDamageParticles(vg_)
    DrawTurnBanner(vg_)
    DrawLeaderboardPopup(vg_)
    DrawRogueRewardPopup(vg_)
    DrawNumberConfigPopup(vg_)
    DrawGameOver(vg_)
    nvgEndFrame(vg_)
end
