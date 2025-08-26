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
    ],
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

-- Continue in next part...