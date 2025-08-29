--[[
    Module: EffectsLibrary
    Description: Comprehensive visual effects library with shine, glow, rainbow, sparkle, and more
    Features: Special effects for UI elements, particle trails, dynamic lighting, animated effects
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local EffectsLibrary = {}
EffectsLibrary.__index = EffectsLibrary

-- ========================================
-- TYPES
-- ========================================

type EffectOptions = {
    duration: number?,
    intensity: number?,
    color: Color3?,
    speed: number?,
    size: number?,
    delay: number?,
    loop: boolean?,
    fadeIn: boolean?,
    fadeOut: boolean?,
    onComplete: (() -> ())?,
}

type ActiveEffect = {
    id: string,
    type: string,
    object: Instance,
    connections: {RBXScriptConnection},
    tweens: {Tween},
    instances: {Instance},
    startTime: number,
    options: EffectOptions,
    state: "active" | "paused" | "stopped",
}

type ParticleEffect = {
    emitter: ParticleEmitter,
    attachment: Attachment?,
    lifetime: number,
    startTime: number,
}

-- ========================================
-- CONSTANTS
-- ========================================

local EFFECT_TYPES = {
    SHINE = "Shine",
    GLOW = "Glow",
    RAINBOW = "Rainbow",
    SPARKLE = "Sparkle",
    PULSE = "Pulse",
    FLOAT = "Float",
    SHAKE = "Shake",
    RIPPLE = "Ripple",
    HOLOGRAM = "Hologram",
    ELECTRICITY = "Electricity",
    FIRE = "Fire",
    ICE = "Ice",
    AURA = "Aura",
    SCAN = "Scan",
    GLITCH = "Glitch",
}

local DEFAULT_SHINE_SPEED = 2
local DEFAULT_GLOW_SIZE = 30
local DEFAULT_PULSE_SCALE = 1.1
local DEFAULT_FLOAT_AMPLITUDE = 10
local DEFAULT_SHAKE_INTENSITY = 10
local DEFAULT_SPARKLE_RATE = 10

-- ========================================
-- INITIALIZATION
-- ========================================

function EffectsLibrary.new(dependencies)
    local self = setmetatable({}, EffectsLibrary)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._animationSystem = dependencies.AnimationSystem
    self._particleSystem = dependencies.ParticleSystem
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- Effect tracking
    self._activeEffects = {} -- Active effects by ID
    self._effectsByObject = {} -- Map of object to effect IDs
    self._particleEffects = {} -- Active particle effects
    
    -- Settings
    self._enabled = true
    self._qualityLevel = "high" -- "low", "medium", "high"
    self._maxEffectsPerObject = 5
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Effect pools
    self._effectPools = {}
    
    -- ID counter
    self._nextId = 0
    
    self:Initialize()
    
    return self
end

function EffectsLibrary:Initialize()
    -- Listen for settings changes
    if self._eventBus then
        self._eventBus:On("SettingsChanged", function(settings)
            if settings.effectsEnabled ~= nil then
                self._enabled = settings.effectsEnabled
            end
            if settings.graphicsQuality then
                self._qualityLevel = settings.graphicsQuality
            end
        end)
    end
    
    -- Initialize effect pools
    self:InitializeEffectPools()
    
    if self._debugMode then
        print("[EffectsLibrary] Initialized with quality:", self._qualityLevel)
    end
end

-- ========================================
-- SHINE EFFECT
-- ========================================

function EffectsLibrary:CreateShineEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    -- Create shine frame
    local shine = Instance.new("Frame")
    shine.Name = "ShineEffect"
    shine.Size = UDim2.new(0, 50, 2, 0)
    shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
    shine.BackgroundColor3 = options.color or self._config.COLORS.White
    shine.BackgroundTransparency = 0.8
    shine.Rotation = 45
    shine.ZIndex = frame.ZIndex + 1
    shine.Parent = frame
    
    -- Create gradient for shine
    local gradient = self._utilities.CreateGradient(shine, {
        self._config.COLORS.White,
        self._config.COLORS.White,
        self._config.COLORS.White
    })
    
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    -- Animate shine
    local speed = options.speed or DEFAULT_SHINE_SPEED
    local duration = options.duration or -1 -- -1 means infinite
    local loopCount = options.loop ~= false and -1 or 1
    
    local function animateShine()
        return self._utilities.Tween(shine, {
            Position = UDim2.new(1.5, 0, 1.5, 0)
        }, TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))
    end
    
    local currentTween
    local connection
    
    if loopCount == -1 then
        -- Infinite loop
        connection = Services.RunService.Heartbeat:Connect(function()
            if not shine.Parent then
                connection:Disconnect()
                return
            end
            
            if not currentTween or currentTween.PlaybackState == Enum.PlaybackState.Completed then
                shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
                currentTween = animateShine()
            end
        end)
    else
        -- Single animation
        currentTween = animateShine()
    end
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.SHINE,
        object = frame,
        connections = connection and {connection} or {},
        tweens = currentTween and {currentTween} or {},
        instances = {shine},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    -- Handle completion
    if duration > 0 then
        task.delay(duration, function()
            self:RemoveEffect(effectId)
        end)
    end
    
    return effectId
end

-- ========================================
-- GLOW EFFECT
-- ========================================

function EffectsLibrary:CreateGlowEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    -- Check if frame has a parent
    -- Ensure frame has a parent
    if not frame or not frame.Parent then
        warn("[EffectsLibrary] Cannot create glow effect - frame has no parent")
        return nil
    end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    -- Create glow image
    local glow = Instance.new("ImageLabel")
    glow.Name = "GlowEffect"
    glow.Size = UDim2.new(1, options.size or DEFAULT_GLOW_SIZE, 1, options.size or DEFAULT_GLOW_SIZE)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084" -- Glow texture
    glow.ImageColor3 = options.color or self._config.COLORS.Primary
    glow.ImageTransparency = 0.5
    glow.ZIndex = frame.ZIndex - 1
    glow.Parent = frame.Parent
    
    -- Position behind the frame
    local frameIndex = 0
    if frame.Parent then
        for i, child in ipairs(frame.Parent:GetChildren()) do
            if child == frame then
                frameIndex = i
                break
            end
        end
    end
    glow.LayoutOrder = frameIndex - 1
    
    -- Animate glow
    local pulseSize = options.size or DEFAULT_GLOW_SIZE
    local tweenInfo = TweenInfo.new(
        options.speed or 1,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        options.loop ~= false and -1 or 0,
        true
    )
    
    local pulseTween = Services.TweenService:Create(glow, tweenInfo, {
        Size = UDim2.new(1, pulseSize + 10, 1, pulseSize + 10),
        ImageTransparency = 0.7
    })
    
    pulseTween:Play()
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.GLOW,
        object = frame,
        connections = {},
        tweens = {pulseTween},
        instances = {glow},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- RAINBOW EFFECT
-- ========================================

function EffectsLibrary:CreateRainbowEffect(textLabel: TextLabel | TextButton, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local speed = options.speed or 1
    local hue = 0
    
    local connection = Services.RunService.Heartbeat:Connect(function(deltaTime)
        if not textLabel.Parent then
            connection:Disconnect()
            return
        end
        
        hue = (hue + deltaTime * speed * 60) % 360
        textLabel.TextColor3 = Color3.fromHSV(hue / 360, 1, 1)
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.RAINBOW,
        object = textLabel,
        connections = {connection},
        tweens = {},
        instances = {},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- SPARKLE LOOP EFFECT
-- ========================================

function EffectsLibrary:CreateSparkleLoop(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local rate = options.speed or DEFAULT_SPARKLE_RATE
    local sparkleContainer = Instance.new("Frame")
    sparkleContainer.Name = "SparkleContainer"
    sparkleContainer.Size = UDim2.new(1, 0, 1, 0)
    sparkleContainer.BackgroundTransparency = 1
    sparkleContainer.ClipsDescendants = true
    sparkleContainer.ZIndex = frame.ZIndex + 1
    sparkleContainer.Parent = frame
    
    local lastSparkleTime = 0
    local sparkles = {}
    
    local connection = Services.RunService.Heartbeat:Connect(function()
        if not sparkleContainer.Parent then
            connection:Disconnect()
            return
        end
        
        -- Create new sparkles
        if tick() - lastSparkleTime > 1 / rate then
            lastSparkleTime = tick()
            
            local sparkle = Instance.new("ImageLabel")
            sparkle.Size = UDim2.new(0, 20, 0, 20)
            sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
            sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
            sparkle.BackgroundTransparency = 1
            sparkle.Image = "rbxassetid://7037761097" -- Star/sparkle image
            sparkle.ImageColor3 = options.color or self._config.COLORS.White
            sparkle.ImageTransparency = 1
            sparkle.Rotation = math.random(0, 360)
            sparkle.Parent = sparkleContainer
            
            table.insert(sparkles, {
                instance = sparkle,
                startTime = tick(),
                lifetime = 1
            })
            
            -- Animate sparkle
            Services.TweenService:Create(sparkle, TweenInfo.new(0.2), {
                ImageTransparency = 0,
                Size = UDim2.new(0, 30, 0, 30)
            }):Play()
            
            task.wait(0.2)
            
            Services.TweenService:Create(sparkle, TweenInfo.new(0.8), {
                ImageTransparency = 1,
                Size = UDim2.new(0, 10, 0, 10),
                Rotation = sparkle.Rotation + 180
            }):Play()
        end
        
        -- Clean up old sparkles
        for i = #sparkles, 1, -1 do
            local sparkleData = sparkles[i]
            if tick() - sparkleData.startTime > sparkleData.lifetime then
                sparkleData.instance:Destroy()
                table.remove(sparkles, i)
            end
        end
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.SPARKLE,
        object = frame,
        connections = {connection},
        tweens = {},
        instances = {sparkleContainer},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- PULSE EFFECT
-- ========================================

function EffectsLibrary:CreatePulseEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local scale = options.intensity or DEFAULT_PULSE_SCALE
    local speed = options.speed or 0.5
    local originalSize = frame.Size
    
    local tweenInfo = TweenInfo.new(
        speed,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        options.loop ~= false and -1 or 0,
        true
    )
    
    local pulseTween = Services.TweenService:Create(frame, tweenInfo, {
        Size = UDim2.new(
            originalSize.X.Scale * scale,
            originalSize.X.Offset * scale,
            originalSize.Y.Scale * scale,
            originalSize.Y.Offset * scale
        )
    })
    
    pulseTween:Play()
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.PULSE,
        object = frame,
        connections = {},
        tweens = {pulseTween},
        instances = {},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- FLOATING EFFECT
-- ========================================

function EffectsLibrary:CreateFloatingEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local amplitude = options.intensity or DEFAULT_FLOAT_AMPLITUDE
    local speed = options.speed or 2
    local startY = frame.Position.Y.Offset
    local time = 0
    
    local connection = Services.RunService.Heartbeat:Connect(function(deltaTime)
        if not frame.Parent then
            connection:Disconnect()
            return
        end
        
        time = time + deltaTime
        local offset = math.sin(time * speed) * amplitude
        
        frame.Position = UDim2.new(
            frame.Position.X.Scale,
            frame.Position.X.Offset,
            frame.Position.Y.Scale,
            startY + offset
        )
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.FLOAT,
        object = frame,
        connections = {connection},
        tweens = {},
        instances = {},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- RIPPLE EFFECT
-- ========================================

function EffectsLibrary:CreateRippleEffect(frame: GuiObject, position: Vector2?, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    -- Calculate ripple position
    local framePos = frame.AbsolutePosition
    local frameSize = frame.AbsoluteSize
    local ripplePos = position or framePos + frameSize / 2
    local relativePos = ripplePos - framePos
    
    -- Create ripple
    local ripple = Instance.new("Frame")
    ripple.Name = "RippleEffect"
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, relativePos.X, 0, relativePos.Y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = options.color or self._config.COLORS.White
    ripple.BackgroundTransparency = 0.6
    ripple.ZIndex = frame.ZIndex + 1
    ripple.Parent = frame
    
    self._utilities.CreateCorner(ripple, 999) -- Full circle
    
    -- Animate ripple
    local maxSize = math.max(frameSize.X, frameSize.Y) * 2
    local duration = options.duration or 0.6
    
    local expandTween = Services.TweenService:Create(ripple, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    
    expandTween:Play()
    expandTween.Completed:Connect(function()
        ripple:Destroy()
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.RIPPLE,
        object = frame,
        connections = {},
        tweens = {expandTween},
        instances = {ripple},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- HOLOGRAM EFFECT
-- ========================================

function EffectsLibrary:CreateHologramEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    -- Create scan lines
    local scanContainer = Instance.new("Frame")
    scanContainer.Name = "HologramEffect"
    scanContainer.Size = UDim2.new(1, 0, 1, 0)
    scanContainer.BackgroundTransparency = 1
    scanContainer.ClipsDescendants = true
    scanContainer.ZIndex = frame.ZIndex + 1
    scanContainer.Parent = frame
    
    -- Create scan line
    local scanLine = Instance.new("Frame")
    scanLine.Size = UDim2.new(1, 0, 0, 2)
    scanLine.Position = UDim2.new(0, 0, 0, 0)
    scanLine.BackgroundColor3 = options.color or Color3.fromRGB(0, 255, 255)
    scanLine.BackgroundTransparency = 0.5
    scanLine.Parent = scanContainer
    
    -- Create static lines
    for i = 1, 10 do
        local staticLine = Instance.new("Frame")
        staticLine.Size = UDim2.new(1, 0, 0, 1)
        staticLine.Position = UDim2.new(0, 0, i/10, 0)
        staticLine.BackgroundColor3 = options.color or Color3.fromRGB(0, 255, 255)
        staticLine.BackgroundTransparency = 0.9
        staticLine.Parent = scanContainer
    end
    
    -- Add glitch effect
    local glitchFrame = Instance.new("Frame")
    glitchFrame.Size = UDim2.new(1, 0, 1, 0)
    glitchFrame.BackgroundTransparency = 1
    glitchFrame.Parent = scanContainer
    
    -- Animate scan
    local scanTween = Services.TweenService:Create(scanLine, TweenInfo.new(
        options.speed or 2,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out,
        options.loop ~= false and -1 or 0,
        false
    ), {
        Position = UDim2.new(0, 0, 1, 0)
    })
    
    scanTween:Play()
    
    -- Glitch effect
    local connection = Services.RunService.Heartbeat:Connect(function()
        if not glitchFrame.Parent then
            connection:Disconnect()
            return
        end
        
        if math.random() < 0.02 then -- 2% chance per frame
            frame.Position = UDim2.new(
                frame.Position.X.Scale,
                frame.Position.X.Offset + math.random(-2, 2),
                frame.Position.Y.Scale,
                frame.Position.Y.Offset
            )
            
            task.wait(0.05)
            
            frame.Position = UDim2.new(
                frame.Position.X.Scale,
                frame.Position.X.Offset - math.random(-2, 2),
                frame.Position.Y.Scale,
                frame.Position.Y.Offset
            )
        end
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.HOLOGRAM,
        object = frame,
        connections = {connection},
        tweens = {scanTween},
        instances = {scanContainer},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- ELECTRICITY EFFECT
-- ========================================

function EffectsLibrary:CreateElectricityEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local container = Instance.new("Frame")
    container.Name = "ElectricityEffect"
    container.Size = UDim2.new(1, 20, 1, 20)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.ZIndex = frame.ZIndex + 1
    container.Parent = frame
    
    local bolts = {}
    local boltCount = 0
    
    local connection = Services.RunService.Heartbeat:Connect(function()
        if not container.Parent then
            connection:Disconnect()
            return
        end
        
        -- Clean old bolts
        for i = #bolts, 1, -1 do
            local bolt = bolts[i]
            if tick() - bolt.created > 0.1 then
                bolt.instance:Destroy()
                table.remove(bolts, i)
            end
        end
        
        -- Create new bolt
        if math.random() < 0.3 and boltCount < 5 then
            boltCount = boltCount + 1
            
            local bolt = Instance.new("Frame")
            bolt.Size = UDim2.new(0, 2, 0, math.random(20, 100))
            bolt.Position = UDim2.new(math.random(), 0, math.random(), 0)
            bolt.Rotation = math.random(0, 360)
            bolt.BackgroundColor3 = options.color or Color3.fromRGB(100, 200, 255)
            bolt.Parent = container
            
            table.insert(bolts, {
                instance = bolt,
                created = tick()
            })
            
            -- Animate bolt
            Services.TweenService:Create(bolt, TweenInfo.new(0.1), {
                BackgroundTransparency = 1
            }):Play()
            
            task.delay(0.1, function()
                boltCount = boltCount - 1
            end)
        end
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.ELECTRICITY,
        object = frame,
        connections = {connection},
        tweens = {},
        instances = {container},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- FIRE EFFECT
-- ========================================

function EffectsLibrary:CreateFireEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled or self._qualityLevel == "low" then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local container = Instance.new("Frame")
    container.Name = "FireEffect"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = true
    container.ZIndex = frame.ZIndex + 1
    container.Parent = frame
    
    local particles = {}
    local lastParticleTime = 0
    
    local connection = Services.RunService.Heartbeat:Connect(function(deltaTime)
        if not container.Parent then
            connection:Disconnect()
            return
        end
        
        -- Create new particles
        if tick() - lastParticleTime > 0.05 then
            lastParticleTime = tick()
            
            for i = 1, 3 do
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, math.random(5, 15), 0, math.random(5, 15))
                particle.Position = UDim2.new(math.random(), 0, 1, 0)
                particle.BackgroundColor3 = Color3.new(1, math.random() * 0.5 + 0.5, 0)
                particle.Parent = container
                
                self._utilities.CreateCorner(particle, 999)
                
                table.insert(particles, {
                    instance = particle,
                    velocity = Vector2.new((math.random() - 0.5) * 20, -math.random(50, 100)),
                    lifetime = math.random() * 0.5 + 0.5,
                    created = tick()
                })
            end
        end
        
        -- Update particles
        for i = #particles, 1, -1 do
            local particle = particles[i]
            local age = tick() - particle.created
            
            if age > particle.lifetime then
                particle.instance:Destroy()
                table.remove(particles, i)
            else
                -- Update position
                local currentPos = particle.instance.Position
                particle.instance.Position = UDim2.new(
                    currentPos.X.Scale,
                    currentPos.X.Offset + particle.velocity.X * deltaTime,
                    currentPos.Y.Scale,
                    currentPos.Y.Offset + particle.velocity.Y * deltaTime
                )
                
                -- Fade out
                particle.instance.BackgroundTransparency = age / particle.lifetime
                
                -- Slow down horizontal movement
                particle.velocity = Vector2.new(
                    particle.velocity.X * 0.98,
                    particle.velocity.Y
                )
            end
        end
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.FIRE,
        object = frame,
        connections = {connection},
        tweens = {},
        instances = {container},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- ICE EFFECT
-- ========================================

function EffectsLibrary:CreateIceEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    -- Create frost overlay
    local frost = Instance.new("Frame")
    frost.Name = "IceEffect"
    frost.Size = UDim2.new(1, 0, 1, 0)
    frost.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
    frost.BackgroundTransparency = 0.7
    frost.ZIndex = frame.ZIndex + 1
    frost.Parent = frame
    
    self._utilities.CreateCorner(frost, frame:FindFirstChildOfClass("UICorner") and 
        frame:FindFirstChildOfClass("UICorner").CornerRadius.Offset or 0)
    
    -- Create ice crystals
    for i = 1, 5 do
        local crystal = Instance.new("ImageLabel")
        crystal.Size = UDim2.new(0, 30, 0, 30)
        crystal.Position = UDim2.new(math.random(), 0, math.random(), 0)
        crystal.BackgroundTransparency = 1
        crystal.Image = "rbxassetid://7037761097" -- Star shape for crystal
        crystal.ImageColor3 = Color3.fromRGB(150, 200, 255)
        crystal.ImageTransparency = 0.3
        crystal.Rotation = math.random(0, 360)
        crystal.Parent = frost
        
        -- Animate crystal
        Services.TweenService:Create(crystal, TweenInfo.new(
            math.random() * 2 + 1,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1,
            true
        ), {
            Rotation = crystal.Rotation + 360,
            ImageTransparency = 0.6
        }):Play()
    end
    
    -- Add shimmer
    local shimmer = Instance.new("Frame")
    shimmer.Size = UDim2.new(0, 50, 2, 0)
    shimmer.Position = UDim2.new(-0.5, 0, -0.5, 0)
    shimmer.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
    shimmer.BackgroundTransparency = 0.5
    shimmer.Rotation = 45
    shimmer.Parent = frost
    
    local shimmerGradient = self._utilities.CreateGradient(shimmer, {
        Color3.fromRGB(200, 230, 255),
        Color3.fromRGB(200, 230, 255),
        Color3.fromRGB(200, 230, 255)
    })
    
    shimmerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    -- Animate shimmer
    local shimmerTween = Services.TweenService:Create(shimmer, TweenInfo.new(
        options.speed or 3,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out,
        options.loop ~= false and -1 or 0,
        false
    ), {
        Position = UDim2.new(1.5, 0, 1.5, 0)
    })
    
    shimmerTween:Play()
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.ICE,
        object = frame,
        connections = {},
        tweens = {shimmerTween},
        instances = {frost},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- AURA EFFECT
-- ========================================

function EffectsLibrary:CreateAuraEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local auraColors = {
        options.color or self._config.COLORS.Primary,
        self._utilities.DarkenColor(options.color or self._config.COLORS.Primary, 0.2),
        self._utilities.DarkenColor(options.color or self._config.COLORS.Primary, 0.4),
    }
    
    local auras = {}
    
    -- Create multiple aura layers
    for i = 1, 3 do
        local aura = Instance.new("ImageLabel")
        aura.Name = "AuraLayer" .. i
        aura.Size = UDim2.new(1, 20 * i, 1, 20 * i)
        aura.Position = UDim2.new(0.5, 0, 0.5, 0)
        aura.AnchorPoint = Vector2.new(0.5, 0.5)
        aura.BackgroundTransparency = 1
        aura.Image = "rbxassetid://5028857084"
        aura.ImageColor3 = auraColors[i]
        aura.ImageTransparency = 0.7
        aura.ZIndex = frame.ZIndex - i
        aura.Parent = frame.Parent
        
        table.insert(auras, aura)
        
        -- Animate each layer
        Services.TweenService:Create(aura, TweenInfo.new(
            options.speed or (1 + i * 0.5),
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1,
            true
        ), {
            Size = UDim2.new(1, 30 * i, 1, 30 * i),
            ImageTransparency = 0.9
        }):Play()
        
        -- Rotate aura
        spawn(function()
            while aura.Parent do
                aura.Rotation = aura.Rotation + (i * 0.5)
                Services.RunService.Heartbeat:Wait()
            end
        end)
    end
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.AURA,
        object = frame,
        connections = {},
        tweens = {},
        instances = auras,
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- SCAN EFFECT
-- ========================================

function EffectsLibrary:CreateScanEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    -- Create scan container
    local scanContainer = Instance.new("Frame")
    scanContainer.Name = "ScanEffect"
    scanContainer.Size = UDim2.new(1, 0, 1, 0)
    scanContainer.BackgroundTransparency = 1
    scanContainer.ClipsDescendants = true
    scanContainer.ZIndex = frame.ZIndex + 1
    scanContainer.Parent = frame
    
    -- Create scan beam
    local scanBeam = Instance.new("Frame")
    scanBeam.Size = UDim2.new(1, 0, 0, 3)
    scanBeam.Position = UDim2.new(0, 0, -0.1, 0)
    scanBeam.BackgroundColor3 = options.color or Color3.fromRGB(0, 255, 0)
    scanBeam.Parent = scanContainer
    
    -- Create scan trail
    local scanTrail = Instance.new("Frame")
    scanTrail.Size = UDim2.new(1, 0, 0, 20)
    scanTrail.Position = UDim2.new(0, 0, -0.1, -20)
    scanTrail.BackgroundColor3 = options.color or Color3.fromRGB(0, 255, 0)
    scanTrail.BackgroundTransparency = 0.5
    scanTrail.Parent = scanContainer
    
    local trailGradient = self._utilities.CreateGradient(scanTrail, {
        (options.color or Color3.fromRGB(0, 255, 0)),
        (options.color or Color3.fromRGB(0, 255, 0))
    }, 90)
    
    trailGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.7),
        NumberSequenceKeypoint.new(1, 0.5)
    })
    
    -- Animate scan
    local scanTween = Services.TweenService:Create(scanBeam, TweenInfo.new(
        options.speed or 2,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out,
        options.loop ~= false and -1 or 0,
        false
    ), {
        Position = UDim2.new(0, 0, 1.1, 0)
    })
    
    local trailTween = Services.TweenService:Create(scanTrail, TweenInfo.new(
        options.speed or 2,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out,
        options.loop ~= false and -1 or 0,
        false
    ), {
        Position = UDim2.new(0, 0, 1.1, -20)
    })
    
    scanTween:Play()
    trailTween:Play()
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.SCAN,
        object = frame,
        connections = {},
        tweens = {scanTween, trailTween},
        instances = {scanContainer},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- GLITCH EFFECT
-- ========================================

function EffectsLibrary:CreateGlitchEffect(frame: GuiObject, options: EffectOptions?): string
    if not self._enabled then return "" end
    
    options = options or {}
    local effectId = self:GenerateId()
    
    local originalPosition = frame.Position
    local glitchIntensity = options.intensity or 5
    
    -- Create RGB split layers
    local redLayer = frame:Clone()
    redLayer.Name = "GlitchRed"
    redLayer.ZIndex = frame.ZIndex - 1
    if redLayer:IsA("ImageLabel") then
        redLayer.ImageColor3 = Color3.new(1, 0, 0)
    elseif redLayer:IsA("TextLabel") or redLayer:IsA("TextButton") then
        redLayer.TextColor3 = Color3.new(1, 0, 0)
    end
    redLayer.Parent = frame.Parent
    
    local blueLayer = frame:Clone()
    blueLayer.Name = "GlitchBlue"
    blueLayer.ZIndex = frame.ZIndex - 2
    if blueLayer:IsA("ImageLabel") then
        blueLayer.ImageColor3 = Color3.new(0, 0, 1)
    elseif blueLayer:IsA("TextLabel") or blueLayer:IsA("TextButton") then
        blueLayer.TextColor3 = Color3.new(0, 0, 1)
    end
    blueLayer.Parent = frame.Parent
    
    local connection = Services.RunService.Heartbeat:Connect(function()
        if not frame.Parent then
            connection:Disconnect()
            return
        end
        
        -- Random glitch chance
        if math.random() < 0.1 then
            -- Position glitch
            frame.Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset + math.random(-glitchIntensity, glitchIntensity),
                originalPosition.Y.Scale,
                originalPosition.Y.Offset + math.random(-glitchIntensity, glitchIntensity)
            )
            
            -- RGB split
            redLayer.Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset - 2,
                originalPosition.Y.Scale,
                originalPosition.Y.Offset
            )
            
            blueLayer.Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset + 2,
                originalPosition.Y.Scale,
                originalPosition.Y.Offset
            )
            
            redLayer.Visible = true
            blueLayer.Visible = true
            
            task.wait(0.05)
            
            -- Reset
            frame.Position = originalPosition
            redLayer.Visible = false
            blueLayer.Visible = false
        end
    end)
    
    -- Track effect
    local effect: ActiveEffect = {
        id = effectId,
        type = EFFECT_TYPES.GLITCH,
        object = frame,
        connections = {connection},
        tweens = {},
        instances = {redLayer, blueLayer},
        startTime = tick(),
        options = options,
        state = "active",
    }
    
    self:TrackEffect(effect)
    
    return effectId
end

-- ========================================
-- EFFECT MANAGEMENT
-- ========================================

function EffectsLibrary:TrackEffect(effect: ActiveEffect)
    self._activeEffects[effect.id] = effect
    
    if not self._effectsByObject[effect.object] then
        self._effectsByObject[effect.object] = {}
    end
    self._effectsByObject[effect.object][effect.id] = true
    
    -- Check effect limit per object
    local effectCount = 0
    for _ in pairs(self._effectsByObject[effect.object]) do
        effectCount = effectCount + 1
    end
    
    if effectCount > self._maxEffectsPerObject then
        warn("[EffectsLibrary] Maximum effects per object reached")
        -- Remove oldest effect
        local oldestId
        local oldestTime = math.huge
        for id in pairs(self._effectsByObject[effect.object]) do
            local e = self._activeEffects[id]
            if e and e.startTime < oldestTime then
                oldestTime = e.startTime
                oldestId = id
            end
        end
        if oldestId then
            self:RemoveEffect(oldestId)
        end
    end
end

function EffectsLibrary:RemoveEffect(effectId: string)
    local effect = self._activeEffects[effectId]
    if not effect then return end
    
    effect.state = "stopped"
    
    -- Stop all connections
    for _, connection in ipairs(effect.connections) do
        connection:Disconnect()
    end
    
    -- Cancel all tweens
    for _, tween in ipairs(effect.tweens) do
        tween:Cancel()
    end
    
    -- Destroy all instances
    for _, instance in ipairs(effect.instances) do
        instance:Destroy()
    end
    
    -- Clean up tracking
    if effect.object and self._effectsByObject[effect.object] then
        self._effectsByObject[effect.object][effectId] = nil
        
        if next(self._effectsByObject[effect.object]) == nil then
            self._effectsByObject[effect.object] = nil
        end
    end
    
    self._activeEffects[effectId] = nil
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("EffectRemoved", {
            id = effectId,
            type = effect.type,
        })
    end
end

function EffectsLibrary:RemoveAllEffectsFromObject(object: Instance)
    local effectIds = self._effectsByObject[object]
    if not effectIds then return end
    
    for effectId in pairs(effectIds) do
        self:RemoveEffect(effectId)
    end
end

function EffectsLibrary:PauseEffect(effectId: string)
    local effect = self._activeEffects[effectId]
    if not effect or effect.state ~= "active" then return end
    
    effect.state = "paused"
    
    -- Pause all tweens
    for _, tween in ipairs(effect.tweens) do
        tween:Pause()
    end
end

function EffectsLibrary:ResumeEffect(effectId: string)
    local effect = self._activeEffects[effectId]
    if not effect or effect.state ~= "paused" then return end
    
    effect.state = "active"
    
    -- Resume all tweens
    for _, tween in ipairs(effect.tweens) do
        tween:Play()
    end
end

-- ========================================
-- EFFECT POOLS
-- ========================================

function EffectsLibrary:InitializeEffectPools()
    -- Pre-create commonly used effect instances
    self._effectPools.sparkles = {}
    self._effectPools.glows = {}
    self._effectPools.ripples = {}
    
    -- This would be expanded in a production system
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function EffectsLibrary:GenerateId(): string
    self._nextId = self._nextId + 1
    return "effect_" .. tostring(self._nextId)
end

function EffectsLibrary:GetActiveEffectCount(): number
    local count = 0
    for _ in pairs(self._activeEffects) do
        count = count + 1
    end
    return count
end

function EffectsLibrary:GetEffectsByType(effectType: string): {ActiveEffect}
    local effects = {}
    for _, effect in pairs(self._activeEffects) do
        if effect.type == effectType then
            table.insert(effects, effect)
        end
    end
    return effects
end

-- ========================================
-- QUALITY SETTINGS
-- ========================================

function EffectsLibrary:SetQualityLevel(level: "low" | "medium" | "high")
    self._qualityLevel = level
    
    -- Adjust existing effects based on quality
    if level == "low" then
        -- Remove complex effects
        for id, effect in pairs(self._activeEffects) do
            if effect.type == EFFECT_TYPES.FIRE or 
               effect.type == EFFECT_TYPES.ELECTRICITY or
               effect.type == EFFECT_TYPES.HOLOGRAM then
                self:RemoveEffect(id)
            end
        end
    end
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function EffectsLibrary:DebugPrint()
        print("\n=== EffectsLibrary Debug Info ===")
        print("Enabled:", self._enabled)
        print("Quality Level:", self._qualityLevel)
        print("Active Effects:", self:GetActiveEffectCount())
        
        print("\nEffects by Type:")
        for effectType in pairs(EFFECT_TYPES) do
            local effects = self:GetEffectsByType(effectType)
            if #effects > 0 then
                print("  " .. effectType .. ":", #effects)
            end
        end
        
        print("\nObjects with Effects:")
        for object, effectIds in pairs(self._effectsByObject) do
            local count = 0
            for _ in pairs(effectIds) do
                count = count + 1
            end
            print("  " .. object.Name .. ":", count, "effects")
        end
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function EffectsLibrary:Destroy()
    -- Remove all active effects
    for effectId in pairs(self._activeEffects) do
        self:RemoveEffect(effectId)
    end
    
    -- Clear pools
    self._effectPools = {}
    
    -- Clear tracking
    self._activeEffects = {}
    self._effectsByObject = {}
    self._particleEffects = {}
end

-- ========================================
-- MAKE GLOBALLY ACCESSIBLE
-- ========================================

-- This allows the module to be accessed via _G.SpecialEffects for compatibility
_G.SpecialEffects = EffectsLibrary

return EffectsLibrary