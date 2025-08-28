--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                      SANRIO TYCOON CLIENT - CLEAN & OPTIMIZED                         ║
    ║                          NO PATCHES - JUST MODULE LOADING                             ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

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
-- SINGLETON CHECK
-- ========================================
if _G.SanrioTycoonClientLoaded then
    warn("[SanrioTycoonClient] Already loaded! Cleaning up...")
    local existingGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
    if existingGui then
        existingGui:Destroy()
    end
    return _G.SanrioTycoonClient
end

_G.SanrioTycoonClientLoaded = true
print("[SanrioTycoonClient] Starting CLEAN & OPTIMIZED client...")

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
-- SAFE MODULE LOADER
-- ========================================
local loadedModules = {}
local function safeRequire(module)
    if loadedModules[module] then
        return loadedModules[module]
    end
    
    local success, result = pcall(require, module)
    if success then
        loadedModules[module] = result
        return result
    else
        warn("[SanrioTycoonClient] Failed to load module:", module.Name, "-", result)
        return nil
    end
end

-- ========================================
-- CORE MODULES
-- ========================================
print("[SanrioTycoonClient] Loading core modules...")
local ClientTypes = safeRequire(CoreModules:WaitForChild("ClientTypes"))
local ClientConfig = safeRequire(CoreModules:WaitForChild("ClientConfig"))
local ClientServices = safeRequire(CoreModules:WaitForChild("ClientServices"))
local ClientUtilities = safeRequire(CoreModules:WaitForChild("ClientUtilities"))

if not ClientConfig or not ClientUtilities then
    error("[SanrioTycoonClient] Critical core modules failed to load!")
end

-- ========================================
-- INFRASTRUCTURE
-- ========================================
print("[SanrioTycoonClient] Loading infrastructure...")
local EventBus = safeRequire(InfrastructureModules:WaitForChild("EventBus"))
local StateManager = safeRequire(InfrastructureModules:WaitForChild("StateManager"))
local DataCache = safeRequire(InfrastructureModules:WaitForChild("DataCache"))
local RemoteManager = safeRequire(InfrastructureModules:WaitForChild("RemoteManager"))

-- Initialize infrastructure
local eventBus = EventBus and EventBus.new({Config = ClientConfig})
local stateManager = StateManager and StateManager.new({Config = ClientConfig, Utilities = ClientUtilities, EventBus = eventBus})
local remoteManager = RemoteManager and RemoteManager.new({Config = ClientConfig, Utilities = ClientUtilities, EventBus = eventBus})
local dataCache = DataCache and DataCache.new({
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
local SoundSystem = safeRequire(SystemModules:WaitForChild("SoundSystem"))
local ParticleSystem = safeRequire(SystemModules:WaitForChild("ParticleSystem"))
local NotificationSystem = safeRequire(SystemModules:WaitForChild("NotificationSystem"))
local UIFactory = safeRequire(SystemModules:WaitForChild("UIFactory"))
local AnimationSystem = safeRequire(SystemModules:WaitForChild("AnimationSystem"))
local EffectsLibrary = safeRequire(SystemModules:WaitForChild("EffectsLibrary"))

-- Initialize systems
local soundSystem = SoundSystem and SoundSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})
local particleSystem = ParticleSystem and ParticleSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})
local animationSystem = AnimationSystem and AnimationSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})

-- Disable animation performance warnings
if animationSystem then
    animationSystem._performanceWarningThreshold = 999999
    animationSystem._performanceWarningCooldown = 999999
end

local uiFactory = UIFactory and UIFactory.new({
    EventBus = eventBus,
    StateManager = stateManager,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

local notificationSystem = NotificationSystem and NotificationSystem.new({
    EventBus = eventBus,
    StateManager = stateManager,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem,
    UIFactory = uiFactory,
    Config = ClientConfig
})

local effectsLibrary = EffectsLibrary and EffectsLibrary.new({
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
local MainUI = safeRequire(FrameworkModules:WaitForChild("MainUI"))
local WindowManager = safeRequire(FrameworkModules:WaitForChild("WindowManager"))

local windowManager = WindowManager and WindowManager.new({
    EventBus = eventBus,
    StateManager = stateManager,
    AnimationSystem = animationSystem,
    SoundSystem = soundSystem,
    UIFactory = uiFactory,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

local mainUI = MainUI and MainUI.new({
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
-- UI MODULES
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

for _, moduleName in ipairs(uiModuleNames) do
    local moduleScript = UIModules:FindFirstChild(moduleName)
    if moduleScript then
        local moduleClass = safeRequire(moduleScript)
        if moduleClass and moduleClass.new then
            local instance = moduleClass.new(uiDependencies)
            if instance then
                uiModules[moduleName] = instance
                print("[SanrioTycoonClient] ✅ " .. moduleName .. " loaded")
                
                -- Register with MainUI
                if mainUI and mainUI.RegisterModule then
                    mainUI:RegisterModule(moduleName, instance)
                end
            end
        end
    end
end

-- ========================================
-- REMOTE CONNECTIONS
-- ========================================
print("[SanrioTycoonClient] Setting up remote connections...")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")

if RemoteEvents and remoteManager then
    for _, remote in ipairs(RemoteEvents:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            remoteManager:RegisterRemoteEvent(remote)
        end
    end
end

if RemoteFunctions and remoteManager then
    for _, remote in ipairs(RemoteFunctions:GetChildren()) do
        if remote:IsA("RemoteFunction") then
            remoteManager:RegisterRemoteFunction(remote)
        end
    end
end

-- Set up remote handlers
if remoteManager then
    remoteManager:On("CurrencyUpdated", function(currencies)
        if dataCache then dataCache:Set("currencies", currencies) end
        if stateManager then stateManager:Set("currencies", currencies) end
        if eventBus then eventBus:Fire("CurrencyUpdated", currencies) end
    end)

    remoteManager:On("DataLoaded", function(playerData)
        if playerData then
            if dataCache then dataCache:Set("", playerData) end
            if stateManager then stateManager:Set("playerData", playerData) end
            if eventBus then eventBus:Fire("PlayerDataLoaded", playerData) end
        end
    end)

    remoteManager:On("CaseOpened", function(results, eggData)
        if uiModules.CaseOpeningUI and uiModules.CaseOpeningUI.Open then
            uiModules.CaseOpeningUI:Open(results, eggData)
        end
    end)
end

-- ========================================
-- INITIALIZATION
-- ========================================
task.spawn(function()
    task.wait(0.5)
    
    -- Initialize MainUI
    if mainUI and mainUI.Initialize then
        pcall(function() mainUI:Initialize() end)
    end
    
    -- Initialize WindowManager
    local screenGui = mainUI and mainUI.ScreenGui or PlayerGui:FindFirstChild("SanrioTycoonUI")
    if screenGui and windowManager and windowManager.Initialize then
        windowManager:Initialize(screenGui)
    end
    
    -- Load player data
    if remoteManager and remoteManager.Invoke then
        local success, playerData = pcall(function()
            return remoteManager:Invoke("GetPlayerData")
        end)
        
        if success and playerData then
            if dataCache then dataCache:Set("", playerData) end
            if stateManager then stateManager:Set("playerData", playerData) end
            if eventBus then eventBus:Fire("PlayerDataLoaded", playerData) end
        end
    end
    
    -- Initialize currency display
    if uiModules.CurrencyDisplay and uiModules.CurrencyDisplay.Initialize then
        pcall(function() uiModules.CurrencyDisplay:Initialize() end)
    end
    
    -- Fire ready event
    if eventBus then eventBus:Fire("ClientReady") end
    
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] ✅ CLEAN CLIENT READY!")
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] Loaded " .. table.getn(uiModules) .. " UI modules")
end)

-- ========================================
-- PUBLIC API
-- ========================================
_G.SanrioTycoonClient = {
    Version = "CLEAN-1.0.0",
    
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
    
    Debug = {
        -- Open any module
        OpenModule = function(moduleName)
            if mainUI and mainUI.OpenModule then
                mainUI:OpenModule(moduleName)
            end
        end,
        
        -- Close all modules
        CloseAllModules = function()
            if windowManager and windowManager.CloseAllWindows then
                windowManager:CloseAllWindows()
            end
        end,
        
        -- Get loaded modules
        GetLoadedModules = function()
            local loaded = {}
            for name, _ in pairs(uiModules) do
                table.insert(loaded, name)
            end
            return loaded
        end,
        
        -- Test specific modules
        TestShop = function()
            if mainUI then mainUI:OpenModule("ShopUI") end
        end,
        
        TestInventory = function()
            if mainUI then mainUI:OpenModule("InventoryUI") end
        end,
        
        TestQuest = function()
            if mainUI then mainUI:OpenModule("QuestUI") end
        end,
        
        TestSettings = function()
            if mainUI then mainUI:OpenModule("SettingsUI") end
        end,
        
        TestTrading = function()
            if mainUI then mainUI:OpenModule("TradingUI") end
        end,
        
        TestCase = function()
            if uiModules.CaseOpeningUI then
                local mockResults = {{
                    petId = "pet_hello_kitty_1",
                    rarity = "Common",
                    isNew = true
                }}
                uiModules.CaseOpeningUI:Open(mockResults, {name = "Basic Egg"})
            end
        end
    }
}

return _G.SanrioTycoonClient