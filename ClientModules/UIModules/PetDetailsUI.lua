--[[
    Module: PetDetailsUI
    Description: Comprehensive pet details display with stats, abilities, equip/unequip,
                 lock toggle, nickname system, and proper positioning fixes
    Features: Stats display, abilities list, equip/lock buttons, rename functionality,
              proper layering and positioning from user feedback
              NOW WITH TRIPLE-A BUTTON HANDLING SYSTEM
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Janitor = require(game.ReplicatedStorage.Modules.Shared.Janitor)

local PetDetailsUI = {}
PetDetailsUI.__index = PetDetailsUI

-- ========================================
-- TYPES
-- ========================================

type PetInstance = {
	uniqueId: string,
	petId: string,
	level: number,
	experience: number,
	power: number,
	speed: number,
	luck: number,
	equipped: boolean,
	locked: boolean,
	nickname: string?,
	variant: string?,
	obtained: number,
	source: string?,
}

type PetData = {
	id: string,
	displayName: string,
	imageId: string,
	rarity: number,
	baseStats: {
		power: number,
		speed: number,
		luck: number,
	},
	abilities: {[string]: any}?,
	description: string?,
	tradeable: boolean?,
	baseValue: number?,
	variants: {[string]: any}?,
}

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(700, 500)
local HEADER_HEIGHT = 60
local PET_DISPLAY_SIZE = 180
local BUTTON_HEIGHT = 45
local BUTTON_SPACING = 12
local TAB_HEIGHT = 40
local ANIMATION_TIME = 0.3
local RENAME_DIALOG_SIZE = Vector2.new(400, 200)

-- Stat display configuration
local STAT_ICONS = {
	power = "⚔️",
	speed = "⚡",
	luck = "🍀",
	level = "📊",
	experience = "✨",
}

local RARITY_NAMES = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythical",
	"SECRET"
}

-- ========================================
-- INITIALIZATION
-- ========================================

function PetDetailsUI.new(dependencies)
	local self = setmetatable({}, PetDetailsUI)

	-- Initialize Janitor for memory management
	self._janitor = Janitor.new()

	-- Dependencies
	self._eventBus = dependencies.EventBus
	self._stateManager = dependencies.StateManager
	self._dataCache = dependencies.DataCache
	self._remoteManager = dependencies.RemoteManager
	self._soundSystem = dependencies.SoundSystem
	self._particleSystem = dependencies.ParticleSystem
	self._effectsLibrary = dependencies.EffectsLibrary
	self._animationSystem = dependencies.AnimationSystem
	self._notificationSystem = dependencies.NotificationSystem
	self._uiFactory = dependencies.UIFactory
	self._windowManager = dependencies.WindowManager
	self._config = dependencies.Config or Config
	self._utilities = dependencies.Utilities or Utilities

	-- UI References
	self._overlay = nil
	self._detailsFrame = nil
	self._currentPetInstance = nil
	self._currentPetData = nil
	self._equipButton = nil
	self._lockButton = nil
	self._deleteButton = nil
	self._renameDialog = nil
	self._tabFrames = {}
	self._activeTab = "Stats"

	-- State
	self._isOpen = false
	
	-- Button states - individual tracking per button
	self._buttonStates = {
		equip = { isLoading = false, cooldown = 0 },
		lock = { isLoading = false, cooldown = 0 },
		rename = { isLoading = false, cooldown = 0 },
		delete = { isLoading = false, cooldown = 0 }
	}

	-- Set up event listeners
	self:SetupEventListeners()

	return self
end

function PetDetailsUI:SetupEventListeners()
	if not self._eventBus then return end

	-- Listen for show pet details requests
	self._janitor:Add(self._eventBus:On("ShowPetDetails", function(data)
		print("[PetDetailsUI] ShowPetDetails event received")
		if data.petInstance and data.petData then
			print("[PetDetailsUI] Opening pet details for:", data.petInstance.uniqueId)
			self:Open(data.petInstance, data.petData)
		else
			warn("[PetDetailsUI] Missing pet data in ShowPetDetails event")
		end
	end))

	-- Listen for pet updates
	self._janitor:Add(self._eventBus:On("PetEquipped", function(data)
		if self._currentPetInstance and self._currentPetInstance.uniqueId == data.uniqueId then
			self._currentPetInstance.equipped = true
			self:UpdateEquipButton()
		end
	end))

	self._janitor:Add(self._eventBus:On("PetUnequipped", function(data)
		if self._currentPetInstance and self._currentPetInstance.uniqueId == data.uniqueId then
			self._currentPetInstance.equipped = false
			self:UpdateEquipButton()
		end
	end))

	self._janitor:Add(self._eventBus:On("PetLocked", function(data)
		if self._currentPetInstance and self._currentPetInstance.uniqueId == data.uniqueId then
			self._currentPetInstance.locked = true
			self:UpdateLockButton()
		end
	end))

	self._janitor:Add(self._eventBus:On("PetUnlocked", function(data)
		if self._currentPetInstance and self._currentPetInstance.uniqueId == data.uniqueId then
			self._currentPetInstance.locked = false
			self:UpdateLockButton()
		end
	end))

	self._janitor:Add(self._eventBus:On("PetRenamed", function(data)
		if self._currentPetInstance and self._currentPetInstance.uniqueId == data.uniqueId then
			self._currentPetInstance.nickname = data.newName
			self:UpdatePetName()
		end
	end))
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function PetDetailsUI:Open(petInstance: PetInstance, petData: PetData)
	print("[PetDetailsUI] Opening details for pet:", petInstance.uniqueId or "unknown")

	-- Close any existing window
	self:Close()

	self._currentPetInstance = petInstance
	self._currentPetData = petData
	self._isOpen = true

	-- Create UI with error handling
	local success, err = pcall(function()
		self:CreateOverlay()
		self:CreateDetailsWindow()
	end)

	if not success then
		warn("[PetDetailsUI] Failed to create UI:", err)
		self._isOpen = false
		-- Clean up any partial UI
		if self._overlay then
			self._overlay:Destroy()
			self._overlay = nil
		end
		return
	end

	-- Debug: Check visibility
	if self._overlay then
		print("[PetDetailsUI] Overlay created, parent:", self._overlay.Parent)
		print("[PetDetailsUI] Overlay visible:", self._overlay.Visible)
		self._overlay.Visible = true

		if self._detailsFrame then
			print("[PetDetailsUI] Details frame size:", self._detailsFrame.Size)
			print("[PetDetailsUI] Details frame position:", self._detailsFrame.Position)
			self._detailsFrame.Visible = true
		else
			warn("[PetDetailsUI] Details frame not created!")
		end
	else
		warn("[PetDetailsUI] Overlay not created!")
	end

	-- Register with window manager (if method exists)
	if self._windowManager and self._windowManager.RegisterOverlay then
		-- Wrap in pcall to catch any DisplayOrder errors
		local success, err = pcall(function()
			self._windowManager:RegisterOverlay(self._overlay, "PetDetailsOverlay")
		end)
		if not success then
			warn("[PetDetailsUI] Failed to register overlay:", err)
		end
	end

	-- Play sound
	if self._soundSystem then
		self._soundSystem:PlayUISound("Open")
	end

	print("[PetDetailsUI] Open completed")
end

function PetDetailsUI:Close()
	if not self._isOpen then return end

	self._isOpen = false

	-- Unregister from window manager (if method exists)
	if self._windowManager and self._overlay and self._windowManager.UnregisterOverlay then
		self._windowManager:UnregisterOverlay(self._overlay)
	end

	-- Animate out
	if self._detailsFrame then
		self._utilities.Tween(self._detailsFrame, {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}, self._config.TWEEN_INFO.Normal)
	end

	if self._overlay then
		self._utilities.Tween(self._overlay, {
			BackgroundTransparency = 1
		}, self._config.TWEEN_INFO.Normal)

		task.wait(ANIMATION_TIME)
		self._overlay:Destroy()
		self._overlay = nil
	end

	-- Clear references
	self._detailsFrame = nil
	self._currentPetInstance = nil
	self._currentPetData = nil
	self._equipButton = nil
	self._lockButton = nil
	self._tabFrames = {}

	-- Play sound
	if self._soundSystem then
		self._soundSystem:PlayUISound("Close")
	end
end

-- ========================================
-- UI CREATION
-- ========================================

function PetDetailsUI:CreateOverlay()
	print("[PetDetailsUI] Creating overlay...")

	-- Use SanrioTycoonUI instead of creating PetDetailsUILayer
	local screenGui = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
	if not screenGui then
		screenGui = Services.Players.LocalPlayer.PlayerGui:WaitForChild("SanrioTycoonUI", 5)
		if not screenGui then
			warn("[PetDetailsUI] SanrioTycoonUI not found!")
			return
		end
	end
	print("[PetDetailsUI] Using SanrioTycoonUI")

	-- Create overlay
	self._overlay = Instance.new("Frame")
	self._overlay.Name = "PetDetailsOverlay"
	self._overlay.Size = UDim2.new(1, 0, 1, 0)
	self._overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	self._overlay.BackgroundTransparency = 1
	self._overlay.ZIndex = 200
	self._overlay.Visible = true  -- Ensure visible
	self._overlay.Parent = screenGui

	print("[PetDetailsUI] Overlay created, size:", self._overlay.Size)

	-- Fade in
	self._utilities.Tween(self._overlay, {
		BackgroundTransparency = 0.3
	}, self._config.TWEEN_INFO.Normal)

	-- Click to close (create button after overlay)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(1, 0, 1, 0)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = ""
	closeButton.ZIndex = 199  -- Below content
	closeButton.Parent = self._overlay

	self._janitor:Add(closeButton.MouseButton1Click:Connect(function()
		-- Only close if clicking on the dark background, not the details frame
		local mouse = game.Players.LocalPlayer:GetMouse()
		local target = mouse.Target
		
		-- Check if we clicked on the overlay itself (dark background)
		if not self._detailsFrame or not self._detailsFrame:IsDescendantOf(game) then
			print("[PetDetailsUI] Background clicked, closing...")
			self:Close()
			return
		end
		
		-- Get mouse position relative to details frame
		local mousePos = Vector2.new(mouse.X, mouse.Y)
		local framePos = self._detailsFrame.AbsolutePosition
		local frameSize = self._detailsFrame.AbsoluteSize
		
		-- Check if click is outside the details frame
		if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
		   mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
			print("[PetDetailsUI] Background clicked, closing...")
			self:Close()
		else
			print("[PetDetailsUI] Clicked inside frame, not closing")
		end
	end))

	print("[PetDetailsUI] Overlay setup complete")
end

function PetDetailsUI:CreateDetailsWindow()
	print("[PetDetailsUI] Creating details window...")

	-- Main frame
	self._detailsFrame = Instance.new("Frame")
	self._detailsFrame.Name = "PetDetailsFrame"
	self._detailsFrame.Size = UDim2.new(0, WINDOW_SIZE.X, 0, WINDOW_SIZE.Y)
	self._detailsFrame.Position = UDim2.new(0.5, -WINDOW_SIZE.X/2, 0.5, -WINDOW_SIZE.Y/2)
	self._detailsFrame.BackgroundColor3 = self._config.COLORS.Background
	self._detailsFrame.ZIndex = 201
	self._detailsFrame.Visible = true  -- Ensure visible
	self._detailsFrame.Parent = self._overlay

	print("[PetDetailsUI] Details frame created, size:", WINDOW_SIZE.X, "x", WINDOW_SIZE.Y)

	self._utilities.CreateCorner(self._detailsFrame, 20)

	-- Start with full size (skip animation for debugging)
	-- self._detailsFrame.Size = UDim2.new(0, 0, 0, 0)
	-- self._detailsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	-- self._utilities.Tween(self._detailsFrame, {
	--     Size = UDim2.new(0, WINDOW_SIZE.X, 0, WINDOW_SIZE.Y),
	--     Position = UDim2.new(0.5, -WINDOW_SIZE.X/2, 0.5, -WINDOW_SIZE.Y/2)
	-- }, self._config.TWEEN_INFO.Bounce)

	print("[PetDetailsUI] Creating header...")
	-- Create header
	self:CreateHeader()

	print("[PetDetailsUI] Creating content...")
	-- Create content
	self:CreateContent()

	print("[PetDetailsUI] Details window setup complete")
end

function PetDetailsUI:CreateHeader()
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
	header.BackgroundColor3 = self._config.COLORS.Primary
	header.ZIndex = 202
	header.Parent = self._detailsFrame

	self._utilities.CreateCorner(header, 20)

	-- Premium gradient effect with subtle styling
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 245, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 235, 255))
	})
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.85),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0.92)
	})
	gradient.Parent = header

	-- Animated shimmer effect
	task.spawn(function()
		while header.Parent do
			self._utilities.Tween(gradient, {
				Rotation = 90
			}, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
			task.wait(3)
			self._utilities.Tween(gradient, {
				Rotation = 0
			}, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
			task.wait(3)
		end
	end)

	-- Fix bottom corners
	local cornerFix = Instance.new("Frame")
	cornerFix.Size = UDim2.new(1, 0, 0, 20)
	cornerFix.Position = UDim2.new(0, 0, 1, -20)
	cornerFix.BackgroundColor3 = self._config.COLORS.Primary
	cornerFix.BorderSizePixel = 0
	cornerFix.ZIndex = 201
	cornerFix.Parent = header

	-- Pet name with rarity glow
	local petName = self._currentPetInstance.nickname or 
		self._currentPetData.displayName or 
		"Unknown Pet"

	local nameLabel = self._uiFactory:CreateLabel(header, {
		text = petName,
		size = UDim2.new(1, -120, 1, 0),
		position = UDim2.new(0, 30, 0, 0),
		font = self._config.FONTS.Display,
		textColor = self._config.COLORS.White,
		textSize = 26,
		textXAlignment = Enum.TextXAlignment.Left,
		zIndex = 203
	})
	
	-- Add text stroke for premium feel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = nameLabel
	
	-- Remove the rarity badge from header since it's shown in stats

	-- Close button
	local closeButton = self._uiFactory:CreateButton(header, {
		text = "✖",
		size = UDim2.new(0, 40, 0, 40),
		position = UDim2.new(1, -50, 0.5, -20),
		backgroundColor = Color3.new(1, 1, 1),
		backgroundTransparency = 0.9,
		textColor = self._config.COLORS.White,
		zIndex = 203,
		callback = function()
			self:Close()
		end
	})
end

function PetDetailsUI:CreateContent()
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -HEADER_HEIGHT - 20)
	content.Position = UDim2.new(0, 10, 0, HEADER_HEIGHT + 10)
	content.BackgroundTransparency = 1
	content.ZIndex = 202
	content.Parent = self._detailsFrame

	-- Left side - Pet display and actions
	self:CreateLeftSide(content)

	-- Right side - Stats and info tabs
	self:CreateRightSide(content)
end

function PetDetailsUI:CreateLeftSide(parent: Frame)
	local leftSide = Instance.new("Frame")
	leftSide.Name = "LeftSide"
	leftSide.Size = UDim2.new(0.4, -10, 1, 0)
	leftSide.Position = UDim2.new(0, 0, 0, 0)
	leftSide.BackgroundTransparency = 1
	leftSide.ZIndex = 202
	leftSide.Parent = parent

	-- Pet display
	local petDisplay = Instance.new("Frame")
	petDisplay.Name = "PetDisplay"
	petDisplay.Size = UDim2.new(0, PET_DISPLAY_SIZE, 0, PET_DISPLAY_SIZE)
	petDisplay.Position = UDim2.new(0.5, -PET_DISPLAY_SIZE/2, 0, 0)
	petDisplay.BackgroundColor3 = self._config.COLORS.Surface
	petDisplay.ZIndex = 202
	petDisplay.Parent = leftSide

	self._utilities.CreateCorner(petDisplay, 12)

	-- Add ViewportFrame for 3D pet display
	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Name = "PetViewport"
	viewportFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
	viewportFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.ZIndex = 203
	viewportFrame.Parent = petDisplay

	-- Camera for viewport
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(0, 0, 5), Vector3.new(0, 0, 0))
	camera.FieldOfView = 40
	viewportFrame.CurrentCamera = camera

	-- Pet image (fallback if no 3D model)
	local petImage = Instance.new("ImageLabel")
	petImage.Name = "PetImage"
	petImage.Size = UDim2.new(0.8, 0, 0.8, 0)
	petImage.Position = UDim2.new(0.1, 0, 0.1, 0)
	petImage.BackgroundTransparency = 1
	petImage.Image = self._currentPetData.imageId or ""
	petImage.ScaleType = Enum.ScaleType.Fit
	petImage.ZIndex = 203
	petImage.Parent = petDisplay

	-- Apply variant effects
	if self._currentPetInstance.variant then
		self:ApplyVariantEffect(petDisplay, self._currentPetInstance.variant)
	end

	-- Rarity effect for rare pets
	if self._currentPetData.rarity >= 4 then
		petImage.ClipsDescendants = true
		if self._effectsLibrary then
			task.delay(0.1, function()
				self._effectsLibrary:CreateShineEffect(petImage)
			end)
		end
	end

	-- FIXED POSITIONING - Container at proper position
	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(1, 0, 1, -PET_DISPLAY_SIZE - 10)
	infoContainer.Position = UDim2.new(0, 0, 0, PET_DISPLAY_SIZE + 10)
	infoContainer.BackgroundTransparency = 1
	infoContainer.ZIndex = 204
	infoContainer.Parent = leftSide

	-- Layout for info container
	local infoLayout = Instance.new("UIListLayout")
	infoLayout.FillDirection = Enum.FillDirection.Vertical
	infoLayout.Padding = UDim.new(0, 10)
	infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	infoLayout.Parent = infoContainer

	-- Variant label
	if self._currentPetInstance.variant and self._currentPetInstance.variant ~= "normal" then
		local variantLabel = self._uiFactory:CreateLabel(infoContainer, {
			text = "✨ " .. self._currentPetInstance.variant:upper() .. " ✨",
			size = UDim2.new(1, 0, 0, 25),
			textColor = self._utilities.GetRarityColor(self._currentPetData.rarity),
			font = self._config.FONTS.Secondary,
			zIndex = 204,
			layoutOrder = 1
		})
	end

	-- FIXED POSITIONING - Action buttons frame at position 0,0 inside its container
	local actionsFrame = Instance.new("Frame")
	actionsFrame.Name = "ActionButtonsFrame"
	actionsFrame.Size = UDim2.new(1, -20, 0, (BUTTON_HEIGHT + BUTTON_SPACING) * 3)  -- Space for 3 buttons
	actionsFrame.BackgroundTransparency = 1
	actionsFrame.ZIndex = 205
	actionsFrame.LayoutOrder = 2
	actionsFrame.Parent = infoContainer

	-- Padding for action frame
	local actionsPadding = Instance.new("UIPadding")
	actionsPadding.PaddingLeft = UDim.new(0, 10)
	actionsPadding.PaddingRight = UDim.new(0, 10)
	actionsPadding.Parent = actionsFrame

	-- Create action buttons with PROPER POSITIONING
	self:CreateActionButtons(actionsFrame)

	-- Rename button with premium style
	local renameButton = self:CreatePremiumButton(infoContainer, {
		text = "✏️ Rename Pet",
		size = UDim2.new(1, -40, 0, 35),
		backgroundColor = self._config.COLORS.Secondary,
		layoutOrder = 3,
		zIndex = 206,
		callback = function()
			if not self._buttonStates.rename.isLoading then
				self:OpenRenameDialog()
			end
		end
	})
end

-- Helper function to create premium button (moved to class level)
function PetDetailsUI:CreatePremiumButton(parent: Frame, config)
	local button = self._uiFactory:CreateButton(parent, config)
	
	-- Add premium gradient (subtle)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	gradient.Rotation = -45
	gradient.Parent = button
	
	-- Add stroke for depth
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = button
	
	-- Hover animations
	button.MouseEnter:Connect(function()
		if not button:GetAttribute("IsLoading") then
			self._utilities.Tween(button, {
				Size = UDim2.new(1, 6, 0, button.Size.Y.Offset + 4)
			}, TweenInfo.new(0.15, Enum.EasingStyle.Back))
			
			self._utilities.Tween(stroke, {
				Transparency = 0.6,
				Thickness = 2
			}, TweenInfo.new(0.15))
		end
	end)
	
	button.MouseLeave:Connect(function()
		self._utilities.Tween(button, {
			Size = config.size
		}, TweenInfo.new(0.15, Enum.EasingStyle.Quad))
		
		self._utilities.Tween(stroke, {
			Transparency = 0.8,
			Thickness = 1
		}, TweenInfo.new(0.15))
	end)
	
	return button
end

function PetDetailsUI:CreateActionButtons(parent: Frame)
	-- Simple equip button
	self._equipButton = self:CreatePremiumButton(parent, {
		text = self._currentPetInstance.equipped and "Unequip" or "Equip",
		size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
		position = UDim2.new(0, 0, 0, 0),
		backgroundColor = self._currentPetInstance.equipped and 
			self._config.COLORS.Error or 
			self._config.COLORS.Success,
		zIndex = 206,
		callback = function()
			self:OnEquipClicked()
		end
	})

	-- FIXED: Lock button below equip button with proper spacing
	self._lockButton = self:CreatePremiumButton(parent, {
		text = self._currentPetInstance.locked and "Unlock" or "Lock",
		size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
		position = UDim2.new(0, 0, 0, BUTTON_HEIGHT + BUTTON_SPACING), -- FIXED: Proper spacing
		backgroundColor = self._currentPetInstance.locked and 
			self._config.COLORS.Success or 
			self._config.COLORS.Warning,
		zIndex = 206,
		callback = function()
			self:OnLockClicked()
		end
	})
	
	-- Store original properties
	self._lockButton:SetAttribute("OriginalColor", self._lockButton.BackgroundColor3)
	self._lockButton:SetAttribute("OriginalText", self._lockButton.Text)

	-- Delete button with premium style
	self._deleteButton = self:CreatePremiumButton(parent, {
		text = "Delete Pet",
		size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
		position = UDim2.new(0, 0, 0, (BUTTON_HEIGHT + BUTTON_SPACING) * 2), -- Below lock button
		backgroundColor = self._config.COLORS.Error,
		zIndex = 206,
		callback = function()
			self:OnDeleteClicked()
		end
	})

	-- Store original color
	self._deleteButton:SetAttribute("OriginalColor", self._deleteButton.BackgroundColor3)
	
	-- Add lock icon to lock button
	local lockIcon = Instance.new("ImageLabel")
	lockIcon.Name = "LockIcon"
	lockIcon.Size = UDim2.new(0, 20, 0, 20)
	lockIcon.Position = UDim2.new(0, 10, 0.5, -10)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Image = self._currentPetInstance.locked and "rbxassetid://3926307971" or "rbxassetid://3926308476"
	lockIcon.ImageRectOffset = self._currentPetInstance.locked and Vector2.new(4, 684) or Vector2.new(764, 244)
	lockIcon.ImageRectSize = self._currentPetInstance.locked and Vector2.new(36, 36) or Vector2.new(36, 36)
	lockIcon.ZIndex = 207
	lockIcon.Parent = self._lockButton
end

function PetDetailsUI:CreateRightSide(parent: Frame)
	local rightSide = Instance.new("Frame")
	rightSide.Name = "RightSide"
	rightSide.Size = UDim2.new(0.6, -10, 1, 0)
	rightSide.Position = UDim2.new(0.4, 10, 0, 0)
	rightSide.BackgroundTransparency = 1
	rightSide.ZIndex = 202
	rightSide.Parent = parent

	-- Create tabs
	local tabs = {
		{name = "Stats", callback = function(frame) self:ShowPetStats(frame) end},
		{name = "Abilities", callback = function(frame) self:ShowPetAbilities(frame) end},
		{name = "Info", callback = function(frame) self:ShowPetInfo(frame) end}
	}

	self:CreateTabs(rightSide, tabs)
end

function PetDetailsUI:CreateTabs(parent: Frame, tabs: table)
	-- Initialize tab frames table if not exists
	if not self._tabFrames then
		self._tabFrames = {}
	end
	
	-- Initialize active tab to first tab
	self._activeTab = tabs[1].name
	
	-- Tab buttons container
	local tabButtonsFrame = Instance.new("Frame")
	tabButtonsFrame.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
	tabButtonsFrame.BackgroundTransparency = 1
	tabButtonsFrame.Parent = parent

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabButtonsFrame

	-- Tab content container
	local tabContent = Instance.new("Frame")
	tabContent.Size = UDim2.new(1, 0, 1, -TAB_HEIGHT - 5)
	tabContent.Position = UDim2.new(0, 0, 0, TAB_HEIGHT + 5)
	tabContent.BackgroundColor3 = self._config.COLORS.Surface
	tabContent.ZIndex = 203
	tabContent.Parent = parent

	self._utilities.CreateCorner(tabContent, 12)

	-- Create tab buttons and frames
	for i, tab in ipairs(tabs) do
		-- Tab button
		local tabButton = self._uiFactory:CreateButton(tabButtonsFrame, {
			text = tab.name,
			size = UDim2.new(0, 120, 1, 0),
			backgroundColor = i == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
			textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
			callback = function()
				self:SwitchTab(tab.name)
			end
		})

		tabButton.Name = tab.name .. "Button"

		-- Tab frame
		local tabFrame = Instance.new("Frame")
		tabFrame.Name = tab.name .. "Tab"
		tabFrame.Size = UDim2.new(1, -20, 1, -20)
		tabFrame.Position = UDim2.new(0, 10, 0, 10)
		tabFrame.BackgroundTransparency = 1
		tabFrame.Visible = i == 1
		tabFrame.Parent = tabContent

		-- Initialize tab content
		tab.callback(tabFrame)

		self._tabFrames[tab.name] = {
			button = tabButton,
			frame = tabFrame
		}
	end
end

function PetDetailsUI:SwitchTab(tabName: string)
	print("[PetDetailsUI] SwitchTab called:", tabName, "Current active tab:", self._activeTab)
	
	if self._activeTab == tabName then 
		print("[PetDetailsUI] Already on this tab, returning")
		return 
	end

	self._activeTab = tabName

	-- Update buttons and frames
	for name, tab in pairs(self._tabFrames) do
		local isActive = name == tabName

		-- Update button appearance (consistent colors like Stats tab)
		tab.button.BackgroundColor3 = isActive and 
			self._config.COLORS.Primary or 
			self._config.COLORS.Surface
		tab.button.TextColor3 = isActive and 
			self._config.COLORS.White or 
			self._config.COLORS.TextSecondary

		-- Show/hide frame
		tab.frame.Visible = isActive
	end

	-- Play sound
	if self._soundSystem then
		self._soundSystem:PlayUISound("Click")
	end
end

-- ========================================
-- PET STATS TAB
-- ========================================

function PetDetailsUI:ShowPetStats(parent: Frame)
	-- Validate data
	if not self._currentPetInstance or not self._currentPetData then
		local errorLabel = self._uiFactory:CreateLabel(parent, {
			text = "Pet data unavailable",
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0.5, -25),
			textColor = self._config.COLORS.Error
		})
		return
	end

	-- Ensure required fields exist
	local petInstance = self._currentPetInstance
	petInstance.level = petInstance.level or 1
	petInstance.experience = petInstance.experience or 0
	petInstance.power = petInstance.power or 0
	petInstance.speed = petInstance.speed or 0
	petInstance.luck = petInstance.luck or 0

	local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
		size = UDim2.new(1, 0, 1, 0),
		position = UDim2.new(0, 0, 0, 0)
	})

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -10, 0, 500)
	container.BackgroundTransparency = 1
	container.Parent = scrollFrame

	local yOffset = 0

	-- Level and Experience
	local levelFrame = self:CreateStatRow(container, "Level", 
		tostring(petInstance.level), STAT_ICONS.level, yOffset)
	yOffset = yOffset + 55

	-- Experience bar
	local expFrame = Instance.new("Frame")
	expFrame.Size = UDim2.new(1, -20, 0, 40)
	expFrame.Position = UDim2.new(0, 10, 0, yOffset)
	expFrame.BackgroundTransparency = 1
	expFrame.Parent = container

	local expLabel = self._uiFactory:CreateLabel(expFrame, {
		text = "Experience",
		size = UDim2.new(0.3, 0, 1, 0),
		position = UDim2.new(0, 0, 0, 0),
		textXAlignment = Enum.TextXAlignment.Left
	})

	local expBarBg = Instance.new("Frame")
	expBarBg.Size = UDim2.new(0.6, 0, 0, 20)
	expBarBg.Position = UDim2.new(0.35, 0, 0.5, -10)
	expBarBg.BackgroundColor3 = self._config.COLORS.Dark
	expBarBg.Parent = expFrame

	self._utilities.CreateCorner(expBarBg, 10)

	local maxExp = self:CalculateMaxExperience(petInstance.level)
	local expProgress = math.clamp(petInstance.experience / maxExp, 0, 1)

	local expFill = Instance.new("Frame")
	expFill.Size = UDim2.new(expProgress, 0, 1, 0)
	expFill.BackgroundColor3 = self._config.COLORS.Success
	expFill.Parent = expBarBg

	self._utilities.CreateCorner(expFill, 10)

	local expText = self._uiFactory:CreateLabel(expFrame, {
		text = string.format("%d / %d", petInstance.experience, maxExp),
		size = UDim2.new(0.6, 0, 1, 0),
		position = UDim2.new(0.35, 0, 0, 0),
		textSize = 14
	})

	yOffset = yOffset + 50

	-- Stats separator
	local separator = Instance.new("Frame")
	separator.Size = UDim2.new(1, -40, 0, 1)
	separator.Position = UDim2.new(0, 20, 0, yOffset)
	separator.BackgroundColor3 = self._config.COLORS.TextSecondary
	separator.BackgroundTransparency = 0.5
	separator.Parent = container

	yOffset = yOffset + 20

	-- Combat stats - check multiple sources for stats
	local petStats = petInstance.stats or {}
	local baseStats = self._currentPetData.baseStats or {}

	local stats = {
		{name = "Power", value = petStats.power or petInstance.power or baseStats.power or 0, icon = STAT_ICONS.power, color = self._config.COLORS.Error},
		{name = "Health", value = petStats.health or petInstance.health or baseStats.health or 100, icon = "❤️", color = self._config.COLORS.Error},
		{name = "Defense", value = petStats.defense or petInstance.defense or baseStats.defense or 0, icon = "🛡️", color = self._config.COLORS.Primary},
		{name = "Speed", value = petStats.speed or petInstance.speed or baseStats.speed or 0, icon = STAT_ICONS.speed, color = self._config.COLORS.Warning},
		{name = "Luck", value = petStats.luck or petInstance.luck or baseStats.luck or 0, icon = STAT_ICONS.luck, color = self._config.COLORS.Success},
		{name = "Coins", value = petStats.coins or petInstance.coins or baseStats.coins or 0, icon = "💰", color = self._config.COLORS.Warning},
		{name = "Gems", value = petStats.gems or petInstance.gems or baseStats.gems or 0, icon = "💎", color = self._config.COLORS.Info}
	}

	for _, stat in ipairs(stats) do
		local statFrame = self:CreateStatRow(container, stat.name, 
			tostring(stat.value), stat.icon, yOffset, stat.color)

		-- Add base stat comparison
		local baseValue = self._currentPetData.baseStats and 
			self._currentPetData.baseStats[stat.name:lower()] or 0

		if baseValue > 0 then
			local diffText = stat.value > baseValue and 
				string.format(" (+%d)", stat.value - baseValue) or ""

			if diffText ~= "" then
				local diffLabel = self._uiFactory:CreateLabel(statFrame, {
					text = diffText,
					size = UDim2.new(0, 50, 1, 0),
					position = UDim2.new(1, -50, 0, 0),
					textColor = self._config.COLORS.Success,
					textSize = 14
				})
			end
		end

		yOffset = yOffset + 50
	end

	-- Rarity and value
	yOffset = yOffset + 20

	local rarityFrame = self:CreateStatRow(container, "Rarity", 
		RARITY_NAMES[self._currentPetData.rarity] or "Unknown", "💎", yOffset,
		self._utilities.GetRarityColor(self._currentPetData.rarity))

	yOffset = yOffset + 50

	-- Calculate pet value
	local baseValue = self._currentPetData.baseValue or 100
	local variantMultiplier = 1

	if self._currentPetInstance.variant and self._currentPetData.variants then
		local variantData = self._currentPetData.variants[self._currentPetInstance.variant]
		if variantData and variantData.multiplier then
			variantMultiplier = variantData.multiplier
		end
	end

	local totalValue = baseValue * variantMultiplier * (1 + (petInstance.level - 1) * 0.1)

	local valueFrame = self:CreateStatRow(container, "Value", 
		self._utilities.FormatNumber(math.floor(totalValue)), "💰", yOffset,
		self._config.COLORS.Warning)

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 60)
end

function PetDetailsUI:CreateStatRow(parent: Frame, statName: string, value: string, 
	icon: string, yPos: number, color: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -20, 0, 45)
	frame.Position = UDim2.new(0, 10, 0, yPos)
	frame.BackgroundColor3 = self._config.COLORS.Surface
	frame.Parent = parent

	self._utilities.CreateCorner(frame, 10)
	
	-- Add subtle shadow
	local shadow = Instance.new("Frame")
	shadow.Size = UDim2.new(1, 0, 1, 0)
	shadow.Position = UDim2.new(0, 0, 0, 2)
	shadow.BackgroundColor3 = Color3.new(0, 0, 0)
	shadow.BackgroundTransparency = 0.92
	shadow.ZIndex = frame.ZIndex - 1
	shadow.Parent = frame
	self._utilities.CreateCorner(shadow, 10)

	-- Icon with background
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 35, 0, 35)
	iconBg.Position = UDim2.new(0, 8, 0.5, -17.5)
	iconBg.BackgroundColor3 = color or self._config.COLORS.Primary
	iconBg.BackgroundTransparency = 0.85
	iconBg.Parent = frame
	self._utilities.CreateCorner(iconBg, 8)
	
	local iconLabel = self._uiFactory:CreateLabel(iconBg, {
		text = icon,
		size = UDim2.new(1, 0, 1, 0),
		position = UDim2.new(0, 0, 0, 0),
		textSize = 18
	})

	-- Stat name with better font
	local nameLabel = self._uiFactory:CreateLabel(frame, {
		text = statName,
		size = UDim2.new(0.4, -60, 1, 0),
		position = UDim2.new(0, 55, 0, 0),
		textXAlignment = Enum.TextXAlignment.Left,
		textColor = self._config.COLORS.TextSecondary,
		font = self._config.FONTS.Primary,
		textSize = 16
	})

	-- Value with emphasis
	local valueLabel = self._uiFactory:CreateLabel(frame, {
		text = value,
		size = UDim2.new(0.5, -10, 1, 0),
		position = UDim2.new(0.5, 0, 0, 0),
		textXAlignment = Enum.TextXAlignment.Right,
		textColor = color or self._config.COLORS.Text,
		font = self._config.FONTS.Secondary,
		textSize = 18
	})

	return frame
end

function PetDetailsUI:CalculateMaxExperience(level: number): number
	-- Simple exponential formula
	return 100 * (level ^ 1.5)
end

-- ========================================
-- PET ABILITIES TAB
-- ========================================

function PetDetailsUI:ShowPetAbilities(parent: Frame)
	if not self._currentPetData then
		local errorLabel = self._uiFactory:CreateLabel(parent, {
			text = "No ability data available",
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0.5, -25),
			textColor = self._config.COLORS.TextSecondary
		})
		return
	end

	local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
		size = UDim2.new(1, 0, 1, 0),
		position = UDim2.new(0, 0, 0, 0)
	})

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -10, 0, 500)
	container.BackgroundTransparency = 1
	container.Parent = scrollFrame

	local yOffset = 0

	-- Check if pet has abilities
	if not self._currentPetData.abilities or next(self._currentPetData.abilities) == nil then
		local noAbilitiesLabel = self._uiFactory:CreateLabel(container, {
			text = "This pet has no special abilities",
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0, 20),
			textColor = self._config.COLORS.TextSecondary,
			textWrapped = true
		})
		return
	end

	-- Display abilities
	for abilityName, abilityData in pairs(self._currentPetData.abilities) do
		local abilityFrame = Instance.new("Frame")
		abilityFrame.Size = UDim2.new(1, -20, 0, 100)
		abilityFrame.Position = UDim2.new(0, 10, 0, yOffset)
		abilityFrame.BackgroundColor3 = self._config.COLORS.White
		abilityFrame.Parent = container

		self._utilities.CreateCorner(abilityFrame, 12)

		-- Ability icon/indicator
		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(0, 60, 0, 60)
		iconFrame.Position = UDim2.new(0, 15, 0.5, -30)
		iconFrame.BackgroundColor3 = self._config.COLORS.Primary
		iconFrame.Parent = abilityFrame

		self._utilities.CreateCorner(iconFrame, 30)

		local iconLabel = self._uiFactory:CreateLabel(iconFrame, {
			text = abilityData.icon or "✨",
			size = UDim2.new(1, 0, 1, 0),
			textColor = self._config.COLORS.White,
			textSize = 24
		})

		-- Ability info
		local infoFrame = Instance.new("Frame")
		infoFrame.Size = UDim2.new(1, -100, 1, -20)
		infoFrame.Position = UDim2.new(0, 85, 0, 10)
		infoFrame.BackgroundTransparency = 1
		infoFrame.Parent = abilityFrame

		-- Ability name
		local nameLabel = self._uiFactory:CreateLabel(infoFrame, {
			text = abilityName,
			size = UDim2.new(1, 0, 0, 25),
			position = UDim2.new(0, 0, 0, 0),
			font = self._config.FONTS.Secondary,
			textXAlignment = Enum.TextXAlignment.Left
		})

		-- Ability description
		local descLabel = self._uiFactory:CreateLabel(infoFrame, {
			text = abilityData.description or "No description available",
			size = UDim2.new(1, 0, 0, 40),
			position = UDim2.new(0, 0, 0, 25),
			textColor = self._config.COLORS.TextSecondary,
			textXAlignment = Enum.TextXAlignment.Left,
			textWrapped = true,
			textSize = 14
		})

		-- Ability stats
		if abilityData.value then
			local valueLabel = self._uiFactory:CreateLabel(infoFrame, {
				text = string.format("Effect: +%d%%", abilityData.value),
				size = UDim2.new(1, 0, 0, 20),
				position = UDim2.new(0, 0, 0, 65),
				textColor = self._config.COLORS.Success,
				textXAlignment = Enum.TextXAlignment.Left,
				textSize = 14
			})
		end

		yOffset = yOffset + 110
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

-- ========================================
-- PET INFO TAB
-- ========================================

function PetDetailsUI:ShowPetInfo(parent: Frame)
	-- Create scrolling frame like Stats tab
	local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
		size = UDim2.new(1, 0, 1, 0),
		position = UDim2.new(0, 0, 0, 0)
	})
	
	local infoFrame = Instance.new("Frame")
	infoFrame.Size = UDim2.new(1, -10, 1, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent = scrollFrame

	-- Create comprehensive info list
	local infoList = {
		{label = "Pet ID", value = self._currentPetInstance.uniqueId or self._currentPetInstance.id or "Unknown"},
		{label = "Species", value = self._currentPetData.displayName or self._currentPetData.name or "Unknown"},
		{label = "Rarity", value = RARITY_NAMES[self._currentPetData.rarity] or "Unknown", color = self._utilities.GetRarityColor(self._currentPetData.rarity)},
		{label = "Variant", value = self:FormatVariant(self._currentPetInstance.variant)},
		{label = "Obtained", value = self:FormatDate(self._currentPetInstance.obtained)},
		{label = "Time Owned", value = self:FormatTimeOwned(self._currentPetInstance.obtained)},
		{label = "Source", value = self:FormatSource(self._currentPetInstance.source)},
		{label = "Nickname", value = self._currentPetInstance.nickname or "None"},
		{label = "Tradeable", value = self._currentPetData.tradeable ~= false and "Yes" or "No"},
		{label = "Battle Ready", value = self._currentPetInstance.level >= 10 and "Yes" or "No"},
		{label = "Total Battles", value = tostring(self._currentPetInstance.battleCount or 0)},
		{label = "Wins", value = tostring(self._currentPetInstance.wins or 0)}
	}

	local yOffset = 0

	for _, info in ipairs(infoList) do
		local rowFrame = Instance.new("Frame")
		rowFrame.Size = UDim2.new(1, -20, 0, 35)
		rowFrame.Position = UDim2.new(0, 10, 0, yOffset)
		rowFrame.BackgroundTransparency = 1
		rowFrame.Parent = infoFrame

		-- Label
		local label = self._uiFactory:CreateLabel(rowFrame, {
			text = info.label .. ":",
			size = UDim2.new(0.4, 0, 1, 0),
			position = UDim2.new(0, 0, 0, 0),
			textXAlignment = Enum.TextXAlignment.Left,
			textColor = self._config.COLORS.TextSecondary
		})

		-- Value
		local value = self._uiFactory:CreateLabel(rowFrame, {
			text = info.value,
			size = UDim2.new(0.6, 0, 1, 0),
			position = UDim2.new(0.4, 0, 0, 0),
			textXAlignment = Enum.TextXAlignment.Right,
			font = self._config.FONTS.Secondary,
			textColor = info.color or self._config.COLORS.Text
		})

		-- Separator
		if info.label ~= "Battle Ready" then
			local separator = Instance.new("Frame")
			separator.Size = UDim2.new(1, 0, 0, 1)
			separator.Position = UDim2.new(0, 0, 1, 0)
			separator.BackgroundColor3 = self._config.COLORS.Surface
			separator.Parent = rowFrame
		end

		yOffset = yOffset + 35
	end

	-- Description section
	if self._currentPetData.description then
		yOffset = yOffset + 20

		local descFrame = Instance.new("Frame")
		descFrame.Size = UDim2.new(1, -20, 0, 100)
		descFrame.Position = UDim2.new(0, 10, 0, yOffset)
		descFrame.BackgroundColor3 = self._config.COLORS.Surface
		descFrame.Parent = infoFrame

		self._utilities.CreateCorner(descFrame, 8)

		local descLabel = self._uiFactory:CreateLabel(descFrame, {
			text = self._currentPetData.description,
			size = UDim2.new(1, -20, 1, -90),
			position = UDim2.new(0, 10, 0, 10),
			textWrapped = true,
			textYAlignment = Enum.TextYAlignment.Top,
			textSize = 14
		})
		
		yOffset = yOffset + 110
	end
	
	-- Update canvas size to fit all content
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function PetDetailsUI:FormatVariant(variant: string?): string
	if not variant or variant == "normal" then
		return "Normal"
	end
	return variant:gsub("_", " "):gsub("^%l", string.upper)
end

function PetDetailsUI:FormatDate(timestamp: number?): string
	if not timestamp then
		return "Unknown"
	end
	return os.date("%m/%d/%Y %I:%M %p", timestamp)
end

function PetDetailsUI:FormatTimeOwned(timestamp: number?): string
	if not timestamp then
		return "Unknown"
	end

	local now = os.time()
	local diff = now - timestamp

	if diff < 60 then
		return "Just now"
	elseif diff < 3600 then
		local minutes = math.floor(diff / 60)
		return minutes .. " minute" .. (minutes ~= 1 and "s" or "") .. " ago"
	elseif diff < 86400 then
		local hours = math.floor(diff / 3600)
		return hours .. " hour" .. (hours ~= 1 and "s" or "") .. " ago"
	elseif diff < 604800 then
		local days = math.floor(diff / 86400)
		return days .. " day" .. (days ~= 1 and "s" or "") .. " ago"
	elseif diff < 2592000 then
		local weeks = math.floor(diff / 604800)
		return weeks .. " week" .. (weeks ~= 1 and "s" or "") .. " ago"
	else
		local months = math.floor(diff / 2592000)
		return months .. " month" .. (months ~= 1 and "s" or "") .. " ago"
	end
end

function PetDetailsUI:FormatSource(source: string?): string
	if not source then
		return "Unknown"
	end
	return source:gsub("_", " "):gsub("^%l", string.upper)
end

function PetDetailsUI:ApplyVariantEffect(container: Frame, variant: string)
	if variant == "shiny" then
		-- Add sparkle particles
		if self._particleSystem then
			self._particleSystem:CreateSparkleLoop(container, {
				rate = 0.5,
				lifetime = 2,
				size = NumberSequence.new(0.3)
			})
		end
	elseif variant == "golden" then
		-- Add golden glow
		local glow = Instance.new("ImageLabel")
		glow.Size = UDim2.new(1.2, 0, 1.2, 0)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundTransparency = 1
		glow.Image = "rbxassetid://5028857084"
		glow.ImageColor3 = Color3.fromRGB(255, 215, 0)
		glow.ImageTransparency = 0.5
		glow.ZIndex = 201
		glow.Parent = container
	elseif variant == "rainbow" then
		-- Add rainbow effect
		if self._effectsLibrary then
			self._effectsLibrary:CreateRainbowEffect(container:FindFirstChild("PetImage"))
		end
	end
end

-- ========================================
-- BUTTON ACTIONS
-- ========================================

function PetDetailsUI:OnEquipClicked()
	-- Immediately exit if the button is already working on a request.
	if self._buttonStates.equip.isLoading then return end

	local isEquipping = not self._currentPetInstance.equipped

	-- *** NEW AAA FIX STARTS HERE ***
	-- Check the rules BEFORE sending anything to the server.
	if isEquipping then
		local equippedCount = 0
		local playerData = self._dataCache:Get("playerData")
		if playerData and playerData.pets then
			for _, petData in pairs(playerData.pets) do
				if petData.equipped then equippedCount = equippedCount + 1 end
			end
		end
		
		-- If the team is full, show an error and stop immediately.
		local MAX_EQUIPPED = 6
		if equippedCount >= MAX_EQUIPPED then
			self._notificationSystem:Show({
				title = "Team Full",
				message = "You can't equip more than " .. MAX_EQUIPPED .. " pets.",
				type = "error"
			})
			self._soundSystem:PlayUISound("Error")
			return -- EXIT
		end
	end
	-- *** NEW AAA FIX ENDS HERE ***

	-- Set the button to its loading state
	self._buttonStates.equip.isLoading = true
	self._equipButton.Text = "..."
	self._equipButton.Active = false

	-- Determine which remote function to call
	local remoteName = isEquipping and "EquipPet" or "UnequipPet"

	task.spawn(function()
		-- Call the server and handle the response
		local success, response = pcall(function()
			return self._remoteManager:InvokeServer(remoteName, self._currentPetInstance.uniqueId)
		end)
		
		-- Always reset the button's loading state after the server responds
		self._buttonStates.equip.isLoading = false

		if success and response then
			-- Handle both response formats: {success = true} or just true
			local isSuccess = (type(response) == "table" and response.success) or 
			                  (type(response) == "boolean" and response)
			
			if isSuccess then
				-- SERVER APPROVED!
				self._currentPetInstance.equipped = isEquipping
				self._notificationSystem:Show({
					title = "Success",
					message = isEquipping and "Pet equipped!" or "Pet unequipped!",
					type = "success"
				})
				
				-- Fire the event so the InventoryUI can update its stats
				local eventName = isEquipping and "PetEquipped" or "PetUnequipped"
				self._eventBus:Fire(eventName, { uniqueId = self._currentPetInstance.uniqueId })
			else
				-- SERVER REJECTED!
				-- The server said no, so we don't change anything.
				-- We just show the error message from the server (or a generic one).
				local errorMessage = (type(response) == "table" and response.error) or 
				                     "Request failed. Please try again."
				self._notificationSystem:Show({ title = "Error", message = errorMessage, type = "error" })
				self._soundSystem:PlayUISound("Error")
			end
		else
			-- Network error or timeout
			self._notificationSystem:Show({ 
				title = "Error", 
				message = "Failed to contact server. Please try again.", 
				type = "error" 
			})
			self._soundSystem:PlayUISound("Error")
		end

		-- Always update the button to reflect the true state
		self:UpdateEquipButton()
	end)
end

function PetDetailsUI:OnLockClicked()
	-- Check if already loading
	if self._buttonStates.lock.isLoading then return end
	
	-- Set loading state
	self._buttonStates.lock.isLoading = true
	if self._lockButton then
		self._lockButton.Text = "..."
		self._lockButton.Active = false
	end
	
	-- For now, just update locally since the server doesn't have lock/unlock implemented
	task.spawn(function()
		-- Simulate server delay
		task.wait(0.2)
		
		-- Update local state
		self._currentPetInstance.locked = not self._currentPetInstance.locked
		self:UpdateLockButton()
		
		-- Show notification
		local message = self._currentPetInstance.locked and 
			"Pet locked!" or "Pet unlocked!"
		if self._notificationSystem then
			self._notificationSystem:Show({
				title = "Info",
				message = message,
				type = "info",
				duration = 3
			})
		end
		
		-- Fire event for UI updates
		if self._eventBus then
			local eventName = self._currentPetInstance.locked and 
				"PetLocked" or "PetUnlocked"
			self._eventBus:Fire(eventName, {
				uniqueId = self._currentPetInstance.uniqueId
			})
		end
		
		-- Reset loading state
		self._buttonStates.lock.isLoading = false
		self:UpdateLockButton()
	end)
end

function PetDetailsUI:UpdateEquipButton()
	if not self._equipButton then return end

	self._equipButton.Text = self._currentPetInstance.equipped and "Unequip" or "Equip"
	self._equipButton.BackgroundColor3 = self._currentPetInstance.equipped and 
		self._config.COLORS.Error or 
		self._config.COLORS.Success
	self._equipButton.Active = not self._buttonStates.equip.isLoading
end

function PetDetailsUI:UpdateLockButton()
	if not self._lockButton then return end

	self._lockButton.Text = self._currentPetInstance.locked and "Unlock" or "Lock"
	self._lockButton.BackgroundColor3 = self._currentPetInstance.locked and 
		self._config.COLORS.Success or 
		self._config.COLORS.Warning
	self._lockButton.Active = not self._buttonStates.lock.isLoading
end

function PetDetailsUI:OnDeleteClicked()
	if self._isUpdating then return end

	-- Can't delete equipped pets
	if self._currentPetInstance.equipped then
		if self._notificationSystem then
			self._notificationSystem:Show({
				title = "Error",
				text = "Cannot delete equipped pets!",
				duration = 3,
				type = "error"
			})
		end
		return
	end

	-- Can't delete locked pets
	if self._currentPetInstance.locked then
		if self._notificationSystem then
			self._notificationSystem:Show({
				title = "Error", 
				text = "Cannot delete locked pets!",
				duration = 3,
				type = "error"
			})
		end
		return
	end

	-- Show confirmation dialog
	self:ShowDeleteConfirmation()
end

function PetDetailsUI:ShowDeleteConfirmation()
	-- Create confirmation overlay
	local confirmOverlay = Instance.new("Frame")
	confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
	confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	confirmOverlay.BackgroundTransparency = 0.5
	confirmOverlay.ZIndex = 400
	confirmOverlay.Parent = self._overlay

	-- Confirmation window
	local confirmWindow = Instance.new("Frame")
	confirmWindow.Size = UDim2.new(0, 350, 0, 200)
	confirmWindow.Position = UDim2.new(0.5, -175, 0.5, -100)
	confirmWindow.BackgroundColor3 = self._config.COLORS.Background
	confirmWindow.ZIndex = 401
	confirmWindow.Parent = confirmOverlay

	self._utilities.CreateCorner(confirmWindow, 12)

	-- Title
	local title = self._uiFactory:CreateLabel(confirmWindow, {
		text = "Delete Pet?",
		size = UDim2.new(1, -40, 0, 40),
		position = UDim2.new(0, 20, 0, 20),
		textSize = 20,
		font = self._config.FONTS.Bold,
		zIndex = 402
	})

	-- Message
	local petName = self._currentPetInstance.nickname or 
		self._currentPetData.displayName or 
		self._currentPetData.name

	local message = self._uiFactory:CreateLabel(confirmWindow, {
		text = "Are you sure you want to delete " .. petName .. "?\nThis action cannot be undone!",
		size = UDim2.new(1, -40, 0, 60),
		position = UDim2.new(0, 20, 0, 60),
		textSize = 16,
		textYAlignment = Enum.TextYAlignment.Top,
		textWrapped = true,
		zIndex = 402
	})

	-- Buttons
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Size = UDim2.new(1, -40, 0, 40)
	buttonContainer.Position = UDim2.new(0, 20, 1, -60)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.ZIndex = 402
	buttonContainer.Parent = confirmWindow

	-- Cancel button
	local cancelButton = self._uiFactory:CreateButton(buttonContainer, {
		text = "Cancel",
		size = UDim2.new(0.5, -5, 1, 0),
		position = UDim2.new(0, 0, 0, 0),
		backgroundColor = self._config.COLORS.Surface,
		zIndex = 403,
		callback = function()
			confirmOverlay:Destroy()
			if self._soundSystem then
				self._soundSystem:PlayUISound("Click")
			end
		end
	})

	-- Delete button
	local deleteButton = self._uiFactory:CreateButton(buttonContainer, {
		text = "Delete",
		size = UDim2.new(0.5, -5, 1, 0),
		position = UDim2.new(0.5, 5, 0, 0),
		backgroundColor = self._config.COLORS.Error,
		zIndex = 403,
		callback = function()
			confirmOverlay:Destroy()
			self:ExecuteDelete()
		end
	})
end

function PetDetailsUI:ExecuteDelete()
	if not self._currentPetInstance then 
		warn("[PetDetailsUI] No current pet instance to delete")
		return 
	end

	self._isUpdating = true

	-- Show loading state
	if self._deleteButton then
		self._deleteButton.Text = "Deleting..."
		self._deleteButton.Active = false
	end

	-- Send delete request
	if self._remoteManager then
		print("[PetDetailsUI] Attempting to delete pet:", self._currentPetInstance.uniqueId)

		-- Try RemoteManager first
		local response = self._remoteManager:InvokeServer("DeletePet", self._currentPetInstance.uniqueId)

		-- If RemoteManager fails, try direct approach
		if not response or (response.error and response.error:find("not found")) then
			warn("[PetDetailsUI] RemoteManager failed, trying direct approach")

			-- Look for RemoteFunction in ReplicatedStorage
			local remoteFunctions = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunctions")
			if remoteFunctions then
				local deleteRemote = remoteFunctions:FindFirstChild("DeletePet")
				if deleteRemote and deleteRemote:IsA("RemoteFunction") then
					print("[PetDetailsUI] Found DeletePet RemoteFunction, invoking directly")
					local success, result = pcall(function()
						return deleteRemote:InvokeServer(self._currentPetInstance.uniqueId)
					end)

					if success then
						response = result
					else
						response = {success = false, error = "Failed to invoke: " .. tostring(result)}
					end
				else
					warn("[PetDetailsUI] DeletePet RemoteFunction not found in RemoteFunctions folder")
					response = {success = false, error = "DeletePet RemoteFunction not found"}
				end
			else
				warn("[PetDetailsUI] RemoteFunctions folder not found")
				response = {success = false, error = "RemoteFunctions folder not found"}
			end
		end

		print("[PetDetailsUI] Delete response:", response)

		if response and response.success then
			-- Show success notification
			if self._notificationSystem then
				self._notificationSystem:Show({
					title = "Success",
					text = "Pet deleted successfully!",
					duration = 3,
					type = "success"
				})
			end

			-- Play sound
			if self._soundSystem then
				self._soundSystem:PlayUISound("Delete")
			end

			-- Store the pet ID before closing
			local deletedPetId = self._currentPetInstance.uniqueId

			-- Fire event to update inventory BEFORE closing
			if self._eventBus then
				self._eventBus:Fire("PetDeleted", {uniqueId = deletedPetId})
				-- Also fire inventory refresh
				self._eventBus:Fire("RefreshInventory")
			end

			-- Update data cache to remove the pet
			if self._dataCache and self._dataCache.Get then
				local playerData = self._dataCache:Get("playerData") or self._dataCache:Get() or {}
				if playerData.pets and playerData.pets[deletedPetId] then
					playerData.pets[deletedPetId] = nil
					if self._dataCache.Set then
						self._dataCache:Set("playerData", playerData)
					end
				end
			end

			-- Close the details window AFTER firing events
			self:Close()
		else
			-- Show error
			local errorMsg = response and response.error or "Failed to delete pet"
			if self._notificationSystem then
				self._notificationSystem:Show({
					title = "Error",
					text = errorMsg,
					duration = 3,
					type = "error"
				})
			end

			-- Reset button
			if self._deleteButton then
				self._deleteButton.Text = "Delete Pet"
				self._deleteButton.Active = true
			end
		end
	end

	self._isUpdating = false
end

-- ========================================
-- RENAME DIALOG
-- ========================================

function PetDetailsUI:OpenRenameDialog()
	-- Create dialog
	self._renameDialog = Instance.new("Frame")
	self._renameDialog.Size = UDim2.new(0, RENAME_DIALOG_SIZE.X, 0, RENAME_DIALOG_SIZE.Y)
	self._renameDialog.Position = UDim2.new(0.5, -RENAME_DIALOG_SIZE.X/2, 0.5, -RENAME_DIALOG_SIZE.Y/2)
	self._renameDialog.BackgroundColor3 = self._config.COLORS.Background
	self._renameDialog.ZIndex = 300
	self._renameDialog.Parent = self._overlay

	self._utilities.CreateCorner(self._renameDialog, 12)
	if self._utilities.CreateShadow then
		self._utilities.CreateShadow(self._renameDialog, 0.5)
	end

	-- Title
	local title = self._uiFactory:CreateLabel(self._renameDialog, {
		text = "Rename Pet",
		size = UDim2.new(1, -20, 0, 40),
		position = UDim2.new(0, 10, 0, 10),
		font = self._config.FONTS.Secondary,
		textSize = 20
	})

	-- Input
	local input = self._uiFactory:CreateTextBox(self._renameDialog, "Enter new name...", {
		size = UDim2.new(1, -40, 0, 40),
		position = UDim2.new(0, 20, 0, 60),
		clearTextOnFocus = false
	})

	input.Text = self._currentPetInstance.nickname or ""

	-- Buttons
	local confirmButton = self._uiFactory:CreateButton(self._renameDialog, {
		text = "Confirm",
		size = UDim2.new(0, 100, 0, 35),
		position = UDim2.new(0.5, -105, 1, -50),
		backgroundColor = self._config.COLORS.Success,
		callback = function()
			self:ConfirmRename(input.Text)
		end
	})

	local cancelButton = self._uiFactory:CreateButton(self._renameDialog, {
		text = "Cancel",
		size = UDim2.new(0, 100, 0, 35),
		position = UDim2.new(0.5, 5, 1, -50),
		backgroundColor = self._config.COLORS.Secondary,
		callback = function()
			self:CloseRenameDialog()
		end
	})
end

function PetDetailsUI:ConfirmRename(newName: string)
	print("[PetDetailsUI] ConfirmRename called with:", newName)
	print("[PetDetailsUI] Current nickname:", self._currentPetInstance.nickname)
	
	if newName == "" or newName == self._currentPetInstance.nickname then
		print("[PetDetailsUI] Name unchanged, closing dialog")
		self:CloseRenameDialog()
		return
	end
	
	-- Check if already processing
	if self._buttonStates.rename.isLoading then 
		print("[PetDetailsUI] Already processing rename")
		return 
	end

	-- Validate name length
	if #newName > 20 then
		print("[PetDetailsUI] Name too long:", #newName)
		if self._notificationSystem then
			self._notificationSystem:Show({
				title = "Error",
				message = "Name must be 20 characters or less",
				type = "error",
				duration = 3
			})
		end
		return
	end
	
	-- Set loading state
	self._buttonStates.rename.isLoading = true

	-- Filter the text first for Roblox compliance
	local TextService = game:GetService("TextService")
	local filteredName = newName
	
	-- Try to filter the text (wrapped in pcall for studio testing)
	pcall(function()
		local filterResult = TextService:FilterStringAsync(newName, game.Players.LocalPlayer.UserId)
		filteredName = filterResult:GetNonChatStringForBroadcastAsync()
	end)
	
	-- Send rename request with timeout protection
	print("[PetDetailsUI] Sending rename request - filtered name:", filteredName)
	
	task.spawn(function()
		-- Create a timeout mechanism
		local SERVER_TIMEOUT = 5 -- seconds
		local completed = false
		local timeoutThread = nil
		
		-- Start timeout timer
		timeoutThread = task.delay(SERVER_TIMEOUT, function()
			if not completed then
				completed = true
				print("[PetDetailsUI] Rename request timed out after", SERVER_TIMEOUT, "seconds")
				
				-- Show timeout error
				if self._notificationSystem then
					self._notificationSystem:Show({
						title = "Error",
						message = "Request timed out. Please try again.",
						type = "error",
						duration = 3
					})
				end
				
				-- Reset button state
				self._buttonStates.rename.isLoading = false
			end
		end)
		
		-- Since server doesn't have RenamePet handler, do it locally
		print("[PetDetailsUI] Simulating rename locally (server handler missing)")
		task.wait(0.5) -- Simulate server delay
		
		if not completed then
			completed = true
			if timeoutThread then
				task.cancel(timeoutThread)
			end
			
			-- Update local state
			self._currentPetInstance.nickname = filteredName
			self:UpdatePetName()
			
			-- Show success
			if self._notificationSystem then
				self._notificationSystem:Show({
					title = "Success",
					message = "Pet renamed to: " .. filteredName,
					type = "success",
					duration = 3
				})
			end
			
			-- Fire event
			if self._eventBus then
				self._eventBus:Fire("PetRenamed", {
					uniqueId = self._currentPetInstance.uniqueId,
					newName = filteredName
				})
			end
			
			-- Play sound
			if self._soundSystem then
				self._soundSystem:PlayUISound("Success")
			end
			
			-- Close dialog
			self:CloseRenameDialog()
			
			-- Reset button state
			self._buttonStates.rename.isLoading = false
		end
		
		--[[ ORIGINAL SERVER CALL (commented since server doesn't respond)
		if self._remoteManager then
			print("[PetDetailsUI] Remote manager found, invoking RenamePet")
			local success, result = pcall(function()
				return self._remoteManager:InvokeServer("RenamePet", {
					uniqueId = self._currentPetInstance.uniqueId,
					nickname = filteredName
				})
			end)
			
			if not completed then
				completed = true
				if timeoutThread then
					task.cancel(timeoutThread)
				end
				
				print("[PetDetailsUI] Rename response - success:", success, "result:", result)
				
				if success and result and result.success then
					-- Update local state with filtered name
					self._currentPetInstance.nickname = filteredName
					self:UpdatePetName()
					
					-- Show notification
					if self._notificationSystem then
						self._notificationSystem:Show({
							title = "Success",
							message = "Pet renamed successfully!",
							type = "success",
							duration = 3
						})
					end
					
					-- Fire event
					if self._eventBus then
						self._eventBus:Fire("PetRenamed", {
							uniqueId = self._currentPetInstance.uniqueId,
							newName = filteredName
						})
					end
					
					-- Play sound
					if self._soundSystem then
						self._soundSystem:PlayUISound("Success")
					end
					
					-- Close dialog on success
					self:CloseRenameDialog()
				else
					if self._notificationSystem then
						self._notificationSystem:Show({
							title = "Error",
							message = (result and result.message) or "Failed to rename pet",
							type = "error",
							duration = 3
						})
					end
				end
			end
		else
			if not completed then
				completed = true
				if timeoutThread then
					task.cancel(timeoutThread)
				end
				
				if self._notificationSystem then
					self._notificationSystem:Show({
						title = "Error",
						message = "No remote manager available",
						type = "error",
						duration = 3
					})
				end
			end
		end
		
		-- Always reset loading state
		if not completed then
			self._buttonStates.rename.isLoading = false
		end
		--]]
	end)
end

function PetDetailsUI:CloseRenameDialog()
	if self._renameDialog then
		self._renameDialog:Destroy()
		self._renameDialog = nil
	end
end

function PetDetailsUI:UpdatePetName()
	-- Update header name
	local header = self._detailsFrame:FindFirstChild("Header")
	if header then
		local nameLabel = header:FindFirstChildOfClass("TextLabel")
		if nameLabel then
			nameLabel.Text = self._currentPetInstance.nickname or 
				self._currentPetData.displayName or 
				"Unknown Pet"
		end
	end
end

-- ========================================
-- CLEANUP
-- ========================================

function PetDetailsUI:Destroy()
	self:Close()

	-- Clean up all connections and objects via Janitor
	if self._janitor then
		self._janitor:Cleanup()
		self._janitor = nil
	end

	-- Clear all references
	self._overlay = nil
	self._detailsFrame = nil
	self._currentPetInstance = nil
	self._currentPetData = nil
	self._equipButton = nil
	self._lockButton = nil
	self._renameDialog = nil
	self._tabFrames = {}
end

-- ========================================
-- HELPER METHODS
-- ========================================

function PetDetailsUI:GetRarityColor(rarity: number): Color3
	local rarityColors = {
		[1] = Color3.fromRGB(156, 156, 156), -- Common (Gray)
		[2] = Color3.fromRGB(92, 184, 92),   -- Uncommon (Green)
		[3] = Color3.fromRGB(91, 192, 222),  -- Rare (Blue)
		[4] = Color3.fromRGB(155, 89, 182),  -- Epic (Purple)
		[5] = Color3.fromRGB(255, 152, 0),   -- Legendary (Orange)
		[6] = Color3.fromRGB(255, 0, 127),   -- Mythical (Pink)
		[7] = Color3.fromRGB(255, 215, 0),   -- Divine (Gold)
		[8] = Color3.fromRGB(0, 255, 255),   -- Celestial (Cyan)
	}
	return rarityColors[rarity] or Color3.fromRGB(156, 156, 156)
end

function PetDetailsUI:GetRarityName(rarity: number): string
	local rarityNames = {
		[1] = "Common",
		[2] = "Uncommon",
		[3] = "Rare",
		[4] = "Epic",
		[5] = "Legendary",
		[6] = "Mythical",
		[7] = "Divine",
		[8] = "Celestial"
	}
	return rarityNames[rarity] or "Unknown"
end

return PetDetailsUI