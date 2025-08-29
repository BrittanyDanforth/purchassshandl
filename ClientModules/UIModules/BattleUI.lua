--[[
    Module: BattleUI
    Description: Comprehensive battle interface with matchmaking, team selection,
                 battle arena display, move selection, health bars, and battle log
    Features: PvP matchmaking, team management, real-time battle display, 
              move animations, battle history
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local BattleUI = {}
BattleUI.__index = BattleUI

-- ========================================
-- TYPES
-- ========================================

type BattleState = {
    battleId: string,
    players: {Player},
    teams: {{petId: string, health: number, maxHealth: number}},
    currentTurn: number,
    turnTimer: number,
    battleLog: {string},
    status: "waiting" | "active" | "finished"
}

type BattleMove = {
    id: string,
    name: string,
    damage: number,
    type: string,
    cooldown: number,
    description: string
}

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(1000, 700)
local HEADER_HEIGHT = 60
local TEAM_DISPLAY_SIZE = Vector2.new(300, 150)
local MOVE_BUTTON_SIZE = Vector2.new(150, 60)
local HEALTH_BAR_HEIGHT = 20
local BATTLE_LOG_HEIGHT = 150
local TURN_TIMER = 30
local MATCHMAKING_TIMEOUT = 60

-- Battle colors
local BATTLE_COLORS = {
    playerHealth = Config.COLORS.Success,
    enemyHealth = Config.COLORS.Error,
    turnActive = Config.COLORS.Warning,
    turnInactive = Config.COLORS.TextSecondary
}

-- ========================================
-- INITIALIZATION
-- ========================================

function BattleUI.new(dependencies)
    local self = setmetatable({}, BattleUI)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    self._dataCache = dependencies.DataCache
    self._remoteManager = dependencies.RemoteManager
    self._soundSystem = dependencies.SoundSystem
    self._particleSystem = dependencies.ParticleSystem
    self._animationSystem = dependencies.AnimationSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._uiFactory = dependencies.UIFactory
    self._windowManager = dependencies.WindowManager
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self.TabFrames = {}
    self.BattleArena = nil
    self.CurrentBattle = nil
    self.MatchmakingOverlay = nil
    self.TeamSelectionUI = nil
    self.BattleControls = {}
    self.HealthBars = {}
    self.BattleLogFrame = nil
    self.TurnTimer = nil
    
    -- State
    self.SelectedTeam = {}
    self.BattleHistory = {}
    self.IsInBattle = false
    self.IsSearching = false
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function BattleUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Battle events
    self._eventBus:On("MatchmakingStarted", function()
        self:ShowMatchmakingUI()
    end)
    
    self._eventBus:On("MatchmakingFound", function(data)
        self:OnMatchFound(data)
    end)
    
    self._eventBus:On("BattleStarted", function(data)
        self:StartBattle(data)
    end)
    
    self._eventBus:On("BattleUpdate", function(data)
        self:UpdateBattle(data)
    end)
    
    self._eventBus:On("BattleEnded", function(data)
        self:EndBattle(data)
    end)
    
    self._eventBus:On("TurnStarted", function(data)
        self:OnTurnStart(data)
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function BattleUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshBattleStats()
        return
    end
    
    -- Create UI
    self:CreateUI()
end

function BattleUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
    
    -- Cancel matchmaking if active
    if self.IsSearching then
        self:CancelMatchmaking()
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function BattleUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                   (self._windowManager and self._windowManager.GetMainPanel and self._windowManager:GetMainPanel()) or 
                   Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[BattleUI] No parent container found")
        return
    end
    
    -- Create main frame
    self.Frame = self._uiFactory:CreateFrame(parent, {
        name = "BattleFrame",
        size = UDim2.new(1, -20, 1, -90),
        position = UDim2.new(0, 10, 0, 80),
        backgroundColor = self._config.COLORS.Background,
        visible = true
    })
    
    -- Create header
    self:CreateHeader()
    
    -- Create tabs
    self:CreateTabs()
end

function BattleUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "⚔️ Battle Arena ⚔️",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24
    })
end

function BattleUI:CreateTabs()
    local tabs = {
        {
            name = "PvP Arena",
            callback = function(frame) 
                self:CreatePvPView(frame) 
            end
        },
        {
            name = "Tournament",
            callback = function(frame)
                self:CreateTournamentView(frame)
            end
        },
        {
            name = "Battle History",
            callback = function(frame)
                self:CreateHistoryView(frame)
            end
        }
    }
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 1, -80)
    tabContainer.Position = UDim2.new(0, 10, 0, 70)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.Frame
    
    -- Tab buttons
    local tabButtonsFrame = Instance.new("Frame")
    tabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
    tabButtonsFrame.BackgroundTransparency = 1
    tabButtonsFrame.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabButtonsFrame
    
    -- Tab content
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -45)
    tabContent.Position = UDim2.new(0, 0, 0, 45)
    tabContent.BackgroundColor3 = self._config.COLORS.White
    tabContent.Parent = tabContainer
    
    self._utilities.CreateCorner(tabContent, 12)
    
    for i, tab in ipairs(tabs) do
        -- Tab button
        local tabButton = self._uiFactory:CreateButton(tabButtonsFrame, {
            text = tab.name,
            size = UDim2.new(0, 150, 1, 0),
            backgroundColor = i == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
            textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
            callback = function()
                -- Update button states
                for j, btn in ipairs(tabButtonsFrame:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = j == i and self._config.COLORS.Primary or self._config.COLORS.Surface
                        btn.TextColor3 = j == i and self._config.COLORS.White or self._config.COLORS.Dark
                    end
                end
                
                -- Show tab content
                for name, frame in pairs(self.TabFrames) do
                    frame.Visible = name == tab.name
                end
            end
        })
        
        -- Tab frame
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = tab.name .. "Tab"
        tabFrame.Size = UDim2.new(1, -20, 1, -20)
        tabFrame.Position = UDim2.new(0, 10, 0, 10)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = tabContent
        
        tab.callback(tabFrame)
        self.TabFrames[tab.name] = tabFrame
    end
end

-- ========================================
-- PVP VIEW
-- ========================================

function BattleUI:CreatePvPView(parent: Frame)
    -- Battle stats
    local statsFrame = self:CreateBattleStats(parent)
    
    -- Quick match button
    local quickMatchButton = self._uiFactory:CreateButton(parent, {
        text = "🎯 Quick Match",
        size = UDim2.new(0, 200, 0, 60),
        position = UDim2.new(0.5, -100, 0, 120),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            self:StartQuickMatch()
        end
    })
    
    -- Add glow effect
    if self._effectsLibrary then
        self._effectsLibrary:CreateGlowEffect(quickMatchButton, {
            color = self._config.COLORS.Success,
            size = 20
        })
    end
    
    -- Online players section
    local playersLabel = self._uiFactory:CreateLabel(parent, {
        text = "Online Players",
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0, 200),
        font = self._config.FONTS.Secondary,
        textXAlignment = Enum.TextXAlignment.Left
    })
    
    local playersFrame = Instance.new("Frame")
    playersFrame.Size = UDim2.new(1, -20, 1, -250)
    playersFrame.Position = UDim2.new(0, 10, 0, 240)
    playersFrame.BackgroundColor3 = self._config.COLORS.Surface
    playersFrame.Parent = parent
    
    self._utilities.CreateCorner(playersFrame, 12)
    
    local playerScroll = self._uiFactory:CreateScrollingFrame(playersFrame, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    self.PlayerListFrame = playerScroll
    
    -- Refresh players
    self:RefreshOnlinePlayers()
end

function BattleUI:CreateBattleStats(parent: Frame): Frame
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -20, 0, 100)
    statsFrame.Position = UDim2.new(0, 10, 0, 10)
    statsFrame.BackgroundColor3 = self._config.COLORS.White
    statsFrame.Parent = parent
    
    self._utilities.CreateCorner(statsFrame, 12)
    self._utilities.CreatePadding(statsFrame, 15)
    
    -- Stats grid
    local statsGrid = Instance.new("UIGridLayout")
    statsGrid.CellPadding = UDim2.new(0, 20, 0, 10)
    statsGrid.CellSize = UDim2.new(0.25, -15, 0.5, -5)
    statsGrid.FillDirection = Enum.FillDirection.Horizontal
    statsGrid.Parent = statsFrame
    
    local stats = {
        {label = "Wins", value = 0, color = self._config.COLORS.Success},
        {label = "Losses", value = 0, color = self._config.COLORS.Error},
        {label = "Win Rate", value = "0%", color = self._config.COLORS.Primary},
        {label = "Rank", value = "Unranked", color = self._config.COLORS.Warning}
    }
    
    for _, stat in ipairs(stats) do
        local statFrame = Instance.new("Frame")
        statFrame.BackgroundTransparency = 1
        statFrame.Parent = statsFrame
        
        local valueLabel = self._uiFactory:CreateLabel(statFrame, {
            text = tostring(stat.value),
            size = UDim2.new(1, 0, 0.6, 0),
            font = self._config.FONTS.Display,
            textColor = stat.color,
            textSize = 24
        })
        
        local nameLabel = self._uiFactory:CreateLabel(statFrame, {
            text = stat.label,
            size = UDim2.new(1, 0, 0.4, 0),
            position = UDim2.new(0, 0, 0.6, 0),
            textColor = self._config.COLORS.TextSecondary,
            textSize = 14
        })
    end
    
    return statsFrame
end

function BattleUI:RefreshOnlinePlayers()
    if not self.PlayerListFrame then return end
    
    -- Clear existing
    for _, child in ipairs(self.PlayerListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add online players
    local yOffset = 0
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Services.Players.LocalPlayer then
            self:CreatePlayerCard(player, yOffset)
            yOffset = yOffset + 75
        end
    end
    
    -- Update canvas size
    self.PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
end

function BattleUI:CreatePlayerCard(player: Player, yPos: number)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 70)
    card.Position = UDim2.new(0, 5, 0, yPos)
    card.BackgroundColor3 = self._config.COLORS.White
    card.Parent = self.PlayerListFrame
    
    self._utilities.CreateCorner(card, 8)
    self._utilities.CreatePadding(card, 10)
    
    -- Player avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 0, 0.5, -25)
    avatar.BackgroundColor3 = self._config.COLORS.Background
    avatar.Image = Services.Players:GetUserThumbnailAsync(
        player.UserId, 
        Enum.ThumbnailType.HeadShot, 
        Enum.ThumbnailSize.Size100x100
    )
    avatar.Parent = card
    
    self._utilities.CreateCorner(avatar, 25)
    
    -- Player info
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = player.DisplayName,
        size = UDim2.new(0.4, -70, 0, 25),
        position = UDim2.new(0, 60, 0, 5),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary
    })
    
    -- Battle rating
    local ratingLabel = self._uiFactory:CreateLabel(card, {
        text = "Rating: 1000",
        size = UDim2.new(0.4, -70, 0, 20),
        position = UDim2.new(0, 60, 0, 30),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textSize = 14
    })
    
    -- Battle button
    local battleButton = self._uiFactory:CreateButton(card, {
        text = "Challenge",
        size = UDim2.new(0, 100, 0, 35),
        position = UDim2.new(1, -105, 0.5, -17.5),
        backgroundColor = self._config.COLORS.Primary,
        callback = function()
            self:ChallengePlayer(player)
        end
    })
    
    return card
end

-- ========================================
-- MATCHMAKING
-- ========================================

function BattleUI:StartQuickMatch()
    if self.IsSearching then return end
    
    -- Request matchmaking
    if self._remoteManager then
        local success, result = self._remoteManager:InvokeServer("JoinBattleMatchmaking")
        
        if success then
            self.IsSearching = true
            self:ShowMatchmakingUI()
            
            -- Play sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("Search")
            end
        else
            self._notificationSystem:SendNotification("Error", 
                result or "Failed to join matchmaking", "error")
        end
    end
end

function BattleUI:ShowMatchmakingUI()
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "MatchmakingOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 500
    overlay.Parent = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    self.MatchmakingOverlay = overlay
    
    -- Search window
    local searchWindow = Instance.new("Frame")
    searchWindow.Size = UDim2.new(0, 400, 0, 200)
    searchWindow.Position = UDim2.new(0.5, -200, 0.5, -100)
    searchWindow.BackgroundColor3 = self._config.COLORS.Background
    searchWindow.ZIndex = 501
    searchWindow.Parent = overlay
    
    self._utilities.CreateCorner(searchWindow, 20)
    
    -- Spinner
    local spinner = Instance.new("ImageLabel")
    spinner.Size = UDim2.new(0, 60, 0, 60)
    spinner.Position = UDim2.new(0.5, -30, 0.3, -30)
    spinner.BackgroundTransparency = 1
    spinner.Image = "rbxassetid://4965362309" -- Loading spinner
    spinner.ZIndex = 502
    spinner.Parent = searchWindow
    
    -- Animate spinner
    local spinTween = Services.TweenService:Create(spinner, 
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
        {Rotation = 360}
    )
    spinTween:Play()
    
    -- Status label
    local statusLabel = self._uiFactory:CreateLabel(searchWindow, {
        text = "Searching for opponent...",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0.6, 0),
        font = self._config.FONTS.Secondary,
        zIndex = 502
    })
    
    -- Timer
    local timerLabel = self._uiFactory:CreateLabel(searchWindow, {
        text = "0:00",
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0.75, 0),
        textColor = self._config.COLORS.TextSecondary,
        textSize = 16,
        zIndex = 502
    })
    
    -- Cancel button
    local cancelButton = self._uiFactory:CreateButton(searchWindow, {
        text = "Cancel",
        size = UDim2.new(0, 100, 0, 35),
        position = UDim2.new(0.5, -50, 1, -45),
        backgroundColor = self._config.COLORS.Secondary,
        zIndex = 502,
        callback = function()
            self:CancelMatchmaking()
        end
    })
    
    -- Start timer
    self:StartMatchmakingTimer(timerLabel)
end

function BattleUI:StartMatchmakingTimer(label: TextLabel)
    local startTime = tick()
    
    spawn(function()
        while self.IsSearching and self.MatchmakingOverlay do
            local elapsed = tick() - startTime
            local minutes = math.floor(elapsed / 60)
            local seconds = math.floor(elapsed % 60)
            label.Text = string.format("%d:%02d", minutes, seconds)
            
            -- Timeout check
            if elapsed > MATCHMAKING_TIMEOUT then
                self:CancelMatchmaking()
                self._notificationSystem:SendNotification("Timeout", 
                    "Matchmaking timed out. Please try again.", "error")
                break
            end
            
            task.wait(1)
        end
    end)
end

function BattleUI:CancelMatchmaking()
    self.IsSearching = false
    
    -- Send cancel request
    if self._remoteManager then
        self._remoteManager:Fire("CancelMatchmaking")
    end
    
    -- Close overlay
    if self.MatchmakingOverlay then
        self.MatchmakingOverlay:Destroy()
        self.MatchmakingOverlay = nil
    end
end

function BattleUI:OnMatchFound(data: {opponent: Player, battleId: string})
    self.IsSearching = false
    
    -- Close matchmaking UI
    if self.MatchmakingOverlay then
        self.MatchmakingOverlay:Destroy()
        self.MatchmakingOverlay = nil
    end
    
    -- Show notification
    self._notificationSystem:SendNotification("Match Found!", 
        "Battle starting against " .. data.opponent.DisplayName, "success")
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("MatchFound")
    end
    
    -- Open team selection
    self:OpenTeamSelection(data)
end

-- ========================================
-- TEAM SELECTION
-- ========================================

function BattleUI:OpenTeamSelection(battleData: table)
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "TeamSelectionOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 400
    overlay.Parent = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    self.TeamSelectionUI = overlay
    
    -- Selection window
    local window = Instance.new("Frame")
    window.Size = UDim2.new(0, 800, 0, 600)
    window.Position = UDim2.new(0.5, -400, 0.5, -300)
    window.BackgroundColor3 = self._config.COLORS.Background
    window.ZIndex = 401
    window.Parent = overlay
    
    self._utilities.CreateCorner(window, 20)
    
    -- Header
    local header = self._uiFactory:CreateFrame(window, {
        size = UDim2.new(1, 0, 0, 60),
        backgroundColor = self._config.COLORS.Primary,
        zIndex = 402
    })
    
    local titleLabel = self._uiFactory:CreateLabel(header, {
        text = "Select Your Battle Team",
        size = UDim2.new(1, 0, 1, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 20,
        zIndex = 403
    })
    
    -- Pet selection area
    local selectionArea = Instance.new("Frame")
    selectionArea.Size = UDim2.new(1, -20, 0.6, -80)
    selectionArea.Position = UDim2.new(0, 10, 0, 70)
    selectionArea.BackgroundColor3 = self._config.COLORS.Surface
    selectionArea.ZIndex = 402
    selectionArea.Parent = window
    
    self._utilities.CreateCorner(selectionArea, 12)
    
    local petScroll = self._uiFactory:CreateScrollingFrame(selectionArea, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    -- Team display
    local teamDisplay = self:CreateTeamDisplay(window)
    
    -- Load pets
    self:LoadPetsForBattle(petScroll)
    
    -- Start button
    local startButton = self._uiFactory:CreateButton(window, {
        text = "Start Battle",
        size = UDim2.new(0, 200, 0, 50),
        position = UDim2.new(0.5, -100, 1, -60),
        backgroundColor = self._config.COLORS.Success,
        zIndex = 403,
        callback = function()
            if #self.SelectedTeam >= 3 then
                self:ConfirmTeamSelection(battleData)
            else
                self._notificationSystem:SendNotification("Error", 
                    "Select at least 3 pets for battle", "error")
            end
        end
    })
end

function BattleUI:CreateTeamDisplay(parent: Frame): Frame
    local teamFrame = Instance.new("Frame")
    teamFrame.Size = UDim2.new(1, -20, 0.25, 0)
    teamFrame.Position = UDim2.new(0, 10, 0.65, 0)
    teamFrame.BackgroundColor3 = self._config.COLORS.White
    teamFrame.ZIndex = 402
    teamFrame.Parent = parent
    
    self._utilities.CreateCorner(teamFrame, 12)
    
    local teamLabel = self._uiFactory:CreateLabel(teamFrame, {
        text = "Selected Team (0/6)",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 10, 0, 5),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        zIndex = 403
    })
    
    self.TeamCountLabel = teamLabel
    
    -- Team slots
    local slotsFrame = Instance.new("Frame")
    slotsFrame.Size = UDim2.new(1, -20, 1, -40)
    slotsFrame.Position = UDim2.new(0, 10, 0, 35)
    slotsFrame.BackgroundTransparency = 1
    slotsFrame.ZIndex = 403
    slotsFrame.Parent = teamFrame
    
    local slotLayout = Instance.new("UIListLayout")
    slotLayout.FillDirection = Enum.FillDirection.Horizontal
    slotLayout.Padding = UDim.new(0, 10)
    slotLayout.Parent = slotsFrame
    
    self.TeamSlotsFrame = slotsFrame
    
    -- Create empty slots
    for i = 1, 6 do
        local slot = self:CreateTeamSlot(i)
        slot.Parent = slotsFrame
    end
    
    return teamFrame
end

function BattleUI:CreateTeamSlot(index: number): Frame
    local slot = Instance.new("Frame")
    slot.Name = "TeamSlot" .. index
    slot.Size = UDim2.new(0, 80, 1, 0)
    slot.BackgroundColor3 = self._config.COLORS.Background
    slot.BorderSizePixel = 0
    
    self._utilities.CreateCorner(slot, 8)
    self._utilities.CreateStroke(slot, self._config.COLORS.TextSecondary, 2)
    
    local slotLabel = self._uiFactory:CreateLabel(slot, {
        text = tostring(index),
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.TextSecondary,
        textSize = 20
    })
    
    return slot
end

function BattleUI:LoadPetsForBattle(parent: ScrollingFrame)
    local playerData = self._dataCache and self._dataCache:Get() or {}
    if not playerData.pets then return end
    
    local pets = {}
    
    -- Get battle-ready pets (level 10+)
    for uniqueId, pet in pairs(playerData.pets) do
        if type(pet) == "table" and pet.level >= 10 and not pet.locked then
            pet.uniqueId = uniqueId
            table.insert(pets, pet)
        end
    end
    
    -- Sort by power
    table.sort(pets, function(a, b)
        return (a.power or 0) > (b.power or 0)
    end)
    
    -- Create grid
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.Parent = parent
    
    -- Create pet cards
    for _, pet in ipairs(pets) do
        local petData = self._dataCache and self._dataCache:Get("petDatabase." .. pet.petId) or
                       {displayName = "Unknown", rarity = 1}
        
        self:CreateBattlePetCard(parent, pet, petData)
    end
    
    -- Update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        parent.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function BattleUI:CreateBattlePetCard(parent: ScrollingFrame, petInstance: table, petData: table): Frame
    local card = Instance.new("Frame")
    card.Name = petInstance.uniqueId
    card.BackgroundColor3 = self._config.COLORS.Surface
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 8)
    
    -- Selection indicator
    local selectionBorder = Instance.new("Frame")
    selectionBorder.Name = "SelectionBorder"
    selectionBorder.Size = UDim2.new(1, 0, 1, 0)
    selectionBorder.BackgroundTransparency = 1
    selectionBorder.Visible = false
    selectionBorder.Parent = card
    
    self._utilities.CreateStroke(selectionBorder, self._config.COLORS.Success, 3)
    self._utilities.CreateCorner(selectionBorder, 8)
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, -10, 1, -50)
    petImage.Position = UDim2.new(0, 5, 0, 5)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = card
    
    -- Pet info
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -4, 0, 40)
    infoFrame.Position = UDim2.new(0, 2, 1, -42)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = card
    
    -- Name
    local nameLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = petInstance.nickname or petData.displayName or "Unknown",
        size = UDim2.new(1, 0, 0, 20),
        textScaled = true,
        textSize = 12
    })
    
    -- Power display
    local powerLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = "⚔️ " .. tostring(petInstance.power or 0),
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 20),
        textColor = self._config.COLORS.Error,
        textSize = 14
    })
    
    -- Level badge
    local levelBadge = Instance.new("Frame")
    levelBadge.Size = UDim2.new(0, 30, 0, 20)
    levelBadge.Position = UDim2.new(0, 2, 0, 2)
    levelBadge.BackgroundColor3 = self._config.COLORS.Dark
    levelBadge.Parent = card
    
    self._utilities.CreateCorner(levelBadge, 4)
    
    local levelLabel = self._uiFactory:CreateLabel(levelBadge, {
        text = "Lv." .. tostring(petInstance.level or 1),
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        textSize = 10
    })
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        self:TogglePetSelection(petInstance, petData, card)
    end)
    
    return card
end

function BattleUI:TogglePetSelection(petInstance: table, petData: table, card: Frame)
    local uniqueId = petInstance.uniqueId
    
    if self.SelectedTeam[uniqueId] then
        -- Remove from team
        self.SelectedTeam[uniqueId] = nil
        card:FindFirstChild("SelectionBorder").Visible = false
    else
        -- Check team size
        local teamSize = 0
        for _ in pairs(self.SelectedTeam) do
            teamSize = teamSize + 1
        end
        
        if teamSize >= 6 then
            self._notificationSystem:SendNotification("Team Full", 
                "Maximum 6 pets per team", "error")
            return
        end
        
        -- Add to team
        self.SelectedTeam[uniqueId] = {
            instance = petInstance,
            data = petData
        }
        card:FindFirstChild("SelectionBorder").Visible = true
    end
    
    -- Update team display
    self:UpdateTeamDisplay()
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
end

function BattleUI:UpdateTeamDisplay()
    -- Update count
    local count = 0
    for _ in pairs(self.SelectedTeam) do
        count = count + 1
    end
    
    if self.TeamCountLabel then
        self.TeamCountLabel.Text = string.format("Selected Team (%d/6)", count)
    end
    
    -- Update slots
    if self.TeamSlotsFrame then
        -- Clear slots
        for i = 1, 6 do
            local slot = self.TeamSlotsFrame:FindFirstChild("TeamSlot" .. i)
            if slot then
                for _, child in ipairs(slot:GetChildren()) do
                    if child:IsA("ImageLabel") then
                        child:Destroy()
                    end
                end
                
                -- Reset appearance
                local label = slot:FindFirstChildOfClass("TextLabel")
                if label then
                    label.Visible = true
                end
            end
        end
        
        -- Fill slots
        local slotIndex = 1
        for uniqueId, teamPet in pairs(self.SelectedTeam) do
            local slot = self.TeamSlotsFrame:FindFirstChild("TeamSlot" .. slotIndex)
            if slot then
                -- Hide number
                local label = slot:FindFirstChildOfClass("TextLabel")
                if label then
                    label.Visible = false
                end
                
                -- Add pet image
                local petImage = Instance.new("ImageLabel")
                petImage.Size = UDim2.new(1, -10, 1, -10)
                petImage.Position = UDim2.new(0, 5, 0, 5)
                petImage.BackgroundTransparency = 1
                petImage.Image = teamPet.data.imageId or ""
                petImage.ScaleType = Enum.ScaleType.Fit
                petImage.Parent = slot
            end
            
            slotIndex = slotIndex + 1
            if slotIndex > 6 then break end
        end
    end
end

function BattleUI:ConfirmTeamSelection(battleData: table)
    -- Convert selected team to array
    local team = {}
    for uniqueId, teamPet in pairs(self.SelectedTeam) do
        table.insert(team, uniqueId)
    end
    
    -- Send team selection
    if self._remoteManager then
        self._remoteManager:FireServer("SelectBattleTeam", {
            battleId = battleData.battleId,
            team = team
        })
    end
    
    -- Close selection UI
    if self.TeamSelectionUI then
        self.TeamSelectionUI:Destroy()
        self.TeamSelectionUI = nil
    end
    
    -- Reset selection
    self.SelectedTeam = {}
    
    -- Show loading
    self._notificationSystem:SendNotification("Battle Starting", 
        "Waiting for opponent...", "info")
end

-- ========================================
-- BATTLE ARENA
-- ========================================

function BattleUI:StartBattle(battleState: BattleState)
    self.CurrentBattle = battleState
    self.IsInBattle = true
    
    -- Create epic battle entrance
    self:CreateEpicBattleEntrance(function()
        -- Create battle arena after entrance
        self:CreateBattleArena()
        
        -- Play battle music
        if self._soundSystem then
            self._soundSystem:PlayMusic("Battle")
        end
    end)
end

function BattleUI:CreateEpicBattleEntrance(callback: () -> ())
    local playerGui = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    -- Create screen darkening overlay
    local darkOverlay = Instance.new("Frame")
    darkOverlay.Name = "BattleDarkOverlay"
    darkOverlay.Size = UDim2.new(1, 0, 1, 0)
    darkOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    darkOverlay.BackgroundTransparency = 1
    darkOverlay.ZIndex = 450
    darkOverlay.Parent = playerGui
    
    -- Fade to dark
    self._utilities.Tween(darkOverlay, {
        BackgroundTransparency = 0.5
    }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Create VS splash
    local vsContainer = Instance.new("Frame")
    vsContainer.Size = UDim2.new(0, 600, 0, 200)
    vsContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    vsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    vsContainer.BackgroundTransparency = 1
    vsContainer.ZIndex = 451
    vsContainer.Parent = darkOverlay
    
    -- VS Text with dramatic entrance
    local vsText = Instance.new("TextLabel")
    vsText.Size = UDim2.new(1, 0, 1, 0)
    vsText.BackgroundTransparency = 1
    vsText.Text = "BATTLE!"
    vsText.Font = Enum.Font.Fantasy
    vsText.TextScaled = true
    vsText.TextColor3 = self._config.COLORS.Error
    vsText.TextStrokeColor3 = Color3.new(0, 0, 0)
    vsText.TextStrokeTransparency = 0
    vsText.TextTransparency = 1
    vsText.ZIndex = 452
    vsText.Parent = vsContainer
    
    -- Start small and grow
    vsContainer.Size = UDim2.new(0, 0, 0, 0)
    
    -- Dramatic entrance animation
    self._utilities.Tween(vsContainer, {
        Size = UDim2.new(0, 600, 0, 200)
    }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    self._utilities.Tween(vsText, {
        TextTransparency = 0
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
    
    -- Add shake effect
    task.spawn(function()
        task.wait(0.4)
        local originalPos = vsContainer.Position
        for i = 1, 10 do
            vsContainer.Position = UDim2.new(
                originalPos.X.Scale, 
                originalPos.X.Offset + math.random(-5, 5),
                originalPos.Y.Scale,
                originalPos.Y.Offset + math.random(-5, 5)
            )
            task.wait(0.03)
        end
        vsContainer.Position = originalPos
    end)
    
    -- Sound effects
    if self._soundSystem then
        self._soundSystem:PlayUISound("BattleStart")
    end
    
    -- Wait then fade out
    task.wait(1.2)
    
    self._utilities.Tween(vsText, {
        TextTransparency = 1
    }, TweenInfo.new(0.3))
    
    self._utilities.Tween(vsContainer, {
        Size = UDim2.new(0, 800, 0, 0)
    }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In))
    
    task.wait(0.3)
    darkOverlay:Destroy()
    
    if callback then
        callback()
    end
end

function BattleUI:CreateBattleArena()
    -- Create overlay with entrance animation
    local overlay = Instance.new("Frame")
    overlay.Name = "BattleArena"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 1, 0) -- Start from bottom
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.2
    overlay.ZIndex = 500
    overlay.Parent = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    self.BattleArena = overlay
    
    -- Slide up animation
    self._utilities.Tween(overlay, {
        Position = UDim2.new(0, 0, 0, 0)
    }, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    
    -- Battle container
    local battleContainer = Instance.new("Frame")
    battleContainer.Size = UDim2.new(1, 0, 1, 0)
    battleContainer.BackgroundTransparency = 1
    battleContainer.ZIndex = 501
    battleContainer.Parent = overlay
    
    -- Create battle UI elements with staggered animations
    task.spawn(function()
        task.wait(0.3)
        self:CreateBattleHeader(battleContainer)
        
        task.wait(0.1)
        self:CreateBattleField(battleContainer)
        
        task.wait(0.1)
        self:CreateBattleControls(battleContainer)
        
        task.wait(0.1)
        self:CreateBattleLog(battleContainer)
        
        -- Initialize battle display
        self:UpdateBattleDisplay()
        
        -- Animate pet cards flying in
        self:AnimatePetCardsEntrance()
    end)
end

function BattleUI:AnimatePetCardsEntrance()
    -- Animate player pets
    if self.PlayerPetFrames then
        for i, frame in ipairs(self.PlayerPetFrames) do
            if frame then
                local originalPos = frame.Position
                frame.Position = UDim2.new(-0.5, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
                
                task.spawn(function()
                    task.wait((i - 1) * 0.1)
                    self._utilities.Tween(frame, {
                        Position = originalPos
                    }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
                    
                    -- Add particle effect
                    self:CreatePetEntranceParticles(frame)
                end)
            end
        end
    end
    
    -- Animate opponent pets
    if self.OpponentPetFrames then
        for i, frame in ipairs(self.OpponentPetFrames) do
            if frame then
                local originalPos = frame.Position
                frame.Position = UDim2.new(1.5, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
                
                task.spawn(function()
                    task.wait((i - 1) * 0.1)
                    self._utilities.Tween(frame, {
                        Position = originalPos
                    }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
                    
                    -- Add particle effect
                    self:CreatePetEntranceParticles(frame)
                end)
            end
        end
    end
end

function BattleUI:CreatePetEntranceParticles(petFrame: Frame)
    for i = 1, 10 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
        particle.Position = UDim2.new(0.5, 0, 0.5, 0)
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.BackgroundColor3 = self._config.COLORS.Primary
        particle.BorderSizePixel = 0
        particle.ZIndex = petFrame.ZIndex - 1
        particle.Parent = petFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = particle
        
        -- Animate outward
        local angle = math.random() * math.pi * 2
        local distance = math.random(30, 60)
        
        self._utilities.Tween(particle, {
            Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        game:GetService("Debris"):AddItem(particle, 0.6)
    end
end

function BattleUI:CreateBattleHeader(parent: Frame)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = self._config.COLORS.Dark
    header.BackgroundTransparency = 0.2
    header.ZIndex = 502
    header.Parent = parent
    
    -- Player info (left)
    local playerInfo = self:CreateBattlerInfo(header, 
        Services.Players.LocalPlayer,
        UDim2.new(0, 300, 1, 0),
        UDim2.new(0, 20, 0, 0),
        true
    )
    
    -- VS label
    local vsLabel = self._uiFactory:CreateLabel(header, {
        text = "VS",
        size = UDim2.new(0, 100, 1, 0),
        position = UDim2.new(0.5, -50, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 32,
        zIndex = 503
    })
    
    -- Opponent info (right)
    local opponent = self.CurrentBattle.players[2]
    local opponentInfo = self:CreateBattlerInfo(header,
        opponent,
        UDim2.new(0, 300, 1, 0),
        UDim2.new(1, -320, 0, 0),
        false
    )
    
    -- Turn timer
    local timerFrame = Instance.new("Frame")
    timerFrame.Size = UDim2.new(0, 200, 0, 40)
    timerFrame.Position = UDim2.new(0.5, -100, 0.5, -20)
    timerFrame.BackgroundColor3 = self._config.COLORS.Dark
    timerFrame.ZIndex = 503
    timerFrame.Parent = header
    
    self._utilities.CreateCorner(timerFrame, 20)
    
    local timerLabel = self._uiFactory:CreateLabel(timerFrame, {
        text = "30",
        size = UDim2.new(1, 0, 1, 0),
        font = self._config.FONTS.Numbers,
        textColor = self._config.COLORS.White,
        textSize = 24,
        zIndex = 504
    })
    
    self.TurnTimerLabel = timerLabel
    
    -- Turn indicator label
    local turnIndicator = self._uiFactory:CreateLabel(header, {
        text = "YOUR TURN",
        size = UDim2.new(0, 200, 0, 30),
        position = UDim2.new(0.5, -100, 1, -35),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.Success,
        textSize = 18,
        zIndex = 504
    })
    
    self.TurnIndicatorLabel = turnIndicator
    
    -- Add glow effect to turn indicator
    local indicatorGlow = Instance.new("Frame")
    indicatorGlow.Size = UDim2.new(1, 10, 1, 10)
    indicatorGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    indicatorGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    indicatorGlow.BackgroundTransparency = 1
    indicatorGlow.ZIndex = turnIndicator.ZIndex - 1
    indicatorGlow.Parent = turnIndicator
    
    local indicatorStroke = Instance.new("UIStroke")
    indicatorStroke.Color = self._config.COLORS.Success
    indicatorStroke.Thickness = 2
    indicatorStroke.Transparency = 0.5
    indicatorStroke.Parent = indicatorGlow
    
    -- Animate indicator glow
    task.spawn(function()
        while indicatorGlow.Parent do
            self._utilities.Tween(indicatorStroke, {
                Transparency = 0.2
            }, TweenInfo.new(1, Enum.EasingStyle.Sine))
            task.wait(1)
            self._utilities.Tween(indicatorStroke, {
                Transparency = 0.5
            }, TweenInfo.new(1, Enum.EasingStyle.Sine))
            task.wait(1)
        end
    end)
end

function BattleUI:CreateBattlerInfo(parent: Frame, player: Player, size: UDim2, position: UDim2, isPlayer: boolean): Frame
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = size
    infoFrame.Position = position
    infoFrame.BackgroundTransparency = 1
    infoFrame.ZIndex = 503
    infoFrame.Parent = parent
    
    -- Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 60, 0, 60)
    avatar.Position = isPlayer and UDim2.new(0, 10, 0.5, -30) or UDim2.new(1, -70, 0.5, -30)
    avatar.BackgroundColor3 = self._config.COLORS.White
    avatar.Image = Services.Players:GetUserThumbnailAsync(
        player.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size100x100
    )
    avatar.ZIndex = 504
    avatar.Parent = infoFrame
    
    self._utilities.CreateCorner(avatar, 30)
    
    -- Name
    local nameLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = player.DisplayName,
        size = UDim2.new(1, -80, 0, 30),
        position = isPlayer and UDim2.new(0, 80, 0, 10) or UDim2.new(0, 10, 0, 10),
        textXAlignment = isPlayer and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        zIndex = 504
    })
    
    -- Team health bar
    local healthBar = self:CreateTeamHealthBar(infoFrame, isPlayer)
    
    return infoFrame
end

function BattleUI:CreateTeamHealthBar(parent: Frame, isPlayer: boolean): Frame
    local barFrame = Instance.new("Frame")
    barFrame.Size = UDim2.new(1, -90, 0, 20)
    barFrame.Position = isPlayer and UDim2.new(0, 80, 0, 45) or UDim2.new(0, 10, 0, 45)
    barFrame.BackgroundColor3 = self._config.COLORS.Dark
    barFrame.ZIndex = 504
    barFrame.Parent = parent
    
    self._utilities.CreateCorner(barFrame, 10)
    
    local fill = Instance.new("Frame")
    fill.Name = "HealthFill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = isPlayer and BATTLE_COLORS.playerHealth or BATTLE_COLORS.enemyHealth
    fill.ZIndex = 505
    fill.Parent = barFrame
    
    self._utilities.CreateCorner(fill, 10)
    
    local healthLabel = self._uiFactory:CreateLabel(barFrame, {
        text = "100%",
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Numbers,
        textSize = 14,
        zIndex = 506
    })
    
    -- Store reference
    if isPlayer then
        self.HealthBars.Player = {bar = barFrame, fill = fill, label = healthLabel}
    else
        self.HealthBars.Opponent = {bar = barFrame, fill = fill, label = healthLabel}
    end
    
    return barFrame
end

function BattleUI:CreateBattleField(parent: Frame)
    local field = Instance.new("Frame")
    field.Size = UDim2.new(1, -40, 1, -320)
    field.Position = UDim2.new(0, 20, 0, 100)
    field.BackgroundTransparency = 1
    field.ZIndex = 502
    field.Parent = parent
    
    -- Player side
    local playerSide = Instance.new("Frame")
    playerSide.Size = UDim2.new(0.5, -10, 1, 0)
    playerSide.Position = UDim2.new(0, 0, 0, 0)
    playerSide.BackgroundTransparency = 1
    playerSide.ZIndex = 503
    playerSide.Parent = field
    
    -- Opponent side
    local opponentSide = Instance.new("Frame")
    opponentSide.Size = UDim2.new(0.5, -10, 1, 0)
    opponentSide.Position = UDim2.new(0.5, 10, 0, 0)
    opponentSide.BackgroundTransparency = 1
    opponentSide.ZIndex = 503
    opponentSide.Parent = field
    
    -- Create pet displays
    self:CreatePetDisplays(playerSide, true)
    self:CreatePetDisplays(opponentSide, false)
end

function BattleUI:CreatePetDisplays(parent: Frame, isPlayer: boolean)
    -- Active pet display
    local activePet = Instance.new("Frame")
    activePet.Name = "ActivePet"
    activePet.Size = UDim2.new(0, 200, 0, 200)
    activePet.Position = UDim2.new(0.5, -100, 0.3, -100)
    activePet.BackgroundTransparency = 1
    activePet.ZIndex = 504
    activePet.Parent = parent
    
    -- Pet image placeholder
    local petImage = Instance.new("ImageLabel")
    petImage.Name = "PetImage"
    petImage.Size = UDim2.new(1, 0, 1, 0)
    petImage.BackgroundTransparency = 1
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.ZIndex = 505
    petImage.Parent = activePet
    
    -- Health bar
    local healthBar = self:CreatePetHealthBar(activePet)
    
    -- Bench pets
    local benchFrame = Instance.new("Frame")
    benchFrame.Name = "BenchPets"
    benchFrame.Size = UDim2.new(1, 0, 0, 80)
    benchFrame.Position = UDim2.new(0, 0, 1, -100)
    benchFrame.BackgroundTransparency = 1
    benchFrame.ZIndex = 504
    benchFrame.Parent = parent
    
    local benchLayout = Instance.new("UIListLayout")
    benchLayout.FillDirection = Enum.FillDirection.Horizontal
    benchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    benchLayout.Padding = UDim.new(0, 10)
    benchLayout.Parent = benchFrame
    
    -- Create bench slots
    for i = 1, 5 do
        local benchSlot = self:CreateBenchPetSlot()
        benchSlot.Parent = benchFrame
    end
end

function BattleUI:CreatePetHealthBar(parent: Frame): Frame
    local barFrame = Instance.new("Frame")
    barFrame.Name = "PetHealthBar"
    barFrame.Size = UDim2.new(1, 0, 0, 20)
    barFrame.Position = UDim2.new(0, 0, 1, 10)
    barFrame.BackgroundColor3 = self._config.COLORS.Dark
    barFrame.ZIndex = 506
    barFrame.Parent = parent
    
    self._utilities.CreateCorner(barFrame, 10)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = self._config.COLORS.Success
    fill.ZIndex = 507
    fill.Parent = barFrame
    
    self._utilities.CreateCorner(fill, 10)
    
    local healthText = self._uiFactory:CreateLabel(barFrame, {
        text = "100/100",
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Numbers,
        textSize = 14,
        zIndex = 508
    })
    
    return barFrame
end

function BattleUI:CreateBenchPetSlot(): Frame
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(0, 60, 0, 60)
    slot.BackgroundColor3 = self._config.COLORS.Surface
    slot.BorderSizePixel = 0
    
    self._utilities.CreateCorner(slot, 8)
    
    -- Pet icon placeholder
    local petIcon = Instance.new("ImageLabel")
    petIcon.Name = "PetIcon"
    petIcon.Size = UDim2.new(1, -10, 1, -10)
    petIcon.Position = UDim2.new(0, 5, 0, 5)
    petIcon.BackgroundTransparency = 1
    petIcon.ScaleType = Enum.ScaleType.Fit
    petIcon.Parent = slot
    
    -- Health indicator
    local healthIndicator = Instance.new("Frame")
    healthIndicator.Name = "HealthIndicator"
    healthIndicator.Size = UDim2.new(1, -4, 0, 4)
    healthIndicator.Position = UDim2.new(0, 2, 1, -6)
    healthIndicator.BackgroundColor3 = self._config.COLORS.Success
    healthIndicator.BorderSizePixel = 0
    healthIndicator.Parent = slot
    
    return slot
end

function BattleUI:CreateBattleControls(parent: Frame)
    local controlsBar = Instance.new("Frame")
    controlsBar.Size = UDim2.new(1, -40, 0, 100)
    controlsBar.Position = UDim2.new(0, 20, 1, -200)
    controlsBar.BackgroundColor3 = self._config.COLORS.Dark
    controlsBar.BackgroundTransparency = 0.2
    controlsBar.ZIndex = 502
    controlsBar.Parent = parent
    
    self._utilities.CreateCorner(controlsBar, 12)
    self._utilities.CreatePadding(controlsBar, 20)
    
    -- Move buttons
    local moveFrame = Instance.new("Frame")
    moveFrame.Size = UDim2.new(0.7, -10, 1, 0)
    moveFrame.BackgroundTransparency = 1
    moveFrame.Parent = controlsBar
    
    local moveGrid = Instance.new("UIGridLayout")
    moveGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    moveGrid.CellSize = UDim2.new(0.5, -5, 0.5, -5)
    moveGrid.FillDirection = Enum.FillDirection.Horizontal
    moveGrid.Parent = moveFrame
    
    -- Create move buttons
    for i = 1, 4 do
        local moveButton = self:CreateMoveButton(i)
        moveButton.Parent = moveFrame
    end
    
    -- Switch pet area
    local switchFrame = Instance.new("Frame")
    switchFrame.Size = UDim2.new(0.3, -10, 1, 0)
    switchFrame.Position = UDim2.new(0.7, 10, 0, 0)
    switchFrame.BackgroundTransparency = 1
    switchFrame.Parent = controlsBar
    
    local switchLabel = self._uiFactory:CreateLabel(switchFrame, {
        text = "Switch Pet",
        size = UDim2.new(1, 0, 0, 20),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.White
    })
    
    local switchScroll = Instance.new("ScrollingFrame")
    switchScroll.Size = UDim2.new(1, 0, 1, -25)
    switchScroll.Position = UDim2.new(0, 0, 0, 25)
    switchScroll.BackgroundTransparency = 1
    switchScroll.ScrollBarThickness = 4
    switchScroll.Parent = switchFrame
    
    self.SwitchPetFrame = switchScroll
end

function BattleUI:CreateMoveButton(index: number): Frame
    local button = self._uiFactory:CreateButton(nil, {
        text = "Move " .. index,
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = self._config.COLORS.Primary,
        callback = function()
            self:UseMove(index)
        end
    })
    
    button.Name = "MoveButton" .. index
    
    -- Store in controls
    self.BattleControls["MoveButton" .. index] = button
    
    -- Add ready glow effect
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "ReadyGlow"
    glowFrame.Size = UDim2.new(1, 8, 1, 8)
    glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = button.ZIndex - 1
    glowFrame.Parent = button
    
    local glowStroke = Instance.new("UIStroke")
    glowStroke.Name = "GlowStroke"
    glowStroke.Color = self._config.COLORS.Success
    glowStroke.Thickness = 3
    glowStroke.Transparency = 1
    glowStroke.Parent = glowFrame
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 8)
    glowCorner.Parent = glowFrame
    
    -- Add cooldown overlay with sweep effect
    local cooldownOverlay = Instance.new("Frame")
    cooldownOverlay.Name = "CooldownOverlay"
    cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
    cooldownOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    cooldownOverlay.BackgroundTransparency = 0.5
    cooldownOverlay.Visible = false
    cooldownOverlay.ZIndex = button.ZIndex + 1
    cooldownOverlay.Parent = button
    
    self._utilities.CreateCorner(cooldownOverlay, 8)
    
    local cooldownLabel = self._uiFactory:CreateLabel(cooldownOverlay, {
        text = "0",
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Numbers,
        zIndex = cooldownOverlay.ZIndex + 1
    })
    
    return button
end

function BattleUI:CreateBattleLog(parent: Frame)
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(0, 300, 0, BATTLE_LOG_HEIGHT)
    logFrame.Position = UDim2.new(1, -320, 1, -200)
    logFrame.BackgroundColor3 = self._config.COLORS.Dark
    logFrame.BackgroundTransparency = 0.3
    logFrame.ZIndex = 502
    logFrame.Parent = parent
    
    self._utilities.CreateCorner(logFrame, 12)
    
    local logTitle = self._uiFactory:CreateLabel(logFrame, {
        text = "Battle Log",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 10, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.White,
        zIndex = 503
    })
    
    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -10, 1, -35)
    logScroll.Position = UDim2.new(0, 5, 0, 30)
    logScroll.BackgroundTransparency = 1
    logScroll.ScrollBarThickness = 4
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.Parent = logFrame
    
    self.BattleLogFrame = logScroll
    
    -- Auto-scroll to bottom
    logScroll:GetPropertyChangedSignal("CanvasSize"):Connect(function()
        logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset - logScroll.AbsoluteSize.Y)
    end)
end

-- ========================================
-- BATTLE LOGIC
-- ========================================

function BattleUI:UpdateBattleDisplay()
    if not self.CurrentBattle then return end
    
    -- Update health bars
    self:UpdateHealthBars()
    
    -- Update pet displays
    self:UpdatePetDisplays()
    
    -- Update move buttons
    self:UpdateMoveButtons()
    
    -- Update turn indicator
    self:UpdateTurnIndicator()
end

function BattleUI:UpdateHealthBars()
    -- Calculate team health percentages
    local playerHealth = self:CalculateTeamHealth(1)
    local opponentHealth = self:CalculateTeamHealth(2)
    
    -- Update player health bar with smooth animation
    if self.HealthBars.Player then
        local percentage = playerHealth.current / playerHealth.max
        local oldPercentage = self.HealthBars.Player.lastPercentage or percentage
        
        -- Smooth size transition
        self._utilities.Tween(self.HealthBars.Player.fill, {
            Size = UDim2.new(percentage, 0, 1, 0)
        }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Color based on health percentage
        local healthColor = self:GetHealthColor(percentage)
        self._utilities.Tween(self.HealthBars.Player.fill, {
            BackgroundColor3 = healthColor
        }, TweenInfo.new(0.3))
        
        -- Animate percentage text
        self:AnimateHealthText(self.HealthBars.Player.label, oldPercentage * 100, percentage * 100)
        
        -- Show damage if health decreased
        if percentage < oldPercentage then
            local damage = math.floor((oldPercentage - percentage) * playerHealth.max)
            self:ShowDamageNumber(self.HealthBars.Player.bar, damage)
        end
        
        self.HealthBars.Player.lastPercentage = percentage
    end
    
    -- Update opponent health bar with smooth animation
    if self.HealthBars.Opponent then
        local percentage = opponentHealth.current / opponentHealth.max
        local oldPercentage = self.HealthBars.Opponent.lastPercentage or percentage
        
        -- Smooth size transition
        self._utilities.Tween(self.HealthBars.Opponent.fill, {
            Size = UDim2.new(percentage, 0, 1, 0)
        }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Color based on health percentage
        local healthColor = self:GetHealthColor(percentage)
        self._utilities.Tween(self.HealthBars.Opponent.fill, {
            BackgroundColor3 = healthColor
        }, TweenInfo.new(0.3))
        
        -- Animate percentage text
        self:AnimateHealthText(self.HealthBars.Opponent.label, oldPercentage * 100, percentage * 100)
        
        -- Show damage if health decreased
        if percentage < oldPercentage then
            local damage = math.floor((oldPercentage - percentage) * opponentHealth.max)
            self:ShowDamageNumber(self.HealthBars.Opponent.bar, damage)
        end
        
        self.HealthBars.Opponent.lastPercentage = percentage
    end
end

function BattleUI:GetHealthColor(percentage: number): Color3
    if percentage > 0.7 then
        return self._config.COLORS.Success -- Green
    elseif percentage > 0.4 then
        return Color3.fromRGB(255, 200, 0) -- Yellow
    elseif percentage > 0.2 then
        return Color3.fromRGB(255, 140, 0) -- Orange
    else
        return self._config.COLORS.Error -- Red
    end
end

function BattleUI:AnimateHealthText(label: TextLabel, fromValue: number, toValue: number)
    local startTime = tick()
    local duration = 0.5
    
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Ease out quad
        progress = 1 - (1 - progress) * (1 - progress)
        
        local currentValue = fromValue + (toValue - fromValue) * progress
        label.Text = string.format("%d%%", math.floor(currentValue))
        
        if progress >= 1 then
            connection:Disconnect()
        end
    end)
end

function BattleUI:ShowDamageNumber(healthBar: Frame, damage: number)
    -- Create floating damage text
    local damageText = Instance.new("TextLabel")
    damageText.Size = UDim2.new(0, 100, 0, 50)
    damageText.Position = UDim2.new(0.5, 0, 0.5, 0)
    damageText.AnchorPoint = Vector2.new(0.5, 0.5)
    damageText.BackgroundTransparency = 1
    damageText.Text = "-" .. tostring(damage)
    damageText.Font = self._config.FONTS.Numbers
    damageText.TextColor3 = self._config.COLORS.Error
    damageText.TextScaled = true
    damageText.TextStrokeColor3 = Color3.new(0, 0, 0)
    damageText.TextStrokeTransparency = 0
    damageText.ZIndex = 600
    damageText.Parent = healthBar.Parent
    
    -- Start small and grow
    damageText.Size = UDim2.new(0, 0, 0, 0)
    
    -- Animate floating up
    self._utilities.Tween(damageText, {
        Size = UDim2.new(0, 100, 0, 50),
        Position = UDim2.new(0.5, math.random(-20, 20), 0, -50),
        TextTransparency = 0
    }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    task.wait(0.3)
    
    -- Fade out
    self._utilities.Tween(damageText, {
        Position = UDim2.new(0.5, math.random(-20, 20), 0, -80),
        TextTransparency = 1,
        TextStrokeTransparency = 1
    }, TweenInfo.new(0.5, Enum.EasingStyle.Quad))
    
    game:GetService("Debris"):AddItem(damageText, 1)
end

function BattleUI:CalculateTeamHealth(teamIndex: number): {current: number, max: number}
    local team = self.CurrentBattle.teams[teamIndex]
    if not team then return {current = 0, max = 1} end
    
    local current = 0
    local max = 0
    
    for _, pet in ipairs(team) do
        current = current + (pet.health or 0)
        max = max + (pet.maxHealth or 100)
    end
    
    return {current = current, max = max}
end

function BattleUI:UpdatePetDisplays()
    -- Update active pets and bench for both sides
    -- This would show current pet images, health, and status
end

function BattleUI:UpdateMoveButtons()
    -- Enable/disable move buttons based on turn
    local isMyTurn = self.CurrentBattle and self.CurrentBattle.currentTurn == 1
    
    for i = 1, 4 do
        local button = self.BattleControls["MoveButton" .. i]
        if button then
            button.Active = isMyTurn
            
            -- Update button appearance
            if isMyTurn then
                button.BackgroundColor3 = self._config.COLORS.Primary
                self:EnableMoveButton(button, i)
            else
                button.BackgroundColor3 = self._config.COLORS.TextSecondary
                self:DisableMoveButton(button)
            end
            
            -- Check cooldown
            local cooldown = self:GetMoveCooldown(i)
            if cooldown > 0 then
                self:ShowCooldown(button, cooldown)
            else
                self:HideCooldown(button)
            end
        end
    end
end

function BattleUI:EnableMoveButton(button: TextButton, moveIndex: number)
    -- Show ready glow
    local glowFrame = button:FindFirstChild("ReadyGlow")
    if glowFrame then
        local glowStroke = glowFrame:FindFirstChild("GlowStroke")
        if glowStroke then
            -- Animate glow pulse
            task.spawn(function()
                while button.Active and glowStroke.Parent do
                    self._utilities.Tween(glowStroke, {
                        Transparency = 0.3,
                        Thickness = 4
                    }, TweenInfo.new(0.8, Enum.EasingStyle.Sine))
                    task.wait(0.8)
                    self._utilities.Tween(glowStroke, {
                        Transparency = 0.6,
                        Thickness = 3
                    }, TweenInfo.new(0.8, Enum.EasingStyle.Sine))
                    task.wait(0.8)
                end
            end)
        end
    end
    
    -- Add hover effect
    if not button:GetAttribute("HoverConnected") then
        button:SetAttribute("HoverConnected", true)
        
        button.MouseEnter:Connect(function()
            if button.Active then
                self._utilities.Tween(button, {
                    Size = UDim2.new(1, 5, 1, 5)
                }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
                
                -- Show ability preview
                self:ShowAbilityPreview(moveIndex)
            end
        end)
        
        button.MouseLeave:Connect(function()
            self._utilities.Tween(button, {
                Size = UDim2.new(1, 0, 1, 0)
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
            
            self:HideAbilityPreview()
        end)
    end
end

function BattleUI:DisableMoveButton(button: TextButton)
    -- Hide glow
    local glowFrame = button:FindFirstChild("ReadyGlow")
    if glowFrame then
        local glowStroke = glowFrame:FindFirstChild("GlowStroke")
        if glowStroke then
            glowStroke.Transparency = 1
        end
    end
    
    -- Reset size
    button.Size = UDim2.new(1, 0, 1, 0)
end

function BattleUI:GetMoveCooldown(moveIndex: number): number
    -- This would check actual cooldown from battle state
    -- For now, return 0 (no cooldown)
    return 0
end

function BattleUI:ShowCooldown(button: TextButton, cooldown: number)
    local overlay = button:FindFirstChild("CooldownOverlay")
    if overlay then
        overlay.Visible = true
        
        -- Update cooldown text
        local label = overlay:FindFirstChildOfClass("TextLabel")
        if label then
            label.Text = tostring(cooldown)
        end
        
        -- Create sweep animation
        self:CreateCooldownSweep(button, cooldown)
    end
end

function BattleUI:HideCooldown(button: TextButton)
    local overlay = button:FindFirstChild("CooldownOverlay")
    if overlay then
        overlay.Visible = false
    end
end

function BattleUI:CreateCooldownSweep(button: TextButton, totalTime: number)
    local sweep = button:FindFirstChild("CooldownSweep") or Instance.new("ImageLabel")
    sweep.Name = "CooldownSweep"
    sweep.Size = UDim2.new(1, 0, 1, 0)
    sweep.BackgroundTransparency = 1
    sweep.Image = "rbxassetid://4641587788" -- Radial fill image
    sweep.ImageColor3 = Color3.new(0, 0, 0)
    sweep.ImageTransparency = 0.5
    sweep.ZIndex = button.ZIndex + 2
    sweep.Parent = button
    
    -- Animate sweep
    local startTime = tick()
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = elapsed / totalTime
        
        if progress >= 1 then
            sweep:Destroy()
            connection:Disconnect()
            self:HideCooldown(button)
        else
            -- Update radial fill based on progress
            sweep.ImageRectSize = Vector2.new(512, 512 * (1 - progress))
            sweep.ImageRectOffset = Vector2.new(0, 512 * progress)
        end
    end)
end

function BattleUI:UpdateTurnIndicator()
    if not self.CurrentBattle then return end
    
    local isPlayerTurn = self.CurrentBattle.currentTurn == 1
    
    -- Update active pet glow
    self:UpdateActivePetGlow(isPlayerTurn)
    
    -- Update turn timer with animation
    if self.TurnTimerLabel then
        local timer = self.CurrentBattle.turnTimer or 30
        self.TurnTimerLabel.Text = tostring(timer)
        
        -- Animate timer pulse if low time
        if timer <= 5 then
            self:AnimateTimerUrgent()
        end
    end
    
    -- Update turn indicator text
    if self.TurnIndicatorLabel then
        self.TurnIndicatorLabel.Text = isPlayerTurn and "YOUR TURN" or "OPPONENT'S TURN"
        self.TurnIndicatorLabel.TextColor3 = isPlayerTurn and self._config.COLORS.Success or self._config.COLORS.Warning
    end
end

function BattleUI:UpdateActivePetGlow(isPlayerTurn: boolean)
    -- Find active pet frames
    local playerPets = self.PlayerSide and self.PlayerSide:FindFirstChild("PetArea")
    local opponentPets = self.OpponentSide and self.OpponentSide:FindFirstChild("PetArea")
    
    if playerPets then
        local activePet = playerPets:FindFirstChild("ActivePet")
        if activePet then
            if isPlayerTurn then
                self:AddActivePetGlow(activePet)
            else
                self:RemoveActivePetGlow(activePet)
            end
        end
    end
    
    if opponentPets then
        local activePet = opponentPets:FindFirstChild("ActivePet")
        if activePet then
            if not isPlayerTurn then
                self:AddActivePetGlow(activePet)
            else
                self:RemoveActivePetGlow(activePet)
            end
        end
    end
end

function BattleUI:AddActivePetGlow(petFrame: Frame)
    -- Remove existing glow
    local existingGlow = petFrame:FindFirstChild("TurnGlow")
    if existingGlow then
        existingGlow:Destroy()
    end
    
    -- Create glowing border
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "TurnGlow"
    glowFrame.Size = UDim2.new(1, 20, 1, 20)
    glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = petFrame.ZIndex - 1
    glowFrame.Parent = petFrame
    
    -- Create UIStroke for glow
    local stroke = Instance.new("UIStroke")
    stroke.Color = self._config.COLORS.Success
    stroke.Thickness = 4
    stroke.Transparency = 0.5
    stroke.Parent = glowFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = glowFrame
    
    -- Animate glow pulse
    task.spawn(function()
        while glowFrame.Parent do
            self._utilities.Tween(stroke, {
                Thickness = 6,
                Transparency = 0.2
            }, TweenInfo.new(0.8, Enum.EasingStyle.Sine))
            task.wait(0.8)
            self._utilities.Tween(stroke, {
                Thickness = 4,
                Transparency = 0.5
            }, TweenInfo.new(0.8, Enum.EasingStyle.Sine))
            task.wait(0.8)
        end
    end)
    
    -- Add particles
    self:CreateTurnParticles(petFrame)
end

function BattleUI:RemoveActivePetGlow(petFrame: Frame)
    local glowFrame = petFrame:FindFirstChild("TurnGlow")
    if glowFrame then
        self._utilities.Tween(glowFrame, {
            BackgroundTransparency = 1
        }, TweenInfo.new(0.3))
        
        task.wait(0.3)
        glowFrame:Destroy()
    end
end

function BattleUI:CreateTurnParticles(petFrame: Frame)
    task.spawn(function()
        for i = 1, 20 do
            task.wait(math.random() * 0.5)
            
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, 4, 0, 4)
            particle.Position = UDim2.new(math.random(), 0, 1, 0)
            particle.BackgroundColor3 = self._config.COLORS.Success
            particle.BorderSizePixel = 0
            particle.ZIndex = petFrame.ZIndex + 1
            particle.Parent = petFrame
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
            
            -- Float up animation
            self._utilities.Tween(particle, {
                Position = UDim2.new(particle.Position.X.Scale, 0, -0.2, 0),
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            }, TweenInfo.new(2, Enum.EasingStyle.Linear))
            
            game:GetService("Debris"):AddItem(particle, 2)
        end
    end)
end

function BattleUI:AnimateTimerUrgent()
    if not self.TurnTimerLabel then return end
    
    -- Flash red
    self.TurnTimerLabel.TextColor3 = self._config.COLORS.Error
    
    -- Pulse animation
    self._utilities.Tween(self.TurnTimerLabel, {
        TextSize = 28
    }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
    
    task.wait(0.2)
    
    self._utilities.Tween(self.TurnTimerLabel, {
        TextSize = 24
    }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
end

function BattleUI:OnTurnStart(data: {turn: number, timer: number})
    self.CurrentBattle.currentTurn = data.turn
    self.CurrentBattle.turnTimer = data.timer
    
    -- Update UI
    self:UpdateBattleDisplay()
    
    -- Start turn timer
    self:StartTurnTimer()
    
    -- Show notification
    local isMyTurn = data.turn == 1
    if isMyTurn then
        self._notificationSystem:SendNotification("Your Turn!", 
            "Select your move", "info", 3)
        
        -- Play sound
        if self._soundSystem then
            self._soundSystem:PlayUISound("YourTurn")
        end
    end
end

function BattleUI:StartTurnTimer()
    -- Stop existing timer
    if self._timerConnection then
        self._timerConnection:Disconnect()
        self._timerConnection = nil
    end
    
    local timer = self.CurrentBattle.turnTimer or TURN_TIMER
    local lastUpdate = tick()
    
    -- Create countdown animation
    self._timerConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not self.IsInBattle then
            if self._timerConnection then
                self._timerConnection:Disconnect()
                self._timerConnection = nil
            end
            return
        end
        
        local now = tick()
        local elapsed = now - lastUpdate
        
        if elapsed >= 1 then
            lastUpdate = now
            timer = timer - 1
            
            if timer <= 0 then
                if self._timerConnection then
                    self._timerConnection:Disconnect()
                    self._timerConnection = nil
                end
                return
            end
            
            -- Update timer display
            if self.TurnTimerLabel then
                self.TurnTimerLabel.Text = tostring(timer)
                
                -- Animate timer change
                self:AnimateTimerTick(timer)
                
                -- Change color based on time
                if timer <= 5 then
                    self.TurnTimerLabel.TextColor3 = self._config.COLORS.Error
                    self:CreateTimerWarning(timer)
                elseif timer <= 10 then
                    self.TurnTimerLabel.TextColor3 = self._config.COLORS.Warning
                else
                    self.TurnTimerLabel.TextColor3 = self._config.COLORS.White
                end
            end
        end
    end)
end

function BattleUI:AnimateTimerTick(timer: number)
    if not self.TurnTimerLabel then return end
    
    -- Scale pop animation
    self.TurnTimerLabel.Size = UDim2.new(0, 120, 0, 120)
    
    self._utilities.Tween(self.TurnTimerLabel, {
        Size = UDim2.new(0, 100, 0, 100)
    }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    -- Critical time effects
    if timer <= 5 then
        -- Create radial sweep
        self:CreateTimerSweep(timer)
    end
end

function BattleUI:CreateTimerSweep(timeLeft: number)
    local timerParent = self.TurnTimerLabel.Parent
    if not timerParent then return end
    
    -- Create sweep effect
    local sweep = Instance.new("ImageLabel")
    sweep.Name = "TimerSweep"
    sweep.Size = UDim2.new(0, 120, 0, 120)
    sweep.Position = self.TurnTimerLabel.Position
    sweep.AnchorPoint = self.TurnTimerLabel.AnchorPoint
    sweep.BackgroundTransparency = 1
    sweep.Image = "rbxassetid://4641587788" -- Circle image
    sweep.ImageColor3 = self._config.COLORS.Error
    sweep.ImageTransparency = 0.7
    sweep.ZIndex = self.TurnTimerLabel.ZIndex - 1
    sweep.Parent = timerParent
    
    -- Animate sweep
    sweep.Size = UDim2.new(0, 100, 0, 100)
    self._utilities.Tween(sweep, {
        Size = UDim2.new(0, 150, 0, 150),
        ImageTransparency = 1
    }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    game:GetService("Debris"):AddItem(sweep, 0.5)
end

function BattleUI:CreateTimerWarning(timer: number)
    if timer == 5 then
        -- Create warning flash
        local warning = Instance.new("Frame")
        warning.Size = UDim2.new(1, 0, 1, 0)
        warning.BackgroundColor3 = self._config.COLORS.Error
        warning.BackgroundTransparency = 0.9
        warning.ZIndex = 450
        warning.Parent = self.BattleArena
        
        -- Flash animation
        self._utilities.Tween(warning, {
            BackgroundTransparency = 0.7
        }, TweenInfo.new(0.1))
        
        task.wait(0.1)
        
        self._utilities.Tween(warning, {
            BackgroundTransparency = 1
        }, TweenInfo.new(0.3))
        
        game:GetService("Debris"):AddItem(warning, 0.4)
        
        -- Sound effect
        if self._soundSystem then
            self._soundSystem:PlayUISound("TimerWarning")
        end
    end
end

function BattleUI:ShowAbilityPreview(moveIndex: number)
    -- Create preview tooltip
    if self._abilityPreview then
        self._abilityPreview:Destroy()
    end
    
    local preview = Instance.new("Frame")
    preview.Name = "AbilityPreview"
    preview.Size = UDim2.new(0, 200, 0, 100)
    preview.Position = UDim2.new(0.5, -100, 0, -120)
    preview.BackgroundColor3 = self._config.COLORS.Dark
    preview.BorderSizePixel = 0
    preview.ZIndex = 600
    preview.Parent = self.BattleArena
    
    self._utilities.CreateCorner(preview, 8)
    self._utilities.CreateShadow(preview, 10)
    
    -- Move name
    local moveName = self._uiFactory:CreateLabel(preview, {
        text = "Move " .. moveIndex,
        size = UDim2.new(1, -10, 0, 30),
        position = UDim2.new(0, 5, 0, 5),
        font = self._config.FONTS.Secondary,
        textSize = 16
    })
    
    -- Move description
    local moveDesc = self._uiFactory:CreateLabel(preview, {
        text = "Damage: 50\nType: Normal\nAccuracy: 95%",
        size = UDim2.new(1, -10, 0, 60),
        position = UDim2.new(0, 5, 0, 35),
        font = self._config.FONTS.Body,
        textSize = 14,
        textColor = self._config.COLORS.TextSecondary
    })
    
    self._abilityPreview = preview
    
    -- Animate entrance
    preview.Size = UDim2.new(0, 0, 0, 0)
    self._utilities.Tween(preview, {
        Size = UDim2.new(0, 200, 0, 100)
    }, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end

function BattleUI:HideAbilityPreview()
    if self._abilityPreview then
        self._utilities.Tween(self._abilityPreview, {
            Size = UDim2.new(0, 0, 0, 0)
        }, TweenInfo.new(0.15, Enum.EasingStyle.Quad))
        
        task.wait(0.15)
        if self._abilityPreview then
            self._abilityPreview:Destroy()
            self._abilityPreview = nil
        end
    end
end

function BattleUI:UseMove(moveIndex: number)
    if not self.CurrentBattle or self.CurrentBattle.currentTurn ~= 1 then
        return
    end
    
    -- Create button press effect
    local button = self.BattleControls["MoveButton" .. moveIndex]
    if button then
        self:CreateMoveUseEffect(button)
    end
    
    -- Send move to server
    if self._remoteManager then
        self._remoteManager:FireServer("UseBattleMove", {
            battleId = self.CurrentBattle.battleId,
            moveIndex = moveIndex
        })
    end
    
    -- Disable buttons temporarily
    self:DisableMoveButtons()
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Attack")
    end
end

function BattleUI:DisableMoveButtons()
    for i = 1, 4 do
        local button = self.BattleControls["MoveButton" .. i]
        if button then
            button.Active = false
        end
    end
end

function BattleUI:AddBattleLogEntry(text: string, color: Color3?)
    if not self.BattleLogFrame then return end
    
    local entry = self._uiFactory:CreateLabel(self.BattleLogFrame, {
        text = text,
        size = UDim2.new(1, -10, 0, 20),
        position = UDim2.new(0, 5, 0, #self.BattleLogFrame:GetChildren() * 25),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = color or self._config.COLORS.White,
        textSize = 14,
        textWrapped = true
    })
    
    -- Update canvas size
    self.BattleLogFrame.CanvasSize = UDim2.new(0, 0, 0, #self.BattleLogFrame:GetChildren() * 25 + 10)
end

function BattleUI:UpdateBattle(updateData: table)
    -- Update battle state
    for key, value in pairs(updateData) do
        self.CurrentBattle[key] = value
    end
    
    -- Add to battle log
    if updateData.logEntry then
        self:AddBattleLogEntry(updateData.logEntry, updateData.logColor)
    end
    
    -- Play animations
    if updateData.animation then
        self:PlayBattleAnimation(updateData.animation)
    end
    
    -- Update display
    self:UpdateBattleDisplay()
end

function BattleUI:PlayBattleAnimation(animData: table)
    -- Play attack animations, damage numbers, etc.
    if self._animationSystem then
        -- Example: damage animation
        if animData.type == "damage" then
            self._animationSystem:PlayAnimation("DamageNumber", {
                target = animData.target,
                damage = animData.damage,
                color = animData.critical and self._config.COLORS.Warning or self._config.COLORS.Error
            })
        end
    end
end

function BattleUI:EndBattle(result: {winner: number, rewards: table})
    self.IsInBattle = false
    
    -- Stop battle music
    if self._soundSystem then
        self._soundSystem:StopMusic()
    end
    
    -- Show result screen
    self:ShowBattleResult(result)
    
    -- Add to history
    self:AddToBattleHistory(result)
    
    -- Clean up after delay
    task.wait(5)
    self:CloseBattleArena()
end

function BattleUI:ShowBattleResult(result: {winner: number, rewards: table})
    local isWinner = result.winner == 1
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "VictoryOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 550
    overlay.Parent = self.BattleArena
    
    -- Fade in overlay
    self._utilities.Tween(overlay, {
        BackgroundTransparency = 0.5
    }, TweenInfo.new(0.5, Enum.EasingStyle.Quad))
    
    -- Create confetti for victory
    if isWinner then
        self:CreateVictoryConfetti(overlay)
    else
        -- Create defeat effect
        self:CreateDefeatEffect(overlay)
    end
    
    -- Create result frame with entrance animation
    local resultFrame = Instance.new("Frame")
    resultFrame.Size = UDim2.new(0, 0, 0, 0)
    resultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    resultFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    resultFrame.BackgroundColor3 = self._config.COLORS.Background
    resultFrame.ZIndex = 600
    resultFrame.Parent = overlay
    
    self._utilities.CreateCorner(resultFrame, 20)
    
    -- Animate entrance
    self._utilities.Tween(resultFrame, {
        Size = UDim2.new(0, 500, 0, 400)
    }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    -- Result text
    local resultText = isWinner and "VICTORY!" or "DEFEAT"
    local resultColor = isWinner and self._config.COLORS.Success or self._config.COLORS.Error
    
    local resultLabel = self._uiFactory:CreateLabel(resultFrame, {
        text = resultText,
        size = UDim2.new(1, 0, 0, 80),
        position = UDim2.new(0, 0, 0, 20),
        font = self._config.FONTS.Display,
        textColor = resultColor,
        textSize = 48,
        zIndex = 601
    })
    
    -- Animate text entrance
    resultLabel.TextTransparency = 1
    task.spawn(function()
        task.wait(0.5)
        self._utilities.Tween(resultLabel, {
            TextTransparency = 0
        }, TweenInfo.new(0.5, Enum.EasingStyle.Quad))
        
        -- Pulse effect for result text
        if isWinner then
            task.wait(0.5)
            for i = 1, 3 do
                self._utilities.Tween(resultLabel, {
                    TextSize = 52
                }, TweenInfo.new(0.2, Enum.EasingStyle.Sine))
                task.wait(0.2)
                self._utilities.Tween(resultLabel, {
                    TextSize = 48
                }, TweenInfo.new(0.2, Enum.EasingStyle.Sine))
                task.wait(0.2)
            end
        end
    end)
    
    -- Rewards display with animation
    if result.rewards then
        local rewardsFrame = Instance.new("Frame")
        rewardsFrame.Size = UDim2.new(1, -40, 0, 200)
        rewardsFrame.Position = UDim2.new(0, 20, 0, 120)
        rewardsFrame.BackgroundTransparency = 1
        rewardsFrame.ZIndex = 601
        rewardsFrame.Parent = resultFrame
        
        -- Animate rewards flying in
        task.spawn(function()
            task.wait(0.8)
            self:AnimateRewardsFlyIn(rewardsFrame, result.rewards)
        end)
    end
    
    -- Continue button
    local continueButton = self._uiFactory:CreateButton(resultFrame, {
        text = "Continue",
        size = UDim2.new(0, 150, 0, 50),
        position = UDim2.new(0.5, -75, 1, -70),
        backgroundColor = self._config.COLORS.Primary,
        zIndex = 601,
        callback = function()
            self:CloseBattleArena()
        end
    })
    
    -- Play result sound
    if self._soundSystem then
        self._soundSystem:PlayUISound(isWinner and "Victory" or "Defeat")
    end
    
    -- Particles for victory
    if isWinner and self._particleSystem then
        self._particleSystem:CreateBurst(resultFrame, "star", 
            UDim2.new(0.5, 0, 0.5, 0), 50)
    end
end

function BattleUI:DisplayBattleRewards(parent: Frame, rewards: table)
    local rewardLabel = self._uiFactory:CreateLabel(parent, {
        text = "Rewards",
        size = UDim2.new(1, 0, 0, 30),
        font = self._config.FONTS.Secondary,
        textSize = 20
    })
    
    local yOffset = 40
    
    -- Experience
    if rewards.experience then
        local expLabel = self._uiFactory:CreateLabel(parent, {
            text = "+" .. rewards.experience .. " Experience",
            size = UDim2.new(1, 0, 0, 25),
            position = UDim2.new(0, 0, 0, yOffset),
            textColor = self._config.COLORS.Success
        })
        yOffset = yOffset + 30
    end
    
    -- Coins
    if rewards.coins then
        local coinLabel = self._uiFactory:CreateLabel(parent, {
            text = "+" .. self._utilities.FormatNumber(rewards.coins) .. " Coins",
            size = UDim2.new(1, 0, 0, 25),
            position = UDim2.new(0, 0, 0, yOffset),
            textColor = self._config.COLORS.Warning
        })
        yOffset = yOffset + 30
    end
    
    -- Rating change
    if rewards.ratingChange then
        local ratingText = rewards.ratingChange > 0 and 
                          "+" .. rewards.ratingChange .. " Rating" or
                          rewards.ratingChange .. " Rating"
        local ratingColor = rewards.ratingChange > 0 and 
                           self._config.COLORS.Success or 
                           self._config.COLORS.Error
        
        local ratingLabel = self._uiFactory:CreateLabel(parent, {
            text = ratingText,
            size = UDim2.new(1, 0, 0, 25),
            position = UDim2.new(0, 0, 0, yOffset),
            textColor = ratingColor
        })
    end
end

function BattleUI:CloseBattleArena()
    if self.BattleArena then
        -- Fade out
        self._utilities.Tween(self.BattleArena, {
            BackgroundTransparency = 1
        }, self._config.TWEEN_INFO.Normal)
        
        task.wait(0.3)
        self.BattleArena:Destroy()
        self.BattleArena = nil
    end
    
    -- Clear battle state
    self.CurrentBattle = nil
    self.BattleControls = {}
    self.HealthBars = {}
    
    -- Refresh battle stats
    self:RefreshBattleStats()
end

-- ========================================
-- OTHER VIEWS
-- ========================================

function BattleUI:CreateTournamentView(parent: Frame)
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    -- Tournament list would be loaded here
    local emptyLabel = self._uiFactory:CreateLabel(scrollFrame, {
        text = "No active tournaments",
        size = UDim2.new(1, -20, 0, 50),
        position = UDim2.new(0, 10, 0, 10),
        textColor = self._config.COLORS.TextSecondary,
        font = self._config.FONTS.Secondary
    })
end

function BattleUI:CreateHistoryView(parent: Frame)
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    self.HistoryScrollFrame = scrollFrame
    
    -- Load battle history
    self:RefreshBattleHistory()
end

function BattleUI:RefreshBattleHistory()
    if not self.HistoryScrollFrame then return end
    
    -- Clear existing
    for _, child in ipairs(self.HistoryScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Display history
    if #self.BattleHistory == 0 then
        local emptyLabel = self._uiFactory:CreateLabel(self.HistoryScrollFrame, {
            text = "No battle history yet",
            size = UDim2.new(1, -20, 0, 50),
            position = UDim2.new(0, 10, 0, 10),
            textColor = self._config.COLORS.TextSecondary
        })
    else
        local yOffset = 5
        for _, battle in ipairs(self.BattleHistory) do
            self:CreateHistoryEntry(battle, yOffset)
            yOffset = yOffset + 85
        end
        
        self.HistoryScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end
end

function BattleUI:CreateHistoryEntry(battle: table, yPos: number)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 80)
    entry.Position = UDim2.new(0, 5, 0, yPos)
    entry.BackgroundColor3 = self._config.COLORS.Surface
    entry.Parent = self.HistoryScrollFrame
    
    self._utilities.CreateCorner(entry, 8)
    self._utilities.CreatePadding(entry, 10)
    
    -- Result indicator
    local isWin = battle.result == "victory"
    local resultColor = isWin and self._config.COLORS.Success or self._config.COLORS.Error
    
    local resultBar = Instance.new("Frame")
    resultBar.Size = UDim2.new(0, 4, 1, -10)
    resultBar.Position = UDim2.new(0, 0, 0, 5)
    resultBar.BackgroundColor3 = resultColor
    resultBar.BorderSizePixel = 0
    resultBar.Parent = entry
    
    -- Battle info
    local opponentLabel = self._uiFactory:CreateLabel(entry, {
        text = "vs " .. battle.opponent,
        size = UDim2.new(0.5, -20, 0, 25),
        position = UDim2.new(0, 15, 0, 5),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary
    })
    
    local resultLabel = self._uiFactory:CreateLabel(entry, {
        text = isWin and "Victory" or "Defeat",
        size = UDim2.new(0.3, 0, 0, 25),
        position = UDim2.new(0.7, 0, 0, 5),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = resultColor,
        font = self._config.FONTS.Secondary
    })
    
    local dateLabel = self._uiFactory:CreateLabel(entry, {
        text = os.date("%m/%d/%Y", battle.timestamp),
        size = UDim2.new(0.5, -20, 0, 20),
        position = UDim2.new(0, 15, 0, 30),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textSize = 14
    })
    
    local durationLabel = self._uiFactory:CreateLabel(entry, {
        text = self:FormatDuration(battle.duration),
        size = UDim2.new(0.5, -20, 0, 20),
        position = UDim2.new(0, 15, 0, 50),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textSize = 14
    })
end

function BattleUI:AddToBattleHistory(result: table)
    -- Add to history
    table.insert(self.BattleHistory, 1, {
        opponent = self.CurrentBattle.players[2].DisplayName,
        result = result.winner == 1 and "victory" or "defeat",
        timestamp = os.time(),
        duration = tick() - (self.CurrentBattle.startTime or tick()),
        rewards = result.rewards
    })
    
    -- Limit history size
    while #self.BattleHistory > 50 do
        table.remove(self.BattleHistory, #self.BattleHistory)
    end
    
    -- Refresh display
    self:RefreshBattleHistory()
end

function BattleUI:RefreshBattleStats()
    -- Load and display battle statistics
    -- This would fetch wins, losses, rating, etc. from the server
end

function BattleUI:ChallengePlayer(player: Player)
    -- Send challenge request
    if self._remoteManager then
        local success, result = self._remoteManager:InvokeServer("ChallengeToBattle", player)
        
        if success then
            self._notificationSystem:SendNotification("Challenge Sent", 
                "Waiting for " .. player.DisplayName .. " to respond...", "info")
        else
            self._notificationSystem:SendNotification("Error", 
                result or "Failed to send challenge", "error")
        end
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function BattleUI:FormatDuration(seconds: number): string
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("Duration: %d:%02d", minutes, secs)
end

-- ========================================
-- CLEANUP
-- ========================================

function BattleUI:Destroy()
    -- Close any open windows
    self:Close()
    
    -- Cancel any active battles
    if self.IsInBattle then
        self:CloseBattleArena()
    end
    
    -- Clear references
    self.Frame = nil
    self.TabFrames = {}
    self.BattleArena = nil
    self.CurrentBattle = nil
    self.MatchmakingOverlay = nil
    self.TeamSelectionUI = nil
    self.BattleControls = {}
    self.HealthBars = {}
    self.BattleLogFrame = nil
end

function BattleUI:CreateVictoryConfetti(parent: Frame)
    -- Create confetti particles
    for i = 1, 50 do
        task.spawn(function()
            local confetti = Instance.new("Frame")
            confetti.Size = UDim2.new(0, math.random(8, 15), 0, math.random(15, 25))
            confetti.Position = UDim2.new(math.random(), 0, -0.1, 0)
            confetti.BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 1)
            confetti.BorderSizePixel = 0
            confetti.ZIndex = 560
            confetti.Parent = parent
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = confetti
            
            -- Random rotation
            confetti.Rotation = math.random(0, 360)
            
            -- Fall animation
            local fallTime = math.random() * 2 + 3
            local swayAmount = math.random(30, 80)
            
            self._utilities.Tween(confetti, {
                Position = UDim2.new(confetti.Position.X.Scale + math.random(-0.1, 0.1), 
                                   swayAmount * math.sin(tick() * 2), 1.1, 0),
                Rotation = confetti.Rotation + math.random(180, 540)
            }, TweenInfo.new(fallTime, Enum.EasingStyle.Linear))
            
            -- Fade out at bottom
            task.wait(fallTime - 0.5)
            self._utilities.Tween(confetti, {
                BackgroundTransparency = 1
            }, TweenInfo.new(0.5))
            
            game:GetService("Debris"):AddItem(confetti, 0.5)
        end)
    end
    
    -- Victory sparkles
    for i = 1, 20 do
        task.spawn(function()
            task.wait(math.random() * 2)
            
            local sparkle = Instance.new("ImageLabel")
            sparkle.Size = UDim2.new(0, 50, 0, 50)
            sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
            sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
            sparkle.BackgroundTransparency = 1
            sparkle.Image = "rbxassetid://7072719831" -- Star image
            sparkle.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Gold
            sparkle.ZIndex = 565
            sparkle.Parent = parent
            
            -- Sparkle animation
            sparkle.Size = UDim2.new(0, 0, 0, 0)
            self._utilities.Tween(sparkle, {
                Size = UDim2.new(0, 50, 0, 50),
                Rotation = 180,
                ImageTransparency = 0
            }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            
            task.wait(0.5)
            
            self._utilities.Tween(sparkle, {
                Size = UDim2.new(0, 0, 0, 0),
                Rotation = 360,
                ImageTransparency = 1
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
            
            game:GetService("Debris"):AddItem(sparkle, 0.3)
        end)
    end
end

function BattleUI:CreateDefeatEffect(parent: Frame)
    -- Create slow motion effect
    local slowMoFrame = Instance.new("Frame")
    slowMoFrame.Size = UDim2.new(1, 0, 1, 0)
    slowMoFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    slowMoFrame.BackgroundTransparency = 0.8
    slowMoFrame.ZIndex = 555
    slowMoFrame.Parent = parent
    
    -- Pulse effect
    task.spawn(function()
        for i = 1, 3 do
            self._utilities.Tween(slowMoFrame, {
                BackgroundTransparency = 0.6
            }, TweenInfo.new(0.3, Enum.EasingStyle.Sine))
            task.wait(0.3)
            self._utilities.Tween(slowMoFrame, {
                BackgroundTransparency = 0.8
            }, TweenInfo.new(0.3, Enum.EasingStyle.Sine))
            task.wait(0.3)
        end
    end)
    
    -- Defeat particles (falling dark particles)
    for i = 1, 30 do
        task.spawn(function()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(10, 20), 0, math.random(10, 20))
            particle.Position = UDim2.new(math.random(), 0, -0.1, 0)
            particle.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
            particle.BorderSizePixel = 0
            particle.ZIndex = 560
            particle.Parent = parent
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
            
            -- Fall slowly
            self._utilities.Tween(particle, {
                Position = UDim2.new(particle.Position.X.Scale, 0, 1.1, 0),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 0)
            }, TweenInfo.new(math.random() * 2 + 4, Enum.EasingStyle.Linear))
            
            game:GetService("Debris"):AddItem(particle, 6)
        end)
    end
end

function BattleUI:AnimateRewardsFlyIn(rewardsFrame: Frame, rewards: table)
    local yOffset = 40
    local delay = 0
    
    -- Title
    local rewardLabel = self._uiFactory:CreateLabel(rewardsFrame, {
        text = "Rewards",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0.5, 0, 0, 0),
        font = self._config.FONTS.Secondary,
        textSize = 20
    })
    rewardLabel.AnchorPoint = Vector2.new(0.5, 0)
    
    -- Animate each reward flying in
    if rewards.experience then
        task.spawn(function()
            task.wait(delay)
            local expLabel = self._uiFactory:CreateLabel(rewardsFrame, {
                text = "+" .. rewards.experience .. " Experience",
                size = UDim2.new(1, 0, 0, 25),
                position = UDim2.new(-0.5, 0, 0, yOffset),
                textColor = self._config.COLORS.Success
            })
            
            self._utilities.Tween(expLabel, {
                Position = UDim2.new(0, 0, 0, yOffset)
            }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            
            -- Glow effect
            task.wait(0.5)
            self:CreateCollectEffect(expLabel)
        end)
        yOffset = yOffset + 30
        delay = delay + 0.1
    end
    
    if rewards.coins then
        task.spawn(function()
            task.wait(delay)
            local coinLabel = self._uiFactory:CreateLabel(rewardsFrame, {
                text = "+" .. self._utilities.FormatNumber(rewards.coins) .. " Coins",
                size = UDim2.new(1, 0, 0, 25),
                position = UDim2.new(1.5, 0, 0, yOffset),
                textColor = self._config.COLORS.Warning
            })
            
            self._utilities.Tween(coinLabel, {
                Position = UDim2.new(0, 0, 0, yOffset)
            }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            
            task.wait(0.5)
            self:CreateCollectEffect(coinLabel)
        end)
        yOffset = yOffset + 30
        delay = delay + 0.1
    end
    
    -- Items with collect animation
    if rewards.items then
        for _, item in ipairs(rewards.items) do
            task.spawn(function()
                task.wait(delay)
                local itemLabel = self._uiFactory:CreateLabel(rewardsFrame, {
                    text = item.name .. " x" .. item.quantity,
                    size = UDim2.new(1, 0, 0, 25),
                    position = UDim2.new(0, 0, 1, 0),
                    textColor = self._config.COLORS.Primary
                })
                
                self._utilities.Tween(itemLabel, {
                    Position = UDim2.new(0, 0, 0, yOffset)
                }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
                
                -- Add collect particle effect
                task.wait(0.5)
                self:CreateCollectEffect(itemLabel)
            end)
            yOffset = yOffset + 30
            delay = delay + 0.1
        end
    end
end

function BattleUI:CreateCollectEffect(element: GuiObject)
    for i = 1, 8 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 6, 0, 6)
        particle.Position = UDim2.new(0.5, 0, 0.5, 0)
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.BackgroundColor3 = self._config.COLORS.Success
        particle.BorderSizePixel = 0
        particle.ZIndex = element.ZIndex + 1
        particle.Parent = element
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = particle
        
        local angle = (i - 1) * (math.pi * 2 / 8)
        local distance = 30
        
        self._utilities.Tween(particle, {
            Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        game:GetService("Debris"):AddItem(particle, 0.4)
    end
end

function BattleUI:CreateMoveUseEffect(button: TextButton)
    -- Button press animation
    self._utilities.Tween(button, {
        Size = UDim2.new(0.9, 0, 0.9, 0)
    }, TweenInfo.new(0.1, Enum.EasingStyle.Quad))
    
    task.wait(0.1)
    
    self._utilities.Tween(button, {
        Size = UDim2.new(1, 0, 1, 0)
    }, TweenInfo.new(0.1, Enum.EasingStyle.Back))
    
    -- Create energy burst
    for i = 1, 8 do
        local burst = Instance.new("Frame")
        burst.Size = UDim2.new(0, 4, 0, 20)
        burst.Position = UDim2.new(0.5, 0, 0.5, 0)
        burst.AnchorPoint = Vector2.new(0.5, 0.5)
        burst.BackgroundColor3 = self._config.COLORS.Primary
        burst.BorderSizePixel = 0
        burst.Rotation = (i - 1) * 45
        burst.ZIndex = button.ZIndex + 10
        burst.Parent = button
        
        -- Animate outward
        self._utilities.Tween(burst, {
            Size = UDim2.new(0, 2, 0, 40),
            Position = UDim2.new(0.5, math.cos(math.rad(burst.Rotation)) * 50, 
                               0.5, math.sin(math.rad(burst.Rotation)) * 50),
            BackgroundTransparency = 1
        }, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        game:GetService("Debris"):AddItem(burst, 0.4)
    end
    
    -- Sound effect
    if self._soundSystem then
        self._soundSystem:PlayUISound("UseMove")
    end
end

function BattleUI:CreateImpactEffect(targetPosition: UDim2, moveType: string?)
    local playerGui = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    if not playerGui then return end
    
    -- Impact explosion
    local impact = Instance.new("Frame")
    impact.Size = UDim2.new(0, 0, 0, 0)
    impact.Position = targetPosition
    impact.AnchorPoint = Vector2.new(0.5, 0.5)
    impact.BackgroundColor3 = self._config.COLORS.Error
    impact.BorderSizePixel = 0
    impact.ZIndex = 600
    impact.Parent = self.BattleArena or playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = impact
    
    -- Expand and fade
    self._utilities.Tween(impact, {
        Size = UDim2.new(0, 150, 0, 150),
        BackgroundTransparency = 1
    }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Create shockwave rings
    for i = 1, 3 do
        task.spawn(function()
            task.wait(i * 0.1)
            
            local ring = Instance.new("Frame")
            ring.Size = UDim2.new(0, 50, 0, 50)
            ring.Position = targetPosition
            ring.AnchorPoint = Vector2.new(0.5, 0.5)
            ring.BackgroundTransparency = 1
            ring.ZIndex = 599
            ring.Parent = impact.Parent
            
            local ringStroke = Instance.new("UIStroke")
            ringStroke.Color = self._config.COLORS.Error
            ringStroke.Thickness = 3
            ringStroke.Transparency = 0
            ringStroke.Parent = ring
            
            local ringCorner = Instance.new("UICorner")
            ringCorner.CornerRadius = UDim.new(0.5, 0)
            ringCorner.Parent = ring
            
            -- Expand ring
            self._utilities.Tween(ring, {
                Size = UDim2.new(0, 200 + i * 50, 0, 200 + i * 50)
            }, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            self._utilities.Tween(ringStroke, {
                Transparency = 1,
                Thickness = 1
            }, TweenInfo.new(0.6, Enum.EasingStyle.Quad))
            
            game:GetService("Debris"):AddItem(ring, 0.6)
        end)
    end
    
    -- Impact particles
    for i = 1, 20 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
        particle.Position = targetPosition
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.BackgroundColor3 = Color3.fromRGB(255, math.random(100, 255), 0)
        particle.BorderSizePixel = 0
        particle.ZIndex = 601
        particle.Parent = impact.Parent
        
        local particleCorner = Instance.new("UICorner")
        particleCorner.CornerRadius = UDim.new(0.5, 0)
        particleCorner.Parent = particle
        
        -- Random direction
        local angle = math.random() * math.pi * 2
        local distance = math.random(50, 150)
        local targetX = targetPosition.X.Offset + math.cos(angle) * distance
        local targetY = targetPosition.Y.Offset + math.sin(angle) * distance
        
        self._utilities.Tween(particle, {
            Position = UDim2.new(0, targetX, 0, targetY),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Rotation = math.random(180, 540)
        }, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        game:GetService("Debris"):AddItem(particle, 0.6)
    end
    
    game:GetService("Debris"):AddItem(impact, 0.5)
    
    -- Sound effect
    if self._soundSystem then
        self._soundSystem:PlayUISound("Impact")
    end
end

return BattleUI