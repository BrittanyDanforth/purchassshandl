--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                     SANRIO TYCOON - DAILY REWARD SYSTEM MODULE                       ║
    ║                           Handles daily login rewards and streaks                    ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local DailyRewardSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local Configuration = require(script.Parent.Configuration)
local DataStoreModule = require(script.Parent.DataStoreModule)

-- ========================================
-- DAILY REWARD DEFINITIONS
-- ========================================
DailyRewardSystem.Rewards = {
    -- Day 1-7 (Week 1)
    {day = 1, coins = 100, gems = 0, items = {}},
    {day = 2, coins = 200, gems = 0, items = {}},
    {day = 3, coins = 300, gems = 5, items = {}},
    {day = 4, coins = 400, gems = 0, items = {}},
    {day = 5, coins = 500, gems = 10, items = {}},
    {day = 6, coins = 750, gems = 0, items = {}},
    {day = 7, coins = 1000, gems = 25, items = {"basic_egg"}}, -- Free egg on day 7
    
    -- Day 8-14 (Week 2)
    {day = 8, coins = 1250, gems = 0, items = {}},
    {day = 9, coins = 1500, gems = 0, items = {}},
    {day = 10, coins = 1750, gems = 15, items = {}},
    {day = 11, coins = 2000, gems = 0, items = {}},
    {day = 12, coins = 2500, gems = 20, items = {}},
    {day = 13, coins = 3000, gems = 0, items = {}},
    {day = 14, coins = 5000, gems = 50, items = {"rare_egg"}}, -- Better egg on day 14
    
    -- Day 15-21 (Week 3)
    {day = 15, coins = 6000, gems = 0, items = {}},
    {day = 16, coins = 7000, gems = 30, items = {}},
    {day = 17, coins = 8000, gems = 0, items = {}},
    {day = 18, coins = 9000, gems = 40, items = {}},
    {day = 19, coins = 10000, gems = 0, items = {}},
    {day = 20, coins = 12500, gems = 50, items = {}},
    {day = 21, coins = 15000, gems = 100, items = {"premium_egg"}}, -- Premium egg on day 21
    
    -- Day 22-28 (Week 4)
    {day = 22, coins = 17500, gems = 0, items = {}},
    {day = 23, coins = 20000, gems = 60, items = {}},
    {day = 24, coins = 22500, gems = 0, items = {}},
    {day = 25, coins = 25000, gems = 75, items = {}},
    {day = 26, coins = 30000, gems = 0, items = {}},
    {day = 27, coins = 35000, gems = 100, items = {}},
    {day = 28, coins = 50000, gems = 200, items = {"legendary_egg", "title_dedicated"}}, -- Big reward for 28 days
    
    -- After 28 days, cycle back with multiplier
    {day = 29, coins = 2500, gems = 10, items = {}},
    {day = 30, coins = 100000, gems = 500, items = {"legendary_egg", "title_veteran"}} -- Huge 30 day reward
}

-- VIP bonus multiplier
DailyRewardSystem.VIP_MULTIPLIER = 2

-- ========================================
-- CHECK DAILY REWARD
-- ========================================
function DailyRewardSystem:CanClaimDailyReward(player)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then
        return false, "No player data"
    end
    
    local dailyData = playerData.dailyReward
    local currentTime = os.time()
    local lastClaim = dailyData.lastClaim or 0
    
    -- Check if 24 hours have passed
    local timeSinceLastClaim = currentTime - lastClaim
    local hoursUntilNext = math.max(0, 24 - (timeSinceLastClaim / 3600))
    
    if timeSinceLastClaim < 86400 then -- 86400 seconds = 24 hours
        return false, string.format("Next reward in %d hours", math.ceil(hoursUntilNext))
    end
    
    return true
end

-- ========================================
-- CALCULATE STREAK
-- ========================================
function DailyRewardSystem:CalculateStreak(player)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return 1 end
    
    local dailyData = playerData.dailyReward
    local currentTime = os.time()
    local lastClaim = dailyData.lastClaim or 0
    local timeSinceLastClaim = currentTime - lastClaim
    
    -- If more than 48 hours have passed, reset streak
    if timeSinceLastClaim > 172800 then -- 172800 seconds = 48 hours
        return 1
    end
    
    -- Continue streak
    return math.min((dailyData.streak or 0) + 1, 30) -- Max 30 day streak
end

-- ========================================
-- GET REWARD FOR DAY
-- ========================================
function DailyRewardSystem:GetRewardForDay(day)
    -- Find reward for specific day
    for _, reward in ipairs(self.Rewards) do
        if reward.day == day then
            return reward
        end
    end
    
    -- If beyond 30 days, give cycling rewards with multiplier
    local cycleDay = ((day - 1) % 7) + 1
    local cycleMultiplier = math.floor((day - 1) / 30) + 1
    
    return {
        day = day,
        coins = self.Rewards[cycleDay].coins * cycleMultiplier,
        gems = self.Rewards[cycleDay].gems * cycleMultiplier,
        items = self.Rewards[cycleDay].items
    }
end

-- ========================================
-- CLAIM DAILY REWARD
-- ========================================
function DailyRewardSystem:ClaimDailyReward(player)
    local canClaim, reason = self:CanClaimDailyReward(player)
    if not canClaim then
        return {success = false, error = reason}
    end
    
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then
        return {success = false, error = "No player data"}
    end
    
    -- Calculate new streak
    local newStreak = self:CalculateStreak(player)
    local reward = self:GetRewardForDay(newStreak)
    
    -- Apply VIP bonus if player has VIP
    local multiplier = 1
    if playerData.ownedGamepasses[Configuration.GAMEPASS_IDS.VIP] then
        multiplier = self.VIP_MULTIPLIER
    end
    
    -- Give rewards
    local actualCoins = reward.coins * multiplier
    local actualGems = reward.gems * multiplier
    
    playerData.currencies.coins = playerData.currencies.coins + actualCoins
    playerData.currencies.gems = playerData.currencies.gems + actualGems
    
    -- Give items (eggs, titles, etc.)
    local itemsGiven = {}
    for _, item in ipairs(reward.items) do
        if string.find(item, "_egg") then
            -- It's an egg, open it
            local CaseSystem = require(script.Parent.CaseSystem)
            local result = CaseSystem:OpenCase(player, item, 1)
            if result.success then
                table.insert(itemsGiven, {type = "egg", id = item, results = result.results})
            end
        elseif string.find(item, "title_") then
            -- It's a title
            local titleName = string.gsub(item, "title_", "")
            if not playerData.titles.owned then
                playerData.titles.owned = {}
            end
            table.insert(playerData.titles.owned, titleName)
            table.insert(itemsGiven, {type = "title", name = titleName})
        end
    end
    
    -- Update daily reward data
    playerData.dailyReward = {
        lastClaim = os.time(),
        streak = newStreak,
        day = newStreak
    }
    
    -- Update statistics
    playerData.statistics.totalCoinsEarned = (playerData.statistics.totalCoinsEarned or 0) + actualCoins
    playerData.statistics.totalGemsEarned = (playerData.statistics.totalGemsEarned or 0) + actualGems
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Send notification
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("DailyRewardClaimed") then
        RemoteEvents.DailyRewardClaimed:FireClient(player, {
            success = true,
            day = newStreak,
            streak = newStreak,
            rewards = {
                coins = actualCoins,
                gems = actualGems,
                items = itemsGiven
            },
            nextRewardTime = os.time() + 86400
        })
    end
    
    -- Send notification
    if RemoteEvents and RemoteEvents:FindFirstChild("NotificationSent") then
        RemoteEvents.NotificationSent:FireClient(player, {
            type = "success",
            title = "Daily Reward Claimed!",
            message = string.format("Day %d reward claimed! Streak: %d days", newStreak, newStreak),
            duration = 5
        })
    end
    
    return {
        success = true,
        day = newStreak,
        streak = newStreak,
        rewards = {
            coins = actualCoins,
            gems = actualGems,
            items = itemsGiven
        }
    }
end

-- ========================================
-- GET ALL REWARDS (FOR UI)
-- ========================================
function DailyRewardSystem:GetAllRewards(player)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return {} end
    
    local currentStreak = playerData.dailyReward.streak or 0
    local hasVIP = playerData.ownedGamepasses[Configuration.GAMEPASS_IDS.VIP]
    
    -- Get first 30 days of rewards for display
    local rewards = {}
    for i = 1, 30 do
        local reward = self:GetRewardForDay(i)
        local multiplier = hasVIP and self.VIP_MULTIPLIER or 1
        
        table.insert(rewards, {
            day = i,
            coins = reward.coins * multiplier,
            gems = reward.gems * multiplier,
            items = reward.items,
            claimed = i <= currentStreak,
            current = i == currentStreak + 1
        })
    end
    
    return rewards
end

-- ========================================
-- CHECK ON PLAYER JOIN
-- ========================================
function DailyRewardSystem:CheckDailyReward(player)
    local canClaim = self:CanClaimDailyReward(player)
    
    if canClaim then
        -- Notify player they can claim
        local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if RemoteEvents and RemoteEvents:FindFirstChild("NotificationSent") then
            wait(5) -- Wait for player to load
            RemoteEvents.NotificationSent:FireClient(player, {
                type = "info",
                title = "Daily Reward Available!",
                message = "Claim your daily reward in the shop!",
                duration = 10
            })
        end
    end
end

return DailyRewardSystem