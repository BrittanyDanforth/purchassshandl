--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - DATASTORE MODULE                              ║
    ║                           Handles all data persistence                               ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local DataStoreModule = {}

-- Services
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Dependencies
local Configuration = require(script.Parent.Configuration)

-- DataStores
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v5")
local BackupDataStore = DataStoreService:GetDataStore("PlayerBackup_v5")
local ClanDataStore = DataStoreService:GetDataStore("ClanData_v1")
local BannedDataStore = DataStoreService:GetDataStore("BannedPlayers_v1")
local GlobalDataStore = DataStoreService:GetDataStore("GlobalData_v1")

-- Local Storage
DataStoreModule.PlayerData = {}
DataStoreModule.ClanData = {}
DataStoreModule.DirtyPlayers = {}
DataStoreModule.DirtyClans = {}

-- ========================================
-- DEFAULT PLAYER DATA TEMPLATE
-- ========================================
function DataStoreModule:GetDefaultPlayerData()
    return {
        -- Basic Info
        username = "",
        userId = 0,
        joinDate = os.time(),
        lastSeen = os.time(),
        playtime = 0,
        
        -- Currencies
        currencies = {
            coins = Configuration.CONFIG.STARTING_COINS,
            gems = Configuration.CONFIG.STARTING_GEMS,
            tickets = 0,
            eventTokens = 0,
            battlePoints = 0,
            clanCoins = 0
        },
        
        -- Pet Inventory (Dictionary for O(1) lookup)
        pets = {}, -- {[petId] = petData}
        petCount = 0,
        maxPetStorage = Configuration.CONFIG.MAX_INVENTORY_SIZE,
        equippedPets = {},
        petCollection = {}, -- Track unique pets obtained
        
        -- Statistics
        statistics = {
            totalEggsOpened = 0,
            totalPetsHatched = 0,
            legendaryPetsFound = 0,
            mythicalPetsFound = 0,
            secretPetsFound = 0,
            totalCoinsEarned = 0,
            totalGemsEarned = 0,
            totalGemsSpent = 0,
            highestPetRarity = 0,
            totalPetsSold = 0,
            totalPetsEvolved = 0,
            totalPetsFused = 0,
            PlayTime = 0,
            eggStatistics = {},
            tradingStats = {
                tradesCompleted = 0,
                tradesDeclined = 0,
                totalTradeValue = 0,
                scamReports = 0,
                tradePartners = {}
            },
            battleStats = {
                wins = 0,
                losses = 0,
                draws = 0,
                winStreak = 0,
                highestWinStreak = 0,
                totalDamageDealt = 0,
                totalDamageReceived = 0,
                battlesStarted = 0
            }
        },
        
        -- Owned Gamepasses
        ownedGamepasses = {},
        
        -- Achievements
        achievements = {},
        titles = {
            equipped = "Newbie",
            owned = {"Newbie"}
        },
        
        -- Daily Rewards
        dailyReward = {
            lastClaim = 0,
            streak = 0,
            day = 1
        },
        
        -- Quests
        quests = {
            daily = {},
            weekly = {},
            special = {},
            completed = {}
        },
        
        -- Battle Pass
        battlePass = {
            tier = 1,
            xp = 0,
            claimed = {},
            purchased = false
        },
        
        -- Clan
        clan = {
            id = nil,
            role = nil,
            contribution = 0,
            joinDate = nil
        },
        
        -- Settings
        settings = {
            musicEnabled = true,
            sfxEnabled = true,
            notifications = true,
            trading = true,
            lowQuality = false,
            autoSave = true
        },
        
        -- Security
        security = {
            lastLoginTime = os.time(),
            suspiciousActivity = 0,
            warnings = 0,
            banned = false,
            banReason = nil,
            banExpiry = nil
        },
        
        -- Group Status
        inGroup = false,
        groupRank = 0,
        
        -- Rebirth
        rebirths = 0,
        rebirthTokens = 0,
        rebirthMultiplier = 1
    }
end

-- ========================================
-- DEEP MERGE FUNCTION
-- ========================================
local function DeepMerge(template, data)
    if type(template) ~= "table" then return data or template end
    if type(data) ~= "table" then return template end
    
    local result = {}
    
    -- First, copy all template values
    for key, value in pairs(template) do
        if type(value) == "table" then
            result[key] = DeepMerge(value, data[key])
        else
            result[key] = data[key] ~= nil and data[key] or value
        end
    end
    
    -- Then, preserve any extra data that's not in template
    for key, value in pairs(data) do
        if result[key] == nil then
            result[key] = value
        end
    end
    
    return result
end

-- ========================================
-- SAVE PLAYER DATA
-- ========================================
function DataStoreModule:SavePlayerData(player)
    local userId = player.UserId
    local data = self.PlayerData[userId]
    
    if not data then
        warn("[DataStore] No data to save for", player.Name)
        return false
    end
    
    -- Update last seen
    data.lastSeen = os.time()
    
    -- Attempt to save with retries
    local attempts = 0
    local success = false
    local errorMsg = nil
    
    while attempts < Configuration.CONFIG.DATA_RETRY_ATTEMPTS and not success do
        attempts = attempts + 1
        
        success, errorMsg = pcall(function()
            PlayerDataStore:SetAsync(tostring(userId), data)
        end)
        
        if not success then
            warn("[DataStore] Save attempt", attempts, "failed for", player.Name, ":", errorMsg)
            if attempts < Configuration.CONFIG.DATA_RETRY_ATTEMPTS then
                wait(Configuration.CONFIG.DATA_RETRY_DELAY)
            end
        end
    end
    
    if success then
        -- Clear dirty flag
        self.DirtyPlayers[userId] = nil
        
        -- Create backup every 5th save
        if math.random(1, 5) == 1 then
            local backupSuccess, backupError = pcall(function()
                BackupDataStore:SetAsync(tostring(userId) .. "_" .. os.date("%Y%m%d"), data)
            end)
            if not backupSuccess then
                warn("[DataStore] Backup failed for", player.Name, ":", backupError)
            end
        end
        
        return true
    else
        warn("[DataStore] CRITICAL: Failed to save data for", player.Name, "after", attempts, "attempts")
        
        -- Log to server for monitoring
        if errorMsg then
            print("[DataStore] Last error:", errorMsg)
        end
        
        -- Notify player of save failure
        local RemoteEvents = game.ReplicatedStorage:FindFirstChild("RemoteEvents")
        if RemoteEvents and RemoteEvents:FindFirstChild("SystemNotification") then
            RemoteEvents.SystemNotification:FireClient(player, {
                title = "Save Warning",
                message = "Your data failed to save. Please rejoin to prevent data loss.",
                type = "error",
                duration = 10
            })
        end
        
        -- Add to critical failure tracking
        if not self.CriticalFailures then
            self.CriticalFailures = {}
        end
        self.CriticalFailures[userId] = {
            timestamp = os.time(),
            attempts = attempts,
            lastError = errorMsg
        }
        
        return false
    end
end

-- ========================================
-- LOAD PLAYER DATA
-- ========================================
function DataStoreModule:LoadPlayerData(player)
    local userId = player.UserId
    local data = nil
    local success = false
    local attempts = 0
    
    -- Try to load data with retries
    while attempts < Configuration.CONFIG.DATA_RETRY_ATTEMPTS and not success do
        attempts = attempts + 1
        
        success = pcall(function()
            data = PlayerDataStore:GetAsync(tostring(userId))
        end)
        
        if not success and attempts < Configuration.CONFIG.DATA_RETRY_ATTEMPTS then
            wait(Configuration.CONFIG.DATA_RETRY_DELAY)
        end
    end
    
    -- If no data exists, create new
    if not data then
        data = self:GetDefaultPlayerData()
        data.username = player.Name
        data.userId = userId
    else
        -- Merge with default to ensure all fields exist
        data = DeepMerge(self:GetDefaultPlayerData(), data)
        data.username = player.Name -- Update username in case it changed
    end
    
    -- Store in memory
    self.PlayerData[userId] = data
    
    print("[DataStore] Loaded data for", player.Name, "- Currencies:", data.currencies)
    
    return data
end

-- Get player data from memory
function DataStoreModule:GetPlayerData(player)
    return self.PlayerData[player.UserId]
end

-- ========================================
-- MARK DATA AS DIRTY
-- ========================================
-- Track last dirty mark time to prevent spam
DataStoreModule.LastDirtyMark = {}

function DataStoreModule:MarkPlayerDirty(userId)
    -- Rate limit dirty marks to once per second per player
    local now = tick()
    local lastMark = self.LastDirtyMark[userId] or 0
    
    if now - lastMark < 1 then
        return -- Ignore if marked dirty less than 1 second ago
    end
    
    self.LastDirtyMark[userId] = now
    self.DirtyPlayers[userId] = true
end

function DataStoreModule:MarkClanDirty(clanId)
    self.DirtyClans[clanId] = true
end

-- ========================================
-- DATA ACCESS METHODS
-- ========================================
function DataStoreModule:GetPlayerData(player)
    if not player then return nil end
    
    local userId = typeof(player) == "Instance" and player.UserId or player
    return self.PlayerData[userId]
end

function DataStoreModule:UpdatePlayerData(player, path, value)
    local playerData = self:GetPlayerData(player)
    if not playerData then return false end
    
    -- Navigate to the path
    local current = playerData
    local keys = string.split(path, ".")
    
    for i = 1, #keys - 1 do
        local key = keys[i]
        if not current[key] then
            current[key] = {}
        end
        current = current[key]
    end
    
    -- Set the value
    current[keys[#keys]] = value
    
    -- Mark as dirty
    self:MarkPlayerDirty(player.UserId)
    
    return true
end

-- ========================================
-- AUTO-SAVE SYSTEM
-- ========================================
function DataStoreModule:StartAutoSave()
    spawn(function()
        while true do
            wait(Configuration.CONFIG.DATA_AUTOSAVE_INTERVAL)
            
            -- Batch save dirty players to reduce throttling
            local playersToSave = {}
            local savedCount = 0
            
            -- Collect players to save
            for userId, _ in pairs(self.DirtyPlayers) do
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    table.insert(playersToSave, player)
                else
                    -- Player left, remove from dirty list
                    self.DirtyPlayers[userId] = nil
                end
            end
            
            -- Save with delay between each to prevent throttling
            for i, player in ipairs(playersToSave) do
                if self:SavePlayerData(player) then
                    savedCount = savedCount + 1
                end
                -- Small delay between saves to prevent throttling
                if i < #playersToSave then
                    wait(0.5)
                end
            end
            
            if savedCount > 0 then
                print("[AutoSave] Saved", savedCount, "player(s)")
            end
            
            -- Save dirty clans
            local clanCount = 0
            for clanId, _ in pairs(self.DirtyClans) do
                local clan = self.ClanData[clanId]
                if clan then
                    local success = pcall(function()
                        ClanDataStore:SetAsync(clanId, clan)
                    end)
                    if success then
                        self.DirtyClans[clanId] = nil
                        clanCount = clanCount + 1
                    end
                else
                    self.DirtyClans[clanId] = nil
                end
            end
            
            if clanCount > 0 then
                print("[AutoSave] Saved", clanCount, "clan(s)")
            end
        end
    end)
end

-- ========================================
-- CLAN DATA MANAGEMENT
-- ========================================
function DataStoreModule:LoadClanData(clanId)
    local data = nil
    local success = pcall(function()
        data = ClanDataStore:GetAsync(clanId)
    end)
    
    if success and data then
        self.ClanData[clanId] = data
        return data
    end
    
    return nil
end

function DataStoreModule:SaveClanData(clanId)
    local data = self.ClanData[clanId]
    if not data then return false end
    
    local success = pcall(function()
        ClanDataStore:SetAsync(clanId, data)
    end)
    
    if success then
        self.DirtyClans[clanId] = nil
    end
    
    return success
end

function DataStoreModule:CreateClan(name, leader)
    local clanId = HttpService:GenerateGUID(false)
    
    local clanData = {
        id = clanId,
        name = name,
        description = "A new clan",
        leaderId = leader.UserId,
        members = {
            [tostring(leader.UserId)] = {
                userId = leader.UserId,
                username = leader.Name,
                role = "Leader",
                joinDate = os.time(),
                contribution = 0
            }
        },
        treasury = {
            coins = 0,
            gems = 0
        },
        level = 1,
        xp = 0,
        created = os.time(),
        settings = {
            public = true,
            minLevel = 1,
            requireApproval = false
        },
        upgrades = {},
        wars = {
            wins = 0,
            losses = 0,
            current = nil
        }
    }
    
    self.ClanData[clanId] = clanData
    self:MarkClanDirty(clanId)
    
    return clanData
end

-- ========================================
-- BAN MANAGEMENT
-- ========================================
function DataStoreModule:BanPlayer(userId, reason, duration)
    local banData = {
        userId = userId,
        reason = reason,
        bannedAt = os.time(),
        duration = duration,
        expiresAt = duration and (os.time() + duration) or nil
    }
    
    pcall(function()
        BannedDataStore:SetAsync(tostring(userId), banData)
    end)
    
    -- Update player data if loaded
    local playerData = self.PlayerData[userId]
    if playerData then
        playerData.security.banned = true
        playerData.security.banReason = reason
        playerData.security.banExpiry = banData.expiresAt
        self:MarkPlayerDirty(userId)
    end
    
    return true
end

function DataStoreModule:UnbanPlayer(userId)
    pcall(function()
        BannedDataStore:RemoveAsync(tostring(userId))
    end)
    
    -- Update player data if loaded
    local playerData = self.PlayerData[userId]
    if playerData then
        playerData.security.banned = false
        playerData.security.banReason = nil
        playerData.security.banExpiry = nil
        self:MarkPlayerDirty(userId)
    end
    
    return true
end

function DataStoreModule:IsPlayerBanned(userId)
    local banData = nil
    local success = pcall(function()
        banData = BannedDataStore:GetAsync(tostring(userId))
    end)
    
    if success and banData then
        -- Check if ban has expired
        if banData.expiresAt and os.time() >= banData.expiresAt then
            self:UnbanPlayer(userId)
            return false, nil
        end
        return true, banData
    end
    
    return false, nil
end

-- ========================================
-- GLOBAL DATA
-- ========================================
function DataStoreModule:GetGlobalData(key)
    local data = nil
    pcall(function()
        data = GlobalDataStore:GetAsync(key)
    end)
    return data
end

function DataStoreModule:SetGlobalData(key, value)
    local success = pcall(function()
        GlobalDataStore:SetAsync(key, value)
    end)
    return success
end

-- ========================================
-- CLEANUP
-- ========================================
function DataStoreModule:CleanupPlayer(player)
    local userId = player.UserId
    
    -- Save data one last time
    self:SavePlayerData(player)
    
    -- Remove from memory
    self.PlayerData[userId] = nil
    self.DirtyPlayers[userId] = nil
end

return DataStoreModule