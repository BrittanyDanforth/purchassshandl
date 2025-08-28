--[[
    SanrioTycoonServer
    Main server initialization script
    FIXED VERSION - Handles nil checks properly
]]

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ServerScriptService = game:GetService("ServerScriptService"),
    DataStoreService = game:GetService("DataStoreService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
}

print("[Server] Initializing Sanrio Tycoon Shop v6.0...")

-- ========================================
-- FOLDER SETUP WITH PROPER NIL CHECKS
-- ========================================

-- Wait for ReplicatedStorage folders (with timeout)
local function SafeWaitForChild(parent, childName, timeout)
    timeout = timeout or 10
    local startTime = tick()
    
    while not parent:FindFirstChild(childName) and tick() - startTime < timeout do
        task.wait(0.1)
    end
    
    local child = parent:FindFirstChild(childName)
    if not child then
        warn("[Server] Failed to find " .. childName .. " in " .. parent:GetFullName())
    end
    return child
end

-- Create or get folders
local function GetOrCreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        print("[Server] Created folder:", name)
    end
    return folder
end

-- Setup ReplicatedStorage structure
local SanrioFolder = GetOrCreateFolder(Services.ReplicatedStorage, "SanrioTycoon")
local RemotesFolder = GetOrCreateFolder(SanrioFolder, "Remotes")
local RemoteEventsFolder = GetOrCreateFolder(RemotesFolder, "Events")
local RemoteFunctionsFolder = GetOrCreateFolder(RemotesFolder, "Functions")
local SharedModulesFolder = GetOrCreateFolder(SanrioFolder, "SharedModules")

-- Setup ServerScriptService structure
local ServerModulesFolder = SafeWaitForChild(Services.ServerScriptService, "ServerModules", 5)
if not ServerModulesFolder then
    ServerModulesFolder = GetOrCreateFolder(Services.ServerScriptService, "ServerModules")
end

-- ========================================
-- LOAD MODULES WITH ERROR HANDLING
-- ========================================

local LoadedModules = {}
local Systems = {}

-- Safe module loader
local function LoadModule(folder, moduleName)
    if not folder then
        warn("[Server] Cannot load module " .. moduleName .. " - folder is nil")
        return nil
    end
    
    local moduleScript = folder:FindFirstChild(moduleName)
    if not moduleScript then
        warn("[Server] Module not found:", moduleName)
        return nil
    end
    
    local success, module = pcall(require, moduleScript)
    if not success then
        warn("[Server] Failed to load module " .. moduleName .. ":", module)
        return nil
    end
    
    print("[Server] Loaded module:", moduleName)
    return module
end

-- Load server modules
local ModulesToLoad = {
    "Configuration",
    "DataStoreModule", 
    "PetDatabase",
    "PetSystem",
    "CaseSystem",
    "TradingSystem",
    "BattleSystem",
    "QuestSystem",
    "DailyRewardSystem",
    "AchievementSystem",
    "ClanSystem",
    "MarketSystem",
    "RebirthSystem"
}

for _, moduleName in ipairs(ModulesToLoad) do
    local module = LoadModule(ServerModulesFolder, moduleName)
    if module then
        LoadedModules[moduleName] = module
        Systems[moduleName] = module
    end
end

-- ========================================
-- CREATE REMOTES
-- ========================================

local function CreateRemote(folder, name, type)
    if not folder then return nil end
    
    local existing = folder:FindFirstChild(name)
    if existing then return existing end
    
    local remote = Instance.new(type)
    remote.Name = name
    remote.Parent = folder
    return remote
end

-- RemoteEvents
local RemoteEvents = {
    -- Core
    DataUpdated = CreateRemote(RemoteEventsFolder, "DataUpdated", "RemoteEvent"),
    
    -- Pet System
    PetEquipped = CreateRemote(RemoteEventsFolder, "PetEquipped", "RemoteEvent"),
    PetUnequipped = CreateRemote(RemoteEventsFolder, "PetUnequipped", "RemoteEvent"),
    PetDeleted = CreateRemote(RemoteEventsFolder, "PetDeleted", "RemoteEvent"),
    PetEvolved = CreateRemote(RemoteEventsFolder, "PetEvolved", "RemoteEvent"),
    
    -- Case System
    CaseOpened = CreateRemote(RemoteEventsFolder, "CaseOpened", "RemoteEvent"),
    
    -- Trading
    TradeRequested = CreateRemote(RemoteEventsFolder, "TradeRequested", "RemoteEvent"),
    TradeUpdated = CreateRemote(RemoteEventsFolder, "TradeUpdated", "RemoteEvent"),
    TradeCompleted = CreateRemote(RemoteEventsFolder, "TradeCompleted", "RemoteEvent"),
    TradeCancelled = CreateRemote(RemoteEventsFolder, "TradeCancelled", "RemoteEvent"),
    
    -- Battle
    BattleStarted = CreateRemote(RemoteEventsFolder, "BattleStarted", "RemoteEvent"),
    BattleUpdated = CreateRemote(RemoteEventsFolder, "BattleUpdated", "RemoteEvent"),
    BattleEnded = CreateRemote(RemoteEventsFolder, "BattleEnded", "RemoteEvent"),
    
    -- Notifications
    ShowNotification = CreateRemote(RemoteEventsFolder, "ShowNotification", "RemoteEvent"),
    
    -- Currency
    CurrencyUpdated = CreateRemote(RemoteEventsFolder, "CurrencyUpdated", "RemoteEvent"),
    
    -- Additional Events (missing from client)
    MatchmakingFound = CreateRemote(RemoteEventsFolder, "MatchmakingFound", "RemoteEvent"),
    DailyRewardAvailable = CreateRemote(RemoteEventsFolder, "DailyRewardAvailable", "RemoteEvent"),
    TradeRequest = CreateRemote(RemoteEventsFolder, "TradeRequest", "RemoteEvent"),
    FriendRequest = CreateRemote(RemoteEventsFolder, "FriendRequest", "RemoteEvent"),
    ChatMessage = CreateRemote(RemoteEventsFolder, "ChatMessage", "RemoteEvent"),
}

-- RemoteFunctions
local RemoteFunctions = {
    -- Data
    GetPlayerData = CreateRemote(RemoteFunctionsFolder, "GetPlayerData", "RemoteFunction"),
    
    -- Shop
    GetShopData = CreateRemote(RemoteFunctionsFolder, "GetShopData", "RemoteFunction"),
    PurchaseItem = CreateRemote(RemoteFunctionsFolder, "PurchaseItem", "RemoteFunction"),
    
    -- Cases
    OpenCase = CreateRemote(RemoteFunctionsFolder, "OpenCase", "RemoteFunction"),
    
    -- Pets
    EquipPet = CreateRemote(RemoteFunctionsFolder, "EquipPet", "RemoteFunction"),
    UnequipPet = CreateRemote(RemoteFunctionsFolder, "UnequipPet", "RemoteFunction"),
    DeletePet = CreateRemote(RemoteFunctionsFolder, "DeletePet", "RemoteFunction"),
    EvolvePet = CreateRemote(RemoteFunctionsFolder, "EvolvePet", "RemoteFunction"),
    
    -- Trading
    SendTradeRequest = CreateRemote(RemoteFunctionsFolder, "SendTradeRequest", "RemoteFunction"),
    AcceptTrade = CreateRemote(RemoteFunctionsFolder, "AcceptTrade", "RemoteFunction"),
    DeclineTrade = CreateRemote(RemoteFunctionsFolder, "DeclineTrade", "RemoteFunction"),
    UpdateTradeOffer = CreateRemote(RemoteFunctionsFolder, "UpdateTradeOffer", "RemoteFunction"),
    ConfirmTrade = CreateRemote(RemoteFunctionsFolder, "ConfirmTrade", "RemoteFunction"),
    
    -- Battle
    StartBattle = CreateRemote(RemoteFunctionsFolder, "StartBattle", "RemoteFunction"),
    UseMove = CreateRemote(RemoteFunctionsFolder, "UseMove", "RemoteFunction"),
    
    -- Daily Rewards
    ClaimDailyReward = CreateRemote(RemoteFunctionsFolder, "ClaimDailyReward", "RemoteFunction"),
    GetDailyRewardStatus = CreateRemote(RemoteFunctionsFolder, "GetDailyRewardStatus", "RemoteFunction"),
    
    -- Additional Functions (missing from client)
    -- Settings
    LoadSettings = CreateRemote(RemoteFunctionsFolder, "LoadSettings", "RemoteFunction"),
    UpdateSettings = CreateRemote(RemoteFunctionsFolder, "UpdateSettings", "RemoteFunction"),
    
    -- Data Sync
    SyncDataChanges = CreateRemote(RemoteFunctionsFolder, "SyncDataChanges", "RemoteFunction"),
    
    -- Pet Management
    LockPet = CreateRemote(RemoteFunctionsFolder, "LockPet", "RemoteFunction"),
    UnlockPet = CreateRemote(RemoteFunctionsFolder, "UnlockPet", "RemoteFunction"),
    RenamePet = CreateRemote(RemoteFunctionsFolder, "RenamePet", "RemoteFunction"),
    
    -- Trading (additional)
    RequestTrade = CreateRemote(RemoteFunctionsFolder, "RequestTrade", "RemoteFunction"),
    UpdateTrade = CreateRemote(RemoteFunctionsFolder, "UpdateTrade", "RemoteFunction"),
    
    -- Battle Matchmaking
    JoinBattleMatchmaking = CreateRemote(RemoteFunctionsFolder, "JoinBattleMatchmaking", "RemoteFunction"),
    CancelMatchmaking = CreateRemote(RemoteFunctionsFolder, "CancelMatchmaking", "RemoteFunction"),
    JoinBattle = CreateRemote(RemoteFunctionsFolder, "JoinBattle", "RemoteFunction"),
    SelectBattleMove = CreateRemote(RemoteFunctionsFolder, "SelectBattleMove", "RemoteFunction"),
    ForfeitBattle = CreateRemote(RemoteFunctionsFolder, "ForfeitBattle", "RemoteFunction"),
    
    -- Shop (additional)
    PurchaseGamepass = CreateRemote(RemoteFunctionsFolder, "PurchaseGamepass", "RemoteFunction"),
    PurchaseCurrency = CreateRemote(RemoteFunctionsFolder, "PurchaseCurrency", "RemoteFunction"),
    
    -- Clan System
    SendClanInvite = CreateRemote(RemoteFunctionsFolder, "SendClanInvite", "RemoteFunction"),
    AcceptClanInvite = CreateRemote(RemoteFunctionsFolder, "AcceptClanInvite", "RemoteFunction"),
    KickMember = CreateRemote(RemoteFunctionsFolder, "KickMember", "RemoteFunction"),
}

-- ========================================
-- INITIALIZE SYSTEMS
-- ========================================

-- Initialize each system with error handling
for systemName, system in pairs(Systems) do
    if system and system.Initialize then
        local success, err = pcall(system.Initialize, RemoteEvents, RemoteFunctions)
        if not success then
            warn("[Server] Failed to initialize " .. systemName .. ":", err)
        else
            print("[Server] Initialized " .. systemName)
        end
    end
end

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================

local function OnPlayerAdded(player)
    print("[Server] Player joined:", player.Name)
    
    -- Load player data
    if Systems.DataStoreModule then
        local success, data = pcall(function()
            return Systems.DataStoreModule:LoadPlayerData(player)
        end)
        
        if not success then
            warn("[Server] Failed to load data for", player.Name, ":", data)
        end
    end
end

local function OnPlayerRemoving(player)
    print("[Server] Player leaving:", player.Name)
    
    -- Save player data
    if Systems.DataStoreModule then
        local success, err = pcall(function()
            Systems.DataStoreModule:SavePlayerData(player)
        end)
        
        if not success then
            warn("[Server] Failed to save data for", player.Name, ":", err)
        end
    end
end

-- Connect player events
Services.Players.PlayerAdded:Connect(OnPlayerAdded)
Services.Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Handle existing players
for _, player in ipairs(Services.Players:GetPlayers()) do
    task.spawn(OnPlayerAdded, player)
end

-- ========================================
-- REMOTE HANDLERS
-- ========================================

-- Shop data request
if RemoteFunctions.GetShopData then
    RemoteFunctions.GetShopData.OnServerInvoke = function(player)
        if Systems.CaseSystem and Systems.CaseSystem.GetEggData then
            return Systems.CaseSystem:GetEggData()
        end
        
        -- Return default data if system not loaded
        return {
            {id = "starter_egg", name = "Starter Egg", price = 100, currency = "coins"},
            {id = "rare_egg", name = "Rare Egg", price = 1000, currency = "coins"},
            {id = "epic_egg", name = "Epic Egg", price = 50, currency = "gems"}
        }
    end
end

-- Player data request
if RemoteFunctions.GetPlayerData then
    RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
        if Systems.DataStoreModule and Systems.DataStoreModule.GetPlayerData then
            return Systems.DataStoreModule:GetPlayerData(player)
        end
        
        -- Return default data
        return {
            currencies = {coins = 1000, gems = 50},
            pets = {},
            inventory = {},
            settings = {}
        }
    end
end

-- Settings handlers
if RemoteFunctions.LoadSettings then
    RemoteFunctions.LoadSettings.OnServerInvoke = function(player)
        -- Return default settings or load from datastore
        return {
            soundEnabled = true,
            musicEnabled = true,
            particlesEnabled = true,
            shadowsEnabled = true,
        }
    end
end

if RemoteFunctions.UpdateSettings then
    RemoteFunctions.UpdateSettings.OnServerInvoke = function(player, settings)
        -- TODO: Save settings to datastore
        return true
    end
end

print("[Server] Sanrio Tycoon Shop initialized successfully!")
print("[Server] Modules loaded:", #LoadedModules)

-- Export for other scripts
_G.SanrioTycoonServer = {
    Systems = Systems,
    RemoteEvents = RemoteEvents,
    RemoteFunctions = RemoteFunctions,
    LoadedModules = LoadedModules
}

return _G.SanrioTycoonServer