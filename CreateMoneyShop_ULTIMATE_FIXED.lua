--[[
  🎀 SANRIO SHOP — ULTIMATE FIXED VERSION (LocalScript)
  
  FIXES:
  1. ✅ Processing state properly updates after purchase
  2. ✅ Shop button persists after reset/respawn
  3. ✅ Toggle appears immediately after purchase
  4. ✅ Proper ownership refresh
--]]

-- // Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- // Animation presets
local ANIM = {
	FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
	MED = TweenInfo.new(0.25, Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
	SLOW = TweenInfo.new(0.35, Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
	BOUNCE = TweenInfo.new(0.30, Enum.EasingStyle.Back,Enum.EasingDirection.Out),
	SMOOTH = TweenInfo.new(0.40, Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
}

local MOBILE_THRESHOLD = 1024

-- // Utils
local Utils = {}

function Utils.tween(inst: Instance?, info: TweenInfo, props: {[string]: any})
	if not inst then return end
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

function Utils.setFont(gui: TextLabel | TextButton, weight: Enum.FontWeight?, size: number?)
	weight = weight or Enum.FontWeight.Regular
	size = size or 14
	gui.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", weight, Enum.FontStyle.Normal)
	gui.TextSize = size
end

function Utils.blend(a: Color3, b: Color3, alpha: number): Color3
	alpha = math.clamp(alpha or 0.5, 0, 1)
	return Color3.new(
		a.R + (b.R - a.R) * alpha,
		a.G + (b.G - a.G) * alpha,
		a.B + (b.B - a.B) * alpha
	)
end

function Utils.isMobile(): boolean
	local cam = workspace.CurrentCamera
	if not cam then return false end
	local vp = cam.ViewportSize
	return vp.X <= MOBILE_THRESHOLD or GuiService:IsTenFootInterface()
end

function Utils.comma(n: number): string
	return ("%d"):format(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

function Utils.safe(fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then warn("[SanrioShop]", err) end
	return ok
end

-- // Assets
local Asset = {}
Asset.list = {
	paperTexture = "rbxassetid://3584103989",
	badgeHello = "rbxassetid://17398522865",
	badgeMelody = "rbxassetid://17398525031",
	badgeKuromi ="rbxassetid://17398526388",
	badgeCinna = "rbxassetid://17398524224",

	iconCloseX = "rbxassetid://13516603909",
	iconCash = "rbxassetid://10709728059",
	iconPass = "rbxassetid://10709727148",

	hkBowPattern = "rbxassetid://6022668879",
	cloudTexture = "rbxassetid://4096004729",
	starPattern = "rbxassetid://121915223943271",

	sfxClick = "rbxassetid://876939830",
	sfxHover = "rbxassetid://12221967",
	sfxOpen = "rbxassetid://9125713501",
	sfxClose = "rbxassetid://9119713951",
}

function Asset.valid(id: string?): boolean
	return type(id) == "string" and id ~= "" and id ~= "rbxassetid://0"
end

-- // Theme
local Theme = {}
Theme.tokens = {
	default = {
		bg = Color3.fromRGB(253,252,250),
		surface = Color3.fromRGB(255,255,255),
		surfaceAlt = Color3.fromRGB(246,248,252),
		stroke = Color3.fromRGB(222,226,235),
		text = Color3.fromRGB(35,38,46),
		subtext = Color3.fromRGB(120,126,140),
		scrollbar = Color3.fromRGB(180,185,200),
		kitty = Color3.fromRGB(255, 64, 64),
		cinna = Color3.fromRGB(186, 214, 255),
		kuromi = Color3.fromRGB(200, 190, 255),
		success = Color3.fromRGB( 76, 175,80),
		warning = Color3.fromRGB(255, 152,0),
		error = Color3.fromRGB(244,67,54),
	}
}
Theme.current = "default"

function Theme.c(k: string): Color3
	local t = Theme.tokens[Theme.current]
	return t[k] or Color3.new(1,1,1)
end

-- // Data
local ShopData = {}
ShopData.data = {
	cash = {
		{id = 1897730242, amount = 1000,name = "1,000 Cash", icon = "rbxassetid://0", description = "A small boost to get you started"},
		{id = 1897730373, amount = 5000,name = "5,000 Cash", icon = "rbxassetid://0", description = "Perfect for mid-game purchases"},
		{id = 1897730467, amount = 10000,name = "10,000 Cash", icon = "rbxassetid://0", description = "A significant cash injection"},
		{id = 1897730581, amount = 50000,name = "50,000 Cash", icon = "rbxassetid://0", description = "Maximum value bundle"},
	},
	gamepasses = {
		{id = 1412171840, name = "Auto Collect", price = 99, icon = "rbxassetid://0", description = "Automatically collect cash!", hasToggle = true},
		{id = 1398974710, name = "2x Cash", price = 199, icon = "rbxassetid://0", description = "Double all cash earned"},
	}
}

-- Cache for ownership to reduce API calls
local ownershipCache = {}

function ShopData.getProductInfo(id: number)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.Product)
	end)
	return ok and info or nil
end

function ShopData.getPassInfo(id: number)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)
	end)
	return ok and info or nil
end

function ShopData.userOwnsPass(userId: number, passId: number)
	-- Check cache first
	local cacheKey = userId .. "_" .. passId
	if ownershipCache[cacheKey] ~= nil then
		print("  📦 Using cached ownership for", passId, ":", ownershipCache[cacheKey])
		return ownershipCache[cacheKey]
	end
	
	-- In Studio, check if we've marked this as purchased
	if game:GetService("RunService"):IsStudio() then
		-- Check if this gamepass was recently purchased
		if not _G.StudioGamepassPurchases then
			_G.StudioGamepassPurchases = {}
		end
		
		-- Use a player-specific key for Studio purchases
		local studioKey = tostring(userId) .. "_" .. tostring(passId)
		local recentPurchase = _G.StudioGamepassPurchases[studioKey]
		if recentPurchase then
			print("  🎮 Studio: Using recent purchase status for", passId, "userId:", userId)
			ownershipCache[cacheKey] = true
			return true
		end
	end
	
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
	end)
	
	if ok then
		ownershipCache[cacheKey] = owns
		print("  ✅ API ownership check for", passId, ":", owns)
	else
		print("  ❌ API ownership check failed for", passId)
	end
	
	return ok and owns or false
end

-- Clear ownership cache
function ShopData.clearOwnershipCache()
	ownershipCache = {}
	print("🗑️ Cleared entire ownership cache")
end

-- Hydrate icons/prices properly
local function hydrateMetadata()
	for _, gp in ipairs(ShopData.data.gamepasses) do
		gp.icon = "rbxthumb://type=GamePass&id="..tostring(gp.id).."&w=150&h=150"
		local info = ShopData.getPassInfo(gp.id)
		if info and info.PriceInRobux and (not gp.price or gp.price == 0) then
			gp.price = info.PriceInRobux
		end
	end
	for _, dev in ipairs(ShopData.data.cash) do
		local info = ShopData.getProductInfo(dev.id)
		if info and info.IconImageAssetId and info.IconImageAssetId ~= 0 then
			dev.icon = "rbxthumb://type=Asset&id="..tostring(info.IconImageAssetId).."&w=420&h=420"
		else
			dev.icon = Asset.list.iconCash
		end
	end
end

-- // SFX
local Sfx = {enabled = true, sounds = {}}
function Sfx:init()
	local function mk(id, vol)
		if not Asset.valid(id) then return end
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = vol or .5
		s.Parent = SoundService
		return s
	end
	self.sounds.click = mk(Asset.list.sfxClick, .4)
	self.sounds.hover = mk(Asset.list.sfxHover, .25)
	self.sounds.open = mk(Asset.list.sfxOpen, .5)
	self.sounds.close = mk(Asset.list.sfxClose, .5)
	self.sounds.success = mk(Asset.list.sfxClick, .6)
end
function Sfx:play(n)
	if not self.enabled then return end
	local s = self.sounds[n]
	if s then s:Play() end
end
Sfx:init()

-- // UIFactory
local UI = {}

function UI.frame(p): Frame
	local f = Instance.new("Frame")
	f.Name = p.Name or "Frame"
	f.Size = p.Size or UDim2.fromScale(1,1)
	f.Position = p.Position or UDim2.new()
	f.AnchorPoint = p.AnchorPoint or Vector2.new(0,0)
	f.BackgroundColor3 = p.BackgroundColor3 or Theme.c("surface")
	f.BackgroundTransparency = p.BackgroundTransparency or 0
	f.BorderSizePixel = 0
	f.Visible = p.Visible ~= false
	f.ZIndex = p.ZIndex or 1
	f.ClipsDescendants = p.ClipsDescendants or false
	if p.CornerRadius then
		local c = Instance.new("UICorner")
		c.CornerRadius = p.CornerRadius
		c.Parent = f
	end
	if p.Stroke then
		local s = Instance.new("UIStroke")
		s.Color = p.Stroke.Color or Theme.c("stroke")
		s.Thickness = p.Stroke.Thickness or 1
		s.Transparency = p.Stroke.Transparency or 0
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = f
	end
	return f
end

function UI.textLabel(p): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = p.Name or "TextLabel"
	l.BackgroundTransparency = 1
	l.Size = p.Size or UDim2.fromScale(1,1)
	l.Position = p.Position or UDim2.new()
	l.AnchorPoint = p.AnchorPoint or Vector2.new(0,0)
	l.Text = p.Text or ""
	l.TextColor3 = p.TextColor3 or Theme.c("text")
	l.TextXAlignment = p.TextXAlignment or Enum.TextXAlignment.Center
	l.TextYAlignment = p.TextYAlignment or Enum.TextYAlignment.Center
	l.TextWrapped = p.TextWrapped ~= false
	l.RichText = p.RichText or false
	l.TextScaled = p.TextScaled or false
	l.TextTruncate = p.TextTruncate or Enum.TextTruncate.None
	Utils.setFont(l, p.FontWeight or Enum.FontWeight.Regular, p.TextSize or 14)
	l.ZIndex = p.ZIndex or 1
	return l
end

function UI.textButton(p): TextButton
	local b = Instance.new("TextButton")
	b.Name = p.Name or "TextButton"
	b.Size = p.Size or UDim2.fromOffset(120,40)
	b.Position = p.Position or UDim2.new()
	b.AnchorPoint = p.AnchorPoint or Vector2.new(0,0)
	b.BackgroundColor3 = p.BackgroundColor3 or Theme.c("surface")
	b.BackgroundTransparency = p.BackgroundTransparency or 0
	b.BorderSizePixel = 0
	b.Text = p.Text or ""
	b.TextColor3 = p.TextColor3 or Theme.c("text")
	Utils.setFont(b, p.FontWeight or Enum.FontWeight.Medium, p.TextSize or 16)
	b.AutoButtonColor = false
	b.ZIndex = p.ZIndex or 1
	if p.CornerRadius then local c = Instance.new("UICorner"); c.CornerRadius = p.CornerRadius; c.Parent = b end
	if p.Stroke then
		local s = Instance.new("UIStroke")
		s.Color = p.Stroke.Color or Theme.c("stroke")
		s.Thickness = p.Stroke.Thickness or 1
		s.Transparency = p.Stroke.Transparency or 0
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = b
	end
	b.MouseEnter:Connect(function()
		Utils.tween(b, ANIM.FAST, {Size = UDim2.new(b.Size.X.Scale, b.Size.X.Offset + 4, b.Size.Y.Scale, b.Size.Y.Offset + 4)})
		Sfx:play("hover")
	end)
	b.MouseLeave:Connect(function()
		Utils.tween(b, ANIM.FAST, {Size = p.Size or UDim2.fromOffset(120,40)})
	end)
	b.MouseButton1Click:Connect(function() Sfx:play("click") end)
	return b
end

function UI.image(p): ImageLabel
	local i = Instance.new("ImageLabel")
	i.Name = p.Name or "ImageLabel"
	i.BackgroundTransparency = 1
	i.Image = p.Image or ""
	i.ImageColor3 = p.ImageColor3 or Color3.new(1,1,1)
	i.ImageTransparency = p.ImageTransparency or 0
	i.ScaleType = p.ScaleType or Enum.ScaleType.Fit
	i.Size = p.Size or UDim2.fromOffset(100,100)
	i.Position = p.Position or UDim2.new()
	i.AnchorPoint = p.AnchorPoint or Vector2.new(0,0)
	i.ZIndex = p.ZIndex or 1
	if p.CornerRadius then local c = Instance.new("UICorner"); c.CornerRadius = p.CornerRadius; c.Parent = i end
	return i
end

function UI.scroll(p): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Name = p.Name or "ScrollingFrame"
	s.BackgroundTransparency = p.BackgroundTransparency or 1
	s.BorderSizePixel = 0
	s.Size = p.Size or UDim2.fromScale(1,1)
	s.Position = p.Position or UDim2.new()
	s.CanvasSize = p.CanvasSize or UDim2.new()
	s.ScrollBarThickness = p.ScrollBarThickness or 8
	s.ScrollBarImageColor3 = p.ScrollBarImageColor3 or Theme.c("scrollbar")
	s.ScrollingDirection = p.ScrollingDirection or Enum.ScrollingDirection.Y
	s.ZIndex = p.ZIndex or 1
	if p.Layout then
		local layout = p.Layout.Type == "Grid" and Instance.new("UIGridLayout") or Instance.new("UIListLayout")
		for k, v in pairs(p.Layout) do
			if k ~= "Type" and layout[k] ~= nil then layout[k] = v end
		end
		layout.Parent = s
	end
	if p.Padding then
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = p.Padding.Top or UDim.new()
		pad.PaddingBottom = p.Padding.Bottom or UDim.new()
		pad.PaddingLeft = p.Padding.Left or UDim.new()
		pad.PaddingRight = p.Padding.Right or UDim.new()
		pad.Parent = s
	end
	return s
end

-- Halo helper
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

-- Global references
local screen, dim, panel, toggle
local homePage, cashPage, passPage

-- Create shop button with persistence
local function createShopButton()
	-- Check if button screen already exists
	local buttonScreen = playerGui:FindFirstChild("SANRIO_SHOP_BUTTON")
	if not buttonScreen then
		buttonScreen = Instance.new("ScreenGui")
		buttonScreen.Name = "SANRIO_SHOP_BUTTON"
		buttonScreen.ResetOnSpawn = false
		buttonScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		buttonScreen.DisplayOrder = 999
		buttonScreen.Parent = playerGui
	end
	
	-- Check if toggle already exists
	local existingToggle = buttonScreen:FindFirstChild("ShopToggle")
	if existingToggle then
		return existingToggle
	end
	
	toggle = UI.textButton({
		Name = "ShopToggle", 
		Size = UDim2.fromOffset(156,50), 
		Position = UDim2.new(1,-16,1,-16), 
		AnchorPoint = Vector2.new(1,1), 
		BackgroundColor3 = Theme.c("surface"), 
		CornerRadius = UDim.new(1,0), 
		Stroke = {Color = Theme.c("stroke")}, 
		ZIndex = 100
	})
	toggle.Parent = buttonScreen
	
	local tIcon = UI.image({
		Image = Asset.list.badgeHello, 
		ImageColor3 = Theme.c("kitty"), 
		Size = UDim2.fromOffset(24,24), 
		Position = UDim2.new(0,12,0.5,0), 
		AnchorPoint = Vector2.new(0,0.5), 
		ZIndex = 101
	})
	tIcon.Parent = toggle
	
	local tText = UI.textLabel({
		Text = "Shop", 
		Position = UDim2.new(0,44,0,0), 
		Size = UDim2.new(1,-50,1,0), 
		TextXAlignment = Enum.TextXAlignment.Left, 
		FontWeight = Enum.FontWeight.SemiBold, 
		TextSize = 20, 
		ZIndex = 101
	})
	tText.Parent = toggle

	-- Add pulse animation
	task.spawn(function()
		while toggle and toggle.Parent do
			Utils.tween(toggle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(164, 54)
			})
			task.wait(1.5)
			if not toggle or not toggle.Parent then break end
			Utils.tween(toggle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(156, 50)
			})
			task.wait(1.5)
		end
	end)
	
	return toggle
end

-- Create main shop GUI
local function createShopGUI()
	-- Check if shop already exists
	local existingShop = playerGui:FindFirstChild("SANRIO_SHOP_REBUILT")
	if existingShop then
		screen = existingShop
		dim = screen:FindFirstChild("Dim")
		panel = screen:FindFirstChild("Panel")
		if panel then
			local pages = panel:FindFirstChild("Pages")
			if pages then
				homePage = pages:FindFirstChild("HomePage")
				cashPage = pages:FindFirstChild("CashPage")
				passPage = pages:FindFirstChild("GamepassesPage")
			end
		end
		return
	end

	screen = Instance.new("ScreenGui")
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
	dim = UI.frame({Name = "Dim", Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Visible = false, ZIndex = 5})
	dim.Parent = screen

	-- Panel
	panel = UI.frame({
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
	
	-- Store close button reference to connect later after Shop is defined
	closeBtn:SetAttribute("NeedsConnection", true)
end

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
	self.tabs[name] = {button = b, accent = accent}
	return b
end

function Tabs:createPage(name: string)
	local p = UI.frame({Name = name.."Page", BackgroundTransparency = 1, Visible = false, ZIndex = 11})
	self.pages[name] = p
	return p
end

function Tabs:select(name: string)
	if self.current == name then return end
	for tName, tab in pairs(self.tabs) do
		local active = (tName == name)
		Utils.tween(tab.button, ANIM.FAST, {BackgroundColor3 = active and Utils.blend(tab.accent, Color3.new(1,1,1), 0.9) or Theme.c("surface")})
		local s = tab.button:FindFirstChildOfClass("UIStroke"); if s then s.Color = active and tab.accent or Theme.c("stroke") end
		for _, child in ipairs(tab.button:GetChildren()) do
			if child:IsA("ImageLabel") then child.ImageColor3 = active and tab.accent or Theme.c("text") end
			if child:IsA("TextLabel") then child.TextColor3 = active and tab.accent or Theme.c("text") end
		end
	end
	for _, p in pairs(self.pages) do p.Visible = false end
	local page = self.pages[name]
	if page then
		page.Visible = true
		page.Position = UDim2.new(0,0,0,10)
		Utils.tween(page, ANIM.BOUNCE, {Position = UDim2.new(0,0,0,0)})
	end
	self.current = name
	Sfx:play("click")
end

-- Price chip
local function priceChip(text: string, accent: Color3)
	local chip = UI.frame({Name = "Chip", Size = UDim2.fromOffset(138,32), BackgroundColor3 = Utils.blend(accent, Color3.new(1,1,1), 0.9), CornerRadius = UDim.new(1,0), ZIndex = 16})
	local st = Instance.new("UIStroke"); st.Color = accent; st.Thickness = 1.5; st.Transparency = 0.35; st.Parent = chip
	local lb = UI.textLabel({Text = text, TextColor3 = accent, TextSize = 16, FontWeight = Enum.FontWeight.Medium, ZIndex = 17})
	lb.Parent = chip
	return chip
end

-- CTA button factory
local function CTAButton(text: string, accent: Color3)
	local btn = UI.textButton({Name = "CTA", Text = text, Size = UDim2.new(0,240,0,56), BackgroundColor3 = Utils.blend(accent, Color3.new(1,1,1), 0.88), TextColor3 = accent, CornerRadius = UDim.new(1,0), Stroke = {Color = accent, Thickness = 2, Transparency = 0.15}, FontWeight = Enum.FontWeight.Bold, TextSize = 22, ZIndex = 16})
	return btn
end

-- Purchase state registry
local Pending = {product = {}, pass = {}}

-- Owned state function
local function setOwnedState(card: Frame, item: {[string]: any})
	local inner = card:FindFirstChild("Inner")
	local cta = inner and inner:FindFirstChild("CTA")
	if cta and cta:IsA("TextButton") then
		cta.Text = "Owned"
		cta.Active = false
		cta.AutoButtonColor = false
		cta.BackgroundColor3 = Utils.blend(Theme.c("success"), Color3.new(1,1,1), 0.9)
		cta.TextColor3 = Theme.c("success")
	end
	local outline = card:FindFirstChildOfClass("UIStroke")
	if outline then outline.Color = Theme.c("success") end
	local chip = inner and inner:FindFirstChild("Chip")
	if chip and chip:IsA("Frame") then
		local s = chip:FindFirstChildOfClass("UIStroke"); if s then s.Color = Theme.c("success") end
		local t = chip:FindFirstChildOfClass("TextLabel"); if t then t.Text = "Permanent"; t.TextColor3 = Theme.c("success") end
	end
end

-- Forward declare build functions
local buildHome, buildCash, buildPasses

-- Refresh all pages
local function refreshAllPages()
	-- Clear ownership cache
	ShopData.clearOwnershipCache()
	
	-- Rebuild all pages
	if homePage then
		for _, child in ipairs(homePage:GetChildren()) do
			child:Destroy()
		end
		buildHome()
	end
	
	if cashPage then
		for _, child in ipairs(cashPage:GetChildren()) do
			child:Destroy()
		end
		buildCash()
	end
	
	if passPage then
		for _, child in ipairs(passPage:GetChildren()) do
			child:Destroy()
		end
		buildPasses()
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
	local iconId = (item.icon and Asset.valid(item.icon)) and item.icon or ((kind == "pass") and Asset.list.iconPass or Asset.list.iconCash)
	local iconColor = (kind == "pass") and Color3.fromRGB(240,240,255) or Theme.c("text")
	-- Make gamepass icons larger (64x64 instead of 48x48)
	local iconSize = (kind == "pass") and UDim2.fromOffset(64,64) or UDim2.fromOffset(48,48)
	local icon = UI.image({Name = "Icon", Image = iconId, ImageColor3 = iconColor, Size = iconSize, Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), ZIndex = 15})
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
	local isOwned = false
	if kind == "pass" then
		isOwned = ShopData.userOwnsPass(localPlayer.UserId, item.id)
		print("🎮 Gamepass ownership check:", item.name, "ID:", item.id, "Owned:", isOwned)
	end
	
	if isOwned then
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
				task.spawn(function()
					autoCollectRemote:FireServer(true)
				end)
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
					task.spawn(function()
						autoCollectRemote:FireServer(toggleState)
					end)
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
			-- Double check ownership before prompting
			if kind == "pass" then
				local owns = ShopData.userOwnsPass(localPlayer.UserId, item.id)
				if owns then
					-- Already owns, just refresh UI
					refreshAllPages()
					return
				end
			end
			
			cta.Text = "Processing…"
			cta.Active = false
			cta.AutoButtonColor = false
			
			if kind == "pass" then
				print("🛍️ Prompting gamepass purchase:", item.id, item.name)
				Pending.pass[item.id] = {cta = cta, card = card, item = item}
				
				-- Add timeout failsafe
				task.spawn(function()
					task.wait(10) -- Wait 10 seconds
					if Pending.pass[item.id] then
						print("⏰ Timeout reached for gamepass:", item.id)
						-- Still pending after 10 seconds, reset button
						if cta and cta.Parent then
							cta.Text = "Purchase"
							cta.Active = true
							cta.AutoButtonColor = true
						end
						Pending.pass[item.id] = nil
					end
				end)
				
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
buildHome = function()
	-- overlay + soft bows
	local overlay = UI.frame({Name = "HomeOverlay", Size = UDim2.new(1,-24,1,-24), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Theme.c("surfaceAlt"), CornerRadius = UDim.new(0,18), ClipsDescendants = true, ZIndex = 10})
	overlay.Parent = homePage
	local g = Instance.new("UIGradient"); g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Utils.blend(Theme.c("kitty"), Color3.new(1,1,1), 0.96)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1))}; g.Rotation = 90; g.Parent = overlay
	if Asset.valid(Asset.list.hkBowPattern) then
		local pattern = UI.image({Name = "BowPattern", Image = Asset.list.hkBowPattern, ImageColor3 = Color3.fromRGB(255,200,200), ImageTransparency = 0.94, Size = UDim2.fromScale(1,1), ScaleType = Enum.ScaleType.Tile, ZIndex = 10}); pattern.TileSize = UDim2.fromOffset(120,120); pattern.Parent = overlay
	end

	-- hero
	local hero = UI.frame({Name = "Hero", Size = UDim2.new(1,-24,0,220), Position = UDim2.new(0,12,0,0), CornerRadius = UDim.new(0,18), BackgroundColor3 = Theme.c("surfaceAlt"), Stroke = {Color = Theme.c("stroke")}, ZIndex = 12})
	hero.Parent = homePage
	local hg2 = Instance.new("UIGradient"); hg2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Utils.blend(Theme.c("kitty"), Color3.new(1,1,1), 0.97)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1))}; hg2.Rotation = 45; hg2.Parent = hero
	local badge = UI.image({Name = "HeroBadge", Image = Asset.list.badgeHello, Size = UDim2.fromOffset(72,72), Position = UDim2.new(0,24,0.5,0), AnchorPoint = Vector2.new(0,0.5), ZIndex = 13}); badge.Parent = hero
	local hTitle = UI.textLabel({Name = "HeroTitle", Text = "5,000 Cash", Position = UDim2.new(0,116,0,34), Size = UDim2.new(1,-300,0,40), TextXAlignment = Enum.TextXAlignment.Left, FontWeight = Enum.FontWeight.Bold, TextSize = 32, ZIndex = 13}); hTitle.Parent = hero
	local hDesc = UI.textLabel({Name = "HeroDesc", Text = "Perfect for mid‑game purchases", Position = UDim2.new(0,116,0,78), Size = UDim2.new(1,-300,0,50), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.c("subtext"), FontWeight = Enum.FontWeight.Regular, TextSize = 18, TextWrapped = true, ZIndex = 13}); hDesc.Parent = hero
	local hCTA = UI.textButton({Name = "HeroCTA", Text = "Get Now", Size = UDim2.fromOffset(200,52), Position = UDim2.new(1,-220,0.5,0), AnchorPoint = Vector2.new(0,0.5), CornerRadius = UDim.new(1,0), FontWeight = Enum.FontWeight.Bold, TextSize = 22, ZIndex = 14}); hCTA.Parent = hero

	-- featured strip (horizontal)
	local featured = UI.scroll({Name = "Featured", Size = UDim2.new(1,0,0,356), Position = UDim2.new(0,0,0, 330), ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 6, Layout = {Type = "List", FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,24)}, Padding = {Left = UDim.new(0,12), Right = UDim.new(0,12)}, ZIndex = 13})
	featured.Parent = homePage

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

buildCash = function()
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

buildPasses = function()
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
	for _, gp in ipairs(ShopData.data.gamepasses) do
		local card = makeItemCard(gp, "pass", Theme.c("kuromi")); card.Parent = grid
	end
	task.defer(function() local lay = grid:FindFirstChildOfClass("UIGridLayout"); if lay then grid.CanvasSize = UDim2.new(0,0,0, lay.AbsoluteContentSize.Y + 32) end end)
end

-- // Purchase callbacks
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if userId ~= localPlayer.UserId then return end
	local cta = Pending.product[productId]
	if cta and cta.Parent then
		cta.Text = wasPurchased and "Purchased!" or "Purchase"
		cta.Active = true; cta.AutoButtonColor = true
		if wasPurchased then
			Sfx:play("success")
			local ev = ReplicatedStorage:FindFirstChild("GrantProductCurrency")
			if ev and ev:IsA("RemoteEvent") then ev:FireServer(productId) end
			task.delay(1.5, function() if cta and cta.Parent then cta.Text = "Purchase" end end)
		end
	end
	Pending.product[productId] = nil
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(userId, gamePassId, wasPurchased)
	print("🎮 PromptGamePassPurchaseFinished fired - UserId:", userId, "GamePassId:", gamePassId, "Purchased:", wasPurchased)
	print("  📝 LocalPlayer UserId:", localPlayer.UserId)
	
	-- More flexible userId check for Studio testing
	local isForThisPlayer = (userId == localPlayer.UserId) or (tonumber(userId) == localPlayer.UserId)
	
	-- In Studio, sometimes the userId doesn't match perfectly
	if game:GetService("RunService"):IsStudio() then
		print("  🎮 Studio detected - being more lenient with userId check")
		-- If this is one of our gamepasses and it was purchased, assume it's for us
		local isOurGamepass = false
		for _, pass in ipairs(ShopData.data.gamepasses) do
			if pass.id == gamePassId then
				isOurGamepass = true
				break
			end
		end
		
		if isOurGamepass and wasPurchased then
			print("  ✅ Our gamepass was purchased in Studio - assuming it's for this player")
			isForThisPlayer = true
		end
	end
	
	if not isForThisPlayer then 
		print("  ❌ Not for this player (", userId, "vs", localPlayer.UserId, ")")
		return 
	end
	
	print("  ✅ For this player! Pending data:", Pending.pass[gamePassId] ~= nil)
	
	local pendingData = Pending.pass[gamePassId]
	if pendingData then
		local cta = pendingData.cta
		local card = pendingData.card
		local item = pendingData.item
		
		if wasPurchased then
			-- Mark as purchased in Studio
			if game:GetService("RunService"):IsStudio() then
				if not _G.StudioGamepassPurchases then
					_G.StudioGamepassPurchases = {}
				end
				-- Use player-specific key
				local studioKey = tostring(localPlayer.UserId) .. "_" .. tostring(gamePassId)
				_G.StudioGamepassPurchases[studioKey] = true
				print("  📝 Marked gamepass", gamePassId, "as purchased in Studio for userId:", localPlayer.UserId)
				
				-- Clear the ownership cache for this gamepass
				local cacheKey = localPlayer.UserId .. "_" .. gamePassId
				ownershipCache[cacheKey] = nil
				print("  🗑️ Cleared ownership cache for", gamePassId)
			end
			
			-- Update CTA immediately
			if cta and cta.Parent then
				cta.Text = "Updating..."
				cta.Active = false
				cta.AutoButtonColor = false
			end
			
			-- Play success sound
			Sfx:play("success")
			
			-- Clear pending state immediately
			Pending.pass[gamePassId] = nil
			
			-- Wait for Roblox to update ownership
			task.wait(2)
			
			-- Clear cache before refresh
			ShopData.clearOwnershipCache()
			
			-- Force refresh all pages
			refreshAllPages()
		else
			-- Reset button if cancelled
			if cta and cta.Parent then
				cta.Text = "Purchase"
				cta.Active = true
				cta.AutoButtonColor = true
			end
		end
		
		Pending.pass[gamePassId] = nil
	else
		-- No pending data but purchase was successful - still refresh
		if wasPurchased then
			print("  🔄 No pending data but purchase successful - refreshing anyway")
			
			-- Play success sound
			Sfx:play("success")
			
			-- Wait a bit for ownership to update
			task.wait(1.5)
			
			-- Clear cache before refresh
			ShopData.clearOwnershipCache()
			
			-- Force refresh
			refreshAllPages()
		end
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
	Utils.tween(self:get(), ANIM.MED, {Size = 0})
end

-- Shop Manager
local Shop = {isOpen = false, isAnimating = false}

function Shop:open()
	if self.isOpen then return end
	if self.isAnimating then return end

	self.isAnimating = true
	self.isOpen = true

	preload()

	-- Make sure GUI elements exist
	if not dim or not panel then
		warn("Shop GUI elements missing!")
		self.isAnimating = false
		self.isOpen = false
		return
	end

	-- Clear ownership cache when opening
	ShopData.clearOwnershipCache()

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
	if self.isOpen then self:close() else self:open() end
end

function Shop:reset()
	self.isOpen = false
	self.isAnimating = false
	if dim then dim.Visible = false end
	if panel then panel.Visible = false end
	Blur:hide()
end

-- Build everything after metadata
hydrateMetadata()

-- Initialize shop
local function initializeShop()
	-- Create GUI first
	createShopGUI()
	
	-- Only create tabs if panel exists
	if not panel then return end
	
	-- Tab bar
	local tabBar = UI.frame({Name = "TabBar", Size = UDim2.new(1,-24,0,52), Position = UDim2.new(0,12,0,92), BackgroundTransparency = 1, ZIndex = 11})
	tabBar.Parent = panel
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0,10)
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Parent = tabBar

	local homeTab = Tabs:createTab("Home", nil, Theme.c("kitty")); homeTab.Parent = tabBar
	local cashTab = Tabs:createTab("Cash", Asset.list.iconCash, Theme.c("cinna")); cashTab.Parent = tabBar
	local passTab = Tabs:createTab("Gamepasses", Asset.list.iconPass, Theme.c("kuromi")); passTab.Parent = tabBar

	-- Pages container
	local pages = UI.frame({Name = "Pages", Size = UDim2.new(1,-24,1,-164), Position = UDim2.new(0,12,0,164), BackgroundTransparency = 1, ZIndex = 10})
	pages.Parent = panel
	homePage = Tabs:createPage("Home"); homePage.Parent = pages
	cashPage = Tabs:createPage("Cash"); cashPage.Parent = pages
	passPage = Tabs:createPage("Gamepasses"); passPage.Parent = pages

	-- Build pages
	buildHome(); buildCash(); buildPasses()

	-- Bindings
	homeTab.MouseButton1Click:Connect(function() Tabs:select("Home") end)
	cashTab.MouseButton1Click:Connect(function() Tabs:select("Cash") end)
	passTab.MouseButton1Click:Connect(function() Tabs:select("Gamepasses") end)
end

-- Create shop button
toggle = createShopButton()

-- Connect shop button
local function connectShopButton()
	if not toggle then return end
	
	toggle.MouseButton1Click:Connect(function() 
		-- Check if shop is in a bad state
		if Shop.isOpen == true and (not panel or not panel.Visible) then
			Shop:reset()
		end
		Shop:toggle() 
	end)

	-- Add touch support for mobile
	if toggle.TouchTap then
		toggle.TouchTap:Connect(function()
			Shop:toggle()
		end)
	end
end

connectShopButton()

-- Initialize shop
initializeShop()

-- Connect close button after Shop is defined
if screen then
	local panel = screen:FindFirstChild("Panel")
	if panel then
		local header = panel:FindFirstChild("Header")
		if header then
			local closeBtn = header:FindFirstChild("Close")
			if closeBtn and closeBtn:GetAttribute("NeedsConnection") then
				closeBtn.MouseButton1Click:Connect(function() 
					Shop:close() 
				end)
				closeBtn:SetAttribute("NeedsConnection", false)
			end
		end
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		Shop:toggle()
	end
	if input.KeyCode == Enum.KeyCode.ButtonStart then
		Shop:toggle()
	end
	if input.KeyCode == Enum.KeyCode.Escape and Shop.isOpen then
		Shop:close()
	end
end)

-- Listen for gamepass purchase notifications from server
local gamepassPurchaseRemote = game:GetService("ReplicatedStorage"):WaitForChild("TycoonRemotes", 5)
if gamepassPurchaseRemote then
	gamepassPurchaseRemote = gamepassPurchaseRemote:WaitForChild("GamepassPurchased", 5)
	if gamepassPurchaseRemote then
		gamepassPurchaseRemote.OnClientEvent:Connect(function(gamePassId)
			print("🎯 Received gamepass purchase notification from server:", gamePassId)
			
			-- Check if it's one of our gamepasses
			local isOurGamepass = false
			for _, pass in ipairs(ShopData.data.gamepasses) do
				if pass.id == gamePassId then
					isOurGamepass = true
					break
				end
			end
			
			if isOurGamepass then
				print("  ✅ Our gamepass! Refreshing shop...")
				
				-- Mark as purchased in Studio
				if game:GetService("RunService"):IsStudio() then
					if not _G.StudioGamepassPurchases then
						_G.StudioGamepassPurchases = {}
					end
					-- Use player-specific key
					local studioKey = tostring(localPlayer.UserId) .. "_" .. tostring(gamePassId)
					_G.StudioGamepassPurchases[studioKey] = true
					print("  📝 Marked gamepass", gamePassId, "as purchased in Studio (via server notification) for userId:", localPlayer.UserId)
					
					-- Clear the ownership cache for this gamepass
					local cacheKey = localPlayer.UserId .. "_" .. gamePassId
					ownershipCache[cacheKey] = nil
					print("  🗑️ Cleared ownership cache for", gamePassId)
				end
				
				-- Play success sound
				Sfx:play("success")
				
				-- Clear any pending states
				for id, _ in pairs(Pending.pass) do
					if id == gamePassId then
						Pending.pass[id] = nil
					end
				end
				
				-- Wait for ownership to update
				task.wait(1.5)
				
				-- Clear cache before refresh
				ShopData.clearOwnershipCache()
				
				-- Force refresh
				refreshAllPages()
			end
		end)
	end
end

-- Simple selection image for gamepad focus
local selectImg = Instance.new("ImageLabel")
selectImg.Image = "rbxassetid://3570695787"
selectImg.ScaleType = Enum.ScaleType.Slice
selectImg.SliceCenter = Rect.new(100,100,100,100)
selectImg.ImageTransparency = 0.5
selectImg.Size = UDim2.fromOffset(0,0)
selectImg.BackgroundTransparency = 1

-- Safely set the selection image
local success, err = pcall(function()
	GuiService.SelectionImage = selectImg
end)

if not success then
	pcall(function()
		GuiService.SelectionImageObject = selectImg
	end)
end

-- Handle character respawn
local function onCharacterAdded()
	task.wait(0.5)
	
	-- Recreate shop button if needed
	toggle = createShopButton()
	connectShopButton()
	
	-- Reinitialize shop if needed
	if not screen or not screen.Parent then
		initializeShop()
	end
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Also check periodically in case something goes wrong
task.spawn(function()
	while true do
		task.wait(2)
		-- Ensure shop button exists
		if not toggle or not toggle.Parent then
			toggle = createShopButton()
			connectShopButton()
		end
	end
end)

print("🎀 SANRIO SHOP — Ultimate Fixed Version loaded!")
print("  ✅ Processing updates properly after purchase")
print("  ✅ Shop button persists after reset")
print("  ✅ Toggle appears immediately after gamepass purchase")
print("  ✅ Press 'M' or click the Shop button to open")