--[[
    SIMPLE WORKING CLIENT
    This goes in StarterPlayer > StarterPlayerScripts as a LocalScript
    It loads all the modules from the ClientModules folder
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for character and modules
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local clientModules = playerScripts:WaitForChild("ClientModules")

print("[SimpleClient] Starting initialization...")

-- Module folders
local CoreModules = clientModules:WaitForChild("Core")
local InfrastructureModules = clientModules:WaitForChild("Infrastructure")
local SystemsModules = clientModules:WaitForChild("Systems")
local FrameworkModules = clientModules:WaitForChild("Framework")
local UIModules = clientModules:WaitForChild("UIModules")

-- ========================================
-- PHASE 1: CORE MODULES
-- ========================================
print("[SimpleClient] Loading core modules...")

local ClientConfig = require(CoreModules:WaitForChild("ClientConfig"))
local ClientUtilities = require(CoreModules:WaitForChild("ClientUtilities"))
local ClientTypes = require(CoreModules:WaitForChild("ClientTypes"))
local ClientServices = require(CoreModules:WaitForChild("ClientServices"))

-- Initialize services
ClientServices:Initialize()

-- ========================================
-- PHASE 2: INFRASTRUCTURE
-- ========================================
print("[SimpleClient] Loading infrastructure...")

-- Load infrastructure modules in order
local EventBus = require(InfrastructureModules:WaitForChild("EventBus"))
local StateManager = require(InfrastructureModules:WaitForChild("StateManager"))
local RemoteManager = require(InfrastructureModules:WaitForChild("RemoteManager"))
local DataCache = require(InfrastructureModules:WaitForChild("DataCache"))

-- Create instances with proper dependencies
local eventBus = EventBus.new({
    Config = ClientConfig,
    Utilities = ClientUtilities
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

-- ========================================
-- PHASE 3: SYSTEMS
-- ========================================
print("[SimpleClient] Loading systems...")

local SoundSystem = require(SystemsModules:WaitForChild("SoundSystem"))
local ParticleSystem = require(SystemsModules:WaitForChild("ParticleSystem"))
local AnimationSystem = require(SystemsModules:WaitForChild("AnimationSystem"))
local NotificationSystem = require(SystemsModules:WaitForChild("NotificationSystem"))
local UIFactory = require(SystemsModules:WaitForChild("UIFactory"))
local EffectsLibrary = require(SystemsModules:WaitForChild("EffectsLibrary"))

-- Create system instances
local soundSystem = SoundSystem.new({
    Config = ClientConfig,
    EventBus = eventBus
})

local particleSystem = ParticleSystem.new({
    Config = ClientConfig,
    EventBus = eventBus
})

local animationSystem = AnimationSystem.new({
    Config = ClientConfig,
    EventBus = eventBus,
    Utilities = ClientUtilities
})

local notificationSystem = NotificationSystem.new({
    Config = ClientConfig,
    EventBus = eventBus,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem
})

local uiFactory = UIFactory.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    EventBus = eventBus,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem
})

local effectsLibrary = EffectsLibrary.new({
    Config = ClientConfig,
    ParticleSystem = particleSystem,
    AnimationSystem = animationSystem,
    SoundSystem = soundSystem
})

-- Make effects globally available for old code
_G.SpecialEffects = effectsLibrary

-- ========================================
-- PHASE 4: FRAMEWORK
-- ========================================
print("[SimpleClient] Loading framework...")

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
    AnimationSystem = animationSystem,
    UIFactory = uiFactory,
    WindowManager = windowManager,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

-- Initialize MainUI
local success, err = pcall(function()
    mainUI:Initialize()
end)

if not success then
    warn("[SimpleClient] MainUI initialization error:", err)
end

-- ========================================
-- PHASE 5: UI MODULES
-- ========================================
print("[SimpleClient] Loading UI modules...")

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

-- Load and register all UI modules
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

local loadedModules = 0
local failedModules = {}

for _, moduleName in ipairs(uiModuleNames) do
    local moduleScript = UIModules:FindFirstChild(moduleName)
    if moduleScript then
        local success, result = pcall(function()
            local ModuleClass = require(moduleScript)
            local instance = ModuleClass.new(uiDependencies)
            mainUI:RegisterModule(moduleName, instance)
            return instance
        end)
        
        if success then
            loadedModules = loadedModules + 1
            print("[SimpleClient] ✓ Loaded", moduleName)
        else
            table.insert(failedModules, {name = moduleName, error = tostring(result)})
            warn("[SimpleClient] ✗ Failed to load", moduleName, ":", result)
        end
    else
        warn("[SimpleClient] Module not found:", moduleName)
    end
end

print("[SimpleClient] Loaded", loadedModules, "/", #uiModuleNames, "UI modules")

-- ========================================
-- PHASE 6: DATA LOADING
-- ========================================
print("[SimpleClient] Loading initial data...")

-- Request player data
task.spawn(function()
    local success, playerData = pcall(function()
        return remoteManager:InvokeServer("GetPlayerData")
    end)
    
    if success and playerData then
        -- Update all systems with player data
        dataCache:UpdatePlayerData(playerData)
        stateManager:SetState("playerData", playerData)
        eventBus:Fire("PlayerDataLoaded", playerData)
        print("[SimpleClient] ✓ Player data loaded")
    else
        warn("[SimpleClient] Failed to load player data")
    end
end)

-- ========================================
-- PHASE 7: EVENT CONNECTIONS
-- ========================================
print("[SimpleClient] Setting up connections...")

-- Listen for data updates
remoteManager:On("DataUpdated", function(data)
    if data then
        dataCache:UpdatePlayerData(data)
        stateManager:SetState("playerData", data)
    end
end)

-- Listen for notifications
remoteManager:On("ShowNotification", function(notificationData)
    notificationSystem:Show(notificationData)
end)

-- Currency updates
remoteManager:On("CurrencyUpdated", function(currencyData)
    if currencyData then
        dataCache:UpdateCurrency(currencyData.type, currencyData.amount)
    end
end)

-- ========================================
-- DONE!
-- ========================================
print("[SimpleClient] ========================================")
print("[SimpleClient] ✅ INITIALIZATION COMPLETE!")
print("[SimpleClient] ========================================")
print("[SimpleClient] UI Modules:", loadedModules, "/", #uiModuleNames)
if #failedModules > 0 then
    print("[SimpleClient] Failed modules:")
    for _, failure in ipairs(failedModules) do
        print("  -", failure.name, ":", failure.error)
    end
end

-- Fire ready event
eventBus:Fire("ClientReady")

-- Export API for debugging
local ClientAPI = {
    Version = "1.0.0",
    Systems = {
        EventBus = eventBus,
        StateManager = stateManager,
        DataCache = dataCache,
        RemoteManager = remoteManager,
        SoundSystem = soundSystem,
        ParticleSystem = particleSystem,
        AnimationSystem = animationSystem,
        NotificationSystem = notificationSystem,
        UIFactory = uiFactory,
        EffectsLibrary = effectsLibrary
    },
    Framework = {
        MainUI = mainUI,
        WindowManager = windowManager
    },
    Debug = {
        PrintModuleStatus = function()
            print("=== Module Status ===")
            print("Loaded UI Modules:", loadedModules)
            print("Failed:", #failedModules)
            
            local registered = mainUI._moduleStates or {}
            for name, state in pairs(registered) do
                print(" -", name, ":", state.isInitialized and "Ready" or "Not initialized")
            end
        end
    }
}

-- Set global for compatibility
_G.SanrioTycoonClient = ClientAPI

return ClientAPI