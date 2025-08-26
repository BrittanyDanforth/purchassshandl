--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                     SANRIO TYCOON - ACHIEVEMENT SYSTEM MODULE                        ║
    ║                        Tracks and rewards player accomplishments                     ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local AchievementSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")

-- Dependencies
local Configuration = require(script.Parent.Configuration)
local DataStoreModule = require(script.Parent.DataStoreModule)

-- ========================================
-- ACHIEVEMENT DEFINITIONS
-- ========================================
AchievementSystem.Achievements = {
    -- Pet Collection Achievements
    {
        id = "first_pet",
        name = "Pet Owner",
        description = "Hatch your first pet",
        icon = "🥚",
        badgeId = Configuration.BADGE_IDS.FIRST_PET,
        requirement = {type = "pets_hatched", value = 1},
        rewards = {coins = 500, gems = 10, title = "Pet Owner"},
        tier = "Bronze"
    },
    {
        id = "pet_collector_10",
        name = "Pet Collector",
        description = "Hatch 10 pets",
        icon = "🐣",
        requirement = {type = "pets_hatched", value = 10},
        rewards = {coins = 2000, gems = 25},
        tier = "Bronze"
    },
    {
        id = "pet_collector_50",
        name = "Pet Enthusiast",
        description = "Hatch 50 pets",
        icon = "🐾",
        requirement = {type = "pets_hatched", value = 50},
        rewards = {coins = 10000, gems = 100, title = "Pet Enthusiast"},
        tier = "Silver"
    },
    {
        id = "pet_collector_100",
        name = "Pet Master",
        description = "Hatch 100 pets",
        icon = "👑",
        requirement = {type = "pets_hatched", value = 100},
        rewards = {coins = 25000, gems = 250, title = "Pet Master"},
        tier = "Gold"
    },
    {
        id = "pet_collector_500",
        name = "Pet Legend",
        description = "Hatch 500 pets",
        icon = "🌟",
        requirement = {type = "pets_hatched", value = 500},
        rewards = {coins = 100000, gems = 1000, title = "Pet Legend"},
        tier = "Diamond"
    },
    
    -- Unique Pet Collection
    {
        id = "variety_5",
        name = "Variety Collector",
        description = "Collect 5 different pet types",
        icon = "🎨",
        requirement = {type = "unique_pets", value = 5},
        rewards = {coins = 3000, gems = 30},
        tier = "Bronze"
    },
    {
        id = "variety_20",
        name = "Diversity Master",
        description = "Collect 20 different pet types",
        icon = "🌈",
        requirement = {type = "unique_pets", value = 20},
        rewards = {coins = 15000, gems = 150, title = "Collector"},
        tier = "Silver"
    },
    {
        id = "variety_50",
        name = "Complete Collection",
        description = "Collect 50 different pet types",
        icon = "📚",
        requirement = {type = "unique_pets", value = 50},
        rewards = {coins = 50000, gems = 500, title = "Completionist"},
        tier = "Gold"
    },
    
    -- Rarity Achievements
    {
        id = "first_rare",
        name = "Rare Find",
        description = "Hatch your first rare pet",
        icon = "💎",
        requirement = {type = "rare_pet", value = 1},
        rewards = {coins = 5000, gems = 50},
        tier = "Bronze"
    },
    {
        id = "first_epic",
        name = "Epic Discovery",
        description = "Hatch your first epic pet",
        icon = "💜",
        requirement = {type = "epic_pet", value = 1},
        rewards = {coins = 10000, gems = 100},
        tier = "Silver"
    },
    {
        id = "first_legendary",
        name = "Legendary Tamer",
        description = "Hatch your first legendary pet",
        icon = "🔥",
        badgeId = Configuration.BADGE_IDS.LEGENDARY_PET,
        requirement = {type = "legendary_pet", value = 1},
        rewards = {coins = 25000, gems = 250, title = "Legendary"},
        tier = "Gold"
    },
    {
        id = "first_mythical",
        name = "Mythical Master",
        description = "Hatch your first mythical pet",
        icon = "✨",
        badgeId = Configuration.BADGE_IDS.MYTHICAL_PET,
        requirement = {type = "mythical_pet", value = 1},
        rewards = {coins = 50000, gems = 500, title = "Mythical"},
        tier = "Diamond"
    },
    {
        id = "first_secret",
        name = "Secret Keeper",
        description = "Hatch your first secret pet",
        icon = "🔮",
        badgeId = Configuration.BADGE_IDS.SECRET_PET,
        requirement = {type = "secret_pet", value = 1},
        rewards = {coins = 100000, gems = 1000, title = "Secret Keeper"},
        tier = "Diamond"
    },
    
    -- Trading Achievements
    {
        id = "first_trade",
        name = "First Trade",
        description = "Complete your first trade",
        icon = "🤝",
        badgeId = Configuration.BADGE_IDS.FIRST_TRADE,
        requirement = {type = "trades_completed", value = 1},
        rewards = {coins = 1000, gems = 20},
        tier = "Bronze"
    },
    {
        id = "trader_10",
        name = "Active Trader",
        description = "Complete 10 trades",
        icon = "💱",
        requirement = {type = "trades_completed", value = 10},
        rewards = {coins = 5000, gems = 50, title = "Trader"},
        tier = "Bronze"
    },
    {
        id = "trader_50",
        name = "Expert Trader",
        description = "Complete 50 trades",
        icon = "📊",
        requirement = {type = "trades_completed", value = 50},
        rewards = {coins = 20000, gems = 200, title = "Expert Trader"},
        tier = "Silver"
    },
    {
        id = "trader_100",
        name = "Master Merchant",
        description = "Complete 100 trades",
        icon = "🏪",
        requirement = {type = "trades_completed", value = 100},
        rewards = {coins = 50000, gems = 500, title = "Master Merchant"},
        tier = "Gold"
    },
    
    -- Battle Achievements
    {
        id = "first_battle_win",
        name = "First Victory",
        description = "Win your first battle",
        icon = "⚔️",
        badgeId = Configuration.BADGE_IDS.FIRST_BATTLE,
        requirement = {type = "battles_won", value = 1},
        rewards = {coins = 1500, gems = 30},
        tier = "Bronze"
    },
    {
        id = "warrior_10",
        name = "Warrior",
        description = "Win 10 battles",
        icon = "🗡️",
        requirement = {type = "battles_won", value = 10},
        rewards = {coins = 7500, gems = 75, title = "Warrior"},
        tier = "Bronze"
    },
    {
        id = "champion_50",
        name = "Champion",
        description = "Win 50 battles",
        icon = "🏆",
        requirement = {type = "battles_won", value = 50},
        rewards = {coins = 30000, gems = 300, title = "Champion"},
        tier = "Silver"
    },
    {
        id = "legend_100",
        name = "Battle Legend",
        description = "Win 100 battles",
        icon = "👑",
        requirement = {type = "battles_won", value = 100},
        rewards = {coins = 75000, gems = 750, title = "Battle Legend"},
        tier = "Gold"
    },
    {
        id = "streak_10",
        name = "Unstoppable",
        description = "Win 10 battles in a row",
        icon = "🔥",
        requirement = {type = "battle_streak", value = 10},
        rewards = {coins = 25000, gems = 250, title = "Unstoppable"},
        tier = "Gold"
    },
    
    -- Currency Achievements
    {
        id = "coins_1000",
        name = "Penny Pincher",
        description = "Collect 1,000 coins",
        icon = "💰",
        requirement = {type = "coins", value = 1000},
        rewards = {gems = 10},
        tier = "Bronze"
    },
    {
        id = "coins_10000",
        name = "Coin Collector",
        description = "Collect 10,000 coins",
        icon = "💵",
        requirement = {type = "coins", value = 10000},
        rewards = {gems = 50},
        tier = "Bronze"
    },
    {
        id = "coins_100000",
        name = "Wealthy",
        description = "Collect 100,000 coins",
        icon = "💸",
        requirement = {type = "coins", value = 100000},
        rewards = {gems = 200, title = "Wealthy"},
        tier = "Silver"
    },
    {
        id = "coins_1000000",
        name = "Millionaire",
        description = "Collect 1,000,000 coins",
        icon = "🤑",
        badgeId = Configuration.BADGE_IDS.RICH_PLAYER,
        requirement = {type = "coins", value = 1000000},
        rewards = {gems = 1000, title = "Millionaire"},
        tier = "Gold"
    },
    {
        id = "coins_10000000",
        name = "Tycoon",
        description = "Collect 10,000,000 coins",
        icon = "👑",
        requirement = {type = "coins", value = 10000000},
        rewards = {gems = 5000, title = "Tycoon"},
        tier = "Diamond"
    },
    
    -- Daily Login Achievements
    {
        id = "streak_7",
        name = "Week Warrior",
        description = "Login for 7 days in a row",
        icon = "📅",
        requirement = {type = "login_streak", value = 7},
        rewards = {coins = 10000, gems = 100, title = "Dedicated"},
        tier = "Bronze"
    },
    {
        id = "streak_30",
        name = "Monthly Master",
        description = "Login for 30 days in a row",
        icon = "📆",
        requirement = {type = "login_streak", value = 30},
        rewards = {coins = 50000, gems = 500, title = "Loyal Player"},
        tier = "Gold"
    },
    
    -- Special Achievements
    {
        id = "hello_kitty_all",
        name = "Hello Kitty Fan",
        description = "Collect all Hello Kitty variants",
        icon = "🎀",
        requirement = {type = "specific_collection", collection = "hello_kitty"},
        rewards = {coins = 100000, gems = 1000, title = "Hello Kitty Fan"},
        tier = "Diamond"
    },
    {
        id = "shiny_pet",
        name = "Shiny Hunter",
        description = "Hatch a shiny pet",
        icon = "✨",
        requirement = {type = "shiny_pet", value = 1},
        rewards = {coins = 50000, gems = 500, title = "Shiny Hunter"},
        tier = "Gold"
    },
    {
        id = "max_level_pet",
        name = "Max Power",
        description = "Level a pet to max level (100)",
        icon = "💪",
        requirement = {type = "max_level_pet", value = 1},
        rewards = {coins = 100000, gems = 1000, title = "Max Power"},
        tier = "Diamond"
    }
}

-- ========================================
-- CHECK ACHIEVEMENTS
-- ========================================
function AchievementSystem:CheckAchievements(player)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return end
    
    -- Ensure statistics exists
    if not playerData.statistics then
        playerData.statistics = DataStoreModule:GetDefaultPlayerData().statistics
    end
    
    -- Ensure achievements table exists
    if not playerData.achievements then
        playerData.achievements = {}
    end
    
    for _, achievement in ipairs(self.Achievements) do
        if not playerData.achievements[achievement.id] then
            local completed = false
            
            -- Check different achievement types
            if achievement.requirement.type == "pets_hatched" then
                completed = (playerData.statistics.totalPetsHatched or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "unique_pets" then
                local uniqueCount = 0
                for _ in pairs(playerData.petCollection or {}) do
                    uniqueCount = uniqueCount + 1
                end
                completed = uniqueCount >= achievement.requirement.value
                
            elseif achievement.requirement.type == "rare_pet" then
                local count = 0
                for _, petData in pairs(playerData.pets or {}) do
                    if petData.rarity and petData.rarity >= Configuration.RARITY.RARE then
                        count = count + 1
                    end
                end
                completed = count >= achievement.requirement.value
                
            elseif achievement.requirement.type == "epic_pet" then
                local count = 0
                for _, petData in pairs(playerData.pets or {}) do
                    if petData.rarity and petData.rarity >= Configuration.RARITY.EPIC then
                        count = count + 1
                    end
                end
                completed = count >= achievement.requirement.value
                
            elseif achievement.requirement.type == "legendary_pet" then
                local count = 0
                for _, petData in pairs(playerData.pets or {}) do
                    if petData.rarity and petData.rarity >= Configuration.RARITY.LEGENDARY then
                        count = count + 1
                    end
                end
                completed = count >= achievement.requirement.value
                
            elseif achievement.requirement.type == "mythical_pet" then
                completed = (playerData.statistics.mythicalPetsFound or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "secret_pet" then
                completed = (playerData.statistics.secretPetsFound or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "trades_completed" then
                completed = (playerData.statistics.tradingStats and playerData.statistics.tradingStats.tradesCompleted or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "battles_won" then
                completed = (playerData.statistics.battleStats and playerData.statistics.battleStats.wins or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "battle_streak" then
                completed = (playerData.statistics.battleStats and playerData.statistics.battleStats.highestWinStreak or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "coins" then
                completed = (playerData.currencies.coins or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "login_streak" then
                completed = (playerData.dailyReward and playerData.dailyReward.streak or 0) >= achievement.requirement.value
                
            elseif achievement.requirement.type == "shiny_pet" then
                local count = 0
                for _, petData in pairs(playerData.pets or {}) do
                    if petData.shiny then
                        count = count + 1
                    end
                end
                completed = count >= achievement.requirement.value
                
            elseif achievement.requirement.type == "max_level_pet" then
                local count = 0
                for _, petData in pairs(playerData.pets or {}) do
                    if petData.level >= 100 then
                        count = count + 1
                    end
                end
                completed = count >= achievement.requirement.value
                
            elseif achievement.requirement.type == "specific_collection" then
                if achievement.requirement.collection == "hello_kitty" then
                    local helloKittyPets = {"hello_kitty_classic", "hello_kitty_angel", "hello_kitty_goddess", "hello_kitty_rainbow"}
                    local hasAll = true
                    for _, petId in ipairs(helloKittyPets) do
                        if not playerData.petCollection[petId] then
                            hasAll = false
                            break
                        end
                    end
                    completed = hasAll
                end
            end
            
            -- Award achievement if completed
            if completed then
                self:AwardAchievement(player, achievement)
            end
        end
    end
end

-- ========================================
-- AWARD ACHIEVEMENT
-- ========================================
function AchievementSystem:AwardAchievement(player, achievement)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return end
    
    -- Mark as completed
    playerData.achievements[achievement.id] = {
        unlockedAt = os.time(),
        claimed = false
    }
    
    -- Give rewards
    if achievement.rewards.coins then
        playerData.currencies.coins = (playerData.currencies.coins or 0) + achievement.rewards.coins
    end
    
    if achievement.rewards.gems then
        playerData.currencies.gems = (playerData.currencies.gems or 0) + achievement.rewards.gems
    end
    
    if achievement.rewards.title then
        if not playerData.titles then
            playerData.titles = {owned = {}, equipped = "Newbie"}
        end
        table.insert(playerData.titles.owned, achievement.rewards.title)
    end
    
    -- Award badge if applicable
    if achievement.badgeId then
        pcall(function()
            BadgeService:AwardBadge(player.UserId, achievement.badgeId)
        end)
    end
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Notify player
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("AchievementUnlocked") then
        RemoteEvents.AchievementUnlocked:FireClient(player, achievement)
    end
    
    if RemoteEvents and RemoteEvents:FindFirstChild("NotificationSent") then
        RemoteEvents.NotificationSent:FireClient(player, {
            type = "achievement",
            title = "Achievement Unlocked!",
            message = achievement.name .. ": " .. achievement.description,
            duration = 10,
            icon = achievement.icon
        })
    end
end

-- ========================================
-- GET PLAYER ACHIEVEMENTS
-- ========================================
function AchievementSystem:GetPlayerAchievements(player)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return {} end
    
    local achievements = {}
    
    for _, achievement in ipairs(self.Achievements) do
        local status = "locked"
        local progress = 0
        local maxProgress = achievement.requirement.value or 1
        
        if playerData.achievements[achievement.id] then
            status = "completed"
            progress = maxProgress
        else
            -- Calculate progress
            if achievement.requirement.type == "pets_hatched" then
                progress = playerData.statistics.totalPetsHatched or 0
            elseif achievement.requirement.type == "unique_pets" then
                local count = 0
                for _ in pairs(playerData.petCollection or {}) do
                    count = count + 1
                end
                progress = count
            elseif achievement.requirement.type == "trades_completed" then
                progress = playerData.statistics.tradingStats and playerData.statistics.tradingStats.tradesCompleted or 0
            elseif achievement.requirement.type == "battles_won" then
                progress = playerData.statistics.battleStats and playerData.statistics.battleStats.wins or 0
            elseif achievement.requirement.type == "coins" then
                progress = playerData.currencies.coins or 0
            elseif achievement.requirement.type == "login_streak" then
                progress = playerData.dailyReward and playerData.dailyReward.streak or 0
            end
            
            progress = math.min(progress, maxProgress)
        end
        
        table.insert(achievements, {
            id = achievement.id,
            name = achievement.name,
            description = achievement.description,
            icon = achievement.icon,
            tier = achievement.tier,
            status = status,
            progress = progress,
            maxProgress = maxProgress,
            rewards = achievement.rewards,
            unlockedAt = playerData.achievements[achievement.id] and playerData.achievements[achievement.id].unlockedAt
        })
    end
    
    return achievements
end

return AchievementSystem