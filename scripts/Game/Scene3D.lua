local G = require "Game.Context"
local _ENV = G
---@diagnostic disable: undefined-global

local function ToColor255(c)
    return Color((c[1] or 255) / 255, (c[2] or 255) / 255, (c[3] or 255) / 255, (c[4] or 255) / 255)
end

function CreatePBRMaterial3D(name, color, metallic, roughness, emissiveMul)
    if materials3D_[name] ~= nil then return materials3D_[name] end
    local mat = Material:new()
    mat:SetTechnique(0, cache:GetResource("Technique", "Techniques/PBR/PBRNoTexture.xml"))
    mat:SetShaderParameter("MatDiffColor", Variant(color))
    mat:SetShaderParameter("MatSpecColor", Variant(Color(0.45, 0.45, 0.45, 1.0)))
    mat:SetShaderParameter("Metallic", Variant(metallic or 0.0))
    mat:SetShaderParameter("Roughness", Variant(roughness or 0.6))
    if emissiveMul and emissiveMul > 0 then
        mat:SetShaderParameter("MatEmissiveColor", Variant(Color(color.r * emissiveMul, color.g * emissiveMul, color.b * emissiveMul)))
    end
    materials3D_[name] = mat
    return mat
end

function GetRuneMaterial3D(gemType)
    local color = ToColor255(GEM_COLORS[gemType] or { 255, 255, 255, 255 })
    return CreatePBRMaterial3D("rune_" .. tostring(gemType), color, 0.0, 0.28, 0.45)
end

function GetRuneIconMaterial3D(gemType)
    local base = ToColor255(GEM_COLORS[gemType] or { 255, 255, 255, 255 })
    return CreatePBRMaterial3D("rune_icon_" .. tostring(gemType), Color(
        math.min(base.r * 1.7 + 0.15, 1.0),
        math.min(base.g * 1.7 + 0.15, 1.0),
        math.min(base.b * 1.7 + 0.15, 1.0),
        1.0
    ), 0.1, 0.18, 1.2)
end

function BoardToWorld(row, col)
    local cellSize = CONFIG.visual3D.cellSize
    local center = (BOARD_SIZE + 1) * 0.5
    return Vector3((col - center) * cellSize, CONFIG.visual3D.floorY, (center - row) * cellSize)
end

function BoardToWorldAt(row, col, y)
    local p = BoardToWorld(row, col)
    return Vector3(p.x, y, p.z)
end

function CreateScene3D()
    scene3D_ = Scene:new()
    scene3D_:CreateComponent("Octree")
    scene3D_:CreateComponent("DebugRenderer")

    local lightGroupFile = cache:GetResource("XMLFile", CONFIG.visual3D.lightGroup)
    if lightGroupFile ~= nil then
        local lightGroup = scene3D_:CreateChild("LightGroup")
        lightGroup:LoadXML(lightGroupFile:GetRoot())
        local zone = lightGroup:GetComponent("Zone", true)
        if zone ~= nil then
            zone.fogStart = 16.0
            zone.fogEnd = 42.0
        end
    end

    cameraNode3D_ = scene3D_:CreateChild("Camera")
    cameraNode3D_.position = CONFIG.visual3D.cameraPosition
    cameraNode3D_:LookAt(CONFIG.visual3D.cameraTarget)
    camera3D_ = cameraNode3D_:CreateComponent("Camera")
    camera3D_.nearClip = 0.1
    camera3D_.farClip = 90.0
    camera3D_.fov = 43.0
    renderer:SetViewport(0, Viewport:new(scene3D_, camera3D_))
    renderer.hdrRendering = true

    boardRoot3D_ = scene3D_:CreateChild("Board3D")
    CreateDungeonRoom3D()
    CreateRuneGrid3D()
    CreateHero3D()
    print("3D scene created: dungeon board, replaceable models and 3D runes ready")
end

function CreateDungeonRoom3D()
    local visual = CONFIG.visual3D
    local room = visual.room
    roomNode3D_ = boardRoot3D_:CreateChild("ReplaceableDungeonFloor")
    roomNode3D_.position = Vector3(0, visual.floorY - 0.04, 0)
    local boardWorldSize = visual.cellSize * BOARD_SIZE + 0.8
    local floorScaleX = boardWorldSize / room.sourceSize.x
    local floorScaleZ = boardWorldSize / room.sourceSize.z
    roomNode3D_.scale = Vector3(floorScaleX, room.thickness or 0.08, floorScaleZ)

    local model = roomNode3D_:CreateComponent("StaticModel")
    model:SetModel(cache:GetResource("Model", room.model))
    if #(room.materials or {}) > 0 then
        for index, matPath in ipairs(room.materials or {}) do
            model:SetMaterial(index - 1, cache:GetResource("Material", matPath))
        end
    else
        model:SetMaterial(CreatePBRMaterial3D("dungeon_floor", Color(0.30, 0.25, 0.20, 1.0), 0.0, 0.86, 0.0))
    end
    model.castShadows = true

    local wallMat = CreatePBRMaterial3D("dungeon_wall", Color(0.18, 0.16, 0.16, 1.0), 0.0, 0.88, 0.0)
    local half = boardWorldSize * 0.5 + 0.25
    local wallData = {
        { pos = Vector3(0, 0.75, half), scale = Vector3(boardWorldSize + 0.8, 1.5, 0.36) },
        { pos = Vector3(0, 0.75, -half), scale = Vector3(boardWorldSize + 0.8, 1.5, 0.36) },
        { pos = Vector3(half, 0.75, 0), scale = Vector3(0.36, 1.5, boardWorldSize + 0.8) },
        { pos = Vector3(-half, 0.75, 0), scale = Vector3(0.36, 1.5, boardWorldSize + 0.8) },
    }
    for _, wall in ipairs(wallData) do
        local node = boardRoot3D_:CreateChild("DungeonWall")
        node.position = wall.pos
        node.scale = wall.scale
        local wallModel = node:CreateComponent("StaticModel")
        wallModel:SetModel(cache:GetResource("Model", "Models/Box.mdl"))
        wallModel:SetMaterial(wallMat)
        wallModel.castShadows = true
    end
end

function ApplyModelMaterials3D(model, materials, fallbackMaterial)
    if #(materials or {}) == 0 then
        if fallbackMaterial ~= nil then
            model:SetMaterial(fallbackMaterial)
        end
        return
    end
    for index, matPath in ipairs(materials or {}) do
        local mat = cache:GetResource("Material", matPath)
        if mat ~= nil then
            model:SetMaterial(index - 1, mat)
        end
    end
end

function CreateHealthDisplay3D(parent, name, radius, topY, fillColor)
    local root = parent:CreateChild(name .. "HealthDisplay")
    root.position = Vector3(0, topY, 0)

    local bgNode = root:CreateChild("HealthBackground")
    local bg = bgNode:CreateComponent("StaticModel")
    bg:SetModel(cache:GetResource("Model", "Models/Cylinder.mdl"))
    bg:SetMaterial(CreatePBRMaterial3D(name .. "_hp_bg", Color(0.10, 0.10, 0.10, 1.0), 0.0, 0.55, 0.0))
    bgNode.scale = Vector3(radius * 2.08, 0.035, radius * 2.08)

    local wedgeNode = root:CreateChild("HealthWedge")
    wedgeNode.position = Vector3(0, 0.026, 0)
    local wedge = wedgeNode:CreateComponent("CustomGeometry")
    wedge.dynamic = true
    wedge:SetNumGeometries(1)
    wedge:SetMaterial(CreatePBRMaterial3D(name .. "_hp_fill", fillColor, 0.0, 0.45, 0.25))

    local textNode = root:CreateChild("HealthText")
    textNode.position = Vector3(0, 0.082, 0)
    textNode.rotation = Quaternion(90, Vector3.RIGHT)
    textNode.scale = Vector3(0.012, 0.012, 0.012)
    local text = textNode:CreateComponent("Text3D")
    text:SetFont("Fonts/MiSans-Regular.ttf", 28)
    text:SetAlignment(HA_CENTER, VA_CENTER)
    text:SetTextAlignment(HA_CENTER)
    text:SetColor(Color(1.0, 1.0, 1.0, 1.0))
    text:SetText("0")

    return {
        root = root,
        wedge = wedge,
        text = text,
        radius = radius,
    }
end

function UpdateHealthDisplay3D(display, hp, maxHp)
    if display == nil then return end
    local rate = Clamp((hp or 0) / math.max(1, maxHp or 1), 0, 1)
    local segments = math.max(3, math.ceil(36 * rate))
    local radius = display.radius
    display.wedge:Clear()
    display.wedge:SetNumGeometries(1)
    display.wedge:BeginGeometry(0, TRIANGLE_LIST)
    if rate > 0 then
        local startAngle = -math.pi * 0.5
        local totalAngle = math.pi * 2 * rate
        for i = 1, segments do
            local a1 = startAngle + totalAngle * (i - 1) / segments
            local a2 = startAngle + totalAngle * i / segments
            display.wedge:DefineVertex(Vector3(0, 0, 0))
            display.wedge:DefineNormal(Vector3.UP)
            display.wedge:DefineVertex(Vector3(math.cos(a1) * radius, 0, math.sin(a1) * radius))
            display.wedge:DefineNormal(Vector3.UP)
            display.wedge:DefineVertex(Vector3(math.cos(a2) * radius, 0, math.sin(a2) * radius))
            display.wedge:DefineNormal(Vector3.UP)
        end
    else
        display.wedge:DefineVertex(Vector3(0, 0, 0))
        display.wedge:DefineNormal(Vector3.UP)
        display.wedge:DefineVertex(Vector3(0.001, 0, 0))
        display.wedge:DefineNormal(Vector3.UP)
        display.wedge:DefineVertex(Vector3(0, 0, 0.001))
        display.wedge:DefineNormal(Vector3.UP)
    end
    display.wedge:Commit()
    display.text:SetText(tostring(math.max(0, math.floor(hp or 0))))
end

function CreateHero3D()
    local cfg = CONFIG.visual3D.hero
    heroNode3D_ = boardRoot3D_:CreateChild("ReplaceableHeroModel")
    heroNode3D_.scale = Vector3(cfg.scale, cfg.scale, cfg.scale)
    heroNode3D_.rotation = Quaternion(cfg.yaw or 0, Vector3.UP)
    heroModel3D_ = heroNode3D_:CreateComponent("StaticModel")
    heroModel3D_:SetModel(cache:GetResource("Model", cfg.model))
    ApplyModelMaterials3D(heroModel3D_, cfg.materials, CreatePBRMaterial3D("hero_body", Color(0.45, 0.45, 0.45, 1.0), 0.0, 0.55, 0.0))
    heroModel3D_.castShadows = true
    heroHealthDisplay3D_ = CreateHealthDisplay3D(heroNode3D_, "hero", 0.42, 0.58, Color(0.25, 0.85, 0.25, 1.0))
end

function CreateRuneGrid3D()
    runeNodes3D_ = {}
    runeModels3D_ = {}
    runeIconNodes3D_ = {}
    cellMarkers3D_ = {}
    selectionMaterial3D_ = CreatePBRMaterial3D("selection_cell", Color(1.0, 0.78, 0.18, 1.0), 0.2, 0.18, 1.4)

    for row = 1, BOARD_SIZE do
        runeNodes3D_[row] = {}
        runeModels3D_[row] = {}
        runeIconNodes3D_[row] = {}
        cellMarkers3D_[row] = {}
        for col = 1, BOARD_SIZE do
            local marker = boardRoot3D_:CreateChild("CellSelectionMarker")
            marker.position = BoardToWorldAt(row, col, CONFIG.visual3D.floorY + 0.012)
            marker.scale = Vector3(CONFIG.visual3D.cellSize * 0.92, 0.025, CONFIG.visual3D.cellSize * 0.92)
            marker.enabled = false
            local markerModel = marker:CreateComponent("StaticModel")
            markerModel:SetModel(cache:GetResource("Model", "Models/Box.mdl"))
            markerModel:SetMaterial(selectionMaterial3D_)
            cellMarkers3D_[row][col] = marker

            local node = boardRoot3D_:CreateChild("RuneCube")
            local cube = node:CreateChild("CubeBody")
            cube.scale = Vector3(CONFIG.visual3D.cellSize * 0.78, CONFIG.visual3D.runeHeight, CONFIG.visual3D.cellSize * 0.78)
            local cubeModel = cube:CreateComponent("StaticModel")
            cubeModel:SetModel(cache:GetResource("Model", "Models/Box.mdl"))
            cubeModel.castShadows = true
            runeModels3D_[row][col] = cubeModel

            local icons = {}
            runeNodes3D_[row][col] = node
            runeIconNodes3D_[row][col] = icons
        end
    end
end

function CreateRuneIcon3D(parent, icons, gemType, modelPath, scale, rotation)
    local node = parent:CreateChild("RuneIcon" .. tostring(gemType))
    node.position = Vector3(0, CONFIG.visual3D.runeHeight * 0.58 + 0.04, 0)
    node.scale = scale
    node.rotation = rotation
    node.enabled = false
    local model = node:CreateComponent("StaticModel")
    model:SetModel(cache:GetResource("Model", modelPath))
    model:SetMaterial(GetRuneIconMaterial3D(gemType))
    model.castShadows = false
    icons[gemType] = node
end

function SetRuneNodeType3D(row, col, gemType)
    local node = runeNodes3D_[row] and runeNodes3D_[row][col]
    local model = runeModels3D_[row] and runeModels3D_[row][col]
    if node == nil or model == nil then return end
    local icons = runeIconNodes3D_[row] and runeIconNodes3D_[row][col] or {}
    if gemType == nil or gemType == 0 then
        node.enabled = false
        model.enabled = false
        for _, iconNode in pairs(icons) do
            iconNode.enabled = false
        end
        return
    end
    node.enabled = true
    model.enabled = true
    model:SetMaterial(GetRuneMaterial3D(gemType))
    for iconType, iconNode in pairs(icons) do
        iconNode.enabled = iconType == gemType
    end
end

function SetRuneNodeTransform3D(row, col, pos, scaleMul)
    local node = runeNodes3D_[row] and runeNodes3D_[row][col]
    if node == nil then return end
    node.position = pos
    local s = scaleMul or 1.0
    node.scale = Vector3(s, s, s)
    node.rotation = Quaternion(0, Vector3.UP)
end

function IsActorCell3D(row, col)
    if hero_ ~= nil and hero_.row == row and hero_.col == col then return true end
    for _, monster in ipairs(monsters_ or {}) do
        if monster.hp > 0 and monster.row == row and monster.col == col then
            return true
        end
    end
    return false
end

function IsMovingRuneDestination3D(row, col)
    for _, move in ipairs(monsterMoves_ or {}) do
        if move.gemType ~= nil and move.gemType ~= 0 and move.fromRow == row and move.fromCol == col then
            return true
        end
    end
    return false
end

function UpdateRuneGrid3D()
    if scene3D_ == nil or boardRoot3D_ == nil then return end

    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local gemType = board_[row] and board_[row][col] or 0
            if IsActorCell3D(row, col) and not IsMovingRuneDestination3D(row, col) then
                gemType = 0
            end
            SetRuneNodeType3D(row, col, gemType)
            SetRuneNodeTransform3D(row, col, BoardToWorldAt(row, col, CONFIG.visual3D.floorY + CONFIG.visual3D.runeHeight * 0.5), 1.0)
            if cellMarkers3D_[row] and cellMarkers3D_[row][col] then
                cellMarkers3D_[row][col].enabled = selected_ ~= nil and selected_.row == row and selected_.col == col and not IsActorCell3D(row, col)
            end
        end
    end

    ApplyMonsterMoveRuneAnimation3D()
    ApplyRuneAnimation3D()
end

function ApplyMonsterMoveRuneAnimation3D()
    for _, move in ipairs(monsterMoves_ or {}) do
        if move.gemType ~= nil and move.gemType ~= 0 then
            local t = 1 - Clamp(move.life / move.maxLife, 0, 1)
            local eased = EaseInOut(t)
            local from = BoardToWorld(move.toRow, move.toCol)
            local to = BoardToWorld(move.fromRow, move.fromCol)
            local y = CONFIG.visual3D.floorY + CONFIG.visual3D.runeHeight * 0.5 + math.sin(t * math.pi) * 0.08
            SetRuneNodeType3D(move.fromRow, move.fromCol, move.gemType)
            SetRuneNodeTransform3D(move.fromRow, move.fromCol, Vector3(Lerp(from.x, to.x, eased), y, Lerp(from.z, to.z, eased)), 1.0)
        end
    end
end

function ApplyRuneAnimation3D()
    local anim = currentAnim_
    if anim == nil then return end
    local t = Clamp(anim.elapsed / anim.duration, 0, 1)

    if anim.kind == "swap" then
        local eased = EaseInOut(t)
        if anim.reverse then eased = 1 - eased end
        local aFrom = BoardToWorld(anim.a.row, anim.a.col)
        local bFrom = BoardToWorld(anim.b.row, anim.b.col)
        local y = CONFIG.visual3D.floorY + CONFIG.visual3D.runeHeight * 0.5 + math.sin(t * math.pi) * 0.12
        SetRuneNodeType3D(anim.a.row, anim.a.col, anim.typeB)
        SetRuneNodeType3D(anim.b.row, anim.b.col, anim.typeA)
        SetRuneNodeTransform3D(anim.a.row, anim.a.col, Vector3(Lerp(aFrom.x, bFrom.x, eased), y, Lerp(aFrom.z, bFrom.z, eased)), 1.06)
        SetRuneNodeTransform3D(anim.b.row, anim.b.col, Vector3(Lerp(bFrom.x, aFrom.x, eased), y, Lerp(bFrom.z, aFrom.z, eased)), 1.06)
    elseif anim.kind == "clear" then
        local pulse = 1.0 + math.sin(t * math.pi) * 0.35
        for _, cell in ipairs(anim.matches or {}) do
            SetRuneNodeTransform3D(cell.row, cell.col, BoardToWorldAt(cell.row, cell.col, CONFIG.visual3D.floorY + CONFIG.visual3D.runeHeight * 0.5 + t * 0.12), pulse)
        end
    elseif anim.kind == "drop" or anim.kind == "enemyDrop" then
        local eased = EaseOutBack(t)
        for _, drop in ipairs(anim.drops or {}) do
            local from = BoardToWorld(drop.fromRow, drop.fromCol)
            if drop.fromRow < 1 then
                local spawn = BoardToWorld(1, drop.fromCol)
                from = Vector3(spawn.x, CONFIG.visual3D.floorY + CONFIG.visual3D.runeHeight * 0.5, spawn.z + CONFIG.visual3D.cellSize * math.abs(drop.fromRow))
            end
            local to = BoardToWorld(drop.toRow, drop.toCol)
            SetRuneNodeType3D(drop.toRow, drop.toCol, drop.type)
            SetRuneNodeTransform3D(drop.toRow, drop.toCol, Vector3(Lerp(from.x, to.x, eased), Lerp(from.y, CONFIG.visual3D.floorY + CONFIG.visual3D.runeHeight * 0.5, eased), Lerp(from.z, to.z, eased)), 1.0)
        end
    end
end

function EnsureMonsterNodes3D()
    while #monsterNodes3D_ < #monsters_ do
        local node = boardRoot3D_:CreateChild("ReplaceableMonsterModel")
        local cfg = CONFIG.visual3D.monster
        node.scale = Vector3(cfg.scale, cfg.scale, cfg.scale)
        node.rotation = Quaternion(cfg.yaw or 0, Vector3.UP)
        local model = node:CreateComponent("StaticModel")
        model:SetModel(cache:GetResource("Model", cfg.model))
        ApplyModelMaterials3D(model, cfg.materials, CreatePBRMaterial3D("monster_body", Color(0.95, 0.08, 0.06, 1.0), 0.0, 0.46, 0.25))
        model.castShadows = true
        local healthDisplay = CreateHealthDisplay3D(node, "monster", 0.42, 0.58, Color(0.95, 0.08, 0.06, 1.0))
        table.insert(monsterNodes3D_, { node = node, model = model, healthDisplay = healthDisplay })
    end
    while #monsterNodes3D_ > #monsters_ do
        local entry = table.remove(monsterNodes3D_)
        if entry and entry.node then entry.node:Remove() end
    end
end

function FindMonsterMoveVisual(monster)
    for _, move in ipairs(monsterMoves_) do
        if move.monster == monster then return move end
    end
    return nil
end

function UpdateMonsterVisuals3D(timeStep)
    EnsureMonsterNodes3D()
    for index, monster in ipairs(monsters_) do
        local entry = monsterNodes3D_[index]
        if entry ~= nil then
            local node = entry.node
            node.enabled = monster.hp > 0
            local pos = BoardToWorld(monster.row, monster.col)
            local move = FindMonsterMoveVisual(monster)
            local movePulse = 0
            if move ~= nil then
                local t = 1 - Clamp(move.life / move.maxLife, 0, 1)
                local eased = EaseInOut(t)
                local from = BoardToWorld(move.fromRow, move.fromCol)
                local to = BoardToWorld(move.toRow, move.toCol)
                pos = Vector3(Lerp(from.x, to.x, eased), CONFIG.visual3D.floorY, Lerp(from.z, to.z, eased))
                movePulse = math.sin(t * math.pi) * 0.24
            end
            if monster.attackFlash ~= nil and monster.attackFlash > 0 then
                monster.attackFlash = math.max(0, monster.attackFlash - timeStep)
                local heroPos = BoardToWorld(hero_.row, hero_.col)
                local attackT = monster.attackFlash / 0.36
                local lunge = math.sin((1 - attackT) * math.pi) * 0.28
                local dx = heroPos.x - pos.x
                local dz = heroPos.z - pos.z
                local len = math.sqrt(dx * dx + dz * dz)
                if len > 0.001 then
                    pos = Vector3(pos.x + dx / len * lunge, pos.y, pos.z + dz / len * lunge)
                end
                node.scale = Vector3(CONFIG.visual3D.monster.scale * (1.0 + lunge * 0.22), CONFIG.visual3D.monster.scale * (1.0 - lunge * 0.1), CONFIG.visual3D.monster.scale * (1.0 + lunge * 0.22))
            else
                node.scale = Vector3(CONFIG.visual3D.monster.scale, CONFIG.visual3D.monster.scale, CONFIG.visual3D.monster.scale)
            end
            node.position = Vector3(pos.x, CONFIG.visual3D.floorY + movePulse, pos.z)
            node.rotation = Quaternion(0, Vector3.UP)
            UpdateHealthDisplay3D(entry.healthDisplay, monster.hp, monster.maxHp)
        end
    end
end

function FaceNodeToCell3D(node, fromPos, toPos, yawOffset)
    local dx = toPos.x - fromPos.x
    local dz = toPos.z - fromPos.z
    if math.abs(dx) + math.abs(dz) < 0.001 then return end
    local yaw = math.deg(math.atan(dx, dz)) + (yawOffset or 0)
    node.rotation = Quaternion(yaw, Vector3.UP)
end

function UpdateHeroVisual3D()
    if heroNode3D_ == nil then return end
    local pos = BoardToWorld(hero_.row, hero_.col)
    heroNode3D_.position = Vector3(pos.x, CONFIG.visual3D.floorY, pos.z)
    heroNode3D_.rotation = Quaternion(0, Vector3.UP)
    UpdateHealthDisplay3D(heroHealthDisplay3D_, hero_.hp, hero_.maxHp)
end

function BuildItemSignature3D()
    local parts = {}
    for _, trap in ipairs(traps_) do
        table.insert(parts, trap.kind .. ":" .. trap.row .. ":" .. trap.col .. ":" .. tostring(trap.turns or 0))
    end
    for _, silo in ipairs(missileSilos_) do
        table.insert(parts, "missile:" .. silo.row .. ":" .. silo.col .. ":" .. tostring(silo.turnsLeft or 0))
    end
    return table.concat(parts, "|")
end

function RebuildItemNodes3D()
    for _, node in ipairs(itemNodes3D_) do
        if node ~= nil then node:Remove() end
    end
    itemNodes3D_ = {}
    for _, trap in ipairs(traps_) do
        table.insert(itemNodes3D_, CreateItemNode3D(trap.kind, trap.row, trap.col, trap.turns or 0))
    end
    for _, silo in ipairs(missileSilos_) do
        table.insert(itemNodes3D_, CreateItemNode3D("missile", silo.row, silo.col, silo.turnsLeft or 0))
    end
end

function CreateItemNode3D(kind, row, col, turns)
    local nodeName = (kind == "laserH" or kind == "laserV" or kind == "laser") and "GeneratedLaserItem3D" or "GeneratedItem3D"
    local node = boardRoot3D_:CreateChild(nodeName)
    local pos = BoardToWorld(row, col)
    node.position = Vector3(pos.x, CONFIG.visual3D.floorY + 0.25, pos.z)
    local color = Color(1, 1, 1, 1)
    local modelPath = "Models/Box.mdl"
    local scale = Vector3(0.42, 0.42, 0.42)
    if kind == "laserH" or kind == "laserV" or kind == "laser" then
        color = Color(0.1, 0.85, 1.0, 1.0)
        modelPath = "Models/Box.mdl"
        scale = kind == "laserH" and Vector3(0.72, 0.18, 0.28) or Vector3(0.28, 0.18, 0.72)
    elseif kind == "turret" then
        color = Color(1.0, 0.72, 0.24, 1.0)
        modelPath = "Models/Cylinder.mdl"
        scale = Vector3(0.38, 0.34, 0.38)
    elseif kind == "missile" or kind == "missileSilo" then
        color = Color(1.0, 0.35, 0.12, 1.0)
        modelPath = "Models/Cone.mdl"
        scale = Vector3(0.42, 0.55, 0.42)
    elseif kind == "bomb" then
        color = Color(0.25, 0.08, 0.06, 1.0)
        modelPath = "Models/Sphere.mdl"
        scale = Vector3(0.42, 0.42, 0.42)
    end
    node.scale = scale
    local model = node:CreateComponent("StaticModel")
    model:SetModel(cache:GetResource("Model", modelPath))
    model:SetMaterial(CreatePBRMaterial3D("item_" .. kind, color, kind == "turret" and 0.65 or 0.15, 0.24, 0.8))
    model.castShadows = true

    local badge = node:CreateChild("TurnsBadge")
    badge.position = Vector3(0, 0.88, 0)
    badge.scale = Vector3(0.24, 0.24, 0.24)
    badge.rotation = Quaternion(90, Vector3.RIGHT)

    local badgeBg = badge:CreateChild("TurnsBadgeBackground")
    badgeBg.position = Vector3(0, -0.012, 0)
    badgeBg.scale = Vector3(1.45, 0.12, 1.45)
    local badgeModel = badgeBg:CreateComponent("StaticModel")
    badgeModel:SetModel(cache:GetResource("Model", "Models/Cylinder.mdl"))
    badgeModel:SetMaterial(CreatePBRMaterial3D("turn_badge_bg", Color(0.10, 0.06, 0.03, 1.0), 0.0, 0.2, 0.55))
    badgeModel.castShadows = false

    local textNode = badge:CreateChild("TurnsBadgeText")
    textNode.position = Vector3(0, 0.02, 0)
    textNode.scale = Vector3(0.018, 0.018, 0.018)
    local text = textNode:CreateComponent("Text3D")
    text:SetFont("Fonts/MiSans-Regular.ttf", 34)
    text:SetAlignment(HA_CENTER, VA_CENTER)
    text:SetTextAlignment(HA_CENTER)
    text:SetColor(Color(1.0, 0.92, 0.38, 1.0))
    text:SetText(tostring(math.max(0, turns or 0)))
    return node
end

function UpdateItemNodes3D(timeStep)
    local signature = BuildItemSignature3D()
    if signature ~= itemSignature3D_ then
        itemSignature3D_ = signature
        RebuildItemNodes3D()
    end
    for index, node in ipairs(itemNodes3D_) do
        if node ~= nil and node.name ~= "GeneratedLaserItem3D" then
            node:Rotate(Quaternion(0, (35.0 + index) * timeStep, 0))
        end
    end
end

function SyncScene3D()
    UpdateRuneGrid3D()
    UpdateHeroVisual3D()
    UpdateMonsterVisuals3D(0)
    itemSignature3D_ = nil
    UpdateItemNodes3D(0)
end

function UpdateScene3D(timeStep)
    if scene3D_ == nil then return end
    UpdateRuneGrid3D()
    UpdateHeroVisual3D()
    UpdateMonsterVisuals3D(timeStep)
    UpdateItemNodes3D(timeStep)

    for _, node in ipairs(itemNodes3D_) do
        if node ~= nil then
            node.position = Vector3(node.position.x, CONFIG.visual3D.floorY + 0.25 + math.sin(time_ * 4) * 0.04, node.position.z)
        end
    end
end

function ScreenToBoardCell3D(inputX, inputY)
    if camera3D_ == nil then return nil end
    local nx = inputX / math.max(1, physW_)
    local ny = inputY / math.max(1, physH_)
    local ray = camera3D_:GetScreenRay(nx, ny)
    if ray == nil or math.abs(ray.direction.y) < 0.001 then return nil end
    local t = (CONFIG.visual3D.floorY - ray.origin.y) / ray.direction.y
    if t < 0 then return nil end
    local hitX = ray.origin.x + ray.direction.x * t
    local hitZ = ray.origin.z + ray.direction.z * t
    local cellSize = CONFIG.visual3D.cellSize
    local center = (BOARD_SIZE + 1) * 0.5
    local col = math.floor(hitX / cellSize + center + 0.5)
    local row = math.floor(center - hitZ / cellSize + 0.5)
    if not IsValidCell(row, col) then return nil end
    return { row = row, col = col }
end

function WorldToHudPoint3D(worldPos)
    if camera3D_ == nil or worldPos == nil then return nil end
    local screenPos = camera3D_:WorldToScreenPoint(worldPos)
    if screenPos.x < -0.1 or screenPos.x > 1.1 or screenPos.y < -0.1 or screenPos.y > 1.1 then return nil end
    return {
        x = screenPos.x * screenW_,
        y = screenPos.y * screenH_,
    }
end

function MonsterCenterHudPoint3D(monster)
    if monster == nil then return nil end
    for index, candidate in ipairs(monsters_) do
        if candidate == monster then
            local entry = monsterNodes3D_[index]
            if entry ~= nil and entry.node ~= nil then
                return WorldToHudPoint3D(entry.node.worldPosition + Vector3(0, 0.36, 0))
            end
            break
        end
    end
    local fallback = BoardToWorld(monster.row, monster.col)
    return WorldToHudPoint3D(Vector3(fallback.x, CONFIG.visual3D.floorY + 0.36, fallback.z))
end

function MarkMonsterAttack3D(monster)
    monster.attackFlash = 0.36
end
