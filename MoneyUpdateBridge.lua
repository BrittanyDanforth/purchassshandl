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
    
    -- Also check PlayerMoney folder (created by UnifiedLeaderboard)
    local playerMoneyFolder = workspace:FindFirstChild("PlayerMoney")
    if playerMoneyFolder then
        local playerFolder = playerMoneyFolder:FindFirstChild(player.Name)
        if playerFolder then
            table.insert(locations, playerFolder:FindFirstChild("Money"))
            table.insert(locations, playerFolder:FindFirstChild("Cash"))
            table.insert(locations, playerFolder:FindFirstChild("Value"))
            
            -- UnifiedLeaderboard creates a "Value" NumberValue
            local valueObj = playerFolder:FindFirstChild("Value")
            if valueObj and valueObj:IsA("NumberValue") then
                table.insert(locations, valueObj)
            end
        end
    end
    
    -- Check tycoon-specific locations
    local tycoons = {
        workspace:FindFirstChild("New Hellokitty  tycoon") and workspace["New Hellokitty  tycoon"]:FindFirstChild("Tycoons"),
        workspace:FindFirstChild("Zednov's Tycoon Kit") and workspace["Zednov's Tycoon Kit"]:FindFirstChild("Tycoons"),
        workspace:FindFirstChild("Cinnamoroll tycoon") and workspace["Cinnamoroll tycoon"]:FindFirstChild("Tycoons"),
        workspace:FindFirstChild("Kuromi tycoon") and workspace["Kuromi tycoon"]:FindFirstChild("Tycoons")
    }
    
    for _, tycoonFolder in ipairs(tycoons) do
        if tycoonFolder then
            for _, tycoon in pairs(tycoonFolder:GetChildren()) do
                local owner = tycoon:FindFirstChild("Owner")
                if owner and owner.Value == player then
                    -- Found player's tycoon, look for money in various locations
                    local cash = tycoon:FindFirstChild("Cash") or tycoon:FindFirstChild("Money")
                    if cash then
                        table.insert(locations, cash)
                    end
                    
                    -- Check CurrencyToCollect
                    local currencyFolder = tycoon:FindFirstChild("CurrencyToCollect")
                    if currencyFolder then
                        local curr = currencyFolder:FindFirstChild("Cash") or currencyFolder:FindFirstChild("Money")
                        if curr then
                            table.insert(locations, curr)
                        end
                    end
                    
                    -- Check inside PurchasedObjects for money values
                    local purchasedObjects = tycoon:FindFirstChild("PurchasedObjects")
                    if purchasedObjects then
                        local moneyObj = purchasedObjects:FindFirstChild("Money") or purchasedObjects:FindFirstChild("Cash")
                        if moneyObj then
                            table.insert(locations, moneyObj)
                        end
                        
                        -- Also check for a Collector part with money value
                        local collector = purchasedObjects:FindFirstChild("Collector")
                        if collector then
                            local collectorMoney = collector:FindFirstChild("Cash") or collector:FindFirstChild("Money")
                            if collectorMoney then
                                table.insert(locations, collectorMoney)
                            end
                        end
                    end
                    
                    -- Check Essentials folder
                    local essentials = tycoon:FindFirstChild("Essentials")
                    if essentials then
                        local essentialCash = essentials:FindFirstChild("Cash") or essentials:FindFirstChild("Money")
                        if essentialCash then
                            table.insert(locations, essentialCash)
                        end
                    end
                    
                    -- Check for PlayerMoney inside tycoon
                    local tycoonPlayerMoney = tycoon:FindFirstChild("PlayerMoney")
                    if tycoonPlayerMoney then
                        local playerValue = tycoonPlayerMoney:FindFirstChild("Value") or tycoonPlayerMoney:FindFirstChild("Money") or tycoonPlayerMoney:FindFirstChild("Cash")
                        if playerValue then
                            table.insert(locations, playerValue)
                        end
                    end
                    
                    -- Check Values folder
                    local values = tycoon:FindFirstChild("Values")
                    if values then
                        local money = values:FindFirstChild("Money") or values:FindFirstChild("Cash") or values:FindFirstChild("PlayerMoney")
                        if money then
                            table.insert(locations, money)
                        end
                    end
                end
            end
        end
    end
    
    -- Return first valid money value found
    for _, moneyValue in ipairs(locations) do
        if moneyValue and (moneyValue:IsA("NumberValue") or moneyValue:IsA("IntValue")) then
            print("[MoneyUpdateBridge] Found money value for", player.Name, "at", moneyValue:GetFullName())
            return moneyValue
        end
    end
    
    -- Debug: print search locations
    if #locations > 0 then
        print("[MoneyUpdateBridge] Searched", #locations, "locations for", player.Name, "but found no valid NumberValue/IntValue")
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

-- Track player money OBJECTS, not just values
local playerMoneyObjects = {}
local playerConnections = {}

-- ==========================================================
-- REPLACE THE OLD monitorPlayerMoney FUNCTION WITH THIS NEW ONE
-- ==========================================================
local function monitorPlayerMoney(player)
    -- Wait a bit for PlayerMoney folder to be created by UnifiedLeaderboard
    task.wait(1)
    
    -- Try to find the money value object
    local moneyValue = findPlayerMoneyValue(player)

    if not moneyValue then
        -- If not found, wait for tycoon setup and try again
        for i = 1, 5 do
            task.wait(2)
            moneyValue = findPlayerMoneyValue(player)
            if moneyValue then break end
        end
    end

    if not moneyValue then
        warn("[MoneyUpdateBridge] Could not find money value for player after several retries:", player.Name)
        return
    end

    print("[MoneyUpdateBridge] Successfully found and now monitoring money for:", player.Name)
    playerMoneyObjects[player] = moneyValue

    -- Send the initial value right away
    updatePlayerCurrencies(player, moneyValue.Value)

    -- Connect to the .Changed event. This is VERY efficient.
    local connection = moneyValue.Changed:Connect(function(newValue)
        updatePlayerCurrencies(player, newValue)
    end)

    -- Store the connection so we can disconnect it later
    playerConnections[player] = connection
end

local function stopMonitoringPlayer(player)
    if playerConnections[player] then
        playerConnections[player]:Disconnect()
        playerConnections[player] = nil
    end
    if playerMoneyObjects[player] then
        playerMoneyObjects[player] = nil
    end
    playerMoneyValues[player] = nil
    lastUpdateTime[player] = nil
end

-- Connect existing players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        monitorPlayerMoney(player)
    end)
end

-- Connect new players
Players.PlayerAdded:Connect(monitorPlayerMoney)

-- Handle existing players in the game
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(monitorPlayerMoney, player)
end

-- Clean up when a player leaves
Players.PlayerRemoving:Connect(stopMonitoringPlayer)

-- ==========================================================
-- DELETE THE OLD RunService.Heartbeat CONNECTION ENTIRELY
-- ==========================================================
-- RunService.Heartbeat:Connect(function() ... end) -- DELETE THIS WHOLE BLOCK

print("[MoneyUpdateBridge] Initialized - Monitoring real-time money changes efficiently.")