--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                         EPIC PET DETAILS UI - COMPLETE REVAMP                        ║
    ║                    Shows all the insane details from PetDatabase                     ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Janitor = require(game.ReplicatedStorage.Modules.Shared.Janitor)
local PetDatabase = require(game.ReplicatedStorage.Modules.Shared.PetDatabase)

local PetDetailsUI = {}
PetDetailsUI.__index = PetDetailsUI

-- ========================================
-- CONSTANTS
-- ========================================

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

local TAB_CONFIGS = {
    {
        name = "Overview",
        icon = "📊",
        color = RARITY_COLORS[4]
    },
    {
        name = "Abilities",
        icon = "⚡",
        color = RARITY_COLORS[5]
    },
    {
        name = "Evolution",
        icon = "✨",
        color = RARITY_COLORS[6]
    },
    {
        name = "Synergies",
        icon = "🤝",
        color = RARITY_COLORS[7]
    },
    {
        name = "Collection",
        icon = "📚",
        color = RARITY_COLORS[8]
    }
}

-- ========================================
-- INITIALIZATION
-- ========================================

function PetDetailsUI.new(dependencies)
    local self = setmetatable({}, PetDetailsUI)
    
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
    self._overlay = nil
    self._detailsFrame = nil
    self._currentPetInstance = nil
    self._currentPetData = nil
    self._tabFrames = {}
    self._activeTab = "Overview"
    self._modelViewport = nil
    
    -- State
    self._isOpen = false
    self._isAnimating = false
    
    -- Setup listeners
    self:SetupEventListeners()
    
    return self
end

function PetDetailsUI:SetupEventListeners()
    self._janitor:Add(self._eventBus:On("ShowPetDetails", function(data)
        if data.petInstance and data.petData then
            self:Open(data.petInstance, data.petData)
        end
    end))
    
    self._janitor:Add(self._eventBus:On("HidePetDetails", function()
        self:Close()
    end))
end

-- ========================================
-- OPENING/CLOSING
-- ========================================

function PetDetailsUI:Open(petInstance, petData)
    if self._isOpen or self._isAnimating then return end
    
    self._isAnimating = true
    self._currentPetInstance = petInstance
    self._currentPetData = petData
    
    -- Create UI
    self:CreateUI()
    
    -- Epic opening animation
    self._overlay.BackgroundTransparency = 1
    self._detailsFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
    
    self._utilities.Tween(self._overlay, {
        BackgroundTransparency = 0.3
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
    
    self._utilities.Tween(self._detailsFrame, {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    -- Play epic sound based on rarity
    if petData.rarity >= 6 then
        self._soundSystem:PlayUISound("EpicReveal")
    else
        self._soundSystem:PlayUISound("Open")
    end
    
    task.wait(0.5)
    self._isAnimating = false
    self._isOpen = true
end

function PetDetailsUI:Close()
    if not self._isOpen or self._isAnimating then return end
    
    self._isAnimating = true
    
    self._utilities.Tween(self._overlay, {
        BackgroundTransparency = 1
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
    
    self._utilities.Tween(self._detailsFrame, {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
    
    self._soundSystem:PlayUISound("Close")
    
    task.wait(0.3)
    
    if self._overlay then
        self._overlay:Destroy()
        self._overlay = nil
    end
    
    self._isAnimating = false
    self._isOpen = false
end

-- ========================================
-- UI CREATION
-- ========================================

function PetDetailsUI:CreateUI()
    -- Dark overlay
    self._overlay = Instance.new("Frame")
    self._overlay.Size = UDim2.new(1, 0, 1, 0)
    self._overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    self._overlay.BackgroundTransparency = 0.3
    self._overlay.ZIndex = 100
    self._overlay.Parent = game.Players.LocalPlayer.PlayerGui.MainUI
    
    -- Click to close
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(1, 0, 1, 0)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = ""
    closeButton.ZIndex = 101
    closeButton.Parent = self._overlay
    
    closeButton.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Main frame with epic styling
    self._detailsFrame = Instance.new("Frame")
    self._detailsFrame.Size = UDim2.new(0.8, 0, 0.85, 0)
    self._detailsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    self._detailsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    self._detailsFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    self._detailsFrame.ZIndex = 200
    self._detailsFrame.Parent = self._overlay
    
    self._utilities.CreateCorner(self._detailsFrame, 20)
    
    -- Rarity gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.98, 0.98, 0.98)),
        ColorSequenceKeypoint.new(1, RARITY_COLORS[self._currentPetData.rarity] or RARITY_COLORS[1])
    })
    gradient.Rotation = 90
    gradient.Parent = self._detailsFrame
    
    -- Add special effects for high rarity
    if self._currentPetData.rarity >= 6 then
        self:AddRarityEffects()
    end
    
    -- Create sections
    self:CreateHeader()
    self:CreateLeftPanel()
    self:CreateRightPanel()
    self:CreateActionBar()
end

function PetDetailsUI:CreateHeader()
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = RARITY_COLORS[self._currentPetData.rarity] or RARITY_COLORS[1]
    header.ZIndex = 201
    header.Parent = self._detailsFrame
    
    self._utilities.CreateCorner(header, 20)
    
    -- Rarity badge
    local rarityBadge = Instance.new("Frame")
    rarityBadge.Size = UDim2.new(0, 150, 0, 40)
    rarityBadge.Position = UDim2.new(0, 20, 0.5, -20)
    rarityBadge.BackgroundColor3 = Color3.new(1, 1, 1)
    rarityBadge.ZIndex = 202
    rarityBadge.Parent = header
    
    self._utilities.CreateCorner(rarityBadge, 20)
    
    local rarityText = Instance.new("TextLabel")
    rarityText.Size = UDim2.new(1, 0, 1, 0)
    rarityText.BackgroundTransparency = 1
    rarityText.Font = Enum.Font.GothamBlack
    rarityText.Text = PetDatabase.RARITY_DATA[self._currentPetData.rarity].name:upper()
    rarityText.TextColor3 = RARITY_COLORS[self._currentPetData.rarity]
    rarityText.TextScaled = true
    rarityText.ZIndex = 203
    rarityText.Parent = rarityBadge
    
    -- Pet name with epic styling
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Position = UDim2.new(0.25, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.Text = self._currentPetInstance.nickname or self._currentPetData.displayName
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.ZIndex = 203
    nameLabel.Parent = header
    
    -- Add stroke for readability
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = nameLabel
    
    -- Variant indicator
    if self._currentPetInstance.variant and self._currentPetInstance.variant ~= "NORMAL" then
        local variantBadge = Instance.new("Frame")
        variantBadge.Size = UDim2.new(0, 120, 0, 30)
        variantBadge.Position = UDim2.new(1, -140, 0.5, -15)
        variantBadge.BackgroundColor3 = PetDatabase.VARIANTS[self._currentPetInstance.variant].color or Color3.new(1, 1, 1)
        variantBadge.ZIndex = 202
        variantBadge.Parent = header
        
        self._utilities.CreateCorner(variantBadge, 15)
        
        local variantText = Instance.new("TextLabel")
        variantText.Size = UDim2.new(1, 0, 1, 0)
        variantText.BackgroundTransparency = 1
        variantText.Font = Enum.Font.GothamBold
        variantText.Text = self._currentPetInstance.variant
        variantText.TextColor3 = Color3.new(1, 1, 1)
        variantText.TextScaled = true
        variantText.ZIndex = 203
        variantText.Parent = variantBadge
        
        -- Variant effects
        self:AddVariantEffects(variantBadge)
    end
end

function PetDetailsUI:CreateLeftPanel()
    local leftPanel = Instance.new("Frame")
    leftPanel.Size = UDim2.new(0.4, -10, 1, -180)
    leftPanel.Position = UDim2.new(0, 10, 0, 90)
    leftPanel.BackgroundColor3 = Color3.new(1, 1, 1)
    leftPanel.ZIndex = 201
    leftPanel.Parent = self._detailsFrame
    
    self._utilities.CreateCorner(leftPanel, 16)
    
    -- 3D Model viewport
    self:Create3DViewport(leftPanel)
    
    -- Stats display
    self:CreateStatsDisplay(leftPanel)
end

function PetDetailsUI:Create3DViewport(parent)
    local viewportFrame = Instance.new("ViewportFrame")
    viewportFrame.Size = UDim2.new(1, -20, 0.5, -10)
    viewportFrame.Position = UDim2.new(0, 10, 0, 10)
    viewportFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    viewportFrame.BorderSizePixel = 0
    viewportFrame.ZIndex = 202
    viewportFrame.Parent = parent
    
    self._utilities.CreateCorner(viewportFrame, 12)
    
    -- Camera
    local camera = Instance.new("Camera")
    camera.CFrame = CFrame.new(0, 2, 5) * CFrame.Angles(-0.2, 0, 0)
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera
    
    -- Load pet model
    if self._currentPetData.model then
        -- This would load the actual 3D model
        -- For now, we'll create a placeholder
        local model = Instance.new("Part")
        model.Size = Vector3.new(2, 2, 2)
        model.Color = RARITY_COLORS[self._currentPetData.rarity] or Color3.new(1, 1, 1)
        model.Material = Enum.Material.Neon
        model.Parent = viewportFrame
        
        -- Rotation animation
        task.spawn(function()
            while model.Parent do
                model.CFrame = model.CFrame * CFrame.Angles(0, 0.02, 0)
                task.wait()
            end
        end)
    end
    
    self._modelViewport = viewportFrame
end

function PetDetailsUI:CreateStatsDisplay(parent)
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -20, 0.45, -10)
    statsFrame.Position = UDim2.new(0, 10, 0.55, 0)
    statsFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    statsFrame.ZIndex = 202
    statsFrame.Parent = parent
    
    self._utilities.CreateCorner(statsFrame, 12)
    
    local stats = {
        {icon = "❤️", name = "Health", value = self._currentPetData.baseStats.health, color = Color3.fromRGB(255, 100, 100)},
        {icon = "⚔️", name = "Attack", value = self._currentPetData.baseStats.attack, color = Color3.fromRGB(255, 150, 50)},
        {icon = "🛡️", name = "Defense", value = self._currentPetData.baseStats.defense, color = Color3.fromRGB(100, 150, 255)},
        {icon = "💨", name = "Speed", value = self._currentPetData.baseStats.speed, color = Color3.fromRGB(100, 255, 100)},
        {icon = "🍀", name = "Luck", value = self._currentPetData.baseStats.luck, color = Color3.fromRGB(255, 200, 50)},
        {icon = "⚡", name = "Power", value = self:CalculatePower(), color = RARITY_COLORS[self._currentPetData.rarity]}
    }
    
    for i, stat in ipairs(stats) do
        self:CreateStatBar(statsFrame, stat, i)
    end
end

function PetDetailsUI:CreateStatBar(parent, stat, index)
    local statFrame = Instance.new("Frame")
    statFrame.Size = UDim2.new(1, -20, 0.15, 0)
    statFrame.Position = UDim2.new(0, 10, 0.15 * (index - 1) + 0.05, 0)
    statFrame.BackgroundTransparency = 1
    statFrame.Parent = parent
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 0, 0.5, -15)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.Gotham
    icon.Text = stat.icon
    icon.TextScaled = true
    icon.Parent = statFrame
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.3, -40, 1, 0)
    nameLabel.Position = UDim2.new(0, 40, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = stat.name
    nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = statFrame
    
    -- Bar background
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.5, 0, 0.6, 0)
    barBg.Position = UDim2.new(0.35, 0, 0.2, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    barBg.Parent = statFrame
    
    self._utilities.CreateCorner(barBg, 6)
    
    -- Bar fill
    local maxStat = 1000 -- Adjust based on your stat scaling
    local fillPercent = math.min(stat.value / maxStat, 1)
    
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0) -- Start at 0 for animation
    barFill.BackgroundColor3 = stat.color
    barFill.Parent = barBg
    
    self._utilities.CreateCorner(barFill, 6)
    
    -- Animate fill
    task.wait(0.1 * index)
    self._utilities.Tween(barFill, {
        Size = UDim2.new(fillPercent, 0, 1, 0)
    }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.15, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.85, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(stat.value)
    valueLabel.TextColor3 = stat.color
    valueLabel.TextScaled = true
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = statFrame
end

function PetDetailsUI:CreateRightPanel()
    local rightPanel = Instance.new("Frame")
    rightPanel.Size = UDim2.new(0.6, -10, 1, -180)
    rightPanel.Position = UDim2.new(0.4, 10, 0, 90)
    rightPanel.BackgroundColor3 = Color3.new(1, 1, 1)
    rightPanel.ZIndex = 201
    rightPanel.Parent = self._detailsFrame
    
    self._utilities.CreateCorner(rightPanel, 16)
    
    -- Tab buttons
    self:CreateTabButtons(rightPanel)
    
    -- Tab content
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, -70)
    contentFrame.Position = UDim2.new(0, 10, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = rightPanel
    
    -- Create all tab contents
    for _, tabConfig in ipairs(TAB_CONFIGS) do
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Name = tabConfig.name .. "Tab"
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.ScrollBarThickness = 6
        tabFrame.Visible = tabConfig.name == self._activeTab
        tabFrame.Parent = contentFrame
        
        self._tabFrames[tabConfig.name] = tabFrame
        
        -- Populate tab content
        if tabConfig.name == "Overview" then
            self:CreateOverviewTab(tabFrame)
        elseif tabConfig.name == "Abilities" then
            self:CreateAbilitiesTab(tabFrame)
        elseif tabConfig.name == "Evolution" then
            self:CreateEvolutionTab(tabFrame)
        elseif tabConfig.name == "Synergies" then
            self:CreateSynergiesTab(tabFrame)
        elseif tabConfig.name == "Collection" then
            self:CreateCollectionTab(tabFrame)
        end
    end
end

function PetDetailsUI:CreateTabButtons(parent)
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 0, 50)
    tabContainer.Position = UDim2.new(0, 10, 0, 10)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 5)
    layout.Parent = tabContainer
    
    for _, tabConfig in ipairs(TAB_CONFIGS) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.2, -5, 1, 0)
        button.BackgroundColor3 = tabConfig.name == self._activeTab and tabConfig.color or Color3.new(0.95, 0.95, 0.95)
        button.Font = Enum.Font.GothamBold
        button.Text = tabConfig.icon .. " " .. tabConfig.name
        button.TextColor3 = tabConfig.name == self._activeTab and Color3.new(1, 1, 1) or Color3.fromRGB(100, 100, 100)
        button.TextScaled = true
        button.Parent = tabContainer
        
        self._utilities.CreateCorner(button, 10)
        
        button.MouseButton1Click:Connect(function()
            self:SwitchTab(tabConfig.name)
            
            -- Update all buttons
            for _, child in pairs(tabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    local isActive = child.Text:find(tabConfig.name)
                    child.BackgroundColor3 = isActive and tabConfig.color or Color3.new(0.95, 0.95, 0.95)
                    child.TextColor3 = isActive and Color3.new(1, 1, 1) or Color3.fromRGB(100, 100, 100)
                end
            end
        end)
    end
end

function PetDetailsUI:SwitchTab(tabName)
    self._activeTab = tabName
    
    for name, frame in pairs(self._tabFrames) do
        frame.Visible = name == tabName
    end
    
    self._soundSystem:PlayUISound("Click")
end

-- ========================================
-- TAB CONTENTS
-- ========================================

function PetDetailsUI:CreateOverviewTab(parent)
    local padding = Instance.new("UIPadding")
    padding.PaddingAll = UDim.new(0, 10)
    padding.Parent = parent
    
    -- Description
    local descFrame = self:CreateSection(parent, "Description", 0)
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 60)
    descLabel.Position = UDim2.new(0, 10, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = self._currentPetData.description
    descLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    descLabel.TextScaled = true
    descLabel.TextWrapped = true
    descLabel.Parent = descFrame
    
    -- Passive bonuses
    if self._currentPetData.passives then
        local passiveFrame = self:CreateSection(parent, "Passive Bonuses", 120)
        local yOffset = 35
        
        for _, passive in ipairs(self._currentPetData.passives) do
            local passiveItem = Instance.new("Frame")
            passiveItem.Size = UDim2.new(1, -20, 0, 50)
            passiveItem.Position = UDim2.new(0, 10, 0, yOffset)
            passiveItem.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            passiveItem.Parent = passiveFrame
            
            self._utilities.CreateCorner(passiveItem, 8)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.7, -10, 0.5, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Text = passive.name
            nameLabel.TextColor3 = RARITY_COLORS[self._currentPetData.rarity]
            nameLabel.TextScaled = true
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = passiveItem
            
            local descLabel = Instance.new("TextLabel")
            descLabel.Size = UDim2.new(1, -20, 0.5, 0)
            descLabel.Position = UDim2.new(0, 10, 0.5, 0)
            descLabel.BackgroundTransparency = 1
            descLabel.Font = Enum.Font.Gotham
            descLabel.Text = passive.description
            descLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
            descLabel.TextScaled = true
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = passiveItem
            
            yOffset = yOffset + 60
        end
    end
end

function PetDetailsUI:CreateAbilitiesTab(parent)
    local padding = Instance.new("UIPadding")
    padding.PaddingAll = UDim.new(0, 10)
    padding.Parent = parent
    
    local yOffset = 0
    
    for i, ability in ipairs(self._currentPetData.abilities or {}) do
        local abilityFrame = Instance.new("Frame")
        abilityFrame.Size = UDim2.new(1, 0, 0, 150)
        abilityFrame.Position = UDim2.new(0, 0, 0, yOffset)
        abilityFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
        abilityFrame.Parent = parent
        
        self._utilities.CreateCorner(abilityFrame, 12)
        
        -- Ability icon (placeholder)
        local iconFrame = Instance.new("Frame")
        iconFrame.Size = UDim2.new(0, 80, 0, 80)
        iconFrame.Position = UDim2.new(0, 15, 0.5, -40)
        iconFrame.BackgroundColor3 = RARITY_COLORS[self._currentPetData.rarity]
        iconFrame.Parent = abilityFrame
        
        self._utilities.CreateCorner(iconFrame, 12)
        
        -- Ability name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0.25, 0)
        nameLabel.Position = UDim2.new(0, 110, 0.1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = ability.name
        nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        nameLabel.TextScaled = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = abilityFrame
        
        -- Level requirement
        if ability.unlockLevel > 1 then
            local levelReq = Instance.new("TextLabel")
            levelReq.Size = UDim2.new(0.3, 0, 0.2, 0)
            levelReq.Position = UDim2.new(0.7, 0, 0.1, 0)
            levelReq.BackgroundTransparency = 1
            levelReq.Font = Enum.Font.Gotham
            levelReq.Text = "Lv. " .. ability.unlockLevel
            levelReq.TextColor3 = self._currentPetInstance.level >= ability.unlockLevel 
                and Color3.fromRGB(100, 200, 100) 
                or Color3.fromRGB(200, 100, 100)
            levelReq.TextScaled = true
            levelReq.TextXAlignment = Enum.TextXAlignment.Right
            levelReq.Parent = abilityFrame
        end
        
        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.85, -110, 0.35, 0)
        descLabel.Position = UDim2.new(0, 110, 0.35, 0)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = ability.description
        descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        descLabel.TextScaled = true
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = abilityFrame
        
        -- Cooldown and mana
        local statsText = string.format("Cooldown: %ds | Mana: %d", ability.cooldown or 0, ability.manaCost or 0)
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Size = UDim2.new(0.85, -110, 0.2, 0)
        statsLabel.Position = UDim2.new(0, 110, 0.75, 0)
        statsLabel.BackgroundTransparency = 1
        statsLabel.Font = Enum.Font.Gotham
        statsLabel.Text = statsText
        statsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        statsLabel.TextScaled = true
        statsLabel.TextXAlignment = Enum.TextXAlignment.Left
        statsLabel.Parent = abilityFrame
        
        -- Ultimate indicator
        if ability.isUltimate then
            local ultBadge = Instance.new("Frame")
            ultBadge.Size = UDim2.new(0, 100, 0, 25)
            ultBadge.Position = UDim2.new(1, -110, 0, 10)
            ultBadge.BackgroundColor3 = RARITY_COLORS[8]
            ultBadge.Parent = abilityFrame
            
            self._utilities.CreateCorner(ultBadge, 12)
            
            local ultLabel = Instance.new("TextLabel")
            ultLabel.Size = UDim2.new(1, 0, 1, 0)
            ultLabel.BackgroundTransparency = 1
            ultLabel.Font = Enum.Font.GothamBold
            ultLabel.Text = "ULTIMATE"
            ultLabel.TextColor3 = Color3.new(1, 1, 1)
            ultLabel.TextScaled = true
            ultLabel.Parent = ultBadge
        end
        
        yOffset = yOffset + 160
    end
end

function PetDetailsUI:CreateEvolutionTab(parent)
    local padding = Instance.new("UIPadding")
    padding.PaddingAll = UDim.new(0, 10)
    padding.Parent = parent
    
    if self._currentPetData.evolution then
        -- Current form
        local currentFrame = self:CreateEvolutionCard(parent, self._currentPetData, 0, true)
        
        -- Arrow
        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(1, 0, 0, 50)
        arrow.Position = UDim2.new(0, 0, 0, 160)
        arrow.BackgroundTransparency = 1
        arrow.Font = Enum.Font.Gotham
        arrow.Text = "⬇️"
        arrow.TextScaled = true
        arrow.Parent = parent
        
        -- Next form
        local nextPetData = PetDatabase:GetPet(self._currentPetData.evolution.evolvesTo)
        if nextPetData then
            local nextFrame = self:CreateEvolutionCard(parent, nextPetData, 220, false)
            
            -- Requirements
            local reqFrame = Instance.new("Frame")
            reqFrame.Size = UDim2.new(1, 0, 0, 100)
            reqFrame.Position = UDim2.new(0, 0, 0, 380)
            reqFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            reqFrame.Parent = parent
            
            self._utilities.CreateCorner(reqFrame, 12)
            
            local reqTitle = Instance.new("TextLabel")
            reqTitle.Size = UDim2.new(1, 0, 0.3, 0)
            reqTitle.BackgroundTransparency = 1
            reqTitle.Font = Enum.Font.GothamBold
            reqTitle.Text = "Evolution Requirements"
            reqTitle.TextColor3 = RARITY_COLORS[5]
            reqTitle.TextScaled = true
            reqTitle.Parent = reqFrame
            
            local reqText = string.format(
                "Level %d Required\n%s", 
                self._currentPetData.evolution.requiredLevel,
                self:FormatRequirements(self._currentPetData.evolution.requiredItems)
            )
            
            local reqLabel = Instance.new("TextLabel")
            reqLabel.Size = UDim2.new(1, -20, 0.7, -10)
            reqLabel.Position = UDim2.new(0, 10, 0.3, 5)
            reqLabel.BackgroundTransparency = 1
            reqLabel.Font = Enum.Font.Gotham
            reqLabel.Text = reqText
            reqLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
            reqLabel.TextScaled = true
            reqLabel.TextWrapped = true
            reqLabel.Parent = reqFrame
        end
    else
        -- No evolution
        local noEvoLabel = Instance.new("TextLabel")
        noEvoLabel.Size = UDim2.new(1, 0, 0.5, 0)
        noEvoLabel.Position = UDim2.new(0, 0, 0.25, 0)
        noEvoLabel.BackgroundTransparency = 1
        noEvoLabel.Font = Enum.Font.GothamBold
        noEvoLabel.Text = "This pet has reached its final form!"
        noEvoLabel.TextColor3 = RARITY_COLORS[self._currentPetData.rarity]
        noEvoLabel.TextScaled = true
        noEvoLabel.Parent = parent
    end
end

function PetDetailsUI:CreateActionBar()
    local actionBar = Instance.new("Frame")
    actionBar.Size = UDim2.new(1, 0, 0, 80)
    actionBar.Position = UDim2.new(0, 0, 1, -80)
    actionBar.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    actionBar.ZIndex = 201
    actionBar.Parent = self._detailsFrame
    
    self._utilities.CreateCorner(actionBar, 20)
    
    -- Action buttons
    local actions = {
        {name = "Equip", color = RARITY_COLORS[4], callback = function() self:OnEquipClicked() end},
        {name = "Lock", color = RARITY_COLORS[5], callback = function() self:OnLockClicked() end},
        {name = "Rename", color = RARITY_COLORS[6], callback = function() self:OnRenameClicked() end},
        {name = "Compare", color = RARITY_COLORS[7], callback = function() self:OnCompareClicked() end}
    }
    
    local buttonWidth = 1 / #actions
    
    for i, action in ipairs(actions) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(buttonWidth, -10, 1, -20)
        button.Position = UDim2.new(buttonWidth * (i - 1), 5, 0, 10)
        button.BackgroundColor3 = action.color
        button.Font = Enum.Font.GothamBold
        button.Text = action.name:upper()
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Parent = actionBar
        
        self._utilities.CreateCorner(button, 12)
        
        -- Button effects
        button.MouseEnter:Connect(function()
            self._utilities.Tween(button, {
                Size = UDim2.new(buttonWidth, -8, 1, -18)
            }, TweenInfo.new(0.1, Enum.EasingStyle.Quad))
        end)
        
        button.MouseLeave:Connect(function()
            self._utilities.Tween(button, {
                Size = UDim2.new(buttonWidth, -10, 1, -20)
            }, TweenInfo.new(0.1, Enum.EasingStyle.Quad))
        end)
        
        button.MouseButton1Click:Connect(function()
            action.callback()
            
            -- Click effect
            local clickEffect = Instance.new("Frame")
            clickEffect.Size = UDim2.new(0, 0, 0, 0)
            clickEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
            clickEffect.AnchorPoint = Vector2.new(0.5, 0.5)
            clickEffect.BackgroundColor3 = Color3.new(1, 1, 1)
            clickEffect.BackgroundTransparency = 0.5
            clickEffect.Parent = button
            
            self._utilities.CreateCorner(clickEffect, 12)
            
            self._utilities.Tween(clickEffect, {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
            
            game:GetService("Debris"):AddItem(clickEffect, 0.3)
        end)
    end
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function PetDetailsUI:CalculatePower()
    local power = 0
    local stats = self._currentPetData.baseStats
    
    if stats then
        power = stats.attack + stats.defense + (stats.health / 10)
        
        -- Level multiplier
        local level = self._currentPetInstance.level or 1
        power = power * (1 + (level - 1) * 0.1)
        
        -- Rarity multiplier
        power = power * self._currentPetData.rarity
        
        -- Variant multiplier
        if self._currentPetInstance.variant then
            local variantData = PetDatabase.VARIANTS[self._currentPetInstance.variant]
            if variantData then
                power = power * variantData.multiplier
            end
        end
    end
    
    return math.floor(power)
end

function PetDetailsUI:CreateSection(parent, title, yPos)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 100)
    section.Position = UDim2.new(0, 0, 0, yPos)
    section.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    section.Parent = parent
    
    self._utilities.CreateCorner(section, 12)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = RARITY_COLORS[self._currentPetData.rarity]
    titleLabel.TextScaled = true
    titleLabel.Parent = section
    
    return section
end

function PetDetailsUI:OnEquipClicked()
    local isEquipping = not self._currentPetInstance.equipped
    local remoteName = isEquipping and "EquipPet" or "UnequipPet"
    
    self._remoteManager:InvokeServer(remoteName, self._currentPetInstance.uniqueId)
    self._soundSystem:PlayUISound("Equip")
end

-- ========================================
-- CLEANUP
-- ========================================

function PetDetailsUI:Destroy()
    if self._janitor then
        self._janitor:Cleanup()
        self._janitor = nil
    end
end

return PetDetailsUI