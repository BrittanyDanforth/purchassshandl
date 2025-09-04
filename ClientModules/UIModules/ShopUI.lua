--[[
    Module: ShopUI
    Description: Shop interface with egg shop, gamepass shop, and currency shop tabs
    Features: Tab system, purchase confirmations, loading states, grid layouts
    Note: Case opening is handled by a separate CaseOpeningUI module
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Janitor = require(game.ReplicatedStorage.Modules.Shared.Janitor)

local ShopUI = {}
ShopUI.__index = ShopUI

-- ========================================
-- TYPES
-- ========================================

type EggData = {
    id: string,
    name: string,
    displayName: string,
    icon: string,
    price: number,
    currency: string,
    rarities: {[string]: number}?,
    description: string?,
    maxAmount: number?,
}

type GamepassData = {
    id: number,
    name: string,
    displayName: string,
    icon: string,
    price: number,
    description: string,
    owned: boolean?,
}

type CurrencyPackage = {
    id: number,
    amount: number,
    price: number,
    bonus: number?,
    currency: string,
}

type ShopTab = {
    name: string,
    icon: string?,
    content: Frame?,
    initialized: boolean,
}

-- ========================================
-- CONSTANTS
-- ========================================

local FRAME_SIZE = UDim2.new(1, -20, 1, -90)
local FRAME_POSITION = UDim2.new(0, 10, 0, 80)
local HEADER_HEIGHT = 80
local TAB_HEIGHT = 50
local CARD_PADDING = 15
local EGG_CARD_SIZE = Vector2.new(240, 300)
local GAMEPASS_CARD_HEIGHT = 120
local CURRENCY_CARD_SIZE = Vector2.new(220, 280)
local LOADING_TEXT = "Loading..."
local MAX_MULTI_OPEN = 10

-- Default shop tabs
local DEFAULT_TABS = {
    {name = "Eggs", icon = "🥚"},
    {name = "Gamepasses", icon = "⭐"},
    {name = "Currency", icon = "💎"},
}

-- Default currency packages
local DEFAULT_CURRENCY_PACKAGES = {
    {id = 123499, amount = 100, price = 99, bonus = 0, currency = "Gems"},
    {id = 123500, amount = 500, price = 499, bonus = 10, currency = "Gems"},
    {id = 123501, amount = 1000, price = 999, bonus = 20, currency = "Gems"},
    {id = 123502, amount = 5000, price = 4999, bonus = 30, currency = "Gems"},
    {id = 123503, amount = 10000, price = 9999, bonus = 50, currency = "Gems"},
}

-- ========================================
-- INITIALIZATION
-- ========================================

function ShopUI.new(dependencies)
    local self = setmetatable({}, ShopUI)
    
    -- Initialize Janitor for memory management
    self._janitor = Janitor.new()
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._remoteManager = dependencies.RemoteManager
    self._dataCache = dependencies.DataCache
    self._windowManager = dependencies.WindowManager
    self._notificationSystem = dependencies.NotificationSystem
    self._soundSystem = dependencies.SoundSystem
    self._uiFactory = dependencies.UIFactory
    self._animationSystem = dependencies.AnimationSystem
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self._header = nil
    self._tabContainer = nil
    self._tabs = {}
    self._currentTab = nil
    self._tabFrames = {}
    
    -- Data
    self._eggData = {}
    self._gamepassData = {}
    self._currencyPackages = DEFAULT_CURRENCY_PACKAGES
    
    -- State
    self._isOpen = false
    self._isLoading = false
    self._purchaseInProgress = false
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Cache
    self._eggScrollFrame = nil
    self._gamepassScrollFrame = nil
    self._currencyScrollFrame = nil
    
    return self
end

function ShopUI:Initialize(frame: Frame?, dependencies: table?)
    if dependencies then
        -- Update dependencies if provided
        for key, value in pairs(dependencies) do
            self["_" .. key] = value
        end
    end
    
    if self._debugMode then
        print("[ShopUI] Initialized")
    end
end

-- ========================================
-- SEARCH/FILTER
-- ========================================

function ShopUI:FilterEggs(searchText: string)
    searchText = searchText:lower()
    
    for _, child in ipairs(self._eggScrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^EggCard_") then
            local shouldShow = true
            
            if searchText ~= "" then
                local eggName = child:FindFirstChild("InfoSection")
                if eggName then
                    local nameLabel = eggName:FindFirstChildOfClass("TextLabel")
                    if nameLabel and nameLabel.Text then
                        shouldShow = nameLabel.Text:lower():find(searchText, 1, true) ~= nil
                    end
                end
            end
            
            child.Visible = shouldShow
            
            -- Animate visibility change
            if shouldShow then
                child.Size = UDim2.new(0, EGG_CARD_SIZE.X, 0, 0)
                self._utilities.Tween(child, {
                    Size = UDim2.new(0, EGG_CARD_SIZE.X, 0, EGG_CARD_SIZE.Y)
                }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            end
        end
    end
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function ShopUI:Open()
    if self._isOpen then
        if self.Frame then
            -- Smooth reopen animation
            self.Frame.Visible = true
            self.Frame.BackgroundTransparency = 1
            self._utilities.Tween(self.Frame, {
                BackgroundTransparency = 0
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end
        return
    end
    
    -- Create UI if not exists
    if not self.Frame then
        self:CreateUI()
    end
    
    -- Smooth entrance animation
    self.Frame.Visible = true
    self.Frame.BackgroundTransparency = 1
    local originalPosition = self.Frame.Position
    self.Frame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 100)
    
    -- Fade in and slide up
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 0,
        Position = originalPosition
    }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    self._isOpen = true
    
    -- Load shop data
    self:LoadShopData()
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("ShopOpened", {})
    end
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Open")
    end
end

function ShopUI:Close()
    if not self._isOpen or not self.Frame then return end
    
    -- Smooth exit animation
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 1,
        Position = UDim2.new(self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, 1, 100)
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
    
    task.wait(0.3)
    self.Frame.Visible = false
    self._isOpen = false
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("ShopClosed", {})
    end
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Close")
    end
end

-- ========================================
-- WINDOW MANAGER INTEGRATION
-- ========================================

function ShopUI:Initialize()
    -- This function just builds the UI but doesn't show it
    if not self.Frame then
        self:CreateUI()
    end
end

function ShopUI:AnimateOpen()
    -- Called by WindowManager to play the open animation
    if not self.Frame then self:Initialize() end
    
    self.Frame.Visible = true
    self.Frame.BackgroundTransparency = 1
    
    -- Animate in
    local originalPosition = self.Frame.Position or UDim2.new(0.5, 0, 0.5, 0)
    self.Frame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 100)
    
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 0,
        Position = originalPosition
    }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    self._isOpen = true
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Open")
    end
end

function ShopUI:AnimateClose()
    -- Called by WindowManager to play the close animation
    if not self.Frame then return end
    
    -- Animate out
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 1,
        Position = UDim2.new(self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, 1, 100)
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
    
    -- Note: We don't wait here, WindowManager handles the timing
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Close")
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("ShopClosed", {})
    end
end

function ShopUI:OnReady()
    -- Called by WindowManager AFTER the open animation is finished
    -- This is the safe place to load data!
    self:LoadShopData()
end

function ShopUI:OnClosed()
    -- Called by WindowManager after close animation completes
    self.Frame.Visible = false
    self._isOpen = false
end

-- ========================================
-- UI CREATION
-- ========================================

function ShopUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                  Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[ShopUI] No parent container found")
        return
    end
    
    -- Main frame
    self.Frame = Instance.new("Frame")
    self.Frame.Name = "ShopFrame"
    self.Frame.Size = FRAME_SIZE
    self.Frame.Position = FRAME_POSITION
    self.Frame.BackgroundColor3 = self._config.COLORS.White
    self.Frame.BorderSizePixel = 0
    self.Frame.Visible = false
    self.Frame.Parent = parent
    
    self._utilities.CreateCorner(self.Frame, 12)
    
    -- Create header
    self:CreateHeader()
    
    -- Create tabs
    self:CreateTabs()
end

function ShopUI:CreateHeader()
    self._header = Instance.new("Frame")
    self._header.Name = "Header"
    self._header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    self._header.BackgroundColor3 = self._config.COLORS.Primary
    self._header.BorderSizePixel = 0
    self._header.Parent = self.Frame
    
    self._utilities.CreateCorner(self._header, 12)
    
    -- Add gradient to header
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.95, 0.95, 0.95))
    })
    headerGradient.Rotation = 90
    headerGradient.Parent = self._header
    
    -- Title section (left side)
    local titleContainer = Instance.new("Frame")
    titleContainer.Name = "TitleContainer"
    titleContainer.Size = UDim2.new(0.3, -10, 1, 0)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = self._header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✨ SHOP"
    title.TextColor3 = self._config.COLORS.White
    title.Font = self._config.FONTS.Display
    title.TextScaled = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleContainer
    
    local titleConstraint = Instance.new("UITextSizeConstraint")
    titleConstraint.MaxTextSize = 28
    titleConstraint.MinTextSize = 20
    titleConstraint.Parent = title
    
    -- Search section (middle)
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0.4, -20, 0, 40)
    searchContainer.Position = UDim2.new(0.3, 10, 0.5, -20)
    searchContainer.BackgroundColor3 = Color3.new(1, 1, 1)
    searchContainer.BackgroundTransparency = 0.9
    searchContainer.Parent = self._header
    
    self._utilities.CreateCorner(searchContainer, 20)
    
    -- Search icon
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 40, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = self._config.COLORS.White
    searchIcon.TextScaled = true
    searchIcon.Parent = searchContainer
    
    -- Search input
    self._searchBox = Instance.new("TextBox")
    self._searchBox.Name = "SearchBox"
    self._searchBox.Size = UDim2.new(1, -80, 1, 0)
    self._searchBox.Position = UDim2.new(0, 40, 0, 0)
    self._searchBox.BackgroundTransparency = 1
    self._searchBox.Text = ""
    self._searchBox.PlaceholderText = "Search items..."
    self._searchBox.TextColor3 = self._config.COLORS.White
    self._searchBox.PlaceholderColor3 = Color3.new(0.9, 0.9, 0.9)
    self._searchBox.Font = self._config.FONTS.Primary
    self._searchBox.TextScaled = true
    self._searchBox.Parent = searchContainer
    
    local searchConstraint = Instance.new("UITextSizeConstraint")
    searchConstraint.MaxTextSize = 18
    searchConstraint.MinTextSize = 14
    searchConstraint.Parent = self._searchBox
    
    -- Clear button (hidden by default)
    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearButton"
    clearButton.Size = UDim2.new(0, 40, 1, 0)
    clearButton.Position = UDim2.new(1, -40, 0, 0)
    clearButton.BackgroundTransparency = 1
    clearButton.Text = "✖"
    clearButton.TextColor3 = self._config.COLORS.White
    clearButton.Font = self._config.FONTS.Primary
    clearButton.TextScaled = true
    clearButton.Visible = false
    clearButton.Parent = searchContainer
    
    -- Search functionality
    self._searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = self._searchBox.Text
        clearButton.Visible = searchText ~= ""
        
        if self._currentTab == "Eggs" then
            self:FilterEggs(searchText)
        end
    end)
    
    self._janitor:Add(clearButton.MouseButton1Click:Connect(function()
        self._searchBox.Text = ""
        if self._soundSystem then
            self._soundSystem:PlayUISound("Click")
        end
    end))
    
    -- Filters section (right side)
    local filtersContainer = Instance.new("Frame")
    filtersContainer.Name = "FiltersContainer"
    filtersContainer.Size = UDim2.new(0.3, -10, 1, 0)
    filtersContainer.Position = UDim2.new(0.7, 0, 0, 0)
    filtersContainer.BackgroundTransparency = 1
    filtersContainer.Parent = self._header
    
    -- Layout for filter buttons
    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    filterLayout.Padding = UDim.new(0, 8)
    filterLayout.Parent = filtersContainer
    
    -- Sort dropdown
    local sortButton = Instance.new("TextButton")
    sortButton.Name = "SortButton"
    sortButton.Size = UDim2.new(0, 100, 0, 32)
    sortButton.BackgroundColor3 = Color3.new(1, 1, 1)
    sortButton.BackgroundTransparency = 0.9
    sortButton.Text = "Sort: Price ▼"
    sortButton.TextColor3 = self._config.COLORS.White
    sortButton.Font = self._config.FONTS.Primary
    sortButton.TextScaled = true
    sortButton.Parent = filtersContainer
    
    self._utilities.CreateCorner(sortButton, 16)
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(self._header, {
        name = "CloseButton",
        text = "×",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0.5, -20),
        backgroundColor = self._config.COLORS.White,
        textColor = self._config.COLORS.Primary,
        font = self._config.FONTS.Display,
        callback = function()
            self:Close()
        end
    })
end

function ShopUI:CreateTabs()
    -- Tab container
    self._tabContainer = Instance.new("Frame")
    self._tabContainer.Name = "TabContainer"
    self._tabContainer.Size = UDim2.new(1, -20, 1, -HEADER_HEIGHT - 20)
    self._tabContainer.Position = UDim2.new(0, 10, 0, HEADER_HEIGHT + 10)
    self._tabContainer.BackgroundTransparency = 1
    self._tabContainer.Parent = self.Frame
    
    -- Tab buttons
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
    tabButtons.BackgroundColor3 = self._config.COLORS.Surface
    tabButtons.BorderSizePixel = 0
    tabButtons.Parent = self._tabContainer
    
    self._utilities.CreateCorner(tabButtons, 8)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabButtons
    
    -- Tab content
    local tabContent = Instance.new("Frame")
    tabContent.Name = "TabContent"
    tabContent.Size = UDim2.new(1, 0, 1, -TAB_HEIGHT - 10)
    tabContent.Position = UDim2.new(0, 0, 0, TAB_HEIGHT + 10)
    tabContent.BackgroundTransparency = 1
    tabContent.Parent = self._tabContainer
    
    -- Create tab buttons and frames
    for i, tabData in ipairs(DEFAULT_TABS) do
        self:CreateTab(tabData, tabButtons, tabContent, i)
    end
    
    -- Select first tab
    self:SelectTab(DEFAULT_TABS[1].name)
end

function ShopUI:CreateTab(tabData: {name: string, icon: string?}, tabButtons: Frame, tabContent: Frame, order: number)
    -- Tab button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = tabData.name .. "TabContainer"
    buttonContainer.Size = UDim2.new(1/#DEFAULT_TABS, -5, 1, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = tabButtons
    
    -- Tab button
    local tabButton = self._uiFactory:CreateButton(buttonContainer, {
        name = tabData.name .. "Tab",
        text = (tabData.icon or "") .. " " .. tabData.name,
        size = UDim2.new(1, 0, 1, -4),
        backgroundColor = self._config.COLORS.White,
        textColor = order == 1 and self._config.COLORS.Primary or self._config.COLORS.Dark,
        font = self._config.FONTS.Secondary,
        callback = function()
            self:SelectTab(tabData.name)
        end
    })
    
    -- Remove corner radius for cleaner look
    local corner = tabButton:FindFirstChild("UICorner")
    if corner then corner:Destroy() end
    
    -- Add underline indicator
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(order == 1 and 1 or 0, 0, 0, 3)
    underline.Position = UDim2.new(0.5, 0, 1, -3)
    underline.AnchorPoint = Vector2.new(0.5, 0)
    underline.BackgroundColor3 = self._config.COLORS.Primary
    underline.BorderSizePixel = 0
    underline.Parent = buttonContainer
    
    -- Tab frame
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = tabData.name .. "Content"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = order == 1
    tabFrame.Parent = tabContent
    
    -- Store references
    self._tabs[tabData.name] = {
        button = tabButton,
        frame = tabFrame,
        underline = underline,
        container = buttonContainer,
        initialized = false
    }
    self._tabFrames[tabData.name] = tabFrame
end

function ShopUI:SelectTab(tabName: string)
    if self._currentTab == tabName then return end
    
    local currentTab = self._tabs[self._currentTab]
    local targetTab = self._tabs[tabName]
    
    -- Update button states with animations
    for name, tab in pairs(self._tabs) do
        if name == tabName then
            -- Active button animation
            self._utilities.Tween(tab.button, {
                TextColor3 = self._config.COLORS.Primary
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            -- Animate underline
            self._utilities.Tween(tab.underline, {
                Size = UDim2.new(1, 0, 0, 3)
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            -- Scale effect
            tab.button:TweenSize(
                UDim2.new(tab.button.Size.X.Scale, tab.button.Size.X.Offset, 1, -4),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Back,
                0.2,
                true
            )
        else
            -- Inactive button animation
            self._utilities.Tween(tab.button, {
                TextColor3 = self._config.COLORS.Dark
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            -- Hide underline
            self._utilities.Tween(tab.underline, {
                Size = UDim2.new(0, 0, 0, 3)
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            -- Reset scale
            tab.button:TweenSize(
                UDim2.new(tab.button.Size.X.Scale, tab.button.Size.X.Offset, 1, -4),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
        end
    end
    
    -- Hide all tab frames first
    for name, tab in pairs(self._tabs) do
        if tab.frame and name ~= tabName then
            tab.frame.Visible = false
        end
    end
    
    -- Clear any existing content if needed
    if currentTab and currentTab.frame then
        -- Fade out current tab
        self._utilities.Tween(currentTab.frame, {
            BackgroundTransparency = 1
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        
        task.wait(0.2)
        currentTab.frame.Visible = false
        currentTab.frame.BackgroundTransparency = 0
    end
    
    -- Initialize tab if needed
    if not self._tabs[tabName].initialized then
        self:InitializeTab(tabName)
        self._tabs[tabName].initialized = true
    end
    
    -- Show new tab with animation
    if targetTab and targetTab.frame then
        targetTab.frame.Visible = true
        targetTab.frame.BackgroundTransparency = 1
        targetTab.frame.Position = UDim2.new(1.5, 0, 0, 0)
        
        -- Slide in
        self._utilities.Tween(targetTab.frame, {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0
        }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    end
    
    self._currentTab = tabName
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
end

function ShopUI:InitializeTab(tabName: string)
    local tab = self._tabs[tabName]
    if not tab then return end
    
    if tabName == "Eggs" then
        self:CreateEggShop(tab.frame)
    elseif tabName == "Gamepasses" then
        self:CreateGamepassShop(tab.frame)
    elseif tabName == "Currency" then
        self:CreateCurrencyShop(tab.frame)
    end
end

-- ========================================
-- EGG SHOP
-- ========================================

function ShopUI:CreateEggShop(parent: Frame)
    -- Clear previous content
    if self._eggScrollFrame and self._eggScrollFrame.Parent then
        self._eggScrollFrame:Destroy()
    end
    
    -- Create container
    local container = Instance.new("Frame")
    container.Name = "EggShopContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Loading indicator
    local loadingLabel = self._uiFactory:CreateLabel(container, {
        text = LOADING_TEXT,
        size = UDim2.new(1, 0, 0, 50),
        position = UDim2.new(0, 0, 0.5, -25),
        textColor = self._config.COLORS.TextSecondary,
        font = self._config.FONTS.Primary
    })
    
    -- Fetch egg data
    spawn(function()
        wait(0.1) -- Small delay for UI to render
        
        local success, eggData = pcall(function()
            if self._remoteManager then
                return self._remoteManager:InvokeFunction("GetShopData", "eggs")
            else
                -- Fallback
                return RemoteFunctions.GetShopData and 
                       RemoteFunctions.GetShopData:InvokeServer("eggs")
            end
        end)
        
        if success and eggData then
            self._eggData = eggData
            loadingLabel:Destroy()
            self:PopulateEggShop(container)
        else
            -- Use default egg data if server data not available
            self._eggData = self._config.DEFAULT_EGGS or {
                {
                    id = "starter_egg",
                    name = "Starter Egg",
                    price = 100,
                    currency = "coins",
                    icon = "rbxassetid://12345678",
                    rarity = "common"
                },
                {
                    id = "rare_egg", 
                    name = "Rare Egg",
                    price = 1000,
                    currency = "coins",
                    icon = "rbxassetid://12345678",
                    rarity = "rare"
                },
                {
                    id = "epic_egg",
                    name = "Epic Egg", 
                    price = 50,
                    currency = "gems",
                    icon = "rbxassetid://12345678",
                    rarity = "epic"
                }
            }
            loadingLabel:Destroy()
            self:PopulateEggShop(container)
            if self._debugMode then
                warn("[ShopUI] Using default egg data - server data not available")
            end
        end
    end)
end

function ShopUI:PopulateEggShop(container: Frame)
    -- Create scrolling frame with momentum
    self._eggScrollFrame = self:CreateEnhancedScrollingFrame(container, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, CARD_PADDING, 0, CARD_PADDING)
    gridLayout.CellSize = UDim2.new(0, EGG_CARD_SIZE.X, 0, EGG_CARD_SIZE.Y)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = self._eggScrollFrame
    
    -- Add padding
    self._utilities.CreatePadding(self._eggScrollFrame, 20)
    
    -- Lazy load egg cards with fade-in
    local visibleCards = {}
    local cardQueue = {}
    
    for i, eggData in ipairs(self._eggData) do
        table.insert(cardQueue, {data = eggData, order = i})
    end
    
    -- Load cards in batches for performance
    local function loadNextBatch()
        local batchSize = 6
        local loaded = 0
        
        while loaded < batchSize and #cardQueue > 0 do
            local item = table.remove(cardQueue, 1)
            local card = self:CreateEggCard(self._eggScrollFrame, item.data)
            
            if card then
                card.LayoutOrder = item.order
                card.BackgroundTransparency = 1
                
                -- Set initial position for slide-up effect
                local originalPos = card.Position
                card.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, 
                                         originalPos.Y.Scale, originalPos.Y.Offset + 20)
                
                -- Staggered entrance animation
                task.wait(loaded * 0.05)
                
                -- Fade and slide in animation
                self._utilities.Tween(card, {
                    BackgroundTransparency = 0,
                    Position = originalPos
                }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
                
                table.insert(visibleCards, card)
            end
            
            loaded = loaded + 1
        end
        
        -- Update canvas size
        task.defer(function()
            self._eggScrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
        end)
        
        -- Load next batch if more items
        if #cardQueue > 0 then
            task.wait(0.1)
            loadNextBatch()
        end
    end
    
    -- Start loading
    loadNextBatch()
end

function ShopUI:CreateEnhancedScrollingFrame(parent: Frame, config: table)
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, config)
    
    -- Enable elastic behavior
    scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageTransparency = 0.5
    
    -- Add momentum scrolling
    local lastScrollPosition = scrollFrame.CanvasPosition
    local velocity = Vector2.new(0, 0)
    local scrollConnection = nil
    local isScrolling = false
    local damping = 0.94
    
    scrollConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not isScrolling and velocity.Magnitude > 0.1 then
            -- Apply momentum
            local newPosition = scrollFrame.CanvasPosition + velocity
            
            -- Clamp to bounds
            local maxY = math.max(0, scrollFrame.AbsoluteCanvasSize.Y - scrollFrame.AbsoluteSize.Y)
            newPosition = Vector2.new(
                0,
                math.clamp(newPosition.Y, 0, maxY)
            )
            
            scrollFrame.CanvasPosition = newPosition
            
            -- Apply damping
            velocity = velocity * damping
            
            -- Stop if velocity is too small
            if velocity.Magnitude < 0.1 then
                velocity = Vector2.new(0, 0)
            end
        end
        
        lastScrollPosition = scrollFrame.CanvasPosition
    end)
    
    -- Track scrolling
    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if isScrolling then
            local delta = scrollFrame.CanvasPosition - lastScrollPosition
            velocity = delta * 0.5 -- Adjust sensitivity
        end
    end)
    
    -- Detect scroll start/end
    scrollFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isScrolling = true
            velocity = Vector2.new(0, 0)
        end
    end)
    
    scrollFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isScrolling = false
        end
    end)
    
    -- Mouse wheel support
    scrollFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            velocity = Vector2.new(0, -input.Position.Z * 50)
        end
    end)
    
    -- Scrollbar fade on hover
    local scrollBarBg = scrollFrame:FindFirstChild("ScrollBarBackground")
    if scrollBarBg then
        self._janitor:Add(scrollFrame.MouseEnter:Connect(function()
            self._utilities.Tween(scrollFrame, {
                ScrollBarImageTransparency = 0.2
            }, TweenInfo.new(0.2))
        end))
        
        self._janitor:Add(scrollFrame.MouseLeave:Connect(function()
            self._utilities.Tween(scrollFrame, {
                ScrollBarImageTransparency = 0.5
            }, TweenInfo.new(0.2))
        end))
    end
    
    -- Store connection for cleanup
    scrollFrame.AncestryChanged:Connect(function()
        if not scrollFrame.Parent and scrollConnection then
            scrollConnection:Disconnect()
        end
    end)
    
    return scrollFrame
end

function ShopUI:CreateEggCard(parent: Frame, eggData: EggData): Frame?
    if not eggData or not eggData.id then return nil end
    
    local card = Instance.new("Frame")
    card.Name = "EggCard_" .. eggData.id
    card.BackgroundColor3 = Color3.new(1, 1, 1) -- Pure white
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 16) -- Larger corner radius
    
    -- Add subtle border
    local border = Instance.new("UIStroke")
    border.Color = self._config.COLORS.Primary
    border.Transparency = 0.95
    border.Thickness = 1
    border.Parent = card
    
    -- Gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.98, 0.98, 0.98))
    })
    gradient.Rotation = 90
    gradient.Parent = card
    
    -- Top section with image
    local imageContainer = Instance.new("Frame")
    imageContainer.Name = "ImageContainer"
    imageContainer.Size = UDim2.new(1, 0, 0.6, 0)
    imageContainer.BackgroundTransparency = 1
    imageContainer.ZIndex = 2
    imageContainer.Parent = card
    
    -- Egg image
    local eggImage = Instance.new("ImageLabel")
    eggImage.Name = "EggImage"
    eggImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    eggImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    eggImage.AnchorPoint = Vector2.new(0.5, 0.5)
    eggImage.BackgroundTransparency = 1
    eggImage.Image = eggData.icon or ""
    eggImage.ScaleType = Enum.ScaleType.Fit
    eggImage.Parent = imageContainer
    
    -- Info section
    local infoSection = Instance.new("Frame")
    infoSection.Name = "InfoSection"
    infoSection.Size = UDim2.new(1, 0, 0.4, 0)
    infoSection.Position = UDim2.new(0, 0, 0.6, 0)
    infoSection.BackgroundTransparency = 1
    infoSection.ZIndex = 2
    infoSection.Parent = card
    
    -- Egg name
    local nameLabel = self._uiFactory:CreateLabel(infoSection, {
        text = eggData.displayName or eggData.name,
        size = UDim2.new(1, -20, 0, 24),
        position = UDim2.new(0, 10, 0, 5),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.Text,
        textSize = 18
    })
    
    -- Price container
    local priceContainer = Instance.new("Frame")
    priceContainer.Size = UDim2.new(1, -20, 0, 32)
    priceContainer.Position = UDim2.new(0, 10, 0, 35)
    priceContainer.BackgroundColor3 = self._config.COLORS.Primary
    priceContainer.BackgroundTransparency = 0.95
    priceContainer.Parent = infoSection
    
    self._utilities.CreateCorner(priceContainer, 8)
    
    -- Currency icon
    local currencyIcon = Instance.new("ImageLabel")
    currencyIcon.Size = UDim2.new(0, 24, 0, 24)
    currencyIcon.Position = UDim2.new(0, 8, 0.5, -12)
    currencyIcon.BackgroundTransparency = 1
    currencyIcon.Image = self:GetCurrencyIcon(eggData.currency)
    currencyIcon.Parent = priceContainer
    
    -- Price label
    local priceLabel = self._uiFactory:CreateLabel(priceContainer, {
        text = self._utilities.FormatNumber(eggData.price),
        size = UDim2.new(1, -40, 1, 0),
        position = UDim2.new(0, 35, 0, 0),
        font = self._config.FONTS.Numbers,
        textSize = 20,
        textColor = self._config.COLORS.Text
    })
    
    -- Buy button
    local buyButton = self._uiFactory:CreateButton(infoSection, {
        text = "OPEN",
        size = UDim2.new(1, -20, 0, 36),
        position = UDim2.new(0, 10, 1, -45),
        backgroundColor = self._config.COLORS.Primary,
        font = self._config.FONTS.Primary,
        textSize = 16,
        callback = function()
            self:ShowEggPurchaseDialog(eggData)
        end
    })
    
    -- Add gradient to button
    local buttonGradient = Instance.new("UIGradient")
    buttonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.9, 0.9))
    })
    buttonGradient.Rotation = 90
    buttonGradient.Parent = buyButton
    
    -- Add button stroke for depth
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = self._config.COLORS.Primary
    buttonStroke.Transparency = 0.8
    buttonStroke.Thickness = 1
    buttonStroke.Parent = buyButton
    
    -- Button hover effects
    local originalButtonSize = buyButton.Size
    self._janitor:Add(buyButton.MouseEnter:Connect(function()
        -- Scale animation
        self._utilities.Tween(buyButton, {
            Size = UDim2.new(1, -16, 0, 40)
        }, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        
        -- Gradient animation
        self._utilities.Tween(buttonGradient, {
            Rotation = 270
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
        
        -- Stroke glow
        self._utilities.Tween(buttonStroke, {
            Transparency = 0.4,
            Thickness = 2
        }, TweenInfo.new(0.2))
    end))
    
    self._janitor:Add(buyButton.MouseLeave:Connect(function()
        -- Reset scale
        self._utilities.Tween(buyButton, {
            Size = originalButtonSize
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
        
        -- Reset gradient
        self._utilities.Tween(buttonGradient, {
            Rotation = 90
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
        
        -- Reset stroke
        self._utilities.Tween(buttonStroke, {
            Transparency = 0.8,
            Thickness = 1
        }, TweenInfo.new(0.2))
    end))
    
    -- Premium hover effects
    local originalBorderTransparency = border.Transparency
    
    -- Add holographic effect for rare items (if rarity data exists)
    if eggData.rarity and eggData.rarity >= 4 then
        local holo = Instance.new("Frame")
        holo.Name = "HolographicEffect"
        holo.Size = UDim2.new(1, -4, 1, -4)
        holo.Position = UDim2.new(0, 2, 0, 2)
        holo.BackgroundTransparency = 0.9
        holo.ZIndex = card.ZIndex + 10
        holo.Parent = card
        
        local holoGradient = Instance.new("UIGradient")
        holoGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255))
        })
        holoGradient.Rotation = 45
        holoGradient.Parent = holo
        
        self._utilities.CreateCorner(holo, 12)
        
        -- Animate holographic effect
        task.spawn(function()
            while holo.Parent do
                self._utilities.Tween(holoGradient, {
                    Rotation = holoGradient.Rotation + 360
                }, TweenInfo.new(4, Enum.EasingStyle.Linear))
                task.wait(4)
            end
        end)
    end
    

    
    self._janitor:Add(card.MouseEnter:Connect(function()
        -- Clean up any existing shadow first
        local shadowFrame = card:FindFirstChild("ShadowFrame")
        if shadowFrame then
            local existingShadow = shadowFrame:FindFirstChild("DropShadow")
            if existingShadow then
                existingShadow:Destroy()
            end
        end
        
        -- Scale up animation
        card:TweenSize(
            UDim2.new(0, EGG_CARD_SIZE.X * 1.05, 0, EGG_CARD_SIZE.Y * 1.05),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Back,
            0.25,
            true
        )
        
        -- Border glow
        self._utilities.Tween(border, {
            Transparency = 0.7,
            Thickness = 2
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
        
        -- Create shadow inside the card with proper layering
        local shadowFrame = card:FindFirstChild("ShadowFrame")
        if not shadowFrame then
            shadowFrame = Instance.new("Frame")
            shadowFrame.Name = "ShadowFrame"
            shadowFrame.Size = UDim2.new(1, 0, 1, 0)
            shadowFrame.BackgroundTransparency = 1
            shadowFrame.ZIndex = 0
            shadowFrame.Parent = card
        end
        
        -- Create the actual shadow (more subtle)
        local shadowContainer = Instance.new("Frame")
        shadowContainer.Name = "DropShadow"
        shadowContainer.Size = UDim2.new(1, 8, 1, 8)  -- Reduced from 20 to 8
        shadowContainer.Position = UDim2.new(0.5, 0, 0.5, 4)  -- Reduced offset from 10 to 4
        shadowContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        shadowContainer.BackgroundColor3 = Color3.new(0, 0, 0)
        shadowContainer.BackgroundTransparency = 0.9  -- More transparent (was 0.85)
        shadowContainer.ZIndex = -1
        shadowContainer.Parent = shadowFrame
        
        -- Add corner to shadow for rounded effect
        self._utilities.CreateCorner(shadowContainer, 20)
        
        -- Animate shadow appearance
        shadowContainer.BackgroundTransparency = 1
        self._utilities.Tween(shadowContainer, {
            BackgroundTransparency = 0.8  -- More subtle final transparency
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
        
        -- Store reference without using attribute
        card:SetAttribute("HasDropShadow", true)
        
        -- Scale egg image
        self._utilities.Tween(eggImage, {
            Size = UDim2.new(0.85, 0, 0.85, 0)
        }, TweenInfo.new(0.3, Enum.EasingStyle.Back))
        
        -- Add shine effect
        local shine = Instance.new("Frame")
        shine.Name = "ShineEffect"
        shine.Size = UDim2.new(0.3, 0, 2, 0)
        shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
        shine.BackgroundColor3 = Color3.new(1, 1, 1)
        shine.BackgroundTransparency = 0.8
        shine.BorderSizePixel = 0
        shine.ZIndex = card.ZIndex + 5
        shine.Parent = card
        
        local shineGradient = Instance.new("UIGradient")
        shineGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.4, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.6),
            NumberSequenceKeypoint.new(0.6, 0.8),
            NumberSequenceKeypoint.new(1, 1)
        })
        shineGradient.Rotation = 30
        shineGradient.Parent = shine
        
        -- Animate shine across card
        local shineTween = self._utilities.Tween(shine, {
            Position = UDim2.new(1.2, 0, -0.5, 0)
        }, TweenInfo.new(0.6, Enum.EasingStyle.Linear))
        
        shineTween.Completed:Connect(function()
            if shine and shine.Parent then
                shine:Destroy()
            end
        end)
        
        -- Sound effect
        if self._soundSystem then
            self._soundSystem:PlayUISound("Hover")
        end
    end))
    
    self._janitor:Add(card.MouseLeave:Connect(function()
        -- Scale back
        card:TweenSize(
            UDim2.new(0, EGG_CARD_SIZE.X, 0, EGG_CARD_SIZE.Y),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        
        -- Reset border
        self._utilities.Tween(border, {
            Transparency = originalBorderTransparency,
            Thickness = 1
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
        
        -- Remove drop shadow
        if card:GetAttribute("HasDropShadow") then
            local shadowFrame = card:FindFirstChild("ShadowFrame")
            if shadowFrame then
                local dropShadow = shadowFrame:FindFirstChild("DropShadow")
                if dropShadow then
                    -- Animate shadow disappearance
                    local shadowTween = self._utilities.Tween(dropShadow, {
                        BackgroundTransparency = 1
                    }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
                    
                    shadowTween.Completed:Connect(function()
                        if dropShadow and dropShadow.Parent then
                            dropShadow:Destroy()
                        end
                    end)
                end
            end
            card:SetAttribute("HasDropShadow", false)
        end
        
        -- Reset egg image
        self._utilities.Tween(eggImage, {
            Size = UDim2.new(0.8, 0, 0.8, 0)
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
    end))
    
    return card
end

function ShopUI:ShowEggPurchaseDialog(eggData: EggData)
    if self._purchaseInProgress then return end
    
    -- Create modal
    local modalId = self._windowManager:CreateWindow({
        title = "Open " .. (eggData.displayName or eggData.name) .. "?",
        size = Vector2.new(500, 400),
        modal = true,
        canClose = true,
        canMinimize = false,
        canResize = false,
    })
    
    local content = self._windowManager:GetWindowContent(modalId)
    if not content then return end
    
    -- Egg preview
    local eggPreview = Instance.new("ImageLabel")
    eggPreview.Size = UDim2.new(0, 100, 0, 100)
    eggPreview.Position = UDim2.new(0.5, -50, 0, 10)
    eggPreview.BackgroundTransparency = 1
    eggPreview.Image = eggData.icon or ""
    eggPreview.ScaleType = Enum.ScaleType.Fit
    eggPreview.Parent = content
    
    -- Multi-open options
    local amountLabel = self._uiFactory:CreateLabel(content, {
        text = "Amount to open:",
        size = UDim2.new(1, -20, 0, 25),
        position = UDim2.new(0, 10, 0, 130),
        textColor = self._config.COLORS.Text,
        textSize = 18,
        font = self._config.FONTS.Secondary
    })
    
    -- Amount buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -20, 0, 50)
    buttonContainer.Position = UDim2.new(0, 10, 0, 165)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = content
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonContainer
    
    local amounts = {1, 3, 5, 10}
    local selectedAmount = 1
    local amountButtons = {}
    
    for _, amount in ipairs(amounts) do
        local btn = self._uiFactory:CreateButton(buttonContainer, {
            text = amount .. "x",
            size = UDim2.new(0, 80, 1, 0),
            backgroundColor = amount == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
            textColor = amount == 1 and self._config.COLORS.White or self._config.COLORS.Text,
            textSize = 18,
            font = self._config.FONTS.Bold,
            callback = function()
                selectedAmount = amount
                -- Update button states
                for amt, button in pairs(amountButtons) do
                    if amt == amount then
                        button.BackgroundColor3 = self._config.COLORS.Primary
                        button.TextColor3 = self._config.COLORS.White
                    else
                        button.BackgroundColor3 = self._config.COLORS.Surface
                        button.TextColor3 = self._config.COLORS.Text
                    end
                end
            end
        })
        amountButtons[amount] = btn
    end
    
    -- Total cost
    local totalCostLabel = self._uiFactory:CreateLabel(content, {
        text = "Total: " .. self._utilities.FormatNumber(eggData.price),
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0, 235),
        font = self._config.FONTS.Bold,
        textSize = 20,
        textColor = self._config.COLORS.Text
    })
    
    -- Update total cost when amount changes
    spawn(function()
        while content.Parent do
            totalCostLabel.Text = "Total: " .. self._utilities.FormatNumber(eggData.price * selectedAmount) .. 
                                " " .. eggData.currency
            wait(0.1)
        end
    end)
    
    -- Confirm button
    local confirmButton = self._uiFactory:CreateButton(content, {
        text = "Confirm Purchase",
        size = UDim2.new(1, -20, 0, 50),
        position = UDim2.new(0, 10, 1, -70),
        backgroundColor = self._config.COLORS.Success,
        textSize = 18,
        font = self._config.FONTS.Bold,
        callback = function()
            self._windowManager:CloseWindow(modalId)
            self:PurchaseEgg(eggData, selectedAmount)
        end
    })
end

function ShopUI:PurchaseEgg(eggData: EggData, amount: number)
    if self._purchaseInProgress then return end
    
    self._purchaseInProgress = true
    
    -- Request egg opening from server FIRST
    local success, result = pcall(function()
        if self._remoteManager then
            return self._remoteManager:InvokeFunction("OpenCase", eggData.id, amount)
        else
            return RemoteFunctions.OpenCase:InvokeServer(eggData.id, amount)
        end
    end)
    
    self._purchaseInProgress = false
    
    -- Handle the response
    if not success then
        self._notificationSystem:Show({
            title = "Error",
            text = "Could not connect to server. Please try again.",
            type = "error"
        })
        return
    end
    
    if not result or not result.success then
        self._notificationSystem:Show({
            title = "Error",
            text = result and result.error or "Failed to open egg",
            type = "error"
        })
        return
    end
    
    -- ONLY NOW do we show success animations
    -- Create purchase animation overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "PurchaseOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 1000
    overlay.Parent = self.Frame
    
    -- Fade in overlay
    self._utilities.Tween(overlay, {
        BackgroundTransparency = 0.5
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
    
    -- Find the egg card
    local eggCard = nil
    if self._eggScrollFrame then
        eggCard = self._eggScrollFrame:FindFirstChild("EggCard_" .. eggData.id)
    end
    
    -- Animate egg flying to center
    if eggCard then
        local flyingEgg = Instance.new("ImageLabel")
        flyingEgg.Size = UDim2.new(0, 100, 0, 100)
        flyingEgg.Image = eggData.icon or ""
        flyingEgg.BackgroundTransparency = 1
        flyingEgg.ScaleType = Enum.ScaleType.Fit
        flyingEgg.ZIndex = 1001
        flyingEgg.Parent = overlay
        
        -- Start at egg card position
        local startPos = eggCard.AbsolutePosition + eggCard.AbsoluteSize / 2
        flyingEgg.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
        flyingEgg.AnchorPoint = Vector2.new(0.5, 0.5)
        
        -- Fly to center with spin
        self._utilities.Tween(flyingEgg, {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 150, 0, 150),
            Rotation = 360
        }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        
        -- Add glow effect
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1.5, 0, 1.5, 0)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084" -- Glow image
        glow.ImageColor3 = self._config.COLORS.Success
        glow.ImageTransparency = 0.5
        glow.ZIndex = 1000
        glow.Parent = flyingEgg
        
        -- Pulse glow
        task.spawn(function()
            while glow.Parent do
                self._utilities.Tween(glow, {
                    Size = UDim2.new(2, 0, 2, 0),
                    ImageTransparency = 0.8
                }, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
                task.wait(0.5)
                self._utilities.Tween(glow, {
                    Size = UDim2.new(1.5, 0, 1.5, 0),
                    ImageTransparency = 0.5
                }, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
                task.wait(0.5)
            end
        end)
    end
    
    -- Continue with animations
    
    -- Clean up overlay after animation
    task.wait(0.5)
    if overlay then
        self._utilities.Tween(overlay, {
            BackgroundTransparency = 1
        }, TweenInfo.new(0.3))
        task.wait(0.3)
        overlay:Destroy()
    end
    
    -- Create success particles at purchase location
    self:CreatePurchaseSuccessEffects(eggCard)
    
    -- Animate currency deduction
    self:AnimateCurrencyDeduction(eggData.currency, eggData.price * amount)
    
    -- Fire event to open case opening UI
    if self._eventBus then
        self._eventBus:Fire("OpenCaseAnimation", {
            results = result.results,
            eggData = eggData
        })
    end
    
    -- Update local currency immediately with animation
    if result.newCurrencies then
        for currency, value in pairs(result.newCurrencies) do
            if self._dataCache then
                self._dataCache:Set("currencies." .. currency, value)
            end
        end
    end
    
    -- Play success sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Purchase")
    end
end

-- ========================================
-- GAMEPASS SHOP
-- ========================================

function ShopUI:CreateGamepassShop(parent: Frame)
    -- Clear previous content
    if self._gamepassScrollFrame and self._gamepassScrollFrame.Parent then
        self._gamepassScrollFrame:Destroy()
    end
    
    -- Create scrolling frame
    self._gamepassScrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    -- List layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Padding = UDim.new(0, 15)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self._gamepassScrollFrame
    
    self._utilities.CreatePadding(self._gamepassScrollFrame, 10)
    
    -- Loading indicator
    local loadingLabel = self._uiFactory:CreateLabel(self._gamepassScrollFrame, {
        text = "Loading gamepasses...",
        size = UDim2.new(1, -20, 0, 50),
        textColor = self._config.COLORS.TextSecondary
    })
    
    -- Fetch gamepass data
    spawn(function()
        local success, gamepassData = pcall(function()
            if self._remoteManager then
                return self._remoteManager:InvokeFunction("GetShopData", "gamepasses")
            else
                return RemoteFunctions.GetShopData and
                       RemoteFunctions.GetShopData:InvokeServer("gamepasses")
            end
        end)
        
        if success and gamepassData then
            self._gamepassData = gamepassData
            loadingLabel:Destroy()
            
            -- Create gamepass cards
            for i, passData in ipairs(gamepassData) do
                local card = self:CreateGamepassCard(self._gamepassScrollFrame, passData)
                if card then
                    card.LayoutOrder = i
                end
            end
            
            -- Update canvas size
            spawn(function()
                wait()
                self._gamepassScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 
                    listLayout.AbsoluteContentSize.Y + 20)
            end)
        else
            loadingLabel.Text = "Failed to load gamepasses"
        end
    end)
end

function ShopUI:CreateGamepassCard(parent: Frame, passData: GamepassData): Frame?
    local card = Instance.new("Frame")
    card.Name = passData.name .. "Card"
    card.Size = UDim2.new(1, -20, 0, GAMEPASS_CARD_HEIGHT)
    card.BackgroundColor3 = self._config.COLORS.White
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    self._utilities.CreatePadding(card, 15)
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 70, 0, 70)
    icon.Position = UDim2.new(0, 0, 0.5, -35)
    icon.BackgroundTransparency = 1
    icon.Image = passData.icon
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = card
    
    -- Info container
    local infoContainer = Instance.new("Frame")
    infoContainer.Size = UDim2.new(1, -200, 1, 0)
    infoContainer.Position = UDim2.new(0, 85, 0, 0)
    infoContainer.BackgroundTransparency = 1
    infoContainer.Parent = card
    
    -- Name
    local nameLabel = self._uiFactory:CreateLabel(infoContainer, {
        text = passData.displayName or passData.name,
        size = UDim2.new(1, 0, 0, 25),
        position = UDim2.new(0, 0, 0, 10),
        font = self._config.FONTS.Secondary,
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.Text
    })
    
    -- Description
    local descLabel = self._uiFactory:CreateLabel(infoContainer, {
        text = passData.description,
        size = UDim2.new(1, 0, 0, 35),
        position = UDim2.new(0, 0, 0, 35),
        textXAlignment = Enum.TextXAlignment.Left,
        textWrapped = true,
        textColor = self._config.COLORS.TextSecondary,
        textScaled = false,
        textSize = 14
    })
    
    -- Buy button or owned indicator
    if passData.owned then
        local ownedLabel = self._uiFactory:CreateLabel(card, {
            text = "✓ Owned",
            size = UDim2.new(0, 100, 0, 35),
            position = UDim2.new(1, -110, 0.5, -17.5),
            backgroundColor = self._config.COLORS.Success,
            backgroundTransparency = 0,
            textColor = self._config.COLORS.White,
            font = self._config.FONTS.Secondary
        })
        self._utilities.CreateCorner(ownedLabel, 8)
    else
        local buyButton = self._uiFactory:CreateButton(card, {
            text = tostring(passData.price) .. " R$",
            size = UDim2.new(0, 100, 0, 35),
            position = UDim2.new(1, -110, 0.5, -17.5),
            backgroundColor = self._config.COLORS.Primary,
            callback = function()
                self:PurchaseGamepass(passData)
            end
        })
    end
    
    return card
end

function ShopUI:PurchaseGamepass(passData: GamepassData)
    Services.MarketplaceService:PromptGamePassPurchase(Services.Players.LocalPlayer, passData.id)
end

-- ========================================
-- CURRENCY SHOP
-- ========================================

function ShopUI:CreateCurrencyShop(parent: Frame)
    -- Clear previous content
    if self._currencyScrollFrame and self._currencyScrollFrame.Parent then
        self._currencyScrollFrame:Destroy()
    end
    
    -- Create scrolling frame
    self._currencyScrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
    gridLayout.CellSize = UDim2.new(0, CURRENCY_CARD_SIZE.X, 0, CURRENCY_CARD_SIZE.Y)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = self._currencyScrollFrame
    
    -- Create currency cards
    for i, package in ipairs(self._currencyPackages) do
        local card = self:CreateCurrencyCard(self._currencyScrollFrame, package)
        if card then
            card.LayoutOrder = i
        end
    end
end

function ShopUI:CreateCurrencyCard(parent: Frame, package: CurrencyPackage): Frame?
    local card = Instance.new("Frame")
    card.Name = "Package" .. package.amount
    card.BackgroundColor3 = self._config.COLORS.White
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    
    -- Currency icon
    local currencyIcon = Instance.new("ImageLabel")
    currencyIcon.Size = UDim2.new(0, 80, 0, 80)
    currencyIcon.Position = UDim2.new(0.5, -40, 0, 20)
    currencyIcon.BackgroundTransparency = 1
    currencyIcon.Image = self:GetCurrencyIcon(package.currency)
    currencyIcon.ScaleType = Enum.ScaleType.Fit
    currencyIcon.Parent = card
    
    -- Amount label
    local amountLabel = self._uiFactory:CreateLabel(card, {
        text = self._utilities.FormatNumber(package.amount),
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0, 110),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.Primary
    })
    
    -- Bonus label
    if package.bonus and package.bonus > 0 then
        local bonusLabel = self._uiFactory:CreateLabel(card, {
            text = "+" .. package.bonus .. "% Bonus!",
            size = UDim2.new(1, -20, 0, 20),
            position = UDim2.new(0, 10, 0, 140),
            textColor = self._config.COLORS.Success,
            font = self._config.FONTS.Secondary
        })
        
        -- Add glow effect
        if self._effectsLibrary then
            self._effectsLibrary:CreateGlowEffect(bonusLabel, {
                color = self._config.COLORS.Success,
                size = 20
            })
        end
    end
    
    -- Price button
    local priceButton = self._uiFactory:CreateButton(card, {
        text = "R$" .. tostring(package.price / 100),
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 1, -50),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            self:PurchaseCurrency(package)
        end
    })
    
    return card
end

function ShopUI:PurchaseCurrency(package: CurrencyPackage)
    Services.MarketplaceService:PromptProductPurchase(Services.Players.LocalPlayer, package.id)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ShopUI:GetCurrencyIcon(currency: string): string
    local icons = {
        coins = self._config.ICONS.Coin or "rbxassetid://10000000001",
        gems = self._config.ICONS.Gem or "rbxassetid://10000000002",
        tickets = self._config.ICONS.Ticket or "rbxassetid://10000000003",
    }
    
    return icons[currency:lower()] or icons.coins
end

function ShopUI:LoadShopData()
    -- This would load all shop data at once
    -- For now, each tab loads its own data
end

function ShopUI:CreatePurchaseSuccessEffects(sourceElement: GuiObject?)
    if not sourceElement then return end
    
    local playerGui = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    if not playerGui then return end
    
    -- Create particle container
    local particleContainer = Instance.new("Frame")
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ZIndex = 2000
    particleContainer.Parent = playerGui
    
    -- Get source position
    local centerPos = sourceElement.AbsolutePosition + sourceElement.AbsoluteSize / 2
    
    -- Create success particles
    for i = 1, 20 do
        task.spawn(function()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(6, 12), 0, math.random(6, 12))
            particle.Position = UDim2.new(0, centerPos.X, 0, centerPos.Y)
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.BackgroundColor3 = self._config.COLORS.Success
            particle.BorderSizePixel = 0
            particle.ZIndex = 2001
            particle.Parent = particleContainer
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
            
            -- Random burst direction
            local angle = math.random() * math.pi * 2
            local distance = math.random(50, 150)
            local targetX = centerPos.X + math.cos(angle) * distance
            local targetY = centerPos.Y + math.sin(angle) * distance - math.random(20, 50)
            
            -- Animate particle
            self._utilities.Tween(particle, {
                Position = UDim2.new(0, targetX, 0, targetY),
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Rotation = math.random(180, 540)
            }, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end)
    end
    
    -- Create sparkle effects
    for i = 1, 10 do
        task.spawn(function()
            task.wait(math.random() * 0.3)
            
            local sparkle = Instance.new("ImageLabel")
            sparkle.Size = UDim2.new(0, 30, 0, 30)
            sparkle.Position = UDim2.new(0, centerPos.X + math.random(-30, 30), 0, centerPos.Y + math.random(-30, 30))
            sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
            sparkle.BackgroundTransparency = 1
            sparkle.Image = "rbxassetid://7072719831" -- Star image
            sparkle.ImageColor3 = self._config.COLORS.Success
            sparkle.ZIndex = 2002
            sparkle.Parent = particleContainer
            
            -- Sparkle animation
            sparkle.Size = UDim2.new(0, 0, 0, 0)
            self._utilities.Tween(sparkle, {
                Size = UDim2.new(0, 30, 0, 30),
                Rotation = 180,
                ImageTransparency = 0
            }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            
            task.wait(0.3)
            
            self._utilities.Tween(sparkle, {
                Size = UDim2.new(0, 0, 0, 0),
                Rotation = 360,
                ImageTransparency = 1
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
        end)
    end
    
    -- Clean up
    game:GetService("Debris"):AddItem(particleContainer, 2)
end

function ShopUI:AnimateCurrencyDeduction(currency: string, amount: number)
    local playerGui = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    if not playerGui then return end
    
    -- Find currency display
    local currencyDisplay = playerGui:FindFirstChild("CurrencyDisplay")
    if not currencyDisplay then
        local mainUI = playerGui:FindFirstChild("MainUI")
        if mainUI then
            currencyDisplay = mainUI:FindFirstChild("CurrencyFrame")
        end
    end
    
    if not currencyDisplay then return end
    
    -- Create floating deduction text
    local deductText = Instance.new("TextLabel")
    deductText.Size = UDim2.new(0, 200, 0, 50)
    deductText.Position = UDim2.new(1, -220, 0, 30)
    deductText.BackgroundTransparency = 1
    deductText.Text = "-" .. self._utilities.FormatNumber(amount)
    deductText.Font = self._config.FONTS.Numbers
    deductText.TextColor3 = self._config.COLORS.Error
    deductText.TextScaled = true
    deductText.TextStrokeColor3 = Color3.new(0, 0, 0)
    deductText.TextStrokeTransparency = 0
    deductText.ZIndex = 1000
    deductText.Parent = playerGui
    
    -- Animate floating up and fading
    self._utilities.Tween(deductText, {
        Position = UDim2.new(1, -220, 0, -20),
        TextTransparency = 1,
        TextStrokeTransparency = 1
    }, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Flash currency display
    if currencyDisplay then
        local originalColor = currencyDisplay.BackgroundColor3
        currencyDisplay.BackgroundColor3 = self._config.COLORS.Error
        
        self._utilities.Tween(currencyDisplay, {
            BackgroundColor3 = originalColor
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
    end
    
    game:GetService("Debris"):AddItem(deductText, 1.5)
end

function ShopUI:RefreshShopData()
    -- Refresh all shop data
    if self._tabs["Eggs"] and self._tabs["Eggs"].initialized then
        self._tabs["Eggs"].initialized = false
        if self._currentTab == "Eggs" then
            self:InitializeTab("Eggs")
        end
    end
    
    if self._tabs["Gamepasses"] and self._tabs["Gamepasses"].initialized then
        self._tabs["Gamepasses"].initialized = false
        if self._currentTab == "Gamepasses" then
            self:InitializeTab("Gamepasses")
        end
    end
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function ShopUI:DebugPrint()
        print("\n=== ShopUI Debug Info ===")
        print("Is Open:", self._isOpen)
        print("Current Tab:", self._currentTab or "None")
        print("Purchase In Progress:", self._purchaseInProgress)
        
        print("\nEgg Data Count:", #self._eggData)
        print("Gamepass Data Count:", #self._gamepassData)
        print("Currency Packages:", #self._currencyPackages)
        
        print("\nInitialized Tabs:")
        for name, tab in pairs(self._tabs) do
            print("  " .. name .. ":", tab.initialized and "Yes" or "No")
        end
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function ShopUI:Destroy()
    -- Clean up all connections and objects via Janitor
    if self._janitor then
        self._janitor:Cleanup()
        self._janitor = nil
    end
    
    -- Destroy frame
    if self.Frame then
        self.Frame:Destroy()
        self.Frame = nil
    end
    
    -- Clear references
    self._tabs = {}
    self._tabFrames = {}
    self._currentTab = nil
    self._eggData = {}
    self._gamepassData = {}
    self._eggScrollFrame = nil
    self._gamepassScrollFrame = nil
    self._currencyScrollFrame = nil
end

return ShopUI