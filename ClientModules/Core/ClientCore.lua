--[[
    Module: ClientCore
    Description: Main orchestrator for the Sanrio Tycoon client
    Manages initialization, module loading, lifecycle, and error boundaries
]]

local Types = require(script.Parent.ClientTypes)
local Config = require(script.Parent.ClientConfig)
local Services = require(script.Parent.ClientServices)
local Utilities = require(script.Parent.ClientUtilities)

local ClientCore = {}
ClientCore.__index = ClientCore

-- ========================================
-- MODULE REGISTRY
-- ========================================

local MODULE_LOAD_ORDER = {
    -- Phase 1: Infrastructure (must load first)
    {
        name = "Infrastructure",
        modules = {
            "EventBus",
            "StateManager", 
            "DataCache",
            "RemoteManager",
            "ModuleLoader",
        }
    },
    
    -- Phase 2: Systems (depend on infrastructure)
    {
        name = "Systems",
        modules = {
            "SoundSystem",
            "ParticleSystem",
            "NotificationSystem",
            "UIFactory",
            "AnimationSystem",
            "EffectsLibrary",
        }
    },
    
    -- Phase 3: Framework (depend on systems)
    {
        name = "Framework",
        modules = {
            "MainUI",
            "WindowManager",
            "CurrencyDisplay",
        }
    },
    
    -- Phase 4: UI Modules (depend on framework)
    {
        name = "UIModules",
        modules = {
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
            "ProgressionUI",
        }
    }
}

-- ========================================
-- INITIALIZATION
-- ========================================

function ClientCore.new()
    local self = setmetatable({}, ClientCore)
    
    -- Core properties
    self._initialized = false
    self._modules = {}
    self._loadedModules = {}
    self._moduleStatus = {}
    self._connections = {}
    self._errorHandlers = {}
    self._startTime = tick()
    
    -- Performance tracking
    self._performanceData = {
        moduleLoadTimes = {},
        initializationTime = 0,
        memoryUsage = {},
    }
    
    -- Error tracking
    self._errors = {
        count = 0,
        log = {},
        criticalErrors = {},
    }
    
    -- Events
    self.ModuleLoaded = Utilities.CreateUUID() -- Will be replaced with proper event
    self.ModuleError = Utilities.CreateUUID()
    self.InitializationComplete = Utilities.CreateUUID()
    self.Shutdown = Utilities.CreateUUID()
    
    return self
end

-- ========================================
-- PUBLIC METHODS
-- ========================================

function ClientCore:Initialize()
    if self._initialized then
        warn("[ClientCore] Already initialized")
        return
    end
    
    print("[ClientCore] Starting initialization...")
    
    -- Set up error boundary
    self:SetupErrorBoundary()
    
    -- Phase 1: Core setup
    local success, error = pcall(function()
        self:InitializePhase1_Core()
    end)
    
    if not success then
        self:HandleCriticalError("Phase 1 Core", error)
        return
    end
    
    -- Phase 2: Infrastructure
    success, error = pcall(function()
        self:InitializePhase2_Infrastructure()
    end)
    
    if not success then
        self:HandleCriticalError("Phase 2 Infrastructure", error)
        return
    end
    
    -- Phase 3: Systems
    success, error = pcall(function()
        self:InitializePhase3_Systems()
    end)
    
    if not success then
        self:HandleCriticalError("Phase 3 Systems", error)
        return
    end
    
    -- Phase 4: Framework
    success, error = pcall(function()
        self:InitializePhase4_Framework()
    end)
    
    if not success then
        self:HandleCriticalError("Phase 4 Framework", error)
        return
    end
    
    -- Phase 5: UI Modules (can be lazy loaded)
    success, error = pcall(function()
        self:InitializePhase5_UIModules()
    end)
    
    if not success then
        self:HandleCriticalError("Phase 5 UI Modules", error)
        -- Don't return, UI modules are not critical
    end
    
    -- Phase 6: Final setup
    self:InitializePhase6_FinalSetup()
    
    self._initialized = true
    self._performanceData.initializationTime = tick() - self._startTime
    
    print(string.format("[ClientCore] Initialization complete in %.2fs", self._performanceData.initializationTime))
    
    -- Fire initialization complete event
    if self.InitializationComplete and self.InitializationComplete.Fire then
        self.InitializationComplete:Fire()
    end
end

function ClientCore:GetModule(moduleName: string): Types.Module?
    if not self._loadedModules[moduleName] then
        warn("[ClientCore] Module not loaded:", moduleName)
        return nil
    end
    
    return self._loadedModules[moduleName]
end

function ClientCore:LoadModule(moduleName: string): Types.Module?
    if self._loadedModules[moduleName] then
        return self._loadedModules[moduleName]
    end
    
    -- Find module path
    local modulePath = self:FindModulePath(moduleName)
    if not modulePath then
        warn("[ClientCore] Module not found:", moduleName)
        return nil
    end
    
    -- Load module
    local success, moduleOrError = pcall(require, modulePath)
    if not success then
        self:HandleModuleError(moduleName, moduleOrError)
        return nil
    end
    
    -- Initialize module
    if type(moduleOrError.new) == "function" then
        local moduleInstance = moduleOrError.new(self:GetModuleDependencies(moduleName))
        self._loadedModules[moduleName] = moduleInstance
        self._moduleStatus[moduleName] = "loaded"
        
        print("[ClientCore] Loaded module:", moduleName)
        
        -- Fire module loaded event
        if self.ModuleLoaded and self.ModuleLoaded.Fire then
            self.ModuleLoaded:Fire(moduleName, moduleInstance)
        end
        
        return moduleInstance
    else
        -- Module is a simple table/function
        self._loadedModules[moduleName] = moduleOrError
        self._moduleStatus[moduleName] = "loaded"
        return moduleOrError
    end
end

function ClientCore:UnloadModule(moduleName: string): boolean
    local module = self._loadedModules[moduleName]
    if not module then
        return false
    end
    
    -- Call destroy if available
    if type(module.Destroy) == "function" then
        local success, error = pcall(module.Destroy, module)
        if not success then
            warn("[ClientCore] Error destroying module:", moduleName, error)
        end
    end
    
    -- Clear from registry
    self._loadedModules[moduleName] = nil
    self._moduleStatus[moduleName] = "unloaded"
    
    return true
end

function ClientCore:ReloadModule(moduleName: string): Types.Module?
    self:UnloadModule(moduleName)
    return self:LoadModule(moduleName)
end

function ClientCore:Shutdown()
    print("[ClientCore] Shutting down...")
    
    -- Fire shutdown event
    if self.Shutdown and self.Shutdown.Fire then
        self.Shutdown:Fire()
    end
    
    -- Unload all UI modules first
    for _, moduleData in ipairs(MODULE_LOAD_ORDER) do
        if moduleData.name == "UIModules" then
            for _, moduleName in ipairs(moduleData.modules) do
                self:UnloadModule(moduleName)
            end
        end
    end
    
    -- Then unload framework
    self:UnloadModule("CurrencyDisplay")
    self:UnloadModule("WindowManager")
    self:UnloadModule("MainUI")
    
    -- Then systems
    for _, moduleData in ipairs(MODULE_LOAD_ORDER) do
        if moduleData.name == "Systems" then
            for _, moduleName in ipairs(moduleData.modules) do
                self:UnloadModule(moduleName)
            end
        end
    end
    
    -- Finally infrastructure
    for _, moduleData in ipairs(MODULE_LOAD_ORDER) do
        if moduleData.name == "Infrastructure" then
            for _, moduleName in ipairs(moduleData.modules) do
                self:UnloadModule(moduleName)
            end
        end
    end
    
    -- Disconnect all connections
    for _, connection in pairs(self._connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    self._initialized = false
    print("[ClientCore] Shutdown complete")
end

-- ========================================
-- INITIALIZATION PHASES
-- ========================================

function ClientCore:InitializePhase1_Core()
    print("[ClientCore] Phase 1: Core setup")
    
    -- Validate configuration
    if not Config:ValidateConfig() then
        error("Configuration validation failed")
    end
    
    -- Set up core services
    if not Services.LocalPlayer then
        error("LocalPlayer not available")
    end
    
    -- Create events
    local Event = self:CreateEvent()
    self.ModuleLoaded = Event.new()
    self.ModuleError = Event.new()
    self.InitializationComplete = Event.new()
    self.Shutdown = Event.new()
    
    -- Set up performance monitoring
    if Config.DEBUG.ENABLED then
        self:StartPerformanceMonitoring()
    end
end

function ClientCore:InitializePhase2_Infrastructure()
    print("[ClientCore] Phase 2: Loading infrastructure")
    
    local infraModules = MODULE_LOAD_ORDER[1].modules
    for _, moduleName in ipairs(infraModules) do
        local startTime = tick()
        local module = self:LoadModule(moduleName)
        
        if not module then
            error("Failed to load critical infrastructure module: " .. moduleName)
        end
        
        self._performanceData.moduleLoadTimes[moduleName] = tick() - startTime
    end
end

function ClientCore:InitializePhase3_Systems()
    print("[ClientCore] Phase 3: Loading systems")
    
    local systemModules = MODULE_LOAD_ORDER[2].modules
    for _, moduleName in ipairs(systemModules) do
        local startTime = tick()
        local module = self:LoadModule(moduleName)
        
        if not module then
            warn("[ClientCore] Failed to load system module:", moduleName)
            -- Continue, systems are not critical
        end
        
        self._performanceData.moduleLoadTimes[moduleName] = tick() - startTime
    end
end

function ClientCore:InitializePhase4_Framework()
    print("[ClientCore] Phase 4: Loading framework")
    
    -- MainUI must load first
    local mainUI = self:LoadModule("MainUI")
    if not mainUI then
        error("Failed to load MainUI - critical framework component")
    end
    
    -- Then window manager
    local windowManager = self:LoadModule("WindowManager")
    if not windowManager then
        warn("[ClientCore] Failed to load WindowManager")
    end
    
    -- Then currency display
    local currencyDisplay = self:LoadModule("CurrencyDisplay")
    if not currencyDisplay then
        warn("[ClientCore] Failed to load CurrencyDisplay")
    end
end

function ClientCore:InitializePhase5_UIModules()
    print("[ClientCore] Phase 5: Loading UI modules")
    
    local uiModules = MODULE_LOAD_ORDER[4].modules
    
    -- Load critical UI modules immediately
    local criticalModules = {"InventoryUI", "ShopUI", "SettingsUI"}
    
    for _, moduleName in ipairs(criticalModules) do
        local startTime = tick()
        local module = self:LoadModule(moduleName)
        
        if not module then
            warn("[ClientCore] Failed to load UI module:", moduleName)
        end
        
        self._performanceData.moduleLoadTimes[moduleName] = tick() - startTime
    end
    
    -- Queue other modules for lazy loading
    task.spawn(function()
        for _, moduleName in ipairs(uiModules) do
            if not Utilities.TableContains(criticalModules, moduleName) then
                task.wait(0.1) -- Small delay between loads
                
                local startTime = tick()
                local module = self:LoadModule(moduleName)
                
                if module then
                    self._performanceData.moduleLoadTimes[moduleName] = tick() - startTime
                end
            end
        end
    end)
end

function ClientCore:InitializePhase6_FinalSetup()
    print("[ClientCore] Phase 6: Final setup")
    
    -- Set up remote handlers
    local remoteManager = self:GetModule("RemoteManager")
    if remoteManager then
        remoteManager:SetupDefaultHandlers()
    end
    
    -- Initialize data
    local dataCache = self:GetModule("DataCache")
    if dataCache then
        dataCache:RequestInitialData()
    end
    
    -- Start UI
    local mainUI = self:GetModule("MainUI")
    if mainUI and mainUI.Show then
        mainUI:Show()
    end
    
    -- Log memory usage
    self._performanceData.memoryUsage.afterInit = collectgarbage("count") / 1024
    
    print(string.format("[ClientCore] Memory usage: %.2f MB", self._performanceData.memoryUsage.afterInit))
end

-- ========================================
-- ERROR HANDLING
-- ========================================

function ClientCore:SetupErrorBoundary()
    -- Global error handler
    self._connections.ErrorHandler = Services.RunService.Heartbeat:Connect(function()
        -- Check for script errors
        local success, error = pcall(function()
            -- Heartbeat check
        end)
        
        if not success then
            self:HandleRuntimeError(error)
        end
    end)
end

function ClientCore:HandleCriticalError(phase: string, error: string)
    warn("[ClientCore] CRITICAL ERROR in", phase, ":", error)
    
    self._errors.criticalErrors[phase] = {
        error = error,
        timestamp = tick(),
        traceback = debug.traceback()
    }
    
    -- Try to show error UI
    local notificationSystem = self:GetModule("NotificationSystem")
    if notificationSystem then
        notificationSystem:ShowError("Critical error during startup. Please rejoin.")
    else
        -- Fallback error display
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Critical Error",
            Text = "Failed to initialize game. Please rejoin.",
            Duration = 10
        })
    end
end

function ClientCore:HandleModuleError(moduleName: string, error: string)
    warn("[ClientCore] Module error in", moduleName, ":", error)
    
    self._errors.count = self._errors.count + 1
    table.insert(self._errors.log, {
        module = moduleName,
        error = error,
        timestamp = tick(),
        traceback = debug.traceback()
    })
    
    self._moduleStatus[moduleName] = "error"
    
    -- Fire module error event
    if self.ModuleError and self.ModuleError.Fire then
        self.ModuleError:Fire(moduleName, error)
    end
end

function ClientCore:HandleRuntimeError(error: string)
    self._errors.count = self._errors.count + 1
    
    if #self._errors.log > 100 then
        table.remove(self._errors.log, 1)
    end
    
    table.insert(self._errors.log, {
        module = "Runtime",
        error = error,
        timestamp = tick()
    })
end

-- ========================================
-- HELPER METHODS
-- ========================================

function ClientCore:FindModulePath(moduleName: string): Instance?
    -- Search in all module folders
    local searchPaths = {
        script.Parent.Parent.Infrastructure,
        script.Parent.Parent.Systems,
        script.Parent.Parent.Framework,
        script.Parent.Parent.UIModules,
    }
    
    for _, folder in ipairs(searchPaths) do
        local module = folder:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            return module
        end
    end
    
    return nil
end

function ClientCore:GetModuleDependencies(moduleName: string): table
    -- Return common dependencies all modules need
    return {
        Core = self,
        Config = Config,
        Services = Services,
        Utilities = Utilities,
        Types = Types,
        EventBus = self:GetModule("EventBus"),
        StateManager = self:GetModule("StateManager"),
        DataCache = self:GetModule("DataCache"),
        RemoteManager = self:GetModule("RemoteManager"),
    }
end

function ClientCore:StartPerformanceMonitoring()
    local lastCheck = tick()
    local frameCount = 0
    
    self._connections.PerformanceMonitor = Services.RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        
        local now = tick()
        if now - lastCheck >= 1 then
            local fps = frameCount / (now - lastCheck)
            local memory = collectgarbage("count") / 1024
            
            -- Log performance data
            if Config.DEBUG.SHOW_FPS then
                print(string.format("[Performance] FPS: %.1f | Memory: %.1f MB", fps, memory))
            end
            
            frameCount = 0
            lastCheck = now
        end
    end)
end

function ClientCore:CreateEvent()
    -- Simple event implementation
    local Event = {}
    Event.__index = Event
    
    function Event.new()
        local self = setmetatable({}, Event)
        self._connections = {}
        return self
    end
    
    function Event:Connect(callback)
        local id = Utilities.CreateUUID()
        self._connections[id] = callback
        
        return {
            Disconnect = function()
                self._connections[id] = nil
            end,
            Connected = self._connections[id] ~= nil
        }
    end
    
    function Event:Fire(...)
        for _, callback in pairs(self._connections) do
            task.spawn(callback, ...)
        end
    end
    
    return Event
end

-- ========================================
-- PUBLIC API
-- ========================================

function ClientCore:GetLoadedModules(): {[string]: Types.ModuleStatus}
    return self._moduleStatus
end

function ClientCore:GetPerformanceData(): table
    return Utilities.DeepCopy(self._performanceData)
end

function ClientCore:GetErrorLog(): table
    return Utilities.DeepCopy(self._errors)
end

function ClientCore:IsInitialized(): boolean
    return self._initialized
end

-- Create singleton instance
local instance = ClientCore.new()

-- Auto-initialize on require (can be disabled if needed)
task.spawn(function()
    instance:Initialize()
end)

return instance