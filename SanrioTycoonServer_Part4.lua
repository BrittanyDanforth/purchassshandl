-- ========================================
-- TRADING SYSTEM
-- ========================================
local TradingSystem = {}

function TradingSystem:CreateTrade(player1, player2)
    local tradeId = Services.HttpService:GenerateGUID(false)
    
    local trade = {
        id = tradeId,
        player1 = {
            userId = player1.UserId,
            player = player1,
            items = {
                pets = {},
                currencies = {coins = 0, gems = 0, tickets = 0},
                items = {}
            },
            ready = false,
            confirmed = false
        },
        player2 = {
            userId = player2.UserId,
            player = player2,
            items = {
                pets = {},
                currencies = {coins = 0, gems = 0, tickets = 0},
                items = {}
            },
            ready = false,
            confirmed = false
        },
        status = "pending",
        createdAt = tick(),
        expiresAt = tick() + CONFIG.TRADE_EXPIRY_TIME
    }
    
    ActiveTrades[tradeId] = trade
    
    -- Notify players
    if RemoteEvents.TradeStarted then
        RemoteEvents.TradeStarted:FireClient(player1, trade)
        RemoteEvents.TradeStarted:FireClient(player2, trade)
    end
    
    return trade
end

function TradingSystem:AddItem(tradeId, player, itemType, itemData)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "pending" then
        return false, "Trade is not active"
    end
    
    local tradePlayer = nil
    if trade.player1.userId == player.UserId then
        tradePlayer = trade.player1
    elseif trade.player2.userId == player.UserId then
        tradePlayer = trade.player2
    else
        return false, "Player not in trade"
    end
    
    -- Reset ready status when items change
    trade.player1.ready = false
    trade.player2.ready = false
    
    if itemType == "pet" then
        if #tradePlayer.items.pets >= CONFIG.MAX_TRADE_ITEMS then
            return false, "Maximum pets reached"
        end
        
        -- Verify pet ownership
        local playerData = PlayerData[player.UserId]
        local ownsPet = false
        for _, pet in ipairs(playerData.pets) do
            if pet.id == itemData.id and not pet.locked then
                ownsPet = true
                break
            end
        end
        
        if not ownsPet then
            return false, "You don't own this pet"
        end
        
        table.insert(tradePlayer.items.pets, itemData)
        
    elseif itemType == "currency" then
        local playerData = PlayerData[player.UserId]
        local currencyType = itemData.type
        local amount = itemData.amount
        
        if amount <= 0 then
            return false, "Invalid amount"
        end
        
        if playerData.currencies[currencyType] < amount then
            return false, "Insufficient " .. currencyType
        end
        
        tradePlayer.items.currencies[currencyType] = amount
        
    elseif itemType == "item" then
        -- Handle inventory items
        -- TODO: Implement inventory item trading
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:RemoveItem(tradeId, player, itemType, itemData)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "pending" then
        return false, "Trade is not active"
    end
    
    local tradePlayer = nil
    if trade.player1.userId == player.UserId then
        tradePlayer = trade.player1
    elseif trade.player2.userId == player.UserId then
        tradePlayer = trade.player2
    else
        return false, "Player not in trade"
    end
    
    -- Reset ready status
    trade.player1.ready = false
    trade.player2.ready = false
    
    if itemType == "pet" then
        for i, pet in ipairs(tradePlayer.items.pets) do
            if pet.id == itemData.id then
                table.remove(tradePlayer.items.pets, i)
                break
            end
        end
    elseif itemType == "currency" then
        tradePlayer.items.currencies[itemData.type] = 0
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:SetReady(tradeId, player, ready)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.player1.userId == player.UserId then
        trade.player1.ready = ready
    elseif trade.player2.userId == player.UserId then
        trade.player2.ready = ready
    else
        return false, "Player not in trade"
    end
    
    -- Check if both ready
    if trade.player1.ready and trade.player2.ready then
        trade.status = "ready"
    else
        trade.status = "pending"
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:ConfirmTrade(tradeId, player)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "ready" then
        return false, "Both players must be ready"
    end
    
    if trade.player1.userId == player.UserId then
        trade.player1.confirmed = true
    elseif trade.player2.userId == player.UserId then
        trade.player2.confirmed = true
    else
        return false, "Player not in trade"
    end
    
    -- Execute trade if both confirmed
    if trade.player1.confirmed and trade.player2.confirmed then
        return self:ExecuteTrade(tradeId)
    end
    
    -- Update both players
    if RemoteEvents.TradeUpdated then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:ExecuteTrade(tradeId)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    local player1Data = PlayerData[trade.player1.userId]
    local player2Data = PlayerData[trade.player2.userId]
    
    if not player1Data or not player2Data then
        return false, "Player data not found"
    end
    
    -- Validate all items still exist and are valid
    -- Player 1 validation
    for _, pet in ipairs(trade.player1.items.pets) do
        local found = false
        for _, ownedPet in ipairs(player1Data.pets) do
            if ownedPet.id == pet.id and not ownedPet.locked then
                found = true
                break
            end
        end
        if not found then
            return false, "Player 1 no longer owns pet: " .. pet.name
        end
    end
    
    for currency, amount in pairs(trade.player1.items.currencies) do
        if player1Data.currencies[currency] < amount then
            return false, "Player 1 has insufficient " .. currency
        end
    end
    
    -- Player 2 validation
    for _, pet in ipairs(trade.player2.items.pets) do
        local found = false
        for _, ownedPet in ipairs(player2Data.pets) do
            if ownedPet.id == pet.id and not ownedPet.locked then
                found = true
                break
            end
        end
        if not found then
            return false, "Player 2 no longer owns pet: " .. pet.name
        end
    end
    
    for currency, amount in pairs(trade.player2.items.currencies) do
        if player2Data.currencies[currency] < amount then
            return false, "Player 2 has insufficient " .. currency
        end
    end
    
    -- Calculate trade value for statistics
    local tradeValue = 0
    
    -- Execute the trade
    -- Remove items from player 1
    for _, pet in ipairs(trade.player1.items.pets) do
        for i, ownedPet in ipairs(player1Data.pets) do
            if ownedPet.id == pet.id then
                table.remove(player1Data.pets, i)
                local petData = PetDatabase[ownedPet.petId]
                if petData then
                    tradeValue = tradeValue + petData.baseValue
                end
                break
            end
        end
    end
    
    for currency, amount in pairs(trade.player1.items.currencies) do
        player1Data.currencies[currency] = player1Data.currencies[currency] - amount
        tradeValue = tradeValue + amount
    end
    
    -- Remove items from player 2
    for _, pet in ipairs(trade.player2.items.pets) do
        for i, ownedPet in ipairs(player2Data.pets) do
            if ownedPet.id == pet.id then
                table.remove(player2Data.pets, i)
                local petData = PetDatabase[ownedPet.petId]
                if petData then
                    tradeValue = tradeValue + petData.baseValue
                end
                break
            end
        end
    end
    
    for currency, amount in pairs(trade.player2.items.currencies) do
        player2Data.currencies[currency] = player2Data.currencies[currency] - amount
        tradeValue = tradeValue + amount
    end
    
    -- Apply trade tax
    local taxAmount = math.floor(tradeValue * CONFIG.TRADE_TAX_PERCENTAGE)
    
    -- Add items to player 1 (from player 2)
    for _, pet in ipairs(trade.player2.items.pets) do
        pet.owner = trade.player1.userId
        pet.tradedFrom = trade.player2.userId
        pet.tradedAt = os.time()
        table.insert(player1Data.pets, pet)
    end
    
    for currency, amount in pairs(trade.player2.items.currencies) do
        local afterTax = math.floor(amount * (1 - CONFIG.TRADE_TAX_PERCENTAGE))
        player1Data.currencies[currency] = player1Data.currencies[currency] + afterTax
    end
    
    -- Add items to player 2 (from player 1)
    for _, pet in ipairs(trade.player1.items.pets) do
        pet.owner = trade.player2.userId
        pet.tradedFrom = trade.player1.userId
        pet.tradedAt = os.time()
        table.insert(player2Data.pets, pet)
    end
    
    for currency, amount in pairs(trade.player1.items.currencies) do
        local afterTax = math.floor(amount * (1 - CONFIG.TRADE_TAX_PERCENTAGE))
        player2Data.currencies[currency] = player2Data.currencies[currency] + afterTax
    end
    
    -- Update statistics
    player1Data.statistics.tradingStats.tradesCompleted = player1Data.statistics.tradingStats.tradesCompleted + 1
    player2Data.statistics.tradingStats.tradesCompleted = player2Data.statistics.tradingStats.tradesCompleted + 1
    
    player1Data.statistics.tradingStats.totalTradeValue = player1Data.statistics.tradingStats.totalTradeValue + tradeValue
    player2Data.statistics.tradingStats.totalTradeValue = player2Data.statistics.tradingStats.totalTradeValue + tradeValue
    
    -- Add to trade history
    local tradeRecord = {
        tradeId = tradeId,
        partner = trade.player2.userId,
        gave = trade.player1.items,
        received = trade.player2.items,
        timestamp = os.time(),
        value = tradeValue
    }
    table.insert(player1Data.trading.history, tradeRecord)
    
    tradeRecord = {
        tradeId = tradeId,
        partner = trade.player1.userId,
        gave = trade.player2.items,
        received = trade.player1.items,
        timestamp = os.time(),
        value = tradeValue
    }
    table.insert(player2Data.trading.history, tradeRecord)
    
    -- Save to DataStore
    SavePlayerData(trade.player1.player)
    SavePlayerData(trade.player2.player)
    
    -- Save trade to history
    spawn(function()
        pcall(function()
            DataStores.TradeHistory:SetAsync(tradeId, {
                player1 = trade.player1.userId,
                player2 = trade.player2.userId,
                items1 = trade.player1.items,
                items2 = trade.player2.items,
                timestamp = os.time(),
                value = tradeValue,
                tax = taxAmount
            })
        end)
    end)
    
    -- Mark trade as completed
    trade.status = "completed"
    trade.completedAt = tick()
    
    -- Notify players
    if RemoteEvents.TradeCompleted then
        RemoteEvents.TradeCompleted:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeCompleted:FireClient(trade.player2.player, trade)
    end
    
    -- Clean up
    ActiveTrades[tradeId] = nil
    
    -- Log analytics
    ServerAnalytics:LogEvent("TradeCompleted", nil, {
        player1 = trade.player1.userId,
        player2 = trade.player2.userId,
        value = tradeValue,
        tax = taxAmount
    })
    
    return true
end

function TradingSystem:CancelTrade(tradeId, player)
    local trade = ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.player1.userId ~= player.UserId and trade.player2.userId ~= player.UserId then
        return false, "Player not in trade"
    end
    
    trade.status = "cancelled"
    trade.cancelledBy = player.UserId
    trade.cancelledAt = tick()
    
    -- Notify players
    if RemoteEvents.TradeCancelled then
        RemoteEvents.TradeCancelled:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeCancelled:FireClient(trade.player2.player, trade)
    end
    
    -- Update statistics
    local player1Data = PlayerData[trade.player1.userId]
    local player2Data = PlayerData[trade.player2.userId]
    
    if player1Data then
        player1Data.statistics.tradingStats.tradesDeclined = player1Data.statistics.tradingStats.tradesDeclined + 1
    end
    if player2Data then
        player2Data.statistics.tradingStats.tradesDeclined = player2Data.statistics.tradingStats.tradesDeclined + 1
    end
    
    -- Clean up
    ActiveTrades[tradeId] = nil
    
    return true
end

-- ========================================
-- BATTLE SYSTEM
-- ========================================
local BattleSystem = {}

function BattleSystem:CreateBattle(player1, player2, battleType)
    local battleId = Services.HttpService:GenerateGUID(false)
    
    local battle = {
        id = battleId,
        type = battleType or "pvp",
        player1 = {
            userId = player1.UserId,
            player = player1,
            pets = {},
            activePet = nil,
            health = 0,
            maxHealth = 0,
            energy = 100,
            buffs = {},
            debuffs = {}
        },
        player2 = {
            userId = player2.UserId,
            player = player2,
            pets = {},
            activePet = nil,
            health = 0,
            maxHealth = 0,
            energy = 100,
            buffs = {},
            debuffs = {}
        },
        turn = 1,
        currentPlayer = 1,
        status = "preparing",
        startedAt = nil,
        endedAt = nil,
        winner = nil,
        turnHistory = {},
        rewards = {}
    }
    
    BattleInstances[battleId] = battle
    
    -- Notify players
    if RemoteEvents.BattleStarted then
        RemoteEvents.BattleStarted:FireClient(player1, battle)
        RemoteEvents.BattleStarted:FireClient(player2, battle)
    end
    
    return battle
end

function BattleSystem:SetupBattleTeam(battleId, player, petIds)
    local battle = BattleInstances[battleId]
    if not battle then return false, "Battle not found" end
    
    if battle.status ~= "preparing" then
        return false, "Battle already started"
    end
    
    local battlePlayer = nil
    if battle.player1.userId == player.UserId then
        battlePlayer = battle.player1
    elseif battle.player2.userId == player.UserId then
        battlePlayer = battle.player2
    else
        return false, "Player not in battle"
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then return false, "Player data not found" end
    
    -- Validate pets
    battlePlayer.pets = {}
    for _, petId in ipairs(petIds) do
        for _, pet in ipairs(playerData.pets) do
            if pet.id == petId then
                local petData = PetDatabase[pet.petId]
                if petData then
                    local battlePet = {
                        id = pet.id,
                        petId = pet.petId,
                        name = pet.nickname or petData.displayName,
                        level = pet.level,
                        stats = {},
                        abilities = petData.abilities,
                        currentHealth = pet.stats.health,
                        maxHealth = pet.stats.health,
                        currentEnergy = pet.stats.energy,
                        maxEnergy = pet.stats.energy,
                        buffs = {},
                        debuffs = {},
                        cooldowns = {}
                    }
                    
                    -- Copy stats
                    for stat, value in pairs(pet.stats) do
                        battlePet.stats[stat] = value
                    end
                    
                    table.insert(battlePlayer.pets, battlePet)
                end
                break
            end
        end
    end
    
    if #battlePlayer.pets == 0 then
        return false, "No valid pets selected"
    end
    
    -- Set first pet as active
    battlePlayer.activePet = 1
    local activePet = battlePlayer.pets[1]
    battlePlayer.health = activePet.currentHealth
    battlePlayer.maxHealth = activePet.maxHealth
    
    -- Check if both players ready
    if #battle.player1.pets > 0 and #battle.player2.pets > 0 then
        battle.status = "active"
        battle.startedAt = tick()
        
        -- Notify players
        if RemoteEvents.BattleReady then
            RemoteEvents.BattleReady:FireClient(battle.player1.player, battle)
            RemoteEvents.BattleReady:FireClient(battle.player2.player, battle)
        end
    end
    
    return true
end

function BattleSystem:ExecuteTurn(battleId, player, action)
    local battle = BattleInstances[battleId]
    if not battle then return false, "Battle not found" end
    
    if battle.status ~= "active" then
        return false, "Battle not active"
    end
    
    -- Verify it's player's turn
    local playerNum = 0
    if battle.player1.userId == player.UserId then
        playerNum = 1
    elseif battle.player2.userId == player.UserId then
        playerNum = 2
    else
        return false, "Player not in battle"
    end
    
    if battle.currentPlayer ~= playerNum then
        return false, "Not your turn"
    end
    
    local attacker = playerNum == 1 and battle.player1 or battle.player2
    local defender = playerNum == 1 and battle.player2 or battle.player1
    
    local attackerPet = attacker.pets[attacker.activePet]
    local defenderPet = defender.pets[defender.activePet]
    
    if not attackerPet or not defenderPet then
        return false, "Invalid pet state"
    end
    
    local turnResult = {
        turn = battle.turn,
        attacker = playerNum,
        action = action,
        damage = 0,
        healing = 0,
        effects = {},
        critical = false
    }
    
    if action.type == "ability" then
        local ability = nil
        for _, ab in ipairs(attackerPet.abilities) do
            if ab.id == action.abilityId then
                ability = ab
                break
            end
        end
        
        if not ability then
            return false, "Invalid ability"
        end
        
        -- Check cooldown
        if attackerPet.cooldowns[ability.id] and attackerPet.cooldowns[ability.id] > 0 then
            return false, "Ability on cooldown"
        end
        
        -- Check energy
        if ability.energyCost and attackerPet.currentEnergy < ability.energyCost then
            return false, "Not enough energy"
        end
        
        -- Execute ability
        if ability.effect == "damage" or ability.effect == "damage_aoe" then
            local damage = ability.value
            
            -- Apply stats
            damage = damage + (attackerPet.stats.power or 0)
            
            -- Check critical
            local critRoll = math.random()
            if critRoll < (attackerPet.stats.critRate or 0) then
                damage = damage * (attackerPet.stats.critDamage or 1.5)
                turnResult.critical = true
            end
            
            -- Apply defense
            damage = damage - (defenderPet.stats.defense or 0)
            damage = math.max(1, damage)
            
            -- Deal damage
            defenderPet.currentHealth = defenderPet.currentHealth - damage
            defender.health = defender.health - damage
            
            turnResult.damage = damage
            
        elseif ability.effect == "heal" or ability.effect == "heal_aoe" then
            local healing = ability.value
            
            if ability.value < 1 then
                -- Percentage heal
                healing = math.floor(attackerPet.maxHealth * ability.value)
            end
            
            attackerPet.currentHealth = math.min(attackerPet.maxHealth, attackerPet.currentHealth + healing)
            attacker.health = attackerPet.currentHealth
            
            turnResult.healing = healing
            
        elseif ability.effect == "buff" then
            -- Apply buff
            table.insert(attackerPet.buffs, {
                id = ability.id,
                effect = ability.effect,
                value = ability.value,
                duration = ability.duration or 3,
                remaining = ability.duration or 3
            })
            
            table.insert(turnResult.effects, {
                type = "buff",
                target = "self",
                effect = ability.effect
            })
        end
        
        -- Set cooldown
        attackerPet.cooldowns[ability.id] = ability.cooldown
        
        -- Deduct energy
        if ability.energyCost then
            attackerPet.currentEnergy = attackerPet.currentEnergy - ability.energyCost
        end
        
    elseif action.type == "switch" then
        -- Switch pet
        if action.petIndex and action.petIndex <= #attacker.pets then
            local newPet = attacker.pets[action.petIndex]
            if newPet.currentHealth > 0 then
                attacker.activePet = action.petIndex
                attacker.health = newPet.currentHealth
                attacker.maxHealth = newPet.maxHealth
                
                table.insert(turnResult.effects, {
                    type = "switch",
                    newPet = newPet.name
                })
            else
                return false, "Cannot switch to fainted pet"
            end
        else
            return false, "Invalid pet index"
        end
        
    elseif action.type == "item" then
        -- Use item (if implemented)
        -- TODO: Implement item usage in battle
    end
    
    -- Check for defeated pets
    if defenderPet.currentHealth <= 0 then
        defenderPet.currentHealth = 0
        defender.health = 0
        
        -- Find next available pet
        local nextPet = nil
        for i, pet in ipairs(defender.pets) do
            if pet.currentHealth > 0 then
                defender.activePet = i
                defender.health = pet.currentHealth
                defender.maxHealth = pet.maxHealth
                nextPet = pet
                break
            end
        end
        
        if not nextPet then
            -- All pets defeated, battle over
            battle.status = "completed"
            battle.endedAt = tick()
            battle.winner = playerNum
            
            -- Calculate rewards
            self:CalculateBattleRewards(battle)
            
            -- Update statistics
            self:UpdateBattleStats(battle)
            
            -- Notify players
            if RemoteEvents.BattleEnded then
                RemoteEvents.BattleEnded:FireClient(battle.player1.player, battle)
                RemoteEvents.BattleEnded:FireClient(battle.player2.player, battle)
            end
            
            -- Clean up
            BattleInstances[battleId] = nil
            
            return true
        end
    end
    
    -- Process buffs/debuffs
    for _, pet in ipairs(attacker.pets) do
        for i = #pet.buffs, 1, -1 do
            local buff = pet.buffs[i]
            buff.remaining = buff.remaining - 1
            if buff.remaining <= 0 then
                table.remove(pet.buffs, i)
            end
        end
        
        for i = #pet.debuffs, 1, -1 do
            local debuff = pet.debuffs[i]
            debuff.remaining = debuff.remaining - 1
            if debuff.remaining <= 0 then
                table.remove(pet.debuffs, i)
            end
        end
    end
    
    -- Reduce cooldowns
    for _, pet in ipairs(attacker.pets) do
        for abilityId, cooldown in pairs(pet.cooldowns) do
            if cooldown > 0 then
                pet.cooldowns[abilityId] = cooldown - 1
            end
        end
    end
    
    -- Record turn
    table.insert(battle.turnHistory, turnResult)
    
    -- Switch turns
    battle.turn = battle.turn + 1
    battle.currentPlayer = battle.currentPlayer == 1 and 2 or 1
    
    -- Update both players
    if RemoteEvents.BattleTurnCompleted then
        RemoteEvents.BattleTurnCompleted:FireClient(battle.player1.player, battle, turnResult)
        RemoteEvents.BattleTurnCompleted:FireClient(battle.player2.player, battle, turnResult)
    end
    
    return true
end

function BattleSystem:CalculateBattleRewards(battle)
    local winner = battle.winner == 1 and battle.player1 or battle.player2
    local loser = battle.winner == 1 and battle.player2 or battle.player1
    
    -- Base rewards
    local baseCoins = 1000
    local baseGems = 10
    local baseXP = 100
    
    -- Apply multipliers
    local coinReward = baseCoins * CONFIG.BATTLE_REWARDS_MULTIPLIER
    local gemReward = baseGems
    local xpReward = baseXP * CONFIG.BATTLE_XP_GAIN
    
    -- Winner rewards
    battle.rewards.winner = {
        coins = coinReward,
        gems = gemReward,
        xp = xpReward
    }
    
    -- Loser rewards (50% of winner)
    battle.rewards.loser = {
        coins = math.floor(coinReward * 0.5),
        gems = math.floor(gemReward * 0.5),
        xp = math.floor(xpReward * 0.5)
    }
    
    -- Apply rewards
    local winnerData = PlayerData[winner.userId]
    local loserData = PlayerData[loser.userId]
    
    if winnerData then
        winnerData.currencies.coins = winnerData.currencies.coins + battle.rewards.winner.coins
        winnerData.currencies.gems = winnerData.currencies.gems + battle.rewards.winner.gems
        
        -- Add XP to pets
        for _, pet in ipairs(winner.pets) do
            for _, ownedPet in ipairs(winnerData.pets) do
                if ownedPet.id == pet.id then
                    ownedPet.experience = ownedPet.experience + battle.rewards.winner.xp
                    -- Check for level up
                    local petData = PetDatabase[ownedPet.petId]
                    if petData and petData.xpRequirements[ownedPet.level] then
                        if ownedPet.experience >= petData.xpRequirements[ownedPet.level] then
                            ownedPet.level = ownedPet.level + 1
                            ownedPet.experience = ownedPet.experience - petData.xpRequirements[ownedPet.level - 1]
                            
                            -- Level up stat boost
                            for stat, value in pairs(ownedPet.stats) do
                                ownedPet.stats[stat] = math.floor(value * 1.1)
                            end
                        end
                    end
                    break
                end
            end
        end
        
        SavePlayerData(winner.player)
    end
    
    if loserData then
        loserData.currencies.coins = loserData.currencies.coins + battle.rewards.loser.coins
        loserData.currencies.gems = loserData.currencies.gems + battle.rewards.loser.gems
        
        -- Add XP to pets (less for losing)
        for _, pet in ipairs(loser.pets) do
            for _, ownedPet in ipairs(loserData.pets) do
                if ownedPet.id == pet.id then
                    ownedPet.experience = ownedPet.experience + battle.rewards.loser.xp
                    break
                end
            end
        end
        
        SavePlayerData(loser.player)
    end
end

function BattleSystem:UpdateBattleStats(battle)
    local winner = battle.winner == 1 and battle.player1 or battle.player2
    local loser = battle.winner == 1 and battle.player2 or battle.player1
    
    local winnerData = PlayerData[winner.userId]
    local loserData = PlayerData[loser.userId]
    
    if winnerData then
        winnerData.statistics.battleStats.wins = winnerData.statistics.battleStats.wins + 1
        winnerData.statistics.battleStats.winStreak = winnerData.statistics.battleStats.winStreak + 1
        
        if winnerData.statistics.battleStats.winStreak > winnerData.statistics.battleStats.highestWinStreak then
            winnerData.statistics.battleStats.highestWinStreak = winnerData.statistics.battleStats.winStreak
        end
    end
    
    if loserData then
        loserData.statistics.battleStats.losses = loserData.statistics.battleStats.losses + 1
        loserData.statistics.battleStats.winStreak = 0
    end
    
    -- Log analytics
    ServerAnalytics:LogEvent("BattleCompleted", nil, {
        battleId = battle.id,
        winner = winner.userId,
        loser = loser.userId,
        duration = battle.endedAt - battle.startedAt,
        turns = battle.turn
    })
end

-- ========================================
-- CLAN SYSTEM
-- ========================================
local ClanSystem = {}

function ClanSystem:CreateClan(player, clanName, clanTag)
    local playerData = PlayerData[player.UserId]
    if not playerData then return false, "Player data not found" end
    
    -- Check if player already in clan
    if playerData.clan.id then
        return false, "You are already in a clan"
    end
    
    -- Check currency
    if playerData.currencies.coins < CONFIG.CLAN_CREATE_COST then
        return false, "Not enough coins. Need " .. CONFIG.CLAN_CREATE_COST
    end
    
    -- Validate clan name
    if #clanName < 3 or #clanName > 20 then
        return false, "Clan name must be 3-20 characters"
    end
    
    if #clanTag < 2 or #clanTag > 5 then
        return false, "Clan tag must be 2-5 characters"
    end
    
    -- Check if clan name exists
    local existingClan = nil
    local success, result = pcall(function()
        return DataStores.ClanData:GetAsync("ClanName_" .. clanName)
    end)
    
    if success and result then
        return false, "Clan name already taken"
    end
    
    -- Create clan
    local clanId = Services.HttpService:GenerateGUID(false)
    
    local clan = {
        id = clanId,
        name = clanName,
        tag = clanTag,
        owner = player.UserId,
        created = os.time(),
        level = 1,
        experience = 0,
        treasury = {
            coins = 0,
            gems = 0
        },
        members = {
            [player.UserId] = {
                userId = player.UserId,
                username = player.Name,
                role = "owner",
                joinDate = os.time(),
                contribution = 0,
                permissions = {
                    invite = true,
                    kick = true,
                    promote = true,
                    withdraw = true,
                    startWar = true,
                    editInfo = true
                }
            }
        },
        memberCount = 1,
        maxMembers = 10,
        description = "A new clan",
        requirements = {
            minLevel = 0,
            approval = false
        },
        stats = {
            wars = 0,
            wins = 0,
            losses = 0,
            totalContribution = 0
        },
        perks = {},
        announcements = {},
        invites = {},
        applications = {}
    }
    
    -- Deduct cost
    playerData.currencies.coins = playerData.currencies.coins - CONFIG.CLAN_CREATE_COST
    
    -- Update player data
    playerData.clan = {
        id = clanId,
        name = clanName,
        role = "owner",
        contribution = 0,
        joinDate = os.time(),
        permissions = clan.members[player.UserId].permissions
    }
    
    -- Save clan data
    local saveSuccess = pcall(function()
        DataStores.ClanData:SetAsync(clanId, clan)
        DataStores.ClanData:SetAsync("ClanName_" .. clanName, clanId)
    end)
    
    if not saveSuccess then
        -- Refund
        playerData.currencies.coins = playerData.currencies.coins + CONFIG.CLAN_CREATE_COST
        return false, "Failed to create clan"
    end
    
    -- Cache clan
    ClanData[clanId] = clan
    
    -- Save player data
    SavePlayerData(player)
    
    -- Notify player
    if RemoteEvents.ClanCreated then
        RemoteEvents.ClanCreated:FireClient(player, clan)
    end
    
    -- Log analytics
    ServerAnalytics:LogEvent("ClanCreated", player, {
        clanId = clanId,
        clanName = clanName,
        clanTag = clanTag
    })
    
    return true, clan
end

function ClanSystem:InvitePlayer(clanId, inviter, targetUsername)
    local clan = ClanData[clanId]
    if not clan then
        -- Load from DataStore
        local success, data = pcall(function()
            return DataStores.ClanData:GetAsync(clanId)
        end)
        if success and data then
            clan = data
            ClanData[clanId] = clan
        else
            return false, "Clan not found"
        end
    end
    
    -- Check permissions
    local member = clan.members[inviter.UserId]
    if not member or not member.permissions.invite then
        return false, "You don't have permission to invite"
    end
    
    -- Check clan capacity
    if clan.memberCount >= clan.maxMembers then
        return false, "Clan is full"
    end
    
    -- Find target player
    local targetPlayer = nil
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.Name == targetUsername then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer then
        return false, "Player not found"
    end
    
    local targetData = PlayerData[targetPlayer.UserId]
    if not targetData then
        return false, "Player data not found"
    end
    
    if targetData.clan.id then
        return false, "Player is already in a clan"
    end
    
    -- Create invite
    local inviteId = Services.HttpService:GenerateGUID(false)
    clan.invites[inviteId] = {
        id = inviteId,
        targetUserId = targetPlayer.UserId,
        invitedBy = inviter.UserId,
        timestamp = os.time(),
        expires = os.time() + 86400 -- 24 hours
    }
    
    -- Save clan data
    pcall(function()
        DataStores.ClanData:SetAsync(clanId, clan)
    end)
    
    -- Notify target player
    if RemoteEvents.ClanInvite then
        RemoteEvents.ClanInvite:FireClient(targetPlayer, {
            inviteId = inviteId,
            clan = clan,
            invitedBy = inviter.Name
        })
    end
    
    return true
end

-- ========================================
-- QUEST SYSTEM
-- ========================================
local QuestSystem = {}

-- Define quest templates
local QuestTemplates = {
    daily = {
        {
            id = "hatch_eggs",
            name = "Egg Collector",
            description = "Hatch {target} eggs",
            type = "hatch_eggs",
            target = 10,
            rewards = {coins = 1000, gems = 10, xp = 100},
            difficulty = "easy"
        },
        {
            id = "win_battles",
            name = "Battle Champion",
            description = "Win {target} battles",
            type = "win_battles",
            target = 5,
            rewards = {coins = 2000, gems = 20, xp = 200},
            difficulty = "medium"
        },
        {
            id = "trade_pets",
            name = "Pet Trader",
            description = "Complete {target} trades",
            type = "complete_trades",
            target = 3,
            rewards = {coins = 1500, gems = 15, xp = 150},
            difficulty = "medium"
        },
        {
            id = "collect_coins",
            name = "Coin Collector",
            description = "Collect {target} coins",
            type = "collect_coins",
            target = 10000,
            rewards = {gems = 25, xp = 250},
            difficulty = "easy"
        },
        {
            id = "evolve_pet",
            name = "Evolution Master",
            description = "Evolve {target} pets",
            type = "evolve_pets",
            target = 1,
            rewards = {coins = 5000, gems = 50, xp = 500},
            difficulty = "hard"
        }
    },
    weekly = {
        {
            id = "legendary_hunt",
            name = "Legendary Hunter",
            description = "Hatch {target} legendary pets",
            type = "hatch_legendary",
            target = 1,
            rewards = {coins = 10000, gems = 100, xp = 1000},
            difficulty = "hard"
        },
        {
            id = "battle_master",
            name = "Battle Master",
            description = "Win {target} battles in a row",
            type = "win_streak",
            target = 10,
            rewards = {coins = 15000, gems = 150, xp = 1500},
            difficulty = "hard"
        },
        {
            id = "clan_contributor",
            name = "Clan Contributor",
            description = "Contribute {target} to clan",
            type = "clan_contribution",
            target = 100000,
            rewards = {coins = 20000, gems = 200, xp = 2000},
            difficulty = "medium"
        }
    }
}

function QuestSystem:GenerateDailyQuests(player)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    -- Check if already generated today
    local today = os.date("*t")
    local todayKey = string.format("%04d-%02d-%02d", today.year, today.month, today.day)
    
    if playerData.quests.lastDaily == todayKey then
        return -- Already generated
    end
    
    -- Clear old daily quests
    playerData.quests.daily = {}
    
    -- Generate new quests
    local availableQuests = {}
    for _, quest in ipairs(QuestTemplates.daily) do
        table.insert(availableQuests, quest)
    end
    
    -- Shuffle and select
    for i = 1, CONFIG.DAILY_QUEST_COUNT do
        if #availableQuests > 0 then
            local index = math.random(1, #availableQuests)
            local questTemplate = availableQuests[index]
            table.remove(availableQuests, index)
            
            local quest = {
                id = questTemplate.id .. "_" .. os.time() .. "_" .. i,
                templateId = questTemplate.id,
                name = questTemplate.name,
                description = questTemplate.description:gsub("{target}", tostring(questTemplate.target)),
                type = questTemplate.type,
                target = questTemplate.target,
                progress = 0,
                completed = false,
                claimed = false,
                rewards = questTemplate.rewards,
                difficulty = questTemplate.difficulty,
                expiresAt = os.time() + CONFIG.QUEST_REFRESH_TIME.Daily
            }
            
            table.insert(playerData.quests.daily, quest)
        end
    end
    
    playerData.quests.lastDaily = todayKey
    
    -- Notify player
    if RemoteEvents.QuestsUpdated then
        RemoteEvents.QuestsUpdated:FireClient(player, playerData.quests)
    end
end

function QuestSystem:UpdateQuestProgress(player, questType, amount)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    amount = amount or 1
    
    -- Check daily quests
    for _, quest in ipairs(playerData.quests.daily) do
        if quest.type == questType and not quest.completed then
            quest.progress = quest.progress + amount
            
            if quest.progress >= quest.target then
                quest.progress = quest.target
                quest.completed = true
                
                -- Notify completion
                if RemoteEvents.QuestCompleted then
                    RemoteEvents.QuestCompleted:FireClient(player, quest)
                end
            end
        end
    end
    
    -- Check weekly quests
    for _, quest in ipairs(playerData.quests.weekly) do
        if quest.type == questType and not quest.completed then
            quest.progress = quest.progress + amount
            
            if quest.progress >= quest.target then
                quest.progress = quest.target
                quest.completed = true
                
                -- Notify completion
                if RemoteEvents.QuestCompleted then
                    RemoteEvents.QuestCompleted:FireClient(player, quest)
                end
            end
        end
    end
    
    -- Update UI
    if RemoteEvents.QuestsUpdated then
        RemoteEvents.QuestsUpdated:FireClient(player, playerData.quests)
    end
end

function QuestSystem:ClaimQuestReward(player, questId)
    local playerData = PlayerData[player.UserId]
    if not playerData then return false, "Player data not found" end
    
    -- Find quest
    local quest = nil
    for _, q in ipairs(playerData.quests.daily) do
        if q.id == questId then
            quest = q
            break
        end
    end
    
    if not quest then
        for _, q in ipairs(playerData.quests.weekly) do
            if q.id == questId then
                quest = q
                break
            end
        end
    end
    
    if not quest then
        return false, "Quest not found"
    end
    
    if not quest.completed then
        return false, "Quest not completed"
    end
    
    if quest.claimed then
        return false, "Reward already claimed"
    end
    
    -- Give rewards
    if quest.rewards.coins then
        playerData.currencies.coins = playerData.currencies.coins + quest.rewards.coins
    end
    if quest.rewards.gems then
        playerData.currencies.gems = playerData.currencies.gems + quest.rewards.gems
    end
    if quest.rewards.xp then
        -- Add XP to equipped pets
        for _, petId in ipairs(playerData.equippedPets) do
            for _, pet in ipairs(playerData.pets) do
                if pet.id == petId then
                    pet.experience = pet.experience + quest.rewards.xp
                    break
                end
            end
        end
    end
    
    quest.claimed = true
    
    -- Save data
    SavePlayerData(player)
    
    -- Notify player
    if RemoteEvents.QuestRewardClaimed then
        RemoteEvents.QuestRewardClaimed:FireClient(player, quest)
    end
    
    return true
end

-- ========================================
-- ACHIEVEMENT SYSTEM
-- ========================================
local AchievementSystem = {}

local AchievementDefinitions = {
    -- Pet Collection
    {
        id = "first_pet",
        name = "First Friend",
        description = "Hatch your first pet",
        category = "collection",
        requirement = {type = "pets_hatched", value = 1},
        rewards = {coins = 100, title = "Pet Owner"},
        tier = "Bronze"
    },
    {
        id = "pet_collector_10",
        name = "Pet Collector",
        description = "Collect 10 different pets",
        category = "collection",
        requirement = {type = "unique_pets", value = 10},
        rewards = {coins = 1000, gems = 10, title = "Collector"},
        tier = "Bronze"
    },
    {
        id = "pet_collector_50",
        name = "Pet Master",
        description = "Collect 50 different pets",
        category = "collection",
        requirement = {type = "unique_pets", value = 50},
        rewards = {coins = 10000, gems = 100, title = "Master Collector"},
        tier = "Silver"
    },
    {
        id = "legendary_owner",
        name = "Legendary Trainer",
        description = "Own a legendary pet",
        category = "collection",
        requirement = {type = "legendary_pet", value = 1},
        rewards = {coins = 50000, gems = 500, title = "Legendary"},
        tier = "Gold"
    },
    
    -- Wealth
    {
        id = "millionaire",
        name = "Millionaire",
        description = "Have 1,000,000 coins",
        category = "wealth",
        requirement = {type = "coins", value = 1000000},
        rewards = {gems = 100, title = "Millionaire"},
        tier = "Silver"
    },
    {
        id = "billionaire",
        name = "Billionaire",
        description = "Have 1,000,000,000 coins",
        category = "wealth",
        requirement = {type = "coins", value = 1000000000},
        rewards = {gems = 1000, title = "Billionaire"},
        tier = "Gold"
    },
    
    -- Battle
    {
        id = "first_victory",
        name = "First Victory",
        description = "Win your first battle",
        category = "battle",
        requirement = {type = "battles_won", value = 1},
        rewards = {coins = 500, title = "Victor"},
        tier = "Bronze"
    },
    {
        id = "battle_veteran",
        name = "Battle Veteran",
        description = "Win 100 battles",
        category = "battle",
        requirement = {type = "battles_won", value = 100},
        rewards = {coins = 10000, gems = 100, title = "Veteran"},
        tier = "Silver"
    },
    {
        id = "undefeated",
        name = "Undefeated",
        description = "Win 10 battles in a row",
        category = "battle",
        requirement = {type = "win_streak", value = 10},
        rewards = {coins = 25000, gems = 250, title = "Undefeated"},
        tier = "Gold"
    },
    
    -- Trading
    {
        id = "first_trade",
        name = "First Trade",
        description = "Complete your first trade",
        category = "trading",
        requirement = {type = "trades_completed", value = 1},
        rewards = {coins = 500, title = "Trader"},
        tier = "Bronze"
    },
    {
        id = "master_trader",
        name = "Master Trader",
        description = "Complete 100 trades",
        category = "trading",
        requirement = {type = "trades_completed", value = 100},
        rewards = {coins = 20000, gems = 200, title = "Master Trader"},
        tier = "Gold"
    },
    
    -- Special
    {
        id = "lucky_hatch",
        name = "Lucky Hatch",
        description = "Hatch a mythical pet",
        category = "special",
        requirement = {type = "mythical_pet", value = 1},
        rewards = {coins = 100000, gems = 1000, title = "Blessed"},
        tier = "Diamond"
    },
    {
        id = "secret_finder",
        name = "Secret Finder",
        description = "Discover a secret pet",
        category = "special",
        requirement = {type = "secret_pet", value = 1},
        rewards = {coins = 999999, gems = 9999, title = "Secret Keeper"},
        tier = "Diamond"
    }
}

function AchievementSystem:CheckAchievements(player)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    for _, achievement in ipairs(AchievementDefinitions) do
        if not playerData.achievements[achievement.id] then
            local completed = false
            
            if achievement.requirement.type == "pets_hatched" then
                completed = playerData.statistics.totalPetsHatched >= achievement.requirement.value
                
            elseif achievement.requirement.type == "unique_pets" then
                local uniqueCount = 0
                for petId, _ in pairs(playerData.petCollection) do
                    uniqueCount = uniqueCount + 1
                end
                completed = uniqueCount >= achievement.requirement.value
                
            elseif achievement.requirement.type == "legendary_pet" then
                for _, pet in ipairs(playerData.pets) do
                    local petData = PetDatabase[pet.petId]
                    if petData and petData.rarity >= 5 then
                        completed = true
                        break
                    end
                end
                
            elseif achievement.requirement.type == "mythical_pet" then
                completed = playerData.statistics.mythicalPetsFound >= achievement.requirement.value
                
            elseif achievement.requirement.type == "secret_pet" then
                completed = playerData.statistics.secretPetsFound >= achievement.requirement.value
                
            elseif achievement.requirement.type == "coins" then
                completed = playerData.currencies.coins >= achievement.requirement.value
                
            elseif achievement.requirement.type == "battles_won" then
                completed = playerData.statistics.battleStats.wins >= achievement.requirement.value
                
            elseif achievement.requirement.type == "win_streak" then
                completed = playerData.statistics.battleStats.highestWinStreak >= achievement.requirement.value
                
            elseif achievement.requirement.type == "trades_completed" then
                completed = playerData.statistics.tradingStats.tradesCompleted >= achievement.requirement.value
            end
            
            if completed then
                self:UnlockAchievement(player, achievement)
            end
        end
    end
end

function AchievementSystem:UnlockAchievement(player, achievement)
    local playerData = PlayerData[player.UserId]
    if not playerData then return end
    
    playerData.achievements[achievement.id] = {
        unlockedAt = os.time(),
        tier = achievement.tier
    }
    
    -- Give rewards
    if achievement.rewards.coins then
        playerData.currencies.coins = playerData.currencies.coins + achievement.rewards.coins
    end
    if achievement.rewards.gems then
        playerData.currencies.gems = playerData.currencies.gems + achievement.rewards.gems
    end
    if achievement.rewards.title then
        table.insert(playerData.titles.owned, achievement.rewards.title)
    end
    
    -- Notify player
    if RemoteEvents.AchievementUnlocked then
        RemoteEvents.AchievementUnlocked:FireClient(player, achievement)
    end
    
    -- Log analytics
    ServerAnalytics:LogEvent("AchievementUnlocked", player, {
        achievementId = achievement.id,
        tier = achievement.tier
    })
end

-- ========================================
-- DAILY REWARDS SYSTEM
-- ========================================
local DailyRewardSystem = {}

local DailyRewards = {
    {day = 1, rewards = {coins = 1000, gems = 10}},
    {day = 2, rewards = {coins = 2000, gems = 20}},
    {day = 3, rewards = {coins = 3000, gems = 30}},
    {day = 4, rewards = {coins = 4000, gems = 40}},
    {day = 5, rewards = {coins = 5000, gems = 50, items = {"lucky_potion"}}},
    {day = 6, rewards = {coins = 6000, gems = 60}},
    {day = 7, rewards = {coins = 10000, gems = 100, egg = "premium"}}
}

function DailyRewardSystem:CheckDailyReward(player)
    local playerData = PlayerData[player.UserId]
    if not playerData then return false end
    
    local now = os.time()
    local lastClaim = playerData.dailyRewards.lastClaim
    
    -- Check if can claim
    local timeSinceLastClaim = now - lastClaim
    if timeSinceLastClaim < 86400 then -- 24 hours
        local timeRemaining = 86400 - timeSinceLastClaim
        return false, timeRemaining
    end
    
    -- Check streak
    if timeSinceLastClaim > 172800 then -- 48 hours - streak broken
        playerData.dailyRewards.streak = 0
    end
    
    return true
end

function DailyRewardSystem:ClaimDailyReward(player)
    local canClaim, timeRemaining = self:CheckDailyReward(player)
    if not canClaim then
        return false, "Please wait " .. math.floor(timeRemaining / 3600) .. " hours"
    end
    
    local playerData = PlayerData[player.UserId]
    
    -- Increment streak
    playerData.dailyRewards.streak = playerData.dailyRewards.streak + 1
    if playerData.dailyRewards.streak > 7 then
        playerData.dailyRewards.streak = 1
    end
    
    -- Get reward
    local rewardData = DailyRewards[playerData.dailyRewards.streak]
    local rewards = {}
    
    -- Apply rewards
    if rewardData.rewards.coins then
        local coins = rewardData.rewards.coins * playerData.dailyRewards.multiplier
        playerData.currencies.coins = playerData.currencies.coins + coins
        rewards.coins = coins
    end
    
    if rewardData.rewards.gems then
        local gems = rewardData.rewards.gems * playerData.dailyRewards.multiplier
        playerData.currencies.gems = playerData.currencies.gems + gems
        rewards.gems = gems
    end
    
    if rewardData.rewards.items then
        rewards.items = rewardData.rewards.items
        -- TODO: Add items to inventory
    end
    
    if rewardData.rewards.egg then
        rewards.egg = rewardData.rewards.egg
        -- Give free egg
    end
    
    -- Update last claim
    playerData.dailyRewards.lastClaim = os.time()
    
    -- Add to history
    table.insert(playerData.dailyRewards.history, {
        day = playerData.dailyRewards.streak,
        claimedAt = os.time(),
        rewards = rewards
    })
    
    -- Keep only last 30 days of history
    if #playerData.dailyRewards.history > 30 then
        table.remove(playerData.dailyRewards.history, 1)
    end
    
    -- Save data
    SavePlayerData(player)
    
    -- Notify player
    if RemoteEvents.DailyRewardClaimed then
        RemoteEvents.DailyRewardClaimed:FireClient(player, {
            streak = playerData.dailyRewards.streak,
            rewards = rewards
        })
    end
    
    return true, rewards
end

-- ========================================
-- INITIALIZATION
-- ========================================
local function SetupRemoteEvents()
    local remoteFolder = Services.ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "RemoteEvents"
        remoteFolder.Parent = Services.ReplicatedStorage
    end
    
    -- Create RemoteEvents
    local eventNames = {
        "DataLoaded",
        "CaseOpened",
        "TradeStarted",
        "TradeUpdated",
        "TradeCompleted",
        "TradeCancelled",
        "BattleStarted",
        "BattleReady",
        "BattleTurnCompleted",
        "BattleEnded",
        "ClanCreated",
        "ClanInvite",
        "QuestsUpdated",
        "QuestCompleted",
        "QuestRewardClaimed",
        "AchievementUnlocked",
        "DailyRewardClaimed",
        "NotificationSent",
        "CurrencyUpdated",
        "PetUpdated",
        "InventoryUpdated"
    }
    
    for _, eventName in ipairs(eventNames) do
        local remoteEvent = remoteFolder:FindFirstChild(eventName)
        if not remoteEvent then
            remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = eventName
            remoteEvent.Parent = remoteFolder
        end
        RemoteEvents[eventName] = remoteEvent
    end
    
    -- Create RemoteFunctions
    local functionNames = {
        "OpenCase",
        "RequestTrade",
        "UpdateTrade",
        "ConfirmTrade",
        "JoinBattle",
        "BattleTurn",
        "CreateClan",
        "JoinClan",
        "ClaimQuest",
        "ClaimDailyReward",
        "GetPlayerData",
        "SaveSettings"
    }
    
    for _, functionName in ipairs(functionNames) do
        local remoteFunction = remoteFolder:FindFirstChild(functionName)
        if not remoteFunction then
            remoteFunction = Instance.new("RemoteFunction")
            remoteFunction.Name = functionName
            remoteFunction.Parent = remoteFolder
        end
        RemoteFunctions[functionName] = remoteFunction
    end
end

local function SetupRemoteHandlers()
    -- Case Opening
    RemoteFunctions.OpenCase.OnServerInvoke = function(player, eggType)
        return OpenCase(player, eggType)
    end
    
    -- Trading
    RemoteFunctions.RequestTrade.OnServerInvoke = function(player, targetPlayer)
        -- Rate limit check
        local canProceed, errorMsg = RateLimiter:Check(player, "Trade")
        if not canProceed then
            return {success = false, error = errorMsg}
        end
        
        -- Check if players can trade
        local playerData = PlayerData[player.UserId]
        local targetData = PlayerData[targetPlayer.UserId]
        
        if not playerData or not targetData then
            return {success = false, error = "Player data not found"}
        end
        
        -- Level check
        if playerData.rebirth.level < CONFIG.MIN_LEVEL_TO_TRADE then
            return {success = false, error = "You need to be level " .. CONFIG.MIN_LEVEL_TO_TRADE .. " to trade"}
        end
        
        if targetData.rebirth.level < CONFIG.MIN_LEVEL_TO_TRADE then
            return {success = false, error = "Target player needs to be level " .. CONFIG.MIN_LEVEL_TO_TRADE}
        end
        
        -- Check if target accepts trades
        if not targetData.settings.tradeRequests then
            return {success = false, error = "Player has trades disabled"}
        end
        
        -- Create trade
        local trade = TradingSystem:CreateTrade(player, targetPlayer)
        return {success = true, trade = trade}
    end
    
    RemoteFunctions.UpdateTrade.OnServerInvoke = function(player, tradeId, action, data)
        if action == "add_item" then
            return TradingSystem:AddItem(tradeId, player, data.itemType, data.itemData)
        elseif action == "remove_item" then
            return TradingSystem:RemoveItem(tradeId, player, data.itemType, data.itemData)
        elseif action == "set_ready" then
            return TradingSystem:SetReady(tradeId, player, data.ready)
        elseif action == "cancel" then
            return TradingSystem:CancelTrade(tradeId, player)
        end
    end
    
    RemoteFunctions.ConfirmTrade.OnServerInvoke = function(player, tradeId)
        return TradingSystem:ConfirmTrade(tradeId, player)
    end
    
    -- Battle
    RemoteFunctions.JoinBattle.OnServerInvoke = function(player, targetPlayer)
        -- Rate limit check
        local canProceed, errorMsg = RateLimiter:Check(player, "Battle")
        if not canProceed then
            return {success = false, error = errorMsg}
        end
        
        local battle = BattleSystem:CreateBattle(player, targetPlayer, "pvp")
        return {success = true, battle = battle}
    end
    
    RemoteFunctions.BattleTurn.OnServerInvoke = function(player, battleId, action)
        return BattleSystem:ExecuteTurn(battleId, player, action)
    end
    
    -- Clan
    RemoteFunctions.CreateClan.OnServerInvoke = function(player, clanName, clanTag)
        return ClanSystem:CreateClan(player, clanName, clanTag)
    end
    
    RemoteFunctions.JoinClan.OnServerInvoke = function(player, inviteId)
        -- TODO: Implement clan joining
    end
    
    -- Quests
    RemoteFunctions.ClaimQuest.OnServerInvoke = function(player, questId)
        return QuestSystem:ClaimQuestReward(player, questId)
    end
    
    -- Daily Rewards
    RemoteFunctions.ClaimDailyReward.OnServerInvoke = function(player)
        return DailyRewardSystem:ClaimDailyReward(player)
    end
    
    -- Data
    RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
        return PlayerData[player.UserId]
    end
    
    RemoteFunctions.SaveSettings.OnServerInvoke = function(player, settings)
        local playerData = PlayerData[player.UserId]
        if playerData then
            playerData.settings = settings
            SavePlayerData(player)
            return true
        end
        return false
    end
end

local function OnPlayerAdded(player)
    -- Load player data
    LoadPlayerData(player)
    
    -- Generate daily quests
    QuestSystem:GenerateDailyQuests(player)
    
    -- Check achievements
    AchievementSystem:CheckAchievements(player)
    
    -- Check daily reward
    DailyRewardSystem:CheckDailyReward(player)
    
    -- Welcome message
    if RemoteEvents.NotificationSent then
        wait(3)
        RemoteEvents.NotificationSent:FireClient(player, {
            type = "welcome",
            title = "Welcome to Sanrio Tycoon Shop!",
            message = "Start your adventure by opening your first egg!",
            duration = 10
        })
    end
end

local function OnPlayerRemoving(player)
    -- Save player data
    SavePlayerData(player)
    
    -- Clean up
    RateLimiter:Reset(player)
    
    -- Cancel active trades
    for tradeId, trade in pairs(ActiveTrades) do
        if trade.player1.userId == player.UserId or trade.player2.userId == player.UserId then
            TradingSystem:CancelTrade(tradeId, player)
        end
    end
    
    -- End active battles
    for battleId, battle in pairs(BattleInstances) do
        if battle.player1.userId == player.UserId or battle.player2.userId == player.UserId then
            battle.status = "abandoned"
            battle.winner = battle.player1.userId == player.UserId and 2 or 1
            BattleSystem:UpdateBattleStats(battle)
            BattleInstances[battleId] = nil
        end
    end
    
    -- Remove from memory
    PlayerData[player.UserId] = nil
end

-- ========================================
-- MARKETPLACESERVICE HANDLING
-- ========================================
Services.MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Services.Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Handle gamepass purchases
    local gamepassData = GamepassData[receiptInfo.ProductId]
    if gamepassData then
        playerData.ownedGamepasses[receiptInfo.ProductId] = true
        
        -- Apply immediate benefits
        for _, benefit in ipairs(gamepassData.benefits) do
            if benefit.type == "storage_increase" then
                playerData.maxPetStorage = playerData.maxPetStorage + benefit.value
            elseif benefit.type == "pet_slots" then
                CONFIG.MAX_INVENTORY_SIZE = CONFIG.MAX_INVENTORY_SIZE + benefit.value
            end
        end
        
        SavePlayerData(player)
        
        -- Notify player
        if RemoteEvents.NotificationSent then
            RemoteEvents.NotificationSent:FireClient(player, {
                type = "purchase",
                title = "Purchase Successful!",
                message = "You now own " .. gamepassData.name,
                duration = 10
            })
        end
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    -- Handle developer products (like gem purchases)
    local productInfo = {
        [123499] = {gems = 100},
        [123500] = {gems = 500},
        [123501] = {gems = 1000},
        [123502] = {gems = 5000},
        [123503] = {gems = 10000}
    }
    
    local product = productInfo[receiptInfo.ProductId]
    if product then
        if product.gems then
            playerData.currencies.gems = playerData.currencies.gems + product.gems
            playerData.statistics.totalGemsEarned = playerData.statistics.totalGemsEarned + product.gems
        end
        
        SavePlayerData(player)
        
        -- Notify player
        if RemoteEvents.CurrencyUpdated then
            RemoteEvents.CurrencyUpdated:FireClient(player, playerData.currencies)
        end
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ========================================
-- AUTO-SAVE SYSTEM
-- ========================================
spawn(function()
    while true do
        wait(CONFIG.DATA_AUTOSAVE_INTERVAL)
        
        for userId, data in pairs(PlayerData) do
            local player = Services.Players:GetPlayerByUserId(userId)
            if player then
                SavePlayerData(player)
            end
        end
        
        -- Save clan data
        for clanId, clan in pairs(ClanData) do
            pcall(function()
                DataStores.ClanData:SetAsync(clanId, clan)
            end)
        end
        
        -- Flush analytics
        ServerAnalytics:FlushEvents()
    end
end)

-- ========================================
-- MAIN INITIALIZATION
-- ========================================
local function InitializeSanrioTycoonShop()
    print("Initializing Sanrio Tycoon Shop Server v" .. CONFIG.VERSION)
    
    -- Setup remote events
    SetupRemoteEvents()
    SetupRemoteHandlers()
    
    -- Connect player events
    Services.Players.PlayerAdded:Connect(OnPlayerAdded)
    Services.Players.PlayerRemoving:Connect(OnPlayerRemoving)
    
    -- Load existing players (in case script was added mid-game)
    for _, player in ipairs(Services.Players:GetPlayers()) do
        OnPlayerAdded(player)
    end
    
    -- Initialize leaderboard
    spawn(function()
        while true do
            wait(60) -- Update every minute
            
            -- Update coin leaderboard
            local coinLeaderboard = {}
            for userId, data in pairs(PlayerData) do
                table.insert(coinLeaderboard, {
                    userId = userId,
                    value = data.currencies.coins,
                    username = data.username
                })
            end
            
            table.sort(coinLeaderboard, function(a, b)
                return a.value > b.value
            end)
            
            -- Save top 100
            local topCoins = {}
            for i = 1, math.min(100, #coinLeaderboard) do
                topCoins[i] = coinLeaderboard[i]
            end
            
            pcall(function()
                DataStores.LeaderboardData:SetAsync("TopCoins", topCoins)
            end)
        end
    end)
    
    print("Sanrio Tycoon Shop Server initialized successfully!")
end

-- Start the server
InitializeSanrioTycoonShop()

-- Return module for potential expansion
return SanrioTycoonServer