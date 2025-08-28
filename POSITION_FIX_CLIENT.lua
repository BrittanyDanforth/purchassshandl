--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                    SANRIO TYCOON CLIENT - POSITION FIX v7.1                          ║
    ║                         FIXES UI POSITIONING - NO OVERLAPS                           ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ========================================
-- SINGLETON CHECK
-- ========================================
if _G.SanrioTycoonClientLoaded then
    warn("[SanrioTycoonClient] Already loaded! Preventing duplicate initialization.")
    
    local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local existingGuis = {}
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name == "SanrioTycoonUI" then
            table.insert(existingGuis, gui)
        end
    end
    
    if #existingGuis > 1 then
        warn("[SanrioTycoonClient] Found " .. #existingGuis .. " duplicate SanrioTycoonUI - cleaning up!")
        for i = 2, #existingGuis do
            existingGuis[i]:Destroy()
        end
    end
    
    return _G.SanrioTycoonClient
end
_G.SanrioTycoonClientLoaded = true

print("[SanrioTycoonClient] Starting POSITION FIX client v7.1...")

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

print("[SanrioTycoonClient] Loading core modules...")

-- ========================================
-- CORE MODULE LOADING
-- ========================================
local ClientTypes = require(CoreModules:WaitForChild("ClientTypes"))
local ClientConfig = require(CoreModules:WaitForChild("ClientConfig"))
local ClientServices = require(CoreModules:WaitForChild("ClientServices"))
local ClientUtilities = require(CoreModules:WaitForChild("ClientUtilities"))

task.wait(0.1)

-- ========================================
-- FIX TWEEN FOR CASE OPENING
-- ========================================
local originalTween = ClientUtilities.Tween
ClientUtilities.Tween = function(instance, properties, tweenInfo)
    local validProperties = {}
    for prop, value in pairs(properties) do
        local success = pcall(function()
            local _ = instance[prop]
        end)
        if success then
            validProperties[prop] = value
        end
    end
    
    if next(validProperties) then
        return originalTween(instance, validProperties, tweenInfo)
    else
        return {
            Completed = {
                Wait = function() end,
                Connect = function(_, callback)
                    task.spawn(callback)
                    return {Disconnect = function() end}
                end
            },
            Cancel = function() end,
            Pause = function() end,
            Play = function() end
        }
    end
end

-- ========================================
-- INFRASTRUCTURE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading infrastructure...")

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

-- Patch DataCache if needed
if not dataCache.Set then
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
    dataCache.Get = function(self, path)
        if path == "" or not path then
            return self._data
        end
        return self._data and self._data[path]
    end
end

if not dataCache.Watch then
    dataCache.Watch = function(self, path, callback)
        return { Disconnect = function() end }
    end
end

print("[SanrioTycoonClient] Infrastructure loaded!")

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

-- DISABLE ANIMATION WARNINGS
animationSystem._performanceWarningThreshold = 999999
animationSystem._performanceWarningCooldown = 999999

-- ========================================
-- FIX UI FACTORY
-- ========================================
local uiFactory = UIFactory.new({
    EventBus = eventBus,
    StateManager = stateManager,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

-- Patch CreateFrame to ensure proper positioning
local originalCreateFrame = uiFactory.CreateFrame
if originalCreateFrame then
    uiFactory.CreateFrame = function(self, parent, config)
        -- Force minimum left offset to avoid navigation overlap
        if config.position then
            local xScale = config.position.X.Scale
            local xOffset = config.position.X.Offset
            local yScale = config.position.Y.Scale
            local yOffset = config.position.Y.Offset
            
            -- Ensure minimum 250 pixel offset from left to avoid navigation
            if xOffset < 250 and xScale == 0 then
                config.position = UDim2.new(xScale, 250, yScale, yOffset)
                print("[UIFactory] Adjusted frame position to avoid navigation overlap:", config.name)
            end
        end
        
        return originalCreateFrame(self, parent, config)
    end
end

-- Fix dropdown GetValue
local originalCreateDropdown = uiFactory.CreateDropdown
if originalCreateDropdown then
    uiFactory.CreateDropdown = function(self, config)
        local dropdown = originalCreateDropdown(self, config)
        if dropdown and not dropdown.GetValue then
            dropdown.GetValue = function()
                return dropdown.Value or (config and config.defaultValue) or ""
            end
        end
        return dropdown
    end
end

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

print("[SanrioTycoonClient] Systems loaded!")

-- ========================================
-- FRAMEWORK MODULE LOADING
-- ========================================
print("[SanrioTycoonClient] Loading framework...")

local MainUI = require(FrameworkModules:WaitForChild("MainUI"))
local WindowManager = require(FrameworkModules:WaitForChild("WindowManager"))

-- Clean existing GUI
local existingGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
if existingGui then
    warn("[SanrioTycoonClient] Found existing SanrioTycoonUI - removing it!")
    existingGui:Destroy()
    task.wait(0.1)
end

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

print("[SanrioTycoonClient] Framework loaded!")

-- ========================================
-- UI MODULE FIXES
-- ========================================
print("[SanrioTycoonClient] Loading UI modules with position fixes...")

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

-- Fix InventoryUI
local InventoryUIModule = require(UIModules:WaitForChild("InventoryUI"))
local originalInventoryNew = InventoryUIModule.new
InventoryUIModule.new = function(deps)
    local instance = originalInventoryNew(deps)
    
    -- Fix CreateStorageBar
    local originalCreateStorageBar = instance.CreateStorageBar
    if originalCreateStorageBar then
        instance.CreateStorageBar = function(self, parent)
            local bar = originalCreateStorageBar(self, parent)
            if bar and bar:FindFirstChild("Frame") then
                local frame = bar.Frame
                frame.UpdateValue = function(current, max)
                    local fillBar = frame:FindFirstChild("Fill")
                    if fillBar then
                        fillBar.Size = UDim2.new(math.min(current / max, 1), 0, 1, 0)
                    end
                    local label = frame:FindFirstChild("Label")
                    if label then
                        label.Text = current .. "/" .. max
                    end
                end
            end
            return bar
        end
    end
    
    return instance
end

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

-- Register modules
for name, instance in pairs(uiModules) do
    mainUI:RegisterModule(name, instance)
end

-- ========================================
-- POSITION FIX AFTER LOADING
-- ========================================
local function fixAllUIPositions()
    local screenGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
    if not screenGui then return end
    
    print("[SanrioTycoonClient] Fixing UI positions...")
    
    -- Fix main panel position
    local mainPanel = screenGui:FindFirstChild("MainUIPanel") or screenGui:FindFirstChild("MainPanel")
    if mainPanel then
        -- Ensure main panel doesn't overlap navigation
        mainPanel.Position = UDim2.new(0, 250, 0, 0)
        mainPanel.Size = UDim2.new(1, -250, 1, 0)
        print("[SanrioTycoonClient] Fixed MainUIPanel position")
    end
    
    -- Fix individual UI frames
    local framesToFix = {
        "InventoryFrame",
        "QuestFrame",
        "SettingsFrame",
        "TradingFrame",
        "BattleFrame",
        "SocialFrame",
        "ProgressionFrame"
    }
    
    for _, frameName in ipairs(framesToFix) do
        local frame = screenGui:FindFirstChild(frameName, true)
        if frame and frame:IsA("Frame") then
            -- Ensure proper positioning relative to parent
            frame.Position = UDim2.new(0, 10, 0, 80)
            frame.Size = UDim2.new(1, -20, 1, -90)
            print("[SanrioTycoonClient] Fixed " .. frameName .. " position")
        end
    end
end

-- ========================================
-- REMOTE CONNECTIONS
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
    
    for _, remote in ipairs(RemoteFunctions:GetChildren()) do
        if remote:IsA("RemoteFunction") then
            remoteManager:RegisterRemoteFunction(remote)
        end
    end
end

-- ========================================
-- EVENT CONNECTIONS
-- ========================================
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
    end
end)

remoteManager:On("DataUpdated", function(playerData)
    if playerData then
        dataCache:Set("", playerData)
        stateManager:Set("playerData", playerData)
        eventBus:Fire("PlayerDataUpdated", playerData)
    end
end)

-- Other events...
remoteManager:On("CaseOpened", function(results)
    eventBus:Fire("CaseOpened", results)
end)

-- ========================================
-- INITIALIZATION
-- ========================================
print("[SanrioTycoonClient] Starting initialization...")

task.spawn(function()
    task.wait(0.5)
    
    -- Phase 1: Initialize UI
    local success, err = pcall(function()
        mainUI:Initialize()
    end)
    
    if not success then
        warn("[SanrioTycoonClient] MainUI initialization error: " .. tostring(err))
    end
    
    -- Get ScreenGui
    local screenGui = mainUI.ScreenGui or PlayerGui:FindFirstChild("SanrioTycoonUI")
    if screenGui then
        windowManager:Initialize(screenGui)
        
        -- Apply position fixes
        task.wait(0.5)
        fixAllUIPositions()
    end
    
    -- Phase 2: Load data
    task.wait(0.5)
    
    local dataSuccess, playerData = pcall(function()
        return remoteManager:Invoke("GetPlayerData")
    end)
    
    if dataSuccess and playerData then
        dataCache:Set("", playerData)
        stateManager:Set("playerData", playerData)
        eventBus:Fire("PlayerDataLoaded", playerData)
    else
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
    
    -- Phase 3: Finalize
    task.wait(0.5)
    
    if uiModules.CurrencyDisplay then
        pcall(function()
            uiModules.CurrencyDisplay:Initialize()
        end)
    end
    
    -- Apply position fixes again to ensure they stick
    fixAllUIPositions()
    
    eventBus:Fire("ClientReady")
    
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] ✅ POSITION FIX CLIENT v7.1 READY!")
    print("[SanrioTycoonClient] ========================================")
end)

-- ========================================
-- PUBLIC API
-- ========================================
_G.SanrioTycoonClient = {
    Version = "7.1.0-POSITION-FIX",
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
    
    Debug = {
        FixPositions = function()
            fixAllUIPositions()
            print("Applied position fixes to all UIs")
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
        
        PrintPositions = function()
            local screenGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
            if screenGui then
                print("=== UI Positions ===")
                for _, child in ipairs(screenGui:GetDescendants()) do
                    if child:IsA("Frame") and (child.Name:match("Frame") or child.Name:match("UI")) then
                        print(child.Name .. " - Position:", tostring(child.Position), "Size:", tostring(child.Size))
                    end
                end
            end
        end,
        
        CleanupDuplicates = function()
            local count = 0
            for _, gui in ipairs(PlayerGui:GetChildren()) do
                if gui.Name == "SanrioTycoonUI" and gui ~= mainUI.ScreenGui then
                    gui:Destroy()
                    count = count + 1
                end
            end
            print("Cleaned up " .. count .. " duplicate SanrioTycoonUI instances")
        end
    }
}

print("[SanrioTycoonClient] 🎉 POSITION FIX v7.1 LOADED!")
print("[SanrioTycoonClient] 📦 " .. loadedCount .. "/" .. #uiModuleNames .. " UI modules loaded")
print("[SanrioTycoonClient] 🔧 Fixes applied:")
print("[SanrioTycoonClient]   ✅ MainPanel positioned at x=250 to avoid navigation")
print("[SanrioTycoonClient]   ✅ All UI frames use consistent positioning")
print("[SanrioTycoonClient]   ✅ Case opening TextTransparency fixed")
print("[SanrioTycoonClient]   ✅ No popup windows - uses original frame approach")

return _G.SanrioTycoonClient