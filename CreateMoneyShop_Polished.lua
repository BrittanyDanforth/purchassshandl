-- Enhanced Money Shop with Gamepasses (Polished Version)
-- Place in: StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()

-- Enhanced Sanrio-inspired design tokens
local THEME = {
	Palette = {
		BackgroundPrimary = Color3.fromRGB(253, 242, 250),
		PanelFill = Color3.fromRGB(247, 214, 225),
		Accent = Color3.fromRGB(248, 189, 195),
		AccentDark = Color3.fromRGB(191, 141, 142),
		AccentLight = Color3.fromRGB(252, 220, 224),
		NeutralDark = Color3.fromRGB(30, 24, 26),
		White = Color3.fromRGB(255, 255, 255),
		Success = Color3.fromRGB(152, 251, 152),
		Gold = Color3.fromRGB(255, 215, 0),
	},
	Typography = {
		Header = Enum.Font.Cartoon,
		Body = Enum.Font.Gotham,
		Button = Enum.Font.GothamBold,
		Price = Enum.Font.SourceSansBold,
	},
	Strokes = {
		DefaultThickness = 2,
		HoverThickness = 3,
		LineJoinMode = Enum.LineJoinMode.Round,
	},
	Motion = {
		Transition = 0.3,
		Quick = 0.15,
		Bounce = 0.4,
	},
}

-- Developer products
local products = {
	{id = 3366419712, amount = 1000, icon = "💵", popular = false},
	{id = 3366420012, amount = 5000, icon = "💰", popular = true},
	{id = 3366420478, amount = 10000, icon = "💎", popular = false},
	{id = 3366420800, amount = 25000, icon = "👑", popular = false, bestValue = true},
}

-- Gamepasses (replace with your actual gamepass IDs)
local gamepasses = {
	{id = 1412171840, name = "Auto Collect", icon = "🤖", description = "Here's the upgrade you've been waiting for! This pass collects all your cash for you, instantly. You can forget about that repetitive trip over and over again, and just spend your time decorating!", price = nil, hasToggle = true}, -- Price fetched from Roblox
	{id = 123456789, name = "VIP", icon = "⭐", description = "Exclusive VIP benefits!", price = 399},
	{id = 123456790, name = "2x Cash", icon = "💸", description = "Double all cash earnings!", price = 799},
	{id = 123456792, name = "Bigger Pockets", icon = "🎒", description = "50% more inventory space!", price = 299},
}

-- Sound effects
local sounds = {
	hover = "rbxassetid://9120458165",
	click = "rbxassetid://9120373176",
	purchase = "rbxassetid://9120443648",
	tabSwitch = "rbxassetid://9120386886",
}

-- Create sound objects
local soundObjects = {}
for name, id in pairs(sounds) do
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.3
	sound.Parent = SoundService
	soundObjects[name] = sound
end

-- Format numbers with commas
local function formatNumber(n)
	local formatted = tostring(n)
	while true do
		local newFormatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		formatted = newFormatted
		if k == 0 then break end
	end
	return formatted
end

-- Play sound effect
local function playSound(soundName)
	local sound = soundObjects[soundName]
	if sound then
		sound:Play()
	end
end

-- Root GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyShop_Enhanced"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Overlay with blur effect
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Visible = false
overlay.Modal = true
overlay.ZIndex = 5
overlay.Parent = screenGui

-- Main modal container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.85, 0, 0.75, 0)
mainFrame.SizeConstraint = Enum.SizeConstraint.RelativeXX
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = THEME.Palette.BackgroundPrimary
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui

-- Add aspect ratio constraint for consistent shape
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1.5
aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 24)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = THEME.Strokes.DefaultThickness
mainStroke.LineJoinMode = THEME.Strokes.LineJoinMode
mainStroke.Color = THEME.Palette.AccentDark
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

-- Gradient background
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, THEME.Palette.BackgroundPrimary),
	ColorSequenceKeypoint.new(0.5, THEME.Palette.BackgroundPrimary:Lerp(THEME.Palette.PanelFill, 0.3)),
	ColorSequenceKeypoint.new(1, THEME.Palette.PanelFill)
}
gradient.Rotation = 135
gradient.Parent = mainFrame

-- Header with better structure
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 80)
header.BackgroundTransparency = 1
header.ZIndex = 11
header.Parent = mainFrame

-- Header background for visual separation
local headerBg = Instance.new("Frame")
headerBg.Size = UDim2.new(1, 0, 1, 10)
headerBg.BackgroundColor3 = THEME.Palette.White
headerBg.BackgroundTransparency = 0.9
headerBg.BorderSizePixel = 0
headerBg.Parent = header

local headerGradient = Instance.new("UIGradient")
headerGradient.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.8, 0),
	NumberSequenceKeypoint.new(1, 1)
}
headerGradient.Rotation = 90
headerGradient.Parent = headerBg

-- Title with better positioning
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.5, 0, 0, 36)
title.Position = UDim2.new(0, 24, 0, 12)
title.BackgroundTransparency = 1
title.Text = "✨ Kawaii Shop ✨"
title.TextColor3 = THEME.Palette.AccentDark
title.TextStrokeColor3 = THEME.Palette.White
title.TextStrokeTransparency = 0.7
title.Font = THEME.Typography.Header
title.TextSize = 32
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 12
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0.6, 0, 0, 20)
subtitle.Position = UDim2.new(0, 24, 0, 48)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Get exclusive items and boosts! 💖"
subtitle.TextColor3 = THEME.Palette.NeutralDark
subtitle.TextTransparency = 0.1
subtitle.Font = THEME.Typography.Body
subtitle.TextSize = 16
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 12
subtitle.Parent = header

-- Close button with better design
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.fromOffset(48, 48)
closeBtn.Position = UDim2.new(1, -24, 0, 16)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = THEME.Palette.Accent
closeBtn.Text = "✕"
closeBtn.TextColor3 = THEME.Palette.White
closeBtn.Font = THEME.Typography.Button
closeBtn.TextSize = 24
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 13
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.5, 0)
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Thickness = 0
closeStroke.Color = THEME.Palette.AccentDark
closeStroke.Parent = closeBtn

-- Tab navigation
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -48, 0, 48)
tabContainer.Position = UDim2.new(0, 24, 0, 88)
tabContainer.BackgroundTransparency = 1
tabContainer.ZIndex = 11
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.Padding = UDim.new(0, 12)
tabLayout.Parent = tabContainer

-- Content frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -48, 1, -160)
contentFrame.Position = UDim2.new(0, 24, 0, 144)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.ZIndex = 10
contentFrame.Parent = mainFrame

-- Tab creation function
local currentTab = nil
local tabs = {}
local pages = {}

local function createTab(name, icon)
	local tab = Instance.new("TextButton")
	tab.Name = name .. "Tab"
	tab.Size = UDim2.fromOffset(120, 40)
	tab.BackgroundColor3 = THEME.Palette.White
	tab.BackgroundTransparency = 0.9
	tab.Text = icon .. " " .. name
	tab.TextColor3 = THEME.Palette.NeutralDark
	tab.Font = THEME.Typography.Button
	tab.TextSize = 16
	tab.AutoButtonColor = false
	tab.ZIndex = 12
	tab.Parent = tabContainer
	
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 20)
	tabCorner.Parent = tab
	
	local tabStroke = Instance.new("UIStroke")
	tabStroke.Thickness = 0
	tabStroke.Color = THEME.Palette.AccentDark
	tabStroke.Transparency = 0.5
	tabStroke.Parent = tab
	
	tabs[name] = tab
	return tab
end

-- Create tabs
createTab("Cash", "💰")
createTab("Gamepasses", "⭐")

-- Page creation function
local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 6
	page.ScrollBarImageColor3 = THEME.Palette.AccentDark
	page.ScrollBarImageTransparency = 0.3
	page.BorderSizePixel = 0
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.ZIndex = 10
	page.Parent = contentFrame
	
	local pagePadding = Instance.new("UIPadding")
	pagePadding.PaddingTop = UDim.new(0, 8)
	pagePadding.PaddingBottom = UDim.new(0, 8)
	pagePadding.PaddingLeft = UDim.new(0, 8)
	pagePadding.PaddingRight = UDim.new(0, 8)
	pagePadding.Parent = page
	
	pages[name] = page
	return page
end

-- Create pages
local cashPage = createPage("Cash")
local gamepassPage = createPage("Gamepasses")

-- Cash page layout
local cashLayout = Instance.new("UIGridLayout")
cashLayout.CellSize = UDim2.new(0.48, 0, 0, 120)
cashLayout.CellPadding = UDim2.new(0.04, 0, 0, 16)
cashLayout.FillDirection = Enum.FillDirection.Horizontal
cashLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cashLayout.SortOrder = Enum.SortOrder.LayoutOrder
cashLayout.Parent = cashPage

-- Gamepass page layout
local gamepassLayout = Instance.new("UIListLayout")
gamepassLayout.FillDirection = Enum.FillDirection.Vertical
gamepassLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gamepassLayout.Padding = UDim.new(0, 12)
gamepassLayout.SortOrder = Enum.SortOrder.LayoutOrder
gamepassLayout.Parent = gamepassPage

-- Update canvas size
local function updateCanvas(page, layout)
	page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
end

cashLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	updateCanvas(cashPage, cashLayout)
end)

gamepassLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	updateCanvas(gamepassPage, gamepassLayout)
end)

-- Tab switching logic
local function switchTab(tabName)
	if currentTab == tabName then return end
	
	playSound("tabSwitch")
	
	-- Update tab appearance
	for name, tab in pairs(tabs) do
		if name == tabName then
			TweenService:Create(tab, TweenInfo.new(THEME.Motion.Quick), {
				BackgroundTransparency = 0.1,
				TextColor3 = THEME.Palette.AccentDark
			}):Play()
			TweenService:Create(tab:FindFirstChild("UIStroke"), TweenInfo.new(THEME.Motion.Quick), {
				Thickness = 2
			}):Play()
		else
			TweenService:Create(tab, TweenInfo.new(THEME.Motion.Quick), {
				BackgroundTransparency = 0.9,
				TextColor3 = THEME.Palette.NeutralDark
			}):Play()
			TweenService:Create(tab:FindFirstChild("UIStroke"), TweenInfo.new(THEME.Motion.Quick), {
				Thickness = 0
			}):Play()
		end
	end
	
	-- Hide all pages
	for _, page in pairs(pages) do
		page.Visible = false
	end
	
	-- Show selected page with animation
	local selectedPage = pages[tabName]
	if selectedPage then
		selectedPage.Visible = true
		selectedPage.CanvasPosition = Vector2.new(0, 0)
		
		-- Animate page entrance
		local pageScale = selectedPage:FindFirstChild("UIScale")
		if not pageScale then
			pageScale = Instance.new("UIScale")
			pageScale.Parent = selectedPage
		end
		pageScale.Scale = 0.95
		TweenService:Create(pageScale, TweenInfo.new(THEME.Motion.Quick, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1
		}):Play()
	end
	
	currentTab = tabName
end

-- Connect tab buttons
for name, tab in pairs(tabs) do
	tab.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
	
	tab.MouseEnter:Connect(function()
		playSound("hover")
		if currentTab ~= name then
			TweenService:Create(tab, TweenInfo.new(THEME.Motion.Quick), {
				BackgroundTransparency = 0.7
			}):Play()
		end
	end)
	
	tab.MouseLeave:Connect(function()
		if currentTab ~= name then
			TweenService:Create(tab, TweenInfo.new(THEME.Motion.Quick), {
				BackgroundTransparency = 0.9
			}):Play()
		end
	end)
end

-- Create product cards
for i, product in ipairs(products) do
	local card = Instance.new("Frame")
	card.Name = "Product" .. i
	card.BackgroundColor3 = THEME.Palette.White
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.LayoutOrder = i
	card.ZIndex = 10
	card.Parent = cashPage
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 2
	cardStroke.Color = THEME.Palette.AccentLight
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card
	
	-- Shadow effect
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 12, 1, 12)
	shadow.Position = UDim2.fromOffset(-6, -6)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.9
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.ZIndex = 9
	shadow.Parent = card
	
	-- Icon with gradient background
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.fromOffset(64, 64)
	iconFrame.Position = UDim2.new(0.5, 0, 0, 16)
	iconFrame.AnchorPoint = Vector2.new(0.5, 0)
	iconFrame.BackgroundColor3 = THEME.Palette.Accent
	iconFrame.ZIndex = 11
	iconFrame.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 16)
	iconCorner.Parent = iconFrame
	
	local iconGradient = Instance.new("UIGradient")
	iconGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, THEME.Palette.AccentLight),
		ColorSequenceKeypoint.new(1, THEME.Palette.Accent)
	}
	iconGradient.Rotation = 45
	iconGradient.Parent = iconFrame
	
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Text = product.icon
	icon.TextScaled = true
	icon.Font = THEME.Typography.Header
	icon.ZIndex = 12
	icon.Parent = iconFrame
	
	-- Amount
	local amount = Instance.new("TextLabel")
	amount.Size = UDim2.new(1, -16, 0, 24)
	amount.Position = UDim2.new(0, 8, 1, -32)
	amount.BackgroundTransparency = 1
	amount.Text = formatNumber(product.amount) .. " Cash"
	amount.TextColor3 = THEME.Palette.NeutralDark
	amount.Font = THEME.Typography.Price
	amount.TextSize = 18
	amount.ZIndex = 11
	amount.Parent = card
	
	-- Tags
	if product.popular then
		local popularTag = Instance.new("Frame")
		popularTag.Size = UDim2.fromOffset(80, 24)
		popularTag.Position = UDim2.new(1, -8, 0, 8)
		popularTag.AnchorPoint = Vector2.new(1, 0)
		popularTag.BackgroundColor3 = THEME.Palette.Accent
		popularTag.ZIndex = 12
		popularTag.Parent = card
		
		local tagCorner = Instance.new("UICorner")
		tagCorner.CornerRadius = UDim.new(0, 12)
		tagCorner.Parent = popularTag
		
		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.fromScale(1, 1)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Text = "POPULAR"
		tagLabel.TextColor3 = THEME.Palette.White
		tagLabel.Font = THEME.Typography.Button
		tagLabel.TextSize = 12
		tagLabel.ZIndex = 13
		tagLabel.Parent = popularTag
	elseif product.bestValue then
		local valueTag = Instance.new("Frame")
		valueTag.Size = UDim2.fromOffset(90, 24)
		valueTag.Position = UDim2.new(1, -8, 0, 8)
		valueTag.AnchorPoint = Vector2.new(1, 0)
		valueTag.BackgroundColor3 = THEME.Palette.Gold
		valueTag.ZIndex = 12
		valueTag.Parent = card
		
		local tagCorner = Instance.new("UICorner")
		tagCorner.CornerRadius = UDim.new(0, 12)
		tagCorner.Parent = valueTag
		
		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.fromScale(1, 1)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Text = "BEST VALUE"
		tagLabel.TextColor3 = THEME.Palette.NeutralDark
		tagLabel.Font = THEME.Typography.Button
		tagLabel.TextSize = 12
		tagLabel.ZIndex = 13
		tagLabel.Parent = valueTag
	end
	
	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(1, -16, 0, 36)
	buyBtn.Position = UDim2.new(0, 8, 1, -44)
	buyBtn.BackgroundColor3 = THEME.Palette.Accent
	buyBtn.Text = "BUY"
	buyBtn.TextColor3 = THEME.Palette.White
	buyBtn.Font = THEME.Typography.Button
	buyBtn.TextSize = 16
	buyBtn.AutoButtonColor = false
	buyBtn.ZIndex = 12
	buyBtn.Parent = card
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 18)
	buyCorner.Parent = buyBtn
	
	local buyStroke = Instance.new("UIStroke")
	buyStroke.Thickness = 0
	buyStroke.Color = THEME.Palette.AccentDark
	buyStroke.Parent = buyBtn
	
	-- Hover effects
	local cardScale = Instance.new("UIScale")
	cardScale.Scale = 1
	cardScale.Parent = card
	
	buyBtn.MouseEnter:Connect(function()
		playSound("hover")
		TweenService:Create(cardScale, TweenInfo.new(THEME.Motion.Quick), {Scale = 1.05}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(THEME.Motion.Quick), {
			Color = THEME.Palette.Accent,
			Thickness = 3
		}):Play()
		TweenService:Create(buyBtn, TweenInfo.new(THEME.Motion.Quick), {
			BackgroundColor3 = THEME.Palette.AccentDark
		}):Play()
	end)
	
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(cardScale, TweenInfo.new(THEME.Motion.Quick), {Scale = 1}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(THEME.Motion.Quick), {
			Color = THEME.Palette.AccentLight,
			Thickness = 2
		}):Play()
		TweenService:Create(buyBtn, TweenInfo.new(THEME.Motion.Quick), {
			BackgroundColor3 = THEME.Palette.Accent
		}):Play()
	end)
	
	buyBtn.MouseButton1Click:Connect(function()
		playSound("click")
		MarketplaceService:PromptProductPurchase(player, product.id)
	end)
end

-- Function to fetch gamepass price
local function fetchGamepassPrice(gamepassId)
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)
	
	if success and info then
		return info.PriceInRobux
	end
	return nil
end

-- Fetch real prices for gamepasses
spawn(function()
	for _, gamepass in ipairs(gamepasses) do
		if not gamepass.price then
			local price = fetchGamepassPrice(gamepass.id)
			if price then
				gamepass.price = price
			end
		end
	end
end)

-- Create gamepass cards
for i, gamepass in ipairs(gamepasses) do
	local card = Instance.new("Frame")
	card.Name = "Gamepass" .. i
	card.Size = UDim2.new(0.9, 0, 0, 100)
	card.BackgroundColor3 = THEME.Palette.White
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.LayoutOrder = i
	card.ZIndex = 10
	card.Parent = gamepassPage
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 2
	cardStroke.Color = THEME.Palette.Gold
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card
	
	local cardGradient = Instance.new("UIGradient")
	cardGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, THEME.Palette.Gold:Lerp(Color3.new(1, 1, 1), 0.9))
	}
	cardGradient.Rotation = 90
	cardGradient.Parent = card
	
	-- Icon
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.fromOffset(72, 72)
	iconBg.Position = UDim2.new(0, 14, 0.5, 0)
	iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = THEME.Palette.Gold
	iconBg.ZIndex = 11
	iconBg.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 16)
	iconCorner.Parent = iconBg
	
	local gamepassIcon = Instance.new("TextLabel")
	gamepassIcon.Size = UDim2.fromScale(1, 1)
	gamepassIcon.BackgroundTransparency = 1
	gamepassIcon.Text = gamepass.icon
	gamepassIcon.TextScaled = true
	gamepassIcon.Font = THEME.Typography.Header
	gamepassIcon.ZIndex = 12
	gamepassIcon.Parent = iconBg
	
	-- Info
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, -100, 0, 24)
	nameLabel.Position = UDim2.new(0, 100, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = gamepass.name
	nameLabel.TextColor3 = THEME.Palette.NeutralDark
	nameLabel.Font = THEME.Typography.Button
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 11
	nameLabel.Parent = card
	
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.5, -100, 0, 36)
	descLabel.Position = UDim2.new(0, 100, 0, 44)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = gamepass.description
	descLabel.TextColor3 = THEME.Palette.NeutralDark
	descLabel.TextTransparency = 0.2
	descLabel.Font = THEME.Typography.Body
	descLabel.TextSize = 14
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.ZIndex = 11
	descLabel.Parent = card
	
	-- Price button
	local priceBtn = Instance.new("TextButton")
	priceBtn.Size = UDim2.fromOffset(120, 48)
	priceBtn.Position = UDim2.new(1, -14, 0.5, 0)
	priceBtn.AnchorPoint = Vector2.new(1, 0.5)
	priceBtn.BackgroundColor3 = THEME.Palette.Success
	priceBtn.Text = gamepass.price and ("R$" .. tostring(gamepass.price)) or "Loading..."
	priceBtn.TextColor3 = THEME.Palette.White
	priceBtn.Font = THEME.Typography.Price
	priceBtn.TextSize = 20
	priceBtn.AutoButtonColor = false
	priceBtn.ZIndex = 12
	priceBtn.Parent = card
	
	-- Update price when loaded
	if not gamepass.price then
		spawn(function()
			local price = fetchGamepassPrice(gamepass.id)
			if price then
				gamepass.price = price
				priceBtn.Text = "R$" .. tostring(price)
			else
				priceBtn.Text = "Error"
			end
		end)
	end
	
	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0, 24)
	priceCorner.Parent = priceBtn
	
	local priceStroke = Instance.new("UIStroke")
	priceStroke.Thickness = 2
	priceStroke.Color = THEME.Palette.Success:Lerp(Color3.new(0, 0, 0), 0.2)
	priceStroke.Transparency = 0.5
	priceStroke.Parent = priceBtn
	
	-- Hover effects
	local cardScale = Instance.new("UIScale")
	cardScale.Scale = 1
	cardScale.Parent = card
	
	priceBtn.MouseEnter:Connect(function()
		playSound("hover")
		TweenService:Create(cardScale, TweenInfo.new(THEME.Motion.Quick), {Scale = 1.02}):Play()
		TweenService:Create(priceBtn, TweenInfo.new(THEME.Motion.Quick), {
			Size = UDim2.fromOffset(130, 52)
		}):Play()
	end)
	
	priceBtn.MouseLeave:Connect(function()
		TweenService:Create(cardScale, TweenInfo.new(THEME.Motion.Quick), {Scale = 1}):Play()
		TweenService:Create(priceBtn, TweenInfo.new(THEME.Motion.Quick), {
			Size = UDim2.fromOffset(120, 48)
		}):Play()
	end)
	
	-- Check if player owns this gamepass
	local ownsGamepass = false
	spawn(function()
		local success, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.id)
		end)
		if success and result then
			ownsGamepass = true
			-- Update button appearance if they own it
			priceBtn.BackgroundColor3 = THEME.Palette.AccentDark
			priceBtn.Text = "Owned"
			
			-- Add toggle if this gamepass supports it
			if gamepass.hasToggle then
				-- Create toggle switch
				local toggleFrame = Instance.new("Frame")
				toggleFrame.Size = UDim2.fromOffset(60, 30)
				toggleFrame.Position = UDim2.new(1, -14, 0.5, 0)
				toggleFrame.AnchorPoint = Vector2.new(1, 0.5)
				toggleFrame.BackgroundColor3 = THEME.Palette.AccentLight
				toggleFrame.BorderSizePixel = 0
				toggleFrame.ZIndex = 12
				toggleFrame.Parent = card
				
				local toggleCorner = Instance.new("UICorner")
				toggleCorner.CornerRadius = UDim.new(0.5, 0)
				toggleCorner.Parent = toggleFrame
				
				local toggleStroke = Instance.new("UIStroke")
				toggleStroke.Thickness = 2
				toggleStroke.Color = THEME.Palette.AccentDark
				toggleStroke.Transparency = 0.5
				toggleStroke.Parent = toggleFrame
				
				local toggleButton = Instance.new("TextButton")
				toggleButton.Size = UDim2.fromOffset(26, 26)
				toggleButton.Position = UDim2.fromOffset(2, 2)
				toggleButton.BackgroundColor3 = THEME.Palette.White
				toggleButton.Text = ""
				toggleButton.AutoButtonColor = false
				toggleButton.ZIndex = 13
				toggleButton.Parent = toggleFrame
				
				local toggleButtonCorner = Instance.new("UICorner")
				toggleButtonCorner.CornerRadius = UDim.new(0.5, 0)
				toggleButtonCorner.Parent = toggleButton
				
				-- Check current state from server
				local remoteFolder = ReplicatedStorage:WaitForChild("TycoonRemotes", 5)
				local autoCollectRemote = remoteFolder and remoteFolder:FindFirstChild("AutoCollectToggle")
				
				local isEnabled = true -- Default to enabled
				
				-- Toggle function
				local function updateToggleVisual(enabled)
					if enabled then
						toggleFrame.BackgroundColor3 = THEME.Palette.Success
						TweenService:Create(toggleButton, TweenInfo.new(0.2), {
							Position = UDim2.fromOffset(32, 2)
						}):Play()
					else
						toggleFrame.BackgroundColor3 = THEME.Palette.AccentLight
						TweenService:Create(toggleButton, TweenInfo.new(0.2), {
							Position = UDim2.fromOffset(2, 2)
						}):Play()
					end
				end
				
				updateToggleVisual(isEnabled)
				
				-- Toggle click
				toggleButton.MouseButton1Click:Connect(function()
					playSound("click")
					isEnabled = not isEnabled
					updateToggleVisual(isEnabled)
					
					-- Fire to server
					if autoCollectRemote then
						autoCollectRemote:FireServer(isEnabled)
					end
				end)
				
				-- Move price button
				priceBtn:Destroy()
			end
		end
	end)
	
	priceBtn.MouseButton1Click:Connect(function()
		if not ownsGamepass then
			playSound("click")
			MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
		end
	end)
end

-- Toggle button with pulse animation
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.fromOffset(72, 72)
toggleBtn.Position = UDim2.new(1, -20, 1, -20)
toggleBtn.AnchorPoint = Vector2.new(1, 1)
toggleBtn.BackgroundColor3 = THEME.Palette.Accent
toggleBtn.Text = "💰"
toggleBtn.TextScaled = true
toggleBtn.Font = THEME.Typography.Header
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 15
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.5, 0)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Thickness = 3
toggleStroke.Color = THEME.Palette.AccentDark
toggleStroke.Parent = toggleBtn

-- Pulse effect
local pulseFrame = Instance.new("Frame")
pulseFrame.Size = UDim2.fromScale(1, 1)
pulseFrame.BackgroundColor3 = THEME.Palette.Accent
pulseFrame.BackgroundTransparency = 0.7
pulseFrame.ZIndex = 14
pulseFrame.Parent = toggleBtn

local pulseCorner = Instance.new("UICorner")
pulseCorner.CornerRadius = UDim.new(0.5, 0)
pulseCorner.Parent = pulseFrame

local pulseScale = Instance.new("UIScale")
pulseScale.Scale = 1
pulseScale.Parent = pulseFrame

-- Continuous pulse animation
spawn(function()
	while true do
		TweenService:Create(pulseScale, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Scale = 1.3
		}):Play()
		wait(1.5)
		TweenService:Create(pulseScale, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Scale = 1
		}):Play()
		wait(1.5)
	end
end)

-- Show/Hide functions
local isOpen = false

local function showShop()
	if isOpen then return end
	isOpen = true
	
	overlay.Visible = true
	mainFrame.Visible = true
	
	-- Reset to first tab
	switchTab("Cash")
	
	-- Animate overlay
	TweenService:Create(overlay, TweenInfo.new(THEME.Motion.Transition), {
		BackgroundTransparency = 0.3
	}):Play()
	
	-- Animate main frame
	local scale = mainFrame:FindFirstChild("UIScale") or Instance.new("UIScale")
	scale.Scale = 0.8
	scale.Parent = mainFrame
	
	TweenService:Create(scale, TweenInfo.new(THEME.Motion.Bounce, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	}):Play()
	
	-- Animate toggle button
	TweenService:Create(toggleBtn, TweenInfo.new(THEME.Motion.Quick), {
		Rotation = 360
	}):Play()
end

local function hideShop()
	if not isOpen then return end
	isOpen = false
	
	-- Animate overlay
	TweenService:Create(overlay, TweenInfo.new(THEME.Motion.Quick), {
		BackgroundTransparency = 1
	}):Play()
	
	-- Animate main frame
	local scale = mainFrame:FindFirstChild("UIScale")
	if scale then
		local tween = TweenService:Create(scale, TweenInfo.new(THEME.Motion.Quick, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Scale = 0.8
		})
		
		tween.Completed:Connect(function()
			mainFrame.Visible = false
			overlay.Visible = false
		end)
		
		tween:Play()
	end
	
	-- Reset toggle rotation
	TweenService:Create(toggleBtn, TweenInfo.new(THEME.Motion.Quick), {
		Rotation = 0
	}):Play()
end

-- Connect buttons
toggleBtn.MouseButton1Click:Connect(function()
	playSound("click")
	if isOpen then
		hideShop()
	else
		showShop()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	playSound("click")
	hideShop()
end)

overlay.MouseButton1Click:Connect(function()
	hideShop()
end)

-- Toggle button hover
toggleBtn.MouseEnter:Connect(function()
	playSound("hover")
	TweenService:Create(toggleBtn, TweenInfo.new(THEME.Motion.Quick), {
		Size = UDim2.fromOffset(80, 80)
	}):Play()
end)

toggleBtn.MouseLeave:Connect(function()
	TweenService:Create(toggleBtn, TweenInfo.new(THEME.Motion.Quick), {
		Size = UDim2.fromOffset(72, 72)
	}):Play()
end)

-- Close button hover
closeBtn.MouseEnter:Connect(function()
	playSound("hover")
	TweenService:Create(closeBtn, TweenInfo.new(THEME.Motion.Quick), {
		BackgroundColor3 = THEME.Palette.AccentDark,
		Size = UDim2.fromOffset(52, 52)
	}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(THEME.Motion.Quick), {
		BackgroundColor3 = THEME.Palette.Accent,
		Size = UDim2.fromOffset(48, 48)
	}):Play()
end)

-- Purchase success handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		playSound("purchase")
		-- You can add a success notification here
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if wasPurchased and userId == player.UserId then
		playSound("purchase")
		-- You can add a success notification here
	end
end)

-- Cleanup
screenGui.AncestryChanged:Connect(function()
	if not screenGui.Parent then
		for _, sound in pairs(soundObjects) do
			sound:Destroy()
		end
	end
end)

print("✨ Enhanced Money Shop loaded with gamepasses!")