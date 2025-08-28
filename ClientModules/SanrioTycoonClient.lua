--[[
    Module: SanrioTycoonClient
    Description: Main client initialization script that loads and orchestrates all modules
    This replaces the monolithic SANRIO_TYCOON_CLIENT_COMPLETE_5000PLUS.lua
    
    FINAL FIXED VERSION - Includes all dependency fixes:
    1. Fixed module path to correctly reference ClientModules folder
    2. Fixed ClientServices stack overflow
    3. Fixed EventBus Config dependency
    4. Fixed DataCache dependencies
    5. Fixed RemoteManager dependencies
    6. Fixed StateManager dependencies
    7. Fixed InventoryUI syntax error
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
-- MODULE PATHS
-- ========================================

-- FIXED: Correctly reference the ClientModules folder
local ClientModules = script.Parent:WaitForChild("ClientModules")
local CoreModules = ClientModules:WaitForChild("Core")
local InfrastructureModules = ClientModules:WaitForChild("Infrastructure")
local SystemModules = ClientModules:WaitForChild("Systems")
local FrameworkModules = ClientModules:WaitForChild("Framework")
local UIModules = ClientModules:WaitForChild("UIModules")

-- ========================================
-- CORE MODULE LOADING
-- ========================================

print("[SanrioTycoonClient] Starting initialization...")

-- Load core modules first (order matters!)
local ClientTypes = require(CoreModules:WaitForChild("ClientTypes"))
local ClientConfig = require(CoreModules:WaitForChild("ClientConfig"))
local ClientServices = require(CoreModules:WaitForChild("ClientServices"))
local ClientUtilities = require(CoreModules:WaitForChild("ClientUtilities"))

-- Wait for ClientServices to initialize (fixes stack overflow)
task.wait(0.1)

-- ========================================
-- INFRASTRUCTURE LOADING
-- ========================================

print("[SanrioTycoonClient] Loading infrastructure...")

local EventBus = require(InfrastructureModules:WaitForChild("EventBus"))
local StateManager = require(InfrastructureModules:WaitForChild("StateManager"))
local DataCache = require(InfrastructureModules:WaitForChild("DataCache"))
local RemoteManager = require(InfrastructureModules:WaitForChild("RemoteManager"))
local ModuleLoader = require(InfrastructureModules:WaitForChild("ModuleLoader"))

-- Initialize infrastructure with proper dependencies
-- IMPORTANT: Order matters due to circular dependencies

-- 1. EventBus (no dependencies on other infrastructure)
local eventBus = EventBus.new({
    Config = ClientConfig
})

-- 2. StateManager (depends on EventBus)
local stateManager = StateManager.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    EventBus = eventBus
})

-- 3. RemoteManager (depends on EventBus)
local remoteManager = RemoteManager.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    EventBus = eventBus
})

-- 4. DataCache (depends on all others)
local dataCache = DataCache.new({
    Config = ClientConfig,
    Utilities = ClientUtilities,
    StateManager = stateManager,
    EventBus = eventBus,
    RemoteManager = remoteManager
})

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

-- Initialize systems with dependencies
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

local notificationSystem = NotificationSystem.new({
    EventBus = eventBus,
    StateManager = stateManager,
    SoundSystem = soundSystem,
    AnimationSystem = nil, -- Will set after animation system init
    UIFactory = nil, -- Will set after UI factory init
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

local effectsLibrary = EffectsLibrary.new({
    EventBus = eventBus,
    StateManager = stateManager,
    ParticleSystem = particleSystem,
    AnimationSystem = animationSystem,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

-- Update circular dependencies
notificationSystem._animationSystem = animationSystem
notificationSystem._uiFactory = uiFactory

-- Make EffectsLibrary globally available for legacy compatibility
_G.SpecialEffects = effectsLibrary

-- ========================================
-- FRAMEWORK MODULE LOADING
-- ========================================

print("[SanrioTycoonClient] Loading framework...")

local MainUI = require(FrameworkModules:WaitForChild("MainUI"))
local WindowManager = require(FrameworkModules:WaitForChild("WindowManager"))

-- Initialize framework
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

-- Load all UI modules
local uiModuleDefinitions = {
    {name = "CurrencyDisplay", module = require(UIModules:WaitForChild("CurrencyDisplay"))},
    {name = "ShopUI", module = require(UIModules:WaitForChild("ShopUI"))},
    {name = "CaseOpeningUI", module = require(UIModules:WaitForChild("CaseOpeningUI"))},
    {name = "InventoryUI", module = require(UIModules:WaitForChild("InventoryUI"))},
    {name = "PetDetailsUI", module = require(UIModules:WaitForChild("PetDetailsUI"))},
    {name = "TradingUI", module = require(UIModules:WaitForChild("TradingUI"))},
    {name = "BattleUI", module = require(UIModules:WaitForChild("BattleUI"))},
    {name = "QuestUI", module = require(UIModules:WaitForChild("QuestUI"))},
    {name = "SettingsUI", module = require(UIModules:WaitForChild("SettingsUI"))},
    {name = "DailyRewardUI", module = require(UIModules:WaitForChild("DailyRewardUI"))},
    {name = "SocialUI", module = require(UIModules:WaitForChild("SocialUI"))},
    {name = "ProgressionUI", module = require(UIModules:WaitForChild("ProgressionUI"))}
}

local uiModuleInstances = {}
local loadedCount = 0
local failedModules = {}

for _, def in ipairs(uiModuleDefinitions) do
    print("[SanrioTycoonClient] Initializing " .. def.name .. "...")
    local success, result = pcall(function()
        return def.module.new(uiDependencies)
    end)
    
    if success then
        uiModuleInstances[def.name] = result
        loadedCount = loadedCount + 1
        print("[SanrioTycoonClient] ✓ " .. def.name .. " loaded successfully")
    else
        table.insert(failedModules, {name = def.name, error = tostring(result)})
        warn("[SanrioTycoonClient] ✗ Failed to initialize " .. def.name .. ": " .. tostring(result))
    end
end

print("[SanrioTycoonClient] Module loading complete: " .. loadedCount .. "/" .. #uiModuleDefinitions .. " loaded successfully")

-- Register UI modules with MainUI
for name, instance in pairs(uiModuleInstances) do
    if instance then
        mainUI:RegisterModule(name, instance)
    end
end

-- ========================================
-- REMOTE EVENT SETUP
-- ========================================

print("[SanrioTycoonClient] Setting up remote connections...")

-- Wait for remotes folder with timeout
local Remotes = ReplicatedStorage:WaitForChild("SanrioTycoon", 10)
if not Remotes then
    warn("[SanrioTycoonClient] SanrioTycoon folder not found in ReplicatedStorage!")
    -- Continue anyway, remotes might be created later
else
    local RemotesFolder = Remotes:WaitForChild("Remotes", 10)
    if RemotesFolder then
        local RemoteEvents = RemotesFolder:FindFirstChild("Events")
        local RemoteFunctions = RemotesFolder:FindFirstChild("Functions")
        
        -- Connect all remote events to the remote manager
        if RemoteEvents then
            for _, remote in ipairs(RemoteEvents:GetChildren()) do
                if remote:IsA("RemoteEvent") then
                    remoteManager:RegisterRemoteEvent(remote)
                end
            end
            print("[SanrioTycoonClient] Registered " .. #RemoteEvents:GetChildren() .. " RemoteEvents")
        else
            warn("[SanrioTycoonClient] Remote Events folder not found!")
        end
        
        if RemoteFunctions then
            for _, remote in ipairs(RemoteFunctions:GetChildren()) do
                if remote:IsA("RemoteFunction") then
                    remoteManager:RegisterRemoteFunction(remote)
                end
            end
            print("[SanrioTycoonClient] Registered " .. #RemoteFunctions:GetChildren() .. " RemoteFunctions")
        else
            warn("[SanrioTycoonClient] Remote Functions folder not found!")
        end
    else
        warn("[SanrioTycoonClient] Remotes folder not found!")
    end
end

-- ========================================
-- DATA INITIALIZATION
-- ========================================

print("[SanrioTycoonClient] Loading player data...")

-- Request initial data from server
local function loadInitialData()
    -- Use pcall to handle potential errors
    local success, playerData = pcall(function()
        return remoteManager:InvokeServer("GetPlayerData")
    end)
    
    if success and playerData then
        dataCache:Set("", playerData)
        stateManager:SetState("playerData", playerData)
        eventBus:Fire("PlayerDataLoaded", playerData)
        print("[SanrioTycoonClient] ✓ Player data loaded successfully")
    else
        warn("[SanrioTycoonClient] ✗ Failed to load player data: " .. tostring(playerData))
    end
    
    -- Load additional data
    local dataSets = {
        {name = "petDatabase", remote = "GetPetDatabase"},
        {name = "eggDatabase", remote = "GetEggDatabase"},
        {name = "gamepassDatabase", remote = "GetGamepassDatabase"}
    }
    
    for _, dataSet in ipairs(dataSets) do
        task.spawn(function()
            local success, data = pcall(function()
                return remoteManager:InvokeServer(dataSet.remote)
            end)
            
            if success and data then
                dataCache:Set(dataSet.name, data)
                stateManager:SetState(dataSet.name, data)
                print("[SanrioTycoonClient] ✓ " .. dataSet.name .. " loaded successfully")
            else
                warn("[SanrioTycoonClient] ✗ Failed to load " .. dataSet.name)
            end
        end)
    end
end

-- ========================================
-- EVENT CONNECTIONS
-- ========================================

print("[SanrioTycoonClient] Setting up event connections...")

-- Currency updates
remoteManager:On("UpdateCurrency", function(currencies)
    dataCache:Set("currencies", currencies)
    stateManager:SetState("currencies", currencies)
    eventBus:Fire("CurrencyUpdated", currencies)
end)

-- Pet updates
remoteManager:On("PetAdded", function(petData)
    local pets = dataCache:Get("pets") or {}
    pets[petData.uniqueId] = petData
    dataCache:Set("pets", pets)
    eventBus:Fire("PetAdded", petData)
end)

remoteManager:On("PetRemoved", function(uniqueId)
    local pets = dataCache:Get("pets") or {}
    pets[uniqueId] = nil
    dataCache:Set("pets", pets)
    eventBus:Fire("PetRemoved", uniqueId)
end)

remoteManager:On("PetUpdated", function(uniqueId, updates)
    local pets = dataCache:Get("pets") or {}
    if pets[uniqueId] then
        for key, value in pairs(updates) do
            pets[uniqueId][key] = value
        end
        dataCache:Set("pets", pets)
        eventBus:Fire("PetUpdated", uniqueId, updates)
    end
end)

-- Quest updates
remoteManager:On("QuestProgress", function(questId, progress)
    eventBus:Fire("QuestProgress", {questId = questId, progress = progress})
end)

remoteManager:On("QuestCompleted", function(questId)
    eventBus:Fire("QuestCompleted", questId)
    notificationSystem:SendNotification("Quest Complete!", 
        "You have completed a quest!", "success")
end)

-- Achievement updates
remoteManager:On("AchievementProgress", function(achievement)
    eventBus:Fire("AchievementProgress", achievement)
end)

remoteManager:On("AchievementUnlocked", function(achievement)
    eventBus:Fire("AchievementUnlocked", achievement)
end)

-- Battle updates
remoteManager:On("MatchmakingFound", function(opponentData)
    eventBus:Fire("MatchmakingFound", opponentData)
end)

remoteManager:On("BattleStarted", function(battleData)
    eventBus:Fire("BattleStarted", battleData)
end)

remoteManager:On("BattleEnded", function(result)
    eventBus:Fire("BattleEnded", result)
end)

-- Trading updates
remoteManager:On("TradeRequest", function(playerName)
    eventBus:Fire("TradeRequest", playerName)
    notificationSystem:SendNotification("Trade Request", 
        playerName .. " wants to trade with you!", "info", 10,
        {
            {
                text = "Accept",
                callback = function()
                    remoteManager:FireServer("AcceptTrade", playerName)
                end
            },
            {
                text = "Decline",
                callback = function()
                    remoteManager:FireServer("DeclineTrade", playerName)
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
    notificationSystem:SendNotification("Trade Complete!", 
        "Trade completed successfully!", "success")
end)

-- Daily rewards
remoteManager:On("DailyRewardAvailable", function()
    eventBus:Fire("DailyRewardAvailable")
    if uiModuleInstances.DailyRewardUI then
        uiModuleInstances.DailyRewardUI:CheckAndShow()
    end
end)

-- Case opening
remoteManager:On("CaseOpened", function(results)
    eventBus:Fire("CaseOpened", results)
end)

-- Notifications
remoteManager:On("Notification", function(title, message, type)
    notificationSystem:SendNotification(title, message, type or "info")
end)

-- ========================================
-- INITIALIZATION SEQUENCE
-- ========================================

print("[SanrioTycoonClient] Starting initialization sequence...")

-- Initialize in phases
local function initializePhase1()
    print("[SanrioTycoonClient] Phase 1: Creating main UI...")
    
    -- Create main UI
    local success, err = pcall(function()
        mainUI:Initialize()
    end)
    
    if not success then
        warn("[SanrioTycoonClient] MainUI initialization had errors: " .. tostring(err))
        -- Don't return false - continue anyway as MainUI might be partially initialized
    else
        print("[SanrioTycoonClient] ✓ MainUI initialized successfully")
    end
    
    -- Initialize window manager
    local screenGui = mainUI:GetScreenGui()
    if screenGui then
        windowManager:Initialize(screenGui)
        print("[SanrioTycoonClient] ✓ Window manager initialized")
    else
        warn("[SanrioTycoonClient] Failed to get ScreenGui from MainUI - continuing anyway")
        -- Don't return false - we can still load modules even without window manager
    end
    
    -- Load initial data
    loadInitialData()
    
    return true
end

local function initializePhase2()
    print("[SanrioTycoonClient] Phase 2: Initializing UI modules...")
    
    -- Initialize currency display
    if uiModuleInstances.CurrencyDisplay then
        local success, err = pcall(function()
            uiModuleInstances.CurrencyDisplay:Initialize()
        end)
        if not success then
            warn("[SanrioTycoonClient] Failed to initialize CurrencyDisplay: " .. tostring(err))
        else
            print("[SanrioTycoonClient] ✓ Currency display initialized")
        end
    end
    
    -- Check for daily rewards after a delay
    task.wait(1)
    if uiModuleInstances.DailyRewardUI then
        local success, err = pcall(function()
            uiModuleInstances.DailyRewardUI:CheckAndShow()
        end)
        if not success then
            warn("[SanrioTycoonClient] Failed to check daily rewards: " .. tostring(err))
        end
    end
    
    -- Fire ready event
    eventBus:Fire("ClientReady")
    
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] ✅ CLIENT INITIALIZATION COMPLETE!")
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] Loaded modules: " .. loadedCount .. "/" .. #uiModuleDefinitions)
    
    if #failedModules > 0 then
        print("[SanrioTycoonClient] Failed modules:")
        for _, fail in ipairs(failedModules) do
            print("[SanrioTycoonClient]   - " .. fail.name .. ": " .. fail.error)
        end
    end
end

-- ========================================
-- PERFORMANCE MONITORING
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
            
            -- Update state
            stateManager:SetState("performance", performanceStats)
            
            -- Reset
            frameCount = 0
            lastTime = currentTime
        end
    end)
end)

-- ========================================
-- CLEANUP ON LEAVE
-- ========================================

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        print("[SanrioTycoonClient] Player leaving, cleaning up...")
        
        -- Save settings
        if uiModuleInstances.SettingsUI then
            pcall(function()
                uiModuleInstances.SettingsUI:SaveSettings()
            end)
        end
        
        -- Clean up all modules
        for name, instance in pairs(uiModuleInstances) do
            if instance and instance.Destroy then
                pcall(function()
                    instance:Destroy()
                end)
            end
        end
        
        -- Clean up systems
        pcall(function() soundSystem:Destroy() end)
        pcall(function() particleSystem:Destroy() end)
        pcall(function() notificationSystem:Destroy() end)
        pcall(function() animationSystem:Destroy() end)
        pcall(function() effectsLibrary:Destroy() end)
        
        -- Clean up framework
        pcall(function() mainUI:Destroy() end)
        pcall(function() windowManager:Destroy() end)
        
        -- Clean up infrastructure
        pcall(function() eventBus:Destroy() end)
        pcall(function() stateManager:Destroy() end)
        pcall(function() remoteManager:Destroy() end)
        pcall(function() dataCache:Destroy() end)
    end
end)

-- ========================================
-- START INITIALIZATION
-- ========================================

-- Use spawn to prevent yielding
task.spawn(function()
    -- Small delay to ensure all modules are loaded
    task.wait(0.5)
    
    -- Phase 1: Core systems
    local phase1Success = initializePhase1()
    
    -- Always try phase 2 even if phase 1 had issues
    -- Small delay to ensure everything is loaded
    task.wait(0.1)
    
    -- Phase 2: UI and features
    initializePhase2()
    
    if not phase1Success then
        warn("[SanrioTycoonClient] Phase 1 had initialization issues, but continuing anyway")
    end
end)

-- ========================================
-- PUBLIC API
-- ========================================

-- Expose systems for debugging or external access
_G.SanrioTycoonClient = {
    Version = "2.2.0",
    Modules = uiModuleInstances,
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
        return dataCache:Get()
    end,
    
    GetPet = function(uniqueId)
        local pets = dataCache:Get("pets") or {}
        return pets[uniqueId]
    end,
    
    RefreshUI = function()
        eventBus:Fire("RefreshUI")
    end,
    
    -- Debug functions
    Debug = {
        PrintModuleStatus = function()
            print("=== Module Status ===")
            print("Loaded: " .. loadedCount .. "/" .. #uiModuleDefinitions)
            for name, instance in pairs(uiModuleInstances) do
                print("  " .. name .. ": ✓ Loaded")
            end
            if #failedModules > 0 then
                print("Failed:")
                for _, fail in ipairs(failedModules) do
                    print("  " .. fail.name .. ": ✗ " .. fail.error)
                end
            end
        end,
        
        GetErrors = function()
            return failedModules
        end,
        
        TestNotification = function()
            if notificationSystem then
                notificationSystem:SendNotification("Test", "This is a test notification!", "info")
            end
        end,
        
        TestUI = function()
            print("=== Testing UI Visibility ===")
            local screenGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
            if screenGui then
                print("ScreenGui found: " .. tostring(screenGui.Enabled))
                print("Visible elements:")
                for _, child in ipairs(screenGui:GetDescendants()) do
                    if child:IsA("Frame") and child.Visible and child.Parent == screenGui then
                        print("  - " .. child.Name)
                    end
                end
            else
                print("ScreenGui not found!")
            end
        end,
        
        ShowUI = function()
            local screenGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
            if screenGui then
                screenGui.Enabled = true
                print("UI enabled")
            end
        end,
        
        ListRemotes = function()
            print("=== Registered Remotes ===")
            -- This would need implementation in RemoteManager
            print("(Not implemented yet)")
        end
    }
}

print("[SanrioTycoonClient] 🎮 Sanrio Tycoon Client v2.2.0 Ready!")
print("[SanrioTycoonClient] 📦 " .. loadedCount .. "/" .. #uiModuleDefinitions .. " UI modules loaded")
print("[SanrioTycoonClient] ✨ Use _G.SanrioTycoonClient to access the API")
print("[SanrioTycoonClient] 🔧 Debug commands:")
print("[SanrioTycoonClient]   _G.SanrioTycoonClient.Debug.PrintModuleStatus()")
print("[SanrioTycoonClient]   _G.SanrioTycoonClient.Debug.TestUI()")
print("[SanrioTycoonClient]   _G.SanrioTycoonClient.Debug.TestNotification()")

return _G.SanrioTycoonClient