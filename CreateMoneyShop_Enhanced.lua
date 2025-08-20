--[[
	✨ KAWAII MONEY SHOP ENHANCED - Full Implementation
	Based on "The Kawaii Monetization Blueprint"
	
	Features:
	- Multiple Sanrio themes (Cinnamoroll, Hello Kitty, My Melody, Kuromi)
	- Tabbed navigation (Currency, Gamepasses, Featured)
	- Real-time price fetching for gamepasses
	- Auto-claim integration support
	- 2x Cash gamepass detection
	- Psychological nudges (Best Value, Most Popular)
	- Enhanced animations and polish
--]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ========================================
-- THEME SYSTEM (Section 1.3)
-- ========================================

local THEMES = {
	-- Cinnamoroll Sky Theme (Default)
	Cinnamoroll = {
		BackgroundPrimary = Color3.fromRGB(255, 255, 255),      -- White
		PanelFill = Color3.fromRGB(193, 231, 245),             -- Light Blue
		Accent = Color3.fromRGB(76, 181, 232),                 -- Sky Blue
		AccentDark = Color3.fromRGB(251, 216, 222),            -- Blush Pink
		TextPrimary = Color3.fromRGB(30, 24, 26),              -- Near Black
		Success = Color3.fromRGB(255, 208, 225),               -- Pastel Pink
		Warning = Color3.fromRGB(255, 231, 153),               -- Pastel Yellow
		White = Color3.fromRGB(255, 255, 255),
	},
	-- Hello Kitty Classic
	HelloKitty = {
		BackgroundPrimary = Color3.fromRGB(255, 255, 255),
		PanelFill = Color3.fromRGB(255, 231, 23),              -- Yellow
		Accent = Color3.fromRGB(237, 22, 79),                  -- Crimson
		AccentDark = Color3.fromRGB(28, 99, 183),              -- Blue
		TextPrimary = Color3.fromRGB(30, 24, 26),
		Success = Color3.fromRGB(123, 237, 159),               -- Mint
		Warning = Color3.fromRGB(255, 231, 23),                -- Yellow
		White = Color3.fromRGB(255, 255, 255),
	},
	-- My Melody Sweet
	MyMelody = {
		BackgroundPrimary = Color3.fromRGB(253, 242, 250),     -- Off-White
		PanelFill = Color3.fromRGB(252, 234, 248),             -- Light Pink
		Accent = Color3.fromRGB(248, 189, 195),                -- Pink
		AccentDark = Color3.fromRGB(191, 141, 142),            -- Muted Rose
		TextPrimary = Color3.fromRGB(30, 24, 26),
		Success = Color3.fromRGB(147, 214, 161),               -- Soft Green
		Warning = Color3.fromRGB(255, 208, 225),               -- Dusty Rose
		White = Color3.fromRGB(255, 255, 255),
	},
	-- Kuromi Punk
	Kuromi = {
		BackgroundPrimary = Color3.fromRGB(225, 221, 244),     -- Light Lilac
		PanelFill = Color3.fromRGB(202, 197, 237),             -- Lavender
		Accent = Color3.fromRGB(240, 195, 226),                -- Pastel Pink
		AccentDark = Color3.fromRGB(81, 66, 131),              -- Dark Purple
		TextPrimary = Color3.fromRGB(0, 0, 0),                 -- Black
		Success = Color3.fromRGB(202, 197, 237),               -- Lavender
		Warning = Color3.fromRGB(240, 195, 226),               -- Pink
		White = Color3.fromRGB(255, 255, 255),
	}
}

-- Select theme (can be changed dynamically)
local CURRENT_THEME = "Cinnamoroll"
local PALETTE = THEMES[CURRENT_THEME]

-- Typography (Section 1.3)
local FONTS = {
	Header = Enum.Font.FredokaOne,          -- Rounded, kawaii
	Body = Enum.Font.Gotham,                -- Clean, legible
	Button = Enum.Font.FredokaOne,          -- Chunky
	Currency = Enum.Font.SourceSansBold,    -- Clear numbers
}

-- Animation timings
local MOTION = {
	Quick = 0.15,       -- Hover effects
	Normal = 0.3,       -- Standard transitions
	Bounce = 0.4,       -- Bouncy animations
	Elastic = 0.5,      -- Elastic effects
}

-- UI styling constants
local CORNER_RADIUS = {
	Container = UDim.new(0.05, 0),
	Card = UDim.new(0.1, 0),
	Button = UDim.new(0.25, 0),
	Round = UDim.new(0.5, 0),
}

-- ========================================
-- SHOP DATA CONFIGURATION
-- ========================================

-- Currency products with psychological nudges (Section 2.3)
local CURRENCY_PRODUCTS = {
	{
		id = 3366419712,
		amount = 1000,
		icon = "💵",
		description = "Small starter boost",
		tag = nil,
	},
	{
		id = 3366420012,
		amount = 5000,
		icon = "💰",
		description = "Perfect for regular players",
		tag = "MOST POPULAR",
		tagColor = "Success",
	},
	{
		id = 3366420478,
		amount = 10000,
		icon = "💎",
		description = "Great value for builders",
		tag = nil,
	},
	{
		id = 3366420800,
		amount = 25000,
		icon = "👑",
		description = "Maximum cash for pros!",
		tag = "BEST VALUE",
		tagColor = "Warning",
	},
}

-- Gamepass configuration (will fetch real prices)
local GAMEPASS_CONFIG = {
	{
		id = 123456789, -- Replace with your VIP gamepass ID
		name = "VIP Access",
		icon = "⭐",
		benefits = {
			"Exclusive VIP area access",
			"Special VIP chat tag",
			"20% bonus on all purchases",
		},
		tag = "EXCLUSIVE",
		tagColor = "Accent",
	},
	{
		id = 123456790, -- Replace with your 2x Cash gamepass ID
		name = "2x Cash Forever",
		icon = "💰",
		benefits = {
			"Double all cash earnings",
			"Works with auto-collect",
			"Stacks with other bonuses",
		},
		tag = "POPULAR",
		tagColor = "Success",
	},
	{
		id = 123456791, -- Replace with your auto-collect gamepass ID
		name = "Auto Collect",
		icon = "🔄",
		benefits = {
			"Automatically collect cash",
			"No more manual clicking",
			"Works 24/7",
		},
		tag = nil,
	},
	{
		id = 123456792, -- Replace with your bigger pockets gamepass ID
		name = "Bigger Pockets",
		icon = "🎒",
		benefits = {
			"2x inventory capacity",
			"Store more items",
			"Quality of life upgrade",
		},
		tag = nil,
	},
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

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

-- Connection tracking for cleanup
local connections = {}
local function track(conn)
	table.insert(connections, conn)
	return conn
end

-- Create tween helper
local function tween(object, properties, duration, style, direction)
	duration = duration or MOTION.Quick
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	
	return TweenService:Create(object, TweenInfo.new(duration, style, direction), properties)
end

-- Fetch gamepass price and ownership
local function fetchGamepassInfo(gamepassId)
	local info = {price = "???", owned = false}
	
	-- Check ownership
	local success, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	
	if success then
		info.owned = owned
	end
	
	-- Get product info for price
	local success2, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)
	
	if success2 and productInfo then
		if productInfo.PriceInRobux then
			info.price = tostring(productInfo.PriceInRobux)
		else
			info.price = "Free"
		end
	end
	
	return info
end

-- ========================================
-- CREATE UI STRUCTURE
-- ========================================

-- Root GUI
local gui = Instance.new("ScreenGui")
gui.Name = "KawaiiMoneyShop"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

-- Dark overlay
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
overlay.Parent = gui

-- Main container (Hybrid sizing - Section 3.1)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromScale(0.85, 0.85)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = PALETTE.BackgroundPrimary
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ZIndex = 10
mainFrame.Parent = gui

-- Main frame styling
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = CORNER_RADIUS.Container
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 3
mainStroke.LineJoinMode = Enum.LineJoinMode.Round
mainStroke.Color = PALETTE.AccentDark
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, PALETTE.BackgroundPrimary:Lerp(PALETTE.White, 0.1)),
	ColorSequenceKeypoint.new(1, PALETTE.PanelFill)
}
mainGradient.Rotation = 90
mainGradient.Parent = mainFrame

local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0, 20)
mainPadding.PaddingBottom = UDim.new(0, 20)
mainPadding.PaddingLeft = UDim.new(0, 20)
mainPadding.PaddingRight = UDim.new(0, 20)
mainPadding.Parent = mainFrame

-- ========================================
-- HEADER
-- ========================================

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 80)
header.BackgroundTransparency = 1
header.ZIndex = 11
header.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "✨ Kawaii Shop ✨"
title.TextColor3 = PALETTE.TextPrimary
title.Font = FONTS.Header
title.TextSize = 36
title.Parent = header

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -60, 0, 24)
subtitle.Position = UDim2.new(0, 0, 0, 40)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Get cute boosts & exclusive perks! 💖"
subtitle.TextColor3 = PALETTE.TextPrimary
subtitle.TextTransparency = 0.2
subtitle.Font = FONTS.Body
subtitle.TextSize = 18
subtitle.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(48, 48)
closeBtn.Position = UDim2.new(1, -48, 0, 16)
closeBtn.BackgroundColor3 = PALETTE.Accent
closeBtn.Text = "✕"
closeBtn.TextColor3 = PALETTE.White
closeBtn.Font = FONTS.Button
closeBtn.TextSize = 24
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 12
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = CORNER_RADIUS.Round
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Thickness = 3
closeStroke.Color = PALETTE.AccentDark
closeStroke.Parent = closeBtn

-- ========================================
-- TAB NAVIGATION (Section 2.3)
-- ========================================

local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 60)
tabContainer.Position = UDim2.new(0, 0, 0, 90)
tabContainer.BackgroundTransparency = 1
tabContainer.ZIndex = 11
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 12)
tabLayout.Parent = tabContainer

-- Create tabs
local tabs = {}
local currentTab = nil

local TAB_DATA = {
	{id = "currency", name = "💰 Currency", icon = "💰"},
	{id = "gamepasses", name = "⭐ Game Passes", icon = "⭐"},
	{id = "featured", name = "✨ Featured", icon = "✨"},
}

for _, tabData in ipairs(TAB_DATA) do
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = tabData.id .. "Tab"
	tabBtn.Size = UDim2.fromOffset(160, 48)
	tabBtn.BackgroundColor3 = PALETTE.PanelFill
	tabBtn.Text = tabData.name
	tabBtn.TextColor3 = PALETTE.TextPrimary
	tabBtn.Font = FONTS.Button
	tabBtn.TextSize = 20
	tabBtn.AutoButtonColor = false
	tabBtn.Parent = tabContainer
	
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = CORNER_RADIUS.Button
	tabCorner.Parent = tabBtn
	
	local tabStroke = Instance.new("UIStroke")
	tabStroke.Thickness = 2
	tabStroke.Color = PALETTE.Accent
	tabStroke.Transparency = 0.5
	tabStroke.Parent = tabBtn
	
	tabs[tabData.id] = tabBtn
end

-- Content container
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -160)
contentFrame.Position = UDim2.new(0, 0, 0, 160)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.ZIndex = 10
contentFrame.Parent = mainFrame

local pages = {}

-- ========================================
-- CURRENCY PAGE
-- ========================================

local currencyPage = Instance.new("ScrollingFrame")
currencyPage.Name = "CurrencyPage"
currencyPage.Size = UDim2.fromScale(1, 1)
currencyPage.BackgroundTransparency = 1
currencyPage.ScrollBarThickness = 6
currencyPage.ScrollBarImageColor3 = PALETTE.AccentDark
currencyPage.BorderSizePixel = 0
currencyPage.CanvasSize = UDim2.new(0, 0, 0, 0)
currencyPage.Visible = false
currencyPage.Parent = contentFrame

local currencyPadding = Instance.new("UIPadding")
currencyPadding.PaddingAll = UDim.new(0, 12)
currencyPadding.Parent = currencyPage

local currencyGrid = Instance.new("UIGridLayout")
currencyGrid.CellSize = UDim2.new(1, -16, 0, 120)
currencyGrid.CellPadding = UDim2.fromOffset(12, 12)
currencyGrid.FillDirection = Enum.FillDirection.Horizontal
currencyGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
currencyGrid.SortOrder = Enum.SortOrder.LayoutOrder
currencyGrid.Parent = currencyPage

-- Create currency product cards
for i, product in ipairs(CURRENCY_PRODUCTS) do
	local card = Instance.new("Frame")
	card.Name = "Product" .. i
	card.BackgroundColor3 = PALETTE.PanelFill
	card.BorderSizePixel = 0
	card.LayoutOrder = i
	card.Parent = currencyPage
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = CORNER_RADIUS.Card
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 2
	cardStroke.Color = PALETTE.Accent
	cardStroke.Transparency = 0.4
	cardStroke.Parent = card
	
	-- Tag if exists (psychological nudge)
	if product.tag then
		local tagFrame = Instance.new("Frame")
		tagFrame.Size = UDim2.fromOffset(120, 28)
		tagFrame.Position = UDim2.new(1, -8, 0, 8)
		tagFrame.AnchorPoint = Vector2.new(1, 0)
		tagFrame.BackgroundColor3 = PALETTE[product.tagColor] or PALETTE.Accent
		tagFrame.ZIndex = 12
		tagFrame.Parent = card
		
		local tagCorner = Instance.new("UICorner")
		tagCorner.CornerRadius = CORNER_RADIUS.Button
		tagCorner.Parent = tagFrame
		
		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.fromScale(1, 1)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Text = product.tag
		tagLabel.TextColor3 = PALETTE.White
		tagLabel.Font = FONTS.Button
		tagLabel.TextSize = 14
		tagLabel.Parent = tagFrame
	end
	
	-- Card layout
	local cardLayout = Instance.new("UIListLayout")
	cardLayout.FillDirection = Enum.FillDirection.Horizontal
	cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	cardLayout.Padding = UDim.new(0, 16)
	cardLayout.Parent = card
	
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingAll = UDim.new(0, 16)
	cardPadding.Parent = card
	
	-- Icon background
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.fromOffset(80, 80)
	iconFrame.BackgroundColor3 = PALETTE.Accent
	iconFrame.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = CORNER_RADIUS.Button
	iconCorner.Parent = iconFrame
	
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Thickness = 2
	iconStroke.Color = PALETTE.AccentDark
	iconStroke.Parent = iconFrame
	
	local iconAspect = Instance.new("UIAspectRatioConstraint")
	iconAspect.AspectRatio = 1
	iconAspect.Parent = iconFrame
	
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Text = product.icon
	icon.TextColor3 = PALETTE.White
	icon.Font = FONTS.Header
	icon.TextSize = 36
	icon.Parent = iconFrame
	
	-- Info container
	local infoFrame = Instance.new("Frame")
	infoFrame.Size = UDim2.new(1, -200, 1, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent = card
	
	local infoLayout = Instance.new("UIListLayout")
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.Padding = UDim.new(0, 4)
	infoLayout.Parent = infoFrame
	
	-- Amount
	local amountLabel = Instance.new("TextLabel")
	amountLabel.Size = UDim2.new(1, 0, 0, 28)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = formatNumber(product.amount) .. " Cash"
	amountLabel.TextColor3 = PALETTE.TextPrimary
	amountLabel.Font = FONTS.Currency
	amountLabel.TextSize = 24
	amountLabel.TextXAlignment = Enum.TextXAlignment.Left
	amountLabel.Parent = infoFrame
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 0, 20)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = product.description
	descLabel.TextColor3 = PALETTE.TextPrimary
	descLabel.TextTransparency = 0.3
	descLabel.Font = FONTS.Body
	descLabel.TextSize = 16
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = infoFrame
	
	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.fromOffset(100, 48)
	buyBtn.BackgroundColor3 = PALETTE.Accent
	buyBtn.Text = "Buy"
	buyBtn.TextColor3 = PALETTE.White
	buyBtn.Font = FONTS.Button
	buyBtn.TextSize = 20
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = card
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = CORNER_RADIUS.Button
	buyCorner.Parent = buyBtn
	
	local buyStroke = Instance.new("UIStroke")
	buyStroke.Thickness = 3
	buyStroke.Color = PALETTE.AccentDark
	buyStroke.Parent = buyBtn
	
	local buyGradient = Instance.new("UIGradient")
	buyGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.Accent:lerp(PALETTE.White, 0.15)),
		ColorSequenceKeypoint.new(1, PALETTE.Accent)
	})
	buyGradient.Rotation = 90
	buyGradient.Parent = buyBtn
	
	local buyScale = Instance.new("UIScale")
	buyScale.Scale = 1
	buyScale.Parent = buyBtn
	
	-- Button animations
	track(buyBtn.MouseEnter:Connect(function()
		tween(buyScale, {Scale = 1.05}):Play()
		tween(buyBtn, {BackgroundColor3 = PALETTE.Accent:lerp(PALETTE.White, 0.1)}):Play()
	end))
	
	track(buyBtn.MouseLeave:Connect(function()
		tween(buyScale, {Scale = 1}):Play()
		tween(buyBtn, {BackgroundColor3 = PALETTE.Accent}):Play()
	end))
	
	track(buyBtn.MouseButton1Down:Connect(function()
		tween(buyScale, {Scale = 0.95}, MOTION.Quick, Enum.EasingStyle.Back):Play()
	end))
	
	track(buyBtn.MouseButton1Up:Connect(function()
		tween(buyScale, {Scale = 1}, MOTION.Bounce, Enum.EasingStyle.Elastic):Play()
		
		-- Trigger purchase
		MarketplaceService:PromptProductPurchase(player, product.id)
		
		-- Visual feedback
		buyBtn.Text = "💖"
		task.wait(0.5)
		buyBtn.Text = "Buy"
	end))
end

-- Update currency canvas
local function updateCurrencyCanvas()
	local contentSize = currencyGrid.AbsoluteContentSize
	currencyPage.CanvasSize = UDim2.fromOffset(contentSize.X, contentSize.Y + 24)
end
currencyGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCurrencyCanvas)
updateCurrencyCanvas()

pages["currency"] = currencyPage

-- ========================================
-- GAMEPASSES PAGE
-- ========================================

local gamepassPage = Instance.new("ScrollingFrame")
gamepassPage.Name = "GamepassPage"
gamepassPage.Size = UDim2.fromScale(1, 1)
gamepassPage.BackgroundTransparency = 1
gamepassPage.ScrollBarThickness = 6
gamepassPage.ScrollBarImageColor3 = PALETTE.AccentDark
gamepassPage.BorderSizePixel = 0
gamepassPage.CanvasSize = UDim2.new(0, 0, 0, 0)
gamepassPage.Visible = false
gamepassPage.Parent = contentFrame

local gamepassPadding = Instance.new("UIPadding")
gamepassPadding.PaddingAll = UDim.new(0, 12)
gamepassPadding.Parent = gamepassPage

local gamepassLayout = Instance.new("UIListLayout")
gamepassLayout.FillDirection = Enum.FillDirection.Vertical
gamepassLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gamepassLayout.Padding = UDim.new(0, 16)
gamepassLayout.SortOrder = Enum.SortOrder.LayoutOrder
gamepassLayout.Parent = gamepassPage

-- Create gamepass cards with real-time price fetching
for i, gamepass in ipairs(GAMEPASS_CONFIG) do
	local card = Instance.new("Frame")
	card.Name = "Gamepass" .. i
	card.Size = UDim2.new(1, -24, 0, 180)
	card.BackgroundColor3 = PALETTE.PanelFill
	card.BorderSizePixel = 0
	card.LayoutOrder = i
	card.Parent = gamepassPage
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = CORNER_RADIUS.Card
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 2
	cardStroke.Color = PALETTE.Accent
	cardStroke.Transparency = 0.4
	cardStroke.Parent = card
	
	-- Special gradient for gamepasses
	local cardGradient = Instance.new("UIGradient")
	cardGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, PALETTE.Accent:lerp(PALETTE.White, 0.9))
	})
	cardGradient.Rotation = 45
	cardGradient.Parent = card
	
	-- Tag if exists
	if gamepass.tag then
		local tagFrame = Instance.new("Frame")
		tagFrame.Size = UDim2.fromOffset(100, 28)
		tagFrame.Position = UDim2.new(1, -8, 0, 8)
		tagFrame.AnchorPoint = Vector2.new(1, 0)
		tagFrame.BackgroundColor3 = PALETTE[gamepass.tagColor] or PALETTE.Accent
		tagFrame.ZIndex = 12
		tagFrame.Parent = card
		
		local tagCorner = Instance.new("UICorner")
		tagCorner.CornerRadius = CORNER_RADIUS.Button
		tagCorner.Parent = tagFrame
		
		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.fromScale(1, 1)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Text = gamepass.tag
		tagLabel.TextColor3 = PALETTE.White
		tagLabel.Font = FONTS.Button
		tagLabel.TextSize = 14
		tagLabel.Parent = tagFrame
	end
	
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingAll = UDim.new(0, 20)
	cardPadding.Parent = card
	
	local cardContentLayout = Instance.new("UIListLayout")
	cardContentLayout.FillDirection = Enum.FillDirection.Vertical
	cardContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardContentLayout.Padding = UDim.new(0, 12)
	cardContentLayout.Parent = card
	
	-- Title row
	local titleRow = Instance.new("Frame")
	titleRow.Size = UDim2.new(1, 0, 0, 32)
	titleRow.BackgroundTransparency = 1
	titleRow.Parent = card
	
	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.Padding = UDim.new(0, 12)
	titleLayout.Parent = titleRow
	
	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.fromOffset(32, 32)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = gamepass.icon
	iconLabel.TextColor3 = PALETTE.AccentDark
	iconLabel.Font = FONTS.Header
	iconLabel.TextSize = 28
	iconLabel.Parent = titleRow
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -44, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = gamepass.name
	nameLabel.TextColor3 = PALETTE.TextPrimary
	nameLabel.Font = FONTS.Header
	nameLabel.TextSize = 24
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = titleRow
	
	-- Benefits list
	local benefitsFrame = Instance.new("Frame")
	benefitsFrame.Size = UDim2.new(1, 0, 0, 80)
	benefitsFrame.BackgroundTransparency = 1
	benefitsFrame.Parent = card
	
	local benefitsLayout = Instance.new("UIListLayout")
	benefitsLayout.FillDirection = Enum.FillDirection.Vertical
	benefitsLayout.Padding = UDim.new(0, 4)
	benefitsLayout.Parent = benefitsFrame
	
	for _, benefit in ipairs(gamepass.benefits) do
		local benefitLabel = Instance.new("TextLabel")
		benefitLabel.Size = UDim2.new(1, 0, 0, 20)
		benefitLabel.BackgroundTransparency = 1
		benefitLabel.Text = "• " .. benefit
		benefitLabel.TextColor3 = PALETTE.TextPrimary
		benefitLabel.TextTransparency = 0.1
		benefitLabel.Font = FONTS.Body
		benefitLabel.TextSize = 16
		benefitLabel.TextXAlignment = Enum.TextXAlignment.Left
		benefitLabel.Parent = benefitsFrame
	end
	
	-- Price and buy row
	local buyRow = Instance.new("Frame")
	buyRow.Size = UDim2.new(1, 0, 0, 48)
	buyRow.BackgroundTransparency = 1
	buyRow.Parent = card
	
	local buyLayout = Instance.new("UIListLayout")
	buyLayout.FillDirection = Enum.FillDirection.Horizontal
	buyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	buyLayout.Padding = UDim.new(0, 16)
	buyLayout.Parent = buyRow
	
	-- Price display
	local priceFrame = Instance.new("Frame")
	priceFrame.Size = UDim2.fromOffset(120, 48)
	priceFrame.BackgroundTransparency = 1
	priceFrame.Parent = buyRow
	
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.fromScale(1, 1)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "Loading..."
	priceLabel.TextColor3 = PALETTE.Success
	priceLabel.Font = FONTS.Currency
	priceLabel.TextSize = 28
	priceLabel.Parent = priceFrame
	
	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.fromOffset(140, 48)
	buyBtn.BackgroundColor3 = PALETTE.Success
	buyBtn.Text = "Get Now!"
	buyBtn.TextColor3 = PALETTE.White
	buyBtn.Font = FONTS.Button
	buyBtn.TextSize = 20
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = buyRow
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = CORNER_RADIUS.Button
	buyCorner.Parent = buyBtn
	
	local buyStroke = Instance.new("UIStroke")
	buyStroke.Thickness = 3
	buyStroke.Color = PALETTE.Success:lerp(Color3.new(0, 0, 0), 0.2)
	buyStroke.Parent = buyBtn
	
	local buyScale = Instance.new("UIScale")
	buyScale.Scale = 1
	buyScale.Parent = buyBtn
	
	-- Fetch real-time gamepass info
	spawn(function()
		local info = fetchGamepassInfo(gamepass.id)
		
		if info.owned then
			priceLabel.Text = "OWNED"
			priceLabel.TextColor3 = PALETTE.Success
			buyBtn.Text = "✓ Owned"
			buyBtn.BackgroundColor3 = PALETTE.Success:lerp(Color3.new(0, 0, 0), 0.3)
			buyBtn.Active = false
		else
			priceLabel.Text = "R$ " .. info.price
			
			-- Button interactions only if not owned
			track(buyBtn.MouseEnter:Connect(function()
				tween(buyScale, {Scale = 1.08}):Play()
			end))
			
			track(buyBtn.MouseLeave:Connect(function()
				tween(buyScale, {Scale = 1}):Play()
			end))
			
			track(buyBtn.MouseButton1Click:Connect(function()
				tween(buyScale, {Scale = 1.15}, MOTION.Elastic, Enum.EasingStyle.Elastic):Play()
				
				-- Prompt gamepass purchase
				MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
				
				wait(0.5)
				tween(buyScale, {Scale = 1}):Play()
			end))
		end
	end)
end

-- Update gamepass canvas
local function updateGamepassCanvas()
	local contentSize = gamepassLayout.AbsoluteContentSize
	gamepassPage.CanvasSize = UDim2.fromOffset(0, contentSize.Y + 24)
end
gamepassLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateGamepassCanvas)
updateGamepassCanvas()

pages["gamepasses"] = gamepassPage

-- ========================================
-- FEATURED PAGE
-- ========================================

local featuredPage = Instance.new("Frame")
featuredPage.Name = "FeaturedPage"
featuredPage.Size = UDim2.fromScale(1, 1)
featuredPage.BackgroundTransparency = 1
featuredPage.Visible = false
featuredPage.Parent = contentFrame

local comingSoon = Instance.new("TextLabel")
comingSoon.Size = UDim2.fromScale(1, 1)
comingSoon.BackgroundTransparency = 1
comingSoon.Text = "✨ Special offers coming soon! ✨\n\nCheck back for limited-time deals!"
comingSoon.TextColor3 = PALETTE.TextPrimary
comingSoon.Font = FONTS.Header
comingSoon.TextSize = 28
comingSoon.TextWrapped = true
comingSoon.Parent = featuredPage

pages["featured"] = featuredPage

-- ========================================
-- TAB SWITCHING
-- ========================================

local function switchTab(tabId)
	for id, tab in pairs(tabs) do
		if id == tabId then
			-- Active tab
			tween(tab, {
				BackgroundColor3 = PALETTE.Accent,
				TextColor3 = PALETTE.White
			}):Play()
			currentTab = id
		else
			-- Inactive tab
			tween(tab, {
				BackgroundColor3 = PALETTE.PanelFill,
				TextColor3 = PALETTE.TextPrimary
			}):Play()
		end
	end
	
	-- Show/hide pages
	for id, page in pairs(pages) do
		if id == tabId then
			page.Visible = true
			page.Position = UDim2.fromScale(0, 0)
			tween(page, {Position = UDim2.fromScale(0, 0)}, MOTION.Normal, Enum.EasingStyle.Quart):Play()
		else
			if page.Visible then
				tween(page, {Position = UDim2.fromScale(-1, 0)}, MOTION.Quick, Enum.EasingStyle.Quart):Play()
				task.wait(MOTION.Quick)
				page.Visible = false
			end
		end
	end
end

-- Connect tab buttons
for id, tab in pairs(tabs) do
	track(tab.MouseButton1Click:Connect(function()
		switchTab(id)
	end))
end

-- ========================================
-- TOGGLE BUTTON
-- ========================================

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.fromOffset(80, 80)
toggleBtn.Position = UDim2.new(1, -100, 1, -100)
toggleBtn.AnchorPoint = Vector2.new(1, 1)
toggleBtn.BackgroundColor3 = PALETTE.Accent
toggleBtn.Text = "💖"
toggleBtn.TextSize = 36
toggleBtn.Font = FONTS.Button
toggleBtn.TextColor3 = PALETTE.White
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 15
toggleBtn.Parent = gui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = CORNER_RADIUS.Round
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Thickness = 3
toggleStroke.Color = PALETTE.AccentDark
toggleStroke.Parent = toggleBtn

local toggleScale = Instance.new("UIScale")
toggleScale.Scale = 1
toggleScale.Parent = toggleBtn

-- Floating animation
spawn(function()
	while true do
		tween(toggleBtn, {Position = UDim2.new(1, -100, 1, -105)}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
		wait(2)
		tween(toggleBtn, {Position = UDim2.new(1, -100, 1, -95)}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
		wait(2)
	end
end)

-- ========================================
-- SHOW/HIDE ANIMATIONS
-- ========================================

local function showShop()
	overlay.Visible = true
	mainFrame.Visible = true
	
	-- Fade in overlay
	tween(overlay, {BackgroundTransparency = 0.3}, MOTION.Normal):Play()
	
	-- Scale in main frame
	local scale = mainFrame:FindFirstChild("UIScale") or Instance.new("UIScale")
	scale.Scale = 0.8
	scale.Parent = mainFrame
	
	tween(scale, {Scale = 1}, MOTION.Normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
	
	-- Default to currency tab
	switchTab("currency")
end

local function hideShop()
	-- Fade out overlay
	tween(overlay, {BackgroundTransparency = 1}, MOTION.Quick):Play()
	
	-- Scale out main frame
	local scale = mainFrame:FindFirstChild("UIScale")
	if scale then
		tween(scale, {Scale = 0.9}, MOTION.Quick, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
	end
	
	task.wait(MOTION.Quick)
	overlay.Visible = false
	mainFrame.Visible = false
end

-- Connect buttons
track(toggleBtn.MouseButton1Click:Connect(showShop))
track(closeBtn.MouseButton1Click:Connect(hideShop))
track(overlay.MouseButton1Click:Connect(hideShop))

-- Toggle button hover
track(toggleBtn.MouseEnter:Connect(function()
	tween(toggleScale, {Scale = 1.1}):Play()
end))

track(toggleBtn.MouseLeave:Connect(function()
	tween(toggleScale, {Scale = 1}):Play()
end))

-- Close button hover
track(closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, {BackgroundColor3 = PALETTE.Accent:lerp(PALETTE.White, 0.1)}):Play()
end))

track(closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, {BackgroundColor3 = PALETTE.Accent}):Play()
end))

-- ========================================
-- CLEANUP
-- ========================================

gui.Destroying:Connect(function()
	for _, conn in ipairs(connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
end)

-- ========================================
-- AUTO-COLLECT SUPPORT
-- ========================================

-- Listen for auto-collect status from server
local autoCollectRemote = ReplicatedStorage:WaitForChild("AutoCollectStatus", 5)
if autoCollectRemote then
	autoCollectRemote.OnClientEvent:Connect(function(enabled)
		-- Update UI to show auto-collect status
		if enabled then
			print("Auto-collect is active!")
		end
	end)
end

print("✨ Kawaii Money Shop Enhanced loaded! Theme:", CURRENT_THEME)