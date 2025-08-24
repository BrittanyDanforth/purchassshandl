--[[
  🎀 ETHICAL BATTLE PASS SYSTEM
  
  Following the monetization guide while maintaining:
  - Clear value proposition (10x return)
  - No pay-to-win elements
  - Achievable goals for active players
  - Child-friendly progression
--]]

local BattlePass = {}

-- Configuration
local BATTLE_PASS_CONFIG = {
	-- Pricing
	PREMIUM_COST_ROBUX = 499, -- Reasonable price point
	SEASON_LENGTH_DAYS = 30, -- One month seasons
	
	-- Progression
	TOTAL_TIERS = 50,
	XP_PER_TIER = 1000,
	
	-- Rewards structure
	FREE_TRACK_REWARDS = {
		-- Basic rewards for all players
		[1] = {type = "coins", amount = 1000},
		[5] = {type = "petFood", amount = 10},
		[10] = {type = "freeGachaPull", amount = 1},
		[15] = {type = "coins", amount = 5000},
		[20] = {type = "decoration", id = "basic_fountain"},
		[25] = {type = "freeGachaPull", amount = 2},
		[30] = {type = "coins", amount = 10000},
		[35] = {type = "petFood", amount = 50},
		[40] = {type = "freeGachaPull", amount = 3},
		[45] = {type = "coins", amount = 25000},
		[50] = {type = "specialCurrency", amount = 50} -- Small gem reward
	},
	
	PREMIUM_TRACK_REWARDS = {
		-- High-value rewards for premium pass holders
		[1] = {type = "gems", amount = 100},
		[5] = {type = "exclusivePet", id = "battlepass_hello_kitty", rarity = "rare"},
		[10] = {type = "gems", amount = 150},
		[15] = {type = "exclusiveDecoration", id = "premium_sakura_tree"},
		[20] = {type = "gems", amount = 200},
		[25] = {type = "exclusivePet", id = "battlepass_cinnamoroll", rarity = "epic"},
		[30] = {type = "gems", amount = 250},
		[35] = {type = "exclusiveAvatar", id = "sanrio_outfit_set"},
		[40] = {type = "gems", amount = 300},
		[45] = {type = "exclusiveEffect", id = "rainbow_trail"},
		[50] = {type = "exclusivePet", id = "battlepass_kuromi", rarity = "legendary"}
	}
}

-- Calculate total gem value in premium track
local function calculatePremiumValue()
	local totalGems = 0
	for tier, reward in pairs(BATTLE_PASS_CONFIG.PREMIUM_TRACK_REWARDS) do
		if reward.type == "gems" then
			totalGems = totalGems + reward.amount
		end
	end
	return totalGems -- Should be enough to buy next pass + extra
end

-- Create Battle Pass UI
function BattlePass:CreateUI(parent, player)
	local frame = Instance.new("Frame")
	frame.Name = "BattlePassUI"
	frame.Size = UDim2.fromScale(0.9, 0.8)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
	frame.Parent = parent
	
	-- Header with season info
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 100)
	header.BackgroundColor3 = Color3.fromRGB(255, 179, 212)
	header.Parent = frame
	
	local seasonTitle = Instance.new("TextLabel")
	seasonTitle.Text = "🌸 Sakura Season Battle Pass 🌸"
	seasonTitle.Size = UDim2.fromScale(0.7, 0.5)
	seasonTitle.TextScaled = true
	seasonTitle.Font = Enum.Font.Cartoon
	seasonTitle.Parent = header
	
	-- Time remaining
	local timeLeft = Instance.new("TextLabel")
	timeLeft.Text = "28 days remaining"
	timeLeft.Size = UDim2.fromScale(0.7, 0.5)
	timeLeft.Position = UDim2.fromScale(0, 0.5)
	timeLeft.TextScaled = true
	timeLeft.Font = Enum.Font.SourceSans
	timeLeft.Parent = header
	
	-- Progress bar
	local progressBar = self:CreateProgressBar(frame, player)
	
	-- Reward tracks
	local rewardScroll = Instance.new("ScrollingFrame")
	rewardScroll.Size = UDim2.new(1, -20, 1, -200)
	rewardScroll.Position = UDim2.new(0, 10, 0, 150)
	rewardScroll.CanvasSize = UDim2.new(BATTLE_PASS_CONFIG.TOTAL_TIERS * 0.15, 0, 0, 200)
	rewardScroll.ScrollingDirection = Enum.ScrollingDirection.X
	rewardScroll.Parent = frame
	
	-- Create tier display
	for tier = 1, BATTLE_PASS_CONFIG.TOTAL_TIERS do
		local tierFrame = self:CreateTierDisplay(tier, player)
		tierFrame.Position = UDim2.new((tier-1) * 0.15, 10, 0, 0)
		tierFrame.Parent = rewardScroll
	end
	
	-- Purchase button (if not owned)
	if not self:PlayerOwnsPremium(player) then
		local purchaseBtn = Instance.new("TextButton")
		purchaseBtn.Text = "🌟 Unlock Premium - " .. BATTLE_PASS_CONFIG.PREMIUM_COST_ROBUX .. " Robux 🌟"
		purchaseBtn.Size = UDim2.fromOffset(400, 60)
		purchaseBtn.Position = UDim2.new(1, -420, 0, 20)
		purchaseBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		purchaseBtn.Font = Enum.Font.SourceSansBold
		purchaseBtn.TextScaled = true
		purchaseBtn.Parent = header
		
		-- Show value proposition
		local valueText = Instance.new("TextLabel")
		valueText.Text = "Get " .. calculatePremiumValue() .. "+ Gems worth of rewards!"
		valueText.Size = UDim2.fromOffset(400, 20)
		valueText.Position = UDim2.new(1, -420, 0, 85)
		valueText.TextScaled = true
		valueText.Font = Enum.Font.SourceSans
		valueText.TextColor3 = Color3.fromRGB(0, 200, 0)
		valueText.Parent = header
		
		purchaseBtn.MouseButton1Click:Connect(function()
			self:PromptPremiumPurchase(player)
		end)
	end
	
	return frame
end

-- Create individual tier display
function BattlePass:CreateTierDisplay(tier, player)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(140, 200)
	frame.BackgroundColor3 = Color3.new(0.95, 0.95, 0.95)
	
	-- Tier number
	local tierLabel = Instance.new("TextLabel")
	tierLabel.Text = "Tier " .. tier
	tierLabel.Size = UDim2.new(1, 0, 0, 30)
	tierLabel.TextScaled = true
	tierLabel.Font = Enum.Font.SourceSansBold
	tierLabel.Parent = frame
	
	local currentTier = self:GetPlayerTier(player)
	local hasPremium = self:PlayerOwnsPremium(player)
	
	-- Free track reward
	local freeReward = BATTLE_PASS_CONFIG.FREE_TRACK_REWARDS[tier]
	if freeReward then
		local freeFrame = self:CreateRewardDisplay(freeReward, false)
		freeFrame.Position = UDim2.new(0, 5, 0, 35)
		freeFrame.Parent = frame
		
		-- Show if claimed
		if tier <= currentTier then
			local claimed = Instance.new("TextLabel")
			claimed.Text = "✓"
			claimed.Size = UDim2.fromScale(1, 1)
			claimed.TextScaled = true
			claimed.TextColor3 = Color3.fromRGB(0, 200, 0)
			claimed.BackgroundTransparency = 1
			claimed.Font = Enum.Font.SourceSansBold
			claimed.Parent = freeFrame
		end
	end
	
	-- Premium track reward
	local premiumReward = BATTLE_PASS_CONFIG.PREMIUM_TRACK_REWARDS[tier]
	if premiumReward then
		local premiumFrame = self:CreateRewardDisplay(premiumReward, true)
		premiumFrame.Position = UDim2.new(0, 5, 0, 115)
		premiumFrame.Parent = frame
		
		if not hasPremium then
			-- Show locked state
			premiumFrame.BackgroundTransparency = 0.5
			
			local lock = Instance.new("ImageLabel")
			lock.Image = "rbxassetid://10734933222" -- Lock icon
			lock.Size = UDim2.fromOffset(30, 30)
			lock.Position = UDim2.fromScale(0.5, 0.5)
			lock.AnchorPoint = Vector2.new(0.5, 0.5)
			lock.BackgroundTransparency = 1
			lock.Parent = premiumFrame
		elseif tier <= currentTier then
			-- Show claimed
			local claimed = Instance.new("TextLabel")
			claimed.Text = "✓"
			claimed.Size = UDim2.fromScale(1, 1)
			claimed.TextScaled = true
			claimed.TextColor3 = Color3.fromRGB(255, 215, 0)
			claimed.BackgroundTransparency = 1
			claimed.Font = Enum.Font.SourceSansBold
			claimed.Parent = premiumFrame
		end
	end
	
	-- Highlight current tier
	if tier == currentTier + 1 then
		frame.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
		local glow = Instance.new("UIStroke")
		glow.Color = Color3.fromRGB(255, 215, 0)
		glow.Thickness = 3
		glow.Parent = frame
	end
	
	return frame
end

-- Create reward display
function BattlePass:CreateRewardDisplay(reward, isPremium)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(130, 75)
	frame.BackgroundColor3 = isPremium and Color3.fromRGB(255, 240, 200) or Color3.fromRGB(230, 230, 230)
	
	-- Reward icon
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(50, 50)
	icon.Position = UDim2.new(0, 5, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	
	-- Set icon based on reward type
	if reward.type == "gems" then
		icon.Image = "rbxassetid://10709727148" -- Gem icon
	elseif reward.type == "coins" then
		icon.Image = "rbxassetid://10709728059" -- Coin icon
	elseif reward.type == "exclusivePet" then
		icon.Image = "rbxassetid://17398522865" -- Pet icon
	elseif reward.type == "freeGachaPull" then
		icon.Image = "rbxassetid://10734973280" -- Ticket icon
	end
	
	icon.Parent = frame
	
	-- Reward text
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(0.5, -5, 1, 0)
	text.Position = UDim2.new(0.5, 0, 0, 0)
	text.Text = tostring(reward.amount or reward.id)
	text.TextScaled = true
	text.Font = Enum.Font.SourceSans
	text.Parent = frame
	
	return frame
end

-- Daily/Weekly quest system
function BattlePass:CreateQuestSystem()
	local quests = {
		daily = {
			{id = "play_10min", description = "Play for 10 minutes", xp = 100, progress = 0, max = 600},
			{id = "collect_1000_coins", description = "Collect 1,000 coins", xp = 150, progress = 0, max = 1000},
			{id = "feed_pet", description = "Feed any pet", xp = 100, progress = 0, max = 1},
			{id = "upgrade_building", description = "Upgrade any building", xp = 200, progress = 0, max = 1},
		},
		weekly = {
			{id = "play_2hours", description = "Play for 2 hours total", xp = 500, progress = 0, max = 7200},
			{id = "collect_50k_coins", description = "Collect 50,000 coins", xp = 750, progress = 0, max = 50000},
			{id = "complete_event", description = "Complete an event", xp = 1000, progress = 0, max = 1},
			{id = "reach_level_10", description = "Reach tycoon level 10", xp = 1500, progress = 0, max = 10},
		}
	}
	
	return quests
end

-- Quest UI
function BattlePass:CreateQuestUI(parent, player)
	local frame = Instance.new("Frame")
	frame.Name = "QuestLog"
	frame.Size = UDim2.fromOffset(400, 600)
	frame.Position = UDim2.new(0, 20, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Parent = parent
	
	local title = Instance.new("TextLabel")
	title.Text = "Battle Pass Quests"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = frame
	
	local quests = self:CreateQuestSystem()
	
	-- Daily quests
	local dailyLabel = Instance.new("TextLabel")
	dailyLabel.Text = "Daily Quests (Reset in 18h)"
	dailyLabel.Size = UDim2.new(1, 0, 0, 30)
	dailyLabel.Position = UDim2.new(0, 0, 0, 60)
	dailyLabel.TextScaled = true
	dailyLabel.Font = Enum.Font.SourceSans
	dailyLabel.Parent = frame
	
	local yOffset = 100
	for _, quest in ipairs(quests.daily) do
		local questFrame = self:CreateQuestDisplay(quest)
		questFrame.Position = UDim2.new(0, 10, 0, yOffset)
		questFrame.Parent = frame
		yOffset = yOffset + 70
	end
	
	-- Weekly quests
	local weeklyLabel = Instance.new("TextLabel")
	weeklyLabel.Text = "Weekly Quests (Reset in 5d)"
	weeklyLabel.Size = UDim2.new(1, 0, 0, 30)
	weeklyLabel.Position = UDim2.new(0, 0, 0, yOffset + 20)
	weeklyLabel.TextScaled = true
	weeklyLabel.Font = Enum.Font.SourceSans
	weeklyLabel.Parent = frame
	
	yOffset = yOffset + 60
	for _, quest in ipairs(quests.weekly) do
		local questFrame = self:CreateQuestDisplay(quest)
		questFrame.Position = UDim2.new(0, 10, 0, yOffset)
		questFrame.Parent = frame
		yOffset = yOffset + 70
	end
	
	return frame
end

-- Individual quest display
function BattlePass:CreateQuestDisplay(quest)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -20, 0, 60)
	frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	
	-- Quest description
	local desc = Instance.new("TextLabel")
	desc.Text = quest.description
	desc.Size = UDim2.new(0.6, 0, 0.5, 0)
	desc.Position = UDim2.new(0, 10, 0, 0)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextScaled = true
	desc.Font = Enum.Font.SourceSans
	desc.Parent = frame
	
	-- XP reward
	local xpLabel = Instance.new("TextLabel")
	xpLabel.Text = "+" .. quest.xp .. " XP"
	xpLabel.Size = UDim2.new(0.4, -10, 0.5, 0)
	xpLabel.Position = UDim2.new(0.6, 0, 0, 0)
	xpLabel.TextXAlignment = Enum.TextXAlignment.Right
	xpLabel.TextScaled = true
	xpLabel.Font = Enum.Font.SourceSansBold
	xpLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	xpLabel.Parent = frame
	
	-- Progress bar
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(1, -20, 0, 20)
	progressBar.Position = UDim2.new(0, 10, 0.5, 5)
	progressBar.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
	progressBar.Parent = frame
	
	local progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.fromScale(quest.progress / quest.max, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	progressFill.Parent = progressBar
	
	-- Progress text
	local progressText = Instance.new("TextLabel")
	progressText.Text = quest.progress .. " / " .. quest.max
	progressText.Size = UDim2.fromScale(1, 1)
	progressText.TextScaled = true
	progressText.Font = Enum.Font.SourceSans
	progressText.BackgroundTransparency = 1
	progressText.Parent = progressBar
	
	-- Complete state
	if quest.progress >= quest.max then
		frame.BackgroundColor3 = Color3.fromRGB(200, 255, 200)
		local check = Instance.new("TextLabel")
		check.Text = "✓"
		check.Size = UDim2.fromOffset(30, 30)
		check.Position = UDim2.new(1, -40, 0.5, 0)
		check.AnchorPoint = Vector2.new(0.5, 0.5)
		check.TextScaled = true
		check.TextColor3 = Color3.fromRGB(0, 200, 0)
		check.Font = Enum.Font.SourceSansBold
		check.Parent = frame
	end
	
	return frame
end

-- Tier skip option (ethical implementation)
function BattlePass:ShowTierSkipOption(player)
	local currentTier = self:GetPlayerTier(player)
	local remainingTiers = BATTLE_PASS_CONFIG.TOTAL_TIERS - currentTier
	
	if remainingTiers <= 0 then return end
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(400, 300)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "Skip Tiers?"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = frame
	
	-- Explanation
	local explanation = Instance.new("TextLabel")
	explanation.Text = "You can skip tiers if you don't have time to complete all quests.\nEach tier costs 50 Gems."
	explanation.Size = UDim2.new(1, -20, 0, 80)
	explanation.Position = UDim2.new(0, 10, 0, 60)
	explanation.TextWrapped = true
	explanation.TextScaled = true
	explanation.Font = Enum.Font.SourceSans
	explanation.Parent = frame
	
	-- Tier selector
	local selector = Instance.new("TextBox")
	selector.Text = "1"
	selector.Size = UDim2.fromOffset(100, 40)
	selector.Position = UDim2.new(0.5, 0, 0, 160)
	selector.AnchorPoint = Vector2.new(0.5, 0)
	selector.TextScaled = true
	selector.Font = Enum.Font.SourceSans
	selector.Parent = frame
	
	-- Cost display
	local costLabel = Instance.new("TextLabel")
	costLabel.Text = "Cost: 50 Gems"
	costLabel.Size = UDim2.new(1, 0, 0, 30)
	costLabel.Position = UDim2.new(0, 0, 0, 210)
	costLabel.TextScaled = true
	costLabel.Font = Enum.Font.SourceSansBold
	costLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
	costLabel.Parent = frame
	
	-- Update cost on text change
	selector:GetPropertyChangedSignal("Text"):Connect(function()
		local tiers = tonumber(selector.Text) or 1
		tiers = math.clamp(tiers, 1, remainingTiers)
		costLabel.Text = "Cost: " .. (tiers * 50) .. " Gems"
	end)
	
	-- Purchase button
	local purchaseBtn = Instance.new("TextButton")
	purchaseBtn.Text = "Skip Tiers"
	purchaseBtn.Size = UDim2.fromOffset(150, 40)
	purchaseBtn.Position = UDim2.new(0.25, 0, 1, -50)
	purchaseBtn.AnchorPoint = Vector2.new(0.5, 0)
	purchaseBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	purchaseBtn.Font = Enum.Font.SourceSansBold
	purchaseBtn.TextScaled = true
	purchaseBtn.Parent = frame
	
	-- Cancel button
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Text = "Cancel"
	cancelBtn.Size = UDim2.fromOffset(150, 40)
	cancelBtn.Position = UDim2.new(0.75, 0, 1, -50)
	cancelBtn.AnchorPoint = Vector2.new(0.5, 0)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	cancelBtn.Font = Enum.Font.SourceSansBold
	cancelBtn.TextScaled = true
	cancelBtn.Parent = frame
	
	purchaseBtn.MouseButton1Click:Connect(function()
		local tiers = tonumber(selector.Text) or 1
		self:PurchaseTierSkips(player, tiers)
		frame:Destroy()
	end)
	
	cancelBtn.MouseButton1Click:Connect(function()
		frame:Destroy()
	end)
	
	return frame
end

return BattlePass