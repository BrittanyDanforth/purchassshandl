--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                       SANRIO TYCOON - BATTLE SYSTEM MODULE                           ║
    ║                          Turn-based pet battle mechanics                             ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local BattleSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Dependencies
local Configuration = require(script.Parent.Configuration)
local DataStoreModule = require(script.Parent.DataStoreModule)
local PetSystem = require(script.Parent.PetSystem)
local PetDatabase = require(script.Parent.PetDatabase)

-- Battle Storage
BattleSystem.ActiveBattles = {}
BattleSystem.BattleQueue = {}

-- ========================================
-- BATTLE CONFIGURATION
-- ========================================
local BATTLE_CONFIG = {
    TURN_TIME = 30,
    MAX_TEAM_SIZE = 6,
    BATTLE_REWARDS = {
        WIN_COINS = 1000,
        WIN_XP = 100,
        LOSE_COINS = 250,
        LOSE_XP = 25
    },
    STATUS_EFFECTS = {
        STUN = {duration = 1, skipTurn = true},
        SLEEP = {duration = 2, skipTurn = true},
        POISON = {duration = 3, damagePerTurn = 0.1},
        BURN = {duration = 3, damagePerTurn = 0.15},
        FREEZE = {duration = 2, speedReduction = 0.5},
        CONFUSE = {duration = 2, accuracy = 0.5},
        WEAKNESS = {duration = 3, damageReduction = 0.3},
        STRENGTH = {duration = 3, damageBoost = 0.3}
    }
}

-- ========================================
-- ABILITY DEFINITIONS
-- ========================================
local ABILITIES = {
    -- Basic Attacks
    tackle = {
        name = "Tackle",
        description = "Basic physical attack",
        power = 40,
        accuracy = 100,
        type = "physical",
        target = "single"
    },
    
    scratch = {
        name = "Scratch",
        description = "Sharp claw attack",
        power = 45,
        accuracy = 95,
        type = "physical",
        target = "single",
        effect = {type = "bleed", chance = 0.1}
    },
    
    -- Special Attacks
    flame_burst = {
        name = "Flame Burst",
        description = "Fiery explosion",
        power = 60,
        accuracy = 90,
        type = "special",
        target = "single",
        effect = {type = "burn", chance = 0.3}
    },
    
    ice_beam = {
        name = "Ice Beam",
        description = "Freezing ray",
        power = 55,
        accuracy = 95,
        type = "special",
        target = "single",
        effect = {type = "freeze", chance = 0.2}
    },
    
    thunder_shock = {
        name = "Thunder Shock",
        description = "Electric attack",
        power = 50,
        accuracy = 100,
        type = "special",
        target = "single",
        effect = {type = "stun", chance = 0.15}
    },
    
    -- Area Attacks
    earthquake = {
        name = "Earthquake",
        description = "Ground-shaking attack",
        power = 40,
        accuracy = 100,
        type = "physical",
        target = "all"
    },
    
    -- Support Moves
    heal = {
        name = "Heal",
        description = "Restore HP",
        power = 0,
        accuracy = 100,
        type = "support",
        target = "self",
        heal = 0.5
    },
    
    protect = {
        name = "Protect",
        description = "Shield from attacks",
        power = 0,
        accuracy = 100,
        type = "support",
        target = "self",
        effect = {type = "shield", duration = 1}
    },
    
    power_up = {
        name = "Power Up",
        description = "Boost attack power",
        power = 0,
        accuracy = 100,
        type = "support",
        target = "team",
        effect = {type = "strength", duration = 3}
    }
}

-- ========================================
-- CREATE BATTLE
-- ========================================
function BattleSystem:CreateBattle(player1, player2, battleType)
    local battleId = HttpService:GenerateGUID(false)
    
    local battle = {
        id = battleId,
        type = battleType or "pvp",
        players = {
            [1] = {
                player = player1,
                userId = player1.UserId,
                team = {},
                currentPet = 1,
                ready = false
            },
            [2] = {
                player = player2,
                userId = player2.UserId,
                team = {},
                currentPet = 1,
                ready = false
            }
        },
        turn = 1,
        turnPlayer = 1,
        turnStartTime = 0,
        status = "setup",
        winner = nil,
        logs = {}
    }
    
    self.ActiveBattles[battleId] = battle
    
    -- Notify players
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("BattleStarted") then
        RemoteEvents.BattleStarted:FireClient(player1, battle)
        RemoteEvents.BattleStarted:FireClient(player2, battle)
    end
    
    return battleId
end

-- ========================================
-- SET BATTLE TEAM
-- ========================================
function BattleSystem:SetBattleTeam(battleId, player, petIds)
    local battle = self.ActiveBattles[battleId]
    if not battle then return false, "Battle not found" end
    
    if battle.status ~= "setup" then
        return false, "Battle already started"
    end
    
    -- Find player side
    local playerSide = nil
    for i, side in ipairs(battle.players) do
        if side.userId == player.UserId then
            playerSide = side
            break
        end
    end
    
    if not playerSide then
        return false, "Player not in battle"
    end
    
    -- Validate pets
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then
        return false, "No player data"
    end
    
    playerSide.team = {}
    
    for i, petId in ipairs(petIds) do
        if i > BATTLE_CONFIG.MAX_TEAM_SIZE then break end
        
        local pet = playerData.pets[petId]
        if pet then
            -- Create battle instance of pet
            local battlePet = {
                id = petId,
                petId = pet.petId,
                name = pet.name,
                level = pet.level,
                currentHP = pet.stats.health,
                maxHP = pet.stats.health,
                stats = {
                    power = pet.stats.power,
                    defense = pet.stats.defense or pet.stats.power * 0.8,
                    speed = pet.stats.speed,
                    luck = pet.stats.luck
                },
                statusEffects = {},
                abilities = self:GetPetAbilities(pet)
            }
            
            table.insert(playerSide.team, battlePet)
        end
    end
    
    if #playerSide.team == 0 then
        return false, "No valid pets selected"
    end
    
    playerSide.ready = true
    
    -- Check if both ready
    if battle.players[1].ready and battle.players[2].ready then
        self:StartBattle(battleId)
    end
    
    return true
end

-- ========================================
-- START BATTLE
-- ========================================
function BattleSystem:StartBattle(battleId)
    local battle = self.ActiveBattles[battleId]
    if not battle then return end
    
    battle.status = "active"
    battle.turnStartTime = tick()
    
    -- Determine first turn based on speed
    local speed1 = battle.players[1].team[1].stats.speed
    local speed2 = battle.players[2].team[1].stats.speed
    
    battle.turnPlayer = speed1 >= speed2 and 1 or 2
    
    -- Notify players
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("BattleReady") then
        for _, side in ipairs(battle.players) do
            RemoteEvents.BattleReady:FireClient(side.player, {
                battleId = battleId,
                battle = battle,
                yourTurn = battle.turnPlayer == _
            })
        end
    end
    
    -- Start turn timer
    self:StartTurnTimer(battleId)
end

-- ========================================
-- EXECUTE ACTION
-- ========================================
function BattleSystem:ExecuteAction(battleId, player, action)
    local battle = self.ActiveBattles[battleId]
    if not battle or battle.status ~= "active" then
        return false, "Battle not active"
    end
    
    -- Find player side
    local playerSideIndex = nil
    for i, side in ipairs(battle.players) do
        if side.userId == player.UserId then
            playerSideIndex = i
            break
        end
    end
    
    if not playerSideIndex or battle.turnPlayer ~= playerSideIndex then
        return false, "Not your turn"
    end
    
    local attackerSide = battle.players[playerSideIndex]
    local defenderSide = battle.players[playerSideIndex == 1 and 2 or 1]
    
    local attackerPet = attackerSide.team[attackerSide.currentPet]
    local defenderPet = defenderSide.team[defenderSide.currentPet]
    
    if not attackerPet or attackerPet.currentHP <= 0 then
        return false, "Invalid attacker pet"
    end
    
    -- Check status effects
    for effect, data in pairs(attackerPet.statusEffects or {}) do
        if BATTLE_CONFIG.STATUS_EFFECTS[effect] and BATTLE_CONFIG.STATUS_EFFECTS[effect].skipTurn then
            -- Skip turn due to status effect
            self:NextTurn(battleId)
            return true
        end
    end
    
    -- Execute action based on type
    if action.type == "ability" then
        self:ExecuteAbility(battle, attackerPet, defenderPet, action.abilityId)
    elseif action.type == "switch" then
        self:SwitchPet(battle, playerSideIndex, action.petIndex)
    elseif action.type == "flee" then
        self:FleeBattle(battle, playerSideIndex)
    end
    
    -- Check for defeated pets
    self:CheckDefeatedPets(battle)
    
    -- Next turn
    self:NextTurn(battleId)
    
    return true
end

-- ========================================
-- EXECUTE ABILITY
-- ========================================
function BattleSystem:ExecuteAbility(battle, attacker, defender, abilityId)
    local ability = ABILITIES[abilityId]
    if not ability then return end
    
    -- Add to battle log
    table.insert(battle.logs, {
        type = "ability",
        attacker = attacker.name,
        ability = ability.name,
        timestamp = tick()
    })
    
    -- Check accuracy
    local hitChance = ability.accuracy / 100
    if attacker.statusEffects.confuse then
        hitChance = hitChance * 0.5
    end
    
    if math.random() > hitChance then
        table.insert(battle.logs, {
            type = "miss",
            attacker = attacker.name,
            timestamp = tick()
        })
        return
    end
    
    -- Calculate damage
    if ability.power > 0 then
        local damage = self:CalculateDamage(attacker, defender, ability)
        
        defender.currentHP = math.max(0, defender.currentHP - damage)
        
        table.insert(battle.logs, {
            type = "damage",
            target = defender.name,
            damage = damage,
            timestamp = tick()
        })
    end
    
    -- Apply effects
    if ability.effect then
        self:ApplyStatusEffect(defender, ability.effect.type, ability.effect.duration or 3)
    end
    
    -- Apply healing
    if ability.heal then
        local healAmount = math.floor(attacker.maxHP * ability.heal)
        attacker.currentHP = math.min(attacker.maxHP, attacker.currentHP + healAmount)
        
        table.insert(battle.logs, {
            type = "heal",
            target = attacker.name,
            amount = healAmount,
            timestamp = tick()
        })
    end
end

-- ========================================
-- CALCULATE DAMAGE
-- ========================================
function BattleSystem:CalculateDamage(attacker, defender, ability)
    local baseDamage = ability.power
    local attackStat = attacker.stats.power
    local defenseStat = defender.stats.defense
    
    -- Apply status effect modifiers
    if attacker.statusEffects.strength then
        attackStat = attackStat * 1.3
    end
    if attacker.statusEffects.weakness then
        attackStat = attackStat * 0.7
    end
    
    -- Damage formula
    local damage = math.floor((baseDamage * attackStat / defenseStat) * (0.9 + math.random() * 0.2))
    
    -- Critical hit chance
    local critChance = 0.05 + (attacker.stats.luck / 1000)
    if math.random() < critChance then
        damage = damage * 2
        table.insert(battle.logs, {
            type = "critical",
            timestamp = tick()
        })
    end
    
    return damage
end

-- ========================================
-- END BATTLE
-- ========================================
function BattleSystem:EndBattle(battleId, winningSide)
    local battle = self.ActiveBattles[battleId]
    if not battle then return end
    
    battle.status = "ended"
    battle.winner = winningSide
    
    local winner = battle.players[winningSide]
    local loser = battle.players[winningSide == 1 and 2 or 1]
    
    -- Give rewards
    self:GiveBattleRewards(winner.player, true)
    self:GiveBattleRewards(loser.player, false)
    
    -- Update statistics
    local winnerData = DataStoreModule.PlayerData[winner.userId]
    local loserData = DataStoreModule.PlayerData[loser.userId]
    
    if winnerData then
        winnerData.statistics.battleStats.wins = (winnerData.statistics.battleStats.wins or 0) + 1
        winnerData.statistics.battleStats.winStreak = (winnerData.statistics.battleStats.winStreak or 0) + 1
        winnerData.statistics.battleStats.highestWinStreak = math.max(
            winnerData.statistics.battleStats.highestWinStreak or 0,
            winnerData.statistics.battleStats.winStreak
        )
        DataStoreModule:MarkPlayerDirty(winner.userId)
    end
    
    if loserData then
        loserData.statistics.battleStats.losses = (loserData.statistics.battleStats.losses or 0) + 1
        loserData.statistics.battleStats.winStreak = 0
        DataStoreModule:MarkPlayerDirty(loser.userId)
    end
    
    -- Update quest progress
    local QuestSystem = require(script.Parent.QuestSystem)
    QuestSystem:OnBattleWon(winner.player)
    
    -- Notify players
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("BattleEnded") then
        RemoteEvents.BattleEnded:FireClient(winner.player, {
            battleId = battleId,
            winner = true,
            rewards = BATTLE_CONFIG.BATTLE_REWARDS
        })
        RemoteEvents.BattleEnded:FireClient(loser.player, {
            battleId = battleId,
            winner = false,
            rewards = {
                coins = BATTLE_CONFIG.BATTLE_REWARDS.LOSE_COINS,
                xp = BATTLE_CONFIG.BATTLE_REWARDS.LOSE_XP
            }
        })
    end
    
    -- Clean up
    self.ActiveBattles[battleId] = nil
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================
function BattleSystem:GetPetAbilities(pet)
    local petData = PetDatabase:GetPet(pet.petId)
    local abilities = {"tackle"} -- Default ability
    
    if petData and petData.abilities then
        for _, ability in ipairs(petData.abilities) do
            if pet.level >= ability.unlockLevel then
                -- Map ability names to ability IDs
                local abilityId = ability.name:lower():gsub(" ", "_"):gsub("'", "")
                
                -- Add to ABILITIES table if not exists
                if not ABILITIES[abilityId] then
                    ABILITIES[abilityId] = {
                        name = ability.name,
                        description = ability.description,
                        power = ability.effect.value or ability.effect.damage or 50,
                        accuracy = 95,
                        type = ability.effect.type == "heal" and "support" or "special",
                        target = ability.effect.type:find("team") and "team" or "single",
                        cooldown = ability.cooldown,
                        effect = ability.effect
                    }
                end
                
                table.insert(abilities, abilityId)
            end
        end
    end
    
    return abilities
end

function BattleSystem:ApplyStatusEffect(pet, effect, duration)
    pet.statusEffects[effect] = {
        duration = duration,
        appliedAt = tick()
    }
end

function BattleSystem:CheckDefeatedPets(battle)
    for sideIndex, side in ipairs(battle.players) do
        local currentPet = side.team[side.currentPet]
        
        if currentPet and currentPet.currentHP <= 0 then
            -- Find next alive pet
            local foundAlive = false
            for i, pet in ipairs(side.team) do
                if pet.currentHP > 0 then
                    side.currentPet = i
                    foundAlive = true
                    break
                end
            end
            
            if not foundAlive then
                -- All pets defeated, end battle
                self:EndBattle(battle.id, sideIndex == 1 and 2 or 1)
                return
            end
        end
    end
end

function BattleSystem:NextTurn(battleId)
    local battle = self.ActiveBattles[battleId]
    if not battle then return end
    
    -- Update status effects
    for _, side in ipairs(battle.players) do
        for _, pet in ipairs(side.team) do
            for effect, data in pairs(pet.statusEffects) do
                data.duration = data.duration - 1
                if data.duration <= 0 then
                    pet.statusEffects[effect] = nil
                end
                
                -- Apply damage over time
                local effectConfig = BATTLE_CONFIG.STATUS_EFFECTS[effect]
                if effectConfig and effectConfig.damagePerTurn then
                    local damage = math.floor(pet.maxHP * effectConfig.damagePerTurn)
                    pet.currentHP = math.max(0, pet.currentHP - damage)
                end
            end
        end
    end
    
    -- Switch turn
    battle.turn = battle.turn + 1
    battle.turnPlayer = battle.turnPlayer == 1 and 2 or 1
    battle.turnStartTime = tick()
    
    -- Notify players
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("BattleTurnCompleted") then
        for i, side in ipairs(battle.players) do
            RemoteEvents.BattleTurnCompleted:FireClient(side.player, {
                battleId = battleId,
                battle = battle,
                yourTurn = battle.turnPlayer == i
            })
        end
    end
    
    -- Start turn timer
    self:StartTurnTimer(battleId)
end

function BattleSystem:StartTurnTimer(battleId)
    -- Auto-end turn after timeout
    spawn(function()
        wait(BATTLE_CONFIG.TURN_TIME)
        
        local battle = self.ActiveBattles[battleId]
        if battle and battle.status == "active" then
            -- Auto-execute basic attack
            local playerSide = battle.players[battle.turnPlayer]
            self:ExecuteAction(battleId, playerSide.player, {
                type = "ability",
                abilityId = "tackle"
            })
        end
    end)
end

function BattleSystem:GiveBattleRewards(player, won)
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if not playerData then return end
    
    local coins = won and BATTLE_CONFIG.BATTLE_REWARDS.WIN_COINS or BATTLE_CONFIG.BATTLE_REWARDS.LOSE_COINS
    local xp = won and BATTLE_CONFIG.BATTLE_REWARDS.WIN_XP or BATTLE_CONFIG.BATTLE_REWARDS.LOSE_XP
    
    playerData.currencies.coins = playerData.currencies.coins + coins
    playerData.battlePass.xp = (playerData.battlePass.xp or 0) + xp
    
    DataStoreModule:MarkPlayerDirty(player.UserId)
end

function BattleSystem:OnPlayerLeaving(player)
    -- End any active battles
    local battleId = self.PlayerBattles[player.UserId]
    if battleId then
        local battle = self.ActiveBattles[battleId]
        if battle then
            -- Determine winner (the other player)
            local winner = battle.players[1] == player and battle.players[2] or battle.players[1]
            
            -- End battle with forfeit
            self:EndBattle(battleId, winner, "Opponent disconnected")
        end
    end
    
    -- Clean up player data
    self.PlayerBattles[player.UserId] = nil
    self.BattleTeams[player.UserId] = nil
end

return BattleSystem