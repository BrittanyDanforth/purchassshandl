--[[
    SANRIO SHOP PROFESSIONAL - Complete Premium Shop System
    A fully polished, modern shop with beautiful UI and smooth animations
    Place in StarterPlayer > StarterPlayerScripts as LocalScript
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- Design System
local Design = {
    Colors = {
        -- Primary palette
        Primary = Color3.fromRGB(255, 182, 193),      -- Soft pink
        Secondary = Color3.fromRGB(255, 218, 185),    -- Peach
        Accent = Color3.fromRGB(255, 105, 180),       -- Hot pink
        
        -- UI colors
        Background = Color3.fromRGB(255, 250, 245),   -- Cream white
        Surface = Color3.fromRGB(255, 255, 255),      -- Pure white
        Text = Color3.fromRGB(50, 50, 50),            -- Dark gray
        TextSecondary = Color3.fromRGB(120, 120, 120), -- Medium gray
        
        -- State colors
        Success = Color3.fromRGB(134, 239, 172),      -- Mint green
        Error = Color3.fromRGB(255, 99, 71),          -- Tomato
        Warning = Color3.fromRGB(255, 206, 84),       -- Yellow
        
        -- Cash tiers
        Cash = {
            Tier1 = Color3.fromRGB(255, 215, 0),      -- Gold
            Tier2 = Color3.fromRGB(255, 105, 180),    -- Hot pink
            Tier3 = Color3.fromRGB(138, 43, 226),     -- Blue violet
        },
        
        -- Gamepass colors
        Gamepass = {
            Common = Color3.fromRGB(200, 200, 200),   -- Silver
            Rare = Color3.fromRGB(100, 200, 255),     -- Sky blue
            Epic = Color3.fromRGB(200, 100, 255),     -- Purple
            Legendary = Color3.fromRGB(255, 200, 50), -- Gold
        }
    },
    
    Fonts = {
        Title = Enum.Font.FredokaOne,
        Header = Enum.Font.Fredoka,
        Body = Enum.Font.Gotham,
        Button = Enum.Font.GothamBold,
        Price = Enum.Font.GothamBlack,
    },
    
    Corners = {
        Small = 8,
        Medium = 12,
        Large = 16,
        XLarge = 24,
        Round = 999,
    },
    
    Padding = {
        Small = 8,
        Medium = 16,
        Large = 24,
        XLarge = 32,
    },
    
    Animation = {
        Fast = 0.2,
        Medium = 0.3,
        Slow = 0.5,
        Spring = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    }
}

-- Sound Manager
local Sounds = {
    list = {
        Open = 5274738643,
        Close = 5274738706,
        Click = 421058925,
        Hover = 10066936758,
        Purchase = 1102831766,
        Success = 5274738797,
        Error = 5274738674,
        Coin = 131961136,
        Sparkle = 5075991510,
    },
    cache = {},
    
    play = function(self, name, volume, pitch)
        local id = self.list[name]
        if not id then return end
        
        local sound = self.cache[name]
        if not sound then
            sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. id
            sound.Volume = 0.5
            sound.Parent = SoundService
            self.cache[name] = sound
        end
        
        sound.Volume = volume or 0.5
        sound.PlaybackSpeed = pitch or 1
        sound:Play()
    end
}

-- Shop Data
local ShopData = {
    Cash = {
        {
            id = 3366419712,
            amount = 1000,
            price = 49,
            name = "Starter Pack",
            icon = "rbxassetid://14703427776",
            color = Design.Colors.Cash.Tier1,
            popular = false,
        },
        {
            id = 3366420478,
            amount = 10000,
            price = 399,
            name = "Value Bundle",
            icon = "rbxassetid://14703428261",
            color = Design.Colors.Cash.Tier2,
            popular = true,
            discount = 20,
        },
        {
            id = 3366420800,
            amount = 25000,
            price = 899,
            name = "Mega Deal",
            icon = "rbxassetid://14703428690",
            color = Design.Colors.Cash.Tier3,
            popular = false,
            discount = 35,
        },
    },
    
    Gamepasses = {
        {
            id = 881932987,
            name = "2x Cash",
            price = 299,
            icon = "rbxassetid://14703429087",
            description = "Double all cash earned!",
            color = Design.Colors.Gamepass.Rare,
        },
        {
            id = 881933249,
            name = "Auto Collect",
            price = 199,
            icon = "rbxassetid://14703429470",
            description = "Automatically collect dropped money",
            color = Design.Colors.Gamepass.Common,
            hasToggle = true,
        },
        {
            id = 881933506,
            name = "VIP Access",
            price = 499,
            icon = "rbxassetid://14703429869",
            description = "Exclusive VIP benefits and areas",
            color = Design.Colors.Gamepass.Epic,
        },
        {
            id = 881933743,
            name = "Speed Boost",
            price = 149,
            icon = "rbxassetid://14703430262",
            description = "Move 50% faster!",
            color = Design.Colors.Gamepass.Common,
        },
        {
            id = 881934088,
            name = "Lucky Charm",
            price = 399,
            icon = "rbxassetid://14703430671",
            description = "Increased luck for rare drops",
            color = Design.Colors.Gamepass.Legendary,
        },
    },
    
    Featured = {
        title = "LIMITED TIME OFFER",
        endTime = os.time() + (24 * 60 * 60), -- 24 hours
        items = {
            {
                type = "bundle",
                name = "Sanrio Starter Bundle",
                originalPrice = 999,
                price = 499,
                icon = "rbxassetid://14703431084",
                includes = {
                    "10,000 Cash",
                    "2x Cash Gamepass",
                    "Exclusive Pet",
                },
                color = Design.Colors.Accent,
            }
        }
    }
}-- Utility Functions
local Utils = {
    comma = function(n)
        local formatted = tostring(n)
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end,
    
    scale = function(value)
        return UDim2.new(value, 0, value, 0)
    end,
    
    tween = function(object, properties, info)
        info = info or Design.Animation.Smooth
        local tween = TweenService:Create(object, info, properties)
        tween:Play()
        return tween
    end,
    
    spring = function(object, properties)
        return Utils.tween(object, properties, Design.Animation.Spring)
    end,
    
    pulse = function(object, scale)
        scale = scale or 1.1
        local original = object.Size
        Utils.spring(object, {Size = Utils.scale(scale)})
        task.wait(0.1)
        Utils.spring(object, {Size = original})
    end,
    
    ripple = function(button, x, y)
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0, x, 0, y)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = Color3.new(1, 1, 1)
        ripple.BackgroundTransparency = 0.7
        ripple.ZIndex = 100
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple
        
        ripple.Parent = button
        
        local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        Utils.tween(ripple, {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1
        }, TweenInfo.new(0.6, Enum.EasingStyle.Quad))
        
        Debris:AddItem(ripple, 0.6)
    end,
    
    shimmer = function(frame)
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 45
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.4, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.7),
            NumberSequenceKeypoint.new(0.6, 0.8),
            NumberSequenceKeypoint.new(1, 1),
        })
        gradient.Parent = frame
        
        local startPos = -1
        local endPos = 2
        
        task.spawn(function()
            while gradient.Parent do
                gradient.Offset = Vector2.new(startPos, 0)
                Utils.tween(gradient, {Offset = Vector2.new(endPos, 0)}, 
                    TweenInfo.new(2, Enum.EasingStyle.Linear))
                task.wait(3)
            end
        end)
        
        return gradient
    end,
    
    glow = function(object, color)
        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.Size = UDim2.new(1.5, 0, 1.5, 0)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = color or Color3.new(1, 1, 1)
        glow.ImageTransparency = 0.5
        glow.ZIndex = object.ZIndex - 1
        glow.Parent = object.Parent
        
        -- Pulse animation
        task.spawn(function()
            while glow.Parent do
                Utils.tween(glow, {
                    Size = UDim2.new(1.8, 0, 1.8, 0),
                    ImageTransparency = 0.7
                }, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                task.wait(1.5)
                Utils.tween(glow, {
                    Size = UDim2.new(1.5, 0, 1.5, 0),
                    ImageTransparency = 0.5
                }, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                task.wait(1.5)
            end
        end)
        
        return glow
    end,
    
    formatTime = function(seconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local secs = seconds % 60
        
        if hours > 0 then
            return string.format("%d:%02d:%02d", hours, minutes, secs)
        else
            return string.format("%d:%02d", minutes, secs)
        end
    end,
    
    isPC = function()
        return not UserInputService.TouchEnabled
    end,
}

-- UI Builder
local UI = {
    create = function(class, properties)
        local instance = Instance.new(class)
        for k, v in pairs(properties) do
            if k ~= "Children" then
                instance[k] = v
            end
        end
        if properties.Children then
            for _, child in pairs(properties.Children) do
                child.Parent = instance
            end
        end
        return instance
    end,
    
    frame = function(props)
        local defaults = {
            BackgroundColor3 = Design.Colors.Surface,
            BorderSizePixel = 0,
        }
        for k, v in pairs(defaults) do
            if props[k] == nil then props[k] = v end
        end
        return UI.create("Frame", props)
    end,
    
    text = function(props)
        local defaults = {
            BackgroundTransparency = 1,
            TextColor3 = Design.Colors.Text,
            Font = Design.Fonts.Body,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
        }
        for k, v in pairs(defaults) do
            if props[k] == nil then props[k] = v end
        end
        return UI.create("TextLabel", props)
    end,
    
    button = function(props)
        local defaults = {
            BackgroundColor3 = Design.Colors.Primary,
            BorderSizePixel = 0,
            Font = Design.Fonts.Button,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            AutoButtonColor = false,
        }
        for k, v in pairs(defaults) do
            if props[k] == nil then props[k] = v end
        end
        
        local button = UI.create("TextButton", props)
        
        -- Add hover effects
        button.MouseEnter:Connect(function()
            Sounds:play("Hover", 0.3, 1.2)
            Utils.spring(button, {Size = UDim2.new(button.Size.X.Scale * 1.05, 0, button.Size.Y.Scale * 1.05, 0)})
        end)
        
        button.MouseLeave:Connect(function()
            Utils.spring(button, {Size = props.Size})
        end)
        
        button.MouseButton1Down:Connect(function()
            Utils.tween(button, {Size = UDim2.new(button.Size.X.Scale * 0.95, 0, button.Size.Y.Scale * 0.95, 0)}, Design.Animation.Fast)
        end)
        
        button.MouseButton1Up:Connect(function()
            Utils.spring(button, {Size = props.Size})
        end)
        
        button.MouseButton1Click:Connect(function()
            Sounds:play("Click", 0.5)
            local x = mouse.X - button.AbsolutePosition.X
            local y = mouse.Y - button.AbsolutePosition.Y
            Utils.ripple(button, x, y)
        end)
        
        return button
    end,
    
    image = function(props)
        local defaults = {
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
        }
        for k, v in pairs(defaults) do
            if props[k] == nil then props[k] = v end
        end
        return UI.create("ImageLabel", props)
    end,
    
    scrolling = function(props)
        local defaults = {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Design.Colors.Primary,
            ScrollBarImageTransparency = 0.5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }
        for k, v in pairs(defaults) do
            if props[k] == nil then props[k] = v end
        end
        return UI.create("ScrollingFrame", props)
    end,
    
    corner = function(radius)
        return UI.create("UICorner", {
            CornerRadius = UDim.new(0, radius or Design.Corners.Medium)
        })
    end,
    
    stroke = function(color, thickness)
        return UI.create("UIStroke", {
            Color = color or Design.Colors.Primary,
            Thickness = thickness or 2,
            Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    end,
    
    padding = function(size)
        size = size or Design.Padding.Medium
        return UI.create("UIPadding", {
            PaddingLeft = UDim.new(0, size),
            PaddingRight = UDim.new(0, size),
            PaddingTop = UDim.new(0, size),
            PaddingBottom = UDim.new(0, size),
        })
    end,
    
    gradient = function(colors, rotation)
        return UI.create("UIGradient", {
            Color = ColorSequence.new(colors),
            Rotation = rotation or 90,
        })
    end,
    
    list = function(padding, order)
        return UI.create("UIListLayout", {
            SortOrder = order or Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, padding or Design.Padding.Small),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        })
    end,
    
    grid = function(cellSize, cellPadding)
        return UI.create("UIGridLayout", {
            CellSize = cellSize or UDim2.new(0.3, -10, 0, 150),
            CellPadding = UDim2.new(0, cellPadding or Design.Padding.Medium, 0, cellPadding or Design.Padding.Medium),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        })
    end,
}-- Cache for ownership checks
local ownershipCache = {}

-- Check gamepass ownership
local function checkOwnership(passId)
    local cacheKey = tostring(passId)
    if ownershipCache[cacheKey] ~= nil then
        return ownershipCache[cacheKey]
    end
    
    local success, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
    end)
    
    if success then
        ownershipCache[cacheKey] = owns
        return owns
    else
        return false
    end
end

-- Shop State
local Shop = {
    gui = nil,
    isOpen = false,
    currentTab = "Home",
    toggleButton = nil,
    animating = false,
    remotes = nil,
}

-- Initialize remotes
task.spawn(function()
    local folder = ReplicatedStorage:WaitForChild("TycoonRemotes", 5)
    if folder then
        Shop.remotes = {
            AutoCollect = folder:FindFirstChild("AutoCollectToggle"),
            MoneyCollected = folder:FindFirstChild("MoneyCollected"),
            GamepassPurchased = folder:FindFirstChild("GamepassPurchased"),
            GetAutoCollectState = folder:FindFirstChild("GetAutoCollectState"),
            GrantCurrency = folder:FindFirstChild("GrantProductCurrency"),
        }
    end
end)

-- Create toggle button
local function createToggleButton()
    local button = UI.button({
        Name = "ShopToggle",
        Size = UDim2.new(0, 60, 0, 60),
        Position = UDim2.new(0, 20, 0.5, -30),
        BackgroundColor3 = Design.Colors.Primary,
        Text = "",
        ZIndex = 100,
        Children = {
            UI.corner(Design.Corners.Round),
            UI.stroke(Design.Colors.Accent, 3),
            UI.image({
                Size = UDim2.new(0.7, 0, 0.7, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = "rbxassetid://14703431523", -- Shop icon
                ImageColor3 = Color3.new(1, 1, 1),
            }),
        }
    })
    
    Utils.glow(button, Design.Colors.Primary)
    
    -- Floating animation
    task.spawn(function()
        while button.Parent do
            Utils.tween(button, {
                Position = UDim2.new(0, 20, 0.5, -35)
            }, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(2)
            Utils.tween(button, {
                Position = UDim2.new(0, 20, 0.5, -25)
            }, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(2)
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        Shop:toggle()
    end)
    
    return button
end

-- Create main shop GUI
local function createShopGUI()
    local screenGui = UI.create("ScreenGui", {
        Name = "SanrioShop",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    -- Background dim
    local dim = UI.frame({
        Name = "Dim",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 1,
    })
    dim.Parent = screenGui
    
    -- Main container
    local container = UI.frame({
        Name = "Container",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })
    container.Parent = screenGui
    
    -- Shop window
    local shopFrame = UI.frame({
        Name = "ShopFrame",
        Size = UDim2.new(0.9, 0, 0.85, 0),
        Position = UDim2.new(0.5, 0, 1.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Design.Colors.Background,
        ZIndex = 10,
        Children = {
            UI.corner(Design.Corners.XLarge),
            UI.stroke(Design.Colors.Primary, 4),
            UI.create("UIScale", {Scale = 0}),
        }
    })
    
    -- Responsive scaling
    local aspectRatio = UI.create("UIAspectRatioConstraint", {
        AspectRatio = 1.6,
        DominantAxis = Enum.DominantAxis.Width,
    })
    aspectRatio.Parent = shopFrame
    
    -- Header
    local header = UI.frame({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = Design.Colors.Primary,
        ZIndex = 11,
        Children = {
            UI.gradient({Design.Colors.Primary, Design.Colors.Accent}),
            UI.corner(Design.Corners.XLarge),
        }
    })
    
    -- Fix header corners
    local headerFix = UI.frame({
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 1, -40),
        BackgroundColor3 = Design.Colors.Primary,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = header,
    })
    
    -- Title
    local title = UI.text({
        Name = "Title",
        Size = UDim2.new(0.7, 0, 0.6, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "SANRIO SHOP",
        Font = Design.Fonts.Title,
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        ZIndex = 12,
        Children = {
            UI.stroke(Design.Colors.Accent, 2),
        }
    })
    title.Parent = header
    
    -- Sparkle effects
    for i = 1, 3 do
        local sparkle = UI.image({
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            Image = "rbxassetid://6026568227",
            ImageColor3 = Color3.new(1, 1, 0.8),
            ZIndex = 13,
            Parent = header,
        })
        
        task.spawn(function()
            while sparkle.Parent do
                local x = math.random()
                local y = math.random()
                sparkle.Position = UDim2.new(x, 0, y, 0)
                sparkle.ImageTransparency = 1
                Utils.tween(sparkle, {
                    ImageTransparency = 0,
                    Rotation = 360,
                }, TweenInfo.new(2, Enum.EasingStyle.Sine))
                task.wait(2)
                Utils.tween(sparkle, {
                    ImageTransparency = 1,
                }, TweenInfo.new(1, Enum.EasingStyle.Sine))
                task.wait(math.random() * 3)
            end
        end)
    end
    
    -- Close button
    local closeButton = UI.button({
        Name = "Close",
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(1, -15, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Text = "×",
        Font = Design.Fonts.Title,
        TextColor3 = Design.Colors.Error,
        TextScaled = false,
        TextSize = 36,
        ZIndex = 13,
        Children = {
            UI.corner(Design.Corners.Round),
            UI.stroke(Design.Colors.Error, 2),
        }
    })
    closeButton.MouseButton1Click:Connect(function()
        Shop:close()
    end)
    closeButton.Parent = header
    
    header.Parent = shopFrame
    
    -- Tab container
    local tabContainer = UI.frame({
        Name = "TabContainer",
        Size = UDim2.new(1, -40, 0, 60),
        Position = UDim2.new(0, 20, 0, 90),
        BackgroundTransparency = 1,
        ZIndex = 11,
        Children = {
            UI.list(Design.Padding.Small, Enum.SortOrder.LayoutOrder),
        }
    })
    
    -- Content container
    local contentContainer = UI.frame({
        Name = "ContentContainer",
        Size = UDim2.new(1, -40, 1, -180),
        Position = UDim2.new(0, 20, 0, 160),
        BackgroundTransparency = 1,
        ZIndex = 11,
    })
    
    tabContainer.Parent = shopFrame
    contentContainer.Parent = shopFrame
    shopFrame.Parent = container
    
    return screenGui, shopFrame, tabContainer, contentContainer
end

-- Tab system
local TabSystem = {
    tabs = {},
    pages = {},
    current = nil,
    
    create = function(self, name, icon, color)
        local tab = UI.button({
            Name = name .. "Tab",
            Size = UDim2.new(0.3, -10, 1, 0),
            BackgroundColor3 = Design.Colors.Surface,
            Text = "",
            LayoutOrder = #self.tabs + 1,
            Children = {
                UI.corner(Design.Corners.Large),
                UI.stroke(color, 2),
                UI.frame({
                    Name = "Content",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Children = {
                        UI.list(Design.Padding.Small),
                        UI.image({
                            Name = "Icon",
                            Size = UDim2.new(0, 24, 0, 24),
                            Image = icon,
                            LayoutOrder = 1,
                        }),
                        UI.text({
                            Name = "Label",
                            Size = UDim2.new(1, -30, 0, 20),
                            Text = name,
                            Font = Design.Fonts.Button,
                            TextScaled = true,
                            LayoutOrder = 2,
                        }),
                    }
                }),
            }
        })
        
        local page = UI.scrolling({
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            Children = {
                UI.padding(Design.Padding.Medium),
            }
        })
        
        tab.MouseButton1Click:Connect(function()
            self:select(name)
        end)
        
        self.tabs[name] = tab
        self.pages[name] = page
        
        return tab, page
    end,
    
    select = function(self, name)
        if self.current == name then return end
        
        -- Hide current page
        if self.current and self.pages[self.current] then
            self.pages[self.current].Visible = false
            Utils.tween(self.tabs[self.current], {
                BackgroundColor3 = Design.Colors.Surface,
                Size = UDim2.new(0.3, -10, 1, 0),
            })
            self.tabs[self.current].Content.Label.Font = Design.Fonts.Button
        end
        
        -- Show new page
        self.current = name
        if self.pages[name] then
            self.pages[name].Visible = true
            Utils.spring(self.tabs[name], {
                BackgroundColor3 = Design.Colors.Primary,
                Size = UDim2.new(0.35, -10, 1.1, 0),
            })
            self.tabs[name].Content.Label.Font = Design.Fonts.Title
        end
        
        Sounds:play("Click", 0.4, 1.1)
    end,
}-- Create item card
local function createItemCard(item, type, container)
    local isOwned = type == "gamepass" and checkOwnership(item.id)
    local cardColor = isOwned and Design.Colors.Success or (item.color or Design.Colors.Surface)
    
    local card = UI.frame({
        Name = item.name .. "Card",
        BackgroundColor3 = Design.Colors.Surface,
        LayoutOrder = item.layoutOrder or 0,
        Children = {
            UI.corner(Design.Corners.Large),
            UI.stroke(cardColor, 3),
            UI.padding(Design.Padding.Medium),
        }
    })
    
    -- Add shimmer for premium items
    if item.popular or item.discount then
        Utils.shimmer(card)
    end
    
    -- Content container
    local content = UI.frame({
        Name = "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Children = {
            UI.list(Design.Padding.Small),
        }
    })
    
    -- Popular/Discount badge
    if item.popular or item.discount then
        local badge = UI.frame({
            Name = "Badge",
            Size = UDim2.new(0, 80, 0, 25),
            Position = UDim2.new(1, -5, 0, 5),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = item.popular and Design.Colors.Accent or Design.Colors.Warning,
            ZIndex = 15,
            Children = {
                UI.corner(Design.Corners.Medium),
                UI.text({
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = item.popular and "POPULAR" or ("-" .. item.discount .. "%"),
                    Font = Design.Fonts.Button,
                    TextScaled = true,
                    TextColor3 = Color3.new(1, 1, 1),
                }),
            }
        })
        badge.Parent = card
    end
    
    -- Icon
    local iconContainer = UI.frame({
        Name = "IconContainer",
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    })
    
    local icon = UI.image({
        Size = UDim2.new(0, 60, 0, 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = item.icon,
        Children = {
            UI.corner(Design.Corners.Medium),
        }
    })
    icon.Parent = iconContainer
    
    if isOwned then
        Utils.glow(icon, Design.Colors.Success)
    end
    
    -- Name
    local nameLabel = UI.text({
        Name = "ItemName",
        Size = UDim2.new(1, 0, 0, 25),
        Text = item.name,
        Font = Design.Fonts.Header,
        TextScaled = true,
        LayoutOrder = 2,
    })
    
    -- Description or amount
    if type == "cash" then
        local amountLabel = UI.text({
            Name = "Amount",
            Size = UDim2.new(1, 0, 0, 20),
            Text = Utils.comma(item.amount) .. " Cash",
            Font = Design.Fonts.Body,
            TextColor3 = Design.Colors.TextSecondary,
            TextScaled = true,
            LayoutOrder = 3,
        })
        amountLabel.Parent = content
    elseif item.description then
        local descLabel = UI.text({
            Name = "Description",
            Size = UDim2.new(1, 0, 0, 30),
            Text = item.description,
            Font = Design.Fonts.Body,
            TextColor3 = Design.Colors.TextSecondary,
            TextScaled = true,
            TextWrapped = true,
            LayoutOrder = 3,
        })
        descLabel.Parent = content
    end
    
    -- Price/Purchase button
    local buttonContainer = UI.frame({
        Name = "ButtonContainer",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        LayoutOrder = 4,
    })
    
    if isOwned then
        local ownedLabel = UI.frame({
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Design.Colors.Success,
            Children = {
                UI.corner(Design.Corners.Medium),
                UI.text({
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "OWNED",
                    Font = Design.Fonts.Button,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                }),
            }
        })
        ownedLabel.Parent = buttonContainer
        
        -- Add toggle for auto-collect
        if item.hasToggle and Shop.remotes and Shop.remotes.AutoCollect then
            local toggleButton = UI.button({
                Size = UDim2.new(0.8, 0, 0, 30),
                Position = UDim2.new(0.5, 0, 1, 10),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Design.Colors.Primary,
                Text = "Toggle Auto-Collect",
                Font = Design.Fonts.Button,
                TextScaled = true,
                TextColor3 = Color3.new(1, 1, 1),
                Children = {
                    UI.corner(Design.Corners.Small),
                }
            })
            
            toggleButton.MouseButton1Click:Connect(function()
                Shop.remotes.AutoCollect:FireServer()
                Sounds:play("Click", 0.5)
            end)
            
            toggleButton.Parent = card
        end
    else
        local purchaseButton = UI.button({
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = cardColor,
            Text = "R$" .. tostring(item.price),
            Font = Design.Fonts.Price,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            Children = {
                UI.corner(Design.Corners.Medium),
                UI.gradient({cardColor, item.color or Design.Colors.Primary}),
            }
        })
        
        -- Original price for discounts
        if item.discount and item.originalPrice then
            local originalLabel = UI.text({
                Size = UDim2.new(0, 60, 0, 15),
                Position = UDim2.new(0.5, 0, 0, -5),
                AnchorPoint = Vector2.new(0.5, 0),
                Text = "R$" .. item.originalPrice,
                Font = Design.Fonts.Body,
                TextColor3 = Design.Colors.TextSecondary,
                TextScaled = true,
                Children = {
                    UI.frame({
                        Size = UDim2.new(1, 0, 0, 1),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Design.Colors.TextSecondary,
                        BorderSizePixel = 0,
                    })
                }
            })
            originalLabel.Parent = purchaseButton
        end
        
        purchaseButton.MouseButton1Click:Connect(function()
            if type == "cash" then
                MarketplaceService:PromptProductPurchase(player, item.id)
            else
                MarketplaceService:PromptGamePassPurchase(player, item.id)
            end
            Sounds:play("Click", 0.6)
        end)
        
        purchaseButton.Parent = buttonContainer
    end
    
    iconContainer.Parent = content
    nameLabel.Parent = content
    buttonContainer.Parent = content
    content.Parent = card
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        Utils.spring(card, {Size = UDim2.new(card.Size.X.Scale * 1.05, 0, card.Size.Y.Scale * 1.05, 0)})
    end)
    
    card.MouseLeave:Connect(function()
        Utils.spring(card, {Size = UDim2.new(card.Size.X.Scale / 1.05, 0, card.Size.Y.Scale / 1.05, 0)})
    end)
    
    return card
end

-- Build shop pages
local function buildHomePage(page)
    -- Welcome section
    local welcomeSection = UI.frame({
        Name = "Welcome",
        Size = UDim2.new(1, 0, 0, 120),
        BackgroundColor3 = Design.Colors.Primary,
        LayoutOrder = 1,
        Children = {
            UI.corner(Design.Corners.Large),
            UI.gradient({Design.Colors.Primary, Design.Colors.Secondary}),
            UI.padding(Design.Padding.Large),
            UI.text({
                Size = UDim2.new(1, 0, 0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                Text = "Welcome to Sanrio Shop!",
                Font = Design.Fonts.Title,
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
            }),
            UI.text({
                Size = UDim2.new(1, 0, 0.3, 0),
                Position = UDim2.new(0.5, 0, 0.6, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                Text = "Get exclusive items and boosts!",
                Font = Design.Fonts.Body,
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
            }),
        }
    })
    
    -- Featured section
    if ShopData.Featured and #ShopData.Featured.items > 0 then
        local featuredSection = UI.frame({
            Name = "Featured",
            Size = UDim2.new(1, 0, 0, 200),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Children = {
                UI.list(Design.Padding.Medium),
            }
        })
        
        local featuredHeader = UI.text({
            Size = UDim2.new(1, 0, 0, 30),
            Text = ShopData.Featured.title,
            Font = Design.Fonts.Header,
            TextColor3 = Design.Colors.Accent,
            LayoutOrder = 1,
        })
        
        -- Timer
        local timerLabel = UI.text({
            Size = UDim2.new(1, 0, 0, 20),
            Text = "Ends in: --:--:--",
            Font = Design.Fonts.Body,
            TextColor3 = Design.Colors.Error,
            LayoutOrder = 2,
        })
        
        task.spawn(function()
            while timerLabel.Parent do
                local remaining = ShopData.Featured.endTime - os.time()
                if remaining > 0 then
                    timerLabel.Text = "Ends in: " .. Utils.formatTime(remaining)
                else
                    timerLabel.Text = "EXPIRED"
                    timerLabel.TextColor3 = Design.Colors.TextSecondary
                end
                task.wait(1)
            end
        end)
        
        featuredHeader.Parent = featuredSection
        timerLabel.Parent = featuredSection
        
        -- Featured items
        for _, item in ipairs(ShopData.Featured.items) do
            local card = createItemCard(item, "featured", featuredSection)
            card.Size = UDim2.new(1, 0, 0, 120)
            card.LayoutOrder = 3
            card.Parent = featuredSection
        end
        
        featuredSection.Parent = page
    end
    
    -- Quick links
    local quickLinks = UI.frame({
        Name = "QuickLinks",
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Children = {
            UI.grid(UDim2.new(0.45, 0, 0, 80), Design.Padding.Medium),
        }
    })
    
    local cashButton = UI.button({
        BackgroundColor3 = Design.Colors.Cash.Tier2,
        Text = "Get Cash",
        Font = Design.Fonts.Button,
        TextColor3 = Color3.new(1, 1, 1),
        LayoutOrder = 1,
        Children = {
            UI.corner(Design.Corners.Medium),
            UI.gradient({Design.Colors.Cash.Tier1, Design.Colors.Cash.Tier2}),
        }
    })
    cashButton.MouseButton1Click:Connect(function()
        TabSystem:select("Cash")
    end)
    
    local passButton = UI.button({
        BackgroundColor3 = Design.Colors.Gamepass.Epic,
        Text = "Gamepasses",
        Font = Design.Fonts.Button,
        TextColor3 = Color3.new(1, 1, 1),
        LayoutOrder = 2,
        Children = {
            UI.corner(Design.Corners.Medium),
            UI.gradient({Design.Colors.Gamepass.Rare, Design.Colors.Gamepass.Epic}),
        }
    })
    passButton.MouseButton1Click:Connect(function()
        TabSystem:select("Gamepasses")
    end)
    
    cashButton.Parent = quickLinks
    passButton.Parent = quickLinks
    
    welcomeSection.Parent = page
    quickLinks.Parent = page
    
    -- Update canvas size
    page.CanvasSize = UDim2.new(0, 0, 0, page.UIListLayout.AbsoluteContentSize.Y + 40)
    page.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, page.UIListLayout.AbsoluteContentSize.Y + 40)
    end)
end

local function buildCashPage(page)
    local grid = UI.grid(UDim2.new(0.3, -10, 0, 180), Design.Padding.Medium)
    grid.Parent = page
    
    for i, product in ipairs(ShopData.Cash) do
        local card = createItemCard(product, "cash", page)
        card.LayoutOrder = i
        card.Parent = page
    end
    
    -- Update canvas size
    page.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 40)
    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 40)
    end)
end

local function buildGamepassPage(page)
    local grid = UI.grid(UDim2.new(0.3, -10, 0, 200), Design.Padding.Medium)
    grid.Parent = page
    
    for i, pass in ipairs(ShopData.Gamepasses) do
        local card = createItemCard(pass, "gamepass", page)
        card.LayoutOrder = i
        card.Parent = page
    end
    
    -- Update canvas size
    page.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 40)
    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 40)
    end)
end-- Shop methods
function Shop:init()
    if self.gui then return end
    
    -- Create GUI
    local gui, frame, tabContainer, contentContainer = createShopGUI()
    self.gui = gui
    self.frame = frame
    
    -- Create tabs
    local homeTab, homePage = TabSystem:create("Home", "rbxassetid://14703432003", Design.Colors.Primary)
    local cashTab, cashPage = TabSystem:create("Cash", "rbxassetid://14703432421", Design.Colors.Cash.Tier2)
    local passTab, passPage = TabSystem:create("Gamepasses", "rbxassetid://14703432832", Design.Colors.Gamepass.Epic)
    
    homeTab.Parent = tabContainer
    cashTab.Parent = tabContainer
    passTab.Parent = tabContainer
    
    homePage.Parent = contentContainer
    cashPage.Parent = contentContainer
    passPage.Parent = contentContainer
    
    -- Build pages
    buildHomePage(homePage)
    buildCashPage(cashPage)
    buildGamepassPage(passPage)
    
    -- Create toggle button
    self.toggleButton = createToggleButton()
    self.toggleButton.Parent = gui
    
    gui.Parent = playerGui
end

function Shop:open()
    if self.animating or self.isOpen then return end
    self.animating = true
    self.isOpen = true
    
    Sounds:play("Open", 0.6)
    
    -- Show GUI
    self.gui.Enabled = true
    
    -- Animate in
    Utils.tween(self.gui.Dim, {BackgroundTransparency = 0.3})
    
    self.frame.Position = UDim2.new(0.5, 0, 1.5, 0)
    self.frame.UIScale.Scale = 0.8
    
    Utils.spring(self.frame, {Position = UDim2.new(0.5, 0, 0.5, 0)})
    Utils.spring(self.frame.UIScale, {Scale = 1})
    
    -- Select Home tab by default
    TabSystem:select("Home")
    
    task.wait(0.5)
    self.animating = false
end

function Shop:close()
    if self.animating or not self.isOpen then return end
    self.animating = true
    self.isOpen = false
    
    Sounds:play("Close", 0.5)
    
    -- Animate out
    Utils.tween(self.gui.Dim, {BackgroundTransparency = 1})
    Utils.tween(self.frame, {Position = UDim2.new(0.5, 0, 1.5, 0)})
    Utils.tween(self.frame.UIScale, {Scale = 0.8})
    
    task.wait(0.3)
    self.gui.Enabled = false
    self.animating = false
end

function Shop:toggle()
    if self.isOpen then
        self:close()
    else
        self:open()
    end
end

-- Purchase handlers
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
    if userId == player.UserId and wasPurchased then
        Sounds:play("Success", 0.7)
        
        -- Find product and show effect
        for _, product in ipairs(ShopData.Cash) do
            if product.id == productId then
                -- Fire remote if available
                if Shop.remotes and Shop.remotes.GrantCurrency then
                    Shop.remotes.GrantCurrency:FireServer(productId)
                end
                
                -- Show success effect
                local successLabel = UI.text({
                    Size = UDim2.new(0, 300, 0, 60),
                    Position = UDim2.new(0.5, 0, 0.9, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Design.Colors.Success,
                    Text = "+" .. Utils.comma(product.amount) .. " Cash!",
                    Font = Design.Fonts.Title,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    ZIndex = 1000,
                    Children = {
                        UI.corner(Design.Corners.Large),
                        UI.stroke(Color3.new(1, 1, 1), 3),
                    }
                })
                
                successLabel.Parent = Shop.gui
                
                Utils.spring(successLabel, {
                    Position = UDim2.new(0.5, 0, 0.8, 0),
                    Size = UDim2.new(0, 350, 0, 70),
                })
                
                task.wait(2)
                Utils.tween(successLabel, {
                    Position = UDim2.new(0.5, 0, 0.7, 0),
                    BackgroundTransparency = 1,
                    TextTransparency = 1,
                })
                
                task.wait(0.5)
                successLabel:Destroy()
                break
            end
        end
    end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(userId, passId, wasPurchased)
    if userId == player.UserId and wasPurchased then
        -- Clear cache
        ownershipCache[tostring(passId)] = true
        
        Sounds:play("Success", 0.8)
        
        -- Fire remote
        if Shop.remotes and Shop.remotes.GamepassPurchased then
            Shop.remotes.GamepassPurchased:FireServer(passId)
        end
        
        -- Refresh gamepass page
        local passPage = TabSystem.pages["Gamepasses"]
        if passPage then
            for _, child in pairs(passPage:GetChildren()) do
                if child:IsA("Frame") and child.Name:match("Card") then
                    child:Destroy()
                end
            end
            buildGamepassPage(passPage)
        end
        
        -- Show success
        local successLabel = UI.text({
            Size = UDim2.new(0, 300, 0, 60),
            Position = UDim2.new(0.5, 0, 0.9, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Design.Colors.Success,
            Text = "Purchase Successful!",
            Font = Design.Fonts.Title,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            ZIndex = 1000,
            Children = {
                UI.corner(Design.Corners.Large),
                UI.stroke(Color3.new(1, 1, 1), 3),
            }
        })
        
        successLabel.Parent = Shop.gui
        
        -- Confetti effect
        for i = 1, 20 do
            task.spawn(function()
                local confetti = UI.frame({
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0.5, math.random(-100, 100), 0.5, 0),
                    BackgroundColor3 = Color3.fromHSV(math.random(), 1, 1),
                    Rotation = math.random(360),
                    ZIndex = 999,
                    Children = {
                        UI.corner(2),
                    }
                })
                
                confetti.Parent = Shop.gui
                
                local endPos = UDim2.new(confetti.Position.X.Scale, confetti.Position.X.Offset + math.random(-200, 200), 1, 100)
                
                Utils.tween(confetti, {
                    Position = endPos,
                    Rotation = confetti.Rotation + math.random(-720, 720),
                    BackgroundTransparency = 1,
                }, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                
                Debris:AddItem(confetti, 2)
            end)
        end
        
        task.wait(2)
        Utils.tween(successLabel, {
            BackgroundTransparency = 1,
            TextTransparency = 1,
        })
        
        task.wait(0.5)
        successLabel:Destroy()
    end
end)

-- Money collection effects
local function setupMoneyEffects()
    local folder = ReplicatedStorage:WaitForChild("TycoonRemotes", 5)
    if not folder then return end
    
    local moneyCollected = folder:FindFirstChild("MoneyCollected")
    if not moneyCollected then return end
    
    moneyCollected.OnClientEvent:Connect(function(amount, position)
        Sounds:play("Coin", 0.4, 1 + math.random() * 0.2)
        
        -- Create floating text
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 100, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 2, 0)
        billboardGui.AlwaysOnTop = true
        
        local textLabel = UI.text({
            Size = UDim2.new(1, 0, 1, 0),
            Text = "+$" .. Utils.comma(amount),
            Font = Design.Fonts.Price,
            TextColor3 = Design.Colors.Cash.Tier1,
            TextScaled = true,
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.new(0, 0, 0),
        })
        
        textLabel.Parent = billboardGui
        
        -- Create part at position
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Position = position
        part.Parent = workspace
        
        billboardGui.Parent = part
        
        -- Animate
        Utils.tween(part, {
            Position = position + Vector3.new(0, 5, 0)
        }, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        Utils.tween(textLabel, {
            TextTransparency = 1,
            TextStrokeTransparency = 1
        }, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        
        Debris:AddItem(part, 1)
    end)
end

-- Initialize
Shop:init()
task.spawn(setupMoneyEffects)

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        Shop:toggle()
    end
end)

print("Sanrio Shop Professional loaded!")