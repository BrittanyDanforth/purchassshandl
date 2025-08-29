--[[
    Module: QuestUI
    Description: Comprehensive quest interface with daily/weekly quests, progress tracking,
                 rewards system, and achievement display
    Features: Quest cards with progress bars, reward previews, claim animations,
              achievement tiers, quest categories, real-time updates
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local QuestUI = {}
QuestUI.__index = QuestUI

-- ========================================
-- TYPES
-- ========================================

type Quest = {
    id: string,
    name: string,
    description: string,
    type: "daily" | "weekly" | "special",
    category: string,
    progress: number,
    target: number,
    rewards: {
        coins: number?,
        gems: number?,
        tickets: number?,
        items: {string}?,
        experience: number?
    },
    completed: boolean,
    claimed: boolean,
    expiresAt: number?,
    icon: string?
}

type Achievement = {
    id: string,
    name: string,
    description: string,
    icon: string,
    tier: "Bronze" | "Silver" | "Gold" | "Platinum" | "Diamond",
    category: string,
    progress: number,
    target: number,
    unlocked: boolean,
    unlockedAt: number?,
    rewards: {
        title: string?,
        badge: string?,
        coins: number?,
        gems: number?
    }
}

-- ========================================
-- CONSTANTS
-- ========================================

local QUEST_CARD_HEIGHT = 120
local ACHIEVEMENT_CARD_HEIGHT = 80
local PROGRESS_BAR_HEIGHT = 20
local CLAIM_ANIMATION_TIME = 0.5
local REFRESH_COOLDOWN = 1 -- Prevent spam refreshing

-- Quest categories
local QUEST_CATEGORIES = {
    battle = {name = "Battle", icon = "⚔️", color = Config.COLORS.Error},
    collection = {name = "Collection", icon = "🐾", color = Config.COLORS.Primary},
    trading = {name = "Trading", icon = "🤝", color = Config.COLORS.Success},
    spending = {name = "Economy", icon = "💰", color = Config.COLORS.Warning},
    social = {name = "Social", icon = "👥", color = Config.COLORS.Info}
}

-- Achievement tiers
local ACHIEVEMENT_TIERS = {
    Bronze = {color = Color3.fromRGB(205, 127, 50), icon = "🥉", points = 10},
    Silver = {color = Color3.fromRGB(192, 192, 192), icon = "🥈", points = 25},
    Gold = {color = Color3.fromRGB(255, 215, 0), icon = "🥇", points = 50},
    Platinum = {color = Color3.fromRGB(229, 228, 226), icon = "💎", points = 100},
    Diamond = {color = Color3.fromRGB(185, 242, 255), icon = "💠", points = 250}
}

-- ========================================
-- INITIALIZATION
-- ========================================

function QuestUI.new(dependencies)
    local self = setmetatable({}, QuestUI)
    
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
    self.DailyQuestContainer = nil
    self.WeeklyQuestContainer = nil
    self.AchievementContainer = nil
    self.QuestCards = {}
    self.AchievementCards = {}
    
    -- State
    self.LastRefresh = 0
    self.ClaimingQuests = {}
    self.FilteredCategory = nil
    self.SortOrder = "progress" -- progress, rewards, name
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function QuestUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Quest updates
    self._eventBus:On("QuestProgressUpdated", function(data)
        self:OnQuestProgressUpdate(data)
    end)
    
    self._eventBus:On("QuestCompleted", function(questId)
        self:OnQuestCompleted(questId)
    end)
    
    self._eventBus:On("QuestClaimed", function(data)
        self:OnQuestClaimed(data)
    end)
    
    self._eventBus:On("NewQuestAvailable", function(quest)
        self:OnNewQuest(quest)
    end)
    
    -- Achievement updates
    self._eventBus:On("AchievementUnlocked", function(achievement)
        self:OnAchievementUnlocked(achievement)
    end)
    
    self._eventBus:On("AchievementProgress", function(data)
        self:OnAchievementProgress(data)
    end)
    
    -- Data updates
    self._eventBus:On("DataUpdated", function(path)
        if path:match("quests") or path:match("achievements") then
            self:RefreshDisplay()
        end
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function QuestUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshQuests()
        return
    end
    
    -- Create UI
    self:CreateUI()
    
    -- Load data
    self:RefreshQuests()
end

function QuestUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
    
    -- Notify window manager
    if self._windowManager then
        self._windowManager:CloseWindow("QuestUI")
    end
    
    -- Fire close event
    if self._eventBus then
        self._eventBus:Fire("QuestClosed")
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function QuestUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                   (self._windowManager and self._windowManager.GetMainPanel and self._windowManager:GetMainPanel()) or 
                   Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[QuestUI] No parent container found")
        return
    end
    
    -- Create main frame
    self.Frame = self._uiFactory:CreateFrame(parent, {
        name = "QuestFrame",
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

function QuestUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "📜 Quest Board 📜",
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
            self:RefreshQuests(true)
        end
    })
end

function QuestUI:CreateTabs()
    local tabs = {
        {
            name = "Daily Quests",
            callback = function(frame)
                self:CreateQuestList(frame, "daily")
            end
        },
        {
            name = "Weekly Quests", 
            callback = function(frame)
                self:CreateQuestList(frame, "weekly")
            end
        },
        {
            name = "Achievements",
            callback = function(frame)
                self:CreateAchievementList(frame)
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
                
                -- Refresh data when switching tabs
                if tab.name:match("Quests") then
                    self:RefreshQuests()
                elseif tab.name == "Achievements" then
                    self:RefreshAchievements()
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
-- QUEST LIST
-- ========================================

function QuestUI:CreateQuestList(parent: Frame, questType: string)
    -- Filter bar
    local filterBar = self:CreateQuestFilterBar(parent)
    
    -- Scroll frame
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, 0, 1, -50),
        position = UDim2.new(0, 0, 0, 50)
    })
    
    local questContainer = Instance.new("Frame")
    questContainer.Name = "QuestContainer"
    questContainer.Size = UDim2.new(1, -20, 0, 100)
    questContainer.BackgroundTransparency = 1
    questContainer.Parent = scrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = questContainer
    
    self._utilities.CreatePadding(questContainer, 10)
    
    -- Store reference
    if questType == "daily" then
        self.DailyQuestContainer = questContainer
    else
        self.WeeklyQuestContainer = questContainer
    end
    
    -- Update canvas size when content changes
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Add empty state
    self:CreateEmptyState(questContainer, questType)
end

function QuestUI:CreateQuestFilterBar(parent: Frame): Frame
    local filterBar = Instance.new("Frame")
    filterBar.Size = UDim2.new(1, 0, 0, 40)
    filterBar.BackgroundTransparency = 1
    filterBar.Parent = parent
    
    -- Category filter
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(0.5, -5, 1, 0)
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Parent = filterBar
    
    local categoryLabel = self._uiFactory:CreateLabel(categoryFrame, {
        text = "Category:",
        size = UDim2.new(0, 70, 1, 0),
        textXAlignment = Enum.TextXAlignment.Left
    })
    
    local categories = {"All"}
    for key, cat in pairs(QUEST_CATEGORIES) do
        table.insert(categories, cat.name)
    end
    
    local categoryDropdown = self._uiFactory:CreateDropdown(categoryFrame, categories, "All", {
        size = UDim2.new(1, -80, 0, 30),
        position = UDim2.new(0, 80, 0.5, -15),
        callback = function(selected)
            self.FilteredCategory = selected == "All" and nil or selected
            self:ApplyQuestFilters()
        end
    })
    
    -- Sort options
    local sortFrame = Instance.new("Frame")
    sortFrame.Size = UDim2.new(0.5, -5, 1, 0)
    sortFrame.Position = UDim2.new(0.5, 5, 0, 0)
    sortFrame.BackgroundTransparency = 1
    sortFrame.Parent = filterBar
    
    local sortLabel = self._uiFactory:CreateLabel(sortFrame, {
        text = "Sort by:",
        size = UDim2.new(0, 60, 1, 0),
        textXAlignment = Enum.TextXAlignment.Left
    })
    
    local sortDropdown = self._uiFactory:CreateDropdown(sortFrame, {
        options = {"Progress", "Rewards", "Name"},
        default = "Progress",
        size = UDim2.new(1, -70, 0, 30),
        position = UDim2.new(0, 70, 0.5, -15),
        callback = function(selected)
            self.SortOrder = selected:lower()
            self:ApplyQuestFilters()
        end
    })
    
    return filterBar
end

function QuestUI:CreateEmptyState(parent: Frame, questType: string)
    local emptyFrame = Instance.new("Frame")
    emptyFrame.Name = "EmptyState"
    emptyFrame.Size = UDim2.new(1, 0, 0, 200)
    emptyFrame.BackgroundTransparency = 1
    emptyFrame.Parent = parent
    
    local emptyIcon = self._uiFactory:CreateLabel(emptyFrame, {
        text = "📋",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0, 20),
        textSize = 48,
        textTransparency = 0.5
    })
    
    local emptyText = self._uiFactory:CreateLabel(emptyFrame, {
        text = "No " .. questType .. " quests available",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 90),
        textColor = self._config.COLORS.TextSecondary,
        textSize = 18
    })
    
    local refreshHint = self._uiFactory:CreateLabel(emptyFrame, {
        text = "Check back later for new quests!",
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 130),
        textColor = self._config.COLORS.TextSecondary,
        textSize = 14
    })
end

-- ========================================
-- QUEST CARD
-- ========================================

function QuestUI:CreateQuestCard(parent: Frame, quest: Quest): Frame
    local card = Instance.new("Frame")
    card.Name = quest.id
    card.Size = UDim2.new(1, 0, 0, QUEST_CARD_HEIGHT)
    card.BackgroundColor3 = self._config.COLORS.White
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    self._utilities.CreatePadding(card, 15)
    
    -- Store reference
    self.QuestCards[quest.id] = card
    
    -- Completion status bar
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(0, 5, 1, -10)
    statusBar.Position = UDim2.new(0, 0, 0, 5)
    statusBar.BackgroundColor3 = quest.completed and self._config.COLORS.Success or self._config.COLORS.Warning
    statusBar.BorderSizePixel = 0
    statusBar.Parent = card
    
    self._utilities.CreateCorner(statusBar, 2)
    
    -- Category icon
    local category = self:GetQuestCategory(quest)
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 50, 0, 50)
    iconFrame.Position = UDim2.new(0, 15, 0.5, -25)
    iconFrame.BackgroundColor3 = category.color
    iconFrame.Parent = card
    
    self._utilities.CreateCorner(iconFrame, 25)
    
    local iconLabel = self._uiFactory:CreateLabel(iconFrame, {
        text = category.icon,
        size = UDim2.new(1, 0, 1, 0),
        textSize = 24
    })
    
    -- Quest info
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -250, 1, -20)
    infoFrame.Position = UDim2.new(0, 75, 0, 10)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = card
    
    -- Quest name
    local nameLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = quest.name,
        size = UDim2.new(1, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textSize = 18
    })
    
    -- Quest description
    local descLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = quest.description,
        size = UDim2.new(1, 0, 0, 35),
        position = UDim2.new(0, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textWrapped = true,
        textSize = 14
    })
    
    -- Progress bar
    local progressFrame = self:CreateQuestProgressBar(infoFrame, quest)
    progressFrame.Position = UDim2.new(0, 0, 1, -25)
    
    -- Rewards section
    local rewardsFrame = self:CreateQuestRewards(card, quest)
    
    -- Action button
    if quest.completed and not quest.claimed then
        local claimButton = self._uiFactory:CreateButton(card, {
            text = "Claim",
            size = UDim2.new(0, 100, 0, 35),
            position = UDim2.new(1, -115, 1, -45),
            backgroundColor = self._config.COLORS.Success,
            callback = function()
                self:ClaimQuest(quest)
            end
        })
        
        -- Add glow effect for claimable quests
        if self._effectsLibrary then
            self._effectsLibrary:CreateGlowEffect(claimButton, {
                color = self._config.COLORS.Success,
                size = 15
            })
        end
    elseif quest.claimed then
        local claimedLabel = self._uiFactory:CreateLabel(card, {
            text = "✓ Claimed",
            size = UDim2.new(0, 100, 0, 35),
            position = UDim2.new(1, -115, 1, -45),
            textColor = self._config.COLORS.Success,
            font = self._config.FONTS.Secondary
        })
    end
    
    -- Expiry timer for time-limited quests
    if quest.expiresAt then
        self:CreateExpiryTimer(card, quest.expiresAt)
    end
    
    -- Add hover effects
    self:AddQuestCardEffects(card, quest)
    
    return card
end

function QuestUI:CreateQuestProgressBar(parent: Frame, quest: Quest): Frame
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressBar"
    progressFrame.Size = UDim2.new(1, 0, 0, PROGRESS_BAR_HEIGHT)
    progressFrame.BackgroundColor3 = self._config.COLORS.Surface
    progressFrame.Parent = parent
    
    self._utilities.CreateCorner(progressFrame, 10)
    
    -- Add inner shadow for depth
    local innerShadow = Instance.new("Frame")
    innerShadow.Size = UDim2.new(1, -4, 1, -4)
    innerShadow.Position = UDim2.new(0, 2, 0, 2)
    innerShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    innerShadow.BackgroundTransparency = 0.9
    innerShadow.ZIndex = progressFrame.ZIndex + 1
    innerShadow.Parent = progressFrame
    self._utilities.CreateCorner(innerShadow, 8)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0) -- Start at 0 for animation
    fill.BackgroundColor3 = quest.completed and self._config.COLORS.Success or self._config.COLORS.Primary
    fill.BorderSizePixel = 0
    fill.ZIndex = progressFrame.ZIndex + 2
    fill.Parent = progressFrame
    
    self._utilities.CreateCorner(fill, 10)
    
    -- Add gradient for premium look
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1.2, 1.2, 1.2)),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8))
    })
    gradient.Parent = fill
    
    -- Add milestone markers
    local milestones = {0.25, 0.5, 0.75}
    for _, milestone in ipairs(milestones) do
        local marker = Instance.new("Frame")
        marker.Size = UDim2.new(0, 2, 1, 0)
        marker.Position = UDim2.new(milestone, -1, 0, 0)
        marker.BackgroundColor3 = self._config.COLORS.Dark
        marker.BackgroundTransparency = 0.5
        marker.ZIndex = progressFrame.ZIndex + 3
        marker.Parent = progressFrame
    end
    
    -- Animate fill on creation
    local targetSize = math.min(quest.progress / quest.target, 1)
    task.defer(function()
        self._utilities.Tween(fill, {
            Size = UDim2.new(targetSize, 0, 1, 0)
        }, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        
        -- Add pulse effect if completed
        if quest.completed then
            task.wait(0.8)
            self:AddCompletedPulse(fill)
        end
    end)
    
    -- Progress text with animated counter
    local progressText = self._uiFactory:CreateLabel(progressFrame, {
        text = "0%",
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Numbers,
        textSize = 12,
        zIndex = progressFrame.ZIndex + 4
    })
    
    -- Store references for updates
    progressFrame:SetAttribute("QuestId", quest.id)
    progressFrame:SetAttribute("LastProgress", 0)
    
    -- Animate percentage text
    task.defer(function()
        self:AnimateProgressText(progressText, 0, quest.progress, quest.target)
    end)
    
    return progressFrame
end

function QuestUI:AnimateProgressText(label: TextLabel, fromProgress: number, toProgress: number, target: number)
    local startTime = tick()
    local duration = 0.8
    
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Ease out quint
        progress = 1 - math.pow(1 - progress, 5)
        
        local currentProgress = fromProgress + (toProgress - fromProgress) * progress
        local percentage = math.floor((currentProgress / target) * 100)
        
        label.Text = string.format("%d%% (%d/%d)", percentage, math.floor(currentProgress), target)
        
        if progress >= 1 then
            connection:Disconnect()
        end
    end)
end

function QuestUI:AddCompletedPulse(fill: Frame)
    -- Create pulse effect for completed quests
    local pulseFrame = Instance.new("Frame")
    pulseFrame.Size = UDim2.new(1, 0, 1, 0)
    pulseFrame.BackgroundColor3 = self._config.COLORS.Success
    pulseFrame.BackgroundTransparency = 0.5
    pulseFrame.ZIndex = fill.ZIndex + 1
    pulseFrame.Parent = fill
    
    self._utilities.CreateCorner(pulseFrame, 10)
    
    -- Pulse animation
    task.spawn(function()
        while pulseFrame.Parent do
            self._utilities.Tween(pulseFrame, {
                BackgroundTransparency = 0.8
            }, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
            task.wait(0.5)
            self._utilities.Tween(pulseFrame, {
                BackgroundTransparency = 0.5
            }, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
            task.wait(0.5)
        end
    end)
end

function QuestUI:CreateQuestRewards(parent: Frame, quest: Quest): Frame
    local rewardsFrame = Instance.new("Frame")
    rewardsFrame.Size = UDim2.new(0, 120, 1, -30)
    rewardsFrame.Position = UDim2.new(1, -130, 0, 15)
    rewardsFrame.BackgroundTransparency = 1
    rewardsFrame.Parent = parent
    
    local rewardsLabel = self._uiFactory:CreateLabel(rewardsFrame, {
        text = "Rewards:",
        size = UDim2.new(1, 0, 0, 20),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.TextSecondary,
        textSize = 14
    })
    
    local rewardY = 25
    
    -- Display rewards with icons
    if quest.rewards.coins then
        local coinReward = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "💰 " .. self._utilities.FormatNumber(quest.rewards.coins),
            size = UDim2.new(1, 0, 0, 18),
            position = UDim2.new(0, 0, 0, rewardY),
            textColor = self._config.COLORS.Warning,
            textSize = 12
        })
        rewardY = rewardY + 18
    end
    
    if quest.rewards.gems then
        local gemReward = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "💎 " .. self._utilities.FormatNumber(quest.rewards.gems),
            size = UDim2.new(1, 0, 0, 18),
            position = UDim2.new(0, 0, 0, rewardY),
            textColor = self._config.COLORS.Info,
            textSize = 12
        })
        rewardY = rewardY + 18
    end
    
    if quest.rewards.tickets then
        local ticketReward = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "🎟️ " .. self._utilities.FormatNumber(quest.rewards.tickets),
            size = UDim2.new(1, 0, 0, 18),
            position = UDim2.new(0, 0, 0, rewardY),
            textColor = self._config.COLORS.Secondary,
            textSize = 12
        })
        rewardY = rewardY + 18
    end
    
    if quest.rewards.experience then
        local expReward = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "⭐ " .. self._utilities.FormatNumber(quest.rewards.experience) .. " XP",
            size = UDim2.new(1, 0, 0, 18),
            position = UDim2.new(0, 0, 0, rewardY),
            textColor = self._config.COLORS.Accent,
            textSize = 12
        })
        rewardY = rewardY + 18
    end
    
    if quest.rewards.items and #quest.rewards.items > 0 then
        local itemReward = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "📦 " .. #quest.rewards.items .. " item" .. (#quest.rewards.items > 1 and "s" or ""),
            size = UDim2.new(1, 0, 0, 18),
            position = UDim2.new(0, 0, 0, rewardY),
            textColor = self._config.COLORS.Primary,
            textSize = 12
        })
    end
    
    return rewardsFrame
end

function QuestUI:CreateExpiryTimer(parent: Frame, expiresAt: number)
    local timerLabel = self._uiFactory:CreateLabel(parent, {
        text = "",
        size = UDim2.new(0, 100, 0, 20),
        position = UDim2.new(1, -110, 0, 10),
        textColor = self._config.COLORS.Error,
        font = self._config.FONTS.Numbers,
        textSize = 12
    })
    
    -- Update timer
    spawn(function()
        while parent.Parent and expiresAt > os.time() do
            local timeLeft = expiresAt - os.time()
            timerLabel.Text = "⏰ " .. self:FormatTimeLeft(timeLeft)
            
            -- Change color based on urgency
            if timeLeft < 3600 then -- Less than 1 hour
                timerLabel.TextColor3 = self._config.COLORS.Error
            elseif timeLeft < 86400 then -- Less than 1 day
                timerLabel.TextColor3 = self._config.COLORS.Warning
            else
                timerLabel.TextColor3 = self._config.COLORS.TextSecondary
            end
            
            task.wait(1)
        end
        
        -- Quest expired
        if parent.Parent then
            timerLabel.Text = "⏰ Expired"
            timerLabel.TextColor3 = self._config.COLORS.Error
        end
    end)
end

function QuestUI:AddQuestCardEffects(card: Frame, quest: Quest)
    local originalColor = card.BackgroundColor3
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        self._utilities.Tween(card, {
            BackgroundColor3 = self._config.COLORS.Surface
        }, self._config.TWEEN_INFO.Fast)
        
        -- Scale effect
        if self._animationSystem then
            self._animationSystem:PlayAnimation("HoverScale", {
                target = card,
                scale = 1.02
            })
        end
    end)
    
    card.MouseLeave:Connect(function()
        self._utilities.Tween(card, {
            BackgroundColor3 = originalColor
        }, self._config.TWEEN_INFO.Fast)
        
        if self._animationSystem then
            self._animationSystem:PlayAnimation("HoverScale", {
                target = card,
                scale = 1
            })
        end
    end)
end

-- ========================================
-- QUEST ACTIONS
-- ========================================

function QuestUI:ClaimQuest(quest: Quest)
    if self.ClaimingQuests[quest.id] then return end
    self.ClaimingQuests[quest.id] = true
    
    -- Send claim request
    if self._remoteManager then
        local success, result = self._remoteManager:InvokeServer("ClaimQuest", quest.id)
        
        if success then
            -- Play claim animation
            self:PlayClaimAnimation(quest)
            
            -- Update quest state
            quest.claimed = true
            
            -- Refresh the card
            self:RefreshQuestCard(quest)
            
            -- Show rewards notification
            self:ShowRewardsNotification(quest.rewards)
            
            -- Play sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("QuestComplete")
            end
            
            -- Update currencies if needed
            if self._eventBus then
                self._eventBus:Fire("CurrencyUpdated", result.currencies)
            end
        else
            self._notificationSystem:SendNotification("Error", 
                result or "Failed to claim quest", "error")
        end
    end
    
    self.ClaimingQuests[quest.id] = false
end

function QuestUI:PlayClaimAnimation(quest: Quest)
    local card = self.QuestCards[quest.id]
    if not card then return end
    
    -- Create reward particles
    if self._particleSystem then
        self._particleSystem:CreateBurst(card, "coin", 
            UDim2.new(0.5, 0, 0.5, 0), 20)
    end
    
    -- Fade and slide animation
    if self._animationSystem then
        self._animationSystem:PlayAnimation("ClaimReward", {
            target = card,
            onComplete = function()
                -- Update card appearance
                local statusBar = card:FindFirstChild("StatusBar")
                if statusBar then
                    self._utilities.Tween(statusBar, {
                        BackgroundColor3 = self._config.COLORS.Success
                    }, self._config.TWEEN_INFO.Normal)
                end
            end
        })
    end
end

function QuestUI:ShowRewardsNotification(rewards: table)
    local rewardText = "Quest Complete! Rewards: "
    local rewardParts = {}
    
    if rewards.coins then
        table.insert(rewardParts, "💰 " .. self._utilities.FormatNumber(rewards.coins))
    end
    
    if rewards.gems then
        table.insert(rewardParts, "💎 " .. self._utilities.FormatNumber(rewards.gems))
    end
    
    if rewards.tickets then
        table.insert(rewardParts, "🎟️ " .. self._utilities.FormatNumber(rewards.tickets))
    end
    
    if rewards.experience then
        table.insert(rewardParts, "⭐ " .. self._utilities.FormatNumber(rewards.experience) .. " XP")
    end
    
    rewardText = rewardText .. table.concat(rewardParts, ", ")
    
    self._notificationSystem:SendNotification("Quest Complete!", rewardText, "success", 5)
end

-- ========================================
-- ACHIEVEMENTS
-- ========================================

function QuestUI:CreateAchievementList(parent: Frame)
    -- Achievement stats
    local statsBar = self:CreateAchievementStats(parent)
    
    -- Filter bar
    local filterBar = self:CreateAchievementFilterBar(parent)
    
    -- Scroll frame
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, 0, 1, -130),
        position = UDim2.new(0, 0, 0, 130)
    })
    
    local achievementContainer = Instance.new("Frame")
    achievementContainer.Name = "AchievementContainer"
    achievementContainer.Size = UDim2.new(1, -20, 0, 100)
    achievementContainer.BackgroundTransparency = 1
    achievementContainer.Parent = scrollFrame
    
    self.AchievementContainer = achievementContainer
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = achievementContainer
    
    self._utilities.CreatePadding(achievementContainer, 10)
    
    -- Update canvas size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

function QuestUI:CreateAchievementStats(parent: Frame): Frame
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, 0, 0, 70)
    statsFrame.BackgroundColor3 = self._config.COLORS.Surface
    statsFrame.Parent = parent
    
    self._utilities.CreateCorner(statsFrame, 12)
    self._utilities.CreatePadding(statsFrame, 15)
    
    -- Calculate stats
    local totalAchievements = 0
    local unlockedAchievements = 0
    local totalPoints = 0
    
    local playerData = self._dataCache and self._dataCache:Get() or {}
    if playerData.achievements then
        for _, achievement in pairs(playerData.achievements) do
            totalAchievements = totalAchievements + 1
            if achievement.unlocked then
                unlockedAchievements = unlockedAchievements + 1
                local tierData = ACHIEVEMENT_TIERS[achievement.tier]
                if tierData then
                    totalPoints = totalPoints + tierData.points
                end
            end
        end
    end
    
    -- Stats display
    local statsGrid = Instance.new("UIGridLayout")
    statsGrid.CellPadding = UDim2.new(0, 20, 0, 0)
    statsGrid.CellSize = UDim2.new(0.25, -15, 1, 0)
    statsGrid.FillDirection = Enum.FillDirection.Horizontal
    statsGrid.Parent = statsFrame
    
    local stats = {
        {label = "Unlocked", value = unlockedAchievements .. "/" .. totalAchievements, icon = "🏆"},
        {label = "Completion", value = math.floor((unlockedAchievements / math.max(totalAchievements, 1)) * 100) .. "%", icon = "📊"},
        {label = "Total Points", value = self._utilities.FormatNumber(totalPoints), icon = "⭐"},
        {label = "Rank", value = self:GetAchievementRank(totalPoints), icon = "🎖️"}
    }
    
    for _, stat in ipairs(stats) do
        local statFrame = Instance.new("Frame")
        statFrame.BackgroundTransparency = 1
        statFrame.Parent = statsFrame
        
        local iconLabel = self._uiFactory:CreateLabel(statFrame, {
            text = stat.icon,
            size = UDim2.new(0, 30, 0, 30),
            position = UDim2.new(0, 0, 0.5, -15),
            textSize = 20
        })
        
        local valueLabel = self._uiFactory:CreateLabel(statFrame, {
            text = stat.value,
            size = UDim2.new(1, -35, 0, 25),
            position = UDim2.new(0, 35, 0, 5),
            textXAlignment = Enum.TextXAlignment.Left,
            font = self._config.FONTS.Display,
            textSize = 18
        })
        
        local labelText = self._uiFactory:CreateLabel(statFrame, {
            text = stat.label,
            size = UDim2.new(1, -35, 0, 20),
            position = UDim2.new(0, 35, 0, 30),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.TextSecondary,
            textSize = 12
        })
    end
    
    return statsFrame
end

function QuestUI:CreateAchievementFilterBar(parent: Frame): Frame
    local filterBar = Instance.new("Frame")
    filterBar.Size = UDim2.new(1, 0, 0, 40)
    filterBar.Position = UDim2.new(0, 0, 0, 80)
    filterBar.BackgroundTransparency = 1
    filterBar.Parent = parent
    
    -- Tier filter
    local tierFrame = Instance.new("Frame")
    tierFrame.Size = UDim2.new(0.33, -5, 1, 0)
    tierFrame.BackgroundTransparency = 1
    tierFrame.Parent = filterBar
    
    local tiers = {"All"}
    for tier, _ in pairs(ACHIEVEMENT_TIERS) do
        table.insert(tiers, tier)
    end
    
    local tierDropdown = self._uiFactory:CreateDropdown(tierFrame, {
        options = tiers,
        default = "All",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0.5, -15),
        callback = function(selected)
            self:FilterAchievements({tier = selected ~= "All" and selected or nil})
        end
    })
    
    -- Status filter
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0.33, -5, 1, 0)
    statusFrame.Position = UDim2.new(0.33, 5, 0, 0)
    statusFrame.BackgroundTransparency = 1
    statusFrame.Parent = filterBar
    
    local statusDropdown = self._uiFactory:CreateDropdown(statusFrame, {
        options = {"All", "Unlocked", "Locked"},
        default = "All",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0.5, -15),
        callback = function(selected)
            self:FilterAchievements({status = selected ~= "All" and selected or nil})
        end
    })
    
    -- Search
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0.33, -5, 1, 0)
    searchFrame.Position = UDim2.new(0.67, 5, 0, 0)
    searchFrame.BackgroundTransparency = 1
    searchFrame.Parent = filterBar
    
    local searchBox = self._uiFactory:CreateTextBox(searchFrame, "Search...", {
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0.5, -15),
        callback = function(text)
            self:FilterAchievements({search = text})
        end
    })
    
    return filterBar
end

function QuestUI:CreateAchievementCard(parent: Frame, achievement: Achievement): Frame
    local card = Instance.new("Frame")
    card.Name = achievement.id
    card.Size = UDim2.new(1, 0, 0, ACHIEVEMENT_CARD_HEIGHT)
    card.BackgroundColor3 = achievement.unlocked and self._config.COLORS.White or self._config.COLORS.Surface
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    self._utilities.CreatePadding(card, 15)
    
    -- Store reference
    self.AchievementCards[achievement.id] = card
    
    -- Tier indicator
    local tierData = ACHIEVEMENT_TIERS[achievement.tier]
    local tierBar = Instance.new("Frame")
    tierBar.Size = UDim2.new(0, 5, 1, -10)
    tierBar.Position = UDim2.new(0, 0, 0, 5)
    tierBar.BackgroundColor3 = tierData.color
    tierBar.BorderSizePixel = 0
    tierBar.Parent = card
    
    self._utilities.CreateCorner(tierBar, 2)
    
    -- Icon
    local iconLabel = self._uiFactory:CreateLabel(card, {
        text = achievement.icon,
        size = UDim2.new(0, 50, 0, 50),
        position = UDim2.new(0, 15, 0.5, -25),
        textSize = 36,
        textTransparency = achievement.unlocked and 0 or 0.5
    })
    
    -- Info
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -200, 1, -10)
    infoFrame.Position = UDim2.new(0, 75, 0, 5)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = card
    
    local nameLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = achievement.name,
        size = UDim2.new(1, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textColor = achievement.unlocked and self._config.COLORS.Dark or self._config.COLORS.TextSecondary,
        textSize = 16
    })
    
    local descLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = achievement.description,
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textWrapped = true,
        textSize = 14
    })
    
    -- Progress bar for locked achievements
    if not achievement.unlocked and achievement.progress then
        local progressBar = self:CreateAchievementProgressBar(infoFrame, achievement)
        progressBar.Position = UDim2.new(0, 0, 1, -5)
    end
    
    -- Tier badge
    local tierBadge = Instance.new("Frame")
    tierBadge.Size = UDim2.new(0, 80, 0, 25)
    tierBadge.Position = UDim2.new(1, -90, 0.5, -12.5)
    tierBadge.BackgroundColor3 = tierData.color
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
    
    -- Points
    local pointsLabel = self._uiFactory:CreateLabel(card, {
        text = tierData.icon .. " " .. tierData.points .. " pts",
        size = UDim2.new(0, 80, 0, 20),
        position = UDim2.new(1, -90, 0, 10),
        textColor = achievement.unlocked and tierData.color or self._config.COLORS.TextSecondary,
        font = self._config.FONTS.Numbers,
        textSize = 14
    })
    
    -- Unlock date for completed achievements
    if achievement.unlocked and achievement.unlockedAt then
        local dateLabel = self._uiFactory:CreateLabel(card, {
            text = os.date("%m/%d/%Y", achievement.unlockedAt),
            size = UDim2.new(0, 80, 0, 15),
            position = UDim2.new(1, -90, 1, -20),
            textColor = self._config.COLORS.TextSecondary,
            textSize = 10
        })
    end
    
    -- Add hover effect
    self:AddAchievementCardEffects(card, achievement)
    
    return card
end

function QuestUI:CreateAchievementProgressBar(parent: Frame, achievement: Achievement): Frame
    local progressFrame = Instance.new("Frame")
    progressFrame.Size = UDim2.new(1, 0, 0, 4)
    progressFrame.BackgroundColor3 = self._config.COLORS.Background
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = parent
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.min(achievement.progress / achievement.target, 1), 0, 1, 0)
    fill.BackgroundColor3 = ACHIEVEMENT_TIERS[achievement.tier].color
    fill.BorderSizePixel = 0
    fill.Parent = progressFrame
    
    return progressFrame
end

function QuestUI:AddAchievementCardEffects(card: Frame, achievement: Achievement)
    if not achievement.unlocked then return end
    
    -- Add shine effect for unlocked achievements
    if self._effectsLibrary then
        self._effectsLibrary:CreateShineEffect(card, {
            interval = 5,
            speed = 1
        })
    end
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        if self._animationSystem then
            self._animationSystem:PlayAnimation("Float", {
                target = card,
                height = 5
            })
        end
    end)
    
    card.MouseLeave:Connect(function()
        if self._animationSystem then
            self._animationSystem:StopAnimation(card)
        end
    end)
end

-- ========================================
-- DATA REFRESH
-- ========================================

function QuestUI:RefreshQuests(force: boolean?)
    if not force and tick() - self.LastRefresh < REFRESH_COOLDOWN then
        return
    end
    
    self.LastRefresh = tick()
    
    -- Get quest data
    local playerData = self._dataCache and self._dataCache:Get() or {}
    local quests = playerData.quests or {}
    
    -- Clear existing quest cards
    for id, card in pairs(self.QuestCards) do
        card:Destroy()
    end
    self.QuestCards = {}
    
    -- Remove empty states
    if self.DailyQuestContainer then
        local emptyState = self.DailyQuestContainer:FindFirstChild("EmptyState")
        if emptyState then
            emptyState:Destroy()
        end
    end
    
    if self.WeeklyQuestContainer then
        local emptyState = self.WeeklyQuestContainer:FindFirstChild("EmptyState")
        if emptyState then
            emptyState:Destroy()
        end
    end
    
    -- Add daily quests
    local dailyQuests = quests.daily or {}
    if self.DailyQuestContainer then
        if #dailyQuests == 0 then
            self:CreateEmptyState(self.DailyQuestContainer, "daily")
        else
            for _, quest in ipairs(dailyQuests) do
                quest.type = "daily"
                self:CreateQuestCard(self.DailyQuestContainer, quest)
            end
        end
    end
    
    -- Add weekly quests
    local weeklyQuests = quests.weekly or {}
    if self.WeeklyQuestContainer then
        if #weeklyQuests == 0 then
            self:CreateEmptyState(self.WeeklyQuestContainer, "weekly")
        else
            for _, quest in ipairs(weeklyQuests) do
                quest.type = "weekly"
                self:CreateQuestCard(self.WeeklyQuestContainer, quest)
            end
        end
    end
    
    -- Apply filters
    self:ApplyQuestFilters()
end

function QuestUI:RefreshQuestCard(quest: Quest)
    local card = self.QuestCards[quest.id]
    if not card then return end
    
    -- Update status bar
    local statusBar = card:FindFirstChild("StatusBar")
    if statusBar then
        statusBar.BackgroundColor3 = quest.completed and self._config.COLORS.Success or self._config.COLORS.Warning
    end
    
    -- Update progress bar
    local progressBar = card:FindFirstChild("ProgressBar", true)
    if progressBar then
        local fill = progressBar:FindFirstChild("Fill")
        if fill then
            self._utilities.Tween(fill, {
                Size = UDim2.new(math.min(quest.progress / quest.target, 1), 0, 1, 0),
                BackgroundColor3 = quest.completed and self._config.COLORS.Success or self._config.COLORS.Primary
            }, self._config.TWEEN_INFO.Normal)
        end
        
        local progressText = progressBar:FindFirstChildOfClass("TextLabel")
        if progressText then
            progressText.Text = string.format("%d / %d", quest.progress, quest.target)
        end
    end
    
    -- Update button
    local existingButton = card:FindFirstChildOfClass("TextButton")
    if existingButton then
        existingButton:Destroy()
    end
    
    local existingLabel = card:FindFirstChild("ClaimedLabel", true)
    if existingLabel and existingLabel:IsA("TextLabel") then
        existingLabel:Destroy()
    end
    
    if quest.completed and not quest.claimed then
        local claimButton = self._uiFactory:CreateButton(card, {
            text = "Claim",
            size = UDim2.new(0, 100, 0, 35),
            position = UDim2.new(1, -115, 1, -45),
            backgroundColor = self._config.COLORS.Success,
            callback = function()
                self:ClaimQuest(quest)
            end
        })
        
        if self._effectsLibrary then
            self._effectsLibrary:CreateGlowEffect(claimButton, {
                color = self._config.COLORS.Success,
                size = 15
            })
        end
    elseif quest.claimed then
        local claimedLabel = self._uiFactory:CreateLabel(card, {
            name = "ClaimedLabel",
            text = "✓ Claimed",
            size = UDim2.new(0, 100, 0, 35),
            position = UDim2.new(1, -115, 1, -45),
            textColor = self._config.COLORS.Success,
            font = self._config.FONTS.Secondary
        })
    end
end

function QuestUI:RefreshAchievements()
    -- Clear existing
    for id, card in pairs(self.AchievementCards) do
        card:Destroy()
    end
    self.AchievementCards = {}
    
    -- Get achievement data
    local playerData = self._dataCache and self._dataCache:Get() or {}
    local achievements = playerData.achievements or {}
    
    -- Sample achievements if none exist
    if next(achievements) == nil then
        achievements = self:GetSampleAchievements()
    end
    
    -- Create achievement cards
    for _, achievement in pairs(achievements) do
        self:CreateAchievementCard(self.AchievementContainer, achievement)
    end
end

function QuestUI:GetSampleAchievements(): {Achievement}
    return {
        {
            id = "first_steps",
            name = "First Steps",
            description = "Open your first egg",
            icon = "🥚",
            tier = "Bronze",
            category = "collection",
            progress = 1,
            target = 1,
            unlocked = true,
            unlockedAt = os.time() - 86400
        },
        {
            id = "pet_collector",
            name = "Pet Collector",
            description = "Collect 10 different pets",
            icon = "🐾",
            tier = "Bronze",
            category = "collection",
            progress = 7,
            target = 10,
            unlocked = false
        },
        {
            id = "millionaire",
            name = "Millionaire",
            description = "Earn 1,000,000 coins",
            icon = "💰",
            tier = "Silver",
            category = "economy",
            progress = 543210,
            target = 1000000,
            unlocked = false
        },
        {
            id = "battle_master",
            name = "Battle Master",
            description = "Win 100 battles",
            icon = "⚔️",
            tier = "Gold",
            category = "battle",
            progress = 0,
            target = 100,
            unlocked = false
        },
        {
            id = "legendary_trainer",
            name = "Legendary Trainer",
            description = "Own a legendary pet",
            icon = "✨",
            tier = "Platinum",
            category = "collection",
            progress = 0,
            target = 1,
            unlocked = false
        }
    }
end

-- ========================================
-- FILTERS AND SORTING
-- ========================================

function QuestUI:ApplyQuestFilters()
    -- Apply to both containers
    if self.DailyQuestContainer then
        self:FilterQuestContainer(self.DailyQuestContainer)
    end
    
    if self.WeeklyQuestContainer then
        self:FilterQuestContainer(self.WeeklyQuestContainer)
    end
end

function QuestUI:FilterQuestContainer(container: Frame)
    local cards = {}
    
    -- Collect all quest cards
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "EmptyState" then
            table.insert(cards, child)
        end
    end
    
    -- Sort cards
    table.sort(cards, function(a, b)
        -- Get quest data (would be stored on card or fetched)
        if self.SortOrder == "progress" then
            -- Sort by completion status first, then progress
            return false -- Implement actual sorting logic
        elseif self.SortOrder == "rewards" then
            -- Sort by reward value
            return false
        else -- name
            return a.Name < b.Name
        end
    end)
    
    -- Reorder cards
    for i, card in ipairs(cards) do
        card.LayoutOrder = i
    end
end

function QuestUI:FilterAchievements(filters: table)
    -- Filter achievement cards based on criteria
    for id, card in pairs(self.AchievementCards) do
        local visible = true
        
        -- Apply filters
        if filters.tier then
            -- Check tier
        end
        
        if filters.status then
            -- Check unlock status
        end
        
        if filters.search then
            -- Check name/description
        end
        
        card.Visible = visible
    end
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

function QuestUI:OnQuestProgressUpdate(data: {questId: string, progress: number})
    -- Find and update quest
    local playerData = self._dataCache and self._dataCache:Get() or {}
    local quest = self:FindQuest(data.questId)
    
    if quest then
        quest.progress = data.progress
        quest.completed = quest.progress >= quest.target
        
        -- Update card
        self:RefreshQuestCard(quest)
        
        -- Show progress notification
        if not quest.completed then
            self._notificationSystem:SendNotification("Quest Progress", 
                quest.name .. ": " .. quest.progress .. "/" .. quest.target, "info", 3)
        end
    end
end

function QuestUI:OnQuestCompleted(questId: string)
    local quest = self:FindQuest(questId)
    if not quest then return end
    
    quest.completed = true
    self:RefreshQuestCard(quest)
    
    -- Notification
    self._notificationSystem:SendNotification("Quest Complete!", 
        quest.name .. " - Claim your rewards!", "success", 5)
    
    -- Effects
    local card = self.QuestCards[questId]
    if card then
        -- Particles
        if self._particleSystem then
            self._particleSystem:CreateBurst(card, "star", 
                UDim2.new(0.5, 0, 0.5, 0), 20)
        end
        
        -- Glow effect
        if self._effectsLibrary then
            self._effectsLibrary:CreateGlowEffect(card, {
                color = self._config.COLORS.Success,
                size = 20,
                duration = 2
            })
        end
    end
    
    -- Sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("QuestComplete")
    end
end

function QuestUI:OnQuestClaimed(data: {questId: string, rewards: table})
    local quest = self:FindQuest(data.questId)
    if quest then
        quest.claimed = true
        self:RefreshQuestCard(quest)
    end
end

function QuestUI:OnNewQuest(quest: Quest)
    -- Add new quest to appropriate container
    local container = quest.type == "daily" and self.DailyQuestContainer or self.WeeklyQuestContainer
    if container then
        -- Remove empty state if present
        local emptyState = container:FindFirstChild("EmptyState")
        if emptyState then
            emptyState:Destroy()
        end
        
        -- Create card
        self:CreateQuestCard(container, quest)
        
        -- Notification
        self._notificationSystem:SendNotification("New Quest!", 
            quest.name, "info", 5)
    end
end

function QuestUI:OnAchievementUnlocked(achievement: Achievement)
    -- Update card if it exists
    local card = self.AchievementCards[achievement.id]
    if card then
        -- Refresh appearance
        card.BackgroundColor3 = self._config.COLORS.White
        
        -- Update elements
        local iconLabel = card:FindFirstChildOfClass("TextLabel")
        if iconLabel then
            iconLabel.TextTransparency = 0
        end
    end
    
    -- Big notification
    self._notificationSystem:SendNotification("Achievement Unlocked!", 
        achievement.name .. " - " .. ACHIEVEMENT_TIERS[achievement.tier].icon, 
        "success", 10)
    
    -- Special effects
    if self._particleSystem then
        self._particleSystem:CreateBurst(self.Frame, "star", 
            UDim2.new(0.5, 0, 0.5, 0), 50)
    end
    
    -- Sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Achievement")
    end
end

function QuestUI:OnAchievementProgress(data: {achievementId: string, progress: number})
    local card = self.AchievementCards[data.achievementId]
    if card then
        -- Update progress bar
        local progressBar = card:FindFirstChild("ProgressBar", true)
        if progressBar then
            local fill = progressBar:FindFirstChildOfClass("Frame")
            if fill then
                -- Update progress smoothly
                self._utilities.Tween(fill, {
                    Size = UDim2.new(data.progress / 100, 0, 1, 0) -- Assuming normalized progress
                }, self._config.TWEEN_INFO.Normal)
            end
        end
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function QuestUI:GetQuestCategory(quest: Quest): table
    local category = quest.category or "general"
    return QUEST_CATEGORIES[category] or {
        name = "General",
        icon = "📋",
        color = self._config.COLORS.Primary
    }
end

function QuestUI:FindQuest(questId: string): Quest?
    local playerData = self._dataCache and self._dataCache:Get() or {}
    local quests = playerData.quests or {}
    
    -- Check daily quests
    if quests.daily then
        for _, quest in ipairs(quests.daily) do
            if quest.id == questId then
                return quest
            end
        end
    end
    
    -- Check weekly quests
    if quests.weekly then
        for _, quest in ipairs(quests.weekly) do
            if quest.id == questId then
                return quest
            end
        end
    end
    
    return nil
end

function QuestUI:FormatTimeLeft(seconds: number): string
    if seconds < 60 then
        return seconds .. "s"
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. "m"
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. "h"
    else
        return math.floor(seconds / 86400) .. "d"
    end
end

function QuestUI:GetAchievementRank(points: number): string
    if points >= 10000 then
        return "Legend"
    elseif points >= 5000 then
        return "Master"
    elseif points >= 2500 then
        return "Expert"
    elseif points >= 1000 then
        return "Veteran"
    elseif points >= 500 then
        return "Skilled"
    elseif points >= 100 then
        return "Novice"
    else
        return "Beginner"
    end
end

function QuestUI:RefreshDisplay()
    -- Debounced refresh
    if self._refreshDebounce then
        task.cancel(self._refreshDebounce)
    end
    
    self._refreshDebounce = task.delay(0.1, function()
        self._refreshDebounce = nil
        
        -- Refresh based on active tab
        for name, frame in pairs(self.TabFrames) do
            if frame.Visible then
                if name:match("Quests") then
                    self:RefreshQuests()
                elseif name == "Achievements" then
                    self:RefreshAchievements()
                end
                break
            end
        end
    end)
end

-- ========================================
-- CLEANUP
-- ========================================

function QuestUI:Destroy()
    -- Cancel any active timers
    if self._refreshDebounce then
        task.cancel(self._refreshDebounce)
    end
    
    -- Close UI
    self:Close()
    
    -- Clear references
    self.Frame = nil
    self.TabFrames = {}
    self.QuestCards = {}
    self.AchievementCards = {}
    self.DailyQuestContainer = nil
    self.WeeklyQuestContainer = nil
    self.AchievementContainer = nil
end

return QuestUI