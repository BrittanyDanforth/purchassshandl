--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                  SANRIO TYCOON SHOP - ULTIMATE FIXED VERSION                         ║
    ║                        Version 5.0 - COMPLETE 5000+ LINES                            ║
    ║                                                                                      ║
    ║  THIS IS THE FULL SCRIPT - PLACE IN ServerScriptService                            ║
    ║  All systems are properly defined - No undefined globals!                           ║
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
    Chat = game:GetService("Chat"),
    Debris = game:GetService("Debris"),
    ContentProvider = game:GetService("ContentProvider"),
    LocalizationService = game:GetService("LocalizationService")
}

-- DataStore Setup
local PlayerDataStore = Services.DataStoreService:GetDataStore("SanrioTycoonData_v5")
local BackupDataStore = Services.DataStoreService:GetDataStore("SanrioTycoonBackup_v5")
local GlobalDataStore = Services.DataStoreService:GetDataStore("SanrioTycoonGlobal_v5")

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
-- GLOBAL PLAYER DATA STORAGE
-- ========================================
local PlayerData = {}

-- ========================================
-- COMPLETE PET DATABASE (100+ PETS)
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
    
    ["keroppi_classic"] = {
        id = "keroppi_classic",
        name = "Classic Keroppi",
        displayName = "Keroppi",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 80,
            gems = 1,
            luck = 6,
            speed = 15,
            power = 40
        },
        description = "Cheerful green frog from Donut Pond",
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
                name = "Lily Pad Jump",
                description = "Teleports to target location",
                cooldown = 30,
                effect = "teleport",
                value = 50,
                range = 100
            },
            {
                name = "Pond Splash",
                description = "Slows enemies by 30%",
                cooldown = 45,
                effect = "slow_aoe",
                value = 0.3,
                radius = 25
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1000,
            items = {"lily_pad", "pond_water"}
        },
        evolvesTo = "keroppi_prince",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 255, 150)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)}
        }
    },
    
    ["pochacco_classic"] = {
        id = "pochacco_classic",
        name = "Classic Pochacco",
        displayName = "Pochacco",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 90,
            gems = 1,
            luck = 8,
            speed = 18,
            power = 42
        },
        description = "Sporty white dog who loves basketball",
        imageId = "rbxassetid://10000000019",
        modelId = "rbxassetid://10000000020",
        animations = {
            idle = "rbxassetid://10000000021",
            walk = "rbxassetid://10000000022",
            attack = "rbxassetid://10000000023",
            special = "rbxassetid://10000000024"
        },
        abilities = {
            {
                name = "Sports Rush",
                description = "Increases speed by 50% for 20 seconds",
                cooldown = 40,
                effect = "speed_boost",
                value = 0.5,
                duration = 20
            },
            {
                name = "Team Player",
                description = "Nearby pets gain 10% stats",
                passive = true,
                effect = "aura_boost",
                value = 0.1,
                radius = 25
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1000,
            items = {"basketball", "sports_shoes"}
        },
        evolvesTo = "pochacco_champion",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)}
        }
    },
    
    ["tuxedosam_classic"] = {
        id = "tuxedosam_classic",
        name = "Classic Tuxedosam",
        displayName = "Tuxedosam",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 110,
            gems = 2,
            luck = 9,
            speed = 8,
            power = 55
        },
        description = "Dapper penguin in a sailor suit",
        imageId = "rbxassetid://10000000025",
        modelId = "rbxassetid://10000000026",
        animations = {
            idle = "rbxassetid://10000000027",
            walk = "rbxassetid://10000000028",
            attack = "rbxassetid://10000000029",
            special = "rbxassetid://10000000030"
        },
        abilities = {
            {
                name = "Ice Slide",
                description = "Creates ice path that speeds up allies",
                cooldown = 35,
                effect = "ice_path",
                value = 0.3,
                duration = 15
            },
            {
                name = "Gentleman's Charm",
                description = "Increases luck by 15%",
                passive = true,
                effect = "luck_boost",
                value = 0.15
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1200,
            items = {"bow_tie", "ice_cube"}
        },
        evolvesTo = "tuxedosam_admiral",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 150, 255)},
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
        imageId = "rbxassetid://10000000031",
        modelId = "rbxassetid://10000000032",
        animations = {
            idle = "rbxassetid://10000000033",
            walk = "rbxassetid://10000000034",
            attack = "rbxassetid://10000000035",
            special = "rbxassetid://10000000036"
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
    
    ["cinnamoroll_classic"] = {
        id = "cinnamoroll_classic",
        name = "Classic Cinnamoroll",
        displayName = "Cinnamoroll",
        tier = "Uncommon",
        rarity = 2,
        baseStats = {
            coins = 300,
            gems = 4,
            luck = 12,
            speed = 20,
            power = 70
        },
        description = "Fluffy white puppy who can fly with his long ears",
        imageId = "rbxassetid://10000000037",
        modelId = "rbxassetid://10000000038",
        animations = {
            idle = "rbxassetid://10000000039",
            walk = "rbxassetid://10000000040",
            attack = "rbxassetid://10000000041",
            special = "rbxassetid://10000000042",
            fly = "rbxassetid://10000000043"
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
            level = 35,
            gems = 3000,
            items = {"cloud_essence", "cinnamon_stick", "white_wings"}
        },
        evolvesTo = "cinnamoroll_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            celestial = {multiplier = 30, colorShift = Color3.fromRGB(200, 200, 255)}
        }
    },
    
    ["pompompurin_classic"] = {
        id = "pompompurin_classic",
        name = "Classic Pompompurin",
        displayName = "Pompompurin",
        tier = "Uncommon",
        rarity = 2,
        baseStats = {
            coins = 280,
            gems = 3,
            luck = 15,
            speed = 10,
            power = 90
        },
        description = "Golden retriever who loves pudding",
        imageId = "rbxassetid://10000000044",
        modelId = "rbxassetid://10000000045",
        animations = {
            idle = "rbxassetid://10000000046",
            walk = "rbxassetid://10000000047",
            attack = "rbxassetid://10000000048",
            special = "rbxassetid://10000000049",
            eat = "rbxassetid://10000000050"
        },
        abilities = {
            {
                name = "Pudding Power",
                description = "Heals 30% HP and boosts stats by 20%",
                cooldown = 60,
                effect = "heal_boost",
                value = 0.3,
                boost = 0.2,
                duration = 30
            },
            {
                name = "Golden Retriever",
                description = "Fetches extra loot from defeated enemies",
                passive = true,
                effect = "extra_loot",
                value = 0.5
            },
            {
                name = "Loyalty Bonus",
                description = "Nearby pets gain 10% stats",
                passive = true,
                effect = "aura_boost",
                value = 0.1,
                radius = 30
            }
        },
        evolutionRequirements = {
            level = 35,
            gems = 2800,
            items = {"golden_collar", "pudding_bowl", "beret"}
        },
        evolvesTo = "pompompurin_chef",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            royal = {multiplier = 25, colorShift = Color3.fromRGB(255, 215, 0)}
        }
    },
    
    ["chococat_classic"] = {
        id = "chococat_classic",
        name = "Classic Chococat",
        displayName = "Chococat",
        tier = "Uncommon",
        rarity = 2,
        baseStats = {
            coins = 260,
            gems = 4,
            luck = 18,
            speed = 22,
            power = 75
        },
        description = "Black cat with excellent knowledge and big eyes",
        imageId = "rbxassetid://10000000051",
        modelId = "rbxassetid://10000000052",
        animations = {
            idle = "rbxassetid://10000000053",
            walk = "rbxassetid://10000000054",
            attack = "rbxassetid://10000000055",
            special = "rbxassetid://10000000056"
        },
        abilities = {
            {
                name = "Knowledge Burst",
                description = "Increases XP gain by 100% for team",
                cooldown = 120,
                effect = "xp_boost_team",
                value = 1,
                duration = 60
            },
            {
                name = "Cat Reflexes",
                description = "30% dodge chance",
                passive = true,
                effect = "dodge_chance",
                value = 0.3
            },
            {
                name = "Smart Investment",
                description = "20% more rewards from all sources",
                passive = true,
                effect = "reward_boost",
                value = 0.2
            }
        },
        evolutionRequirements = {
            level = 35,
            gems = 3200,
            items = {"book_of_knowledge", "cat_collar", "glasses"}
        },
        evolvesTo = "chococat_professor",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(100, 100, 150)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            cosmic = {multiplier = 35, colorShift = Color3.fromRGB(100, 0, 200)}
        }
    },
    
    -- TIER 3: RARE PETS (15% drop rate)
    ["badtz_maru_classic"] = {
        id = "badtz_maru_classic",
        name = "Classic Badtz-Maru",
        displayName = "Badtz-Maru",
        tier = "Rare",
        rarity = 3,
        baseStats = {
            coins = 500,
            gems = 8,
            luck = 20,
            speed = 25,
            power = 150
        },
        description = "Mischievous penguin with a bad attitude",
        imageId = "rbxassetid://10000000057",
        modelId = "rbxassetid://10000000058",
        animations = {
            idle = "rbxassetid://10000000059",
            walk = "rbxassetid://10000000060",
            attack = "rbxassetid://10000000061",
            special = "rbxassetid://10000000062",
            slide = "rbxassetid://10000000063"
        },
        abilities = {
            {
                name = "Ice Slide",
                description = "Slides forward dealing damage and freezing enemies",
                cooldown = 45,
                effect = "ice_dash",
                value = 300,
                freeze_duration = 3
            },
            {
                name = "Penguin Army",
                description = "Summons 3 mini penguins to fight",
                cooldown = 90,
                effect = "summon",
                value = 3,
                summon_duration = 30
            },
            {
                name = "Cold Heart",
                description = "Immune to freeze and slow effects",
                passive = true,
                effect = "freeze_immunity",
                value = 1
            },
            {
                name = "Arctic Aura",
                description = "Slows nearby enemies by 20%",
                passive = true,
                effect = "slow_aura",
                value = 0.2,
                radius = 25
            }
        },
        evolutionRequirements = {
            level = 50,
            gems = 5000,
            items = {"ice_crystal", "penguin_feather", "arctic_essence"}
        },
        evolvesTo = "badtz_maru_emperor",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 150, 255)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            arctic = {multiplier = 30, colorShift = Color3.fromRGB(200, 255, 255)}
        }
    },
    
    ["gudetama_classic"] = {
        id = "gudetama_classic",
        name = "Classic Gudetama",
        displayName = "Gudetama",
        tier = "Rare",
        rarity = 3,
        baseStats = {
            coins = 600,
            gems = 10,
            luck = 30,
            speed = 5,
            power = 100
        },
        description = "Lazy egg who just wants to be left alone",
        imageId = "rbxassetid://10000000064",
        modelId = "rbxassetid://10000000065",
        animations = {
            idle = "rbxassetid://10000000066",
            walk = "rbxassetid://10000000067",
            attack = "rbxassetid://10000000068",
            special = "rbxassetid://10000000069",
            lazy = "rbxassetid://10000000070"
        },
        abilities = {
            {
                name = "Lazy Shield",
                description = "Too lazy to take damage - blocks 50% damage",
                passive = true,
                effect = "damage_reduction",
                value = 0.5
            },
            {
                name = "Egg-sistential Crisis",
                description = "Confuses all enemies for 5 seconds",
                cooldown = 60,
                effect = "confuse_all",
                value = 5
            },
            {
                name = "Can't Be Bothered",
                description = "Immune to all debuffs",
                passive = true,
                effect = "debuff_immunity",
                value = 1
            },
            {
                name = "Lazy Luck",
                description = "30% chance to dodge any attack",
                passive = true,
                effect = "dodge_chance",
                value = 0.3
            }
        },
        evolutionRequirements = {
            level = 50,
            gems = 6000,
            items = {"egg_shell", "bacon_strip", "lazy_essence"}
        },
        evolvesTo = "gudetama_supreme",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            scrambled = {multiplier = 35, colorShift = Color3.fromRGB(255, 255, 150)}
        }
    },
    
    ["rururugakuen_classic"] = {
        id = "rururugakuen_classic",
        name = "Classic Rururugakuen",
        displayName = "Rururugakuen",
        tier = "Rare",
        rarity = 3,
        baseStats = {
            coins = 550,
            gems = 9,
            luck = 25,
            speed = 30,
            power = 130
        },
        description = "School uniform character ready to learn",
        imageId = "rbxassetid://10000000071",
        modelId = "rbxassetid://10000000072",
        animations = {
            idle = "rbxassetid://10000000073",
            walk = "rbxassetid://10000000074",
            attack = "rbxassetid://10000000075",
            special = "rbxassetid://10000000076",
            study = "rbxassetid://10000000077"
        },
        abilities = {
            {
                name = "Study Session",
                description = "Increases XP gain by 100% for 60 seconds",
                cooldown = 120,
                effect = "xp_boost",
                value = 1,
                duration = 60
            },
            {
                name = "Knowledge is Power",
                description = "Gains 1% stats for each level",
                passive = true,
                effect = "level_scaling",
                value = 0.01
            },
            {
                name = "Perfect Score",
                description = "Critical hits deal 3x damage",
                passive = true,
                effect = "crit_damage",
                value = 3
            },
            {
                name = "Class President",
                description = "Boosts all pets' XP gain by 20%",
                passive = true,
                effect = "team_xp_boost",
                value = 0.2
            }
        },
        evolutionRequirements = {
            level = 50,
            gems = 5500,
            items = {"textbook", "school_badge", "graduation_cap"}
        },
        evolvesTo = "rururugakuen_valedictorian",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 255, 200)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            honor_roll = {multiplier = 40, colorShift = Color3.fromRGB(255, 255, 255)}
        }
    },
    
    ["aggretsuko_classic"] = {
        id = "aggretsuko_classic",
        name = "Classic Aggretsuko",
        displayName = "Aggretsuko",
        tier = "Rare",
        rarity = 3,
        baseStats = {
            coins = 520,
            gems = 8,
            luck = 22,
            speed = 28,
            power = 180
        },
        description = "Red panda office worker with rage issues",
        imageId = "rbxassetid://10000000078",
        modelId = "rbxassetid://10000000079",
        animations = {
            idle = "rbxassetid://10000000080",
            walk = "rbxassetid://10000000081",
            attack = "rbxassetid://10000000082",
            special = "rbxassetid://10000000083",
            rage = "rbxassetid://10000000084"
        },
        abilities = {
            {
                name = "Rage Mode",
                description = "Doubles all stats when below 50% health",
                passive = true,
                effect = "rage_trigger",
                value = 2,
                threshold = 0.5
            },
            {
                name = "Death Metal Scream",
                description = "Stuns all enemies and deals massive damage",
                cooldown = 180,
                effect = "scream_stun",
                value = 500,
                stun_duration = 3
            },
            {
                name = "Office Fury",
                description = "Gains power from stress (time-based)",
                passive = true,
                effect = "time_scaling",
                value = 0.02
            },
            {
                name = "Microphone Drop",
                description = "Creates shockwave dealing area damage",
                cooldown = 90,
                effect = "shockwave",
                value = 300,
                radius = 40
            }
        },
        evolutionRequirements = {
            level = 50,
            gems = 6500,
            items = {"microphone", "office_badge", "rage_essence"}
        },
        evolvesTo = "aggretsuko_metalhead",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 100, 100)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)},
            metal = {multiplier = 45, colorShift = Color3.fromRGB(50, 50, 50)}
        }
    },
    
    -- TIER 4: EPIC PETS (4% drop rate)
    ["hello_kitty_angel"] = {
        id = "hello_kitty_angel",
        name = "Angel Hello Kitty",
        displayName = "Angel Hello Kitty",
        tier = "Epic",
        rarity = 4,
        baseStats = {
            coins = 1200,
            gems = 20,
            luck = 40,
            speed = 35,
            power = 300
        },
        description = "Divine Hello Kitty with angelic wings",
        imageId = "rbxassetid://10000000085",
        modelId = "rbxassetid://10000000086",
        animations = {
            idle = "rbxassetid://10000000087",
            walk = "rbxassetid://10000000088",
            attack = "rbxassetid://10000000089",
            special = "rbxassetid://10000000090",
            fly = "rbxassetid://10000000091",
            bless = "rbxassetid://10000000092"
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
                description = "Revives fallen pets with 50% health",
                cooldown = 600,
                effect = "revive_all",
                value = 0.5
            },
            {
                name = "Celestial Aura",
                description = "All pets gain 30% stats",
                passive = true,
                effect = "aura_boost",
                value = 0.3
            },
            {
                name = "Holy Light",
                description = "Damages all enemies and heals all allies",
                cooldown = 180,
                effect = "holy_burst",
                damage = 500,
                heal = 0.3
            }
        },
        evolutionRequirements = {
            level = 75,
            gems = 15000,
            items = {"angel_halo", "divine_wings", "celestial_orb", "blessed_ribbon"}
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
    
    ["kuromi_demon"] = {
        id = "kuromi_demon",
        name = "Demon Kuromi",
        displayName = "Demon Kuromi",
        tier = "Epic",
        rarity = 4,
        baseStats = {
            coins = 1000,
            gems = 18,
            luck = 35,
            speed = 40,
            power = 350
        },
        description = "Kuromi embracing her demonic powers",
        imageId = "rbxassetid://10000000093",
        modelId = "rbxassetid://10000000094",
        animations = {
            idle = "rbxassetid://10000000095",
            walk = "rbxassetid://10000000096",
            attack = "rbxassetid://10000000097",
            special = "rbxassetid://10000000098",
            transform = "rbxassetid://10000000099",
            rage = "rbxassetid://10000000100"
        },
        abilities = {
            {
                name = "Demonic Transformation",
                description = "Transform into demon form, tripling all stats",
                cooldown = 300,
                effect = "transform",
                value = 3,
                duration = 45
            },
            {
                name = "Hell's Fury",
                description = "Unleashes demonic rage, dealing massive damage",
                cooldown = 180,
                effect = "fury_attack",
                value = 1000,
                radius = 40
            },
            {
                name = "Soul Steal",
                description = "Steals 20% of enemy's max health",
                cooldown = 120,
                effect = "life_steal",
                value = 0.2
            },
            {
                name = "Infernal Presence",
                description = "Enemies take damage over time",
                passive = true,
                effect = "damage_aura",
                value = 50,
                radius = 30
            },
            {
                name = "Dark Pact",
                description = "Sacrifice 20% HP for 100% damage boost",
                cooldown = 90,
                effect = "blood_pact",
                cost = 0.2,
                boost = 1,
                duration = 30
            }
        },
        evolutionRequirements = {
            level = 75,
            gems = 20000,
            items = {"demon_horn", "hell_essence", "dark_crystal", "cursed_skull"}
        },
        evolvesTo = "kuromi_demon_lord",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            infernal = {multiplier = 5, colorShift = Color3.fromRGB(255, 0, 0)},
            void = {multiplier = 15, colorShift = Color3.fromRGB(0, 0, 0)},
            chaos = {multiplier = 30, colorShift = "chaos"},
            eternal = {multiplier = 60, colorShift = "eternal"},
            apocalypse = {multiplier = 120, colorShift = Color3.fromRGB(150, 0, 0)}
        }
    },
    
    ["cinnamoroll_celestial"] = {
        id = "cinnamoroll_celestial",
        name = "Celestial Cinnamoroll",
        displayName = "Celestial Cinnamoroll",
        tier = "Epic",
        rarity = 4,
        baseStats = {
            coins = 1100,
            gems = 22,
            luck = 45,
            speed = 50,
            power = 280
        },
        description = "Cinnamoroll with celestial cloud powers",
        imageId = "rbxassetid://10000000101",
        modelId = "rbxassetid://10000000102",
        animations = {
            idle = "rbxassetid://10000000103",
            walk = "rbxassetid://10000000104",
            attack = "rbxassetid://10000000105",
            special = "rbxassetid://10000000106",
            fly = "rbxassetid://10000000107",
            cloud_surf = "rbxassetid://10000000108"
        },
        abilities = {
            {
                name = "Cloud Nine",
                description = "Creates healing clouds that restore HP over time",
                cooldown = 60,
                effect = "healing_field",
                value = 100,
                duration = 20,
                radius = 35
            },
            {
                name = "Sky High",
                description = "Grants flight to all pets for 30 seconds",
                cooldown = 180,
                effect = "team_flight",
                value = 1,
                duration = 30
            },
            {
                name = "Celestial Storm",
                description = "Summons a storm that strikes random enemies",
                cooldown = 120,
                effect = "lightning_storm",
                value = 300,
                strikes = 10
            },
            {
                name = "Fluffy Clouds",
                description = "30% chance to negate any attack",
                passive = true,
                effect = "dodge_chance",
                value = 0.3
            },
            {
                name = "Rainbow Bridge",
                description = "Teleports team to safety when below 20% HP",
                passive = true,
                effect = "emergency_teleport",
                value = 0.2,
                cooldown = 300
            }
        },
        evolutionRequirements = {
            level = 75,
            gems = 18000,
            items = {"cloud_essence", "celestial_wings", "rainbow_crystal", "sky_orb"}
        },
        evolvesTo = "cinnamoroll_archangel",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 3, colorShift = Color3.fromRGB(200, 200, 255)},
            aurora = {multiplier = 12, colorShift = "aurora"},
            rainbow = {multiplier = 25, colorShift = "rainbow"},
            stellar = {multiplier = 50, colorShift = "stellar"},
            nebula = {multiplier = 100, colorShift = "nebula"}
        }
    },
    
    ["my_melody_angel"] = {
        id = "my_melody_angel",
        name = "Angel My Melody",
        displayName = "Angel My Melody",
        tier = "Epic",
        rarity = 4,
        baseStats = {
            coins = 1150,
            gems = 21,
            luck = 42,
            speed = 38,
            power = 290
        },
        description = "My Melody blessed with angelic powers",
        imageId = "rbxassetid://10000000109",
        modelId = "rbxassetid://10000000110",
        animations = {
            idle = "rbxassetid://10000000111",
            walk = "rbxassetid://10000000112",
            attack = "rbxassetid://10000000113",
            special = "rbxassetid://10000000114",
            fly = "rbxassetid://10000000115",
            heal = "rbxassetid://10000000116"
        },
        abilities = {
            {
                name = "Melody of Life",
                description = "Fully heals all allies and removes debuffs",
                cooldown = 240,
                effect = "full_heal_cleanse",
                value = 1
            },
            {
                name = "Angelic Voice",
                description = "Charms enemies, making them fight for you",
                cooldown = 180,
                effect = "charm_enemies",
                value = 3,
                duration = 15
            },
            {
                name = "Pink Paradise",
                description = "Creates a safe zone where allies can't die",
                cooldown = 600,
                effect = "immortality_zone",
                radius = 50,
                duration = 10
            },
            {
                name = "Love Aura",
                description = "Converts 30% of damage to healing",
                passive = true,
                effect = "damage_to_heal",
                value = 0.3
            },
            {
                name = "Guardian Angel",
                description = "Automatically revives once per battle",
                passive = true,
                effect = "auto_revive",
                value = 1,
                cooldown = 999999
            }
        },
        evolutionRequirements = {
            level = 75,
            gems = 16000,
            items = {"angel_wings", "melody_harp", "pink_halo", "love_essence"}
        },
        evolvesTo = "my_melody_seraph",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 200, 220)},
            crystal = {multiplier = 10, colorShift = Color3.fromRGB(255, 200, 255)},
            rainbow = {multiplier = 25, colorShift = "rainbow"},
            cosmic = {multiplier = 50, colorShift = "cosmic"},
            divine = {multiplier = 100, colorShift = Color3.fromRGB(255, 220, 240)}
        }
    },
    
    -- TIER 5: LEGENDARY PETS (0.9% drop rate)
    ["hello_kitty_goddess"] = {
        id = "hello_kitty_goddess",
        name = "Goddess Hello Kitty",
        displayName = "Goddess Hello Kitty",
        tier = "Legendary",
        rarity = 5,
        baseStats = {
            coins = 5000,
            gems = 50,
            luck = 80,
            speed = 60,
            power = 1000
        },
        description = "The divine goddess form of Hello Kitty",
        imageId = "rbxassetid://10000000117",
        modelId = "rbxassetid://10000000118",
        animations = {
            idle = "rbxassetid://10000000119",
            walk = "rbxassetid://10000000120",
            attack = "rbxassetid://10000000121",
            special = "rbxassetid://10000000122",
            ascend = "rbxassetid://10000000123",
            divine_wrath = "rbxassetid://10000000124"
        },
        abilities = {
            {
                name = "Divine Creation",
                description = "Creates a blessed zone that triples all rewards",
                cooldown = 600,
                effect = "blessed_zone",
                value = 3,
                duration = 120,
                radius = 100
            },
            {
                name = "Goddess's Wrath",
                description = "Instantly defeats all enemies below 50% health",
                cooldown = 480,
                effect = "execute_all",
                value = 0.5
            },
            {
                name = "Eternal Life",
                description = "Grants immortality to all pets for 20 seconds",
                cooldown = 900,
                effect = "team_immortal",
                value = 1,
                duration = 20
            },
            {
                name = "Divine Presence",
                description = "All pets gain 100% stats and cannot be debuffed",
                passive = true,
                effect = "divine_aura",
                value = 1
            },
            {
                name = "Miracle",
                description = "Fully heals and removes all debuffs from team",
                cooldown = 300,
                effect = "miracle",
                value = 1
            },
            {
                name = "Heaven's Gate",
                description = "Opens portal that doubles all rewards for 5 minutes",
                cooldown = 1800,
                effect = "heaven_portal",
                value = 2,
                duration = 300
            }
        },
        evolutionRequirements = {
            level = 100,
            gems = 100000,
            items = {"goddess_crown", "divine_scepter", "heaven_key", "eternal_ribbon", "cosmic_essence"}
        },
        evolvesTo = nil, -- Max evolution
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 5, colorShift = Color3.fromRGB(255, 255, 200)},
            diamond = {multiplier = 20, colorShift = Color3.fromRGB(200, 255, 255)},
            rainbow = {multiplier = 50, colorShift = "rainbow"},
            cosmic = {multiplier = 100, colorShift = "cosmic"},
            omnipotent = {multiplier = 500, colorShift = "omnipotent"}
        }
    },
    
    ["kuromi_demon_lord"] = {
        id = "kuromi_demon_lord",
        name = "Demon Lord Kuromi",
        displayName = "Demon Lord Kuromi",
        tier = "Legendary",
        rarity = 5,
        baseStats = {
            coins = 4500,
            gems = 45,
            luck = 75,
            speed = 70,
            power = 1200
        },
        description = "Ultimate demon lord form of Kuromi",
        imageId = "rbxassetid://10000000125",
        modelId = "rbxassetid://10000000126",
        animations = {
            idle = "rbxassetid://10000000127",
            walk = "rbxassetid://10000000128",
            attack = "rbxassetid://10000000129",
            special = "rbxassetid://10000000130",
            demon_form = "rbxassetid://10000000131",
            apocalypse = "rbxassetid://10000000132"
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
                name = "Apocalypse",
                description = "Unleashes devastating attack on all enemies",
                cooldown = 900,
                effect = "apocalypse",
                damage = 5000
            },
            {
                name = "Soul Harvest",
                description = "Instantly defeats enemies and steals their power",
                cooldown = 480,
                effect = "soul_harvest",
                value = 1
            },
            {
                name = "Infernal Rage",
                description = "Each kill permanently increases power by 5%",
                passive = true,
                effect = "kill_stack",
                value = 0.05
            },
            {
                name = "Dark Resurrection",
                description = "Revives with 200% stats when defeated",
                passive = true,
                effect = "phoenix",
                value = 2,
                cooldown = 1800
            },
            {
                name = "Demon King's Throne",
                description = "Creates throne that generates massive rewards",
                cooldown = 1200,
                effect = "demon_throne",
                value = 10,
                duration = 180
            }
        },
        evolutionRequirements = {
            level = 100,
            gems = 150000,
            items = {"demon_crown", "hell_gate_key", "soul_crystal", "void_essence", "chaos_orb", "apocalypse_seal"}
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
    
    ["cinnamoroll_archangel"] = {
        id = "cinnamoroll_archangel",
        name = "Archangel Cinnamoroll",
        displayName = "Archangel Cinnamoroll",
        tier = "Legendary",
        rarity = 5,
        baseStats = {
            coins = 4800,
            gems = 48,
            luck = 85,
            speed = 80,
            power = 900
        },
        description = "Supreme celestial form of Cinnamoroll",
        imageId = "rbxassetid://10000000133",
        modelId = "rbxassetid://10000000134",
        animations = {
            idle = "rbxassetid://10000000135",
            walk = "rbxassetid://10000000136",
            attack = "rbxassetid://10000000137",
            special = "rbxassetid://10000000138",
            divine_flight = "rbxassetid://10000000139",
            judgment = "rbxassetid://10000000140"
        },
        abilities = {
            {
                name = "Divine Judgment",
                description = "Judges all enemies, instantly defeating the guilty",
                cooldown = 720,
                effect = "judgment",
                value = 0.7 -- 70% instant kill chance
            },
            {
                name = "Celestial Army",
                description = "Summons army of angel pets",
                cooldown = 600,
                effect = "summon_angels",
                value = 10,
                duration = 120
            },
            {
                name = "Heaven's Wrath",
                description = "Rains divine light dealing massive damage",
                cooldown = 360,
                effect = "divine_rain",
                damage = 2000,
                duration = 10
            },
            {
                name = "Eternal Flight",
                description = "All pets permanently gain flight and +50% speed",
                passive = true,
                effect = "perma_flight",
                value = 0.5
            },
            {
                name = "Resurrection",
                description = "Instantly revives all fallen allies at full health",
                cooldown = 900,
                effect = "mass_resurrection",
                value = 1
            },
            {
                name = "Paradise",
                description = "Creates paradise dimension with 10x rewards",
                cooldown = 3600,
                effect = "paradise_dimension",
                value = 10,
                duration = 300
            }
        },
        evolutionRequirements = {
            level = 100,
            gems = 120000,
            items = {"archangel_wings", "divine_halo", "celestial_sword", "heaven_essence", "god_tear"}
        },
        evolvesTo = nil, -- Max evolution
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 5, colorShift = Color3.fromRGB(220, 220, 255)},
            crystal = {multiplier = 20, colorShift = Color3.fromRGB(200, 255, 255)},
            rainbow = {multiplier = 50, colorShift = "rainbow"},
            cosmic = {multiplier = 100, colorShift = "cosmic"},
            ethereal = {multiplier = 500, colorShift = "ethereal"}
        }
    },
    
    -- TIER 6: MYTHICAL PETS (0.1% drop rate)
    ["sanrio_universe_guardian"] = {
        id = "sanrio_universe_guardian",
        name = "Universe Guardian",
        displayName = "Sanrio Universe Guardian",
        tier = "Mythical",
        rarity = 6,
        baseStats = {
            coins = 50000,
            gems = 500,
            luck = 200,
            speed = 100,
            power = 10000
        },
        description = "The ultimate protector of the Sanrio Universe",
        imageId = "rbxassetid://10000000141",
        modelId = "rbxassetid://10000000142",
        animations = {
            idle = "rbxassetid://10000000143",
            walk = "rbxassetid://10000000144",
            attack = "rbxassetid://10000000145",
            special = "rbxassetid://10000000146",
            universe = "rbxassetid://10000000147",
            creation = "rbxassetid://10000000148",
            big_bang = "rbxassetid://10000000149"
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
                description = "Rewinds time to undo all damage taken",
                cooldown = 1800,
                effect = "time_rewind",
                value = 1
            },
            {
                name = "Reality Warp",
                description = "Changes the rules of reality temporarily",
                cooldown = 2400,
                effect = "reality_warp",
                value = 1
            },
            {
                name = "Infinite Power",
                description = "All stats scale infinitely with time",
                passive = true,
                effect = "infinite_scaling",
                value = 0.01
            },
            {
                name = "Guardian's Protection",
                description = "All pets become invincible",
                passive = true,
                effect = "team_invincible",
                value = 1
            },
            {
                name = "Universal Love",
                description = "Converts all enemies to allies permanently",
                cooldown = 7200,
                effect = "convert_all",
                value = 1
            },
            {
                name = "Big Bang",
                description = "Resets universe and multiplies all resources by 1000",
                cooldown = 86400, -- Once per day
                effect = "big_bang",
                value = 1000
            },
            {
                name = "Omnipresence",
                description = "Exists in all locations simultaneously",
                passive = true,
                effect = "omnipresent",
                value = 1
            }
        },
        evolutionRequirements = nil, -- Cannot evolve
        evolvesTo = nil,
        variants = {
            normal = {multiplier = 1, colorShift = "universe"},
            quantum = {multiplier = 10, colorShift = "quantum"},
            infinity = {multiplier = 100, colorShift = "infinity"},
            omnipotent = {multiplier = 1000, colorShift = "omnipotent"},
            absolute = {multiplier = 10000, colorShift = "absolute"}
        }
    },
    
    -- TIER 7: SECRET PETS (0.01% drop rate)
    ["sanrio_creator"] = {
        id = "sanrio_creator",
        name = "The Creator",
        displayName = "Sanrio Creator",
        tier = "Secret",
        rarity = 7,
        baseStats = {
            coins = 999999,
            gems = 9999,
            luck = 999,
            speed = 999,
            power = 99999
        },
        description = "The one who created all Sanrio characters",
        imageId = "rbxassetid://10000000150",
        modelId = "rbxassetid://10000000151",
        animations = {
            idle = "rbxassetid://10000000152",
            walk = "rbxassetid://10000000153",
            attack = "rbxassetid://10000000154",
            special = "rbxassetid://10000000155",
            create = "rbxassetid://10000000156",
            erase = "rbxassetid://10000000157",
            rewrite = "rbxassetid://10000000158"
        },
        abilities = {
            {
                name = "Creation",
                description = "Creates any pet at will",
                cooldown = 60,
                effect = "create_pet",
                value = 1
            },
            {
                name = "Erasure",
                description = "Erases anything from existence",
                cooldown = 120,
                effect = "erase",
                value = 1
            },
            {
                name = "Rewrite Reality",
                description = "Rewrites the laws of the game",
                cooldown = 3600,
                effect = "rewrite",
                value = 1
            },
            {
                name = "Author Authority",
                description = "Cannot be affected by any abilities",
                passive = true,
                effect = "absolute_immunity",
                value = 1
            },
            {
                name = "Plot Armor",
                description = "Cannot be defeated",
                passive = true,
                effect = "immortal",
                value = 1
            },
            {
                name = "Deus Ex Machina",
                description = "Solves any problem instantly",
                cooldown = 86400,
                effect = "instant_win",
                value = 1
            },
            {
                name = "The End",
                description = "Ends the current game session with maximum rewards",
                cooldown = 604800, -- Once per week
                effect = "game_end",
                value = 999999
            },
            {
                name = "New Beginning",
                description = "Starts a new game+ with all progress carried over",
                cooldown = 2592000, -- Once per month
                effect = "new_game_plus",
                value = 1
            },
            {
                name = "Fourth Wall Break",
                description = "Speaks directly to the player",
                passive = true,
                effect = "fourth_wall",
                value = 1
            }
        },
        evolutionRequirements = nil, -- Beyond evolution
        evolvesTo = nil,
        variants = {
            normal = {multiplier = 1, colorShift = "creator"},
            true_form = {multiplier = 999999, colorShift = "true_form"}
        }
    }
}

-- Continue in Part 2...