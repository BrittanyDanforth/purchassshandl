-- Enhanced Purchase Handler with Gamepass Support
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Create remote events
local remotes = Instance.new("Folder")
remotes.Name = "ShopRemotes"
remotes.Parent = ReplicatedStorage

local purchaseSuccess = Instance.new("RemoteEvent")
purchaseSuccess.Name = "PurchaseSuccess"
purchaseSuccess.Parent = remotes

local updateMultiplier = Instance.new("RemoteEvent")
updateMultiplier.Name = "UpdateMultiplier"
updateMultiplier.Parent = remotes

-- DataStores
local purchaseHistory = DataStoreService:GetDataStore("PurchaseHistory")
local playerData = DataStoreService:GetDataStore("PlayerData")

-- Product IDs (must match client)
local PRODUCTS = {
	[3366419712] = {amount = 1000, name = "1K Cash"},
	[3366420012] = {amount = 5000, name = "5K Cash"},
	[3366420478] = {amount = 10000, name = "10K Cash"},
	[3366420800] = {amount = 25000, name = "25K Cash"},
}

-- Gamepass IDs (replace with your actual IDs)
local GAMEPASSES = {
	VIP = 123456789,
	DOUBLE_CASH = 123456790,
	AUTO_COLLECT = 123456791,
	BIGGER_POCKETS = 123456792,
}

-- Active player data
local playerDataCache = {}
local autoCollectConnections = {}

-- Load player data
local function loadPlayerData(player)
	local success, data = pcall(function()
		return playerData:GetAsync("Player_" .. player.UserId)
	end)
	
	if success and data then
		playerDataCache[player] = data
	else
		playerDataCache[player] = {
			cashMultiplier = 1,
			autoCollectEnabled = false,
			biggerPocketsEnabled = false,
			vipEnabled = false
		}
	end
	
	-- Check gamepass ownership
	for passName, passId in pairs(GAMEPASSES) do
		local owned = false
		local checkSuccess, hasPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		
		if checkSuccess and hasPass then
			owned = true
		end
		
		if passName == "DOUBLE_CASH" and owned then
			playerDataCache[player].cashMultiplier = 2
			updateMultiplier:FireClient(player, 2)
		elseif passName == "AUTO_COLLECT" and owned then
			playerDataCache[player].autoCollectEnabled = true
			setupAutoCollect(player)
		elseif passName == "BIGGER_POCKETS" and owned then
			playerDataCache[player].biggerPocketsEnabled = true
			-- Apply inventory increase logic here
		elseif passName == "VIP" and owned then
			playerDataCache[player].vipEnabled = true
			-- Apply VIP benefits here
		end
	end
end

-- Save player data
local function savePlayerData(player)
	if playerDataCache[player] then
		pcall(function()
			playerData:SetAsync("Player_" .. player.UserId, playerDataCache[player])
		end)
	end
end

-- Auto-collect setup
function setupAutoCollect(player)
	if not playerDataCache[player] or not playerDataCache[player].autoCollectEnabled then
		return
	end
	
	-- Clean up existing connection
	if autoCollectConnections[player] then
		autoCollectConnections[player]:Disconnect()
		autoCollectConnections[player] = nil
	end
	
	-- Create auto-collect loop
	autoCollectConnections[player] = RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then return end
		
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end
		
		-- Find nearby collectibles (adjust based on your tycoon system)
		local tycoon = workspace:FindFirstChild(player.Name .. "_Tycoon")
		if not tycoon then return end
		
		local collectibles = tycoon:FindFirstChild("Collectibles")
		if not collectibles then return end
		
		for _, collectible in pairs(collectibles:GetChildren()) do
			if collectible:FindFirstChild("Cash") and collectible:FindFirstChild("Position") then
				local distance = (humanoidRootPart.Position - collectible.Position.Value).Magnitude
				if distance < 20 then -- Auto-collect range
					-- Award cash with multiplier
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats and leaderstats:FindFirstChild("Cash") then
						local baseAmount = collectible.Cash.Value
						local multiplier = playerDataCache[player].cashMultiplier or 1
						leaderstats.Cash.Value = leaderstats.Cash.Value + (baseAmount * multiplier)
						
						-- Create collection effect
						local effect = Instance.new("Part")
						effect.Name = "CollectEffect"
						effect.Size = Vector3.new(1, 1, 1)
						effect.Position = collectible.Position.Value
						effect.Anchored = true
						effect.CanCollide = false
						effect.BrickColor = BrickColor.new("Lime green")
						effect.Material = Enum.Material.Neon
						effect.Parent = workspace
						
						-- Tween to player
						local tween = game:GetService("TweenService"):Create(
							effect,
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
							{
								Position = humanoidRootPart.Position,
								Size = Vector3.new(0.1, 0.1, 0.1),
								Transparency = 1
							}
						)
						
						tween.Completed:Connect(function()
							effect:Destroy()
						end)
						
						tween:Play()
						
						-- Remove collectible
						collectible:Destroy()
					end
				end
			end
		end
	end)
end

-- Process receipt for developer products
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Check if already processed
	local purchaseKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local success, alreadyProcessed = pcall(function()
		return purchaseHistory:GetAsync(purchaseKey)
	end)
	
	if success and alreadyProcessed then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Process the purchase
	local productInfo = PRODUCTS[receiptInfo.ProductId]
	if not productInfo then
		warn("Unknown product ID:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Award currency
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = leaderstats.Cash.Value + productInfo.amount
		
		-- Mark as processed
		pcall(function()
			purchaseHistory:SetAsync(purchaseKey, true)
		end)
		
		-- Notify client
		purchaseSuccess:FireClient(player, "product", productInfo.name, productInfo.amount)
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Handle gamepass purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then return end
	
	-- Handle different gamepasses
	if gamePassId == GAMEPASSES.DOUBLE_CASH then
		playerDataCache[player].cashMultiplier = 2
		updateMultiplier:FireClient(player, 2)
		purchaseSuccess:FireClient(player, "gamepass", "2x Cash", "Activated!")
		
	elseif gamePassId == GAMEPASSES.AUTO_COLLECT then
		playerDataCache[player].autoCollectEnabled = true
		setupAutoCollect(player)
		purchaseSuccess:FireClient(player, "gamepass", "Auto Collect", "Activated!")
		
	elseif gamePassId == GAMEPASSES.BIGGER_POCKETS then
		playerDataCache[player].biggerPocketsEnabled = true
		-- Apply inventory increase
		purchaseSuccess:FireClient(player, "gamepass", "Bigger Pockets", "Activated!")
		
	elseif gamePassId == GAMEPASSES.VIP then
		playerDataCache[player].vipEnabled = true
		-- Apply VIP benefits
		purchaseSuccess:FireClient(player, "gamepass", "VIP", "Activated!")
	end
	
	-- Save data
	savePlayerData(player)
end)

-- Player setup
Players.PlayerAdded:Connect(function(player)
	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats
	
	-- Load player data
	loadPlayerData(player)
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	-- Save data
	savePlayerData(player)
	
	-- Clean up auto-collect
	if autoCollectConnections[player] then
		autoCollectConnections[player]:Disconnect()
		autoCollectConnections[player] = nil
	end
	
	-- Clear cache
	playerDataCache[player] = nil
end)

-- Server shutdown handling
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	wait(2)
end)

print("✨ Enhanced Purchase Handler loaded with gamepass support!")