--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                     SANRIO TYCOON - ADVANCED UI EFFECTS                              ║
    ║                    Beautiful animations and visual polish                            ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local UIEffects = {}
UIEffects.__index = UIEffects

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- ========================================
-- TWEEN CONFIGURATIONS
-- ========================================
local TWEENS = {
    Instant = TweenInfo.new(0),
    VeryFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- Special effects
    Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.1),
    
    -- Loops
    Pulse = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    Rotate = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
}

-- ========================================
-- CONSTRUCTOR
-- ========================================
function UIEffects.new()
    local self = setmetatable({}, UIEffects)
    self.connections = {}
    self.effects = {}
    return self
end

-- ========================================
-- ENTRANCE ANIMATIONS
-- ========================================
function UIEffects:PopIn(element, options)
    options = options or {}
    local startScale = options.startScale or 0
    local endScale = options.endScale or 1
    local duration = options.duration or 0.4
    
    element.AnchorPoint = Vector2.new(0.5, 0.5)
    element.Size = element.Size
    
    -- Create scale object if doesn't exist
    local scale = element:FindFirstChild("UIScale") or Instance.new("UIScale")
    scale.Scale = startScale
    scale.Parent = element
    
    -- Animate
    local tween = TweenService:Create(
        scale,
        TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = endScale}
    )
    
    tween:Play()
    
    -- Add rotation if requested
    if options.rotation then
        element.Rotation = -15
        TweenService:Create(
            element,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Rotation = 0}
        ):Play()
    end
    
    return tween
end

function UIEffects:SlideIn(element, direction, options)
    options = options or {}
    local distance = options.distance or 100
    local duration = options.duration or 0.5
    
    local startPos = element.Position
    local offset = Vector2.new(0, 0)
    
    if direction == "left" then
        offset = Vector2.new(-distance, 0)
    elseif direction == "right" then
        offset = Vector2.new(distance, 0)
    elseif direction == "top" then
        offset = Vector2.new(0, -distance)
    elseif direction == "bottom" then
        offset = Vector2.new(0, distance)
    end
    
    element.Position = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + offset.X,
        startPos.Y.Scale,
        startPos.Y.Offset + offset.Y
    )
    
    local tween = TweenService:Create(
        element,
        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = startPos}
    )
    
    tween:Play()
    
    -- Add fade if requested
    if options.fade then
        element.BackgroundTransparency = 1
        self:FadeIn(element, duration)
    end
    
    return tween
end

function UIEffects:FadeIn(element, duration)
    duration = duration or 0.3
    
    local originalTransparency = element.BackgroundTransparency
    element.BackgroundTransparency = 1
    
    -- Fade background
    local bgTween = TweenService:Create(
        element,
        TweenInfo.new(duration, Enum.EasingStyle.Quad),
        {BackgroundTransparency = originalTransparency}
    )
    
    bgTween:Play()
    
    -- Fade all text children
    for _, child in ipairs(element:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local textTransparency = child.TextTransparency
            child.TextTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(duration, Enum.EasingStyle.Quad),
                {TextTransparency = textTransparency}
            ):Play()
        elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
            local imageTransparency = child.ImageTransparency
            child.ImageTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(duration, Enum.EasingStyle.Quad),
                {ImageTransparency = imageTransparency}
            ):Play()
        end
    end
    
    return bgTween
end

-- ========================================
-- HOVER EFFECTS
-- ========================================
function UIEffects:AddHoverEffect(button, options)
    options = options or {}
    local scaleAmount = options.scale or 1.05
    local brightness = options.brightness or 1.2
    local springiness = options.springy or false
    
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    
    local function onHover()
        if springiness then
            self:Spring(button, scaleAmount)
        else
            TweenService:Create(
                button,
                TWEENS.VeryFast,
                {
                    Size = UDim2.new(
                        originalSize.X.Scale * scaleAmount,
                        originalSize.X.Offset * scaleAmount,
                        originalSize.Y.Scale * scaleAmount,
                        originalSize.Y.Offset * scaleAmount
                    ),
                    BackgroundColor3 = Color3.new(
                        math.min(originalColor.R * brightness, 1),
                        math.min(originalColor.G * brightness, 1),
                        math.min(originalColor.B * brightness, 1)
                    )
                }
            ):Play()
        end
        
        if options.sound then
            -- Play hover sound
        end
    end
    
    local function onUnhover()
        TweenService:Create(
            button,
            TWEENS.VeryFast,
            {
                Size = originalSize,
                BackgroundColor3 = originalColor
            }
        ):Play()
    end
    
    button.MouseEnter:Connect(onHover)
    button.MouseLeave:Connect(onUnhover)
end

-- ========================================
-- CLICK EFFECTS
-- ========================================
function UIEffects:AddClickEffect(button, options)
    options = options or {}
    
    button.MouseButton1Down:Connect(function()
        -- Scale down
        local scale = button:FindFirstChild("UIScale") or Instance.new("UIScale")
        scale.Parent = button
        
        TweenService:Create(
            scale,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {Scale = 0.95}
        ):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        -- Scale back up with spring
        local scale = button:FindFirstChild("UIScale")
        if scale then
            TweenService:Create(
                scale,
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Scale = 1}
            ):Play()
        end
        
        -- Create ripple effect
        if options.ripple then
            self:CreateRipple(button)
        end
        
        if options.sound then
            -- Play click sound
        end
    end)
end

-- ========================================
-- SPECIAL EFFECTS
-- ========================================
function UIEffects:CreateRipple(button)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.Size = UDim2.new(0, 10, 0, 10)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.7
    ripple.ZIndex = button.ZIndex + 1
    ripple.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    -- Animate ripple
    local sizeTween = TweenService:Create(
        ripple,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(2, 0, 2, 0),
            BackgroundTransparency = 1
        }
    )
    
    sizeTween:Play()
    sizeTween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

function UIEffects:AddGlow(element, color, options)
    options = options or {}
    local intensity = options.intensity or 20
    local animated = options.animated ~= false
    
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, intensity * 2, 1, intensity * 2)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = color or Color3.new(1, 1, 1)
    glow.ImageTransparency = options.transparency or 0.5
    glow.ZIndex = element.ZIndex - 1
    glow.Parent = element
    
    if animated then
        local connection = RunService.Heartbeat:Connect(function()
            local time = tick()
            glow.ImageTransparency = 0.3 + math.sin(time * 2) * 0.2
            glow.Size = UDim2.new(
                1, intensity * 2 + math.sin(time * 3) * 10,
                1, intensity * 2 + math.sin(time * 3) * 10
            )
        end)
        
        self.connections[glow] = connection
    end
    
    return glow
end

function UIEffects:AddShine(element, options)
    options = options or {}
    local speed = options.speed or 2
    local width = options.width or 50
    local angle = options.angle or 45
    
    local shine = Instance.new("Frame")
    shine.Name = "Shine"
    shine.Size = UDim2.new(0, width, 2, 0)
    shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
    shine.Rotation = angle
    shine.BackgroundColor3 = Color3.new(1, 1, 1)
    shine.BackgroundTransparency = options.transparency or 0.8
    shine.ZIndex = element.ZIndex + 1
    shine.Parent = element
    
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Parent = shine
    
    -- Animate shine
    local function animateShine()
        shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
        
        local tween = TweenService:Create(
            shine,
            TweenInfo.new(speed, Enum.EasingStyle.Linear),
            {Position = UDim2.new(1.5, 0, 1.5, 0)}
        )
        
        tween:Play()
        tween.Completed:Connect(function()
            wait(speed)
            animateShine()
        end)
    end
    
    animateShine()
    
    return shine
end

function UIEffects:CreateParticles(parent, particleType, options)
    options = options or {}
    local count = options.count or 10
    local lifetime = options.lifetime or 2
    local speed = options.speed or 50
    
    for i = 1, count do
        local particle = Instance.new("Frame")
        particle.Name = "Particle"
        particle.Size = UDim2.new(0, math.random(5, 15), 0, math.random(5, 15))
        particle.Position = UDim2.new(0.5, math.random(-20, 20), 0.5, math.random(-20, 20))
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.BackgroundTransparency = 0
        particle.BorderSizePixel = 0
        particle.ZIndex = parent.ZIndex + 1
        particle.Parent = parent
        
        if particleType == "star" then
            particle.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
            particle.Rotation = math.random(0, 360)
            
            local star = Instance.new("ImageLabel")
            star.Size = UDim2.new(1, 0, 1, 0)
            star.BackgroundTransparency = 1
            star.Image = "rbxassetid://6023565895"
            star.ImageColor3 = particle.BackgroundColor3
            star.Parent = particle
            
        elseif particleType == "heart" then
            particle.BackgroundColor3 = Color3.fromRGB(255, 102, 204)
            particle.Rotation = math.random(-15, 15)
            
            local heart = Instance.new("ImageLabel")
            heart.Size = UDim2.new(1, 0, 1, 0)
            heart.BackgroundTransparency = 1
            heart.Image = "rbxassetid://6023836832"
            heart.ImageColor3 = particle.BackgroundColor3
            heart.Parent = particle
            
        elseif particleType == "sparkle" then
            particle.BackgroundColor3 = Color3.new(1, 1, 1)
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
        end
        
        -- Animate particle
        local angle = math.random() * math.pi * 2
        local distance = math.random(speed, speed * 2)
        
        local endPos = UDim2.new(
            0.5, math.cos(angle) * distance,
            0.5, math.sin(angle) * distance - 50
        )
        
        spawn(function()
            wait(i * 0.05) -- Stagger particles
            
            local moveTween = TweenService:Create(
                particle,
                TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = endPos,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 0, 0)
                }
            )
            
            moveTween:Play()
            moveTween.Completed:Connect(function()
                particle:Destroy()
            end)
            
            -- Rotate
            local rotateTween = TweenService:Create(
                particle,
                TweenInfo.new(lifetime, Enum.EasingStyle.Linear),
                {Rotation = particle.Rotation + 360}
            )
            rotateTween:Play()
        end)
    end
end

-- ========================================
-- UTILITY EFFECTS
-- ========================================
function UIEffects:Spring(element, scale)
    local originalSize = element.Size
    
    -- Overshoot
    TweenService:Create(
        element,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(
                originalSize.X.Scale * (scale + 0.1),
                originalSize.X.Offset * (scale + 0.1),
                originalSize.Y.Scale * (scale + 0.1),
                originalSize.Y.Offset * (scale + 0.1)
            )
        }
    ):Play()
    
    wait(0.2)
    
    -- Settle
    TweenService:Create(
        element,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(
                originalSize.X.Scale * scale,
                originalSize.X.Offset * scale,
                originalSize.Y.Scale * scale,
                originalSize.Y.Offset * scale
            )
        }
    ):Play()
end

function UIEffects:Shake(element, intensity, duration)
    intensity = intensity or 5
    duration = duration or 0.5
    
    local originalPos = element.Position
    local startTime = tick()
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > duration then
            element.Position = originalPos
            connection:Disconnect()
            return
        end
        
        local fade = 1 - (elapsed / duration)
        local offsetX = math.random(-intensity, intensity) * fade
        local offsetY = math.random(-intensity, intensity) * fade
        
        element.Position = UDim2.new(
            originalPos.X.Scale,
            originalPos.X.Offset + offsetX,
            originalPos.Y.Scale,
            originalPos.Y.Offset + offsetY
        )
    end)
end

function UIEffects:Rainbow(element, speed)
    speed = speed or 1
    
    local connection = RunService.Heartbeat:Connect(function()
        local hue = (tick() * speed) % 1
        element.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
    end)
    
    self.connections[element] = connection
    return connection
end

-- ========================================
-- CLEANUP
-- ========================================
function UIEffects:Cleanup()
    for _, connection in pairs(self.connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    self.connections = {}
end

return UIEffects