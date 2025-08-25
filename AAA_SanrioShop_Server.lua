-- AAA Sanrio Tycoon Shop System - Server Side
-- Professional implementation without emoji spam

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    DataStoreService = game:GetService("DataStoreService"),
    MarketplaceService = game:GetService("MarketplaceService"),
    HttpService = game:GetService("HttpService"),
    RunService = game:GetService("RunService")
}

-- Constants
local CONSTANTS = {
    DATASTORE_VERSION = "SanrioShopV2",
    SAVE_INTERVAL = 30,
    MAX_BOOST_STACK = 3,
    
    -- Currency Types
    CURRENCY = {
        CASH = "Cash",
        GEMS = "Gems", 
        TOKENS = "Tokens"
    },
    
    -- Item Rarities
    RARITY = {
        COMMON = {name = "Common", weight = 70, color = Color3.fromRGB(176, 176, 176)},
        RARE = {name = "Rare", weight = 25, color = Color3.fromRGB(85, 170, 255)},
        EPIC = {name = "Epic", weight = 4, color = Color3.fromRGB(163, 53, 238)},
        LEGENDARY = {name = "Legendary", weight = 0.9, color = Color3.fromRGB(255, 170, 0)},
        MYTHIC = {name = "Mythic", weight = 0.1, color = Color3.fromRGB(255, 0, 128)}
    }
}

-- Initialize Remotes
local Remotes = Instance.new("Folder")
Remotes.Name = "ShopRemotes"
Remotes.Parent = Services.ReplicatedStorage

local RemoteEvents = {
    PurchaseItem = Instance.new("RemoteEvent", Remotes),
    OpenCase = Instance.new("RemoteEvent", Remotes),
    ActivateBoost = Instance.new("RemoteEvent", Remotes),
    ClaimDaily = Instance.new("RemoteEvent", Remotes)
}

local RemoteFunctions = {
    GetShopData = Instance.new("RemoteFunction", Remotes),
    GetPlayerData = Instance.new("RemoteFunction", Remotes),
    GetCaseContents = Instance.new("RemoteFunction", Remotes)
}

-- Name remotes
for name, remote in pairs(RemoteEvents) do
    remote.Name = name
end
for name, remote in pairs(RemoteFunctions) do
    remote.Name = name
end

-- DataStore
local DataStore = Services.DataStoreService:GetDataStore(CONSTANTS.DATASTORE_VERSION)

-- Player Data Cache
local PlayerDataCache = {}

-- Shop Configuration
local SHOP_CONFIG = {
    GAMEPASSES = {
        {
            id = 123456789,
            name = "VIP Membership",
            price = 399,
            benefits = {
                "2x Cash earnings",
                "1.5x Gem rewards",
                "Exclusive VIP area access",
                "Special VIP chat tag",
                "10% shop discount",
                "Daily VIP bonus"
            },
            icon = "rbxassetid://ACTUAL_VIP_ICON_ID"
        },
        {
            id = 123456790,
            name = "Auto Collector",
            price = 199,
            benefits = {
                "Automatic cash collection",
                "No manual clicking required",
                "Works while AFK"
            },
            icon = "rbxassetid://ACTUAL_AUTO_ICON_ID"
        },
        {
            id = 123456791,
            name = "Double Cash",
            price = 499,
            benefits = {
                "Permanent 2x cash multiplier",
                "Stacks with other boosts"
            },
            icon = "rbxassetid://ACTUAL_2X_ICON_ID"
        }
    },
    
    BOOSTS = {
        {
            id = "boost_2x_5min",
            name = "2x Cash - 5 Minutes",
            duration = 300,
            multiplier = 2,
            price = {type = CONSTANTS.CURRENCY.GEMS, amount = 50},
            icon = "rbxassetid://ACTUAL_BOOST_ICON_ID"
        },
        {
            id = "boost_2x_1hour", 
            name = "2x Cash - 1 Hour",
            duration = 3600,
            multiplier = 2,
            price = {type = CONSTANTS.CURRENCY.GEMS, amount = 200},
            icon = "rbxassetid://ACTUAL_BOOST_ICON_ID"
        },
        {
            id = "boost_3x_15min",
            name = "3x Cash - 15 Minutes",
            duration = 900,
            multiplier = 3,
            price = {type = CONSTANTS.CURRENCY.GEMS, amount = 150},
            icon = "rbxassetid://ACTUAL_3X_ICON_ID"
        }
    },
    
    CASES = {
        {
            id = "case_basic",
            name = "Basic Case",
            price = {type = CONSTANTS.CURRENCY.CASH, amount = 1000},
            icon = "rbxassetid://ACTUAL_BASIC_CASE_ID",
            contents = {} -- Populated dynamically
        },
        {
            id = "case_premium",
            name = "Premium Case", 
            price = {type = CONSTANTS.CURRENCY.GEMS, amount = 100},
            icon = "rbxassetid://ACTUAL_PREMIUM_CASE_ID",
            contents = {} -- Populated dynamically
        },
        {
            id = "case_ultimate",
            name = "Ultimate Case",
            price = {type = CONSTANTS.CURRENCY.GEMS, amount = 500},
            icon = "rbxassetid://ACTUAL_ULTIMATE_CASE_ID",
            contents = {} -- Populated dynamically
        }
    }
}

-- Case Loot Tables
local CASE_LOOT = {
    case_basic = {
        {itemId = "decoration_basic_floor", rarity = "COMMON", name = "Basic Floor"},
        {itemId = "decoration_pink_walls", rarity = "COMMON", name = "Pink Walls"},
        {itemId = "furniture_basic_table", rarity = "COMMON", name = "Basic Table"},
        {itemId = "worker_trainee", rarity = "RARE", name = "Trainee Worker"},
        {itemId = "decoration_neon_sign", rarity = "RARE", name = "Neon Sign"},
        {itemId = "boost_instant_cash", rarity = "EPIC", name = "Instant Cash"}
    },
    case_premium = {
        {itemId = "worker_hello_kitty", rarity = "RARE", name = "Hello Kitty Worker"},
        {itemId = "decoration_premium_floor", rarity = "RARE", name = "Premium Floor"},
        {itemId = "furniture_vip_booth", rarity = "EPIC", name = "VIP Booth"},
        {itemId = "worker_my_melody", rarity = "EPIC", name = "My Melody Worker"},
        {itemId = "effect_rainbow_trail", rarity = "LEGENDARY", name = "Rainbow Trail"},
        {itemId = "multiplier_permanent_1.5x", rarity = "LEGENDARY", name = "1.5x Multiplier"}
    },
    case_ultimate = {
        {itemId = "worker_kuromi_special", rarity = "EPIC", name = "Kuromi Special"},
        {itemId = "decoration_crystal_chandelier", rarity = "EPIC", name = "Crystal Chandelier"},
        {itemId = "furniture_golden_set", rarity = "LEGENDARY", name = "Golden Furniture Set"},
        {itemId = "effect_aura_legendary", rarity = "LEGENDARY", name = "Legendary Aura"},
        {itemId = "multiplier_permanent_2x", rarity = "MYTHIC", name = "2x Permanent Multiplier"},
        {itemId = "exclusive_sanrio_statue", rarity = "MYTHIC", name = "Exclusive Sanrio Statue"}
    }
}

-- Player Data Structure
local function createNewPlayerData()
    return {
        currencies = {
            [CONSTANTS.CURRENCY.CASH] = 5000,
            [CONSTANTS.CURRENCY.GEMS] = 50,
            [CONSTANTS.CURRENCY.TOKENS] = 0
        },
        inventory = {
            items = {},
            equipped = {}
        },
        boosts = {
            active = {},
            queue = {}
        },
        statistics = {
            totalSpent = 0,
            casesOpened = 0,
            pityCounter = {
                basic = 0,
                premium = 0,
                ultimate = 0
            },
            lastDaily = 0,
            dailyStreak = 0
        },
        gamepasses = {},
        settings = {
            musicEnabled = true,
            sfxEnabled = true,
            particlesEnabled = true
        }
    }
end

-- Data Management
local function loadPlayerData(player)
    local key = "Player_" .. player.UserId
    local success, data = pcall(function()
        return DataStore:GetAsync(key)
    end)
    
    if success and data then
        -- Validate and migrate data if needed
        PlayerDataCache[player.UserId] = data
    else
        PlayerDataCache[player.UserId] = createNewPlayerData()
    end
    
    return PlayerDataCache[player.UserId]
end

local function savePlayerData(player)
    local data = PlayerDataCache[player.UserId]
    if not data then return end
    
    local key = "Player_" .. player.UserId
    local success, err = pcall(function()
        DataStore:SetAsync(key, data)
    end)
    
    if not success then
        warn("Failed to save data for", player.Name, "-", err)
    end
end

-- Currency Management
local function getCurrency(player, currencyType)
    local data = PlayerDataCache[player.UserId]
    if not data then return 0 end
    return data.currencies[currencyType] or 0
end

local function addCurrency(player, currencyType, amount)
    local data = PlayerDataCache[player.UserId]
    if not data then return false end
    
    data.currencies[currencyType] = (data.currencies[currencyType] or 0) + amount
    
    -- Fire update to client
    RemoteEvents.PurchaseItem:FireClient(player, "CurrencyUpdate", {
        [currencyType] = data.currencies[currencyType]
    })
    
    return true
end

local function removeCurrency(player, currencyType, amount)
    local data = PlayerDataCache[player.UserId]
    if not data then return false end
    
    local current = data.currencies[currencyType] or 0
    if current < amount then return false end
    
    data.currencies[currencyType] = current - amount
    
    -- Fire update to client
    RemoteEvents.PurchaseItem:FireClient(player, "CurrencyUpdate", {
        [currencyType] = data.currencies[currencyType]
    })
    
    return true
end

-- Purchase Validation
local function canAfford(player, price)
    return getCurrency(player, price.type) >= price.amount
end

-- Boost System
local function activateBoost(player, boostId)
    local data = PlayerDataCache[player.UserId]
    if not data then return false, "No data" end
    
    local boostConfig = nil
    for _, boost in ipairs(SHOP_CONFIG.BOOSTS) do
        if boost.id == boostId then
            boostConfig = boost
            break
        end
    end
    
    if not boostConfig then return false, "Invalid boost" end
    
    -- Check if can afford
    if not canAfford(player, boostConfig.price) then
        return false, "Insufficient funds"
    end
    
    -- Check boost stack limit
    local activeBoosts = 0
    for _, boost in ipairs(data.boosts.active) do
        if boost.endTime > os.time() then
            activeBoosts = activeBoosts + 1
        end
    end
    
    if activeBoosts >= CONSTANTS.MAX_BOOST_STACK then
        -- Add to queue
        table.insert(data.boosts.queue, {
            id = boostId,
            multiplier = boostConfig.multiplier,
            duration = boostConfig.duration
        })
        return true, "Queued"
    end
    
    -- Remove currency
    removeCurrency(player, boostConfig.price.type, boostConfig.price.amount)
    
    -- Activate boost
    table.insert(data.boosts.active, {
        id = boostId,
        multiplier = boostConfig.multiplier,
        startTime = os.time(),
        endTime = os.time() + boostConfig.duration
    })
    
    return true, "Activated"
end

-- Case Opening System
local function calculateCaseContents(caseId)
    local lootTable = CASE_LOOT[caseId]
    if not lootTable then return nil end
    
    local contents = {}
    local totalWeight = 0
    
    -- Calculate total weight
    for _, item in ipairs(lootTable) do
        local rarityData = CONSTANTS.RARITY[item.rarity]
        if rarityData then
            totalWeight = totalWeight + rarityData.weight
        end
    end
    
    -- Generate 100 items for the scroll
    for i = 1, 100 do
        local roll = math.random() * totalWeight
        local currentWeight = 0
        
        for _, item in ipairs(lootTable) do
            local rarityData = CONSTANTS.RARITY[item.rarity]
            if rarityData then
                currentWeight = currentWeight + rarityData.weight
                if roll <= currentWeight then
                    table.insert(contents, {
                        itemId = item.itemId,
                        name = item.name,
                        rarity = item.rarity,
                        icon = "rbxassetid://ITEM_ICON_" .. item.itemId
                    })
                    break
                end
            end
        end
    end
    
    return contents
end

local function openCase(player, caseId)
    local data = PlayerDataCache[player.UserId]
    if not data then return false, "No data" end
    
    local caseConfig = nil
    for _, case in ipairs(SHOP_CONFIG.CASES) do
        if case.id == caseId then
            caseConfig = case
            break
        end
    end
    
    if not caseConfig then return false, "Invalid case" end
    
    -- Check if can afford
    if not canAfford(player, caseConfig.price) then
        return false, "Insufficient funds"
    end
    
    -- Remove currency
    removeCurrency(player, caseConfig.price.type, caseConfig.price.amount)
    
    -- Generate case contents
    local contents = calculateCaseContents(caseId)
    if not contents then return false, "Failed to generate contents" end
    
    -- Determine winner (position 85-95 for suspense)
    local winnerIndex = math.random(85, 95)
    local wonItem = contents[winnerIndex]
    
    -- Apply pity system if needed
    local pityType = caseId:gsub("case_", "")
    data.statistics.pityCounter[pityType] = data.statistics.pityCounter[pityType] + 1
    
    -- Check for pity
    if data.statistics.pityCounter[pityType] >= 10 and wonItem.rarity == "COMMON" then
        -- Force better item
        for i, item in ipairs(contents) do
            if item.rarity == "EPIC" or item.rarity == "LEGENDARY" then
                wonItem = item
                winnerIndex = i
                break
            end
        end
        data.statistics.pityCounter[pityType] = 0
    end
    
    -- Add to inventory
    table.insert(data.inventory.items, {
        itemId = wonItem.itemId,
        name = wonItem.name,
        rarity = wonItem.rarity,
        obtainedAt = os.time(),
        source = caseId
    })
    
    -- Update statistics
    data.statistics.casesOpened = data.statistics.casesOpened + 1
    
    -- If rare item, reset pity
    if wonItem.rarity == "EPIC" or wonItem.rarity == "LEGENDARY" or wonItem.rarity == "MYTHIC" then
        data.statistics.pityCounter[pityType] = 0
    end
    
    return true, {
        contents = contents,
        winnerIndex = winnerIndex,
        wonItem = wonItem
    }
end

-- Remote Handlers
RemoteFunctions.GetShopData.OnServerInvoke = function(player)
    return SHOP_CONFIG
end

RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
    return PlayerDataCache[player.UserId]
end

RemoteFunctions.GetCaseContents.OnServerInvoke = function(player, caseId)
    return calculateCaseContents(caseId)
end

RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemType, itemId)
    if itemType == "gamepass" then
        -- Handle gamepass purchase
        for _, pass in ipairs(SHOP_CONFIG.GAMEPASSES) do
            if pass.id == itemId then
                Services.MarketplaceService:PromptGamePassPurchase(player, pass.id)
                break
            end
        end
    elseif itemType == "boost" then
        local success, result = activateBoost(player, itemId)
        RemoteEvents.PurchaseItem:FireClient(player, "BoostResult", {
            success = success,
            message = result
        })
    end
end)

RemoteEvents.OpenCase.OnServerEvent:Connect(function(player, caseId)
    local success, result = openCase(player, caseId)
    RemoteEvents.OpenCase:FireClient(player, "CaseResult", {
        success = success,
        data = result
    })
end)

-- Player Management
Services.Players.PlayerAdded:Connect(function(player)
    loadPlayerData(player)
    
    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local cash = Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Value = getCurrency(player, CONSTANTS.CURRENCY.CASH)
    cash.Parent = leaderstats
    
    -- Update display
    spawn(function()
        while player.Parent do
            wait(1)
            cash.Value = getCurrency(player, CONSTANTS.CURRENCY.CASH)
        end
    end)
end)

Services.Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    PlayerDataCache[player.UserId] = nil
end)

-- Auto Save
spawn(function()
    while true do
        wait(CONSTANTS.SAVE_INTERVAL)
        for _, player in ipairs(Services.Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

print("AAA Sanrio Shop System Initialized")