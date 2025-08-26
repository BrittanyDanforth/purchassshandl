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

-- Continue in Part 2...