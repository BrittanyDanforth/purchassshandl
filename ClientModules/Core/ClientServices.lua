--[[
    Module: ClientServices
    Description: Centralized Roblox service management with caching and error handling
    Provides safe access to all game services and player references
]]

local ClientServices = {}
ClientServices.__index = ClientServices

-- ========================================
-- SERVICE DEFINITIONS
-- ========================================

local SERVICE_NAMES = {
    -- Core Services
    "Players",
    "ReplicatedStorage",
    "ReplicatedFirst",
    "Workspace",
    "Lighting",
    "StarterGui",
    "StarterPlayer",
    "ServerStorage",     -- Client can't access but included for completeness
    "ServerScriptService", -- Client can't access but included for completeness
    
    -- Player Services
    "UserInputService",
    "ContextActionService",
    "GuiService",
    "VRService",
    "HapticService",
    
    -- Game Services
    "RunService",
    "TweenService",
    "PathfindingService",
    "PhysicsService",
    "CollectionService",
    "DataStoreService",  -- Client can't access but included for completeness
    "MemoryStoreService", -- Client can't access but included for completeness
    
    -- Content Services
    "ContentProvider",
    "AssetService",
    "InsertService",
    "HttpService",       -- Restricted on client
    "MarketplaceService",
    "BadgeService",
    "GamePassService",
    
    -- Social Services
    "SocialService",
    "Chat",
    "TextService",
    "LocalizationService",
    "TeleportService",
    "FriendService",
    "GroupService",
    
    -- Audio/Visual Services
    "SoundService",
    "Debris",
    "TweenService",
    
    -- Analytics Services
    "AnalyticsService",
    "PolicyService",
    "TestService",
    
    -- Other Services
    "Teams",
    "Stats",
    "StarterPack",
    "PointsService",
    "AdService",
    "NotificationService",
    "VoiceChatService",
    "TextChatService",
}

-- Services that require special handling
local RESTRICTED_SERVICES = {
    ServerStorage = true,
    ServerScriptService = true,
    DataStoreService = true,
    MemoryStoreService = true,
}

-- ========================================
-- SERVICE CACHE
-- ========================================

local serviceCache = {}
local serviceCacheMetatable = {
    __index = function(self, serviceName)
        local service = ClientServices:GetService(serviceName)
        if service then
            rawset(self, serviceName, service)
        end
        return service
    end
}
setmetatable(serviceCache, serviceCacheMetatable)

-- ========================================
-- INITIALIZATION
-- ========================================

function ClientServices.new()
    local self = setmetatable({}, ClientServices)
    
    -- Initialize properties
    self._initialized = false
    self._serviceCache = serviceCache
    self._playerReferences = {}
    self._connections = {}
    
    -- Don't initialize immediately to avoid circular dependency
    -- self:Initialize()
    
    return self
end

function ClientServices:Initialize()
    if self._initialized then
        return
    end
    
    -- Cache frequently used services
    self.Players = self:GetService("Players")
    self.ReplicatedStorage = self:GetService("ReplicatedStorage")
    self.UserInputService = self:GetService("UserInputService")
    self.TweenService = self:GetService("TweenService")
    self.RunService = self:GetService("RunService")
    self.HttpService = self:GetService("HttpService")
    self.SoundService = self:GetService("SoundService")
    self.GuiService = self:GetService("GuiService")
    self.ContentProvider = self:GetService("ContentProvider")
    self.MarketplaceService = self:GetService("MarketplaceService")
    self.TeleportService = self:GetService("TeleportService")
    self.BadgeService = self:GetService("BadgeService")
    self.Chat = self:GetService("Chat")
    self.LocalizationService = self:GetService("LocalizationService")
    self.ContextActionService = self:GetService("ContextActionService")
    self.HapticService = self:GetService("HapticService")
    self.VRService = self:GetService("VRService")
    self.TextService = self:GetService("TextService")
    self.Lighting = self:GetService("Lighting")
    self.StarterGui = self:GetService("StarterGui")
    self.Workspace = self:GetService("Workspace")
    
    -- Initialize player references
    self:InitializePlayerReferences()
    
    self._initialized = true
end

-- ========================================
-- SERVICE ACCESS
-- ========================================

function ClientServices:GetService(serviceName: string)
    -- Check cache first using rawget to avoid triggering __index
    local cached = rawget(serviceCache, serviceName)
    if cached then
        return cached
    end
    
    -- Check if restricted
    if RESTRICTED_SERVICES[serviceName] then
        warn("[ClientServices] Cannot access restricted service:", serviceName)
        return nil
    end
    
    -- Try to get service
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    
    if success and service then
        serviceCache[serviceName] = service
        return service
    else
        warn("[ClientServices] Failed to get service:", serviceName)
        return nil
    end
end

function ClientServices:Get(serviceName: string)
    return self:GetService(serviceName)
end

-- ========================================
-- PLAYER REFERENCES
-- ========================================

function ClientServices:InitializePlayerReferences()
    local Players = self.Players
    if not Players then
        warn("[ClientServices] Players service not available")
        return
    end
    
    -- Get local player
    self.LocalPlayer = Players.LocalPlayer
    if not self.LocalPlayer then
        warn("[ClientServices] LocalPlayer not available")
        return
    end
    
    -- Get PlayerGui
    self.PlayerGui = self.LocalPlayer:WaitForChild("PlayerGui", 10)
    if not self.PlayerGui then
        warn("[ClientServices] PlayerGui not available")
        return
    end
    
    -- Get/Wait for character
    local character = self.LocalPlayer.Character or self.LocalPlayer.CharacterAdded:Wait()
    self:SetupCharacter(character)
    
    -- Listen for character changes
    self._connections.CharacterAdded = self.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        self:SetupCharacter(newCharacter)
    end)
    
    self._connections.CharacterRemoving = self.LocalPlayer.CharacterRemoving:Connect(function()
        self.Character = nil
        self.Humanoid = nil
        self.HumanoidRootPart = nil
    end)
    
    -- Get mouse
    self.Mouse = self.LocalPlayer:GetMouse()
    
    -- Store player name for easy access
    self.PlayerName = self.LocalPlayer.Name
    self.PlayerUserId = self.LocalPlayer.UserId
    self.PlayerDisplayName = self.LocalPlayer.DisplayName
end

function ClientServices:SetupCharacter(character: Model)
    if not character then
        return
    end
    
    self.Character = character
    
    -- Wait for humanoid
    self.Humanoid = character:WaitForChild("Humanoid", 10)
    if not self.Humanoid then
        warn("[ClientServices] Humanoid not found in character")
        return
    end
    
    -- Wait for root part
    self.HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    if not self.HumanoidRootPart then
        warn("[ClientServices] HumanoidRootPart not found in character")
    end
    
    -- Fire character loaded event (other modules can listen)
    if self.CharacterLoaded then
        self.CharacterLoaded:Fire(character)
    end
end

function ClientServices:WaitForCharacter(timeout: number?): Model?
    timeout = timeout or 30
    
    if self.Character then
        return self.Character
    end
    
    local character = self.LocalPlayer.Character
    if character then
        self:SetupCharacter(character)
        return character
    end
    
    -- Wait for character to spawn
    local startTime = tick()
    local connection
    local result = nil
    
    connection = self.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        result = newCharacter
        connection:Disconnect()
    end)
    
    while not result and (tick() - startTime) < timeout do
        task.wait(0.1)
    end
    
    if connection then
        connection:Disconnect()
    end
    
    if result then
        self:SetupCharacter(result)
    end
    
    return result
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function ClientServices:IsStudio(): boolean
    return self.RunService:IsStudio()
end

function ClientServices:IsServer(): boolean
    return self.RunService:IsServer()
end

function ClientServices:IsClient(): boolean
    return self.RunService:IsClient()
end

function ClientServices:GetPlatform(): string
    if self.UserInputService.TouchEnabled then
        return "Mobile"
    elseif self.UserInputService.GamepadEnabled then
        return "Console"
    elseif self.UserInputService.KeyboardEnabled then
        return "PC"
    else
        return "Unknown"
    end
end

function ClientServices:IsVREnabled(): boolean
    return self.VRService.VREnabled
end

function ClientServices:GetCoreGuiEnabled(coreGuiType: Enum.CoreGuiType): boolean
    local success, enabled = pcall(function()
        return self.StarterGui:GetCoreGuiEnabled(coreGuiType)
    end)
    return success and enabled or false
end

function ClientServices:SetCoreGuiEnabled(coreGuiType: Enum.CoreGuiType, enabled: boolean)
    local success, err = pcall(function()
        self.StarterGui:SetCoreGuiEnabled(coreGuiType, enabled)
    end)
    
    if not success then
        warn("[ClientServices] Failed to set CoreGui:", err)
    end
end

function ClientServices:GetScreenSize(): Vector2
    local camera = self.Workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    else
        return Vector2.new(1920, 1080) -- Default fallback
    end
end

function ClientServices:GetCamera(): Camera?
    return self.Workspace.CurrentCamera
end

-- ========================================
-- SERVICE SHORTCUTS
-- ========================================

-- Common service property shortcuts
function ClientServices:GetPlayers(): {Player}
    return self.Players:GetPlayers()
end

function ClientServices:GetPing(): number
    return self.LocalPlayer:GetNetworkPing() or 0
end

function ClientServices:GetFPS(): number
    return math.floor(1 / self.RunService.RenderStepped:Wait())
end

function ClientServices:GetMemoryUsage(): number
    return collectgarbage("count") / 1024 -- MB
end

-- ========================================
-- CLEANUP
-- ========================================

function ClientServices:Destroy()
    -- Disconnect all connections
    for name, connection in pairs(self._connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    self._connections = {}
    self._initialized = false
end

-- ========================================
-- CREATE SINGLETON
-- ========================================

local instance = ClientServices.new()

-- Add event for character loaded
local Event = {}
Event.__index = Event

function Event.new()
    local self = setmetatable({}, Event)
    self._connections = {}
    return self
end

function Event:Connect(callback)
    local id = tostring(callback)
    self._connections[id] = callback
    
    return {
        Disconnect = function()
            self._connections[id] = nil
        end,
        Connected = true
    }
end

function Event:Fire(...)
    for _, callback in pairs(self._connections) do
        task.spawn(callback, ...)
    end
end

instance.CharacterLoaded = Event.new()

-- Initialize after creation to avoid circular dependency
task.spawn(function()
    task.wait()
    instance:Initialize()
end)

return instance