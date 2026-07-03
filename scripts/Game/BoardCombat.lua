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

function MissileSiloAt(row, col)
    for _, silo in ipairs(missileSilos_) do
        if silo.row == row and silo.col == col then
            return silo
        end
    end
    return nil
end

function OccupiedByMissileSilo(row, col)
    return MissileSiloAt(row, col) ~= nil
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

    local extraCount = math.floor((wave_ - 1) * (CONFIG.monsterCountIncreasePerWave or 0))
    local targetCount = CONFIG.monsterCount + extraCount
    targetCount = Clamp(targetCount, 1, CONFIG.monsterMaxCount)

    for _, cell in ipairs(spawnCells) do
        if #monsters_ >= targetCount then break end
        if not (cell.row == hero_.row and cell.col == hero_.col) and not OccupiedByObstacle(cell.row, cell.col) then
            local hp = CONFIG.baseMonsterHp + wave_ * CONFIG.monsterWaveHpBonus + math.random(0, 2)
            table.insert(monsters_, {
                row = cell.row,
                col = cell.col,
                hp = hp,
                maxHp = hp,
                hpBuffer = hp,
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
    hero_ = { row = 5, col = 5, hp = CONFIG.heroMaxHp, maxHp = CONFIG.heroMaxHp, hpBuffer = CONFIG.heroMaxHp }
    selected_ = nil
    lastTapCell_ = nil
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
    score_ = 0
    moves_ = 0
    wave_ = 1
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
    turnId_ = 0
    pendingRogueReward_ = false
    playerTurnActive_ = false
    playerTurnTimer_ = 0
    pendingPlayerTurnTimerAfterRender_ = false
    startGamePromptVisible_ = false
    startGameButtonRect_ = nil
    activeRuneDrops_ = {}
    currentTurnText_ = "玩家回合"
    currentTurnKind_ = "player"
    turnBanner_ = nil
    turnBannerQueue_ = {}
    ResetRoguelikeState()
    gameState_ = "playing"
    FillNewBoard()
    SpawnMonsters()
    ClearActorCells()
    EnsureBoardHasMove()
    SyncScene3D()
    SetMessage("符石生存开始：击败每波怪物后选择遗物、BUFF或道具", 3.0)
    ShowTurnBanner("玩家回合", "player")
    SchedulePlayerTurnTimerAfterRender()
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

function EnsureBoardStable(combo, phase)
    if gameState_ ~= "playing" or isAnimating_ then return false end

    local matches, specials = FindMatches()
    if #matches > 0 and StartAutoClearAnimation ~= nil then
        hintCells_ = {}
        hintScore_ = 0
        SetMessage("符石爆裂，黑暗生物受到波及", 1.5)
        StartAutoClearAnimation(matches, combo or 1, specials, nil, phase)
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

function ActiveRuneDropCount()
    return #(activeRuneDrops_ or {})
end

function IsRuneDropCell(row, col)
    for _, drop in ipairs(activeRuneDrops_ or {}) do
        if drop.toRow == row and drop.toCol == col then return true end
    end
    return false
end

function RemoveActiveRuneDropTarget(row, col)
    for i = #(activeRuneDrops_ or {}), 1, -1 do
        local drop = activeRuneDrops_[i]
        if drop.toRow == row and drop.toCol == col then
            table.remove(activeRuneDrops_, i)
        end
    end
end

function AddActiveRuneDrops(drops)
    for _, drop in ipairs(drops or {}) do
        RemoveActiveRuneDropTarget(drop.fromRow, drop.fromCol)
        RemoveActiveRuneDropTarget(drop.toRow, drop.toCol)
        table.insert(activeRuneDrops_, {
            type = drop.type,
            fromRow = drop.fromRow,
            fromCol = drop.fromCol,
            toRow = drop.toRow,
            toCol = drop.toCol,
            life = DROP_DURATION,
            maxLife = DROP_DURATION,
        })
    end
end

function IsStableSwapCell(row, col)
    if not IsValidCell(row, col) or IsRuneDropCell(row, col) or HasMonsterAt(row, col) or OccupiedByObstacle(row, col) then
        return false
    end
    local object = BoardObjectAt(row, col)
    return IsSwappableBoardObject(object)
end

function HasBlockingPlayerAnimation()
    return currentAnim_ ~= nil and (currentAnim_.kind == "swap" or currentAnim_.kind == "itemSwapTrigger" or currentAnim_.kind == "clear")
end

function HasPendingPlayerResolution()
    return currentAnim_ ~= nil or ActiveRuneDropCount() > 0 or HasPendingItemAnimations()
end

function StartPlayerTurnTimer()
    playerTurnActive_ = true
    pendingPlayerTurnTimerAfterRender_ = false
    playerTurnTimer_ = CONFIG.playerTurnDuration or 2.0
    playerTurnManualClearCount_ = 0
end

function SchedulePlayerTurnTimerAfterRender()
    playerTurnActive_ = false
    playerTurnTimer_ = CONFIG.playerTurnDuration or 2.0
    pendingPlayerTurnTimerAfterRender_ = true
    startGamePromptVisible_ = false
end

function StartPendingPlayerTurnTimerAfterRender()
    if pendingPlayerTurnTimerAfterRender_ and gameState_ == "playing" then
        pendingPlayerTurnTimerAfterRender_ = false
        startGamePromptVisible_ = true
    end
end

function StartGameFromPrompt()
    if not startGamePromptVisible_ or gameState_ ~= "playing" then return false end
    startGamePromptVisible_ = false
    startGameButtonRect_ = nil
    StartPlayerTurnTimer()
    SetMessage("玩家回合开始，连续消除会刷新倒计时", 1.6)
    return true
end

function EndPlayerTurnWhenStable()
    if playerTurnActive_ then
        playerTurnActive_ = false
    end
    if HasPendingPlayerResolution() then return false end
    FinishPlayerMove()
    return true
end

function AddCellUnique(cells, exists, row, col, gemType)
    local key = CellKey(row, col)
    if not exists[key] then
        exists[key] = true
        table.insert(cells, { row = row, col = col, type = gemType })
    end
end

function AddSpecialIfUnlocked(specials, special)
    if IsSpecialUnlocked(special.kind) then
        table.insert(specials, special)
    end
end

function AddSpecialFromRun(specials, runCells, direction)
    if #runCells < 4 then return end
    if #runCells == 4 then
        AddSpecialIfUnlocked(specials, { kind = direction == "horizontal" and "laserH" or "laserV", cells = runCells })
    elseif #runCells == 5 then
        AddSpecialIfUnlocked(specials, { kind = "missileSilo", cells = runCells })
    elseif #runCells > 5 then
        AddSpecialIfUnlocked(specials, { kind = direction == "horizontal" and "laserH" or "laserV", cells = runCells })
        AddSpecialIfUnlocked(specials, { kind = "missileSilo", cells = runCells })
    end
end

function GetBoardGem(row, col)
    if row < 1 or row > BOARD_SIZE or col < 1 or col > BOARD_SIZE then return 0 end
    if IsRuneDropCell(row, col) then return 0 end
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
                        AddSpecialIfUnlocked(specials, { kind = "bomb", cells = cells, anchor = { row = row, col = col, type = gemType } })
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
                    AddSpecialIfUnlocked(specials, { kind = "turret", cells = cells })
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
        local runType = GetBoardGem(row, 1)
        local runStart = 1
        local runLength = 1
        for col = 2, BOARD_SIZE + 1 do
            local gemType = nil
            if col <= BOARD_SIZE then gemType = GetBoardGem(row, col) end
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
        local runType = GetBoardGem(1, col)
        local runStart = 1
        local runLength = 1
        for row = 2, BOARD_SIZE + 1 do
            local gemType = nil
            if row <= BOARD_SIZE then gemType = GetBoardGem(row, col) end
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
    end
    board_[row][col] = 0
    table.insert(traps_, trap)
    local label = kind == "laserH" and "横向激光" or kind == "laserV" and "纵向激光" or kind == "turret" and "炮台" or kind == "missileSilo" and "导弹井" or "炸弹"
    AddFloatText(row, col, label, { 120, 230, 255, 255 })
    AddOperationLog("生成道具：" .. label .. " (" .. tostring(row) .. "," .. tostring(col) .. ")")
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
    AddOperationLog("生成道具：导弹井 (" .. tostring(row) .. "," .. tostring(col) .. ")")
    AddFloatText(row, col, "导弹井", { 255, 220, 120, 255 })
end

function SpawnMissileSilos(cells)
    for _, cell in ipairs(cells or {}) do
        AddMissileSilo(cell.row, cell.col)
    end
end

function BoardObjectAt(row, col)
    local trap = TrapAt(row, col)
    if trap ~= nil then
        return { kind = "trap", ref = trap }
    end
    local silo = MissileSiloAt(row, col)
    if silo ~= nil then
        return { kind = "silo", ref = silo }
    end
    if board_[row] ~= nil and board_[row][col] ~= 0 then
        return { kind = "gem", gemType = board_[row][col] }
    end
    return nil
end

function PlaceBoardObject(row, col, object)
    board_[row][col] = 0
    if object == nil then return end
    if object.kind == "gem" then
        board_[row][col] = object.gemType
    elseif object.kind == "trap" then
        object.ref.row = row
        object.ref.col = col
    elseif object.kind == "silo" then
        object.ref.row = row
        object.ref.col = col
    end
end

function IsTriggerTrapKind(kind)
    return kind == "laserH" or kind == "laserV" or kind == "bomb"
end

function IsManualTriggerTrapKind(kind)
    return IsTriggerTrapKind(kind) or kind == "turret"
end

function IsSwappableBoardObject(object)
    if object == nil then return false end
    if object.kind == "gem" then return true end
    if object.kind == "trap" then return IsManualTriggerTrapKind(object.ref.kind) end
    return false
end

function CanSwapBoardObjects(a, b)
    if not IsAdjacent(a, b) then return false end
    if OccupiedByActor(a.row, a.col) or OccupiedByActor(b.row, b.col) then return false end
    local objA = BoardObjectAt(a.row, a.col)
    local objB = BoardObjectAt(b.row, b.col)
    return IsSwappableBoardObject(objA) and IsSwappableBoardObject(objB)
end

function SwapBoardObjects(a, b)
    if not CanSwapBoardObjects(a, b) then return false end
    local objA = BoardObjectAt(a.row, a.col)
    local objB = BoardObjectAt(b.row, b.col)
    PlaceBoardObject(a.row, a.col, nil)
    PlaceBoardObject(b.row, b.col, nil)
    PlaceBoardObject(a.row, a.col, objB)
    PlaceBoardObject(b.row, b.col, objA)
    ClearActorCells()
    lastSwapDropDir_ = { row = b.row - a.row, col = b.col - a.col }
    itemSignature3D_ = nil
    AddOperationLog("交换：" .. FormatBoardCell(a.row, a.col) .. " 与 " .. FormatBoardCell(b.row, b.col))
    return true
end

function GetTriggerableTrapAt(row, col)
    local trap = TrapAt(row, col)
    if trap ~= nil and IsManualTriggerTrapKind(trap.kind) then
        return trap
    end
    return nil
end

function ClearGemWithoutAreaDamage(row, col)
    if IsValidCell(row, col) and board_[row][col] ~= 0 then
        local gemType = board_[row][col]
        board_[row][col] = 0
        table.insert(matchEffects_, { row = row, col = col, life = 0.3, maxLife = 0.3, type = gemType })
        AddParticles(row, col, GEM_COLORS[gemType], 4)
        score_ = score_ + CONFIG.scorePerGem
    end
end

function RemoveTrapInstance(trap)
    for i = #traps_, 1, -1 do
        if traps_[i] == trap then
            table.remove(traps_, i)
            pendingItemBoardRefill_ = true
            return true
        end
    end
    return false
end

function GetLaserBeamHitProgress(beam, row, col)
    local distance = nil
    local sideDistance = nil
    if beam.kind == "laserH" and row == beam.row then
        distance = math.abs(col - beam.col)
        if col < beam.col then
            sideDistance = beam.col - 1
        elseif col > beam.col then
            sideDistance = BOARD_SIZE - beam.col
        else
            sideDistance = 1
        end
    elseif beam.kind == "laserV" and col == beam.col then
        distance = math.abs(row - beam.row)
        if row < beam.row then
            sideDistance = beam.row - 1
        elseif row > beam.row then
            sideDistance = BOARD_SIZE - beam.row
        else
            sideDistance = 1
        end
    end
    if distance == nil then return nil end
    return distance / math.max(1, sideDistance or 1)
end

function ResolveLaserBeamHits(beam)
    if beam == nil then return end
    local progress = 1 - Clamp((beam.life or 0) / math.max(0.001, beam.maxLife or 0.36), 0, 1)

    for _, monster in ipairs(monsters_) do
        if monster.hp > 0 and beam.hitMonsters[monster] ~= true then
            local hitProgress = GetLaserBeamHitProgress(beam, monster.row, monster.col)
            if hitProgress ~= nil and progress >= hitProgress then
                beam.hitMonsters[monster] = true
                ResolveItemHitMonster(monster, beam.damage or GetRogueItemDamage(CONFIG.laserDamage), "激光-", { name = beam.kind == "laserH" and "横向激光" or "纵向激光", row = beam.row, col = beam.col, action = beam.action or "触发" })
            end
        end
    end

    for _, trap in ipairs(traps_) do
        if CanChainTriggerTrap(trap) and beam.hitTraps[trap] ~= true then
            local hitProgress = GetLaserBeamHitProgress(beam, trap.row, trap.col)
            if hitProgress ~= nil and hitProgress > 0 and progress >= hitProgress then
                beam.hitTraps[trap] = true
                TriggerChainTrap(trap, "激光连锁")
            end
        end
    end
end

function ResolveBombExplosionHits(explosion)
    if explosion == nil then return end
    local progress = 1 - Clamp((explosion.life or 0) / math.max(0.001, explosion.maxLife or 0.55), 0, 1)
    local maxRadius = math.max(1, CONFIG.bombRadius or 1)
    local currentRadius = progress * (maxRadius + 0.72)

    for _, monster in ipairs(monsters_) do
        if monster.hp > 0 and explosion.hitMonsters[monster] ~= true then
            local distance = math.max(Abs(monster.row - explosion.row), Abs(monster.col - explosion.col))
            if distance <= maxRadius and distance <= currentRadius then
                explosion.hitMonsters[monster] = true
                ResolveItemHitMonster(monster, explosion.damage or GetRogueItemDamage(CONFIG.bombDamage), "爆炸-", { name = "炸弹", row = explosion.row, col = explosion.col, action = explosion.action or "爆炸" })
            end
        end
    end

    for _, trap in ipairs(traps_) do
        if CanChainTriggerTrap(trap) and explosion.hitTraps[trap] ~= true then
            local distance = math.max(Abs(trap.row - explosion.row), Abs(trap.col - explosion.col))
            if distance > 0 and distance <= maxRadius and distance <= currentRadius then
                explosion.hitTraps[trap] = true
                TriggerChainTrap(trap, "爆炸连锁")
            end
        end
    end
end

function ResolveItemAnimationFinished()
    local removedAny = RemoveDeadMonsters()
    if removedAny then
        pendingItemBoardRefill_ = true
    end
end

function ResolveItemHitMonster(monster, amount, label, source)
    if monster == nil or monster.hp <= 0 then return end
    DamageMonster(monster, amount, label, source)
end

function CanChainTriggerTrap(trap)
    return trap ~= nil and trap.triggered ~= true and IsTriggerTrapKind(trap.kind)
end

function FindChainTrapAt(row, col, sourceTrap)
    for _, trap in ipairs(traps_) do
        if trap ~= sourceTrap and CanChainTriggerTrap(trap) and trap.row == row and trap.col == col then
            return trap
        end
    end
    return nil
end

function TriggerLaserTrapEffect(trap, action)
    AddLaserBeam(trap, action or "触发")
    if trap.kind == "laserH" then
        for col = 1, BOARD_SIZE do
            ClearGemWithoutAreaDamage(trap.row, col)
        end
    else
        for row = 1, BOARD_SIZE do
            ClearGemWithoutAreaDamage(row, trap.col)
        end
    end
    AddOperationLog((action or "触发") .. "：激光" .. FormatBoardCell(trap.row, trap.col) .. " 沿瞄准线发射")
end

function TriggerBombTrapEffect(trap, action)
    AddBombExplosion(trap, action or "爆炸")
    local minRow = math.max(1, trap.row - CONFIG.bombRadius)
    local maxRow = math.min(BOARD_SIZE, trap.row + CONFIG.bombRadius)
    local minCol = math.max(1, trap.col - CONFIG.bombRadius)
    local maxCol = math.min(BOARD_SIZE, trap.col + CONFIG.bombRadius)
    for row = minRow, maxRow do
        for col = minCol, maxCol do
            ClearGemWithoutAreaDamage(row, col)
        end
    end
    AddOperationLog((action or "触发") .. "：炸弹" .. FormatBoardCell(trap.row, trap.col) .. " 向外扩散爆炸")
end

function TriggerTrapEffect(trap, action)
    if not CanChainTriggerTrap(trap) then return false end
    trap.triggered = true
    if trap.kind == "laserH" or trap.kind == "laserV" then
        TriggerLaserTrapEffect(trap, action)
    elseif trap.kind == "bomb" then
        TriggerBombTrapEffect(trap, action)
    else
        return false
    end
    RemoveTrapInstance(trap)
    itemSignature3D_ = nil
    pendingItemBoardRefill_ = true
    return true
end

function TriggerChainTrap(trap, source)
    if trap == nil then return false end
    local sourceName = source or "连锁触发"
    return TriggerTrapEffect(trap, sourceName)
end

function TriggerLaserTrapManually(trap)
    return TriggerTrapEffect(trap, "手动触发")
end

function TriggerBombTrapManually(trap)
    return TriggerTrapEffect(trap, "手动触发")
end

function TriggerTurretTrapManually(trap)
    if trap == nil or trap.kind ~= "turret" then return false end
    local nearest = FindNearestMonster(trap)
    if nearest == nil then
        SetMessage("炮台周围没有可攻击的怪物", 1.2)
        return false
    end
    trap.angle = math.atan(nearest.row - trap.row, nearest.col - trap.col)
    trap.targetRow = nearest.row
    trap.targetCol = nearest.col
    AddItemTriggerEffect("turret", trap.row, trap.col, nearest.row, nearest.col)
    AddCannonShell(trap, nearest, GetRogueItemDamage(CONFIG.turretDamage))
    trap.turns = math.max(0, (trap.turns or 1) - 1)
    AddOperationLog("手动触发：炮台" .. FormatBoardCell(trap.row, trap.col) .. " 向怪物" .. FormatBoardCell(nearest.row, nearest.col) .. " 开火")
    if trap.turns <= 0 then
        RemoveTrapInstance(trap)
        itemSignature3D_ = nil
        pendingItemBoardRefill_ = true
    end
    return true
end

function TriggerTrapManually(trap)
    if trap == nil or gameState_ ~= "playing" or isAnimating_ then return false end
    local triggered = false
    if trap.kind == "laserH" or trap.kind == "laserV" then
        triggered = TriggerLaserTrapManually(trap)
        SetMessage("激光向两侧发射，命中怪物并可连锁触发道具", 1.8)
    elseif trap.kind == "bomb" then
        triggered = TriggerBombTrapManually(trap)
        SetMessage("炸弹冲击波向外扩散，命中怪物并可连锁触发道具", 1.8)
    elseif trap.kind == "turret" then
        triggered = TriggerTurretTrapManually(trap)
        SetMessage("炮台锁定最近怪物并开火", 1.5)
    else
        return false
    end
    if not triggered then return false end

    selected_ = nil
    dragStart_ = nil
    dragTriggered_ = false
    moves_ = moves_ + 1
    pendingMove_ = false
    hero_.attackFlash = 0.42
    RunItemTurn()
    pendingMonsterTurn_ = true
    local drops = DropAndRefillBoard()
    local heroMoved = dropHeroMoved_
    if #drops > 0 then
        StartEnemyDropAnimation(drops, 0, "item", heroMoved)
    else
        currentAnim_ = {
            kind = "waitItems",
            elapsed = 0,
            duration = 0.05,
        }
        isAnimating_ = true
    end
    return true
end

function TryTriggerTrapCell(cell)
    if cell == nil then return false end
    return TriggerTrapManually(GetTriggerableTrapAt(cell.row, cell.col))
end

function TryTriggerTrapBySwap(a, b)
    if not IsAdjacent(a, b) then return false end
    local trapA = GetTriggerableTrapAt(a.row, a.col)
    if trapA ~= nil and board_[b.row] and board_[b.row][b.col] ~= 0 then
        return TriggerTrapManually(trapA)
    end
    local trapB = GetTriggerableTrapAt(b.row, b.col)
    if trapB ~= nil and board_[a.row] and board_[a.row][a.col] ~= 0 then
        return TriggerTrapManually(trapB)
    end
    return false
end

function FormatBoardCell(row, col)
    return "(" .. tostring(row) .. "," .. tostring(col) .. ")"
end

function FormatDamageSource(source)
    if type(source) == "table" then
        local name = source.name or "道具"
        local pos = ""
        if source.row ~= nil and source.col ~= nil then
            pos = FormatBoardCell(source.row, source.col)
        end
        local action = source.action or "触发"
        return name .. pos .. action
    end
    return tostring(source or "")
end

function FormatMonsterHealth(monster)
    return tostring(math.max(0, monster.hp)) .. "/" .. tostring(monster.maxHp or monster.hp or 0)
end

function FormatAttackerList(attackers)
    local parts = {}
    for _, monster in ipairs(attackers or {}) do
        table.insert(parts, FormatBoardCell(monster.row, monster.col))
    end
    if #parts == 0 then
        return "怪物"
    end
    return tostring(#parts) .. "只怪物" .. table.concat(parts, "、")
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

function FireMissileSilos(startDrop)
    if #missileSilos_ == 0 then return false end

    local firedAny = false
    for _, silo in ipairs(missileSilos_) do
        if (silo.armedTurn or 0) <= turnId_ then
            local target = FindSiloLockedTarget(silo)
            if target then
                AddItemTriggerEffect("missile", silo.row, silo.col, target.row, target.col)
                for missileIndex = 1, CONFIG.missilesPerSiloTurn do
                    AddMissile(silo.row, silo.col, target, missileIndex)
                    DamageMonster(target, GetRogueItemDamage(CONFIG.missileDamage), "导弹-", { name = "导弹井", row = silo.row, col = silo.col, action = "发射" })
                    firedAny = true
                end
            end
            silo.turnsLeft = (silo.turnsLeft or CONFIG.missileSiloTurns) - 1
        end
    end

    for i = #missileSilos_, 1, -1 do
        if (missileSilos_[i].turnsLeft or 0) <= 0 then
            table.remove(missileSilos_, i)
            pendingItemBoardRefill_ = true
        end
    end

    if firedAny then
        SetMessage("导弹井发射追踪导弹", 1.8)
        if isItemTurnResolving_ then
            pendingItemBoardRefill_ = true
        else
            RemoveDeadMonsters()
        end
    end
    if firedAny and startDrop ~= false and StartEnemyDropAnimation ~= nil then
        local drops = DropAndRefillBoard()
        local heroMoved = dropHeroMoved_
        return StartEnemyDropAnimation(drops, 0, "monster", heroMoved)
    end
    return firedAny
end

function GetSpecialPriority(kind)
    if kind == "missileSilo" then return 4 end
    if kind == "bomb" then return 3 end
    if kind == "laserH" or kind == "laserV" then return 2 end
    if kind == "turret" then return 1 end
    return 0
end

function PickHighestPrioritySpecial(specials)
    local best = nil
    local bestPriority = -1
    for _, special in ipairs(specials or {}) do
        local priority = GetSpecialPriority(special.kind)
        if priority > bestPriority then
            best = special
            bestPriority = priority
        end
    end
    return best
end

function SpawnSpecialTraps(specials, preferredCells)
    local special = PickHighestPrioritySpecial(specials)
    if special == nil then return end
    if special.kind == "missileSilo" then
        for _, cell in ipairs(special.cells or {}) do
            AddMissileSilo(cell.row, cell.col)
        end
    else
        local anchor = PickSpecialAnchor(special, preferredCells)
        if anchor then
            AddTrap(special.kind, anchor.row, anchor.col, special.cells)
        end
    end
end

function CompleteWaveIfCleared()
    if #monsters_ == 0 and gameState_ == "playing" then
        pendingRogueReward_ = true
    end
end

function TryOpenPendingRogueReward()
    if pendingRogueReward_ and gameState_ == "playing" and not isAnimating_ and not HasPendingItemAnimations() and #monsterMoves_ == 0 then
        pendingRogueReward_ = false
        BeginRogueReward()
        return true
    end
    return false
end

function RemoveDeadMonsters()
    local removedAny = false
    for i = #monsters_, 1, -1 do
        local monster = monsters_[i]
        if monster.hp <= 0 then
            AddFloatText(monster.row, monster.col, "击杀", { 255, 210, 80, 255 })
            AddParticles(monster.row, monster.col, { 255, 64, 36, 255 }, 24)
            if AddMonsterDeathBurst3D ~= nil then
                AddMonsterDeathBurst3D(monster.row, monster.col)
            end
            score_ = score_ + CONFIG.killScore + wave_ * CONFIG.killScorePerWave
            table.remove(monsters_, i)
            removedAny = true
        end
    end

    if #monsters_ == 0 and gameState_ == "playing" then
        CompleteWaveIfCleared()
    end
    return removedAny
end

function PlayMeowClearSound(combo, manualClearCount)
    if meowClearSound_ == nil or meowSoundSource_ == nil then return end
    local baseFrequency = meowClearSound_:GetFrequency()
    if baseFrequency == nil or baseFrequency <= 0 then
        baseFrequency = 44100
    end
    local manualStep = math.max(0, (manualClearCount or 1) - 1)
    local chainStep = math.max(0, (combo or 1) - 1)
    local pitch = Clamp(1.0 + manualStep * 0.18 + chainStep * 0.04, 1.0, 1.9)
    meowSoundSource_:Play(meowClearSound_, baseFrequency * pitch, 0.78)
end

function ApplyMatchDamage(matches, combo, specials, preferredCells, manualClearCount)
    PlayMeowClearSound(combo, manualClearCount)
    SpawnSpecialTraps(specials or {}, preferredCells)
    local damagedMonsters = {}
    local matchedCount = #matches

    for _, cell in ipairs(matches) do
        table.insert(matchEffects_, { row = cell.row, col = cell.col, life = 0.35, maxLife = 0.35, type = cell.type })
        AddParticles(cell.row, cell.col, GEM_COLORS[cell.type], 8, { fromRuneCenter = true, minSpeed = 52, speedRange = 105, gravity = 0, minSize = 2, sizeRange = 3 })

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
            local finalDamage = matchedCount + GetRogueBuff("matchDamageBonus")
            DamageMonster(monster, finalDamage, "-", { name = "符石爆裂", row = monster.row, col = monster.col, action = "波及" })
            anyDamage = true
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

function GetActiveDropDirection()
    if not IsDirectionalDropUnlocked() then
        return { row = 1, col = 0 }
    end
    local dir = lastSwapDropDir_ or { row = 1, col = 0 }
    local row = dir.row or 0
    local col = dir.col or 0
    if Abs(row) + Abs(col) ~= 1 then
        return { row = 1, col = 0 }
    end
    return { row = row, col = col }
end

function GetSpawnCellForDrop(sourceCell, dropDir, spawnIndex)
    return {
        row = sourceCell.row - dropDir.row * spawnIndex,
        col = sourceCell.col - dropDir.col * spawnIndex,
    }
end

function OccupiedByFixedDropBlocker(row, col)
    return HasMonsterAt(row, col) or OccupiedByObstacle(row, col)
end

function ApplyHeroDrop(fromRow, fromCol, toRow, toCol)
    if fromRow == toRow and fromCol == toCol then return end
    dropHeroMoved_ = true
    pendingHeroDrop_ = {
        fromRow = fromRow,
        fromCol = fromCol,
        toRow = toRow,
        toCol = toCol,
        life = DROP_DURATION,
        maxLife = DROP_DURATION,
    }
    hero_.row = toRow
    hero_.col = toCol
end

function ProcessDropSegment(segment, drops, dropDir)
    if #segment == 0 then return end

    local items = {}
    for _, cell in ipairs(segment) do
        if IsDirectionalDropUnlocked() and hero_.row == cell.row and hero_.col == cell.col then
            table.insert(items, { kind = "hero", fromRow = cell.row, fromCol = cell.col })
        else
            local gemType = board_[cell.row][cell.col]
            if gemType ~= 0 then
                table.insert(items, { kind = "gem", type = gemType, fromRow = cell.row, fromCol = cell.col })
            end
        end
        board_[cell.row][cell.col] = 0
    end

    local sourceCell = segment[#segment]
    local spawnIndex = 0
    for index, cell in ipairs(segment) do
        local item = items[index]
        if item == nil then
            local gemType = math.random(1, GEM_TYPES)
            board_[cell.row][cell.col] = gemType
            spawnIndex = spawnIndex + 1
            local spawnCell = GetSpawnCellForDrop(sourceCell, dropDir, spawnIndex)
            table.insert(drops, {
                type = gemType,
                fromRow = spawnCell.row,
                fromCol = spawnCell.col,
                toRow = cell.row,
                toCol = cell.col,
            })
        elseif item.kind == "hero" then
            ApplyHeroDrop(item.fromRow, item.fromCol, cell.row, cell.col)
        else
            board_[cell.row][cell.col] = item.type
            if item.fromRow ~= cell.row or item.fromCol ~= cell.col then
                table.insert(drops, {
                    type = item.type,
                    fromRow = item.fromRow,
                    fromCol = item.fromCol,
                    toRow = cell.row,
                    toCol = cell.col,
                })
            end
        end
    end
end

function ProcessDropLine(cells, drops, dropDir)
    local segment = {}
    for _, cell in ipairs(cells) do
        if OccupiedByFixedDropBlocker(cell.row, cell.col) then
            ProcessDropSegment(segment, drops, dropDir)
            segment = {}
            board_[cell.row][cell.col] = 0
        else
            table.insert(segment, cell)
        end
    end
    ProcessDropSegment(segment, drops, dropDir)
end

function DropAndRefillBoard()
    dropHeroMoved_ = false
    local drops = {}
    local dropDir = GetActiveDropDirection()

    if dropDir.row ~= 0 then
        for col = 1, BOARD_SIZE do
            local cells = {}
            if dropDir.row > 0 then
                for row = BOARD_SIZE, 1, -1 do
                    table.insert(cells, { row = row, col = col })
                end
            else
                for row = 1, BOARD_SIZE do
                    table.insert(cells, { row = row, col = col })
                end
            end
            ProcessDropLine(cells, drops, dropDir)
        end
    else
        for row = 1, BOARD_SIZE do
            local cells = {}
            if dropDir.col > 0 then
                for col = BOARD_SIZE, 1, -1 do
                    table.insert(cells, { row = row, col = col })
                end
            else
                for col = 1, BOARD_SIZE do
                    table.insert(cells, { row = row, col = col })
                end
            end
            ProcessDropLine(cells, drops, dropDir)
        end
    end

    ClearActorCells()
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

function DamageMonster(monster, amount, label, source)
    monster.hpBuffer = math.max(monster.hpBuffer or monster.hp or 0, monster.hp or 0)
    monster.hp = monster.hp - amount
    monster.hitFlash = 0.32
    monster.hitPulse = 0.26
    if source ~= nil and source ~= "" then
        AddOperationLog("道具伤害：" .. FormatDamageSource(source) .. "，命中怪物" .. FormatBoardCell(monster.row, monster.col) .. "，造成 " .. tostring(amount) .. " 点伤害，怪物生命 " .. FormatMonsterHealth(monster))
    end
    local angle = -math.pi * 0.78 + (math.random() - 0.5) * 0.9
    AddFloatText(monster.row, monster.col, (label or "-") .. tostring(amount), { 255, 92, 60, 255 }, {
        angle = angle,
        speed = 86,
        gravity = 220,
        life = 0.95,
        size = 22,
        pop = true,
        offsetY = -tile_ * 0.05,
    })
    AddParticles(monster.row, monster.col, { 255, 84, 42, 255 }, 18)
end

function FindLaserTarget(trap)
    if trap == nil then return nil end
    for _, monster in ipairs(monsters_) do
        if monster.hp > 0 then
            if (trap.kind == "laserH" and monster.row == trap.row)
                or (trap.kind == "laserV" and monster.col == trap.col) then
                return monster
            end
        end
    end
    return nil
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
    for _, trap in ipairs(traps_) do
        if trap.kind == "laserH" or trap.kind == "laserV" then
            local target = FindLaserTarget(trap)
            if target then
                trap.targetRow = target.row
                trap.targetCol = target.col
            else
                trap.targetRow = nil
                trap.targetCol = nil
            end
        end
    end
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

function AddCannonShell(trap, monster, damage)
    local fromPoint = ItemHudPoint3D ~= nil and ItemHudPoint3D(trap.row, trap.col, 0.62) or nil
    local targetPoint = BoardHudPoint3D ~= nil and BoardHudPoint3D(monster.row, monster.col, 0.36) or nil
    local sx, sy = CellCenter(trap.row, trap.col)
    local tx, ty = CellCenter(monster.row, monster.col)
    if fromPoint ~= nil then
        sx = fromPoint.x
        sy = fromPoint.y
    end
    if targetPoint ~= nil then
        tx = targetPoint.x
        ty = targetPoint.y
    end
    table.insert(cannonShells_, {
        x = sx,
        y = sy,
        fromX = sx,
        fromY = sy,
        toX = tx,
        toY = ty,
        sourceRow = trap.row,
        sourceCol = trap.col,
        targetMonster = monster,
        damage = damage or CONFIG.turretDamage,
        source = { name = "炮台", row = trap.row, col = trap.col, action = "开火" },
        resolved = false,
        life = 0.5,
        maxLife = 0.5,
    })
end

function AddBombExplosion(trap, action)
    local x, y = CellCenter(trap.row, trap.col)
    table.insert(bombExplosions_, {
        row = trap.row,
        col = trap.col,
        x = x,
        y = y,
        action = action or "爆炸",
        damage = GetRogueItemDamage(CONFIG.bombDamage),
        hitMonsters = {},
        hitTraps = {},
        life = 0.55,
        maxLife = 0.55,
    })
    AddItemTriggerEffect("bomb", trap.row, trap.col, trap.row, trap.col)
end

function AddLaserBeam(trap, action)
    local targetRow = trap.targetRow or trap.row
    local targetCol = trap.targetCol or trap.col
    table.insert(laserBeams_, {
        kind = trap.kind,
        row = trap.row,
        col = trap.col,
        targetRow = targetRow,
        targetCol = targetCol,
        action = action or "触发",
        damage = GetRogueItemDamage(CONFIG.laserDamage),
        hitMonsters = {},
        hitTraps = {},
        life = 0.36,
        maxLife = 0.36,
    })
    AddItemTriggerEffect(trap.kind, trap.row, trap.col, targetRow, targetCol)
end

function TriggerTrap(trap, monster)
    if trap == nil then return false end
    if trap.kind == "laserH" or trap.kind == "laserV" then
        return TriggerTrapEffect(trap, "触发")
    elseif trap.kind == "bomb" then
        return TriggerTrapEffect(trap, "爆炸")
    end
    return false
end

StartAutoClearAnimation = nil
StartEnemyDropAnimation = nil

function StartTrapRefillDrop(combo, phase)
    if StartEnemyDropAnimation == nil then return false end
    local drops = DropAndRefillBoard()
    local heroMoved = dropHeroMoved_
    return StartEnemyDropAnimation(drops, combo or 0, phase or "monster", heroMoved)
end

function CheckTriggeredTraps(startDrop)
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
                if TriggerTrap(trap, hitMonster) then
                    triggeredAny = true
                    removedAnyTrap = true
                end
            end
            if trap.triggered ~= true and trap.turns ~= nil and trap.lastTickTurn ~= turnId_ then
                trap.turns = trap.turns - 1
                trap.lastTickTurn = turnId_
            end
            if trap.triggered ~= true and trap.turns ~= nil and trap.turns <= 0 then
                table.remove(traps_, i)
                removedAnyTrap = true
                pendingItemBoardRefill_ = true
            end
        end
    end
    local removedAnyMonster = false
    if isItemTurnResolving_ then
        if triggeredAny then pendingItemBoardRefill_ = true end
        removedAnyMonster = false
    else
        removedAnyMonster = RemoveDeadMonsters()
    end
    if removedAnyTrap then
        if startDrop == false then return triggeredAny or removedAnyMonster or removedAnyTrap end
        return StartTrapRefillDrop()
    end
    if (triggeredAny or removedAnyMonster) and startDrop ~= false and StartEnemyDropAnimation ~= nil then
        local drops = DropAndRefillBoard()
        local heroMoved = dropHeroMoved_
        return StartEnemyDropAnimation(drops, 0, "monster", heroMoved)
    end
    if startDrop ~= false then
        EnsureBoardHasMove()
    end
    return triggeredAny or removedAnyMonster
end

function FireTurrets(startDrop)
    local killedAny = false
    local removedTurret = false
    for i = #traps_, 1, -1 do
        local trap = traps_[i]
        if trap.kind == "turret" then
            local nearest = FindNearestMonster(trap)
            if nearest then
                trap.angle = math.atan(nearest.row - trap.row, nearest.col - trap.col)
                AddItemTriggerEffect("turret", trap.row, trap.col, nearest.row, nearest.col)
                local damage = GetRogueItemDamage(CONFIG.turretDamage)
                AddCannonShell(trap, nearest, damage)
            end
            trap.turns = trap.turns - 1
            if trap.turns <= 0 then
                table.remove(traps_, i)
                removedTurret = true
                pendingItemBoardRefill_ = true
            end
        end
    end
    local removedAny = false
    if isItemTurnResolving_ then
        if killedAny then pendingItemBoardRefill_ = true end
    else
        removedAny = RemoveDeadMonsters()
    end
    if removedTurret then
        if startDrop == false then return killedAny or removedAny or removedTurret end
        return StartTrapRefillDrop()
    end
    if (killedAny or removedAny) and startDrop ~= false and StartEnemyDropAnimation ~= nil then
        local drops = DropAndRefillBoard()
        local heroMoved = dropHeroMoved_
        return StartEnemyDropAnimation(drops, 0, "monster", heroMoved)
    end
    if startDrop ~= false then
        EnsureBoardHasMove()
    end
    return killedAny or removedAny
end

function DamageHero(amount, sourceRow, sourceCol, attackers)
    if gameState_ ~= "playing" then return end
    hero_.hpBuffer = math.max(hero_.hpBuffer or hero_.hp or 0, hero_.hp or 0)
    hero_.hp = hero_.hp - amount
    AddOperationLog("怪物攻击：" .. FormatAttackerList(attackers) .. " 对玩家造成 " .. tostring(amount) .. " 点伤害，玩家生命 " .. tostring(math.max(0, hero_.hp)) .. "/" .. tostring(hero_.maxHp))
    AddHeroDamageHudParticles(amount)
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

function GetMonsterFallbackMoveCell(index, monster)
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
            return cell
        end
    end
    return nil
end

function GetMonsterNextMoveCell(index, monster)
    local pathStep = FindMonsterPathStep(index, monster)
    if pathStep then return pathStep end
    return GetMonsterFallbackMoveCell(index, monster)
end

function GetMonsterAttackDamage(monster)
    return math.max(1, monster and monster.attack or 1)
end

function CountPredictedAttackersBefore(monsterIndex)
    local count = 0
    local maxAttackers = CONFIG.maxMonsterAttackersPerTurn or 3
    local nextMonsterTurnId = turnId_ + 1
    for index = 1, monsterIndex - 1 do
        local monster = monsters_[index]
        if monster ~= nil and monster.hp > 0 and count < maxAttackers then
            if IsInCrossRange(monster.row, monster.col, hero_.row, hero_.col, 1) and monster.lastAttackTurn ~= nextMonsterTurnId then
                count = count + 1
            end
        end
    end
    return count
end

function PredictMonsterIntent(index, monster)
    if gameState_ ~= "playing" or monster == nil or monster.hp <= 0 then return nil end
    local maxAttackers = CONFIG.maxMonsterAttackersPerTurn or 3
    if CountPredictedAttackersBefore(index) >= maxAttackers then return nil end

    if IsInCrossRange(monster.row, monster.col, hero_.row, hero_.col, 1) then
        if monster.lastAttackTurn ~= turnId_ + 1 then
            return { kind = "attack", damage = GetMonsterAttackDamage(monster) }
        end
        return nil
    end

    local cell = GetMonsterNextMoveCell(index, monster)
    if cell ~= nil then
        return {
            kind = "move",
            row = cell.row,
            col = cell.col,
            dr = cell.row - monster.row,
            dc = cell.col - monster.col,
        }
    end
    return nil
end

function TryMoveMonster(index, monster)
    local cell = GetMonsterNextMoveCell(index, monster)
    if cell then
        MoveMonsterToCell(monster, cell)
        return true
    end
    return false
end

function MonsterTurn()
    if gameState_ ~= "playing" then return end
    local attackers = 0
    local totalDamage = 0
    local attackerList = {}
    local maxAttackers = CONFIG.maxMonsterAttackersPerTurn or 3

    for index, monster in ipairs(monsters_) do
        if monster.hp > 0 and attackers < maxAttackers then
            if IsInCrossRange(monster.row, monster.col, hero_.row, hero_.col, 1) then
                if monster.lastAttackTurn ~= turnId_ then
                    monster.lastAttackTurn = turnId_
                    attackers = attackers + 1
                    totalDamage = totalDamage + GetMonsterAttackDamage(monster)
                    table.insert(attackerList, monster)
                end
            else
                TryMoveMonster(index, monster)
                if CheckTriggeredTraps() then return end
            end
        end
    end

    if attackers > 0 then
        for _, monster in ipairs(monsters_) do
            if monster.hp > 0 and IsInCrossRange(monster.row, monster.col, hero_.row, hero_.col, 1) then
                MarkMonsterAttack3D(monster)
            end
        end
        DamageHero(totalDamage, hero_.row, hero_.col, attackerList)
        SetMessage("怪物逼近并攻击玩家。通过消除和道具清理威胁", 2.0)
    end
    StartWaitMonsterMovesThenResolve()
end
