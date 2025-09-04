--[[
    Module: MassDeleteUI
    Description: Two-panel wizard-style mass pet deletion interface
    Features:
        - Left panel: Available pets with filters
        - Right panel: Selected pets for deletion
        - Drag-and-drop style selection
        - Real-time resource calculation
        - Safety countdown on delete confirmation
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local MassDeleteUI = {}
MassDeleteUI.__index = MassDeleteUI

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(1200, 700)
local CARD_SIZE = UDim2.new(0, 90, 0, 110)
local RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(100, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
	Mythic = Color3.fromRGB(255, 100, 100)
}

local RARITY_VALUES = {
	Common = {coins = 10, dust = 1},
	Uncommon = {coins = 25, dust = 3},
	Rare = {coins = 100, dust = 10},
	Epic = {coins = 500, dust = 50},
	Legendary = {coins = 2000, dust = 200},
	Mythic = {coins = 10000, dust = 1000}
}

-- ========================================
-- INITIALIZATION
-- ========================================

function MassDeleteUI.new(client)
	local self = setmetatable({}, MassDeleteUI)

	-- Core references
	self._client = client
	self._player = Services.Players.LocalPlayer
	self._playerGui = self._player:WaitForChild("PlayerGui")
	self._tweenService = Services.TweenService

	-- Dependencies
	self._remoteManager = client.RemoteManager
	self._eventBus = client.EventBus
	self._dataCache = client.DataCache
	self._soundSystem = client.SoundSystem
	self._notificationSystem = client.NotificationSystem
	self._utilities = client.Utilities or Utilities

	-- State
	self._availablePets = {} -- Pets in left panel
	self._selectedPets = {} -- Pets in right panel
	self._filters = {
		rarities = {},
		duplicatesOnly = false,
		keepBest = true,
		searchText = ""
	}
	self._totalCoins = 0
	self._totalDust = 0
	
	-- UI References
	self._screenGui = nil
	self._window = nil
	self._leftPanel = nil
	self._rightPanel = nil
	self._leftGrid = nil
	self._rightGrid = nil
	self._resourceDisplay = nil
	self._deleteButton = nil

	-- Janitor for cleanup
	self._janitor = client.Janitor.new()

	self:Initialize()

	return self
end

function MassDeleteUI:Initialize()
	-- Set up event listeners
	self:SetupEventListeners()
end

-- ========================================
-- UI CREATION
-- ========================================

function MassDeleteUI:CreateWindow()
	-- Find or create ScreenGui
	self._screenGui = self._playerGui:FindFirstChild("MassDeleteUI")
	if self._screenGui then
		self._screenGui:Destroy()
	end
	
	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "MassDeleteUI"
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.Parent = self._playerGui

	-- Create dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.Parent = self._screenGui

	-- Create main window
	local window = Instance.new("Frame")
	window.Name = "Window"
	window.Size = UDim2.new(0, WINDOW_SIZE.X, 0, WINDOW_SIZE.Y)
	window.Position = UDim2.new(0.5, -WINDOW_SIZE.X/2, 0.5, -WINDOW_SIZE.Y/2)
	window.BackgroundColor3 = Config.COLORS.Background
	window.BorderSizePixel = 0
	window.Parent = self._screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = window

	self._window = window

	-- Create header
	self:CreateHeader(window)

	-- Create filter section
	self:CreateFilterSection(window)

	-- Create two panels
	self:CreatePanels(window)

	-- Create bottom section
	self:CreateBottomSection(window)

	-- Load pets
	self:RefreshAvailablePets()
end

function MassDeleteUI:CreateHeader(parent)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Config.COLORS.Primary
	header.BorderSizePixel = 0
	header.Parent = parent

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Fix bottom corners
	local headerFix = Instance.new("Frame")
	headerFix.Size = UDim2.new(1, 0, 0, 12)
	headerFix.Position = UDim2.new(0, 0, 1, -12)
	headerFix.BackgroundColor3 = Config.COLORS.Primary
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Text = "Mass Delete Pets - Wizard"
	title.Font = Config.FONTS.Display or Enum.Font.SourceSansBold
	title.TextSize = 20
	title.TextColor3 = Config.COLORS.White
	title.BackgroundTransparency = 1
	title.Parent = header

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0.5, -20)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.SourceSansBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Config.COLORS.White
	closeBtn.BackgroundTransparency = 1
	closeBtn.Parent = header

	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)
end

function MassDeleteUI:CreateFilterSection(parent)
	local filterFrame = Instance.new("Frame")
	filterFrame.Name = "FilterSection"
	filterFrame.Size = UDim2.new(1, -20, 0, 80)
	filterFrame.Position = UDim2.new(0, 10, 0, 60)
	filterFrame.BackgroundTransparency = 1
	filterFrame.Parent = parent

	-- Rarity pills (row 1)
	local rarityRow = Instance.new("Frame")
	rarityRow.Size = UDim2.new(1, 0, 0, 35)
	rarityRow.BackgroundTransparency = 1
	rarityRow.Parent = filterFrame

	local xOffset = 0
	for _, rarity in ipairs({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
		local pill = Instance.new("TextButton")
		pill.Size = UDim2.new(0, 90, 0, 30)
		pill.Position = UDim2.new(0, xOffset, 0, 0)
		pill.Text = rarity
		pill.Font = Enum.Font.SourceSans
		pill.TextSize = 14
		pill.TextColor3 = RARITY_COLORS[rarity]
		pill.BackgroundColor3 = Config.COLORS.Surface
		pill.BorderSizePixel = 2
		pill.BorderColor3 = Config.COLORS.Border
		pill.Parent = rarityRow

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 15)
		pillCorner.Parent = pill

		pill.MouseButton1Click:Connect(function()
			if self._filters.rarities[rarity] then
				self._filters.rarities[rarity] = nil
				pill.BackgroundColor3 = Config.COLORS.Surface
				pill.BorderColor3 = Config.COLORS.Border
			else
				self._filters.rarities[rarity] = true
				pill.BackgroundColor3 = RARITY_COLORS[rarity]
				pill.BorderColor3 = RARITY_COLORS[rarity]
			end
			self:RefreshAvailablePets()
		end)

		xOffset = xOffset + 100
	end

	-- Controls row (row 2)
	local controlsRow = Instance.new("Frame")
	controlsRow.Size = UDim2.new(1, 0, 0, 35)
	controlsRow.Position = UDim2.new(0, 0, 0, 40)
	controlsRow.BackgroundTransparency = 1
	controlsRow.Parent = filterFrame

	-- Duplicates only toggle
	local dupToggle = Instance.new("TextButton")
	dupToggle.Size = UDim2.new(0, 150, 0, 30)
	dupToggle.Position = UDim2.new(0, 0, 0, 0)
	dupToggle.Text = "🔁 Duplicates Only"
	dupToggle.Font = Enum.Font.SourceSans
	dupToggle.TextSize = 14
	dupToggle.TextColor3 = Config.COLORS.Text
	dupToggle.BackgroundColor3 = Config.COLORS.Surface
	dupToggle.BorderSizePixel = 2
	dupToggle.BorderColor3 = Config.COLORS.Border
	dupToggle.Parent = controlsRow

	local dupCorner = Instance.new("UICorner")
	dupCorner.CornerRadius = UDim.new(0, 6)
	dupCorner.Parent = dupToggle

	dupToggle.MouseButton1Click:Connect(function()
		self._filters.duplicatesOnly = not self._filters.duplicatesOnly
		if self._filters.duplicatesOnly then
			dupToggle.BackgroundColor3 = Config.COLORS.Primary
			dupToggle.TextColor3 = Config.COLORS.White
		else
			dupToggle.BackgroundColor3 = Config.COLORS.Surface
			dupToggle.TextColor3 = Config.COLORS.Text
		end
		self:RefreshAvailablePets()
	end)

	-- Search bar
	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(0, 200, 0, 30)
	searchBox.Position = UDim2.new(0, 160, 0, 0)
	searchBox.PlaceholderText = "🔍 Search pets..."
	searchBox.Text = ""
	searchBox.Font = Enum.Font.SourceSans
	searchBox.TextSize = 14
	searchBox.TextColor3 = Config.COLORS.Text
	searchBox.BackgroundColor3 = Config.COLORS.Surface
	searchBox.BorderSizePixel = 0
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = controlsRow

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 6)
	searchCorner.Parent = searchBox

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self._filters.searchText = searchBox.Text:lower()
		self:RefreshAvailablePets()
	end)
end

function MassDeleteUI:CreatePanels(parent)
	local panelContainer = Instance.new("Frame")
	panelContainer.Name = "PanelContainer"
	panelContainer.Size = UDim2.new(1, -20, 1, -230)
	panelContainer.Position = UDim2.new(0, 10, 0, 150)
	panelContainer.BackgroundTransparency = 1
	panelContainer.Parent = parent

	-- Left Panel: Your Pets
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0.48, 0, 1, 0)
	leftPanel.BackgroundColor3 = Config.COLORS.Surface
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = panelContainer

	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 8)
	leftCorner.Parent = leftPanel

	-- Left panel header
	local leftHeader = Instance.new("TextLabel")
	leftHeader.Size = UDim2.new(1, 0, 0, 40)
	leftHeader.Text = "Your Pets"
	leftHeader.Font = Enum.Font.SourceSansBold
	leftHeader.TextSize = 16
	leftHeader.TextColor3 = Config.COLORS.Text
	leftHeader.BackgroundColor3 = Config.COLORS.Card
	leftHeader.BorderSizePixel = 0
	leftHeader.Parent = leftPanel

	local leftHeaderCorner = Instance.new("UICorner")
	leftHeaderCorner.CornerRadius = UDim.new(0, 8)
	leftHeaderCorner.Parent = leftHeader

	-- Left grid
	local leftScroll = Instance.new("ScrollingFrame")
	leftScroll.Name = "LeftGrid"
	leftScroll.Size = UDim2.new(1, -10, 1, -50)
	leftScroll.Position = UDim2.new(0, 5, 0, 45)
	leftScroll.BackgroundTransparency = 1
	leftScroll.BorderSizePixel = 0
	leftScroll.ScrollBarThickness = 6
	leftScroll.Parent = leftPanel

	local leftGrid = Instance.new("UIGridLayout")
	leftGrid.CellSize = CARD_SIZE
	leftGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	leftGrid.SortOrder = Enum.SortOrder.LayoutOrder
	leftGrid.Parent = leftScroll

	self._leftPanel = leftPanel
	self._leftGrid = leftScroll

	-- Center controls
	local centerControls = Instance.new("Frame")
	centerControls.Name = "CenterControls"
	centerControls.Size = UDim2.new(0, 60, 1, 0)
	centerControls.Position = UDim2.new(0.48, 5, 0, 0)
	centerControls.BackgroundTransparency = 1
	centerControls.Parent = panelContainer

	-- Move all button
	local moveAllBtn = Instance.new("TextButton")
	moveAllBtn.Size = UDim2.new(1, 0, 0, 40)
	moveAllBtn.Position = UDim2.new(0, 0, 0.5, -60)
	moveAllBtn.Text = ">>"
	moveAllBtn.Font = Enum.Font.SourceSansBold
	moveAllBtn.TextSize = 20
	moveAllBtn.TextColor3 = Config.COLORS.White
	moveAllBtn.BackgroundColor3 = Config.COLORS.Primary
	moveAllBtn.BorderSizePixel = 0
	moveAllBtn.Parent = centerControls

	local moveAllCorner = Instance.new("UICorner")
	moveAllCorner.CornerRadius = UDim.new(0, 8)
	moveAllCorner.Parent = moveAllBtn

	-- Keep one checkbox
	local keepOneCheck = Instance.new("Frame")
	keepOneCheck.Size = UDim2.new(1, 0, 0, 30)
	keepOneCheck.Position = UDim2.new(0, 0, 0.5, -15)
	keepOneCheck.BackgroundTransparency = 1
	keepOneCheck.Parent = centerControls

	local checkbox = Instance.new("TextButton")
	checkbox.Size = UDim2.new(0, 20, 0, 20)
	checkbox.Position = UDim2.new(0, 5, 0, 5)
	checkbox.Text = ""
	checkbox.BackgroundColor3 = Config.COLORS.Surface
	checkbox.BorderSizePixel = 2
	checkbox.BorderColor3 = Config.COLORS.Border
	checkbox.Parent = keepOneCheck

	local checkCorner = Instance.new("UICorner")
	checkCorner.CornerRadius = UDim.new(0, 4)
	checkCorner.Parent = checkbox

	local checkLabel = Instance.new("TextLabel")
	checkLabel.Size = UDim2.new(1, -30, 1, 0)
	checkLabel.Position = UDim2.new(0, 30, 0, 0)
	checkLabel.Text = "Keep\nbest"
	checkLabel.Font = Enum.Font.SourceSans
	checkLabel.TextSize = 11
	checkLabel.TextColor3 = Config.COLORS.TextSecondary
	checkLabel.BackgroundTransparency = 1
	checkLabel.TextWrapped = true
	checkLabel.Parent = keepOneCheck

	checkbox.MouseButton1Click:Connect(function()
		self._filters.keepBest = not self._filters.keepBest
		if self._filters.keepBest then
			checkbox.Text = "✓"
			checkbox.TextColor3 = Config.COLORS.Success
		else
			checkbox.Text = ""
		end
	end)

	-- Set initial state
	if self._filters.keepBest then
		checkbox.Text = "✓"
		checkbox.TextColor3 = Config.COLORS.Success
	end

	moveAllBtn.MouseButton1Click:Connect(function()
		self:MoveAllFiltered()
	end)

	-- Clear all button
	local clearAllBtn = Instance.new("TextButton")
	clearAllBtn.Size = UDim2.new(1, 0, 0, 40)
	clearAllBtn.Position = UDim2.new(0, 0, 0.5, 20)
	clearAllBtn.Text = "<<"
	clearAllBtn.Font = Enum.Font.SourceSansBold
	clearAllBtn.TextSize = 20
	clearAllBtn.TextColor3 = Config.COLORS.White
	clearAllBtn.BackgroundColor3 = Config.COLORS.Error
	clearAllBtn.BorderSizePixel = 0
	clearAllBtn.Parent = centerControls

	local clearAllCorner = Instance.new("UICorner")
	clearAllCorner.CornerRadius = UDim.new(0, 8)
	clearAllCorner.Parent = clearAllBtn

	clearAllBtn.MouseButton1Click:Connect(function()
		self:ClearSelection()
	end)

	-- Right Panel: Marked for Deletion
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(0.48, 0, 1, 0)
	rightPanel.Position = UDim2.new(0.52, 0, 0, 0)
	rightPanel.BackgroundColor3 = Config.COLORS.Surface
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = panelContainer

	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 8)
	rightCorner.Parent = rightPanel

	-- Right panel header
	local rightHeader = Instance.new("TextLabel")
	rightHeader.Size = UDim2.new(1, 0, 0, 40)
	rightHeader.Text = "Marked for Deletion"
	rightHeader.Font = Enum.Font.SourceSansBold
	rightHeader.TextSize = 16
	rightHeader.TextColor3 = Config.COLORS.Error
	rightHeader.BackgroundColor3 = Color3.new(0.3, 0.1, 0.1)
	rightHeader.BorderSizePixel = 0
	rightHeader.Parent = rightPanel

	local rightHeaderCorner = Instance.new("UICorner")
	rightHeaderCorner.CornerRadius = UDim.new(0, 8)
	rightHeaderCorner.Parent = rightHeader

	-- Right grid
	local rightScroll = Instance.new("ScrollingFrame")
	rightScroll.Name = "RightGrid"
	rightScroll.Size = UDim2.new(1, -10, 1, -140)
	rightScroll.Position = UDim2.new(0, 5, 0, 45)
	rightScroll.BackgroundTransparency = 1
	rightScroll.BorderSizePixel = 0
	rightScroll.ScrollBarThickness = 6
	rightScroll.Parent = rightPanel

	local rightGrid = Instance.new("UIGridLayout")
	rightGrid.CellSize = CARD_SIZE
	rightGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	rightGrid.SortOrder = Enum.SortOrder.LayoutOrder
	rightGrid.Parent = rightScroll

	self._rightPanel = rightPanel
	self._rightGrid = rightScroll

	-- Resource summary in right panel
	local summaryFrame = Instance.new("Frame")
	summaryFrame.Name = "Summary"
	summaryFrame.Size = UDim2.new(1, -10, 0, 80)
	summaryFrame.Position = UDim2.new(0, 5, 1, -85)
	summaryFrame.BackgroundColor3 = Config.COLORS.Card
	summaryFrame.BorderSizePixel = 0
	summaryFrame.Parent = rightPanel

	local summaryCorner = Instance.new("UICorner")
	summaryCorner.CornerRadius = UDim.new(0, 8)
	summaryCorner.Parent = summaryFrame

	local totalLabel = Instance.new("TextLabel")
	totalLabel.Name = "TotalLabel"
	totalLabel.Size = UDim2.new(1, -10, 0, 25)
	totalLabel.Position = UDim2.new(0, 5, 0, 5)
	totalLabel.Text = "Total Pets: 0"
	totalLabel.Font = Enum.Font.SourceSansBold
	totalLabel.TextSize = 16
	totalLabel.TextColor3 = Config.COLORS.Text
	totalLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalLabel.BackgroundTransparency = 1
	totalLabel.Parent = summaryFrame

	local resourceLabel = Instance.new("TextLabel")
	resourceLabel.Name = "ResourceLabel"
	resourceLabel.Size = UDim2.new(1, -10, 0, 20)
	resourceLabel.Position = UDim2.new(0, 5, 0, 30)
	resourceLabel.Text = "Resources Back: 0 Coins, 0 Dust"
	resourceLabel.Font = Enum.Font.SourceSans
	resourceLabel.TextSize = 14
	resourceLabel.TextColor3 = Config.COLORS.Success
	resourceLabel.TextXAlignment = Enum.TextXAlignment.Left
	resourceLabel.BackgroundTransparency = 1
	resourceLabel.Parent = summaryFrame

	local warningLabel = Instance.new("TextLabel")
	warningLabel.Name = "WarningLabel"
	warningLabel.Size = UDim2.new(1, -10, 0, 20)
	warningLabel.Position = UDim2.new(0, 5, 0, 55)
	warningLabel.Text = "⚠️ WARNING: High-value pets selected!"
	warningLabel.Font = Enum.Font.SourceSansBold
	warningLabel.TextSize = 12
	warningLabel.TextColor3 = Config.COLORS.Error
	warningLabel.TextXAlignment = Enum.TextXAlignment.Left
	warningLabel.BackgroundTransparency = 1
	warningLabel.Visible = false
	warningLabel.Parent = summaryFrame

	self._resourceDisplay = summaryFrame
end

function MassDeleteUI:CreateBottomSection(parent)
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, 0, 0, 60)
	bottomBar.Position = UDim2.new(0, 0, 1, -60)
	bottomBar.BackgroundColor3 = Config.COLORS.Surface
	bottomBar.BorderSizePixel = 0
	bottomBar.Parent = parent

	-- Delete button
	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0, 200, 0, 40)
	deleteBtn.Position = UDim2.new(1, -220, 0.5, -20)
	deleteBtn.Text = "Delete Pets"
	deleteBtn.Font = Enum.Font.SourceSansBold
	deleteBtn.TextSize = 18
	deleteBtn.TextColor3 = Config.COLORS.White
	deleteBtn.BackgroundColor3 = Config.COLORS.Error
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Parent = bottomBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = deleteBtn

	deleteBtn.MouseButton1Click:Connect(function()
		self:ShowConfirmation()
	end)

	self._deleteButton = deleteBtn
end

-- ========================================
-- PET CARD CREATION
-- ========================================

function MassDeleteUI:CreatePetCard(pet, isRightPanel)
	local card = Instance.new("Frame")
	card.Name = "PetCard_" .. pet.uniqueId
	card.BackgroundColor3 = Config.COLORS.Card or Color3.fromRGB(255, 255, 255)
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	-- Red tint for right panel
	if isRightPanel then
		local redOverlay = Instance.new("Frame")
		redOverlay.Name = "RedOverlay"
		redOverlay.Size = UDim2.new(1, 0, 1, 0)
		redOverlay.BackgroundColor3 = Config.COLORS.Error
		redOverlay.BackgroundTransparency = 0.85
		redOverlay.Parent = card

		local overlayCorner = Instance.new("UICorner")
		overlayCorner.CornerRadius = UDim.new(0, 6)
		overlayCorner.Parent = redOverlay
	end

	-- Pet image placeholder
	local petImage = Instance.new("Frame")
	petImage.Name = "PetImage"
	petImage.Size = UDim2.new(1, -10, 1, -25)
	petImage.Position = UDim2.new(0, 5, 0, 5)
	petImage.BackgroundColor3 = Config.COLORS.Surface or Color3.fromRGB(240, 240, 240)
	petImage.BorderSizePixel = 0
	petImage.Parent = card

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -4, 0, 20)
	nameLabel.Position = UDim2.new(0, 2, 1, -22)
	nameLabel.Text = pet.name or "Pet"
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 11
	nameLabel.TextColor3 = RARITY_COLORS[pet.rarity] or Config.COLORS.Text
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Level badge
	local levelBadge = Instance.new("Frame")
	levelBadge.Size = UDim2.new(0, 25, 0, 16)
	levelBadge.Position = UDim2.new(1, -28, 0, 3)
	levelBadge.BackgroundColor3 = Config.COLORS.Primary
	levelBadge.BorderSizePixel = 0
	levelBadge.Parent = card

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 4)
	badgeCorner.Parent = levelBadge

	local levelText = Instance.new("TextLabel")
	levelText.Size = UDim2.new(1, 0, 1, 0)
	levelText.Text = tostring(pet.level or 1)
	levelText.Font = Enum.Font.SourceSansBold
	levelText.TextSize = 10
	levelText.TextColor3 = Config.COLORS.White
	levelText.BackgroundTransparency = 1
	levelText.Parent = levelBadge

	-- Click handler
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = card

	button.MouseButton1Click:Connect(function()
		if isRightPanel then
			self:MovePetToLeft(pet, card)
		else
			self:MovePetToRight(pet, card)
		end
	end)

	return card
end

-- ========================================
-- PET MOVEMENT
-- ========================================

function MassDeleteUI:MovePetToRight(pet, oldCard)
	-- Add to selected
	self._selectedPets[pet.uniqueId] = pet
	
	-- Remove from available
	self._availablePets[pet.uniqueId] = nil
	
	-- Animate card movement
	self:AnimateCardTransfer(oldCard, self._rightGrid, true)
	
	-- Update displays
	self:UpdateResourceCalculation()
	self:UpdateDeleteButton()
	
	-- Play sound
	self._soundSystem:PlayUISound("Click")
end

function MassDeleteUI:MovePetToLeft(pet, oldCard)
	-- Remove from selected
	self._selectedPets[pet.uniqueId] = nil
	
	-- Add back to available
	self._availablePets[pet.uniqueId] = pet
	
	-- Animate card movement
	self:AnimateCardTransfer(oldCard, self._leftGrid, false)
	
	-- Update displays
	self:UpdateResourceCalculation()
	self:UpdateDeleteButton()
	
	-- Play sound
	self._soundSystem:PlayUISound("Click")
end

function MassDeleteUI:AnimateCardTransfer(oldCard, targetGrid, toRight)
	-- Get positions
	local startPos = oldCard.AbsolutePosition
	local screenGui = self._screenGui
	
	-- Create flying card
	local flyingCard = oldCard:Clone()
	flyingCard.Parent = screenGui
	flyingCard.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
	flyingCard.Size = UDim2.new(0, oldCard.AbsoluteSize.X, 0, oldCard.AbsoluteSize.Y)
	
	-- Remove old card
	oldCard:Destroy()
	
	-- Calculate target position (center of target panel)
	local targetPanel = toRight and self._rightPanel or self._leftPanel
	local targetCenter = targetPanel.AbsolutePosition + targetPanel.AbsoluteSize/2
	
	-- Animate to target
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = self._tweenService:Create(flyingCard, tweenInfo, {
		Position = UDim2.new(0, targetCenter.X - flyingCard.AbsoluteSize.X/2, 
		                     0, targetCenter.Y - flyingCard.AbsoluteSize.Y/2),
		Size = UDim2.new(0, 0, 0, 0),
		Rotation = toRight and 15 or -15
	})
	
	tween:Play()
	tween.Completed:Connect(function()
		flyingCard:Destroy()
		-- Refresh the target grid
		if toRight then
			self:RefreshSelectedPets()
		else
			self:RefreshAvailablePets()
		end
	end)
end

function MassDeleteUI:MoveAllFiltered()
	local toMove = {}
	
	-- Collect all visible pets in left panel
	for uniqueId, pet in pairs(self._availablePets) do
		-- Check for duplicates if keepBest is enabled
		if self._filters.keepBest and self._filters.duplicatesOnly then
			local duplicates = self:GetDuplicatesOf(pet)
			if #duplicates > 1 then
				-- Sort by level and keep the best
				table.sort(duplicates, function(a, b)
					return (a.level or 1) > (b.level or 1)
				end)
				-- Skip the best one
				for i = 2, #duplicates do
					if duplicates[i].uniqueId == uniqueId then
						table.insert(toMove, pet)
						break
					end
				end
			end
		else
			table.insert(toMove, pet)
		end
	end
	
	-- Move all at once
	for _, pet in ipairs(toMove) do
		self._selectedPets[pet.uniqueId] = pet
		self._availablePets[pet.uniqueId] = nil
	end
	
	-- Refresh both panels
	self:RefreshAvailablePets()
	self:RefreshSelectedPets()
	self:UpdateResourceCalculation()
	self:UpdateDeleteButton()
	
	-- Play sound
	self._soundSystem:PlayUISound("Whoosh")
end

function MassDeleteUI:ClearSelection()
	-- Move all back
	for uniqueId, pet in pairs(self._selectedPets) do
		self._availablePets[uniqueId] = pet
	end
	self._selectedPets = {}
	
	-- Refresh both panels
	self:RefreshAvailablePets()
	self:RefreshSelectedPets()
	self:UpdateResourceCalculation()
	self:UpdateDeleteButton()
	
	-- Play sound
	self._soundSystem:PlayUISound("Whoosh")
end

-- ========================================
-- DATA MANAGEMENT
-- ========================================

function MassDeleteUI:RefreshAvailablePets()
	-- Clear grid
	for _, child in ipairs(self._leftGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get player data
	local playerData = self._dataCache:Get("playerData")
	if not playerData or not playerData.pets then
		return
	end

	-- Filter pets
	local filtered = {}
	for uniqueId, pet in pairs(playerData.pets) do
		if not pet.equipped and not self._selectedPets[uniqueId] then
			local include = true
			
			-- Rarity filter
			if next(self._filters.rarities) and not self._filters.rarities[pet.rarity] then
				include = false
			end
			
			-- Duplicates filter
			if self._filters.duplicatesOnly then
				local duplicates = self:GetDuplicatesOf(pet)
				if #duplicates <= 1 then
					include = false
				end
			end
			
			-- Search filter
			if self._filters.searchText ~= "" then
				local petName = (pet.name or ""):lower()
				if not petName:find(self._filters.searchText, 1, true) then
					include = false
				end
			end
			
			if include then
				self._availablePets[uniqueId] = pet
				table.insert(filtered, pet)
			else
				self._availablePets[uniqueId] = nil
			end
		end
	end

	-- Sort by rarity and level
	table.sort(filtered, function(a, b)
		if a.rarity ~= b.rarity then
			local rarityOrder = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6}
			return (rarityOrder[a.rarity] or 1) < (rarityOrder[b.rarity] or 1)
		end
		return (a.level or 1) < (b.level or 1)
	end)

	-- Create cards
	for _, pet in ipairs(filtered) do
		local card = self:CreatePetCard(pet, false)
		card.Parent = self._leftGrid
	end
end

function MassDeleteUI:RefreshSelectedPets()
	-- Clear grid
	for _, child in ipairs(self._rightGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create cards for selected pets
	local sorted = {}
	for _, pet in pairs(self._selectedPets) do
		table.insert(sorted, pet)
	end

	-- Sort by rarity (highest first for visibility)
	table.sort(sorted, function(a, b)
		if a.rarity ~= b.rarity then
			local rarityOrder = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6}
			return (rarityOrder[a.rarity] or 1) > (rarityOrder[b.rarity] or 1)
		end
		return (a.level or 1) > (b.level or 1)
	end)

	-- Create cards
	for _, pet in ipairs(sorted) do
		local card = self:CreatePetCard(pet, true)
		card.Parent = self._rightGrid
	end
end

function MassDeleteUI:GetDuplicatesOf(targetPet)
	local playerData = self._dataCache:Get("playerData")
	if not playerData or not playerData.pets then
		return {}
	end

	local duplicates = {}
	for uniqueId, pet in pairs(playerData.pets) do
		if pet.petId == targetPet.petId and not pet.equipped then
			table.insert(duplicates, pet)
		end
	end

	return duplicates
end

function MassDeleteUI:UpdateResourceCalculation()
	self._totalCoins = 0
	self._totalDust = 0
	local count = 0
	local hasHighValue = false

	for _, pet in pairs(self._selectedPets) do
		count = count + 1
		local values = RARITY_VALUES[pet.rarity] or RARITY_VALUES.Common
		local levelMultiplier = 1 + ((pet.level or 1) - 1) * 0.1
		
		self._totalCoins = self._totalCoins + math.floor(values.coins * levelMultiplier)
		self._totalDust = self._totalDust + math.floor(values.dust * levelMultiplier)
		
		if pet.rarity == "Epic" or pet.rarity == "Legendary" or pet.rarity == "Mythic" then
			hasHighValue = true
		end
	end

	-- Update display
	local totalLabel = self._resourceDisplay:FindFirstChild("TotalLabel")
	local resourceLabel = self._resourceDisplay:FindFirstChild("ResourceLabel")
	local warningLabel = self._resourceDisplay:FindFirstChild("WarningLabel")

	if totalLabel then
		totalLabel.Text = "Total Pets: " .. count
	end

	if resourceLabel then
		resourceLabel.Text = string.format("Resources Back: %s Coins, %s Dust",
			self._utilities:FormatNumber(self._totalCoins),
			self._utilities:FormatNumber(self._totalDust)
		)
	end

	if warningLabel then
		warningLabel.Visible = hasHighValue
	end
end

function MassDeleteUI:UpdateDeleteButton()
	local count = 0
	for _ in pairs(self._selectedPets) do
		count = count + 1
	end

	if self._deleteButton then
		self._deleteButton.Text = count > 0 and ("Delete " .. count .. " Pets") or "Delete Pets"
		self._deleteButton.BackgroundColor3 = count > 0 and Config.COLORS.Error or Config.COLORS.Secondary
	end
end

-- ========================================
-- CONFIRMATION
-- ========================================

function MassDeleteUI:ShowConfirmation()
	local count = 0
	for _ in pairs(self._selectedPets) do
		count = count + 1
	end

	if count == 0 then
		self._notificationSystem:Show({
			title = "No Selection",
			message = "Please select at least one pet to delete.",
			type = "warning"
		})
		return
	end

	-- Create confirmation popup
	local confirmOverlay = Instance.new("Frame")
	confirmOverlay.Name = "ConfirmOverlay"
	confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
	confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	confirmOverlay.BackgroundTransparency = 0.5
	confirmOverlay.ZIndex = 10
	confirmOverlay.Parent = self._screenGui

	local confirmDialog = Instance.new("Frame")
	confirmDialog.Size = UDim2.new(0, 400, 0, 250)
	confirmDialog.Position = UDim2.new(0.5, -200, 0.5, -125)
	confirmDialog.BackgroundColor3 = Config.COLORS.Background
	confirmDialog.BorderSizePixel = 0
	confirmDialog.ZIndex = 11
	confirmDialog.Parent = confirmOverlay

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 12)
	dialogCorner.Parent = confirmDialog

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.Text = "CONFIRM DELETION"
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 24
	title.TextColor3 = Config.COLORS.Error
	title.BackgroundTransparency = 1
	title.Parent = confirmDialog

	-- Message
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -40, 0, 80)
	message.Position = UDim2.new(0, 20, 0, 70)
	message.Text = string.format("You are about to permanently delete %d pets.\n\nYou will receive:\n%s Coins\n%s Pet Dust",
		count,
		self._utilities:FormatNumber(self._totalCoins),
		self._utilities:FormatNumber(self._totalDust)
	)
	message.Font = Enum.Font.SourceSans
	message.TextSize = 16
	message.TextColor3 = Config.COLORS.Text
	message.BackgroundTransparency = 1
	message.TextWrapped = true
	message.Parent = confirmDialog

	-- Buttons
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 40)
	cancelBtn.Position = UDim2.new(0, 40, 1, -60)
	cancelBtn.Text = "Cancel"
	cancelBtn.Font = Enum.Font.SourceSans
	cancelBtn.TextSize = 16
	cancelBtn.TextColor3 = Config.COLORS.White
	cancelBtn.BackgroundColor3 = Config.COLORS.Secondary
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = confirmDialog

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size = UDim2.new(0, 140, 0, 40)
	confirmBtn.Position = UDim2.new(1, -180, 1, -60)
	confirmBtn.Text = "Delete (3)"
	confirmBtn.Font = Enum.Font.SourceSansBold
	confirmBtn.TextSize = 16
	confirmBtn.TextColor3 = Config.COLORS.White
	confirmBtn.BackgroundColor3 = Config.COLORS.Secondary
	confirmBtn.BorderSizePixel = 0
	confirmBtn.Parent = confirmDialog

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmBtn

	-- Cancel handler
	cancelBtn.MouseButton1Click:Connect(function()
		confirmOverlay:Destroy()
	end)

	-- Countdown
	local countdown = 3
	confirmBtn.Text = "Delete (" .. countdown .. ")"
	
	local countdownConnection
	countdownConnection = game:GetService("RunService").Heartbeat:Connect(function()
		countdown = countdown - (1/60)
		if countdown <= 0 then
			countdownConnection:Disconnect()
			confirmBtn.Text = "DELETE NOW"
			confirmBtn.BackgroundColor3 = Config.COLORS.Error
			
			-- Enable delete
			confirmBtn.MouseButton1Click:Connect(function()
				confirmOverlay:Destroy()
				self:ExecuteDelete()
			end)
		else
			confirmBtn.Text = "Delete (" .. math.ceil(countdown) .. ")"
		end
	end)
end

function MassDeleteUI:ExecuteDelete()
	local petIds = {}
	for uniqueId in pairs(self._selectedPets) do
		table.insert(petIds, uniqueId)
	end

	-- Use InvokeServer for RemoteFunctions
	local result = self._remoteManager:InvokeServer("BatchDeletePets", {
		petIds = petIds
	})
	
	if result and result.success then
		-- Animate resource collection
		self:AnimateResourceCollection()
		
		self._notificationSystem:Show({
			title = "Pets Deleted",
			message = string.format("Successfully deleted %d pets!\nReceived %s coins and %s dust!",
				result.deletedCount or #petIds,
				self._utilities:FormatNumber(result.coinsReceived or 0),
				self._utilities:FormatNumber(result.dustReceived or 0)
			),
			type = "success",
			duration = 4
		})
		
		-- Clear selection and refresh
		self._selectedPets = {}
		self:RefreshAvailablePets()
		self:RefreshSelectedPets()
		self:UpdateResourceCalculation()
		self:UpdateDeleteButton()
		
		-- Fire event
		self._eventBus:Fire("PetsDeleted", {count = result.deletedCount})
		
		-- Close after animation
		task.wait(1)
		self:Close()
	else
		self._notificationSystem:Show({
			title = "Delete Failed",
			message = result and result.error or "Failed to delete pets",
			type = "error"
		})
	end
end

function MassDeleteUI:AnimateResourceCollection()
	-- Get all cards in right panel
	local cards = {}
	for _, child in ipairs(self._rightGrid:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("PetCard_") then
			table.insert(cards, child)
		end
	end

	-- Animate cards shrinking and flying to resource display
	local targetPos = self._resourceDisplay.AbsolutePosition + self._resourceDisplay.AbsoluteSize/2
	
	for i, card in ipairs(cards) do
		task.spawn(function()
			task.wait(i * 0.05) -- Stagger
			
			local startPos = card.AbsolutePosition
			local flyingCard = card:Clone()
			flyingCard.Parent = self._screenGui
			flyingCard.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
			flyingCard.Size = UDim2.new(0, card.AbsoluteSize.X, 0, card.AbsoluteSize.Y)
			
			card:Destroy()
			
			-- Animate to resource display
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			local tween = self._tweenService:Create(flyingCard, tweenInfo, {
				Position = UDim2.new(0, targetPos.X, 0, targetPos.Y),
				Size = UDim2.new(0, 0, 0, 0),
				Rotation = 360
			})
			
			tween:Play()
			tween.Completed:Connect(function()
				flyingCard:Destroy()
			end)
		end)
	end
	
	-- Play collection sound
	self._soundSystem:PlayUISound("CoinCollect")
end

-- ========================================
-- LIFECYCLE
-- ========================================

function MassDeleteUI:Open()
	if not self._screenGui then
		self:CreateWindow()
	end
	
	if self._screenGui then
		self._screenGui.Enabled = true
		self:RefreshAvailablePets()
		self:RefreshSelectedPets()
		self:UpdateResourceCalculation()
		self:UpdateDeleteButton()
	end
end

function MassDeleteUI:Close()
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
		self._window = nil
		self._leftPanel = nil
		self._rightPanel = nil
		self._leftGrid = nil
		self._rightGrid = nil
		self._resourceDisplay = nil
		self._deleteButton = nil
		self._availablePets = {}
		self._selectedPets = {}
	end
end

function MassDeleteUI:SetupEventListeners()
	-- Listen for toggle event
	self._janitor:Add(self._eventBus:On("ToggleMassDelete", function()
		if self._screenGui and self._screenGui.Enabled then
			self:Close()
		else
			self:Open()
		end
	end))

	-- Listen for data updates
	self._janitor:Add(self._eventBus:On("PlayerDataUpdated", function()
		if self._screenGui and self._screenGui.Enabled then
			self:RefreshAvailablePets()
			self:UpdateResourceCalculation()
		end
	end))
end

function MassDeleteUI:Destroy()
	self:Close()
	self._janitor:Destroy()
end

return MassDeleteUI