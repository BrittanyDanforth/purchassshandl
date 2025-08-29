--[[
    Debug Overlay System
    Shows real-time debugging information for UI and performance
]]

local DebugOverlay = {}
DebugOverlay.__index = DebugOverlay

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Stats = game:GetService("Stats"),
}

-- Constants
local TOGGLE_KEY = Enum.KeyCode.F9
local UPDATE_RATE = 0.5 -- seconds

function DebugOverlay.new(config)
    local self = setmetatable({}, DebugOverlay)
    
    self._config = config or {}
    self._enabled = false
    self._gui = nil
    self._labels = {}
    self._updateConnection = nil
    self._lastUpdate = 0
    
    -- UI State tracking
    self._uiState = {
        openModules = {},
        lastNavigation = "",
        errorCount = 0,
        warningCount = 0,
    }
    
    -- Performance metrics
    self._performance = {
        fps = 0,
        memory = 0,
        instances = 0,
        scripts = 0,
    }
    
    self:SetupKeybind()
    
    return self
end

function DebugOverlay:SetupKeybind()
    Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == TOGGLE_KEY then
            self:Toggle()
        end
    end)
end

function DebugOverlay:Toggle()
    self._enabled = not self._enabled
    
    if self._enabled then
        self:CreateOverlay()
        self:StartUpdating()
    else
        self:DestroyOverlay()
        self:StopUpdating()
    end
end

function DebugOverlay:CreateOverlay()
    -- Create ScreenGui
    self._gui = Instance.new("ScreenGui")
    self._gui.Name = "DebugOverlay"
    self._gui.DisplayOrder = 999
    self._gui.ResetOnSpawn = false
    self._gui.Parent = Services.Players.LocalPlayer.PlayerGui
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "DebugFrame"
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(1, -310, 0, 10)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = self._gui
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Debug Overlay (F9 to toggle)"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Create sections
    self:CreateSection(frame, "Performance", 40, {
        "FPS: 0",
        "Memory: 0 MB",
        "Instances: 0",
        "Scripts: 0",
    })
    
    self:CreateSection(frame, "UI State", 150, {
        "Current Module: None",
        "Open Modules: 0",
        "Last Navigation: None",
        "Errors: 0 | Warnings: 0",
    })
    
    self:CreateSection(frame, "Player Data", 260, {
        "Coins: 0",
        "Gems: 0",
        "Pets: 0",
        "Level: 0",
    })
end

function DebugOverlay:CreateSection(parent, name, yPos, labels)
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, -20, 0, 20)
    sectionTitle.Position = UDim2.new(0, 10, 0, yPos)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = name
    sectionTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.SourceSansBold
    sectionTitle.TextSize = 16
    sectionTitle.Parent = parent
    
    -- Labels
    self._labels[name] = {}
    for i, text in ipairs(labels) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 18)
        label.Position = UDim2.new(0, 10, 0, yPos + 20 + (i-1) * 20)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.Parent = parent
        
        table.insert(self._labels[name], label)
    end
end

function DebugOverlay:StartUpdating()
    self._updateConnection = Services.RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - self._lastUpdate < UPDATE_RATE then
            return
        end
        self._lastUpdate = now
        
        self:UpdatePerformance()
        self:UpdateUIState()
        self:UpdatePlayerData()
    end)
end

function DebugOverlay:StopUpdating()
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
end

function DebugOverlay:UpdatePerformance()
    local labels = self._labels["Performance"]
    if not labels then return end
    
    -- FPS
    self._performance.fps = math.floor(1 / Services.Stats.RenderStepped:GetValue())
    labels[1].Text = "FPS: " .. self._performance.fps
    
    -- Memory
    self._performance.memory = math.floor(Services.Stats:GetTotalMemoryUsageMb())
    labels[2].Text = "Memory: " .. self._performance.memory .. " MB"
    
    -- Instance count
    self._performance.instances = #game:GetDescendants()
    labels[3].Text = "Instances: " .. self._performance.instances
    
    -- Script count
    local scriptCount = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            scriptCount = scriptCount + 1
        end
    end
    self._performance.scripts = scriptCount
    labels[4].Text = "Scripts: " .. scriptCount
end

function DebugOverlay:UpdateUIState()
    local labels = self._labels["UI State"]
    if not labels then return end
    
    -- Get current module from MainUI
    local mainUI = _G.SanrioTycoonClient and _G.SanrioTycoonClient.MainUI
    if mainUI then
        labels[1].Text = "Current Module: " .. (mainUI._currentModule or "None")
        
        -- Count open modules
        local openCount = 0
        if mainUI._moduleStates then
            for _, state in pairs(mainUI._moduleStates) do
                if state.isOpen then
                    openCount = openCount + 1
                end
            end
        end
        labels[2].Text = "Open Modules: " .. openCount
    end
    
    labels[3].Text = "Last Navigation: " .. self._uiState.lastNavigation
    labels[4].Text = string.format("Errors: %d | Warnings: %d", 
        self._uiState.errorCount, 
        self._uiState.warningCount
    )
end

function DebugOverlay:UpdatePlayerData()
    local labels = self._labels["Player Data"]
    if not labels then return end
    
    -- Get data from cache
    local dataCache = _G.SanrioTycoonClient and _G.SanrioTycoonClient.DataCache
    if dataCache then
        local playerData = dataCache:Get("playerData") or {}
        local currencies = playerData.currencies or {}
        
        labels[1].Text = "Coins: " .. (currencies.coins or 0)
        labels[2].Text = "Gems: " .. (currencies.gems or 0)
        labels[3].Text = "Pets: " .. (playerData.petCount or 0)
        labels[4].Text = "Level: " .. (playerData.level or 0)
    end
end

function DebugOverlay:DestroyOverlay()
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
    end
    self._labels = {}
end

function DebugOverlay:TrackNavigation(moduleName)
    self._uiState.lastNavigation = moduleName .. " @ " .. os.date("%H:%M:%S")
end

function DebugOverlay:TrackError()
    self._uiState.errorCount = self._uiState.errorCount + 1
end

function DebugOverlay:TrackWarning()
    self._uiState.warningCount = self._uiState.warningCount + 1
end

return DebugOverlay