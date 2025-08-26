-- MoneyUpdateBridge.lua
-- This script bridges the tycoon's money system with the Sanrio shop's currency update system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Wait for remotes to be created
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
    warn("[MoneyUpdateBridge] RemoteEvents folder not found!")
    return
end

local CurrencyUpdated = RemoteEvents:WaitForChild("CurrencyUpdated", 10)
if not CurrencyUpdated then
    warn("[MoneyUpdateBridge] CurrencyUpdated remote not found!")
    return
end

-- Track player money values
local playerMoneyValues = {}
local lastUpdateTime = {}

-- Function to find player's money value
local function findPlayerMoneyValue(player)
    -- Check common locations for money values
    local locations = {
        player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money"),
        player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash"),
        player:FindFirstChild("Stats") and player.Stats:FindFirstChild("Money"),
        player:FindFirstChild("Stats") and player.Stats:FindFirstChild("Cash"),
        player:FindFirstChild("Data") and player.Data:FindFirstChild("Money"),
        player:FindFirstChild("Data") and player.Data:FindFirstChild("Cash"),
    }
    
    -- Also check PlayerMoney folder
    local playerMoneyFolder = workspace:FindFirstChild("PlayerMoney")
    if playerMoneyFolder then
        local playerFolder = playerMoneyFolder:FindFirstChild(player.Name)
        if playerFolder then
            table.insert(locations, playerFolder:FindFirstChild("Money"))
            table.insert(locations, playerFolder:FindFirstChild("Cash"))
        end
    end
    
    -- Return first valid money value found
    for _, moneyValue in ipairs(locations) do
        if moneyValue and moneyValue:IsA("NumberValue") or moneyValue:IsA("IntValue") then
            return moneyValue
        end
    end
    
    return nil
end

-- Function to update player currencies
local function updatePlayerCurrencies(player, newCoins)
    -- Get player data from DataStore module if available
    local playerData = nil
    if _G.SanrioTycoonModules and _G.SanrioTycoonModules.DataStoreModule then
        playerData = _G.SanrioTycoonModules.DataStoreModule:GetPlayerData(player)
    end
    
    -- Create currency table
    local currencies = {
        coins = newCoins,
        gems = playerData and playerData.currencies and playerData.currencies.gems or 0,
        tickets = playerData and playerData.currencies and playerData.currencies.tickets or 0
    }
    
    -- Fire the update
    CurrencyUpdated:FireClient(player, currencies)
end

-- Monitor player money changes
local function monitorPlayerMoney(player)
    local moneyValue = findPlayerMoneyValue(player)
    if not moneyValue then
        warn("[MoneyUpdateBridge] Could not find money value for player:", player.Name)
        return
    end
    
    print("[MoneyUpdateBridge] Monitoring money for player:", player.Name)
    
    -- Store initial value
    playerMoneyValues[player] = moneyValue.Value
    lastUpdateTime[player] = tick()
    
    -- Connect to value changes
    local connection = moneyValue.Changed:Connect(function(newValue)
        local currentTime = tick()
        
        -- Throttle updates to prevent spam (max 10 updates per second)
        if currentTime - lastUpdateTime[player] < 0.1 then
            return
        end
        
        -- Only update if value actually changed
        if playerMoneyValues[player] ~= newValue then
            playerMoneyValues[player] = newValue
            lastUpdateTime[player] = currentTime
            
            -- Update currencies
            updatePlayerCurrencies(player, newValue)
        end
    end)
    
    -- Clean up on player leaving
    player.AncestryChanged:Connect(function()
        if not player.Parent then
            connection:Disconnect()
            playerMoneyValues[player] = nil
            lastUpdateTime[player] = nil
        end
    end)
end

-- Connect existing players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        monitorPlayerMoney(player)
    end)
end

-- Connect new players
Players.PlayerAdded:Connect(function(player)
    -- Wait for character and money to be set up
    wait(2)
    monitorPlayerMoney(player)
end)

-- Also update periodically in case we missed any changes
RunService.Heartbeat:Connect(function()
    for player, lastValue in pairs(playerMoneyValues) do
        if player.Parent then
            local moneyValue = findPlayerMoneyValue(player)
            if moneyValue and moneyValue.Value ~= lastValue then
                playerMoneyValues[player] = moneyValue.Value
                updatePlayerCurrencies(player, moneyValue.Value)
            end
        end
    end
end)

print("[MoneyUpdateBridge] Initialized - Monitoring real-time money changes")