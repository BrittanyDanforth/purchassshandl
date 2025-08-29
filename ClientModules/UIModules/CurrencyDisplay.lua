--[[
    Module: CurrencyDisplay
    Description: Manages the currency display UI with real-time updates, animations,
                 abbreviations, and click-to-copy functionality
    Features: Multi-currency support, animated value changes, formatted numbers, copy to clipboard
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local CurrencyDisplay = {}
CurrencyDisplay.__index = CurrencyDisplay

-- ========================================
-- TYPES
-- ========================================

type CurrencyItem = {
    name: string,
    icon: string,
    value: number,
    label: TextLabel?,
    container: Frame?,
    animationTween: Tween?,
    displayValue: number,
    targetValue: number,
}

type CurrencyOptions = {
    position: UDim2?,
    size: UDim2?,
    parent: Instance?,
    currencies: {{name: string, icon: string}}?,
    animateChanges: boolean?,
    showAbbreviations: boolean?,
    clickToCopy: boolean?,
    layout: "horizontal" | "vertical"?,
}

-- ========================================
-- CONSTANTS
-- ========================================

local DEFAULT_SIZE = UDim2.new(0, 400, 0, 60)
local DEFAULT_POSITION = UDim2.new(0, 10, 0, 70) -- Moved down to avoid overlap
local CURRENCY_ITEM_WIDTH = 120
local ICON_SIZE = 30
local ANIMATION_DURATION = 0.3
local VALUE_UPDATE_RATE = 0.03 -- 30 FPS for smooth counting
local FLASH_COLOR = Color3.fromRGB(50, 255, 50)
local DEFAULT_TEXT_COLOR = Color3.fromRGB(50, 50, 50)
local COPY_NOTIFICATION_DURATION = 2

-- Default currencies
local DEFAULT_CURRENCIES = {
    {name = "Coins", icon = "rbxassetid://10000000001"},
    {name = "Gems", icon = "rbxassetid://10000000002"},
    {name = "Tickets", icon = "rbxassetid://10000000003"},
}

-- ========================================
-- INITIALIZATION
-- ========================================

function CurrencyDisplay.new(dependencies)
    local self = setmetatable({}, CurrencyDisplay)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._dataCache = dependencies.DataCache
    self._animationSystem = dependencies.AnimationSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._soundSystem = dependencies.SoundSystem
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self._currencyItems = {} -- Track currency items by name
    self._valueUpdateConnection = nil
    
    -- Settings
    self._options = {
        animateChanges = true,
        showAbbreviations = true,
        clickToCopy = true,
        layout = "horizontal",
    }
    
    -- State
    self._isUpdating = false
    self._updateQueue = {}
    self._debugMode = self._config.DEBUG.ENABLED
    
    return self
end

function CurrencyDisplay:Initialize(parent: Instance?, options: CurrencyOptions?)
    options = options or {}
    self._options = self:MergeOptions(self._options, options)
    
    -- Create a separate ScreenGui for currency display with highest DisplayOrder
    local playerGui = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    local currencyGui = playerGui:FindFirstChild("CurrencyDisplayGui")
    if not currencyGui then
        currencyGui = Instance.new("ScreenGui")
        currencyGui.Name = "CurrencyDisplayGui"
        currencyGui.ResetOnSpawn = false
        currencyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        currencyGui.DisplayOrder = 999 -- Always on top of other UI
        currencyGui.Parent = playerGui
    end
    
    -- Create main frame
    self:CreateFrame(currencyGui, options)
    
    -- Create currency items
    local currencies = options.currencies or DEFAULT_CURRENCIES
    self:CreateCurrencyItems(currencies)
    
    -- Set up data bindings
    self:SetupDataBindings()
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    -- Start update loop for smooth animations
    self:StartUpdateLoop()
    
    if self._debugMode then
        print("[CurrencyDisplay] Initialized with", #currencies, "currencies")
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function CurrencyDisplay:CreateFrame(parent: Instance, options: CurrencyOptions)
    self.Frame = Instance.new("Frame")
    self.Frame.Name = "CurrencyDisplay"
    self.Frame.Size = options.size or DEFAULT_SIZE
    self.Frame.Position = options.position or DEFAULT_POSITION
    self.Frame.BackgroundColor3 = self._config.COLORS.White
    self.Frame.BorderSizePixel = 0
    self.Frame.ZIndex = 999 -- Always on top of other UI
    self.Frame.Parent = parent
    
    self._utilities.CreateCorner(self.Frame, 8)
    -- No shadow per user feedback
    
    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = options.layout == "vertical" and 
        Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = self.Frame
    
    -- Padding
    self._utilities.CreatePadding(self.Frame, 10)
end

function CurrencyDisplay:CreateCurrencyItems(currencies: {{name: string, icon: string}})
    for i, currencyData in ipairs(currencies) do
        self:CreateCurrencyItem(currencyData, i)
    end
end

function CurrencyDisplay:CreateCurrencyItem(currencyData: {name: string, icon: string}, order: number)
    -- Container
    local container = Instance.new("Frame")
    container.Name = currencyData.name .. "Container"
    container.Size = UDim2.new(0, CURRENCY_ITEM_WIDTH, 1, 0)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = self.Frame
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
    icon.Position = UDim2.new(0, 0, 0.5, -ICON_SIZE/2)
    icon.BackgroundTransparency = 1
    icon.Image = currencyData.icon
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ImageColor3 = self._config.COLORS.White
    icon.Parent = container
    
    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(1, -ICON_SIZE - 10, 1, 0)
    valueLabel.Position = UDim2.new(0, ICON_SIZE + 10, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "0"
    valueLabel.TextColor3 = DEFAULT_TEXT_COLOR
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Font = self._config.FONTS.Numbers
    valueLabel.TextScaled = true
    valueLabel.Parent = container
    
    -- Text size constraint
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 20
    textConstraint.MinTextSize = 14
    textConstraint.Parent = valueLabel
    
    -- Create currency item object
    local currencyItem: CurrencyItem = {
        name = currencyData.name,
        icon = currencyData.icon,
        value = 0,
        label = valueLabel,
        container = container,
        animationTween = nil,
        displayValue = 0,
        targetValue = 0,
    }
    
    self._currencyItems[currencyData.name:lower()] = currencyItem
    
    -- Click to copy functionality
    if self._options.clickToCopy then
        self:SetupClickToCopy(container, currencyItem)
    end
    
    -- Hover effect
    self:SetupHoverEffect(container, icon)
end

-- ========================================
-- CLICK TO COPY
-- ========================================

function CurrencyDisplay:SetupClickToCopy(container: Frame, currencyItem: CurrencyItem)
    container.Active = true
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self:OnCurrencyClicked(currencyItem)
        end
    end)
    
    -- Add click cursor
    container.MouseEnter:Connect(function()
        container.MouseIcon = "rbxasset://SystemCursors/PointingHand"
    end)
    
    container.MouseLeave:Connect(function()
        container.MouseIcon = ""
    end)
end

function CurrencyDisplay:OnCurrencyClicked(currencyItem: CurrencyItem)
    local value = tostring(currencyItem.value)
    
    -- Copy to clipboard (this would need platform-specific implementation)
    -- For now, show a notification with the value
    if self._notificationSystem then
        self._notificationSystem:Show({
            text = currencyItem.name .. ": " .. self._utilities.FormatNumber(currencyItem.value),
            type = "info",
            duration = COPY_NOTIFICATION_DURATION,
        })
    end
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
    
    -- Visual feedback
    local label = currencyItem.label
    if label then
        -- Scale animation
        local originalSize = label.Size
        self._utilities.Tween(label, {
            Size = UDim2.new(originalSize.X.Scale * 1.1, originalSize.X.Offset, 
                           originalSize.Y.Scale * 1.1, originalSize.Y.Offset)
        }, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        task.wait(0.1)
        
        self._utilities.Tween(label, {
            Size = originalSize
        }, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("CurrencyClicked", {
            currency = currencyItem.name,
            value = currencyItem.value,
        })
    end
end

-- ========================================
-- HOVER EFFECTS
-- ========================================

function CurrencyDisplay:SetupHoverEffect(container: Frame, icon: ImageLabel)
    local originalIconSize = icon.Size
    local hoverScale = 1.2
    
    container.MouseEnter:Connect(function()
        self._utilities.Tween(icon, {
            Size = UDim2.new(0, ICON_SIZE * hoverScale, 0, ICON_SIZE * hoverScale),
            Position = UDim2.new(0, -(ICON_SIZE * hoverScale - ICON_SIZE) / 2, 0.5, -ICON_SIZE * hoverScale / 2)
        }, self._config.TWEEN_INFO.Fast)
    end)
    
    container.MouseLeave:Connect(function()
        self._utilities.Tween(icon, {
            Size = originalIconSize,
            Position = UDim2.new(0, 0, 0.5, -ICON_SIZE/2)
        }, self._config.TWEEN_INFO.Fast)
    end)
end

-- ========================================
-- VALUE UPDATES
-- ========================================

function CurrencyDisplay:UpdateCurrency(currencyName: string, value: number, instant: boolean?)
    currencyName = currencyName:lower()
    local currencyItem = self._currencyItems[currencyName]
    
    if not currencyItem then
        if self._debugMode then
            warn("[CurrencyDisplay] Currency not found:", currencyName)
        end
        return
    end
    
    -- Update target value
    currencyItem.targetValue = value
    
    if instant or not self._options.animateChanges then
        -- Instant update
        currencyItem.value = value
        currencyItem.displayValue = value
        self:UpdateCurrencyLabel(currencyItem)
    else
        -- Animated update - will be handled by update loop
        self:AnimateCurrencyChange(currencyItem)
    end
end

function CurrencyDisplay:AnimateCurrencyChange(currencyItem: CurrencyItem)
    if not currencyItem.label then return end
    
    -- Flash animation
    if currencyItem.animationTween then
        currencyItem.animationTween:Cancel()
    end
    
    -- Determine if increase or decrease
    local isIncrease = currencyItem.targetValue > currencyItem.value
    local flashColor = isIncrease and self._config.COLORS.Success or self._config.COLORS.Error
    
    -- Flash the text color
    currencyItem.animationTween = self._utilities.Tween(currencyItem.label, {
        TextColor3 = flashColor
    }, self._config.TWEEN_INFO.Fast)
    
    -- Return to normal color after delay
    task.delay(ANIMATION_DURATION, function()
        if currencyItem.label and currencyItem.label.Parent then
            self._utilities.Tween(currencyItem.label, {
                TextColor3 = DEFAULT_TEXT_COLOR
            }, self._config.TWEEN_INFO.Normal)
        end
    end)
    
    -- Play sound for significant changes
    if self._soundSystem and math.abs(currencyItem.targetValue - currencyItem.value) > 0 then
        if isIncrease then
            self._soundSystem:PlayUISound("CoinCollect")
        end
    end
    
    -- Add to update queue
    self._updateQueue[currencyItem.name] = true
end

function CurrencyDisplay:UpdateCurrencyLabel(currencyItem: CurrencyItem)
    if not currencyItem.label then return end
    
    local formattedValue = self._options.showAbbreviations and 
        self._utilities.FormatNumber(currencyItem.displayValue) or 
        tostring(math.floor(currencyItem.displayValue))
    
    currencyItem.label.Text = formattedValue
end

-- ========================================
-- UPDATE LOOP
-- ========================================

function CurrencyDisplay:StartUpdateLoop()
    self._valueUpdateConnection = Services.RunService.Heartbeat:Connect(function(deltaTime)
        for currencyName, _ in pairs(self._updateQueue) do
            local currencyItem = self._currencyItems[currencyName]
            if currencyItem then
                self:UpdateCurrencyAnimation(currencyItem, deltaTime)
            end
        end
    end)
end

function CurrencyDisplay:UpdateCurrencyAnimation(currencyItem: CurrencyItem, deltaTime: number)
    -- Check if we've reached the target
    if math.abs(currencyItem.displayValue - currencyItem.targetValue) < 1 then
        currencyItem.displayValue = currencyItem.targetValue
        currencyItem.value = currencyItem.targetValue
        self._updateQueue[currencyItem.name] = nil
    else
        -- Smooth interpolation
        local speed = 5 -- Adjust for faster/slower counting
        local diff = currencyItem.targetValue - currencyItem.displayValue
        currencyItem.displayValue = currencyItem.displayValue + (diff * speed * deltaTime)
    end
    
    -- Update label
    self:UpdateCurrencyLabel(currencyItem)
end

-- ========================================
-- DATA BINDINGS
-- ========================================

function CurrencyDisplay:SetupDataBindings()
    if not self._dataCache then return end
    
    -- Subscribe to currency changes
    for currencyName, currencyItem in pairs(self._currencyItems) do
        self._dataCache:Subscribe("currencies." .. currencyName, function(value)
            self:UpdateCurrency(currencyName, value or 0)
        end)
        
        -- Get initial value - try multiple sources
        local initialValue = self._dataCache:Get("currencies." .. currencyName)
        if not initialValue then
            -- Try getting from playerData
            local playerData = self._dataCache:Get("playerData")
            if playerData and playerData.currencies then
                initialValue = playerData.currencies[currencyName]
            end
        end
        
        -- Set initial value (default to 0 if not found)
        self:UpdateCurrency(currencyName, initialValue or 0, true)
    end
end

-- ========================================
-- EVENT LISTENERS
-- ========================================

function CurrencyDisplay:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Listen for currency updates
    self._eventBus:On("CurrencyUpdated", function(data)
        if data.currency and data.value then
            self:UpdateCurrency(data.currency, data.value)
        end
    end)
    
    -- Listen for batch updates
    self._eventBus:On("CurrenciesUpdated", function(currencies)
        for currencyName, value in pairs(currencies) do
            self:UpdateCurrency(currencyName, value)
        end
    end)
    
    -- Listen for player data loaded
    self._eventBus:On("PlayerDataLoaded", function(playerData)
        if playerData and playerData.currencies then
            for currencyName, value in pairs(playerData.currencies) do
                self:UpdateCurrency(currencyName, value)
            end
        end
    end)
    
    -- Listen for remote currency updates from server
    self._eventBus:On("RemoteCurrencyUpdated", function(currencies)
        if type(currencies) == "table" then
            for currencyName, value in pairs(currencies) do
                self:UpdateCurrency(currencyName, value)
            end
        end
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function CurrencyDisplay:MergeOptions(defaults: table, overrides: table): table
    local merged = {}
    
    for key, value in pairs(defaults) do
        merged[key] = value
    end
    
    for key, value in pairs(overrides) do
        if value ~= nil then
            merged[key] = value
        end
    end
    
    return merged
end

function CurrencyDisplay:AddCurrency(currencyData: {name: string, icon: string})
    if self._currencyItems[currencyData.name:lower()] then
        warn("[CurrencyDisplay] Currency already exists:", currencyData.name)
        return
    end
    
    local order = 0
    for _ in pairs(self._currencyItems) do
        order = order + 1
    end
    
    self:CreateCurrencyItem(currencyData, order + 1)
    
    -- Set up data binding for new currency
    if self._dataCache then
        self._dataCache:Subscribe("currencies." .. currencyData.name:lower(), function(value)
            self:UpdateCurrency(currencyData.name, value or 0)
        end)
    end
end

function CurrencyDisplay:RemoveCurrency(currencyName: string)
    currencyName = currencyName:lower()
    local currencyItem = self._currencyItems[currencyName]
    
    if not currencyItem then return end
    
    -- Clean up
    if currencyItem.animationTween then
        currencyItem.animationTween:Cancel()
    end
    
    if currencyItem.container then
        currencyItem.container:Destroy()
    end
    
    self._currencyItems[currencyName] = nil
    self._updateQueue[currencyName] = nil
end

function CurrencyDisplay:GetCurrencyValue(currencyName: string): number
    currencyName = currencyName:lower()
    local currencyItem = self._currencyItems[currencyName]
    return currencyItem and currencyItem.value or 0
end

function CurrencyDisplay:SetPosition(position: UDim2)
    if self.Frame then
        self._utilities.Tween(self.Frame, {Position = position}, self._config.TWEEN_INFO.Normal)
    end
end

function CurrencyDisplay:SetVisible(visible: boolean)
    if self.Frame then
        self.Frame.Visible = visible
    end
end

-- ========================================
-- BATCH OPERATIONS
-- ========================================

function CurrencyDisplay:UpdateMultipleCurrencies(currencies: {[string]: number}, instant: boolean?)
    for currencyName, value in pairs(currencies) do
        self:UpdateCurrency(currencyName, value, instant)
    end
end

function CurrencyDisplay:ResetAllCurrencies()
    for currencyName, currencyItem in pairs(self._currencyItems) do
        self:UpdateCurrency(currencyName, 0, true)
    end
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function CurrencyDisplay:DebugPrint()
        print("\n=== CurrencyDisplay Debug Info ===")
        print("Currencies:")
        
        for name, item in pairs(self._currencyItems) do
            print("  " .. name .. ":", 
                  "Value =", item.value,
                  "Display =", math.floor(item.displayValue),
                  "Target =", item.targetValue,
                  "Animating =", self._updateQueue[name] and "Yes" or "No")
        end
        
        print("\nOptions:")
        for key, value in pairs(self._options) do
            print("  " .. key .. ":", tostring(value))
        end
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function CurrencyDisplay:Destroy()
    -- Stop update loop
    if self._valueUpdateConnection then
        self._valueUpdateConnection:Disconnect()
        self._valueUpdateConnection = nil
    end
    
    -- Cancel all animations
    for _, currencyItem in pairs(self._currencyItems) do
        if currencyItem.animationTween then
            currencyItem.animationTween:Cancel()
        end
    end
    
    -- Destroy frame
    if self.Frame then
        self.Frame:Destroy()
        self.Frame = nil
    end
    
    -- Clear references
    self._currencyItems = {}
    self._updateQueue = {}
end

return CurrencyDisplay