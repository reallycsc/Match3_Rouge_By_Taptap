local G = require "Game.Context"
local _ENV = G
---@diagnostic disable: undefined-global

function IsGemWouldMatch(row, col, gemType)
    if col >= 3 and board_[row][col - 1] == gemType and board_[row][col - 2] == gemType then
        return true
    end
    if row >= 3 and board_[row - 1][col] == gemType and board_[row - 2][col] == gemType then
        return true
    end
    return false
end

function OccupiedByActor(row, col)
    if row == hero_.row and col == hero_.col then return true end
    return HasMonsterAt(row, col)
end

function TrapAt(row, col)
    for _, trap in ipairs(traps_) do
        if not trap.triggered and trap.row == row and trap.col == col then
            return trap
        end
    end
    return nil
end

function OccupiedByMissileSilo(row, col)
    for _, silo in ipairs(missileSilos_) do
        if silo.row == row and silo.col == col then
            return true
        end
    end
    return false
end

function OccupiedByObstacle(row, col)
    return TrapAt(row, col) ~= nil or OccupiedByMissileSilo(row, col)
end

function OccupiedByBoardBlocker(row, col)
    return OccupiedByActor(row, col) or OccupiedByObstacle(row, col)
end

function FillGemAt(row, col)
    if OccupiedByBoardBlocker(row, col) then
        board_[row][col] = 0
        return
    end

    local gemType = math.random(1, GEM_TYPES)
    local guard = 0
    while IsGemWouldMatch(row, col, gemType) and guard < 30 do
        gemType = math.random(1, GEM_TYPES)
        guard = guard + 1
    end
    board_[row][col] = gemType
end

function ClearActorCells()
    if board_[hero_.row] then
        board_[hero_.row][hero_.col] = 0
    end
    for _, monster in ipairs(monsters_) do
        if monster.hp > 0 and board_[monster.row] then
            board_[monster.row][monster.col] = 0
        end
    end
end

function FillNewBoard()
    board_ = {}
    for row = 1, BOARD_SIZE do
        board_[row] = {}
        for col = 1, BOARD_SIZE do
            FillGemAt(row, col)
        end
    end
end

HasMonsterAt = function(row, col)
    for _, monster in ipairs(monsters_) do
        if monster.row == row and monster.col == col and monster.hp > 0 then
            return true
        end
    end
    return false
end

function OccupiedByMonster(row, col, ignoredIndex)
    for index, monster in ipairs(monsters_) do
        if index ~= ignoredIndex and monster.hp > 0 and monster.row == row and monster.col == col then
            return true
        end
    end
    return false
end

function SpawnMonsters()
    monsters_ = {}
    local spawnCells = {
        { row = 1, col = 1 }, { row = 1, col = 9 }, { row = 9, col = 9 }, { row = 9, col = 1 },
        { row = 1, col = 5 }, { row = 5, col = 9 }, { row = 9, col = 5 }, { row = 5, col = 1 },
        { row = 2, col = 7 }, { row = 7, col = 2 },
    }

    local targetCount = CONFIG.monsterCount + math.floor((wave_ - 1) * 0.75)
    targetCount = Clamp(targetCount, 4, CONFIG.monsterMaxCount)

    for _, cell in ipairs(spawnCells) do
        if #monsters_ >= targetCount then break end
        if not (cell.row == hero_.row and cell.col == hero_.col) and not OccupiedByObstacle(cell.row, cell.col) then
            local hp = CONFIG.baseMonsterHp + wave_ * CONFIG.monsterWaveHpBonus + math.random(0, 2)
            table.insert(monsters_, {
                row = cell.row,
                col = cell.col,
                hp = hp,
                maxHp = hp,
                attack = CONFIG.monsterAttackBase + math.floor(wave_ / CONFIG.monsterAttackPerWave),
                pulse = math.random() * 10,
            })
        end
    end
    ClearActorCells()
end

function ResetGame()
    restartCount_ = restartCount_ + 1
    math.randomseed(os.time() + restartCount_ * 7919)
    for _ = 1, restartCount_ % 11 + 3 do
        math.random()
    end
    hero_ = { row = 5, col = 5, hp = CONFIG.heroMaxHp, maxHp = CONFIG.heroMaxHp }
    selected_ = nil
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
    score_ = 0
    moves_ = 0
    wave_ = 1
    screenShake_ = 0
    isAnimating_ = false
    currentAnim_ = nil
    pendingMove_ = false
    dragStart_ = nil
    dragTriggered_ = false
    turnId_ = 0
    gameState_ = "playing"
    FillNewBoard()
    SpawnMonsters()
    ClearActorCells()
    EnsureBoardHasMove()
    SyncScene3D()
    SetMessage("符石生存开始：直线5消会部署3回合导弹井", 3.0)
    print("Game reset: board generated, monsters=" .. tostring(#monsters_))
end

function AddContiguousSameTypeCells(cells, exists, row, col, gemType)
    if not IsValidCell(row, col) or GetBoardGem(row, col) ~= gemType then return end
    local key = CellKey(row, col)
    if exists[key] then return end
    exists[key] = true
    table.insert(cells, { row = row, col = col, type = gemType })
    AddContiguousSameTypeCells(cells, exists, row - 1, col, gemType)
    AddContiguousSameTypeCells(cells, exists, row + 1, col, gemType)
    AddContiguousSameTypeCells(cells, exists, row, col - 1, gemType)
    AddContiguousSameTypeCells(cells, exists, row, col + 1, gemType)
end

function PickTriggeredMatches(matches, a, b)
    local marked = {}
    for _, cell in ipairs(matches) do
        marked[CellKey(cell.row, cell.col)] = cell
    end

    local anchors = { a, b }
    local collected = {}
    local collectedExists = {}
    local count = 0

    for _, anchor in ipairs(anchors) do
        local gemType = GetBoardGem(anchor.row, anchor.col)
        if gemType ~= 0 and marked[CellKey(anchor.row, anchor.col)] then
            local cells = {}
            local exists = {}
            AddContiguousSameTypeCells(cells, exists, anchor.row, anchor.col, gemType)
            for _, cell in ipairs(cells) do
                local key = CellKey(cell.row, cell.col)
                if marked[key] and not collectedExists[key] then
                    collectedExists[key] = true
                    table.insert(collected, cell)
                    count = count + 1
                end
            end
        end
    end
    return count, collected
end

function MapMatchedCellsToCurrentBoard(matchedCells, a, b)
    local mapped = {}
    local exists = {}
    for _, cell in ipairs(matchedCells or {}) do
        local row = cell.row
        local col = cell.col
        if row == a.row and col == a.col then
            row = b.row
            col = b.col
        elseif row == b.row and col == b.col then
            row = a.row
            col = a.col
        end
        local key = CellKey(row, col)
        if not exists[key] then
            exists[key] = true
            table.insert(mapped, { row = row, col = col, type = cell.type })
        end
    end
    return mapped
end

function EvaluateMatchDamage(matches)
    local damagedMonsters = {}
    for _, cell in ipairs(matches or {}) do
        for index, monster in ipairs(monsters_) do
            if monster.hp > 0 and IsInCrossRange(cell.row, cell.col, monster.row, monster.col, MATCH_DAMAGE_RADIUS) then
                damagedMonsters[index] = true
            end
        end
    end

    local damage = 0
    for index, shouldDamage in pairs(damagedMonsters) do
        local monster = monsters_[index]
        if shouldDamage and monster and monster.hp > 0 then
            damage = damage + math.min(#matches, monster.hp)
        end
    end
    return damage
end

function EvaluateSpecialValue(specials)
    local value = 0
    for _, special in ipairs(specials or {}) do
        if special.kind == "missileSilo" then
            value = value + 40
        elseif special.kind == "bomb" then
            value = value + 30
        elseif special.kind == "turret" then
            value = value + 20
        elseif special.kind == "laserH" or special.kind == "laserV" then
            value = value + 10
        end
    end
    return value
end

function EvaluateMoveAfterSwap(a, b)
    if OccupiedByBoardBlocker(a.row, a.col) or OccupiedByBoardBlocker(b.row, b.col) then return nil end
    if board_[a.row][a.col] == 0 or board_[b.row][b.col] == 0 then return nil end
    if board_[a.row][a.col] == board_[b.row][b.col] then return nil end

    board_[a.row][a.col], board_[b.row][b.col] = board_[b.row][b.col], board_[a.row][a.col]
    local matches, specials = FindMatches()
    local count, triggeredMatches = PickTriggeredMatches(matches, a, b)
    local damage = EvaluateMatchDamage(matches)
    local specialValue = EvaluateSpecialValue(specials)
    local mappedMatches = MapMatchedCellsToCurrentBoard(triggeredMatches, a, b)
    board_[a.row][a.col], board_[b.row][b.col] = board_[b.row][b.col], board_[a.row][a.col]
    return {
        count = count,
        damage = damage,
        specialValue = specialValue,
        matches = mappedMatches,
    }
end

function IsBetterHintCandidate(candidate, best)
    if candidate == nil or candidate.count <= 0 then return false end
    if best == nil then return true end
    if candidate.specialValue ~= best.specialValue then
        return candidate.specialValue > best.specialValue
    end
    if candidate.specialValue == 0 and candidate.damage ~= best.damage then
        return candidate.damage > best.damage
    end
    if candidate.count ~= best.count then
        return candidate.count > best.count
    end
    return false
end

function UpdateBestMoveHint()
    hintCells_ = {}
    hintScore_ = 0
    local best = nil

    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local current = { row = row, col = col }
            if IsValidCell(row, col + 1) then
                local candidate = EvaluateMoveAfterSwap(current, { row = row, col = col + 1 })
                if IsBetterHintCandidate(candidate, best) then
                    best = candidate
                end
            end
            if IsValidCell(row + 1, col) then
                local candidate = EvaluateMoveAfterSwap(current, { row = row + 1, col = col })
                if IsBetterHintCandidate(candidate, best) then
                    best = candidate
                end
            end
        end
    end

    if best then
        hintScore_ = best.count
        for _, cell in ipairs(best.matches or {}) do
            hintCells_[CellKey(cell.row, cell.col)] = true
        end
    end
end

function BoardHasAvailableMove()
    UpdateBestMoveHint()
    return hintScore_ > 0
end

function ShuffleList(items)
    for i = #items, 2, -1 do
        local j = math.random(1, i)
        items[i], items[j] = items[j], items[i]
    end
end

function AssignGemsToPlayableCells(cells, gems)
    for index, cell in ipairs(cells) do
        local gemType = gems[index] or math.random(1, GEM_TYPES)
        board_[cell.row][cell.col] = gemType
    end
    ClearActorCells()
end

function ShuffleBoardGems()
    local cells = {}
    local gems = {}
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            if not OccupiedByBoardBlocker(row, col) then
                table.insert(cells, { row = row, col = col })
                if board_[row][col] ~= 0 then
                    table.insert(gems, board_[row][col])
                end
            else
                board_[row][col] = 0
            end
        end
    end

    for attempt = 1, 60 do
        ShuffleList(gems)
        AssignGemsToPlayableCells(cells, gems)
        local matches = FindMatches()
        if #matches == 0 and BoardHasAvailableMove() then
            shuffleCount_ = shuffleCount_ + 1
            SetMessage("盘面无可用交换，已重排符石", 2.2)
            print("Board shuffled: attempt=" .. tostring(attempt) .. ", movesHint=" .. tostring(hintScore_))
            return true
        end
    end

    for attempt = 1, 60 do
        for _, cell in ipairs(cells) do
            board_[cell.row][cell.col] = math.random(1, GEM_TYPES)
        end
        ClearActorCells()
        local matches = FindMatches()
        if #matches == 0 and BoardHasAvailableMove() then
            shuffleCount_ = shuffleCount_ + 1
            SetMessage("盘面无可用交换，已生成新符石", 2.2)
            print("Board regenerated after shuffle fallback: attempt=" .. tostring(attempt))
            return true
        end
    end

    UpdateBestMoveHint()
    return false
end

function EnsureBoardStable(combo)
    if gameState_ ~= "playing" or isAnimating_ then return false end

    local matches, specials = FindMatches()
    if #matches > 0 and StartAutoClearAnimation ~= nil then
        hintCells_ = {}
        hintScore_ = 0
        SetMessage("符石爆裂，黑暗生物受到波及", 1.5)
        StartAutoClearAnimation(matches, combo or 1, specials, nil)
        return true
    end

    if not BoardHasAvailableMove() then
        ShuffleBoardGems()
        return true
    end
    return false
end

function EnsureBoardHasMove()
    EnsureBoardStable(1)
end

function AddCellUnique(cells, exists, row, col, gemType)
    local key = CellKey(row, col)
    if not exists[key] then
        exists[key] = true
        table.insert(cells, { row = row, col = col, type = gemType })
    end
end

function AddSpecialFromRun(specials, runCells, direction)
    if #runCells < 4 then return end
    if #runCells == 4 then
        table.insert(specials, { kind = direction == "horizontal" and "laserH" or "laserV", cells = runCells })
    elseif #runCells == 5 then
        table.insert(specials, { kind = "missileSilo", cells = runCells })
    elseif #runCells > 5 then
        table.insert(specials, { kind = direction == "horizontal" and "laserH" or "laserV", cells = runCells })
        table.insert(specials, { kind = "missileSilo", cells = runCells })
    end
end

function GetBoardGem(row, col)
    if row < 1 or row > BOARD_SIZE or col < 1 or col > BOARD_SIZE then return 0 end
    return board_[row][col]
end

function AddLineCellsUnique(cells, exists, row, col, dr, dc, gemType)
    local r = row
    local c = col
    while GetBoardGem(r, c) == gemType do
        AddCellUnique(cells, exists, r, c, gemType)
        r = r + dr
        c = c + dc
    end
end

function AddShapeSpecials(specials, marked)
    local usedShapes = {}
    local cellsInBomb = {}
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local gemType = GetBoardGem(row, col)
            if gemType ~= 0 then
                local cells = {}
                local exists = {}
                AddLineCellsUnique(cells, exists, row, col, 0, -1, gemType)
                AddLineCellsUnique(cells, exists, row, col + 1, 0, 1, gemType)
                local horizontalCount = #cells
                AddLineCellsUnique(cells, exists, row - 1, col, -1, 0, gemType)
                AddLineCellsUnique(cells, exists, row + 1, col, 1, 0, gemType)
                local verticalCount = #cells - horizontalCount + 1
                if horizontalCount >= 3 and verticalCount >= 3 and #cells >= 5 then
                    local key = table.concat({ row, col, gemType }, ":")
                    if not usedShapes[key] then
                        usedShapes[key] = true
                        for _, cell in ipairs(cells) do
                            local cellKey = CellKey(cell.row, cell.col)
                            marked[cellKey] = cell
                            cellsInBomb[cellKey] = true
                        end
                        table.insert(specials, { kind = "bomb", cells = cells, anchor = { row = row, col = col, type = gemType } })
                    end
                end
            end
        end
    end

    for row = 1, BOARD_SIZE - 1 do
        for col = 1, BOARD_SIZE - 1 do
            local gemType = GetBoardGem(row, col)
            if gemType ~= 0
                and GetBoardGem(row + 1, col) == gemType
                and GetBoardGem(row, col + 1) == gemType
                and GetBoardGem(row + 1, col + 1) == gemType then
                local cells = {
                    { row = row, col = col, type = gemType },
                    { row = row + 1, col = col, type = gemType },
                    { row = row, col = col + 1, type = gemType },
                    { row = row + 1, col = col + 1, type = gemType },
                }
                local overlapsBomb = false
                for _, cell in ipairs(cells) do
                    if cellsInBomb[CellKey(cell.row, cell.col)] then
                        overlapsBomb = true
                        break
                    end
                end
                if not overlapsBomb then
                    for _, cell in ipairs(cells) do
                        marked[CellKey(cell.row, cell.col)] = cell
                    end
                    table.insert(specials, { kind = "turret", cells = cells })
                end
            end
        end
    end
end

function FindMatches()
    local marked = {}
    local matches = {}
    local specials = {}

    for row = 1, BOARD_SIZE do
        local runType = board_[row][1]
        local runStart = 1
        local runLength = 1
        for col = 2, BOARD_SIZE + 1 do
            local gemType = nil
            if col <= BOARD_SIZE then gemType = board_[row][col] end
            if gemType == runType and gemType ~= 0 then
                runLength = runLength + 1
            else
                if runType ~= 0 and runLength >= 3 then
                    local runCells = {}
                    for c = runStart, col - 1 do
                        local cell = { row = row, col = c, type = runType }
                        marked[CellKey(row, c)] = cell
                        table.insert(runCells, cell)
                    end
                    AddSpecialFromRun(specials, runCells, "horizontal")
                end
                runType = gemType
                runStart = col
                runLength = 1
            end
        end
    end

    for col = 1, BOARD_SIZE do
        local runType = board_[1][col]
        local runStart = 1
        local runLength = 1
        for row = 2, BOARD_SIZE + 1 do
            local gemType = nil
            if row <= BOARD_SIZE then gemType = board_[row][col] end
            if gemType == runType and gemType ~= 0 then
                runLength = runLength + 1
            else
                if runType ~= 0 and runLength >= 3 then
                    local runCells = {}
                    for r = runStart, row - 1 do
                        local cell = { row = r, col = col, type = runType }
                        marked[CellKey(r, col)] = cell
                        table.insert(runCells, cell)
                    end
                    AddSpecialFromRun(specials, runCells, "vertical")
                end
                runType = gemType
                runStart = row
                runLength = 1
            end
        end
    end

    AddShapeSpecials(specials, marked)
    for _, cell in pairs(marked) do
        table.insert(matches, cell)
    end
    return matches, specials
end

function CopyCells(cells)
    local copy = {}
    for _, cell in ipairs(cells or {}) do
        table.insert(copy, { row = cell.row, col = cell.col, type = cell.type })
    end
    return copy
end

function GetCellsBounds(cells, fallbackRow, fallbackCol)
    local minRow = fallbackRow
    local maxRow = fallbackRow
    local minCol = fallbackCol
    local maxCol = fallbackCol
    for _, cell in ipairs(cells or {}) do
        minRow = math.min(minRow, cell.row)
        maxRow = math.max(maxRow, cell.row)
        minCol = math.min(minCol, cell.col)
        maxCol = math.max(maxCol, cell.col)
    end
    return minRow, maxRow, minCol, maxCol
end

function AddTrap(kind, row, col, cells)
    if OccupiedByActor(row, col) then return end
    local trapCells = CopyCells(cells)
    if #trapCells == 0 then
        table.insert(trapCells, { row = row, col = col })
    end
    local minRow, maxRow, minCol, maxCol = GetCellsBounds(trapCells, row, col)
    local trap = {
        kind = kind,
        row = row,
        col = col,
        cells = trapCells,
        minRow = minRow,
        maxRow = maxRow,
        minCol = minCol,
        maxCol = maxCol,
        triggered = false,
        angle = -math.pi * 0.5,
    }
    if kind == "turret" then
        trap.turns = CONFIG.turretTurns
    elseif kind == "laserH" or kind == "laserV" then
        trap.turns = CONFIG.laserTurns
    elseif kind == "bomb" then
        trap.turns = CONFIG.bombTurns
    end
    board_[row][col] = 0
    table.insert(traps_, trap)
    AddFloatText(row, col, kind == "laserH" and "横向激光" or kind == "laserV" and "纵向激光" or kind == "turret" and "炮台" or kind == "missileSilo" and "导弹井" or "炸弹", { 120, 230, 255, 255 })
end

function PickSpecialAnchor(special, preferredCells)
    for _, preferred in ipairs(preferredCells or {}) do
        for _, cell in ipairs(special.cells or {}) do
            if preferred.row == cell.row and preferred.col == cell.col then
                return cell
            end
        end
    end
    return special.anchor or special.cells[math.ceil(#special.cells * 0.5)] or special.cells[1]
end

function AddMissileSilo(row, col)
    if OccupiedByActor(row, col) then return end
    board_[row][col] = 0
    table.insert(missileSilos_, {
        row = row,
        col = col,
        armedTurn = turnId_ + 1,
        turnsLeft = CONFIG.missileSiloTurns,
        age = 0,
    })
    AddFloatText(row, col, "导弹井", { 255, 220, 120, 255 })
end

function SpawnMissileSilos(cells)
    for _, cell in ipairs(cells or {}) do
        AddMissileSilo(cell.row, cell.col)
    end
end

function FindMonsterAt(row, col)
    if row == nil or col == nil then return nil end
    for _, monster in ipairs(monsters_) do
        if monster.hp > 0 and monster.row == row and monster.col == col then
            return monster
        end
    end
    return nil
end

function FindSiloLockedTarget(silo)
    local target = FindMonsterAt(silo.targetRow, silo.targetCol)
    if target then return target end
    target = FindNearestMonster(silo)
    if target then
        silo.targetRow = target.row
        silo.targetCol = target.col
        silo.angle = math.atan(target.row - silo.row, target.col - silo.col)
    end
    return target
end

function FireMissileSilos()
    if #missileSilos_ == 0 then return false end

    local firedAny = false
    for _, silo in ipairs(missileSilos_) do
        if (silo.armedTurn or 0) <= turnId_ then
            local target = FindSiloLockedTarget(silo)
            if target then
                AddItemTriggerEffect("missile", silo.row, silo.col, target.row, target.col)
                for missileIndex = 1, CONFIG.missilesPerSiloTurn do
                    AddMissile(silo.row, silo.col, target, missileIndex)
                    DamageMonster(target, CONFIG.missileDamage, "导弹-")
                    firedAny = true
                end
            end
            silo.turnsLeft = (silo.turnsLeft or CONFIG.missileSiloTurns) - 1
        end
    end

    for i = #missileSilos_, 1, -1 do
        if (missileSilos_[i].turnsLeft or 0) <= 0 then
            table.remove(missileSilos_, i)
        end
    end

    if firedAny then
        SetMessage("导弹井发射追踪导弹", 1.8)
        RemoveDeadMonsters()
    end
    if firedAny and StartEnemyDropAnimation ~= nil then
        local drops = DropAndRefillBoard()
        return StartEnemyDropAnimation(drops, 0)
    end
    return firedAny
end

function SpawnSpecialTraps(specials, preferredCells)
    for _, special in ipairs(specials) do
        if special.kind == "missileSilo" then
            SpawnMissileSilos(special.cells)
        else
            local anchor = PickSpecialAnchor(special, preferredCells)
            if anchor then
                AddTrap(special.kind, anchor.row, anchor.col, special.cells)
            end
        end
    end
end

function RemoveDeadMonsters()
    local removedAny = false
    for i = #monsters_, 1, -1 do
        local monster = monsters_[i]
        if monster.hp <= 0 then
            AddFloatText(monster.row, monster.col, "击杀", { 255, 210, 80, 255 })
            AddParticles(monster.row, monster.col, { 255, 64, 36, 255 }, 24)
            score_ = score_ + CONFIG.killScore + wave_ * CONFIG.killScorePerWave
            table.remove(monsters_, i)
            removedAny = true
        end
    end

    if #monsters_ == 0 and gameState_ == "playing" then
        wave_ = wave_ + 1
        hero_.hp = Clamp(hero_.hp + CONFIG.heroHealPerWave, 0, hero_.maxHp)
        SpawnMonsters()
        SetMessage("新的恶魔潮涌入棋盘。主角恢复 " .. tostring(CONFIG.heroHealPerWave) .. " 点生命", 2.5)
        print("Next wave: " .. tostring(wave_) .. ", monsters=" .. tostring(#monsters_))
    end
    return removedAny
end

function ApplyMatchDamage(matches, combo, specials, preferredCells)
    SpawnSpecialTraps(specials or {}, preferredCells)
    local damagedMonsters = {}
    local matchedCount = #matches

    for _, cell in ipairs(matches) do
        table.insert(matchEffects_, { row = cell.row, col = cell.col, life = 0.35, maxLife = 0.35, type = cell.type })
        AddParticles(cell.row, cell.col, GEM_COLORS[cell.type], 5)

        for index, monster in ipairs(monsters_) do
            if monster.hp > 0 and IsInCrossRange(cell.row, cell.col, monster.row, monster.col, MATCH_DAMAGE_RADIUS) then
                damagedMonsters[index] = true
            end
        end
    end

    local anyDamage = false
    for index, shouldDamage in pairs(damagedMonsters) do
        local monster = monsters_[index]
        if shouldDamage and monster and monster.hp > 0 then
            local finalDamage = matchedCount
            monster.hp = monster.hp - finalDamage
            anyDamage = true
            AddFloatText(monster.row, monster.col, "-" .. tostring(finalDamage), { 255, 80, 60, 255 })
            AddParticles(monster.row, monster.col, { 255, 80, 42, 255 }, 12)
            print("Monster damaged: index=" .. tostring(index) .. ", damage=" .. tostring(finalDamage) .. ", hp=" .. tostring(monster.hp))
        end
    end

    score_ = score_ + matchedCount * CONFIG.scorePerGem * combo
    if combo > 1 then
        AddFloatText(matches[1].row, matches[1].col, "连锁 x" .. tostring(combo), { 255, 220, 90, 255 })
    end
    if anyDamage then
        SetMessage("符石爆裂，黑暗生物受到波及", 1.5)
    end
    RemoveDeadMonsters()
end

function DropAndRefillBoard()
    local drops = {}

    for col = 1, BOARD_SIZE do
        local gems = {}
        for row = BOARD_SIZE, 1, -1 do
            if not OccupiedByBoardBlocker(row, col) and board_[row][col] ~= 0 then
                table.insert(gems, { type = board_[row][col], fromRow = row, fromCol = col })
            end
            board_[row][col] = 0
        end

        local gemIndex = 1
        local spawnIndex = 0
        for row = BOARD_SIZE, 1, -1 do
            if not OccupiedByBoardBlocker(row, col) then
                local gem = gems[gemIndex]
                if gem then
                    board_[row][col] = gem.type
                    if gem.fromRow ~= row then
                        table.insert(drops, {
                            type = gem.type,
                            fromRow = gem.fromRow,
                            fromCol = gem.fromCol,
                            toRow = row,
                            toCol = col,
                        })
                    end
                    gemIndex = gemIndex + 1
                else
                    local gemType = math.random(1, GEM_TYPES)
                    board_[row][col] = gemType
                    spawnIndex = spawnIndex + 1
                    table.insert(drops, {
                        type = gemType,
                        fromRow = -spawnIndex,
                        fromCol = col,
                        toRow = row,
                        toCol = col,
                    })
                end
            end
        end
    end

    return drops
end

function ResolveMatches()
    local combo = 0
    local totalMatched = 0

    while combo < MAX_CASCADE_COMBO do
        local matches, specials = FindMatches()
        if #matches == 0 then break end
        combo = combo + 1
        totalMatched = totalMatched + #matches
        ApplyMatchDamage(matches, combo, specials, nil)
        for _, cell in ipairs(matches) do
            board_[cell.row][cell.col] = 0
        end
        DropAndRefillBoard()
    end

    return totalMatched > 0
end

function DamageMonster(monster, amount, label)
    monster.hp = monster.hp - amount
    AddFloatText(monster.row, monster.col, (label or "-") .. tostring(amount), { 255, 92, 60, 255 })
    AddParticles(monster.row, monster.col, { 255, 84, 42, 255 }, 14)
end

function FindNearestMonster(trap)
    local nearest = nil
    local nearestDist = 999
    for _, monster in ipairs(monsters_) do
        if monster.hp > 0 then
            local dist = Abs(monster.row - trap.row) + Abs(monster.col - trap.col)
            if dist < nearestDist then
                nearestDist = dist
                nearest = monster
            end
        end
    end
    return nearest
end

function UpdateTurretAngles()
    for _, trap in ipairs(traps_) do
        if trap.kind == "turret" then
            local target = FindNearestMonster(trap)
            if target then
                trap.angle = math.atan(target.row - trap.row, target.col - trap.col)
                trap.targetRow = target.row
                trap.targetCol = target.col
            else
                trap.targetRow = nil
                trap.targetCol = nil
            end
        end
    end
end

function UpdateMissileSiloTargets()
    for _, silo in ipairs(missileSilos_) do
        local target = FindSiloLockedTarget(silo)
        if target then
            silo.targetRow = target.row
            silo.targetCol = target.col
            silo.angle = math.atan(target.row - silo.row, target.col - silo.col)
        else
            silo.targetRow = nil
            silo.targetCol = nil
        end
    end
end

function UpdateAutoAimTargets()
    UpdateTurretAngles()
    UpdateMissileSiloTargets()
end

function AddMissile(row, col, monster, missileIndex)
    local sx, sy = CellCenter(row, col)
    local tx, ty = CellCenter(monster.row, monster.col)
    local index = missileIndex or 1
    local spread = (index - (CONFIG.missilesPerSiloTurn + 1) * 0.5) * tile_ * 0.1
    local angle = (index - 1) * math.pi * 2 / CONFIG.missilesPerSiloTurn
    local offsetX = math.cos(angle) * spread
    local offsetY = math.sin(angle) * spread
    table.insert(missiles_, {
        fromX = sx + offsetX,
        fromY = sy + offsetY,
        x = sx + offsetX,
        y = sy + offsetY,
        toX = tx + offsetX * 0.35,
        toY = ty + offsetY * 0.35,
        life = 1.0 + index * 0.04,
        maxLife = 1.0 + index * 0.04,
        launchDelay = 0.08 + (index - 1) * 0.1,
        arcMul = 0.82 + index * 0.12,
    })
    table.insert(missileLaunches_, {
        x = sx + offsetX,
        y = sy + offsetY,
        life = 0.24 + index * 0.04,
        maxLife = 0.24 + index * 0.04,
    })
end

function AddCannonShell(trap, monster)
    local sx, sy = CellCenter(trap.row, trap.col)
    local tx, ty = CellCenter(monster.row, monster.col)
    table.insert(cannonShells_, {
        x = sx,
        y = sy,
        fromX = sx,
        fromY = sy,
        toX = tx,
        toY = ty,
        life = 0.5,
        maxLife = 0.5,
    })
end

function AddBombExplosion(trap)
    local x, y = CellCenter(trap.row, trap.col)
    table.insert(bombExplosions_, {
        x = x,
        y = y,
        life = 0.55,
        maxLife = 0.55,
    })
    AddItemTriggerEffect("bomb", trap.row, trap.col, trap.row, trap.col)
end

function AddLaserBeam(trap, monster)
    table.insert(laserBeams_, {
        kind = trap.kind,
        row = trap.row,
        col = trap.col,
        targetRow = monster.row,
        targetCol = monster.col,
        life = 0.36,
        maxLife = 0.36,
    })
    AddItemTriggerEffect(trap.kind, trap.row, trap.col, monster.row, monster.col)
end

function TriggerTrap(trap, monster)
    if trap.kind == "laserH" then
        AddLaserBeam(trap, monster)
        DamageMonster(monster, CONFIG.laserDamage, "激光-")
    elseif trap.kind == "laserV" then
        AddLaserBeam(trap, monster)
        DamageMonster(monster, CONFIG.laserDamage, "激光-")
    elseif trap.kind == "bomb" then
        AddBombExplosion(trap)
        for _, target in ipairs(monsters_) do
            if target.hp > 0 and IsNearCell(trap.row, trap.col, target.row, target.col, CONFIG.bombRadius) then
                DamageMonster(target, CONFIG.bombDamage, "爆炸-")
            end
        end
    end
end

StartAutoClearAnimation = nil
StartEnemyDropAnimation = nil

function StartTrapRefillDrop(combo)
    if StartEnemyDropAnimation == nil then return false end
    local drops = DropAndRefillBoard()
    return StartEnemyDropAnimation(drops, combo or 0)
end

function CheckTriggeredTraps()
    local triggeredAny = false
    local removedAnyTrap = false
    for i = #traps_, 1, -1 do
        local trap = traps_[i]
        if trap.kind ~= "turret" then
            local hitMonster = nil
            for _, monster in ipairs(monsters_) do
                if monster.hp > 0 then
                    local hit = (trap.kind == "laserH" and monster.row == trap.row)
                        or (trap.kind == "laserV" and monster.col == trap.col)
                        or (trap.kind == "bomb" and IsNearCell(trap.row, trap.col, monster.row, monster.col, CONFIG.bombRadius))
                    if hit then
                        hitMonster = monster
                        break
                    end
                end
            end
            if hitMonster then
                TriggerTrap(trap, hitMonster)
                triggeredAny = true
            end
            trap.turns = (trap.turns or 1) - 1
            if trap.turns <= 0 then
                table.remove(traps_, i)
                removedAnyTrap = true
            end
        end
    end
    local removedAnyMonster = RemoveDeadMonsters()
    if removedAnyTrap then
        return StartTrapRefillDrop()
    end
    if (triggeredAny or removedAnyMonster) and StartEnemyDropAnimation ~= nil then
        local drops = DropAndRefillBoard()
        return StartEnemyDropAnimation(drops, 0)
    end
    EnsureBoardHasMove()
    return false
end

function FireTurrets()
    local killedAny = false
    local removedTurret = false
    for i = #traps_, 1, -1 do
        local trap = traps_[i]
        if trap.kind == "turret" then
            local nearest = FindNearestMonster(trap)
            if nearest then
                trap.angle = math.atan(nearest.row - trap.row, nearest.col - trap.col)
                AddItemTriggerEffect("turret", trap.row, trap.col, nearest.row, nearest.col)
                AddCannonShell(trap, nearest)
                DamageMonster(nearest, CONFIG.turretDamage, "炮击-")
                if nearest.hp <= 0 then
                    killedAny = true
                end
            end
            trap.turns = trap.turns - 1
            if trap.turns <= 0 then
                table.remove(traps_, i)
                removedTurret = true
            end
        end
    end
    local removedAny = RemoveDeadMonsters()
    if removedTurret then
        return StartTrapRefillDrop()
    end
    if (killedAny or removedAny) and StartEnemyDropAnimation ~= nil then
        local drops = DropAndRefillBoard()
        return StartEnemyDropAnimation(drops, 0)
    end
    EnsureBoardHasMove()
    return false
end

function DamageHero(amount, sourceRow, sourceCol)
    if gameState_ ~= "playing" then return end
    hero_.hp = hero_.hp - amount
    AddFloatText(hero_.row, hero_.col, "-" .. tostring(amount), { 255, 70, 70, 255 })
    AddParticles(sourceRow, sourceCol, { 210, 40, 32, 255 }, 8)
    screenShake_ = math.max(screenShake_, 7)
    print("Hero damaged: amount=" .. tostring(amount) .. ", hp=" .. tostring(hero_.hp))

    if hero_.hp <= 0 then
        hero_.hp = 0
        gameState_ = "gameover"
        SubmitScoreToLeaderboard()
        SetMessage("主角倒下了。按 R 或点击棋盘重开", 99)
    end
end

function IsMonsterMoveCellBlocked(row, col, ignoredIndex)
    return not IsValidCell(row, col)
        or (row == hero_.row and col == hero_.col)
        or OccupiedByMonster(row, col, ignoredIndex)
        or OccupiedByObstacle(row, col)
end

function IsHeroAdjacentTargetCell(row, col)
    return IsInCrossRange(row, col, hero_.row, hero_.col, 1) and not (row == hero_.row and col == hero_.col)
end

function FindMonsterPathStep(index, monster)
    local startKey = CellKey(monster.row, monster.col)
    local visited = { [startKey] = true }
    local queue = {
        {
            row = monster.row,
            col = monster.col,
            firstRow = nil,
            firstCol = nil,
        }
    }
    local head = 1
    local dirs = {
        { dr = -1, dc = 0 },
        { dr = 1, dc = 0 },
        { dr = 0, dc = -1 },
        { dr = 0, dc = 1 },
    }
    local bestCell = nil
    local bestDist = Abs(hero_.row - monster.row) + Abs(hero_.col - monster.col)

    while head <= #queue do
        local current = queue[head]
        head = head + 1

        if current.firstRow ~= nil then
            local dist = Abs(hero_.row - current.row) + Abs(hero_.col - current.col)
            if dist < bestDist then
                bestDist = dist
                bestCell = { row = current.firstRow, col = current.firstCol }
            end
        end

        if IsHeroAdjacentTargetCell(current.row, current.col) and current.firstRow ~= nil then
            return { row = current.firstRow, col = current.firstCol }
        end

        for _, dir in ipairs(dirs) do
            local row = current.row + dir.dr
            local col = current.col + dir.dc
            local key = CellKey(row, col)
            if not visited[key] and not IsMonsterMoveCellBlocked(row, col, index) then
                visited[key] = true
                table.insert(queue, {
                    row = row,
                    col = col,
                    firstRow = current.firstRow or row,
                    firstCol = current.firstCol or col,
                })
            end
        end
    end

    return bestCell
end

function MoveMonsterToCell(monster, cell)
    local oldRow = monster.row
    local oldCol = monster.col
    local targetGem = board_[cell.row][cell.col]
    monster.row = cell.row
    monster.col = cell.col
    if targetGem ~= 0 then
        board_[oldRow][oldCol] = targetGem
    else
        board_[oldRow][oldCol] = 0
    end
    board_[cell.row][cell.col] = 0
    table.insert(monsterMoves_, {
        monster = monster,
        fromRow = oldRow,
        fromCol = oldCol,
        toRow = cell.row,
        toCol = cell.col,
        gemType = targetGem,
        life = 0.28,
        maxLife = 0.28,
    })
    ClearActorCells()
end

function TryMoveMonster(index, monster)
    local pathStep = FindMonsterPathStep(index, monster)
    if pathStep then
        MoveMonsterToCell(monster, pathStep)
        return true
    end

    local rowDelta = hero_.row - monster.row
    local colDelta = hero_.col - monster.col
    local options = {}

    if Abs(rowDelta) >= Abs(colDelta) then
        if rowDelta ~= 0 then table.insert(options, { row = monster.row + (rowDelta > 0 and 1 or -1), col = monster.col }) end
        if colDelta ~= 0 then table.insert(options, { row = monster.row, col = monster.col + (colDelta > 0 and 1 or -1) }) end
    else
        if colDelta ~= 0 then table.insert(options, { row = monster.row, col = monster.col + (colDelta > 0 and 1 or -1) }) end
        if rowDelta ~= 0 then table.insert(options, { row = monster.row + (rowDelta > 0 and 1 or -1), col = monster.col }) end
    end

    for _, cell in ipairs(options) do
        if not IsMonsterMoveCellBlocked(cell.row, cell.col, index) then
            MoveMonsterToCell(monster, cell)
            return true
        end
    end
    return false
end

function MonsterTurn()
    if gameState_ ~= "playing" then return end
    turnId_ = turnId_ + 1
    local attackers = 0

    if FireMissileSilos() then
        return
    end

    local turretStartedDrop = FireTurrets()
    if turretStartedDrop then return end
    if CheckTriggeredTraps() then return end

    for index, monster in ipairs(monsters_) do
        if monster.hp > 0 then
            if IsInCrossRange(monster.row, monster.col, hero_.row, hero_.col, 1) then
                attackers = attackers + 1
            else
                TryMoveMonster(index, monster)
                if CheckTriggeredTraps() then return end
                if monster.hp > 0 and IsInCrossRange(monster.row, monster.col, hero_.row, hero_.col, 1) then
                    attackers = attackers + 1
                end
            end
        end
    end

    if attackers > 0 then
        for _, monster in ipairs(monsters_) do
            if monster.hp > 0 and IsInCrossRange(monster.row, monster.col, hero_.row, hero_.col, 1) then
                MarkMonsterAttack3D(monster)
            end
        end
        DamageHero(attackers, hero_.row, hero_.col)
        SetMessage("怪物逼近并攻击了主角。用 WASD 移动或消除周围符石", 2.0)
    end
    EnsureBoardStable(1)
end
