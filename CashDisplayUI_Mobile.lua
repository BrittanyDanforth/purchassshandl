--[[
    Cute Pastel Cash Display UI - MOBILE OPTIMIZED VERSION
    - Much smaller size
    - Better positioning for mobile
    - Out of the way of controls
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Local Player objects
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clean up any old UI first
if playerGui:FindFirstChild("CuteCashDisplay") then
	playerGui.CuteCashDisplay:Destroy()
end

-- =================================================================================
-- CONFIGURATION
-- =================================================================================
local ANIMATE_CHANGES = true
local CURRENCY_SYMBOL = "$"
local POLL_RATE = 1.0
local MIN_ANIMATE_DIFF = 10
local ICON_IMAGE_ID = "rbxassetid://80120083525360"

-- Pastel palette
local COLORS = {
	panel       = Color3.fromRGB(245, 235, 255),
	accent      = Color3.fromRGB(255, 200, 221),
	textDark    = Color3.fromRGB(60, 50, 70),
	positive    = Color3.fromRGB(120, 255, 150),
	negative    = Color3.fromRGB(255, 120, 120),
	shadow      = Color3.fromRGB(220, 210, 230),
	border      = Color3.fromRGB(230, 220, 240),
}

-- =================================================================================
-- UI CREATION - SMALLER SIZES!
-- =================================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CuteCashDisplay"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 50
screenGui.Parent = playerGui

-- Shadow container (MUCH SMALLER)
local shadowFrame = Instance.new("Frame")
shadowFrame.Name = "Shadow"
shadowFrame.AnchorPoint = Vector2.new(1, 1)
-- Position: More to the right, higher up to avoid mobile buttons
shadowFrame.Position = UDim2.new(1, -15, 1, -180)  -- Higher up!
shadowFrame.Size = UDim2.new(0, 200, 0, 60)  -- Much smaller!
shadowFrame.BackgroundColor3 = COLORS.shadow
shadowFrame.BackgroundTransparency = 0.8  -- More transparent
shadowFrame.BorderSizePixel = 0
shadowFrame.Parent = screenGui

local shadowCorner = Instance.new("UICorner", shadowFrame)
shadowCorner.CornerRadius = UDim.new(0, 16)  -- Smaller radius

-- Main panel (SMALLER)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "CashPanel"
mainPanel.Size = UDim2.new(1, -4, 1, -4)
mainPanel.BackgroundColor3 = COLORS.panel
mainPanel.BackgroundTransparency = 0.5  -- More see-through
mainPanel.BorderSizePixel = 0
mainPanel.Parent = shadowFrame

local panelCorner = Instance.new("UICorner", mainPanel)
panelCorner.CornerRadius = UDim.new(0, 14)

-- Gradient & Stroke (thinner)
local gradient = Instance.new("UIGradient", mainPanel)
gradient.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(245,240,255))
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new(0.4)

local stroke = Instance.new("UIStroke", mainPanel)
stroke.Color = COLORS.border
stroke.Transparency = 0.4
stroke.Thickness = 1.5  -- Thinner stroke
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Icon container (TINY)
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.Size = UDim2.new(0, 40, 0, 40)  -- Much smaller icon
iconContainer.Position = UDim2.new(0, 10, 0.5, 0)
iconContainer.AnchorPoint = Vector2.new(0, 0.5)
iconContainer.BackgroundColor3 = COLORS.accent
iconContainer.BackgroundTransparency = 0.2
iconContainer.BorderSizePixel = 0
iconContainer.Parent = mainPanel

local iconCorner = Instance.new("UICorner", iconContainer)
iconCorner.CornerRadius = UDim.new(1, 0)

-- Icon Image
local iconLabel = Instance.new("ImageLabel")
iconLabel.Size = UDim2.new(0.75, 0, 0.75, 0)
iconLabel.Position = UDim2.new(0.125, 0, 0.125, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Image = ICON_IMAGE_ID
iconLabel.ScaleType = Enum.ScaleType.Fit
iconLabel.Parent = iconContainer

-- Text container (adjusted for smaller size)
local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Size = UDim2.new(1, -60, 1, -10)
textContainer.Position = UDim2.new(0, 55, 0, 5)
textContainer.BackgroundTransparency = 1
textContainer.Parent = mainPanel

-- Remove title label - just show the amount for space saving
-- Amount Label (smaller text)
local cashAmount = Instance.new("TextLabel")
cashAmount.Name = "Amount"
cashAmount.Size = UDim2.new(1, -5, 1, -10)
cashAmount.Position = UDim2.new(0, 0, 0.5, 0)
cashAmount.AnchorPoint = Vector2.new(0, 0.5)
cashAmount.BackgroundTransparency = 1
cashAmount.Text = CURRENCY_SYMBOL .. "0"
cashAmount.TextColor3 = COLORS.textDark
cashAmount.Font = Enum.Font.GothamBold
cashAmount.TextScaled = true
cashAmount.TextXAlignment = Enum.TextXAlignment.Left
cashAmount.Parent = textContainer

-- Text size constraint to prevent it from being too big
local textSizeConstraint = Instance.new("UITextSizeConstraint")
textSizeConstraint.MaxTextSize = 24  -- Max text size
textSizeConstraint.MinTextSize = 14  -- Min text size
textSizeConstraint.Parent = cashAmount

local amountStroke = Instance.new("UIStroke", cashAmount)
amountStroke.Color = Color3.fromRGB(255, 255, 255)
amountStroke.Transparency = 0.5
amountStroke.Thickness = 1

-- Change Indicator (smaller, positioned better)
local changeIndicator = Instance.new("TextLabel")
changeIndicator.Name = "ChangeIndicator"
changeIndicator.Size = UDim2.new(0.5, 0, 0, 14)
changeIndicator.Position = UDim2.new(1, -5, 0, -5)
changeIndicator.AnchorPoint = Vector2.new(1, 0)
changeIndicator.BackgroundTransparency = 1
changeIndicator.Text = ""
changeIndicator.Font = Enum.Font.Gotham
changeIndicator.TextScaled = true
changeIndicator.TextXAlignment = Enum.TextXAlignment.Right
changeIndicator.TextTransparency = 1
changeIndicator.Parent = textContainer

local changeConstraint = Instance.new("UITextSizeConstraint")
changeConstraint.MaxTextSize = 12
changeConstraint.Parent = changeIndicator

local changeStroke = Instance.new("UIStroke", changeIndicator)
changeStroke.Thickness = 0.5

-- =================================================================================
-- LOGIC & ANIMATIONS (adjusted for smaller size)
-- =================================================================================
local currentCash = 0
local displayedCash = 0
local animating = false

local function formatNumber(num)
	num = math.floor(num)
	-- Use shorter format for mobile
	if num >= 1e9 then return string.format("%.1fB", num / 1e9)
	elseif num >= 1e6 then return string.format("%.1fM", num / 1e6)
	elseif num >= 1e3 then return string.format("%.1fK", num / 1e3)
	else return tostring(num) end  -- No commas for space saving
end

local function animateCashChange(oldValue, newValue)
	local diff = newValue - oldValue
	if diff == 0 then return end

	local positive = diff > 0

	-- Smaller, subtler animations
	changeIndicator.Text = (positive and "+" or "") .. formatNumber(math.abs(diff))
	changeIndicator.TextColor3 = positive and COLORS.positive or COLORS.negative
	changeIndicator.TextTransparency = 0
	changeIndicator.Position = UDim2.new(1, -5, 0, -3)
	
	TweenService:Create(changeIndicator, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -5, 0, -16), 
		TextTransparency = 1
	}):Play()

	-- Smaller icon bounce
	local originalSize = iconContainer.Size
	TweenService:Create(iconContainer, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSize + UDim2.fromOffset(4, 4)
	}):Play()
	
	task.wait(0.1)
	TweenService:Create(iconContainer, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
		Size = originalSize
	}):Play()

	-- Subtle border glow
	TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Color = positive and COLORS.positive or COLORS.negative, 
		Thickness = 2, 
		Transparency = 0.2
	}):Play()
	
	task.wait(0.2)
	TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Color = COLORS.border, 
		Thickness = 1.5, 
		Transparency = 0.4
	}):Play()

	-- Update number
	if ANIMATE_CHANGES and math.abs(diff) >= MIN_ANIMATE_DIFF then
		animating = true
		local start = tick()
		local duration = 0.4  -- Faster animation
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local t = math.min((tick() - start)/duration, 1)
			local ease = 1 - (1 - t) * (1 - t)
			displayedCash = oldValue + diff * ease
			cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
			if t >= 1 then
				connection:Disconnect()
				animating = false
			end
		end)
	else
		cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(newValue)
	end
end

-- =================================================================================
-- DATA HANDLING
-- =================================================================================
local remotesFolder = ReplicatedStorage:WaitForChild("CashSystemRemotes")
local cashUpdateEvent = remotesFolder:WaitForChild("CashUpdated")

local function applyCashUpdate(newCash)
	newCash = tonumber(newCash)
	if newCash and newCash ~= currentCash then
		animateCashChange(currentCash, newCash)
		currentCash = newCash
	end
end

cashUpdateEvent.OnClientEvent:Connect(applyCashUpdate)

-- Get initial value
local leaderstats = player:WaitForChild("leaderstats")
local cashStat = leaderstats:WaitForChild("Cash")
currentCash = cashStat.Value
cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(currentCash)

-- Responsive sizing - but keep it small!
local function optimizeForDevice()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local isMobile = viewportSize.X < 800 or viewportSize.Y < 600

	if isMobile then
		-- Even smaller for mobile
		shadowFrame.Size = UDim2.new(0, 180, 0, 55)
		shadowFrame.Position = UDim2.new(1, -12, 1, -200)  -- Higher up for mobile
		iconContainer.Size = UDim2.new(0, 35, 0, 35)
		textSizeConstraint.MaxTextSize = 20
	else
		-- Still small for desktop
		shadowFrame.Size = UDim2.new(0, 200, 0, 60)
		shadowFrame.Position = UDim2.new(1, -15, 1, -180)
		iconContainer.Size = UDim2.new(0, 40, 0, 40)
		textSizeConstraint.MaxTextSize = 24
	end
end

optimizeForDevice()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(optimizeForDevice)

print("💰 Mobile-Optimized Cash Display loaded!")