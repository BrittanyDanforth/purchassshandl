--[[
    Module: MassDeleteUI
    Description: Simple mass pet deletion interface
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

local WINDOW_SIZE = Vector2.new(800, 600)
local CARD_SIZE = UDim2.new(0, 100, 0, 120)
local RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(100, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
	Mythic = Color3.fromRGB(255, 100, 100)
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

	-- Dependencies
	self._remoteManager = client.RemoteManager
	self._eventBus = client.EventBus
	self._dataCache = client.DataCache
	self._soundSystem = client.SoundSystem
	self._notificationSystem = client.NotificationSystem
	self._utilities = client.Utilities or Utilities

	-- State
	self._selectedPets = {} -- [uniqueId] = true
	self._petCards = {} -- [uniqueId] = card
	
	-- UI References
	self._screenGui = nil
	self._window = nil
	self._grid = nil
	self._selectedLabel = nil

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

	-- Create pet grid
	self:CreatePetGrid(window)

	-- Create bottom bar
	self:CreateBottomBar(window)

	-- Load pets
	self:RefreshPets()
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
	title.Text = "Mass Delete Pets"
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
	filterFrame.Size = UDim2.new(1, -20, 0, 60)
	filterFrame.Position = UDim2.new(0, 10, 0, 60)
	filterFrame.BackgroundTransparency = 1
	filterFrame.Parent = parent

	-- Quick select buttons
	local selectDupesBtn = Instance.new("TextButton")
	selectDupesBtn.Size = UDim2.new(0, 180, 0, 35)
	selectDupesBtn.Position = UDim2.new(0, 0, 0, 0)
	selectDupesBtn.Text = "Select Duplicates"
	selectDupesBtn.Font = Enum.Font.SourceSans
	selectDupesBtn.TextSize = 14
	selectDupesBtn.TextColor3 = Config.COLORS.White
	selectDupesBtn.BackgroundColor3 = Config.COLORS.Primary
	selectDupesBtn.BorderSizePixel = 0
	selectDupesBtn.Parent = filterFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = selectDupesBtn

	selectDupesBtn.MouseButton1Click:Connect(function()
		self:SelectDuplicates()
	end)

	-- Select common button
	local selectCommonBtn = Instance.new("TextButton")
	selectCommonBtn.Size = UDim2.new(0, 150, 0, 35)
	selectCommonBtn.Position = UDim2.new(0, 190, 0, 0)
	selectCommonBtn.Text = "Select Common"
	selectCommonBtn.Font = Enum.Font.SourceSans
	selectCommonBtn.TextSize = 14
	selectCommonBtn.TextColor3 = Config.COLORS.White
	selectCommonBtn.BackgroundColor3 = Config.COLORS.Secondary
	selectCommonBtn.BorderSizePixel = 0
	selectCommonBtn.Parent = filterFrame

	local btnCorner2 = Instance.new("UICorner")
	btnCorner2.CornerRadius = UDim.new(0, 6)
	btnCorner2.Parent = selectCommonBtn

	selectCommonBtn.MouseButton1Click:Connect(function()
		self:SelectByRarity("Common")
	end)

	-- Clear selection button
	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0, 120, 0, 35)
	clearBtn.Position = UDim2.new(0, 350, 0, 0)
	clearBtn.Text = "Clear All"
	clearBtn.Font = Enum.Font.SourceSans
	clearBtn.TextSize = 14
	clearBtn.TextColor3 = Config.COLORS.White
	clearBtn.BackgroundColor3 = Config.COLORS.Error
	clearBtn.BorderSizePixel = 0
	clearBtn.Parent = filterFrame

	local btnCorner3 = Instance.new("UICorner")
	btnCorner3.CornerRadius = UDim.new(0, 6)
	btnCorner3.Parent = clearBtn

	clearBtn.MouseButton1Click:Connect(function()
		self:ClearSelection()
	end)
end

function MassDeleteUI:CreatePetGrid(parent)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PetGrid"
	scrollFrame.Size = UDim2.new(1, -20, 1, -180)
	scrollFrame.Position = UDim2.new(0, 10, 0, 130)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = parent

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = CARD_SIZE
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = scrollFrame

	self._grid = scrollFrame
end

function MassDeleteUI:CreateBottomBar(parent)
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, 0, 0, 60)
	bottomBar.Position = UDim2.new(0, 0, 1, -60)
	bottomBar.BackgroundColor3 = Config.COLORS.Surface
	bottomBar.BorderSizePixel = 0
	bottomBar.Parent = parent

	-- Selected count label
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Size = UDim2.new(0, 300, 1, 0)
	selectedLabel.Position = UDim2.new(0, 20, 0, 0)
	selectedLabel.Text = "0 pets selected"
	selectedLabel.Font = Enum.Font.SourceSans
	selectedLabel.TextSize = 16
	selectedLabel.TextColor3 = Config.COLORS.Text
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Parent = bottomBar

	self._selectedLabel = selectedLabel

	-- Delete button
	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0, 150, 0, 40)
	deleteBtn.Position = UDim2.new(1, -170, 0.5, -20)
	deleteBtn.Text = "Delete Selected"
	deleteBtn.Font = Enum.Font.SourceSansBold
	deleteBtn.TextSize = 16
	deleteBtn.TextColor3 = Config.COLORS.White
	deleteBtn.BackgroundColor3 = Config.COLORS.Error
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Parent = bottomBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = deleteBtn

	deleteBtn.MouseButton1Click:Connect(function()
		self:ConfirmDelete()
	end)
end

-- ========================================
-- PET CARD CREATION
-- ========================================

function MassDeleteUI:CreatePetCard(pet)
	local card = Instance.new("Frame")
	card.Name = "PetCard_" .. pet.uniqueId
	card.BackgroundColor3 = Config.COLORS.Card or Color3.fromRGB(255, 255, 255)
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	-- Selection overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "SelectionOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Config.COLORS.Error
	overlay.BackgroundTransparency = 0.7
	overlay.Visible = false
	overlay.Parent = card

	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 8)
	overlayCorner.Parent = overlay

	-- Pet image placeholder
	local petImage = Instance.new("Frame")
	petImage.Name = "PetImage"
	petImage.Size = UDim2.new(1, -10, 1, -30)
	petImage.Position = UDim2.new(0, 5, 0, 5)
	petImage.BackgroundColor3 = Config.COLORS.Surface or Color3.fromRGB(240, 240, 240)
	petImage.BorderSizePixel = 0
	petImage.Parent = card

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 1, -25)
	nameLabel.Text = pet.name or "Pet"
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = RARITY_COLORS[pet.rarity] or Config.COLORS.Text
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Click button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = card

	button.MouseButton1Click:Connect(function()
		self:TogglePetSelection(pet.uniqueId)
	end)

	return card
end

-- ========================================
-- SELECTION LOGIC
-- ========================================

function MassDeleteUI:RefreshPets()
	-- Clear existing cards
	for _, child in ipairs(self._grid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	self._petCards = {}

	-- Get player data
	local playerData = self._dataCache:Get("playerData")
	if not playerData or not playerData.pets then
		return
	end

	-- Create cards for unequipped pets
	for uniqueId, pet in pairs(playerData.pets) do
		if not pet.equipped then
			local card = self:CreatePetCard(pet)
			card.Parent = self._grid
			self._petCards[uniqueId] = card
		end
	end

	self:UpdateSelectedCount()
end

function MassDeleteUI:TogglePetSelection(uniqueId)
	if self._selectedPets[uniqueId] then
		self._selectedPets[uniqueId] = nil
	else
		self._selectedPets[uniqueId] = true
	end

	-- Update visual
	local card = self._petCards[uniqueId]
	if card then
		local overlay = card:FindFirstChild("SelectionOverlay")
		if overlay then
			overlay.Visible = self._selectedPets[uniqueId] ~= nil
		end
	end

	self:UpdateSelectedCount()
	self._soundSystem:PlayUISound("Click")
end

function MassDeleteUI:SelectDuplicates()
	local playerData = self._dataCache:Get("playerData")
	if not playerData or not playerData.pets then return end

	-- Group pets by type
	local petsByType = {}
	for uniqueId, pet in pairs(playerData.pets) do
		if not pet.equipped then
			local petId = pet.petId
			if not petsByType[petId] then
				petsByType[petId] = {}
			end
			table.insert(petsByType[petId], {uniqueId = uniqueId, level = pet.level or 1})
		end
	end

	-- Select duplicates (keep highest level)
	self._selectedPets = {}
	for petId, pets in pairs(petsByType) do
		if #pets > 1 then
			-- Sort by level
			table.sort(pets, function(a, b)
				return a.level > b.level
			end)
			
			-- Select all except the best
			for i = 2, #pets do
				self._selectedPets[pets[i].uniqueId] = true
			end
		end
	end

	self:UpdateVisuals()
	self:UpdateSelectedCount()
end

function MassDeleteUI:SelectByRarity(rarity)
	local playerData = self._dataCache:Get("playerData")
	if not playerData or not playerData.pets then return end

	self._selectedPets = {}
	for uniqueId, pet in pairs(playerData.pets) do
		if not pet.equipped and pet.rarity == rarity then
			self._selectedPets[uniqueId] = true
		end
	end

	self:UpdateVisuals()
	self:UpdateSelectedCount()
end

function MassDeleteUI:ClearSelection()
	self._selectedPets = {}
	self:UpdateVisuals()
	self:UpdateSelectedCount()
end

function MassDeleteUI:UpdateVisuals()
	for uniqueId, card in pairs(self._petCards) do
		local overlay = card:FindFirstChild("SelectionOverlay")
		if overlay then
			overlay.Visible = self._selectedPets[uniqueId] ~= nil
		end
	end
end

function MassDeleteUI:UpdateSelectedCount()
	local count = 0
	for _ in pairs(self._selectedPets) do
		count = count + 1
	end
	
	if self._selectedLabel then
		self._selectedLabel.Text = count .. " pets selected"
	end
end

-- ========================================
-- DELETION
-- ========================================

function MassDeleteUI:ConfirmDelete()
	local count = 0
	local petIds = {}
	
	for uniqueId in pairs(self._selectedPets) do
		count = count + 1
		table.insert(petIds, uniqueId)
	end

	if count == 0 then
		self._notificationSystem:Show({
			title = "No Selection",
			message = "Please select at least one pet to delete.",
			type = "warning"
		})
		return
	end

	-- Simple confirmation
	local confirmText = string.format("Delete %d pets? This cannot be undone!", count)
	
	-- Create simple confirmation dialog
	local confirmFrame = Instance.new("Frame")
	confirmFrame.Size = UDim2.new(0, 400, 0, 200)
	confirmFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
	confirmFrame.BackgroundColor3 = Config.COLORS.Background
	confirmFrame.BorderSizePixel = 0
	confirmFrame.ZIndex = 10
	confirmFrame.Parent = self._screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = confirmFrame

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -40, 0, 100)
	text.Position = UDim2.new(0, 20, 0, 20)
	text.Text = confirmText
	text.Font = Enum.Font.SourceSans
	text.TextSize = 18
	text.TextColor3 = Config.COLORS.Text
	text.BackgroundTransparency = 1
	text.TextWrapped = true
	text.Parent = confirmFrame

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 40)
	cancelBtn.Position = UDim2.new(0, 40, 1, -60)
	cancelBtn.Text = "Cancel"
	cancelBtn.Font = Enum.Font.SourceSans
	cancelBtn.TextSize = 16
	cancelBtn.TextColor3 = Config.COLORS.White
	cancelBtn.BackgroundColor3 = Config.COLORS.Secondary
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = confirmFrame

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn

	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0, 120, 0, 40)
	deleteBtn.Position = UDim2.new(1, -160, 1, -60)
	deleteBtn.Text = "Delete"
	deleteBtn.Font = Enum.Font.SourceSansBold
	deleteBtn.TextSize = 16
	deleteBtn.TextColor3 = Config.COLORS.White
	deleteBtn.BackgroundColor3 = Config.COLORS.Error
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Parent = confirmFrame

	local deleteCorner = Instance.new("UICorner")
	deleteCorner.CornerRadius = UDim.new(0, 8)
	deleteCorner.Parent = deleteBtn

	cancelBtn.MouseButton1Click:Connect(function()
		confirmFrame:Destroy()
	end)

	deleteBtn.MouseButton1Click:Connect(function()
		confirmFrame:Destroy()
		self:ExecuteDelete(petIds)
	end)
end

function MassDeleteUI:ExecuteDelete(petIds)
	-- Use InvokeServer instead of FireServer for RemoteFunctions
	local result = self._remoteManager:InvokeServer("BatchDeletePets", {
		petIds = petIds
	})
	
	if result and result.success then
		self._notificationSystem:Show({
			title = "Pets Deleted",
			message = string.format("Successfully deleted %d pets!", result.deletedCount or #petIds),
			type = "success"
		})
		
		-- Clear selection and refresh
		self._selectedPets = {}
		self:RefreshPets()
		
		-- Fire event for other UIs to update
		self._eventBus:Fire("PetsDeleted", {count = result.deletedCount})
		
		-- Close the UI
		self:Close()
	else
		self._notificationSystem:Show({
			title = "Delete Failed",
			message = result and result.error or "Failed to delete pets",
			type = "error"
		})
	end
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
		self:RefreshPets()
	end
end

function MassDeleteUI:Close()
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
		self._window = nil
		self._grid = nil
		self._selectedLabel = nil
		self._petCards = {}
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
			self:RefreshPets()
		end
	end))
end

function MassDeleteUI:Destroy()
	self:Close()
	self._janitor:Destroy()
end

return MassDeleteUI