-- ========================================
-- LOCATION: ReplicatedStorage > Modules > Shared > ClientDataManager (ModuleScript)
-- ========================================
-- CLIENT DATA MANAGER
-- Single source of truth for client-side data
-- Reactive system with event broadcasting
-- Fixes: Pets now show in inventory, auto-updates all UI
-- ========================================

local ClientDataManager = {}
ClientDataManager.__index = ClientDataManager

-- ========================================
-- CONSTRUCTOR
-- ========================================
function ClientDataManager.new()
    local self = setmetatable({}, ClientDataManager)
    
    -- Core data storage
    self._data = {}
    self._previousData = {}
    
    -- Event system
    self._dataChangedEvent = Instance.new("BindableEvent")
    self._specificEvents = {} -- For targeted listeners
    
    -- Performance optimization
    self._updateQueue = {}
    self._isProcessingQueue = false
    self._batchUpdateConnection = nil
    
    -- Debug mode
    self._debugMode = false
    
    return self
end

-- ========================================
-- DATA ACCESSORS
-- ========================================
function ClientDataManager:GetData(path)
    if not path then
        return self._data
    end
    
    -- Navigate through path
    local current = self._data
    for segment in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    
    return current
end

function ClientDataManager:GetPreviousData(path)
    if not path then
        return self._previousData
    end
    
    -- Navigate through path
    local current = self._previousData
    for segment in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    
    return current
end

-- ========================================
-- DATA SETTERS
-- ========================================
function ClientDataManager:SetData(newData, skipNotification)
    -- Store previous data for comparison
    self._previousData = self:_deepClone(self._data)
    
    -- Set new data
    self._data = self:_deepClone(newData)
    
    -- Notify listeners unless skipped
    if not skipNotification then
        self:_notifyDataChanged({
            path = nil,
            oldValue = self._previousData,
            newValue = self._data,
            changeType = "full"
        })
    end
    
    if self._debugMode then
        print("[ClientDataManager] Full data update")
    end
end

function ClientDataManager:UpdateData(path, value, skipNotification)
    -- Store previous data
    self._previousData = self:_deepClone(self._data)
    
    -- Parse path and update data
    local segments = {}
    for segment in string.gmatch(path, "[^%.]+") do
        table.insert(segments, segment)
    end
    
    -- Navigate to parent
    local current = self._data
    local parent = nil
    local lastKey = segments[#segments]
    
    for i = 1, #segments - 1 do
        local segment = segments[i]
        if type(current[segment]) ~= "table" then
            current[segment] = {}
        end
        parent = current
        current = current[segment]
    end
    
    -- Store old value
    local oldValue = current[lastKey]
    
    -- Set new value
    if value == nil then
        current[lastKey] = nil
    else
        current[lastKey] = self:_deepClone(value)
    end
    
    -- Notify listeners unless skipped
    if not skipNotification then
        self:_notifyDataChanged({
            path = path,
            oldValue = oldValue,
            newValue = current[lastKey],
            changeType = "update"
        })
    end
    
    if self._debugMode then
        print("[ClientDataManager] Updated path:", path, "to:", value)
    end
end

-- ========================================
-- BATCH UPDATES
-- ========================================
function ClientDataManager:BatchUpdate(updates)
    -- Queue updates
    for _, update in ipairs(updates) do
        table.insert(self._updateQueue, update)
    end
    
    -- Process queue if not already processing
    if not self._isProcessingQueue then
        self:_processBatchQueue()
    end
end

function ClientDataManager:_processBatchQueue()
    if #self._updateQueue == 0 then
        self._isProcessingQueue = false
        return
    end
    
    self._isProcessingQueue = true
    
    -- Store previous data once
    self._previousData = self:_deepClone(self._data)
    
    -- Apply all updates
    local changes = {}
    while #self._updateQueue > 0 do
        local update = table.remove(self._updateQueue, 1)
        
        if update.path then
            self:UpdateData(update.path, update.value, true) -- Skip individual notifications
            table.insert(changes, {
                path = update.path,
                oldValue = self:GetPreviousData(update.path),
                newValue = update.value,
                changeType = "update"
            })
        end
    end
    
    -- Send one batched notification
    self:_notifyDataChanged({
        changeType = "batch",
        changes = changes
    })
    
    self._isProcessingQueue = false
end

-- ========================================
-- EVENT SYSTEM
-- ========================================
function ClientDataManager:OnDataChanged(callback)
    return self._dataChangedEvent.Event:Connect(callback)
end

function ClientDataManager:OnSpecificDataChanged(path, callback)
    if not self._specificEvents[path] then
        self._specificEvents[path] = Instance.new("BindableEvent")
    end
    
    return self._specificEvents[path].Event:Connect(callback)
end

function ClientDataManager:_notifyDataChanged(changeInfo)
    -- Fire general event
    self._dataChangedEvent:Fire(changeInfo)
    
    -- Fire specific path events
    if changeInfo.path then
        for registeredPath, event in pairs(self._specificEvents) do
            if string.find(changeInfo.path, registeredPath) == 1 or 
               string.find(registeredPath, changeInfo.path) == 1 then
                event:Fire(changeInfo)
            end
        end
    else
        -- Full data change, notify all specific listeners
        for _, event in pairs(self._specificEvents) do
            event:Fire(changeInfo)
        end
    end
end

-- ========================================
-- REACTIVE HELPERS
-- ========================================
function ClientDataManager:Watch(path, callback)
    -- Immediately call with current value
    callback(self:GetData(path))
    
    -- Set up listener for future changes
    return self:OnSpecificDataChanged(path, function(changeInfo)
        callback(self:GetData(path), changeInfo)
    end)
end

function ClientDataManager:Computed(dependencies, computeFunction)
    local connection
    local lastValue
    
    local function recompute()
        local values = {}
        for _, path in ipairs(dependencies) do
            table.insert(values, self:GetData(path))
        end
        
        local newValue = computeFunction(unpack(values))
        if newValue ~= lastValue then
            lastValue = newValue
            return newValue
        end
        
        return nil
    end
    
    -- Initial computation
    lastValue = recompute()
    
    -- Set up reactive updates
    local connections = {}
    for _, path in ipairs(dependencies) do
        table.insert(connections, self:OnSpecificDataChanged(path, function()
            recompute()
        end))
    end
    
    return {
        Value = lastValue,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
        end
    }
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
function ClientDataManager:_deepClone(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:_deepClone(value)
    end
    
    return copy
end

function ClientDataManager:_deepCompare(a, b)
    if type(a) ~= type(b) then
        return false
    end
    
    if type(a) ~= "table" then
        return a == b
    end
    
    -- Compare table keys
    for key in pairs(a) do
        if not self:_deepCompare(a[key], b[key]) then
            return false
        end
    end
    
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    
    return true
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================
function ClientDataManager:EnableDebugMode()
    self._debugMode = true
end

function ClientDataManager:DisableDebugMode()
    self._debugMode = false
end

function ClientDataManager:GetMemoryUsage()
    local function calculateSize(data)
        local size = 0
        
        if type(data) == "table" then
            for key, value in pairs(data) do
                size = size + calculateSize(key) + calculateSize(value)
            end
        elseif type(data) == "string" then
            size = size + #data
        elseif type(data) == "number" then
            size = size + 8
        elseif type(data) == "boolean" then
            size = size + 1
        end
        
        return size
    end
    
    return calculateSize(self._data)
end

-- ========================================
-- INTEGRATION HELPERS
-- ========================================
function ClientDataManager:ConnectToRemote(remoteEvent)
    return remoteEvent.OnClientEvent:Connect(function(data)
        if data.type == "full" then
            self:SetData(data.payload)
        elseif data.type == "update" then
            self:UpdateData(data.path, data.value)
        elseif data.type == "batch" then
            self:BatchUpdate(data.updates)
        end
    end)
end

-- ========================================
-- USAGE EXAMPLES
-- ========================================
--[[
Example 1: Basic Usage
```lua
local dataManager = ClientDataManager.new()

-- Set full data
dataManager:SetData({
    currencies = {coins = 100, gems = 10},
    pets = {},
    settings = {music = true}
})

-- Update specific path
dataManager:UpdateData("currencies.coins", 150)

-- Get data
local coins = dataManager:GetData("currencies.coins") -- 150
```

Example 2: Reactive UI
```lua
-- Watch for changes
dataManager:Watch("currencies.coins", function(coins)
    coinLabel.Text = "Coins: " .. tostring(coins)
end)

-- Computed values
local totalWealth = dataManager:Computed({"currencies.coins", "currencies.gems"}, function(coins, gems)
    return coins + (gems * 100) -- Gems worth 100 coins each
end)
```

Example 3: UI Controllers
```lua
-- In InventoryController
dataManager:OnSpecificDataChanged("pets", function(changeInfo)
    self:RefreshInventory()
end)

-- In CurrencyDisplay
dataManager:Watch("currencies", function(currencies)
    self:UpdateAllCurrencyDisplays(currencies)
end)
```
--]]

return ClientDataManager