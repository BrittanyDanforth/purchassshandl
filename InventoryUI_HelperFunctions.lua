-- Add to Utilities module
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

-- Update CreatePetGrid to use smaller cell size
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
	gridLayout.CellSize = UDim2.new(0, 150, 0, 140)  -- Reduced height since we removed stats
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

-- Update the equipped view to also use simple cards
function UIModules.InventoryUI:CreateEquippedView(parent)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -20, 1, -20)
	container.Position = UDim2.new(0, 10, 0, 10)
	container.BackgroundTransparency = 1
	container.Parent = parent

	-- Title
	local titleLabel = UIComponents:CreateLabel(container, "Equipped Pets (0/6)", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 20)
	titleLabel.Font = CLIENT_CONFIG.FONTS.Secondary
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Equipped slots grid
	local slotsFrame = Instance.new("Frame")
	slotsFrame.Size = UDim2.new(1, 0, 1, -50)
	slotsFrame.Position = UDim2.new(0, 0, 0, 40)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = container

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	gridLayout.CellSize = UDim2.new(0, 150, 0, 140)  -- Same size as inventory grid
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = slotsFrame

	self.EquippedSlotsFrame = slotsFrame
	self.EquippedTitleLabel = titleLabel

	-- Create 6 slots
	for i = 1, 6 do
		local slot = Instance.new("Frame")
		slot.Name = "EquipSlot" .. i
		slot.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface
		slot.BorderSizePixel = 2
		slot.BorderColor3 = CLIENT_CONFIG.COLORS.Primary
		slot.LayoutOrder = i
		slot.Parent = slotsFrame

		Utilities:CreateCorner(slot, 12)

		-- Slot number
		local slotNumber = UIComponents:CreateLabel(slot, tostring(i), UDim2.new(0, 30, 0, 30), UDim2.new(0, 5, 0, 5), 16)
		slotNumber.TextColor3 = CLIENT_CONFIG.COLORS.Primary
		slotNumber.Font = CLIENT_CONFIG.FONTS.Numbers

		-- Empty slot text
		local emptyLabel = UIComponents:CreateLabel(slot, "Empty Slot", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0.5, -10), 14)
		emptyLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
		emptyLabel.Name = "EmptyLabel"
	end

	-- Refresh equipped pets
	self:RefreshEquippedPets()
end

-- Refresh equipped pets display
function UIModules.InventoryUI:RefreshEquippedPets()
	if not self.EquippedSlotsFrame then return end

	-- Get player data
	local playerData = DataManager and DataManager:GetData() or LocalData.PlayerData
	if not playerData or not playerData.pets then return end

	-- Clear all slots first
	for i = 1, 6 do
		local slot = self.EquippedSlotsFrame:FindFirstChild("EquipSlot" .. i)
		if slot then
			-- Remove existing pet card if any
			local existingCard = slot:FindFirstChild("PetCard")
			if existingCard then
				existingCard:Destroy()
			end
			
			-- Show empty label
			local emptyLabel = slot:FindFirstChild("EmptyLabel")
			if emptyLabel then
				emptyLabel.Visible = true
			end
		end
	end

	-- Find equipped pets and add them to slots
	local equippedCount = 0
	local equippedPets = {}
	
	-- Collect equipped pets
	for _, pet in pairs(playerData.pets) do
		if pet.equipped and pet.equipSlot then
			equippedPets[pet.equipSlot] = pet
			equippedCount = equippedCount + 1
		end
	end

	-- Update title
	if self.EquippedTitleLabel then
		self.EquippedTitleLabel.Text = string.format("Equipped Pets (%d/6)", equippedCount)
	end

	-- Place equipped pets in their slots
	for slotNum, pet in pairs(equippedPets) do
		local slot = self.EquippedSlotsFrame:FindFirstChild("EquipSlot" .. slotNum)
		if slot then
			-- Hide empty label
			local emptyLabel = slot:FindFirstChild("EmptyLabel")
			if emptyLabel then
				emptyLabel.Visible = false
			end

			-- Get pet data
			local petData = LocalData.PetDatabase and LocalData.PetDatabase[pet.petId]
			if petData then
				-- Create mini pet card
				local miniCard = self:CreateEquippedPetCard(slot, pet, petData, slotNum)
			end
		end
	end
end

-- Create a mini pet card for equipped view
function UIModules.InventoryUI:CreateEquippedPetCard(slot, petInstance, petData, slotNumber)
	local card = Instance.new("Frame")
	card.Name = "PetCard"
	card.Size = UDim2.new(1, -4, 1, -4)
	card.Position = UDim2.new(0, 2, 0, 2)
	card.BackgroundTransparency = 1
	card.Parent = slot

	-- Pet image
	local petImage = Instance.new("ImageLabel")
	petImage.Size = UDim2.new(0, 80, 0, 80)
	petImage.Position = UDim2.new(0.5, -40, 0, 20)
	petImage.BackgroundTransparency = 1
	petImage.ScaleType = Enum.ScaleType.Fit
	petImage.Image = petData.imageId or "rbxassetid://0"
	petImage.Parent = card

	-- Pet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 1, -25)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = petInstance.nickname or petData.displayName
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = CLIENT_CONFIG.COLORS.Text
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = card

	-- Level in corner
	local levelLabel = UIComponents:CreateLabel(card, "Lv." .. (petInstance.level or 1), UDim2.new(0, 40, 0, 20), UDim2.new(1, -45, 0, 5), 12)
	levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.Primary
	levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
	levelLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Click to view details
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = card

	button.MouseButton1Click:Connect(function()
		self:ShowPetDetails(petInstance, petData)
	end)

	-- Unequip on right click
	button.MouseButton2Click:Connect(function()
		local success, result = pcall(function()
			return RemoteFunctions.UnequipPet:InvokeServer(petInstance.uniqueId or petInstance.id)
		end)

		if success and result then
			NotificationSystem:SendNotification("Success", "Pet unequipped!", "success")
			self:RefreshEquippedPets()
			self:RefreshInventory()
		end
	end)

	return card
end