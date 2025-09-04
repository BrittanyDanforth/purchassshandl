--[[
    Module: ParticleSystem
    Description: Advanced particle effects with pooling, batch rendering, and performance optimization
    Provides various particle effects for UI feedback and celebrations
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

-- ========================================
-- TYPES
-- ========================================

type ParticleData = {
    id: string,
    part: BasePart,
    image: ImageLabel?,
    startTime: number,
    lifetime: number,
    startPosition: Vector3,
    velocity: Vector3,
    acceleration: Vector3,
    startSize: number,
    endSize: number,
    startTransparency: number,
    endTransparency: number,
    rotationSpeed: number,
    color: Color3,
    emitter: ParticleEmitter?,
}

type ParticleEmitter = {
    id: string,
    active: boolean,
    position: Vector3,
    rate: number,
    spread: number,
    particleType: string,
    properties: table,
    lastEmit: number,
    attachment: Attachment?,
}

type ParticlePreset = {
    texture: string,
    lifetime: NumberRange,
    rate: number,
    speed: NumberRange,
    spreadAngle: Vector2,
    acceleration: Vector3,
    drag: number,
    rotSpeed: NumberRange,
    transparency: NumberSequence,
    size: NumberSequence,
    color: ColorSequence,
    lightEmission: number,
    lightInfluence: number,
}

-- ========================================
-- CONSTANTS
-- ========================================

local MAX_PARTICLES = 500
local POOL_SIZE = 100
local UPDATE_RATE = 60 -- FPS
local CLEANUP_INTERVAL = 5
local BATCH_SIZE = 50

-- Particle textures
local PARTICLE_TEXTURES = {
    Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
    Star = "rbxasset://textures/particles/star.dds",
    Heart = "rbxasset://textures/particles/heart.dds",
    Smoke = "rbxasset://textures/particles/smoke_main.dds",
    Fire = "rbxasset://textures/particles/fire_main.dds",
    Confetti = "rbxasset://textures/particles/confetti.dds",
    Coin = "rbxassetid://7149835823", -- Custom coin texture
    Diamond = "rbxassetid://7149835824", -- Custom diamond texture
}

-- ========================================
-- INITIALIZATION
-- ========================================

function ParticleSystem.new(dependencies)
    local self = setmetatable({}, ParticleSystem)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    
    -- Particle storage
    self._activeParticles = {} -- id -> ParticleData
    self._particlePool = {} -- particleType -> {parts}
    self._emitters = {} -- id -> ParticleEmitter
    self._presets = {} -- name -> ParticlePreset
    
    -- Performance
    self._particleCount = 0
    self._updateConnection = nil
    self._lastUpdate = 0
    self._throttleLevel = 0 -- 0 = full, 1 = reduced, 2 = minimal
    
    -- Settings
    self._enabled = true
    self._qualityLevel = 2 -- 0 = low, 1 = medium, 2 = high
    self._maxParticles = MAX_PARTICLES
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Container for world particles
    self._worldContainer = nil
    self._screenContainer = nil
    
    self:Initialize()
    
    return self
end

function ParticleSystem:Initialize()
    -- Create containers
    self:CreateContainers()
    
    -- Load settings
    self:LoadSettings()
    
    -- Create presets
    self:CreatePresets()
    
    -- Start update loop
    self:StartUpdateLoop()
    
    -- Start cleanup task
    self:StartCleanupTask()
    
    -- Listen for settings changes
    if self._stateManager then
        self._stateManager:Subscribe("player.settings", function(settings)
            if settings then
                self:UpdateSettings(settings)
            end
        end)
    end
    
    if self._debugMode then
        print("[ParticleSystem] Initialized with quality level:", self._qualityLevel)
    end
end

-- ========================================
-- PARTICLE CREATION
-- ========================================

function ParticleSystem:CreateParticle(particleType: string, position: Vector3, properties: table?): string?
    if not self._enabled or self._particleCount >= self._maxParticles then
        return nil
    end
    
    properties = properties or {}
    
    -- Get pooled particle or create new
    local particle = self:GetPooledParticle(particleType) or self:CreateNewParticle(particleType)
    if not particle then
        return nil
    end
    
    -- Generate ID
    local id = self._utilities.CreateUUID()
    
    -- Configure particle
    local particleData: ParticleData = {
        id = id,
        part = particle,
        image = particle:FindFirstChildOfClass("BillboardGui") and particle.BillboardGui.ImageLabel,
        startTime = tick(),
        lifetime = properties.lifetime or 2,
        startPosition = position,
        velocity = properties.velocity or Vector3.new(
            math.random(-5, 5),
            math.random(5, 15),
            math.random(-5, 5)
        ),
        acceleration = properties.acceleration or Vector3.new(0, -20, 0),
        startSize = properties.size or 1,
        endSize = properties.endSize or 0,
        startTransparency = properties.transparency or 0,
        endTransparency = properties.endTransparency or 1,
        rotationSpeed = properties.rotationSpeed or math.random(-360, 360),
        color = properties.color or Color3.new(1, 1, 1),
    }
    
    -- Apply initial properties
    particle.Position = position
    particle.Size = Vector3.new(particleData.startSize, particleData.startSize, 0.1)
    
    if particleData.image then
        particleData.image.ImageColor3 = particleData.color
        particleData.image.ImageTransparency = particleData.startTransparency
    end
    
    -- Store particle
    self._activeParticles[id] = particleData
    self._particleCount = self._particleCount + 1
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("ParticleCreated", {
            id = id,
            type = particleType,
            position = position,
        })
    end
    
    return id
end

function ParticleSystem:CreateSparkle(position: Vector3, color: Color3?): string?
    return self:CreateParticle("Sparkle", position, {
        lifetime = 1,
        size = 0.5,
        endSize = 0,
        color = color or Color3.new(1, 1, 0),
        velocity = Vector3.new(
            math.random(-10, 10),
            math.random(5, 20),
            math.random(-10, 10)
        ),
        rotationSpeed = math.random(180, 540),
    })
end

function ParticleSystem:CreateStar(position: Vector3, color: Color3?): string?
    return self:CreateParticle("Star", position, {
        lifetime = 1.5,
        size = 1,
        endSize = 0.2,
        color = color or Color3.new(1, 1, 0),
        velocity = Vector3.new(
            math.random(-5, 5),
            math.random(10, 25),
            math.random(-5, 5)
        ),
        rotationSpeed = math.random(90, 270),
    })
end

function ParticleSystem:CreateHeart(position: Vector3, color: Color3?): string?
    return self:CreateParticle("Heart", position, {
        lifetime = 2,
        size = 1.2,
        endSize = 0.3,
        color = color or Color3.fromRGB(255, 100, 150),
        velocity = Vector3.new(
            math.random(-3, 3),
            math.random(8, 15),
            math.random(-3, 3)
        ),
        acceleration = Vector3.new(0, -10, 0),
        rotationSpeed = math.random(-90, 90),
    })
end

function ParticleSystem:CreateCoin(position: Vector3): string?
    return self:CreateParticle("Coin", position, {
        lifetime = 1.5,
        size = 0.8,
        endSize = 0.4,
        color = Color3.fromRGB(255, 215, 0),
        velocity = Vector3.new(
            math.random(-8, 8),
            math.random(15, 25),
            math.random(-8, 8)
        ),
        acceleration = Vector3.new(0, -30, 0),
        rotationSpeed = math.random(360, 720),
    })
end

function ParticleSystem:CreateConfetti(position: Vector3): string?
    local colors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(0, 255, 255),
    }
    
    return self:CreateParticle("Confetti", position, {
        lifetime = 3,
        size = 0.6,
        endSize = 0.6,
        color = colors[math.random(1, #colors)],
        velocity = Vector3.new(
            math.random(-15, 15),
            math.random(10, 30),
            math.random(-15, 15)
        ),
        acceleration = Vector3.new(0, -15, 0),
        rotationSpeed = math.random(180, 720),
    })
end

-- ========================================
-- PARTICLE BURSTS
-- ========================================

function ParticleSystem:CreateBurst(particleType: string, position: Vector3, count: number, spread: number?)
    spread = spread or 5
    
    local particles = {}
    
    for i = 1, math.min(count, 50) do -- Limit burst size
        local offset = Vector3.new(
            math.random(-spread, spread),
            math.random(-spread/2, spread/2),
            math.random(-spread, spread)
        )
        
        local id = self:CreateParticle(particleType, position + offset)
        if id then
            table.insert(particles, id)
        end
        
        -- Small delay between particles for performance
        if i % 10 == 0 then
            task.wait()
        end
    end
    
    return particles
end

function ParticleSystem:CreateSparkleExplosion(position: Vector3, count: number?)
    return self:CreateBurst("Sparkle", position, count or 20, 3)
end

function ParticleSystem:CreateConfettiShower(position: Vector3, count: number?)
    return self:CreateBurst("Confetti", position, count or 30, 10)
end

function ParticleSystem:CreateCoinShower(position: Vector3, count: number?)
    return self:CreateBurst("Coin", position, count or 15, 5)
end

-- ========================================
-- EMITTER SYSTEM
-- ========================================

function ParticleSystem:CreateEmitter(position: Vector3, particleType: string, rate: number): string
    local id = self._utilities.CreateUUID()
    
    local emitter: ParticleEmitter = {
        id = id,
        active = true,
        position = position,
        rate = rate,
        spread = 2,
        particleType = particleType,
        properties = {},
        lastEmit = 0,
        attachment = nil,
    }
    
    self._emitters[id] = emitter
    
    return id
end

function ParticleSystem:UpdateEmitter(id: string, properties: table)
    local emitter = self._emitters[id]
    if not emitter then
        return
    end
    
    for key, value in pairs(properties) do
        emitter[key] = value
    end
end

function ParticleSystem:StopEmitter(id: string)
    local emitter = self._emitters[id]
    if emitter then
        emitter.active = false
    end
end

function ParticleSystem:DestroyEmitter(id: string)
    local emitter = self._emitters[id]
    if emitter then
        if emitter.attachment then
            emitter.attachment:Destroy()
        end
        self._emitters[id] = nil
    end
end

-- ========================================
-- ROBLOX PARTICLE EMITTERS
-- ========================================

function ParticleSystem:CreateRobloxEmitter(parent: Instance, preset: string): ParticleEmitter?
    local presetData = self._presets[preset]
    if not presetData then
        warn("[ParticleSystem] Unknown preset:", preset)
        return nil
    end
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = parent
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = presetData.texture
    emitter.Lifetime = presetData.lifetime
    emitter.Rate = presetData.rate
    emitter.Speed = presetData.speed
    emitter.SpreadAngle = presetData.spreadAngle
    emitter.Acceleration = presetData.acceleration
    emitter.Drag = presetData.drag
    emitter.RotSpeed = presetData.rotSpeed
    emitter.Transparency = presetData.transparency
    emitter.Size = presetData.size
    emitter.Color = presetData.color
    emitter.LightEmission = presetData.lightEmission
    emitter.LightInfluence = presetData.lightInfluence
    emitter.Parent = attachment
    
    -- Auto cleanup after lifetime
    task.delay(presetData.lifetime.Max + 1, function()
        if emitter and emitter.Parent then
            emitter.Enabled = false
            task.wait(1)
            attachment:Destroy()
        end
    end)
    
    return emitter
end

-- ========================================
-- UPDATE SYSTEM
-- ========================================

function ParticleSystem:StartUpdateLoop()
    self._updateConnection = Services.RunService.Heartbeat:Connect(function(deltaTime)
        self:UpdateParticles(deltaTime)
        self:UpdateEmitters(deltaTime)
    end)
end

function ParticleSystem:UpdateParticles(deltaTime: number)
    local now = tick()
    local toRemove = {}
    
    for id, particle in pairs(self._activeParticles) do
        local age = now - particle.startTime
        local lifePercent = age / particle.lifetime
        
        if lifePercent >= 1 then
            table.insert(toRemove, id)
        else
            -- Update position
            particle.velocity = particle.velocity + particle.acceleration * deltaTime
            local newPosition = particle.part.Position + particle.velocity * deltaTime
            particle.part.Position = newPosition
            
            -- Update size
            local size = self._utilities.Lerp(particle.startSize, particle.endSize, lifePercent)
            particle.part.Size = Vector3.new(size, size, 0.1)
            
            -- Update transparency
            if particle.image then
                particle.image.ImageTransparency = self._utilities.Lerp(
                    particle.startTransparency,
                    particle.endTransparency,
                    lifePercent
                )
            end
            
            -- Update rotation
            particle.part.CFrame = particle.part.CFrame * CFrame.Angles(
                0, 0, math.rad(particle.rotationSpeed * deltaTime)
            )
        end
    end
    
    -- Remove dead particles
    for _, id in ipairs(toRemove) do
        self:RemoveParticle(id)
    end
end

function ParticleSystem:UpdateEmitters(deltaTime: number)
    local now = tick()
    
    for id, emitter in pairs(self._emitters) do
        if emitter.active then
            local timeSinceEmit = now - emitter.lastEmit
            local emitInterval = 1 / emitter.rate
            
            if timeSinceEmit >= emitInterval then
                -- Emit particle
                local offset = Vector3.new(
                    math.random(-emitter.spread, emitter.spread),
                    0,
                    math.random(-emitter.spread, emitter.spread)
                )
                
                self:CreateParticle(
                    emitter.particleType,
                    emitter.position + offset,
                    emitter.properties
                )
                
                emitter.lastEmit = now
            end
        end
    end
end

-- ========================================
-- PARTICLE MANAGEMENT
-- ========================================

function ParticleSystem:GetPooledParticle(particleType: string): BasePart?
    local pool = self._particlePool[particleType]
    if not pool or #pool == 0 then
        return nil
    end
    
    return table.remove(pool)
end

function ParticleSystem:CreateNewParticle(particleType: string): BasePart
    local part = Instance.new("Part")
    part.Name = "Particle_" .. particleType
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Create billboard GUI for texture
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(2, 0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local image = Instance.new("ImageLabel")
    image.Size = UDim2.new(1, 0, 1, 0)
    image.BackgroundTransparency = 1
    image.Image = PARTICLE_TEXTURES[particleType] or PARTICLE_TEXTURES.Sparkle
    image.Parent = billboard
    
    part.Parent = self._worldContainer
    
    return part
end

function ParticleSystem:ReturnToPool(particleType: string, part: BasePart)
    if not self._particlePool[particleType] then
        self._particlePool[particleType] = {}
    end
    
    local pool = self._particlePool[particleType]
    
    if #pool < POOL_SIZE then
        -- Reset particle
        part.CFrame = CFrame.new(0, -1000, 0)
        part.Velocity = Vector3.new()
        part.AssemblyLinearVelocity = Vector3.new()
        part.AssemblyAngularVelocity = Vector3.new()
        
        table.insert(pool, part)
    else
        part:Destroy()
    end
end

function ParticleSystem:RemoveParticle(id: string)
    local particle = self._activeParticles[id]
    if not particle then
        return
    end
    
    -- Determine particle type from name
    local particleType = particle.part.Name:match("Particle_(.+)") or "Unknown"
    
    -- Return to pool
    self:ReturnToPool(particleType, particle.part)
    
    -- Remove from active
    self._activeParticles[id] = nil
    self._particleCount = self._particleCount - 1
end

-- ========================================
-- SETTINGS & OPTIMIZATION
-- ========================================

function ParticleSystem:LoadSettings()
    if self._stateManager then
        local settings = self._stateManager:Get("player.settings")
        if settings then
            self._enabled = settings.particlesEnabled ~= false
            self._qualityLevel = settings.lowQualityMode and 0 or 2
            self:UpdateQualitySettings()
        end
    end
end

function ParticleSystem:UpdateSettings(settings: Types.SettingsData)
    self._enabled = settings.particlesEnabled ~= false
    self._qualityLevel = settings.lowQualityMode and 0 or 2
    self:UpdateQualitySettings()
    
    if not self._enabled then
        self:ClearAllParticles()
    end
end

function ParticleSystem:UpdateQualitySettings()
    -- Adjust limits based on quality
    if self._qualityLevel == 0 then
        self._maxParticles = 50
        self._throttleLevel = 2
    elseif self._qualityLevel == 1 then
        self._maxParticles = 200
        self._throttleLevel = 1
    else
        self._maxParticles = MAX_PARTICLES
        self._throttleLevel = 0
    end
end

function ParticleSystem:SetThrottleLevel(level: number)
    self._throttleLevel = math.clamp(level, 0, 2)
end

-- ========================================
-- CONTAINERS
-- ========================================

function ParticleSystem:CreateContainers()
    -- World space particles
    local worldContainer = Services.Workspace:FindFirstChild("ParticleContainer")
    if not worldContainer then
        worldContainer = Instance.new("Folder")
        worldContainer.Name = "ParticleContainer"
        worldContainer.Parent = Services.Workspace
    end
    self._worldContainer = worldContainer
    
    -- Screen space particles (for UI)
    local screenGui = Services.PlayerGui:FindFirstChild("ParticleGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "ParticleGui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 100
        screenGui.Parent = Services.PlayerGui
    end
    self._screenContainer = screenGui
end

-- ========================================
-- PRESETS
-- ========================================

function ParticleSystem:CreatePresets()
    -- Sparkle burst preset
    self._presets["SparkeBurst"] = {
        texture = PARTICLE_TEXTURES.Sparkle,
        lifetime = NumberRange.new(0.5, 1),
        rate = 50,
        speed = NumberRange.new(5, 20),
        spreadAngle = Vector2.new(360, 360),
        acceleration = Vector3.new(0, -10, 0),
        drag = 1,
        rotSpeed = NumberRange.new(-360, 360),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        color = ColorSequence.new(Color3.fromRGB(255, 255, 100)),
        lightEmission = 1,
        lightInfluence = 0,
    }
    
    -- Coin fountain preset
    self._presets["CoinFountain"] = {
        texture = PARTICLE_TEXTURES.Coin,
        lifetime = NumberRange.new(1, 2),
        rate = 20,
        speed = NumberRange.new(10, 25),
        spreadAngle = Vector2.new(45, 45),
        acceleration = Vector3.new(0, -35, 0),
        drag = 0.5,
        rotSpeed = NumberRange.new(360, 720),
        transparency = NumberSequence.new(0),
        size = NumberSequence.new(0.8),
        color = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
        lightEmission = 0.5,
        lightInfluence = 0.5,
    }
    
    -- Heart float preset
    self._presets["HeartFloat"] = {
        texture = PARTICLE_TEXTURES.Heart,
        lifetime = NumberRange.new(2, 3),
        rate = 5,
        speed = NumberRange.new(2, 5),
        spreadAngle = Vector2.new(10, 10),
        acceleration = Vector3.new(0, 5, 0),
        drag = 2,
        rotSpeed = NumberRange.new(-90, 90),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0),
            NumberSequenceKeypoint.new(0.8, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.2, 1.2),
            NumberSequenceKeypoint.new(1, 0.8),
        }),
        color = ColorSequence.new(Color3.fromRGB(255, 100, 150)),
        lightEmission = 0.3,
        lightInfluence = 0.7,
    }
end

-- ========================================
-- CLEANUP
-- ========================================

function ParticleSystem:StartCleanupTask()
    task.spawn(function()
        while true do
            task.wait(CLEANUP_INTERVAL)
            self:CleanupPools()
        end
    end)
end

function ParticleSystem:CleanupPools()
    for particleType, pool in pairs(self._particlePool) do
        -- Remove excess pooled particles
        while #pool > POOL_SIZE / 2 do
            local part = table.remove(pool)
            part:Destroy()
        end
    end
end

function ParticleSystem:ClearAllParticles()
    -- Remove all active particles
    for id in pairs(self._activeParticles) do
        self:RemoveParticle(id)
    end
    
    -- Stop all emitters
    for id in pairs(self._emitters) do
        self:DestroyEmitter(id)
    end
end

-- ========================================
-- DEBUGGING
-- ========================================

function ParticleSystem:GetStats(): table
    local pooledCount = 0
    for _, pool in pairs(self._particlePool) do
        pooledCount = pooledCount + #pool
    end
    
    return {
        activeParticles = self._particleCount,
        pooledParticles = pooledCount,
        activeEmitters = self._utilities:CountTable(self._emitters),
        qualityLevel = self._qualityLevel,
        throttleLevel = self._throttleLevel,
        enabled = self._enabled,
    }
end

if Config.DEBUG.ENABLED then
    function ParticleSystem:DebugPrint()
        print("\n=== ParticleSystem Debug Info ===")
        
        local stats = self:GetStats()
        print("Active Particles:", stats.activeParticles)
        print("Pooled Particles:", stats.pooledParticles)
        print("Active Emitters:", stats.activeEmitters)
        print("Quality Level:", stats.qualityLevel)
        print("Throttle Level:", stats.throttleLevel)
        print("Enabled:", stats.enabled)
        
        print("================================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function ParticleSystem:Destroy()
    -- Stop update loop
    if self._updateConnection then
        self._updateConnection:Disconnect()
    end
    
    -- Clear all particles
    self:ClearAllParticles()
    
    -- Destroy pools
    for _, pool in pairs(self._particlePool) do
        for _, part in ipairs(pool) do
            part:Destroy()
        end
    end
    
    -- Clear containers
    if self._worldContainer then
        self._worldContainer:ClearAllChildren()
    end
    
    if self._screenContainer then
        self._screenContainer:Destroy()
    end
end

return ParticleSystem