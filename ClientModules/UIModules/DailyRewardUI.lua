--[[
    Module: DailyRewardUI
    Description: Comprehensive daily reward system with streak tracking, reward grid,
                 claim animations, and multiplier bonuses
    Features: 7-day cycle, streak bonuses, special rewards, countdown timer,
              reward animations, VIP multipliers
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local DailyRewardUI = {}
DailyRewardUI.__index = DailyRewardUI

-- ========================================
-- TYPES
-- ========================================

type DailyReward = {
    day: number,
    coins: number?,
    gems: number?,
    tickets: number?,
    items: {string}?,
    special: string?,
    vipMultiplier: number?
}

type RewardState = {
    streak: number,
    lastClaimed: number,
    currentCycle: number,
    totalDaysClaimed: number,
    vipActive: boolean
}

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(700, 500)
local HEADER_HEIGHT = 80
local DAY_CARD_SIZE = Vector2.new(90, 160)
local CLAIM_COOLDOWN = 24 * 60 * 60 -- 24 hours
local ANIMATION_DURATION = 2

-- Daily rewards cycle (7 days)
local DAILY_REWARDS = {
    {
        day = 1,
        coins = 1000,
        gems = 10,
        description = "Welcome Back!"
    },
    {
        day = 2,
        coins = 2000,
        gems = 20,
        description = "Keep it going!"
    },
    {
        day = 3,
        coins = 3000,
        gems = 30,
        tickets = 1,
        description = "Nice streak!"
    },
    {
        day = 4,
        coins = 4000,
        gems = 40,
        description = "Halfway there!"
    },
    {
        day = 5,
        coins = 5000,
        gems = 50,
        special = "Lucky Potion",
        description = "Special reward!"
    },
    {
        day = 6,
        coins = 6000,
        gems = 60,
        tickets = 2,
        description = "Almost there!"
    },
    {
        day = 7,
        coins = 10000,
        gems = 100,
        special = "Premium Egg",
        description = "Weekly bonus!"
    }
}

-- Streak milestones for bonus rewards
local STREAK_MILESTONES = {
    [7] = {bonus = 0.1, title = "Week Warrior"},
    [14] = {bonus = 0.2, title = "Fortnight Fighter"},
    [30] = {bonus = 0.3, title = "Monthly Master"},
    [50] = {bonus = 0.4, title = "Dedicated Player"},
    [100] = {bonus = 0.5, title = "Century Champion"},
    [365] = {bonus = 1.0, title = "Year Legend"}
}

-- VIP multipliers
local VIP_MULTIPLIERS = {
    coins = 2,
    gems = 1.5,
    tickets = 2
}

-- ========================================
-- INITIALIZATION
-- ========================================

function DailyRewardUI.new(dependencies)
    local self = setmetatable({}, DailyRewardUI)
    
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
    self.Overlay = nil
    self.Window = nil
    self.DayCards = {}
    self.ClaimButton = nil
    self.CountdownLabel = nil
    self.StreakLabel = nil
    
    -- State
    self.RewardState = {
        streak = 0,
        lastClaimed = 0,
        currentCycle = 0,
        totalDaysClaimed = 0,
        vipActive = false
    }
    self.CanClaim = false
    self.TimeRemaining = 0
    self.CountdownConnection = nil
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function DailyRewardUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Daily reward events
    self._eventBus:On("DailyRewardAvailable", function()
        self:CheckAndShow()
    end)
    
    self._eventBus:On("DailyRewardClaimed", function(data)
        self:OnRewardClaimed(data)
    end)
    
    self._eventBus:On("StreakUpdated", function(streak)
        self:UpdateStreak(streak)
    end)
    
    -- Data updates
    self._eventBus:On("DataLoaded", function()
        self:LoadRewardState()
    end)
end

-- ========================================
-- CHECK AND SHOW
-- ========================================

function DailyRewardUI:CheckAndShow()
    -- Check with server if can claim
    if self._remoteManager then
        local result = self._remoteManager:InvokeServer("CheckDailyReward")
        
        if result then
            self.CanClaim = result.canClaim
            self.TimeRemaining = result.timeRemaining or 0
            self.RewardState = result.state or self.RewardState
            
            if self.CanClaim then
                self:ShowDailyRewardWindow()
            else
                -- Show time remaining notification
                local hours = math.floor(self.TimeRemaining / 3600)
                local minutes = math.floor((self.TimeRemaining % 3600) / 60)
                
                self._notificationSystem:SendNotification("Daily Reward", 
                    string.format("Come back in %dh %dm for your daily reward!", hours, minutes), 
                    "info")
            end
        end
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function DailyRewardUI:ShowDailyRewardWindow()
    if self.Overlay then return end
    
    -- Create overlay
    self.Overlay = Instance.new("Frame")
    self.Overlay.Name = "DailyRewardOverlay"
    self.Overlay.Size = UDim2.new(1, 0, 1, 0)
    self.Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    self.Overlay.BackgroundTransparency = 1
    self.Overlay.ZIndex = 600
    self.Overlay.Parent = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI") or
                         Services.Players.LocalPlayer.PlayerGui
    
    -- Fade in overlay
    self._utilities.Tween(self.Overlay, {
        BackgroundTransparency = 0.3
    }, self._config.TWEEN_INFO.Normal)
    
    -- Create window
    self:CreateRewardWindow()
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("DailyReward")
    end
end

function DailyRewardUI:CreateRewardWindow()
    -- Main window
    self.Window = Instance.new("Frame")
    self.Window.Name = "DailyRewardWindow"
    self.Window.Size = UDim2.new(0, WINDOW_SIZE.X, 0, WINDOW_SIZE.Y)
    self.Window.Position = UDim2.new(0.5, -WINDOW_SIZE.X/2, 0.5, -WINDOW_SIZE.Y/2)
    self.Window.BackgroundColor3 = self._config.COLORS.Background
    self.Window.ZIndex = 601
    self.Window.Parent = self.Overlay
    
    self._utilities.CreateCorner(self.Window, 20)
    
    -- Animate window entrance
    self.Window.Size = UDim2.new(0, 0, 0, 0)
    self.Window.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    self._utilities.Tween(self.Window, {
        Size = UDim2.new(0, WINDOW_SIZE.X, 0, WINDOW_SIZE.Y),
        Position = UDim2.new(0.5, -WINDOW_SIZE.X/2, 0.5, -WINDOW_SIZE.Y/2)
    }, self._config.TWEEN_INFO.Bounce)
    
    -- Create components
    self:CreateHeader()
    self:CreateRewardGrid()
    self:CreateFooter()
    
    -- Add effects
    self:AddWindowEffects()
end

function DailyRewardUI:CreateHeader()
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    header.BackgroundColor3 = self._config.COLORS.Primary
    header.ZIndex = 602
    header.Parent = self.Window
    
    -- Create gradient
    local gradient = self._utilities.CreateGradient(header, {
        self._config.COLORS.Primary,
        self._config.COLORS.Accent
    })
    
    -- Title
    local titleLabel = self._uiFactory:CreateLabel(header, {
        text = "🎁 Daily Rewards 🎁",
        size = UDim2.new(1, -60, 0, 40),
        position = UDim2.new(0, 30, 0, 10),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 28,
        zIndex = 603
    })
    
    -- Streak info
    local currentStreak = self.RewardState.streak or 0
    local streakText = self:GetStreakText(currentStreak)
    
    self.StreakLabel = self._uiFactory:CreateLabel(header, {
        text = streakText,
        size = UDim2.new(1, -60, 0, 25),
        position = UDim2.new(0, 30, 0, 45),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.White,
        textSize = 16,
        zIndex = 603
    })
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(header, {
        text = "✖",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0, 20),
        backgroundColor = Color3.fromRGB(255, 65, 65),
        textColor = self._config.COLORS.White,
        textSize = 20,
        zIndex = 604,
        callback = function()
            self:Close()
        end
    })
    
    -- Hover effect for close button
    closeButton.MouseEnter:Connect(function()
        self._utilities.Tween(closeButton, {
            BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        }, self._config.TWEEN_INFO.VeryFast)
    end)
    
    closeButton.MouseLeave:Connect(function()
        self._utilities.Tween(closeButton, {
            BackgroundColor3 = Color3.fromRGB(255, 65, 65)
        }, self._config.TWEEN_INFO.VeryFast)
    end)
end

function DailyRewardUI:CreateRewardGrid()
    -- Container for day cards
    local gridContainer = Instance.new("Frame")
    gridContainer.Size = UDim2.new(1, -40, 1, -200)
    gridContainer.Position = UDim2.new(0, 20, 0, HEADER_HEIGHT + 20)
    gridContainer.BackgroundTransparency = 1
    gridContainer.ZIndex = 602
    gridContainer.Parent = self.Window
    
    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.CellSize = UDim2.new(1/7, -8.5, 0.5, -5)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    gridLayout.Parent = gridContainer
    
    -- Create day cards
    local currentDay = ((self.RewardState.streak - 1) % 7) + 1
    
    for i, reward in ipairs(DAILY_REWARDS) do
        local isClaimed = i < currentDay or (i == currentDay and not self.CanClaim)
        local isToday = i == currentDay and self.CanClaim
        local card = self:CreateDayCard(gridContainer, reward, isClaimed, isToday)
        self.DayCards[i] = card
    end
    
    -- Add multiplier info if VIP
    if self.RewardState.vipActive then
        self:CreateVIPMultiplierInfo(gridContainer)
    end
end

function DailyRewardUI:CreateDayCard(parent: Frame, reward: DailyReward, isClaimed: boolean, isToday: boolean): Frame
    local card = Instance.new("Frame")
    card.Name = "Day" .. reward.day
    card.BackgroundColor3 = isClaimed and self._config.COLORS.Success or self._config.COLORS.White
    card.BackgroundTransparency = isClaimed and 0.3 or 0
    card.ZIndex = 603
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    
    -- Add border for today
    if isToday then
        self._utilities.CreateStroke(card, self._config.COLORS.Warning, 3)
        
        -- Add glow effect
        if self._effectsLibrary then
            self._effectsLibrary:CreateGlowEffect(card, {
                color = self._config.COLORS.Warning,
                size = 20,
                transparency = 0.5
            })
        end
        
        -- Pulse animation
        if self._animationSystem then
            self._animationSystem:PlayAnimation("Pulse", {
                target = card,
                scale = 1.05,
                duration = 1
            })
        end
    end
    
    -- Day label
    local dayLabel = self._uiFactory:CreateLabel(card, {
        text = "Day " .. reward.day,
        size = UDim2.new(1, -10, 0, 30),
        position = UDim2.new(0, 5, 0, 5),
        font = self._config.FONTS.Secondary,
        textColor = isToday and self._config.COLORS.Warning or 
                   (isClaimed and self._config.COLORS.White or self._config.COLORS.Dark),
        textSize = 16,
        zIndex = 604
    })
    
    -- Rewards container
    local rewardsFrame = Instance.new("Frame")
    rewardsFrame.Size = UDim2.new(1, -10, 1, -80)
    rewardsFrame.Position = UDim2.new(0, 5, 0, 35)
    rewardsFrame.BackgroundTransparency = 1
    rewardsFrame.ZIndex = 604
    rewardsFrame.Parent = card
    
    local yOffset = 0
    
    -- Display rewards
    if reward.coins then
        local coinAmount = reward.coins
        if self.RewardState.vipActive then
            coinAmount = math.floor(coinAmount * VIP_MULTIPLIERS.coins)
        end
        
        local coinLabel = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "💰 " .. self._utilities.FormatNumber(coinAmount),
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 0, yOffset),
            textColor = self._config.COLORS.Warning,
            textSize = 14,
            zIndex = 605
        })
        yOffset = yOffset + 20
    end
    
    if reward.gems then
        local gemAmount = reward.gems
        if self.RewardState.vipActive then
            gemAmount = math.floor(gemAmount * VIP_MULTIPLIERS.gems)
        end
        
        local gemLabel = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "💎 " .. self._utilities.FormatNumber(gemAmount),
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 0, yOffset),
            textColor = self._config.COLORS.Info,
            textSize = 14,
            zIndex = 605
        })
        yOffset = yOffset + 20
    end
    
    if reward.tickets then
        local ticketAmount = reward.tickets
        if self.RewardState.vipActive then
            ticketAmount = math.floor(ticketAmount * VIP_MULTIPLIERS.tickets)
        end
        
        local ticketLabel = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "🎟️ " .. ticketAmount,
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 0, yOffset),
            textColor = self._config.COLORS.Secondary,
            textSize = 14,
            zIndex = 605
        })
        yOffset = yOffset + 20
    end
    
    if reward.special then
        local specialLabel = self._uiFactory:CreateLabel(rewardsFrame, {
            text = "🎁 " .. reward.special,
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 0, yOffset),
            textColor = self._config.COLORS.Accent,
            textSize = 12,
            textWrapped = true,
            zIndex = 605
        })
    end
    
    -- Status indicator
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -10, 0, 25)
    statusFrame.Position = UDim2.new(0, 5, 1, -30)
    statusFrame.BackgroundColor3 = isClaimed and self._config.COLORS.Success or 
                                  (isToday and self._config.COLORS.Warning or self._config.COLORS.Surface)
    statusFrame.ZIndex = 604
    statusFrame.Parent = card
    
    self._utilities.CreateCorner(statusFrame, 6)
    
    local statusText = isClaimed and "✓ Claimed" or 
                      (isToday and "Ready!" or "Locked")
    
    local statusLabel = self._uiFactory:CreateLabel(statusFrame, {
        text = statusText,
        size = UDim2.new(1, 0, 1, 0),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.White,
        textSize = 12,
        zIndex = 605
    })
    
    return card
end

function DailyRewardUI:CreateFooter()
    -- Footer container
    local footer = Instance.new("Frame")
    footer.Size = UDim2.new(1, -40, 0, 100)
    footer.Position = UDim2.new(0, 20, 1, -120)
    footer.BackgroundTransparency = 1
    footer.ZIndex = 602
    footer.Parent = self.Window
    
    -- Streak milestone info
    local milestoneInfo = self:GetCurrentMilestone()
    if milestoneInfo then
        local milestoneLabel = self._uiFactory:CreateLabel(footer, {
            text = milestoneInfo.text,
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 0, 0),
            textColor = self._config.COLORS.TextSecondary,
            font = self._config.FONTS.Secondary,
            textSize = 14
        })
    end
    
    -- Claim button
    self.ClaimButton = self._uiFactory:CreateButton(footer, {
        text = "Claim Reward!",
        size = UDim2.new(0, 250, 0, 60),
        position = UDim2.new(0.5, -125, 0.5, -20),
        backgroundColor = self._config.COLORS.Success,
        textSize = 20,
        zIndex = 603,
        callback = function()
            if self.CanClaim then
                self:ClaimDailyReward()
            end
        end
    })
    
    -- Add glow and pulse to claim button
    if self.CanClaim then
        if self._effectsLibrary then
            self._effectsLibrary:CreateGlowEffect(self.ClaimButton, {
                color = self._config.COLORS.Success,
                size = 15
            })
        end
        
        -- Pulse animation
        spawn(function()
            while self.ClaimButton and self.ClaimButton.Parent and self.CanClaim do
                self._utilities.Tween(self.ClaimButton, {
                    Size = UDim2.new(0, 260, 0, 65)
                }, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
                task.wait(0.5)
                
                if self.ClaimButton and self.ClaimButton.Parent then
                    self._utilities.Tween(self.ClaimButton, {
                        Size = UDim2.new(0, 250, 0, 60)
                    }, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
                end
                task.wait(0.5)
            end
        end)
    else
        -- Show countdown
        self.ClaimButton.Active = false
        self.ClaimButton.BackgroundColor3 = self._config.COLORS.TextSecondary
        self:StartCountdown()
    end
    
    -- Total days claimed
    local totalDaysLabel = self._uiFactory:CreateLabel(footer, {
        text = "Total Days Claimed: " .. self.RewardState.totalDaysClaimed,
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 1, -20),
        textColor = self._config.COLORS.TextSecondary,
        textSize = 12
    })
end

function DailyRewardUI:CreateVIPMultiplierInfo(parent: Frame)
    local vipFrame = Instance.new("Frame")
    vipFrame.Size = UDim2.new(1, 0, 0, 30)
    vipFrame.Position = UDim2.new(0, 0, 1, 5)
    vipFrame.BackgroundColor3 = self._config.COLORS.Warning
    vipFrame.BackgroundTransparency = 0.8
    vipFrame.ZIndex = 603
    vipFrame.Parent = parent.Parent
    
    self._utilities.CreateCorner(vipFrame, 8)
    
    local vipLabel = self._uiFactory:CreateLabel(vipFrame, {
        text = "⭐ VIP Active: 2x Coins • 1.5x Gems • 2x Tickets ⭐",
        size = UDim2.new(1, 0, 1, 0),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.Warning,
        textSize = 14,
        zIndex = 604
    })
    
    -- Shine effect
    if self._effectsLibrary then
        self._effectsLibrary:CreateShineEffect(vipFrame, {
            speed = 2,
            interval = 3
        })
    end
end

-- ========================================
-- CLAIM LOGIC
-- ========================================

function DailyRewardUI:ClaimDailyReward()
    if not self.CanClaim then return end
    
    -- Disable button
    self.ClaimButton.Active = false
    self.ClaimButton.Text = "Claiming..."
    
    -- Send claim request
    if self._remoteManager then
        local success, rewards = self._remoteManager:InvokeServer("ClaimDailyReward")
        
        if success then
            -- Update state
            self.CanClaim = false
            self.RewardState.streak = (self.RewardState.streak or 0) + 1
            self.RewardState.lastClaimed = os.time()
            self.RewardState.totalDaysClaimed = (self.RewardState.totalDaysClaimed or 0) + 1
            
            -- Show reward animation
            self:ShowRewardAnimation(rewards)
            
            -- Update UI
            if self._eventBus then
                self._eventBus:Fire("CurrencyUpdated", rewards.currencies)
            end
            
            -- Play sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("RewardClaim")
            end
            
            -- Close after animation
            task.wait(ANIMATION_DURATION)
            self:Close()
        else
            -- Reset button
            self.ClaimButton.Active = true
            self.ClaimButton.Text = "Claim Reward!"
            
            self._notificationSystem:SendNotification("Error", 
                rewards or "Failed to claim daily reward", "error")
        end
    end
end

function DailyRewardUI:ShowRewardAnimation(rewards: table)
    if not rewards or type(rewards) ~= "table" then
        rewards = {}
    end
    
    -- Create reward display
    local rewardDisplay = Instance.new("Frame")
    rewardDisplay.Size = UDim2.new(0, 300, 0, 200)
    rewardDisplay.Position = UDim2.new(0.5, -150, 0.2, 0)
    rewardDisplay.BackgroundColor3 = self._config.COLORS.White
    rewardDisplay.ZIndex = 700
    rewardDisplay.Parent = self.Overlay
    
    self._utilities.CreateCorner(rewardDisplay, 15)
    
    -- Header
    local header = self._uiFactory:CreateLabel(rewardDisplay, {
        text = "🎉 Rewards Claimed! 🎉",
        size = UDim2.new(1, 0, 0, 40),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.Success,
        textSize = 20,
        zIndex = 701
    })
    
    -- Rewards list
    local rewardsList = Instance.new("Frame")
    rewardsList.Size = UDim2.new(1, -40, 1, -60)
    rewardsList.Position = UDim2.new(0, 20, 0, 50)
    rewardsList.BackgroundTransparency = 1
    rewardsList.ZIndex = 701
    rewardsList.Parent = rewardDisplay
    
    local yOffset = 0
    
    -- Display each reward with animation
    if rewards.coins then
        local coinReward = self:CreateRewardItem(rewardsList, 
            "💰 Coins", rewards.coins, self._config.COLORS.Warning, yOffset)
        yOffset = yOffset + 35
    end
    
    if rewards.gems then
        local gemReward = self:CreateRewardItem(rewardsList, 
            "💎 Gems", rewards.gems, self._config.COLORS.Info, yOffset)
        yOffset = yOffset + 35
    end
    
    if rewards.tickets then
        local ticketReward = self:CreateRewardItem(rewardsList, 
            "🎟️ Tickets", rewards.tickets, self._config.COLORS.Secondary, yOffset)
        yOffset = yOffset + 35
    end
    
    if rewards.items and #rewards.items > 0 then
        for _, item in ipairs(rewards.items) do
            local itemReward = self:CreateRewardItem(rewardsList, 
                "📦 " .. item, 1, self._config.COLORS.Accent, yOffset)
            yOffset = yOffset + 35
        end
    end
    
    -- Animate display
    rewardDisplay.Size = UDim2.new(0, 0, 0, 0)
    rewardDisplay.Position = UDim2.new(0.5, 0, 0.2, 0)
    
    self._utilities.Tween(rewardDisplay, {
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.2, 0)
    }, self._config.TWEEN_INFO.Bounce)
    
    -- Particles
    if self._particleSystem then
        self._particleSystem:CreateBurst(rewardDisplay, "star", 
            UDim2.new(0.5, 0, 0.5, 0), 30)
        self._particleSystem:CreateBurst(rewardDisplay, "coin", 
            UDim2.new(0.5, 0, 0.5, 0), 20)
    end
    
    -- Effects
    if self._effectsLibrary then
        self._effectsLibrary:CreateRainbowEffect(header, {
            speed = 2
        })
    end
    
    -- Fade out after delay
    task.wait(ANIMATION_DURATION - 0.5)
    self._utilities.Tween(rewardDisplay, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.2, 0)
    }, self._config.TWEEN_INFO.Normal)
end

function DailyRewardUI:CreateRewardItem(parent: Frame, name: string, amount: number, color: Color3, yPos: number): Frame
    local item = Instance.new("Frame")
    item.Size = UDim2.new(1, 0, 0, 30)
    item.Position = UDim2.new(0, 0, 0, yPos)
    item.BackgroundTransparency = 1
    item.Parent = parent
    
    local nameLabel = self._uiFactory:CreateLabel(item, {
        text = name,
        size = UDim2.new(0.5, 0, 1, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = color,
        font = self._config.FONTS.Secondary,
        textSize = 16
    })
    
    local amountLabel = self._uiFactory:CreateLabel(item, {
        text = "+" .. self._utilities.FormatNumber(amount),
        size = UDim2.new(0.5, 0, 1, 0),
        position = UDim2.new(0.5, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = color,
        font = self._config.FONTS.Numbers,
        textSize = 18
    })
    
    -- Slide in animation
    item.Position = UDim2.new(-1, 0, 0, yPos)
    self._utilities.Tween(item, {
        Position = UDim2.new(0, 0, 0, yPos)
    }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    return item
end

-- ========================================
-- COUNTDOWN
-- ========================================

function DailyRewardUI:StartCountdown()
    if self.CountdownConnection then
        self.CountdownConnection:Disconnect()
    end
    
    self.CountdownConnection = Services.RunService.Heartbeat:Connect(function()
        if not self.ClaimButton or not self.ClaimButton.Parent then
            self:StopCountdown()
            return
        end
        
        local timeLeft = self.TimeRemaining - (os.time() - self.RewardState.lastClaimed)
        
        if timeLeft <= 0 then
            self.ClaimButton.Text = "Claim Reward!"
            self.ClaimButton.Active = true
            self.ClaimButton.BackgroundColor3 = self._config.COLORS.Success
            self.CanClaim = true
            self:StopCountdown()
        else
            local hours = math.floor(timeLeft / 3600)
            local minutes = math.floor((timeLeft % 3600) / 60)
            local seconds = timeLeft % 60
            
            self.ClaimButton.Text = string.format("Next in %02d:%02d:%02d", hours, minutes, seconds)
        end
    end)
end

function DailyRewardUI:StopCountdown()
    if self.CountdownConnection then
        self.CountdownConnection:Disconnect()
        self.CountdownConnection = nil
    end
end

-- ========================================
-- EFFECTS
-- ========================================

function DailyRewardUI:AddWindowEffects()
    -- Background pattern
    local pattern = Instance.new("ImageLabel")
    pattern.Size = UDim2.new(1, 0, 1, 0)
    pattern.BackgroundTransparency = 1
    pattern.Image = "rbxassetid://7360782959" -- Subtle pattern
    pattern.ImageTransparency = 0.95
    pattern.ScaleType = Enum.ScaleType.Tile
    pattern.TileSize = UDim2.new(0, 100, 0, 100)
    pattern.ZIndex = 600
    pattern.Parent = self.Window
    
    -- Floating particles
    spawn(function()
        while self.Window and self.Window.Parent do
            if self._particleSystem then
                self._particleSystem:CreateFloatingParticle(self.Window, "sparkle", {
                    lifetime = 3,
                    velocity = Vector2.new(math.random(-20, 20), -50),
                    size = UDim2.new(0, 20, 0, 20)
                })
            end
            task.wait(0.5)
        end
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function DailyRewardUI:GetStreakText(streak: number): string
    local milestone = self:GetCurrentMilestone()
    
    if milestone then
        return string.format("🔥 %d Day Streak! • %s • +%d%% Bonus!", 
            streak, milestone.title, math.floor(milestone.bonus * 100))
    else
        return string.format("Day %d • Keep your streak going!", streak)
    end
end

function DailyRewardUI:GetCurrentMilestone(): table?
    local streak = self.RewardState.streak or 0
    local currentMilestone = nil
    local nextMilestone = nil
    local nextMilestoneDay = nil
    
    -- Find current milestone
    for days, data in pairs(STREAK_MILESTONES) do
        if streak >= days and (not currentMilestone or days > currentMilestone) then
            currentMilestone = days
        end
        
        if streak < days and (not nextMilestoneDay or days < nextMilestoneDay) then
            nextMilestoneDay = days
            nextMilestone = data
        end
    end
    
    if currentMilestone then
        local data = STREAK_MILESTONES[currentMilestone]
        return {
            text = "Current: " .. data.title,
            title = data.title,
            bonus = data.bonus
        }
    elseif nextMilestone then
        local daysUntil = nextMilestoneDay - streak
        return {
            text = string.format("Next milestone in %d days: %s (+%d%% bonus)", 
                daysUntil, nextMilestone.title, math.floor(nextMilestone.bonus * 100)),
            title = "Building Streak",
            bonus = 0
        }
    end
    
    return nil
end

function DailyRewardUI:LoadRewardState()
    local playerData = self._dataCache and self._dataCache:Get() or {}
    
    if playerData.dailyRewards then
        self.RewardState = {
            streak = playerData.dailyRewards.streak or 0,
            lastClaimed = playerData.dailyRewards.lastClaimed or 0,
            currentCycle = playerData.dailyRewards.currentCycle or 0,
            totalDaysClaimed = playerData.dailyRewards.totalDaysClaimed or 0,
            vipActive = playerData.gamepasses and playerData.gamepasses.vip or false
        }
    end
end

function DailyRewardUI:UpdateStreak(streak: number)
    self.RewardState.streak = streak
    
    if self.StreakLabel then
        self.StreakLabel.Text = self:GetStreakText(streak)
        
        -- Add effect for milestone
        local milestone = self:GetCurrentMilestone()
        if milestone and milestone.bonus > 0 then
            if self._effectsLibrary then
                self._effectsLibrary:CreateGlowEffect(self.StreakLabel, {
                    color = self._config.COLORS.Warning,
                    size = 10,
                    duration = 2
                })
            end
        end
    end
end

function DailyRewardUI:OnRewardClaimed(data: table)
    -- Update state
    self.RewardState = data.state or self.RewardState
    
    -- Show achievement if milestone reached
    for days, milestone in pairs(STREAK_MILESTONES) do
        if self.RewardState.streak == days then
            self._notificationSystem:SendNotification("Milestone Reached!", 
                milestone.title .. " - " .. math.floor(milestone.bonus * 100) .. "% bonus rewards!", 
                "success", 10)
            
            -- Special effects
            if self._particleSystem then
                self._particleSystem:CreateBurst(self.Window or self.Overlay, "star", 
                    UDim2.new(0.5, 0, 0.5, 0), 50)
            end
            
            if self._soundSystem then
                self._soundSystem:PlayUISound("Achievement")
            end
            
            break
        end
    end
end

-- ========================================
-- CLOSE
-- ========================================

function DailyRewardUI:Close()
    self:StopCountdown()
    
    if self.Window then
        -- Animate out
        self._utilities.Tween(self.Window, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, self._config.TWEEN_INFO.Normal)
    end
    
    if self.Overlay then
        self._utilities.Tween(self.Overlay, {
            BackgroundTransparency = 1
        }, self._config.TWEEN_INFO.Normal)
        
        task.wait(0.3)
        self.Overlay:Destroy()
        self.Overlay = nil
    end
    
    -- Clear references
    self.Window = nil
    self.DayCards = {}
    self.ClaimButton = nil
    self.CountdownLabel = nil
    self.StreakLabel = nil
end

-- ========================================
-- CLEANUP
-- ========================================

function DailyRewardUI:Destroy()
    self:Close()
    
    -- Clear all references
    self.RewardState = {}
    self.CanClaim = false
    self.TimeRemaining = 0
end

return DailyRewardUI