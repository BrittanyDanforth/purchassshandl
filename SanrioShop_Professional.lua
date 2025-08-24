--[[
    SANRIO SHOP PROFESSIONAL
    A fully polished, feature-rich shop system with modern UI/UX
    Place in StarterPlayer > StarterPlayerScripts
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    -- Colors
    PRIMARY_COLOR = Color3.fromRGB(255, 182, 193),  -- Light pink
    SECONDARY_COLOR = Color3.fromRGB(255, 105, 180), -- Hot pink
    ACCENT_COLOR = Color3.fromRGB(255, 20, 147),     -- Deep pink
    BACKGROUND_COLOR = Color3.fromRGB(255, 240, 245), -- Lavender blush
    TEXT_COLOR = Color3.fromRGB(50, 50, 50),         -- Dark gray
    LIGHT_TEXT = Color3.fromRGB(255, 255, 255),      -- White
    SUCCESS_COLOR = Color3.fromRGB(50, 205, 50),     -- Lime green
    ERROR_COLOR = Color3.fromRGB(255, 69, 58),       -- Red
    
    -- UI Settings
    CORNER_RADIUS = UDim.new(0, 12),
    PADDING = UDim.new(0, 20),
    BUTTON_PADDING = UDim.new(0, 15),
    ANIMATION_TIME = 0.3,
    HOVER_SCALE = 1.05,
    CLICK_SCALE = 0.95,
    
    -- Shop Settings
    SHOP_SIZE = UDim2.new(0.8, 0, 0.85, 0),
    MIN_SHOP_SIZE = Vector2.new(800, 600),
    MAX_SHOP_SIZE = Vector2.new(1400, 900),
    
    -- Sounds
    SOUNDS = {
        OPEN = 5274738828,
        CLOSE = 5274739176,
        HOVER = 12221990,
        CLICK = 421058925,
        PURCHASE = 5635301473,
        ERROR = 5635304007,
        SUCCESS = 5635309305,
    }
}

-- Product Data with new IDs
local SHOP_DATA = {
    cash = {
        {
            id = 3366419712,
            amount = 1000,
            name = "Starter Pack",
            icon = "rbxassetid://14309025957",
            description = "Perfect for beginners!",
            popular = false
        },
        {
            id = 3366420478,
            amount = 10000,
            name = "Value Bundle",
            icon = "rbxassetid://14309026147",
            description = "Best value for your Robux!",
            popular = true
        },
        {
            id = 3366420800,
            amount = 25000,
            name = "Mega Pack",
            icon = "rbxassetid://14309026376",
            description = "Massive cash injection!",
            popular = false
        }
    },
    
    gamepasses = {
        {
            id = 111111,
            name = "VIP",
            price = 499,
            icon = "rbxassetid://14309026578",
            description = "Exclusive VIP benefits!",
            perks = {"2x Money", "VIP Chat Tag", "Special Effects"}
        },
        {
            id = 222222,
            name = "Auto Collect",
            price = 299,
            icon = "rbxassetid://14309026789",
            description = "Automatically collect money!",
            perks = {"Auto collection", "No more clicking", "Save time"},
            hasToggle = true
        },
        {
            id = 333333,
            name = "Speed Boost",
            price = 199,
            icon = "rbxassetid://14309026987",
            description = "Move 2x faster!",
            perks = {"2x Speed", "Run everywhere", "Save time"}
        }
    }
}

-- Cache
local ownershipCache = {}
local purchasePending = {}

-- Sound Manager
local SoundManager = {}
function SoundManager:create()
    local sounds = {}
    for name, id in pairs(CONFIG.SOUNDS) do
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. id
        sound.Volume = 0.3
        sound.Parent = SoundService
        sounds[name] = sound
    end
    
    return {
        play = function(self, name)
            local sound = sounds[name]
            if sound then
                sound:Play()
            end
        end
    }
end

local soundManager = SoundManager:create()

-- Utility Functions
local function tween(instance, properties, duration, style, direction)
    duration = duration or CONFIG.ANIMATION_TIME
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local info = TweenInfo.new(duration, style, direction)
    local tweenObj = TweenService:Create(instance, info, properties)
    tweenObj:Play()
    return tweenObj
end

local function formatNumber(n)
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

local function createGradient(color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation or 90
    return gradient
end

-- UI Builder
local UIBuilder = {}

function UIBuilder:createFrame(props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.color or CONFIG.BACKGROUND_COLOR
    frame.Size = props.size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.position or UDim2.new(0, 0, 0, 0)
    frame.AnchorPoint = props.anchor or Vector2.new(0, 0)
    frame.BorderSizePixel = 0
    frame.Name = props.name or "Frame"
    
    if props.corner then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = props.corner
        corner.Parent = frame
    end
    
    if props.gradient then
        props.gradient.Parent = frame
    end
    
    if props.stroke then
        local stroke = Instance.new("UIStroke")
        stroke.Color = props.stroke.color or CONFIG.PRIMARY_COLOR
        stroke.Thickness = props.stroke.thickness or 2
        stroke.Transparency = props.stroke.transparency or 0
        stroke.Parent = frame
    end
    
    if props.padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = props.padding
        padding.PaddingRight = props.padding
        padding.PaddingTop = props.padding
        padding.PaddingBottom = props.padding
        padding.Parent = frame
    end
    
    frame.Parent = props.parent
    return frame
end

function UIBuilder:createButton(props)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = props.color or CONFIG.PRIMARY_COLOR
    button.Size = props.size or UDim2.new(0, 200, 0, 50)
    button.Position = props.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = props.anchor or Vector2.new(0, 0)
    button.Text = props.text or "Button"
    button.TextColor3 = props.textColor or CONFIG.LIGHT_TEXT
    button.TextScaled = true
    button.Font = Enum.Font.Gotham
    button.BorderSizePixel = 0
    button.Name = props.name or "Button"
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = props.corner or CONFIG.CORNER_RADIUS
    corner.Parent = button
    
    if props.gradient then
        props.gradient.Parent = button
    end
    
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = props.maxTextSize or 24
    textConstraint.MinTextSize = props.minTextSize or 14
    textConstraint.Parent = button
    
    -- Hover effects
    local originalSize = button.Size
    local hovering = false
    
    button.MouseEnter:Connect(function()
        if not hovering then
            hovering = true
            soundManager:play("HOVER")
            tween(button, {Size = UDim2.new(
                originalSize.X.Scale * CONFIG.HOVER_SCALE,
                originalSize.X.Offset * CONFIG.HOVER_SCALE,
                originalSize.Y.Scale * CONFIG.HOVER_SCALE,
                originalSize.Y.Offset * CONFIG.HOVER_SCALE
            )}, 0.2)
        end
    end)
    
    button.MouseLeave:Connect(function()
        hovering = false
        tween(button, {Size = originalSize}, 0.2)
    end)
    
    button.MouseButton1Down:Connect(function()
        soundManager:play("CLICK")
        tween(button, {Size = UDim2.new(
            originalSize.X.Scale * CONFIG.CLICK_SCALE,
            originalSize.X.Offset * CONFIG.CLICK_SCALE,
            originalSize.Y.Scale * CONFIG.CLICK_SCALE,
            originalSize.Y.Offset * CONFIG.CLICK_SCALE
        )}, 0.1)
    end)
    
    button.MouseButton1Up:Connect(function()
        tween(button, {Size = hovering and UDim2.new(
            originalSize.X.Scale * CONFIG.HOVER_SCALE,
            originalSize.X.Offset * CONFIG.HOVER_SCALE,
            originalSize.Y.Scale * CONFIG.HOVER_SCALE,
            originalSize.Y.Offset * CONFIG.HOVER_SCALE
        ) or originalSize}, 0.1)
    end)
    
    button.Parent = props.parent
    return button
end

function UIBuilder:createLabel(props)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = props.size or UDim2.new(1, 0, 0, 50)
    label.Position = props.position or UDim2.new(0, 0, 0, 0)
    label.AnchorPoint = props.anchor or Vector2.new(0, 0)
    label.Text = props.text or "Label"
    label.TextColor3 = props.textColor or CONFIG.TEXT_COLOR
    label.TextScaled = props.scaled ~= false
    label.Font = props.font or Enum.Font.Gotham
    label.Name = props.name or "Label"
    
    if props.scaled ~= false then
        local constraint = Instance.new("UITextSizeConstraint")
        constraint.MaxTextSize = props.maxTextSize or 30
        constraint.MinTextSize = props.minTextSize or 12
        constraint.Parent = label
    else
        label.TextSize = props.textSize or 20
    end
    
    label.Parent = props.parent
    return label
end

function UIBuilder:createImage(props)
    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Size = props.size or UDim2.new(0, 100, 0, 100)
    image.Position = props.position or UDim2.new(0, 0, 0, 0)
    image.AnchorPoint = props.anchor or Vector2.new(0, 0)
    image.Image = props.image or ""
    image.ScaleType = props.scaleType or Enum.ScaleType.Fit
    image.Name = props.name or "Image"
    
    if props.corner then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = props.corner
        corner.Parent = image
    end
    
    image.Parent = props.parent
    return image
end

function UIBuilder:createScrollingFrame(props)
    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = props.transparent and 1 or 0
    scroll.BackgroundColor3 = props.color or CONFIG.BACKGROUND_COLOR
    scroll.Size = props.size or UDim2.new(1, 0, 1, 0)
    scroll.Position = props.position or UDim2.new(0, 0, 0, 0)
    scroll.AnchorPoint = props.anchor or Vector2.new(0, 0)
    scroll.ScrollBarThickness = 8
    scroll.ScrollBarImageColor3 = CONFIG.PRIMARY_COLOR
    scroll.BorderSizePixel = 0
    scroll.Name = props.name or "ScrollingFrame"
    
    if props.corner then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = props.corner
        corner.Parent = scroll
    end
    
    scroll.Parent = props.parent
    return scroll
end

-- Shop System
local Shop = {
    isOpen = false,
    currentTab = "Home",
    gui = nil,
    content = nil,
    tabs = {},
    animations = {}
}

function Shop:createToggleButton()
    local button = UIBuilder:createButton({
        parent = playerGui,
        name = "ShopToggle",
        text = "SHOP",
        size = UDim2.new(0, 120, 0, 50),
        position = UDim2.new(0, 20, 0.5, -25),
        anchor = Vector2.new(0, 0.5),
        color = CONFIG.PRIMARY_COLOR,
        gradient = createGradient(CONFIG.PRIMARY_COLOR, CONFIG.SECONDARY_COLOR)
    })
    
    button.MouseButton1Click:Connect(function()
        self:toggle()
    end)
    
    return button
end

function Shop:createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SanrioShop"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.Parent = playerGui
    
    -- Background dim
    local dim = UIBuilder:createFrame({
        parent = screenGui,
        name = "Dim",
        color = Color3.new(0, 0, 0),
        size = UDim2.new(1, 0, 1, 0)
    })
    dim.BackgroundTransparency = 1
    dim.ZIndex = 1
    
    -- Main container
    local container = UIBuilder:createFrame({
        parent = screenGui,
        name = "Container",
        size = CONFIG.SHOP_SIZE,
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchor = Vector2.new(0.5, 0.5),
        color = CONFIG.BACKGROUND_COLOR,
        corner = UDim.new(0, 20),
        stroke = {
            color = CONFIG.PRIMARY_COLOR,
            thickness = 3
        }
    })
    container.ZIndex = 2
    
    -- Scale constraint
    local constraint = Instance.new("UISizeConstraint")
    constraint.MinSize = CONFIG.MIN_SHOP_SIZE
    constraint.MaxSize = CONFIG.MAX_SHOP_SIZE
    constraint.Parent = container
    
    -- Header
    local header = UIBuilder:createFrame({
        parent = container,
        name = "Header",
        size = UDim2.new(1, 0, 0, 80),
        color = CONFIG.PRIMARY_COLOR,
        gradient = createGradient(CONFIG.PRIMARY_COLOR, CONFIG.SECONDARY_COLOR)
    })
    
    local title = UIBuilder:createLabel({
        parent = header,
        text = "SANRIO SHOP",
        size = UDim2.new(0.5, 0, 1, 0),
        position = UDim2.new(0, 20, 0, 0),
        textColor = CONFIG.LIGHT_TEXT,
        font = Enum.Font.GothamBold,
        maxTextSize = 36
    })
    
    -- Close button
    local closeBtn = UIBuilder:createButton({
        parent = header,
        text = "×",
        size = UDim2.new(0, 50, 0, 50),
        position = UDim2.new(1, -60, 0.5, 0),
        anchor = Vector2.new(0, 0.5),
        color = CONFIG.ACCENT_COLOR,
        textColor = CONFIG.LIGHT_TEXT,
        corner = UDim.new(0.5, 0),
        maxTextSize = 36
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        self:close()
    end)
    
    -- Tab container
    local tabContainer = UIBuilder:createFrame({
        parent = container,
        name = "TabContainer",
        size = UDim2.new(1, -40, 0, 60),
        position = UDim2.new(0, 20, 0, 90),
        color = Color3.new(1, 1, 1),
        corner = CONFIG.CORNER_RADIUS
    })
    tabContainer.BackgroundTransparency = 0.9
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabContainer
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingBottom = UDim.new(0, 10)
    tabPadding.Parent = tabContainer
    
    -- Content area
    local contentArea = UIBuilder:createFrame({
        parent = container,
        name = "ContentArea",
        size = UDim2.new(1, -40, 1, -170),
        position = UDim2.new(0, 20, 0, 160),
        color = Color3.new(1, 1, 1),
        corner = CONFIG.CORNER_RADIUS
    })
    contentArea.BackgroundTransparency = 0.95
    
    self.gui = screenGui
    self.container = container
    self.content = contentArea
    self.dim = dim
    
    -- Create tabs
    local tabData = {
        {name = "Home", icon = "🏠"},
        {name = "Cash", icon = "💰"},
        {name = "Gamepasses", icon = "🎫"},
        {name = "Settings", icon = "⚙️"}
    }
    
    for _, tab in ipairs(tabData) do
        self:createTab(tabContainer, tab.name, tab.icon)
    end
    
    -- Start hidden
    container.Position = UDim2.new(0.5, 0, 1.5, 0)
    dim.BackgroundTransparency = 1
    
    return screenGui
end

function Shop:createTab(parent, name, icon)
    local tab = UIBuilder:createButton({
        parent = parent,
        text = icon .. " " .. name,
        size = UDim2.new(0.24, -10, 1, -20),
        color = self.currentTab == name and CONFIG.ACCENT_COLOR or CONFIG.PRIMARY_COLOR,
        textColor = CONFIG.LIGHT_TEXT,
        corner = CONFIG.CORNER_RADIUS
    })
    
    tab.MouseButton1Click:Connect(function()
        self:switchTab(name)
    end)
    
    self.tabs[name] = tab
end

function Shop:switchTab(tabName)
    if self.currentTab == tabName then return end
    
    soundManager:play("CLICK")
    
    -- Update tab colors
    for name, tab in pairs(self.tabs) do
        local isActive = name == tabName
        tween(tab, {
            BackgroundColor3 = isActive and CONFIG.ACCENT_COLOR or CONFIG.PRIMARY_COLOR
        }, 0.2)
    end
    
    self.currentTab = tabName
    self:loadContent(tabName)
end

function Shop:loadContent(tabName)
    -- Clear content
    for _, child in ipairs(self.content:GetChildren()) do
        child:Destroy()
    end
    
    if tabName == "Home" then
        self:loadHomeContent()
    elseif tabName == "Cash" then
        self:loadCashContent()
    elseif tabName == "Gamepasses" then
        self:loadGamepassContent()
    elseif tabName == "Settings" then
        self:loadSettingsContent()
    end
end

function Shop:loadHomeContent()
    local welcomeFrame = UIBuilder:createFrame({
        parent = self.content,
        size = UDim2.new(1, -40, 0.4, 0),
        position = UDim2.new(0, 20, 0, 20),
        color = CONFIG.PRIMARY_COLOR,
        corner = CONFIG.CORNER_RADIUS,
        gradient = createGradient(CONFIG.PRIMARY_COLOR, CONFIG.SECONDARY_COLOR)
    })
    
    local welcomeText = UIBuilder:createLabel({
        parent = welcomeFrame,
        text = "Welcome to Sanrio Shop!",
        size = UDim2.new(1, -40, 0.5, 0),
        position = UDim2.new(0, 20, 0, 20),
        textColor = CONFIG.LIGHT_TEXT,
        font = Enum.Font.GothamBold,
        maxTextSize = 32
    })
    
    local subText = UIBuilder:createLabel({
        parent = welcomeFrame,
        text = "Get exclusive items and boosts for your tycoon!",
        size = UDim2.new(1, -40, 0.3, 0),
        position = UDim2.new(0, 20, 0.6, 0),
        textColor = CONFIG.LIGHT_TEXT,
        maxTextSize = 20
    })
    
    -- Featured items
    local featuredLabel = UIBuilder:createLabel({
        parent = self.content,
        text = "Featured Items",
        size = UDim2.new(1, -40, 0, 40),
        position = UDim2.new(0, 20, 0.45, 0),
        font = Enum.Font.GothamBold,
        maxTextSize = 24
    })
    
    local featuredFrame = UIBuilder:createScrollingFrame({
        parent = self.content,
        size = UDim2.new(1, -40, 0.45, -20),
        position = UDim2.new(0, 20, 0.52, 0),
        transparent = true
    })
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 15)
    layout.Parent = featuredFrame
    
    -- Add featured items
    local featured = {
        SHOP_DATA.cash[2], -- Value Bundle
        SHOP_DATA.gamepasses[1] -- VIP
    }
    
    for _, item in ipairs(featured) do
        self:createFeaturedCard(featuredFrame, item)
    end
    
    featuredFrame.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X, 0, 0)
end

function Shop:createFeaturedCard(parent, item)
    local card = UIBuilder:createFrame({
        parent = parent,
        size = UDim2.new(0, 250, 1, -10),
        color = Color3.new(1, 1, 1),
        corner = CONFIG.CORNER_RADIUS,
        stroke = {
            color = CONFIG.ACCENT_COLOR,
            thickness = 2
        }
    })
    
    local icon = UIBuilder:createImage({
        parent = card,
        size = UDim2.new(0.8, 0, 0.5, 0),
        position = UDim2.new(0.1, 0, 0.05, 0),
        image = item.icon or "",
        corner = CONFIG.CORNER_RADIUS
    })
    
    local nameLabel = UIBuilder:createLabel({
        parent = card,
        text = item.name,
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0.58, 0),
        font = Enum.Font.GothamBold,
        maxTextSize = 20
    })
    
    local priceText = item.amount and ("$" .. formatNumber(item.amount)) or ("R$" .. item.price)
    local priceLabel = UIBuilder:createLabel({
        parent = card,
        text = priceText,
        size = UDim2.new(1, -20, 0, 25),
        position = UDim2.new(0, 10, 0.72, 0),
        textColor = CONFIG.ACCENT_COLOR,
        font = Enum.Font.GothamBold,
        maxTextSize = 18
    })
    
    local buyButton = UIBuilder:createButton({
        parent = card,
        text = "View",
        size = UDim2.new(0.8, 0, 0, 35),
        position = UDim2.new(0.1, 0, 0.88, 0),
        color = CONFIG.ACCENT_COLOR,
        corner = UDim.new(0, 8)
    })
    
    buyButton.MouseButton1Click:Connect(function()
        self:switchTab(item.amount and "Cash" or "Gamepasses")
    end)
end

function Shop:loadCashContent()
    local scroll = UIBuilder:createScrollingFrame({
        parent = self.content,
        size = UDim2.new(1, -20, 1, -20),
        position = UDim2.new(0, 10, 0, 10),
        transparent = true
    })
    
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.31, 0, 0, 280)
    grid.CellPadding = UDim2.new(0.035, 0, 0, 20)
    grid.Parent = scroll
    
    for _, product in ipairs(SHOP_DATA.cash) do
        self:createCashCard(scroll, product)
    end
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
end

function Shop:createCashCard(parent, product)
    local card = UIBuilder:createFrame({
        parent = parent,
        color = Color3.new(1, 1, 1),
        corner = CONFIG.CORNER_RADIUS,
        stroke = {
            color = product.popular and CONFIG.ACCENT_COLOR or CONFIG.PRIMARY_COLOR,
            thickness = product.popular and 3 or 2
        }
    })
    
    if product.popular then
        local badge = UIBuilder:createFrame({
            parent = card,
            size = UDim2.new(0, 100, 0, 30),
            position = UDim2.new(0.5, 0, 0, -15),
            anchor = Vector2.new(0.5, 0),
            color = CONFIG.ACCENT_COLOR,
            corner = UDim.new(0, 15)
        })
        
        local badgeText = UIBuilder:createLabel({
            parent = badge,
            text = "POPULAR",
            textColor = CONFIG.LIGHT_TEXT,
            font = Enum.Font.GothamBold,
            scaled = false,
            textSize = 14
        })
    end
    
    local icon = UIBuilder:createImage({
        parent = card,
        size = UDim2.new(0.6, 0, 0.35, 0),
        position = UDim2.new(0.2, 0, 0.1, 0),
        image = product.icon,
        corner = CONFIG.CORNER_RADIUS
    })
    
    local cashAmount = UIBuilder:createLabel({
        parent = card,
        text = formatNumber(product.amount) .. " Cash",
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0.48, 0),
        font = Enum.Font.GothamBold,
        maxTextSize = 24
    })
    
    local description = UIBuilder:createLabel({
        parent = card,
        text = product.description,
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0.6, 0),
        textColor = Color3.fromRGB(100, 100, 100),
        maxTextSize = 16
    })
    
    -- Get price from MarketplaceService
    local priceLabel = UIBuilder:createLabel({
        parent = card,
        text = "Loading...",
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0.72, 0),
        textColor = CONFIG.SUCCESS_COLOR,
        font = Enum.Font.GothamBold,
        maxTextSize = 20
    })
    
    task.spawn(function()
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(product.id, Enum.InfoType.Product)
        end)
        
        if success and info then
            priceLabel.Text = "R$" .. info.PriceInRobux
        else
            priceLabel.Text = "Price unavailable"
        end
    end)
    
    local buyButton = UIBuilder:createButton({
        parent = card,
        text = "Buy Now",
        size = UDim2.new(0.8, 0, 0, 40),
        position = UDim2.new(0.1, 0, 0.85, 0),
        color = CONFIG.SUCCESS_COLOR,
        gradient = createGradient(CONFIG.SUCCESS_COLOR, Color3.fromRGB(40, 180, 40))
    })
    
    buyButton.MouseButton1Click:Connect(function()
        self:purchaseProduct(product)
    end)
end

function Shop:loadGamepassContent()
    local scroll = UIBuilder:createScrollingFrame({
        parent = self.content,
        size = UDim2.new(1, -20, 1, -20),
        position = UDim2.new(0, 10, 0, 10),
        transparent = true
    })
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 15)
    list.Parent = scroll
    
    for _, gamepass in ipairs(SHOP_DATA.gamepasses) do
        self:createGamepassCard(scroll, gamepass)
    end
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
end

function Shop:createGamepassCard(parent, gamepass)
    local card = UIBuilder:createFrame({
        parent = parent,
        size = UDim2.new(1, -20, 0, 120),
        color = Color3.new(1, 1, 1),
        corner = CONFIG.CORNER_RADIUS,
        padding = UDim.new(0, 15)
    })
    
    local icon = UIBuilder:createImage({
        parent = card,
        size = UDim2.new(0, 90, 0, 90),
        position = UDim2.new(0, 0, 0.5, 0),
        anchor = Vector2.new(0, 0.5),
        image = gamepass.icon,
        corner = CONFIG.CORNER_RADIUS
    })
    
    local infoFrame = UIBuilder:createFrame({
        parent = card,
        size = UDim2.new(1, -220, 1, 0),
        position = UDim2.new(0, 110, 0, 0),
        color = Color3.new(1, 1, 1)
    })
    
    local nameLabel = UIBuilder:createLabel({
        parent = infoFrame,
        text = gamepass.name,
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 0),
        font = Enum.Font.GothamBold,
        scaled = false,
        textSize = 22
    })
    
    local descLabel = UIBuilder:createLabel({
        parent = infoFrame,
        text = gamepass.description,
        size = UDim2.new(1, 0, 0, 25),
        position = UDim2.new(0, 0, 0, 35),
        textColor = Color3.fromRGB(100, 100, 100),
        scaled = false,
        textSize = 16
    })
    
    if gamepass.perks then
        local perksText = "• " .. table.concat(gamepass.perks, "\n• ")
        local perksLabel = UIBuilder:createLabel({
            parent = infoFrame,
            text = perksText,
            size = UDim2.new(1, 0, 0, 40),
            position = UDim2.new(0, 0, 0, 65),
            textColor = CONFIG.PRIMARY_COLOR,
            scaled = false,
            textSize = 14
        })
    end
    
    -- Check ownership
    local owned = false
    task.spawn(function()
        local success, result = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.id)
        end)
        owned = success and result
        
        if owned then
            self:updateGamepassCardOwned(card, gamepass)
        else
            self:updateGamepassCardUnowned(card, gamepass)
        end
    end)
end

function Shop:updateGamepassCardOwned(card, gamepass)
    local buttonFrame = UIBuilder:createFrame({
        parent = card,
        size = UDim2.new(0, 100, 0, 90),
        position = UDim2.new(1, 0, 0.5, 0),
        anchor = Vector2.new(1, 0.5),
        color = Color3.new(1, 1, 1)
    })
    
    local ownedLabel = UIBuilder:createLabel({
        parent = buttonFrame,
        text = "OWNED",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 10),
        textColor = CONFIG.SUCCESS_COLOR,
        font = Enum.Font.GothamBold,
        scaled = false,
        textSize = 18
    })
    
    if gamepass.hasToggle then
        local toggleButton = UIBuilder:createButton({
            parent = buttonFrame,
            text = "Toggle",
            size = UDim2.new(1, 0, 0, 35),
            position = UDim2.new(0, 0, 0, 45),
            color = CONFIG.PRIMARY_COLOR
        })
        
        toggleButton.MouseButton1Click:Connect(function()
            self:toggleGamepass(gamepass)
        end)
    end
end

function Shop:updateGamepassCardUnowned(card, gamepass)
    local buyButton = UIBuilder:createButton({
        parent = card,
        text = "R$" .. gamepass.price,
        size = UDim2.new(0, 100, 0, 40),
        position = UDim2.new(1, 0, 0.5, 0),
        anchor = Vector2.new(1, 0.5),
        color = CONFIG.SUCCESS_COLOR,
        gradient = createGradient(CONFIG.SUCCESS_COLOR, Color3.fromRGB(40, 180, 40))
    })
    
    buyButton.MouseButton1Click:Connect(function()
        self:purchaseGamepass(gamepass)
    end)
end

function Shop:loadSettingsContent()
    local settingsFrame = UIBuilder:createFrame({
        parent = self.content,
        size = UDim2.new(1, -40, 1, -40),
        position = UDim2.new(0, 20, 0, 20),
        color = Color3.new(1, 1, 1),
        corner = CONFIG.CORNER_RADIUS,
        padding = UDim.new(0, 20)
    })
    
    local title = UIBuilder:createLabel({
        parent = settingsFrame,
        text = "Settings",
        size = UDim2.new(1, 0, 0, 40),
        font = Enum.Font.GothamBold,
        maxTextSize = 28
    })
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 20)
    list.Parent = settingsFrame
    
    -- Sound toggle
    local soundToggle = self:createSettingToggle(settingsFrame, "Sound Effects", true, function(enabled)
        SoundService.RespectFilteringEnabled = not enabled
    end)
    
    -- Effects toggle
    local effectsToggle = self:createSettingToggle(settingsFrame, "Visual Effects", true, function(enabled)
        -- Toggle visual effects
    end)
end

function Shop:createSettingToggle(parent, name, default, callback)
    local container = UIBuilder:createFrame({
        parent = parent,
        size = UDim2.new(1, 0, 0, 50),
        color = Color3.new(0.95, 0.95, 0.95),
        corner = CONFIG.CORNER_RADIUS
    })
    
    local label = UIBuilder:createLabel({
        parent = container,
        text = name,
        size = UDim2.new(0.7, 0, 1, 0),
        position = UDim2.new(0, 20, 0, 0),
        scaled = false,
        textSize = 18
    })
    
    local toggleBg = UIBuilder:createFrame({
        parent = container,
        size = UDim2.new(0, 60, 0, 30),
        position = UDim2.new(1, -80, 0.5, 0),
        anchor = Vector2.new(0, 0.5),
        color = default and CONFIG.SUCCESS_COLOR or Color3.fromRGB(200, 200, 200),
        corner = UDim.new(0.5, 0)
    })
    
    local toggleBtn = UIBuilder:createFrame({
        parent = toggleBg,
        size = UDim2.new(0, 26, 0, 26),
        position = default and UDim2.new(1, -28, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        anchor = Vector2.new(0, 0.5),
        color = Color3.new(1, 1, 1),
        corner = UDim.new(0.5, 0)
    })
    
    local enabled = default
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = toggleBg
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        tween(toggleBtn, {
            Position = enabled and UDim2.new(1, -28, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        }, 0.2)
        
        tween(toggleBg, {
            BackgroundColor3 = enabled and CONFIG.SUCCESS_COLOR or Color3.fromRGB(200, 200, 200)
        }, 0.2)
        
        callback(enabled)
        soundManager:play("CLICK")
    end)
    
    return container
end

function Shop:purchaseProduct(product)
    if purchasePending[product.id] then return end
    
    purchasePending[product.id] = true
    soundManager:play("CLICK")
    
    local success, err = pcall(function()
        MarketplaceService:PromptProductPurchase(player, product.id)
    end)
    
    if not success then
        warn("Failed to prompt product purchase:", err)
        purchasePending[product.id] = nil
    end
    
    -- Timeout protection
    task.delay(10, function()
        purchasePending[product.id] = nil
    end)
end

function Shop:purchaseGamepass(gamepass)
    if purchasePending[gamepass.id] then return end
    
    purchasePending[gamepass.id] = true
    soundManager:play("CLICK")
    
    local success, err = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
    end)
    
    if not success then
        warn("Failed to prompt gamepass purchase:", err)
        purchasePending[gamepass.id] = nil
    end
    
    -- Timeout protection
    task.delay(10, function()
        purchasePending[gamepass.id] = nil
    end)
end

function Shop:toggleGamepass(gamepass)
    if gamepass.name == "Auto Collect" then
        local remotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
        if remotes then
            local toggleRemote = remotes:FindFirstChild("AutoCollectToggle")
            if toggleRemote then
                toggleRemote:FireServer()
                soundManager:play("CLICK")
            end
        end
    end
end

function Shop:open()
    if self.isOpen then return end
    
    self.isOpen = true
    soundManager:play("OPEN")
    
    self.gui.Enabled = true
    
    -- Animate in
    tween(self.dim, {BackgroundTransparency = 0.3}, 0.3)
    tween(self.container, {Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Back)
    
    -- Load home content by default
    self:switchTab("Home")
end

function Shop:close()
    if not self.isOpen then return end
    
    self.isOpen = false
    soundManager:play("CLOSE")
    
    -- Animate out
    tween(self.dim, {BackgroundTransparency = 1}, 0.3)
    local closeTween = tween(self.container, {Position = UDim2.new(0.5, 0, 1.5, 0)}, 0.3)
    
    closeTween.Completed:Connect(function()
        self.gui.Enabled = false
    end)
end

function Shop:toggle()
    if self.isOpen then
        self:close()
    else
        self:open()
    end
end

-- Purchase handlers
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
    purchasePending[productId] = nil
    
    if userId == player.UserId and wasPurchased then
        soundManager:play("SUCCESS")
        
        -- Find product data
        local productData
        for _, product in ipairs(SHOP_DATA.cash) do
            if product.id == productId then
                productData = product
                break
            end
        end
        
        if productData then
            -- Fire remote to grant currency
            local remotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
            if remotes then
                local grantRemote = remotes:FindFirstChild("GrantProductCurrency")
                if grantRemote then
                    grantRemote:FireServer(productId, productData.amount)
                end
            end
        end
    end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(targetPlayer, gamePassId, wasPurchased)
    purchasePending[gamePassId] = nil
    
    if targetPlayer == player and wasPurchased then
        soundManager:play("SUCCESS")
        ownershipCache[gamePassId] = true
        
        -- Refresh current tab
        Shop:loadContent(Shop.currentTab)
        
        -- Fire remote to notify server
        local remotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
        if remotes then
            local purchaseRemote = remotes:FindFirstChild("GamepassPurchased")
            if purchaseRemote then
                purchaseRemote:FireServer(gamePassId)
            end
        end
    end
end)

-- Money collection effects
local function setupMoneyEffects()
    local remotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
    if not remotes then return end
    
    local moneyCollected = remotes:FindFirstChild("MoneyCollected")
    if not moneyCollected then return end
    
    moneyCollected.OnClientEvent:Connect(function(amount, position)
        -- Create floating text effect
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(2, 0, 1, 0)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "+$" .. formatNumber(amount)
        text.TextColor3 = CONFIG.SUCCESS_COLOR
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Parent = billboard
        
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Position = position
        part.Parent = workspace
        billboard.Parent = part
        
        -- Animate
        local startPos = position
        local endPos = position + Vector3.new(0, 5, 0)
        
        local tween = TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {
            Position = endPos
        })
        
        local fadeTween = TweenService:Create(text, TweenInfo.new(1.5), {
            TextTransparency = 1
        })
        
        tween:Play()
        fadeTween:Play()
        
        tween.Completed:Connect(function()
            part:Destroy()
        end)
        
        soundManager:play("SUCCESS")
    end)
end

-- Initialize
local function initialize()
    -- Preload assets
    local assetsToLoad = {}
    for _, sound in pairs(CONFIG.SOUNDS) do
        table.insert(assetsToLoad, "rbxassetid://" .. sound)
    end
    
    for _, item in ipairs(SHOP_DATA.cash) do
        if item.icon then
            table.insert(assetsToLoad, item.icon)
        end
    end
    
    for _, item in ipairs(SHOP_DATA.gamepasses) do
        if item.icon then
            table.insert(assetsToLoad, item.icon)
        end
    end
    
    ContentProvider:PreloadAsync(assetsToLoad)
    
    -- Create shop
    Shop:createToggleButton()
    Shop:createMainGUI()
    
    -- Setup effects
    setupMoneyEffects()
end

initialize()

print("Sanrio Shop Professional loaded successfully!")