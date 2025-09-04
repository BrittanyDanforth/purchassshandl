-- ========================================
-- CLAN SYSTEM MODULE
-- Complete clan/guild system with features
-- ========================================

local ClanSystem = {}

-- Dependencies
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Constants
local CLAN_VERSION = 1
local MAX_CLAN_MEMBERS = 50
local MIN_CLAN_NAME_LENGTH = 3
local MAX_CLAN_NAME_LENGTH = 20
local MIN_CLAN_TAG_LENGTH = 2
local MAX_CLAN_TAG_LENGTH = 5
local CLAN_CREATION_COST = 50000 -- 50k coins
local MAX_CLAN_BANK = 10000000 -- 10M

-- Clan ranks
local RANKS = {
    LEADER = 5,
    CO_LEADER = 4,
    ELDER = 3,
    MEMBER = 2,
    RECRUIT = 1
}

local RANK_NAMES = {
    [RANKS.LEADER] = "Leader",
    [RANKS.CO_LEADER] = "Co-Leader",
    [RANKS.ELDER] = "Elder",
    [RANKS.MEMBER] = "Member",
    [RANKS.RECRUIT] = "Recruit"
}

-- Permissions
local PERMISSIONS = {
    KICK = {RANKS.LEADER, RANKS.CO_LEADER},
    INVITE = {RANKS.LEADER, RANKS.CO_LEADER, RANKS.ELDER},
    PROMOTE = {RANKS.LEADER, RANKS.CO_LEADER},
    BANK_WITHDRAW = {RANKS.LEADER, RANKS.CO_LEADER},
    EDIT_INFO = {RANKS.LEADER, RANKS.CO_LEADER},
    START_WAR = {RANKS.LEADER}
}

-- Initialize
function ClanSystem:Init()
    self.Configuration = _G.Configuration
    self.DataStoreModule = _G.DataStoreModule
    
    -- Clan data
    self.Clans = {}
    self.PlayerClans = {} -- userId -> clanId
    self.ClanInvites = {} -- userId -> {clanId -> inviteData}
    self.ClanWars = {}
    
    -- DataStores
    self.ClanDataStore = DataStoreService:GetDataStore("ClanDataV" .. CLAN_VERSION)
    self.ClanMemberStore = DataStoreService:GetDataStore("ClanMembersV" .. CLAN_VERSION)
    
    -- Load existing clans
    self:LoadClans()
    
    -- Leaderboard update loop
    spawn(function()
        while true do
            wait(300) -- Update every 5 minutes
            self:UpdateClanLeaderboards()
        end
    end)
    
    -- War check loop
    spawn(function()
        while true do
            wait(60) -- Check every minute
            self:CheckWarStatus()
        end
    end)
    
    print("[ClanSystem] Initialized")
end

-- ========================================
-- CLAN MANAGEMENT
-- ========================================

function ClanSystem:CreateClan(player, clanName, clanTag, description)
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    -- Check if player is already in a clan
    if self.PlayerClans[player.UserId] then
        return {success = false, error = "You are already in a clan"}
    end
    
    -- Validate clan name
    clanName = clanName:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
    if #clanName < MIN_CLAN_NAME_LENGTH or #clanName > MAX_CLAN_NAME_LENGTH then
        return {success = false, error = "Clan name must be " .. MIN_CLAN_NAME_LENGTH .. "-" .. MAX_CLAN_NAME_LENGTH .. " characters"}
    end
    
    -- Validate clan tag
    clanTag = clanTag:upper():gsub("%s", "")
    if #clanTag < MIN_CLAN_TAG_LENGTH or #clanTag > MAX_CLAN_TAG_LENGTH then
        return {success = false, error = "Clan tag must be " .. MIN_CLAN_TAG_LENGTH .. "-" .. MAX_CLAN_TAG_LENGTH .. " characters"}
    end
    
    -- Check if name or tag already exists
    for clanId, clan in pairs(self.Clans) do
        if clan.name:lower() == clanName:lower() then
            return {success = false, error = "Clan name already taken"}
        end
        if clan.tag == clanTag then
            return {success = false, error = "Clan tag already taken"}
        end
    end
    
    -- Check currency
    if playerData.currencies.coins < CLAN_CREATION_COST then
        return {success = false, error = "Need " .. CLAN_CREATION_COST .. " coins to create a clan"}
    end
    
    -- Deduct currency
    playerData.currencies.coins = playerData.currencies.coins - CLAN_CREATION_COST
    
    -- Create clan
    local clanId = HttpService:GenerateGUID(false)
    local clan = {
        id = clanId,
        name = clanName,
        tag = clanTag,
        description = description or "Welcome to our clan!",
        leaderId = player.UserId,
        createdAt = os.time(),
        level = 1,
        experience = 0,
        bank = 0,
        members = {
            [player.UserId] = {
                userId = player.UserId,
                username = player.Name,
                rank = RANKS.LEADER,
                joinedAt = os.time(),
                contributions = 0,
                lastActive = os.time()
            }
        },
        settings = {
            joinType = "open", -- open, invite, closed
            minLevel = 1,
            announcement = "",
            icon = "",
            primaryColor = Color3.fromRGB(255, 255, 255),
            secondaryColor = Color3.fromRGB(0, 0, 0)
        },
        statistics = {
            totalMembers = 1,
            warsWon = 0,
            warsLost = 0,
            totalDonations = 0,
            weeklyActivity = 0,
            trophies = 1000
        }
    }
    
    -- Add to system
    self.Clans[clanId] = clan
    self.PlayerClans[player.UserId] = clanId
    
    -- Update player data
    playerData.clan = {
        id = clanId,
        name = clanName,
        tag = clanTag,
        rank = RANKS.LEADER,
        joinedAt = os.time()
    }
    
    -- Save to DataStore
    self:SaveClan(clan)
    
    -- Mark player data dirty
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Fire events
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.ClanCreated:FireClient(player, clan)
    RemoteEvents.ClanUpdated:FireAllClients(clanId)
    
    return {
        success = true,
        clanId = clanId,
        clan = clan
    }
end

function ClanSystem:JoinClan(player, clanId)
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    -- Check if already in a clan
    if self.PlayerClans[player.UserId] then
        return {success = false, error = "You are already in a clan"}
    end
    
    local clan = self.Clans[clanId]
    if not clan then
        return {success = false, error = "Clan not found"}
    end
    
    -- Check member limit
    if clan.statistics.totalMembers >= MAX_CLAN_MEMBERS then
        return {success = false, error = "Clan is full"}
    end
    
    -- Check join requirements
    if clan.settings.joinType == "closed" then
        return {success = false, error = "Clan is closed"}
    end
    
    if clan.settings.joinType == "invite" then
        -- Check for invite
        local invites = self.ClanInvites[player.UserId]
        if not invites or not invites[clanId] then
            return {success = false, error = "You need an invitation to join this clan"}
        end
    end
    
    if playerData.level < clan.settings.minLevel then
        return {success = false, error = "Level " .. clan.settings.minLevel .. " required"}
    end
    
    -- Add member
    clan.members[player.UserId] = {
        userId = player.UserId,
        username = player.Name,
        rank = RANKS.RECRUIT,
        joinedAt = os.time(),
        contributions = 0,
        lastActive = os.time()
    }
    
    clan.statistics.totalMembers = clan.statistics.totalMembers + 1
    
    -- Update player
    self.PlayerClans[player.UserId] = clanId
    playerData.clan = {
        id = clanId,
        name = clan.name,
        tag = clan.tag,
        rank = RANKS.RECRUIT,
        joinedAt = os.time()
    }
    
    -- Clear any invites
    if self.ClanInvites[player.UserId] then
        self.ClanInvites[player.UserId][clanId] = nil
    end
    
    -- Save
    self:SaveClan(clan)
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Notify
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.ClanJoined:FireClient(player, clan)
    
    -- Notify clan members
    for memberId, _ in pairs(clan.members) do
        local member = Players:GetPlayerByUserId(memberId)
        if member and member ~= player then
            RemoteEvents.ClanMemberJoined:FireClient(member, player.Name)
        end
    end
    
    RemoteEvents.ClanUpdated:FireAllClients(clanId)
    
    return {success = true, clan = clan}
end

function ClanSystem:LeaveClan(player)
    local clanId = self.PlayerClans[player.UserId]
    if not clanId then
        return {success = false, error = "You are not in a clan"}
    end
    
    local clan = self.Clans[clanId]
    if not clan then
        return {success = false, error = "Clan not found"}
    end
    
    local member = clan.members[player.UserId]
    if not member then
        return {success = false, error = "Member data not found"}
    end
    
    -- Check if leader
    if member.rank == RANKS.LEADER then
        -- Find new leader (highest rank member)
        local newLeader = nil
        local highestRank = 0
        
        for userId, mem in pairs(clan.members) do
            if userId ~= player.UserId and mem.rank > highestRank then
                newLeader = mem
                highestRank = mem.rank
            end
        end
        
        if newLeader then
            -- Transfer leadership
            newLeader.rank = RANKS.LEADER
            clan.leaderId = newLeader.userId
            
            -- Notify new leader
            local newLeaderPlayer = Players:GetPlayerByUserId(newLeader.userId)
            if newLeaderPlayer then
                local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
                RemoteEvents.NotificationSent:FireClient(newLeaderPlayer, {
                    title = "Clan Leadership",
                    message = "You are now the clan leader!",
                    type = "success"
                })
            end
        else
            -- Disband clan if no members left
            self:DisbandClan(clanId)
            return {success = true, disbanded = true}
        end
    end
    
    -- Remove member
    clan.members[player.UserId] = nil
    clan.statistics.totalMembers = clan.statistics.totalMembers - 1
    
    -- Update player
    self.PlayerClans[player.UserId] = nil
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if playerData then
        playerData.clan = nil
        self.DataStoreModule:MarkPlayerDirty(player.UserId)
    end
    
    -- Save
    self:SaveClan(clan)
    
    -- Notify
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.ClanLeft:FireClient(player)
    
    -- Notify clan members
    for memberId, _ in pairs(clan.members) do
        local mem = Players:GetPlayerByUserId(memberId)
        if mem then
            RemoteEvents.ClanMemberLeft:FireClient(mem, player.Name)
        end
    end
    
    RemoteEvents.ClanUpdated:FireAllClients(clanId)
    
    return {success = true}
end

function ClanSystem:KickMember(player, targetUserId)
    local clanId = self.PlayerClans[player.UserId]
    if not clanId then
        return {success = false, error = "You are not in a clan"}
    end
    
    local clan = self.Clans[clanId]
    if not clan then
        return {success = false, error = "Clan not found"}
    end
    
    local member = clan.members[player.UserId]
    local targetMember = clan.members[targetUserId]
    
    if not member or not targetMember then
        return {success = false, error = "Member not found"}
    end
    
    -- Check permissions
    if not self:HasPermission(member.rank, "KICK") then
        return {success = false, error = "No permission to kick members"}
    end
    
    -- Cannot kick higher or equal rank
    if targetMember.rank >= member.rank then
        return {success = false, error = "Cannot kick members of equal or higher rank"}
    end
    
    -- Remove member
    clan.members[targetUserId] = nil
    clan.statistics.totalMembers = clan.statistics.totalMembers - 1
    
    -- Update kicked player
    self.PlayerClans[targetUserId] = nil
    local targetPlayerData = self.DataStoreModule:GetPlayerData(targetUserId)
    if targetPlayerData then
        targetPlayerData.clan = nil
        self.DataStoreModule:MarkPlayerDirty(targetUserId)
    end
    
    -- Save
    self:SaveClan(clan)
    
    -- Notify
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    
    if targetPlayer then
        RemoteEvents.ClanKicked:FireClient(targetPlayer, clan.name)
    end
    
    -- Notify clan members
    for memberId, _ in pairs(clan.members) do
        local mem = Players:GetPlayerByUserId(memberId)
        if mem then
            RemoteEvents.ClanMemberKicked:FireClient(mem, targetMember.username, player.Name)
        end
    end
    
    RemoteEvents.ClanUpdated:FireAllClients(clanId)
    
    return {success = true}
end

function ClanSystem:PromoteMember(player, targetUserId, newRank)
    local clanId = self.PlayerClans[player.UserId]
    if not clanId then
        return {success = false, error = "You are not in a clan"}
    end
    
    local clan = self.Clans[clanId]
    if not clan then
        return {success = false, error = "Clan not found"}
    end
    
    local member = clan.members[player.UserId]
    local targetMember = clan.members[targetUserId]
    
    if not member or not targetMember then
        return {success = false, error = "Member not found"}
    end
    
    -- Check permissions
    if not self:HasPermission(member.rank, "PROMOTE") then
        return {success = false, error = "No permission to promote members"}
    end
    
    -- Validate new rank
    if newRank < RANKS.RECRUIT or newRank > RANKS.CO_LEADER then
        return {success = false, error = "Invalid rank"}
    end
    
    -- Cannot promote to same or higher than own rank
    if newRank >= member.rank then
        return {success = false, error = "Cannot promote to your rank or higher"}
    end
    
    -- Cannot demote from higher rank than self
    if targetMember.rank >= member.rank then
        return {success = false, error = "Cannot modify members of equal or higher rank"}
    end
    
    local oldRank = targetMember.rank
    targetMember.rank = newRank
    
    -- Update player data
    local targetPlayerData = self.DataStoreModule:GetPlayerData(targetUserId)
    if targetPlayerData and targetPlayerData.clan then
        targetPlayerData.clan.rank = newRank
        self.DataStoreModule:MarkPlayerDirty(targetUserId)
    end
    
    -- Save
    self:SaveClan(clan)
    
    -- Notify
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    
    local action = newRank > oldRank and "promoted" or "demoted"
    
    if targetPlayer then
        RemoteEvents.NotificationSent:FireClient(targetPlayer, {
            title = "Rank Changed",
            message = "You were " .. action .. " to " .. RANK_NAMES[newRank],
            type = "info"
        })
    end
    
    RemoteEvents.ClanMemberPromoted:FireAllClients(clanId, targetMember.username, RANK_NAMES[newRank])
    RemoteEvents.ClanUpdated:FireAllClients(clanId)
    
    return {success = true}
end

-- ========================================
-- CLAN FEATURES
-- ========================================

function ClanSystem:DonateToClan(player, amount)
    local clanId = self.PlayerClans[player.UserId]
    if not clanId then
        return {success = false, error = "You are not in a clan"}
    end
    
    local clan = self.Clans[clanId]
    if not clan then
        return {success = false, error = "Clan not found"}
    end
    
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    -- Validate amount
    amount = math.floor(amount)
    if amount < 100 then
        return {success = false, error = "Minimum donation is 100 coins"}
    end
    
    if playerData.currencies.coins < amount then
        return {success = false, error = "Insufficient coins"}
    end
    
    -- Check bank limit
    if clan.bank + amount > MAX_CLAN_BANK then
        amount = MAX_CLAN_BANK - clan.bank
        if amount <= 0 then
            return {success = false, error = "Clan bank is full"}
        end
    end
    
    -- Process donation
    playerData.currencies.coins = playerData.currencies.coins - amount
    clan.bank = clan.bank + amount
    
    -- Update member contribution
    local member = clan.members[player.UserId]
    if member then
        member.contributions = member.contributions + amount
        member.lastActive = os.time()
    end
    
    -- Update statistics
    clan.statistics.totalDonations = clan.statistics.totalDonations + amount
    playerData.statistics.clanDonations = (playerData.statistics.clanDonations or 0) + amount
    
    -- Award clan XP
    local xpGained = math.floor(amount / 100)
    self:AddClanExperience(clan, xpGained)
    
    -- Save
    self:SaveClan(clan)
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Notify
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.ClanDonationMade:FireClient(player, amount, clan.bank)
    
    -- Notify clan members
    for memberId, _ in pairs(clan.members) do
        local mem = Players:GetPlayerByUserId(memberId)
        if mem and mem ~= player then
            RemoteEvents.ClanBankUpdated:FireClient(mem, clan.bank, player.Name, amount)
        end
    end
    
    return {
        success = true,
        donated = amount,
        newBank = clan.bank
    }
end

function ClanSystem:EditClanInfo(player, changes)
    local clanId = self.PlayerClans[player.UserId]
    if not clanId then
        return {success = false, error = "You are not in a clan"}
    end
    
    local clan = self.Clans[clanId]
    if not clan then
        return {success = false, error = "Clan not found"}
    end
    
    local member = clan.members[player.UserId]
    if not member then
        return {success = false, error = "Member not found"}
    end
    
    -- Check permissions
    if not self:HasPermission(member.rank, "EDIT_INFO") then
        return {success = false, error = "No permission to edit clan info"}
    end
    
    -- Apply changes
    if changes.description then
        changes.description = changes.description:sub(1, 200) -- Limit length
        clan.description = changes.description
    end
    
    if changes.announcement then
        changes.announcement = changes.announcement:sub(1, 500)
        clan.settings.announcement = changes.announcement
    end
    
    if changes.joinType then
        if changes.joinType == "open" or changes.joinType == "invite" or changes.joinType == "closed" then
            clan.settings.joinType = changes.joinType
        end
    end
    
    if changes.minLevel then
        changes.minLevel = math.max(1, math.min(100, changes.minLevel))
        clan.settings.minLevel = changes.minLevel
    end
    
    if changes.primaryColor then
        clan.settings.primaryColor = changes.primaryColor
    end
    
    if changes.secondaryColor then
        clan.settings.secondaryColor = changes.secondaryColor
    end
    
    -- Save
    self:SaveClan(clan)
    
    -- Notify
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.ClanInfoUpdated:FireAllClients(clanId, changes)
    
    return {success = true}
end

function ClanSystem:InviteToClan(player, targetPlayerName)
    local clanId = self.PlayerClans[player.UserId]
    if not clanId then
        return {success = false, error = "You are not in a clan"}
    end
    
    local clan = self.Clans[clanId]
    if not clan then
        return {success = false, error = "Clan not found"}
    end
    
    local member = clan.members[player.UserId]
    if not member then
        return {success = false, error = "Member not found"}
    end
    
    -- Check permissions
    if not self:HasPermission(member.rank, "INVITE") then
        return {success = false, error = "No permission to invite members"}
    end
    
    -- Find target player
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then
        return {success = false, error = "Player not found"}
    end
    
    -- Check if target is already in a clan
    if self.PlayerClans[targetPlayer.UserId] then
        return {success = false, error = "Player is already in a clan"}
    end
    
    -- Check member limit
    if clan.statistics.totalMembers >= MAX_CLAN_MEMBERS then
        return {success = false, error = "Clan is full"}
    end
    
    -- Create invite
    if not self.ClanInvites[targetPlayer.UserId] then
        self.ClanInvites[targetPlayer.UserId] = {}
    end
    
    self.ClanInvites[targetPlayer.UserId][clanId] = {
        clanId = clanId,
        clanName = clan.name,
        clanTag = clan.tag,
        invitedBy = player.Name,
        invitedAt = os.time(),
        expiresAt = os.time() + 3600 -- 1 hour
    }
    
    -- Notify target
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.ClanInviteReceived:FireClient(targetPlayer, {
        clanId = clanId,
        clanName = clan.name,
        clanTag = clan.tag,
        invitedBy = player.Name,
        members = clan.statistics.totalMembers,
        level = clan.level
    })
    
    return {success = true}
end

-- ========================================
-- CLAN WARS
-- ========================================

function ClanSystem:StartClanWar(player, targetClanId, wagerAmount)
    local clanId = self.PlayerClans[player.UserId]
    if not clanId then
        return {success = false, error = "You are not in a clan"}
    end
    
    local clan = self.Clans[clanId]
    local targetClan = self.Clans[targetClanId]
    
    if not clan or not targetClan then
        return {success = false, error = "Clan not found"}
    end
    
    local member = clan.members[player.UserId]
    if not member then
        return {success = false, error = "Member not found"}
    end
    
    -- Check permissions
    if not self:HasPermission(member.rank, "START_WAR") then
        return {success = false, error = "Only leaders can start clan wars"}
    end
    
    -- Check if already in war
    for warId, war in pairs(self.ClanWars) do
        if war.status == "active" and (war.clan1Id == clanId or war.clan2Id == clanId) then
            return {success = false, error = "Your clan is already in a war"}
        end
    end
    
    -- Validate wager
    wagerAmount = math.max(0, math.floor(wagerAmount or 0))
    if wagerAmount > 0 then
        if clan.bank < wagerAmount then
            return {success = false, error = "Insufficient clan bank funds"}
        end
        if targetClan.bank < wagerAmount then
            return {success = false, error = "Target clan has insufficient funds"}
        end
    end
    
    -- Create war request
    local warId = HttpService:GenerateGUID(false)
    local war = {
        id = warId,
        clan1Id = clanId,
        clan1Name = clan.name,
        clan2Id = targetClanId,
        clan2Name = targetClan.name,
        wager = wagerAmount,
        status = "pending",
        createdAt = os.time(),
        startsAt = os.time() + 300, -- 5 minute preparation
        endsAt = os.time() + 3900, -- 65 minutes total (5 prep + 60 war)
        scores = {
            [clanId] = 0,
            [targetClanId] = 0
        },
        participants = {
            [clanId] = {},
            [targetClanId] = {}
        }
    }
    
    self.ClanWars[warId] = war
    
    -- Notify target clan
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    for memberId, _ in pairs(targetClan.members) do
        local mem = Players:GetPlayerByUserId(memberId)
        if mem then
            RemoteEvents.ClanWarRequest:FireClient(mem, {
                warId = warId,
                challengerName = clan.name,
                challengerTag = clan.tag,
                wager = wagerAmount
            })
        end
    end
    
    -- Set timeout for acceptance
    delay(300, function()
        if self.ClanWars[warId] and self.ClanWars[warId].status == "pending" then
            self.ClanWars[warId] = nil
            -- Notify challenger clan
            for memberId, _ in pairs(clan.members) do
                local mem = Players:GetPlayerByUserId(memberId)
                if mem then
                    RemoteEvents.NotificationSent:FireClient(mem, {
                        title = "War Request Expired",
                        message = "Your war request to " .. targetClan.name .. " has expired",
                        type = "info"
                    })
                end
            end
        end
    end)
    
    return {
        success = true,
        warId = warId
    }
end

-- ========================================
-- UTILITIES
-- ========================================

function ClanSystem:HasPermission(rank, permission)
    local allowedRanks = PERMISSIONS[permission]
    if not allowedRanks then return false end
    
    for _, allowedRank in ipairs(allowedRanks) do
        if rank >= allowedRank then
            return true
        end
    end
    
    return false
end

function ClanSystem:AddClanExperience(clan, amount)
    clan.experience = clan.experience + amount
    
    -- Check for level up
    local requiredXP = self:GetRequiredExperience(clan.level)
    while clan.experience >= requiredXP do
        clan.experience = clan.experience - requiredXP
        clan.level = clan.level + 1
        
        -- Award level up bonuses
        local bonus = 1000 * clan.level
        clan.bank = math.min(clan.bank + bonus, MAX_CLAN_BANK)
        
        -- Notify members
        local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
        for memberId, _ in pairs(clan.members) do
            local mem = Players:GetPlayerByUserId(memberId)
            if mem then
                RemoteEvents.ClanLevelUp:FireClient(mem, clan.level, bonus)
            end
        end
        
        requiredXP = self:GetRequiredExperience(clan.level)
    end
end

function ClanSystem:GetRequiredExperience(level)
    return 1000 + (level * 500)
end

function ClanSystem:GetClanList(filters)
    local results = {}
    
    for clanId, clan in pairs(self.Clans) do
        local match = true
        
        -- Apply filters
        if filters then
            if filters.search then
                local search = filters.search:lower()
                if not (clan.name:lower():find(search) or clan.tag:lower():find(search)) then
                    match = false
                end
            end
            
            if filters.minLevel and clan.level < filters.minLevel then
                match = false
            end
            
            if filters.joinType and clan.settings.joinType ~= filters.joinType then
                match = false
            end
            
            if filters.hasSpace and clan.statistics.totalMembers >= MAX_CLAN_MEMBERS then
                match = false
            end
        end
        
        if match then
            table.insert(results, {
                id = clanId,
                name = clan.name,
                tag = clan.tag,
                level = clan.level,
                members = clan.statistics.totalMembers,
                maxMembers = MAX_CLAN_MEMBERS,
                trophies = clan.statistics.trophies,
                joinType = clan.settings.joinType,
                minLevel = clan.settings.minLevel,
                leaderId = clan.leaderId
            })
        end
    end
    
    -- Sort by trophies
    table.sort(results, function(a, b)
        return a.trophies > b.trophies
    end)
    
    return results
end

function ClanSystem:GetClanDetails(clanId)
    local clan = self.Clans[clanId]
    if not clan then
        return nil
    end
    
    -- Prepare member list
    local members = {}
    for userId, member in pairs(clan.members) do
        table.insert(members, {
            userId = userId,
            username = member.username,
            rank = member.rank,
            rankName = RANK_NAMES[member.rank],
            contributions = member.contributions,
            joinedAt = member.joinedAt,
            lastActive = member.lastActive,
            isOnline = Players:GetPlayerByUserId(userId) ~= nil
        })
    end
    
    -- Sort by rank and contributions
    table.sort(members, function(a, b)
        if a.rank ~= b.rank then
            return a.rank > b.rank
        end
        return a.contributions > b.contributions
    end)
    
    return {
        id = clanId,
        name = clan.name,
        tag = clan.tag,
        description = clan.description,
        level = clan.level,
        experience = clan.experience,
        requiredExperience = self:GetRequiredExperience(clan.level),
        bank = clan.bank,
        members = members,
        settings = clan.settings,
        statistics = clan.statistics
    }
end

function ClanSystem:UpdateClanLeaderboards()
    -- Calculate weekly activity for all clans
    for clanId, clan in pairs(self.Clans) do
        local activity = 0
        
        for userId, member in pairs(clan.members) do
            -- Active if played in last week
            if os.time() - member.lastActive < 604800 then
                activity = activity + 1
            end
        end
        
        clan.statistics.weeklyActivity = math.floor((activity / clan.statistics.totalMembers) * 100)
    end
    
    -- Could save to DataStore for persistence
end

function ClanSystem:CheckWarStatus()
    local currentTime = os.time()
    
    for warId, war in pairs(self.ClanWars) do
        if war.status == "pending" then
            -- Handled by timeout
        elseif war.status == "accepted" and currentTime >= war.startsAt then
            -- Start war
            war.status = "active"
            
            -- Notify clans
            self:NotifyWarStart(war)
            
        elseif war.status == "active" and currentTime >= war.endsAt then
            -- End war
            self:EndClanWar(warId)
        end
    end
end

function ClanSystem:DisbandClan(clanId)
    local clan = self.Clans[clanId]
    if not clan then return end
    
    -- Remove all members
    for userId, _ in pairs(clan.members) do
        self.PlayerClans[userId] = nil
        
        local playerData = self.DataStoreModule:GetPlayerData(userId)
        if playerData then
            playerData.clan = nil
            self.DataStoreModule:MarkPlayerDirty(userId)
        end
        
        -- Notify if online
        local player = Players:GetPlayerByUserId(userId)
        if player then
            local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
            RemoteEvents.ClanDisbanded:FireClient(player, clan.name)
        end
    end
    
    -- Remove clan
    self.Clans[clanId] = nil
    
    -- Remove from DataStore
    spawn(function()
        pcall(function()
            self.ClanDataStore:RemoveAsync(clanId)
        end)
    end)
end

-- ========================================
-- DATA PERSISTENCE
-- ========================================

function ClanSystem:LoadClans()
    -- This would load clans from DataStore in production
    -- For now, just initialize empty
    print("[ClanSystem] Ready to load clans")
end

function ClanSystem:SaveClan(clan)
    -- Save to DataStore
    spawn(function()
        pcall(function()
            self.ClanDataStore:SetAsync(clan.id, clan)
        end)
    end)
end

function ClanSystem:OnPlayerLeaving(player)
    -- Update last active time
    local clanId = self.PlayerClans[player.UserId]
    if clanId then
        local clan = self.Clans[clanId]
        if clan and clan.members[player.UserId] then
            clan.members[player.UserId].lastActive = os.time()
            self:SaveClan(clan)
        end
    end
    
    -- Remove from any active wars
    for warId, war in pairs(self.ClanWars) do
        if war.participants[clanId] and war.participants[clanId][player.UserId] then
            war.participants[clanId][player.UserId] = nil
        end
    end
end

return ClanSystem