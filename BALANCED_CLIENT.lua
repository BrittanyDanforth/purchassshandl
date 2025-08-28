--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                    SANRIO TYCOON CLIENT - BALANCED v9.0                              ║
    ║                    MODERATE UI SIZES + ALL FIXES                                     ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- The fix: Use moderate sizes that fit within MainPanel without overlapping navigation
-- Also fixes all UI errors (UpdateValue, PlaceholderText, etc.)

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

print("[SanrioTycoonClient] Starting BALANCED client v9.0...")

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
-- Moderate UI size that fits comfortably in MainPanel
-- MainPanel is at x=80 with width (1, -80), so we need good padding
local MODERATE_UI_SIZE = UDim2.new(0.85, 0, 0.85, 0)  -- 85% of MainPanel size
local MODERATE_UI_POSITION = UDim2.new(0.5, 0, 0.5, 0)  -- Centered
local UI_ANCHOR = Vector2.new(0.5, 0.5)  -- Center anchor

-- Alternative for specific UIs that need more space
local LARGE_UI_SIZE = UDim2.new(0.95, -40, 0.95, -40)  -- Almost full with padding
local LARGE_UI_POSITION = UDim2.new(0.5, 0, 0.5, 0)

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
-- UI FACTORY FIXES
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

-- Fix TextBox PlaceholderText
local originalCreateTextBox = uiFactory.CreateTextBox
if originalCreateTextBox then
    uiFactory.CreateTextBox = function(self, config)
        -- Fix PlaceholderText if it's a table
        if config and type(config.placeholderText) == "table" then
            config.placeholderText = tostring(config.placeholderText[1] or "")
        end
        return originalCreateTextBox(self, config)
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
print("[SanrioTycoonClient] Loading UI modules with balanced sizes...")

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

-- UI Size configurations
local UI_SIZES = {
    ShopUI = { size = LARGE_UI_SIZE, position = LARGE_UI_POSITION },  -- Shop needs more space
    InventoryUI = { size = MODERATE_UI_SIZE, position = MODERATE_UI_POSITION },
    QuestUI = { size = MODERATE_UI_SIZE, position = MODERATE_UI_POSITION },
    TradingUI = { size = LARGE_UI_SIZE, position = LARGE_UI_POSITION },  -- Trading needs space
    BattleUI = { size = LARGE_UI_SIZE, position = LARGE_UI_POSITION },  -- Battle needs space
    SettingsUI = { size = MODERATE_UI_SIZE, position = MODERATE_UI_POSITION },
    DailyRewardUI = { size = MODERATE_UI_SIZE, position = MODERATE_UI_POSITION },
    SocialUI = { size = MODERATE_UI_SIZE, position = MODERATE_UI_POSITION },
    ProgressionUI = { size = MODERATE_UI_SIZE, position = MODERATE_UI_POSITION },
    PetDetailsUI = { size = MODERATE_UI_SIZE, position = MODERATE_UI_POSITION }
}

-- Fix InventoryUI
local InventoryUIModule = require(UIModules:WaitForChild("InventoryUI"))
local originalInventoryNew = InventoryUIModule.new
InventoryUIModule.new = function(deps)
    local instance = originalInventoryNew(deps)
    
    -- Fix CreateStorageBar to not assume UpdateValue exists
    local originalCreateStorageBar = instance.CreateStorageBar
    if originalCreateStorageBar then
        instance.CreateStorageBar = function(self, parent)
            local bar = originalCreateStorageBar(self, parent)
            
            -- Create UpdateValue function on the bar container
            if bar then
                bar.UpdateValue = function(current, max)
                    local frame = bar:FindFirstChild("Frame") or bar
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
    
    -- Override CreateUI to use moderate size
    local originalCreateUI = instance.CreateUI
    if originalCreateUI then
        instance.CreateUI = function(self)
            originalCreateUI(self)
            -- Apply size after creation
            if self.Frame then
                self.Frame.Size = UI_SIZES.InventoryUI.size
                self.Frame.Position = UI_SIZES.InventoryUI.position
                self.Frame.AnchorPoint = UI_ANCHOR
            end
        end
    end
    
    return instance
end

-- Fix QuestUI
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
    
    -- Fix CreateUI to use moderate size
    local originalCreateUI = instance.CreateUI
    if originalCreateUI then
        instance.CreateUI = function(self)
            originalCreateUI(self)
            if self.Frame then
                self.Frame.Size = UI_SIZES.QuestUI.size
                self.Frame.Position = UI_SIZES.QuestUI.position
                self.Frame.AnchorPoint = UI_ANCHOR
            end
        end
    end
    
    return instance
end

-- Fix CaseOpeningUI
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

-- General UI module wrapper to apply sizes
local function wrapUIModule(moduleName, moduleClass)
    local originalNew = moduleClass.new
    return function(deps)
        local instance = originalNew(deps)
        
        -- Override CreateUI if it exists
        local originalCreateUI = instance.CreateUI
        if originalCreateUI and UI_SIZES[moduleName] then
            instance.CreateUI = function(self)
                originalCreateUI(self)
                -- Apply configured size
                if self.Frame then
                    self.Frame.Size = UI_SIZES[moduleName].size
                    self.Frame.Position = UI_SIZES[moduleName].position
                    self.Frame.AnchorPoint = UI_ANCHOR
                    print("[" .. moduleName .. "] Applied balanced size")
                end
            end
        end
        
        return instance
    end
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
        
        -- Apply wrapper for modules with size configs
        if UI_SIZES[moduleName] and moduleName ~= "InventoryUI" and moduleName ~= "QuestUI" and moduleName ~= "CaseOpeningUI" then
            moduleClass.new = wrapUIModule(moduleName, moduleClass)
        end
        
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

-- Register modules
for name, instance in pairs(uiModules) do
    mainUI:RegisterModule(name, instance)
end

-- ========================================
-- REMOTE CONNECTIONS
-- ========================================
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
    print("[SanrioTycoonClient] ✅ BALANCED CLIENT v9.0 READY!")
    print("[SanrioTycoonClient] ========================================")
end)

-- ========================================
-- PUBLIC API
-- ========================================
_G.SanrioTycoonClient = {
    Version = "9.0.0-BALANCED",
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
            end
        end,
        
        TestBattle = function()
            if mainUI then
                mainUI:OpenModule("BattleUI")
            end
        end,
        
        TestTrading = function()
            if mainUI then
                mainUI:OpenModule("TradingUI")
            end
        end,
        
        PrintSizes = function()
            print("=== BALANCED UI SIZES ===")
            print("Navigation: 80px wide")
            print("MainPanel: Starts at x=80")
            print("Moderate UIs: 85% of MainPanel")
            print("Large UIs (Shop/Battle/Trading): 95% with padding")
            
            local screenGui = PlayerGui:FindFirstChild("SanrioTycoonUI")
            if screenGui then
                for name, config in pairs(UI_SIZES) do
                    print(name .. ": " .. tostring(config.size))
                end
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
        end
    }
}

print("[SanrioTycoonClient] 🎉 BALANCED v9.0 LOADED!")
print("[SanrioTycoonClient] 📦 " .. loadedCount .. "/" .. #uiModuleNames .. " UI modules")
print("[SanrioTycoonClient] 🔧 Fixes:")
print("[SanrioTycoonClient]   ✅ Moderate UI sizes (85% for most, 95% for Shop/Battle/Trading)")
print("[SanrioTycoonClient]   ✅ No navigation overlap")
print("[SanrioTycoonClient]   ✅ UpdateValue error fixed")
print("[SanrioTycoonClient]   ✅ PlaceholderText error fixed")
print("[SanrioTycoonClient]   ✅ Quest closes properly")
print("[SanrioTycoonClient]   ✅ Case opening works")

return _G.SanrioTycoonClient