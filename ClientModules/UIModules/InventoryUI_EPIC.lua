--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                          EPIC INVENTORY UI - COMPLETE REVAMP                         ║
    ║                    Matching the insane PetDatabase with epic features                ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Janitor = require(game.ReplicatedStorage.Modules.Shared.Janitor)
local EffectPool = require(script.Parent.Parent.Systems.EffectPool)
local PetDatabase = require(game.ReplicatedStorage.Modules.Shared.PetDatabase)

local InventoryUI = {}
InventoryUI.__index = InventoryUI

-- ========================================
-- EPIC CONSTANTS
-- ========================================

-- Rarity colors matching PetDatabase
local RARITY_COLORS = {
    [1] = Color3.fromRGB(200, 200, 200), -- Common
    [2] = Color3.fromRGB(85, 170, 255),  -- Rare
    [3] = Color3.fromRGB(163, 53, 238),  -- Epic
    [4] = Color3.fromRGB(255, 170, 0),   -- Legendary
    [5] = Color3.fromRGB(255, 92, 161),  -- Mythical
    [6] = Color3.fromRGB(255, 255, 0),   -- Divine
    [7] = Color3.fromRGB(185, 242, 255), -- Celestial
    [8] = Color3.fromRGB(255, 0, 255),   -- Immortal
}

local RARITY_NAMES = {
    [1] = "COMMON",
    [2] = "RARE",
    [3] = "EPIC",
    [4] = "LEGENDARY",
    [5] = "MYTHICAL",
    [6] = "DIVINE",
    [7] = "CELESTIAL",
    [8] = "IMMORTAL"
}

-- Variant colors
local VARIANT_EFFECTS = {
    NORMAL = {color = Color3.new(1, 1, 1), glow = 0},
    SHINY = {color = Color3.fromRGB(255, 255, 255), glow = 0.3, sparkles = true},
    GOLDEN = {color = Color3.fromRGB(255, 215, 0), glow = 0.5, shine = true},
    RAINBOW = {color = "Rainbow", glow = 0.7, animated = true},
    SHADOW = {color = Color3.fromRGB(0, 0, 0), glow = 0.8, darkness = true},
    COSMIC = {color = "Galaxy", glow = 1.0, stars = true},
    VOID = {color = "Void", glow = 1.5, blackHole = true}
}

-- UI Settings
local CARD_SIZE = Vector2.new(140, 170) -- Bigger for more details
local CARDS_PER_ROW = 6
local GRID_PADDING = 15
local ANIMATION_TIME = 0.3

-- Filter categories
local FILTER_CATEGORIES = {
    {
        name = "Status",
        filters = {"All", "Equipped", "Locked", "Favorite"}
    },
    {
        name = "Rarity",
        filters = {"Common", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Celestial", "Immortal"}
    },
    {
        name = "Variant",
        filters = {"Normal", "Shiny", "Golden", "Rainbow", "Shadow", "Cosmic", "Void"}
    },
    {
        name = "Special",
        filters = {"Limited", "Event", "Secret", "Fusion", "Awakened", "Corrupted", "Glitched"}
    },
    {
        name = "Series",
        filters = {"Hello Kitty", "My Melody", "Kuromi", "Cinnamoroll", "Pompompurin", "Others"}
    }
}

-- Sort options
local SORT_OPTIONS = {
    "Power",
    "Rarity",
    "Level",
    "Recent",
    "Name",
    "Variant",
    "Series"
}

-- ========================================
-- INITIALIZATION
-- ========================================

function InventoryUI.new(dependencies)
    local self = setmetatable({}, InventoryUI)
    
    -- Initialize Janitor
    self._janitor = Janitor.new()
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    self._dataCache = dependencies.DataCache
    self._remoteManager = dependencies.RemoteManager
    self._soundSystem = dependencies.SoundSystem
    self._particleSystem = dependencies.ParticleSystem
    self._animationSystem = dependencies.AnimationSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._uiFactory = dependencies.UIFactory
    self._windowManager = dependencies.WindowManager
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self.PetGrid = nil
    self.FilterPanels = {}
    self.ActiveFilters = {}
    self.SortDropdown = nil
    self.CurrentSort = "Power"
    self.SearchBox = nil
    self.SearchText = ""
    
    -- Pet tracking
    self.AllPets = {}
    self.FilteredPets = {}
    self.PetCards = {}
    self.SelectedPets = {}
    
    -- Performance
    self.VirtualScrolling = true
    self.CardPool = {}
    self.VisibleCards = {}
    
    -- Special effects pools
    self.RarityEffectPools = {}
    self.VariantEffectPools = {}
    
    -- Initialize effect pools for each rarity
    for rarity = 6, 8 do -- Divine, Celestial, Immortal
        self.RarityEffectPools[rarity] = EffectPool.new({
            effectType = "RarityAura_" .. RARITY_NAMES[rarity],
            initialSize = 10,
            maxSize = 50,
            createFunction = function()
                return self:CreateRarityEffect(rarity)
            end
        })
    end
    
    -- Setup event listeners
    self:SetupEventListeners()
    
    return self
end

-- ========================================
-- UI CREATION
-- ========================================

function InventoryUI:Create()
    -- Create main window
    self.Frame = self._windowManager:CreateWindow({
        title = "✨ EPIC PET COLLECTION ✨",
        size = UDim2.new(0.9, 0, 0.9, 0),
        minSize = Vector2.new(800, 600),
        closeable = true,
        resizable = true,
        icon = "rbxassetid://123456789"
    })
    
    -- Create epic background
    local background = Instance.new("ImageLabel")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundTransparency = 1
    background.Image = "rbxassetid://987654321" -- Epic gradient background
    background.ImageTransparency = 0.95
    background.ZIndex = -1
    background.Parent = self.Frame
    
    -- Create sections
    self:CreateHeader()
    self:CreateFilterPanel()
    self:CreatePetGrid()
    self:CreateBottomBar()
    
    -- Add epic animations
    self:AddOpeningAnimation()
    
    self._janitor:Add(self.Frame)
    
    return self.Frame
end

function InventoryUI:CreateHeader()
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 120)
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BorderSizePixel = 0
    header.Parent = self.Frame
    
    self._utilities.CreateCorner(header, 0)
    
    -- Epic title with gradient
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, RARITY_COLORS[5]), -- Mythical
        ColorSequenceKeypoint.new(0.5, RARITY_COLORS[6]), -- Divine
        ColorSequenceKeypoint.new(1, RARITY_COLORS[7]) -- Celestial
    })
    titleGradient.Parent = header
    
    -- Collection stats
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(0.4, 0, 1, -20)
    statsContainer.Position = UDim2.new(0, 10, 0, 10)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = header
    
    -- Total pets counter with animation
    self.TotalPetsLabel = self:CreateAnimatedStat(statsContainer, {
        position = UDim2.new(0, 0, 0, 0),
        icon = "🐾",
        label = "Total Pets",
        value = 0,
        color = RARITY_COLORS[4]
    })
    
    -- Collection value display
    self.CollectionValueLabel = self:CreateAnimatedStat(statsContainer, {
        position = UDim2.new(0, 0, 0.33, 0),
        icon = "💎",
        label = "Collection Power",
        value = 0,
        color = RARITY_COLORS[6]
    })
    
    -- Rarity breakdown
    self.RarityBreakdown = self:CreateRarityBreakdown(statsContainer, {
        position = UDim2.new(0, 0, 0.66, 0)
    })
    
    -- Search with epic styling
    self:CreateSearchBar(header)
    
    -- Quick action buttons
    self:CreateQuickActions(header)
end

function InventoryUI:CreateSearchBar(parent)
    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(0.3, 0, 0, 50)
    searchContainer.Position = UDim2.new(0.5, -150, 0.5, -25)
    searchContainer.BackgroundColor3 = Color3.new(1, 1, 1)
    searchContainer.Parent = parent
    
    self._utilities.CreateCorner(searchContainer, 25)
    self._utilities.CreateStroke(searchContainer, RARITY_COLORS[5], 2)
    
    -- Animated search icon
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.new(0, 30, 0, 30)
    searchIcon.Position = UDim2.new(0, 10, 0.5, -15)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://3926305904"
    searchIcon.ImageRectOffset = Vector2.new(324, 364)
    searchIcon.ImageRectSize = Vector2.new(36, 36)
    searchIcon.ImageColor3 = RARITY_COLORS[5]
    searchIcon.Parent = searchContainer
    
    -- Search input
    self.SearchBox = Instance.new("TextBox")
    self.SearchBox.Size = UDim2.new(1, -60, 1, 0)
    self.SearchBox.Position = UDim2.new(0, 50, 0, 0)
    self.SearchBox.BackgroundTransparency = 1
    self.SearchBox.Font = Enum.Font.Gotham
    self.SearchBox.PlaceholderText = "Search epic pets..."
    self.SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    self.SearchBox.Text = ""
    self.SearchBox.TextColor3 = Color3.fromRGB(50, 50, 50)
    self.SearchBox.TextScaled = true
    self.SearchBox.Parent = searchContainer
    
    -- Live search with debounce
    local searchDebounce = nil
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if searchDebounce then
            searchDebounce:Disconnect()
        end
        
        searchDebounce = task.wait(SEARCH_DEBOUNCE)
        if searchDebounce then
            self.SearchText = self.SearchBox.Text
            self:ApplyFilters()
            
            -- Pulse animation on search
            self._utilities.Tween(searchIcon, {
                ImageColor3 = RARITY_COLORS[7]
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
            
            task.wait(0.2)
            
            self._utilities.Tween(searchIcon, {
                ImageColor3 = RARITY_COLORS[5]
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
        end
    end)
end

function InventoryUI:CreateFilterPanel()
    local filterPanel = Instance.new("ScrollingFrame")
    filterPanel.Name = "FilterPanel"
    filterPanel.Size = UDim2.new(0.2, -10, 1, -180)
    filterPanel.Position = UDim2.new(0, 10, 0, 130)
    filterPanel.BackgroundColor3 = Color3.new(1, 1, 1)
    filterPanel.BorderSizePixel = 0
    filterPanel.ScrollBarThickness = 4
    filterPanel.Parent = self.Frame
    
    self._utilities.CreateCorner(filterPanel, 12)
    self._utilities.CreateStroke(filterPanel, Color3.fromRGB(230, 230, 230), 1)
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = filterPanel
    
    -- Create filter categories
    for _, category in ipairs(FILTER_CATEGORIES) do
        self:CreateFilterCategory(filterPanel, category)
    end
    
    -- Sort dropdown
    self:CreateSortDropdown(filterPanel)
end

function InventoryUI:CreateFilterCategory(parent, category)
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(1, -20, 0, 0)
    categoryFrame.AutomaticSize = Enum.AutomaticSize.Y
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Parent = parent
    
    -- Category header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.Text = category.name
    header.TextColor3 = RARITY_COLORS[5]
    header.TextScaled = true
    header.Parent = categoryFrame
    
    -- Filter buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, 0, 0, 0)
    buttonContainer.Position = UDim2.new(0, 0, 0, 35)
    buttonContainer.AutomaticSize = Enum.AutomaticSize.Y
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = categoryFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.48, 0, 0, 30)
    gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 5)
    gridLayout.Parent = buttonContainer
    
    for _, filterName in ipairs(category.filters) do
        local button = self:CreateFilterButton(buttonContainer, filterName, category.name)
        self.FilterPanels[category.name .. "_" .. filterName] = button
    end
end

function InventoryUI:CreateFilterButton(parent, filterName, categoryName)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.Gotham
    button.Text = filterName
    button.TextColor3 = Color3.fromRGB(100, 100, 100)
    button.TextScaled = true
    button.BorderSizePixel = 0
    button.Parent = parent
    
    self._utilities.CreateCorner(button, 6)
    
    local isActive = false
    
    button.MouseButton1Click:Connect(function()
        isActive = not isActive
        
        if isActive then
            -- Activate filter
            button.BackgroundColor3 = RARITY_COLORS[5]
            button.TextColor3 = Color3.new(1, 1, 1)
            
            if not self.ActiveFilters[categoryName] then
                self.ActiveFilters[categoryName] = {}
            end
            self.ActiveFilters[categoryName][filterName] = true
            
            -- Epic activation effect
            local glow = Instance.new("ImageLabel")
            glow.Size = UDim2.new(1, 10, 1, 10)
            glow.Position = UDim2.new(0.5, 0, 0.5, 0)
            glow.AnchorPoint = Vector2.new(0.5, 0.5)
            glow.BackgroundTransparency = 1
            glow.Image = "rbxassetid://5028857084"
            glow.ImageColor3 = RARITY_COLORS[5]
            glow.ZIndex = -1
            glow.Parent = button
            
            self._utilities.Tween(glow, {
                Size = UDim2.new(1, 20, 1, 20),
                ImageTransparency = 1
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
            
            game:GetService("Debris"):AddItem(glow, 0.3)
        else
            -- Deactivate filter
            button.BackgroundColor3 = Color3.new(1, 1, 1)
            button.TextColor3 = Color3.fromRGB(100, 100, 100)
            
            if self.ActiveFilters[categoryName] then
                self.ActiveFilters[categoryName][filterName] = nil
            end
        end
        
        self:ApplyFilters()
        self._soundSystem:PlayUISound("Click")
    end)
    
    return button
end

function InventoryUI:CreatePetGrid()
    local gridContainer = Instance.new("Frame")
    gridContainer.Size = UDim2.new(0.8, -20, 1, -180)
    gridContainer.Position = UDim2.new(0.2, 10, 0, 130)
    gridContainer.BackgroundColor3 = Color3.new(1, 1, 1)
    gridContainer.Parent = self.Frame
    
    self._utilities.CreateCorner(gridContainer, 12)
    
    -- Epic grid background pattern
    local pattern = Instance.new("ImageLabel")
    pattern.Size = UDim2.new(1, 0, 1, 0)
    pattern.BackgroundTransparency = 1
    pattern.Image = "rbxassetid://123123123" -- Subtle pattern
    pattern.ImageTransparency = 0.98
    pattern.ScaleType = Enum.ScaleType.Tile
    pattern.TileSize = UDim2.new(0, 100, 0, 100)
    pattern.ZIndex = -1
    pattern.Parent = gridContainer
    
    -- Scrolling frame
    self.PetGrid = Instance.new("ScrollingFrame")
    self.PetGrid.Size = UDim2.new(1, -20, 1, -20)
    self.PetGrid.Position = UDim2.new(0, 10, 0, 10)
    self.PetGrid.BackgroundTransparency = 1
    self.PetGrid.ScrollBarThickness = 8
    self.PetGrid.ScrollBarImageColor3 = RARITY_COLORS[5]
    self.PetGrid.Parent = gridContainer
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, CARD_SIZE.X, 0, CARD_SIZE.Y)
    gridLayout.CellPadding = UDim2.new(0, GRID_PADDING, 0, GRID_PADDING)
    gridLayout.Parent = self.PetGrid
    
    -- Virtual scrolling setup
    if self.VirtualScrolling then
        self:SetupVirtualScrolling()
    end
end

function InventoryUI:CreateBottomBar()
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 60)
    bottomBar.Position = UDim2.new(0, 0, 1, -60)
    bottomBar.BackgroundColor3 = Color3.new(1, 1, 1)
    bottomBar.Parent = self.Frame
    
    self._utilities.CreateCorner(bottomBar, 0)
    
    -- Action buttons
    local actions = {
        {name = "Equip Best", icon = "⚔️", color = RARITY_COLORS[4]},
        {name = "Mass Delete", icon = "🗑️", color = Color3.fromRGB(255, 100, 100)},
        {name = "Evolution", icon = "✨", color = RARITY_COLORS[5]},
        {name = "Fusion", icon = "🔮", color = RARITY_COLORS[6]},
        {name = "Collection", icon = "📊", color = RARITY_COLORS[7]}
    }
    
    for i, action in ipairs(actions) do
        local button = self:CreateActionButton(bottomBar, action, i)
    end
end

-- ========================================
-- PET CARD CREATION
-- ========================================

function InventoryUI:CreatePetCard(petInstance, petData)
    local card = Instance.new("Frame")
    card.Name = "PetCard_" .. petInstance.uniqueId
    card.BackgroundColor3 = Color3.new(1, 1, 1)
    card.BorderSizePixel = 0
    
    -- Epic card shape
    self._utilities.CreateCorner(card, 16)
    
    -- Rarity gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, RARITY_COLORS[petData.rarity] or RARITY_COLORS[1])
    })
    gradient.Rotation = 45
    gradient.Parent = card
    
    -- Shadow for depth
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.85
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = -1
    shadow.Parent = card
    
    -- Rarity border effect
    if petData.rarity >= 6 then -- Divine and above
        self:AddRarityEffect(card, petData.rarity)
    end
    
    -- Variant effect
    if petInstance.variant and petInstance.variant ~= "NORMAL" then
        self:AddVariantEffect(card, petInstance.variant)
    end
    
    -- Pet image container with special effects
    local imageContainer = Instance.new("Frame")
    imageContainer.Size = UDim2.new(1, -20, 0.6, 0)
    imageContainer.Position = UDim2.new(0, 10, 0, 10)
    imageContainer.BackgroundTransparency = 1
    imageContainer.Parent = card
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, 0, 1, 0)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.icon or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = imageContainer
    
    -- Level badge with glow
    local levelBadge = Instance.new("Frame")
    levelBadge.Size = UDim2.new(0, 40, 0, 25)
    levelBadge.Position = UDim2.new(0, 5, 0, 5)
    levelBadge.BackgroundColor3 = RARITY_COLORS[petData.rarity] or RARITY_COLORS[1]
    levelBadge.Parent = card
    
    self._utilities.CreateCorner(levelBadge, 12)
    
    local levelText = Instance.new("TextLabel")
    levelText.Size = UDim2.new(1, 0, 1, 0)
    levelText.BackgroundTransparency = 1
    levelText.Font = Enum.Font.GothamBold
    levelText.Text = "Lv." .. tostring(petInstance.level or 1)
    levelText.TextColor3 = Color3.new(1, 1, 1)
    levelText.TextScaled = true
    levelText.Parent = levelBadge
    
    -- Pet name with rarity color
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 5, 0.62, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = petInstance.nickname or petData.displayName or petData.name
    nameLabel.TextColor3 = RARITY_COLORS[petData.rarity] or RARITY_COLORS[1]
    nameLabel.TextScaled = true
    nameLabel.Parent = card
    
    -- Power display with icon
    local powerFrame = Instance.new("Frame")
    powerFrame.Size = UDim2.new(1, -10, 0.15, 0)
    powerFrame.Position = UDim2.new(0, 5, 0.78, 0)
    powerFrame.BackgroundTransparency = 1
    powerFrame.Parent = card
    
    local powerIcon = Instance.new("TextLabel")
    powerIcon.Size = UDim2.new(0.3, 0, 1, 0)
    powerIcon.BackgroundTransparency = 1
    powerIcon.Font = Enum.Font.GothamBold
    powerIcon.Text = "⚡"
    powerIcon.TextColor3 = Color3.fromRGB(255, 200, 0)
    powerIcon.TextScaled = true
    powerIcon.Parent = powerFrame
    
    local powerValue = self:CalculatePetPower(petInstance, petData)
    local powerLabel = Instance.new("TextLabel")
    powerLabel.Size = UDim2.new(0.7, 0, 1, 0)
    powerLabel.Position = UDim2.new(0.3, 0, 0, 0)
    powerLabel.BackgroundTransparency = 1
    powerLabel.Font = Enum.Font.Gotham
    powerLabel.Text = self:FormatNumber(powerValue)
    powerLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    powerLabel.TextScaled = true
    powerLabel.Parent = powerFrame
    
    -- Status indicators
    if petInstance.equipped then
        self:AddEquippedIndicator(card)
    end
    
    if petInstance.locked then
        self:AddLockedIndicator(card)
    end
    
    -- Special badges
    if petData.limitedEdition then
        self:AddLimitedBadge(card)
    end
    
    if petData.secret then
        self:AddSecretBadge(card)
    end
    
    -- Click handler
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.ZIndex = 10
    clickButton.Parent = card
    
    clickButton.MouseButton1Click:Connect(function()
        self:OnPetCardClicked(petInstance, petData)
    end)
    
    -- Hover effects
    clickButton.MouseEnter:Connect(function()
        self:OnCardHoverEnter(card, petData.rarity)
    end)
    
    clickButton.MouseLeave:Connect(function()
        self:OnCardHoverLeave(card, petData.rarity)
    end)
    
    return card
end

-- ========================================
-- SPECIAL EFFECTS
-- ========================================

function InventoryUI:AddRarityEffect(card, rarity)
    if rarity == 6 then -- Divine
        -- Golden aura
        local aura = Instance.new("ImageLabel")
        aura.Size = UDim2.new(1, 30, 1, 30)
        aura.Position = UDim2.new(0.5, 0, 0.5, 0)
        aura.AnchorPoint = Vector2.new(0.5, 0.5)
        aura.BackgroundTransparency = 1
        aura.Image = "rbxassetid://5028857084"
        aura.ImageColor3 = RARITY_COLORS[6]
        aura.ZIndex = -1
        aura.Parent = card
        
        -- Pulsing animation
        local pulse = game:GetService("RunService").Heartbeat:Connect(function()
            aura.ImageTransparency = 0.3 + math.sin(tick() * 2) * 0.2
        end)
        
        self._janitor:Add(pulse)
        
    elseif rarity == 7 then -- Celestial
        -- Floating stars
        for i = 1, 3 do
            local star = Instance.new("ImageLabel")
            star.Size = UDim2.new(0, 20, 0, 20)
            star.Position = UDim2.new(math.random(), 0, math.random(), 0)
            star.BackgroundTransparency = 1
            star.Image = "rbxassetid://6034684930"
            star.ImageColor3 = RARITY_COLORS[7]
            star.Parent = card
            
            -- Orbit animation
            task.spawn(function()
                local angle = math.random() * math.pi * 2
                while star.Parent do
                    angle = angle + 0.02
                    star.Position = UDim2.new(
                        0.5 + math.cos(angle) * 0.3, 0,
                        0.5 + math.sin(angle) * 0.3, 0
                    )
                    task.wait()
                end
            end)
        end
        
    elseif rarity == 8 then -- Immortal
        -- Reality distortion effect
        local distortion = Instance.new("Frame")
        distortion.Size = UDim2.new(1, 40, 1, 40)
        distortion.Position = UDim2.new(0.5, 0, 0.5, 0)
        distortion.AnchorPoint = Vector2.new(0.5, 0.5)
        distortion.BackgroundColor3 = RARITY_COLORS[8]
        distortion.BackgroundTransparency = 0.9
        distortion.ZIndex = -2
        distortion.Parent = card
        
        self._utilities.CreateCorner(distortion, 20)
        
        -- Glitch effect
        task.spawn(function()
            while distortion.Parent do
                distortion.Position = UDim2.new(
                    0.5 + (math.random() - 0.5) * 0.02, 0,
                    0.5 + (math.random() - 0.5) * 0.02, 0
                )
                distortion.BackgroundColor3 = Color3.fromRGB(
                    math.random(200, 255),
                    math.random(0, 100),
                    math.random(200, 255)
                )
                task.wait(0.1)
            end
        end)
    end
end

function InventoryUI:AddVariantEffect(card, variant)
    local effect = VARIANT_EFFECTS[variant]
    if not effect then return end
    
    if variant == "SHINY" then
        -- Sparkle particles
        for i = 1, 5 do
            local sparkle = Instance.new("ImageLabel")
            sparkle.Size = UDim2.new(0, 10, 0, 10)
            sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
            sparkle.BackgroundTransparency = 1
            sparkle.Image = "rbxassetid://6034684949"
            sparkle.ImageColor3 = Color3.new(1, 1, 1)
            sparkle.Parent = card
            
            -- Twinkle animation
            task.spawn(function()
                while sparkle.Parent do
                    sparkle.ImageTransparency = math.random() * 0.5
                    task.wait(math.random() * 0.5 + 0.2)
                end
            end)
        end
        
    elseif variant == "GOLDEN" then
        -- Golden shine sweep
        local shine = Instance.new("Frame")
        shine.Size = UDim2.new(0, 5, 2, 0)
        shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
        shine.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        shine.BackgroundTransparency = 0.7
        shine.Rotation = 45
        shine.Parent = card
        
        -- Sweep animation
        local sweep = self._utilities.Tween(shine, {
            Position = UDim2.new(1.5, 0, 1.5, 0)
        }, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
        
        self._janitor:Add(sweep)
        
    elseif variant == "RAINBOW" then
        -- Rainbow gradient animation
        local rainbow = Instance.new("UIGradient")
        rainbow.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238))
        })
        rainbow.Parent = card
        
        -- Rotation animation
        task.spawn(function()
            while rainbow.Parent do
                rainbow.Rotation = (rainbow.Rotation + 1) % 360
                task.wait()
            end
        end)
        
    elseif variant == "COSMIC" then
        -- Galaxy effect
        local galaxy = Instance.new("ImageLabel")
        galaxy.Size = UDim2.new(1, 0, 1, 0)
        galaxy.BackgroundTransparency = 1
        galaxy.Image = "rbxassetid://6034684948" -- Galaxy texture
        galaxy.ImageTransparency = 0.7
        galaxy.ZIndex = -1
        galaxy.Parent = card
        
        -- Rotation
        task.spawn(function()
            while galaxy.Parent do
                galaxy.Rotation = galaxy.Rotation + 0.1
                task.wait()
            end
        end)
        
    elseif variant == "VOID" then
        -- Black hole effect
        local void = Instance.new("ImageLabel")
        void.Size = UDim2.new(1.5, 0, 1.5, 0)
        void.Position = UDim2.new(0.5, 0, 0.5, 0)
        void.AnchorPoint = Vector2.new(0.5, 0.5)
        void.BackgroundTransparency = 1
        void.Image = "rbxassetid://6034684947" -- Void spiral
        void.ImageColor3 = Color3.new(0, 0, 0)
        void.ImageTransparency = 0.5
        void.ZIndex = -2
        void.Parent = card
        
        -- Spiral animation
        task.spawn(function()
            while void.Parent do
                void.Rotation = void.Rotation - 1
                void.Size = UDim2.new(
                    1.5 + math.sin(tick()) * 0.1, 0,
                    1.5 + math.sin(tick()) * 0.1, 0
                )
                task.wait()
            end
        end)
    end
end

-- ========================================
-- FILTERING AND SORTING
-- ========================================

function InventoryUI:ApplyFilters()
    self.FilteredPets = {}
    
    for _, petInstance in ipairs(self.AllPets) do
        local petData = PetDatabase:GetPet(petInstance.petId)
        if petData and self:PassesFilters(petInstance, petData) then
            table.insert(self.FilteredPets, {
                instance = petInstance,
                data = petData
            })
        end
    end
    
    -- Apply sorting
    self:SortPets()
    
    -- Update display
    self:RefreshPetGrid()
    
    -- Update stats
    self:UpdateCollectionStats()
end

function InventoryUI:PassesFilters(petInstance, petData)
    -- Search filter
    if self.SearchText and self.SearchText ~= "" then
        local searchLower = string.lower(self.SearchText)
        local nameLower = string.lower(petData.name or "")
        local displayNameLower = string.lower(petData.displayName or "")
        local nicknameLower = string.lower(petInstance.nickname or "")
        
        if not (string.find(nameLower, searchLower) or 
                string.find(displayNameLower, searchLower) or
                string.find(nicknameLower, searchLower)) then
            return false
        end
    end
    
    -- Category filters
    for categoryName, filters in pairs(self.ActiveFilters) do
        local hasActiveFilter = false
        local passesFilter = false
        
        for filterName, isActive in pairs(filters) do
            if isActive then
                hasActiveFilter = true
                
                -- Check each filter type
                if categoryName == "Status" then
                    if filterName == "Equipped" and petInstance.equipped then
                        passesFilter = true
                    elseif filterName == "Locked" and petInstance.locked then
                        passesFilter = true
                    elseif filterName == "Favorite" and petInstance.favorite then
                        passesFilter = true
                    end
                    
                elseif categoryName == "Rarity" then
                    if RARITY_NAMES[petData.rarity] == string.upper(filterName) then
                        passesFilter = true
                    end
                    
                elseif categoryName == "Variant" then
                    if (petInstance.variant or "NORMAL") == string.upper(filterName) then
                        passesFilter = true
                    end
                    
                elseif categoryName == "Special" then
                    if filterName == "Limited" and petData.limitedEdition then
                        passesFilter = true
                    elseif filterName == "Event" and petData.eventExclusive then
                        passesFilter = true
                    elseif filterName == "Secret" and petData.secret then
                        passesFilter = true
                    elseif filterName == "Fusion" and petData.fusionPet then
                        passesFilter = true
                    elseif filterName == "Awakened" and petData.awakened then
                        passesFilter = true
                    elseif filterName == "Corrupted" and petData.corrupted then
                        passesFilter = true
                    elseif filterName == "Glitched" and petData.glitched then
                        passesFilter = true
                    end
                    
                elseif categoryName == "Series" then
                    if string.find(string.lower(petData.name), string.lower(filterName)) then
                        passesFilter = true
                    end
                end
            end
        end
        
        if hasActiveFilter and not passesFilter then
            return false
        end
    end
    
    return true
end

function InventoryUI:SortPets()
    table.sort(self.FilteredPets, function(a, b)
        if self.CurrentSort == "Power" then
            local powerA = self:CalculatePetPower(a.instance, a.data)
            local powerB = self:CalculatePetPower(b.instance, b.data)
            return powerA > powerB
            
        elseif self.CurrentSort == "Rarity" then
            if a.data.rarity ~= b.data.rarity then
                return a.data.rarity > b.data.rarity
            end
            return (a.instance.level or 1) > (b.instance.level or 1)
            
        elseif self.CurrentSort == "Level" then
            return (a.instance.level or 1) > (b.instance.level or 1)
            
        elseif self.CurrentSort == "Recent" then
            return (a.instance.obtained or 0) > (b.instance.obtained or 0)
            
        elseif self.CurrentSort == "Name" then
            local nameA = a.instance.nickname or a.data.displayName or a.data.name
            local nameB = b.instance.nickname or b.data.displayName or b.data.name
            return nameA < nameB
            
        elseif self.CurrentSort == "Variant" then
            local variantA = a.instance.variant or "NORMAL"
            local variantB = b.instance.variant or "NORMAL"
            return variantA > variantB
            
        elseif self.CurrentSort == "Series" then
            return a.data.name < b.data.name
        end
        
        return false
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function InventoryUI:CalculatePetPower(petInstance, petData)
    local basePower = 0
    
    -- Base stats calculation
    if petData.baseStats then
        basePower = petData.baseStats.attack + petData.baseStats.defense + (petData.baseStats.health / 10)
    end
    
    -- Level multiplier
    local level = petInstance.level or 1
    basePower = basePower * (1 + (level - 1) * 0.1)
    
    -- Rarity multiplier
    basePower = basePower * petData.rarity
    
    -- Variant multiplier
    local variant = petInstance.variant or "NORMAL"
    local variantData = PetDatabase.VARIANTS[variant]
    if variantData then
        basePower = basePower * variantData.multiplier
    end
    
    return math.floor(basePower)
end

function InventoryUI:FormatNumber(num)
    if num >= 1e12 then
        return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.2fK", num / 1e3)
    else
        return tostring(math.floor(num))
    end
end

function InventoryUI:OnPetCardClicked(petInstance, petData)
    -- Epic click effect
    self._soundSystem:PlayUISound("EpicClick")
    
    -- Open pet details with all the epic data
    self._eventBus:Fire("ShowPetDetails", {
        petInstance = petInstance,
        petData = petData
    })
end

-- ========================================
-- CLEANUP
-- ========================================

function InventoryUI:Destroy()
    if self._janitor then
        self._janitor:Cleanup()
        self._janitor = nil
    end
end

return InventoryUI