--[[
    Module: MainUI
    Description: Main UI framework that creates the base ScreenGui, navigation bar, main panel,
                 currency display, and manages overall UI structure
    Features: Responsive design, navigation system, module management, overlay handling
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local MainUI = {}
MainUI.__index = MainUI

-- ========================================
-- TYPES
-- ========================================

type NavigationButton = {
    Name: string,
    Icon: string,
    Module: string,
    Callback: (() -> ())?,
}

type ModuleState = {
    instance: table?,
    frame: Frame?,
    isOpen: boolean,
    isInitialized: boolean,
}

type OverlayData = {
    frame: Frame,
    zIndex: number,
    closeCallback: (() -> ())?,
}

-- ========================================
-- CONSTANTS
-- ========================================

local NAVIGATION_WIDTH = 80
local CURRENCY_DISPLAY_WIDTH = 400
local CURRENCY_DISPLAY_HEIGHT = 60
local NAV_BUTTON_HEIGHT = 60
local NAV_BUTTON_PADDING = 10
local MAIN_PANEL_CORNER_RADIUS = 0 -- Seamless connection
local TOOLTIP_OFFSET = 10
local TOOLTIP_ANIMATION_TIME = 0.2
local UI_PADDING = 10

-- Default navigation buttons
local DEFAULT_NAV_BUTTONS: {NavigationButton} = {
    {Name = "Shop", Icon = "rbxassetid://10000000006", Module = "ShopUI"},
    {Name = "Inventory", Icon = "rbxassetid://10000000005", Module = "InventoryUI"},
    {Name = "Trade", Icon = "rbxassetid://10000000007", Module = "TradingUI"},
    {Name = "Battle", Icon = "rbxassetid://10000000008", Module = "BattleUI"},
    {Name = "Quest", Icon = "rbxassetid://10000000009", Module = "QuestUI"},
    {Name = "Settings", Icon = "rbxassetid://10000000010", Module = "SettingsUI"},
}

-- ========================================
-- INITIALIZATION
-- ========================================

function MainUI.new(dependencies)
    local self = setmetatable({}, MainUI)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    self._dataCache = dependencies.DataCache
    self._uiFactory = dependencies.UIFactory
    self._animationSystem = dependencies.AnimationSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._soundSystem = dependencies.SoundSystem
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.ScreenGui = nil
    self.MainContainer = nil
    self.MainPanel = nil
    self.NavigationBar = nil
    self.CurrencyDisplay = nil
    self.NotificationContainer = nil
    
    -- Module management
    self._modules = {} -- Module instances
    self._moduleStates = {} -- Module states
    self._currentModule = nil
    
    -- Navigation
    self._navButtons = {}
    self._navHoverStates = {}
    self._customNavButtons = {}
    
    -- Overlay management
    self._activeOverlays = {}
    self._overlayStack = {}
    
    -- Currency tracking
    self._currencyLabels = {}
    self._currencyAnimations = {}
    self._currencyValues = {}
    
    -- Settings
    self._uiScale = 1
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Cleanup tracking
    self._connections = {}
    self._isDestroyed = false
    
    self:Initialize()
    
    return self
end

function MainUI:Initialize()
    -- Create main screen GUI
    self:CreateScreenGui()
    
    -- Create main container
    self:CreateMainContainer()
    
    -- Create navigation bar
    self:CreateNavigationBar()
    
    -- Create main panel
    self:CreateMainPanel()
    
    -- Create currency display
    self:CreateCurrencyDisplay()
    
    -- Create notification container
    self:CreateNotificationContainer()
    
    -- Set up data bindings
    self:SetupDataBindings()
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    -- Clean up any lingering overlays
    self:CleanupLingeringOverlays()
    
    -- Start update loops
    self:StartUpdateLoops()
    
    if self._debugMode then
        print("[MainUI] Initialized successfully")
    end
end

-- ========================================
-- SCREEN GUI CREATION
-- ========================================

function MainUI:CreateScreenGui()
    -- Check for existing instance first
    local playerGui = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    local existingUI = playerGui:FindFirstChild("SanrioTycoonUI")
    
    if existingUI then
        existingUI:Destroy()
        warn("[MainUI] Removed existing SanrioTycoonUI to prevent duplicates")
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SanrioTycoonUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10
    screenGui.Parent = playerGui
    
    self.ScreenGui = screenGui
end

function MainUI:CreateMainContainer()
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.BackgroundTransparency = 1
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = self.ScreenGui
    
    -- Apply UI scale
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = self._uiScale
    uiScale.Parent = mainContainer
    
    self.MainContainer = mainContainer
    self._uiScaleInstance = uiScale
end

-- ========================================
-- NAVIGATION BAR
-- ========================================

function MainUI:CreateNavigationBar()
    -- Create navigation bar frame
    local navBar = Instance.new("Frame")
    navBar.Name = "NavigationBar"
    navBar.Size = UDim2.new(0, NAVIGATION_WIDTH, 1, 0)
    navBar.Position = UDim2.new(0, 0, 0, 0)
    navBar.BackgroundColor3 = self._config.COLORS.White
    navBar.BorderSizePixel = 0
    navBar.ClipsDescendants = false
    navBar.ZIndex = self._config.ZINDEX and self._config.ZINDEX.Navigation or 30
    navBar.Parent = self.MainContainer
    
    -- No corner radius for seamless connection
    -- No shadow to prevent overlap issues
    
    -- Create button container with padding
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 1, -20)
    buttonContainer.Position = UDim2.new(0, 0, 0, 10)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = navBar
    
    -- Layout for buttons
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, NAV_BUTTON_PADDING)
    layout.Parent = buttonContainer
    
    -- Padding
    self._utilities.CreatePadding(buttonContainer, UI_PADDING)
    
    self.NavigationBar = navBar
    self._navButtonContainer = buttonContainer
    
    -- Create navigation buttons
    self:CreateNavigationButtons()
end

function MainUI:CreateNavigationButtons()
    local buttons = {}
    
    -- Combine default and custom buttons
    for _, navData in ipairs(DEFAULT_NAV_BUTTONS) do
        table.insert(buttons, navData)
    end
    
    for _, navData in ipairs(self._customNavButtons) do
        table.insert(buttons, navData)
    end
    
    -- Create buttons
    for _, navData in ipairs(buttons) do
        self:CreateNavButton(navData)
    end
end

function MainUI:CreateNavButton(navData: NavigationButton)
    local button = Instance.new("TextButton")
    button.Name = navData.Name .. "NavButton"
    button.Size = UDim2.new(1, 0, 0, NAV_BUTTON_HEIGHT)
    button.BackgroundColor3 = self._config.COLORS.Background
    button.Text = ""
    button.AutoButtonColor = false -- We'll handle hover manually
    button.BorderSizePixel = 0
    button.ZIndex = self._config.ZINDEX.Default + 1
    button.Parent = self._navButtonContainer
    
    self._utilities.CreateCorner(button, 8)
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0.5, -20, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Image = navData.Icon or ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = button.ZIndex + 1
    icon.Parent = button
    
    -- Store button reference
    self._navButtons[navData.Name] = button
    
    -- Initialize hover state
    self._navHoverStates[button] = {
        originalColor = self._config.COLORS.Background,
        isHovered = false,
        activeTween = nil,
        tooltip = nil,
    }
    
    -- Set up interactions
    self:SetupNavButtonInteractions(button, navData)
end

function MainUI:SetupNavButtonInteractions(button: TextButton, navData: NavigationButton)
    local state = self._navHoverStates[button]
    
    -- Mouse enter
    button.MouseEnter:Connect(function()
        if state.activeTween then
            state.activeTween:Cancel()
        end
        
        state.isHovered = true
        state.activeTween = self._utilities.Tween(button, {
            BackgroundColor3 = self._config.COLORS.Primary
        }, self._config.TWEEN_INFO.Fast)
        
        -- Create tooltip
        self:CreateNavTooltip(button, navData.Name)
    end)
    
    -- Mouse leave
    button.MouseLeave:Connect(function()
        if state.activeTween then
            state.activeTween:Cancel()
        end
        
        state.isHovered = false
        state.activeTween = self._utilities.Tween(button, {
            BackgroundColor3 = state.originalColor
        }, self._config.TWEEN_INFO.Fast)
        
        -- Remove tooltip
        self:RemoveNavTooltip(navData.Name)
    end)
    
    -- Click
    button.MouseButton1Click:Connect(function()
        if self._soundSystem then
            self._soundSystem:PlayUISound("Click")
        end
        
        -- Force clear hover state
        if state.activeTween then
            state.activeTween:Cancel()
        end
        state.isHovered = false
        button.BackgroundColor3 = state.originalColor
        
        -- Remove tooltip
        self:RemoveNavTooltip(navData.Name)
        
        -- Debounce navigation clicks
        if self._navigationDebounce then
            return
        end
        self._navigationDebounce = true
        
        -- Handle click
        if navData.Callback then
            navData.Callback()
        elseif navData.Module then
            self:OpenModule(navData.Module)
        end
        
        -- Reset debounce after a short delay
        task.wait(0.2)
        self._navigationDebounce = false
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("NavigationClicked", {
                name = navData.Name,
                module = navData.Module,
            })
        end
    end)
end

function MainUI:CreateNavTooltip(button: TextButton, text: string)
    -- Get absolute position
    local absolutePos = button.AbsolutePosition
    local absoluteSize = button.AbsoluteSize
    
    -- Create tooltip at screen level
    local tooltip = Instance.new("Frame")
    tooltip.Name = "NavTooltip_" .. text
    tooltip.Size = UDim2.new(0, 120, 0, 35)
    tooltip.Position = UDim2.new(0, absolutePos.X + absoluteSize.X + TOOLTIP_OFFSET, 0, 
        absolutePos.Y + (absoluteSize.Y - 35) / 2)
    tooltip.BackgroundColor3 = self._config.COLORS.Dark
    tooltip.BackgroundTransparency = 0.05
    tooltip.BorderSizePixel = 0
    tooltip.ZIndex = self._config.ZINDEX.Tooltip
    tooltip.Parent = self.ScreenGui
    
    self._utilities.CreateCorner(tooltip, 8)
    
    -- Tooltip text
    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "Text"
    tooltipText.Size = UDim2.new(1, -10, 1, 0)
    tooltipText.Position = UDim2.new(0, 5, 0, 0)
    tooltipText.BackgroundTransparency = 1
    tooltipText.Text = text
    tooltipText.TextColor3 = self._config.COLORS.White
    tooltipText.TextScaled = true
    tooltipText.Font = self._config.FONTS.Secondary
    tooltipText.ZIndex = tooltip.ZIndex + 1
    tooltipText.Parent = tooltip
    
    -- Add text size constraint
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 16
    textConstraint.MinTextSize = 12
    textConstraint.Parent = tooltipText
    
    -- Animate in
    tooltip.BackgroundTransparency = 1
    tooltipText.TextTransparency = 1
    
    self._utilities.Tween(tooltip, {BackgroundTransparency = 0.05}, self._config.TWEEN_INFO.Fast)
    self._utilities.Tween(tooltipText, {TextTransparency = 0}, self._config.TWEEN_INFO.Fast)
    
    -- Store tooltip reference
    local state = self._navHoverStates[button]
    if state then
        state.tooltip = tooltip
    end
end

function MainUI:RemoveNavTooltip(name: string)
    -- Find and remove all tooltips with this name
    for _, child in ipairs(self.ScreenGui:GetChildren()) do
        if child.Name == "NavTooltip_" .. name then
            child:Destroy()
        end
    end
end

-- ========================================
-- MAIN PANEL
-- ========================================

function MainUI:CreateMainPanel()
    -- Create main UI panel that contains everything else
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainUIPanel"
    mainPanel.Size = UDim2.new(1, -NAVIGATION_WIDTH, 1, 0)
    mainPanel.Position = UDim2.new(0, NAVIGATION_WIDTH, 0, 0)
    mainPanel.BackgroundColor3 = self._config.COLORS.Background
    mainPanel.BackgroundTransparency = 0
    mainPanel.BorderSizePixel = 0
    mainPanel.ClipsDescendants = true
    mainPanel.ZIndex = 5
    mainPanel.Parent = self.MainContainer
    
    -- No corner radius for seamless look
    -- No shadow to prevent overlap issues
    
    self.MainPanel = mainPanel
end

-- ========================================
-- CURRENCY DISPLAY
-- ========================================

function MainUI:CreateCurrencyDisplay()
    local currencyFrame = Instance.new("Frame")
    currencyFrame.Name = "CurrencyDisplay"
    currencyFrame.Size = UDim2.new(0, CURRENCY_DISPLAY_WIDTH, 0, CURRENCY_DISPLAY_HEIGHT)
    currencyFrame.Position = UDim2.new(0.5, 0, 0, 10)
    currencyFrame.AnchorPoint = Vector2.new(0.5, 0)
    currencyFrame.BackgroundColor3 = self._config.COLORS.White
    currencyFrame.BorderSizePixel = 0
    currencyFrame.ZIndex = self._config.ZINDEX and self._config.ZINDEX.CurrencyDisplay or 100
    currencyFrame.Parent = self.ScreenGui
    
    self._utilities.CreateCorner(currencyFrame, 12)
    
    -- Add subtle shadow for depth
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.Size = UDim2.new(1, 6, 1, 6)
    shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 3)
    shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.9
    shadowFrame.ZIndex = currencyFrame.ZIndex - 1
    shadowFrame.Parent = self.ScreenGui
    self._utilities.CreateCorner(shadowFrame, 14)
    
    -- Add subtle gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.95, 0.95, 0.95))
    })
    gradient.Rotation = 90
    gradient.Parent = currencyFrame
    
    -- Add border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = self._config.COLORS.Primary
    stroke.Transparency = 0.9
    stroke.Thickness = 1
    stroke.Parent = currencyFrame
    
    -- Layout for currency items
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Padding = UDim.new(0, 10)
    layout.Parent = currencyFrame
    
    self._utilities.CreatePadding(currencyFrame, 10)
    
    -- Create currency displays
    local currencies = {
        {name = "Coins", icon = self._config.ICONS.Coin or "rbxassetid://10000000001"},
        {name = "Gems", icon = self._config.ICONS.Gem or "rbxassetid://10000000002"},
        {name = "Tickets", icon = self._config.ICONS.Ticket or "rbxassetid://10000000003"},
    }
    
    for _, currencyData in ipairs(currencies) do
        self:CreateCurrencyItem(currencyFrame, currencyData)
    end
    
    self.CurrencyDisplay = currencyFrame
end

function MainUI:CreateCurrencyItem(parent: Frame, currencyData: {name: string, icon: string})
    local container = Instance.new("Frame")
    container.Name = currencyData.name .. "Container"
    container.Size = UDim2.new(0, 120, 1, 0)
    container.BackgroundTransparency = 0.95
    container.BackgroundColor3 = self._config.COLORS.Primary
    container.Parent = parent
    
    self._utilities.CreateCorner(container, 8)
    
    -- Add hover effect
    container.MouseEnter:Connect(function()
        self._utilities.Tween(container, {
            BackgroundTransparency = 0.9
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
    end)
    
    container.MouseLeave:Connect(function()
        self._utilities.Tween(container, {
            BackgroundTransparency = 0.95
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
    end)
    
    -- Icon with padding
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 35, 0, 35)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = currencyData.icon
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ImageColor3 = Color3.new(1, 1, 1)
    icon.Parent = container
    
    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(1, -55, 1, 0)
    valueLabel.Position = UDim2.new(0, 50, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "0"
    valueLabel.TextColor3 = self._config.COLORS.Text
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Font = self._config.FONTS.Numbers
    valueLabel.TextScaled = true
    valueLabel.Parent = container
    
    -- Text size constraint
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 20
    textConstraint.MinTextSize = 14
    textConstraint.Parent = valueLabel
    
    -- Store reference
    self._currencyLabels[currencyData.name] = valueLabel
    
    -- Make clickable for copy value
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:OnCurrencyClicked(currencyData.name, valueLabel.Text)
        end
    end)
end

function MainUI:OnCurrencyClicked(currencyName: string, value: string)
    -- Copy to clipboard functionality would go here
    -- For now, just show a notification
    if self._notificationSystem then
        self._notificationSystem:Show({
            text = currencyName .. ": " .. value,
            type = "info",
            duration = 2,
        })
    end
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
end

function MainUI:UpdateCurrency(currencyName: string, value: number)
    local label = self._currencyLabels[currencyName]
    if not label then return end
    
    -- Get old value
    local oldValue = self._currencyValues[currencyName] or value
    self._currencyValues[currencyName] = value
    
    -- Animate number change
    if oldValue ~= value then
        -- Show difference indicator
        self:ShowCurrencyDifference(label, value - oldValue)
        
        -- Animate the number counting
        self:AnimateCurrencyCount(label, oldValue, value)
        
        -- Glow effect on change
        self:AnimateCurrencyGlow(label.Parent)
    else
        -- Just update text if no change
        label.Text = self._utilities.FormatNumber(value)
    end
end

function MainUI:AnimateCurrencyCount(label: TextLabel, fromValue: number, toValue: number)
    local startTime = tick()
    local duration = 0.5
    local difference = toValue - fromValue
    
    -- Cancel previous animation
    if self._currencyAnimations[label] then
        self._currencyAnimations[label]:Disconnect()
    end
    
    -- Create counting animation
    self._currencyAnimations[label] = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Ease out cubic
        progress = 1 - math.pow(1 - progress, 3)
        
        local currentValue = fromValue + (difference * progress)
        label.Text = self._utilities.FormatNumber(math.floor(currentValue))
        
        if progress >= 1 then
            self._currencyAnimations[label]:Disconnect()
            self._currencyAnimations[label] = nil
            label.Text = self._utilities.FormatNumber(toValue)
        end
    end)
end

function MainUI:ShowCurrencyDifference(label: TextLabel, difference: number)
    local container = label.Parent
    
    -- Create difference indicator
    local diffLabel = Instance.new("TextLabel")
    diffLabel.Size = UDim2.new(0, 100, 0, 30)
    diffLabel.Position = UDim2.new(0.5, 0, 0, -10)
    diffLabel.AnchorPoint = Vector2.new(0.5, 1)
    diffLabel.BackgroundTransparency = 1
    diffLabel.Font = self._config.FONTS.Numbers
    diffLabel.TextScaled = true
    diffLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    diffLabel.TextStrokeTransparency = 0
    diffLabel.ZIndex = container.ZIndex + 10
    diffLabel.Parent = container
    
    if difference > 0 then
        diffLabel.Text = "+" .. self._utilities.FormatNumber(difference)
        diffLabel.TextColor3 = self._config.COLORS.Success
    else
        diffLabel.Text = self._utilities.FormatNumber(difference)
        diffLabel.TextColor3 = self._config.COLORS.Error
    end
    
    -- Animate floating up
    self._utilities.Tween(diffLabel, {
        Position = UDim2.new(0.5, 0, 0, -40),
        TextTransparency = 1,
        TextStrokeTransparency = 1
    }, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    game:GetService("Debris"):AddItem(diffLabel, 1.5)
end

function MainUI:AnimateCurrencyGlow(container: Frame)
    -- Create glow effect
    local glow = Instance.new("Frame")
    glow.Name = "CurrencyGlow"
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundColor3 = self._config.COLORS.Success
    glow.BackgroundTransparency = 0.5
    glow.ZIndex = container.ZIndex - 1
    glow.Parent = container.Parent
    
    self._utilities.CreateCorner(glow, 12)
    
    -- Pulse animation
    self._utilities.Tween(glow, {
        Size = UDim2.new(1, 20, 1, 20),
        BackgroundTransparency = 1
    }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    game:GetService("Debris"):AddItem(glow, 0.5)
    
    -- Scale bounce effect
    local originalSize = container.Size
    self._utilities.Tween(container, {
        Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 5, 
                        originalSize.Y.Scale, originalSize.Y.Offset + 5)
    }, TweenInfo.new(0.1, Enum.EasingStyle.Quad))
    
    task.wait(0.1)
    
    self._utilities.Tween(container, {
        Size = originalSize
    }, TweenInfo.new(0.1, Enum.EasingStyle.Quad))
end

-- ========================================
-- NOTIFICATION CONTAINER
-- ========================================

function MainUI:CreateNotificationContainer()
    local notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "NotificationContainer"
    notificationContainer.Size = UDim2.new(0, 350, 1, -20)
    notificationContainer.Position = UDim2.new(1, -360, 0, 10)
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.ZIndex = self._config.ZINDEX.Notification
    notificationContainer.Parent = self.MainPanel
    
    self.NotificationContainer = notificationContainer
    
    -- Pass container to notification system
    if self._notificationSystem and self._notificationSystem.SetContainer then
        self._notificationSystem:SetContainer(notificationContainer)
    end
end

-- ========================================
-- MODULE MANAGEMENT
-- ========================================

function MainUI:RegisterModule(moduleName: string, moduleInstance: table)
    self._modules[moduleName] = moduleInstance
    self._moduleStates[moduleName] = {
        instance = moduleInstance,
        frame = nil,
        isOpen = false,
        isInitialized = false,
    }
    
    if self._debugMode then
        print("[MainUI] Registered module:", moduleName)
    end
end

function MainUI:GetScreenGui(): ScreenGui?
    return self.ScreenGui
end

function MainUI:OpenModule(moduleName: string)
    local moduleState = self._moduleStates[moduleName]
    if not moduleState then
        warn("[MainUI] Module not found:", moduleName)
        return
    end
    
    -- Close current module if different with animation
    if self._currentModule and self._currentModule ~= moduleName then
        -- Fade out current module
        local currentState = self._moduleStates[self._currentModule]
        if currentState and currentState.instance and currentState.instance.Frame then
            self._utilities.Tween(currentState.instance.Frame, {
                Position = UDim2.new(0, -50, 0, 0),
                BackgroundTransparency = 1
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
        end
        
        task.wait(0.1)
        self:CloseModule(self._currentModule)
    end
    
    -- Initialize module if needed
    if not moduleState.isInitialized then
        self:InitializeModule(moduleName)
    end
    
    -- Open module
    if moduleState.instance and moduleState.instance.Open then
        moduleState.instance:Open()
        moduleState.isOpen = true
        self._currentModule = moduleName
        
        -- Animate in the new module
        if moduleState.instance.Frame then
            moduleState.instance.Frame.Position = UDim2.new(0, 50, 0, 0)
            moduleState.instance.Frame.BackgroundTransparency = 1
            
            self._utilities.Tween(moduleState.instance.Frame, {
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 0
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("ModuleOpened", {
                name = moduleName,
            })
        end
    end
end

function MainUI:CloseModule(moduleName: string)
    local moduleState = self._moduleStates[moduleName]
    if not moduleState or not moduleState.isOpen then return end
    
    if moduleState.instance and moduleState.instance.Close then
        moduleState.instance:Close()
        moduleState.isOpen = false
        
        if self._currentModule == moduleName then
            self._currentModule = nil
        end
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("ModuleClosed", {
                name = moduleName,
            })
        end
    end
end

function MainUI:InitializeModule(moduleName: string)
    local moduleState = self._moduleStates[moduleName]
    if not moduleState or moduleState.isInitialized then return end
    
    -- Create module frame
    local moduleFrame = Instance.new("Frame")
    moduleFrame.Name = moduleName .. "Frame"
    moduleFrame.Size = UDim2.new(1, -20, 1, -80)
    moduleFrame.Position = UDim2.new(0, 10, 0, 70)
    moduleFrame.BackgroundTransparency = 1
    moduleFrame.Visible = false
    moduleFrame.Parent = self.MainPanel
    
    moduleState.frame = moduleFrame
    
    -- Initialize module with frame
    if moduleState.instance and moduleState.instance.Initialize then
        moduleState.instance:Initialize(moduleFrame, {
            mainUI = self,
            eventBus = self._eventBus,
            stateManager = self._stateManager,
            dataCache = self._dataCache,
        })
    end
    
    moduleState.isInitialized = true
end

-- ========================================
-- OVERLAY MANAGEMENT
-- ========================================

function MainUI:CreateOverlay(name: string, options: {zIndex: number?, closeOnClick: boolean?}?): Frame
    options = options or {}
    
    -- Create overlay background
    local overlay = Instance.new("Frame")
    overlay.Name = name .. "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = options.zIndex or self._config.ZINDEX.Overlay
    overlay.Parent = self.ScreenGui
    
    -- Click to close functionality
    if options.closeOnClick then
        overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:RemoveOverlay(name)
            end
        end)
    end
    
    -- Track overlay
    self._activeOverlays[name] = {
        frame = overlay,
        zIndex = overlay.ZIndex,
        closeCallback = nil,
    }
    
    table.insert(self._overlayStack, name)
    
    -- Animate in
    overlay.BackgroundTransparency = 1
    self._utilities.Tween(overlay, {BackgroundTransparency = 0.5}, self._config.TWEEN_INFO.Fast)
    
    return overlay
end

function MainUI:RemoveOverlay(name: string)
    local overlayData = self._activeOverlays[name]
    if not overlayData then return end
    
    -- Animate out
    self._utilities.Tween(overlayData.frame, {BackgroundTransparency = 1}, self._config.TWEEN_INFO.Fast)
    
    task.wait(0.2)
    
    -- Remove from tracking
    overlayData.frame:Destroy()
    self._activeOverlays[name] = nil
    
    -- Remove from stack
    for i, overlayName in ipairs(self._overlayStack) do
        if overlayName == name then
            table.remove(self._overlayStack, i)
            break
        end
    end
    
    -- Fire callback if exists
    if overlayData.closeCallback then
        overlayData.closeCallback()
    end
end

-- ========================================
-- DATA BINDINGS
-- ========================================

function MainUI:SetupDataBindings()
    if not self._dataCache then return end
    
    -- Watch currency changes
    if self._dataCache and self._dataCache.OnDataChanged then
        self._dataCache:OnDataChanged("currencies", function(currencies, oldCurrencies)
            if currencies then
                self:UpdateCurrency("Coins", currencies.coins or 0)
                self:UpdateCurrency("Gems", currencies.gems or 0)
                self:UpdateCurrency("Tickets", currencies.tickets or 0)
            end
        end)
        
        -- Watch settings changes
        self._dataCache:OnDataChanged("settings", function(settings, oldSettings)
            if settings and settings.uiScale then
                self:SetUIScale(settings.uiScale)
            end
        end)
    end
end

-- ========================================
-- EVENT LISTENERS
-- ========================================

function MainUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Listen for module requests
    table.insert(self._connections, self._eventBus:On("OpenModule", function(data)
        self:OpenModule(data.module)
    end))
    
    -- Listen for overlay requests
    table.insert(self._connections, self._eventBus:On("CreateOverlay", function(data)
        self:CreateOverlay(data.name, data.options)
    end))
    
    table.insert(self._connections, self._eventBus:On("RemoveOverlay", function(data)
        self:RemoveOverlay(data.name)
    end))
    
    -- Listen for UI scale changes
    table.insert(self._connections, self._eventBus:On("SetUIScale", function(data)
        self:SetUIScale(data.scale)
    end))
end

-- ========================================
-- UPDATE LOOPS
-- ========================================

function MainUI:StartUpdateLoops()
    -- Tooltip cleanup loop
    spawn(function()
        while not self._isDestroyed and self.ScreenGui and self.ScreenGui.Parent do
            wait(5)
            
            -- Clean up orphaned tooltips
            for _, child in ipairs(self.ScreenGui:GetChildren()) do
                if string.find(child.Name, "NavTooltip_") then
                    -- Check if associated button is still being hovered
                    local isOrphaned = true
                    for button, state in pairs(self._navHoverStates) do
                        if state.tooltip == child and state.isHovered then
                            isOrphaned = false
                            break
                        end
                    end
                    
                    if isOrphaned then
                        child:Destroy()
                    end
                end
            end
        end
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function MainUI:SetUIScale(scale: number)
    self._uiScale = math.clamp(scale, 0.5, 2)
    
    if self._uiScaleInstance then
        self._utilities.Tween(self._uiScaleInstance, {
            Scale = self._uiScale
        }, self._config.TWEEN_INFO.Normal)
    end
end

function MainUI:AddNavigationButton(navData: NavigationButton)
    table.insert(self._customNavButtons, navData)
    self:CreateNavButton(navData)
end

function MainUI:RemoveNavigationButton(name: string)
    -- Remove from custom buttons
    for i, navData in ipairs(self._customNavButtons) do
        if navData.Name == name then
            table.remove(self._customNavButtons, i)
            break
        end
    end
    
    -- Remove button instance
    local button = self._navButtons[name]
    if button then
        button:Destroy()
        self._navButtons[name] = nil
        self._navHoverStates[button] = nil
    end
end

function MainUI:CleanupLingeringOverlays()
    -- Clean up any lingering overlays from previous sessions
    task.wait(0.1)
    
    for _, child in ipairs(self.ScreenGui:GetChildren()) do
        if string.find(child.Name, "Overlay") or 
           (child:IsA("Frame") and child.Size == UDim2.new(1, 0, 1, 0) and 
            child.BackgroundTransparency < 1 and child ~= self.MainContainer) then
            if self._debugMode then
                print("[MainUI] Cleaning up lingering overlay:", child.Name)
            end
            child:Destroy()
        end
    end
end

function MainUI:GetCurrentModule(): string?
    return self._currentModule
end

function MainUI:GetModuleFrame(moduleName: string): Frame?
    local moduleState = self._moduleStates[moduleName]
    return moduleState and moduleState.frame
end

function MainUI:IsModuleOpen(moduleName: string): boolean
    local moduleState = self._moduleStates[moduleName]
    return moduleState and moduleState.isOpen or false
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function MainUI:DebugPrint()
        print("\n=== MainUI Debug Info ===")
        print("Current Module:", self._currentModule or "None")
        print("UI Scale:", self._uiScale)
        
        print("\nRegistered Modules:")
        for moduleName, state in pairs(self._moduleStates) do
            print("  " .. moduleName .. ":", state.isInitialized and "Initialized" or "Not Initialized", 
                  state.isOpen and "(Open)" or "(Closed)")
        end
        
        print("\nActive Overlays:")
        for overlayName in pairs(self._activeOverlays) do
            print("  " .. overlayName)
        end
        
        print("\nNavigation Buttons:")
        for name in pairs(self._navButtons) do
            print("  " .. name)
        end
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function MainUI:Destroy()
    self._isDestroyed = true
    
    -- Disconnect all connections
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    
    -- Clean up all modules
    for moduleName, moduleState in pairs(self._moduleStates) do
        if moduleState.instance and moduleState.instance.Destroy then
            moduleState.instance:Destroy()
        end
    end
    
    -- Clean up tweens
    for _, animation in pairs(self._currencyAnimations) do
        if animation then
            animation:Cancel()
        end
    end
    
    -- Clean up hover states
    for button, state in pairs(self._navHoverStates) do
        if state.activeTween then
            state.activeTween:Cancel()
        end
    end
    
    -- Destroy screen GUI
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    
    -- Clear references
    self._modules = {}
    self._moduleStates = {}
    self._navButtons = {}
    self._navHoverStates = {}
    self._activeOverlays = {}
    self._overlayStack = {}
    self._currencyLabels = {}
    self._currencyAnimations = {}
    self._connections = {}
end

return MainUI