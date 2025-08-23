--[[
	Modern Cash Display UI System
	Works seamlessly with UnifiedLeaderboard
	Mobile & PC friendly with animations
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local ANIMATE_CHANGES = true
local SHOW_CURRENCY_SYMBOL = true
local CURRENCY_SYMBOL = "$"
local UPDATE_RATE = 0.1 -- How often to check for changes

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CashDisplay"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Main frame (positioned top-right, mobile-friendly)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "CashFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 70)
mainFrame.Position = UDim2.new(1, -10, 0, 10) -- Top-right with padding
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Gradient background
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
})
gradient.Rotation = 90
gradient.Parent = mainFrame

-- Add subtle border glow
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0) -- Gold color
stroke.Transparency = 0.7
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Cash icon
local iconFrame = Instance.new("Frame")
iconFrame.Name = "IconFrame"
iconFrame.Size = UDim2.new(0, 50, 0, 50)
iconFrame.Position = UDim2.new(0, 10, 0.5, 0)
iconFrame.AnchorPoint = Vector2.new(0, 0.5)
iconFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
iconFrame.BorderSizePixel = 0
iconFrame.Parent = mainFrame

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 10)
iconCorner.Parent = iconFrame

local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "💰"
iconLabel.TextScaled = true
iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
iconLabel.Font = Enum.Font.SourceSansBold
iconLabel.Parent = iconFrame

-- Cash amount label
local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashAmount"
cashLabel.Size = UDim2.new(1, -70, 0, 30)
cashLabel.Position = UDim2.new(0, 70, 0.5, 0)
cashLabel.AnchorPoint = Vector2.new(0, 0.5)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "$0"
cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cashLabel.TextScaled = true
cashLabel.Font = Enum.Font.SourceSansBold
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = mainFrame

-- Add text stroke for better readability
local textStroke = Instance.new("UIStroke")
textStroke.Color = Color3.fromRGB(0, 0, 0)
textStroke.Transparency = 0.5
textStroke.Thickness = 2
textStroke.Parent = cashLabel

-- Change indicator (shows +/- amount)
local changeLabel = Instance.new("TextLabel")
changeLabel.Name = "ChangeIndicator"
changeLabel.Size = UDim2.new(1, -70, 0, 20)
changeLabel.Position = UDim2.new(0, 70, 1, -5)
changeLabel.AnchorPoint = Vector2.new(0, 1)
changeLabel.BackgroundTransparency = 1
changeLabel.Text = ""
changeLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
changeLabel.TextScaled = true
changeLabel.Font = Enum.Font.SourceSans
changeLabel.TextXAlignment = Enum.TextXAlignment.Left
changeLabel.TextTransparency = 1
changeLabel.Parent = mainFrame

-- Variables
local currentCash = 0
local displayedCash = 0
local animating = false

-- Format number with commas and abbreviations
local function formatNumber(num)
	if num >= 1000000000000 then
		return string.format("%.2fT", num / 1000000000000)
	elseif num >= 1000000000 then
		return string.format("%.2fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("%.2fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.2fK", num / 1000)
	else
		-- Add commas for numbers under 1000
		local formatted = tostring(math.floor(num))
		return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	end
end

-- Animate cash change
local function animateCashChange(oldValue, newValue)
	local difference = newValue - oldValue
	
	if difference == 0 then return end
	
	-- Show change indicator
	changeLabel.Text = (difference > 0 and "+" or "") .. CURRENCY_SYMBOL .. formatNumber(math.abs(difference))
	changeLabel.TextColor3 = difference > 0 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
	
	-- Animate change indicator
	changeLabel.TextTransparency = 0
	local fadeOut = TweenService:Create(changeLabel, TweenInfo.new(2, Enum.EasingStyle.Quad), {
		TextTransparency = 1,
		Position = UDim2.new(0, 70, 0.5, 0)
	})
	fadeOut:Play()
	
	-- Reset position after fade
	fadeOut.Completed:Connect(function()
		changeLabel.Position = UDim2.new(0, 70, 1, -5)
	end)
	
	-- Pulse effect on main frame
	local pulse = TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Transparency = 0.3,
		Thickness = 4
	})
	pulse:Play()
	
	pulse.Completed:Connect(function()
		local unpulse = TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Transparency = 0.7,
			Thickness = 2
		})
		unpulse:Play()
	end)
	
	-- Animate number counting
	if ANIMATE_CHANGES and math.abs(difference) > 10 then
		animating = true
		local startTime = tick()
		local duration = 0.5
		
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			local progress = math.min(elapsed / duration, 1)
			
			-- Smooth easing
			progress = 1 - (1 - progress) * (1 - progress)
			
			displayedCash = math.floor(oldValue + (difference * progress))
			cashLabel.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
			
			if progress >= 1 then
				connection:Disconnect()
				displayedCash = newValue
				cashLabel.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
				animating = false
			end
		end)
	else
		displayedCash = newValue
		cashLabel.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
	end
end

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("CashUIRemotes", 5)
local getCashRemote = remotes and remotes:WaitForChild("GetPlayerCash", 5)
local cashUpdateRemote = remotes and remotes:WaitForChild("CashUpdated", 5)

-- Get money from server
local function updateCash()
	-- Try RemoteFunction first
	if getCashRemote then
		local success, newCash = pcall(function()
			return getCashRemote:InvokeServer()
		end)
		
		if success and newCash then
			if newCash ~= currentCash then
				animateCashChange(currentCash, newCash)
				currentCash = newCash
			end
			return
		end
	end
	
	-- Fallback: check leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
		if cash then
			local value = tonumber(cash.Value) or 0
			if value ~= currentCash then
				animateCashChange(currentCash, value)
				currentCash = value
			end
		end
	end
end

-- Listen for cash updates from server
if cashUpdateRemote then
	cashUpdateRemote.OnClientEvent:Connect(function(newCash)
		if newCash ~= currentCash then
			animateCashChange(currentCash, newCash)
			currentCash = newCash
		end
	end)
end

-- Mobile optimization: Make UI slightly larger on mobile
local function optimizeForDevice()
	local isSmallScreen = workspace.CurrentCamera.ViewportSize.Y < 600
	
	if isSmallScreen then
		mainFrame.Size = UDim2.new(0, 220, 0, 60)
		cashLabel.TextScaled = true
	end
end

-- Initial setup
optimizeForDevice()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(optimizeForDevice)

-- Start update loop
updateCash()
while true do
	if not animating then
		updateCash()
	end
	wait(UPDATE_RATE)
end