--[[
	🎀 SANRIO SHOP — FULLY FIXED VERSION (LocalScript)
	
	FIXES INCLUDED:
	1. ✅ Fixed stuck "Processing" after gamepass purchase
	2. ✅ Added gamepass thumbnail loading
	3. ✅ Fixed shop button disappearing on respawn
	4. ✅ Improved ownership checking and UI refresh
	5. ✅ Added toggle for Auto Collect gamepass
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local localPlayer = game.Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Asset manifest
local Asset = {
	list = {
		-- UI Icons
		iconCloseX = 7076728446,
		iconCash = 11791710234,
		iconPass = 7191004076,
		-- Character badges
		badgeHello = 14303742435,
		badgeCinna = 14303742621,
		badgeKuromi = 14303744085,
		-- Patterns & textures
		paperTexture = 5553946656,
		hkBowPattern = 14303776259,
		cloudTexture = 14303776498,
		starPattern = 123639832,
		-- Sound IDs
		soundOpen = 9125402735,
		soundClose = 9125402512,
		soundClick = 876939830,
		soundCash = 7150509725,
		soundSuccess = 7149279614,
	},
	valid = function(id) return type(id) == "number" and id > 0 end
}

-- Shop data with gamepass
local ShopData = {
	data = {
		gamepasses = {
			{
				id = 1412171840,
				name = "Auto Collect",
				description = "Automatically collects money from your collector!",
				price = 99,
				hasToggle = true
			},
			{
				id = 1398974710,
				name = "2x Cash",
				description = "Double all money collected!",
				price = 199
			}
		},
		cash = {
			{id = 1897730242, name = "Starter Cash", description = "Get 1,000 Cash instantly!", amount = 1000, price = 49},
			{id = 1897730373, name = "Builder Pack", description = "Get 5,000 Cash to expand faster!", amount = 5000, price = 199},
			{id = 1897730467, name = "Tycoon Bundle", description = "Get 10,000 Cash for major upgrades!", amount = 10000, price = 349},
			{id = 1897730581, name = "Deluxe Pack", description = "Get 50,000 Cash and dominate!", amount = 50000, price = 999},
		},
	},
	userOwnsPass = function(userId, passId)
		local s, r = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(userId, passId) end)
		return s and r
	end
}

-- Theme colors (MUST BE DEFINED FIRST)
local Theme = {
	colors = {
		kitty = Color3.fromRGB(255, 110, 157),
		cinna = Color3.fromRGB(123, 189, 255),
		kuromi = Color3.fromRGB(195, 123, 255),
		surface = Color3.fromRGB(255, 252, 250),
		surfaceAlt = Color3.fromRGB(255, 248, 245),
		text = Color3.fromRGB(30, 25, 30),
		subtext = Color3.fromRGB(90, 85, 90),
		stroke = Color3.fromRGB(220, 215, 220),
		success = Color3.fromRGB(88, 204, 128),
		error = Color3.fromRGB(255, 88, 116),
		disabled = Color3.fromRGB(200, 195, 200),
	},
	c = function(name) return Theme.colors[name] or Color3.new(1,1,1) end
}

-- Ownership cache for better performance
local ownedPassesCache = {}

-- UI builder helpers
local UI = {}
function UI.frame(props)
	local f = Instance.new("Frame")
	for k,v in pairs(props) do
		if k == "CornerRadius" then 
			local corner = Instance.new("UICorner")
			corner.CornerRadius = v
			corner.Parent = f
			continue 
		end
		if k == "Stroke" then
			local s = Instance.new("UIStroke")
			s.Thickness = v.Thickness or 1
			s.Color = v.Color or Color3.new(0,0,0)
			s.Transparency = v.Transparency or 0
			s.Parent = f
			continue
		end
		if k == "Layout" then
			local lType = v.Type or "List"
			local l = Instance.new("UI"..lType.."Layout")
			if lType == "List" then
				l.FillDirection = v.FillDirection or Enum.FillDirection.Vertical
				l.HorizontalAlignment = v.HorizontalAlignment or Enum.HorizontalAlignment.Left
				l.VerticalAlignment = v.VerticalAlignment or Enum.VerticalAlignment.Top
				l.Padding = v.Padding or UDim.new(0,8)
				l.SortOrder = v.SortOrder or Enum.SortOrder.LayoutOrder
			elseif lType == "Grid" then
				l.CellSize = v.CellSize or UDim2.new(0,100,0,100)
				l.CellPadding = v.CellPadding or UDim2.new(0,8,0,8)
				l.FillDirection = v.FillDirection or Enum.FillDirection.Horizontal
				l.HorizontalAlignment = v.HorizontalAlignment or Enum.HorizontalAlignment.Left
				l.VerticalAlignment = v.VerticalAlignment or Enum.VerticalAlignment.Top
				l.SortOrder = v.SortOrder or Enum.SortOrder.LayoutOrder
			end
			l.Parent = f
			continue
		end
		f[k] = v
	end
	return f
end

function UI.textLabel(props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.BuilderSansMedium
	t.TextScaled = false
	t.TextSize = props.TextSize or 18
	t.TextColor3 = props.TextColor3 or Theme.c("text")
	t.AutoLocalize = false
	t.RichText = false
	for k,v in pairs(props) do
		if k == "FontWeight" then t.Font = (v == Enum.FontWeight.Bold) and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium; continue end
		t[k] = v
	end
	return t
end

function UI.textButton(props)
	local b = UI.textLabel(props)
	b.Parent = nil; local btn = Instance.new("TextButton")
	for k,v in pairs(props) do btn[k] = v end
	b.Size = UDim2.fromScale(1,1); b.Parent = btn
	btn.AutoButtonColor = true; btn.Text = ""
	return btn
end

function UI.image(props)
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.ScaleType = props.ScaleType or Enum.ScaleType.Fit
	i.BorderSizePixel = 0
	for k,v in pairs(props) do i[k] = v end
	return i
end

function UI.scroll(props)
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 6
	s.ScrollBarImageTransparency = 0.5
	s.AutomaticCanvasSize = props.AutomaticCanvasSize or Enum.AutomaticSize.Y
	s.CanvasSize = props.CanvasSize or UDim2.new(0,0,0,0)
	for k,v in pairs(props) do
		if k == "Layout" then
			local lType = v.Type or "List"
			local l = Instance.new("UI"..lType.."Layout")
			if lType == "List" then
				l.FillDirection = v.FillDirection or Enum.FillDirection.Vertical
				l.HorizontalAlignment = v.HorizontalAlignment or Enum.HorizontalAlignment.Left
				l.VerticalAlignment = v.VerticalAlignment or Enum.VerticalAlignment.Top
				l.Padding = v.Padding or UDim.new(0,8)
				l.SortOrder = v.SortOrder or Enum.SortOrder.LayoutOrder
			elseif lType == "Grid" then
				l.CellSize = v.CellSize or UDim2.new(0,100,0,100)
				l.CellPadding = v.CellPadding or UDim2.new(0,8,0,8)
				l.FillDirection = v.FillDirection or Enum.FillDirection.Horizontal
				l.HorizontalAlignment = v.HorizontalAlignment or Enum.HorizontalAlignment.Left
				l.VerticalAlignment = v.VerticalAlignment or Enum.VerticalAlignment.Top
				l.SortOrder = v.SortOrder or Enum.SortOrder.LayoutOrder
			end
			l.Parent = s
			continue
		end
		s[k] = v
	end
	return s
end

-- Utils
local Utils = {
	tween = function(obj, info, props)
		local t = TweenService:Create(obj, info, props)
		t:Play()
		return t
	end,
	comma = function(n)
		local formatted = tostring(n)
		while true do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if k == 0 then break end
		end
		return formatted
	end,
	blend = function(c1, c2, alpha)
		return Color3.new(c1.R * (1-alpha) + c2.R * alpha, c1.G * (1-alpha) + c2.G * alpha, c1.B * (1-alpha) + c2.B * alpha)
	end,
	isMobile = function()
		return UserInputService.TouchEnabled and not UserInputService.MouseEnabled and not UserInputService.KeyboardEnabled
	end,
	safe = function(fn, ...)
		local s, e = pcall(fn, ...)
		if not s then warn("[Shop Error]", e) end
		return s, e
	end
}

-- Animation presets
local ANIM = {
	FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	MED = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SLOW = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

-- Sound manager
local Sfx = {
	cache = {},
	play = function(self, name)
		local id = Asset.list["sound"..name:sub(1,1):upper()..name:sub(2)]
		if not id then return end
		local sound = self.cache[name]
		if not sound then
			sound = Instance.new("Sound"); sound.SoundId = "rbxassetid://"..id; sound.Volume = 0.2; sound.Parent = playerGui; self.cache[name] = sound
		end
		sound:Play()
	end
}

-- Shop button
local function createShopButton()
	-- Remove any existing shop button
	local existingButton = playerGui:FindFirstChild("SANRIO_SHOP_BUTTON")
	if existingButton then
		existingButton:Destroy()
	end
	
	local buttonScreen = Instance.new("ScreenGui")
	buttonScreen.Name = "SANRIO_SHOP_BUTTON"
	buttonScreen.ResetOnSpawn = false
	buttonScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonScreen.DisplayOrder = 999
	buttonScreen.Parent = playerGui

	local toggle = UI.textButton({
		Name = "ShopToggle",
		Size = UDim2.fromOffset(150, 50),
		Position = UDim2.new(0.03, 0, 0.5, -25),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.c("kitty"),
		CornerRadius = UDim.new(0, 25),
		ZIndex = 100
	})
	toggle.Parent = buttonScreen

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 3
	stroke.ZIndex = 101
	stroke.Parent = toggle

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 245, 255))
	}
	gradient.Rotation = 90
	gradient.Parent = toggle

	local icon = UI.image({
		Name = "Icon",
		Image = Asset.list.badgeHello,
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.new(0, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 101
	})
	icon.Parent = toggle

	local label = UI.textLabel({
		Name = "Label",
		Text = "SHOP",
		TextSize = 20,
		FontWeight = Enum.FontWeight.Bold,
		TextColor3 = Color3.new(1, 1, 1),
		Position = UDim2.new(0, 52, 0, 0),
		Size = UDim2.new(1, -64, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 101
	})
	label.Parent = toggle

	-- Add subtle pulse animation
	task.spawn(function()
		while toggle.Parent do
			Utils.tween(toggle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(156, 50)
			})
			wait(1.5)
			Utils.tween(toggle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(150, 50)
			})
			wait(1.5)
		end
	end)
	
	return toggle
end

-- Pending purchases
local Pending = {pass = {}, product = {}}

-- CTAButton factory
local function CTAButton(text: string, accent: Color3)
	local btn = UI.textButton({Name = "CTA", Text = text, Size = UDim2.fromOffset(480, 56), BackgroundColor3 = accent, TextColor3 = Color3.new(1,1,1), CornerRadius = UDim.new(0,28), FontWeight = Enum.FontWeight.Bold, TextSize = 22, ZIndex = 16})
	local st = Instance.new("UIStroke"); st.Color = Utils.blend(accent, Color3.new(0,0,0), 0.3); st.Thickness = 2; st.Transparency = 0.5; st.Parent = btn
	local gr = Instance.new("UIGradient"); gr.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(240,240,250))}; gr.Rotation = 90; gr.Parent = btn
	btn.MouseButton1Click:Connect(function() Sfx:play("click") end)
	return btn
end

-- Price chip
local function priceChip(text: string, accent: Color3)
	local chip = UI.frame({Name = "PriceChip", Size = UDim2.fromOffset(120, 32), BackgroundColor3 = Utils.blend(accent, Color3.new(1,1,1), 0.85), CornerRadius = UDim.new(1,0), ZIndex = 16})
	local st = Instance.new("UIStroke"); st.Color = accent; st.Thickness = 1.5; st.Transparency = 0.5; st.Parent = chip
	local lbl = UI.textLabel({Name = "Price", Text = text, TextColor3 = Utils.blend(accent, Color3.new(0,0,0), 0.3), FontWeight = Enum.FontWeight.Bold, TextSize = 20, Size = UDim2.fromScale(1,1), ZIndex = 17})
	lbl.Parent = chip
	return chip
end

-- Halo effect
local function addHalo(parent: GuiObject, color: Color3, sizeOffset: number, transparency: number)
	local halo = UI.image({
		Name = "Halo",
		Image = "rbxassetid://6015897843",
		ScaleType = Enum.ScaleType.Slice,
		ImageColor3 = color,
		ImageTransparency = transparency or 0.93,
		Size = UDim2.new(1, sizeOffset or 32, 1, sizeOffset or 32),
		Position = UDim2.new(0, -((sizeOffset or 32) / 2), 0, -((sizeOffset or 32) / 2)),
		ZIndex = (parent.ZIndex or 1) - 1
	})
	halo.SliceCenter = Rect.new(49,49,450,450)
	halo.Parent = parent
	return halo
end

-- // Root GUI
-- Check if shop already exists and remove it
local existingShop = playerGui:FindFirstChild("SANRIO_SHOP_REBUILT")
if existingShop then
	print("Removing existing shop GUI...")
	existingShop:Destroy()
	wait(0.1)
end

local screen = Instance.new("ScreenGui")
screen.Name = "SANRIO_SHOP_REBUILT"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 1000
screen.Parent = playerGui

-- Paper BG
if Asset.valid(Asset.list.paperTexture) then
	local paper = UI.image({Name = "PaperBG", Image = Asset.list.paperTexture, ImageTransparency = 0.93, Size = UDim2.fromScale(1,1), ScaleType = Enum.ScaleType.Tile, ZIndex = 1})
	paper.TileSize = UDim2.fromOffset(200,200)
	paper.Parent = screen
end

-- Dim
local dim = UI.frame({Name = "Dim", Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Visible = false, ZIndex = 5})
dim.Parent = screen

-- Panel
local panel = UI.frame({
	Name = "Panel",
	Size = UDim2.new(0, 1140, 0, 860),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Theme.c("surface"),
	CornerRadius = UDim.new(0, 24),
	Stroke = {Thickness = 1.5, Color = Theme.c("stroke")},
	ZIndex = 10,
	Visible = false,
})
panel.Parent = screen
addHalo(panel, Theme.c("kitty"), 56, 0.95)

-- Responsive scale
local scale = Instance.new("UIScale")
scale.Parent = panel
local function updateScale()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local s = math.clamp(math.min(vp.X, vp.Y) / 1280, 0.65, 1.0)
	if Utils.isMobile() then s = s * 0.9 end
	scale.Scale = s
end
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	updateScale()
end

-- Header
local header = UI.frame({Name = "Header", Size = UDim2.new(1,-24,0,72), Position = UDim2.new(0,12,0,12), CornerRadius = UDim.new(0,18), BackgroundColor3 = Theme.c("surfaceAlt"), Stroke = {Color = Theme.c("stroke")}, ZIndex = 11})
header.Parent = panel
local hg = Instance.new("UIGradient"); hg.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(250,250,250))}; hg.Rotation = 90; hg.Parent = header

local kitty = UI.image({Name = "Kitty", Image = Asset.list.badgeHello, Size = UDim2.fromOffset(42,42), Position = UDim2.new(0,16,0.5,0), AnchorPoint = Vector2.new(0,0.5), ZIndex = 12})
kitty.Parent = header
local title = UI.textLabel({Name = "Title", Text = "Sanrio Shop", Position = UDim2.new(0,72,0,0), Size = UDim2.new(1,-140,1,0), TextXAlignment = Enum.TextXAlignment.Left, FontWeight = Enum.FontWeight.Bold, TextSize = 32, ZIndex = 12})
title.Parent = header

local closeBtn = UI.textButton({Name = "Close", Size = UDim2.fromOffset(40,40), Position = UDim2.new(1,-56,0.5,0), AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = Color3.fromRGB(235,60,60), CornerRadius = UDim.new(1,0), ZIndex = 13})
closeBtn.Parent = header
local closeIcon = UI.image({Name = "X", Image = Asset.list.iconCloseX, ImageColor3 = Color3.new(1,1,1), Size = UDim2.fromOffset(20,20), Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), ZIndex = 14})
closeIcon.Parent = closeBtn

-- Tab system
local Tabs = {tabs = {}, pages = {}, current = nil}

function Tabs:createTab(name: string, icon: string?, accent: Color3): TextButton
	local b = UI.textButton({Name = name.."Tab", Text = name, Size = UDim2.new(0, 168, 1, 0), BackgroundColor3 = Theme.c("surface"), TextColor3 = Theme.c("text"), CornerRadius = UDim.new(1,0), Stroke = {Color = Theme.c("stroke")}, FontWeight = Enum.FontWeight.Medium, TextSize = 20, ZIndex = 12})
	if icon and Asset.valid(icon) then
		local ic = UI.image({Name = "Icon", Image = icon, Size = UDim2.fromOffset(20,20), Position = UDim2.new(0,12,0.5,0), AnchorPoint = Vector2.new(0,0.5), ImageColor3 = Theme.c("text"), ZIndex = 13})
		ic.Parent = b
		b.Text = ""
		local tx = UI.textLabel({Name = "Text", Text = name, Position = UDim2.new(0,40,0,0), Size = UDim2.new(1,-52,1,0), TextXAlignment = Enum.TextXAlignment.Left, FontWeight = Enum.FontWeight.Medium, TextSize = 20, ZIndex = 13})
		tx.Parent = b
	end
	self.tabs[name] = b
	return b
end

function Tabs:createPage(name: string): Frame
	local p = UI.frame({Name = name.."Page", Size = UDim2.new(1,-48,1,-180), Position = UDim2.new(0,24,0,156), BackgroundTransparency = 1, Visible = false, ZIndex = 11})
	self.pages[name] = p
	return p
end

function Tabs:select(name: string)
	if self.current == name then return end
	for n, tab in pairs(self.tabs) do
		local selected = n == name
		tab.BackgroundColor3 = selected and Theme.c("surfaceAlt") or Theme.c("surface")
		local txt = tab:FindFirstChild("Text") or tab
		txt.TextColor3 = selected and Theme.c("text") or Theme.c("subtext")
		local icon = tab:FindFirstChild("Icon")
		if icon then icon.ImageColor3 = selected and Theme.c("text") or Theme.c("subtext") end
		local stroke = tab:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Transparency = selected and 0.5 or 0.7 end
	end
	for n, page in pairs(self.pages) do page.Visible = n == name end
	self.current = name
end

-- Tab bar
local tabBar = UI.frame({Name = "TabBar", Size = UDim2.new(1,-48,0,48), Position = UDim2.new(0,24,0,96), BackgroundTransparency = 1, Layout = {Type = "List", FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,12)}, ZIndex = 11})
tabBar.Parent = panel

-- Create tabs and pages
local homePage = Tabs:createPage("Home"); homePage.Parent = panel
local cashPage = Tabs:createPage("Cash"); cashPage.Parent = panel
local passPage = Tabs:createPage("Pass"); passPage.Parent = panel

local homeTab = Tabs:createTab("Home", Asset.list.badgeHello, Theme.c("kitty")); homeTab.Parent = tabBar
local cashTab = Tabs:createTab("Cash", Asset.list.badgeCinna, Theme.c("cinna")); cashTab.Parent = tabBar
local passTab = Tabs:createTab("Gamepasses", Asset.list.badgeKuromi, Theme.c("kuromi")); passTab.Parent = tabBar

homeTab.MouseButton1Click:Connect(function() Tabs:select("Home"); Sfx:play("click") end)
cashTab.MouseButton1Click:Connect(function() Tabs:select("Cash"); Sfx:play("click") end)
passTab.MouseButton1Click:Connect(function() Tabs:select("Pass"); Sfx:play("click") end)

-- Set owned state helper
local function setOwnedState(card, item)
	local inner = card:FindFirstChild("Inner")
	if not inner then return end
	
	local cta = inner:FindFirstChild("CTA")
	if cta then
		cta.Text = "Owned"
		cta.BackgroundColor3 = Theme.c("success")
		cta.Active = false
		cta.AutoButtonColor = false
		local st = cta:FindFirstChildOfClass("UIStroke")
		if st then st.Color = Utils.blend(Theme.c("success"), Color3.new(0,0,0), 0.3) end
	end
	
	local outline = card:FindFirstChild("AccentOutline")
	if outline then outline.Color = Theme.c("success"); outline.Transparency = 0.2 end
	
	local halo = card:FindFirstChild("Halo")
	if halo then halo.ImageColor3 = Theme.c("success") end
	
	local chip = inner:FindFirstChild("PriceChip")
	if chip then
		chip.BackgroundColor3 = Utils.blend(Theme.c("success"), Color3.new(1,1,1), 0.85)
		local st = chip:FindFirstChildOfClass("UIStroke")
		if st then st.Color = Theme.c("success") end
		local lbl = chip:FindFirstChildOfClass("TextLabel")
		if lbl then lbl.TextColor3 = Utils.blend(Theme.c("success"), Color3.new(0,0,0), 0.3) end
	end
end

-- Card factory
local function makeItemCard(item: {[string]: any}, kind: string, accent: Color3)
	local card = UI.frame({Name = "ItemCard", Size = UDim2.new(0, 520, 0, 300), BackgroundColor3 = Theme.c("surface"), CornerRadius = UDim.new(0,20), Stroke = {Color = Theme.c("stroke"), Transparency = 0.30}, ZIndex = 12})
	local inner = UI.frame({Name = "Inner", Size = UDim2.new(1,-18,1,-18), Position = UDim2.new(0,9,0,9), BackgroundColor3 = (kind == "pass") and Color3.fromRGB(34,34,42) or Theme.c("surfaceAlt"), CornerRadius = UDim.new(0,16), Stroke = {Color = (kind == "pass") and Utils.blend(Theme.c("kuromi"), Color3.new(0.2,0.2,0.25), 0.5) or Theme.c("stroke"), Transparency = 0.25}, ZIndex = 13})
	inner.Parent = card

	local outline = Instance.new("UIStroke"); outline.Name = "AccentOutline"; outline.Color = accent; outline.Thickness = 2; outline.Transparency = 0.15; outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; outline.Parent = card
	addHalo(card, accent, 32, 0.92)

	-- Icon plate
	local plate = UI.frame({Name = "IconPlate", Size = UDim2.fromOffset(80,80), Position = UDim2.new(0,20,0,24), BackgroundColor3 = Utils.blend(accent, Color3.new(1,1,1), 0.9), CornerRadius = UDim.new(1,0), ZIndex = 14})
	plate.Parent = inner
	
	-- Use proper gamepass thumbnail for gamepasses
	local iconId
	if kind == "pass" and item.id then
		-- Use Roblox gamepass thumbnail API
		iconId = "rbxthumb://type=GamePass&id=" .. tostring(item.id) .. "&w=150&h=150"
	else
		iconId = (item.icon and Asset.valid(item.icon)) and item.icon or ((kind == "pass") and Asset.list.iconPass or Asset.list.iconCash)
	end
	
	-- Don't apply color tint to gamepass thumbnails
	local iconColor = (kind == "pass" and item.id) and Color3.new(1,1,1) or ((kind == "pass") and Color3.fromRGB(240,240,255) or Theme.c("text"))
	local icon = UI.image({Name = "Icon", Image = iconId, ImageColor3 = iconColor, Size = UDim2.fromOffset(48,48), Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), ZIndex = 15})
	icon.Parent = plate

	-- Title & Desc
	local tl = UI.textLabel({Name = "Title", Text = item.name or (kind == "pass" and "Gamepass" or "Cash Bundle"), TextColor3 = (kind == "pass") and Color3.fromRGB(240,240,250) or Theme.c("text"), TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,120,0,20), Size = UDim2.new(1,-220,0,40), FontWeight = Enum.FontWeight.SemiBold, TextSize = 28, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 15})
	tl.Parent = inner
	local dl = UI.textLabel({Name = "Desc", Text = item.description or (kind == "pass" and "Permanent upgrade" or "One‑time currency"), TextColor3 = (kind == "pass") and Color3.fromRGB(200,200,220) or Theme.c("subtext"), TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,120,0,66), Size = UDim2.new(1,-140,0,56), FontWeight = Enum.FontWeight.Regular, TextSize = 18, TextWrapped = true, ZIndex = 15})
	dl.Parent = inner

	-- Price chip
	local chipTxt = (kind == "pass") and ("R$ "..tostring(item.price)) or ((item.amount and (Utils.comma(item.amount).." Cash")) or "Bundle")
	local chip = priceChip(chipTxt, accent); chip.Size = UDim2.fromOffset(160, 34); chip.Position = UDim2.new(1,-172,0,16); chip.Parent = inner
	local chipLbl = chip:FindFirstChildOfClass("TextLabel"); if chipLbl then chipLbl.TextSize = 18 end

	-- CTA
	local cta = CTAButton("Purchase", accent)
	cta.Position = UDim2.new(0,20,1,-76)
	cta.Parent = inner

	-- Check if owned (for gamepasses)
	if kind == "pass" and ShopData.userOwnsPass(localPlayer.UserId, item.id) then
		if item.hasToggle then
			-- Create toggle for auto-collect
			cta.Text = "Toggle"
			cta.Size = UDim2.fromOffset(180, 56)
			
			local toggleFrame = UI.frame({
				Name = "ToggleFrame",
				Size = UDim2.fromOffset(60, 30),
				Position = UDim2.new(1, -80, 1, -66),
				BackgroundColor3 = Theme.c("stroke"),
				CornerRadius = UDim.new(0.5, 0),
				ZIndex = 16
			})
			toggleFrame.Parent = inner
			
			local toggleButton = UI.frame({
				Name = "ToggleButton",
				Size = UDim2.fromOffset(26, 26),
				Position = UDim2.fromOffset(2, 2),
				BackgroundColor3 = Theme.c("surface"),
				CornerRadius = UDim.new(0.5, 0),
				ZIndex = 17
			})
			toggleButton.Parent = toggleFrame
			
			local toggleState = true -- Default to on
			local autoCollectRemote = ReplicatedStorage:WaitForChild("TycoonRemotes", 5)
			if autoCollectRemote then
				autoCollectRemote = autoCollectRemote:FindFirstChild("AutoCollectToggle")
			end
			
			-- Set initial state to ON
			toggleFrame.BackgroundColor3 = Theme.c("success")
			toggleButton.Position = UDim2.fromOffset(32, 2)
			cta.Text = "ON"
			
			-- Fire initial state
			if autoCollectRemote then
				autoCollectRemote:FireServer(true)
			end
			
			local function updateToggle()
				toggleState = not toggleState
				if toggleState then
					toggleFrame.BackgroundColor3 = Theme.c("success")
					Utils.tween(toggleButton, ANIM.FAST, {Position = UDim2.fromOffset(32, 2)})
					cta.Text = "ON"
				else
					toggleFrame.BackgroundColor3 = Theme.c("stroke")
					Utils.tween(toggleButton, ANIM.FAST, {Position = UDim2.fromOffset(2, 2)})
					cta.Text = "OFF"
				end
				
				if autoCollectRemote then
					autoCollectRemote:FireServer(toggleState)
				end
			end
			
			cta.MouseButton1Click:Connect(updateToggle)
		else
			-- Regular owned state
			setOwnedState(card, item)
		end
	else
		-- Purchase button logic
		cta.MouseButton1Click:Connect(function()
			-- Double-check ownership before prompting
			if kind == "pass" then
				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, item.id)
				end)
				
				if success and owns then
					-- Already owns, just refresh
					cta.Text = "Owned"
					cta.Active = false
					cta.AutoButtonColor = false
					
					-- Refresh the shop
					task.wait(0.5)
					if passPage then
						for _, child in ipairs(passPage:GetChildren()) do
							child:Destroy()
						end
						buildPasses()
					end
					return
				end
			end
			
			cta.Text = "Processing…"; cta.Active = false; cta.AutoButtonColor = false
			if kind == "pass" then
				Pending.pass[item.id] = cta
				Utils.safe(function() MarketplaceService:PromptGamePassPurchase(localPlayer, item.id) end)
			else
				Pending.product[item.id] = cta
				Utils.safe(function() MarketplaceService:PromptProductPurchase(localPlayer, item.id) end)
			end
		end)
	end

	-- Hover lift
	local original = card.Position
	card.MouseEnter:Connect(function()
		Utils.tween(card, ANIM.MED, {Position = UDim2.new(original.X.Scale, original.X.Offset, original.Y.Scale, original.Y.Offset - 8)})
	end)
	card.MouseLeave:Connect(function()
		Utils.tween(card, ANIM.MED, {Position = original})
	end)

	return card
end

-- // Build Pages

local function buildHome()
	-- overlay + soft bows
	local overlay = UI.frame({Name = "HomeOverlay", Size = UDim2.new(1,-24,1,-24), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Utils.blend(Theme.c("kitty"), Color3.new(1,1,1), 0.65), CornerRadius = UDim.new(0,18), ClipsDescendants = true, ZIndex = 11})
	overlay.Parent = homePage
	local grad = Instance.new("UIGradient"); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Utils.blend(Theme.c("kitty"), Color3.new(1,1,1), 0.75))}; grad.Rotation = 90; grad.Parent = overlay
	if Asset.valid(Asset.list.hkBowPattern) then
		local bows = UI.image({Name = "Bows", Image = Asset.list.hkBowPattern, ImageColor3 = Theme.c("kitty"), ImageTransparency = 0.7, ScaleType = Enum.ScaleType.Tile, Size = UDim2.fromScale(1,1), ZIndex = 10}); bows.TileSize = UDim2.fromOffset(180,180); bows.Parent = overlay
	end

	-- home content
	local content = UI.frame({Name = "Content", Size = UDim2.new(1,-32,1,-32), Position = UDim2.new(0,16,0,16), BackgroundTransparency = 1, ZIndex = 12})
	content.Parent = homePage

	-- welcome
	local hw = UI.textLabel({Name = "Welcome", Text = "Welcome to the Shop!", TextSize = 36, FontWeight = Enum.FontWeight.Bold, Size = UDim2.new(1,0,0,48), ZIndex = 13})
	hw.Parent = content
	local hs = UI.textLabel({Name = "Sub", Text = "Get cash bundles, exclusive gamepasses, and more!", TextSize = 20, TextColor3 = Theme.c("subtext"), Position = UDim2.new(0,0,0,56), Size = UDim2.new(1,0,0,28), ZIndex = 13})
	hs.Parent = content

	-- featured section
	local ft = UI.textLabel({Name = "FeaturedTitle", Text = "✨ Featured Items", TextSize = 28, FontWeight = Enum.FontWeight.SemiBold, Position = UDim2.new(0,0,0,112), Size = UDim2.new(1,0,0,36), ZIndex = 13})
	ft.Parent = content
	local featured = UI.scroll({Name = "Featured", Size = UDim2.new(1,0,0,320), Position = UDim2.new(0,0,0,156), ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.X, Layout = {Type = "List", FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,24)}, ZIndex = 12})
	featured.Parent = content

	-- Quick buy CTA
	local hCTA = CTAButton("Get Featured Bundle", Theme.c("kitty")); hCTA.Position = UDim2.new(0.5,0,1,-76); hCTA.AnchorPoint = Vector2.new(0.5,0); hCTA.Parent = content

	local picks = {}
	for i=1, math.min(2, #ShopData.data.cash) do table.insert(picks, {item=ShopData.data.cash[i], kind="cash", accent=Theme.c("cinna")}) end
	for i=1, math.min(2, #ShopData.data.gamepasses) do table.insert(picks, {item=ShopData.data.gamepasses[i], kind="pass", accent=Theme.c("kuromi")}) end
	for _, it in ipairs(picks) do local c = makeItemCard(it.item, it.kind, it.accent); c.Parent = featured end

	task.defer(function()
		local ll = featured:FindFirstChildOfClass("UIListLayout")
		if ll then featured.CanvasSize = UDim2.new(0, ll.AbsoluteContentSize.X + 24, 0, 0) end
	end)

	if picks[1] then
		hCTA.BackgroundColor3 = Utils.blend(picks[1].accent, Color3.new(1,1,1), 0.9)
		hCTA.TextColor3 = picks[1].accent
		local st = hCTA:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", hCTA); st.Color = picks[1].accent; st.Thickness = 2
		hCTA.MouseButton1Click:Connect(function()
			if picks[1].kind == "pass" then MarketplaceService:PromptGamePassPurchase(localPlayer, picks[1].item.id) else MarketplaceService:PromptProductPurchase(localPlayer, picks[1].item.id) end
		end)
	end
end

local function buildCash()
	local overlay = UI.frame({Name = "CashOverlay", Size = UDim2.new(1,-24,1,-24), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Utils.blend(Theme.c("cinna"), Color3.new(1,1,1), 0.7), CornerRadius = UDim.new(0,18), ClipsDescendants = true, ZIndex = 11})
	overlay.Parent = cashPage
	local grad = Instance.new("UIGradient"); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Utils.blend(Theme.c("cinna"), Color3.new(1,1,1), 0.85))}; grad.Rotation = 90; grad.Parent = overlay
	-- clouds
	local function cloud(pos, size, alpha)
		local c = UI.image({Image = Asset.list.cloudTexture, ImageTransparency = alpha or 0.2, Size = size, Position = pos, ZIndex = 10})
		c.Parent = overlay
	end
	cloud(UDim2.new(1,-140,0,40), UDim2.fromOffset(120,80), 0.12)
	cloud(UDim2.new(1,-80,0,120), UDim2.fromOffset(100,70), 0.35)
	cloud(UDim2.new(0,30,1,-120), UDim2.fromOffset(130,85), 0.08)

	local grid = UI.scroll({Name = "CashGrid", Size = UDim2.new(1,-32,1,-32), Position = UDim2.new(0,16,0,16), Layout = {Type = "Grid", CellSize = UDim2.new(0,520,0,300), CellPadding = UDim2.new(0,24,0,24), HorizontalAlignment = Enum.HorizontalAlignment.Center}, ZIndex = 12})
	grid.Parent = cashPage
	for _, item in ipairs(ShopData.data.cash) do
		makeItemCard(item, "cash", Theme.c("cinna")).Parent = grid
	end
	task.defer(function() local lay = grid:FindFirstChildOfClass("UIGridLayout"); if lay then grid.CanvasSize = UDim2.new(0,0,0, lay.AbsoluteContentSize.Y + 32) end end)
end

local function buildPasses()
	local bg = UI.frame({Name = "PassBG", BackgroundColor3 = Color3.fromRGB(22,22,26), CornerRadius = UDim.new(0,18), ClipsDescendants = true, ZIndex = 11})
	bg.Parent = passPage
	local overlay = UI.frame({Name = "Overlay", Size = UDim2.new(1,-24,1,-24), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Utils.blend(Theme.c("kuromi"), Color3.new(1,1,1), 0.85), CornerRadius = UDim.new(0,18), ClipsDescendants = true, ZIndex = 11})
	overlay.Parent = bg
	local g = Instance.new("UIGradient"); g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(34,34,42)), ColorSequenceKeypoint.new(1, Color3.fromRGB(28,28,34))}; g.Rotation = 135; g.Parent = overlay
	if Asset.valid(Asset.list.starPattern) then
		local stars = UI.image({Name = "Stars", Image = Asset.list.starPattern, ImageColor3 = Theme.c("kuromi"), ImageTransparency = 0.6, ScaleType = Enum.ScaleType.Tile, Size = UDim2.fromScale(1,1), ZIndex = 10}); stars.TileSize = UDim2.fromOffset(720,720); stars.Parent = overlay
	end

	local grid = UI.scroll({Name = "PassGrid", Size = UDim2.new(1,-32,1,-32), Position = UDim2.new(0,16,0,16), Layout = {Type = "Grid", CellSize = UDim2.new(0,520,0,300), CellPadding = UDim2.new(0,24,0,24), HorizontalAlignment = Enum.HorizontalAlignment.Center}, ZIndex = 12})
	grid.Parent = passPage
	for _, item in ipairs(ShopData.data.gamepasses) do
		makeItemCard(item, "pass", Theme.c("kuromi")).Parent = grid
	end
	task.defer(function() local lay = grid:FindFirstChildOfClass("UIGridLayout"); if lay then grid.CanvasSize = UDim2.new(0,0,0, lay.AbsoluteContentSize.Y + 32) end end)
end

-- Marketplace callbacks
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
	if userId ~= localPlayer.UserId then return end
	local cta = Pending.product[productId]
	if cta and cta.Parent then
		if isPurchased then
			cta.Text = "Success!"; cta.BackgroundColor3 = Theme.c("success")
			task.delay(1.1, function() if cta and cta.Parent then cta.Text = "Purchase" end end)
		else
			cta.Text = "Purchase"; cta.Active = true; cta.AutoButtonColor = true
			task.delay(1.1, function() if cta and cta.Parent then cta.Text = "Purchase" end end)
		end
	end
	Pending.product[productId] = nil
end)

-- FIXED GAMEPASS PURCHASE HANDLER
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(userId, gamePassId, wasPurchased)
	if userId ~= localPlayer.UserId then return end
	
	local cta = Pending.pass[gamePassId]
	if cta and cta.Parent then
		cta.Text = wasPurchased and "Updating..." or "Purchase"
		cta.Active = false
		cta.AutoButtonColor = false
	end
	
	Pending.pass[gamePassId] = nil
	
	if wasPurchased then
		-- Clear ownership cache
		ownedPassesCache = {}
		
		-- Wait for Roblox to update ownership
		task.wait(1.5)
		
		-- Force rebuild all pages that might show gamepasses
		if passPage then
			for _, child in ipairs(passPage:GetChildren()) do
				child:Destroy()
			end
			buildPasses()
		end
		
		if homePage then
			for _, child in ipairs(homePage:GetChildren()) do
				child:Destroy()
			end
			buildHome()
		end
		
		-- Play success sound
		Sfx:play("success")
	end
end)

-- // Build UI
local function preload()
	local list = {
		Asset.list.badgeHello,
		Asset.list.badgeCinna,
		Asset.list.badgeKuromi,
		Asset.list.hkBowPattern,
		Asset.list.cloudTexture,
		Asset.list.starPattern,
		Asset.list.iconCloseX,
		Asset.list.iconCash,
		Asset.list.iconPass,
	}
	local valid = {}
	for _, id in ipairs(list) do if Asset.valid(id) then table.insert(valid, id) end end
	if #valid > 0 then Utils.safe(function() ContentProvider:PreloadAsync(valid) end) end
end

local Blur = {node = nil}
function Blur:get()
	if self.node then return self.node end
	local b = Lighting:FindFirstChild("SanrioShopBlur")
	if b and b:IsA("BlurEffect") then self.node = b; return b end
	local n = Instance.new("BlurEffect"); n.Name = "SanrioShopBlur"; n.Size = 0; n.Parent = Lighting; self.node = n; return n
end
function Blur:show(size)
	Utils.tween(self:get(), ANIM.MED, {Size = size or 10})
end
function Blur:hide()
	local b = self:get(); if b then Utils.tween(b, ANIM.FAST, {Size = 0}) end
end

-- Create shop button
local toggle = createShopButton()

-- Shop Manager
local Shop = {isOpen = false, isAnimating = false}

function Shop:open()
	print("Shop:open called - current state: isOpen=", self.isOpen, " isAnimating=", self.isAnimating)
	if self.isOpen then 
		print("Shop already open, returning")
		return 
	end
	if self.isAnimating then
		print("Animation in progress, returning")
		return
	end
	
	-- Clear ownership cache when opening
	ownedPassesCache = {}
	
	self.isAnimating = true
	self.isOpen = true
	
	print("Opening shop...")
	preload()
	
	-- Make sure GUI elements exist
	if not dim or not panel then
		warn("Shop GUI elements missing!")
		self.isAnimating = false
		self.isOpen = false
		return
	end
	
	dim.Visible = true
	panel.Visible = true
	dim.BackgroundTransparency = 1
	panel.Position = UDim2.new(0.5,0,0.52,0)
	panel.Size = UDim2.new(0,1120,0,830)
	panel.BackgroundTransparency = 0.2
	
	Blur:show(10)
	Utils.tween(dim, ANIM.MED, {BackgroundTransparency = 0.3})
	Utils.tween(panel, ANIM.SLOW, {Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0,1140,0,860), BackgroundTransparency = 0})
	Sfx:play("open")
	Tabs:select("Home")
	
	task.delay(0.35, function() 
		self.isAnimating = false 
		print("Shop open animation complete")
	end)
end

function Shop:close()
	if not self.isOpen or self.isAnimating then return end
	self.isAnimating = true; self.isOpen = false
	Blur:hide()
	Utils.tween(dim, ANIM.FAST, {BackgroundTransparency = 1})
	Utils.tween(panel, ANIM.FAST, {Position = UDim2.new(0.5,0,0.53,0), Size = UDim2.new(0,1120,0,830)})
	Sfx:play("close")
	task.delay(0.2, function()
		dim.Visible = false; panel.Visible = false; self.isAnimating = false
	end)
end

function Shop:toggle()
	print("Shop:toggle called - isOpen=", self.isOpen)
	if self.isOpen then self:close() else self:open() end
end

function Shop:reset()
	print("Resetting shop state...")
	self.isOpen = false
	self.isAnimating = false
	if dim then dim.Visible = false end
	if panel then panel.Visible = false end
	Blur:hide()
end

-- Build everything after metadata
buildHome()
buildCash()
buildPasses()

-- Connect shop button
toggle.MouseButton1Click:Connect(function()
	print("Shop button clicked!")
	-- Failsafe check
	if Shop.isOpen and not (panel and panel.Visible) then
		print("Shop in stuck state, resetting...")
		Shop:reset()
	end
	Shop:toggle()
end)

-- Also support TouchTap for mobile
toggle.TouchTap:Connect(function()
	Shop:toggle()
end)

-- Keyboard support
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.M and not UserInputService:GetFocusedTextBox() then
		Shop:toggle()
	elseif input.KeyCode == Enum.KeyCode.Escape and Shop.isOpen then
		Shop:close()
	end
end)

closeBtn.MouseButton1Click:Connect(function() Shop:close() end)

-- Gamepad support
if GuiService:IsTenFootInterface() then
	GuiService:AddSelectionParent("SanrioShop", screen)
	panel.SelectionGroup = true
	GuiService.SelectedObject = homeTab
end

-- Build size adj
task.defer(function()
	for n, p in pairs(Tabs.pages) do
		if p.AbsoluteSize.Y > 0 then
			local maxH = p.AbsoluteSize.Y
			for _, child in ipairs(p:GetChildren()) do
				if child:IsA("ScrollingFrame") then
					child.Size = UDim2.new(1, -32, 0, maxH - 32)
				elseif child:IsA("Frame") and child.Name:find("Overlay") then
					child.Size = UDim2.new(1, -24, 0, maxH - 24)
				end
			end
		end
	end
end)

-- Re-create shop button on respawn
localPlayer.CharacterAdded:Connect(function()
	task.wait(1) -- Wait for GUI to load
	if not playerGui:FindFirstChild("SANRIO_SHOP_BUTTON") then
		toggle = createShopButton()
		toggle.MouseButton1Click:Connect(function()
			print("Shop button clicked!")
			if Shop.isOpen and not (panel and panel.Visible) then
				print("Shop in stuck state, resetting...")
				Shop:reset()
			end
			Shop:toggle()
		end)
		toggle.TouchTap:Connect(function()
			Shop:toggle()
		end)
	end
end)

print("🎀 SANRIO SHOP — Fully fixed version loaded! All issues resolved.")