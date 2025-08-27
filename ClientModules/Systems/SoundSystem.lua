--[[
    Module: SoundSystem
    Description: Advanced sound management with caching, pooling, 3D audio, and volume control
    Based on original PlaySound functionality with major enhancements
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local SoundSystem = {}
SoundSystem.__index = SoundSystem

-- ========================================
-- TYPES
-- ========================================

type SoundInstance = {
    sound: Sound,
    inUse: boolean,
    lastUsed: number,
    playCount: number,
}

type SoundOptions = {
    volume: number?,
    pitch: number?,
    position: Vector3?,
    parent: Instance?,
    looped: boolean?,
    priority: number?,
    fadeIn: number?,
    fadeOut: number?,
}

type MusicTrack = {
    soundId: string,
    name: string,
    volume: number,
    category: string,
}

-- ========================================
-- CONSTANTS
-- ========================================

local MAX_POOL_SIZE = 20
local CLEANUP_INTERVAL = 30
local PRELOAD_BATCH_SIZE = 10
local FADE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
local DEFAULT_VOLUME = 0.5
local SPATIAL_ROLLOFF_MAX = 50

-- Sound categories for volume control
local SOUND_CATEGORIES = {
    UI = "UI",
    MUSIC = "Music",
    SFX = "SFX",
    AMBIENT = "Ambient",
    VOICE = "Voice",
}

-- ========================================
-- INITIALIZATION
-- ========================================

function SoundSystem.new(dependencies)
    local self = setmetatable({}, SoundSystem)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    self._dataCache = dependencies.DataCache
    self._eventBus = dependencies.EventBus
    self._services = dependencies.Services or Services
    
    -- Sound storage
    self._soundCache = {} -- soundId -> Sound instance
    self._soundPool = {} -- soundId -> {SoundInstance}
    self._failedSounds = {} -- Track failed sounds
    self._activeMusic = {} -- category -> Sound
    
    -- Volume settings
    self._masterVolume = 1
    self._categoryVolumes = {
        [SOUND_CATEGORIES.UI] = 1,
        [SOUND_CATEGORIES.MUSIC] = 0.5,
        [SOUND_CATEGORIES.SFX] = 1,
        [SOUND_CATEGORIES.AMBIENT] = 0.3,
        [SOUND_CATEGORIES.VOICE] = 1,
    }
    
    -- 3D audio settings
    self._listenerPart = nil
    self._3dSounds = {} -- Sound -> true for 3D sounds
    
    -- Music system
    self._musicQueue = {}
    self._currentMusic = nil
    self._musicFading = false
    
    -- Performance
    self._totalSoundsPlayed = 0
    self._cacheHits = 0
    self._cacheMisses = 0
    
    -- Settings
    self._enabled = true
    self._debugMode = self._config.DEBUG.ENABLED
    
    self:Initialize()
    
    return self
end

function SoundSystem:Initialize()
    -- Load settings from DataCache
    if self._dataCache then
        local settings = self._dataCache:GetSettings()
        if settings then
            self._masterVolume = settings.sfxVolume or DEFAULT_VOLUME
            self._categoryVolumes[SOUND_CATEGORIES.MUSIC] = settings.musicVolume or DEFAULT_VOLUME
            self._enabled = settings.sfxEnabled ~= false
        end
    end
    
    -- Set up 3D listener
    self:SetupListener()
    
    -- Start cleanup task
    self:StartCleanupTask()
    
    -- Listen for setting changes
    if self._dataCache then
        self._dataCache:OnDataChanged("settings", function(settings)
            self:UpdateSettings(settings)
        end)
    end
    
    -- Preload common sounds
    self:PreloadSounds()
    
    if self._debugMode then
        print("[SoundSystem] Initialized with master volume:", self._masterVolume)
    end
end

-- ========================================
-- MAIN SOUND PLAYBACK
-- ========================================

function SoundSystem:PlaySound(soundId: string, options: SoundOptions?): Sound?
    if not self._enabled or not soundId then
        return nil
    end
    
    options = options or {}
    
    -- Check if sound has failed before
    if self._failedSounds[soundId] then
        -- Try fallback sound if available
        local fallback = self:GetFallbackSound(soundId)
        if fallback then
            soundId = fallback
        else
            return nil
        end
    end
    
    -- Get or create sound
    local sound = self:GetPooledSound(soundId) or self:CreateSound(soundId)
    if not sound then
        return nil
    end
    
    -- Apply options
    self:ApplyOptions(sound, options)
    
    -- Determine category
    local category = self:DetermineCategory(soundId, options)
    
    -- Apply volume
    local finalVolume = (options.volume or DEFAULT_VOLUME) * 
                       self._categoryVolumes[category] * 
                       self._masterVolume
    
    sound.Volume = math.clamp(finalVolume, 0, 1)
    
    -- Handle 3D positioning
    if options.position then
        self:Setup3DSound(sound, options.position, options.parent)
    end
    
    -- Handle fade in
    if options.fadeIn and options.fadeIn > 0 then
        sound.Volume = 0
        sound:Play()
        self._services.TweenService:Create(
            sound,
            TweenInfo.new(options.fadeIn, Enum.EasingStyle.Linear),
            {Volume = finalVolume}
        ):Play()
    else
        sound:Play()
    end
    
    -- Track statistics
    self._totalSoundsPlayed = self._totalSoundsPlayed + 1
    
    -- Handle cleanup for one-shot sounds
    if not options.looped then
        sound.Ended:Connect(function()
            self:ReturnToPool(soundId, sound)
        end)
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("SoundPlayed", {
            soundId = soundId,
            category = category,
            volume = finalVolume,
        })
    end
    
    return sound
end

function SoundSystem:PlaySoundAtPosition(soundId: string, position: Vector3, options: SoundOptions?): Sound?
    options = options or {}
    options.position = position
    return self:PlaySound(soundId, options)
end

function SoundSystem:PlayUISound(soundName: string): Sound?
    local soundId = self._config.SOUNDS[soundName]
    if not soundId then
        warn("[SoundSystem] UI sound not found:", soundName)
        return nil
    end
    
    return self:PlaySound(soundId, {
        volume = 1,
        priority = 1,
    })
end

-- ========================================
-- MUSIC SYSTEM
-- ========================================

function SoundSystem:PlayMusic(soundId: string, category: string?, fadeTime: number?): Sound?
    category = category or SOUND_CATEGORIES.MUSIC
    fadeTime = fadeTime or 1
    
    -- Stop current music in category
    local currentMusic = self._activeMusic[category]
    if currentMusic then
        self:StopMusic(category, fadeTime)
        
        -- Wait for fade to complete
        task.wait(fadeTime)
    end
    
    -- Create music sound
    local music = self:CreateSound(soundId)
    if not music then
        return nil
    end
    
    music.Looped = true
    music.Volume = 0
    
    -- Apply category volume
    local targetVolume = self._categoryVolumes[category] * self._masterVolume
    
    -- Store as active music
    self._activeMusic[category] = music
    
    -- Play with fade in
    music:Play()
    self._services.TweenService:Create(
        music,
        TweenInfo.new(fadeTime, Enum.EasingStyle.Linear),
        {Volume = targetVolume}
    ):Play()
    
    return music
end

function SoundSystem:StopMusic(category: string?, fadeTime: number?)
    category = category or SOUND_CATEGORIES.MUSIC
    fadeTime = fadeTime or 1
    
    local music = self._activeMusic[category]
    if not music then
        return
    end
    
    -- Fade out
    local tween = self._services.TweenService:Create(
        music,
        TweenInfo.new(fadeTime, Enum.EasingStyle.Linear),
        {Volume = 0}
    )
    
    tween:Play()
    tween.Completed:Connect(function()
        music:Stop()
        music:Destroy()
        self._activeMusic[category] = nil
    end)
end

function SoundSystem:CrossfadeMusic(newSoundId: string, category: string?, fadeTime: number?)
    category = category or SOUND_CATEGORIES.MUSIC
    fadeTime = fadeTime or 2
    
    local currentMusic = self._activeMusic[category]
    
    -- Start new music at 0 volume
    local newMusic = self:CreateSound(newSoundId)
    if not newMusic then
        return nil
    end
    
    newMusic.Looped = true
    newMusic.Volume = 0
    newMusic:Play()
    
    local targetVolume = self._categoryVolumes[category] * self._masterVolume
    
    -- Crossfade
    if currentMusic then
        -- Fade out old
        self._services.TweenService:Create(
            currentMusic,
            TweenInfo.new(fadeTime, Enum.EasingStyle.Linear),
            {Volume = 0}
        ):Play()
        
        task.delay(fadeTime, function()
            currentMusic:Stop()
            currentMusic:Destroy()
        end)
    end
    
    -- Fade in new
    self._services.TweenService:Create(
        newMusic,
        TweenInfo.new(fadeTime, Enum.EasingStyle.Linear),
        {Volume = targetVolume}
    ):Play()
    
    self._activeMusic[category] = newMusic
    
    return newMusic
end

-- ========================================
-- SOUND MANAGEMENT
-- ========================================

function SoundSystem:CreateSound(soundId: string): Sound?
    -- Check cache first
    local cached = self._soundCache[soundId]
    if cached and cached.Parent then
        self._cacheHits = self._cacheHits + 1
        return cached:Clone()
    end
    
    self._cacheMisses = self._cacheMisses + 1
    
    -- Create new sound
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = DEFAULT_VOLUME
    sound.Parent = self._services.SoundService
    
    -- Preload with error handling
    local success = pcall(function()
        self._services.ContentProvider:PreloadAsync({sound})
    end)
    
    if success and sound.IsLoaded then
        -- Cache the template
        self._soundCache[soundId] = sound:Clone()
        self._soundCache[soundId].Parent = nil -- Don't parent the template
        
        return sound
    else
        -- Mark as failed
        self._failedSounds[soundId] = true
        sound:Destroy()
        
        if self._debugMode then
            warn("[SoundSystem] Failed to load sound:", soundId)
        end
        
        return nil
    end
end

function SoundSystem:GetPooledSound(soundId: string): Sound?
    local pool = self._soundPool[soundId]
    if not pool then
        return nil
    end
    
    -- Find available sound
    for _, instance in ipairs(pool) do
        if not instance.inUse then
            instance.inUse = true
            instance.lastUsed = tick()
            instance.playCount = instance.playCount + 1
            return instance.sound
        end
    end
    
    -- Pool is full, create new if under limit
    if #pool < MAX_POOL_SIZE then
        local sound = self:CreateSound(soundId)
        if sound then
            local instance = {
                sound = sound,
                inUse = true,
                lastUsed = tick(),
                playCount = 1,
            }
            table.insert(pool, instance)
            return sound
        end
    end
    
    return nil
end

function SoundSystem:ReturnToPool(soundId: string, sound: Sound)
    local pool = self._soundPool[soundId]
    if not pool then
        self._soundPool[soundId] = {}
        pool = self._soundPool[soundId]
    end
    
    -- Find the instance
    for _, instance in ipairs(pool) do
        if instance.sound == sound then
            instance.inUse = false
            instance.lastUsed = tick()
            
            -- Reset sound properties
            sound.Volume = DEFAULT_VOLUME
            sound.Pitch = 1
            sound.TimePosition = 0
            
            -- Remove from 3D sounds
            self._3dSounds[sound] = nil
            
            return
        end
    end
    
    -- Not in pool, add it if space
    if #pool < MAX_POOL_SIZE then
        table.insert(pool, {
            sound = sound,
            inUse = false,
            lastUsed = tick(),
            playCount = 1,
        })
    else
        -- Pool full, destroy
        sound:Destroy()
    end
end

-- ========================================
-- 3D AUDIO
-- ========================================

function SoundSystem:SetupListener()
    -- Use camera as listener by default
    local camera = self._services.Workspace.CurrentCamera
    if camera then
        self._listenerPart = camera
    end
    
    -- Update listener when camera changes
    self._services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        local newCamera = self._services.Workspace.CurrentCamera
        if newCamera then
            self._listenerPart = newCamera
        end
    end)
end

function SoundSystem:Setup3DSound(sound: Sound, position: Vector3, parent: Instance?)
    -- Create attachment for 3D positioning
    local part = parent
    
    if not part then
        part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Transparency = 1
        part.Position = position
        part.Size = Vector3.new(1, 1, 1)
        part.Parent = self._services.Workspace
        
        -- Clean up part when sound ends
        sound.Ended:Connect(function()
            part:Destroy()
        end)
    end
    
    -- Configure 3D properties
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMaxDistance = SPATIAL_ROLLOFF_MAX
    sound.RollOffMinDistance = 5
    sound.EmitterSize = 10
    
    -- Parent sound to part
    sound.Parent = part
    
    -- Track as 3D sound
    self._3dSounds[sound] = true
end

function SoundSystem:SetListenerPosition(position: Vector3)
    -- This would be used for custom listener positioning
    -- Currently using camera as listener
end

-- ========================================
-- VOLUME CONTROL
-- ========================================

function SoundSystem:SetMasterVolume(volume: number)
    self._masterVolume = math.clamp(volume, 0, 1)
    self:UpdateAllVolumes()
end

function SoundSystem:SetCategoryVolume(category: string, volume: number)
    self._categoryVolumes[category] = math.clamp(volume, 0, 1)
    self:UpdateCategoryVolumes(category)
end

function SoundSystem:GetMasterVolume(): number
    return self._masterVolume
end

function SoundSystem:GetCategoryVolume(category: string): number
    return self._categoryVolumes[category] or 1
end

function SoundSystem:UpdateAllVolumes()
    -- Update all active sounds
    for category, music in pairs(self._activeMusic) do
        if music and music.Parent then
            music.Volume = self._categoryVolumes[category] * self._masterVolume
        end
    end
    
    -- Update pooled sounds
    for _, pool in pairs(self._soundPool) do
        for _, instance in ipairs(pool) do
            if instance.inUse and instance.sound.Parent then
                -- Recalculate volume based on original
                local category = self:DetermineCategory(instance.sound.SoundId)
                instance.sound.Volume = instance.sound.Volume * self._masterVolume
            end
        end
    end
end

function SoundSystem:UpdateCategoryVolumes(category: string)
    -- Update music
    local music = self._activeMusic[category]
    if music and music.Parent then
        music.Volume = self._categoryVolumes[category] * self._masterVolume
    end
    
    -- Would need to track category per sound for full implementation
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function SoundSystem:DetermineCategory(soundId: string, options: SoundOptions?): string
    -- Check if it's a known UI sound
    for name, id in pairs(self._config.SOUNDS) do
        if id == soundId then
            if name:match("Click") or name:match("Open") or name:match("Close") then
                return SOUND_CATEGORIES.UI
            end
        end
    end
    
    -- Check options
    if options and options.priority and options.priority > 5 then
        return SOUND_CATEGORIES.UI
    end
    
    -- Default to SFX
    return SOUND_CATEGORIES.SFX
end

function SoundSystem:GetFallbackSound(soundId: string): string?
    -- Map of failed sounds to fallbacks
    local fallbacks = {
        [self._config.SOUNDS.Click] = "rbxasset://sounds/clickfast.wav",
        [self._config.SOUNDS.Error] = "rbxasset://sounds/error.wav",
        [self._config.SOUNDS.Success] = "rbxasset://sounds/victory.wav",
    }
    
    return fallbacks[soundId]
end

function SoundSystem:ApplyOptions(sound: Sound, options: SoundOptions)
    if options.pitch then
        sound.Pitch = math.clamp(options.pitch, 0.5, 2)
    end
    
    if options.looped ~= nil then
        sound.Looped = options.looped
    end
    
    if options.priority then
        -- Roblox doesn't have priority, but we can simulate with volume
        -- Higher priority = slightly louder
        sound.Volume = sound.Volume * (1 + (options.priority - 1) * 0.1)
    end
end

function SoundSystem:PreloadSounds()
    -- Preload common UI sounds
    local toPreload = {}
    
    for name, soundId in pairs(self._config.SOUNDS) do
        table.insert(toPreload, soundId)
    end
    
    -- Batch preload
    for i = 1, #toPreload, PRELOAD_BATCH_SIZE do
        local batch = {}
        
        for j = i, math.min(i + PRELOAD_BATCH_SIZE - 1, #toPreload) do
            local sound = self:CreateSound(toPreload[j])
            if sound then
                sound:Destroy() -- Just preloading, not keeping
            end
        end
        
        task.wait() -- Yield between batches
    end
end

function SoundSystem:UpdateSettings(settings: Types.SettingsData)
    self._masterVolume = settings.sfxVolume or DEFAULT_VOLUME
    self._categoryVolumes[SOUND_CATEGORIES.MUSIC] = settings.musicVolume or DEFAULT_VOLUME
    self._enabled = settings.sfxEnabled ~= false
    
    self:UpdateAllVolumes()
end

-- ========================================
-- CLEANUP
-- ========================================

function SoundSystem:StartCleanupTask()
    task.spawn(function()
        while true do
            task.wait(CLEANUP_INTERVAL)
            self:CleanupUnusedSounds()
        end
    end)
end

function SoundSystem:CleanupUnusedSounds()
    local now = tick()
    local cleaned = 0
    
    for soundId, pool in pairs(self._soundPool) do
        for i = #pool, 1, -1 do
            local instance = pool[i]
            
            -- Remove sounds unused for over a minute
            if not instance.inUse and (now - instance.lastUsed) > 60 then
                instance.sound:Destroy()
                table.remove(pool, i)
                cleaned = cleaned + 1
            end
        end
        
        -- Remove empty pools
        if #pool == 0 then
            self._soundPool[soundId] = nil
        end
    end
    
    if self._debugMode and cleaned > 0 then
        print("[SoundSystem] Cleaned up", cleaned, "unused sounds")
    end
end

-- ========================================
-- DEBUGGING
-- ========================================

function SoundSystem:GetStats(): table
    local pooledCount = 0
    local activeCount = 0
    
    for _, pool in pairs(self._soundPool) do
        for _, instance in ipairs(pool) do
            pooledCount = pooledCount + 1
            if instance.inUse then
                activeCount = activeCount + 1
            end
        end
    end
    
    return {
        totalPlayed = self._totalSoundsPlayed,
        cacheHits = self._cacheHits,
        cacheMisses = self._cacheMisses,
        cacheHitRate = self._cacheHits / math.max(1, self._cacheHits + self._cacheMisses),
        pooledSounds = pooledCount,
        activeSounds = activeCount,
        failedSounds = self._utilities:CountTable(self._failedSounds),
    }
end

if Config.DEBUG.ENABLED then
    function SoundSystem:DebugPrint()
        print("\n=== SoundSystem Debug Info ===")
        
        local stats = self:GetStats()
        print("Total Played:", stats.totalPlayed)
        print("Cache Hit Rate:", string.format("%.1f%%", stats.cacheHitRate * 100))
        print("Pooled Sounds:", stats.pooledSounds)
        print("Active Sounds:", stats.activeSounds)
        print("Failed Sounds:", stats.failedSounds)
        
        print("\nVolumes:")
        print("  Master:", self._masterVolume)
        for category, volume in pairs(self._categoryVolumes) do
            print("  " .. category .. ":", volume)
        end
        
        print("=============================\n")
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function SoundSystem:StopAllSounds()
    -- Stop all music
    for category, music in pairs(self._activeMusic) do
        self:StopMusic(category, 0)
    end
    
    -- Stop all pooled sounds
    for _, pool in pairs(self._soundPool) do
        for _, instance in ipairs(pool) do
            if instance.sound.IsPlaying then
                instance.sound:Stop()
            end
        end
    end
end

function SoundSystem:Mute(muted: boolean)
    self._enabled = not muted
    
    if muted then
        self:StopAllSounds()
    end
end

function SoundSystem:Destroy()
    -- Stop all sounds
    self:StopAllSounds()
    
    -- Destroy all pooled sounds
    for _, pool in pairs(self._soundPool) do
        for _, instance in ipairs(pool) do
            instance.sound:Destroy()
        end
    end
    
    -- Clear caches
    self._soundCache = {}
    self._soundPool = {}
    self._failedSounds = {}
    self._activeMusic = {}
    self._3dSounds = {}
end

return SoundSystem