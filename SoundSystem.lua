--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                     SANRIO TYCOON - ADVANCED SOUND SYSTEM                            ║
    ║                    Professional sound management with categories                      ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local SoundSystem = {}
SoundSystem.__index = SoundSystem

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- ========================================
-- SOUND DEFINITIONS
-- ========================================
local SOUNDS = {
    -- UI Sounds
    UI = {
        Click = {id = "rbxassetid://876939830", volume = 0.3, pitch = 1.2},
        Hover = {id = "rbxassetid://10066936758", volume = 0.2, pitch = 1.5},
        Open = {id = "rbxassetid://9113651994", volume = 0.4, pitch = 1},
        Close = {id = "rbxassetid://9113651870", volume = 0.4, pitch = 0.9},
        Tab = {id = "rbxassetid://10066936943", volume = 0.3, pitch = 1.1},
        Error = {id = "rbxassetid://6895079853", volume = 0.5, pitch = 0.8},
        Success = {id = "rbxassetid://9043665007", volume = 0.5, pitch = 1},
    },
    
    -- Pet Sounds
    Pet = {
        Hatch = {id = "rbxassetid://9113880610", volume = 0.6, pitch = 1},
        Equip = {id = "rbxassetid://9126213752", volume = 0.4, pitch = 1.1},
        Unequip = {id = "rbxassetid://9126213686", volume = 0.4, pitch = 0.9},
        LevelUp = {id = "rbxassetid://9044545570", volume = 0.7, pitch = 1},
        Evolve = {id = "rbxassetid://9113143350", volume = 0.8, pitch = 1},
        Fuse = {id = "rbxassetid://9113882003", volume = 0.6, pitch = 1.2},
        Sell = {id = "rbxassetid://9119726485", volume = 0.4, pitch = 0.8},
    },
    
    -- Case/Egg Sounds
    Case = {
        Spin = {id = "rbxassetid://9113658186", volume = 0.5, pitch = 1, looped = true},
        SlowDown = {id = "rbxassetid://9113657918", volume = 0.5, pitch = 0.8},
        Stop = {id = "rbxassetid://9044540002", volume = 0.6, pitch = 1},
        RareHatch = {id = "rbxassetid://9125367501", volume = 0.8, pitch = 1.2},
        EpicHatch = {id = "rbxassetid://9125367333", volume = 0.9, pitch = 1.1},
        LegendaryHatch = {id = "rbxassetid://9125367154", volume = 1, pitch = 1},
        MythicalHatch = {id = "rbxassetid://9125366918", volume = 1, pitch = 0.9},
    },
    
    -- Currency/Reward Sounds
    Currency = {
        CoinCollect = {id = "rbxassetid://131961136", volume = 0.3, pitch = 1.3},
        GemCollect = {id = "rbxassetid://9125538073", volume = 0.4, pitch = 1.5},
        Purchase = {id = "rbxassetid://9113660731", volume = 0.5, pitch = 1},
        Reward = {id = "rbxassetid://9043693935", volume = 0.6, pitch = 1.1},
        Jackpot = {id = "rbxassetid://9113142469", volume = 0.8, pitch = 1},
    },
    
    -- Battle Sounds
    Battle = {
        Start = {id = "rbxassetid://9112859193", volume = 0.6, pitch = 1},
        Hit = {id = "rbxassetid://9116827458", volume = 0.4, pitch = 1},
        Crit = {id = "rbxassetid://9113882140", volume = 0.6, pitch = 0.8},
        Miss = {id = "rbxassetid://9116201881", volume = 0.3, pitch = 1.2},
        Heal = {id = "rbxassetid://9125404718", volume = 0.5, pitch = 1.1},
        Victory = {id = "rbxassetid://9043766241", volume = 0.7, pitch = 1},
        Defeat = {id = "rbxassetid://9043748002", volume = 0.5, pitch = 0.8},
    },
    
    -- Notification Sounds
    Notification = {
        Info = {id = "rbxassetid://9125503013", volume = 0.4, pitch = 1.2},
        Warning = {id = "rbxassetid://9113654613", volume = 0.5, pitch = 1},
        Error = {id = "rbxassetid://9113654377", volume = 0.6, pitch = 0.9},
        Success = {id = "rbxassetid://9043693935", volume = 0.5, pitch = 1.3},
        Achievement = {id = "rbxassetid://9043746373", volume = 0.8, pitch = 1},
    },
    
    -- Ambient/Music
    Ambient = {
        ShopMusic = {id = "rbxassetid://9046432921", volume = 0.2, pitch = 1, looped = true},
        BattleMusic = {id = "rbxassetid://9043816017", volume = 0.3, pitch = 1, looped = true},
        MenuMusic = {id = "rbxassetid://9042658349", volume = 0.15, pitch = 1, looped = true},
    }
}

-- ========================================
-- CONSTRUCTOR
-- ========================================
function SoundSystem.new()
    local self = setmetatable({}, SoundSystem)
    
    self.sounds = {}
    self.musicEnabled = true
    self.sfxEnabled = true
    self.masterVolume = 1
    self.currentMusic = nil
    
    -- Create sound groups
    self.sfxGroup = Instance.new("SoundGroup")
    self.sfxGroup.Name = "SFXGroup"
    self.sfxGroup.Volume = 1
    self.sfxGroup.Parent = SoundService
    
    self.musicGroup = Instance.new("SoundGroup")
    self.musicGroup.Name = "MusicGroup"
    self.musicGroup.Volume = 0.5
    self.musicGroup.Parent = SoundService
    
    -- Preload critical sounds
    self:PreloadSounds()
    
    return self
end

-- ========================================
-- SOUND LOADING
-- ========================================
function SoundSystem:PreloadSounds()
    local criticalSounds = {
        "UI.Click", "UI.Success", "Pet.Hatch", 
        "Case.Stop", "Currency.CoinCollect"
    }
    
    for _, soundPath in ipairs(criticalSounds) do
        local category, name = soundPath:match("(%w+)%.(%w+)")
        if category and name and SOUNDS[category] and SOUNDS[category][name] then
            self:GetSound(category, name)
        end
    end
end

function SoundSystem:GetSound(category, name)
    local key = category .. "." .. name
    
    if self.sounds[key] then
        return self.sounds[key]
    end
    
    local soundData = SOUNDS[category] and SOUNDS[category][name]
    if not soundData then
        warn("[SoundSystem] Sound not found:", key)
        return nil
    end
    
    local sound = Instance.new("Sound")
    sound.Name = key
    sound.SoundId = soundData.id
    sound.Volume = soundData.volume * self.masterVolume
    sound.Pitch = soundData.pitch or 1
    sound.Looped = soundData.looped or false
    
    -- Assign to appropriate group
    if category == "Ambient" then
        sound.SoundGroup = self.musicGroup
    else
        sound.SoundGroup = self.sfxGroup
    end
    
    sound.Parent = workspace
    
    self.sounds[key] = sound
    return sound
end

-- ========================================
-- PLAY FUNCTIONS
-- ========================================
function SoundSystem:Play(category, name, options)
    if category ~= "Ambient" and not self.sfxEnabled then return end
    if category == "Ambient" and not self.musicEnabled then return end
    
    local sound = self:GetSound(category, name)
    if not sound then return end
    
    options = options or {}
    
    -- Clone for one-shot sounds
    if not sound.Looped then
        sound = sound:Clone()
        sound.Parent = workspace
        
        -- Auto cleanup
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
    
    -- Apply options
    if options.volume then
        sound.Volume = sound.Volume * options.volume
    end
    if options.pitch then
        sound.PlaybackSpeed = options.pitch
    end
    if options.position then
        sound.Parent = options.position
    end
    
    sound:Play()
    
    return sound
end

function SoundSystem:PlayUI(soundName, options)
    return self:Play("UI", soundName, options)
end

function SoundSystem:PlayPet(soundName, options)
    return self:Play("Pet", soundName, options)
end

function SoundSystem:PlayCase(soundName, options)
    return self:Play("Case", soundName, options)
end

function SoundSystem:PlayCurrency(soundName, options)
    return self:Play("Currency", soundName, options)
end

function SoundSystem:PlayBattle(soundName, options)
    return self:Play("Battle", soundName, options)
end

function SoundSystem:PlayNotification(soundName, options)
    return self:Play("Notification", soundName, options)
end

-- ========================================
-- MUSIC FUNCTIONS
-- ========================================
function SoundSystem:PlayMusic(musicName, fadeIn)
    if not self.musicEnabled then return end
    
    -- Stop current music
    if self.currentMusic then
        if fadeIn then
            self:FadeOut(self.currentMusic, 1, function()
                self.currentMusic:Stop()
            end)
        else
            self.currentMusic:Stop()
        end
    end
    
    -- Play new music
    local music = self:GetSound("Ambient", musicName)
    if not music then return end
    
    self.currentMusic = music
    
    if fadeIn then
        music.Volume = 0
        music:Play()
        self:FadeIn(music, 2, SOUNDS.Ambient[musicName].volume * self.masterVolume)
    else
        music:Play()
    end
end

function SoundSystem:StopMusic(fadeOut)
    if not self.currentMusic then return end
    
    if fadeOut then
        self:FadeOut(self.currentMusic, 2, function()
            self.currentMusic:Stop()
            self.currentMusic = nil
        end)
    else
        self.currentMusic:Stop()
        self.currentMusic = nil
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
function SoundSystem:FadeIn(sound, duration, targetVolume)
    local tween = TweenService:Create(
        sound,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = targetVolume}
    )
    tween:Play()
    return tween
end

function SoundSystem:FadeOut(sound, duration, callback)
    local tween = TweenService:Create(
        sound,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = 0}
    )
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

function SoundSystem:SetMasterVolume(volume)
    self.masterVolume = math.clamp(volume, 0, 1)
    self.sfxGroup.Volume = self.masterVolume
    self.musicGroup.Volume = self.masterVolume * 0.5
end

function SoundSystem:SetMusicEnabled(enabled)
    self.musicEnabled = enabled
    if not enabled and self.currentMusic then
        self:StopMusic(true)
    end
end

function SoundSystem:SetSFXEnabled(enabled)
    self.sfxEnabled = enabled
end

-- ========================================
-- SPECIAL EFFECTS
-- ========================================
function SoundSystem:PlayRaritySound(rarity)
    local rarityMap = {
        [1] = nil, -- Common, no special sound
        [2] = nil, -- Uncommon, no special sound
        [3] = "RareHatch",
        [4] = "EpicHatch",
        [5] = "LegendaryHatch",
        [6] = "MythicalHatch",
        [7] = "MythicalHatch", -- Secret uses mythical sound
    }
    
    local soundName = rarityMap[rarity]
    if soundName then
        self:PlayCase(soundName)
    end
end

function SoundSystem:PlayButtonClick()
    self:PlayUI("Click", {pitch = 0.9 + math.random() * 0.2})
end

function SoundSystem:PlayButtonHover()
    self:PlayUI("Hover")
end

function SoundSystem:PlayPurchase(success)
    if success then
        self:PlayCurrency("Purchase")
        wait(0.1)
        self:PlayUI("Success")
    else
        self:PlayUI("Error")
    end
end

return SoundSystem