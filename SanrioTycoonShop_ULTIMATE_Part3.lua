-- ========================================
-- ADVANCED UI SYSTEM WITH ANIMATIONS
-- ========================================
local UISystem = {
    screenGuis = {},
    animations = {},
    particles = {},
    
    createMainShopUI = function(player)
        local playerGui = player:WaitForChild("PlayerGui")
        
        -- Create main ScreenGui with advanced properties
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SanrioTycoonShopUltimate"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 10
        screenGui.IgnoreGuiInset = true
        screenGui.Parent = playerGui
        
        UISystem.screenGuis[player.UserId] = screenGui
        
        -- Create blur effect for background
        local blurEffect = Instance.new("BlurEffect")
        blurEffect.Size = 0
        blurEffect.Parent = Services.Lighting
        
        -- Main container with glass morphism effect
        local mainContainer = Instance.new("Frame")
        mainContainer.Name = "MainContainer"
        mainContainer.Size = UDim2.new(0.95, 0, 0.9, 0)
        mainContainer.Position = UDim2.new(0.025, 0, 0.05, 0)
        mainContainer.BackgroundColor3 = Color3.fromRGB(255, 240, 245)
        mainContainer.BackgroundTransparency = 0.1
        mainContainer.BorderSizePixel = 0
        mainContainer.ClipsDescendants = true
        mainContainer.Parent = screenGui
        
        -- Advanced corner styling
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 30)
        mainCorner.Parent = mainContainer
        
        -- Glass effect gradient
        local glassGradient = Instance.new("UIGradient")
        glassGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 240))
        }
        glassGradient.Rotation = 45
        glassGradient.Parent = mainContainer
        
        -- Add drop shadow
        UISystem.createDropShadow(mainContainer)
        
        -- Header with animated gradient
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0.12, 0)
        header.Position = UDim2.new(0, 0, 0, 0)
        header.BackgroundColor3 = Color3.fromRGB(255, 100, 150)
        header.BorderSizePixel = 0
        header.Parent = mainContainer
        
        local headerGradient = Instance.new("UIGradient")
        headerGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 150)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 200))
        }
        headerGradient.Rotation = 0
        headerGradient.Parent = header
        
        -- Animate header gradient
        spawn(function()
            while header.Parent do
                for i = 0, 360, 2 do
                    headerGradient.Rotation = i
                    wait(0.03)
                end
            end
        end)
        
        -- Logo and title with effects
        local logoContainer = Instance.new("Frame")
        logoContainer.Size = UDim2.new(0.3, 0, 0.8, 0)
        logoContainer.Position = UDim2.new(0.02, 0, 0.1, 0)
        logoContainer.BackgroundTransparency = 1
        logoContainer.Parent = header
        
        local logoImage = Instance.new("ImageLabel")
        logoImage.Size = UDim2.new(0.2, 0, 1, 0)
        logoImage.Position = UDim2.new(0, 0, 0, 0)
        logoImage.BackgroundTransparency = 1
        logoImage.Image = "rbxassetid://10000000001" -- Sanrio logo
        logoImage.ScaleType = Enum.ScaleType.Fit
        logoImage.Parent = logoContainer
        
        -- Floating animation for logo
        UISystem.createFloatingAnimation(logoImage)
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(0.75, 0, 1, 0)
        titleLabel.Position = UDim2.new(0.22, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Sanrio Tycoon Ultimate Shop"
        titleLabel.TextColor3 = Color3.white
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.FredokaOne
        titleLabel.Parent = logoContainer
        
        -- Add text stroke with glow
        local titleStroke = Instance.new("UIStroke")
        titleStroke.Color = Color3.fromRGB(255, 50, 100)
        titleStroke.Thickness = 3
        titleStroke.Parent = titleLabel
        
        -- Currency display with live updates
        local currencyFrame = Instance.new("Frame")
        currencyFrame.Size = UDim2.new(0.4, 0, 0.8, 0)
        currencyFrame.Position = UDim2.new(0.58, 0, 0.1, 0)
        currencyFrame.BackgroundTransparency = 1
        currencyFrame.Parent = header
        
        local currencyLayout = Instance.new("UIListLayout")
        currencyLayout.FillDirection = Enum.FillDirection.Horizontal
        currencyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        currencyLayout.Padding = UDim.new(0, 15)
        currencyLayout.Parent = currencyFrame
        
        -- Create currency displays
        local currencies = {"Coins", "Gems", "Tickets"}
        local currencyColors = {
            Coins = Color3.fromRGB(255, 215, 0),
            Gems = Color3.fromRGB(100, 200, 255),
            Tickets = Color3.fromRGB(255, 100, 255)
        }
        
        for _, currency in ipairs(currencies) do
            local currencyDisplay = UISystem.createCurrencyDisplay(
                currency,
                PlayerData[player.UserId] and PlayerData[player.UserId].currencies[string.lower(currency)] or 0,
                currencyColors[currency]
            )
            currencyDisplay.Parent = currencyFrame
        end
        
        -- Navigation tabs with advanced styling
        local navFrame = Instance.new("Frame")
        navFrame.Name = "Navigation"
        navFrame.Size = UDim2.new(0.96, 0, 0.08, 0)
        navFrame.Position = UDim2.new(0.02, 0, 0.13, 0)
        navFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        navFrame.BackgroundTransparency = 0.3
        navFrame.Parent = mainContainer
        
        local navCorner = Instance.new("UICorner")
        navCorner.CornerRadius = UDim.new(0, 20)
        navCorner.Parent = navFrame
        
        local navLayout = Instance.new("UIListLayout")
        navLayout.FillDirection = Enum.FillDirection.Horizontal
        navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        navLayout.Padding = UDim.new(0, 5)
        navLayout.Parent = navFrame
        
        -- Tab categories
        local tabs = {
            {name = "Eggs", icon = "🥚", color = Color3.fromRGB(255, 200, 100)},
            {name = "Gamepasses", icon = "🎫", color = Color3.fromRGB(100, 255, 100)},
            {name = "Currency", icon = "💎", color = Color3.fromRGB(100, 200, 255)},
            {name = "Pets", icon = "🐾", color = Color3.fromRGB(255, 150, 200)},
            {name = "Trading", icon = "🤝", color = Color3.fromRGB(200, 150, 255)},
            {name = "Battle", icon = "⚔️", color = Color3.fromRGB(255, 100, 100)},
            {name = "Clan", icon = "🏰", color = Color3.fromRGB(150, 200, 100)},
            {name = "Events", icon = "🎉", color = Color3.fromRGB(255, 200, 50)}
        }
        
        local tabButtons = {}
        local contentFrames = {}
        
        for i, tabData in ipairs(tabs) do
            local tabButton = UISystem.createTabButton(tabData)
            tabButton.Parent = navFrame
            tabButtons[tabData.name] = tabButton
            
            local contentFrame = UISystem.createContentFrame(tabData.name)
            contentFrame.Parent = mainContainer
            contentFrame.Visible = (i == 1)
            contentFrames[tabData.name] = contentFrame
            
            -- Tab switching with animations
            tabButton.MouseButton1Click:Connect(function()
                UISystem.switchTab(tabData.name, tabButtons, contentFrames)
            end)
        end
        
        -- Content area with dynamic loading
        local contentArea = Instance.new("Frame")
        contentArea.Name = "ContentArea"
        contentArea.Size = UDim2.new(0.96, 0, 0.76, 0)
        contentArea.Position = UDim2.new(0.02, 0, 0.22, 0)
        contentArea.BackgroundTransparency = 1
        contentArea.Parent = mainContainer
        
        -- Initialize first tab
        UISystem.loadEggsTab(contentFrames["Eggs"], player)
        
        -- Close button with hover effects
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 40, 0, 40)
        closeButton.Position = UDim2.new(1, -50, 0, 10)
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        closeButton.Text = "✖"
        closeButton.TextColor3 = Color3.white
        closeButton.TextScaled = true
        closeButton.Font = Enum.Font.GothamBold
        closeButton.Parent = header
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0.5, 0)
        closeCorner.Parent = closeButton
        
        closeButton.MouseEnter:Connect(function()
            UISystem.tweenSize(closeButton, UDim2.new(0, 45, 0, 45), 0.1)
        end)
        
        closeButton.MouseLeave:Connect(function()
            UISystem.tweenSize(closeButton, UDim2.new(0, 40, 0, 40), 0.1)
        end)
        
        closeButton.MouseButton1Click:Connect(function()
            UISystem.closeShop(player, screenGui, blurEffect)
        end)
        
        -- Open animation
        mainContainer.Size = UDim2.new(0, 0, 0, 0)
        mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        UISystem.tweenSize(mainContainer, UDim2.new(0.95, 0, 0.9, 0), 0.5, Enum.EasingStyle.Back)
        UISystem.tweenPosition(mainContainer, UDim2.new(0.025, 0, 0.05, 0), 0.5, Enum.EasingStyle.Back)
        
        local blurInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local blurTween = Services.TweenService:Create(blurEffect, blurInfo, {Size = 24})
        blurTween:Play()
        
        return screenGui
    end,
    
    createDropShadow = function(frame)
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 20, 1, 20)
        shadow.Position = UDim2.new(0, -10, 0, -10)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.7
        shadow.ZIndex = frame.ZIndex - 1
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 35)
        shadowCorner.Parent = shadow
        
        shadow.Parent = frame.Parent
        frame.Parent = shadow.Parent
        
        return shadow
    end,
    
    createFloatingAnimation = function(object)
        spawn(function()
            local startPos = object.Position
            while object.Parent do
                local floatInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                local floatUp = Services.TweenService:Create(object, floatInfo, {
                    Position = startPos + UDim2.new(0, 0, -0.05, 0)
                })
                floatUp:Play()
                floatUp.Completed:Wait()
                
                local floatDown = Services.TweenService:Create(object, floatInfo, {
                    Position = startPos
                })
                floatDown:Play()
                floatDown.Completed:Wait()
            end
        end)
    end,
    
    createCurrencyDisplay = function(currencyName, amount, color)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 150, 1, 0)
        container.BackgroundColor3 = Color3.white
        container.BackgroundTransparency = 0.2
        container.BorderSizePixel = 0
        
        local containerCorner = Instance.new("UICorner")
        containerCorner.CornerRadius = UDim.new(0, 15)
        containerCorner.Parent = container
        
        local iconFrame = Instance.new("Frame")
        iconFrame.Size = UDim2.new(0.3, 0, 0.8, 0)
        iconFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
        iconFrame.BackgroundColor3 = color
        iconFrame.BorderSizePixel = 0
        iconFrame.Parent = container
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0.5, 0)
        iconCorner.Parent = iconFrame
        
        local amountLabel = Instance.new("TextLabel")
        amountLabel.Size = UDim2.new(0.6, 0, 1, 0)
        amountLabel.Position = UDim2.new(0.38, 0, 0, 0)
        amountLabel.BackgroundTransparency = 1
        amountLabel.Text = UISystem.formatNumber(amount)
        amountLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        amountLabel.TextScaled = true
        amountLabel.Font = Enum.Font.GothamBold
        amountLabel.Parent = container
        
        -- Live update connection
        spawn(function()
            while container.Parent do
                wait(0.1)
                local player = Services.Players.LocalPlayer
                if player and PlayerData[player.UserId] then
                    local newAmount = PlayerData[player.UserId].currencies[string.lower(currencyName)] or 0
                    if newAmount ~= amount then
                        amount = newAmount
                        amountLabel.Text = UISystem.formatNumber(amount)
                        
                        -- Flash effect on change
                        local flash = Instance.new("Frame")
                        flash.Size = UDim2.new(1, 0, 1, 0)
                        flash.BackgroundColor3 = color
                        flash.BackgroundTransparency = 0.5
                        flash.BorderSizePixel = 0
                        flash.Parent = container
                        
                        local flashCorner = Instance.new("UICorner")
                        flashCorner.CornerRadius = UDim.new(0, 15)
                        flashCorner.Parent = flash
                        
                        local flashInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
                        local flashTween = Services.TweenService:Create(flash, flashInfo, {
                            BackgroundTransparency = 1
                        })
                        flashTween:Play()
                        flashTween.Completed:Connect(function()
                            flash:Destroy()
                        end)
                    end
                end
            end
        end)
        
        return container
    end,
    
    formatNumber = function(number)
        if number >= 1000000000000 then
            return string.format("%.2fT", number / 1000000000000)
        elseif number >= 1000000000 then
            return string.format("%.2fB", number / 1000000000)
        elseif number >= 1000000 then
            return string.format("%.2fM", number / 1000000)
        elseif number >= 1000 then
            return string.format("%.2fK", number / 1000)
        else
            return tostring(number)
        end
    end,
    
    createTabButton = function(tabData)
        local button = Instance.new("TextButton")
        button.Name = tabData.name .. "Tab"
        button.Size = UDim2.new(0.12, 0, 0.9, 0)
        button.BackgroundColor3 = tabData.color
        button.BackgroundTransparency = 0.3
        button.Text = tabData.icon .. " " .. tabData.name
        button.TextColor3 = Color3.white
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.AutoButtonColor = false
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 15)
        buttonCorner.Parent = button
        
        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = tabData.color
        buttonStroke.Thickness = 0
        buttonStroke.Parent = button
        
        -- Hover effects
        button.MouseEnter:Connect(function()
            UISystem.tweenProperty(button, "BackgroundTransparency", 0, 0.1)
            UISystem.tweenProperty(buttonStroke, "Thickness", 3, 0.1)
        end)
        
        button.MouseLeave:Connect(function()
            if not button:GetAttribute("Selected") then
                UISystem.tweenProperty(button, "BackgroundTransparency", 0.3, 0.1)
                UISystem.tweenProperty(buttonStroke, "Thickness", 0, 0.1)
            end
        end)
        
        return button
    end,
    
    createContentFrame = function(name)
        local frame = Instance.new("ScrollingFrame")
        frame.Name = name .. "Content"
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Position = UDim2.new(0, 0, 0, 0)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 8
        frame.ScrollBarImageColor3 = Color3.fromRGB(255, 150, 200)
        frame.ScrollBarImageTransparency = 0.3
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        return frame
    end,
    
    switchTab = function(tabName, tabButtons, contentFrames)
        -- Deselect all tabs
        for name, button in pairs(tabButtons) do
            button:SetAttribute("Selected", false)
            UISystem.tweenProperty(button, "BackgroundTransparency", 0.3, 0.2)
            local stroke = button:FindFirstChild("UIStroke")
            if stroke then
                UISystem.tweenProperty(stroke, "Thickness", 0, 0.2)
            end
        end
        
        -- Hide all content
        for name, frame in pairs(contentFrames) do
            frame.Visible = false
        end
        
        -- Select new tab
        local selectedButton = tabButtons[tabName]
        local selectedContent = contentFrames[tabName]
        
        if selectedButton and selectedContent then
            selectedButton:SetAttribute("Selected", true)
            UISystem.tweenProperty(selectedButton, "BackgroundTransparency", 0, 0.2)
            local stroke = selectedButton:FindFirstChild("UIStroke")
            if stroke then
                UISystem.tweenProperty(stroke, "Thickness", 3, 0.2)
            end
            
            -- Show content with fade animation
            selectedContent.Visible = true
            selectedContent.GroupTransparency = 1
            UISystem.tweenProperty(selectedContent, "GroupTransparency", 0, 0.3)
            
            -- Load content if not already loaded
            if not selectedContent:GetAttribute("Loaded") then
                UISystem.loadTabContent(tabName, selectedContent)
                selectedContent:SetAttribute("Loaded", true)
            end
        end
    end,
    
    loadTabContent = function(tabName, contentFrame)
        local player = Services.Players.LocalPlayer
        
        if tabName == "Eggs" then
            UISystem.loadEggsTab(contentFrame, player)
        elseif tabName == "Gamepasses" then
            UISystem.loadGamepassesTab(contentFrame, player)
        elseif tabName == "Currency" then
            UISystem.loadCurrencyTab(contentFrame, player)
        elseif tabName == "Pets" then
            UISystem.loadPetsTab(contentFrame, player)
        elseif tabName == "Trading" then
            UISystem.loadTradingTab(contentFrame, player)
        elseif tabName == "Battle" then
            UISystem.loadBattleTab(contentFrame, player)
        elseif tabName == "Clan" then
            UISystem.loadClanTab(contentFrame, player)
        elseif tabName == "Events" then
            UISystem.loadEventsTab(contentFrame, player)
        end
    end,
    
    loadEggsTab = function(contentFrame, player)
        -- Create grid layout
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0.3, 0, 0.5, 0)
        gridLayout.CellPadding = UDim2.new(0.025, 0, 0.05, 0)
        gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = contentFrame
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 20)
        padding.PaddingBottom = UDim.new(0, 20)
        padding.PaddingLeft = UDim.new(0, 20)
        padding.PaddingRight = UDim.new(0, 20)
        padding.Parent = contentFrame
        
        -- Create egg cards
        for eggId, eggData in pairs(EggCases) do
            local eggCard = UISystem.createEggCard(eggData, player)
            eggCard.Parent = contentFrame
        end
    end,
    
    createEggCard = function(eggData, player)
        local card = Instance.new("Frame")
        card.Name = eggData.id .. "Card"
        card.BackgroundColor3 = Color3.white
        card.BorderSizePixel = 0
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 20)
        cardCorner.Parent = card
        
        -- Add gradient background
        local cardGradient = Instance.new("UIGradient")
        cardGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.white),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 240, 240))
        }
        cardGradient.Rotation = 90
        cardGradient.Parent = card
        
        -- Egg image container
        local imageContainer = Instance.new("Frame")
        imageContainer.Size = UDim2.new(1, 0, 0.5, 0)
        imageContainer.Position = UDim2.new(0, 0, 0, 0)
        imageContainer.BackgroundTransparency = 1
        imageContainer.Parent = card
        
        local eggImage = Instance.new("ImageLabel")
        eggImage.Size = UDim2.new(0.7, 0, 0.9, 0)
        eggImage.Position = UDim2.new(0.15, 0, 0.05, 0)
        eggImage.BackgroundTransparency = 1
        eggImage.Image = eggData.imageId
        eggImage.ScaleType = Enum.ScaleType.Fit
        eggImage.Parent = imageContainer
        
        -- Floating animation
        UISystem.createFloatingAnimation(eggImage)
        
        -- Rarity indicator
        local rarityColors = {
            starter_egg = Color3.fromRGB(150, 150, 150),
            premium_egg = Color3.fromRGB(100, 200, 255),
            legendary_egg = Color3.fromRGB(255, 215, 0),
            mythical_egg = Color3.fromRGB(255, 100, 255),
            valentine_egg = Color3.fromRGB(255, 100, 150)
        }
        
        local rarityStrip = Instance.new("Frame")
        rarityStrip.Size = UDim2.new(1, 0, 0, 5)
        rarityStrip.Position = UDim2.new(0, 0, 0.5, -2)
        rarityStrip.BackgroundColor3 = rarityColors[eggData.id] or Color3.white
        rarityStrip.BorderSizePixel = 0
        rarityStrip.Parent = card
        
        -- Info section
        local infoFrame = Instance.new("Frame")
        infoFrame.Size = UDim2.new(1, -20, 0.45, -10)
        infoFrame.Position = UDim2.new(0, 10, 0.52, 0)
        infoFrame.BackgroundTransparency = 1
        infoFrame.Parent = card
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.2, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = eggData.name
        nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = infoFrame
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, 0, 0.3, 0)
        descLabel.Position = UDim2.new(0, 0, 0.2, 0)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = eggData.description
        descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        descLabel.TextScaled = true
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextWrapped = true
        descLabel.Parent = infoFrame
        
        -- Price button
        local priceButton = Instance.new("TextButton")
        priceButton.Size = UDim2.new(0.8, 0, 0.25, 0)
        priceButton.Position = UDim2.new(0.1, 0, 0.65, 0)
        priceButton.BackgroundColor3 = rarityColors[eggData.id] or Color3.fromRGB(100, 200, 255)
        priceButton.Text = eggData.price .. " " .. eggData.currency
        priceButton.TextColor3 = Color3.white
        priceButton.TextScaled = true
        priceButton.Font = Enum.Font.GothamBold
        priceButton.Parent = infoFrame
        
        local priceCorner = Instance.new("UICorner")
        priceCorner.CornerRadius = UDim.new(0, 12)
        priceCorner.Parent = priceButton
        
        -- Click effect
        priceButton.MouseButton1Click:Connect(function()
            UISystem.openEggAnimation(player, eggData)
        end)
        
        -- Hover effects
        card.MouseEnter:Connect(function()
            UISystem.tweenSize(card, UDim2.new(0.32, 0, 0.52, 0), 0.2, Enum.EasingStyle.Back)
            local shadow = UISystem.createDropShadow(card)
            shadow.Name = "HoverShadow"
        end)
        
        card.MouseLeave:Connect(function()
            UISystem.tweenSize(card, UDim2.new(0.3, 0, 0.5, 0), 0.2)
            local shadow = card.Parent:FindFirstChild("HoverShadow")
            if shadow then shadow:Destroy() end
        end)
        
        return card
    end,
    
    openEggAnimation = function(player, eggData)
        -- This would trigger the server-side egg opening
        -- and create the opening animation UI
        
        local screenGui = UISystem.screenGuis[player.UserId]
        if not screenGui then return end
        
        -- Create fullscreen overlay
        local overlay = Instance.new("Frame")
        overlay.Name = "EggOpeningOverlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 0.3
        overlay.ZIndex = 100
        overlay.Parent = screenGui
        
        -- Fade in
        overlay.BackgroundTransparency = 1
        UISystem.tweenProperty(overlay, "BackgroundTransparency", 0.3, 0.3)
        
        -- Create egg opening container
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.8, 0, 0.7, 0)
        container.Position = UDim2.new(0.1, 0, 0.15, 0)
        container.BackgroundColor3 = Color3.white
        container.ZIndex = 101
        container.Parent = overlay
        
        local containerCorner = Instance.new("UICorner")
        containerCorner.CornerRadius = UDim.new(0, 30)
        containerCorner.Parent = container
        
        -- Request egg opening from server
        local remoteEvent = Services.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("OpenCase")
        remoteEvent:FireServer(eggData.id)
    end,
    
    -- Utility functions
    tweenSize = function(object, targetSize, duration, easingStyle)
        easingStyle = easingStyle or Enum.EasingStyle.Quad
        local info = TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out)
        local tween = Services.TweenService:Create(object, info, {Size = targetSize})
        tween:Play()
        return tween
    end,
    
    tweenPosition = function(object, targetPosition, duration, easingStyle)
        easingStyle = easingStyle or Enum.EasingStyle.Quad
        local info = TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out)
        local tween = Services.TweenService:Create(object, info, {Position = targetPosition})
        tween:Play()
        return tween
    end,
    
    tweenProperty = function(object, property, targetValue, duration)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = Services.TweenService:Create(object, info, {[property] = targetValue})
        tween:Play()
        return tween
    end,
    
    closeShop = function(player, screenGui, blurEffect)
        -- Close animation
        local mainContainer = screenGui:FindFirstChild("MainContainer")
        if mainContainer then
            UISystem.tweenSize(mainContainer, UDim2.new(0, 0, 0, 0), 0.3, Enum.EasingStyle.Back)
            UISystem.tweenPosition(mainContainer, UDim2.new(0.5, 0, 0.5, 0), 0.3, Enum.EasingStyle.Back)
        end
        
        if blurEffect then
            local blurInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local blurTween = Services.TweenService:Create(blurEffect, blurInfo, {Size = 0})
            blurTween:Play()
            blurTween.Completed:Connect(function()
                blurEffect:Destroy()
            end)
        end
        
        wait(0.3)
        screenGui:Destroy()
        UISystem.screenGuis[player.UserId] = nil
    end
}

-- ========================================
-- PARTICLE & EFFECTS SYSTEM
-- ========================================
local EffectsSystem = {
    createSparkleEffect = function(parent, color)
        local attachment = Instance.new("Attachment")
        attachment.Parent = parent
        
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        sparkles.LightEmission = 1
        sparkles.LightInfluence = 0
        sparkles.Color = ColorSequence.new(color or Color3.fromRGB(255, 255, 100))
        sparkles.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(1, 0)
        }
        sparkles.Lifetime = NumberRange.new(1, 2)
        sparkles.Rate = 50
        sparkles.Speed = NumberRange.new(5, 10)
        sparkles.SpreadAngle = Vector2.new(180, 180)
        sparkles.VelocityInheritance = 0
        sparkles.Parent = attachment
        
        return sparkles
    end,
    
    createRainbowEffect = function(parent)
        local attachment = Instance.new("Attachment")
        attachment.Parent = parent
        
        local rainbow = Instance.new("ParticleEmitter")
        rainbow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        rainbow.LightEmission = 1
        rainbow.LightInfluence = 0
        rainbow.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238))
        }
        rainbow.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 1.5),
            NumberSequenceKeypoint.new(1, 0)
        }
        rainbow.Lifetime = NumberRange.new(2, 3)
        rainbow.Rate = 100
        rainbow.Speed = NumberRange.new(10, 20)
        rainbow.SpreadAngle = Vector2.new(360, 360)
        rainbow.VelocityInheritance = 0
        rainbow.RotSpeed = NumberRange.new(100, 300)
        rainbow.Parent = attachment
        
        return rainbow
    end,
    
    createExplosionEffect = function(position, color, size)
        local part = Instance.new("Part")
        part.Name = "ExplosionEffect"
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Position = position
        part.Size = Vector3.new(1, 1, 1)
        part.Parent = workspace
        
        local attachment = Instance.new("Attachment")
        attachment.Parent = part
        
        -- Main explosion
        local explosion = Instance.new("ParticleEmitter")
        explosion.Texture = "rbxasset://textures/particles/explosion.dds"
        explosion.LightEmission = 1
        explosion.LightInfluence = 0
        explosion.Color = ColorSequence.new(color or Color3.fromRGB(255, 200, 100))
        explosion.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, size or 10),
            NumberSequenceKeypoint.new(1, (size or 10) * 3)
        }
        explosion.Lifetime = NumberRange.new(0.5, 1)
        explosion.Rate = 0
        explosion.Speed = NumberRange.new(50, 100)
        explosion.SpreadAngle = Vector2.new(360, 360)
        explosion.VelocityInheritance = 0
        explosion.Parent = attachment
        
        explosion:Emit(100)
        
        -- Shockwave
        local shockwave = Instance.new("ParticleEmitter")
        shockwave.Texture = "rbxasset://textures/particles/smoke_main.dds"
        shockwave.LightEmission = 0.5
        shockwave.LightInfluence = 0
        shockwave.Color = ColorSequence.new(Color3.white)
        shockwave.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, size or 10),
            NumberSequenceKeypoint.new(1, (size or 10) * 2)
        }
        shockwave.Lifetime = NumberRange.new(1)
        shockwave.Rate = 0
        shockwave.Speed = NumberRange.new(0)
        shockwave.SpreadAngle = Vector2.new(0, 0)
        shockwave.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 1)
        }
        shockwave.Parent = attachment
        
        shockwave:Emit(1)
        
        -- Clean up after 3 seconds
        Services.Debris:AddItem(part, 3)
        
        return part
    end,
    
    createLegendaryAura = function(character)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        -- Bottom attachment
        local bottomAttachment = Instance.new("Attachment")
        bottomAttachment.Position = Vector3.new(0, -3, 0)
        bottomAttachment.Parent = rootPart
        
        -- Top attachment
        local topAttachment = Instance.new("Attachment")
        topAttachment.Position = Vector3.new(0, 3, 0)
        topAttachment.Parent = rootPart
        
        -- Aura beam
        local beam = Instance.new("Beam")
        beam.Attachment0 = bottomAttachment
        beam.Attachment1 = topAttachment
        beam.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
        }
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.5)
        }
        beam.Width0 = 5
        beam.Width1 = 5
        beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        beam.TextureSpeed = 2
        beam.Parent = rootPart
        
        -- Rotating particles
        local particles = Instance.new("ParticleEmitter")
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.LightEmission = 1
        particles.LightInfluence = 0
        particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
        particles.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        }
        particles.Lifetime = NumberRange.new(2)
        particles.Rate = 30
        particles.Speed = NumberRange.new(5)
        particles.SpreadAngle = Vector2.new(0, 0)
        particles.VelocityInheritance = 0
        particles.Parent = bottomAttachment
        
        -- Rotate the attachments
        spawn(function()
            while bottomAttachment.Parent do
                bottomAttachment.CFrame = bottomAttachment.CFrame * CFrame.Angles(0, math.rad(5), 0)
                topAttachment.CFrame = topAttachment.CFrame * CFrame.Angles(0, math.rad(-5), 0)
                wait()
            end
        end)
        
        return {beam = beam, particles = particles}
    end
}

-- ========================================
-- SOUND SYSTEM
-- ========================================
local SoundSystem = {
    sounds = {},
    music = {},
    
    initialize = function()
        -- UI Sounds
        SoundSystem.sounds.click = SoundSystem.createSound("rbxassetid://876939830", 0.5)
        SoundSystem.sounds.hover = SoundSystem.createSound("rbxassetid://550209561", 0.3)
        SoundSystem.sounds.open = SoundSystem.createSound("rbxassetid://511340819", 0.7)
        SoundSystem.sounds.close = SoundSystem.createSound("rbxassetid://550209561", 0.5)
        
        -- Egg Opening Sounds
        SoundSystem.sounds.eggCrack = SoundSystem.createSound("rbxassetid://2767090", 0.8)
        SoundSystem.sounds.eggHatch = SoundSystem.createSound("rbxassetid://182765513", 1)
        
        -- Rarity Sounds
        SoundSystem.sounds.commonReveal = SoundSystem.createSound("rbxassetid://1838439224", 0.6)
        SoundSystem.sounds.rareReveal = SoundSystem.createSound("rbxassetid://1838439355", 0.7)
        SoundSystem.sounds.epicReveal = SoundSystem.createSound("rbxassetid://1838439495", 0.8)
        SoundSystem.sounds.legendaryReveal = SoundSystem.createSound("rbxassetid://1838439689", 0.9)
        SoundSystem.sounds.mythicalReveal = SoundSystem.createSound("rbxassetid://1838439833", 1)
        
        -- Battle Sounds
        SoundSystem.sounds.attack = SoundSystem.createSound("rbxassetid://2767090", 0.6)
        SoundSystem.sounds.defend = SoundSystem.createSound("rbxassetid://2767090", 0.5)
        SoundSystem.sounds.victory = SoundSystem.createSound("rbxassetid://1838453689", 0.8)
        SoundSystem.sounds.defeat = SoundSystem.createSound("rbxassetid://1838453451", 0.6)
        
        -- Background Music
        SoundSystem.music.shop = SoundSystem.createSound("rbxassetid://1838615869", 0.3, true)
        SoundSystem.music.battle = SoundSystem.createSound("rbxassetid://1838616357", 0.4, true)
        SoundSystem.music.victory = SoundSystem.createSound("rbxassetid://1838616701", 0.5, true)
    end,
    
    createSound = function(soundId, volume, looped)
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.5
        sound.Looped = looped or false
        sound.Parent = Services.SoundService
        return sound
    end,
    
    play = function(soundName)
        local sound = SoundSystem.sounds[soundName]
        if sound then
            sound:Play()
        end
    end,
    
    playMusic = function(musicName)
        -- Stop all music
        for name, music in pairs(SoundSystem.music) do
            music:Stop()
        end
        
        -- Play selected music
        local music = SoundSystem.music[musicName]
        if music then
            music:Play()
        end
    end,
    
    stopMusic = function()
        for name, music in pairs(SoundSystem.music) do
            music:Stop()
        end
    end
}

-- Initialize sound system
SoundSystem.initialize()

-- ========================================
-- Continue in next part...
-- ========================================