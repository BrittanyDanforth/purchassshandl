--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                    SANRIO TYCOON SERVER - COMPLETE v13.0                             ║
    ║                    PLACE IN: ServerScriptService                                     ║
    ║                    NAME AS: SanrioTycoonServer                                       ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ========================================
-- SERVICES
-- ========================================
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

print("🚀 [BOOTSTRAP] Starting Sanrio Tycoon initialization sequence...")

-- ========================================
-- CONFIGURATION
-- ========================================
local CONFIG = {
    AUTO_SAVE_INTERVAL = 300, -- 5 minutes
    DATA_STORE_KEY = "SanrioTycoon_PlayerData_v1",
    DEBUG_MODE = false,
    
    -- Remote limits
    REMOTE_RATE_LIMITS = {
        OpenCase = {rate = 1, per = 0.5}, -- 1 per 0.5 seconds
        Trade = {rate = 1, per = 2}, -- 1 per 2 seconds
        Market = {rate = 5, per = 10}, -- 5 per 10 seconds
    }
}

-- ========================================
-- FOLDER STRUCTURE CREATION
-- ========================================
print("📁 [BOOTSTRAP] Creating folder structure...")

local function createFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

-- Server folders
local ServerModules = createFolder(ServerScriptService, "ServerModules")
local Systems = createFolder(ServerModules, "Systems")
local Services = createFolder(ServerModules, "Services")
local DataModules = createFolder(ServerModules, "Data")

-- Storage folders
local PlayerData = createFolder(ServerStorage, "PlayerData")
local Templates = createFolder(ServerStorage, "Templates")

-- ReplicatedStorage folders
local Modules = createFolder(ReplicatedStorage, "Modules")
local SharedModules = createFolder(Modules, "Shared")
local ClientModules = createFolder(Modules, "Client")
local RemoteEvents = createFolder(ReplicatedStorage, "RemoteEvents")
local RemoteFunctions = createFolder(ReplicatedStorage, "RemoteFunctions")
local Assets = createFolder(ReplicatedStorage, "Assets")

print("✅ [BOOTSTRAP] Folder structure ready!")

-- ========================================
-- REMOTE CREATION
-- ========================================
print("🔌 [BOOTSTRAP] Creating RemoteEvents and RemoteFunctions...")

-- RemoteEvents
local eventNames = {
    -- Core
    "DataLoaded", "DataUpdated", "CurrencyUpdated", "InventoryUpdated",
    
    -- Pets
    "CaseOpened", "PetUpdated", "PetLevelUp", "PetDeleted", "PetEvolved", "PetFused",
    
    -- Trading
    "TradeStarted", "TradeUpdated", "TradeCompleted", "TradeCancelled", "TradeRequest",
    
    -- Market
    "MarketListingCreated", "MarketListingCancelled", "MarketListingPurchased",
    "MarketPurchaseComplete", "MarketUpdated",
    
    -- Clan System
    "ClanCreated", "ClanJoined", "ClanLeft", "ClanKicked", "ClanUpdated",
    "ClanMemberJoined", "ClanMemberLeft", "ClanMemberKicked", "ClanMemberPromoted",
    "ClanDonationMade", "ClanBankUpdated", "ClanLevelUp", "ClanInfoUpdated",
    "ClanInviteReceived", "ClanInvite", "ClanWarRequest", "ClanWarStarted", 
    "ClanWarEnded", "ClanDisbanded",
    
    -- Battle System
    "BattleStarted", "BattleEnded", "BattleReady", "BattleTurnCompleted",
    "MatchmakingFound",
    
    -- Rebirth System
    "RebirthPerformed", "RebirthCompleted", "RebirthItemPurchased", 
    "RebirthUpgradeActivated",
    
    -- Daily/Quest/Achievement
    "DailyRewardClaimed", "DailyRewardUpdated", "DailyRewardAvailable",
    "QuestsUpdated", "QuestCompleted", "QuestRewardClaimed",
    "AchievementUnlocked",
    
    -- Social
    "FriendRequest", "ChatMessage", "GlobalAnnouncement",
    
    -- Notifications
    "NotificationSent", "ShowAdminNotification",
    
    -- Game Events
    "MinigameStarted", "MinigameEnded", "TournamentStarted", "TournamentEnded",
    "RaidStarted", "RaidCompleted", "DungeonStarted", "DungeonCompleted",
    "WorldBossSpawned", "WorldBossDefeated", "SeasonChanged", "WeatherChanged",
    "AuctionBidPlaced", "AuctionEnded"
}

for _, eventName in ipairs(eventNames) do
    local event = RemoteEvents:FindFirstChild(eventName)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = RemoteEvents
    end
end

-- RemoteFunctions
local functionNames = {
    -- Data
    "GetPlayerData", "SyncDataChanges",
    
    -- Pets
    "OpenCase", "EquipPet", "UnequipPet", "DeletePet", "MassDeletePets",
    "LockPet", "UnlockPet", "EvolvePet", "FusePets", "RenamePet", "CustomizePet",
    "SetBattleTeam", "SellPet",
    
    -- Trading
    "StartTrade", "RequestTrade", "UpdateTrade", "AddTradeItem", "RemoveTradeItem",
    "SetTradeCurrency", "ConfirmTrade", "CancelTrade", "GetRecentTradePartners",
    
    -- Market
    "CreateMarketListing", "CancelMarketListing", "PurchaseMarketListing",
    "SearchMarketListings", "GetPlayerListings", "GetRecentSales", "GetPriceHistory",
    
    -- Shop
    "GetShopData", "PurchaseItem", "PurchaseCurrency", "PurchaseGamepass",
    
    -- Clan
    "CreateClan", "JoinClan", "LeaveClan", "InviteToClan", "SendClanInvite",
    "AcceptClanInvite", "KickFromClan", "KickMember", "PromoteMember", "DemoteMember",
    "DonateToClan", "GetClanList", "StartClanWar",
    
    -- Battle
    "StartBattle", "JoinBattle", "JoinBattleMatchmaking", "CancelMatchmaking",
    "BattleAction", "SelectBattleMove", "ForfeitBattle",
    
    -- Rebirth
    "PerformRebirth", "GetRebirthInfo", "GetRebirthShop", "PurchaseRebirthItem",
    
    -- Daily/Quest
    "GetDailyRewards", "ClaimDailyReward", "ClaimQuest", "AbandonQuest",
    
    -- Social/Settings
    "UpdateSettings", "SaveSettings", "LoadSettings",
    
    -- Housing
    "PurchaseHouse", "PlaceFurniture",
    
    -- Minigames/Events
    "StartMinigame", "MinigameAction", "ClaimMinigameReward",
    "JoinTournament", "LeaveTournament", "JoinRaid", "LeaveRaid",
    "JoinDungeon", "LeaveDungeon", "GetLeaderboards",
    
    -- Debug (admin only)
    "DebugGivePet", "DebugGiveCurrency", "DebugSetLevel"
}

for _, functionName in ipairs(functionNames) do
    local func = RemoteFunctions:FindFirstChild(functionName)
    if not func then
        func = Instance.new("RemoteFunction")
        func.Name = functionName
        func.Parent = RemoteFunctions
    end
end

print("✅ [BOOTSTRAP] All remotes created!")

-- ========================================
-- MODULE LOADING SYSTEM
-- ========================================
print("📚 [BOOTSTRAP] Loading modules in dependency order...")

local loadedModules = {}
local moduleLoadOrder = {
    -- Core modules first
    "Configuration",
    "Janitor",
    "DeltaNetworking",
    
    -- Data layer
    "DataStoreModule",
    
    -- Systems
    "PetDatabase",
    "PetSystem",
    "CaseSystem",
    "TradingSystem",
    "DailyRewardSystem",
    "QuestSystem",
    "BattleSystem",
    "AchievementSystem",
    "ClanSystem",
    "MarketSystem",
    "RebirthSystem"
}

-- Safe module loader
local function safeRequire(module)
    local success, result = pcall(require, module)
    if success then
        return result
    else
        warn("[BOOTSTRAP] Failed to load module:", module.Name, result)
        return nil
    end
end

-- Load modules
for _, moduleName in ipairs(moduleLoadOrder) do
    local module = ServerModules:FindFirstChild(moduleName) or 
                   Systems:FindFirstChild(moduleName) or
                   Services:FindFirstChild(moduleName) or
                   DataModules:FindFirstChild(moduleName)
    
    if module then
        local loadedModule = safeRequire(module)
        if loadedModule then
            loadedModules[moduleName] = loadedModule
            print("   ✅ Loaded", moduleName)
        end
    else
        warn("   ❌ Module not found:", moduleName)
    end
end

print("✅ [BOOTSTRAP] All modules loaded!")

-- ========================================
-- SYSTEM INITIALIZATION
-- ========================================
print("🔧 [BOOTSTRAP] Initializing systems...")

-- Initialize systems that need it
local systemsToInit = {
    "DataStoreModule",
    "PetSystem",
    "CaseSystem",
    "TradingSystem",
    "DailyRewardSystem",
    "QuestSystem",
    "BattleSystem",
    "AchievementSystem",
    "ClanSystem",
    "MarketSystem",
    "RebirthSystem"
}

for _, systemName in ipairs(systemsToInit) do
    local system = loadedModules[systemName]
    if system and type(system.Initialize) == "function" then
        local success, err = pcall(system.Initialize, system)
        if not success then
            warn("[BOOTSTRAP] Failed to initialize", systemName, ":", err)
        end
    end
end

print("✅ [BOOTSTRAP] All systems initialized!")

-- ========================================
-- REMOTE HANDLERS
-- ========================================
print("🔌 [BOOTSTRAP] Connecting remote handlers...")

local DataStore = loadedModules.DataStoreModule
local PetSystem = loadedModules.PetSystem
local CaseSystem = loadedModules.CaseSystem
local TradingSystem = loadedModules.TradingSystem
local MarketSystem = loadedModules.MarketSystem
local ClanSystem = loadedModules.ClanSystem
local BattleSystem = loadedModules.BattleSystem
local QuestSystem = loadedModules.QuestSystem
local DailyRewardSystem = loadedModules.DailyRewardSystem
local RebirthSystem = loadedModules.RebirthSystem

-- GetPlayerData
RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
    if DataStore then
        return DataStore:GetPlayerData(player)
    end
    return {}
end

-- Case System
if CaseSystem then
    RemoteFunctions.OpenCase.OnServerInvoke = function(player, eggId, amount)
        return CaseSystem:OpenCase(player, eggId, amount)
    end
end

-- Pet System
if PetSystem then
    RemoteFunctions.EquipPet.OnServerInvoke = function(player, petId)
        return PetSystem:EquipPet(player, petId)
    end
    
    RemoteFunctions.UnequipPet.OnServerInvoke = function(player, petId)
        return PetSystem:UnequipPet(player, petId)
    end
    
    RemoteFunctions.DeletePet.OnServerInvoke = function(player, petId)
        return PetSystem:DeletePet(player, petId)
    end
    
    RemoteFunctions.LockPet.OnServerInvoke = function(player, petId)
        return PetSystem:LockPet(player, petId)
    end
    
    RemoteFunctions.UnlockPet.OnServerInvoke = function(player, petId)
        return PetSystem:UnlockPet(player, petId)
    end
    
    RemoteFunctions.RenamePet.OnServerInvoke = function(player, petId, newName)
        return PetSystem:RenamePet(player, petId, newName)
    end
    
    RemoteFunctions.EvolvePet.OnServerInvoke = function(player, petId)
        return PetSystem:EvolvePet(player, petId)
    end
    
    RemoteFunctions.FusePets.OnServerInvoke = function(player, petIds)
        return PetSystem:FusePets(player, petIds)
    end
end

-- Trading System
if TradingSystem then
    RemoteFunctions.StartTrade.OnServerInvoke = function(player, targetPlayer)
        return TradingSystem:StartTrade(player, targetPlayer)
    end
    
    RemoteFunctions.RequestTrade.OnServerInvoke = function(player, targetPlayer)
        return TradingSystem:RequestTrade(player, targetPlayer)
    end
    
    RemoteFunctions.UpdateTrade.OnServerInvoke = function(player, tradeData)
        return TradingSystem:UpdateTrade(player, tradeData)
    end
    
    RemoteFunctions.ConfirmTrade.OnServerInvoke = function(player)
        return TradingSystem:ConfirmTrade(player)
    end
    
    RemoteFunctions.CancelTrade.OnServerInvoke = function(player)
        return TradingSystem:CancelTrade(player)
    end
end

-- Market System
if MarketSystem then
    RemoteFunctions.CreateMarketListing.OnServerInvoke = function(player, petId, price)
        return MarketSystem:CreateListing(player, petId, price)
    end
    
    RemoteFunctions.CancelMarketListing.OnServerInvoke = function(player, listingId)
        return MarketSystem:CancelListing(player, listingId)
    end
    
    RemoteFunctions.PurchaseMarketListing.OnServerInvoke = function(player, listingId)
        return MarketSystem:PurchaseListing(player, listingId)
    end
    
    RemoteFunctions.SearchMarketListings.OnServerInvoke = function(player, filters)
        return MarketSystem:SearchListings(filters)
    end
end

-- Clan System
if ClanSystem then
    RemoteFunctions.CreateClan.OnServerInvoke = function(player, clanName, clanTag)
        return ClanSystem:CreateClan(player, clanName, clanTag)
    end
    
    RemoteFunctions.JoinClan.OnServerInvoke = function(player, clanId)
        return ClanSystem:JoinClan(player, clanId)
    end
    
    RemoteFunctions.LeaveClan.OnServerInvoke = function(player)
        return ClanSystem:LeaveClan(player)
    end
    
    RemoteFunctions.InviteToClan.OnServerInvoke = function(player, targetPlayer)
        return ClanSystem:InviteToClan(player, targetPlayer)
    end
    
    RemoteFunctions.KickFromClan.OnServerInvoke = function(player, targetPlayer)
        return ClanSystem:KickFromClan(player, targetPlayer)
    end
    
    RemoteFunctions.PromoteMember.OnServerInvoke = function(player, targetPlayer)
        return ClanSystem:PromoteMember(player, targetPlayer)
    end
    
    RemoteFunctions.DonateToClan.OnServerInvoke = function(player, amount)
        return ClanSystem:DonateToClan(player, amount)
    end
end

-- Battle System
if BattleSystem then
    RemoteFunctions.StartBattle.OnServerInvoke = function(player, opponentId)
        return BattleSystem:StartBattle(player, opponentId)
    end
    
    RemoteFunctions.JoinBattleMatchmaking.OnServerInvoke = function(player)
        return BattleSystem:JoinMatchmaking(player)
    end
    
    RemoteFunctions.CancelMatchmaking.OnServerInvoke = function(player)
        return BattleSystem:CancelMatchmaking(player)
    end
    
    RemoteFunctions.SelectBattleMove.OnServerInvoke = function(player, moveId)
        return BattleSystem:SelectMove(player, moveId)
    end
    
    RemoteFunctions.ForfeitBattle.OnServerInvoke = function(player)
        return BattleSystem:ForfeitBattle(player)
    end
end

-- Quest System
if QuestSystem then
    RemoteFunctions.ClaimQuest.OnServerInvoke = function(player, questId)
        return QuestSystem:ClaimQuest(player, questId)
    end
    
    RemoteFunctions.AbandonQuest.OnServerInvoke = function(player, questId)
        return QuestSystem:AbandonQuest(player, questId)
    end
end

-- Daily Rewards
if DailyRewardSystem then
    RemoteFunctions.GetDailyRewards.OnServerInvoke = function(player)
        return DailyRewardSystem:GetRewards(player)
    end
    
    RemoteFunctions.ClaimDailyReward.OnServerInvoke = function(player, day)
        return DailyRewardSystem:ClaimReward(player, day)
    end
end

-- Rebirth System
if RebirthSystem then
    RemoteFunctions.PerformRebirth.OnServerInvoke = function(player)
        return RebirthSystem:PerformRebirth(player)
    end
    
    RemoteFunctions.GetRebirthInfo.OnServerInvoke = function(player)
        return RebirthSystem:GetRebirthInfo(player)
    end
    
    RemoteFunctions.GetRebirthShop.OnServerInvoke = function(player)
        return RebirthSystem:GetShop()
    end
    
    RemoteFunctions.PurchaseRebirthItem.OnServerInvoke = function(player, itemId)
        return RebirthSystem:PurchaseItem(player, itemId)
    end
end

-- Shop System
RemoteFunctions.GetShopData.OnServerInvoke = function(player)
    -- Return shop data
    return {
        eggs = CaseSystem and CaseSystem:GetEggData() or {},
        items = {},
        gamepasses = {}
    }
end

RemoteFunctions.PurchaseItem.OnServerInvoke = function(player, itemType, itemId)
    if itemType == "egg" and CaseSystem then
        return CaseSystem:PurchaseEgg(player, itemId)
    end
    return false
end

-- Settings
RemoteFunctions.SaveSettings.OnServerInvoke = function(player, settings)
    if DataStore then
        return DataStore:SaveSettings(player, settings)
    end
    return false
end

RemoteFunctions.LoadSettings.OnServerInvoke = function(player)
    if DataStore then
        return DataStore:LoadSettings(player)
    end
    return {}
end

print("✅ [BOOTSTRAP] All remote handlers connected!")

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================
print("👥 [BOOTSTRAP] Setting up player handlers...")

-- Player Added
Players.PlayerAdded:Connect(function(player)
    print("[BOOTSTRAP] Player joined:", player.Name)
    
    -- Load player data
    if DataStore then
        local success, data = pcall(function()
            return DataStore:LoadPlayerData(player)
        end)
        
        if success and data then
            -- Fire data loaded event
            RemoteEvents.DataLoaded:FireClient(player, data)
            
            -- Initialize player systems
            if PetSystem then PetSystem:InitializePlayer(player) end
            if TradingSystem then TradingSystem:InitializePlayer(player) end
            if ClanSystem then ClanSystem:InitializePlayer(player) end
            if BattleSystem then BattleSystem:InitializePlayer(player) end
            if QuestSystem then QuestSystem:InitializePlayer(player) end
            if DailyRewardSystem then DailyRewardSystem:InitializePlayer(player) end
        else
            warn("[BOOTSTRAP] Failed to load data for", player.Name)
        end
    end
end)

-- Player Removing
Players.PlayerRemoving:Connect(function(player)
    print("[BOOTSTRAP] Player leaving:", player.Name)
    
    -- Save player data
    if DataStore then
        pcall(function()
            DataStore:SavePlayerData(player)
        end)
    end
    
    -- Cleanup player from systems
    if PetSystem then PetSystem:CleanupPlayer(player) end
    if TradingSystem then TradingSystem:CleanupPlayer(player) end
    if ClanSystem then ClanSystem:CleanupPlayer(player) end
    if BattleSystem then BattleSystem:CleanupPlayer(player) end
    if QuestSystem then QuestSystem:CleanupPlayer(player) end
    if DailyRewardSystem then DailyRewardSystem:CleanupPlayer(player) end
end)

print("✅ [BOOTSTRAP] Player handlers ready!")

-- ========================================
-- AUTO SAVE SYSTEM
-- ========================================
print("💾 [BOOTSTRAP] Starting auto-save system...")

task.spawn(function()
    while true do
        task.wait(CONFIG.AUTO_SAVE_INTERVAL)
        
        if DataStore then
            for _, player in ipairs(Players:GetPlayers()) do
                pcall(function()
                    DataStore:SavePlayerData(player)
                end)
            end
            print("[BOOTSTRAP] Auto-saved all player data")
        end
    end
end)

print("✅ [BOOTSTRAP] Auto-save system running!")

-- ========================================
-- SERVER SHUTDOWN HANDLER
-- ========================================
game:BindToClose(function()
    print("[BOOTSTRAP] Server shutting down, saving all data...")
    
    if DataStore then
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                DataStore:SavePlayerData(player)
            end)
        end
    end
    
    task.wait(2) -- Give time for saves to complete
end)

-- ========================================
-- INITIALIZATION COMPLETE
-- ========================================
print("🎮 [BOOTSTRAP] SANRIO TYCOON MAIN INITIALIZATION")
print("===================================================")

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    print("[BOOTSTRAP] Handling existing player:", player.Name)
    Players.PlayerAdded:Fire(player)
end

print("===================================================")
print("✨ [BOOTSTRAP] SANRIO TYCOON FULLY INITIALIZED!")
print("🎮 All systems online and ready!")

-- ========================================
-- PUBLIC API
-- ========================================
_G.SanrioTycoonServer = {
    Version = "13.0.0",
    Systems = loadedModules,
    
    -- Debug functions
    Debug = {
        GivePet = function(player, petId)
            if PetSystem then
                return PetSystem:GivePet(player, petId)
            end
        end,
        
        GiveCurrency = function(player, currency, amount)
            if DataStore then
                local data = DataStore:GetPlayerData(player)
                if data and data.currencies then
                    data.currencies[currency] = (data.currencies[currency] or 0) + amount
                    RemoteEvents.CurrencyUpdated:FireClient(player, data.currencies)
                    return true
                end
            end
            return false
        end,
        
        ResetPlayer = function(player)
            if DataStore then
                return DataStore:ResetPlayerData(player)
            end
        end
    }
}

return _G.SanrioTycoonServer