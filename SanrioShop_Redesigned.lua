--[[
	🌸 SANRIO SHOP REDESIGNED - BEST PRACTICES EDITION
	
	Following UI/UX best practices:
	- Subtle monetization (no aggressive "BUY NOW")
	- Mobile-first responsive design
	- Cute pastel color palette
	- Gentle animations and feedback
	- Non-intrusive shop access
	- Psychology-driven patterns
--]]

-- // Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Remote access
local TycoonRemotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")

-- // PASTEL COLOR PALETTE (High lightness, low saturation)
local COLORS = {
	-- Base pastels
	pink = Color3.fromRGB(255, 230, 238),      -- Soft pink
	blue = Color3.fromRGB(230, 243, 255),      -- Baby blue
	purple = Color3.fromRGB(243, 235, 255),    -- Lavender
	mint = Color3.fromRGB(235, 255, 245),      -- Mint green
	peach = Color3.fromRGB(255, 240, 230),     -- Peach
	
	-- UI colors
	background = Color3.fromRGB(255, 252, 250), -- Warm white
	surface = Color3.fromRGB(255, 255, 255),    -- Pure white
	surfaceAlt = Color3.fromRGB(252, 250, 255), -- Slight purple tint
	
	-- Text (high contrast)
	text = Color3.fromRGB(80, 70, 85),          -- Deep purple-grey
	textLight = Color3.fromRGB(120, 110, 130),  -- Lighter purple-grey
	
	-- Accents
	accent = Color3.fromRGB(255, 180, 210),     -- Pastel pink accent
	success = Color3.fromRGB(180, 255, 200),    -- Pastel green
	warning = Color3.fromRGB(255, 230, 180),    -- Pastel yellow
	
	-- Subtle borders
	border = Color3.fromRGB(240, 235, 245),     -- Very light purple
	shadow = Color3.fromRGB(230, 225, 235),     -- Soft shadow
}

-- // Animation presets (gentle, not jarring)
local ANIM = {
	GENTLE = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	SOFT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SMOOTH = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	BOUNCE = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
}

-- // Utils
local function tween(obj, info, props)
	if not obj then return end
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function isMobile()
	local viewport = workspace.CurrentCamera.ViewportSize
	return viewport.X < 800 or GuiService:IsTenFootInterface()
end

local function formatNumber(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	else
		return tostring(n)
	end
end

-- // Sound effects (gentle, not loud)
local sounds = {}
local function createSound(id, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.3 -- Keep sounds quiet
	sound.Parent = SoundService
	return sound
end

sounds.tap = createSound("rbxassetid://876939830", 0.25)     -- Soft tap
sounds.swoosh = createSound("rbxassetid://452267918", 0.3)   -- Gentle swoosh
sounds.success = createSound("rbxassetid://6895409578", 0.4) -- Pleasant chime

-- // Shop Data
local ShopData = {
	cash = {
		{id = 1897730242, amount = 1000, name = "Starter Bundle", icon = "💝", description = "A little boost to help you grow!", popular = false},
		{id = 1897730373, amount = 5000, name = "Growth Bundle", icon = "🌸", description = "Perfect for your next upgrade", popular = true},
		{id = 1897730467, amount = 10000, name = "Success Bundle", icon = "✨", description = "Reach your goals faster", popular = false},
		{id = 1897730581, amount = 50000, name = "Dream Bundle", icon = "🌟", description = "Make your dreams come true", popular = false},
	},
	gamepasses = {
		{id = 1412171840, name = "Auto Collect", icon = "🎀", description = "Relax while cash collects itself!", hasToggle = true},
		{id = 1398974710, name = "2x Cash", icon = "💖", description = "Double your happiness!", popular = true},
	}
}

-- Ownership cache
local ownershipCache = {}

-- // Create subtle shop access button (small, non-intrusive)
local function createShopButton()
	local buttonScreen = playerGui:FindFirstChild("SHOP_BUTTON_CUTE") or Instance.new("ScreenGui")
	buttonScreen.Name = "SHOP_BUTTON_CUTE"
	buttonScreen.ResetOnSpawn = false
	buttonScreen.DisplayOrder = 10
	buttonScreen.Parent = playerGui
	
	-- Small, cute button positioned out of the way
	local button = buttonScreen:FindFirstChild("ShopButton") or Instance.new("TextButton")
	button.Name = "ShopButton"
	button.Size = UDim2.fromOffset(50, 50)
	button.Position = UDim2.new(0.02, 0, 0.5, -100) -- Left side, away from controls
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.BackgroundColor3 = COLORS.surface
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = buttonScreen
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	
	-- Soft shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = COLORS.shadow
	shadow.ImageTransparency = 0.6
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.Position = UDim2.new(0, -5, 0, -5)
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.ZIndex = 0
	shadow.Parent = button
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "🛍️"
	icon.TextScaled = true
	icon.Font = Enum.Font.Gotham
	icon.Parent = button
	
	-- Subtle border
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.border
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = button
	
	-- Gentle hover animation
	button.MouseEnter:Connect(function()
		tween(button, ANIM.GENTLE, {Size = UDim2.fromOffset(55, 55)})
		tween(stroke, ANIM.GENTLE, {Transparency = 0.2})
	end)
	
	button.MouseLeave:Connect(function()
		tween(button, ANIM.GENTLE, {Size = UDim2.fromOffset(50, 50)})
		tween(stroke, ANIM.GENTLE, {Transparency = 0.5})
	end)
	
	-- Subtle pulse animation
	task.spawn(function()
		while button.Parent do
			tween(icon, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Rotation = 5
			})
			task.wait(2)
			tween(icon, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Rotation = -5
			})
			task.wait(2)
		end
	end)
	
	return button
end

-- // Main Shop UI
local shopScreen, shopFrame
local currentPage = "home"

local function createShopUI()
	shopScreen = playerGui:FindFirstChild("SHOP_UI_CUTE") or Instance.new("ScreenGui")
	shopScreen.Name = "SHOP_UI_CUTE"
	shopScreen.ResetOnSpawn = false
	shopScreen.DisplayOrder = 100
	shopScreen.Enabled = false
	shopScreen.Parent = playerGui
	
	-- Soft dimmed background
	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.6
	dim.Parent = shopScreen
	
	-- Main shop container (mobile-friendly size)
	shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.fromOffset(400, 600)
	shopFrame.Position = UDim2.fromScale(0.5, 0.5)
	shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFrame.BackgroundColor3 = COLORS.background
	shopFrame.Parent = shopScreen
	
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 24)
	frameCorner.Parent = shopFrame
	
	-- Soft gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.surfaceAlt),
		ColorSequenceKeypoint.new(1, COLORS.background)
	})
	gradient.Rotation = 90
	gradient.Parent = shopFrame
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 80)
	header.BackgroundColor3 = COLORS.surface
	header.Parent = shopFrame
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 24)
	headerCorner.Parent = header
	
	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0, 24)
	headerBottom.Position = UDim2.new(0, 0, 1, -24)
	headerBottom.BackgroundColor3 = COLORS.surface
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Kawaii Shop"
	title.TextColor3 = COLORS.text
	title.TextScaled = true
	title.Font = Enum.Font.Gotham
	title.Parent = header
	
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 28
	titleConstraint.Parent = title
	
	-- Close button (subtle X)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(40, 40)
	closeButton.Position = UDim2.new(1, -50, 0.5, 0)
	closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
	closeButton.BackgroundColor3 = COLORS.pink
	closeButton.Text = "×"
	closeButton.TextColor3 = COLORS.text
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Gotham
	closeButton.AutoButtonColor = false
	closeButton.Parent = header
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton
	
	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -40, 1, -100)
	content.Position = UDim2.new(0, 20, 0, 90)
	content.BackgroundTransparency = 1
	content.Parent = shopFrame
	
	-- Scale UI for different devices
	local scale = Instance.new("UIScale")
	scale.Parent = shopFrame
	
	local function updateScale()
		local viewport = workspace.CurrentCamera.ViewportSize
		local baseScale = math.min(viewport.X / 600, viewport.Y / 800)
		scale.Scale = math.clamp(baseScale * 0.9, 0.6, 1.2)
		
		-- Adjust size for mobile
		if isMobile() then
			shopFrame.Size = UDim2.fromOffset(380, 550)
		else
			shopFrame.Size = UDim2.fromOffset(400, 600)
		end
	end
	
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	updateScale()
	
	return content, closeButton, dim
end

-- // Create item cards with subtle design
local function createItemCard(item, itemType, parent)
	local card = Instance.new("Frame")
	card.Name = "ItemCard"
	card.Size = UDim2.new(1, 0, 0, 140)
	card.BackgroundColor3 = COLORS.surface
	card.Parent = parent
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card
	
	-- Subtle border
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.border
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = card
	
	-- Icon background
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.fromOffset(60, 60)
	iconBg.Position = UDim2.new(0, 20, 0.5, 0)
	iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = itemType == "pass" and COLORS.purple or COLORS.blue
	iconBg.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.3, 0)
	iconCorner.Parent = iconBg
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Text = item.icon or "🎁"
	icon.TextScaled = true
	icon.Font = Enum.Font.Gotham
	icon.Parent = iconBg
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -200, 0, 24)
	title.Position = UDim2.new(0, 90, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = item.name
	title.TextColor3 = COLORS.text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextScaled = true
	title.Font = Enum.Font.GothamSemibold
	title.Parent = card
	
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 20
	titleConstraint.Parent = title
	
	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -110, 0, 40)
	desc.Position = UDim2.new(0, 90, 0, 45)
	desc.BackgroundTransparency = 1
	desc.Text = item.description
	desc.TextColor3 = COLORS.textLight
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.TextScaled = true
	desc.Font = Enum.Font.Gotham
	desc.Parent = card
	
	local descConstraint = Instance.new("UITextSizeConstraint")
	descConstraint.MaxTextSize = 14
	descConstraint.Parent = desc
	
	-- Popular badge (subtle, not aggressive)
	if item.popular then
		local badge = Instance.new("Frame")
		badge.Size = UDim2.fromOffset(70, 20)
		badge.Position = UDim2.new(1, -80, 0, 10)
		badge.BackgroundColor3 = COLORS.warning
		badge.Parent = card
		
		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0.5, 0)
		badgeCorner.Parent = badge
		
		local badgeText = Instance.new("TextLabel")
		badgeText.Size = UDim2.fromScale(1, 1)
		badgeText.BackgroundTransparency = 1
		badgeText.Text = "Popular"
		badgeText.TextColor3 = COLORS.text
		badgeText.TextScaled = true
		badgeText.Font = Enum.Font.Gotham
		badgeText.Parent = badge
		
		local badgeConstraint = Instance.new("UITextSizeConstraint")
		badgeConstraint.MaxTextSize = 12
		badgeConstraint.Parent = badgeText
	end
	
	-- Price/Action button (subtle, not "BUY NOW!")
	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.fromOffset(100, 36)
	actionButton.Position = UDim2.new(1, -110, 1, -20)
	actionButton.AnchorPoint = Vector2.new(0.5, 0.5)
	actionButton.BackgroundColor3 = itemType == "pass" and COLORS.purple or COLORS.mint
	actionButton.AutoButtonColor = false
	actionButton.Parent = card
	
	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0.5, 0)
	actionCorner.Parent = actionButton
	
	local actionText = Instance.new("TextLabel")
	actionText.Size = UDim2.fromScale(1, 1)
	actionText.BackgroundTransparency = 1
	actionText.TextColor3 = COLORS.text
	actionText.TextScaled = true
	actionText.Font = Enum.Font.GothamMedium
	actionText.Parent = actionButton
	
	local actionConstraint = Instance.new("UITextSizeConstraint")
	actionConstraint.MaxTextSize = 16
	actionConstraint.Parent = actionText
	
	-- Set price text
	if itemType == "cash" then
		actionText.Text = "$" .. formatNumber(item.amount)
	else
		-- Check ownership for gamepasses
		local owned = false
		pcall(function()
			owned = MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, item.id)
		end)
		
		if owned then
			actionButton.BackgroundColor3 = COLORS.success
			actionText.Text = "Owned ✓"
			
			-- Add toggle for auto-collect
			if item.hasToggle then
				-- Create toggle UI here
			end
		else
			actionText.Text = "Get"
		end
	end
	
	-- Gentle hover effect
	local originalSize = actionButton.Size
	actionButton.MouseEnter:Connect(function()
		tween(actionButton, ANIM.GENTLE, {Size = UDim2.fromOffset(105, 38)})
		tween(stroke, ANIM.GENTLE, {Transparency = 0.4})
	end)
	
	actionButton.MouseLeave:Connect(function()
		tween(actionButton, ANIM.GENTLE, {Size = originalSize})
		tween(stroke, ANIM.GENTLE, {Transparency = 0.7})
	end)
	
	-- Purchase logic
	actionButton.MouseButton1Click:Connect(function()
		if sounds.tap then sounds.tap:Play() end
		
		if itemType == "cash" then
			actionText.Text = "..."
			MarketplaceService:PromptProductPurchase(localPlayer, item.id)
		else
			if not owned then
				actionText.Text = "..."
				MarketplaceService:PromptGamePassPurchase(localPlayer, item.id)
			end
		end
	end)
	
	-- Card hover animation
	card.MouseEnter:Connect(function()
		tween(card, ANIM.GENTLE, {BackgroundTransparency = 0.05})
	end)
	
	card.MouseLeave:Connect(function()
		tween(card, ANIM.GENTLE, {BackgroundTransparency = 0})
	end)
	
	return card
end

-- // Build shop pages
local function buildShopContent(content)
	-- Clear existing content
	for _, child in ipairs(content:GetChildren()) do
		child:Destroy()
	end
	
	-- Create scrolling frame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = COLORS.border
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = content
	
	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	
	-- Header text
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Text = "✨ Enhance Your Experience"
	header.TextColor3 = COLORS.text
	header.TextScaled = true
	header.Font = Enum.Font.GothamMedium
	header.Parent = scroll
	
	local headerConstraint = Instance.new("UITextSizeConstraint")
	headerConstraint.MaxTextSize = 20
	headerConstraint.Parent = header
	
	-- Add cash bundles
	local cashHeader = Instance.new("TextLabel")
	cashHeader.Size = UDim2.new(1, 0, 0, 24)
	cashHeader.BackgroundTransparency = 1
	cashHeader.Text = "💰 Cash Bundles"
	cashHeader.TextColor3 = COLORS.textLight
	cashHeader.TextXAlignment = Enum.TextXAlignment.Left
	cashHeader.TextScaled = true
	cashHeader.Font = Enum.Font.Gotham
	cashHeader.LayoutOrder = 1
	cashHeader.Parent = scroll
	
	local cashConstraint = Instance.new("UITextSizeConstraint")
	cashConstraint.MaxTextSize = 16
	cashConstraint.Parent = cashHeader
	
	for i, item in ipairs(ShopData.cash) do
		local card = createItemCard(item, "cash", scroll)
		card.LayoutOrder = 10 + i
	end
	
	-- Add gamepasses
	local passHeader = Instance.new("TextLabel")
	passHeader.Size = UDim2.new(1, 0, 0, 24)
	passHeader.BackgroundTransparency = 1
	passHeader.Text = "🎀 Special Upgrades"
	passHeader.TextColor3 = COLORS.textLight
	passHeader.TextXAlignment = Enum.TextXAlignment.Left
	passHeader.TextScaled = true
	passHeader.Font = Enum.Font.Gotham
	passHeader.LayoutOrder = 100
	passHeader.Parent = scroll
	
	local passConstraint = Instance.new("UITextSizeConstraint")
	passConstraint.MaxTextSize = 16
	passConstraint.Parent = passHeader
	
	-- Add spacing
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, 8)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = 99
	spacer.Parent = scroll
	
	for i, item in ipairs(ShopData.gamepasses) do
		local card = createItemCard(item, "pass", scroll)
		card.LayoutOrder = 110 + i
	end
	
	-- Update canvas size
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)
end

-- // Shop state management
local shopOpen = false

local function openShop()
	if shopOpen then return end
	shopOpen = true
	
	if not shopScreen then
		local content, closeButton, dim = createShopUI()
		buildShopContent(content)
		
		-- Connect close button
		closeButton.MouseButton1Click:Connect(function()
			if sounds.tap then sounds.tap:Play() end
			closeShop()
		end)
		
		-- Close on dim click
		dim.MouseButton1Click:Connect(function()
			closeShop()
		end)
	end
	
	shopScreen.Enabled = true
	shopFrame.Size = UDim2.fromOffset(380, 580)
	shopFrame.Position = UDim2.fromScale(0.5, 0.55)
	
	-- Gentle open animation
	tween(shopFrame, ANIM.BOUNCE, {
		Size = isMobile() and UDim2.fromOffset(380, 550) or UDim2.fromOffset(400, 600),
		Position = UDim2.fromScale(0.5, 0.5)
	})
	
	if sounds.swoosh then sounds.swoosh:Play() end
end

local function closeShop()
	if not shopOpen then return end
	shopOpen = false
	
	-- Gentle close animation
	tween(shopFrame, ANIM.SOFT, {
		Size = UDim2.fromOffset(380, 580),
		Position = UDim2.fromScale(0.5, 0.55)
	})
	
	task.wait(0.3)
	if shopScreen then
		shopScreen.Enabled = false
	end
end

-- // Initialize
local shopButton = createShopButton()
shopButton.MouseButton1Click:Connect(function()
	if sounds.tap then sounds.tap:Play() end
	if shopOpen then
		closeShop()
	else
		openShop()
	end
end)

-- Purchase callbacks
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if userId ~= localPlayer.UserId then return end
	
	if wasPurchased then
		if sounds.success then sounds.success:Play() end
		
		-- Show subtle success feedback
		local successToast = Instance.new("Frame")
		successToast.Size = UDim2.fromOffset(200, 50)
		successToast.Position = UDim2.fromScale(0.5, 0.1)
		successToast.AnchorPoint = Vector2.new(0.5, 0.5)
		successToast.BackgroundColor3 = COLORS.success
		successToast.Parent = shopScreen or playerGui
		
		local toastCorner = Instance.new("UICorner")
		toastCorner.CornerRadius = UDim.new(0.5, 0)
		toastCorner.Parent = successToast
		
		local toastText = Instance.new("TextLabel")
		toastText.Size = UDim2.fromScale(1, 1)
		toastText.BackgroundTransparency = 1
		toastText.Text = "Purchase complete! 💖"
		toastText.TextColor3 = COLORS.text
		toastText.TextScaled = true
		toastText.Font = Enum.Font.Gotham
		toastText.Parent = successToast
		
		-- Fade in and out
		successToast.BackgroundTransparency = 1
		toastText.TextTransparency = 1
		
		tween(successToast, ANIM.GENTLE, {BackgroundTransparency = 0})
		tween(toastText, ANIM.GENTLE, {TextTransparency = 0})
		
		task.wait(2)
		
		tween(successToast, ANIM.GENTLE, {BackgroundTransparency = 1})
		tween(toastText, ANIM.GENTLE, {TextTransparency = 1})
		
		task.wait(0.3)
		successToast:Destroy()
	end
	
	-- Refresh shop content
	if shopScreen and shopFrame then
		local content = shopFrame:FindFirstChild("Content")
		if content then
			buildShopContent(content)
		end
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(userId, passId, wasPurchased)
	if userId ~= localPlayer.UserId then return end
	
	if wasPurchased then
		if sounds.success then sounds.success:Play() end
		
		-- Clear cache and refresh
		ownershipCache = {}
		
		if shopScreen and shopFrame then
			local content = shopFrame:FindFirstChild("Content")
			if content then
				task.wait(0.5)
				buildShopContent(content)
			end
		end
	end
end)

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	if input.KeyCode == Enum.KeyCode.M then
		if shopOpen then
			closeShop()
		else
			openShop()
		end
	elseif input.KeyCode == Enum.KeyCode.Escape and shopOpen then
		closeShop()
	end
end)

print("🌸 Cute Pastel Shop UI loaded! Press M to open.")

-- Setup money collection effects (kept from original)
local function setupMoneyEffects()
	if not TycoonRemotes then return end
	local moneyCollectRemote = TycoonRemotes:FindFirstChild("MoneyCollected")
	if not moneyCollectRemote or not moneyCollectRemote:IsA("RemoteEvent") then return end
	
	moneyCollectRemote.OnClientEvent:Connect(function(collectorPart, amount, has2x, isAutoCollect)
		if not collectorPart or not collectorPart.Parent then return end
		
		-- Create cute floating text
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 100, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = localPlayer.PlayerGui
		billboard.Adornee = collectorPart
		
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = "+$" .. formatNumber(amount)
		text.TextColor3 = isAutoCollect and COLORS.mint or COLORS.success
		text.TextStrokeTransparency = 0.8
		text.TextStrokeColor3 = COLORS.surface
		text.TextScaled = true
		text.Font = Enum.Font.GothamBold
		text.Parent = billboard
		
		if has2x then
			text.Text = text.Text .. " ✨"
		end
		
		-- Gentle float up animation
		tween(billboard, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			StudsOffset = Vector3.new(0, 8, 0)
		})
		
		tween(text, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})
		
		Debris:AddItem(billboard, 1.5)
	end)
end

task.spawn(setupMoneyEffects)