--[[
    Module: ModuleLoader
    Description: Dynamic module loading with dependency injection, hot reload, and circular dependency detection
    Manages lazy loading and module lifecycle
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)

local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

-- ========================================
-- TYPES
-- ========================================

type ModuleDefinition = {
    name: string,
    path: Instance,
    dependencies: {string},
    lazy: boolean,
    priority: number,
    version: string?,
}

type LoadedModule = {
    instance: any,
    definition: ModuleDefinition,
    loadTime: number,
    reloadCount: number,
    status: Types.ModuleStatus,
    error: string?,
}

-- ========================================
-- CONSTANTS
-- ========================================

local MODULE_PATHS = {
    Core = script.Parent.Parent.Core,
    Infrastructure = script.Parent.Parent.Infrastructure,
    Systems = script.Parent.Parent.Systems,
    Framework = script.Parent.Parent.Framework,
    UIModules = script.Parent.Parent.UIModules,
}

local LAZY_LOAD_DELAY = 0.1
local MAX_DEPENDENCY_DEPTH = 10
local HOT_RELOAD_COOLDOWN = 1

-- ========================================
-- INITIALIZATION
-- ========================================

function ModuleLoader.new(dependencies)
    local self = setmetatable({}, ModuleLoader)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    self._eventBus = dependencies.EventBus
    
    -- Module registry
    self._modules = {} -- name -> LoadedModule
    self._definitions = {} -- name -> ModuleDefinition
    self._loadQueue = {}
    self._loadingModules = {} -- Track modules currently being loaded
    
    -- Dependency tracking
    self._dependencyGraph = {} -- module -> {dependencies}
    self._reverseDependencies = {} -- module -> {dependents}
    
    -- Hot reload
    self._hotReloadEnabled = false
    self._lastReloadTimes = {}
    self._fileWatchers = {}
    
    -- Performance
    self._totalLoadTime = 0
    self._moduleLoadTimes = {}
    
    -- Settings
    self._debugMode = self._config.DEBUG.ENABLED
    self._lazyLoadingEnabled = true
    
    self:Initialize()
    
    return self
end

function ModuleLoader:Initialize()
    -- Scan for available modules
    self:ScanModules()
    
    -- Build dependency graph
    self:BuildDependencyGraph()
    
    -- Start lazy load processor
    if self._lazyLoadingEnabled then
        self:StartLazyLoadProcessor()
    end
    
    if self._debugMode then
        print(string.format("[ModuleLoader] Found %d modules", self:CountTable(self._definitions)))
    end
end

-- ========================================
-- MODULE DISCOVERY
-- ========================================

function ModuleLoader:ScanModules()
    for categoryName, folder in pairs(MODULE_PATHS) do
        if folder and folder:IsA("Folder") then
            self:ScanFolder(folder, categoryName)
        end
    end
end

function ModuleLoader:ScanFolder(folder: Instance, category: string)
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") then
            -- Extract module info
            local definition: ModuleDefinition = {
                name = child.Name,
                path = child,
                dependencies = self:ExtractDependencies(child),
                lazy = category == "UIModules", -- UI modules are lazy by default
                priority = self:GetModulePriority(category, child.Name),
                version = child:GetAttribute("Version"),
            }
            
            self._definitions[child.Name] = definition
            
            if self._debugMode then
                print(string.format("[ModuleLoader] Discovered: %s (%s)", child.Name, category))
            end
        elseif child:IsA("Folder") then
            -- Recursive scan
            self:ScanFolder(child, category .. "/" .. child.Name)
        end
    end
end

function ModuleLoader:ExtractDependencies(module: ModuleScript): {string}
    -- This is a simplified version - in production, you'd parse the module
    -- or use attributes to declare dependencies
    
    local deps = module:GetAttribute("Dependencies")
    if deps and type(deps) == "string" then
        return string.split(deps, ",")
    end
    
    -- Default dependencies based on module location
    local parent = module.Parent
    if parent == MODULE_PATHS.UIModules then
        return {"EventBus", "StateManager", "DataCache", "RemoteManager"}
    elseif parent == MODULE_PATHS.Systems then
        return {"Config", "Utilities"}
    else
        return {}
    end
end

function ModuleLoader:GetModulePriority(category: string, moduleName: string): number
    -- Lower number = higher priority (loads first)
    local priorities = {
        Core = 1,
        Infrastructure = 2,
        Systems = 3,
        Framework = 4,
        UIModules = 5,
    }
    
    -- Special cases
    local specialPriorities = {
        ClientCore = 0,
        EventBus = 1,
        StateManager = 2,
        DataCache = 3,
        RemoteManager = 4,
    }
    
    return specialPriorities[moduleName] or priorities[category] or 99
end

-- ========================================
-- DEPENDENCY MANAGEMENT
-- ========================================

function ModuleLoader:BuildDependencyGraph()
    self._dependencyGraph = {}
    self._reverseDependencies = {}
    
    for moduleName, definition in pairs(self._definitions) do
        self._dependencyGraph[moduleName] = definition.dependencies or {}
        
        -- Build reverse dependencies
        for _, dep in ipairs(definition.dependencies or {}) do
            if not self._reverseDependencies[dep] then
                self._reverseDependencies[dep] = {}
            end
            table.insert(self._reverseDependencies[dep], moduleName)
        end
    end
    
    -- Check for circular dependencies
    for moduleName in pairs(self._definitions) do
        if self:HasCircularDependency(moduleName) then
            error(string.format("[ModuleLoader] Circular dependency detected for: %s", moduleName))
        end
    end
end

function ModuleLoader:HasCircularDependency(moduleName: string, visited: {[string]: boolean}?, stack: {[string]: boolean}?): boolean
    visited = visited or {}
    stack = stack or {}
    
    visited[moduleName] = true
    stack[moduleName] = true
    
    local dependencies = self._dependencyGraph[moduleName] or {}
    
    for _, dep in ipairs(dependencies) do
        if not visited[dep] then
            if self:HasCircularDependency(dep, visited, stack) then
                return true
            end
        elseif stack[dep] then
            -- Found a cycle
            return true
        end
    end
    
    stack[moduleName] = nil
    return false
end

function ModuleLoader:GetLoadOrder(): {string}
    local order = {}
    local visited = {}
    
    local function visit(moduleName: string)
        if visited[moduleName] then
            return
        end
        
        visited[moduleName] = true
        
        -- Visit dependencies first
        local deps = self._dependencyGraph[moduleName] or {}
        for _, dep in ipairs(deps) do
            visit(dep)
        end
        
        -- Then add this module
        table.insert(order, moduleName)
    end
    
    -- Sort by priority first
    local sortedModules = {}
    for name, def in pairs(self._definitions) do
        table.insert(sortedModules, {name = name, priority = def.priority})
    end
    table.sort(sortedModules, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Visit in priority order
    for _, module in ipairs(sortedModules) do
        visit(module.name)
    end
    
    return order
end

-- ========================================
-- MODULE LOADING
-- ========================================

function ModuleLoader:LoadModule(moduleName: string, force: boolean?): any
    -- Check if already loaded
    local loaded = self._modules[moduleName]
    if loaded and loaded.status == "loaded" and not force then
        return loaded.instance
    end
    
    -- Check if currently loading (prevent infinite recursion)
    if self._loadingModules[moduleName] then
        warn(string.format("[ModuleLoader] Recursive dependency detected: %s", moduleName))
        return nil
    end
    
    -- Get definition
    local definition = self._definitions[moduleName]
    if not definition then
        warn(string.format("[ModuleLoader] Module not found: %s", moduleName))
        return nil
    end
    
    -- Mark as loading
    self._loadingModules[moduleName] = true
    
    local startTime = tick()
    
    -- Load dependencies first
    local dependencies = {}
    for _, depName in ipairs(definition.dependencies or {}) do
        local dep = self:LoadModule(depName)
        if not dep and self:IsRequiredDependency(depName) then
            self._loadingModules[moduleName] = nil
            error(string.format("[ModuleLoader] Required dependency failed to load: %s", depName))
        end
        dependencies[depName] = dep
    end
    
    -- Inject additional core dependencies
    dependencies.Config = Config
    dependencies.Utilities = Utilities
    dependencies.Services = require(script.Parent.Parent.Core.ClientServices)
    dependencies.Types = Types
    
    -- Load the module
    local success, moduleOrError = pcall(require, definition.path)
    
    if not success then
        self._loadingModules[moduleName] = nil
        
        local errorModule: LoadedModule = {
            instance = nil,
            definition = definition,
            loadTime = tick() - startTime,
            reloadCount = 0,
            status = "error",
            error = tostring(moduleOrError),
        }
        
        self._modules[moduleName] = errorModule
        
        warn(string.format("[ModuleLoader] Failed to load %s: %s", moduleName, moduleOrError))
        
        -- Fire error event
        if self._eventBus then
            self._eventBus:Fire("ModuleLoadError", {
                module = moduleName,
                error = moduleOrError,
            })
        end
        
        return nil
    end
    
    -- Initialize module if it has a constructor
    local instance = moduleOrError
    if type(moduleOrError) == "table" and type(moduleOrError.new) == "function" then
        local constructSuccess, instanceOrError = pcall(moduleOrError.new, dependencies)
        
        if constructSuccess then
            instance = instanceOrError
        else
            self._loadingModules[moduleName] = nil
            warn(string.format("[ModuleLoader] Failed to initialize %s: %s", moduleName, instanceOrError))
            return nil
        end
    end
    
    -- Store loaded module
    local loadedModule: LoadedModule = {
        instance = instance,
        definition = definition,
        loadTime = tick() - startTime,
        reloadCount = loaded and loaded.reloadCount + 1 or 0,
        status = "loaded",
        error = nil,
    }
    
    self._modules[moduleName] = loadedModule
    self._loadingModules[moduleName] = nil
    
    -- Track performance
    self._moduleLoadTimes[moduleName] = loadedModule.loadTime
    self._totalLoadTime = self._totalLoadTime + loadedModule.loadTime
    
    if self._debugMode then
        print(string.format("[ModuleLoader] Loaded %s in %.3fs", moduleName, loadedModule.loadTime))
    end
    
    -- Fire loaded event
    if self._eventBus then
        self._eventBus:Fire("ModuleLoaded", {
            module = moduleName,
            loadTime = loadedModule.loadTime,
        })
    end
    
    return instance
end

function ModuleLoader:IsRequiredDependency(moduleName: string): boolean
    -- Core modules are always required
    local required = {
        "EventBus",
        "StateManager",
        "DataCache",
        "RemoteManager",
    }
    
    return self._utilities.TableContains(required, moduleName)
end

function ModuleLoader:LoadModules(moduleNames: {string})
    local loaded = {}
    
    for _, name in ipairs(moduleNames) do
        loaded[name] = self:LoadModule(name)
    end
    
    return loaded
end

function ModuleLoader:LoadAllModules()
    local order = self:GetLoadOrder()
    
    for _, moduleName in ipairs(order) do
        local definition = self._definitions[moduleName]
        if not definition.lazy then
            self:LoadModule(moduleName)
        end
    end
end

-- ========================================
-- LAZY LOADING
-- ========================================

function ModuleLoader:QueueLazyLoad(moduleName: string)
    if not self._lazyLoadingEnabled then
        self:LoadModule(moduleName)
        return
    end
    
    -- Check if already queued or loaded
    local loaded = self._modules[moduleName]
    if loaded and loaded.status == "loaded" then
        return
    end
    
    for _, queued in ipairs(self._loadQueue) do
        if queued == moduleName then
            return
        end
    end
    
    table.insert(self._loadQueue, moduleName)
end

function ModuleLoader:StartLazyLoadProcessor()
    task.spawn(function()
        while self._lazyLoadingEnabled do
            if #self._loadQueue > 0 then
                local moduleName = table.remove(self._loadQueue, 1)
                self:LoadModule(moduleName)
            end
            task.wait(LAZY_LOAD_DELAY)
        end
    end)
end

-- ========================================
-- HOT RELOAD
-- ========================================

function ModuleLoader:EnableHotReload(enabled: boolean)
    self._hotReloadEnabled = enabled
    
    if enabled then
        self:StartFileWatchers()
    else
        self:StopFileWatchers()
    end
end

function ModuleLoader:StartFileWatchers()
    if not Services.RunService:IsStudio() then
        return
    end
    
    -- Watch for module changes
    for moduleName, definition in pairs(self._definitions) do
        local module = definition.path
        
        self._fileWatchers[moduleName] = module.Changed:Connect(function(property)
            if property == "Source" then
                self:HandleModuleChange(moduleName)
            end
        end)
    end
end

function ModuleLoader:StopFileWatchers()
    for _, connection in pairs(self._fileWatchers) do
        connection:Disconnect()
    end
    self._fileWatchers = {}
end

function ModuleLoader:HandleModuleChange(moduleName: string)
    local lastReload = self._lastReloadTimes[moduleName] or 0
    local now = tick()
    
    if now - lastReload < HOT_RELOAD_COOLDOWN then
        return
    end
    
    self._lastReloadTimes[moduleName] = now
    
    if self._debugMode then
        print(string.format("[ModuleLoader] Hot reloading: %s", moduleName))
    end
    
    -- Find all dependent modules
    local toReload = {moduleName}
    local visited = {[moduleName] = true}
    
    local function addDependents(name)
        local dependents = self._reverseDependencies[name] or {}
        for _, dependent in ipairs(dependents) do
            if not visited[dependent] then
                visited[dependent] = true
                table.insert(toReload, dependent)
                addDependents(dependent)
            end
        end
    end
    
    addDependents(moduleName)
    
    -- Reload in reverse order (dependents first)
    for i = #toReload, 1, -1 do
        local name = toReload[i]
        local loaded = self._modules[name]
        
        if loaded and loaded.instance and type(loaded.instance.Destroy) == "function" then
            -- Clean up old instance
            pcall(loaded.instance.Destroy, loaded.instance)
        end
        
        -- Reload
        self:LoadModule(name, true)
    end
    
    -- Fire reload event
    if self._eventBus then
        self._eventBus:Fire("ModulesReloaded", toReload)
    end
end

function ModuleLoader:ReloadModule(moduleName: string): any
    return self:LoadModule(moduleName, true)
end

-- ========================================
-- MODULE ACCESS
-- ========================================

function ModuleLoader:GetModule(moduleName: string): any
    local loaded = self._modules[moduleName]
    
    if loaded and loaded.status == "loaded" then
        return loaded.instance
    elseif loaded and loaded.status == "error" then
        warn(string.format("[ModuleLoader] Module had error: %s", moduleName))
        return nil
    else
        -- Try to load if not loaded
        return self:LoadModule(moduleName)
    end
end

function ModuleLoader:GetModuleStatus(moduleName: string): Types.ModuleStatus
    local loaded = self._modules[moduleName]
    return loaded and loaded.status or "unloaded"
end

function ModuleLoader:GetLoadedModules(): {[string]: Types.ModuleInfo}
    local info = {}
    
    for name, loaded in pairs(self._modules) do
        info[name] = {
            name = name,
            status = loaded.status,
            dependencies = loaded.definition.dependencies,
            instance = loaded.instance,
            error = loaded.error,
            loadTime = loaded.loadTime,
        }
    end
    
    return info
end

function ModuleLoader:IsModuleLoaded(moduleName: string): boolean
    local loaded = self._modules[moduleName]
    return loaded and loaded.status == "loaded"
end

-- ========================================
-- UTILITIES
-- ========================================

function ModuleLoader:CountTable(tbl: table): number
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function ModuleLoader:GetPerformanceStats(): table
    return {
        totalModules = self:CountTable(self._definitions),
        loadedModules = self:CountTable(self._modules),
        totalLoadTime = self._totalLoadTime,
        averageLoadTime = self._totalLoadTime / math.max(1, self:CountTable(self._modules)),
        moduleLoadTimes = self._utilities.ShallowCopy(self._moduleLoadTimes),
    }
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function ModuleLoader:DebugPrint()
        print("\n=== ModuleLoader Debug Info ===")
        
        local stats = self:GetPerformanceStats()
        print("Total Modules:", stats.totalModules)
        print("Loaded Modules:", stats.loadedModules)
        print("Total Load Time:", string.format("%.3fs", stats.totalLoadTime))
        print("Average Load Time:", string.format("%.3fs", stats.averageLoadTime))
        
        print("\nLoad Order:")
        local order = self:GetLoadOrder()
        for i, name in ipairs(order) do
            local loaded = self._modules[name]
            local status = loaded and loaded.status or "unloaded"
            print(string.format("  %d. %s (%s)", i, name, status))
        end
        
        print("\nSlowest Modules:")
        local times = {}
        for name, time in pairs(stats.moduleLoadTimes) do
            table.insert(times, {name = name, time = time})
        end
        table.sort(times, function(a, b) return a.time > b.time end)
        
        for i = 1, math.min(5, #times) do
            print(string.format("  %s: %.3fs", times[i].name, times[i].time))
        end
        
        print("==============================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function ModuleLoader:Destroy()
    -- Stop watchers
    self:StopFileWatchers()
    
    -- Stop lazy loading
    self._lazyLoadingEnabled = false
    
    -- Destroy all loaded modules
    for name, loaded in pairs(self._modules) do
        if loaded.instance and type(loaded.instance.Destroy) == "function" then
            pcall(loaded.instance.Destroy, loaded.instance)
        end
    end
    
    -- Clear registries
    self._modules = {}
    self._definitions = {}
    self._loadQueue = {}
end

return ModuleLoader