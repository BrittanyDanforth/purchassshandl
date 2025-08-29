--[[
    Module: AnimationSystem
    Description: Advanced animation system with tween chains, parallel animations, spring physics,
                 custom easing curves, animation queues, and performance monitoring
    Features: Sequential/parallel animations, spring physics, custom easing, performance metrics
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local AnimationSystem = {}
AnimationSystem.__index = AnimationSystem

-- ========================================
-- TYPES
-- ========================================

type AnimationOptions = {
    duration: number?,
    easingStyle: Enum.EasingStyle?,
    easingDirection: Enum.EasingDirection?,
    repeatCount: number?,
    reverses: boolean?,
    delayTime: number?,
    onComplete: (() -> ())?,
    onStep: ((alpha: number) -> ())?,
    tag: string?,
    priority: number?,
}

type SpringOptions = {
    mass: number?,
    stiffness: number?,
    damping: number?,
    initialVelocity: number?,
    goal: any?,
    onComplete: (() -> ())?,
    onStep: ((value: any) -> ())?,
    tag: string?,
}

type AnimationChain = {
    id: string,
    animations: {Animation},
    currentIndex: number,
    mode: "sequential" | "parallel",
    onComplete: (() -> ())?,
    loop: boolean,
    state: "idle" | "playing" | "paused" | "completed",
}

type Animation = {
    id: string,
    object: Instance,
    properties: {[string]: any},
    startValues: {[string]: any}?,
    tween: Tween?,
    options: AnimationOptions,
    state: "pending" | "playing" | "paused" | "completed" | "cancelled",
    startTime: number?,
    endTime: number?,
}

type SpringAnimation = {
    id: string,
    object: Instance,
    property: string,
    spring: Spring,
    connection: RBXScriptConnection?,
    state: "playing" | "completed",
}

type Spring = {
    position: number,
    velocity: number,
    mass: number,
    stiffness: number,
    damping: number,
    goal: number,
}

-- ========================================
-- CONSTANTS
-- ========================================

local DEFAULT_DURATION = 0.3
local DEFAULT_EASING_STYLE = Enum.EasingStyle.Quad
local DEFAULT_EASING_DIRECTION = Enum.EasingDirection.Out
local DEFAULT_SPRING_MASS = 1
local DEFAULT_SPRING_STIFFNESS = 100
local DEFAULT_SPRING_DAMPING = 10
local SPRING_EPSILON = 0.001
local MAX_CONCURRENT_ANIMATIONS = 50 -- Reduced for better performance
local PERFORMANCE_SAMPLE_RATE = 60 -- frames

-- Custom easing functions
local CUSTOM_EASINGS = {
    -- Smooth step (smoothstep)
    smoothStep = function(t: number): number
        return t * t * (3 - 2 * t)
    end,
    
    -- Smoother step (smootherstep)
    smootherStep = function(t: number): number
        return t * t * t * (t * (6 * t - 15) + 10)
    end,
    
    -- Exponential out strong
    expOutStrong = function(t: number): number
        return t == 1 and 1 or 1 - math.pow(2, -10 * t)
    end,
    
    -- Elastic out custom
    elasticOut = function(t: number): number
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        local p = 0.3
        local s = p / 4
        return math.pow(2, -10 * t) * math.sin((t - s) * (2 * math.pi) / p) + 1
    end,
    
    -- Bounce out custom
    bounceOut = function(t: number): number
        if t < 1/2.75 then
            return 7.5625 * t * t
        elseif t < 2/2.75 then
            t = t - 1.5/2.75
            return 7.5625 * t * t + 0.75
        elseif t < 2.5/2.75 then
            t = t - 2.25/2.75
            return 7.5625 * t * t + 0.9375
        else
            t = t - 2.625/2.75
            return 7.5625 * t * t + 0.984375
        end
    end,
    
    -- Back out custom
    backOut = function(t: number): number
        local s = 1.70158
        return (t - 1) * (t - 1) * ((s + 1) * (t - 1) + s) + 1
    end,
}

-- ========================================
-- INITIALIZATION
-- ========================================

function AnimationSystem.new(dependencies)
    local self = setmetatable({}, AnimationSystem)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._config = dependencies.Config or Config
    
    -- Animation tracking
    self._animations = {} -- Active animations by ID
    self._animationChains = {} -- Animation chains by ID
    self._springAnimations = {} -- Spring animations by ID
    self._animationsByObject = {} -- Map of object to animation IDs
    self._animationQueue = {} -- Queue of pending animations
    
    -- Performance tracking
    self._performanceMetrics = {
        totalAnimations = 0,
        activeAnimations = 0,
        completedAnimations = 0,
        cancelledAnimations = 0,
        averageFrameTime = 0,
        frameTimeHistory = {},
        lastUpdateTime = 0,
    }
    
    -- Settings
    self._enabled = true
    self._timeScale = 1
    self._maxConcurrentAnimations = MAX_CONCURRENT_ANIMATIONS
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Update connection
    self._updateConnection = nil
    self._springUpdateConnection = nil
    
    -- ID counter
    self._nextId = 0
    
    self:Initialize()
    
    return self
end

function AnimationSystem:Initialize()
    -- Start update loops
    self:StartUpdateLoop()
    self:StartSpringUpdateLoop()
    
    -- Listen for settings changes
    if self._eventBus then
        self._eventBus:On("SettingsChanged", function(settings)
            if settings.animationsEnabled ~= nil then
                self._enabled = settings.animationsEnabled
            end
        end)
    end
    
    if self._debugMode then
        print("[AnimationSystem] Initialized")
    end
end

-- ========================================
-- BASIC ANIMATIONS
-- ========================================

function AnimationSystem:Animate(object: Instance, properties: {[string]: any}, options: AnimationOptions?): string
    options = options or {}
    
    -- Generate animation ID
    local animationId = self:GenerateId()
    
    -- Create TweenInfo
    local tweenInfo = TweenInfo.new(
        (options.duration or DEFAULT_DURATION) / self._timeScale,
        options.easingStyle or DEFAULT_EASING_STYLE,
        options.easingDirection or DEFAULT_EASING_DIRECTION,
        options.repeatCount or 0,
        options.reverses or false,
        options.delayTime or 0
    )
    
    -- Store start values
    local startValues = {}
    for property, _ in pairs(properties) do
        local success, value = pcall(function() return object[property] end)
        if success then
            startValues[property] = value
        end
    end
    
    -- Create tween
    local tween = Services.TweenService:Create(object, tweenInfo, properties)
    
    -- Create animation data
    local animation: Animation = {
        id = animationId,
        object = object,
        properties = properties,
        startValues = startValues,
        tween = tween,
        options = options,
        state = "pending",
        startTime = tick(),
        endTime = tick() + tweenInfo.Time,
    }
    
    -- Track animation
    self._animations[animationId] = animation
    self:TrackAnimationForObject(object, animationId)
    
    -- Update metrics
    self._performanceMetrics.totalAnimations = self._performanceMetrics.totalAnimations + 1
    self._performanceMetrics.activeAnimations = self._performanceMetrics.activeAnimations + 1
    
    -- Handle completion
    tween.Completed:Connect(function(playbackState)
        if animation.state == "playing" then
            animation.state = "completed"
            self:OnAnimationCompleted(animationId)
            
            if options.onComplete then
                task.spawn(options.onComplete)
            end
        end
    end)
    
    -- Start animation if enabled
    if self._enabled then
        animation.state = "playing"
        tween:Play()
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("AnimationStarted", {
                id = animationId,
                object = object,
                properties = properties,
            })
        end
    else
        -- If animations disabled, jump to end state
        for property, value in pairs(properties) do
            pcall(function() object[property] = value end)
        end
        animation.state = "completed"
        self:OnAnimationCompleted(animationId)
    end
    
    return animationId
end

-- ========================================
-- ANIMATION CHAINS
-- ========================================

function AnimationSystem:CreateChain(mode: "sequential" | "parallel"?): AnimationChain
    local chainId = self:GenerateId()
    
    local chain: AnimationChain = {
        id = chainId,
        animations = {},
        currentIndex = 1,
        mode = mode or "sequential",
        onComplete = nil,
        loop = false,
        state = "idle",
    }
    
    self._animationChains[chainId] = chain
    
    return chain
end

function AnimationSystem:AddToChain(chain: AnimationChain, object: Instance, properties: {[string]: any}, options: AnimationOptions?)
    local animation: Animation = {
        id = self:GenerateId(),
        object = object,
        properties = properties,
        startValues = nil,
        tween = nil,
        options = options or {},
        state = "pending",
        startTime = nil,
        endTime = nil,
    }
    
    table.insert(chain.animations, animation)
    
    return chain
end

function AnimationSystem:PlayChain(chain: AnimationChain, onComplete: (() -> ())?): string
    if not self._animationChains[chain.id] then
        warn("[AnimationSystem] Chain not found:", chain.id)
        return chain.id
    end
    
    chain.onComplete = onComplete
    chain.state = "playing"
    chain.currentIndex = 1
    
    if chain.mode == "sequential" then
        self:PlayNextInChain(chain)
    else -- parallel
        for _, animation in ipairs(chain.animations) do
            self:PlayChainAnimation(animation, function()
                -- Check if all animations in chain completed
                local allCompleted = true
                for _, anim in ipairs(chain.animations) do
                    if anim.state ~= "completed" then
                        allCompleted = false
                        break
                    end
                end
                
                if allCompleted then
                    self:OnChainCompleted(chain)
                end
            end)
        end
    end
    
    return chain.id
end

function AnimationSystem:PlayNextInChain(chain: AnimationChain)
    if chain.currentIndex > #chain.animations then
        if chain.loop then
            chain.currentIndex = 1
            self:PlayNextInChain(chain)
        else
            self:OnChainCompleted(chain)
        end
        return
    end
    
    local animation = chain.animations[chain.currentIndex]
    self:PlayChainAnimation(animation, function()
        chain.currentIndex = chain.currentIndex + 1
        self:PlayNextInChain(chain)
    end)
end

function AnimationSystem:PlayChainAnimation(animation: Animation, onComplete: (() -> ())?)
    local options = animation.options
    options.onComplete = onComplete
    
    self:Animate(animation.object, animation.properties, options)
end

function AnimationSystem:OnChainCompleted(chain: AnimationChain)
    chain.state = "completed"
    
    if chain.onComplete then
        task.spawn(chain.onComplete)
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("AnimationChainCompleted", {
            chainId = chain.id,
        })
    end
    
    -- Clean up if not looping
    if not chain.loop then
        self._animationChains[chain.id] = nil
    end
end

-- ========================================
-- SPRING PHYSICS ANIMATIONS
-- ========================================

function AnimationSystem:AnimateSpring(object: Instance, property: string, goal: any, options: SpringOptions?): string
    options = options or {}
    
    local springId = self:GenerateId()
    
    -- Get current value
    local success, currentValue = pcall(function() return object[property] end)
    if not success then
        warn("[AnimationSystem] Failed to get property value:", property)
        return springId
    end
    
    -- Create spring
    local spring: Spring = {
        position = tonumber(currentValue) or 0,
        velocity = options.initialVelocity or 0,
        mass = options.mass or DEFAULT_SPRING_MASS,
        stiffness = options.stiffness or DEFAULT_SPRING_STIFFNESS,
        damping = options.damping or DEFAULT_SPRING_DAMPING,
        goal = tonumber(goal) or 0,
    }
    
    -- Create spring animation
    local springAnimation: SpringAnimation = {
        id = springId,
        object = object,
        property = property,
        spring = spring,
        connection = nil,
        state = "playing",
    }
    
    self._springAnimations[springId] = springAnimation
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("SpringAnimationStarted", {
            id = springId,
            object = object,
            property = property,
            goal = goal,
        })
    end
    
    return springId
end

function AnimationSystem:UpdateSpring(spring: Spring, deltaTime: number): boolean
    -- Calculate spring force
    local displacement = spring.position - spring.goal
    local springForce = -spring.stiffness * displacement
    local dampingForce = -spring.damping * spring.velocity
    local totalForce = springForce + dampingForce
    
    -- Update velocity and position
    local acceleration = totalForce / spring.mass
    spring.velocity = spring.velocity + acceleration * deltaTime
    spring.position = spring.position + spring.velocity * deltaTime
    
    -- Check if spring has settled
    local isSettled = math.abs(spring.velocity) < SPRING_EPSILON and 
                     math.abs(displacement) < SPRING_EPSILON
    
    return isSettled
end

function AnimationSystem:StartSpringUpdateLoop()
    self._springUpdateConnection = Services.RunService.Heartbeat:Connect(function(deltaTime)
        if not self._enabled then return end
        
        local toRemove = {}
        
        for springId, springAnimation in pairs(self._springAnimations) do
            if springAnimation.state == "playing" then
                local isSettled = self:UpdateSpring(springAnimation.spring, deltaTime * self._timeScale)
                
                -- Apply the spring value to the object
                local success = pcall(function()
                    springAnimation.object[springAnimation.property] = springAnimation.spring.position
                end)
                
                if not success or isSettled then
                    springAnimation.state = "completed"
                    table.insert(toRemove, springId)
                    
                    -- Fire event
                    if self._eventBus then
                        self._eventBus:Fire("SpringAnimationCompleted", {
                            id = springId,
                        })
                    end
                end
            end
        end
        
        -- Clean up completed animations
        for _, springId in ipairs(toRemove) do
            self._springAnimations[springId] = nil
        end
    end)
end

-- ========================================
-- CUSTOM EASING
-- ========================================

function AnimationSystem:AnimateCustom(object: Instance, property: string, startValue: any, endValue: any, duration: number, easingFunction: (number) -> number, onComplete: (() -> ())?): string
    local animationId = self:GenerateId()
    local startTime = tick()
    local connection
    
    -- Ensure we can work with numbers
    startValue = tonumber(startValue) or 0
    endValue = tonumber(endValue) or 0
    
    connection = Services.RunService.Heartbeat:Connect(function()
        if not self._enabled then
            connection:Disconnect()
            return
        end
        
        local elapsed = (tick() - startTime) * self._timeScale
        local progress = math.min(elapsed / duration, 1)
        local easedProgress = easingFunction(progress)
        
        -- Interpolate value
        local currentValue = startValue + (endValue - startValue) * easedProgress
        
        -- Apply to object
        local success = pcall(function()
            object[property] = currentValue
        end)
        
        if not success or progress >= 1 then
            connection:Disconnect()
            
            if onComplete then
                task.spawn(onComplete)
            end
            
            -- Fire event
            if self._eventBus then
                self._eventBus:Fire("CustomAnimationCompleted", {
                    id = animationId,
                    object = object,
                    property = property,
                })
            end
        end
    end)
    
    return animationId
end

-- ========================================
-- PRESET ANIMATIONS
-- ========================================

function AnimationSystem:FadeIn(object: GuiObject, duration: number?): string
    object.Visible = true
    object.BackgroundTransparency = 1
    
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        object.TextTransparency = 1
    end
    
    local properties = {BackgroundTransparency = 0}
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        properties.TextTransparency = 0
    end
    
    return self:Animate(object, properties, {
        duration = duration or 0.3,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out,
    })
end

function AnimationSystem:FadeOut(object: GuiObject, duration: number?): string
    local properties = {BackgroundTransparency = 1}
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        properties.TextTransparency = 1
    end
    
    return self:Animate(object, properties, {
        duration = duration or 0.3,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out,
        onComplete = function()
            object.Visible = false
        end,
    })
end

function AnimationSystem:SlideIn(object: GuiObject, direction: "left" | "right" | "top" | "bottom", duration: number?): string
    local startPosition = object.Position
    local offset = UDim2.new(0, 0, 0, 0)
    
    if direction == "left" then
        offset = UDim2.new(-1.5, 0, 0, 0)
    elseif direction == "right" then
        offset = UDim2.new(1.5, 0, 0, 0)
    elseif direction == "top" then
        offset = UDim2.new(0, 0, -1.5, 0)
    elseif direction == "bottom" then
        offset = UDim2.new(0, 0, 1.5, 0)
    end
    
    object.Position = startPosition + offset
    object.Visible = true
    
    return self:Animate(object, {Position = startPosition}, {
        duration = duration or 0.5,
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.Out,
    })
end

function AnimationSystem:SlideOut(object: GuiObject, direction: "left" | "right" | "top" | "bottom", duration: number?): string
    local offset = UDim2.new(0, 0, 0, 0)
    
    if direction == "left" then
        offset = UDim2.new(-1.5, 0, 0, 0)
    elseif direction == "right" then
        offset = UDim2.new(1.5, 0, 0, 0)
    elseif direction == "top" then
        offset = UDim2.new(0, 0, -1.5, 0)
    elseif direction == "bottom" then
        offset = UDim2.new(0, 0, 1.5, 0)
    end
    
    return self:Animate(object, {Position = object.Position + offset}, {
        duration = duration or 0.5,
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.In,
        onComplete = function()
            object.Visible = false
        end,
    })
end

function AnimationSystem:ScaleIn(object: GuiObject, duration: number?): string
    local originalSize = object.Size
    object.Size = UDim2.new(0, 0, 0, 0)
    object.AnchorPoint = Vector2.new(0.5, 0.5)
    object.Position = object.Position + UDim2.new(
        originalSize.X.Scale * 0.5,
        originalSize.X.Offset * 0.5,
        originalSize.Y.Scale * 0.5,
        originalSize.Y.Offset * 0.5
    )
    object.Visible = true
    
    return self:Animate(object, {Size = originalSize}, {
        duration = duration or 0.3,
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.Out,
    })
end

function AnimationSystem:ScaleOut(object: GuiObject, duration: number?): string
    object.AnchorPoint = Vector2.new(0.5, 0.5)
    
    return self:Animate(object, {Size = UDim2.new(0, 0, 0, 0)}, {
        duration = duration or 0.3,
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.In,
        onComplete = function()
            object.Visible = false
        end,
    })
end

function AnimationSystem:Bounce(object: GuiObject, scale: number?, duration: number?): string
    scale = scale or 1.2
    duration = duration or 0.5
    
    local originalSize = object.Size
    local bounceSize = UDim2.new(
        originalSize.X.Scale * scale,
        originalSize.X.Offset * scale,
        originalSize.Y.Scale * scale,
        originalSize.Y.Offset * scale
    )
    
    -- Create chain for bounce effect
    local chain = self:CreateChain("sequential")
    
    -- Scale up
    self:AddToChain(chain, object, {Size = bounceSize}, {
        duration = duration * 0.3,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out,
    })
    
    -- Scale down past original
    self:AddToChain(chain, object, {Size = UDim2.new(
        originalSize.X.Scale * 0.9,
        originalSize.X.Offset * 0.9,
        originalSize.Y.Scale * 0.9,
        originalSize.Y.Offset * 0.9
    )}, {
        duration = duration * 0.4,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.InOut,
    })
    
    -- Back to original
    self:AddToChain(chain, object, {Size = originalSize}, {
        duration = duration * 0.3,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out,
    })
    
    return self:PlayChain(chain)
end

function AnimationSystem:Shake(object: GuiObject, intensity: number?, duration: number?): string
    intensity = intensity or 10
    duration = duration or 0.5
    
    local originalPosition = object.Position
    local shakeCount = 10
    local shakeChain = self:CreateChain("sequential")
    
    for i = 1, shakeCount do
        local offsetX = (math.random() - 0.5) * 2 * intensity
        local offsetY = (math.random() - 0.5) * 2 * intensity
        
        self:AddToChain(shakeChain, object, {
            Position = originalPosition + UDim2.new(0, offsetX, 0, offsetY)
        }, {
            duration = duration / shakeCount,
            easingStyle = Enum.EasingStyle.Linear,
        })
    end
    
    -- Return to original position
    self:AddToChain(shakeChain, object, {Position = originalPosition}, {
        duration = duration / shakeCount,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out,
    })
    
    return self:PlayChain(shakeChain)
end

function AnimationSystem:Pulse(object: GuiObject, scale: number?, duration: number?): string
    scale = scale or 1.1
    duration = duration or 1
    
    local originalSize = object.Size
    local pulseSize = UDim2.new(
        originalSize.X.Scale * scale,
        originalSize.X.Offset * scale,
        originalSize.Y.Scale * scale,
        originalSize.Y.Offset * scale
    )
    
    return self:Animate(object, {Size = pulseSize}, {
        duration = duration,
        easingStyle = Enum.EasingStyle.Sine,
        easingDirection = Enum.EasingDirection.InOut,
        repeatCount = -1,
        reverses = true,
    })
end

-- ========================================
-- ANIMATION CONTROL
-- ========================================

function AnimationSystem:Pause(animationId: string)
    local animation = self._animations[animationId]
    if animation and animation.tween then
        animation.tween:Pause()
        animation.state = "paused"
    end
end

function AnimationSystem:Resume(animationId: string)
    local animation = self._animations[animationId]
    if animation and animation.tween and animation.state == "paused" then
        animation.tween:Play()
        animation.state = "playing"
    end
end

function AnimationSystem:Cancel(animationId: string)
    local animation = self._animations[animationId]
    if animation then
        if animation.tween then
            animation.tween:Cancel()
        end
        animation.state = "cancelled"
        self:OnAnimationCancelled(animationId)
    end
end

function AnimationSystem:CancelAllForObject(object: Instance)
    local animationIds = self._animationsByObject[object]
    if animationIds then
        for animationId in pairs(animationIds) do
            self:Cancel(animationId)
        end
    end
end

function AnimationSystem:SetTimeScale(scale: number)
    self._timeScale = math.max(0.1, math.min(10, scale))
end

-- ========================================
-- BATCH ANIMATIONS
-- ========================================

function AnimationSystem:AnimateBatch(animations: {{object: Instance, properties: {[string]: any}, options: AnimationOptions?}}): {string}
    local animationIds = {}
    
    for _, animData in ipairs(animations) do
        local id = self:Animate(animData.object, animData.properties, animData.options)
        table.insert(animationIds, id)
    end
    
    return animationIds
end

function AnimationSystem:StaggeredAnimate(objects: {Instance}, properties: {[string]: any}, staggerDelay: number, options: AnimationOptions?): {string}
    local animationIds = {}
    
    for i, object in ipairs(objects) do
        local animOptions = table.clone(options or {})
        animOptions.delayTime = (animOptions.delayTime or 0) + (i - 1) * staggerDelay
        
        local id = self:Animate(object, properties, animOptions)
        table.insert(animationIds, id)
    end
    
    return animationIds
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function AnimationSystem:StartUpdateLoop()
    local lastFrameTime = tick()
    
    self._updateConnection = Services.RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local frameTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        -- Update performance metrics
        table.insert(self._performanceMetrics.frameTimeHistory, frameTime)
        if #self._performanceMetrics.frameTimeHistory > PERFORMANCE_SAMPLE_RATE then
            table.remove(self._performanceMetrics.frameTimeHistory, 1)
        end
        
        -- Calculate average frame time
        local sum = 0
        for _, time in ipairs(self._performanceMetrics.frameTimeHistory) do
            sum = sum + time
        end
        self._performanceMetrics.averageFrameTime = sum / #self._performanceMetrics.frameTimeHistory
        
        -- Check for performance issues (only warn for very severe drops)
        if frameTime > 1/10 then -- Less than 10 FPS (very tolerant)
            self:OnPerformanceIssue(frameTime)
        end
        
        -- Process animation queue if needed
        self:ProcessAnimationQueue()
    end)
end

function AnimationSystem:ProcessAnimationQueue()
    if #self._animationQueue == 0 then return end
    
    local activeCount = 0
    for _, animation in pairs(self._animations) do
        if animation.state == "playing" then
            activeCount = activeCount + 1
        end
    end
    
    -- Process queued animations if under limit
    while activeCount < self._maxConcurrentAnimations and #self._animationQueue > 0 do
        local queuedAnim = table.remove(self._animationQueue, 1)
        self:Animate(queuedAnim.object, queuedAnim.properties, queuedAnim.options)
        activeCount = activeCount + 1
    end
end

function AnimationSystem:OnPerformanceIssue(frameTime: number)
    -- Only log extreme performance issues to reduce console spam
    if self._debugMode and frameTime > 0.5 then -- 500ms = 2 FPS
        warn("[AnimationSystem] Severe performance issue detected. Frame time:", frameTime)
    end
    
    -- Reduce max concurrent animations temporarily
    if frameTime > 0.2 then -- More than 200ms
        self._maxConcurrentAnimations = math.max(10, self._maxConcurrentAnimations - 10)
        -- Restore after 2 seconds (don't use task.wait in performance-critical code)
        task.spawn(function()
            task.wait(2)
            self._maxConcurrentAnimations = MAX_CONCURRENT_ANIMATIONS
        end)
    end
    
    -- Fire event for other systems to react
    if self._eventBus then
        self._eventBus:Fire("AnimationPerformanceIssue", {
            frameTime = frameTime,
            activeAnimations = self._performanceMetrics.activeAnimations,
        })
    end
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function AnimationSystem:GenerateId(): string
    self._nextId = self._nextId + 1
    return "anim_" .. tostring(self._nextId)
end

function AnimationSystem:TrackAnimationForObject(object: Instance, animationId: string)
    if not self._animationsByObject[object] then
        self._animationsByObject[object] = {}
    end
    self._animationsByObject[object][animationId] = true
end

function AnimationSystem:OnAnimationCompleted(animationId: string)
    local animation = self._animations[animationId]
    if not animation then return end
    
    -- Update metrics
    self._performanceMetrics.activeAnimations = self._performanceMetrics.activeAnimations - 1
    self._performanceMetrics.completedAnimations = self._performanceMetrics.completedAnimations + 1
    
    -- Clean up tracking
    if animation.object and self._animationsByObject[animation.object] then
        self._animationsByObject[animation.object][animationId] = nil
        
        -- Remove object tracking if no more animations
        if next(self._animationsByObject[animation.object]) == nil then
            self._animationsByObject[animation.object] = nil
        end
    end
    
    -- Remove animation
    self._animations[animationId] = nil
end

function AnimationSystem:OnAnimationCancelled(animationId: string)
    local animation = self._animations[animationId]
    if not animation then return end
    
    -- Update metrics
    self._performanceMetrics.activeAnimations = self._performanceMetrics.activeAnimations - 1
    self._performanceMetrics.cancelledAnimations = self._performanceMetrics.cancelledAnimations + 1
    
    -- Clean up tracking
    if animation.object and self._animationsByObject[animation.object] then
        self._animationsByObject[animation.object][animationId] = nil
        
        -- Remove object tracking if no more animations
        if next(self._animationsByObject[animation.object]) == nil then
            self._animationsByObject[animation.object] = nil
        end
    end
    
    -- Remove animation
    self._animations[animationId] = nil
end

-- ========================================
-- DEBUGGING
-- ========================================

function AnimationSystem:GetStats(): table
    return {
        enabled = self._enabled,
        timeScale = self._timeScale,
        totalAnimations = self._performanceMetrics.totalAnimations,
        activeAnimations = self._performanceMetrics.activeAnimations,
        completedAnimations = self._performanceMetrics.completedAnimations,
        cancelledAnimations = self._performanceMetrics.cancelledAnimations,
        averageFrameTime = self._performanceMetrics.averageFrameTime,
        averageFPS = 1 / self._performanceMetrics.averageFrameTime,
        queuedAnimations = #self._animationQueue,
        activeChains = self:GetTableSize(self._animationChains),
        activeSprings = self:GetTableSize(self._springAnimations),
    }
end

function AnimationSystem:GetTableSize(tbl: table): number
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

if Config.DEBUG.ENABLED then
    function AnimationSystem:DebugPrint()
        print("\n=== AnimationSystem Debug Info ===")
        
        local stats = self:GetStats()
        for key, value in pairs(stats) do
            print(key .. ":", value)
        end
        
        print("\nActive Animations:")
        for animId, animation in pairs(self._animations) do
            print("  " .. animId .. ":", animation.state, "-", animation.object.Name)
        end
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function AnimationSystem:Destroy()
    -- Cancel all active animations
    for animationId in pairs(self._animations) do
        self:Cancel(animationId)
    end
    
    -- Disconnect update loops
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
    
    if self._springUpdateConnection then
        self._springUpdateConnection:Disconnect()
        self._springUpdateConnection = nil
    end
    
    -- Clear all data
    self._animations = {}
    self._animationChains = {}
    self._springAnimations = {}
    self._animationsByObject = {}
    self._animationQueue = {}
end

return AnimationSystem