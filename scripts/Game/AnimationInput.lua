local G = require "Game.Context"
local _ENV = G
---@diagnostic disable: undefined-global

function SwapCells(a, b)
    if OccupiedByBoardBlocker(a.row, a.col) or OccupiedByBoardBlocker(b.row, b.col) then return end
    board_[a.row][a.col], board_[b.row][b.col] = board_[b.row][b.col], board_[a.row][a.col]
end

function FinishPlayerMove()
    isAnimating_ = false
    currentAnim_ = nil
    pendingMove_ = false
    moves_ = moves_ + 1
    MonsterTurn()
    if not isAnimating_ then
        EnsureBoardHasMove()
    end
end

function FinishEnemyBoardDrop(anim)
    isAnimating_ = false
    currentAnim_ = nil

    local matches, specials = FindMatches()
    if #matches > 0 then
        StartClearAnimation(matches, (anim and anim.combo or 0) + 1, specials, nil)
    else
        EnsureBoardHasMove()
    end
end

function StartClearAnimation(matches, combo, specials, preferredCells)
    isAnimating_ = true
    currentAnim_ = {
        kind = "clear",
        elapsed = 0,
        duration = CLEAR_DURATION,
        matches = matches,
        specials = specials or {},
        combo = combo,
        preferredCells = preferredCells,
    }
end

StartAutoClearAnimation = function(matches, combo, specials, preferredCells)
    StartClearAnimation(matches, combo, specials, preferredCells)
end

function StartDropAnimation(drops, combo)
    isAnimating_ = true
    currentAnim_ = {
        kind = "drop",
        elapsed = 0,
        duration = DROP_DURATION,
        drops = drops,
        combo = combo,
    }
end

StartEnemyDropAnimation = function(drops, combo)
    if #drops == 0 then
        FinishEnemyBoardDrop({ combo = combo or 0 })
        return true
    end
    isAnimating_ = true
    currentAnim_ = {
        kind = "enemyDrop",
        elapsed = 0,
        duration = DROP_DURATION,
        drops = drops,
        combo = combo or 0,
    }
    return true
end

function StartSwapAnimation(a, b, reverse)
    local typeA = board_[a.row][a.col]
    local typeB = board_[b.row][b.col]
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
            StartClearAnimation(matches, 1, specials, { anim.a, anim.b })
        else
            StartSwapBackAnimation(anim)
        end
    elseif anim.kind == "clear" then
        ApplyMatchDamage(anim.matches, anim.combo, anim.specials, anim.preferredCells)
        for _, cell in ipairs(anim.matches) do
            board_[cell.row][cell.col] = 0
        end
        local drops = DropAndRefillBoard()
        StartDropAnimation(drops, anim.combo)
    elseif anim.kind == "drop" then
        local matches, specials = FindMatches()
        if #matches > 0 and anim.combo < MAX_CASCADE_COMBO then
            StartClearAnimation(matches, anim.combo + 1, specials, nil)
        else
            FinishPlayerMove()
        end
    elseif anim.kind == "enemyDrop" then
        FinishEnemyBoardDrop(anim)
    end
end

function TrySwap(a, b)
    if gameState_ ~= "playing" or isAnimating_ then return end
    hintCells_ = {}
    hintScore_ = 0
    if OccupiedByBoardBlocker(a.row, a.col) or OccupiedByBoardBlocker(b.row, b.col) then
        selected_ = nil
        SetMessage("主角、怪物和陷阱所在格不能交换", 1.4)
        return
    end
    if not IsAdjacent(a, b) then
        selected_ = b
        return
    end

    if board_[a.row][a.col] == 0 or board_[b.row][b.col] == 0 then
        selected_ = nil
        SetMessage("空格不能交换", 1.2)
        return
    end

    SwapCells(a, b)
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
    if gameState_ ~= "playing" or isAnimating_ then return end
    local nextRow = hero_.row + rowDelta
    local nextCol = hero_.col + colDelta
    if not IsValidCell(nextRow, nextCol) then return end
    if HasMonsterAt(nextRow, nextCol) then
        SetMessage("被怪物挡住了。先用三消消灭它", 1.5)
        return
    end

    hero_.row = nextRow
    hero_.col = nextCol
    selected_ = nil
    moves_ = moves_ + 1
    SetMessage("主角移动，怪物也开始逼近", 1.2)
    MonsterTurn()
end

function UpdateEffects(timeStep)
    if messageTimer_ > 0 then
        messageTimer_ = messageTimer_ - timeStep
    end
    if screenShake_ > 0 then
        screenShake_ = math.max(0, screenShake_ - timeStep * 24)
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

    for i = #matchEffects_, 1, -1 do
        local item = matchEffects_[i]
        item.life = item.life - timeStep
        if item.life <= 0 then
            table.remove(matchEffects_, i)
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
        local t = 1 - Clamp(item.life / item.maxLife, 0, 1)
        item.x = Lerp(item.fromX, item.toX, EaseInOut(t))
        item.y = Lerp(item.fromY, item.toY, EaseInOut(t))
        if item.life <= 0 then
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

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local timeStep = eventData["TimeStep"]:GetFloat()
    time_ = time_ + timeStep
    UpdateAutoAimTargets()
    UpdateEffects(timeStep)
    UpdateAnimation(timeStep)
    UpdateScene3D(timeStep)
end

function HandleCellPressed(cell)
    if cell == nil then return end
    dragStart_ = cell
    dragTriggered_ = false
    selected_ = cell
end

function HandleCellReleased(cell)
    if dragTriggered_ then
        dragStart_ = nil
        dragTriggered_ = false
        return
    end
    if cell == nil then
        dragStart_ = nil
        return
    end

    if selected_ == nil then
        selected_ = cell
    elseif selected_.row == cell.row and selected_.col == cell.col then
        selected_ = cell
    else
        TrySwap(selected_, cell)
    end
    dragStart_ = nil
end

function HandleCellDragged(cell)
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
    if isAnimating_ then return end
    if gameState_ == "gameover" then
        ResetGame()
        return
    end

    local button = eventData["Button"]:GetInt()
    if button ~= MOUSEB_LEFT then return end

    HandleCellPressed(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
end

---@param eventType string
---@param eventData MouseButtonUpEventData
function HandleMouseButtonUp(eventType, eventData)
    if isAnimating_ then return end
    local button = eventData["Button"]:GetInt()
    if button ~= MOUSEB_LEFT then return end
    HandleCellReleased(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
end

---@param eventType string
---@param eventData MouseMoveEventData
function HandleMouseMove(eventType, eventData)
    if isAnimating_ then return end
    HandleCellDragged(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
end

---@param eventType string
---@param eventData TouchBeginEventData
function HandleTouchBegin(eventType, eventData)
    if isAnimating_ then return end
    if gameState_ == "gameover" then
        ResetGame()
        return
    end

    HandleCellPressed(ScreenToCell(eventData["X"]:GetInt(), eventData["Y"]:GetInt()))
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
