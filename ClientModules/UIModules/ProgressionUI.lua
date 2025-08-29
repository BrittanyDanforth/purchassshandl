--[[
    Module: ProgressionUI
    Description: Comprehensive progression interface with battle pass, achievements,
                 player stats, and seasonal content
    Features: Battle pass tiers, achievement tracking, statistics dashboard,
              level progression, prestige system, seasonal rewards
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local ProgressionUI = {}
ProgressionUI.__index = ProgressionUI

-- ========================================
-- TYPES
-- ========================================

type BattlePassTier = {
    tier: number,
    freeReward: RewardData?,
    premiumReward: RewardData?,
    requiredExp: number,
    claimed: {free: boolean, premium: boolean}
}

type RewardData = {
    type: "currency" | "pet" | "item" | "cosmetic",
    id: string,
    amount: number,
    displayName: string,
    icon: string,
    rarity: number
}

type Achievement = {
    id: string,
    name: string,
    description: string,
    icon: string,
    category: string,
    tier: "Bronze" | "Silver" | "Gold" | "Platinum" | "Diamond",
    progress: number,
    target: number,
    completed: boolean,
    claimedAt: number?,
    rewards: {RewardData}
}

type PlayerStats = {
    level: number,
    experience: number,
    nextLevelExp: number,
    prestige: number,
    totalPlayTime: number,
    totalCoinsEarned: number,
    totalGemsEarned: number,
    petsCollected: number,
    uniquePetsOwned: number,
    eggsOpened: number,
    tradesCompleted: number,
    battlesWon: number,
    questsCompleted: number,
    achievementsUnlocked: number,
    caseOpenings: number,
    highestPetLevel: number,
    dailyLoginStreak: number,
    maxDailyStreak: number
}

type Season = {
    id: string,
    name: string,
    theme: string,
    startDate: number,
    endDate: number,
    currentTier: number,
    maxTier: number,
    isPremium: boolean,
    experience: number,
    rewards: {BattlePassTier}
}

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(900, 650)
local HEADER_HEIGHT = 60
local TAB_HEIGHT = 40
local TIER_CARD_HEIGHT = 120
local ACHIEVEMENT_CARD_HEIGHT = 100
local STAT_CARD_SIZE = Vector2.new(180, 100)

-- Achievement categories
local ACHIEVEMENT_CATEGORIES = {
    {id = "general", name = "General", icon = "⭐"},
    {id = "pets", name = "Pet Collection", icon = "🐾"},
    {id = "trading", name = "Trading", icon = "🤝"},
    {id = "battles", name = "Battles", icon = "⚔️"},
    {id = "wealth", name = "Wealth", icon = "💰"},
    {id = "social", name = "Social", icon = "👥"}
}

-- Tier colors
local TIER_COLORS = {
    Bronze = Color3.fromRGB(205, 127, 50),
    Silver = Color3.fromRGB(192, 192, 192),
    Gold = Color3.fromRGB(255, 215, 0),
    Platinum = Color3.fromRGB(229, 228, 226),
    Diamond = Color3.fromRGB(185, 242, 255)
}

-- Experience requirements per level
local EXP_PER_LEVEL = 1000
local EXP_SCALING = 1.15 -- Each level requires 15% more exp
local MAX_LEVEL = 100
local PRESTIGE_LEVELS = 10

-- ========================================
-- INITIALIZATION
-- ========================================

function ProgressionUI.new(dependencies)
    local self = setmetatable({}, ProgressionUI)
    
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
    self.CurrentTab = "battlepass"
    self.BattlePassContainer = nil
    self.AchievementsContainer = nil
    self.StatsContainer = nil
    
    -- State
    self.CurrentSeason = nil
    self.PlayerStats = nil
    self.Achievements = {}
    self.SelectedCategory = "general"
    self.ClaimQueue = {}
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function ProgressionUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Battle pass events
    self._eventBus:On("BattlePassUpdated", function(season)
        self:OnBattlePassUpdate(season)
    end)
    
    self._eventBus:On("TierUnlocked", function(tier)
        self:OnTierUnlocked(tier)
    end)
    
    -- Achievement events
    self._eventBus:On("AchievementProgress", function(achievement)
        self:OnAchievementProgress(achievement)
    end)
    
    self._eventBus:On("AchievementUnlocked", function(achievement)
        self:OnAchievementUnlocked(achievement)
    end)
    
    -- Stats events
    self._eventBus:On("PlayerLevelUp", function(newLevel)
        self:OnLevelUp(newLevel)
    end)
    
    self._eventBus:On("PlayerPrestige", function(prestigeLevel)
        self:OnPrestige(prestigeLevel)
    end)
    
    self._eventBus:On("StatsUpdated", function(stats)
        self:OnStatsUpdate(stats)
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function ProgressionUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshContent()
        return
    end
    
    -- Create UI
    self:CreateUI()
    
    -- Load initial data
    self:LoadProgressionData()
end

function ProgressionUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function ProgressionUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                   self._windowManager and self._windowManager:GetMainPanel() or 
                   Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[ProgressionUI] No parent container found")
        return
    end
    
    -- Create main frame
    self.Frame = self._uiFactory:CreateFrame(parent, {
        name = "ProgressionFrame",
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

function ProgressionUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary
    })
    
    -- Dynamic title
    self.HeaderLabel = self._uiFactory:CreateLabel(header, {
        text = "🎖️ Battle Pass 🎖️",
        size = UDim2.new(1, -200, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24
    })
    
    -- Season timer
    self.SeasonTimer = self._uiFactory:CreateLabel(header, {
        text = "Season ends in: --:--:--",
        size = UDim2.new(0, 180, 0, 30),
        position = UDim2.new(1, -190, 0.5, -15),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 14
    })
    
    -- Update timer
    self:StartSeasonTimer()
end

function ProgressionUI:CreateTabs()
    local tabs = {
        {
            name = "Battle Pass",
            icon = "🎖️",
            callback = function(frame)
                self.CurrentTab = "battlepass"
                self.HeaderLabel.Text = "🎖️ Battle Pass 🎖️"
                self:CreateBattlePassView(frame)
            end
        },
        {
            name = "Achievements",
            icon = "🏆",
            callback = function(frame)
                self.CurrentTab = "achievements"
                self.HeaderLabel.Text = "🏆 Achievements 🏆"
                self:CreateAchievementsView(frame)
            end
        },
        {
            name = "Statistics",
            icon = "📊",
            callback = function(frame)
                self.CurrentTab = "statistics"
                self.HeaderLabel.Text = "📊 Statistics 📊"
                self:CreateStatisticsView(frame)
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
                
                -- Update header
                tab.callback(self.TabFrames[tab.name])
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
-- BATTLE PASS VIEW
-- ========================================

function ProgressionUI:CreateBattlePassView(parent: Frame)
    -- Top section - Progress and buy button
    local topSection = Instance.new("Frame")
    topSection.Size = UDim2.new(1, 0, 0, 100)
    topSection.BackgroundTransparency = 1
    topSection.Parent = parent
    
    -- Progress info
    local progressFrame = Instance.new("Frame")
    progressFrame.Size = UDim2.new(0.7, -10, 1, 0)
    progressFrame.BackgroundColor3 = self._config.COLORS.Surface
    progressFrame.Parent = topSection
    
    self._utilities.CreateCorner(progressFrame, 12)
    self._utilities.CreatePadding(progressFrame, 15)
    
    -- Current tier
    self.TierLabel = self._uiFactory:CreateLabel(progressFrame, {
        text = "Tier 1 / 100",
        size = UDim2.new(0.3, 0, 0, 30),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Display,
        textSize = 20
    })
    
    -- Experience bar
    local expBarFrame = Instance.new("Frame")
    expBarFrame.Size = UDim2.new(1, 0, 0, 30)
    expBarFrame.Position = UDim2.new(0, 0, 0, 40)
    expBarFrame.BackgroundTransparency = 1
    expBarFrame.Parent = progressFrame
    
    self.ExpBar = self._uiFactory:CreateProgressBar(expBarFrame, {
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0.5, -10),
        value = 0,
        maxValue = 1000,
        fillColor = self._config.COLORS.Accent
    })
    
    self.ExpLabel = self._uiFactory:CreateLabel(expBarFrame, {
        text = "0 / 1,000 XP",
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0.5, -10),
        textColor = self._config.COLORS.White,
        textSize = 14
    })
    
    -- Premium button
    local premiumFrame = Instance.new("Frame")
    premiumFrame.Size = UDim2.new(0.3, -10, 1, 0)
    premiumFrame.Position = UDim2.new(0.7, 10, 0, 0)
    premiumFrame.BackgroundTransparency = 1
    premiumFrame.Parent = topSection
    
    self.PremiumButton = self._uiFactory:CreateButton(premiumFrame, {
        text = "🌟 Get Premium Pass",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0.5, -30),
        backgroundColor = self._config.COLORS.Warning,
        textSize = 16,
        callback = function()
            self:ShowPremiumPurchase()
        end
    })
    
    -- Rewards scroll
    local rewardsContainer = Instance.new("Frame")
    rewardsContainer.Size = UDim2.new(1, 0, 1, -110)
    rewardsContainer.Position = UDim2.new(0, 0, 0, 110)
    rewardsContainer.BackgroundTransparency = 1
    rewardsContainer.Parent = parent
    
    -- Free/Premium labels
    local labelHeight = 30
    local freeLabel = self._uiFactory:CreateLabel(rewardsContainer, {
        text = "FREE",
        size = UDim2.new(0, 60, 0, labelHeight),
        backgroundColor = self._config.COLORS.Secondary,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 14
    })
    
    self._utilities.CreateCorner(freeLabel, 4)
    
    local premiumLabel = self._uiFactory:CreateLabel(rewardsContainer, {
        text = "PREMIUM",
        size = UDim2.new(0, 80, 0, labelHeight),
        position = UDim2.new(0, 0, 0, labelHeight + 5),
        backgroundColor = self._config.COLORS.Warning,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 14
    })
    
    self._utilities.CreateCorner(premiumLabel, 4)
    
    -- Horizontal scroll for tiers
    self.TierScroll = Instance.new("ScrollingFrame")
    self.TierScroll.Size = UDim2.new(1, -70, 1, -70)
    self.TierScroll.Position = UDim2.new(0, 70, 0, 0)
    self.TierScroll.BackgroundTransparency = 1
    self.TierScroll.ScrollBarThickness = 6
    self.TierScroll.ScrollingDirection = Enum.ScrollingDirection.X
    self.TierScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TierScroll.Parent = rewardsContainer
    
    -- Tier container
    self.TierContainer = Instance.new("Frame")
    self.TierContainer.Size = UDim2.new(0, 0, 1, 0)
    self.TierContainer.BackgroundTransparency = 1
    self.TierContainer.Parent = self.TierScroll
    
    -- Create initial tiers
    self:CreateBattlePassTiers()
end

function ProgressionUI:CreateBattlePassTiers()
    if not self.CurrentSeason then return end
    
    local tierWidth = 120
    local tierSpacing = 10
    local totalWidth = 0
    
    -- Clear existing tiers
    for _, child in ipairs(self.TierContainer:GetChildren()) do
        child:Destroy()
    end
    
    -- Create tier cards
    for i = 1, self.CurrentSeason.maxTier do
        local tierData = self.CurrentSeason.rewards[i] or {
            tier = i,
            freeReward = nil,
            premiumReward = nil,
            requiredExp = self:CalculateRequiredExp(i),
            claimed = {free = false, premium = false}
        }
        
        local tierCard = self:CreateTierCard(tierData, i)
        tierCard.Position = UDim2.new(0, (i - 1) * (tierWidth + tierSpacing), 0, 0)
        tierCard.Parent = self.TierContainer
        
        totalWidth = i * (tierWidth + tierSpacing)
    end
    
    -- Update canvas size
    self.TierContainer.Size = UDim2.new(0, totalWidth, 1, 0)
    self.TierScroll.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
    
    -- Scroll to current tier
    if self.CurrentSeason.currentTier > 1 then
        local scrollPos = (self.CurrentSeason.currentTier - 1) * (tierWidth + tierSpacing)
        self.TierScroll.CanvasPosition = Vector2.new(math.min(scrollPos, totalWidth - self.TierScroll.AbsoluteSize.X), 0)
    end
end

function ProgressionUI:CreateTierCard(tierData: BattlePassTier, index: number): Frame
    local card = Instance.new("Frame")
    card.Name = "Tier" .. tierData.tier
    card.Size = UDim2.new(0, 110, 1, 0)
    card.BackgroundTransparency = 1
    card.Parent = self.TierContainer
    
    -- Tier number
    local tierLabel = Instance.new("Frame")
    tierLabel.Size = UDim2.new(1, 0, 0, 25)
    tierLabel.BackgroundColor3 = tierData.tier <= (self.CurrentSeason.currentTier or 0) and 
                                self._config.COLORS.Success or self._config.COLORS.Surface
    tierLabel.Parent = card
    
    self._utilities.CreateCorner(tierLabel, 4)
    
    local tierText = self._uiFactory:CreateLabel(tierLabel, {
        text = tostring(tierData.tier),
        size = UDim2.new(1, 0, 1, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 16
    })
    
    -- Free reward
    local freeReward = self:CreateRewardCard(tierData.freeReward, true, tierData.claimed.free)
    freeReward.Position = UDim2.new(0, 0, 0, 30)
    freeReward.Parent = card
    
    -- Premium reward
    local premiumReward = self:CreateRewardCard(tierData.premiumReward, false, tierData.claimed.premium)
    premiumReward.Position = UDim2.new(0, 0, 0, 95)
    premiumReward.Parent = card
    
    -- Locked overlay for unclaimed tiers
    if tierData.tier > (self.CurrentSeason.currentTier or 0) then
        local lockOverlay = Instance.new("Frame")
        lockOverlay.Size = UDim2.new(1, 0, 1, -25)
        lockOverlay.Position = UDim2.new(0, 0, 0, 25)
        lockOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
        lockOverlay.BackgroundTransparency = 0.5
        lockOverlay.ZIndex = card.ZIndex + 2
        lockOverlay.Parent = card
        
        local lockIcon = self._uiFactory:CreateLabel(lockOverlay, {
            text = "🔒",
            size = UDim2.new(1, 0, 1, 0),
            textSize = 32,
            textTransparency = 0.3
        })
    end
    
    -- Click to claim
    if tierData.tier <= (self.CurrentSeason.currentTier or 0) then
        if tierData.freeReward and not tierData.claimed.free then
            freeReward.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    self:ClaimReward(tierData.tier, "free")
                end
            end)
        end
        
        if tierData.premiumReward and not tierData.claimed.premium and self.CurrentSeason.isPremium then
            premiumReward.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    self:ClaimReward(tierData.tier, "premium")
                end
            end)
        end
    end
    
    return card
end

function ProgressionUI:CreateRewardCard(reward: RewardData?, isFree: boolean, claimed: boolean): Frame
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = claimed and self._config.COLORS.Success or 
                           (reward and self._config.COLORS.White or self._config.COLORS.Surface)
    card.BackgroundTransparency = reward and 0 or 0.5
    card.Parent = self.TierContainer
    
    self._utilities.CreateCorner(card, 8)
    
    if reward then
        -- Reward icon
        local icon = self._uiFactory:CreateLabel(card, {
            text = reward.icon or "🎁",
            size = UDim2.new(0, 40, 0, 40),
            position = UDim2.new(0.5, -20, 0.5, -20),
            textSize = 28,
            textTransparency = claimed and 0.5 or 0
        })
        
        -- Amount badge
        if reward.amount > 1 then
            local amountBadge = Instance.new("Frame")
            amountBadge.Size = UDim2.new(0, 30, 0, 20)
            amountBadge.Position = UDim2.new(1, -35, 1, -25)
            amountBadge.BackgroundColor3 = self._config.COLORS.Dark
            amountBadge.Parent = card
            
            self._utilities.CreateCorner(amountBadge, 4)
            
            local amountText = self._uiFactory:CreateLabel(amountBadge, {
                text = tostring(reward.amount),
                size = UDim2.new(1, 0, 1, 0),
                textColor = self._config.COLORS.White,
                textSize = 12
            })
        end
        
        -- Claimed checkmark
        if claimed then
            local checkmark = self._uiFactory:CreateLabel(card, {
                text = "✓",
                size = UDim2.new(1, 0, 1, 0),
                textColor = self._config.COLORS.White,
                font = self._config.FONTS.Display,
                textSize = 36,
                zIndex = card.ZIndex + 1
            })
        end
        
        -- Hover effect
        if not claimed then
            card.MouseEnter:Connect(function()
                self._utilities.Tween(card, {
                    BackgroundColor3 = self._config.COLORS.Primary
                }, self._config.TWEEN_INFO.Fast)
                
                -- Show tooltip
                self:ShowRewardTooltip(reward, card)
            end)
            
            card.MouseLeave:Connect(function()
                self._utilities.Tween(card, {
                    BackgroundColor3 = self._config.COLORS.White
                }, self._config.TWEEN_INFO.Fast)
                
                -- Hide tooltip
                self:HideTooltip()
            end)
        end
    else
        -- Empty reward slot
        local emptyLabel = self._uiFactory:CreateLabel(card, {
            text = "-",
            size = UDim2.new(1, 0, 1, 0),
            textColor = self._config.COLORS.TextSecondary,
            textSize = 24
        })
    end
    
    return card
end

-- ========================================
-- ACHIEVEMENTS VIEW
-- ========================================

function ProgressionUI:CreateAchievementsView(parent: Frame)
    -- Category selector
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(0, 150, 1, 0)
    categoryFrame.BackgroundColor3 = self._config.COLORS.Surface
    categoryFrame.Parent = parent
    
    self._utilities.CreateCorner(categoryFrame, 12)
    
    local categoryScroll = self._uiFactory:CreateScrollingFrame(categoryFrame, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.FillDirection = Enum.FillDirection.Vertical
    categoryLayout.Padding = UDim.new(0, 5)
    categoryLayout.Parent = categoryScroll
    
    -- Achievement list
    local achievementFrame = Instance.new("Frame")
    achievementFrame.Size = UDim2.new(1, -160, 1, 0)
    achievementFrame.Position = UDim2.new(0, 160, 0, 0)
    achievementFrame.BackgroundTransparency = 1
    achievementFrame.Parent = parent
    
    self.AchievementScroll = self._uiFactory:CreateScrollingFrame(achievementFrame, {
        size = UDim2.new(1, 0, 1, 0)
    })
    
    local achievementLayout = Instance.new("UIListLayout")
    achievementLayout.FillDirection = Enum.FillDirection.Vertical
    achievementLayout.Padding = UDim.new(0, 10)
    achievementLayout.Parent = self.AchievementScroll
    
    -- Create categories
    for i, category in ipairs(ACHIEVEMENT_CATEGORIES) do
        local categoryButton = self._uiFactory:CreateButton(categoryScroll, {
            text = category.icon .. " " .. category.name,
            size = UDim2.new(1, 0, 0, 40),
            backgroundColor = i == 1 and self._config.COLORS.Primary or self._config.COLORS.White,
            textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
            textXAlignment = Enum.TextXAlignment.Left,
            callback = function()
                -- Update selection
                for _, btn in ipairs(categoryScroll:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = btn == categoryButton and 
                                              self._config.COLORS.Primary or self._config.COLORS.White
                        btn.TextColor3 = btn == categoryButton and 
                                        self._config.COLORS.White or self._config.COLORS.Dark
                    end
                end
                
                -- Show achievements
                self.SelectedCategory = category.id
                self:ShowAchievements(category.id)
            end
        })
    end
    
    -- Progress summary
    local summaryFrame = Instance.new("Frame")
    summaryFrame.Size = UDim2.new(1, 0, 0, 80)
    summaryFrame.BackgroundColor3 = self._config.COLORS.Primary
    summaryFrame.Parent = achievementFrame
    
    self._utilities.CreateCorner(summaryFrame, 12)
    self._utilities.CreatePadding(summaryFrame, 15)
    
    self.AchievementProgress = self._uiFactory:CreateLabel(summaryFrame, {
        text = "0 / 0 Achievements Completed",
        size = UDim2.new(0.6, 0, 0, 30),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Display,
        textSize = 20
    })
    
    self.AchievementPoints = self._uiFactory:CreateLabel(summaryFrame, {
        text = "0 Points",
        size = UDim2.new(0.4, 0, 0, 30),
        position = UDim2.new(0.6, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 18
    })
    
    local progressBar = self._uiFactory:CreateProgressBar(summaryFrame, {
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 40),
        value = 0,
        maxValue = 100,
        fillColor = self._config.COLORS.Success
    })
    
    -- Adjust scroll position
    self.AchievementScroll.Position = UDim2.new(0, 0, 0, 90)
    self.AchievementScroll.Size = UDim2.new(1, 0, 1, -90)
    
    -- Show initial category
    self:ShowAchievements("general")
end

function ProgressionUI:ShowAchievements(categoryId: string)
    -- Clear existing
    for _, child in ipairs(self.AchievementScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Filter achievements by category
    local categoryAchievements = {}
    for _, achievement in pairs(self.Achievements) do
        if achievement.category == categoryId then
            table.insert(categoryAchievements, achievement)
        end
    end
    
    -- Sort by completion status and tier
    table.sort(categoryAchievements, function(a, b)
        if a.completed ~= b.completed then
            return not a.completed
        end
        return a.tier < b.tier
    end)
    
    -- Create achievement cards
    for _, achievement in ipairs(categoryAchievements) do
        local card = self:CreateAchievementCard(achievement)
        card.Parent = self.AchievementScroll
    end
    
    -- Update progress
    self:UpdateAchievementProgress()
end

function ProgressionUI:CreateAchievementCard(achievement: Achievement): Frame
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, ACHIEVEMENT_CARD_HEIGHT)
    card.BackgroundColor3 = achievement.completed and self._config.COLORS.White or 
                           Color3.fromRGB(240, 240, 240)
    card.Parent = self.AchievementScroll
    
    self._utilities.CreateCorner(card, 12)
    self._utilities.CreatePadding(card, 15)
    
    -- Icon
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 70, 0, 70)
    iconFrame.Position = UDim2.new(0, 0, 0.5, -35)
    iconFrame.BackgroundColor3 = TIER_COLORS[achievement.tier] or self._config.COLORS.Primary
    iconFrame.BackgroundTransparency = achievement.completed and 0 or 0.5
    iconFrame.Parent = card
    
    self._utilities.CreateCorner(iconFrame, 35)
    
    local icon = self._uiFactory:CreateLabel(iconFrame, {
        text = achievement.icon,
        size = UDim2.new(1, 0, 1, 0),
        textSize = 36,
        textTransparency = achievement.completed and 0 or 0.5
    })
    
    -- Info
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -170, 1, 0)
    infoFrame.Position = UDim2.new(0, 85, 0, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = card
    
    local nameLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = achievement.name,
        size = UDim2.new(1, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textColor = achievement.completed and self._config.COLORS.Dark or 
                   Color3.fromRGB(120, 120, 120),
        textSize = 18
    })
    
    local descLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = achievement.description,
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textSize = 14
    })
    
    -- Progress bar
    if not achievement.completed then
        local progressBar = self._uiFactory:CreateProgressBar(infoFrame, {
            size = UDim2.new(0.7, 0, 0, 15),
            position = UDim2.new(0, 0, 0, 55),
            value = achievement.progress,
            maxValue = achievement.target,
            fillColor = TIER_COLORS[achievement.tier] or self._config.COLORS.Primary
        })
        
        local progressText = self._uiFactory:CreateLabel(infoFrame, {
            text = achievement.progress .. " / " .. achievement.target,
            size = UDim2.new(0.3, 0, 0, 15),
            position = UDim2.new(0.7, 5, 0, 55),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.TextSecondary,
            textSize = 12
        })
    else
        -- Completion info
        local completedLabel = self._uiFactory:CreateLabel(infoFrame, {
            text = "✓ Completed " .. self:FormatDate(achievement.claimedAt or 0),
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 0, 55),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.Success,
            font = self._config.FONTS.Secondary,
            textSize = 14
        })
    end
    
    -- Tier badge
    local tierBadge = Instance.new("Frame")
    tierBadge.Size = UDim2.new(0, 80, 0, 25)
    tierBadge.Position = UDim2.new(1, -90, 0, 10)
    tierBadge.BackgroundColor3 = TIER_COLORS[achievement.tier] or self._config.COLORS.Primary
    tierBadge.Parent = card
    
    self._utilities.CreateCorner(tierBadge, 12)
    
    local tierLabel = self._uiFactory:CreateLabel(tierBadge, {
        text = achievement.tier,
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Secondary,
        textSize = 12
    })
    
    -- Rewards preview
    if achievement.rewards and #achievement.rewards > 0 then
        local rewardFrame = Instance.new("Frame")
        rewardFrame.Size = UDim2.new(0, 70, 1, -40)
        rewardFrame.Position = UDim2.new(1, -80, 0, 35)
        rewardFrame.BackgroundTransparency = 1
        rewardFrame.Parent = card
        
        for i, reward in ipairs(achievement.rewards) do
            if i <= 2 then -- Show max 2 rewards
                local rewardIcon = self._uiFactory:CreateLabel(rewardFrame, {
                    text = reward.icon or "🎁",
                    size = UDim2.new(0, 25, 0, 25),
                    position = UDim2.new(0, (i - 1) * 30, 0, 0),
                    textSize = 20
                })
            end
        end
    end
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        if not achievement.completed then
            self._utilities.Tween(card, {
                BackgroundColor3 = self._config.COLORS.White
            }, self._config.TWEEN_INFO.Fast)
        end
    end)
    
    card.MouseLeave:Connect(function()
        if not achievement.completed then
            self._utilities.Tween(card, {
                BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            }, self._config.TWEEN_INFO.Fast)
        end
    end)
    
    return card
end

-- ========================================
-- STATISTICS VIEW
-- ========================================

function ProgressionUI:CreateStatisticsView(parent: Frame)
    -- Level and prestige header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 120)
    headerFrame.BackgroundColor3 = self._config.COLORS.Primary
    headerFrame.Parent = parent
    
    self._utilities.CreateCorner(headerFrame, 12)
    
    -- Level display
    local levelFrame = Instance.new("Frame")
    levelFrame.Size = UDim2.new(0.5, -10, 1, -20)
    levelFrame.Position = UDim2.new(0, 10, 0, 10)
    levelFrame.BackgroundTransparency = 1
    levelFrame.Parent = headerFrame
    
    self.LevelLabel = self._uiFactory:CreateLabel(levelFrame, {
        text = "Level 1",
        size = UDim2.new(1, 0, 0, 40),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 32
    })
    
    -- Experience progress
    self.LevelExpBar = self._uiFactory:CreateProgressBar(levelFrame, {
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 50),
        value = 0,
        maxValue = EXP_PER_LEVEL,
        fillColor = self._config.COLORS.Accent
    })
    
    self.LevelExpLabel = self._uiFactory:CreateLabel(levelFrame, {
        text = "0 / " .. EXP_PER_LEVEL .. " XP",
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 75),
        textColor = self._config.COLORS.White,
        textTransparency = 0.3,
        textSize = 14
    })
    
    -- Prestige display
    local prestigeFrame = Instance.new("Frame")
    prestigeFrame.Size = UDim2.new(0.5, -10, 1, -20)
    prestigeFrame.Position = UDim2.new(0.5, 0, 0, 10)
    prestigeFrame.BackgroundTransparency = 1
    prestigeFrame.Parent = headerFrame
    
    self.PrestigeLabel = self._uiFactory:CreateLabel(prestigeFrame, {
        text = "Prestige 0",
        size = UDim2.new(1, 0, 0, 40),
        textXAlignment = Enum.TextXAlignment.Right,
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.Warning,
        textSize = 28
    })
    
    local prestigeButton = self._uiFactory:CreateButton(prestigeFrame, {
        text = "Prestige Info",
        size = UDim2.new(0, 120, 0, 30),
        position = UDim2.new(1, -120, 0, 50),
        backgroundColor = self._config.COLORS.Secondary,
        textSize = 14,
        callback = function()
            self:ShowPrestigeInfo()
        end
    })
    
    -- Stats grid
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, 0, 1, -130)
    statsContainer.Position = UDim2.new(0, 0, 0, 130)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = parent
    
    local scrollFrame = self._uiFactory:CreateScrollingFrame(statsContainer, {
        size = UDim2.new(1, 0, 1, 0)
    })
    
    local gridFrame = Instance.new("Frame")
    gridFrame.Size = UDim2.new(1, -20, 0, 800)
    gridFrame.BackgroundTransparency = 1
    gridFrame.Parent = scrollFrame
    
    local statsGrid = Instance.new("UIGridLayout")
    statsGrid.CellPadding = UDim2.new(0, 15, 0, 15)
    statsGrid.CellSize = UDim2.new(0, STAT_CARD_SIZE.X, 0, STAT_CARD_SIZE.Y)
    statsGrid.FillDirection = Enum.FillDirection.Horizontal
    statsGrid.Parent = gridFrame
    
    self._utilities.CreatePadding(gridFrame, 10)
    
    -- Create stat cards
    self:CreateStatCards(gridFrame)
    
    -- Update canvas size
    statsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, statsGrid.AbsoluteContentSize.Y + 20)
    end)
end

function ProgressionUI:UpdateStatCardsInPlace()
    if not self.StatCards or not self.PlayerStats then return end
    
    -- Update existing stat cards with new values
    local statsData = {
        ["Total Play Time"] = self:FormatPlayTime(self.PlayerStats.totalPlayTime or 0),
        ["Total Coins Earned"] = self._utilities.FormatNumber(self.PlayerStats.totalCoinsEarned or 0),
        ["Total Gems Earned"] = self._utilities.FormatNumber(self.PlayerStats.totalGemsEarned or 0),
        ["Pets Hatched"] = self._utilities.FormatNumber(self.PlayerStats.petsHatched or 0),
        ["Rare Pets Found"] = self._utilities.FormatNumber(self.PlayerStats.rarePetsFound or 0),
        ["Battles Won"] = self._utilities.FormatNumber(self.PlayerStats.battlesWon or 0),
        ["Trades Completed"] = self._utilities.FormatNumber(self.PlayerStats.tradesCompleted or 0),
        ["Quests Completed"] = self._utilities.FormatNumber(self.PlayerStats.questsCompleted or 0),
        ["Daily Streak"] = self.PlayerStats.currentDailyStreak .. " / " .. self.PlayerStats.maxDailyStreak .. " days",
        ["Achievement Points"] = self._utilities.FormatNumber(self.PlayerStats.achievementPoints or 0),
        ["Collection Progress"] = (self.PlayerStats.uniquePetsOwned or 0) .. " / " .. (self.PlayerStats.totalPetTypes or 999),
        ["VIP Level"] = "Level " .. (self.PlayerStats.vipLevel or 0)
    }
    
    -- Update each card's value label
    for cardTitle, newValue in pairs(statsData) do
        local card = self.StatCards[cardTitle]
        if card and card.ValueLabel then
            -- Animate the value change
            if card.ValueLabel.Text ~= newValue then
                self._utilities.Tween(card.ValueLabel, {
                    TextTransparency = 1
                }, TweenInfo.new(0.15, Enum.EasingStyle.Quad))
                
                task.wait(0.15)
                card.ValueLabel.Text = newValue
                
                self._utilities.Tween(card.ValueLabel, {
                    TextTransparency = 0
                }, TweenInfo.new(0.15, Enum.EasingStyle.Quad))
            end
        end
    end
end

function ProgressionUI:CreateStatCards(parent: Frame)
    local stats = {
        {
            title = "Total Play Time",
            value = self:FormatPlayTime(self.PlayerStats and self.PlayerStats.totalPlayTime or 0),
            icon = "⏱️",
            color = self._config.COLORS.Secondary
        },
        {
            title = "Total Coins Earned",
            value = self._utilities.FormatNumber(self.PlayerStats and self.PlayerStats.totalCoinsEarned or 0),
            icon = "💰",
            color = self._config.COLORS.Warning
        },
        {
            title = "Total Gems Earned",
            value = self._utilities.FormatNumber(self.PlayerStats and self.PlayerStats.totalGemsEarned or 0),
            icon = "💎",
            color = self._config.COLORS.Info
        },
        {
            title = "Pets Collected",
            value = tostring(self.PlayerStats and self.PlayerStats.petsCollected or 0),
            icon = "🐾",
            color = self._config.COLORS.Primary
        },
        {
            title = "Unique Pets",
            value = tostring(self.PlayerStats and self.PlayerStats.uniquePetsOwned or 0),
            icon = "🦄",
            color = self._config.COLORS.Accent
        },
        {
            title = "Eggs Opened",
            value = tostring(self.PlayerStats and self.PlayerStats.eggsOpened or 0),
            icon = "🥚",
            color = self._config.COLORS.Success
        },
        {
            title = "Trades Completed",
            value = tostring(self.PlayerStats and self.PlayerStats.tradesCompleted or 0),
            icon = "🤝",
            color = self._config.COLORS.Info
        },
        {
            title = "Battles Won",
            value = tostring(self.PlayerStats and self.PlayerStats.battlesWon or 0),
            icon = "⚔️",
            color = self._config.COLORS.Error
        },
        {
            title = "Quests Completed",
            value = tostring(self.PlayerStats and self.PlayerStats.questsCompleted or 0),
            icon = "📜",
            color = self._config.COLORS.Secondary
        },
        {
            title = "Achievements",
            value = tostring(self.PlayerStats and self.PlayerStats.achievementsUnlocked or 0),
            icon = "🏆",
            color = self._config.COLORS.Warning
        },
        {
            title = "Cases Opened",
            value = tostring(self.PlayerStats and self.PlayerStats.caseOpenings or 0),
            icon = "📦",
            color = self._config.COLORS.Primary
        },
        {
            title = "Highest Pet Level",
            value = tostring(self.PlayerStats and self.PlayerStats.highestPetLevel or 0),
            icon = "⭐",
            color = self._config.COLORS.Accent
        },
        {
            title = "Daily Streak",
            value = tostring(self.PlayerStats and self.PlayerStats.dailyLoginStreak or 0) .. " days",
            icon = "🔥",
            color = self._config.COLORS.Error
        },
        {
            title = "Best Streak",
            value = tostring(self.PlayerStats and self.PlayerStats.maxDailyStreak or 0) .. " days",
            icon = "🌟",
            color = self._config.COLORS.Warning
        }
    }
    
    -- Initialize stat cards storage if not exists
    if not self.StatCards then
        self.StatCards = {}
    end
    
    for _, stat in ipairs(stats) do
        local statCard = Instance.new("Frame")
        statCard.BackgroundColor3 = self._config.COLORS.White
        statCard.Parent = parent
        
        self._utilities.CreateCorner(statCard, 12)
        self._utilities.CreatePadding(statCard, 15)
        
        -- Store reference for in-place updates
        self.StatCards[stat.title] = {Frame = statCard}
        
        -- Icon
        local iconLabel = self._uiFactory:CreateLabel(statCard, {
            text = stat.icon,
            size = UDim2.new(0, 40, 0, 40),
            position = UDim2.new(0.5, -20, 0, 5),
            textSize = 32
        })
        
        -- Value
        local valueLabel = self._uiFactory:CreateLabel(statCard, {
            text = stat.value,
            size = UDim2.new(1, 0, 0, 25),
            position = UDim2.new(0, 0, 0, 45),
            font = self._config.FONTS.Display,
            textColor = stat.color,
            textSize = 20
        })
        
        -- Store value label reference for in-place updates
        self.StatCards[stat.title].ValueLabel = valueLabel
        
        -- Title
        local titleLabel = self._uiFactory:CreateLabel(statCard, {
            text = stat.title,
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 1, -20),
            textColor = self._config.COLORS.TextSecondary,
            font = self._config.FONTS.Secondary,
            textSize = 12
        })
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ProgressionUI:LoadProgressionData()
    if self._remoteManager then
        -- Load battle pass
        spawn(function()
            local seasonData = self._remoteManager:InvokeServer("GetBattlePassData")
            if seasonData then
                self.CurrentSeason = seasonData
                self:UpdateBattlePassDisplay()
            end
        end)
        
        -- Load achievements
        spawn(function()
            local achievementData = self._remoteManager:InvokeServer("GetAchievements")
            if achievementData then
                self.Achievements = achievementData
                self:ShowAchievements(self.SelectedCategory)
            end
        end)
        
        -- Load stats
        spawn(function()
            local statsData = self._remoteManager:InvokeServer("GetPlayerStats")
            if statsData then
                self.PlayerStats = statsData
                self:UpdateStatsDisplay()
            end
        end)
    else
        -- Use sample data
        self:LoadSampleData()
    end
end

function ProgressionUI:LoadSampleData()
    -- Sample battle pass
    self.CurrentSeason = {
        id = "season_1",
        name = "Sanrio Season",
        theme = "Kawaii Adventure",
        startDate = os.time() - (7 * 24 * 60 * 60), -- Started 7 days ago
        endDate = os.time() + (23 * 24 * 60 * 60), -- Ends in 23 days
        currentTier = 15,
        maxTier = 100,
        isPremium = false,
        experience = 7500,
        rewards = {}
    }
    
    -- Generate sample rewards
    for i = 1, 100 do
        self.CurrentSeason.rewards[i] = {
            tier = i,
            freeReward = i % 5 == 0 and {
                type = "currency",
                id = "coins",
                amount = i * 1000,
                displayName = "Coins",
                icon = "💰"
            } or nil,
            premiumReward = {
                type = i % 10 == 0 and "pet" or "currency",
                id = i % 10 == 0 and "rare_pet_" .. i or "gems",
                amount = i % 10 == 0 and 1 or i * 10,
                displayName = i % 10 == 0 and "Rare Pet" or "Gems",
                icon = i % 10 == 0 and "🦄" or "💎"
            },
            requiredExp = self:CalculateRequiredExp(i),
            claimed = {
                free = i < 10,
                premium = false
            }
        }
    end
    
    -- Sample achievements
    self.Achievements = {
        {
            id = "first_pet",
            name = "First Pet",
            description = "Hatch your first pet from an egg",
            icon = "🥚",
            category = "general",
            tier = "Bronze",
            progress = 1,
            target = 1,
            completed = true,
            claimedAt = os.time() - (5 * 24 * 60 * 60),
            rewards = {{type = "currency", id = "coins", amount = 1000, icon = "💰"}}
        },
        {
            id = "pet_collector",
            name = "Pet Collector",
            description = "Collect 50 different pets",
            icon = "🐾",
            category = "pets",
            tier = "Silver",
            progress = 32,
            target = 50,
            completed = false,
            rewards = {{type = "currency", id = "gems", amount = 100, icon = "💎"}}
        },
        {
            id = "millionaire",
            name = "Millionaire",
            description = "Earn a total of 1,000,000 coins",
            icon = "💰",
            category = "wealth",
            tier = "Gold",
            progress = 750000,
            target = 1000000,
            completed = false,
            rewards = {{type = "pet", id = "golden_pet", amount = 1, icon = "🌟"}}
        }
    }
    
    -- Sample stats
    self.PlayerStats = {
        level = 42,
        experience = 15750,
        nextLevelExp = self:CalculateLevelExp(43),
        prestige = 1,
        totalPlayTime = 72 * 3600, -- 72 hours
        totalCoinsEarned = 5250000,
        totalGemsEarned = 12500,
        petsCollected = 156,
        uniquePetsOwned = 48,
        eggsOpened = 523,
        tradesCompleted = 67,
        battlesWon = 234,
        questsCompleted = 189,
        achievementsUnlocked = 42,
        caseOpenings = 89,
        highestPetLevel = 75,
        dailyLoginStreak = 12,
        maxDailyStreak = 28
    }
    
    -- Update displays
    self:UpdateBattlePassDisplay()
    self:UpdateStatsDisplay()
end

function ProgressionUI:UpdateBattlePassDisplay()
    if not self.CurrentSeason then return end
    
    -- Update tier label
    if self.TierLabel then
        self.TierLabel.Text = "Tier " .. self.CurrentSeason.currentTier .. " / " .. self.CurrentSeason.maxTier
    end
    
    -- Update exp bar
    local currentTierExp = self.CurrentSeason.rewards[self.CurrentSeason.currentTier] and 
                          self.CurrentSeason.rewards[self.CurrentSeason.currentTier].requiredExp or 0
    local nextTierExp = self.CurrentSeason.rewards[self.CurrentSeason.currentTier + 1] and 
                       self.CurrentSeason.rewards[self.CurrentSeason.currentTier + 1].requiredExp or 
                       currentTierExp + 1000
    
    local tierProgress = self.CurrentSeason.experience - currentTierExp
    local tierRequired = nextTierExp - currentTierExp
    
    if self.ExpBar then
        self.ExpBar:SetValue(tierProgress)
        self.ExpBar:SetMaxValue(tierRequired)
    end
    
    if self.ExpLabel then
        self.ExpLabel.Text = tierProgress .. " / " .. tierRequired .. " XP"
    end
    
    -- Update premium button
    if self.PremiumButton then
        self.PremiumButton.Text = self.CurrentSeason.isPremium and "✓ Premium Active" or "🌟 Get Premium Pass"
        self.PremiumButton.BackgroundColor3 = self.CurrentSeason.isPremium and 
                                             self._config.COLORS.Success or self._config.COLORS.Warning
    end
    
    -- Create tier cards
    self:CreateBattlePassTiers()
end

function ProgressionUI:UpdateStatsDisplay()
    if not self.PlayerStats then return end
    
    -- Update level
    if self.LevelLabel then
        self.LevelLabel.Text = "Level " .. self.PlayerStats.level
    end
    
    -- Update exp bar
    local currentLevelExp = self:CalculateLevelExp(self.PlayerStats.level)
    local expInLevel = self.PlayerStats.experience - currentLevelExp
    local expForLevel = self.PlayerStats.nextLevelExp - currentLevelExp
    
    if self.LevelExpBar then
        self.LevelExpBar:SetValue(expInLevel)
        self.LevelExpBar:SetMaxValue(expForLevel)
    end
    
    if self.LevelExpLabel then
        self.LevelExpLabel.Text = expInLevel .. " / " .. expForLevel .. " XP"
    end
    
    -- Update prestige
    if self.PrestigeLabel then
        self.PrestigeLabel.Text = "Prestige " .. self.PlayerStats.prestige
    end
    
    -- Update stat cards in-place instead of recreating
    if self.TabFrames["Statistics"] and self.TabFrames["Statistics"].Visible then
        self:UpdateStatCardsInPlace()
    end
end

function ProgressionUI:UpdateAchievementProgress()
    local completed = 0
    local total = 0
    local points = 0
    
    for _, achievement in pairs(self.Achievements) do
        total = total + 1
        if achievement.completed then
            completed = completed + 1
            points = points + (achievement.tier == "Bronze" and 10 or
                             achievement.tier == "Silver" and 25 or
                             achievement.tier == "Gold" and 50 or
                             achievement.tier == "Platinum" and 100 or
                             achievement.tier == "Diamond" and 200 or 0)
        end
    end
    
    if self.AchievementProgress then
        self.AchievementProgress.Text = completed .. " / " .. total .. " Achievements Completed"
    end
    
    if self.AchievementPoints then
        self.AchievementPoints.Text = points .. " Points"
    end
end

function ProgressionUI:CalculateRequiredExp(tier: number): number
    local baseExp = EXP_PER_LEVEL
    return math.floor(baseExp * math.pow(EXP_SCALING, tier - 1))
end

function ProgressionUI:CalculateLevelExp(level: number): number
    local totalExp = 0
    for i = 1, level - 1 do
        totalExp = totalExp + math.floor(EXP_PER_LEVEL * math.pow(EXP_SCALING, i - 1))
    end
    return totalExp
end

function ProgressionUI:FormatPlayTime(seconds: number): string
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

function ProgressionUI:FormatDate(timestamp: number): string
    if timestamp == 0 then return "Never" end
    
    local date = os.date("*t", timestamp)
    return string.format("%02d/%02d/%04d", date.month, date.day, date.year)
end

function ProgressionUI:StartSeasonTimer()
    spawn(function()
        while self.Frame and self.Frame.Parent and self.CurrentSeason do
            -- Use server time for accuracy
            local serverTime = workspace:GetServerTimeNow()
            local timeLeft = self.CurrentSeason.endDate - serverTime
            
            if timeLeft > 0 then
                local days = math.floor(timeLeft / 86400)
                local hours = math.floor((timeLeft % 86400) / 3600)
                local minutes = math.floor((timeLeft % 3600) / 60)
                local seconds = math.floor(timeLeft % 60)
                
                if self.SeasonTimer then
                    if days > 0 then
                        self.SeasonTimer.Text = string.format("Season ends in: %dd %dh %dm", days, hours, minutes)
                    elseif hours > 0 then
                        self.SeasonTimer.Text = string.format("Season ends in: %dh %dm %ds", hours, minutes, seconds)
                    else
                        self.SeasonTimer.Text = string.format("Season ends in: %dm %ds", minutes, seconds)
                    end
                end
            else
                if self.SeasonTimer then
                    self.SeasonTimer.Text = "Season ended!"
                end
            end
            
            -- Update more frequently when time is low
            local updateInterval = timeLeft > 3600 and 60 or (timeLeft > 60 and 10 or 1)
            task.wait(updateInterval)
        end
    end)
end

-- ========================================
-- ACTIONS
-- ========================================

function ProgressionUI:ClaimReward(tier: number, rewardType: "free" | "premium")
    if self._remoteManager then
        local success = self._remoteManager:InvokeServer("ClaimBattlePassReward", tier, rewardType)
        
        if success then
            -- Update claimed status
            if self.CurrentSeason.rewards[tier] then
                self.CurrentSeason.rewards[tier].claimed[rewardType] = true
            end
            
            -- Refresh display
            self:CreateBattlePassTiers()
            
            -- Show notification
            self._notificationSystem:SendNotification("Reward Claimed!", 
                "You claimed your " .. rewardType .. " reward!", "success")
            
            -- Effects
            if self._soundSystem then
                self._soundSystem:PlayUISound("Success")
            end
        end
    end
end

function ProgressionUI:ShowPremiumPurchase()
    -- Create purchase dialog
    local dialog = self._windowManager:CreateDialog({
        title = "🌟 Premium Battle Pass",
        size = Vector2.new(400, 300),
        content = "Unlock premium rewards and exclusive content!\n\n" ..
                 "• 100 premium tier rewards\n" ..
                 "• Exclusive pets and cosmetics\n" ..
                 "• 25% bonus experience\n" ..
                 "• Premium chat badge\n\n" ..
                 "Price: 999 Robux",
        buttons = {
            {
                text = "Purchase",
                style = "primary",
                callback = function()
                    if Services.MarketplaceService then
                        Services.MarketplaceService:PromptProductPurchase(
                            Services.Players.LocalPlayer,
                            123456789 -- Replace with actual product ID
                        )
                    end
                end
            },
            {
                text = "Cancel",
                style = "secondary"
            }
        }
    })
end

function ProgressionUI:ShowPrestigeInfo()
    local canPrestige = self.PlayerStats and 
                       self.PlayerStats.level >= MAX_LEVEL and 
                       self.PlayerStats.prestige < PRESTIGE_LEVELS
    
    local content = canPrestige and
        "You've reached max level! Ready to prestige?\n\n" ..
        "Prestiging will:\n" ..
        "• Reset your level to 1\n" ..
        "• Grant prestige rewards\n" ..
        "• Unlock exclusive content\n" ..
        "• Increase experience multiplier\n\n" ..
        "Current Prestige: " .. self.PlayerStats.prestige .. " / " .. PRESTIGE_LEVELS
    or
        "Reach level " .. MAX_LEVEL .. " to unlock prestige!\n\n" ..
        "Prestige benefits:\n" ..
        "• Exclusive rewards\n" ..
        "• Special titles\n" ..
        "• Unique cosmetics\n" ..
        "• Experience bonuses\n\n" ..
        "Your level: " .. (self.PlayerStats and self.PlayerStats.level or 1) .. " / " .. MAX_LEVEL
    
    local dialog = self._windowManager:CreateDialog({
        title = "⭐ Prestige System",
        size = Vector2.new(400, 350),
        content = content,
        buttons = canPrestige and {
            {
                text = "Prestige Now",
                style = "primary",
                callback = function()
                    self:ConfirmPrestige()
                end
            },
            {
                text = "Maybe Later",
                style = "secondary"
            }
        } or {
            {
                text = "OK",
                style = "primary"
            }
        }
    })
end

function ProgressionUI:ConfirmPrestige()
    local dialog = self._windowManager:CreateDialog({
        title = "⚠️ Confirm Prestige",
        size = Vector2.new(350, 200),
        content = "Are you sure you want to prestige?\n\n" ..
                 "This action cannot be undone!",
        buttons = {
            {
                text = "Yes, Prestige",
                style = "danger",
                callback = function()
                    self:DoPrestige()
                end
            },
            {
                text = "Cancel",
                style = "secondary"
            }
        }
    })
end

function ProgressionUI:DoPrestige()
    if self._remoteManager then
        local success = self._remoteManager:InvokeServer("Prestige")
        
        if success then
            -- Effects
            if self._effectsLibrary then
                self._effectsLibrary:CreateScreenFlash(self._config.COLORS.Warning)
            end
            
            if self._soundSystem then
                self._soundSystem:PlayUISound("LevelUp")
            end
            
            self._notificationSystem:SendNotification("Prestige Complete!", 
                "Congratulations on your prestige!", "success", 10)
        end
    end
end

function ProgressionUI:ShowRewardTooltip(reward: RewardData, anchor: GuiObject)
    -- Create tooltip near the reward card
    local tooltip = Instance.new("Frame")
    tooltip.Name = "RewardTooltip"
    tooltip.Size = UDim2.new(0, 200, 0, 100)
    tooltip.BackgroundColor3 = self._config.COLORS.Dark
    tooltip.BorderSizePixel = 0
    tooltip.ZIndex = 1000
    tooltip.Parent = self.Frame.Parent
    
    -- Position above anchor
    local pos = anchor.AbsolutePosition
    tooltip.Position = UDim2.new(0, pos.X - 45, 0, pos.Y - 110)
    
    self._utilities.CreateCorner(tooltip, 8)
    self._utilities.CreatePadding(tooltip, 10)
    
    -- Content
    local nameLabel = self._uiFactory:CreateLabel(tooltip, {
        text = reward.displayName,
        size = UDim2.new(1, 0, 0, 20),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.White,
        textSize = 16
    })
    
    local typeLabel = self._uiFactory:CreateLabel(tooltip, {
        text = reward.type:upper(),
        size = UDim2.new(1, 0, 0, 15),
        position = UDim2.new(0, 0, 0, 25),
        textColor = Color3.fromRGB(200, 200, 200),
        textSize = 12
    })
    
    if reward.rarity then
        local rarityColors = {
            Color3.fromRGB(200, 200, 200), -- Common
            Color3.fromRGB(76, 175, 80),   -- Uncommon
            Color3.fromRGB(33, 150, 243),  -- Rare
            Color3.fromRGB(156, 39, 176),  -- Epic
            Color3.fromRGB(255, 152, 0),   -- Legendary
            Color3.fromRGB(233, 30, 99),   -- Mythical
            Color3.fromRGB(255, 235, 59)   -- Secret
        }
        
        local rarityLabel = self._uiFactory:CreateLabel(tooltip, {
            text = "Rarity: " .. reward.rarity,
            size = UDim2.new(1, 0, 0, 15),
            position = UDim2.new(0, 0, 0, 45),
            textColor = rarityColors[reward.rarity] or self._config.COLORS.White,
            textSize = 12
        })
    end
    
    self.CurrentTooltip = tooltip
end

function ProgressionUI:HideTooltip()
    if self.CurrentTooltip then
        self.CurrentTooltip:Destroy()
        self.CurrentTooltip = nil
    end
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

function ProgressionUI:OnBattlePassUpdate(season: Season)
    self.CurrentSeason = season
    self:UpdateBattlePassDisplay()
end

function ProgressionUI:OnTierUnlocked(tier: number)
    -- Animation for tier unlock
    if self._animationSystem then
        local tierCard = self.TierContainer:FindFirstChild("Tier" .. tier)
        if tierCard then
            self._animationSystem:PlayAnimation("pulse", tierCard, {
                scale = 1.2,
                duration = 0.5
            })
        end
    end
    
    -- Notification
    self._notificationSystem:SendNotification("Tier Unlocked!", 
        "You've reached Tier " .. tier .. "!", "success")
    
    -- Sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("LevelUp")
    end
end

function ProgressionUI:OnAchievementProgress(achievement: Achievement)
    -- Find and update achievement card
    for _, card in ipairs(self.AchievementScroll:GetChildren()) do
        if card.Name == achievement.id then
            -- Update progress bar if exists
            local progressBar = card:FindFirstChild("ProgressBar", true)
            if progressBar then
                self._utilities.Tween(progressBar.Fill, {
                    Size = UDim2.new(achievement.progress / achievement.target, 0, 1, 0)
                }, self._config.TWEEN_INFO.Normal)
            end
            break
        end
    end
end

function ProgressionUI:OnAchievementUnlocked(achievement: Achievement)
    -- Update achievement in list
    for i, ach in ipairs(self.Achievements) do
        if ach.id == achievement.id then
            self.Achievements[i] = achievement
            break
        end
    end
    
    -- Refresh display
    if self.CurrentTab == "achievements" then
        self:ShowAchievements(self.SelectedCategory)
    end
    
    -- Big notification
    if self._windowManager then
        self._windowManager:CreateAchievementPopup({
            icon = achievement.icon,
            name = achievement.name,
            tier = achievement.tier,
            description = achievement.description
        })
    end
    
    -- Effects
    if self._effectsLibrary then
        self._effectsLibrary:CreateConfetti(self.Frame)
    end
    
    if self._soundSystem then
        self._soundSystem:PlayUISound("Achievement")
    end
end

function ProgressionUI:OnLevelUp(newLevel: number)
    if self.PlayerStats then
        self.PlayerStats.level = newLevel
        self:UpdateStatsDisplay()
    end
    
    -- Level up notification
    self._notificationSystem:SendNotification("Level Up!", 
        "You've reached Level " .. newLevel .. "!", "success", 5)
    
    -- Effects
    if self._effectsLibrary and self.LevelLabel then
        self._effectsLibrary:CreateGlowEffect(self.LevelLabel, {
            duration = 2,
            color = self._config.COLORS.Accent
        })
    end
    
    if self._soundSystem then
        self._soundSystem:PlayUISound("LevelUp")
    end
end

function ProgressionUI:OnPrestige(prestigeLevel: number)
    if self.PlayerStats then
        self.PlayerStats.prestige = prestigeLevel
        self.PlayerStats.level = 1
        self.PlayerStats.experience = 0
        self:UpdateStatsDisplay()
    end
    
    -- Prestige notification
    self._notificationSystem:SendNotification("PRESTIGE!", 
        "Welcome to Prestige " .. prestigeLevel .. "!", "legendary", 10)
end

function ProgressionUI:OnStatsUpdate(stats: PlayerStats)
    self.PlayerStats = stats
    self:UpdateStatsDisplay()
end

function ProgressionUI:RefreshContent()
    if self.CurrentTab == "battlepass" then
        self:LoadProgressionData()
    elseif self.CurrentTab == "achievements" then
        self:ShowAchievements(self.SelectedCategory)
    elseif self.CurrentTab == "statistics" then
        self:UpdateStatsDisplay()
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function ProgressionUI:Destroy()
    self:Close()
    
    -- Clear references
    self.Frame = nil
    self.TabFrames = {}
    self.BattlePassContainer = nil
    self.AchievementsContainer = nil
    self.StatsContainer = nil
    self.CurrentSeason = nil
    self.PlayerStats = nil
    self.Achievements = {}
    
    -- Hide tooltip
    self:HideTooltip()
end

return ProgressionUI