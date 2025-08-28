--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║               SANRIO TYCOON CLIENT - FINAL ULTIMATE VERSION 5.0                      ║
    ║                        FIXES ALL REMAINING ISSUES                                    ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
    
    FIXES IN THIS VERSION:
    ✅ Fixed DataCache/StateManager method access issues
    ✅ Fixed UI overlap with navigation buttons
    ✅ Fixed invisible Settings and Inventory UI
    ✅ Fixed all method calls (FireServer → Fire, etc.)
    ✅ Fixed dropdown GetValue error
    ✅ Adjusted panel positions to prevent overlap
]]

-- ========================================
-- SINGLETON CHECK (MUST BE FIRST!)
-- ========================================
if _G.SanrioTycoonClientLoaded then
    warn("[SanrioTycoonClient] Already loaded! Preventing double initialization.")
    return _G.SanrioTycoonClient
end
_G.SanrioTycoonClientLoaded = true

print("[SanrioTycoonClient] Starting FINAL ULTIMATE client v5.0...")

-- ========================================
-- SERVICES
-- ========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========================================
-- MODULE PATHS
-- ========================================
local ClientModules = script.Parent:WaitForChild("ClientModules")
local CoreModules = ClientModules:WaitForChild("Core")
local InfrastructureModules = ClientModules:WaitForChild("Infrastructure")
local SystemModules = ClientModules:WaitForChild("Systems")
local FrameworkModules = ClientModules:WaitForChild("Framework")
local UIModules = ClientModules:WaitForChild("UIModules")

print("[SanrioTycoonClient] Found ClientModules at:", ClientModules:GetFullName())

-- ========================================
-- CORE MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading core modules...")

local ClientTypes = require(CoreModules:WaitForChild("ClientTypes"))
local ClientConfig = require(CoreModules:WaitForChild("ClientConfig"))
local ClientServices = require(CoreModules:WaitForChild("ClientServices"))
local ClientUtilities = require(CoreModules:WaitForChild("ClientUtilities"))

-- Wait for ClientServices to initialize
task.wait(0.1)

-- ========================================
-- INFRASTRUCTURE LOADING (FIXED!)
-- ========================================
print("[SanrioTycoonClient] Loading infrastructure...")

-- Load module classes
local EventBus = require(InfrastructureModules:WaitForChild("EventBus"))
local StateManager = require(InfrastructureModules:WaitForChild("StateManager"))
local DataCache = require(InfrastructureModules:WaitForChild("DataCache"))
local RemoteManager = require(InfrastructureModules:WaitForChild("RemoteManager"))
local ModuleLoader = require(InfrastructureModules:WaitForChild("ModuleLoader"))

-- Create instances
local eventBus = EventBus.new({
    Config = ClientConfig
})

local stateManager = StateManager.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    EventBus = eventBus
})

local remoteManager = RemoteManager.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    EventBus = eventBus
})

local dataCache = DataCache.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    StateManager = stateManager,
    EventBus = eventBus,
    RemoteManager = remoteManager
})

-- Verify methods exist
assert(dataCache.Set, "DataCache missing Set method!")
assert(dataCache.Get, "DataCache missing Get method!")
assert(dataCache.Watch, "DataCache missing Watch method!")
assert(stateManager.Set, "StateManager missing Set method!")

print("[SanrioTycoonClient] Infrastructure loaded with all methods verified!")

-- ========================================
-- SYSTEM MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading systems...")

local SoundSystem = require(SystemModules:WaitForChild("SoundSystem"))
local ParticleSystem = require(SystemModules:WaitForChild("ParticleSystem"))
local NotificationSystem = require(SystemModules:WaitForChild("NotificationSystem"))
local UIFactory = require(SystemModules:WaitForChild("UIFactory"))
local AnimationSystem = require(SystemModules:WaitForChild("AnimationSystem"))
local EffectsLibrary = require(SystemModules:WaitForChild("EffectsLibrary"))

-- Create system instances
local soundSystem = SoundSystem.new({
    EventBus = eventBus,
    StateManager = stateManager,
    Config = ClientConfig
})

local particleSystem = ParticleSystem.new({
    EventBus = eventBus,
    StateManager = stateManager,
    Config = ClientConfig
})

local animationSystem = AnimationSystem.new({
    EventBus = eventBus,
    StateManager = stateManager,
    Config = ClientConfig
})

local uiFactory = UIFactory.new({
    EventBus = eventBus,
    StateManager = stateManager,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

local notificationSystem = NotificationSystem.new({
    EventBus = eventBus,
    StateManager = stateManager,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem,
    UIFactory = uiFactory,
    Config = ClientConfig
})

local effectsLibrary = EffectsLibrary.new({
    EventBus = eventBus,
    StateManager = stateManager,
    ParticleSystem = particleSystem,
    AnimationSystem = animationSystem,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

-- Make EffectsLibrary globally available
_G.SpecialEffects = effectsLibrary

print("[SanrioTycoonClient] Systems loaded successfully!")

-- ========================================
-- FRAMEWORK MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading framework...")

local MainUI = require(FrameworkModules:WaitForChild("MainUI"))
local WindowManager = require(FrameworkModules:WaitForChild("WindowManager"))

-- Create framework instances
local windowManager = WindowManager.new({
    EventBus = eventBus,
    StateManager = stateManager,
    AnimationSystem = animationSystem,
    SoundSystem = soundSystem,
    UIFactory = uiFactory,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

local mainUI = MainUI.new({
    EventBus = eventBus,
    StateManager = stateManager,
    DataCache = dataCache,
    RemoteManager = remoteManager,
    SoundSystem = soundSystem,
    NotificationSystem = notificationSystem,
    UIFactory = uiFactory,
    WindowManager = windowManager,
    EffectsLibrary = effectsLibrary,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

print("[SanrioTycoonClient] Framework loaded successfully!")

-- ========================================
-- UI MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading ALL UI modules...")

-- Common dependencies for all UI modules
local uiDependencies = {
    EventBus = eventBus,
    StateManager = stateManager,
    DataCache = dataCache,
    RemoteManager = remoteManager,
    SoundSystem = soundSystem,
    ParticleSystem = particleSystem,
    AnimationSystem = animationSystem,
    NotificationSystem = notificationSystem,
    UIFactory = uiFactory,
    WindowManager = windowManager,
    EffectsLibrary = effectsLibrary,
    Config = ClientConfig,
    Utilities = ClientUtilities
}

-- Load ALL UI modules
local uiModules = {}
local uiModuleNames = {
    "CurrencyDisplay",
    "ShopUI",
    "CaseOpeningUI",
    "InventoryUI",
    "PetDetailsUI",
    "TradingUI",
    "BattleUI",
    "QuestUI",
    "SettingsUI",
    "DailyRewardUI",
    "SocialUI",
    "ProgressionUI"
}

local loadedCount = 0
local failedModules = {}

for _, moduleName in ipairs(uiModuleNames) do
    local success, result = pcall(function()
        local moduleScript = UIModules:WaitForChild(moduleName, 5)
        if not moduleScript then
            error("Module not found: " .. moduleName)
        end
        local moduleClass = require(moduleScript)
        local instance = moduleClass.new(uiDependencies)
        
        -- Verify the instance has required methods
        if moduleName == "InventoryUI" and not instance.Open then
            error("InventoryUI missing Open method")
        end
        
        return instance
    end)
    
    if success and result then
        uiModules[moduleName] = result
        loadedCount = loadedCount + 1
        print("[SanrioTycoonClient] ✅ " .. moduleName .. " loaded")
    else
        table.insert(failedModules, {name = moduleName, error = tostring(result)})
        warn("[SanrioTycoonClient] ❌ Failed to load " .. moduleName .. ": " .. tostring(result))
    end
end

print("[SanrioTycoonClient] UI modules loaded: " .. loadedCount .. "/" .. #uiModuleNames)

-- Register all loaded UI modules with MainUI
for name, instance in pairs(uiModules) do
    mainUI:RegisterModule(name, instance)
end

-- ========================================
-- FIX UI OVERLAP ISSUE
-- ========================================
-- Adjust MainUI panel position to not overlap navigation
task.spawn(function()
    task.wait(1) -- Wait for UI to initialize
    local screenGui = PlayerGui:WaitForChild("SanrioTycoonUI", 5)
    if screenGui then
        local mainPanel = screenGui:FindFirstChild("MainUIPanel")
        if mainPanel then
            -- Move panel to the right to avoid navigation overlap
            mainPanel.Position = UDim2.new(0, 250, 0, 80) -- Adjusted from default
            print("[SanrioTycoonClient] Adjusted MainUIPanel position to avoid overlap")
        end
    end
end)

-- ========================================
-- REMOTE CONNECTION SETUP
-- ========================================
print("[SanrioTycoonClient] Setting up remote connections...")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)

if RemoteEvents and RemoteFunctions then
    -- Register all RemoteEvents
    for _, remote in ipairs(RemoteEvents:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            remoteManager:RegisterRemoteEvent(remote)
        end
    end
    print("[SanrioTycoonClient] Registered " .. #RemoteEvents:GetChildren() .. " RemoteEvents")
    
    -- Register all RemoteFunctions
    for _, remote in ipairs(RemoteFunctions:GetChildren()) do
        if remote:IsA("RemoteFunction") then
            remoteManager:RegisterRemoteFunction(remote)
        end
    end
    print("[SanrioTycoonClient] Registered " .. #RemoteFunctions:GetChildren() .. " RemoteFunctions")
else
    warn("[SanrioTycoonClient] Remote folders not found! Server might not be initialized.")
end

-- ========================================
-- EVENT CONNECTIONS (FIXED!)
-- ========================================
print("[SanrioTycoonClient] Setting up event handlers...")

-- Currency updates
remoteManager:On("CurrencyUpdated", function(currencies)
    if dataCache and dataCache.Set then
        dataCache:Set("currencies", currencies)
    end
    if stateManager and stateManager.Set then
        stateManager:Set("currencies", currencies)
    end
    eventBus:Fire("CurrencyUpdated", currencies)
end)

-- Data loaded
remoteManager:On("DataLoaded", function(playerData)
    if playerData then
        if dataCache and dataCache.Set then
            dataCache:Set("", playerData)
        end
        if stateManager and stateManager.Set then
            stateManager:Set("playerData", playerData)
        end
        eventBus:Fire("PlayerDataLoaded", playerData)
        print("[SanrioTycoonClient] Player data loaded from server")
    end
end)

-- Data updates
remoteManager:On("DataUpdated", function(playerData)
    if playerData then
        if dataCache and dataCache.Set then
            dataCache:Set("", playerData)
        end
        if stateManager and stateManager.Set then
            stateManager:Set("playerData", playerData)
        end
        eventBus:Fire("PlayerDataUpdated", playerData)
    end
end)

-- Pet updates
remoteManager:On("PetUpdated", function(petData)
    if dataCache and dataCache.Get then
        local pets = dataCache:Get("pets") or {}
        if petData and petData.uniqueId then
            pets[petData.uniqueId] = petData
            if dataCache.Set then
                dataCache:Set("pets", pets)
            end
            eventBus:Fire("PetUpdated", petData)
        end
    end
end)

remoteManager:On("PetDeleted", function(petIds)
    if dataCache and dataCache.Get then
        local pets = dataCache:Get("pets") or {}
        for _, petId in ipairs(petIds) do
            pets[petId] = nil
        end
        if dataCache.Set then
            dataCache:Set("pets", pets)
        end
        eventBus:Fire("PetsDeleted", petIds)
    end
end)

-- Case opening
remoteManager:On("CaseOpened", function(results)
    eventBus:Fire("CaseOpened", results)
end)

-- Quests
remoteManager:On("QuestsUpdated", function(quests)
    if dataCache and dataCache.Set then
        dataCache:Set("quests", quests)
    end
    eventBus:Fire("QuestsUpdated", quests)
end)

remoteManager:On("QuestCompleted", function(questId)
    eventBus:Fire("QuestCompleted", questId)
    notificationSystem:SendNotification("Quest Complete!", "You have completed a quest!", "success")
end)

-- Achievements
remoteManager:On("AchievementUnlocked", function(achievement)
    eventBus:Fire("AchievementUnlocked", achievement)
    notificationSystem:SendNotification("Achievement Unlocked!", achievement.name, "success")
end)

-- Trading
remoteManager:On("TradeRequest", function(playerName)
    eventBus:Fire("TradeRequest", playerName)
    notificationSystem:SendNotification("Trade Request", 
        playerName .. " wants to trade with you!", "info", 10,
        {
            {
                text = "Accept",
                callback = function()
                    remoteManager:Fire("AcceptTrade", playerName)
                end
            },
            {
                text = "Decline",
                callback = function()
                    remoteManager:Fire("DeclineTrade", playerName)
                end
            }
        }
    )
end)

remoteManager:On("TradeStarted", function(tradeData)
    eventBus:Fire("TradeStarted", tradeData)
end)

remoteManager:On("TradeUpdated", function(tradeData)
    eventBus:Fire("TradeUpdated", tradeData)
end)

remoteManager:On("TradeCancelled", function()
    eventBus:Fire("TradeCancelled")
end)

remoteManager:On("TradeCompleted", function()
    eventBus:Fire("TradeCompleted")
    notificationSystem:SendNotification("Trade Complete!", "Trade completed successfully!", "success")
end)

-- Daily rewards
remoteManager:On("DailyRewardAvailable", function()
    eventBus:Fire("DailyRewardAvailable")
    if uiModules.DailyRewardUI then
        uiModules.DailyRewardUI:CheckAndShow()
    end
end)

remoteManager:On("DailyRewardUpdated", function(rewardData)
    if dataCache and dataCache.Set then
        dataCache:Set("dailyReward", rewardData)
    end
    eventBus:Fire("DailyRewardUpdated", rewardData)
end)

remoteManager:On("DailyRewardClaimed", function()
    eventBus:Fire("DailyRewardClaimed")
end)

-- Battle
remoteManager:On("BattleStarted", function(battleData)
    eventBus:Fire("BattleStarted", battleData)
end)

remoteManager:On("BattleEnded", function(result)
    eventBus:Fire("BattleEnded", result)
end)

-- Notifications
remoteManager:On("NotificationSent", function(title, message, type)
    notificationSystem:SendNotification(title, message, type or "info")
end)

-- ========================================
-- INITIALIZATION SEQUENCE
-- ========================================
print("[SanrioTycoonClient] Starting initialization sequence...")

local function initializePhase1()
    print("[SanrioTycoonClient] Phase 1: Creating main UI...")
    
    -- Initialize main UI
    local success, err = pcall(function()
        mainUI:Initialize()
    end)
    
    if not success then
        warn("[SanrioTycoonClient] MainUI initialization error: " .. tostring(err))
    else
        print("[SanrioTycoonClient] ✅ MainUI initialized")
    end
    
    -- Initialize window manager with screen GUI
    local screenGui = mainUI.ScreenGui or PlayerGui:FindFirstChild("SanrioTycoonUI")
    if screenGui then
        windowManager:Initialize(screenGui)
        print("[SanrioTycoonClient] ✅ WindowManager initialized")
        
        -- Fix panel overlap
        local mainPanel = screenGui:FindFirstChild("MainUIPanel")
        if mainPanel then
            mainPanel.Position = UDim2.new(0, 250, 0, 80)
        end
    else
        warn("[SanrioTycoonClient] ScreenGui not found!")
    end
    
    return true
end

local function initializePhase2()
    print("[SanrioTycoonClient] Phase 2: Loading initial data...")
    
    -- Request initial data from server
    task.spawn(function()
        task.wait(0.5)
        
        -- Get player data
        local success, result = pcall(function()
            return remoteManager:Invoke("GetPlayerData")
        end)
        
        if success and result then
            if dataCache and dataCache.Set then
                dataCache:Set("", result)
            end
            if stateManager and stateManager.Set then
                stateManager:Set("playerData", result)
            end
            eventBus:Fire("PlayerDataLoaded", result)
            print("[SanrioTycoonClient] ✅ Player data loaded")
        else
            warn("[SanrioTycoonClient] Failed to load player data: " .. tostring(result))
            -- Use default data
            if dataCache and dataCache.Get then
                local defaultData = dataCache:Get("")
                if stateManager and stateManager.Set then
                    stateManager:Set("playerData", defaultData)
                end
                eventBus:Fire("PlayerDataLoaded", defaultData)
            end
        end
        
        -- Load shop data for eggs
        local shopSuccess, shopData = pcall(function()
            return remoteManager:Invoke("GetShopData", "eggs")
        end)
        
        if shopSuccess and shopData and dataCache and dataCache.Set then
            dataCache:Set("eggDatabase", shopData)
            print("[SanrioTycoonClient] ✅ Egg data loaded")
        end
        
        -- Load other data
        local dataSets = {
            {name = "gamepasses", remote = "GetShopData", param = "gamepasses"},
            {name = "dailyRewards", remote = "GetDailyRewards"},
            {name = "clanList", remote = "GetClanList"},
            {name = "settings", remote = "LoadSettings"}
        }
        
        for _, dataSet in ipairs(dataSets) do
            task.spawn(function()
                local s, d = pcall(function()
                    if dataSet.param then
                        return remoteManager:Invoke(dataSet.remote, dataSet.param)
                    else
                        return remoteManager:Invoke(dataSet.remote)
                    end
                end)
                
                if s and d and dataCache and dataCache.Set then
                    dataCache:Set(dataSet.name, d)
                    print("[SanrioTycoonClient] ✅ " .. dataSet.name .. " loaded")
                end
            end)
        end
    end)
    
    return true
end

local function initializePhase3()
    print("[SanrioTycoonClient] Phase 3: Finalizing UI...")
    
    -- Initialize currency display
    if uiModules.CurrencyDisplay then
        local success = pcall(function()
            uiModules.CurrencyDisplay:Initialize()
        end)
        if success then
            print("[SanrioTycoonClient] ✅ Currency display initialized")
        end
    end
    
    -- Check daily rewards (skip if function doesn't exist)
    task.wait(1)
    if uiModules.DailyRewardUI then
        pcall(function()
            local hasCheckDailyReward = remoteManager:GetRemoteFunction("CheckDailyReward")
            if hasCheckDailyReward then
                uiModules.DailyRewardUI:CheckAndShow()
            end
        end)
    end
    
    -- Fire ready event
    eventBus:Fire("ClientReady")
    
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] ✅ CLIENT INITIALIZATION COMPLETE!")
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] Loaded modules: " .. loadedCount .. "/" .. #uiModuleNames)
    
    if #failedModules > 0 then
        print("[SanrioTycoonClient] Failed modules:")
        for _, fail in ipairs(failedModules) do
            print("[SanrioTycoonClient]   - " .. fail.name)
        end
    end
    
    return true
end

-- ========================================
-- PERFORMANCE MONITORING (FIXED!)
-- ========================================
local performanceStats = {
    fps = 0,
    memory = 0,
    ping = 0,
    dataReceived = 0,
    dataSent = 0
}

task.spawn(function()
    local lastTime = tick()
    local frameCount = 0
    
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastTime >= 1 then
            performanceStats.fps = frameCount
            performanceStats.memory = math.floor(collectgarbage("count"))
            
            -- Update state (with safety check)
            if stateManager and stateManager.Set then
                stateManager:Set("performance", performanceStats)
            end
            
            -- Reset
            frameCount = 0
            lastTime = currentTime
        end
    end)
end)

-- ========================================
-- START INITIALIZATION
-- ========================================
task.spawn(function()
    -- Small delay to ensure everything is loaded
    task.wait(0.5)
    
    -- Phase 1: Core UI
    initializePhase1()
    
    -- Phase 2: Data loading
    task.wait(0.1)
    initializePhase2()
    
    -- Phase 3: Final setup
    task.wait(0.5)
    initializePhase3()
end)

-- ========================================
-- PUBLIC API
-- ========================================
local SanrioTycoonClientAPI = {
    Version = "5.0.0",
    Modules = uiModules,
    Systems = {
        EventBus = eventBus,
        StateManager = stateManager,
        DataCache = dataCache,
        RemoteManager = remoteManager,
        SoundSystem = soundSystem,
        ParticleSystem = particleSystem,
        NotificationSystem = notificationSystem,
        AnimationSystem = animationSystem,
        EffectsLibrary = effectsLibrary
    },
    Framework = {
        MainUI = mainUI,
        WindowManager = windowManager
    },
    Config = ClientConfig,
    Utilities = ClientUtilities,
    
    -- Utility functions
    GetPlayerData = function()
        if dataCache and dataCache.Get then
            return dataCache:Get("")
        end
        return nil
    end,
    
    GetPet = function(uniqueId)
        if dataCache and dataCache.Get then
            local pets = dataCache:Get("pets") or {}
            return pets[uniqueId]
        end
        return nil
    end,
    
    RefreshUI = function()
        eventBus:Fire("RefreshUI")
    end,
    
    -- Debug functions
    Debug = {
        PrintModuleStatus = function()
            print("=== Sanrio Tycoon Client v5.0.0 ===")
            print("Loaded UI Modules: " .. loadedCount .. "/" .. #uiModuleNames)
            for name, instance in pairs(uiModules) do
                print("  ✅ " .. name)
            end
            if #failedModules > 0 then
                print("Failed Modules:")
                for _, fail in ipairs(failedModules) do
                    print("  ❌ " .. fail.name .. " - " .. fail.error)
                end
            end
        end,
        
        TestNotification = function()
            notificationSystem:SendNotification("Test", "This is a test notification!", "info")
        end,
        
        TestShop = function()
            if mainUI then
                mainUI:OpenModule("ShopUI")
            end
        end,
        
        TestInventory = function()
            if mainUI then
                mainUI:OpenModule("InventoryUI")
            end
        end,
        
        TestSettings = function()
            if mainUI then
                mainUI:OpenModule("SettingsUI")
            end
        end,
        
        FixOverlap = function()
            local screenGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
            if screenGui then
                local mainPanel = screenGui:FindFirstChild("MainUIPanel")
                if mainPanel then
                    mainPanel.Position = UDim2.new(0, 250, 0, 80)
                    print("Fixed panel overlap")
                end
            end
        end,
        
        ListRemotes = function()
            print("=== Registered Remotes ===")
            if RemoteEvents then
                print("RemoteEvents: " .. #RemoteEvents:GetChildren())
                for _, remote in ipairs(RemoteEvents:GetChildren()) do
                    if remote:IsA("RemoteEvent") then
                        print("  - " .. remote.Name)
                    end
                end
            end
            if RemoteFunctions then
                print("RemoteFunctions: " .. #RemoteFunctions:GetChildren())
                for _, remote in ipairs(RemoteFunctions:GetChildren()) do
                    if remote:IsA("RemoteFunction") then
                        print("  - " .. remote.Name)
                    end
                end
            end
        end
    }
}

-- Store in _G for access
_G.SanrioTycoonClient = SanrioTycoonClientAPI

print("[SanrioTycoonClient] 🎮 Sanrio Tycoon Client v5.0.0 READY!")
print("[SanrioTycoonClient] 📦 " .. loadedCount .. "/" .. #uiModuleNames .. " UI modules loaded")
print("[SanrioTycoonClient] ✨ Use _G.SanrioTycoonClient.Debug.PrintModuleStatus() for info")
print("[SanrioTycoonClient] 🛒 Use _G.SanrioTycoonClient.Debug.TestShop() to test shop")
print("[SanrioTycoonClient] 🎒 Use _G.SanrioTycoonClient.Debug.TestInventory() to test inventory")
print("[SanrioTycoonClient] ⚙️ Use _G.SanrioTycoonClient.Debug.TestSettings() to test settings")
print("[SanrioTycoonClient] 🔧 Use _G.SanrioTycoonClient.Debug.FixOverlap() if UI overlaps")

return SanrioTycoonClientAPI