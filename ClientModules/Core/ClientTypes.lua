--[[
    Module: ClientTypes
    Description: Complete type definitions for the Sanrio Tycoon client
    Provides type safety and clear contracts across all modules
]]

local ClientTypes = {}

-- ========================================
-- PET TYPES
-- ========================================

-- Individual pet instance data
export type PetData = {
    id: string,                -- Unique instance ID
    petId: string,             -- Pet template ID (e.g., "cat_normal")
    level: number,             -- Current level (1-100)
    experience: number,        -- Current experience points
    stars: number,             -- Star rating (0-5)
    locked: boolean,           -- Whether pet is locked
    equipped: boolean,         -- Whether pet is equipped
    nickname: string?,         -- Optional custom name
    variant: string?,          -- Special variant (e.g., "golden", "rainbow")
    timestamp: number,         -- When pet was obtained
    source: string?,           -- How pet was obtained (e.g., "egg", "trade")
    obtained: string?,         -- Additional obtain info
    power: number?,            -- Battle power
    health: number?,           -- Battle health
    speed: number?,            -- Battle speed
    abilities: {string}?,      -- Battle abilities
}

-- Pet template/definition data
export type PetDefinition = {
    id: string,                -- Template ID
    name: string,              -- Display name
    rarity: number,            -- Rarity tier (1-7)
    baseValue: number,         -- Base coin value
    basePower: number,         -- Base battle power
    baseHealth: number,        -- Base battle health
    baseSpeed: number,         -- Base battle speed
    description: string,       -- Pet description
    imageId: string,           -- Asset ID for image
    modelId: string?,          -- Asset ID for 3D model
    animations: {[string]: string}?, -- Animation IDs
    evolvesTo: string?,        -- Evolution target
    evolveLevel: number?,      -- Level required to evolve
}

-- ========================================
-- PLAYER DATA TYPES
-- ========================================

-- Currency data
export type CurrencyData = {
    coins: number,
    gems: number,
    tickets: number,
    candies: number?,
    stars: number?,
}

-- Settings data
export type SettingsData = {
    musicVolume: number,       -- 0-1
    sfxVolume: number,         -- 0-1
    particlesEnabled: boolean,
    lowQualityMode: boolean,
    autoDelete: {
        enabled: boolean,
        rarities: {number},    -- Which rarities to auto-delete
    },
    uiScale: number,           -- 0.8-1.2
    language: string?,         -- Language code
    keybinds: {[string]: Enum.KeyCode}?,
}

-- Quest data
export type QuestData = {
    id: string,
    type: "daily" | "weekly" | "special",
    name: string,
    description: string,
    progress: number,
    target: number,
    completed: boolean,
    claimed: boolean,
    rewards: {
        currencies: CurrencyData?,
        items: {[string]: number}?,
        pets: {string}?,
    },
    expiresAt: number?,
}

-- Daily reward data
export type DailyRewardData = {
    streak: number,
    lastClaim: number,
    nextReward: number,
    currentDay: number,
    multiplier: number,
    specialRewards: {[number]: any}?,
}

-- Player statistics
export type PlayerStats = {
    totalPets: number,
    totalCoins: number,
    totalGems: number,
    eggsOpened: number,
    trades: number,
    battles: number,
    wins: number,
    playtime: number,
    achievements: number,
}

-- Complete player data structure
export type PlayerData = {
    userId: number,
    username: string,
    displayName: string,
    currencies: CurrencyData,
    pets: {[string]: PetData},
    inventory: {[string]: number},
    equipped: {string},         -- Array of equipped pet IDs
    settings: SettingsData,
    quests: {
        daily: {[string]: QuestData},
        weekly: {[string]: QuestData},
        special: {[string]: QuestData}?,
    },
    achievements: {[string]: boolean},
    stats: PlayerStats,
    dailyReward: DailyRewardData,
    battlepass: {
        level: number,
        experience: number,
        claimed: {[number]: boolean},
        premium: boolean,
    }?,
    clan: {
        id: string,
        name: string,
        role: string,
    }?,
    rebirth: {
        level: number,
        multiplier: number,
    }?,
}

-- ========================================
-- UI COMPONENT TYPES
-- ========================================

-- Button configuration
export type ButtonConfig = {
    parent: Instance,
    text: string,
    size: UDim2,
    position: UDim2,
    callback: () -> ()?,
    backgroundColor: Color3?,
    textColor: Color3?,
    font: Enum.Font?,
    textSize: number?,
    cornerRadius: number?,
    strokeColor: Color3?,
    strokeThickness: number?,
    hoverColor: Color3?,
    clickSound: string?,
}

-- Frame configuration
export type FrameConfig = {
    parent: Instance,
    name: string?,
    size: UDim2,
    position: UDim2,
    backgroundColor: Color3?,
    backgroundTransparency: number?,
    cornerRadius: number?,
    strokeColor: Color3?,
    strokeThickness: number?,
    zIndex: number?,
    visible: boolean?,
}

-- Label configuration
export type LabelConfig = {
    parent: Instance,
    text: string,
    size: UDim2,
    position: UDim2,
    textSize: number?,
    textColor: Color3?,
    font: Enum.Font?,
    textXAlignment: Enum.TextXAlignment?,
    textYAlignment: Enum.TextYAlignment?,
    backgroundColor: Color3?,
    backgroundTransparency: number?,
    textScaled: boolean?,
    richText: boolean?,
    zIndex: number?,
}

-- Notification configuration
export type NotificationConfig = {
    message: string,
    type: "success" | "error" | "warning" | "info" | "default",
    duration: number?,
    icon: string?,
    sound: boolean?,
    actions: {[string]: () -> ()}?,
    position: UDim2?,
    canDismiss: boolean?,
}

-- ========================================
-- TRADING TYPES
-- ========================================

export type TradeData = {
    tradeId: string,
    participants: {
        [string]: {  -- userId as key
            player: Player,
            ready: boolean,
            items: {
                pets: {string},
                currencies: CurrencyData?,
            },
        },
    },
    status: "pending" | "ready" | "completed" | "cancelled",
    timestamp: number,
    expiresAt: number,
}

-- ========================================
-- BATTLE TYPES
-- ========================================

export type BattleTeam = {
    pets: {PetData},
    player: Player,
    ready: boolean,
}

export type BattleState = {
    battleId: string,
    teams: {[string]: BattleTeam},
    currentTurn: string,        -- Player userId
    turnNumber: number,
    log: {string},
    status: "waiting" | "active" | "ended",
    winner: string?,
    rewards: {
        currencies: CurrencyData?,
        items: {[string]: number}?,
        experience: number?,
    }?,
}

export type BattleMove = {
    moveId: string,
    name: string,
    damage: number,
    type: string,
    cooldown: number,
    description: string,
}

-- ========================================
-- SHOP TYPES
-- ========================================

export type EggData = {
    id: string,
    name: string,
    price: number,
    currency: "coins" | "gems",
    contents: {
        [string]: number,       -- petId -> weight
    },
    imageId: string,
    description: string,
    limitedTime: boolean,
    stock: number?,
    owned: number?,
}

export type GamepassData = {
    id: number,
    name: string,
    price: number,              -- In Robux
    description: string,
    benefits: {string},
    imageId: string,
    owned: boolean,
}

export type CurrencyPackage = {
    id: string,
    name: string,
    price: number,              -- In Robux
    amount: number,
    currency: "coins" | "gems",
    bonus: number?,
    imageId: string,
}

-- ========================================
-- EVENT TYPES
-- ========================================

export type EventCallback<T...> = (T...) -> ()

export type Connection = {
    Disconnect: () -> (),
    Connected: boolean,
}

export type Event<T...> = {
    Connect: (callback: EventCallback<T...>) -> Connection,
    Once: (callback: EventCallback<T...>) -> Connection,
    Wait: () -> T...,
    Fire: (T...) -> (),
}

-- ========================================
-- STATE MANAGEMENT TYPES
-- ========================================

export type StateSubscription = {
    Unsubscribe: () -> (),
    IsActive: () -> boolean,
}

export type StateChange = {
    path: string,
    oldValue: any,
    newValue: any,
    timestamp: number,
}

-- ========================================
-- MODULE TYPES
-- ========================================

export type Module = {
    Name: string,
    Initialize: (dependencies: {[string]: any}) -> (),
    Destroy: () -> (),
    [string]: any,
}

export type ModuleStatus = "unloaded" | "loading" | "loaded" | "error"

export type ModuleInfo = {
    name: string,
    status: ModuleStatus,
    dependencies: {string},
    instance: Module?,
    error: string?,
    loadTime: number?,
}

-- ========================================
-- ANIMATION TYPES
-- ========================================

export type TweenConfig = {
    time: number?,
    easingStyle: Enum.EasingStyle?,
    easingDirection: Enum.EasingDirection?,
    repeatCount: number?,
    reverses: boolean?,
    delayTime: number?,
}

export type AnimationChain = {
    tweens: {TweenBase},
    onComplete: (() -> ())?,
    onStep: ((step: number) -> ())?,
}

-- ========================================
-- PARTICLE TYPES
-- ========================================

export type ParticleConfig = {
    parent: Instance,
    particleType: "sparkle" | "star" | "heart" | "coin" | "confetti",
    position: Vector3,
    velocity: Vector3?,
    lifetime: number?,
    size: number?,
    color: Color3?,
    transparency: number?,
    rotationSpeed: number?,
}

export type ParticleBurst = {
    config: ParticleConfig,
    count: number,
    spread: number?,
    duration: number?,
}

-- ========================================
-- UI WINDOW TYPES
-- ========================================

export type WindowConfig = {
    title: string,
    size: UDim2,
    position: UDim2?,
    canResize: boolean?,
    canMinimize: boolean?,
    canClose: boolean?,
    zIndex: number?,
    modal: boolean?,
}

export type WindowState = {
    isOpen: boolean,
    isMinimized: boolean,
    isFocused: boolean,
    position: UDim2,
    size: UDim2,
}

-- ========================================
-- NETWORK TYPES
-- ========================================

export type RemoteResult<T> = {
    success: boolean,
    data: T?,
    error: string?,
    code: string?,
}

export type RemoteOptions = {
    timeout: number?,
    retries: number?,
    priority: "low" | "normal" | "high"?,
}

-- ========================================
-- MISC TYPES
-- ========================================

export type ClanData = {
    id: string,
    name: string,
    description: string,
    icon: string,
    members: {
        [string]: {
            userId: number,
            username: string,
            role: "owner" | "admin" | "member",
            joinedAt: number,
            contribution: number,
        },
    },
    level: number,
    experience: number,
    perks: {string},
}

export type LeaderboardEntry = {
    rank: number,
    userId: number,
    username: string,
    displayName: string,
    value: number,
    avatar: string?,
    clan: string?,
}

export type LeaderboardData = {
    type: "coins" | "gems" | "pets" | "wins" | "playtime",
    timeframe: "daily" | "weekly" | "alltime",
    entries: {LeaderboardEntry},
    lastUpdated: number,
}

-- Type validation utilities
function ClientTypes.ValidatePetData(data: any): (boolean, string?)
    if type(data) ~= "table" then
        return false, "PetData must be a table"
    end
    
    if type(data.id) ~= "string" then
        return false, "PetData.id must be a string"
    end
    
    if type(data.petId) ~= "string" then
        return false, "PetData.petId must be a string"
    end
    
    if type(data.level) ~= "number" then
        return false, "PetData.level must be a number"
    end
    
    -- Add more validation as needed
    
    return true, nil
end

function ClientTypes.ValidatePlayerData(data: any): (boolean, string?)
    if type(data) ~= "table" then
        return false, "PlayerData must be a table"
    end
    
    if type(data.userId) ~= "number" then
        return false, "PlayerData.userId must be a number"
    end
    
    if type(data.currencies) ~= "table" then
        return false, "PlayerData.currencies must be a table"
    end
    
    -- Add more validation as needed
    
    return true, nil
end

-- Export the module
return ClientTypes