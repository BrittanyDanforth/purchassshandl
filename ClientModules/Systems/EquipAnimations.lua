--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - EQUIP ANIMATIONS MODULE                        ║
    ║                        Smooth AAA Quality Equip/Unequip Effects                       ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local EquipAnimations = {}
EquipAnimations.__index = EquipAnimations

-- ========================================
-- SERVICES
-- ========================================
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- ========================================
-- CONSTANTS
-- ========================================
local TWEEN_INFO = {
    Equip = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Unequip = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    Glow = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    Pulse = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
}

local COLORS = {
    EquipGlow = Color3.fromRGB(100, 255, 150),  -- Green glow
    UnequipGlow = Color3.fromRGB(255, 150, 100), -- Orange glow
    Success = Color3.fromRGB(50, 255, 100),
    Sparkle = Color3.fromRGB(255, 255, 200)
}

-- ========================================
-- INITIALIZATION
-- ========================================

function EquipAnimations.new(config)
    local self = setmetatable({}, EquipAnimations)
    
    self._config = config
    self._activeAnimations = {}
    
    return self
end

-- ========================================
-- EQUIP ANIMATION
-- ========================================

function EquipAnimations:PlayEquipAnimation(petCard, callback)
    -- Store original properties
    local originalSize = petCard.Size
    local originalPosition = petCard.Position
    
    -- Create glow frame behind card
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "EquipGlow"
    glowFrame.Size = petCard.Size
    glowFrame.Position = petCard.Position
    glowFrame.BackgroundColor3 = COLORS.EquipGlow
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = petCard.ZIndex - 1
    glowFrame.Parent = petCard.Parent
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 12)
    glowCorner.Parent = glowFrame
    
    -- Phase 1: Shrink and glow
    local shrinkTween = TweenService:Create(petCard, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(originalSize.X.Scale * 0.8, originalSize.X.Offset * 0.8, 
                        originalSize.Y.Scale * 0.8, originalSize.Y.Offset * 0.8)
    })
    
    local glowInTween = TweenService:Create(glowFrame, TweenInfo.new(0.2), {
        Size = UDim2.new(originalSize.X.Scale * 1.3, originalSize.X.Offset * 1.3,
                        originalSize.Y.Scale * 1.3, originalSize.Y.Offset * 1.3),
        BackgroundTransparency = 0.5
    })
    
    shrinkTween:Play()
    glowInTween:Play()
    
    -- Create sparkles
    self:CreateSparkles(petCard, COLORS.EquipGlow)
    
    -- Phase 2: Bounce back with checkmark
    shrinkTween.Completed:Connect(function()
        -- Add equipped indicator with animation
        local checkmark = Instance.new("ImageLabel")
        checkmark.Name = "EquippedIndicator"
        checkmark.Size = UDim2.new(0, 0, 0, 0)
        checkmark.Position = UDim2.new(1, -26, 0, 2)
        checkmark.BackgroundTransparency = 1
        checkmark.Image = "rbxassetid://7072717697"
        checkmark.ImageColor3 = self._config.COLORS.Success
        checkmark.ImageTransparency = 0
        checkmark.Parent = petCard
        
        -- Animate checkmark appearance
        TweenService:Create(checkmark, TWEEN_INFO.Equip, {
            Size = UDim2.new(0, 24, 0, 24)
        }):Play()
        
        -- Bounce card back
        local bounceTween = TweenService:Create(petCard, TWEEN_INFO.Equip, {
            Size = originalSize
        })
        
        bounceTween:Play()
        
        -- Fade out glow
        TweenService:Create(glowFrame, TweenInfo.new(0.5), {
            Size = originalSize,
            BackgroundTransparency = 1
        }):Play()
        
        -- Add success particles
        self:CreateSuccessParticles(petCard)
        
        -- Cleanup
        task.wait(0.5)
        glowFrame:Destroy()
        
        if callback then
            callback()
        end
    end)
end

-- ========================================
-- UNEQUIP ANIMATION
-- ========================================

function EquipAnimations:PlayUnequipAnimation(petCard, callback)
    -- Find equipped indicator
    local checkmark = petCard:FindFirstChild("EquippedIndicator")
    if not checkmark then
        if callback then callback() end
        return
    end
    
    -- Create unequip glow
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "UnequipGlow"
    glowFrame.Size = petCard.Size
    glowFrame.Position = petCard.Position
    glowFrame.BackgroundColor3 = COLORS.UnequipGlow
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = petCard.ZIndex - 1
    glowFrame.Parent = petCard.Parent
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 12)
    glowCorner.Parent = glowFrame
    
    -- Animate glow in
    TweenService:Create(glowFrame, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.7
    }):Play()
    
    -- Animate checkmark disappearing
    local checkmarkTween = TweenService:Create(checkmark, TWEEN_INFO.Unequip, {
        Size = UDim2.new(0, 0, 0, 0),
        ImageTransparency = 1,
        Rotation = 180
    })
    
    -- Add wobble to card
    local wobbleTween = TweenService:Create(petCard, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true), {
        Rotation = 5
    })
    
    wobbleTween:Play()
    checkmarkTween:Play()
    
    -- Create dust particles
    self:CreateDustParticles(petCard)
    
    checkmarkTween.Completed:Connect(function()
        checkmark:Destroy()
        
        -- Reset rotation
        TweenService:Create(petCard, TweenInfo.new(0.2), {
            Rotation = 0
        }):Play()
        
        -- Fade out glow
        TweenService:Create(glowFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        }):Play()
        
        task.wait(0.3)
        glowFrame:Destroy()
        
        if callback then
            callback()
        end
    end)
end

-- ========================================
-- PARTICLE EFFECTS
-- ========================================

function EquipAnimations:CreateSparkles(parent, color)
    for i = 1, 15 do
        task.spawn(function()
            local sparkle = Instance.new("Frame")
            sparkle.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))
            sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
            sparkle.BackgroundColor3 = color
            sparkle.BorderSizePixel = 0
            sparkle.ZIndex = parent.ZIndex + 10
            sparkle.Parent = parent
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = sparkle
            
            -- Animate sparkle
            local riseTween = TweenService:Create(sparkle, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(sparkle.Position.X.Scale, 0, sparkle.Position.Y.Scale - 0.3, 0),
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            })
            
            riseTween:Play()
            
            -- Rotate sparkle
            local rotateTween = TweenService:Create(sparkle, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
                Rotation = math.random(180, 360)
            })
            rotateTween:Play()
            
            Debris:AddItem(sparkle, 0.8)
        end)
    end
end

function EquipAnimations:CreateSuccessParticles(parent)
    -- Create star burst effect
    local burst = Instance.new("ImageLabel")
    burst.Size = UDim2.new(0, 60, 0, 60)
    burst.Position = UDim2.new(0.5, -30, 0.5, -30)
    burst.BackgroundTransparency = 1
    burst.Image = "rbxassetid://7151272237" -- Star image
    burst.ImageColor3 = COLORS.Success
    burst.ImageTransparency = 0.5
    burst.ZIndex = parent.ZIndex + 20
    burst.Parent = parent
    
    -- Animate burst
    TweenService:Create(burst, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 120, 0, 120),
        Position = UDim2.new(0.5, -60, 0.5, -60),
        ImageTransparency = 1,
        Rotation = 180
    }):Play()
    
    Debris:AddItem(burst, 0.5)
end

function EquipAnimations:CreateDustParticles(parent)
    for i = 1, 10 do
        task.spawn(function()
            local dust = Instance.new("Frame")
            dust.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
            dust.Position = UDim2.new(0.5, math.random(-20, 20), 1, 0)
            dust.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            dust.BackgroundTransparency = 0.5
            dust.BorderSizePixel = 0
            dust.ZIndex = parent.ZIndex + 5
            dust.Parent = parent
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = dust
            
            -- Animate dust falling
            local fallTween = TweenService:Create(dust, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(dust.Position.X.Scale, dust.Position.X.Offset + math.random(-10, 10), 1, 20),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 0)
            })
            
            fallTween:Play()
            Debris:AddItem(dust, 0.6)
        end)
    end
end

-- ========================================
-- STATE SYNC
-- ========================================

function EquipAnimations:UpdateEquippedIndicator(petCard, isEquipped, instant)
    if instant then
        -- Instant update without animation
        local indicator = petCard:FindFirstChild("EquippedIndicator")
        
        if isEquipped and not indicator then
            indicator = Instance.new("ImageLabel")
            indicator.Name = "EquippedIndicator"
            indicator.Size = UDim2.new(0, 24, 0, 24)
            indicator.Position = UDim2.new(1, -26, 0, 2)
            indicator.BackgroundTransparency = 1
            indicator.Image = "rbxassetid://7072717697"
            indicator.ImageColor3 = self._config.COLORS.Success
            indicator.Parent = petCard
        elseif not isEquipped and indicator then
            indicator:Destroy()
        end
    else
        -- Animated update
        if isEquipped then
            self:PlayEquipAnimation(petCard)
        else
            self:PlayUnequipAnimation(petCard)
        end
    end
end

-- ========================================
-- PULSE ANIMATION
-- ========================================

function EquipAnimations:AddEquippedPulse(petCard)
    local indicator = petCard:FindFirstChild("EquippedIndicator")
    if not indicator then return end
    
    -- Create pulse effect
    local pulseTween = TweenService:Create(indicator, TWEEN_INFO.Glow, {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -28, 0, 0)
    })
    
    pulseTween:Play()
    self._activeAnimations[petCard] = pulseTween
end

function EquipAnimations:RemoveEquippedPulse(petCard)
    local tween = self._activeAnimations[petCard]
    if tween then
        tween:Cancel()
        self._activeAnimations[petCard] = nil
        
        local indicator = petCard:FindFirstChild("EquippedIndicator")
        if indicator then
            TweenService:Create(indicator, TweenInfo.new(0.2), {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(1, -26, 0, 2)
            }):Play()
        end
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function EquipAnimations:Destroy()
    for _, tween in pairs(self._activeAnimations) do
        if tween then
            tween:Cancel()
        end
    end
    
    self._activeAnimations = {}
end

return EquipAnimations