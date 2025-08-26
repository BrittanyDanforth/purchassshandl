--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - CONFIGURATION MODULE                          ║
    ║                              Central Configuration System                            ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local Configuration = {}

-- ========================================
-- GAME CONFIGURATION
-- ========================================
Configuration.CONFIG = {
    -- Data Management
    DATA_AUTOSAVE_INTERVAL = 60,
    DATA_RETRY_ATTEMPTS = 3,
    DATA_RETRY_DELAY = 2,
    
    -- Economy
    STARTING_COINS = 1000,
    STARTING_GEMS = 50,
    DAILY_REWARD_BASE = 100,
    DAILY_REWARD_STREAK_BONUS = 50,
    
    -- Trading
    TRADE_TAX_PERCENTAGE = 0.05,
    TRADE_COOLDOWN = 30,
    MAX_TRADE_ITEMS = 20,
    
    -- Battle
    BATTLE_TURN_TIME = 30,
    BATTLE_REWARD_MULTIPLIER = 1.5,
    BATTLE_XP_BASE = 100,
    
    -- Pets
    MAX_EQUIPPED_PETS = 6,
    MAX_INVENTORY_SIZE = 500,
    PET_FUSION_COST = 1000,
    PET_EVOLUTION_COST = 500,
    
    -- Clan
    CLAN_CREATE_COST = 10000,
    CLAN_MAX_MEMBERS = 50,
    CLAN_WAR_DURATION = 3600,
    
    -- Security
    RATE_LIMIT_REQUESTS = 10,
    RATE_LIMIT_WINDOW = 60,
    SUSPICIOUS_WEALTH_MULTIPLIER = 100,
    
    -- Group
    GROUP_ID = 123456789,
    GROUP_BONUS_MULTIPLIER = 1.1,
    
    -- Leaderboards
    LEADERBOARD_UPDATE_INTERVAL = 60,
    LEADERBOARD_MAX_ENTRIES = 100
}

-- ========================================
-- GAMEPASS IDS & DATA
-- ========================================
Configuration.GAMEPASS_IDS = {
    DOUBLE_COINS = 123457,
    AUTO_COLLECT = 123458,
    EXTRA_STORAGE = 123459,
    LUCKY_BOOST = 123460,
    INSTANT_HATCH = 123461,
    VIP = 123456,
    TELEPORT = 123462,
    TRIPLE_REWARDS = 123463,
    UNLIMITED_EQUIP = 123464,
    AUTO_DELETE = 123465
}

Configuration.GAMEPASS_DATA = {
    [123457] = {
        name = "2x Cash Multiplier",
        description = "Double all cash earned from eggs and rewards!",
        price = 199,
        icon = "rbxassetid://10000002001"
    },
    [123458] = {
        name = "Auto Collector",
        description = "Automatically collect rewards from your tycoon!",
        price = 299,
        icon = "rbxassetid://10000002002"
    },
    [123459] = {
        name = "Pet Storage +100",
        description = "Increase your pet storage by 100 slots!",
        price = 149,
        icon = "rbxassetid://10000002004"
    },
    [123460] = {
        name = "Lucky Boost",
        description = "Increase rare pet drops by 25%!",
        price = 399,
        icon = "rbxassetid://10000002005"
    },
    [123461] = {
        name = "Instant Hatch",
        description = "Skip egg hatching animations!",
        price = 99,
        icon = "rbxassetid://10000002006"
    },
    [123456] = {
        name = "VIP Status",
        description = "Exclusive VIP benefits and daily rewards!",
        price = 999,
        icon = "rbxassetid://10000002003"
    },
    [123462] = {
        name = "Teleport Access",
        description = "Teleport anywhere instantly!",
        price = 249,
        icon = "rbxassetid://10000002007"
    },
    [123463] = {
        name = "Triple Rewards",
        description = "3x rewards from all sources!",
        price = 599,
        icon = "rbxassetid://10000002008"
    },
    [123464] = {
        name = "Unlimited Equip",
        description = "Equip unlimited pets at once!",
        price = 799,
        icon = "rbxassetid://10000002009"
    },
    [123465] = {
        name = "Auto Delete",
        description = "Auto-delete common pets when inventory is full!",
        price = 199,
        icon = "rbxassetid://10000002010"
    }
}

-- ========================================
-- BADGE IDS
-- ========================================
Configuration.BADGE_IDS = {
    WELCOME = 2124441234,
    FIRST_PET = 2124441235,
    FIRST_TRADE = 2124441236,
    FIRST_BATTLE = 2124441237,
    LEGENDARY_PET = 2124441238,
    MYTHICAL_PET = 2124441239,
    SECRET_PET = 2124441240,
    CLAN_MEMBER = 2124441241,
    CLAN_LEADER = 2124441242,
    RICH_PLAYER = 2124441243
}

-- ========================================
-- DEVELOPER PRODUCT IDS
-- ========================================
Configuration.DEVELOPER_PRODUCTS = {
    COINS_1000 = 1234567890,
    COINS_5000 = 1234567891,
    COINS_10000 = 1234567892,
    GEMS_100 = 1234567893,
    GEMS_500 = 1234567894,
    GEMS_1000 = 1234567895
}

-- ========================================
-- RARITY CONFIGURATION
-- ========================================
Configuration.RARITY = {
    COMMON = 1,
    UNCOMMON = 2,
    RARE = 3,
    EPIC = 4,
    LEGENDARY = 5,
    MYTHICAL = 6,
    SECRET = 7,
    EVENT = 8,
    EXCLUSIVE = 9
}

-- ========================================
-- RARITY COLORS
-- ========================================
Configuration.RARITY_COLORS = {
    [1] = Color3.fromRGB(200, 200, 200), -- Common (Gray)
    [2] = Color3.fromRGB(100, 200, 100), -- Uncommon (Green)
    [3] = Color3.fromRGB(100, 150, 255), -- Rare (Blue)
    [4] = Color3.fromRGB(200, 100, 255), -- Epic (Purple)
    [5] = Color3.fromRGB(255, 200, 0),   -- Legendary (Gold)
    [6] = Color3.fromRGB(255, 100, 200), -- Mythical (Pink)
    [7] = Color3.fromRGB(255, 0, 0),     -- Secret (Red)
    [8] = Color3.fromRGB(0, 255, 255),   -- Event (Cyan)
    [9] = Color3.fromRGB(50, 50, 50)     -- Exclusive (Black)
}

-- ========================================
-- SOUND IDS
-- ========================================
Configuration.SOUNDS = {
    CASE_OPEN = "rbxassetid://9116891308",
    PET_HATCH = "rbxassetid://9116891309",
    LEVEL_UP = "rbxassetid://9116891310",
    PURCHASE = "rbxassetid://9116891311",
    ERROR = "rbxassetid://9116891312",
    SUCCESS = "rbxassetid://9116891313",
    BATTLE_START = "rbxassetid://9116891314",
    BATTLE_WIN = "rbxassetid://9116891315",
    BATTLE_LOSE = "rbxassetid://9116891316",
    NOTIFICATION = "rbxassetid://9116891317"
}

return Configuration