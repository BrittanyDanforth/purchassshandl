--[[
    Module: StateManager
    Description: Centralized state management with reactive subscriptions and transactions
    Provides dot-notation access, change detection, and state persistence
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)

local StateManager = {}
StateManager.__index = StateManager

-- ========================================
-- TYPES
-- ========================================

type Subscription = {
    id: string,
    path: string,
    callback: (newValue: any, oldValue: any, path: string) -> (),
    active: boolean,
}

type Transaction = {
    changes: {[string]: any},
    timestamp: number,
    committed: boolean,
}

-- ========================================
-- CONSTANTS
-- ========================================

local PATH_SEPARATOR = "."
local WILDCARD = "*"
local MAX_HISTORY_SIZE = 100
local DEFAULT_PERSISTENCE_KEY = "SanrioTycoonState"

-- ========================================
-- INITIALIZATION
-- ========================================

function StateManager.new(dependencies)
    local self = setmetatable({}, StateManager)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    self._eventBus = dependencies.EventBus
    
    -- State storage
    self._state = {}
    self._subscriptions = {} -- path -> {Subscription}
    self._wildcardSubscriptions = {} -- Subscriptions to all changes
    
    -- Transaction support
    self._currentTransaction = nil
    self._transactionStack = {}
    
    -- History tracking
    self._history = {}
    self._historyEnabled = false
    self._maxHistorySize = MAX_HISTORY_SIZE
    
    -- Performance
    self._changeCount = 0
    self._subscriptionCount = 0
    
    -- Settings
    self._persistenceEnabled = false
    self._persistenceKey = DEFAULT_PERSISTENCE_KEY
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Initialize with empty state
    self:Initialize()
    
    return self
end

function StateManager:Initialize()
    -- Load persisted state if enabled
    if self._persistenceEnabled then
        self:LoadPersistedState()
    end
    
    -- Set up auto-save if persistence is enabled
    if self._persistenceEnabled then
        task.spawn(function()
            while self._persistenceEnabled do
                task.wait(30) -- Save every 30 seconds
                self:SaveState()
            end
        end)
    end
end

-- ========================================
-- STATE ACCESS
-- ========================================

function StateManager:Get(path: string?): any
    if not path or path == "" then
        return self._utilities.DeepCopy(self._state)
    end
    
    local segments = self:ParsePath(path)
    local current = self._state
    
    for _, segment in ipairs(segments) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    
    -- Return deep copy to prevent external modification
    if type(current) == "table" then
        return self._utilities.DeepCopy(current)
    end
    
    return current
end

function StateManager:Set(path: string, value: any)
    if not path or path == "" then
        error("[StateManager] Cannot set root state directly")
    end
    
    local oldValue = self:Get(path)
    
    -- Check if value actually changed
    if self:AreEqual(oldValue, value) then
        return
    end
    
    -- Apply change
    if self._currentTransaction then
        -- Add to transaction
        self._currentTransaction.changes[path] = value
    else
        -- Apply immediately
        self:ApplyChange(path, value, oldValue)
    end
end

function StateManager:Update(path: string, updater: (current: any) -> any)
    if type(updater) ~= "function" then
        error("[StateManager] Updater must be a function")
    end
    
    local current = self:Get(path)
    local newValue = updater(current)
    
    self:Set(path, newValue)
end

function StateManager:Delete(path: string)
    self:Set(path, nil)
end

-- ========================================
-- SUBSCRIPTIONS
-- ========================================

function StateManager:Subscribe(path: string, callback: (newValue: any, oldValue: any) -> ()): Types.StateSubscription
    if type(callback) ~= "function" then
        error("[StateManager] Callback must be a function")
    end
    
    local subscription: Subscription = {
        id = self._utilities.CreateUUID(),
        path = path,
        callback = callback,
        active = true,
    }
    
    -- Add to appropriate list
    if path == WILDCARD then
        table.insert(self._wildcardSubscriptions, subscription)
    else
        if not self._subscriptions[path] then
            self._subscriptions[path] = {}
        end
        table.insert(self._subscriptions[path], subscription)
    end
    
    self._subscriptionCount = self._subscriptionCount + 1
    
    -- Call immediately with current value
    local currentValue = self:Get(path)
    callback(currentValue, nil, path)
    
    -- Return subscription handle
    return {
        Unsubscribe = function()
            self:RemoveSubscription(subscription)
        end,
        
        IsActive = function()
            return subscription.active
        end
    }
end

function StateManager:SubscribeMany(paths: {string}, callback: (changes: {[string]: any}) -> ()): Types.StateSubscription
    local subscriptions = {}
    local active = true
    
    -- Create a wrapper that collects changes
    local pendingChanges = {}
    local updateScheduled = false
    
    local function scheduleUpdate()
        if updateScheduled then
            return
        end
        
        updateScheduled = true
        task.defer(function()
            if active and next(pendingChanges) then
                callback(pendingChanges)
                pendingChanges = {}
            end
            updateScheduled = false
        end)
    end
    
    -- Subscribe to each path
    for _, path in ipairs(paths) do
        local sub = self:Subscribe(path, function(newValue, oldValue)
            if active then
                pendingChanges[path] = newValue
                scheduleUpdate()
            end
        end)
        
        table.insert(subscriptions, sub)
    end
    
    -- Return combined subscription
    return {
        Unsubscribe = function()
            active = false
            for _, sub in ipairs(subscriptions) do
                sub:Unsubscribe()
            end
        end,
        
        IsActive = function()
            return active
        end
    }
end

-- ========================================
-- TRANSACTIONS
-- ========================================

function StateManager:Transaction(updater: () -> ())
    if type(updater) ~= "function" then
        error("[StateManager] Updater must be a function")
    end
    
    -- Create new transaction
    local transaction: Transaction = {
        changes = {},
        timestamp = tick(),
        committed = false,
    }
    
    -- Push to stack
    table.insert(self._transactionStack, transaction)
    self._currentTransaction = transaction
    
    -- Execute updater
    local success, error = pcall(updater)
    
    -- Pop from stack
    table.remove(self._transactionStack)
    self._currentTransaction = self._transactionStack[#self._transactionStack]
    
    if success then
        -- Commit all changes
        self:CommitTransaction(transaction)
    else
        -- Rollback
        if self._debugMode then
            warn("[StateManager] Transaction failed:", error)
        end
    end
end

function StateManager:CommitTransaction(transaction: Transaction)
    -- Apply all changes at once
    local notifications = {}
    
    for path, value in pairs(transaction.changes) do
        local oldValue = self:Get(path)
        
        if not self:AreEqual(oldValue, value) then
            self:ApplyChangeInternal(path, value)
            
            table.insert(notifications, {
                path = path,
                oldValue = oldValue,
                newValue = value,
            })
        end
    end
    
    -- Notify subscribers after all changes are applied
    for _, notification in ipairs(notifications) do
        self:NotifySubscribers(notification.path, notification.newValue, notification.oldValue)
    end
    
    transaction.committed = true
end

-- ========================================
-- STATE MANAGEMENT
-- ========================================

function StateManager:Reset(path: string?)
    if path then
        self:Set(path, nil)
    else
        -- Reset entire state
        local oldState = self._utilities.DeepCopy(self._state)
        self._state = {}
        
        -- Notify all subscribers
        self:NotifyAllSubscribers(oldState)
    end
end

function StateManager:GetSnapshot(): table
    return self._utilities.DeepCopy(self._state)
end

function StateManager:LoadSnapshot(snapshot: table)
    if type(snapshot) ~= "table" then
        error("[StateManager] Snapshot must be a table")
    end
    
    local oldState = self._utilities.DeepCopy(self._state)
    self._state = self._utilities.DeepCopy(snapshot)
    
    -- Notify all subscribers
    self:NotifyAllSubscribers(oldState)
end

function StateManager:Merge(path: string, data: table)
    if type(data) ~= "table" then
        error("[StateManager] Data must be a table for merge")
    end
    
    local current = self:Get(path) or {}
    if type(current) ~= "table" then
        current = {}
    end
    
    -- Merge data
    for key, value in pairs(data) do
        current[key] = value
    end
    
    self:Set(path, current)
end

-- ========================================
-- PERSISTENCE
-- ========================================

function StateManager:EnablePersistence(enabled: boolean, key: string?)
    self._persistenceEnabled = enabled
    self._persistenceKey = key or DEFAULT_PERSISTENCE_KEY
    
    if enabled then
        self:LoadPersistedState()
    end
end

function StateManager:SaveState()
    if not self._persistenceEnabled then
        return
    end
    
    local success, error = pcall(function()
        local HttpService = game:GetService("HttpService")
        local json = HttpService:JSONEncode(self._state)
        
        -- Store in DataStore or LocalStorage
        -- This is a placeholder - implement actual persistence
        if self._debugMode then
            print("[StateManager] Would save state:", #json, "bytes")
        end
    end)
    
    if not success and self._debugMode then
        warn("[StateManager] Failed to save state:", error)
    end
end

function StateManager:LoadPersistedState()
    -- This is a placeholder - implement actual persistence
    if self._debugMode then
        print("[StateManager] Would load persisted state")
    end
end

-- ========================================
-- HISTORY
-- ========================================

function StateManager:EnableHistory(enabled: boolean, maxSize: number?)
    self._historyEnabled = enabled
    self._maxHistorySize = maxSize or MAX_HISTORY_SIZE
    
    if not enabled then
        self._history = {}
    end
end

function StateManager:GetHistory(limit: number?): table
    limit = limit or #self._history
    
    local history = {}
    local start = math.max(1, #self._history - limit + 1)
    
    for i = start, #self._history do
        table.insert(history, self._history[i])
    end
    
    return history
end

function StateManager:ClearHistory()
    self._history = {}
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

function StateManager:ParsePath(path: string): {string}
    local segments = {}
    
    for segment in string.gmatch(path, "[^" .. PATH_SEPARATOR .. "]+") do
        table.insert(segments, segment)
    end
    
    return segments
end

function StateManager:ApplyChange(path: string, value: any, oldValue: any)
    -- Apply the change
    self:ApplyChangeInternal(path, value)
    
    -- Record history
    if self._historyEnabled then
        self:RecordChange(path, value, oldValue)
    end
    
    -- Notify subscribers
    self:NotifySubscribers(path, value, oldValue)
    
    -- Update metrics
    self._changeCount = self._changeCount + 1
end

function StateManager:ApplyChangeInternal(path: string, value: any)
    local segments = self:ParsePath(path)
    local current = self._state
    
    -- Navigate to parent
    for i = 1, #segments - 1 do
        local segment = segments[i]
        
        if type(current[segment]) ~= "table" then
            current[segment] = {}
        end
        
        current = current[segment]
    end
    
    -- Set value
    local lastSegment = segments[#segments]
    
    if value == nil then
        current[lastSegment] = nil
    else
        current[lastSegment] = self._utilities.DeepCopy(value)
    end
end

function StateManager:NotifySubscribers(path: string, newValue: any, oldValue: any)
    -- Notify exact path subscribers
    local subs = self._subscriptions[path]
    if subs then
        for i = #subs, 1, -1 do
            local sub = subs[i]
            if sub.active then
                local success, error = pcall(sub.callback, newValue, oldValue, path)
                
                if not success and self._debugMode then
                    warn("[StateManager] Subscriber error:", error)
                end
            else
                table.remove(subs, i)
            end
        end
    end
    
    -- Notify parent path subscribers (e.g., "player" when "player.coins" changes)
    local segments = self:ParsePath(path)
    for i = #segments - 1, 1, -1 do
        local parentPath = table.concat(segments, PATH_SEPARATOR, 1, i)
        local parentSubs = self._subscriptions[parentPath]
        
        if parentSubs then
            local parentValue = self:Get(parentPath)
            
            for j = #parentSubs, 1, -1 do
                local sub = parentSubs[j]
                if sub.active then
                    local success, error = pcall(sub.callback, parentValue, nil, parentPath)
                    
                    if not success and self._debugMode then
                        warn("[StateManager] Parent subscriber error:", error)
                    end
                else
                    table.remove(parentSubs, j)
                end
            end
        end
    end
    
    -- Notify wildcard subscribers
    for i = #self._wildcardSubscriptions, 1, -1 do
        local sub = self._wildcardSubscriptions[i]
        if sub.active then
            local success, error = pcall(sub.callback, newValue, oldValue, path)
            
            if not success and self._debugMode then
                warn("[StateManager] Wildcard subscriber error:", error)
            end
        else
            table.remove(self._wildcardSubscriptions, i)
        end
    end
    
    -- Fire event bus event
    if self._eventBus then
        self._eventBus:Fire("StateChanged", {
            path = path,
            oldValue = oldValue,
            newValue = newValue,
        })
    end
end

function StateManager:NotifyAllSubscribers(oldState: table)
    -- This is called when entire state changes
    for path, subs in pairs(self._subscriptions) do
        local newValue = self:Get(path)
        local oldValue = self:GetValueFromState(oldState, path)
        
        for _, sub in ipairs(subs) do
            if sub.active then
                pcall(sub.callback, newValue, oldValue, path)
            end
        end
    end
    
    -- Notify wildcards
    for _, sub in ipairs(self._wildcardSubscriptions) do
        if sub.active then
            pcall(sub.callback, self._state, oldState, "*")
        end
    end
end

function StateManager:GetValueFromState(state: table, path: string): any
    local segments = self:ParsePath(path)
    local current = state
    
    for _, segment in ipairs(segments) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    
    return current
end

function StateManager:RemoveSubscription(subscription: Subscription)
    subscription.active = false
    self._subscriptionCount = self._subscriptionCount - 1
end

function StateManager:RecordChange(path: string, newValue: any, oldValue: any)
    table.insert(self._history, {
        path = path,
        oldValue = oldValue,
        newValue = newValue,
        timestamp = tick(),
    })
    
    -- Limit history size
    if #self._history > self._maxHistorySize then
        table.remove(self._history, 1)
    end
end

function StateManager:AreEqual(a: any, b: any): boolean
    if a == b then
        return true
    end
    
    if type(a) ~= type(b) then
        return false
    end
    
    if type(a) == "table" then
        -- Compare tables
        for k, v in pairs(a) do
            if not self:AreEqual(v, b[k]) then
                return false
            end
        end
        
        for k, v in pairs(b) do
            if not self:AreEqual(v, a[k]) then
                return false
            end
        end
        
        return true
    end
    
    return false
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function StateManager:DebugPrint()
        print("\n=== StateManager Debug Info ===")
        print("Total changes:", self._changeCount)
        print("Active subscriptions:", self._subscriptionCount)
        print("History entries:", #self._history)
        
        print("\nState structure:")
        local function printTable(t, indent)
            indent = indent or ""
            for k, v in pairs(t) do
                if type(v) == "table" then
                    print(indent .. k .. ": {")
                    printTable(v, indent .. "  ")
                    print(indent .. "}")
                else
                    print(indent .. k .. ":", tostring(v))
                end
            end
        end
        
        printTable(self._state)
        print("============================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function StateManager:Destroy()
    -- Save state if persistence is enabled
    if self._persistenceEnabled then
        self:SaveState()
    end
    
    -- Clear subscriptions
    for _, subs in pairs(self._subscriptions) do
        for _, sub in ipairs(subs) do
            sub.active = false
        end
    end
    
    for _, sub in ipairs(self._wildcardSubscriptions) do
        sub.active = false
    end
    
    self._subscriptions = {}
    self._wildcardSubscriptions = {}
    
    -- Clear state
    self._state = {}
    self._history = {}
    
    self._persistenceEnabled = false
end

return StateManager