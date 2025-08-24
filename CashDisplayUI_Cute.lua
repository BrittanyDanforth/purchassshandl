--[[
	Cute Pastel Cash Display UI
	Following modern UI/UX best practices for casual games
	Soft pastels, clear hierarchy, gentle animations
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local ANIMATE_CHANGES = true
local CURRENCY_SYMBOL = "$"
local UPDATE_RATE = 0.1

-- PASTEL COLOR PALETTE (High lightness, low saturation)
local COLORS = {
	-- Main pastels
	background = Color3.fromRGB(255, 245, 250), -- Soft pink-white
	panel = Color3.fromRGB(245, 235, 255), -- Lavender white
	accent = Color3.fromRGB(255, 200, 221), -- Pastel pink
	secondary = Color3.fromRGB(200, 230, 255), -- Pastel blue
	
	-- Text colors (high contrast)
	textDark = Color3.fromRGB(80, 70, 90), -- Deep purple-grey
	textLight = Color3.fromRGB(255, 255, 255), -- Pure white
	
	-- Feedback colors
	positive = Color3.fromRGB(180, 255, 200), -- Pastel mint green
	negative = Color3.fromRGB(255, 180, 180), -- Pastel coral
	
	-- Neutrals
	shadow = Color3.fromRGB(220, 210, 230), -- Light shadow
	border = Color3.fromRGB(230, 220, 240), -- Soft border
}

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CuteCashDisplay"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Main container with shadow (positioned bottom-right, above chat)
local shadowFrame = Instance.new("Frame")
shadowFrame.Name = "Shadow"
shadowFrame.Size = UDim2.new(0, 310, 0, 95)
shadowFrame.Position = UDim2.new(1, -25, 1, -140)
shadowFrame.AnchorPoint = Vector2.new(1, 1)
shadowFrame.BackgroundColor3 = COLORS.shadow
shadowFrame.BackgroundTransparency = 0.4
shadowFrame.BorderSizePixel = 0
shadowFrame.ZIndex = 1
shadowFrame.Parent = screenGui

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 24)
shadowCorner.Parent = shadowFrame

-- Main panel
local mainPanel = Instance.new("Frame")
mainPanel.Name = "CashPanel"
mainPanel.Size = UDim2.new(1, -5, 1, -5)
mainPanel.Position = UDim2.new(0, 0, 0, 0)
mainPanel.BackgroundColor3 = COLORS.panel
mainPanel.BorderSizePixel = 0
mainPanel.ZIndex = 2
mainPanel.Parent = shadowFrame

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = mainPanel

-- Soft gradient overlay
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 240, 255))
})
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new(0.7)
gradient.Parent = mainPanel

-- Subtle border stroke
local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.border
stroke.Transparency = 0.5
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainPanel

-- Icon container (circular, left side)
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.Size = UDim2.new(0, 65, 0, 65)
iconContainer.Position = UDim2.new(0, 15, 0.5, 0)
iconContainer.AnchorPoint = Vector2.new(0, 0.5)
iconContainer.BackgroundColor3 = COLORS.accent
iconContainer.BorderSizePixel = 0
iconContainer.ZIndex = 3
iconContainer.Parent = mainPanel

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0) -- Perfect circle
iconCorner.Parent = iconContainer

-- Icon gradient for depth
local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 221))
})
iconGradient.Rotation = -45
iconGradient.Parent = iconContainer

-- Cash icon (using text for simplicity, could be ImageLabel)
local cashIcon = Instance.new("TextLabel")
cashIcon.Size = UDim2.new(1, 0, 1, 0)
cashIcon.BackgroundTransparency = 1
cashIcon.Text = "💰"
cashIcon.TextScaled = true
cashIcon.TextColor3 = COLORS.textLight
cashIcon.Font = Enum.Font.FredokaOne
cashIcon.Parent = iconContainer

-- Text container
local textContainer = Instance.new("Frame")
textContainer.Size = UDim2.new(1, -95, 1, -20)
textContainer.Position = UDim2.new(0, 90, 0, 10)
textContainer.BackgroundTransparency = 1
textContainer.ZIndex = 3
textContainer.Parent = mainPanel

-- "Cash" label (small, above amount)
local cashTitleLabel = Instance.new("TextLabel")
cashTitleLabel.Size = UDim2.new(1, 0, 0, 20)
cashTitleLabel.Position = UDim2.new(0, 0, 0, 5)
cashTitleLabel.BackgroundTransparency = 1
cashTitleLabel.Text = "Cash"
cashTitleLabel.TextColor3 = COLORS.textDark
cashTitleLabel.TextTransparency = 0.3
cashTitleLabel.Font = Enum.Font.Gotham
cashTitleLabel.TextScaled = true
cashTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
cashTitleLabel.Parent = textContainer

-- Cash amount (large, prominent)
local cashAmount = Instance.new("TextLabel")
cashAmount.Name = "Amount"
cashAmount.Size = UDim2.new(1, 0, 0, 35)
cashAmount.Position = UDim2.new(0, 0, 0, 25)
cashAmount.BackgroundTransparency = 1
cashAmount.Text = "$0"
cashAmount.TextColor3 = COLORS.textDark
cashAmount.Font = Enum.Font.GothamBold
cashAmount.TextScaled = true
cashAmount.TextXAlignment = Enum.TextXAlignment.Left
cashAmount.Parent = textContainer

-- Change indicator (appears on changes)
local changeIndicator = Instance.new("TextLabel")
changeIndicator.Name = "ChangeIndicator"
changeIndicator.Size = UDim2.new(0.6, 0, 0, 18)
changeIndicator.Position = UDim2.new(1, -5, 0.5, 0)
changeIndicator.AnchorPoint = Vector2.new(1, 0.5)
changeIndicator.BackgroundTransparency = 1
changeIndicator.Text = ""
changeIndicator.Font = Enum.Font.Gotham
changeIndicator.TextScaled = true
changeIndicator.TextXAlignment = Enum.TextXAlignment.Right
changeIndicator.TextTransparency = 1
changeIndicator.Parent = textContainer

-- Variables
local currentCash = 0
local displayedCash = 0
local animating = false

-- Format with proper grouping
local function formatNumber(num)
	if num >= 1000000000000 then
		return string.format("%.1fT", num / 1000000000000)
	elseif num >= 1000000000 then
		return string.format("%.1fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		-- Add commas
		local formatted = tostring(math.floor(num))
		return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	end
end

-- Smooth, subtle animations
local function animateCashChange(oldValue, newValue)
	local difference = newValue - oldValue
	if difference == 0 then return end
	
	-- Change indicator with gentle fade
	local isPositive = difference > 0
	changeIndicator.Text = (isPositive and "+" or "") .. CURRENCY_SYMBOL .. formatNumber(math.abs(difference))
	changeIndicator.TextColor3 = isPositive and COLORS.positive or COLORS.negative
	
	-- Gentle slide and fade animation
	changeIndicator.Position = UDim2.new(1, -5, 0.5, -10)
	changeIndicator.TextTransparency = 0
	
	local slideUp = TweenService:Create(changeIndicator, 
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -5, 0.5, -25),
		TextTransparency = 1
	})
	slideUp:Play()
	
	-- Reset position after animation
	slideUp.Completed:Connect(function()
		changeIndicator.Position = UDim2.new(1, -5, 0.5, 0)
	end)
	
	-- Subtle icon bounce
	local iconBounce = TweenService:Create(iconContainer,
		TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 70, 0, 70)
	})
	iconBounce:Play()
	
	iconBounce.Completed:Connect(function()
		local iconReturn = TweenService:Create(iconContainer,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 65, 0, 65)
		})
		iconReturn:Play()
	end)
	
	-- Subtle glow effect
	local glowColor = isPositive and COLORS.positive or COLORS.negative
	local glow = TweenService:Create(stroke,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Color = glowColor,
		Thickness = 3,
		Transparency = 0.2
	})
	glow:Play()
	
	glow.Completed:Connect(function()
		local glowFade = TweenService:Create(stroke,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			Color = COLORS.border,
			Thickness = 2,
			Transparency = 0.5
		})
		glowFade:Play()
	end)
	
	-- Smooth number counting
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
			cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
			
			if progress >= 1 then
				connection:Disconnect()
				displayedCash = newValue
				cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
				animating = false
			end
		end)
	else
		displayedCash = newValue
		cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
	end
end

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("CashUIRemotes", 5)
local getCashRemote = remotes and remotes:WaitForChild("GetPlayerCash", 5)
local cashUpdateRemote = remotes and remotes:WaitForChild("CashUpdated", 5)

-- Get money from server
local function updateCash()
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
	
	-- Fallback to leaderstats
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

-- Listen for updates
if cashUpdateRemote then
	cashUpdateRemote.OnClientEvent:Connect(function(newCash)
		if newCash ~= currentCash then
			animateCashChange(currentCash, newCash)
			currentCash = newCash
		end
	end)
end

-- Responsive sizing
local function optimizeForDevice()
	local viewport = workspace.CurrentCamera.ViewportSize
	local isMobile = viewport.X < 800 or viewport.Y < 600
	
	if isMobile then
		-- Slightly smaller and higher up on mobile
		shadowFrame.Size = UDim2.new(0, 280, 0, 85)
		shadowFrame.Position = UDim2.new(1, -20, 1, -160)
		cashTitleLabel.TextScaled = true
		cashAmount.TextScaled = true
	else
		-- Desktop size
		shadowFrame.Size = UDim2.new(0, 310, 0, 95)
		shadowFrame.Position = UDim2.new(1, -25, 1, -140)
	end
end

-- Initial setup with gentle fade in
mainPanel.GroupTransparency = 1
optimizeForDevice()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(optimizeForDevice)

-- Fade in animation
local fadeIn = TweenService:Create(mainPanel,
	TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
	GroupTransparency = 0
})
fadeIn:Play()

-- Start update loop
updateCash()
while true do
	if not animating then
		updateCash()
	end
	wait(UPDATE_RATE)
end