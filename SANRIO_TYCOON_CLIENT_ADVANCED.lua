-- ========================================
-- LOCATION: StarterPlayer > StarterPlayerScripts > SANRIO_TYCOON_CLIENT_ADVANCED (LocalScript - NOT Script)
-- ========================================
-- SANRIO TYCOON CLIENT - ADVANCED VERSION
-- With ClientDataManager, WindowManager, Janitor, and Reactive UI
-- Fixes:
--   - Pets now show in inventory immediately after opening egg
--   - Debug panel works and gives currency
--   - Currency display updates reactively
--   - All windows have proper close buttons
--   - Case opening shows what you actually won
--   - No more UpdateValue errors
-- ========================================

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

-- Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Advanced Modules
local ClientDataManager = require(ReplicatedStorage.Modules.Shared.ClientDataManager)
local WindowManager = require(ReplicatedStorage.Modules.Client.WindowManager)
local Janitor = require(ReplicatedStorage.Modules.Shared.Janitor)
local DeltaNetworking = require(ReplicatedStorage.Modules.Shared.DeltaNetworking)

-- Remote Events/Functions
local RemoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteEvents = {}
local RemoteFunctions = {}

for _, obj in ipairs(RemoteFolder:GetChildren()) do
    if obj:IsA("RemoteEvent") then
        RemoteEvents[obj.Name] = obj
    elseif obj:IsA("RemoteFunction") then
        RemoteFunctions[obj.Name] = obj
    end
end

-- ========================================
-- MANAGERS INITIALIZATION
-- ========================================
local DataManager = ClientDataManager.new()
local Windows = WindowManager.new(PlayerGui)
local MainJanitor = Janitor.new()

-- Connect delta networking
local DeltaReceiver = DeltaNetworking.newClient(RemoteEvents.DataUpdated, DataManager)

-- ========================================
-- CONFIGURATION
-- ========================================
local CONFIG = {
    VERSION = "2.0.0",
    ENABLE_DEBUG = game:GetService("RunService"):IsStudio(),
    UI_SOUNDS = {
        click = "rbxassetid://9113642908",
        hover = "rbxassetid://9113651501",
        success = "rbxassetid://9113651440",
        error = "rbxassetid://9113651916",
        notification = "rbxassetid://9113652057"
    }
}

-- ========================================
-- UI MODULES
-- ========================================
local UIModules = {}

-- ========================================
-- MAIN UI SETUP
-- ========================================
local function CreateMainUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SanrioTycoonUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Currency Display
    local currencyFrame = Instance.new("Frame")
    currencyFrame.Name = "CurrencyDisplay"
    currencyFrame.Size = UDim2.new(0, 300, 0, 100)
    currencyFrame.Position = UDim2.new(0, 10, 0, 10)
    currencyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    currencyFrame.BorderSizePixel = 0
    currencyFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = currencyFrame
    
    -- Coins Display
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "Coins"
    coinsLabel.Size = UDim2.new(1, -20, 0.5, -5)
    coinsLabel.Position = UDim2.new(0, 10, 0, 5)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "💰 0"
    coinsLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.Parent = currencyFrame
    
    -- Gems Display
    local gemsLabel = Instance.new("TextLabel")
    gemsLabel.Name = "Gems"
    gemsLabel.Size = UDim2.new(1, -20, 0.5, -5)
    gemsLabel.Position = UDim2.new(0, 10, 0.5, 0)
    gemsLabel.BackgroundTransparency = 1
    gemsLabel.Text = "💎 0"
    gemsLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    gemsLabel.TextScaled = true
    gemsLabel.Font = Enum.Font.SourceSansBold
    gemsLabel.Parent = currencyFrame
    
    -- Tab Buttons
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TabButtons"
    tabFrame.Size = UDim2.new(0, 600, 0, 50)
    tabFrame.Position = UDim2.new(0.5, -300, 1, -60)
    tabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabFrame.BorderSizePixel = 0
    tabFrame.Parent = screenGui
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 12)
    tabCorner.Parent = tabFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabFrame
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.PaddingTop = UDim.new(0, 5)
    tabPadding.PaddingBottom = UDim.new(0, 5)
    tabPadding.Parent = tabFrame
    
    return {
        ScreenGui = screenGui,
        CurrencyFrame = currencyFrame,
        CoinsLabel = coinsLabel,
        GemsLabel = gemsLabel,
        TabFrame = tabFrame
    }
end

local MainUI = CreateMainUI()

-- ========================================
-- REACTIVE CURRENCY DISPLAY
-- ========================================
DataManager:Watch("currencies", function(currencies)
    if currencies then
        MainUI.CoinsLabel.Text = "💰 " .. tostring(currencies.coins or 0)
        MainUI.GemsLabel.Text = "💎 " .. tostring(currencies.gems or 0)
    end
end)

-- ========================================
-- SHOP MODULE
-- ========================================
UIModules.Shop = {}
UIModules.Shop.Janitor = Janitor.new()
UIModules.Shop.WindowId = nil

function UIModules.Shop:CreateContent()
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    
    -- Egg selection
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = content
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 150, 0, 200)
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.Parent = scrollFrame
    
    -- Create egg cards
    local eggs = {
        {id = "basic", name = "Basic Egg", price = 100, currency = "coins", color = Color3.fromRGB(150, 200, 100)},
        {id = "rare", name = "Rare Egg", price = 500, currency = "coins", color = Color3.fromRGB(100, 150, 200)},
        {id = "legendary", name = "Legendary Egg", price = 100, currency = "gems", color = Color3.fromRGB(200, 100, 200)}
    }
    
    for _, egg in ipairs(eggs) do
        local card = self:CreateEggCard(egg)
        card.Parent = scrollFrame
    end
    
    -- Update canvas size
    spawn(function()
        wait(0.1)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y)
    end)
    
    return content
end

function UIModules.Shop:CreateEggCard(eggData)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = eggData.color
    card.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    -- Egg icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.8, 0, 0.5, 0)
    icon.Position = UDim2.new(0.1, 0, 0.05, 0)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://10471290831" -- Placeholder egg icon
    icon.Parent = card
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 5, 0.55, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = eggData.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = card
    
    -- Price
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(1, -10, 0.1, 0)
    priceLabel.Position = UDim2.new(0, 5, 0.7, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = (eggData.currency == "coins" and "💰 " or "💎 ") .. tostring(eggData.price)
    priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.SourceSans
    priceLabel.Parent = card
    
    -- Buy button
    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    buyButton.Position = UDim2.new(0.1, 0, 0.82, 0)
    buyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    buyButton.Text = "BUY"
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextScaled = true
    buyButton.Font = Enum.Font.SourceSansBold
    buyButton.Parent = card
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = buyButton
    
    -- Hover effects
    local janitor = Janitor.new()
    
    janitor:Add(card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {
            Position = card.Position - UDim2.new(0, 0, 0, 5),
            Size = UDim2.new(0, 160, 0, 210)
        }):Play()
        
        -- Play hover sound
        if CONFIG.UI_SOUNDS.hover then
            local sound = Instance.new("Sound")
            sound.SoundId = CONFIG.UI_SOUNDS.hover
            sound.Volume = 0.3
            sound.Parent = workspace
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 1)
        end
    end))
    
    janitor:Add(card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {
            Position = card.Position + UDim2.new(0, 0, 0, 5),
            Size = UDim2.new(0, 150, 0, 200)
        }):Play()
    end))
    
    janitor:Add(buyButton.MouseButton1Click:Connect(function()
        RemoteEvents.OpenCase:FireServer(eggData.id)
        
        -- Click animation
        TweenService:Create(buyButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.7, 0, 0.13, 0)
        }):Play()
        
        wait(0.1)
        
        TweenService:Create(buyButton, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.8, 0, 0.15, 0)
        }):Play()
    end))
    
    -- Store janitor
    card:SetAttribute("Janitor", janitor)
    self.Janitor:Add(janitor)
    
    return card
end

function UIModules.Shop:Open()
    if self.WindowId then
        Windows:CloseWindow(self.WindowId)
    end
    
    self.WindowId = Windows:OpenWindow({
        Title = "🛍️ Sanrio Shop",
        Content = self:CreateContent(),
        Size = UDim2.new(0.6, 0, 0.7, 0)
    })
end

-- ========================================
-- INVENTORY MODULE
-- ========================================
UIModules.Inventory = {}
UIModules.Inventory.Janitor = Janitor.new()
UIModules.Inventory.WindowId = nil

function UIModules.Inventory:CreateContent()
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    
    -- Stats bar
    local statsBar = Instance.new("Frame")
    statsBar.Size = UDim2.new(1, -20, 0, 40)
    statsBar.Position = UDim2.new(0, 10, 0, 10)
    statsBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    statsBar.BorderSizePixel = 0
    statsBar.Parent = content
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsBar
    
    local petCountLabel = Instance.new("TextLabel")
    petCountLabel.Name = "PetCount"
    petCountLabel.Size = UDim2.new(0.5, 0, 1, 0)
    petCountLabel.BackgroundTransparency = 1
    petCountLabel.Text = "Pets: 0/500"
    petCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    petCountLabel.TextScaled = true
    petCountLabel.Font = Enum.Font.SourceSansBold
    petCountLabel.Parent = statsBar
    
    -- Pet grid
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -70)
    scrollFrame.Position = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = content
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 120, 0, 150)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.Parent = scrollFrame
    
    -- Store references
    self.ScrollFrame = scrollFrame
    self.GridLayout = gridLayout
    self.PetCountLabel = petCountLabel
    
    -- Reactive update
    self:RefreshInventory()
    
    return content
end

function UIModules.Inventory:RefreshInventory()
    if not self.ScrollFrame then return end
    
    -- Clear existing
    for _, child in ipairs(self.ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get pets from data manager
    local playerData = DataManager:GetData()
    if not playerData or not playerData.pets then return end
    
    -- Convert dictionary to array for display
    local pets = {}
    for id, pet in pairs(playerData.pets) do
        table.insert(pets, pet)
    end
    
    -- Update count
    if self.PetCountLabel then
        self.PetCountLabel.Text = string.format("Pets: %d/500", #pets)
    end
    
    -- Create pet cards
    for _, pet in ipairs(pets) do
        local card = self:CreatePetCard(pet)
        card.Parent = self.ScrollFrame
    end
    
    -- Update canvas size
    spawn(function()
        wait(0.1)
        if self.ScrollFrame and self.GridLayout then
            self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, self.GridLayout.AbsoluteContentSize.Y)
        end
    end)
end

function UIModules.Inventory:CreatePetCard(petData)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    card.BorderSizePixel = 0
    
    -- Animation entrance
    card.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 120, 0, 150)
    }):Play()
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    -- Tier color border
    local tierColors = {
        Common = Color3.fromRGB(150, 150, 150),
        Rare = Color3.fromRGB(100, 150, 200),
        Epic = Color3.fromRGB(150, 100, 200),
        Legendary = Color3.fromRGB(200, 150, 50)
    }
    
    local border = Instance.new("UIStroke")
    border.Color = tierColors[petData.tier] or Color3.fromRGB(255, 255, 255)
    border.Thickness = 3
    border.Parent = card
    
    -- Pet icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.8, 0, 0.5, 0)
    icon.Position = UDim2.new(0.1, 0, 0.05, 0)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://10471290831" -- Placeholder
    icon.Parent = card
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 5, 0.55, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = petData.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.Parent = card
    
    -- Level
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, -10, 0.1, 0)
    levelLabel.Position = UDim2.new(0, 5, 0.7, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv. " .. tostring(petData.level)
    levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSans
    levelLabel.Parent = card
    
    -- Variant indicator
    if petData.variant ~= "normal" then
        local variantLabel = Instance.new("TextLabel")
        variantLabel.Size = UDim2.new(1, -10, 0.1, 0)
        variantLabel.Position = UDim2.new(0, 5, 0.8, 0)
        variantLabel.BackgroundTransparency = 1
        variantLabel.Text = petData.variant:upper()
        variantLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        variantLabel.TextScaled = true
        variantLabel.Font = Enum.Font.SourceSansBold
        variantLabel.Parent = card
    end
    
    return card
end

function UIModules.Inventory:Open()
    if self.WindowId then
        Windows:CloseWindow(self.WindowId)
    end
    
    self.WindowId = Windows:OpenWindow({
        Title = "🎒 My Pets",
        Content = self:CreateContent(),
        Size = UDim2.new(0.7, 0, 0.8, 0)
    })
end

-- Watch for pet changes
DataManager:Watch("pets", function(pets)
    if UIModules.Inventory.WindowId then
        UIModules.Inventory:RefreshInventory()
    end
end)

-- ========================================
-- TAB BUTTON CREATION
-- ========================================
local function CreateTabButton(name, icon, callback)
    local button = Instance.new("TextButton")
    button.Name = name .. "Tab"
    button.Size = UDim2.new(0, 100, 1, -10)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.Text = icon .. " " .. name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.Parent = MainUI.TabFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Hover effect
    MainJanitor:Add(button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(80, 80, 80),
            Size = UDim2.new(0, 110, 1, -5)
        }):Play()
    end))
    
    MainJanitor:Add(button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            Size = UDim2.new(0, 100, 1, -10)
        }):Play()
    end))
    
    MainJanitor:Add(button.MouseButton1Click:Connect(callback))
    
    return button
end

-- Create tabs
CreateTabButton("Shop", "🛍️", function() UIModules.Shop:Open() end)
CreateTabButton("Pets", "🎒", function() UIModules.Inventory:Open() end)
CreateTabButton("Trade", "🤝", function() 
    Windows:ShowAlert("Coming Soon", "Trading system will be available in the next update!", function() end)
end)
CreateTabButton("Battle", "⚔️", function()
    Windows:ShowAlert("Coming Soon", "Battle system will be available in the next update!", function() end)
end)

-- ========================================
-- NOTIFICATION HANDLER
-- ========================================
RemoteEvents.NotificationSent.OnClientEvent:Connect(function(data)
    -- Create notification
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 300, 0, 80)
    notif.Position = UDim2.new(1, 10, 1, -100)
    notif.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notif.BorderSizePixel = 0
    notif.Parent = MainUI.ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notif
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0.4, 0)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = data.title or "Notification"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = notif
    
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -20, 0.5, 0)
    message.Position = UDim2.new(0, 10, 0.4, 0)
    message.BackgroundTransparency = 1
    message.Text = data.message or ""
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.TextScaled = true
    message.Font = Enum.Font.SourceSans
    message.Parent = notif
    
    -- Animate in
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -310, 1, -100)
    }):Play()
    
    -- Play sound
    if CONFIG.UI_SOUNDS.notification then
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.UI_SOUNDS.notification
        sound.Volume = 0.5
        sound.Parent = workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end
    
    -- Animate out after 3 seconds
    wait(3)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 10, 1, -100)
    }):Play()
    wait(0.3)
    notif:Destroy()
end)

-- ========================================
-- CASE OPENING RESULT HANDLER
-- ========================================
RemoteEvents.DataUpdated.OnClientEvent:Connect(function(data)
    if data.type == "caseOpened" then
        -- Show pet obtained
        local resultFrame = Instance.new("Frame")
        resultFrame.Size = UDim2.new(0, 400, 0, 500)
        resultFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
        resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        resultFrame.BorderSizePixel = 0
        resultFrame.ZIndex = 100
        resultFrame.Parent = MainUI.ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 20)
        corner.Parent = resultFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0.1, 0)
        title.BackgroundTransparency = 1
        title.Text = "YOU GOT!"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextScaled = true
        title.Font = Enum.Font.SourceSansBold
        title.Parent = resultFrame
        
        -- Pet display
        local petFrame = Instance.new("Frame")
        petFrame.Size = UDim2.new(0.8, 0, 0.5, 0)
        petFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
        petFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        petFrame.BorderSizePixel = 0
        petFrame.Parent = resultFrame
        
        local petCorner = Instance.new("UICorner")
        petCorner.CornerRadius = UDim.new(0, 12)
        petCorner.Parent = petFrame
        
        -- Pet name
        local petName = Instance.new("TextLabel")
        petName.Size = UDim2.new(1, 0, 0.1, 0)
        petName.Position = UDim2.new(0, 0, 0.7, 0)
        petName.BackgroundTransparency = 1
        petName.Text = data.pet.name
        petName.TextColor3 = Color3.fromRGB(255, 255, 255)
        petName.TextScaled = true
        petName.Font = Enum.Font.SourceSansBold
        petName.Parent = resultFrame
        
        -- Rarity
        local rarity = Instance.new("TextLabel")
        rarity.Size = UDim2.new(1, 0, 0.08, 0)
        rarity.Position = UDim2.new(0, 0, 0.8, 0)
        rarity.BackgroundTransparency = 1
        rarity.Text = data.pet.tier .. " - " .. data.pet.variant:upper()
        rarity.TextColor3 = data.pet.variant == "shiny" and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
        rarity.TextScaled = true
        rarity.Font = Enum.Font.SourceSans
        rarity.Parent = resultFrame
        
        -- OK button
        local okButton = Instance.new("TextButton")
        okButton.Size = UDim2.new(0.4, 0, 0.08, 0)
        okButton.Position = UDim2.new(0.3, 0, 0.9, 0)
        okButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        okButton.Text = "AWESOME!"
        okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        okButton.TextScaled = true
        okButton.Font = Enum.Font.SourceSansBold
        okButton.Parent = resultFrame
        
        local okCorner = Instance.new("UICorner")
        okCorner.CornerRadius = UDim.new(0, 8)
        okCorner.Parent = okButton
        
        -- Animate in
        resultFrame.Size = UDim2.new(0, 0, 0, 0)
        resultFrame.Rotation = -180
        TweenService:Create(resultFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 400, 0, 500),
            Rotation = 0
        }):Play()
        
        -- Play success sound
        if CONFIG.UI_SOUNDS.success then
            local sound = Instance.new("Sound")
            sound.SoundId = CONFIG.UI_SOUNDS.success
            sound.Volume = 0.7
            sound.Parent = workspace
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 3)
        end
        
        okButton.MouseButton1Click:Connect(function()
            TweenService:Create(resultFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Rotation = 180
            }):Play()
            wait(0.3)
            resultFrame:Destroy()
        end)
    end
end)

-- ========================================
-- DEBUG PANEL (Studio Only)
-- ========================================
if CONFIG.ENABLE_DEBUG then
    local debugFrame = Instance.new("Frame")
    debugFrame.Size = UDim2.new(0, 200, 0, 300)
    debugFrame.Position = UDim2.new(1, -210, 1, -310)
    debugFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    debugFrame.BorderSizePixel = 0
    debugFrame.Parent = MainUI.ScreenGui
    
    local debugCorner = Instance.new("UICorner")
    debugCorner.CornerRadius = UDim.new(0, 12)
    debugCorner.Parent = debugFrame
    
    local debugTitle = Instance.new("TextLabel")
    debugTitle.Size = UDim2.new(1, 0, 0, 30)
    debugTitle.BackgroundTransparency = 1
    debugTitle.Text = "DEBUG PANEL"
    debugTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
    debugTitle.TextScaled = true
    debugTitle.Font = Enum.Font.SourceSansBold
    debugTitle.Parent = debugFrame
    
    local debugLayout = Instance.new("UIListLayout")
    debugLayout.Padding = UDim.new(0, 5)
    debugLayout.Parent = debugFrame
    
    local function CreateDebugButton(text, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSans
        button.Parent = debugFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(callback)
        return button
    end
    
    CreateDebugButton("Give 10K Coins", function()
        RemoteFunctions.DebugGiveCurrency:InvokeServer("coins", 10000)
    end)
    
    CreateDebugButton("Give 1K Gems", function()
        RemoteFunctions.DebugGiveCurrency:InvokeServer("gems", 1000)
    end)
    
    CreateDebugButton("Open Basic Egg", function()
        RemoteEvents.OpenCase:FireServer("basic")
    end)
    
    CreateDebugButton("Open Legendary Egg", function()
        RemoteEvents.OpenCase:FireServer("legendary")
    end)
    
    CreateDebugButton("Print Data", function()
        print("Current Player Data:")
        print(DataManager:GetData())
    end)
    
    CreateDebugButton("Memory Usage", function()
        print("Data Manager Memory:", DataManager:GetMemoryUsage(), "bytes")
    end)
end

-- ========================================
-- CLEANUP ON LEAVE
-- ========================================
Players.PlayerRemoving:Connect(function(player)
    if player == Player then
        MainJanitor:Cleanup()
        for _, module in pairs(UIModules) do
            if module.Janitor then
                module.Janitor:Cleanup()
            end
        end
    end
end)

print("[SanrioTycoon] Advanced Client v" .. CONFIG.VERSION .. " initialized")
print("[SanrioTycoon] Data Manager: REACTIVE")
print("[SanrioTycoon] Window Manager: ENABLED")
print("[SanrioTycoon] Memory Management: JANITOR")