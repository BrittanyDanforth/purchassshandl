-- ========================================
-- BATTLE SYSTEM
-- ========================================
local BattleSystem = {
    activeBattles = {},
    battleArenas = {},
    
    initializeArenas = function()
        BattleSystem.battleArenas = {
            ["arena_classic"] = {
                name = "Classic Arena",
                description = "Standard battle arena",
                maxPlayers = 2,
                environment = "normal",
                rewards = {
                    winner = {coins = 1000, gems = 10, xp = 100},
                    loser = {coins = 100, gems = 1, xp = 25}
                }
            },
            ["arena_legendary"] = {
                name = "Legendary Arena",
                description = "High stakes battles for experienced players",
                minLevel = 50,
                maxPlayers = 2,
                environment = "legendary",
                rewards = {
                    winner = {coins = 10000, gems = 100, xp = 1000},
                    loser = {coins = 1000, gems = 10, xp = 250}
                }
            },
            ["arena_tournament"] = {
                name = "Tournament Arena",
                description = "Competitive tournament battles",
                maxPlayers = 16,
                environment = "tournament",
                tournamentMode = true,
                rewards = {
                    first = {coins = 100000, gems = 1000, xp = 10000, title = "Champion"},
                    second = {coins = 50000, gems = 500, xp = 5000, title = "Runner-up"},
                    third = {coins = 25000, gems = 250, xp = 2500, title = "Bronze"},
                    participant = {coins = 5000, gems = 50, xp = 500}
                }
            }
        }
    end,
    
    createBattle = function(player1, player2, arenaType)
        local battleId = HttpService:GenerateGUID(false)
        local arena = BattleSystem.battleArenas[arenaType]
        
        if not arena then return false, "Invalid arena" end
        
        local battle = {
            id = battleId,
            arena = arenaType,
            players = {player1, player2},
            teams = {
                [player1.UserId] = {
                    player = player1,
                    pets = {},
                    activePet = nil,
                    health = 0,
                    maxHealth = 0,
                    energy = 100,
                    shields = 0,
                    buffs = {},
                    debuffs = {}
                },
                [player2.UserId] = {
                    player = player2,
                    pets = {},
                    activePet = nil,
                    health = 0,
                    maxHealth = 0,
                    energy = 100,
                    shields = 0,
                    buffs = {},
                    debuffs = {}
                }
            },
            turn = 1,
            currentPlayer = player1.UserId,
            status = "preparing",
            startTime = nil,
            endTime = nil,
            winner = nil,
            turnHistory = {},
            damageDealt = {
                [player1.UserId] = 0,
                [player2.UserId] = 0
            }
        }
        
        BattleSystem.activeBattles[battleId] = battle
        
        return true, battleId
    end,
    
    loadPetsForBattle = function(battleId, player, petIds)
        local battle = BattleSystem.activeBattles[battleId]
        if not battle then return false end
        
        local playerData = PlayerData[player.UserId]
        if not playerData then return false end
        
        local team = battle.teams[player.UserId]
        if not team then return false end
        
        -- Validate and load pets
        for _, petId in ipairs(petIds) do
            local pet = nil
            for _, p in ipairs(playerData.pets) do
                if p.id == petId then
                    pet = p
                    break
                end
            end
            
            if pet then
                local petData = PetDatabase[pet.petId]
                if petData then
                    local battlePet = {
                        id = pet.id,
                        petId = pet.petId,
                        name = pet.name,
                        level = pet.level,
                        variant = pet.variant,
                        health = petData.baseStats.power * pet.level,
                        maxHealth = petData.baseStats.power * pet.level,
                        attack = petData.baseStats.power,
                        defense = petData.baseStats.power * 0.5,
                        speed = petData.baseStats.speed,
                        luck = petData.baseStats.luck,
                        abilities = petData.abilities,
                        cooldowns = {},
                        alive = true
                    }
                    
                    -- Apply variant bonuses
                    if pet.variant and petData.variants[pet.variant] then
                        local multiplier = petData.variants[pet.variant].multiplier
                        battlePet.health = battlePet.health * multiplier
                        battlePet.maxHealth = battlePet.maxHealth * multiplier
                        battlePet.attack = battlePet.attack * multiplier
                        battlePet.defense = battlePet.defense * multiplier
                    end
                    
                    table.insert(team.pets, battlePet)
                    team.health = team.health + battlePet.health
                    team.maxHealth = team.maxHealth + battlePet.maxHealth
                end
            end
        end
        
        -- Set first pet as active
        if #team.pets > 0 then
            team.activePet = team.pets[1]
        end
        
        return true
    end,
    
    startBattle = function(battleId)
        local battle = BattleSystem.activeBattles[battleId]
        if not battle then return false end
        
        -- Verify both teams have pets
        for userId, team in pairs(battle.teams) do
            if #team.pets == 0 then
                return false, "Team has no pets"
            end
        end
        
        battle.status = "active"
        battle.startTime = os.time()
        
        -- Determine who goes first based on speed
        local team1 = battle.teams[battle.players[1].UserId]
        local team2 = battle.teams[battle.players[2].UserId]
        
        local speed1 = 0
        local speed2 = 0
        
        for _, pet in ipairs(team1.pets) do
            speed1 = speed1 + pet.speed
        end
        
        for _, pet in ipairs(team2.pets) do
            speed2 = speed2 + pet.speed
        end
        
        if speed2 > speed1 then
            battle.currentPlayer = battle.players[2].UserId
        end
        
        return true
    end,
    
    executeAction = function(battleId, playerId, action)
        local battle = BattleSystem.activeBattles[battleId]
        if not battle then return false end
        
        if battle.status ~= "active" then return false end
        if battle.currentPlayer ~= playerId then return false end
        
        local attackerTeam = battle.teams[playerId]
        local defenderTeam = nil
        
        for userId, team in pairs(battle.teams) do
            if userId ~= playerId then
                defenderTeam = team
                break
            end
        end
        
        if not attackerTeam or not defenderTeam then return false end
        if not attackerTeam.activePet or not defenderTeam.activePet then return false end
        
        local result = {
            attacker = playerId,
            action = action,
            damage = 0,
            effects = {},
            critical = false,
            miss = false
        }
        
        if action.type == "attack" then
            -- Calculate damage
            local baseDamage = attackerTeam.activePet.attack
            local defense = defenderTeam.activePet.defense
            
            -- Apply ability modifiers
            if action.abilityIndex then
                local ability = attackerTeam.activePet.abilities[action.abilityIndex]
                if ability and not ability.passive then
                    -- Check cooldown
                    local cooldownKey = attackerTeam.activePet.id .. "_" .. action.abilityIndex
                    if attackerTeam.activePet.cooldowns[cooldownKey] and 
                       attackerTeam.activePet.cooldowns[cooldownKey] > battle.turn then
                        return false, "Ability on cooldown"
                    end
                    
                    -- Apply ability effects
                    if ability.effect == "damage_aoe" then
                        baseDamage = ability.value
                        result.aoe = true
                    elseif ability.effect == "heal_aoe" then
                        -- Heal all friendly pets
                        for _, pet in ipairs(attackerTeam.pets) do
                            if pet.alive then
                                pet.health = math.min(pet.maxHealth, pet.health + pet.maxHealth * ability.value)
                            end
                        end
                        result.heal = ability.value
                    end
                    
                    -- Set cooldown
                    attackerTeam.activePet.cooldowns[cooldownKey] = battle.turn + ability.cooldown
                end
            end
            
            -- Calculate critical hit
            local critChance = attackerTeam.activePet.luck / 100
            if math.random() < critChance then
                baseDamage = baseDamage * 2
                result.critical = true
            end
            
            -- Calculate miss chance
            local missChance = 0.05 -- 5% base miss chance
            if math.random() < missChance then
                result.miss = true
                baseDamage = 0
            end
            
            -- Apply defense
            local damage = math.max(1, baseDamage - defense)
            
            -- Apply shields
            if defenderTeam.shields > 0 then
                local shieldAbsorb = math.min(damage, defenderTeam.shields)
                damage = damage - shieldAbsorb
                defenderTeam.shields = defenderTeam.shields - shieldAbsorb
                result.shieldAbsorbed = shieldAbsorb
            end
            
            -- Deal damage
            defenderTeam.activePet.health = defenderTeam.activePet.health - damage
            defenderTeam.health = defenderTeam.health - damage
            result.damage = damage
            
            -- Track damage dealt
            battle.damageDealt[playerId] = battle.damageDealt[playerId] + damage
            
            -- Check if pet defeated
            if defenderTeam.activePet.health <= 0 then
                defenderTeam.activePet.alive = false
                result.defeated = true
                
                -- Switch to next pet
                local nextPet = nil
                for _, pet in ipairs(defenderTeam.pets) do
                    if pet.alive and pet.health > 0 then
                        nextPet = pet
                        break
                    end
                end
                
                if nextPet then
                    defenderTeam.activePet = nextPet
                    result.switched = nextPet.name
                else
                    -- All pets defeated, battle over
                    battle.status = "completed"
                    battle.winner = playerId
                    battle.endTime = os.time()
                    BattleSystem.endBattle(battleId)
                end
            end
            
        elseif action.type == "switch" then
            -- Switch active pet
            local newPet = nil
            for _, pet in ipairs(attackerTeam.pets) do
                if pet.id == action.petId and pet.alive then
                    newPet = pet
                    break
                end
            end
            
            if newPet then
                attackerTeam.activePet = newPet
                result.switched = newPet.name
            else
                return false, "Invalid pet switch"
            end
            
        elseif action.type == "item" then
            -- Use item (potions, revives, etc.)
            -- Implementation depends on item system
            
        elseif action.type == "forfeit" then
            battle.status = "completed"
            battle.winner = battle.currentPlayer == battle.players[1].UserId and 
                          battle.players[2].UserId or battle.players[1].UserId
            battle.endTime = os.time()
            result.forfeit = true
            BattleSystem.endBattle(battleId)
        end
        
        -- Record turn in history
        table.insert(battle.turnHistory, {
            turn = battle.turn,
            player = playerId,
            action = action,
            result = result,
            timestamp = os.time()
        })
        
        -- Switch turns
        battle.turn = battle.turn + 1
        battle.currentPlayer = battle.currentPlayer == battle.players[1].UserId and 
                             battle.players[2].UserId or battle.players[1].UserId
        
        return true, result
    end,
    
    endBattle = function(battleId)
        local battle = BattleSystem.activeBattles[battleId]
        if not battle then return end
        
        local arena = BattleSystem.battleArenas[battle.arena]
        if not arena then return end
        
        -- Award rewards
        for _, playerId in ipairs({battle.players[1].UserId, battle.players[2].UserId}) do
            local playerData = PlayerData[playerId]
            if playerData then
                local rewards = nil
                
                if battle.winner == playerId then
                    rewards = arena.rewards.winner
                    playerData.statistics.battleStats.wins = playerData.statistics.battleStats.wins + 1
                else
                    rewards = arena.rewards.loser
                    playerData.statistics.battleStats.losses = playerData.statistics.battleStats.losses + 1
                end
                
                if rewards then
                    if rewards.coins then
                        playerData.currencies.coins = playerData.currencies.coins + rewards.coins
                    end
                    if rewards.gems then
                        playerData.currencies.gems = playerData.currencies.gems + rewards.gems
                    end
                    if rewards.xp then
                        -- Add XP to pets that participated
                        local team = battle.teams[playerId]
                        for _, battlePet in ipairs(team.pets) do
                            for _, pet in ipairs(playerData.pets) do
                                if pet.id == battlePet.id then
                                    pet.experience = (pet.experience or 0) + rewards.xp
                                    -- Check for level up
                                    local xpNeeded = pet.level * 100
                                    while pet.experience >= xpNeeded do
                                        pet.experience = pet.experience - xpNeeded
                                        pet.level = pet.level + 1
                                        xpNeeded = pet.level * 100
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- Update battle statistics
                playerData.statistics.battleStats.damageDealt = 
                    playerData.statistics.battleStats.damageDealt + battle.damageDealt[playerId]
                
                SavePlayerData(Services.Players:GetPlayerByUserId(playerId))
            end
        end
        
        -- Clean up
        BattleSystem.activeBattles[battleId] = nil
    end
}

-- ========================================
-- CLAN/GUILD SYSTEM
-- ========================================
local ClanSystem = {
    clans = {},
    invitations = {},
    
    createClan = function(player, clanName, clanTag)
        local playerId = player.UserId
        local playerData = PlayerData[playerId]
        
        if not playerData then return false, "No player data" end
        
        -- Check if player is already in a clan
        if playerData.clan.id then
            return false, "Already in a clan"
        end
        
        -- Validate clan name and tag
        if #clanName < 3 or #clanName > 20 then
            return false, "Clan name must be 3-20 characters"
        end
        
        if #clanTag < 2 or #clanTag > 4 then
            return false, "Clan tag must be 2-4 characters"
        end
        
        -- Check if name or tag already exists
        for _, clan in pairs(ClanSystem.clans) do
            if clan.name == clanName then
                return false, "Clan name already taken"
            end
            if clan.tag == clanTag then
                return false, "Clan tag already taken"
            end
        end
        
        -- Create clan cost
        local createCost = 100000
        if playerData.currencies.coins < createCost then
            return false, "Not enough coins. Need " .. createCost
        end
        
        -- Deduct cost
        playerData.currencies.coins = playerData.currencies.coins - createCost
        
        -- Create clan
        local clanId = HttpService:GenerateGUID(false)
        local clan = {
            id = clanId,
            name = clanName,
            tag = clanTag,
            description = "",
            leaderId = playerId,
            createdAt = os.time(),
            level = 1,
            experience = 0,
            members = {
                [playerId] = {
                    userId = playerId,
                    username = player.Name,
                    role = "Leader",
                    joinDate = os.time(),
                    contribution = 0,
                    lastActive = os.time()
                }
            },
            treasury = {
                coins = 0,
                gems = 0
            },
            upgrades = {
                memberLimit = 10,
                expBonus = 0,
                luckBonus = 0,
                coinBonus = 0
            },
            settings = {
                public = true,
                minLevel = 1,
                autoAccept = false,
                requireApproval = true
            },
            statistics = {
                totalMembers = 1,
                totalContribution = 0,
                bossesDefeated = 0,
                eventsCompleted = 0
            },
            chat = {},
            announcements = {},
            wars = {
                active = {},
                history = {}
            }
        }
        
        ClanSystem.clans[clanId] = clan
        
        -- Update player data
        playerData.clan = {
            id = clanId,
            name = clanName,
            role = "Leader",
            contribution = 0,
            joinDate = os.time()
        }
        
        SavePlayerData(player)
        
        return true, clan
    end,
    
    invitePlayer = function(clanId, inviterPlayer, targetPlayerName)
        local clan = ClanSystem.clans[clanId]
        if not clan then return false, "Clan not found" end
        
        local inviterData = clan.members[inviterPlayer.UserId]
        if not inviterData then return false, "Not a clan member" end
        
        -- Check permissions
        if inviterData.role ~= "Leader" and inviterData.role ~= "Officer" then
            return false, "No permission to invite"
        end
        
        -- Find target player
        local targetPlayer = nil
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player.Name == targetPlayerName then
                targetPlayer = player
                break
            end
        end
        
        if not targetPlayer then return false, "Player not found" end
        
        local targetData = PlayerData[targetPlayer.UserId]
        if not targetData then return false, "Target player data not found" end
        
        if targetData.clan.id then
            return false, "Player is already in a clan"
        end
        
        -- Check if already invited
        local inviteKey = clanId .. "_" .. targetPlayer.UserId
        if ClanSystem.invitations[inviteKey] then
            return false, "Already invited"
        end
        
        -- Create invitation
        ClanSystem.invitations[inviteKey] = {
            clanId = clanId,
            clanName = clan.name,
            inviterId = inviterPlayer.UserId,
            inviterName = inviterPlayer.Name,
            targetId = targetPlayer.UserId,
            targetName = targetPlayer.Name,
            timestamp = os.time(),
            expiresAt = os.time() + 86400 -- 24 hours
        }
        
        return true
    end,
    
    acceptInvitation = function(player, clanId)
        local playerId = player.UserId
        local inviteKey = clanId .. "_" .. playerId
        local invitation = ClanSystem.invitations[inviteKey]
        
        if not invitation then return false, "No invitation found" end
        
        if os.time() > invitation.expiresAt then
            ClanSystem.invitations[inviteKey] = nil
            return false, "Invitation expired"
        end
        
        local clan = ClanSystem.clans[clanId]
        if not clan then return false, "Clan not found" end
        
        local playerData = PlayerData[playerId]
        if not playerData then return false, "No player data" end
        
        if playerData.clan.id then
            return false, "Already in a clan"
        end
        
        -- Check member limit
        local memberCount = 0
        for _ in pairs(clan.members) do
            memberCount = memberCount + 1
        end
        
        if memberCount >= clan.upgrades.memberLimit then
            return false, "Clan is full"
        end
        
        -- Add to clan
        clan.members[playerId] = {
            userId = playerId,
            username = player.Name,
            role = "Member",
            joinDate = os.time(),
            contribution = 0,
            lastActive = os.time()
        }
        
        clan.statistics.totalMembers = clan.statistics.totalMembers + 1
        
        -- Update player data
        playerData.clan = {
            id = clanId,
            name = clan.name,
            role = "Member",
            contribution = 0,
            joinDate = os.time()
        }
        
        -- Remove invitation
        ClanSystem.invitations[inviteKey] = nil
        
        -- Add join announcement
        table.insert(clan.announcements, {
            type = "member_joined",
            message = player.Name .. " has joined the clan!",
            timestamp = os.time()
        })
        
        SavePlayerData(player)
        
        return true
    end,
    
    contributeToClan = function(player, currencyType, amount)
        local playerId = player.UserId
        local playerData = PlayerData[playerId]
        
        if not playerData then return false, "No player data" end
        if not playerData.clan.id then return false, "Not in a clan" end
        
        local clan = ClanSystem.clans[playerData.clan.id]
        if not clan then return false, "Clan not found" end
        
        -- Validate currency
        if not playerData.currencies[currencyType] then
            return false, "Invalid currency type"
        end
        
        if playerData.currencies[currencyType] < amount then
            return false, "Not enough " .. currencyType
        end
        
        if amount <= 0 then return false, "Invalid amount" end
        
        -- Make contribution
        playerData.currencies[currencyType] = playerData.currencies[currencyType] - amount
        clan.treasury[currencyType] = (clan.treasury[currencyType] or 0) + amount
        
        -- Update contribution stats
        local member = clan.members[playerId]
        if member then
            member.contribution = member.contribution + amount
            member.lastActive = os.time()
        end
        
        playerData.clan.contribution = playerData.clan.contribution + amount
        clan.statistics.totalContribution = clan.statistics.totalContribution + amount
        
        -- Award clan XP
        local xpGained = math.floor(amount / 100)
        clan.experience = clan.experience + xpGained
        
        -- Check for level up
        local xpNeeded = clan.level * 10000
        while clan.experience >= xpNeeded do
            clan.experience = clan.experience - xpNeeded
            clan.level = clan.level + 1
            
            -- Apply level rewards
            if clan.level % 5 == 0 then
                clan.upgrades.memberLimit = clan.upgrades.memberLimit + 5
            end
            if clan.level % 10 == 0 then
                clan.upgrades.expBonus = clan.upgrades.expBonus + 0.05
                clan.upgrades.luckBonus = clan.upgrades.luckBonus + 0.02
                clan.upgrades.coinBonus = clan.upgrades.coinBonus + 0.1
            end
            
            xpNeeded = clan.level * 10000
        end
        
        SavePlayerData(player)
        
        return true
    end,
    
    startClanWar = function(clan1Id, clan2Id)
        local clan1 = ClanSystem.clans[clan1Id]
        local clan2 = ClanSystem.clans[clan2Id]
        
        if not clan1 or not clan2 then return false, "Invalid clans" end
        
        -- Check if already in war
        for _, war in ipairs(clan1.wars.active) do
            if war.opponent == clan2Id then
                return false, "Already at war with this clan"
            end
        end
        
        local warId = HttpService:GenerateGUID(false)
        local war = {
            id = warId,
            clan1 = {
                id = clan1Id,
                name = clan1.name,
                score = 0,
                participants = {}
            },
            clan2 = {
                id = clan2Id,
                name = clan2.name,
                score = 0,
                participants = {}
            },
            startTime = os.time(),
            endTime = os.time() + 86400, -- 24 hour war
            status = "active",
            battles = {},
            rewards = {
                winner = {coins = 1000000, gems = 10000, clanXP = 50000},
                loser = {coins = 100000, gems = 1000, clanXP = 5000}
            }
        }
        
        table.insert(clan1.wars.active, war)
        table.insert(clan2.wars.active, war)
        
        return true, war
    end,
    
    -- Auto-save clan data periodically
    saveClanData = function()
        -- In a real implementation, this would save to DataStore
        -- For now, it's kept in memory
    end
}

-- ========================================
-- QUEST & ACHIEVEMENT SYSTEM
-- ========================================
local QuestSystem = {
    questTemplates = {
        daily = {
            {
                id = "daily_hatch_5",
                name = "Egg Collector",
                description = "Hatch 5 eggs",
                type = "hatch_eggs",
                target = 5,
                rewards = {coins = 5000, gems = 50, xp = 100},
                resetTime = 86400
            },
            {
                id = "daily_battle_3",
                name = "Battle Master",
                description = "Win 3 battles",
                type = "win_battles",
                target = 3,
                rewards = {coins = 10000, gems = 100, xp = 200},
                resetTime = 86400
            },
            {
                id = "daily_trade_1",
                name = "Trader",
                description = "Complete 1 trade",
                type = "complete_trades",
                target = 1,
                rewards = {coins = 3000, gems = 30, xp = 50},
                resetTime = 86400
            }
        },
        weekly = {
            {
                id = "weekly_legendary",
                name = "Legendary Hunter",
                description = "Hatch a legendary pet",
                type = "hatch_legendary",
                target = 1,
                rewards = {coins = 50000, gems = 500, xp = 1000},
                resetTime = 604800
            },
            {
                id = "weekly_battles_20",
                name = "Battle Champion",
                description = "Win 20 battles",
                type = "win_battles",
                target = 20,
                rewards = {coins = 100000, gems = 1000, xp = 2000},
                resetTime = 604800
            }
        },
        special = {
            {
                id = "special_first_mythical",
                name = "Mythical Discovery",
                description = "Hatch your first mythical pet",
                type = "hatch_mythical",
                target = 1,
                rewards = {coins = 1000000, gems = 10000, title = "Mythical Master"},
                oneTime = true
            }
        }
    },
    
    achievements = {
        {
            id = "newbie",
            name = "Welcome!",
            description = "Join the game for the first time",
            points = 10,
            rewards = {title = "Newbie"},
            hidden = false
        },
        {
            id = "first_pet",
            name = "Pet Owner",
            description = "Hatch your first pet",
            points = 25,
            rewards = {coins = 1000, title = "Pet Owner"},
            hidden = false
        },
        {
            id = "millionaire",
            name = "Millionaire",
            description = "Accumulate 1,000,000 coins",
            points = 100,
            rewards = {gems = 1000, title = "Millionaire"},
            hidden = false
        },
        {
            id = "legendary_collector",
            name = "Legendary Collector",
            description = "Own 10 legendary pets",
            points = 500,
            rewards = {gems = 5000, title = "Legendary Collector"},
            hidden = false
        },
        {
            id = "secret_finder",
            name = "Secret Finder",
            description = "Discover a secret pet",
            points = 1000,
            rewards = {gems = 50000, title = "Secret Finder"},
            hidden = true
        }
    },
    
    assignDailyQuests = function(player)
        local playerData = PlayerData[player.UserId]
        if not playerData then return end
        
        -- Clear old daily quests
        playerData.quests.daily = {}
        
        -- Assign 3 random daily quests
        local availableQuests = {}
        for _, quest in ipairs(QuestSystem.questTemplates.daily) do
            table.insert(availableQuests, quest)
        end
        
        for i = 1, 3 do
            if #availableQuests > 0 then
                local index = math.random(1, #availableQuests)
                local questTemplate = availableQuests[index]
                
                local quest = {
                    id = questTemplate.id,
                    name = questTemplate.name,
                    description = questTemplate.description,
                    type = questTemplate.type,
                    target = questTemplate.target,
                    progress = 0,
                    completed = false,
                    claimed = false,
                    rewards = questTemplate.rewards,
                    assignedAt = os.time(),
                    expiresAt = os.time() + questTemplate.resetTime
                }
                
                table.insert(playerData.quests.daily, quest)
                table.remove(availableQuests, index)
            end
        end
        
        SavePlayerData(player)
    end,
    
    updateQuestProgress = function(player, questType, amount)
        local playerData = PlayerData[player.UserId]
        if not playerData then return end
        
        -- Check all active quests
        for _, questList in pairs({playerData.quests.daily, playerData.quests.weekly, playerData.quests.special}) do
            for _, quest in ipairs(questList) do
                if quest.type == questType and not quest.completed then
                    quest.progress = math.min(quest.progress + amount, quest.target)
                    
                    if quest.progress >= quest.target then
                        quest.completed = true
                        
                        -- Send notification
                        -- NotificationSystem.send(player, "Quest completed: " .. quest.name)
                    end
                end
            end
        end
        
        SavePlayerData(player)
    end,
    
    claimQuestReward = function(player, questId)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false end
        
        -- Find quest
        local quest = nil
        local questList = nil
        
        for listName, list in pairs({daily = playerData.quests.daily, weekly = playerData.quests.weekly, special = playerData.quests.special}) do
            for _, q in ipairs(list) do
                if q.id == questId then
                    quest = q
                    questList = listName
                    break
                end
            end
            if quest then break end
        end
        
        if not quest then return false, "Quest not found" end
        if not quest.completed then return false, "Quest not completed" end
        if quest.claimed then return false, "Already claimed" end
        
        -- Award rewards
        if quest.rewards.coins then
            playerData.currencies.coins = playerData.currencies.coins + quest.rewards.coins
        end
        if quest.rewards.gems then
            playerData.currencies.gems = playerData.currencies.gems + quest.rewards.gems
        end
        if quest.rewards.title then
            table.insert(playerData.titles.owned, quest.rewards.title)
        end
        
        quest.claimed = true
        
        -- Add to completed quests
        table.insert(playerData.quests.completed, {
            id = quest.id,
            name = quest.name,
            completedAt = os.time()
        })
        
        SavePlayerData(player)
        
        return true
    end,
    
    checkAchievements = function(player)
        local playerData = PlayerData[player.UserId]
        if not playerData then return end
        
        for _, achievement in ipairs(QuestSystem.achievements) do
            -- Check if already earned
            local earned = false
            for _, earnedAch in ipairs(playerData.achievements) do
                if earnedAch.id == achievement.id then
                    earned = true
                    break
                end
            end
            
            if not earned then
                local qualified = false
                
                -- Check achievement conditions
                if achievement.id == "newbie" then
                    qualified = true
                elseif achievement.id == "first_pet" then
                    qualified = #playerData.pets > 0
                elseif achievement.id == "millionaire" then
                    qualified = playerData.currencies.coins >= 1000000
                elseif achievement.id == "legendary_collector" then
                    local legendaryCount = 0
                    for _, pet in ipairs(playerData.pets) do
                        local petData = PetDatabase[pet.petId]
                        if petData and petData.rarity >= 5 then
                            legendaryCount = legendaryCount + 1
                        end
                    end
                    qualified = legendaryCount >= 10
                end
                
                if qualified then
                    -- Award achievement
                    table.insert(playerData.achievements, {
                        id = achievement.id,
                        earnedAt = os.time()
                    })
                    
                    -- Award rewards
                    if achievement.rewards then
                        if achievement.rewards.coins then
                            playerData.currencies.coins = playerData.currencies.coins + achievement.rewards.coins
                        end
                        if achievement.rewards.gems then
                            playerData.currencies.gems = playerData.currencies.gems + achievement.rewards.gems
                        end
                        if achievement.rewards.title then
                            table.insert(playerData.titles.owned, achievement.rewards.title)
                        end
                    end
                    
                    -- Notification
                    -- NotificationSystem.send(player, "Achievement unlocked: " .. achievement.name)
                end
            end
        end
        
        SavePlayerData(player)
    end
}

-- ========================================
-- DAILY REWARDS & BATTLE PASS
-- ========================================
local DailyRewardSystem = {
    rewards = {
        {day = 1, coins = 1000, gems = 10},
        {day = 2, coins = 2000, gems = 20},
        {day = 3, coins = 3000, gems = 30},
        {day = 4, coins = 5000, gems = 50},
        {day = 5, coins = 7500, gems = 75},
        {day = 6, coins = 10000, gems = 100},
        {day = 7, coins = 15000, gems = 150, special = "legendary_egg"}
    },
    
    claimDailyReward = function(player)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false end
        
        local currentTime = os.time()
        local lastClaim = playerData.dailyRewards.lastClaim
        local timeSinceClaim = currentTime - lastClaim
        
        -- Check if can claim
        if timeSinceClaim < 86400 then -- 24 hours
            local timeLeft = 86400 - timeSinceClaim
            return false, "Come back in " .. math.floor(timeLeft / 3600) .. " hours"
        end
        
        -- Check if streak is broken (48 hour grace period)
        if timeSinceClaim > 172800 then
            playerData.dailyRewards.streak = 0
        end
        
        -- Increment streak
        playerData.dailyRewards.streak = playerData.dailyRewards.streak + 1
        
        -- Get reward for current day (loops after 7 days)
        local rewardDay = ((playerData.dailyRewards.streak - 1) % 7) + 1
        local reward = DailyRewardSystem.rewards[rewardDay]
        
        -- Apply multiplier
        local multiplier = playerData.dailyRewards.multiplier or 1
        
        -- Award rewards
        playerData.currencies.coins = playerData.currencies.coins + math.floor(reward.coins * multiplier)
        playerData.currencies.gems = playerData.currencies.gems + math.floor(reward.gems * multiplier)
        
        -- Special rewards
        if reward.special then
            if reward.special == "legendary_egg" then
                -- Award a free legendary egg
                -- Implementation depends on inventory system
            end
        end
        
        -- Update claim time
        playerData.dailyRewards.lastClaim = currentTime
        
        SavePlayerData(player)
        
        return true, reward
    end
}

local BattlePassSystem = {
    season = 1,
    tiers = 100,
    
    rewards = {
        free = {},
        premium = {}
    },
    
    initializeRewards = function()
        for tier = 1, BattlePassSystem.tiers do
            -- Free rewards
            BattlePassSystem.rewards.free[tier] = {
                tier = tier,
                coins = tier * 1000,
                gems = tier * 10
            }
            
            -- Premium rewards
            BattlePassSystem.rewards.premium[tier] = {
                tier = tier,
                coins = tier * 2500,
                gems = tier * 25,
                pets = {}
            }
            
            -- Special tier rewards
            if tier % 10 == 0 then
                BattlePassSystem.rewards.free[tier].special = "rare_egg"
                BattlePassSystem.rewards.premium[tier].special = "legendary_egg"
            end
            
            if tier == 50 then
                BattlePassSystem.rewards.premium[tier].exclusive = "battle_pass_pet_50"
            end
            
            if tier == 100 then
                BattlePassSystem.rewards.premium[tier].exclusive = "battle_pass_pet_100"
                BattlePassSystem.rewards.premium[tier].title = "Season " .. BattlePassSystem.season .. " Champion"
            end
        end
    end,
    
    addExperience = function(player, amount)
        local playerData = PlayerData[player.UserId]
        if not playerData then return end
        
        playerData.battlePass.experience = playerData.battlePass.experience + amount
        
        -- Calculate tier
        local xpPerTier = 1000
        local oldTier = playerData.battlePass.level
        local newTier = math.floor(playerData.battlePass.experience / xpPerTier) + 1
        
        if newTier > oldTier then
            playerData.battlePass.level = math.min(newTier, BattlePassSystem.tiers)
            
            -- Auto-claim rewards for tiers passed
            for tier = oldTier + 1, newTier do
                BattlePassSystem.claimTierReward(player, tier)
            end
        end
        
        SavePlayerData(player)
    end,
    
    claimTierReward = function(player, tier)
        local playerData = PlayerData[player.UserId]
        if not playerData then return false end
        
        if tier > playerData.battlePass.level then
            return false, "Tier not reached"
        end
        
        -- Check if already claimed
        for _, claimedTier in ipairs(playerData.battlePass.claimedRewards) do
            if claimedTier == tier then
                return false, "Already claimed"
            end
        end
        
        -- Get rewards
        local freeReward = BattlePassSystem.rewards.free[tier]
        local premiumReward = BattlePassSystem.rewards.premium[tier]
        
        -- Award free rewards
        if freeReward then
            if freeReward.coins then
                playerData.currencies.coins = playerData.currencies.coins + freeReward.coins
            end
            if freeReward.gems then
                playerData.currencies.gems = playerData.currencies.gems + freeReward.gems
            end
        end
        
        -- Award premium rewards if owned
        if playerData.battlePass.premiumOwned and premiumReward then
            if premiumReward.coins then
                playerData.currencies.coins = playerData.currencies.coins + premiumReward.coins
            end
            if premiumReward.gems then
                playerData.currencies.gems = playerData.currencies.gems + premiumReward.gems
            end
            if premiumReward.exclusive then
                -- Award exclusive pet
                -- Implementation depends on pet system
            end
            if premiumReward.title then
                table.insert(playerData.titles.owned, premiumReward.title)
            end
        end
        
        -- Mark as claimed
        table.insert(playerData.battlePass.claimedRewards, tier)
        
        SavePlayerData(player)
        
        return true
    end
}

-- Initialize battle pass rewards
BattlePassSystem.initializeRewards()

-- ========================================
-- Continue in next part...
-- ========================================