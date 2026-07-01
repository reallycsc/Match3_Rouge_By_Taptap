-- 暗黑破坏神风格三消战斗原型
-- 入口仅负责把 UrhoX 全局事件转发到模块化游戏上下文。

local Game = require "Game.Loader"

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    Game.HandleUpdate(eventType, eventData)
end

---@param eventType string
---@param eventData MouseButtonDownEventData
function HandleMouseButtonDown(eventType, eventData)
    Game.HandleMouseButtonDown(eventType, eventData)
end

---@param eventType string
---@param eventData MouseButtonUpEventData
function HandleMouseButtonUp(eventType, eventData)
    Game.HandleMouseButtonUp(eventType, eventData)
end

---@param eventType string
---@param eventData MouseMoveEventData
function HandleMouseMove(eventType, eventData)
    Game.HandleMouseMove(eventType, eventData)
end

---@param eventType string
---@param eventData TouchBeginEventData
function HandleTouchBegin(eventType, eventData)
    Game.HandleTouchBegin(eventType, eventData)
end

---@param eventType string
---@param eventData TouchMoveEventData
function HandleTouchMove(eventType, eventData)
    Game.HandleTouchMove(eventType, eventData)
end

---@param eventType string
---@param eventData TouchEndEventData
function HandleTouchEnd(eventType, eventData)
    Game.HandleTouchEnd(eventType, eventData)
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    Game.HandleKeyDown(eventType, eventData)
end

function HandleScreenMode(eventType, eventData)
    Game.HandleScreenMode(eventType, eventData)
end

function HandleNanoVGRender(eventType, eventData)
    Game.HandleNanoVGRender(eventType, eventData)
end

function Start()
    Game.Start()
end

function Stop()
    Game.Stop()
end
