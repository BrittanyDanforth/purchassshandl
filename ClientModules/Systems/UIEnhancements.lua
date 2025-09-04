--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - UI ENHANCEMENTS MODULE                        ║
    ║                         Premium AAA UI Polish and Animations                         ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local UIEnhancements = {}
UIEnhancements.__index = UIEnhancements

-- ========================================
-- SERVICES & DEPENDENCIES
-- ========================================
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-- ========================================
-- CONSTANTS
-- ========================================

-- Premium UI positioning (raised and centered better)
local ENHANCED_UI_POSITION = UDim2.new(0, 20, 0, 40) -- Much higher and more centered
local ENHANCED_UI_SIZE = UDim2.new(1, -40, 1, -60) -- More padding for cleaner look

-- Animation constants for smooth AAA feel
local TWEEN_INFO = {
    UltraFast = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    Elastic = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.8, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    
    -- Special animations
    CaseOpening = TweenInfo.new(2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
    Hover = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Click = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
}

-- Visual enhancement colors
local ENHANCEMENT_COLORS = {
    GlowPrimary = Color3.fromRGB(255, 100, 200),
    GlowSecondary = Color3.fromRGB(100, 200, 255),
    Shimmer = Color3.fromRGB(255, 255, 255),
    Shadow = Color3.fromRGB(0, 0, 0),
    Success = Color3.fromRGB(100, 255, 100),
    Error = Color3.fromRGB(255, 100, 100)
}

-- ========================================
-- INITIALIZATION
-- ========================================

function UIEnhancements.new(config)
    local self = setmetatable({}, UIEnhancements)
    
    self._config = config
    self._animations = {}
    self._glowEffects = {}
    self._connections = {}
    
    return self
end

-- ========================================
-- POSITION FIXES
-- ========================================

function UIEnhancements:FixUIPositioning(frame)
    -- Immediately fix positioning for all UI frames
    if frame:IsA("Frame") and frame.Parent then
        -- Check if it's a main UI frame
        local name = frame.Name:lower()
        if name:find("frame") or name:find("ui") then
            -- Apply enhanced positioning
            frame.Position = ENHANCED_UI_POSITION
            frame.Size = ENHANCED_UI_SIZE
            
            -- Add slight animation to show the change
            frame.AnchorPoint = Vector2.new(0, 0)
            
            local originalPos = frame.Position
            frame.Position = UDim2.new(0, 20, 1, 0) -- Start from bottom
            
            TweenService:Create(frame, TWEEN_INFO.Smooth, {
                Position = ENHANCED_UI_POSITION
            }):Play()
        end
    end
end

-- ========================================
-- SMOOTH TRANSITIONS
-- ========================================

function UIEnhancements:AddSmoothTransition(frame, openCallback, closeCallback)
    -- Override open/close with smooth animations
    local originalVisible = frame.Visible
    
    -- Custom open function
    local function smoothOpen()
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        
        -- Animate open
        local openTween = TweenService:Create(frame, TWEEN_INFO.Elastic, {
            Size = ENHANCED_UI_SIZE,
            Position = UDim2.new(0.5, 0, 0.5, -20) -- Slightly raised
        })
        
        openTween:Play()
        
        if openCallback then
            openTween.Completed:Connect(openCallback)
        end
        
        -- Add fade in for children
        self:FadeChildren(frame, 0, 1, TWEEN_INFO.Fast)
    end
    
    -- Custom close function
    local function smoothClose()
        -- Animate close
        local closeTween = TweenService:Create(frame, TWEEN_INFO.Fast, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        
        closeTween.Completed:Connect(function()
            frame.Visible = false
            if closeCallback then
                closeCallback()
            end
        end)
        
        closeTween:Play()
        
        -- Fade out children
        self:FadeChildren(frame, 1, 0, TWEEN_INFO.UltraFast)
    end
    
    return smoothOpen, smoothClose
end

-- ========================================
-- HOVER EFFECTS
-- ========================================

function UIEnhancements:AddPremiumHover(button)
    if not button:IsA("GuiButton") then return end
    
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    
    -- Create hover container
    local hoverGlow = Instance.new("Frame")
    hoverGlow.Name = "HoverGlow"
    hoverGlow.Size = UDim2.new(1, 20, 1, 20)
    hoverGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    hoverGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    hoverGlow.BackgroundColor3 = ENHANCEMENT_COLORS.GlowPrimary
    hoverGlow.BackgroundTransparency = 1
    hoverGlow.ZIndex = button.ZIndex - 1
    hoverGlow.Parent = button.Parent
    
    -- UI corner for glow
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = hoverGlow
    
    -- Mouse enter
    button.MouseEnter:Connect(function()
        -- Button animation
        TweenService:Create(button, TWEEN_INFO.Hover, {
            Size = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, 
                           originalSize.Y.Scale * 1.05, originalSize.Y.Offset),
            BackgroundColor3 = self:LightenColor(originalColor, 0.1)
        }):Play()
        
        -- Glow animation
        TweenService:Create(hoverGlow, TWEEN_INFO.Hover, {
            BackgroundTransparency = 0.7,
            Size = UDim2.new(1, 30, 1, 30)
        }):Play()
        
        -- Play hover sound
        self:PlayHoverSound()
    end)
    
    -- Mouse leave
    button.MouseLeave:Connect(function()
        -- Reset button
        TweenService:Create(button, TWEEN_INFO.Hover, {
            Size = originalSize,
            BackgroundColor3 = originalColor
        }):Play()
        
        -- Reset glow
        TweenService:Create(hoverGlow, TWEEN_INFO.Hover, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 20, 1, 20)
        }):Play()
    end)
    
    -- Click animation
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TWEEN_INFO.Click, {
            Size = UDim2.new(originalSize.X.Scale * 0.95, originalSize.X.Offset, 
                           originalSize.Y.Scale * 0.95, originalSize.Y.Offset)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TWEEN_INFO.Click, {
            Size = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, 
                           originalSize.Y.Scale * 1.05, originalSize.Y.Offset)
        }):Play()
        
        task.wait(0.1)
        
        TweenService:Create(button, TWEEN_INFO.Hover, {
            Size = originalSize
        }):Play()
    end)
end

-- ========================================
-- CASE OPENING ENHANCEMENT
-- ========================================

function UIEnhancements:CreatePremiumCaseOpening()
    -- This will create a beautiful case opening experience
    return {
        -- Spinning wheel with premium graphics
        CreateSpinningWheel = function(parent, items)
            local wheel = Instance.new("Frame")
            wheel.Name = "PremiumWheel"
            wheel.Size = UDim2.new(0, 600, 0, 150)
            wheel.Position = UDim2.new(0.5, -300, 0.5, -75)
            wheel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            wheel.BorderSizePixel = 0
            wheel.ClipsDescendants = true
            wheel.Parent = parent
            
            -- Premium border
            local border = Instance.new("UIStroke")
            border.Color = ENHANCEMENT_COLORS.GlowPrimary
            border.Thickness = 3
            border.Transparency = 0
            border.Parent = wheel
            
            -- Corner
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 20)
            corner.Parent = wheel
            
            -- Add gradient background
            local gradient = Instance.new("UIGradient")
            gradient.Rotation = 90
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 50)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 30, 70)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 50))
            })
            gradient.Parent = wheel
            
            return wheel
        end,
        
        -- Premium animation
        AnimateWheel = function(wheel, targetItem, duration)
            -- Add particle effects
            self:AddParticleEffects(wheel.Parent)
            
            -- Smooth spinning animation
            local startPos = wheel.Position
            local spinDistance = 2000 + math.random(500, 1500) -- Random for excitement
            
            -- Spin animation with easing
            local spinTween = TweenService:Create(wheel, TweenInfo.new(
                duration,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset - spinDistance, 
                                   startPos.Y.Scale, startPos.Y.Offset)
            })
            
            spinTween:Play()
            
            -- Add dramatic slow down effect
            task.wait(duration * 0.7)
            
            -- Flash effect when landing
            task.wait(duration * 0.3)
            self:CreateFlashEffect(wheel.Parent)
            
            return spinTween
        end
    }
end

-- ========================================
-- PARTICLE EFFECTS
-- ========================================

function UIEnhancements:AddParticleEffects(parent)
    -- Create multiple particle emitters for premium feel
    for i = 1, 20 do
        task.spawn(function()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
            particle.Position = UDim2.new(math.random(), 0, 1, 10)
            particle.BackgroundColor3 = ENHANCEMENT_COLORS.GlowPrimary
            particle.BorderSizePixel = 0
            particle.Parent = parent
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
            
            -- Animate particle
            local riseTween = TweenService:Create(particle, TweenInfo.new(
                math.random(2, 4),
                Enum.EasingStyle.Linear
            ), {
                Position = UDim2.new(particle.Position.X.Scale, 0, -0.1, 0),
                BackgroundTransparency = 1
            })
            
            riseTween.Completed:Connect(function()
                particle:Destroy()
            end)
            
            riseTween:Play()
            
            -- Add shimmer
            task.spawn(function()
                while particle.Parent do
                    TweenService:Create(particle, TweenInfo.new(0.5), {
                        BackgroundColor3 = ENHANCEMENT_COLORS.GlowSecondary
                    }):Play()
                    task.wait(0.5)
                    TweenService:Create(particle, TweenInfo.new(0.5), {
                        BackgroundColor3 = ENHANCEMENT_COLORS.GlowPrimary
                    }):Play()
                    task.wait(0.5)
                end
            end)
        end)
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIEnhancements:FadeChildren(parent, fromAlpha, toAlpha, tweenInfo)
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then
            if child:IsA("Frame") then
                child.BackgroundTransparency = fromAlpha
                TweenService:Create(child, tweenInfo, {
                    BackgroundTransparency = toAlpha
                }):Play()
            end
            
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.TextTransparency = fromAlpha
                TweenService:Create(child, tweenInfo, {
                    TextTransparency = toAlpha
                }):Play()
            end
            
            if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                child.ImageTransparency = fromAlpha
                TweenService:Create(child, tweenInfo, {
                    ImageTransparency = toAlpha
                }):Play()
            end
        end
    end
end

function UIEnhancements:CreateFlashEffect(parent)
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(2, 0, 2, 0)
    flash.Position = UDim2.new(0.5, 0, 0.5, 0)
    flash.AnchorPoint = Vector2.new(0.5, 0.5)
    flash.BackgroundColor3 = ENHANCEMENT_COLORS.Shimmer
    flash.BackgroundTransparency = 1
    flash.ZIndex = 999
    flash.Parent = parent
    
    -- Flash animation
    TweenService:Create(flash, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.3
    }):Play()
    
    task.wait(0.2)
    
    TweenService:Create(flash, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()
    
    task.wait(0.5)
    flash:Destroy()
end

function UIEnhancements:LightenColor(color, amount)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s * (1 - amount), math.min(1, v * (1 + amount)))
end

function UIEnhancements:PlayHoverSound()
    -- Create subtle hover sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://421058925" -- Soft hover sound
    sound.Volume = 0.1
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- ========================================
-- CLEANUP
-- ========================================

function UIEnhancements:Destroy()
    for _, connection in pairs(self._connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    for _, tween in pairs(self._animations) do
        if tween then
            tween:Cancel()
        end
    end
    
    self._connections = {}
    self._animations = {}
end

return UIEnhancements