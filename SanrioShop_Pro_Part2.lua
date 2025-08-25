-- SANRIO SHOP PROFESSIONAL - Part 2: Utility Functions
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local Part1 = require(script.Parent.SanrioShop_Pro_Part1)
local CONFIG = Part1.CONFIG
local ASSETS = Part1.ASSETS

-- Sound Manager
local SoundManager = {}
SoundManager.sounds = {}

function SoundManager:play(soundName, volume, pitch)
    local soundId = ASSETS[soundName]
    if not soundId then return end
    
    local sound = SoundManager.sounds[soundName]
    if not sound then
        sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.5
        sound.Pitch = pitch or 1
        sound.Parent = SoundService
        SoundManager.sounds[soundName] = sound
    end
    
    sound:Play()
end

-- Utility Functions
local function tween(instance, properties, duration, style, direction)
    duration = duration or CONFIG.TWEEN_TIME
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function formatNumber(n)
    if n >= 1e6 then
        return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    else
        return tostring(n)
    end
end

local function createUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or CONFIG.CORNER_RADIUS)
    corner.Parent = parent
    return corner
end

local function createUIStroke(parent, thickness, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 2
    stroke.Color = color or CONFIG.SHADOW_COLOR
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

local function createUIGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = colors or ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 230, 230))
    }
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

local function createUIPadding(parent, padding)
    local uiPadding = Instance.new("UIPadding")
    local p = padding or CONFIG.PADDING
    uiPadding.PaddingTop = UDim.new(0, p)
    uiPadding.PaddingBottom = UDim.new(0, p)
    uiPadding.PaddingLeft = UDim.new(0, p)
    uiPadding.PaddingRight = UDim.new(0, p)
    uiPadding.Parent = parent
    return uiPadding
end

-- Ownership cache
local ownershipCache = {}
local cacheExpiry = {}

local function userOwnsGamepass(passId)
    local now = tick()
    
    if ownershipCache[passId] and cacheExpiry[passId] and cacheExpiry[passId] > now then
        return ownershipCache[passId]
    end
    
    if RunService:IsStudio() then
        if _G.StudioGamepassPurchases and _G.StudioGamepassPurchases[passId] then
            ownershipCache[passId] = true
            cacheExpiry[passId] = now + 300
            return true
        end
    end
    
    local success, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, passId)
    end)
    
    if success then
        ownershipCache[passId] = owns
        cacheExpiry[passId] = now + 300
        return owns
    end
    
    return false
end

local function clearOwnershipCache(passId)
    ownershipCache[passId] = nil
    cacheExpiry[passId] = nil
end

-- Preload assets
local function preloadAssets()
    local assets = {}
    for _, id in pairs(ASSETS) do
        table.insert(assets, {id = id, type = "Sound"})
    end
    ContentProvider:PreloadAsync(assets)
end

return {
    SoundManager = SoundManager,
    tween = tween,
    formatNumber = formatNumber,
    createUICorner = createUICorner,
    createUIStroke = createUIStroke,
    createUIGradient = createUIGradient,
    createUIPadding = createUIPadding,
    userOwnsGamepass = userOwnsGamepass,
    clearOwnershipCache = clearOwnershipCache,
    preloadAssets = preloadAssets
}