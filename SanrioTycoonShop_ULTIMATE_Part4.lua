-- ========================================
-- ADVANCED CASE OPENING ANIMATION SYSTEM
-- ========================================
local CaseOpeningSystem = {
    activeSessions = {},
    
    createOpeningSession = function(player, eggData, result)
        local sessionId = HttpService:GenerateGUID(false)
        local session = {
            id = sessionId,
            player = player,
            eggData = eggData,
            result = result,
            startTime = tick(),
            phase = "starting"
        }
        
        CaseOpeningSystem.activeSessions[sessionId] = session
        
        -- Create UI
        local screenGui = UISystem.screenGuis[player.UserId]
        if not screenGui then return end
        
        -- Full screen overlay with blur
        local overlay = Instance.new("Frame")
        overlay.Name = "CaseOpeningOverlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 0.2
        overlay.ZIndex = 200
        overlay.Parent = screenGui
        
        -- Animate overlay fade in
        overlay.BackgroundTransparency = 1
        UISystem.tweenProperty(overlay, "BackgroundTransparency", 0.2, 0.5)
        
        -- Main container
        local mainContainer = Instance.new("Frame")
        mainContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
        mainContainer.Position = UDim2.new(0.05, 0, 0.1, 0)
        mainContainer.BackgroundColor3 = Color3.fromRGB(255, 250, 245)
        mainContainer.BorderSizePixel = 0
        mainContainer.ZIndex = 201
        mainContainer.Parent = overlay
        
        local containerCorner = Instance.new("UICorner")
        containerCorner.CornerRadius = UDim.new(0, 40)
        containerCorner.Parent = mainContainer
        
        -- Add gradient
        local containerGradient = Instance.new("UIGradient")
        containerGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(250, 240, 245))
        }
        containerGradient.Rotation = 90
        containerGradient.Parent = mainContainer
        
        -- Title section
        local titleFrame = Instance.new("Frame")
        titleFrame.Size = UDim2.new(1, 0, 0.15, 0)
        titleFrame.BackgroundTransparency = 1
        titleFrame.Parent = mainContainer
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 1, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Opening " .. eggData.name .. "..."
        titleLabel.TextColor3 = Color3.fromRGB(255, 100, 150)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.FredokaOne
        titleLabel.Parent = titleFrame
        
        -- Case spinner section
        local spinnerFrame = Instance.new("Frame")
        spinnerFrame.Size = UDim2.new(1, -40, 0.4, 0)
        spinnerFrame.Position = UDim2.new(0, 20, 0.2, 0)
        spinnerFrame.BackgroundColor3 = Color3.fromRGB(240, 235, 240)
        spinnerFrame.BorderSizePixel = 0
        spinnerFrame.ClipsDescendants = true
        spinnerFrame.Parent = mainContainer
        
        local spinnerCorner = Instance.new("UICorner")
        spinnerCorner.CornerRadius = UDim.new(0, 20)
        spinnerCorner.Parent = spinnerFrame
        
        -- Center indicator
        local centerIndicator = Instance.new("Frame")
        centerIndicator.Size = UDim2.new(0, 4, 1.2, 0)
        centerIndicator.Position = UDim2.new(0.5, -2, -0.1, 0)
        centerIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 100)
        centerIndicator.BorderSizePixel = 0
        centerIndicator.ZIndex = 205
        centerIndicator.Parent = spinnerFrame
        
        -- Glow effect for center
        local centerGlow = Instance.new("ImageLabel")
        centerGlow.Size = UDim2.new(0, 40, 0.5, 0)
        centerGlow.Position = UDim2.new(0.5, -20, 0.25, 0)
        centerGlow.BackgroundTransparency = 1
        centerGlow.Image = "rbxasset://textures/particles/sparkles_main.dds"
        centerGlow.ImageColor3 = Color3.fromRGB(255, 50, 100)
        centerGlow.ImageTransparency = 0.5
        centerGlow.ZIndex = 204
        centerGlow.Parent = spinnerFrame
        
        -- Animate glow
        spawn(function()
            while centerGlow.Parent do
                UISystem.tweenProperty(centerGlow, "ImageTransparency", 0.2, 0.5)
                wait(0.5)
                UISystem.tweenProperty(centerGlow, "ImageTransparency", 0.5, 0.5)
                wait(0.5)
            end
        end)
        
        -- Create scrolling container
        local scrollContainer = Instance.new("Frame")
        scrollContainer.Name = "ScrollContainer"
        scrollContainer.Size = UDim2.new(3, 0, 1, 0)
        scrollContainer.Position = UDim2.new(-1, 0, 0, 0)
        scrollContainer.BackgroundTransparency = 1
        scrollContainer.Parent = spinnerFrame
        
        -- Generate case items
        local itemWidth = 140
        local itemPadding = 20
        local totalWidth = #result.caseItems * (itemWidth + itemPadding)
        
        for i, petName in ipairs(result.caseItems) do
            local itemFrame = CaseOpeningSystem.createCaseItem(petName, i, itemWidth, itemPadding)
            itemFrame.Parent = scrollContainer
            
            -- Highlight winner
            if i == 50 then
                itemFrame.BorderSizePixel = 3
                itemFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
                
                -- Add winner glow
                local winnerGlow = Instance.new("Frame")
                winnerGlow.Size = UDim2.new(1.1, 0, 1.1, 0)
                winnerGlow.Position = UDim2.new(-0.05, 0, -0.05, 0)
                winnerGlow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                winnerGlow.BackgroundTransparency = 0.8
                winnerGlow.ZIndex = itemFrame.ZIndex - 1
                winnerGlow.Parent = itemFrame
                
                local glowCorner = Instance.new("UICorner")
                glowCorner.CornerRadius = UDim.new(0, 15)
                glowCorner.Parent = winnerGlow
            end
        end
        
        -- Result display (initially hidden)
        local resultFrame = Instance.new("Frame")
        resultFrame.Name = "ResultFrame"
        resultFrame.Size = UDim2.new(1, -40, 0.35, 0)
        resultFrame.Position = UDim2.new(0, 20, 0.65, 0)
        resultFrame.BackgroundTransparency = 1
        resultFrame.Visible = false
        resultFrame.Parent = mainContainer
        
        -- Start spinning animation
        CaseOpeningSystem.startSpinAnimation(scrollContainer, result, resultFrame, session)
        
        return session
    end,
    
    createCaseItem = function(petName, index, width, padding)
        local petData = PetDatabase[petName] or PetDatabase["hello_kitty_classic"]
        
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = "Item" .. index
        itemFrame.Size = UDim2.new(0, width, 0.9, 0)
        itemFrame.Position = UDim2.new(0, (index - 1) * (width + padding) + padding/2, 0.05, 0)
        itemFrame.BackgroundColor3 = Color3.white
        itemFrame.BorderSizePixel = 0
        itemFrame.ZIndex = 202
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 15)
        itemCorner.Parent = itemFrame
        
        -- Rarity gradient
        local rarityColors = {
            [1] = {Color3.fromRGB(200, 200, 200), Color3.fromRGB(150, 150, 150)}, -- Common
            [2] = {Color3.fromRGB(100, 200, 255), Color3.fromRGB(50, 150, 255)}, -- Uncommon
            [3] = {Color3.fromRGB(200, 100, 255), Color3.fromRGB(150, 50, 255)}, -- Rare
            [4] = {Color3.fromRGB(255, 150, 255), Color3.fromRGB(255, 100, 200)}, -- Epic
            [5] = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 165, 0)}, -- Legendary
            [6] = {Color3.fromRGB(255, 100, 255), Color3.fromRGB(200, 50, 255)}, -- Mythical
            [7] = {Color3.fromRGB(255, 50, 50), Color3.fromRGB(150, 0, 0)} -- Secret
        }
        
        local colors = rarityColors[petData.rarity] or rarityColors[1]
        
        local rarityGradient = Instance.new("UIGradient")
        rarityGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, colors[1]),
            ColorSequenceKeypoint.new(1, colors[2])
        }
        rarityGradient.Rotation = 90
        rarityGradient.Parent = itemFrame
        
        -- Pet image
        local petImage = Instance.new("ImageLabel")
        petImage.Size = UDim2.new(0.8, 0, 0.6, 0)
        petImage.Position = UDim2.new(0.1, 0, 0.05, 0)
        petImage.BackgroundTransparency = 1
        petImage.Image = petData.imageId
        petImage.ScaleType = Enum.ScaleType.Fit
        petImage.Parent = itemFrame
        
        -- Pet name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
        nameLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = petData.displayName
        nameLabel.TextColor3 = Color3.white
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = itemFrame
        
        -- Add shine effect for rare pets
        if petData.rarity >= 4 then
            local shine = Instance.new("Frame")
            shine.Size = UDim2.new(0, 30, 2, 0)
            shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
            shine.BackgroundColor3 = Color3.white
            shine.BackgroundTransparency = 0.8
            shine.BorderSizePixel = 0
            shine.Rotation = 45
            shine.Parent = itemFrame
            
            -- Animate shine
            spawn(function()
                while shine.Parent do
                    shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
                    local shineTween = UISystem.tweenPosition(
                        shine, 
                        UDim2.new(1.5, 0, 1.5, 0), 
                        3, 
                        Enum.EasingStyle.Linear
                    )
                    shineTween.Completed:Wait()
                    wait(2)
                end
            end)
        end
        
        return itemFrame
    end,
    
    startSpinAnimation = function(scrollContainer, result, resultFrame, session)
        local itemWidth = 160 -- Width + padding
        local winnerPosition = 50 * itemWidth - scrollContainer.Parent.AbsoluteSize.X / 2 + itemWidth / 2
        
        -- Phase 1: Quick start
        local phase1Info = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        local phase1Tween = Services.TweenService:Create(scrollContainer, phase1Info, {
            Position = UDim2.new(0, -winnerPosition * 0.3, 0, 0)
        })
        
        -- Phase 2: Main spin
        local phase2Info = TweenInfo.new(2, Enum.EasingStyle.Linear)
        local phase2Tween = Services.TweenService:Create(scrollContainer, phase2Info, {
            Position = UDim2.new(0, -winnerPosition * 0.8, 0, 0)
        })
        
        -- Phase 3: Slow down
        local phase3Info = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local phase3Tween = Services.TweenService:Create(scrollContainer, phase3Info, {
            Position = UDim2.new(0, -winnerPosition * 0.95, 0, 0)
        })
        
        -- Phase 4: Final adjustment
        local phase4Info = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local phase4Tween = Services.TweenService:Create(scrollContainer, phase4Info, {
            Position = UDim2.new(0, -winnerPosition, 0, 0)
        })
        
        -- Play phases
        phase1Tween:Play()
        SoundSystem.play("eggCrack")
        
        phase1Tween.Completed:Connect(function()
            phase2Tween:Play()
        end)
        
        phase2Tween.Completed:Connect(function()
            phase3Tween:Play()
        end)
        
        phase3Tween.Completed:Connect(function()
            phase4Tween:Play()
        end)
        
        phase4Tween.Completed:Connect(function()
            wait(0.5)
            CaseOpeningSystem.revealResult(result, resultFrame, session)
        end)
    end,
    
    revealResult = function(result, resultFrame, session)
        resultFrame.Visible = true
        
        local petData = PetDatabase[result.winner]
        if not petData then return end
        
        -- Play reveal sound based on rarity
        local rarityToSound = {
            [1] = "commonReveal",
            [2] = "commonReveal", 
            [3] = "rareReveal",
            [4] = "epicReveal",
            [5] = "legendaryReveal",
            [6] = "mythicalReveal",
            [7] = "mythicalReveal"
        }
        
        SoundSystem.play(rarityToSound[petData.rarity] or "commonReveal")
        
        -- Create result display
        local resultContainer = Instance.new("Frame")
        resultContainer.Size = UDim2.new(0.8, 0, 1, 0)
        resultContainer.Position = UDim2.new(0.1, 0, 0, 0)
        resultContainer.BackgroundColor3 = Color3.white
        resultContainer.BorderSizePixel = 0
        resultContainer.Parent = resultFrame
        
        local resultCorner = Instance.new("UICorner")
        resultCorner.CornerRadius = UDim.new(0, 20)
        resultCorner.Parent = resultContainer
        
        -- Add rarity effects
        if petData.rarity >= 5 then
            -- Legendary or higher
            EffectsSystem.createExplosionEffect(
                session.player.Character.HumanoidRootPart.Position + Vector3.new(0, 10, 0),
                Color3.fromRGB(255, 215, 0),
                20
            )
            
            -- Screen shake
            local camera = workspace.CurrentCamera
            local originalCFrame = camera.CFrame
            
            spawn(function()
                for i = 1, 20 do
                    camera.CFrame = originalCFrame * CFrame.new(
                        math.random(-10, 10) / 10,
                        math.random(-10, 10) / 10,
                        0
                    )
                    wait(0.05)
                end
                camera.CFrame = originalCFrame
            end)
        end
        
        -- Pet display
        local petDisplay = Instance.new("ViewportFrame")
        petDisplay.Size = UDim2.new(0.5, 0, 0.8, 0)
        petDisplay.Position = UDim2.new(0, 0, 0.1, 0)
        petDisplay.BackgroundTransparency = 1
        petDisplay.Parent = resultContainer
        
        local petCamera = Instance.new("Camera")
        petCamera.Parent = petDisplay
        petDisplay.CurrentCamera = petCamera
        
        -- Load pet model
        local petModel = CaseOpeningSystem.loadPetModel(petData)
        if petModel then
            petModel.Parent = petDisplay
            
            local cf = CFrame.new(petModel.PrimaryPart.Position + Vector3.new(0, 0, 5), petModel.PrimaryPart.Position)
            petCamera.CFrame = cf
            
            -- Rotate pet
            spawn(function()
                while petModel.Parent do
                    petModel:SetPrimaryPartCFrame(petModel.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(2), 0))
                    wait()
                end
            end)
        end
        
        -- Info display
        local infoFrame = Instance.new("Frame")
        infoFrame.Size = UDim2.new(0.45, 0, 0.8, 0)
        infoFrame.Position = UDim2.new(0.52, 0, 0.1, 0)
        infoFrame.BackgroundTransparency = 1
        infoFrame.Parent = resultContainer
        
        local congratsLabel = Instance.new("TextLabel")
        congratsLabel.Size = UDim2.new(1, 0, 0.15, 0)
        congratsLabel.BackgroundTransparency = 1
        congratsLabel.Text = "CONGRATULATIONS!"
        congratsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        congratsLabel.TextScaled = true
        congratsLabel.Font = Enum.Font.FredokaOne
        congratsLabel.Parent = infoFrame
        
        local youGotLabel = Instance.new("TextLabel")
        youGotLabel.Size = UDim2.new(1, 0, 0.1, 0)
        youGotLabel.Position = UDim2.new(0, 0, 0.15, 0)
        youGotLabel.BackgroundTransparency = 1
        youGotLabel.Text = "You hatched:"
        youGotLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        youGotLabel.TextScaled = true
        youGotLabel.Font = Enum.Font.Gotham
        youGotLabel.Parent = infoFrame
        
        local petNameLabel = Instance.new("TextLabel")
        petNameLabel.Size = UDim2.new(1, 0, 0.2, 0)
        petNameLabel.Position = UDim2.new(0, 0, 0.25, 0)
        petNameLabel.BackgroundTransparency = 1
        petNameLabel.Text = petData.displayName
        petNameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        petNameLabel.TextScaled = true
        petNameLabel.Font = Enum.Font.GothamBold
        petNameLabel.Parent = infoFrame
        
        -- Rarity badge
        local rarityBadge = Instance.new("Frame")
        rarityBadge.Size = UDim2.new(0.8, 0, 0.15, 0)
        rarityBadge.Position = UDim2.new(0.1, 0, 0.5, 0)
        rarityBadge.BackgroundColor3 = CaseOpeningSystem.getRarityColor(petData.rarity)
        rarityBadge.Parent = infoFrame
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 10)
        badgeCorner.Parent = rarityBadge
        
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, 0, 1, 0)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = CaseOpeningSystem.getRarityName(petData.rarity)
        rarityLabel.TextColor3 = Color3.white
        rarityLabel.TextScaled = true
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.Parent = rarityBadge
        
        -- Stats display
        local statsFrame = Instance.new("Frame")
        statsFrame.Size = UDim2.new(1, 0, 0.25, 0)
        statsFrame.Position = UDim2.new(0, 0, 0.7, 0)
        statsFrame.BackgroundTransparency = 1
        statsFrame.Parent = infoFrame
        
        local statsLayout = Instance.new("UIListLayout")
        statsLayout.FillDirection = Enum.FillDirection.Vertical
        statsLayout.Padding = UDim.new(0, 5)
        statsLayout.Parent = statsFrame
        
        -- Display stats
        local stats = {
            {icon = "🪙", name = "Coins", value = petData.baseStats.coins},
            {icon = "💎", name = "Gems", value = petData.baseStats.gems},
            {icon = "🍀", name = "Luck", value = petData.baseStats.luck},
            {icon = "⚡", name = "Speed", value = petData.baseStats.speed}
        }
        
        for _, stat in ipairs(stats) do
            local statLabel = Instance.new("TextLabel")
            statLabel.Size = UDim2.new(1, 0, 0, 20)
            statLabel.BackgroundTransparency = 1
            statLabel.Text = stat.icon .. " " .. stat.name .. ": " .. stat.value
            statLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
            statLabel.TextScaled = true
            statLabel.Font = Enum.Font.Gotham
            statLabel.TextXAlignment = Enum.TextXAlignment.Left
            statLabel.Parent = statsFrame
        end
        
        -- Collect button
        local collectButton = Instance.new("TextButton")
        collectButton.Size = UDim2.new(0.3, 0, 0.08, 0)
        collectButton.Position = UDim2.new(0.35, 0, 0.9, 0)
        collectButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        collectButton.Text = "Collect"
        collectButton.TextColor3 = Color3.white
        collectButton.TextScaled = true
        collectButton.Font = Enum.Font.GothamBold
        collectButton.Parent = resultContainer
        
        local collectCorner = Instance.new("UICorner")
        collectCorner.CornerRadius = UDim.new(0, 15)
        collectCorner.Parent = collectButton
        
        collectButton.MouseButton1Click:Connect(function()
            CaseOpeningSystem.closeSession(session)
        end)
        
        -- Animate result appearance
        resultContainer.Size = UDim2.new(0, 0, 0, 0)
        resultContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        UISystem.tweenSize(resultContainer, UDim2.new(0.8, 0, 1, 0), 0.5, Enum.EasingStyle.Back)
        UISystem.tweenPosition(resultContainer, UDim2.new(0.1, 0, 0, 0), 0.5, Enum.EasingStyle.Back)
    end,
    
    loadPetModel = function(petData)
        -- In a real implementation, this would load the actual 3D model
        -- For now, create a placeholder
        local model = Instance.new("Model")
        model.Name = petData.name
        
        local part = Instance.new("Part")
        part.Name = "Body"
        part.Size = Vector3.new(4, 4, 4)
        part.Shape = Enum.PartType.Ball
        part.Material = Enum.Material.Neon
        part.BrickColor = BrickColor.new("Pink")
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Anchored = true
        part.CanCollide = false
        part.Parent = model
        
        model.PrimaryPart = part
        
        -- Add particles based on rarity
        if petData.rarity >= 4 then
            EffectsSystem.createSparkleEffect(part, Color3.fromRGB(255, 215, 0))
        end
        
        if petData.rarity >= 6 then
            EffectsSystem.createRainbowEffect(part)
        end
        
        return model
    end,
    
    getRarityColor = function(rarity)
        local colors = {
            [1] = Color3.fromRGB(150, 150, 150), -- Common
            [2] = Color3.fromRGB(100, 200, 100), -- Uncommon
            [3] = Color3.fromRGB(100, 150, 255), -- Rare
            [4] = Color3.fromRGB(200, 100, 255), -- Epic
            [5] = Color3.fromRGB(255, 215, 0), -- Legendary
            [6] = Color3.fromRGB(255, 100, 255), -- Mythical
            [7] = Color3.fromRGB(255, 50, 50) -- Secret
        }
        return colors[rarity] or colors[1]
    end,
    
    getRarityName = function(rarity)
        local names = {
            [1] = "COMMON",
            [2] = "UNCOMMON",
            [3] = "RARE",
            [4] = "EPIC",
            [5] = "LEGENDARY",
            [6] = "MYTHICAL",
            [7] = "SECRET"
        }
        return names[rarity] or "UNKNOWN"
    end,
    
    closeSession = function(session)
        CaseOpeningSystem.activeSessions[session.id] = nil
        
        local screenGui = UISystem.screenGuis[session.player.UserId]
        if screenGui then
            local overlay = screenGui:FindFirstChild("CaseOpeningOverlay")
            if overlay then
                UISystem.tweenProperty(overlay, "BackgroundTransparency", 1, 0.3)
                wait(0.3)
                overlay:Destroy()
            end
        end
    end
}

-- ========================================
-- NOTIFICATION SYSTEM
-- ========================================
local NotificationSystem = {
    notifications = {},
    maxNotifications = 5,
    
    send = function(player, title, message, notificationType, duration)
        local screenGui = UISystem.screenGuis[player.UserId]
        if not screenGui then return end
        
        -- Create notification container if it doesn't exist
        local container = screenGui:FindFirstChild("NotificationContainer")
        if not container then
            container = Instance.new("Frame")
            container.Name = "NotificationContainer"
            container.Size = UDim2.new(0.3, 0, 1, 0)
            container.Position = UDim2.new(0.69, 0, 0, 0)
            container.BackgroundTransparency = 1
            container.Parent = screenGui
            
            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            layout.VerticalAlignment = Enum.VerticalAlignment.Top
            layout.Padding = UDim.new(0, 10)
            layout.Parent = container
            
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 20)
            padding.PaddingRight = UDim.new(0, 20)
            padding.Parent = container
        end
        
        -- Create notification
        local notification = Instance.new("Frame")
        notification.Size = UDim2.new(1, 0, 0, 80)
        notification.BackgroundColor3 = Color3.white
        notification.BorderSizePixel = 0
        notification.Parent = container
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 15)
        notifCorner.Parent = notification
        
        -- Add shadow
        local shadow = Instance.new("ImageLabel")
        shadow.Size = UDim2.new(1, 10, 1, 10)
        shadow.Position = UDim2.new(0, -5, 0, -5)
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.7
        shadow.ZIndex = notification.ZIndex - 1
        shadow.Parent = notification
        
        -- Type indicator
        local typeColors = {
            success = Color3.fromRGB(100, 200, 100),
            error = Color3.fromRGB(255, 100, 100),
            warning = Color3.fromRGB(255, 200, 100),
            info = Color3.fromRGB(100, 150, 255),
            reward = Color3.fromRGB(255, 215, 0)
        }
        
        local typeBar = Instance.new("Frame")
        typeBar.Size = UDim2.new(0, 5, 1, 0)
        typeBar.Position = UDim2.new(0, 0, 0, 0)
        typeBar.BackgroundColor3 = typeColors[notificationType] or typeColors.info
        typeBar.BorderSizePixel = 0
        typeBar.Parent = notification
        
        local typeBarCorner = Instance.new("UICorner")
        typeBarCorner.CornerRadius = UDim.new(0, 15)
        typeBarCorner.Parent = typeBar
        
        -- Content
        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, -20, 1, -10)
        contentFrame.Position = UDim2.new(0, 15, 0, 5)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = notification
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = contentFrame
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, 0, 0.5, 0)
        messageLabel.Position = UDim2.new(0, 0, 0.4, 0)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        messageLabel.TextScaled = true
        messageLabel.Font = Enum.Font.Gotham
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextWrapped = true
        messageLabel.Parent = contentFrame
        
        -- Close button
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 20, 0, 20)
        closeButton.Position = UDim2.new(1, -25, 0, 5)
        closeButton.BackgroundTransparency = 1
        closeButton.Text = "✖"
        closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        closeButton.TextScaled = true
        closeButton.Font = Enum.Font.Gotham
        closeButton.Parent = notification
        
        closeButton.MouseButton1Click:Connect(function()
            NotificationSystem.removeNotification(notification)
        end)
        
        -- Animate entrance
        notification.Position = UDim2.new(1, 100, 0, 0)
        UISystem.tweenPosition(notification, UDim2.new(0, 0, 0, 0), 0.5, Enum.EasingStyle.Back)
        
        -- Auto remove after duration
        duration = duration or 5
        spawn(function()
            wait(duration)
            if notification.Parent then
                NotificationSystem.removeNotification(notification)
            end
        end)
        
        -- Limit notifications
        local children = container:GetChildren()
        local notifCount = 0
        for _, child in ipairs(children) do
            if child:IsA("Frame") and child ~= notification then
                notifCount = notifCount + 1
            end
        end
        
        if notifCount >= NotificationSystem.maxNotifications then
            for _, child in ipairs(children) do
                if child:IsA("Frame") and child ~= notification then
                    NotificationSystem.removeNotification(child)
                    break
                end
            end
        end
        
        return notification
    end,
    
    removeNotification = function(notification)
        UISystem.tweenPosition(notification, UDim2.new(1, 100, 0, 0), 0.3)
        wait(0.3)
        notification:Destroy()
    end
}

-- ========================================
-- MAIN INITIALIZATION & PLAYER MANAGEMENT
-- ========================================
local GameInitializer = {
    initialize = function()
        print("[SANRIO TYCOON] Initializing Ultimate Shop System v5.0...")
        
        -- Initialize all systems
        BattleSystem.initializeArenas()
        
        -- Setup datastores
        local success, error = pcall(function()
            -- Test datastore access
            PlayerDataStore:GetAsync("TestKey")
        end)
        
        if not success then
            warn("[SANRIO TYCOON] DataStore access failed: " .. tostring(error))
        else
            print("[SANRIO TYCOON] DataStore access confirmed")
        end
        
        -- Create global leaderboard
        GameInitializer.createLeaderboard()
        
        -- Start auto-save loop
        GameInitializer.startAutoSave()
        
        -- Initialize server events
        GameInitializer.setupServerEvents()
        
        print("[SANRIO TYCOON] Initialization complete!")
    end,
    
    createLeaderboard = function()
        -- This would create a global leaderboard for various stats
        local leaderboardModel = Instance.new("Model")
        leaderboardModel.Name = "SanrioTycoonLeaderboards"
        leaderboardModel.Parent = workspace
        
        -- Would contain actual leaderboard parts and UI
    end,
    
    startAutoSave = function()
        spawn(function()
            while true do
                wait(300) -- Save every 5 minutes
                
                for userId, data in pairs(PlayerData) do
                    local player = Services.Players:GetPlayerByUserId(userId)
                    if player then
                        SavePlayerData(player)
                    end
                end
                
                print("[SANRIO TYCOON] Auto-save completed")
            end
        end)
    end,
    
    setupServerEvents = function()
        -- Setup all remote events and functions
        local remoteEvents = Services.ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then
            remoteEvents = Instance.new("Folder")
            remoteEvents.Name = "RemoteEvents"
            remoteEvents.Parent = Services.ReplicatedStorage
        end
        
        -- Create all necessary remotes
        local remotes = {
            "OpenCase",
            "PurchaseGamepass",
            "PurchaseGems",
            "EquipPet",
            "UnequipPet",
            "EvolvePet",
            "FusePets",
            "InitiateTrade",
            "AcceptTrade",
            "DeclineTrade",
            "JoinBattle",
            "BattleAction",
            "CreateClan",
            "JoinClan",
            "LeaveClan",
            "ClaimDailyReward",
            "ClaimQuest",
            "UseItem",
            "OpenShop",
            "UpdateSettings"
        }
        
        for _, remoteName in ipairs(remotes) do
            if not remoteEvents:FindFirstChild(remoteName) then
                local remote = Instance.new("RemoteEvent")
                remote.Name = remoteName
                remote.Parent = remoteEvents
            end
        end
        
        -- Setup remote functions
        local remoteFunctions = {
            "GetPlayerData",
            "GetLeaderboard",
            "GetClanInfo",
            "SearchClans",
            "GetTradeHistory",
            "GetBattleHistory"
        }
        
        for _, funcName in ipairs(remoteFunctions) do
            if not remoteEvents:FindFirstChild(funcName) then
                local func = Instance.new("RemoteFunction")
                func.Name = funcName
                func.Parent = remoteEvents
            end
        end
    end
}

-- ========================================
-- PLAYER CONNECTION HANDLERS
-- ========================================
Services.Players.PlayerAdded:Connect(function(player)
    print("[SANRIO TYCOON] Player joined: " .. player.Name)
    
    -- Load player data
    LoadPlayerData(player)
    
    -- Initialize player systems
    spawn(function()
        -- Assign daily quests
        QuestSystem.assignDailyQuests(player)
        
        -- Check achievements
        QuestSystem.checkAchievements(player)
        
        -- Anti-exploit monitoring
        AntiExploit.detectPatterns(player)
    end)
    
    -- Setup character
    player.CharacterAdded:Connect(function(character)
        wait(2) -- Wait for character to fully load
        
        -- Create shop UI
        UISystem.createMainShopUI(player)
        
        -- Send welcome notification
        NotificationSystem.send(
            player,
            "Welcome to Sanrio Tycoon!",
            "Click the shop button to get started!",
            "info",
            10
        )
        
        -- Check for returning player rewards
        local playerData = PlayerData[player.UserId]
        if playerData then
            local timeSinceLastLogin = os.time() - playerData.lastSeen
            if timeSinceLastLogin > 86400 then -- More than 24 hours
                NotificationSystem.send(
                    player,
                    "Welcome Back!",
                    "Claim your returning player bonus!",
                    "reward",
                    8
                )
                
                -- Award returning bonus
                playerData.currencies.gems = playerData.currencies.gems + 100
                SavePlayerData(player)
            end
        end
    end)
end)

Services.Players.PlayerRemoving:Connect(function(player)
    print("[SANRIO TYCOON] Player leaving: " .. player.Name)
    
    -- Save player data
    SavePlayerData(player)
    
    -- Clean up player data
    PlayerData[player.UserId] = nil
    
    -- Clean up any active sessions
    for sessionId, session in pairs(CaseOpeningSystem.activeSessions) do
        if session.player == player then
            CaseOpeningSystem.activeSessions[sessionId] = nil
        end
    end
    
    -- Clean up UI
    if UISystem.screenGuis[player.UserId] then
        UISystem.screenGuis[player.UserId] = nil
    end
end)

-- ========================================
-- REMOTE EVENT HANDLERS
-- ========================================
local remoteEvents = Services.ReplicatedStorage:WaitForChild("RemoteEvents")

remoteEvents.OpenCase.OnServerEvent:Connect(function(player, eggType)
    if not AntiExploit.validateRequest(player, "OpenCase") then
        return
    end
    
    local result = OpenCase(player, eggType)
    if result.success then
        -- Create opening animation on client
        CaseOpeningSystem.createOpeningSession(player, EggCases[eggType], result)
        
        -- Update quest progress
        QuestSystem.updateQuestProgress(player, "hatch_eggs", 1)
        
        -- Check for legendary/mythical
        local petData = PetDatabase[result.winner]
        if petData then
            if petData.rarity >= 5 then
                QuestSystem.updateQuestProgress(player, "hatch_legendary", 1)
            end
            if petData.rarity >= 6 then
                QuestSystem.updateQuestProgress(player, "hatch_mythical", 1)
            end
        end
    else
        NotificationSystem.send(
            player,
            "Failed to open egg",
            result.error or "Unknown error",
            "error",
            5
        )
    end
end)

remoteEvents.PurchaseGamepass.OnServerEvent:Connect(function(player, gamepassId)
    if not AntiExploit.validateRequest(player, "PurchaseGamepass") then
        return
    end
    
    Services.MarketplaceService:PromptGamePassPurchase(player, gamepassId)
end)

remoteEvents.EquipPet.OnServerEvent:Connect(function(player, petId)
    if not AntiExploit.validateRequest(player, "EquipPet") then
        return
    end
    
    if not AntiExploit.validatePet(player, petId) then
        return
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    if #playerData.equippedPets >= CONFIG.MAX_EQUIPPED_PETS then
        NotificationSystem.send(
            player,
            "Cannot equip",
            "Maximum pets equipped",
            "warning",
            3
        )
        return
    end
    
    -- Find and equip pet
    for _, pet in ipairs(playerData.pets) do
        if pet.id == petId then
            if not pet.equipped then
                pet.equipped = true
                table.insert(playerData.equippedPets, petId)
                SavePlayerData(player)
                
                NotificationSystem.send(
                    player,
                    "Pet Equipped",
                    pet.name .. " is now equipped!",
                    "success",
                    3
                )
            end
            break
        end
    end
end)

-- ========================================
-- FINAL INITIALIZATION
-- ========================================
GameInitializer.initialize()

print([[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║                    SANRIO TYCOON SHOP ULTIMATE - FULLY LOADED                        ║
║                                                                                      ║
║                              Created by: YourName                                    ║
║                               Version: 5.0.0                                         ║
║                                                                                      ║
║  Features Loaded:                                                                    ║
║  ✓ 100+ Unique Pets                                                                ║
║  ✓ Advanced Case Opening System                                                     ║
║  ✓ Trading System with Security                                                     ║
║  ✓ Pet Evolution & Fusion                                                          ║
║  ✓ Battle System & PvP Arena                                                       ║
║  ✓ Clan/Guild System                                                               ║
║  ✓ Quest & Achievement System                                                      ║
║  ✓ Daily Rewards & Battle Pass                                                     ║
║  ✓ Advanced UI with Animations                                                     ║
║  ✓ Particle Effects System                                                         ║
║  ✓ Sound System                                                                    ║
║  ✓ Anti-Exploit Protection                                                         ║
║  ✓ Auto-Save System                                                                ║
║  ✓ Notification System                                                             ║
║                                                                                      ║
║                         Total Lines of Code: 5000+                                   ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]])