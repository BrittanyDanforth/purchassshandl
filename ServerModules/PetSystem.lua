--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                          SANRIO TYCOON - PET SYSTEM MODULE                           ║
    ║                        Handles all pet-related functionality                         ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local PetSystem = {}

-- Services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Dependencies
local Configuration = require(script.Parent.Configuration)
local DataStoreModule = require(script.Parent.DataStoreModule)
local PetDatabase = require(script.Parent.PetDatabase)

-- Mutex to prevent race conditions during equip/unequip operations
local EquipMutex = {}  -- [userId] = true when operation is in progress

-- ========================================
-- PET MANAGEMENT
-- ========================================

function PetSystem:CreatePetInstance(petId, level, xp)
    local petData = PetDatabase:GetPet(petId)
    if not petData then
        warn("[PetSystem] Unknown pet ID:", petId)
        return nil
    end
    
    local uniqueId = HttpService:GenerateGUID(false)
    
    local petInstance = {
        uniqueId = uniqueId,
        petId = petId,
        name = petData.name,
        rarity = petData.rarity,
        level = level or 1,
        xp = xp or 0,
        equipped = false,
        locked = false,
        obtained = os.time(),
        
        -- Calculate stats based on level
        stats = self:CalculatePetStats(petData, level or 1),
        
        -- Special attributes
        shiny = math.random(1, 1000) == 1, -- 0.1% chance
        variant = petData.variants and petData.variants[math.random(1, #petData.variants)] or nil,
        
        -- Battle stats
        battleStats = {
            wins = 0,
            losses = 0,
            battlesParticipated = 0
        }
    }
    
    return petInstance
end

function PetSystem:CalculatePetStats(petData, level)
    local stats = {}
    
    for stat, baseValue in pairs(petData.baseStats) do
        -- Linear growth with slight exponential curve
        stats[stat] = math.floor(baseValue * (1 + (level - 1) * 0.1 + (level - 1)^1.2 * 0.01))
    end
    
    return stats
end

function PetSystem:AddPetToInventory(player, petInstance)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return false, "No player data" end
    
    -- Check storage limit
    if playerData.petCount >= playerData.maxPetStorage then
        return false, "Pet storage full!"
    end
    
    -- Add to inventory
    playerData.pets[petInstance.uniqueId] = petInstance
    playerData.petCount = (playerData.petCount or 0) + 1
    
    -- Add to collection if new
    if not playerData.petCollection[petInstance.petId] then
        playerData.petCollection[petInstance.petId] = {
            firstObtained = os.time(),
            count = 1
        }
    else
        playerData.petCollection[petInstance.petId].count = 
            playerData.petCollection[petInstance.petId].count + 1
    end
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Fire pet updated event
    local RemoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents")
    local PetUpdated = RemoteEvents:FindFirstChild("PetUpdated")
    if PetUpdated then
        print("[PetSystem] Firing PetUpdated event to client for pet:", petInstance.uniqueId)
        PetUpdated:FireClient(player, {
            action = "added",
            petId = petInstance.uniqueId,
            pet = petInstance
        })
    else
        warn("[PetSystem] PetUpdated RemoteEvent not found!")
    end
    
    -- Also fire inventory updated event
    local InventoryUpdated = RemoteEvents:FindFirstChild("InventoryUpdated")
    if InventoryUpdated then
        print("[PetSystem] Firing InventoryUpdated event with", playerData.petCount, "pets")
        InventoryUpdated:FireClient(player, {
            pets = playerData.pets,
            petCount = playerData.petCount
        })
    else
        warn("[PetSystem] InventoryUpdated RemoteEvent not found!")
    end
    
    return true, petInstance
end

function PetSystem:RemovePetFromInventory(player, uniqueId)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return false, "No player data" end
    
    local pet = playerData.pets[uniqueId]
    if not pet then return false, "Pet not found" end
    
    -- Unequip if equipped
    if pet.equipped then
        self:UnequipPet(player, uniqueId)
    end
    
    -- Remove from inventory
    playerData.pets[uniqueId] = nil
    playerData.petCount = math.max(0, (playerData.petCount or 1) - 1)
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    return true
end

-- ========================================
-- PET EQUIPPING
-- ========================================

function PetSystem:EquipPet(player, uniqueId)
    -- MUTEX CHECK: Prevent concurrent operations
    if EquipMutex[player.UserId] then
        print("[PetSystem] BLOCKED concurrent equip attempt by", player.Name)
        return {success = false, error = "Please wait for the previous operation to complete."}
    end
    
    -- Lock the mutex
    EquipMutex[player.UserId] = true
    
    -- Ensure we always unlock the mutex
    local function cleanup()
        EquipMutex[player.UserId] = nil
    end
    
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then 
        cleanup()
        return {success = false, error = "No player data"}
    end
    
    local pet = playerData.pets[uniqueId]
    if not pet then 
        cleanup()
        return {success = false, error = "Pet not found"}
    end
    
    if pet.equipped then 
        cleanup()
        return {success = false, error = "Pet already equipped"}
    end
    
    -- AUTHORITATIVE COUNT: Count equipped pets directly from the source of truth
    local equippedCount = 0
    for id, p in pairs(playerData.pets) do
        if p.equipped then
            equippedCount = equippedCount + 1
        end
    end
    
    -- STRICT ENFORCEMENT: Check limit BEFORE making any changes
    if equippedCount >= Configuration.CONFIG.MAX_EQUIPPED_PETS then
        print("[PetSystem] BLOCKED equip attempt by", player.Name, "- Already have", equippedCount, "equipped")
        cleanup()
        return {success = false, error = "You cannot equip more than " .. Configuration.CONFIG.MAX_EQUIPPED_PETS .. " pets."}
    end
    
    -- Only equip if we're under the limit
    pet.equipped = true
    
    -- Rebuild equippedPets array from scratch (temporary until we remove it entirely)
    playerData.equippedPets = {}
    for id, p in pairs(playerData.pets) do
        if p.equipped then
            table.insert(playerData.equippedPets, id)
        end
    end
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Fire events to client
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents then
        -- Send pet update
        local PetUpdated = RemoteEvents:FindFirstChild("PetUpdated")
        if PetUpdated then
            PetUpdated:FireClient(player, {
                action = "equipped",
                petId = uniqueId,
                pet = pet
            })
        end
        
        -- Send full data update for immediate UI refresh
        local DataUpdated = RemoteEvents:FindFirstChild("DataUpdated")
        if DataUpdated then
            DataUpdated:FireClient(player, playerData)
        end
    end
    
    -- Unlock mutex before returning
    cleanup()
    return {success = true}
end

function PetSystem:UnequipPet(player, uniqueId)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return {success = false, error = "No player data"} end
    
    local pet = playerData.pets[uniqueId]
    if not pet then return {success = false, error = "Pet not found"} end
    
    if not pet.equipped then return {success = false, error = "Pet not equipped"} end
    
    -- Unequip the pet
    pet.equipped = false
    
    -- Remove from equipped list
    for i, id in ipairs(playerData.equippedPets) do
        if id == uniqueId then
            table.remove(playerData.equippedPets, i)
            break
        end
    end
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Fire events to client
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents then
        -- Send pet update
        local PetUpdated = RemoteEvents:FindFirstChild("PetUpdated")
        if PetUpdated then
            PetUpdated:FireClient(player, {
                action = "unequipped",
                petId = uniqueId,
                pet = pet
            })
        end
        
        -- Send full data update for immediate UI refresh
        local DataUpdated = RemoteEvents:FindFirstChild("DataUpdated")
        if DataUpdated then
            DataUpdated:FireClient(player, playerData)
        end
    end
    
    return {success = true}
end

-- ========================================
-- PET EVOLUTION
-- ========================================

function PetSystem:CanEvolve(petInstance)
    local petData = PetDatabase:GetPet(petInstance.petId)
    if not petData or not petData.evolution then
        return false, "Pet cannot evolve"
    end
    
    local evolutionData = petData.evolution
    
    -- Check level requirement
    if petInstance.level < evolutionData.requiredLevel then
        return false, "Level too low (need " .. evolutionData.requiredLevel .. ")"
    end
    
    return true, evolutionData
end

function PetSystem:EvolvePet(player, uniqueId)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return false, "No player data" end
    
    local pet = playerData.pets[uniqueId]
    if not pet then return false, "Pet not found" end
    
    local canEvolve, evolutionData = self:CanEvolve(pet)
    if not canEvolve then
        return false, evolutionData
    end
    
    -- Check if player has required items
    if evolutionData.requiredItems then
        for itemId, amount in pairs(evolutionData.requiredItems) do
            -- Check inventory for items (implement item system)
            -- For now, just check currency
            if itemId == "coins" then
                if playerData.currencies.coins < amount then
                    return false, "Not enough coins"
                end
            elseif itemId == "gems" then
                if playerData.currencies.gems < amount then
                    return false, "Not enough gems"
                end
            end
        end
    end
    
    -- Deduct costs
    if evolutionData.requiredItems then
        for itemId, amount in pairs(evolutionData.requiredItems) do
            if itemId == "coins" then
                playerData.currencies.coins = playerData.currencies.coins - amount
            elseif itemId == "gems" then
                playerData.currencies.gems = playerData.currencies.gems - amount
            end
        end
    end
    
    -- Evolve the pet
    local evolvedPetData = PetDatabase:GetPet(evolutionData.evolvesTo)
    if not evolvedPetData then
        return false, "Evolution pet not found"
    end
    
    -- Update pet data
    pet.petId = evolutionData.evolvesTo
    pet.name = evolvedPetData.name
    pet.stats = self:CalculatePetStats(evolvedPetData, pet.level)
    pet.evolved = true
    pet.evolvedFrom = pet.petId
    pet.evolvedAt = os.time()
    
    -- Update statistics
    playerData.statistics.totalPetsEvolved = (playerData.statistics.totalPetsEvolved or 0) + 1
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    return true, pet
end

-- ========================================
-- PET FUSION
-- ========================================

function PetSystem:CanFuse(pet1, pet2)
    -- Pets must be same species and level
    if pet1.petId ~= pet2.petId then
        return false, "Pets must be same species"
    end
    
    if pet1.level ~= pet2.level then
        return false, "Pets must be same level"
    end
    
    if pet1.uniqueId == pet2.uniqueId then
        return false, "Cannot fuse pet with itself"
    end
    
    return true
end

function PetSystem:FusePets(player, uniqueId1, uniqueId2)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return false, "No player data" end
    
    local pet1 = playerData.pets[uniqueId1]
    local pet2 = playerData.pets[uniqueId2]
    
    if not pet1 or not pet2 then
        return false, "Pet not found"
    end
    
    local canFuse, reason = self:CanFuse(pet1, pet2)
    if not canFuse then
        return false, reason
    end
    
    -- Check fusion cost
    local fusionCost = Configuration.CONFIG.PET_FUSION_COST * pet1.level
    if playerData.currencies.coins < fusionCost then
        return false, "Not enough coins (need " .. fusionCost .. ")"
    end
    
    -- Deduct cost
    playerData.currencies.coins = playerData.currencies.coins - fusionCost
    
    -- Create fused pet (higher level, better stats)
    local fusedPet = self:CreatePetInstance(pet1.petId, pet1.level + 1, 0)
    
    -- Inherit best traits
    fusedPet.shiny = pet1.shiny or pet2.shiny
    fusedPet.variant = pet1.variant or pet2.variant
    
    -- Boost stats by 20%
    for stat, value in pairs(fusedPet.stats) do
        fusedPet.stats[stat] = math.floor(value * 1.2)
    end
    
    -- Remove original pets
    self:RemovePetFromInventory(player, uniqueId1)
    self:RemovePetFromInventory(player, uniqueId2)
    
    -- Add fused pet
    self:AddPetToInventory(player, fusedPet)
    
    -- Update statistics
    playerData.statistics.totalPetsFused = (playerData.statistics.totalPetsFused or 0) + 1
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    return true, fusedPet
end

-- ========================================
-- PET LEVELING
-- ========================================

function PetSystem:AddExperience(player, uniqueId, amount)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return false end
    
    local pet = playerData.pets[uniqueId]
    if not pet then return false end
    
    pet.xp = pet.xp + amount
    
    -- Check for level up
    local xpNeeded = self:GetXPForNextLevel(pet.level)
    local levelsGained = 0
    
    while pet.xp >= xpNeeded do
        pet.xp = pet.xp - xpNeeded
        pet.level = pet.level + 1
        levelsGained = levelsGained + 1
        
        -- Recalculate stats
        local petData = PetDatabase:GetPet(pet.petId)
        if petData then
            pet.stats = self:CalculatePetStats(petData, pet.level)
        end
        
        xpNeeded = self:GetXPForNextLevel(pet.level)
    end
    
    if levelsGained > 0 then
        -- Fire level up event
        local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if RemoteEvents and RemoteEvents:FindFirstChild("PetLevelUp") then
            RemoteEvents.PetLevelUp:FireClient(player, {
                pet = pet,
                levelsGained = levelsGained
            })
        end
    end
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    return true, levelsGained
end

function PetSystem:GetXPForNextLevel(level)
    -- Exponential XP curve
    return math.floor(100 * (1.5 ^ (level - 1)))
end

-- ========================================
-- PET ABILITIES
-- ========================================

function PetSystem:GetPetAbilities(petInstance)
    local petData = PetDatabase:GetPet(petInstance.petId)
    if not petData or not petData.abilities then
        return {}
    end
    
    local unlockedAbilities = {}
    
    for _, ability in ipairs(petData.abilities) do
        if petInstance.level >= ability.unlockLevel then
            table.insert(unlockedAbilities, ability)
        end
    end
    
    return unlockedAbilities
end

function PetSystem:CalculateTotalBonus(player, bonusType)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return 1 end
    
    local totalBonus = 1
    
    -- Check equipped pets
    for _, uniqueId in ipairs(playerData.equippedPets) do
        local pet = playerData.pets[uniqueId]
        if pet then
            local petData = PetDatabase:GetPet(pet.petId)
            if petData and petData.passiveBonus and petData.passiveBonus[bonusType] then
                totalBonus = totalBonus * (1 + petData.passiveBonus[bonusType])
            end
        end
    end
    
    return totalBonus
end

-- ========================================
-- PET SELLING
-- ========================================

function PetSystem:GetPetValue(petInstance)
    local petData = PetDatabase:GetPet(petInstance.petId)
    if not petData then return 0 end
    
    -- Base value based on rarity
    local baseValue = 100 * (petData.rarity ^ 2)
    
    -- Level multiplier
    local levelMultiplier = 1 + (petInstance.level - 1) * 0.2
    
    -- Shiny bonus
    local shinyMultiplier = petInstance.shiny and 10 or 1
    
    -- Variant bonus
    local variantMultiplier = petInstance.variant and 2 or 1
    
    return math.floor(baseValue * levelMultiplier * shinyMultiplier * variantMultiplier)
end

function PetSystem:SellPet(player, uniqueId)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return false, "No player data" end
    
    local pet = playerData.pets[uniqueId]
    if not pet then return false, "Pet not found" end
    
    if pet.locked then return false, "Pet is locked" end
    
    local value = self:GetPetValue(pet)
    
    -- Remove pet
    local success = self:RemovePetFromInventory(player, uniqueId)
    if not success then
        return false, "Failed to remove pet"
    end
    
    -- Give coins
    playerData.currencies.coins = playerData.currencies.coins + value
    
    -- Update statistics
    playerData.statistics.totalPetsSold = (playerData.statistics.totalPetsSold or 0) + 1
    playerData.statistics.totalCoinsEarned = (playerData.statistics.totalCoinsEarned or 0) + value
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    return true, value
end

-- ========================================
-- DATA VALIDATION
-- ========================================

function PetSystem:ValidatePlayerPets(player)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return end
    
    -- Rebuild equippedPets array based on equipped flags
    local correctEquippedPets = {}
    local equippedCount = 0
    local changesWereMade = false
    
    -- Sort pets by some criteria to ensure consistent unequipping order
    local sortedPets = {}
    for id, pet in pairs(playerData.pets) do
        if pet.equipped then
            table.insert(sortedPets, {id = id, pet = pet})
        end
    end
    
    -- Process equipped pets
    for _, petData in ipairs(sortedPets) do
        equippedCount = equippedCount + 1
        -- If we're over the limit, unequip excess pets
        if equippedCount > Configuration.CONFIG.MAX_EQUIPPED_PETS then
            petData.pet.equipped = false
            changesWereMade = true
            print("[PetSystem] VALIDATION: Unequipped excess pet:", petData.id, "for player:", player.Name, "- Was at", equippedCount, "/", Configuration.CONFIG.MAX_EQUIPPED_PETS)
        else
            table.insert(correctEquippedPets, petData.id)
        end
    end
    
    -- Update the equippedPets array
    playerData.equippedPets = correctEquippedPets
    
    -- Mark data as dirty if we made changes
    if changesWereMade then
        DataStoreModule:MarkPlayerDirty(player.UserId)
        
        -- Notify client of the change
        local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if RemoteEvents then
            local DataUpdated = RemoteEvents:FindFirstChild("DataUpdated")
            if DataUpdated then
                DataUpdated:FireClient(player, playerData)
            end
        end
        
        print("[PetSystem] VALIDATION COMPLETE: Fixed equipped count for", player.Name, "- Now:", #correctEquippedPets, "/", Configuration.CONFIG.MAX_EQUIPPED_PETS)
    else
        print("[PetSystem] VALIDATION COMPLETE: No issues for", player.Name, "- Equipped:", #correctEquippedPets, "/", Configuration.CONFIG.MAX_EQUIPPED_PETS)
    end
end

-- ========================================
-- BATCH DELETION
-- ========================================

function PetSystem:BatchDeletePets(player, petIds)
    -- Validate input
    if type(petIds) ~= "table" or #petIds == 0 then
        return {success = false, error = "Invalid pet list"}
    end
    
    -- Limit batch size to prevent abuse
    if #petIds > 500 then
        return {success = false, error = "Too many pets selected (max 500)"}
    end
    
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then
        return {success = false, error = "No player data"}
    end
    
    -- Start transaction
    local deletedPets = {}
    local totalCoins = 0
    local totalDust = 0
    local failedDeletes = {}
    
    -- Process each pet
    for _, uniqueId in ipairs(petIds) do
        local pet = playerData.pets[uniqueId]
        
        if pet then
            -- Can't delete equipped pets
            if pet.equipped then
                table.insert(failedDeletes, {
                    id = uniqueId,
                    reason = "Pet is equipped"
                })
            -- Can't delete locked pets
            elseif pet.locked then
                table.insert(failedDeletes, {
                    id = uniqueId,
                    reason = "Pet is locked"
                })
            else
                -- Calculate resources from pet
                local petData = PetDatabase:GetPet(pet.petId)
                if petData then
                    -- Base values by rarity
                    local baseValues = {
                        Common = {coins = 10, dust = 1},
                        Uncommon = {coins = 25, dust = 2},
                        Rare = {coins = 100, dust = 5},
                        Epic = {coins = 500, dust = 15},
                        Legendary = {coins = 2000, dust = 50},
                        Mythic = {coins = 10000, dust = 200}
                    }
                    
                    local rarityValues = baseValues[pet.rarity] or baseValues.Common
                    local levelMultiplier = 1 + (pet.level - 1) * 0.1
                    
                    local coins = math.floor(rarityValues.coins * levelMultiplier)
                    local dust = math.floor(rarityValues.dust * levelMultiplier)
                    
                    totalCoins = totalCoins + coins
                    totalDust = totalDust + dust
                    
                    -- Store deleted pet info for logging
                    table.insert(deletedPets, {
                        uniqueId = uniqueId,
                        petId = pet.petId,
                        name = pet.name,
                        rarity = pet.rarity,
                        level = pet.level,
                        coins = coins,
                        dust = dust
                    })
                    
                    -- Remove pet from inventory
                    playerData.pets[uniqueId] = nil
                end
            end
        else
            table.insert(failedDeletes, {
                id = uniqueId,
                reason = "Pet not found"
            })
        end
    end
    
    -- Only proceed if we deleted something
    if #deletedPets > 0 then
        -- Add resources to player
        playerData.coins = (playerData.coins or 0) + totalCoins
        playerData.petDust = (playerData.petDust or 0) + totalDust
        
        -- Mark data as dirty for saving
        DataStoreModule:MarkDirty(player.UserId)
        
        -- Fire client update
        local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if RemoteEvents then
            local DataUpdated = RemoteEvents:FindFirstChild("DataUpdated")
            if DataUpdated then
                DataUpdated:FireClient(player, playerData)
            end
            
            -- Fire specific event for mass deletion
            local PetsDeleted = RemoteEvents:FindFirstChild("PetsDeleted")
            if PetsDeleted then
                PetsDeleted:FireClient(player, {
                    deletedCount = #deletedPets,
                    coinsReceived = totalCoins,
                    dustReceived = totalDust
                })
            end
        end
        
        -- Log the deletion
        print(string.format(
            "[PetSystem] Batch deleted %d pets for %s. Coins: %d, Dust: %d",
            #deletedPets,
            player.Name,
            totalCoins,
            totalDust
        ))
    end
    
    return {
        success = true,
        deletedCount = #deletedPets,
        coinsReceived = totalCoins,
        dustReceived = totalDust,
        failedDeletes = failedDeletes
    }
end

return PetSystem