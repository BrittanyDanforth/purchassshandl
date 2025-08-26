-- ========================================
-- NOTIFICATION SYSTEM
-- ========================================
local NotificationSystem = {}

function NotificationSystem:SendNotification(title, message, notificationType, duration)
    if not LocalData.Settings.NotificationsEnabled then return end
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(1, 0, 0, 80)
    notification.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    notification.BackgroundTransparency = 1
    notification.Parent = MainUI.NotificationContainer
    
    Utilities:CreateCorner(notification, 12)
    Utilities:CreateShadow(notification, 0.4)
    
    -- Notification content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    content.Parent = notification
    
    Utilities:CreateCorner(content, 12)
    
    -- Color bar
    local colorBar = Instance.new("Frame")
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.BorderSizePixel = 0
    colorBar.Parent = content
    
    if notificationType == "success" then
        colorBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    elseif notificationType == "error" then
        colorBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    elseif notificationType == "warning" then
        colorBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
    elseif notificationType == "info" then
        colorBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Info
    else
        colorBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    end
    
    -- Title
    local titleLabel = UIComponents:CreateLabel(content, title, UDim2.new(1, -70, 0, 25), UDim2.new(0, 15, 0, 10), 16)
    titleLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Message
    local messageLabel = UIComponents:CreateLabel(content, message, UDim2.new(1, -70, 0, 35), UDim2.new(0, 15, 0, 35), 14)
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    messageLabel.TextWrapped = true
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 20
    closeButton.Parent = content
    
    -- Animate in
    notification.Position = UDim2.new(1, 0, 0, 0)
    Utilities:Tween(notification, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Sound
    Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Notification)
    
    -- Particles
    if notificationType == "success" then
        ParticleSystem:CreateBurst(notification, "star", UDim2.new(0.5, 0, 0.5, 0), 5)
    end
    
    -- Auto dismiss
    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        
        Utilities:Tween(notification, {Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        wait(0.3)
        notification:Destroy()
    end
    
    closeButton.MouseButton1Click:Connect(dismiss)
    
    delay(duration or CLIENT_CONFIG.NOTIFICATION_DURATION, dismiss)
    
    return notification
end

-- ========================================
-- SHOP UI MODULE
-- ========================================
UIModules.ShopUI = {}

function UIModules.ShopUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main shop frame
    local shopFrame = UIComponents:CreateFrame(MainUI.MainContainer, "ShopFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    shopFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = shopFrame
    
    -- Shop header
    local header = UIComponents:CreateFrame(shopFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "✨ Sanrio Tycoon Shop ✨", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Create tabs
    local tabs = {
        {
            Name = "Eggs",
            Init = function(parent)
                self:CreateEggShop(parent)
            end
        },
        {
            Name = "Gamepasses",
            Init = function(parent)
                self:CreateGamepassShop(parent)
            end
        },
        {
            Name = "Currency",
            Init = function(parent)
                self:CreateCurrencyShop(parent)
            end
        }
    }
    
    local tabContainer, tabFrames = UIComponents:CreateTab(shopFrame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    
    self.TabFrames = tabFrames
end

function UIModules.ShopUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.ShopUI:CreateEggShop(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
    gridLayout.CellSize = UDim2.new(0, 200, 0, 280)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Sample egg data (will be replaced with server data)
    local eggs = {
        {id = "basic", name = "Basic Egg", price = 100, currency = "Coins", image = "rbxassetid://10000001001"},
        {id = "premium", name = "Premium Egg", price = 250, currency = "Gems", image = "rbxassetid://10000001003"},
        {id = "rare", name = "Rare Egg", price = 500, currency = "Gems", image = "rbxassetid://10000001005"},
        {id = "epic", name = "Epic Egg", price = 1000, currency = "Gems", image = "rbxassetid://10000001007"},
        {id = "legendary", name = "Legendary Egg", price = 2500, currency = "Gems", image = "rbxassetid://10000001009"},
        {id = "mythical", name = "Mythical Egg", price = 10000, currency = "Gems", image = "rbxassetid://10000001011"}
    }
    
    for i, eggData in ipairs(eggs) do
        local eggCard = self:CreateEggCard(scrollFrame, eggData)
        eggCard.LayoutOrder = i
    end
    
    -- Update canvas size
    scrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function UIModules.ShopUI:CreateEggCard(parent, eggData)
    local card = Instance.new("Frame")
    card.Name = eggData.id .. "Card"
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 12)
    Utilities:CreateShadow(card, 0.3)
    
    -- Egg image
    local eggImage = UIComponents:CreateImageLabel(card, eggData.image, UDim2.new(0, 120, 0, 120), UDim2.new(0.5, -60, 0, 20))
    
    -- Floating animation
    spawn(function()
        while card.Parent do
            Utilities:Tween(eggImage, {Position = UDim2.new(0.5, -60, 0, 15)}, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(2)
            Utilities:Tween(eggImage, {Position = UDim2.new(0.5, -60, 0, 25)}, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(2)
        end
    end)
    
    -- Egg name
    local nameLabel = UIComponents:CreateLabel(card, eggData.name, UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 150), 18)
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Price container
    local priceContainer = Instance.new("Frame")
    priceContainer.Size = UDim2.new(1, -20, 0, 30)
    priceContainer.Position = UDim2.new(0, 10, 0, 180)
    priceContainer.BackgroundTransparency = 1
    priceContainer.Parent = card
    
    local currencyIcon = UIComponents:CreateImageLabel(priceContainer, 
        eggData.currency == "Gems" and CLIENT_CONFIG.ICONS.Gem or CLIENT_CONFIG.ICONS.Coin,
        UDim2.new(0, 24, 0, 24), UDim2.new(0, 0, 0.5, -12))
    
    local priceLabel = UIComponents:CreateLabel(priceContainer, Utilities:FormatNumber(eggData.price), 
        UDim2.new(1, -30, 1, 0), UDim2.new(0, 30, 0, 0), 16)
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.Font = CLIENT_CONFIG.FONTS.Numbers
    
    -- Buy button
    local buyButton = UIComponents:CreateButton(card, "Open", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 1, -50), function()
        self:OpenEgg(eggData)
    end)
    
    -- Multi-hatch buttons
    if LocalData.PlayerData and LocalData.PlayerData.ownedGamepasses and LocalData.PlayerData.ownedGamepasses[123462] then
        local multiButton = UIComponents:CreateButton(card, "Open x3", UDim2.new(0.48, -5, 0, 35), UDim2.new(0, 10, 1, -45), function()
            self:OpenEgg(eggData, 3)
        end)
        multiButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Secondary
        
        buyButton.Size = UDim2.new(0.48, -5, 0, 35)
        buyButton.Position = UDim2.new(0.52, 5, 1, -45)
    end
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        Utilities:Tween(card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Background}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        ParticleSystem:CreateBurst(card, "sparkle", UDim2.new(0.5, 0, 0.5, 0), 3)
    end)
    
    card.MouseLeave:Connect(function()
        Utilities:Tween(card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    return card
end

function UIModules.ShopUI:OpenEgg(eggData, count)
    -- Request egg opening from server
    local result = RemoteFunctions.OpenCase:InvokeServer(eggData.id, count)
    
    if result.success then
        -- Open case opening UI
        UIModules.CaseOpeningUI:Open(result.results)
        
        -- Update currency
        if MainUI.UpdateCurrency then
            MainUI.UpdateCurrency(result.newBalance)
        end
    else
        NotificationSystem:SendNotification("Error", result.error or "Failed to open egg", "error")
    end
end

function UIModules.ShopUI:CreateGamepassShop(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Padding = UDim.new(0, 15)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    Utilities:CreatePadding(scrollFrame, 10)
    
    -- Sample gamepass data
    local gamepasses = {
        {id = 123456, name = "2x Cash Multiplier", description = "Double all cash earned!", price = 199, icon = "rbxassetid://10000002001"},
        {id = 123457, name = "Auto Collector", description = "Automatically collect cash!", price = 299, icon = "rbxassetid://10000002002"},
        {id = 123458, name = "VIP Status", description = "Exclusive VIP perks!", price = 999, icon = "rbxassetid://10000002003"},
        {id = 123459, name = "Pet Storage +100", description = "Increase pet storage!", price = 149, icon = "rbxassetid://10000002004"},
        {id = 123460, name = "Lucky Boost", description = "Increase rare drops by 25%!", price = 399, icon = "rbxassetid://10000002005"}
    }
    
    for i, passData in ipairs(gamepasses) do
        local passCard = self:CreateGamepassCard(scrollFrame, passData)
        passCard.LayoutOrder = i
    end
    
    -- Update canvas size
    scrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)
end

function UIModules.ShopUI:CreateGamepassCard(parent, passData)
    local card = Instance.new("Frame")
    card.Name = passData.name .. "Card"
    card.Size = UDim2.new(1, -20, 0, 100)
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 12)
    Utilities:CreateShadow(card, 0.3)
    Utilities:CreatePadding(card, 15)
    
    -- Icon
    local icon = UIComponents:CreateImageLabel(card, passData.icon, UDim2.new(0, 70, 0, 70), UDim2.new(0, 0, 0.5, -35))
    
    -- Info container
    local infoContainer = Instance.new("Frame")
    infoContainer.Size = UDim2.new(1, -200, 1, 0)
    infoContainer.Position = UDim2.new(0, 85, 0, 0)
    infoContainer.BackgroundTransparency = 1
    infoContainer.Parent = card
    
    -- Name
    local nameLabel = UIComponents:CreateLabel(infoContainer, passData.name, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 5), 18)
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Description
    local descLabel = UIComponents:CreateLabel(infoContainer, passData.description, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 30), 14)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    descLabel.TextWrapped = true
    
    -- Buy button
    local buyButton = UIComponents:CreateButton(card, "R$ " .. passData.price, UDim2.new(0, 100, 0, 50), UDim2.new(1, -115, 0.5, -25), function()
        Services.MarketplaceService:PromptGamePassPurchase(LocalPlayer, passData.id)
    end)
    buyButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    
    -- Check if owned
    if LocalData.PlayerData and LocalData.PlayerData.ownedGamepasses and LocalData.PlayerData.ownedGamepasses[passData.id] then
        buyButton.Text = "Owned"
        buyButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        buyButton.Active = false
    end
    
    return card
end

function UIModules.ShopUI:CreateCurrencyShop(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
    gridLayout.CellSize = UDim2.new(0, 200, 0, 250)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Gem packages
    local packages = {
        {id = 123499, amount = 100, price = 99, bonus = 0},
        {id = 123500, amount = 500, price = 499, bonus = 10},
        {id = 123501, amount = 1000, price = 999, bonus = 20},
        {id = 123502, amount = 5000, price = 4999, bonus = 30},
        {id = 123503, amount = 10000, price = 9999, bonus = 50}
    }
    
    for i, package in ipairs(packages) do
        local packageCard = self:CreateCurrencyCard(scrollFrame, package)
        packageCard.LayoutOrder = i
    end
end

function UIModules.ShopUI:CreateCurrencyCard(parent, package)
    local card = Instance.new("Frame")
    card.Name = "Package" .. package.amount
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 12)
    Utilities:CreateShadow(card, 0.3)
    
    -- Gem icon
    local gemIcon = UIComponents:CreateImageLabel(card, CLIENT_CONFIG.ICONS.Gem, UDim2.new(0, 80, 0, 80), UDim2.new(0.5, -40, 0, 20))
    
    -- Amount label
    local amountLabel = UIComponents:CreateLabel(card, Utilities:FormatNumber(package.amount), UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 110), 24)
    amountLabel.Font = CLIENT_CONFIG.FONTS.Display
    amountLabel.TextColor3 = CLIENT_CONFIG.COLORS.Primary
    
    -- Bonus label
    if package.bonus > 0 then
        local bonusLabel = UIComponents:CreateLabel(card, "+" .. package.bonus .. "% Bonus!", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 140), 14)
        bonusLabel.TextColor3 = CLIENT_CONFIG.COLORS.Success
        bonusLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    end
    
    -- Buy button
    local buyButton = UIComponents:CreateButton(card, "R$ " .. (package.price / 100), UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 1, -50), function()
        Services.MarketplaceService:PromptProductPurchase(LocalPlayer, package.id)
    end)
    buyButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    
    -- Best value tag
    if package.bonus >= 30 then
        local tag = Instance.new("Frame")
        tag.Size = UDim2.new(0, 80, 0, 25)
        tag.Position = UDim2.new(1, -80, 0, 0)
        tag.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
        tag.Parent = card
        
        Utilities:CreateCorner(tag, UDim.new(0, 4))
        
        local tagLabel = UIComponents:CreateLabel(tag, "BEST VALUE", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 10)
        tagLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
        tagLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    end
    
    return card
end

-- ========================================
-- CASE OPENING UI MODULE
-- ========================================
UIModules.CaseOpeningUI = {}

function UIModules.CaseOpeningUI:Open(results)
    -- Create fullscreen overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "CaseOpeningOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 100
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Create main container
    local container = Instance.new("Frame")
    container.Name = "CaseOpeningContainer"
    container.Size = UDim2.new(0, 800, 0, 600)
    container.Position = UDim2.new(0.5, -400, 0.5, -300)
    container.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    container.ZIndex = 101
    container.Parent = overlay
    
    Utilities:CreateCorner(container, 20)
    Utilities:CreateShadow(container, 0.5, 30)
    
    -- Animate in
    container.Position = UDim2.new(0.5, -400, 0.5, -300)
    container.Size = UDim2.new(0, 0, 0, 0)
    Utilities:Tween(container, {
        Size = UDim2.new(0, 800, 0, 600),
        Position = UDim2.new(0.5, -400, 0.5, -300)
    }, CLIENT_CONFIG.TWEEN_INFO.Elastic)
    
    -- Process each result
    for i, result in ipairs(results) do
        wait(0.5) -- Delay between multiple opens
        self:ShowCaseAnimation(container, result, i, #results)
    end
    
    -- Close button (shown after all animations)
    wait(1)
    local closeButton = UIComponents:CreateButton(container, "Collect", UDim2.new(0, 200, 0, 50), UDim2.new(0.5, -100, 1, -70), function()
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Close)
        Utilities:Tween(container, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        wait(0.3)
        overlay:Destroy()
    end)
    closeButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    closeButton.ZIndex = 105
end

function UIModules.CaseOpeningUI:ShowCaseAnimation(container, result, index, total)
    -- Clear previous content
    for _, child in ipairs(container:GetChildren()) do
        if child.Name == "CaseContent" then
            child:Destroy()
        end
    end
    
    local content = Instance.new("Frame")
    content.Name = "CaseContent"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.ZIndex = 102
    content.Parent = container
    
    -- Title
    local titleLabel = UIComponents:CreateLabel(content, "Opening " .. (result.petData.displayName or "Mystery Pet") .. "...", 
        UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 20), 24)
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 103
    
    -- Case spinner
    local spinnerFrame = Instance.new("Frame")
    spinnerFrame.Name = "SpinnerFrame"
    spinnerFrame.Size = UDim2.new(1, -100, 0, 200)
    spinnerFrame.Position = UDim2.new(0, 50, 0, 80)
    spinnerFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
    spinnerFrame.ClipsDescendants = true
    spinnerFrame.ZIndex = 102
    spinnerFrame.Parent = content
    
    Utilities:CreateCorner(spinnerFrame, 12)
    
    -- Create case items
    local itemContainer = Instance.new("Frame")
    itemContainer.Name = "ItemContainer"
    itemContainer.Size = UDim2.new(0, #result.caseItems * CLIENT_CONFIG.CASE_ITEM_WIDTH, 1, 0)
    itemContainer.BackgroundTransparency = 1
    itemContainer.ZIndex = 103
    itemContainer.Parent = spinnerFrame
    
    -- Create indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 4, 1, 20)
    indicator.Position = UDim2.new(0.5, -2, 0, -10)
    indicator.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    indicator.ZIndex = 104
    indicator.Parent = spinnerFrame
    
    Utilities:CreateCorner(indicator, 2)
    
    -- Add glow to indicator
    local indicatorGlow = Instance.new("ImageLabel")
    indicatorGlow.Size = UDim2.new(0, 20, 0, 20)
    indicatorGlow.Position = UDim2.new(0.5, -10, 0, -10)
    indicatorGlow.BackgroundTransparency = 1
    indicatorGlow.Image = "rbxassetid://5028857084"
    indicatorGlow.ImageColor3 = CLIENT_CONFIG.COLORS.Error
    indicatorGlow.ZIndex = 103
    indicatorGlow.Parent = indicator
    
    -- Create items
    for i, petId in ipairs(result.caseItems) do
        local itemFrame = self:CreateCaseItem(petId, i == 50) -- Winner is at position 50
        itemFrame.Position = UDim2.new(0, (i - 1) * CLIENT_CONFIG.CASE_ITEM_WIDTH, 0, 0)
        itemFrame.Parent = itemContainer
    end
    
    -- Play spin sound
    Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.CaseOpen)
    
    -- Animate spin
    local targetPosition = -((50 - 1) * CLIENT_CONFIG.CASE_ITEM_WIDTH) + (spinnerFrame.AbsoluteSize.X / 2) - (CLIENT_CONFIG.CASE_ITEM_WIDTH / 2)
    targetPosition = targetPosition + math.random(-20, 20) -- Add randomness
    
    -- Spin animation
    local spinTween = Utilities:Tween(itemContainer, {
        Position = UDim2.new(0, targetPosition, 0, 0)
    }, TweenInfo.new(CLIENT_CONFIG.CASE_SPIN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Wait for spin to complete
    spinTween.Completed:Wait()
    
    -- Flash winner
    wait(0.5)
    local winnerItem = itemContainer:GetChildren()[50]
    if winnerItem then
        for i = 1, 3 do
            Utilities:Tween(winnerItem, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning}, TweenInfo.new(0.2))
            wait(0.2)
            Utilities:Tween(winnerItem, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White}, TweenInfo.new(0.2))
            wait(0.2)
        end
    end
    
    -- Show result
    self:ShowResult(content, result)
end

function UIModules.CaseOpeningUI:CreateCaseItem(petId, isWinner)
    local petData = LocalData.PetDatabase[petId] or {
        displayName = "Unknown",
        rarity = 1,
        imageId = "rbxassetid://0"
    }
    
    local item = Instance.new("Frame")
    item.Name = petId
    item.Size = UDim2.new(0, CLIENT_CONFIG.CASE_ITEM_WIDTH - 10, 1, -20)
    item.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    item.BorderSizePixel = 0
    item.ZIndex = 103
    
    Utilities:CreateCorner(item, 8)
    
    -- Rarity border
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 0, 4)
    border.Position = UDim2.new(0, 0, 1, -4)
    border.BackgroundColor3 = Utilities:GetRarityColor(petData.rarity)
    border.BorderSizePixel = 0
    border.ZIndex = 104
    border.Parent = item
    
    -- Pet image
    local petImage = UIComponents:CreateImageLabel(item, petData.imageId, UDim2.new(0, 100, 0, 100), UDim2.new(0.5, -50, 0.5, -60))
    petImage.ZIndex = 104
    
    -- Pet name
    local nameLabel = UIComponents:CreateLabel(item, petData.displayName, UDim2.new(1, -10, 0, 30), UDim2.new(0, 5, 1, -35), 14)
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    nameLabel.TextWrapped = true
    nameLabel.ZIndex = 104
    
    -- Add glow if winner
    if isWinner then
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1, 20, 1, 20)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = Utilities:GetRarityColor(petData.rarity)
        glow.ZIndex = 102
        glow.Parent = item
    end
    
    return item
end

function UIModules.CaseOpeningUI:ShowResult(container, result)
    -- Clear spinner
    local spinner = container:FindFirstChild("SpinnerFrame")
    if spinner then
        Utilities:Tween(spinner, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        for _, child in ipairs(spinner:GetDescendants()) do
            if child:IsA("GuiObject") then
                Utilities:Tween(child, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
            end
        end
    end
    
    wait(0.3)
    
    -- Show result
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(1, -100, 1, -200)
    resultFrame.Position = UDim2.new(0, 50, 0, 100)
    resultFrame.BackgroundTransparency = 1
    resultFrame.ZIndex = 103
    resultFrame.Parent = container
    
    -- Pet model/image
    local petDisplay = Instance.new("ViewportFrame")
    petDisplay.Size = UDim2.new(0, 300, 0, 300)
    petDisplay.Position = UDim2.new(0.5, -150, 0, 20)
    petDisplay.BackgroundTransparency = 1
    petDisplay.ZIndex = 104
    petDisplay.Parent = resultFrame
    
    -- For now, show image instead of 3D model
    local petImage = UIComponents:CreateImageLabel(petDisplay, result.petData.imageId, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
    petImage.ZIndex = 104
    
    -- Rarity effects
    local rarityColor = Utilities:GetRarityColor(result.petData.rarity)
    
    -- Background glow
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 100, 1, 100)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = rarityColor
    glow.ImageTransparency = 0.5
    glow.ZIndex = 103
    glow.Parent = petDisplay
    
    -- Animate glow
    spawn(function()
        while glow.Parent do
            Utilities:Tween(glow, {Size = UDim2.new(1, 120, 1, 120), ImageTransparency = 0.3}, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(1)
            Utilities:Tween(glow, {Size = UDim2.new(1, 100, 1, 100), ImageTransparency = 0.5}, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(1)
        end
    end)
    
    -- "You Got!" text
    local gotLabel = UIComponents:CreateLabel(resultFrame, "You Got!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 330), 32)
    gotLabel.Font = CLIENT_CONFIG.FONTS.Display
    gotLabel.TextColor3 = rarityColor
    gotLabel.ZIndex = 104
    
    -- Pet name
    local nameLabel = UIComponents:CreateLabel(resultFrame, result.petData.displayName, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 370), 28)
    nameLabel.Font = CLIENT_CONFIG.FONTS.Display
    nameLabel.ZIndex = 104
    
    -- Variant label
    if result.variant ~= "normal" then
        local variantLabel = UIComponents:CreateLabel(resultFrame, "✨ " .. result.variant:upper() .. " VARIANT! ✨", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 410), 20)
        variantLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        variantLabel.TextColor3 = rarityColor
        variantLabel.ZIndex = 104
        
        -- Extra particles for special variants
        ParticleSystem:CreateBurst(resultFrame, "star", UDim2.new(0.5, 0, 0.5, 0), 20)
    end
    
    -- Rarity label
    local rarityNames = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "SECRET"}
    local rarityLabel = UIComponents:CreateLabel(resultFrame, rarityNames[result.petData.rarity] or "Unknown", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 440), 18)
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    rarityLabel.ZIndex = 104
    
    -- Sound effects
    if result.petData.rarity >= 5 then
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Legendary)
    else
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
    end
    
    -- Particles based on rarity
    if result.petData.rarity >= 4 then
        for i = 1, 50 do
            spawn(function()
                wait(i * 0.05)
                ParticleSystem:CreateParticle(resultFrame, "star", UDim2.new(math.random(), 0, 1, 0))
            end)
        end
    end
    
    -- Fade in
    for _, obj in ipairs(resultFrame:GetDescendants()) do
        if obj:IsA("GuiObject") then
            local transparency = obj.BackgroundTransparency
            obj.BackgroundTransparency = 1
            Utilities:Tween(obj, {BackgroundTransparency = transparency}, CLIENT_CONFIG.TWEEN_INFO.Slow)
        end
        if obj:IsA("TextLabel") then
            local transparency = obj.TextTransparency
            obj.TextTransparency = 1
            Utilities:Tween(obj, {TextTransparency = transparency}, CLIENT_CONFIG.TWEEN_INFO.Slow)
        end
        if obj:IsA("ImageLabel") then
            local transparency = obj.ImageTransparency
            obj.ImageTransparency = 1
            Utilities:Tween(obj, {ImageTransparency = transparency}, CLIENT_CONFIG.TWEEN_INFO.Slow)
        end
    end
end

-- Continue in Part 3...