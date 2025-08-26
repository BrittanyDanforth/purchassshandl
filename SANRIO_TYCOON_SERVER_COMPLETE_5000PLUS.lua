--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                  SANRIO TYCOON SHOP - ULTIMATE SERVER SCRIPT                         ║
    ║                           Version 5.0 - COMPLETE 5000+ LINES                         ║
    ║                                                                                      ║
    ║  THIS IS A SERVER SCRIPT - Place in ServerScriptService                            ║
    ║  All systems are properly defined - No undefined globals!                           ║
    ║  Client UI will be created separately                                              ║
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
    MessagingService = game:GetService("MessagingService"),
    TeleportService = game:GetService("TeleportService"),
    GroupService = game:GetService("GroupService"),
    BadgeService = game:GetService("BadgeService"),
    MemoryStoreService = game:GetService("MemoryStoreService"),
    Chat = game:GetService("Chat"),
    Debris = game:GetService("Debris"),
    PhysicsService = game:GetService("PhysicsService"),
    PathfindingService = game:GetService("PathfindingService"),
    SoundService = game:GetService("SoundService"),
    Lighting = game:GetService("Lighting"),
    LocalizationService = game:GetService("LocalizationService"),
    TestService = game:GetService("TestService"),
    VoiceChatService = game:GetService("VoiceChatService"),
    ContentProvider = game:GetService("ContentProvider"),
    KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider"),
    LogService = game:GetService("LogService"),
    ContextActionService = game:GetService("ContextActionService"),
    TextService = game:GetService("TextService"),
    UserInputService = game:GetService("UserInputService")
}

-- ========================================
-- MODULE SYSTEM
-- ========================================
local SanrioTycoonServer = {
    Version = "5.0.0",
    BuildNumber = 1337,
    Systems = {},
    Modules = {},
    Data = {},
    Cache = {},
    Instances = {}
}

-- Define all system modules
SanrioTycoonServer.Systems.PlayerData = {}
SanrioTycoonServer.Systems.PetSystem = {}
SanrioTycoonServer.Systems.CaseOpening = {}
SanrioTycoonServer.Systems.Trading = {}
SanrioTycoonServer.Systems.Battle = {}
SanrioTycoonServer.Systems.Clan = {}
SanrioTycoonServer.Systems.Quest = {}
SanrioTycoonServer.Systems.Achievement = {}
SanrioTycoonServer.Systems.Daily = {}
SanrioTycoonServer.Systems.BattlePass = {}
SanrioTycoonServer.Systems.Economy = {}
SanrioTycoonServer.Systems.Security = {}
SanrioTycoonServer.Systems.Analytics = {}
SanrioTycoonServer.Systems.Events = {}
SanrioTycoonServer.Systems.Leaderboard = {}
SanrioTycoonServer.Systems.Notification = {}
SanrioTycoonServer.Systems.Social = {}
SanrioTycoonServer.Systems.Rebirth = {}
SanrioTycoonServer.Systems.Evolution = {}
SanrioTycoonServer.Systems.Fusion = {}
SanrioTycoonServer.Systems.Inventory = {}
SanrioTycoonServer.Systems.Market = {}
SanrioTycoonServer.Systems.Auction = {}
SanrioTycoonServer.Systems.Tournament = {}
SanrioTycoonServer.Systems.Minigames = {}
SanrioTycoonServer.Systems.Housing = {}
SanrioTycoonServer.Systems.Customization = {}
SanrioTycoonServer.Systems.Weather = {}
SanrioTycoonServer.Systems.DayNight = {}
SanrioTycoonServer.Systems.Season = {}
SanrioTycoonServer.Systems.WorldBoss = {}
SanrioTycoonServer.Systems.Dungeon = {}
SanrioTycoonServer.Systems.Raid = {}

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
    MarketData = Services.DataStoreService:GetDataStore("SanrioTycoonMarket_v5"),
    AuctionData = Services.DataStoreService:GetDataStore("SanrioTycoonAuction_v5"),
    TournamentData = Services.DataStoreService:GetDataStore("SanrioTycoonTournament_v5"),
    EventData = Services.DataStoreService:GetDataStore("SanrioTycoonEvents_v5"),
    BanData = Services.DataStoreService:GetDataStore("SanrioTycoonBans_v5"),
    PromoData = Services.DataStoreService:GetDataStore("SanrioTycoonPromos_v5"),
    AnalyticsData = Services.DataStoreService:GetDataStore("SanrioTycoonAnalytics_v5"),
    HousingData = Services.DataStoreService:GetDataStore("SanrioTycoonHousing_v5"),
    SeasonData = Services.DataStoreService:GetDataStore("SanrioTycoonSeason_v5")
}

-- ========================================
-- MEMORY STORES
-- ========================================
local MemoryStores = {
    ActivePlayers = Services.MemoryStoreService:GetSortedMap("ActivePlayers"),
    ActiveTrades = Services.MemoryStoreService:GetSortedMap("ActiveTrades"),
    BattleQueue = Services.MemoryStoreService:GetQueue("BattleQueue", 30),
    ClanWars = Services.MemoryStoreService:GetSortedMap("ClanWars"),
    LiveEvents = Services.MemoryStoreService:GetSortedMap("LiveEvents"),
    AuctionHouse = Services.MemoryStoreService:GetSortedMap("AuctionHouse"),
    TournamentQueue = Services.MemoryStoreService:GetQueue("TournamentQueue", 60),
    WorldBosses = Services.MemoryStoreService:GetSortedMap("WorldBosses"),
    DungeonInstances = Services.MemoryStoreService:GetSortedMap("DungeonInstances"),
    RaidGroups = Services.MemoryStoreService:GetSortedMap("RaidGroups")
}

-- ========================================
-- CONFIGURATION
-- ========================================
local CONFIG = {
    -- Version Control
    VERSION = "5.0.0",
    BUILD_NUMBER = 1337,
    API_VERSION = 2,
    
    -- Server Settings
    MAX_PLAYERS = 50,
    SERVER_REGION = game.JobId,
    SERVER_TYPE = "Production", -- Production, Testing, Development
    
    -- DataStore Settings
    DATASTORE_VERSION = 5,
    DATA_AUTOSAVE_INTERVAL = 60,
    DATA_BACKUP_INTERVAL = 300,
    DATA_COMPRESSION = true,
    
    -- Economy Settings
    STARTING_GEMS = 500,
    STARTING_COINS = 10000,
    STARTING_TICKETS = 10,
    STARTING_STARS = 0,
    STARTING_TOKENS = 0,
    
    -- Currency Limits
    MAX_COINS = 999999999999,
    MAX_GEMS = 999999999,
    MAX_TICKETS = 999999,
    MAX_STARS = 999999,
    MAX_TOKENS = 999999,
    
    -- Pet System
    MAX_EQUIPPED_PETS = 6,
    MAX_INVENTORY_SIZE = 500,
    EVOLUTION_COST_MULTIPLIER = 2.5,
    FUSION_SUCCESS_RATE = 0.7,
    MAX_PET_LEVEL = 100,
    PET_XP_MULTIPLIER = 1.5,
    SHINY_CHANCE = 0.02,
    GOLDEN_CHANCE = 0.005,
    RAINBOW_CHANCE = 0.001,
    DARK_MATTER_CHANCE = 0.0001,
    
    -- Trading System
    TRADE_TAX_PERCENTAGE = 0.05,
    MAX_TRADE_ITEMS = 20,
    TRADE_COOLDOWN = 60,
    TRADE_EXPIRY_TIME = 300,
    MIN_LEVEL_TO_TRADE = 10,
    TRADE_HISTORY_LIMIT = 100,
    
    -- Battle System
    BATTLE_REWARDS_MULTIPLIER = 2,
    BATTLE_XP_GAIN = 100,
    BATTLE_COOLDOWN = 30,
    MAX_BATTLE_DURATION = 600,
    BATTLE_ENERGY_COST = 10,
    PVP_ENABLED = true,
    
    -- Clan System
    CLAN_CREATE_COST = 50000,
    CLAN_MAX_MEMBERS = 50,
    CLAN_WAR_COOLDOWN = 86400,
    CLAN_CONTRIBUTION_LIMIT = 100000,
    CLAN_UPGRADE_COSTS = {
        Level2 = 100000,
        Level3 = 500000,
        Level4 = 1000000,
        Level5 = 5000000
    },
    
    -- Quest System
    DAILY_QUEST_COUNT = 5,
    WEEKLY_QUEST_COUNT = 3,
    SPECIAL_QUEST_COUNT = 1,
    QUEST_REFRESH_TIME = {
        Daily = 86400,
        Weekly = 604800,
        Special = 2592000
    },
    
    -- Achievement System
    ACHIEVEMENT_TIERS = {
        Bronze = {multiplier = 1, color = Color3.fromRGB(205, 127, 50)},
        Silver = {multiplier = 2, color = Color3.fromRGB(192, 192, 192)},
        Gold = {multiplier = 5, color = Color3.fromRGB(255, 215, 0)},
        Platinum = {multiplier = 10, color = Color3.fromRGB(229, 228, 226)},
        Diamond = {multiplier = 20, color = Color3.fromRGB(185, 242, 255)}
    },
    
    -- Battle Pass
    BATTLE_PASS_DURATION = 2592000, -- 30 days
    BATTLE_PASS_LEVELS = 100,
    BATTLE_PASS_FREE_REWARDS = 30,
    BATTLE_PASS_PREMIUM_COST = 999,
    
    -- Anti-Exploit
    MAX_REQUESTS_PER_MINUTE = 30,
    SUSPICIOUS_WEALTH_THRESHOLD = 1000000000,
    WEALTH_GAIN_RATE_LIMIT = 10000000,
    ACTION_COOLDOWNS = {
        OpenCase = 1,
        Trade = 5,
        Battle = 10,
        ClaimDaily = 86400,
        Evolve = 5,
        Fuse = 10,
        Rebirth = 60,
        Market = 2,
        Auction = 5
    },
    EXPLOIT_DETECTION = {
        SpeedHack = {threshold = 50, punishment = "kick"},
        TeleportHack = {threshold = 100, punishment = "ban"},
        WealthHack = {threshold = 1000000, punishment = "ban"},
        DuplicationHack = {threshold = 5, punishment = "ban"}
    },
    
    -- Security
    ENCRYPTION_KEY = "SanrioTycoon2024SecureKey",
    SESSION_TIMEOUT = 3600,
    MAX_FAILED_ATTEMPTS = 5,
    IP_RATE_LIMIT = 100,
    
    -- Group Benefits
    GROUP_ID = 123456789,
    GROUP_BONUS_MULTIPLIER = 1.25,
    GROUP_RANKS = {
        Guest = 0,
        Member = 1,
        VIP = 100,
        Moderator = 150,
        Admin = 200,
        Owner = 255
    },
    GROUP_BENEFITS = {
        Member = {coins = 1.1, gems = 1.1, xp = 1.1},
        VIP = {coins = 1.25, gems = 1.25, xp = 1.25},
        Moderator = {coins = 1.5, gems = 1.5, xp = 1.5},
        Admin = {coins = 2, gems = 2, xp = 2},
        Owner = {coins = 3, gems = 3, xp = 3}
    },
    
    -- Premium Benefits
    PREMIUM_MULTIPLIER = 2,
    VIP_MULTIPLIER = 3,
    PREMIUM_DAILY_GEMS = 100,
    VIP_DAILY_GEMS = 250,
    
    -- Events
    EVENT_MULTIPLIER = 2,
    LIMITED_PET_DURATION = 604800,
    EVENT_ROTATION = {
        Monday = "DoubleCoins",
        Tuesday = "DoubleGems",
        Wednesday = "DoubleXP",
        Thursday = "LuckyDay",
        Friday = "SpecialEggs",
        Saturday = "WeekendMadness",
        Sunday = "SuperSunday"
    },
    
    -- Rebirth System
    REBIRTH_REQUIREMENT_MULTIPLIER = 10,
    REBIRTH_BONUS_PER_LEVEL = 0.1,
    MAX_REBIRTH_LEVEL = 100,
    REBIRTH_COSTS = {}, -- Generated dynamically
    
    -- Market System
    MARKET_TAX = 0.1,
    MARKET_LISTING_DURATION = 86400,
    MAX_MARKET_LISTINGS = 10,
    MARKET_HISTORY_LIMIT = 50,
    
    -- Auction System
    AUCTION_TAX = 0.15,
    AUCTION_MIN_INCREMENT = 0.05,
    AUCTION_MAX_DURATION = 172800,
    AUCTION_EXTENSION_TIME = 300,
    
    -- Tournament System
    TOURNAMENT_ENTRY_FEE = 1000,
    TOURNAMENT_PRIZE_POOL = {
        First = 0.5,
        Second = 0.3,
        Third = 0.2
    },
    TOURNAMENT_MIN_PLAYERS = 8,
    TOURNAMENT_MAX_PLAYERS = 64,
    
    -- Housing System
    HOUSE_PLOT_COST = 100000,
    HOUSE_DECORATION_LIMIT = 500,
    HOUSE_VISITOR_LIMIT = 20,
    HOUSE_THEMES = {
        "Classic", "Modern", "Fantasy", "Futuristic", "Nature", "Underwater"
    },
    
    -- Minigames
    MINIGAME_COOLDOWN = 300,
    MINIGAME_REWARDS = {
        Easy = {coins = 1000, gems = 10},
        Medium = {coins = 5000, gems = 50},
        Hard = {coins = 10000, gems = 100},
        Extreme = {coins = 50000, gems = 500}
    },
    
    -- World Boss
    WORLD_BOSS_SPAWN_INTERVAL = 3600,
    WORLD_BOSS_MAX_PLAYERS = 50,
    WORLD_BOSS_HEALTH_MULTIPLIER = 1000,
    WORLD_BOSS_REWARDS_TOP = 10,
    
    -- Dungeons
    DUNGEON_ENERGY_COST = 20,
    DUNGEON_PARTY_SIZE = 4,
    DUNGEON_DIFFICULTIES = {
        Easy = {multiplier = 1, level = 10},
        Normal = {multiplier = 2, level = 25},
        Hard = {multiplier = 5, level = 50},
        Nightmare = {multiplier = 10, level = 75},
        Hell = {multiplier = 20, level = 100}
    },
    
    -- Raids
    RAID_ENERGY_COST = 50,
    RAID_PARTY_SIZE = 8,
    RAID_WEEKLY_LIMIT = 3,
    RAID_REVIVE_COST = 100,
    
    -- Notification Settings
    NOTIFICATION_DURATION = 5,
    MAX_NOTIFICATIONS_QUEUE = 10,
    NOTIFICATION_TYPES = {
        "Info", "Success", "Warning", "Error", "Achievement", "Reward", "System"
    },
    
    -- Performance
    BATCH_SIZE = 50,
    UPDATE_RATE = 30,
    PHYSICS_THROTTLE = true,
    STREAMING_ENABLED = true,
    
    -- Debug
    DEBUG_MODE = false,
    LOG_ANALYTICS = true,
    VERBOSE_ERRORS = false,
    TEST_MODE = false
}

-- Generate rebirth costs
for i = 1, CONFIG.MAX_REBIRTH_LEVEL do
    CONFIG.REBIRTH_COSTS[i] = math.floor(10000 * (CONFIG.REBIRTH_REQUIREMENT_MULTIPLIER ^ (i - 1)))
end

-- ========================================
-- GLOBAL DATA STORAGE
-- ========================================
local PlayerData = {}
local ActiveTrades = {}
local BattleInstances = {}
local ClanData = {}
local QuestPool = {}
local EventSchedule = {}
local ServerAnalytics = {}
local MarketListings = {}
local AuctionListings = {}
local TournamentData = {}
local WorldBossData = {}
local DungeonInstances = {}
local RaidInstances = {}
local HousingData = {}
local MinigameInstances = {}

-- ========================================
-- REMOTE EVENTS & FUNCTIONS
-- ========================================
local RemoteEvents = {}
local RemoteFunctions = {}

-- ========================================
-- RATE LIMITING & SECURITY
-- ========================================
local RateLimiter = {
    requests = {},
    bans = {},
    warnings = {},
    suspiciousActivity = {}
}

function RateLimiter:Check(player, action)
    local userId = player.UserId
    local now = tick()
    
    -- Check if banned
    if self.bans[userId] and self.bans[userId] > now then
        return false, "You are banned from this action until " .. os.date("%c", self.bans[userId])
    end
    
    -- Initialize request tracking
    if not self.requests[userId] then
        self.requests[userId] = {}
    end
    
    if not self.requests[userId][action] then
        self.requests[userId][action] = {
            count = 0,
            resetTime = now + 60,
            history = {}
        }
    end
    
    local requestData = self.requests[userId][action]
    
    -- Reset if time window passed
    if now > requestData.resetTime then
        requestData.count = 0
        requestData.resetTime = now + 60
        requestData.history = {}
    end
    
    -- Track request
    requestData.count = requestData.count + 1
    table.insert(requestData.history, {time = now, action = action})
    
    -- Check rate limit
    if requestData.count > CONFIG.MAX_REQUESTS_PER_MINUTE then
        self:AddWarning(player, "Rate limit exceeded for " .. action)
        
        -- Ban if too many warnings
        if self:GetWarningCount(player) >= CONFIG.MAX_FAILED_ATTEMPTS then
            self:BanPlayer(player, 3600) -- 1 hour ban
            return false, "You have been temporarily banned for excessive requests"
        end
        
        return false, "Rate limit exceeded. Please slow down."
    end
    
    -- Check action-specific cooldowns
    if CONFIG.ACTION_COOLDOWNS[action] then
        if requestData.lastAction and (now - requestData.lastAction) < CONFIG.ACTION_COOLDOWNS[action] then
            local remaining = math.ceil(CONFIG.ACTION_COOLDOWNS[action] - (now - requestData.lastAction))
            return false, "Action on cooldown. Please wait " .. remaining .. " seconds"
        end
        requestData.lastAction = now
    end
    
    return true
end

function RateLimiter:AddWarning(player, reason)
    local userId = player.UserId
    if not self.warnings[userId] then
        self.warnings[userId] = {}
    end
    
    table.insert(self.warnings[userId], {
        time = tick(),
        reason = reason
    })
    
    -- Log suspicious activity
    ServerAnalytics:LogSuspiciousActivity(player, reason)
end

function RateLimiter:GetWarningCount(player)
    local userId = player.UserId
    if not self.warnings[userId] then
        return 0
    end
    
    -- Count warnings in last hour
    local now = tick()
    local count = 0
    for _, warning in ipairs(self.warnings[userId]) do
        if now - warning.time < 3600 then
            count = count + 1
        end
    end
    
    return count
end

function RateLimiter:BanPlayer(player, duration)
    local userId = player.UserId
    self.bans[userId] = tick() + duration
    
    -- Log ban
    ServerAnalytics:LogBan(player, duration)
    
    -- Kick player
    player:Kick("You have been temporarily banned for suspicious activity")
end

function RateLimiter:CheckWealth(player, currency, amount)
    local userId = player.UserId
    local playerData = PlayerData[userId]
    
    if not playerData then
        return false, "No player data"
    end
    
    -- Check suspicious wealth
    if amount > CONFIG.SUSPICIOUS_WEALTH_THRESHOLD then
        self:AddWarning(player, "Suspicious wealth amount: " .. amount)
        return false, "Suspicious transaction detected"
    end
    
    -- Check wealth gain rate
    if not self.suspiciousActivity[userId] then
        self.suspiciousActivity[userId] = {
            lastCheck = tick(),
            totalGained = 0
        }
    end
    
    local activity = self.suspiciousActivity[userId]
    local now = tick()
    
    -- Reset if more than a minute passed
    if now - activity.lastCheck > 60 then
        activity.totalGained = 0
        activity.lastCheck = now
    end
    
    activity.totalGained = activity.totalGained + amount
    
    if activity.totalGained > CONFIG.WEALTH_GAIN_RATE_LIMIT then
        self:AddWarning(player, "Excessive wealth gain rate")
        return false, "Wealth gain rate limit exceeded"
    end
    
    return true
end

function RateLimiter:Reset(player)
    local userId = player.UserId
    self.requests[userId] = nil
    self.warnings[userId] = nil
    self.suspiciousActivity[userId] = nil
end

-- ========================================
-- ANALYTICS SYSTEM
-- ========================================
ServerAnalytics = {
    events = {},
    metrics = {},
    errors = {},
    performance = {}
}

function ServerAnalytics:LogEvent(eventType, player, data)
    if not CONFIG.LOG_ANALYTICS then return end
    
    local event = {
        type = eventType,
        userId = player and player.UserId or "Server",
        timestamp = os.time(),
        data = data or {},
        serverId = game.JobId
    }
    
    table.insert(self.events, event)
    
    -- Save to DataStore periodically
    if #self.events >= 100 then
        self:FlushEvents()
    end
end

function ServerAnalytics:LogError(errorType, errorMessage, stackTrace)
    local error = {
        type = errorType,
        message = errorMessage,
        stack = stackTrace,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    table.insert(self.errors, error)
    
    if CONFIG.VERBOSE_ERRORS then
        warn("[ERROR]", errorType, ":", errorMessage)
        warn("Stack:", stackTrace)
    end
end

function ServerAnalytics:LogPerformance(metric, value)
    if not self.performance[metric] then
        self.performance[metric] = {
            count = 0,
            total = 0,
            min = math.huge,
            max = -math.huge,
            average = 0
        }
    end
    
    local perf = self.performance[metric]
    perf.count = perf.count + 1
    perf.total = perf.total + value
    perf.min = math.min(perf.min, value)
    perf.max = math.max(perf.max, value)
    perf.average = perf.total / perf.count
end

function ServerAnalytics:LogSuspiciousActivity(player, reason)
    self:LogEvent("SuspiciousActivity", player, {
        reason = reason,
        playerData = PlayerData[player.UserId]
    })
end

function ServerAnalytics:LogBan(player, duration)
    self:LogEvent("PlayerBan", player, {
        duration = duration,
        reason = "Automated security system"
    })
end

function ServerAnalytics:FlushEvents()
    -- Save events to DataStore
    spawn(function()
        local success, error = pcall(function()
            local key = "Analytics_" .. os.time() .. "_" .. game.JobId
            DataStores.AnalyticsData:SetAsync(key, self.events)
        end)
        
        if success then
            self.events = {}
        else
            self:LogError("Analytics", "Failed to save analytics", error)
        end
    end)
end

function ServerAnalytics:GetMetrics()
    return {
        events = #self.events,
        errors = #self.errors,
        performance = self.performance,
        uptime = tick()
    }
end

-- ========================================
-- COMPLETE PET DATABASE (100+ PETS)
-- ========================================
local PetDatabase = {}

-- Helper function to generate pet data
local function CreatePet(data)
    -- Add computed fields
    data.xpRequirements = {}
    local baseXP = 100
    for level = 1, data.maxLevel do
        data.xpRequirements[level] = math.floor(baseXP * (1.15 ^ (level - 1)))
    end
    
    -- Add default sounds if not provided
    if not data.sounds then
        data.sounds = {
            spawn = "rbxassetid://0",
            attack = "rbxassetid://0",
            special = "rbxassetid://0",
            hurt = "rbxassetid://0"
        }
    end
    
    -- Add default animations if not provided
    if not data.animations then
        data.animations = {
            idle = "rbxassetid://0",
            walk = "rbxassetid://0",
            attack = "rbxassetid://0",
            special = "rbxassetid://0"
        }
    end
    
    return data
end

-- TIER 1: COMMON PETS (50% drop rate)
PetDatabase["hello_kitty_classic"] = CreatePet({
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
        critDamage = 1.5,
        energy = 100,
        stamina = 100
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
        death = "rbxassetid://10000000008",
        dance = "rbxassetid://10000000009",
        sleep = "rbxassetid://10000000010"
    },
    sounds = {
        spawn = "rbxassetid://10000000011",
        attack = "rbxassetid://10000000012",
        special = "rbxassetid://10000000013",
        hurt = "rbxassetid://10000000014",
        happy = "rbxassetid://10000000015",
        sad = "rbxassetid://10000000016"
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
            energyCost = 20,
            level = 1
        },
        {
            id = "red_bow_power",
            name = "Red Bow Power",
            description = "Grants 10% chance to double rewards",
            passive = true,
            effect = "double_chance",
            value = 0.1,
            level = 10
        },
        {
            id = "friendship_aura",
            name = "Friendship Aura",
            description = "Nearby pets gain 5% happiness",
            passive = true,
            effect = "happiness_aura",
            value = 0.05,
            radius = 20,
            level = 25
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 1000,
        items = {"red_bow", "white_ribbon"},
        friendship = 100
    },
    evolvesTo = "hello_kitty_angel",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 200, 200), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        cosmic = {multiplier = 50, colorShift = "cosmic", particleEffect = "star_field"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["my_melody_classic"] = CreatePet({
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
        critDamage = 1.6,
        energy = 110,
        stamina = 90
    },
    description = "Sweet white rabbit with her signature pink hood",
    imageId = "rbxassetid://10000000017",
    modelId = "rbxassetid://10000000018",
    animations = {
        idle = "rbxassetid://10000000019",
        walk = "rbxassetid://10000000020",
        attack = "rbxassetid://10000000021",
        special = "rbxassetid://10000000022",
        hurt = "rbxassetid://10000000023",
        death = "rbxassetid://10000000024",
        hop = "rbxassetid://10000000025",
        sing = "rbxassetid://10000000026"
    },
    sounds = {
        spawn = "rbxassetid://10000000027",
        attack = "rbxassetid://10000000028",
        special = "rbxassetid://10000000029",
        hurt = "rbxassetid://10000000030",
        melody = "rbxassetid://10000000031"
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
            energyCost = 25,
            level = 1
        },
        {
            id = "pink_hood_protection",
            name = "Pink Hood Protection",
            description = "Reduces damage taken by 15%",
            passive = true,
            effect = "damage_reduction",
            value = 0.15,
            level = 10
        },
        {
            id = "sweet_song",
            name = "Sweet Song",
            description = "Puts enemies to sleep for 3 seconds",
            cooldown = 90,
            effect = "sleep",
            value = 3,
            radius = 25,
            targetType = "enemies",
            energyCost = 40,
            level = 25
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 1000,
        items = {"pink_hood", "melody_note"},
        friendship = 100
    },
    evolvesTo = "my_melody_angel",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 192, 203), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        crystal = {multiplier = 30, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "crystal_shards"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["keroppi_classic"] = CreatePet({
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
        critDamage = 1.7,
        energy = 120,
        stamina = 100
    },
    description = "Cheerful green frog from Donut Pond",
    imageId = "rbxassetid://10000000032",
    modelId = "rbxassetid://10000000033",
    animations = {
        idle = "rbxassetid://10000000034",
        walk = "rbxassetid://10000000035",
        attack = "rbxassetid://10000000036",
        special = "rbxassetid://10000000037",
        jump = "rbxassetid://10000000038",
        swim = "rbxassetid://10000000039",
        ribbit = "rbxassetid://10000000040"
    },
    sounds = {
        spawn = "rbxassetid://10000000041",
        attack = "rbxassetid://10000000042",
        special = "rbxassetid://10000000043",
        ribbit = "rbxassetid://10000000044",
        splash = "rbxassetid://10000000045"
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
            energyCost = 15,
            level = 1
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
            energyCost = 20,
            level = 10
        },
        {
            id = "amphibian_adaptation",
            name = "Amphibian Adaptation",
            description = "Gains 50% speed in water",
            passive = true,
            effect = "water_speed",
            value = 0.5,
            level = 20
        },
        {
            id = "rain_dance",
            name = "Rain Dance",
            description = "Summons rain that heals allies",
            cooldown = 120,
            effect = "rain_heal",
            value = 50,
            duration = 10,
            radius = 40,
            targetType = "area",
            energyCost = 50,
            level = 30
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 1000,
        items = {"lily_pad", "pond_water"},
        swims = 100
    },
    evolvesTo = "keroppi_prince",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 255, 150), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        swamp = {multiplier = 15, colorShift = Color3.fromRGB(50, 100, 50), particleEffect = "swamp_bubbles"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["pochacco_classic"] = CreatePet({
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
        critDamage = 1.8,
        energy = 130,
        stamina = 120
    },
    description = "Sporty white dog who loves basketball",
    imageId = "rbxassetid://10000000046",
    modelId = "rbxassetid://10000000047",
    animations = {
        idle = "rbxassetid://10000000048",
        walk = "rbxassetid://10000000049",
        attack = "rbxassetid://10000000050",
        special = "rbxassetid://10000000051",
        dribble = "rbxassetid://10000000052",
        dunk = "rbxassetid://10000000053",
        victory = "rbxassetid://10000000054"
    },
    sounds = {
        spawn = "rbxassetid://10000000055",
        attack = "rbxassetid://10000000056",
        special = "rbxassetid://10000000057",
        bark = "rbxassetid://10000000058",
        whistle = "rbxassetid://10000000059"
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
            energyCost = 20,
            level = 1
        },
        {
            id = "team_player",
            name = "Team Player",
            description = "Nearby pets gain 10% stats",
            passive = true,
            effect = "aura_boost",
            value = 0.1,
            radius = 25,
            level = 10
        },
        {
            id = "slam_dunk",
            name = "Slam Dunk",
            description = "Powerful attack that stuns for 2 seconds",
            cooldown = 60,
            effect = "stun_attack",
            value = 200,
            stunDuration = 2,
            targetType = "enemy",
            energyCost = 30,
            level = 20
        },
        {
            id = "mvp_mode",
            name = "MVP Mode",
            description = "Doubles all stats for 15 seconds",
            cooldown = 180,
            effect = "stat_multiply",
            value = 2,
            duration = 15,
            targetType = "self",
            energyCost = 60,
            level = 35
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 1000,
        items = {"basketball", "sports_shoes"},
        wins = 50
    },
    evolvesTo = "pochacco_champion",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        allstar = {multiplier = 25, colorShift = Color3.fromRGB(255, 100, 0), particleEffect = "fire_trail"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["tuxedosam_classic"] = CreatePet({
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
        critDamage = 2.0,
        energy = 80,
        stamina = 100
    },
    description = "Dapper penguin in a sailor suit",
    imageId = "rbxassetid://10000000060",
    modelId = "rbxassetid://10000000061",
    animations = {
        idle = "rbxassetid://10000000062",
        walk = "rbxassetid://10000000063",
        attack = "rbxassetid://10000000064",
        special = "rbxassetid://10000000065",
        slide = "rbxassetid://10000000066",
        bow = "rbxassetid://10000000067",
        adjust_tie = "rbxassetid://10000000068"
    },
    sounds = {
        spawn = "rbxassetid://10000000069",
        attack = "rbxassetid://10000000070",
        special = "rbxassetid://10000000071",
        squawk = "rbxassetid://10000000072",
        slide = "rbxassetid://10000000073"
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
            energyCost = 25,
            level = 1
        },
        {
            id = "gentlemans_charm",
            name = "Gentleman's Charm",
            description = "Increases luck by 15%",
            passive = true,
            effect = "luck_boost",
            value = 0.15,
            level = 10
        },
        {
            id = "arctic_wind",
            name = "Arctic Wind",
            description = "Freezes all enemies for 2 seconds",
            cooldown = 90,
            effect = "freeze_all",
            value = 2,
            radius = 30,
            targetType = "all_enemies",
            energyCost = 40,
            level = 25
        },
        {
            id = "formal_occasion",
            name = "Formal Occasion",
            description = "All allies gain 25% stats for 30 seconds",
            cooldown = 150,
            effect = "team_buff",
            value = 0.25,
            duration = 30,
            targetType = "all_allies",
            energyCost = 60,
            level = 40
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 1200,
        items = {"bow_tie", "ice_cube"},
        slides = 200
    },
    evolvesTo = "tuxedosam_admiral",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(150, 150, 255), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        tuxedo = {multiplier = 15, colorShift = Color3.fromRGB(0, 0, 0), particleEffect = "formal_sparkle"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["badtz_maru_classic"] = CreatePet({
    id = "badtz_maru_classic",
    name = "Classic Badtz-Maru",
    displayName = "Badtz-Maru",
    tier = "Common",
    rarity = 1,
    baseValue = 85,
    baseStats = {
        coins = 85,
        gems = 1,
        luck = 5,
        speed = 12,
        power = 60,
        health = 100,
        defense = 12,
        critRate = 0.10,
        critDamage = 2.0,
        energy = 100,
        stamina = 90
    },
    description = "Mischievous penguin with a bad attitude",
    imageId = "rbxassetid://10000000074",
    modelId = "rbxassetid://10000000075",
    animations = {
        idle = "rbxassetid://10000000076",
        walk = "rbxassetid://10000000077",
        attack = "rbxassetid://10000000078",
        special = "rbxassetid://10000000079",
        angry = "rbxassetid://10000000080",
        prank = "rbxassetid://10000000081"
    },
    sounds = {
        spawn = "rbxassetid://10000000082",
        attack = "rbxassetid://10000000083",
        special = "rbxassetid://10000000084",
        grumble = "rbxassetid://10000000085"
    },
    abilities = {
        {
            id = "bad_attitude",
            name = "Bad Attitude",
            description = "Increases damage by 30% when angry",
            passive = true,
            effect = "anger_damage",
            value = 0.3,
            level = 1
        },
        {
            id = "prank_master",
            name = "Prank Master",
            description = "Confuses enemy for 3 seconds",
            cooldown = 40,
            effect = "confuse",
            value = 3,
            targetType = "enemy",
            energyCost = 20,
            level = 15
        },
        {
            id = "rebel_yell",
            name = "Rebel Yell",
            description = "Intimidates all enemies, reducing their stats by 20%",
            cooldown = 80,
            effect = "intimidate",
            value = 0.2,
            duration = 20,
            radius = 30,
            targetType = "all_enemies",
            energyCost = 35,
            level = 30
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 900,
        items = {"rebel_badge", "dark_sunglasses"},
        pranks = 100
    },
    evolvesTo = "badtz_maru_rebel",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(100, 100, 150), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["hangyodon_classic"] = CreatePet({
    id = "hangyodon_classic",
    name = "Classic Hangyodon",
    displayName = "Hangyodon",
    tier = "Common",
    rarity = 1,
    baseValue = 75,
    baseStats = {
        coins = 75,
        gems = 1,
        luck = 8,
        speed = 10,
        power = 45,
        health = 110,
        defense = 14,
        critRate = 0.06,
        critDamage = 1.7,
        energy = 90,
        stamina = 100
    },
    description = "Sea creature from the depths of the ocean",
    imageId = "rbxassetid://10000000086",
    modelId = "rbxassetid://10000000087",
    animations = {
        idle = "rbxassetid://10000000088",
        walk = "rbxassetid://10000000089",
        attack = "rbxassetid://10000000090",
        special = "rbxassetid://10000000091",
        swim = "rbxassetid://10000000092",
        bubble = "rbxassetid://10000000093"
    },
    sounds = {
        spawn = "rbxassetid://10000000094",
        attack = "rbxassetid://10000000095",
        special = "rbxassetid://10000000096",
        bubble = "rbxassetid://10000000097"
    },
    abilities = {
        {
            id = "bubble_shield",
            name = "Bubble Shield",
            description = "Creates protective bubbles that absorb damage",
            cooldown = 45,
            effect = "shield",
            value = 150,
            duration = 10,
            targetType = "self",
            energyCost = 25,
            level = 1
        },
        {
            id = "ocean_dweller",
            name = "Ocean Dweller",
            description = "Regenerates health when in water",
            passive = true,
            effect = "water_regen",
            value = 0.02,
            level = 10
        },
        {
            id = "tidal_wave",
            name = "Tidal Wave",
            description = "Summons a wave that pushes enemies back",
            cooldown = 70,
            effect = "knockback_wave",
            value = 100,
            range = 40,
            targetType = "cone",
            energyCost = 40,
            level = 25
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 800,
        items = {"ocean_pearl", "seaweed"},
        dives = 150
    },
    evolvesTo = "hangyodon_deep",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(100, 200, 255), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["pekkle_classic"] = CreatePet({
    id = "pekkle_classic",
    name = "Classic Pekkle",
    displayName = "Pekkle",
    tier = "Common",
    rarity = 1,
    baseValue = 70,
    baseStats = {
        coins = 70,
        gems = 1,
        luck = 10,
        speed = 14,
        power = 38,
        health = 85,
        defense = 7,
        critRate = 0.09,
        critDamage = 1.6,
        energy = 110,
        stamina = 95
    },
    description = "Friendly white duck who loves to dance",
    imageId = "rbxassetid://10000000098",
    modelId = "rbxassetid://10000000099",
    animations = {
        idle = "rbxassetid://10000000100",
        walk = "rbxassetid://10000000101",
        attack = "rbxassetid://10000000102",
        special = "rbxassetid://10000000103",
        dance = "rbxassetid://10000000104",
        waddle = "rbxassetid://10000000105"
    },
    sounds = {
        spawn = "rbxassetid://10000000106",
        attack = "rbxassetid://10000000107",
        special = "rbxassetid://10000000108",
        quack = "rbxassetid://10000000109"
    },
    abilities = {
        {
            id = "happy_dance",
            name = "Happy Dance",
            description = "Increases team morale and speed by 15%",
            cooldown = 50,
            effect = "team_morale",
            value = 0.15,
            duration = 25,
            radius = 30,
            targetType = "all_allies",
            energyCost = 20,
            level = 1
        },
        {
            id = "lucky_duck",
            name = "Lucky Duck",
            description = "Increases luck by 20%",
            passive = true,
            effect = "luck_increase",
            value = 0.2,
            level = 12
        },
        {
            id = "feather_flurry",
            name = "Feather Flurry",
            description = "Shoots feathers in all directions",
            cooldown = 60,
            effect = "projectile_burst",
            value = 50,
            projectileCount = 8,
            targetType = "area",
            energyCost = 30,
            level = 28
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 750,
        items = {"golden_feather", "dance_shoes"},
        dances = 100
    },
    evolvesTo = "pekkle_star",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["ahiru_no_pekkle_classic"] = CreatePet({
    id = "ahiru_no_pekkle_classic",
    name = "Classic Ahiru no Pekkle",
    displayName = "Ahiru no Pekkle",
    tier = "Common",
    rarity = 1,
    baseValue = 65,
    baseStats = {
        coins = 65,
        gems = 1,
        luck = 12,
        speed = 11,
        power = 35,
        health = 80,
        defense = 6,
        critRate = 0.11,
        critDamage = 1.5,
        energy = 115,
        stamina = 90
    },
    description = "Pekkle's cheerful friend who brings good fortune",
    imageId = "rbxassetid://10000000110",
    modelId = "rbxassetid://10000000111",
    animations = {
        idle = "rbxassetid://10000000112",
        walk = "rbxassetid://10000000113",
        attack = "rbxassetid://10000000114",
        special = "rbxassetid://10000000115",
        flutter = "rbxassetid://10000000116"
    },
    sounds = {
        spawn = "rbxassetid://10000000117",
        attack = "rbxassetid://10000000118",
        special = "rbxassetid://10000000119",
        chirp = "rbxassetid://10000000120"
    },
    abilities = {
        {
            id = "fortune_finder",
            name = "Fortune Finder",
            description = "Increases coin drops by 25%",
            passive = true,
            effect = "coin_find",
            value = 0.25,
            level = 1
        },
        {
            id = "lucky_charm",
            name = "Lucky Charm",
            description = "Grants a random buff to an ally",
            cooldown = 40,
            effect = "random_buff",
            value = 1,
            duration = 20,
            targetType = "ally",
            energyCost = 15,
            level = 18
        }
    },
    evolutionRequirements = {
        level = 25,
        gems = 700,
        items = {"fortune_coin", "lucky_clover"},
        coinsFound = 10000
    },
    evolvesTo = "ahiru_no_pekkle_fortune",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 220, 100), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

-- TIER 2: UNCOMMON PETS (30% drop rate)
PetDatabase["kuromi_classic"] = CreatePet({
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
        critDamage = 2.0,
        energy = 100,
        stamina = 100
    },
    description = "Mischievous white rabbit with devil horns and a pink skull",
    imageId = "rbxassetid://10000000121",
    modelId = "rbxassetid://10000000122",
    animations = {
        idle = "rbxassetid://10000000123",
        walk = "rbxassetid://10000000124",
        attack = "rbxassetid://10000000125",
        special = "rbxassetid://10000000126",
        evil_laugh = "rbxassetid://10000000127",
        devil_stance = "rbxassetid://10000000128"
    },
    sounds = {
        spawn = "rbxassetid://10000000129",
        attack = "rbxassetid://10000000130",
        special = "rbxassetid://10000000131",
        laugh = "rbxassetid://10000000132",
        growl = "rbxassetid://10000000133"
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
            energyCost = 30,
            level = 1
        },
        {
            id = "mischief_maker",
            name = "Mischief Maker",
            description = "25% chance to steal enemy buffs",
            passive = true,
            effect = "steal_buffs",
            value = 0.25,
            level = 10
        },
        {
            id = "devils_luck",
            name = "Devil's Luck",
            description = "Increases critical hit chance by 20%",
            passive = true,
            effect = "crit_chance",
            value = 0.2,
            level = 15
        },
        {
            id = "nightmare_realm",
            name = "Nightmare Realm",
            description = "Traps enemies in a nightmare for 4 seconds",
            cooldown = 120,
            effect = "nightmare",
            value = 4,
            radius = 30,
            targetType = "all_enemies",
            energyCost = 60,
            level = 30
        }
    },
    evolutionRequirements = {
        level = 35,
        gems = 2500,
        items = {"devil_horn", "pink_skull", "dark_essence"},
        darkSpells = 50
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
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["cinnamoroll_classic"] = CreatePet({
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
        critDamage = 1.8,
        energy = 120,
        stamina = 110
    },
    description = "Fluffy white puppy who can fly with his long ears",
    imageId = "rbxassetid://10000000134",
    modelId = "rbxassetid://10000000135",
    animations = {
        idle = "rbxassetid://10000000136",
        walk = "rbxassetid://10000000137",
        attack = "rbxassetid://10000000138",
        special = "rbxassetid://10000000139",
        fly = "rbxassetid://10000000140",
        cloud_ride = "rbxassetid://10000000141",
        tail_wag = "rbxassetid://10000000142"
    },
    sounds = {
        spawn = "rbxassetid://10000000143",
        attack = "rbxassetid://10000000144",
        special = "rbxassetid://10000000145",
        fly = "rbxassetid://10000000146",
        happy = "rbxassetid://10000000147"
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
            energyCost = 35,
            level = 1
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
            energyCost = 40,
            level = 12
        },
        {
            id = "fluffy_shield",
            name = "Fluffy Shield",
            description = "Absorbs next 3 attacks",
            cooldown = 90,
            effect = "shield",
            value = 3,
            targetType = "self",
            energyCost = 30,
            level = 20
        },
        {
            id = "cafe_aroma",
            name = "Cafe Aroma",
            description = "Heals all allies and increases their energy",
            cooldown = 120,
            effect = "heal_energy",
            healValue = 0.25,
            energyValue = 50,
            radius = 40,
            targetType = "all_allies",
            energyCost = 50,
            level = 35
        }
    },
    evolutionRequirements = {
        level = 35,
        gems = 3000,
        items = {"cloud_essence", "cinnamon_stick", "white_wings"},
        flights = 100
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
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["pompompurin_classic"] = CreatePet({
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
        critDamage = 2.2,
        energy = 90,
        stamina = 120
    },
    description = "Golden retriever who loves pudding",
    imageId = "rbxassetid://10000000148",
    modelId = "rbxassetid://10000000149",
    animations = {
        idle = "rbxassetid://10000000150",
        walk = "rbxassetid://10000000151",
        attack = "rbxassetid://10000000152",
        special = "rbxassetid://10000000153",
        eat = "rbxassetid://10000000154",
        nap = "rbxassetid://10000000155",
        tail_chase = "rbxassetid://10000000156"
    },
    sounds = {
        spawn = "rbxassetid://10000000157",
        attack = "rbxassetid://10000000158",
        special = "rbxassetid://10000000159",
        eat = "rbxassetid://10000000160",
        yawn = "rbxassetid://10000000161"
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
            energyCost = 40,
            level = 1
        },
        {
            id = "golden_retriever",
            name = "Golden Retriever",
            description = "Fetches extra loot from defeated enemies",
            passive = true,
            effect = "extra_loot",
            value = 0.5,
            level = 8
        },
        {
            id = "loyalty_bonus",
            name = "Loyalty Bonus",
            description = "Nearby pets gain 10% stats",
            passive = true,
            effect = "aura_boost",
            value = 0.1,
            radius = 30,
            level = 15
        },
        {
            id = "pudding_party",
            name = "Pudding Party",
            description = "Creates puddings that heal allies over time",
            cooldown = 100,
            effect = "healing_items",
            value = 5,
            healPerItem = 100,
            duration = 30,
            targetType = "area",
            energyCost = 60,
            level = 30
        }
    },
    evolutionRequirements = {
        level = 35,
        gems = 2800,
        items = {"golden_collar", "pudding_bowl", "beret"},
        puddings = 200
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
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["chococat_classic"] = CreatePet({
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
        critDamage = 2.0,
        energy = 110,
        stamina = 100
    },
    description = "Black cat with excellent knowledge and big eyes",
    imageId = "rbxassetid://10000000162",
    modelId = "rbxassetid://10000000163",
    animations = {
        idle = "rbxassetid://10000000164",
        walk = "rbxassetid://10000000165",
        attack = "rbxassetid://10000000166",
        special = "rbxassetid://10000000167",
        think = "rbxassetid://10000000168",
        read = "rbxassetid://10000000169"
    },
    sounds = {
        spawn = "rbxassetid://10000000170",
        attack = "rbxassetid://10000000171",
        special = "rbxassetid://10000000172",
        meow = "rbxassetid://10000000173",
        purr = "rbxassetid://10000000174"
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
            energyCost = 50,
            level = 1
        },
        {
            id = "cat_reflexes",
            name = "Cat Reflexes",
            description = "30% dodge chance",
            passive = true,
            effect = "dodge_chance",
            value = 0.3,
            level = 10
        },
        {
            id = "smart_investment",
            name = "Smart Investment",
            description = "20% more rewards from all sources",
            passive = true,
            effect = "reward_boost",
            value = 0.2,
            level = 18
        },
        {
            id = "genius_insight",
            name = "Genius Insight",
            description = "Reveals enemy weaknesses and increases team crit rate",
            cooldown = 90,
            effect = "insight",
            critBoost = 0.25,
            duration = 30,
            targetType = "team",
            energyCost = 45,
            level = 32
        }
    },
    evolutionRequirements = {
        level = 35,
        gems = 3200,
        items = {"book_of_knowledge", "cat_collar", "glasses"},
        booksRead = 50
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
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["monkichi_classic"] = CreatePet({
    id = "monkichi_classic",
    name = "Classic Monkichi",
    displayName = "Monkichi",
    tier = "Uncommon",
    rarity = 2,
    baseValue = 480,
    baseStats = {
        coins = 240,
        gems = 3,
        luck = 14,
        speed = 25,
        power = 85,
        health = 145,
        defense = 15,
        critRate = 0.13,
        critDamage = 2.1,
        energy = 130,
        stamina = 115
    },
    description = "Energetic monkey who loves bananas and adventures",
    imageId = "rbxassetid://10000000175",
    modelId = "rbxassetid://10000000176",
    animations = {
        idle = "rbxassetid://10000000177",
        walk = "rbxassetid://10000000178",
        attack = "rbxassetid://10000000179",
        special = "rbxassetid://10000000180",
        swing = "rbxassetid://10000000181",
        banana_throw = "rbxassetid://10000000182"
    },
    sounds = {
        spawn = "rbxassetid://10000000183",
        attack = "rbxassetid://10000000184",
        special = "rbxassetid://10000000185",
        monkey_sound = "rbxassetid://10000000186"
    },
    abilities = {
        {
            id = "banana_barrage",
            name = "Banana Barrage",
            description = "Throws multiple bananas that stun enemies",
            cooldown = 40,
            effect = "projectile_stun",
            value = 80,
            projectileCount = 5,
            stunDuration = 1.5,
            targetType = "cone",
            energyCost = 35,
            level = 1
        },
        {
            id = "jungle_agility",
            name = "Jungle Agility",
            description = "Increases speed and jump height by 30%",
            passive = true,
            effect = "agility_boost",
            value = 0.3,
            level = 12
        },
        {
            id = "monkey_business",
            name = "Monkey Business",
            description = "Steals items from enemies",
            cooldown = 60,
            effect = "steal_items",
            value = 1,
            targetType = "enemy",
            energyCost = 25,
            level = 25
        }
    },
    evolutionRequirements = {
        level = 35,
        gems = 2400,
        items = {"golden_banana", "vine_rope"},
        swings = 300
    },
    evolvesTo = "monkichi_king",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 200, 100), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["rururugakuen_classic"] = CreatePet({
    id = "rururugakuen_classic",
    name = "Classic Rururugakuen",
    displayName = "Rururugakuen",
    tier = "Uncommon",
    rarity = 2,
    baseValue = 530,
    baseStats = {
        coins = 265,
        gems = 4,
        luck = 16,
        speed = 18,
        power = 78,
        health = 135,
        defense = 17,
        critRate = 0.14,
        critDamage = 1.9,
        energy = 105,
        stamina = 105
    },
    description = "School uniform character ready to learn",
    imageId = "rbxassetid://10000000187",
    modelId = "rbxassetid://10000000188",
    animations = {
        idle = "rbxassetid://10000000189",
        walk = "rbxassetid://10000000190",
        attack = "rbxassetid://10000000191",
        special = "rbxassetid://10000000192",
        study = "rbxassetid://10000000193",
        raise_hand = "rbxassetid://10000000194"
    },
    sounds = {
        spawn = "rbxassetid://10000000195",
        attack = "rbxassetid://10000000196",
        special = "rbxassetid://10000000197",
        bell = "rbxassetid://10000000198"
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
            energyCost = 45,
            level = 1
        },
        {
            id = "honor_student",
            name = "Honor Student",
            description = "Gains bonus stats based on level",
            passive = true,
            effect = "level_scaling",
            value = 0.01,
            level = 8
        },
        {
            id = "perfect_attendance",
            name = "Perfect Attendance",
            description = "Increases daily reward bonuses",
            passive = true,
            effect = "daily_bonus",
            value = 0.5,
            level = 20
        },
        {
            id = "graduation_ceremony",
            name = "Graduation Ceremony",
            description = "Evolves a random ally to next form",
            cooldown = 300,
            effect = "ally_evolve",
            value = 1,
            targetType = "ally",
            energyCost = 80,
            level = 40
        }
    },
    evolutionRequirements = {
        level = 35,
        gems = 2650,
        items = {"diploma", "honor_badge"},
        lessonsCompleted = 100
    },
    evolvesTo = "rururugakuen_graduate",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["u_sa_ha_na_classic"] = CreatePet({
    id = "u_sa_ha_na_classic",
    name = "Classic U*SA*HA*NA",
    displayName = "U*SA*HA*NA",
    tier = "Uncommon",
    rarity = 2,
    baseValue = 510,
    baseStats = {
        coins = 255,
        gems = 3,
        luck = 13,
        speed = 16,
        power = 82,
        health = 155,
        defense = 19,
        critRate = 0.11,
        critDamage = 2.0,
        energy = 100,
        stamina = 110
    },
    description = "Colorful rabbit who loves rainbows and flowers",
    imageId = "rbxassetid://10000000199",
    modelId = "rbxassetid://10000000200",
    animations = {
        idle = "rbxassetid://10000000201",
        walk = "rbxassetid://10000000202",
        attack = "rbxassetid://10000000203",
        special = "rbxassetid://10000000204",
        flower_dance = "rbxassetid://10000000205",
        rainbow_jump = "rbxassetid://10000000206"
    },
    sounds = {
        spawn = "rbxassetid://10000000207",
        attack = "rbxassetid://10000000208",
        special = "rbxassetid://10000000209",
        giggle = "rbxassetid://10000000210"
    },
    abilities = {
        {
            id = "rainbow_power",
            name = "Rainbow Power",
            description = "Creates a rainbow that boosts all stats by 25%",
            cooldown = 70,
            effect = "rainbow_boost",
            value = 0.25,
            duration = 25,
            radius = 35,
            targetType = "area",
            energyCost = 40,
            level = 1
        },
        {
            id = "flower_garden",
            name = "Flower Garden",
            description = "Spawns flowers that heal allies",
            cooldown = 50,
            effect = "healing_garden",
            value = 30,
            flowerCount = 5,
            duration = 20,
            targetType = "area",
            energyCost = 30,
            level = 15
        },
        {
            id = "colorful_personality",
            name = "Colorful Personality",
            description = "Randomly changes variant each battle",
            passive = true,
            effect = "variant_shift",
            value = 1,
            level = 25
        }
    },
    evolutionRequirements = {
        level = 35,
        gems = 2550,
        items = {"rainbow_crystal", "flower_crown"},
        rainbowsCreated = 50
    },
    evolvesTo = "u_sa_ha_na_rainbow",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 200, 255), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

-- Continue in next part...-- TIER 3: RARE PETS (15% drop rate)
PetDatabase["gudetama_classic"] = CreatePet({
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
        critDamage = 3.0,
        energy = 50,
        stamina = 200
    },
    description = "Lazy egg who just wants to be left alone",
    imageId = "rbxassetid://10000000211",
    modelId = "rbxassetid://10000000212",
    animations = {
        idle = "rbxassetid://10000000213",
        walk = "rbxassetid://10000000214",
        attack = "rbxassetid://10000000215",
        special = "rbxassetid://10000000216",
        lazy = "rbxassetid://10000000217",
        yawn = "rbxassetid://10000000218",
        flop = "rbxassetid://10000000219"
    },
    sounds = {
        spawn = "rbxassetid://10000000220",
        attack = "rbxassetid://10000000221",
        special = "rbxassetid://10000000222",
        yawn = "rbxassetid://10000000223",
        sigh = "rbxassetid://10000000224"
    },
    abilities = {
        {
            id = "lazy_shield",
            name = "Lazy Shield",
            description = "Too lazy to take damage - blocks 50% damage",
            passive = true,
            effect = "damage_reduction",
            value = 0.5,
            level = 1
        },
        {
            id = "egg_sistential_crisis",
            name = "Egg-sistential Crisis",
            description = "Confuses all enemies for 5 seconds",
            cooldown = 60,
            effect = "confuse_all",
            value = 5,
            targetType = "all_enemies",
            energyCost = 20,
            level = 10
        },
        {
            id = "cant_be_bothered",
            name = "Can't Be Bothered",
            description = "Immune to all debuffs",
            passive = true,
            effect = "debuff_immunity",
            value = 1,
            level = 20
        },
        {
            id = "lazy_luck",
            name = "Lazy Luck",
            description = "30% chance to dodge any attack",
            passive = true,
            effect = "dodge_chance",
            value = 0.3,
            level = 25
        },
        {
            id = "ultimate_laziness",
            name = "Ultimate Laziness",
            description = "Sleeps for 10 seconds, then deals massive damage",
            cooldown = 180,
            effect = "sleep_burst",
            sleepDuration = 10,
            damage = 1000,
            radius = 50,
            targetType = "self",
            energyCost = 10,
            level = 40
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 6000,
        items = {"egg_shell", "bacon_strip", "lazy_essence"},
        napsToken = 500
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
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["aggretsuko_classic"] = CreatePet({
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
        critDamage = 2.8,
        energy = 100,
        stamina = 100
    },
    description = "Red panda office worker with rage issues",
    imageId = "rbxassetid://10000000225",
    modelId = "rbxassetid://10000000226",
    animations = {
        idle = "rbxassetid://10000000227",
        walk = "rbxassetid://10000000228",
        attack = "rbxassetid://10000000229",
        special = "rbxassetid://10000000230",
        rage = "rbxassetid://10000000231",
        scream = "rbxassetid://10000000232",
        office_work = "rbxassetid://10000000233"
    },
    sounds = {
        spawn = "rbxassetid://10000000234",
        attack = "rbxassetid://10000000235",
        special = "rbxassetid://10000000236",
        rage = "rbxassetid://10000000237",
        metal_scream = "rbxassetid://10000000238"
    },
    abilities = {
        {
            id = "rage_mode",
            name = "Rage Mode",
            description = "Doubles all stats when below 50% health",
            passive = true,
            effect = "rage_trigger",
            value = 2,
            threshold = 0.5,
            level = 1
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
            energyCost = 60,
            level = 15
        },
        {
            id = "office_fury",
            name = "Office Fury",
            description = "Gains power from stress (time-based)",
            passive = true,
            effect = "time_scaling",
            value = 0.02,
            level = 20
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
            energyCost = 40,
            level = 30
        },
        {
            id = "karaoke_night",
            name = "Karaoke Night",
            description = "Switches between calm and rage, gaining different buffs",
            cooldown = 120,
            effect = "mode_switch",
            calmBonus = {defense = 2, health = 2},
            rageBonus = {power = 2, critRate = 0.5},
            duration = 60,
            targetType = "self",
            energyCost = 50,
            level = 45
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 6500,
        items = {"microphone", "office_badge", "rage_essence"},
        rageOuts = 100
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
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["kiki_and_lala_classic"] = CreatePet({
    id = "kiki_and_lala_classic",
    name = "Classic Kiki & Lala",
    displayName = "Little Twin Stars",
    tier = "Rare",
    rarity = 3,
    baseValue = 1100,
    baseStats = {
        coins = 550,
        gems = 9,
        luck = 25,
        speed = 20,
        power = 120,
        health = 220,
        defense = 30,
        critRate = 0.18,
        critDamage = 2.2,
        energy = 110,
        stamina = 110
    },
    description = "The Little Twin Stars from the starry sky",
    imageId = "rbxassetid://10000000239",
    modelId = "rbxassetid://10000000240",
    animations = {
        idle = "rbxassetid://10000000241",
        walk = "rbxassetid://10000000242",
        attack = "rbxassetid://10000000243",
        special = "rbxassetid://10000000244",
        float = "rbxassetid://10000000245",
        star_dance = "rbxassetid://10000000246"
    },
    sounds = {
        spawn = "rbxassetid://10000000247",
        attack = "rbxassetid://10000000248",
        special = "rbxassetid://10000000249",
        twinkle = "rbxassetid://10000000250"
    },
    abilities = {
        {
            id = "twin_bond",
            name = "Twin Bond",
            description = "Shares damage and healing between twins",
            passive = true,
            effect = "damage_share",
            value = 0.5,
            level = 1
        },
        {
            id = "starlight_blessing",
            name = "Starlight Blessing",
            description = "Heals and buffs all allies",
            cooldown = 80,
            effect = "bless_all",
            healValue = 0.3,
            buffValue = 0.2,
            duration = 30,
            targetType = "all_allies",
            energyCost = 50,
            level = 12
        },
        {
            id = "celestial_dance",
            name = "Celestial Dance",
            description = "Creates a starfield that damages enemies",
            cooldown = 100,
            effect = "starfield",
            value = 50,
            tickRate = 0.5,
            duration = 20,
            radius = 40,
            targetType = "area",
            energyCost = 60,
            level = 25
        },
        {
            id = "wish_upon_a_star",
            name = "Wish Upon a Star",
            description = "Grants a random powerful buff to team",
            cooldown = 200,
            effect = "random_wish",
            possibleBuffs = {"invincibility", "double_damage", "instant_heal", "time_stop"},
            duration = 15,
            targetType = "team",
            energyCost = 80,
            level = 40
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 5500,
        items = {"star_fragment", "moon_dust", "celestial_crown"},
        wishes = 77
    },
    evolvesTo = "kiki_and_lala_celestial",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "star_sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        cosmic = {multiplier = 40, colorShift = "cosmic", particleEffect = "galaxy_swirl"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["dear_daniel_classic"] = CreatePet({
    id = "dear_daniel_classic",
    name = "Classic Dear Daniel",
    displayName = "Dear Daniel",
    tier = "Rare",
    rarity = 3,
    baseValue = 1000,
    baseStats = {
        coins = 500,
        gems = 8,
        luck = 20,
        speed = 18,
        power = 140,
        health = 240,
        defense = 35,
        critRate = 0.16,
        critDamage = 2.4,
        energy = 100,
        stamina = 105
    },
    description = "Hello Kitty's childhood friend and boyfriend",
    imageId = "rbxassetid://10000000251",
    modelId = "rbxassetid://10000000252",
    animations = {
        idle = "rbxassetid://10000000253",
        walk = "rbxassetid://10000000254",
        attack = "rbxassetid://10000000255",
        special = "rbxassetid://10000000256",
        dance = "rbxassetid://10000000257",
        photo = "rbxassetid://10000000258"
    },
    sounds = {
        spawn = "rbxassetid://10000000259",
        attack = "rbxassetid://10000000260",
        special = "rbxassetid://10000000261",
        camera = "rbxassetid://10000000262"
    },
    abilities = {
        {
            id = "photography",
            name = "Photography",
            description = "Captures moment, stunning enemies briefly",
            cooldown = 45,
            effect = "camera_flash",
            value = 100,
            stunDuration = 2,
            radius = 25,
            targetType = "cone",
            energyCost = 30,
            level = 1
        },
        {
            id = "gentleman_charm",
            name = "Gentleman's Charm",
            description = "Increases team's luck and happiness",
            passive = true,
            effect = "charm_aura",
            luckBonus = 0.15,
            happinessBonus = 0.1,
            radius = 30,
            level = 10
        },
        {
            id = "dance_partner",
            name = "Dance Partner",
            description = "Boosts stats when near Hello Kitty",
            passive = true,
            effect = "partner_boost",
            value = 0.5,
            partner = "hello_kitty",
            level = 20
        },
        {
            id = "travel_memories",
            name = "Travel Memories",
            description = "Shares experiences, boosting team XP",
            cooldown = 120,
            effect = "xp_share",
            value = 0.5,
            duration = 60,
            targetType = "team",
            energyCost = 50,
            level = 35
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 5000,
        items = {"camera", "travel_journal", "gentleman_suit"},
        photosToken = 200
    },
    evolvesTo = "dear_daniel_world",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["mimmy_classic"] = CreatePet({
    id = "mimmy_classic",
    name = "Classic Mimmy",
    displayName = "Mimmy",
    tier = "Rare",
    rarity = 3,
    baseValue = 1050,
    baseStats = {
        coins = 525,
        gems = 8,
        luck = 22,
        speed = 16,
        power = 130,
        health = 230,
        defense = 32,
        critRate = 0.15,
        critDamage = 2.3,
        energy = 105,
        stamina = 100
    },
    description = "Hello Kitty's twin sister with a yellow bow",
    imageId = "rbxassetid://10000000263",
    modelId = "rbxassetid://10000000264",
    animations = {
        idle = "rbxassetid://10000000265",
        walk = "rbxassetid://10000000266",
        attack = "rbxassetid://10000000267",
        special = "rbxassetid://10000000268",
        shy = "rbxassetid://10000000269",
        sister_hug = "rbxassetid://10000000270"
    },
    sounds = {
        spawn = "rbxassetid://10000000271",
        attack = "rbxassetid://10000000272",
        special = "rbxassetid://10000000273",
        giggle = "rbxassetid://10000000274"
    },
    abilities = {
        {
            id = "sisterly_love",
            name = "Sisterly Love",
            description = "Heals and protects Hello Kitty",
            cooldown = 60,
            effect = "protect_sister",
            healValue = 0.5,
            shieldValue = 300,
            targetType = "specific_ally",
            targetId = "hello_kitty",
            energyCost = 40,
            level = 1
        },
        {
            id = "shy_power",
            name = "Shy Power",
            description = "Becomes stronger when taking damage",
            passive = true,
            effect = "damage_stack",
            value = 0.05,
            maxStacks = 10,
            level = 12
        },
        {
            id = "twin_telepathy",
            name = "Twin Telepathy",
            description = "Copies Hello Kitty's buffs",
            passive = true,
            effect = "copy_buffs",
            targetId = "hello_kitty",
            level = 22
        },
        {
            id = "yellow_bow_magic",
            name = "Yellow Bow Magic",
            description = "Creates protective barriers for all allies",
            cooldown = 100,
            effect = "barrier_all",
            value = 200,
            duration = 20,
            targetType = "all_allies",
            energyCost = 60,
            level = 38
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 5250,
        items = {"yellow_bow", "twin_pendant", "sister_bond"},
        sistersHelped = 100
    },
    evolvesTo = "mimmy_guardian",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

-- TIER 4: EPIC PETS (4% drop rate)
PetDatabase["hello_kitty_angel"] = CreatePet({
    id = "hello_kitty_angel",
    name = "Angel Hello Kitty",
    displayName = "Angel Hello Kitty",
    tier = "Epic",
    rarity = 4,
    baseValue = 5000,
    baseStats = {
        coins = 1200,
        gems = 20,
        luck = 40,
        speed = 35,
        power = 300,
        health = 500,
        defense = 60,
        critRate = 0.20,
        critDamage = 3.0,
        energy = 150,
        stamina = 150
    },
    description = "Divine Hello Kitty with angelic wings",
    imageId = "rbxassetid://10000000275",
    modelId = "rbxassetid://10000000276",
    animations = {
        idle = "rbxassetid://10000000277",
        walk = "rbxassetid://10000000278",
        attack = "rbxassetid://10000000279",
        special = "rbxassetid://10000000280",
        fly = "rbxassetid://10000000281",
        bless = "rbxassetid://10000000282",
        ascend = "rbxassetid://10000000283"
    },
    sounds = {
        spawn = "rbxassetid://10000000284",
        attack = "rbxassetid://10000000285",
        special = "rbxassetid://10000000286",
        bless = "rbxassetid://10000000287",
        choir = "rbxassetid://10000000288"
    },
    abilities = {
        {
            id = "divine_blessing",
            name = "Divine Blessing",
            description = "Blesses all pets, doubling their stats for 60 seconds",
            cooldown = 300,
            effect = "blessing_aoe",
            value = 2,
            duration = 60,
            targetType = "all_allies",
            energyCost = 80,
            level = 1
        },
        {
            id = "heavenly_shield",
            name = "Heavenly Shield",
            description = "Creates an impenetrable shield for all allies",
            cooldown = 240,
            effect = "team_shield",
            value = 10,
            duration = 10,
            targetType = "team",
            energyCost = 60,
            level = 15
        },
        {
            id = "angels_grace",
            name = "Angel's Grace",
            description = "Revives fallen pets with 50% health",
            cooldown = 600,
            effect = "revive_all",
            value = 0.5,
            targetType = "fallen_allies",
            energyCost = 100,
            level = 25
        },
        {
            id = "celestial_aura",
            name = "Celestial Aura",
            description = "All pets gain 30% stats",
            passive = true,
            effect = "aura_boost",
            value = 0.3,
            level = 30
        },
        {
            id = "holy_light",
            name = "Holy Light",
            description = "Damages all enemies and heals all allies",
            cooldown = 180,
            effect = "holy_burst",
            damage = 500,
            heal = 0.3,
            targetType = "all",
            energyCost = 90,
            level = 40
        },
        {
            id = "miracle",
            name = "Miracle",
            description = "Instantly wins battle if health below 10%",
            passive = true,
            effect = "miracle_win",
            threshold = 0.1,
            cooldown = 86400,
            level = 50
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 15000,
        items = {"angel_halo", "divine_wings", "celestial_orb", "blessed_ribbon"},
        blessings = 100
    },
    evolvesTo = "hello_kitty_goddess",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "holy_sparkle"},
        crystal = {multiplier = 10, colorShift = Color3.fromRGB(200, 255, 255), particleEffect = "crystal_aura"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_wings"},
        cosmic = {multiplier = 50, colorShift = "cosmic", particleEffect = "cosmic_halo"},
        divine = {multiplier = 100, colorShift = Color3.fromRGB(255, 255, 255), particleEffect = "divine_light"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["kuromi_demon"] = CreatePet({
    id = "kuromi_demon",
    name = "Demon Kuromi",
    displayName = "Demon Kuromi",
    tier = "Epic",
    rarity = 4,
    baseValue = 4500,
    baseStats = {
        coins = 1000,
        gems = 18,
        luck = 35,
        speed = 40,
        power = 350,
        health = 450,
        defense = 50,
        critRate = 0.30,
        critDamage = 3.5,
        energy = 140,
        stamina = 140
    },
    description = "Kuromi embracing her demonic powers",
    imageId = "rbxassetid://10000000289",
    modelId = "rbxassetid://10000000290",
    animations = {
        idle = "rbxassetid://10000000291",
        walk = "rbxassetid://10000000292",
        attack = "rbxassetid://10000000293",
        special = "rbxassetid://10000000294",
        transform = "rbxassetid://10000000295",
        rage = "rbxassetid://10000000296",
        summon = "rbxassetid://10000000297"
    },
    sounds = {
        spawn = "rbxassetid://10000000298",
        attack = "rbxassetid://10000000299",
        special = "rbxassetid://10000000300",
        transform = "rbxassetid://10000000301",
        evil_laugh = "rbxassetid://10000000302"
    },
    abilities = {
        {
            id = "demonic_transformation",
            name = "Demonic Transformation",
            description = "Transform into demon form, tripling all stats",
            cooldown = 300,
            effect = "transform",
            value = 3,
            duration = 45,
            targetType = "self",
            energyCost = 100,
            level = 1
        },
        {
            id = "hells_fury",
            name = "Hell's Fury",
            description = "Unleashes demonic rage, dealing massive damage",
            cooldown = 180,
            effect = "fury_attack",
            value = 1000,
            radius = 40,
            targetType = "area",
            energyCost = 80,
            level = 12
        },
        {
            id = "soul_steal",
            name = "Soul Steal",
            description = "Steals 20% of enemy's max health",
            cooldown = 120,
            effect = "life_steal",
            value = 0.2,
            targetType = "enemy",
            energyCost = 60,
            level = 20
        },
        {
            id = "infernal_presence",
            name = "Infernal Presence",
            description = "Enemies take damage over time",
            passive = true,
            effect = "damage_aura",
            value = 50,
            radius = 30,
            level = 28
        },
        {
            id = "dark_pact",
            name = "Dark Pact",
            description = "Sacrifice 20% HP for 100% damage boost",
            cooldown = 90,
            effect = "blood_pact",
            cost = 0.2,
            boost = 1,
            duration = 30,
            targetType = "self",
            energyCost = 40,
            level = 35
        },
        {
            id = "summon_demons",
            name = "Summon Demons",
            description = "Summons demon minions to fight",
            cooldown = 240,
            effect = "summon_minions",
            count = 5,
            minionStats = {power = 100, health = 200},
            duration = 60,
            targetType = "self",
            energyCost = 120,
            level = 45
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 20000,
        items = {"demon_horn", "hell_essence", "dark_crystal", "cursed_skull"},
        soulsCollected = 666
    },
    evolvesTo = "kuromi_demon_lord",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        infernal = {multiplier = 5, colorShift = Color3.fromRGB(255, 0, 0), particleEffect = "hellfire"},
        void = {multiplier = 15, colorShift = Color3.fromRGB(0, 0, 0), particleEffect = "void_smoke"},
        chaos = {multiplier = 30, colorShift = "chaos", particleEffect = "chaos_storm"},
        eternal = {multiplier = 60, colorShift = "eternal", particleEffect = "eternal_flames"},
        apocalypse = {multiplier = 120, colorShift = Color3.fromRGB(150, 0, 0), particleEffect = "doomsday"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["cinnamoroll_celestial"] = CreatePet({
    id = "cinnamoroll_celestial",
    name = "Celestial Cinnamoroll",
    displayName = "Celestial Cinnamoroll",
    tier = "Epic",
    rarity = 4,
    baseValue = 4800,
    baseStats = {
        coins = 1100,
        gems = 22,
        luck = 45,
        speed = 50,
        power = 280,
        health = 420,
        defense = 55,
        critRate = 0.22,
        critDamage = 2.8,
        energy = 160,
        stamina = 150
    },
    description = "Cinnamoroll with celestial cloud powers",
    imageId = "rbxassetid://10000000303",
    modelId = "rbxassetid://10000000304",
    animations = {
        idle = "rbxassetid://10000000305",
        walk = "rbxassetid://10000000306",
        attack = "rbxassetid://10000000307",
        special = "rbxassetid://10000000308",
        fly = "rbxassetid://10000000309",
        cloud_surf = "rbxassetid://10000000310",
        sky_dance = "rbxassetid://10000000311"
    },
    sounds = {
        spawn = "rbxassetid://10000000312",
        attack = "rbxassetid://10000000313",
        special = "rbxassetid://10000000314",
        fly = "rbxassetid://10000000315",
        wind = "rbxassetid://10000000316"
    },
    abilities = {
        {
            id = "cloud_nine",
            name = "Cloud Nine",
            description = "Creates healing clouds that restore HP over time",
            cooldown = 60,
            effect = "healing_field",
            value = 100,
            duration = 20,
            radius = 35,
            targetType = "area",
            energyCost = 50,
            level = 1
        },
        {
            id = "sky_high",
            name = "Sky High",
            description = "Grants flight to all pets for 30 seconds",
            cooldown = 180,
            effect = "team_flight",
            value = 1,
            duration = 30,
            targetType = "team",
            energyCost = 70,
            level = 10
        },
        {
            id = "celestial_storm",
            name = "Celestial Storm",
            description = "Summons a storm that strikes random enemies",
            cooldown = 120,
            effect = "lightning_storm",
            value = 300,
            strikes = 10,
            targetType = "random_enemies",
            energyCost = 80,
            level = 18
        },
        {
            id = "fluffy_clouds",
            name = "Fluffy Clouds",
            description = "30% chance to negate any attack",
            passive = true,
            effect = "dodge_chance",
            value = 0.3,
            level = 25
        },
        {
            id = "rainbow_bridge",
            name = "Rainbow Bridge",
            description = "Teleports team to safety when below 20% HP",
            passive = true,
            effect = "emergency_teleport",
            value = 0.2,
            cooldown = 300,
            level = 32
        },
        {
            id = "heavenly_cafe",
            name = "Heavenly Cafe",
            description = "Creates a cafe that buffs all allies",
            cooldown = 240,
            effect = "buff_zone",
            statsBoost = 0.5,
            duration = 60,
            radius = 50,
            targetType = "location",
            energyCost = 100,
            level = 42
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 18000,
        items = {"cloud_essence", "celestial_wings", "rainbow_crystal", "sky_orb"},
        cloudsRidden = 500
    },
    evolvesTo = "cinnamoroll_archangel",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "cloud_sparkle"},
        aurora = {multiplier = 12, colorShift = "aurora", particleEffect = "aurora_trail"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_clouds"},
        stellar = {multiplier = 50, colorShift = "stellar", particleEffect = "star_shower"},
        nebula = {multiplier = 100, colorShift = "nebula", particleEffect = "nebula_swirl"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["my_melody_angel"] = CreatePet({
    id = "my_melody_angel",
    name = "Angel My Melody",
    displayName = "Angel My Melody",
    tier = "Epic",
    rarity = 4,
    baseValue = 4600,
    baseStats = {
        coins = 1150,
        gems = 21,
        luck = 42,
        speed = 38,
        power = 290,
        health = 480,
        defense = 58,
        critRate = 0.18,
        critDamage = 2.6,
        energy = 155,
        stamina = 145
    },
    description = "My Melody blessed with angelic powers",
    imageId = "rbxassetid://10000000317",
    modelId = "rbxassetid://10000000318",
    animations = {
        idle = "rbxassetid://10000000319",
        walk = "rbxassetid://10000000320",
        attack = "rbxassetid://10000000321",
        special = "rbxassetid://10000000322",
        fly = "rbxassetid://10000000323",
        heal = "rbxassetid://10000000324",
        sing = "rbxassetid://10000000325"
    },
    sounds = {
        spawn = "rbxassetid://10000000326",
        attack = "rbxassetid://10000000327",
        special = "rbxassetid://10000000328",
        heal = "rbxassetid://10000000329",
        angelic_voice = "rbxassetid://10000000330"
    },
    abilities = {
        {
            id = "melody_of_life",
            name = "Melody of Life",
            description = "Fully heals all allies and removes debuffs",
            cooldown = 240,
            effect = "full_heal_cleanse",
            value = 1,
            targetType = "all_allies",
            energyCost = 90,
            level = 1
        },
        {
            id = "angelic_voice",
            name = "Angelic Voice",
            description = "Charms enemies, making them fight for you",
            cooldown = 180,
            effect = "charm_enemies",
            value = 3,
            duration = 15,
            targetType = "enemies",
            energyCost = 70,
            level = 14
        },
        {
            id = "pink_paradise",
            name = "Pink Paradise",
            description = "Creates a safe zone where allies can't die",
            cooldown = 600,
            effect = "immortality_zone",
            radius = 50,
            duration = 10,
            targetType = "area",
            energyCost = 120,
            level = 22
        },
        {
            id = "love_aura",
            name = "Love Aura",
            description = "Converts 30% of damage to healing",
            passive = true,
            effect = "damage_to_heal",
            value = 0.3,
            level = 28
        },
        {
            id = "guardian_angel",
            name = "Guardian Angel",
            description = "Automatically revives once per battle",
            passive = true,
            effect = "auto_revive",
            value = 1,
            cooldown = 999999,
            level = 36
        },
        {
            id = "symphony_of_hope",
            name = "Symphony of Hope",
            description = "Plays a song that gradually heals and buffs team",
            cooldown = 300,
            effect = "healing_song",
            healPerSecond = 50,
            buffPerSecond = 0.02,
            duration = 30,
            targetType = "all_allies",
            energyCost = 100,
            level = 44
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 16000,
        items = {"angel_wings", "melody_harp", "pink_halo", "love_essence"},
        healingDone = 100000
    },
    evolvesTo = "my_melody_seraph",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 200, 220), particleEffect = "heart_sparkle"},
        crystal = {multiplier = 10, colorShift = Color3.fromRGB(255, 200, 255), particleEffect = "crystal_hearts"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_notes"},
        cosmic = {multiplier = 50, colorShift = "cosmic", particleEffect = "cosmic_melody"},
        divine = {multiplier = 100, colorShift = Color3.fromRGB(255, 220, 240), particleEffect = "divine_song"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["pompompurin_chef"] = CreatePet({
    id = "pompompurin_chef",
    name = "Chef Pompompurin",
    displayName = "Chef Pompompurin",
    tier = "Epic",
    rarity = 4,
    baseValue = 4400,
    baseStats = {
        coins = 1050,
        gems = 19,
        luck = 38,
        speed = 22,
        power = 320,
        health = 550,
        defense = 65,
        critRate = 0.15,
        critDamage = 3.0,
        energy = 130,
        stamina = 160
    },
    description = "Master chef Pompompurin with magical cooking skills",
    imageId = "rbxassetid://10000000331",
    modelId = "rbxassetid://10000000332",
    animations = {
        idle = "rbxassetid://10000000333",
        walk = "rbxassetid://10000000334",
        attack = "rbxassetid://10000000335",
        special = "rbxassetid://10000000336",
        cook = "rbxassetid://10000000337",
        serve = "rbxassetid://10000000338",
        taste = "rbxassetid://10000000339"
    },
    sounds = {
        spawn = "rbxassetid://10000000340",
        attack = "rbxassetid://10000000341",
        special = "rbxassetid://10000000342",
        cooking = "rbxassetid://10000000343",
        bell = "rbxassetid://10000000344"
    },
    abilities = {
        {
            id = "master_chef",
            name = "Master Chef",
            description = "Creates magical food that grants random buffs",
            cooldown = 80,
            effect = "create_food",
            foodTypes = {"attack_boost", "defense_boost", "speed_boost", "heal", "energy"},
            foodCount = 5,
            duration = 40,
            targetType = "area",
            energyCost = 60,
            level = 1
        },
        {
            id = "pudding_mastery",
            name = "Pudding Mastery",
            description = "Pudding heals 100% more",
            passive = true,
            effect = "pudding_boost",
            value = 1,
            level = 10
        },
        {
            id = "kitchen_fury",
            name = "Kitchen Fury",
            description = "Throws kitchen utensils at enemies",
            cooldown = 45,
            effect = "projectile_barrage",
            value = 100,
            projectileCount = 10,
            targetType = "spread",
            energyCost = 40,
            level = 18
        },
        {
            id = "five_star_meal",
            name = "Five Star Meal",
            description = "Creates ultimate meal that fully restores team",
            cooldown = 300,
            effect = "ultimate_meal",
            healValue = 1,
            buffValue = 0.5,
            duration = 60,
            targetType = "all_allies",
            energyCost = 100,
            level = 28
        },
        {
            id = "golden_spoon",
            name = "Golden Spoon",
            description = "Attacks have 20% chance to drop food",
            passive = true,
            effect = "food_drop",
            value = 0.2,
            level = 35
        },
        {
            id = "restaurant_empire",
            name = "Restaurant Empire",
            description = "Opens restaurant that generates coins over time",
            cooldown = 600,
            effect = "coin_generator",
            coinsPerSecond = 100,
            duration = 300,
            targetType = "location",
            energyCost = 120,
            level = 45
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 17000,
        items = {"chef_hat", "golden_spoon", "recipe_book", "five_star_badge"},
        mealsCooked = 1000
    },
    evolvesTo = "pompompurin_gourmet",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "steam"},
        golden = {multiplier = 10, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_steam"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_aroma"},
        masterchef = {multiplier = 50, colorShift = Color3.fromRGB(255, 255, 255), particleEffect = "michelin_stars"},
        legendary = {multiplier = 100, colorShift = Color3.fromRGB(255, 200, 0), particleEffect = "legendary_feast"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

-- Continue in Part 3...-- TIER 5: LEGENDARY PETS (0.9% drop rate)
PetDatabase["hello_kitty_goddess"] = CreatePet({
    id = "hello_kitty_goddess",
    name = "Goddess Hello Kitty",
    displayName = "Goddess Hello Kitty",
    tier = "Legendary",
    rarity = 5,
    baseValue = 50000,
    baseStats = {
        coins = 5000,
        gems = 50,
        luck = 80,
        speed = 60,
        power = 1000,
        health = 2000,
        defense = 200,
        critRate = 0.40,
        critDamage = 5.0,
        energy = 300,
        stamina = 300
    },
    description = "The divine goddess form of Hello Kitty",
    imageId = "rbxassetid://10000000345",
    modelId = "rbxassetid://10000000346",
    animations = {
        idle = "rbxassetid://10000000347",
        walk = "rbxassetid://10000000348",
        attack = "rbxassetid://10000000349",
        special = "rbxassetid://10000000350",
        ascend = "rbxassetid://10000000351",
        divine_wrath = "rbxassetid://10000000352",
        creation = "rbxassetid://10000000353"
    },
    sounds = {
        spawn = "rbxassetid://10000000354",
        attack = "rbxassetid://10000000355",
        special = "rbxassetid://10000000356",
        divine = "rbxassetid://10000000357",
        universe = "rbxassetid://10000000358"
    },
    abilities = {
        {
            id = "divine_creation",
            name = "Divine Creation",
            description = "Creates a blessed zone that triples all rewards",
            cooldown = 600,
            effect = "blessed_zone",
            value = 3,
            duration = 120,
            radius = 100,
            targetType = "area",
            energyCost = 150,
            level = 1
        },
        {
            id = "goddess_wrath",
            name = "Goddess's Wrath",
            description = "Instantly defeats all enemies below 50% health",
            cooldown = 480,
            effect = "execute_all",
            value = 0.5,
            targetType = "all_enemies",
            energyCost = 120,
            level = 10
        },
        {
            id = "eternal_life",
            name = "Eternal Life",
            description = "Grants immortality to all pets for 20 seconds",
            cooldown = 900,
            effect = "team_immortal",
            value = 1,
            duration = 20,
            targetType = "team",
            energyCost = 200,
            level = 20
        },
        {
            id = "divine_presence",
            name = "Divine Presence",
            description = "All pets gain 100% stats and cannot be debuffed",
            passive = true,
            effect = "divine_aura",
            value = 1,
            level = 25
        },
        {
            id = "miracle",
            name = "Miracle",
            description = "Fully heals and removes all debuffs from team",
            cooldown = 300,
            effect = "miracle",
            value = 1,
            targetType = "team",
            energyCost = 100,
            level = 30
        },
        {
            id = "heavens_gate",
            name = "Heaven's Gate",
            description = "Opens portal that doubles all rewards for 5 minutes",
            cooldown = 1800,
            effect = "heaven_portal",
            value = 2,
            duration = 300,
            targetType = "global",
            energyCost = 250,
            level = 40
        },
        {
            id = "universal_love",
            name = "Universal Love",
            description = "Converts all enemies to allies",
            cooldown = 3600,
            effect = "convert_all",
            value = 1,
            targetType = "all_enemies",
            energyCost = 300,
            level = 50
        }
    },
    evolutionRequirements = nil, -- Max evolution
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = "divine_glow"},
        shiny = {multiplier = 5, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "holy_light"},
        diamond = {multiplier = 20, colorShift = Color3.fromRGB(200, 255, 255), particleEffect = "diamond_shine"},
        rainbow = {multiplier = 50, colorShift = "rainbow", particleEffect = "rainbow_goddess"},
        cosmic = {multiplier = 100, colorShift = "cosmic", particleEffect = "cosmic_deity"},
        omnipotent = {multiplier = 500, colorShift = "omnipotent", particleEffect = "reality_warp"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

PetDatabase["kuromi_demon_lord"] = CreatePet({
    id = "kuromi_demon_lord",
    name = "Demon Lord Kuromi",
    displayName = "Demon Lord Kuromi",
    tier = "Legendary",
    rarity = 5,
    baseValue = 45000,
    baseStats = {
        coins = 4500,
        gems = 45,
        luck = 75,
        speed = 70,
        power = 1200,
        health = 1800,
        defense = 180,
        critRate = 0.45,
        critDamage = 6.0,
        energy = 280,
        stamina = 280
    },
    description = "Ultimate demon lord form of Kuromi",
    imageId = "rbxassetid://10000000359",
    modelId = "rbxassetid://10000000360",
    animations = {
        idle = "rbxassetid://10000000361",
        walk = "rbxassetid://10000000362",
        attack = "rbxassetid://10000000363",
        special = "rbxassetid://10000000364",
        demon_form = "rbxassetid://10000000365",
        apocalypse = "rbxassetid://10000000366",
        throne = "rbxassetid://10000000367"
    },
    sounds = {
        spawn = "rbxassetid://10000000368",
        attack = "rbxassetid://10000000369",
        special = "rbxassetid://10000000370",
        apocalypse = "rbxassetid://10000000371",
        demon_roar = "rbxassetid://10000000372"
    },
    abilities = {
        {
            id = "hells_dominion",
            name = "Hell's Dominion",
            description = "Controls all enemies for 30 seconds",
            cooldown = 600,
            effect = "mind_control",
            value = 1,
            duration = 30,
            targetType = "all_enemies",
            energyCost = 180,
            level = 1
        },
        {
            id = "apocalypse",
            name = "Apocalypse",
            description = "Unleashes devastating attack on all enemies",
            cooldown = 900,
            effect = "apocalypse",
            damage = 5000,
            targetType = "all_enemies",
            energyCost = 250,
            level = 12
        },
        {
            id = "soul_harvest",
            name = "Soul Harvest",
            description = "Instantly defeats enemies and steals their power",
            cooldown = 480,
            effect = "soul_harvest",
            value = 1,
            targetType = "all_enemies",
            energyCost = 200,
            level = 20
        },
        {
            id = "infernal_rage",
            name = "Infernal Rage",
            description = "Each kill permanently increases power by 5%",
            passive = true,
            effect = "kill_stack",
            value = 0.05,
            level = 25
        },
        {
            id = "dark_resurrection",
            name = "Dark Resurrection",
            description = "Revives with 200% stats when defeated",
            passive = true,
            effect = "phoenix",
            value = 2,
            cooldown = 1800,
            level = 32
        },
        {
            id = "demon_kings_throne",
            name = "Demon King's Throne",
            description = "Creates throne that generates massive rewards",
            cooldown = 1200,
            effect = "demon_throne",
            value = 10,
            duration = 180,
            targetType = "location",
            energyCost = 300,
            level = 40
        },
        {
            id = "eternal_darkness",
            name = "Eternal Darkness",
            description = "Plunges world into darkness, weakening all enemies",
            cooldown = 2400,
            effect = "darkness_world",
            enemyDebuff = 0.5,
            allyBuff = 0.5,
            duration = 300,
            targetType = "global",
            energyCost = 400,
            level = 50
        }
    },
    evolutionRequirements = nil, -- Max evolution
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = "demon_aura"},
        infernal = {multiplier = 5, colorShift = Color3.fromRGB(255, 0, 0), particleEffect = "hellfire_crown"},
        void = {multiplier = 20, colorShift = Color3.fromRGB(0, 0, 0), particleEffect = "void_lord"},
        chaos = {multiplier = 50, colorShift = "chaos", particleEffect = "chaos_realm"},
        eternal = {multiplier = 100, colorShift = "eternal", particleEffect = "eternal_torment"},
        omega = {multiplier = 500, colorShift = "omega", particleEffect = "end_times"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

-- TIER 6: MYTHICAL PETS (0.1% drop rate)
PetDatabase["sanrio_universe_guardian"] = CreatePet({
    id = "sanrio_universe_guardian",
    name = "Universe Guardian",
    displayName = "Sanrio Universe Guardian",
    tier = "Mythical",
    rarity = 6,
    baseValue = 500000,
    baseStats = {
        coins = 50000,
        gems = 500,
        luck = 200,
        speed = 100,
        power = 10000,
        health = 20000,
        defense = 1000,
        critRate = 0.80,
        critDamage = 10.0,
        energy = 1000,
        stamina = 1000
    },
    description = "The ultimate protector of the Sanrio Universe",
    imageId = "rbxassetid://10000000373",
    modelId = "rbxassetid://10000000374",
    animations = {
        idle = "rbxassetid://10000000375",
        walk = "rbxassetid://10000000376",
        attack = "rbxassetid://10000000377",
        special = "rbxassetid://10000000378",
        universe = "rbxassetid://10000000379",
        creation = "rbxassetid://10000000380",
        big_bang = "rbxassetid://10000000381"
    },
    sounds = {
        spawn = "rbxassetid://10000000382",
        attack = "rbxassetid://10000000383",
        special = "rbxassetid://10000000384",
        universe = "rbxassetid://10000000385",
        cosmic = "rbxassetid://10000000386"
    },
    abilities = {
        {
            id = "universe_creation",
            name = "Universe Creation",
            description = "Creates a new dimension with 100x rewards",
            cooldown = 3600,
            effect = "dimension_create",
            value = 100,
            duration = 300,
            targetType = "global",
            energyCost = 500,
            level = 1
        },
        {
            id = "time_manipulation",
            name = "Time Manipulation",
            description = "Rewinds time to undo all damage taken",
            cooldown = 1800,
            effect = "time_rewind",
            value = 1,
            targetType = "global",
            energyCost = 300,
            level = 10
        },
        {
            id = "reality_warp",
            name = "Reality Warp",
            description = "Changes the rules of reality temporarily",
            cooldown = 2400,
            effect = "reality_warp",
            value = 1,
            targetType = "global",
            energyCost = 400,
            level = 20
        },
        {
            id = "infinite_power",
            name = "Infinite Power",
            description = "All stats scale infinitely with time",
            passive = true,
            effect = "infinite_scaling",
            value = 0.01,
            level = 25
        },
        {
            id = "guardians_protection",
            name = "Guardian's Protection",
            description = "All pets become invincible",
            passive = true,
            effect = "team_invincible",
            value = 1,
            level = 30
        },
        {
            id = "universal_love",
            name = "Universal Love",
            description = "Converts all enemies to allies permanently",
            cooldown = 7200,
            effect = "convert_all",
            value = 1,
            targetType = "all_enemies",
            energyCost = 600,
            level = 40
        },
        {
            id = "big_bang",
            name = "Big Bang",
            description = "Resets universe and multiplies all resources by 1000",
            cooldown = 86400, -- Once per day
            effect = "big_bang",
            value = 1000,
            targetType = "universe",
            energyCost = 1000,
            level = 50
        },
        {
            id = "omnipresence",
            name = "Omnipresence",
            description = "Exists in all locations simultaneously",
            passive = true,
            effect = "omnipresent",
            value = 1,
            level = 60
        }
    },
    evolutionRequirements = nil,
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = "universe", particleEffect = "universe_energy"},
        quantum = {multiplier = 10, colorShift = "quantum", particleEffect = "quantum_field"},
        infinity = {multiplier = 100, colorShift = "infinity", particleEffect = "infinite_loop"},
        omnipotent = {multiplier = 1000, colorShift = "omnipotent", particleEffect = "god_rays"},
        absolute = {multiplier = 10000, colorShift = "absolute", particleEffect = "existence_itself"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

-- TIER 7: SECRET PETS (0.01% drop rate)
PetDatabase["sanrio_creator"] = CreatePet({
    id = "sanrio_creator",
    name = "The Creator",
    displayName = "Sanrio Creator",
    tier = "Secret",
    rarity = 7,
    baseValue = 9999999,
    baseStats = {
        coins = 999999,
        gems = 9999,
        luck = 999,
        speed = 999,
        power = 99999,
        health = 99999,
        defense = 9999,
        critRate = 1.0,
        critDamage = 99.9,
        energy = 9999,
        stamina = 9999
    },
    description = "The one who created all Sanrio characters",
    imageId = "rbxassetid://10000000387",
    modelId = "rbxassetid://10000000388",
    animations = {
        idle = "rbxassetid://10000000389",
        walk = "rbxassetid://10000000390",
        attack = "rbxassetid://10000000391",
        special = "rbxassetid://10000000392",
        create = "rbxassetid://10000000393",
        erase = "rbxassetid://10000000394",
        rewrite = "rbxassetid://10000000395"
    },
    sounds = {
        spawn = "rbxassetid://10000000396",
        attack = "rbxassetid://10000000397",
        special = "rbxassetid://10000000398",
        create = "rbxassetid://10000000399",
        omnipotent = "rbxassetid://10000000400"
    },
    abilities = {
        {
            id = "creation",
            name = "Creation",
            description = "Creates any pet at will",
            cooldown = 60,
            effect = "create_pet",
            value = 1,
            targetType = "select",
            energyCost = 0,
            level = 1
        },
        {
            id = "erasure",
            name = "Erasure",
            description = "Erases anything from existence",
            cooldown = 120,
            effect = "erase",
            value = 1,
            targetType = "select",
            energyCost = 0,
            level = 1
        },
        {
            id = "rewrite_reality",
            name = "Rewrite Reality",
            description = "Rewrites the laws of the game",
            cooldown = 3600,
            effect = "rewrite",
            value = 1,
            targetType = "universe",
            energyCost = 0,
            level = 1
        },
        {
            id = "author_authority",
            name = "Author Authority",
            description = "Cannot be affected by any abilities",
            passive = true,
            effect = "absolute_immunity",
            value = 1,
            level = 1
        },
        {
            id = "plot_armor",
            name = "Plot Armor",
            description = "Cannot be defeated",
            passive = true,
            effect = "immortal",
            value = 1,
            level = 1
        },
        {
            id = "deus_ex_machina",
            name = "Deus Ex Machina",
            description = "Solves any problem instantly",
            cooldown = 86400,
            effect = "instant_win",
            value = 1,
            targetType = "situation",
            energyCost = 0,
            level = 1
        },
        {
            id = "the_end",
            name = "The End",
            description = "Ends the current game session with maximum rewards",
            cooldown = 604800, -- Once per week
            effect = "game_end",
            value = 999999,
            targetType = "game",
            energyCost = 0,
            level = 1
        },
        {
            id = "new_beginning",
            name = "New Beginning",
            description = "Starts a new game+ with all progress carried over",
            cooldown = 2592000, -- Once per month
            effect = "new_game_plus",
            value = 1,
            targetType = "game",
            energyCost = 0,
            level = 1
        },
        {
            id = "fourth_wall_break",
            name = "Fourth Wall Break",
            description = "Speaks directly to the player",
            passive = true,
            effect = "fourth_wall",
            value = 1,
            level = 1
        }
    },
    evolutionRequirements = nil,
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = "creator", particleEffect = "reality_pencil"},
        true_form = {multiplier = 999999, colorShift = "true_form", particleEffect = "existence_author"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

-- ========================================
-- EGG/CASE SYSTEM
-- ========================================
local EggCases = {
    ["basic"] = {
        id = "basic",
        name = "Basic Egg",
        description = "Common characters with good drop rates",
        price = 100,
        currency = "Coins",
        imageId = "rbxassetid://10000001001",
        modelId = "rbxassetid://10000001002",
        openAnimation = "crack",
        openTime = 3,
        particles = {"basic_sparkles"},
        pets = {
            "hello_kitty_classic",
            "my_melody_classic",
            "keroppi_classic",
            "pochacco_classic",
            "tuxedosam_classic",
            "badtz_maru_classic",
            "hangyodon_classic",
            "pekkle_classic",
            "ahiru_no_pekkle_classic"
        },
        dropRates = {
            ["hello_kitty_classic"] = 15,
            ["my_melody_classic"] = 15,
            ["keroppi_classic"] = 12,
            ["pochacco_classic"] = 12,
            ["tuxedosam_classic"] = 12,
            ["badtz_maru_classic"] = 12,
            ["hangyodon_classic"] = 10,
            ["pekkle_classic"] = 8,
            ["ahiru_no_pekkle_classic"] = 4
        },
        guaranteedRarity = nil,
        pitySystem = {
            enabled = false
        }
    },
    
    ["premium"] = {
        id = "premium",
        name = "Premium Egg",
        description = "Rare characters with better rewards",
        price = 250,
        currency = "Gems",
        imageId = "rbxassetid://10000001003",
        modelId = "rbxassetid://10000001004",
        openAnimation = "golden_crack",
        openTime = 5,
        particles = {"golden_sparkles", "star_burst"},
        pets = {
            "kuromi_classic",
            "cinnamoroll_classic",
            "pompompurin_classic",
            "chococat_classic",
            "monkichi_classic",
            "rururugakuen_classic",
            "u_sa_ha_na_classic",
            "hello_kitty_classic",
            "my_melody_classic"
        },
        dropRates = {
            ["kuromi_classic"] = 20,
            ["cinnamoroll_classic"] = 20,
            ["pompompurin_classic"] = 18,
            ["chococat_classic"] = 15,
            ["monkichi_classic"] = 12,
            ["rururugakuen_classic"] = 8,
            ["u_sa_ha_na_classic"] = 5,
            ["hello_kitty_classic"] = 1,
            ["my_melody_classic"] = 1
        },
        guaranteedRarity = 1,
        pitySystem = {
            enabled = true,
            threshold = 10,
            guaranteedRarity = 2
        }
    },
    
    ["rare"] = {
        id = "rare",
        name = "Rare Egg",
        description = "Rare and epic pets await",
        price = 500,
        currency = "Gems",
        imageId = "rbxassetid://10000001005",
        modelId = "rbxassetid://10000001006",
        openAnimation = "magical_crack",
        openTime = 7,
        particles = {"magic_sparkles", "rare_burst", "star_shower"},
        pets = {
            "gudetama_classic",
            "aggretsuko_classic",
            "kiki_and_lala_classic",
            "dear_daniel_classic",
            "mimmy_classic",
            "kuromi_classic",
            "cinnamoroll_classic"
        },
        dropRates = {
            ["gudetama_classic"] = 25,
            ["aggretsuko_classic"] = 25,
            ["kiki_and_lala_classic"] = 20,
            ["dear_daniel_classic"] = 15,
            ["mimmy_classic"] = 10,
            ["kuromi_classic"] = 3,
            ["cinnamoroll_classic"] = 2
        },
        guaranteedRarity = 2,
        pitySystem = {
            enabled = true,
            threshold = 8,
            guaranteedRarity = 3
        }
    },
    
    ["epic"] = {
        id = "epic",
        name = "Epic Egg",
        description = "Epic pets with amazing powers",
        price = 1000,
        currency = "Gems",
        imageId = "rbxassetid://10000001007",
        modelId = "rbxassetid://10000001008",
        openAnimation = "epic_explosion",
        openTime = 10,
        particles = {"epic_burst", "purple_flames", "magic_circle"},
        pets = {
            "hello_kitty_angel",
            "kuromi_demon",
            "cinnamoroll_celestial",
            "my_melody_angel",
            "pompompurin_chef",
            "gudetama_classic",
            "aggretsuko_classic"
        },
        dropRates = {
            ["hello_kitty_angel"] = 18,
            ["kuromi_demon"] = 18,
            ["cinnamoroll_celestial"] = 18,
            ["my_melody_angel"] = 18,
            ["pompompurin_chef"] = 18,
            ["gudetama_classic"] = 7,
            ["aggretsuko_classic"] = 3
        },
        guaranteedRarity = 3,
        pitySystem = {
            enabled = true,
            threshold = 5,
            guaranteedRarity = 4
        }
    },
    
    ["legendary"] = {
        id = "legendary",
        name = "Legendary Egg",
        description = "Ultra-rare characters with amazing bonuses",
        price = 2500,
        currency = "Gems",
        imageId = "rbxassetid://10000001009",
        modelId = "rbxassetid://10000001010",
        openAnimation = "legendary_explosion",
        openTime = 15,
        particles = {"legendary_explosion", "rainbow_burst", "golden_shower", "divine_light"},
        pets = {
            "hello_kitty_goddess",
            "kuromi_demon_lord",
            "hello_kitty_angel",
            "kuromi_demon",
            "cinnamoroll_celestial"
        },
        dropRates = {
            ["hello_kitty_goddess"] = 15,
            ["kuromi_demon_lord"] = 15,
            ["hello_kitty_angel"] = 30,
            ["kuromi_demon"] = 25,
            ["cinnamoroll_celestial"] = 15
        },
        guaranteedRarity = 4,
        pitySystem = {
            enabled = true,
            threshold = 3,
            guaranteedRarity = 5
        }
    },
    
    ["mythical"] = {
        id = "mythical",
        name = "Mythical Egg",
        description = "The rarest pets in existence",
        price = 10000,
        currency = "Gems",
        imageId = "rbxassetid://10000001011",
        modelId = "rbxassetid://10000001012",
        openAnimation = "mythical_transformation",
        openTime = 20,
        particles = {"void_particles", "cosmic_burst", "reality_shatter", "universe_birth"},
        pets = {
            "sanrio_universe_guardian",
            "hello_kitty_goddess",
            "kuromi_demon_lord"
        },
        dropRates = {
            ["sanrio_universe_guardian"] = 10,
            ["hello_kitty_goddess"] = 45,
            ["kuromi_demon_lord"] = 45
        },
        guaranteedRarity = 5,
        pitySystem = {
            enabled = true,
            threshold = 2,
            guaranteedRarity = 6
        }
    },
    
    ["secret"] = {
        id = "secret",
        name = "??? Egg",
        description = "???",
        price = 999999,
        currency = "Gems",
        imageId = "rbxassetid://10000001013",
        modelId = "rbxassetid://10000001014",
        openAnimation = "secret_reveal",
        openTime = 30,
        particles = {"glitch_particles", "void_tear", "reality_break", "fourth_wall_shatter"},
        pets = {
            "sanrio_creator"
        },
        dropRates = {
            ["sanrio_creator"] = 100
        },
        guaranteedRarity = 7,
        hidden = true,
        requirements = {
            minLevel = 999,
            mustOwn = {"sanrio_universe_guardian"},
            specialCode = true
        }
    },
    
    -- Special Event Eggs
    ["valentine"] = {
        id = "valentine",
        name = "Valentine's Special Egg",
        description = "Limited Valentine's Day exclusive pets",
        price = 5000,
        currency = "Gems",
        imageId = "rbxassetid://10000001015",
        modelId = "rbxassetid://10000001016",
        openAnimation = "heart_explosion",
        openTime = 8,
        particles = {"heart_particles", "pink_sparkles", "love_burst", "cupid_arrows"},
        limitedTime = true,
        availableFrom = "2024-02-01",
        availableUntil = "2024-02-28",
        pets = {
            "hello_kitty_valentine",
            "my_melody_cupid",
            "kuromi_heartbreaker",
            "cinnamoroll_love"
        },
        dropRates = {
            ["hello_kitty_valentine"] = 30,
            ["my_melody_cupid"] = 30,
            ["kuromi_heartbreaker"] = 25,
            ["cinnamoroll_love"] = 15
        },
        guaranteedRarity = 4,
        pitySystem = {
            enabled = true,
            threshold = 5,
            guaranteedRarity = 5
        }
    }
}

-- ========================================
-- GAMEPASS DEFINITIONS
-- ========================================
local GamepassData = {
    [123456] = {
        id = 123456,
        name = "2x Cash Multiplier",
        description = "Double all cash earned from your tycoon!",
        price = 199,
        currency = "Robux",
        icon = "rbxassetid://10000002001",
        benefits = {
            {type = "cash_multiplier", value = 2},
            {type = "vip_badge", value = true}
        },
        permanent = true,
        category = "Multipliers"
    },
    
    [123457] = {
        id = 123457,
        name = "Auto Cash Claimer",
        description = "Automatically collect cash from your tycoon!",
        price = 299,
        currency = "Robux",
        icon = "rbxassetid://10000002002",
        benefits = {
            {type = "auto_collect", value = true},
            {type = "collection_range", value = 100}
        },
        permanent = true,
        category = "Automation"
    },
    
    [123458] = {
        id = 123458,
        name = "VIP Status",
        description = "Exclusive VIP perks and special access!",
        price = 999,
        currency = "Robux",
        icon = "rbxassetid://10000002003",
        benefits = {
            {type = "vip_access", value = true},
            {type = "gem_multiplier", value = 2},
            {type = "coin_multiplier", value = 2},
            {type = "exclusive_area", value = "vip_lounge"},
            {type = "chat_tag", value = "[VIP]"},
            {type = "trade_slots", value = 10},
            {type = "pet_slots", value = 100}
        },
        permanent = true,
        category = "VIP"
    },
    
    [123459] = {
        id = 123459,
        name = "Pet Storage +100",
        description = "Increase your pet inventory by 100 slots!",
        price = 149,
        currency = "Robux",
        icon = "rbxassetid://10000002004",
        benefits = {
            {type = "storage_increase", value = 100}
        },
        permanent = true,
        stackable = true,
        maxStack = 10,
        category = "Storage"
    },
    
    [123460] = {
        id = 123460,
        name = "Lucky Boost",
        description = "Increase rare pet drop rates by 25%!",
        price = 399,
        currency = "Robux",
        icon = "rbxassetid://10000002005",
        benefits = {
            {type = "luck_multiplier", value = 1.25},
            {type = "shiny_chance", value = 1.5},
            {type = "variant_luck", value = 2}
        },
        permanent = true,
        category = "Luck"
    },
    
    [123461] = {
        id = 123461,
        name = "Speed Coil",
        description = "Move 50% faster in your tycoon!",
        price = 99,
        currency = "Robux",
        icon = "rbxassetid://10000002006",
        benefits = {
            {type = "speed_boost", value = 1.5}
        },
        permanent = true,
        category = "Movement"
    },
    
    [123462] = {
        id = 123462,
        name = "Triple Hatch",
        description = "Open 3 eggs at once!",
        price = 599,
        currency = "Robux",
        icon = "rbxassetid://10000002007",
        benefits = {
            {type = "multi_hatch", value = 3}
        },
        permanent = true,
        category = "Hatching"
    }
}

-- ========================================
-- PLAYER DATA MANAGEMENT SYSTEM
-- ========================================
local function GetDefaultPlayerData()
    return {
        -- Basic Info
        userId = 0,
        username = "",
        displayName = "",
        joinDate = os.time(),
        lastSeen = os.time(),
        totalPlayTime = 0,
        
        -- Currencies
        currencies = {
            coins = CONFIG.STARTING_COINS,
            gems = CONFIG.STARTING_GEMS,
            tickets = CONFIG.STARTING_TICKETS,
            candies = 0,
            stars = 0,
            tokens = 0,
            rebirth_tokens = 0
        },
        
        -- Pet Inventory
        pets = {},
        maxPetStorage = CONFIG.MAX_INVENTORY_SIZE,
        equippedPets = {},
        
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
            highestPetRarity = 0,
            totalPetsSold = 0,
            totalPetsEvolved = 0,
            totalPetsFused = 0,
            
            eggStatistics = {},
            
            tradingStats = {
                tradesCompleted = 0,
                tradesDeclined = 0,
                totalTradeValue = 0,
                scamReports = 0,
                tradePartners = {}
            },
            
            battleStats = {
                wins = 0,
                losses = 0,
                draws = 0,
                damageDealt = 0,
                damageTaken = 0,
                petsDefeated = 0,
                winStreak = 0,
                highestWinStreak = 0
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
            food = {},
            special = {}
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
            cameraShake = true,
            notifications = true
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
            multiplier = 1,
            history = {}
        },
        
        -- Battle Pass
        battlePass = {
            season = 1,
            level = 1,
            experience = 0,
            premiumOwned = false,
            claimedRewards = {},
            questsCompleted = {}
        },
        
        -- Clan/Guild
        clan = {
            id = nil,
            name = nil,
            role = nil,
            contribution = 0,
            joinDate = nil,
            permissions = {}
        },
        
        -- Friends System
        friends = {
            list = {},
            requests = {},
            blocked = {},
            favorites = {}
        },
        
        -- Trading
        trading = {
            history = {},
            favorites = {},
            wishlist = {},
            blacklist = {},
            reputation = 0
        },
        
        -- Quests
        quests = {
            daily = {},
            weekly = {},
            special = {},
            completed = {},
            progress = {}
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
            reports = 0,
            reputation = 100
        },
        
        -- Rebirth System
        rebirth = {
            level = 0,
            totalRebirths = 0,
            bonusMultiplier = 1,
            perks = {}
        },
        
        -- Pet Collection
        petCollection = {},
        
        -- Limited Time
        limitedTimeRewards = {},
        eventProgress = {}
    }
end

local function LoadPlayerData(player)
    local success, data = pcall(function()
        return DataStores.PlayerData:GetAsync(player.UserId)
    end)
    
    if success and data then
        PlayerData[player.UserId] = data
        
        -- Update data structure for any new fields
        local defaultData = GetDefaultPlayerData()
        for key, value in pairs(defaultData) do
            if PlayerData[player.UserId][key] == nil then
                PlayerData[player.UserId][key] = value
            end
        end
        
        -- Deep merge for nested tables
        for key, value in pairs(defaultData) do
            if type(value) == "table" and type(PlayerData[player.UserId][key]) == "table" then
                for subKey, subValue in pairs(value) do
                    if PlayerData[player.UserId][key][subKey] == nil then
                        PlayerData[player.UserId][key][subKey] = subValue
                    end
                end
            end
        end
    else
        PlayerData[player.UserId] = GetDefaultPlayerData()
        PlayerData[player.UserId].userId = player.UserId
        PlayerData[player.UserId].username = player.Name
        PlayerData[player.UserId].displayName = player.DisplayName
    end
    
    -- Load gamepass ownership
    for gamepassId, _ in pairs(GamepassData) do
        spawn(function()
            local hasGamepass = false
            local success, result = pcall(function()
                return Services.MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
            end)
            if success then
                hasGamepass = result
            end
            PlayerData[player.UserId].ownedGamepasses[gamepassId] = hasGamepass
        end)
    end
    
    -- Check group membership
    spawn(function()
        local success, isInGroup = pcall(function()
            return player:IsInGroup(CONFIG.GROUP_ID)
        end)
        if success and isInGroup then
            PlayerData[player.UserId].inGroup = true
            
            -- Get group rank
            local success2, rank = pcall(function()
                return player:GetRankInGroup(CONFIG.GROUP_ID)
            end)
            if success2 then
                PlayerData[player.UserId].groupRank = rank
            end
        end
    end)
    
    -- Track session
    PlayerData[player.UserId].sessionStart = tick()
    
    -- Fire data loaded event
    if RemoteEvents.DataLoaded then
        RemoteEvents.DataLoaded:FireClient(player, PlayerData[player.UserId])
    end
end

local function SavePlayerData(player)
    if PlayerData[player.UserId] then
        -- Update last seen
        PlayerData[player.UserId].lastSeen = os.time()
        
        -- Update play time
        if PlayerData[player.UserId].sessionStart then
            local sessionTime = tick() - PlayerData[player.UserId].sessionStart
            PlayerData[player.UserId].totalPlayTime = PlayerData[player.UserId].totalPlayTime + sessionTime
        end
        
        local success, error = pcall(function()
            DataStores.PlayerData:SetAsync(player.UserId, PlayerData[player.UserId])
        end)
        
        if not success then
            warn("Failed to save data for " .. player.Name .. ": " .. tostring(error))
            
            -- Try backup datastore
            pcall(function()
                DataStores.BackupData:SetAsync(player.UserId .. "_" .. os.time(), PlayerData[player.UserId])
            end)
        end
    end
end

-- ========================================
-- WEIGHTED RANDOM & CASE OPENING SYSTEM
-- ========================================
local function GetWeightedRandomPet(eggType, player)
    local egg = EggCases[eggType]
    if not egg then return nil end
    
    local playerData = PlayerData[player.UserId]
    local luckMultiplier = 1
    
    -- Apply luck multipliers
    if playerData then
        if playerData.ownedGamepasses[123460] then -- Lucky Boost
            luckMultiplier = luckMultiplier * 1.25
        end
        if playerData.inGroup then
            luckMultiplier = luckMultiplier * CONFIG.GROUP_BONUS_MULTIPLIER
        end
        -- Apply pet luck bonuses
        for _, petId in ipairs(playerData.equippedPets or {}) do
            for _, pet in ipairs(playerData.pets) do
                if pet.id == petId then
                    local petData = PetDatabase[pet.petId]
                    if petData and petData.baseStats.luck then
                        luckMultiplier = luckMultiplier * (1 + petData.baseStats.luck / 1000)
                    end
                end
            end
        end
    end
    
    local totalWeight = 0
    for _, weight in pairs(egg.dropRates) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random() * totalWeight / luckMultiplier
    local currentWeight = 0
    
    for petName, weight in pairs(egg.dropRates) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return petName
        end
    end
    
    -- Fallback to first pet
    for petName, _ in pairs(egg.dropRates) do
        return petName
    end
end

local function GenerateCaseItems(eggType, winnerPet)
    local items = {}
    local egg = EggCases[eggType]
    
    -- Generate 100 items for the visual spinner
    for i = 1, 100 do
        if i == 50 then
            -- Place the actual winner at position 50 (center)
            items[i] = winnerPet
        elseif i >= 47 and i <= 53 and i ~= 50 then
            -- Place legendary items near center for psychological effect
            local legendaryPets = {}
            for petName, petData in pairs(PetDatabase) do
                if petData.rarity >= 5 then
                    table.insert(legendaryPets, petData.id)
                end
            end
            if #legendaryPets > 0 then
                items[i] = legendaryPets[math.random(1, #legendaryPets)]
            else
                items[i] = GetWeightedRandomPet(eggType, nil)
            end
        else
            -- Random pets for other positions
            items[i] = GetWeightedRandomPet(eggType, nil)
        end
    end
    
    return items
end

local function OpenCase(player, eggType)
    -- Rate limit check
    local canProceed, errorMsg = RateLimiter:Check(player, "OpenCase")
    if not canProceed then
        return {success = false, error = errorMsg}
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then return {success = false, error = "No player data"} end
    
    local egg = EggCases[eggType]
    if not egg then return {success = false, error = "Invalid egg type"} end
    
    -- Check if egg is available (for limited time eggs)
    if egg.limitedTime then
        local currentDate = os.date("*t")
        local currentDateString = string.format("%04d-%02d-%02d", currentDate.year, currentDate.month, currentDate.day)
        if currentDateString < egg.availableFrom or currentDateString > egg.availableUntil then
            return {success = false, error = "This egg is not available right now"}
        end
    end
    
    -- Check requirements
    if egg.requirements then
        if egg.requirements.minLevel and playerData.rebirth.level < egg.requirements.minLevel then
            return {success = false, error = "You need to be rebirth level " .. egg.requirements.minLevel}
        end
        if egg.requirements.mustOwn then
            for _, requiredPet in ipairs(egg.requirements.mustOwn) do
                local hasPet = false
                for _, pet in ipairs(playerData.pets) do
                    if pet.petId == requiredPet then
                        hasPet = true
                        break
                    end
                end
                if not hasPet then
                    return {success = false, error = "You need to own " .. requiredPet .. " first"}
                end
            end
        end
    end
    
    -- Check currency
    local currencyType = string.lower(egg.currency)
    if not playerData.currencies[currencyType] or playerData.currencies[currencyType] < egg.price then
        return {success = false, error = "Not enough " .. egg.currency}
    end
    
    -- Multi-hatch check
    local hatchCount = 1
    if playerData.ownedGamepasses[123462] then -- Triple Hatch
        hatchCount = 3
    end
    
    -- Deduct currency
    local totalCost = egg.price * hatchCount
    if playerData.currencies[currencyType] < totalCost then
        hatchCount = math.floor(playerData.currencies[currencyType] / egg.price)
        totalCost = egg.price * hatchCount
    end
    
    -- Wealth check
    local wealthCheck, wealthError = RateLimiter:CheckWealth(player, currencyType, totalCost)
    if not wealthCheck then
        return {success = false, error = wealthError}
    end
    
    playerData.currencies[currencyType] = playerData.currencies[currencyType] - totalCost
    
    local results = {}
    
    for h = 1, hatchCount do
        -- Check pity system
        if egg.pitySystem and egg.pitySystem.enabled then
            if not playerData.statistics.eggStatistics[eggType] then
                playerData.statistics.eggStatistics[eggType] = {
                    opened = 0,
                    sinceLastRare = 0
                }
            end
            
            playerData.statistics.eggStatistics[eggType].sinceLastRare = 
                playerData.statistics.eggStatistics[eggType].sinceLastRare + 1
        end
        
        -- Determine winner
        local winnerPet = GetWeightedRandomPet(eggType, player)
        
        -- Apply pity system
        if egg.pitySystem and egg.pitySystem.enabled then
            if playerData.statistics.eggStatistics[eggType].sinceLastRare >= egg.pitySystem.threshold then
                -- Force a rare pet
                local rarePets = {}
                for petId, _ in pairs(egg.dropRates) do
                    local petData = PetDatabase[petId]
                    if petData and petData.rarity >= egg.pitySystem.guaranteedRarity then
                        table.insert(rarePets, petId)
                    end
                end
                if #rarePets > 0 then
                    winnerPet = rarePets[math.random(1, #rarePets)]
                    playerData.statistics.eggStatistics[eggType].sinceLastRare = 0
                end
            end
        end
        
        local petData = PetDatabase[winnerPet]
        if not petData then
            return {success = false, error = "Invalid pet data"}
        end
        
        -- Reset pity counter if rare pet
        if egg.pitySystem and egg.pitySystem.enabled and petData.rarity >= egg.pitySystem.guaranteedRarity then
            playerData.statistics.eggStatistics[eggType].sinceLastRare = 0
        end
        
        -- Generate case items with winner at center
        local caseItems = GenerateCaseItems(eggType, winnerPet)
        
        -- Determine variant
        local variant = "normal"
        local variantRoll = math.random()
        
        -- Apply variant chances
        local shinyChance = CONFIG.SHINY_CHANCE
        local goldenChance = CONFIG.GOLDEN_CHANCE
        local rainbowChance = CONFIG.RAINBOW_CHANCE
        local darkMatterChance = CONFIG.DARK_MATTER_CHANCE
        
        -- Apply multipliers
        if playerData.ownedGamepasses[123460] then -- Lucky Boost
            shinyChance = shinyChance * 1.5
            goldenChance = goldenChance * 1.5
            rainbowChance = rainbowChance * 1.5
            darkMatterChance = darkMatterChance * 1.5
        end
        
        if variantRoll < darkMatterChance then
            variant = "dark_matter"
        elseif variantRoll < rainbowChance then
            variant = "rainbow"
        elseif variantRoll < goldenChance then
            variant = "golden"
        elseif variantRoll < shinyChance then
            variant = "shiny"
        end
        
        -- Special variants for specific pets
        if petData.variants[variant] == nil then
            variant = "normal"
        end
        
        -- Create pet instance
        local petInstance = {
            id = Services.HttpService:GenerateGUID(false),
            petId = petData.id,
            name = petData.name,
            displayName = petData.displayName,
            level = 1,
            experience = 0,
            variant = variant,
            owner = player.UserId,
            obtained = os.time(),
            source = "egg_" .. eggType,
            equipped = false,
            locked = false,
            nickname = nil,
            stats = {}
        }
        
        -- Copy base stats and apply variant multiplier
        for stat, value in pairs(petData.baseStats) do
            petInstance.stats[stat] = value
            if petData.variants[variant] then
                local multiplier = petData.variants[variant].multiplier
                petInstance.stats[stat] = math.floor(value * multiplier)
            end
        end
        
        -- Apply rebirth bonuses
        if playerData.rebirth.level > 0 then
            local rebirthMultiplier = 1 + (playerData.rebirth.level * CONFIG.REBIRTH_BONUS_PER_LEVEL)
            for stat, value in pairs(petInstance.stats) do
                petInstance.stats[stat] = math.floor(value * rebirthMultiplier)
            end
        end
        
        -- Add to inventory
        table.insert(playerData.pets, petInstance)
        
        -- Update pet collection
        if not playerData.petCollection[petData.id] then
            playerData.petCollection[petData.id] = {
                discovered = true,
                firstObtained = os.time(),
                totalObtained = 0,
                variants = {}
            }
        end
        playerData.petCollection[petData.id].totalObtained = 
            playerData.petCollection[petData.id].totalObtained + 1
        playerData.petCollection[petData.id].variants[variant] = true
        
        -- Update statistics
        playerData.statistics.totalEggsOpened = playerData.statistics.totalEggsOpened + 1
        playerData.statistics.totalPetsHatched = playerData.statistics.totalPetsHatched + 1
        
        if egg.currency == "Gems" then
            playerData.statistics.totalGemsSpent = playerData.statistics.totalGemsSpent + egg.price
        end
        
        if petData.rarity >= 5 then
            playerData.statistics.legendaryPetsFound = playerData.statistics.legendaryPetsFound + 1
        end
        if petData.rarity >= 6 then
            playerData.statistics.mythicalPetsFound = playerData.statistics.mythicalPetsFound + 1
        end
        if petData.rarity >= 7 then
            playerData.statistics.secretPetsFound = playerData.statistics.secretPetsFound + 1
        end
        
        if petData.rarity > playerData.statistics.highestPetRarity then
            playerData.statistics.highestPetRarity = petData.rarity
        end
        
        table.insert(results, {
            pet = petInstance,
            petData = petData,
            variant = variant,
            caseItems = caseItems
        })
        
        -- Log analytics
        ServerAnalytics:LogEvent("PetHatched", player, {
            egg = eggType,
            pet = petData.id,
            variant = variant,
            rarity = petData.rarity
        })
    end
    
    -- Save data
    SavePlayerData(player)
    
    -- Fire client event
    if RemoteEvents.CaseOpened then
        RemoteEvents.CaseOpened:FireClient(player, {
            success = true,
            results = results,
            newBalance = playerData.currencies[currencyType]
        })
    end
    
    return {
        success = true,
        results = results,
        newBalance = playerData.currencies[currencyType]
    }
end

-- Continue in Part 4...-- ========================================
-- TRADING SYSTEM
-- ========================================
local TradingSystem = {}

function TradingSystem:CreateTrade(player1, player2)
    local tradeId = Services.HttpService:GenerateGUID(false)
    
    local trade = {
        id = tradeId,
        player1 = {
            userId = player1.UserId,
            player = player1,
            items = {
                pets = {},
                currencies = {coins = 0, gems = 0, tickets = 0},
                items = {}
            },
            ready = false,
            confirmed = false
        },
        player2 = {
            userId = player2.UserId,
            player = player2,
            items = {
                pets = {},
                currencies = {coins = 0, gems = 0, tickets = 0},
                items = {}
            },
            ready = false,
            confirmed = false
        },
        status = "pending",
        createdAt = tick(),
        expiresAt = tick() + CONFIG.TRADE_EXPIRY_TIME
    }
    
    ActiveTrades[tradeId] = trade
    
    -- Notify players
    if RemoteEvents.TradeStarted then
        RemoteEvents.TradeStarted:FireClient(player1, trade)
        RemoteEvents.TradeStarted:FireClient(player2, trade)
    end
    
    return trade
end

function TradingSystem:AddItem(tradeId, player, itemType, itemData)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "pending" then
        return false, "Trade is not active"
    end
    
    local tradePlayer = nil
    if trade.player1.userId == player.UserId then
        tradePlayer = trade.player1
    elseif trade.player2.userId == player.UserId then
        tradePlayer = trade.player2
    else
        return false, "Player not in trade"
    end
    
    -- Reset ready status when items change
    trade.player1.ready = false
    trade.player2.ready = false
    
    if itemType == "pet" then
        if #tradePlayer.items.pets >= CONFIG.MAX_TRADE_ITEMS then
            return false, "Maximum pets reached"
        end
        
        -- Verify pet ownership
        local playerData = PlayerData[player.UserId]
        local ownsPet = false
        for _, pet in ipairs(playerData.pets) do
            if pet.id == itemData.id and not pet.locked then
                ownsPet = true
                break
            end
        end
        
        if not ownsPet then
            return false, "You don't own this pet"
        end
        
        table.insert(tradePlayer.items.pets, itemData)
        
    elseif itemType == "currency" then
        local playerData = PlayerData[player.UserId]
        local currencyType = itemData.type
        local amount = itemData.amount
        
        if amount <= 0 then
            return false, "Invalid amount"
        end
        
        if playerData.currencies[currencyType] < amount then
            return false, "Insufficient " .. currencyType
        end
        
        tradePlayer.items.currencies[currencyType] = amount
        
    elseif itemType == "item" then
        -- Handle inventory items
        -- TODO: Implement inventory item trading
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:RemoveItem(tradeId, player, itemType, itemData)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "pending" then
        return false, "Trade is not active"
    end
    
    local tradePlayer = nil
    if trade.player1.userId == player.UserId then
        tradePlayer = trade.player1
    elseif trade.player2.userId == player.UserId then
        tradePlayer = trade.player2
    else
        return false, "Player not in trade"
    end
    
    -- Reset ready status
    trade.player1.ready = false
    trade.player2.ready = false
    
    if itemType == "pet" then
        for i, pet in ipairs(tradePlayer.items.pets) do
            if pet.id == itemData.id then
                table.remove(tradePlayer.items.pets, i)
                break
            end
        end
    elseif itemType == "currency" then
        tradePlayer.items.currencies[itemData.type] = 0
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:SetReady(tradeId, player, ready)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.player1.userId == player.UserId then
        trade.player1.ready = ready
    elseif trade.player2.userId == player.UserId then
        trade.player2.ready = ready
    else
        return false, "Player not in trade"
    end
    
    -- Check if both ready
    if trade.player1.ready and trade.player2.ready then
        trade.status = "ready"
    else
        trade.status = "pending"
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:ConfirmTrade(tradeId, player)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "ready" then
        return false, "Both players must be ready"
    end
    
    if trade.player1.userId == player.UserId then
        trade.player1.confirmed = true
    elseif trade.player2.userId == player.UserId then
        trade.player2.confirmed = true
    else
        return false, "Player not in trade"
    end
    
    -- Execute trade if both confirmed
    if trade.player1.confirmed and trade.player2.confirmed then
        return self:ExecuteTrade(tradeId)
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:ExecuteTrade(tradeId)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    local player1Data = PlayerData[trade.player1.userId]
    local player2Data = PlayerData[trade.player2.userId]
    
    if not player1Data or not player2Data then
        return false, "Player data not found"
    end
    
    -- Validate all items still exist and are valid
    -- Player 1 validation
    for _, pet in ipairs(trade.player1.items.pets) do
        local found = false
        for _, ownedPet in ipairs(player1Data.pets) do
            if ownedPet.id == pet.id and not ownedPet.locked then
                found = true
                break
            end
        end
        if not found then
            return false, "Player 1 no longer owns pet: " .. pet.name
        end
    end
    
    for currency, amount in pairs(trade.player1.items.currencies) do
        if player1Data.currencies[currency] < amount then
            return false, "Player 1 has insufficient " .. currency
        end
    end
    
    -- Player 2 validation
    for _, pet in ipairs(trade.player2.items.pets) do
        local found = false
        for _, ownedPet in ipairs(player2Data.pets) do
            if ownedPet.id == pet.id and not ownedPet.locked then
                found = true
                break
            end
        end
        if not found then
            return false, "Player 2 no longer owns pet: " .. pet.name
        end
    end
    
    for currency, amount in pairs(trade.player2.items.currencies) do
        if player2Data.currencies[currency] < amount then
            return false, "Player 2 has insufficient " .. currency
        end
    end
    
    -- Calculate trade value for statistics
    local tradeValue = 0
    
    -- Execute the trade
    -- Remove items from player 1
    for _, pet in ipairs(trade.player1.items.pets) do
        for i, ownedPet in ipairs(player1Data.pets) do
            if ownedPet.id == pet.id then
                table.remove(player1Data.pets, i)
                local petData = PetDatabase[ownedPet.petId]
                if petData then
                    tradeValue = tradeValue + petData.baseValue
                end
                break
            end
        end
    end
    
    for currency, amount in pairs(trade.player1.items.currencies) do
        player1Data.currencies[currency] = player1Data.currencies[currency] - amount
        tradeValue = tradeValue + amount
    end
    
    -- Remove items from player 2
    for _, pet in ipairs(trade.player2.items.pets) do
        for i, ownedPet in ipairs(player2Data.pets) do
            if ownedPet.id == pet.id then
                table.remove(player2Data.pets, i)
                local petData = PetDatabase[ownedPet.petId]
                if petData then
                    tradeValue = tradeValue + petData.baseValue
                end
                break
            end
        end
    end
    
    for currency, amount in pairs(trade.player2.items.currencies) do
        player2Data.currencies[currency] = player2Data.currencies[currency] - amount
        tradeValue = tradeValue + amount
    end
    
    -- Apply trade tax
    local taxAmount = math.floor(tradeValue * CONFIG.TRADE_TAX_PERCENTAGE)
    
    -- Add items to player 1 (from player 2)
    for _, pet in ipairs(trade.player2.items.pets) do
        pet.owner = trade.player1.userId
        pet.tradedFrom = trade.player2.userId
        pet.tradedAt = os.time()
        table.insert(player1Data.pets, pet)
    end
    
    for currency, amount in pairs(trade.player2.items.currencies) do
        local afterTax = math.floor(amount * (1 - CONFIG.TRADE_TAX_PERCENTAGE))
        player1Data.currencies[currency] = player1Data.currencies[currency] + afterTax
    end
    
    -- Add items to player 2 (from player 1)
    for _, pet in ipairs(trade.player1.items.pets) do
        pet.owner = trade.player2.userId
        pet.tradedFrom = trade.player1.userId
        pet.tradedAt = os.time()
        table.insert(player2Data.pets, pet)
    end
    
    for currency, amount in pairs(trade.player1.items.currencies) do
        local afterTax = math.floor(amount * (1 - CONFIG.TRADE_TAX_PERCENTAGE))
        player2Data.currencies[currency] = player2Data.currencies[currency] + afterTax
    end
    
    -- Update statistics
    player1Data.statistics.tradingStats.tradesCompleted = player1Data.statistics.tradingStats.tradesCompleted + 1
    player2Data.statistics.tradingStats.tradesCompleted = player2Data.statistics.tradingStats.tradesCompleted + 1
    
    player1Data.statistics.tradingStats.totalTradeValue = player1Data.statistics.tradingStats.totalTradeValue + tradeValue
    player2Data.statistics.tradingStats.totalTradeValue = player2Data.statistics.tradingStats.totalTradeValue + tradeValue
    
    -- Add to trade history
    local tradeRecord = {
        tradeId = tradeId,
        partner = trade.player2.userId,
        gave = trade.player1.items,
        received = trade.player2.items,
        timestamp = os.time(),
        value = tradeValue
    }
    table.insert(player1Data.trading.history, tradeRecord)
    
    tradeRecord = {
        tradeId = tradeId,
        partner = trade.player1.userId,
        gave = trade.player2.items,
        received = trade.player1.items,
        timestamp = os.time(),
        value = tradeValue
    }
    table.insert(player2Data.trading.history, tradeRecord)
    
    -- Save to DataStore
    SavePlayerData(trade.player1.player)
    SavePlayerData(trade.player2.player)
    
    -- Save trade to history
    spawn(function()
        pcall(function()
            DataStores.TradeHistory:SetAsync(tradeId, {
                player1 = trade.player1.userId,
                player2 = trade.player2.userId,
                items1 = trade.player1.items,
                items2 = trade.player2.items,
                timestamp = os.time(),
                value = tradeValue,
                tax = taxAmount
            })
        end)
    end)
    
    -- Mark trade as completed
    trade.status = "completed"
    trade.completedAt = tick()
    
    -- Notify players
    if RemoteEvents.TradeCompleted then
        RemoteEvents.TradeCompleted:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeCompleted:FireClient(trade.player2.player, trade)
    end
    
    -- Clean up
    ActiveTrades[tradeId] = nil
    
    -- Log analytics
    ServerAnalytics:LogEvent("TradeCompleted", nil, {
        player1 = trade.player1.userId,
        player2 = trade.player2.userId,
        value = tradeValue,
        tax = taxAmount
    })
    
    return true
end

function TradingSystem:CancelTrade(tradeId, player)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.player1.userId ~= player.UserId and trade.player2.userId ~= player.UserId then
        return false, "Player not in trade"
    end
    
    trade.status = "cancelled"
    trade.cancelledBy = player.UserId
    trade.cancelledAt = tick()
    
    -- Notify players
    if RemoteEvents.TradeCancelled then
        RemoteEvents.TradeCancelled:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeCancelled:FireClient(trade.player2.player, trade)
    end
    
    -- Update statistics
    local player1Data = PlayerData[trade.player1.userId]
    local player2Data = PlayerData[trade.player2.userId]
    
    if player1Data then
        player1Data.statistics.tradingStats.tradesDeclined = player1Data.statistics.tradingStats.tradesDeclined + 1
    end
    if player2Data then
        player2Data.statistics.tradingStats.tradesDeclined = player2Data.statistics.tradingStats.tradesDeclined + 1
    end
    
    -- Clean up
    ActiveTrades[tradeId] = nil
    
    return true
end

-- ========================================
-- BATTLE SYSTEM
-- ========================================
local BattleSystem = {}

function BattleSystem:CreateBattle(player1, player2, battleType)
    local battleId = Services.HttpService:GenerateGUID(false)
    
    local battle = {
        id = battleId,
        type = battleType or "pvp",
        player1 = {
            userId = player1.UserId,
            player = player1,
            pets = {},
            activePet = nil,
            health = 0,
            maxHealth = 0,
            energy = 100,
            buffs = {},
            debuffs = {}
        },
        player2 = {
            userId = player2.UserId,
            player = player2,
            pets = {},
            activePet = nil,
            health = 0,
            maxHealth = 0,
            energy = 100,
            buffs = {},
            debuffs = {}
        },
        turn = 1,
        currentPlayer = 1,
        status = "preparing",
        startedAt = nil,
        endedAt = nil,
        winner = nil,
        turnHistory = {},
        rewards = {}
    }
    
    BattleInstances[battleId] = battle
    
    -- Notify players
    if RemoteEvents.BattleStarted then
        RemoteEvents.BattleStarted:FireClient(player1, battle)
        RemoteEvents.BattleStarted:FireClient(player2, battle)
    end
    
    return battle
end

function BattleSystem:SetupBattleTeam(battleId, player, petIds)
    local battle = BattleInstances[battleId]
    if not battle then return false, "Battle not found" end
    
    if battle.status ~= "preparing" then
        return false, "Battle already started"
    end
    
    local battlePlayer = nil
    if battle.player1.userId == player.UserId then
        battlePlayer = battle.player1
    elseif battle.player2.userId == player.UserId then
        battlePlayer = battle.player2
    else
        return false, "Player not in battle"
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then return false, "Player data not found" end
    
    -- Validate pets
    battlePlayer.pets = {}
    for _, petId in ipairs(petIds) do
        for _, pet in ipairs(playerData.pets) do
            if pet.id == petId then
                local petData = PetDatabase[pet.petId]
                if petData then
                    local battlePet = {
                        id = pet.id,
                        petId = pet.petId,
                        name = pet.nickname or petData.displayName,
                        level = pet.level,
                        stats = {},
                        abilities = petData.abilities,
                        currentHealth = pet.stats.health,
                        maxHealth = pet.stats.health,
                        currentEnergy = pet.stats.energy,
                        maxEnergy = pet.stats.energy,
                        buffs = {},
                        debuffs = {},
                        cooldowns = {}
                    }
                    
                    -- Copy stats
                    for stat, value in pairs(pet.stats) do
                        battlePet.stats[stat] = value
                    end
                    
                    table.insert(battlePlayer.pets, battlePet)
                end
                break
            end
        end
    end
    
    if #battlePlayer.pets == 0 then
        return false, "No valid pets selected"
    end
    
    -- Set first pet as active
    battlePlayer.activePet = 1
    local activePet = battlePlayer.pets[1]
    battlePlayer.health = activePet.currentHealth
    battlePlayer.maxHealth = activePet.maxHealth
    
    -- Check if both players ready
    if #battle.player1.pets > 0 and #battle.player2.pets > 0 then
        battle.status = "active"
        battle.startedAt = tick()
        
        -- Notify players
        if RemoteEvents.BattleReady then
            RemoteEvents.BattleReady:FireClient(battle.player1.player, battle)
            RemoteEvents.BattleReady:FireClient(battle.player2.player, battle)
        end
    end
    
    return true
end

function BattleSystem:ExecuteTurn(battleId, player, action)
    local battle = BattleInstances[battleId]
    if not battle then return false, "Battle not found" end
    
    if battle.status ~= "active" then
        return false, "Battle not active"
    end
    
    -- Verify it's player's turn
    local playerNum = 0
    if battle.player1.userId == player.UserId then
        playerNum = 1
    elseif battle.player2.userId == player.UserId then
        playerNum = 2
    else
        return false, "Player not in battle"
    end
    
    if battle.currentPlayer ~= playerNum then
        return false, "Not your turn"
    end
    
    local attacker = playerNum == 1 and battle.player1 or battle.player2
    local defender = playerNum == 1 and battle.player2 or battle.player1
    
    local attackerPet = attacker.pets[attacker.activePet]
    local defenderPet = defender.pets[defender.activePet]
    
    if not attackerPet or not defenderPet then
        return false, "Invalid pet state"
    end
    
    local turnResult = {
        turn = battle.turn,
        attacker = playerNum,
        action = action,
        damage = 0,
        healing = 0,
        effects = {},
        critical = false
    }
    
    if action.type == "ability" then
        local ability = nil
        for _, ab in ipairs(attackerPet.abilities) do
            if ab.id == action.abilityId then
                ability = ab
                break
            end
        end
        
        if not ability then
            return false, "Invalid ability"
        end
        
        -- Check cooldown
        if attackerPet.cooldowns[ability.id] and attackerPet.cooldowns[ability.id] > 0 then
            return false, "Ability on cooldown"
        end
        
        -- Check energy
        if ability.energyCost and attackerPet.currentEnergy < ability.energyCost then
            return false, "Not enough energy"
        end
        
        -- Execute ability
        if ability.effect == "damage" or ability.effect == "damage_aoe" then
            local damage = ability.value
            
            -- Apply stats
            damage = damage + (attackerPet.stats.power or 0)
            
            -- Check critical
            local critRoll = math.random()
            if critRoll < (attackerPet.stats.critRate or 0) then
                damage = damage * (attackerPet.stats.critDamage or 1.5)
                turnResult.critical = true
            end
            
            -- Apply defense
            damage = damage - (defenderPet.stats.defense or 0)
            damage = math.max(1, damage)
            
            -- Deal damage
            defenderPet.currentHealth = defenderPet.currentHealth - damage
            defender.health = defender.health - damage
            
            turnResult.damage = damage
            
        elseif ability.effect == "heal" or ability.effect == "heal_aoe" then
            local healing = ability.value
            
            if ability.value < 1 then
                -- Percentage heal
                healing = math.floor(attackerPet.maxHealth * ability.value)
            end
            
            attackerPet.currentHealth = math.min(attackerPet.maxHealth, attackerPet.currentHealth + healing)
            attacker.health = attackerPet.currentHealth
            
            turnResult.healing = healing
            
        elseif ability.effect == "buff" then
            -- Apply buff
            table.insert(attackerPet.buffs, {
                id = ability.id,
                effect = ability.effect,
                value = ability.value,
                duration = ability.duration or 3,
                remaining = ability.duration or 3
            })
            
            table.insert(turnResult.effects, {
                type = "buff",
                target = "self",
                effect = ability.effect
            })
        end
        
        -- Set cooldown
        attackerPet.cooldowns[ability.id] = ability.cooldown
        
        -- Deduct energy
        if ability.energyCost then
            attackerPet.currentEnergy = attackerPet.currentEnergy - ability.energyCost
        end
        
    elseif action.type == "switch" then
        -- Switch pet
        if action.petIndex and action.petIndex <= #attacker.pets then
            local newPet = attacker.pets[action.petIndex]
            if newPet.currentHealth > 0 then
                attacker.activePet = action.petIndex
                attacker.health = newPet.currentHealth
                attacker.maxHealth = newPet.maxHealth
                
                table.insert(turnResult.effects, {
                    type = "switch",
                    newPet = newPet.name
                })
            else
                return false, "Cannot switch to fainted pet"
            end
        else
            return false, "Invalid pet index"
        end
        
    elseif action.type == "item" then
        -- Use item (if implemented)
        -- TODO: Implement item usage in battle
    end
    
    -- Check for defeated pets
    if defenderPet.currentHealth <= 0 then
        defenderPet.currentHealth = 0
        defender.health = 0
        
        -- Find next available pet
        local nextPet = nil
        for i, pet in ipairs(defender.pets) do
            if pet.currentHealth > 0 then
                defender.activePet = i
                defender.health = pet.currentHealth
                defender.maxHealth = pet.maxHealth
                nextPet = pet
                break
            end
        end
        
        if not nextPet then
            -- All pets defeated, battle over
            battle.status = "completed"
            battle.endedAt = tick()
            battle.winner = playerNum
            
            -- Calculate rewards
            self:CalculateBattleRewards(battle)
            
            -- Update statistics
            self:UpdateBattleStats(battle)
            
            -- Notify players
            if RemoteEvents.BattleEnded then
                RemoteEvents.BattleEnded:FireClient(battle.player1.player, battle)
                RemoteEvents.BattleEnded:FireClient(battle.player2.player, battle)
            end
            
            -- Clean up
            BattleInstances[battleId] = nil
            
            return true
        end
    end
    
    -- Process buffs/debuffs
    for _, pet in ipairs(attacker.pets) do
        for i = #pet.buffs, 1, -1 do
            local buff = pet.buffs[i]
            buff.remaining = buff.remaining - 1
            if buff.remaining <= 0 then
                table.remove(pet.buffs, i)
            end
        end
        
        for i = #pet.debuffs, 1, -1 do
            local debuff = pet.debuffs[i]
            debuff.remaining = debuff.remaining - 1
            if debuff.remaining <= 0 then
                table.remove(pet.debuffs, i)
            end
        end
    end
    
    -- Reduce cooldowns
    for _, pet in ipairs(attacker.pets) do
        for abilityId, cooldown in pairs(pet.cooldowns) do
            if cooldown > 0 then
                pet.cooldowns[abilityId] = cooldown - 1
            end
        end
    end
    
    -- Record turn
    table.insert(battle.turnHistory, turnResult)
    
    -- Switch turns
    battle.turn = battle.turn + 1
    battle.currentPlayer = battle.currentPlayer == 1 and 2 or 1
    
    -- Update both players
    if RemoteEvents.BattleTurnCompleted then
        RemoteEvents.BattleTurnCompleted:FireClient(battle.player1.player, battle, turnResult)
        RemoteEvents.BattleTurnCompleted:FireClient(battle.player2.player, battle, turnResult)
    end
    
    return true
end

function BattleSystem:CalculateBattleRewards(battle)
    local winner = battle.winner == 1 and battle.player1 or battle.player2
    local loser = battle.winner == 1 and battle.player2 or battle.player1
    
    -- Base rewards
    local baseCoins = 1000
    local baseGems = 10
    local baseXP = 100
    
    -- Apply multipliers
    local coinReward = baseCoins * CONFIG.BATTLE_REWARDS_MULTIPLIER
    local gemReward = baseGems
    local xpReward = baseXP * CONFIG.BATTLE_XP_GAIN
    
    -- Winner rewards
    battle.rewards.winner = {
        coins = coinReward,
        gems = gemReward,
        xp = xpReward
    }
    
    -- Loser rewards (50% of winner)
    battle.rewards.loser = {
        coins = math.floor(coinReward * 0.5),
        gems = math.floor(gemReward * 0.5),
        xp = math.floor(xpReward * 0.5)
    }
    
    -- Apply rewards
    local winnerData = PlayerData[winner.userId]
    local loserData = PlayerData[loser.userId]
    
    if winnerData then
        winnerData.currencies.coins = winnerData.currencies.coins + battle.rewards.winner.coins
        winnerData.currencies.gems = winnerData.currencies.gems + battle.rewards.winner.gems
        
        -- Add XP to pets
        for _, pet in ipairs(winner.pets) do
            for _, ownedPet in ipairs(winnerData.pets) do
                if ownedPet.id == pet.id then
                    ownedPet.experience = ownedPet.experience + battle.rewards.winner.xp
                    -- Check for level up
                    local petData = PetDatabase[ownedPet.petId]
                    if petData and petData.xpRequirements[ownedPet.level] then
                        if ownedPet.experience >= petData.xpRequirements[ownedPet.level] then
                            ownedPet.level = ownedPet.level + 1
                            ownedPet.experience = ownedPet.experience - petData.xpRequirements[ownedPet.level - 1]
                            
                            -- Level up stat boost
                            for stat, value in pairs(ownedPet.stats) do
                                ownedPet.stats[stat] = math.floor(value * 1.1)
                            end
                        end
                    end
                    break
                end
            end
        end
        
        SavePlayerData(winner.player)
    end
    
    if loserData then
        loserData.currencies.coins = loserData.currencies.coins + battle.rewards.loser.coins
        loserData.currencies.gems = loserData.currencies.gems + battle.rewards.loser.gems
        
        -- Add XP to pets (less for losing)
        for _, pet in ipairs(loser.pets) do
            for _, ownedPet in ipairs(loserData.pets) do
                if ownedPet.id == pet.id then
                    ownedPet.experience = ownedPet.experience + battle.rewards.loser.xp
                    break
                end
            end
        end
        
        SavePlayerData(loser.player)
    end
end

function BattleSystem:UpdateBattleStats(battle)
    local winner = battle.winner == 1 and battle.player1 or battle.player2
    local loser = battle.winner == 1 and battle.player2 or battle.player1
    
    local winnerData = PlayerData[winner.userId]
    local loserData = PlayerData[loser.userId]
    
    if winnerData then
        winnerData.statistics.battleStats.wins = winnerData.statistics.battleStats.wins + 1
        winnerData.statistics.battleStats.winStreak = winnerData.statistics.battleStats.winStreak + 1
        
        if winnerData.statistics.battleStats.winStreak > winnerData.statistics.battleStats.highestWinStreak then
            winnerData.statistics.battleStats.highestWinStreak = winnerData.statistics.battleStats.winStreak
        end
    end
    
    if loserData then
        loserData.statistics.battleStats.losses = loserData.statistics.battleStats.losses + 1
        loserData.statistics.battleStats.winStreak = 0
    end
    
    -- Log analytics
    ServerAnalytics:LogEvent("BattleCompleted", nil, {
        battleId = battle.id,
        winner = winner.userId,
        loser = loser.userId,
        duration = battle.endedAt - battle.startedAt,
        turns = battle.turn
    })
end

-- ========================================
-- CLAN SYSTEM
-- ========================================
local ClanSystem = {}

function ClanSystem:CreateClan(player, clanName, clanTag)
    local playerData = PlayerData[player.UserId]
    if not playerData then return false, "Player data not found" end
    
    -- Check if player already in clan
    if playerData.clan.id then
        return false, "You are already in a clan"
    end
    
    -- Check currency
    if playerData.currencies.coins < CONFIG.CLAN_CREATE_COST then
        return false, "Not enough coins. Need " .. CONFIG.CLAN_CREATE_COST
    end
    
    -- Validate clan name
    if #clanName < 3 or #clanName > 20 then
        return false, "Clan name must be 3-20 characters"
    end
    
    if #clanTag < 2 or #clanTag > 5 then
        return false, "Clan tag must be 2-5 characters"
    end
    
    -- Check if clan name exists
    local existingClan = nil
    local success, result = pcall(function()
        return DataStores.ClanData:GetAsync("ClanName_" .. clanName)
    end)
    
    if success and result then
        return false, "Clan name already taken"
    end
    
    -- Create clan
    local clanId = Services.HttpService:GenerateGUID(false)
    
    local clan = {
        id = clanId,
        name = clanName,
        tag = clanTag,
        owner = player.UserId,
        created = os.time(),
        level = 1,
        experience = 0,
        treasury = {
            coins = 0,
            gems = 0
        },
        members = {
            [player.UserId] = {
                userId = player.UserId,
                username = player.Name,
                role = "owner",
                joinDate = os.time(),
                contribution = 0,
                permissions = {
                    invite = true,
                    kick = true,
                    promote = true,
                    withdraw = true,
                    startWar = true,
                    editInfo = true
                }
            }
        },
        memberCount = 1,
        maxMembers = 10,
        description = "A new clan",
        requirements = {
            minLevel = 0,
            approval = false
        },
        stats = {
            wars = 0,
            wins = 0,
            losses = 0,
            totalContribution = 0
        },
        perks = {},
        announcements = {},
        invites = {},
        applications = {}
    }
    
    -- Deduct cost
    playerData.currencies.coins = playerData.currencies.coins - CONFIG.CLAN_CREATE_COST
    
    -- Update player data
    playerData.clan = {
        id = clanId,
        name = clanName,
        role = "owner",
        contribution = 0,
        joinDate = os.time(),
        permissions = clan.members[player.UserId].permissions
    }
    
    -- Save clan data
    local saveSuccess = pcall(function()
        DataStores.ClanData:SetAsync(clanId, clan)
        DataStores.ClanData:SetAsync("ClanName_" .. clanName, clanId)
    end)
    
    if not saveSuccess then
        -- Refund
        playerData.currencies.coins = playerData.currencies.coins + CONFIG.CLAN_CREATE_COST
        return false, "Failed to create clan"
    end
    
    -- Cache clan
    ClanData[clanId] = clan
    
    -- Save player data
    SavePlayerData(player)
    
    -- Notify player
    if RemoteEvents.ClanCreated then
        RemoteEvents.ClanCreated:FireClient(player, clan)
    end
    
    -- Log analytics
    ServerAnalytics:LogEvent("ClanCreated", player, {
        clanId = clanId,
        clanName = clanName,
        clanTag = clanTag
    })
    
    return true, clan
end

function ClanSystem:InvitePlayer(clanId, inviter, targetUsername)
    local clan = ClanData[clanId]
    if not clan then
        -- Load from DataStore
        local success, data = pcall(function()
            return DataStores.ClanData:GetAsync(clanId)
        end)
        if success and data then
            clan = data
            ClanData[clanId] = clan
        else
            return false, "Clan not found"
        end
    end
    
    -- Check permissions
    local member = clan.members[inviter.UserId]
    if not member or not member.permissions.invite then
        return false, "You don't have permission to invite"
    end
    
    -- Check clan capacity
    if clan.memberCount >= clan.maxMembers then
        return false, "Clan is full"
    end
    
    -- Find target player
    local targetPlayer = nil
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.Name == targetUsername then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer then
        return false, "Player not found"
    end
    
    local targetData = PlayerData[targetPlayer.UserId]
    if not targetData then
        return false, "Player data not found"
    end
    
    if targetData.clan.id then
        return false, "Player is already in a clan"
    end
    
    -- Create invite
    local inviteId = Services.HttpService:GenerateGUID(false)
    clan.invites[inviteId] = {
        id = inviteId,
        targetUserId = targetPlayer.UserId,
        invitedBy = inviter.UserId,
        timestamp = os.time(),
        expires = os.time() + 86400 -- 24 hours
    }
    
    -- Save clan data
    pcall(function()
        DataStores.ClanData:SetAsync(clanId, clan)
    end)
    
    -- Notify target player
    if RemoteEvents.ClanInvite then
        RemoteEvents.ClanInvite:FireClient(targetPlayer, {
            inviteId = inviteId,
            clan = clan,
            invitedBy = inviter.Name
        })
    end
    
    return true
end

-- ========================================
-- QUEST SYSTEM
-- ========================================
local QuestSystem = {}

-- Define quest templates
local QuestTemplates = {
    daily = {
        {
            id = "hatch_eggs",
            name = "Egg Collector",
            description = "Hatch {target} eggs",
            type = "hatch_eggs",
            target = 10,
            rewards = {coins = 1000, gems = 10, xp = 100},
            difficulty = "easy"
        },
        {
            id = "win_battles",
            name = "Battle Champion",
            description = "Win {target} battles",
            type = "win_battles",
            target = 5,
            rewards = {coins = 2000, gems = 20, xp = 200},
            difficulty = "medium"
        },
        {
            id = "trade_pets",
            name = "Pet Trader",
            description = "Complete {target} trades",
            type = "complete_trades",
            target = 3,
            rewards = {coins = 1500, gems = 15, xp = 150},
            difficulty = "medium"
        },
        {
            id = "collect_coins",
            name = "Coin Collector",
            description = "Collect {target} coins",
            type = "collect_coins",
            target = 10000,
            rewards = {gems = 25, xp = 250},
            difficulty = "easy"
        },
        {
            id = "evolve_pet",
            name = "Evolution Master",
            description = "Evolve {target} pets",
            type = "evolve_pets",
            target = 1,
            rewards = {coins = 5000, gems = 50, xp = 500},
            difficulty = "hard"
        }
    },
    weekly = {
        {
            id = "legendary_hunt",
            name = "Legendary Hunter",
            description = "Hatch {target} legendary pets",
            type = "hatch_legendary",
            target = 1,
            rewards = {coins = 10000, gems = 100, xp = 1000},
            difficulty = "hard"
        },
        {
            id = "battle_master",
            name = "Battle Master",
            description = "Win {target} battles in a row",
            type = "win_streak",
            target = 10,
            rewards = {coins = 15000, gems = 150, xp = 1500},
            difficulty = "hard"
        },
        {
            id = "clan_contributor",
            name = "Clan Contributor",
            description = "Contribute {target} to clan",
            type = "clan_contribution",
            target = 100000,
            rewards = {coins = 20000, gems = 200, xp = 2000},
            difficulty = "medium"
        }
    }
}

function QuestSystem:GenerateDailyQuests(player)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    -- Check if already generated today
    local today = os.date("*t")
    local todayKey = string.format("%04d-%02d-%02d", today.year, today.month, today.day)
    
    if playerData.quests.lastDaily == todayKey then
        return -- Already generated
    end
    
    -- Clear old daily quests
    playerData.quests.daily = {}
    
    -- Generate new quests
    local availableQuests = {}
    for _, quest in ipairs(QuestTemplates.daily) do
        table.insert(availableQuests, quest)
    end
    
    -- Shuffle and select
    for i = 1, CONFIG.DAILY_QUEST_COUNT do
        if #availableQuests > 0 then
            local index = math.random(1, #availableQuests)
            local questTemplate = availableQuests[index]
            table.remove(availableQuests, index)
            
            local quest = {
                id = questTemplate.id .. "_" .. os.time() .. "_" .. i,
                templateId = questTemplate.id,
                name = questTemplate.name,
                description = questTemplate.description:gsub("{target}", tostring(questTemplate.target)),
                type = questTemplate.type,
                target = questTemplate.target,
                progress = 0,
                completed = false,
                claimed = false,
                rewards = questTemplate.rewards,
                difficulty = questTemplate.difficulty,
                expiresAt = os.time() + CONFIG.QUEST_REFRESH_TIME.Daily
            }
            
            table.insert(playerData.quests.daily, quest)
        end
    end
    
    playerData.quests.lastDaily = todayKey
    
    -- Notify player
    if RemoteEvents.QuestsUpdated then
        RemoteEvents.QuestsUpdated:FireClient(player, playerData.quests)
    end
end

function QuestSystem:UpdateQuestProgress(player, questType, amount)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    amount = amount or 1
    
    -- Check daily quests
    for _, quest in ipairs(playerData.quests.daily) do
        if quest.type == questType and not quest.completed then
            quest.progress = quest.progress + amount
            
            if quest.progress >= quest.target then
                quest.progress = quest.target
                quest.completed = true
                
                -- Notify completion
                if RemoteEvents.QuestCompleted then
                    RemoteEvents.QuestCompleted:FireClient(player, quest)
                end
            end
        end
    end
    
    -- Check weekly quests
    for _, quest in ipairs(playerData.quests.weekly) do
        if quest.type == questType and not quest.completed then
            quest.progress = quest.progress + amount
            
            if quest.progress >= quest.target then
                quest.progress = quest.target
                quest.completed = true
                
                -- Notify completion
                if RemoteEvents.QuestCompleted then
                    RemoteEvents.QuestCompleted:FireClient(player, quest)
                end
            end
        end
    end
    
    -- Update UI
    if RemoteEvents.QuestsUpdated then
        RemoteEvents.QuestsUpdated:FireClient(player, playerData.quests)
    end
end

function QuestSystem:ClaimQuestReward(player, questId)
    local playerData = PlayerData[player.UserId]
    if not playerData then return false, "Player data not found" end
    
    -- Find quest
    local quest = nil
    for _, q in ipairs(playerData.quests.daily) do
        if q.id == questId then
            quest = q
            break
        end
    end
    
    if not quest then
        for _, q in ipairs(playerData.quests.weekly) do
            if q.id == questId then
                quest = q
                break
            end
        end
    end
    
    if not quest then
        return false, "Quest not found"
    end
    
    if not quest.completed then
        return false, "Quest not completed"
    end
    
    if quest.claimed then
        return false, "Reward already claimed"
    end
    
    -- Give rewards
    if quest.rewards.coins then
        playerData.currencies.coins = playerData.currencies.coins + quest.rewards.coins
    end
    if quest.rewards.gems then
        playerData.currencies.gems = playerData.currencies.gems + quest.rewards.gems
    end
    if quest.rewards.xp then
        -- Add XP to equipped pets
        for _, petId in ipairs(playerData.equippedPets) do
            for _, pet in ipairs(playerData.pets) do
                if pet.id == petId then
                    pet.experience = pet.experience + quest.rewards.xp
                    break
                end
            end
        end
    end
    
    quest.claimed = true
    
    -- Save data
    SavePlayerData(player)
    
    -- Notify player
    if RemoteEvents.QuestRewardClaimed then
        RemoteEvents.QuestRewardClaimed:FireClient(player, quest)
    end
    
    return true
end

-- ========================================
-- ACHIEVEMENT SYSTEM
-- ========================================
local AchievementSystem = {}

local AchievementDefinitions = {
    -- Pet Collection
    {
        id = "first_pet",
        name = "First Friend",
        description = "Hatch your first pet",
        category = "collection",
        requirement = {type = "pets_hatched", value = 1},
        rewards = {coins = 100, title = "Pet Owner"},
        tier = "Bronze"
    },
    {
        id = "pet_collector_10",
        name = "Pet Collector",
        description = "Collect 10 different pets",
        category = "collection",
        requirement = {type = "unique_pets", value = 10},
        rewards = {coins = 1000, gems = 10, title = "Collector"},
        tier = "Bronze"
    },
    {
        id = "pet_collector_50",
        name = "Pet Master",
        description = "Collect 50 different pets",
        category = "collection",
        requirement = {type = "unique_pets", value = 50},
        rewards = {coins = 10000, gems = 100, title = "Master Collector"},
        tier = "Silver"
    },
    {
        id = "legendary_owner",
        name = "Legendary Trainer",
        description = "Own a legendary pet",
        category = "collection",
        requirement = {type = "legendary_pet", value = 1},
        rewards = {coins = 50000, gems = 500, title = "Legendary"},
        tier = "Gold"
    },
    
    -- Wealth
    {
        id = "millionaire",
        name = "Millionaire",
        description = "Have 1,000,000 coins",
        category = "wealth",
        requirement = {type = "coins", value = 1000000},
        rewards = {gems = 100, title = "Millionaire"},
        tier = "Silver"
    },
    {
        id = "billionaire",
        name = "Billionaire",
        description = "Have 1,000,000,000 coins",
        category = "wealth",
        requirement = {type = "coins", value = 1000000000},
        rewards = {gems = 1000, title = "Billionaire"},
        tier = "Gold"
    },
    
    -- Battle
    {
        id = "first_victory",
        name = "First Victory",
        description = "Win your first battle",
        category = "battle",
        requirement = {type = "battles_won", value = 1},
        rewards = {coins = 500, title = "Victor"},
        tier = "Bronze"
    },
    {
        id = "battle_veteran",
        name = "Battle Veteran",
        description = "Win 100 battles",
        category = "battle",
        requirement = {type = "battles_won", value = 100},
        rewards = {coins = 10000, gems = 100, title = "Veteran"},
        tier = "Silver"
    },
    {
        id = "undefeated",
        name = "Undefeated",
        description = "Win 10 battles in a row",
        category = "battle",
        requirement = {type = "win_streak", value = 10},
        rewards = {coins = 25000, gems = 250, title = "Undefeated"},
        tier = "Gold"
    },
    
    -- Trading
    {
        id = "first_trade",
        name = "First Trade",
        description = "Complete your first trade",
        category = "trading",
        requirement = {type = "trades_completed", value = 1},
        rewards = {coins = 500, title = "Trader"},
        tier = "Bronze"
    },
    {
        id = "master_trader",
        name = "Master Trader",
        description = "Complete 100 trades",
        category = "trading",
        requirement = {type = "trades_completed", value = 100},
        rewards = {coins = 20000, gems = 200, title = "Master Trader"},
        tier = "Gold"
    },
    
    -- Special
    {
        id = "lucky_hatch",
        name = "Lucky Hatch",
        description = "Hatch a mythical pet",
        category = "special",
        requirement = {type = "mythical_pet", value = 1},
        rewards = {coins = 100000, gems = 1000, title = "Blessed"},
        tier = "Diamond"
    },
    {
        id = "secret_finder",
        name = "Secret Finder",
        description = "Discover a secret pet",
        category = "special",
        requirement = {type = "secret_pet", value = 1},
        rewards = {coins = 999999, gems = 9999, title = "Secret Keeper"},
        tier = "Diamond"
    }
}

function AchievementSystem:CheckAchievements(player)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    for _, achievement in ipairs(AchievementDefinitions) do
        if not playerData.achievements[achievement.id] then
            local completed = false
            
            if achievement.requirement.type == "pets_hatched" then
                completed = playerData.statistics.totalPetsHatched >= achievement.requirement.value
                
            elseif achievement.requirement.type == "unique_pets" then
                local uniqueCount = 0
                for petId, _ in pairs(playerData.petCollection) do
                    uniqueCount = uniqueCount + 1
                end
                completed = uniqueCount >= achievement.requirement.value
                
            elseif achievement.requirement.type == "legendary_pet" then
                for _, pet in ipairs(playerData.pets) do
                    local petData = PetDatabase[pet.petId]
                    if petData and petData.rarity >= 5 then
                        completed = true
                        break
                    end
                end
                
            elseif achievement.requirement.type == "mythical_pet" then
                completed = playerData.statistics.mythicalPetsFound >= achievement.requirement.value
                
            elseif achievement.requirement.type == "secret_pet" then
                completed = playerData.statistics.secretPetsFound >= achievement.requirement.value
                
            elseif achievement.requirement.type == "coins" then
                completed = playerData.currencies.coins >= achievement.requirement.value
                
            elseif achievement.requirement.type == "battles_won" then
                completed = playerData.statistics.battleStats.wins >= achievement.requirement.value
                
            elseif achievement.requirement.type == "win_streak" then
                completed = playerData.statistics.battleStats.highestWinStreak >= achievement.requirement.value
                
            elseif achievement.requirement.type == "trades_completed" then
                completed = playerData.statistics.tradingStats.tradesCompleted >= achievement.requirement.value
            end
            
            if completed then
                self:UnlockAchievement(player, achievement)
            end
        end
    end
end

function AchievementSystem:UnlockAchievement(player, achievement)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    playerData.achievements[achievement.id] = {
        unlockedAt = os.time(),
        tier = achievement.tier
    }
    
    -- Give rewards
    if achievement.rewards.coins then
        playerData.currencies.coins = playerData.currencies.coins + achievement.rewards.coins
    end
    if achievement.rewards.gems then
        playerData.currencies.gems = playerData.currencies.gems + achievement.rewards.gems
    end
    if achievement.rewards.title then
        table.insert(playerData.titles.owned, achievement.rewards.title)
    end
    
    -- Notify player
    if RemoteEvents.AchievementUnlocked then
        RemoteEvents.AchievementUnlocked:FireClient(player, achievement)
    end
    
    -- Log analytics
    ServerAnalytics:LogEvent("AchievementUnlocked", player, {
        achievementId = achievement.id,
        tier = achievement.tier
    })
end

-- ========================================
-- DAILY REWARDS SYSTEM
-- ========================================
local DailyRewardSystem = {}

local DailyRewards = {
    {day = 1, rewards = {coins = 1000, gems = 10}},
    {day = 2, rewards = {coins = 2000, gems = 20}},
    {day = 3, rewards = {coins = 3000, gems = 30}},
    {day = 4, rewards = {coins = 4000, gems = 40}},
    {day = 5, rewards = {coins = 5000, gems = 50, items = {"lucky_potion"}}},
    {day = 6, rewards = {coins = 6000, gems = 60}},
    {day = 7, rewards = {coins = 10000, gems = 100, egg = "premium"}}
}

function DailyRewardSystem:CheckDailyReward(player)
    local playerData = PlayerData[player.UserId]
    if not playerData then return false end
    
    local now = os.time()
    local lastClaim = playerData.dailyRewards.lastClaim
    
    -- Check if can claim
    local timeSinceLastClaim = now - lastClaim
    if timeSinceLastClaim < 86400 then -- 24 hours
        local timeRemaining = 86400 - timeSinceLastClaim
        return false, timeRemaining
    end
    
    -- Check streak
    if timeSinceLastClaim > 172800 then -- 48 hours - streak broken
        playerData.dailyRewards.streak = 0
    end
    
    return true
end

function DailyRewardSystem:ClaimDailyReward(player)
    local canClaim, timeRemaining = self:CheckDailyReward(player)
    if not canClaim then
        return false, "Please wait " .. math.floor(timeRemaining / 3600) .. " hours"
    end
    
    local playerData = PlayerData[player.UserId]
    
    -- Increment streak
    playerData.dailyRewards.streak = playerData.dailyRewards.streak + 1
    if playerData.dailyRewards.streak > 7 then
        playerData.dailyRewards.streak = 1
    end
    
    -- Get reward
    local rewardData = DailyRewards[playerData.dailyRewards.streak]
    local rewards = {}
    
    -- Apply rewards
    if rewardData.rewards.coins then
        local coins = rewardData.rewards.coins * playerData.dailyRewards.multiplier
        playerData.currencies.coins = playerData.currencies.coins + coins
        rewards.coins = coins
    end
    
    if rewardData.rewards.gems then
        local gems = rewardData.rewards.gems * playerData.dailyRewards.multiplier
        playerData.currencies.gems = playerData.currencies.gems + gems
        rewards.gems = gems
    end
    
    if rewardData.rewards.items then
        rewards.items = rewardData.rewards.items
        -- TODO: Add items to inventory
    end
    
    if rewardData.rewards.egg then
        rewards.egg = rewardData.rewards.egg
        -- Give free egg
    end
    
    -- Update last claim
    playerData.dailyRewards.lastClaim = os.time()
    
    -- Add to history
    table.insert(playerData.dailyRewards.history, {
        day = playerData.dailyRewards.streak,
        claimedAt = os.time(),
        rewards = rewards
    })
    
    -- Keep only last 30 days of history
    if #playerData.dailyRewards.history > 30 then
        table.remove(playerData.dailyRewards.history, 1)
    end
    
    -- Save data
    SavePlayerData(player)
    
    -- Notify player
    if RemoteEvents.DailyRewardClaimed then
        RemoteEvents.DailyRewardClaimed:FireClient(player, {
            streak = playerData.dailyRewards.streak,
            rewards = rewards
        })
    end
    
    return true, rewards
end

-- ========================================
-- INITIALIZATION
-- ========================================
local function SetupRemoteEvents()
    local remoteFolder = Services.ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "RemoteEvents"
        remoteFolder.Parent = Services.ReplicatedStorage
    end
    
    -- Create RemoteEvents
    local eventNames = {
        "DataLoaded",
        "CaseOpened",
        "TradeStarted",
        "TradeUpdated",
        "TradeCompleted",
        "TradeCancelled",
        "BattleStarted",
        "BattleReady",
        "BattleTurnCompleted",
        "BattleEnded",
        "ClanCreated",
        "ClanInvite",
        "QuestsUpdated",
        "QuestCompleted",
        "QuestRewardClaimed",
        "AchievementUnlocked",
        "DailyRewardClaimed",
        "NotificationSent",
        "CurrencyUpdated",
        "PetUpdated",
        "InventoryUpdated"
    }
    
    for _, eventName in ipairs(eventNames) do
        local remoteEvent = remoteFolder:FindFirstChild(eventName)
        if not remoteEvent then
            remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = eventName
            remoteEvent.Parent = remoteFolder
        end
        RemoteEvents[eventName] = remoteEvent
    end
    
    -- Create RemoteFunctions
    local functionNames = {
        "OpenCase",
        "RequestTrade",
        "UpdateTrade",
        "ConfirmTrade",
        "JoinBattle",
        "BattleTurn",
        "CreateClan",
        "JoinClan",
        "ClaimQuest",
        "ClaimDailyReward",
        "GetPlayerData",
        "SaveSettings"
    }
    
    for _, functionName in ipairs(functionNames) do
        local remoteFunction = remoteFolder:FindFirstChild(functionName)
        if not remoteFunction then
            remoteFunction = Instance.new("RemoteFunction")
            remoteFunction.Name = functionName
            remoteFunction.Parent = remoteFolder
        end
        RemoteFunctions[functionName] = remoteFunction
    end
end

local function SetupRemoteHandlers()
    -- Case Opening
    RemoteFunctions.OpenCase.OnServerInvoke = function(player, eggType)
        return OpenCase(player, eggType)
    end
    
    -- Trading
    RemoteFunctions.RequestTrade.OnServerInvoke = function(player, targetPlayer)
        -- Rate limit check
        local canProceed, errorMsg = RateLimiter:Check(player, "Trade")
        if not canProceed then
            return {success = false, error = errorMsg}
        end
        
        -- Check if players can trade
        local playerData = PlayerData[player.UserId]
        local targetData = PlayerData[targetPlayer.UserId]
        
        if not playerData or not targetData then
            return {success = false, error = "Player data not found"}
        end
        
        -- Level check
        if playerData.rebirth.level < CONFIG.MIN_LEVEL_TO_TRADE then
            return {success = false, error = "You need to be level " .. CONFIG.MIN_LEVEL_TO_TRADE .. " to trade"}
        end
        
        if targetData.rebirth.level < CONFIG.MIN_LEVEL_TO_TRADE then
            return {success = false, error = "Target player needs to be level " .. CONFIG.MIN_LEVEL_TO_TRADE}
        end
        
        -- Check if target accepts trades
        if not targetData.settings.tradeRequests then
            return {success = false, error = "Player has trades disabled"}
        end
        
        -- Create trade
        local trade = TradingSystem:CreateTrade(player, targetPlayer)
        return {success = true, trade = trade}
    end
    
    RemoteFunctions.UpdateTrade.OnServerInvoke = function(player, tradeId, action, data)
        if action == "add_item" then
            return TradingSystem:AddItem(tradeId, player, data.itemType, data.itemData)
        elseif action == "remove_item" then
            return TradingSystem:RemoveItem(tradeId, player, data.itemType, data.itemData)
        elseif action == "set_ready" then
            return TradingSystem:SetReady(tradeId, player, data.ready)
        elseif action == "cancel" then
            return TradingSystem:CancelTrade(tradeId, player)
        end
    end
    
    RemoteFunctions.ConfirmTrade.OnServerInvoke = function(player, tradeId)
        return TradingSystem:ConfirmTrade(tradeId, player)
    end
    
    -- Battle
    RemoteFunctions.JoinBattle.OnServerInvoke = function(player, targetPlayer)
        -- Rate limit check
        local canProceed, errorMsg = RateLimiter:Check(player, "Battle")
        if not canProceed then
            return {success = false, error = errorMsg}
        end
        
        local battle = BattleSystem:CreateBattle(player, targetPlayer, "pvp")
        return {success = true, battle = battle}
    end
    
    RemoteFunctions.BattleTurn.OnServerInvoke = function(player, battleId, action)
        return BattleSystem:ExecuteTurn(battleId, player, action)
    end
    
    -- Clan
    RemoteFunctions.CreateClan.OnServerInvoke = function(player, clanName, clanTag)
        return ClanSystem:CreateClan(player, clanName, clanTag)
    end
    
    RemoteFunctions.JoinClan.OnServerInvoke = function(player, inviteId)
        -- TODO: Implement clan joining
    end
    
    -- Quests
    RemoteFunctions.ClaimQuest.OnServerInvoke = function(player, questId)
        return QuestSystem:ClaimQuestReward(player, questId)
    end
    
    -- Daily Rewards
    RemoteFunctions.ClaimDailyReward.OnServerInvoke = function(player)
        return DailyRewardSystem:ClaimDailyReward(player)
    end
    
    -- Data
    RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
        return PlayerData[player.UserId]
    end
    
    RemoteFunctions.SaveSettings.OnServerInvoke = function(player, settings)
        local playerData = PlayerData[player.UserId]
        if playerData then
            playerData.settings = settings
            SavePlayerData(player)
            return true
        end
        return false
    end
end

local function OnPlayerAdded(player)
    -- Load player data
    LoadPlayerData(player)
    
    -- Generate daily quests
    QuestSystem:GenerateDailyQuests(player)
    
    -- Check achievements
    AchievementSystem:CheckAchievements(player)
    
    -- Check daily reward
    DailyRewardSystem:CheckDailyReward(player)
    
    -- Welcome message
    if RemoteEvents.NotificationSent then
        wait(3)
        RemoteEvents.NotificationSent:FireClient(player, {
            type = "welcome",
            title = "Welcome to Sanrio Tycoon Shop!",
            message = "Start your adventure by opening your first egg!",
            duration = 10
        })
    end
end

local function OnPlayerRemoving(player)
    -- Save player data
    SavePlayerData(player)
    
    -- Clean up
    RateLimiter:Reset(player)
    
    -- Cancel active trades
    for tradeId, trade in pairs(ActiveTrades) do
        if trade.player1.userId == player.UserId or trade.player2.userId == player.UserId then
            TradingSystem:CancelTrade(tradeId, player)
        end
    end
    
    -- End active battles
    for battleId, battle in pairs(BattleInstances) do
        if battle.player1.userId == player.UserId or battle.player2.userId == player.UserId then
            battle.status = "abandoned"
            battle.winner = battle.player1.userId == player.UserId and 2 or 1
            BattleSystem:UpdateBattleStats(battle)
            BattleInstances[battleId] = nil
        end
    end
    
    -- Remove from memory
    PlayerData[player.UserId] = nil
end

-- ========================================
-- MARKETPLACESERVICE HANDLING
-- ========================================
Services.MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Services.Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Handle gamepass purchases
    local gamepassData = GamepassData[receiptInfo.ProductId]
    if gamepassData then
        playerData.ownedGamepasses[receiptInfo.ProductId] = true
        
        -- Apply immediate benefits
        for _, benefit in ipairs(gamepassData.benefits) do
            if benefit.type == "storage_increase" then
                playerData.maxPetStorage = playerData.maxPetStorage + benefit.value
            elseif benefit.type == "pet_slots" then
                CONFIG.MAX_INVENTORY_SIZE = CONFIG.MAX_INVENTORY_SIZE + benefit.value
            end
        end
        
        SavePlayerData(player)
        
        -- Notify player
        if RemoteEvents.NotificationSent then
            RemoteEvents.NotificationSent:FireClient(player, {
                type = "purchase",
                title = "Purchase Successful!",
                message = "You now own " .. gamepassData.name,
                duration = 10
            })
        end
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    -- Handle developer products (like gem purchases)
    local productInfo = {
        [123499] = {gems = 100},
        [123500] = {gems = 500},
        [123501] = {gems = 1000},
        [123502] = {gems = 5000},
        [123503] = {gems = 10000}
    }
    
    local product = productInfo[receiptInfo.ProductId]
    if product then
        if product.gems then
            playerData.currencies.gems = playerData.currencies.gems + product.gems
            playerData.statistics.totalGemsEarned = playerData.statistics.totalGemsEarned + product.gems
        end
        
        SavePlayerData(player)
        
        -- Notify player
        if RemoteEvents.CurrencyUpdated then
            RemoteEvents.CurrencyUpdated:FireClient(player, playerData.currencies)
        end
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ========================================
-- AUTO-SAVE SYSTEM
-- ========================================
spawn(function()
    while true do
        wait(CONFIG.DATA_AUTOSAVE_INTERVAL)
        
        for userId, data in pairs(PlayerData) do
            local player = Services.Players:GetPlayerByUserId(userId)
            if player then
                SavePlayerData(player)
            end
        end
        
        -- Save clan data
        for clanId, clan in pairs(ClanData) do
            pcall(function()
                DataStores.ClanData:SetAsync(clanId, clan)
            end)
        end
        
        -- Flush analytics
        ServerAnalytics:FlushEvents()
    end
end)

-- ========================================
-- MAIN INITIALIZATION
-- ========================================
local function InitializeSanrioTycoonShop()
    print("Initializing Sanrio Tycoon Shop Server v" .. CONFIG.VERSION)
    
    -- Setup remote events
    SetupRemoteEvents()
    SetupRemoteHandlers()
    
    -- Connect player events
    Services.Players.PlayerAdded:Connect(OnPlayerAdded)
    Services.Players.PlayerRemoving:Connect(OnPlayerRemoving)
    
    -- Load existing players (in case script was added mid-game)
    for _, player in ipairs(Services.Players:GetPlayers()) do
        OnPlayerAdded(player)
    end
    
    -- Initialize leaderboard
    spawn(function()
        while true do
            wait(60) -- Update every minute
            
            -- Update coin leaderboard
            local coinLeaderboard = {}
            for userId, data in pairs(PlayerData) do
                table.insert(coinLeaderboard, {
                    userId = userId,
                    value = data.currencies.coins,
                    username = data.username
                })
            end
            
            table.sort(coinLeaderboard, function(a, b)
                return a.value > b.value
            end)
            
            -- Save top 100
            local topCoins = {}
            for i = 1, math.min(100, #coinLeaderboard) do
                topCoins[i] = coinLeaderboard[i]
            end
            
            pcall(function()
                DataStores.LeaderboardData:SetAsync("TopCoins", topCoins)
            end)
        end
    end)
    
    print("Sanrio Tycoon Shop Server initialized successfully!")
end

-- Start the server
InitializeSanrioTycoonShop()

-- Return module for potential expansion
return SanrioTycoonServer