-- Simplified CreatePetCard function - shows only basic info
function UIModules.InventoryUI:CreatePetCard(parent, petInstance, petData)
	if not petInstance or not petData then
		return nil
	end

	-- Create card container
	local card = Instance.new("Frame")
	card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.id or "unknown")
	card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface or Color3.fromRGB(255, 250, 250)
	card.BorderSizePixel = 3
	card.BorderColor3 = Utilities:GetRarityColor(petData.rarity)
	card.Parent = parent

	-- Add corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	-- Create pet image
	local petImage = Instance.new("ImageLabel")
	petImage.Name = "PetImage"
	petImage.Size = UDim2.new(0, 100, 0, 100)
	petImage.Position = UDim2.new(0.5, -50, 0, 15)
	petImage.BackgroundTransparency = 1
	petImage.ScaleType = Enum.ScaleType.Fit
	petImage.Image = petData.imageId or "rbxassetid://0"
	petImage.Parent = card

	-- Level badge (top-left)
	local levelBadge = Instance.new("Frame")
	levelBadge.Name = "LevelBadge"
	levelBadge.Size = UDim2.new(0, 45, 0, 22)
	levelBadge.Position = UDim2.new(0, 5, 0, 5)
	levelBadge.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(50, 50, 50)
	levelBadge.Parent = card

	local levelCorner = Instance.new("UICorner")
	levelCorner.CornerRadius = UDim.new(0, 10)
	levelCorner.Parent = levelBadge

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, 0, 1, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv." .. (petInstance.level or 1)
	levelLabel.TextScaled = true
	levelLabel.TextColor3 = Color3.new(1, 1, 1)
	levelLabel.Font = Enum.Font.SourceSansBold
	levelLabel.Parent = levelBadge

	-- Equipped indicator (top-right)
	local equippedBadge = Instance.new("Frame")
	equippedBadge.Name = "EquippedBadge"
	equippedBadge.Size = UDim2.new(0, 24, 0, 24)
	equippedBadge.Position = UDim2.new(1, -30, 0, 5)
	equippedBadge.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success or Color3.fromRGB(0, 255, 0)
	equippedBadge.BorderSizePixel = 0
	equippedBadge.Visible = petInstance.equipped or false
	equippedBadge.Parent = card

	local equippedCorner = Instance.new("UICorner")
	equippedCorner.CornerRadius = UDim.new(0, 12)
	equippedCorner.Parent = equippedBadge

	local checkmark = Instance.new("TextLabel")
	checkmark.Size = UDim2.new(1, 0, 1, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Text = "✓"
	checkmark.TextSize = 18
	checkmark.TextColor3 = Color3.new(1, 1, 1)
	checkmark.Font = Enum.Font.SourceSansBold
	checkmark.Parent = equippedBadge

	-- Lock indicator (always create, control visibility)
	local lockIcon = Instance.new("ImageLabel")
	lockIcon.Name = "LockIcon"
	lockIcon.Size = UDim2.new(0, 20, 0, 20)
	lockIcon.Position = UDim2.new(1, -25, 1, -25)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Image = "rbxassetid://10709778200"
	lockIcon.ImageColor3 = CLIENT_CONFIG.COLORS.Error or Color3.fromRGB(255, 0, 0)
	lockIcon.ScaleType = Enum.ScaleType.Fit
	lockIcon.Visible = petInstance.locked or false
	lockIcon.Parent = card

	-- Variant badge (bottom-right)
	if petInstance.variant and petInstance.variant ~= "normal" then
		local variantBadge = Instance.new("Frame")
		variantBadge.Name = "VariantBadge"
		variantBadge.Size = UDim2.new(0, 30, 0, 30)
		variantBadge.Position = UDim2.new(1, -35, 1, -35)
		variantBadge.BackgroundColor3 = Utilities:GetVariantColor(petInstance.variant)
		variantBadge.Parent = card

		Utilities:CreateCorner(variantBadge, 15)

		local variantIcon = Instance.new("TextLabel")
		variantIcon.Size = UDim2.new(1, 0, 1, 0)
		variantIcon.BackgroundTransparency = 1
		variantIcon.Text = "✨"
		variantIcon.TextScaled = true
		variantIcon.TextColor3 = CLIENT_CONFIG.COLORS.White
		variantIcon.Parent = variantBadge
	end

	-- Pet name (centered at bottom)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 25)
	nameLabel.Position = UDim2.new(0.5, 0, 0, 120)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = petInstance.nickname or petData.displayName or "Unknown Pet"
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = CLIENT_CONFIG.COLORS.Text or Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card

	-- Click handler
	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = card

	clickButton.MouseButton1Click:Connect(function()
		self:ShowPetDetails(petInstance, petData)
	end)

	-- Hover effect
	card.MouseEnter:Connect(function()
		card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background or Color3.fromRGB(240, 240, 240)
	end)

	card.MouseLeave:Connect(function()
		card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface or Color3.fromRGB(255, 250, 250)
	end)

	-- Store attributes for search
	card:SetAttribute("PetName", petData.displayName)
	card:SetAttribute("PetNickname", petInstance.nickname or "")

	return card
end

-- Update function with proper indicator updates
function UIModules.InventoryUI:UpdatePetCard(card, petInstance, petData)
	-- Update card name
	card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.id)

	-- Update pet image
	local petImage = card:FindFirstChild("PetImage")
	if petImage then
		petImage.Image = petData.imageId
	end

	-- Update level badge
	local levelBadge = card:FindFirstChild("LevelBadge")
	if levelBadge then
		local levelText = levelBadge:FindFirstChild("TextLabel")
		if levelText then
			levelText.Text = "Lv." .. (petInstance.level or 1)
		end
	end

	-- Update name
	local nameLabel = card:FindFirstChild("NameLabel")
	if nameLabel then
		nameLabel.Text = petInstance.nickname or petData.displayName
		card:SetAttribute("PetName", petData.displayName)
		card:SetAttribute("PetNickname", petInstance.nickname or "")
	end

	-- Update equipped badge
	local equippedBadge = card:FindFirstChild("EquippedBadge")
	if equippedBadge then
		equippedBadge.Visible = petInstance.equipped or false
	end

	-- Update lock icon
	local lockIcon = card:FindFirstChild("LockIcon")
	if lockIcon then
		lockIcon.Visible = petInstance.locked or false
	end

	-- Update border color for rarity
	card.BorderColor3 = Utilities:GetRarityColor(petData.rarity)

	-- Update variant badge
	local variantBadge = card:FindFirstChild("VariantBadge")
	if petInstance.variant and petInstance.variant ~= "normal" then
		if not variantBadge then
			-- Create variant badge
			variantBadge = Instance.new("Frame")
			variantBadge.Name = "VariantBadge"
			variantBadge.Size = UDim2.new(0, 30, 0, 30)
			variantBadge.Position = UDim2.new(1, -35, 1, -35)
			variantBadge.BackgroundColor3 = Utilities:GetVariantColor(petInstance.variant)
			variantBadge.Parent = card

			Utilities:CreateCorner(variantBadge, 15)

			local variantIcon = Instance.new("TextLabel")
			variantIcon.Size = UDim2.new(1, 0, 1, 0)
			variantIcon.BackgroundTransparency = 1
			variantIcon.Text = "✨"
			variantIcon.TextScaled = true
			variantIcon.TextColor3 = CLIENT_CONFIG.COLORS.White
			variantIcon.Parent = variantBadge
		end
		variantBadge.Visible = true
		variantBadge.BackgroundColor3 = Utilities:GetVariantColor(petInstance.variant)
	elseif variantBadge then
		variantBadge.Visible = false
	end
end