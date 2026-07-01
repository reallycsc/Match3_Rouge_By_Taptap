local G = require "Game.Context"
local _ENV = G
---@diagnostic disable: undefined-global

function CreateTurnBanner(text, kind, onComplete)
    return {
        text = text,
        kind = kind or "player",
        life = 1.28,
        maxLife = 1.28,
        onComplete = onComplete,
    }
end

function StartNextTurnBanner()
    if #turnBannerQueue_ > 0 then
        local nextBanner = table.remove(turnBannerQueue_, 1)
        turnBanner_ = CreateTurnBanner(nextBanner.text, nextBanner.kind, nextBanner.onComplete)
        return true
    end
    return false
end

function ShowTurnBanner(text, kind, onComplete)
    local bannerKind = kind or "player"
    if turnBanner_ ~= nil then
        local lastQueued = turnBannerQueue_[#turnBannerQueue_]
        if onComplete == nil and ((turnBanner_.text == text and turnBanner_.kind == bannerKind) or (lastQueued ~= nil and lastQueued.text == text and lastQueued.kind == bannerKind)) then
            return
        end
        table.insert(turnBannerQueue_, { text = text, kind = bannerKind, onComplete = onComplete })
        return
    end
    turnBanner_ = CreateTurnBanner(text, bannerKind, onComplete)
end

function CompleteTurnBanner(banner)
    if banner ~= nil and banner.onComplete ~= nil then
        local callback = banner.onComplete
        banner.onComplete = nil
        callback()
    end
end

function UpdateTurnBanner(timeStep)
    if turnBanner_ == nil then
        StartNextTurnBanner()
        return
    end
    turnBanner_.life = turnBanner_.life - timeStep
    if turnBanner_.life <= 0 then
        local completed = turnBanner_
        turnBanner_ = nil
        CompleteTurnBanner(completed)
        StartNextTurnBanner()
    end
end

function SwapCells(a, b)
    if OccupiedByBoardBlocker(a.row, a.col) or OccupiedByBoardBlocker(b.row, b.col) then return end
    board_[a.row][a.col], board_[b.row][b.col] = board_[b.row][b.col], board_[a.row][a.col]
end

function HasPendingItemAnimations()
    return #laserBeams_ > 0
        or #bombExplosions_ > 0
        or #cannonShells_ > 0
        or #missiles_ > 0
        or #missileLaunches_ > 0
        or #itemTriggerEffects_ > 0
end

function StartMonsterTurnAfterItemAnimations()
    if HasPendingItemAnimations() then
        isAnimating_ = true
        pendingMonsterTurn_ = true
        currentAnim_ = {
            kind = "waitItems",
            elapsed = 0,
            duration = 0.05,
        }
    else
        FinishItemTurnAndStartMonsterTurn()
    end
end

function StartMonsterTurnAfterBanner()
    waitingMonsterTurnBanner_ = false
    MonsterTurn()
    if not isAnimating_ then
        BeginPlayerTurn()
    end
end

function BeginMonsterTurnAfterBanner()
    waitingMonsterTurnBanner_ = true
    ShowTurnBanner("怪物回合", "monster", StartMonsterTurnAfterBanner)
end

function FinishItemTurnAndStartMonsterTurn()
    pendingMonsterTurn_ = false
    isItemTurnResolving_ = false
    local removedAny = RemoveDeadMonsters()
    if pendingItemBoardRefill_ or removedAny then
        pendingItemBoardRefill_ = false
        local drops = DropAndRefillBoard()
        local heroMoved = dropHeroMoved_
        if #drops > 0 then
            StartEnemyDropAnimation(drops, 0, "item", heroMoved)
            return
        end
    end
    BeginMonsterTurnAfterBanner()
end

function RunItemTurn()
    turnId_ = turnId_ + 1
    pendingItemBoardRefill_ = false
    isItemTurnResolving_ = true
    FireMissileSilos(false)
    FireTurrets(false)
    CheckTriggeredTraps(false)
end

function BeginPlayerTurn()
    if isAnimating_ or currentAnim_ ~= nil then return end
    ShowTurnBanner("玩家回合", "player")
    EnsureBoardHasMove()
end

function StartWaitMonsterMovesThenResolve()
    if #monsterMoves_ > 0 then
        isAnimating_ = true
        currentAnim_ = {
            kind = "waitMonsterMoves",
            elapsed = 0,
            duration = 0.05,
        }
    elseif not EnsureBoardStable(1, "monster") then
        BeginPlayerTurn()
    end
end

function FinishPlayerMove()
    isAnimating_ = false
    currentAnim_ = nil
    pendingMove_ = false
    moves_ = moves_ + 1
    RunItemTurn()
    StartMonsterTurnAfterItemAnimations()
end

function FinishPhaseChain(phase)
    isAnimating_ = false
    currentAnim_ = nil
    if phase == "item" then
        FinishItemTurnAndStartMonsterTurn()
    elseif phase == "monster" then
        StartWaitMonsterMovesThenResolve()
    else
        FinishPlayerMove()
    end
end

function FinishEnemyBoardDrop(anim)
    if anim ~= nil and anim.resolved then return end
    if anim ~= nil then anim.resolved = true end
    isAnimating_ = false
    currentAnim_ = nil

    local matches, specials = FindMatches()
    if #matches > 0 and (anim and anim.combo or 0) < MAX_CASCADE_COMBO then
        StartClearAnimation(matches, (anim and anim.combo or 0) + 1, specials, nil, anim and anim.phase or nil)
    else
        FinishPhaseChain(anim and anim.phase or nil)
    end
end

function StartClearAnimation(matches, combo, specials, preferredCells, phase)
    isAnimating_ = true
    currentAnim_ = {
        kind = "clear",
        elapsed = 0,
        duration = CLEAR_DURATION,
        matches = matches,
        specials = specials or {},
        combo = combo,
        preferredCells = preferredCells,
        phase = phase or "player",
    }
end

StartAutoClearAnimation = function(matches, combo, specials, preferredCells, phase)
    StartClearAnimation(matches, combo, specials, preferredCells, phase)
end

function StartDropAnimation(drops, combo, phase, heroMoved)
    isAnimating_ = true
    currentAnim_ = {
        kind = "drop",
        elapsed = 0,
        duration = DROP_DURATION,
        drops = drops,
        combo = combo,
        phase = phase or "player",
        heroMoved = heroMoved == true,
    }
end

StartEnemyDropAnimation = function(drops, combo, phase, heroMoved)
    if #drops == 0 then
        FinishEnemyBoardDrop({ combo = combo or 0, phase = phase or "monster", heroMoved = heroMoved == true })
        return true
    end
    isAnimating_ = true
    currentAnim_ = {
        kind = "enemyDrop",
        elapsed = 0,
        duration = DROP_DURATION,
        drops = drops,
        combo = combo or 0,
        phase = phase or "monster",
        heroMoved = heroMoved == true,
    }
    return true
end

function StartItemSwapTriggerAnimation(a, b, objA, objB)
    isAnimating_ = true
    currentAnim_ = {
        kind = "itemSwapTrigger",
        elapsed = 0,
        duration = SWAP_DURATION,
        a = { row = a.row, col = a.col },
        b = { row = b.row, col = b.col },
        objA = objA,
        objB = objB,
    }
end

function StartSwapAnimation(a, b, reverse)
    local typeA = board_[a.row][a.col]
    local typeB = board_[b.row][b.col]
    if not reverse then
        lastSwapDropDir_ = { row = b.row - a.row, col = b.col - a.col }
    end
    isAnimating_ = true
    currentAnim_ = {
        kind = "swap",
        elapsed = 0,
        duration = SWAP_DURATION,
        a = { row = a.row, col = a.col },
        b = { row = b.row, col = b.col },
        typeA = typeA,
        typeB = typeB,
        reverse = reverse or false,
    }
end

function StartSwapBackAnimation(anim)
    isAnimating_ = true
    currentAnim_ = {
        kind = "swap",
        elapsed = 0,
        duration = SWAP_DURATION,
        a = anim.a,
        b = anim.b,
        typeA = anim.typeA,
        typeB = anim.typeB,
        reverse = true,
    }
end

function UpdateAnimation(timeStep)
    if currentAnim_ == nil then return end

    currentAnim_.elapsed = currentAnim_.elapsed + timeStep
    if currentAnim_.elapsed < currentAnim_.duration then return end

    local anim = currentAnim_
    if anim.kind == "swap" then
        if anim.reverse then
            SwapCells(anim.a, anim.b)
            selected_ = anim.b
            isAnimating_ = false
            currentAnim_ = nil
            SetMessage("无效交换：需要形成三消", 1.3)
            AddFloatText(anim.b.row, anim.b.col, "无效", { 190, 190, 190, 255 })
            return
        end

        local matches, specials = FindMatches()
        if #matches > 0 then
            selected_ = nil
            StartClearAnimation(matches, 1, specials, { anim.a, anim.b }, "player")
        else
            StartSwapBackAnimation(anim)
        end
    elseif anim.kind == "itemSwapTrigger" then
        isAnimating_ = false
        currentAnim_ = nil
        if SwapBoardObjects(anim.a, anim.b) then
            local triggerTrap = nil
            if anim.objA.kind == "trap" and IsTriggerTrapKind(anim.objA.ref.kind) then
                triggerTrap = anim.objA.ref
            elseif anim.objB.kind == "trap" and IsTriggerTrapKind(anim.objB.ref.kind) then
                triggerTrap = anim.objB.ref
            end
            if triggerTrap ~= nil then
                TriggerTrapManually(triggerTrap)
            end
        end
    elseif anim.kind == "clear" then
        ApplyMatchDamage(anim.matches, anim.combo, anim.specials, anim.preferredCells)
        for _, cell in ipairs(anim.matches) do
            board_[cell.row][cell.col] = 0
        end
        local drops = DropAndRefillBoard()
        local heroMoved = dropHeroMoved_
        StartDropAnimation(drops, anim.combo, anim.phase, heroMoved)
    elseif anim.kind == "drop" then
        local matches, specials = FindMatches()
        if #matches > 0 and anim.combo < MAX_CASCADE_COMBO then
            StartClearAnimation(matches, anim.combo + 1, specials, nil, anim.phase)
        else
            FinishPhaseChain(anim.phase)
        end
    elseif anim.kind == "enemyDrop" then
        FinishEnemyBoardDrop(anim)
    elseif anim.kind == "waitItems" then
        if HasPendingItemAnimations() then
            anim.elapsed = 0
            return
        end
        isAnimating_ = false
        currentAnim_ = nil
        if pendingMonsterTurn_ then
            FinishItemTurnAndStartMonsterTurn()
        end
    elseif anim.kind == "waitMonsterMoves" then
        if #monsterMoves_ > 0 then
            anim.elapsed = 0
            return
        end
        isAnimating_ = false
        currentAnim_ = nil
        if not EnsureBoardStable(1, "monster") then
            BeginPlayerTurn()
        end
    end
end

function TrySwap(a, b)
    if gameState_ ~= "playing" or isAnimating_ or waitingMonsterTurnBanner_ then return end
    hintCells_ = {}
    hintScore_ = 0
    if not IsAdjacent(a, b) then
        selected_ = b
        return
    end

    local objA = BoardObjectAt(a.row, a.col)
    local objB = BoardObjectAt(b.row, b.col)
    if objA == nil or objB == nil then
        selected_ = nil
        SetMessage("空格不能交换", 1.2)
        return
    end

    if objA.kind ~= "gem" or objB.kind ~= "gem" then
        if CanSwapBoardObjects(a, b) then
            selected_ = nil
            lastTapCell_ = nil
            local triggerTrap = nil
            if objA.kind == "trap" and IsTriggerTrapKind(objA.ref.kind) then
                triggerTrap = objA.ref
            elseif objB.kind == "trap" and IsTriggerTrapKind(objB.ref.kind) then
                triggerTrap = objB.ref
            end
            if triggerTrap ~= nil then
                StartItemSwapTriggerAnimation(a, b, objA, objB)
            else
                hero_.attackFlash = 0.42
                pendingMove_ = true
                local matches, specials = FindMatches()
                if #matches > 0 then
                    StartClearAnimation(matches, 1, specials, { a, b }, "player")
                else
                    FinishPlayerMove()
                end
            end
        else
            selected_ = nil
            SetMessage("炮台和导弹井不能交换位置", 1.4)
        end
        return
    end

    SwapCells(a, b)
    hero_.attackFlash = 0.42
    pendingMove_ = true
    selected_ = nil
    StartSwapAnimation(a, b, false)
end

function ScreenToCell(inputX, inputY)
    local cell3D = ScreenToBoardCell3D(inputX, inputY)
    if cell3D ~= nil then return cell3D end

    local x = inputX / dpr_
    local y = inputY / dpr_
    if x < boardX_ or y < boardY_ or x > boardX_ + boardPixels_ or y > boardY_ + boardPixels_ then
        return nil
    end

    local localX = x - boardX_
    local localY = y - boardY_
    local stride = tile_ + gap_
    local col = math.floor(localX / stride) + 1
    local row = math.floor(localY / stride) + 1
    if not IsValidCell(row, col) then return nil end

    local inCellX = localX - (col - 1) * stride
    local inCellY = localY - (row - 1) * stride
    if inCellX > tile_ or inCellY > tile_ then return nil end
    return { row = row, col = col }
end

function TryMoveHero(rowDelta, colDelta)
    if gameState_ ~= "playing" or isAnimating_ or waitingMonsterTurnBanner_ then return end
    SetMessage("主角镇守棋盘中心，不能移动", 1.3)
end

function UpdateEffects(timeStep)
    if messageTimer_ > 0 then
        messageTimer_ = messageTimer_ - timeStep
    end
    if screenShake_ > 0 then
        screenShake_ = math.max(0, screenShake_ - timeStep * 24)
    end

    if hero_.hpBuffer == nil then
        hero_.hpBuffer = hero_.hp
    elseif hero_.hpBuffer > hero_.hp then
        hero_.hpBuffer = math.max(hero_.hp, hero_.hpBuffer - timeStep * math.max(5.0, hero_.maxHp * 0.95))
    elseif hero_.hpBuffer < hero_.hp then
        hero_.hpBuffer = hero_.hp
    end

    for _, monster in ipairs(monsters_) do
        if monster.hpBuffer == nil then
            monster.hpBuffer = monster.hp
        elseif monster.hpBuffer > monster.hp then
            monster.hpBuffer = math.max(monster.hp, monster.hpBuffer - timeStep * math.max(2.5, monster.maxHp * 1.8))
        elseif monster.hpBuffer < monster.hp then
            monster.hpBuffer = monster.hp
        end
    end

    for i = #floatTexts_, 1, -1 do
        local item = floatTexts_[i]
        item.life = item.life - timeStep
        item.y = item.y + item.vy * timeStep
        if item.life <= 0 then
            table.remove(floatTexts_, i)
        end
    end

    for i = #particles_, 1, -1 do
        local item = particles_[i]
        item.life = item.life - timeStep
        item.x = item.x + item.vx * timeStep
        item.y = item.y + item.vy * timeStep
        item.vy = item.vy + 120 * timeStep
        if item.life <= 0 then
            table.remove(particles_, i)
        end
    end

    for i = #hudDamageParticles_, 1, -1 do
        local item = hudDamageParticles_[i]
        item.life = item.life - timeStep
        item.x = item.x + item.vx * timeStep
        item.y = item.y + item.vy * timeStep
        item.vy = item.vy + 180 * timeStep
        if item.life <= 0 then
            table.remove(hudDamageParticles_, i)
        end
    end

    for i = #matchEffects_, 1, -1 do
        local item = matchEffects_[i]
        item.life = item.life - timeStep
        if item.life <= 0 then
            table.remove(matchEffects_, i)
        end
    end

    if pendingHeroDrop_ ~= nil then
        pendingHeroDrop_.life = pendingHeroDrop_.life - timeStep
        if pendingHeroDrop_.life <= 0 then
            pendingHeroDrop_ = nil
        end
    end

    for i = #laserBeams_, 1, -1 do
        local item = laserBeams_[i]
        item.life = item.life - timeStep
        if item.life <= 0 then
            table.remove(laserBeams_, i)
        end
    end

    for i = #bombExplosions_, 1, -1 do
        local item = bombExplosions_[i]
        item.life = item.life - timeStep
        if item.life <= 0 then
            table.remove(bombExplosions_, i)
        end
    end

    for i = #cannonShells_, 1, -1 do
        local item = cannonShells_[i]
        item.life = item.life - timeStep
        if item.sourceRow ~= nil and item.sourceCol ~= nil and ItemHudPoint3D ~= nil then
            local fromPoint = ItemHudPoint3D(item.sourceRow, item.sourceCol, 0.62)
            if fromPoint ~= nil then
                item.fromX = fromPoint.x
                item.fromY = fromPoint.y
            end
        end
        if item.targetMonster ~= nil and item.targetMonster.hp > 0 and BoardHudPoint3D ~= nil then
            local targetPoint = BoardHudPoint3D(item.targetMonster.row, item.targetMonster.col, 0.36)
            if targetPoint ~= nil then
                item.toX = targetPoint.x
                item.toY = targetPoint.y
            end
        end
        local t = 1 - Clamp(item.life / item.maxLife, 0, 1)
        item.x = Lerp(item.fromX, item.toX, EaseInOut(t))
        item.y = Lerp(item.fromY, item.toY, EaseInOut(t))
        if item.life <= 0 then
            if not item.resolved and item.targetMonster ~= nil and item.targetMonster.hp > 0 then
                item.resolved = true
                DamageMonster(item.targetMonster, item.damage or CONFIG.turretDamage, "炮击-", item.source)
                if item.targetMonster.hp <= 0 then
                    pendingItemBoardRefill_ = true
                end
            end
            table.remove(cannonShells_, i)
        end
    end

    for i = #missiles_, 1, -1 do
        local item = missiles_[i]
        item.life = item.life - timeStep
        local raw = 1 - Clamp(item.life / item.maxLife, 0, 1)
        local delay = item.launchDelay or 0
        local flyDuration = math.max(0.01, item.maxLife - delay)
        local t = Clamp((raw * item.maxLife - delay) / flyDuration, 0, 1)
        local eased = EaseInOut(t)
        local arc = math.sin(t * math.pi) * tile_ * 1.05 * (item.arcMul or 1.0)
        item.scale = 0.25 + math.sin(t * math.pi) * 0.95 + t * 0.18
        item.alpha = Clamp(raw / math.max(delay, 0.01), 0, 1)
        item.x = Lerp(item.fromX, item.toX, eased)
        item.y = Lerp(item.fromY, item.toY, eased) - arc
        if item.life <= 0 then
            table.remove(missiles_, i)
        end
    end

    for i = #missileLaunches_, 1, -1 do
        local item = missileLaunches_[i]
        item.life = item.life - timeStep
        if item.life <= 0 then
            table.remove(missileLaunches_, i)
        end
    end

    for i = #itemTriggerEffects_, 1, -1 do
        local item = itemTriggerEffects_[i]
        item.life = item.life - timeStep
        if item.life <= 0 then
            table.remove(itemTriggerEffects_, i)
        end
    end

    for _, item in ipairs(missileSilos_) do
        item.age = (item.age or 0) + timeStep
    end

    for i = #monsterMoves_, 1, -1 do
        local item = monsterMoves_[i]
        item.life = item.life - timeStep
        if item.life <= 0 then
            table.remove(monsterMoves_, i)
        end
    end
end

function UpdatePanelAnimations(timeStep)
    local target = operationLogVisible_ and 1 or 0
    local speed = timeStep * 8.0
    if operationLogAnim_ < target then
        operationLogAnim_ = math.min(target, operationLogAnim_ + speed)
    elseif operationLogAnim_ > target then
        operationLogAnim_ = math.max(target, operationLogAnim_ - speed)
    end
end

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local timeStep = eventData["TimeStep"]:GetFloat()
    time_ = time_ + timeStep
    UpdateAutoAimTargets()
    UpdateEffects(timeStep)
    UpdatePanelAnimations(timeStep)
    UpdateTurnBanner(timeStep)
    UpdateAnimation(timeStep)
    TryOpenPendingRogueReward()
    UpdateScene3D(timeStep)
end

function HandleCellPressed(cell)
    if waitingMonsterTurnBanner_ then return end
    if cell == nil then return end
    dragStart_ = cell
    dragTriggered_ = false
end

function IsDoubleTapCell(cell)
    return lastTapCell_ ~= nil
        and lastTapCell_.row == cell.row
        and lastTapCell_.col == cell.col
        and (time_ - (lastTapCell_.time or 0)) <= 0.35
end

function RememberTapCell(cell)
    lastTapCell_ = { row = cell.row, col = cell.col, time = time_ }
end

function HandleCellReleased(cell)
    if waitingMonsterTurnBanner_ then return end
    if dragTriggered_ then
        dragStart_ = nil
        dragTriggered_ = false
        return
    end
    if cell == nil then
        dragStart_ = nil
        return
    end

    if selected_ ~= nil and (selected_.row ~= cell.row or selected_.col ~= cell.col) then
        TrySwap(selected_, cell)
        RememberTapCell(cell)
    elseif selected_ ~= nil and selected_.row == cell.row and selected_.col == cell.col then
        if TryTriggerTrapCell(cell) then
            lastTapCell_ = nil
        else
            selected_ = cell
            RememberTapCell(cell)
        end
    else
        selected_ = cell
        RememberTapCell(cell)
    end
    dragStart_ = nil
end

function HandleCellDragged(cell)
    if waitingMonsterTurnBanner_ then return end
    if dragStart_ == nil or dragTriggered_ or cell == nil then return end
    if isAnimating_ or gameState_ ~= "playing" then return end
    if cell.row == dragStart_.row and cell.col == dragStart_.col then return end
    if IsAdjacent(dragStart_, cell) then
        dragTriggered_ = true
        selected_ = nil
        TrySwap(dragStart_, cell)
    end
end

---@param eventType string
---@param eventData MouseButtonDownEventData
function HandleMouseButtonDown(eventType, eventData)
    if gameState_ == "gameover" then
        ResetGame()
        return
    end

    local button = eventData["Button"]:GetInt()
    if button ~= MOUSEB_LEFT then return end

    if HandleUiPress(eventData["X"]:GetInt(), eventData["Y"]:GetInt()) then return end
    if isAnimating_ then return end

    HandleCellPressed(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
end

---@param eventType string
---@param eventData MouseButtonUpEventData
function HandleMouseButtonUp(eventType, eventData)
    local button = eventData["Button"]:GetInt()
    if button ~= MOUSEB_LEFT then return end
    if operationLogDragging_ then
        StopOperationLogDrag()
        uiPressConsumed_ = false
        return
    end
    if isAnimating_ then return end
    if uiPressConsumed_ then
        uiPressConsumed_ = false
        dragStart_ = nil
        dragTriggered_ = false
        return
    end
    HandleCellReleased(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
end

---@param eventType string
---@param eventData MouseMoveEventData
function HandleMouseMove(eventType, eventData)
    if UpdateOperationLogDrag(eventData["Y"]:GetInt()) then return end
    if isAnimating_ then return end
    HandleCellDragged(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
end

---@param eventType string
---@param eventData TouchBeginEventData
function HandleTouchBegin(eventType, eventData)
    if gameState_ == "gameover" then
        ResetGame()
        return
    end

    if HandleUiPress(eventData["X"]:GetInt(), eventData["Y"]:GetInt()) then return end
    if isAnimating_ then return end

    HandleCellPressed(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
end

---@param eventType string
---@param eventData TouchMoveEventData
function HandleTouchMove(eventType, eventData)
    if UpdateOperationLogDrag(eventData["Y"]:GetInt()) then return end
end

---@param eventType string
---@param eventData TouchEndEventData
function HandleTouchEnd(eventType, eventData)
    if operationLogDragging_ then
        StopOperationLogDrag()
        uiPressConsumed_ = false
    end
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    if key == KEY_R then
        ResetGame()
    elseif key == KEY_L then
        ToggleLeaderboard()
    elseif key == KEY_W or key == KEY_UP or key == KEY_S or key == KEY_DOWN or key == KEY_A or key == KEY_LEFT or key == KEY_D or key == KEY_RIGHT then
        SetMessage("主角镇守棋盘中心，不能移动", 1.3)
    end
end

function HandleScreenMode(eventType, eventData)
    RecalcLayout()
end
