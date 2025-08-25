-- AAA Sanrio Tycoon Shop System - Client Side
-- Professional UI with CSGO-style case opening

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    SoundService = game:GetService("SoundService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Debris = game:GetService("Debris")
}

local Player = Services.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remotes
local Remotes = Services.ReplicatedStorage:WaitForChild("ShopRemotes")
local RemoteEvents = {
    PurchaseItem = Remotes:WaitForChild("PurchaseItem"),
    OpenCase = Remotes:WaitForChild("OpenCase"),
    ActivateBoost = Remotes:WaitForChild("ActivateBoost"),
    ClaimDaily = Remotes:WaitForChild("ClaimDaily")
}
local RemoteFunctions = {
    GetShopData = Remotes:WaitForChild("GetShopData"),
    GetPlayerData = Remotes:WaitForChild("GetPlayerData"),
    GetCaseContents = Remotes:WaitForChild("GetCaseContents")
}

-- Constants
local UI_CONSTANTS = {
    COLORS = {
        PRIMARY = Color3.fromRGB(255, 182, 193), -- Light Pink
        SECONDARY = Color3.fromRGB(255, 255, 255), -- White
        BACKGROUND = Color3.fromRGB(245, 245, 245), -- Light Gray
        ACCENT = Color3.fromRGB(255, 105, 180), -- Hot Pink
        SUCCESS = Color3.fromRGB(46, 204, 113), -- Green
        ERROR = Color3.fromRGB(231, 76, 60), -- Red
        GOLD = Color3.fromRGB(212, 175, 55), -- Gold
        
        -- Rarity Colors
        COMMON = Color3.fromRGB(176, 176, 176),
        RARE = Color3.fromRGB(85, 170, 255),
        EPIC = Color3.fromRGB(163, 53, 238),
        LEGENDARY = Color3.fromRGB(255, 170, 0),
        MYTHIC = Color3.fromRGB(255, 0, 128)
    },
    
    ANIMATIONS = {
        HOVER_SCALE = 1.05,
        CLICK_SCALE = 0.95,
        TRANSITION_TIME = 0.3,
        CASE_SCROLL_TIME = 4.5
    },
    
    SOUNDS = {
        HOVER = "rbxassetid://HOVER_SOUND_ID",
        CLICK = "rbxassetid://CLICK_SOUND_ID",
        PURCHASE = "rbxassetid://PURCHASE_SOUND_ID",
        CASE_TICK = "rbxassetid://CASE_TICK_ID",
        CASE_WIN = "rbxassetid://CASE_WIN_ID",
        ERROR = "rbxassetid://ERROR_SOUND_ID"
    }
}

-- Create Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SanrioShopGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Shop Button
local ShopButton = Instance.new("ImageButton")
ShopButton.Name = "ShopButton"
ShopButton.Size = UDim2.new(0, 80, 0, 80)
ShopButton.Position = UDim2.new(0, 20, 0.5, -40)
ShopButton.Image = "rbxassetid://SHOP_BUTTON_ICON"
ShopButton.BackgroundColor3 = UI_CONSTANTS.COLORS.PRIMARY
ShopButton.BackgroundTransparency = 0.1
ShopButton.Parent = ScreenGui

local ShopButtonCorner = Instance.new("UICorner")
ShopButtonCorner.CornerRadius = UDim.new(0, 16)
ShopButtonCorner.Parent = ShopButton

local ShopButtonStroke = Instance.new("UIStroke")
ShopButtonStroke.Color = UI_CONSTANTS.COLORS.ACCENT
ShopButtonStroke.Thickness = 2
ShopButtonStroke.Parent = ShopButton

-- Main Shop Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainShopFrame"
MainFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = UI_CONSTANTS.COLORS.BACKGROUND
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 20)
MainFrameCorner.Parent = MainFrame

local MainFrameStroke = Instance.new("UIStroke")
MainFrameStroke.Color = UI_CONSTANTS.COLORS.PRIMARY
MainFrameStroke.Thickness = 2
MainFrameStroke.Transparency = 0.5
MainFrameStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 80)
Header.BackgroundColor3 = UI_CONSTANTS.COLORS.PRIMARY
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 20)
HeaderCorner.Parent = Header

local HeaderBottom = Instance.new("Frame")
HeaderBottom.Size = UDim2.new(1, 0, 0, 20)
HeaderBottom.Position = UDim2.new(0, 0, 1, -20)
HeaderBottom.BackgroundColor3 = UI_CONSTANTS.COLORS.PRIMARY
HeaderBottom.BorderSizePixel = 0
HeaderBottom.Parent = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "ShopTitle"
Title.Size = UDim2.new(0.5, 0, 0.7, 0)
Title.Position = UDim2.new(0.25, 0, 0.15, 0)
Title.BackgroundTransparency = 1
Title.Text = "SANRIO TYCOON SHOP"
Title.TextColor3 = UI_CONSTANTS.COLORS.SECONDARY
Title.Font = Enum.Font.Montserrat
Title.TextScaled = true
Title.Parent = Header

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -50, 0.5, -20)
CloseButton.BackgroundColor3 = UI_CONSTANTS.COLORS.ERROR
CloseButton.Text = "X"
CloseButton.TextColor3 = UI_CONSTANTS.COLORS.SECONDARY
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 24
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

-- Currency Display
local CurrencyFrame = Instance.new("Frame")
CurrencyFrame.Name = "CurrencyDisplay"
CurrencyFrame.Size = UDim2.new(0.3, 0, 0.6, 0)
CurrencyFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
CurrencyFrame.BackgroundTransparency = 1
CurrencyFrame.Parent = Header

local CurrencyLayout = Instance.new("UIListLayout")
CurrencyLayout.FillDirection = Enum.FillDirection.Horizontal
CurrencyLayout.Padding = UDim.new(0, 15)
CurrencyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
CurrencyLayout.Parent = CurrencyFrame

-- Function to create currency display
local function createCurrencyDisplay(name, initialValue)
    local container = Instance.new("Frame")
    container.Name = name .. "Display"
    container.Size = UDim2.new(0, 120, 1, 0)
    container.BackgroundColor3 = UI_CONSTANTS.COLORS.SECONDARY
    container.BackgroundTransparency = 0.1
    container.Parent = CurrencyFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 10)
    containerCorner.Parent = container
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 8, 0.5, -12)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. name .. "_ICON"
    icon.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Name = "ValueLabel"
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 35, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(initialValue)
    label.TextColor3 = UI_CONSTANTS.COLORS.BACKGROUND
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.Parent = container
    
    return label
end

local CashDisplay = createCurrencyDisplay("Cash", 0)
local GemsDisplay = createCurrencyDisplay("Gems", 0)
local TokensDisplay = createCurrencyDisplay("Tokens", 0)

-- Category Sidebar
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "CategorySidebar"
Sidebar.Size = UDim2.new(0.2, -10, 1, -90)
Sidebar.Position = UDim2.new(0, 5, 0, 85)
Sidebar.BackgroundColor3 = UI_CONSTANTS.COLORS.SECONDARY
Sidebar.BackgroundTransparency = 0.95
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 4
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.Parent = Sidebar

-- Categories
local CATEGORIES = {
    {id = "store", name = "Store", icon = "STORE_ICON"},
    {id = "boosts", name = "Boosts", icon = "BOOST_ICON"},
    {id = "cases", name = "Cases", icon = "CASE_ICON"},
    {id = "vip", name = "VIP", icon = "VIP_ICON"}
}

local CategoryButtons = {}
local CurrentCategory = "store"

-- Content Area
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(0.8, -15, 1, -90)
ContentArea.Position = UDim2.new(0.2, 10, 0, 85)
ContentArea.BackgroundColor3 = UI_CONSTANTS.COLORS.SECONDARY
ContentArea.BackgroundTransparency = 0.98
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 8
ContentArea.Parent = MainFrame

local ContentLayout = Instance.new("UIGridLayout")
ContentLayout.CellSize = UDim2.new(0.23, -10, 0.3, -10)
ContentLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
ContentLayout.Parent = ContentArea

-- Case Opening GUI
local CaseOpeningFrame = Instance.new("Frame")
CaseOpeningFrame.Name = "CaseOpeningFrame"
CaseOpeningFrame.Size = UDim2.new(1, 0, 1, 0)
CaseOpeningFrame.BackgroundColor3 = Color3.new(0, 0, 0)
CaseOpeningFrame.BackgroundTransparency = 0.3
CaseOpeningFrame.Visible = false
CaseOpeningFrame.Parent = ScreenGui

-- Case Scroll Container
local ScrollContainer = Instance.new("Frame")
ScrollContainer.Name = "ScrollContainer"
ScrollContainer.Size = UDim2.new(0.8, 0, 0, 200)
ScrollContainer.Position = UDim2.new(0.5, 0, 0.5, -100)
ScrollContainer.AnchorPoint = Vector2.new(0.5, 0)
ScrollContainer.BackgroundColor3 = UI_CONSTANTS.COLORS.BACKGROUND
ScrollContainer.ClipsDescendants = true
ScrollContainer.Parent = CaseOpeningFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 20)
ScrollCorner.Parent = ScrollContainer

-- Scroll Line (Center indicator)
local CenterLine = Instance.new("Frame")
CenterLine.Name = "CenterLine"
CenterLine.Size = UDim2.new(0, 4, 1.2, 0)
CenterLine.Position = UDim2.new(0.5, -2, -0.1, 0)
CenterLine.BackgroundColor3 = UI_CONSTANTS.COLORS.GOLD
CenterLine.BorderSizePixel = 0
CenterLine.ZIndex = 10
CenterLine.Parent = ScrollContainer

-- Items Scroller
local ItemsScroller = Instance.new("Frame")
ItemsScroller.Name = "ItemsScroller"
ItemsScroller.Size = UDim2.new(0, 10000, 1, 0) -- Wide for many items
ItemsScroller.Position = UDim2.new(0, 0, 0, 0)
ItemsScroller.BackgroundTransparency = 1
ItemsScroller.Parent = ScrollContainer

local ItemsLayout = Instance.new("UIListLayout")
ItemsLayout.FillDirection = Enum.FillDirection.Horizontal
ItemsLayout.Padding = UDim.new(0, 10)
ItemsLayout.Parent = ItemsScroller

-- CSGO-Style Case Opening Function
local function openCaseAnimation(caseData)
    CaseOpeningFrame.Visible = true
    
    -- Clear previous items
    for _, child in pairs(ItemsScroller:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create items
    local itemFrames = {}
    for i, item in ipairs(caseData.contents) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = "Item" .. i
        itemFrame.Size = UDim2.new(0, 180, 0.9, 0)
        itemFrame.BackgroundColor3 = UI_CONSTANTS.COLORS.SECONDARY
        itemFrame.Parent = ItemsScroller
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 12)
        itemCorner.Parent = itemFrame
        
        -- Rarity border
        local rarityStroke = Instance.new("UIStroke")
        rarityStroke.Color = UI_CONSTANTS.COLORS[item.rarity]
        rarityStroke.Thickness = 3
        rarityStroke.Parent = itemFrame
        
        -- Item image
        local itemImage = Instance.new("ImageLabel")
        itemImage.Size = UDim2.new(0.8, 0, 0.6, 0)
        itemImage.Position = UDim2.new(0.1, 0, 0.1, 0)
        itemImage.BackgroundTransparency = 1
        itemImage.Image = item.icon
        itemImage.ScaleType = Enum.ScaleType.Fit
        itemImage.Parent = itemFrame
        
        -- Item name
        local itemName = Instance.new("TextLabel")
        itemName.Size = UDim2.new(0.9, 0, 0.2, 0)
        itemName.Position = UDim2.new(0.05, 0, 0.75, 0)
        itemName.BackgroundTransparency = 1
        itemName.Text = item.name
        itemName.TextColor3 = Color3.new(0, 0, 0)
        itemName.Font = Enum.Font.SourceSansBold
        itemName.TextScaled = true
        itemName.Parent = itemFrame
        
        table.insert(itemFrames, itemFrame)
    end
    
    -- Position for winner
    local winnerPosition = (caseData.winnerIndex - 1) * 190 + 95 - (ScrollContainer.AbsoluteSize.X / 2)
    
    -- Start position (show first few items)
    ItemsScroller.Position = UDim2.new(0, 100, 0, 0)
    
    -- Create scrolling animation
    local scrollInfo = TweenInfo.new(
        UI_CONSTANTS.ANIMATIONS.CASE_SCROLL_TIME,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )
    
    local scrollTween = Services.TweenService:Create(
        ItemsScroller,
        scrollInfo,
        {Position = UDim2.new(0, -winnerPosition, 0, 0)}
    )
    
    -- Play tick sounds during scroll
    local tickSound = Instance.new("Sound")
    tickSound.SoundId = UI_CONSTANTS.SOUNDS.CASE_TICK
    tickSound.Volume = 0.5
    tickSound.Parent = ScreenGui
    
    local lastTick = 0
    local tickConnection
    tickConnection = Services.RunService.RenderStepped:Connect(function()
        local currentX = ItemsScroller.Position.X.Offset
        local itemsPassed = math.floor(math.abs(currentX) / 190)
        
        if itemsPassed > lastTick then
            lastTick = itemsPassed
            tickSound.PlaybackSpeed = 1 + (itemsPassed / 50) -- Increase pitch
            tickSound:Play()
        end
    end)
    
    scrollTween:Play()
    
    scrollTween.Completed:Connect(function()
        tickConnection:Disconnect()
        tickSound:Destroy()
        
        -- Play win sound
        local winSound = Instance.new("Sound")
        winSound.SoundId = UI_CONSTANTS.SOUNDS.CASE_WIN
        winSound.Volume = 0.7
        winSound.Parent = ScreenGui
        winSound:Play()
        
        -- Highlight winner
        local winnerFrame = itemFrames[caseData.winnerIndex]
        if winnerFrame then
            -- Add glow effect
            local glow = Instance.new("UIStroke")
            glow.Color = UI_CONSTANTS.COLORS.GOLD
            glow.Thickness = 5
            glow.Transparency = 0
            glow.Parent = winnerFrame
            
            -- Pulse animation
            local pulseIn = Services.TweenService:Create(
                winnerFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {Size = UDim2.new(0, 200, 0.95, 0)}
            )
            local pulseOut = Services.TweenService:Create(
                winnerFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {Size = UDim2.new(0, 180, 0.9, 0)}
            )
            
            pulseIn:Play()
            pulseIn.Completed:Connect(function()
                pulseOut:Play()
            end)
        end
        
        -- Show claim button after delay
        wait(2)
        
        local claimButton = Instance.new("TextButton")
        claimButton.Size = UDim2.new(0, 200, 0, 50)
        claimButton.Position = UDim2.new(0.5, -100, 0.7, 0)
        claimButton.BackgroundColor3 = UI_CONSTANTS.COLORS.SUCCESS
        claimButton.Text = "CLAIM"
        claimButton.TextColor3 = UI_CONSTANTS.COLORS.SECONDARY
        claimButton.Font = Enum.Font.SourceSansBold
        claimButton.TextSize = 24
        claimButton.Parent = CaseOpeningFrame
        
        local claimCorner = Instance.new("UICorner")
        claimCorner.CornerRadius = UDim.new(0, 12)
        claimCorner.Parent = claimButton
        
        claimButton.MouseButton1Click:Connect(function()
            CaseOpeningFrame.Visible = false
            claimButton:Destroy()
            winSound:Destroy()
        end)
    end)
end

-- Create category buttons
for _, category in ipairs(CATEGORIES) do
    local button = Instance.new("TextButton")
    button.Name = category.id
    button.Size = UDim2.new(1, -10, 0, 50)
    button.BackgroundColor3 = UI_CONSTANTS.COLORS.SECONDARY
    button.BackgroundTransparency = 0.9
    button.Text = ""
    button.Parent = Sidebar
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = button
    
    local buttonIcon = Instance.new("ImageLabel")
    buttonIcon.Size = UDim2.new(0, 30, 0, 30)
    buttonIcon.Position = UDim2.new(0, 10, 0.5, -15)
    buttonIcon.BackgroundTransparency = 1
    buttonIcon.Image = "rbxassetid://" .. category.icon
    buttonIcon.Parent = button
    
    local buttonLabel = Instance.new("TextLabel")
    buttonLabel.Size = UDim2.new(1, -50, 1, 0)
    buttonLabel.Position = UDim2.new(0, 45, 0, 0)
    buttonLabel.BackgroundTransparency = 1
    buttonLabel.Text = category.name
    buttonLabel.TextColor3 = Color3.new(0, 0, 0)
    buttonLabel.Font = Enum.Font.SourceSans
    buttonLabel.TextSize = 18
    buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
    buttonLabel.Parent = button
    
    CategoryButtons[category.id] = button
    
    button.MouseButton1Click:Connect(function()
        CurrentCategory = category.id
        updateShopContent()
        
        -- Update button states
        for _, btn in pairs(CategoryButtons) do
            btn.BackgroundTransparency = 0.9
        end
        button.BackgroundTransparency = 0.7
    end)
end

-- Shop functionality
local function updateShopContent()
    -- This would be populated with actual shop data
    print("Loading category:", CurrentCategory)
end

local function toggleShop()
    MainFrame.Visible = not MainFrame.Visible
    
    if MainFrame.Visible then
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        local openTween = Services.TweenService:Create(
            MainFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.85, 0, 0.85, 0)}
        )
        openTween:Play()
        updateShopContent()
    end
end

-- Button connections
ShopButton.MouseButton1Click:Connect(toggleShop)
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Handle remote events
RemoteEvents.OpenCase.OnClientEvent:Connect(function(eventType, data)
    if eventType == "CaseResult" and data.success then
        openCaseAnimation(data.data)
    end
end)

-- Update currency displays
spawn(function()
    while true do
        wait(1)
        local playerData = RemoteFunctions.GetPlayerData:InvokeServer()
        if playerData then
            CashDisplay.Text = string.format("%s", playerData.currencies.Cash or 0)
            GemsDisplay.Text = string.format("%s", playerData.currencies.Gems or 0)
            TokensDisplay.Text = string.format("%s", playerData.currencies.Tokens or 0)
        end
    end
end)

print("AAA Sanrio Shop Client Initialized")