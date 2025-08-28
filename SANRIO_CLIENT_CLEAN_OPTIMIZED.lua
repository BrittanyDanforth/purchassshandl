--[[
    SANRIO TYCOON CLIENT - CLEAN OPTIMIZED VERSION
    This is a clean, performance-optimized client that just loads modules
    Module-specific fixes should be done in the module files themselves!
]]

-- ========================================
-- SINGLETON CHECK
-- ========================================
if _G.SanrioTycoonClientLoaded then
    warn("[SanrioTycoonClient] Already loaded!")
    return _G.SanrioTycoonClient
end
_G.SanrioTycoonClientLoaded = true

print("[SanrioTycoonClient] Starting CLEAN OPTIMIZED client v11.0...")

-- ========================================
-- SERVICES
-- ========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

-- ========================================
-- CORE MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading core modules...")

local ClientTypes = require(CoreModules:WaitForChild("ClientTypes"))
local ClientConfig = require(CoreModules:WaitForChild("ClientConfig"))
local ClientServices = require(CoreModules:WaitForChild("ClientServices"))
local ClientUtilities = require(CoreModules:WaitForChild("ClientUtilities"))

-- ========================================
-- INFRASTRUCTURE
-- ========================================
print("[SanrioTycoonClient] Loading infrastructure...")

local EventBus = require(InfrastructureModules:WaitForChild("EventBus"))
local StateManager = require(InfrastructureModules:WaitForChild("StateManager"))
local DataCache = require(InfrastructureModules:WaitForChild("DataCache"))
local RemoteManager = require(InfrastructureModules:WaitForChild("RemoteManager"))

-- Create instances
local eventBus = EventBus.new({Config = ClientConfig})
local stateManager = StateManager.new({Config = ClientConfig, Utilities = ClientUtilities, EventBus = eventBus})
local remoteManager = RemoteManager.new({Config = ClientConfig, Utilities = ClientUtilities, EventBus = eventBus})
local dataCache = DataCache.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    StateManager = stateManager,
    EventBus = eventBus,
    RemoteManager = remoteManager
})

-- ========================================
-- SYSTEMS
-- ========================================
print("[SanrioTycoonClient] Loading systems...")

local SoundSystem = require(SystemModules:WaitForChild("SoundSystem"))
local ParticleSystem = require(SystemModules:WaitForChild("ParticleSystem"))
local NotificationSystem = require(SystemModules:WaitForChild("NotificationSystem"))
local UIFactory = require(SystemModules:WaitForChild("UIFactory"))
local AnimationSystem = require(SystemModules:WaitForChild("AnimationSystem"))
local EffectsLibrary = require(SystemModules:WaitForChild("EffectsLibrary"))

-- Create system instances
local soundSystem = SoundSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})
local particleSystem = ParticleSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})
local animationSystem = AnimationSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})

-- Disable animation performance warnings to reduce spam
animationSystem._performanceWarningThreshold = 999999

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

-- ========================================
-- FRAMEWORK
-- ========================================
print("[SanrioTycoonClient] Loading framework...")

local MainUI = require(FrameworkModules:WaitForChild("MainUI"))
local WindowManager = require(FrameworkModules:WaitForChild("WindowManager"))

-- Clean up any existing UI
local existingGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
if existingGui then
    existingGui:Destroy()
    task.wait(0.1)
end

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

-- ========================================
-- UI MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading UI modules...")

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
    Utilities = ClientUtilities,
    MainUI = mainUI
}

-- UI Module list
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

-- Load modules
local uiModules = {}
local loadedCount = 0

for _, moduleName in ipairs(uiModuleNames) do
    local success, result = pcall(function()
        local moduleScript = UIModules:FindFirstChild(moduleName)
        if not moduleScript then
            warn("[SanrioTycoonClient] Module not found: " .. moduleName)
            return nil
        end
        
        local moduleClass = require(moduleScript)
        local instance = moduleClass.new(uiDependencies)
        
        -- Initialize if needed
        if instance.Initialize then
            pcall(function()
                instance:Initialize()
            end)
        end
        
        return instance
    end)
    
    if success and result then
        uiModules[moduleName] = result
        loadedCount = loadedCount + 1
        print("[SanrioTycoonClient] ✅ " .. moduleName .. " loaded")
    else
        warn("[SanrioTycoonClient] ❌ Failed to load " .. moduleName .. ": " .. tostring(result))
    end
end

-- Register modules with MainUI
for name, instance in pairs(uiModules) do
    mainUI:RegisterModule(name, instance)
end

-- ========================================
-- REMOTE EVENT HANDLERS
-- ========================================
print("[SanrioTycoonClient] Setting up remote handlers...")

-- Currency updates
remoteManager:On("CurrencyUpdated", function(currencies)
    if currencies then
        dataCache:Set("currencies", currencies)
        stateManager:Set("currencies", currencies)
        eventBus:Fire("CurrencyUpdated", currencies)
    end
end)

-- Data loading
remoteManager:On("DataLoaded", function(playerData)
    if playerData then
        dataCache:Set("", playerData)
        stateManager:Set("playerData", playerData)
        eventBus:Fire("PlayerDataLoaded", playerData)
    end
end)

-- Case opening
remoteManager:On("CaseOpened", function(results, eggData)
    if uiModules.CaseOpeningUI then
        uiModules.CaseOpeningUI:Open(results, eggData)
    end
end)

-- ========================================
-- INITIALIZATION
-- ========================================
task.spawn(function()
    -- Initialize MainUI
    local success = pcall(function()
        mainUI:Initialize()
    end)
    
    if not success then
        warn("[SanrioTycoonClient] Failed to initialize MainUI")
    end
    
    -- Initialize WindowManager
    local screenGui = mainUI.ScreenGui or PlayerGui:FindFirstChild("SanrioTycoonUI")
    if screenGui then
        windowManager:Initialize(screenGui)
    end
    
    -- Load player data
    task.wait(0.5)
    local dataSuccess, playerData = pcall(function()
        return remoteManager:Invoke("GetPlayerData")
    end)
    
    if dataSuccess and playerData then
        dataCache:Set("", playerData)
        stateManager:Set("playerData", playerData)
        eventBus:Fire("PlayerDataLoaded", playerData)
    end
    
    -- Fire ready event
    eventBus:Fire("ClientReady")
    
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] ✅ CLIENT READY!")
    print("[SanrioTycoonClient] ========================================")
end)

-- ========================================
-- PUBLIC API
-- ========================================
_G.SanrioTycoonClient = {
    Version = "11.0.0-CLEAN",
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
        EffectsLibrary = effectsLibrary,
        WindowManager = windowManager
    },
    Framework = {
        MainUI = mainUI,
        WindowManager = windowManager
    },
    
    -- Debug commands
    Debug = {
        OpenModule = function(moduleName)
            if mainUI then
                mainUI:OpenModule(moduleName)
            end
        end,
        
        CloseAllModules = function()
            if windowManager then
                windowManager:CloseAllWindows()
            end
        end,
        
        GetLoadedModules = function()
            print("=== Loaded Modules ===")
            for name, _ in pairs(uiModules) do
                print(" - " .. name)
            end
            print("Total: " .. loadedCount .. "/" .. #uiModuleNames)
        end
    }
}

print("[SanrioTycoonClient] 🎉 CLEAN CLIENT LOADED!")
print("[SanrioTycoonClient] 📦 " .. loadedCount .. "/" .. #uiModuleNames .. " modules loaded")

return _G.SanrioTycoonClient