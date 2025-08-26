--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - CASE SYSTEM MODULE                            ║
    ║                         Handles egg/case opening mechanics                           ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local CaseSystem = {}

-- Services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Configuration = require(script.Parent.Configuration)
local DataStoreModule = require(script.Parent.DataStoreModule)
local PetSystem = require(script.Parent.PetSystem)
local PetDatabase = require(script.Parent.PetDatabase)

-- ========================================
-- EGG/CASE DEFINITIONS
-- ========================================
CaseSystem.EggCases = {
    ["basic_egg"] = {
        name = "Basic Egg",
        description = "A simple egg with common pets",
        price = 100,
        currency = "coins",
        icon = "rbxassetid://10000001001",
        dropRates = {
            ["hello_kitty_classic"] = 30,
            ["my_melody_basic"] = 25,
            ["cinnamoroll_basic"] = 20,
            ["pompompurin_basic"] = 10,
            ["keroppi_basic"] = 8,
            ["pochacco_basic"] = 5,
            ["tuxedosam_basic"] = 2
        },
        pitySystem = {
            enabled = true,
            threshold = 10,
            guaranteedRarity = Configuration.RARITY.UNCOMMON
        }
    },
    
    ["rare_egg"] = {
        name = "Rare Egg",
        description = "Contains rarer Sanrio friends!",
        price = 500,
        currency = "coins",
        icon = "rbxassetid://10000001002",
        dropRates = {
            ["kuromi_basic"] = 25,
            ["badtz_maru_basic"] = 20,
            ["chococat_basic"] = 20,
            ["my_melody_sweet"] = 15,
            ["pompompurin_chef"] = 10,
            ["pochacco_athlete"] = 5,
            ["tuxedosam_gentleman"] = 3,
            ["keroppi_ninja"] = 2
        },
        pitySystem = {
            enabled = true,
            threshold = 8,
            guaranteedRarity = Configuration.RARITY.RARE
        }
    },
    
    ["premium_egg"] = {
        name = "Premium Egg",
        description = "Premium pets with better chances!",
        price = 100,
        currency = "gems",
        icon = "rbxassetid://10000001003",
        dropRates = {
            ["hello_kitty_angel"] = 20,
            ["kuromi_devil"] = 18,
            ["cinnamoroll_sky"] = 15,
            ["badtz_maru_rebel"] = 12,
            ["chococat_wise"] = 10,
            ["keroppi_ninja"] = 10,
            ["my_melody_sweet"] = 8,
            ["pochacco_athlete"] = 5,
            ["hello_kitty_goddess"] = 2
        },
        pitySystem = {
            enabled = true,
            threshold = 5,
            guaranteedRarity = Configuration.RARITY.EPIC
        }
    },
    
    ["legendary_egg"] = {
        name = "Legendary Egg",
        description = "The rarest pets await!",
        price = 500,
        currency = "gems",
        icon = "rbxassetid://10000001004",
        dropRates = {
            ["hello_kitty_goddess"] = 15,
            ["golden_cinnamoroll"] = 10,
            ["shadow_kuromi"] = 8,
            ["kuromi_devil"] = 20,
            ["badtz_maru_rebel"] = 15,
            ["chococat_wise"] = 12,
            ["cinnamoroll_sky"] = 10,
            ["keroppi_ninja"] = 8,
            ["hello_kitty_rainbow"] = 2
        },
        pitySystem = {
            enabled = true,
            threshold = 3,
            guaranteedRarity = Configuration.RARITY.LEGENDARY
        }
    },
    
    ["event_egg"] = {
        name = "Event Egg",
        description = "Limited time special pets!",
        price = 1000,
        currency = "eventTokens",
        icon = "rbxassetid://10000001005",
        hidden = true, -- Only show during events
        dropRates = {
            ["hello_kitty_rainbow"] = 25,
            ["golden_cinnamoroll"] = 25,
            ["shadow_kuromi"] = 25,
            ["hello_kitty_goddess"] = 25
        },
        limitedTime = {
            startTime = 0,
            endTime = 0
        }
    },
    
    ["mythical_egg"] = {
        name = "Mythical Egg",
        description = "Contains the most powerful pets!",
        price = 1000,
        currency = "gems",
        icon = "rbxassetid://10000001006",
        dropRates = {
            ["hello_kitty_rainbow"] = 5,
            ["golden_cinnamoroll"] = 15,
            ["shadow_kuromi"] = 15,
            ["hello_kitty_goddess"] = 25,
            ["kuromi_devil"] = 20,
            ["badtz_maru_rebel"] = 10,
            ["chococat_wise"] = 10
        },
        pitySystem = {
            enabled = true,
            threshold = 2,
            guaranteedRarity = Configuration.RARITY.MYTHICAL
        }
    }
}

-- ========================================
-- GET SHOP DATA FOR CLIENT
-- ========================================
function CaseSystem:GetShopEggs()
    local shopData = {}
    
    for eggId, eggData in pairs(self.EggCases) do
        -- Don't send hidden eggs
        if not eggData.hidden then
            table.insert(shopData, {
                id = eggId,
                name = eggData.name,
                description = eggData.description,
                price = eggData.price,
                currency = eggData.currency,
                icon = eggData.icon,
                -- Calculate average rarity for display
                averageRarity = self:CalculateAverageRarity(eggData.dropRates),
                -- Show if it's limited time
                limitedTime = eggData.limitedTime,
                -- Special effects
                effects = eggData.effects
            })
        end
    end
    
    -- Sort by price (cheapest first)
    table.sort(shopData, function(a, b)
        if a.currency == b.currency then
            return a.price < b.price
        else
            -- Coins first, then gems
            return a.currency == "coins"
        end
    end)
    
    return shopData
end

function CaseSystem:CalculateAverageRarity(dropRates)
    local totalWeight = 0
    local rarityScore = 0
    
    for petId, weight in pairs(dropRates) do
        local petData = PetDatabase:GetPet(petId)
        if petData then
            totalWeight = totalWeight + weight
            rarityScore = rarityScore + (petData.rarity * weight)
        end
    end
    
    if totalWeight > 0 then
        return math.floor(rarityScore / totalWeight)
    end
    
    return 1
end

-- ========================================
-- WEIGHTED RANDOM SELECTION
-- ========================================
function CaseSystem:GetWeightedRandomPet(eggType, player)
    local egg = self.EggCases[eggType]
    if not egg then return nil end
    
    local playerData = nil
    local luckMultiplier = 1
    
    -- Get player data for luck calculation
    if player and player.UserId then
        playerData = DataStoreModule.PlayerData[player.UserId]
    end
    
    -- Calculate luck multiplier
    if playerData then
        -- Gamepass luck
        if playerData.ownedGamepasses[Configuration.GAMEPASS_IDS.LUCKY_BOOST] then
            luckMultiplier = luckMultiplier * 1.25
        end
        
        -- Group bonus
        if playerData.inGroup then
            luckMultiplier = luckMultiplier * Configuration.CONFIG.GROUP_BONUS_MULTIPLIER
        end
        
        -- Pet luck bonuses
        local petLuckBonus = PetSystem:CalculateTotalBonus(player, "luck")
        luckMultiplier = luckMultiplier * petLuckBonus
    end
    
    -- Calculate modified weights with proper luck system
    local modifiedDropRates = {}
    local modifiedTotalWeight = 0
    
    for petName, weight in pairs(egg.dropRates) do
        local petData = PetDatabase:GetPet(petName)
        local rarity = petData and petData.rarity or 1
        
        -- Higher luck increases chance for rarer pets
        local luckBoost = 1 + ((luckMultiplier - 1) * (rarity - 1) / 5)
        modifiedDropRates[petName] = weight * luckBoost
        modifiedTotalWeight = modifiedTotalWeight + (weight * luckBoost)
    end
    
    -- Select random pet
    local random = math.random() * modifiedTotalWeight
    local currentWeight = 0
    
    for petName, weight in pairs(modifiedDropRates) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return petName
        end
    end
    
    -- Fallback
    for petName, _ in pairs(egg.dropRates) do
        return petName
    end
end

-- ========================================
-- PITY SYSTEM
-- ========================================
function CaseSystem:CheckPitySystem(player, eggType)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return nil end
    
    local egg = self.EggCases[eggType]
    if not egg or not egg.pitySystem or not egg.pitySystem.enabled then
        return nil
    end
    
    -- Initialize egg statistics if needed
    if not playerData.statistics.eggStatistics then
        playerData.statistics.eggStatistics = {}
    end
    
    if not playerData.statistics.eggStatistics[eggType] then
        playerData.statistics.eggStatistics[eggType] = {
            opened = 0,
            sinceLastRare = 0
        }
    end
    
    local eggStats = playerData.statistics.eggStatistics[eggType]
    eggStats.sinceLastRare = eggStats.sinceLastRare + 1
    
    -- Check if pity threshold reached
    if eggStats.sinceLastRare >= egg.pitySystem.threshold then
        -- Get a guaranteed rare pet
        local rarePets = {}
        for petName, _ in pairs(egg.dropRates) do
            local petData = PetDatabase:GetPet(petName)
            if petData and petData.rarity >= egg.pitySystem.guaranteedRarity then
                table.insert(rarePets, petName)
            end
        end
        
        if #rarePets > 0 then
            eggStats.sinceLastRare = 0
            return rarePets[math.random(1, #rarePets)]
        end
    end
    
    return nil
end

-- ========================================
-- OPEN CASE/EGG
-- ========================================
function CaseSystem:OpenCase(player, eggType, hatchCount)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then
        return {success = false, error = "No player data"}
    end
    
    local egg = self.EggCases[eggType]
    if not egg then
        return {success = false, error = "Invalid egg type"}
    end
    
    -- Check if egg is available (for limited time eggs)
    if egg.limitedTime then
        local currentTime = os.time()
        if currentTime < egg.limitedTime.startTime or currentTime > egg.limitedTime.endTime then
            return {success = false, error = "This egg is not available"}
        end
    end
    
    hatchCount = math.min(hatchCount or 1, 10) -- Max 10 at once
    local currencyType = string.lower(egg.currency)
    
    -- Check currency
    local totalCost = egg.price * hatchCount
    if playerData.currencies[currencyType] < totalCost then
        return {success = false, error = "Not enough " .. currencyType}
    end
    
    -- Check for instant hatch gamepass
    local instantHatch = playerData.ownedGamepasses[Configuration.GAMEPASS_IDS.INSTANT_HATCH]
    
    -- Deduct currency
    playerData.currencies[currencyType] = playerData.currencies[currencyType] - totalCost
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    local results = {}
    
    for i = 1, hatchCount do
        -- Check pity system first
        local pitypet = self:CheckPitySystem(player, eggType)
        local selectedPet = pitypet or self:GetWeightedRandomPet(eggType, player)
        
        if selectedPet then
            -- Create pet instance
            local petInstance = PetSystem:CreatePetInstance(selectedPet, 1, 0)
            
            if petInstance then
                -- Add to inventory
                local success, result = PetSystem:AddPetToInventory(player, petInstance)
                
                if success then
                    table.insert(results, {
                        pet = petInstance,
                        isNew = not playerData.petCollection[selectedPet]
                    })
                    
                    -- Update statistics
                    playerData.statistics.totalEggsOpened = 
                        (playerData.statistics.totalEggsOpened or 0) + 1
                    playerData.statistics.totalPetsHatched = 
                        (playerData.statistics.totalPetsHatched or 0) + 1
                    
                    local petData = PetDatabase:GetPet(selectedPet)
                    if petData then
                        if petData.rarity == Configuration.RARITY.LEGENDARY then
                            playerData.statistics.legendaryPetsFound = 
                                (playerData.statistics.legendaryPetsFound or 0) + 1
                        elseif petData.rarity == Configuration.RARITY.MYTHICAL then
                            playerData.statistics.mythicalPetsFound = 
                                (playerData.statistics.mythicalPetsFound or 0) + 1
                        elseif petData.rarity >= Configuration.RARITY.SECRET then
                            playerData.statistics.secretPetsFound = 
                                (playerData.statistics.secretPetsFound or 0) + 1
                        end
                        
                        -- Reset pity counter if rare pet obtained
                        if petData.rarity >= Configuration.RARITY.RARE then
                            if playerData.statistics.eggStatistics and 
                               playerData.statistics.eggStatistics[eggType] then
                                playerData.statistics.eggStatistics[eggType].sinceLastRare = 0
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Send results to client
    return {
        success = true,
        results = results,
        instantHatch = instantHatch,
        newBalance = playerData.currencies
    }
end

-- ========================================
-- GENERATE VISUAL SPINNER ITEMS
-- ========================================
function CaseSystem:GenerateCaseItems(eggType, winnerPet, player)
    local items = {}
    local egg = self.EggCases[eggType]
    
    if not egg then return items end
    
    -- Generate 100 items for visual spinner
    for i = 1, 100 do
        if i == 50 then
            -- Place winner at center
            items[i] = winnerPet
        elseif i >= 47 and i <= 53 and i ~= 50 then
            -- Place good pets near center for excitement
            local rarePets = {}
            for petName, _ in pairs(egg.dropRates) do
                local petData = PetDatabase:GetPet(petName)
                if petData and petData.rarity >= Configuration.RARITY.RARE then
                    table.insert(rarePets, petName)
                end
            end
            if #rarePets > 0 then
                items[i] = rarePets[math.random(1, #rarePets)]
            else
                items[i] = self:GetWeightedRandomPet(eggType, nil)
            end
        else
            -- Random pets for other positions
            items[i] = self:GetWeightedRandomPet(eggType, nil)
        end
    end
    
    return items
end

-- ========================================
-- GET SHOP DATA
-- ========================================
function CaseSystem:GetShopEggs()
    local eggs = {}
    
    for id, data in pairs(self.EggCases) do
        if not data.hidden then
            table.insert(eggs, {
                id = id,
                name = data.name,
                description = data.description,
                price = data.price,
                currency = data.currency,
                icon = data.icon
            })
        end
    end
    
    -- Sort by price
    table.sort(eggs, function(a, b)
        if a.currency == b.currency then
            return a.price < b.price
        else
            return a.currency == "coins"
        end
    end)
    
    return eggs
end

return CaseSystem