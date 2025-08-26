--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - QUEST SYSTEM MODULE                           ║
    ║                         Daily, Weekly, and Special Quests                            ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local QuestSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Dependencies
local Configuration = require(script.Parent.Configuration)
local DataStoreModule = require(script.Parent.DataStoreModule)

-- ========================================
-- QUEST TEMPLATES
-- ========================================
QuestSystem.DailyQuestTemplates = {
    {
        id = "daily_open_eggs",
        name = "Egg Collector",
        description = "Open %d eggs",
        icon = "🥚",
        requirement = {
            type = "open_eggs",
            amount = {5, 10, 15} -- Different amounts for variety
        },
        rewards = {
            coins = {500, 1000, 1500},
            gems = {0, 5, 10},
            xp = {50, 100, 150}
        }
    },
    {
        id = "daily_hatch_pets",
        name = "Pet Hatcher",
        description = "Hatch %d pets",
        icon = "🐣",
        requirement = {
            type = "hatch_pets",
            amount = {3, 5, 10}
        },
        rewards = {
            coins = {750, 1250, 2000},
            gems = {5, 10, 15},
            xp = {75, 125, 200}
        }
    },
    {
        id = "daily_complete_trades",
        name = "Trader",
        description = "Complete %d trades",
        icon = "🤝",
        requirement = {
            type = "complete_trades",
            amount = {1, 2, 3}
        },
        rewards = {
            coins = {1000, 2000, 3000},
            gems = {10, 20, 30},
            xp = {100, 200, 300}
        }
    },
    {
        id = "daily_win_battles",
        name = "Battle Champion",
        description = "Win %d battles",
        icon = "⚔️",
        requirement = {
            type = "win_battles",
            amount = {3, 5, 10}
        },
        rewards = {
            coins = {1500, 2500, 5000},
            gems = {15, 25, 50},
            xp = {150, 250, 500}
        }
    },
    {
        id = "daily_collect_coins",
        name = "Coin Collector",
        description = "Collect %d coins",
        icon = "💰",
        requirement = {
            type = "collect_coins",
            amount = {5000, 10000, 25000}
        },
        rewards = {
            coins = {2000, 4000, 10000},
            gems = {10, 20, 50},
            xp = {100, 200, 500}
        }
    },
    {
        id = "daily_equip_pets",
        name = "Pet Master",
        description = "Equip %d different pets",
        icon = "🎯",
        requirement = {
            type = "equip_pets",
            amount = {3, 5, 6}
        },
        rewards = {
            coins = {1000, 2000, 3000},
            gems = {5, 10, 15},
            xp = {50, 100, 150}
        }
    }
}

QuestSystem.WeeklyQuestTemplates = {
    {
        id = "weekly_legendary_pet",
        name = "Legendary Hunter",
        description = "Hatch a legendary or better pet",
        icon = "🌟",
        requirement = {
            type = "hatch_rarity",
            rarity = Configuration.RARITY.LEGENDARY
        },
        rewards = {
            coins = 50000,
            gems = 200,
            xp = 1000,
            items = {"premium_egg"}
        }
    },
    {
        id = "weekly_total_trades",
        name = "Master Trader",
        description = "Complete %d total trades",
        icon = "📊",
        requirement = {
            type = "complete_trades",
            amount = 25
        },
        rewards = {
            coins = 100000,
            gems = 500,
            xp = 2000
        }
    },
    {
        id = "weekly_battle_streak",
        name = "Undefeated",
        description = "Win %d battles in a row",
        icon = "🏆",
        requirement = {
            type = "battle_streak",
            amount = 10
        },
        rewards = {
            coins = 75000,
            gems = 300,
            xp = 1500,
            items = {"title_warrior"}
        }
    }
}

-- ========================================
-- GENERATE DAILY QUESTS
-- ========================================
function QuestSystem:GenerateDailyQuests(player)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return end
    
    -- Check if new day
    local currentDay = math.floor(os.time() / 86400)
    local lastQuestDay = playerData.quests.lastDailyGeneration or 0
    
    if currentDay <= lastQuestDay then
        return -- Already generated today
    end
    
    -- Clear old daily quests
    playerData.quests.daily = {}
    
    -- Generate 3 random daily quests
    local availableQuests = {}
    for _, template in ipairs(self.DailyQuestTemplates) do
        table.insert(availableQuests, template)
    end
    
    for i = 1, 3 do
        if #availableQuests > 0 then
            local index = math.random(1, #availableQuests)
            local template = availableQuests[index]
            table.remove(availableQuests, index)
            
            -- Create quest instance
            local difficulty = math.random(1, #template.requirement.amount)
            local quest = {
                id = template.id .. "_" .. i,
                templateId = template.id,
                name = template.name,
                description = string.format(template.description, template.requirement.amount[difficulty]),
                icon = template.icon,
                requirement = {
                    type = template.requirement.type,
                    amount = template.requirement.amount[difficulty],
                    progress = 0
                },
                rewards = {
                    coins = template.rewards.coins[difficulty],
                    gems = template.rewards.gems[difficulty],
                    xp = template.rewards.xp[difficulty]
                },
                completed = false,
                claimed = false
            }
            
            table.insert(playerData.quests.daily, quest)
        end
    end
    
    -- Update last generation time
    playerData.quests.lastDailyGeneration = currentDay
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Notify client
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("QuestsUpdated") then
        RemoteEvents.QuestsUpdated:FireClient(player, playerData.quests)
    end
end

-- ========================================
-- UPDATE QUEST PROGRESS
-- ========================================
function QuestSystem:UpdateQuestProgress(player, questType, amount)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return end
    
    local updated = false
    
    -- Check daily quests
    for _, quest in ipairs(playerData.quests.daily or {}) do
        if quest.requirement.type == questType and not quest.completed then
            quest.requirement.progress = quest.requirement.progress + amount
            
            if quest.requirement.progress >= quest.requirement.amount then
                quest.requirement.progress = quest.requirement.amount
                quest.completed = true
                updated = true
                
                -- Send notification
                local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
                if RemoteEvents and RemoteEvents:FindFirstChild("QuestCompleted") then
                    RemoteEvents.QuestCompleted:FireClient(player, quest)
                end
            end
        end
    end
    
    -- Check weekly quests
    for _, quest in ipairs(playerData.quests.weekly or {}) do
        if quest.requirement.type == questType and not quest.completed then
            if questType == "hatch_rarity" then
                -- Special handling for rarity quests
                if amount >= quest.requirement.rarity then
                    quest.completed = true
                    updated = true
                end
            else
                quest.requirement.progress = quest.requirement.progress + amount
                
                if quest.requirement.progress >= quest.requirement.amount then
                    quest.requirement.progress = quest.requirement.amount
                    quest.completed = true
                    updated = true
                end
            end
            
            if quest.completed then
                local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
                if RemoteEvents and RemoteEvents:FindFirstChild("QuestCompleted") then
                    RemoteEvents.QuestCompleted:FireClient(player, quest)
                end
            end
        end
    end
    
    if updated then
        -- Mark data as dirty
        DataStoreModule:MarkPlayerDirty(player.UserId)
        
        -- Update client
        local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if RemoteEvents and RemoteEvents:FindFirstChild("QuestsUpdated") then
            RemoteEvents.QuestsUpdated:FireClient(player, playerData.quests)
        end
    end
end

-- ========================================
-- CLAIM QUEST REWARD
-- ========================================
function QuestSystem:ClaimQuestReward(player, questId)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then
        return {success = false, error = "No player data"}
    end
    
    -- Find quest
    local quest = nil
    local questList = nil
    
    for _, q in ipairs(playerData.quests.daily or {}) do
        if q.id == questId then
            quest = q
            questList = playerData.quests.daily
            break
        end
    end
    
    if not quest then
        for _, q in ipairs(playerData.quests.weekly or {}) do
            if q.id == questId then
                quest = q
                questList = playerData.quests.weekly
                break
            end
        end
    end
    
    if not quest then
        return {success = false, error = "Quest not found"}
    end
    
    if not quest.completed then
        return {success = false, error = "Quest not completed"}
    end
    
    if quest.claimed then
        return {success = false, error = "Reward already claimed"}
    end
    
    -- Give rewards
    if quest.rewards.coins then
        playerData.currencies.coins = playerData.currencies.coins + quest.rewards.coins
    end
    
    if quest.rewards.gems then
        playerData.currencies.gems = playerData.currencies.gems + quest.rewards.gems
    end
    
    if quest.rewards.xp then
        -- Add XP to battle pass or player level
        playerData.battlePass.xp = (playerData.battlePass.xp or 0) + quest.rewards.xp
    end
    
    if quest.rewards.items then
        -- Give items (implement based on item system)
        for _, item in ipairs(quest.rewards.items) do
            if string.find(item, "title_") then
                local titleName = string.gsub(item, "title_", "")
                table.insert(playerData.titles.owned, titleName)
            end
        end
    end
    
    -- Mark as claimed
    quest.claimed = true
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Send success response
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("QuestRewardClaimed") then
        RemoteEvents.QuestRewardClaimed:FireClient(player, {
            questId = questId,
            rewards = quest.rewards
        })
    end
    
    return {success = true, rewards = quest.rewards}
end

-- ========================================
-- QUEST INTEGRATION HOOKS
-- ========================================
function QuestSystem:OnEggOpened(player, count)
    self:UpdateQuestProgress(player, "open_eggs", count)
end

function QuestSystem:OnPetHatched(player, pet)
    self:UpdateQuestProgress(player, "hatch_pets", 1)
    
    -- Check rarity quests
    if pet.rarity then
        self:UpdateQuestProgress(player, "hatch_rarity", pet.rarity)
    end
end

function QuestSystem:OnTradeCompleted(player)
    self:UpdateQuestProgress(player, "complete_trades", 1)
end

function QuestSystem:OnBattleWon(player)
    self:UpdateQuestProgress(player, "win_battles", 1)
end

function QuestSystem:OnCoinsCollected(player, amount)
    self:UpdateQuestProgress(player, "collect_coins", amount)
end

function QuestSystem:OnPetEquipped(player)
    self:UpdateQuestProgress(player, "equip_pets", 1)
end

return QuestSystem