--[[
    SANRIO SHOP PROFESSIONAL
    Ultimate Shop System with Modern UI/UX
    
    Features:
    ✓ Beautiful modern UI with smooth animations
    ✓ Home page that opens by default
    ✓ Cash shop with working DevProduct IDs
    ✓ Gamepass shop with ownership checking
    ✓ Responsive design for all devices
    ✓ Professional hover effects and transitions
    ✓ Purchase confirmations and sound effects
    
    Place in StarterPlayer > StarterPlayerScripts
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()

-- Modern color palette
local Theme = {
    Colors = {
        Primary = Color3.fromRGB(255, 182, 193),      -- Light pink
        Secondary = Color3.fromRGB(255, 240, 245),    -- Lavender blush
        Accent = Color3.fromRGB(255, 105, 180),       -- Hot pink
        Success = Color3.fromRGB(144, 238, 144),      -- Light green
        Warning = Color3.fromRGB(255, 218, 185),      -- Peach
        Cash = Color3.fromRGB(50, 205, 50),           -- Lime green
        Premium = Color3.fromRGB(255, 215, 0),        -- Gold
        Background = Color3.fromRGB(255, 250, 250),   -- Snow
        Surface = Color3.fromRGB(255, 255, 255),      -- White
        Text = Color3.fromRGB(51, 51, 51),            -- Dark gray
        TextLight = Color3.fromRGB(255, 255, 255),    -- White
        Shadow = Color3.new(0, 0, 0),                 -- Black
    },
    Corners = {
        Small = 8,
        Medium = 12,
        Large = 16,
        XLarge = 24,
        Round = 999
    },
    Animations = {
        Fast = 0.2,
        Medium = 0.3,
        Slow = 0.5,
        Bounce = 0.4
    }
}

-- Shop configuration with updated DevProduct IDs
local ShopData = {
    CashProducts = {
        {
            id = 3366419712,
            amount = 1000,
            price = 99,
            name = "Starter Pack",
            icon = "rbxassetid://13471778013",
            description = "Perfect for beginners!",
            color = Theme.Colors.Cash
        },
        {
            id = 3366420478,
            amount = 10000,
            price = 499,
            name = "Value Bundle",
            icon = "rbxassetid://13471778013",
            description = "Most popular choice!",
            color = Theme.Colors.Cash,
            badge = "POPULAR",
            badgeColor = Theme.Colors.Accent
        },
        {
            id = 3366420800,
            amount = 25000,
            price = 999,
            name = "Mega Deal",
            icon = "rbxassetid://13471778013",
            description = "Best value for money!",
            color = Theme.Colors.Cash,
            badge = "BEST VALUE",
            badgeColor = Theme.Colors.Premium
        }
    },
    
    Gamepasses = {
        {
            id = 123456789, -- Replace with your actual gamepass ID
            name = "VIP Pass",
            price = 499,
            icon = "rbxassetid://13471761758",
            description = "Exclusive VIP benefits!",
            color = Theme.Colors.Premium,
            benefits = {
                "2x Daily Rewards",
                "VIP Chat Tag",
                "Special Effects",
                "Exclusive Areas"
            }
        },
        {
            id = 234567890, -- Replace with your actual gamepass ID
            name = "Auto Collect",
            price = 299,
            icon = "rbxassetid://13471768529",
            description = "Automatically collect money!",
            color = Color3.fromRGB(135, 206, 250),
            benefits = {
                "Auto-collection",
                "No manual clicking",
                "Works while AFK",
                "Collect from anywhere"
            }
        },
        {
            id = 345678901, -- Replace with your actual gamepass ID
            name = "2x Money",
            price = 399,
            icon = "rbxassetid://18910521455",
            description = "Double all earnings!",
            color = Theme.Colors.Cash,
            benefits = {
                "2x Money from all sources",
                "Stacks with events",
                "Permanent boost",
                "Works with donations"
            }
        },
        {
            id = 456789012, -- Replace with your actual gamepass ID
            name = "Lucky Charm",
            price = 199,
            icon = "rbxassetid://2614987630",
            description = "Increase your luck!",
            color = Theme.Colors.Accent,
            benefits = {
                "Better RNG odds",
                "Rare item chances",
                "Lucky animations",
                "Fortune effects"
            }
        }
    }
}

-- Sound configuration
local SoundIds = {
    Open = "rbxassetid://9114221327",
    Close = "rbxassetid://9114221646",
    Hover = "rbxassetid://10066936758",
    Click = "rbxassetid://9113651332",
    Purchase = "rbxassetid://9113654060",
    Error = "rbxassetid://9113653721",
    Tab = "rbxassetid://9113652400",
    Coin = "rbxassetid://131323304",
    Sparkle = "rbxassetid://9125456973"
}

-- Create sound manager
local SoundManager = {}
SoundManager.sounds = {}

function SoundManager:preload()
    for name, id in pairs(SoundIds) do
        local sound = Instance.new("Sound")
        sound.SoundId = id
        sound.Volume = 0.5
        sound.Parent = SoundService
        self.sounds[name] = sound
    end
end

function SoundManager:play(soundName, volume, pitch)
    local sound = self.sounds[soundName]
    if sound then
        sound.Volume = volume or 0.5
        sound.Pitch = pitch or 1
        sound:Play()
    end
end

-- Utility functions
local Utils = {}

function Utils.tween(obj, props, duration, style, direction, callback)
    local tweenInfo = TweenInfo.new(
        duration or Theme.Animations.Medium,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(obj, tweenInfo, props)
    tween:Play()
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    return tween
end

function Utils.formatNumber(n)
    if n >= 1e9 then
        return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    else
        return tostring(n)
    end
end

function Utils.createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Theme.Corners.Medium)
    corner.Parent = parent
    return corner
end

function Utils.createStroke(parent, thickness, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 2
    stroke.Color = color or Theme.Colors.Shadow
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

function Utils.createGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = colors or ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.9, 0.9))
    }
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

function Utils.createPadding(parent, padding)
    local uiPadding = Instance.new("UIPadding")
    local p = padding or 12
    uiPadding.PaddingTop = UDim.new(0, p)
    uiPadding.PaddingBottom = UDim.new(0, p)
    uiPadding.PaddingLeft = UDim.new(0, p)
    uiPadding.PaddingRight = UDim.new(0, p)
    uiPadding.Parent = parent
    return uiPadding
end

function Utils.createShadow(parent, size, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, size or 10, 1, size or 10)
    shadow.Position = UDim2.new(0, -(size or 10)/2, 0, -(size or 10)/2)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Theme.Colors.Shadow
    shadow.ImageTransparency = transparency or 0.7
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    
    Utils.createCorner(shadow, parent:FindFirstChild("UICorner") and parent.UICorner.CornerRadius.Offset + 2 or Theme.Corners.Medium + 2)
    
    return shadow
end

-- Ownership cache
local ownershipCache = {}
local cacheExpiry = {}

local function checkGamepassOwnership(passId)
    local now = tick()
    
    -- Check cache
    if ownershipCache[passId] and cacheExpiry[passId] and cacheExpiry[passId] > now then
        return ownershipCache[passId]
    end
    
    -- Studio testing
    if RunService:IsStudio() then
        if _G.StudioGamepassPurchases and _G.StudioGamepassPurchases[passId] then
            ownershipCache[passId] = true
            cacheExpiry[passId] = now + 300
            return true
        end
    end
    
    -- Check ownership
    local success, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
    end)
    
    if success then
        ownershipCache[passId] = owns
        cacheExpiry[passId] = now + 300 -- Cache for 5 minutes
        return owns
    end
    
    return false
end

local function clearOwnershipCache(passId)
    ownershipCache[passId] = nil
    cacheExpiry[passId] = nil
end

-- Shop state
local Shop = {
    isOpen = false,
    isAnimating = false,
    currentTab = "Home",
    gui = nil,
    mainFrame = nil,
    contentFrame = nil,
    tabButtons = {},
    pages = {}
}

-- Create modern product card
local function createProductCard(product, productType, parent)
    local card = Instance.new("Frame")
    card.Name = product.name
    card.Size = UDim2.new(0.3, -10, 0, 220)
    card.BackgroundColor3 = Theme.Colors.Surface
    card.Parent = parent
    
    Utils.createCorner(card, Theme.Corners.Large)
    Utils.createStroke(card, 2, product.color or Theme.Colors.Primary, 0.3)
    Utils.createShadow(card, 8, 0.5)
    
    -- Badge
    if product.badge then
        local badge = Instance.new("Frame")
        badge.Size = UDim2.new(0, 120, 0, 28)
        badge.Position = UDim2.new(0.5, 0, 0, -14)
        badge.AnchorPoint = Vector2.new(0.5, 0)
        badge.BackgroundColor3 = product.badgeColor or Theme.Colors.Accent
        badge.ZIndex = 2
        badge.Parent = card
        
        Utils.createCorner(badge, Theme.Corners.Small)
        
        local badgeText = Instance.new("TextLabel")
        badgeText.Size = UDim2.new(1, 0, 1, 0)
        badgeText.BackgroundTransparency = 1
        badgeText.Text = product.badge
        badgeText.TextColor3 = Theme.Colors.TextLight
        badgeText.TextScaled = true
        badgeText.Font = Enum.Font.GothamBold
        badgeText.Parent = badge
    end
    
    -- Icon container
    local iconContainer = Instance.new("Frame")
    iconContainer.Size = UDim2.new(1, -20, 0, 80)
    iconContainer.Position = UDim2.new(0, 10, 0, 20)
    iconContainer.BackgroundColor3 = Theme.Colors.Secondary
    iconContainer.Parent = card
    
    Utils.createCorner(iconContainer, Theme.Corners.Medium)
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = product.icon
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = iconContainer
    
    -- Glow effect
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1.5, 0, 1.5, 0)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxasset://textures/ui/LuaChat/9-slice/glow.png"
    glow.ImageColor3 = product.color or Theme.Colors.Primary
    glow.ImageTransparency = 0.8
    glow.ZIndex = icon.ZIndex - 1
    glow.Parent = iconContainer
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.new(0, 10, 0, 110)
    title.BackgroundTransparency = 1
    title.Text = product.name
    title.TextColor3 = Theme.Colors.Text
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = card
    
    -- Description
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -20, 0, 18)
    desc.Position = UDim2.new(0, 10, 0, 138)
    desc.BackgroundTransparency = 1
    desc.Text = product.description
    desc.TextColor3 = Theme.Colors.Text
    desc.TextTransparency = 0.3
    desc.TextScaled = true
    desc.Font = Enum.Font.Gotham
    desc.Parent = card
    
    -- Price button
    local priceButton = Instance.new("TextButton")
    priceButton.Size = UDim2.new(1, -20, 0, 36)
    priceButton.Position = UDim2.new(0, 10, 1, -46)
    priceButton.BackgroundColor3 = product.color or Theme.Colors.Primary
    priceButton.AutoButtonColor = false
    priceButton.Text = ""
    priceButton.Parent = card
    
    Utils.createCorner(priceButton, Theme.Corners.Medium)
    
    local priceText = Instance.new("TextLabel")
    priceText.Size = UDim2.new(1, 0, 1, 0)
    priceText.BackgroundTransparency = 1
    priceText.TextColor3 = Theme.Colors.TextLight
    priceText.TextScaled = true
    priceText.Font = Enum.Font.GothamBold
    priceText.Parent = priceButton
    
    -- Set price text
    if productType == "cash" then
        priceText.Text = string.format("R$%d = %s Cash", product.price, Utils.formatNumber(product.amount))
    else
        local owned = checkGamepassOwnership(product.id)
        if owned then
            priceText.Text = "OWNED"
            priceButton.BackgroundColor3 = Theme.Colors.Success
        else
            priceText.Text = string.format("R$%d", product.price)
        end
    end
    
    -- Hover animations
    local hovering = false
    local originalSize = card.Size
    
    card.MouseEnter:Connect(function()
        hovering = true
        SoundManager:play("Hover", 0.3)
        
        Utils.tween(card, {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset + 10)
        }, Theme.Animations.Fast)
        
        Utils.tween(card:FindFirstChild("UIStroke"), {
            Transparency = 0
        }, Theme.Animations.Fast)
        
        Utils.tween(card:FindFirstChild("Shadow"), {
            Size = UDim2.new(1, 16, 1, 16),
            Position = UDim2.new(0, -8, 0, -8),
            ImageTransparency = 0.5
        }, Theme.Animations.Fast)
        
        -- Glow pulse
        spawn(function()
            while hovering do
                Utils.tween(glow, {ImageTransparency = 0.6}, 0.5)
                wait(0.5)
                if not hovering then break end
                Utils.tween(glow, {ImageTransparency = 0.8}, 0.5)
                wait(0.5)
            end
        end)
    end)
    
    card.MouseLeave:Connect(function()
        hovering = false
        
        Utils.tween(card, {
            Size = originalSize
        }, Theme.Animations.Fast)
        
        Utils.tween(card:FindFirstChild("UIStroke"), {
            Transparency = 0.3
        }, Theme.Animations.Fast)
        
        Utils.tween(card:FindFirstChild("Shadow"), {
            Size = UDim2.new(1, 8, 1, 8),
            Position = UDim2.new(0, -4, 0, -4),
            ImageTransparency = 0.7
        }, Theme.Animations.Fast)
        
        Utils.tween(glow, {ImageTransparency = 0.8}, Theme.Animations.Fast)
    end)
    
    -- Click animation and purchase
    priceButton.MouseButton1Click:Connect(function()
        SoundManager:play("Click", 0.5)
        
        -- Click animation
        Utils.tween(card, {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 5, originalSize.Y.Scale, originalSize.Y.Offset - 5)
        }, 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, function()
            Utils.tween(card, {
                Size = originalSize
            }, 0.1)
        end)
        
        -- Handle purchase
        if productType == "cash" then
            MarketplaceService:PromptProductPurchase(player, product.id)
        else
            if not checkGamepassOwnership(product.id) then
                MarketplaceService:PromptGamePassPurchase(player, product.id)
            end
        end
    end)
    
    return card
end

-- Create pages
local function createHomePage(parent)
    local page = Instance.new("ScrollingFrame")
    page.Name = "HomePage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 8
    page.ScrollBarImageColor3 = Theme.Colors.Primary
    page.CanvasSize = UDim2.new(0, 0, 1.5, 0)
    page.Parent = parent
    
    -- Welcome banner
    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(1, -40, 0, 180)
    banner.Position = UDim2.new(0, 20, 0, 20)
    banner.BackgroundColor3 = Theme.Colors.Primary
    banner.Parent = page
    
    Utils.createCorner(banner, Theme.Corners.XLarge)
    
    local bannerGradient = Utils.createGradient(banner, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Colors.Primary),
        ColorSequenceKeypoint.new(1, Theme.Colors.Accent)
    }, 45)
    
    -- Banner content
    local welcomeTitle = Instance.new("TextLabel")
    welcomeTitle.Size = UDim2.new(0.6, 0, 0, 50)
    welcomeTitle.Position = UDim2.new(0, 30, 0, 40)
    welcomeTitle.BackgroundTransparency = 1
    welcomeTitle.Text = "Welcome to Sanrio Shop!"
    welcomeTitle.TextColor3 = Theme.Colors.TextLight
    welcomeTitle.TextScaled = true
    welcomeTitle.Font = Enum.Font.GothamBold
    welcomeTitle.Parent = banner
    
    local welcomeDesc = Instance.new("TextLabel")
    welcomeDesc.Size = UDim2.new(0.6, 0, 0, 30)
    welcomeDesc.Position = UDim2.new(0, 30, 0, 100)
    welcomeDesc.BackgroundTransparency = 1
    welcomeDesc.Text = "Get exclusive items and boosts for your tycoon!"
    welcomeDesc.TextColor3 = Theme.Colors.TextLight
    welcomeDesc.TextTransparency = 0.2
    welcomeDesc.TextScaled = true
    welcomeDesc.Font = Enum.Font.Gotham
    welcomeDesc.Parent = banner
    
    -- Decorative elements
    local star1 = Instance.new("ImageLabel")
    star1.Size = UDim2.new(0, 80, 0, 80)
    star1.Position = UDim2.new(0.7, 0, 0.2, 0)
    star1.BackgroundTransparency = 1
    star1.Image = "rbxassetid://2614987630"
    star1.ImageColor3 = Theme.Colors.TextLight
    star1.ImageTransparency = 0.3
    star1.Rotation = -15
    star1.Parent = banner
    
    local star2 = Instance.new("ImageLabel")
    star2.Size = UDim2.new(0, 60, 0, 60)
    star2.Position = UDim2.new(0.85, 0, 0.6, 0)
    star2.BackgroundTransparency = 1
    star2.Image = "rbxassetid://2614987630"
    star2.ImageColor3 = Theme.Colors.TextLight
    star2.ImageTransparency = 0.4
    star2.Rotation = 20
    star2.Parent = banner
    
    -- Featured section
    local featuredTitle = Instance.new("TextLabel")
    featuredTitle.Size = UDim2.new(1, -40, 0, 40)
    featuredTitle.Position = UDim2.new(0, 20, 0, 220)
    featuredTitle.BackgroundTransparency = 1
    featuredTitle.Text = "Featured Items"
    featuredTitle.TextColor3 = Theme.Colors.Text
    featuredTitle.TextScaled = true
    featuredTitle.Font = Enum.Font.GothamBold
    featuredTitle.TextXAlignment = Enum.TextXAlignment.Left
    featuredTitle.Parent = page
    
    -- Featured container
    local featuredContainer = Instance.new("Frame")
    featuredContainer.Size = UDim2.new(1, -40, 0, 240)
    featuredContainer.Position = UDim2.new(0, 20, 0, 270)
    featuredContainer.BackgroundTransparency = 1
    featuredContainer.Parent = page
    
    local featuredLayout = Instance.new("UIListLayout")
    featuredLayout.FillDirection = Enum.FillDirection.Horizontal
    featuredLayout.Padding = UDim.new(0, 15)
    featuredLayout.Parent = featuredContainer
    
    -- Add featured items
    createProductCard(ShopData.CashProducts[2], "cash", featuredContainer)
    createProductCard(ShopData.Gamepasses[1], "pass", featuredContainer)
    createProductCard(ShopData.CashProducts[3], "cash", featuredContainer)
    
    -- Hot deals section
    local dealsTitle = Instance.new("TextLabel")
    dealsTitle.Size = UDim2.new(1, -40, 0, 40)
    dealsTitle.Position = UDim2.new(0, 20, 0, 530)
    dealsTitle.BackgroundTransparency = 1
    dealsTitle.Text = "Hot Deals"
    dealsTitle.TextColor3 = Theme.Colors.Text
    dealsTitle.TextScaled = true
    dealsTitle.Font = Enum.Font.GothamBold
    dealsTitle.TextXAlignment = Enum.TextXAlignment.Left
    dealsTitle.Parent = page
    
    local dealsContainer = Instance.new("Frame")
    dealsContainer.Size = UDim2.new(1, -40, 0, 240)
    dealsContainer.Position = UDim2.new(0, 20, 0, 580)
    dealsContainer.BackgroundTransparency = 1
    dealsContainer.Parent = page
    
    local dealsLayout = Instance.new("UIListLayout")
    dealsLayout.FillDirection = Enum.FillDirection.Horizontal
    dealsLayout.Padding = UDim.new(0, 15)
    dealsLayout.Parent = dealsContainer
    
    -- Add more items
    createProductCard(ShopData.Gamepasses[2], "pass", dealsContainer)
    createProductCard(ShopData.CashProducts[1], "cash", dealsContainer)
    createProductCard(ShopData.Gamepasses[3], "pass", dealsContainer)
    
    return page
end

local function createCashPage(parent)
    local page = Instance.new("ScrollingFrame")
    page.Name = "CashPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 8
    page.ScrollBarImageColor3 = Theme.Colors.Cash
    page.CanvasSize = UDim2.new(0, 0, 1, 0)
    page.Visible = false
    page.Parent = parent
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -40, 1, -40)
    container.Position = UDim2.new(0, 20, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = page
    
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0.3, -10, 0, 220)
    layout.CellPadding = UDim2.new(0.05, 0, 0, 20)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Parent = container
    
    -- Add all cash products
    for _, product in ipairs(ShopData.CashProducts) do
        createProductCard(product, "cash", container)
    end
    
    return page
end

local function createPassesPage(parent)
    local page = Instance.new("ScrollingFrame")
    page.Name = "PassesPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 8
    page.ScrollBarImageColor3 = Theme.Colors.Premium
    page.CanvasSize = UDim2.new(0, 0, 1, 0)
    page.Visible = false
    page.Parent = parent
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -40, 1, -40)
    container.Position = UDim2.new(0, 20, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = page
    
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0.3, -10, 0, 220)
    layout.CellPadding = UDim2.new(0.05, 0, 0, 20)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Parent = container
    
    -- Add all gamepasses
    for _, pass in ipairs(ShopData.Gamepasses) do
        createProductCard(pass, "pass", container)
    end
    
    return page
end

-- Create main shop UI
local function createShopUI()
    -- Main ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "SanrioShopProfessional"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10
    gui.Enabled = false
    gui.Parent = playerGui
    
    -- Background dim
    local dimFrame = Instance.new("Frame")
    dimFrame.Name = "DimFrame"
    dimFrame.Size = UDim2.new(1, 0, 1, 0)
    dimFrame.BackgroundColor3 = Theme.Colors.Shadow
    dimFrame.BackgroundTransparency = 1
    dimFrame.Parent = gui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Theme.Colors.Background
    mainFrame.Parent = gui
    
    Utils.createCorner(mainFrame, Theme.Corners.XLarge)
    Utils.createStroke(mainFrame, 3, Theme.Colors.Primary, 0.3)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 100)
    header.BackgroundColor3 = Theme.Colors.Primary
    header.Parent = mainFrame
    
    Utils.createCorner(header, Theme.Corners.XLarge)
    
    -- Header mask (to hide bottom corners)
    local headerMask = Instance.new("Frame")
    headerMask.Size = UDim2.new(1, 0, 0, 30)
    headerMask.Position = UDim2.new(0, 0, 1, -30)
    headerMask.BackgroundColor3 = Theme.Colors.Primary
    headerMask.BorderSizePixel = 0
    headerMask.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 0, 50)
    title.Position = UDim2.new(0, 30, 0.5, 0)
    title.AnchorPoint = Vector2.new(0, 0.5)
    title.BackgroundTransparency = 1
    title.Text = "Sanrio Shop"
    title.TextColor3 = Theme.Colors.TextLight
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -60, 0.5, 0)
    closeButton.AnchorPoint = Vector2.new(0, 0.5)
    closeButton.BackgroundColor3 = Theme.Colors.Accent
    closeButton.Text = "×"
    closeButton.TextColor3 = Theme.Colors.TextLight
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.AutoButtonColor = false
    closeButton.Parent = header
    
    Utils.createCorner(closeButton, Theme.Corners.Round)
    
    closeButton.MouseEnter:Connect(function()
        Utils.tween(closeButton, {BackgroundColor3 = Theme.Colors.Accent:Lerp(Theme.Colors.Shadow, 0.2)}, Theme.Animations.Fast)
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utils.tween(closeButton, {BackgroundColor3 = Theme.Colors.Accent}, Theme.Animations.Fast)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        Shop:close()
    end)
    
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -60, 0, 50)
    tabContainer.Position = UDim2.new(0, 30, 0, 110)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 15)
    tabLayout.Parent = tabContainer
    
    -- Create tabs
    local tabs = {
        {name = "Home", icon = "rbxassetid://13471761758", color = Theme.Colors.Primary},
        {name = "Cash", icon = "rbxassetid://13471778013", color = Theme.Colors.Cash},
        {name = "Passes", icon = "rbxassetid://2614987630", color = Theme.Colors.Premium}
    }
    
    for _, tabData in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabData.name .. "Tab"
        tabButton.Size = UDim2.new(0, 150, 1, 0)
        tabButton.BackgroundColor3 = tabData.name == "Home" and tabData.color or Theme.Colors.Secondary
        tabButton.Text = ""
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabContainer
        
        Utils.createCorner(tabButton, Theme.Corners.Medium)
        
        local tabIcon = Instance.new("ImageLabel")
        tabIcon.Size = UDim2.new(0, 24, 0, 24)
        tabIcon.Position = UDim2.new(0, 15, 0.5, 0)
        tabIcon.AnchorPoint = Vector2.new(0, 0.5)
        tabIcon.BackgroundTransparency = 1
        tabIcon.Image = tabData.icon
        tabIcon.ImageColor3 = tabData.name == "Home" and Theme.Colors.TextLight or Theme.Colors.Text
        tabIcon.Parent = tabButton
        
        local tabText = Instance.new("TextLabel")
        tabText.Size = UDim2.new(1, -50, 1, 0)
        tabText.Position = UDim2.new(0, 45, 0, 0)
        tabText.BackgroundTransparency = 1
        tabText.Text = tabData.name
        tabText.TextColor3 = tabData.name == "Home" and Theme.Colors.TextLight or Theme.Colors.Text
        tabText.TextScaled = true
        tabText.Font = Enum.Font.Gotham
        tabText.TextXAlignment = Enum.TextXAlignment.Left
        tabText.Parent = tabButton
        
        Shop.tabButtons[tabData.name] = {
            button = tabButton,
            icon = tabIcon,
            text = tabText,
            color = tabData.color
        }
        
        tabButton.MouseButton1Click:Connect(function()
            Shop:switchTab(tabData.name)
        end)
    end
    
    -- Content container
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -170)
    contentFrame.Position = UDim2.new(0, 0, 0, 170)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ClipsDescendants = true
    contentFrame.Parent = mainFrame
    
    -- Create pages
    Shop.pages.Home = createHomePage(contentFrame)
    Shop.pages.Cash = createCashPage(contentFrame)
    Shop.pages.Passes = createPassesPage(contentFrame)
    
    -- Store references
    Shop.gui = gui
    Shop.mainFrame = mainFrame
    Shop.dimFrame = dimFrame
    Shop.contentFrame = contentFrame
    
    return gui
end

-- Tab switching
function Shop:switchTab(tabName)
    if self.currentTab == tabName or self.isAnimating then return end
    
    SoundManager:play("Tab", 0.4)
    self.currentTab = tabName
    
    -- Update tab appearance
    for name, tab in pairs(self.tabButtons) do
        local isActive = name == tabName
        
        Utils.tween(tab.button, {
            BackgroundColor3 = isActive and tab.color or Theme.Colors.Secondary
        }, Theme.Animations.Fast)
        
        Utils.tween(tab.icon, {
            ImageColor3 = isActive and Theme.Colors.TextLight or Theme.Colors.Text
        }, Theme.Animations.Fast)
        
        Utils.tween(tab.text, {
            TextColor3 = isActive and Theme.Colors.TextLight or Theme.Colors.Text
        }, Theme.Animations.Fast)
    end
    
    -- Switch pages with animation
    for name, page in pairs(self.pages) do
        if name == tabName then
            page.Visible = true
            page.Position = UDim2.new(0, 0, 0.1, 0)
            Utils.tween(page, {
                Position = UDim2.new(0, 0, 0, 0)
            }, Theme.Animations.Medium, Enum.EasingStyle.Back)
        else
            if page.Visible then
                Utils.tween(page, {
                    Position = UDim2.new(0, 0, -0.1, 0)
                }, Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
                    page.Visible = false
                end)
            end
        end
    end
end

-- Shop controls
function Shop:open()
    if self.isOpen or self.isAnimating then return end
    
    self.isAnimating = true
    self.gui.Enabled = true
    
    SoundManager:play("Open", 0.7)
    
    -- Animate dim
    Utils.tween(self.dimFrame, {
        BackgroundTransparency = 0.3
    }, Theme.Animations.Medium)
    
    -- Animate main frame
    self.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    self.mainFrame.Rotation = -5
    
    Utils.tween(self.mainFrame, {
        Size = UDim2.new(0.85, 0, 0.9, 0),
        Rotation = 0
    }, Theme.Animations.Bounce, Enum.EasingStyle.Back, Enum.EasingDirection.Out, function()
        self.isOpen = true
        self.isAnimating = false
        
        -- Ensure Home tab is selected by default
        if self.currentTab ~= "Home" then
            self:switchTab("Home")
        end
    end)
end

function Shop:close()
    if not self.isOpen or self.isAnimating then return end
    
    self.isAnimating = true
    
    SoundManager:play("Close", 0.7)
    
    -- Animate out
    Utils.tween(self.dimFrame, {
        BackgroundTransparency = 1
    }, Theme.Animations.Medium)
    
    Utils.tween(self.mainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Rotation = 5
    }, Theme.Animations.Medium, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
        self.gui.Enabled = false
        self.isOpen = false
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

-- Create shop button
local function createShopButton()
    local buttonGui = Instance.new("ScreenGui")
    buttonGui.Name = "ShopButtonPro"
    buttonGui.ResetOnSpawn = false
    buttonGui.DisplayOrder = 5
    buttonGui.Parent = playerGui
    
    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 80, 0, 80)
    button.Position = UDim2.new(0, 20, 0.5, -40)
    button.BackgroundColor3 = Theme.Colors.Primary
    button.Image = "rbxassetid://13471761758"
    button.ImageColor3 = Theme.Colors.TextLight
    button.Parent = buttonGui
    
    Utils.createCorner(button, Theme.Corners.Round)
    Utils.createStroke(button, 3, Theme.Colors.Accent, 0.3)
    Utils.createShadow(button, 10, 0.5)
    
    -- Pulse animation
    spawn(function()
        while true do
            Utils.tween(button, {
                Size = UDim2.new(0, 85, 0, 85),
                Position = UDim2.new(0, 17.5, 0.5, -42.5)
            }, 2, Enum.EasingStyle.Sine)
            wait(2)
            Utils.tween(button, {
                Size = UDim2.new(0, 80, 0, 80),
                Position = UDim2.new(0, 20, 0.5, -40)
            }, 2, Enum.EasingStyle.Sine)
            wait(2)
        end
    end)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        Utils.tween(button:FindFirstChild("UIStroke"), {
            Transparency = 0
        }, Theme.Animations.Fast)
        
        Utils.tween(button, {
            BackgroundColor3 = Theme.Colors.Accent
        }, Theme.Animations.Fast)
    end)
    
    button.MouseLeave:Connect(function()
        Utils.tween(button:FindFirstChild("UIStroke"), {
            Transparency = 0.3
        }, Theme.Animations.Fast)
        
        Utils.tween(button, {
            BackgroundColor3 = Theme.Colors.Primary
        }, Theme.Animations.Fast)
    end)
    
    button.MouseButton1Click:Connect(function()
        Shop:toggle()
    end)
    
    return buttonGui
end

-- Purchase handlers
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
    if userId == player.UserId then
        if wasPurchased then
            SoundManager:play("Purchase", 0.8)
            SoundManager:play("Sparkle", 0.6)
            
            -- Find and grant currency
            for _, product in ipairs(ShopData.CashProducts) do
                if product.id == productId then
                    -- Fire remote to server
                    local remotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
                    if remotes then
                        local grantRemote = remotes:FindFirstChild("GrantProductCurrency")
                        if grantRemote then
                            grantRemote:FireServer(productId, product.amount)
                        end
                    end
                    break
                end
            end
        else
            SoundManager:play("Error", 0.5)
        end
    end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(userId, passId, wasPurchased)
    if userId == player.UserId then
        if wasPurchased then
            SoundManager:play("Purchase", 0.8)
            SoundManager:play("Sparkle", 0.6)
            
            -- Clear cache
            clearOwnershipCache(passId)
            
            -- Refresh passes page if open
            if Shop.currentTab == "Passes" and Shop.isOpen then
                -- Recreate the page to show ownership
                Shop.pages.Passes:Destroy()
                Shop.pages.Passes = createPassesPage(Shop.contentFrame)
                Shop.pages.Passes.Visible = true
            end
            
            -- Fire remote to server
            local remotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
            if remotes then
                local passRemote = remotes:FindFirstChild("GamepassPurchased")
                if passRemote then
                    passRemote:FireServer(passId)
                end
            end
        else
            SoundManager:play("Error", 0.5)
        end
    end
end)

-- Initialize shop
task.spawn(function()
    -- Preload sounds
    SoundManager:preload()
    
    -- Wait a moment for assets
    wait(0.5)
    
    -- Create UI
    createShopUI()
    createShopButton()
    
    -- Auto-open shop after short delay
    wait(1.5)
    Shop:open()
end)

print("Sanrio Shop Professional loaded successfully!")