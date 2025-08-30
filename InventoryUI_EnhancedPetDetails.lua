-- Enhanced ShowPetStats function with all stat types
function UIModules.InventoryUI:ShowPetStats(parent, petInstance, petData)
	-- Validate data
	if not petInstance or not petData then
		local errorLabel = UIComponents:CreateLabel(parent, "Pet data unavailable", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 20)
		errorLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
		return
	end

	-- Create scrolling frame for stats
	local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))

	local statsContainer = Instance.new("Frame")
	statsContainer.Size = UDim2.new(1, -10, 0, 500)
	statsContainer.BackgroundTransparency = 1
	statsContainer.Parent = scrollFrame

	local yOffset = 0

	-- Level and XP Section
	local levelFrame = Instance.new("Frame")
	levelFrame.Size = UDim2.new(1, 0, 0, 60)
	levelFrame.Position = UDim2.new(0, 0, 0, yOffset)
	levelFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
	levelFrame.Parent = statsContainer

	Utilities:CreateCorner(levelFrame, 8)
	Utilities:CreatePadding(levelFrame, 10)

	local levelLabel = UIComponents:CreateLabel(levelFrame, "Level " .. (petInstance.level or 1), UDim2.new(0.5, 0, 0, 20), UDim2.new(0, 0, 0, 0), 16)
	levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Calculate XP requirement
	local currentLevel = petInstance.level or 1
	local xpRequired = 100 * (currentLevel * currentLevel) -- Example formula
	if petData.xpRequirements and petData.xpRequirements[currentLevel] then
		xpRequired = petData.xpRequirements[currentLevel]
	end

	local xpBar = UIComponents:CreateProgressBar(levelFrame, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 30), 
		petInstance.experience or 0, xpRequired)

	local xpText = UIComponents:CreateLabel(levelFrame, string.format("%s / %s XP", 
		Utilities:FormatNumber(petInstance.experience or 0), 
		Utilities:FormatNumber(xpRequired)), 
		UDim2.new(0, 150, 0, 20), UDim2.new(1, -150, 0, 30), 12)
	xpText.TextXAlignment = Enum.TextXAlignment.Right
	xpText.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary

	yOffset = yOffset + 70

	-- Main Stats Section
	local stats = {}
	
	-- Ensure stats table exists
	petInstance.stats = petInstance.stats or {}
	
	-- Calculate actual stats with level multipliers
	local levelMultiplier = 1 + ((petInstance.level or 1) - 1) * 0.1 -- 10% per level
	
	-- Get base stats from pet data or use defaults
	local baseStats = petData.baseStats or {}
	
	-- Power calculation
	local basePower = baseStats.power or 100
	local actualPower = petInstance.stats.power or math.floor(basePower * levelMultiplier)
	
	-- Other stats
	stats = {
		{name = "Power", icon = "⚔️", value = actualPower, color = Color3.fromRGB(255, 100, 100)},
		{name = "Health", icon = "❤️", value = petInstance.stats.health or math.floor((baseStats.health or 500) * levelMultiplier), color = Color3.fromRGB(255, 50, 50)},
		{name = "Defense", icon = "🛡️", value = petInstance.stats.defense or math.floor((baseStats.defense or 50) * levelMultiplier), color = Color3.fromRGB(100, 150, 255)},
		{name = "Speed", icon = "💨", value = petInstance.stats.speed or math.floor((baseStats.speed or 100) * levelMultiplier), color = Color3.fromRGB(100, 255, 255)},
		{name = "Luck", icon = "🍀", value = petInstance.stats.luck or math.floor((baseStats.luck or 10) * levelMultiplier), color = Color3.fromRGB(100, 255, 100)},
		{name = "Coins", icon = "💰", value = petInstance.stats.coins or petInstance.stats.coinMultiplier or baseStats.coinMultiplier or 100, suffix = "%", color = Color3.fromRGB(255, 215, 0)},
		{name = "Gems", icon = "💎", value = petInstance.stats.gems or petInstance.stats.gemMultiplier or baseStats.gemMultiplier or 0, suffix = "%", color = Color3.fromRGB(150, 100, 255)}
	}

	-- Create stat frames
	for _, stat in ipairs(stats) do
		local statFrame = Instance.new("Frame")
		statFrame.Size = UDim2.new(1, 0, 0, 45)
		statFrame.Position = UDim2.new(0, 0, 0, yOffset)
		statFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
		statFrame.Parent = statsContainer

		Utilities:CreateCorner(statFrame, 8)
		Utilities:CreatePadding(statFrame, 10)

		-- Icon
		local iconLabel = UIComponents:CreateLabel(statFrame, stat.icon, UDim2.new(0, 30, 1, 0), UDim2.new(0, 0, 0, 0), 20)

		-- Name
		local nameLabel = UIComponents:CreateLabel(statFrame, stat.name, UDim2.new(0.4, -40, 1, 0), UDim2.new(0, 40, 0, 0), 14)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)

		-- Value with formatting
		local valueText = stat.value
		if stat.suffix then
			valueText = "+" .. valueText .. stat.suffix
		else
			valueText = Utilities:FormatNumber(valueText)
		end
		
		local valueLabel = UIComponents:CreateLabel(statFrame, valueText, UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), 16)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Font = CLIENT_CONFIG.FONTS.Numbers
		valueLabel.TextColor3 = stat.color or CLIENT_CONFIG.COLORS.Dark

		-- Add progress bar for visual representation
		if not stat.suffix then
			local maxValue = stat.name == "Power" and 10000 or
							 stat.name == "Health" and 5000 or
							 stat.name == "Defense" and 1000 or
							 stat.name == "Speed" and 500 or
							 stat.name == "Luck" and 100 or 1000
			
			local progressBar = Instance.new("Frame")
			progressBar.Size = UDim2.new(0.4, -10, 0, 4)
			progressBar.Position = UDim2.new(0.3, 5, 1, -10)
			progressBar.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			progressBar.BorderSizePixel = 0
			progressBar.Parent = statFrame
			
			local progressFill = Instance.new("Frame")
			progressFill.Size = UDim2.new(math.min(1, stat.value / maxValue), 0, 1, 0)
			progressFill.BackgroundColor3 = stat.color or CLIENT_CONFIG.COLORS.Primary
			progressFill.BorderSizePixel = 0
			progressFill.Parent = progressBar
			
			Utilities:CreateCorner(progressBar, 2)
			Utilities:CreateCorner(progressFill, 2)
		end

		yOffset = yOffset + 50
	end

	-- Total Power Section
	local totalPowerFrame = Instance.new("Frame")
	totalPowerFrame.Size = UDim2.new(1, 0, 0, 60)
	totalPowerFrame.Position = UDim2.new(0, 0, 0, yOffset)
	totalPowerFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
	totalPowerFrame.Parent = statsContainer

	Utilities:CreateCorner(totalPowerFrame, 12)
	Utilities:CreatePadding(totalPowerFrame, 15)

	local totalPowerLabel = UIComponents:CreateLabel(totalPowerFrame, "⚡ TOTAL POWER", UDim2.new(0.5, 0, 0, 20), UDim2.new(0, 0, 0, 0), 14)
	totalPowerLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalPowerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
	totalPowerLabel.Font = CLIENT_CONFIG.FONTS.Secondary

	-- Calculate total power (sum of all combat stats)
	local totalPower = actualPower + 
					   (petInstance.stats.health or 500) * 0.1 + 
					   (petInstance.stats.defense or 50) * 2 + 
					   (petInstance.stats.speed or 100) * 0.5
	
	local totalPowerValue = UIComponents:CreateLabel(totalPowerFrame, Utilities:FormatNumber(math.floor(totalPower)), UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 20), 24)
	totalPowerValue.TextColor3 = CLIENT_CONFIG.COLORS.White
	totalPowerValue.Font = CLIENT_CONFIG.FONTS.Numbers

	yOffset = yOffset + 70

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

-- Enhanced ShowPetAbilities with better display
function UIModules.InventoryUI:ShowPetAbilities(parent, petInstance, petData)
	if not petData then
		local errorLabel = UIComponents:CreateLabel(parent, "No ability data available", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 20)
		errorLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
		return
	end

	local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))

	local abilitiesContainer = Instance.new("Frame")
	abilitiesContainer.Size = UDim2.new(1, -10, 0, 500)
	abilitiesContainer.BackgroundTransparency = 1
	abilitiesContainer.Parent = scrollFrame

	local yOffset = 0

	-- Get abilities from pet data
	local abilities = petData.abilities
	
	if not abilities or type(abilities) ~= "table" then
		-- Show no abilities message
		local noAbilitiesFrame = Instance.new("Frame")
		noAbilitiesFrame.Size = UDim2.new(1, 0, 0, 150)
		noAbilitiesFrame.Position = UDim2.new(0, 0, 0.5, -75)
		noAbilitiesFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
		noAbilitiesFrame.Parent = abilitiesContainer
		
		Utilities:CreateCorner(noAbilitiesFrame, 12)
		
		local iconLabel = UIComponents:CreateLabel(noAbilitiesFrame, "🚫", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 20), 40)
		iconLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
		
		local messageLabel = UIComponents:CreateLabel(noAbilitiesFrame, "This pet has no special abilities", UDim2.new(1, -40, 0, 30), UDim2.new(0, 20, 0, 80), 18)
		messageLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
		messageLabel.Font = CLIENT_CONFIG.FONTS.Secondary
		
		return
	end

	-- Handle both array and dictionary formats
	local abilityList = {}
	if abilities[1] then
		-- Array format
		abilityList = abilities
	else
		-- Dictionary format - convert to array
		for name, data in pairs(abilities) do
			if type(data) == "table" then
				data.name = data.name or name
				table.insert(abilityList, data)
			end
		end
	end

	-- Sort abilities by level requirement
	table.sort(abilityList, function(a, b)
		return (a.level or 1) < (b.level or 1)
	end)

	-- Display each ability
	for i, ability in ipairs(abilityList) do
		local abilityFrame = Instance.new("Frame")
		abilityFrame.Size = UDim2.new(1, 0, 0, 120)
		abilityFrame.Position = UDim2.new(0, 0, 0, yOffset)
		abilityFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
		abilityFrame.Parent = abilitiesContainer

		Utilities:CreateCorner(abilityFrame, 12)
		Utilities:CreatePadding(abilityFrame, 15)

		-- Check if ability is unlocked
		local isUnlocked = (ability.level or 1) <= (petInstance.level or 1)
		
		-- Ability icon/emoji
		local abilityIcon = ability.icon or "🌟"
		local iconLabel = UIComponents:CreateLabel(abilityFrame, abilityIcon, UDim2.new(0, 40, 0, 40), UDim2.new(0, 0, 0, 0), 30)
		iconLabel.TextColor3 = isUnlocked and CLIENT_CONFIG.COLORS.Primary or Color3.fromRGB(150, 150, 150)

		-- Ability name
		local nameLabel = UIComponents:CreateLabel(abilityFrame, ability.name or "Unknown Ability", UDim2.new(0.7, -50, 0, 25), UDim2.new(0, 50, 0, 0), 18)
		nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = isUnlocked and CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(150, 150, 150)

		-- Level requirement or active status
		if not isUnlocked then
			local lockLabel = UIComponents:CreateLabel(abilityFrame, "🔒 Lv." .. (ability.level or 1), UDim2.new(0, 100, 0, 25), UDim2.new(1, -100, 0, 0), 14)
			lockLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
			lockLabel.TextXAlignment = Enum.TextXAlignment.Right
			lockLabel.Font = CLIENT_CONFIG.FONTS.Secondary
		else
			local activeLabel = UIComponents:CreateLabel(abilityFrame, "✓ Active", UDim2.new(0, 80, 0, 25), UDim2.new(1, -80, 0, 0), 14)
			activeLabel.TextColor3 = CLIENT_CONFIG.COLORS.Success
			activeLabel.TextXAlignment = Enum.TextXAlignment.Right
			activeLabel.Font = CLIENT_CONFIG.FONTS.Secondary
		end

		-- Description
		local descText = ability.description or "No description available"
		local descLabel = UIComponents:CreateLabel(abilityFrame, descText, UDim2.new(1, -60, 0, 40), UDim2.new(0, 50, 0, 30), 14)
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		descLabel.TextWrapped = true

		-- Stats row
		local statsY = 75
		local statX = 50
		
		-- Cooldown
		if ability.cooldown then
			local cdLabel = UIComponents:CreateLabel(abilityFrame, "⏱️ " .. ability.cooldown .. "s", UDim2.new(0, 80, 0, 20), UDim2.new(0, statX, 0, statsY), 12)
			cdLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			cdLabel.TextXAlignment = Enum.TextXAlignment.Left
			statX = statX + 90
		end

		-- Damage/Effect
		if ability.damage or ability.effect then
			local effectText = ability.damage and ("💥 " .. ability.damage) or ("✨ " .. ability.effect)
			local effectLabel = UIComponents:CreateLabel(abilityFrame, effectText, UDim2.new(0, 80, 0, 20), UDim2.new(0, statX, 0, statsY), 12)
			effectLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			effectLabel.TextXAlignment = Enum.TextXAlignment.Left
			statX = statX + 90
		end

		-- Range
		if ability.range then
			local rangeLabel = UIComponents:CreateLabel(abilityFrame, "📏 " .. ability.range, UDim2.new(0, 80, 0, 20), UDim2.new(0, statX, 0, statsY), 12)
			rangeLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
			rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
		end

		-- Make frame slightly transparent if locked
		if not isUnlocked then
			abilityFrame.BackgroundTransparency = 0.3
		end

		yOffset = yOffset + 130
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

-- Enhanced ShowPetInfo with all metadata
function UIModules.InventoryUI:ShowPetInfo(parent, petInstance, petData)
	local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))
	
	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(1, -10, 0, 500)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = scrollFrame

	-- Calculate pet value based on rarity and variant
	local baseValue = petData.baseValue or 100
	local variantMultiplier = 1
	if petInstance.variant and petData.variants and petData.variants[petInstance.variant] then
		variantMultiplier = petData.variants[petInstance.variant].multiplier or 1
	elseif petInstance.variant == "shiny" then
		variantMultiplier = 5
	elseif petInstance.variant == "golden" then
		variantMultiplier = 10
	elseif petInstance.variant == "rainbow" then
		variantMultiplier = 25
	end
	local totalValue = math.floor(baseValue * variantMultiplier * (1 + (petInstance.level or 1) * 0.1))

	local infoList = {
		{label = "Pet ID", value = petInstance.uniqueId or petInstance.id or "N/A", copyable = true},
		{label = "Species", value = petData.displayName or "Unknown"},
		{label = "Category", value = petData.category or "Standard"},
		{label = "Rarity", value = ({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "SECRET"})[petData.rarity or 1], color = Utilities:GetRarityColor(petData.rarity)},
		{label = "Variant", value = petInstance.variant and petInstance.variant:gsub("_", " "):gsub("^%l", string.upper) or "Normal", color = Utilities:GetVariantColor(petInstance.variant)},
		{label = "Level", value = tostring(petInstance.level or 1)},
		{label = "Experience", value = Utilities:FormatNumber(petInstance.experience or 0) .. " XP"},
		{label = "Obtained", value = os.date("%m/%d/%Y %I:%M %p", petInstance.obtained or os.time())},
		{label = "Source", value = petInstance.source and petInstance.source:gsub("_", " "):gsub("^%l", string.upper) or "Unknown"},
		{label = "Times Hatched", value = tostring(petInstance.timesHatched or 1)},
		{label = "Value", value = "💰 " .. Utilities:FormatNumber(totalValue), color = Color3.fromRGB(255, 215, 0)},
		{label = "Tradeable", value = (petData.tradeable ~= false) and "Yes" or "No", color = (petData.tradeable ~= false) and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Error},
		{label = "Locked", value = petInstance.locked and "Yes" or "No", color = petInstance.locked and CLIENT_CONFIG.COLORS.Error or CLIENT_CONFIG.COLORS.Success},
		{label = "Equipped", value = petInstance.equipped and "Yes" or "No", color = petInstance.equipped and CLIENT_CONFIG.COLORS.Success or Color3.fromRGB(150, 150, 150)},
		{label = "Nickname", value = petInstance.nickname or "None", editable = true}
	}

	local yOffset = 0
	for _, info in ipairs(infoList) do
		local infoRow = Instance.new("Frame")
		infoRow.Size = UDim2.new(1, 0, 0, 35)
		infoRow.Position = UDim2.new(0, 0, 0, yOffset)
		infoRow.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
		infoRow.Parent = infoContainer

		Utilities:CreateCorner(infoRow, 6)
		Utilities:CreatePadding(infoRow, 10)

		-- Label
		local labelText = UIComponents:CreateLabel(infoRow, info.label .. ":", UDim2.new(0.4, 0, 1, 0), UDim2.new(0, 0, 0, 0), 14)
		labelText.TextXAlignment = Enum.TextXAlignment.Left
		labelText.TextColor3 = Color3.fromRGB(100, 100, 100)
		labelText.Font = CLIENT_CONFIG.FONTS.Secondary

		-- Value
		local valueText = UIComponents:CreateLabel(infoRow, tostring(info.value), UDim2.new(0.6, -70, 1, 0), UDim2.new(0.4, 0, 0, 0), 14)
		valueText.TextXAlignment = Enum.TextXAlignment.Right
		valueText.Font = CLIENT_CONFIG.FONTS.Secondary
		valueText.TextColor3 = info.color or CLIENT_CONFIG.COLORS.Dark

		-- Special actions
		if info.copyable then
			local copyButton = UIComponents:CreateButton(infoRow, "📋", UDim2.new(0, 25, 0, 25), UDim2.new(1, -30, 0.5, -12.5), function()
				setclipboard(tostring(info.value))
				NotificationSystem:SendNotification("Copied!", "Pet ID copied to clipboard", "success")
			end)
			copyButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Secondary
		elseif info.editable and info.label == "Nickname" and info.value == "None" then
			local renameButton = UIComponents:CreateButton(infoRow, "✏️", UDim2.new(0, 60, 0, 25), UDim2.new(1, -65, 0.5, -12.5), function()
				self:RenamePet(petInstance)
			end)
			renameButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
			renameButton.Text = "Rename"
			renameButton.TextScaled = true
		end

		-- Hover effect
		infoRow.MouseEnter:Connect(function()
			infoRow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
		end)

		infoRow.MouseLeave:Connect(function()
			infoRow.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
		end)

		yOffset = yOffset + 40
	end

	-- Add pet description if available
	if petData.description then
		local descFrame = Instance.new("Frame")
		descFrame.Size = UDim2.new(1, 0, 0, 80)
		descFrame.Position = UDim2.new(0, 0, 0, yOffset)
		descFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface
		descFrame.Parent = infoContainer

		Utilities:CreateCorner(descFrame, 8)
		Utilities:CreatePadding(descFrame, 15)

		local descTitle = UIComponents:CreateLabel(descFrame, "Description", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), 16)
		descTitle.Font = CLIENT_CONFIG.FONTS.Secondary
		descTitle.TextXAlignment = Enum.TextXAlignment.Left

		local descText = UIComponents:CreateLabel(descFrame, petData.description, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 25), 14)
		descText.TextXAlignment = Enum.TextXAlignment.Left
		descText.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
		descText.TextWrapped = true

		yOffset = yOffset + 90
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end