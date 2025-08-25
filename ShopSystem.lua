-- Shop System with Red Coil, Green Coil, Red Balloon, and Grappling Hook
-- Using the exact asset IDs provided

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Create RemoteEvents
local remotes = Instance.new("Folder")
remotes.Name = "ShopRemotes"
remotes.Parent = ReplicatedStorage

local purchaseRemote = Instance.new("RemoteEvent")
purchaseRemote.Name = "PurchaseItem"
purchaseRemote.Parent = remotes

local equipRemote = Instance.new("RemoteEvent")
equipRemote.Name = "EquipItem"
equipRemote.Parent = remotes

local getDataRemote = Instance.new("RemoteFunction")
getDataRemote.Name = "GetPlayerData"
getDataRemote.Parent = remotes

-- DataStore
local shopDataStore = DataStoreService:GetDataStore("ShopDataV1")

-- Shop Items Configuration
local SHOP_ITEMS = {
    {
        Name = "Red Coil",
        ItemId = "RedCoil",
        Price = 100,
        ImageId = "rbxassetid://9676503482",
        Description = "A powerful red speed coil!",
        Type = "Gear",
        Stats = {Speed = 32}
    },
    {
        Name = "Green Coil",
        ItemId = "GreenCoil", 
        Price = 150,
        ImageId = "rbxassetid://9676542145",
        Description = "An enhanced green speed coil!",
        Type = "Gear",
        Stats = {Speed = 40}
    },
    {
        Name = "Red Balloon",
        ItemId = "RedBalloon",
        Price = 200,
        ImageId = "rbxassetid://9672579022",
        Description = "Float with this magical balloon!",
        Type = "Gear",
        Stats = {JumpPower = 100}
    },
    {
        Name = "Grappling Hook",
        ItemId = "GrapplingHook",
        Price = 500,
        ImageId = "rbxassetid://9677437680",
        Description = "Swing around with this grappling hook!",
        Type = "Tool",
        Stats = {Range = 50}
    }
}

-- Player Data Management
local playerData = {}

local function loadPlayerData(player)
    local success, data = pcall(function()
        return shopDataStore:GetAsync("Player_" .. player.UserId)
    end)
    
    if success and data then
        playerData[player.UserId] = data
    else
        -- Initialize new player data
        playerData[player.UserId] = {
            Coins = 1000, -- Starting coins
            OwnedItems = {},
            EquippedItem = nil
        }
    end
    
    return playerData[player.UserId]
end

local function savePlayerData(player)
    if playerData[player.UserId] then
        pcall(function()
            shopDataStore:SetAsync("Player_" .. player.UserId, playerData[player.UserId])
        end)
    end
end

-- Purchase Handler
local function handlePurchase(player, itemId)
    local data = playerData[player.UserId]
    if not data then return false, "Data not loaded" end
    
    -- Find item
    local item = nil
    for _, shopItem in ipairs(SHOP_ITEMS) do
        if shopItem.ItemId == itemId then
            item = shopItem
            break
        end
    end
    
    if not item then return false, "Invalid item" end
    
    -- Check if already owned
    if data.OwnedItems[itemId] then
        return false, "Already owned"
    end
    
    -- Check if player has enough coins
    if data.Coins < item.Price then
        return false, "Not enough coins"
    end
    
    -- Purchase item
    data.Coins = data.Coins - item.Price
    data.OwnedItems[itemId] = true
    
    -- Save data
    savePlayerData(player)
    
    return true, "Purchase successful"
end

-- Load ItemSpawner module
local ItemSpawner = require(script.Parent:WaitForChild("ItemSpawner"))

-- Equip Handler
local function handleEquip(player, itemId)
    local data = playerData[player.UserId]
    if not data then return false, "Data not loaded" end
    
    -- Check if owned
    if not data.OwnedItems[itemId] then
        return false, "Item not owned"
    end
    
    -- Equip item
    data.EquippedItem = itemId
    
    -- Apply item effects
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        
        -- Reset stats
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        
        -- Apply item stats
        for _, shopItem in ipairs(SHOP_ITEMS) do
            if shopItem.ItemId == itemId then
                if shopItem.Stats.Speed then
                    humanoid.WalkSpeed = shopItem.Stats.Speed
                end
                if shopItem.Stats.JumpPower then
                    humanoid.JumpPower = shopItem.Stats.JumpPower
                end
                break
            end
        end
        
        -- Give tool
        ItemSpawner.GiveTool(player, itemId)
    end
    
    savePlayerData(player)
    return true, "Equipped successfully"
end

-- Remote Events
purchaseRemote.OnServerEvent:Connect(function(player, itemId)
    local success, message = handlePurchase(player, itemId)
    purchaseRemote:FireClient(player, success, message, playerData[player.UserId])
end)

equipRemote.OnServerEvent:Connect(function(player, itemId)
    local success, message = handleEquip(player, itemId)
    equipRemote:FireClient(player, success, message)
end)

getDataRemote.OnServerInvoke = function(player)
    return playerData[player.UserId]
end

-- Player Management
Players.PlayerAdded:Connect(function(player)
    loadPlayerData(player)
    
    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = playerData[player.UserId].Coins
    coins.Parent = leaderstats
    
    -- Update coins display
    spawn(function()
        while player.Parent do
            wait(0.5)
            if playerData[player.UserId] then
                coins.Value = playerData[player.UserId].Coins
            end
        end
    end)
    
    player.CharacterAdded:Connect(function(character)
        wait(1)
        -- Re-apply equipped item
        local data = playerData[player.UserId]
        if data and data.EquippedItem then
            handleEquip(player, data.EquippedItem)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerData[player.UserId] = nil
end)

-- Auto-save
spawn(function()
    while true do
        wait(60) -- Save every minute
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

print("Shop System Loaded Successfully!")