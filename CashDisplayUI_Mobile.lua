--[[
    Cute Pastel Cash Display UI - ULTRA COMPACT VERSION
    - TINY size for mobile
    - Minimal design
    - Completely out of the way
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
-- UI CREATION - ULTRA TINY!
-- =================================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CuteCashDisplay"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 50
screenGui.Parent = playerGui

-- Main container (TINY AF)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "TinyCashDisplay"
mainFrame.AnchorPoint = Vector2.new(1, 0)
-- TOP RIGHT CORNER - completely out of the way
mainFrame.Position = UDim2.new(1, -10, 0, 10)  -- Top right!
mainFrame.Size = UDim2.new(0, 120, 0, 35)  -- SUPER SMALL!
mainFrame.BackgroundColor3 = COLORS.panel
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

-- Simple gradient
local gradient = Instance.new("UIGradient", mainFrame)
gradient.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(245,240,255))
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new(0.5)

-- Thin stroke
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = COLORS.border
stroke.Transparency = 0.6
stroke.Thickness = 1
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Tiny icon
local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 25, 0, 25)  -- TINY icon
icon.Position = UDim2.new(0, 5, 0.5, 0)
icon.AnchorPoint = Vector2.new(0, 0.5)
icon.BackgroundTransparency = 1
icon.Image = ICON_IMAGE_ID
icon.ScaleType = Enum.ScaleType.Fit
icon.Parent = mainFrame

-- Cash amount (just the number)
local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashAmount"
cashLabel.Size = UDim2.new(1, -35, 1, 0)
cashLabel.Position = UDim2.new(0, 30, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "$0"
cashLabel.TextColor3 = COLORS.textDark
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextScaled = true
cashLabel.TextXAlignment = Enum.TextXAlignment.Center
cashLabel.Parent = mainFrame

-- Size constraint
local textConstraint = Instance.new("UITextSizeConstraint")
textConstraint.MaxTextSize = 16  -- Small text
textConstraint.MinTextSize = 12
textConstraint.Parent = cashLabel

-- White outline for readability
local textStroke = Instance.new("UIStroke", cashLabel)
textStroke.Color = Color3.fromRGB(255, 255, 255)
textStroke.Transparency = 0.3
textStroke.Thickness = 1

-- =================================================================================
-- LOGIC - SIMPLIFIED
-- =================================================================================
local currentCash = 0

local function formatNumber(num)
	num = math.floor(num)
	-- Ultra short format
	if num >= 1e9 then return string.format("%.0fB", num / 1e9)
	elseif num >= 1e6 then return string.format("%.0fM", num / 1e6)
	elseif num >= 1e3 then return string.format("%.0fK", num / 1e3)
	else return tostring(num) end
end

local function updateCash(newValue)
	local diff = newValue - currentCash
	currentCash = newValue
	cashLabel.Text = CURRENCY_SYMBOL .. formatNumber(newValue)
	
	-- Mini animation only for changes
	if diff ~= 0 then
		-- Quick color flash
		local positive = diff > 0
		TweenService:Create(stroke, TweenInfo.new(0.2), {
			Color = positive and COLORS.positive or COLORS.negative,
			Thickness = 2
		}):Play()
		
		task.wait(0.2)
		TweenService:Create(stroke, TweenInfo.new(0.3), {
			Color = COLORS.border,
			Thickness = 1
		}):Play()
		
		-- Tiny pulse
		TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			Size = mainFrame.Size + UDim2.fromOffset(5, 2)
		}):Play()
		
		task.wait(0.1)
		TweenService:Create(mainFrame, TweenInfo.new(0.1), {
			Size = UDim2.new(0, 120, 0, 35)
		}):Play()
	end
end

-- =================================================================================
-- DATA HANDLING
-- =================================================================================
local remotesFolder = ReplicatedStorage:WaitForChild("CashUIRemotes")
local cashUpdateEvent = remotesFolder:WaitForChild("CashUpdated")
local getCashRemote = remotesFolder:WaitForChild("GetPlayerCash")

-- Get initial cash value
local success, initialCash = pcall(function()
	return getCashRemote:InvokeServer()
end)
if success and initialCash then
	currentCash = initialCash
	updateDisplay(currentCash)
end

cashUpdateEvent.OnClientEvent:Connect(function(newCash)
	if tonumber(newCash) then
		updateCash(tonumber(newCash))
	end
end)

-- Get initial value
local leaderstats = player:WaitForChild("leaderstats")
local cashStat = leaderstats:WaitForChild("Cash")
currentCash = cashStat.Value
cashLabel.Text = CURRENCY_SYMBOL .. formatNumber(currentCash)

-- Mobile check - make even smaller if needed
local function checkDevice()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local isMobile = viewportSize.X < 800 or viewportSize.Y < 600
	
	if isMobile then
		-- ULTRA TINY for mobile
		mainFrame.Size = UDim2.new(0, 100, 0, 30)
		mainFrame.Position = UDim2.new(1, -8, 0, 8)
		icon.Size = UDim2.new(0, 20, 0, 20)
		textConstraint.MaxTextSize = 14
	else
		-- Still small for PC
		mainFrame.Size = UDim2.new(0, 120, 0, 35)
		mainFrame.Position = UDim2.new(1, -10, 0, 10)
		icon.Size = UDim2.new(0, 25, 0, 25)
		textConstraint.MaxTextSize = 16
	end
end

checkDevice()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(checkDevice)

print("💰 Ultra Compact Cash Display loaded!")