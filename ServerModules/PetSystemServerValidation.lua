--[[
    Server-Side Pet System Validation
    =================================
    
    This is an example of how the server should validate pet equip/unequip requests
    to prevent the 7/6 bug and ensure data integrity.
    
    The server should NEVER trust the client and should always validate:
    1. The player owns the pet
    2. The pet exists
    3. The equipped count doesn't exceed the maximum
    4. The action is valid (can't equip an already equipped pet)
]]

local MAX_EQUIPPED_PETS = 6

-- Example server-side validation for EquipPet
function PetSystem:EquipPet(player, uniqueId)
    -- Get player data from your data system
    local playerData = DataManager:Get(player)
    if not playerData then
        return { success = false, error = "Failed to load player data." }
    end
    
    -- Check if pet exists and belongs to player
    if not playerData.pets or not playerData.pets[uniqueId] then
        return { success = false, error = "Pet not found." }
    end
    
    local pet = playerData.pets[uniqueId]
    
    -- Check if already equipped
    if pet.equipped then
        return { success = false, error = "Pet is already equipped." }
    end
    
    -- *** CRITICAL: Count currently equipped pets ***
    local equippedCount = 0
    for _, petData in pairs(playerData.pets) do
        if petData.equipped then
            equippedCount = equippedCount + 1
        end
    end
    
    -- *** CRITICAL: Enforce maximum limit ***
    if equippedCount >= MAX_EQUIPPED_PETS then
        return { 
            success = false, 
            error = "You cannot equip more than " .. MAX_EQUIPPED_PETS .. " pets." 
        }
    end
    
    -- All checks passed - equip the pet
    pet.equipped = true
    
    -- Save the data
    DataManager:Save(player)
    
    -- Return success
    return { success = true }
end

-- Example server-side validation for UnequipPet
function PetSystem:UnequipPet(player, uniqueId)
    -- Get player data
    local playerData = DataManager:Get(player)
    if not playerData then
        return { success = false, error = "Failed to load player data." }
    end
    
    -- Check if pet exists and belongs to player
    if not playerData.pets or not playerData.pets[uniqueId] then
        return { success = false, error = "Pet not found." }
    end
    
    local pet = playerData.pets[uniqueId]
    
    -- Check if not equipped
    if not pet.equipped then
        return { success = false, error = "Pet is not equipped." }
    end
    
    -- Unequip the pet
    pet.equipped = false
    
    -- Save the data
    DataManager:Save(player)
    
    -- Return success
    return { success = true }
end

--[[
    RemoteFunction Setup
    ====================
    
    In your server initialization, you would connect these functions:
    
    local EquipPetRemote = ReplicatedStorage.Remotes.Functions.EquipPet
    local UnequipPetRemote = ReplicatedStorage.Remotes.Functions.UnequipPet
    
    EquipPetRemote.OnServerInvoke = function(player, uniqueId)
        return PetSystem:EquipPet(player, uniqueId)
    end
    
    UnequipPetRemote.OnServerInvoke = function(player, uniqueId)
        return PetSystem:UnequipPet(player, uniqueId)
    end
]]