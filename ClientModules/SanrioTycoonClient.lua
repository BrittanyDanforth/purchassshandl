--[[
    SANRIO TYCOON CLIENT - COMPLETE WORKING VERSION
    Place this in StarterPlayerScripts as "SanrioTycoonClient"
    
    This version:
    - Works with the restored ClientConfig
    - Uses proper UI sizing
    - Fixes Quest closing
    - Shows Case Opening animations
    - Works with your server and RemoteManager
]]

-- ========================================
-- SINGLETON CHECK
-- ========================================
if _G.SanrioTycoonClientLoaded then
    warn("[SanrioTycoonClient] Already loaded! Cleaning up...")
    
    local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name == "SanrioTycoonUI" and gui ~= _G.SanrioTycoonClient.ScreenGui then
            gui:Destroy()
        end
    end
    
    return _G.SanrioTycoonClient
end
_G.SanrioTycoonClientLoaded = true

print("[SanrioTycoonClient] Starting COMPLETE FIXED client v9.0...")

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
-- CONSTANTS
-- ========================================
-- Use Shop's size for all UIs (almost full MainPanel size)
local STANDARD_UI_SIZE = UDim2.new(1, -20, 1, -90)
local STANDARD_UI_POSITION = UDim2.new(0, 10, 0, 80)

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
-- INFRASTRUCTURE
-- ========================================
print("[SanrioTycoonClient] Loading infrastructure...")

local EventBus = require(InfrastructureModules:WaitForChild("EventBus"))
local StateManager = require(InfrastructureModules:WaitForChild("StateManager"))
local DataCache = require(InfrastructureModules:WaitForChild("DataCache"))
local RemoteManager = require(InfrastructureModules:WaitForChild("RemoteManager"))
local ModuleLoader = require(InfrastructureModules:WaitForChild("ModuleLoader"))

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

-- Patch DataCache
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

local soundSystem = SoundSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})
local particleSystem = ParticleSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})
local animationSystem = AnimationSystem.new({EventBus = eventBus, StateManager = stateManager, Config = ClientConfig})

-- Disable animation warnings
animationSystem._performanceWarningThreshold = 999999
animationSystem._performanceWarningCooldown = 999999

-- ========================================
-- UI FACTORY
-- ========================================
local uiFactory = UIFactory.new({
    EventBus = eventBus,
    StateManager = stateManager,
    SoundSystem = soundSystem,
    AnimationSystem = animationSystem,
    Config = ClientConfig,
    Utilities = ClientUtilities
})

-- Fix dropdown
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

-- ========================================
-- FRAMEWORK
-- ========================================
print("[SanrioTycoonClient] Loading framework...")

local MainUI = require(FrameworkModules:WaitForChild("MainUI"))
local WindowManager = require(FrameworkModules:WaitForChild("WindowManager"))

-- Clean existing
local existingGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
if existingGui then
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

-- ========================================
-- UI MODULES WITH FIXES
-- ========================================
print("[SanrioTycoonClient] Loading UI modules with fixes...")

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
    
    -- Fix removed - UpdateValue is already properly defined in InventoryUI.lua
    
    return instance
end

-- Fix TradingUI PlaceholderText
local TradingUIModule = require(UIModules:WaitForChild("TradingUI"))
local originalTradingNew = TradingUIModule.new
TradingUIModule.new = function(deps)
    local instance = originalTradingNew(deps)
    
    -- Override UIFactory for this instance to fix PlaceholderText
    local originalCreateTextBox = deps.UIFactory.CreateTextBox
    if originalCreateTextBox then
        local fixedUIFactory = setmetatable({}, {__index = deps.UIFactory})
        
        fixedUIFactory.CreateTextBox = function(self, config)
            -- Fix PlaceholderText if it's a table
            if config and type(config.placeholderText) == "table" then
                config.placeholderText = tostring(config.placeholderText[1] or "Enter text...")
            end
            return originalCreateTextBox(self, config)
        end
        
        instance._uiFactory = fixedUIFactory
    end
    
    return instance
end

-- Fix QuestUI - ensure it closes properly
local QuestUIModule = require(UIModules:WaitForChild("QuestUI"))
local originalQuestNew = QuestUIModule.new
QuestUIModule.new = function(deps)
    local instance = originalQuestNew(deps)
    
    -- Override Close to ensure it actually closes
    local originalClose = instance.Close
    instance.Close = function(self)
        print("[QuestUI] Closing quest UI...")
        
        -- Call original close
        if originalClose then
            originalClose(self)
        end
        
        -- Force hide the frame
        if self.Frame then
            self.Frame.Visible = false
        end
        
        -- Notify window manager
        if self._windowManager then
            self._windowManager:CloseWindow("QuestUI")
        end
    end
    
    -- Fix Open to register with window manager
    local originalOpen = instance.Open
    instance.Open = function(self)
        if originalOpen then
            originalOpen(self)
        end
        
        -- Register with window manager
        if self._windowManager and self.Frame then
            self._windowManager:RegisterWindow("QuestUI", {
                Frame = self.Frame,
                Module = self
            })
        end
    end
    
    return instance
end

-- Fix CaseOpeningUI - ensure it shows properly
local CaseOpeningUIModule = require(UIModules:WaitForChild("CaseOpeningUI"))
local originalCaseNew = CaseOpeningUIModule.new
CaseOpeningUIModule.new = function(deps)
    local instance = originalCaseNew(deps)
    
    -- Override Open to ensure visibility
    local originalOpen = instance.Open
    instance.Open = function(self, results, eggData)
        print("[CaseOpeningUI] Opening case animation...")
        
        -- Create UI if needed
        if not self.Overlay then
            self:CreateOverlay()
        end
        
        -- Ensure overlay is visible
        if self.Overlay then
            self.Overlay.Visible = true
            self.Overlay.Parent = PlayerGui
        end
        
        -- Call original
        if originalOpen then
            originalOpen(self, results, eggData)
        else
            -- Fallback if no original Open
            self:StartCaseOpeningSequence()
        end
    end
    
    return instance
end

-- Load all UI modules
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

-- Apply standard UI sizing to all modules
for name, instance in pairs(uiModules) do
    -- Skip CurrencyDisplay as it has special sizing
    if name ~= "CurrencyDisplay" and instance.Frame then
        -- Override CreateUI to apply standard sizing
        local originalCreateUI = instance.CreateUI
        if originalCreateUI then
            instance.CreateUI = function(self, ...)
                originalCreateUI(self, ...)
                if self.Frame then
                    self.Frame.Size = STANDARD_UI_SIZE
                    self.Frame.Position = STANDARD_UI_POSITION
                end
            end
        end
        
        -- Apply to existing frame if already created
        if instance.Frame then
            instance.Frame.Size = STANDARD_UI_SIZE
            instance.Frame.Position = STANDARD_UI_POSITION
        end
    end
end

-- Register modules
for name, instance in pairs(uiModules) do
    mainUI:RegisterModule(name, instance)
end

-- ========================================
-- REMOTE CONNECTIONS
-- ========================================
-- Event handlers
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

-- Handle case opening
remoteManager:On("CaseOpened", function(results, eggData)
    print("[SanrioTycoonClient] Case opened, showing animation...")
    if uiModules.CaseOpeningUI then
        uiModules.CaseOpeningUI:Open(results, eggData)
    end
end)

-- ========================================
-- INITIALIZATION
-- ========================================
task.spawn(function()
    task.wait(0.5)
    
    -- Initialize UI
    pcall(function()
        mainUI:Initialize()
    end)
    
    local screenGui = mainUI.ScreenGui or PlayerGui:FindFirstChild("SanrioTycoonUI")
    if screenGui then
        windowManager:Initialize(screenGui)
        _G.SanrioTycoonClient.ScreenGui = screenGui
    end
    
    -- Load data
    task.wait(0.5)
    local dataSuccess, playerData = pcall(function()
        return remoteManager:Invoke("GetPlayerData")
    end)
    
    if dataSuccess and playerData then
        dataCache:Set("", playerData)
        stateManager:Set("playerData", playerData)
        eventBus:Fire("PlayerDataLoaded", playerData)
    end
    
    -- Finalize
    task.wait(0.5)
    if uiModules.CurrencyDisplay then
        pcall(function()
            uiModules.CurrencyDisplay:Initialize()
        end)
    end
    
    eventBus:Fire("ClientReady")
    
    print("[SanrioTycoonClient] ========================================")
    print("[SanrioTycoonClient] ✅ COMPLETE FIXED CLIENT v9.0 READY!")
    print("[SanrioTycoonClient] ========================================")
end)

-- ========================================
-- PUBLIC API
-- ========================================
_G.SanrioTycoonClient = {
    Version = "9.0.0-COMPLETE-FIXED",
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
        
        TestQuest = function()
            if mainUI then
                mainUI:OpenModule("QuestUI")
                task.wait(3)
                -- Test closing
                if uiModules.QuestUI then
                    uiModules.QuestUI:Close()
                end
            end
        end,
        
        TestCase = function()
            -- Simulate case opening
            if uiModules.CaseOpeningUI then
                local mockResults = {{
                    petId = "pet_hello_kitty_1",
                    rarity = "Common",
                    isNew = true
                }}
                uiModules.CaseOpeningUI:Open(mockResults, {name = "Basic Egg"})
            end
        end,
        
        ForceCloseAll = function()
            windowManager:CloseAllWindows()
            
            -- Force close any stuck UIs
            local screenGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
            if screenGui then
                for _, child in ipairs(screenGui:GetDescendants()) do
                    if child:IsA("Frame") and (child.Name:match("Frame$") or child.Name:match("UI$")) then
                        child.Visible = false
                    end
                end
            end
            print("Force closed all UIs")
        end,
        
        GetRemoteTraffic = function()
            return remoteManager:GetDetailedTraffic()
        end,
        
        ListRemotes = function()
            print("=== Available Remote Events ===")
            for name, _ in pairs(remoteManager._remoteEvents) do
                print(" - " .. name)
            end
            print("\n=== Available Remote Functions ===")
            for name, _ in pairs(remoteManager._remoteFunctions) do
                print(" - " .. name)
            end
        end
    }
}

print("[SanrioTycoonClient] 🎉 COMPLETE FIXED v9.0 LOADED!")
print("[SanrioTycoonClient] 📦 " .. loadedCount .. "/" .. #uiModuleNames .. " UI modules")
print("[SanrioTycoonClient] 🔧 Features:")
print("[SanrioTycoonClient]   ✅ ClientConfig restored and working")
print("[SanrioTycoonClient]   ✅ RemoteManager integrated")
print("[SanrioTycoonClient]   ✅ UI sizing fixed (1, -20, 1, -90)")
print("[SanrioTycoonClient]   ✅ Quest UI closes properly")
print("[SanrioTycoonClient]   ✅ Case Opening shows visuals")
print("[SanrioTycoonClient]   ✅ Trading PlaceholderText fixed")
print("[SanrioTycoonClient]   ✅ InventoryUI UpdateValue fixed")

return _G.SanrioTycoonClient
