--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - COMPLETE UI POLISH SYSTEM                      ║
    ║                              AAA Quality UI Overhaul Module                           ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local UIPolishSystem = {}
UIPolishSystem.__index = UIPolishSystem

-- ========================================
-- SERVICES & DEPENDENCIES
-- ========================================
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

-- ========================================
-- PREMIUM UI CONSTANTS
-- ========================================

-- POSITIONING FIXES - NO MORE LOW UIs!
local PREMIUM_UI_POSITIONS = {
    MainFrame = UDim2.new(0, 30, 0, 30),      -- Raised significantly
    SecondaryFrame = UDim2.new(0, 40, 0, 40),  -- Even more padding
    Modal = UDim2.new(0.5, 0, 0.5, -20),       -- Centered but slightly raised
    Popup = UDim2.new(0.5, 0, 0.4, 0),         -- Upper center for popups
}

local PREMIUM_UI_SIZES = {
    MainFrame = UDim2.new(1, -60, 1, -80),     -- Proper margins all around
    Modal = UDim2.new(0, 600, 0, 400),         -- Standard modal size
    Popup = UDim2.new(0, 400, 0, 300),         -- Smaller popups
}

-- ANIMATION TWEENS - SMOOTH AS BUTTER
local PREMIUM_TWEENS = {
    -- Ultra smooth transitions
    UltraSmooth = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    
    -- Bouncy for fun elements
    Bounce = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.1),
    Elastic = TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    
    -- Quick for responsive feel
    Instant = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    
    -- Special effects
    Hover = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    Click = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
    
    -- Case opening special
    CaseSpin = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    CaseReveal = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

-- MODERN COLORS - NO MORE UGLY PINK
local MODERN_COLORS = {
    -- Gradient colors for backgrounds
    GradientStart = Color3.fromRGB(30, 30, 40),
    GradientEnd = Color3.fromRGB(50, 40, 70),
    
    -- Glass morphism
    Glass = Color3.fromRGB(255, 255, 255),
    GlassTransparency = 0.85,
    
    -- Accent colors
    AccentPrimary = Color3.fromRGB(120, 80, 255),   -- Purple
    AccentSecondary = Color3.fromRGB(255, 80, 120), -- Soft red
    AccentSuccess = Color3.fromRGB(80, 255, 150),   -- Mint green
    
    -- Glow effects
    GlowBlue = Color3.fromRGB(100, 200, 255),
    GlowPurple = Color3.fromRGB(200, 100, 255),
    GlowGold = Color3.fromRGB(255, 220, 100),
}

-- ========================================
-- INITIALIZATION
-- ========================================

function UIPolishSystem.new(config)
    local self = setmetatable({}, UIPolishSystem)
    
    self._config = config
    self._polishedElements = {}
    self._activeAnimations = {}
    self._soundCache = {}
    self._particleEmitters = {}
    
    -- Start background services
    self:InitializeBackgroundEffects()
    
    return self
end

-- ========================================
-- MAIN POLISH FUNCTIONS
-- ========================================

function UIPolishSystem:PolishAllUI()
    -- This is the main function that polishes EVERYTHING
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Find all UI elements and polish them
    for _, screenGui in ipairs(playerGui:GetChildren()) do
        if screenGui:IsA("ScreenGui") then
            self:PolishScreenGui(screenGui)
        end
    end
end

function UIPolishSystem:PolishScreenGui(screenGui)
    -- Polish each element in the ScreenGui
    for _, element in ipairs(screenGui:GetDescendants()) do
        if element:IsA("Frame") then
            self:PolishFrame(element)
        elseif element:IsA("TextButton") or element:IsA("ImageButton") then
            self:PolishButton(element)
        elseif element:IsA("ScrollingFrame") then
            self:PolishScrollingFrame(element)
        elseif element:IsA("TextBox") then
            self:PolishTextBox(element)
        end
    end
end

-- ========================================
-- FRAME POSITIONING FIXES
-- ========================================

function UIPolishSystem:PolishFrame(frame)
    local frameName = frame.Name:lower()
    
    -- Fix main UI frames that are too low
    if frameName:find("frame") and frameName:find("main") or 
       frameName:find("inventory") or frameName:find("shop") or 
       frameName:find("quest") or frameName:find("settings") then
        
        -- RAISE THE UI!
        if frame.Position.Y.Offset == 80 then -- Old position
            self:AnimatePosition(frame, UDim2.new(0, 30, 0, 30))
        end
        
        -- Add glass morphism effect
        self:AddGlassMorphism(frame)
        
        -- Add subtle shadow
        self:AddDropShadow(frame)
        
        -- Add entrance animation
        self:AddEntranceAnimation(frame)
    end
    
    -- Add breathing animation to cards
    if frameName:find("card") then
        self:AddBreathingAnimation(frame)
        self:Add3DTiltEffect(frame)
    end
end

-- ========================================
-- BUTTON ENHANCEMENTS
-- ========================================

function UIPolishSystem:PolishButton(button)
    -- Store original properties
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    local originalPosition = button.Position
    
    -- Add hover glow
    local glowFrame = self:CreateGlowFrame(button)
    
    -- Mouse enter - SMOOTH HOVER
    button.MouseEnter:Connect(function()
        -- Scale up
        TweenService:Create(button, PREMIUM_TWEENS.Hover, {
            Size = UDim2.new(
                originalSize.X.Scale * 1.05,
                originalSize.X.Offset * 1.05,
                originalSize.Y.Scale * 1.05,
                originalSize.Y.Offset * 1.05
            ),
            BackgroundColor3 = self:LightenColor(originalColor, 0.2)
        }):Play()
        
        -- Glow effect
        TweenService:Create(glowFrame, PREMIUM_TWEENS.Hover, {
            BackgroundTransparency = 0.6,
            Size = UDim2.new(1.2, 0, 1.2, 0)
        }):Play()
        
        -- Hover sound
        self:PlayUISound("Hover")
        
        -- Add floating animation
        self:StartFloatingAnimation(button)
    end)
    
    -- Mouse leave
    button.MouseLeave:Connect(function()
        -- Reset size
        TweenService:Create(button, PREMIUM_TWEENS.Hover, {
            Size = originalSize,
            BackgroundColor3 = originalColor
        }):Play()
        
        -- Remove glow
        TweenService:Create(glowFrame, PREMIUM_TWEENS.Hover, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1.1, 0, 1.1, 0)
        }):Play()
        
        -- Stop floating
        self:StopFloatingAnimation(button)
    end)
    
    -- Click animation - JUICY FEEDBACK
    button.MouseButton1Down:Connect(function()
        -- Shrink
        TweenService:Create(button, PREMIUM_TWEENS.Click, {
            Size = UDim2.new(
                originalSize.X.Scale * 0.95,
                originalSize.X.Offset * 0.95,
                originalSize.Y.Scale * 0.95,
                originalSize.Y.Offset * 0.95
            )
        }):Play()
        
        -- Click sound
        self:PlayUISound("Click")
        
        -- Ripple effect
        self:CreateRippleEffect(button)
    end)
    
    button.MouseButton1Up:Connect(function()
        -- Bounce back
        TweenService:Create(button, PREMIUM_TWEENS.Bounce, {
            Size = originalSize
        }):Play()
        
        -- Particle burst
        self:CreateClickParticles(button)
    end)
end

-- ========================================
-- SCROLLING FRAME POLISH
-- ========================================

function UIPolishSystem:PolishScrollingFrame(scrollFrame)
    -- Smooth scrolling with momentum
    local lastScrollPosition = scrollFrame.CanvasPosition
    local velocity = Vector2.new(0, 0)
    local scrollConnection
    
    scrollConnection = RunService.Heartbeat:Connect(function(dt)
        if velocity.Magnitude > 0.1 then
            -- Apply momentum
            scrollFrame.CanvasPosition = scrollFrame.CanvasPosition + velocity * dt * 60
            
            -- Damping
            velocity = velocity * 0.9
            
            -- Elastic bounce at edges
            local maxY = scrollFrame.AbsoluteCanvasSize.Y - scrollFrame.AbsoluteSize.Y
            if scrollFrame.CanvasPosition.Y < 0 then
                scrollFrame.CanvasPosition = Vector2.new(scrollFrame.CanvasPosition.X, 0)
                velocity = Vector2.new(velocity.X, -velocity.Y * 0.5)
            elseif scrollFrame.CanvasPosition.Y > maxY then
                scrollFrame.CanvasPosition = Vector2.new(scrollFrame.CanvasPosition.X, maxY)
                velocity = Vector2.new(velocity.X, -velocity.Y * 0.5)
            end
        end
    end)
    
    -- Track scrolling for momentum
    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local delta = scrollFrame.CanvasPosition - lastScrollPosition
        velocity = delta * 10
        lastScrollPosition = scrollFrame.CanvasPosition
    end)
    
    -- Fade scrollbar
    scrollFrame.ScrollBarImageTransparency = 0.7
    
    scrollFrame.MouseEnter:Connect(function()
        TweenService:Create(scrollFrame, PREMIUM_TWEENS.Fast, {
            ScrollBarImageTransparency = 0.3
        }):Play()
    end)
    
    scrollFrame.MouseLeave:Connect(function()
        TweenService:Create(scrollFrame, PREMIUM_TWEENS.Fast, {
            ScrollBarImageTransparency = 0.7
        }):Play()
    end)
end

-- ========================================
-- CASE OPENING REDESIGN
-- ========================================

function UIPolishSystem:CreatePremiumCaseOpening(parent)
    -- Complete redesign - NO MORE UGLY PINK!
    
    -- Dark elegant background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    background.BackgroundTransparency = 0.2
    background.Parent = parent
    
    -- Animated gradient overlay
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 0
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, MODERN_COLORS.GradientStart),
        ColorSequenceKeypoint.new(0.5, MODERN_COLORS.AccentPrimary),
        ColorSequenceKeypoint.new(1, MODERN_COLORS.GradientEnd)
    })
    gradient.Parent = background
    
    -- Animate gradient rotation
    spawn(function()
        while background.Parent do
            TweenService:Create(gradient, TweenInfo.new(5, Enum.EasingStyle.Linear), {
                Rotation = 360
            }):Play()
            wait(5)
            gradient.Rotation = 0
        end
    end)
    
    -- Spinning wheel container
    local wheelContainer = Instance.new("Frame")
    wheelContainer.Size = UDim2.new(0, 800, 0, 200)
    wheelContainer.Position = UDim2.new(0.5, -400, 0.5, -100)
    wheelContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    wheelContainer.ClipsDescendants = true
    wheelContainer.Parent = parent
    
    -- Premium border with glow
    local border = Instance.new("UIStroke")
    border.Color = MODERN_COLORS.AccentPrimary
    border.Thickness = 3
    border.Transparency = 0
    border.Parent = wheelContainer
    
    -- Animated border glow
    spawn(function()
        while border.Parent do
            TweenService:Create(border, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = MODERN_COLORS.GlowPurple
            }):Play()
            wait(1)
            TweenService:Create(border, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = MODERN_COLORS.GlowBlue
            }):Play()
            wait(1)
        end
    end)
    
    -- Add particles around the wheel
    self:CreateCaseParticles(parent)
    
    return wheelContainer
end

-- ========================================
-- VISUAL EFFECTS
-- ========================================

function UIPolishSystem:AddGlassMorphism(frame)
    -- Modern glass effect
    frame.BackgroundColor3 = MODERN_COLORS.Glass
    frame.BackgroundTransparency = MODERN_COLORS.GlassTransparency
    
    -- Blur effect (simulated)
    local blur = Instance.new("Frame")
    blur.Size = UDim2.new(1, 10, 1, 10)
    blur.Position = UDim2.new(0, -5, 0, -5)
    blur.BackgroundColor3 = frame.BackgroundColor3
    blur.BackgroundTransparency = 0.9
    blur.ZIndex = frame.ZIndex - 1
    blur.Parent = frame.Parent
    
    local blurCorner = Instance.new("UICorner")
    blurCorner.CornerRadius = UDim.new(0, 12)
    blurCorner.Parent = blur
end

function UIPolishSystem:AddDropShadow(frame)
    -- Multiple shadow layers for depth
    for i = 1, 3 do
        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(1, i * 4, 1, i * 4)
        shadow.Position = UDim2.new(0, i * 2, 0, i * 2)
        shadow.BackgroundColor3 = Color3.new(0, 0, 0)
        shadow.BackgroundTransparency = 0.9 + (i * 0.03)
        shadow.ZIndex = frame.ZIndex - i
        shadow.Parent = frame.Parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12 + i * 2)
        corner.Parent = shadow
    end
end

function UIPolishSystem:CreateGlowFrame(button)
    local glow = Instance.new("Frame")
    glow.Name = "GlowEffect"
    glow.Size = UDim2.new(1.1, 0, 1.1, 0)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundColor3 = MODERN_COLORS.AccentPrimary
    glow.BackgroundTransparency = 1
    glow.ZIndex = button.ZIndex - 1
    glow.Parent = button.Parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = glow
    
    -- Position glow behind button
    button.ZIndex = button.ZIndex + 1
    
    return glow
end

function UIPolishSystem:CreateRippleEffect(button)
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 10, 0, 10)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.3
    ripple.ZIndex = button.ZIndex + 1
    ripple.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = ripple
    
    -- Animate ripple
    local tween = TweenService:Create(ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(2, 0, 2, 0),
        BackgroundTransparency = 1
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

-- ========================================
-- ANIMATIONS
-- ========================================

function UIPolishSystem:AddEntranceAnimation(frame)
    -- Store original values
    local originalPosition = frame.Position
    local originalSize = frame.Size
    
    -- Start from bottom
    frame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 100)
    frame.Size = UDim2.new(0, 0, 0, 0)
    
    -- Animate in
    wait(0.1)
    
    TweenService:Create(frame, PREMIUM_TWEENS.Elastic, {
        Position = originalPosition,
        Size = originalSize
    }):Play()
    
    -- Add fade in
    local function fadeIn(obj)
        if obj:IsA("Frame") then
            obj.BackgroundTransparency = 1
            TweenService:Create(obj, PREMIUM_TWEENS.Smooth, {
                BackgroundTransparency = obj:GetAttribute("OriginalTransparency") or 0
            }):Play()
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            obj.TextTransparency = 1
            TweenService:Create(obj, PREMIUM_TWEENS.Smooth, {
                TextTransparency = 0
            }):Play()
        end
    end
    
    fadeIn(frame)
    for _, child in ipairs(frame:GetDescendants()) do
        fadeIn(child)
    end
end

function UIPolishSystem:AddBreathingAnimation(frame)
    -- Subtle scale animation
    local originalSize = frame.Size
    
    spawn(function()
        while frame.Parent do
            TweenService:Create(frame, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(
                    originalSize.X.Scale * 1.02,
                    originalSize.X.Offset,
                    originalSize.Y.Scale * 1.02,
                    originalSize.Y.Offset
                )
            }):Play()
            wait(2)
            TweenService:Create(frame, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = originalSize
            }):Play()
            wait(2)
        end
    end)
end

function UIPolishSystem:Add3DTiltEffect(frame)
    local mouse = Players.LocalPlayer:GetMouse()
    
    frame.MouseEnter:Connect(function()
        self._tiltConnection = RunService.Heartbeat:Connect(function()
            local framePos = frame.AbsolutePosition + frame.AbsoluteSize / 2
            local mousePos = Vector2.new(mouse.X, mouse.Y)
            local delta = (mousePos - framePos) / frame.AbsoluteSize
            
            -- Clamp delta
            delta = Vector2.new(
                math.clamp(delta.X, -0.5, 0.5),
                math.clamp(delta.Y, -0.5, 0.5)
            )
            
            -- Apply rotation (simulated with position offset)
            frame.Position = UDim2.new(
                frame.Position.X.Scale,
                frame.Position.X.Offset + delta.X * 5,
                frame.Position.Y.Scale,
                frame.Position.Y.Offset - delta.Y * 5
            )
        end)
    end)
    
    frame.MouseLeave:Connect(function()
        if self._tiltConnection then
            self._tiltConnection:Disconnect()
        end
        
        -- Reset position
        TweenService:Create(frame, PREMIUM_TWEENS.Fast, {
            Position = frame:GetAttribute("OriginalPosition") or frame.Position
        }):Play()
    end)
end

function UIPolishSystem:StartFloatingAnimation(element)
    local floatTween = TweenService:Create(element, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Position = UDim2.new(
            element.Position.X.Scale,
            element.Position.X.Offset,
            element.Position.Y.Scale,
            element.Position.Y.Offset - 5
        )
    })
    
    floatTween:Play()
    self._activeAnimations[element] = floatTween
end

function UIPolishSystem:StopFloatingAnimation(element)
    local tween = self._activeAnimations[element]
    if tween then
        tween:Cancel()
        self._activeAnimations[element] = nil
    end
end

-- ========================================
-- PARTICLE EFFECTS
-- ========================================

function UIPolishSystem:CreateClickParticles(button)
    for i = 1, 10 do
        spawn(function()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))
            particle.Position = UDim2.new(0.5, 0, 0.5, 0)
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.BackgroundColor3 = MODERN_COLORS.AccentPrimary
            particle.ZIndex = 999
            particle.Parent = button
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
            
            -- Random direction
            local angle = math.random() * math.pi * 2
            local distance = math.random(30, 60)
            
            TweenService:Create(particle, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance),
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            
            Debris:AddItem(particle, 0.6)
        end)
    end
end

function UIPolishSystem:CreateCaseParticles(parent)
    -- Ambient floating particles
    for i = 1, 30 do
        spawn(function()
            wait(math.random() * 2)
            
            while parent.Parent do
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
                particle.Position = UDim2.new(math.random(), 0, 1, 10)
                particle.BackgroundColor3 = MODERN_COLORS.GlowGold
                particle.BackgroundTransparency = 0.5
                particle.ZIndex = 50
                particle.Parent = parent
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0.5, 0)
                corner.Parent = particle
                
                -- Float up with slight wave
                local startX = particle.Position.X.Scale
                local floatTween = TweenService:Create(particle, TweenInfo.new(math.random(3, 5), Enum.EasingStyle.Linear), {
                    Position = UDim2.new(startX + (math.random() - 0.5) * 0.1, 0, -0.1, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 0, 0)
                })
                
                floatTween:Play()
                floatTween.Completed:Connect(function()
                    particle:Destroy()
                end)
                
                wait(math.random() * 0.5)
            end
        end)
    end
end

-- ========================================
-- SOUND SYSTEM
-- ========================================

function UIPolishSystem:InitializeSounds()
    self._sounds = {
        Hover = "rbxassetid://421058925",
        Click = "rbxassetid://421058940",
        Success = "rbxassetid://421058993",
        Open = "rbxassetid://421058918",
        Close = "rbxassetid://421058884",
        Woosh = "rbxassetid://421058853",
        Pop = "rbxassetid://421058779",
    }
end

function UIPolishSystem:PlayUISound(soundName, volume)
    local soundId = self._sounds[soundName]
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.3
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIPolishSystem:AnimatePosition(element, newPosition)
    TweenService:Create(element, PREMIUM_TWEENS.Smooth, {
        Position = newPosition
    }):Play()
end

function UIPolishSystem:LightenColor(color, amount)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s * (1 - amount * 0.5), math.min(1, v + amount))
end

function UIPolishSystem:InitializeBackgroundEffects()
    -- Initialize sounds
    self:InitializeSounds()
    
    -- Start monitoring for new UI elements
    RunService.Heartbeat:Connect(function()
        -- Auto-polish new elements
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and not self._polishedElements[gui] then
                self._polishedElements[gui] = true
                self:PolishScreenGui(gui)
            end
        end
    end)
end

-- ========================================
-- CLEANUP
-- ========================================

function UIPolishSystem:Destroy()
    -- Stop all animations
    for element, tween in pairs(self._activeAnimations) do
        if tween then
            tween:Cancel()
        end
    end
    
    -- Clear references
    self._activeAnimations = {}
    self._polishedElements = {}
end

return UIPolishSystem