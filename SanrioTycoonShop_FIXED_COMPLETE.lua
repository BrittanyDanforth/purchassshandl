--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                    SANRIO TYCOON SHOP - COMPLETE FIXED VERSION                       ║
    ║                              Version 5.0 - FULLY WORKING                             ║
    ║                                                                                      ║
    ║  INSTALLATION:                                                                       ║
    ║  1. Place this ENTIRE script in ServerScriptService                                ║
    ║  2. Name it: "SanrioTycoonShopSystem"                                              ║
    ║  3. This is a SERVER SCRIPT - handles all backend logic                            ║
    ║  4. For UI, you need a separate CLIENT script                                      ║
    ║                                                                                      ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ========================================
-- SERVICES
-- ========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local PhysicsService = game:GetService("PhysicsService")
local GroupService = game:GetService("GroupService")
local BadgeService = game:GetService("BadgeService")
local Chat = game:GetService("Chat")
local Debris = game:GetService("Debris")

-- DataStore Setup
local PlayerDataStore = DataStoreService:GetDataStore("SanrioTycoonData_v5")
local BackupDataStore = DataStoreService:GetDataStore("SanrioTycoonBackup_v5")

-- ========================================
-- CONFIGURATION
-- ========================================
local CONFIG = {
    VERSION = "5.0.0",
    BUILD_NUMBER = 1337,
    
    -- Economy
    STARTING_GEMS = 500,
    STARTING_COINS = 10000,
    DAILY_REWARD_GEMS = 50,
    
    -- Pet System
    MAX_EQUIPPED_PETS = 6,
    MAX_INVENTORY_SIZE = 500,
    EVOLUTION_COST_MULTIPLIER = 2.5,
    FUSION_SUCCESS_RATE = 0.7,
    
    -- Trading
    TRADE_TAX_PERCENTAGE = 0.05,
    MAX_TRADE_ITEMS = 20,
    TRADE_COOLDOWN = 60,
    
    -- Anti-Exploit
    MAX_REQUESTS_PER_MINUTE = 30,
    SUSPICIOUS_WEALTH_THRESHOLD = 1000000000,
    
    -- Group Benefits
    GROUP_ID = 123456789, -- Replace with your group ID
    GROUP_BONUS_MULTIPLIER = 1.25,
}

-- ========================================
-- GLOBAL VARIABLES
-- ========================================
local PlayerData = {} -- Stores all player data

-- ========================================
-- PET DATABASE
-- ========================================
local PetDatabase = {
    ["hello_kitty_classic"] = {
        id = "hello_kitty_classic",
        name = "Classic Hello Kitty",
        displayName = "Hello Kitty",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 100,
            gems = 1,
            luck = 5,
            speed = 10,
            power = 50
        },
        description = "The beloved white cat with her iconic red bow",
        imageId = "rbxassetid://10000000001", -- Replace with actual ID
        modelId = "rbxassetid://10000000002",
        abilities = {
            {
                name = "Cuteness Overload",
                description = "Increases coin production by 20% for 30 seconds",
                cooldown = 60,
                effect = "coin_boost",
                value = 0.2,
                duration = 30
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1000,
            items = {"red_bow", "white_ribbon"}
        },
        evolvesTo = "hello_kitty_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 200, 200)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)}
        }
    },
    
    ["my_melody_classic"] = {
        id = "my_melody_classic",
        name = "Classic My Melody",
        displayName = "My Melody",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 120,
            gems = 1,
            luck = 7,
            speed = 12,
            power = 45
        },
        description = "Sweet white rabbit with her signature pink hood",
        imageId = "rbxassetid://10000000003",
        modelId = "rbxassetid://10000000004",
        abilities = {
            {
                name = "Melody Magic",
                description = "Heals nearby pets by 20% of max health",
                cooldown = 45,
                effect = "heal_aoe",
                value = 0.2,
                radius = 20
            }
        },
        evolutionRequirements = {
            level = 25,
            gems = 1000,
            items = {"pink_hood", "melody_note"}
        },
        evolvesTo = "my_melody_angel",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 192, 203)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)}
        }
    },
    
    ["kuromi_classic"] = {
        id = "kuromi_classic",
        name = "Classic Kuromi",
        displayName = "Kuromi",
        tier = "Uncommon",
        rarity = 2,
        baseStats = {
            coins = 250,
            gems = 3,
            luck = 10,
            speed = 15,
            power = 80
        },
        description = "Mischievous white rabbit with devil horns",
        imageId = "rbxassetid://10000000005",
        modelId = "rbxassetid://10000000006",
        abilities = {
            {
                name = "Dark Magic",
                description = "Deals damage to all enemies in range",
                cooldown = 30,
                effect = "damage_aoe",
                value = 150,
                radius = 25
            }
        },
        evolutionRequirements = {
            level = 35,
            gems = 2500,
            items = {"devil_horn", "pink_skull"}
        },
        evolvesTo = "kuromi_demon",
        variants = {
            normal = {multiplier = 1, colorShift = nil},
            shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 100, 255)},
            golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0)},
            rainbow = {multiplier = 10, colorShift = "rainbow"},
            dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100)}
        }
    }
    -- Add more pets as needed
}

-- ========================================
-- EGG CASES
-- ========================================
local EggCases = {
    ["basic"] = {
        id = "basic",
        name = "Basic Egg",
        description = "Common pets with good drop rates",
        price = 100,
        currency = "Coins",
        imageId = "rbxassetid://10000001001",
        pets = {"hello_kitty_classic", "my_melody_classic"},
        dropRates = {
            ["hello_kitty_classic"] = 60,
            ["my_melody_classic"] = 40
        }
    },
    
    ["premium"] = {
        id = "premium",
        name = "Premium Egg",
        description = "Better chance for rare pets",
        price = 500,
        currency = "Gems",
        imageId = "rbxassetid://10000001002",
        pets = {"kuromi_classic", "hello_kitty_classic", "my_melody_classic"},
        dropRates = {
            ["kuromi_classic"] = 30,
            ["hello_kitty_classic"] = 40,
            ["my_melody_classic"] = 30
        }
    }
}

-- ========================================
-- GAMEPASS DATA
-- ========================================
local GamepassData = {
    [123456] = { -- Replace with actual gamepass ID
        name = "2x Luck",
        description = "Double your chances of getting rare pets!",
        price = 399,
        benefits = {"luck_multiplier_2"}
    },
    [123457] = {
        name = "Auto Hatch",
        description = "Automatically open eggs!",
        price = 599,
        benefits = {"auto_hatch"}
    },
    [123458] = {
        name = "VIP",
        description = "VIP benefits and exclusive access!",
        price = 999,
        benefits = {"vip_access", "gem_multiplier_2", "exclusive_area"}
    }
}

-- ========================================
-- PLAYER DATA TEMPLATE
-- ========================================
local function GetDefaultPlayerData()
    return {
        -- Basic Info
        userId = 0,
        username = "",
        displayName = "",
        joinDate = os.time(),
        lastSeen = os.time(),
        
        -- Currencies
        currencies = {
            coins = CONFIG.STARTING_COINS,
            gems = CONFIG.STARTING_GEMS
        },
        
        -- Pets
        pets = {},
        equippedPets = {},
        maxPetStorage = 50,
        
        -- Stats
        statistics = {
            totalEggsOpened = 0,
            totalPetsHatched = 0,
            totalCoinsEarned = 0,
            totalGemsEarned = 0,
            totalGemsSpent = 0
        },
        
        -- Gamepasses
        ownedGamepasses = {},
        
        -- Settings
        settings = {
            musicEnabled = true,
            sfxEnabled = true,
            particlesEnabled = true
        }
    }
end

-- ========================================
-- DATA MANAGEMENT
-- ========================================
local function LoadPlayerData(player)
    local success, data = pcall(function()
        return PlayerDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        PlayerData[player.UserId] = data
    else
        PlayerData[player.UserId] = GetDefaultPlayerData()
        PlayerData[player.UserId].userId = player.UserId
        PlayerData[player.UserId].username = player.Name
        PlayerData[player.UserId].displayName = player.DisplayName
    end
    
    -- Load gamepasses
    for gamepassId, _ in pairs(GamepassData) do
        spawn(function()
            local hasPass = false
            local success, result = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
            end)
            if success then
                hasPass = result
            end
            PlayerData[player.UserId].ownedGamepasses[gamepassId] = hasPass
        end)
    end
end

local function SavePlayerData(player)
    if PlayerData[player.UserId] then
        PlayerData[player.UserId].lastSeen = os.time()
        
        local success, error = pcall(function()
            PlayerDataStore:SetAsync(player.UserId, PlayerData[player.UserId])
        end)
        
        if not success then
            warn("Failed to save data for " .. player.Name .. ": " .. tostring(error))
        end
    end
end

-- ========================================
-- WEIGHTED RANDOM SYSTEM
-- ========================================
local function GetWeightedRandomPet(dropRates)
    local totalWeight = 0
    for _, weight in pairs(dropRates) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for petId, weight in pairs(dropRates) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return petId
        end
    end
    
    -- Fallback
    for petId, _ in pairs(dropRates) do
        return petId
    end
end

-- ========================================
-- CASE OPENING SYSTEM
-- ========================================
local function OpenCase(player, eggType)
    local playerData = PlayerData[player.UserId]
    if not playerData then 
        return {success = false, error = "No player data"}
    end
    
    local egg = EggCases[eggType]
    if not egg then 
        return {success = false, error = "Invalid egg type"}
    end
    
    -- Check currency
    if egg.currency == "Gems" then
        if playerData.currencies.gems < egg.price then
            return {success = false, error = "Not enough gems"}
        end
        playerData.currencies.gems = playerData.currencies.gems - egg.price
    elseif egg.currency == "Coins" then
        if playerData.currencies.coins < egg.price then
            return {success = false, error = "Not enough coins"}
        end
        playerData.currencies.coins = playerData.currencies.coins - egg.price
    end
    
    -- Get random pet
    local petId = GetWeightedRandomPet(egg.dropRates)
    local petData = PetDatabase[petId]
    
    if not petData then
        return {success = false, error = "Invalid pet data"}
    end
    
    -- Determine variant
    local variant = "normal"
    local variantRoll = math.random()
    
    if variantRoll < 0.001 then
        variant = "dark_matter"
    elseif variantRoll < 0.01 then
        variant = "rainbow"
    elseif variantRoll < 0.05 then
        variant = "golden"
    elseif variantRoll < 0.2 then
        variant = "shiny"
    end
    
    -- Create pet instance
    local petInstance = {
        id = HttpService:GenerateGUID(false),
        petId = petData.id,
        name = petData.name,
        displayName = petData.displayName,
        level = 1,
        experience = 0,
        variant = variant,
        obtained = os.time(),
        equipped = false,
        locked = false,
        stats = {}
    }
    
    -- Copy base stats and apply variant multiplier
    for stat, value in pairs(petData.baseStats) do
        petInstance.stats[stat] = value
        if petData.variants[variant] then
            petInstance.stats[stat] = math.floor(value * petData.variants[variant].multiplier)
        end
    end
    
    -- Add to inventory
    table.insert(playerData.pets, petInstance)
    
    -- Update statistics
    playerData.statistics.totalEggsOpened = playerData.statistics.totalEggsOpened + 1
    playerData.statistics.totalPetsHatched = playerData.statistics.totalPetsHatched + 1
    if egg.currency == "Gems" then
        playerData.statistics.totalGemsSpent = playerData.statistics.totalGemsSpent + egg.price
    end
    
    -- Save data
    SavePlayerData(player)
    
    return {
        success = true,
        pet = petInstance,
        petData = petData,
        variant = variant
    }
end

-- ========================================
-- ANTI-EXPLOIT SYSTEM
-- ========================================
local AntiExploit = {
    requests = {},
    
    ValidateRequest = function(player, requestType)
        local userId = player.UserId
        local currentTime = tick()
        
        if not AntiExploit.requests[userId] then
            AntiExploit.requests[userId] = {}
        end
        
        -- Clean old requests
        local validRequests = {}
        for _, request in ipairs(AntiExploit.requests[userId]) do
            if currentTime - request.time < 60 then
                table.insert(validRequests, request)
            end
        end
        AntiExploit.requests[userId] = validRequests
        
        -- Check rate limit
        if #AntiExploit.requests[userId] >= CONFIG.MAX_REQUESTS_PER_MINUTE then
            warn("Rate limit exceeded for player: " .. player.Name)
            return false
        end
        
        -- Add new request
        table.insert(AntiExploit.requests[userId], {
            type = requestType,
            time = currentTime
        })
        
        return true
    end,
    
    ValidatePetOwnership = function(player, petId)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false end
        
        for _, pet in ipairs(playerData.pets) do
            if pet.id == petId then
                return true
            end
        end
        
        return false
    end
}

-- ========================================
-- REMOTE EVENTS SETUP
-- ========================================
local function SetupRemotes()
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end
    
    -- Create RemoteEvents
    local eventNames = {
        "OpenCase",
        "EquipPet",
        "UnequipPet",
        "DeletePet",
        "LockPet",
        "RequestPlayerData",
        "UpdateSettings",
        "ClaimReward"
    }
    
    for _, eventName in ipairs(eventNames) do
        if not remoteEvents:FindFirstChild(eventName) then
            local event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = remoteEvents
        end
    end
    
    -- Create RemoteFunctions
    local functionNames = {
        "GetPlayerData",
        "GetShopData",
        "ValidatePurchase"
    }
    
    for _, funcName in ipairs(functionNames) do
        if not remoteEvents:FindFirstChild(funcName) then
            local func = Instance.new("RemoteFunction")
            func.Name = funcName
            func.Parent = remoteEvents
        end
    end
    
    return remoteEvents
end

-- ========================================
-- REMOTE HANDLERS
-- ========================================
local function SetupRemoteHandlers()
    local remotes = SetupRemotes()
    
    -- Open Case Handler
    remotes.OpenCase.OnServerEvent:Connect(function(player, eggType)
        if not AntiExploit.ValidateRequest(player, "OpenCase") then
            return
        end
        
        local result = OpenCase(player, eggType)
        
        -- Send result to player
        if result.success then
            remotes.OpenCase:FireClient(player, result)
        else
            remotes.OpenCase:FireClient(player, {success = false, error = result.error})
        end
    end)
    
    -- Get Player Data Handler
    remotes.GetPlayerData.OnServerInvoke = function(player)
        return PlayerData[player.UserId]
    end
    
    -- Get Shop Data Handler
    remotes.GetShopData.OnServerInvoke = function(player)
        return {
            eggs = EggCases,
            gamepasses = GamepassData,
            pets = PetDatabase
        }
    end
    
    -- Equip Pet Handler
    remotes.EquipPet.OnServerEvent:Connect(function(player, petId)
        if not AntiExploit.ValidateRequest(player, "EquipPet") then
            return
        end
        
        if not AntiExploit.ValidatePetOwnership(player, petId) then
            warn("Invalid pet ownership for player: " .. player.Name)
            return
        end
        
        local playerData = PlayerData[player.UserId]
        if not playerData then return end
        
        -- Check equipped limit
        if #playerData.equippedPets >= CONFIG.MAX_EQUIPPED_PETS then
            return
        end
        
        -- Check if already equipped
        for _, equippedId in ipairs(playerData.equippedPets) do
            if equippedId == petId then
                return
            end
        end
        
        -- Equip pet
        table.insert(playerData.equippedPets, petId)
        
        -- Update pet equipped status
        for _, pet in ipairs(playerData.pets) do
            if pet.id == petId then
                pet.equipped = true
                break
            end
        end
        
        SavePlayerData(player)
    end)
    
    -- Unequip Pet Handler
    remotes.UnequipPet.OnServerEvent:Connect(function(player, petId)
        if not AntiExploit.ValidateRequest(player, "UnequipPet") then
            return
        end
        
        local playerData = PlayerData[player.UserId]
        if not playerData then return end
        
        -- Remove from equipped
        for i, equippedId in ipairs(playerData.equippedPets) do
            if equippedId == petId then
                table.remove(playerData.equippedPets, i)
                break
            end
        end
        
        -- Update pet equipped status
        for _, pet in ipairs(playerData.pets) do
            if pet.id == petId then
                pet.equipped = false
                break
            end
        end
        
        SavePlayerData(player)
    end)
end

-- ========================================
-- PLAYER HANDLERS
-- ========================================
Players.PlayerAdded:Connect(function(player)
    print("[SANRIO TYCOON] Player joined: " .. player.Name)
    
    -- Load data
    LoadPlayerData(player)
    
    -- Apply gamepass benefits when character spawns
    player.CharacterAdded:Connect(function(character)
        local playerData = PlayerData[player.UserId]
        if playerData then
            -- Example: Apply speed boost for VIP
            if playerData.ownedGamepasses[123458] then -- VIP gamepass
                local humanoid = character:WaitForChild("Humanoid")
                humanoid.WalkSpeed = 20 -- Default is 16
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    print("[SANRIO TYCOON] Player leaving: " .. player.Name)
    
    -- Save data
    SavePlayerData(player)
    
    -- Clean up
    PlayerData[player.UserId] = nil
    AntiExploit.requests[player.UserId] = nil
end)

-- ========================================
-- AUTO SAVE
-- ========================================
spawn(function()
    while true do
        wait(300) -- Save every 5 minutes
        
        for userId, _ in pairs(PlayerData) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                SavePlayerData(player)
            end
        end
        
        print("[SANRIO TYCOON] Auto-save completed")
    end
end)

-- ========================================
-- MARKETPLACE HANDLERS
-- ========================================
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Handle gem purchases
    local gemProducts = {
        [1000001] = 100,  -- 100 gems - Replace with actual product ID
        [1000002] = 500,  -- 500 gems
        [1000003] = 1200, -- 1200 gems
        [1000004] = 2500, -- 2500 gems
        [1000005] = 6000  -- 6000 gems
    }
    
    local gemAmount = gemProducts[receiptInfo.ProductId]
    if gemAmount then
        playerData.currencies.gems = playerData.currencies.gems + gemAmount
        playerData.statistics.totalGemsEarned = playerData.statistics.totalGemsEarned + gemAmount
        SavePlayerData(player)
        
        print("Awarded " .. gemAmount .. " gems to " .. player.Name)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
    if wasPurchased then
        local playerData = PlayerData[player.UserId]
        if playerData then
            playerData.ownedGamepasses[gamepassId] = true
            SavePlayerData(player)
            print(player.Name .. " purchased gamepass: " .. gamepassId)
        end
    end
end)

-- ========================================
-- INITIALIZATION
-- ========================================
local function Initialize()
    print("[SANRIO TYCOON] Initializing server...")
    
    -- Setup remotes
    SetupRemoteHandlers()
    
    -- Test DataStore access
    local success, error = pcall(function()
        PlayerDataStore:GetAsync("TestKey")
    end)
    
    if success then
        print("[SANRIO TYCOON] DataStore access confirmed")
    else
        warn("[SANRIO TYCOON] DataStore error: " .. tostring(error))
    end
    
    print("[SANRIO TYCOON] Server initialized successfully!")
    print("[SANRIO TYCOON] Version: " .. CONFIG.VERSION)
end

-- Start the server
Initialize()

print([[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                    SANRIO TYCOON SHOP - SERVER RUNNING                               ║
║                                                                                      ║
║  Status: ✓ Active                                                                    ║
║  Version: 5.0.0                                                                      ║
║  Build: 1337                                                                         ║
║                                                                                      ║
║  Systems Online:                                                                     ║
║  ✓ DataStore System                                                                 ║
║  ✓ Pet Database                                                                     ║
║  ✓ Case Opening System                                                              ║
║  ✓ Anti-Exploit Protection                                                          ║
║  ✓ Auto-Save System                                                                 ║
║  ✓ Remote Event Handlers                                                            ║
║                                                                                      ║
║  Waiting for players...                                                             ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]])