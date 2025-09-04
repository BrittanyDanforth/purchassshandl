--[[
    Module: DataCache
    Description: Local data caching layer with change detection and memory optimization
    Manages all player data, pets, settings, and cached assets
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)

local DataCache = {}
DataCache.__index = DataCache

-- ========================================
-- DEFAULT DATA STRUCTURES
-- ========================================

local DEFAULT_PLAYER_DATA = {
    currencies = {
        coins = 0,
        gems = 0,
        tickets = 0,
        candies = 0,
        stars = 0,
    },
    pets = {},
    inventory = {},
    equipped = {},  -- Array of equipped pet IDs
    settings = {
        musicVolume = 0.5,
        sfxVolume = 0.5,
        particlesEnabled = true,
        lowQualityMode = false,
        autoDelete = {
            enabled = false,
            rarities = {}
        },
        uiScale = 1,
        language = "en",
    },
    quests = {
        daily = {},
        weekly = {},
        special = {},
    },
    achievements = {},
    stats = {
        totalPets = 0,
        totalCoins = 0,
        totalGems = 0,
        eggsOpened = 0,
        trades = 0,
        battles = 0,
        wins = 0,
        playtime = 0,
        achievements = 0,
    },
    dailyReward = {
        streak = 0,
        lastClaim = 0,
        nextReward = 0,
        currentDay = 1,
        multiplier = 1,
    },
    battlepass = {
        level = 1,
        experience = 0,
        claimed = {},
        premium = false,
    },
    clan = nil,
    rebirth = {
        level = 0,
        multiplier = 1,
    },
}

-- ========================================
-- INITIALIZATION
-- ========================================

function DataCache.new(dependencies)
    local self = setmetatable({}, DataCache)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    self._stateManager = dependencies.StateManager
    self._eventBus = dependencies.EventBus
    self._remoteManager = dependencies.RemoteManager
    
    -- Data storage
    self._playerData = self._utilities.DeepCopy(DEFAULT_PLAYER_DATA)
    self._petDatabase = {}
    self._eggDatabase = {}
    self._gamepassDatabase = {}
    self._questDatabase = {}
    
    -- Cache storage
    self._assetCache = {
        images = {},
        sounds = {},
        models = {},
    }
    
    -- Change tracking
    self._changeListeners = {}
    self._pendingChanges = {}
    self._lastSyncTime = 0
    
    -- Performance
    self._cacheHits = 0
    self._cacheMisses = 0
    self._totalRequests = 0
    
    -- Settings
    self._autoSyncEnabled = true
    self._syncInterval = 5 -- seconds
    self._maxCacheSize = 1000
    self._debugMode = self._config.DEBUG.ENABLED
    
    self:Initialize()
    
    return self
end

function DataCache:Initialize()
    -- Set up state manager integration if available
    if self._stateManager then
        self._stateManager:Set("player", self._playerData)
        
        -- Subscribe to state changes
        self._stateManager:Subscribe("player", function(newData)
            if newData then
                self:UpdatePlayerData(newData, true) -- true = from state manager
            end
        end)
    end
    
    -- Set up auto-sync
    if self._autoSyncEnabled then
        task.spawn(function()
            while self._autoSyncEnabled do
                task.wait(self._syncInterval)
                self:SyncPendingChanges()
            end
        end)
    end
    
    -- Listen for remote data updates
    if self._eventBus then
        self._eventBus:On("DataUpdated", function(data)
            self:HandleRemoteUpdate(data)
        end)
        
        self._eventBus:On("CurrencyUpdated", function(currencies)
            self:UpdateCurrencies(currencies)
        end)
        
        self._eventBus:On("PetDeleted", function(petIds)
            self:RemovePets(petIds)
        end)
    end
end

-- ========================================
-- PLAYER DATA ACCESS
-- ========================================

function DataCache:Get(path: string?): any
    if not path or path == "" then
        return self:GetPlayerData()
    end
    
    -- Parse path and traverse data
    local parts = string.split(path, ".")
    local current = self._playerData
    
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[part]
    end
    
    return current
end

function DataCache:Set(path: string, value: any): boolean
    if not path or path == "" then
        warn("[DataCache] Cannot set value without path")
        return false
    end
    
    -- Parse path and traverse data
    local parts = string.split(path, ".")
    local current = self._playerData
    
    -- Navigate to parent of target
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current) ~= "table" then
            warn("[DataCache] Cannot set value - invalid path:", path)
            return false
        end
        
        -- Create intermediate tables if they don't exist
        if not current[part] then
            current[part] = {}
        end
        current = current[part]
    end
    
    -- Set the value
    local lastPart = parts[#parts]
    local oldValue = current[lastPart]
    current[lastPart] = value
    
    -- Notify changes
    self:NotifyChange(parts[1], lastPart, value, oldValue)
    
    -- Save to server if configured
    if self._config.AUTO_SAVE_TO_SERVER then
        self:SaveToServer()
    end
    
    return true
end

function DataCache:GetPlayerData(): Types.PlayerData
    return self._utilities.DeepCopy(self._playerData)
end

function DataCache:GetCurrency(currencyType: string): number
    return self._playerData.currencies[currencyType] or 0
end

function DataCache:GetCurrencies(): Types.CurrencyData
    return self._utilities.DeepCopy(self._playerData.currencies)
end

function DataCache:GetPets(): {[string]: Types.PetData}
    return self._utilities.DeepCopy(self._playerData.pets)
end

function DataCache:GetPet(petId: string): Types.PetData?
    local pet = self._playerData.pets[petId]
    return pet and self._utilities.DeepCopy(pet) or nil
end

function DataCache:GetEquippedPets(): {string}
    return self._utilities.DeepCopy(self._playerData.equipped)
end

function DataCache:IsPetEquipped(petId: string): boolean
    return self._utilities.TableContains(self._playerData.equipped, petId)
end

function DataCache:GetSettings(): Types.SettingsData
    return self._utilities.DeepCopy(self._playerData.settings)
end

function DataCache:GetSetting(settingPath: string): any
    local segments = string.split(settingPath, ".")
    local current = self._playerData.settings
    
    for _, segment in ipairs(segments) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    
    return current
end

function DataCache:GetQuests(questType: "daily" | "weekly" | "special"): {[string]: Types.QuestData}
    return self._utilities.DeepCopy(self._playerData.quests[questType] or {})
end

function DataCache:GetStats(): Types.PlayerStats
    return self._utilities.DeepCopy(self._playerData.stats)
end

function DataCache:GetDailyRewardData(): Types.DailyRewardData
    return self._utilities.DeepCopy(self._playerData.dailyReward)
end

-- ========================================
-- DATA UPDATES
-- ========================================

function DataCache:UpdatePlayerData(data: Types.PlayerData, fromStateManager: boolean?)
    local oldData = self._utilities.DeepCopy(self._playerData)
    
    -- Merge data
    self._playerData = self._utilities.DeepCopy(data)
    
    -- Detect changes
    local changes = self:DetectChanges(oldData, self._playerData)
    
    if #changes > 0 then
        -- Update state manager if not from state manager
        if self._stateManager and not fromStateManager then
            self._stateManager:Set("player", self._playerData)
        end
        
        -- Notify listeners
        self:NotifyChanges(changes)
        
        -- Fire events
        if self._eventBus then
            self._eventBus:Fire("PlayerDataUpdated", self._playerData)
        end
    end
end

function DataCache:UpdateCurrency(currencyType: string, amount: number)
    local oldAmount = self._playerData.currencies[currencyType] or 0
    
    if oldAmount ~= amount then
        self._playerData.currencies[currencyType] = amount
        
        -- Update state
        if self._stateManager then
            self._stateManager:Set("player.currencies." .. currencyType, amount)
        end
        
        -- Notify
        self:NotifyChange("currency", currencyType, amount, oldAmount)
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("CurrencyChanged", {
                type = currencyType,
                oldAmount = oldAmount,
                newAmount = amount,
                difference = amount - oldAmount,
            })
        end
    end
end

function DataCache:UpdateCurrencies(currencies: Types.CurrencyData)
    local oldCurrencies = self._utilities.DeepCopy(self._playerData.currencies)
    local hasChanges = false
    
    for currencyType, amount in pairs(currencies) do
        if self._playerData.currencies[currencyType] ~= amount then
            self._playerData.currencies[currencyType] = amount
            hasChanges = true
        end
    end
    
    if hasChanges then
        -- Update state
        if self._stateManager then
            self._stateManager:Set("player.currencies", self._playerData.currencies)
        end
        
        -- Notify
        self:NotifyChange("currencies", nil, currencies, oldCurrencies)
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("CurrenciesUpdated", currencies)
        end
    end
end

function DataCache:UpdatePets(pets: {[string]: Types.PetData})
    self._playerData.pets = self._utilities.DeepCopy(pets)
    
    -- Update stats
    self._playerData.stats.totalPets = 0
    for _ in pairs(pets) do
        self._playerData.stats.totalPets = self._playerData.stats.totalPets + 1
    end
    
    -- Update state
    if self._stateManager then
        self._stateManager:Set("player.pets", self._playerData.pets)
        self._stateManager:Set("player.stats.totalPets", self._playerData.stats.totalPets)
    end
    
    -- Notify
    self:NotifyChange("pets", nil, pets, nil)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("PetsUpdated", pets)
    end
end

function DataCache:AddPet(petData: Types.PetData)
    if not petData.id then
        warn("[DataCache] Cannot add pet without ID")
        return
    end
    
    self._playerData.pets[petData.id] = self._utilities.DeepCopy(petData)
    self._playerData.stats.totalPets = self._playerData.stats.totalPets + 1
    
    -- Update state
    if self._stateManager then
        self._stateManager:Set("player.pets." .. petData.id, petData)
        self._stateManager:Set("player.stats.totalPets", self._playerData.stats.totalPets)
    end
    
    -- Notify
    self:NotifyChange("pet", petData.id, petData, nil)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("PetAdded", petData)
    end
end

function DataCache:RemovePet(petId: string)
    local pet = self._playerData.pets[petId]
    if not pet then
        return
    end
    
    -- Remove from pets
    self._playerData.pets[petId] = nil
    self._playerData.stats.totalPets = math.max(0, self._playerData.stats.totalPets - 1)
    
    -- Remove from equipped if equipped
    local equippedIndex = table.find(self._playerData.equipped, petId)
    if equippedIndex then
        table.remove(self._playerData.equipped, equippedIndex)
    end
    
    -- Update state
    if self._stateManager then
        self._stateManager:Set("player.pets." .. petId, nil)
        self._stateManager:Set("player.equipped", self._playerData.equipped)
        self._stateManager:Set("player.stats.totalPets", self._playerData.stats.totalPets)
    end
    
    -- Notify
    self:NotifyChange("pet", petId, nil, pet)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("PetRemoved", petId)
    end
end

function DataCache:RemovePets(petIds: {string})
    for _, petId in ipairs(petIds) do
        self:RemovePet(petId)
    end
end

function DataCache:UpdatePetProperty(petId: string, property: string, value: any)
    local pet = self._playerData.pets[petId]
    if not pet then
        warn("[DataCache] Pet not found:", petId)
        return
    end
    
    local oldValue = pet[property]
    pet[property] = value
    
    -- Update state
    if self._stateManager then
        self._stateManager:Set("player.pets." .. petId .. "." .. property, value)
    end
    
    -- Notify
    self:NotifyChange("petProperty", petId, {property = property, value = value}, oldValue)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("PetPropertyChanged", {
            petId = petId,
            property = property,
            oldValue = oldValue,
            newValue = value,
        })
    end
end

function DataCache:SetEquippedPets(petIds: {string})
    local oldEquipped = self._utilities.DeepCopy(self._playerData.equipped)
    self._playerData.equipped = self._utilities.DeepCopy(petIds)
    
    -- Update pet equipped status
    for _, pet in pairs(self._playerData.pets) do
        pet.equipped = self._utilities.TableContains(petIds, pet.id)
    end
    
    -- Update state
    if self._stateManager then
        self._stateManager:Set("player.equipped", self._playerData.equipped)
        self._stateManager:Set("player.pets", self._playerData.pets)
    end
    
    -- Notify
    self:NotifyChange("equipped", nil, petIds, oldEquipped)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("EquippedPetsChanged", petIds)
    end
end

function DataCache:UpdateSettings(settings: Types.SettingsData)
    local oldSettings = self._utilities.DeepCopy(self._playerData.settings)
    self._playerData.settings = self._utilities.DeepCopy(settings)
    
    -- Update state
    if self._stateManager then
        self._stateManager:Set("player.settings", self._playerData.settings)
    end
    
    -- Notify
    self:NotifyChange("settings", nil, settings, oldSettings)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("SettingsUpdated", settings)
    end
end

function DataCache:UpdateSetting(settingPath: string, value: any)
    local segments = string.split(settingPath, ".")
    local current = self._playerData.settings
    
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
    local oldValue = current[lastSegment]
    current[lastSegment] = value
    
    -- Update state
    if self._stateManager then
        self._stateManager:Set("player.settings." .. settingPath, value)
    end
    
    -- Notify
    self:NotifyChange("setting", settingPath, value, oldValue)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("SettingChanged", {
            path = settingPath,
            oldValue = oldValue,
            newValue = value,
        })
    end
end

-- ========================================
-- DATABASE ACCESS
-- ========================================

function DataCache:GetPetDatabase(): {[string]: Types.PetDefinition}
    return self._utilities.DeepCopy(self._petDatabase)
end

function DataCache:GetPetDefinition(petId: string): Types.PetDefinition?
    local def = self._petDatabase[petId]
    return def and self._utilities.DeepCopy(def) or nil
end

function DataCache:SetPetDatabase(database: {[string]: Types.PetDefinition})
    self._petDatabase = self._utilities.DeepCopy(database)
    
    if self._eventBus then
        self._eventBus:Fire("PetDatabaseLoaded", self._petDatabase)
    end
end

function DataCache:GetEggDatabase(): table
    return self._utilities.DeepCopy(self._eggDatabase)
end

function DataCache:SetEggDatabase(database: table)
    self._eggDatabase = self._utilities.DeepCopy(database)
    
    if self._eventBus then
        self._eventBus:Fire("EggDatabaseLoaded", self._eggDatabase)
    end
end

-- ========================================
-- ASSET CACHING
-- ========================================

function DataCache:CacheAsset(assetType: "image" | "sound" | "model", assetId: string, asset: any)
    local cache = self._assetCache[assetType .. "s"]
    if not cache then
        warn("[DataCache] Invalid asset type:", assetType)
        return
    end
    
    -- Check cache size
    local cacheSize = 0
    for _ in pairs(cache) do
        cacheSize = cacheSize + 1
    end
    
    if cacheSize >= self._maxCacheSize then
        -- Remove oldest entry (simple FIFO)
        local oldestKey = next(cache)
        if oldestKey then
            cache[oldestKey] = nil
        end
    end
    
    cache[assetId] = {
        asset = asset,
        timestamp = tick(),
        accessCount = 0,
    }
    
    self._cacheHits = self._cacheHits + 1
end

function DataCache:GetCachedAsset(assetType: "image" | "sound" | "model", assetId: string): any?
    local cache = self._assetCache[assetType .. "s"]
    if not cache then
        return nil
    end
    
    local entry = cache[assetId]
    if entry then
        entry.accessCount = entry.accessCount + 1
        self._cacheHits = self._cacheHits + 1
        return entry.asset
    end
    
    self._cacheMisses = self._cacheMisses + 1
    return nil
end

function DataCache:ClearAssetCache(assetType: string?)
    if assetType then
        local cache = self._assetCache[assetType .. "s"]
        if cache then
            for key in pairs(cache) do
                cache[key] = nil
            end
        end
    else
        -- Clear all caches
        for _, cache in pairs(self._assetCache) do
            for key in pairs(cache) do
                cache[key] = nil
            end
        end
    end
end

-- ========================================
-- CHANGE DETECTION & NOTIFICATION
-- ========================================

function DataCache:DetectChanges(oldData: table, newData: table, path: string?): {Types.StateChange}
    path = path or ""
    local changes = {}
    
    -- Check for additions and modifications
    for key, newValue in pairs(newData) do
        local fullPath = path == "" and key or path .. "." .. key
        local oldValue = oldData[key]
        
        if type(newValue) == "table" and type(oldValue) == "table" then
            -- Recursive check
            local subChanges = self:DetectChanges(oldValue, newValue, fullPath)
            for _, change in ipairs(subChanges) do
                table.insert(changes, change)
            end
        elseif oldValue ~= newValue then
            table.insert(changes, {
                path = fullPath,
                oldValue = oldValue,
                newValue = newValue,
                timestamp = tick(),
            })
        end
    end
    
    -- Check for deletions
    for key, oldValue in pairs(oldData) do
        if newData[key] == nil then
            local fullPath = path == "" and key or path .. "." .. key
            table.insert(changes, {
                path = fullPath,
                oldValue = oldValue,
                newValue = nil,
                timestamp = tick(),
            })
        end
    end
    
    return changes
end

function DataCache:OnDataChanged(dataType: string, callback: (data: any, oldData: any) -> ()): Types.Connection
    local id = self._utilities.CreateUUID()
    
    if not self._changeListeners[dataType] then
        self._changeListeners[dataType] = {}
    end
    
    self._changeListeners[dataType][id] = callback
    
    return {
        Disconnect = function()
            if self._changeListeners[dataType] then
                self._changeListeners[dataType][id] = nil
            end
        end,
        Connected = true,
    }
end

-- Alias for OnDataChanged for compatibility
function DataCache:Watch(dataType: string, callback: (data: any, oldData: any) -> ()): Types.Connection
    return self:OnDataChanged(dataType, callback)
end

function DataCache:NotifyChange(dataType: string, key: string?, newValue: any, oldValue: any)
    local listeners = self._changeListeners[dataType]
    if listeners then
        for _, callback in pairs(listeners) do
            task.spawn(callback, newValue, oldValue, key)
        end
    end
    
    -- Also notify wildcard listeners
    local wildcardListeners = self._changeListeners["*"]
    if wildcardListeners then
        for _, callback in pairs(wildcardListeners) do
            task.spawn(callback, {
                type = dataType,
                key = key,
                newValue = newValue,
                oldValue = oldValue,
            })
        end
    end
end

function DataCache:NotifyChanges(changes: {Types.StateChange})
    for _, change in ipairs(changes) do
        -- Determine data type from path
        local segments = string.split(change.path, ".")
        local dataType = segments[1]
        
        self:NotifyChange(dataType, change.path, change.newValue, change.oldValue)
    end
end

-- ========================================
-- REMOTE SYNCHRONIZATION
-- ========================================

function DataCache:RequestInitialData()
    if not self._remoteManager then
        warn("[DataCache] RemoteManager not available")
        return
    end
    
    -- Request initial data from server
    task.spawn(function()
        local result = self._remoteManager:InvokeServer("GetPlayerData")
        
        if result and result.success and result.data then
            self:UpdatePlayerData(result.data)
            
            if self._debugMode then
                print("[DataCache] Initial data loaded")
            end
        else
            warn("[DataCache] Failed to load initial data")
        end
    end)
end

function DataCache:HandleRemoteUpdate(data: any)
    -- Handle different types of updates
    if data.type == "full" then
        self:UpdatePlayerData(data.playerData)
    elseif data.type == "currencies" then
        self:UpdateCurrencies(data.currencies)
    elseif data.type == "pets" then
        self:UpdatePets(data.pets)
    elseif data.type == "pet" then
        if data.action == "add" then
            self:AddPet(data.pet)
        elseif data.action == "remove" then
            self:RemovePet(data.petId)
        elseif data.action == "update" then
            self:UpdatePetProperty(data.petId, data.property, data.value)
        end
    elseif data.type == "settings" then
        self:UpdateSettings(data.settings)
    elseif data.type == "quest" then
        -- Update specific quest
        if data.questType and data.questId then
            self._playerData.quests[data.questType][data.questId] = data.quest
            
            if self._stateManager then
                self._stateManager:Set("player.quests." .. data.questType .. "." .. data.questId, data.quest)
            end
        end
    end
end

function DataCache:QueueChange(changeType: string, data: any)
    table.insert(self._pendingChanges, {
        type = changeType,
        data = data,
        timestamp = tick(),
    })
end

function DataCache:SyncPendingChanges()
    if #self._pendingChanges == 0 then
        return
    end
    
    if not self._remoteManager then
        return
    end
    
    local changes = self._pendingChanges
    self._pendingChanges = {}
    
    -- Send to server
    task.spawn(function()
        local result = self._remoteManager:InvokeServer("SyncDataChanges", changes)
        
        if not result or not result.success then
            -- Re-queue failed changes
            for _, change in ipairs(changes) do
                table.insert(self._pendingChanges, change)
            end
            
            if self._debugMode then
                warn("[DataCache] Failed to sync changes")
            end
        end
    end)
    
    self._lastSyncTime = tick()
end

-- ========================================
-- DEBUGGING & STATS
-- ========================================

function DataCache:GetCacheStats(): table
    local stats = {
        cacheHits = self._cacheHits,
        cacheMisses = self._cacheMisses,
        hitRate = self._totalRequests > 0 and (self._cacheHits / self._totalRequests) or 0,
        assetCounts = {},
        pendingChanges = #self._pendingChanges,
        lastSyncTime = self._lastSyncTime,
    }
    
    for assetType, cache in pairs(self._assetCache) do
        local count = 0
        for _ in pairs(cache) do
            count = count + 1
        end
        stats.assetCounts[assetType] = count
    end
    
    return stats
end

if Config.DEBUG.ENABLED then
    function DataCache:DebugPrint()
        print("\n=== DataCache Debug Info ===")
        
        local stats = self:GetCacheStats()
        print("Cache Hit Rate:", string.format("%.2f%%", stats.hitRate * 100))
        print("Pending Changes:", stats.pendingChanges)
        
        print("\nAsset Cache:")
        for assetType, count in pairs(stats.assetCounts) do
            print("  " .. assetType .. ":", count)
        end
        
        print("\nPlayer Data:")
        print("  Currencies:")
        for currency, amount in pairs(self._playerData.currencies) do
            print("    " .. currency .. ":", self._utilities.FormatNumber(amount))
        end
        
        print("  Pets:", self._playerData.stats.totalPets)
        print("  Equipped:", #self._playerData.equipped)
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function DataCache:Destroy()
    -- Sync any pending changes
    if #self._pendingChanges > 0 then
        self:SyncPendingChanges()
    end
    
    -- Stop auto-sync
    self._autoSyncEnabled = false
    
    -- Clear listeners
    self._changeListeners = {}
    
    -- Clear cache
    self:ClearAssetCache()
    
    -- Clear data
    self._playerData = {}
    self._petDatabase = {}
    self._eggDatabase = {}
    self._gamepassDatabase = {}
end

return DataCache