--[[
    Module: TradingUI
    Description: Comprehensive trading interface with dual trade windows, pet selection,
                 ready states, countdown timer, trade history, and security confirmations
    Features: Player search, trade requests, item addition/removal, currency trading,
              ready/confirm system, trade history, security checks
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local TradingUI = {}
TradingUI.__index = TradingUI

-- ========================================
-- TYPES
-- ========================================

type TradeItem = {
    type: "pet" | "currency",
    id: string?,
    amount: number?,
    data: any?
}

type TradeState = {
    tradeId: string,
    partner: Player,
    yourOffer: {TradeItem},
    theirOffer: {TradeItem},
    yourReady: boolean,
    theirReady: boolean,
    confirmed: boolean,
    timestamp: number
}

type TradeHistory = {
    partner: string,
    partnerId: number,
    timestamp: number,
    yourOffer: {TradeItem},
    theirOffer: {TradeItem},
    status: "completed" | "cancelled"
}

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(900, 600)
local HEADER_HEIGHT = 60
local TRADE_SLOT_SIZE = Vector2.new(80, 100)
local MAX_TRADE_ITEMS = 20
local COUNTDOWN_TIME = 5
local SEARCH_DEBOUNCE = 0.5
local TRADE_HISTORY_LIMIT = 50
local SELECTOR_SIZE = Vector2.new(600, 500)

-- Trade status colors
local STATUS_COLORS = {
    notReady = Config.COLORS.Error,
    ready = Config.COLORS.Warning,
    confirmed = Config.COLORS.Success
}

-- ========================================
-- INITIALIZATION
-- ========================================

function TradingUI.new(dependencies)
    local self = setmetatable({}, TradingUI)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    self._dataCache = dependencies.DataCache
    self._remoteManager = dependencies.RemoteManager
    self._soundSystem = dependencies.SoundSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._uiFactory = dependencies.UIFactory
    self._windowManager = dependencies.WindowManager
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self.TabFrames = {}
    self.SearchResultsFrame = nil
    self.TradeOverlay = nil
    self.TradeWindow = nil
    self.PetSelector = nil
    self.CurrentTrade = nil
    self.TradeControls = {}
    self.StatusLabels = {}
    self.TradeSides = {}
    self.TradeHistory = {}
    self.CountdownActive = false
    
    -- State
    self.SearchDebounce = nil
    self.SelectedPets = {}
    self.CurrencyAmounts = {coins = 0, gems = 0}
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    -- Defer loading trade history until Initialize is called
    -- self:LoadTradeHistory() -- Moved to Initialize
    
    return self
end

function TradingUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Trade events
    self._eventBus:On("TradeRequested", function(data)
        self:HandleTradeRequest(data.from)
    end)
    
    self._eventBus:On("TradeStarted", function(data)
        self:OpenTradeWindow(data.trade)
    end)
    
    self._eventBus:On("TradeUpdated", function(data)
        if self.CurrentTrade and self.CurrentTrade.tradeId == data.tradeId then
            self.CurrentTrade = data.trade
            self:UpdateTradeDisplay()
        end
    end)
    
    self._eventBus:On("TradeCancelled", function(data)
        if self.CurrentTrade and self.CurrentTrade.tradeId == data.tradeId then
            self:CloseTradeWindow()
            self._notificationSystem:SendNotification("Trade Cancelled", 
                data.reason or "Trade was cancelled", "info")
        end
    end)
    
    self._eventBus:On("TradeCompleted", function(data)
        if self.CurrentTrade and self.CurrentTrade.tradeId == data.tradeId then
            self:HandleTradeComplete(data)
        end
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function TradingUI:Open()
    -- Load trade history on first open
    if not self.TradeHistory or #self.TradeHistory == 0 then
        self:LoadTradeHistory()
    end
    
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshRecentTrades()
        return
    end
    
    -- Create UI
    self:CreateUI()
end

function TradingUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
    
    -- Close any open trade window
    if self.TradeWindow then
        self:CloseTradeWindow()
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function TradingUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                   self._windowManager and self._windowManager:GetMainPanel() or 
                   Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[TradingUI] No parent container found")
        return
    end
    
    -- Create main frame
    if self._uiFactory and self._uiFactory.CreateFrame then
        self.Frame = self._uiFactory:CreateFrame(parent, {
            name = "TradingFrame",
            size = UDim2.new(1, -20, 1, -90),
            position = UDim2.new(0, 10, 0, 80),
            backgroundColor = self._config.COLORS.Background,
            visible = true
        })
    else
        -- Fallback if CreateFrame doesn't exist
        self.Frame = Instance.new("Frame")
        self.Frame.Name = "TradingFrame"
        self.Frame.Size = UDim2.new(1, -20, 1, -90)
        self.Frame.Position = UDim2.new(0, 10, 0, 80)
        self.Frame.BackgroundColor3 = self._config.COLORS.Background
        self.Frame.BorderSizePixel = 0
        self.Frame.Parent = mainPanel
        
        self._utilities.CreateCorner(self.Frame, 12)
    end
    
    -- Create header
    self:CreateHeader()
    
    -- Create tabs
    self:CreateTabs()
end

function TradingUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "🤝 Trading Center 🤝",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24
    })
end

function TradingUI:CreateTabs()
    local tabs = {
        {
            name = "Send Trade",
            callback = function(frame) 
                self:CreateSendTradeView(frame) 
            end
        },
        {
            name = "Trade History",
            callback = function(frame)
                self:CreateTradeHistoryView(frame)
            end
        }
    }
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 1, -80)
    tabContainer.Position = UDim2.new(0, 10, 0, 70)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.Frame
    
    -- Tab buttons
    local tabButtonsFrame = Instance.new("Frame")
    tabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
    tabButtonsFrame.BackgroundTransparency = 1
    tabButtonsFrame.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabButtonsFrame
    
    -- Tab content
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -45)
    tabContent.Position = UDim2.new(0, 0, 0, 45)
    tabContent.BackgroundColor3 = self._config.COLORS.White
    tabContent.Parent = tabContainer
    
    self._utilities.CreateCorner(tabContent, 12)
    
    for i, tab in ipairs(tabs) do
        -- Tab button
        local tabButton = self._uiFactory:CreateButton(tabButtonsFrame, {
            text = tab.name,
            size = UDim2.new(0, 150, 1, 0),
            backgroundColor = i == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
            textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
            callback = function()
                -- Update button states
                for j, btn in ipairs(tabButtonsFrame:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = j == i and self._config.COLORS.Primary or self._config.COLORS.Surface
                        btn.TextColor3 = j == i and self._config.COLORS.White or self._config.COLORS.Dark
                    end
                end
                
                -- Show tab content
                for name, frame in pairs(self.TabFrames) do
                    frame.Visible = name == tab.name
                end
            end
        })
        
        -- Tab frame
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = tab.name .. "Tab"
        tabFrame.Size = UDim2.new(1, -20, 1, -20)
        tabFrame.Position = UDim2.new(0, 10, 0, 10)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = tabContent
        
        tab.callback(tabFrame)
        self.TabFrames[tab.name] = tabFrame
    end
end

-- ========================================
-- SEND TRADE VIEW
-- ========================================

function TradingUI:CreateSendTradeView(parent: Frame)
    -- Player search
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -20, 0, 50)
    searchFrame.Position = UDim2.new(0, 10, 0, 10)
    searchFrame.BackgroundTransparency = 1
    searchFrame.Parent = parent
    
    local searchBox = self._uiFactory:CreateTextBox(searchFrame, {
        placeholder = "Enter player name...",
        size = UDim2.new(0.7, -10, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        callback = function(text)
            self:OnSearchChanged(text)
        end
    })
    
    local searchButton = self._uiFactory:CreateButton(searchFrame, {
        text = "Search",
        size = UDim2.new(0.3, -10, 1, 0),
        position = UDim2.new(0.7, 10, 0, 0),
        callback = function()
            self:SearchPlayer(searchBox.Text)
        end
    })
    
    -- Search results
    local resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "SearchResults"
    resultsFrame.Size = UDim2.new(1, -20, 0, 200)
    resultsFrame.Position = UDim2.new(0, 10, 0, 70)
    resultsFrame.BackgroundColor3 = self._config.COLORS.White
    resultsFrame.Parent = parent
    
    self._utilities.CreateCorner(resultsFrame, 12)
    
    local resultsScroll = self._uiFactory:CreateScrollingFrame(resultsFrame, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    self.SearchResultsFrame = resultsScroll
    
    -- Recent trades section
    local recentLabel = self._uiFactory:CreateLabel(parent, {
        text = "Recent Trade Partners",
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0, 280),
        font = self._config.FONTS.Secondary,
        textXAlignment = Enum.TextXAlignment.Left
    })
    
    local recentFrame = Instance.new("Frame")
    recentFrame.Size = UDim2.new(1, -20, 1, -330)
    recentFrame.Position = UDim2.new(0, 10, 0, 320)
    recentFrame.BackgroundColor3 = self._config.COLORS.Surface
    recentFrame.Parent = parent
    
    self._utilities.CreateCorner(recentFrame, 12)
    
    self.RecentTradesFrame = self._uiFactory:CreateScrollingFrame(recentFrame, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    -- Load recent trades
    self:RefreshRecentTrades()
end

function TradingUI:OnSearchChanged(text: string)
    -- Debounce search
    if self.SearchDebounce then
        task.cancel(self.SearchDebounce)
    end
    
    self.SearchDebounce = task.spawn(function()
        task.wait(SEARCH_DEBOUNCE)
        self:SearchPlayer(text)
        self.SearchDebounce = nil
    end)
end

function TradingUI:SearchPlayer(username: string)
    -- Clear previous results
    for _, child in ipairs(self.SearchResultsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if username == "" then return end
    
    -- Search for online players
    local results = {}
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Services.Players.LocalPlayer and 
           string.find(string.lower(player.Name), string.lower(username)) then
            table.insert(results, player)
        end
    end
    
    -- Display results
    if #results == 0 then
        local noResultsLabel = self._uiFactory:CreateLabel(self.SearchResultsFrame, {
            text = "No players found",
            size = UDim2.new(1, 0, 0, 50),
            position = UDim2.new(0, 0, 0, 0),
            textColor = self._config.COLORS.TextSecondary
        })
    else
        for i, player in ipairs(results) do
            self:CreatePlayerResult(player, i)
        end
    end
end

function TradingUI:CreatePlayerResult(player: Player, index: number)
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = player.Name
    resultFrame.Size = UDim2.new(1, -10, 0, 60)
    resultFrame.Position = UDim2.new(0, 5, 0, (index - 1) * 65 + 5)
    resultFrame.BackgroundColor3 = self._config.COLORS.Surface
    resultFrame.Parent = self.SearchResultsFrame
    
    self._utilities.CreateCorner(resultFrame, 8)
    self._utilities.CreatePadding(resultFrame, 10)
    
    -- Player avatar
    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 40, 0, 40)
    avatarImage.Position = UDim2.new(0, 0, 0.5, -20)
    avatarImage.BackgroundColor3 = self._config.COLORS.White
    avatarImage.Image = Services.Players:GetUserThumbnailAsync(
        player.UserId, 
        Enum.ThumbnailType.HeadShot, 
        Enum.ThumbnailSize.Size100x100
    )
    avatarImage.Parent = resultFrame
    
    self._utilities.CreateCorner(avatarImage, 20)
    
    -- Player name
    local nameLabel = self._uiFactory:CreateLabel(resultFrame, {
        text = player.DisplayName,
        size = UDim2.new(0.5, -60, 1, 0),
        position = UDim2.new(0, 50, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Trade button
    local tradeButton = self._uiFactory:CreateButton(resultFrame, {
        text = "Send Trade",
        size = UDim2.new(0, 100, 0, 30),
        position = UDim2.new(1, -105, 0.5, -15),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            self:SendTradeRequest(player)
        end
    })
    
    -- Update canvas size
    self.SearchResultsFrame.CanvasSize = UDim2.new(0, 0, 0, #self.SearchResultsFrame:GetChildren() * 65 + 10)
end

function TradingUI:SendTradeRequest(targetPlayer: Player)
    if not targetPlayer then return end
    
    -- Send trade request
    if self._remoteManager then
        local success, result = self._remoteManager:InvokeServer("RequestTrade", targetPlayer)
        
        if success then
            self._notificationSystem:SendNotification("Trade Request Sent", 
                "Waiting for " .. targetPlayer.DisplayName .. " to respond...", "info")
            
            -- Play sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("Send")
            end
        else
            self._notificationSystem:SendNotification("Trade Failed", 
                result or "Failed to send trade request", "error")
        end
    end
end

-- ========================================
-- TRADE HISTORY VIEW
-- ========================================

function TradingUI:CreateTradeHistoryView(parent: Frame)
    local historyScroll = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    self.HistoryScrollFrame = historyScroll
    
    -- Refresh history display
    self:RefreshTradeHistory()
end

function TradingUI:RefreshTradeHistory()
    if not self.HistoryScrollFrame then return end
    
    -- Clear existing
    for _, child in ipairs(self.HistoryScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Display history
    if #self.TradeHistory == 0 then
        local emptyLabel = self._uiFactory:CreateLabel(self.HistoryScrollFrame, {
            text = "No trade history yet",
            size = UDim2.new(1, 0, 0, 50),
            position = UDim2.new(0, 0, 0, 10),
            textColor = self._config.COLORS.TextSecondary
        })
    else
        for i, trade in ipairs(self.TradeHistory) do
            self:CreateHistoryEntry(trade, i)
        end
    end
end

function TradingUI:CreateHistoryEntry(trade: TradeHistory, index: number)
    local entryFrame = Instance.new("Frame")
    entryFrame.Size = UDim2.new(1, -10, 0, 80)
    entryFrame.Position = UDim2.new(0, 5, 0, (index - 1) * 85 + 5)
    entryFrame.BackgroundColor3 = self._config.COLORS.Surface
    entryFrame.Parent = self.HistoryScrollFrame
    
    self._utilities.CreateCorner(entryFrame, 8)
    self._utilities.CreatePadding(entryFrame, 10)
    
    -- Status indicator
    local statusColor = trade.status == "completed" and 
                       self._config.COLORS.Success or 
                       self._config.COLORS.TextSecondary
    
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(0, 4, 1, -10)
    statusBar.Position = UDim2.new(0, 0, 0, 5)
    statusBar.BackgroundColor3 = statusColor
    statusBar.BorderSizePixel = 0
    statusBar.Parent = entryFrame
    
    -- Trade info
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -20, 1, 0)
    infoFrame.Position = UDim2.new(0, 15, 0, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = entryFrame
    
    -- Partner name
    local partnerLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = "Trade with " .. trade.partner,
        size = UDim2.new(1, 0, 0, 25),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Secondary,
        textXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Date/time
    local timeLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = self:FormatTradeTime(trade.timestamp),
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 25),
        textColor = self._config.COLORS.TextSecondary,
        textXAlignment = Enum.TextXAlignment.Left,
        textSize = 14
    })
    
    -- Trade summary
    local summaryText = self:GetTradeSummary(trade)
    local summaryLabel = self._uiFactory:CreateLabel(infoFrame, {
        text = summaryText,
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 45),
        textColor = self._config.COLORS.Dark,
        textXAlignment = Enum.TextXAlignment.Left,
        textSize = 14
    })
    
    -- Update canvas size
    self.HistoryScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #self.TradeHistory * 85 + 10)
end

-- ========================================
-- TRADE WINDOW
-- ========================================

function TradingUI:OpenTradeWindow(trade: TradeState)
    -- Close any existing trade
    if self.TradeWindow then
        self:CloseTradeWindow()
    end
    
    self.CurrentTrade = trade
    self.SelectedPets = {}
    self.CurrencyAmounts = {coins = 0, gems = 0}
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "TradeOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 300
    overlay.Parent = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    self.TradeOverlay = overlay
    
    -- Fade in
    self._utilities.Tween(overlay, {
        BackgroundTransparency = 0.3
    }, self._config.TWEEN_INFO.Normal)
    
    -- Trade window
    local tradeWindow = Instance.new("Frame")
    tradeWindow.Name = "TradeWindow"
    tradeWindow.Size = UDim2.new(0, WINDOW_SIZE.X, 0, WINDOW_SIZE.Y)
    tradeWindow.Position = UDim2.new(0.5, -WINDOW_SIZE.X/2, 0.5, -WINDOW_SIZE.Y/2)
    tradeWindow.BackgroundColor3 = self._config.COLORS.Background
    tradeWindow.ZIndex = 301
    tradeWindow.Parent = overlay
    
    self._utilities.CreateCorner(tradeWindow, 20)
    
    self.TradeWindow = tradeWindow
    
    -- Animate in
    tradeWindow.Size = UDim2.new(0, 0, 0, 0)
    tradeWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    self._utilities.Tween(tradeWindow, {
        Size = UDim2.new(0, WINDOW_SIZE.X, 0, WINDOW_SIZE.Y),
        Position = UDim2.new(0.5, -WINDOW_SIZE.X/2, 0.5, -WINDOW_SIZE.Y/2)
    }, self._config.TWEEN_INFO.Bounce)
    
    -- Create trade UI
    self:CreateTradeHeader()
    self:CreateTradeContent()
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("OpenMenu")
    end
    
    -- Register with window manager
    if self._windowManager then
        self._windowManager:RegisterOverlay(overlay, "TradeWindow")
    end
end

function TradingUI:CreateTradeHeader()
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = self._config.COLORS.Primary
    header.ZIndex = 302
    header.Parent = self.TradeWindow
    
    self._utilities.CreateCorner(header, 20)
    
    -- Fix bottom corners
    local cornerFix = Instance.new("Frame")
    cornerFix.Size = UDim2.new(1, 0, 0, 20)
    cornerFix.Position = UDim2.new(0, 0, 1, -20)
    cornerFix.BackgroundColor3 = self._config.COLORS.Primary
    cornerFix.BorderSizePixel = 0
    cornerFix.ZIndex = 301
    cornerFix.Parent = header
    
    -- Title
    local titleLabel = self._uiFactory:CreateLabel(header, {
        text = "Trading with " .. self.CurrentTrade.partner.DisplayName,
        size = UDim2.new(1, -100, 1, 0),
        position = UDim2.new(0, 20, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textXAlignment = Enum.TextXAlignment.Left,
        zIndex = 303
    })
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(header, {
        text = "✖",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -45, 0, 5),
        backgroundColor = Color3.new(1, 1, 1),
        backgroundTransparency = 0.9,
        textColor = self._config.COLORS.White,
        zIndex = 303,
        callback = function()
            self:CancelTrade()
        end
    })
end

function TradingUI:CreateTradeContent()
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -120)
    content.Position = UDim2.new(0, 10, 0, 60)
    content.BackgroundTransparency = 1
    content.ZIndex = 302
    content.Parent = self.TradeWindow
    
    -- Your side
    local yourSide = self:CreateTradeSide(content, 
        Services.Players.LocalPlayer.DisplayName, 
        true,
        UDim2.new(0.5, -10, 1, 0),
        UDim2.new(0, 0, 0, 0)
    )
    self.TradeSides.You = yourSide
    
    -- Their side
    local theirSide = self:CreateTradeSide(content,
        self.CurrentTrade.partner.DisplayName,
        false,
        UDim2.new(0.5, -10, 1, 0),
        UDim2.new(0.5, 10, 0, 0)
    )
    self.TradeSides.Them = theirSide
    
    -- Controls
    self:CreateTradeControls()
    
    -- Update initial display
    self:UpdateTradeDisplay()
end

function TradingUI:CreateTradeSide(parent: Frame, playerName: string, isYou: boolean, 
                                  size: UDim2, position: UDim2): Frame
    local sideFrame = Instance.new("Frame")
    sideFrame.Size = size
    sideFrame.Position = position
    sideFrame.BackgroundColor3 = self._config.COLORS.White
    sideFrame.ZIndex = 303
    sideFrame.Parent = parent
    
    self._utilities.CreateCorner(sideFrame, 12)
    
    -- Header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 40)
    headerFrame.BackgroundColor3 = self._config.COLORS.Primary
    headerFrame.ZIndex = 304
    headerFrame.Parent = sideFrame
    
    self._utilities.CreateCorner(headerFrame, 12)
    
    -- Fix bottom corners
    local bottomRect = Instance.new("Frame")
    bottomRect.Size = UDim2.new(1, 0, 0, 12)
    bottomRect.Position = UDim2.new(0, 0, 1, -12)
    bottomRect.BackgroundColor3 = headerFrame.BackgroundColor3
    bottomRect.BorderSizePixel = 0
    bottomRect.ZIndex = 304
    bottomRect.Parent = headerFrame
    
    local playerLabel = self._uiFactory:CreateLabel(headerFrame, {
        text = playerName,
        size = UDim2.new(1, -20, 1, 0),
        position = UDim2.new(0, 10, 0, 0),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.White,
        zIndex = 305
    })
    
    -- Items area
    local itemsArea = Instance.new("ScrollingFrame")
    itemsArea.Name = "ItemsArea"
    itemsArea.Size = UDim2.new(1, -20, 1, -140)
    itemsArea.Position = UDim2.new(0, 10, 0, 50)
    itemsArea.BackgroundColor3 = self._config.COLORS.Background
    itemsArea.ScrollBarThickness = 8
    itemsArea.CanvasSize = UDim2.new(0, 0, 2, 0)
    itemsArea.ZIndex = 304
    itemsArea.Parent = sideFrame
    
    self._utilities.CreateCorner(itemsArea, 8)
    
    local itemsGrid = Instance.new("UIGridLayout")
    itemsGrid.CellPadding = UDim2.new(0, 5, 0, 5)
    itemsGrid.CellSize = UDim2.new(0, TRADE_SLOT_SIZE.X, 0, TRADE_SLOT_SIZE.Y)
    itemsGrid.FillDirection = Enum.FillDirection.Horizontal
    itemsGrid.Parent = itemsArea
    
    -- Update canvas size
    itemsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        itemsArea.CanvasSize = UDim2.new(0, 0, 0, itemsGrid.AbsoluteContentSize.Y + 20)
    end)
    
    -- Currency area
    local currencyFrame = self:CreateCurrencyArea(sideFrame, isYou)
    
    -- Status indicator
    local statusLabel = self._uiFactory:CreateLabel(sideFrame, {
        text = "Not Ready",
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 1, -40),
        textColor = STATUS_COLORS.notReady,
        font = self._config.FONTS.Secondary,
        zIndex = 305
    })
    
    if isYou then
        self.StatusLabels.You = statusLabel
        
        -- Add pet button
        local addPetButton = self._uiFactory:CreateButton(sideFrame, {
            text = "+ Add Pet",
            size = UDim2.new(0, 80, 0, 30),
            position = UDim2.new(0, 10, 0, 50),
            backgroundColor = self._config.COLORS.Primary,
            zIndex = 310,
            callback = function()
                self:OpenPetSelector()
            end
        })
    else
        self.StatusLabels.Them = statusLabel
    end
    
    return sideFrame
end

function TradingUI:CreateCurrencyArea(parent: Frame, isYou: boolean): Frame
    local currencyFrame = Instance.new("Frame")
    currencyFrame.Name = "CurrencyFrame"
    currencyFrame.Size = UDim2.new(1, -20, 0, 40)
    currencyFrame.Position = UDim2.new(0, 10, 1, -90)
    currencyFrame.BackgroundColor3 = self._config.COLORS.Background
    currencyFrame.ZIndex = 304
    currencyFrame.Parent = parent
    
    self._utilities.CreateCorner(currencyFrame, 8)
    self._utilities.CreatePadding(currencyFrame, 10)
    
    local currencyLayout = Instance.new("UIListLayout")
    currencyLayout.FillDirection = Enum.FillDirection.Horizontal
    currencyLayout.Padding = UDim.new(0, 10)
    currencyLayout.Parent = currencyFrame
    
    -- Coins
    local coinsContainer = self:CreateCurrencyInput(currencyFrame, "coins", 
        self._config.ICONS.Coin, isYou)
    
    -- Gems
    local gemsContainer = self:CreateCurrencyInput(currencyFrame, "gems", 
        self._config.ICONS.Gem, isYou)
    
    return currencyFrame
end

function TradingUI:CreateCurrencyInput(parent: Frame, currencyType: string, 
                                      icon: string, isEditable: boolean): Frame
    local container = Instance.new("Frame")
    container.Name = currencyType .. "Container"
    container.Size = UDim2.new(0.5, -5, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 20, 0, 20)
    iconLabel.Position = UDim2.new(0, 0, 0.5, -10)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = icon
    iconLabel.Parent = container
    
    if isEditable then
        local input = self._uiFactory:CreateTextBox(container, {
            placeholder = "0",
            size = UDim2.new(1, -25, 1, 0),
            position = UDim2.new(0, 25, 0, 0),
            textColor = self._config.COLORS.Dark,
            font = self._config.FONTS.Numbers,
            callback = function(text)
                local amount = tonumber(text) or 0
                self:UpdateCurrency(currencyType, amount)
            end
        })
        input.Text = "0"
    else
        local label = self._uiFactory:CreateLabel(container, {
            text = "0",
            size = UDim2.new(1, -25, 1, 0),
            position = UDim2.new(0, 25, 0, 0),
            textXAlignment = Enum.TextXAlignment.Left,
            font = self._config.FONTS.Numbers
        })
    end
    
    return container
end

function TradingUI:CreateTradeControls()
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(1, -20, 0, 50)
    controlsFrame.Position = UDim2.new(0, 10, 1, -60)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.ZIndex = 302
    controlsFrame.Parent = self.TradeWindow
    
    -- Cancel button
    local cancelButton = self._uiFactory:CreateButton(controlsFrame, {
        text = "Cancel",
        size = UDim2.new(0, 100, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:CancelTrade()
        end
    })
    
    -- Ready button
    local readyButton = self._uiFactory:CreateButton(controlsFrame, {
        text = "Ready",
        size = UDim2.new(0, 100, 1, 0),
        position = UDim2.new(0.5, -50, 0, 0),
        backgroundColor = self._config.COLORS.Warning,
        callback = function()
            self:ToggleReady()
        end
    })
    
    -- Confirm button (hidden initially)
    local confirmButton = self._uiFactory:CreateButton(controlsFrame, {
        text = "Confirm Trade",
        size = UDim2.new(0, 150, 1, 0),
        position = UDim2.new(0.75, -75, 0, 0),
        backgroundColor = self._config.COLORS.Success,
        visible = false,
        callback = function()
            self:ConfirmTrade()
        end
    })
    
    self.TradeControls = {
        ReadyButton = readyButton,
        ConfirmButton = confirmButton
    }
end

-- ========================================
-- PET SELECTOR
-- ========================================

function TradingUI:OpenPetSelector()
    -- Create selector
    local selector = Instance.new("Frame")
    selector.Name = "PetSelector"
    selector.Size = UDim2.new(0, SELECTOR_SIZE.X, 0, SELECTOR_SIZE.Y)
    selector.Position = UDim2.new(0.5, -SELECTOR_SIZE.X/2, 0.5, -SELECTOR_SIZE.Y/2)
    selector.BackgroundColor3 = self._config.COLORS.Background
    selector.ZIndex = 400
    selector.Parent = self.TradeWindow.Parent
    
    self._utilities.CreateCorner(selector, 12)
    
    self.PetSelector = selector
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = self._config.COLORS.Primary
    header.ZIndex = 401
    header.Parent = selector
    
    self._utilities.CreateCorner(header, 12)
    
    local titleLabel = self._uiFactory:CreateLabel(header, {
        text = "Select Pets to Trade",
        size = UDim2.new(1, -60, 1, 0),
        position = UDim2.new(0, 20, 0, 0),
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.White,
        zIndex = 402
    })
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(header, {
        text = "✖",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -45, 0, 5),
        backgroundColor = Color3.new(1, 1, 1),
        backgroundTransparency = 0.9,
        textColor = self._config.COLORS.White,
        zIndex = 402,
        callback = function()
            selector:Destroy()
            self.PetSelector = nil
        end
    })
    
    -- Pet grid
    local scrollFrame = self._uiFactory:CreateScrollingFrame(selector, {
        size = UDim2.new(1, -20, 1, -70),
        position = UDim2.new(0, 10, 0, 60)
    })
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.Parent = scrollFrame
    
    -- Load pets
    self:LoadPetsForSelection(scrollFrame)
    
    -- Update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function TradingUI:LoadPetsForSelection(parent: ScrollingFrame)
    local playerData = self._dataCache and self._dataCache:Get() or {}
    if not playerData.pets then return end
    
    local pets = {}
    
    -- Get available pets (not equipped, not locked, not already in trade)
    for uniqueId, pet in pairs(playerData.pets) do
        if type(pet) == "table" and 
           not pet.equipped and 
           not pet.locked and
           not self.SelectedPets[uniqueId] then
            pet.uniqueId = uniqueId
            table.insert(pets, pet)
        end
    end
    
    -- Sort by level
    table.sort(pets, function(a, b)
        return (a.level or 1) > (b.level or 1)
    end)
    
    -- Create cards
    for _, pet in ipairs(pets) do
        local petData = self._dataCache and self._dataCache:Get("petDatabase." .. pet.petId) or
                       {displayName = "Unknown", rarity = 1}
        
        self:CreatePetSelectionCard(parent, pet, petData)
    end
end

function TradingUI:CreatePetSelectionCard(parent: ScrollingFrame, petInstance: table, petData: table): Frame
    local card = Instance.new("Frame")
    card.Name = petInstance.uniqueId
    card.BackgroundColor3 = self._config.COLORS.Surface
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 8)
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, -10, 1, -30)
    petImage.Position = UDim2.new(0, 5, 0, 5)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = card
    
    -- Name label
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = petInstance.nickname or petData.displayName or "Unknown",
        size = UDim2.new(1, -4, 0, 20),
        position = UDim2.new(0, 2, 1, -22),
        textScaled = true,
        textSize = 12
    })
    
    -- Level badge
    local levelBadge = Instance.new("Frame")
    levelBadge.Size = UDim2.new(0, 30, 0, 20)
    levelBadge.Position = UDim2.new(0, 2, 0, 2)
    levelBadge.BackgroundColor3 = self._config.COLORS.Dark
    levelBadge.Parent = card
    
    self._utilities.CreateCorner(levelBadge, 4)
    
    local levelLabel = self._uiFactory:CreateLabel(levelBadge, {
        text = "Lv." .. tostring(petInstance.level or 1),
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        textSize = 10
    })
    
    -- Rarity indicator
    local rarityBar = Instance.new("Frame")
    rarityBar.Size = UDim2.new(1, 0, 0, 3)
    rarityBar.Position = UDim2.new(0, 0, 1, -3)
    rarityBar.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    rarityBar.BorderSizePixel = 0
    rarityBar.Parent = card
    
    -- Selection overlay
    local selectionOverlay = Instance.new("Frame")
    selectionOverlay.Name = "SelectionOverlay"
    selectionOverlay.Size = UDim2.new(1, 0, 1, 0)
    selectionOverlay.BackgroundColor3 = self._config.COLORS.Success
    selectionOverlay.BackgroundTransparency = 1
    selectionOverlay.Visible = false
    selectionOverlay.Parent = card
    
    self._utilities.CreateCorner(selectionOverlay, 8)
    
    local checkmark = self._uiFactory:CreateLabel(selectionOverlay, {
        text = "✓",
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        textSize = 30
    })
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        -- Check trade limit
        if #self.SelectedPets >= MAX_TRADE_ITEMS then
            self._notificationSystem:SendNotification("Trade Limit", 
                "Maximum " .. MAX_TRADE_ITEMS .. " items per trade", "error")
            return
        end
        
        -- Add to trade
        self:AddPetToTrade(petInstance, petData)
        
        -- Update visual
        selectionOverlay.Visible = true
        selectionOverlay.BackgroundTransparency = 0.7
        
        -- Close selector
        if self.PetSelector then
            self.PetSelector:Destroy()
            self.PetSelector = nil
        end
    end)
    
    return card
end

-- ========================================
-- TRADE ACTIONS
-- ========================================

function TradingUI:AddPetToTrade(petInstance: table, petData: table)
    if not self.CurrentTrade then return end
    
    -- Add to selected pets
    self.SelectedPets[petInstance.uniqueId] = {
        instance = petInstance,
        data = petData
    }
    
    -- Send update to server
    if self._remoteManager then
        self._remoteManager:FireServer("UpdateTradeOffer", {
            tradeId = self.CurrentTrade.tradeId,
            action = "addPet",
            petId = petInstance.uniqueId
        })
    end
    
    -- Update display
    self:UpdateTradeDisplay()
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
end

function TradingUI:RemovePetFromTrade(uniqueId: string)
    if not self.CurrentTrade or not self.SelectedPets[uniqueId] then return end
    
    -- Remove from selected
    self.SelectedPets[uniqueId] = nil
    
    -- Send update to server
    if self._remoteManager then
        self._remoteManager:FireServer("UpdateTradeOffer", {
            tradeId = self.CurrentTrade.tradeId,
            action = "removePet",
            petId = uniqueId
        })
    end
    
    -- Update display
    self:UpdateTradeDisplay()
end

function TradingUI:UpdateCurrency(currencyType: string, amount: number)
    if not self.CurrentTrade then return end
    
    -- Validate amount
    local playerData = self._dataCache and self._dataCache:Get() or {}
    local maxAmount = playerData.currencies and playerData.currencies[currencyType] or 0
    amount = math.clamp(amount, 0, maxAmount)
    
    -- Update local state
    self.CurrencyAmounts[currencyType] = amount
    
    -- Send update to server
    if self._remoteManager then
        self._remoteManager:FireServer("UpdateTradeOffer", {
            tradeId = self.CurrentTrade.tradeId,
            action = "updateCurrency",
            currencyType = currencyType,
            amount = amount
        })
    end
end

function TradingUI:ToggleReady()
    if not self.CurrentTrade then return end
    
    -- Send ready state to server
    if self._remoteManager then
        self._remoteManager:FireServer("UpdateTradeReady", {
            tradeId = self.CurrentTrade.tradeId,
            ready = not self.CurrentTrade.yourReady
        })
    end
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
end

function TradingUI:ConfirmTrade()
    if not self.CurrentTrade or self.CountdownActive then return end
    
    -- Start countdown
    self.CountdownActive = true
    self:StartTradeCountdown()
    
    -- Send confirmation to server
    if self._remoteManager then
        self._remoteManager:FireServer("ConfirmTrade", {
            tradeId = self.CurrentTrade.tradeId
        })
    end
end

function TradingUI:CancelTrade()
    if not self.CurrentTrade then return end
    
    -- Send cancel to server
    if self._remoteManager then
        self._remoteManager:FireServer("CancelTrade", {
            tradeId = self.CurrentTrade.tradeId
        })
    end
    
    -- Close window
    self:CloseTradeWindow()
end

-- ========================================
-- TRADE DISPLAY
-- ========================================

function TradingUI:UpdateTradeDisplay()
    if not self.CurrentTrade or not self.TradeSides.You then return end
    
    -- Update your side
    self:UpdateTradeSideDisplay(self.TradeSides.You:FindFirstChild("ItemsArea"), 
                               self.CurrentTrade.yourOffer, true)
    
    -- Update their side
    self:UpdateTradeSideDisplay(self.TradeSides.Them:FindFirstChild("ItemsArea"), 
                               self.CurrentTrade.theirOffer, false)
    
    -- Update status labels
    if self.StatusLabels.You then
        self.StatusLabels.You.Text = self.CurrentTrade.yourReady and "Ready" or "Not Ready"
        self.StatusLabels.You.TextColor3 = self.CurrentTrade.yourReady and 
                                          STATUS_COLORS.ready or STATUS_COLORS.notReady
    end
    
    if self.StatusLabels.Them then
        self.StatusLabels.Them.Text = self.CurrentTrade.theirReady and "Ready" or "Not Ready"
        self.StatusLabels.Them.TextColor3 = self.CurrentTrade.theirReady and 
                                           STATUS_COLORS.ready or STATUS_COLORS.notReady
    end
    
    -- Update buttons
    if self.TradeControls.ReadyButton then
        self.TradeControls.ReadyButton.Text = self.CurrentTrade.yourReady and "Not Ready" or "Ready"
        self.TradeControls.ReadyButton.BackgroundColor3 = self.CurrentTrade.yourReady and 
                                                         self._config.COLORS.Secondary or 
                                                         self._config.COLORS.Warning
    end
    
    -- Show confirm button if both ready
    if self.TradeControls.ConfirmButton then
        self.TradeControls.ConfirmButton.Visible = self.CurrentTrade.yourReady and 
                                                   self.CurrentTrade.theirReady
    end
    
    -- Update currency displays
    self:UpdateCurrencyDisplays()
end

function TradingUI:UpdateTradeSideDisplay(itemsArea: ScrollingFrame?, items: {TradeItem}, isYourSide: boolean)
    if not itemsArea then return end
    
    -- Clear existing items
    for _, child in ipairs(itemsArea:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Display items
    for _, item in ipairs(items) do
        if item.type == "pet" then
            self:CreateTradeItemDisplay(itemsArea, item, isYourSide)
        end
    end
end

function TradingUI:CreateTradeItemDisplay(parent: ScrollingFrame, item: TradeItem, canRemove: boolean): Frame
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = item.id or "Item"
    itemFrame.BackgroundColor3 = self._config.COLORS.Surface
    itemFrame.Parent = parent
    
    self._utilities.CreateCorner(itemFrame, 8)
    
    -- Get pet data
    local petData = item.data or {}
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, -10, 1, -25)
    petImage.Position = UDim2.new(0, 5, 0, 5)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = itemFrame
    
    -- Name label
    local nameLabel = self._uiFactory:CreateLabel(itemFrame, {
        text = petData.displayName or "Unknown",
        size = UDim2.new(1, -4, 0, 20),
        position = UDim2.new(0, 2, 1, -22),
        textScaled = true,
        textSize = 10
    })
    
    -- Rarity indicator
    local rarityBar = Instance.new("Frame")
    rarityBar.Size = UDim2.new(1, 0, 0, 3)
    rarityBar.Position = UDim2.new(0, 0, 1, -3)
    rarityBar.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    rarityBar.BorderSizePixel = 0
    rarityBar.Parent = itemFrame
    
    -- Remove button for your side
    if canRemove then
        local removeButton = Instance.new("TextButton")
        removeButton.Size = UDim2.new(0, 20, 0, 20)
        removeButton.Position = UDim2.new(1, -22, 0, 2)
        removeButton.BackgroundColor3 = self._config.COLORS.Error
        removeButton.Text = "✖"
        removeButton.TextColor3 = self._config.COLORS.White
        removeButton.Font = Enum.Font.SourceSansBold
        removeButton.TextSize = 14
        removeButton.Parent = itemFrame
        
        self._utilities.CreateCorner(removeButton, 4)
        
        removeButton.MouseButton1Click:Connect(function()
            self:RemovePetFromTrade(item.id)
        end)
    end
    
    return itemFrame
end

function TradingUI:UpdateCurrencyDisplays()
    -- Update your currency inputs/displays
    local yourCurrencyFrame = self.TradeSides.You:FindFirstChild("CurrencyFrame")
    if yourCurrencyFrame then
        -- Currency values are already updated via text box callbacks
    end
    
    -- Update their currency display
    local theirCurrencyFrame = self.TradeSides.Them:FindFirstChild("CurrencyFrame")
    if theirCurrencyFrame then
        for _, item in ipairs(self.CurrentTrade.theirOffer) do
            if item.type == "currency" then
                local container = theirCurrencyFrame:FindFirstChild(item.id .. "Container")
                if container then
                    local label = container:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text = self._utilities.FormatNumber(item.amount or 0)
                    end
                end
            end
        end
    end
end

-- ========================================
-- COUNTDOWN
-- ========================================

function TradingUI:StartTradeCountdown()
    local countdownFrame = Instance.new("Frame")
    countdownFrame.Size = UDim2.new(0, 200, 0, 100)
    countdownFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
    countdownFrame.BackgroundColor3 = self._config.COLORS.Dark
    countdownFrame.ZIndex = 500
    countdownFrame.Parent = self.TradeWindow
    
    self._utilities.CreateCorner(countdownFrame, 12)
    
    local countdownLabel = self._uiFactory:CreateLabel(countdownFrame, {
        text = "Trading in " .. COUNTDOWN_TIME,
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        font = self._config.FONTS.Display,
        textSize = 24,
        zIndex = 501
    })
    
    -- Countdown animation
    for i = COUNTDOWN_TIME, 1, -1 do
        task.wait(1)
        if countdownLabel and countdownLabel.Parent then
            countdownLabel.Text = "Trading in " .. i
            
            -- Play tick sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("Tick")
            end
        else
            break
        end
    end
    
    -- Clean up
    if countdownFrame then
        countdownFrame:Destroy()
    end
    
    self.CountdownActive = false
end

-- ========================================
-- TRADE COMPLETION
-- ========================================

function TradingUI:HandleTradeComplete(data: {tradeId: string, success: boolean})
    if data.success then
        -- Add to history
        self:AddToTradeHistory({
            partner = self.CurrentTrade.partner.Name,
            partnerId = self.CurrentTrade.partner.UserId,
            timestamp = os.time(),
            yourOffer = self.CurrentTrade.yourOffer,
            theirOffer = self.CurrentTrade.theirOffer,
            status = "completed"
        })
        
        -- Show success notification
        self._notificationSystem:SendNotification("Trade Complete!", 
            "Your trade was successful!", "success")
        
        -- Play success sound
        if self._soundSystem then
            self._soundSystem:PlayUISound("Success")
        end
    else
        self._notificationSystem:SendNotification("Trade Failed", 
            "The trade could not be completed", "error")
    end
    
    -- Close window
    self:CloseTradeWindow()
end

function TradingUI:CloseTradeWindow()
    if self.TradeOverlay then
        -- Unregister from window manager
        if self._windowManager then
            self._windowManager:UnregisterOverlay(self.TradeOverlay)
        end
        
        -- Animate out
        if self.TradeWindow then
            self._utilities.Tween(self.TradeWindow, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }, self._config.TWEEN_INFO.Normal)
        end
        
        self._utilities.Tween(self.TradeOverlay, {
            BackgroundTransparency = 1
        }, self._config.TWEEN_INFO.Normal)
        
        task.wait(0.3)
        self.TradeOverlay:Destroy()
    end
    
    -- Clear references
    self.TradeOverlay = nil
    self.TradeWindow = nil
    self.CurrentTrade = nil
    self.SelectedPets = {}
    self.CurrencyAmounts = {coins = 0, gems = 0}
    self.TradeSides = {}
    self.StatusLabels = {}
    self.TradeControls = {}
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("CloseMenu")
    end
end

-- ========================================
-- TRADE REQUESTS
-- ========================================

function TradingUI:HandleTradeRequest(fromPlayer: Player)
    -- Create request notification with actions
    self._notificationSystem:SendNotification(
        "Trade Request",
        fromPlayer.DisplayName .. " wants to trade with you!",
        "info",
        10,
        {
            {
                text = "Accept",
                callback = function()
                    self:AcceptTradeRequest(fromPlayer)
                end
            },
            {
                text = "Decline",
                callback = function()
                    self:DeclineTradeRequest(fromPlayer)
                end
            }
        }
    )
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Notification")
    end
end

function TradingUI:AcceptTradeRequest(fromPlayer: Player)
    if self._remoteManager then
        self._remoteManager:FireServer("RespondToTrade", {
            from = fromPlayer,
            accept = true
        })
    end
end

function TradingUI:DeclineTradeRequest(fromPlayer: Player)
    if self._remoteManager then
        self._remoteManager:FireServer("RespondToTrade", {
            from = fromPlayer,
            accept = false
        })
    end
end

-- ========================================
-- TRADE HISTORY
-- ========================================

function TradingUI:LoadTradeHistory()
    -- Load from local storage or data cache
    local savedHistory = self._dataCache and self._dataCache:Get("tradeHistory") or {}
    self.TradeHistory = savedHistory
    
    -- Limit history size
    while #self.TradeHistory > TRADE_HISTORY_LIMIT do
        table.remove(self.TradeHistory, #self.TradeHistory)
    end
end

function TradingUI:SaveTradeHistory()
    if self._dataCache then
        self._dataCache:Set("tradeHistory", self.TradeHistory)
    end
end

function TradingUI:AddToTradeHistory(trade: TradeHistory)
    -- Add to beginning
    table.insert(self.TradeHistory, 1, trade)
    
    -- Limit size
    while #self.TradeHistory > TRADE_HISTORY_LIMIT do
        table.remove(self.TradeHistory, #self.TradeHistory)
    end
    
    -- Save
    self:SaveTradeHistory()
    
    -- Refresh displays
    self:RefreshTradeHistory()
    self:RefreshRecentTrades()
end

function TradingUI:RefreshRecentTrades()
    if not self.RecentTradesFrame then return end
    
    -- Clear existing
    for _, child in ipairs(self.RecentTradesFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get unique recent partners
    local recentPartners = {}
    local partnerMap = {}
    
    for _, trade in ipairs(self.TradeHistory) do
        if not partnerMap[trade.partnerId] then
            partnerMap[trade.partnerId] = true
            table.insert(recentPartners, {
                name = trade.partner,
                userId = trade.partnerId,
                lastTrade = trade.timestamp
            })
            
            if #recentPartners >= 10 then
                break
            end
        end
    end
    
    -- Display recent partners
    if #recentPartners == 0 then
        local emptyLabel = self._uiFactory:CreateLabel(self.RecentTradesFrame, {
            text = "No recent trades",
            size = UDim2.new(1, 0, 0, 50),
            position = UDim2.new(0, 0, 0, 10),
            textColor = self._config.COLORS.TextSecondary
        })
    else
        for i, partner in ipairs(recentPartners) do
            self:CreateRecentPartnerEntry(partner, i)
        end
    end
end

function TradingUI:CreateRecentPartnerEntry(partner: table, index: number)
    local entryFrame = Instance.new("Frame")
    entryFrame.Size = UDim2.new(1, -10, 0, 50)
    entryFrame.Position = UDim2.new(0, 5, 0, (index - 1) * 55 + 5)
    entryFrame.BackgroundColor3 = self._config.COLORS.Surface
    entryFrame.Parent = self.RecentTradesFrame
    
    self._utilities.CreateCorner(entryFrame, 8)
    self._utilities.CreatePadding(entryFrame, 10)
    
    -- Player name
    local nameLabel = self._uiFactory:CreateLabel(entryFrame, {
        text = partner.name,
        size = UDim2.new(0.5, 0, 0.5, 0),
        position = UDim2.new(0, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary
    })
    
    -- Last trade time
    local timeLabel = self._uiFactory:CreateLabel(entryFrame, {
        text = self:FormatTradeTime(partner.lastTrade),
        size = UDim2.new(0.5, 0, 0.5, 0),
        position = UDim2.new(0, 0, 0.5, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary,
        textSize = 12
    })
    
    -- Trade button
    local tradeButton = self._uiFactory:CreateButton(entryFrame, {
        text = "Trade",
        size = UDim2.new(0, 60, 0, 30),
        position = UDim2.new(1, -65, 0.5, -15),
        backgroundColor = self._config.COLORS.Primary,
        callback = function()
            local player = Services.Players:GetPlayerByUserId(partner.userId)
            if player then
                self:SendTradeRequest(player)
            else
                self._notificationSystem:SendNotification("Error", 
                    partner.name .. " is no longer in the game", "error")
            end
        end
    })
    
    -- Update canvas size
    self.RecentTradesFrame.CanvasSize = UDim2.new(0, 0, 0, #recentPartners * 55 + 10)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function TradingUI:FormatTradeTime(timestamp: number): string
    local now = os.time()
    local diff = now - timestamp
    
    if diff < 60 then
        return "Just now"
    elseif diff < 3600 then
        return math.floor(diff / 60) .. " minutes ago"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. " hours ago"
    else
        return math.floor(diff / 86400) .. " days ago"
    end
end

function TradingUI:GetTradeSummary(trade: TradeHistory): string
    local yourPets = 0
    local theirPets = 0
    local yourCoins = 0
    local yourGems = 0
    local theirCoins = 0
    local theirGems = 0
    
    -- Count items
    for _, item in ipairs(trade.yourOffer) do
        if item.type == "pet" then
            yourPets = yourPets + 1
        elseif item.type == "currency" then
            if item.id == "coins" then
                yourCoins = item.amount or 0
            elseif item.id == "gems" then
                yourGems = item.amount or 0
            end
        end
    end
    
    for _, item in ipairs(trade.theirOffer) do
        if item.type == "pet" then
            theirPets = theirPets + 1
        elseif item.type == "currency" then
            if item.id == "coins" then
                theirCoins = item.amount or 0
            elseif item.id == "gems" then
                theirGems = item.amount or 0
            end
        end
    end
    
    -- Build summary
    local parts = {}
    
    if yourPets > 0 then
        table.insert(parts, "You: " .. yourPets .. " pets")
    end
    if yourCoins > 0 then
        table.insert(parts, self._utilities.FormatNumber(yourCoins) .. " coins")
    end
    if yourGems > 0 then
        table.insert(parts, self._utilities.FormatNumber(yourGems) .. " gems")
    end
    
    if theirPets > 0 then
        table.insert(parts, "Them: " .. theirPets .. " pets")
    end
    if theirCoins > 0 then
        table.insert(parts, self._utilities.FormatNumber(theirCoins) .. " coins")
    end
    if theirGems > 0 then
        table.insert(parts, self._utilities.FormatNumber(theirGems) .. " gems")
    end
    
    return table.concat(parts, " | ")
end

-- ========================================
-- CLEANUP
-- ========================================

function TradingUI:Destroy()
    -- Close any open windows
    self:Close()
    
    -- Cancel pending operations
    if self.SearchDebounce then
        task.cancel(self.SearchDebounce)
    end
    
    -- Save history
    self:SaveTradeHistory()
    
    -- Clear references
    self.Frame = nil
    self.TabFrames = {}
    self.SearchResultsFrame = nil
    self.TradeOverlay = nil
    self.TradeWindow = nil
    self.PetSelector = nil
    self.CurrentTrade = nil
    self.TradeControls = {}
    self.StatusLabels = {}
    self.TradeSides = {}
end

return TradingUI