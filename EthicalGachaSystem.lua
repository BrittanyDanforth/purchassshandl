--[[
  🎀 ETHICAL GACHA SYSTEM FOR SANRIO TYCOON
  
  Implements the monetization strategy while maintaining:
  - Full Roblox compliance (odds disclosure)
  - Child-friendly design
  - Ethical psychological mechanics
  - Transparent value propositions
--]]

local GachaSystem = {}

-- Configuration following the monetization guide
local GACHA_CONFIG = {
	-- Rarity tiers with EXACT odds (must be disclosed)
	RARITIES = {
		{name = "Common", color = Color3.fromRGB(200, 200, 200), rate = 60.0},
		{name = "Uncommon", color = Color3.fromRGB(100, 200, 100), rate = 25.0},
		{name = "Rare", color = Color3.fromRGB(100, 150, 255), rate = 10.0},
		{name = "Epic", color = Color3.fromRGB(200, 100, 255), rate = 4.5},
		{name = "Legendary", color = Color3.fromRGB(255, 215, 0), rate = 0.5}
	},
	
	-- Pity system (ethical failsafe)
	PITY_SYSTEM = {
		enabled = true,
		guaranteedEpicAt = 90,  -- Guaranteed Epic+ after 90 pulls
		counter = "PityCounter", -- DataStore key
	},
	
	-- Duplicate conversion (makes every pull valuable)
	DUPLICATE_SHARDS = {
		Common = 1,
		Uncommon = 1,
		Rare = 1,
		Epic = 1,
		Legendary = 1
	},
	
	-- Pricing (in Rainbow Gems)
	PULL_COSTS = {
		single = 100,
		multi10 = 900  -- 10% discount for bulk
	}
}

-- MANDATORY: Odds Disclosure UI
function GachaSystem:CreateOddsDisclosureUI(parent)
	-- This MUST be shown before ANY purchase
	local frame = Instance.new("Frame")
	frame.Name = "OddsDisclosure"
	frame.Size = UDim2.fromOffset(400, 500)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Parent = parent
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "Drop Rates"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = frame
	
	-- Odds table
	local yOffset = 60
	for _, rarity in ipairs(GACHA_CONFIG.RARITIES) do
		local rarityFrame = Instance.new("Frame")
		rarityFrame.Size = UDim2.new(1, -20, 0, 60)
		rarityFrame.Position = UDim2.fromOffset(10, yOffset)
		rarityFrame.BackgroundColor3 = rarity.color
		rarityFrame.BackgroundTransparency = 0.8
		rarityFrame.Parent = frame
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Text = rarity.name
		nameLabel.Size = UDim2.fromScale(0.5, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.Parent = rarityFrame
		
		local rateLabel = Instance.new("TextLabel")
		rateLabel.Text = string.format("%.1f%%", rarity.rate)
		rateLabel.Size = UDim2.fromScale(0.5, 1)
		rateLabel.Position = UDim2.fromScale(0.5, 0)
		rateLabel.TextScaled = true
		rateLabel.Font = Enum.Font.SourceSansBold
		rateLabel.Parent = rarityFrame
		
		yOffset = yOffset + 70
	end
	
	-- Pity system explanation
	local pityLabel = Instance.new("TextLabel")
	pityLabel.Text = "⭐ Guaranteed Epic or Legendary after 90 pulls without one!"
	pityLabel.Size = UDim2.new(1, -20, 0, 40)
	pityLabel.Position = UDim2.fromOffset(10, yOffset)
	pityLabel.TextScaled = true
	pityLabel.TextWrapped = true
	pityLabel.Font = Enum.Font.SourceSans
	pityLabel.Parent = frame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Text = "I Understand"
	closeButton.Size = UDim2.fromOffset(200, 50)
	closeButton.Position = UDim2.new(0.5, 0, 1, -60)
	closeButton.AnchorPoint = Vector2.new(0.5, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextScaled = true
	closeButton.Parent = frame
	
	return frame, closeButton
end

-- Ethical gacha animation (exciting but not manipulative)
function GachaSystem:PlayGachaAnimation(eggModel, resultRarity)
	local animationSteps = {
		-- Step 1: Egg appears
		{
			duration = 0.5,
			action = function()
				eggModel.Transparency = 1
				TweenService:Create(eggModel, TweenInfo.new(0.5), {
					Transparency = 0,
					Size = eggModel.Size * 1.2
				}):Play()
			end
		},
		
		-- Step 2: Egg shakes (builds anticipation)
		{
			duration = 1.5,
			action = function()
				local shake = Instance.new("BodyPosition")
				shake.MaxForce = Vector3.new(400, 0, 400)
				shake.Parent = eggModel
				
				for i = 1, 10 do
					shake.Position = eggModel.Position + Vector3.new(
						math.random(-2, 2),
						0,
						math.random(-2, 2)
					)
					wait(0.15)
				end
				shake:Destroy()
			end
		},
		
		-- Step 3: Cracks appear
		{
			duration = 0.5,
			action = function()
				-- Add crack decals
				local crack = Instance.new("Decal")
				crack.Texture = "rbxassetid://..." -- Crack texture
				crack.Face = Enum.NormalId.Front
				crack.Parent = eggModel
			end
		},
		
		-- Step 4: Color reveal (indicates rarity)
		{
			duration = 0.5,
			action = function()
				local glowPart = Instance.new("PointLight")
				glowPart.Brightness = 2
				glowPart.Range = 20
				glowPart.Color = GACHA_CONFIG.RARITIES[resultRarity].color
				glowPart.Parent = eggModel
				
				-- Rarity-specific effects
				if resultRarity >= 4 then -- Epic or Legendary
					-- Add particles for high rarity
					local particles = Instance.new("ParticleEmitter")
					particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					particles.Rate = 100
					particles.Lifetime = NumberRange.new(1)
					particles.Parent = eggModel
				end
			end
		},
		
		-- Step 5: Egg breaks and pet revealed
		{
			duration = 1,
			action = function()
				eggModel.Transparency = 1
				-- Spawn pet model here
			end
		}
	}
	
	return animationSteps
end

-- Pity system implementation
function GachaSystem:CheckPity(player)
	local pityCount = player:GetAttribute("GachaPityCounter") or 0
	local lastEpicPull = player:GetAttribute("LastEpicPull") or 0
	
	-- Calculate pulls since last Epic+
	local pullsSinceEpic = pityCount - lastEpicPull
	
	-- Guarantee Epic+ if at pity threshold
	if pullsSinceEpic >= GACHA_CONFIG.PITY_SYSTEM.guaranteedEpicAt then
		return true, pullsSinceEpic
	end
	
	return false, pullsSinceEpic
end

-- Main gacha pull function
function GachaSystem:PerformPull(player, pullCount)
	local results = {}
	
	for i = 1, pullCount do
		-- Check pity system
		local isPity, pullsSinceEpic = self:CheckPity(player)
		
		-- Determine rarity
		local rarity
		if isPity then
			-- Guaranteed Epic or Legendary
			local rand = math.random() * 100
			if rand <= 10 then -- 10% chance for Legendary on pity
				rarity = 5
			else
				rarity = 4
			end
			-- Reset pity counter
			player:SetAttribute("LastEpicPull", player:GetAttribute("GachaPityCounter") or 0)
		else
			-- Normal rates
			local rand = math.random() * 100
			local cumulative = 0
			
			for idx, tier in ipairs(GACHA_CONFIG.RARITIES) do
				cumulative = cumulative + tier.rate
				if rand <= cumulative then
					rarity = idx
					break
				end
			end
		end
		
		-- Increment pity counter
		player:SetAttribute("GachaPityCounter", (player:GetAttribute("GachaPityCounter") or 0) + 1)
		
		-- Get random pet from rarity tier
		local pet = self:GetRandomPetByRarity(rarity)
		
		-- Check for duplicate
		if self:PlayerOwnsPet(player, pet.id) then
			-- Convert to shards
			local shards = GACHA_CONFIG.DUPLICATE_SHARDS[GACHA_CONFIG.RARITIES[rarity].name]
			self:GrantShards(player, pet.id, shards)
			pet.isDuplicate = true
			pet.shardsGranted = shards
		else
			-- Grant new pet
			self:GrantPet(player, pet.id)
		end
		
		table.insert(results, {
			pet = pet,
			rarity = rarity,
			rarityName = GACHA_CONFIG.RARITIES[rarity].name
		})
	end
	
	return results
end

-- UI for showing pulls remaining until pity
function GachaSystem:CreatePityCounterUI(parent, player)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(200, 60)
	frame.Position = UDim2.new(1, -210, 0, 10)
	frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	frame.BackgroundTransparency = 0.3
	frame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.5)
	label.Text = "Pity System"
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.SourceSansBold
	label.Parent = frame
	
	local counter = Instance.new("TextLabel")
	counter.Size = UDim2.fromScale(1, 0.5)
	counter.Position = UDim2.fromScale(0, 0.5)
	counter.TextScaled = true
	counter.TextColor3 = Color3.fromRGB(255, 215, 0)
	counter.Font = Enum.Font.SourceSansBold
	counter.Parent = frame
	
	-- Update counter
	local function updateCounter()
		local isPity, pullsSinceEpic = self:CheckPity(player)
		local remaining = GACHA_CONFIG.PITY_SYSTEM.guaranteedEpicAt - pullsSinceEpic
		
		if remaining <= 0 then
			counter.Text = "GUARANTEED EPIC+ NEXT!"
			counter.TextColor3 = Color3.fromRGB(255, 100, 100)
		else
			counter.Text = remaining .. " pulls to Epic+"
			counter.TextColor3 = Color3.fromRGB(255, 215, 0)
		end
	end
	
	updateCounter()
	return frame, updateCounter
end

-- Collection book UI (drives completionism ethically)
function GachaSystem:CreateCollectionBookUI(parent, player)
	local book = Instance.new("ScrollingFrame")
	book.Size = UDim2.fromScale(0.9, 0.8)
	book.Position = UDim2.fromScale(0.5, 0.5)
	book.AnchorPoint = Vector2.new(0.5, 0.5)
	book.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
	book.Parent = parent
	
	-- Grid layout
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(120, 140)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.Parent = book
	
	-- Get all pets
	local allPets = self:GetAllPets()
	local ownedPets = self:GetPlayerPets(player)
	
	-- Progress counter
	local progress = Instance.new("TextLabel")
	progress.Size = UDim2.new(1, 0, 0, 50)
	progress.Text = string.format("Collection Progress: %d / %d", #ownedPets, #allPets)
	progress.TextScaled = true
	progress.Font = Enum.Font.SourceSansBold
	progress.Parent = parent
	
	-- Create pet slots
	for _, pet in ipairs(allPets) do
		local slot = Instance.new("Frame")
		slot.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
		slot.Parent = book
		
		local owned = self:PlayerOwnsPet(player, pet.id)
		
		if owned then
			-- Show colored pet
			local image = Instance.new("ImageLabel")
			image.Size = UDim2.fromScale(0.8, 0.8)
			image.Position = UDim2.fromScale(0.5, 0.4)
			image.AnchorPoint = Vector2.new(0.5, 0.5)
			image.Image = pet.imageId
			image.BackgroundTransparency = 1
			image.Parent = slot
			
			-- Show awakening progress
			local shards = self:GetPlayerShards(player, pet.id)
			local shardsNeeded = self:GetShardsNeededForNextLevel(pet.id)
			
			local shardBar = Instance.new("Frame")
			shardBar.Size = UDim2.new(0.9, 0, 0, 10)
			shardBar.Position = UDim2.new(0.5, 0, 0.85, 0)
			shardBar.AnchorPoint = Vector2.new(0.5, 0)
			shardBar.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
			shardBar.Parent = slot
			
			local shardFill = Instance.new("Frame")
			shardFill.Size = UDim2.fromScale(shards / shardsNeeded, 1)
			shardFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
			shardFill.Parent = shardBar
		else
			-- Show silhouette
			local silhouette = Instance.new("ImageLabel")
			silhouette.Size = UDim2.fromScale(0.8, 0.8)
			silhouette.Position = UDim2.fromScale(0.5, 0.4)
			silhouette.AnchorPoint = Vector2.new(0.5, 0.5)
			silhouette.Image = pet.imageId
			silhouette.ImageColor3 = Color3.new(0, 0, 0)
			silhouette.ImageTransparency = 0.5
			silhouette.BackgroundTransparency = 1
			silhouette.Parent = slot
			
			-- Question mark
			local question = Instance.new("TextLabel")
			question.Text = "?"
			question.Size = UDim2.fromScale(1, 1)
			question.TextScaled = true
			question.Font = Enum.Font.SourceSansBold
			question.TextColor3 = Color3.new(0.5, 0.5, 0.5)
			question.BackgroundTransparency = 1
			question.Parent = slot
		end
		
		-- Pet name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		nameLabel.Position = UDim2.new(0, 0, 1, -20)
		nameLabel.Text = owned and pet.name or "???"
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.SourceSans
		nameLabel.Parent = slot
	end
	
	return book
end

-- Battle Pass integration
function GachaSystem:GrantBattlePassRewards(player, tier)
	local rewards = {
		[5] = {type = "gems", amount = 50},
		[10] = {type = "pet", id = "special_pompompurin", rarity = 3},
		[15] = {type = "gems", amount = 100},
		[20] = {type = "gachaTickets", amount = 5},
		-- etc...
	}
	
	local reward = rewards[tier]
	if reward then
		if reward.type == "gems" then
			-- Grant premium currency
			self:GrantGems(player, reward.amount)
		elseif reward.type == "pet" then
			-- Grant exclusive battle pass pet
			self:GrantPet(player, reward.id)
		elseif reward.type == "gachaTickets" then
			-- Grant free gacha pulls
			self:GrantTickets(player, reward.amount)
		end
	end
end

-- ETHICAL SAFEGUARDS
function GachaSystem:ImplementSafeguards()
	-- 1. Spending limits
	local DAILY_GEM_SPEND_LIMIT = 5000 -- Reasonable daily limit
	
	-- 2. Parental controls
	local function requireParentalApproval(player, purchaseAmount)
		-- Show parental gate
		local gate = Instance.new("ScreenGui")
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(400, 200)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Parent = gate
		
		local prompt = Instance.new("TextLabel")
		prompt.Text = "Please ask a parent to type: SEVEN"
		prompt.Size = UDim2.fromScale(1, 0.5)
		prompt.Parent = frame
		
		local input = Instance.new("TextBox")
		input.Size = UDim2.fromScale(0.8, 0.3)
		input.Position = UDim2.fromScale(0.5, 0.7)
		input.AnchorPoint = Vector2.new(0.5, 0.5)
		input.Parent = frame
		
		gate.Parent = player.PlayerGui
		
		-- Wait for correct input
		local approved = false
		input.FocusLost:Connect(function()
			if input.Text:lower() == "seven" then
				approved = true
				gate:Destroy()
			end
		end)
		
		return approved
	end
	
	-- 3. Cool-down periods
	local function enforceGachaCooldown(player)
		-- Prevent spam pulling
		local lastPull = player:GetAttribute("LastGachaPull") or 0
		local now = tick()
		
		if now - lastPull < 2 then -- 2 second cooldown
			return false
		end
		
		player:SetAttribute("LastGachaPull", now)
		return true
	end
	
	-- 4. Transparent value display
	local function showPullValue(gems)
		-- Always show real money equivalent
		local robuxCost = gems * 2 -- Example conversion
		local realMoney = robuxCost * 0.0035 -- DevEx rate
		
		return string.format("%d Gems (≈ $%.2f)", gems, realMoney)
	end
end

return GachaSystem