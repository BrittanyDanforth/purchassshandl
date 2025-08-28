-- ========================================
-- INVENTORY UI MODULE
-- ========================================
UIModules.InventoryUI = {}

function UIModules.InventoryUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshInventory()
        return
    end
    
    -- Create main inventory frame
    local inventoryFrame = UIComponents:CreateFrame(MainUI.MainContainer, "InventoryFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    inventoryFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = inventoryFrame
    
    -- Header
    local header = UIComponents:CreateFrame(inventoryFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "🎀 My Pet Collection 🎀", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Stats bar
    local statsBar = Instance.new("Frame")
    statsBar.Size = UDim2.new(1, 0, 0, 40)
    statsBar.Position = UDim2.new(0, 0, 0, 60)
    statsBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    statsBar.Parent = inventoryFrame
    
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    statsLayout.Padding = UDim.new(0, 20)
    statsLayout.Parent = statsBar
    
    Utilities:CreatePadding(statsBar, 10)
    
    -- Pet count
    local petCountLabel = UIComponents:CreateLabel(statsBar, "Pets: 0/500", UDim2.new(0, 150, 1, 0), UDim2.new(0, 0, 0, 0), 16)
    petCountLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Equipped count
    local equippedLabel = UIComponents:CreateLabel(statsBar, "Equipped: 0/6", UDim2.new(0, 150, 1, 0), UDim2.new(0, 0, 0, 0), 16)
    equippedLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Storage usage
    local storageBar = UIComponents:CreateProgressBar(statsBar, UDim2.new(0, 200, 0, 20), UDim2.new(0, 0, 0.5, -10), 0, 500)
    
    self.StatsLabels = {
        PetCount = petCountLabel,
        Equipped = equippedLabel,
        Storage = storageBar
    }
    
    -- Filter and sort controls
    local controlsBar = Instance.new("Frame")
    controlsBar.Size = UDim2.new(1, 0, 0, 50)
    controlsBar.Position = UDim2.new(0, 0, 0, 100)
    controlsBar.BackgroundTransparency = 1
    controlsBar.Parent = inventoryFrame
    
    -- Search box
    local searchBox = UIComponents:CreateTextBox(controlsBar, "Search pets...", UDim2.new(0, 200, 0, 35), UDim2.new(0, 10, 0.5, -17.5))
    searchBox.Changed:Connect(function()
        self:FilterPets(searchBox.Text)
    end)
    
    -- Sort dropdown
    local sortOptions = {"Rarity", "Level", "Power", "Recent", "Name"}
    local sortDropdown = self:CreateDropdown(controlsBar, "Sort by", sortOptions, UDim2.new(0, 150, 0, 35), UDim2.new(0, 220, 0.5, -17.5))
    
    -- Filter dropdown
    local filterOptions = {"All", "Equipped", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Shiny", "Golden", "Rainbow"}
    local filterDropdown = self:CreateDropdown(controlsBar, "Filter", filterOptions, UDim2.new(0, 150, 0, 35), UDim2.new(0, 380, 0.5, -17.5))
    
    -- Mass actions
    local massDeleteButton = UIComponents:CreateButton(controlsBar, "Mass Delete", UDim2.new(0, 120, 0, 35), UDim2.new(1, -130, 0.5, -17.5), function()
        self:OpenMassDelete()
    end)
    massDeleteButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    
    -- Main content area with tabs
    local tabs = {
        {
            Name = "Pets",
            Init = function(parent)
                self:CreatePetGrid(parent)
            end
        },
        {
            Name = "Equipped",
            Init = function(parent)
                self:CreateEquippedView(parent)
            end
        },
        {
            Name = "Collection",
            Init = function(parent)
                self:CreateCollectionView(parent)
            end
        }
    }
    
    local tabContainer, tabFrames = UIComponents:CreateTab(inventoryFrame, tabs, UDim2.new(1, -20, 1, -170), UDim2.new(0, 10, 0, 160))
    self.TabFrames = tabFrames
    
    -- Initial inventory load
    self:RefreshInventory()
end

function UIModules.InventoryUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.InventoryUI:CreateDropdown(parent, placeholder, options, size, position)
    local dropdown = Instance.new("Frame")
    dropdown.Size = size
    dropdown.Position = position
    dropdown.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    dropdown.Parent = parent
    
    Utilities:CreateCorner(dropdown, 8)
    Utilities:CreateStroke(dropdown, CLIENT_CONFIG.COLORS.Primary, 2)
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = placeholder
    button.TextColor3 = CLIENT_CONFIG.COLORS.Dark
    button.Font = CLIENT_CONFIG.FONTS.Primary
    button.TextScaled = true
    button.Parent = dropdown
    
    Utilities:CreatePadding(button, 8)
    
    local arrow = UIComponents:CreateLabel(dropdown, "▼", UDim2.new(0, 20, 1, 0), UDim2.new(1, -25, 0, 0), 12)
    arrow.TextColor3 = CLIENT_CONFIG.COLORS.Dark
    
    local isOpen = false
    local optionsFrame = nil
    
    button.MouseButton1Click:Connect(function()
        if isOpen then
            if optionsFrame then
                optionsFrame:Destroy()
            end
            isOpen = false
            arrow.Text = "▼"
        else
            optionsFrame = Instance.new("Frame")
            optionsFrame.Size = UDim2.new(1, 0, 0, #options * 35)
            optionsFrame.Position = UDim2.new(0, 0, 1, 5)
            optionsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
            optionsFrame.ZIndex = dropdown.ZIndex + 10
            optionsFrame.Parent = dropdown
            
            Utilities:CreateCorner(optionsFrame, 8)
            Utilities:CreateShadow(optionsFrame, 0.3)
            
            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.Parent = optionsFrame
            
            for _, option in ipairs(options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Size = UDim2.new(1, 0, 0, 35)
                optionButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
                optionButton.Text = option
                optionButton.TextColor3 = CLIENT_CONFIG.COLORS.Dark
                optionButton.Font = CLIENT_CONFIG.FONTS.Primary
                optionButton.TextScaled = true
                optionButton.ZIndex = optionsFrame.ZIndex + 1
                optionButton.Parent = optionsFrame
                
                Utilities:CreatePadding(optionButton, 8)
                
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
                end)
                
                optionButton.MouseButton1Click:Connect(function()
                    button.Text = option
                    optionsFrame:Destroy()
                    isOpen = false
                    arrow.Text = "▼"
                    
                    -- Callback
                    if dropdown.OnSelect then
                        dropdown.OnSelect(option)
                    end
                end)
            end
            
            isOpen = true
            arrow.Text = "▲"
        end
    end)
    
    return dropdown
end

function UIModules.InventoryUI:CreatePetGrid(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.CellSize = UDim2.new(0, 150, 0, 180)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    self.PetGrid = scrollFrame
    self.GridLayout = gridLayout
    
    -- Update canvas size
    scrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function UIModules.InventoryUI:CreatePetCard(parent, petInstance, petData)
    local card = Instance.new("Frame")
    card.Name = petInstance.id
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 12)
    Utilities:CreateShadow(card, 0.2)
    
    -- Rarity background
    local rarityGradient = Utilities:CreateGradient(card, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.White),
        ColorSequenceKeypoint.new(1, Utilities:GetRarityColor(petData.rarity))
    }, 90)
    
    -- Pet image
    local petImage = UIComponents:CreateImageLabel(card, petData.imageId, UDim2.new(0, 100, 0, 100), UDim2.new(0.5, -50, 0, 15))
    
    -- Variant effect
    if petInstance.variant ~= "normal" then
        local variantOverlay = Instance.new("ImageLabel")
        variantOverlay.Size = UDim2.new(1, 0, 1, 0)
        variantOverlay.BackgroundTransparency = 1
        variantOverlay.Image = "rbxassetid://5028857084"
        variantOverlay.ImageTransparency = 0.7
        variantOverlay.Parent = petImage
        
        if petInstance.variant == "shiny" then
            variantOverlay.ImageColor3 = Color3.fromRGB(255, 255, 200)
            
            -- Sparkle animation
            spawn(function()
                while variantOverlay.Parent do
                    Utilities:Tween(variantOverlay, {ImageTransparency = 0.5}, TweenInfo.new(1, Enum.EasingStyle.Sine))
                    wait(1)
                    Utilities:Tween(variantOverlay, {ImageTransparency = 0.7}, TweenInfo.new(1, Enum.EasingStyle.Sine))
                    wait(1)
                end
            end)
        elseif petInstance.variant == "golden" then
            variantOverlay.ImageColor3 = Color3.fromRGB(255, 215, 0)
        elseif petInstance.variant == "rainbow" then
            -- Rainbow animation
            spawn(function()
                local hue = 0
                while variantOverlay.Parent do
                    hue = (hue + 1) % 360
                    variantOverlay.ImageColor3 = Color3.fromHSV(hue / 360, 1, 1)
                    Services.RunService.Heartbeat:Wait()
                end
            end)
        elseif petInstance.variant == "dark_matter" then
            variantOverlay.ImageColor3 = Color3.fromRGB(50, 0, 100)
            variantOverlay.Image = "rbxassetid://5028857472" -- Different effect
        end
    end
    
    -- Level badge
    local levelBadge = Instance.new("Frame")
    levelBadge.Size = UDim2.new(0, 40, 0, 20)
    levelBadge.Position = UDim2.new(0, 5, 0, 5)
    levelBadge.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
    levelBadge.Parent = card
    
    Utilities:CreateCorner(levelBadge, 10)
    
    local levelLabel = UIComponents:CreateLabel(levelBadge, "Lv." .. petInstance.level, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 10)
    levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Equipped indicator
    if petInstance.equipped then
        local equippedBadge = Instance.new("Frame")
        equippedBadge.Size = UDim2.new(0, 20, 0, 20)
        equippedBadge.Position = UDim2.new(1, -25, 0, 5)
        equippedBadge.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
        equippedBadge.Parent = card
        
        Utilities:CreateCorner(equippedBadge, 10)
        
        local checkmark = UIComponents:CreateLabel(equippedBadge, "✓", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 14)
        checkmark.TextColor3 = CLIENT_CONFIG.COLORS.White
        checkmark.Font = CLIENT_CONFIG.FONTS.Secondary
    end
    
    -- Lock indicator
    if petInstance.locked then
        local lockIcon = UIComponents:CreateImageLabel(card, "rbxassetid://10709778200", UDim2.new(0, 20, 0, 20), UDim2.new(1, -25, 1, -25))
        lockIcon.ImageColor3 = CLIENT_CONFIG.COLORS.Error
    end
    
    -- Pet name
    local nameLabel = UIComponents:CreateLabel(card, petInstance.nickname or petData.displayName, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, 120), 14)
    nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    nameLabel.TextWrapped = true
    
    -- Stats preview
    local statsText = string.format("⚔️ %s 🛡️ %s", 
        Utilities:FormatNumber(petInstance.stats.power or 0),
        Utilities:FormatNumber(petInstance.stats.defense or 0)
    )
    local statsLabel = UIComponents:CreateLabel(card, statsText, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 1, -25), 12)
    statsLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Click handler
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:ShowPetDetails(petInstance, petData)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:ShowPetContextMenu(card, petInstance, petData)
        end
    end)
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        Utilities:Tween(card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Background}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        ParticleSystem:CreateParticle(card, "sparkle", UDim2.new(0.5, 0, 0.5, 0))
    end)
    
    card.MouseLeave:Connect(function()
        Utilities:Tween(card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    return card
end

function UIModules.InventoryUI:ShowPetDetails(petInstance, petData)
    -- Create modal overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "PetDetailsOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 200
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Details window
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Name = "PetDetailsFrame"
    detailsFrame.Size = UDim2.new(0, 700, 0, 500)
    detailsFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    detailsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    detailsFrame.ZIndex = 201
    detailsFrame.Parent = overlay
    
    Utilities:CreateCorner(detailsFrame, 20)
    Utilities:CreateShadow(detailsFrame, 0.5, 30)
    
    -- Animate in
    detailsFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    detailsFrame.Size = UDim2.new(0, 0, 0, 0)
    Utilities:Tween(detailsFrame, {
        Size = UDim2.new(0, 700, 0, 500),
        Position = UDim2.new(0.5, -350, 0.5, -250)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Utilities:GetRarityColor(petData.rarity)
    header.ZIndex = 202
    header.Parent = detailsFrame
    
    local headerCorner = Utilities:CreateCorner(header, 20)
    
    local bottomCorner = Instance.new("Frame")
    bottomCorner.Size = UDim2.new(1, 0, 0, 20)
    bottomCorner.Position = UDim2.new(0, 0, 1, -20)
    bottomCorner.BackgroundColor3 = header.BackgroundColor3
    bottomCorner.BorderSizePixel = 0
    bottomCorner.ZIndex = 202
    bottomCorner.Parent = header
    
    local titleLabel = UIComponents:CreateLabel(header, petInstance.nickname or petData.displayName, UDim2.new(1, -60, 1, 0), UDim2.new(0, 20, 0, 0), 24)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 203
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 24
    closeButton.ZIndex = 203
    closeButton.Parent = header
    
    closeButton.MouseButton1Click:Connect(function()
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Close)
        Utilities:Tween(detailsFrame, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        wait(0.3)
        overlay:Destroy()
    end)
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -80)
    content.Position = UDim2.new(0, 20, 0, 70)
    content.BackgroundTransparency = 1
    content.ZIndex = 202
    content.Parent = detailsFrame
    
    -- Left side - Pet display
    local leftSide = Instance.new("Frame")
    leftSide.Size = UDim2.new(0.4, -10, 1, 0)
    leftSide.BackgroundTransparency = 1
    leftSide.ZIndex = 202
    leftSide.Parent = content
    
    -- Pet image/model
    local petDisplay = Instance.new("ViewportFrame")
    petDisplay.Size = UDim2.new(1, 0, 0, 250)
    petDisplay.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    petDisplay.ZIndex = 202
    petDisplay.Parent = leftSide
    
    Utilities:CreateCorner(petDisplay, 12)
    
    -- For now, show image
    local petImage = UIComponents:CreateImageLabel(petDisplay, petData.imageId, UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.1, 0, 0.1, 0))
    petImage.ZIndex = 203
    
    -- Variant label
    if petInstance.variant ~= "normal" then
        local variantLabel = UIComponents:CreateLabel(leftSide, "✨ " .. petInstance.variant:upper() .. " ✨", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 260), 18)
        variantLabel.TextColor3 = Utilities:GetRarityColor(petData.rarity)
        variantLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        variantLabel.ZIndex = 203
    end
    
    -- Action buttons
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Size = UDim2.new(1, 0, 0, 100)
    actionsFrame.Position = UDim2.new(0, 0, 1, -100)
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.ZIndex = 202
    actionsFrame.Parent = leftSide
    
    local actionsLayout = Instance.new("UIListLayout")
    actionsLayout.FillDirection = Enum.FillDirection.Vertical
    actionsLayout.Padding = UDim.new(0, 10)
    actionsLayout.Parent = actionsFrame
    
    -- Equip/Unequip button
    local equipButton = UIComponents:CreateButton(actionsFrame, petInstance.equipped and "Unequip" or "Equip", UDim2.new(1, 0, 0, 40), nil, function()
        self:ToggleEquip(petInstance)
        equipButton.Text = petInstance.equipped and "Unequip" or "Equip"
    end)
    equipButton.BackgroundColor3 = petInstance.equipped and CLIENT_CONFIG.COLORS.Error or CLIENT_CONFIG.COLORS.Success
    
    -- Lock/Unlock button
    local lockButton = UIComponents:CreateButton(actionsFrame, petInstance.locked and "Unlock" or "Lock", UDim2.new(1, 0, 0, 40), nil, function()
        self:ToggleLock(petInstance)
        lockButton.Text = petInstance.locked and "Unlock" or "Lock"
    end)
    lockButton.BackgroundColor3 = petInstance.locked and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Warning
    
    -- Right side - Stats and info
    local rightSide = Instance.new("Frame")
    rightSide.Size = UDim2.new(0.6, -10, 1, 0)
    rightSide.Position = UDim2.new(0.4, 10, 0, 0)
    rightSide.BackgroundTransparency = 1
    rightSide.ZIndex = 202
    rightSide.Parent = content
    
    -- Stats tabs
    local statsTabs = {
        {
            Name = "Stats",
            Init = function(parent)
                self:ShowPetStats(parent, petInstance, petData)
            end
        },
        {
            Name = "Abilities",
            Init = function(parent)
                self:ShowPetAbilities(parent, petInstance, petData)
            end
        },
        {
            Name = "Info",
            Init = function(parent)
                self:ShowPetInfo(parent, petInstance, petData)
            end
        }
    }
    
    UIComponents:CreateTab(rightSide, statsTabs, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
end

function UIModules.InventoryUI:ShowPetStats(parent, petInstance, petData)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))
    
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, -10, 0, 500)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = scrollFrame
    
    local yOffset = 0
    
    -- Level and XP
    local levelFrame = Instance.new("Frame")
    levelFrame.Size = UDim2.new(1, 0, 0, 60)
    levelFrame.Position = UDim2.new(0, 0, 0, yOffset)
    levelFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    levelFrame.Parent = statsContainer
    
    Utilities:CreateCorner(levelFrame, 8)
    Utilities:CreatePadding(levelFrame, 10)
    
    local levelLabel = UIComponents:CreateLabel(levelFrame, "Level " .. petInstance.level, UDim2.new(0.5, 0, 0, 20), UDim2.new(0, 0, 0, 0), 16)
    levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local xpBar = UIComponents:CreateProgressBar(levelFrame, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 30), 
        petInstance.experience, petData.xpRequirements[petInstance.level] or 99999)
    
    yOffset = yOffset + 70
    
    -- Main stats
    local stats = {
        {name = "Power", icon = "⚔️", value = petInstance.stats.power},
        {name = "Health", icon = "❤️", value = petInstance.stats.health},
        {name = "Defense", icon = "🛡️", value = petInstance.stats.defense},
        {name = "Speed", icon = "💨", value = petInstance.stats.speed},
        {name = "Luck", icon = "🍀", value = petInstance.stats.luck},
        {name = "Coins", icon = "💰", value = petInstance.stats.coins},
        {name = "Gems", icon = "💎", value = petInstance.stats.gems}
    }
    
    for _, stat in ipairs(stats) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(1, 0, 0, 40)
        statFrame.Position = UDim2.new(0, 0, 0, yOffset)
        statFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
        statFrame.Parent = statsContainer
        
        Utilities:CreateCorner(statFrame, 8)
        Utilities:CreatePadding(statFrame, 10)
        
        local iconLabel = UIComponents:CreateLabel(statFrame, stat.icon, UDim2.new(0, 30, 1, 0), UDim2.new(0, 0, 0, 0), 20)
        
        local nameLabel = UIComponents:CreateLabel(statFrame, stat.name, UDim2.new(0.4, -40, 1, 0), UDim2.new(0, 40, 0, 0), 14)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        
        local valueLabel = UIComponents:CreateLabel(statFrame, Utilities:FormatNumber(stat.value), UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), 16)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Font = CLIENT_CONFIG.FONTS.Numbers
        
        yOffset = yOffset + 45
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function UIModules.InventoryUI:ShowPetAbilities(parent, petInstance, petData)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))
    
    local abilitiesContainer = Instance.new("Frame")
    abilitiesContainer.Size = UDim2.new(1, -10, 0, 500)
    abilitiesContainer.BackgroundTransparency = 1
    abilitiesContainer.Parent = scrollFrame
    
    local yOffset = 0
    
    for _, ability in ipairs(petData.abilities or {}) do
        local abilityFrame = Instance.new("Frame")
        abilityFrame.Size = UDim2.new(1, 0, 0, 100)
        abilityFrame.Position = UDim2.new(0, 0, 0, yOffset)
        abilityFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
        abilityFrame.Parent = abilitiesContainer
        
        Utilities:CreateCorner(abilityFrame, 12)
        Utilities:CreatePadding(abilityFrame, 15)
        
        -- Ability name
        local nameLabel = UIComponents:CreateLabel(abilityFrame, ability.name, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0), 18)
        nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Level requirement
        if ability.level > petInstance.level then
            nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            
            local lockLabel = UIComponents:CreateLabel(abilityFrame, "🔒 Unlocks at Lv." .. ability.level, UDim2.new(0, 150, 0, 20), UDim2.new(1, -150, 0, 5), 12)
            lockLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
            lockLabel.TextXAlignment = Enum.TextXAlignment.Right
        else
            local activeLabel = UIComponents:CreateLabel(abilityFrame, "✓ Active", UDim2.new(0, 100, 0, 20), UDim2.new(1, -100, 0, 5), 12)
            activeLabel.TextColor3 = CLIENT_CONFIG.COLORS.Success
            activeLabel.TextXAlignment = Enum.TextXAlignment.Right
        end
        
        -- Description
        local descLabel = UIComponents:CreateLabel(abilityFrame, ability.description, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 30), 14)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        descLabel.TextWrapped = true
        
        -- Cooldown
        if ability.cooldown then
            local cooldownLabel = UIComponents:CreateLabel(abilityFrame, "⏱️ " .. ability.cooldown .. "s cooldown", UDim2.new(0, 150, 0, 20), UDim2.new(0, 0, 1, -25), 12)
            cooldownLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
            cooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
        end
        
        -- Energy cost
        if ability.energyCost then
            local energyLabel = UIComponents:CreateLabel(abilityFrame, "⚡ " .. ability.energyCost .. " energy", UDim2.new(0, 150, 0, 20), UDim2.new(1, -150, 1, -25), 12)
            energyLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
            energyLabel.TextXAlignment = Enum.TextXAlignment.Right
        end
        
        yOffset = yOffset + 110
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function UIModules.InventoryUI:ShowPetInfo(parent, petInstance, petData)
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -10, 1, -10)
    infoFrame.Position = UDim2.new(0, 5, 0, 5)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = parent
    
    local infoList = {
        {label = "Pet ID", value = petInstance.id},
        {label = "Species", value = petData.displayName},
        {label = "Rarity", value = ({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "SECRET"})[petData.rarity]},
        {label = "Variant", value = petInstance.variant:gsub("_", " "):gsub("^%l", string.upper)},
        {label = "Obtained", value = os.date("%m/%d/%Y", petInstance.obtained)},
        {label = "Source", value = petInstance.source:gsub("_", " "):gsub("^%l", string.upper)},
        {label = "Value", value = Utilities:FormatNumber(petData.baseValue * (petData.variants[petInstance.variant].multiplier or 1))},
        {label = "Tradeable", value = petData.tradeable and "Yes" or "No"},
        {label = "Nickname", value = petInstance.nickname or "None"}
    }
    
    local yOffset = 0
    for _, info in ipairs(infoList) do
        local infoRow = Instance.new("Frame")
        infoRow.Size = UDim2.new(1, 0, 0, 30)
        infoRow.Position = UDim2.new(0, 0, 0, yOffset)
        infoRow.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
        infoRow.Parent = infoFrame
        
        Utilities:CreateCorner(infoRow, 6)
        Utilities:CreatePadding(infoRow, 10)
        
        local labelText = UIComponents:CreateLabel(infoRow, info.label .. ":", UDim2.new(0.4, 0, 1, 0), UDim2.new(0, 0, 0, 0), 14)
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.TextColor3 = Color3.fromRGB(100, 100, 100)
        
        local valueText = UIComponents:CreateLabel(infoRow, tostring(info.value), UDim2.new(0.6, 0, 1, 0), UDim2.new(0.4, 0, 0, 0), 14)
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.Font = CLIENT_CONFIG.FONTS.Secondary
        
        -- Special formatting
        if info.label == "Rarity" then
            valueText.TextColor3 = Utilities:GetRarityColor(petData.rarity)
        elseif info.label == "Tradeable" and info.value == "No" then
            valueText.TextColor3 = CLIENT_CONFIG.COLORS.Error
        elseif info.label == "Nickname" and info.value == "None" then
            -- Add rename button
            local renameButton = UIComponents:CreateButton(infoRow, "Rename", UDim2.new(0, 60, 0, 20), UDim2.new(1, -65, 0.5, -10), function()
                self:RenamePet(petInstance)
            end)
            renameButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
            valueText.Size = UDim2.new(0.6, -70, 1, 0)
        end
        
        yOffset = yOffset + 35
    end
end

function UIModules.InventoryUI:RenamePet(petInstance)
    -- Create rename dialog
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    dialog.ZIndex = 300
    dialog.Parent = MainUI.ScreenGui
    
    Utilities:CreateCorner(dialog, 12)
    Utilities:CreateShadow(dialog, 0.5)
    
    local title = UIComponents:CreateLabel(dialog, "Rename Pet", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 10), 20)
    title.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local input = UIComponents:CreateTextBox(dialog, "Enter new name...", UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 0, 60))
    
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -40, 0, 40)
    buttonContainer.Position = UDim2.new(0, 20, 1, -60)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = dialog
    
    local cancelButton = UIComponents:CreateButton(buttonContainer, "Cancel", UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), function()
        dialog:Destroy()
    end)
    cancelButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    
    local confirmButton = UIComponents:CreateButton(buttonContainer, "Confirm", UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), function()
        if input.Text ~= "" then
            petInstance.nickname = input.Text
            -- TODO: Send to server
            NotificationSystem:SendNotification("Success", "Pet renamed to " .. input.Text, "success")
            dialog:Destroy()
        end
    end)
    confirmButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
end

function UIModules.InventoryUI:RefreshInventory()
    if not LocalData.PlayerData then return end
    
    -- Clear existing
    if self.PetGrid then
        for _, child in ipairs(self.PetGrid:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
    -- Update stats
    local petCount = #LocalData.PlayerData.pets
    local equippedCount = 0
    for _, pet in ipairs(LocalData.PlayerData.pets) do
        if pet.equipped then
            equippedCount = equippedCount + 1
        end
    end
    
    if self.StatsLabels then
        self.StatsLabels.PetCount.Text = "Pets: " .. petCount .. "/" .. LocalData.PlayerData.maxPetStorage
        self.StatsLabels.Equipped.Text = "Equipped: " .. equippedCount .. "/6"
        self.StatsLabels.Storage.UpdateValue(petCount)
    end
    
    -- Add pet cards
    if self.PetGrid then
        for i, pet in ipairs(LocalData.PlayerData.pets) do
            local petData = LocalData.PetDatabase[pet.petId]
            if petData then
                local card = self:CreatePetCard(self.PetGrid, pet, petData)
                card.LayoutOrder = i
            end
        end
    end
end

-- Continue in Part 4...