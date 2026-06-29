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
    nvgRoundedRect(ctx, x, y, w, h, 14)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], color[4] or 255))
    nvgFill(ctx)
    if borderColor then
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x, y, w, h, 14)
        nvgStrokeColor(ctx, nvgRGBA(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 255))
        nvgStrokeWidth(ctx, 2)
        nvgStroke(ctx)
    end
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

    if anim.kind == "swap" then
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
        DrawTurnBadge(ctx, cx, cy, trap.turns or 0)
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
        nvgBeginPath(ctx)
        nvgRect(ctx, cx - tile_ * 1.5, cy - tile_ * 1.5, tile_ * 3, tile_ * 3)
        nvgFillColor(ctx, nvgRGBA(255, 78, 52, 26 + math.floor(pulse * 32)))
        nvgFill(ctx)
        DrawText(ctx, cx + 2, cy + 2, tile_ * 0.22, "爆", { 0, 0, 0, 150 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        DrawText(ctx, cx, cy, tile_ * 0.22, "爆", { 255, 238, 180, 240 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        DrawTurnBadge(ctx, cx, cy, trap.turns or 0)
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
        DrawTrapBase(ctx, trap)
    end

    DrawAutoAimLines(ctx)

    DrawStaticGemSymbols(ctx)

    DrawAnimatedGems(ctx)

    for _, trap in ipairs(traps_) do
        DrawTrap(ctx, trap)
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

    DrawRoundedPanel(ctx, x, y, panelW, panelH, { 21, 13, 15, 222 }, { 118, 75, 44, 205 })
    DrawText(ctx, x + panelW * 0.5, y + 14, 17, "可生成道具", { 255, 220, 138, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, x + panelW * 0.5, y + 35, 11, "按形状消除后生成", { 190, 160, 126, 220 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local items = {
        { kind = "laser", title = "激光", rule = "横/纵4消", damage = "伤害 " .. tostring(CONFIG.laserDamage), desc = "持续" .. tostring(CONFIG.laserTurns) .. "回合，整行或整列触发" },
        { kind = "turret", title = "炮台", rule = "方块4消", damage = "每回合 " .. tostring(CONFIG.turretDamage), desc = "持续" .. tostring(CONFIG.turretTurns) .. "回合瞄准最近怪物" },
        { kind = "missile", title = "导弹井", rule = "直线5消", damage = "每回合 1枚*" .. tostring(CONFIG.missileDamage), desc = "存在" .. tostring(CONFIG.missileSiloTurns) .. "回合追踪目标" },
        { kind = "bomb", title = "炸弹", rule = "L/T5消", damage = "伤害 " .. tostring(CONFIG.bombDamage), desc = "持续" .. tostring(CONFIG.bombTurns) .. "回合，触发时爆炸" },
    }

    for index, item in ipairs(items) do
        local itemY = y + 54 + (index - 1) * rowH
        local iconX = x + 27
        local textX = x + 50
        DrawToolInfoIcon(ctx, iconX, itemY + 22, item.kind)
        DrawText(ctx, textX, itemY, 14, item.title .. "  " .. item.rule, { 255, 232, 178, 255 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        DrawText(ctx, textX, itemY + 20, 12, item.damage, { 255, 176, 100, 245 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        DrawText(ctx, textX, itemY + 38, 11, item.desc, { 205, 178, 150, 225 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    end
end

function DrawLeaderboardPanel(ctx)
    local panelW = math.min(270, math.max(198, screenW_ - (boardX_ + boardPixels_) - 28))
    local x = screenW_ - panelW - 14
    local y = boardY_
    local collapsedH = 44
    if not leaderboard_.visible then
        DrawRoundedPanel(ctx, x, y, panelW, collapsedH, { 21, 13, 15, 215 }, { 118, 75, 44, 190 })
        DrawText(ctx, x + panelW * 0.5, y + 13, 15, "排行榜  [L]", { 255, 220, 138, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        return
    end

    local panelH = math.min(boardPixels_, 402)
    DrawRoundedPanel(ctx, x, y, panelW, panelH, { 21, 13, 15, 224 }, { 118, 75, 44, 205 })
    DrawText(ctx, x + panelW * 0.5, y + 12, 17, "TapTap 排行榜", { 255, 220, 138, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, x + panelW * 0.5, y + 34, 11, "按 L 隐藏 / 刷新", { 190, 160, 126, 220 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local userText = leaderboard_.nickname or "TapTap玩家"
    if leaderboard_.myRank then
        userText = userText .. "  #" .. tostring(leaderboard_.myRank)
    end
    DrawText(ctx, x + 14, y + 58, 12, userText, { 235, 208, 166, 240 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    DrawText(ctx, x + 14, y + 76, 11, leaderboard_.status or "", { 178, 152, 126, 220 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)

    local startY = y + 104
    local rowH = 27
    for index = 1, 10 do
        local entry = leaderboard_.entries[index]
        local rowY = startY + (index - 1) * rowH
        if rowY + rowH > y + panelH - 12 then break end
        local bgAlpha = entry and entry.isMe and 70 or (index % 2 == 0 and 24 or 12)
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, x + 10, rowY - 2, panelW - 20, rowH - 3, 6)
        nvgFillColor(ctx, nvgRGBA(255, 200, 92, bgAlpha))
        nvgFill(ctx)

        if entry then
            DrawText(ctx, x + 18, rowY, 12, "#" .. tostring(entry.rank), { 255, 216, 120, 245 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
            local name = entry.nickname or "TapTap玩家"
            if string.len(name) > 18 then
                name = string.sub(name, 1, 18) .. "..."
            end
            DrawText(ctx, x + 54, rowY, 12, name, { 230, 210, 184, 245 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
            DrawText(ctx, x + panelW - 18, rowY, 12, tostring(entry.score), { 255, 176, 100, 245 }, NVG_ALIGN_RIGHT + NVG_ALIGN_TOP)
        else
            DrawText(ctx, x + 18, rowY, 12, "#" .. tostring(index), { 110, 92, 78, 170 }, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        end
    end
end

function DrawMonsterHealthBar(ctx, monster, entry)
    if camera3D_ == nil or entry == nil or entry.node == nil then return end
    local worldPos = entry.node.worldPosition + Vector3(0, 1.05, 0)
    local screenPos = camera3D_:WorldToScreenPoint(worldPos)
    if screenPos.x < -0.1 or screenPos.x > 1.1 or screenPos.y < -0.1 or screenPos.y > 1.1 then return end

    local rate = Clamp(monster.hp / math.max(1, monster.maxHp), 0, 1)
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

function DrawMonsterHealthBars(ctx)
    for index, monster in ipairs(monsters_) do
        if monster.hp > 0 then
            DrawMonsterHealthBar(ctx, monster, monsterNodes3D_[index])
        end
    end
end

function DrawItemTriggerEffects(ctx)
    for _, effect in ipairs(itemTriggerEffects_) do
        local t = Clamp(effect.life / effect.maxLife, 0, 1)
        local progress = 1 - t
        local alpha = math.floor(230 * t)
        local pulse = math.sin(progress * math.pi)
        local color = { 255, 210, 92, alpha }
        if effect.kind == "laserH" or effect.kind == "laserV" then
            color = { 96, 235, 255, alpha }
        elseif effect.kind == "turret" then
            color = { 255, 214, 106, alpha }
        elseif effect.kind == "missile" or effect.kind == "missileSilo" then
            color = { 255, 136, 48, alpha }
        elseif effect.kind == "bomb" then
            color = { 255, 82, 46, alpha }
        end

        local ringR = tile_ * (0.28 + progress * 0.58)
        nvgBeginPath(ctx)
        nvgCircle(ctx, effect.x, effect.y, ringR)
        nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], color[4]))
        nvgStrokeWidth(ctx, 2.5 + pulse * 2.2)
        nvgStroke(ctx)

        if effect.kind == "bomb" then
            for i = 1, 12 do
                local angle = i * math.pi * 2 / 12 + progress * 1.8
                local inner = tile_ * 0.22
                local outer = tile_ * (0.74 + progress * 0.65)
                nvgBeginPath(ctx)
                nvgMoveTo(ctx, effect.x + math.cos(angle) * inner, effect.y + math.sin(angle) * inner)
                nvgLineTo(ctx, effect.x + math.cos(angle) * outer, effect.y + math.sin(angle) * outer)
                nvgStrokeColor(ctx, nvgRGBA(255, 190, 78, math.floor(alpha * 0.82)))
                nvgStrokeWidth(ctx, 2)
                nvgStroke(ctx)
            end
        else
            local headX = Lerp(effect.x, effect.tx, progress)
            local headY = Lerp(effect.y, effect.ty, progress)
            nvgBeginPath(ctx)
            nvgMoveTo(ctx, effect.x, effect.y)
            nvgLineTo(ctx, headX, headY)
            nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], math.floor(alpha * 0.72)))
            nvgStrokeWidth(ctx, effect.kind == "turret" and 3.5 or 2.4)
            nvgStroke(ctx)
            nvgBeginPath(ctx)
            nvgCircle(ctx, headX, headY, tile_ * (0.11 + pulse * 0.13))
            nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha))
            nvgFill(ctx)
        end
    end
end

function DrawHud(ctx)
    DrawText(ctx, screenW_ * 0.5, 24, 28, CONFIG.title, { 255, 214, 128, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local panelW = math.min(boardPixels_ + 24, screenW_ - 28)
    local panelX = (screenW_ - panelW) * 0.5
    DrawRoundedPanel(ctx, panelX, 78, panelW, 42, { 24, 15, 18, 215 }, { 115, 72, 43, 180 })

    local hpRate = Clamp(hero_.hp / hero_.maxHp, 0, 1)
    local hpW = math.min(240, panelW * 0.45)
    local hpH = 14
    local hpX = panelX + (panelW - hpW) * 0.5
    local hpY = 93
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, hpX, hpY, hpW, hpH, 7)
    nvgFillColor(ctx, nvgRGBA(40, 16, 18, 255))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, hpX, hpY, hpW * hpRate, hpH, 7)
    nvgFillColor(ctx, nvgRGBA(190, 36, 44, 255))
    nvgFill(ctx)
    DrawText(ctx, panelX + panelW * 0.18, 91, 14, "波次 " .. tostring(wave_), { 255, 220, 145, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, screenW_ * 0.5, hpY + hpH * 0.5, 12, "生命 " .. tostring(hero_.hp) .. "/" .. tostring(hero_.maxHp), { 255, 235, 220, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    DrawText(ctx, panelX + panelW * 0.76, 91, 14, "分数 " .. tostring(score_), { 255, 220, 145, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    DrawText(ctx, panelX + panelW * 0.92, 91, 14, "步数 " .. tostring(moves_), { 255, 220, 145, 255 }, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    local hintAlpha = messageTimer_ > 0 and 235 or 170
    local tipText = message_ or ""
    local tipW = math.min(screenW_ - 32, math.max(boardPixels_ * 0.72, 360))
    local tipH = 34
    local tipX = (screenW_ - tipW) * 0.5
    local tipY = boardY_ + boardPixels_ + 16
    if tipY + tipH > screenH_ - 10 then
        tipY = screenH_ - tipH - 10
    end
    DrawRoundedPanel(ctx, tipX, tipY, tipW, tipH, { 10, 7, 8, messageTimer_ > 0 and 190 or 135 }, { 255, 206, 116, messageTimer_ > 0 and 85 or 45 })
    DrawText(ctx, screenW_ * 0.5, tipY + tipH * 0.5, 14, tipText, { 242, 218, 178, hintAlpha }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    DrawToolInfoPanel(ctx)
    DrawLeaderboardPanel(ctx)
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
    DrawItemTriggerEffects(vg_)
    DrawEffects(vg_)
    DrawMonsterHealthBars(vg_)
    DrawHud(vg_)
    DrawGameOver(vg_)
    nvgEndFrame(vg_)
end
