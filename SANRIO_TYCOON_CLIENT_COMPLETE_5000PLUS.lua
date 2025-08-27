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
-- ADVANCED MODULE LOADING
-- ========================================
local AdvancedModules = {}
local ModulesFolder = Services.ReplicatedStorage:WaitForChild("Modules", 5)

if ModulesFolder then
    local SharedFolder = ModulesFolder:FindFirstChild("Shared")
    local ClientFolder = ModulesFolder:FindFirstChild("Client")
    
    if SharedFolder then
        if SharedFolder:FindFirstChild("ClientDataManager") then
            AdvancedModules.ClientDataManager = require(SharedFolder.ClientDataManager)
        end
        if SharedFolder:FindFirstChild("Janitor") then
            AdvancedModules.Janitor = require(SharedFolder.Janitor)
        end
        if SharedFolder:FindFirstChild("DeltaNetworking") then
            AdvancedModules.DeltaNetworking = require(SharedFolder.DeltaNetworking)
        end
    end
    
    if ClientFolder then
        if ClientFolder:FindFirstChild("WindowManager") then
            AdvancedModules.WindowManager = require(ClientFolder.WindowManager)
        end
    end
end

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
local RemoteEventsFolder = Services.ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctionsFolder = Services.ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents = {}
local RemoteFunctions = {}

-- Get all remote events
for _, obj in ipairs(RemoteEventsFolder:GetChildren()) do
    if obj:IsA("RemoteEvent") then
        RemoteEvents[obj.Name] = obj
    end
end

-- Get all remote functions
for _, obj in ipairs(RemoteFunctionsFolder:GetChildren()) do
    if obj:IsA("RemoteFunction") then
        RemoteFunctions[obj.Name] = obj
    end
end

-- ========================================
-- INITIALIZE MANAGERS
-- ========================================
local DataManager = nil
local WindowManager = nil
local MainJanitor = nil

-- Initialize managers only if modules exist
if AdvancedModules.ClientDataManager then
    DataManager = AdvancedModules.ClientDataManager.new()
end

if AdvancedModules.WindowManager then
    WindowManager = AdvancedModules.WindowManager.new(PlayerGui)
end

if AdvancedModules.Janitor then
    MainJanitor = AdvancedModules.Janitor.new()
end

-- Connect delta networking if available
local DeltaReceiver = nil
if DataManager and AdvancedModules.DeltaNetworking and RemoteEvents.DataUpdated then
    DeltaReceiver = AdvancedModules.DeltaNetworking.newClient(RemoteEvents.DataUpdated, DataManager)
    -- Note: DeltaReceiver manages its own cleanup
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
    
    -- ZIndex layers for proper UI stacking
    ZINDEX = {
        Background = 1,
        Default = 10,
        Card = 20,
        Window = 50,
        Modal = 100,
        Overlay = 200,
        Tooltip = 999,
        Debug = 1000
    },
    
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
        Surface = Color3.fromRGB(255, 250, 250),      -- Slightly off-white
        Dark = Color3.fromRGB(50, 50, 50),            -- Dark
        White = Color3.fromRGB(255, 255, 255),        -- White
        TextSecondary = Color3.fromRGB(150, 150, 150), -- Gray text
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
    
    -- Sounds (all tested and working)
    SOUNDS = {
        Click = "rbxasset://sounds/clickfast.wav",     -- Working click sound
        Open = "rbxasset://sounds/uuhhh.mp3",          -- Default open sound
        Close = "rbxasset://sounds/switch.mp3",        -- Default close sound  
        Success = "rbxasset://sounds/victory.wav",     -- Default success sound
        Error = "rbxasset://sounds/error.wav",         -- Default error sound
        Notification = "rbxasset://sounds/electronicpingshort.wav",  -- Default notification
        CaseOpen = "rbxasset://sounds/snap.mp3",       -- Default case open
        Legendary = "rbxasset://sounds/victory.wav",   -- Default legendary sound
        Purchase = "rbxasset://sounds/buy.wav",        -- Default purchase sound
        LevelUp = "rbxasset://sounds/victory.wav"      -- Default level up sound
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
    PlayerData = {
        -- Initialize with default values to prevent nil errors
        currencies = {
            coins = 0,
            gems = 0,
            tickets = 0
        },
        pets = {},
        equippedPets = {},
        inventory = {},
        statistics = {},
        dailyRewards = {
            lastClaimed = 0,
            streak = 0
        }
    },
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

-- Sound cache to prevent repeated loading attempts
Utilities.SoundCache = {}
Utilities.FailedSounds = {}  -- Track sounds that failed to load

function Utilities:PlaySound(soundId)
    if not LocalData.Settings.SFXEnabled then return end
    
    -- Skip if we've already tried and failed to load this sound
    if self.FailedSounds[soundId] then
        return
    end
    
    -- Try to use cached sound
    local cachedSound = self.SoundCache[soundId]
    if cachedSound and cachedSound.Parent then
        cachedSound:Play()
        return
    end
    
    -- Create new sound
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = LocalData.Settings.SFXVolume or 0.5
    sound.Parent = workspace
    
    -- Preload the sound with error handling
    local success = pcall(function()
        Services.ContentProvider:PreloadAsync({sound})
    end)
    
    if success and sound.IsLoaded then
        -- Cache successful sound
        self.SoundCache[soundId] = sound
        sound:Play()
        
        -- Don't destroy cached sounds, reuse them
        sound.Ended:Connect(function()
            -- Just stop, don't destroy
            sound:Stop()
        end)
    else
        -- Mark as failed to prevent repeated attempts
        self.FailedSounds[soundId] = true
        sound:Destroy()
        
        -- Use fallback sound if available
        if soundId == CLIENT_CONFIG.SOUNDS.Click then
            -- Use Roblox default click sound as fallback
            local fallback = Instance.new("Sound")
            fallback.SoundId = "rbxasset://sounds/click.wav"
            fallback.Volume = LocalData.Settings.SFXVolume or 0.5
            fallback.Parent = workspace
            fallback:Play()
            fallback.Ended:Connect(function()
                fallback:Destroy()
            end)
        end
    end
end

function Utilities:FormatNumber(num)
    -- Handle nil or non-number values
    if not num or type(num) ~= "number" then
        return "0"
    end
    
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
    -- COMPLETELY DISABLE ALL SHADOWS - They're causing too many issues
    return {Destroy = function() end}  -- Return dummy object
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
    
    -- Store original properties for hover state
    button:SetAttribute("OriginalColor", button.BackgroundColor3)
    button:SetAttribute("OriginalSize", size or UDim2.new(0, 200, 0, 50))
    
    -- Track hover state
    local isHovering = false
    local currentTween = nil
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        isHovering = true
        if currentTween then currentTween:Cancel() end
        currentTween = Utilities:Tween(button, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Secondary}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(button, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 4)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    button.MouseLeave:Connect(function()
        isHovering = false
        if currentTween then currentTween:Cancel() end
        -- Use stored original color instead of hardcoded Primary
        local originalColor = button:GetAttribute("OriginalColor") or CLIENT_CONFIG.COLORS.Primary
        currentTween = Utilities:Tween(button, {BackgroundColor3 = originalColor}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(button, {Size = button:GetAttribute("OriginalSize") or size or UDim2.new(0, 200, 0, 50)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
    end)
    
    button.MouseButton1Click:Connect(function()
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Click)
        
        -- More physical click animation with scale and position
        local originalSize = button.Size
        local originalPosition = button.Position
        local corner = button:FindFirstChildOfClass("UICorner")
        
        -- Squish down with scale for more natural feel
        Services.TweenService:Create(button, CLIENT_CONFIG.TWEEN_INFO.Fast, {
            Size = UDim2.new(originalSize.X.Scale * 0.95, originalSize.X.Offset, originalSize.Y.Scale * 0.95, originalSize.Y.Offset),
            Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, originalPosition.Y.Scale, originalPosition.Y.Offset + 2)
        }):Play()
        
        if corner then
            -- Make corners slightly rounder on press
            Services.TweenService:Create(corner, CLIENT_CONFIG.TWEEN_INFO.Fast, {
                CornerRadius = UDim.new(0, 12)
            }):Play()
        end
        
        task.wait(0.1)
        
        -- Bounce back up
        Services.TweenService:Create(button, CLIENT_CONFIG.TWEEN_INFO.Bounce, {
            Size = originalSize,
            Position = originalPosition
        }):Play()
        
        if corner then
            Services.TweenService:Create(corner, CLIENT_CONFIG.TWEEN_INFO.Bounce, {
                CornerRadius = UDim.new(0, 8)
            }):Play()
        end
        
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
    image.Image = imageId or ""
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
    -- Ensure values are valid
    value = value or 0
    maxValue = maxValue or 1
    if maxValue == 0 then maxValue = 1 end -- Prevent division by zero
    
    local container = Instance.new("Frame")
    container.Name = "ProgressBar"
    container.Size = size or UDim2.new(0, 200, 0, 20)
    container.Position = position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    container.Parent = parent
    
    Utilities:CreateCorner(container, 10)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(math.clamp(value / maxValue, 0, 1), 0, 1, 0)
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
    
    -- Store update function in a table to avoid setting properties on Frame
    local progressBar = {
        Frame = container,
        UpdateValue = function(newValue)
            value = math.clamp(newValue, 0, maxValue)
            Utilities:Tween(fill, {Size = UDim2.new(value / maxValue, 0, 1, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
            label.Text = string.format("%d / %d", value, maxValue)
        end
    }
    
    return progressBar
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
    
    -- Return toggle object with methods
    local toggle = {
        Frame = container,
        SetValue = function(newValue)
            if newValue ~= value then
                toggleButton.MouseButton1Click:Fire()
            end
        end,
        GetValue = function()
            return value
        end
    }
    
    return toggle
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
        
        -- Only initialize once
        if tab.Init then
            local initialized = false
            local originalInit = tab.Init
            tab.Init = function(frame)
                if not initialized then
                    initialized = true
                    originalInit(frame)
                end
            end
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
            task.wait(i * 0.05)
            self:CreateParticle(parent, particleType, position)
        end)
    end
end

function ParticleSystem:CreateTrail(parent, particleType, startPos, endPos, count)
    local steps = count or 10
    for i = 1, steps do
        spawn(function()
            task.wait(i * 0.05)
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
    
    -- Clean up any lingering overlays
    spawn(function()
        wait(0.1) -- Small delay to ensure everything is loaded
        for _, child in ipairs(screenGui:GetChildren()) do
            if string.find(child.Name, "Overlay") or 
               (child:IsA("Frame") and child.Size == UDim2.new(1, 0, 1, 0) and 
                child.BackgroundTransparency < 1) then
                print("[DEBUG] Cleaning up lingering overlay:", child.Name)
                child:Destroy()
            end
        end
    end)
    
    -- Create main container
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.Position = UDim2.new(0, 0, 0, 0)
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = screenGui
    
    self.MainContainer = mainContainer
    
    -- Create navigation bar FIRST (so we know its width)
    self:CreateNavigationBar()
    
    -- Create main UI panel that contains everything else - NO GAP
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainUIPanel"
    mainPanel.Size = UDim2.new(1, -80, 1, 0)  -- Full height, width minus nav bar exactly
    mainPanel.Position = UDim2.new(0, 80, 0, 0)  -- Positioned directly against nav bar, no gap
    mainPanel.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    mainPanel.BackgroundTransparency = 0  -- Solid background
    mainPanel.BorderSizePixel = 0
    mainPanel.ClipsDescendants = true
    mainPanel.ZIndex = 5  -- Behind other UI elements but above background
    mainPanel.Parent = mainContainer
    
    -- Add visual polish to main panel
    Utilities:CreateCorner(mainPanel, 0)  -- No corners for seamless look
    -- No shadow for main panel to prevent overlapping issues
    
    -- Store reference
    self.MainPanel = mainPanel
    
    -- Create currency display INSIDE the main panel
    self:CreateCurrencyDisplay()
    
    -- Create notification container
    self:CreateNotificationContainer()
    
    -- Apply UI scale
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = LocalData.Settings.UIScale
    uiScale.Parent = mainContainer
    
    -- Track active overlays properly
    self.ActiveOverlays = {}
    
    -- Proper overlay management methods
    function self:RegisterOverlay(overlayName, overlay)
        self.ActiveOverlays[overlayName] = overlay
    end
    
    function self:UnregisterOverlay(overlayName)
        if self.ActiveOverlays[overlayName] then
            self.ActiveOverlays[overlayName]:Destroy()
            self.ActiveOverlays[overlayName] = nil
        end
    end
    
    -- Clean up tooltips only (they should auto-destroy on mouse leave anyway)
    spawn(function()
        while self.ScreenGui and self.ScreenGui.Parent do
            wait(5) -- Less frequent check
            for _, child in ipairs(self.ScreenGui:GetChildren()) do
                -- Only clean up orphaned tooltips
                if string.find(child.Name, "NavTooltip_") then
                    child:Destroy()
                end
            end
        end
    end)
    
    return self
end

function MainUI:CreateCurrencyDisplay()
    local currencyFrame = UIComponents:CreateFrame(self.MainPanel or self.MainContainer, "CurrencyDisplay", UDim2.new(0, 400, 0, 60), UDim2.new(0, 10, 0, 10))
    currencyFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    currencyFrame.BorderSizePixel = 0
    currencyFrame.ZIndex = CLIENT_CONFIG.ZINDEX.Default + 10
    Utilities:CreateCorner(currencyFrame, 8)
    -- Shadow disabled to prevent overlap issues
    
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
    
    -- Set up reactive updates if DataManager is available
    if DataManager then
        -- Watch for coin changes
        DataManager:Watch("currencies.coins", function(coins)
            coinLabel.Text = Utilities:FormatNumber(coins or 0)
            
            -- Animation
            Utilities:Tween(coinLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            spawn(function()
                task.wait(0.3)
                Utilities:Tween(coinLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Dark}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            end)
        end)
        
        -- Watch for gem changes
        DataManager:Watch("currencies.gems", function(gems)
            gemLabel.Text = Utilities:FormatNumber(gems or 0)
            
            -- Animation
            Utilities:Tween(gemLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            spawn(function()
                task.wait(0.3)
                Utilities:Tween(gemLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Dark}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            end)
        end)
    else
        -- Fallback update function
        self.UpdateCurrency = function(currencies)
            -- Update values instantly
            coinLabel.Text = Utilities:FormatNumber(currencies.coins or 0)
            gemLabel.Text = Utilities:FormatNumber(currencies.gems or 0)
            
            -- Quick flash animation without blocking
            spawn(function()
                Utilities:Tween(coinLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                Utilities:Tween(gemLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                task.wait(0.3)
                Utilities:Tween(coinLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Dark}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                Utilities:Tween(gemLabel, {TextColor3 = CLIENT_CONFIG.COLORS.Dark}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            end)
        end
    end
end

function MainUI:CreateNavigationBar()
    -- Navigation bar that covers full height of screen
    local navBar = UIComponents:CreateFrame(self.MainContainer, "NavigationBar", UDim2.new(0, 80, 1, 0), UDim2.new(0, 0, 0, 0))
    navBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    navBar.BorderSizePixel = 0
    navBar.ClipsDescendants = false
    navBar.ZIndex = CLIENT_CONFIG.ZINDEX.Default
    -- No shadow for nav bar to prevent overlapping
    
    -- Create a container for buttons with proper padding from top
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 1, -20)
    buttonContainer.Position = UDim2.new(0, 0, 0, 10)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = navBar
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 10)
    layout.Parent = buttonContainer
    
    Utilities:CreatePadding(buttonContainer, 10)
    
    local navButtons = {
        {Name = "Shop", Icon = CLIENT_CONFIG.ICONS.Egg, Module = "ShopUI"},
        {Name = "Inventory", Icon = CLIENT_CONFIG.ICONS.Pet, Module = "InventoryUI"},
        {Name = "Trade", Icon = CLIENT_CONFIG.ICONS.Trade, Module = "TradingUI"},
        {Name = "Battle", Icon = CLIENT_CONFIG.ICONS.Battle, Module = "BattleUI"},
        {Name = "Quest", Icon = CLIENT_CONFIG.ICONS.Quest, Module = "QuestUI"},
        {Name = "Settings", Icon = CLIENT_CONFIG.ICONS.Settings, Module = "SettingsUI"}
    }
    
    -- Track hover states to prevent stuck pink buttons
    self.NavHoverStates = self.NavHoverStates or {}
    
    for _, nav in ipairs(navButtons) do
        local button = Instance.new("TextButton")
        button.Name = nav.Name .. "NavButton"
        button.Size = UDim2.new(1, 0, 0, 60)
        button.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
        button.Text = ""
        button.AutoButtonColor = false -- Disable Roblox hover effects
        button.ZIndex = CLIENT_CONFIG.ZINDEX.Default + 1
        button.Parent = buttonContainer
        
        Utilities:CreateCorner(button, 8)
        
        local icon = UIComponents:CreateImageLabel(button, nav.Icon, UDim2.new(0, 40, 0, 40), UDim2.new(0.5, -20, 0.5, -20))
        icon.ZIndex = CLIENT_CONFIG.ZINDEX.Default + 2
        
        -- Store hover state for this button
        self.NavHoverStates[button] = {
            originalColor = CLIENT_CONFIG.COLORS.Background,
            isHovered = false,
            activeTween = nil
        }
        
        button.MouseEnter:Connect(function()
            local state = self.NavHoverStates[button]
            if state.activeTween then
                state.activeTween:Cancel()
            end
            
            state.isHovered = true
            state.activeTween = Utilities:Tween(button, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            
            -- Create tooltip at screen level for proper layering
            local screenGui = self.ScreenGui
            local absolutePos = button.AbsolutePosition
            local absoluteSize = button.AbsoluteSize
            
            local tooltip = Instance.new("Frame")
            tooltip.Name = "NavTooltip_" .. nav.Name
            tooltip.Size = UDim2.new(0, 120, 0, 35)
            tooltip.Position = UDim2.new(0, absolutePos.X + absoluteSize.X + 10, 0, absolutePos.Y + (absoluteSize.Y - 35) / 2)
            tooltip.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
            tooltip.BackgroundTransparency = 0.05
            tooltip.BorderSizePixel = 0
            tooltip.ZIndex = CLIENT_CONFIG.ZINDEX.Tooltip
            tooltip.Parent = screenGui
            
            -- Create shadow for depth
            local shadow = Instance.new("ImageLabel")
            shadow.Name = "Shadow"
            shadow.Size = UDim2.new(1, 10, 1, 10)
            shadow.Position = UDim2.new(0, -5, 0, -5)
            shadow.BackgroundTransparency = 1
            shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            shadow.ImageColor3 = Color3.new(0, 0, 0)
            shadow.ImageTransparency = 0.7
            shadow.ZIndex = CLIENT_CONFIG.ZINDEX.Tooltip - 1
            shadow.Parent = tooltip
            
            Utilities:CreateCorner(tooltip, 8)
            Utilities:CreateCorner(shadow, 8)
            
            local tooltipText = UIComponents:CreateLabel(tooltip, nav.Name, UDim2.new(1, -10, 1, 0), UDim2.new(0, 5, 0, 0), 16)
            tooltipText.TextColor3 = CLIENT_CONFIG.COLORS.White
            tooltipText.TextXAlignment = Enum.TextXAlignment.Center
            tooltipText.Font = CLIENT_CONFIG.FONTS.Secondary
            tooltipText.ZIndex = CLIENT_CONFIG.ZINDEX.Tooltip + 1
            
            -- Animate in
            tooltip.BackgroundTransparency = 1
            tooltipText.TextTransparency = 1
            shadow.ImageTransparency = 1
            
            Utilities:Tween(tooltip, {BackgroundTransparency = 0.05}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            Utilities:Tween(tooltipText, {TextTransparency = 0}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            Utilities:Tween(shadow, {ImageTransparency = 0.7}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        end)
        
        button.MouseLeave:Connect(function()
            local state = self.NavHoverStates[button]
            if state.activeTween then
                state.activeTween:Cancel()
            end
            
            state.isHovered = false
            state.activeTween = Utilities:Tween(button, {BackgroundColor3 = state.originalColor}, CLIENT_CONFIG.TWEEN_INFO.Fast)
            
            -- Find and remove ALL tooltips with this name from screen
            local screenGui = self.ScreenGui
            for _, child in ipairs(screenGui:GetChildren()) do
                if child.Name == "NavTooltip_" .. nav.Name then
                    -- Immediately destroy without animation to prevent lingering
                    child:Destroy()
                end
            end
        end)
        
        button.MouseButton1Click:Connect(function()
            Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Click)
            
            -- Force clear hover state on click
            local state = self.NavHoverStates[button]
            if state then
                if state.activeTween then
                    state.activeTween:Cancel()
                end
                state.isHovered = false
                button.BackgroundColor3 = state.originalColor
            end
            
            -- Remove any lingering tooltip
            local screenGui = self.ScreenGui
            local tooltip = screenGui:FindFirstChild("NavTooltip_" .. nav.Name)
            if tooltip then
                tooltip:Destroy()
            end
            
            self:OpenModule(nav.Module)
        end)
    end
    
    -- Function to clean up all hover states
    self.CleanupNavigation = function()
        for btn, state in pairs(self.NavHoverStates) do
            if state.activeTween then
                state.activeTween:Cancel()
            end
            if btn and btn.Parent then
                btn.BackgroundColor3 = state.originalColor
            end
        end
        
        -- Remove all navigation tooltips
        local screenGui = self.ScreenGui
        for _, child in ipairs(screenGui:GetChildren()) do
            if string.find(child.Name, "NavTooltip_") then
                child:Destroy()
            end
        end
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
    -- Clean up any lingering hover states and tooltips
    if self.CleanupNavigation then
        self.CleanupNavigation()
    end
    
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
    notification.Position = UDim2.new(1, 0, 0, 0)  -- Start off-screen
    notification.Parent = MainUI.NotificationContainer
    
    -- Let the UIListLayout calculate position for one frame
    task.wait()
    
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
    
    -- Animate in from the correct Y position (set by UIListLayout)
    local finalY = notification.Position.Y
    notification.Position = UDim2.new(1, 0, finalY.Scale, finalY.Offset)
    Utilities:Tween(notification, {
        Position = UDim2.new(0, 0, finalY.Scale, finalY.Offset), 
        BackgroundTransparency = 0
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
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
        task.wait(0.3)
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
    
    -- Create main shop frame inside the main panel
    local shopFrame = UIComponents:CreateFrame(MainUI.MainPanel or MainUI.MainContainer, "ShopFrame", UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 80))
    shopFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    shopFrame.BackgroundTransparency = 0
    
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
    -- ==========================================================
    -- COMPLETE REWRITE - PROPER STATE MANAGEMENT
    -- ==========================================================
    
    -- Store reference to current scroll frame
    if self.CurrentEggScrollFrame and self.CurrentEggScrollFrame.Parent then
        self.CurrentEggScrollFrame:Destroy()
    end
    
    -- Clear everything in parent
    for _, child in ipairs(parent:GetChildren()) do
        child:Destroy()
    end
    
    -- Create main container (NOT a scrolling frame yet)
    local container = Instance.new("Frame")
    container.Name = "EggShopContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Create the actual scrolling frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "EggScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -10)
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = CLIENT_CONFIG.COLORS.Primary
    scrollFrame.ScrollBarImageTransparency = 0.5
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = container
    
    -- Store reference
    self.CurrentEggScrollFrame = scrollFrame
    
    -- Create grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "EggGridLayout"
    gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
    gridLayout.CellSize = UDim2.new(0, 200, 0, 280)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Loading state
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Name = "LoadingFrame"
    loadingFrame.Size = UDim2.new(1, 0, 0, 100)
    loadingFrame.BackgroundTransparency = 1
    loadingFrame.Parent = scrollFrame
    
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Size = UDim2.new(1, 0, 1, 0)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "Loading eggs..."
    loadingLabel.TextColor3 = CLIENT_CONFIG.COLORS.Dark
    loadingLabel.TextScaled = true
    loadingLabel.Font = CLIENT_CONFIG.FONTS.Primary or Enum.Font.Gotham
    loadingLabel.Parent = loadingFrame
    
    -- Get egg data
    task.spawn(function()
        task.wait(0.1) -- Small delay to ensure UI is ready
        
        local success, eggs = pcall(function()
            if RemoteFunctions.GetShopData then
                return RemoteFunctions.GetShopData:InvokeServer("eggs")
            end
        end)
        
        -- Remove loading
        if loadingFrame and loadingFrame.Parent then
            loadingFrame:Destroy()
        end
        
        -- Use test data if server call failed
        if not success or not eggs then
            eggs = {
                {id = "basic_egg", name = "Basic Egg", price = 100, currency = "coins", imageId = "rbxassetid://10883352204"},
                {id = "rare_egg", name = "Rare Egg", price = 500, currency = "gems", imageId = "rbxassetid://10883355122"},
                {id = "epic_egg", name = "Epic Egg", price = 1000, currency = "gems", imageId = "rbxassetid://10883356470"},
                {id = "legendary_egg", name = "Legendary Egg", price = 2500, currency = "gems", imageId = "rbxassetid://10883357885"}
            }
        end
        
        -- Create egg cards
        if eggs and type(eggs) == "table" then
            for i, eggData in ipairs(eggs) do
                if eggData and eggData.id then
                    local card = self:CreateEggCard(scrollFrame, eggData)
                    if card then
                        card.LayoutOrder = i
                    end
                end
            end
        end
        
        -- Update canvas size after cards are created
        task.wait(0.1)
        if gridLayout and gridLayout.Parent then
            local updateCanvas = function()
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 40)
            end
            
            gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
            updateCanvas() -- Initial update
        end
    end)
end

function UIModules.ShopUI:CreateEggCard(parent, eggData)
    -- ==========================================================
    -- REWRITTEN - CLEAN CARD CREATION
    -- ==========================================================
    if not eggData or not eggData.id then
        return nil
    end
    
    -- Create card container
    local card = Instance.new("Frame")
    card.Name = "EggCard_" .. eggData.id
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface or Color3.fromRGB(255, 255, 255)
    card.BorderSizePixel = 0
    card.Parent = parent
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    -- Add shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://7024272965"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(20, 20, 280, 280)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.ZIndex = 0
    shadow.Parent = card
    
    -- Create egg image
    local imageId = eggData.image or eggData.imageId or ""
    local eggImage = Instance.new("ImageLabel")
    eggImage.Name = "EggImage"
    eggImage.Size = UDim2.new(0, 120, 0, 120)
    eggImage.Position = UDim2.new(0.5, -60, 0, 20)
    eggImage.BackgroundTransparency = 1
    eggImage.ScaleType = Enum.ScaleType.Fit
    eggImage.Parent = card
    
    if imageId ~= "" and imageId ~= "rbxassetid://0" then
        eggImage.Image = imageId
    else
        -- Placeholder text
        eggImage.Image = ""
        local placeholderText = Instance.new("TextLabel")
        placeholderText.Size = UDim2.new(1, 0, 1, 0)
        placeholderText.BackgroundTransparency = 1
        placeholderText.Text = "?"
        placeholderText.TextScaled = true
        placeholderText.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary or Color3.fromRGB(150, 150, 150)
        placeholderText.Font = Enum.Font.SourceSansBold
        placeholderText.Parent = eggImage
    end
    
    -- Simple floating animation
    task.spawn(function()
        local startPos = eggImage.Position
        while card.Parent do
            eggImage:TweenPosition(UDim2.new(0.5, -60, 0, 15), "InOut", "Sine", 2, true)
            task.wait(2)
            if not card.Parent then break end
            eggImage:TweenPosition(startPos, "InOut", "Sine", 2, true)
            task.wait(2)
        end
    end)
    
    -- Egg name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -20, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 150)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = eggData.name or "Unknown Egg"
    nameLabel.TextScaled = true
    nameLabel.TextColor3 = CLIENT_CONFIG.COLORS.Text or Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = card
    
    -- Price section
    local priceFrame = Instance.new("Frame")
    priceFrame.Name = "PriceFrame"
    priceFrame.Size = UDim2.new(1, -20, 0, 30)
    priceFrame.Position = UDim2.new(0, 10, 0, 180)
    priceFrame.BackgroundTransparency = 1
    priceFrame.Parent = card
    
    -- Currency icon
    local currencyIcon = Instance.new("ImageLabel")
    currencyIcon.Size = UDim2.new(0, 24, 0, 24)
    currencyIcon.Position = UDim2.new(0, 0, 0.5, -12)
    currencyIcon.BackgroundTransparency = 1
    currencyIcon.Image = (eggData.currency == "gems" or eggData.currency == "Gems") and 
        "rbxassetid://6270808621" or "rbxassetid://6270808400"
    currencyIcon.Parent = priceFrame
    
    -- Price text
    local priceText = Instance.new("TextLabel")
    priceText.Size = UDim2.new(1, -30, 1, 0)
    priceText.Position = UDim2.new(0, 30, 0, 0)
    priceText.BackgroundTransparency = 1
    priceText.Text = tostring(eggData.price or 0)
    priceText.TextScaled = true
    priceText.TextColor3 = CLIENT_CONFIG.COLORS.Text or Color3.new(1, 1, 1)
    priceText.TextXAlignment = Enum.TextXAlignment.Left
    priceText.Font = Enum.Font.SourceSans
    priceText.Parent = priceFrame
    
    -- Buy button
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(1, -20, 0, 40)
    buyButton.Position = UDim2.new(0, 10, 1, -50)
    buyButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary or Color3.fromRGB(0, 170, 255)
    buyButton.Text = "Open"
    buyButton.TextScaled = true
    buyButton.TextColor3 = Color3.new(1, 1, 1)
    buyButton.Font = Enum.Font.SourceSansBold
    buyButton.Parent = card
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 8)
    buyCorner.Parent = buyButton
    
    buyButton.MouseButton1Click:Connect(function()
        self:OpenEgg(eggData)
    end)
    
    -- Hover effects
    card.MouseEnter:Connect(function()
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background or Color3.fromRGB(240, 240, 240)
    end)
    
    card.MouseLeave:Connect(function()
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface or Color3.fromRGB(255, 255, 255)
    end)
    
    return card
end

function UIModules.ShopUI:OpenEgg(eggData, count)
    -- Request egg opening from server with pcall protection
    local success, result = pcall(function()
        return RemoteFunctions.OpenCase:InvokeServer(eggData.id, count)
    end)
    
    if not success then
        -- If it failed, result is the error message
        NotificationSystem:SendNotification("Error", "Could not connect to server. Please try again.", "error")
        return -- Stop the function
    end
    
    -- Now the rest of your code can run safely
    if result.success then
        -- Open case opening UI
        UIModules.CaseOpeningUI:Open(result.results)
        
        -- ==========================================================
        -- INSTANT CURRENCY UPDATE - NO WAITING
        -- ==========================================================
        -- Update local data immediately
        if LocalData.PlayerData and LocalData.PlayerData.currencies then
            if result.newBalance then
                -- Update from server response
                LocalData.PlayerData.currencies = result.newBalance
            else
                -- Calculate locally if server doesn't send balance
                local currency = eggData.currency == "gems" and "gems" or "coins"
                local cost = eggData.price * (count or 1)
                LocalData.PlayerData.currencies[currency] = (LocalData.PlayerData.currencies[currency] or 0) - cost
            end
        end
        
        -- Update UI immediately
        if MainUI.UpdateCurrency then
            MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
        end
        -- ==========================================================
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
    
    -- Show loading indicator
    local loadingLabel = UIComponents:CreateLabel(scrollFrame, "Loading gamepasses...", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 20)
    loadingLabel.TextColor3 = CLIENT_CONFIG.COLORS.Dark
    
    -- Get gamepass data from server
    spawn(function()
        local success, gamepasses = pcall(function()
            if RemoteFunctions.GetShopData then
                return RemoteFunctions.GetShopData:InvokeServer("gamepasses")
            else
                -- Fallback data if remote doesn't exist
                return {
                    {id = 123456, name = "2x Cash Multiplier", description = "Double all cash earned!", price = 199, icon = "rbxassetid://10000002001"},
                    {id = 123457, name = "Auto Collector", description = "Automatically collect cash!", price = 299, icon = "rbxassetid://10000002002"},
                    {id = 123458, name = "VIP Status", description = "Exclusive VIP perks!", price = 999, icon = "rbxassetid://10000002003"},
                    {id = 123459, name = "Pet Storage +100", description = "Increase pet storage!", price = 149, icon = "rbxassetid://10000002004"},
                    {id = 123460, name = "Lucky Boost", description = "Increase rare drops by 25%!", price = 399, icon = "rbxassetid://10000002005"}
                }
            end
        end)
        
        -- Remove loading label
        if loadingLabel and loadingLabel.Parent then
            loadingLabel:Destroy()
        end
        
        if success and gamepasses then
            for i, passData in ipairs(gamepasses) do
                local passCard = self:CreateGamepassCard(scrollFrame, passData)
                passCard.LayoutOrder = i
            end
        else
            local errorLabel = UIComponents:CreateLabel(scrollFrame, "Failed to load gamepasses", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 20)
            errorLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
        end
    end)
    
    -- Update canvas size
    spawn(function()
        task.wait(0.1) -- Wait for layout to update
        if listLayout and listLayout.Parent then
            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
            end)
            -- Set initial size
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end
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
    -- ==========================================================
    -- COMPLETE REWRITE - PREVENT DOUBLE BUTTON CREATION
    -- ==========================================================
    
    -- First, destroy any existing case opening UI to prevent duplicates
    local existingOverlay = MainUI.ScreenGui:FindFirstChild("CaseOpeningOverlay")
    if existingOverlay then
        existingOverlay:Destroy()
    end
    
    -- Create fullscreen overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "CaseOpeningOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1  -- Start transparent
    overlay.ZIndex = 100
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in overlay
    Utilities:Tween(overlay, {BackgroundTransparency = 0.3}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Create main container
    local container = Instance.new("Frame")
    container.Name = "CaseOpeningContainer"
    container.Size = UDim2.new(0, 800, 0, 600)
    container.Position = UDim2.new(0.5, -400, 0.5, -300)
    container.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background or Color3.fromRGB(255, 255, 255)
    container.BorderSizePixel = 0
    container.ZIndex = 101
    container.Parent = overlay
    
    -- Add corner radius
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 20)
    containerCorner.Parent = container
    
    -- Animate container in
    container.Size = UDim2.new(0, 0, 0, 0)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Utilities:Tween(container, {
        Size = UDim2.new(0, 800, 0, 600),
        Position = UDim2.new(0.5, -400, 0.5, -300)
    }, CLIENT_CONFIG.TWEEN_INFO.Elastic)
    
    -- Process each result
    spawn(function()
        for i, result in ipairs(results) do
            task.wait(0.5) -- Delay between multiple opens
            self:ShowCaseAnimation(container, result, i, #results)
        end
        
        -- After all animations, create the collect button
        task.wait(1)
        
        -- Only create button if container still exists
        if not container or not container.Parent then return end
        
        -- Make sure we don't create duplicate buttons
        local existingButton = container:FindFirstChild("CollectButton")
        if existingButton then
            existingButton:Destroy()
        end
        
        -- Create collect button ONCE
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CollectButton"
        closeButton.Size = UDim2.new(0, 200, 0, 50)
        closeButton.Position = UDim2.new(0.5, -100, 1, -70)
        closeButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success or Color3.fromRGB(0, 255, 0)
        closeButton.Text = "Collect"
        closeButton.TextScaled = true
        closeButton.TextColor3 = Color3.new(1, 1, 1)
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.ZIndex = 105
        closeButton.Active = true
        closeButton.AutoButtonColor = true  -- Let Roblox handle hover
        closeButton.Parent = container
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeButton
        
        -- Single connection with immediate action
        closeButton.Activated:Connect(function()
            -- Immediately destroy button to prevent double clicks
            closeButton:Destroy()
            
            -- Play sound
            if CLIENT_CONFIG and CLIENT_CONFIG.SOUNDS and CLIENT_CONFIG.SOUNDS.Close then
                Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Close)
            end
            
            -- Animate out and destroy
            Utilities:Tween(container, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
            Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
            
            task.wait(0.3)
            if overlay and overlay.Parent then
                overlay:Destroy()
            end
        end)
    end)
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
    
    -- Title (don't spoil the result!)
    local titleLabel = UIComponents:CreateLabel(content, "Opening Case...", 
        UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 20), 24)
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 103
    
    -- Case spinner
    local spinnerFrame = Instance.new("Frame")
    spinnerFrame.Name = "SpinnerFrame"
    spinnerFrame.Size = UDim2.new(1, -100, 0, 200)
    spinnerFrame.Position = UDim2.new(0, 50, 0, 80)
    spinnerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40) -- Darker background for contrast
    spinnerFrame.BorderSizePixel = 2
    spinnerFrame.BorderColor3 = CLIENT_CONFIG.COLORS.Primary
    spinnerFrame.ClipsDescendants = true
    spinnerFrame.ZIndex = 102
    spinnerFrame.Parent = content
    
    Utilities:CreateCorner(spinnerFrame, 12)
    
    -- Add inner border for depth
    local innerBorder = Instance.new("Frame")
    innerBorder.Size = UDim2.new(1, -4, 1, -4)
    innerBorder.Position = UDim2.new(0, 2, 0, 2)
    innerBorder.BackgroundTransparency = 1
    innerBorder.BorderSizePixel = 1
    innerBorder.BorderColor3 = Color3.fromRGB(50, 50, 60)
    innerBorder.ZIndex = 102
    innerBorder.Parent = spinnerFrame
    
    -- Create case items
    local itemContainer = Instance.new("Frame")
    itemContainer.Name = "ItemContainer"
    local caseItems = result.caseItems or {}
    itemContainer.Size = UDim2.new(0, #caseItems * CLIENT_CONFIG.CASE_ITEM_WIDTH, 1, 0)
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
    local caseItems = result.caseItems or {}
    
    -- If no case items, create dummy spinner
    if #caseItems == 0 then
        -- Get the pet that was won
        local wonPetId = nil
        if result.pet then
            wonPetId = result.pet.petId
        elseif result.petData then
            wonPetId = result.petData.id
        end
        
        -- Create a dummy spinner with random pets
        local dummyPets = {"hello_kitty_classic", "my_melody_basic", "cinnamoroll_basic", "kuromi_basic", "pompompurin_basic"}
        for i = 1, 60 do
            if i == 50 and wonPetId then
                -- Place the won pet at position 50
                table.insert(caseItems, wonPetId)
            else
                -- Random pet
                table.insert(caseItems, dummyPets[math.random(1, #dummyPets)])
            end
        end
    end
    
    for i, petId in ipairs(caseItems) do
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
    task.wait(0.5)
    local winnerItem = itemContainer:GetChildren()[50]
    if winnerItem then
        for i = 1, 3 do
            Utilities:Tween(winnerItem, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning}, TweenInfo.new(0.2))
            task.wait(0.2)
            Utilities:Tween(winnerItem, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White}, TweenInfo.new(0.2))
            task.wait(0.2)
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
    
    task.wait(0.3)
    
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
    
    -- Get pet data safely
    local petData = result.petData or result.pet or {}
    local petId = petData.petId or petData.id or "unknown"
    local dbPetData = LocalData.PetDatabase and LocalData.PetDatabase[petId] or {}
    
    -- Merge data sources
    local finalPetData = {
        imageId = petData.imageId or dbPetData.imageId or "rbxassetid://0",
        rarity = petData.rarity or dbPetData.rarity or 1,
        displayName = petData.displayName or petData.name or dbPetData.displayName or "Unknown Pet"
    }
    
    -- For now, show image instead of 3D model
    local petImage = UIComponents:CreateImageLabel(petDisplay, finalPetData.imageId, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
    petImage.ZIndex = 104
    
    -- Add shine effect for rare pets (Epic or higher)
    if finalPetData.rarity >= 4 then
        petImage.ClipsDescendants = true
        -- Delay shine effect creation to avoid nil reference
        spawn(function()
            wait(0.1)
            if _G.SpecialEffects and _G.SpecialEffects.CreateShineEffect then
                _G.SpecialEffects:CreateShineEffect(petImage)
            end
        end)
    end
    
    -- Rarity effects
    local rarityColor = Utilities:GetRarityColor(finalPetData.rarity)
    
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
            task.wait(1)
            Utilities:Tween(glow, {Size = UDim2.new(1, 100, 1, 100), ImageTransparency = 0.5}, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1)
        end
    end)
    
    -- "You Got!" text
    local gotLabel = UIComponents:CreateLabel(resultFrame, "You Got!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 330), 32)
    gotLabel.Font = CLIENT_CONFIG.FONTS.Display
    gotLabel.TextColor3 = rarityColor
    gotLabel.ZIndex = 104
    
    -- Pet name
    local nameLabel = UIComponents:CreateLabel(resultFrame, finalPetData.displayName, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 370), 28)
    nameLabel.Font = CLIENT_CONFIG.FONTS.Display
    nameLabel.ZIndex = 104
    
    -- Variant label
    local variant = result.variant or (result.pet and result.pet.variant) or (result.petData and result.petData.variant) or "normal"
    if variant and variant ~= "normal" then
        local variantLabel = UIComponents:CreateLabel(resultFrame, "✨ " .. variant:upper() .. " VARIANT! ✨", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 410), 20)
        variantLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        variantLabel.TextColor3 = rarityColor
        variantLabel.ZIndex = 104
        
        -- Extra particles for special variants
        ParticleSystem:CreateBurst(resultFrame, "star", UDim2.new(0.5, 0, 0.5, 0), 20)
    end
    
    -- Rarity label
    local rarityNames = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "SECRET"}
    local rarity = finalPetData.rarity or 1
    local rarityLabel = UIComponents:CreateLabel(resultFrame, rarityNames[rarity] or "Unknown", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 440), 18)
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    rarityLabel.ZIndex = 104
    
    -- Sound effects
    if finalPetData.rarity >= 5 then
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Legendary)
    else
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
    end
    
    -- Particles based on rarity
    if finalPetData.rarity >= 4 then
        for i = 1, 50 do
            spawn(function()
                task.wait(i * 0.05)
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
    
    -- Initialize pet card cache for performance
    self.PetCardCache = {}
    self.MaxCacheSize = 100  -- Maximum cards to keep in cache
    
    -- Set up reactive updates if DataManager is available
    if DataManager and not self.PetWatcher then
        self.PetWatcher = DataManager:Watch("pets", function()
            if self.Frame and self.Frame.Visible then
                self:RefreshInventory()
            end
        end)
    end
    
    -- Create main inventory frame inside the main panel
    local inventoryFrame = UIComponents:CreateFrame(MainUI.MainPanel or MainUI.MainContainer, "InventoryFrame", UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 80))
    inventoryFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    inventoryFrame.BackgroundTransparency = 0
    
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
    
    -- ==========================================================
    -- DEBOUNCED SEARCH TO PREVENT LAG
    -- ==========================================================
    local searchDebounce = nil
    searchBox.Changed:Connect(function()
        -- Cancel any pending search
        if searchDebounce then
            task.cancel(searchDebounce)
        end
        
        -- Wait 0.3 seconds after user stops typing
        searchDebounce = task.spawn(function()
            task.wait(0.3)
            self:FilterPets(searchBox.Text)
            searchDebounce = nil
        end)
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

function UIModules.InventoryUI:CreateDropdown(parent, placeholder, options, size, position, onSelectCallback)
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
                    if onSelectCallback then
                        onSelectCallback(option)
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
    -- Create scrolling frame directly
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PetGridScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -10)
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = CLIENT_CONFIG.COLORS.Primary or Color3.fromRGB(0, 170, 255)
    scrollFrame.ScrollBarImageTransparency = 0.5
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = parent
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "PetGridLayout"
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.CellSize = UDim2.new(0, 150, 0, 180)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    self.PetGrid = scrollFrame
    self.GridLayout = gridLayout
    
    -- Update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function UIModules.InventoryUI:CreatePetCard(parent, petInstance, petData)
    -- ==========================================================
    -- COMPLETE REWRITE - CLEAN PET CARD CREATION
    -- ==========================================================
    if not petInstance or not petData then
        return nil
    end
    
    -- Create card container
    local card = Instance.new("Frame")
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.id or "unknown")
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface or Color3.fromRGB(255, 250, 250)
    card.BorderSizePixel = 0
    card.Parent = parent
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    -- No shadow frame - keep it simple
    
    -- Create pet image directly
    local petImage = Instance.new("ImageLabel")
    petImage.Name = "PetImage"
    petImage.Size = UDim2.new(0, 100, 0, 100)
    petImage.Position = UDim2.new(0.5, -50, 0, 15)
    petImage.BackgroundTransparency = 1
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Image = petData.imageId or "rbxassetid://0"
    petImage.Parent = card
    
    -- Variant effect (simplified)
    if petInstance.variant and petInstance.variant ~= "normal" then
        local variantLabel = Instance.new("TextLabel")
        variantLabel.Size = UDim2.new(1, 0, 0, 15)
        variantLabel.Position = UDim2.new(0, 0, 0, 0)
        variantLabel.BackgroundTransparency = 1
        variantLabel.Text = petInstance.variant:upper()
        variantLabel.TextScaled = true
        variantLabel.Font = Enum.Font.SourceSansBold
        variantLabel.TextColor3 = 
            petInstance.variant == "shiny" and Color3.fromRGB(255, 255, 200) or
            petInstance.variant == "golden" and Color3.fromRGB(255, 215, 0) or
            petInstance.variant == "rainbow" and Color3.fromRGB(255, 100, 255) or
            Color3.fromRGB(200, 200, 255)
        variantLabel.Parent = card
    end
    
    -- Level badge
    local levelBadge = Instance.new("Frame")
    levelBadge.Name = "LevelBadge"
    levelBadge.Size = UDim2.new(0, 40, 0, 20)
    levelBadge.Position = UDim2.new(0, 5, 0, 5)
    levelBadge.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(50, 50, 50)
    levelBadge.Parent = card
    
    local levelCorner = Instance.new("UICorner")
    levelCorner.CornerRadius = UDim.new(0, 10)
    levelCorner.Parent = levelBadge
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 1, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv." .. (petInstance.level or 1)
    levelLabel.TextScaled = true
    levelLabel.TextColor3 = Color3.new(1, 1, 1)
    levelLabel.Font = Enum.Font.SourceSansBold
    levelLabel.Parent = levelBadge
    
    -- Equipped indicator - ALWAYS create but set visibility
    local equippedBadge = Instance.new("Frame")
    equippedBadge.Name = "EquippedBadge"
    equippedBadge.Size = UDim2.new(0, 24, 0, 24)
    equippedBadge.Position = UDim2.new(1, -30, 0, 5)
    equippedBadge.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success or Color3.fromRGB(0, 255, 0)
    equippedBadge.BorderSizePixel = 0
    equippedBadge.Visible = petInstance.equipped or false
    equippedBadge.ZIndex = card.ZIndex + 3
    equippedBadge.Parent = card
    
    local equippedCorner = Instance.new("UICorner")
    equippedCorner.CornerRadius = UDim.new(0, 12)
    equippedCorner.Parent = equippedBadge
    
    local checkmark = Instance.new("TextLabel")
    checkmark.Name = "Checkmark"
    checkmark.Size = UDim2.new(1, 0, 1, 0)
    checkmark.BackgroundTransparency = 1
    checkmark.Text = "✓"
    checkmark.TextScaled = false
    checkmark.TextSize = 18
    checkmark.TextColor3 = Color3.new(1, 1, 1)
    checkmark.Font = Enum.Font.SourceSansBold
    checkmark.ZIndex = equippedBadge.ZIndex + 1
    checkmark.Parent = equippedBadge
    
    -- Lock indicator
    if petInstance.locked then
        local lockIcon = Instance.new("ImageLabel")
        lockIcon.Size = UDim2.new(0, 20, 0, 20)
        lockIcon.Position = UDim2.new(1, -25, 1, -25)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Image = "rbxassetid://10709778200"
        lockIcon.ImageColor3 = CLIENT_CONFIG.COLORS.Error or Color3.fromRGB(255, 0, 0)
        lockIcon.ScaleType = Enum.ScaleType.Fit
        lockIcon.Parent = card
    end
    
    -- Pet name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 120)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = petInstance.nickname or petData.displayName or "Unknown Pet"
    nameLabel.TextScaled = true
    nameLabel.TextColor3 = CLIENT_CONFIG.COLORS.Text or Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = card
    
    -- Stats preview (simplified)
    local statsText = string.format("⚔️ %d", petInstance.power or 0)
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -10, 0, 20)
    statsLabel.Position = UDim2.new(0, 5, 1, -25)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = statsText
    statsLabel.TextScaled = true
    statsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statsLabel.Font = Enum.Font.SourceSans
    statsLabel.Parent = card
    
    -- Click handler
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Parent = card
    
    clickButton.MouseButton1Click:Connect(function()
        self:ShowPetDetails(petInstance, petData)
    end)
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background or Color3.fromRGB(240, 240, 240)
    end)
    
    card.MouseLeave:Connect(function()
        card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface or Color3.fromRGB(255, 250, 250)
    end)
    
    return card
end

function UIModules.InventoryUI:ShowPetDetails(petInstance, petData)
    -- ==========================================================
    -- REUSABLE DETAILS WINDOW TO FIX BREAKING ON REFRESH
    -- ==========================================================
    
    -- Close any existing details window first
    if self.DetailsOverlay and self.DetailsOverlay.Parent then
        self.DetailsOverlay:Destroy()
    end
    
    -- Create modal overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "PetDetailsOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 200
    overlay.Parent = MainUI.ScreenGui
    
    -- Store reference so we can clean it up
    self.DetailsOverlay = overlay
    
    -- Register with MainUI overlay management
    MainUI:RegisterOverlay("PetDetails", overlay)
    
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
        task.wait(0.3)
        MainUI:UnregisterOverlay("PetDetails")
        self.DetailsOverlay = nil
    end)
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -80)
    content.Position = UDim2.new(0, 20, 0, 70)
    content.BackgroundTransparency = 1
    content.ZIndex = 202
    content.Parent = detailsFrame
    
    -- Left side - Pet display WITHOUT LAYOUT CONTROLLING EVERYTHING
    local leftSide = Instance.new("Frame")
    leftSide.Name = "PetDetailsLeftSide"
    leftSide.Size = UDim2.new(0.4, -10, 1, 0)
    leftSide.BackgroundTransparency = 1
    leftSide.ZIndex = 202
    leftSide.Parent = content
    
    -- Pet display at the TOP with MANUAL positioning
    local petDisplay = Instance.new("ViewportFrame")
    petDisplay.Name = "PetDisplay"
    petDisplay.Size = UDim2.new(1, 0, 0, 180)
    petDisplay.Position = UDim2.new(0, 0, 0, 0)  -- AT THE TOP!
    petDisplay.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    petDisplay.ZIndex = 202
    petDisplay.Parent = leftSide
    
    Utilities:CreateCorner(petDisplay, 12)
    
    -- For now, show image
    local petImage = UIComponents:CreateImageLabel(petDisplay, petData.imageId, UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.1, 0, 0.1, 0))
    petImage.ZIndex = 203
    
    -- Container for variant label and buttons WITH UIListLayout
    local infoContainer = Instance.new("Frame")
    infoContainer.Name = "InfoContainer"
    infoContainer.Size = UDim2.new(1, 0, 1, -200)  -- Fill remaining space
    infoContainer.Position = UDim2.new(0, 0, 0, 190)  -- Right below pet display
    infoContainer.BackgroundTransparency = 1
    infoContainer.ZIndex = 204
    infoContainer.Parent = leftSide
    
    -- UIListLayout ONLY for the info container
    local infoLayout = Instance.new("UIListLayout")
    infoLayout.Name = "InfoLayout"
    infoLayout.FillDirection = Enum.FillDirection.Vertical
    infoLayout.Padding = UDim.new(0, 10)
    infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    infoLayout.Parent = infoContainer
    
    -- Variant label (if exists) - goes in container
    if petInstance.variant and petInstance.variant ~= "normal" then
        local variantLabel = UIComponents:CreateLabel(infoContainer, "✨ " .. (petInstance.variant or ""):upper() .. " ✨", UDim2.new(1, 0, 0, 25), nil, 16)
        variantLabel.Name = "VariantLabel"
        variantLabel.TextColor3 = Utilities:GetRarityColor(petData.rarity)
        variantLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        variantLabel.ZIndex = 204
        variantLabel.LayoutOrder = 1
    end
    
    -- Action buttons frame - goes in container with layout
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Name = "ActionButtonsFrame"
    actionsFrame.Size = UDim2.new(1, -20, 0, 100)  -- Slightly inset for polish
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.ZIndex = 205
    actionsFrame.LayoutOrder = 2
    actionsFrame.Parent = infoContainer
    
    -- Add padding to the action frame for polish
    local actionsPadding = Instance.new("UIPadding")
    actionsPadding.PaddingLeft = UDim.new(0, 10)
    actionsPadding.PaddingRight = UDim.new(0, 10)
    actionsPadding.Parent = actionsFrame
    
    -- NO UIListLayout! Manual positioning for FULL CONTROL
    
    -- Equip/Unequip button at TOP of actions frame
    local equipButton
    equipButton = UIComponents:CreateButton(actionsFrame, petInstance.equipped and "Unequip" or "Equip", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), function()
        -- 1. Show the user we are working on it
        if equipButton then
            equipButton.Text = "..."
            equipButton.Active = false
        end
        
        -- 2. Ask the server to do the action
        local remote = petInstance.equipped and RemoteFunctions.UnequipPet or RemoteFunctions.EquipPet
        local success, result = pcall(function()
            return remote:InvokeServer(petInstance.uniqueId or petInstance.id)
        end)
        
        -- 3. The server will respond with a DataUpdated event which will automatically
        --    refresh the inventory and fix the button text. We just re-enable it here.
        --    No need to manually set the text; the automatic refresh will handle it!
        if equipButton then
            equipButton.Active = true
        end
        
        if not success then
            -- Connection error
            NotificationSystem:SendNotification("Error", "Failed to connect to server", "error")
            if equipButton then
                equipButton.Text = petInstance.equipped and "Unequip" or "Equip"
            end
        elseif type(result) == "table" and result.success == false then
            -- Server returned error
            NotificationSystem:SendNotification("Error", result.error or "Action failed", "error")
            if equipButton then
                equipButton.Text = petInstance.equipped and "Unequip" or "Equip"
            end
        elseif result then
            -- Success! Update the local state (result is true or a success table)
            petInstance.equipped = not petInstance.equipped
            if equipButton then
                equipButton.Text = petInstance.equipped and "Unequip" or "Equip"
                equipButton.BackgroundColor3 = petInstance.equipped and CLIENT_CONFIG.COLORS.Error or CLIENT_CONFIG.COLORS.Success
                equipButton:SetAttribute("OriginalColor", equipButton.BackgroundColor3)
            end
            
            -- Show success notification
            NotificationSystem:SendNotification("Success", petInstance.equipped and "Pet equipped!" or "Pet unequipped!", "success")
        end
    end)
    equipButton.BackgroundColor3 = petInstance.equipped and CLIENT_CONFIG.COLORS.Error or CLIENT_CONFIG.COLORS.Success
    -- Update the stored original color when we change it
    equipButton:SetAttribute("OriginalColor", equipButton.BackgroundColor3)
    equipButton.ZIndex = 206  -- Higher than parent for proper layering
    
    -- Lock/Unlock button positioned BELOW equip button
    local lockButton
    lockButton = UIComponents:CreateButton(actionsFrame, petInstance.locked and "Unlock" or "Lock", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 50), function()
        -- Toggle lock locally for now (server implementation needed)
        petInstance.locked = not petInstance.locked
        if lockButton then
            lockButton.Text = petInstance.locked and "Unlock" or "Lock"
            lockButton.BackgroundColor3 = petInstance.locked and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Warning
            lockButton:SetAttribute("OriginalColor", lockButton.BackgroundColor3)
        end
        
        -- TODO: Add server call when lock/unlock remote is available
        NotificationSystem:SendNotification("Info", petInstance.locked and "Pet locked!" or "Pet unlocked!", "info")
    end)
    lockButton.BackgroundColor3 = petInstance.locked and CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Warning
    -- Update the stored original color when we change it
    lockButton:SetAttribute("OriginalColor", lockButton.BackgroundColor3)
    lockButton.ZIndex = 206  -- Higher than parent for proper layering
    
    -- Right side - Stats and info
    local rightSide = Instance.new("Frame")
    rightSide.Name = "PetDetailsRightSide"
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
    -- ==========================================================
    -- VALIDATE DATA TO PREVENT NIL ERRORS
    -- ==========================================================
    if not petInstance or not petData then
        local errorLabel = UIComponents:CreateLabel(parent, "Pet data unavailable", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 20)
        errorLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
        return
    end
    
    -- Ensure required fields exist with defaults
    petInstance.level = petInstance.level or 1
    petInstance.experience = petInstance.experience or 0
    petInstance.power = petInstance.power or 0
    petInstance.speed = petInstance.speed or 0
    petInstance.luck = petInstance.luck or 0
    
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
    
    local xpRequired = 99999  -- Default XP requirement
    if petData.xpRequirements and type(petData.xpRequirements) == "table" and petData.xpRequirements[petInstance.level] then
        xpRequired = petData.xpRequirements[petInstance.level]
    end
    
    local xpBar = UIComponents:CreateProgressBar(levelFrame, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 30), 
        petInstance.experience, xpRequired)
    
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
    -- Validate data
    if not petData then
        local errorLabel = UIComponents:CreateLabel(parent, "No ability data available", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 20)
        errorLabel.TextColor3 = CLIENT_CONFIG.COLORS.Dark
        return
    end
    
    local scrollFrame = UIComponents:CreateScrollingFrame(parent, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))
    
    local abilitiesContainer = Instance.new("Frame")
    abilitiesContainer.Size = UDim2.new(1, -10, 0, 500)
    abilitiesContainer.BackgroundTransparency = 1
    abilitiesContainer.Parent = scrollFrame
    
    local yOffset = 0
    
    local abilities = petData.abilities
    if not abilities or type(abilities) ~= "table" or #abilities == 0 then
        -- Show placeholder if no abilities
        local placeholderLabel = UIComponents:CreateLabel(abilitiesContainer, "This pet has no special abilities yet", UDim2.new(1, 0, 0, 100), UDim2.new(0, 0, 0, 0), 18)
        placeholderLabel.TextColor3 = CLIENT_CONFIG.COLORS.Dark
        placeholderLabel.TextTransparency = 0.5
        return
    end
    
    for _, ability in ipairs(abilities) do
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
        {label = "Variant", value = petInstance.variant and petInstance.variant:gsub("_", " "):gsub("^%l", string.upper) or "Normal"},
        {label = "Obtained", value = os.date("%m/%d/%Y", petInstance.obtained or os.time())},
        {label = "Source", value = petInstance.source and petInstance.source:gsub("_", " "):gsub("^%l", string.upper) or "Unknown"},
        {label = "Value", value = Utilities:FormatNumber((petData.baseValue or 100) * ((petData.variants and petData.variants[petInstance.variant or "normal"] and petData.variants[petInstance.variant or "normal"].multiplier) or 1))},
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
            -- Send to server
            local success, result = pcall(function()
                return RemoteFunctions.RenamePet:InvokeServer(petInstance.uniqueId, input.Text)
            end)
            
            if success and result then
                Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Success)
                self:RefreshInventory()
            else
                Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Error)
                NotificationSystem:SendNotification("Error", "Failed to rename pet", "error")
            end
            NotificationSystem:SendNotification("Success", "Pet renamed to " .. input.Text, "success")
            dialog:Destroy()
        end
    end)
    confirmButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
end

function UIModules.InventoryUI:FilterPets(searchText)
    if not self.PetGrid then return end
    
    searchText = searchText:lower()
    
    for _, child in ipairs(self.PetGrid:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIGridLayout" then
            local petName = child:GetAttribute("PetName") or ""
            local petNickname = child:GetAttribute("PetNickname") or ""
            local searchName = (petNickname ~= "" and petNickname or petName):lower()
            local isVisible = searchText == "" or searchName:find(searchText, 1, true) ~= nil
            child.Visible = isVisible
        end
    end
end

function UIModules.InventoryUI:OpenMassDelete()
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "MassDeleteOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 300
    overlay.Parent = MainUI.ScreenGui
    
    -- Fade in
    overlay.BackgroundTransparency = 1
    Utilities:Tween(overlay, {BackgroundTransparency = 0.5}, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Delete window
    local deleteWindow = Instance.new("Frame")
    deleteWindow.Name = "MassDeleteWindow"
    deleteWindow.Size = UDim2.new(0, 600, 0, 500)
    deleteWindow.Position = UDim2.new(0.5, -300, 0.5, -250)
    deleteWindow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    deleteWindow.ZIndex = 301
    deleteWindow.Parent = overlay
    
    Utilities:CreateCorner(deleteWindow, 20)
    Utilities:CreateShadow(deleteWindow, 0.5, 30)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    header.ZIndex = 302
    header.Parent = deleteWindow
    
    Utilities:CreateCorner(header, 20)
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 20)
    headerFix.Position = UDim2.new(0, 0, 1, -20)
    headerFix.BackgroundColor3 = header.BackgroundColor3
    headerFix.BorderSizePixel = 0
    headerFix.ZIndex = 302
    headerFix.Parent = header
    
    local titleLabel = UIComponents:CreateLabel(header, "Mass Delete Pets", UDim2.new(1, -60, 1, 0), UDim2.new(0, 20, 0, 0), 22)
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
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
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Close)
        Utilities:Tween(deleteWindow, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        task.wait(0.3)
        overlay:Destroy()
    end)
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -140)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundTransparency = 1
    content.ZIndex = 302
    content.Parent = deleteWindow
    
    -- Instructions
    local infoLabel = UIComponents:CreateLabel(content, "Select pets to delete. This action cannot be undone!", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), 16)
    infoLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error
    infoLabel.TextWrapped = true
    infoLabel.ZIndex = 303
    
    -- Quick select buttons
    local quickSelectFrame = Instance.new("Frame")
    quickSelectFrame.Size = UDim2.new(1, 0, 0, 40)
    quickSelectFrame.Position = UDim2.new(0, 0, 0, 50)
    quickSelectFrame.BackgroundTransparency = 1
    quickSelectFrame.ZIndex = 303
    quickSelectFrame.Parent = content
    
    local selectAllCommon = UIComponents:CreateButton(quickSelectFrame, "All Common", UDim2.new(0, 120, 1, 0), UDim2.new(0, 0, 0, 0), function()
        self:SelectPetsByRarity(1)
    end)
    
    local selectAllUncommon = UIComponents:CreateButton(quickSelectFrame, "All Uncommon", UDim2.new(0, 120, 1, 0), UDim2.new(0, 130, 0, 0), function()
        self:SelectPetsByRarity(2)
    end)
    
    local deselectAll = UIComponents:CreateButton(quickSelectFrame, "Deselect All", UDim2.new(0, 120, 1, 0), UDim2.new(0, 260, 0, 0), function()
        self:DeselectAllPets()
    end)
    deselectAll.BackgroundColor3 = CLIENT_CONFIG.COLORS.Secondary
    
    -- Pet selection grid
    local scrollFrame = UIComponents:CreateScrollingFrame(content, UDim2.new(1, 0, 1, -150), UDim2.new(0, 0, 0, 100))
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    self.DeleteSelectionGrid = scrollFrame
    self.SelectedForDeletion = {}
    
    -- Load pets for selection
    self:LoadPetsForDeletion(scrollFrame)
    
    -- Update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Bottom bar
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 60)
    bottomBar.Position = UDim2.new(0, 0, 1, -60)
    bottomBar.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
    bottomBar.ZIndex = 302
    bottomBar.Parent = deleteWindow
    
    Utilities:CreateCorner(bottomBar, 20)
    
    -- Selected count
    local selectedLabel = UIComponents:CreateLabel(bottomBar, "Selected: 0 pets", UDim2.new(0, 200, 1, 0), UDim2.new(0, 20, 0, 0), 18)
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.ZIndex = 303
    self.DeleteSelectedLabel = selectedLabel
    
    -- Delete button
    local deleteButton = UIComponents:CreateButton(bottomBar, "Delete Selected", UDim2.new(0, 150, 0, 40), UDim2.new(1, -170, 0.5, -20), function()
        local count = 0
        for _ in pairs(self.SelectedForDeletion) do
            count = count + 1
        end
        
        if count > 0 then
            self:ConfirmMassDelete()
        else
            NotificationSystem:SendNotification("Error", "No pets selected for deletion", "error")
        end
    end)
    deleteButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    deleteButton.ZIndex = 303
    
    -- Animate in
    deleteWindow.Size = UDim2.new(0, 0, 0, 0)
    Utilities:Tween(deleteWindow, {Size = UDim2.new(0, 600, 0, 500)}, CLIENT_CONFIG.TWEEN_INFO.Elastic)
end

function UIModules.InventoryUI:RefreshInventory()
    -- ==========================================================
    -- COMPLETE REWRITE - BULLETPROOF INVENTORY REFRESH
    -- ==========================================================
    
    -- Prevent multiple refreshes
    if self.IsRefreshing then
        print("[DEBUG] Already refreshing, skipping")
        return
    end
    self.IsRefreshing = true
    
    -- Ensure PetGrid exists
    if not self.PetGrid or not self.PetGrid.Parent then
        warn("[InventoryUI] PetGrid not found, cannot refresh")
        self.IsRefreshing = false
        return
    end
    
    -- Store grid layout reference
    local gridLayout = self.PetGrid:FindFirstChildOfClass("UIGridLayout")
    
    -- Hide all existing cards instead of destroying them (for recycling)
    for _, card in ipairs(self.PetCardCache) do
        card.Visible = false
        card.Parent = nil  -- Temporarily unparent for performance
    end
    
    -- Get player data
    local playerData = DataManager and DataManager:GetData() or LocalData.PlayerData
    if not playerData then
        -- Show error state
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(1, 0, 0, 50)
        errorLabel.Position = UDim2.new(0, 0, 0.5, -25)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = "No data available"
        errorLabel.TextScaled = true
        errorLabel.TextColor3 = CLIENT_CONFIG.COLORS.Error or Color3.fromRGB(255, 0, 0)
        errorLabel.Font = Enum.Font.SourceSans
        errorLabel.Parent = self.PetGrid
        return
    end
    
    -- Show loading state
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Name = "LoadingLabel"
    loadingLabel.Size = UDim2.new(1, 0, 0, 50)
    loadingLabel.Position = UDim2.new(0, 0, 0.5, -25)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "Loading pets..."
    loadingLabel.TextScaled = true
    loadingLabel.TextColor3 = CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(100, 100, 100)
    loadingLabel.Font = Enum.Font.SourceSans
    loadingLabel.Parent = self.PetGrid
    
    -- Process pets data
    task.spawn(function()
        -- Small delay to show loading
        task.wait(0.1)
        
        local pets = {}
        local equippedCount = 0
        
        -- Safely process pet data
        if playerData.pets and type(playerData.pets) == "table" then
            -- DEBUG: Check structure
            local petCount = 0
            for k, v in pairs(playerData.pets) do
                petCount = petCount + 1
            end
            print("[DEBUG] Total pets in data:", petCount)
            
            -- Determine if pets is array or dictionary
            local isArray = true
            local hasNumberKeys = false
            local hasStringKeys = false
            
            for key, _ in pairs(playerData.pets) do
                if type(key) == "number" then
                    hasNumberKeys = true
                else
                    hasStringKeys = true
                    isArray = false
                end
            end
            
            print("[DEBUG] Pet data structure - Array:", isArray, "Has numbers:", hasNumberKeys, "Has strings:", hasStringKeys)
            
            -- Clear pets array to avoid duplicates
            pets = {}
            
            if isArray then
                -- Direct array usage
                for i, pet in ipairs(playerData.pets) do
                    if pet and type(pet) == "table" then
                        table.insert(pets, pet)
                    end
                end
            else
                -- Convert dictionary to array
                for uniqueId, petData in pairs(playerData.pets) do
                    if type(petData) == "table" then
                        petData.uniqueId = uniqueId
                        table.insert(pets, petData)
                    end
                end
            end
            
            print("[DEBUG] Processed pets:", #pets)
            
            -- Count equipped pets
            for _, pet in pairs(pets) do
                if pet.equipped then
                    equippedCount = equippedCount + 1
                end
            end
            
            -- Sort pets by level (highest first)
            table.sort(pets, function(a, b)
                local aLevel = a.level or 1
                local bLevel = b.level or 1
                return aLevel > bLevel
            end)
        end
    
        -- Remove loading label
        if loadingLabel and loadingLabel.Parent then
            loadingLabel:Destroy()
        end
        
        -- Update stats
        local petCount = #pets
        if self.StatsLabels then
            self.StatsLabels.PetCount.Text = "Pets: " .. petCount .. "/" .. (playerData.maxPetStorage or 500)
            self.StatsLabels.Equipped.Text = "Equipped: " .. equippedCount .. "/6"
            if self.StatsLabels.Storage and self.StatsLabels.Storage.UpdateValue then
                self.StatsLabels.Storage.UpdateValue(petCount)
            end
        end
        
        -- Create pet cards
        if #pets == 0 then
            -- Show empty state
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 100)
            emptyLabel.Position = UDim2.new(0, 0, 0.5, -50)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No pets yet!\nOpen eggs to get started"
            emptyLabel.TextScaled = true
            emptyLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary or Color3.fromRGB(150, 150, 150)
            emptyLabel.Font = Enum.Font.SourceSans
            emptyLabel.Parent = self.PetGrid
        else
            -- Create cards for each pet
            for i, pet in ipairs(pets) do
                -- Get pet template data
                local petData = LocalData.PetDatabase and LocalData.PetDatabase[pet.petId]
                
                if not petData then
                    -- Create fallback data if not in database
                    petData = {
                        id = pet.petId or "unknown",
                        displayName = pet.name or pet.petId or "Unknown Pet",
                        imageId = pet.imageId or "rbxassetid://0",
                        rarity = pet.rarity or 1,
                        description = pet.description or "A mysterious pet"
                    }
                end
                
                -- Try to reuse existing card from cache
                local card = self.PetCardCache[i]
                if card then
                    -- Update existing card
                    self:UpdatePetCard(card, pet, petData)
                    card.Parent = self.PetGrid
                    card.Visible = true
                else
                    -- Create new card if not enough in cache
                    card = self:CreatePetCard(self.PetGrid, pet, petData)
                    if card then
                        self.PetCardCache[i] = card
                    end
                end
                
                if card then
                    card.LayoutOrder = i
                end
            end
        end
        
        -- Reset refresh flag
        self.IsRefreshing = false
    end)
end

function UIModules.InventoryUI:UpdatePetCard(card, petInstance, petData)
    -- Update card name for identification
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.id)
    
    -- Update pet image
    local petImage = card:FindFirstChild("PetImage")
    if petImage then
        petImage.Image = petData.imageId
    end
    
    -- Update level badge
    local levelBadge = card:FindFirstChild("LevelBadge")
    if levelBadge then
        local levelText = levelBadge:FindFirstChild("TextLabel")
        if levelText then
            levelText.Text = "Lv." .. (petInstance.level or 1)
        end
    end
    
    -- Update name label
    local nameLabel = card:FindFirstChild("NameLabel")
    if nameLabel then
        nameLabel.Text = petInstance.nickname or petData.displayName
    end
    
    -- Update lock icon
    local lockIcon = card:FindFirstChild("LockIcon")
    if lockIcon then
        lockIcon.Visible = petInstance.locked or false
    end
    
    -- Update equipped indicator
    local equippedBadge = card:FindFirstChild("EquippedBadge")
    if equippedBadge then
        equippedBadge.Visible = petInstance.equipped or false
    end
    
    -- Update border color for rarity
    card.BorderColor3 = Utilities:GetRarityColor(petData.rarity)
    
    -- Update variant indicator if exists
    if petInstance.variant and petInstance.variant ~= "normal" then
        local variantBadge = card:FindFirstChild("VariantBadge")
        if not variantBadge then
            -- Create variant badge if it doesn't exist
            variantBadge = Instance.new("Frame")
            variantBadge.Name = "VariantBadge"
            variantBadge.Size = UDim2.new(0, 30, 0, 30)
            variantBadge.Position = UDim2.new(1, -35, 1, -35)
            variantBadge.BackgroundColor3 = CLIENT_CONFIG.COLORS.Warning
            variantBadge.ZIndex = card.ZIndex + 3
            variantBadge.Parent = card
            
            Utilities:CreateCorner(variantBadge, 15)
            
            local variantIcon = Instance.new("TextLabel")
            variantIcon.Size = UDim2.new(1, 0, 1, 0)
            variantIcon.BackgroundTransparency = 1
            variantIcon.Text = "✨"
            variantIcon.TextScaled = true
            variantIcon.TextColor3 = CLIENT_CONFIG.COLORS.White
            variantIcon.ZIndex = card.ZIndex + 4
            variantIcon.Parent = variantBadge
        end
        variantBadge.Visible = true
    else
        local variantBadge = card:FindFirstChild("VariantBadge")
        if variantBadge then
            variantBadge.Visible = false
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
    
    -- Create main trading frame inside the main panel
    local tradingFrame = UIComponents:CreateFrame(MainUI.MainPanel or MainUI.MainContainer, "TradingFrame", UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 80))
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
    
    -- Load recent partners from trade history
    spawn(function()
        local success, partners = pcall(function()
            return RemoteFunctions.GetRecentTradePartners:InvokeServer()
        end)
        
        if success and partners then
            for i, partner in ipairs(partners) do
                if i > 5 then break end -- Show only last 5 partners
                
                local partnerFrame = Instance.new("Frame")
                partnerFrame.Size = UDim2.new(1, -10, 0, 50)
                partnerFrame.Position = UDim2.new(0, 5, 0, (i-1) * 55)
                partnerFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface
                partnerFrame.Parent = recentScroll
                
                Utilities:CreateCorner(partnerFrame, 8)
                
                -- Avatar
                local avatar = Instance.new("ImageLabel")
                avatar.Size = UDim2.new(0, 40, 0, 40)
                avatar.Position = UDim2.new(0, 5, 0.5, -20)
                avatar.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
                avatar.Image = Services.Players:GetUserThumbnailAsync(partner.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                avatar.Parent = partnerFrame
                
                Utilities:CreateCorner(avatar, 20)
                
                -- Name
                local nameLabel = UIComponents:CreateLabel(partnerFrame, partner.username, UDim2.new(0, 150, 0, 20), UDim2.new(0, 50, 0, 5), 14)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
                
                -- Last trade time
                local timeLabel = UIComponents:CreateLabel(partnerFrame, partner.lastTradeTime or "Recently", UDim2.new(0, 150, 0, 20), UDim2.new(0, 50, 0, 25), 12)
                timeLabel.TextXAlignment = Enum.TextXAlignment.Left
                timeLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
                
                -- Trade button
                local tradeBtn = UIComponents:CreateButton(partnerFrame, "Trade", UDim2.new(0, 60, 0, 30), UDim2.new(1, -65, 0.5, -15), function()
                    self:SendTradeRequest(game.Players:GetPlayerByUserId(partner.userId))
                end)
                tradeBtn.BackgroundColor3 = CLIENT_CONFIG.COLORS.Primary
                
                -- Hover effect
                partnerFrame.MouseEnter:Connect(function()
                    Utilities:Tween(partnerFrame, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Background}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                end)
                
                partnerFrame.MouseLeave:Connect(function()
                    Utilities:Tween(partnerFrame, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                end)
            end
            
            -- Update scroll canvas
            recentScroll.CanvasSize = UDim2.new(0, 0, 0, #partners * 55 + 10)
        else
            -- Show empty state
            local emptyLabel = UIComponents:CreateLabel(recentScroll, "No recent trades", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 10), 14)
            emptyLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
        end
    end)
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
    -- Wrap in pcall for safety
    local success, result = pcall(function()
        return RemoteFunctions.RequestTrade:InvokeServer(targetPlayer)
    end)
    
    if not success then
        NotificationSystem:SendNotification("Error", "Failed to connect to server", "error")
        return
    end
    
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
    -- Send to server
    local success, result = pcall(function()
        return RemoteFunctions.UpdateTrade:InvokeServer(self.CurrentTrade.id, "add_item", {
            itemType = "pet",
            itemData = pet
        })
    end)
    
    if not success or not result then
        NotificationSystem:SendNotification("Error", "Failed to add pet to trade", "error")
    end
end

function UIModules.TradingUI:UpdateCurrency(currencyType, amount)
    -- Send to server
    local success, result = pcall(function()
        return RemoteFunctions.UpdateTrade:InvokeServer(self.CurrentTrade.id, "add_item", {
            itemType = "currency",
            itemData = {type = currencyType, amount = amount}
        })
    end)
    
    if not success or not result then
        NotificationSystem:SendNotification("Error", "Failed to update currency in trade", "error")
    end
end

function UIModules.TradingUI:ToggleReady()
    local ready = self.CurrentTrade.player1.userId == LocalPlayer.UserId and 
        not self.CurrentTrade.player1.ready or 
        not self.CurrentTrade.player2.ready
    
    -- Wrap in pcall
    pcall(function()
        RemoteFunctions.UpdateTrade:InvokeServer(self.CurrentTrade.id, "set_ready", {ready = ready})
    end)
end

function UIModules.TradingUI:ConfirmTrade()
    -- Wrap in pcall
    local success = pcall(function()
        RemoteFunctions.ConfirmTrade:InvokeServer(self.CurrentTrade.id)
    end)
    
    if not success then
        NotificationSystem:SendNotification("Error", "Failed to confirm trade", "error")
    end
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

function UIModules.TradingUI:CreateTradeItemCard(parent, item)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 80, 0, 80)
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.Secondary
    card.BorderSizePixel = 0
    card.Parent = parent
    
    Utilities:CreateCorner(card, 8)
    
    if item.itemType == "pet" then
        local petData = LocalData.PetDatabase[item.itemData.petId] or {}
        
        local petImage = UIComponents:CreateImageLabel(card, petData.imageId or "", 
            UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))
        
        -- Rarity border
        local border = Instance.new("Frame")
        border.Size = UDim2.new(1, 0, 0, 3)
        border.Position = UDim2.new(0, 0, 1, -3)
        border.BackgroundColor3 = Utilities:GetRarityColor(petData.rarity or 1)
        border.BorderSizePixel = 0
        border.Parent = card
    elseif item.itemType == "currency" then
        local iconMap = {
            coins = CLIENT_CONFIG.ICONS.Coin,
            gems = CLIENT_CONFIG.ICONS.Gem,
            tickets = CLIENT_CONFIG.ICONS.Ticket
        }
        
        local icon = UIComponents:CreateImageLabel(card, iconMap[item.itemData.type] or "", 
            UDim2.new(0, 40, 0, 40), UDim2.new(0.5, -20, 0.3, -20))
        
        local amountLabel = UIComponents:CreateLabel(card, tostring(item.itemData.amount), 
            UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 1, -25), 14)
        amountLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    end
    
    return card
end

function UIModules.TradingUI:UpdateTradeDisplay()
    -- Update trade window based on current trade data
    if not self.CurrentTrade or not self.CurrentTradeFrame then return end
    
    -- Update player 1 side
    local player1Side = self.CurrentTradeFrame:FindFirstChild("Player1Side")
    if player1Side then
        player1Side.ItemsFrame:ClearAllChildren()
        for _, item in ipairs(self.CurrentTrade.player1.items) do
            self:CreateTradeItemCard(player1Side.ItemsFrame, item)
        end
        
        player1Side.ReadyButton.BackgroundColor3 = self.CurrentTrade.player1.ready and 
            CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.Secondary
    end
    
    -- Update player 2 side
    local player2Side = self.CurrentTradeFrame:FindFirstChild("Player2Side")
    if player2Side then
        player2Side.ItemsFrame:ClearAllChildren()
        for _, item in ipairs(self.CurrentTrade.player2.items) do
            self:CreateTradeItemCard(player2Side.ItemsFrame, item)
        end
        
        player2Side.ReadyLabel.Text = self.CurrentTrade.player2.ready and "Ready" or "Not Ready"
        player2Side.ReadyLabel.TextColor3 = self.CurrentTrade.player2.ready and 
            CLIENT_CONFIG.COLORS.Success or CLIENT_CONFIG.COLORS.TextSecondary
    end
end

function UIModules.InventoryUI:CreateEquippedView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Parent = scrollFrame
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.CellSize = UDim2.new(0, 120, 0, 140)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Add equipped pets display
    local equippedLabel = UIComponents:CreateLabel(scrollFrame, "Your equipped pets will appear here", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    equippedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    equippedLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    return scrollFrame
end

function UIModules.InventoryUI:CreateCollectionView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Add collection progress display
    local collectionLabel = UIComponents:CreateLabel(scrollFrame, "Pet collection progress will appear here", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    collectionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    collectionLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    return scrollFrame
end

function UIModules.InventoryUI:LoadPetsForDeletion(parent)
    local playerData = DataManager and DataManager:GetData() or LocalData.PlayerData
    if not playerData or not playerData.pets then return end
    
    local pets = {}
    
    -- Convert to array if needed
    if type(playerData.pets) == "table" then
        for id, pet in pairs(playerData.pets) do
            if not pet.equipped then -- Don't allow deleting equipped pets
                pet.uniqueId = id
                table.insert(pets, pet)
            end
        end
    end
    
    -- Sort by rarity (lowest first for easier mass deletion)
    table.sort(pets, function(a, b)
        return (a.rarity or 1) < (b.rarity or 1)
    end)
    
    -- Create selectable cards
    for i, pet in ipairs(pets) do
        local petData = LocalData.PetDatabase and LocalData.PetDatabase[pet.petId] or {
            id = pet.petId or "unknown",
            displayName = pet.name or "Unknown Pet",
            imageId = pet.imageId or "rbxassetid://0",
            rarity = pet.rarity or 1
        }
        
        local card = self:CreateDeletableCard(parent, pet, petData)
        card.LayoutOrder = i
    end
end

function UIModules.InventoryUI:CreateDeletableCard(parent, petInstance, petData)
    local card = Instance.new("Frame")
    card.Name = petInstance.uniqueId
    card.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    card.BorderSizePixel = 0
    card.Parent = parent
    
    Utilities:CreateCorner(card, 8)
    
    -- Selection indicator
    local selectIndicator = Instance.new("Frame")
    selectIndicator.Name = "SelectIndicator"
    selectIndicator.Size = UDim2.new(1, -4, 1, -4)
    selectIndicator.Position = UDim2.new(0, 2, 0, 2)
    selectIndicator.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    selectIndicator.BackgroundTransparency = 1
    selectIndicator.BorderSizePixel = 0
    selectIndicator.ZIndex = card.ZIndex + 1
    selectIndicator.Parent = card
    
    Utilities:CreateCorner(selectIndicator, 6)
    
    -- Pet image
    if petData.imageId and petData.imageId ~= "rbxassetid://0" then
        local petImage = UIComponents:CreateImageLabel(card, petData.imageId, UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.1, 0, 0.1, 0))
        petImage.ZIndex = card.ZIndex + 2
    end
    
    -- Rarity border
    local rarityBorder = Instance.new("Frame")
    rarityBorder.Size = UDim2.new(1, 0, 0, 3)
    rarityBorder.Position = UDim2.new(0, 0, 1, -3)
    rarityBorder.BackgroundColor3 = Utilities:GetRarityColor(petData.rarity or 1)
    rarityBorder.BorderSizePixel = 0
    rarityBorder.ZIndex = card.ZIndex + 2
    rarityBorder.Parent = card
    
    -- Level indicator
    local levelLabel = UIComponents:CreateLabel(card, "Lv." .. (petInstance.level or 1), UDim2.new(0, 30, 0, 20), UDim2.new(0, 5, 0, 5), 12)
    levelLabel.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
    levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    levelLabel.ZIndex = card.ZIndex + 3
    Utilities:CreateCorner(levelLabel, 4)
    
    -- Make clickable
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = card.ZIndex + 10
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        if self.SelectedForDeletion[petInstance.uniqueId] then
            self.SelectedForDeletion[petInstance.uniqueId] = nil
            selectIndicator.BackgroundTransparency = 1
        else
            self.SelectedForDeletion[petInstance.uniqueId] = true
            selectIndicator.BackgroundTransparency = 0.3
        end
        
        self:UpdateDeleteCount()
    end)
    
    return card
end

function UIModules.InventoryUI:SelectPetsByRarity(rarity)
    if not self.DeleteSelectionGrid then return end
    
    for _, card in ipairs(self.DeleteSelectionGrid:GetChildren()) do
        if card:IsA("Frame") then
            local petId = card.Name
            local playerData = DataManager and DataManager:GetData() or LocalData.PlayerData
            if playerData and playerData.pets and playerData.pets[petId] then
                local pet = playerData.pets[petId]
                if pet.rarity == rarity and not pet.equipped then
                    self.SelectedForDeletion[petId] = true
                    local indicator = card:FindFirstChild("SelectIndicator")
                    if indicator then
                        indicator.BackgroundTransparency = 0.3
                    end
                end
            end
        end
    end
    
    self:UpdateDeleteCount()
end

function UIModules.InventoryUI:DeselectAllPets()
    self.SelectedForDeletion = {}
    
    if self.DeleteSelectionGrid then
        for _, card in ipairs(self.DeleteSelectionGrid:GetChildren()) do
            if card:IsA("Frame") then
                local indicator = card:FindFirstChild("SelectIndicator")
                if indicator then
                    indicator.BackgroundTransparency = 1
                end
            end
        end
    end
    
    self:UpdateDeleteCount()
end

function UIModules.InventoryUI:UpdateDeleteCount()
    local count = 0
    for _ in pairs(self.SelectedForDeletion) do
        count = count + 1
    end
    
    if self.DeleteSelectedLabel then
        self.DeleteSelectedLabel.Text = "Selected: " .. count .. " pets"
    end
end

function UIModules.InventoryUI:ConfirmMassDelete()
    local count = 0
    local petIds = {}
    
    for petId in pairs(self.SelectedForDeletion) do
        count = count + 1
        table.insert(petIds, petId)
    end
    
    if count == 0 then return end
    
    -- Show confirmation dialog
    local confirmText = "Are you sure you want to delete " .. count .. " pets?\n\nThis action cannot be undone!"
    
    -- TODO: Show proper confirmation dialog
    -- For now, just send the delete request
    
    local success, result = pcall(function()
        return RemoteFunctions.MassDeletePets:InvokeServer(petIds)
    end)
    
    if success and result.success then
        NotificationSystem:SendNotification("Success", "Deleted " .. count .. " pets", "success")
        
        -- Close mass delete window
        local overlay = MainUI.ScreenGui:FindFirstChild("MassDeleteOverlay")
        if overlay then
            overlay:Destroy()
        end
        
        -- Refresh inventory
        self:RefreshInventory()
    else
        NotificationSystem:SendNotification("Error", result and result.error or "Failed to delete pets", "error")
    end
end

function UIModules.TradingUI:CreateActiveTradesView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Add trade items
    local tradeLabel = UIComponents:CreateLabel(scrollFrame, "No active trades", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    tradeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tradeLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    return scrollFrame
end

function UIModules.TradingUI:CreateTradeHistoryView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Add history items
    local historyLabel = UIComponents:CreateLabel(scrollFrame, "Trade history will appear here", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    historyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    historyLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    return scrollFrame
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
    
    -- Create main battle frame inside the main panel
    local battleFrame = UIComponents:CreateFrame(MainUI.MainPanel or MainUI.MainContainer, "BattleFrame", UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 80))
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
    -- Implement matchmaking
    local success, result = pcall(function()
        return RemoteFunctions.JoinBattleMatchmaking:InvokeServer()
    end)
    
    if success and result then
        if result.success then
            NotificationSystem:SendNotification("Matchmaking", "Searching for opponent...", "info")
            -- Update UI to show searching state
            self:ShowMatchmakingUI()
        else
            NotificationSystem:SendNotification("Error", result.error or "Failed to join matchmaking", "error")
        end
    else
        NotificationSystem:SendNotification("Error", result or "Failed to join matchmaking", "error")
    end
end

function UIModules.BattleUI:ShowMatchmakingUI()
    -- Create matchmaking overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "MatchmakingOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 500
    overlay.Parent = MainUI.ScreenGui
    
    local searchWindow = Instance.new("Frame")
    searchWindow.Size = UDim2.new(0, 400, 0, 200)
    searchWindow.Position = UDim2.new(0.5, -200, 0.5, -100)
    searchWindow.BackgroundColor3 = CLIENT_CONFIG.COLORS.Background
    searchWindow.ZIndex = 501
    searchWindow.Parent = overlay
    
    Utilities:CreateCorner(searchWindow, 20)
    Utilities:CreateShadow(searchWindow, 0.5, 20)
    
    local spinner = Instance.new("ImageLabel")
    spinner.Size = UDim2.new(0, 60, 0, 60)
    spinner.Position = UDim2.new(0.5, -30, 0.3, 0)
    spinner.BackgroundTransparency = 1
    spinner.Image = "rbxassetid://8244601490"
    spinner.ZIndex = 502
    spinner.Parent = searchWindow
    
    -- Animate spinner
    Utilities:Tween(spinner, {Rotation = 360}, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
    
    local statusLabel = UIComponents:CreateLabel(searchWindow, "Searching for opponent...", 
        UDim2.new(1, -40, 0, 30), UDim2.new(0, 20, 0.6, 0), 20)
    statusLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    statusLabel.ZIndex = 502
    
    local cancelButton = UIComponents:CreateButton(searchWindow, "Cancel", 
        UDim2.new(0, 120, 0, 40), UDim2.new(0.5, -60, 0.8, -20), function()
            RemoteFunctions.CancelMatchmaking:InvokeServer()
            overlay:Destroy()
        end)
    cancelButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Error
    cancelButton.ZIndex = 502
    
    self.MatchmakingOverlay = overlay
end

-- Handle matchmaking found event
RemoteEvents.MatchmakingFound.OnClientEvent:Connect(function(data)
    -- Close matchmaking overlay
    if UIModules.BattleUI.MatchmakingOverlay then
        UIModules.BattleUI.MatchmakingOverlay:Destroy()
        UIModules.BattleUI.MatchmakingOverlay = nil
    end
    
    -- Open battle arena
    UIModules.BattleUI:OpenBattleArena({
        id = data.battleId,
        players = {
            [1] = {player = LocalPlayer},
            [2] = {player = {Name = data.opponent}}
        }
    })
end)

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

function UIModules.BattleUI:CreateTournamentView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Add tournament items
    local tournamentLabel = UIComponents:CreateLabel(scrollFrame, "No active tournaments", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    tournamentLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tournamentLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    return scrollFrame
end

function UIModules.BattleUI:CreateHistoryView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Add battle history items
    local historyLabel = UIComponents:CreateLabel(scrollFrame, "Battle history will appear here", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    historyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    historyLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    return scrollFrame
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
    
    -- Create main quest frame inside the main panel
    local questFrame = UIComponents:CreateFrame(MainUI.MainPanel or MainUI.MainContainer, "QuestFrame", UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 80))
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
    questContainer.Name = "QuestContainer"
    questContainer.Size = UDim2.new(1, -20, 0, 500)
    questContainer.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    questContainer.BackgroundTransparency = 0.95  -- Slightly visible background
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
    local progressBar = UIComponents:CreateProgressBar(infoFrame, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 1, -25), quest.progress or 0, quest.target or 1)
    progressBar.Frame.Parent = infoFrame
    
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
    if self.DailyQuestContainer and LocalData.PlayerData.quests and LocalData.PlayerData.quests.daily then
        for _, quest in ipairs(LocalData.PlayerData.quests.daily) do
            self:CreateQuestCard(self.DailyQuestContainer, quest)
        end
    end
    
    -- Add weekly quests
    if self.WeeklyQuestContainer and LocalData.PlayerData.quests and LocalData.PlayerData.quests.weekly then
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

function UIModules.QuestUI:CreateAchievementList(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Add achievement items
    local achievementLabel = UIComponents:CreateLabel(scrollFrame, "Achievements coming soon!", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    achievementLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    achievementLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    return scrollFrame
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
    
    -- Create main settings frame - Parent to MainPanel like other UIs
    local settingsFrame = UIComponents:CreateFrame(MainUI.MainPanel, "SettingsFrame", UDim2.new(1, -20, 1, -80), UDim2.new(0, 10, 0, 70))
    settingsFrame.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    settingsFrame.BorderSizePixel = 0
    settingsFrame.ClipsDescendants = true
    settingsFrame.ZIndex = 100  -- High ZIndex to ensure it's fully visible
    Utilities:CreateCorner(settingsFrame, 12)
    
    self.Frame = settingsFrame
    
    -- Header
    local header = UIComponents:CreateFrame(settingsFrame, "Header", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), CLIENT_CONFIG.COLORS.Primary)
    header.ZIndex = settingsFrame.ZIndex + 1
    
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
        
        -- Update DataManager if available (this will trigger reactive updates)
        if DataManager then
            DataManager:SetData(playerData)
        end
        
        -- Update currency display (fallback for non-reactive)
        if MainUI.UpdateCurrency then
            MainUI.UpdateCurrency(playerData.currencies)
        end
        
        -- Refresh inventory if open (this will be automatic with reactive updates)
        if UIModules.InventoryUI and UIModules.InventoryUI.Frame and UIModules.InventoryUI.Frame.Visible then
            UIModules.InventoryUI:RefreshInventory()
        end
        
        -- Generate quests if needed
        if not playerData.quests.daily or #playerData.quests.daily == 0 then
            -- Request quest generation
        end
    end)
    
    -- ==========================================================
    -- PROPERLY THROTTLED DATA UPDATE TO PREVENT REFRESH SPAM
    -- ==========================================================
    local lastInventoryRefresh = 0
    
    RemoteEvents.DataUpdated.OnClientEvent:Connect(function(playerData)
        -- Always update the raw data immediately
        LocalData.PlayerData = playerData
        
        if DataManager then
            DataManager:SetData(playerData)
        end
        
        -- Always update currency display immediately (it's lightweight)
        if MainUI.UpdateCurrency and playerData.currencies then
            MainUI.UpdateCurrency(playerData.currencies)
        end
        
        -- But only refresh the HEAVY inventory UI at most once per second
        local now = tick()
        if now - lastInventoryRefresh > 1 then
            lastInventoryRefresh = now
            if UIModules.InventoryUI and UIModules.InventoryUI.Frame and UIModules.InventoryUI.Frame.Visible then
                UIModules.InventoryUI:RefreshInventory()
            end
        end
    end)
    -- ==========================================================
    
    -- Handle currency updates
    RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(function(currencies)
        if LocalData.PlayerData then
            LocalData.PlayerData.currencies = currencies
        end
        
        if MainUI.UpdateCurrency then
            MainUI.UpdateCurrency(currencies)
        end
    end)
    
    -- Handle pet deletion - CRITICAL FOR INVENTORY REFRESH
    RemoteEvents.PetDeleted.OnClientEvent:Connect(function(deletedPetIds)
        NotificationSystem:SendNotification("Pets Deleted", #deletedPetIds .. " pets were successfully deleted!", "success")
        
        -- Force immediate inventory refresh
        if UIModules.InventoryUI and UIModules.InventoryUI.Frame and UIModules.InventoryUI.Frame.Visible then
            UIModules.InventoryUI:RefreshInventory()
        end
        
        -- Also refresh mass delete if it's open
        if UIModules.InventoryUI.MassDeleteFrame then
            UIModules.InventoryUI:RefreshMassDeleteGrid()
        end
    end)
    
    -- Handle case opening results
    RemoteEvents.CaseOpened.OnClientEvent:Connect(function(result)
        print("[DEBUG] Received CaseOpened event:", result)
        
        if result.success then
            -- Show the case opening animation
            if result.results and UIModules.CaseOpeningUI then
                UIModules.CaseOpeningUI:Open(result.results)
            end
            
            -- The inventory will auto-refresh if using DataManager reactive updates
            -- But we also ensure it refreshes after a delay for animation
            spawn(function()
                task.wait(2) -- Wait for animation to finish
                if UIModules.InventoryUI and UIModules.InventoryUI.Frame and UIModules.InventoryUI.Frame.Visible then
                    UIModules.InventoryUI:RefreshInventory()
                end
            end)
        else
            NotificationSystem:SendNotification("Error", result.error or "Failed to open case", "error")
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
    
    -- Update currency display with initial values
    if MainUI.UpdateCurrency then
        MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
    end
    
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
            task.wait(0.5)
        end
    end)
    
    -- Wait for data
    task.wait(2)
    
    -- Fade out loading screen
    Utilities:Tween(loadingScreen, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Slow)
    Utilities:Tween(loadingLabel, {TextTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Slow)
    task.wait(0.5)
    loadingScreen:Destroy()
    
    -- Show welcome notification
    NotificationSystem:SendNotification("Welcome!", "Welcome to Sanrio Tycoon Shop! 🎀", "info", 8)
    
    -- Open shop by default after a small delay to ensure everything is loaded
    task.wait(0.5)
    if UIModules.ShopUI then
        UIModules.ShopUI:Open()
    end
end

-- Start initialization
Initialize()

-- ========================================
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
    local titleLabel = UIComponents:CreateLabel(header, "🎁 Daily Rewards 🎁", UDim2.new(1, -50, 0, 40), UDim2.new(0, 0, 0, 10), 28)
    titleLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    titleLabel.Font = CLIENT_CONFIG.FONTS.Display
    titleLabel.ZIndex = 603
    
    -- Streak info - calculate current streak FIRST
    local currentStreak = 1
    if LocalData.PlayerData and LocalData.PlayerData.dailyReward then
        currentStreak = LocalData.PlayerData.dailyReward.streak or 1
    end
    
    local streakLabel = UIComponents:CreateLabel(header, string.format("Day %d • Keep your streak going!", currentStreak), UDim2.new(1, -50, 0, 25), UDim2.new(0, 0, 0, 45), 16)
    streakLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
    streakLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    
    -- CRITICAL: Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 20)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
    closeButton.Text = "✖"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 604
    closeButton.Parent = header
    
    Utilities:CreateCorner(closeButton, 8)
    
    closeButton.MouseEnter:Connect(function()
        Utilities:Tween(closeButton, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, CLIENT_CONFIG.TWEEN_INFO.VeryFast)
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utilities:Tween(closeButton, {BackgroundColor3 = Color3.fromRGB(255, 65, 65)}, CLIENT_CONFIG.TWEEN_INFO.VeryFast)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        -- Animate out
        Utilities:PlaySound(CLIENT_CONFIG.SOUNDS.Click)
        Utilities:Tween(rewardWindow, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, CLIENT_CONFIG.TWEEN_INFO.Fast)
        
        -- Animate overlay and wait for completion
        local overlayTween = Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        overlayTween.Completed:Wait()
        
        -- Now safe to destroy
        overlay:Destroy()
    end)
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
    
    local currentStreak = LocalData.PlayerData and LocalData.PlayerData.dailyRewards and LocalData.PlayerData.dailyRewards.streak or 1
    
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
            task.wait(0.5)
            Utilities:Tween(claimButton, {Size = UDim2.new(0, 250, 0, 60)}, TweenInfo.new(0.5, Enum.EasingStyle.Sine))
            task.wait(0.5)
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
                task.wait(1)
                Utilities:Tween(glow, {Size = UDim2.new(1, 20, 1, 20), ImageTransparency = 0.5}, TweenInfo.new(1, Enum.EasingStyle.Sine))
                task.wait(1)
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
        task.wait(2)
        local rewardWindow = overlay:FindFirstChild("DailyRewardWindow")
        if rewardWindow then
            Utilities:Tween(rewardWindow, {Size = UDim2.new(0, 0, 0, 0)}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        end
        
        -- Animate overlay and wait for completion
        local overlayTween = Utilities:Tween(overlay, {BackgroundTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        overlayTween.Completed:Wait()
        
        -- Now safe to destroy
        overlay:Destroy()
    else
        NotificationSystem:SendNotification("Error", rewards or "Failed to claim daily reward", "error")
    end
end

function UIModules.DailyRewardUI:ShowRewardAnimation(rewards)
    -- Ensure rewards is a table
    if type(rewards) ~= "table" then
        rewards = {}
    end
    
    -- Create reward display (positioned above the daily reward window)
    local rewardDisplay = Instance.new("Frame")
    rewardDisplay.Size = UDim2.new(0, 300, 0, 200)
    rewardDisplay.Position = UDim2.new(0.5, -150, 0.2, 0) -- Move to top of screen
    rewardDisplay.BackgroundColor3 = CLIENT_CONFIG.COLORS.White
    rewardDisplay.BorderSizePixel = 0
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
    
    -- Animate from top
    rewardDisplay.Size = UDim2.new(0, 0, 0, 0)
    rewardDisplay.Position = UDim2.new(0.5, 0, 0.2, 0)
    Utilities:Tween(rewardDisplay, {
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.2, 0)
    }, CLIENT_CONFIG.TWEEN_INFO.Bounce)
    
    -- Auto close with fade
    task.wait(2.5)
    local closeTween = Utilities:Tween(rewardDisplay, {
        Size = UDim2.new(0, 0, 0, 0), 
        Position = UDim2.new(0.5, 0, 0.2, 0),
        BackgroundTransparency = 1
    }, CLIENT_CONFIG.TWEEN_INFO.Normal)
    
    -- Also fade out children
    for _, child in ipairs(rewardDisplay:GetDescendants()) do
        if child:IsA("TextLabel") then
            Utilities:Tween(child, {TextTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        elseif child:IsA("ImageLabel") then
            Utilities:Tween(child, {ImageTransparency = 1}, CLIENT_CONFIG.TWEEN_INFO.Normal)
        end
    end
    
    -- Wait for the close tween to complete
    closeTween.Completed:Wait()
    
    -- Now safe to destroy
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
            task.wait(30) -- Refresh every 30 seconds
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
    -- Fetch leaderboard data from server
    spawn(function()
        local success, leaderboardData = pcall(function()
            return RemoteFunctions.GetLeaderboards:InvokeServer()
        end)
        
        if not success or not leaderboardData then
            -- Use fallback data if server request fails
            leaderboardData = {
                coins = {},
                level = {},
                pets = {}
            }
        end
        
        -- Update each leaderboard
        self:UpdateLeaderboard("coins", leaderboardData.coins or {})
        self:UpdateLeaderboard("level", leaderboardData.level or {})
        self:UpdateLeaderboard("pets", leaderboardData.pets or {})
    end)
    
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
            -- Send friend request
            pcall(function()
                game:GetService("StarterGui"):SetCore("PromptSendFriendRequest", player)
            end)
            
            -- Show notification
            NotificationSystem:SendNotification("Friend Request", "Friend request sent to " .. player.Name, "success", 3)
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
        task.wait(0.3)
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
    
    -- Get real player data
    local playerData = nil
    if player == LocalPlayer then
        -- Use local data for own profile
        playerData = DataManager and DataManager:GetData() or LocalData.PlayerData
    else
        -- Request data from server for other players
        local success, data = pcall(function()
            return RemoteFunctions.GetPlayerData:InvokeServer(player)
        end)
        if success and data then
            playerData = data
        end
    end
    
    -- If no data available, show loading message
    if not playerData then
        local loadingLabel = UIComponents:CreateLabel(statsContainer, "Loading player data...", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
        loadingLabel.TextColor3 = CLIENT_CONFIG.COLORS.Dark
        return
    end
    
    -- Calculate real stats
    local totalWealth = (playerData.currencies and ((playerData.currencies.coins or 0) + ((playerData.currencies.gems or 0) * 100))) or 0
    local petCount = 0
    if playerData.pets then
        if type(playerData.pets) == "table" then
            for _ in pairs(playerData.pets) do
                petCount = petCount + 1
            end
        end
    end
    
    local battleWins = (playerData.statistics and playerData.statistics.battleStats and playerData.statistics.battleStats.wins) or 0
    local tradesCompleted = (playerData.statistics and playerData.statistics.tradeStats and playerData.statistics.tradeStats.tradesCompleted) or 0
    local playTime = (playerData.statistics and playerData.statistics.PlayTime) or 0
    local achievements = 0
    local totalAchievements = 100 -- You can make this dynamic
    
    if playerData.achievements then
        for _, achieved in pairs(playerData.achievements) do
            if achieved then
                achievements = achievements + 1
            end
        end
    end
    
    -- Format stats for display
    local stats = {
        {title = "Total Wealth", value = Utilities:FormatNumber(totalWealth), icon = "💰", color = CLIENT_CONFIG.COLORS.Warning},
        {title = "Pets Owned", value = tostring(petCount), icon = "🐾", color = CLIENT_CONFIG.COLORS.Primary},
        {title = "Battle Wins", value = tostring(battleWins), icon = "⚔️", color = CLIENT_CONFIG.COLORS.Success},
        {title = "Trades Completed", value = tostring(tradesCompleted), icon = "🤝", color = CLIENT_CONFIG.COLORS.Info},
        {title = "Play Time", value = string.format("%.1fh", playTime / 3600), icon = "⏱️", color = CLIENT_CONFIG.COLORS.Secondary},
        {title = "Achievements", value = achievements .. "/" .. totalAchievements, icon = "🏆", color = CLIENT_CONFIG.COLORS.Accent}
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
    
    local petGrid = Instance.new("UIGridLayout")
    petGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    petGrid.CellSize = UDim2.new(0, 120, 0, 140)
    petGrid.FillDirection = Enum.FillDirection.Horizontal
    petGrid.Parent = scrollFrame
    
    -- Note for other players
    if player ~= LocalPlayer then
        local noteLabel = UIComponents:CreateLabel(parent, "This player's pet collection is private", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0.5, -25), 18)
        noteLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noteLabel.Font = CLIENT_CONFIG.FONTS.Secondary
    else
        -- Show own pets
        local playerData = LocalData.PlayerData
        if playerData and playerData.pets then
            local petCount = 0
            for petId, petData in pairs(playerData.pets) do
                petCount = petCount + 1
                if petCount > 9 then break end -- Show max 9 pets
                
                local petCard = Instance.new("Frame")
                petCard.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface
                petCard.BorderSizePixel = 0
                petCard.Parent = petGrid
                
                Utilities:CreateCorner(petCard, 8)
                
                -- Pet image
                local dbPetData = LocalData.PetDatabase and LocalData.PetDatabase[petData.petId] or {}
                local imageId = dbPetData.imageId or "rbxassetid://0"
                
                if imageId ~= "rbxassetid://0" then
                    local petImage = UIComponents:CreateImageLabel(petCard, imageId, UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.1, 0, 0.1, 0))
                    petImage.ScaleType = Enum.ScaleType.Fit
                else
                    local placeholder = UIComponents:CreateLabel(petCard, "?", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 40)
                    placeholder.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
                end
                
                -- Level indicator
                local levelLabel = UIComponents:CreateLabel(petCard, "Lv." .. (petData.level or 1), UDim2.new(0, 40, 0, 20), UDim2.new(1, -45, 1, -25), 12)
                levelLabel.BackgroundColor3 = CLIENT_CONFIG.COLORS.Dark
                levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
                Utilities:CreateCorner(levelLabel, 4)
            end
        else
            -- No pets message
            local noPetsLabel = UIComponents:CreateLabel(petGrid, "No pets yet!", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 16)
            noPetsLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
        end
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

function UIModules.ProfileUI:ShowProfileBadges(parent, player)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    
    local badgeList = Instance.new("Frame")
    badgeList.Size = UDim2.new(1, -20, 0, 800)
    badgeList.BackgroundTransparency = 1
    badgeList.Parent = scrollFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.Parent = badgeList
    
    Utilities:CreatePadding(badgeList, 10)
    
    -- Sample badges
    local badges = {
        {name = "Beta Tester", icon = "🎮", desc = "Joined during beta", owned = true},
        {name = "VIP", icon = "⭐", desc = "VIP member", owned = true},
        {name = "Collector", icon = "🏆", desc = "Collected 100 pets", owned = false},
        {name = "Trader", icon = "🤝", desc = "Completed 50 trades", owned = false},
        {name = "Champion", icon = "👑", desc = "Won a tournament", owned = false}
    }
    
    for _, badge in ipairs(badges) do
        local badgeCard = Instance.new("Frame")
        badgeCard.Size = UDim2.new(1, 0, 1, 0)
        badgeCard.BackgroundColor3 = badge.owned and CLIENT_CONFIG.COLORS.White or Color3.fromRGB(230, 230, 230)
        badgeCard.Parent = badgeList
        
        Utilities:CreateCorner(badgeCard, 12)
        Utilities:CreatePadding(badgeCard, 10)
        
        if not badge.owned then
            badgeCard.BackgroundTransparency = 0.5
        end
        
        -- Icon
        local iconLabel = UIComponents:CreateLabel(badgeCard, badge.icon, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), 32)
        iconLabel.TextTransparency = badge.owned and 0 or 0.5
        
        -- Name
        local nameLabel = UIComponents:CreateLabel(badgeCard, badge.name, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 55), 12)
        nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
        nameLabel.TextColor3 = badge.owned and CLIENT_CONFIG.COLORS.Dark or Color3.fromRGB(150, 150, 150)
        nameLabel.TextWrapped = true
        
        -- Description
        local descLabel = UIComponents:CreateLabel(badgeCard, badge.desc, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 75), 10)
        descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        descLabel.TextWrapped = true
        
        -- Lock overlay for unowned badges
        if not badge.owned then
            local lockIcon = UIComponents:CreateLabel(badgeCard, "🔒", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 48)
            lockIcon.TextTransparency = 0.7
            lockIcon.ZIndex = badgeCard.ZIndex + 1
        end
    end
    
    -- Update canvas size
    spawn(function()
        task.wait(0.1)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
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
    
    -- Load clan list
    spawn(function()
        local success, clans = pcall(function()
            return RemoteFunctions.GetClanList:InvokeServer()
        end)
        
        if success and clans then
            for i, clan in ipairs(clans) do
                local clanCard = Instance.new("Frame")
                clanCard.Size = UDim2.new(1, -10, 0, 80)
                clanCard.Position = UDim2.new(0, 5, 0, (i-1) * 85)
                clanCard.BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface
                clanCard.Parent = clanList
                
                Utilities:CreateCorner(clanCard, 12)
                Utilities:CreateShadow(clanCard, 0.2)
                
                -- Clan icon
                local iconFrame = Instance.new("Frame")
                iconFrame.Size = UDim2.new(0, 60, 0, 60)
                iconFrame.Position = UDim2.new(0, 10, 0.5, -30)
                iconFrame.BackgroundColor3 = clan.color or CLIENT_CONFIG.COLORS.Primary
                iconFrame.Parent = clanCard
                Utilities:CreateCorner(iconFrame, 8)
                
                local iconLabel = UIComponents:CreateLabel(iconFrame, string.sub(clan.name, 1, 2):upper(), UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 24)
                iconLabel.Font = CLIENT_CONFIG.FONTS.Display
                iconLabel.TextColor3 = CLIENT_CONFIG.COLORS.White
                
                -- Clan info
                local nameLabel = UIComponents:CreateLabel(clanCard, clan.name, UDim2.new(0, 200, 0, 25), UDim2.new(0, 80, 0, 10), 18)
                nameLabel.Font = CLIENT_CONFIG.FONTS.Secondary
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local membersLabel = UIComponents:CreateLabel(clanCard, clan.memberCount .. "/" .. clan.maxMembers .. " Members", UDim2.new(0, 200, 0, 20), UDim2.new(0, 80, 0, 35), 14)
                membersLabel.TextXAlignment = Enum.TextXAlignment.Left
                membersLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
                
                local levelLabel = UIComponents:CreateLabel(clanCard, "Level " .. clan.level, UDim2.new(0, 100, 0, 20), UDim2.new(0, 80, 0, 55), 14)
                levelLabel.TextXAlignment = Enum.TextXAlignment.Left
                levelLabel.TextColor3 = CLIENT_CONFIG.COLORS.TextSecondary
                
                -- Join button
                local joinButton = UIComponents:CreateButton(clanCard, "Join", UDim2.new(0, 80, 0, 35), UDim2.new(1, -90, 0.5, -17.5), function()
                    local result = RemoteFunctions.JoinClan:InvokeServer(clan.id)
                    if result.success then
                        NotificationSystem:SendNotification("Success", "Joined " .. clan.name .. "!", "success")
                        self:ShowClanDetails(clan.id)
                    else
                        NotificationSystem:SendNotification("Error", result.message or "Failed to join clan", "error")
                    end
                end)
                joinButton.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
                
                -- Hover effect
                clanCard.MouseEnter:Connect(function()
                    Utilities:Tween(clanCard, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Background}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                end)
                
                clanCard.MouseLeave:Connect(function()
                    Utilities:Tween(clanCard, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Surface}, CLIENT_CONFIG.TWEEN_INFO.Fast)
                end)
            end
            
            -- Update canvas size
            clanList.CanvasSize = UDim2.new(0, 0, 0, #clans * 85 + 10)
        else
            -- Show empty state or sample clans
            local sampleClans = {
                {name = "Sanrio Squad", memberCount = 45, maxMembers = 50, level = 10, color = CLIENT_CONFIG.COLORS.Primary},
                {name = "Hello Kitty Club", memberCount = 38, maxMembers = 50, level = 8, color = Color3.fromRGB(255, 105, 180)},
                {name = "Kuromi Gang", memberCount = 42, maxMembers = 50, level = 9, color = Color3.fromRGB(138, 43, 226)}
            }
            
            -- Create sample clan cards (same code as above but with sample data)
            for i, clan in ipairs(sampleClans) do
                clan.id = "sample_" .. i
                -- ... (repeat clan card creation code)
            end
        end
    end)
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
_G.SpecialEffects = SpecialEffects  -- Make it globally accessible

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
            task.wait(1)
            Utilities:Tween(glow, {
                Size = UDim2.new(1, 30, 1, 30),
                ImageTransparency = 0.5
            }, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1)
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
            task.wait(3)
            Utilities:Tween(shine, {Position = UDim2.new(1.5, 0, -0.5, 0)}, TweenInfo.new(0.5, Enum.EasingStyle.Linear))
            task.wait(0.5)
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
            task.wait(0.5)
            Utilities:Tween(frame, {Size = UDim2.new(
                frame.Size.X.Scale / scale,
                frame.Size.X.Offset / scale,
                frame.Size.Y.Scale / scale,
                frame.Size.Y.Offset / scale
            )}, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(0.5)
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
                    task.wait(1)
                    
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
            task.wait(1)
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

function UIModules.MinigameUI:EndMinigame(overlay, score, won, gameStats)
    -- Default game stats
    gameStats = gameStats or {}
    local attempts = gameStats.attempts or 1
    local timeElapsed = gameStats.timeElapsed or 0
    
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
        -- Send rewards to server
        local success, rewards = pcall(function()
            return RemoteFunctions.ClaimMinigameReward:InvokeServer("memory", {
                score = score,
                attempts = attempts,
                timeElapsed = timeElapsed
            })
        end)
        
        if success and rewards then
            -- Update currencies
            if rewards.coins then
                LocalData.PlayerData.currencies.coins = (LocalData.PlayerData.currencies.coins or 0) + rewards.coins
            end
            if rewards.gems then
                LocalData.PlayerData.currencies.gems = (LocalData.PlayerData.currencies.gems or 0) + rewards.gems
            end
            
            -- Update UI
            if MainUI.UpdateCurrency then
                MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
            end
            
            -- Show success notification
            NotificationSystem:SendNotification("Rewards Claimed!", "You received " .. tostring(rewards.coins or 0) .. " coins and " .. tostring(rewards.gems or 0) .. " gems!", "success")
        end
        
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
        -- Create container for both minimized and expanded states
        local container = Instance.new("Frame")
        container.Name = "DebugPanelContainer"
        container.Size = UDim2.new(0, 300, 0, 400)
        container.Position = UDim2.new(1, -310, 1, -410)
        container.BackgroundTransparency = 1
        container.Parent = MainUI.ScreenGui
        
        -- Main panel
        local panel = Instance.new("Frame")
        panel.Name = "DebugPanel"
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.BackgroundColor3 = Color3.new(0, 0, 0)
        panel.BackgroundTransparency = 0.3
        panel.Parent = container
        
        Utilities:CreateCorner(panel, 8)
        
        -- Header with title and controls
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 30)
        header.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        header.Parent = panel
        
        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 8)
        headerCorner.Parent = header
        
        -- Fix bottom corners
        local headerFix = Instance.new("Frame")
        headerFix.Size = UDim2.new(1, 0, 0, 8)
        headerFix.Position = UDim2.new(0, 0, 1, -8)
        headerFix.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        headerFix.BorderSizePixel = 0
        headerFix.Parent = header
        
        local title = UIComponents:CreateLabel(header, "Debug Panel", UDim2.new(1, -60, 1, 0), UDim2.new(0, 10, 0, 0), 16)
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Font = CLIENT_CONFIG.FONTS.Secondary
        title.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Minimize button
        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
        minimizeBtn.Position = UDim2.new(1, -55, 0.5, -12.5)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        minimizeBtn.Text = "—"
        minimizeBtn.TextColor3 = Color3.new(0, 0, 0)
        minimizeBtn.Font = Enum.Font.SourceSansBold
        minimizeBtn.TextSize = 20
        minimizeBtn.Parent = header
        
        local minBtnCorner = Instance.new("UICorner")
        minBtnCorner.CornerRadius = UDim.new(0, 6)
        minBtnCorner.Parent = minimizeBtn
        
        -- Close button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 25, 0, 25)
        closeBtn.Position = UDim2.new(1, -28, 0.5, -12.5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.new(1, 1, 1)
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 24
        closeBtn.Parent = header
        
        local closeBtnCorner = Instance.new("UICorner")
        closeBtnCorner.CornerRadius = UDim.new(0, 6)
        closeBtnCorner.Parent = closeBtn
        
        -- Minimized indicator
        local minimizedIndicator = Instance.new("TextButton")
        minimizedIndicator.Name = "MinimizedIndicator"
        minimizedIndicator.Size = UDim2.new(0, 120, 0, 30)
        minimizedIndicator.Position = UDim2.new(1, -130, 1, -40)
        minimizedIndicator.BackgroundColor3 = Color3.new(0, 0, 0)
        minimizedIndicator.BackgroundTransparency = 0.3
        minimizedIndicator.Text = "Debug Panel"
        minimizedIndicator.TextColor3 = Color3.new(1, 1, 1)
        minimizedIndicator.Font = Enum.Font.SourceSansBold
        minimizedIndicator.TextSize = 14
        minimizedIndicator.Visible = false
        minimizedIndicator.Parent = MainUI.ScreenGui
        
        local minIndicatorCorner = Instance.new("UICorner")
        minIndicatorCorner.CornerRadius = UDim.new(0, 8)
        minIndicatorCorner.Parent = minimizedIndicator
        
        -- Make header draggable
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = container.Position
            end
        end)
        
        Services.UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                container.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        Services.UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        -- Button functionality
        local isMinimized = false
        
        minimizeBtn.MouseButton1Click:Connect(function()
            isMinimized = true
            container.Visible = false
            minimizedIndicator.Visible = true
            minimizedIndicator.Position = UDim2.new(
                container.Position.X.Scale,
                container.Position.X.Offset,
                container.Position.Y.Scale,
                container.Position.Y.Offset + 370
            )
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            container:Destroy()
            minimizedIndicator:Destroy()
        end)
        
        minimizedIndicator.MouseButton1Click:Connect(function()
            isMinimized = false
            container.Visible = true
            minimizedIndicator.Visible = false
        end)
        
        -- Content
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
            if RemoteFunctions.DebugGiveCurrency then
                RemoteFunctions.DebugGiveCurrency:InvokeServer("coins", 1000000)
            else
                -- Fallback: Update local display (won't persist)
                if LocalData.PlayerData then
                    LocalData.PlayerData.currencies.coins = (LocalData.PlayerData.currencies.coins or 0) + 1000000
                    if MainUI.UpdateCurrency then
                        MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
                    end
                end
            end
        end)
        
        AddDebugButton("Give 1K Gems", function()
            print("Debug: Adding 1K gems")
            if RemoteFunctions.DebugGiveCurrency then
                RemoteFunctions.DebugGiveCurrency:InvokeServer("gems", 1000)
            else
                -- Fallback: Update local display (won't persist)
                if LocalData.PlayerData then
                    LocalData.PlayerData.currencies.gems = (LocalData.PlayerData.currencies.gems or 0) + 1000
                    if MainUI.UpdateCurrency then
                        MainUI.UpdateCurrency(LocalData.PlayerData.currencies)
                    end
                end
            end
        end)
        
        AddDebugButton("Open Legendary Egg", function()
            UIModules.ShopUI:OpenEgg({id = "legendary_egg", name = "Legendary Egg", price = 0, currency = "Gems"})
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

-- ========================================
-- CLEANUP ON LEAVE
-- ========================================
Services.Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        -- Clean up with main janitor
        if MainJanitor then
            MainJanitor:Cleanup()
        end
        
        -- Clean up window manager
        if WindowManager then
            WindowManager:CloseAllWindows()
        end
        
        -- Clean up data manager
        if DataManager and DataManager.Cleanup then
            DataManager:Cleanup()
        end
        
        -- Clean up UI module janitors
        for _, module in pairs(UIModules) do
            if module.Janitor then
                module.Janitor:Cleanup()
            end
        end
    end
end)

-- Also cleanup if script is destroyed
script.AncestryChanged:Connect(function()
    if not script.Parent then
        if MainJanitor then
            MainJanitor:Cleanup()
        end
    end
end)

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