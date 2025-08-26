--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                  SANRIO TYCOON SHOP - ULTIMATE CLIENT UI SCRIPT                      ║
    ║                           Version 5.0 - COMPLETE UI SYSTEM                           ║
    ║                                                                                      ║
    ║  THIS IS A CLIENT SCRIPT - Place in StarterPlayer > StarterPlayerScripts           ║
    ║  Works with the server script you already have installed                           ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ========================================
-- SERVICES & DEPENDENCIES
-- ========================================
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    SoundService = game:GetService("SoundService"),
    GuiService = game:GetService("GuiService"),
    Lighting = game:GetService("Lighting"),
    StarterGui = game:GetService("StarterGui"),
    ContentProvider = game:GetService("ContentProvider"),
    MarketplaceService = game:GetService("MarketplaceService"),
    TeleportService = game:GetService("TeleportService"),
    BadgeService = game:GetService("BadgeService"),
    Chat = game:GetService("Chat"),
    LocalizationService = game:GetService("LocalizationService"),
    ContextActionService = game:GetService("ContextActionService"),
    HapticService = game:GetService("HapticService"),
    VRService = game:GetService("VRService"),
    TextService = game:GetService("TextService")
}

-- ========================================
-- LOCAL PLAYER
-- ========================================
local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Mouse = LocalPlayer:GetMouse()

-- ========================================
-- REMOTE EVENTS & FUNCTIONS
-- ========================================
local RemoteFolder = Services.ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteEvents = {}
local RemoteFunctions = {}

-- Get all remote events
for _, obj in ipairs(RemoteFolder:GetChildren()) do
    if obj:IsA("RemoteEvent") then
        RemoteEvents[obj.Name] = obj
    elseif obj:IsA("RemoteFunction") then
        RemoteFunctions[obj.Name] = obj
    end
end

-- ========================================
-- CLIENT CONFIGURATION
-- ========================================
local CLIENT_CONFIG = {
    -- UI Settings
    UI_SCALE = 1,
    ANIMATION_SPEED = 0.3,
    PARTICLE_LIFETIME = 5,
    MAX_PARTICLES = 100,
    NOTIFICATION_DURATION = 5,
    
    -- Colors
    COLORS = {
        Primary = Color3.fromRGB(255, 182, 193),      -- Light Pink (Hello Kitty)
        Secondary = Color3.fromRGB(255, 105, 180),    -- Hot Pink
        Accent = Color3.fromRGB(255, 20, 147),        -- Deep Pink
        Success = Color3.fromRGB(50, 255, 50),        -- Green
        Error = Color3.fromRGB(255, 50, 50),          -- Red
        Warning = Color3.fromRGB(255, 255, 50),       -- Yellow
        Info = Color3.fromRGB(100, 200, 255),         -- Blue
        Background = Color3.fromRGB(255, 240, 245),   -- Lavender Blush
        Dark = Color3.fromRGB(50, 50, 50),            -- Dark
        White = Color3.fromRGB(255, 255, 255),        -- White
    },
    
    -- Rarity Colors
    RARITY_COLORS = {
        [1] = Color3.fromRGB(200, 200, 200),  -- Common (Gray)
        [2] = Color3.fromRGB(50, 255, 50),    -- Uncommon (Green)
        [3] = Color3.fromRGB(50, 150, 255),   -- Rare (Blue)
        [4] = Color3.fromRGB(200, 50, 255),   -- Epic (Purple)
        [5] = Color3.fromRGB(255, 200, 50),   -- Legendary (Gold)
        [6] = Color3.fromRGB(255, 50, 200),   -- Mythical (Pink)
        [7] = Color3.fromRGB(255, 0, 0),      -- Secret (Red)
    },
    
    -- Fonts
    FONTS = {
        Primary = Enum.Font.Gotham,
        Secondary = Enum.Font.GothamBold,
        Display = Enum.Font.GothamBlack,
        Cute = Enum.Font.Cartoon,
        Numbers = Enum.Font.SourceSansBold
    },
    
    -- Sounds
    SOUNDS = {
        Click = "rbxassetid://876939830",
        Open = "rbxassetid://131961136",
        Close = "rbxassetid://131961140",
        Success = "rbxassetid://131961138",
        Error = "rbxassetid://131961134",
        Notification = "rbxassetid://131961142",
        CaseOpen = "rbxassetid://131961144",
        Legendary = "rbxassetid://131961146",
        Purchase = "rbxassetid://131961148",
        LevelUp = "rbxassetid://131961150"
    },
    
    -- Icons
    ICONS = {
        Coin = "rbxassetid://10000000001",
        Gem = "rbxassetid://10000000002",
        Ticket = "rbxassetid://10000000003",
        Star = "rbxassetid://10000000004",
        Pet = "rbxassetid://10000000005",
        Egg = "rbxassetid://10000000006",
        Trade = "rbxassetid://10000000007",
        Battle = "rbxassetid://10000000008",
        Quest = "rbxassetid://10000000009",
        Settings = "rbxassetid://10000000010"
    },
    
    -- Case Opening
    CASE_SPIN_TIME = 5,
    CASE_ITEMS_VISIBLE = 5,
    CASE_ITEM_WIDTH = 150,
    CASE_DECELERATION = 0.98,
    
    -- Animations
    TWEEN_INFO = {
        Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Normal = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        Elastic = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    }
}

-- ========================================
-- LOCAL DATA STORAGE
-- ========================================
local LocalData = {
    PlayerData = nil,
    PetDatabase = {},
    EggDatabase = {},
    GamepassDatabase = {},
    QuestData = {},
    Settings = {
        MusicEnabled = true,
        SFXEnabled = true,
        ParticlesEnabled = true,
        LowQualityMode = false,
        UIScale = 1,
        NotificationsEnabled = true
    },
    Cache = {
        LoadedImages = {},
        LoadedSounds = {},
        LoadedModels = {}
    }
}

-- ========================================
-- UI MODULES
-- ========================================
local UIModules = {
    MainUI = {},
    ShopUI = {},
    InventoryUI = {},
    CaseOpeningUI = {},
    TradingUI = {},
    BattleUI = {},
    ClanUI = {},
    QuestUI = {},
    SettingsUI = {},
    NotificationUI = {},
    LeaderboardUI = {},
    ProfileUI = {},
    DailyRewardUI = {},
    BattlePassUI = {},
    AchievementUI = {}
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
local Utilities = {}

function Utilities:PlaySound(soundId)
    if not LocalData.Settings.SFXEnabled then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function Utilities:FormatNumber(num)
    if num >= 1e12 then
        return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.2fK", num / 1e3)
    else
        return tostring(math.floor(num))
    end
end

function Utilities:FormatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    elseif seconds < 86400 then
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    else
        return string.format("%dd %dh", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
    end
end

function Utilities:GetRarityColor(rarity)
    return CLIENT_CONFIG.RARITY_COLORS[rarity] or CLIENT_CONFIG.COLORS.White
end

function Utilities:CreateGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

function Utilities:CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function Utilities:CreateStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or CLIENT_CONFIG.COLORS.Dark
    stroke.Thickness = thickness or 2
    stroke.Transparency = transparency or 0
    stroke.Parent = parent
    return stroke
end

function Utilities:CreatePadding(parent, padding)
    local uiPadding = Instance.new("UIPadding")
    if type(padding) == "number" then
        uiPadding.PaddingTop = UDim.new(0, padding)
        uiPadding.PaddingBottom = UDim.new(0, padding)
        uiPadding.PaddingLeft = UDim.new(0, padding)
        uiPadding.PaddingRight = UDim.new(0, padding)
    else
        uiPadding.PaddingTop = UDim.new(0, padding.Top or 0)
        uiPadding.PaddingBottom = UDim.new(0, padding.Bottom or 0)
        uiPadding.PaddingLeft = UDim.new(0, padding.Left or 0)
        uiPadding.PaddingRight = UDim.new(0, padding.Right or 0)
    end
    uiPadding.Parent = parent
    return uiPadding
end

function Utilities:CreateShadow(parent, transparency, size)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageTransparency = transparency or 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, size or 20, 1, size or 20)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent.Parent
    return shadow
end

function Utilities:Tween(object, properties, tweenInfo)
    local tween = Services.TweenService:Create(object, tweenInfo or CLIENT_CONFIG.TWEEN_INFO.Normal, properties)
    tween:Play()
    return tween
end

function Utilities:LoadImage(imageId)
    if LocalData.Cache.LoadedImages[imageId] then
        return LocalData.Cache.LoadedImages[imageId]
    end
    
    Services.ContentProvider:PreloadAsync({imageId})
    LocalData.Cache.LoadedImages[imageId] = true
    return imageId
end

-- ========================================
-- UI COMPONENTS
-- ========================================
local UIComponents = {}

function UIComponents:CreateButton(parent, text, size, position, callback)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = size or UDim2.new(0, 200, 0, 50)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    button.Text = text
    button.TextColor3 = CLIENT_CONFIG.COLORS.White
    button.Font = CLIENT_CONFIG.FONTS.Secondary
    button.TextScaled = true
    button.Parent = parent
    
    Utilities:CreateCorner(button, 8)
    Utilities:CreateStroke(button, CLIENT_CONFIG.COLORS.Dark, 2, 0.8)
    Utilities:CreatePadding(button, 8)
    
    local shadow = Utilities:CreateShadow(button)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        Utilities:Tween(button, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Secondary}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(button, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 4)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    button.MouseLeave:Connect(function()
        Utilities:Tween(button, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(button, {Size = size or UDim2.new(0, 200, 0, 50)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    button.MouseButton1Click:Connect(function()
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Click)
        
        -- Click animation
        local originalSize = button.Size
        Utilities:Tween(button, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 8, originalSize.Y.Scale, originalSize.Y.Offset - 8)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        wait(0.1)
        Utilities:Tween(button, {Size = originalSize}, CLIENT_CONFIG.TWEEN_INFO.Bounce)
        
        if callback then
            callback()
        end
    end)
    
    return button
end

function UIComponents:CreateFrame(parent, name, size, position, color)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size or UDim2.new(0.5, 0, 0.5, 0)
    frame.Position = position or UDim2.new(0.25, 0, 0.25, 0)
    frame.BackgroundColor3 = color or CLIENT_CONFIG.COLORS.Background
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    Utilities:CreateCorner(frame, 12)
    
    return frame
end

function UIComponents:CreateLabel(parent, text, size, position, textSize)
    local label = Instance.new("TextLabel")
    label.Name = text .. "Label"
    label.Size = size or UDim2.new(0, 200, 0, 50)
    label.Position = position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CLIENT_CONFIG.COLORS.Dark
    label.Font = CLIENT_CONFIG.FONTS.Primary
    label.TextSize = textSize or 18
    label.TextScaled = true
    label.Parent = parent
    
    return label
end

function UIComponents:CreateImageLabel(parent, imageId, size, position)
    local image = Instance.new("ImageLabel")
    image.Name = "Image"
    image.Size = size or UDim2.new(0, 100, 0, 100)
    image.Position = position or UDim2.new(0, 0, 0, 0)
    image.BackgroundTransparency = 1
    image.Image = imageId
    image.ScaleType = Enum.ScaleType.Fit
    image.Parent = parent
    
    return image
end

function UIComponents:CreateTextBox(parent, placeholderText, size, position)
    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = size or UDim2.new(0, 200, 0, 40)
    textBox.Position = position or UDim2.new(0, 0, 0, 0)
    textBox.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    textBox.PlaceholderText = placeholderText
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.Text = ""
    textBox.TextColor3 = CLIENT_CONFIG.COLORS.Dark
    textBox.Font = CLIENT_CONFIG.FONTS.Primary
    textBox.TextScaled = true
    textBox.ClearTextOnFocus = false
    textBox.Parent = parent
    
    Utilities:CreateCorner(textBox, 8)
    Utilities:CreateStroke(textBox, CLIENT_CONFIG.COLORS.Primary, 2)
    Utilities:CreatePadding(textBox, 8)
    
    -- Focus effects
    textBox.Focused:Connect(function()
        Utilities:Tween(textBox.UIStroke, {Color = CLIENT_CONFIG.COLORS.Secondary}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    textBox.FocusLost:Connect(function()
        Utilities:Tween(textBox.UIStroke, {Color = CLIENT_CONFIG.COLORS.Primary}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    return textBox
end

function UIComponents:CreateScrollingFrame(parent, size, position, canvasSize)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollingFrame"
    scrollFrame.Size = size or UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = position or UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.CanvasSize = canvasSize or UDim2.new(0, 0, 2, 0)
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = CLIENT_CONFIG.COLORS.Primary
    scrollFrame.Parent = parent
    
    return scrollFrame
end

function UIComponents:CreateProgressBar(parent, size, position, value, maxValue)
    local container = Instance.new("Frame")
    container.Name = "ProgressBar"
    container.Size = size or UDim2.new(0, 200, 0, 20)
    container.Position = position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    container.Parent = parent
    
    Utilities:CreateCorner(container, 10)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(value / maxValue, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    fill.Parent = container
    
    Utilities:CreateCorner(fill, 10)
    Utilities:CreateGradient(fill, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.Success),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 0))
    })
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("%d / %d", value, maxValue)
    label.TextColor3 = CLIENT_CONFIG.COLORS.White
    label.Font = CLIENT_CONFIG.FONTS.Secondary
    label.TextScaled = true
    label.Parent = container
    
    container.UpdateValue = function(newValue)
        value = math.clamp(newValue, 0, maxValue)
        Utilities:Tween(fill, {Size = UDim2.new(value / maxValue, 0, 1, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        label.Text = string.format("%d / %d", value, maxValue)
    end
    
    return container
end

function UIComponents:CreateToggle(parent, text, size, position, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Name = text .. "Toggle"
    container.Size = size or UDim2.new(0, 200, 0, 40)
    container.Position = position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, -10, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CLIENT_CONFIG.COLORS.Dark
    label.Font = CLIENT_CONFIG.FONTS.Primary
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 60, 0, 30)
    toggleButton.Position = UDim2.new(1, -60, 0.5, -15)
    toggleButton.BackgroundColor3 = defaultValue and CLIENT_CONFIG.COLORS.Success or Color3.fromRGB(200, 200, 200)
    toggleButton.Text = ""
    toggleButton.Parent = container
    
    Utilities:CreateCorner(toggleButton, 15)
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0, 24, 0, 24)
    slider.Position = defaultValue and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
    slider.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    slider.Parent = toggleButton
    
    Utilities:CreateCorner(slider, 12)
    Utilities:CreateShadow(slider, 0.3, 4)
    
    local value = defaultValue
    
    toggleButton.MouseButton1Click:Connect(function()
        value = not value
        
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Click)
        
        if value then
            Utilities:Tween(toggleButton, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            Utilities:Tween(slider, {Position = UDim2.new(1, -27, 0.5, -12)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        else
            Utilities:Tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            Utilities:Tween(slider, {Position = UDim2.new(0, 3, 0.5, -12)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        end
        
        if callback then
            callback(value)
        end
    end)
    
    container.SetValue = function(newValue)
        if newValue ~= value then
            toggleButton.MouseButton1Click:Fire()
        end
    end
    
    return container
end

function UIComponents:CreateTab(parent, tabs, size, position)
    local container = Instance.new("Frame")
    container.Name = "TabContainer"
    container.Size = size or UDim2.new(1, 0, 1, 0)
    container.Position = position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, 0, 0, 40)
    tabButtons.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    tabButtons.Parent = container
    
    Utilities:CreateCorner(tabButtons, 8)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabButtons
    
    local tabContent = Instance.new("Frame")
    tabContent.Name = "TabContent"
    tabContent.Size = UDim2.new(1, 0, 1, -50)
    tabContent.Position = UDim2.new(0, 0, 0, 50)
    tabContent.BackgroundTransparency = 1
    tabContent.Parent = container
    
    local currentTab = nil
    local tabFrames = {}
    local tabButtonInstances = {}
    
    for i, tab in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tab.Name .. "Tab"
        tabButton.Size = UDim2.new(1 / #tabs, -5, 1, 0)
        tabButton.BackgroundColor3 = i == 1 and CLIENT_CONFIG.COLORS.Primary or CLIENT_CONFIG.COLORS.White
        tabButton.Text = tab.Name
        tabButton.TextColor3 = i == 1 and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
        tabButton.Font = CLIENT_CONFIG.FONTS.Secondary
        tabButton.TextScaled = true
        tabButton.Parent = tabButtons
        
        Utilities:CreateCorner(tabButton, 8)
        Utilities:CreatePadding(tabButton, 8)
        
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = tab.Name .. "Content"
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = tabContent
        
        tabFrames[tab.Name] = tabFrame
        tabButtonInstances[tab.Name] = tabButton
        
        if i == 1 then
            currentTab = tab.Name
        end
        
        tabButton.MouseButton1Click:Connect(function()
            if currentTab == tab.Name then return end
            
            Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Click)
            
            -- Update buttons
            for name, btn in pairs(tabButtonInstances) do
                if name == tab.Name then
                    Utilities:Tween(btn, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary, TextColor3 = CLIENT_CONFIG.COLORS.White}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                else
                    Utilities:Tween(btn, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White, TextColor3 = CLIENT_CONFIG.COLORS.Dark}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                end
            end
            
            -- Update content
            for name, frame in pairs(tabFrames) do
                frame.Visible = name == tab.Name
            end
            
            currentTab = tab.Name
            
            if tab.Callback then
                tab.Callback(tabFrame)
            end
        end)
        
        if tab.Init then
            tab.Init(tabFrame)
        end
    end
    
    return container, tabFrames
end

-- ========================================
-- PARTICLE SYSTEM
-- ========================================
local ParticleSystem = {}

function ParticleSystem:CreateParticle(parent, particleType, position)
    if not LocalData.Settings.ParticlesEnabled then return end
    
    local particle = Instance.new("ImageLabel")
    particle.Name = "Particle"
    particle.Size = UDim2.new(0, math.random(20, 40), 0, math.random(20, 40))
    particle.Position = position or UDim2.new(math.random(), 0, math.random(), 0)
    particle.BackgroundTransparency = 1
    particle.ZIndex = 999
    particle.Parent = parent
    
    if particleType == "star" then
        particle.Image = "rbxassetid://1266543676"
        particle.ImageColor3 = Color3.fromRGB(255, 255, 0)
    elseif particleType == "heart" then
        particle.Image = "rbxassetid://1536547385"
        particle.ImageColor3 = CLIENT_CONFIG.COLORS.Primary
    elseif particleType == "sparkle" then
        particle.Image = "rbxassetid://1266543231"
        particle.ImageColor3 = Color3.fromRGB(255, 255, 255)
    elseif particleType == "coin" then
        particle.Image = CLIENT_CONFIG.ICONS.Coin
        particle.ImageColor3 = Color3.fromRGB(255, 215, 0)
    end
    
    -- Random animation
    local endPosition = UDim2.new(
        particle.Position.X.Scale + math.random(-0.2, 0.2),
        particle.Position.X.Offset,
        particle.Position.Y.Scale - math.random(0.3, 0.5),
        particle.Position.Y.Offset
    )
    
    local tweenInfo = TweenInfo.new(
        math.random(2, 4),
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local moveTween = Services.TweenService:Create(particle, tweenInfo, {
        Position = endPosition,
        ImageTransparency = 1,
        Rotation = math.random(-180, 180)
    })
    
    moveTween:Play()
    
    moveTween.Completed:Connect(function()
        particle:Destroy()
    end)
    
    return particle
end

function ParticleSystem:CreateBurst(parent, particleType, position, count)
    for i = 1, count or 10 do
        spawn(function()
            wait(i * 0.05)
            self:CreateParticle(parent, particleType, position)
        end)
    end
end

function ParticleSystem:CreateTrail(parent, particleType, startPos, endPos, count)
    local steps = count or 10
    for i = 1, steps do
        spawn(function()
            wait(i * 0.05)
            local t = i / steps
            local pos = UDim2.new(
                startPos.X.Scale + (endPos.X.Scale - startPos.X.Scale) * t,
                startPos.X.Offset + (endPos.X.Offset - startPos.X.Offset) * t,
                startPos.Y.Scale + (endPos.Y.Scale - startPos.Y.Scale) * t,
                startPos.Y.Offset + (endPos.Y.Offset - startPos.Y.Offset) * t
            )
            self:CreateParticle(parent, particleType, pos)
        end)
    end
end

-- ========================================
-- MAIN UI SYSTEM
-- ========================================
local MainUI = {}

function MainUI:Initialize()
    -- Create main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SanrioTycoonUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    self.ScreenGui = screenGui
    
    -- Create main container
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = screenGui
    
    self.MainContainer = mainContainer
    
    -- Create currency display
    self:CreateCurrencyDisplay()
    
    -- Create navigation bar
    self:CreateNavigationBar()
    
    -- Create notification container
    self:CreateNotificationContainer()
    
    -- Apply UI scale
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = LocalData.Settings.UIScale
    uiScale.Parent = mainContainer
    
    return self
end

function MainUI:CreateCurrencyDisplay()
    local currencyFrame = UIComponents:CreateFrame(self.MainContainer, "CurrencyDisplay", UDim2.new(0, 400, 0, 60), UDim2.new(0, 10, 0, 10))
    currencyFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    Utilities:CreateShadow(currencyFrame, 0.3)
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Padding = UDim.new(0, 10)
    layout.Parent = currencyFrame
    
    Utilities:CreatePadding(currencyFrame, 10)
    
    -- Coins
    local coinContainer = Instance.new("Frame")
    coinContainer.Size = UDim2.new(0, 120, 1, 0)
    coinContainer.BackgroundTransparency = 1
    coinContainer.Parent = currencyFrame
    
    local coinIcon = UIComponents:CreateImageLabel(coinContainer, CLIENT_CONFIG.ICONS.Coin, UDim2.new(0, 30, 0, 30), UDim2.new(0, 0, 0.5, -15))
    
    local coinLabel = UIComponents:CreateLabel(coinContainer, "0", UDim2.new(1, -40, 1, 0), UDim2.new(0, 40, 0, 0), 20)
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Font = CLIENT_CONFIG.FONTS.Numbers
    
    -- Gems
    local gemContainer = Instance.new("Frame")
    gemContainer.Size = UDim2.new(0, 120, 1, 0)
    gemContainer.BackgroundTransparency = 1
    gemContainer.Parent = currencyFrame
    
    local gemIcon = UIComponents:CreateImageLabel(gemContainer, CLIENT_CONFIG.ICONS.Gem, UDim2.new(0, 30, 0, 30), UDim2.new(0, 0, 0.5, -15))
    
    local gemLabel = UIComponents:CreateLabel(gemContainer, "0", UDim2.new(1, -40, 1, 0), UDim2.new(0, 40, 0, 0), 20)
    gemLabel.TextXAlignment = Enum.TextXAlignment.Left
    gemLabel.Font = CLIENT_CONFIG.FONTS.Numbers
    
    -- Store references
    self.CurrencyLabels = {
        Coins = coinLabel,
        Gems = gemLabel
    }
    
    -- Update function
    self.UpdateCurrency = function(currencies)
        coinLabel.Text = Utilities:FormatNumber(currencies.coins or 0)
        gemLabel.Text = Utilities:FormatNumber(currencies.gems or 0)
        
        -- Animation
        Utilities:Tween(coinLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(gemLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        wait(0.3)
        Utilities:Tween(coinLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Dark}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(gemLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Dark}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end
end

function MainUI:CreateNavigationBar()
    local navBar = UIComponents:CreateFrame(self.MainContainer, "NavigationBar", UDim2.new(0, 80, 1, -140), UDim2.new(0, 10, 0, 80))
    navBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    Utilities:CreateShadow(navBar, 0.3)
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.Parent = navBar
    
    Utilities:CreatePadding(navBar, 10)
    
    local navButtons = {
        {Name = "Shop", Icon = CLIENT_CONFIG.ICONS.Egg, Module = "ShopUI"},
        {Name = "Inventory", Icon = CLIENT_CONFIG.ICONS.Pet, Module = "InventoryUI"},
        {Name = "Trade", Icon = CLIENT_CONFIG.ICONS.Trade, Module = "TradingUI"},
        {Name = "Battle", Icon = CLIENT_CONFIG.ICONS.Battle, Module = "BattleUI"},
        {Name = "Quest", Icon = CLIENT_CONFIG.ICONS.Quest, Module = "QuestUI"},
        {Name = "Settings", Icon = CLIENT_CONFIG.ICONS.Settings, Module = "SettingsUI"}
    }
    
    for _, nav in ipairs(navButtons) do
        local button = Instance.new("TextButton")
        button.Name = nav.Name .. "NavButton"
        button.Size = UDim2.new(1, 0, 0, 60)
        button.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
        button.Text = ""
        button.Parent = navBar
        
        Utilities:CreateCorner(button, 8)
        
        local icon = UIComponents:CreateImageLabel(button, nav.Icon, UDim2.new(0, 40, 0, 40), UDim2.new(0.5, -20, 0.5, -20))
        
        button.MouseEnter:Connect(function()
            Utilities:Tween(button, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            
            -- Show tooltip
            local tooltip = Instance.new("Frame")
            tooltip.Name = "Tooltip"
            tooltip.Size = UDim2.new(0, 100, 0, 30)
            tooltip.Position = UDim2.new(1, 10, 0.5, -15)
            tooltip.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
            tooltip.Parent = button
            
            Utilities:CreateCorner(tooltip, 6)
            
            local tooltipText = UIComponents:CreateLabel(tooltip, nav.Name, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 14)
            tooltipText.TextColor3 = CLIENT_CONFIG.COLORS.White
            
            Utilities:Tween(tooltip, {BackgroundTransparency = 0}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        end)
        
        button.MouseLeave:Connect(function()
            Utilities:Tween(button, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Background}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            
            local tooltip = button:FindFirstChild("Tooltip")
            if tooltip then
                tooltip:Destroy()
            end
        end)
        
        button.MouseButton1Click:Connect(function()
            Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Click)
            self:OpenModule(nav.Module)
        end)
    end
    
    self.NavigationBar = navBar
end

function MainUI:CreateNotificationContainer()
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, 350, 1, -20)
    container.Position = UDim2.new(1, -360, 0, 10)
    container.BackgroundTransparency = 1
    container.Parent = self.MainContainer
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container
    
    self.NotificationContainer = container
end

function MainUI:OpenModule(moduleName)
    -- Close all modules first
    for name, module in pairs(UIModules) do
        if module.Close then
            module:Close()
        end
    end
    
    -- Open selected module
    local module = UIModules[moduleName]
    if module and module.Open then
        module:Open()
    end
end

-- Continue in Part 2...-- ========================================
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

-- Continue in Part 3...-- ========================================
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

-- Continue in Part 4...-- ========================================
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
}-- ========================================
-- DAILY REWARD UI MODULE
-- ========================================
UIModules.DailyRewardUI = {}

function UIModules.DailyRewardUI:CheckAndShow()
    -- Check if can claim daily reward
    local canClaim, timeRemaining = RemoteFunctions.CheckDailyReward:InvokeServer()
    
    if canClaim then
        self:ShowDailyRewardWindow()
    else
        -- Show time remaining
        local hours = math.floor(timeRemaining / 3600)
        local minutes = math.floor((timeRemaining % 3600) / 60)
        NotificationSystem:SendNotification("Daily Reward", string.format("Come back in %dh %dm for your daily reward!", hours, minutes), "info")
    end
end

function UIModules.DailyRewardUI:ShowDailyRewardWindow()
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "DailyRewardOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 600
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Daily reward window
    local rewardWindow = Instance.new("Frame")
    rewardWindow.Name = "DailyRewardWindow"
    rewardWindow.Size = UDim2.new(0, 700, 0, 500)
    rewardWindow.Position = UDim2.new(0.5, -350, 0.5, -250)
    rewardWindow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    rewardWindow.ZIndex = 601
    rewardWindow.Parent = overlay
    
    Utilities:CreateCorner(rewardWindow, 20)
    Utilities:CreateShadow(rewardWindow, 0.5, 30)
    
    -- Animate in
    rewardWindow.Position = UDim2.new(0.5, -350, 0.5, -250)
    rewardWindow.Size = UDim2.new(0, 0, 0, 0)
    Utilities:Tween(rewardWindow, {
        Size = UDim2.new(0, 700, 0, 500),
        Position = UDim2.new(0.5, -350, 0.5, -250)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 602
    header.Parent = rewardWindow
    
    Utilities:CreateCorner(header, 20)
    
    local bottomRect = Instance.new("Frame")
    bottomRect.Size = UDim2.new(1, 0, 0, 20)
    bottomRect.Position = UDim2.new(0, 0, 1, -20)
    bottomRect.BackgroundColor3 = header.BackgroundColor3
    bottomRect.BorderSizePixel = 0
    bottomRect.ZIndex = 602
    bottomRect.Parent = header
    
    -- Title
    local titleLabel = UIComponents:CreateLabel(header, "🎁 Daily Rewards 🎁", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 28)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 603
    
    -- Streak info
    local streakLabel = UIComponents:CreateLabel(header, "Day 1 • Keep your streak going!", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 45), 16)
    streakLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    streakLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    streakLabel.ZIndex = 603
    
    -- Days grid
    local daysContainer = Instance.new("Frame")
    daysContainer.Size = UDim2.new(1, -40, 1, -140)
    daysContainer.Position = UDim2.new(0, 20, 0, 100)
    daysContainer.BackgroundTransparency = 1
    daysContainer.ZIndex = 602
    daysContainer.Parent = rewardWindow
    
    local daysGrid = Instance.new("UIGridLayout")
    daysGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    daysGrid.CellSize = UDim2.new(1/7, -8.5, 0.5, -5)
    daysGrid.FillDirection = Enum.FillDirection.Horizontal
    daysGrid.Parent = daysContainer
    
    -- Create day cards
    local dailyRewards = {
        {day = 1, coins = 1000, gems = 10},
        {day = 2, coins = 2000, gems = 20},
        {day = 3, coins = 3000, gems = 30},
        {day = 4, coins = 4000, gems = 40},
        {day = 5, coins = 5000, gems = 50, special = "Lucky Potion"},
        {day = 6, coins = 6000, gems = 60},
        {day = 7, coins = 10000, gems = 100, special = "Premium Egg"}
    }
    
    local currentStreak = LocalData.PlayerData and LocalData.PlayerData.dailyRewards.streak or 1
    
    for i, reward in ipairs(dailyRewards) do
        local dayCard = self:CreateDayCard(daysContainer, reward, i <= currentStreak, i == currentStreak)
    end
    
    -- Claim button
    local claimButton = UIComponents:CreateButton(rewardWindow, "Claim Reward!", UDim2.new(0, 250, 0, 60), UDim2.new(0.5, -125, 1, -80), function()
        self:ClaimDailyReward(overlay)
    end)
    claimButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    claimButton.TextSize = 20
    claimButton.ZIndex = 603
    
    -- Add glow effect to button
    spawn(function()
        while claimButton.Parent do
            Utilities:Tween(claimButton, {Size = UDim2.new(0, 260, 0, 65)}, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
            wait(0.5)
            Utilities:Tween(claimButton, {Size = UDim2.new(0, 250, 0, 60)}, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
            wait(0.5)
        end
    end)
    
    -- Update streak label
    if LocalData.PlayerData then
        streakLabel.Text = string.format("Day %d • Keep your streak going!", currentStreak)
    end
end

function UIModules.DailyRewardUI:CreateDayCard(parent, reward, isClaimed, isToday)
    local card = Instance.new("Frame")
    card.Name = "Day" .. reward.day
    card.BackgroundColor3 = isClaimed and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.White
    card.BackgroundTransparency = isClaimed and 0.3 or 0
    card.ZIndex = 603
    card.Parent = parent
    
    Utilities:CreateCorner(card, 12)
    
    if isToday then
        -- Add glow effect
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1, 20, 1, 20)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = CLIENT_CONFIG.COLORS.Warning
        glow.ZIndex = 602
        glow.Parent = card
        
        -- Animate glow
        spawn(function()
            while glow.Parent do
                Utilities:Tween(glow, {Size = UDim2.new(1, 30, 1, 30), ImageTransparency = 0.7}, TweenInfo.new(1, Enum.EasingStyle.Sine))
                wait(1)
                Utilities:Tween(glow, {Size = UDim2.new(1, 20, 1, 20), ImageTransparency = 0.5}, TweenInfo.new(1, Enum.EasingStyle.Sine))
                wait(1)
            end
        end)
        
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
    end
    
    -- Day label
    local dayLabel = UIComponents:CreateLabel(card, "Day " .. reward.day, UDim2.new(1, -10, 0, 25), UDim2.new(0, 5, 0, 5), 16)
    dayLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    dayLabel.TextColor3 = isToday and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    dayLabel.ZIndex = 604
    
    -- Rewards
    local rewardY = 35
    
    -- Coins
    local coinLabel = UIComponents:CreateLabel(card, "💰 " .. Utilities:FormatNumber(reward.coins), UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, rewardY), 14)
    coinLabel.TextColor3 = isToday and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    coinLabel.ZIndex = 604
    rewardY = rewardY + 20
    
    -- Gems
    local gemLabel = UIComponents:CreateLabel(card, "💎 " .. reward.gems, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, rewardY), 14)
    gemLabel.TextColor3 = isToday and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    gemLabel.ZIndex = 604
    rewardY = rewardY + 20
    
    -- Special reward
    if reward.special then
        local specialLabel = UIComponents:CreateLabel(card, "🎁 " .. reward.special, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, rewardY), 12)
        specialLabel.TextColor3 = CLIENT_CONFIG.COLORS.Accent
        specialLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        specialLabel.TextWrapped = true
        specialLabel.ZIndex = 604
    end
    
    -- Claimed checkmark
    if isClaimed and not isToday then
        local checkmark = UIComponents:CreateLabel(card, "✓", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 48)
        checkmark.TextColor3 = CLIENT_CONFIG.COLORS.White
        checkmark.TextTransparency = 0.5
        checkmark.Font = CLIENT_CONFIG.FONTS.Display
        checkmark.ZIndex = 605
    end
    
    return card
end

function UIModules.DailyRewardUI:ClaimDailyReward(overlay)
    local success, rewards = RemoteFunctions.ClaimDailyReward:InvokeServer()
    
    if success then
        -- Show reward animation
        self:ShowRewardAnimation(rewards)
        
        -- Update UI
        if MainUI.UpdateCurrency and LocalData.PlayerData then
            MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
        end
        
        -- Close window after delay
        wait(2)
        Utilities:Tween(overlay:FindFirstChild("DailyRewardWindow"), {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        wait(0.3)
        overlay:Destroy()
    else
        NotificationSystem:SendNotification("Error", rewards or "Failed to claim daily reward", "error")
    end
end

function UIModules.DailyRewardUI:ShowRewardAnimation(rewards)
    -- Create reward display
    local rewardDisplay = Instance.new("Frame")
    rewardDisplay.Size = UDim2.new(0, 300, 0, 200)
    rewardDisplay.Position = UDim2.new(0.5, -150, 0.5, -100)
    rewardDisplay.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    rewardDisplay.ZIndex = 700
    rewardDisplay.Parent = MainUI.ScreenGui
    
    Utilities:CreateCorner(rewardDisplay, 12)
    Utilities:CreateShadow(rewardDisplay, 0.5)
    
    -- Title
    local titleLabel = UIComponents:CreateLabel(rewardDisplay, "Rewards Claimed!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 20)
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.Success
    titleLabel.ZIndex = 701
    
    -- Rewards list
    local yOffset = 60
    if rewards.coins then
        local coinLabel = UIComponents:CreateLabel(rewardDisplay, "+ " .. Utilities:FormatNumber(rewards.coins) .. " Coins", 
            UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, yOffset), 18)
        coinLabel.TextColor3 = CLIENT_CONFIG.COLORS.Warning
        coinLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        coinLabel.ZIndex = 701
        yOffset = yOffset + 30
    end
    
    if rewards.gems then
        local gemLabel = UIComponents:CreateLabel(rewardDisplay, "+ " .. rewards.gems .. " Gems", 
            UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, yOffset), 18)
        gemLabel.TextColor3 = CLIENT_CONFIG.COLORS.Primary
        gemLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        gemLabel.ZIndex = 701
        yOffset = yOffset + 30
    end
    
    -- Particles
    ParticleSystem:CreateBurst(rewardDisplay, "coin", UDim2.new(0.5, 0, 0.5, 0), 20)
    
    -- Sound
    Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
    
    -- Animate
    rewardDisplay.Size = UDim2.new(0, 0, 0, 0)
    rewardDisplay.Position = UDim2.new(0.5, 0, 0.5, 0)
    Utilities:Tween(rewardDisplay, {
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Auto close
    wait(3)
    Utilities:Tween(rewardDisplay, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    wait(0.3)
    rewardDisplay:Destroy()
end

-- ========================================
-- LEADERBOARD UI MODULE
-- ========================================
UIModules.LeaderboardUI = {}

function UIModules.LeaderboardUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshLeaderboards()
        return
    end
    
    -- Create main leaderboard frame
    local leaderboardFrame = UIComponents:CreateFrame(MainUI.MainContainer, "LeaderboardFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    leaderboardFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = leaderboardFrame
    
    -- Header
    local header = UIComponents:CreateFrame(leaderboardFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "🏆 Leaderboards 🏆", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Create tabs
    local tabs = {
        {
            Name = "Top Coins",
            Init = function(parent)
                self:CreateLeaderboard(parent, "coins")
            end
        },
        {
            Name = "Top Gems",
            Init = function(parent)
                self:CreateLeaderboard(parent, "gems")
            end
        },
        {
            Name = "Battle Rating",
            Init = function(parent)
                self:CreateLeaderboard(parent, "battle")
            end
        },
        {
            Name = "Pet Collection",
            Init = function(parent)
                self:CreateLeaderboard(parent, "pets")
            end
        }
    }
    
    local tabContainer, tabFrames = UIComponents:CreateTab(leaderboardFrame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    self.TabFrames = tabFrames
    
    -- Refresh timer
    spawn(function()
        while self.Frame and self.Frame.Parent do
            wait(30) -- Refresh every 30 seconds
            self:RefreshLeaderboards()
        end
    end)
end

function UIModules.LeaderboardUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.LeaderboardUI:CreateLeaderboard(parent, leaderboardType)
    -- Your rank display
    local yourRankFrame = Instance.new("Frame")
    yourRankFrame.Size = UDim2.new(1, -20, 0, 80)
    yourRankFrame.Position = UDim2.new(0, 10, 0, 10)
    yourRankFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    yourRankFrame.Parent = parent
    
    Utilities:CreateCorner(yourRankFrame, 12)
    Utilities:CreatePadding(yourRankFrame, 15)
    
    local yourRankLabel = UIComponents:CreateLabel(yourRankFrame, "Your Rank: #???", UDim2.new(0.3, 0, 1, 0), UDim2.new(0, 0, 0, 0), 20)
    yourRankLabel.TextXAlignment = Enum.TextXAlignment.Left
    yourRankLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    yourRankLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local yourValueLabel = UIComponents:CreateLabel(yourRankFrame, "0", UDim2.new(0.7, 0, 1, 0), UDim2.new(0.3, 0, 0, 0), 24)
    yourValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    yourValueLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    yourValueLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Leaderboard list
    local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -20, 1, -110), UDim2.new(0, 10, 0, 100))
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Store references
    if not self.Leaderboards then
        self.Leaderboards = {}
    end
    
    self.Leaderboards[leaderboardType] = {
        Container = scrollFrame,
        YourRankLabel = yourRankLabel,
        YourValueLabel = yourValueLabel
    }
end

function UIModules.LeaderboardUI:CreateLeaderboardEntry(parent, rank, playerName, value, isYou)
    local entry = Instance.new("Frame")
    entry.Name = "Rank" .. rank
    entry.Size = UDim2.new(1, -10, 0, 60)
    entry.BackgroundColor3 = isYou and CLIENT_CONFIG.COLORS.Primary or CLIENT_CONFIG.COLORS.White
    entry.BackgroundTransparency = isYou and 0.2 or 0
    entry.LayoutOrder = rank
    entry.Parent = parent
    
    Utilities:CreateCorner(entry, 8)
    Utilities:CreatePadding(entry, 10)
    
    -- Rank display
    local rankFrame = Instance.new("Frame")
    rankFrame.Size = UDim2.new(0, 50, 1, 0)
    rankFrame.BackgroundTransparency = 1
    rankFrame.Parent = entry
    
    local rankLabel = UIComponents:CreateLabel(rankFrame, "#" .. rank, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 20)
    rankLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Special colors for top 3
    if rank == 1 then
        rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    elseif rank == 2 then
        rankLabel.TextColor3 = Color3.fromRGB(192, 192, 192) -- Silver
    elseif rank == 3 then
        rankLabel.TextColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
    else
        rankLabel.TextColor3 = isYou and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    end
    
    -- Player info
    local playerLabel = UIComponents:CreateLabel(entry, playerName, UDim2.new(0.5, -70, 1, 0), UDim2.new(0, 60, 0, 0), 16)
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    playerLabel.TextColor3 = isYou and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Dark
    
    -- Value
    local valueLabel = UIComponents:CreateLabel(entry, Utilities:FormatNumber(value), UDim2.new(0.4, -10, 1, 0), UDim2.new(0.6, 0, 0, 0), 18)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = CLIENT_CONFIG.FONTS.Numbers
    valueLabel.TextColor3 = isYou and CLIENT_CONFIG.COLORS.White or CLIENT_CONFIG.COLORS.Primary
    
    -- Trophy icon for top 3
    if rank <= 3 then
        local trophy = UIComponents:CreateLabel(entry, rank == 1 and "🥇" or rank == 2 and "🥈" or "🥉", 
            UDim2.new(0, 30, 0, 30), UDim2.new(1, -40, 0.5, -15), 24)
        trophy.ZIndex = entry.ZIndex + 1
    end
    
    return entry
end

function UIModules.LeaderboardUI:RefreshLeaderboards()
    -- TODO: Fetch leaderboard data from server
    -- For now, use sample data
    
    local sampleData = {
        coins = {
            {name = "RichPlayer123", value = 999999999},
            {name = "CoinMaster", value = 500000000},
            {name = "MoneyBags", value = 250000000},
            {name = "Wealthy", value = 100000000},
            {name = "Collector", value = 50000000}
        },
        gems = {
            {name = "GemHoarder", value = 999999},
            {name = "DiamondKing", value = 500000},
            {name = "JewelMaster", value = 250000},
            {name = "GemCollector", value = 100000},
            {name = "Sparkles", value = 50000}
        }
    }
    
    -- Update each leaderboard
    for leaderboardType, data in pairs(sampleData) do
        if self.Leaderboards and self.Leaderboards[leaderboardType] then
            local container = self.Leaderboards[leaderboardType].Container
            
            -- Clear existing
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            -- Add entries
            for i, entry in ipairs(data) do
                self:CreateLeaderboardEntry(container, i, entry.name, entry.value, entry.name == LocalPlayer.Name)
            end
            
            -- Update your rank (sample)
            self.Leaderboards[leaderboardType].YourRankLabel.Text = "Your Rank: #42"
            self.Leaderboards[leaderboardType].YourValueLabel.Text = Utilities:FormatNumber(12345)
        end
    end
end

-- ========================================
-- PROFILE UI MODULE
-- ========================================
UIModules.ProfileUI = {}

function UIModules.ProfileUI:ShowProfile(player)
    -- Create profile overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "ProfileOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 700
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Profile window
    local profileWindow = Instance.new("Frame")
    profileWindow.Name = "ProfileWindow"
    profileWindow.Size = UDim2.new(0, 800, 0, 600)
    profileWindow.Position = UDim2.new(0.5, -400, 0.5, -300)
    profileWindow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    profileWindow.ZIndex = 701
    profileWindow.Parent = overlay
    
    Utilities:CreateCorner(profileWindow, 20)
    Utilities:CreateShadow(profileWindow, 0.5, 30)
    
    -- Animate in
    profileWindow.Position = UDim2.new(0.5, -400, 0.5, -300)
    profileWindow.Size = UDim2.new(0, 0, 0, 0)
    Utilities:Tween(profileWindow, {
        Size = UDim2.new(0, 800, 0, 600),
        Position = UDim2.new(0.5, -400, 0.5, -300)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Header with gradient
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 150)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 702
    header.Parent = profileWindow
    
    Utilities:CreateCorner(header, 20)
    Utilities:CreateGradient(header, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.Primary),
        ColorSequenceKeypoint.new(1, CLIENT_CONFIG.COLORS.Secondary)
    })
    
    -- Profile picture
    local profilePic = Instance.new("ImageLabel")
    profilePic.Size = UDim2.new(0, 120, 0, 120)
    profilePic.Position = UDim2.new(0, 30, 0.5, -60)
    profilePic.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    profilePic.Image = Services.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    profilePic.ZIndex = 703
    profilePic.Parent = header
    
    Utilities:CreateCorner(profilePic, 60)
    Utilities:CreateStroke(profilePic, CLIENT_CONFIG.COLORS.White, 4)
    
    -- Player name
    local nameLabel = UIComponents:CreateLabel(header, player.DisplayName, UDim2.new(0.5, -170, 0, 40), UDim2.new(0, 170, 0, 20), 28)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    nameLabel.Font = CLIENT_CONFIG.FONTS.Display
    nameLabel.ZIndex = 703
    
    -- Username if different
    if player.Name ~= player.DisplayName then
        local usernameLabel = UIComponents:CreateLabel(header, "@" .. player.Name, UDim2.new(0.5, -170, 0, 30), UDim2.new(0, 170, 0, 65), 16)
        usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
        usernameLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
        usernameLabel.TextTransparency = 0.3
        usernameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        usernameLabel.ZIndex = 703
    end
    
    -- Level/Status
    local levelLabel = UIComponents:CreateLabel(header, "Level 42 • Tycoon Master", UDim2.new(0.5, -170, 0, 30), UDim2.new(0, 170, 0, 100), 16)
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    levelLabel.ZIndex = 703
    
    -- Action buttons
    if player ~= LocalPlayer then
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Size = UDim2.new(0, 300, 0, 40)
        buttonContainer.Position = UDim2.new(1, -320, 0.5, -20)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.ZIndex = 703
        buttonContainer.Parent = header
        
        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonLayout.Padding = UDim.new(0, 10)
        buttonLayout.Parent = buttonContainer
        
        -- Add friend button
        local friendButton = UIComponents:CreateButton(buttonContainer, "Add Friend", UDim2.new(0, 90, 1, 0), nil, function()
            -- TODO: Add friend
        end)
        friendButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
        friendButton.ZIndex = 704
        
        -- Trade button
        local tradeButton = UIComponents:CreateButton(buttonContainer, "Trade", UDim2.new(0, 90, 1, 0), nil, function()
            UIModules.TradingUI:InitiateTrade(player)
            overlay:Destroy()
        end)
        tradeButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Info
        tradeButton.ZIndex = 704
        
        -- Battle button
        local battleButton = UIComponents:CreateButton(buttonContainer, "Battle", UDim2.new(0, 90, 1, 0), nil, function()
            UIModules.BattleUI:ChallengePlayer(player)
            overlay:Destroy()
        end)
        battleButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
        battleButton.ZIndex = 704
    end
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 24
    closeButton.ZIndex = 704
    closeButton.Parent = header
    
    closeButton.MouseButton1Click:Connect(function()
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Close)
        Utilities:Tween(profileWindow, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        wait(0.3)
        overlay:Destroy()
    end)
    
    -- Content tabs
    local tabs = {
        {
            Name = "Stats",
            Init = function(parent)
                self:ShowProfileStats(parent, player)
            end
        },
        {
            Name = "Pets",
            Init = function(parent)
                self:ShowProfilePets(parent, player)
            end
        },
        {
            Name = "Achievements",
            Init = function(parent)
                self:ShowProfileAchievements(parent, player)
            end
        },
        {
            Name = "Badges",
            Init = function(parent)
                self:ShowProfileBadges(parent, player)
            end
        }
    }
    
    UIComponents:CreateTab(profileWindow, tabs, UDim2.new(1, -20, 1, -170), UDim2.new(0, 10, 0, 160))
end

function UIModules.ProfileUI:ShowProfileStats(parent, player)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, -20, 0, 600)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = scrollFrame
    
    -- Stats grid
    local statsGrid = Instance.new("UIGridLayout")
    statsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    statsGrid.CellSize = UDim2.new(0.5, -5, 0, 100)
    statsGrid.FillDirection = Enum.FillDirection.Horizontal
    statsGrid.Parent = statsContainer
    
    Utilities:CreatePadding(statsContainer, 10)
    
    -- Sample stats
    local stats = {
        {title = "Total Wealth", value = "1.5M", icon = "💰", color = CLIENT_CONFIG.COLORS.Warning},
        {title = "Pets Owned", value = "127", icon = "🐾", color = CLIENT_CONFIG.COLORS.Primary},
        {title = "Battle Wins", value = "342", icon = "⚔️", color = CLIENT_CONFIG.COLORS.Success},
        {title = "Trades Completed", value = "89", icon = "🤝", color = CLIENT_CONFIG.COLORS.Info},
        {title = "Play Time", value = "127h", icon = "⏱️", color = CLIENT_CONFIG.COLORS.Secondary},
        {title = "Achievements", value = "45/100", icon = "🏆", color = CLIENT_CONFIG.COLORS.Accent}
    }
    
    for _, stat in ipairs(stats) do
        local statCard = Instance.new("Frame")
        statCard.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
        statCard.Parent = statsContainer
        
        Utilities:CreateCorner(statCard, 12)
        Utilities:CreatePadding(statCard, 15)
        
        -- Icon
        local iconLabel = UIComponents:CreateLabel(statCard, stat.icon, UDim2.new(0, 50, 0, 50), UDim2.new(0, 0, 0, 0), 36)
        
        -- Title
        local titleLabel = UIComponents:CreateLabel(statCard, stat.title, UDim2.new(1, -60, 0, 25), UDim2.new(0, 60, 0, 10), 14)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        titleLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        
        -- Value
        local valueLabel = UIComponents:CreateLabel(statCard, stat.value, UDim2.new(1, -60, 0, 35), UDim2.new(0, 60, 0, 35), 24)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.TextColor3 = stat.color
        valueLabel.Font = CLIENT_CONFIG.FONTS.Display
    end
    
    -- Update canvas
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, statsGrid.AbsoluteContentSize.Y + 20)
end

function UIModules.ProfileUI:ShowProfilePets(parent, player)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local petsGrid = Instance.new("UIGridLayout")
    petsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    petsGrid.CellSize = UDim2.new(0, 120, 0, 140)
    petsGrid.FillDirection = Enum.FillDirection.Horizontal
    petsGrid.Parent = scrollFrame
    
    -- Note for other players
    if player ~= LocalPlayer then
        local noteLabel = UIComponents:CreateLabel(parent, "This player's pet collection is private", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 18)
        noteLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noteLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    else
        -- Show own pets
        -- TODO: Load pets
    end
end

function UIModules.ProfileUI:ShowProfileAchievements(parent, player)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local achievementList = Instance.new("Frame")
    achievementList.Size = UDim2.new(1, -20, 0, 800)
    achievementList.BackgroundTransparency = 1
    achievementList.Parent = scrollFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = achievementList
    
    Utilities:CreatePadding(achievementList, 10)
    
    -- Sample achievements
    local achievements = {
        {name = "First Steps", desc = "Open your first egg", icon = "🥚", unlocked = true, tier = "Bronze"},
        {name = "Pet Collector", desc = "Collect 10 different pets", icon = "🐾", unlocked = true, tier = "Bronze"},
        {name = "Millionaire", desc = "Earn 1,000,000 coins", icon = "💰", unlocked = true, tier = "Silver"},
        {name = "Battle Master", desc = "Win 100 battles", icon = "⚔️", unlocked = false, tier = "Gold"},
        {name = "Legendary Trainer", desc = "Own a legendary pet", icon = "✨", unlocked = false, tier = "Gold"}
    }
    
    for _, achievement in ipairs(achievements) do
        local achievementCard = Instance.new("Frame")
        achievementCard.Size = UDim2.new(1, 0, 0, 80)
        achievementCard.BackgroundColor3 = achievement.unlocked and CLIENT_CONFIG.COLORS.White or Color3.fromRGB(230, 230, 230)
        achievementCard.Parent = achievementList
        
        Utilities:CreateCorner(achievementCard, 12)
        Utilities:CreatePadding(achievementCard, 15)
        
        -- Icon
        local iconLabel = UIComponents:CreateLabel(achievementCard, achievement.icon, UDim2.new(0, 50, 0, 50), UDim2.new(0, 0, 0.5, -25), 36)
        iconLabel.TextTransparency = achievement.unlocked and 0 or 0.5
        
        -- Info
        local nameLabel = UIComponents:CreateLabel(achievementCard, achievement.name, UDim2.new(1, -150, 0, 25), UDim2.new(0, 60, 0, 10), 16)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        nameLabel.TextColor3 = achievement.unlocked and CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(150, 150, 150)
        
        local descLabel = UIComponents:CreateLabel(achievementCard, achievement.desc, UDim2.new(1, -150, 0, 25), UDim2.new(0, 60, 0, 35), 14)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        
        -- Tier badge
        local tierColors = {
            Bronze = Color3.fromRGB(205, 127, 50),
            Silver = Color3.fromRGB(192, 192, 192),
            Gold = Color3.fromRGB(255, 215, 0)
        }
        
        local tierBadge = Instance.new("Frame")
        tierBadge.Size = UDim2.new(0, 80, 0, 25)
        tierBadge.Position = UDim2.new(1, -90, 0.5, -12.5)
        tierBadge.BackgroundColor3 = tierColors[achievement.tier] or CLIENT_CONFIG.COLORS.Primary
        tierBadge.Parent = achievementCard
        
        Utilities:CreateCorner(tierBadge, 12)
        
        local tierLabel = UIComponents:CreateLabel(tierBadge, achievement.tier, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 12)
        tierLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
        tierLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        
        if not achievement.unlocked then
            tierBadge.BackgroundTransparency = 0.5
        end
    end
    
    -- Update canvas
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end

-- ========================================
-- CLAN UI MODULE
-- ========================================
UIModules.ClanUI = {}

function UIModules.ClanUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main clan frame
    local clanFrame = UIComponents:CreateFrame(MainUI.MainContainer, "ClanFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    clanFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = clanFrame
    
    -- Header
    local header = UIComponents:CreateFrame(clanFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    
    local headerLabel = UIComponents:CreateLabel(header, "⚔️ Clan System ⚔️", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
    headerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    headerLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Check if player is in a clan
    if LocalData.PlayerData and LocalData.PlayerData.clan.id then
        self:ShowClanInterface()
    else
        self:ShowNoClanInterface()
    end
end

function UIModules.ClanUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

function UIModules.ClanUI:ShowNoClanInterface()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 1, -80)
    container.Position = UDim2.new(0, 10, 0, 70)
    container.BackgroundTransparency = 1
    container.Parent = self.Frame
    
    -- Create clan section
    local createSection = Instance.new("Frame")
    createSection.Size = UDim2.new(1, 0, 0, 300)
    createSection.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    createSection.Parent = container
    
    Utilities:CreateCorner(createSection, 12)
    Utilities:CreatePadding(createSection, 20)
    
    local createTitle = UIComponents:CreateLabel(createSection, "Create Your Own Clan", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 24)
    createTitle.Font = CLIENT_CONFIG.FONTS.Display
    
    local createDesc = UIComponents:CreateLabel(createSection, "Start your own clan and invite friends to join!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 40), 16)
    createDesc.TextColor3 = Color3.fromRGB(100, 100, 100)
    createDesc.TextWrapped = true
    
    -- Clan name input
    local nameInput = UIComponents:CreateTextBox(createSection, "Enter clan name...", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 100))
    
    -- Clan tag input
    local tagInput = UIComponents:CreateTextBox(createSection, "Tag (2-5 chars)", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 150))
    
    -- Cost display
    local costLabel = UIComponents:CreateLabel(createSection, "Cost: 💰 50,000 Coins", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 200), 18)
    costLabel.TextColor3 = CLIENT_CONFIG.COLORS.Warning
    costLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Create button
    local createButton = UIComponents:CreateButton(createSection, "Create Clan", UDim2.new(0, 200, 0, 50), UDim2.new(0.5, -100, 1, -60), function()
        self:CreateClan(nameInput.Text, tagInput.Text)
    end)
    createButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    
    -- Browse clans section
    local browseSection = Instance.new("Frame")
    browseSection.Size = UDim2.new(1, 0, 1, -320)
    browseSection.Position = UDim2.new(0, 0, 0, 320)
    browseSection.BackgroundTransparency = 1
    browseSection.Parent = container
    
    local browseTitle = UIComponents:CreateLabel(browseSection, "Browse Clans", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 20)
    browseTitle.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local clanList = UIComponents:CreateScrollingFrame(browseSection, UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40))
    
    -- TODO: Load clan list
end

function UIModules.ClanUI:ShowClanInterface()
    -- Create tabs for clan interface
    local tabs = {
        {
            Name = "Overview",
            Init = function(parent)
                self:CreateClanOverview(parent)
            end
        },
        {
            Name = "Members",
            Init = function(parent)
                self:CreateMembersList(parent)
            end
        },
        {
            Name = "Treasury",
            Init = function(parent)
                self:CreateTreasury(parent)
            end
        },
        {
            Name = "Wars",
            Init = function(parent)
                self:CreateClanWars(parent)
            end
        }
    }
    
    UIComponents:CreateTab(self.Frame, tabs, UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
end

function UIModules.ClanUI:CreateClan(name, tag)
    if name == "" or tag == "" then
        NotificationSystem:SendNotification("Error", "Please enter a clan name and tag", "error")
        return
    end
    
    local success, result = RemoteFunctions.CreateClan:InvokeServer(name, tag)
    
    if success then
        NotificationSystem:SendNotification("Success", "Clan created successfully!", "success")
        self:ShowClanInterface()
    else
        NotificationSystem:SendNotification("Error", result or "Failed to create clan", "error")
    end
end

-- ========================================
-- SPECIAL EFFECTS MODULE
-- ========================================
local SpecialEffects = {}

function SpecialEffects:CreateRainbowText(textLabel)
    spawn(function()
        local hue = 0
        while textLabel.Parent do
            hue = (hue + 1) % 360
            textLabel.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
            Services.RunService.Heartbeat:Wait()
        end
    end)
end

function SpecialEffects:CreateGlowEffect(frame, color)
    local glow = Instance.new("ImageLabel")
    glow.Name = "GlowEffect"
    glow.Size = UDim2.new(1, 30, 1, 30)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = color or CLIENT_CONFIG.COLORS.Primary
    glow.ZIndex = frame.ZIndex - 1
    glow.Parent = frame.Parent
    
    -- Animate glow
    spawn(function()
        while glow.Parent do
            Utilities:Tween(glow, {
                Size = UDim2.new(1, 40, 1, 40),
                ImageTransparency = 0.7
            }, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(1)
            Utilities:Tween(glow, {
                Size = UDim2.new(1, 30, 1, 30),
                ImageTransparency = 0.5
            }, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(1)
        end
    end)
    
    return glow
end

function SpecialEffects:CreateShineEffect(frame)
    local shine = Instance.new("Frame")
    shine.Name = "ShineEffect"
    shine.Size = UDim2.new(0, 50, 2, 0)
    shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
    shine.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    shine.BackgroundTransparency = 0.8
    shine.Rotation = 45
    shine.ZIndex = frame.ZIndex + 1
    shine.Parent = frame
    
    local gradient = Utilities:CreateGradient(shine, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.White),
        ColorSequenceKeypoint.new(0.5, CLIENT_CONFIG.COLORS.White),
        ColorSequenceKeypoint.new(1, CLIENT_CONFIG.COLORS.White)
    })
    
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    -- Animate shine
    spawn(function()
        while shine.Parent do
            shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
            wait(3)
            Utilities:Tween(shine, {Position = UDim2.new(1.5, 0, -0.5, 0)}, TweenInfo.new(0.5, Enum.EasingStyle.Linear))
            wait(0.5)
        end
    end)
    
    return shine
end

function SpecialEffects:CreateFloatingEffect(frame, amplitude, speed)
    amplitude = amplitude or 10
    speed = speed or 2
    
    spawn(function()
        local startY = frame.Position.Y.Offset
        local time = 0
        
        while frame.Parent do
            time = time + Services.RunService.Heartbeat:Wait()
            local offset = math.sin(time * speed) * amplitude
            frame.Position = UDim2.new(
                frame.Position.X.Scale,
                frame.Position.X.Offset,
                frame.Position.Y.Scale,
                startY + offset
            )
        end
    end)
end

function SpecialEffects:CreatePulseEffect(frame, scale)
    scale = scale or 1.1
    
    spawn(function()
        while frame.Parent do
            Utilities:Tween(frame, {Size = UDim2.new(
                frame.Size.X.Scale * scale,
                frame.Size.X.Offset * scale,
                frame.Size.Y.Scale * scale,
                frame.Size.Y.Offset * scale
            )}, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(0.5)
            Utilities:Tween(frame, {Size = UDim2.new(
                frame.Size.X.Scale / scale,
                frame.Size.X.Offset / scale,
                frame.Size.Y.Scale / scale,
                frame.Size.Y.Offset / scale
            )}, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            wait(0.5)
        end
    end)
end

-- ========================================
-- BATTLE PASS UI MODULE
-- ========================================
UIModules.BattlePassUI = {}

function UIModules.BattlePassUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create main battle pass frame
    local battlePassFrame = UIComponents:CreateFrame(MainUI.MainContainer, "BattlePassFrame", UDim2.new(1, -110, 1, -90), UDim2.new(0, 100, 0, 80))
    battlePassFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    
    self.Frame = battlePassFrame
    
    -- Header
    local header = UIComponents:CreateFrame(battlePassFrame, "Header", UDim2.new(1, 0, 0, 100), UDim2.new(0, 0, 0, 0))
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    
    Utilities:CreateGradient(header, {
        ColorSequenceKeypoint.new(0, CLIENT_CONFIG.COLORS.Primary),
        ColorSequenceKeypoint.new(1, CLIENT_CONFIG.COLORS.Secondary)
    })
    
    local titleLabel = UIComponents:CreateLabel(header, "🌟 Battle Pass Season 1 🌟", UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 10), 28)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    
    -- Season timer
    local timerLabel = UIComponents:CreateLabel(header, "28 Days Remaining", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 45), 16)
    timerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    timerLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Level progress
    local levelContainer = Instance.new("Frame")
    levelContainer.Size = UDim2.new(1, -40, 0, 30)
    levelContainer.Position = UDim2.new(0, 20, 1, -40)
    levelContainer.BackgroundTransparency = 1
    levelContainer.Parent = header
    
    local levelLabel = UIComponents:CreateLabel(levelContainer, "Level 1", UDim2.new(0, 80, 1, 0), UDim2.new(0, 0, 0, 0), 18)
    levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    local xpBar = UIComponents:CreateProgressBar(levelContainer, UDim2.new(1, -200, 0, 20), UDim2.new(0, 90, 0.5, -10), 0, 1000)
    xpBar.Fill.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
    
    local levelEndLabel = UIComponents:CreateLabel(levelContainer, "Level 2", UDim2.new(0, 80, 1, 0), UDim2.new(1, -80, 0, 0), 18)
    levelEndLabel.TextXAlignment = Enum.TextXAlignment.Right
    levelEndLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelEndLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Premium upgrade button
    if not (LocalData.PlayerData and LocalData.PlayerData.battlePass.premiumOwned) then
        local upgradeButton = UIComponents:CreateButton(header, "Upgrade to Premium", UDim2.new(0, 150, 0, 35), UDim2.new(1, -160, 0, 10), function()
            self:ShowPremiumUpgrade()
        end)
        upgradeButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
        upgradeButton.ZIndex = header.ZIndex + 1
        
        SpecialEffects:CreateGlowEffect(upgradeButton, CLIENT_CONFIG.COLORS.Warning)
    end
    
    -- Rewards track
    local rewardsContainer = Instance.new("ScrollingFrame")
    rewardsContainer.Size = UDim2.new(1, -20, 1, -120)
    rewardsContainer.Position = UDim2.new(0, 10, 0, 110)
    rewardsContainer.BackgroundTransparency = 1
    rewardsContainer.ScrollBarThickness = 12
    rewardsContainer.CanvasSize = UDim2.new(5, 0, 0, 0) -- Horizontal scrolling
    rewardsContainer.ScrollingDirection = Enum.ScrollingDirection.X
    rewardsContainer.Parent = battlePassFrame
    
    -- Create reward tiers
    self:CreateRewardTrack(rewardsContainer)
end

function UIModules.BattlePassUI:CreateRewardTrack(parent)
    local tiers = 100
    local tierWidth = 150
    local tierSpacing = 10
    
    for tier = 1, tiers do
        local tierFrame = Instance.new("Frame")
        tierFrame.Size = UDim2.new(0, tierWidth, 1, -20)
        tierFrame.Position = UDim2.new(0, (tier - 1) * (tierWidth + tierSpacing) + 10, 0, 10)
        tierFrame.BackgroundTransparency = 1
        tierFrame.Parent = parent
        
        -- Tier number
        local tierLabel = UIComponents:CreateLabel(tierFrame, "Tier " .. tier, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 16)
        tierLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        
        -- Free reward
        local freeReward = self:CreateRewardCard(tierFrame, "Free", UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 0, 40), {
            type = "coins",
            amount = tier * 1000,
            claimed = false,
            locked = tier > 1
        })
        
        -- Premium reward
        local premiumReward = self:CreateRewardCard(tierFrame, "Premium", UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 0, 130), {
            type = "gems",
            amount = tier * 10,
            claimed = false,
            locked = true,
            premium = true
        })
        
        -- Connection line
        if tier < tiers then
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0, tierSpacing, 0, 2)
            line.Position = UDim2.new(1, 0, 0, 80)
            line.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
            line.BorderSizePixel = 0
            line.Parent = tierFrame
        end
    end
end

function UIModules.BattlePassUI:CreateRewardCard(parent, label, size, position, rewardData)
    local card = Instance.new("Frame")
    card.Size = size
    card.Position = position
    card.BackgroundColor3 = rewardData.locked and Color3.fromRGB(200, 200, 200) or CLIENT_CONFIG.COLORS.White
    card.Parent = parent
    
    Utilities:CreateCorner(card, 8)
    
    if rewardData.premium and rewardData.locked then
        -- Add lock overlay
        local lockOverlay = Instance.new("Frame")
        lockOverlay.Size = UDim2.new(1, 0, 1, 0)
        lockOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
        lockOverlay.BackgroundTransparency = 0.5
        lockOverlay.ZIndex = card.ZIndex + 1
        lockOverlay.Parent = card
        
        Utilities:CreateCorner(lockOverlay, 8)
        
        local lockIcon = UIComponents:CreateLabel(lockOverlay, "🔒", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
        lockIcon.ZIndex = lockOverlay.ZIndex + 1
    end
    
    -- Reward icon
    local icon = ""
    if rewardData.type == "coins" then
        icon = "💰"
    elseif rewardData.type == "gems" then
        icon = "💎"
    elseif rewardData.type == "pet" then
        icon = "🥚"
    end
    
    local iconLabel = UIComponents:CreateLabel(card, icon, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 10), 24)
    
    -- Amount
    local amountLabel = UIComponents:CreateLabel(card, Utilities:FormatNumber(rewardData.amount), UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 40), 16)
    amountLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- Label
    local typeLabel = UIComponents:CreateLabel(card, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 1, -25), 12)
    typeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    if rewardData.claimed then
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
        card.BackgroundTransparency = 0.5
        
        local checkmark = UIComponents:CreateLabel(card, "✓", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 36)
        checkmark.TextColor3 = CLIENT_CONFIG.COLORS.White
        checkmark.TextTransparency = 0.7
    end
    
    return card
end

-- ========================================
-- MINIGAME UI MODULE
-- ========================================
UIModules.MinigameUI = {}

function UIModules.MinigameUI:StartMinigame(gameType)
    if gameType == "memory" then
        self:StartMemoryGame()
    elseif gameType == "catch" then
        self:StartCatchGame()
    elseif gameType == "quiz" then
        self:StartQuizGame()
    end
end

function UIModules.MinigameUI:StartMemoryGame()
    -- Create minigame overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "MinigameOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 800
    overlay.Parent = MainUI.ScreenGui
    
    -- Game container
    local gameContainer = Instance.new("Frame")
    gameContainer.Size = UDim2.new(0, 600, 0, 700)
    gameContainer.Position = UDim2.new(0.5, -300, 0.5, -350)
    gameContainer.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    gameContainer.ZIndex = 801
    gameContainer.Parent = overlay
    
    Utilities:CreateCorner(gameContainer, 20)
    Utilities:CreateShadow(gameContainer, 0.5, 30)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
    header.ZIndex = 802
    header.Parent = gameContainer
    
    Utilities:CreateCorner(header, 20)
    
    local titleLabel = UIComponents:CreateLabel(header, "🧠 Memory Match 🧠", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 24)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 803
    
    -- Score and timer
    local scoreLabel = UIComponents:CreateLabel(header, "Score: 0", UDim2.new(0.5, 0, 0, 25), UDim2.new(0, 20, 0, 45), 16)
    scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
    scoreLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    scoreLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    scoreLabel.ZIndex = 803
    
    local timerLabel = UIComponents:CreateLabel(header, "Time: 60s", UDim2.new(0.5, -20, 0, 25), UDim2.new(0.5, 0, 0, 45), 16)
    timerLabel.TextXAlignment = Enum.TextXAlignment.Right
    timerLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    timerLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    timerLabel.ZIndex = 803
    
    -- Game grid
    local gridContainer = Instance.new("Frame")
    gridContainer.Size = UDim2.new(1, -40, 1, -140)
    gridContainer.Position = UDim2.new(0, 20, 0, 100)
    gridContainer.BackgroundTransparency = 1
    gridContainer.ZIndex = 802
    gridContainer.Parent = gameContainer
    
    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.CellSize = UDim2.new(0.25, -7.5, 0.25, -7.5)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.Parent = gridContainer
    
    -- Create cards
    local cardPairs = {"🎀", "🌸", "🍓", "🌈", "⭐", "💖", "🦄", "🎂"}
    local allCards = {}
    
    -- Double the cards for pairs
    for _, emoji in ipairs(cardPairs) do
        table.insert(allCards, emoji)
        table.insert(allCards, emoji)
    end
    
    -- Shuffle
    for i = #allCards, 2, -1 do
        local j = math.random(i)
        allCards[i], allCards[j] = allCards[j], allCards[i]
    end
    
    -- Game state
    local flippedCards = {}
    local matchedPairs = 0
    local score = 0
    local canFlip = true
    
    -- Create card UI
    for i, cardValue in ipairs(allCards) do
        local card = Instance.new("TextButton")
        card.Name = "Card" .. i
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
        card.Text = ""
        card.ZIndex = 803
        card.Parent = gridContainer
        
        Utilities:CreateCorner(card, 8)
        
        local isFlipped = false
        local isMatched = false
        
        card.MouseButton1Click:Connect(function()
            if not canFlip or isFlipped or isMatched then return end
            
            -- Flip card
            isFlipped = true
            Utilities:Tween(card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White}, TweenInfo.new(0.2))
            card.Text = cardValue
            card.TextSize = 36
            
            table.insert(flippedCards, {card = card, value = cardValue, index = i})
            
            -- Check for match
            if #flippedCards == 2 then
                canFlip = false
                
                if flippedCards[1].value == flippedCards[2].value then
                    -- Match!
                    score = score + 100
                    scoreLabel.Text = "Score: " .. score
                    matchedPairs = matchedPairs + 1
                    
                    for _, cardData in ipairs(flippedCards) do
                        cardData.card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
                    end
                    
                    flippedCards = {}
                    canFlip = true
                    
                    -- Check win
                    if matchedPairs == #cardPairs then
                        self:EndMinigame(overlay, score, true)
                    end
                else
                    -- No match
                    wait(1)
                    
                    for _, cardData in ipairs(flippedCards) do
                        Utilities:Tween(cardData.card, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary}, TweenInfo.new(0.2))
                        cardData.card.Text = ""
                    end
                    
                    flippedCards = {}
                    canFlip = true
                end
            end
        end)
    end
    
    -- Timer
    local timeLeft = 60
    spawn(function()
        while timeLeft > 0 and overlay.Parent do
            wait(1)
            timeLeft = timeLeft - 1
            timerLabel.Text = "Time: " .. timeLeft .. "s"
            
            if timeLeft <= 10 then
                timerLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
            end
        end
        
        if overlay.Parent then
            self:EndMinigame(overlay, score, false)
        end
    end)
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = CLIENT_CONFIG.COLORS.White
    closeButton.Font = CLIENT_CONFIG.FONTS.Primary
    closeButton.TextSize = 24
    closeButton.ZIndex = 804
    closeButton.Parent = header
    
    closeButton.MouseButton1Click:Connect(function()
        overlay:Destroy()
    end)
end

function UIModules.MinigameUI:EndMinigame(overlay, score, won)
    -- Show results
    local resultFrame = Instance.new("Frame")
    resultFrame.Size = UDim2.new(0, 400, 0, 300)
    resultFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    resultFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    resultFrame.ZIndex = 900
    resultFrame.Parent = overlay
    
    Utilities:CreateCorner(resultFrame, 20)
    Utilities:CreateShadow(resultFrame, 0.5)
    
    local resultLabel = UIComponents:CreateLabel(resultFrame, won and "You Win!" or "Time's Up!", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 30), 32)
    resultLabel.TextColor3 = won and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Error
    resultLabel.Font = CLIENT_CONFIG.FONTS.Display
    resultLabel.ZIndex = 901
    
    local scoreLabel = UIComponents:CreateLabel(resultFrame, "Final Score: " .. score, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 90), 20)
    scoreLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    scoreLabel.ZIndex = 901
    
    -- Rewards
    local rewardCoins = score * 10
    local rewardGems = math.floor(score / 100) * 5
    
    local rewardsLabel = UIComponents:CreateLabel(resultFrame, "Rewards:", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 130), 18)
    rewardsLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    rewardsLabel.ZIndex = 901
    
    local coinsLabel = UIComponents:CreateLabel(resultFrame, "💰 " .. Utilities:FormatNumber(rewardCoins) .. " Coins", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 160), 16)
    coinsLabel.TextColor3 = CLIENT_CONFIG.COLORS.Warning
    coinsLabel.ZIndex = 901
    
    local gemsLabel = UIComponents:CreateLabel(resultFrame, "💎 " .. rewardGems .. " Gems", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 185), 16)
    gemsLabel.TextColor3 = CLIENT_CONFIG.COLORS.Primary
    gemsLabel.ZIndex = 901
    
    -- Claim button
    local claimButton = UIComponents:CreateButton(resultFrame, "Claim Rewards", UDim2.new(0, 200, 0, 50), UDim2.new(0.5, -100, 1, -70), function()
        -- TODO: Send rewards to server
        overlay:Destroy()
    end)
    claimButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    claimButton.ZIndex = 902
    
    -- Effects
    if won then
        ParticleSystem:CreateBurst(resultFrame, "star", UDim2.new(0.5, 0, 0.5, 0), 30)
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
    end
end

-- ========================================
-- DEBUG PANEL (Development Only)
-- ========================================
if game:GetService("RunService"):IsStudio() then
    local DebugPanel = {}
    
    function DebugPanel:Create()
        local panel = Instance.new("Frame")
        panel.Name = "DebugPanel"
        panel.Size = UDim2.new(0, 300, 0, 400)
        panel.Position = UDim2.new(1, -310, 1, -410)
        panel.BackgroundColor3 = Color3.new(0, 0, 0)
        panel.BackgroundTransparency = 0.3
        panel.Parent = MainUI.ScreenGui
        
        Utilities:CreateCorner(panel, 8)
        
        local title = UIComponents:CreateLabel(panel, "Debug Panel", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 16)
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Font = CLIENT_CONFIG.FONTS.Secondary
        
        local content = UIComponents:CreateScrollingFrame(panel, UDim2.new(1, -10, 1, -40), UDim2.new(0, 5, 0, 35))
        
        -- Add debug buttons
        local yOffset = 5
        
        local function AddDebugButton(text, callback)
            local btn = UIComponents:CreateButton(content, text, UDim2.new(1, -10, 0, 30), UDim2.new(0, 5, 0, yOffset), callback)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.new(1, 1, 1)
            yOffset = yOffset + 35
        end
        
        AddDebugButton("Give 1M Coins", function()
            print("Debug: Adding 1M coins")
        end)
        
        AddDebugButton("Give 1K Gems", function()
            print("Debug: Adding 1K gems")
        end)
        
        AddDebugButton("Open Legendary Egg", function()
            UIModules.ShopUI:OpenEgg({id = "legendary", name = "Legendary Egg", price = 0, currency = "Gems"})
        end)
        
        AddDebugButton("Test Notification", function()
            NotificationSystem:SendNotification("Test", "This is a test notification!", "info")
        end)
        
        AddDebugButton("Test Particles", function()
            ParticleSystem:CreateBurst(MainUI.MainContainer, "star", UDim2.new(0.5, 0, 0.5, 0), 50)
        end)
        
        AddDebugButton("Show Daily Reward", function()
            UIModules.DailyRewardUI:ShowDailyRewardWindow()
        end)
        
        AddDebugButton("Start Memory Game", function()
            UIModules.MinigameUI:StartMemoryGame()
        end)
        
        AddDebugButton("Show Profile", function()
            UIModules.ProfileUI:ShowProfile(LocalPlayer)
        end)
        
        content.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
    end
    
    DebugPanel:Create()
end

-- ========================================
-- FINAL INITIALIZATION
-- ========================================
print("Sanrio Tycoon Shop Client v5.0 loaded successfully!")
print("Total UI modules loaded:", #UIModules)

-- Return for external access
return {
    MainUI = MainUI,
    UIModules = UIModules,
    NotificationSystem = NotificationSystem,
    ParticleSystem = ParticleSystem,
    SpecialEffects = SpecialEffects,
    Utilities = Utilities,
    LocalData = LocalData,
    CLIENT_CONFIG = CLIENT_CONFIG
}