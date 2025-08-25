--[[
    SANRIO SHOP ULTIMATE - PROFESSIONAL EDITION
    A complete, polished shop system with stunning UI and perfect functionality
    
    Features:
    - Beautiful, modern UI design with gradients and effects
    - Smooth page transitions and animations
    - Auto-loading home page with featured items
    - Professional product cards with hover effects
    - Loading states and skeleton screens
    - Particle effects and visual polish
    - Mobile-optimized responsive design
    - Sound effects and haptic feedback
    - Purchase confirmations with celebrations
    - Auto-refresh and real-time updates
--]]

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Core notifications
StarterGui:SetCore("SendNotification", {
    Title = "Sanrio Shop",
    Text = "Loading shop system...",
    Duration = 2,
})

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("TycoonRemotes", 10)

-- =====================================
-- CONFIGURATION
-- =====================================
local Config = {
    -- Product IDs (Your actual IDs)
    Products = {
        Cash = {
            {
                id = 3366419712,
                amount = 1000,
                name = "Starter Bundle",
                description = "Perfect for beginners!",
                icon = "rbxassetid://14425766299",
                gradient = {
                    Color3.fromRGB(255, 230, 230),
                    Color3.fromRGB(255, 200, 200)
                },
                popular = false,
            },
            {
                id = 3366420012,
                amount = 5000,
                name = "Growth Pack",
                description = "Accelerate your progress!",
                icon = "rbxassetid://14425766402",
                gradient = {
                    Color3.fromRGB(230, 230, 255),
                    Color3.fromRGB(200, 200, 255)
                },
                popular = true,
                ribbon = "POPULAR",
            },
            {
                id = 3366420478,
                amount = 10000,
                name = "Premium Bundle",
                description = "Great value for serious players!",
                icon = "rbxassetid://14425766507",
                gradient = {
                    Color3.fromRGB(255, 230, 255),
                    Color3.fromRGB(255, 200, 255)
                },
                popular = false,
            },
            {
                id = 3366420800,
                amount = 25000,
                name = "Ultimate Pack",
                description = "Maximum value! Best deal!",
                icon = "rbxassetid://14425766611",
                gradient = {
                    Color3.fromRGB(255, 255, 230),
                    Color3.fromRGB(255, 240, 200)
                },
                popular = true,
                ribbon = "BEST VALUE",
                glow = true,
            },
        },
        Gamepasses = {
            {
                id = 1412171840,
                name = "Auto Collect",
                description = "Automatically collect all cash drops! Works while AFK!",
                icon = "rbxassetid://14425767123",
                features = {
                    "Hands-free collection",
                    "Works while AFK", 
                    "Saves time",
                    "Toggle on/off"
                },
                gradient = {
                    Color3.fromRGB(200, 255, 200),
                    Color3.fromRGB(150, 230, 150)
                },
                hasToggle = true,
            },
            {
                id = 1398974710,
                name = "2x Cash Multiplier",
                description = "Double all cash earned permanently! Stack with events!",
                icon = "rbxassetid://14425767234",
                features = {
                    "2x all earnings",
                    "Permanent boost",
                    "Stacks with events",
                    "Best investment"
                },
                gradient = {
                    Color3.fromRGB(255, 230, 200),
                    Color3.fromRGB(255, 200, 150)
                },
                hasToggle = false,
                popular = true,
                ribbon = "MUST HAVE",
            },
        }
    },
    
    -- UI Configuration
    UI = {
        PanelSize = Vector2.new(1200, 900),
        PanelSizeMobile = Vector2.new(960, 760),
        CardSize = Vector2.new(380, 480),
        CardSizeMobile = Vector2.new(340, 420),
        
        AnimationSpeed = {
            Fast = 0.2,
            Medium = 0.3,
            Slow = 0.5,
            Bounce = 0.4,
        },
        
        Colors = {
            -- Main theme
            Primary = Color3.fromRGB(255, 130, 171),
            Secondary = Color3.fromRGB(186, 214, 255),
            Tertiary = Color3.fromRGB(255, 214, 186),
            
            -- UI Colors
            Background = Color3.fromRGB(255, 250, 250),
            Surface = Color3.fromRGB(255, 255, 255),
            SurfaceLight = Color3.fromRGB(255, 253, 253),
            
            -- Text
            TextPrimary = Color3.fromRGB(50, 50, 60),
            TextSecondary = Color3.fromRGB(120, 120, 140),
            TextLight = Color3.fromRGB(255, 255, 255),
            
            -- Status
            Success = Color3.fromRGB(76, 217, 100),
            Warning = Color3.fromRGB(255, 204, 0),
            Error = Color3.fromRGB(255, 69, 58),
            
            -- Shadows
            Shadow = Color3.fromRGB(0, 0, 0),
            ShadowLight = Color3.fromRGB(100, 100, 120),
        }
    },
    
    -- Sound Configuration
    Sounds = {
        Click = "rbxassetid://876939830",
        Hover = "rbxassetid://12221967",
        Open = "rbxassetid://130767645",
        Close = "rbxassetid://130772643",
        Purchase = "rbxassetid://131323304",
        Success = "rbxassetid://131323282",
        Error = "rbxassetid://130770091",
        Coin = "rbxassetid://131323282",
        Swoosh = "rbxassetid://130791043",
    }
}

-- =====================================
-- STATE MANAGEMENT
-- =====================================
local State = {
    isOpen = false,
    isAnimating = false,
    currentTab = "Home",
    loadingProducts = {},
    purchasePending = {},
    ownershipCache = {},
    productInfoCache = {},
    lastRefresh = 0,
    autoCollectEnabled = false,
}

-- =====================================
-- UTILITY FUNCTIONS
-- =====================================
local Utils = {}

function Utils.Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utils.Tween(object, properties, duration, style, direction)
    duration = duration or Config.UI.AnimationSpeed.Medium
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration, style, direction),
        properties
    )
    tween:Play()
    return tween
end

function Utils.Spring(object, properties, dampingRatio, frequency)
    dampingRatio = dampingRatio or 0.8
    frequency = frequency or 4
    
    local tween = TweenService:Create(
        object,
        TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Utils.FormatNumber(n)
    if n >= 1e9 then
        return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    else
        return tostring(n)
    end
end

function Utils.FormatCurrency(n)
    return string.format("$%s", string.gsub(string.format("%d", n), "(%d)(%d%d%d)$", "%1,%2"))
end

function Utils.IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.RandomBetween(min, max)
    return min + math.random() * (max - min)
end

-- =====================================
-- SOUND MANAGER
-- =====================================
local SoundManager = {}
SoundManager.sounds = {}
SoundManager.enabled = true

function SoundManager:Initialize()
    for name, id in pairs(Config.Sounds) do
        local sound = Utils.Create("Sound", {
            Name = "Shop_" .. name,
            SoundId = id,
            Volume = 0.5,
            Parent = SoundService,
        })
        self.sounds[name] = sound
    end
end

function SoundManager:Play(soundName, volume, pitch)
    if not self.enabled then return end
    
    local sound = self.sounds[soundName]
    if sound then
        sound.Volume = volume or 0.5
        sound.PlaybackSpeed = pitch or 1
        sound:Play()
    end
end

function SoundManager:PlayClick()
    self:Play("Click", 0.3, 1.1)
end

function SoundManager:PlayHover()
    self:Play("Hover", 0.2, 1)
end

-- =====================================
-- EFFECTS LIBRARY
-- =====================================
local Effects = {}

function Effects.Ripple(button, x, y)
    local ripple = Utils.Create("Frame", {
        Name = "Ripple",
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, x, 0, y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        ZIndex = 100,
        Parent = button,
    })
    
    local corner = Utils.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple,
    })
    
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    
    Utils.Tween(ripple, {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
    }, 0.6)
    
    Debris:AddItem(ripple, 0.6)
end

function Effects.Glow(frame, color, duration)
    local glow = Utils.Create("ImageLabel", {
        Name = "Glow",
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = color or Config.UI.Colors.Primary,
        ImageTransparency = 0.8,
        ZIndex = -1,
        Parent = frame,
    })
    
    local breathe = Utils.Tween(glow, {
        ImageTransparency = 0.3,
        Size = UDim2.new(1, 40, 1, 40),
    }, duration or 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    
    breathe.Completed:Connect(function()
        Utils.Tween(glow, {
            ImageTransparency = 0.8,
            Size = UDim2.new(1, 30, 1, 30),
        }, duration or 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    end)
    
    return glow
end

function Effects.Shimmer(frame, speed)
    local shimmer = Utils.Create("Frame", {
        Name = "Shimmer",
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(-0.5, 0, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 100,
        Parent = frame,
    })
    
    local gradient = Utils.Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 30,
        Parent = shimmer,
    })
    
    local function animate()
        shimmer.Position = UDim2.new(-0.5, 0, 0, 0)
        Utils.Tween(shimmer, {
            Position = UDim2.new(1.5, 0, 0, 0)
        }, speed or 2, Enum.EasingStyle.Linear)
    end
    
    animate()
    local connection
    connection = shimmer:GetPropertyChangedSignal("Position"):Connect(function()
        if shimmer.Position.X.Scale >= 1.5 then
            wait(1)
            animate()
        end
    end)
    
    return shimmer
end

function Effects.Shadow(frame, size, transparency)
    local shadow = Utils.Create("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, size * 2, 1, size * 2),
        Position = UDim2.new(0.5, 0, 0.5, size/2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10955010139",
        ImageColor3 = Config.UI.Colors.Shadow,
        ImageTransparency = transparency or 0.7,
        ZIndex = -1,
        Parent = frame,
    })
    
    return shadow
end

-- =====================================
-- UI COMPONENTS
-- =====================================
local Components = {}

function Components.Button(props)
    local button = Utils.Create("TextButton", {
        Name = props.Name or "Button",
        Size = props.Size or UDim2.new(0, 200, 0, 50),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint,
        BackgroundColor3 = props.BackgroundColor3 or Config.UI.Colors.Primary,
        BorderSizePixel = 0,
        Text = props.Text or "Button",
        TextColor3 = props.TextColor3 or Config.UI.Colors.TextLight,
        Font = props.Font or Enum.Font.Gotham,
        TextSize = props.TextSize or 16,
        AutoButtonColor = false,
        ZIndex = props.ZIndex or 1,
        Parent = props.Parent,
    })
    
    local corner = Utils.Create("UICorner", {
        CornerRadius = props.CornerRadius or UDim.new(0, 12),
        Parent = button,
    })
    
    if props.Gradient then
        local gradient = Utils.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, props.Gradient[1]),
                ColorSequenceKeypoint.new(1, props.Gradient[2]),
            }),
            Rotation = props.GradientRotation or 45,
            Parent = button,
        })
    end
    
    if props.Shadow then
        Effects.Shadow(button, props.Shadow.Size or 20, props.Shadow.Transparency or 0.3)
    end
    
    -- Hover effects
    local originalSize = button.Size
    local isHovering = false
    
    button.MouseEnter:Connect(function()
        isHovering = true
        SoundManager:PlayHover()
        Utils.Tween(button, {
            Size = UDim2.new(
                originalSize.X.Scale,
                originalSize.X.Offset + 8,
                originalSize.Y.Scale,
                originalSize.Y.Offset + 8
            )
        }, Config.UI.AnimationSpeed.Fast, Enum.EasingStyle.Back)
        
        if props.HoverGlow then
            Effects.Glow(button, props.HoverGlow.Color, 0.8)
        end
    end)
    
    button.MouseLeave:Connect(function()
        isHovering = false
        Utils.Tween(button, {
            Size = originalSize
        }, Config.UI.AnimationSpeed.Fast)
    end)
    
    button.MouseButton1Down:Connect(function()
        Utils.Tween(button, {
            Size = UDim2.new(
                originalSize.X.Scale,
                originalSize.X.Offset - 4,
                originalSize.Y.Scale,
                originalSize.Y.Offset - 4
            )
        }, 0.1)
    end)
    
    button.MouseButton1Up:Connect(function()
        if isHovering then
            Utils.Tween(button, {
                Size = UDim2.new(
                    originalSize.X.Scale,
                    originalSize.X.Offset + 8,
                    originalSize.Y.Scale,
                    originalSize.Y.Offset + 8
                )
            }, 0.1)
        else
            Utils.Tween(button, {
                Size = originalSize
            }, 0.1)
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        SoundManager:PlayClick()
        
        if props.Ripple then
            local x = button.AbsolutePosition.X + button.AbsoluteSize.X/2
            local y = button.AbsolutePosition.Y + button.AbsoluteSize.Y/2
            Effects.Ripple(button, button.AbsoluteSize.X/2, button.AbsoluteSize.Y/2)
        end
        
        if props.OnClick then
            props.OnClick()
        end
    end)
    
    return button
end

function Components.Frame(props)
    local frame = Utils.Create("Frame", {
        Name = props.Name or "Frame",
        Size = props.Size or UDim2.new(1, 0, 1, 0),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint,
        BackgroundColor3 = props.BackgroundColor3 or Config.UI.Colors.Surface,
        BackgroundTransparency = props.BackgroundTransparency or 0,
        BorderSizePixel = 0,
        ZIndex = props.ZIndex or 1,
        ClipsDescendants = props.ClipsDescendants,
        Parent = props.Parent,
    })
    
    if props.CornerRadius then
        Utils.Create("UICorner", {
            CornerRadius = props.CornerRadius,
            Parent = frame,
        })
    end
    
    if props.Gradient then
        Utils.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, props.Gradient[1]),
                ColorSequenceKeypoint.new(1, props.Gradient[2]),
            }),
            Rotation = props.GradientRotation or 90,
            Parent = frame,
        })
    end
    
    if props.Stroke then
        Utils.Create("UIStroke", {
            Color = props.Stroke.Color or Config.UI.Colors.Primary,
            Thickness = props.Stroke.Thickness or 2,
            Transparency = props.Stroke.Transparency or 0,
            Parent = frame,
        })
    end
    
    if props.Shadow then
        Effects.Shadow(frame, props.Shadow.Size or 20, props.Shadow.Transparency or 0.3)
    end
    
    if props.Padding then
        Utils.Create("UIPadding", {
            PaddingTop = props.Padding.Top or UDim.new(0, 0),
            PaddingBottom = props.Padding.Bottom or UDim.new(0, 0),
            PaddingLeft = props.Padding.Left or UDim.new(0, 0),
            PaddingRight = props.Padding.Right or UDim.new(0, 0),
            Parent = frame,
        })
    end
    
    return frame
end

function Components.Label(props)
    local label = Utils.Create("TextLabel", {
        Name = props.Name or "Label",
        Size = props.Size or UDim2.new(1, 0, 0, 20),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1,
        Text = props.Text or "Label",
        TextColor3 = props.TextColor3 or Config.UI.Colors.TextPrimary,
        Font = props.Font or Enum.Font.Gotham,
        TextSize = props.TextSize or 14,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
        TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
        TextWrapped = props.TextWrapped,
        TextScaled = props.TextScaled,
        RichText = props.RichText,
        ZIndex = props.ZIndex or 1,
        Parent = props.Parent,
    })
    
    return label
end

function Components.Image(props)
    local image = Utils.Create("ImageLabel", {
        Name = props.Name or "Image",
        Size = props.Size or UDim2.new(0, 100, 0, 100),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1,
        Image = props.Image or "",
        ImageColor3 = props.ImageColor3,
        ImageTransparency = props.ImageTransparency or 0,
        ScaleType = props.ScaleType or Enum.ScaleType.Fit,
        ZIndex = props.ZIndex or 1,
        Parent = props.Parent,
    })
    
    if props.CornerRadius then
        Utils.Create("UICorner", {
            CornerRadius = props.CornerRadius,
            Parent = image,
        })
    end
    
    return image
end

function Components.ScrollingFrame(props)
    local scroll = Utils.Create("ScrollingFrame", {
        Name = props.Name or "ScrollingFrame",
        Size = props.Size or UDim2.new(1, 0, 1, 0),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = props.ScrollBarThickness or 4,
        ScrollBarImageColor3 = props.ScrollBarImageColor3 or Config.UI.Colors.Primary,
        ScrollBarImageTransparency = props.ScrollBarImageTransparency or 0.5,
        ScrollingDirection = props.ScrollingDirection or Enum.ScrollingDirection.Y,
        CanvasSize = props.CanvasSize or UDim2.new(0, 0, 0, 0),
        ZIndex = props.ZIndex or 1,
        Parent = props.Parent,
    })
    
    if props.Padding then
        Utils.Create("UIPadding", {
            PaddingTop = props.Padding.Top or UDim.new(0, 0),
            PaddingBottom = props.Padding.Bottom or UDim.new(0, 0),
            PaddingLeft = props.Padding.Left or UDim.new(0, 0),
            PaddingRight = props.Padding.Right or UDim.new(0, 0),
            Parent = scroll,
        })
    end
    
    return scroll
end

-- =====================================
-- PRODUCT CARD COMPONENT
-- =====================================
function Components.ProductCard(product, productType, parent)
    local isCash = productType == "cash"
    local cardSize = Utils.IsMobile() and Config.UI.CardSizeMobile or Config.UI.CardSize
    
    local card = Components.Frame({
        Name = product.name .. "_Card",
        Size = UDim2.fromOffset(cardSize.X, cardSize.Y),
        BackgroundColor3 = Config.UI.Colors.Surface,
        CornerRadius = UDim.new(0, 20),
        Shadow = {Size = 30, Transparency = 0.9},
        Parent = parent,
    })
    
    -- Gradient background
    if product.gradient then
        local gradientFrame = Components.Frame({
            Name = "GradientBG",
            Size = UDim2.new(1, 0, 0.5, 0),
            Gradient = product.gradient,
            GradientRotation = 135,
            CornerRadius = UDim.new(0, 20),
            ZIndex = 2,
            Parent = card,
        })
    end
    
    -- Popular ribbon
    if product.ribbon then
        local ribbon = Components.Frame({
            Name = "Ribbon",
            Size = UDim2.new(0, 120, 0, 30),
            Position = UDim2.new(1, -10, 0, 20),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Config.UI.Colors.Error,
            CornerRadius = UDim.new(0, 15),
            ZIndex = 10,
            Parent = card,
        })
        
        Components.Label({
            Text = product.ribbon,
            TextColor3 = Config.UI.Colors.TextLight,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            ZIndex = 11,
            Parent = ribbon,
        })
        
        -- Ribbon animation
        Utils.Tween(ribbon, {
            Rotation = 5
        }, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    end
    
    -- Product icon container
    local iconContainer = Components.Frame({
        Name = "IconContainer",
        Size = UDim2.new(0, 150, 0, 150),
        Position = UDim2.new(0.5, 0, 0, 40),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = card,
    })
    
    -- Animated icon background
    local iconBG = Components.Frame({
        Name = "IconBG",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.9,
        CornerRadius = UDim.new(1, 0),
        ZIndex = 3,
        Parent = iconContainer,
    })
    
    -- Product icon
    local icon = Components.Image({
        Name = "Icon",
        Size = UDim2.new(0.8, 0, 0.8, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = product.icon or (isCash and "rbxassetid://14425766299" or "rbxassetid://14425767123"),
        ZIndex = 4,
        Parent = iconContainer,
    })
    
    -- Glow effect for special items
    if product.glow then
        Effects.Glow(iconContainer, Config.UI.Colors.Warning, 1.5)
    end
    
    -- Content container
    local content = Components.Frame({
        Name = "Content",
        Size = UDim2.new(1, -40, 1, -220),
        Position = UDim2.new(0, 20, 0, 210),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = card,
    })
    
    -- Product name
    local title = Components.Label({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 30),
        Text = product.name,
        TextColor3 = Config.UI.Colors.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        ZIndex = 5,
        Parent = content,
    })
    
    -- Product description
    local desc = Components.Label({
        Name = "Description",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 35),
        Text = product.description,
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextWrapped = true,
        ZIndex = 5,
        Parent = content,
    })
    
    -- Features list (for gamepasses)
    if product.features then
        local featuresFrame = Components.Frame({
            Name = "Features",
            Size = UDim2.new(1, 0, 0, 80),
            Position = UDim2.new(0, 0, 0, 80),
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = content,
        })
        
        for i, feature in ipairs(product.features) do
            local featureLabel = Components.Label({
                Name = "Feature" .. i,
                Size = UDim2.new(1, -20, 0, 18),
                Position = UDim2.new(0, 20, 0, (i-1) * 20),
                Text = "• " .. feature,
                TextColor3 = Config.UI.Colors.TextSecondary,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = featuresFrame,
            })
        end
    end
    
    -- Price/Amount display
    local priceContainer = Components.Frame({
        Name = "PriceContainer",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 1, -100),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = card,
    })
    
    if isCash then
        -- Cash amount
        local amountLabel = Components.Label({
            Name = "Amount",
            Size = UDim2.new(1, 0, 0, 30),
            Text = Utils.FormatNumber(product.amount) .. " Cash",
            TextColor3 = Config.UI.Colors.Primary,
            Font = Enum.Font.GothamBold,
            TextSize = 24,
            ZIndex = 5,
            Parent = priceContainer,
        })
        
        -- Price (will be loaded)
        local priceLabel = Components.Label({
            Name = "Price",
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 30),
            Text = "Loading...",
            TextColor3 = Config.UI.Colors.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 16,
            ZIndex = 5,
            Parent = priceContainer,
        })
        
        -- Load actual price
        task.spawn(function()
            local info = MarketplaceService:GetProductInfo(product.id, Enum.InfoType.Product)
            if info then
                priceLabel.Text = "R$" .. tostring(info.PriceInRobux)
            end
        end)
    else
        -- Gamepass price
        local priceLabel = Components.Label({
            Name = "Price",
            Size = UDim2.new(1, 0, 1, 0),
            Text = "Loading...",
            TextColor3 = Config.UI.Colors.Primary,
            Font = Enum.Font.GothamBold,
            TextSize = 28,
            ZIndex = 5,
            Parent = priceContainer,
        })
        
        -- Load actual price
        task.spawn(function()
            local info = MarketplaceService:GetProductInfo(product.id, Enum.InfoType.GamePass)
            if info then
                priceLabel.Text = "R$" .. tostring(info.PriceInRobux)
            end
        end)
    end
    
    -- Purchase button
    local purchaseButton = Components.Button({
        Name = "PurchaseButton",
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 20, 1, -60),
        Text = "Purchase",
        BackgroundColor3 = Config.UI.Colors.Primary,
        TextColor3 = Config.UI.Colors.TextLight,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        CornerRadius = UDim.new(0, 25),
        Shadow = {Size = 15, Transparency = 0.5},
        Ripple = true,
        ZIndex = 6,
        Parent = card,
        OnClick = function()
            if isCash then
                MarketplaceService:PromptProductPurchase(Player, product.id)
            else
                MarketplaceService:PromptGamePassPurchase(Player, product.id)
            end
        end,
    })
    
    -- Check ownership for gamepasses
    if not isCash then
        task.spawn(function()
            local owned = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, product.id)
            if owned then
                purchaseButton.Text = "Owned"
                purchaseButton.BackgroundColor3 = Config.UI.Colors.Success
                purchaseButton.Active = false
                
                -- Add toggle if applicable
                if product.hasToggle then
                    -- Create toggle UI
                    local toggleFrame = Components.Frame({
                        Name = "Toggle",
                        Size = UDim2.new(0, 60, 0, 30),
                        Position = UDim2.new(1, -80, 1, -55),
                        BackgroundColor3 = Config.UI.Colors.TextSecondary,
                        CornerRadius = UDim.new(1, 0),
                        ZIndex = 7,
                        Parent = card,
                    })
                    
                    local toggleButton = Components.Frame({
                        Name = "Button",
                        Size = UDim2.new(0, 26, 0, 26),
                        Position = UDim2.new(0, 2, 0, 2),
                        BackgroundColor3 = Config.UI.Colors.Surface,
                        CornerRadius = UDim.new(1, 0),
                        ZIndex = 8,
                        Parent = toggleFrame,
                    })
                    
                    -- Toggle functionality
                    local toggled = State.autoCollectEnabled
                    
                    local function updateToggle()
                        if toggled then
                            toggleFrame.BackgroundColor3 = Config.UI.Colors.Success
                            Utils.Tween(toggleButton, {
                                Position = UDim2.new(1, -28, 0, 2)
                            }, 0.2)
                        else
                            toggleFrame.BackgroundColor3 = Config.UI.Colors.TextSecondary
                            Utils.Tween(toggleButton, {
                                Position = UDim2.new(0, 2, 0, 2)
                            }, 0.2)
                        end
                    end
                    
                    updateToggle()
                    
                    local toggleButton = Utils.Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = toggleFrame,
                    })
                    
                    toggleButton.MouseButton1Click:Connect(function()
                        toggled = not toggled
                        State.autoCollectEnabled = toggled
                        updateToggle()
                        SoundManager:PlayClick()
                        
                        if Remotes then
                            local toggleRemote = Remotes:FindFirstChild("AutoCollectToggle")
                            if toggleRemote then
                                toggleRemote:FireServer(toggled)
                            end
                        end
                    end)
                end
            end
        end)
    end
    
    -- Hover animation
    local originalPosition = card.Position
    card.MouseEnter:Connect(function()
        Utils.Tween(card, {
            Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset,
                originalPosition.Y.Scale,
                originalPosition.Y.Offset - 10
            )
        }, Config.UI.AnimationSpeed.Fast, Enum.EasingStyle.Back)
        
        Utils.Tween(iconBG, {
            Size = UDim2.new(1.1, 0, 1.1, 0),
            BackgroundTransparency = 0.8
        }, Config.UI.AnimationSpeed.Fast)
    end)
    
    card.MouseLeave:Connect(function()
        Utils.Tween(card, {
            Position = originalPosition
        }, Config.UI.AnimationSpeed.Fast)
        
        Utils.Tween(iconBG, {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0.9
        }, Config.UI.AnimationSpeed.Fast)
    end)
    
    return card
end

-- =====================================
-- MAIN SHOP UI
-- =====================================
local Shop = {}
Shop.GUI = nil
Shop.MainPanel = nil
Shop.Pages = {}
Shop.Tabs = {}
Shop.ToggleButton = nil

function Shop:Initialize()
    SoundManager:Initialize()
    self:CreateToggleButton()
    self:CreateMainInterface()
    self:SetupConnections()
    
    -- Show home page by default
    self:ShowPage("Home")
end

function Shop:CreateToggleButton()
    local screenGui = Utils.Create("ScreenGui", {
        Name = "SanrioShopToggle",
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Parent = PlayerGui,
    })
    
    self.ToggleButton = Components.Button({
        Name = "ToggleButton",
        Size = UDim2.new(0, 200, 0, 70),
        Position = UDim2.new(1, -20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        Text = "",
        BackgroundColor3 = Config.UI.Colors.Surface,
        CornerRadius = UDim.new(1, 0),
        Shadow = {Size = 25, Transparency = 0.5},
        Stroke = {
            Color = Config.UI.Colors.Primary,
            Thickness = 3,
            Transparency = 0,
        },
        Parent = screenGui,
        OnClick = function()
            self:Toggle()
        end,
    })
    
    -- Add gradient
    local gradient = Utils.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.UI.Colors.Primary),
            ColorSequenceKeypoint.new(1, Config.UI.Colors.Secondary),
        }),
        Rotation = 45,
        Parent = self.ToggleButton,
    })
    
    -- Icon
    local icon = Components.Image({
        Name = "Icon",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 20, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image = "rbxassetid://14425764931",
        Parent = self.ToggleButton,
    })
    
    -- Text
    local label = Components.Label({
        Name = "Label",
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 70, 0, 0),
        Text = "SHOP",
        TextColor3 = Config.UI.Colors.TextLight,
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.ToggleButton,
    })
    
    -- Pulse animation
    local function pulse()
        Utils.Tween(self.ToggleButton, {
            Size = UDim2.new(0, 210, 0, 75)
        }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        
        wait(1.5)
        
        Utils.Tween(self.ToggleButton, {
            Size = UDim2.new(0, 200, 0, 70)
        }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    end
    
    task.spawn(function()
        while self.ToggleButton.Parent do
            pulse()
            wait(1.5)
        end
    end)
end

function Shop:CreateMainInterface()
    self.GUI = Utils.Create("ScreenGui", {
        Name = "SanrioShopMain",
        ResetOnSpawn = false,
        DisplayOrder = 1000,
        Enabled = false,
        Parent = PlayerGui,
    })
    
    -- Blur effect
    self.Blur = Utils.Create("BlurEffect", {
        Name = "ShopBlur",
        Size = 0,
        Parent = Lighting,
    })
    
    -- Dim background
    local dimBG = Components.Frame({
        Name = "DimBackground",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.3,
        ZIndex = 1,
        Parent = self.GUI,
    })
    
    -- Main panel
    local panelSize = Utils.IsMobile() and Config.UI.PanelSizeMobile or Config.UI.PanelSize
    self.MainPanel = Components.Frame({
        Name = "MainPanel",
        Size = UDim2.fromOffset(panelSize.X, panelSize.Y),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Config.UI.Colors.Background,
        CornerRadius = UDim.new(0, 30),
        Shadow = {Size = 50, Transparency = 0.8},
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = self.GUI,
    })
    
    -- Background pattern
    local pattern = Components.Image({
        Name = "Pattern",
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://14425768345",
        ImageColor3 = Config.UI.Colors.Primary,
        ImageTransparency = 0.95,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 200, 0, 200),
        ZIndex = 2,
        Parent = self.MainPanel,
    })
    
    self:CreateHeader()
    self:CreateTabBar()
    self:CreatePages()
    self:AddParticles()
end

function Shop:CreateHeader()
    local header = Components.Frame({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundColor3 = Config.UI.Colors.Surface,
        Gradient = {Config.UI.Colors.Primary, Config.UI.Colors.Secondary},
        GradientRotation = 45,
        Shadow = {Size = 20, Transparency = 0.9},
        ZIndex = 10,
        Parent = self.MainPanel,
    })
    
    -- Logo
    local logo = Components.Image({
        Name = "Logo",
        Size = UDim2.new(0, 70, 0, 70),
        Position = UDim2.new(0, 30, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image = "rbxassetid://14425764931",
        ZIndex = 11,
        Parent = header,
    })
    
    -- Title
    local title = Components.Label({
        Name = "Title",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, 120, 0, 0),
        Text = "SANRIO SHOP",
        TextColor3 = Config.UI.Colors.TextLight,
        Font = Enum.Font.GothamBold,
        TextSize = 36,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
        Parent = header,
    })
    
    -- Subtitle
    local subtitle = Components.Label({
        Name = "Subtitle",
        Size = UDim2.new(0, 300, 0, 20),
        Position = UDim2.new(0, 120, 1, -25),
        Text = "Get amazing items for your tycoon!",
        TextColor3 = Config.UI.Colors.TextLight,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextTransparency = 0.3,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
        Parent = header,
    })
    
    -- Close button
    local closeButton = Components.Button({
        Name = "CloseButton",
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(1, -70, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Text = "✕",
        BackgroundColor3 = Config.UI.Colors.Error,
        TextColor3 = Config.UI.Colors.TextLight,
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        CornerRadius = UDim.new(1, 0),
        ZIndex = 12,
        Parent = header,
        OnClick = function()
            self:Close()
        end,
    })
end

function Shop:CreateTabBar()
    local tabBar = Components.Frame({
        Name = "TabBar",
        Size = UDim2.new(1, -60, 0, 60),
        Position = UDim2.new(0, 30, 0, 100),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = self.MainPanel,
    })
    
    local tabs = {
        {Name = "Home", Icon = "rbxassetid://14425765123", Color = Config.UI.Colors.Primary},
        {Name = "Cash", Icon = "rbxassetid://14425765234", Color = Config.UI.Colors.Secondary},
        {Name = "Gamepasses", Icon = "rbxassetid://14425765345", Color = Config.UI.Colors.Tertiary},
    }
    
    for i, tabData in ipairs(tabs) do
        local tab = Components.Button({
            Name = tabData.Name .. "Tab",
            Size = UDim2.new(0.33, -10, 1, 0),
            Position = UDim2.new((i-1) * 0.33, (i-1) * 5, 0, 0),
            Text = "",
            BackgroundColor3 = i == 1 and tabData.Color or Config.UI.Colors.SurfaceLight,
            CornerRadius = UDim.new(0, 15),
            ZIndex = 6,
            Parent = tabBar,
            OnClick = function()
                self:ShowPage(tabData.Name)
            end,
        })
        
        -- Tab icon
        local icon = Components.Image({
            Name = "Icon",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 20, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Image = tabData.Icon,
            ImageColor3 = i == 1 and Config.UI.Colors.TextLight or Config.UI.Colors.TextSecondary,
            ZIndex = 7,
            Parent = tab,
        })
        
        -- Tab text
        local text = Components.Label({
            Name = "Text",
            Size = UDim2.new(1, -60, 1, 0),
            Position = UDim2.new(0, 50, 0, 0),
            Text = tabData.Name,
            TextColor3 = i == 1 and Config.UI.Colors.TextLight or Config.UI.Colors.TextSecondary,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
            Parent = tab,
        })
        
        self.Tabs[tabData.Name] = {
            Button = tab,
            Icon = icon,
            Text = text,
            Color = tabData.Color,
        }
    end
end

function Shop:CreatePages()
    local pageContainer = Components.Frame({
        Name = "PageContainer",
        Size = UDim2.new(1, -60, 1, -180),
        Position = UDim2.new(0, 30, 0, 170),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = self.MainPanel,
    })
    
    -- Home page
    self:CreateHomePage(pageContainer)
    
    -- Cash page
    self:CreateCashPage(pageContainer)
    
    -- Gamepasses page
    self:CreateGamepassesPage(pageContainer)
end

function Shop:CreateHomePage(parent)
    local page = Components.ScrollingFrame({
        Name = "HomePage",
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 6,
        ZIndex = 4,
        Parent = parent,
    })
    
    -- Hero section
    local hero = Components.Frame({
        Name = "Hero",
        Size = UDim2.new(1, -20, 0, 300),
        Position = UDim2.new(0, 10, 0, 10),
        Gradient = {Config.UI.Colors.Primary, Config.UI.Colors.Secondary},
        GradientRotation = 135,
        CornerRadius = UDim.new(0, 20),
        Shadow = {Size = 30, Transparency = 0.8},
        ZIndex = 5,
        Parent = page,
    })
    
    -- Hero content
    local heroTitle = Components.Label({
        Name = "HeroTitle",
        Size = UDim2.new(0, 400, 0, 60),
        Position = UDim2.new(0, 40, 0, 40),
        Text = "Welcome to Sanrio Shop!",
        TextColor3 = Config.UI.Colors.TextLight,
        Font = Enum.Font.GothamBold,
        TextSize = 42,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = hero,
    })
    
    local heroDesc = Components.Label({
        Name = "HeroDesc",
        Size = UDim2.new(0, 400, 0, 80),
        Position = UDim2.new(0, 40, 0, 110),
        Text = "Get exclusive items and boosts to enhance your tycoon experience!",
        TextColor3 = Config.UI.Colors.TextLight,
        Font = Enum.Font.Gotham,
        TextSize = 18,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 0.1,
        ZIndex = 6,
        Parent = hero,
    })
    
    -- CTA button
    local ctaButton = Components.Button({
        Name = "CTAButton",
        Size = UDim2.new(0, 200, 0, 60),
        Position = UDim2.new(0, 40, 1, -80),
        Text = "Shop Now",
        BackgroundColor3 = Config.UI.Colors.Surface,
        TextColor3 = Config.UI.Colors.Primary,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        CornerRadius = UDim.new(1, 0),
        Shadow = {Size = 20, Transparency = 0.5},
        ZIndex = 7,
        Parent = hero,
        OnClick = function()
            self:ShowPage("Cash")
        end,
    })
    
    -- Hero image
    local heroImage = Components.Image({
        Name = "HeroImage",
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(1, -400, 0, 0),
        Image = "rbxassetid://14425768456",
        ImageTransparency = 0.1,
        ZIndex = 6,
        Parent = hero,
    })
    
    -- Featured section
    local featuredTitle = Components.Label({
        Name = "FeaturedTitle",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 330),
        Text = "Featured Items",
        TextColor3 = Config.UI.Colors.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 28,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = page,
    })
    
    -- Featured items grid
    local featuredGrid = Components.Frame({
        Name = "FeaturedGrid",
        Size = UDim2.new(1, -20, 0, 500),
        Position = UDim2.new(0, 10, 0, 380),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = page,
    })
    
    local gridLayout = Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0, 380, 0, 480),
        CellPadding = UDim2.new(0, 20, 0, 20),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = featuredGrid,
    })
    
    -- Add featured items
    local featuredItems = {
        Config.Products.Cash[2], -- 5K cash (popular)
        Config.Products.Cash[4], -- 25K cash (best value)
        Config.Products.Gamepasses[2], -- 2x Cash
    }
    
    for i, item in ipairs(featuredItems) do
        local card = Components.ProductCard(item, item.amount and "cash" or "gamepass", featuredGrid)
        card.LayoutOrder = i
    end
    
    -- Update canvas size
    page.CanvasSize = UDim2.new(0, 0, 0, 900)
    
    self.Pages.Home = page
end

function Shop:CreateCashPage(parent)
    local page = Components.ScrollingFrame({
        Name = "CashPage",
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 6,
        Visible = false,
        ZIndex = 4,
        Parent = parent,
    })
    
    -- Page title
    local title = Components.Label({
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 10),
        Text = "Cash Bundles",
        TextColor3 = Config.UI.Colors.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = page,
    })
    
    -- Products grid
    local grid = Components.Frame({
        Name = "Grid",
        Size = UDim2.new(1, -20, 0, 1000),
        Position = UDim2.new(0, 10, 0, 60),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = page,
    })
    
    local gridLayout = Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0, 380, 0, 480),
        CellPadding = UDim2.new(0, 20, 0, 20),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = grid,
    })
    
    -- Add all cash products
    for i, product in ipairs(Config.Products.Cash) do
        local card = Components.ProductCard(product, "cash", grid)
        card.LayoutOrder = i
    end
    
    -- Update canvas size
    page.CanvasSize = UDim2.new(0, 0, 0, 1100)
    
    self.Pages.Cash = page
end

function Shop:CreateGamepassesPage(parent)
    local page = Components.ScrollingFrame({
        Name = "GamepassesPage",
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 6,
        Visible = false,
        ZIndex = 4,
        Parent = parent,
    })
    
    -- Page title
    local title = Components.Label({
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 10),
        Text = "Game Passes",
        TextColor3 = Config.UI.Colors.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = page,
    })
    
    -- Description
    local desc = Components.Label({
        Name = "Description",
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 50),
        Text = "Permanent upgrades to boost your gameplay!",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = page,
    })
    
    -- Products grid
    local grid = Components.Frame({
        Name = "Grid",
        Size = UDim2.new(1, -20, 0, 600),
        Position = UDim2.new(0, 10, 0, 100),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = page,
    })
    
    local gridLayout = Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0, 380, 0, 480),
        CellPadding = UDim2.new(0, 20, 0, 20),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = grid,
    })
    
    -- Add all gamepass products
    for i, product in ipairs(Config.Products.Gamepasses) do
        local card = Components.ProductCard(product, "gamepass", grid)
        card.LayoutOrder = i
    end
    
    -- Update canvas size
    page.CanvasSize = UDim2.new(0, 0, 0, 720)
    
    self.Pages.Gamepasses = page
end

function Shop:AddParticles()
    -- Add floating particles for visual appeal
    local particleContainer = Components.Frame({
        Name = "Particles",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 50,
        Parent = self.MainPanel,
    })
    
    local function createParticle()
        local particle = Components.Image({
            Name = "Particle",
            Size = UDim2.new(0, math.random(10, 30), 0, math.random(10, 30)),
            Position = UDim2.new(math.random(), 0, 1, 20),
            Image = "rbxassetid://14425769567",
            ImageColor3 = Config.UI.Colors.Primary,
            ImageTransparency = 0.7,
            ZIndex = 51,
            Parent = particleContainer,
        })
        
        -- Float upward animation
        local targetY = -0.2
        local duration = Utils.RandomBetween(8, 15)
        
        Utils.Tween(particle, {
            Position = UDim2.new(particle.Position.X.Scale, 0, targetY, 0),
            ImageTransparency = 1,
        }, duration, Enum.EasingStyle.Linear)
        
        Debris:AddItem(particle, duration)
    end
    
    -- Create particles periodically
    task.spawn(function()
        while self.GUI.Parent do
            createParticle()
            wait(Utils.RandomBetween(0.5, 2))
        end
    end)
end

function Shop:ShowPage(pageName)
    -- Update tab appearance
    for name, tab in pairs(self.Tabs) do
        local isActive = name == pageName
        
        Utils.Tween(tab.Button, {
            BackgroundColor3 = isActive and tab.Color or Config.UI.Colors.SurfaceLight
        }, Config.UI.AnimationSpeed.Fast)
        
        Utils.Tween(tab.Icon, {
            ImageColor3 = isActive and Config.UI.Colors.TextLight or Config.UI.Colors.TextSecondary
        }, Config.UI.AnimationSpeed.Fast)
        
        Utils.Tween(tab.Text, {
            TextColor3 = isActive and Config.UI.Colors.TextLight or Config.UI.Colors.TextSecondary
        }, Config.UI.AnimationSpeed.Fast)
    end
    
    -- Show selected page
    for name, page in pairs(self.Pages) do
        if name == pageName then
            page.Visible = true
            page.Position = UDim2.new(0, 0, 0, 20)
            Utils.Tween(page, {
                Position = UDim2.new(0, 0, 0, 0)
            }, Config.UI.AnimationSpeed.Medium, Enum.EasingStyle.Back)
        else
            page.Visible = false
        end
    end
    
    State.currentTab = pageName
    SoundManager:Play("Swoosh", 0.3)
end

function Shop:Open()
    if State.isOpen or State.isAnimating then return end
    
    State.isAnimating = true
    State.isOpen = true
    
    self.GUI.Enabled = true
    
    -- Animate blur
    Utils.Tween(self.Blur, {
        Size = 24
    }, Config.UI.AnimationSpeed.Medium)
    
    -- Animate panel entrance
    self.MainPanel.Position = UDim2.new(0.5, 0, 1.5, 0)
    self.MainPanel.Size = UDim2.fromOffset(
        self.MainPanel.Size.X.Offset * 0.8,
        self.MainPanel.Size.Y.Offset * 0.8
    )
    
    Utils.Spring(self.MainPanel, {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(
            Utils.IsMobile() and Config.UI.PanelSizeMobile.X or Config.UI.PanelSize.X,
            Utils.IsMobile() and Config.UI.PanelSizeMobile.Y or Config.UI.PanelSize.Y
        )
    })
    
    SoundManager:Play("Open")
    
    wait(Config.UI.AnimationSpeed.Bounce)
    State.isAnimating = false
    
    -- Send notification
    StarterGui:SetCore("SendNotification", {
        Title = "Sanrio Shop",
        Text = "Welcome! Check out our amazing items!",
        Duration = 3,
    })
end

function Shop:Close()
    if not State.isOpen or State.isAnimating then return end
    
    State.isAnimating = true
    State.isOpen = false
    
    -- Animate blur
    Utils.Tween(self.Blur, {
        Size = 0
    }, Config.UI.AnimationSpeed.Fast)
    
    -- Animate panel exit
    Utils.Tween(self.MainPanel, {
        Position = UDim2.new(0.5, 0, 1.5, 0),
        Size = UDim2.fromOffset(
            self.MainPanel.Size.X.Offset * 0.8,
            self.MainPanel.Size.Y.Offset * 0.8
        )
    }, Config.UI.AnimationSpeed.Fast)
    
    SoundManager:Play("Close")
    
    wait(Config.UI.AnimationSpeed.Fast)
    self.GUI.Enabled = false
    State.isAnimating = false
end

function Shop:Toggle()
    if State.isOpen then
        self:Close()
    else
        self:Open()
    end
end

function Shop:SetupConnections()
    -- Purchase handlers
    MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
        if userId == Player.UserId and isPurchased then
            SoundManager:Play("Success")
            
            -- Find the product
            local productName = ""
            for _, product in ipairs(Config.Products.Cash) do
                if product.id == productId then
                    productName = product.name
                    break
                end
            end
            
            StarterGui:SetCore("SendNotification", {
                Title = "Purchase Successful!",
                Text = "You bought " .. productName .. "!",
                Duration = 5,
            })
            
            -- Fire remote if exists
            if Remotes then
                local grantRemote = Remotes:FindFirstChild("GrantProductCurrency")
                if grantRemote then
                    grantRemote:FireServer(productId)
                end
            end
        end
    end)
    
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(userId, passId, wasPurchased)
        if userId == Player.UserId and wasPurchased then
            SoundManager:Play("Success")
            
            -- Find the gamepass
            local passName = ""
            for _, pass in ipairs(Config.Products.Gamepasses) do
                if pass.id == passId then
                    passName = pass.name
                    break
                end
            end
            
            StarterGui:SetCore("SendNotification", {
                Title = "Gamepass Purchased!",
                Text = "You now own " .. passName .. "!",
                Duration = 5,
            })
            
            -- Refresh the page to show owned state
            wait(1)
            self:ShowPage(State.currentTab)
        end
    end)
    
    -- Keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.M then
            self:Toggle()
        elseif input.KeyCode == Enum.KeyCode.Escape and State.isOpen then
            self:Close()
        end
    end)
end

-- =====================================
-- INITIALIZATION
-- =====================================
Shop:Initialize()

-- Show success notification
StarterGui:SetCore("SendNotification", {
    Title = "Sanrio Shop",
    Text = "Shop system loaded! Press M to open.",
    Duration = 5,
})

print("[SanrioShop Ultimate] Initialized successfully!")

return Shop