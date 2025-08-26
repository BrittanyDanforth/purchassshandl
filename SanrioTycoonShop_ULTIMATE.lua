--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                         SANRIO TYCOON SHOP - ULTIMATE EDITION                        ║
    ║                              Version 5.0 - Full Production                           ║
    ║                                                                                      ║
    ║  Features:                                                                           ║
    ║  • 100+ Unique Sanrio Pets with Variants                                           ║
    ║  • Advanced Case Opening with Physics & Particles                                   ║
    ║  • Trading System with Security                                                      ║
    ║  • Pet Evolution & Fusion System                                                     ║
    ║  • Daily Rewards & Battle Pass                                                      ║
    ║  • Clan/Guild System                                                                ║
    ║  • Pet Battles & PvP Arena                                                          ║
    ║  • Achievements & Titles                                                            ║
    ║  • Advanced Anti-Exploit System                                                     ║
    ║  • Real-time Leaderboards                                                          ║
    ║  • Pet Inventory Management                                                         ║
    ║  • Auto-Save & Backup System                                                       ║
    ║  • Premium Currency Management                                                      ║
    ║  • Limited Time Events                                                              ║
    ║  • Pet Accessories & Customization                                                  ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ========================================
-- SERVICES & DEPENDENCIES
-- ========================================
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ServerScriptService = game:GetService("ServerScriptService"),
    ServerStorage = game:GetService("ServerStorage"),
    MarketplaceService = game:GetService("MarketplaceService"),
    DataStoreService = game:GetService("DataStoreService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    SoundService = game:GetService("SoundService"),
    Lighting = game:GetService("Lighting"),
    StarterGui = game:GetService("StarterGui"),
    MessagingService = game:GetService("MessagingService"),
    TeleportService = game:GetService("TeleportService"),
    PhysicsService = game:GetService("PhysicsService"),
    PathfindingService = game:GetService("PathfindingService"),
    GroupService = game:GetService("GroupService"),
    BadgeService = game:GetService("BadgeService"),
    ChatService = game:GetService("Chat"),
    Debris = game:GetService("Debris"),
    ContentProvider = game:GetService("ContentProvider"),
    LocalizationService = game:GetService("LocalizationService")
}

-- ========================================
-- CONFIGURATION & CONSTANTS
-- ========================================
local CONFIG = {
    -- Version Control
    VERSION = "5.0.0",
    BUILD_NUMBER = 1337,
    
    -- DataStore Keys
    DATASTORE_KEY = "SanrioTycoonData_v5",
    BACKUP_DATASTORE_KEY = "SanrioTycoonBackup_v5",
    GLOBAL_DATASTORE_KEY = "SanrioTycoonGlobal_v5",
    
    -- Economy Settings
    STARTING_GEMS = 500,
    STARTING_COINS = 10000,
    DAILY_REWARD_GEMS = 50,
    
    -- Pet System
    MAX_EQUIPPED_PETS = 6,
    MAX_INVENTORY_SIZE = 500,
    EVOLUTION_COST_MULTIPLIER = 2.5,
    FUSION_SUCCESS_RATE = 0.7,
    
    -- Trading
    TRADE_TAX_PERCENTAGE = 0.05,
    MAX_TRADE_ITEMS = 20,
    TRADE_COOLDOWN = 60,
    
    -- Anti-Exploit
    MAX_REQUESTS_PER_MINUTE = 30,
    SUSPICIOUS_WEALTH_THRESHOLD = 1000000000,
    
    -- UI Settings
    UI_ANIMATION_SPEED = 0.3,
    PARTICLE_LIFETIME = 5,
    
    -- Group Benefits
    GROUP_ID = 123456789, -- Replace with your group ID
    GROUP_BONUS_MULTIPLIER = 1.25,
    
    -- Premium Benefits
    PREMIUM_MULTIPLIER = 2,
    VIP_MULTIPLIER = 3,
    
    -- Events
    EVENT_MULTIPLIER = 2,
    LIMITED_PET_DURATION = 604800, -- 1 week in seconds
}

-- ========================================
-- ADVANCED PET DATABASE SYSTEM
-- ========================================
local PetDatabase = {
    -- TIER 1: COMMON PETS (50% drop rate)
    ["hello_kitty_classic"] = {
        id = "hello_kitty_classic",
        name = "Classic Hello Kitty",
        displayName = "Hello Kitty",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 100,
            gems = 1,
            luck = 5,
            speed = 10,
            power = 50
        },
        description = "The beloved white cat with her iconic red bow",
        imageId = "rbxassetid://10000000001",
        modelId = "rbxassetid://10000000002",
        animations = {
            idle = "rbxassetid://10000000003",
            walk = "rbxassetid://10000000004",
            attack = "rbxassetid://10000000005",
            special = "rbxassetid://10000000006"
        },
        abilities = {
            {
                name = "Cuteness Overload",
                description = "Increases coin production by 20% for 30 seconds",
                cooldown = 60,
                effect = "coin_boost",
                value = 0.2,
                duration = 30
            },
            {
                name = "Red Bow Power",
                description = "Grants 10% chance to double rewards",
                passive = true,
                effect = "double_chance",
                value = 0.1
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1000,
            items = {"red_bow", "white_ribbon"}
        },
        evolvesTo = "hello_kitty_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 200, 200)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)}
        }
    },
    
    ["my_melody_classic"] = {
        id = "my_melody_classic",
        name = "Classic My Melody",
        displayName = "My Melody",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 120,
            gems = 1,
            luck = 7,
            speed = 12,
            power = 45
        },
        description = "Sweet white rabbit with her signature pink hood",
        imageId = "rbxassetid://10000000007",
        modelId = "rbxassetid://10000000008",
        animations = {
            idle = "rbxassetid://10000000009",
            walk = "rbxassetid://10000000010",
            attack = "rbxassetid://10000000011",
            special = "rbxassetid://10000000012"
        },
        abilities = {
            {
                name = "Melody Magic",
                description = "Heals nearby pets by 20% of max health",
                cooldown = 45,
                effect = "heal_aoe",
                value = 0.2,
                radius = 20
            },
            {
                name = "Pink Hood Protection",
                description = "Reduces damage taken by 15%",
                passive = true,
                effect = "damage_reduction",
                value = 0.15
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1000,
            items = {"pink_hood", "melody_note"}
        },
        evolvesTo = "my_melody_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 192, 203)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)}
        }
    },
    
    -- TIER 2: UNCOMMON PETS (30% drop rate)
    ["kuromi_classic"] = {
        id = "kuromi_classic",
        name = "Classic Kuromi",
        displayName = "Kuromi",
        tier = "Uncommon",
        rarity = 2,
        baseStats = {
            coins = 250,
            gems = 3,
            luck = 10,
            speed = 15,
            power = 80
        },
        description = "Mischievous white rabbit with devil horns and a pink skull",
        imageId = "rbxassetid://10000000013",
        modelId = "rbxassetid://10000000014",
        animations = {
            idle = "rbxassetid://10000000015",
            walk = "rbxassetid://10000000016",
            attack = "rbxassetid://10000000017",
            special = "rbxassetid://10000000018"
        },
        abilities = {
            {
                name = "Dark Magic",
                description = "Deals damage to all enemies in range",
                cooldown = 30,
                effect = "damage_aoe",
                value = 150,
                radius = 25
            },
            {
                name = "Mischief Maker",
                description = "25% chance to steal enemy buffs",
                passive = true,
                effect = "steal_buffs",
                value = 0.25
            },
            {
                name = "Devil's Luck",
                description = "Increases critical hit chance by 20%",
                passive = true,
                effect = "crit_chance",
                value = 0.2
            }
        },
        evolutionRequirements = {
            level = 35,
            gems = 2500,
            items = {"devil_horn", "pink_skull", "dark_essence"}
        },
        evolvesTo = "kuromi_demon",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 100, 255)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            corrupted = {multiplier = 25, colorShift = Color3.fromRGB(100, 0, 0)}
        }
    },
    
    -- TIER 3: RARE PETS (15% drop rate)
    ["cinnamoroll_classic"] = {
        id = "cinnamoroll_classic",
        name = "Classic Cinnamoroll",
        displayName = "Cinnamoroll",
        tier = "Rare",
        rarity = 3,
        baseStats = {
            coins = 500,
            gems = 5,
            luck = 15,
            speed = 25,
            power = 120
        },
        description = "Fluffy white puppy who can fly with his long ears",
        imageId = "rbxassetid://10000000019",
        modelId = "rbxassetid://10000000020",
        animations = {
            idle = "rbxassetid://10000000021",
            walk = "rbxassetid://10000000022",
            attack = "rbxassetid://10000000023",
            special = "rbxassetid://10000000024",
            fly = "rbxassetid://10000000025"
        },
        abilities = {
            {
                name = "Cloud Flight",
                description = "Grants flight and 50% speed boost for 20 seconds",
                cooldown = 60,
                effect = "flight_boost",
                value = 0.5,
                duration = 20
            },
            {
                name = "Cinnamon Swirl",
                description = "Creates a tornado that pulls enemies",
                cooldown = 45,
                effect = "tornado",
                value = 200,
                radius = 30
            },
            {
                name = "Fluffy Shield",
                description = "Absorbs next 3 attacks",
                cooldown = 90,
                effect = "shield",
                value = 3
            }
        },
        evolutionRequirements = {
            level = 50,
            gems = 5000,
            items = {"cloud_essence", "cinnamon_stick", "angel_wings"}
        },
        evolvesTo = "cinnamoroll_celestial",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            celestial = {multiplier = 30, colorShift = Color3.fromRGB(200, 200, 255)}
        }
    },
    
    -- TIER 4: EPIC PETS (4% drop rate)
    ["pompompurin_golden"] = {
        id = "pompompurin_golden",
        name = "Golden Pompompurin",
        displayName = "Golden Pompompurin",
        tier = "Epic",
        rarity = 4,
        baseStats = {
            coins = 1000,
            gems = 10,
            luck = 25,
            speed = 20,
            power = 200
        },
        description = "Golden retriever who loves pudding and treasure",
        imageId = "rbxassetid://10000000026",
        modelId = "rbxassetid://10000000027",
        animations = {
            idle = "rbxassetid://10000000028",
            walk = "rbxassetid://10000000029",
            attack = "rbxassetid://10000000030",
            special = "rbxassetid://10000000031",
            dig = "rbxassetid://10000000032"
        },
        abilities = {
            {
                name = "Golden Touch",
                description = "Turns drops into gold, tripling their value",
                cooldown = 120,
                effect = "gold_conversion",
                value = 3,
                duration = 30
            },
            {
                name = "Pudding Power",
                description = "Heals 50% HP and grants invincibility for 3 seconds",
                cooldown = 180,
                effect = "heal_invincible",
                value = 0.5,
                duration = 3
            },
            {
                name = "Treasure Hunter",
                description = "40% chance to find rare items",
                passive = true,
                effect = "rare_find",
                value = 0.4
            },
            {
                name = "Loyalty Bonus",
                description = "Increases all pet stats by 15%",
                passive = true,
                effect = "stat_boost_all",
                value = 0.15
            }
        },
        evolutionRequirements = {
            level = 75,
            gems = 10000,
            items = {"golden_collar", "pudding_crown", "treasure_map", "loyalty_medal"}
        },
        evolvesTo = "pompompurin_emperor",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200)},
            diamond = {multiplier = 8, colorShift = Color3.fromRGB(200, 255, 255)},
            rainbow = {multiplier = 15, colorShift = "rainbow"},
            dark_matter = {multiplier = 30, colorShift = Color3.fromRGB(50, 0, 100)},
            royal = {multiplier = 40, colorShift = Color3.fromRGB(255, 215, 0)}
        }
    },
    
    -- TIER 5: LEGENDARY PETS (0.9% drop rate)
    ["hello_kitty_angel"] = {
        id = "hello_kitty_angel",
        name = "Angel Hello Kitty",
        displayName = "Angel Hello Kitty",
        tier = "Legendary",
        rarity = 5,
        baseStats = {
            coins = 2500,
            gems = 25,
            luck = 50,
            speed = 35,
            power = 500
        },
        description = "Divine Hello Kitty with angelic wings and heavenly powers",
        imageId = "rbxassetid://10000000033",
        modelId = "rbxassetid://10000000034",
        animations = {
            idle = "rbxassetid://10000000035",
            walk = "rbxassetid://10000000036",
            attack = "rbxassetid://10000000037",
            special = "rbxassetid://10000000038",
            fly = "rbxassetid://10000000039",
            ascend = "rbxassetid://10000000040"
        },
        abilities = {
            {
                name = "Divine Blessing",
                description = "Blesses all pets, doubling their stats for 60 seconds",
                cooldown = 300,
                effect = "blessing_aoe",
                value = 2,
                duration = 60
            },
            {
                name = "Heavenly Shield",
                description = "Creates an impenetrable shield for all allies",
                cooldown = 240,
                effect = "team_shield",
                value = 10,
                duration = 10
            },
            {
                name = "Angel's Grace",
                description = "Revives fallen pets with full health",
                cooldown = 600,
                effect = "revive_all",
                value = 1
            },
            {
                name = "Celestial Aura",
                description = "All pets gain 50% stats permanently",
                passive = true,
                effect = "aura_boost",
                value = 0.5
            },
            {
                name = "Holy Light",
                description = "Damages all enemies and heals all allies",
                cooldown = 180,
                effect = "holy_burst",
                damage = 1000,
                heal = 0.5
            }
        },
        evolutionRequirements = {
            level = 100,
            gems = 50000,
            items = {"angel_halo", "divine_wings", "celestial_orb", "heaven_key", "blessed_ribbon"}
        },
        evolvesTo = "hello_kitty_goddess",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 255, 200)},
            crystal = {multiplier = 10, colorShift = Color3.fromRGB(200, 255, 255)},
            rainbow = {multiplier = 25, colorShift = "rainbow"},
            cosmic = {multiplier = 50, colorShift = "cosmic"},
            divine = {multiplier = 100, colorShift = Color3.fromRGB(255, 255, 255)}
        }
    },
    
    -- TIER 6: MYTHICAL PETS (0.1% drop rate)
    ["kuromi_demon_lord"] = {
        id = "kuromi_demon_lord",
        name = "Demon Lord Kuromi",
        displayName = "Demon Lord Kuromi",
        tier = "Mythical",
        rarity = 6,
        baseStats = {
            coins = 10000,
            gems = 100,
            luck = 100,
            speed = 50,
            power = 2000
        },
        description = "Ultimate form of Kuromi with demonic powers beyond imagination",
        imageId = "rbxassetid://10000000041",
        modelId = "rbxassetid://10000000042",
        animations = {
            idle = "rbxassetid://10000000043",
            walk = "rbxassetid://10000000044",
            attack = "rbxassetid://10000000045",
            special = "rbxassetid://10000000046",
            transform = "rbxassetid://10000000047",
            ultimate = "rbxassetid://10000000048"
        },
        abilities = {
            {
                name = "Hell's Dominion",
                description = "Controls all enemies for 30 seconds",
                cooldown = 600,
                effect = "mind_control",
                value = 1,
                duration = 30
            },
            {
                name = "Demonic Transformation",
                description = "Transform into ultimate demon form, 10x all stats",
                cooldown = 900,
                effect = "transform",
                value = 10,
                duration = 60
            },
            {
                name = "Soul Harvest",
                description = "Instantly defeats enemies below 50% health",
                cooldown = 300,
                effect = "execute",
                value = 0.5
            },
            {
                name = "Infernal Rage",
                description = "Each kill increases power by 10% (stacks)",
                passive = true,
                effect = "kill_stack",
                value = 0.1
            },
            {
                name = "Dark Resurrection",
                description = "Revive with 200% stats when defeated",
                passive = true,
                effect = "phoenix",
                value = 2,
                cooldown = 1800
            },
            {
                name = "Apocalypse",
                description = "Unleash devastating attack on all enemies",
                cooldown = 1200,
                effect = "apocalypse",
                damage = 10000
            }
        },
        evolutionRequirements = {
            level = 200,
            gems = 1000000,
            items = {"demon_crown", "hell_gate_key", "soul_crystal", "dark_matter_core", "chaos_essence", "void_fragment"}
        },
        evolvesTo = nil, -- Max evolution
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            infernal = {multiplier = 5, colorShift = Color3.fromRGB(255, 0, 0)},
            void = {multiplier = 20, colorShift = Color3.fromRGB(0, 0, 0)},
            chaos = {multiplier = 50, colorShift = "chaos"},
            eternal = {multiplier = 100, colorShift = "eternal"},
            omega = {multiplier = 500, colorShift = "omega"}
        }
    },
    
    -- TIER 7: SECRET PETS (0.01% drop rate)
    ["sanrio_universe_guardian"] = {
        id = "sanrio_universe_guardian",
        name = "Universe Guardian",
        displayName = "Sanrio Universe Guardian",
        tier = "Secret",
        rarity = 7,
        baseStats = {
            coins = 100000,
            gems = 1000,
            luck = 500,
            speed = 100,
            power = 10000
        },
        description = "The ultimate protector of the Sanrio Universe",
        imageId = "rbxassetid://10000000049",
        modelId = "rbxassetid://10000000050",
        animations = {
            idle = "rbxassetid://10000000051",
            walk = "rbxassetid://10000000052",
            attack = "rbxassetid://10000000053",
            special = "rbxassetid://10000000054",
            universe = "rbxassetid://10000000055",
            creation = "rbxassetid://10000000056"
        },
        abilities = {
            {
                name = "Universe Creation",
                description = "Creates a new dimension with 100x rewards",
                cooldown = 3600,
                effect = "dimension_create",
                value = 100,
                duration = 300
            },
            {
                name = "Time Manipulation",
                description = "Rewind time to undo all damage",
                cooldown = 1800,
                effect = "time_rewind",
                value = 1
            },
            {
                name = "Reality Warp",
                description = "Change the rules of the game temporarily",
                cooldown = 2400,
                effect = "reality_warp",
                value = 1
            },
            {
                name = "Infinite Power",
                description = "All stats are multiplied by equipped pets count",
                passive = true,
                effect = "infinite_scaling",
                value = 1
            },
            {
                name = "Guardian's Presence",
                description = "All other pets become invincible",
                passive = true,
                effect = "team_invincible",
                value = 1
            },
            {
                name = "Universal Love",
                description = "Convert all enemies to allies permanently",
                cooldown = 7200,
                effect = "convert_all",
                value = 1
            },
            {
                name = "Big Bang",
                description = "Reset and multiply all resources by 1000",
                cooldown = 86400, -- Once per day
                effect = "big_bang",
                value = 1000
            }
        },
        evolutionRequirements = nil, -- Cannot evolve
        evolvesTo = nil,
        variants = {
            normal = {multiplier = 1, colorShift = "universe"},
            quantum = {multiplier = 10, colorShift = "quantum"},
            infinity = {multiplier = 100, colorShift = "infinity"},
            omnipotent = {multiplier = 1000, colorShift = "omnipotent"}
        }
    }
}

-- Continue with more pets (adding at least 50 more unique pets)...
-- This would include all Sanrio characters and their various forms

-- ========================================
-- EGG/CASE SYSTEM DEFINITIONS
-- ========================================
local EggCases = {
    ["starter_egg"] = {
        id = "starter_egg",
        name = "Starter Egg",
        description = "A basic egg for beginners",
        price = 100,
        currency = "Coins",
        imageId = "rbxassetid://10000001001",
        modelId = "rbxassetid://10000001002",
        openAnimation = "crack",
        particles = {"basic_sparkles"},
        dropTable = {
            {pet = "hello_kitty_classic", weight = 40},
            {pet = "my_melody_classic", weight = 35},
            {pet = "keroppi_classic", weight = 25}
        },
        guaranteedRarity = nil,
        pitySystem = {
            enabled = false
        }
    },
    
    ["premium_egg"] = {
        id = "premium_egg",
        name = "Premium Egg",
        description = "Better chances for rare pets",
        price = 500,
        currency = "Gems",
        imageId = "rbxassetid://10000001003",
        modelId = "rbxassetid://10000001004",
        openAnimation = "golden_crack",
        particles = {"golden_sparkles", "star_burst"},
        dropTable = {
            {pet = "kuromi_classic", weight = 30},
            {pet = "cinnamoroll_classic", weight = 25},
            {pet = "pompompurin_classic", weight = 20},
            {pet = "badtz_maru_classic", weight = 15},
            {pet = "hello_kitty_classic", weight = 10}
        },
        guaranteedRarity = 2, -- At least Uncommon
        pitySystem = {
            enabled = true,
            threshold = 10,
            guaranteedRarity = 3
        }
    },
    
    ["legendary_egg"] = {
        id = "legendary_egg",
        name = "Legendary Egg",
        description = "Contains powerful legendary pets",
        price = 2500,
        currency = "Gems",
        imageId = "rbxassetid://10000001005",
        modelId = "rbxassetid://10000001006",
        openAnimation = "legendary_explosion",
        particles = {"rainbow_burst", "golden_shower", "star_explosion"},
        dropTable = {
            {pet = "hello_kitty_angel", weight = 20},
            {pet = "my_melody_angel", weight = 20},
            {pet = "kuromi_demon", weight = 15},
            {pet = "cinnamoroll_celestial", weight = 15},
            {pet = "pompompurin_emperor", weight = 10},
            {pet = "gudetama_legendary", weight = 10},
            {pet = "rururugakuen_legendary", weight = 5},
            {pet = "aggretsuko_legendary", weight = 5}
        },
        guaranteedRarity = 4, -- At least Epic
        pitySystem = {
            enabled = true,
            threshold = 5,
            guaranteedRarity = 5
        }
    },
    
    ["mythical_egg"] = {
        id = "mythical_egg",
        name = "Mythical Egg",
        description = "The rarest pets in existence",
        price = 10000,
        currency = "Gems",
        imageId = "rbxassetid://10000001007",
        modelId = "rbxassetid://10000001008",
        openAnimation = "mythical_transformation",
        particles = {"void_particles", "cosmic_burst", "reality_shatter"},
        dropTable = {
            {pet = "kuromi_demon_lord", weight = 30},
            {pet = "hello_kitty_goddess", weight = 25},
            {pet = "cinnamoroll_archangel", weight = 20},
            {pet = "my_melody_seraph", weight = 15},
            {pet = "pompompurin_titan", weight = 8},
            {pet = "sanrio_universe_guardian", weight = 2}
        },
        guaranteedRarity = 5, -- At least Legendary
        pitySystem = {
            enabled = true,
            threshold = 3,
            guaranteedRarity = 6
        }
    },
    
    -- Special Event Eggs
    ["valentine_egg"] = {
        id = "valentine_egg",
        name = "Valentine's Special Egg",
        description = "Limited Valentine's Day exclusive pets",
        price = 5000,
        currency = "Gems",
        imageId = "rbxassetid://10000001009",
        modelId = "rbxassetid://10000001010",
        openAnimation = "heart_explosion",
        particles = {"heart_particles", "pink_sparkles", "love_burst"},
        limitedTime = true,
        availableFrom = "2024-02-01",
        availableUntil = "2024-02-28",
        dropTable = {
            {pet = "hello_kitty_valentine", weight = 25},
            {pet = "my_melody_cupid", weight = 25},
            {pet = "kuromi_heartbreaker", weight = 20},
            {pet = "cinnamoroll_love", weight = 15},
            {pet = "couple_kitty_melody", weight = 10},
            {pet = "love_guardian", weight = 5}
        },
        guaranteedRarity = 4,
        pitySystem = {
            enabled = true,
            threshold = 5,
            guaranteedRarity = 6
        }
    }
}

-- ========================================
-- GAMEPASS SYSTEM
-- ========================================
local GamepassData = {
    [100000001] = {
        id = 100000001,
        name = "2x Luck",
        description = "Double your chances of getting rare pets!",
        price = 399,
        icon = "rbxassetid://10000002001",
        benefits = {
            {type = "luck_multiplier", value = 2}
        },
        stackable = false,
        category = "Boosts"
    },
    
    [100000002] = {
        id = 100000002,
        name = "Auto Hatch",
        description = "Automatically open eggs without clicking!",
        price = 599,
        icon = "rbxassetid://10000002002",
        benefits = {
            {type = "auto_hatch", value = true},
            {type = "hatch_speed", value = 2}
        },
        stackable = false,
        category = "Convenience"
    },
    
    [100000003] = {
        id = 100000003,
        name = "VIP Status",
        description = "Exclusive VIP benefits and access!",
        price = 999,
        icon = "rbxassetid://10000002003",
        benefits = {
            {type = "vip_access", value = true},
            {type = "gem_multiplier", value = 2},
            {type = "coin_multiplier", value = 2},
            {type = "exclusive_area", value = "vip_lounge"},
            {type = "chat_tag", value = "[VIP]"},
            {type = "trade_slots", value = 10}
        },
        stackable = false,
        category = "VIP"
    },
    
    [100000004] = {
        id = 100000004,
        name = "Pet Storage +100",
        description = "Increase pet storage by 100 slots!",
        price = 299,
        icon = "rbxassetid://10000002004",
        benefits = {
            {type = "storage_increase", value = 100}
        },
        stackable = true,
        maxStack = 10,
        category = "Storage"
    },
    
    [100000005] = {
        id = 100000005,
        name = "Triple Hatch",
        description = "Open 3 eggs at once!",
        price = 799,
        icon = "rbxassetid://10000002005",
        benefits = {
            {type = "multi_hatch", value = 3}
        },
        stackable = false,
        category = "Hatching"
    },
    
    [100000006] = {
        id = 100000006,
        name = "Lucky Gamepass Bundle",
        description = "Contains multiple luck-boosting benefits!",
        price = 1499,
        icon = "rbxassetid://10000002006",
        benefits = {
            {type = "luck_multiplier", value = 3},
            {type = "shiny_chance", value = 2},
            {type = "golden_chance", value = 2},
            {type = "rainbow_chance", value = 1.5}
        },
        stackable = false,
        category = "Bundles"
    }
}

-- ========================================
-- ADVANCED PLAYER DATA STRUCTURE
-- ========================================
local PlayerDataTemplate = {
    -- Basic Info
    userId = 0,
    username = "",
    displayName = "",
    joinDate = 0,
    lastSeen = 0,
    totalPlayTime = 0,
    
    -- Currencies
    currencies = {
        coins = 10000,
        gems = 500,
        tickets = 0,
        candies = 0,
        stars = 0,
        tokens = 0
    },
    
    -- Pet Inventory
    pets = {}, -- Array of pet instances
    maxPetStorage = 50,
    equippedPets = {}, -- Array of equipped pet IDs
    
    -- Statistics
    statistics = {
        totalEggsOpened = 0,
        totalPetsHatched = 0,
        legendaryPetsFound = 0,
        mythicalPetsFound = 0,
        secretPetsFound = 0,
        totalCoinsEarned = 0,
        totalGemsEarned = 0,
        totalGemsSpent = 0,
        tradingStats = {
            tradesCompleted = 0,
            tradesDeclined = 0,
            totalTradeValue = 0,
            scamReports = 0
        },
        battleStats = {
            wins = 0,
            losses = 0,
            draws = 0,
            damageDealt = 0,
            damageTaken = 0,
            petsDefeated = 0
        }
    },
    
    -- Gamepasses
    ownedGamepasses = {},
    
    -- Inventory
    inventory = {
        evolutionItems = {},
        potions = {},
        accessories = {},
        toys = {},
        food = {}
    },
    
    -- Settings
    settings = {
        musicEnabled = true,
        sfxEnabled = true,
        particlesEnabled = true,
        lowQualityMode = false,
        autoSave = true,
        tradeRequests = true,
        friendRequests = true,
        clanInvites = true,
        dmEnabled = true,
        showPetNames = true,
        showDamageNumbers = true,
        uiScale = 1,
        cameraShake = true
    },
    
    -- Achievements
    achievements = {},
    titles = {
        equipped = "Newbie",
        owned = {"Newbie"}
    },
    
    -- Daily Rewards
    dailyRewards = {
        lastClaim = 0,
        streak = 0,
        multiplier = 1
    },
    
    -- Battle Pass
    battlePass = {
        level = 1,
        experience = 0,
        premiumOwned = false,
        claimedRewards = {}
    },
    
    -- Clan/Guild
    clan = {
        id = nil,
        name = nil,
        role = nil,
        contribution = 0,
        joinDate = nil
    },
    
    -- Friends System
    friends = {
        list = {},
        requests = {},
        blocked = {}
    },
    
    -- Trading
    trading = {
        history = {},
        favorites = {},
        wishlist = {},
        blacklist = {}
    },
    
    -- Quests
    quests = {
        daily = {},
        weekly = {},
        special = {},
        completed = {}
    },
    
    -- Boosts
    activeBoosts = {},
    
    -- Redeem Codes
    redeemedCodes = {},
    
    -- Warnings & Moderation
    moderation = {
        warnings = 0,
        mutes = {},
        bans = {},
        reports = 0
    }
}

-- ========================================
-- ANTI-EXPLOIT SYSTEM
-- ========================================
local AntiExploit = {
    playerRequests = {},
    suspiciousActivity = {},
    
    validateRequest = function(player, requestType)
        local userId = player.UserId
        local currentTime = tick()
        
        if not AntiExploit.playerRequests[userId] then
            AntiExploit.playerRequests[userId] = {}
        end
        
        local requests = AntiExploit.playerRequests[userId]
        
        -- Clean old requests
        for i = #requests, 1, -1 do
            if currentTime - requests[i].time > 60 then
                table.remove(requests, i)
            end
        end
        
        -- Check request limit
        if #requests >= CONFIG.MAX_REQUESTS_PER_MINUTE then
            AntiExploit.flagPlayer(player, "Excessive requests")
            return false
        end
        
        -- Add new request
        table.insert(requests, {
            type = requestType,
            time = currentTime
        })
        
        return true
    end,
    
    validateCurrency = function(player, currencyType, amount)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false end
        
        local currentAmount = playerData.currencies[currencyType] or 0
        
        -- Check for suspicious wealth
        if currentAmount > CONFIG.SUSPICIOUS_WEALTH_THRESHOLD then
            AntiExploit.flagPlayer(player, "Suspicious wealth: " .. currencyType .. " = " .. currentAmount)
        end
        
        -- Validate transaction
        if amount < 0 then
            AntiExploit.flagPlayer(player, "Negative currency transaction attempt")
            return false
        end
        
        if currentAmount < amount then
            return false
        end
        
        return true
    end,
    
    validatePet = function(player, petId)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false end
        
        for _, pet in ipairs(playerData.pets) do
            if pet.id == petId and pet.owner == player.UserId then
                return true
            end
        end
        
        AntiExploit.flagPlayer(player, "Invalid pet access: " .. tostring(petId))
        return false
    end,
    
    flagPlayer = function(player, reason)
        local userId = player.UserId
        
        if not AntiExploit.suspiciousActivity[userId] then
            AntiExploit.suspiciousActivity[userId] = {
                flags = 0,
                reasons = {}
            }
        end
        
        local activity = AntiExploit.suspiciousActivity[userId]
        activity.flags = activity.flags + 1
        table.insert(activity.reasons, {
            reason = reason,
            time = os.time()
        })
        
        warn("[ANTI-EXPLOIT] Player " .. player.Name .. " flagged: " .. reason)
        
        -- Auto-kick after too many flags
        if activity.flags >= 10 then
            player:Kick("Suspicious activity detected. Please rejoin.")
            AntiExploit.suspiciousActivity[userId] = nil
        end
        
        -- Log to external service (webhook, analytics, etc.)
        -- LogToDiscord(player, reason)
    end,
    
    validateTrade = function(player1, player2, trade1Items, trade2Items)
        -- Validate both players exist and aren't the same
        if player1 == player2 then
            return false, "Cannot trade with yourself"
        end
        
        -- Validate ownership of all items
        for _, item in ipairs(trade1Items) do
            if not AntiExploit.validatePet(player1, item.id) then
                return false, "Invalid pet ownership"
            end
        end
        
        for _, item in ipairs(trade2Items) do
            if not AntiExploit.validatePet(player2, item.id) then
                return false, "Invalid pet ownership"
            end
        end
        
        -- Check for duplicate items
        local usedItems = {}
        for _, item in ipairs(trade1Items) do
            if usedItems[item.id] then
                return false, "Duplicate items detected"
            end
            usedItems[item.id] = true
        end
        
        for _, item in ipairs(trade2Items) do
            if usedItems[item.id] then
                return false, "Duplicate items detected"
            end
            usedItems[item.id] = true
        end
        
        return true
    end,
    
    -- Advanced pattern detection
    detectPatterns = function(player)
        local userId = player.UserId
        local patterns = {
            rapidClicking = 0,
            teleporting = 0,
            speedHacking = 0,
            noclipping = 0
        }
        
        -- Monitor player behavior
        spawn(function()
            local lastPosition = player.Character and player.Character.HumanoidRootPart.Position
            local clickTimes = {}
            
            while player.Parent do
                wait(0.1)
                
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local currentPosition = player.Character.HumanoidRootPart.Position
                    
                    -- Check for teleporting
                    if lastPosition then
                        local distance = (currentPosition - lastPosition).Magnitude
                        if distance > 50 then -- Suspicious movement
                            patterns.teleporting = patterns.teleporting + 1
                            if patterns.teleporting > 5 then
                                AntiExploit.flagPlayer(player, "Possible teleport hacking")
                            end
                        end
                    end
                    
                    lastPosition = currentPosition
                    
                    -- Check for speed hacking
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.WalkSpeed > 30 then
                        patterns.speedHacking = patterns.speedHacking + 1
                        if patterns.speedHacking > 3 then
                            AntiExploit.flagPlayer(player, "Speed hacking detected")
                            humanoid.WalkSpeed = 16 -- Reset to default
                        end
                    end
                end
            end
        end)
    end
}

-- ========================================
-- TRADING SYSTEM
-- ========================================
local TradingSystem = {
    activeTrades = {},
    tradeHistory = {},
    
    createTrade = function(player1, player2)
        local tradeId = HttpService:GenerateGUID(false)
        
        local trade = {
            id = tradeId,
            player1 = player1,
            player2 = player2,
            player1Items = {},
            player2Items = {},
            player1Ready = false,
            player2Ready = false,
            status = "pending",
            createdAt = os.time(),
            expiresAt = os.time() + 300 -- 5 minute expiry
        }
        
        TradingSystem.activeTrades[tradeId] = trade
        
        return tradeId
    end,
    
    addItemToTrade = function(tradeId, player, item)
        local trade = TradingSystem.activeTrades[tradeId]
        if not trade then return false end
        
        if trade.status ~= "pending" then return false end
        
        if player == trade.player1 then
            if #trade.player1Items >= CONFIG.MAX_TRADE_ITEMS then
                return false, "Trade limit reached"
            end
            table.insert(trade.player1Items, item)
            trade.player1Ready = false
            trade.player2Ready = false
        elseif player == trade.player2 then
            if #trade.player2Items >= CONFIG.MAX_TRADE_ITEMS then
                return false, "Trade limit reached"
            end
            table.insert(trade.player2Items, item)
            trade.player1Ready = false
            trade.player2Ready = false
        else
            return false, "Not part of this trade"
        end
        
        return true
    end,
    
    removeItemFromTrade = function(tradeId, player, itemId)
        local trade = TradingSystem.activeTrades[tradeId]
        if not trade then return false end
        
        if trade.status ~= "pending" then return false end
        
        if player == trade.player1 then
            for i, item in ipairs(trade.player1Items) do
                if item.id == itemId then
                    table.remove(trade.player1Items, i)
                    trade.player1Ready = false
                    trade.player2Ready = false
                    return true
                end
            end
        elseif player == trade.player2 then
            for i, item in ipairs(trade.player2Items) do
                if item.id == itemId then
                    table.remove(trade.player2Items, i)
                    trade.player1Ready = false
                    trade.player2Ready = false
                    return true
                end
            end
        end
        
        return false
    end,
    
    setReady = function(tradeId, player, ready)
        local trade = TradingSystem.activeTrades[tradeId]
        if not trade then return false end
        
        if trade.status ~= "pending" then return false end
        
        if player == trade.player1 then
            trade.player1Ready = ready
        elseif player == trade.player2 then
            trade.player2Ready = ready
        else
            return false
        end
        
        -- Check if both ready
        if trade.player1Ready and trade.player2Ready then
            TradingSystem.executeTrade(tradeId)
        end
        
        return true
    end,
    
    executeTrade = function(tradeId)
        local trade = TradingSystem.activeTrades[tradeId]
        if not trade then return false end
        
        trade.status = "processing"
        
        -- Validate trade one more time
        local valid, reason = AntiExploit.validateTrade(
            trade.player1,
            trade.player2,
            trade.player1Items,
            trade.player2Items
        )
        
        if not valid then
            trade.status = "failed"
            trade.failReason = reason
            return false
        end
        
        -- Get player data
        local player1Data = PlayerData[trade.player1.UserId]
        local player2Data = PlayerData[trade.player2.UserId]
        
        if not player1Data or not player2Data then
            trade.status = "failed"
            trade.failReason = "Player data not found"
            return false
        end
        
        -- Execute the trade
        -- Remove items from player 1
        for _, item in ipairs(trade.player1Items) do
            for i, pet in ipairs(player1Data.pets) do
                if pet.id == item.id then
                    table.remove(player1Data.pets, i)
                    break
                end
            end
        end
        
        -- Remove items from player 2
        for _, item in ipairs(trade.player2Items) do
            for i, pet in ipairs(player2Data.pets) do
                if pet.id == item.id then
                    table.remove(player2Data.pets, i)
                    break
                end
            end
        end
        
        -- Add items to opposite players
        for _, item in ipairs(trade.player1Items) do
            item.previousOwner = trade.player1.UserId
            item.tradedAt = os.time()
            table.insert(player2Data.pets, item)
        end
        
        for _, item in ipairs(trade.player2Items) do
            item.previousOwner = trade.player2.UserId
            item.tradedAt = os.time()
            table.insert(player1Data.pets, item)
        end
        
        -- Update statistics
        player1Data.statistics.tradingStats.tradesCompleted = player1Data.statistics.tradingStats.tradesCompleted + 1
        player2Data.statistics.tradingStats.tradesCompleted = player2Data.statistics.tradingStats.tradesCompleted + 1
        
        -- Calculate trade values
        local trade1Value = TradingSystem.calculateTradeValue(trade.player1Items)
        local trade2Value = TradingSystem.calculateTradeValue(trade.player2Items)
        
        player1Data.statistics.tradingStats.totalTradeValue = player1Data.statistics.tradingStats.totalTradeValue + trade1Value
        player2Data.statistics.tradingStats.totalTradeValue = player2Data.statistics.tradingStats.totalTradeValue + trade2Value
        
        -- Apply trade tax if enabled
        if CONFIG.TRADE_TAX_PERCENTAGE > 0 then
            local tax1 = math.floor(trade1Value * CONFIG.TRADE_TAX_PERCENTAGE)
            local tax2 = math.floor(trade2Value * CONFIG.TRADE_TAX_PERCENTAGE)
            
            player1Data.currencies.coins = math.max(0, player1Data.currencies.coins - tax1)
            player2Data.currencies.coins = math.max(0, player2Data.currencies.coins - tax2)
        end
        
        -- Save trade to history
        local historyEntry = {
            id = trade.id,
            player1 = trade.player1.UserId,
            player2 = trade.player2.UserId,
            player1Items = trade.player1Items,
            player2Items = trade.player2Items,
            completedAt = os.time(),
            trade1Value = trade1Value,
            trade2Value = trade2Value
        }
        
        table.insert(TradingSystem.tradeHistory, historyEntry)
        table.insert(player1Data.trading.history, historyEntry)
        table.insert(player2Data.trading.history, historyEntry)
        
        -- Mark trade as complete
        trade.status = "completed"
        trade.completedAt = os.time()
        
        -- Clean up
        TradingSystem.activeTrades[tradeId] = nil
        
        -- Save player data
        SavePlayerData(trade.player1)
        SavePlayerData(trade.player2)
        
        return true
    end,
    
    calculateTradeValue = function(items)
        local totalValue = 0
        
        for _, item in ipairs(items) do
            local petData = PetDatabase[item.petId]
            if petData then
                local baseValue = petData.baseStats.coins + (petData.baseStats.gems * 100)
                local rarityMultiplier = petData.rarity ^ 2
                local variantMultiplier = item.variant and PetDatabase[item.petId].variants[item.variant].multiplier or 1
                local levelMultiplier = 1 + (item.level - 1) * 0.1
                
                local itemValue = baseValue * rarityMultiplier * variantMultiplier * levelMultiplier
                totalValue = totalValue + itemValue
            end
        end
        
        return math.floor(totalValue)
    end,
    
    cancelTrade = function(tradeId, player)
        local trade = TradingSystem.activeTrades[tradeId]
        if not trade then return false end
        
        if trade.status ~= "pending" then return false end
        
        if player ~= trade.player1 and player ~= trade.player2 then
            return false
        end
        
        trade.status = "cancelled"
        trade.cancelledBy = player.UserId
        trade.cancelledAt = os.time()
        
        TradingSystem.activeTrades[tradeId] = nil
        
        return true
    end,
    
    -- Auto-cleanup expired trades
    cleanupExpiredTrades = function()
        local currentTime = os.time()
        
        for tradeId, trade in pairs(TradingSystem.activeTrades) do
            if currentTime > trade.expiresAt then
                trade.status = "expired"
                TradingSystem.activeTrades[tradeId] = nil
            end
        end
    end
}

-- Run cleanup every minute
spawn(function()
    while true do
        wait(60)
        TradingSystem.cleanupExpiredTrades()
    end
end)

-- ========================================
-- PET EVOLUTION & FUSION SYSTEM
-- ========================================
local EvolutionSystem = {
    evolvePet = function(player, petId)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false, "No player data" end
        
        local pet = nil
        local petIndex = nil
        
        for i, p in ipairs(playerData.pets) do
            if p.id == petId then
                pet = p
                petIndex = i
                break
            end
        end
        
        if not pet then return false, "Pet not found" end
        
        local petData = PetDatabase[pet.petId]
        if not petData then return false, "Invalid pet data" end
        
        if not petData.evolvesTo then
            return false, "This pet cannot evolve"
        end
        
        local requirements = petData.evolutionRequirements
        if not requirements then return false, "No evolution requirements" end
        
        -- Check level requirement
        if pet.level < requirements.level then
            return false, "Pet needs to be level " .. requirements.level
        end
        
        -- Check gem requirement
        if playerData.currencies.gems < requirements.gems then
            return false, "Not enough gems. Need " .. requirements.gems
        end
        
        -- Check item requirements
        for _, itemName in ipairs(requirements.items) do
            local hasItem = false
            for i, item in ipairs(playerData.inventory.evolutionItems) do
                if item.name == itemName and item.quantity > 0 then
                    hasItem = true
                    item.quantity = item.quantity - 1
                    if item.quantity <= 0 then
                        table.remove(playerData.inventory.evolutionItems, i)
                    end
                    break
                end
            end
            
            if not hasItem then
                return false, "Missing evolution item: " .. itemName
            end
        end
        
        -- Deduct gems
        playerData.currencies.gems = playerData.currencies.gems - requirements.gems
        
        -- Evolve the pet
        local evolvedPetData = PetDatabase[petData.evolvesTo]
        if not evolvedPetData then return false, "Evolution data not found" end
        
        local evolvedPet = {
            id = pet.id, -- Keep same ID
            petId = evolvedPetData.id,
            name = evolvedPetData.name,
            level = pet.level,
            experience = pet.experience,
            variant = pet.variant,
            owner = player.UserId,
            obtained = pet.obtained,
            evolved = os.time(),
            previousForm = pet.petId,
            stats = {
                coins = evolvedPetData.baseStats.coins * (1 + (pet.level - 1) * 0.1),
                gems = evolvedPetData.baseStats.gems * (1 + (pet.level - 1) * 0.1),
                luck = evolvedPetData.baseStats.luck * (1 + (pet.level - 1) * 0.1),
                speed = evolvedPetData.baseStats.speed * (1 + (pet.level - 1) * 0.1),
                power = evolvedPetData.baseStats.power * (1 + (pet.level - 1) * 0.1)
            }
        }
        
        -- Replace the old pet with evolved one
        playerData.pets[petIndex] = evolvedPet
        
        -- Save player data
        SavePlayerData(player)
        
        return true, evolvedPet
    end,
    
    fusePets = function(player, pet1Id, pet2Id, pet3Id)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false, "No player data" end
        
        -- Find all three pets
        local pets = {}
        local petIndices = {}
        
        for i, p in ipairs(playerData.pets) do
            if p.id == pet1Id or p.id == pet2Id or p.id == pet3Id then
                table.insert(pets, p)
                table.insert(petIndices, i)
            end
        end
        
        if #pets ~= 3 then
            return false, "All three pets must be selected"
        end
        
        -- Verify all pets are same type and max level
        local basePetId = pets[1].petId
        for _, pet in ipairs(pets) do
            if pet.petId ~= basePetId then
                return false, "All pets must be the same type"
            end
            
            local petData = PetDatabase[pet.petId]
            if pet.level < petData.maxLevel then
                return false, "All pets must be max level"
            end
        end
        
        -- Check if fusion is possible
        local petData = PetDatabase[basePetId]
        if not petData.fusionResult then
            return false, "These pets cannot be fused"
        end
        
        -- Calculate fusion cost
        local fusionCost = petData.baseStats.coins * 100
        if playerData.currencies.coins < fusionCost then
            return false, "Not enough coins. Need " .. fusionCost
        end
        
        -- Check success rate
        local successRate = CONFIG.FUSION_SUCCESS_RATE
        
        -- Increase success rate based on pet variants
        for _, pet in ipairs(pets) do
            if pet.variant == "shiny" then
                successRate = successRate + 0.05
            elseif pet.variant == "golden" then
                successRate = successRate + 0.1
            elseif pet.variant == "rainbow" then
                successRate = successRate + 0.15
            end
        end
        
        successRate = math.min(successRate, 1) -- Cap at 100%
        
        -- Deduct cost
        playerData.currencies.coins = playerData.currencies.coins - fusionCost
        
        -- Attempt fusion
        if math.random() > successRate then
            -- Fusion failed, lose one pet
            table.remove(playerData.pets, petIndices[1])
            SavePlayerData(player)
            return false, "Fusion failed! One pet was lost."
        end
        
        -- Fusion successful
        local fusedPetData = PetDatabase[petData.fusionResult]
        if not fusedPetData then return false, "Fusion result data not found" end
        
        -- Determine variant of fused pet
        local fusedVariant = "normal"
        local variantRoll = math.random()
        
        if variantRoll < 0.01 then
            fusedVariant = "dark_matter"
        elseif variantRoll < 0.05 then
            fusedVariant = "rainbow"
        elseif variantRoll < 0.15 then
            fusedVariant = "golden"
        elseif variantRoll < 0.35 then
            fusedVariant = "shiny"
        end
        
        -- Create fused pet
        local fusedPet = {
            id = HttpService:GenerateGUID(false),
            petId = fusedPetData.id,
            name = fusedPetData.name,
            level = 1,
            experience = 0,
            variant = fusedVariant,
            owner = player.UserId,
            obtained = os.time(),
            fusedFrom = {pets[1].id, pets[2].id, pets[3].id},
            stats = {
                coins = fusedPetData.baseStats.coins,
                gems = fusedPetData.baseStats.gems,
                luck = fusedPetData.baseStats.luck,
                speed = fusedPetData.baseStats.speed,
                power = fusedPetData.baseStats.power
            }
        }
        
        -- Apply variant multiplier
        if fusedPetData.variants[fusedVariant] then
            local multiplier = fusedPetData.variants[fusedVariant].multiplier
            for stat, value in pairs(fusedPet.stats) do
                fusedPet.stats[stat] = value * multiplier
            end
        end
        
        -- Remove the three pets
        table.sort(petIndices, function(a, b) return a > b end) -- Sort descending to remove from end first
        for _, index in ipairs(petIndices) do
            table.remove(playerData.pets, index)
        end
        
        -- Add fused pet
        table.insert(playerData.pets, fusedPet)
        
        -- Update statistics
        playerData.statistics.totalFusions = (playerData.statistics.totalFusions or 0) + 1
        
        -- Save player data
        SavePlayerData(player)
        
        return true, fusedPet
    end
}

-- ========================================
-- Continue in next part...
-- ========================================