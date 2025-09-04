--[[
    Module: UIFactory
    Description: Comprehensive UI component factory with consistent theming and interactions
    Provides all basic UI elements with hover states, animations, and proper styling
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local UIFactory = {}
UIFactory.__index = UIFactory

-- ========================================
-- TYPES
-- ========================================

type ComponentOptions = {
    name: string?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
    layoutOrder: number?,
    visible: boolean?,
    zIndex: number?,
    parent: Instance?,
}

type ButtonOptions = ComponentOptions & {
    text: string?,
    textSize: number?,
    textColor: Color3?,
    backgroundColor: Color3?,
    hoverColor: Color3?,
    pressedColor: Color3?,
    font: Enum.Font?,
    cornerRadius: number?,
    strokeColor: Color3?,
    strokeThickness: number?,
    callback: () -> ()?,
    soundEnabled: boolean?,
    animationEnabled: boolean?,
}

type FrameOptions = ComponentOptions & {
    backgroundColor: Color3?,
    backgroundTransparency: number?,
    borderColor: Color3?,
    borderThickness: number?,
    cornerRadius: number?,
    clipDescendants: boolean?,
}

type LabelOptions = ComponentOptions & {
    text: string?,
    textSize: number?,
    textColor: Color3?,
    font: Enum.Font?,
    textXAlignment: Enum.TextXAlignment?,
    textYAlignment: Enum.TextYAlignment?,
    textWrapped: boolean?,
    textScaled: boolean?,
    richText: boolean?,
    backgroundColor: Color3?,
    backgroundTransparency: number?,
}

-- ========================================
-- CONSTANTS
-- ========================================

local DEFAULT_BUTTON_SIZE = UDim2.new(0, 200, 0, 50)
local DEFAULT_FRAME_SIZE = UDim2.new(0.5, 0, 0.5, 0)
local DEFAULT_LABEL_SIZE = UDim2.new(0, 200, 0, 50)
local DEFAULT_CORNER_RADIUS = 8
local DEFAULT_STROKE_THICKNESS = 2
local DEFAULT_PADDING = 8
local HOVER_SCALE = 1.02
local PRESS_SCALE = 0.95

-- ========================================
-- INITIALIZATION
-- ========================================

function UIFactory.new(dependencies)
    local self = setmetatable({}, UIFactory)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    self._soundSystem = dependencies.SoundSystem
    self._animationSystem = dependencies.AnimationSystem
    self._eventBus = dependencies.EventBus
    
    -- Component tracking
    self._components = {}
    self._themes = {}
    self._defaultTheme = "default"
    
    -- Settings
    self._soundEnabled = true
    self._animationsEnabled = true
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Animation cache
    self._activeTweens = {}
    
    self:Initialize()
    
    return self
end

function UIFactory:Initialize()
    -- Create default themes
    self:CreateDefaultThemes()
    
    -- Listen for settings changes
    if self._eventBus then
        self._eventBus:On("SettingsChanged", function(settings)
            if settings.sfxEnabled ~= nil then
                self._soundEnabled = settings.sfxEnabled
            end
        end)
    end
    
    if self._debugMode then
        print("[UIFactory] Initialized with default theme:", self._defaultTheme)
    end
end

-- ========================================
-- BUTTON CREATION
-- ========================================

function UIFactory:CreateButton(parent: Instance, options: ButtonOptions?): TextButton
    options = options or {}
    
    -- Create button
    local button = Instance.new("TextButton")
    button.Name = options.name or "Button"
    button.Size = options.size or DEFAULT_BUTTON_SIZE
    button.Position = options.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    button.BackgroundColor3 = options.backgroundColor or self._config.COLORS.Primary
    button.Text = options.text or "Button"
    button.TextColor3 = options.textColor or self._config.COLORS.White
    button.Font = options.font or self._config.FONTS.Secondary
    button.TextScaled = true
    button.AutoButtonColor = false -- We'll handle hover states manually
    button.BorderSizePixel = 0
    button.LayoutOrder = options.layoutOrder or 0
    button.Visible = options.visible ~= false
    button.ZIndex = options.zIndex or 1
    
    -- Add UI modifiers
    self._utilities.CreateCorner(button, options.cornerRadius or DEFAULT_CORNER_RADIUS)
    self._utilities.CreateStroke(button, options.strokeColor or self._config.COLORS.Dark, 
        options.strokeThickness or DEFAULT_STROKE_THICKNESS, 0.8)
    self._utilities.CreatePadding(button, DEFAULT_PADDING)
    
    -- Store original properties for animations
    button:SetAttribute("OriginalColor", button.BackgroundColor3)
    button:SetAttribute("OriginalSize", button.Size)
    button:SetAttribute("HoverColor", options.hoverColor or self._config.COLORS.Secondary)
    button:SetAttribute("PressedColor", options.pressedColor or self._utilities.DarkenColor(button.BackgroundColor3, 0.2))
    
    -- Add text size constraint for better scaling
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = options.textSize or 24
    textConstraint.MinTextSize = 12
    textConstraint.Parent = button
    
    -- Setup interactions
    self:SetupButtonInteractions(button, options)
    
    -- Parent last to avoid property changed events during setup
    button.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(button, "Button")
    
    return button
end

function UIFactory:SetupButtonInteractions(button: TextButton, options: ButtonOptions)
    local isHovering = false
    local isPressed = false
    local currentTween = nil
    
    -- Helper function to update button state
    local function updateButtonState()
        if currentTween then
            currentTween:Cancel()
        end
        
        local targetColor
        local targetSize = button:GetAttribute("OriginalSize")
        
        if isPressed then
            targetColor = button:GetAttribute("PressedColor")
            targetSize = UDim2.new(
                targetSize.X.Scale * PRESS_SCALE,
                targetSize.X.Offset * PRESS_SCALE,
                targetSize.Y.Scale * PRESS_SCALE,
                targetSize.Y.Offset * PRESS_SCALE
            )
        elseif isHovering then
            targetColor = button:GetAttribute("HoverColor")
            targetSize = UDim2.new(
                targetSize.X.Scale * HOVER_SCALE,
                targetSize.X.Offset * HOVER_SCALE,
                targetSize.Y.Scale * HOVER_SCALE,
                targetSize.Y.Offset * HOVER_SCALE
            )
        else
            targetColor = button:GetAttribute("OriginalColor")
        end
        
        if options.animationEnabled ~= false and self._animationsEnabled then
            currentTween = self._utilities.Tween(button, {
                BackgroundColor3 = targetColor,
                Size = targetSize
            }, self._config.TWEEN_INFO.Fast)
        else
            button.BackgroundColor3 = targetColor
            button.Size = targetSize
        end
    end
    
    -- Mouse events
    button.MouseEnter:Connect(function()
        isHovering = true
        updateButtonState()
        
        -- Change cursor if it's an ImageButton
        if button:IsA("ImageButton") then
            button.MouseIcon = "rbxasset://SystemCursors/PointingHand"
        end
    end)
    
    button.MouseLeave:Connect(function()
        isHovering = false
        isPressed = false
        updateButtonState()
        
        -- Reset cursor if it's an ImageButton
        if button:IsA("ImageButton") then
            button.MouseIcon = ""
        end
    end)
    
    button.MouseButton1Down:Connect(function()
        isPressed = true
        updateButtonState()
    end)
    
    button.MouseButton1Up:Connect(function()
        isPressed = false
        updateButtonState()
    end)
    
    -- Click handler
    button.MouseButton1Click:Connect(function()
        -- Play sound
        if options.soundEnabled ~= false and self._soundEnabled and self._soundSystem then
            self._soundSystem:PlayUISound("Click")
        end
        
        -- Click animation
        if options.animationEnabled ~= false and self._animationsEnabled then
            self:PlayClickAnimation(button)
        end
        
        -- Fire callback
        if options.callback then
            task.spawn(options.callback)
        end
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("UIButtonClicked", {
                button = button,
                name = button.Name,
            })
        end
    end)
end

function UIFactory:PlayClickAnimation(button: TextButton)
    local corner = button:FindFirstChildOfClass("UICorner")
    local originalCornerRadius = corner and corner.CornerRadius or UDim.new(0, DEFAULT_CORNER_RADIUS)
    
    -- Quick scale pulse
    local originalSize = button.Size
    local originalPosition = button.Position
    
    -- Squish effect
    Services.TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.new(
            originalSize.X.Scale * 0.95,
            originalSize.X.Offset * 0.95,
            originalSize.Y.Scale * 0.95,
            originalSize.Y.Offset * 0.95
        ),
        Position = UDim2.new(
            originalPosition.X.Scale,
            originalPosition.X.Offset,
            originalPosition.Y.Scale,
            originalPosition.Y.Offset + 2
        )
    }):Play()
    
    if corner then
        Services.TweenService:Create(corner, TweenInfo.new(0.1), {
            CornerRadius = UDim.new(0, originalCornerRadius.Offset * 1.5)
        }):Play()
    end
    
    -- Bounce back
    task.wait(0.1)
    
    Services.TweenService:Create(button, self._config.TWEEN_INFO.Bounce, {
        Size = originalSize,
        Position = originalPosition
    }):Play()
    
    if corner then
        Services.TweenService:Create(corner, self._config.TWEEN_INFO.Bounce, {
            CornerRadius = originalCornerRadius
        }):Play()
    end
end

-- ========================================
-- FRAME CREATION
-- ========================================

function UIFactory:CreateFrame(parent: Instance, options: FrameOptions?): Frame
    options = options or {}
    
    local frame = Instance.new("Frame")
    frame.Name = options.name or "Frame"
    frame.Size = options.size or DEFAULT_FRAME_SIZE
    frame.Position = options.position or UDim2.new(0.25, 0, 0.25, 0)
    frame.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    frame.BackgroundColor3 = options.backgroundColor or self._config.COLORS.Background
    frame.BackgroundTransparency = options.backgroundTransparency or 0
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = options.clipDescendants ~= false
    frame.LayoutOrder = options.layoutOrder or 0
    frame.Visible = options.visible ~= false
    frame.ZIndex = options.zIndex or 1
    
    -- Add UI modifiers
    if options.cornerRadius then
        self._utilities.CreateCorner(frame, options.cornerRadius)
    else
        self._utilities.CreateCorner(frame, 12) -- Default corner radius for frames
    end
    
    if options.borderColor and options.borderThickness then
        self._utilities.CreateStroke(frame, options.borderColor, options.borderThickness)
    end
    
    frame.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(frame, "Frame")
    
    return frame
end

-- ========================================
-- LABEL CREATION
-- ========================================

function UIFactory:CreateLabel(parent: Instance, options: LabelOptions?): TextLabel
    options = options or {}
    
    local label = Instance.new("TextLabel")
    label.Name = options.name or "Label"
    label.Size = options.size or DEFAULT_LABEL_SIZE
    label.Position = options.position or UDim2.new(0, 0, 0, 0)
    label.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    label.BackgroundTransparency = options.backgroundTransparency or 1
    label.BackgroundColor3 = options.backgroundColor or self._config.COLORS.Background
    label.Text = options.text or "Label"
    label.TextColor3 = options.textColor or self._config.COLORS.Text
    label.Font = options.font or self._config.FONTS.Primary
    label.TextScaled = options.textScaled ~= false
    label.TextWrapped = options.textWrapped ~= false
    label.TextXAlignment = options.textXAlignment or Enum.TextXAlignment.Center
    label.TextYAlignment = options.textYAlignment or Enum.TextYAlignment.Center
    label.RichText = options.richText or false
    label.BorderSizePixel = 0
    label.LayoutOrder = options.layoutOrder or 0
    label.Visible = options.visible ~= false
    label.ZIndex = options.zIndex or 1
    
    -- Add text size constraint if scaled
    if label.TextScaled then
        local textConstraint = Instance.new("UITextSizeConstraint")
        textConstraint.MaxTextSize = options.textSize or 18
        textConstraint.MinTextSize = 10
        textConstraint.Parent = label
    else
        label.TextSize = options.textSize or 18
    end
    
    label.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(label, "Label")
    
    return label
end

-- ========================================
-- IMAGE LABEL CREATION
-- ========================================

function UIFactory:CreateImageLabel(parent: Instance, imageId: string, options: ComponentOptions?): ImageLabel
    options = options or {}
    
    local image = Instance.new("ImageLabel")
    image.Name = options.name or "Image"
    image.Size = options.size or UDim2.new(0, 100, 0, 100)
    image.Position = options.position or UDim2.new(0, 0, 0, 0)
    image.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    image.BackgroundTransparency = 1
    image.Image = imageId or ""
    image.ScaleType = Enum.ScaleType.Fit
    image.BorderSizePixel = 0
    image.LayoutOrder = options.layoutOrder or 0
    image.Visible = options.visible ~= false
    image.ZIndex = options.zIndex or 1
    
    image.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(image, "ImageLabel")
    
    return image
end

-- ========================================
-- TEXTBOX CREATION
-- ========================================

function UIFactory:CreateTextBox(parent: Instance, placeholderText: string?, options: ComponentOptions?): TextBox
    options = options or {}
    
    local textBox = Instance.new("TextBox")
    textBox.Name = options.name or "TextBox"
    textBox.Size = options.size or UDim2.new(0, 200, 0, 40)
    textBox.Position = options.position or UDim2.new(0, 0, 0, 0)
    textBox.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    textBox.BackgroundColor3 = self._config.COLORS.White
    textBox.PlaceholderText = placeholderText or "Enter text..."
    textBox.PlaceholderColor3 = self._config.COLORS.TextSecondary
    textBox.Text = ""
    textBox.TextColor3 = self._config.COLORS.Text
    textBox.Font = self._config.FONTS.Primary
    textBox.TextScaled = true
    textBox.ClearTextOnFocus = false
    textBox.BorderSizePixel = 0
    textBox.LayoutOrder = options.layoutOrder or 0
    textBox.Visible = options.visible ~= false
    textBox.ZIndex = options.zIndex or 1
    
    -- Add UI modifiers
    self._utilities.CreateCorner(textBox, DEFAULT_CORNER_RADIUS)
    local stroke = self._utilities.CreateStroke(textBox, self._config.COLORS.Primary, 2)
    self._utilities.CreatePadding(textBox, DEFAULT_PADDING)
    
    -- Add text size constraint
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 18
    textConstraint.MinTextSize = 12
    textConstraint.Parent = textBox
    
    -- Focus effects
    textBox.Focused:Connect(function()
        self._utilities.Tween(stroke, {
            Color = self._config.COLORS.Secondary,
            Thickness = 3
        }, self._config.TWEEN_INFO.Fast)
        
        -- Play sound
        if self._soundEnabled and self._soundSystem then
            self._soundSystem:PlayUISound("Click")
        end
    end)
    
    textBox.FocusLost:Connect(function()
        self._utilities.Tween(stroke, {
            Color = self._config.COLORS.Primary,
            Thickness = 2
        }, self._config.TWEEN_INFO.Fast)
    end)
    
    -- Text changed event
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self._eventBus then
            self._eventBus:Fire("UITextBoxChanged", {
                textBox = textBox,
                text = textBox.Text,
            })
        end
    end)
    
    textBox.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(textBox, "TextBox")
    
    return textBox
end

-- ========================================
-- SCROLLING FRAME CREATION
-- ========================================

function UIFactory:CreateScrollingFrame(parent: Instance, options: ComponentOptions?): ScrollingFrame
    options = options or {}
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = options.name or "ScrollingFrame"
    scrollFrame.Size = options.size or UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = options.position or UDim2.new(0, 10, 0, 10)
    scrollFrame.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = self._config.COLORS.Primary
    scrollFrame.ScrollBarImageTransparency = 0.2
    scrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- Will be set by content
    scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    scrollFrame.LayoutOrder = options.layoutOrder or 0
    scrollFrame.Visible = options.visible ~= false
    scrollFrame.ZIndex = options.zIndex or 1
    
    -- Auto-resize canvas based on content
    local function updateCanvasSize()
        local layout = scrollFrame:FindFirstChildOfClass("UIListLayout") or 
                       scrollFrame:FindFirstChildOfClass("UIGridLayout")
        
        if layout then
            if layout:IsA("UIListLayout") then
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
            elseif layout:IsA("UIGridLayout") then
                scrollFrame.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X, 0, layout.AbsoluteContentSize.Y + 20)
            end
        end
    end
    
    -- Connect to layout changes
    scrollFrame.ChildAdded:Connect(function(child)
        if child:IsA("UIListLayout") or child:IsA("UIGridLayout") then
            child:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
            updateCanvasSize()
        end
    end)
    
    scrollFrame.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(scrollFrame, "ScrollingFrame")
    
    return scrollFrame
end

-- ========================================
-- PROGRESS BAR CREATION
-- ========================================

function UIFactory:CreateProgressBar(parent: Instance, value: number?, maxValue: number?, options: ComponentOptions?): Frame
    options = options or {}
    value = value or 0
    maxValue = maxValue or 100
    
    if maxValue == 0 then maxValue = 1 end -- Prevent division by zero
    
    -- Container
    local container = Instance.new("Frame")
    container.Name = options.name or "ProgressBar"
    container.Size = options.size or UDim2.new(0, 200, 0, 20)
    container.Position = options.position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    container.BackgroundColor3 = self._config.COLORS.Surface
    container.BorderSizePixel = 0
    container.LayoutOrder = options.layoutOrder or 0
    container.Visible = options.visible ~= false
    container.ZIndex = options.zIndex or 1
    
    self._utilities.CreateCorner(container, 10)
    self._utilities.CreateStroke(container, self._config.COLORS.Primary, 1, 0.5)
    
    -- Fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(math.clamp(value / maxValue, 0, 1), 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = self._config.COLORS.Success
    fill.BorderSizePixel = 0
    fill.ZIndex = container.ZIndex + 1
    fill.Parent = container
    
    self._utilities.CreateCorner(fill, 10)
    
    -- Gradient for depth
    self._utilities.CreateGradient(fill, {
        self._config.COLORS.Success,
        self._utilities.DarkenColor(self._config.COLORS.Success, 0.2)
    }, 90)
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.Position = UDim2.new(0, 0, 0, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = string.format("%d%%", math.floor((value / maxValue) * 100))
    progressText.TextColor3 = self._config.COLORS.Text
    progressText.Font = self._config.FONTS.Secondary
    progressText.TextScaled = true
    progressText.ZIndex = container.ZIndex + 2
    progressText.Parent = container
    
    -- Methods
    container:SetAttribute("Value", value)
    container:SetAttribute("MaxValue", maxValue)
    
    local function updateProgress(newValue: number, animate: boolean?)
        newValue = math.clamp(newValue or 0, 0, maxValue)
        container:SetAttribute("Value", newValue)
        
        local percentage = newValue / maxValue
        local targetSize = UDim2.new(percentage, 0, 1, 0)
        
        if animate ~= false and self._animationsEnabled then
            self._utilities.Tween(fill, {Size = targetSize}, self._config.TWEEN_INFO.Normal)
        else
            fill.Size = targetSize
        end
        
        progressText.Text = string.format("%d%%", math.floor(percentage * 100))
    end
    
    -- Public method to update progress
    container.SetValue = updateProgress
    
    container.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(container, "ProgressBar")
    
    return container
end

-- ========================================
-- DROPDOWN CREATION
-- ========================================

function UIFactory:CreateDropdown(parent: Instance, items: {string}, defaultItem: string?, options: ComponentOptions?): Frame
    options = options or {}
    items = items or {} -- Ensure items is never nil
    
    local container = Instance.new("Frame")
    container.Name = options.name or "Dropdown"
    container.Size = options.size or UDim2.new(0, 200, 0, 40)
    container.Position = options.position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    container.BackgroundColor3 = self._config.COLORS.Surface
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.LayoutOrder = options.layoutOrder or 0
    container.Visible = options.visible ~= false
    container.ZIndex = options.zIndex or self._config.ZINDEX.Dropdown
    
    self._utilities.CreateCorner(container, DEFAULT_CORNER_RADIUS)
    self._utilities.CreateStroke(container, self._config.COLORS.Primary, 2)
    
    -- Selected item display
    local selectedLabel = self:CreateLabel(container, {
        text = defaultItem or (items and items[1]) or "Select...",
        size = UDim2.new(1, -40, 1, 0),
        position = UDim2.new(0, 10, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        backgroundColor = self._config.COLORS.Surface,
        backgroundTransparency = 0,
    })
    
    -- Dropdown arrow
    local arrow = self:CreateLabel(container, {
        text = "▼",
        size = UDim2.new(0, 30, 1, 0),
        position = UDim2.new(1, -35, 0, 0),
        textColor = self._config.COLORS.Primary,
    })
    
    -- Dropdown list (initially hidden)
    local listContainer = Instance.new("Frame")
    listContainer.Name = "DropdownList"
    listContainer.Size = UDim2.new(1, 0, 0, math.min(#items * 35, 200))
    listContainer.Position = UDim2.new(0, 0, 1, 5)
    listContainer.BackgroundColor3 = self._config.COLORS.Surface
    listContainer.BorderSizePixel = 0
    listContainer.Visible = false
    listContainer.ZIndex = container.ZIndex + 100
    listContainer.Parent = container
    
    self._utilities.CreateCorner(listContainer, DEFAULT_CORNER_RADIUS)
    self._utilities.CreateStroke(listContainer, self._config.COLORS.Primary, 2)
    
    -- Scrolling frame for items
    local scrollFrame = self:CreateScrollingFrame(listContainer, {
        size = UDim2.new(1, -4, 1, -4),
        position = UDim2.new(0, 2, 0, 2),
    })
    scrollFrame.ZIndex = listContainer.ZIndex + 1
    
    -- List layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = scrollFrame
    
    -- Selected value
    local selectedValue = defaultItem or items[1]
    
    -- Create item buttons
    for i, item in ipairs(items) do
        local itemButton = self:CreateButton(scrollFrame, {
            text = item,
            size = UDim2.new(1, -4, 0, 35),
            backgroundColor = self._config.COLORS.Surface,
            hoverColor = self._config.COLORS.Primary,
            textColor = self._config.COLORS.Text,
            strokeThickness = 0,
            cornerRadius = 4,
            layoutOrder = i,
            callback = function()
                selectedValue = item
                selectedLabel.Text = item
                listContainer.Visible = false
                arrow.Text = "▼"
                
                -- Fire event
                if self._eventBus then
                    self._eventBus:Fire("UIDropdownChanged", {
                        dropdown = container,
                        value = item,
                        index = i,
                    })
                end
            end,
        })
        itemButton.ZIndex = scrollFrame.ZIndex + 1
    end
    
    -- Toggle dropdown
    local isOpen = false
    
    local toggleButton = self:CreateButton(container, {
        text = "",
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = self._config.COLORS.Surface,
        backgroundTransparency = 1,
        strokeThickness = 0,
        callback = function()
            isOpen = not isOpen
            listContainer.Visible = isOpen
            arrow.Text = isOpen and "▲" or "▼"
            
            if isOpen then
                -- Animate open
                listContainer.Size = UDim2.new(1, 0, 0, 0)
                self._utilities.Tween(listContainer, {
                    Size = UDim2.new(1, 0, 0, math.min(#items * 35, 200))
                }, self._config.TWEEN_INFO.Fast)
            end
        end,
    })
    toggleButton.ZIndex = container.ZIndex + 1
    
    -- Store dropdown data in a table instead of on the instance
    if not self.DropdownData then
        self.DropdownData = {}
    end
    
    local dropdownMethods = {
        GetValue = function()
            return selectedValue
        end,
        SetValue = function(value: string)
            if table.find(items, value) then
                selectedValue = value
                selectedLabel.Text = value
            end
        end
    }
    
    -- Store methods in the data table
    self.DropdownData[container] = dropdownMethods
    
    -- Add a helper to identify dropdowns
    container:SetAttribute("IsUIFactoryDropdown", true)
    
    container.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(container, "Dropdown")
    
    return container
end

-- ========================================
-- SLIDER CREATION
-- ========================================

function UIFactory:CreateSlider(parent: Instance, min: number|table, max: number?, defaultValue: number?, options: ComponentOptions?): Frame
    -- Handle both old style (separate params) and new style (options table)
    if type(min) == "table" then
        options = min
        min = options.min or 0
        max = options.max or 100
        defaultValue = options.value or options.defaultValue or min
    else
        options = options or {}
        -- Ensure numeric values
        min = tonumber(min) or 0
        max = tonumber(max) or 100
        defaultValue = tonumber(defaultValue) or min
    end
    
    local container = Instance.new("Frame")
    container.Name = options.name or "Slider"
    container.Size = options.size or UDim2.new(0, 200, 0, 40)
    container.Position = options.position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.LayoutOrder = options.layoutOrder or 0
    container.Visible = options.visible ~= false
    container.ZIndex = options.zIndex or 1
    
    -- Track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0.5, -3)
    track.BackgroundColor3 = self._config.COLORS.Surface
    track.BorderSizePixel = 0
    track.Parent = container
    
    self._utilities.CreateCorner(track, 3)
    
    -- Fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = self._config.COLORS.Primary
    fill.BorderSizePixel = 0
    fill.ZIndex = track.ZIndex + 1
    fill.Parent = track
    
    self._utilities.CreateCorner(fill, 3)
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((defaultValue - min) / (max - min), -10, 0.5, -10)
    knob.BackgroundColor3 = self._config.COLORS.White
    knob.BorderSizePixel = 0
    knob.ZIndex = track.ZIndex + 2
    knob.Parent = track
    
    self._utilities.CreateCorner(knob, 10)
    self._utilities.CreateStroke(knob, self._config.COLORS.Primary, 2)
    
    -- Value display
    local valueLabel = self:CreateLabel(container, {
        text = tostring(math.floor(defaultValue)),
        size = UDim2.new(0, 50, 1, 0),
        position = UDim2.new(1, -50, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
    })
    
    -- Slider functionality
    local currentValue = defaultValue
    local dragging = false
    
    local function updateSlider(inputPosition: Vector3)
        local trackStart = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        local relativeX = math.clamp((inputPosition.X - trackStart) / trackWidth, 0, 1)
        
        currentValue = min + (max - min) * relativeX
        
        -- Update visuals
        knob.Position = UDim2.new(relativeX, -10, 0.5, -10)
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        valueLabel.Text = tostring(math.floor(currentValue))
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("UISliderChanged", {
                slider = container,
                value = currentValue,
            })
        end
        
        -- Call callback if provided
        if options.callback then
            options.callback(currentValue)
        end
    end
    
    -- Input handling
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            
            -- Scale up knob
            self._utilities.Tween(knob, {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(knob.Position.X.Scale, -12, 0.5, -12)
            }, self._config.TWEEN_INFO.Fast)
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position)
        end
    end)
    
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            
            -- Scale down knob
            self._utilities.Tween(knob, {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(knob.Position.X.Scale, -10, 0.5, -10)
            }, self._config.TWEEN_INFO.Fast)
        end
    end)
    
    -- Click on track to set value
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input.Position)
        end
    end)
    
    -- Store slider data in a table instead of on the instance
    if not self.SliderData then
        self.SliderData = {}
    end
    
    local sliderMethods = {
        GetValue = function()
            return currentValue
        end,
        SetValue = function(value: number)
            value = math.clamp(value, min, max)
            currentValue = value
            
            local relativeX = (value - min) / (max - min)
            knob.Position = UDim2.new(relativeX, -10, 0.5, -10)
            fill.Size = UDim2.new(relativeX, 0, 1, 0)
            valueLabel.Text = tostring(math.floor(value))
        end
    }
    
    -- Store methods in the data table
    self.SliderData[container] = sliderMethods
    
    -- Add a helper to get methods
    container:SetAttribute("IsUIFactorySlider", true)
    
    container.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(container, "Slider")
    
    return container
end

-- Helper methods for sliders
function UIFactory:GetSliderValue(slider: Frame): number?
    if self.SliderData and self.SliderData[slider] then
        return self.SliderData[slider].GetValue()
    end
    return nil
end

function UIFactory:SetSliderValue(slider: Frame, value: number)
    if self.SliderData and self.SliderData[slider] then
        self.SliderData[slider].SetValue(value)
    end
end

-- Helper methods for dropdowns
function UIFactory:GetDropdownValue(dropdown: Frame): string?
    if self.DropdownData and self.DropdownData[dropdown] then
        return self.DropdownData[dropdown].GetValue()
    end
    return nil
end

function UIFactory:SetDropdownValue(dropdown: Frame, value: string)
    if self.DropdownData and self.DropdownData[dropdown] then
        self.DropdownData[dropdown].SetValue(value)
    end
end

-- Toggle helper methods
function UIFactory:GetToggleValue(toggle: Frame): boolean?
    if self.ToggleData and self.ToggleData[toggle] then
        return self.ToggleData[toggle].GetValue()
    end
    return nil
end

function UIFactory:SetToggleValue(toggle: Frame, value: boolean)
    if self.ToggleData and self.ToggleData[toggle] then
        self.ToggleData[toggle].SetValue(value)
    end
end

-- ========================================
-- CHECKBOX CREATION
-- ========================================

function UIFactory:CreateCheckbox(parent: Instance, checked: boolean?, options: ComponentOptions?): Frame
    options = options or {}
    checked = checked or false
    
    local container = Instance.new("Frame")
    container.Name = options.name or "Checkbox"
    container.Size = options.size or UDim2.new(0, 30, 0, 30)
    container.Position = options.position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.LayoutOrder = options.layoutOrder or 0
    container.Visible = options.visible ~= false
    container.ZIndex = options.zIndex or 1
    
    -- Checkbox box
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.Size = UDim2.new(1, 0, 1, 0)
    box.Position = UDim2.new(0, 0, 0, 0)
    box.BackgroundColor3 = self._config.COLORS.Surface
    box.BorderSizePixel = 0
    box.Parent = container
    
    self._utilities.CreateCorner(box, 6)
    self._utilities.CreateStroke(box, self._config.COLORS.Primary, 2)
    
    -- Check mark
    local checkMark = self:CreateLabel(box, {
        text = "✓",
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.Success,
        font = self._config.FONTS.Display,
        visible = checked,
    })
    
    -- Click handler
    local button = self:CreateButton(container, {
        text = "",
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = self._config.COLORS.Surface,
        backgroundTransparency = 1,
        strokeThickness = 0,
        callback = function()
            checked = not checked
            checkMark.Visible = checked
            
            -- Animate
            if checked then
                checkMark.Size = UDim2.new(0, 0, 0, 0)
                checkMark.Visible = true
                self._utilities.Tween(checkMark, {
                    Size = UDim2.new(1, 0, 1, 0)
                }, self._config.TWEEN_INFO.Bounce)
            end
            
            -- Fire event
            if self._eventBus then
                self._eventBus:Fire("UICheckboxChanged", {
                    checkbox = container,
                    checked = checked,
                })
            end
        end,
    })
    
    -- Public methods
    container.IsChecked = function()
        return checked
    end
    
    container.SetChecked = function(value: boolean)
        checked = value
        checkMark.Visible = checked
    end
    
    container.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(container, "Checkbox")
    
    return container
end

-- ========================================
-- TOGGLE SWITCH CREATION
-- ========================================

function UIFactory:CreateToggle(parent: Instance, enabled: boolean?, options: ComponentOptions?): Frame
    options = options or {}
    enabled = enabled or false
    
    local container = Instance.new("Frame")
    container.Name = options.name or "Toggle"
    container.Size = options.size or UDim2.new(0, 60, 0, 30)
    container.Position = options.position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.LayoutOrder = options.layoutOrder or 0
    container.Visible = options.visible ~= false
    container.ZIndex = options.zIndex or 1
    
    -- Track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 1, 0)
    track.Position = UDim2.new(0, 0, 0, 0)
    track.BackgroundColor3 = enabled and self._config.COLORS.Success or self._config.COLORS.Surface
    track.BorderSizePixel = 0
    track.Parent = container
    
    self._utilities.CreateCorner(track, 15)
    self._utilities.CreateStroke(track, self._config.COLORS.Primary, 2)
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 26, 0, 26)
    knob.Position = enabled and UDim2.new(1, -28, 0, 2) or UDim2.new(0, 2, 0, 2)
    knob.BackgroundColor3 = self._config.COLORS.White
    knob.BorderSizePixel = 0
    knob.ZIndex = track.ZIndex + 1
    knob.Parent = track
    
    self._utilities.CreateCorner(knob, 13)
    
    -- Click handler
    local button = self:CreateButton(container, {
        text = "",
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = track.BackgroundColor3,
        backgroundTransparency = 1,
        strokeThickness = 0,
        callback = function()
            enabled = not enabled
            
            -- Animate toggle
            local targetKnobPos = enabled and UDim2.new(1, -28, 0, 2) or UDim2.new(0, 2, 0, 2)
            local targetTrackColor = enabled and self._config.COLORS.Success or self._config.COLORS.Surface
            
            self._utilities.Tween(knob, {Position = targetKnobPos}, self._config.TWEEN_INFO.Normal)
            self._utilities.Tween(track, {BackgroundColor3 = targetTrackColor}, self._config.TWEEN_INFO.Normal)
            
            -- Fire event
            if self._eventBus then
                self._eventBus:Fire("UIToggleChanged", {
                    toggle = container,
                    enabled = enabled,
                })
            end
        end,
    })
    
    -- Public methods
    container.IsEnabled = function()
        return enabled
    end
    
    container.SetEnabled = function(value: boolean)
        enabled = value
        knob.Position = enabled and UDim2.new(1, -28, 0, 2) or UDim2.new(0, 2, 0, 2)
        track.BackgroundColor3 = enabled and self._config.COLORS.Success or self._config.COLORS.Surface
    end
    
    container.Parent = parent or options.parent
    
    -- Track component
    self:TrackComponent(container, "Toggle")
    
    return container
end

-- ========================================
-- THEME MANAGEMENT
-- ========================================

function UIFactory:CreateDefaultThemes()
    self._themes.default = {
        primary = self._config.COLORS.Primary,
        secondary = self._config.COLORS.Secondary,
        background = self._config.COLORS.Background,
        surface = self._config.COLORS.Surface,
        text = self._config.COLORS.Text,
        success = self._config.COLORS.Success,
        error = self._config.COLORS.Error,
    }
    
    self._themes.dark = {
        primary = Color3.fromRGB(100, 50, 150),
        secondary = Color3.fromRGB(150, 100, 200),
        background = Color3.fromRGB(30, 30, 30),
        surface = Color3.fromRGB(50, 50, 50),
        text = Color3.fromRGB(240, 240, 240),
        success = Color3.fromRGB(50, 200, 50),
        error = Color3.fromRGB(200, 50, 50),
    }
    
    self._themes.ocean = {
        primary = Color3.fromRGB(50, 150, 255),
        secondary = Color3.fromRGB(100, 200, 255),
        background = Color3.fromRGB(220, 240, 255),
        surface = Color3.fromRGB(240, 250, 255),
        text = Color3.fromRGB(20, 50, 80),
        success = Color3.fromRGB(50, 255, 150),
        error = Color3.fromRGB(255, 100, 100),
    }
end

function UIFactory:SetTheme(themeName: string)
    local theme = self._themes[themeName]
    if not theme then
        warn("[UIFactory] Unknown theme:", themeName)
        return
    end
    
    self._defaultTheme = themeName
    
    -- Would update all existing components here
    if self._eventBus then
        self._eventBus:Fire("UIThemeChanged", themeName)
    end
end

-- ========================================
-- COMPONENT TRACKING
-- ========================================

function UIFactory:TrackComponent(component: Instance, componentType: string)
    table.insert(self._components, {
        instance = component,
        type = componentType,
        createdAt = tick(),
    })
    
    -- Clean up destroyed components periodically
    if #self._components > 1000 then
        self:CleanupComponents()
    end
end

function UIFactory:CleanupComponents()
    local activeComponents = {}
    
    for _, data in ipairs(self._components) do
        if data.instance and data.instance.Parent then
            table.insert(activeComponents, data)
        end
    end
    
    self._components = activeComponents
end

function UIFactory:GetComponentStats(): table
    local stats = {}
    
    for _, data in ipairs(self._components) do
        stats[data.type] = (stats[data.type] or 0) + 1
    end
    
    return {
        total = #self._components,
        byType = stats,
    }
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function UIFactory:DebugPrint()
        print("\n=== UIFactory Debug Info ===")
        
        local stats = self:GetComponentStats()
        print("Total Components:", stats.total)
        
        print("\nComponents by Type:")
        for componentType, count in pairs(stats.byType) do
            print("  " .. componentType .. ":", count)
        end
        
        print("\nThemes:", table.concat(self._utilities:GetTableKeys(self._themes), ", "))
        print("Current Theme:", self._defaultTheme)
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function UIFactory:Destroy()
    -- Cancel all active tweens
    for _, tween in pairs(self._activeTweens) do
        if tween.PlaybackState ~= Enum.PlaybackState.Completed then
            tween:Cancel()
        end
    end
    
    -- Clear component tracking
    self._components = {}
end

-- ========================================
-- MISSING METHODS
-- ========================================

-- CreateToggleSwitch method
function UIFactory:CreateToggleSwitch(parent: Instance, options: table?): Frame
    options = options or {}
    
    -- Container
    local container = Instance.new("Frame")
    container.Name = options.name or "ToggleSwitch"
    container.Size = options.size or UDim2.new(0, 50, 0, 25)
    container.Position = options.position or UDim2.new(0, 0, 0, 0)
    local isOn = options.isOn or options.value or false
    
    container.BackgroundColor3 = isOn and self._config.COLORS.Success or self._config.COLORS.ButtonDisabled
    container.BorderSizePixel = 0
    container.Parent = parent
    
    self._utilities.CreateCorner(container, 12)
    
    -- Toggle circle
    local toggle = Instance.new("Frame")
    toggle.Name = "Toggle"
    toggle.Size = UDim2.new(0, 20, 0, 20)
    toggle.Position = isOn and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    toggle.BackgroundColor3 = self._config.COLORS.White
    toggle.BorderSizePixel = 0
    toggle.Parent = container
    
    self._utilities.CreateCorner(toggle, 10)
    
    -- Button
    local button = Instance.new("TextButton")
    button.Text = ""
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        -- Animate
        local targetPos = isOn and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        local targetColor = isOn and self._config.COLORS.Success or self._config.COLORS.ButtonDisabled
        
        self._utilities.Tween(toggle, {Position = targetPos}, TweenInfo.new(0.2))
        self._utilities.Tween(container, {BackgroundColor3 = targetColor}, TweenInfo.new(0.2))
        
        if options.callback then
            options.callback(isOn)
        end
    end)
    
    -- Initialize toggle data table if not exists
    if not self.ToggleData then
        self.ToggleData = {}
    end
    
    -- Store methods in table instead of directly on frame
    self.ToggleData[container] = {
        GetValue = function()
            return isOn
        end,
        SetValue = function(value)
            isOn = value
            toggle.Position = isOn and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
            container.BackgroundColor3 = isOn and self._config.COLORS.Success or self._config.COLORS.ButtonDisabled
        end
    }
    
    return container
end

return UIFactory