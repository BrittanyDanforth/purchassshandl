-- ========================================
-- DAILY REWARD UI MODULE
-- ========================================
UIModules.DailyRewardUI = {}

function UIModules.DailyRewardUI:CheckAndShow()
    -- Check if can claim daily reward
    local canClaim, timeRemaining = RemoteFunctions.CheckDailyReward:InvokeServer()
    
    if canClaim then
        self:ShowDailyRewardWindow()
    else
        -- Show time remaining
        local hours = math.floor(timeRemaining / 3600)
        local minutes = math.floor((timeRemaining % 3600) / 60)
        NotificationSystem:SendNotification("Daily Reward", string.format("Come back in %dh %dm for your daily reward!", hours, minutes), "info")
    end
end

function UIModules.DailyRewardUI:ShowDailyRewardWindow()
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "DailyRewardOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 600
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Daily reward window
    local rewardWindow = Instance.new("Frame")
    rewardWindow.Name = "DailyRewardWindow"
    rewardWindow.Size = UDim2.new(0, 700, 0, 500)
    rewardWindow.Position = UDim2.new(0.5, -350, 0.5, -250)
    rewardWindow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    rewardWindow.ZIndex = 601
    rewardWindow.Parent = overlay
    
    Utilities:CreateCorner(rewardWindow, 20)
    Utilities:CreateShadow(rewardWindow, 0.5, 30)
    
    -- Animate in
    rewardWindow.Position = UDim2.new(0.5, -350, 0.5, -250)
    rewardWindow.Size = UDim2.new(0, 0, 0, 0)
    Utilities:Tween(rewardWindow, {
        Size = UDim2.new(0, 700, 0, 500),
        Position = UDim2.new(0.5, -350, 0.5, -250)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 602
    header.Parent = rewardWindow
    
    Utilities:CreateCorner(header, 20)
    
    local bottomRect = Instance.new("Frame")
    bottomRect.Size = UDim2.new(1, 0, 0, 20)
    bottomRect.Position = UDim2.new(0, 0, 1, -20)
    bottomRect.BackgroundColor3 = header.BackgroundColor3
    bottomRect.BorderSizePixel = 0
    bottomRect.ZIndex = 602
    bottomRect.Parent = header
    
    -- Title
    local titleLabel = UIComponents:CreateLabel(header, "🎁 Daily Rewards 🎁", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 28)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 603
    
    -- Streak info
    local streakLabel = UIComponents:CreateLabel(header, "Day 1 • Keep your streak going!", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 45), 16)
    streakLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    streakLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    streakLabel.ZIndex = 603
    
    -- Days grid
    local daysContainer = Instance.new("Frame")
    daysContainer.Size = UDim2.new(1, -40, 1, -140)
    daysContainer.Position = UDim2.new(0, 20, 0, 100)
    daysContainer.BackgroundTransparency = 1
    daysContainer.ZIndex = 602
    daysContainer.Parent = rewardWindow
    
    local daysGrid = Instance.new("UIGridLayout")
    daysGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    daysGrid.CellSize = UDim2.new(1/7, -8.5, 0.5, -5)
    daysGrid.FillDirection = Enum.FillDirection.Horizontal
    daysGrid.Parent = daysContainer
    
    -- Create day cards
    local dailyRewards = {
        {day = 1, coins = 1000, gems = 10},
        {day = 2, coins = 2000, gems = 20},
        {day = 3, coins = 3000, gems = 30},
        {day = 4, coins = 4000, gems = 40},
        {day = 5, coins = 5000, gems = 50, special = "Lucky Potion"},
        {day = 6, coins = 6000, gems = 60},
        {day = 7, coins = 10000, gems = 100, special = "Premium Egg"}
    }
    
    local currentStreak = LocalData.PlayerData and LocalData.PlayerData.dailyRewards.streak or 1
    
    for i, reward in ipairs(dailyRewards) do
        local dayCard = self:CreateDayCard(daysContainer, reward, i <= currentStreak, i == currentStreak)
    end
    
    -- Claim button
    local claimButton = UIComponents:CreateButton(rewardWindow, "Claim Reward!", UDim2.new(0, 250, 0, 60), UDim2.new(0.5, -125, 1, -80), function()
        self:ClaimDailyReward(overlay)
    end)
    claimButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    claimButton.TextSize = 20
    claimButton.ZIndex = 603
    
    -- Add glow effect to button
    spawn(function()
        while claimButton.Parent do
            Utilities:Tween(claimButton, {Size = UDim2.new(0, 260, 0, 65)}, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
            wait(0.5)
            Utilities:Tween(claimButton, {Size = UDim2.new(0, 250, 0, 60)}, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
            wait(0.5)
        end
    end)
    
    -- Update streak label
    if LocalData.PlayerData then
        streakLabel.Text = string.format("Day %d • Keep your streak going!", currentStreak)
    end
end

function UIModules.DailyRewardUI:CreateDayCard(parent, reward, isClaimed, isToday)
    local card = Instance.new("Frame")
    card.Name = "Day" .. reward.day
    card.BackgroundColor3 = isClaimed and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.White
    card.BackgroundTransparency = isClaimed and 0.3 or 0
    card.ZIndex = 603
    card.Parent = parent
    
    Utilities:CreateCorner(card, 12)
    
    if isToday then
        -- Add glow effect
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1, 20, 1, 20)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = CLIENT_CONFIG.COLORS.Warning
        glow.ZIndex = 602
        glow.Parent = card
        
        -- Animate glow
        spawn(function()
            while glow.Parent do
                Utilities:Tween(glow, {Size = UDim2.new(1, 30, 1, 30), ImageTransparency = 0.7}, TweenInfo.new(1, Enum.EasingStyle.Sine))
                wait(1)
                Utilities:Tween(glow, {Size = UDim2.new(1, 20, 1, 20), ImageTransparency = 0.5}, TweenInfo.new(1, Enum.EasingStyle.Sine))
                wait(1)
            end
        end)
        
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
    end
    
    -- Day label
    local dayLabel = UIComponents:CreateLabel(card, "Day " .. reward.day, UDim2.new(1, -10, 0, 25), UDim2.new(0, 5, 0, 5), 16)
    dayLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    dayLabel.TextColor3 = isToday and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    dayLabel.ZIndex = 604
    
    -- Rewards
    local rewardY = 35
    
    -- Coins
    local coinLabel = UIComponents:CreateLabel(card, "💰 " .. Utilities:FormatNumber(reward.coins), UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, rewardY), 14)
    coinLabel.TextColor3 = isToday and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    coinLabel.ZIndex = 604
    rewardY = rewardY + 20
    
    -- Gems
    local gemLabel = UIComponents:CreateLabel(card, "💎 " .. reward.gems, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, rewardY), 14)
    gemLabel.TextColor3 = isToday and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    gemLabel.ZIndex = 604
    rewardY = rewardY + 20
    
    -- Special reward
    if reward.special then
        local specialLabel = UIComponents:CreateLabel(card, "🎁 " .. reward.special, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, rewardY), 12)
        specialLabel.TextColor3 = CLIENT_CONFIG.COLORS.Accent
        specialLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        specialLabel.TextWrapped = true
        specialLabel.ZIndex = 604
    end
    
    -- Claimed checkmark
    if isClaimed and not isToday then
        local checkmark = UIComponents:CreateLabel(card, "✓", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 48)
        checkmark.TextColor3 = CLIENT_CONFIG.COLORS.White
        checkmark.TextTransparency = 0.5
        checkmark.Font = CLIENT_CONFIG.FONTS.Display
        checkmark.ZIndex = 605
    end
    
    return card
end

function UIModules.DailyRewardUI:ClaimDailyReward(overlay)
    local success, rewards = RemoteFunctions.ClaimDailyReward:InvokeServer()
    
    if success then
        -- Show reward animation
        self:ShowRewardAnimation(rewards)
        
        -- Update UI
        if MainUI.UpdateCurrency and LocalData.PlayerData then
            MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
        end
        
        -- Close window after delay
        wait(2)
        Utilities:Tween(overlay:FindFirstChild("DailyRewardWindow"), {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        wait(0.3)
        overlay:Destroy()
    else
        NotificationSystem:SendNotification("Error", rewards or "Failed to claim daily reward", "error")
    end
end

function UIModules.DailyRewardUI:ShowRewardAnimation(rewards)
    -- Create reward display
    local rewardDisplay = Instance.new("Frame")
    rewardDisplay.Size = UDim2.new(0, 300, 0, 200)
    rewardDisplay.Position = UDim2.new(0.5, -150, 0.5, -100)
    rewardDisplay.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    rewardDisplay.ZIndex = 700
    rewardDisplay.Parent = MainUI.ScreenGui
    
    Utilities:CreateCorner(rewardDisplay, 12)
    Utilities:CreateShadow(rewardDisplay, 0.5)
    
    -- Title
    local titleLabel = UIComponents:CreateLabel(rewardDisplay, "Rewards Claimed!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 20)
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.Success
    titleLabel.ZIndex = 701
    
    -- Rewards list
    local yOffset = 60
    if rewards.coins then
        local coinLabel = UIComponents:CreateLabel(rewardDisplay, "+ " .. Utilities:FormatNumber(rewards.coins) .. " Coins", 
            UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, yOffset), 18)
        coinLabel.TextColor3 = CLIENT_CONFIG.COLORS.Warning
        coinLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        coinLabel.ZIndex = 701
        yOffset = yOffset + 30
    end
    
    if rewards.gems then
        local gemLabel = UIComponents:CreateLabel(rewardDisplay, "+ " .. rewards.gems .. " Gems", 
            UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, yOffset), 18)
        gemLabel.TextColor3 = CLIENT_CONFIG.COLORS.Primary
        gemLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        gemLabel.ZIndex = 701
        yOffset = yOffset + 30
    end
    
    -- Particles
    ParticleSystem:CreateBurst(rewardDisplay, "coin", UDim2.new(0.5, 0, 0.5, 0), 20)
    
    -- Sound
    Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
    
    -- Animate
    rewardDisplay.Size = UDim2.new(0, 0, 0, 0)
    rewardDisplay.Position = UDim2.new(0.5, 0, 0.5, 0)
    Utilities:Tween(rewardDisplay, {
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Auto close
    wait(3)
    Utilities:Tween(rewardDisplay, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    wait(0.3)
    rewardDisplay:Destroy()
end

-- ========================================
-- LEADERBOARD UI MODULE
-- ========================================
UIModules.LeaderboardUI = {}

function UIModules.LeaderboardUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshLeaderboards()
        return
    end
    
    -- Create main leaderboard frame
    local leaderboardFrame = UIComponents:CreateFrame(MainUI.MainContainer, "LeaderboardFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    leaderboardFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = leaderboardFrame
    
    -- Header
    local header = UIComponents:CreateFrame(leaderboardFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "🏆 Leaderboards 🏆", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Create tabs
    local tabs = {
        {
            Name = "Top Coins",
            Init = function(parent)
                self:CreateLeaderboard(parent, "coins")
            end
        },
        {
            Name = "Top Gems",
            Init = function(parent)
                self:CreateLeaderboard(parent, "gems")
            end
        },
        {
            Name = "Battle Rating",
            Init = function(parent)
                self:CreateLeaderboard(parent, "battle")
            end
        },
        {
            Name = "Pet Collection",
            Init = function(parent)
                self:CreateLeaderboard(parent, "pets")
            end
        }
    }
    
    local tabContainer, tabFrames = UIComponents:CreateTab(leaderboardFrame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    self.TabFrames = tabFrames
    
    -- Refresh timer
    spawn(function()
        while self.Frame and self.Frame.Parent do
            wait(30) -- Refresh every 30 seconds
            self:RefreshLeaderboards()
        end
    end)
end

function UIModules.LeaderboardUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.LeaderboardUI:CreateLeaderboard(parent, leaderboardType)
    -- Your rank display
    local yourRankFrame = Instance.new("Frame")
    yourRankFrame.Size = UDim2.new(1, -20, 0, 80)
    yourRankFrame.Position = UDim2.new(0, 10, 0, 10)
    yourRankFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    yourRankFrame.Parent = parent
    
    Utilities:CreateCorner(yourRankFrame, 12)
    Utilities:CreatePadding(yourRankFrame, 15)
    
    local yourRankLabel = UIComponents:CreateLabel(yourRankFrame, "Your Rank: #???", UDim2.new(0.3, 0, 1, 0), UDim2.new(0, 0, 0, 0), 20)
    yourRankLabel.TextXAlignment = Enum.TextXAlignment.Left
    yourRankLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    yourRankLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local yourValueLabel = UIComponents:CreateLabel(yourRankFrame, "0", UDim2.new(0.7, 0, 1, 0), UDim2.new(0.3, 0, 0, 0), 24)
    yourValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    yourValueLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    yourValueLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Leaderboard list
    local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -20, 1, -110), UDim2.new(0, 10, 0, 100))
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Store references
    if not self.Leaderboards then
        self.Leaderboards = {}
    end
    
    self.Leaderboards[leaderboardType] = {
        Container = scrollFrame,
        YourRankLabel = yourRankLabel,
        YourValueLabel = yourValueLabel
    }
end

function UIModules.LeaderboardUI:CreateLeaderboardEntry(parent, rank, playerName, value, isYou)
    local entry = Instance.new("Frame")
    entry.Name = "Rank" .. rank
    entry.Size = UDim2.new(1, -10, 0, 60)
    entry.BackgroundColor3 = isYou and CLIENT_CONFIG.COLORS.Primary or CLIENT_CONFIG.COLORS.White
    entry.BackgroundTransparency = isYou and 0.2 or 0
    entry.LayoutOrder = rank
    entry.Parent = parent
    
    Utilities:CreateCorner(entry, 8)
    Utilities:CreatePadding(entry, 10)
    
    -- Rank display
    local rankFrame = Instance.new("Frame")
    rankFrame.Size = UDim2.new(0, 50, 1, 0)
    rankFrame.BackgroundTransparency = 1
    rankFrame.Parent = entry
    
    local rankLabel = UIComponents:CreateLabel(rankFrame, "#" .. rank, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 20)
    rankLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Special colors for top 3
    if rank == 1 then
        rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    elseif rank == 2 then
        rankLabel.TextColor3 = Color3.fromRGB(192, 192, 192) -- Silver
    elseif rank == 3 then
        rankLabel.TextColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
    else
        rankLabel.TextColor3 = isYou and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    end
    
    -- Player info
    local playerLabel = UIComponents:CreateLabel(entry, playerName, UDim2.new(0.5, -70, 1, 0), UDim2.new(0, 60, 0, 0), 16)
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    playerLabel.TextColor3 = isYou and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    
    -- Value
    local valueLabel = UIComponents:CreateLabel(entry, Utilities:FormatNumber(value), UDim2.new(0.4, -10, 1, 0), UDim2.new(0.6, 0, 0, 0), 18)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = CLIENT_CONFIG.FONTS.Numbers
    valueLabel.TextColor3 = isYou and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Primary
    
    -- Trophy icon for top 3
    if rank <= 3 then
        local trophy = UIComponents:CreateLabel(entry, rank == 1 and "🥇" or rank == 2 and "🥈" or "🥉", 
            UDim2.new(0, 30, 0, 30), UDim2.new(1, -40, 0.5, -15), 24)
        trophy.ZIndex = entry.ZIndex + 1
    end
    
    return entry
end

function UIModules.LeaderboardUI:RefreshLeaderboards()
    -- TODO: Fetch leaderboard data from server
    -- For now, use sample data
    
    local sampleData = {
        coins = {
            {name = "RichPlayer123", value = 999999999},
            {name = "CoinMaster", value = 500000000},
            {name = "MoneyBags", value = 250000000},
            {name = "Wealthy", value = 100000000},
            {name = "Collector", value = 50000000}
        },
        gems = {
            {name = "GemHoarder", value = 999999},
            {name = "DiamondKing", value = 500000},
            {name = "JewelMaster", value = 250000},
            {name = "GemCollector", value = 100000},
            {name = "Sparkles", value = 50000}
        }
    }
    
    -- Update each leaderboard
    for leaderboardType, data in pairs(sampleData) do
        if self.Leaderboards and self.Leaderboards[leaderboardType] then
            local container = self.Leaderboards[leaderboardType].Container
            
            -- Clear existing
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            -- Add entries
            for i, entry in ipairs(data) do
                self:CreateLeaderboardEntry(container, i, entry.name, entry.value, entry.name == LocalPlayer.Name)
            end
            
            -- Update your rank (sample)
            self.Leaderboards[leaderboardType].YourRankLabel.Text = "Your Rank: #42"
            self.Leaderboards[leaderboardType].YourValueLabel.Text = Utilities:FormatNumber(12345)
        end
    end
end

-- ========================================
-- PROFILE UI MODULE
-- ========================================
UIModules.ProfileUI = {}

function UIModules.ProfileUI:ShowProfile(player)
    -- Create profile overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "ProfileOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 700
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Profile window
    local profileWindow = Instance.new("Frame")
    profileWindow.Name = "ProfileWindow"
    profileWindow.Size = UDim2.new(0, 800, 0, 600)
    profileWindow.Position = UDim2.new(0.5, -400, 0.5, -300)
    profileWindow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    profileWindow.ZIndex = 701
    profileWindow.Parent = overlay
    
    Utilities:CreateCorner(profileWindow, 20)
    Utilities:CreateShadow(profileWindow, 0.5, 30)
    
    -- Animate in
    profileWindow.Position = UDim2.new(0.5, -400, 0.5, -300)
    profileWindow.Size = UDim2.new(0, 0, 0, 0)
    Utilities:Tween(profileWindow, {
        Size = UDim2.new(0, 800, 0, 600),
        Position = UDim2.new(0.5, -400, 0.5, -300)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Header with gradient
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 150)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 702
    header.Parent = profileWindow
    
    Utilities:CreateCorner(header, 20)
    Utilities:CreateGradient(header, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.Primary),
        ColorSequenceKeypoint.new(1, CLIENT_CONFIG.COLORS.Secondary)
    })
    
    -- Profile picture
    local profilePic = Instance.new("ImageLabel")
    profilePic.Size = UDim2.new(0, 120, 0, 120)
    profilePic.Position = UDim2.new(0, 30, 0.5, -60)
    profilePic.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    profilePic.Image = Services.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    profilePic.ZIndex = 703
    profilePic.Parent = header
    
    Utilities:CreateCorner(profilePic, 60)
    Utilities:CreateStroke(profilePic, CLIENT_CONFIG.COLORS.White, 4)
    
    -- Player name
    local nameLabel = UIComponents:CreateLabel(header, player.DisplayName, UDim2.new(0.5, -170, 0, 40), UDim2.new(0, 170, 0, 20), 28)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    nameLabel.Font = CLIENT_CONFIG.FONTS.Display
    nameLabel.ZIndex = 703
    
    -- Username if different
    if player.Name ~= player.DisplayName then
        local usernameLabel = UIComponents:CreateLabel(header, "@" .. player.Name, UDim2.new(0.5, -170, 0, 30), UDim2.new(0, 170, 0, 65), 16)
        usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
        usernameLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
        usernameLabel.TextTransparency = 0.3
        usernameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        usernameLabel.ZIndex = 703
    end
    
    -- Level/Status
    local levelLabel = UIComponents:CreateLabel(header, "Level 42 • Tycoon Master", UDim2.new(0.5, -170, 0, 30), UDim2.new(0, 170, 0, 100), 16)
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    levelLabel.ZIndex = 703
    
    -- Action buttons
    if player ~= LocalPlayer then
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Size = UDim2.new(0, 300, 0, 40)
        buttonContainer.Position = UDim2.new(1, -320, 0.5, -20)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.ZIndex = 703
        buttonContainer.Parent = header
        
        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonLayout.Padding = UDim.new(0, 10)
        buttonLayout.Parent = buttonContainer
        
        -- Add friend button
        local friendButton = UIComponents:CreateButton(buttonContainer, "Add Friend", UDim2.new(0, 90, 1, 0), nil, function()
            -- TODO: Add friend
        end)
        friendButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
        friendButton.ZIndex = 704
        
        -- Trade button
        local tradeButton = UIComponents:CreateButton(buttonContainer, "Trade", UDim2.new(0, 90, 1, 0), nil, function()
            UIModules.TradingUI:InitiateTrade(player)
            overlay:Destroy()
        end)
        tradeButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Info
        tradeButton.ZIndex = 704
        
        -- Battle button
        local battleButton = UIComponents:CreateButton(buttonContainer, "Battle", UDim2.new(0, 90, 1, 0), nil, function()
            UIModules.BattleUI:ChallengePlayer(player)
            overlay:Destroy()
        end)
        battleButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
        battleButton.ZIndex = 704
    end
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 24
    closeButton.ZIndex = 704
    closeButton.Parent = header
    
    closeButton.MouseButton1Click:Connect(function()
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Close)
        Utilities:Tween(profileWindow, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        wait(0.3)
        overlay:Destroy()
    end)
    
    -- Content tabs
    local tabs = {
        {
            Name = "Stats",
            Init = function(parent)
                self:ShowProfileStats(parent, player)
            end
        },
        {
            Name = "Pets",
            Init = function(parent)
                self:ShowProfilePets(parent, player)
            end
        },
        {
            Name = "Achievements",
            Init = function(parent)
                self:ShowProfileAchievements(parent, player)
            end
        },
        {
            Name = "Badges",
            Init = function(parent)
                self:ShowProfileBadges(parent, player)
            end
        }
    }
    
    UIComponents:CreateTab(profileWindow, tabs, UDim2.new(1, -20, 1, -170), UDim2.new(0, 10, 0, 160))
end

function UIModules.ProfileUI:ShowProfileStats(parent, player)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, -20, 0, 600)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = scrollFrame
    
    -- Stats grid
    local statsGrid = Instance.new("UIGridLayout")
    statsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    statsGrid.CellSize = UDim2.new(0.5, -5, 0, 100)
    statsGrid.FillDirection = Enum.FillDirection.Horizontal
    statsGrid.Parent = statsContainer
    
    Utilities:CreatePadding(statsContainer, 10)
    
    -- Sample stats
    local stats = {
        {title = "Total Wealth", value = "1.5M", icon = "💰", color = CLIENT_CONFIG.COLORS.Warning},
        {title = "Pets Owned", value = "127", icon = "🐾", color = CLIENT_CONFIG.COLORS.Primary},
        {title = "Battle Wins", value = "342", icon = "⚔️", color = CLIENT_CONFIG.COLORS.Success},
        {title = "Trades Completed", value = "89", icon = "🤝", color = CLIENT_CONFIG.COLORS.Info},
        {title = "Play Time", value = "127h", icon = "⏱️", color = CLIENT_CONFIG.COLORS.Secondary},
        {title = "Achievements", value = "45/100", icon = "🏆", color = CLIENT_CONFIG.COLORS.Accent}
    }
    
    for _, stat in ipairs(stats) do
        local statCard = Instance.new("Frame")
        statCard.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
        statCard.Parent = statsContainer
        
        Utilities:CreateCorner(statCard, 12)
        Utilities:CreatePadding(statCard, 15)
        
        -- Icon
        local iconLabel = UIComponents:CreateLabel(statCard, stat.icon, UDim2.new(0, 50, 0, 50), UDim2.new(0, 0, 0, 0), 36)
        
        -- Title
        local titleLabel = UIComponents:CreateLabel(statCard, stat.title, UDim2.new(1, -60, 0, 25), UDim2.new(0, 60, 0, 10), 14)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        titleLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        
        -- Value
        local valueLabel = UIComponents:CreateLabel(statCard, stat.value, UDim2.new(1, -60, 0, 35), UDim2.new(0, 60, 0, 35), 24)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.TextColor3 = stat.color
        valueLabel.Font = CLIENT_CONFIG.FONTS.Display
    end
    
    -- Update canvas
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, statsGrid.AbsoluteContentSize.Y + 20)
end

function UIModules.ProfileUI:ShowProfilePets(parent, player)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local petsGrid = Instance.new("UIGridLayout")
    petsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    petsGrid.CellSize = UDim2.new(0, 120, 0, 140)
    petsGrid.FillDirection = Enum.FillDirection.Horizontal
    petsGrid.Parent = scrollFrame
    
    -- Note for other players
    if player ~= LocalPlayer then
        local noteLabel = UIComponents:CreateLabel(parent, "This player's pet collection is private", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 18)
        noteLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noteLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    else
        -- Show own pets
        -- TODO: Load pets
    end
end

function UIModules.ProfileUI:ShowProfileAchievements(parent, player)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local achievementList = Instance.new("Frame")
    achievementList.Size = UDim2.new(1, -20, 0, 800)
    achievementList.BackgroundTransparency = 1
    achievementList.Parent = scrollFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = achievementList
    
    Utilities:CreatePadding(achievementList, 10)
    
    -- Sample achievements
    local achievements = {
        {name = "First Steps", desc = "Open your first egg", icon = "🥚", unlocked = true, tier = "Bronze"},
        {name = "Pet Collector", desc = "Collect 10 different pets", icon = "🐾", unlocked = true, tier = "Bronze"},
        {name = "Millionaire", desc = "Earn 1,000,000 coins", icon = "💰", unlocked = true, tier = "Silver"},
        {name = "Battle Master", desc = "Win 100 battles", icon = "⚔️", unlocked = false, tier = "Gold"},
        {name = "Legendary Trainer", desc = "Own a legendary pet", icon = "✨", unlocked = false, tier = "Gold"}
    }
    
    for _, achievement in ipairs(achievements) do
        local achievementCard = Instance.new("Frame")
        achievementCard.Size = UDim2.new(1, 0, 0, 80)
        achievementCard.BackgroundColor3 = achievement.unlocked and CLIENT_CONFIG.COLORS.White or Color3.fromRGB(230, 230, 230)
        achievementCard.Parent = achievementList
        
        Utilities:CreateCorner(achievementCard, 12)
        Utilities:CreatePadding(achievementCard, 15)
        
        -- Icon
        local iconLabel = UIComponents:CreateLabel(achievementCard, achievement.icon, UDim2.new(0, 50, 0, 50), UDim2.new(0, 0, 0.5, -25), 36)
        iconLabel.TextTransparency = achievement.unlocked and 0 or 0.5
        
        -- Info
        local nameLabel = UIComponents:CreateLabel(achievementCard, achievement.name, UDim2.new(1, -150, 0, 25), UDim2.new(0, 60, 0, 10), 16)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        nameLabel.TextColor3 = achievement.unlocked and CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(150, 150, 150)
        
        local descLabel = UIComponents:CreateLabel(achievementCard, achievement.desc, UDim2.new(1, -150, 0, 25), UDim2.new(0, 60, 0, 35), 14)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        
        -- Tier badge
        local tierColors = {
            Bronze = Color3.fromRGB(205, 127, 50),
            Silver = Color3.fromRGB(192, 192, 192),
            Gold = Color3.fromRGB(255, 215, 0)
        }
        
        local tierBadge = Instance.new("Frame")
        tierBadge.Size = UDim2.new(0, 80, 0, 25)
        tierBadge.Position = UDim2.new(1, -90, 0.5, -12.5)
        tierBadge.BackgroundColor3 = tierColors[achievement.tier] or CLIENT_CONFIG.COLORS.Primary
        tierBadge.Parent = achievementCard
        
        Utilities:CreateCorner(tierBadge, 12)
        
        local tierLabel = UIComponents:CreateLabel(tierBadge, achievement.tier, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 12)
        tierLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
        tierLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        
        if not achievement.unlocked then
            tierBadge.BackgroundTransparency = 0.5
        end
    end
    
    -- Update canvas
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end

-- ========================================
-- CLAN UI MODULE
-- ========================================
UIModules.ClanUI = {}

function UIModules.ClanUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main clan frame
    local clanFrame = UIComponents:CreateFrame(MainUI.MainContainer, "ClanFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    clanFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = clanFrame
    
    -- Header
    local header = UIComponents:CreateFrame(clanFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "⚔️ Clan System ⚔️", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Check if player is in a clan
    if LocalData.PlayerData and LocalData.PlayerData.clan.id then
        self:ShowClanInterface()
    else
        self:ShowNoClanInterface()
    end
end

function UIModules.ClanUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.ClanUI:ShowNoClanInterface()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 1, -80)
    container.Position = UDim2.new(0, 10, 0, 70)
    container.BackgroundTransparency = 1
    container.Parent = self.Frame
    
    -- Create clan section
    local createSection = Instance.new("Frame")
    createSection.Size = UDim2.new(1, 0, 0, 300)
    createSection.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    createSection.Parent = container
    
    Utilities:CreateCorner(createSection, 12)
    Utilities:CreatePadding(createSection, 20)
    
    local createTitle = UIComponents:CreateLabel(createSection, "Create Your Own Clan", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 24)
    createTitle.Font = CLIENT_CONFIG.FONTS.Display
    
    local createDesc = UIComponents:CreateLabel(createSection, "Start your own clan and invite friends to join!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 40), 16)
    createDesc.TextColor3 = Color3.fromRGB(100, 100, 100)
    createDesc.TextWrapped = true
    
    -- Clan name input
    local nameInput = UIComponents:CreateTextBox(createSection, "Enter clan name...", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 100))
    
    -- Clan tag input
    local tagInput = UIComponents:CreateTextBox(createSection, "Tag (2-5 chars)", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 150))
    
    -- Cost display
    local costLabel = UIComponents:CreateLabel(createSection, "Cost: 💰 50,000 Coins", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 200), 18)
    costLabel.TextColor3 = CLIENT_CONFIG.COLORS.Warning
    costLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Create button
    local createButton = UIComponents:CreateButton(createSection, "Create Clan", UDim2.new(0, 200, 0, 50), UDim2.new(0.5, -100, 1, -60), function()
        self:CreateClan(nameInput.Text, tagInput.Text)
    end)
    createButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    
    -- Browse clans section
    local browseSection = Instance.new("Frame")
    browseSection.Size = UDim2.new(1, 0, 1, -320)
    browseSection.Position = UDim2.new(0, 0, 0, 320)
    browseSection.BackgroundTransparency = 1
    browseSection.Parent = container
    
    local browseTitle = UIComponents:CreateLabel(browseSection, "Browse Clans", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 20)
    browseTitle.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local clanList = UIComponents:CreateScrollingFrame(browseSection, UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40))
    
    -- TODO: Load clan list
end

function UIModules.ClanUI:ShowClanInterface()
    -- Create tabs for clan interface
    local tabs = {
        {
            Name = "Overview",
            Init = function(parent)
                self:CreateClanOverview(parent)
            end
        },
        {
            Name = "Members",
            Init = function(parent)
                self:CreateMembersList(parent)
            end
        },
        {
            Name = "Treasury",
            Init = function(parent)
                self:CreateTreasury(parent)
            end
        },
        {
            Name = "Wars",
            Init = function(parent)
                self:CreateClanWars(parent)
            end
        }
    }
    
    UIComponents:CreateTab(self.Frame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
end

function UIModules.ClanUI:CreateClan(name, tag)
    if name == "" or tag == "" then
        NotificationSystem:SendNotification("Error", "Please enter a clan name and tag", "error")
        return
    end
    
    local success, result = RemoteFunctions.CreateClan:InvokeServer(name, tag)
    
    if success then
        NotificationSystem:SendNotification("Success", "Clan created successfully!", "success")
        self:ShowClanInterface()
    else
        NotificationSystem:SendNotification("Error", result or "Failed to create clan", "error")
    end
end

-- ========================================
-- SPECIAL EFFECTS MODULE
-- ========================================
local SpecialEffects = {}

function SpecialEffects:CreateRainbowText(textLabel)
    spawn(function()
        local hue = 0
        while textLabel.Parent do
            hue = (hue + 1) % 360
            textLabel.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
            Services.RunService.Heartbeat:Wait()
        end
    end)
end

function SpecialEffects:CreateGlowEffect(frame, color)
    local glow = Instance.new("ImageLabel")
    glow.Name = "GlowEffect"
    glow.Size = UDim2.new(1, 30, 1, 30)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = color or CLIENT_CONFIG.COLORS.Primary
    glow.ZIndex = frame.ZIndex - 1
    glow.Parent = frame.Parent
    
    -- Animate glow
    spawn(function()
        while glow.Parent do
            Utilities:Tween(glow, {
                Size = UDim2.new(1, 40, 1, 40),
                ImageTransparency = 0.7
            }, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(1)
            Utilities:Tween(glow, {
                Size = UDim2.new(1, 30, 1, 30),
                ImageTransparency = 0.5
            }, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(1)
        end
    end)
    
    return glow
end

function SpecialEffects:CreateShineEffect(frame)
    local shine = Instance.new("Frame")
    shine.Name = "ShineEffect"
    shine.Size = UDim2.new(0, 50, 2, 0)
    shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
    shine.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    shine.BackgroundTransparency = 0.8
    shine.Rotation = 45
    shine.ZIndex = frame.ZIndex + 1
    shine.Parent = frame
    
    local gradient = Utilities:CreateGradient(shine, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.White),
        ColorSequenceKeypoint.new(0.5, CLIENT_CONFIG.COLORS.White),
        ColorSequenceKeypoint.new(1, CLIENT_CONFIG.COLORS.White)
    })
    
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    -- Animate shine
    spawn(function()
        while shine.Parent do
            shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
            wait(3)
            Utilities:Tween(shine, {Position = UDim2.new(1.5, 0, -0.5, 0)}, TweenInfo.new(0.5, Enum.EasingStyle.Linear))
            wait(0.5)
        end
    end)
    
    return shine
end

function SpecialEffects:CreateFloatingEffect(frame, amplitude, speed)
    amplitude = amplitude or 10
    speed = speed or 2
    
    spawn(function()
        local startY = frame.Position.Y.Offset
        local time = 0
        
        while frame.Parent do
            time = time + Services.RunService.Heartbeat:Wait()
            local offset = math.sin(time * speed) * amplitude
            frame.Position = UDim2.new(
                frame.Position.X.Scale,
                frame.Position.X.Offset,
                frame.Position.Y.Scale,
                startY + offset
            )
        end
    end)
end

function SpecialEffects:CreatePulseEffect(frame, scale)
    scale = scale or 1.1
    
    spawn(function()
        while frame.Parent do
            Utilities:Tween(frame, {Size = UDim2.new(
                frame.Size.X.Scale * scale,
                frame.Size.X.Offset * scale,
                frame.Size.Y.Scale * scale,
                frame.Size.Y.Offset * scale
            )}, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(0.5)
            Utilities:Tween(frame, {Size = UDim2.new(
                frame.Size.X.Scale / scale,
                frame.Size.X.Offset / scale,
                frame.Size.Y.Scale / scale,
                frame.Size.Y.Offset / scale
            )}, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(0.5)
        end
    end)
end

-- ========================================
-- BATTLE PASS UI MODULE
-- ========================================
UIModules.BattlePassUI = {}

function UIModules.BattlePassUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main battle pass frame
    local battlePassFrame = UIComponents:CreateFrame(MainUI.MainContainer, "BattlePassFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    battlePassFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = battlePassFrame
    
    -- Header
    local header = UIComponents:CreateFrame(battlePassFrame, "Header", UDim2.new(1, 0, 0, 100), UDim2.new(0, 0, 0, 0))
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    
    Utilities:CreateGradient(header, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.Primary),
        ColorSequenceKeypoint.new(1, CLIENT_CONFIG.COLORS.Secondary)
    })
    
    local titleLabel = UIComponents:CreateLabel(header, "🌟 Battle Pass Season 1 🌟", UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 10), 28)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Season timer
    local timerLabel = UIComponents:CreateLabel(header, "28 Days Remaining", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 45), 16)
    timerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    timerLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Level progress
    local levelContainer = Instance.new("Frame")
    levelContainer.Size = UDim2.new(1, -40, 0, 30)
    levelContainer.Position = UDim2.new(0, 20, 1, -40)
    levelContainer.BackgroundTransparency = 1
    levelContainer.Parent = header
    
    local levelLabel = UIComponents:CreateLabel(levelContainer, "Level 1", UDim2.new(0, 80, 1, 0), UDim2.new(0, 0, 0, 0), 18)
    levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local xpBar = UIComponents:CreateProgressBar(levelContainer, UDim2.new(1, -200, 0, 20), UDim2.new(0, 90, 0.5, -10), 0, 1000)
    xpBar.Fill.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
    
    local levelEndLabel = UIComponents:CreateLabel(levelContainer, "Level 2", UDim2.new(0, 80, 1, 0), UDim2.new(1, -80, 0, 0), 18)
    levelEndLabel.TextXAlignment = Enum.TextXAlignment.Right
    levelEndLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelEndLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Premium upgrade button
    if not (LocalData.PlayerData and LocalData.PlayerData.battlePass.premiumOwned) then
        local upgradeButton = UIComponents:CreateButton(header, "Upgrade to Premium", UDim2.new(0, 150, 0, 35), UDim2.new(1, -160, 0, 10), function()
            self:ShowPremiumUpgrade()
        end)
        upgradeButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
        upgradeButton.ZIndex = header.ZIndex + 1
        
        SpecialEffects:CreateGlowEffect(upgradeButton, CLIENT_CONFIG.COLORS.Warning)
    end
    
    -- Rewards track
    local rewardsContainer = Instance.new("ScrollingFrame")
    rewardsContainer.Size = UDim2.new(1, -20, 1, -120)
    rewardsContainer.Position = UDim2.new(0, 10, 0, 110)
    rewardsContainer.BackgroundTransparency = 1
    rewardsContainer.ScrollBarThickness = 12
    rewardsContainer.CanvasSize = UDim2.new(5, 0, 0, 0) -- Horizontal scrolling
    rewardsContainer.ScrollingDirection = Enum.ScrollingDirection.X
    rewardsContainer.Parent = battlePassFrame
    
    -- Create reward tiers
    self:CreateRewardTrack(rewardsContainer)
end

function UIModules.BattlePassUI:CreateRewardTrack(parent)
    local tiers = 100
    local tierWidth = 150
    local tierSpacing = 10
    
    for tier = 1, tiers do
        local tierFrame = Instance.new("Frame")
        tierFrame.Size = UDim2.new(0, tierWidth, 1, -20)
        tierFrame.Position = UDim2.new(0, (tier - 1) * (tierWidth + tierSpacing) + 10, 0, 10)
        tierFrame.BackgroundTransparency = 1
        tierFrame.Parent = parent
        
        -- Tier number
        local tierLabel = UIComponents:CreateLabel(tierFrame, "Tier " .. tier, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 16)
        tierLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        
        -- Free reward
        local freeReward = self:CreateRewardCard(tierFrame, "Free", UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 0, 40), {
            type = "coins",
            amount = tier * 1000,
            claimed = false,
            locked = tier > 1
        })
        
        -- Premium reward
        local premiumReward = self:CreateRewardCard(tierFrame, "Premium", UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 0, 130), {
            type = "gems",
            amount = tier * 10,
            claimed = false,
            locked = true,
            premium = true
        })
        
        -- Connection line
        if tier < tiers then
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0, tierSpacing, 0, 2)
            line.Position = UDim2.new(1, 0, 0, 80)
            line.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
            line.BorderSizePixel = 0
            line.Parent = tierFrame
        end
    end
end

function UIModules.BattlePassUI:CreateRewardCard(parent, label, size, position, rewardData)
    local card = Instance.new("Frame")
    card.Size = size
    card.Position = position
    card.BackgroundColor3 = rewardData.locked and Color3.fromRGB(200, 200, 200) or CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 8)
    
    if rewardData.premium and rewardData.locked then
        -- Add lock overlay
        local lockOverlay = Instance.new("Frame")
        lockOverlay.Size = UDim2.new(1, 0, 1, 0)
        lockOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
        lockOverlay.BackgroundTransparency = 0.5
        lockOverlay.ZIndex = card.ZIndex + 1
        lockOverlay.Parent = card
        
        Utilities:CreateCorner(lockOverlay, 8)
        
        local lockIcon = UIComponents:CreateLabel(lockOverlay, "🔒", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
        lockIcon.ZIndex = lockOverlay.ZIndex + 1
    end
    
    -- Reward icon
    local icon = ""
    if rewardData.type == "coins" then
        icon = "💰"
    elseif rewardData.type == "gems" then
        icon = "💎"
    elseif rewardData.type == "pet" then
        icon = "🥚"
    end
    
    local iconLabel = UIComponents:CreateLabel(card, icon, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 10), 24)
    
    -- Amount
    local amountLabel = UIComponents:CreateLabel(card, Utilities:FormatNumber(rewardData.amount), UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 40), 16)
    amountLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Label
    local typeLabel = UIComponents:CreateLabel(card, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 1, -25), 12)
    typeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    if rewardData.claimed then
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
        card.BackgroundTransparency = 0.5
        
        local checkmark = UIComponents:CreateLabel(card, "✓", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 36)
        checkmark.TextColor3 = CLIENT_CONFIG.COLORS.White
        checkmark.TextTransparency = 0.7
    end
    
    return card
end

-- ========================================
-- MINIGAME UI MODULE
-- ========================================
UIModules.MinigameUI = {}

function UIModules.MinigameUI:StartMinigame(gameType)
    if gameType == "memory" then
        self:StartMemoryGame()
    elseif gameType == "catch" then
        self:StartCatchGame()
    elseif gameType == "quiz" then
        self:StartQuizGame()
    end
end

function UIModules.MinigameUI:StartMemoryGame()
    -- Create minigame overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "MinigameOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 800
    overlay.Parent = MainUI.ScreenGui
    
    -- Game container
    local gameContainer = Instance.new("Frame")
    gameContainer.Size = UDim2.new(0, 600, 0, 700)
    gameContainer.Position = UDim2.new(0.5, -300, 0.5, -350)
    gameContainer.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    gameContainer.ZIndex = 801
    gameContainer.Parent = overlay
    
    Utilities:CreateCorner(gameContainer, 20)
    Utilities:CreateShadow(gameContainer, 0.5, 30)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 802
    header.Parent = gameContainer
    
    Utilities:CreateCorner(header, 20)
    
    local titleLabel = UIComponents:CreateLabel(header, "🧠 Memory Match 🧠", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 24)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 803
    
    -- Score and timer
    local scoreLabel = UIComponents:CreateLabel(header, "Score: 0", UDim2.new(0.5, 0, 0, 25), UDim2.new(0, 20, 0, 45), 16)
    scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
    scoreLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    scoreLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    scoreLabel.ZIndex = 803
    
    local timerLabel = UIComponents:CreateLabel(header, "Time: 60s", UDim2.new(0.5, -20, 0, 25), UDim2.new(0.5, 0, 0, 45), 16)
    timerLabel.TextXAlignment = Enum.TextXAlignment.Right
    timerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    timerLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    timerLabel.ZIndex = 803
    
    -- Game grid
    local gridContainer = Instance.new("Frame")
    gridContainer.Size = UDim2.new(1, -40, 1, -140)
    gridContainer.Position = UDim2.new(0, 20, 0, 100)
    gridContainer.BackgroundTransparency = 1
    gridContainer.ZIndex = 802
    gridContainer.Parent = gameContainer
    
    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.CellSize = UDim2.new(0.25, -7.5, 0.25, -7.5)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.Parent = gridContainer
    
    -- Create cards
    local cardPairs = {"🎀", "🌸", "🍓", "🌈", "⭐", "💖", "🦄", "🎂"}
    local allCards = {}
    
    -- Double the cards for pairs
    for _, emoji in ipairs(cardPairs) do
        table.insert(allCards, emoji)
        table.insert(allCards, emoji)
    end
    
    -- Shuffle
    for i = #allCards, 2, -1 do
        local j = math.random(i)
        allCards[i], allCards[j] = allCards[j], allCards[i]
    end
    
    -- Game state
    local flippedCards = {}
    local matchedPairs = 0
    local score = 0
    local canFlip = true
    
    -- Create card UI
    for i, cardValue in ipairs(allCards) do
        local card = Instance.new("TextButton")
        card.Name = "Card" .. i
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
        card.Text = ""
        card.ZIndex = 803
        card.Parent = gridContainer
        
        Utilities:CreateCorner(card, 8)
        
        local isFlipped = false
        local isMatched = false
        
        card.MouseButton1Click:Connect(function()
            if not canFlip or isFlipped or isMatched then return end
            
            -- Flip card
            isFlipped = true
            Utilities:Tween(card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White}, TweenInfo.new(0.2))
            card.Text = cardValue
            card.TextSize = 36
            
            table.insert(flippedCards, {card = card, value = cardValue, index = i})
            
            -- Check for match
            if #flippedCards == 2 then
                canFlip = false
                
                if flippedCards[1].value == flippedCards[2].value then
                    -- Match!
                    score = score + 100
                    scoreLabel.Text = "Score: " .. score
                    matchedPairs = matchedPairs + 1
                    
                    for _, cardData in ipairs(flippedCards) do
                        cardData.card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
                    end
                    
                    flippedCards = {}
                    canFlip = true
                    
                    -- Check win
                    if matchedPairs == #cardPairs then
                        self:EndMinigame(overlay, score, true)
                    end
                else
                    -- No match
                    wait(1)
                    
                    for _, cardData in ipairs(flippedCards) do
                        Utilities:Tween(cardData.card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary}, TweenInfo.new(0.2))
                        cardData.card.Text = ""
                    end
                    
                    flippedCards = {}
                    canFlip = true
                end
            end
        end)
    end
    
    -- Timer
    local timeLeft = 60
    spawn(function()
        while timeLeft > 0 and overlay.Parent do
            wait(1)
            timeLeft = timeLeft - 1
            timerLabel.Text = "Time: " .. timeLeft .. "s"
            
            if timeLeft <= 10 then
                timerLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
            end
        end
        
        if overlay.Parent then
            self:EndMinigame(overlay, score, false)
        end
    end)
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 24
    closeButton.ZIndex = 804
    closeButton.Parent = header
    
    closeButton.MouseButton1Click:Connect(function()
        overlay:Destroy()
    end)
end

function UIModules.MinigameUI:EndMinigame(overlay, score, won)
    -- Show results
    local resultFrame = Instance.new("Frame")
    resultFrame.Size = UDim2.new(0, 400, 0, 300)
    resultFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    resultFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    resultFrame.ZIndex = 900
    resultFrame.Parent = overlay
    
    Utilities:CreateCorner(resultFrame, 20)
    Utilities:CreateShadow(resultFrame, 0.5)
    
    local resultLabel = UIComponents:CreateLabel(resultFrame, won and "You Win!" or "Time's Up!", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 30), 32)
    resultLabel.TextColor3 = won and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Error
    resultLabel.Font = CLIENT_CONFIG.FONTS.Display
    resultLabel.ZIndex = 901
    
    local scoreLabel = UIComponents:CreateLabel(resultFrame, "Final Score: " .. score, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 90), 20)
    scoreLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    scoreLabel.ZIndex = 901
    
    -- Rewards
    local rewardCoins = score * 10
    local rewardGems = math.floor(score / 100) * 5
    
    local rewardsLabel = UIComponents:CreateLabel(resultFrame, "Rewards:", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 130), 18)
    rewardsLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    rewardsLabel.ZIndex = 901
    
    local coinsLabel = UIComponents:CreateLabel(resultFrame, "💰 " .. Utilities:FormatNumber(rewardCoins) .. " Coins", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 160), 16)
    coinsLabel.TextColor3 = CLIENT_CONFIG.COLORS.Warning
    coinsLabel.ZIndex = 901
    
    local gemsLabel = UIComponents:CreateLabel(resultFrame, "💎 " .. rewardGems .. " Gems", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 185), 16)
    gemsLabel.TextColor3 = CLIENT_CONFIG.COLORS.Primary
    gemsLabel.ZIndex = 901
    
    -- Claim button
    local claimButton = UIComponents:CreateButton(resultFrame, "Claim Rewards", UDim2.new(0, 200, 0, 50), UDim2.new(0.5, -100, 1, -70), function()
        -- TODO: Send rewards to server
        overlay:Destroy()
    end)
    claimButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    claimButton.ZIndex = 902
    
    -- Effects
    if won then
        ParticleSystem:CreateBurst(resultFrame, "star", UDim2.new(0.5, 0, 0.5, 0), 30)
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
    end
end

-- ========================================
-- DEBUG PANEL (Development Only)
-- ========================================
if game:GetService("RunService"):IsStudio() then
    local DebugPanel = {}
    
    function DebugPanel:Create()
        local panel = Instance.new("Frame")
        panel.Name = "DebugPanel"
        panel.Size = UDim2.new(0, 300, 0, 400)
        panel.Position = UDim2.new(1, -310, 1, -410)
        panel.BackgroundColor3 = Color3.new(0, 0, 0)
        panel.BackgroundTransparency = 0.3
        panel.Parent = MainUI.ScreenGui
        
        Utilities:CreateCorner(panel, 8)
        
        local title = UIComponents:CreateLabel(panel, "Debug Panel", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 16)
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Font = CLIENT_CONFIG.FONTS.Secondary
        
        local content = UIComponents:CreateScrollingFrame(panel, UDim2.new(1, -10, 1, -40), UDim2.new(0, 5, 0, 35))
        
        -- Add debug buttons
        local yOffset = 5
        
        local function AddDebugButton(text, callback)
            local btn = UIComponents:CreateButton(content, text, UDim2.new(1, -10, 0, 30), UDim2.new(0, 5, 0, yOffset), callback)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.new(1, 1, 1)
            yOffset = yOffset + 35
        end
        
        AddDebugButton("Give 1M Coins", function()
            print("Debug: Adding 1M coins")
        end)
        
        AddDebugButton("Give 1K Gems", function()
            print("Debug: Adding 1K gems")
        end)
        
        AddDebugButton("Open Legendary Egg", function()
            UIModules.ShopUI:OpenEgg({id = "legendary", name = "Legendary Egg", price = 0, currency = "Gems"})
        end)
        
        AddDebugButton("Test Notification", function()
            NotificationSystem:SendNotification("Test", "This is a test notification!", "info")
        end)
        
        AddDebugButton("Test Particles", function()
            ParticleSystem:CreateBurst(MainUI.MainContainer, "star", UDim2.new(0.5, 0, 0.5, 0), 50)
        end)
        
        AddDebugButton("Show Daily Reward", function()
            UIModules.DailyRewardUI:ShowDailyRewardWindow()
        end)
        
        AddDebugButton("Start Memory Game", function()
            UIModules.MinigameUI:StartMemoryGame()
        end)
        
        AddDebugButton("Show Profile", function()
            UIModules.ProfileUI:ShowProfile(LocalPlayer)
        end)
        
        content.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
    end
    
    DebugPanel:Create()
end

-- ========================================
-- FINAL INITIALIZATION
-- ========================================
print("Sanrio Tycoon Shop Client v5.0 loaded successfully!")
print("Total UI modules loaded:", #UIModules)

-- Return for external access
return {
    MainUI = MainUI,
    UIModules = UIModules,
    NotificationSystem = NotificationSystem,
    ParticleSystem = ParticleSystem,
    SpecialEffects = SpecialEffects,
    Utilities = Utilities,
    LocalData = LocalData,
    CLIENT_CONFIG = CLIENT_CONFIG
}