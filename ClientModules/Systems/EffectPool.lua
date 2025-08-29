--[[
    Module: EffectPool
    Description: Object pooling system for UI effects to prevent micro-stutters
    Features: Reusable effect instances, automatic cleanup, performance optimization
]]

local EffectPool = {}
EffectPool.__index = EffectPool

-- ========================================
-- TYPES
-- ========================================

type PoolConfig = {
    initialSize: number?,
    maxSize: number?,
    growthRate: number?,
    effectType: string,
    createFunction: () -> Instance,
}

type PooledEffect = {
    instance: Instance,
    inUse: boolean,
    lastUsed: number,
}

-- ========================================
-- CONSTANTS
-- ========================================

local DEFAULT_INITIAL_SIZE = 10
local DEFAULT_MAX_SIZE = 50
local DEFAULT_GROWTH_RATE = 5
local CLEANUP_INTERVAL = 30 -- seconds
local MAX_IDLE_TIME = 60 -- seconds

-- ========================================
-- INITIALIZATION
-- ========================================

function EffectPool.new(config: PoolConfig)
    local self = setmetatable({}, EffectPool)
    
    -- Configuration
    self._initialSize = config.initialSize or DEFAULT_INITIAL_SIZE
    self._maxSize = config.maxSize or DEFAULT_MAX_SIZE
    self._growthRate = config.growthRate or DEFAULT_GROWTH_RATE
    self._effectType = config.effectType
    self._createFunction = config.createFunction
    
    -- Pool state
    self._pool = {}
    self._activeEffects = {}
    self._totalCreated = 0
    
    -- Statistics
    self._stats = {
        totalRequests = 0,
        poolHits = 0,
        poolMisses = 0,
        currentPoolSize = 0,
        activeEffects = 0,
    }
    
    -- Initialize pool
    self:InitializePool()
    
    -- Start cleanup routine
    self:StartCleanupRoutine()
    
    return self
end

-- ========================================
-- POOL MANAGEMENT
-- ========================================

function EffectPool:InitializePool()
    for i = 1, self._initialSize do
        local effect = self:CreatePooledEffect()
        table.insert(self._pool, effect)
    end
    self._stats.currentPoolSize = self._initialSize
end

function EffectPool:CreatePooledEffect(): PooledEffect
    local instance = self._createFunction()
    instance.Parent = nil -- Keep out of workspace until needed
    
    self._totalCreated = self._totalCreated + 1
    
    return {
        instance = instance,
        inUse = false,
        lastUsed = tick(),
    }
end

function EffectPool:GetEffect(): Instance?
    self._stats.totalRequests = self._stats.totalRequests + 1
    
    -- Look for available effect in pool
    for i, effect in ipairs(self._pool) do
        if not effect.inUse then
            effect.inUse = true
            effect.lastUsed = tick()
            self._stats.poolHits = self._stats.poolHits + 1
            self._stats.activeEffects = self._stats.activeEffects + 1
            self._activeEffects[effect.instance] = effect
            return effect.instance
        end
    end
    
    -- No available effects, try to grow pool
    self._stats.poolMisses = self._stats.poolMisses + 1
    
    if #self._pool < self._maxSize then
        -- Grow the pool
        local growthAmount = math.min(self._growthRate, self._maxSize - #self._pool)
        
        for i = 1, growthAmount do
            local effect = self:CreatePooledEffect()
            table.insert(self._pool, effect)
        end
        
        self._stats.currentPoolSize = #self._pool
        
        -- Try again after growing
        return self:GetEffect()
    end
    
    -- Pool is at max size, create temporary effect
    warn("[EffectPool] Pool exhausted for", self._effectType, "- creating temporary effect")
    return self._createFunction()
end

function EffectPool:ReturnEffect(instance: Instance)
    local effect = self._activeEffects[instance]
    
    if not effect then
        -- Not a pooled effect, just destroy it
        instance:Destroy()
        return
    end
    
    -- Reset the effect for reuse
    self:ResetEffect(instance)
    
    -- Mark as available
    effect.inUse = false
    effect.lastUsed = tick()
    self._activeEffects[instance] = nil
    self._stats.activeEffects = self._stats.activeEffects - 1
    
    -- Parent to nil to remove from workspace
    instance.Parent = nil
end

function EffectPool:ResetEffect(instance: Instance)
    -- Reset common properties
    instance.Visible = true
    instance.Transparency = 0
    instance.Position = UDim2.new(0, 0, 0, 0)
    instance.Size = UDim2.new(1, 0, 1, 0)
    instance.Rotation = 0
    instance.ZIndex = 1
    
    -- Reset type-specific properties
    if instance:IsA("ImageLabel") then
        instance.ImageTransparency = 0
        instance.ImageColor3 = Color3.new(1, 1, 1)
    elseif instance:IsA("Frame") then
        instance.BackgroundTransparency = 0
        instance.BackgroundColor3 = Color3.new(1, 1, 1)
    end
    
    -- Clear all attributes
    for _, attribute in ipairs(instance:GetAttributes()) do
        instance:SetAttribute(attribute, nil)
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function EffectPool:StartCleanupRoutine()
    task.spawn(function()
        while true do
            task.wait(CLEANUP_INTERVAL)
            self:CleanupIdleEffects()
        end
    end)
end

function EffectPool:CleanupIdleEffects()
    local currentTime = tick()
    local removed = 0
    
    -- Only cleanup if we're above initial size
    if #self._pool <= self._initialSize then
        return
    end
    
    -- Remove idle effects
    for i = #self._pool, 1, -1 do
        local effect = self._pool[i]
        
        if not effect.inUse and (currentTime - effect.lastUsed) > MAX_IDLE_TIME then
            effect.instance:Destroy()
            table.remove(self._pool, i)
            removed = removed + 1
            
            -- Don't go below initial size
            if #self._pool <= self._initialSize then
                break
            end
        end
    end
    
    if removed > 0 then
        self._stats.currentPoolSize = #self._pool
        print(string.format("[EffectPool] Cleaned up %d idle %s effects", removed, self._effectType))
    end
end

-- ========================================
-- STATISTICS
-- ========================================

function EffectPool:GetStats()
    local hitRate = 0
    if self._stats.totalRequests > 0 then
        hitRate = (self._stats.poolHits / self._stats.totalRequests) * 100
    end
    
    return {
        effectType = self._effectType,
        poolSize = self._stats.currentPoolSize,
        activeEffects = self._stats.activeEffects,
        totalRequests = self._stats.totalRequests,
        hitRate = hitRate,
        totalCreated = self._totalCreated,
    }
end

function EffectPool:PrintStats()
    local stats = self:GetStats()
    print(string.format(
        "[EffectPool] %s | Pool: %d/%d | Active: %d | Hit Rate: %.1f%% | Total Created: %d",
        stats.effectType,
        stats.poolSize,
        self._maxSize,
        stats.activeEffects,
        stats.hitRate,
        stats.totalCreated
    ))
end

-- ========================================
-- CLEANUP
-- ========================================

function EffectPool:Destroy()
    -- Return all active effects
    for instance, effect in pairs(self._activeEffects) do
        effect.inUse = false
    end
    self._activeEffects = {}
    
    -- Destroy all pooled effects
    for _, effect in ipairs(self._pool) do
        effect.instance:Destroy()
    end
    self._pool = {}
    
    self._stats.currentPoolSize = 0
    self._stats.activeEffects = 0
end

return EffectPool