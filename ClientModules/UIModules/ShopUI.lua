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
local HEADER_HEIGHT = 60
local TAB_HEIGHT = 40
local CARD_PADDING = 20
local EGG_CARD_SIZE = Vector2.new(220, 280)
local GAMEPASS_CARD_HEIGHT = 100
local CURRENCY_CARD_SIZE = Vector2.new(200, 250)
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
-- OPEN/CLOSE
-- ========================================

function ShopUI:Open()
    if self._isOpen then
        if self.Frame then
            self.Frame.Visible = true
        end
        return
    end
    
    -- Create UI if not exists
    if not self.Frame then
        self:CreateUI()
    end
    
    self.Frame.Visible = true
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
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✨ Sanrio Tycoon Shop ✨"
    title.TextColor3 = self._config.COLORS.White
    title.Font = self._config.FONTS.Display
    title.TextScaled = true
    title.Parent = self._header
    
    local titleConstraint = Instance.new("UITextSizeConstraint")
    titleConstraint.MaxTextSize = 24
    titleConstraint.MinTextSize = 18
    titleConstraint.Parent = title
    
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
    -- Tab button
    local tabButton = self._uiFactory:CreateButton(tabButtons, {
        name = tabData.name .. "Tab",
        text = (tabData.icon or "") .. " " .. tabData.name,
        size = UDim2.new(1/#DEFAULT_TABS, -5, 1, 0),
        backgroundColor = order == 1 and self._config.COLORS.Primary or self._config.COLORS.White,
        textColor = order == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
        font = self._config.FONTS.Secondary,
        callback = function()
            self:SelectTab(tabData.name)
        end
    })
    
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
        initialized = false
    }
    self._tabFrames[tabData.name] = tabFrame
end

function ShopUI:SelectTab(tabName: string)
    if self._currentTab == tabName then return end
    
    -- Update buttons
    for name, tab in pairs(self._tabs) do
        if name == tabName then
            self._utilities.Tween(tab.button, {
                BackgroundColor3 = self._config.COLORS.Primary,
                TextColor3 = self._config.COLORS.White
            }, self._config.TWEEN_INFO.Fast)
        else
            self._utilities.Tween(tab.button, {
                BackgroundColor3 = self._config.COLORS.White,
                TextColor3 = self._config.COLORS.Dark
            }, self._config.TWEEN_INFO.Fast)
        end
    end
    
    -- Update content
    for name, tab in pairs(self._tabs) do
        tab.frame.Visible = name == tabName
    end
    
    self._currentTab = tabName
    
    -- Initialize tab if needed
    if not self._tabs[tabName].initialized then
        self:InitializeTab(tabName)
        self._tabs[tabName].initialized = true
    end
    
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
            loadingLabel.Text = "Failed to load eggs"
            if self._debugMode then
                warn("[ShopUI] Failed to load egg data:", eggData)
            end
        end
    end)
end

function ShopUI:PopulateEggShop(container: Frame)
    -- Create scrolling frame
    self._eggScrollFrame = self._uiFactory:CreateScrollingFrame(container, {
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
    self._utilities.CreatePadding(self._eggScrollFrame, 10)
    
    -- Create egg cards
    for i, eggData in ipairs(self._eggData) do
        local card = self:CreateEggCard(self._eggScrollFrame, eggData)
        if card then
            card.LayoutOrder = i
        end
    end
    
    -- Update canvas size
    spawn(function()
        wait() -- Wait for layout
        self._eggScrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function ShopUI:CreateEggCard(parent: Frame, eggData: EggData): Frame?
    if not eggData or not eggData.id then return nil end
    
    local card = Instance.new("Frame")
    card.Name = "EggCard_" .. eggData.id
    card.BackgroundColor3 = self._config.COLORS.Surface
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 12)
    -- No shadow per user feedback
    
    -- Egg image
    local eggImage = Instance.new("ImageLabel")
    eggImage.Name = "EggImage"
    eggImage.Size = UDim2.new(0, 120, 0, 120)
    eggImage.Position = UDim2.new(0.5, -60, 0, 20)
    eggImage.BackgroundTransparency = 1
    eggImage.Image = eggData.icon or ""
    eggImage.ScaleType = Enum.ScaleType.Fit
    eggImage.Parent = card
    
    -- Egg name
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = eggData.displayName or eggData.name,
        size = UDim2.new(1, -20, 0, 25),
        position = UDim2.new(0, 10, 0, 150),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.Text
    })
    
    -- Price container
    local priceContainer = Instance.new("Frame")
    priceContainer.Size = UDim2.new(1, -20, 0, 30)
    priceContainer.Position = UDim2.new(0, 10, 0, 180)
    priceContainer.BackgroundTransparency = 1
    priceContainer.Parent = card
    
    -- Currency icon
    local currencyIcon = Instance.new("ImageLabel")
    currencyIcon.Size = UDim2.new(0, 25, 0, 25)
    currencyIcon.Position = UDim2.new(0, 0, 0.5, -12.5)
    currencyIcon.BackgroundTransparency = 1
    currencyIcon.Image = self:GetCurrencyIcon(eggData.currency)
    currencyIcon.Parent = priceContainer
    
    -- Price label
    local priceLabel = self._uiFactory:CreateLabel(priceContainer, {
        text = self._utilities.FormatNumber(eggData.price),
        size = UDim2.new(1, -35, 1, 0),
        position = UDim2.new(0, 35, 0, 0),
        font = self._config.FONTS.Numbers,
        textColor = self._config.COLORS.Text
    })
    
    -- Buy button
    local buyButton = self._uiFactory:CreateButton(card, {
        text = "Open",
        size = UDim2.new(1, -20, 0, 35),
        position = UDim2.new(0, 10, 1, -45),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            self:ShowEggPurchaseDialog(eggData)
        end
    })
    
    -- Hover effect for card
    card.MouseEnter:Connect(function()
        self._utilities.Tween(card, {
            BackgroundColor3 = self._utilities.DarkenColor(self._config.COLORS.Surface, 0.05)
        }, self._config.TWEEN_INFO.Fast)
        
        -- Scale egg image
        self._utilities.Tween(eggImage, {
            Size = UDim2.new(0, 130, 0, 130),
            Position = UDim2.new(0.5, -65, 0, 15)
        }, self._config.TWEEN_INFO.Fast)
    end)
    
    card.MouseLeave:Connect(function()
        self._utilities.Tween(card, {
            BackgroundColor3 = self._config.COLORS.Surface
        }, self._config.TWEEN_INFO.Fast)
        
        -- Reset egg image
        self._utilities.Tween(eggImage, {
            Size = UDim2.new(0, 120, 0, 120),
            Position = UDim2.new(0.5, -60, 0, 20)
        }, self._config.TWEEN_INFO.Fast)
    end)
    
    return card
end

function ShopUI:ShowEggPurchaseDialog(eggData: EggData)
    if self._purchaseInProgress then return end
    
    -- Create modal
    local modalId = self._windowManager:CreateWindow({
        title = "Open " .. (eggData.displayName or eggData.name) .. "?",
        size = Vector2.new(400, 300),
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
        size = UDim2.new(1, -20, 0, 20),
        position = UDim2.new(0, 10, 0, 120),
        textColor = self._config.COLORS.Text
    })
    
    -- Amount buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -20, 0, 40)
    buttonContainer.Position = UDim2.new(0, 10, 0, 145)
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
            text = tostring(amount),
            size = UDim2.new(0, 60, 1, 0),
            backgroundColor = amount == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
            textColor = amount == 1 and self._config.COLORS.White or self._config.COLORS.Text,
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
        size = UDim2.new(1, -20, 0, 25),
        position = UDim2.new(0, 10, 0, 195),
        font = self._config.FONTS.Secondary,
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
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 1, -50),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            self._windowManager:CloseWindow(modalId)
            self:PurchaseEgg(eggData, selectedAmount)
        end
    })
end

function ShopUI:PurchaseEgg(eggData: EggData, amount: number)
    if self._purchaseInProgress then return end
    
    self._purchaseInProgress = true
    
    -- Request egg opening from server
    local success, result = pcall(function()
        if self._remoteManager then
            return self._remoteManager:InvokeFunction("OpenCase", eggData.id, amount)
        else
            return RemoteFunctions.OpenCase:InvokeServer(eggData.id, amount)
        end
    end)
    
    self._purchaseInProgress = false
    
    if not success then
        self._notificationSystem:Show({
            title = "Error",
            text = "Could not connect to server. Please try again.",
            type = "error"
        })
        return
    end
    
    if result and result.success then
        -- Fire event to open case opening UI
        if self._eventBus then
            self._eventBus:Fire("OpenCaseAnimation", {
                results = result.results,
                eggData = eggData
            })
        end
        
        -- Update local currency immediately
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
    else
        self._notificationSystem:Show({
            title = "Error",
            text = result and result.error or "Failed to open egg",
            type = "error"
        })
    end
end

-- ========================================
-- GAMEPASS SHOP
-- ========================================

function ShopUI:CreateGamepassShop(parent: Frame)
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