-- Simple, robust, self-contained Shop (Client LocalScript)
-- No server dependencies; clean open/close; safe prompts; minimal moving parts

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Data: Configure here
local PRODUCTS = {
	{id = 1897730242, name = "Starter Cash", amount = 1000, priceR$ = 49},
	{id = 1897730373, name = "Builder Pack", amount = 5000, priceR$ = 199},
	{id = 1897730467, name = "Tycoon Bundle", amount = 10000, priceR$ = 349},
	{id = 1897730581, name = "Deluxe Pack", amount = 50000, priceR$ = 999},
}

local PASSES = {
	{id = 1412171840, name = "Auto Collect", priceR$ = 99},
	{id = 1398974710, name = "2x Cash", priceR$ = 199},
}

-- Utils
local function comma(n)
	local s = tostring(n)
	while true do
		local new, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		s = new
		if k == 0 then break end
	end
	return s
end

local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end

-- Clean any old GUIs
for _, n in ipairs({"SHOP_UI","SHOP_TOGGLE"}) do
	local ex = playerGui:FindFirstChild(n)
	if ex then ex:Destroy() end
end

-- Create toggle button (always visible)
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "SHOP_TOGGLE"
toggleGui.ResetOnSpawn = false
toggleGui.IgnoreGuiInset = true
toggleGui.DisplayOrder = 10000
toggleGui.Parent = playerGui

local toggle = Instance.new("TextButton")
toggle.Name = "Open"
toggle.Size = UDim2.fromOffset(180, 56)
toggle.Position = UDim2.new(0.04, 0, 0.13, 0)
toggle.BackgroundColor3 = Color3.fromRGB(255, 110, 157)
toggle.Text = "SHOP"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 24
toggle.AutoButtonColor = true
toggle.Parent = toggleGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 24)
toggleCorner.Parent = toggle

-- Main shop UI
local ui = Instance.new("ScreenGui")
ui.Name = "SHOP_UI"
ui.ResetOnSpawn = false
ui.IgnoreGuiInset = true
ui.DisplayOrder = 9000
ui.Enabled = false
ui.Parent = playerGui

local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.BackgroundColor3 = Color3.new(0,0,0)
dim.BackgroundTransparency = 1
dim.Size = UDim2.fromScale(1,1)
dim.Text = ""
dim.AutoButtonColor = false
dim.Parent = ui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 980, 0, 720)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(255, 252, 250)
panel.BorderSizePixel = 0
panel.Parent = ui

local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 18)
pCorner.Parent = panel

local pStroke = Instance.new("UIStroke")
pStroke.Thickness = 1.5
pStroke.Color = Color3.fromRGB(220,215,220)
pStroke.Parent = panel

local header = Instance.new("Frame")
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -24, 0, 64)
header.Position = UDim2.new(0, 12, 0, 12)
header.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Text = "Sanrio Shop"
title.TextColor3 = Color3.fromRGB(30,25,30)
title.Font = Enum.Font.GothamBold
title.TextSize = 30
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, -60, 1, 0)
title.Parent = header

local close = Instance.new("TextButton")
close.Name = "Close"
close.Size = UDim2.fromOffset(40,40)
close.Position = UDim2.new(1, -40, 0, 0)
close.AnchorPoint = Vector2.new(1, 0)
close.BackgroundColor3 = Color3.fromRGB(235, 60, 60)
close.Text = "✕"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 20
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1,0)
closeCorner.Parent = close

-- Tabs container
local tabBar = Instance.new("Frame")
tabBar.BackgroundTransparency = 1
tabBar.Size = UDim2.new(1, -24, 0, 44)
tabBar.Position = UDim2.new(0, 12, 0, 84)
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar

local pages = Instance.new("Frame")
pages.BackgroundTransparency = 1
pages.Size = UDim2.new(1, -24, 1, -150)
pages.Position = UDim2.new(0, 12, 0, 136)
pages.Parent = panel

local function newTab(text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(160, 44)
	b.BackgroundColor3 = Color3.fromRGB(255, 248, 245)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(30,25,30)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 18
	b.AutoButtonColor = true
	b.Parent = tabBar
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(220,215,220); s.Parent = b
	return b
end

local function newPage()
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1,1)
	f.Visible = false
	f.Parent = pages
	return f
end

local homeTab = newTab("Home")
local cashTab = newTab("Cash")
local passTab = newTab("Gamepasses")

local homePage = newPage()
local cashPage = newPage()
local passPage = newPage()

local current = nil
local function selectTab(name)
	for _, child in ipairs(tabBar:GetChildren()) do
		if child:IsA("TextButton") then
			child.BackgroundColor3 = Color3.fromRGB(255, 248, 245)
		end
	end
	for _, child in ipairs(pages:GetChildren()) do
		if child:IsA("Frame") then child.Visible = false end
	end

	if name == "Home" then
		homeTab.BackgroundColor3 = Color3.fromRGB(245, 240, 240)
		homePage.Visible = true
	elseif name == "Cash" then
		cashTab.BackgroundColor3 = Color3.fromRGB(245, 240, 240)
		cashPage.Visible = true
	elseif name == "Gamepasses" then
		passTab.BackgroundColor3 = Color3.fromRGB(245, 240, 240)
		passPage.Visible = true
	end
	current = name
end

-- Build Home page
do
	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Text = "Welcome! Grab cash bundles and gamepasses."
	txt.TextColor3 = Color3.fromRGB(30,25,30)
	txt.Font = Enum.Font.Gotham
	txt.TextSize = 22
	txt.Size = UDim2.new(1, -24, 0, 28)
	txt.Position = UDim2.new(0, 12, 0, 8)
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Parent = homePage
end

local function card(parent, titleText, descText, rightText)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -8, 0, 96)
	f.BackgroundColor3 = Color3.fromRGB(255, 248, 245)
	f.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = f
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(220,215,220); s.Transparency = 0.3; s.Parent = f

	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Text = titleText
	tl.TextColor3 = Color3.fromRGB(30,25,30)
	tl.Font = Enum.Font.GothamMedium
	tl.TextSize = 20
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.Size = UDim2.new(1, -220, 0, 28)
	tl.Position = UDim2.new(0, 16, 0, 12)
	tl.Parent = f

	local dl = Instance.new("TextLabel")
	dl.BackgroundTransparency = 1
	dl.Text = descText
	dl.TextColor3 = Color3.fromRGB(90,85,90)
	dl.Font = Enum.Font.Gotham
	dl.TextSize = 16
	dl.TextXAlignment = Enum.TextXAlignment.Left
	dl.Size = UDim2.new(1, -220, 0, 20)
	dl.Position = UDim2.new(0, 16, 0, 46)
	dl.Parent = f

	local rb = Instance.new("TextButton")
	rb.Size = UDim2.fromOffset(120, 44)
	rb.Position = UDim2.new(1, -136, 0.5, -22)
	rb.BackgroundColor3 = Color3.fromRGB(123, 189, 255)
	rb.Text = rightText
	rb.TextColor3 = Color3.new(1,1,1)
	rb.Font = Enum.Font.GothamBold
	rb.TextSize = 18
	rb.AutoButtonColor = true
	rb.Parent = f
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1,0); rc.Parent = rb
	return f, rb
end

-- Cash page list
do
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromScale(1,1)
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.ScrollBarThickness = 6
	list.Parent = cashPage

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = list

	local function updateCanvas()
		list.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

	for _, p in ipairs(PRODUCTS) do
		local f, buy = card(list, p.name, ("Instant +%s Cash"):format(comma(p.amount)), ("R$ %d"):format(p.priceR$))
		buy.MouseButton1Click:Connect(function()
			local ok = pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, localPlayer, p.id)
			if ok then
				buy.Text = "Processing..."
				task.delay(1.2, function() if buy and buy.Parent then buy.Text = ("R$ %d"):format(p.priceR$) end end)
			end
		end)
	end
end

-- Gamepasses page list
do
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromScale(1,1)
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.ScrollBarThickness = 6
	list.Parent = passPage

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = list

	local function updateCanvas()
		list.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

	for _, gp in ipairs(PASSES) do
		local f, buy = card(list, gp.name, "Permanent upgrade", ("R$ %d"):format(gp.priceR$))
		buy.BackgroundColor3 = Color3.fromRGB(195, 123, 255)
		buy.MouseButton1Click:Connect(function()
			local ok = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, localPlayer, gp.id)
			if ok then
				buy.Text = "Processing..."
				task.delay(1.2, function() if buy and buy.Parent then buy.Text = ("R$ %d"):format(gp.priceR$) end end)
			end
		end)
	end
end

-- Open/close logic
local isOpen = false

local function open()
	if isOpen then return end
	isOpen = true
	ui.Enabled = true
	dim.BackgroundTransparency = 1
	panel.Position = UDim2.fromScale(0.5, 0.52)
	panel.Size = UDim2.new(0, 960, 0, 690)
	selectTab("Home")
	tween(dim, TweenInfo.new(0.2), {BackgroundTransparency = 0.3})
	tween(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 980, 0, 720),
	})
end

local function closeUI()
	if not isOpen then return end
	isOpen = false
	tween(dim, TweenInfo.new(0.15), {BackgroundTransparency = 1})
	tween(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.new(0, 960, 0, 690),
	})
	task.delay(0.18, function()
		ui.Enabled = false
	end)
end

toggle.MouseButton1Click:Connect(open)
close.MouseButton1Click:Connect(closeUI)
dim.MouseButton1Click:Connect(closeUI)

-- Keyboard shortcut
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		if isOpen then closeUI() else open() end
	end
end)

-- Preload a couple small assets (optional)
pcall(function()
	ContentProvider:PreloadAsync({toggle})
end)

print("Simple Shop loaded.")

