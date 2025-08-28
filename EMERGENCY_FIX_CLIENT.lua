--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                    SANRIO TYCOON CLIENT - EMERGENCY FIX v6.0                         ║
    ║                         FIXES DATACACHE MISSING METHODS                              ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ========================================
-- SINGLETON CHECK
-- ========================================
if _G.SanrioTycoonClientLoaded then
    warn("[SanrioTycoonClient] Already loaded! Preventing double initialization.")
    return _G.SanrioTycoonClient
end
_G.SanrioTycoonClientLoaded = true

print("[SanrioTycoonClient] Starting EMERGENCY FIX client v6.0...")

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

task.wait(0.1)

-- ========================================
-- INFRASTRUCTURE LOADING (EMERGENCY FIX!)
-- ========================================
print("[SanrioTycoonClient] Loading infrastructure with emergency fixes...")

-- Load modules
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

-- EMERGENCY FIX: Create DataCache with fallback methods
local dataCache = DataCache.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    StateManager = stateManager,
    EventBus = eventBus,
    RemoteManager = remoteManager
})

-- If methods are missing, add them manually
if not dataCache.Set then
    warn("[SanrioTycoonClient] DataCache missing Set method - adding fallback")
    dataCache._data = dataCache._data or {}
    dataCache.Set = function(self, path, value)
        if path == "" then
            self._data = value
        else
            self._data[path] = value
        end
        return true
    end
end

if not dataCache.Get then
    warn("[SanrioTycoonClient] DataCache missing Get method - adding fallback")
    dataCache.Get = function(self, path)
        if path == "" or not path then
            return self._data
        end
        return self._data[path]
    end
end

if not dataCache.Watch then
    warn("[SanrioTycoonClient] DataCache missing Watch method - adding fallback")
    dataCache.Watch = function(self, path, callback)
        -- Simple implementation
        return {
            Disconnect = function() end
        }
    end
end

print("[SanrioTycoonClient] Infrastructure loaded with emergency fixes!")

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

_G.SpecialEffects = effectsLibrary

print("[SanrioTycoonClient] Systems loaded successfully!")

-- ========================================
-- FRAMEWORK MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading framework...")

local MainUI = require(FrameworkModules:WaitForChild("MainUI"))
local WindowManager = require(FrameworkModules:WaitForChild("WindowManager"))

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
        return moduleClass.new(uiDependencies)
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

for name, instance in pairs(uiModules) do
    mainUI:RegisterModule(name, instance)
end

-- ========================================
-- FIX UI OVERLAP
-- ========================================
task.spawn(function()
    task.wait(1)
    local screenGui = PlayerGui:WaitForChild("SanrioTycoonUI", 5)
    if screenGui then
        local mainPanel = screenGui:FindFirstChild("MainUIPanel")
        if mainPanel then
            mainPanel.Position = UDim2.new(0, 250, 0, 80)
            print("[SanrioTycoonClient] Adjusted MainUIPanel position")
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
    for _, remote in ipairs(RemoteEvents:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            remoteManager:RegisterRemoteEvent(remote)
        end
    end
    print("[SanrioTycoonClient] Registered " .. #RemoteEvents:GetChildren() .. " RemoteEvents")
    
    for _, remote in ipairs(RemoteFunctions:GetChildren()) do
        if remote:IsA("RemoteFunction") then
            remoteManager:RegisterRemoteFunction(remote)
        end
    end
    print("[SanrioTycoonClient] Registered " .. #RemoteFunctions:GetChildren() .. " RemoteFunctions")
end

-- ========================================
-- EVENT CONNECTIONS
-- ========================================
print("[SanrioTycoonClient] Setting up event handlers...")

remoteManager:On("CurrencyUpdated", function(currencies)
    dataCache:Set("currencies", currencies)
    stateManager:Set("currencies", currencies)
    eventBus:Fire("CurrencyUpdated", currencies)
end)

remoteManager:On("DataLoaded", function(playerData)
    if playerData then
        dataCache:Set("", playerData)
        stateManager:Set("playerData", playerData)
        eventBus:Fire("PlayerDataLoaded", playerData)
        print("[SanrioTycoonClient] Player data loaded from server")
    end
end)

remoteManager:On("DataUpdated", function(playerData)
    if playerData then
        dataCache:Set("", playerData)
        stateManager:Set("playerData", playerData)
        eventBus:Fire("PlayerDataUpdated", playerData)
    end
end)

remoteManager:On("PetUpdated", function(petData)
    local pets = dataCache:Get("pets") or {}
    if petData and petData.uniqueId then
        pets[petData.uniqueId] = petData
        dataCache:Set("pets", pets)
        eventBus:Fire("PetUpdated", petData)
    end
end)

remoteManager:On("PetDeleted", function(petIds)
    local pets = dataCache:Get("pets") or {}
    for _, petId in ipairs(petIds) do
        pets[petId] = nil
    end
    dataCache:Set("pets", pets)
    eventBus:Fire("PetsDeleted", petIds)
end)

remoteManager:On("CaseOpened", function(results)
    eventBus:Fire("CaseOpened", results)
end)

remoteManager:On("QuestsUpdated", function(quests)
    dataCache:Set("quests", quests)
    eventBus:Fire("QuestsUpdated", quests)
end)

remoteManager:On("QuestCompleted", function(questId)
    eventBus:Fire("QuestCompleted", questId)
    notificationSystem:SendNotification("Quest Complete!", "You have completed a quest!", "success")
end)

remoteManager:On("AchievementUnlocked", function(achievement)
    eventBus:Fire("AchievementUnlocked", achievement)
    notificationSystem:SendNotification("Achievement Unlocked!", achievement.name, "success")
end)

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

remoteManager:On("DailyRewardAvailable", function()
    eventBus:Fire("DailyRewardAvailable")
    if uiModules.DailyRewardUI then
        uiModules.DailyRewardUI:CheckAndShow()
    end
end)

remoteManager:On("DailyRewardUpdated", function(rewardData)
    dataCache:Set("dailyReward", rewardData)
    eventBus:Fire("DailyRewardUpdated", rewardData)
end)

remoteManager:On("DailyRewardClaimed", function()
    eventBus:Fire("DailyRewardClaimed")
end)

remoteManager:On("BattleStarted", function(battleData)
    eventBus:Fire("BattleStarted", battleData)
end)

remoteManager:On("BattleEnded", function(result)
    eventBus:Fire("BattleEnded", result)
end)

remoteManager:On("NotificationSent", function(title, message, type)
    notificationSystem:SendNotification(title, message, type or "info")
end)

-- ========================================
-- INITIALIZATION SEQUENCE
-- ========================================
print("[SanrioTycoonClient] Starting initialization sequence...")

local function initializePhase1()
    print("[SanrioTycoonClient] Phase 1: Creating main UI...")
    
    local success, err = pcall(function()
        mainUI:Initialize()
    end)
    
    if not success then
        warn("[SanrioTycoonClient] MainUI initialization error: " .. tostring(err))
    else
        print("[SanrioTycoonClient] ✅ MainUI initialized")
    end
    
    local screenGui = mainUI.ScreenGui or PlayerGui:FindFirstChild("SanrioTycoonUI")
    if screenGui then
        windowManager:Initialize(screenGui)
        print("[SanrioTycoonClient] ✅ WindowManager initialized")
        
        local mainPanel = screenGui:FindFirstChild("MainUIPanel")
        if mainPanel then
            mainPanel.Position = UDim2.new(0, 250, 0, 80)
        end
    end
    
    return true
end

local function initializePhase2()
    print("[SanrioTycoonClient] Phase 2: Loading initial data...")
    
    task.spawn(function()
        task.wait(0.5)
        
        local success, result = pcall(function()
            return remoteManager:Invoke("GetPlayerData")
        end)
        
        if success and result then
            dataCache:Set("", result)
            stateManager:Set("playerData", result)
            eventBus:Fire("PlayerDataLoaded", result)
            print("[SanrioTycoonClient] ✅ Player data loaded")
        else
            warn("[SanrioTycoonClient] Failed to load player data")
            local defaultData = {
                currencies = {coins = 0, gems = 0},
                pets = {},
                inventory = {},
                equipped = {},
                settings = {}
            }
            dataCache:Set("", defaultData)
            stateManager:Set("playerData", defaultData)
        end
        
        local shopSuccess, shopData = pcall(function()
            return remoteManager:Invoke("GetShopData", "eggs")
        end)
        
        if shopSuccess and shopData then
            dataCache:Set("eggDatabase", shopData)
            print("[SanrioTycoonClient] ✅ Egg data loaded")
        end
    end)
    
    return true
end

local function initializePhase3()
    print("[SanrioTycoonClient] Phase 3: Finalizing UI...")
    
    if uiModules.CurrencyDisplay then
        pcall(function()
            uiModules.CurrencyDisplay:Initialize()
        end)
    end
    
    task.wait(1)
    if uiModules.DailyRewardUI then
        pcall(function()
            uiModules.DailyRewardUI:CheckAndShow()
        end)
    end
    
    eventBus:Fire("ClientReady")
    
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] ✅ CLIENT INITIALIZATION COMPLETE!")
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] Loaded modules: " .. loadedCount .. "/" .. #uiModuleNames)
    
    return true
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================
local performanceStats = {
    fps = 0,
    memory = 0,
    ping = 0
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
            
            if stateManager and stateManager.Set then
                stateManager:Set("performance", performanceStats)
            end
            
            frameCount = 0
            lastTime = currentTime
        end
    end)
end)

-- ========================================
-- START INITIALIZATION
-- ========================================
task.spawn(function()
    task.wait(0.5)
    initializePhase1()
    task.wait(0.1)
    initializePhase2()
    task.wait(0.5)
    initializePhase3()
end)

-- ========================================
-- PUBLIC API
-- ========================================
local SanrioTycoonClientAPI = {
    Version = "6.0.0-EMERGENCY",
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
    
    GetPlayerData = function()
        return dataCache:Get("")
    end,
    
    GetPet = function(uniqueId)
        local pets = dataCache:Get("pets") or {}
        return pets[uniqueId]
    end,
    
    RefreshUI = function()
        eventBus:Fire("RefreshUI")
    end,
    
    Debug = {
        PrintModuleStatus = function()
            print("=== Sanrio Tycoon Client v6.0.0-EMERGENCY ===")
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
            notificationSystem:SendNotification("Test", "Emergency fix is working!", "success")
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
        
        CheckDataCache = function()
            print("=== DataCache Status ===")
            print("Has Set method:", dataCache.Set ~= nil)
            print("Has Get method:", dataCache.Get ~= nil)
            print("Has Watch method:", dataCache.Watch ~= nil)
            print("Data stored:", dataCache:Get("") ~= nil)
        end
    }
}

_G.SanrioTycoonClient = SanrioTycoonClientAPI

print("[SanrioTycoonClient] 🚨 EMERGENCY FIX v6.0.0 READY!")
print("[SanrioTycoonClient] 📦 " .. loadedCount .. "/" .. #uiModuleNames .. " UI modules loaded")
print("[SanrioTycoonClient] ⚠️ DataCache methods manually patched")
print("[SanrioTycoonClient] 🧪 Use _G.SanrioTycoonClient.Debug.CheckDataCache() to verify")

return SanrioTycoonClientAPI