-- ========================================
-- REBIRTH SYSTEM MODULE
-- Complete prestige/rebirth system with rewards
-- ========================================

local RebirthSystem = {}

-- Dependencies
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local REBIRTH_VERSION = 1
local BASE_REBIRTH_COST = 100000 -- 100k coins for first rebirth
local REBIRTH_COST_MULTIPLIER = 2.5 -- Cost increases by 2.5x each rebirth
local MAX_REBIRTHS = 100

-- Rebirth rewards
local REBIRTH_REWARDS = {
    -- Multipliers
    COIN_MULTIPLIER = 0.1,      -- +10% coins per rebirth
    GEM_MULTIPLIER = 0.05,      -- +5% gems per rebirth
    EXP_MULTIPLIER = 0.15,      -- +15% pet exp per rebirth
    LUCK_MULTIPLIER = 0.01,     -- +1% luck per rebirth
    
    -- Flat bonuses
    STORAGE_BONUS = 5,          -- +5 pet storage per rebirth
    EQUIP_BONUS = 0.2,          -- +1 equip slot every 5 rebirths
    
    -- Special rewards at milestones
    MILESTONES = {
        [1] = {
            title = "First Step",
            rewards = {
                gems = 100,
                petSlots = 10,
                exclusivePet = "rebirth_pet_1"
            }
        },
        [5] = {
            title = "Rising Star",
            rewards = {
                gems = 500,
                petSlots = 25,
                equipSlot = 1,
                exclusivePet = "rebirth_pet_5"
            }
        },
        [10] = {
            title = "Dedicated",
            rewards = {
                gems = 1000,
                petSlots = 50,
                equipSlot = 1,
                exclusivePet = "rebirth_pet_10",
                exclusiveTitle = "Reborn"
            }
        },
        [25] = {
            title = "Master",
            rewards = {
                gems = 5000,
                petSlots = 100,
                equipSlot = 1,
                exclusivePet = "rebirth_pet_25",
                exclusiveTitle = "Master",
                aura = "rebirth_aura_1"
            }
        },
        [50] = {
            title = "Legend",
            rewards = {
                gems = 10000,
                petSlots = 200,
                equipSlot = 2,
                exclusivePet = "rebirth_pet_50",
                exclusiveTitle = "Legend",
                aura = "rebirth_aura_2"
            }
        },
        [75] = {
            title = "Mythical",
            rewards = {
                gems = 25000,
                petSlots = 300,
                equipSlot = 2,
                exclusivePet = "rebirth_pet_75",
                exclusiveTitle = "Mythical",
                aura = "rebirth_aura_3"
            }
        },
        [100] = {
            title = "Godly",
            rewards = {
                gems = 100000,
                petSlots = 500,
                equipSlot = 3,
                exclusivePet = "rebirth_pet_100",
                exclusiveTitle = "Godly",
                aura = "rebirth_aura_godly",
                specialEffect = "rebirth_effect_godly"
            }
        }
    }
}

-- Stats that reset on rebirth
local RESET_STATS = {
    "coins",
    "level",
    "experience",
    "totalEggsOpened",
    "totalPetsHatched"
}

-- Stats that are kept
local KEEP_STATS = {
    "gems",
    "rebirths",
    "totalRebirths",
    "bestPets",
    "achievements",
    "titles",
    "auras",
    "gamepasses"
}

-- Initialize
function RebirthSystem:Init()
    self.Configuration = _G.Configuration
    self.DataStoreModule = _G.DataStoreModule
    self.PetSystem = _G.PetSystem
    self.AchievementSystem = _G.AchievementSystem
    
    -- Track rebirth streaks
    self.RebirthStreaks = {}
    
    print("[RebirthSystem] Initialized")
end

-- ========================================
-- REBIRTH FUNCTIONS
-- ========================================

function RebirthSystem:CanRebirth(player)
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return false, "Player data not found"
    end
    
    local rebirths = playerData.statistics.rebirths or 0
    
    -- Check max rebirths
    if rebirths >= MAX_REBIRTHS then
        return false, "Maximum rebirths reached"
    end
    
    -- Calculate cost
    local cost = self:GetRebirthCost(rebirths)
    
    -- Check currency
    if playerData.currencies.coins < cost then
        return false, "Need " .. cost .. " coins to rebirth"
    end
    
    -- Could add level requirements
    local requiredLevel = 50 + (rebirths * 10)
    if playerData.level < requiredLevel then
        return false, "Need level " .. requiredLevel .. " to rebirth"
    end
    
    return true, cost
end

function RebirthSystem:PerformRebirth(player)
    local canRebirth, costOrError = self:CanRebirth(player)
    if not canRebirth then
        return {success = false, error = costOrError}
    end
    
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    local cost = costOrError
    local currentRebirths = playerData.statistics.rebirths or 0
    local newRebirths = currentRebirths + 1
    
    -- Store pre-rebirth data for comparison
    local preRebirthData = {
        coins = playerData.currencies.coins,
        level = playerData.level,
        pets = #playerData.pets
    }
    
    -- Reset stats
    for _, stat in ipairs(RESET_STATS) do
        if stat == "coins" then
            playerData.currencies.coins = 0
        elseif stat == "level" then
            playerData.level = 1
        elseif stat == "experience" then
            playerData.experience = 0
        elseif playerData.statistics[stat] then
            playerData.statistics[stat] = 0
        end
    end
    
    -- Reset non-exclusive pets (keep rebirth rewards)
    local keptPets = {}
    for petId, pet in pairs(playerData.pets) do
        if pet.exclusive or pet.rebirth then
            keptPets[petId] = pet
        end
    end
    playerData.pets = keptPets
    
    -- Update rebirth stats
    playerData.statistics.rebirths = newRebirths
    playerData.statistics.totalRebirths = (playerData.statistics.totalRebirths or 0) + 1
    playerData.statistics.lastRebirthTime = os.time()
    
    -- Calculate and apply multipliers
    local multipliers = self:CalculateMultipliers(newRebirths)
    playerData.multipliers = playerData.multipliers or {}
    
    for key, value in pairs(multipliers) do
        playerData.multipliers[key] = value
    end
    
    -- Apply storage bonus
    local baseStorage = 500
    local bonusStorage = newRebirths * REBIRTH_REWARDS.STORAGE_BONUS
    playerData.maxPetStorage = baseStorage + bonusStorage
    
    -- Apply equip slot bonus
    local baseEquipSlots = 6
    local bonusEquipSlots = math.floor(newRebirths * REBIRTH_REWARDS.EQUIP_BONUS)
    playerData.maxEquipSlots = baseEquipSlots + bonusEquipSlots
    
    -- Check for milestone rewards
    local milestone = REBIRTH_REWARDS.MILESTONES[newRebirths]
    if milestone then
        self:GrantMilestoneRewards(player, playerData, milestone)
    end
    
    -- Track rebirth streak
    local lastRebirth = self.RebirthStreaks[player.UserId] or 0
    if os.time() - lastRebirth < 86400 then -- Within 24 hours
        playerData.statistics.rebirthStreak = (playerData.statistics.rebirthStreak or 0) + 1
    else
        playerData.statistics.rebirthStreak = 1
    end
    self.RebirthStreaks[player.UserId] = os.time()
    
    -- Award achievements
    if self.AchievementSystem then
        self.AchievementSystem:CheckRebirthAchievements(player, newRebirths)
    end
    
    -- Fire rebirth effect
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.RebirthPerformed:FireClient(player, {
        newRebirths = newRebirths,
        multipliers = multipliers,
        milestone = milestone,
        preRebirthData = preRebirthData
    })
    
    -- Notify all players of high rebirth milestones
    if milestone and newRebirths >= 10 then
        RemoteEvents.GlobalAnnouncement:FireAllClients({
            type = "rebirth",
            playerName = player.Name,
            rebirths = newRebirths,
            title = milestone.title
        })
    end
    
    -- Save data
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    
    return {
        success = true,
        newRebirths = newRebirths,
        multipliers = multipliers,
        milestone = milestone,
        rewards = milestone and milestone.rewards
    }
end

function RebirthSystem:GetRebirthCost(rebirths)
    return math.floor(BASE_REBIRTH_COST * (REBIRTH_COST_MULTIPLIER ^ rebirths))
end

function RebirthSystem:CalculateMultipliers(rebirths)
    return {
        coins = 1 + (rebirths * REBIRTH_REWARDS.COIN_MULTIPLIER),
        gems = 1 + (rebirths * REBIRTH_REWARDS.GEM_MULTIPLIER),
        experience = 1 + (rebirths * REBIRTH_REWARDS.EXP_MULTIPLIER),
        luck = 1 + (rebirths * REBIRTH_REWARDS.LUCK_MULTIPLIER)
    }
end

function RebirthSystem:GrantMilestoneRewards(player, playerData, milestone)
    local rewards = milestone.rewards
    
    -- Grant gems
    if rewards.gems then
        playerData.currencies.gems = (playerData.currencies.gems or 0) + rewards.gems
    end
    
    -- Grant pet slots
    if rewards.petSlots then
        playerData.maxPetStorage = playerData.maxPetStorage + rewards.petSlots
    end
    
    -- Grant equip slots
    if rewards.equipSlot then
        playerData.maxEquipSlots = playerData.maxEquipSlots + rewards.equipSlot
    end
    
    -- Grant exclusive pet
    if rewards.exclusivePet and self.PetSystem then
        local petInstance = self.PetSystem:CreatePetInstance(rewards.exclusivePet, 1, 0)
        if petInstance then
            petInstance.exclusive = true
            petInstance.rebirth = true
            petInstance.obtainedFrom = "rebirth_" .. playerData.statistics.rebirths
            self.PetSystem:AddPetToInventory(player, petInstance)
        end
    end
    
    -- Grant title
    if rewards.exclusiveTitle then
        playerData.titles = playerData.titles or {}
        if not table.find(playerData.titles, rewards.exclusiveTitle) then
            table.insert(playerData.titles, rewards.exclusiveTitle)
        end
        
        -- Auto-equip new title
        playerData.equippedTitle = rewards.exclusiveTitle
    end
    
    -- Grant aura
    if rewards.aura then
        playerData.auras = playerData.auras or {}
        if not table.find(playerData.auras, rewards.aura) then
            table.insert(playerData.auras, rewards.aura)
        end
        
        -- Auto-equip new aura
        playerData.equippedAura = rewards.aura
    end
    
    -- Grant special effect
    if rewards.specialEffect then
        playerData.specialEffects = playerData.specialEffects or {}
        if not table.find(playerData.specialEffects, rewards.specialEffect) then
            table.insert(playerData.specialEffects, rewards.specialEffect)
        end
    end
end

-- ========================================
-- REBIRTH SHOP
-- ========================================

function RebirthSystem:GetRebirthShop(player)
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    local rebirths = playerData.statistics.rebirths or 0
    
    -- Shop items that can be purchased with rebirth tokens
    local shopItems = {
        {
            id = "instant_hatch",
            name = "Instant Hatch",
            description = "Eggs open instantly",
            cost = 5,
            type = "permanent",
            owned = playerData.rebirthUpgrades and playerData.rebirthUpgrades.instantHatch
        },
        {
            id = "auto_collect",
            name = "Auto Collect",
            description = "Automatically collect currency",
            cost = 10,
            type = "permanent",
            owned = playerData.rebirthUpgrades and playerData.rebirthUpgrades.autoCollect
        },
        {
            id = "double_eggs",
            name = "Double Eggs",
            description = "25% chance to get 2 pets from eggs",
            cost = 15,
            type = "permanent",
            owned = playerData.rebirthUpgrades and playerData.rebirthUpgrades.doubleEggs
        },
        {
            id = "lucky_boost",
            name = "Lucky Boost",
            description = "+10% base luck",
            cost = 20,
            type = "permanent",
            owned = playerData.rebirthUpgrades and playerData.rebirthUpgrades.luckyBoost
        },
        {
            id = "mega_magnet",
            name = "Mega Magnet",
            description = "Larger collection radius",
            cost = 8,
            type = "permanent",
            owned = playerData.rebirthUpgrades and playerData.rebirthUpgrades.megaMagnet
        },
        {
            id = "pet_mastery",
            name = "Pet Mastery",
            description = "Pets gain +50% more experience",
            cost = 25,
            type = "permanent",
            owned = playerData.rebirthUpgrades and playerData.rebirthUpgrades.petMastery
        }
    }
    
    -- Calculate rebirth tokens (1 per rebirth)
    local rebirthTokens = rebirths - (playerData.statistics.rebirthTokensSpent or 0)
    
    return {
        success = true,
        items = shopItems,
        tokens = rebirthTokens,
        rebirths = rebirths
    }
end

function RebirthSystem:PurchaseRebirthItem(player, itemId)
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    -- Get shop data
    local shopData = self:GetRebirthShop(player)
    if not shopData.success then
        return shopData
    end
    
    -- Find item
    local item = nil
    for _, shopItem in ipairs(shopData.items) do
        if shopItem.id == itemId then
            item = shopItem
            break
        end
    end
    
    if not item then
        return {success = false, error = "Item not found"}
    end
    
    if item.owned then
        return {success = false, error = "Already owned"}
    end
    
    -- Check tokens
    if shopData.tokens < item.cost then
        return {success = false, error = "Not enough rebirth tokens"}
    end
    
    -- Purchase item
    playerData.rebirthUpgrades = playerData.rebirthUpgrades or {}
    playerData.rebirthUpgrades[itemId] = true
    
    -- Update spent tokens
    playerData.statistics.rebirthTokensSpent = (playerData.statistics.rebirthTokensSpent or 0) + item.cost
    
    -- Apply effects immediately
    self:ApplyRebirthUpgrade(player, playerData, itemId)
    
    -- Save
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Notify
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.RebirthItemPurchased:FireClient(player, itemId, item.name)
    
    return {
        success = true,
        item = item,
        tokensLeft = shopData.tokens - item.cost
    }
end

function RebirthSystem:ApplyRebirthUpgrade(player, playerData, upgradeId)
    -- Apply upgrade effects
    if upgradeId == "lucky_boost" then
        playerData.multipliers.luck = (playerData.multipliers.luck or 1) + 0.1
    elseif upgradeId == "pet_mastery" then
        playerData.multipliers.petExperience = (playerData.multipliers.petExperience or 1) + 0.5
    end
    
    -- Some upgrades might need client notification
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.RebirthUpgradeActivated:FireClient(player, upgradeId)
end

-- ========================================
-- LEADERBOARDS
-- ========================================

function RebirthSystem:GetRebirthLeaderboard()
    local leaderboard = {}
    
    -- In production, this would query DataStore
    -- For now, return current players
    for _, player in ipairs(Players:GetPlayers()) do
        local playerData = self.DataStoreModule:GetPlayerData(player)
        if playerData and playerData.statistics.rebirths then
            table.insert(leaderboard, {
                userId = player.UserId,
                username = player.Name,
                rebirths = playerData.statistics.rebirths,
                level = playerData.level,
                title = playerData.equippedTitle
            })
        end
    end
    
    -- Sort by rebirths
    table.sort(leaderboard, function(a, b)
        return a.rebirths > b.rebirths
    end)
    
    return leaderboard
end

-- ========================================
-- UTILITIES
-- ========================================

function RebirthSystem:GetRebirthInfo(player)
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    local rebirths = playerData.statistics.rebirths or 0
    local canRebirth, costOrError = self:CanRebirth(player)
    
    -- Find next milestone
    local nextMilestone = nil
    local nextMilestoneRebirths = nil
    
    for milestoneRebirths, milestone in pairs(REBIRTH_REWARDS.MILESTONES) do
        if milestoneRebirths > rebirths then
            if not nextMilestoneRebirths or milestoneRebirths < nextMilestoneRebirths then
                nextMilestone = milestone
                nextMilestoneRebirths = milestoneRebirths
            end
        end
    end
    
    return {
        success = true,
        currentRebirths = rebirths,
        canRebirth = canRebirth,
        rebirthCost = type(costOrError) == "number" and costOrError or self:GetRebirthCost(rebirths),
        errorMessage = type(costOrError) == "string" and costOrError or nil,
        multipliers = self:CalculateMultipliers(rebirths),
        nextMilestone = nextMilestone,
        nextMilestoneRebirths = nextMilestoneRebirths,
        maxRebirths = MAX_REBIRTHS,
        streak = playerData.statistics.rebirthStreak or 0
    }
end

function RebirthSystem:OnPlayerLeaving(player)
    -- Clean up streak tracking
    self.RebirthStreaks[player.UserId] = nil
end

return RebirthSystem