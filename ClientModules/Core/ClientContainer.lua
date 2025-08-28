--[[
    ClientContainer
    Centralized dependency injection container for all client systems
    This provides a single source of truth for all initialized modules
]]

local ClientContainer = {}
ClientContainer.__index = ClientContainer

-- Services
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    GuiService = game:GetService("GuiService"),
    ContentProvider = game:GetService("ContentProvider"),
    HttpService = game:GetService("HttpService"),
    SoundService = game:GetService("SoundService"),
    Lighting = game:GetService("Lighting"),
    Debris = game:GetService("Debris"),
    MarketplaceService = game:GetService("MarketplaceService"),
    CollectionService = game:GetService("CollectionService")
}

-- Module paths
local ClientModules = script.Parent.Parent
local CoreModules = ClientModules:WaitForChild("Core")
local InfrastructureModules = ClientModules:WaitForChild("Infrastructure")
local SystemsModules = ClientModules:WaitForChild("Systems")
local FrameworkModules = ClientModules:WaitForChild("Framework")
local UIModules = ClientModules:WaitForChild("UIModules")

function ClientContainer.new()
    local self = setmetatable({}, ClientContainer)
    
    -- Store services for easy access
    self.Services = Services
    
    -- Initialize core modules first (order matters!)
    self:InitializeCore()
    self:InitializeInfrastructure()
    self:InitializeSystems()
    self:InitializeFramework()
    
    -- UI modules will be lazy loaded
    self.UIModules = {}
    self.UIModuleScripts = UIModules
    
    return self
end

function ClientContainer:InitializeCore()
    -- Load configuration and utilities first
    self.Config = require(CoreModules:WaitForChild("ClientConfig"))
    self.Utilities = require(CoreModules:WaitForChild("ClientUtilities"))
    self.Types = require(CoreModules:WaitForChild("ClientTypes"))
    
    -- Cached services accessor
    self.ClientServices = require(CoreModules:WaitForChild("ClientServices"))
    self.ClientServices:Initialize()
    
    print("[ClientContainer] Core modules initialized")
end

function ClientContainer:InitializeInfrastructure()
    -- EventBus (no dependencies)
    local EventBus = require(InfrastructureModules:WaitForChild("EventBus"))
    self.EventBus = EventBus.new({
        Config = self.Config,
        Utilities = self.Utilities
    })
    
    -- StateManager (depends on EventBus)
    local StateManager = require(InfrastructureModules:WaitForChild("StateManager"))
    self.StateManager = StateManager.new({
        Config = self.Config,
        Utilities = self.Utilities,
        EventBus = self.EventBus
    })
    
    -- RemoteManager (depends on EventBus)
    local RemoteManager = require(InfrastructureModules:WaitForChild("RemoteManager"))
    self.RemoteManager = RemoteManager.new({
        Config = self.Config,
        Utilities = self.Utilities,
        EventBus = self.EventBus
    })
    
    -- DataCache (depends on all others)
    local DataCache = require(InfrastructureModules:WaitForChild("DataCache"))
    self.DataCache = DataCache.new({
        Config = self.Config,
        Utilities = self.Utilities,
        StateManager = self.StateManager,
        EventBus = self.EventBus,
        RemoteManager = self.RemoteManager
    })
    
    print("[ClientContainer] Infrastructure modules initialized")
end

function ClientContainer:InitializeSystems()
    -- SoundSystem
    local SoundSystem = require(SystemsModules:WaitForChild("SoundSystem"))
    self.SoundSystem = SoundSystem.new({
        Config = self.Config,
        EventBus = self.EventBus
    })
    
    -- ParticleSystem
    local ParticleSystem = require(SystemsModules:WaitForChild("ParticleSystem"))
    self.ParticleSystem = ParticleSystem.new({
        Config = self.Config,
        EventBus = self.EventBus
    })
    
    -- AnimationSystem
    local AnimationSystem = require(SystemsModules:WaitForChild("AnimationSystem"))
    self.AnimationSystem = AnimationSystem.new({
        Config = self.Config,
        EventBus = self.EventBus,
        Utilities = self.Utilities
    })
    
    -- NotificationSystem
    local NotificationSystem = require(SystemsModules:WaitForChild("NotificationSystem"))
    self.NotificationSystem = NotificationSystem.new({
        Config = self.Config,
        EventBus = self.EventBus,
        SoundSystem = self.SoundSystem,
        AnimationSystem = self.AnimationSystem
    })
    
    -- UIFactory
    local UIFactory = require(SystemsModules:WaitForChild("UIFactory"))
    self.UIFactory = UIFactory.new({
        Config = self.Config,
        Utilities = self.Utilities,
        EventBus = self.EventBus,
        SoundSystem = self.SoundSystem,
        AnimationSystem = self.AnimationSystem
    })
    
    -- EffectsLibrary
    local EffectsLibrary = require(SystemsModules:WaitForChild("EffectsLibrary"))
    self.EffectsLibrary = EffectsLibrary.new({
        Config = self.Config,
        ParticleSystem = self.ParticleSystem,
        AnimationSystem = self.AnimationSystem,
        SoundSystem = self.SoundSystem
    })
    
    -- Make EffectsLibrary globally available for the old client
    _G.SpecialEffects = self.EffectsLibrary
    
    print("[ClientContainer] System modules initialized")
end

function ClientContainer:InitializeFramework()
    -- WindowManager
    local WindowManager = require(FrameworkModules:WaitForChild("WindowManager"))
    self.WindowManager = WindowManager.new({
        EventBus = self.EventBus,
        StateManager = self.StateManager,
        AnimationSystem = self.AnimationSystem,
        SoundSystem = self.SoundSystem,
        UIFactory = self.UIFactory,
        Config = self.Config,
        Utilities = self.Utilities
    })
    
    -- MainUI
    local MainUI = require(FrameworkModules:WaitForChild("MainUI"))
    self.MainUI = MainUI.new({
        EventBus = self.EventBus,
        StateManager = self.StateManager,
        DataCache = self.DataCache,
        RemoteManager = self.RemoteManager,
        SoundSystem = self.SoundSystem,
        NotificationSystem = self.NotificationSystem,
        AnimationSystem = self.AnimationSystem,
        UIFactory = self.UIFactory,
        WindowManager = self.WindowManager,
        Config = self.Config,
        Utilities = self.Utilities
    })
    
    print("[ClientContainer] Framework modules initialized")
end

function ClientContainer:GetUIDependencies()
    -- Return the standard dependencies table for UI modules
    return {
        EventBus = self.EventBus,
        StateManager = self.StateManager,
        DataCache = self.DataCache,
        RemoteManager = self.RemoteManager,
        SoundSystem = self.SoundSystem,
        ParticleSystem = self.ParticleSystem,
        AnimationSystem = self.AnimationSystem,
        NotificationSystem = self.NotificationSystem,
        UIFactory = self.UIFactory,
        WindowManager = self.WindowManager,
        EffectsLibrary = self.EffectsLibrary,
        Config = self.Config,
        Utilities = self.Utilities
    }
end

function ClientContainer:LazyLoadUIModule(moduleName)
    -- Check if already loaded
    if self.UIModules[moduleName] then
        return self.UIModules[moduleName]
    end
    
    -- Find module script
    local moduleScript = self.UIModuleScripts:FindFirstChild(moduleName)
    if not moduleScript then
        warn("[ClientContainer] UI module not found:", moduleName)
        return nil
    end
    
    -- Load and initialize
    local success, result = pcall(function()
        local ModuleClass = require(moduleScript)
        return ModuleClass.new(self:GetUIDependencies())
    end)
    
    if success then
        self.UIModules[moduleName] = result
        print("[ClientContainer] Lazy loaded UI module:", moduleName)
        return result
    else
        warn("[ClientContainer] Failed to load UI module", moduleName, ":", result)
        return nil
    end
end

function ClientContainer:Initialize()
    -- Initialize MainUI
    local success, err = pcall(function()
        self.MainUI:Initialize()
    end)
    
    if not success then
        warn("[ClientContainer] MainUI initialization error:", err)
    end
    
    -- Override MainUI's InitializeModule to use our lazy loading
    self.MainUI.InitializeModule = function(mainUI, moduleName)
        local instance = self:LazyLoadUIModule(moduleName)
        if instance then
            mainUI:RegisterModule(moduleName, instance)
            return true
        end
        return false
    end
    
    -- Load CurrencyDisplay immediately as it's always visible
    local currencyDisplay = self:LazyLoadUIModule("CurrencyDisplay")
    if currencyDisplay then
        self.MainUI:RegisterModule("CurrencyDisplay", currencyDisplay)
    end
    
    print("[ClientContainer] Initialization complete")
end

function ClientContainer:Destroy()
    -- Clean up all modules in reverse order
    
    -- UI Modules
    for name, module in pairs(self.UIModules) do
        if module.Destroy then
            module:Destroy()
        end
    end
    
    -- Framework
    if self.MainUI and self.MainUI.Destroy then
        self.MainUI:Destroy()
    end
    if self.WindowManager and self.WindowManager.Destroy then
        self.WindowManager:Destroy()
    end
    
    -- Systems
    local systems = {
        "EffectsLibrary", "UIFactory", "NotificationSystem",
        "AnimationSystem", "ParticleSystem", "SoundSystem"
    }
    for _, systemName in ipairs(systems) do
        local system = self[systemName]
        if system and system.Destroy then
            system:Destroy()
        end
    end
    
    -- Infrastructure
    local infrastructure = {
        "DataCache", "RemoteManager", "StateManager", "EventBus"
    }
    for _, moduleName in ipairs(infrastructure) do
        local module = self[moduleName]
        if module and module.Destroy then
            module:Destroy()
        end
    end
    
    print("[ClientContainer] Cleanup complete")
end

return ClientContainer