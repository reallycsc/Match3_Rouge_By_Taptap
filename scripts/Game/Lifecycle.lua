local G = require "Game.Context"
local _ENV = G

function Start()
    graphics.windowTitle = CONFIG.title
    input.mouseMode = MM_FREE

    RecalcLayout()
    CreateScene3D()
    vg_ = nvgCreate(1)
    if vg_ == nil then
        print("ERROR: Failed to create NanoVG context")
        return
    end

    fontId_ = nvgCreateFont(vg_, "misans", "Fonts/MiSans-Regular.ttf")
    if fontId_ == -1 then
        print("ERROR: Failed to load font Fonts/MiSans-Regular.ttf")
    end

    trapImage_ = nvgCreateImage(vg_, CONFIG.trapImagePath, 0)
    if trapImage_ == -1 then
        print("ERROR: Failed to load trap image " .. CONFIG.trapImagePath)
    else
        print("Trap image loaded: " .. CONFIG.trapImagePath)
    end

    ResetGame()
    SyncScene3D()
    InitTapTapServices()
    SubscribeToEvent(vg_, "NanoVGRender", "HandleNanoVGRender")
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("MouseButtonDown", "HandleMouseButtonDown")
    SubscribeToEvent("MouseButtonUp", "HandleMouseButtonUp")
    SubscribeToEvent("MouseMove", "HandleMouseMove")
    SubscribeToEvent("TouchBegin", "HandleTouchBegin")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("ScreenMode", "HandleScreenMode")
    print("Dark match-3 prototype started")
end

function Stop()
    if vg_ ~= nil then
        nvgDelete(vg_)
        vg_ = nil
    end
    if scene3D_ ~= nil then
        scene3D_:Dispose()
        scene3D_ = nil
    end
end
