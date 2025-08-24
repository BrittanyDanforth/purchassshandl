--[[
    SANRIO SHOP SYSTEM - MAIN SCRIPT
    Complete shop implementation with all features
--]]

-- Module Imports
local Core = require(script.SanrioShop_Core)
local UI = require(script.SanrioShop_UI)

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Remote Events
local Remotes = ReplicatedStorage:WaitForChild("TycoonRemotes", 10)

-- Shop Class
local Shop = {}
Shop.__index = Shop

function Shop.new()
    local self = setmetatable({}, Shop)
    
    self.gui = nil
    self.mainPanel = nil
    self.tabContainer = nil
    self.contentContainer = nil
    self.currentTab = "Home"
    self.tabs = {}
    self.pages = {}
    self.toggleButton = nil
    self.blur = nil
    
    self:initialize()
    
    return self
end

function Shop:initialize()
    Core.SoundSystem.initialize()
    Core.DataManager.refreshPrices()
    
    self:createToggleButton()
    self:createMainInterface()
    self:setupRemoteHandlers()
    self:setupInputHandlers()
    
    Core.State.initialized = true
    Core.Events:emit("shopInitialized")
end

function Shop:createToggleButton()
    -- Create persistent screen gui for toggle
    local toggleScreen = PlayerGui:FindFirstChild("SanrioShopToggle") or Instance.new("ScreenGui")
    toggleScreen.Name = "SanrioShopToggle"
    toggleScreen.ResetOnSpawn = false
    toggleScreen.DisplayOrder = 999
    toggleScreen.Parent = PlayerGui
    
    -- Create toggle button
    self.toggleButton = UI.Components.Button({
        Name = "ShopToggle",
        Text = "",
        Size = UDim2.fromOffset(180, 60),
        Position = UDim2.new(1, -20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = UI.Theme:get("surface"),
        cornerRadius = UDim.new(1, 0),
        stroke = {
            color = UI.Theme:get("accent"),
            thickness = 2,
        },
        shadow = {
            size = 20,
            transparency = 0.3,
        },
        parent = toggleScreen,
        onClick = function()
            self:toggle()
        end,
    }):render()
    
    -- Add icon and text
    local icon = UI.Components.Image({
        Name = "Icon",
        Image = "rbxassetid://14978146869", -- Shop icon
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.fromOffset(16, 14),
        parent = self.toggleButton,
    }):render()
    
    local label = UI.Components.TextLabel({
        Name = "Label",
        Text = "Shop",
        Size = UDim2.new(1, -64, 1, 0),
        Position = UDim2.fromOffset(56, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        parent = self.toggleButton,
    }):render()
    
    -- Pulse animation
    self:addPulseAnimation(self.toggleButton)
end

function Shop:createMainInterface()
    -- Create main screen gui
    self.gui = PlayerGui:FindFirstChild("SanrioShopMain") or Instance.new("ScreenGui")
    self.gui.Name = "SanrioShopMain"
    self.gui.ResetOnSpawn = false
    self.gui.DisplayOrder = 1000
    self.gui.Enabled = false
    self.gui.Parent = PlayerGui
    
    -- Create blur effect
    self.blur = Lighting:FindFirstChild("SanrioShopBlur") or Instance.new("BlurEffect")
    self.blur.Name = "SanrioShopBlur"
    self.blur.Size = 0
    self.blur.Parent = Lighting
    
    -- Create dimmed background
    local dimBackground = UI.Components.Frame({
        Name = "DimBackground",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.3,
        parent = self.gui,
    }):render()
    
    -- Create main panel
    local panelSize = Core.Utils.isMobile() and Core.CONSTANTS.PANEL_SIZE_MOBILE or Core.CONSTANTS.PANEL_SIZE
    
    self.mainPanel = UI.Components.Frame({
        Name = "MainPanel",
        Size = UDim2.fromOffset(panelSize.X, panelSize.Y),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UI.Theme:get("background"),
        cornerRadius = UDim.new(0, 24),
        stroke = {
            color = UI.Theme:get("stroke"),
            thickness = 1,
        },
        shadow = {
            size = 40,
            transparency = 0.2,
            blur = 0.4,
        },
        parent = self.gui,
    }):render()
    
    -- Add responsive scaling
    UI.Responsive.scale(self.mainPanel)
    
    -- Create header
    self:createHeader()
    
    -- Create tab bar
    self:createTabBar()
    
    -- Create content container
    self.contentContainer = UI.Components.Frame({
        Name = "ContentContainer",
        Size = UDim2.new(1, -48, 1, -180),
        Position = UDim2.fromOffset(24, 156),
        BackgroundTransparency = 1,
        parent = self.mainPanel,
    }):render()
    
    -- Create pages
    self:createPages()
    
    -- Select default tab
    self:selectTab("Home")
end

function Shop:createHeader()
    local header = UI.Components.Frame({
        Name = "Header",
        Size = UDim2.new(1, -48, 0, 80),
        Position = UDim2.fromOffset(24, 24),
        BackgroundColor3 = UI.Theme:get("surfaceAlt"),
        cornerRadius = UDim.new(0, 16),
        parent = self.mainPanel,
    }):render()
    
    -- Logo/Icon
    local logo = UI.Components.Image({
        Name = "Logo",
        Image = "rbxassetid://14978148234", -- Sanrio logo
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.fromOffset(16, 10),
        parent = header,
    }):render()
    
    -- Title
    local title = UI.Components.TextLabel({
        Name = "Title",
        Text = "Sanrio Shop",
        Size = UDim2.new(1, -200, 1, 0),
        Position = UDim2.fromOffset(92, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        parent = header,
    }):render()
    
    -- Close button
    local closeButton = UI.Components.Button({
        Name = "CloseButton",
        Text = "✕",
        Size = UDim2.fromOffset(48, 48),
        Position = UDim2.new(1, -64, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = UI.Theme:get("error"),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        cornerRadius = UDim.new(0.5, 0),
        parent = header,
        onClick = function()
            self:close()
        end,
    }):render()
end

function Shop:createTabBar()
    self.tabContainer = UI.Components.Frame({
        Name = "TabContainer",
        Size = UDim2.new(1, -48, 0, 48),
        Position = UDim2.fromOffset(24, 116),
        BackgroundTransparency = 1,
        parent = self.mainPanel,
    }):render()
    
    UI.Layout.stack(self.tabContainer, Enum.FillDirection.Horizontal, 12)
    
    -- Create tabs
    local tabData = {
        {id = "Home", name = "Home", icon = "rbxassetid://14978149123", color = UI.Theme:get("kitty")},
        {id = "Cash", name = "Cash", icon = "rbxassetid://14978149234", color = UI.Theme:get("cinna")},
        {id = "Gamepasses", name = "Passes", icon = "rbxassetid://14978149345", color = UI.Theme:get("kuromi")},
    }
    
    for _, data in ipairs(tabData) do
        self:createTab(data)
    end
end

function Shop:createTab(data)
    local tab = UI.Components.Button({
        Name = data.id .. "Tab",
        Text = "",
        Size = UDim2.fromOffset(160, 48),
        BackgroundColor3 = UI.Theme:get("surface"),
        cornerRadius = UDim.new(0.5, 0),
        stroke = {
            color = UI.Theme:get("stroke"),
            thickness = 1,
        },
        LayoutOrder = #self.tabs + 1,
        parent = self.tabContainer,
        onClick = function()
            self:selectTab(data.id)
        end,
    }):render()
    
    -- Tab content
    local content = UI.Components.Frame({
        Name = "Content",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        parent = tab,
    }):render()
    
    UI.Layout.stack(content, Enum.FillDirection.Horizontal, 8, {left = 16, right = 16})
    
    -- Icon
    local icon = UI.Components.Image({
        Name = "Icon",
        Image = data.icon,
        Size = UDim2.fromOffset(24, 24),
        LayoutOrder = 1,
        parent = content,
    }):render()
    
    -- Label
    local label = UI.Components.TextLabel({
        Name = "Label",
        Text = data.name,
        Size = UDim2.new(1, -32, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        LayoutOrder = 2,
        parent = content,
    }):render()
    
    self.tabs[data.id] = {
        button = tab,
        data = data,
        icon = icon,
        label = label,
    }
end

function Shop:createPages()
    -- Home Page
    self.pages.Home = self:createHomePage()
    
    -- Cash Page
    self.pages.Cash = self:createCashPage()
    
    -- Gamepasses Page
    self.pages.Gamepasses = self:createGamepassesPage()
end

function Shop:createHomePage()
    local page = UI.Components.Frame({
        Name = "HomePage",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        parent = self.contentContainer,
    }):render()
    
    local scrollFrame = UI.Components.ScrollingFrame({
        Size = UDim2.fromScale(1, 1),
        layout = {
            type = "List",
            Padding = UDim.new(0, 24),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        },
        padding = {
            top = UDim.new(0, 12),
            bottom = UDim.new(0, 12),
        },
        parent = page,
    }):render()
    
    -- Hero Section
    local hero = self:createHeroSection(scrollFrame)
    
    -- Featured Products
    local featuredTitle = UI.Components.TextLabel({
        Text = "Featured Items",
        Size = UDim2.new(1, 0, 0, 40),
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        parent = scrollFrame,
    }):render()
    
    local featuredContainer = UI.Components.Frame({
        Size = UDim2.new(1, 0, 0, 320),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        parent = scrollFrame,
    }):render()
    
    local featuredScroll = UI.Components.ScrollingFrame({
        Size = UDim2.fromScale(1, 1),
        ScrollingDirection = Enum.ScrollingDirection.X,
        layout = {
            type = "List",
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 16),
        },
        parent = featuredContainer,
    }):render()
    
    -- Add featured items
    local featured = {}
    for _, product in ipairs(Core.DataManager.products.cash) do
        if product.featured then
            table.insert(featured, {type = "cash", data = product})
        end
    end
    for _, pass in ipairs(Core.DataManager.products.gamepasses) do
        table.insert(featured, {type = "gamepass", data = pass})
    end
    
    for _, item in ipairs(featured) do
        self:createProductCard(item.data, item.type, featuredScroll)
    end
    
    return page
end

function Shop:createCashPage()
    local page = UI.Components.Frame({
        Name = "CashPage",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        parent = self.contentContainer,
    }):render()
    
    local scrollFrame = UI.Components.ScrollingFrame({
        Size = UDim2.fromScale(1, 1),
        layout = {
            type = "Grid",
            CellSize = Core.Utils.isMobile() and 
                UDim2.fromOffset(Core.CONSTANTS.CARD_SIZE_MOBILE.X, Core.CONSTANTS.CARD_SIZE_MOBILE.Y) or
                UDim2.fromOffset(Core.CONSTANTS.CARD_SIZE.X, Core.CONSTANTS.CARD_SIZE.Y),
            CellPadding = UDim2.fromOffset(20, 20),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        },
        padding = {
            top = UDim.new(0, 12),
            bottom = UDim.new(0, 12),
            left = UDim.new(0, 12),
            right = UDim.new(0, 12),
        },
        parent = page,
    }):render()
    
    -- Add cash products
    for _, product in ipairs(Core.DataManager.products.cash) do
        self:createProductCard(product, "cash", scrollFrame)
    end
    
    return page
end

function Shop:createGamepassesPage()
    local page = UI.Components.Frame({
        Name = "GamepassesPage",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        parent = self.contentContainer,
    }):render()
    
    local scrollFrame = UI.Components.ScrollingFrame({
        Size = UDim2.fromScale(1, 1),
        layout = {
            type = "Grid",
            CellSize = Core.Utils.isMobile() and 
                UDim2.fromOffset(Core.CONSTANTS.CARD_SIZE_MOBILE.X, Core.CONSTANTS.CARD_SIZE_MOBILE.Y) or
                UDim2.fromOffset(Core.CONSTANTS.CARD_SIZE.X, Core.CONSTANTS.CARD_SIZE.Y),
            CellPadding = UDim2.fromOffset(20, 20),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        },
        padding = {
            top = UDim.new(0, 12),
            bottom = UDim.new(0, 12),
            left = UDim.new(0, 12),
            right = UDim.new(0, 12),
        },
        parent = page,
    }):render()
    
    -- Add gamepass products
    for _, pass in ipairs(Core.DataManager.products.gamepasses) do
        self:createProductCard(pass, "gamepass", scrollFrame)
    end
    
    return page
end

function Shop:createHeroSection(parent)
    local hero = UI.Components.Frame({
        Name = "HeroSection",
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundColor3 = UI.Theme:get("accent"),
        cornerRadius = UDim.new(0, 16),
        LayoutOrder = 1,
        parent = parent,
    }):render()
    
    -- Gradient overlay
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 200)),
    })
    gradient.Rotation = 45
    gradient.Parent = hero
    
    -- Content
    local content = UI.Components.Frame({
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        parent = hero,
    }):render()
    
    UI.Layout.stack(content, Enum.FillDirection.Horizontal, 24, {
        left = 32,
        right = 32,
        top = 24,
        bottom = 24,
    })
    
    -- Text content
    local textContainer = UI.Components.Frame({
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        parent = content,
    }):render()
    
    local heroTitle = UI.Components.TextLabel({
        Text = "Welcome to Sanrio Shop!",
        Size = UDim2.new(1, 0, 0, 40),
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        parent = textContainer,
    }):render()
    
    local heroDesc = UI.Components.TextLabel({
        Text = "Get exclusive items and boosts for your tycoon!",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.fromOffset(0, 50),
        Font = Enum.Font.Gotham,
        TextSize = 18,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        parent = textContainer,
    }):render()
    
    -- CTA Button
    local ctaButton = UI.Components.Button({
        Text = "Browse Items",
        Size = UDim2.fromOffset(180, 48),
        Position = UDim2.fromOffset(0, 120),
        BackgroundColor3 = Color3.new(1, 1, 1),
        TextColor3 = UI.Theme:get("accent"),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        cornerRadius = UDim.new(0.5, 0),
        parent = textContainer,
        onClick = function()
            self:selectTab("Cash")
        end,
    }):render()
    
    -- Hero image
    local imageContainer = UI.Components.Frame({
        Size = UDim2.new(0.4, -24, 1, 0),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        parent = content,
    }):render()
    
    local heroImage = UI.Components.Image({
        Image = "rbxassetid://14978150123", -- Hero image
        Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Fit,
        parent = imageContainer,
    }):render()
    
    return hero
end

function Shop:createProductCard(product, productType, parent)
    local isGamepass = productType == "gamepass"
    local cardColor = isGamepass and UI.Theme:get("kuromi") or UI.Theme:get("cinna")
    
    local card = UI.Components.Frame({
        Name = product.name .. "Card",
        Size = UDim2.fromOffset(
            Core.Utils.isMobile() and Core.CONSTANTS.CARD_SIZE_MOBILE.X or Core.CONSTANTS.CARD_SIZE.X,
            Core.Utils.isMobile() and Core.CONSTANTS.CARD_SIZE_MOBILE.Y or Core.CONSTANTS.CARD_SIZE.Y
        ),
        BackgroundColor3 = UI.Theme:get("surface"),
        cornerRadius = UDim.new(0, 16),
        stroke = {
            color = cardColor,
            thickness = 2,
            transparency = 0.5,
        },
        parent = parent,
    }):render()
    
    -- Card hover effect
    self:addCardHoverEffect(card)
    
    -- Card content
    local content = UI.Components.Frame({
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        parent = card,
    }):render()
    
    -- Product image
    local imageContainer = UI.Components.Frame({
        Size = UDim2.new(1, 0, 0, 140),
        BackgroundColor3 = UI.Theme:get("surfaceAlt"),
        cornerRadius = UDim.new(0, 12),
        parent = content,
    }):render()
    
    local productImage = UI.Components.Image({
        Image = product.icon,
        Size = UDim2.fromScale(0.8, 0.8),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ScaleType = Enum.ScaleType.Fit,
        parent = imageContainer,
    }):render()
    
    -- Product info
    local infoContainer = UI.Components.Frame({
        Size = UDim2.new(1, 0, 1, -160),
        Position = UDim2.fromOffset(0, 160),
        BackgroundTransparency = 1,
        parent = content,
    }):render()
    
    -- Title
    local title = UI.Components.TextLabel({
        Text = product.name,
        Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        parent = infoContainer,
    }):render()
    
    -- Description
    local description = UI.Components.TextLabel({
        Text = product.description,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.fromOffset(0, 32),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = UI.Theme:get("textSecondary"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        parent = infoContainer,
    }):render()
    
    -- Price/Amount display
    local priceText = isGamepass and 
        ("R$" .. tostring(product.price or 0)) or 
        Core.Utils.formatNumber(product.amount) .. " Cash"
    
    local priceLabel = UI.Components.TextLabel({
        Text = priceText,
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 76),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = cardColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        parent = infoContainer,
    }):render()
    
    -- Purchase button
    local isOwned = isGamepass and Core.DataManager.checkOwnership(product.id)
    
    local purchaseButton = UI.Components.Button({
        Text = isOwned and "Owned" or "Purchase",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 1, -40),
        BackgroundColor3 = isOwned and UI.Theme:get("success") or cardColor,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        cornerRadius = UDim.new(0, 8),
        parent = infoContainer,
        onClick = function()
            if not isOwned then
                self:promptPurchase(product, productType)
            elseif product.hasToggle then
                self:toggleGamepass(product)
            end
        end,
    }):render()
    
    -- Add toggle if applicable
    if isOwned and product.hasToggle then
        self:addToggleSwitch(product, infoContainer)
    end
    
    -- Store reference
    product.cardInstance = card
    product.purchaseButton = purchaseButton
    
    return card
end

function Shop:addCardHoverEffect(card)
    local originalPosition = card.Position
    
    card.MouseEnter:Connect(function()
        Core.Animation.tween(card, {
            Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset,
                originalPosition.Y.Scale,
                originalPosition.Y.Offset - 8
            )
        }, Core.CONSTANTS.ANIM_FAST)
    end)
    
    card.MouseLeave:Connect(function()
        Core.Animation.tween(card, {
            Position = originalPosition
        }, Core.CONSTANTS.ANIM_FAST)
    end)
end

function Shop:addToggleSwitch(product, parent)
    local toggleContainer = UI.Components.Frame({
        Name = "ToggleContainer",
        Size = UDim2.fromOffset(60, 30),
        Position = UDim2.new(1, -60, 0, 76),
        BackgroundColor3 = UI.Theme:get("stroke"),
        cornerRadius = UDim.new(0.5, 0),
        parent = parent,
    }):render()
    
    local toggleButton = UI.Components.Frame({
        Name = "ToggleButton",
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = UI.Theme:get("surface"),
        cornerRadius = UDim.new(0.5, 0),
        parent = toggleContainer,
    }):render()
    
    -- Get current state
    local toggleState = false
    if Remotes then
        local getStateRemote = Remotes:FindFirstChild("GetAutoCollectState")
        if getStateRemote and getStateRemote:IsA("RemoteFunction") then
            local success, state = pcall(function()
                return getStateRemote:InvokeServer()
            end)
            if success and type(state) == "boolean" then
                toggleState = state
            end
        end
    end
    
    -- Update visual state
    local function updateToggleVisual()
        if toggleState then
            toggleContainer.BackgroundColor3 = UI.Theme:get("success")
            Core.Animation.tween(toggleButton, {
                Position = UDim2.fromOffset(32, 2)
            }, Core.CONSTANTS.ANIM_FAST)
        else
            toggleContainer.BackgroundColor3 = UI.Theme:get("stroke")
            Core.Animation.tween(toggleButton, {
                Position = UDim2.fromOffset(2, 2)
            }, Core.CONSTANTS.ANIM_FAST)
        end
    end
    
    updateToggleVisual()
    
    -- Toggle handler
    local toggleClickArea = Instance.new("TextButton")
    toggleClickArea.Text = ""
    toggleClickArea.BackgroundTransparency = 1
    toggleClickArea.Size = UDim2.fromScale(1, 1)
    toggleClickArea.Parent = toggleContainer
    
    toggleClickArea.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        updateToggleVisual()
        
        if Remotes then
            local toggleRemote = Remotes:FindFirstChild("AutoCollectToggle")
            if toggleRemote and toggleRemote:IsA("RemoteEvent") then
                toggleRemote:FireServer(toggleState)
            end
        end
        
        Core.SoundSystem.play("click")
    end)
end

function Shop:addPulseAnimation(instance)
    local pulseRunning = true
    
    task.spawn(function()
        while pulseRunning and instance.Parent do
            Core.Animation.tween(instance, {
                Size = UDim2.fromOffset(188, 64)
            }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.5)
            
            if not pulseRunning or not instance.Parent then break end
            
            Core.Animation.tween(instance, {
                Size = UDim2.fromOffset(180, 60)
            }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.5)
        end
    end)
    
    instance.AncestryChanged:Connect(function()
        if not instance.Parent then
            pulseRunning = false
        end
    end)
end

function Shop:selectTab(tabId)
    if self.currentTab == tabId then return end
    
    -- Update tab visuals
    for id, tab in pairs(self.tabs) do
        local isActive = id == tabId
        local data = tab.data
        
        Core.Animation.tween(tab.button, {
            BackgroundColor3 = isActive and 
                Core.Utils.blend(data.color, Color3.new(1, 1, 1), 0.9) or 
                UI.Theme:get("surface")
        }, Core.CONSTANTS.ANIM_FAST)
        
        local stroke = tab.button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = isActive and data.color or UI.Theme:get("stroke")
        end
        
        tab.icon.ImageColor3 = isActive and data.color or UI.Theme:get("text")
        tab.label.TextColor3 = isActive and data.color or UI.Theme:get("text")
    end
    
    -- Update page visibility
    for id, page in pairs(self.pages) do
        page.Visible = id == tabId
        
        if id == tabId then
            -- Animate page entrance
            page.Position = UDim2.fromOffset(0, 20)
            Core.Animation.tween(page, {
                Position = UDim2.new()
            }, Core.CONSTANTS.ANIM_BOUNCE, Enum.EasingStyle.Back)
        end
    end
    
    self.currentTab = tabId
    Core.SoundSystem.play("click")
    Core.Events:emit("tabChanged", tabId)
end

function Shop:promptPurchase(product, productType)
    if productType == "gamepass" then
        -- Check ownership again before prompting
        if Core.DataManager.checkOwnership(product.id) then
            self:refreshProduct(product, productType)
            return
        end
        
        -- Update button state
        product.purchaseButton.Text = "Processing..."
        product.purchaseButton.Active = false
        
        -- Set up purchase tracking
        Core.State.purchasePending[product.id] = {
            product = product,
            timestamp = tick(),
            type = productType,
        }
        
        -- Prompt purchase
        local success = pcall(function()
            MarketplaceService:PromptGamePassPurchase(Player, product.id)
        end)
        
        if not success then
            product.purchaseButton.Text = "Purchase"
            product.purchaseButton.Active = true
            Core.State.purchasePending[product.id] = nil
        end
        
        -- Timeout handler
        task.delay(Core.CONSTANTS.PURCHASE_TIMEOUT, function()
            if Core.State.purchasePending[product.id] then
                product.purchaseButton.Text = "Purchase"
                product.purchaseButton.Active = true
                Core.State.purchasePending[product.id] = nil
            end
        end)
    else
        -- Dev product purchase
        Core.State.purchasePending[product.id] = {
            product = product,
            timestamp = tick(),
            type = productType,
        }
        
        local success = pcall(function()
            MarketplaceService:PromptProductPurchase(Player, product.id)
        end)
        
        if not success then
            Core.State.purchasePending[product.id] = nil
        end
    end
end

function Shop:refreshProduct(product, productType)
    if productType == "gamepass" then
        local isOwned = Core.DataManager.checkOwnership(product.id)
        
        if product.purchaseButton then
            product.purchaseButton.Text = isOwned and "Owned" or "Purchase"
            product.purchaseButton.BackgroundColor3 = isOwned and 
                UI.Theme:get("success") or UI.Theme:get("kuromi")
            product.purchaseButton.Active = not isOwned
        end
        
        if product.cardInstance then
            local stroke = product.cardInstance:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = isOwned and UI.Theme:get("success") or UI.Theme:get("kuromi")
            end
        end
    end
end

function Shop:refreshAllProducts()
    -- Clear ownership cache
    Core.ownershipCache:clear()
    
    -- Refresh all gamepass products
    for _, pass in ipairs(Core.DataManager.products.gamepasses) do
        self:refreshProduct(pass, "gamepass")
    end
    
    Core.Events:emit("productsRefreshed")
end

function Shop:open()
    if Core.State.isOpen or Core.State.isAnimating then return end
    
    Core.State.isAnimating = true
    Core.State.isOpen = true
    
    -- Refresh data
    Core.DataManager.refreshPrices()
    self:refreshAllProducts()
    
    -- Show GUI
    self.gui.Enabled = true
    
    -- Animate blur
    Core.Animation.tween(self.blur, {
        Size = 24
    }, Core.CONSTANTS.ANIM_MEDIUM)
    
    -- Animate panel entrance
    self.mainPanel.Position = UDim2.fromScale(0.5, 0.55)
    self.mainPanel.Size = UDim2.fromOffset(
        self.mainPanel.Size.X.Offset * 0.9,
        self.mainPanel.Size.Y.Offset * 0.9
    )
    
    Core.Animation.tween(self.mainPanel, {
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(
            Core.Utils.isMobile() and Core.CONSTANTS.PANEL_SIZE_MOBILE.X or Core.CONSTANTS.PANEL_SIZE.X,
            Core.Utils.isMobile() and Core.CONSTANTS.PANEL_SIZE_MOBILE.Y or Core.CONSTANTS.PANEL_SIZE.Y
        )
    }, Core.CONSTANTS.ANIM_BOUNCE, Enum.EasingStyle.Back)
    
    Core.SoundSystem.play("open")
    
    task.wait(Core.CONSTANTS.ANIM_BOUNCE)
    Core.State.isAnimating = false
    
    Core.Events:emit("shopOpened")
end

function Shop:close()
    if not Core.State.isOpen or Core.State.isAnimating then return end
    
    Core.State.isAnimating = true
    Core.State.isOpen = false
    
    -- Animate blur
    Core.Animation.tween(self.blur, {
        Size = 0
    }, Core.CONSTANTS.ANIM_FAST)
    
    -- Animate panel exit
    Core.Animation.tween(self.mainPanel, {
        Position = UDim2.fromScale(0.5, 0.55),
        Size = UDim2.fromOffset(
            self.mainPanel.Size.X.Offset * 0.9,
            self.mainPanel.Size.Y.Offset * 0.9
        )
    }, Core.CONSTANTS.ANIM_FAST)
    
    Core.SoundSystem.play("close")
    
    task.wait(Core.CONSTANTS.ANIM_FAST)
    self.gui.Enabled = false
    Core.State.isAnimating = false
    
    Core.Events:emit("shopClosed")
end

function Shop:toggle()
    if Core.State.isOpen then
        self:close()
    else
        self:open()
    end
end

function Shop:setupRemoteHandlers()
    if not Remotes then return end
    
    -- Gamepass purchase confirmation
    local purchaseConfirm = Remotes:FindFirstChild("GamepassPurchased")
    if purchaseConfirm and purchaseConfirm:IsA("RemoteEvent") then
        purchaseConfirm.OnClientEvent:Connect(function(passId)
            Core.ownershipCache:clear()
            self:refreshAllProducts()
            Core.SoundSystem.play("success")
        end)
    end
    
    -- Product grant confirmation
    local productGrant = Remotes:FindFirstChild("ProductGranted")
    if productGrant and productGrant:IsA("RemoteEvent") then
        productGrant.OnClientEvent:Connect(function(productId, amount)
            Core.SoundSystem.play("success")
            
            -- Show notification
            self:showNotification("Purchase Successful!", 
                "You received " .. Core.Utils.formatNumber(amount) .. " cash!")
        end)
    end
end

function Shop:setupInputHandlers()
    -- Keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.M then
            self:toggle()
        elseif input.KeyCode == Enum.KeyCode.Escape and Core.State.isOpen then
            self:close()
        end
    end)
    
    -- Gamepad support
    if UserInputService.GamepadEnabled then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.ButtonX then
                self:toggle()
            end
        end)
    end
end

function Shop:showNotification(title, message, duration)
    duration = duration or 3
    
    local notification = UI.Components.Frame({
        Name = "Notification",
        Size = UDim2.fromOffset(300, 80),
        Position = UDim2.new(0.5, 0, 0, -100),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = UI.Theme:get("surface"),
        cornerRadius = UDim.new(0, 12),
        stroke = {
            color = UI.Theme:get("success"),
            thickness = 2,
        },
        shadow = {
            size = 20,
            transparency = 0.3,
        },
        parent = self.gui,
    }):render()
    
    UI.Layout.stack(notification, Enum.FillDirection.Vertical, 4, {
        left = 16,
        right = 16,
        top = 12,
        bottom = 12,
    })
    
    local titleLabel = UI.Components.TextLabel({
        Text = title,
        Size = UDim2.new(1, 0, 0, 24),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        LayoutOrder = 1,
        parent = notification,
    }):render()
    
    local messageLabel = UI.Components.TextLabel({
        Text = message,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = UI.Theme:get("textSecondary"),
        LayoutOrder = 2,
        parent = notification,
    }):render()
    
    -- Animate in
    Core.Animation.tween(notification, {
        Position = UDim2.new(0.5, 0, 0, 20)
    }, Core.CONSTANTS.ANIM_BOUNCE, Enum.EasingStyle.Back)
    
    Core.SoundSystem.play("notification")
    
    -- Auto dismiss
    task.wait(duration)
    
    Core.Animation.tween(notification, {
        Position = UDim2.new(0.5, 0, 0, -100)
    }, Core.CONSTANTS.ANIM_FAST)
    
    task.wait(Core.CONSTANTS.ANIM_FAST)
    notification:Destroy()
end

-- Purchase Handlers
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    if player ~= Player then return end
    
    local pending = Core.State.purchasePending[passId]
    if not pending then return end
    
    Core.State.purchasePending[passId] = nil
    
    if purchased then
        -- Clear cache to force refresh
        Core.ownershipCache:clear()
        
        -- Update button immediately
        if pending.product.purchaseButton then
            pending.product.purchaseButton.Text = "Owned"
            pending.product.purchaseButton.BackgroundColor3 = UI.Theme:get("success")
            pending.product.purchaseButton.Active = false
        end
        
        Core.SoundSystem.play("success")
        
        -- Refresh all products after a short delay
        task.wait(0.5)
        shop:refreshAllProducts()
    else
        -- Reset button
        if pending.product.purchaseButton then
            pending.product.purchaseButton.Text = "Purchase"
            pending.product.purchaseButton.Active = true
        end
    end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(player, productId, purchased)
    if player ~= Player then return end
    
    local pending = Core.State.purchasePending[productId]
    if not pending then return end
    
    Core.State.purchasePending[productId] = nil
    
    if purchased then
        Core.SoundSystem.play("success")
        
        -- Fire server event if needed
        if Remotes then
            local grantEvent = Remotes:FindFirstChild("GrantProductCurrency")
            if grantEvent and grantEvent:IsA("RemoteEvent") then
                grantEvent:FireServer(productId)
            end
        end
    end
end)

-- Initialize shop
local shop = Shop.new()

-- Handle character respawn
Player.CharacterAdded:Connect(function()
    task.wait(1)
    if not shop.toggleButton or not shop.toggleButton.Parent then
        shop:createToggleButton()
    end
end)

-- Auto-refresh ownership periodically
task.spawn(function()
    while true do
        task.wait(30)
        if Core.State.isOpen then
            shop:refreshAllProducts()
        end
    end
end)

print("[SanrioShop] System initialized successfully!")

return shop