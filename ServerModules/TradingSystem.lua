--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                       SANRIO TYCOON - TRADING SYSTEM MODULE                          ║
    ║                          Secure peer-to-peer trading system                          ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local TradingSystem = {}

-- Services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local Configuration = require(script.Parent.Configuration)
local DataStoreModule = require(script.Parent.DataStoreModule)
local PetSystem = require(script.Parent.PetSystem)

-- Active trades storage
TradingSystem.ActiveTrades = {}
TradingSystem.TradeCooldowns = {}
TradingSystem.TradeHistory = {}

-- ========================================
-- TRADE CREATION
-- ========================================
function TradingSystem:CreateTrade(player1, player2)
    -- Check if players can trade
    local canTrade, reason = self:CanPlayersTradeSystem(player1, player2)
    if not canTrade then
        return nil, reason
    end
    
    local tradeId = HttpService:GenerateGUID(false)
    
    local trade = {
        id = tradeId,
        player1 = {
            userId = player1.UserId,
            player = player1,
            items = {
                pets = {},
                currencies = {
                    coins = 0,
                    gems = 0
                }
            },
            confirmed = false,
            locked = false
        },
        player2 = {
            userId = player2.UserId,
            player = player2,
            items = {
                pets = {},
                currencies = {
                    coins = 0,
                    gems = 0
                }
            },
            confirmed = false,
            locked = false
        },
        status = "pending",
        createdAt = os.time(),
        expiresAt = os.time() + 300 -- 5 minute timeout
    }
    
    self.ActiveTrades[tradeId] = trade
    
    -- Track active trades for each player
    if not self.ActiveTrades[player1.UserId] then
        self.ActiveTrades[player1.UserId] = {}
    end
    if not self.ActiveTrades[player2.UserId] then
        self.ActiveTrades[player2.UserId] = {}
    end
    
    self.ActiveTrades[player1.UserId][tradeId] = true
    self.ActiveTrades[player2.UserId][tradeId] = true
    
    return trade
end

-- ========================================
-- TRADE VALIDATION
-- ========================================
function TradingSystem:CanPlayersTrade(player1, player2)
    -- Check if both players exist
    if not player1 or not player2 then
        return false, "Invalid players"
    end
    
    -- Check if trading with self
    if player1.UserId == player2.UserId then
        return false, "Cannot trade with yourself"
    end
    
    -- Check player data
    local player1Data = DataStoreModule.PlayerData[player1.UserId]
    local player2Data = DataStoreModule.PlayerData[player2.UserId]
    
    if not player1Data or not player2Data then
        return false, "Player data not loaded"
    end
    
    -- Check if trading is enabled
    if not player1Data.settings.trading then
        return false, player1.Name .. " has trading disabled"
    end
    
    if not player2Data.settings.trading then
        return false, player2.Name .. " has trading disabled"
    end
    
    -- Check cooldowns
    local cooldown1 = self.TradeCooldowns[player1.UserId]
    local cooldown2 = self.TradeCooldowns[player2.UserId]
    local currentTime = os.time()
    
    if cooldown1 and currentTime < cooldown1 then
        return false, player1.Name .. " is on trade cooldown"
    end
    
    if cooldown2 and currentTime < cooldown2 then
        return false, player2.Name .. " is on trade cooldown"
    end
    
    -- Check if already in trade
    if self.ActiveTrades[player1.UserId] then
        for tradeId, _ in pairs(self.ActiveTrades[player1.UserId]) do
            local trade = self.ActiveTrades[tradeId]
            if trade and trade.status == "active" then
                return false, player1.Name .. " is already in a trade"
            end
        end
    end
    
    if self.ActiveTrades[player2.UserId] then
        for tradeId, _ in pairs(self.ActiveTrades[player2.UserId]) do
            local trade = self.ActiveTrades[tradeId]
            if trade and trade.status == "active" then
                return false, player2.Name .. " is already in a trade"
            end
        end
    end
    
    return true
end

-- ========================================
-- ADD ITEMS TO TRADE
-- ========================================
function TradingSystem:AddPetToTrade(tradeId, player, petUniqueId)
    local trade = self.ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "active" then
        return false, "Trade not active"
    end
    
    -- Determine which side the player is on
    local tradeData = nil
    if trade.player1.userId == player.UserId then
        tradeData = trade.player1
    elseif trade.player2.userId == player.UserId then
        tradeData = trade.player2
    else
        return false, "Player not in this trade"
    end
    
    -- Check if trade is locked
    if tradeData.locked then
        return false, "Your trade is locked"
    end
    
    -- Check if pet exists and is owned
    local playerData = DataStoreModule.PlayerData[player.UserId]
    local pet = playerData.pets[petUniqueId]
    
    if not pet then
        return false, "Pet not found"
    end
    
    if pet.locked then
        return false, "Pet is locked"
    end
    
    -- Check if pet already in trade
    if tradeData.items.pets[petUniqueId] then
        return false, "Pet already in trade"
    end
    
    -- Check trade limit
    local petCount = 0
    for _ in pairs(tradeData.items.pets) do
        petCount = petCount + 1
    end
    
    if petCount >= Configuration.CONFIG.MAX_TRADE_ITEMS then
        return false, "Trade item limit reached"
    end
    
    -- Add pet to trade
    tradeData.items.pets[petUniqueId] = {
        petData = pet,
        value = PetSystem:GetPetValue(pet)
    }
    
    -- Reset confirmations
    trade.player1.confirmed = false
    trade.player2.confirmed = false
    
    -- Update trade
    self:BroadcastTradeUpdate(trade)
    
    return true
end

function TradingSystem:RemovePetFromTrade(tradeId, player, petUniqueId)
    local trade = self.ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "active" then
        return false, "Trade not active"
    end
    
    -- Determine which side the player is on
    local tradeData = nil
    if trade.player1.userId == player.UserId then
        tradeData = trade.player1
    elseif trade.player2.userId == player.UserId then
        tradeData = trade.player2
    else
        return false, "Player not in this trade"
    end
    
    -- Check if trade is locked
    if tradeData.locked then
        return false, "Your trade is locked"
    end
    
    -- Remove pet from trade
    if not tradeData.items.pets[petUniqueId] then
        return false, "Pet not in trade"
    end
    
    tradeData.items.pets[petUniqueId] = nil
    
    -- Reset confirmations
    trade.player1.confirmed = false
    trade.player2.confirmed = false
    
    -- Update trade
    self:BroadcastTradeUpdate(trade)
    
    return true
end

function TradingSystem:SetTradeCurrency(tradeId, player, currencyType, amount)
    local trade = self.ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "active" then
        return false, "Trade not active"
    end
    
    -- Validate currency type
    if currencyType ~= "coins" and currencyType ~= "gems" then
        return false, "Invalid currency type"
    end
    
    -- Validate amount
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 then
        return false, "Invalid amount"
    end
    
    -- Determine which side the player is on
    local tradeData = nil
    if trade.player1.userId == player.UserId then
        tradeData = trade.player1
    elseif trade.player2.userId == player.UserId then
        tradeData = trade.player2
    else
        return false, "Player not in this trade"
    end
    
    -- Check if trade is locked
    if tradeData.locked then
        return false, "Your trade is locked"
    end
    
    -- Check if player has enough currency
    local playerData = DataStoreModule.PlayerData[player.UserId]
    if playerData.currencies[currencyType] < amount then
        return false, "Not enough " .. currencyType
    end
    
    -- Set currency amount
    tradeData.items.currencies[currencyType] = amount
    
    -- Reset confirmations
    trade.player1.confirmed = false
    trade.player2.confirmed = false
    
    -- Update trade
    self:BroadcastTradeUpdate(trade)
    
    return true
end

-- ========================================
-- TRADE CONFIRMATION
-- ========================================
function TradingSystem:ConfirmTrade(tradeId, player)
    local trade = self.ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    if trade.status ~= "active" then
        return false, "Trade not active"
    end
    
    -- Determine which side the player is on
    if trade.player1.userId == player.UserId then
        trade.player1.confirmed = true
    elseif trade.player2.userId == player.UserId then
        trade.player2.confirmed = true
    else
        return false, "Player not in this trade"
    end
    
    -- Check if both confirmed
    if trade.player1.confirmed and trade.player2.confirmed then
        -- Execute trade
        return self:ExecuteTrade(trade)
    end
    
    -- Update trade
    self:BroadcastTradeUpdate(trade)
    
    return true
end

-- ========================================
-- EXECUTE TRADE
-- ========================================
function TradingSystem:ExecuteTrade(trade)
    -- Final validation
    local player1Data = DataStoreModule.PlayerData[trade.player1.userId]
    local player2Data = DataStoreModule.PlayerData[trade.player2.userId]
    
    if not player1Data or not player2Data then
        trade.status = "failed"
        return false, "Player data not found"
    end
    
    -- Validate all items still exist and are tradeable
    -- Player 1 items
    for petId, _ in pairs(trade.player1.items.pets) do
        if not player1Data.pets[petId] then
            trade.status = "failed"
            return false, "Pet no longer available"
        end
    end
    
    -- Player 2 items
    for petId, _ in pairs(trade.player2.items.pets) do
        if not player2Data.pets[petId] then
            trade.status = "failed"
            return false, "Pet no longer available"
        end
    end
    
    -- Validate currencies
    if player1Data.currencies.coins < trade.player1.items.currencies.coins or
       player1Data.currencies.gems < trade.player1.items.currencies.gems then
        trade.status = "failed"
        return false, "Player 1 insufficient funds"
    end
    
    if player2Data.currencies.coins < trade.player2.items.currencies.coins or
       player2Data.currencies.gems < trade.player2.items.currencies.gems then
        trade.status = "failed"
        return false, "Player 2 insufficient funds"
    end
    
    -- Calculate trade values and tax
    local tradeValue = self:CalculateTradeValue(trade)
    local taxAmount = math.floor(tradeValue * Configuration.CONFIG.TRADE_TAX_PERCENTAGE)
    
    -- Execute the trade
    -- Transfer pets from player 1 to player 2
    for petId, petInfo in pairs(trade.player1.items.pets) do
        player1Data.pets[petId] = nil
        player1Data.petCount = player1Data.petCount - 1
        
        player2Data.pets[petId] = petInfo.petData
        player2Data.petCount = player2Data.petCount + 1
    end
    
    -- Transfer pets from player 2 to player 1
    for petId, petInfo in pairs(trade.player2.items.pets) do
        player2Data.pets[petId] = nil
        player2Data.petCount = player2Data.petCount - 1
        
        player1Data.pets[petId] = petInfo.petData
        player1Data.petCount = player1Data.petCount + 1
    end
    
    -- Transfer currencies (with tax)
    local p1CoinsAfterTax = math.floor(trade.player1.items.currencies.coins * (1 - Configuration.CONFIG.TRADE_TAX_PERCENTAGE))
    local p1GemsAfterTax = math.floor(trade.player1.items.currencies.gems * (1 - Configuration.CONFIG.TRADE_TAX_PERCENTAGE))
    local p2CoinsAfterTax = math.floor(trade.player2.items.currencies.coins * (1 - Configuration.CONFIG.TRADE_TAX_PERCENTAGE))
    local p2GemsAfterTax = math.floor(trade.player2.items.currencies.gems * (1 - Configuration.CONFIG.TRADE_TAX_PERCENTAGE))
    
    player1Data.currencies.coins = player1Data.currencies.coins - trade.player1.items.currencies.coins + p2CoinsAfterTax
    player1Data.currencies.gems = player1Data.currencies.gems - trade.player1.items.currencies.gems + p2GemsAfterTax
    
    player2Data.currencies.coins = player2Data.currencies.coins - trade.player2.items.currencies.coins + p1CoinsAfterTax
    player2Data.currencies.gems = player2Data.currencies.gems - trade.player2.items.currencies.gems + p1GemsAfterTax
    
    -- Update statistics
    player1Data.statistics.tradingStats.tradesCompleted = 
        (player1Data.statistics.tradingStats.tradesCompleted or 0) + 1
    player2Data.statistics.tradingStats.tradesCompleted = 
        (player2Data.statistics.tradingStats.tradesCompleted or 0) + 1
    
    player1Data.statistics.tradingStats.totalTradeValue = 
        (player1Data.statistics.tradingStats.totalTradeValue or 0) + tradeValue
    player2Data.statistics.tradingStats.totalTradeValue = 
        (player2Data.statistics.tradingStats.totalTradeValue or 0) + tradeValue
    
    -- Mark data as dirty
    DataStoreModule:MarkPlayerDirty(trade.player1.userId)
    DataStoreModule:MarkPlayerDirty(trade.player2.userId)
    
    -- Set cooldowns
    self.TradeCooldowns[trade.player1.userId] = os.time() + Configuration.CONFIG.TRADE_COOLDOWN
    self.TradeCooldowns[trade.player2.userId] = os.time() + Configuration.CONFIG.TRADE_COOLDOWN
    
    -- Update trade status
    trade.status = "completed"
    trade.completedAt = os.time()
    
    -- Store in history
    self:AddToHistory(trade)
    
    -- Clean up active trade
    self:CleanupTrade(trade)
    
    -- Broadcast completion
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("TradeCompleted") then
        RemoteEvents.TradeCompleted:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeCompleted:FireClient(trade.player2.player, trade)
    end
    
    return true
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================
function TradingSystem:CalculateTradeValue(trade)
    local totalValue = 0
    
    -- Calculate pet values
    for _, petInfo in pairs(trade.player1.items.pets) do
        totalValue = totalValue + (petInfo.value or 0)
    end
    
    for _, petInfo in pairs(trade.player2.items.pets) do
        totalValue = totalValue + (petInfo.value or 0)
    end
    
    -- Add currency values
    totalValue = totalValue + trade.player1.items.currencies.coins
    totalValue = totalValue + trade.player1.items.currencies.gems * 100
    totalValue = totalValue + trade.player2.items.currencies.coins
    totalValue = totalValue + trade.player2.items.currencies.gems * 100
    
    return totalValue
end

function TradingSystem:BroadcastTradeUpdate(trade)
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("TradeUpdated") then
        RemoteEvents.TradeUpdated:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeUpdated:FireClient(trade.player2.player, trade)
    end
end

function TradingSystem:CancelTrade(tradeId, player)
    local trade = self.ActiveTrades[tradeId]
    if not trade then return false, "Trade not found" end
    
    -- Check if player is in trade
    if trade.player1.userId ~= player.UserId and trade.player2.userId ~= player.UserId then
        return false, "Player not in this trade"
    end
    
    trade.status = "cancelled"
    trade.cancelledBy = player.UserId
    trade.cancelledAt = os.time()
    
    -- Clean up
    self:CleanupTrade(trade)
    
    -- Notify players
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents and RemoteEvents:FindFirstChild("TradeCancelled") then
        RemoteEvents.TradeCancelled:FireClient(trade.player1.player, trade)
        RemoteEvents.TradeCancelled:FireClient(trade.player2.player, trade)
    end
    
    return true
end

function TradingSystem:CleanupTrade(trade)
    -- Remove from active trades
    self.ActiveTrades[trade.id] = nil
    
    if self.ActiveTrades[trade.player1.userId] then
        self.ActiveTrades[trade.player1.userId][trade.id] = nil
    end
    
    if self.ActiveTrades[trade.player2.userId] then
        self.ActiveTrades[trade.player2.userId][trade.id] = nil
    end
end

function TradingSystem:AddToHistory(trade)
    -- Store simplified trade data
    local historyEntry = {
        id = trade.id,
        player1 = trade.player1.userId,
        player2 = trade.player2.userId,
        status = trade.status,
        value = self:CalculateTradeValue(trade),
        timestamp = trade.completedAt or trade.cancelledAt or os.time()
    }
    
    -- Add to both players' history
    if not self.TradeHistory[trade.player1.userId] then
        self.TradeHistory[trade.player1.userId] = {}
    end
    if not self.TradeHistory[trade.player2.userId] then
        self.TradeHistory[trade.player2.userId] = {}
    end
    
    table.insert(self.TradeHistory[trade.player1.userId], 1, historyEntry)
    table.insert(self.TradeHistory[trade.player2.userId], 1, historyEntry)
    
    -- Limit history size
    if #self.TradeHistory[trade.player1.userId] > 50 then
        table.remove(self.TradeHistory[trade.player1.userId])
    end
    if #self.TradeHistory[trade.player2.userId] > 50 then
        table.remove(self.TradeHistory[trade.player2.userId])
    end
end

function TradingSystem:OnPlayerLeaving(player)
    -- Cancel any active trades
    local activeTradeId = nil
    for tradeId, trade in pairs(self.ActiveTrades) do
        if trade.player1.userId == player.UserId or trade.player2.userId == player.UserId then
            activeTradeId = tradeId
            break
        end
    end
    
    if activeTradeId then
        self:CancelTrade(activeTradeId, player)
    end
    
    -- Clean up trade history (optional - could keep for persistent data)
    self.TradeHistory[player.UserId] = nil
end

return TradingSystem