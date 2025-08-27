--[[
    Module: EventBus
    Description: Decoupled inter-module communication system with priority, wildcards, and debugging
    Enables modules to communicate without direct references
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)

local EventBus = {}
EventBus.__index = EventBus

-- ========================================
-- TYPES
-- ========================================

type EventHandler = {
    id: string,
    callback: (...any) -> (),
    priority: number,
    once: boolean,
    filter: ((... any) -> boolean)?,
}

type EventRecord = {
    timestamp: number,
    eventName: string,
    args: {any},
    handlerCount: number,
}

-- ========================================
-- CONSTANTS
-- ========================================

local DEFAULT_PRIORITY = 50
local MAX_HISTORY_SIZE = 100
local WILDCARD_PATTERN = "*"

-- ========================================
-- INITIALIZATION
-- ========================================

function EventBus.new(dependencies)
    local self = setmetatable({}, EventBus)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    
    -- Event storage
    self._events = {} -- eventName -> {EventHandler}
    self._wildcardHandlers = {} -- Handlers that listen to all events
    
    -- Event history for debugging
    self._history = {}
    self._historyEnabled = false
    
    -- Performance tracking
    self._eventCounts = {}
    self._handlerCounts = {}
    self._performanceEnabled = false
    
    -- Settings
    self._loggingEnabled = self._config.DEBUG.ENABLED and self._config.DEBUG.LOG_EVENTS
    
    return self
end

-- ========================================
-- PUBLIC METHODS
-- ========================================

function EventBus:Fire(eventName: string, ...: any)
    if not eventName or type(eventName) ~= "string" then
        warn("[EventBus] Invalid event name:", eventName)
        return
    end
    
    local args = {...}
    local handlerCount = 0
    
    -- Log event
    if self._loggingEnabled then
        print(string.format("[EventBus] Firing '%s' with %d args", eventName, #args))
    end
    
    -- Record history
    if self._historyEnabled then
        self:RecordEvent(eventName, args)
    end
    
    -- Track performance
    if self._performanceEnabled then
        self._eventCounts[eventName] = (self._eventCounts[eventName] or 0) + 1
    end
    
    -- Get handlers for specific event
    local handlers = self._events[eventName]
    if handlers then
        -- Sort by priority (cached)
        if not handlers._sorted then
            table.sort(handlers, function(a, b)
                return a.priority > b.priority
            end)
            handlers._sorted = true
        end
        
        -- Execute handlers
        for i = #handlers, 1, -1 do -- Reverse iterate for safe removal
            local handler = handlers[i]
            
            -- Check filter
            if not handler.filter or handler.filter(...) then
                local success, err = pcall(handler.callback, ...)
                
                if not success then
                    warn(string.format("[EventBus] Handler error for '%s': %s", eventName, err))
                end
                
                handlerCount = handlerCount + 1
                
                -- Remove if once
                if handler.once then
                    table.remove(handlers, i)
                end
            end
        end
        
        -- Clean up empty handler lists
        if #handlers == 0 then
            self._events[eventName] = nil
        end
    end
    
    -- Execute wildcard handlers
    for _, handler in ipairs(self._wildcardHandlers) do
        local success, err = pcall(handler.callback, eventName, ...)
        
        if not success then
            warn("[EventBus] Wildcard handler error:", err)
        end
        
        handlerCount = handlerCount + 1
    end
    
    -- Update history with handler count
    if self._historyEnabled and #self._history > 0 then
        self._history[#self._history].handlerCount = handlerCount
    end
end

function EventBus:On(eventName: string, callback: (...any) -> (), priority: number?): Types.Connection
    return self:Connect(eventName, callback, priority, false)
end

function EventBus:Once(eventName: string, callback: (...any) -> ()): Types.Connection
    return self:Connect(eventName, callback, DEFAULT_PRIORITY, true)
end

function EventBus:Connect(eventName: string, callback: (...any) -> (), priority: number?, once: boolean?): Types.Connection
    if not eventName or type(eventName) ~= "string" then
        error("[EventBus] Invalid event name")
    end
    
    if type(callback) ~= "function" then
        error("[EventBus] Callback must be a function")
    end
    
    priority = priority or DEFAULT_PRIORITY
    once = once or false
    
    local handler: EventHandler = {
        id = Utilities.CreateUUID(),
        callback = callback,
        priority = priority,
        once = once,
        filter = nil,
    }
    
    -- Add to appropriate list
    if eventName == WILDCARD_PATTERN then
        table.insert(self._wildcardHandlers, handler)
    else
        if not self._events[eventName] then
            self._events[eventName] = {}
        end
        
        table.insert(self._events[eventName], handler)
        self._events[eventName]._sorted = false -- Mark for re-sorting
    end
    
    -- Track handler count
    if self._performanceEnabled then
        self._handlerCounts[eventName] = (self._handlerCounts[eventName] or 0) + 1
    end
    
    -- Create connection object
    local connection = {
        Connected = true
    }
    
    function connection:Disconnect()
        if not self.Connected then
            return
        end
        
        self.Connected = false
        
        -- Remove from appropriate list
        if eventName == WILDCARD_PATTERN then
            for i, h in ipairs(self._wildcardHandlers) do
                if h.id == handler.id then
                    table.remove(self._wildcardHandlers, i)
                    break
                end
            end
        else
            local handlers = self._events[eventName]
            if handlers then
                for i, h in ipairs(handlers) do
                    if h.id == handler.id then
                        table.remove(handlers, i)
                        break
                    end
                end
                
                if #handlers == 0 then
                    self._events[eventName] = nil
                end
            end
        end
        
        -- Update handler count
        if self._performanceEnabled then
            self._handlerCounts[eventName] = math.max(0, (self._handlerCounts[eventName] or 0) - 1)
        end
    end
    
    return connection
end

function EventBus:OnAny(callback: (eventName: string, ...any) -> ()): Types.Connection
    return self:On(WILDCARD_PATTERN, callback)
end

function EventBus:Off(eventName: string, callback: ((...any) -> ())?): ()
    if not eventName then
        return
    end
    
    local handlers = self._events[eventName]
    if not handlers then
        return
    end
    
    if callback then
        -- Remove specific handler
        for i = #handlers, 1, -1 do
            if handlers[i].callback == callback then
                table.remove(handlers, i)
            end
        end
    else
        -- Remove all handlers for event
        self._events[eventName] = nil
    end
end

function EventBus:Wait(eventName: string, timeout: number?): ...any
    timeout = timeout or 30
    
    local result = nil
    local completed = false
    
    local connection = self:Once(eventName, function(...)
        result = {...}
        completed = true
    end)
    
    local startTime = tick()
    while not completed and (tick() - startTime) < timeout do
        task.wait()
    end
    
    if not completed then
        connection:Disconnect()
    end
    
    return if result then table.unpack(result) else nil
end

-- ========================================
-- ADVANCED FEATURES
-- ========================================

function EventBus:CreateFilteredHandler(eventName: string, filter: (...any) -> boolean, callback: (...any) -> ()): Types.Connection
    local wrappedCallback = function(...)
        if filter(...) then
            callback(...)
        end
    end
    
    return self:On(eventName, wrappedCallback)
end

function EventBus:CreateThrottledHandler(eventName: string, callback: (...any) -> (), cooldown: number): Types.Connection
    local lastCall = 0
    
    local throttledCallback = function(...)
        local now = tick()
        if now - lastCall >= cooldown then
            lastCall = now
            callback(...)
        end
    end
    
    return self:On(eventName, throttledCallback)
end

function EventBus:CreateDebouncedHandler(eventName: string, callback: (...any) -> (), delay: number): Types.Connection
    local pending = nil
    
    local debouncedCallback = function(...)
        if pending then
            task.cancel(pending)
        end
        
        local args = {...}
        pending = task.delay(delay, function()
            pending = nil
            callback(table.unpack(args))
        end)
    end
    
    return self:On(eventName, debouncedCallback)
end

-- ========================================
-- DEBUGGING & INSPECTION
-- ========================================

function EventBus:GetListeners(eventName: string): number
    local count = 0
    
    if eventName then
        local handlers = self._events[eventName]
        count = handlers and #handlers or 0
    else
        -- Count all listeners
        for _, handlers in pairs(self._events) do
            count = count + #handlers
        end
        count = count + #self._wildcardHandlers
    end
    
    return count
end

function EventBus:GetEvents(): {string}
    local events = {}
    
    for eventName in pairs(self._events) do
        table.insert(events, eventName)
    end
    
    table.sort(events)
    return events
end

function EventBus:EnableLogging(enabled: boolean)
    self._loggingEnabled = enabled
end

function EventBus:EnableHistory(enabled: boolean)
    self._historyEnabled = enabled
    
    if not enabled then
        self._history = {}
    end
end

function EventBus:GetEventHistory(limit: number?): {EventRecord}
    limit = limit or #self._history
    
    local history = {}
    local start = math.max(1, #self._history - limit + 1)
    
    for i = start, #self._history do
        table.insert(history, self._history[i])
    end
    
    return history
end

function EventBus:ClearHistory()
    self._history = {}
end

function EventBus:GetPerformanceStats(): table
    if not self._performanceEnabled then
        return {}
    end
    
    return {
        eventCounts = Utilities.ShallowCopy(self._eventCounts),
        handlerCounts = Utilities.ShallowCopy(self._handlerCounts),
        totalEvents = self:GetTotalEventsFired(),
        totalHandlers = self:GetListeners(),
    }
end

function EventBus:EnablePerformanceTracking(enabled: boolean)
    self._performanceEnabled = enabled
    
    if not enabled then
        self._eventCounts = {}
        self._handlerCounts = {}
    end
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

function EventBus:RecordEvent(eventName: string, args: {any})
    table.insert(self._history, {
        timestamp = tick(),
        eventName = eventName,
        args = args,
        handlerCount = 0,
    })
    
    -- Limit history size
    if #self._history > MAX_HISTORY_SIZE then
        table.remove(self._history, 1)
    end
end

function EventBus:GetTotalEventsFired(): number
    local total = 0
    
    for _, count in pairs(self._eventCounts) do
        total = total + count
    end
    
    return total
end

-- ========================================
-- CLEANUP
-- ========================================

function EventBus:Destroy()
    -- Remove all handlers
    self._events = {}
    self._wildcardHandlers = {}
    
    -- Clear history
    self._history = {}
    
    -- Clear performance data
    self._eventCounts = {}
    self._handlerCounts = {}
end

-- ========================================
-- DEBUG COMMANDS (Studio only)
-- ========================================

if Config.DEBUG.ENABLED then
    function EventBus:DebugPrint()
        print("\n=== EventBus Debug Info ===")
        print("Total Events:", #self:GetEvents())
        print("Total Handlers:", self:GetListeners())
        
        print("\nEvents with handlers:")
        for eventName, handlers in pairs(self._events) do
            print(string.format("  %s: %d handlers", eventName, #handlers))
        end
        
        print("\nWildcard handlers:", #self._wildcardHandlers)
        
        if self._performanceEnabled then
            print("\nEvent fire counts:")
            for eventName, count in pairs(self._eventCounts) do
                print(string.format("  %s: %d times", eventName, count))
            end
        end
        
        print("=========================\n")
    end
end

return EventBus