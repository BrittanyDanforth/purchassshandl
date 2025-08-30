-- ========================================
-- INVENTORY UI MODULE
-- ========================================
UIModules.InventoryUI = {}

function UIModules.InventoryUI:Open()
	if self.Frame then
		self.Frame.Visible = true
		self:RefreshInventory()
		return
	end

	-- Initialize pet card cache for performance
	self.PetCardCache = {}
	self.MaxCacheSize = 100  -- Maximum cards to keep in cache

	-- Set up reactive updates if DataManager is available
	if DataManager and not self.PetWatcher then
		self.PetWatcher = DataManager:Watch("pets", function()
			if self.Frame and self.Frame.Visible then
				self:RefreshInventory()
			end
		end)
	end

	-- Create main inventory frame inside the main panel
	local inventoryFrame = UIComponents:CreateFrame(MainUI.MainPanel or MainUI.MainContainer, "InventoryFrame", UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 80))
	inventoryFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
	inventoryFrame.BackgroundTransparency = 0

	self.Frame = inventoryFrame

	-- Header
	local header = UIComponents:CreateFrame(inventoryFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)

	local headerLabel = UIComponents:CreateLabel(header, "🎀 My Pet Collection 🎀", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
	headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
	headerLabel.Font = CLIENT_CONFIG.FONTS.Display

	-- Stats bar
	local statsBar = Instance.new("Frame")
	statsBar.Size = UDim2.new(1, 0, 0, 40)
	statsBar.Position = UDim2.new(0, 0, 0, 60)
	statsBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
	statsBar.Parent = inventoryFrame

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Horizontal
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsLayout.Padding = UDim.new(0, 20)
	statsLayout.Parent = statsBar

	Utilities:CreatePadding(statsBar, 10)

	-- Pet count
	local petCountLabel = UIComponents:CreateLabel(statsBar, "Pets: 0/500", UDim2.new(0, 150, 1, 0), UDim2.new(0, 0, 0, 0), 16)
	petCountLabel.Font = CLIENT_CONFIG.FONTS.Secondary

	-- Equipped count
	local equippedLabel = UIComponents:CreateLabel(statsBar, "Equipped: 0/6", UDim2.new(0, 150, 1, 0), UDim2.new(0, 0, 0, 0), 16)
	equippedLabel.Font = CLIENT_CONFIG.FONTS.Secondary

	-- Storage usage
	local storageBar = UIComponents:CreateProgressBar(statsBar, UDim2.new(0, 200, 0, 20), UDim2.new(0, 0, 0.5, -10), 0, 500)

	self.StatsLabels = {
		PetCount = petCountLabel,
		Equipped = equippedLabel,
		Storage = storageBar
	}

	-- Filter and sort controls
	local controlsBar = Instance.new("Frame")
	controlsBar.Size = UDim2.new(1, 0, 0, 50)
	controlsBar.Position = UDim2.new(0, 0, 0, 100)
	controlsBar.BackgroundTransparency = 1
	controlsBar.Parent = inventoryFrame

	-- Search box
	local searchBox = UIComponents:CreateTextBox(controlsBar, "Search pets...", UDim2.new(0, 200, 0, 35), UDim2.new(0, 10, 0.5, -17.5))

	-- Debounced search
	local searchDebounce = nil
	searchBox.Changed:Connect(function()
		if searchDebounce then
			task.cancel(searchDebounce)
		end
		searchDebounce = task.spawn(function()
			task.wait(0.3)
			self:FilterPets(searchBox.Text)
			searchDebounce = nil
		end)
	end)

	-- Sort dropdown
	local sortOptions = {"Rarity", "Level", "Power", "Recent", "Name"}
	local sortDropdown = self:CreateDropdown(controlsBar, "Sort by", sortOptions, UDim2.new(0, 150, 0, 35), UDim2.new(0, 220, 0.5, -17.5))

	-- Filter dropdown
	local filterOptions = {"All", "Equipped", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Shiny", "Golden", "Rainbow"}
	local filterDropdown = self:CreateDropdown(controlsBar, "Filter", filterOptions, UDim2.new(0, 150, 0, 35), UDim2.new(0, 380, 0.5, -17.5))

	-- Mass actions
	local massDeleteButton = UIComponents:CreateButton(controlsBar, "Mass Delete", UDim2.new(0, 120, 0, 35), UDim2.new(1, -130, 0.5, -17.5), function()
		self:OpenMassDelete()
	end)
	massDeleteButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error

	-- Main content area with tabs
	local tabs = {
		{
			Name = "Pets",
			Init = function(parent)
				self:CreatePetGrid(parent)
			end
		},
		{
			Name = "Equipped",
			Init = function(parent)
				self:CreateEquippedView(parent)
			end
		},
		{
			Name = "Collection",
			Init = function(parent)
				self:CreateCollectionView(parent)
			end
		}
	}

	local tabContainer, tabFrames = UIComponents:CreateTab(inventoryFrame, tabs, UDim2.new(1, -20, 1, -170), UDim2.new(0, 10, 0, 160))
	self.TabFrames = tabFrames

	-- Initial inventory load
	self:RefreshInventory()
end

function UIModules.InventoryUI:CreatePetGrid(parent)
	-- Create scrolling frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PetGridScrollFrame"
	scrollFrame.Size = UDim2.new(1, -10, 1, -10)
	scrollFrame.Position = UDim2.new(0, 5, 0, 5)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = CLIENT_CONFIG.COLORS.Primary or Color3.fromRGB(0, 170, 255)
	scrollFrame.ScrollBarImageTransparency = 0.5
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = parent

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.Name = "PetGridLayout"
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.CellSize = UDim2.new(0, 150, 0, 140)  -- Reduced height for simplified cards
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = scrollFrame

	self.PetGrid = scrollFrame
	self.GridLayout = gridLayout

	-- Update canvas size when content changes
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
	end)
end

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

function UIModules.InventoryUI:ShowPetDetails(petInstance, petData)
	-- Close any existing details window first
	if self.DetailsOverlay and self.DetailsOverlay.Parent then
		self.DetailsOverlay:Destroy()
	end

	-- Create modal overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "PetDetailsOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.ZIndex = 200
	overlay.Parent = MainUI.ScreenGui

	-- Store reference so we can clean it up
	self.DetailsOverlay = overlay

	-- Register with MainUI overlay management
	MainUI:RegisterOverlay("PetDetails", overlay)

	-- Fade in
	overlay.BackgroundTransparency = 1
	Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)

	-- Details window
	local detailsFrame = Instance.new("Frame")
	detailsFrame.Name = "PetDetailsFrame"
	detailsFrame.Size = UDim2.new(0, 700, 0, 500)
	detailsFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	detailsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
	detailsFrame.ZIndex = 201
	detailsFrame.Parent = overlay

	Utilities:CreateCorner(detailsFrame, 20)
	Utilities:CreateShadow(detailsFrame, 0.5, 30)

	-- Animate in
	detailsFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	detailsFrame.Size = UDim2.new(0, 0, 0, 0)
	Utilities:Tween(detailsFrame, {
		Size = UDim2.new(0, 700, 0, 500),
		Position = UDim2.new(0.5, -350, 0.5, -250)
	}, CLIENT_CONFIG.TWEEN_INFO.Bounce)

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Utilities:GetRarityColor(petData.rarity)
	header.ZIndex = 202
	header.Parent = detailsFrame

	local headerCorner = Utilities:CreateCorner(header, 20)

	local bottomCorner = Instance.new("Frame")
	bottomCorner.Size = UDim2.new(1, 0, 0, 20)
	bottomCorner.Position = UDim2.new(0, 0, 1, -20)
	bottomCorner.BackgroundColor3 = header.BackgroundColor3
	bottomCorner.BorderSizePixel = 0
	bottomCorner.ZIndex = 202
	bottomCorner.Parent = header

	local titleLabel = UIComponents:CreateLabel(header, petInstance.nickname or petData.displayName, UDim2.new(1, -60, 1, 0), UDim2.new(0, 20, 0, 0), 24)
	titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
	titleLabel.Font = CLIENT_CONFIG.FONTS.Display
	titleLabel.ZIndex = 203

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "✕"
	closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
	closeButton.Font = CLIENT_CONFIG.FONTS.Primary
	closeButton.TextSize = 24
	closeButton.ZIndex = 203
	closeButton.Parent = header

	closeButton.MouseButton1Click:Connect(function()
		Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Close)
		Utilities:Tween(detailsFrame, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
		Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
		task.wait(0.3)
		MainUI:UnregisterOverlay("PetDetails")
		self.DetailsOverlay = nil
	end)

	-- Content
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -40, 1, -80)
	content.Position = UDim2.new(0, 20, 0, 70)
	content.BackgroundTransparency = 1
	content.ZIndex = 202
	content.Parent = detailsFrame

	-- Left side - Pet display
	local leftSide = Instance.new("Frame")
	leftSide.Name = "PetDetailsLeftSide"
	leftSide.Size = UDim2.new(0.4, -10, 1, 0)
	leftSide.BackgroundTransparency = 1
	leftSide.ZIndex = 202
	leftSide.Parent = content

	-- Pet display
	local petDisplay = Instance.new("ViewportFrame")
	petDisplay.Name = "PetDisplay"
	petDisplay.Size = UDim2.new(1, 0, 0, 180)
	petDisplay.Position = UDim2.new(0, 0, 0, 0)
	petDisplay.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
	petDisplay.ZIndex = 202
	petDisplay.Parent = leftSide

	Utilities:CreateCorner(petDisplay, 12)

	-- For now, show image
	local petImage = UIComponents:CreateImageLabel(petDisplay, petData.imageId, UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.1, 0, 0.1, 0))
	petImage.ZIndex = 203

	-- Container for variant label and buttons
	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(1, 0, 1, -200)
	infoContainer.Position = UDim2.new(0, 0, 0, 190)
	infoContainer.BackgroundTransparency = 1
	infoContainer.ZIndex = 204
	infoContainer.Parent = leftSide

	local infoLayout = Instance.new("UIListLayout")
	infoLayout.Name = "InfoLayout"
	infoLayout.FillDirection = Enum.FillDirection.Vertical
	infoLayout.Padding = UDim.new(0, 10)
	infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	infoLayout.Parent = infoContainer

	-- Variant label (if exists)
	if petInstance.variant and petInstance.variant ~= "normal" then
		local variantLabel = UIComponents:CreateLabel(infoContainer, "✨ " .. (petInstance.variant or ""):upper() .. " ✨", UDim2.new(1, 0, 0, 25), nil, 16)
		variantLabel.Name = "VariantLabel"
		variantLabel.TextColor3 = Utilities:GetVariantColor(petInstance.variant)
		variantLabel.Font = CLIENT_CONFIG.FONTS.Secondary
		variantLabel.ZIndex = 204
		variantLabel.LayoutOrder = 1
	end

	-- Action buttons frame
	local actionsFrame = Instance.new("Frame")
	actionsFrame.Name = "ActionButtonsFrame"
	actionsFrame.Size = UDim2.new(1, -20, 0, 100)
	actionsFrame.BackgroundTransparency = 1
	actionsFrame.ZIndex = 205
	actionsFrame.LayoutOrder = 2
	actionsFrame.Parent = infoContainer

	local actionsPadding = Instance.new("UIPadding")
	actionsPadding.PaddingLeft = UDim.new(0, 10)
	actionsPadding.PaddingRight = UDim.new(0, 10)
	actionsPadding.Parent = actionsFrame

	-- Equip/Unequip button
	local equipButton
	equipButton = UIComponents:CreateButton(actionsFrame, petInstance.equipped and "Unequip" or "Equip", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), function()
		if equipButton then
			equipButton.Text = "..."
			equipButton.Active = false
		end

		local remote = petInstance.equipped and RemoteFunctions.UnequipPet or RemoteFunctions.EquipPet
		local success, result = pcall(function()
			return remote:InvokeServer(petInstance.uniqueId or petInstance.id)
		end)

		if equipButton then
			equipButton.Active = true
		end

		if not success then
			NotificationSystem:SendNotification("Error", "Failed to connect to server", "error")
			if equipButton then
				equipButton.Text = petInstance.equipped and "Unequip" or "Equip"
			end
		elseif type(result) == "table" and result.success == false then
			NotificationSystem:SendNotification("Error", result.error or "Action failed", "error")
			if equipButton then
				equipButton.Text = petInstance.equipped and "Unequip" or "Equip"
			end
		elseif result then
			petInstance.equipped = not petInstance.equipped
			if equipButton then
				equipButton.Text = petInstance.equipped and "Unequip" or "Equip"
				equipButton.BackgroundColor3 = petInstance.equipped and CLIENT_CONFIG.COLORS.Error or CLIENT_CONFIG.COLORS.Success
				equipButton:SetAttribute("OriginalColor", equipButton.BackgroundColor3)
			end
			NotificationSystem:SendNotification("Success", petInstance.equipped and "Pet equipped!" or "Pet unequipped!", "success")
		end
	end)
	equipButton.BackgroundColor3 = petInstance.equipped and CLIENT_CONFIG.COLORS.Error or CLIENT_CONFIG.COLORS.Success
	equipButton:SetAttribute("OriginalColor", equipButton.BackgroundColor3)
	equipButton.ZIndex = 206

	-- Lock/Unlock button
	local lockButton
	lockButton = UIComponents:CreateButton(actionsFrame, petInstance.locked and "Unlock" or "Lock", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 50), function()
		petInstance.locked = not petInstance.locked
		if lockButton then
			lockButton.Text = petInstance.locked and "Unlock" or "Lock"
			lockButton.BackgroundColor3 = petInstance.locked and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Warning
			lockButton:SetAttribute("OriginalColor", lockButton.BackgroundColor3)
		end
		NotificationSystem:SendNotification("Info", petInstance.locked and "Pet locked!" or "Pet unlocked!", "info")
	end)
	lockButton.BackgroundColor3 = petInstance.locked and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Warning
	lockButton:SetAttribute("OriginalColor", lockButton.BackgroundColor3)
	lockButton.ZIndex = 206

	-- Right side - Stats and info
	local rightSide = Instance.new("Frame")
	rightSide.Name = "PetDetailsRightSide"
	rightSide.Size = UDim2.new(0.6, -10, 1, 0)
	rightSide.Position = UDim2.new(0.4, 10, 0, 0)
	rightSide.BackgroundTransparency = 1
	rightSide.ZIndex = 202
	rightSide.Parent = content

	-- Stats tabs
	local statsTabs = {
		{
			Name = "Stats",
			Init = function(parent)
				self:ShowPetStats(parent, petInstance, petData)
			end
		},
		{
			Name = "Abilities",
			Init = function(parent)
				self:ShowPetAbilities(parent, petInstance, petData)
			end
		},
		{
			Name = "Info",
			Init = function(parent)
				self:ShowPetInfo(parent, petInstance, petData)
			end
		}
	}

	UIComponents:CreateTab(rightSide, statsTabs, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
end

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

function UIModules.InventoryUI:RefreshInventory()
	-- Prevent multiple refreshes
	if self.IsRefreshing then
		return
	end
	self.IsRefreshing = true

	-- Ensure PetGrid exists
	if not self.PetGrid or not self.PetGrid.Parent then
		self.IsRefreshing = false
		return
	end

	-- Hide all existing cards instead of destroying them (for recycling)
	for _, card in ipairs(self.PetCardCache) do
		card.Visible = false
		card.Parent = nil
	end

	-- Get player data
	local playerData = DataManager and DataManager:GetData() or LocalData.PlayerData
	if not playerData then
		-- Show error state
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(1, 0, 0, 50)
		errorLabel.Position = UDim2.new(0, 0, 0.5, -25)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "No data available"
		errorLabel.TextScaled = true
		errorLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error or Color3.fromRGB(255, 0, 0)
		errorLabel.Font = Enum.Font.SourceSans
		errorLabel.Parent = self.PetGrid
		self.IsRefreshing = false
		return
	end

	-- Show loading state
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "LoadingLabel"
	loadingLabel.Size = UDim2.new(1, 0, 0, 50)
	loadingLabel.Position = UDim2.new(0, 0, 0.5, -25)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Text = "Loading pets..."
	loadingLabel.TextScaled = true
	loadingLabel.TextColor3 = CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(100, 100, 100)
	loadingLabel.Font = Enum.Font.SourceSans
	loadingLabel.Parent = self.PetGrid

	-- Process pets data
	task.spawn(function()
		task.wait(0.1)

		local pets = {}
		local equippedCount = 0

		-- Safely process pet data
		if playerData.pets and type(playerData.pets) == "table" then
			-- Clear pets array to avoid duplicates
			pets = {}

			-- Check if it's an array or dictionary
			if playerData.pets[1] then
				-- Array format
				for i, pet in ipairs(playerData.pets) do
					if pet and type(pet) == "table" then
						table.insert(pets, pet)
					end
				end
			else
				-- Dictionary format
				for uniqueId, petData in pairs(playerData.pets) do
					if type(petData) == "table" then
						petData.uniqueId = uniqueId
						table.insert(pets, petData)
					end
				end
			end

			-- Count equipped pets
			for _, pet in pairs(pets) do
				if pet.equipped then
					equippedCount = equippedCount + 1
				end
			end

			-- Sort pets by level (highest first)
			table.sort(pets, function(a, b)
				local aLevel = a.level or 1
				local bLevel = b.level or 1
				return aLevel > bLevel
			end)
		end

		-- Remove loading label
		if loadingLabel and loadingLabel.Parent then
			loadingLabel:Destroy()
		end

		-- Update stats
		local petCount = #pets
		if self.StatsLabels then
			self.StatsLabels.PetCount.Text = "Pets: " .. petCount .. "/" .. (playerData.maxPetStorage or 500)
			self.StatsLabels.Equipped.Text = "Equipped: " .. equippedCount .. "/6"
			if self.StatsLabels.Storage and self.StatsLabels.Storage.UpdateValue then
				self.StatsLabels.Storage.UpdateValue(petCount)
			end
		end

		-- Create pet cards
		if #pets == 0 then
			-- Show empty state
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 0, 100)
			emptyLabel.Position = UDim2.new(0, 0, 0.5, -50)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "No pets yet!\nOpen eggs to get started"
			emptyLabel.TextScaled = true
			emptyLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary or Color3.fromRGB(150, 150, 150)
			emptyLabel.Font = Enum.Font.SourceSans
			emptyLabel.Parent = self.PetGrid
		else
			-- Create cards for each pet
			for i, pet in ipairs(pets) do
				-- Get pet template data
				local petData = LocalData.PetDatabase and LocalData.PetDatabase[pet.petId]

				if not petData then
					-- Create fallback data if not in database
					petData = {
						id = pet.petId or "unknown",
						displayName = pet.name or pet.petId or "Unknown Pet",
						imageId = pet.imageId or "rbxassetid://0",
						rarity = pet.rarity or 1,
						description = pet.description or "A mysterious pet"
					}
				end

				-- Try to reuse existing card from cache
				local card = self.PetCardCache[i]
				if card then
					-- Update existing card
					self:UpdatePetCard(card, pet, petData)
					card.Parent = self.PetGrid
					card.Visible = true
				else
					-- Create new card if not enough in cache
					card = self:CreatePetCard(self.PetGrid, pet, petData)
					if card then
						self.PetCardCache[i] = card
					end
				end

				if card then
					card.LayoutOrder = i
				end
			end
		end

		-- Reset refresh flag
		self.IsRefreshing = false
	end)
end

function UIModules.InventoryUI:Close()
	if self.Frame then
		self.Frame.Visible = false
	end
end

-- Helper function to create dropdown
function UIModules.InventoryUI:CreateDropdown(parent, placeholder, options, size, position, onSelectCallback)
	local dropdown = Instance.new("Frame")
	dropdown.Size = size
	dropdown.Position = position
	dropdown.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
	dropdown.Parent = parent

	Utilities:CreateCorner(dropdown, 8)
	Utilities:CreateStroke(dropdown, CLIENT_CONFIG.COLORS.Primary, 2)

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = placeholder
	button.TextColor3 = CLIENT_CONFIG.COLORS.Dark
	button.Font = CLIENT_CONFIG.FONTS.Primary
	button.TextScaled = true
	button.Parent = dropdown

	Utilities:CreatePadding(button, 8)

	local arrow = UIComponents:CreateLabel(dropdown, "▼", UDim2.new(0, 20, 1, 0), UDim2.new(1, -25, 0, 0), 12)
	arrow.TextColor3 = CLIENT_CONFIG.COLORS.Dark

	local isOpen = false
	local optionsFrame = nil

	button.MouseButton1Click:Connect(function()
		if isOpen then
			if optionsFrame then
				optionsFrame:Destroy()
			end
			isOpen = false
			arrow.Text = "▼"
		else
			optionsFrame = Instance.new("Frame")
			optionsFrame.Size = UDim2.new(1, 0, 0, #options * 35)
			optionsFrame.Position = UDim2.new(0, 0, 1, 5)
			optionsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
			optionsFrame.ZIndex = dropdown.ZIndex + 10
			optionsFrame.Parent = dropdown

			Utilities:CreateCorner(optionsFrame, 8)
			Utilities:CreateShadow(optionsFrame, 0.3)

			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.Parent = optionsFrame

			for _, option in ipairs(options) do
				local optionButton = Instance.new("TextButton")
				optionButton.Size = UDim2.new(1, 0, 0, 35)
				optionButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
				optionButton.Text = option
				optionButton.TextColor3 = CLIENT_CONFIG.COLORS.Dark
				optionButton.Font = CLIENT_CONFIG.FONTS.Primary
				optionButton.TextScaled = true
				optionButton.ZIndex = optionsFrame.ZIndex + 1
				optionButton.Parent = optionsFrame

				Utilities:CreatePadding(optionButton, 8)

				optionButton.MouseEnter:Connect(function()
					optionButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
				end)

				optionButton.MouseLeave:Connect(function()
					optionButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
				end)

				optionButton.MouseButton1Click:Connect(function()
					button.Text = option
					optionsFrame:Destroy()
					isOpen = false
					arrow.Text = "▼"

					if onSelectCallback then
						onSelectCallback(option)
					end
				end)
			end

			isOpen = true
			arrow.Text = "▲"
		end
	end)

	return dropdown
end

function UIModules.InventoryUI:FilterPets(searchText)
	if not self.PetGrid then return end

	searchText = searchText:lower()

	for _, child in ipairs(self.PetGrid:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^PetCard_") then
			local petName = child:GetAttribute("PetName") or ""
			local petNickname = child:GetAttribute("PetNickname") or ""
			local searchName = (petNickname ~= "" and petNickname or petName):lower()
			local isVisible = searchText == "" or searchName:find(searchText, 1, true) ~= nil
			child.Visible = isVisible
		end
	end
end

function UIModules.InventoryUI:RenamePet(petInstance)
	-- Create rename dialog
	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0, 400, 0, 200)
	dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
	dialog.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
	dialog.ZIndex = 300
	dialog.Parent = MainUI.ScreenGui

	Utilities:CreateCorner(dialog, 12)
	Utilities:CreateShadow(dialog, 0.5)

	local title = UIComponents:CreateLabel(dialog, "Rename Pet", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 10), 20)
	title.Font = CLIENT_CONFIG.FONTS.Secondary

	local input = UIComponents:CreateTextBox(dialog, "Enter new name...", UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 0, 60))

	local buttonContainer = Instance.new("Frame")
	buttonContainer.Size = UDim2.new(1, -40, 0, 40)
	buttonContainer.Position = UDim2.new(0, 20, 1, -60)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = dialog

	local cancelButton = UIComponents:CreateButton(buttonContainer, "Cancel", UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), function()
		dialog:Destroy()
	end)
	cancelButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error

	local confirmButton = UIComponents:CreateButton(buttonContainer, "Confirm", UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), function()
		if input.Text ~= "" then
			petInstance.nickname = input.Text
			-- Send to server
			local success, result = pcall(function()
				return RemoteFunctions.RenamePet:InvokeServer(petInstance.uniqueId, input.Text)
			end)

			if success and result then
				Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
				self:RefreshInventory()
			else
				Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Error)
				NotificationSystem:SendNotification("Error", "Failed to rename pet", "error")
			end
			NotificationSystem:SendNotification("Success", "Pet renamed to " .. input.Text, "success")
			dialog:Destroy()
		end
	end)
	confirmButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
end

-- Add variant color helper to Utilities
function Utilities:GetVariantColor(variant)
	if not variant then return CLIENT_CONFIG.COLORS.Dark end
	
	local variantColors = {
		normal = CLIENT_CONFIG.COLORS.Dark,
		shiny = Color3.fromRGB(255, 255, 150),  -- Light yellow
		golden = Color3.fromRGB(255, 215, 0),    -- Gold
		rainbow = Color3.fromRGB(255, 100, 255), -- Pink/Purple
		dark = Color3.fromRGB(50, 0, 50),        -- Dark purple
		neon = Color3.fromRGB(0, 255, 255),      -- Cyan
		crystal = Color3.fromRGB(150, 200, 255), -- Light blue
		shadow = Color3.fromRGB(30, 30, 30),     -- Very dark
	}
	
	return variantColors[variant:lower()] or CLIENT_CONFIG.COLORS.Warning
end

-- Placeholder functions for other views
function UIModules.InventoryUI:CreateEquippedView(parent)
	local label = UIComponents:CreateLabel(parent, "Equipped pets view coming soon!", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 20)
	label.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
end

function UIModules.InventoryUI:CreateCollectionView(parent)
	local label = UIComponents:CreateLabel(parent, "Collection view coming soon!", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 20)
	label.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
end

function UIModules.InventoryUI:OpenMassDelete()
	NotificationSystem:SendNotification("Coming Soon", "Mass delete feature is under development", "info")
end