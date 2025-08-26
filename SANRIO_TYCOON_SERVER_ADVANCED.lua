-- ========================================
-- SANRIO TYCOON SERVER - ADVANCED VERSION
-- With Delta Networking, Janitor, and Performance Optimizations
-- ========================================

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Advanced Modules
local DeltaNetworking = require(ReplicatedStorage.Modules.Shared.DeltaNetworking)
local Janitor = require(ReplicatedStorage.Modules.Shared.Janitor)

-- ========================================
-- CONFIGURATION
-- ========================================
local CONFIG = {
    VERSION = "2.0.0",
    SAVE_INTERVAL = 60, -- Auto-save every 60 seconds
    DELTA_UPDATE_INTERVAL = 0.5, -- Send delta updates every 0.5 seconds
    MAX_RETRIES = 3,
    ENABLE_DEBUG = false
}

-- ========================================
-- REMOTE SETUP
-- ========================================
local RemoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
if not RemoteFolder then
    RemoteFolder = Instance.new("Folder")
    RemoteFolder.Name = "RemoteEvents"
    RemoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local RemoteEvents = {}
local requiredEvents = {
    "DataUpdated", -- For delta networking
    "OpenCase",
    "RequestTrade",
    "UpdateTrade",
    "ConfirmTrade",
    "JoinBattle",
    "BattleTurn",
    "ClaimQuest",
    "ClaimDailyReward",
    "NotificationSent",
    "PetAction",
    "ShopPurchase"
}

for _, eventName in ipairs(requiredEvents) do
    local remote = RemoteFolder:FindFirstChild(eventName)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = eventName
        remote.Parent = RemoteFolder
    end
    RemoteEvents[eventName] = remote
end

-- Create RemoteFunctions
local RemoteFunctions = {}
local requiredFunctions = {
    "GetPlayerData",
    "SaveSettings",
    "GetShopData",
    "GetActiveQuests",
    "DebugGiveCurrency"
}

for _, funcName in ipairs(requiredFunctions) do
    local remote = RemoteFolder:FindFirstChild(funcName)
    if not remote then
        remote = Instance.new("RemoteFunction")
        remote.Name = funcName
        remote.Parent = RemoteFolder
    end
    RemoteFunctions[funcName] = remote
end

-- ========================================
-- DATA MANAGEMENT
-- ========================================
local DataStore = DataStoreService:GetDataStore("SanrioTycoonData_v2")
local PlayerData = {} -- Now using dictionary for O(1) lookups
local PlayerJanitors = {} -- Cleanup management
local DeltaNetManager = DeltaNetworking.newServer(RemoteEvents.DataUpdated)

-- Default player data template
local function GetDefaultPlayerData()
    return {
        version = CONFIG.VERSION,
        userId = 0,
        username = "",
        displayName = "",
        
        -- Currencies
        currencies = {
            coins = 1000,
            gems = 10,
            tickets = 0,
            tokens = 0
        },
        
        -- Pets as dictionary for O(1) lookup
        pets = {}, -- Will be {[petId] = petData}
        petCollection = {},
        
        -- Statistics
        statistics = {
            playtime = 0,
            totalCoinsEarned = 0,
            totalGemsEarned = 0,
            eggsOpened = 0,
            tradesCompleted = 0,
            battlesWon = 0,
            questsCompleted = 0,
            
            -- Nested stats
            eggStats = {},
            battleStats = {
                wins = 0,
                losses = 0,
                draws = 0,
                highestWinStreak = 0,
                currentWinStreak = 0
            },
            tradeStats = {
                sent = 0,
                received = 0,
                value = 0
            }
        },
        
        -- Progress
        level = 1,
        experience = 0,
        rebirths = 0,
        
        -- Inventory
        inventory = {
            items = {},
            consumables = {},
            materials = {}
        },
        
        -- Settings
        settings = {
            music = true,
            sfx = true,
            notifications = true,
            trading = true,
            autoSave = true
        },
        
        -- Quests
        quests = {
            daily = {},
            weekly = {},
            story = {},
            lastDailyReset = 0,
            lastWeeklyReset = 0
        },
        
        -- Social
        friends = {},
        clan = nil,
        
        -- Gamepasses
        gamepasses = {},
        
        -- Timestamps
        firstJoined = os.time(),
        lastSeen = os.time(),
        lastSaved = os.time()
    }
end

-- Deep merge function for data loading
local function DeepMerge(template, data)
    if type(template) ~= "table" then return data or template end
    if type(data) ~= "table" then return template end
    
    local result = {}
    
    -- Copy template values
    for key, value in pairs(template) do
        if type(value) == "table" then
            result[key] = DeepMerge(value, data[key])
        else
            result[key] = data[key] ~= nil and data[key] or value
        end
    end
    
    -- Preserve extra data
    for key, value in pairs(data) do
        if result[key] == nil then
            result[key] = value
        end
    end
    
    return result
end

-- ========================================
-- PLAYER DATA OPERATIONS
-- ========================================
local function LoadPlayerData(player)
    local janitor = Janitor.new()
    PlayerJanitors[player] = janitor
    
    local success, data = pcall(function()
        return DataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        -- Use DeepMerge for robust data loading
        PlayerData[player.UserId] = DeepMerge(GetDefaultPlayerData(), data)
        
        -- Update user info
        PlayerData[player.UserId].userId = player.UserId
        PlayerData[player.UserId].username = player.Name
        PlayerData[player.UserId].displayName = player.DisplayName
        PlayerData[player.UserId].lastSeen = os.time()
        
        print("[DataManager] Loaded data for", player.Name)
    else
        -- New player
        PlayerData[player.UserId] = GetDefaultPlayerData()
        PlayerData[player.UserId].userId = player.UserId
        PlayerData[player.UserId].username = player.Name
        PlayerData[player.UserId].displayName = player.DisplayName
        
        print("[DataManager] Created new data for", player.Name)
    end
    
    -- Start delta tracking
    DeltaNetManager:TrackPlayer(player, PlayerData[player.UserId])
    
    -- Send initial data
    RemoteEvents.DataUpdated:FireClient(player, {
        type = "full",
        data = PlayerData[player.UserId],
        timestamp = tick()
    })
    
    -- Setup auto-save with Janitor
    local lastSaveTime = tick()
    janitor:Add(RunService.Heartbeat:Connect(function()
        if tick() - lastSaveTime >= CONFIG.SAVE_INTERVAL then
            SavePlayerData(player)
            lastSaveTime = tick()
        end
    end))
    
    -- Setup character spawning
    janitor:Add(player.CharacterAdded:Connect(function(character)
        -- Character setup here
    end))
    
    return PlayerData[player.UserId]
end

function SavePlayerData(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    
    data.lastSaved = os.time()
    
    local attempts = 0
    local success = false
    
    while attempts < CONFIG.MAX_RETRIES and not success do
        attempts = attempts + 1
        success = pcall(function()
            DataStore:SetAsync(player.UserId, data)
        end)
        
        if not success and attempts < CONFIG.MAX_RETRIES then
            wait(2 ^ attempts) -- Exponential backoff
        end
    end
    
    if success then
        if CONFIG.ENABLE_DEBUG then
            print("[DataManager] Saved data for", player.Name)
        end
    else
        warn("[DataManager] Failed to save data for", player.Name, "after", attempts, "attempts")
    end
end

-- ========================================
-- PET SYSTEM (OPTIMIZED)
-- ========================================
local PetDatabase = {
    ["hello_kitty_classic"] = {
        id = "hello_kitty_classic",
        name = "Hello Kitty Classic",
        tier = "Common",
        rarity = 1,
        baseStats = {
            coins = 100,
            gems = 1,
            luck = 5,
            speed = 10
        }
    },
    ["kuromi_shadow"] = {
        id = "kuromi_shadow",
        name = "Shadow Kuromi",
        tier = "Rare",
        rarity = 2,
        baseStats = {
            coins = 250,
            gems = 3,
            luck = 10,
            speed = 15
        }
    },
    ["cinnamoroll_cloud"] = {
        id = "cinnamoroll_cloud",
        name = "Cloud Cinnamoroll",
        tier = "Epic",
        rarity = 3,
        baseStats = {
            coins = 500,
            gems = 5,
            luck = 20,
            speed = 20
        }
    },
    ["my_melody_angel"] = {
        id = "my_melody_angel",
        name = "Angel My Melody",
        tier = "Legendary",
        rarity = 4,
        baseStats = {
            coins = 1000,
            gems = 10,
            luck = 50,
            speed = 30
        }
    }
}

local function CreatePetInstance(petId, variant, owner)
    local petData = PetDatabase[petId]
    if not petData then return nil end
    
    local instanceId = HttpService:GenerateGUID(false)
    
    return {
        instanceId = instanceId,
        id = petId,
        name = petData.name,
        tier = petData.tier,
        variant = variant or "normal",
        level = 1,
        experience = 0,
        stats = table.clone(petData.baseStats),
        equipped = false,
        locked = false,
        createdAt = os.time(),
        ownerId = owner
    }
end

-- ========================================
-- CASE/EGG OPENING SYSTEM
-- ========================================
local EggTypes = {
    basic = {
        price = 100,
        currency = "coins",
        pets = {
            {id = "hello_kitty_classic", weight = 70},
            {id = "kuromi_shadow", weight = 25},
            {id = "cinnamoroll_cloud", weight = 5}
        }
    },
    rare = {
        price = 500,
        currency = "coins",
        pets = {
            {id = "kuromi_shadow", weight = 60},
            {id = "cinnamoroll_cloud", weight = 35},
            {id = "my_melody_angel", weight = 5}
        }
    },
    legendary = {
        price = 100,
        currency = "gems",
        pets = {
            {id = "cinnamoroll_cloud", weight = 70},
            {id = "my_melody_angel", weight = 30}
        }
    }
}

local function GetRandomPetFromEgg(eggType)
    local egg = EggTypes[eggType]
    if not egg then return nil end
    
    local totalWeight = 0
    for _, pet in ipairs(egg.pets) do
        totalWeight = totalWeight + pet.weight
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for _, pet in ipairs(egg.pets) do
        currentWeight = currentWeight + pet.weight
        if random <= currentWeight then
            return pet.id
        end
    end
    
    return egg.pets[1].id
end

-- ========================================
-- REMOTE HANDLERS
-- ========================================
RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
    return PlayerData[player.UserId]
end

RemoteFunctions.SaveSettings.OnServerInvoke = function(player, settings)
    local data = PlayerData[player.UserId]
    if data then
        data.settings = settings
        DeltaNetManager:SendUpdate(player, data)
        return true
    end
    return false
end

RemoteEvents.OpenCase.OnServerEvent:Connect(function(player, eggType)
    local data = PlayerData[player.UserId]
    if not data then return end
    
    local egg = EggTypes[eggType]
    if not egg then return end
    
    -- Check currency
    if data.currencies[egg.currency] < egg.price then
        RemoteEvents.NotificationSent:FireClient(player, {
            title = "Error",
            message = "Not enough " .. egg.currency,
            type = "error"
        })
        return
    end
    
    -- Deduct currency
    data.currencies[egg.currency] = data.currencies[egg.currency] - egg.price
    
    -- Get random pet
    local petId = GetRandomPetFromEgg(eggType)
    local variant = math.random() < 0.1 and "shiny" or "normal"
    
    -- Create pet instance
    local petInstance = CreatePetInstance(petId, variant, player.UserId)
    
    -- Add to player's pets (as dictionary)
    data.pets[petInstance.instanceId] = petInstance
    
    -- Update statistics
    data.statistics.eggsOpened = data.statistics.eggsOpened + 1
    
    -- Send delta update
    DeltaNetManager:SendUpdate(player, data)
    
    -- Send case opened event
    RemoteEvents.DataUpdated:FireClient(player, {
        type = "caseOpened",
        pet = petInstance,
        eggType = eggType,
        timestamp = tick()
    })
end)

-- Debug functions (Studio only)
if RunService:IsStudio() then
    RemoteFunctions.DebugGiveCurrency.OnServerInvoke = function(player, currencyType, amount)
        local data = PlayerData[player.UserId]
        if not data then return false end
        
        if data.currencies[currencyType] then
            data.currencies[currencyType] = data.currencies[currencyType] + amount
            DeltaNetManager:SendUpdate(player, data)
            print("[DEBUG] Gave", player.Name, amount, currencyType)
            return true
        end
        
        return false
    end
end

-- ========================================
-- PLAYER LIFECYCLE
-- ========================================
Players.PlayerAdded:Connect(function(player)
    LoadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Save data
    SavePlayerData(player)
    
    -- Clean up with Janitor
    if PlayerJanitors[player] then
        PlayerJanitors[player]:Cleanup()
        PlayerJanitors[player] = nil
    end
    
    -- Untrack from delta networking
    DeltaNetManager:UntrackPlayer(player)
    
    -- Remove data
    PlayerData[player.UserId] = nil
end)

-- ========================================
-- SERVER SHUTDOWN HANDLING
-- ========================================
game:BindToClose(function()
    print("[Server] Shutting down, saving all player data...")
    
    local saveJobs = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(saveJobs, coroutine.create(function()
            SavePlayerData(player)
        end))
    end
    
    -- Run all saves in parallel
    for _, job in ipairs(saveJobs) do
        coroutine.resume(job)
    end
    
    -- Wait for saves to complete (max 30 seconds)
    local startTime = tick()
    while tick() - startTime < 30 do
        local allDone = true
        for _, job in ipairs(saveJobs) do
            if coroutine.status(job) ~= "dead" then
                allDone = false
                break
            end
        end
        if allDone then break end
        wait(0.1)
    end
    
    print("[Server] Shutdown complete")
end)

print("[SanrioTycoon] Advanced Server v" .. CONFIG.VERSION .. " initialized")
print("[SanrioTycoon] Delta Networking: ENABLED")
print("[SanrioTycoon] Memory Management: JANITOR")
print("[SanrioTycoon] Data Structure: OPTIMIZED")