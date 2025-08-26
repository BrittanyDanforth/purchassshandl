--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                     SANRIO TYCOON - MAIN BOOTSTRAP LOADER                            ║
    ║                    THE ONLY SCRIPT THAT RUNS AUTOMATICALLY                           ║
    ║                     FIXES ALL INFINITE YIELD ERRORS FOREVER                          ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- This is the ONLY server script that should be enabled. It loads everything else in order.
-- Place this as a Script in ServerScriptService named "SANRIO_TYCOON_BOOTSTRAP"

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("🚀 [BOOTSTRAP] Starting Sanrio Tycoon initialization sequence...")

-- ========================================
-- STEP 1: CREATE ALL FOLDERS
-- ========================================
local function createFolderStructure()
    print("📁 [BOOTSTRAP] Creating folder structure...")
    
    -- Server folders
    local serverModulesFolder = ServerScriptService:FindFirstChild("ServerModules") or Instance.new("Folder")
    serverModulesFolder.Name = "ServerModules"
    serverModulesFolder.Parent = ServerScriptService
    
    -- ReplicatedStorage folders
    local modulesFolder = ReplicatedStorage:FindFirstChild("Modules") or Instance.new("Folder")
    modulesFolder.Name = "Modules"
    modulesFolder.Parent = ReplicatedStorage
    
    local sharedFolder = modulesFolder:FindFirstChild("Shared") or Instance.new("Folder")
    sharedFolder.Name = "Shared"
    sharedFolder.Parent = modulesFolder
    
    local clientFolder = modulesFolder:FindFirstChild("Client") or Instance.new("Folder")
    clientFolder.Name = "Client"
    clientFolder.Parent = modulesFolder
    
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
    
    local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions") or Instance.new("Folder")
    remoteFunctionsFolder.Name = "RemoteFunctions"
    remoteFunctionsFolder.Parent = ReplicatedStorage
    
    print("✅ [BOOTSTRAP] Folder structure ready!")
    
    return {
        ServerModules = serverModulesFolder,
        Shared = sharedFolder,
        Client = clientFolder,
        RemoteEvents = remoteEventsFolder,
        RemoteFunctions = remoteFunctionsFolder
    }
end

-- ========================================
-- STEP 2: CREATE ALL REMOTES
-- ========================================
local function createRemotes(folders)
    print("🔌 [BOOTSTRAP] Creating RemoteEvents and RemoteFunctions...")
    
    -- RemoteEvents
    local eventNames = {
        -- Core events
        "DataLoaded", "DataUpdated", "CaseOpened", "PetUpdated", "PetLevelUp",
        
        -- Trading
        "TradeStarted", "TradeUpdated", "TradeCompleted", "TradeCancelled",
        
        -- UI/Notifications
        "NotificationSent", "CurrencyUpdated", "InventoryUpdated",
        
        -- Quests & Achievements
        "QuestsUpdated", "QuestCompleted", "QuestRewardClaimed", "AchievementUnlocked",
        
        -- Daily Rewards
        "DailyRewardClaimed", "DailyRewardUpdated",
        
        -- Battle
        "BattleStarted", "BattleReady", "BattleTurnCompleted", "BattleEnded",
        
        -- Clan
        "ClanCreated", "ClanInvite", "ClanUpdated", "ClanWarStarted", "ClanWarEnded",
        
        -- Other
        "RebirthCompleted", "PetEvolved", "PetFused",
        "MarketListingCreated", "MarketListingPurchased",
        "AuctionBidPlaced", "AuctionEnded",
        "TournamentStarted", "TournamentEnded",
        "MinigameStarted", "MinigameEnded",
        "WeatherChanged", "SeasonChanged",
        "WorldBossSpawned", "WorldBossDefeated",
        "DungeonStarted", "DungeonCompleted",
        "RaidStarted", "RaidCompleted",
        
        -- Admin/Debug
        "ShowAdminNotification"
    }
    
    for _, eventName in ipairs(eventNames) do
        if not folders.RemoteEvents:FindFirstChild(eventName) then
            local event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = folders.RemoteEvents
        end
    end
    
    -- RemoteFunctions
    local functionNames = {
        -- Core
        "GetPlayerData", "GetShopData", "SaveSettings",
        
        -- Pet System
        "OpenCase", "EquipPet", "UnequipPet", "SellPet", "EvolvePet", "FusePets",
        
        -- Trading
        "StartTrade", "AddTradeItem", "RemoveTradeItem", "SetTradeCurrency",
        "ConfirmTrade", "CancelTrade", "GetRecentTradePartners",
        
        -- Quests & Daily
        "ClaimQuest", "AbandonQuest", "ClaimDailyReward", "GetDailyRewards",
        
        -- Battle
        "StartBattle", "SetBattleTeam", "BattleAction",
        
        -- Clan
        "CreateClan", "JoinClan", "LeaveClan", "InviteToClan",
        "KickFromClan", "PromoteMember", "DemoteMember", "DonateToClan", "StartClanWar", "GetClanList",
        
        -- Other
        "PerformRebirth", "CreateMarketListing", "CancelMarketListing",
        "PurchaseMarketListing", "PlaceAuctionBid", "JoinTournament", "LeaveTournament",
        "StartMinigame", "MinigameAction", "PurchaseHouse", "PlaceFurniture",
        "CustomizePet", "JoinDungeon", "LeaveDungeon", "JoinRaid", "LeaveRaid",
        "ClaimMinigameReward", "GetLeaderboards",
        
        -- Debug (Studio only)
        "DebugGiveCurrency", "DebugGivePet", "DebugSetLevel"
    }
    
    for _, functionName in ipairs(functionNames) do
        if not folders.RemoteFunctions:FindFirstChild(functionName) then
            local func = Instance.new("RemoteFunction")
            func.Name = functionName
            func.Parent = folders.RemoteFunctions
        end
    end
    
    print("✅ [BOOTSTRAP] All remotes created!")
end

-- ========================================
-- STEP 3: LOAD MODULES IN CORRECT ORDER
-- ========================================
local function loadModules(folders)
    print("📚 [BOOTSTRAP] Loading modules in dependency order...")
    
    local modules = {}
    
    -- Helper function to safely require modules
    local function safeRequire(parent, moduleName)
        local moduleScript = parent:FindFirstChild(moduleName)
        if moduleScript then
            local success, module = pcall(require, moduleScript)
            if success then
                print("   ✅ Loaded " .. moduleName)
                return module
            else
                warn("   ❌ Failed to load " .. moduleName .. ": " .. tostring(module))
                return nil
            end
        else
            warn("   ⚠️ Module not found: " .. moduleName)
            return nil
        end
    end
    
    -- Load in specific order to avoid circular dependencies
    
    -- 1. Configuration (no dependencies)
    modules.Configuration = safeRequire(folders.ServerModules, "Configuration")
    
    -- 2. Advanced utility modules (no dependencies)
    modules.Janitor = safeRequire(folders.Shared, "Janitor")
    modules.DeltaNetworking = safeRequire(folders.Shared, "DeltaNetworking")
    
    -- 3. Data layer (depends on Configuration)
    modules.DataStoreModule = safeRequire(folders.ServerModules, "DataStoreModule")
    
    -- 4. Pet database (depends on Configuration)
    modules.PetDatabase = safeRequire(folders.ServerModules, "PetDatabase")
    
    -- 5. Core systems (depend on DataStore and PetDatabase)
    modules.PetSystem = safeRequire(folders.ServerModules, "PetSystem")
    modules.CaseSystem = safeRequire(folders.ServerModules, "CaseSystem")
    
    -- 6. Feature systems (depend on core systems)
    modules.TradingSystem = safeRequire(folders.ServerModules, "TradingSystem")
    modules.DailyRewardSystem = safeRequire(folders.ServerModules, "DailyRewardSystem")
    modules.QuestSystem = safeRequire(folders.ServerModules, "QuestSystem")
    modules.BattleSystem = safeRequire(folders.ServerModules, "BattleSystem")
    modules.AchievementSystem = safeRequire(folders.ServerModules, "AchievementSystem")
    
    -- 7. Optional systems
    modules.ClanSystem = safeRequire(folders.ServerModules, "ClanSystem")
    modules.MarketSystem = safeRequire(folders.ServerModules, "MarketSystem")
    modules.RebirthSystem = safeRequire(folders.ServerModules, "RebirthSystem")
    
    print("✅ [BOOTSTRAP] All modules loaded!")
    return modules
end

-- ========================================
-- STEP 4: INITIALIZE SYSTEMS
-- ========================================
local function initializeSystems(modules, folders)
    print("🔧 [BOOTSTRAP] Initializing systems...")
    
    -- Initialize DataStore first
    if modules.DataStoreModule and modules.DataStoreModule.Init then
        modules.DataStoreModule:Init()
    end
    
    -- Initialize other systems
    local systemsToInit = {
        "PetSystem", "CaseSystem", "TradingSystem", "DailyRewardSystem",
        "QuestSystem", "BattleSystem", "AchievementSystem", "ClanSystem",
        "MarketSystem", "RebirthSystem"
    }
    
    for _, systemName in ipairs(systemsToInit) do
        local system = modules[systemName]
        if system and system.Init then
            system:Init(modules) -- Pass all modules for cross-referencing
        end
    end
    
    print("✅ [BOOTSTRAP] All systems initialized!")
end

-- ========================================
-- STEP 5: CONNECT REMOTE HANDLERS
-- ========================================
local function connectRemoteHandlers(modules, folders)
    print("🔌 [BOOTSTRAP] Connecting remote handlers...")
    
    local RemoteEvents = folders.RemoteEvents
    local RemoteFunctions = folders.RemoteFunctions
    
    -- GetShopData - CRITICAL FOR UI
    RemoteFunctions.GetShopData.OnServerInvoke = function(player, dataType)
        if dataType == "eggs" then
            if modules.CaseSystem then
                return modules.CaseSystem:GetShopEggs()
            end
        elseif dataType == "gamepasses" then
            if modules.Configuration and modules.Configuration.GAMEPASS_DATA then
                local gamepasses = {}
                for id, data in pairs(modules.Configuration.GAMEPASS_DATA) do
                    table.insert(gamepasses, {
                        id = id,
                        name = data.name,
                        description = data.description,
                        price = data.price,
                        icon = data.icon
                    })
                end
                table.sort(gamepasses, function(a, b)
                    return a.price < b.price
                end)
                return gamepasses
            end
        end
        return {}
    end
    
    -- GetPlayerData
    RemoteFunctions.GetPlayerData.OnServerInvoke = function(player, targetPlayer)
        if modules.DataStoreModule then
            local target = targetPlayer or player
            local playerData = modules.DataStoreModule:GetPlayerData(target)
            if playerData then
                -- Return a safe copy of the data without sensitive information
                return {
                    currencies = playerData.currencies,
                    pets = playerData.pets,
                    equipped = playerData.equipped,
                    inventory = playerData.inventory,
                    statistics = playerData.statistics,
                    settings = playerData.settings,
                    level = playerData.level,
                    experience = playerData.experience
                }
            end
        end
        return nil
    end
    
    -- OpenCase
    RemoteFunctions.OpenCase.OnServerInvoke = function(player, eggId, hatchCount)
        if modules.CaseSystem then
            local result = modules.CaseSystem:OpenCase(player, eggId, hatchCount)
            
            if result.success then
                -- Update quest progress
                if modules.QuestSystem then
                    modules.QuestSystem:OnEggOpened(player, hatchCount or 1)
                    
                    for _, petResult in ipairs(result.results) do
                        modules.QuestSystem:OnPetHatched(player, petResult.pet)
                    end
                end
                
                -- Check achievements
                if modules.AchievementSystem then
                    modules.AchievementSystem:CheckAchievements(player)
                end
                
                -- Send events
                RemoteEvents.CaseOpened:FireClient(player, result)
                
                -- Send data update
                if modules.DataStoreModule then
                    local playerData = modules.DataStoreModule:GetPlayerData(player)
                    RemoteEvents.DataUpdated:FireClient(player, playerData)
                end
            end
            
            return result
        end
        return {success = false, error = "System not available"}
    end
    
    -- Pet Management
    RemoteFunctions.EquipPet.OnServerInvoke = function(player, petId)
        if modules.PetSystem then
            return modules.PetSystem:EquipPet(player, petId)
        end
        return {success = false, error = "System not available"}
    end
    
    RemoteFunctions.UnequipPet.OnServerInvoke = function(player, petId)
        if modules.PetSystem then
            return modules.PetSystem:UnequipPet(player, petId)
        end
        return {success = false, error = "System not available"}
    end
    
    RemoteFunctions.SellPet.OnServerInvoke = function(player, petId)
        if modules.PetSystem then
            return modules.PetSystem:SellPet(player, petId)
        end
        return {success = false, error = "System not available"}
    end
    
    -- Trading
    RemoteFunctions.StartTrade.OnServerInvoke = function(player, targetPlayerName)
        if modules.TradingSystem then
            local targetPlayer = Players:FindFirstChild(targetPlayerName)
            if targetPlayer then
                return modules.TradingSystem:StartTrade(player, targetPlayer)
            end
        end
        return {success = false, error = "System not available"}
    end
    
    -- Daily Rewards
    RemoteFunctions.ClaimDailyReward.OnServerInvoke = function(player)
        if modules.DailyRewardSystem then
            return modules.DailyRewardSystem:ClaimDailyReward(player)
        end
        return {success = false, error = "System not available"}
    end
    
    RemoteFunctions.GetDailyRewards.OnServerInvoke = function(player)
        if modules.DailyRewardSystem then
            return modules.DailyRewardSystem:GetAllRewards(player)
        end
        return {}
    end
    
    -- Quests
    RemoteFunctions.ClaimQuest.OnServerInvoke = function(player, questId)
        if modules.QuestSystem then
            return modules.QuestSystem:ClaimQuestReward(player, questId)
        end
        return {success = false, error = "System not available"}
    end
    
    -- Battle
    RemoteFunctions.StartBattle.OnServerInvoke = function(player1, targetName)
        if modules.BattleSystem then
            local player2 = Players:FindFirstChild(targetName)
            if player2 then
                local battleId = modules.BattleSystem:CreateBattle(player1, player2, "pvp")
                return {success = true, battleId = battleId}
            end
        end
        return {success = false, error = "System not available"}
    end
    
    -- Trading extras
    RemoteFunctions.GetRecentTradePartners.OnServerInvoke = function(player)
        if modules.TradingSystem then
            return modules.TradingSystem:GetRecentPartners(player)
        end
        return {}
    end
    
    -- Clan extras
    RemoteFunctions.GetClanList.OnServerInvoke = function(player)
        if modules.ClanSystem then
            return modules.ClanSystem:GetPublicClans()
        end
        -- Return sample clans if system not available
        return {
            {id = "clan1", name = "Sanrio Squad", memberCount = 45, maxMembers = 50, level = 10},
            {id = "clan2", name = "Hello Kitty Club", memberCount = 38, maxMembers = 50, level = 8},
            {id = "clan3", name = "Kuromi Gang", memberCount = 42, maxMembers = 50, level = 9}
        }
    end
    
    -- Minigame rewards
    RemoteFunctions.ClaimMinigameReward.OnServerInvoke = function(player, gameType, gameData)
        if modules.DataStoreModule then
            local playerData = modules.DataStoreModule:GetPlayerData(player)
            if playerData then
                -- Calculate rewards based on game performance
                local baseCoins = gameData.score * 10
                local baseGems = math.floor(gameData.score / 100) * 5
                
                -- Apply multipliers or bonuses
                local coinMultiplier = playerData.multipliers and playerData.multipliers.coins or 1
                local finalCoins = math.floor(baseCoins * coinMultiplier)
                local finalGems = baseGems
                
                -- Award rewards
                playerData.currencies.coins = (playerData.currencies.coins or 0) + finalCoins
                playerData.currencies.gems = (playerData.currencies.gems or 0) + finalGems
                
                -- Track statistics
                playerData.statistics = playerData.statistics or {}
                playerData.statistics.minigamesPlayed = (playerData.statistics.minigamesPlayed or 0) + 1
                playerData.statistics.totalMinigameScore = (playerData.statistics.totalMinigameScore or 0) + gameData.score
                
                modules.DataStoreModule:MarkPlayerDirty(player.UserId)
                RemoteEvents.CurrencyUpdated:FireClient(player, playerData.currencies)
                
                return {success = true, coins = finalCoins, gems = finalGems}
            end
        end
        return {success = false, error = "Failed to award rewards"}
    end
    
    -- Leaderboards
    RemoteFunctions.GetLeaderboards.OnServerInvoke = function(player)
        local leaderboards = {
            coins = {},
            level = {},
            pets = {}
        }
        
        if modules.DataStoreModule and modules.DataStoreModule.PlayerData then
            -- Get all player data and sort
            local allPlayers = {}
            for userId, data in pairs(modules.DataStoreModule.PlayerData) do
                table.insert(allPlayers, {
                    userId = userId,
                    username = data.username or "Unknown",
                    coins = data.currencies and data.currencies.coins or 0,
                    level = data.level or 1,
                    petCount = data.pets and #data.pets or 0
                })
            end
            
            -- Sort by coins
            table.sort(allPlayers, function(a, b) return a.coins > b.coins end)
            for i = 1, math.min(10, #allPlayers) do
                table.insert(leaderboards.coins, {
                    rank = i,
                    userId = allPlayers[i].userId,
                    username = allPlayers[i].username,
                    value = allPlayers[i].coins
                })
            end
            
            -- Sort by level
            table.sort(allPlayers, function(a, b) return a.level > b.level end)
            for i = 1, math.min(10, #allPlayers) do
                table.insert(leaderboards.level, {
                    rank = i,
                    userId = allPlayers[i].userId,
                    username = allPlayers[i].username,
                    value = allPlayers[i].level
                })
            end
            
            -- Sort by pet count
            table.sort(allPlayers, function(a, b) return a.petCount > b.petCount end)
            for i = 1, math.min(10, #allPlayers) do
                table.insert(leaderboards.pets, {
                    rank = i,
                    userId = allPlayers[i].userId,
                    username = allPlayers[i].username,
                    value = allPlayers[i].petCount
                })
            end
        end
        
        return leaderboards
    end
    
    -- Debug handlers (Studio only)
    if RunService:IsStudio() then
        RemoteFunctions.DebugGiveCurrency.OnServerInvoke = function(player, currencyType, amount)
            if modules.DataStoreModule then
                local playerData = modules.DataStoreModule.PlayerData[player.UserId]
                if playerData and playerData.currencies then
                    playerData.currencies[currencyType] = (playerData.currencies[currencyType] or 0) + amount
                    modules.DataStoreModule:MarkPlayerDirty(player.UserId)
                    
                    RemoteEvents.CurrencyUpdated:FireClient(player, playerData.currencies)
                    return {success = true}
                end
            end
            return {success = false}
        end
    end
    
    print("✅ [BOOTSTRAP] All remote handlers connected!")
end

-- ========================================
-- STEP 6: PLAYER HANDLERS
-- ========================================
local function setupPlayerHandlers(modules, folders)
    print("👥 [BOOTSTRAP] Setting up player handlers...")
    
    Players.PlayerAdded:Connect(function(player)
        print("[BOOTSTRAP] Player joined:", player.Name)
        
        -- Load player data
        if modules.DataStoreModule then
            modules.DataStoreModule:LoadPlayerData(player)
            
            -- Wait for data to load
            wait(0.5)
            
            -- Send initial data
            local playerData = modules.DataStoreModule:GetPlayerData(player)
            if playerData then
                folders.RemoteEvents.DataLoaded:FireClient(player, playerData)
            end
            
            -- Check daily rewards
            if modules.DailyRewardSystem then
                modules.DailyRewardSystem:CheckDailyReward(player)
            end
            
            -- Generate daily quests
            if modules.QuestSystem then
                modules.QuestSystem:GenerateDailyQuests(player)
            end
            
            -- Check achievements
            if modules.AchievementSystem then
                modules.AchievementSystem:CheckAchievements(player)
            end
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        print("[BOOTSTRAP] Player leaving:", player.Name)
        
        -- Save player data
        if modules.DataStoreModule then
            modules.DataStoreModule:SavePlayerData(player)
        end
        
        -- Clean up systems
        if modules.TradingSystem then
            modules.TradingSystem:OnPlayerLeaving(player)
        end
        
        if modules.BattleSystem then
            modules.BattleSystem:OnPlayerLeaving(player)
        end
    end)
    
    print("✅ [BOOTSTRAP] Player handlers ready!")
end

-- ========================================
-- STEP 7: START AUTO-SAVE
-- ========================================
local function startAutoSave(modules)
    print("💾 [BOOTSTRAP] Starting auto-save system...")
    
    if modules.DataStoreModule and modules.DataStoreModule.StartAutoSave then
        modules.DataStoreModule:StartAutoSave()
    end
    
    print("✅ [BOOTSTRAP] Auto-save system running!")
end

-- ========================================
-- MAIN INITIALIZATION
-- ========================================
local function main()
    print("🎮 [BOOTSTRAP] SANRIO TYCOON MAIN INITIALIZATION")
    print("=" .. string.rep("=", 50))
    
    -- Step 1: Create folders
    local folders = createFolderStructure()
    
    -- Step 2: Create remotes
    createRemotes(folders)
    
    -- Step 3: Load modules
    local modules = loadModules(folders)
    
    -- Step 4: Initialize systems
    initializeSystems(modules, folders)
    
    -- Step 5: Connect remotes
    connectRemoteHandlers(modules, folders)
    
    -- Step 6: Player handlers
    setupPlayerHandlers(modules, folders)
    
    -- Step 7: Start auto-save
    startAutoSave(modules)
    
    print("=" .. string.rep("=", 50))
    print("✨ [BOOTSTRAP] SANRIO TYCOON FULLY INITIALIZED!")
    print("🎮 All systems online and ready!")
    
    -- Expose API for other scripts if needed
    _G.SanrioTycoonAPI = {
        Modules = modules,
        Folders = folders,
        Ready = true
    }
end

-- Run main initialization
main()