--[[
    SANRIO TYCOON SERVER - COMPLETE FIXED VERSION
    Place this in ServerScriptService as "SanrioTycoonServer"
    
    Features:
    - Complete initialization sequence
    - All game systems integrated
    - Proper error handling
    - Auto-save functionality
    - Remote event/function setup
    - Player data management
]]

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ServerScriptService = game:GetService("ServerScriptService"),
    DataStoreService = game:GetService("DataStoreService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    TweenService = game:GetService("TweenService"),
    Debris = game:GetService("Debris"),
}

print("🚀 [BOOTSTRAP] Starting Sanrio Tycoon initialization sequence...")

-- ========================================
-- FOLDER STRUCTURE SETUP
-- ========================================

local function CreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

print("📁 [BOOTSTRAP] Creating folder structure...")

-- ReplicatedStorage structure
local SanrioFolder = CreateFolder(Services.ReplicatedStorage, "SanrioTycoon")
local RemotesFolder = CreateFolder(SanrioFolder, "Remotes")
local RemoteEventsFolder = CreateFolder(RemotesFolder, "Events")
local RemoteFunctionsFolder = CreateFolder(RemotesFolder, "Functions")
local SharedModulesFolder = CreateFolder(SanrioFolder, "SharedModules")
local AssetsFolder = CreateFolder(SanrioFolder, "Assets")

-- ServerScriptService structure  
local ServerModulesFolder = Services.ServerScriptService:FindFirstChild("ServerModules") or CreateFolder(Services.ServerScriptService, "ServerModules")

print("✅ [BOOTSTRAP] Folder structure ready!")

-- ========================================
-- REMOTE EVENTS AND FUNCTIONS
-- ========================================

print("🔌 [BOOTSTRAP] Creating RemoteEvents and RemoteFunctions...")

-- Create RemoteEvents
local remoteEventNames = {
    -- Core Events
    "DataLoaded", "DataUpdated", "CurrencyUpdated",
    
    -- Pet Events
    "PetUpdated", "PetEquipped", "PetUnequipped", "PetDeleted", 
    "PetEvolved", "PetFused", "PetLevelUp",
    
    -- Case Events
    "CaseOpened", "InventoryUpdated",
    
    -- Trading Events
    "TradeRequest", "TradeStarted", "TradeUpdated", "TradeCompleted", "TradeCancelled",
    
    -- Battle Events
    "BattleStarted", "BattleReady", "BattleTurnCompleted", "BattleEnded",
    "MatchmakingFound",
    
    -- Quest Events
    "QuestsUpdated", "QuestCompleted", "QuestRewardClaimed",
    
    -- Daily Reward Events
    "DailyRewardUpdated", "DailyRewardAvailable", "DailyRewardClaimed",
    
    -- Achievement Events
    "AchievementUnlocked",
    
    -- Clan Events
    "ClanCreated", "ClanUpdated", "ClanJoined", "ClanLeft", "ClanKicked",
    "ClanInvite", "ClanInviteReceived", "ClanMemberJoined", "ClanMemberLeft",
    "ClanMemberKicked", "ClanMemberPromoted", "ClanDisbanded", "ClanInfoUpdated",
    "ClanDonationMade", "ClanBankUpdated", "ClanLevelUp",
    "ClanWarRequest", "ClanWarStarted", "ClanWarEnded",
    
    -- Market Events
    "MarketUpdated", "MarketListingCreated", "MarketListingCancelled",
    "MarketListingPurchased", "MarketPurchaseComplete",
    
    -- Rebirth Events
    "RebirthPerformed", "RebirthCompleted", "RebirthItemPurchased", 
    "RebirthUpgradeActivated",
    
    -- Social Events
    "FriendRequest", "ChatMessage", "GlobalAnnouncement",
    
    -- Game Events
    "MinigameStarted", "MinigameEnded", "TournamentStarted", "TournamentEnded",
    "SeasonChanged", "WeatherChanged", "WorldBossSpawned", "WorldBossDefeated",
    "DungeonStarted", "DungeonCompleted", "RaidStarted", "RaidCompleted",
    "AuctionBidPlaced", "AuctionEnded",
    
    -- UI Events
    "NotificationSent", "ShowAdminNotification"
}

local RemoteEvents = {}
for _, eventName in ipairs(remoteEventNames) do
    local event = RemoteEventsFolder:FindFirstChild(eventName)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = RemoteEventsFolder
    end
    RemoteEvents[eventName] = event
end

-- Create RemoteFunctions
local remoteFunctionNames = {
    -- Data Functions
    "GetPlayerData", "SyncDataChanges",
    
    -- Shop Functions
    "GetShopData", "PurchaseItem", "PurchaseGamepass", "PurchaseCurrency",
    
    -- Pet Functions
    "EquipPet", "UnequipPet", "DeletePet", "MassDeletePets", "LockPet", "UnlockPet",
    "EvolvePet", "FusePets", "CustomizePet", "RenamePet", "SellPet",
    
    -- Case Functions
    "OpenCase",
    
    -- Trading Functions
    "RequestTrade", "StartTrade", "UpdateTrade", "AddTradeItem", "RemoveTradeItem",
    "SetTradeCurrency", "ConfirmTrade", "CancelTrade", "GetRecentTradePartners",
    
    -- Battle Functions
    "StartBattle", "JoinBattle", "JoinBattleMatchmaking", "CancelMatchmaking",
    "BattleAction", "SelectBattleMove", "ForfeitBattle", "SetBattleTeam",
    
    -- Quest Functions
    "ClaimQuest", "AbandonQuest",
    
    -- Daily Reward Functions
    "GetDailyRewards", "ClaimDailyReward",
    
    -- Clan Functions
    "CreateClan", "JoinClan", "LeaveClan", "InviteToClan", "SendClanInvite",
    "AcceptClanInvite", "KickMember", "KickFromClan", "PromoteMember", "DemoteMember",
    "DonateToClan", "GetClanList", "StartClanWar",
    
    -- Market Functions
    "CreateMarketListing", "CancelMarketListing", "PurchaseMarketListing",
    "SearchMarketListings", "GetPlayerListings", "GetRecentSales", "GetPriceHistory",
    
    -- Rebirth Functions
    "PerformRebirth", "GetRebirthInfo", "GetRebirthShop", "PurchaseRebirthItem",
    
    -- Social Functions
    "GetLeaderboards",
    
    -- Game Functions
    "StartMinigame", "MinigameAction", "ClaimMinigameReward",
    "JoinTournament", "LeaveTournament", "JoinDungeon", "LeaveDungeon",
    "JoinRaid", "LeaveRaid", "PlaceAuctionBid",
    
    -- Settings Functions
    "SaveSettings", "LoadSettings", "UpdateSettings",
    
    -- House Functions
    "PurchaseHouse", "PlaceFurniture",
    
    -- Debug Functions (Admin only)
    "DebugGivePet", "DebugGiveCurrency", "DebugSetLevel"
}

local RemoteFunctions = {}
for _, funcName in ipairs(remoteFunctionNames) do
    local func = RemoteFunctionsFolder:FindFirstChild(funcName)
    if not func then
        func = Instance.new("RemoteFunction")
        func.Name = funcName
        func.Parent = RemoteFunctionsFolder
    end
    RemoteFunctions[funcName] = func
end

print("✅ [BOOTSTRAP] All remotes created!")

-- ========================================
-- MODULE LOADING
-- ========================================

print("📚 [BOOTSTRAP] Loading modules in dependency order...")

local Modules = {}
local moduleLoadOrder = {
    -- Core modules (no dependencies)
    "Configuration",
    
    -- Infrastructure modules
    "DataStoreModule",
    
    -- Database modules
    "PetDatabase",
    
    -- System modules (dependent on database)
    "PetSystem",
    "CaseSystem",
    "TradingSystem",
    "DailyRewardSystem",
    "QuestSystem",
    "BattleSystem",
    "AchievementSystem",
    "ClanSystem",
    "MarketSystem",
    "RebirthSystem",
}

-- Load modules
for _, moduleName in ipairs(moduleLoadOrder) do
    local moduleScript = ServerModulesFolder:FindFirstChild(moduleName)
    if moduleScript then
        local success, module = pcall(require, moduleScript)
        if success then
            Modules[moduleName] = module
            print("    ✅ Loaded " .. moduleName)
        else
            warn("    ❌ Failed to load " .. moduleName .. ":", module)
        end
    else
        warn("    ❌ Module not found: " .. moduleName)
    end
end

print("✅ [BOOTSTRAP] All modules loaded!")

-- ========================================
-- SYSTEM INITIALIZATION
-- ========================================

print("🔧 [BOOTSTRAP] Initializing systems...")

-- Extract systems for easier access
local Configuration = Modules.Configuration
local DataStoreModule = Modules.DataStoreModule
local PetDatabase = Modules.PetDatabase
local PetSystem = Modules.PetSystem
local CaseSystem = Modules.CaseSystem
local TradingSystem = Modules.TradingSystem
local DailyRewardSystem = Modules.DailyRewardSystem
local QuestSystem = Modules.QuestSystem
local BattleSystem = Modules.BattleSystem
local AchievementSystem = Modules.AchievementSystem
local ClanSystem = Modules.ClanSystem
local MarketSystem = Modules.MarketSystem
local RebirthSystem = Modules.RebirthSystem

-- Initialize systems that have Initialize methods
local systemsToInitialize = {
    ClanSystem,
    MarketSystem,
    RebirthSystem,
}

for _, system in ipairs(systemsToInitialize) do
    if system and system.Initialize then
        local success, err = pcall(system.Initialize, system)
        if not success then
            warn("[BOOTSTRAP] Failed to initialize system:", err)
        end
    end
end

print("✅ [BOOTSTRAP] All systems initialized!")

-- ========================================
-- REMOTE HANDLERS
-- ========================================

print("🔌 [BOOTSTRAP] Connecting remote handlers...")

-- GetPlayerData
RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
    if DataStoreModule then
        return DataStoreModule:GetPlayerData(player)
    end
    return {
        currencies = {coins = 0, gems = 0},
        inventory = {},
        pets = {},
        equipped = {},
        settings = {}
    }
end

-- GetShopData
RemoteFunctions.GetShopData.OnServerInvoke = function(player)
    local shopData = {
        cases = {},
        gamepasses = {},
        currencies = {}
    }
    
    if CaseSystem and CaseSystem.GetCases then
        shopData.cases = CaseSystem:GetCases()
    end
    
    return shopData
end

-- OpenCase
RemoteFunctions.OpenCase.OnServerInvoke = function(player, caseId)
    if not CaseSystem then return {success = false, error = "System not available"} end
    
    local result = CaseSystem:OpenCase(player, caseId)
    if result.success then
        -- Update inventory
        if DataStoreModule then
            DataStoreModule:UpdatePlayerData(player, "inventory", function(inventory)
                table.insert(inventory, result.pet)
                return inventory
            end)
        end
        
        -- Fire events
        RemoteEvents.CaseOpened:FireClient(player, result)
        RemoteEvents.InventoryUpdated:FireClient(player)
    end
    
    return result
end

-- PurchaseItem
RemoteFunctions.PurchaseItem.OnServerInvoke = function(player, itemType, itemId)
    if itemType == "case" then
        -- Deduct currency and give case opening
        if DataStoreModule then
            local caseData = CaseSystem and CaseSystem:GetCase(itemId)
            if caseData then
                local success = DataStoreModule:UpdateCurrency(player, caseData.currency, -caseData.price)
                if success then
                    RemoteEvents.CurrencyUpdated:FireClient(player, caseData.currency, DataStoreModule:GetCurrency(player, caseData.currency))
                    return {success = true}
                else
                    return {success = false, error = "Insufficient funds"}
                end
            end
        end
    end
    
    return {success = false, error = "Invalid purchase"}
end

-- Pet Management
RemoteFunctions.EquipPet.OnServerInvoke = function(player, petId)
    if not PetSystem then return {success = false} end
    
    local result = PetSystem:EquipPet(player, petId)
    if result.success then
        RemoteEvents.PetEquipped:FireClient(player, petId)
        RemoteEvents.DataUpdated:FireClient(player, "equipped", DataStoreModule:GetPlayerData(player).equipped)
    end
    return result
end

RemoteFunctions.UnequipPet.OnServerInvoke = function(player, petId)
    if not PetSystem then return {success = false} end
    
    local result = PetSystem:UnequipPet(player, petId)
    if result.success then
        RemoteEvents.PetUnequipped:FireClient(player, petId)
        RemoteEvents.DataUpdated:FireClient(player, "equipped", DataStoreModule:GetPlayerData(player).equipped)
    end
    return result
end

RemoteFunctions.DeletePet.OnServerInvoke = function(player, petId)
    if not PetSystem then return {success = false} end
    
    local result = PetSystem:DeletePet(player, petId)
    if result.success then
        RemoteEvents.PetDeleted:FireClient(player, petId)
        RemoteEvents.InventoryUpdated:FireClient(player)
    end
    return result
end

-- Trading System
RemoteFunctions.RequestTrade.OnServerInvoke = function(player, targetPlayer)
    if not TradingSystem then return {success = false} end
    
    return TradingSystem:RequestTrade(player, targetPlayer)
end

RemoteFunctions.StartTrade.OnServerInvoke = function(player, targetPlayer)
    if not TradingSystem then return {success = false} end
    
    local result = TradingSystem:StartTrade(player, targetPlayer)
    if result.success then
        RemoteEvents.TradeStarted:FireClient(player, targetPlayer)
        RemoteEvents.TradeStarted:FireClient(targetPlayer, player)
    end
    return result
end

RemoteFunctions.UpdateTrade.OnServerInvoke = function(player, tradeData)
    if not TradingSystem then return {success = false} end
    
    local result = TradingSystem:UpdateTrade(player, tradeData)
    if result.success then
        local trade = TradingSystem:GetTrade(player)
        if trade then
            RemoteEvents.TradeUpdated:FireClient(trade.player1, trade)
            RemoteEvents.TradeUpdated:FireClient(trade.player2, trade)
        end
    end
    return result
end

RemoteFunctions.ConfirmTrade.OnServerInvoke = function(player)
    if not TradingSystem then return {success = false} end
    
    local result = TradingSystem:ConfirmTrade(player)
    if result.success and result.completed then
        RemoteEvents.TradeCompleted:FireClient(result.player1, result)
        RemoteEvents.TradeCompleted:FireClient(result.player2, result)
        RemoteEvents.InventoryUpdated:FireClient(result.player1)
        RemoteEvents.InventoryUpdated:FireClient(result.player2)
    end
    return result
end

RemoteFunctions.CancelTrade.OnServerInvoke = function(player)
    if not TradingSystem then return {success = false} end
    
    local trade = TradingSystem:GetTrade(player)
    local result = TradingSystem:CancelTrade(player)
    
    if result.success and trade then
        RemoteEvents.TradeCancelled:FireClient(trade.player1)
        RemoteEvents.TradeCancelled:FireClient(trade.player2)
    end
    return result
end

-- Battle System
RemoteFunctions.StartBattle.OnServerInvoke = function(player, opponentType, opponentData)
    if not BattleSystem then return {success = false} end
    
    local result = BattleSystem:StartBattle(player, opponentType, opponentData)
    if result.success then
        RemoteEvents.BattleStarted:FireClient(player, result.battleData)
    end
    return result
end

RemoteFunctions.BattleAction.OnServerInvoke = function(player, action, data)
    if not BattleSystem then return {success = false} end
    
    local result = BattleSystem:ProcessAction(player, action, data)
    if result.success then
        RemoteEvents.BattleTurnCompleted:FireClient(player, result)
        
        if result.battleEnded then
            RemoteEvents.BattleEnded:FireClient(player, result)
        end
    end
    return result
end

-- Quest System
RemoteFunctions.ClaimQuest.OnServerInvoke = function(player, questId)
    if not QuestSystem then return {success = false} end
    
    local result = QuestSystem:ClaimQuest(player, questId)
    if result.success then
        RemoteEvents.QuestCompleted:FireClient(player, questId, result.rewards)
        RemoteEvents.QuestsUpdated:FireClient(player, QuestSystem:GetPlayerQuests(player))
        
        -- Update currencies if rewards include them
        if result.rewards and DataStoreModule then
            for currency, amount in pairs(result.rewards.currencies or {}) do
                DataStoreModule:UpdateCurrency(player, currency, amount)
                RemoteEvents.CurrencyUpdated:FireClient(player, currency, DataStoreModule:GetCurrency(player, currency))
            end
        end
    end
    return result
end

-- Daily Rewards
RemoteFunctions.GetDailyRewards.OnServerInvoke = function(player)
    if not DailyRewardSystem then return {} end
    
    return DailyRewardSystem:GetRewardStatus(player)
end

RemoteFunctions.ClaimDailyReward.OnServerInvoke = function(player, day)
    if not DailyRewardSystem then return {success = false} end
    
    local result = DailyRewardSystem:ClaimReward(player, day)
    if result.success then
        RemoteEvents.DailyRewardClaimed:FireClient(player, day, result.rewards)
        
        -- Update currencies if rewards include them
        if result.rewards and DataStoreModule then
            for currency, amount in pairs(result.rewards.currencies or {}) do
                DataStoreModule:UpdateCurrency(player, currency, amount)
                RemoteEvents.CurrencyUpdated:FireClient(player, currency, DataStoreModule:GetCurrency(player, currency))
            end
        end
    end
    return result
end

-- Clan System
RemoteFunctions.CreateClan.OnServerInvoke = function(player, clanName, clanTag)
    if not ClanSystem then return {success = false} end
    
    local result = ClanSystem:CreateClan(player, clanName, clanTag)
    if result.success then
        RemoteEvents.ClanCreated:FireClient(player, result.clan)
    end
    return result
end

RemoteFunctions.JoinClan.OnServerInvoke = function(player, clanId)
    if not ClanSystem then return {success = false} end
    
    local result = ClanSystem:JoinClan(player, clanId)
    if result.success then
        RemoteEvents.ClanJoined:FireClient(player, result.clan)
        
        -- Notify clan members
        local clan = ClanSystem:GetClan(clanId)
        if clan then
            for _, memberId in ipairs(clan.members) do
                local member = Services.Players:GetPlayerByUserId(memberId)
                if member and member ~= player then
                    RemoteEvents.ClanMemberJoined:FireClient(member, player.UserId)
                end
            end
        end
    end
    return result
end

RemoteFunctions.LeaveClan.OnServerInvoke = function(player)
    if not ClanSystem then return {success = false} end
    
    local clanId = ClanSystem:GetPlayerClan(player)
    local result = ClanSystem:LeaveClan(player)
    
    if result.success and clanId then
        RemoteEvents.ClanLeft:FireClient(player)
        
        -- Notify clan members
        local clan = ClanSystem:GetClan(clanId)
        if clan then
            for _, memberId in ipairs(clan.members) do
                local member = Services.Players:GetPlayerByUserId(memberId)
                if member then
                    RemoteEvents.ClanMemberLeft:FireClient(member, player.UserId)
                end
            end
        end
    end
    return result
end

-- Market System
RemoteFunctions.CreateMarketListing.OnServerInvoke = function(player, petId, price)
    if not MarketSystem then return {success = false} end
    
    local result = MarketSystem:CreateListing(player, petId, price)
    if result.success then
        RemoteEvents.MarketListingCreated:FireClient(player, result.listing)
        RemoteEvents.InventoryUpdated:FireClient(player)
    end
    return result
end

RemoteFunctions.PurchaseMarketListing.OnServerInvoke = function(player, listingId)
    if not MarketSystem then return {success = false} end
    
    local result = MarketSystem:PurchaseListing(player, listingId)
    if result.success then
        RemoteEvents.MarketPurchaseComplete:FireClient(player, result)
        RemoteEvents.InventoryUpdated:FireClient(player)
        
        -- Update currency
        if DataStoreModule then
            RemoteEvents.CurrencyUpdated:FireClient(player, "coins", DataStoreModule:GetCurrency(player, "coins"))
        end
        
        -- Notify seller
        local sellerPlayer = Services.Players:GetPlayerByUserId(result.sellerId)
        if sellerPlayer then
            RemoteEvents.MarketListingPurchased:FireClient(sellerPlayer, result)
            RemoteEvents.CurrencyUpdated:FireClient(sellerPlayer, "coins", DataStoreModule:GetCurrency(sellerPlayer, "coins"))
        end
    end
    return result
end

-- Rebirth System
RemoteFunctions.PerformRebirth.OnServerInvoke = function(player)
    if not RebirthSystem then return {success = false} end
    
    local result = RebirthSystem:PerformRebirth(player)
    if result.success then
        RemoteEvents.RebirthCompleted:FireClient(player, result.newRebirth)
        
        -- Update all currencies
        if DataStoreModule then
            local playerData = DataStoreModule:GetPlayerData(player)
            for currency, amount in pairs(playerData.currencies) do
                RemoteEvents.CurrencyUpdated:FireClient(player, currency, amount)
            end
        end
        
        RemoteEvents.DataUpdated:FireClient(player, "rebirth", result.newRebirth)
    end
    return result
end

RemoteFunctions.GetRebirthInfo.OnServerInvoke = function(player)
    if not RebirthSystem then return {} end
    
    return RebirthSystem:GetRebirthInfo(player)
end

-- Settings
RemoteFunctions.SaveSettings.OnServerInvoke = function(player, settings)
    if DataStoreModule then
        DataStoreModule:UpdatePlayerData(player, "settings", function()
            return settings
        end)
        return {success = true}
    end
    return {success = false}
end

RemoteFunctions.LoadSettings.OnServerInvoke = function(player)
    if DataStoreModule then
        local data = DataStoreModule:GetPlayerData(player)
        return data.settings or {}
    end
    return {}
end

-- Debug Commands (Admin Only)
local ADMIN_IDS = Configuration and Configuration.ADMIN_IDS or {1} -- Add admin user IDs

RemoteFunctions.DebugGivePet.OnServerInvoke = function(player, petId, amount)
    if not table.find(ADMIN_IDS, player.UserId) then 
        return {success = false, error = "Unauthorized"} 
    end
    
    amount = amount or 1
    for i = 1, amount do
        if DataStoreModule then
            DataStoreModule:UpdatePlayerData(player, "inventory", function(inventory)
                local pet = {
                    id = HttpService:GenerateGUID(false),
                    petId = petId,
                    level = 1,
                    experience = 0,
                    locked = false
                }
                table.insert(inventory, pet)
                return inventory
            end)
        end
    end
    
    RemoteEvents.InventoryUpdated:FireClient(player)
    return {success = true}
end

RemoteFunctions.DebugGiveCurrency.OnServerInvoke = function(player, currency, amount)
    if not table.find(ADMIN_IDS, player.UserId) then 
        return {success = false, error = "Unauthorized"} 
    end
    
    if DataStoreModule then
        DataStoreModule:UpdateCurrency(player, currency, amount)
        RemoteEvents.CurrencyUpdated:FireClient(player, currency, DataStoreModule:GetCurrency(player, currency))
        return {success = true}
    end
    return {success = false}
end

print("✅ [BOOTSTRAP] All remote handlers connected!")

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================

print("👥 [BOOTSTRAP] Setting up player handlers...")

-- Player joined
Services.Players.PlayerAdded:Connect(function(player)
    print("[BOOTSTRAP] Player joined:", player.Name)
    
    -- Load player data
    if DataStoreModule then
        local success, data = pcall(function()
            return DataStoreModule:LoadPlayerData(player)
        end)
        
        if success and data then
            -- Fire data loaded event
            RemoteEvents.DataLoaded:FireClient(player, data)
            
            -- Initialize player in systems (only if they have the method)
            local systems = {
                {system = PetSystem, name = "PetSystem"},
                {system = TradingSystem, name = "TradingSystem"},
                {system = ClanSystem, name = "ClanSystem"},
                {system = BattleSystem, name = "BattleSystem"},
                {system = QuestSystem, name = "QuestSystem"},
                {system = DailyRewardSystem, name = "DailyRewardSystem"},
            }
            
            for _, systemInfo in ipairs(systems) do
                if systemInfo.system and type(systemInfo.system.InitializePlayer) == "function" then
                    local initSuccess, initErr = pcall(systemInfo.system.InitializePlayer, systemInfo.system, player)
                    if not initSuccess then
                        warn("[BOOTSTRAP] Failed to initialize player in " .. systemInfo.name .. ":", initErr)
                    end
                elseif systemInfo.system and type(systemInfo.system.OnPlayerAdded) == "function" then
                    -- Try alternative method name
                    local initSuccess, initErr = pcall(systemInfo.system.OnPlayerAdded, systemInfo.system, player)
                    if not initSuccess then
                        warn("[BOOTSTRAP] Failed to handle player added in " .. systemInfo.name .. ":", initErr)
                    end
                end
            end
        else
            warn("[BOOTSTRAP] Failed to load data for", player.Name)
        end
    end
end)

-- Player leaving
Services.Players.PlayerRemoving:Connect(function(player)
    print("[BOOTSTRAP] Player leaving:", player.Name)
    
    -- Save player data
    if DataStoreModule then
        pcall(function()
            DataStoreModule:SavePlayerData(player)
        end)
    end
    
    -- Clean up player from systems
    local systems = {
        {system = TradingSystem, name = "TradingSystem"},
        {system = BattleSystem, name = "BattleSystem"},
        {system = ClanSystem, name = "ClanSystem"},
    }
    
    for _, systemInfo in ipairs(systems) do
        if systemInfo.system then
            if type(systemInfo.system.CleanupPlayer) == "function" then
                pcall(systemInfo.system.CleanupPlayer, systemInfo.system, player)
            elseif type(systemInfo.system.OnPlayerRemoving) == "function" then
                pcall(systemInfo.system.OnPlayerRemoving, systemInfo.system, player)
            end
        end
    end
end)

-- Handle players already in game
for _, player in ipairs(Services.Players:GetPlayers()) do
    spawn(function()
        Services.Players.PlayerAdded:Fire(player)
    end)
end

print("✅ [BOOTSTRAP] Player handlers ready!")

-- ========================================
-- AUTO-SAVE SYSTEM
-- ========================================

print("💾 [BOOTSTRAP] Starting auto-save system...")

spawn(function()
    while true do
        wait(Configuration and Configuration.AUTO_SAVE_INTERVAL or 300) -- 5 minutes default
        
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if DataStoreModule then
                pcall(function()
                    DataStoreModule:SavePlayerData(player)
                end)
            end
        end
        
        print("[BOOTSTRAP] Auto-save completed for", #Services.Players:GetPlayers(), "players")
    end
end)

print("✅ [BOOTSTRAP] Auto-save system running!")

-- ========================================
-- GAME SHUTDOWN HANDLER
-- ========================================

game:BindToClose(function()
    print("[BOOTSTRAP] Game shutting down, saving all player data...")
    
    local players = Services.Players:GetPlayers()
    local savePromises = {}
    
    for _, player in ipairs(players) do
        if DataStoreModule then
            table.insert(savePromises, function()
                pcall(function()
                    DataStoreModule:SavePlayerData(player)
                end)
            end)
        end
    end
    
    -- Execute all saves
    for _, save in ipairs(savePromises) do
        save()
    end
    
    print("[BOOTSTRAP] Shutdown save complete")
    wait(2) -- Give time for saves to complete
end)

-- ========================================
-- INITIALIZATION COMPLETE
-- ========================================

print("🎮 [BOOTSTRAP] SANRIO TYCOON MAIN INITIALIZATION")
print("===================================================")

-- Expose API for other scripts
_G.SanrioTycoonServer = {
    Services = Services,
    Modules = Modules,
    RemoteEvents = RemoteEvents,
    RemoteFunctions = RemoteFunctions,
    
    -- Utility functions
    GetPlayerData = function(player)
        return DataStoreModule and DataStoreModule:GetPlayerData(player) or nil
    end,
    
    UpdateCurrency = function(player, currency, amount)
        if DataStoreModule then
            return DataStoreModule:UpdateCurrency(player, currency, amount)
        end
        return false
    end,
}

print("===================================================")
print("✨ [BOOTSTRAP] SANRIO TYCOON FULLY INITIALIZED!")
print("🎮 All systems online and ready!")

return _G.SanrioTycoonServer