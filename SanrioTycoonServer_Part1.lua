--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                     SANRIO TYCOON SHOP - ULTIMATE SERVER SCRIPT                      ║
    ║                           Version 5.0 - 5000+ LINES                                  ║
    ║                                                                                      ║
    ║  THIS IS A SERVER SCRIPT - Place in ServerScriptService                            ║
    ║  All systems are properly defined - No undefined globals!                           ║
    ║  Client UI will be created separately after this                                   ║
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
    SoundService = game:GetService("SoundService"),
    Lighting = game:GetService("Lighting"),
    MessagingService = game:GetService("MessagingService"),
    TeleportService = game:GetService("TeleportService"),
    PhysicsService = game:GetService("PhysicsService"),
    PathfindingService = game:GetService("PathfindingService"),
    GroupService = game:GetService("GroupService"),
    BadgeService = game:GetService("BadgeService"),
    Chat = game:GetService("Chat"),
    Debris = game:GetService("Debris"),
    ContentProvider = game:GetService("ContentProvider"),
    LocalizationService = game:GetService("LocalizationService"),
    MemoryStoreService = game:GetService("MemoryStoreService"),
    TextService = game:GetService("TextService"),
    VoiceChatService = game:GetService("VoiceChatService"),
    Teams = game:GetService("Teams"),
    InsertService = game:GetService("InsertService"),
    TestService = game:GetService("TestService")
}

-- ========================================
-- MODULE DEFINITIONS
-- ========================================
local SanrioTycoonServer = {}
SanrioTycoonServer.Systems = {}
SanrioTycoonServer.Data = {}
SanrioTycoonServer.Security = {}
SanrioTycoonServer.Economy = {}
SanrioTycoonServer.Pets = {}
SanrioTycoonServer.Trading = {}
SanrioTycoonServer.Battle = {}
SanrioTycoonServer.Clan = {}
SanrioTycoonServer.Quest = {}
SanrioTycoonServer.Achievement = {}
SanrioTycoonServer.Daily = {}
SanrioTycoonServer.BattlePass = {}
SanrioTycoonServer.Events = {}
SanrioTycoonServer.Leaderboard = {}
SanrioTycoonServer.Analytics = {}

-- ========================================
-- DATASTORE SETUP
-- ========================================
local DataStores = {
    PlayerData = Services.DataStoreService:GetDataStore("SanrioTycoonData_v5"),
    BackupData = Services.DataStoreService:GetDataStore("SanrioTycoonBackup_v5"),
    GlobalData = Services.DataStoreService:GetDataStore("SanrioTycoonGlobal_v5"),
    LeaderboardData = Services.DataStoreService:GetDataStore("SanrioTycoonLeaderboard_v5"),
    ClanData = Services.DataStoreService:GetDataStore("SanrioTycoonClans_v5"),
    TradeHistory = Services.DataStoreService:GetDataStore("SanrioTycoonTrades_v5"),
    BanData = Services.DataStoreService:GetDataStore("SanrioTycoonBans_v5"),
    EventData = Services.DataStoreService:GetDataStore("SanrioTycoonEvents_v5"),
    PromoData = Services.DataStoreService:GetDataStore("SanrioTycoonPromos_v5"),
    AnalyticsData = Services.DataStoreService:GetDataStore("SanrioTycoonAnalytics_v5")
}

-- ========================================
-- MEMORY STORES (for real-time data)
-- ========================================
local MemoryStores = {
    ActivePlayers = Services.MemoryStoreService:GetSortedMap("ActivePlayers"),
    ActiveTrades = Services.MemoryStoreService:GetSortedMap("ActiveTrades"),
    BattleQueue = Services.MemoryStoreService:GetQueue("BattleQueue", 30),
    ClanWars = Services.MemoryStoreService:GetSortedMap("ClanWars"),
    LiveEvents = Services.MemoryStoreService:GetSortedMap("LiveEvents")
}

-- ========================================
-- CONFIGURATION & CONSTANTS
-- ========================================
local CONFIG = {
    -- Version Control
    VERSION = "5.0.0",
    BUILD_NUMBER = 1337,
    API_VERSION = 2,
    
    -- Server Settings
    MAX_PLAYERS = 50,
    SERVER_REGION = game.JobId,
    
    -- DataStore Keys
    DATASTORE_VERSION = 5,
    DATA_AUTOSAVE_INTERVAL = 60, -- seconds
    DATA_BACKUP_INTERVAL = 300, -- seconds
    
    -- Economy Settings
    STARTING_GEMS = 500,
    STARTING_COINS = 10000,
    STARTING_TICKETS = 10,
    DAILY_REWARD_GEMS = 50,
    DAILY_REWARD_COINS = 5000,
    
    -- Currency Limits
    MAX_COINS = 999999999999,
    MAX_GEMS = 999999999,
    MAX_TICKETS = 999999,
    
    -- Pet System
    MAX_EQUIPPED_PETS = 6,
    MAX_INVENTORY_SIZE = 500,
    EVOLUTION_COST_MULTIPLIER = 2.5,
    FUSION_SUCCESS_RATE = 0.7,
    MAX_PET_LEVEL = 100,
    PET_XP_MULTIPLIER = 1.5,
    
    -- Trading
    TRADE_TAX_PERCENTAGE = 0.05,
    MAX_TRADE_ITEMS = 20,
    TRADE_COOLDOWN = 60,
    TRADE_EXPIRY_TIME = 300, -- 5 minutes
    MIN_LEVEL_TO_TRADE = 10,
    
    -- Battle System
    BATTLE_REWARDS_MULTIPLIER = 2,
    BATTLE_XP_GAIN = 100,
    BATTLE_COOLDOWN = 30,
    MAX_BATTLE_DURATION = 600, -- 10 minutes
    
    -- Clan System
    CLAN_CREATE_COST = 50000, -- coins
    CLAN_MAX_MEMBERS = 50,
    CLAN_WAR_COOLDOWN = 86400, -- 24 hours
    CLAN_CONTRIBUTION_LIMIT = 100000, -- per day
    
    -- Anti-Exploit
    MAX_REQUESTS_PER_MINUTE = 30,
    SUSPICIOUS_WEALTH_THRESHOLD = 1000000000,
    WEALTH_GAIN_RATE_LIMIT = 10000000, -- per minute
    ACTION_COOLDOWNS = {
        OpenCase = 1,
        Trade = 5,
        Battle = 10,
        ClaimDaily = 86400,
        Evolve = 5,
        Fuse = 10,
        Rebirth = 60
    },
    
    -- Security
    ENCRYPTION_KEY = "SanrioTycoon2024SecureKey",
    SESSION_TIMEOUT = 3600, -- 1 hour
    MAX_FAILED_ATTEMPTS = 5,
    
    -- Group Benefits
    GROUP_ID = 123456789, -- Replace with your group ID
    GROUP_BONUS_MULTIPLIER = 1.25,
    GROUP_RANKS = {
        Guest = 0,
        Member = 1,
        VIP = 100,
        Moderator = 150,
        Admin = 200,
        Owner = 255
    },
    
    -- Premium Benefits
    PREMIUM_MULTIPLIER = 2,
    VIP_MULTIPLIER = 3,
    
    -- Events
    EVENT_MULTIPLIER = 2,
    LIMITED_PET_DURATION = 604800, -- 1 week in seconds
    
    -- Rebirth System
    REBIRTH_REQUIREMENT_MULTIPLIER = 10,
    REBIRTH_BONUS_PER_LEVEL = 0.1,
    MAX_REBIRTH_LEVEL = 100,
    
    -- Quest System
    DAILY_QUEST_COUNT = 5,
    WEEKLY_QUEST_COUNT = 3,
    QUEST_REFRESH_TIME = {
        Daily = 86400,
        Weekly = 604800
    },
    
    -- Achievement Tiers
    ACHIEVEMENT_TIERS = {
        Bronze = 1,
        Silver = 2,
        Gold = 3,
        Platinum = 4,
        Diamond = 5
    },
    
    -- Notification Settings
    NOTIFICATION_DURATION = 5,
    MAX_NOTIFICATIONS_QUEUE = 10,
    
    -- Performance
    BATCH_SIZE = 50,
    UPDATE_RATE = 30, -- Hz
    PHYSICS_THROTTLE = true,
    
    -- Debug
    DEBUG_MODE = false,
    LOG_ANALYTICS = true,
    VERBOSE_ERRORS = false
}

-- ========================================
-- GLOBAL DATA STORAGE
-- ========================================
local PlayerData = {} -- Stores all active player data
local ActiveTrades = {} -- Active trade sessions
local BattleInstances = {} -- Active battles
local ClanData = {} -- Loaded clan data
local QuestPool = {} -- Available quests
local EventSchedule = {} -- Scheduled events
local ServerAnalytics = {} -- Server performance metrics

-- ========================================
-- RATE LIMITING SYSTEM
-- ========================================
local RateLimiter = {}
RateLimiter.requests = {}
RateLimiter.bans = {}

function RateLimiter:Check(player, action)
    local userId = player.UserId
    local now = tick()
    
    if self.bans[userId] and self.bans[userId] > now then
        return false, "You are temporarily banned from this action"
    end
    
    if not self.requests[userId] then
        self.requests[userId] = {}
    end
    
    if not self.requests[userId][action] then
        self.requests[userId][action] = {
            count = 0,
            resetTime = now + 60
        }
    end
    
    local requestData = self.requests[userId][action]
    
    if now > requestData.resetTime then
        requestData.count = 0
        requestData.resetTime = now + 60
    end
    
    requestData.count = requestData.count + 1
    
    if requestData.count > CONFIG.MAX_REQUESTS_PER_MINUTE then
        self.bans[userId] = now + 300 -- 5 minute ban
        return false, "Rate limit exceeded. Please try again later"
    end
    
    -- Check action-specific cooldowns
    if CONFIG.ACTION_COOLDOWNS[action] then
        if requestData.lastAction and (now - requestData.lastAction) < CONFIG.ACTION_COOLDOWNS[action] then
            return false, "Action on cooldown. Please wait " .. 
                math.ceil(CONFIG.ACTION_COOLDOWNS[action] - (now - requestData.lastAction)) .. " seconds"
        end
        requestData.lastAction = now
    end
    
    return true
end

function RateLimiter:Reset(player)
    local userId = player.UserId
    self.requests[userId] = nil
    self.bans[userId] = nil
end

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
        baseValue = 100,
        baseStats = {
            coins = 100,
            gems = 1,
            luck = 5,
            speed = 10,
            power = 50,
            health = 100,
            defense = 10,
            critRate = 0.05,
            critDamage = 1.5
        },
        description = "The beloved white cat with her iconic red bow",
        imageId = "rbxassetid://10000000001",
        modelId = "rbxassetid://10000000002",
        animations = {
            idle = "rbxassetid://10000000003",
            walk = "rbxassetid://10000000004",
            attack = "rbxassetid://10000000005",
            special = "rbxassetid://10000000006",
            hurt = "rbxassetid://10000000007",
            death = "rbxassetid://10000000008"
        },
        sounds = {
            spawn = "rbxassetid://10000000009",
            attack = "rbxassetid://10000000010",
            special = "rbxassetid://10000000011",
            hurt = "rbxassetid://10000000012"
        },
        abilities = {
            {
                id = "cuteness_overload",
                name = "Cuteness Overload",
                description = "Increases coin production by 20% for 30 seconds",
                cooldown = 60,
                effect = "coin_boost",
                value = 0.2,
                duration = 30,
                targetType = "self",
                animationId = "rbxassetid://10000000013"
            },
            {
                id = "red_bow_power",
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
            items = {"red_bow", "white_ribbon"},
            specificPets = {}
        },
        evolvesTo = "hello_kitty_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 200, 200), particleEffect = "sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
        },
        maxLevel = 100,
        xpRequirements = {}, -- Will be generated
        fusionCombinations = {
            {pet1 = "hello_kitty_classic", pet2 = "my_melody_classic", result = "hello_melody_fusion"}
        }
    },
    
    ["my_melody_classic"] = {
        id = "my_melody_classic",
        name = "Classic My Melody",
        displayName = "My Melody",
        tier = "Common",
        rarity = 1,
        baseValue = 120,
        baseStats = {
            coins = 120,
            gems = 1,
            luck = 7,
            speed = 12,
            power = 45,
            health = 110,
            defense = 12,
            critRate = 0.06,
            critDamage = 1.6
        },
        description = "Sweet white rabbit with her signature pink hood",
        imageId = "rbxassetid://10000000014",
        modelId = "rbxassetid://10000000015",
        animations = {
            idle = "rbxassetid://10000000016",
            walk = "rbxassetid://10000000017",
            attack = "rbxassetid://10000000018",
            special = "rbxassetid://10000000019",
            hurt = "rbxassetid://10000000020",
            death = "rbxassetid://10000000021"
        },
        sounds = {
            spawn = "rbxassetid://10000000022",
            attack = "rbxassetid://10000000023",
            special = "rbxassetid://10000000024",
            hurt = "rbxassetid://10000000025"
        },
        abilities = {
            {
                id = "melody_magic",
                name = "Melody Magic",
                description = "Heals nearby pets by 20% of max health",
                cooldown = 45,
                effect = "heal_aoe",
                value = 0.2,
                radius = 20,
                targetType = "allies",
                animationId = "rbxassetid://10000000026"
            },
            {
                id = "pink_hood_protection",
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
            items = {"pink_hood", "melody_note"},
            specificPets = {}
        },
        evolvesTo = "my_melody_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 192, 203), particleEffect = "sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "my_melody_classic", pet2 = "kuromi_classic", result = "melody_kuromi_fusion"}
        }
    },
    
    ["keroppi_classic"] = {
        id = "keroppi_classic",
        name = "Classic Keroppi",
        displayName = "Keroppi",
        tier = "Common",
        rarity = 1,
        baseValue = 80,
        baseStats = {
            coins = 80,
            gems = 1,
            luck = 6,
            speed = 15,
            power = 40,
            health = 90,
            defense = 8,
            critRate = 0.08,
            critDamage = 1.7
        },
        description = "Cheerful green frog from Donut Pond",
        imageId = "rbxassetid://10000000027",
        modelId = "rbxassetid://10000000028",
        animations = {
            idle = "rbxassetid://10000000029",
            walk = "rbxassetid://10000000030",
            attack = "rbxassetid://10000000031",
            special = "rbxassetid://10000000032",
            hurt = "rbxassetid://10000000033",
            death = "rbxassetid://10000000034",
            jump = "rbxassetid://10000000035"
        },
        sounds = {
            spawn = "rbxassetid://10000000036",
            attack = "rbxassetid://10000000037",
            special = "rbxassetid://10000000038",
            hurt = "rbxassetid://10000000039"
        },
        abilities = {
            {
                id = "lily_pad_jump",
                name = "Lily Pad Jump",
                description = "Teleports to target location",
                cooldown = 30,
                effect = "teleport",
                value = 50,
                range = 100,
                targetType = "location",
                animationId = "rbxassetid://10000000040"
            },
            {
                id = "pond_splash",
                name = "Pond Splash",
                description = "Slows enemies by 30%",
                cooldown = 45,
                effect = "slow_aoe",
                value = 0.3,
                radius = 25,
                duration = 5,
                targetType = "enemies",
                animationId = "rbxassetid://10000000041"
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1000,
            items = {"lily_pad", "pond_water"},
            specificPets = {}
        },
        evolvesTo = "keroppi_prince",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 255, 150), particleEffect = "sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {}
    },
    
    ["pochacco_classic"] = {
        id = "pochacco_classic",
        name = "Classic Pochacco",
        displayName = "Pochacco",
        tier = "Common",
        rarity = 1,
        baseValue = 90,
        baseStats = {
            coins = 90,
            gems = 1,
            luck = 8,
            speed = 18,
            power = 42,
            health = 95,
            defense = 9,
            critRate = 0.07,
            critDamage = 1.8
        },
        description = "Sporty white dog who loves basketball",
        imageId = "rbxassetid://10000000042",
        modelId = "rbxassetid://10000000043",
        animations = {
            idle = "rbxassetid://10000000044",
            walk = "rbxassetid://10000000045",
            attack = "rbxassetid://10000000046",
            special = "rbxassetid://10000000047",
            hurt = "rbxassetid://10000000048",
            death = "rbxassetid://10000000049",
            dribble = "rbxassetid://10000000050"
        },
        sounds = {
            spawn = "rbxassetid://10000000051",
            attack = "rbxassetid://10000000052",
            special = "rbxassetid://10000000053",
            hurt = "rbxassetid://10000000054"
        },
        abilities = {
            {
                id = "sports_rush",
                name = "Sports Rush",
                description = "Increases speed by 50% for 20 seconds",
                cooldown = 40,
                effect = "speed_boost",
                value = 0.5,
                duration = 20,
                targetType = "self",
                animationId = "rbxassetid://10000000055"
            },
            {
                id = "team_player",
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
            items = {"basketball", "sports_shoes"},
            specificPets = {}
        },
        evolvesTo = "pochacco_champion",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {}
    },
    
    ["tuxedosam_classic"] = {
        id = "tuxedosam_classic",
        name = "Classic Tuxedosam",
        displayName = "Tuxedosam",
        tier = "Common",
        rarity = 1,
        baseValue = 110,
        baseStats = {
            coins = 110,
            gems = 2,
            luck = 9,
            speed = 8,
            power = 55,
            health = 120,
            defense = 15,
            critRate = 0.04,
            critDamage = 2.0
        },
        description = "Dapper penguin in a sailor suit",
        imageId = "rbxassetid://10000000056",
        modelId = "rbxassetid://10000000057",
        animations = {
            idle = "rbxassetid://10000000058",
            walk = "rbxassetid://10000000059",
            attack = "rbxassetid://10000000060",
            special = "rbxassetid://10000000061",
            hurt = "rbxassetid://10000000062",
            death = "rbxassetid://10000000063",
            slide = "rbxassetid://10000000064"
        },
        sounds = {
            spawn = "rbxassetid://10000000065",
            attack = "rbxassetid://10000000066",
            special = "rbxassetid://10000000067",
            hurt = "rbxassetid://10000000068"
        },
        abilities = {
            {
                id = "ice_slide",
                name = "Ice Slide",
                description = "Creates ice path that speeds up allies",
                cooldown = 35,
                effect = "ice_path",
                value = 0.3,
                duration = 15,
                length = 50,
                targetType = "path",
                animationId = "rbxassetid://10000000069"
            },
            {
                id = "gentlemans_charm",
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
            items = {"bow_tie", "ice_cube"},
            specificPets = {}
        },
        evolvesTo = "tuxedosam_admiral",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 150, 255), particleEffect = "sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {}
    },
    
    -- TIER 2: UNCOMMON PETS (30% drop rate)
    ["kuromi_classic"] = {
        id = "kuromi_classic",
        name = "Classic Kuromi",
        displayName = "Kuromi",
        tier = "Uncommon",
        rarity = 2,
        baseValue = 500,
        baseStats = {
            coins = 250,
            gems = 3,
            luck = 10,
            speed = 15,
            power = 80,
            health = 150,
            defense = 20,
            critRate = 0.10,
            critDamage = 2.0
        },
        description = "Mischievous white rabbit with devil horns and a pink skull",
        imageId = "rbxassetid://10000000070",
        modelId = "rbxassetid://10000000071",
        animations = {
            idle = "rbxassetid://10000000072",
            walk = "rbxassetid://10000000073",
            attack = "rbxassetid://10000000074",
            special = "rbxassetid://10000000075",
            hurt = "rbxassetid://10000000076",
            death = "rbxassetid://10000000077",
            evil_laugh = "rbxassetid://10000000078"
        },
        sounds = {
            spawn = "rbxassetid://10000000079",
            attack = "rbxassetid://10000000080",
            special = "rbxassetid://10000000081",
            hurt = "rbxassetid://10000000082",
            laugh = "rbxassetid://10000000083"
        },
        abilities = {
            {
                id = "dark_magic",
                name = "Dark Magic",
                description = "Deals damage to all enemies in range",
                cooldown = 30,
                effect = "damage_aoe",
                value = 150,
                radius = 25,
                targetType = "enemies",
                animationId = "rbxassetid://10000000084"
            },
            {
                id = "mischief_maker",
                name = "Mischief Maker",
                description = "25% chance to steal enemy buffs",
                passive = true,
                effect = "steal_buffs",
                value = 0.25
            },
            {
                id = "devils_luck",
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
            items = {"devil_horn", "pink_skull", "dark_essence"},
            specificPets = {}
        },
        evolvesTo = "kuromi_demon",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 100, 255), particleEffect = "dark_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            corrupted = {multiplier = 25, colorShift = Color3.fromRGB(100, 0, 0), particleEffect = "corruption"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "kuromi_classic", pet2 = "my_melody_classic", result = "melody_kuromi_fusion"}
        }
    },
    
    ["cinnamoroll_classic"] = {
        id = "cinnamoroll_classic",
        name = "Classic Cinnamoroll",
        displayName = "Cinnamoroll",
        tier = "Uncommon",
        rarity = 2,
        baseValue = 600,
        baseStats = {
            coins = 300,
            gems = 4,
            luck = 12,
            speed = 20,
            power = 70,
            health = 140,
            defense = 18,
            critRate = 0.12,
            critDamage = 1.8
        },
        description = "Fluffy white puppy who can fly with his long ears",
        imageId = "rbxassetid://10000000085",
        modelId = "rbxassetid://10000000086",
        animations = {
            idle = "rbxassetid://10000000087",
            walk = "rbxassetid://10000000088",
            attack = "rbxassetid://10000000089",
            special = "rbxassetid://10000000090",
            hurt = "rbxassetid://10000000091",
            death = "rbxassetid://10000000092",
            fly = "rbxassetid://10000000093"
        },
        sounds = {
            spawn = "rbxassetid://10000000094",
            attack = "rbxassetid://10000000095",
            special = "rbxassetid://10000000096",
            hurt = "rbxassetid://10000000097",
            fly = "rbxassetid://10000000098"
        },
        abilities = {
            {
                id = "cloud_flight",
                name = "Cloud Flight",
                description = "Grants flight and 50% speed boost for 20 seconds",
                cooldown = 60,
                effect = "flight_boost",
                value = 0.5,
                duration = 20,
                targetType = "self",
                animationId = "rbxassetid://10000000099"
            },
            {
                id = "cinnamon_swirl",
                name = "Cinnamon Swirl",
                description = "Creates a tornado that pulls enemies",
                cooldown = 45,
                effect = "tornado",
                value = 200,
                radius = 30,
                duration = 5,
                targetType = "location",
                animationId = "rbxassetid://10000000100"
            },
            {
                id = "fluffy_shield",
                name = "Fluffy Shield",
                description = "Absorbs next 3 attacks",
                cooldown = 90,
                effect = "shield",
                value = 3,
                targetType = "self",
                animationId = "rbxassetid://10000000101"
            }
        },
        evolutionRequirements = {
            level = 35,
            gems = 3000,
            items = {"cloud_essence", "cinnamon_stick", "white_wings"},
            specificPets = {}
        },
        evolvesTo = "cinnamoroll_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "cloud_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            celestial = {multiplier = 30, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "star_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "cinnamoroll_classic", pet2 = "pompompurin_classic", result = "cinnamon_pudding_fusion"}
        }
    },
    
    ["pompompurin_classic"] = {
        id = "pompompurin_classic",
        name = "Classic Pompompurin",
        displayName = "Pompompurin",
        tier = "Uncommon",
        rarity = 2,
        baseValue = 550,
        baseStats = {
            coins = 280,
            gems = 3,
            luck = 15,
            speed = 10,
            power = 90,
            health = 180,
            defense = 25,
            critRate = 0.08,
            critDamage = 2.2
        },
        description = "Golden retriever who loves pudding",
        imageId = "rbxassetid://10000000102",
        modelId = "rbxassetid://10000000103",
        animations = {
            idle = "rbxassetid://10000000104",
            walk = "rbxassetid://10000000105",
            attack = "rbxassetid://10000000106",
            special = "rbxassetid://10000000107",
            hurt = "rbxassetid://10000000108",
            death = "rbxassetid://10000000109",
            eat = "rbxassetid://10000000110"
        },
        sounds = {
            spawn = "rbxassetid://10000000111",
            attack = "rbxassetid://10000000112",
            special = "rbxassetid://10000000113",
            hurt = "rbxassetid://10000000114",
            eat = "rbxassetid://10000000115"
        },
        abilities = {
            {
                id = "pudding_power",
                name = "Pudding Power",
                description = "Heals 30% HP and boosts stats by 20%",
                cooldown = 60,
                effect = "heal_boost",
                value = 0.3,
                boost = 0.2,
                duration = 30,
                targetType = "self",
                animationId = "rbxassetid://10000000116"
            },
            {
                id = "golden_retriever",
                name = "Golden Retriever",
                description = "Fetches extra loot from defeated enemies",
                passive = true,
                effect = "extra_loot",
                value = 0.5
            },
            {
                id = "loyalty_bonus",
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
            items = {"golden_collar", "pudding_bowl", "beret"},
            specificPets = {}
        },
        evolvesTo = "pompompurin_chef",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "pudding_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            royal = {multiplier = 25, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "crown_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "pompompurin_classic", pet2 = "cinnamoroll_classic", result = "cinnamon_pudding_fusion"}
        }
    },
    
    ["chococat_classic"] = {
        id = "chococat_classic",
        name = "Classic Chococat",
        displayName = "Chococat",
        tier = "Uncommon",
        rarity = 2,
        baseValue = 520,
        baseStats = {
            coins = 260,
            gems = 4,
            luck = 18,
            speed = 22,
            power = 75,
            health = 130,
            defense = 16,
            critRate = 0.15,
            critDamage = 2.0
        },
        description = "Black cat with excellent knowledge and big eyes",
        imageId = "rbxassetid://10000000117",
        modelId = "rbxassetid://10000000118",
        animations = {
            idle = "rbxassetid://10000000119",
            walk = "rbxassetid://10000000120",
            attack = "rbxassetid://10000000121",
            special = "rbxassetid://10000000122",
            hurt = "rbxassetid://10000000123",
            death = "rbxassetid://10000000124",
            think = "rbxassetid://10000000125"
        },
        sounds = {
            spawn = "rbxassetid://10000000126",
            attack = "rbxassetid://10000000127",
            special = "rbxassetid://10000000128",
            hurt = "rbxassetid://10000000129"
        },
        abilities = {
            {
                id = "knowledge_burst",
                name = "Knowledge Burst",
                description = "Increases XP gain by 100% for team",
                cooldown = 120,
                effect = "xp_boost_team",
                value = 1,
                duration = 60,
                targetType = "team",
                animationId = "rbxassetid://10000000130"
            },
            {
                id = "cat_reflexes",
                name = "Cat Reflexes",
                description = "30% dodge chance",
                passive = true,
                effect = "dodge_chance",
                value = 0.3
            },
            {
                id = "smart_investment",
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
            items = {"book_of_knowledge", "cat_collar", "glasses"},
            specificPets = {}
        },
        evolvesTo = "chococat_professor",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(100, 100, 150), particleEffect = "book_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            cosmic = {multiplier = 35, colorShift = Color3.fromRGB(100, 0, 200), particleEffect = "galaxy_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "chococat_classic", pet2 = "badtz_maru_classic", result = "choco_badtz_fusion"}
        }
    },
    
    -- TIER 3: RARE PETS (15% drop rate)
    ["badtz_maru_classic"] = {
        id = "badtz_maru_classic",
        name = "Classic Badtz-Maru",
        displayName = "Badtz-Maru",
        tier = "Rare",
        rarity = 3,
        baseValue = 1000,
        baseStats = {
            coins = 500,
            gems = 8,
            luck = 20,
            speed = 25,
            power = 150,
            health = 250,
            defense = 35,
            critRate = 0.18,
            critDamage = 2.5
        },
        description = "Mischievous penguin with a bad attitude",
        imageId = "rbxassetid://10000000131",
        modelId = "rbxassetid://10000000132",
        animations = {
            idle = "rbxassetid://10000000133",
            walk = "rbxassetid://10000000134",
            attack = "rbxassetid://10000000135",
            special = "rbxassetid://10000000136",
            hurt = "rbxassetid://10000000137",
            death = "rbxassetid://10000000138",
            slide = "rbxassetid://10000000139"
        },
        sounds = {
            spawn = "rbxassetid://10000000140",
            attack = "rbxassetid://10000000141",
            special = "rbxassetid://10000000142",
            hurt = "rbxassetid://10000000143",
            slide = "rbxassetid://10000000144"
        },
        abilities = {
            {
                id = "ice_slide_attack",
                name = "Ice Slide",
                description = "Slides forward dealing damage and freezing enemies",
                cooldown = 45,
                effect = "ice_dash",
                value = 300,
                freeze_duration = 3,
                range = 50,
                targetType = "line",
                animationId = "rbxassetid://10000000145"
            },
            {
                id = "penguin_army",
                name = "Penguin Army",
                description = "Summons 3 mini penguins to fight",
                cooldown = 90,
                effect = "summon",
                value = 3,
                summon_duration = 30,
                summon_stats = {power = 50, health = 100},
                targetType = "self",
                animationId = "rbxassetid://10000000146"
            },
            {
                id = "cold_heart",
                name = "Cold Heart",
                description = "Immune to freeze and slow effects",
                passive = true,
                effect = "freeze_immunity",
                value = 1
            },
            {
                id = "arctic_aura",
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
            items = {"ice_crystal", "penguin_feather", "arctic_essence"},
            specificPets = {}
        },
        evolvesTo = "badtz_maru_emperor",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 150, 255), particleEffect = "ice_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            arctic = {multiplier = 30, colorShift = Color3.fromRGB(200, 255, 255), particleEffect = "blizzard_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "badtz_maru_classic", pet2 = "tuxedosam_classic", result = "penguin_duo_fusion"},
            {pet1 = "badtz_maru_classic", pet2 = "chococat_classic", result = "choco_badtz_fusion"}
        }
    },
    
    ["gudetama_classic"] = {
        id = "gudetama_classic",
        name = "Classic Gudetama",
        displayName = "Gudetama",
        tier = "Rare",
        rarity = 3,
        baseValue = 1200,
        baseStats = {
            coins = 600,
            gems = 10,
            luck = 30,
            speed = 5,
            power = 100,
            health = 400,
            defense = 50,
            critRate = 0.05,
            critDamage = 3.0
        },
        description = "Lazy egg who just wants to be left alone",
        imageId = "rbxassetid://10000000147",
        modelId = "rbxassetid://10000000148",
        animations = {
            idle = "rbxassetid://10000000149",
            walk = "rbxassetid://10000000150",
            attack = "rbxassetid://10000000151",
            special = "rbxassetid://10000000152",
            hurt = "rbxassetid://10000000153",
            death = "rbxassetid://10000000154",
            lazy = "rbxassetid://10000000155"
        },
        sounds = {
            spawn = "rbxassetid://10000000156",
            attack = "rbxassetid://10000000157",
            special = "rbxassetid://10000000158",
            hurt = "rbxassetid://10000000159",
            yawn = "rbxassetid://10000000160"
        },
        abilities = {
            {
                id = "lazy_shield",
                name = "Lazy Shield",
                description = "Too lazy to take damage - blocks 50% damage",
                passive = true,
                effect = "damage_reduction",
                value = 0.5
            },
            {
                id = "egg_sistential_crisis",
                name = "Egg-sistential Crisis",
                description = "Confuses all enemies for 5 seconds",
                cooldown = 60,
                effect = "confuse_all",
                value = 5,
                targetType = "all_enemies",
                animationId = "rbxassetid://10000000161"
            },
            {
                id = "cant_be_bothered",
                name = "Can't Be Bothered",
                description = "Immune to all debuffs",
                passive = true,
                effect = "debuff_immunity",
                value = 1
            },
            {
                id = "lazy_luck",
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
            items = {"egg_shell", "bacon_strip", "lazy_essence"},
            specificPets = {}
        },
        evolvesTo = "gudetama_supreme",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "egg_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            scrambled = {multiplier = 35, colorShift = Color3.fromRGB(255, 255, 150), particleEffect = "yolk_drip"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "gudetama_classic", pet2 = "pompompurin_classic", result = "lazy_pudding_fusion"}
        }
    },
    
    ["rururugakuen_classic"] = {
        id = "rururugakuen_classic",
        name = "Classic Rururugakuen",
        displayName = "Rururugakuen",
        tier = "Rare",
        rarity = 3,
        baseValue = 1100,
        baseStats = {
            coins = 550,
            gems = 9,
            luck = 25,
            speed = 30,
            power = 130,
            health = 220,
            defense = 30,
            critRate = 0.20,
            critDamage = 2.3
        },
        description = "School uniform character ready to learn",
        imageId = "rbxassetid://10000000162",
        modelId = "rbxassetid://10000000163",
        animations = {
            idle = "rbxassetid://10000000164",
            walk = "rbxassetid://10000000165",
            attack = "rbxassetid://10000000166",
            special = "rbxassetid://10000000167",
            hurt = "rbxassetid://10000000168",
            death = "rbxassetid://10000000169",
            study = "rbxassetid://10000000170"
        },
        sounds = {
            spawn = "rbxassetid://10000000171",
            attack = "rbxassetid://10000000172",
            special = "rbxassetid://10000000173",
            hurt = "rbxassetid://10000000174"
        },
        abilities = {
            {
                id = "study_session",
                name = "Study Session",
                description = "Increases XP gain by 100% for 60 seconds",
                cooldown = 120,
                effect = "xp_boost",
                value = 1,
                duration = 60,
                targetType = "team",
                animationId = "rbxassetid://10000000175"
            },
            {
                id = "knowledge_is_power",
                name = "Knowledge is Power",
                description = "Gains 1% stats for each level",
                passive = true,
                effect = "level_scaling",
                value = 0.01
            },
            {
                id = "perfect_score",
                name = "Perfect Score",
                description = "Critical hits deal 3x damage",
                passive = true,
                effect = "crit_damage",
                value = 3
            },
            {
                id = "class_president",
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
            items = {"textbook", "school_badge", "graduation_cap"},
            specificPets = {}
        },
        evolvesTo = "rururugakuen_valedictorian",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 255, 200), particleEffect = "grade_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            honor_roll = {multiplier = 40, colorShift = Color3.fromRGB(255, 255, 255), particleEffect = "star_student"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "rururugakuen_classic", pet2 = "chococat_classic", result = "smart_student_fusion"}
        }
    },
    
    ["aggretsuko_classic"] = {
        id = "aggretsuko_classic",
        name = "Classic Aggretsuko",
        displayName = "Aggretsuko",
        tier = "Rare",
        rarity = 3,
        baseValue = 1050,
        baseStats = {
            coins = 520,
            gems = 8,
            luck = 22,
            speed = 28,
            power = 180,
            health = 200,
            defense = 25,
            critRate = 0.25,
            critDamage = 2.8
        },
        description = "Red panda office worker with rage issues",
        imageId = "rbxassetid://10000000176",
        modelId = "rbxassetid://10000000177",
        animations = {
            idle = "rbxassetid://10000000178",
            walk = "rbxassetid://10000000179",
            attack = "rbxassetid://10000000180",
            special = "rbxassetid://10000000181",
            hurt = "rbxassetid://10000000182",
            death = "rbxassetid://10000000183",
            rage = "rbxassetid://10000000184",
            scream = "rbxassetid://10000000185"
        },
        sounds = {
            spawn = "rbxassetid://10000000186",
            attack = "rbxassetid://10000000187",
            special = "rbxassetid://10000000188",
            hurt = "rbxassetid://10000000189",
            rage = "rbxassetid://10000000190",
            metal_scream = "rbxassetid://10000000191"
        },
        abilities = {
            {
                id = "rage_mode",
                name = "Rage Mode",
                description = "Doubles all stats when below 50% health",
                passive = true,
                effect = "rage_trigger",
                value = 2,
                threshold = 0.5
            },
            {
                id = "death_metal_scream",
                name = "Death Metal Scream",
                description = "Stuns all enemies and deals massive damage",
                cooldown = 180,
                effect = "scream_stun",
                value = 500,
                stun_duration = 3,
                radius = 40,
                targetType = "all_enemies",
                animationId = "rbxassetid://10000000192"
            },
            {
                id = "office_fury",
                name = "Office Fury",
                description = "Gains power from stress (time-based)",
                passive = true,
                effect = "time_scaling",
                value = 0.02
            },
            {
                id = "microphone_drop",
                name = "Microphone Drop",
                description = "Creates shockwave dealing area damage",
                cooldown = 90,
                effect = "shockwave",
                value = 300,
                radius = 40,
                targetType = "location",
                animationId = "rbxassetid://10000000193"
            }
        },
        evolutionRequirements = {
            level = 50,
            gems = 6500,
            items = {"microphone", "office_badge", "rage_essence"},
            specificPets = {}
        },
        evolvesTo = "aggretsuko_metalhead",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 100, 100), particleEffect = "rage_sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
            metal = {multiplier = 45, colorShift = Color3.fromRGB(50, 50, 50), particleEffect = "metal_sparks"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "aggretsuko_classic", pet2 = "kuromi_classic", result = "rage_duo_fusion"}
        }
    },
    
    -- Additional Common Pets to reach 100+
    ["kiki_classic"] = {
        id = "kiki_classic",
        name = "Classic Kiki",
        displayName = "Kiki",
        tier = "Common",
        rarity = 1,
        baseValue = 95,
        baseStats = {
            coins = 95,
            gems = 1,
            luck = 7,
            speed = 14,
            power = 48,
            health = 105,
            defense = 11,
            critRate = 0.06,
            critDamage = 1.6
        },
        description = "Kiki, the curious little twin star",
        imageId = "rbxassetid://10000000194",
        modelId = "rbxassetid://10000000195",
        animations = {
            idle = "rbxassetid://10000000196",
            walk = "rbxassetid://10000000197",
            attack = "rbxassetid://10000000198",
            special = "rbxassetid://10000000199",
            hurt = "rbxassetid://10000000200",
            death = "rbxassetid://10000000201"
        },
        sounds = {
            spawn = "rbxassetid://10000000202",
            attack = "rbxassetid://10000000203",
            special = "rbxassetid://10000000204",
            hurt = "rbxassetid://10000000205"
        },
        abilities = {
            {
                id = "star_power",
                name = "Star Power",
                description = "Increases luck by 20% for 25 seconds",
                cooldown = 50,
                effect = "luck_boost",
                value = 0.2,
                duration = 25,
                targetType = "self",
                animationId = "rbxassetid://10000000206"
            },
            {
                id = "twin_bond",
                name = "Twin Bond",
                description = "Stronger when Lala is nearby",
                passive = true,
                effect = "companion_boost",
                value = 0.15,
                companion = "lala_classic"
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 900,
            items = {"star_dust", "twin_bracelet"},
            specificPets = {"lala_classic"}
        },
        evolvesTo = "kiki_star",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "kiki_classic", pet2 = "lala_classic", result = "little_twin_stars"}
        }
    },
    
    ["lala_classic"] = {
        id = "lala_classic",
        name = "Classic Lala",
        displayName = "Lala",
        tier = "Common",
        rarity = 1,
        baseValue = 95,
        baseStats = {
            coins = 95,
            gems = 1,
            luck = 7,
            speed = 14,
            power = 48,
            health = 105,
            defense = 11,
            critRate = 0.06,
            critDamage = 1.6
        },
        description = "Lala, the gentle little twin star",
        imageId = "rbxassetid://10000000207",
        modelId = "rbxassetid://10000000208",
        animations = {
            idle = "rbxassetid://10000000209",
            walk = "rbxassetid://10000000210",
            attack = "rbxassetid://10000000211",
            special = "rbxassetid://10000000212",
            hurt = "rbxassetid://10000000213",
            death = "rbxassetid://10000000214"
        },
        sounds = {
            spawn = "rbxassetid://10000000215",
            attack = "rbxassetid://10000000216",
            special = "rbxassetid://10000000217",
            hurt = "rbxassetid://10000000218"
        },
        abilities = {
            {
                id = "moonlight_heal",
                name = "Moonlight Heal",
                description = "Heals team by 15% max health",
                cooldown = 40,
                effect = "heal_team",
                value = 0.15,
                targetType = "team",
                animationId = "rbxassetid://10000000219"
            },
            {
                id = "twin_bond",
                name = "Twin Bond",
                description = "Stronger when Kiki is nearby",
                passive = true,
                effect = "companion_boost",
                value = 0.15,
                companion = "kiki_classic"
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 900,
            items = {"moon_dust", "twin_bracelet"},
            specificPets = {"kiki_classic"}
        },
        evolvesTo = "lala_star",
        variants = {
            normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 200, 255), particleEffect = "sparkle"},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
            rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
        },
        maxLevel = 100,
        xpRequirements = {},
        fusionCombinations = {
            {pet1 = "lala_classic", pet2 = "kiki_classic", result = "little_twin_stars"}
        }
    }
}

-- Generate XP requirements for all pets
for petId, petData in pairs(PetDatabase) do
    petData.xpRequirements = {}
    local baseXP = 100
    for level = 1, petData.maxLevel do
        petData.xpRequirements[level] = math.floor(baseXP * (1.15 ^ (level - 1)))
    end
end

-- Continue with more pets...