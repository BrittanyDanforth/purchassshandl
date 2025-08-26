-- ========================================
-- LOCATION: ReplicatedStorage > Modules > Client > WindowManager (ModuleScript)
-- ========================================
-- WINDOW MANAGER MODULE
-- Professional modal/popup management system
-- Ensures consistent UI across all windows
-- Fixes: All windows now have close buttons, proper animations
-- ========================================

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local WindowManager = {}
WindowManager.__index = WindowManager

-- Requires Janitor module
local Janitor = require(script.Parent.Parent.Shared.Janitor)

-- ========================================
-- CONFIGURATION
-- ========================================
local CONFIG = {
    -- Animation settings
    OPEN_TIME = 0.3,
    CLOSE_TIME = 0.2,
    BACKGROUND_TRANSPARENCY = 0.3,
    BLUR_SIZE = 24,
    
    -- Window settings
    DEFAULT_SIZE = UDim2.new(0.8, 0, 0.8, 0),
    MIN_SIZE = UDim2.new(0.3, 0, 0.3, 0),
    MAX_SIZE = UDim2.new(0.95, 0, 0.95, 0),
    
    -- Z-index management
    BASE_ZINDEX = 100,
    WINDOW_ZINDEX_INCREMENT = 10,
    
    -- Effects
    ENABLE_BLUR = true,
    ENABLE_DARKENING = true,
    ENABLE_ANIMATIONS = true,
    
    -- Sounds
    OPEN_SOUND = "rbxassetid://9113651501",
    CLOSE_SOUND = "rbxassetid://9113651440"
}

-- ========================================
-- CONSTRUCTOR
-- ========================================
function WindowManager.new(playerGui)
    local self = setmetatable({}, WindowManager)
    
    self.PlayerGui = playerGui
    self.Windows = {}
    self.WindowStack = {}
    self.CurrentZIndex = CONFIG.BASE_ZINDEX
    self.BlurEffect = nil
    self.DarkFrame = nil
    self.WindowTemplate = nil
    
    -- Initialize
    self:_setupEffects()
    self:_loadTemplate()
    
    return self
end

-- ========================================
-- WINDOW TEMPLATE SETUP
-- ========================================
function WindowManager:_loadTemplate()
    -- Create a default template if none exists
    local template = Instance.new("Frame")
    template.Name = "WindowTemplate"
    template.Size = CONFIG.DEFAULT_SIZE
    template.Position = UDim2.new(0.5, 0, 0.5, 0)
    template.AnchorPoint = Vector2.new(0.5, 0.5)
    template.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    template.BorderSizePixel = 0
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = template
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    header.BorderSizePixel = 0
    header.Parent = template
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Fix bottom corners
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Window"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0.5, -20)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -70)
    content.Position = UDim2.new(0, 10, 0, 60)
    content.BackgroundTransparency = 1
    content.Parent = template
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = template.ZIndex - 1
    shadow.Parent = template
    
    self.WindowTemplate = template
end

-- ========================================
-- EFFECTS SETUP
-- ========================================
function WindowManager:_setupEffects()
    -- Dark background
    if CONFIG.ENABLE_DARKENING then
        local darkGui = Instance.new("ScreenGui")
        darkGui.Name = "WindowManagerDarkening"
        darkGui.DisplayOrder = CONFIG.BASE_ZINDEX - 10
        darkGui.IgnoreGuiInset = true
        darkGui.Parent = self.PlayerGui
        
        self.DarkFrame = Instance.new("Frame")
        self.DarkFrame.Size = UDim2.new(1, 0, 1, 0)
        self.DarkFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        self.DarkFrame.BackgroundTransparency = 1
        self.DarkFrame.BorderSizePixel = 0
        self.DarkFrame.Parent = darkGui
    end
    
    -- Blur effect
    if CONFIG.ENABLE_BLUR then
        local lighting = game:GetService("Lighting")
        self.BlurEffect = Instance.new("BlurEffect")
        self.BlurEffect.Name = "WindowManagerBlur"
        self.BlurEffect.Size = 0
        self.BlurEffect.Parent = lighting
    end
end

-- ========================================
-- OPEN WINDOW
-- ========================================
function WindowManager:OpenWindow(options)
    options = options or {}
    
    -- Create window data
    local windowData = {
        Id = options.Id or game:GetService("HttpService"):GenerateGUID(false),
        Title = options.Title or "Window",
        Content = options.Content,
        Size = options.Size or CONFIG.DEFAULT_SIZE,
        Position = options.Position,
        CanClose = options.CanClose ~= false,
        OnClose = options.OnClose,
        Draggable = options.Draggable ~= false,
        Resizable = options.Resizable,
        Modal = options.Modal ~= false,
        Janitor = Janitor.new(),
        ZIndex = self.CurrentZIndex
    }
    
    -- Increment Z-index for next window
    self.CurrentZIndex = self.CurrentZIndex + CONFIG.WINDOW_ZINDEX_INCREMENT
    
    -- Create window GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Window_" .. windowData.Id
    screenGui.DisplayOrder = windowData.ZIndex
    screenGui.Parent = self.PlayerGui
    windowData.ScreenGui = screenGui
    windowData.Janitor:Add(screenGui)
    
    -- Clone template
    local window = self.WindowTemplate:Clone()
    window.Size = windowData.Size
    window.ZIndex = windowData.ZIndex
    window.Parent = screenGui
    windowData.Window = window
    
    -- Set title
    window.Header.Title.Text = windowData.Title
    
    -- Setup close button
    local closeButton = window.Header.CloseButton
    closeButton.Visible = windowData.CanClose
    
    if windowData.CanClose then
        windowData.Janitor:Add(closeButton.MouseButton1Click:Connect(function()
            self:CloseWindow(windowData.Id)
        end))
        
        -- Close button hover effect
        windowData.Janitor:Add(closeButton.MouseEnter:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            }):Play()
        end))
        
        windowData.Janitor:Add(closeButton.MouseLeave:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            }):Play()
        end))
    end
    
    -- Add content
    if windowData.Content then
        windowData.Content.Parent = window.Content
    end
    
    -- Make draggable
    if windowData.Draggable then
        self:_makeDraggable(window, window.Header)
    end
    
    -- Make resizable
    if windowData.Resizable then
        self:_makeResizable(window)
    end
    
    -- Animate opening
    if CONFIG.ENABLE_ANIMATIONS then
        window.Size = UDim2.new(0, 0, 0, 0)
        window.GroupTransparency = 1
        
        TweenService:Create(window, TweenInfo.new(CONFIG.OPEN_TIME, Enum.EasingStyle.Back), {
            Size = windowData.Size,
            GroupTransparency = 0
        }):Play()
    end
    
    -- Update effects
    self:_updateEffects()
    
    -- Store window
    self.Windows[windowData.Id] = windowData
    table.insert(self.WindowStack, windowData.Id)
    
    -- Play sound
    self:_playSound(CONFIG.OPEN_SOUND)
    
    return windowData.Id
end

-- ========================================
-- CLOSE WINDOW
-- ========================================
function WindowManager:CloseWindow(windowId)
    local windowData = self.Windows[windowId]
    if not windowData then return end
    
    -- Call close callback
    if windowData.OnClose then
        local shouldClose = windowData.OnClose()
        if shouldClose == false then
            return -- Cancel close
        end
    end
    
    -- Animate closing
    if CONFIG.ENABLE_ANIMATIONS then
        local tween = TweenService:Create(windowData.Window, 
            TweenInfo.new(CONFIG.CLOSE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            GroupTransparency = 1
        })
        
        tween:Play()
        tween.Completed:Connect(function()
            windowData.Janitor:Cleanup()
        end)
    else
        windowData.Janitor:Cleanup()
    end
    
    -- Remove from stack
    for i, id in ipairs(self.WindowStack) do
        if id == windowId then
            table.remove(self.WindowStack, i)
            break
        end
    end
    
    -- Clean up
    self.Windows[windowId] = nil
    
    -- Update effects
    self:_updateEffects()
    
    -- Play sound
    self:_playSound(CONFIG.CLOSE_SOUND)
end

-- ========================================
-- CLOSE ALL WINDOWS
-- ========================================
function WindowManager:CloseAllWindows()
    local windowIds = {}
    for id in pairs(self.Windows) do
        table.insert(windowIds, id)
    end
    
    for _, id in ipairs(windowIds) do
        self:CloseWindow(id)
    end
end

-- ========================================
-- UPDATE EFFECTS
-- ========================================
function WindowManager:_updateEffects()
    local hasWindows = next(self.Windows) ~= nil
    
    if CONFIG.ENABLE_DARKENING and self.DarkFrame then
        TweenService:Create(self.DarkFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = hasWindows and CONFIG.BACKGROUND_TRANSPARENCY or 1
        }):Play()
    end
    
    if CONFIG.ENABLE_BLUR and self.BlurEffect then
        TweenService:Create(self.BlurEffect, TweenInfo.new(0.2), {
            Size = hasWindows and CONFIG.BLUR_SIZE or 0
        }):Play()
    end
end

-- ========================================
-- DRAGGABLE FUNCTIONALITY
-- ========================================
function WindowManager:_makeDraggable(window, handle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    handle.Active = true
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
function WindowManager:_playSound(soundId)
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    
    Debris:AddItem(sound, sound.TimeLength + 1)
end

-- ========================================
-- QUICK ACCESS METHODS
-- ========================================
function WindowManager:ShowAlert(title, message, onOk)
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 1, -60)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextWrapped = true
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextSize = 18
    messageLabel.Parent = content
    
    local okButton = Instance.new("TextButton")
    okButton.Size = UDim2.new(0, 100, 0, 40)
    okButton.Position = UDim2.new(0.5, -50, 1, -50)
    okButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    okButton.Text = "OK"
    okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    okButton.Font = Enum.Font.SourceSansBold
    okButton.TextSize = 18
    okButton.Parent = content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = okButton
    
    local windowId = self:OpenWindow({
        Title = title,
        Content = content,
        Size = UDim2.new(0, 400, 0, 200),
        Draggable = false,
        Modal = true
    })
    
    okButton.MouseButton1Click:Connect(function()
        self:CloseWindow(windowId)
        if onOk then onOk() end
    end)
    
    return windowId
end

return WindowManager