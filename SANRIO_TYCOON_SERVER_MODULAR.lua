--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                    SANRIO TYCOON SHOP - MODULAR SERVER LOADER                        ║
    ║                           Version 6.0 - FULLY MODULARIZED                            ║
    ║                                                                                      ║
    ║  THIS IS THE MAIN SERVER SCRIPT - Place in ServerScriptService                      ║
    ║  All modules should be in ServerScriptService/ServerModules                         ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ========================================
-- SERVICES
-- ========================================
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ServerScriptService = game:GetService("ServerScriptService"),
    ServerStorage = game:GetService("ServerStorage"),
    MarketplaceService = game:GetService("MarketplaceService"),
    DataStoreService = game:GetService("DataStoreService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    GroupService = game:GetService("GroupService"),
    BadgeService = game:GetService("BadgeService")
}

-- ========================================
-- MODULE LOADING
-- ========================================
local ModulesFolder = script.Parent:WaitForChild("ServerModules")

local Modules = {
    Configuration = require(ModulesFolder:WaitForChild("Configuration")),
    DataStore = require(ModulesFolder:WaitForChild("DataStoreModule")),
    PetSystem = require(ModulesFolder:WaitForChild("PetSystem")),
    PetDatabase = require(ModulesFolder:WaitForChild("PetDatabase")),
    CaseSystem = require(ModulesFolder:WaitForChild("CaseSystem")),
    TradingSystem = require(ModulesFolder:WaitForChild("TradingSystem"))
}

-- Advanced modules (if they exist)
local success, result = pcall(function()
    local ModulesFolder = Services.ReplicatedStorage:FindFirstChild("Modules")
    if ModulesFolder then
        local SharedFolder = ModulesFolder:FindFirstChild("Shared")
        if SharedFolder then
            local JanitorModule = SharedFolder:FindFirstChild("Janitor")
            if JanitorModule then
                Modules.Janitor = require(JanitorModule)
            end
            
            local DeltaModule = SharedFolder:FindFirstChild("DeltaNetworking")
            if DeltaModule then
                Modules.DeltaNetworking = require(DeltaModule)
            end
        end
    end
end)

if not success then
    warn("[Server] Advanced modules not found, running without them:", result)
end

-- ========================================
-- REMOTE SETUP
-- ========================================
local function SetupRemotes()
    -- Create folders
    local RemoteFolder = Instance.new("Folder")
    RemoteFolder.Name = "RemoteEvents"
    RemoteFolder.Parent = Services.ReplicatedStorage
    
    local RemoteFunctions = Instance.new("Folder")
    RemoteFunctions.Name = "RemoteFunctions"
    RemoteFunctions.Parent = Services.ReplicatedStorage
    
    -- Create RemoteEvents
    local eventNames = {
        "DataLoaded",
        "DataUpdated",
        "CaseOpened",
        "PetUpdated",
        "PetLevelUp",
        "TradeStarted",
        "TradeUpdated",
        "TradeCompleted",
        "TradeCancelled",
        "NotificationSent",
        "CurrencyUpdated",
        "InventoryUpdated"
    }
    
    local RemoteEvents = {}
    for _, name in ipairs(eventNames) do
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = RemoteFolder
        RemoteEvents[name] = event
    end
    
    -- Create RemoteFunctions
    local functionNames = {
        "OpenCase",
        "EquipPet",
        "UnequipPet",
        "SellPet",
        "EvolvePet",
        "FusePets",
        "StartTrade",
        "AddTradeItem",
        "RemoveTradeItem",
        "SetTradeCurrency",
        "ConfirmTrade",
        "CancelTrade",
        "GetShopData",
        "GetPlayerData",
        "SaveSettings"
    }
    
    local RemoteFuncs = {}
    for _, name in ipairs(functionNames) do
        local func = Instance.new("RemoteFunction")
        func.Name = name
        func.Parent = RemoteFunctions
        RemoteFuncs[name] = func
    end
    
    -- Debug functions (Studio only)
    if Services.RunService:IsStudio() then
        local debugFunc = Instance.new("RemoteFunction")
        debugFunc.Name = "DebugGiveCurrency"
        debugFunc.Parent = RemoteFunctions
        RemoteFuncs.DebugGiveCurrency = debugFunc
    end
    
    return RemoteEvents, RemoteFuncs
end

local RemoteEvents, RemoteFunctions = SetupRemotes()

-- ========================================
-- DELTA NETWORKING SETUP
-- ========================================
local DeltaManager = nil
if Modules.DeltaNetworking then
    DeltaManager = Modules.DeltaNetworking.newServer(RemoteEvents.DataUpdated)
end

-- ========================================
-- JANITOR SETUP
-- ========================================
local MainJanitor = nil
local PlayerJanitors = {}

if Modules.Janitor then
    MainJanitor = Modules.Janitor.new()
end

-- ========================================
-- REMOTE HANDLERS
-- ========================================
local function SetupRemoteHandlers()
    -- Case Opening
    RemoteFunctions.OpenCase.OnServerInvoke = function(player, eggType, hatchCount)
        local result = Modules.CaseSystem:OpenCase(player, eggType, hatchCount)
        
        if result.success then
            -- Send case opened event
            RemoteEvents.CaseOpened:FireClient(player, result)
            
            -- Send data update
            if DeltaManager then
                DeltaManager:SendUpdate(player, Modules.DataStore.PlayerData[player.UserId])
            else
                RemoteEvents.DataLoaded:FireClient(player, Modules.DataStore.PlayerData[player.UserId])
            end
        end
        
        return result
    end
    
    -- Pet Management
    RemoteFunctions.EquipPet.OnServerInvoke = function(player, petId)
        return Modules.PetSystem:EquipPet(player, petId)
    end
    
    RemoteFunctions.UnequipPet.OnServerInvoke = function(player, petId)
        return Modules.PetSystem:UnequipPet(player, petId)
    end
    
    RemoteFunctions.SellPet.OnServerInvoke = function(player, petId)
        local success, value = Modules.PetSystem:SellPet(player, petId)
        
        if success then
            -- Update client
            if DeltaManager then
                DeltaManager:SendUpdate(player, Modules.DataStore.PlayerData[player.UserId])
            else
                RemoteEvents.DataLoaded:FireClient(player, Modules.DataStore.PlayerData[player.UserId])
            end
            
            -- Send notification
            RemoteEvents.NotificationSent:FireClient(player, {
                type = "success",
                title = "Pet Sold!",
                message = "You sold your pet for " .. value .. " coins!",
                duration = 3
            })
        end
        
        return success, value
    end
    
    RemoteFunctions.EvolvePet.OnServerInvoke = function(player, petId)
        local success, result = Modules.PetSystem:EvolvePet(player, petId)
        
        if success then
            -- Update client
            if DeltaManager then
                DeltaManager:SendUpdate(player, Modules.DataStore.PlayerData[player.UserId])
            else
                RemoteEvents.DataLoaded:FireClient(player, Modules.DataStore.PlayerData[player.UserId])
            end
            
            -- Send notification
            RemoteEvents.NotificationSent:FireClient(player, {
                type = "success",
                title = "Evolution Complete!",
                message = "Your pet evolved into " .. result.name .. "!",
                duration = 5
            })
        end
        
        return success, result
    end
    
    RemoteFunctions.FusePets.OnServerInvoke = function(player, petId1, petId2)
        local success, result = Modules.PetSystem:FusePets(player, petId1, petId2)
        
        if success then
            -- Update client
            if DeltaManager then
                DeltaManager:SendUpdate(player, Modules.DataStore.PlayerData[player.UserId])
            else
                RemoteEvents.DataLoaded:FireClient(player, Modules.DataStore.PlayerData[player.UserId])
            end
            
            -- Send notification
            RemoteEvents.NotificationSent:FireClient(player, {
                type = "success",
                title = "Fusion Complete!",
                message = "Your pets fused into a stronger version!",
                duration = 5
            })
        end
        
        return success, result
    end
    
    -- Trading
    RemoteFunctions.StartTrade.OnServerInvoke = function(player1, player2Name)
        local player2 = Services.Players:FindFirstChild(player2Name)
        if not player2 then
            return {success = false, error = "Player not found"}
        end
        
        local trade, error = Modules.TradingSystem:CreateTrade(player1, player2)
        if trade then
            RemoteEvents.TradeStarted:FireClient(player1, trade)
            RemoteEvents.TradeStarted:FireClient(player2, trade)
            return {success = true, trade = trade}
        else
            return {success = false, error = error}
        end
    end
    
    RemoteFunctions.AddTradeItem.OnServerInvoke = function(player, tradeId, itemType, itemId)
        if itemType == "pet" then
            return Modules.TradingSystem:AddPetToTrade(tradeId, player, itemId)
        end
        return false, "Invalid item type"
    end
    
    RemoteFunctions.RemoveTradeItem.OnServerInvoke = function(player, tradeId, itemType, itemId)
        if itemType == "pet" then
            return Modules.TradingSystem:RemovePetFromTrade(tradeId, player, itemId)
        end
        return false, "Invalid item type"
    end
    
    RemoteFunctions.SetTradeCurrency.OnServerInvoke = function(player, tradeId, currencyType, amount)
        return Modules.TradingSystem:SetTradeCurrency(tradeId, player, currencyType, amount)
    end
    
    RemoteFunctions.ConfirmTrade.OnServerInvoke = function(player, tradeId)
        return Modules.TradingSystem:ConfirmTrade(tradeId, player)
    end
    
    RemoteFunctions.CancelTrade.OnServerInvoke = function(player, tradeId)
        return Modules.TradingSystem:CancelTrade(tradeId, player)
    end
    
    -- Shop Data
    RemoteFunctions.GetShopData.OnServerInvoke = function(player, dataType)
        if dataType == "eggs" then
            return Modules.CaseSystem:GetShopEggs()
        elseif dataType == "gamepasses" then
            -- Return gamepass data
            local gamepasses = {}
            for id, name in pairs(Modules.Configuration.GAMEPASS_IDS) do
                table.insert(gamepasses, {
                    id = id,
                    name = name,
                    price = 0, -- MarketplaceService will handle actual price
                    description = "Unlock " .. name .. " benefits!"
                })
            end
            return gamepasses
        end
        return nil
    end
    
    -- Player Data
    RemoteFunctions.GetPlayerData.OnServerInvoke = function(player, targetPlayer)
        if targetPlayer then
            -- Getting another player's data (for profiles)
            local targetData = Modules.DataStore.PlayerData[targetPlayer.UserId]
            if targetData then
                -- Return limited data for privacy
                return {
                    username = targetData.username,
                    level = targetData.level,
                    currencies = {
                        coins = targetData.currencies.coins,
                        gems = targetData.currencies.gems
                    },
                    statistics = targetData.statistics,
                    achievements = targetData.achievements,
                    pets = targetData.petCount,
                    titles = targetData.titles
                }
            end
        else
            -- Getting own data
            return Modules.DataStore.PlayerData[player.UserId]
        end
    end
    
    RemoteFunctions.SaveSettings.OnServerInvoke = function(player, settings)
        local playerData = Modules.DataStore.PlayerData[player.UserId]
        if playerData then
            playerData.settings = settings
            Modules.DataStore:MarkPlayerDirty(player.UserId)
            return true
        end
        return false
    end
    
    -- Debug (Studio only)
    if Services.RunService:IsStudio() and RemoteFunctions.DebugGiveCurrency then
        RemoteFunctions.DebugGiveCurrency.OnServerInvoke = function(player, currencyType, amount)
            local playerData = Modules.DataStore.PlayerData[player.UserId]
            if playerData and playerData.currencies[currencyType] then
                playerData.currencies[currencyType] = playerData.currencies[currencyType] + amount
                Modules.DataStore:MarkPlayerDirty(player.UserId)
                
                -- Update client
                if DeltaManager then
                    DeltaManager:SendUpdate(player, playerData)
                else
                    RemoteEvents.DataLoaded:FireClient(player, playerData)
                end
                
                return true
            end
            return false
        end
    end
end

-- ========================================
-- PLAYER HANDLERS
-- ========================================
local function OnPlayerAdded(player)
    print("[Server] Player joined:", player.Name)
    
    -- Load player data
    local playerData = Modules.DataStore:LoadPlayerData(player)
    
    -- Check if banned
    local isBanned, banData = Modules.DataStore:IsPlayerBanned(player.UserId)
    if isBanned then
        player:Kick("You are banned. Reason: " .. (banData.reason or "No reason provided"))
        return
    end
    
    -- Check group membership
    local success, inGroup = pcall(function()
        return player:IsInGroup(Modules.Configuration.CONFIG.GROUP_ID)
    end)
    playerData.inGroup = success and inGroup or false
    
    -- Setup Delta tracking
    if DeltaManager then
        DeltaManager:TrackPlayer(player, playerData)
    end
    
    -- Create player janitor
    if Modules.Janitor then
        local janitor = Modules.Janitor.new()
        PlayerJanitors[player.UserId] = janitor
        
        -- Setup auto-save
        local lastSaveTime = tick()
        janitor:Add(Services.RunService.Heartbeat:Connect(function()
            if tick() - lastSaveTime >= 60 then
                Modules.DataStore:SavePlayerData(player)
                lastSaveTime = tick()
            end
        end))
    end
    
    -- Send initial data
    wait(1)
    if DeltaManager then
        RemoteEvents.DataUpdated:FireClient(player, {
            type = "full",
            data = playerData,
            timestamp = tick()
        })
    else
        RemoteEvents.DataLoaded:FireClient(player, playerData)
    end
    
    -- Welcome notification
    wait(2)
    RemoteEvents.NotificationSent:FireClient(player, {
        type = "welcome",
        title = "Welcome to Sanrio Tycoon Shop!",
        message = "Start your adventure by opening eggs and collecting pets!",
        duration = 5
    })
end

local function OnPlayerRemoving(player)
    print("[Server] Player leaving:", player.Name)
    
    -- Save data
    Modules.DataStore:SavePlayerData(player)
    
    -- Clean up janitor
    if PlayerJanitors[player.UserId] then
        PlayerJanitors[player.UserId]:Cleanup()
        PlayerJanitors[player.UserId] = nil
    end
    
    -- Untrack from delta
    if DeltaManager then
        DeltaManager:UntrackPlayer(player)
    end
    
    -- Clean up data
    Modules.DataStore:CleanupPlayer(player)
end

-- ========================================
-- GAMEPASS HANDLING
-- ========================================
local function OnGamepassPurchased(player, gamepassId, wasPurchased)
    if not wasPurchased then return end
    
    local playerData = Modules.DataStore.PlayerData[player.UserId]
    if not playerData then return end
    
    -- Grant gamepass
    playerData.ownedGamepasses[gamepassId] = true
    
    -- Apply benefits
    if gamepassId == Modules.Configuration.GAMEPASS_IDS.EXTRA_STORAGE then
        playerData.maxPetStorage = playerData.maxPetStorage + 100
    end
    
    -- Mark dirty
    Modules.DataStore:MarkPlayerDirty(player.UserId)
    
    -- Notify
    RemoteEvents.NotificationSent:FireClient(player, {
        type = "success",
        title = "Gamepass Purchased!",
        message = "Thank you for your purchase!",
        duration = 5
    })
end

-- ========================================
-- INITIALIZATION
-- ========================================
local function Initialize()
    print("[Server] Initializing Sanrio Tycoon Shop v6.0...")
    
    -- Setup remote handlers
    SetupRemoteHandlers()
    
    -- Start auto-save system
    Modules.DataStore:StartAutoSave()
    
    -- Connect player events
    Services.Players.PlayerAdded:Connect(OnPlayerAdded)
    Services.Players.PlayerRemoving:Connect(OnPlayerRemoving)
    
    -- Connect gamepass events
    Services.MarketplaceService.PromptGamePassPurchaseFinished:Connect(OnGamepassPurchased)
    
    -- Handle players who joined before script loaded
    for _, player in ipairs(Services.Players:GetPlayers()) do
        spawn(function()
            OnPlayerAdded(player)
        end)
    end
    
    print("[Server] Sanrio Tycoon Shop initialized successfully!")
    print("[Server] Modules loaded:", #Modules)
end

-- Start
Initialize()

-- Return for external access
return {
    Modules = Modules,
    RemoteEvents = RemoteEvents,
    RemoteFunctions = RemoteFunctions
}