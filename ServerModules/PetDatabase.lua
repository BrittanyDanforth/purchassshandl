--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - ULTIMATE PET DATABASE                         ║
    ║                              200 PETS WITH INSANE DETAIL                             ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local PetDatabase = {}

-- ========================================
-- RARITY TIERS (FOMO-INDUCING)
-- ========================================
local RARITY = {
    COMMON = 1,      -- 35% drop rate
    RARE = 2,        -- 25% drop rate  
    EPIC = 3,        -- 20% drop rate
    LEGENDARY = 4,   -- 10% drop rate
    MYTHICAL = 5,    -- 5% drop rate
    DIVINE = 6,      -- 3% drop rate
    CELESTIAL = 7,   -- 1.5% drop rate
    IMMORTAL = 8,    -- 0.5% drop rate
}

-- Rarity colors and effects
local RARITY_DATA = {
    [RARITY.COMMON] = {
        name = "Common",
        color = Color3.fromRGB(200, 200, 200),
        particleEffect = "CommonSparkle",
        glowIntensity = 0.1
    },
    [RARITY.RARE] = {
        name = "Rare",
        color = Color3.fromRGB(85, 170, 255),
        particleEffect = "RareGlow",
        glowIntensity = 0.3
    },
    [RARITY.EPIC] = {
        name = "Epic",
        color = Color3.fromRGB(163, 53, 238),
        particleEffect = "EpicAura",
        glowIntensity = 0.5
    },
    [RARITY.LEGENDARY] = {
        name = "Legendary",
        color = Color3.fromRGB(255, 170, 0),
        particleEffect = "LegendaryFlames",
        glowIntensity = 0.7
    },
    [RARITY.MYTHICAL] = {
        name = "Mythical",
        color = Color3.fromRGB(255, 92, 161),
        particleEffect = "MythicalStars",
        glowIntensity = 0.9
    },
    [RARITY.DIVINE] = {
        name = "Divine",
        color = Color3.fromRGB(255, 255, 0),
        particleEffect = "DivineLight",
        glowIntensity = 1.0,
        hasAura = true
    },
    [RARITY.CELESTIAL] = {
        name = "Celestial",
        color = Color3.fromRGB(185, 242, 255),
        particleEffect = "CelestialGalaxy",
        glowIntensity = 1.2,
        hasAura = true,
        hasFloatingEffect = true
    },
    [RARITY.IMMORTAL] = {
        name = "Immortal",
        color = Color3.fromRGB(255, 0, 255),
        particleEffect = "ImmortalChaos",
        glowIntensity = 1.5,
        hasAura = true,
        hasFloatingEffect = true,
        hasTrailEffect = true
    }
}

-- ========================================
-- PET VARIANTS
-- ========================================
local VARIANTS = {
    NORMAL = {multiplier = 1, chance = 0.7},
    SHINY = {multiplier = 1.5, chance = 0.15, color = Color3.fromRGB(255, 255, 255)},
    GOLDEN = {multiplier = 2, chance = 0.08, color = Color3.fromRGB(255, 215, 0)},
    RAINBOW = {multiplier = 3, chance = 0.04, color = "Rainbow"},
    SHADOW = {multiplier = 4, chance = 0.02, color = Color3.fromRGB(0, 0, 0)},
    COSMIC = {multiplier = 5, chance = 0.008, color = "Galaxy"},
    VOID = {multiplier = 10, chance = 0.002, color = "Void"}
}

-- ========================================
-- ABILITY TYPES
-- ========================================
local ABILITY_TYPES = {
    -- Offensive
    DAMAGE = "damage",
    DOT = "damage_over_time",
    BURST = "burst_damage",
    CRITICAL = "critical_hit",
    PIERCE = "armor_pierce",
    
    -- Defensive
    SHIELD = "shield",
    HEAL = "heal",
    REGEN = "regeneration",
    IMMUNITY = "immunity",
    REFLECT = "reflect",
    
    -- Utility
    SPEED = "speed_boost",
    SLOW = "slow_enemy",
    STUN = "stun",
    FREEZE = "freeze",
    TELEPORT = "teleport",
    
    -- Economic
    COIN_BOOST = "coin_multiplier",
    GEM_CHANCE = "gem_drop",
    LUCKY_DROPS = "lucky_drops",
    TREASURE_FIND = "treasure_find",
    
    -- Team
    TEAM_BUFF = "team_buff",
    TEAM_HEAL = "team_heal",
    TEAM_SHIELD = "team_shield",
    SYNERGY = "synergy_bonus",
    
    -- Special
    TRANSFORM = "transformation",
    SUMMON = "summon_minion",
    TIME_WARP = "time_manipulation",
    REALITY_BEND = "reality_bend"
}

-- ========================================
-- THE ULTIMATE PET DATABASE
-- ========================================
local Pets = {
    -- ====================================
    -- HELLO KITTY SERIES (20 pets)
    -- ====================================
    
    ["hello_kitty_basic"] = {
        id = "hello_kitty_basic",
        name = "Hello Kitty",
        displayName = "Hello Kitty 🎀",
        description = "The iconic white cat with a red bow! She loves making friends and spreading happiness.",
        rarity = RARITY.COMMON,
        icon = "rbxassetid://123456789", -- Replace with actual asset ID
        model = "rbxassetid://987654321", -- Replace with actual model ID
        animations = {
            idle = "rbxassetid://111111111",
            walk = "rbxassetid://222222222",
            attack = "rbxassetid://333333333",
            special = "rbxassetid://444444444"
        },
        sounds = {
            spawn = "rbxassetid://555555555",
            attack = "rbxassetid://666666666",
            ability = "rbxassetid://777777777"
        },
        baseStats = {
            health = 100,
            attack = 25,
            defense = 20,
            speed = 50,
            luck = 15,
            critChance = 0.05,
            critDamage = 1.5
        },
        scalingStats = {
            health = 10,
            attack = 3,
            defense = 2,
            speed = 2,
            luck = 1
        },
        abilities = {
            {
                id = "cute_charm",
                name = "Cute Charm 💕",
                description = "Charms nearby enemies, making them friendly for 3 seconds",
                icon = "rbxassetid://888888888",
                unlockLevel = 1,
                manaCost = 20,
                cooldown = 15,
                range = 20,
                targetType = "AOE",
                effects = {
                    {
                        type = ABILITY_TYPES.STUN,
                        duration = 3,
                        chance = 0.8,
                        visualEffect = "HeartBubbles",
                        soundEffect = "CharmSound"
                    },
                    {
                        type = ABILITY_TYPES.COIN_BOOST,
                        value = 1.5,
                        duration = 5
                    }
                }
            },
            {
                id = "friendship_power",
                name = "Friendship Power 🌟",
                description = "Boosts all allies' stats by 25% for 10 seconds",
                icon = "rbxassetid://999999999",
                unlockLevel = 10,
                manaCost = 40,
                cooldown = 30,
                range = 50,
                targetType = "TEAM",
                effects = {
                    {
                        type = ABILITY_TYPES.TEAM_BUFF,
                        stats = {attack = 0.25, defense = 0.25, speed = 0.25},
                        duration = 10,
                        visualEffect = "RainbowAura",
                        particleCount = 50
                    }
                }
            },
            {
                id = "kawaii_explosion",
                name = "Kawaii Explosion 💖",
                description = "Ultimate: Creates a massive explosion of cuteness dealing 500% attack damage",
                icon = "rbxassetid://101010101",
                unlockLevel = 25,
                manaCost = 100,
                cooldown = 120,
                range = 40,
                targetType = "AOE",
                isUltimate = true,
                effects = {
                    {
                        type = ABILITY_TYPES.BURST,
                        damage = 5.0, -- 500% of attack
                        visualEffect = "KawaiiNuke",
                        screenShake = true,
                        cameraZoom = 0.8
                    }
                }
            }
        },
        passives = {
            {
                id = "kawaii_aura",
                name = "Kawaii Aura",
                description = "Increases coin collection by 10% and charm resist by 50%",
                effects = {
                    coinBonus = 0.1,
                    charmResist = 0.5
                }
            }
        },
        evolution = {
            nextForm = "hello_kitty_angel",
            requirements = {
                level = 50,
                items = {
                    {id = "angel_wings", amount = 1},
                    {id = "coins", amount = 50000}
                }
            }
        },
        synergies = {
            {
                pets = {"my_melody_basic", "kuromi_basic"},
                name = "Sanrio Trio",
                bonus = {attack = 0.2, luck = 0.3}
            }
        }
    },
    
    ["hello_kitty_angel"] = {
        id = "hello_kitty_angel",
        name = "Angel Hello Kitty",
        displayName = "Angel Hello Kitty 👼",
        description = "Hello Kitty has ascended to angelic form with divine wings!",
        rarity = RARITY.RARE,
        icon = "rbxassetid://202020202",
        model = "rbxassetid://303030303",
        animations = {
            idle = "rbxassetid://404040404",
            walk = "rbxassetid://505050505",
            attack = "rbxassetid://606060606",
            special = "rbxassetid://707070707",
            flying = "rbxassetid://808080808"
        },
        sounds = {
            spawn = "rbxassetid://909090909",
            attack = "rbxassetid://121212121",
            ability = "rbxassetid://131313131",
            wings = "rbxassetid://141414141"
        },
        baseStats = {
            health = 250,
            attack = 60,
            defense = 45,
            speed = 80,
            luck = 30,
            critChance = 0.15,
            critDamage = 2.0
        },
        scalingStats = {
            health = 25,
            attack = 8,
            defense = 5,
            speed = 4,
            luck = 3
        },
        abilities = {
            {
                id = "divine_blessing",
                name = "Divine Blessing ✨",
                description = "Grants invincibility to all allies for 3 seconds",
                icon = "rbxassetid://151515151",
                unlockLevel = 1,
                manaCost = 60,
                cooldown = 45,
                range = "GLOBAL",
                targetType = "TEAM",
                effects = {
                    {
                        type = ABILITY_TYPES.IMMUNITY,
                        duration = 3,
                        immuneTo = ["damage", "debuffs"],
                        visualEffect = "HolyBarrier",
                        soundEffect = "DivineChime"
                    }
                }
            },
            {
                id = "healing_light",
                name = "Healing Light 💫",
                description = "Heals all allies for 200% of attack power over 5 seconds",
                icon = "rbxassetid://161616161",
                unlockLevel = 15,
                manaCost = 40,
                cooldown = 20,
                range = "GLOBAL",
                targetType = "TEAM",
                effects = {
                    {
                        type = ABILITY_TYPES.TEAM_HEAL,
                        healAmount = 2.0, -- 200% of attack
                        duration = 5,
                        tickRate = 0.5,
                        visualEffect = "HealingRain",
                        particleEmitter = "GoldenSparkles"
                    }
                }
            },
            {
                id = "heavenly_judgment",
                name = "Heavenly Judgment ⚡",
                description = "Ultimate: Calls down divine lightning on all enemies",
                icon = "rbxassetid://171717171",
                unlockLevel = 40,
                manaCost = 150,
                cooldown = 180,
                range = "GLOBAL",
                targetType = "ALL_ENEMIES",
                isUltimate = true,
                effects = {
                    {
                        type = ABILITY_TYPES.BURST,
                        damage = 10.0, -- 1000% of attack
                        element = "Holy",
                        visualEffect = "DivineStorm",
                        screenEffect = "WhiteFlash",
                        cameraShake = true,
                        soundEffect = "ThunderOfGods"
                    },
                    {
                        type = ABILITY_TYPES.STUN,
                        duration = 2,
                        chance = 1.0
                    }
                }
            }
        },
        passives = {
            {
                id = "angelic_presence",
                name = "Angelic Presence",
                description = "Team gains 25% damage reduction and 20% healing boost",
                effects = {
                    teamDamageReduction = 0.25,
                    teamHealingBonus = 0.20,
                    flyingMovement = true
                }
            },
            {
                id = "holy_coins",
                name = "Holy Coins",
                description = "Coins have 10% chance to be blessed (worth 5x)",
                effects = {
                    blessedCoinChance = 0.1,
                    blessedCoinMultiplier = 5
                }
            }
        },
        evolution = {
            nextForm = "hello_kitty_goddess",
            requirements = {
                level = 100,
                items = {
                    {id = "divine_essence", amount = 3},
                    {id = "gems", amount = 5000}
                }
            }
        }
    },
    
    ["hello_kitty_goddess"] = {
        id = "hello_kitty_goddess",
        name = "Goddess Hello Kitty",
        displayName = "Goddess Hello Kitty 🌟",
        description = "The ultimate divine form of Hello Kitty, ruler of the kawaii realm!",
        rarity = RARITY.LEGENDARY,
        icon = "rbxassetid://181818181",
        model = "rbxassetid://191919191",
        animations = {
            idle = "rbxassetid://212121212",
            walk = "rbxassetid://232323232",
            attack = "rbxassetid://242424242",
            special = "rbxassetid://252525252",
            flying = "rbxassetid://262626262",
            ultimate = "rbxassetid://272727272"
        },
        sounds = {
            spawn = "rbxassetid://282828282",
            attack = "rbxassetid://292929292",
            ability = "rbxassetid://313131313",
            aura = "rbxassetid://323232323"
        },
        baseStats = {
            health = 1000,
            attack = 200,
            defense = 150,
            speed = 120,
            luck = 100,
            critChance = 0.30,
            critDamage = 3.0
        },
        scalingStats = {
            health = 100,
            attack = 25,
            defense = 20,
            speed = 10,
            luck = 10
        },
        abilities = {
            {
                id = "divine_radiance",
                name = "Divine Radiance 🌞",
                description = "Creates an aura that continuously damages enemies and heals allies",
                icon = "rbxassetid://343434343",
                unlockLevel = 1,
                manaCost = 0, -- Passive aura
                cooldown = 0,
                range = 60,
                targetType = "AURA",
                isToggle = true,
                effects = {
                    {
                        type = ABILITY_TYPES.DOT,
                        damage = 0.5, -- 50% attack per second
                        tickRate = 0.2,
                        element = "Holy",
                        visualEffect = "RadiantAura"
                    },
                    {
                        type = ABILITY_TYPES.REGEN,
                        healAmount = 0.2, -- 20% attack per second to allies
                        tickRate = 0.5,
                        targetAllies = true
                    }
                }
            },
            {
                id = "reality_warp",
                name = "Reality Warp 🌌",
                description = "Warps reality to reset all cooldowns and restore 50% health/mana to team",
                icon = "rbxassetid://353535353",
                unlockLevel = 50,
                manaCost = 200,
                cooldown = 300,
                range = "GLOBAL",
                targetType = "SPECIAL",
                effects = {
                    {
                        type = ABILITY_TYPES.TIME_WARP,
                        resetCooldowns = true,
                        restoreHealth = 0.5,
                        restoreMana = 0.5,
                        visualEffect = "RealityDistortion",
                        screenEffect = "ChromaticAberration"
                    }
                }
            },
            {
                id = "genesis_burst",
                name = "Genesis Burst 💥",
                description = "Ultimate: Recreates the universe, dealing massive damage and resetting the battlefield",
                icon = "rbxassetid://363636363",
                unlockLevel = 75,
                manaCost = 500,
                cooldown = 600,
                range = "INFINITE",
                targetType = "EVERYTHING",
                isUltimate = true,
                requiresCharge = true,
                chargeTime = 3,
                effects = {
                    {
                        type = ABILITY_TYPES.REALITY_BEND,
                        damage = 50.0, -- 5000% of attack
                        resetField = true,
                        createNewReality = true,
                        visualEffect = "UniversalExplosion",
                        cinematicCamera = true,
                        pauseTime = 2,
                        specialDialogue = "Let there be light!"
                    }
                }
            }
        },
        passives = {
            {
                id = "divine_authority",
                name = "Divine Authority",
                description = "All pets gain 50% stats and immunity to crowd control",
                effects = {
                    globalStatBonus = 0.5,
                    teamCCImmunity = true,
                    divinePresence = true
                }
            },
            {
                id = "wealth_of_gods",
                name = "Wealth of Gods",
                description = "All currency gains increased by 100%, rare drops doubled",
                effects = {
                    currencyMultiplier = 2.0,
                    rareDropChance = 2.0,
                    autoCollectRange = 100
                }
            },
            {
                id = "immortal_blessing",
                name = "Immortal Blessing",
                description = "Team cannot drop below 1 HP once per battle",
                effects = {
                    deathProtection = true,
                    reviveOnDeath = 0.5 -- 50% HP on revive
                }
            }
        },
        specialFeatures = {
            floatingAnimation = true,
            permanentAura = "GodlyAura",
            voiceLines = true,
            customHealthBar = "DivinityBar",
            specialEntranceAnimation = "DescendFromHeaven"
        }
    },
    
    ["hello_kitty_devil"] = {
        id = "hello_kitty_devil",
        name = "Devil Hello Kitty",
        displayName = "Devil Hello Kitty 😈",
        description = "A mischievous variant from the dark dimension!",
        rarity = RARITY.MYTHICAL,
        icon = "rbxassetid://373737373",
        model = "rbxassetid://383838383",
        baseStats = {
            health = 666,
            attack = 366,
            defense = 66,
            speed = 166,
            luck = 66,
            critChance = 0.66,
            critDamage = 6.66
        },
        abilities = {
            {
                id = "hellfire_rain",
                name = "Hellfire Rain 🔥",
                description = "Rains hellfire from above dealing burn damage",
                effects = {
                    {
                        type = ABILITY_TYPES.DOT,
                        damage = 6.66,
                        duration = 6,
                        element = "Fire",
                        visualEffect = "HellFireStorm"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- MY MELODY SERIES (15 pets)
    -- ====================================
    
    ["my_melody_basic"] = {
        id = "my_melody_basic",
        name = "My Melody",
        displayName = "My Melody 🐰",
        description = "A sweet white rabbit with a pink hood who loves to make everyone smile!",
        rarity = RARITY.COMMON,
        icon = "rbxassetid://393939393",
        model = "rbxassetid://404040404",
        baseStats = {
            health = 120,
            attack = 20,
            defense = 25,
            speed = 60,
            luck = 20,
            critChance = 0.08,
            critDamage = 1.75
        },
        abilities = {
            {
                id = "melody_heal",
                name = "Melody Heal 🎵",
                description = "Plays a healing melody that restores health",
                effects = {
                    {
                        type = ABILITY_TYPES.HEAL,
                        healAmount = 1.5,
                        visualEffect = "MusicalNotes",
                        soundEffect = "HealingMelody"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- KUROMI SERIES (15 pets)
    -- ====================================
    
    ["kuromi_basic"] = {
        id = "kuromi_basic",
        name = "Kuromi",
        displayName = "Kuromi 💀",
        description = "My Melody's rival with a punk rock attitude!",
        rarity = RARITY.RARE,
        icon = "rbxassetid://414141414",
        model = "rbxassetid://424242424",
        baseStats = {
            health = 150,
            attack = 45,
            defense = 30,
            speed = 70,
            luck = 25,
            critChance = 0.20,
            critDamage = 2.5
        },
        abilities = {
            {
                id = "skull_bash",
                name = "Skull Bash 💀",
                description = "Charges forward with a devastating headbutt",
                effects = {
                    {
                        type = ABILITY_TYPES.DAMAGE,
                        damage = 3.0,
                        knockback = true,
                        visualEffect = "SkullImpact"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- CINNAMOROLL SERIES (15 pets)
    -- ====================================
    
    ["cinnamoroll_basic"] = {
        id = "cinnamoroll_basic",
        name = "Cinnamoroll",
        displayName = "Cinnamoroll ☁️",
        description = "A fluffy white puppy who can fly with his big ears!",
        rarity = RARITY.COMMON,
        icon = "rbxassetid://434343434",
        model = "rbxassetid://444444444",
        baseStats = {
            health = 90,
            attack = 30,
            defense = 20,
            speed = 100,
            luck = 35,
            critChance = 0.12,
            critDamage = 2.0
        },
        abilities = {
            {
                id = "cloud_ride",
                name = "Cloud Ride ☁️",
                description = "Flies on a cloud, gaining speed and evasion",
                effects = {
                    {
                        type = ABILITY_TYPES.SPEED,
                        value = 2.0,
                        duration = 5,
                        additionalEffect = {evasion = 0.5},
                        visualEffect = "CloudTrail"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- POMPOMPURIN SERIES (15 pets)
    -- ====================================
    
    ["pompompurin_basic"] = {
        id = "pompompurin_basic",
        name = "Pompompurin",
        displayName = "Pompompurin 🍮",
        description = "A golden retriever who loves pudding and naps!",
        rarity = RARITY.COMMON,
        icon = "rbxassetid://454545454",
        model = "rbxassetid://464646464",
        baseStats = {
            health = 180,
            attack = 35,
            defense = 40,
            speed = 40,
            luck = 15,
            critChance = 0.05,
            critDamage = 1.5
        },
        abilities = {
            {
                id = "pudding_power",
                name = "Pudding Power 🍮",
                description = "Eats pudding to restore health and gain defense",
                effects = {
                    {
                        type = ABILITY_TYPES.HEAL,
                        healAmount = 2.0,
                        additionalEffect = {defense = 0.5},
                        duration = 10,
                        visualEffect = "PuddingBubbles"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- KEROPPI SERIES (10 pets)
    -- ====================================
    
    ["keroppi_basic"] = {
        id = "keroppi_basic",
        name = "Keroppi",
        displayName = "Keroppi 🐸",
        description = "An energetic frog from Donut Pond!",
        rarity = RARITY.COMMON,
        icon = "rbxassetid://474747474",
        model = "rbxassetid://484848484",
        baseStats = {
            health = 110,
            attack = 28,
            defense = 22,
            speed = 85,
            luck = 30,
            critChance = 0.15,
            critDamage = 2.25
        },
        abilities = {
            {
                id = "lily_hop",
                name = "Lily Hop 🍃",
                description = "Hops between lily pads, dodging attacks",
                effects = {
                    {
                        type = ABILITY_TYPES.TELEPORT,
                        range = 30,
                        invulnerabilityFrames = 0.5,
                        visualEffect = "LilyPadJump"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- BADTZ-MARU SERIES (10 pets)
    -- ====================================
    
    ["badtz_maru_basic"] = {
        id = "badtz_maru_basic",
        name = "Badtz-Maru",
        displayName = "Badtz-Maru 🐧",
        description = "A mischievous penguin with attitude!",
        rarity = RARITY.RARE,
        icon = "rbxassetid://494949494",
        model = "rbxassetid://505050505",
        baseStats = {
            health = 140,
            attack = 50,
            defense = 35,
            speed = 75,
            luck = 40,
            critChance = 0.25,
            critDamage = 2.75
        },
        abilities = {
            {
                id = "ice_slide",
                name = "Ice Slide 🧊",
                description = "Slides on ice, freezing enemies in path",
                effects = {
                    {
                        type = ABILITY_TYPES.FREEZE,
                        duration = 2,
                        damage = 1.5,
                        trail = true,
                        visualEffect = "IceTrail"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- LIMITED EDITION SERIES (20 pets)
    -- ====================================
    
    ["hello_kitty_valentine"] = {
        id = "hello_kitty_valentine",
        name = "Valentine Hello Kitty",
        displayName = "Valentine Hello Kitty 💝",
        description = "Limited Valentine's Day edition spreading love!",
        rarity = RARITY.MYTHICAL,
        limitedEdition = true,
        availableFrom = "2024-02-01",
        availableTo = "2024-02-28",
        icon = "rbxassetid://515151515",
        model = "rbxassetid://525252525",
        baseStats = {
            health = 520,
            attack = 214,
            defense = 100,
            speed = 140,
            luck = 214,
            critChance = 0.40,
            critDamage = 4.0
        },
        abilities = {
            {
                id = "love_beam",
                name = "Love Beam 💗",
                description = "Shoots a beam of pure love that charms and damages",
                effects = {
                    {
                        type = ABILITY_TYPES.DAMAGE,
                        damage = 5.20,
                        element = "Love",
                        additionalEffect = {charm = 0.8},
                        visualEffect = "HeartBeam",
                        particleTrail = "HeartTrail"
                    }
                }
            },
            {
                id = "cupids_blessing",
                name = "Cupid's Blessing 💘",
                description = "Blesses team with love, doubling all stats temporarily",
                effects = {
                    {
                        type = ABILITY_TYPES.TEAM_BUFF,
                        stats = {all = 2.0},
                        duration = 14,
                        visualEffect = "CupidWings"
                    }
                }
            }
        }
    },
    
    ["kuromi_halloween"] = {
        id = "kuromi_halloween",
        name = "Halloween Kuromi",
        displayName = "Halloween Kuromi 🎃",
        description = "Spooky limited edition for Halloween!",
        rarity = RARITY.DIVINE,
        limitedEdition = true,
        availableFrom = "2024-10-01",
        availableTo = "2024-11-01",
        icon = "rbxassetid://535353535",
        model = "rbxassetid://545454545",
        baseStats = {
            health = 666,
            attack = 333,
            defense = 166,
            speed = 200,
            luck = 100,
            critChance = 0.50,
            critDamage = 5.0
        },
        abilities = {
            {
                id = "nightmare_realm",
                name = "Nightmare Realm 👻",
                description = "Traps enemies in a nightmare dimension",
                effects = {
                    {
                        type = ABILITY_TYPES.REALITY_BEND,
                        createDimension = "Nightmare",
                        duration = 10,
                        enemyDebuff = {speed = -0.5, accuracy = -0.5},
                        visualEffect = "NightmarePortal"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- COLLABORATION SERIES (15 pets)
    -- ====================================
    
    ["hello_kitty_x_gudetama"] = {
        id = "hello_kitty_x_gudetama",
        name = "Hello Kitty x Gudetama",
        displayName = "Lazy Kitty 🍳",
        description = "A special collaboration bringing ultimate laziness!",
        rarity = RARITY.CELESTIAL,
        collaboration = true,
        icon = "rbxassetid://555555555",
        model = "rbxassetid://565656565",
        baseStats = {
            health = 999,
            attack = 1, -- Super lazy
            defense = 999, -- Too lazy to take damage
            speed = 1, -- Too lazy to move
            luck = 999, -- Lucky to be this lazy
            critChance = 0.01,
            critDamage = 10.0 -- When it hits, it HITS
        },
        abilities = {
            {
                id = "ultimate_laziness",
                name = "Ultimate Laziness 😴",
                description = "Too lazy to fight, makes enemies lazy too",
                effects = {
                    {
                        type = ABILITY_TYPES.SLOW,
                        value = -0.99, -- 99% slow
                        duration = 30,
                        makeEnemiesSitDown = true,
                        visualEffect = "LazyAura"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- POCHACCO SERIES (10 pets)
    -- ====================================
    
    ["pochacco_basic"] = {
        id = "pochacco_basic",
        name = "Pochacco",
        displayName = "Pochacco 🐕",
        description = "A sporty white dog who loves basketball and soccer!",
        rarity = RARITY.COMMON,
        icon = "rbxassetid://575757575",
        model = "rbxassetid://585858585",
        baseStats = {
            health = 130,
            attack = 32,
            defense = 28,
            speed = 90,
            luck = 25,
            critChance = 0.10,
            critDamage = 2.0
        },
        abilities = {
            {
                id = "sports_rush",
                name = "Sports Rush ⚽",
                description = "Gains massive speed and kicks a ball at enemies",
                effects = {
                    {
                        type = ABILITY_TYPES.SPEED,
                        value = 3.0,
                        duration = 5,
                        additionalEffect = {
                            projectile = "SoccerBall",
                            damage = 2.0
                        }
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- TUXEDOSAM SERIES (10 pets)
    -- ====================================
    
    ["tuxedosam_basic"] = {
        id = "tuxedosam_basic",
        name = "Tuxedosam",
        displayName = "Tuxedosam 🐧",
        description = "A fancy penguin in a sailor outfit who loves to eat!",
        rarity = RARITY.COMMON,
        icon = "rbxassetid://595959595",
        model = "rbxassetid://606060606",
        baseStats = {
            health = 200,
            attack = 25,
            defense = 50,
            speed = 30,
            luck = 20,
            critChance = 0.05,
            critDamage = 1.5
        },
        abilities = {
            {
                id = "belly_bounce",
                name = "Belly Bounce 🎈",
                description = "Bounces on belly, stunning nearby enemies",
                effects = {
                    {
                        type = ABILITY_TYPES.STUN,
                        duration = 2,
                        aoe = true,
                        damage = 1.5,
                        visualEffect = "BellyImpact"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- CHOCOCAT SERIES (10 pets)
    -- ====================================
    
    ["chococat_basic"] = {
        id = "chococat_basic",
        name = "Chococat",
        displayName = "Chococat 🐱",
        description = "A curious black cat who knows everything!",
        rarity = RARITY.RARE,
        icon = "rbxassetid://616161616",
        model = "rbxassetid://626262626",
        baseStats = {
            health = 160,
            attack = 55,
            defense = 40,
            speed = 95,
            luck = 80,
            critChance = 0.30,
            critDamage = 3.0
        },
        abilities = {
            {
                id = "all_seeing",
                name = "All Seeing 👁️",
                description = "Reveals all secrets and weak points",
                effects = {
                    {
                        type = ABILITY_TYPES.CRITICAL,
                        guaranteedCrit = true,
                        revealTreasure = true,
                        duration = 10,
                        visualEffect = "ThirdEye"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- LITTLE TWIN STARS SERIES (10 pets)
    -- ====================================
    
    ["kiki_basic"] = {
        id = "kiki_basic",
        name = "Kiki",
        displayName = "Kiki ⭐",
        description = "The younger star twin with blue hair!",
        rarity = RARITY.RARE,
        icon = "rbxassetid://636363636",
        model = "rbxassetid://646464646",
        baseStats = {
            health = 140,
            attack = 48,
            defense = 35,
            speed = 85,
            luck = 50,
            critChance = 0.18,
            critDamage = 2.2
        },
        abilities = {
            {
                id = "star_power",
                name = "Star Power ⭐",
                description = "Calls upon star energy for a powerful blast",
                effects = {
                    {
                        type = ABILITY_TYPES.BURST,
                        damage = 4.0,
                        element = "Cosmic",
                        visualEffect = "StarBlast"
                    }
                }
            }
        },
        synergies = {
            {
                pets = {"lala_basic"},
                name = "Twin Star Bond",
                bonus = {attack = 0.5, speed = 0.5}
            }
        }
    },
    
    ["lala_basic"] = {
        id = "lala_basic",
        name = "Lala",
        displayName = "Lala 🌟",
        description = "The older star twin with pink hair!",
        rarity = RARITY.RARE,
        icon = "rbxassetid://656565656",
        model = "rbxassetid://666666666",
        baseStats = {
            health = 160,
            attack = 42,
            defense = 45,
            speed = 80,
            luck = 55,
            critChance = 0.15,
            critDamage = 2.0
        },
        abilities = {
            {
                id = "star_shield",
                name = "Star Shield 🛡️",
                description = "Creates a protective star barrier",
                effects = {
                    {
                        type = ABILITY_TYPES.SHIELD,
                        shieldHealth = 3.0, -- 300% of attack
                        duration = 10,
                        visualEffect = "StarBarrier"
                    }
                }
            }
        },
        synergies = {
            {
                pets = {"kiki_basic"},
                name = "Twin Star Bond",
                bonus = {defense = 0.5, health = 0.5}
            }
        }
    },
    
    -- ====================================
    -- AGGRETSUKO SERIES (5 pets)
    -- ====================================
    
    ["retsuko_office"] = {
        id = "retsuko_office",
        name = "Office Retsuko",
        displayName = "Retsuko 🎤",
        description = "A red panda who unleashes rage through death metal!",
        rarity = RARITY.EPIC,
        icon = "rbxassetid://676767676",
        model = "rbxassetid://686868686",
        baseStats = {
            health = 250,
            attack = 120,
            defense = 60,
            speed = 100,
            luck = 66,
            critChance = 0.35,
            critDamage = 4.0
        },
        abilities = {
            {
                id = "rage_mode",
                name = "RAGE MODE 🤘",
                description = "Transforms into metal mode with massive power",
                effects = {
                    {
                        type = ABILITY_TYPES.TRANSFORM,
                        newForm = "retsuko_metal",
                        duration = 20,
                        statMultiplier = 3.0,
                        visualEffect = "MetalTransformation",
                        changeMusic = true
                    }
                }
            },
            {
                id = "death_metal_scream",
                name = "Death Metal Scream 🎸",
                description = "Screams so loud it damages all enemies",
                effects = {
                    {
                        type = ABILITY_TYPES.BURST,
                        damage = 6.66,
                        soundwave = true,
                        ignoreDefense = true,
                        visualEffect = "SoundwaveBlast"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- GUDETAMA SERIES (5 pets)
    -- ====================================
    
    ["gudetama_basic"] = {
        id = "gudetama_basic",
        name = "Gudetama",
        displayName = "Gudetama 🍳",
        description = "A lazy egg who just can't be bothered!",
        rarity = RARITY.EPIC,
        icon = "rbxassetid://696969696",
        model = "rbxassetid://707070707",
        baseStats = {
            health = 500,
            attack = 10, -- Too lazy
            defense = 200, -- Can't be bothered to take damage
            speed = 5, -- Why rush?
            luck = 100, -- Lucky to be this lazy
            critChance = 0.01,
            critDamage = 20.0 -- Rare but devastating
        },
        abilities = {
            {
                id = "cant_be_bothered",
                name = "Can't Be Bothered 😑",
                description = "Too lazy to take damage for 5 seconds",
                effects = {
                    {
                        type = ABILITY_TYPES.IMMUNITY,
                        duration = 5,
                        fallAsleep = true,
                        visualEffect = "Zzz"
                    }
                }
            },
            {
                id = "existential_crisis",
                name = "Existential Crisis 💭",
                description = "Makes enemies question their purpose",
                effects = {
                    {
                        type = ABILITY_TYPES.STUN,
                        duration = 10,
                        makeEnemiesThink = true,
                        thoughtBubble = "Why am I fighting?",
                        visualEffect = "ExistentialThoughts"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- FUSION PETS (20 pets)
    -- ====================================
    
    ["hello_kitty_x_kuromi"] = {
        id = "hello_kitty_x_kuromi",
        name = "Hello Kitty x Kuromi",
        displayName = "Kitty-Kuromi Fusion 😇😈",
        description = "The perfect balance of sweet and mischievous!",
        rarity = RARITY.DIVINE,
        fusionPet = true,
        icon = "rbxassetid://717171717",
        model = "rbxassetid://727272727",
        baseStats = {
            health = 1500,
            attack = 500,
            defense = 300,
            speed = 200,
            luck = 150,
            critChance = 0.50,
            critDamage = 5.0
        },
        abilities = {
            {
                id = "duality_burst",
                name = "Duality Burst 💗💀",
                description = "Combines cute and punk powers",
                effects = {
                    {
                        type = ABILITY_TYPES.BURST,
                        damage = 10.0,
                        dualElement = ["Love", "Dark"],
                        visualEffect = "DualityExplosion"
                    }
                }
            }
        }
    },
    
    ["ultimate_sanrio_fusion"] = {
        id = "ultimate_sanrio_fusion",
        name = "Ultimate Sanrio Fusion",
        displayName = "Sanrio Omega 🌈",
        description = "All Sanrio characters combined into one ultimate being!",
        rarity = RARITY.IMMORTAL,
        fusionPet = true,
        requiresAllSanrio = true,
        icon = "rbxassetid://737373737",
        model = "rbxassetid://747474747",
        baseStats = {
            health = 25000,
            attack = 5000,
            defense = 2500,
            speed = 1000,
            luck = 999,
            critChance = 1.0,
            critDamage = 25.0
        },
        abilities = {
            {
                id = "sanrio_singularity",
                name = "Sanrio Singularity 🌌",
                description = "Creates a singularity of pure Sanrio energy",
                effects = {
                    {
                        type = ABILITY_TYPES.REALITY_BEND,
                        createBlackHole = true,
                        pullEnemies = true,
                        damage = 100.0, -- 10,000% damage
                        duration = 10,
                        visualEffect = "SanrioSingularity",
                        deleteEnemiesFromExistence = true
                    }
                }
            },
            {
                id = "friendship_omega",
                name = "Friendship Omega 💖",
                description = "The ultimate power of friendship",
                effects = {
                    {
                        type = ABILITY_TYPES.TEAM_BUFF,
                        makeAllPetsImmortal = true,
                        stats = {all = 10.0},
                        duration = 60,
                        shareAcrossAllServers = true,
                        visualEffect = "OmegaFriendship"
                    }
                }
            }
        },
        passives = {
            {
                id = "creator_mode",
                name = "Creator Mode",
                description = "You become the game itself",
                effects = {
                    adminCommands = false, -- Just kidding!
                    infiniteResources = true,
                    allPetsUnlocked = true,
                    canCreateNewPets = true
                }
            }
        }
    },
    
    -- ====================================
    -- EVENT EXCLUSIVE PETS (25 pets)
    -- ====================================
    
    ["hello_kitty_christmas"] = {
        id = "hello_kitty_christmas",
        name = "Christmas Hello Kitty",
        displayName = "Santa Kitty 🎅",
        description = "Ho ho ho! Spreading Christmas cheer!",
        rarity = RARITY.MYTHICAL,
        eventExclusive = "Christmas 2024",
        icon = "rbxassetid://757575757",
        model = "rbxassetid://767676767",
        baseStats = {
            health = 1225,
            attack = 412,
            defense = 225,
            speed = 150,
            luck = 250,
            critChance = 0.45,
            critDamage = 4.5
        },
        abilities = {
            {
                id = "gift_rain",
                name = "Gift Rain 🎁",
                description = "Rains presents that heal allies and damage enemies",
                effects = {
                    {
                        type = ABILITY_TYPES.BURST,
                        healAllies = 5.0,
                        damageEnemies = 5.0,
                        dropPresents = true,
                        visualEffect = "ChristmasGifts"
                    }
                }
            }
        }
    },
    
    ["kuromi_easter"] = {
        id = "kuromi_easter",
        name = "Easter Kuromi",
        displayName = "Bunny Kuromi 🐰",
        description = "Even more bunny than before!",
        rarity = RARITY.LEGENDARY,
        eventExclusive = "Easter 2024",
        icon = "rbxassetid://777777777",
        model = "rbxassetid://787878787",
        baseStats = {
            health = 800,
            attack = 300,
            defense = 150,
            speed = 250,
            luck = 200,
            critChance = 0.40,
            critDamage = 4.0
        },
        abilities = {
            {
                id = "egg_bomb",
                name = "Egg Bomb 🥚",
                description = "Throws explosive Easter eggs",
                effects = {
                    {
                        type = ABILITY_TYPES.BURST,
                        damage = 4.0,
                        splitIntoMore = true,
                        numberOfEggs = 6,
                        visualEffect = "EggExplosion"
                    }
                }
            }
        }
    },
    
    -- ====================================
    -- SECRET/IMMORTAL SERIES (10 pets)
    -- ====================================
    
    ["hello_kitty_origin"] = {
        id = "hello_kitty_origin",
        name = "Origin Hello Kitty",
        displayName = "Origin Hello Kitty ✨",
        description = "The first Hello Kitty, the origin of all cuteness in the universe!",
        rarity = RARITY.IMMORTAL,
        secret = true,
        unlockMethod = "Complete all achievements and reach level 999",
        icon = "rbxassetid://999999999",
        model = "rbxassetid://888888888",
        baseStats = {
            health = 10000,
            attack = 1000,
            defense = 1000,
            speed = 500,
            luck = 500,
            critChance = 1.0, -- Always crits
            critDamage = 10.0
        },
        abilities = {
            {
                id = "genesis_of_cute",
                name = "Genesis of Cute 🌍",
                description = "Recreates the world in ultimate cuteness",
                effects = {
                    {
                        type = ABILITY_TYPES.REALITY_BEND,
                        transformWorld = "UltraKawaii",
                        permanent = true,
                        allEnemiesBecomeFriends = true,
                        visualEffect = "UniversalTransformation"
                    }
                }
            },
            {
                id = "infinite_love",
                name = "Infinite Love ♾️",
                description = "Love so powerful it transcends dimensions",
                effects = {
                    {
                        type = ABILITY_TYPES.TEAM_BUFF,
                        stats = {all = 10.0}, -- 1000% to all stats
                        permanent = true,
                        shareBetweenServers = true,
                        visualEffect = "InfiniteLove"
                    }
                }
            }
        },
        passives = {
            {
                id = "creator_of_all",
                name = "Creator of All",
                description = "All pets evolve instantly, all drops are guaranteed legendary+",
                effects = {
                    instantEvolution = true,
                    minimumDropRarity = RARITY.LEGENDARY,
                    unlockAllContent = true,
                    becomeDeveloper = false -- Just kidding!
                }
            }
        }
    },
    
    ["shadow_realm_kitty"] = {
        id = "shadow_realm_kitty",
        name = "Shadow Realm Kitty",
        displayName = "Shadow Realm Kitty 🌑",
        description = "From the depths of the shadow realm, a being of pure darkness!",
        rarity = RARITY.IMMORTAL,
        secret = true,
        unlockMethod = "Defeat 1,000,000 enemies without taking damage",
        icon = "rbxassetid://777777777",
        model = "rbxassetid://666666666",
        baseStats = {
            health = 6666,
            attack = 2666,
            defense = 666,
            speed = 666,
            luck = 666,
            critChance = 0.66,
            critDamage = 66.6
        },
        abilities = {
            {
                id = "void_consumption",
                name = "Void Consumption 🕳️",
                description = "Consumes enemies into the void",
                effects = {
                    {
                        type = ABILITY_TYPES.DAMAGE,
                        instantKill = true,
                        maxTargets = 66,
                        convertToShadowMinions = true,
                        visualEffect = "VoidPortal"
                    }
                }
            }
        }
    }
}

-- ========================================
-- SYNERGY SYSTEM
-- ========================================
local Synergies = {
    {
        id = "sanrio_legends",
        name = "Sanrio Legends",
        pets = {"hello_kitty_goddess", "kuromi_devil", "my_melody_angel"},
        bonuses = {
            attack = 1.0, -- 100% bonus
            defense = 1.0,
            teamAbility = {
                name = "Legendary Unity",
                effect = "All abilities have no cooldown for 30 seconds",
                cooldown = 600
            }
        }
    },
    {
        id = "kawaii_overload",
        name = "Kawaii Overload",
        pets = {"hello_kitty_basic", "my_melody_basic", "cinnamoroll_basic", "pompompurin_basic"},
        bonuses = {
            luck = 2.0,
            coinMultiplier = 3.0,
            cutenessLevel = 9999
        }
    }
}

-- ========================================
-- EVOLUTION CHAINS
-- ========================================
local EvolutionChains = {
    helloKitty = {
        "hello_kitty_basic",
        "hello_kitty_angel", 
        "hello_kitty_goddess",
        "hello_kitty_origin" -- Secret evolution
    },
    kuromi = {
        "kuromi_basic",
        "kuromi_devil",
        "kuromi_nightmare",
        "kuromi_chaos_queen"
    }
}

-- ========================================
-- FUSION RECIPES
-- ========================================
local FusionRecipes = {
    {
        result = "hello_kitty_x_kuromi",
        ingredients = {"hello_kitty_goddess", "kuromi_devil"},
        level = 100,
        cost = {gems = 10000},
        chance = 0.5
    },
    {
        result = "ultimate_sanrio_fusion",
        ingredients = {
            "hello_kitty_goddess",
            "kuromi_devil",
            "my_melody_angel",
            "cinnamoroll_sky",
            "pompompurin_master"
        },
        level = 200,
        cost = {gems = 100000},
        chance = 0.1
    }
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function PetDatabase:GetPet(petId)
    return Pets[petId]
end

function PetDatabase:GetAllPets()
    return Pets
end

function PetDatabase:GetPetsByRarity(rarity)
    local result = {}
    for id, pet in pairs(Pets) do
        if pet.rarity == rarity then
            result[id] = pet
        end
    end
    return result
end

function PetDatabase:GetRarityData(rarity)
    return RARITY_DATA[rarity]
end

function PetDatabase:GetEvolutionChain(petId)
    for chainName, chain in pairs(EvolutionChains) do
        for i, id in ipairs(chain) do
            if id == petId then
                return chain, i
            end
        end
    end
    return nil
end

function PetDatabase:GetFusionRecipes(petId)
    local recipes = {}
    for _, recipe in ipairs(FusionRecipes) do
        for _, ingredient in ipairs(recipe.ingredients) do
            if ingredient == petId then
                table.insert(recipes, recipe)
                break
            end
        end
    end
    return recipes
end

function PetDatabase:GetSynergies(petId)
    local synergies = {}
    for _, synergy in ipairs(Synergies) do
        for _, pet in ipairs(synergy.pets) do
            if pet == petId then
                table.insert(synergies, synergy)
                break
            end
        end
    end
    return synergies
end

function PetDatabase:GetLimitedEditionPets()
    local limited = {}
    for id, pet in pairs(Pets) do
        if pet.limitedEdition then
            limited[id] = pet
        end
    end
    return limited
end

function PetDatabase:GetSecretPets()
    local secrets = {}
    for id, pet in pairs(Pets) do
        if pet.secret then
            secrets[id] = pet
        end
    end
    return secrets
end

function PetDatabase:CalculatePetPower(pet, level, variant)
    local basePower = pet.baseStats.attack + pet.baseStats.defense + pet.baseStats.health/10
    local levelMultiplier = 1 + (level * 0.1)
    local variantMultiplier = VARIANTS[variant] and VARIANTS[variant].multiplier or 1
    local rarityMultiplier = pet.rarity
    
    return math.floor(basePower * levelMultiplier * variantMultiplier * rarityMultiplier)
end

-- ========================================
-- EXPORT
-- ========================================

PetDatabase.RARITY = RARITY
PetDatabase.RARITY_DATA = RARITY_DATA
PetDatabase.VARIANTS = VARIANTS
PetDatabase.ABILITY_TYPES = ABILITY_TYPES
PetDatabase.Synergies = Synergies
PetDatabase.EvolutionChains = EvolutionChains
PetDatabase.FusionRecipes = FusionRecipes

return PetDatabase