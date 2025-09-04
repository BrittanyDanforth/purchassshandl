-- ========================================
-- TRADING UI MODULE
-- ========================================
UIModules.TradingUI = {}

function UIModules.TradingUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main trading frame
    local tradingFrame = UIComponents:CreateFrame(MainUI.MainContainer, "TradingFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    tradingFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = tradingFrame
    
    -- Header
    local header = UIComponents:CreateFrame(tradingFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "🤝 Trading Center 🤝", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Create tabs
    local tabs = {
        {
            Name = "Send Trade",
            Init = function(parent)
                self:CreateSendTradeView(parent)
            end
        },
        {
            Name = "Active Trades",
            Init = function(parent)
                self:CreateActiveTradesView(parent)
            end
        },
        {
            Name = "Trade History",
            Init = function(parent)
                self:CreateTradeHistoryView(parent)
            end
        }
    }
    
    local tabContainer, tabFrames = UIComponents:CreateTab(tradingFrame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    self.TabFrames = tabFrames
end

function UIModules.TradingUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.TradingUI:CreateSendTradeView(parent)
    -- Player search
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -20, 0, 50)
    searchFrame.Position = UDim2.new(0, 10, 0, 10)
    searchFrame.BackgroundTransparency = 1
    searchFrame.Parent = parent
    
    local searchBox = UIComponents:CreateTextBox(searchFrame, "Enter player name...", UDim2.new(0.7, -10, 1, 0), UDim2.new(0, 0, 0, 0))
    
    local searchButton = UIComponents:CreateButton(searchFrame, "Search", UDim2.new(0.3, -10, 1, 0), UDim2.new(0.7, 10, 0, 0), function()
        self:SearchPlayer(searchBox.Text)
    end)
    
    -- Search results
    local resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "SearchResults"
    resultsFrame.Size = UDim2.new(1, -20, 0, 200)
    resultsFrame.Position = UDim2.new(0, 10, 0, 70)
    resultsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    resultsFrame.Parent = parent
    
    Utilities:CreateCorner(resultsFrame, 12)
    
    local resultsScroll = UIComponents:CreateScrollingFrame(resultsFrame)
    
    local resultsLayout = Instance.new("UIListLayout")
    resultsLayout.FillDirection = Enum.FillDirection.Vertical
    resultsLayout.Padding = UDim.new(0, 5)
    resultsLayout.Parent = resultsScroll
    
    Utilities:CreatePadding(resultsScroll, 10)
    
    self.SearchResultsFrame = resultsScroll
    
    -- Recent trades
    local recentFrame = Instance.new("Frame")
    recentFrame.Size = UDim2.new(1, -20, 1, -290)
    recentFrame.Position = UDim2.new(0, 10, 0, 280)
    recentFrame.BackgroundTransparency = 1
    recentFrame.Parent = parent
    
    local recentLabel = UIComponents:CreateLabel(recentFrame, "Recent Trading Partners", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 18)
    recentLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local recentScroll = UIComponents:CreateScrollingFrame(recentFrame, UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40))
    
    -- TODO: Load recent partners
end

function UIModules.TradingUI:SearchPlayer(username)
    -- Clear previous results
    for _, child in ipairs(self.SearchResultsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Search for players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and string.find(string.lower(player.Name), string.lower(username)) then
            self:CreatePlayerResult(player)
        end
    end
end

function UIModules.TradingUI:CreatePlayerResult(player)
    local resultFrame = Instance.new("Frame")
    resultFrame.Size = UDim2.new(1, -10, 0, 60)
    resultFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    resultFrame.Parent = self.SearchResultsFrame
    
    Utilities:CreateCorner(resultFrame, 8)
    Utilities:CreatePadding(resultFrame, 10)
    
    -- Player avatar
    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 40, 0, 40)
    avatarImage.Position = UDim2.new(0, 0, 0.5, -20)
    avatarImage.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    avatarImage.Image = Services.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    avatarImage.Parent = resultFrame
    
    Utilities:CreateCorner(avatarImage, 20)
    
    -- Player name
    local nameLabel = UIComponents:CreateLabel(resultFrame, player.DisplayName, UDim2.new(0.5, -60, 1, 0), UDim2.new(0, 50, 0, 0), 16)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Trade button
    local tradeButton = UIComponents:CreateButton(resultFrame, "Send Trade", UDim2.new(0, 100, 0, 35), UDim2.new(1, -110, 0.5, -17.5), function()
        self:InitiateTrade(player)
    end)
    tradeButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    
    return resultFrame
end

function UIModules.TradingUI:InitiateTrade(targetPlayer)
    local result = RemoteFunctions.RequestTrade:InvokeServer(targetPlayer)
    
    if result.success then
        self:OpenTradeWindow(result.trade)
    else
        NotificationSystem:SendNotification("Trade Failed", result.error or "Failed to initiate trade", "error")
    end
end

function UIModules.TradingUI:OpenTradeWindow(trade)
    -- Create trade overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "TradeOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 300
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Trade window
    local tradeWindow = Instance.new("Frame")
    tradeWindow.Name = "TradeWindow"
    tradeWindow.Size = UDim2.new(0, 900, 0, 600)
    tradeWindow.Position = UDim2.new(0.5, -450, 0.5, -300)
    tradeWindow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    tradeWindow.ZIndex = 301
    tradeWindow.Parent = overlay
    
    Utilities:CreateCorner(tradeWindow, 20)
    Utilities:CreateShadow(tradeWindow, 0.5, 30)
    
    -- Store trade data
    self.CurrentTrade = trade
    self.TradeOverlay = overlay
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 302
    header.Parent = tradeWindow
    
    local headerCorner = Utilities:CreateCorner(header, 20)
    
    local bottomCorner = Instance.new("Frame")
    bottomCorner.Size = UDim2.new(1, 0, 0, 20)
    bottomCorner.Position = UDim2.new(0, 0, 1, -20)
    bottomCorner.BackgroundColor3 = header.BackgroundColor3
    bottomCorner.BorderSizePixel = 0
    bottomCorner.ZIndex = 302
    bottomCorner.Parent = header
    
    -- Get other player
    local otherPlayer = trade.player1.userId == LocalPlayer.UserId and trade.player2 or trade.player1
    
    local titleLabel = UIComponents:CreateLabel(header, "Trading with " .. Services.Players:GetNameFromUserIdAsync(otherPlayer.userId), 
        UDim2.new(1, -60, 1, 0), UDim2.new(0, 20, 0, 0), 20)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    titleLabel.ZIndex = 303
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 24
    closeButton.ZIndex = 303
    closeButton.Parent = header
    
    closeButton.MouseButton1Click:Connect(function()
        self:CancelTrade()
    end)
    
    -- Trade content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -80)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundTransparency = 1
    content.ZIndex = 302
    content.Parent = tradeWindow
    
    -- Your side
    local yourSide = self:CreateTradeSide(content, "You", true, UDim2.new(0.48, -5, 1, -60), UDim2.new(0, 0, 0, 0))
    
    -- Their side
    local theirSide = self:CreateTradeSide(content, otherPlayer.player.Name, false, UDim2.new(0.48, -5, 1, -60), UDim2.new(0.52, 5, 0, 0))
    
    -- Trade controls
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(1, 0, 0, 50)
    controlsFrame.Position = UDim2.new(0, 0, 1, -50)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.ZIndex = 302
    controlsFrame.Parent = content
    
    -- Ready button
    local readyButton = UIComponents:CreateButton(controlsFrame, "Ready", UDim2.new(0, 150, 1, 0), UDim2.new(0.25, -75, 0, 0), function()
        self:ToggleReady()
    end)
    readyButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
    
    -- Confirm button
    local confirmButton = UIComponents:CreateButton(controlsFrame, "Confirm Trade", UDim2.new(0, 150, 1, 0), UDim2.new(0.75, -75, 0, 0), function()
        self:ConfirmTrade()
    end)
    confirmButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    confirmButton.Visible = false
    
    self.TradeControls = {
        ReadyButton = readyButton,
        ConfirmButton = confirmButton
    }
    
    -- Status indicators
    local yourStatus = UIComponents:CreateLabel(yourSide, "Not Ready", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 1, -40), 16)
    yourStatus.TextColor3 = CLIENT_CONFIG.COLORS.Error
    yourStatus.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local theirStatus = UIComponents:CreateLabel(theirSide, "Not Ready", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 1, -40), 16)
    theirStatus.TextColor3 = CLIENT_CONFIG.COLORS.Error
    theirStatus.Font = CLIENT_CONFIG.FONTS.Secondary
    
    self.StatusLabels = {
        You = yourStatus,
        Them = theirStatus
    }
    
    -- Update trade display
    self:UpdateTradeDisplay()
end

function UIModules.TradingUI:CreateTradeSide(parent, playerName, isYou, size, position)
    local sideFrame = Instance.new("Frame")
    sideFrame.Size = size
    sideFrame.Position = position
    sideFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    sideFrame.ZIndex = 303
    sideFrame.Parent = parent
    
    Utilities:CreateCorner(sideFrame, 12)
    
    -- Header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 40)
    headerFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    headerFrame.ZIndex = 304
    headerFrame.Parent = sideFrame
    
    local headerCorner = Utilities:CreateCorner(headerFrame, 12)
    
    local bottomRect = Instance.new("Frame")
    bottomRect.Size = UDim2.new(1, 0, 0, 12)
    bottomRect.Position = UDim2.new(0, 0, 1, -12)
    bottomRect.BackgroundColor3 = headerFrame.BackgroundColor3
    bottomRect.BorderSizePixel = 0
    bottomRect.ZIndex = 304
    bottomRect.Parent = headerFrame
    
    local playerLabel = UIComponents:CreateLabel(headerFrame, playerName, UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), 18)
    playerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    playerLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    playerLabel.ZIndex = 305
    
    -- Items area
    local itemsArea = Instance.new("ScrollingFrame")
    itemsArea.Size = UDim2.new(1, -20, 1, -140)
    itemsArea.Position = UDim2.new(0, 10, 0, 50)
    itemsArea.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    itemsArea.ScrollBarThickness = 8
    itemsArea.CanvasSize = UDim2.new(0, 0, 2, 0)
    itemsArea.ZIndex = 304
    itemsArea.Parent = sideFrame
    
    Utilities:CreateCorner(itemsArea, 8)
    
    local itemsGrid = Instance.new("UIGridLayout")
    itemsGrid.CellPadding = UDim2.new(0, 5, 0, 5)
    itemsGrid.CellSize = UDim2.new(0, 80, 0, 100)
    itemsGrid.FillDirection = Enum.FillDirection.Horizontal
    itemsGrid.Parent = itemsArea
    
    -- Currency area
    local currencyFrame = Instance.new("Frame")
    currencyFrame.Size = UDim2.new(1, -20, 0, 40)
    currencyFrame.Position = UDim2.new(0, 10, 1, -90)
    currencyFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    currencyFrame.ZIndex = 304
    currencyFrame.Parent = sideFrame
    
    Utilities:CreateCorner(currencyFrame, 8)
    Utilities:CreatePadding(currencyFrame, 10)
    
    local currencyLayout = Instance.new("UIListLayout")
    currencyLayout.FillDirection = Enum.FillDirection.Horizontal
    currencyLayout.Padding = UDim.new(0, 10)
    currencyLayout.Parent = currencyFrame
    
    -- Coins
    local coinsContainer = Instance.new("Frame")
    coinsContainer.Size = UDim2.new(0.5, -5, 1, 0)
    coinsContainer.BackgroundTransparency = 1
    coinsContainer.Parent = currencyFrame
    
    local coinsIcon = UIComponents:CreateImageLabel(coinsContainer, CLIENT_CONFIG.ICONS.Coin, UDim2.new(0, 20, 0, 20), UDim2.new(0, 0, 0.5, -10))
    local coinsLabel = UIComponents:CreateLabel(coinsContainer, "0", UDim2.new(1, -25, 1, 0), UDim2.new(0, 25, 0, 0), 14)
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.Font = CLIENT_CONFIG.FONTS.Numbers
    
    -- Gems
    local gemsContainer = Instance.new("Frame")
    gemsContainer.Size = UDim2.new(0.5, -5, 1, 0)
    gemsContainer.BackgroundTransparency = 1
    gemsContainer.Parent = currencyFrame
    
    local gemsIcon = UIComponents:CreateImageLabel(gemsContainer, CLIENT_CONFIG.ICONS.Gem, UDim2.new(0, 20, 0, 20), UDim2.new(0, 0, 0.5, -10))
    local gemsLabel = UIComponents:CreateLabel(gemsContainer, "0", UDim2.new(1, -25, 1, 0), UDim2.new(0, 25, 0, 0), 14)
    gemsLabel.TextXAlignment = Enum.TextXAlignment.Left
    gemsLabel.Font = CLIENT_CONFIG.FONTS.Numbers
    
    -- Add items functionality for your side
    if isYou then
        -- Add pet button
        local addPetButton = UIComponents:CreateButton(sideFrame, "+ Add Pet", UDim2.new(0, 80, 0, 30), UDim2.new(0, 10, 0, 50), function()
            self:OpenPetSelector()
        end)
        addPetButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
        addPetButton.ZIndex = 310
        
        -- Currency input
        local coinInput = UIComponents:CreateTextBox(coinsContainer, "0", UDim2.new(1, -25, 1, 0), UDim2.new(0, 25, 0, 0))
        coinInput.Text = "0"
        coinInput.TextColor3 = CLIENT_CONFIG.COLORS.Dark
        coinInput.Font = CLIENT_CONFIG.FONTS.Numbers
        coinInput:GetPropertyChangedSignal("Text"):Connect(function()
            local amount = tonumber(coinInput.Text) or 0
            self:UpdateCurrency("coins", amount)
        end)
        
        local gemInput = UIComponents:CreateTextBox(gemsContainer, "0", UDim2.new(1, -25, 1, 0), UDim2.new(0, 25, 0, 0))
        gemInput.Text = "0"
        gemInput.TextColor3 = CLIENT_CONFIG.COLORS.Dark
        gemInput.Font = CLIENT_CONFIG.FONTS.Numbers
        gemInput:GetPropertyChangedSignal("Text"):Connect(function()
            local amount = tonumber(gemInput.Text) or 0
            self:UpdateCurrency("gems", amount)
        end)
        
        coinsLabel:Destroy()
        gemsLabel:Destroy()
    end
    
    return sideFrame
end

function UIModules.TradingUI:OpenPetSelector()
    -- Create pet selection overlay
    local selector = Instance.new("Frame")
    selector.Name = "PetSelector"
    selector.Size = UDim2.new(0, 600, 0, 500)
    selector.Position = UDim2.new(0.5, -300, 0.5, -250)
    selector.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    selector.ZIndex = 400
    selector.Parent = MainUI.ScreenGui
    
    Utilities:CreateCorner(selector, 12)
    Utilities:CreateShadow(selector, 0.5)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 401
    header.Parent = selector
    
    Utilities:CreateCorner(header, 12)
    
    local titleLabel = UIComponents:CreateLabel(header, "Select Pets to Trade", UDim2.new(1, -60, 1, 0), UDim2.new(0, 20, 0, 0), 18)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    titleLabel.ZIndex = 402
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 20
    closeButton.ZIndex = 402
    closeButton.Parent = header
    
    closeButton.MouseButton1Click:Connect(function()
        selector:Destroy()
    end)
    
    -- Pet grid
    local scrollFrame = UIComponents:CreateScrollingFrame(selector, UDim2.new(1, -20, 1, -70), UDim2.new(0, 10, 0, 60))
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.Parent = scrollFrame
    
    -- Add pets
    if LocalData.PlayerData then
        for _, pet in ipairs(LocalData.PlayerData.pets) do
            if not pet.locked and pet.tradeable ~= false then
                local petData = LocalData.PetDatabase[pet.petId]
                if petData then
                    local petCard = self:CreateSelectablePetCard(scrollFrame, pet, petData, function()
                        self:AddPetToTrade(pet)
                        selector:Destroy()
                    end)
                end
            end
        end
    end
end

function UIModules.TradingUI:CreateSelectablePetCard(parent, petInstance, petData, callback)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.Text = ""
    card.Parent = parent
    
    Utilities:CreateCorner(card, 8)
    
    -- Pet image
    local petImage = UIComponents:CreateImageLabel(card, petData.imageId, UDim2.new(0, 60, 0, 60), UDim2.new(0.5, -30, 0, 10))
    
    -- Pet name
    local nameLabel = UIComponents:CreateLabel(card, petData.displayName, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, 75), 12)
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    nameLabel.TextWrapped = true
    
    -- Level
    local levelLabel = UIComponents:CreateLabel(card, "Lv." .. petInstance.level, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 1, -25), 10)
    levelLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Click handler
    card.MouseButton1Click:Connect(function()
        callback()
    end)
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    end)
    
    card.MouseLeave:Connect(function()
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    end)
    
    return card
end

function UIModules.TradingUI:AddPetToTrade(pet)
    -- TODO: Send to server
    RemoteFunctions.UpdateTrade:InvokeServer(self.CurrentTrade.id, "add_item", {
        itemType = "pet",
        itemData = pet
    })
end

function UIModules.TradingUI:UpdateCurrency(currencyType, amount)
    -- TODO: Send to server
    RemoteFunctions.UpdateTrade:InvokeServer(self.CurrentTrade.id, "add_item", {
        itemType = "currency",
        itemData = {type = currencyType, amount = amount}
    })
end

function UIModules.TradingUI:ToggleReady()
    local ready = self.CurrentTrade.player1.userId == LocalPlayer.UserId and 
        not self.CurrentTrade.player1.ready or 
        not self.CurrentTrade.player2.ready
    
    RemoteFunctions.UpdateTrade:InvokeServer(self.CurrentTrade.id, "set_ready", {ready = ready})
end

function UIModules.TradingUI:ConfirmTrade()
    RemoteFunctions.ConfirmTrade:InvokeServer(self.CurrentTrade.id)
end

function UIModules.TradingUI:CancelTrade()
    if self.CurrentTrade then
        RemoteFunctions.UpdateTrade:InvokeServer(self.CurrentTrade.id, "cancel", {})
    end
    
    if self.TradeOverlay then
        self.TradeOverlay:Destroy()
        self.TradeOverlay = nil
        self.CurrentTrade = nil
    end
end

function UIModules.TradingUI:UpdateTradeDisplay()
    -- TODO: Update trade window based on current trade data
end

-- ========================================
-- BATTLE UI MODULE
-- ========================================
UIModules.BattleUI = {}

function UIModules.BattleUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main battle frame
    local battleFrame = UIComponents:CreateFrame(MainUI.MainContainer, "BattleFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    battleFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = battleFrame
    
    -- Header
    local header = UIComponents:CreateFrame(battleFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "⚔️ Battle Arena ⚔️", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Create tabs
    local tabs = {
        {
            Name = "PvP Battle",
            Init = function(parent)
                self:CreatePvPView(parent)
            end
        },
        {
            Name = "Tournament",
            Init = function(parent)
                self:CreateTournamentView(parent)
            end
        },
        {
            Name = "Battle History",
            Init = function(parent)
                self:CreateHistoryView(parent)
            end
        }
    }
    
    local tabContainer, tabFrames = UIComponents:CreateTab(battleFrame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    self.TabFrames = tabFrames
end

function UIModules.BattleUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.BattleUI:CreatePvPView(parent)
    -- Battle stats
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -20, 0, 100)
    statsFrame.Position = UDim2.new(0, 10, 0, 10)
    statsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    statsFrame.Parent = parent
    
    Utilities:CreateCorner(statsFrame, 12)
    Utilities:CreatePadding(statsFrame, 15)
    
    -- Stats grid
    local statsGrid = Instance.new("UIGridLayout")
    statsGrid.CellPadding = UDim2.new(0, 20, 0, 10)
    statsGrid.CellSize = UDim2.new(0.25, -15, 0.5, -5)
    statsGrid.FillDirection = Enum.FillDirection.Horizontal
    statsGrid.Parent = statsFrame
    
    local stats = {
        {label = "Wins", value = 0, color = CLIENT_CONFIG.COLORS.Success},
        {label = "Losses", value = 0, color = CLIENT_CONFIG.COLORS.Error},
        {label = "Win Rate", value = "0%", color = CLIENT_CONFIG.COLORS.Info},
        {label = "Win Streak", value = 0, color = CLIENT_CONFIG.COLORS.Warning},
        {label = "Total Battles", value = 0, color = CLIENT_CONFIG.COLORS.Primary},
        {label = "Rank", value = "Unranked", color = CLIENT_CONFIG.COLORS.Secondary},
        {label = "Rating", value = 1000, color = CLIENT_CONFIG.COLORS.Accent},
        {label = "Season Wins", value = 0, color = CLIENT_CONFIG.COLORS.Dark}
    }
    
    for _, stat in ipairs(stats) do
        local statContainer = Instance.new("Frame")
        statContainer.BackgroundTransparency = 1
        statContainer.Parent = statsFrame
        
        local statLabel = UIComponents:CreateLabel(statContainer, stat.label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), 12)
        statLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        
        local valueLabel = UIComponents:CreateLabel(statContainer, tostring(stat.value), UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 20), 18)
        valueLabel.TextColor3 = stat.color
        valueLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    end
    
    -- Quick match button
    local quickMatchButton = UIComponents:CreateButton(parent, "🎯 Quick Match", UDim2.new(0, 300, 0, 60), UDim2.new(0.5, -150, 0, 130), function()
        self:StartQuickMatch()
    end)
    quickMatchButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    quickMatchButton.TextSize = 20
    
    -- Online players
    local onlineFrame = Instance.new("Frame")
    onlineFrame.Size = UDim2.new(1, -20, 1, -220)
    onlineFrame.Position = UDim2.new(0, 10, 0, 210)
    onlineFrame.BackgroundTransparency = 1
    onlineFrame.Parent = parent
    
    local onlineLabel = UIComponents:CreateLabel(onlineFrame, "Online Players", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 18)
    onlineLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local playerScroll = UIComponents:CreateScrollingFrame(onlineFrame, UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40))
    
    -- Load online players
    self:RefreshOnlinePlayers(playerScroll)
end

function UIModules.BattleUI:RefreshOnlinePlayers(scrollFrame)
    -- Clear existing
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scrollFrame
    
    -- Add online players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:CreatePlayerCard(scrollFrame, player)
        end
    end
end

function UIModules.BattleUI:CreatePlayerCard(parent, player)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 70)
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 8)
    Utilities:CreatePadding(card, 10)
    
    -- Player avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 0, 0.5, -25)
    avatar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    avatar.Image = Services.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    avatar.Parent = card
    
    Utilities:CreateCorner(avatar, 25)
    
    -- Player info
    local nameLabel = UIComponents:CreateLabel(card, player.DisplayName, UDim2.new(0.4, -70, 0, 25), UDim2.new(0, 60, 0, 5), 16)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local statusLabel = UIComponents:CreateLabel(card, "🟢 Online", UDim2.new(0.4, -70, 0, 20), UDim2.new(0, 60, 0, 30), 12)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextColor3 = CLIENT_CONFIG.COLORS.Success
    
    -- Stats
    local statsLabel = UIComponents:CreateLabel(card, "Rating: 1000 | Wins: 0", UDim2.new(0.4, 0, 1, 0), UDim2.new(0.4, 0, 0, 0), 14)
    statsLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Battle button
    local battleButton = UIComponents:CreateButton(card, "Battle", UDim2.new(0, 80, 0, 35), UDim2.new(1, -90, 0.5, -17.5), function()
        self:ChallengePla
        self:ChallengePlayer(player)
    end)
    battleButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    
    return card
end

function UIModules.BattleUI:StartQuickMatch()
    -- TODO: Implement matchmaking
    NotificationSystem:SendNotification("Matchmaking", "Searching for opponent...", "info")
end

function UIModules.BattleUI:ChallengePlayer(player)
    local result = RemoteFunctions.JoinBattle:InvokeServer(player)
    
    if result.success then
        self:OpenBattleArena(result.battle)
    else
        NotificationSystem:SendNotification("Battle Failed", result.error or "Failed to start battle", "error")
    end
end

function UIModules.BattleUI:OpenBattleArena(battle)
    -- Create battle overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "BattleArena"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.2
    overlay.ZIndex = 500
    overlay.Parent = MainUI.ScreenGui
    
    -- Battle UI container
    local battleContainer = Instance.new("Frame")
    battleContainer.Size = UDim2.new(1, 0, 1, 0)
    battleContainer.BackgroundTransparency = 1
    battleContainer.ZIndex = 501
    battleContainer.Parent = overlay
    
    -- Top bar - Players info
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 100)
    topBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
    topBar.BackgroundTransparency = 0.2
    topBar.ZIndex = 502
    topBar.Parent = battleContainer
    
    -- Your info
    local yourInfo = self:CreateBattlerInfo(topBar, LocalPlayer, UDim2.new(0.4, 0, 1, 0), UDim2.new(0, 0, 0, 0))
    
    -- VS label
    local vsLabel = UIComponents:CreateLabel(topBar, "VS", UDim2.new(0.2, 0, 1, 0), UDim2.new(0.4, 0, 0, 0), 36)
    vsLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    vsLabel.Font = CLIENT_CONFIG.FONTS.Display
    vsLabel.ZIndex = 503
    
    -- Opponent info
    local opponent = battle.player1.userId == LocalPlayer.UserId and battle.player2.player or battle.player1.player
    local opponentInfo = self:CreateBattlerInfo(topBar, opponent, UDim2.new(0.4, 0, 1, 0), UDim2.new(0.6, 0, 0, 0))
    
    -- Battle arena
    local arenaFrame = Instance.new("Frame")
    arenaFrame.Size = UDim2.new(1, -100, 0.6, 0)
    arenaFrame.Position = UDim2.new(0, 50, 0, 120)
    arenaFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    arenaFrame.ZIndex = 502
    arenaFrame.Parent = battleContainer
    
    Utilities:CreateCorner(arenaFrame, 20)
    
    -- Pet display areas
    local yourPetArea = Instance.new("Frame")
    yourPetArea.Size = UDim2.new(0.4, 0, 1, -20)
    yourPetArea.Position = UDim2.new(0, 10, 0, 10)
    yourPetArea.BackgroundTransparency = 1
    yourPetArea.ZIndex = 503
    yourPetArea.Parent = arenaFrame
    
    local opponentPetArea = Instance.new("Frame")
    opponentPetArea.Size = UDim2.new(0.4, 0, 1, -20)
    opponentPetArea.Position = UDim2.new(0.6, -10, 0, 10)
    opponentPetArea.BackgroundTransparency = 1
    opponentPetArea.ZIndex = 503
    opponentPetArea.Parent = arenaFrame
    
    -- Action buttons
    local actionBar = Instance.new("Frame")
    actionBar.Size = UDim2.new(1, -100, 0, 150)
    actionBar.Position = UDim2.new(0, 50, 1, -180)
    actionBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    actionBar.ZIndex = 502
    actionBar.Parent = battleContainer
    
    Utilities:CreateCorner(actionBar, 12)
    Utilities:CreatePadding(actionBar, 20)
    
    -- Ability buttons
    local abilityFrame = Instance.new("Frame")
    abilityFrame.Size = UDim2.new(0.7, -10, 1, 0)
    abilityFrame.BackgroundTransparency = 1
    abilityFrame.Parent = actionBar
    
    local abilityGrid = Instance.new("UIGridLayout")
    abilityGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    abilityGrid.CellSize = UDim2.new(0.25, -7.5, 0.5, -5)
    abilityGrid.FillDirection = Enum.FillDirection.Horizontal
    abilityGrid.Parent = abilityFrame
    
    -- Pet switch buttons
    local switchFrame = Instance.new("Frame")
    switchFrame.Size = UDim2.new(0.3, -10, 1, 0)
    switchFrame.Position = UDim2.new(0.7, 10, 0, 0)
    switchFrame.BackgroundTransparency = 1
    switchFrame.Parent = actionBar
    
    local switchLabel = UIComponents:CreateLabel(switchFrame, "Switch Pet", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), 14)
    switchLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local petList = Instance.new("Frame")
    petList.Size = UDim2.new(1, 0, 1, -30)
    petList.Position = UDim2.new(0, 0, 0, 30)
    petList.BackgroundTransparency = 1
    petList.Parent = switchFrame
    
    local petLayout = Instance.new("UIListLayout")
    petLayout.FillDirection = Enum.FillDirection.Vertical
    petLayout.Padding = UDim.new(0, 5)
    petLayout.Parent = petList
    
    -- Store battle data
    self.CurrentBattle = battle
    self.BattleOverlay = overlay
    
    -- Setup battle
    self:SetupBattle()
end

function UIModules.BattleUI:CreateBattlerInfo(parent, player, size, position)
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = size
    infoFrame.Position = position
    infoFrame.BackgroundTransparency = 1
    infoFrame.ZIndex = 503
    infoFrame.Parent = parent
    
    -- Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 60, 0, 60)
    avatar.Position = UDim2.new(0, 20, 0.5, -30)
    avatar.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    avatar.Image = Services.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    avatar.ZIndex = 504
    avatar.Parent = infoFrame
    
    Utilities:CreateCorner(avatar, 30)
    
    -- Name
    local nameLabel = UIComponents:CreateLabel(infoFrame, player.DisplayName, UDim2.new(1, -100, 0, 30), UDim2.new(0, 90, 0, 15), 18)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    nameLabel.ZIndex = 504
    
    -- Health bar
    local healthBar = UIComponents:CreateProgressBar(infoFrame, UDim2.new(1, -110, 0, 20), UDim2.new(0, 90, 0, 50), 100, 100)
    healthBar.Fill.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    healthBar.ZIndex = 504
    
    return infoFrame
end

-- ========================================
-- QUEST UI MODULE
-- ========================================
UIModules.QuestUI = {}

function UIModules.QuestUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshQuests()
        return
    end
    
    -- Create main quest frame
    local questFrame = UIComponents:CreateFrame(MainUI.MainContainer, "QuestFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    questFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = questFrame
    
    -- Header
    local header = UIComponents:CreateFrame(questFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "📜 Quest Board 📜", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Create tabs
    local tabs = {
        {
            Name = "Daily Quests",
            Init = function(parent)
                self:CreateQuestList(parent, "daily")
            end
        },
        {
            Name = "Weekly Quests",
            Init = function(parent)
                self:CreateQuestList(parent, "weekly")
            end
        },
        {
            Name = "Achievements",
            Init = function(parent)
                self:CreateAchievementList(parent)
            end
        }
    }
    
    local tabContainer, tabFrames = UIComponents:CreateTab(questFrame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    self.TabFrames = tabFrames
end

function UIModules.QuestUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.QuestUI:CreateQuestList(parent, questType)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local questContainer = Instance.new("Frame")
    questContainer.Size = UDim2.new(1, -20, 0, 500)
    questContainer.BackgroundTransparency = 1
    questContainer.Parent = scrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.Parent = questContainer
    
    Utilities:CreatePadding(questContainer, 10)
    
    -- Store reference
    if questType == "daily" then
        self.DailyQuestContainer = questContainer
    else
        self.WeeklyQuestContainer = questContainer
    end
    
    -- Update canvas size
    questContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

function UIModules.QuestUI:CreateQuestCard(parent, quest)
    local card = Instance.new("Frame")
    card.Name = quest.id
    card.Size = UDim2.new(1, 0, 0, 120)
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 12)
    Utilities:CreateShadow(card, 0.2)
    Utilities:CreatePadding(card, 15)
    
    -- Completion status
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0, 5, 1, 0)
    statusFrame.BackgroundColor3 = quest.completed and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Warning
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = card
    
    -- Quest info
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -150, 1, 0)
    infoFrame.Position = UDim2.new(0, 15, 0, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = card
    
    -- Quest name
    local nameLabel = UIComponents:CreateLabel(infoFrame, quest.name, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0), 18)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Quest description
    local descLabel = UIComponents:CreateLabel(infoFrame, quest.description, UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 30), 14)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    descLabel.TextWrapped = true
    
    -- Progress bar
    local progressBar = UIComponents:CreateProgressBar(infoFrame, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 1, -25), quest.progress, quest.target)
    
    -- Rewards
    local rewardsFrame = Instance.new("Frame")
    rewardsFrame.Size = UDim2.new(0, 120, 1, -40)
    rewardsFrame.Position = UDim2.new(1, -120, 0, 0)
    rewardsFrame.BackgroundTransparency = 1
    rewardsFrame.Parent = card
    
    local rewardsLabel = UIComponents:CreateLabel(rewardsFrame, "Rewards:", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), 14)
    rewardsLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    rewardsLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    local rewardY = 25
    if quest.rewards.coins then
        local coinReward = UIComponents:CreateLabel(rewardsFrame, "💰 " .. Utilities:FormatNumber(quest.rewards.coins), 
            UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, rewardY), 12)
        rewardY = rewardY + 18
    end
    
    if quest.rewards.gems then
        local gemReward = UIComponents:CreateLabel(rewardsFrame, "💎 " .. Utilities:FormatNumber(quest.rewards.gems), 
            UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, rewardY), 12)
        rewardY = rewardY + 18
    end
    
    -- Claim button
    if quest.completed and not quest.claimed then
        local claimButton = UIComponents:CreateButton(card, "Claim", UDim2.new(0, 100, 0, 35), UDim2.new(1, -115, 1, -50), function()
            self:ClaimQuest(quest)
        end)
        claimButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    elseif quest.claimed then
        local claimedLabel = UIComponents:CreateLabel(card, "✓ Claimed", UDim2.new(0, 100, 0, 35), UDim2.new(1, -115, 1, -50), 16)
        claimedLabel.TextColor3 = CLIENT_CONFIG.COLORS.Success
        claimedLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    end
    
    return card
end

function UIModules.QuestUI:RefreshQuests()
    if not LocalData.PlayerData then return end
    
    -- Clear existing
    if self.DailyQuestContainer then
        for _, child in ipairs(self.DailyQuestContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
    if self.WeeklyQuestContainer then
        for _, child in ipairs(self.WeeklyQuestContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
    -- Add daily quests
    if self.DailyQuestContainer and LocalData.PlayerData.quests.daily then
        for _, quest in ipairs(LocalData.PlayerData.quests.daily) do
            self:CreateQuestCard(self.DailyQuestContainer, quest)
        end
    end
    
    -- Add weekly quests
    if self.WeeklyQuestContainer and LocalData.PlayerData.quests.weekly then
        for _, quest in ipairs(LocalData.PlayerData.quests.weekly) do
            self:CreateQuestCard(self.WeeklyQuestContainer, quest)
        end
    end
end

function UIModules.QuestUI:ClaimQuest(quest)
    local result = RemoteFunctions.ClaimQuest:InvokeServer(quest.id)
    
    if result then
        NotificationSystem:SendNotification("Quest Complete!", "You have claimed your rewards!", "success")
        self:RefreshQuests()
        
        -- Update currency
        if MainUI.UpdateCurrency and LocalData.PlayerData then
            MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
        end
    end
end

-- ========================================
-- SETTINGS UI MODULE
-- ========================================
UIModules.SettingsUI = {}

function UIModules.SettingsUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main settings frame
    local settingsFrame = UIComponents:CreateFrame(MainUI.MainContainer, "SettingsFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    settingsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = settingsFrame
    
    -- Header
    local header = UIComponents:CreateFrame(settingsFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "⚙️ Settings ⚙️", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Settings container
    local scrollFrame = UIComponents:CreateScrollingFrame(settingsFrame, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    
    local settingsContainer = Instance.new("Frame")
    settingsContainer.Size = UDim2.new(1, -20, 0, 800)
    settingsContainer.BackgroundTransparency = 1
    settingsContainer.Parent = scrollFrame
    
    local yOffset = 10
    
    -- Audio settings
    local audioSection = self:CreateSettingsSection(settingsContainer, "🔊 Audio Settings", yOffset)
    yOffset = yOffset + 50
    
    local musicToggle = UIComponents:CreateToggle(settingsContainer, "Music", UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 0, yOffset), 
        LocalData.Settings.MusicEnabled, function(value)
            LocalData.Settings.MusicEnabled = value
            self:SaveSettings()
        end)
    yOffset = yOffset + 50
    
    local sfxToggle = UIComponents:CreateToggle(settingsContainer, "Sound Effects", UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 0, yOffset), 
        LocalData.Settings.SFXEnabled, function(value)
            LocalData.Settings.SFXEnabled = value
            self:SaveSettings()
        end)
    yOffset = yOffset + 70
    
    -- Visual settings
    local visualSection = self:CreateSettingsSection(settingsContainer, "👁️ Visual Settings", yOffset)
    yOffset = yOffset + 50
    
    local particlesToggle = UIComponents:CreateToggle(settingsContainer, "Particles", UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 0, yOffset), 
        LocalData.Settings.ParticlesEnabled, function(value)
            LocalData.Settings.ParticlesEnabled = value
            self:SaveSettings()
        end)
    yOffset = yOffset + 50
    
    local lowQualityToggle = UIComponents:CreateToggle(settingsContainer, "Low Quality Mode", UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 0, yOffset), 
        LocalData.Settings.LowQualityMode, function(value)
            LocalData.Settings.LowQualityMode = value
            self:SaveSettings()
        end)
    yOffset = yOffset + 50
    
    -- UI Scale slider
    local scaleFrame = Instance.new("Frame")
    scaleFrame.Size = UDim2.new(1, -40, 0, 60)
    scaleFrame.Position = UDim2.new(0, 20, 0, yOffset)
    scaleFrame.BackgroundTransparency = 1
    scaleFrame.Parent = settingsContainer
    
    local scaleLabel = UIComponents:CreateLabel(scaleFrame, "UI Scale: " .. LocalData.Settings.UIScale, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0), 16)
    
    local scaleSlider = self:CreateSlider(scaleFrame, 0.5, 1.5, LocalData.Settings.UIScale, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 30), function(value)
        LocalData.Settings.UIScale = math.floor(value * 10) / 10
        scaleLabel.Text = "UI Scale: " .. LocalData.Settings.UIScale
        
        -- Apply scale
        local uiScale = MainUI.MainContainer:FindFirstChild("UIScale")
        if uiScale then
            uiScale.Scale = LocalData.Settings.UIScale
        end
        
        self:SaveSettings()
    end)
    
    yOffset = yOffset + 80
    
    -- Notification settings
    local notifSection = self:CreateSettingsSection(settingsContainer, "🔔 Notification Settings", yOffset)
    yOffset = yOffset + 50
    
    local notifToggle = UIComponents:CreateToggle(settingsContainer, "Enable Notifications", UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 0, yOffset), 
        LocalData.Settings.NotificationsEnabled, function(value)
            LocalData.Settings.NotificationsEnabled = value
            self:SaveSettings()
        end)
    yOffset = yOffset + 70
    
    -- Account section
    local accountSection = self:CreateSettingsSection(settingsContainer, "👤 Account", yOffset)
    yOffset = yOffset + 50
    
    -- Account info
    local accountInfo = Instance.new("Frame")
    accountInfo.Size = UDim2.new(1, -40, 0, 100)
    accountInfo.Position = UDim2.new(0, 20, 0, yOffset)
    accountInfo.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    accountInfo.Parent = settingsContainer
    
    Utilities:CreateCorner(accountInfo, 12)
    Utilities:CreatePadding(accountInfo, 15)
    
    local usernameLabel = UIComponents:CreateLabel(accountInfo, "Username: " .. LocalPlayer.Name, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0), 16)
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local userIdLabel = UIComponents:CreateLabel(accountInfo, "User ID: " .. LocalPlayer.UserId, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 25), 16)
    userIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    userIdLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    local accountAgeLabel = UIComponents:CreateLabel(accountInfo, "Account Age: " .. LocalPlayer.AccountAge .. " days", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 50), 16)
    accountAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
    accountAgeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Update canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 120)
end

function UIModules.SettingsUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.SettingsUI:CreateSettingsSection(parent, title, yPosition)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -40, 0, 40)
    section.Position = UDim2.new(0, 20, 0, yPosition)
    section.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    section.BackgroundTransparency = 0.9
    section.Parent = parent
    
    Utilities:CreateCorner(section, 8)
    
    local titleLabel = UIComponents:CreateLabel(section, title, UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), 18)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.Primary
    
    return section
end

function UIModules.SettingsUI:CreateSlider(parent, min, max, current, size, position, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = size
    sliderFrame.Position = position
    sliderFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    sliderFrame.Parent = parent
    
    Utilities:CreateCorner(sliderFrame, 15)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame
    
    Utilities:CreateCorner(fill, 15)
    
    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 30, 0, 30)
    handle.Position = UDim2.new((current - min) / (max - min), -15, 0.5, -15)
    handle.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    handle.Text = ""
    handle.Parent = sliderFrame
    
    Utilities:CreateCorner(handle, 15)
    Utilities:CreateShadow(handle, 0.3, 5)
    
    local dragging = false
    
    handle.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp((Mouse.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
            handle.Position = UDim2.new(relativeX, -15, 0.5, -15)
            fill.Size = UDim2.new(relativeX, 0, 1, 0)
            
            local value = min + (max - min) * relativeX
            callback(value)
        end
    end)
    
    return sliderFrame
end

function UIModules.SettingsUI:SaveSettings()
    -- Send settings to server
    RemoteFunctions.SaveSettings:InvokeServer(LocalData.Settings)
end

-- ========================================
-- INITIALIZATION
-- ========================================
local function Initialize()
    -- Wait for data to load
    RemoteEvents.DataLoaded.OnClientEvent:Connect(function(playerData)
        LocalData.PlayerData = playerData
        
        -- Update currency display
        if MainUI.UpdateCurrency then
            MainUI.UpdateCurrency(playerData.currencies)
        end
        
        -- Generate quests if needed
        if not playerData.quests.daily or #playerData.quests.daily == 0 then
            -- Request quest generation
        end
    end)
    
    -- Handle currency updates
    RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(function(currencies)
        if LocalData.PlayerData then
            LocalData.PlayerData.currencies = currencies
        end
        
        if MainUI.UpdateCurrency then
            MainUI.UpdateCurrency(currencies)
        end
    end)
    
    -- Handle notifications
    RemoteEvents.NotificationSent.OnClientEvent:Connect(function(data)
        NotificationSystem:SendNotification(data.title, data.message, data.type, data.duration)
    end)
    
    -- Handle trade updates
    RemoteEvents.TradeUpdated.OnClientEvent:Connect(function(trade)
        if UIModules.TradingUI.CurrentTrade and UIModules.TradingUI.CurrentTrade.id == trade.id then
            UIModules.TradingUI.CurrentTrade = trade
            UIModules.TradingUI:UpdateTradeDisplay()
        end
    end)
    
    -- Handle trade completion
    RemoteEvents.TradeCompleted.OnClientEvent:Connect(function(trade)
        NotificationSystem:SendNotification("Trade Complete!", "Your trade has been completed successfully!", "success")
        
        if UIModules.TradingUI.TradeOverlay then
            UIModules.TradingUI.TradeOverlay:Destroy()
            UIModules.TradingUI.TradeOverlay = nil
            UIModules.TradingUI.CurrentTrade = nil
        end
        
        -- Refresh inventory
        if UIModules.InventoryUI.RefreshInventory then
            UIModules.InventoryUI:RefreshInventory()
        end
    end)
    
    -- Handle quest updates
    RemoteEvents.QuestsUpdated.OnClientEvent:Connect(function(quests)
        if LocalData.PlayerData then
            LocalData.PlayerData.quests = quests
        end
        
        if UIModules.QuestUI.RefreshQuests then
            UIModules.QuestUI:RefreshQuests()
        end
    end)
    
    -- Handle quest completion
    RemoteEvents.QuestCompleted.OnClientEvent:Connect(function(quest)
        NotificationSystem:SendNotification("Quest Complete!", quest.name .. " completed! Claim your reward!", "success")
        
        -- Particles effect
        ParticleSystem:CreateBurst(MainUI.MainContainer, "star", UDim2.new(0.5, 0, 0.5, 0), 20)
    end)
    
    -- Handle achievement unlock
    RemoteEvents.AchievementUnlocked.OnClientEvent:Connect(function(achievement)
        NotificationSystem:SendNotification("Achievement Unlocked!", achievement.name, "success", 10)
        
        -- Special effects
        ParticleSystem:CreateBurst(MainUI.MainContainer, "star", UDim2.new(0.5, 0, 0.5, 0), 50)
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.LevelUp)
    end)
    
    -- Initialize main UI
    MainUI:Initialize()
    
    -- Show loading screen
    local loadingScreen = Instance.new("Frame")
    loadingScreen.Size = UDim2.new(1, 0, 1, 0)
    loadingScreen.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    loadingScreen.Parent = MainUI.ScreenGui
    
    local loadingLabel = UIComponents:CreateLabel(loadingScreen, "Loading Sanrio Tycoon Shop...", UDim2.new(0, 400, 0, 50), UDim2.new(0.5, -200, 0.5, -25), 24)
    loadingLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Loading animation
    spawn(function()
        local dots = 0
        while loadingScreen.Parent do
            dots = (dots % 3) + 1
            loadingLabel.Text = "Loading Sanrio Tycoon Shop" .. string.rep(".", dots)
            wait(0.5)
        end
    end)
    
    -- Wait for data
    wait(2)
    
    -- Fade out loading screen
    Utilities:Tween(loadingScreen, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Slow)
    Utilities:Tween(loadingLabel, {TextTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Slow)
    wait(0.5)
    loadingScreen:Destroy()
    
    -- Show welcome notification
    NotificationSystem:SendNotification("Welcome!", "Welcome to Sanrio Tycoon Shop! 🎀", "info", 8)
    
    -- Open shop by default
    UIModules.ShopUI:Open()
end

-- Start initialization
Initialize()

-- Return module for potential access
return {
    MainUI = MainUI,
    UIModules = UIModules,
    NotificationSystem = NotificationSystem,
    ParticleSystem = ParticleSystem,
    Utilities = Utilities,
    LocalData = LocalData
}