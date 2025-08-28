--[[
    Module: SocialUI
    Description: Comprehensive social interface with leaderboards, player profiles,
                 and clan system management
    Features: Multiple leaderboards, detailed profiles, clan creation/management,
              member lists, clan chat, social interactions
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local SocialUI = {}
SocialUI.__index = SocialUI

-- ========================================
-- TYPES
-- ========================================

type LeaderboardEntry = {
    rank: number,
    playerId: number,
    playerName: string,
    value: number,
    displayValue: string,
    isPlayer: boolean
}

type PlayerProfile = {
    playerId: number,
    username: string,
    displayName: string,
    level: number,
    joinDate: number,
    statistics: {
        totalWealth: number,
        petsOwned: number,
        battleWins: number,
        tradesCompleted: number,
        playTime: number,
        achievements: number
    },
    badges: {string},
    clan: {
        id: string?,
        name: string?,
        role: string?
    }
}

type Clan = {
    id: string,
    name: string,
    tag: string,
    description: string,
    icon: string,
    color: Color3,
    level: number,
    experience: number,
    memberCount: number,
    maxMembers: number,
    requirements: {
        minLevel: number,
        approval: boolean
    },
    members: {ClanMember},
    created: number,
    treasury: number
}

type ClanMember = {
    playerId: number,
    username: string,
    role: "Owner" | "Officer" | "Member",
    joinDate: number,
    contribution: number,
    lastSeen: number
}

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(900, 650)
local HEADER_HEIGHT = 60
local TAB_HEIGHT = 40
local LEADERBOARD_ENTRY_HEIGHT = 60
local PROFILE_STAT_HEIGHT = 80
local CLAN_MEMBER_HEIGHT = 50
local REFRESH_INTERVAL = 30 -- seconds

-- Leaderboard types
local LEADERBOARD_TYPES = {
    {id = "coins", name = "Top Coins", icon = "💰", color = Config.COLORS.Warning},
    {id = "gems", name = "Top Gems", icon = "💎", color = Config.COLORS.Info},
    {id = "pets", name = "Pet Collection", icon = "🐾", color = Config.COLORS.Primary},
    {id = "battles", name = "Battle Rating", icon = "⚔️", color = Config.COLORS.Error},
    {id = "level", name = "Highest Level", icon = "⭐", color = Config.COLORS.Accent}
}

-- Clan roles and permissions
local CLAN_ROLES = {
    Owner = {
        color = Config.COLORS.Error,
        permissions = {"all"}
    },
    Officer = {
        color = Config.COLORS.Warning,
        permissions = {"invite", "kick", "promote", "message"}
    },
    Member = {
        color = Config.COLORS.Primary,
        permissions = {"leave", "chat"}
    }
}

-- ========================================
-- INITIALIZATION
-- ========================================

function SocialUI.new(dependencies)
    local self = setmetatable({}, SocialUI)
    
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
    self._effectsLibrary = dependencies.EffectsLibrary
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self.TabFrames = {}
    self.LeaderboardContainers = {}
    self.ProfileWindow = nil
    self.ClanInterface = nil
    self.RefreshTimer = nil
    
    -- State
    self.CurrentTab = "leaderboard"
    self.ViewingProfile = nil
    self.CurrentClan = nil
    self.LeaderboardCache = {}
    self.LastRefresh = 0
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function SocialUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Leaderboard updates
    self._eventBus:On("LeaderboardUpdated", function(data)
        self:OnLeaderboardUpdate(data)
    end)
    
    -- Profile events
    self._eventBus:On("ViewProfile", function(playerId)
        self:ShowProfile(playerId)
    end)
    
    -- Clan events
    self._eventBus:On("ClanUpdated", function(clan)
        self:OnClanUpdate(clan)
    end)
    
    self._eventBus:On("ClanInviteReceived", function(invite)
        self:OnClanInvite(invite)
    end)
    
    self._eventBus:On("ClanMemberJoined", function(member)
        self:OnMemberJoined(member)
    end)
    
    self._eventBus:On("ClanMemberLeft", function(playerId)
        self:OnMemberLeft(playerId)
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function SocialUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshContent()
        return
    end
    
    -- Create UI
    self:CreateUI()
    
    -- Start refresh timer
    self:StartRefreshTimer()
end

function SocialUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
    
    -- Stop refresh timer
    self:StopRefreshTimer()
end

-- ========================================
-- UI CREATION
-- ========================================

function SocialUI:CreateUI()
    local mainPanel = self._windowManager and self._windowManager:GetMainPanel() or 
                     Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not mainPanel then
        warn("[SocialUI] No main panel found")
        return
    end
    
    -- Create main frame
    self.Frame = self._uiFactory:CreateFrame(mainPanel, {
        name = "SocialFrame",
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

function SocialUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary
    })
    
    -- Dynamic title based on tab
    self.HeaderLabel = self._uiFactory:CreateLabel(header, {
        text = "🏆 Leaderboards 🏆",
        size = UDim2.new(1, -100, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24
    })
    
    -- Refresh button
    local refreshButton = self._uiFactory:CreateButton(header, {
        text = "🔄",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0.5, -20),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:RefreshContent(true)
        end
    })
end

function SocialUI:CreateTabs()
    local tabs = {
        {
            name = "Leaderboards",
            icon = "🏆",
            callback = function(frame)
                self.CurrentTab = "leaderboard"
                self.HeaderLabel.Text = "🏆 Leaderboards 🏆"
                self:CreateLeaderboardView(frame)
            end
        },
        {
            name = "Profile",
            icon = "👤",
            callback = function(frame)
                self.CurrentTab = "profile"
                self.HeaderLabel.Text = "👤 My Profile 👤"
                self:CreateProfileView(frame, Services.Players.LocalPlayer)
            end
        },
        {
            name = "Clan",
            icon = "⚔️",
            callback = function(frame)
                self.CurrentTab = "clan"
                self.HeaderLabel.Text = "⚔️ Clan System ⚔️"
                self:CreateClanView(frame)
            end
        }
    }
    
    -- Create tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 1, -80)
    tabContainer.Position = UDim2.new(0, 10, 0, 70)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.Frame
    
    -- Tab buttons
    local tabButtonsFrame = Instance.new("Frame")
    tabButtonsFrame.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
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
    
    -- Create tabs
    for i, tab in ipairs(tabs) do
        -- Tab button
        local tabButton = self._uiFactory:CreateButton(tabButtonsFrame, {
            text = tab.icon .. " " .. tab.name,
            size = UDim2.new(1/3, -3.33, 1, 0),
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
                
                -- Refresh content
                self:RefreshContent()
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
-- LEADERBOARD VIEW
-- ========================================

function SocialUI:CreateLeaderboardView(parent: Frame)
    -- Create sub-tabs for different leaderboards
    local leaderboardTypes = Instance.new("Frame")
    leaderboardTypes.Size = UDim2.new(1, 0, 0, 35)
    leaderboardTypes.BackgroundTransparency = 1
    leaderboardTypes.Parent = parent
    
    local typeLayout = Instance.new("UIListLayout")
    typeLayout.FillDirection = Enum.FillDirection.Horizontal
    typeLayout.Padding = UDim.new(0, 5)
    typeLayout.Parent = leaderboardTypes
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, 0, 1, -40)
    contentArea.Position = UDim2.new(0, 0, 0, 40)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = parent
    
    -- Create leaderboard type buttons
    for i, lbType in ipairs(LEADERBOARD_TYPES) do
        local typeButton = self._uiFactory:CreateButton(leaderboardTypes, {
            text = lbType.icon .. " " .. lbType.name,
            size = UDim2.new(1/#LEADERBOARD_TYPES, -4, 1, 0),
            backgroundColor = i == 1 and lbType.color or self._config.COLORS.Surface,
            textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
            textSize = 14,
            callback = function()
                -- Update button states
                for j, btn in ipairs(leaderboardTypes:GetChildren()) do
                    if btn:IsA("TextButton") then
                        local btnType = LEADERBOARD_TYPES[j]
                        if btnType then
                            btn.BackgroundColor3 = j == i and btnType.color or self._config.COLORS.Surface
                            btn.TextColor3 = j == i and self._config.COLORS.White or self._config.COLORS.Dark
                        end
                    end
                end
                
                -- Show leaderboard
                self:ShowLeaderboard(lbType.id)
            end
        })
        
        -- Create leaderboard container
        local lbContainer = self:CreateLeaderboardContainer(contentArea, lbType)
        lbContainer.Visible = i == 1
        self.LeaderboardContainers[lbType.id] = lbContainer
    end
    
    -- Show first leaderboard
    self:ShowLeaderboard(LEADERBOARD_TYPES[1].id)
end

function SocialUI:CreateLeaderboardContainer(parent: Frame, lbType: table): Frame
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Your rank display
    local yourRankFrame = Instance.new("Frame")
    yourRankFrame.Size = UDim2.new(1, 0, 0, 80)
    yourRankFrame.BackgroundColor3 = lbType.color
    yourRankFrame.Parent = container
    
    self._utilities.CreateCorner(yourRankFrame, 12)
    self._utilities.CreatePadding(yourRankFrame, 15)
    
    -- Your rank info
    local yourRankLabel = self._uiFactory:CreateLabel(yourRankFrame, {
        text = "Your Rank: Loading...",
        size = UDim2.new(0.5, 0, 0.5, 0),
        position = UDim2.new(0, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 18
    })
    
    local yourValueLabel = self._uiFactory:CreateLabel(yourRankFrame, {
        text = "0",
        size = UDim2.new(0.5, 0, 0.5, 0),
        position = UDim2.new(0.5, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Display,
        textSize = 24
    })
    
    local yourNameLabel = self._uiFactory:CreateLabel(yourRankFrame, {
        text = Services.Players.LocalPlayer.DisplayName,
        size = UDim2.new(0.5, 0, 0.5, 0),
        position = UDim2.new(0, 0, 0.5, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 16
    })
    
    -- Leaderboard list
    local scrollFrame = self._uiFactory:CreateScrollingFrame(container, {
        size = UDim2.new(1, 0, 1, -90),
        position = UDim2.new(0, 0, 0, 90)
    })
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Store references
    container.YourRankLabel = yourRankLabel
    container.YourValueLabel = yourValueLabel
    container.ScrollFrame = scrollFrame
    container.Type = lbType
    
    return container
end

function SocialUI:ShowLeaderboard(leaderboardId: string)
    -- Hide all containers
    for id, container in pairs(self.LeaderboardContainers) do
        container.Visible = id == leaderboardId
    end
    
    -- Fetch and display data
    self:FetchLeaderboardData(leaderboardId)
end

function SocialUI:FetchLeaderboardData(leaderboardId: string)
    if self._remoteManager then
        local data = self._remoteManager:InvokeServer("GetLeaderboard", leaderboardId)
        
        if data then
            self:UpdateLeaderboard(leaderboardId, data)
        else
            -- Use cached data or show empty
            self:ShowEmptyLeaderboard(leaderboardId)
        end
    end
end

function SocialUI:UpdateLeaderboard(leaderboardId: string, data: table)
    local container = self.LeaderboardContainers[leaderboardId]
    if not container then return end
    
    -- Clear existing entries
    for _, child in ipairs(container.ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Update your rank
    if data.yourRank then
        container.YourRankLabel.Text = "Your Rank: #" .. data.yourRank
        container.YourValueLabel.Text = self._utilities.FormatNumber(data.yourValue or 0)
    end
    
    -- Create entries
    for i, entry in ipairs(data.entries or {}) do
        self:CreateLeaderboardEntry(container.ScrollFrame, entry, i)
    end
    
    -- Cache data
    self.LeaderboardCache[leaderboardId] = {
        data = data,
        timestamp = tick()
    }
end

function SocialUI:CreateLeaderboardEntry(parent: ScrollingFrame, entry: LeaderboardEntry, index: number): Frame
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = "Rank" .. entry.rank
    entryFrame.Size = UDim2.new(1, -10, 0, LEADERBOARD_ENTRY_HEIGHT)
    entryFrame.BackgroundColor3 = entry.isPlayer and self._config.COLORS.Primary or self._config.COLORS.White
    entryFrame.BackgroundTransparency = entry.isPlayer and 0.2 or 0
    entryFrame.LayoutOrder = index
    entryFrame.Parent = parent
    
    self._utilities.CreateCorner(entryFrame, 8)
    self._utilities.CreatePadding(entryFrame, 10)
    
    -- Rank display
    local rankColors = {
        [1] = Color3.fromRGB(255, 215, 0), -- Gold
        [2] = Color3.fromRGB(192, 192, 192), -- Silver
        [3] = Color3.fromRGB(205, 127, 50) -- Bronze
    }
    
    local rankFrame = Instance.new("Frame")
    rankFrame.Size = UDim2.new(0, 50, 1, 0)
    rankFrame.BackgroundTransparency = 1
    rankFrame.Parent = entryFrame
    
    local rankLabel = self._uiFactory:CreateLabel(rankFrame, {
        text = "#" .. entry.rank,
        size = UDim2.new(1, 0, 1, 0),
        font = self._config.FONTS.Display,
        textColor = rankColors[entry.rank] or 
                   (entry.isPlayer and self._config.COLORS.White or self._config.COLORS.Dark),
        textSize = 20
    })
    
    -- Player info
    local playerFrame = Instance.new("Frame")
    playerFrame.Size = UDim2.new(0.5, -60, 1, 0)
    playerFrame.Position = UDim2.new(0, 60, 0, 0)
    playerFrame.BackgroundTransparency = 1
    playerFrame.Parent = entryFrame
    
    local nameLabel = self._uiFactory:CreateLabel(playerFrame, {
        text = entry.playerName,
        size = UDim2.new(1, 0, 0.6, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textColor = entry.isPlayer and self._config.COLORS.White or self._config.COLORS.Dark,
        textSize = 16
    })
    
    -- View profile button
    local profileButton = self._uiFactory:CreateButton(playerFrame, {
        text = "View Profile",
        size = UDim2.new(0, 80, 0, 25),
        position = UDim2.new(0, 0, 0.6, 0),
        backgroundColor = self._config.COLORS.Secondary,
        textSize = 12,
        callback = function()
            self:ShowProfile(entry.playerId)
        end
    })
    
    -- Value display
    local valueLabel = self._uiFactory:CreateLabel(entryFrame, {
        text = entry.displayValue or self._utilities.FormatNumber(entry.value),
        size = UDim2.new(0.4, 0, 1, 0),
        position = UDim2.new(0.6, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        font = self._config.FONTS.Display,
        textColor = entry.isPlayer and self._config.COLORS.White or self._config.COLORS.Primary,
        textSize = 18
    })
    
    -- Add hover effect
    entryFrame.MouseEnter:Connect(function()
        if not entry.isPlayer then
            self._utilities.Tween(entryFrame, {
                BackgroundColor3 = self._config.COLORS.Surface
            }, self._config.TWEEN_INFO.Fast)
        end
    end)
    
    entryFrame.MouseLeave:Connect(function()
        if not entry.isPlayer then
            self._utilities.Tween(entryFrame, {
                BackgroundColor3 = self._config.COLORS.White
            }, self._config.TWEEN_INFO.Fast)
        end
    end)
    
    -- Trophy icon for top 3
    if entry.rank <= 3 then
        local trophyIcon = self._uiFactory:CreateLabel(entryFrame, {
            text = entry.rank == 1 and "🥇" or (entry.rank == 2 and "🥈" or "🥉"),
            size = UDim2.new(0, 30, 0, 30),
            position = UDim2.new(1, -35, 0.5, -15),
            textSize = 24
        })
    end
    
    return entryFrame
end

function SocialUI:ShowEmptyLeaderboard(leaderboardId: string)
    local container = self.LeaderboardContainers[leaderboardId]
    if not container then return end
    
    local emptyLabel = self._uiFactory:CreateLabel(container.ScrollFrame, {
        text = "No data available. Try refreshing!",
        size = UDim2.new(1, -20, 0, 100),
        position = UDim2.new(0, 10, 0, 10),
        textColor = self._config.COLORS.TextSecondary,
        font = self._config.FONTS.Secondary,
        textSize = 18
    })
end

-- ========================================
-- PROFILE VIEW
-- ========================================

function SocialUI:CreateProfileView(parent: Frame, player: Player?)
    if not player then
        player = Services.Players.LocalPlayer
    end
    
    local profileContainer = Instance.new("Frame")
    profileContainer.Size = UDim2.new(1, 0, 1, 0)
    profileContainer.BackgroundTransparency = 1
    profileContainer.Parent = parent
    
    -- Profile header
    self:CreateProfileHeader(profileContainer, player)
    
    -- Profile content with tabs
    self:CreateProfileContent(profileContainer, player)
end

function SocialUI:CreateProfileHeader(parent: Frame, player: Player)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 120)
    header.BackgroundColor3 = self._config.COLORS.Primary
    header.Parent = parent
    
    self._utilities.CreateCorner(header, 12)
    
    -- Avatar
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size = UDim2.new(0, 100, 0, 100)
    avatarFrame.Position = UDim2.new(0, 20, 0.5, -50)
    avatarFrame.BackgroundColor3 = self._config.COLORS.White
    avatarFrame.Parent = header
    
    self._utilities.CreateCorner(avatarFrame, 50)
    
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(1, -4, 1, -4)
    avatar.Position = UDim2.new(0, 2, 0, 2)
    avatar.BackgroundTransparency = 1
    avatar.Image = Services.Players:GetUserThumbnailAsync(
        player.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size100x100
    )
    avatar.Parent = avatarFrame
    
    self._utilities.CreateCorner(avatar, 48)
    
    -- Player info
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(0.5, -140, 1, -20)
    infoFrame.Position = UDim2.new(0, 130, 0, 10)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = header
    
    local displayName = self._uiFactory:CreateLabel(infoFrame, {
        text = player.DisplayName,
        size = UDim2.new(1, 0, 0, 35),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 28
    })
    
    local username = self._uiFactory:CreateLabel(infoFrame, {
        text = "@" .. player.Name,
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 35),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.White,
        textTransparency = 0.3,
        textSize = 16
    })
    
    local joinDate = self._uiFactory:CreateLabel(infoFrame, {
        text = "Joined: " .. os.date("%m/%d/%Y", os.time() - (player.AccountAge * 86400)),
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 60),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.White,
        textTransparency = 0.3,
        textSize = 14
    })
    
    -- Action buttons
    if player ~= Services.Players.LocalPlayer then
        local actionsFrame = Instance.new("Frame")
        actionsFrame.Size = UDim2.new(0.5, -20, 1, -20)
        actionsFrame.Position = UDim2.new(0.5, 10, 0, 10)
        actionsFrame.BackgroundTransparency = 1
        actionsFrame.Parent = header
        
        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        buttonLayout.Padding = UDim.new(0, 10)
        buttonLayout.Parent = actionsFrame
        
        -- Add friend button
        local friendButton = self._uiFactory:CreateButton(actionsFrame, {
            text = "Add Friend",
            size = UDim2.new(0, 100, 0, 35),
            backgroundColor = self._config.COLORS.Success,
            callback = function()
                self:SendFriendRequest(player)
            end
        })
        
        -- Trade button
        local tradeButton = self._uiFactory:CreateButton(actionsFrame, {
            text = "Trade",
            size = UDim2.new(0, 80, 0, 35),
            backgroundColor = self._config.COLORS.Secondary,
            callback = function()
                self._eventBus:Fire("InitiateTrade", player)
            end
        })
        
        -- Battle button
        local battleButton = self._uiFactory:CreateButton(actionsFrame, {
            text = "Battle",
            size = UDim2.new(0, 80, 0, 35),
            backgroundColor = self._config.COLORS.Error,
            callback = function()
                self._eventBus:Fire("ChallengeToBattle", player)
            end
        })
    end
end

function SocialUI:CreateProfileContent(parent: Frame, player: Player)
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -130)
    contentFrame.Position = UDim2.new(0, 0, 0, 130)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = parent
    
    -- Profile tabs
    local profileTabs = {
        {name = "Statistics", icon = "📊"},
        {name = "Pets", icon = "🐾"},
        {name = "Achievements", icon = "🏆"},
        {name = "Badges", icon = "🎖️"}
    }
    
    local tabButtons = Instance.new("Frame")
    tabButtons.Size = UDim2.new(1, 0, 0, 35)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = contentFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabButtons
    
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -40)
    tabContent.Position = UDim2.new(0, 0, 0, 40)
    tabContent.BackgroundColor3 = self._config.COLORS.White
    tabContent.Parent = contentFrame
    
    self._utilities.CreateCorner(tabContent, 12)
    
    -- Create tab frames
    local tabFrames = {}
    
    for i, tab in ipairs(profileTabs) do
        -- Tab button
        local tabButton = self._uiFactory:CreateButton(tabButtons, {
            text = tab.icon .. " " .. tab.name,
            size = UDim2.new(0.25, -3.75, 1, 0),
            backgroundColor = i == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
            textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
            textSize = 14,
            callback = function()
                -- Update button states
                for j, btn in ipairs(tabButtons:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = j == i and self._config.COLORS.Primary or self._config.COLORS.Surface
                        btn.TextColor3 = j == i and self._config.COLORS.White or self._config.COLORS.Dark
                    end
                end
                
                -- Show tab
                for name, frame in pairs(tabFrames) do
                    frame.Visible = name == tab.name
                end
            end
        })
        
        -- Tab frame
        local tabFrame = Instance.new("Frame")
        tabFrame.Size = UDim2.new(1, -20, 1, -20)
        tabFrame.Position = UDim2.new(0, 10, 0, 10)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = tabContent
        
        -- Create tab content
        if tab.name == "Statistics" then
            self:CreateProfileStats(tabFrame, player)
        elseif tab.name == "Pets" then
            self:CreateProfilePets(tabFrame, player)
        elseif tab.name == "Achievements" then
            self:CreateProfileAchievements(tabFrame, player)
        elseif tab.name == "Badges" then
            self:CreateProfileBadges(tabFrame, player)
        end
        
        tabFrames[tab.name] = tabFrame
    end
end

function SocialUI:CreateProfileStats(parent: Frame, player: Player)
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, 0, 1, 0)
    })
    
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, -20, 0, 500)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = scrollFrame
    
    local statsGrid = Instance.new("UIGridLayout")
    statsGrid.CellPadding = UDim2.new(0, 15, 0, 15)
    statsGrid.CellSize = UDim2.new(0.5, -7.5, 0, PROFILE_STAT_HEIGHT)
    statsGrid.FillDirection = Enum.FillDirection.Horizontal
    statsGrid.Parent = statsContainer
    
    self._utilities.CreatePadding(statsContainer, 10)
    
    -- Get player data
    local playerData = player == Services.Players.LocalPlayer and 
                     (self._dataCache and self._dataCache:Get() or {}) or {}
    
    -- Calculate stats
    local stats = {
        {
            title = "Total Wealth",
            value = self._utilities.FormatNumber(
                (playerData.currencies and playerData.currencies.coins or 0) +
                (playerData.currencies and playerData.currencies.gems or 0) * 100
            ),
            icon = "💰",
            color = self._config.COLORS.Warning
        },
        {
            title = "Pets Owned",
            value = tostring(self:CountPets(playerData.pets)),
            icon = "🐾",
            color = self._config.COLORS.Primary
        },
        {
            title = "Battle Wins",
            value = tostring(playerData.statistics and playerData.statistics.battleWins or 0),
            icon = "⚔️",
            color = self._config.COLORS.Success
        },
        {
            title = "Trades Completed",
            value = tostring(playerData.statistics and playerData.statistics.tradesCompleted or 0),
            icon = "🤝",
            color = self._config.COLORS.Info
        },
        {
            title = "Play Time",
            value = self:FormatPlayTime(playerData.statistics and playerData.statistics.playTime or 0),
            icon = "⏱️",
            color = self._config.COLORS.Secondary
        },
        {
            title = "Achievements",
            value = self:CountAchievements(playerData.achievements) .. "/100",
            icon = "🏆",
            color = self._config.COLORS.Accent
        }
    }
    
    -- Create stat cards
    for _, stat in ipairs(stats) do
        local statCard = Instance.new("Frame")
        statCard.BackgroundColor3 = self._config.COLORS.White
        statCard.Parent = statsContainer
        
        self._utilities.CreateCorner(statCard, 12)
        self._utilities.CreatePadding(statCard, 15)
        
        -- Icon
        local iconLabel = self._uiFactory:CreateLabel(statCard, {
            text = stat.icon,
            size = UDim2.new(0, 50, 0, 50),
            textSize = 36
        })
        
        -- Title
        local titleLabel = self._uiFactory:CreateLabel(statCard, {
            text = stat.title,
            size = UDim2.new(1, -60, 0, 25),
            position = UDim2.new(0, 60, 0, 5),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.TextSecondary,
            font = self._config.FONTS.Secondary,
            textSize = 14
        })
        
        -- Value
        local valueLabel = self._uiFactory:CreateLabel(statCard, {
            text = stat.value,
            size = UDim2.new(1, -60, 0, 30),
            position = UDim2.new(0, 60, 0, 30),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = stat.color,
            font = self._config.FONTS.Display,
            textSize = 24
        })
    end
    
    -- Update canvas size
    statsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, statsGrid.AbsoluteContentSize.Y + 20)
    end)
end

function SocialUI:CreateProfilePets(parent: Frame, player: Player)
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, 0, 1, 0)
    })
    
    if player ~= Services.Players.LocalPlayer then
        -- Privacy message
        local privacyLabel = self._uiFactory:CreateLabel(scrollFrame, {
            text = "This player's pet collection is private",
            size = UDim2.new(1, -20, 0, 50),
            position = UDim2.new(0, 10, 0, 10),
            textColor = self._config.COLORS.TextSecondary,
            font = self._config.FONTS.Secondary,
            textSize = 18
        })
        return
    end
    
    -- Pet grid
    local petGrid = Instance.new("UIGridLayout")
    petGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    petGrid.CellSize = UDim2.new(0, 120, 0, 140)
    petGrid.FillDirection = Enum.FillDirection.Horizontal
    petGrid.Parent = scrollFrame
    
    -- Load pets
    local playerData = self._dataCache and self._dataCache:Get() or {}
    if playerData.pets then
        local petCount = 0
        for uniqueId, petInstance in pairs(playerData.pets) do
            if type(petInstance) == "table" then
                petCount = petCount + 1
                if petCount <= 20 then -- Show max 20 pets
                    self:CreatePetCard(scrollFrame, petInstance)
                end
            end
        end
        
        if petCount == 0 then
            local noPetsLabel = self._uiFactory:CreateLabel(scrollFrame, {
                text = "No pets yet!",
                size = UDim2.new(1, -20, 0, 50),
                position = UDim2.new(0, 10, 0, 10),
                textColor = self._config.COLORS.TextSecondary,
                textSize = 18
            })
        elseif petCount > 20 then
            local moreLabel = self._uiFactory:CreateLabel(scrollFrame, {
                text = "+" .. (petCount - 20) .. " more pets",
                size = UDim2.new(0, 120, 0, 140),
                backgroundColor = self._config.COLORS.Surface,
                textColor = self._config.COLORS.TextSecondary,
                textSize = 16
            })
            
            self._utilities.CreateCorner(moreLabel, 8)
        end
    end
    
    -- Update canvas size
    petGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, petGrid.AbsoluteContentSize.Y + 20)
    end)
end

function SocialUI:CreatePetCard(parent: ScrollingFrame, petInstance: table): Frame
    local petData = self._dataCache and 
                   self._dataCache:Get("petDatabase." .. petInstance.petId) or 
                   {displayName = "Unknown", rarity = 1}
    
    local card = Instance.new("Frame")
    card.BackgroundColor3 = self._config.COLORS.Surface
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 8)
    
    -- Rarity border
    local rarityColors = {
        Color3.fromRGB(200, 200, 200), -- Common
        Color3.fromRGB(76, 175, 80),   -- Uncommon
        Color3.fromRGB(33, 150, 243),  -- Rare
        Color3.fromRGB(156, 39, 176),  -- Epic
        Color3.fromRGB(255, 152, 0),   -- Legendary
        Color3.fromRGB(233, 30, 99),   -- Mythical
        Color3.fromRGB(255, 235, 59)   -- Secret
    }
    
    self._utilities.CreateStroke(card, rarityColors[petData.rarity] or rarityColors[1], 2)
    
    -- Pet image
    if petData.imageId then
        local petImage = Instance.new("ImageLabel")
        petImage.Size = UDim2.new(0.8, 0, 0.6, 0)
        petImage.Position = UDim2.new(0.1, 0, 0.1, 0)
        petImage.BackgroundTransparency = 1
        petImage.Image = petData.imageId
        petImage.ScaleType = Enum.ScaleType.Fit
        petImage.Parent = card
    end
    
    -- Pet name
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = petInstance.nickname or petData.displayName,
        size = UDim2.new(1, -10, 0, 20),
        position = UDim2.new(0, 5, 1, -45),
        textScaled = true,
        textSize = 12
    })
    
    -- Level badge
    local levelBadge = Instance.new("Frame")
    levelBadge.Size = UDim2.new(0, 40, 0, 20)
    levelBadge.Position = UDim2.new(1, -45, 1, -25)
    levelBadge.BackgroundColor3 = self._config.COLORS.Dark
    levelBadge.Parent = card
    
    self._utilities.CreateCorner(levelBadge, 4)
    
    local levelLabel = self._uiFactory:CreateLabel(levelBadge, {
        text = "Lv." .. (petInstance.level or 1),
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        textSize = 10
    })
    
    return card
end

function SocialUI:CreateProfileAchievements(parent: Frame, player: Player)
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, 0, 1, 0)
    })
    
    local achievementContainer = Instance.new("Frame")
    achievementContainer.Size = UDim2.new(1, -20, 0, 100)
    achievementContainer.BackgroundTransparency = 1
    achievementContainer.Parent = scrollFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = achievementContainer
    
    self._utilities.CreatePadding(achievementContainer, 10)
    
    -- Sample achievements (would be loaded from data)
    local achievements = {
        {
            name = "First Steps",
            description = "Open your first egg",
            icon = "🥚",
            tier = "Bronze",
            unlocked = true
        },
        {
            name = "Pet Collector",
            description = "Collect 10 different pets",
            icon = "🐾",
            tier = "Silver",
            unlocked = true
        },
        {
            name = "Millionaire",
            description = "Earn 1,000,000 coins",
            icon = "💰",
            tier = "Gold",
            unlocked = true
        },
        {
            name = "Battle Master",
            description = "Win 100 battles",
            icon = "⚔️",
            tier = "Platinum",
            unlocked = false
        }
    }
    
    for _, achievement in ipairs(achievements) do
        local achievementCard = self:CreateAchievementCard(achievementContainer, achievement)
    end
    
    -- Update canvas size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)
end

function SocialUI:CreateAchievementCard(parent: Frame, achievement: table): Frame
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 80)
    card.BackgroundColor3 = achievement.unlocked and self._config.COLORS.White or 
                           Color3.fromRGB(230, 230, 230)
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    self._utilities.CreatePadding(card, 15)
    
    -- Icon
    local iconLabel = self._uiFactory:CreateLabel(card, {
        text = achievement.icon,
        size = UDim2.new(0, 50, 0, 50),
        position = UDim2.new(0, 0, 0.5, -25),
        textSize = 36,
        textTransparency = achievement.unlocked and 0 or 0.5
    })
    
    -- Info
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = achievement.name,
        size = UDim2.new(1, -150, 0, 25),
        position = UDim2.new(0, 60, 0, 10),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textColor = achievement.unlocked and self._config.COLORS.Dark or 
                   Color3.fromRGB(150, 150, 150),
        textSize = 16
    })
    
    local descLabel = self._uiFactory:CreateLabel(card, {
        text = achievement.description,
        size = UDim2.new(1, -150, 0, 25),
        position = UDim2.new(0, 60, 0, 35),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textSize = 14
    })
    
    -- Tier badge
    local tierColors = {
        Bronze = Color3.fromRGB(205, 127, 50),
        Silver = Color3.fromRGB(192, 192, 192),
        Gold = Color3.fromRGB(255, 215, 0),
        Platinum = Color3.fromRGB(229, 228, 226)
    }
    
    local tierBadge = Instance.new("Frame")
    tierBadge.Size = UDim2.new(0, 80, 0, 25)
    tierBadge.Position = UDim2.new(1, -90, 0.5, -12.5)
    tierBadge.BackgroundColor3 = tierColors[achievement.tier] or self._config.COLORS.Primary
    tierBadge.BackgroundTransparency = achievement.unlocked and 0 or 0.5
    tierBadge.Parent = card
    
    self._utilities.CreateCorner(tierBadge, 12)
    
    local tierLabel = self._uiFactory:CreateLabel(tierBadge, {
        text = achievement.tier,
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 12
    })
    
    return card
end

function SocialUI:CreateProfileBadges(parent: Frame, player: Player)
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, 0, 1, 0)
    })
    
    local badgeContainer = Instance.new("Frame")
    badgeContainer.Size = UDim2.new(1, -20, 0, 100)
    badgeContainer.BackgroundTransparency = 1
    badgeContainer.Parent = scrollFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.Parent = badgeContainer
    
    self._utilities.CreatePadding(badgeContainer, 10)
    
    -- Sample badges
    local badges = {
        {name = "Beta Tester", icon = "🎮", description = "Joined during beta", owned = true},
        {name = "VIP", icon = "⭐", description = "VIP member", owned = true},
        {name = "Collector", icon = "🏆", description = "Collected 100 pets", owned = false},
        {name = "Trader", icon = "🤝", description = "Completed 50 trades", owned = false}
    }
    
    for _, badge in ipairs(badges) do
        local badgeCard = self:CreateBadgeCard(badgeContainer, badge)
    end
    
    -- Update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function SocialUI:CreateBadgeCard(parent: Frame, badge: table): Frame
    local card = Instance.new("Frame")
    card.BackgroundColor3 = badge.owned and self._config.COLORS.White or 
                           Color3.fromRGB(230, 230, 230)
    card.BackgroundTransparency = badge.owned and 0 or 0.5
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    self._utilities.CreatePadding(card, 10)
    
    -- Icon
    local iconLabel = self._uiFactory:CreateLabel(card, {
        text = badge.icon,
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 10),
        textSize = 32,
        textTransparency = badge.owned and 0 or 0.5
    })
    
    -- Name
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = badge.name,
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 55),
        font = self._config.FONTS.Secondary,
        textColor = badge.owned and self._config.COLORS.Dark or Color3.fromRGB(150, 150, 150),
        textWrapped = true,
        textSize = 12
    })
    
    -- Description
    local descLabel = self._uiFactory:CreateLabel(card, {
        text = badge.description,
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 75),
        textColor = self._config.COLORS.TextSecondary,
        textWrapped = true,
        textSize = 10
    })
    
    -- Lock overlay
    if not badge.owned then
        local lockIcon = self._uiFactory:CreateLabel(card, {
            text = "🔒",
            size = UDim2.new(1, 0, 1, 0),
            textTransparency = 0.7,
            textSize = 48,
            zIndex = card.ZIndex + 1
        })
    end
    
    return card
end

-- ========================================
-- CLAN VIEW
-- ========================================

function SocialUI:CreateClanView(parent: Frame)
    local playerData = self._dataCache and self._dataCache:Get() or {}
    
    if playerData.clan and playerData.clan.id then
        self:CreateClanInterface(parent)
    else
        self:CreateNoClanInterface(parent)
    end
end

function SocialUI:CreateNoClanInterface(parent: Frame)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Welcome message
    local welcomeFrame = Instance.new("Frame")
    welcomeFrame.Size = UDim2.new(1, -40, 0, 200)
    welcomeFrame.Position = UDim2.new(0, 20, 0, 20)
    welcomeFrame.BackgroundColor3 = self._config.COLORS.Primary
    welcomeFrame.Parent = container
    
    self._utilities.CreateCorner(welcomeFrame, 12)
    
    local welcomeLabel = self._uiFactory:CreateLabel(welcomeFrame, {
        text = "⚔️ Join or Create a Clan! ⚔️",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 30),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 28
    })
    
    local descLabel = self._uiFactory:CreateLabel(welcomeFrame, {
        text = "Team up with other players, participate in clan battles, and earn exclusive rewards!",
        size = UDim2.new(1, -40, 0, 60),
        position = UDim2.new(0, 20, 0, 80),
        textColor = self._config.COLORS.White,
        textWrapped = true,
        textSize = 16
    })
    
    -- Action buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, -40, 0, 60)
    buttonFrame.Position = UDim2.new(0, 20, 0, 240)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = container
    
    local createButton = self._uiFactory:CreateButton(buttonFrame, {
        text = "Create Clan",
        size = UDim2.new(0.48, 0, 1, 0),
        backgroundColor = self._config.COLORS.Success,
        textSize = 18,
        callback = function()
            self:ShowCreateClanDialog()
        end
    })
    
    local browseButton = self._uiFactory:CreateButton(buttonFrame, {
        text = "Browse Clans",
        size = UDim2.new(0.48, 0, 1, 0),
        position = UDim2.new(0.52, 0, 0, 0),
        backgroundColor = self._config.COLORS.Secondary,
        textSize = 18,
        callback = function()
            self:ShowClanBrowser()
        end
    })
    
    -- Benefits list
    local benefitsFrame = Instance.new("Frame")
    benefitsFrame.Size = UDim2.new(1, -40, 1, -320)
    benefitsFrame.Position = UDim2.new(0, 20, 0, 320)
    benefitsFrame.BackgroundColor3 = self._config.COLORS.White
    benefitsFrame.Parent = container
    
    self._utilities.CreateCorner(benefitsFrame, 12)
    self._utilities.CreatePadding(benefitsFrame, 20)
    
    local benefitsTitle = self._uiFactory:CreateLabel(benefitsFrame, {
        text = "Clan Benefits",
        size = UDim2.new(1, 0, 0, 30),
        font = self._config.FONTS.Secondary,
        textSize = 20
    })
    
    local benefits = {
        "🏆 Participate in clan wars and tournaments",
        "💰 Share resources in clan treasury",
        "🎁 Exclusive clan rewards and bonuses",
        "💬 Private clan chat and communication",
        "🤝 Trade freely with clan members",
        "⭐ Earn clan experience and level up together"
    }
    
    local yOffset = 40
    for _, benefit in ipairs(benefits) do
        local benefitLabel = self._uiFactory:CreateLabel(benefitsFrame, {
            text = benefit,
            size = UDim2.new(1, 0, 0, 25),
            position = UDim2.new(0, 0, 0, yOffset),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.TextSecondary,
            textSize = 14
        })
        yOffset = yOffset + 30
    end
end

function SocialUI:CreateClanInterface(parent: Frame)
    -- Load clan data
    local playerData = self._dataCache and self._dataCache:Get() or {}
    local clanData = self.CurrentClan or {}
    
    -- Clan header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 100)
    headerFrame.BackgroundColor3 = clanData.color or self._config.COLORS.Primary
    headerFrame.Parent = parent
    
    self._utilities.CreateCorner(headerFrame, 12)
    
    -- Clan icon
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 80, 0, 80)
    iconFrame.Position = UDim2.new(0, 20, 0.5, -40)
    iconFrame.BackgroundColor3 = self._config.COLORS.White
    iconFrame.Parent = headerFrame
    
    self._utilities.CreateCorner(iconFrame, 40)
    
    local iconLabel = self._uiFactory:CreateLabel(iconFrame, {
        text = clanData.icon or "⚔️",
        size = UDim2.new(1, 0, 1, 0),
        textSize = 48
    })
    
    -- Clan info
    local clanName = self._uiFactory:CreateLabel(headerFrame, {
        text = clanData.name or "My Clan",
        size = UDim2.new(0.5, -120, 0, 35),
        position = UDim2.new(0, 110, 0, 15),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24
    })
    
    local clanTag = self._uiFactory:CreateLabel(headerFrame, {
        text = "[" .. (clanData.tag or "TAG") .. "]",
        size = UDim2.new(0.5, -120, 0, 20),
        position = UDim2.new(0, 110, 0, 50),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.White,
        textTransparency = 0.3,
        textSize = 16
    })
    
    -- Clan stats
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0.5, -20, 1, -20)
    statsFrame.Position = UDim2.new(0.5, 10, 0, 10)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = headerFrame
    
    local levelLabel = self._uiFactory:CreateLabel(statsFrame, {
        text = "Level " .. (clanData.level or 1),
        size = UDim2.new(0.33, 0, 0, 25),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 16
    })
    
    local membersLabel = self._uiFactory:CreateLabel(statsFrame, {
        text = (clanData.memberCount or 1) .. "/" .. (clanData.maxMembers or 50) .. " Members",
        size = UDim2.new(0.33, 0, 0, 25),
        position = UDim2.new(0.33, 0, 0, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 16
    })
    
    local treasuryLabel = self._uiFactory:CreateLabel(statsFrame, {
        text = "💰 " .. self._utilities.FormatNumber(clanData.treasury or 0),
        size = UDim2.new(0.33, 0, 0, 25),
        position = UDim2.new(0.67, 0, 0, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 16
    })
    
    -- Experience bar
    local expBar = self._uiFactory:CreateProgressBar(statsFrame, {
        size = UDim2.new(1, 0, 0, 10),
        position = UDim2.new(0, 0, 0, 35),
        value = clanData.experience or 0,
        maxValue = self:GetClanExpRequired(clanData.level or 1),
        fillColor = self._config.COLORS.Success
    })
    
    -- Clan content tabs
    self:CreateClanTabs(parent)
end

function SocialUI:CreateClanTabs(parent: Frame)
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 1, -110)
    tabFrame.Position = UDim2.new(0, 0, 0, 110)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = parent
    
    local clanTabs = {
        {name = "Members", icon = "👥"},
        {name = "Chat", icon = "💬"},
        {name = "Treasury", icon = "💰"},
        {name = "Settings", icon = "⚙️"}
    }
    
    -- Tab implementation similar to profile tabs
    -- Would include member list, clan chat, treasury management, and clan settings
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function SocialUI:RefreshContent(force: boolean?)
    if not force and tick() - self.LastRefresh < 5 then
        return -- Prevent spam refresh
    end
    
    self.LastRefresh = tick()
    
    if self.CurrentTab == "leaderboard" then
        for id, _ in pairs(self.LeaderboardContainers) do
            self:FetchLeaderboardData(id)
        end
    elseif self.CurrentTab == "clan" and self.CurrentClan then
        self:RefreshClanData()
    end
    
    -- Play refresh sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Refresh")
    end
end

function SocialUI:StartRefreshTimer()
    self:StopRefreshTimer()
    
    self.RefreshTimer = task.spawn(function()
        while self.Frame and self.Frame.Parent do
            task.wait(REFRESH_INTERVAL)
            self:RefreshContent()
        end
    end)
end

function SocialUI:StopRefreshTimer()
    if self.RefreshTimer then
        task.cancel(self.RefreshTimer)
        self.RefreshTimer = nil
    end
end

function SocialUI:ShowProfile(playerId: number)
    -- Create profile window overlay
    if self._remoteManager then
        local profileData = self._remoteManager:InvokeServer("GetPlayerProfile", playerId)
        
        if profileData then
            -- Create profile window
            -- Similar to main profile view but in a popup
        end
    end
end

function SocialUI:SendFriendRequest(player: Player)
    if self._remoteManager then
        local success = self._remoteManager:InvokeServer("SendFriendRequest", player.UserId)
        
        if success then
            self._notificationSystem:SendNotification("Friend Request", 
                "Friend request sent to " .. player.DisplayName, "success")
        end
    end
end

function SocialUI:ShowCreateClanDialog()
    -- Create clan creation dialog
    -- Would include name, tag, color, icon selection
end

function SocialUI:ShowClanBrowser()
    -- Show list of available clans to join
end

function SocialUI:CountPets(pets: table?): number
    if not pets then return 0 end
    
    local count = 0
    for _ in pairs(pets) do
        count = count + 1
    end
    return count
end

function SocialUI:CountAchievements(achievements: table?): number
    if not achievements then return 0 end
    
    local count = 0
    for _, achieved in pairs(achievements) do
        if achieved then
            count = count + 1
        end
    end
    return count
end

function SocialUI:FormatPlayTime(seconds: number): string
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if hours > 0 then
        return string.format("%.1fh", hours + minutes/60)
    else
        return string.format("%dm", minutes)
    end
end

function SocialUI:GetClanExpRequired(level: number): number
    return level * 1000 + (level - 1) * 500
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

function SocialUI:OnLeaderboardUpdate(data: table)
    if data.type and self.LeaderboardContainers[data.type] then
        self:UpdateLeaderboard(data.type, data)
    end
end

function SocialUI:OnClanUpdate(clan: Clan)
    self.CurrentClan = clan
    
    -- Refresh clan interface if open
    if self.Frame and self.Frame.Visible and self.CurrentTab == "clan" then
        self:CreateClanView(self.TabFrames["Clan"])
    end
end

function SocialUI:OnClanInvite(invite: table)
    self._notificationSystem:SendNotification("Clan Invite", 
        "You've been invited to join " .. invite.clanName, "info", 10,
        {
            {
                text = "Accept",
                callback = function()
                    self:AcceptClanInvite(invite.clanId)
                end
            },
            {
                text = "Decline",
                callback = function()
                    self:DeclineClanInvite(invite.clanId)
                end
            }
        }
    )
end

function SocialUI:OnMemberJoined(member: ClanMember)
    if self.CurrentClan then
        self.CurrentClan.memberCount = (self.CurrentClan.memberCount or 0) + 1
        
        -- Show notification
        self._notificationSystem:SendNotification("New Member", 
            member.username .. " joined the clan!", "success")
    end
end

function SocialUI:OnMemberLeft(playerId: number)
    if self.CurrentClan then
        self.CurrentClan.memberCount = math.max(0, (self.CurrentClan.memberCount or 0) - 1)
    end
end

function SocialUI:AcceptClanInvite(clanId: string)
    if self._remoteManager then
        local success = self._remoteManager:InvokeServer("AcceptClanInvite", clanId)
        
        if success then
            self._notificationSystem:SendNotification("Clan Joined", 
                "Welcome to your new clan!", "success")
        end
    end
end

function SocialUI:DeclineClanInvite(clanId: string)
    if self._remoteManager then
        self._remoteManager:FireServer("DeclineClanInvite", clanId)
    end
end

function SocialUI:RefreshClanData()
    if self._remoteManager and self.CurrentClan then
        local clanData = self._remoteManager:InvokeServer("GetClanData", self.CurrentClan.id)
        
        if clanData then
            self.CurrentClan = clanData
            self:OnClanUpdate(clanData)
        end
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function SocialUI:Destroy()
    self:StopRefreshTimer()
    self:Close()
    
    -- Clear references
    self.Frame = nil
    self.TabFrames = {}
    self.LeaderboardContainers = {}
    self.ProfileWindow = nil
    self.ClanInterface = nil
    self.CurrentClan = nil
    self.LeaderboardCache = {}
end

return SocialUI