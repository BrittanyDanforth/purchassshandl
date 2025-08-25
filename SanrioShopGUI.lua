-- 🎀 Sanrio Tycoon Shop GUI System
-- Modern, animated shop interface with multiple sections

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create Main GUI
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "SanrioShopGUI"
shopGui.ResetOnSpawn = false
shopGui.Parent = playerGui

-- 🎨 Color Scheme
local COLORS = {
    Primary = Color3.fromRGB(255, 182, 193), -- Light Pink
    Secondary = Color3.fromRGB(255, 105, 180), -- Hot Pink
    Accent = Color3.fromRGB(255, 215, 0), -- Gold
    Background = Color3.fromRGB(255, 250, 250), -- Snow
    Dark = Color3.fromRGB(50, 50, 50), -- Dark Grey
    Success = Color3.fromRGB(144, 238, 144), -- Light Green
    Error = Color3.fromRGB(255, 99, 71), -- Tomato
    VIP = Color3.fromRGB(255, 215, 0), -- Gold
    Premium = Color3.fromRGB(147, 51, 234) -- Purple
}

-- 🛍️ Shop Button (Bottom Center)
local shopButton = Instance.new("ImageButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0, 100, 0, 100)
shopButton.Position = UDim2.new(0.5, -50, 1, -120)
shopButton.Image = "rbxassetid://SHOPBUTTONICON" -- Cute shop icon
shopButton.BackgroundTransparency = 0.1
shopButton.BackgroundColor3 = COLORS.Primary
shopButton.Parent = shopGui

local shopButtonCorner = Instance.new("UICorner")
shopButtonCorner.CornerRadius = UDim.new(0.5, 0)
shopButtonCorner.Parent = shopButton

local shopButtonStroke = Instance.new("UIStroke")
shopButtonStroke.Color = COLORS.Secondary
shopButtonStroke.Thickness = 3
shopButtonStroke.Parent = shopButton

-- Add bounce animation to shop button
local function animateShopButton()
    local bounce = TweenService:Create(shopButton, 
        TweenInfo.new(0.5, Enum.EasingStyle.Bounce), 
        {Size = UDim2.new(0, 110, 0, 110), Position = UDim2.new(0.5, -55, 1, -125)}
    )
    local shrink = TweenService:Create(shopButton, 
        TweenInfo.new(0.5, Enum.EasingStyle.Bounce), 
        {Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0.5, -50, 1, -120)}
    )
    
    while true do
        wait(3)
        bounce:Play()
        wait(0.5)
        shrink:Play()
        wait(0.5)
    end
end

spawn(animateShopButton)

-- 📱 Main Shop Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainShopFrame"
mainFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.Visible = false
mainFrame.Parent = shopGui

local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 20)
mainFrameCorner.Parent = mainFrame

local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = COLORS.Primary
mainFrameStroke.Thickness = 4
mainFrameStroke.Parent = mainFrame

-- 🎀 Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundColor3 = COLORS.Primary
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = header

local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0.5, 0)
headerBottom.Position = UDim2.new(0, 0, 0.5, 0)
headerBottom.BackgroundColor3 = COLORS.Primary
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.6, 0, 0.7, 0)
title.Position = UDim2.new(0.2, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "✨ Sanrio Shop ✨"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.Cartoon
title.Parent = header

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0.5, -20)
closeButton.BackgroundColor3 = COLORS.Error
closeButton.Text = "✖"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.5, 0)
closeCorner.Parent = closeButton

-- 💰 Currency Display
local currencyFrame = Instance.new("Frame")
currencyFrame.Name = "CurrencyDisplay"
currencyFrame.Size = UDim2.new(0.35, 0, 0.8, 0)
currencyFrame.Position = UDim2.new(0.01, 0, 0.1, 0)
currencyFrame.BackgroundTransparency = 1
currencyFrame.Parent = header

local currencyLayout = Instance.new("UIListLayout")
currencyLayout.FillDirection = Enum.FillDirection.Horizontal
currencyLayout.Padding = UDim.new(0, 10)
currencyLayout.Parent = currencyFrame

-- Create currency displays
local function createCurrencyDisplay(name, symbol, color)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.3, 0, 1, 0)
    container.BackgroundColor3 = Color3.new(0, 0, 0)
    container.BackgroundTransparency = 0.3
    container.Parent = currencyFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = symbol .. " 0"
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = container
    
    return label
end

local coinsDisplay = createCurrencyDisplay("Coins", "🪙", COLORS.Accent)
local gemsDisplay = createCurrencyDisplay("Gems", "💎", COLORS.Premium)
local heartsDisplay = createCurrencyDisplay("Hearts", "💖", COLORS.Secondary)

-- 📑 Category Tabs
local categoryFrame = Instance.new("ScrollingFrame")
categoryFrame.Name = "Categories"
categoryFrame.Size = UDim2.new(0.15, 0, 0.88, 0)
categoryFrame.Position = UDim2.new(0, 0, 0.12, 0)
categoryFrame.BackgroundColor3 = COLORS.Primary
categoryFrame.BackgroundTransparency = 0.5
categoryFrame.BorderSizePixel = 0
categoryFrame.ScrollBarThickness = 4
categoryFrame.Parent = mainFrame

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.Padding = UDim.new(0, 5)
categoryLayout.Parent = categoryFrame

-- Shop Categories
local CATEGORIES = {
    {Name = "🎮 Gamepasses", Id = "Gamepasses", Color = COLORS.VIP},
    {Name = "⚡ Boosts", Id = "Boosts", Color = COLORS.Success},
    {Name = "🎯 Instant", Id = "InstantActions", Color = COLORS.Accent},
    {Name = "👥 Workers", Id = "Workers", Color = COLORS.Secondary},
    {Name = "🎨 Decorations", Id = "Decorations", Color = COLORS.Primary},
    {Name = "⬆️ Upgrades", Id = "Upgrades", Color = COLORS.Premium},
    {Name = "🎁 Gacha", Id = "Gacha", Color = COLORS.Error},
    {Name = "👑 Prestige", Id = "Prestige", Color = COLORS.VIP},
    {Name = "🎉 Limited", Id = "LimitedOffers", Color = COLORS.Error},
    {Name = "📅 Daily", Id = "Daily", Color = COLORS.Success},
    {Name = "🎯 Quests", Id = "Quests", Color = COLORS.Secondary}
}

local categoryButtons = {}
local currentCategory = "Gamepasses"

-- 📦 Content Area
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(0.85, -10, 0.88, -10)
contentFrame.Position = UDim2.new(0.15, 5, 0.12, 5)
contentFrame.BackgroundColor3 = Color3.new(1, 1, 1)
contentFrame.BackgroundTransparency = 0.95
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 8
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIGridLayout")
contentLayout.CellSize = UDim2.new(0.23, -10, 0.3, -10)
contentLayout.CellPadding = UDim2.new(0, 15, 0, 15)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentFrame

-- Create Category Buttons
for i, category in ipairs(CATEGORIES) do
    local button = Instance.new("TextButton")
    button.Name = category.Id
    button.Size = UDim2.new(1, -10, 0, 50)
    button.BackgroundColor3 = category.Color
    button.BackgroundTransparency = 0.3
    button.Text = category.Name
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.Cartoon
    button.Parent = categoryFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = button
    
    categoryButtons[category.Id] = button
    
    button.MouseButton1Click:Connect(function()
        currentCategory = category.Id
        updateShopContent(category.Id)
        
        -- Update button states
        for _, btn in pairs(categoryButtons) do
            btn.BackgroundTransparency = 0.3
        end
        button.BackgroundTransparency = 0
    end)
end

-- 🛍️ Create Item Card
local function createItemCard(itemData, section)
    local card = Instance.new("Frame")
    card.Name = itemData.Name
    card.BackgroundColor3 = Color3.new(1, 1, 1)
    card.Parent = contentFrame
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 15)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = COLORS.Primary
    cardStroke.Thickness = 2
    cardStroke.Parent = card
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.8, 0, 0.5, 0)
    icon.Position = UDim2.new(0.1, 0, 0.05, 0)
    icon.BackgroundTransparency = 1
    icon.Image = itemData.Icon or "rbxassetid://PLACEHOLDER"
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = card
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
    nameLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = itemData.Name
    nameLabel.TextColor3 = COLORS.Dark
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = card
    
    -- Price
    local priceFrame = Instance.new("Frame")
    priceFrame.Size = UDim2.new(0.8, 0, 0.12, 0)
    priceFrame.Position = UDim2.new(0.1, 0, 0.7, 0)
    priceFrame.BackgroundColor3 = COLORS.Primary
    priceFrame.Parent = card
    
    local priceCorner = Instance.new("UICorner")
    priceCorner.CornerRadius = UDim.new(0, 8)
    priceCorner.Parent = priceFrame
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(1, 0, 1, 0)
    priceLabel.BackgroundTransparency = 1
    
    -- Handle different price types
    if itemData.Price then
        if itemData.Price.Currency == "Robux" then
            priceLabel.Text = "R$ " .. itemData.Price.Amount
            priceFrame.BackgroundColor3 = COLORS.Success
        elseif itemData.Price.Currency == "Coins" then
            priceLabel.Text = "🪙 " .. itemData.Price.Amount
            priceFrame.BackgroundColor3 = COLORS.Accent
        elseif itemData.Price.Currency == "Gems" then
            priceLabel.Text = "💎 " .. itemData.Price.Amount
            priceFrame.BackgroundColor3 = COLORS.Premium
        elseif itemData.Price.Currency == "Hearts" then
            priceLabel.Text = "💖 " .. itemData.Price.Amount
            priceFrame.BackgroundColor3 = COLORS.Secondary
        end
    elseif itemData.GamepassId then
        priceLabel.Text = "R$ " .. itemData.Price
        priceFrame.BackgroundColor3 = COLORS.Success
    end
    
    priceLabel.TextColor3 = Color3.new(1, 1, 1)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.SourceSansBold
    priceLabel.Parent = priceFrame
    
    -- Buy Button
    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(0.8, 0, 0.1, 0)
    buyButton.Position = UDim2.new(0.1, 0, 0.85, 0)
    buyButton.BackgroundColor3 = COLORS.Success
    buyButton.Text = "BUY"
    buyButton.TextColor3 = Color3.new(1, 1, 1)
    buyButton.TextScaled = true
    buyButton.Font = Enum.Font.SourceSansBold
    buyButton.Parent = card
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 8)
    buyCorner.Parent = buyButton
    
    -- Special labels
    if itemData.OneTimePurchase then
        local oneTimeLabel = Instance.new("TextLabel")
        oneTimeLabel.Size = UDim2.new(0.3, 0, 0.08, 0)
        oneTimeLabel.Position = UDim2.new(0.65, 0, 0.02, 0)
        oneTimeLabel.BackgroundColor3 = COLORS.Error
        oneTimeLabel.Text = "1x"
        oneTimeLabel.TextColor3 = Color3.new(1, 1, 1)
        oneTimeLabel.TextScaled = true
        oneTimeLabel.Font = Enum.Font.SourceSansBold
        oneTimeLabel.Parent = card
        
        local oneTimeCorner = Instance.new("UICorner")
        oneTimeCorner.CornerRadius = UDim.new(0, 4)
        oneTimeCorner.Parent = oneTimeLabel
    end
    
    -- Hover effects
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {
            Size = UDim2.new(0.23, -5, 0.3, -5)
        }):Play()
        cardStroke.Thickness = 4
    end)
    
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {
            Size = UDim2.new(0.23, -10, 0.3, -10)
        }):Play()
        cardStroke.Thickness = 2
    end)
    
    -- Buy button click
    buyButton.MouseButton1Click:Connect(function()
        if itemData.GamepassId then
            -- Gamepass purchase
            MarketplaceService:PromptGamePassPurchase(player, itemData.GamepassId)
        else
            -- Regular item purchase
            -- Fire remote event to server
            print("Purchasing:", itemData.Name)
        end
    end)
    
    return card
end

-- Update shop content based on category
function updateShopContent(category)
    -- Clear existing content
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Show loading
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Size = UDim2.new(1, 0, 1, 0)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "Loading..."
    loadingLabel.TextColor3 = COLORS.Dark
    loadingLabel.TextScaled = true
    loadingLabel.Font = Enum.Font.Cartoon
    loadingLabel.Parent = contentFrame
    
    wait(0.1) -- Small delay for effect
    loadingLabel:Destroy()
    
    -- Load items based on category
    -- This would connect to your server data
    print("Loading category:", category)
end

-- Shop open/close animation
local shopOpen = false

local function toggleShop()
    shopOpen = not shopOpen
    
    if shopOpen then
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.9, 0, 0.9, 0)
        }):Play()
        
        -- Load default category
        updateShopContent("Gamepasses")
    else
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            mainFrame.Visible = false
        end)
    end
end

-- Connect buttons
shopButton.MouseButton1Click:Connect(toggleShop)
closeButton.MouseButton1Click:Connect(function()
    if shopOpen then toggleShop() end
end)

-- Update currency displays
spawn(function()
    while true do
        wait(1)
        -- Update from server data
        coinsDisplay.Text = "🪙 " .. tostring(player.leaderstats.Coins.Value or 0)
        -- gemsDisplay.Text = "💎 " .. tostring(playerData.Gems or 0)
        -- heartsDisplay.Text = "💖 " .. tostring(playerData.Hearts or 0)
    end
end)

print("🎀 Sanrio Shop GUI Loaded!")