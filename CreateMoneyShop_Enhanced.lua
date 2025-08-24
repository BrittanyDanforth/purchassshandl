--[[
  🎀 SANRIO SHOP — CHILD-CENTRIC ENHANCED VERSION
  
  Enhanced with:
  - Larger tap targets for young players (75x75 minimum)
  - Simplified navigation (single-screen categories)
  - More visual feedback and animations
  - Parental controls integration
  - Age-appropriate design patterns
  - Ethical monetization focus
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
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Top-level remote folder access
local TycoonRemotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")

-- // Child-Centric Design Constants
local CHILD_DESIGN = {
	MIN_TAP_SIZE = 75, -- Minimum tap target size in pixels
	BUTTON_PADDING = 20, -- Extra padding for easier tapping
	ANIMATION_SPEED = 0.35, -- Slower animations for clarity
	FEEDBACK_DELAY = 0.1, -- Immediate feedback timing
	TEXT_SIZE_MIN = 18, -- Minimum readable text size
	TEXT_SIZE_LARGE = 24, -- Large text for important elements
	ICON_SIZE_MIN = 48, -- Minimum icon size
	ICON_SIZE_LARGE = 64, -- Large icons for main actions
}

-- // Animation presets (adjusted for children)
local ANIM = {
	FAST = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	MED = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SLOW = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	BOUNCE = TweenInfo.new(0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	SMOOTH = TweenInfo.new(0.50, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
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
	-- Ensure minimum text size for readability
	size = math.max(size or CHILD_DESIGN.TEXT_SIZE_MIN, CHILD_DESIGN.TEXT_SIZE_MIN)
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

-- // Assets with child-friendly icons
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
	iconHome = "rbxassetid://10734924532", -- Home icon for simplified navigation
	iconStar = "rbxassetid://10734950309", -- Star for achievements
	iconLock = "rbxassetid://10734933222", -- Lock for parental controls

	hkBowPattern = "rbxassetid://6022668879",
	cloudTexture = "rbxassetid://4096004729",
	starPattern = "rbxassetid://121915223943271",

	-- Enhanced sound effects for better feedback
	sfxClick = "rbxassetid://876939830",
	sfxHover = "rbxassetid://10734835585",
	sfxOpen = "rbxassetid://452267918",
	sfxClose = "rbxassetid://452267918",
	sfxSuccess = "rbxassetid://10734847400",
	sfxError = "rbxassetid://10734856351",
}

function Asset.valid(id: string?): boolean
	return type(id) == "string" and id ~= "" and id ~= "rbxassetid://0"
end

-- // Child-Friendly Theme
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
		-- Bright, appealing colors for children
		kitty = Color3.fromRGB(255, 179, 212), -- Softer pink
		cinna = Color3.fromRGB(186, 214, 255),
		kuromi = Color3.fromRGB(200, 190, 255),
		success = Color3.fromRGB(129, 199, 132), -- Softer green
		warning = Color3.fromRGB(255, 183, 77),
		error = Color3.fromRGB(239, 83, 80),
		-- Additional child-friendly colors
		sunshine = Color3.fromRGB(255, 235, 59),
		ocean = Color3.fromRGB(100, 181, 246),
		mint = Color3.fromRGB(129, 236, 236),
	}
}
Theme.current = "default"

function Theme.c(k: string): Color3
	local t = Theme.tokens[Theme.current]
	return t[k] or Color3.new(1,1,1)
end

-- // Simplified Data Structure
local ShopData = {}
ShopData.data = {
	-- Focus on cosmetic items only (ethical monetization)
	cosmetics = {
		{
			id = 1897730242, 
			name = "Pink Bow", 
			icon = "rbxassetid://0", 
			description = "A cute pink bow for your character!",
			category = "accessories",
			price = 50,
			type = "cosmetic"
		},
		{
			id = 1897730373, 
			name = "Star Wings", 
			icon = "rbxassetid://0", 
			description = "Sparkly wings that shine!",
			category = "accessories",
			price = 100,
			type = "cosmetic"
		},
		{
			id = 1897730467, 
			name = "Rainbow Trail", 
			icon = "rbxassetid://0", 
			description = "Leave a colorful trail behind you!",
			category = "effects",
			price = 150,
			type = "cosmetic"
		},
		{
			id = 1897730581, 
			name = "Golden Crown", 
			icon = "rbxassetid://0", 
			description = "A shiny crown fit for royalty!",
			category = "accessories",
			price = 200,
			type = "cosmetic"
		},
	},
	-- Content expansions (ethical monetization)
	expansions = {
		{
			id = 1412171840, 
			name = "Candy Land", 
			price = 299, 
			icon = "rbxassetid://0", 
			description = "Unlock a sweet new world to explore!",
			type = "expansion"
		},
		{
			id = 1398974710, 
			name = "Space Adventure", 
			price = 399, 
			icon = "rbxassetid://0", 
			description = "Blast off to outer space!",
			type = "expansion"
		},
	}
}

-- Parental control settings
local ParentalControls = {
	requireApproval = true,
	dailySpendLimit = 1000,
	sessionTimeLimit = 60, -- minutes
	approvedItems = {},
}

-- Cache for ownership
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

function ShopData.userOwnsItem(userId: number, itemId: number)
	local cacheKey = userId .. "_" .. itemId
	if ownershipCache[cacheKey] ~= nil then
		return ownershipCache[cacheKey]
	end
	
	-- Check ownership through your game's system
	-- This is a placeholder - implement your actual ownership check
	return false
end

-- // Enhanced SFX with multiple variations
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
	self.sounds.hover = mk(Asset.list.sfxHover, .3)
	self.sounds.open = mk(Asset.list.sfxOpen, .5)
	self.sounds.close = mk(Asset.list.sfxClose, .5)
	self.sounds.success = mk(Asset.list.sfxSuccess, .6)
	self.sounds.error = mk(Asset.list.sfxError, .5)
end

function Sfx:play(n)
	if not self.enabled then return end
	local s = self.sounds[n]
	if s then 
		-- Add slight pitch variation for more engaging feedback
		s.Pitch = 0.95 + math.random() * 0.1
		s:Play() 
	end
end
Sfx:init()

-- // Enhanced UI Factory with Child-Centric Design
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
	
	-- Always add rounded corners for friendlier appearance
	local c = Instance.new("UICorner")
	c.CornerRadius = p.CornerRadius or UDim.new(0, 12)
	c.Parent = f
	
	if p.Stroke then
		local s = Instance.new("UIStroke")
		s.Color = p.Stroke.Color or Theme.c("stroke")
		s.Thickness = p.Stroke.Thickness or 2 -- Thicker strokes for visibility
		s.Transparency = p.Stroke.Transparency or 0
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = f
	end
	
	-- Add drop shadow for depth
	if p.Shadow then
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.BackgroundTransparency = 1
		shadow.Image = "rbxassetid://1316045217"
		shadow.ImageColor3 = Color3.new(0, 0, 0)
		shadow.ImageTransparency = 0.8
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(10, 10, 118, 118)
		shadow.Size = UDim2.new(1, 30, 1, 30)
		shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.ZIndex = f.ZIndex - 1
		shadow.Parent = f.Parent
		f.Parent = shadow.Parent
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
	Utils.setFont(l, p.FontWeight or Enum.FontWeight.Regular, p.TextSize or CHILD_DESIGN.TEXT_SIZE_MIN)
	l.ZIndex = p.ZIndex or 1
	
	-- Add text stroke for better readability
	l.TextStrokeTransparency = 0.8
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	
	return l
end

function UI.textButton(p): TextButton
	local b = Instance.new("TextButton")
	b.Name = p.Name or "TextButton"
	
	-- Ensure minimum tap size for children
	local minWidth = math.max(p.Size and p.Size.X.Offset or 120, CHILD_DESIGN.MIN_TAP_SIZE + CHILD_DESIGN.BUTTON_PADDING)
	local minHeight = math.max(p.Size and p.Size.Y.Offset or 40, CHILD_DESIGN.MIN_TAP_SIZE)
	
	b.Size = p.Size or UDim2.fromOffset(minWidth, minHeight)
	b.Position = p.Position or UDim2.new()
	b.AnchorPoint = p.AnchorPoint or Vector2.new(0,0)
	b.BackgroundColor3 = p.BackgroundColor3 or Theme.c("surface")
	b.BackgroundTransparency = p.BackgroundTransparency or 0
	b.BorderSizePixel = 0
	b.Text = p.Text or ""
	b.TextColor3 = p.TextColor3 or Theme.c("text")
	Utils.setFont(b, p.FontWeight or Enum.FontWeight.Medium, p.TextSize or CHILD_DESIGN.TEXT_SIZE_LARGE)
	b.AutoButtonColor = false
	b.ZIndex = p.ZIndex or 1
	
	-- Always add rounded corners
	local c = Instance.new("UICorner")
	c.CornerRadius = p.CornerRadius or UDim.new(0.5, 0)
	c.Parent = b
	
	-- Add stroke
	local s = Instance.new("UIStroke")
	s.Color = p.Stroke and p.Stroke.Color or Theme.c("stroke")
	s.Thickness = p.Stroke and p.Stroke.Thickness or 2
	s.Transparency = p.Stroke and p.Stroke.Transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = b
	
	-- Enhanced hover effects for children
	local originalSize = b.Size
	local isPressed = false
	
	b.MouseEnter:Connect(function()
		if not isPressed then
			Utils.tween(b, ANIM.FAST, {
				Size = UDim2.new(
					originalSize.X.Scale,
					originalSize.X.Offset + 8,
					originalSize.Y.Scale,
					originalSize.Y.Offset + 8
				)
			})
			Utils.tween(s, ANIM.FAST, {Thickness = 3})
			Sfx:play("hover")
		end
	end)
	
	b.MouseLeave:Connect(function()
		if not isPressed then
			Utils.tween(b, ANIM.FAST, {Size = originalSize})
			Utils.tween(s, ANIM.FAST, {Thickness = 2})
		end
	end)
	
	-- Press feedback
	b.MouseButton1Down:Connect(function()
		isPressed = true
		Utils.tween(b, ANIM.FAST, {
			Size = UDim2.new(
				originalSize.X.Scale,
				originalSize.X.Offset - 4,
				originalSize.Y.Scale,
				originalSize.Y.Offset - 4
			),
			BackgroundColor3 = Utils.blend(b.BackgroundColor3, Color3.new(0.8, 0.8, 0.8), 0.3)
		})
	end)
	
	b.MouseButton1Up:Connect(function()
		isPressed = false
		Utils.tween(b, ANIM.FAST, {
			Size = originalSize,
			BackgroundColor3 = p.BackgroundColor3 or Theme.c("surface")
		})
		Sfx:play("click")
	end)
	
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
	
	-- Ensure minimum icon size
	local minSize = CHILD_DESIGN.ICON_SIZE_MIN
	if p.Size then
		i.Size = p.Size
	else
		i.Size = UDim2.fromOffset(minSize, minSize)
	end
	
	i.Position = p.Position or UDim2.new()
	i.AnchorPoint = p.AnchorPoint or Vector2.new(0,0)
	i.ZIndex = p.ZIndex or 1
	
	if p.CornerRadius then 
		local c = Instance.new("UICorner")
		c.CornerRadius = p.CornerRadius
		c.Parent = i
	end
	
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
	s.ScrollBarThickness = p.ScrollBarThickness or 12 -- Thicker for easier grabbing
	s.ScrollBarImageColor3 = p.ScrollBarImageColor3 or Theme.c("scrollbar")
	s.ScrollingDirection = p.ScrollingDirection or Enum.ScrollingDirection.Y
	s.ZIndex = p.ZIndex or 1
	
	-- Make scrollbar more visible
	s.ScrollBarImageTransparency = 0.3
	
	if p.Layout then
		local layout = p.Layout.Type == "Grid" and Instance.new("UIGridLayout") or Instance.new("UIListLayout")
		for k, v in pairs(p.Layout) do
			if k ~= "Type" and layout[k] ~= nil then layout[k] = v end
		end
		layout.Parent = s
	end
	
	if p.Padding then
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = p.Padding.Top or UDim.new(0, 12)
		pad.PaddingBottom = p.Padding.Bottom or UDim.new(0, 12)
		pad.PaddingLeft = p.Padding.Left or UDim.new(0, 12)
		pad.PaddingRight = p.Padding.Right or UDim.new(0, 12)
		pad.Parent = s
	end
	
	return s
end

-- Character guide helper
local function createCharacterGuide(parent: Frame, text: string, characterImage: string?)
	local guide = UI.frame({
		Name = "CharacterGuide",
		Size = UDim2.new(1, -40, 0, 120),
		Position = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = Utils.blend(Theme.c("sunshine"), Color3.new(1,1,1), 0.9),
		CornerRadius = UDim.new(0, 20),
		Stroke = {Color = Theme.c("sunshine"), Thickness = 3},
		Shadow = true,
		ZIndex = 15
	})
	guide.Parent = parent
	
	-- Character image
	local char = UI.image({
		Name = "Character",
		Image = characterImage or Asset.list.badgeHello,
		Size = UDim2.fromOffset(80, 80),
		Position = UDim2.new(0, 20, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 16
	})
	char.Parent = guide
	
	-- Speech bubble
	local bubble = UI.frame({
		Name = "SpeechBubble",
		Size = UDim2.new(1, -140, 1, -20),
		Position = UDim2.new(0, 120, 0, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		CornerRadius = UDim.new(0, 15),
		ZIndex = 16
	})
	bubble.Parent = guide
	
	-- Bubble tail
	local tail = Instance.new("ImageLabel")
	tail.Name = "Tail"
	tail.Size = UDim2.fromOffset(20, 20)
	tail.Position = UDim2.new(0, -15, 0.5, -10)
	tail.BackgroundTransparency = 1
	tail.Image = "rbxassetid://8650853038"
	tail.ImageColor3 = Color3.new(1, 1, 1)
	tail.Rotation = 90
	tail.ZIndex = 15
	tail.Parent = bubble
	
	-- Guide text
	local guideText = UI.textLabel({
		Name = "GuideText",
		Text = text,
		TextColor3 = Theme.c("text"),
		Position = UDim2.new(0, 15, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontWeight = Enum.FontWeight.Medium,
		TextSize = CHILD_DESIGN.TEXT_SIZE_MIN,
		TextWrapped = true,
		ZIndex = 17
	})
	guideText.Parent = bubble
	
	-- Animate character bounce
	task.spawn(function()
		while char and char.Parent do
			Utils.tween(char, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0, 20, 0.5, -5)
			})
			task.wait(1)
			if not char or not char.Parent then break end
			Utils.tween(char, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0, 20, 0.5, 5)
			})
			task.wait(1)
		end
	end)
	
	return guide
end

-- Progress indicator for children
local function createProgressBar(parent: Frame, current: number, max: number)
	local container = UI.frame({
		Name = "ProgressContainer",
		Size = UDim2.new(1, -40, 0, 40),
		Position = UDim2.new(0, 20, 1, -60),
		BackgroundColor3 = Theme.c("surfaceAlt"),
		CornerRadius = UDim.new(0.5, 0),
		Stroke = {Color = Theme.c("stroke")},
		ZIndex = 14
	})
	container.Parent = parent
	
	local fill = UI.frame({
		Name = "ProgressFill",
		Size = UDim2.fromScale(current / max, 1),
		BackgroundColor3 = Theme.c("success"),
		CornerRadius = UDim.new(0.5, 0),
		ZIndex = 15
	})
	fill.Parent = container
	
	-- Add gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Theme.c("success")),
		ColorSequenceKeypoint.new(1, Utils.blend(Theme.c("success"), Theme.c("mint"), 0.5))
	}
	gradient.Parent = fill
	
	local label = UI.textLabel({
		Name = "ProgressLabel",
		Text = string.format("%d / %d", current, max),
		TextColor3 = Theme.c("text"),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = CHILD_DESIGN.TEXT_SIZE_MIN,
		ZIndex = 16
	})
	label.Parent = container
	
	-- Animate fill
	fill.Size = UDim2.fromScale(0, 1)
	Utils.tween(fill, ANIM.SLOW, {Size = UDim2.fromScale(current / max, 1)})
	
	return container
end

-- Achievement notification
local function showAchievement(text: string, icon: string?)
	local achievement = UI.frame({
		Name = "Achievement",
		Size = UDim2.fromOffset(350, 100),
		Position = UDim2.new(0.5, 0, 0, -120),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.c("success"),
		CornerRadius = UDim.new(0, 20),
		Shadow = true,
		ZIndex = 100
	})
	achievement.Parent = playerGui
	
	-- Icon
	local iconImg = UI.image({
		Image = icon or Asset.list.iconStar,
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.new(0, 20, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Color3.new(1, 1, 1),
		ZIndex = 101
	})
	iconImg.Parent = achievement
	
	-- Text
	local achText = UI.textLabel({
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		Position = UDim2.new(0, 100, 0, 0),
		Size = UDim2.new(1, -120, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontWeight = Enum.FontWeight.Bold,
		TextSize = CHILD_DESIGN.TEXT_SIZE_LARGE,
		ZIndex = 101
	})
	achText.Parent = achievement
	
	-- Animate in
	Utils.tween(achievement, ANIM.BOUNCE, {Position = UDim2.new(0.5, 0, 0, 20)})
	Sfx:play("success")
	
	-- Particle effect
	local particles = {}
	for i = 1, 10 do
		local particle = UI.image({
			Image = Asset.list.iconStar,
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageColor3 = Theme.c("sunshine"),
			ZIndex = 99
		})
		particle.Parent = achievement
		table.insert(particles, particle)
		
		-- Animate particle
		local angle = (i / 10) * math.pi * 2
		local distance = 150
		Utils.tween(particle, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance),
			ImageTransparency = 1,
			Size = UDim2.fromOffset(5, 5)
		})
	end
	
	-- Remove after delay
	task.wait(3)
	Utils.tween(achievement, ANIM.MED, {Position = UDim2.new(0.5, 0, 0, -120)})
	task.wait(0.5)
	achievement:Destroy()
end

-- Global references
local screen, dim, panel, toggle
local currentPage = "home"

-- Create shop button with child-friendly design
local function createShopButton()
	local buttonScreen = playerGui:FindFirstChild("SANRIO_SHOP_BUTTON")
	if not buttonScreen then
		buttonScreen = Instance.new("ScreenGui")
		buttonScreen.Name = "SANRIO_SHOP_BUTTON"
		buttonScreen.ResetOnSpawn = false
		buttonScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		buttonScreen.DisplayOrder = 999
		buttonScreen.Parent = playerGui
	end

	local existingToggle = buttonScreen:FindFirstChild("ShopToggle")
	if existingToggle then
		return existingToggle
	end

	-- Larger button for easier tapping
	toggle = UI.textButton({
		Name = "ShopToggle", 
		Size = UDim2.fromOffset(180, 80), 
		Position = UDim2.new(1, -20, 1, -20), 
		AnchorPoint = Vector2.new(1, 1), 
		BackgroundColor3 = Theme.c("kitty"), 
		CornerRadius = UDim.new(0.5, 0), 
		Stroke = {Color = Utils.blend(Theme.c("kitty"), Color3.new(0.8, 0.8, 0.8), 0.3), Thickness = 3}, 
		Shadow = true,
		ZIndex = 100
	})
	toggle.Parent = buttonScreen

	-- Large icon
	local tIcon = UI.image({
		Image = Asset.list.badgeHello, 
		Size = UDim2.fromOffset(50, 50), 
		Position = UDim2.new(0, 15, 0.5, 0), 
		AnchorPoint = Vector2.new(0, 0.5), 
		ZIndex = 101
	})
	tIcon.Parent = toggle

	-- Clear text
	local tText = UI.textLabel({
		Text = "SHOP", 
		Position = UDim2.new(0, 75, 0, 0), 
		Size = UDim2.new(1, -85, 1, 0), 
		TextXAlignment = Enum.TextXAlignment.Left, 
		FontWeight = Enum.FontWeight.Bold, 
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 101
	})
	tText.Parent = toggle

	-- Fun pulse animation
	task.spawn(function()
		while toggle and toggle.Parent do
			Utils.tween(toggle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(190, 85),
				BackgroundColor3 = Utils.blend(Theme.c("kitty"), Theme.c("sunshine"), 0.2)
			})
			task.wait(1.5)
			if not toggle or not toggle.Parent then break end
			Utils.tween(toggle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(180, 80),
				BackgroundColor3 = Theme.c("kitty")
			})
			task.wait(1.5)
		end
	end)

	return toggle
end

-- Create main shop GUI with simplified navigation
local function createShopGUI()
	local existingShop = playerGui:FindFirstChild("SANRIO_SHOP_ENHANCED")
	if existingShop then
		existingShop:Destroy()
	end

	screen = Instance.new("ScreenGui")
	screen.Name = "SANRIO_SHOP_ENHANCED"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 1000
	screen.Parent = playerGui

	-- Colorful background pattern
	local bgPattern = UI.image({
		Name = "BackgroundPattern", 
		Image = Asset.list.starPattern, 
		ImageColor3 = Theme.c("kitty"),
		ImageTransparency = 0.95, 
		Size = UDim2.fromScale(1, 1), 
		ScaleType = Enum.ScaleType.Tile, 
		ZIndex = 1
	})
	bgPattern.TileSize = UDim2.fromOffset(300, 300)
	bgPattern.Parent = screen

	-- Dim overlay
	dim = UI.frame({
		Name = "Dim", 
		Size = UDim2.fromScale(1, 1), 
		BackgroundColor3 = Color3.new(0, 0, 0), 
		BackgroundTransparency = 1, 
		Visible = false, 
		ZIndex = 5
	})
	dim.Parent = screen

	-- Main panel with friendlier size
	panel = UI.frame({
		Name = "Panel",
		Size = UDim2.new(0, 1000, 0, 700),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.c("surface"),
		CornerRadius = UDim.new(0, 30),
		Stroke = {Thickness = 3, Color = Theme.c("kitty")},
		Shadow = true,
		ZIndex = 10,
		Visible = false,
	})
	panel.Parent = screen

	-- Responsive scale
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local s = math.clamp(math.min(vp.X, vp.Y) / 1000, 0.6, 1.0)
		if Utils.isMobile() then s = s * 0.85 end
		scale.Scale = s
	end
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		updateScale()
	end

	-- Friendly header
	local header = UI.frame({
		Name = "Header", 
		Size = UDim2.new(1, -30, 0, 100), 
		Position = UDim2.new(0, 15, 0, 15), 
		CornerRadius = UDim.new(0, 20), 
		BackgroundColor3 = Utils.blend(Theme.c("kitty"), Color3.new(1, 1, 1), 0.9), 
		Stroke = {Color = Theme.c("kitty"), Thickness = 2}, 
		ZIndex = 11
	})
	header.Parent = panel

	-- Shop title with icon
	local shopIcon = UI.image({
		Name = "ShopIcon", 
		Image = Asset.list.badgeHello, 
		Size = UDim2.fromOffset(70, 70), 
		Position = UDim2.new(0, 20, 0.5, 0), 
		AnchorPoint = Vector2.new(0, 0.5), 
		ZIndex = 12
	})
	shopIcon.Parent = header

	local title = UI.textLabel({
		Name = "Title", 
		Text = "✨ Sanrio Shop ✨", 
		Position = UDim2.new(0, 110, 0, 0), 
		Size = UDim2.new(1, -200, 1, 0), 
		TextXAlignment = Enum.TextXAlignment.Left, 
		FontWeight = Enum.FontWeight.Bold, 
		TextSize = 36, 
		TextColor3 = Theme.c("kitty"),
		ZIndex = 12
	})
	title.Parent = header

	-- Large close button
	local closeBtn = UI.textButton({
		Name = "Close", 
		Size = UDim2.fromOffset(70, 70), 
		Position = UDim2.new(1, -85, 0.5, 0), 
		AnchorPoint = Vector2.new(0, 0.5), 
		BackgroundColor3 = Theme.c("error"), 
		CornerRadius = UDim.new(0.5, 0), 
		ZIndex = 13
	})
	closeBtn.Parent = header

	local closeIcon = UI.image({
		Name = "X", 
		Image = Asset.list.iconCloseX, 
		ImageColor3 = Color3.new(1, 1, 1), 
		Size = UDim2.fromOffset(35, 35), 
		Position = UDim2.new(0.5, 0, 0.5, 0), 
		AnchorPoint = Vector2.new(0.5, 0.5), 
		ZIndex = 14
	})
	closeIcon.Parent = closeBtn

	-- Store close button reference
	closeBtn:SetAttribute("NeedsConnection", true)
	
	-- Create simple navigation tabs (visual categories on same page)
	local navBar = UI.frame({
		Name = "NavBar",
		Size = UDim2.new(1, -30, 0, 80),
		Position = UDim2.new(0, 15, 0, 130),
		BackgroundTransparency = 1,
		ZIndex = 11
	})
	navBar.Parent = panel
	
	-- Content area (single scrolling page)
	local content = UI.scroll({
		Name = "Content",
		Size = UDim2.new(1, -30, 1, -240),
		Position = UDim2.new(0, 15, 0, 220),
		ScrollBarThickness = 15,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.c("surfaceAlt"),
		CornerRadius = UDim.new(0, 20),
		Padding = {
			Top = UDim.new(0, 20),
			Bottom = UDim.new(0, 20),
			Left = UDim.new(0, 20),
			Right = UDim.new(0, 20)
		},
		ZIndex = 10
	})
	content.Parent = panel
	
	-- Add UIListLayout for vertical scrolling
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.Padding = UDim.new(0, 30)
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content
	
	return navBar, content
end

-- Create item card with child-friendly design
local function createItemCard(item, category, parent)
	local card = UI.frame({
		Name = "ItemCard",
		Size = UDim2.new(0, 280, 0, 350),
		BackgroundColor3 = Color3.new(1, 1, 1),
		CornerRadius = UDim.new(0, 25),
		Stroke = {Color = Theme.c("stroke"), Thickness = 3},
		Shadow = true,
		ZIndex = 12
	})
	
	-- Category color coding
	local accentColor = Theme.c("kitty")
	if category == "cosmetics" then
		accentColor = Theme.c("kitty")
	elseif category == "expansions" then
		accentColor = Theme.c("ocean")
	end
	
	-- Color header
	local header = UI.frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundColor3 = accentColor,
		CornerRadius = UDim.new(0, 25),
		ZIndex = 13
	})
	header.Parent = card
	
	-- Fix bottom corners
	local cornerFix = UI.frame({
		Name = "CornerFix",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 1, -30),
		BackgroundColor3 = accentColor,
		ZIndex = 13
	})
	cornerFix.Parent = header
	
	-- Item icon
	local iconBg = UI.frame({
		Name = "IconBg",
		Size = UDim2.fromOffset(100, 100),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		CornerRadius = UDim.new(0.5, 0),
		ZIndex = 14
	})
	iconBg.Parent = header
	
	local icon = UI.image({
		Image = item.icon and Asset.valid(item.icon) and item.icon or Asset.list.iconStar,
		Size = UDim2.fromOffset(70, 70),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageColor3 = accentColor,
		ZIndex = 15
	})
	icon.Parent = iconBg
	
	-- Item name
	local itemName = UI.textLabel({
		Text = item.name,
		Position = UDim2.new(0, 15, 0, 130),
		Size = UDim2.new(1, -30, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 22,
		TextColor3 = Theme.c("text"),
		ZIndex = 14
	})
	itemName.Parent = card
	
	-- Description
	local desc = UI.textLabel({
		Text = item.description,
		Position = UDim2.new(0, 15, 0, 175),
		Size = UDim2.new(1, -30, 0, 60),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontWeight = Enum.FontWeight.Regular,
		TextSize = 16,
		TextColor3 = Theme.c("subtext"),
		TextWrapped = true,
		ZIndex = 14
	})
	desc.Parent = card
	
	-- Price display
	local priceTag = UI.frame({
		Name = "PriceTag",
		Size = UDim2.fromOffset(120, 40),
		Position = UDim2.new(0.5, 0, 0, 240),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Utils.blend(accentColor, Color3.new(1, 1, 1), 0.8),
		CornerRadius = UDim.new(0.5, 0),
		Stroke = {Color = accentColor, Thickness = 2},
		ZIndex = 14
	})
	priceTag.Parent = card
	
	local priceText = UI.textLabel({
		Text = "R$ " .. tostring(item.price or 0),
		TextColor3 = accentColor,
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 20,
		ZIndex = 15
	})
	priceText.Parent = priceTag
	
	-- Purchase button
	local buyBtn = UI.textButton({
		Name = "BuyButton",
		Text = "Get It! 🎉",
		Size = UDim2.new(1, -30, 0, 50),
		Position = UDim2.new(0, 15, 1, -65),
		BackgroundColor3 = accentColor,
		TextColor3 = Color3.new(1, 1, 1),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 22,
		CornerRadius = UDim.new(0.5, 0),
		ZIndex = 15
	})
	buyBtn.Parent = card
	
	-- Check if owned
	local isOwned = ShopData.userOwnsItem(localPlayer.UserId, item.id)
	if isOwned then
		buyBtn.Text = "Owned! ✨"
		buyBtn.BackgroundColor3 = Theme.c("success")
		buyBtn.Active = false
	else
		-- Purchase handler
		buyBtn.MouseButton1Click:Connect(function()
			-- Check parental controls
			if ParentalControls.requireApproval then
				-- Show parental approval UI
				showParentalApproval(item, function(approved)
					if approved then
						processPurchase(item)
					end
				end)
			else
				processPurchase(item)
			end
		end)
	end
	
	-- Hover effect for card
	local originalY = 0
	card.MouseEnter:Connect(function()
		originalY = card.Position.Y.Offset
		Utils.tween(card, ANIM.MED, {
			Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset, 
				card.Position.Y.Scale, originalY - 10)
		})
		Utils.tween(card:FindFirstChildOfClass("UIStroke"), ANIM.MED, {
			Thickness = 5,
			Color = accentColor
		})
	end)
	
	card.MouseLeave:Connect(function()
		Utils.tween(card, ANIM.MED, {
			Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset, 
				card.Position.Y.Scale, originalY)
		})
		Utils.tween(card:FindFirstChildOfClass("UIStroke"), ANIM.MED, {
			Thickness = 3,
			Color = Theme.c("stroke")
		})
	end)
	
	card.Parent = parent
	return card
end

-- Parental approval dialog
local function showParentalApproval(item, callback)
	local dialog = UI.frame({
		Name = "ParentalDialog",
		Size = UDim2.fromOffset(500, 400),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.c("surface"),
		CornerRadius = UDim.new(0, 30),
		Shadow = true,
		ZIndex = 50
	})
	dialog.Parent = screen
	
	-- Header
	local header = UI.frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundColor3 = Theme.c("warning"),
		CornerRadius = UDim.new(0, 30),
		ZIndex = 51
	})
	header.Parent = dialog
	
	-- Lock icon
	local lockIcon = UI.image({
		Image = Asset.list.iconLock,
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(0, 20, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Color3.new(1, 1, 1),
		ZIndex = 52
	})
	lockIcon.Parent = header
	
	-- Title
	local title = UI.textLabel({
		Text = "Ask a Parent! 👪",
		Position = UDim2.new(0, 90, 0, 0),
		Size = UDim2.new(1, -100, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 28,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 52
	})
	title.Parent = header
	
	-- Message
	local message = UI.textLabel({
		Text = string.format("You want to buy:\n\n%s\nfor R$ %d\n\nAsk your parent to approve!", 
			item.name, item.price or 0),
		Position = UDim2.new(0, 30, 0, 100),
		Size = UDim2.new(1, -60, 0, 150),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontWeight = Enum.FontWeight.Medium,
		TextSize = 20,
		TextWrapped = true,
		ZIndex = 51
	})
	message.Parent = dialog
	
	-- Buttons
	local approveBtn = UI.textButton({
		Text = "Parent Approves ✅",
		Size = UDim2.fromOffset(180, 60),
		Position = UDim2.new(0.25, 0, 1, -80),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Theme.c("success"),
		TextColor3 = Color3.new(1, 1, 1),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 20,
		ZIndex = 52
	})
	approveBtn.Parent = dialog
	
	local cancelBtn = UI.textButton({
		Text = "Cancel ❌",
		Size = UDim2.fromOffset(180, 60),
		Position = UDim2.new(0.75, 0, 1, -80),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Theme.c("error"),
		TextColor3 = Color3.new(1, 1, 1),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 20,
		ZIndex = 52
	})
	cancelBtn.Parent = dialog
	
	approveBtn.MouseButton1Click:Connect(function()
		dialog:Destroy()
		callback(true)
	end)
	
	cancelBtn.MouseButton1Click:Connect(function()
		dialog:Destroy()
		callback(false)
	end)
	
	-- Animate in
	dialog.Size = UDim2.fromOffset(400, 300)
	Utils.tween(dialog, ANIM.BOUNCE, {Size = UDim2.fromOffset(500, 400)})
end

-- Process purchase
local function processPurchase(item)
	-- Show loading
	local loading = UI.textLabel({
		Text = "Processing... 🎁",
		Size = UDim2.fromOffset(300, 100),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.c("surface"),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 24,
		ZIndex = 60
	})
	loading.Parent = screen
	
	-- Add loading spinner animation
	task.spawn(function()
		local rotation = 0
		while loading and loading.Parent do
			rotation = rotation + 5
			loading.Rotation = rotation
			task.wait(0.03)
		end
	end)
	
	-- Simulate purchase (replace with actual purchase logic)
	task.wait(2)
	
	loading:Destroy()
	
	-- Show success
	showAchievement("Purchase Complete! 🎉", Asset.list.iconStar)
	
	-- Update ownership
	ownershipCache[localPlayer.UserId .. "_" .. item.id] = true
end

-- Build shop content
local function buildShopContent(navBar, content)
	-- Character guide at top
	local guide = createCharacterGuide(content, 
		"Welcome to the shop! Here you can find amazing items to customize your experience! 🌟",
		Asset.list.badgeHello
	)
	guide.LayoutOrder = 1
	
	-- Category: Cosmetics
	local cosmeticsSection = UI.frame({
		Name = "CosmeticsSection",
		Size = UDim2.new(1, 0, 0, 450),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 11
	})
	cosmeticsSection.Parent = content
	
	local cosmeticsTitle = UI.textLabel({
		Text = "✨ Cosmetics ✨",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 0, 0),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 32,
		TextColor3 = Theme.c("kitty"),
		ZIndex = 12
	})
	cosmeticsTitle.Parent = cosmeticsSection
	
	local cosmeticsScroll = UI.scroll({
		Name = "CosmeticsScroll",
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 60),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 12,
		BackgroundTransparency = 1,
		Layout = {
			Type = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 20)
		},
		ZIndex = 11
	})
	cosmeticsScroll.Parent = cosmeticsSection
	
	-- Add cosmetic items
	for _, item in ipairs(ShopData.data.cosmetics) do
		createItemCard(item, "cosmetics", cosmeticsScroll)
	end
	
	-- Update canvas size
	task.defer(function()
		local layout = cosmeticsScroll:FindFirstChildOfClass("UIListLayout")
		if layout then
			cosmeticsScroll.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X + 40, 0, 0)
		end
	end)
	
	-- Category: Expansions
	local expansionsSection = UI.frame({
		Name = "ExpansionsSection",
		Size = UDim2.new(1, 0, 0, 450),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = 11
	})
	expansionsSection.Parent = content
	
	local expansionsTitle = UI.textLabel({
		Text = "🌍 New Worlds 🌍",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 0, 0),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 32,
		TextColor3 = Theme.c("ocean"),
		ZIndex = 12
	})
	expansionsTitle.Parent = expansionsSection
	
	local expansionsScroll = UI.scroll({
		Name = "ExpansionsScroll",
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 60),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 12,
		BackgroundTransparency = 1,
		Layout = {
			Type = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 20)
		},
		ZIndex = 11
	})
	expansionsScroll.Parent = expansionsSection
	
	-- Add expansion items
	for _, item in ipairs(ShopData.data.expansions) do
		createItemCard(item, "expansions", expansionsScroll)
	end
	
	-- Update canvas size
	task.defer(function()
		local layout = expansionsScroll:FindFirstChildOfClass("UIListLayout")
		if layout then
			expansionsScroll.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X + 40, 0, 0)
		end
	end)
	
	-- Progress section
	local progressSection = UI.frame({
		Name = "ProgressSection",
		Size = UDim2.new(1, 0, 0, 150),
		BackgroundColor3 = Utils.blend(Theme.c("sunshine"), Color3.new(1, 1, 1), 0.9),
		CornerRadius = UDim.new(0, 20),
		LayoutOrder = 4,
		ZIndex = 11
	})
	progressSection.Parent = content
	
	local progressTitle = UI.textLabel({
		Text = "🏆 Collection Progress 🏆",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 0, 10),
		FontWeight = Enum.FontWeight.Bold,
		TextSize = 24,
		TextColor3 = Theme.c("text"),
		ZIndex = 12
	})
	progressTitle.Parent = progressSection
	
	-- Calculate owned items
	local totalItems = #ShopData.data.cosmetics + #ShopData.data.expansions
	local ownedItems = 0
	
	for _, item in ipairs(ShopData.data.cosmetics) do
		if ShopData.userOwnsItem(localPlayer.UserId, item.id) then
			ownedItems = ownedItems + 1
		end
	end
	
	for _, item in ipairs(ShopData.data.expansions) do
		if ShopData.userOwnsItem(localPlayer.UserId, item.id) then
			ownedItems = ownedItems + 1
		end
	end
	
	createProgressBar(progressSection, ownedItems, totalItems)
	
	-- Update content canvas size
	task.defer(function()
		local layout = content:FindFirstChildOfClass("UIListLayout")
		if layout then
			content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 40)
		end
	end)
end

-- Shop state management
local Shop = {isOpen = false, isAnimating = false}

function Shop:open()
	if self.isOpen or self.isAnimating then return end
	
	self.isAnimating = true
	self.isOpen = true
	
	if not dim or not panel then
		warn("Shop GUI elements missing!")
		self.isAnimating = false
		self.isOpen = false
		return
	end
	
	dim.Visible = true
	panel.Visible = true
	dim.BackgroundTransparency = 1
	panel.Position = UDim2.new(0.5, 0, 0.5, 100)
	panel.Size = UDim2.new(0, 900, 0, 600)
	
	Utils.tween(dim, ANIM.MED, {BackgroundTransparency = 0.5})
	Utils.tween(panel, ANIM.BOUNCE, {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 1000, 0, 700)
	})
	
	Sfx:play("open")
	
	task.delay(0.45, function()
		self.isAnimating = false
	end)
end

function Shop:close()
	if not self.isOpen or self.isAnimating then return end
	
	self.isAnimating = true
	self.isOpen = false
	
	Utils.tween(dim, ANIM.FAST, {BackgroundTransparency = 1})
	Utils.tween(panel, ANIM.MED, {
		Position = UDim2.new(0.5, 0, 0.5, 100),
		Size = UDim2.new(0, 900, 0, 600)
	})
	
	Sfx:play("close")
	
	task.delay(0.3, function()
		dim.Visible = false
		panel.Visible = false
		self.isAnimating = false
	end)
end

function Shop:toggle()
	if self.isOpen then
		self:close()
	else
		self:open()
	end
end

-- Initialize shop
local function initializeShop()
	local navBar, content = createShopGUI()
	if not navBar or not content then return end
	
	buildShopContent(navBar, content)
	
	-- Connect close button
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
end

-- Create and connect shop button
toggle = createShopButton()
if toggle then
	toggle.MouseButton1Click:Connect(function()
		Shop:toggle()
	end)
end

-- Initialize the shop
initializeShop()

-- Handle input
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		Shop:toggle()
	end
	if input.KeyCode == Enum.KeyCode.Escape and Shop.isOpen then
		Shop:close()
	end
end)

-- Character respawn handling
local function onCharacterAdded()
	task.wait(0.5)
	toggle = createShopButton()
	if toggle then
		toggle.MouseButton1Click:Connect(function()
			Shop:toggle()
		end)
	end
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Keep button alive
task.spawn(function()
	while true do
		task.wait(2)
		if not toggle or not toggle.Parent then
			toggle = createShopButton()
			if toggle then
				toggle.MouseButton1Click:Connect(function()
					Shop:toggle()
				end)
			end
		end
	end
end)

print("🎀 SANRIO SHOP — Child-Centric Enhanced Version loaded!")
print("✨ Features: Larger tap targets, simplified navigation, visual feedback")
print("🛡️ Parental controls and ethical monetization enabled")