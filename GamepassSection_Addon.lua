-- ADD THIS TO YOUR EXISTING CreateMoneyShop SCRIPT
-- This adds a gamepass section without changing your existing look

-- Add this after your products table:
local gamepasses = {
	{id = 1412171840, name = "Auto Collect", icon = "🤖", price = nil}, -- Price fetched from Roblox
	-- Add more gamepasses here if needed
}

-- Add this function after formatNumber:
local function fetchGamepassPrice(gamepassId)
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)
	
	if success and info then
		return info.PriceInRobux
	end
	return "???"
end

-- Add this after creating your product cards (around line 380):

-- Add a separator
local separator = Instance.new("Frame")
separator.Name = "Separator"
separator.Size = UDim2.new(1, -8, 0, 30)
separator.BackgroundTransparency = 1
separator.Parent = container

local separatorLine = Instance.new("Frame")
separatorLine.Size = UDim2.new(0.8, 0, 0, 2)
separatorLine.Position = UDim2.fromScale(0.5, 0.5)
separatorLine.AnchorPoint = Vector2.new(0.5, 0.5)
separatorLine.BackgroundColor3 = THEME.Palette.AccentDark
separatorLine.BackgroundTransparency = 0.7
separatorLine.BorderSizePixel = 0
separatorLine.Parent = separator

local gamepassLabel = Instance.new("TextLabel")
gamepassLabel.Size = UDim2.fromScale(1, 1)
gamepassLabel.BackgroundTransparency = 1
gamepassLabel.Text = "GAMEPASSES"
gamepassLabel.TextColor3 = THEME.Palette.AccentDark
gamepassLabel.Font = THEME.Typography.Header
gamepassLabel.TextSize = 16
gamepassLabel.Parent = separator

-- Create gamepass cards (same style as your product cards)
for i, gamepass in ipairs(gamepasses) do
	local card = Instance.new("Frame")
	card.Name = "Gamepass" .. i
	card.Size = UDim2.new(1, -8, 0, 96)
	card.BackgroundColor3 = THEME.Palette.PanelFill
	card.BorderSizePixel = 0
	card.LayoutOrder = 100 + i -- After products
	card.ZIndex = 10
	card.Parent = container

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0.12, 0)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = THEME.Strokes.DefaultThickness
	cardStroke.Color = THEME.Palette.AccentDark
	cardStroke.Transparency = 0.4
	cardStroke.Parent = card

	-- Icon background (same as products)
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.fromOffset(72, 72)
	iconBg.Position = UDim2.new(0, 12, 0.5, -36)
	iconBg.BackgroundColor3 = THEME.Palette.Accent
	iconBg.BackgroundTransparency = 0
	iconBg.ZIndex = 11
	iconBg.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.25, 0)
	iconCorner.Parent = iconBg

	local iconAspect = Instance.new("UIAspectRatioConstraint")
	iconAspect.AspectRatio = 1
	iconAspect.Parent = iconBg

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Thickness = THEME.Strokes.DefaultThickness
	iconStroke.Color = THEME.Palette.AccentDark
	iconStroke.Parent = iconBg

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Text = gamepass.icon
	icon.TextColor3 = THEME.Palette.White
	icon.TextStrokeColor3 = THEME.Palette.AccentDark
	icon.TextStrokeTransparency = 0.4
	icon.Font = THEME.Typography.Header
	icon.TextSize = 28
	icon.ZIndex = 12
	icon.Parent = iconBg

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -220, 0, 28)
	nameLabel.Position = UDim2.new(0, 100, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = gamepass.name
	nameLabel.TextColor3 = THEME.Palette.NeutralDark
	nameLabel.TextStrokeTransparency = 1
	nameLabel.Font = THEME.Typography.Body
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 11
	nameLabel.Parent = card

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -220, 0, 20)
	desc.Position = UDim2.new(0, 100, 0, 48)
	desc.BackgroundTransparency = 1
	desc.Text = "Permanent upgrade"
	desc.TextColor3 = THEME.Palette.NeutralDark
	desc.TextTransparency = 0.15
	desc.Font = THEME.Typography.Body
	desc.TextSize = 16
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.ZIndex = 11
	desc.Parent = card

	-- Buy button (same style as products)
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.fromOffset(96, 44)
	buyBtn.Position = UDim2.new(1, -112, 0.5, -22)
	buyBtn.BackgroundColor3 = THEME.Palette.Accent
	buyBtn.Text = "Loading..."
	buyBtn.TextColor3 = THEME.Palette.White
	buyBtn.Font = THEME.Typography.Button
	buyBtn.TextSize = 18
	buyBtn.AutoButtonColor = false
	buyBtn.ZIndex = 12
	buyBtn.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.5, 0)
	buyCorner.Parent = buyBtn

	local buyStroke = Instance.new("UIStroke")
	buyStroke.Thickness = THEME.Strokes.DefaultThickness
	buyStroke.Color = THEME.Palette.AccentDark
	buyStroke.Parent = buyBtn

	local buyScale = Instance.new("UIScale")
	buyScale.Scale = 1
	buyScale.Parent = buyBtn

	-- Fetch price
	spawn(function()
		local price = gamepass.price or fetchGamepassPrice(gamepass.id)
		if price and price ~= "???" then
			buyBtn.Text = "R$" .. tostring(price)
		else
			buyBtn.Text = "Buy"
		end
	end)

	-- Same hover animations as products
	track(buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(THEME.Motion.Quick), {BackgroundColor3 = THEME.Palette.Accent:lerp(THEME.Palette.White, 0.08)}):Play()
		TweenService:Create(buyScale, TweenInfo.new(THEME.Motion.Quick), {Scale = 1.05}):Play()
	end))

	track(buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(THEME.Motion.Quick), {BackgroundColor3 = THEME.Palette.Accent}):Play()
		TweenService:Create(buyScale, TweenInfo.new(THEME.Motion.Quick), {Scale = 1}):Play()
	end))

	track(buyBtn.MouseButton1Down:Connect(function()
		TweenService:Create(buyScale, TweenInfo.new(THEME.Motion.Quick), {Scale = 0.95}):Play()
	end))

	track(buyBtn.MouseButton1Up:Connect(function()
		TweenService:Create(buyScale, TweenInfo.new(THEME.Motion.Quick, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.1}):Play()
	end))

	-- Purchase handler
	track(buyBtn.MouseButton1Click:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
	end))
end