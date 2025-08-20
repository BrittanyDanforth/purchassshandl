--[[
	🔒 ENHANCED PURCHASE HANDLER - Kawaii Shop Integration
	
	Features:
	- Secure ProcessReceipt implementation
	- Auto-collect gamepass integration
	- 2x Cash multiplier support
	- Real-time purchase notifications
	- Anti-exploit protection
	- Analytics tracking
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
	-- DataStore
	PURCHASE_HISTORY_STORE = "PurchaseHistoryV3",
	PLAYER_DATA_STORE = "PlayerDataV3",
	
	-- Security
	MIN_PURCHASE_INTERVAL = 0.5,
	SUSPICIOUS_THRESHOLD = 10,
	
	-- Auto-collect
	AUTO_COLLECT_RANGE = 50,
	AUTO_COLLECT_INTERVAL = 0.5,
	
	-- Debug
	DEBUG_MODE = true,
}

-- Product IDs (match client)
local PRODUCTS = {
	-- Currency packs
	[3366419712] = {
		name = "1000 Cash",
		type = "currency",
		amount = 1000,
	},
	[3366420012] = {
		name = "5000 Cash",
		type = "currency",
		amount = 5000,
	},
	[3366420478] = {
		name = "10000 Cash",
		type = "currency",
		amount = 10000,
	},
	[3366420800] = {
		name = "25000 Cash",
		type = "currency",
		amount = 25000,
	},
}

-- Gamepass IDs (replace with your actual IDs)
local GAMEPASSES = {
	VIP = 123456789,
	DOUBLE_CASH = 123456790,
	AUTO_COLLECT = 123456791,
	BIGGER_POCKETS = 123456792,
}

-- DataStores
local purchaseHistory = DataStoreService:GetDataStore(CONFIG.PURCHASE_HISTORY_STORE)
local playerDataStore = DataStoreService:GetDataStore(CONFIG.PLAYER_DATA_STORE)

-- Recent purchases tracking
local recentPurchases = {}

-- Player data cache
local playerData = {}

-- Auto-collect tracking
local autoCollectPlayers = {}

-- Create remotes
local remotes = Instance.new("Folder")
remotes.Name = "ShopRemotes"
remotes.Parent = ReplicatedStorage

local purchaseNotification = Instance.new("RemoteEvent")
purchaseNotification.Name = "PurchaseNotification"
purchaseNotification.Parent = remotes

local autoCollectStatus = Instance.new("RemoteEvent")
autoCollectStatus.Name = "AutoCollectStatus"
autoCollectStatus.Parent = remotes

-- ========================================
-- PLAYER DATA MANAGEMENT
-- ========================================

local function loadPlayerData(player)
	local data = {
		cash = 0,
		multipliers = {
			cash = 1,
		},
		gamepasses = {},
		settings = {
			autoCollect = false,
		}
	}
	
	-- Load from DataStore
	local success, result = pcall(function()
		return playerDataStore:GetAsync("Player_" .. player.UserId)
	end)
	
	if success and result then
		for key, value in pairs(result) do
			data[key] = value
		end
	end
	
	-- Check gamepass ownership
	for passName, passId in pairs(GAMEPASSES) do
		local owned = false
		pcall(function()
			owned = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		data.gamepasses[passName] = owned
		
		-- Apply gamepass effects
		if owned then
			if passName == "DOUBLE_CASH" then
				data.multipliers.cash = 2
			elseif passName == "AUTO_COLLECT" then
				data.settings.autoCollect = true
			end
		end
	end
	
	playerData[player.UserId] = data
	
	-- Set up leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.cash
	cash.Parent = leaderstats
	
	-- Set up multipliers folder
	local multipliers = Instance.new("Folder")
	multipliers.Name = "Multipliers"
	multipliers.Parent = player
	
	local cashMultiplier = Instance.new("NumberValue")
	cashMultiplier.Name = "CashMultiplier"
	cashMultiplier.Value = data.multipliers.cash
	cashMultiplier.Parent = multipliers
	
	-- Set up gamepasses folder
	local gamepassFolder = Instance.new("Folder")
	gamepassFolder.Name = "Gamepasses"
	gamepassFolder.Parent = player
	
	for passName, owned in pairs(data.gamepasses) do
		local pass = Instance.new("BoolValue")
		pass.Name = passName
		pass.Value = owned
		pass.Parent = gamepassFolder
	end
	
	return data
end

local function savePlayerData(player)
	local data = playerData[player.UserId]
	if not data then return end
	
	-- Update cash from leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			data.cash = cash.Value
		end
	end
	
	-- Save to DataStore
	pcall(function()
		playerDataStore:SetAsync("Player_" .. player.UserId, data)
	end)
end

-- ========================================
-- AUTO-COLLECT SYSTEM
-- ========================================

local function startAutoCollect(player)
	if autoCollectPlayers[player.UserId] then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Find player's tycoon
	local tycoon = nil
	local tycoons = workspace:FindFirstChild("Tycoons")
	if tycoons then
		for _, t in pairs(tycoons:GetChildren()) do
			local owner = t:FindFirstChild("Owner")
			if owner and owner.Value == player then
				tycoon = t
				break
			end
		end
	end
	
	if not tycoon then return end
	
	-- Start auto-collect loop
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not player.Parent or not character.Parent then
			connection:Disconnect()
			autoCollectPlayers[player.UserId] = nil
			return
		end
		
		-- Find cash parts near player
		local cashFolder = tycoon:FindFirstChild("CashParts") or tycoon:FindFirstChild("Cash")
		if cashFolder then
			for _, cashPart in pairs(cashFolder:GetChildren()) do
				if cashPart:IsA("BasePart") and cashPart:FindFirstChild("CashValue") then
					local distance = (cashPart.Position - humanoidRootPart.Position).Magnitude
					if distance <= CONFIG.AUTO_COLLECT_RANGE then
						-- Collect the cash
						local cashValue = cashPart:FindFirstChild("CashValue")
						if cashValue then
							local amount = cashValue.Value
							local multiplier = playerData[player.UserId].multipliers.cash or 1
							local finalAmount = amount * multiplier
							
							local leaderstats = player:FindFirstChild("leaderstats")
							if leaderstats then
								local cash = leaderstats:FindFirstChild("Cash")
								if cash then
									cash.Value = cash.Value + finalAmount
								end
							end
							
							-- Destroy cash part
							cashPart:Destroy()
						end
					end
				end
			end
		end
	end)
	
	autoCollectPlayers[player.UserId] = connection
	
	-- Notify client
	autoCollectStatus:FireClient(player, true)
end

local function stopAutoCollect(player)
	local connection = autoCollectPlayers[player.UserId]
	if connection then
		connection:Disconnect()
		autoCollectPlayers[player.UserId] = nil
		autoCollectStatus:FireClient(player, false)
	end
end

-- ========================================
-- PURCHASE HANDLERS
-- ========================================

local function grantCurrency(player, product)
	local data = playerData[player.UserId]
	if not data then return false end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end
	
	local cash = leaderstats:FindFirstChild("Cash")
	if not cash then return false end
	
	-- Apply multipliers
	local multiplier = data.multipliers.cash or 1
	local finalAmount = product.amount * multiplier
	
	-- Grant cash
	cash.Value = cash.Value + finalAmount
	
	-- Notify client
	purchaseNotification:FireClient(player, {
		type = "currency",
		amount = finalAmount,
		originalAmount = product.amount,
		multiplier = multiplier,
		productName = product.name,
	})
	
	return true
end

local function grantGamepass(player, gamepassId)
	local data = playerData[player.UserId]
	if not data then return end
	
	-- Update data
	for passName, passId in pairs(GAMEPASSES) do
		if passId == gamepassId then
			data.gamepasses[passName] = true
			
			-- Update in-game
			local gamepassFolder = player:FindFirstChild("Gamepasses")
			if gamepassFolder then
				local pass = gamepassFolder:FindFirstChild(passName)
				if pass then
					pass.Value = true
				end
			end
			
			-- Apply effects
			if passName == "DOUBLE_CASH" then
				data.multipliers.cash = 2
				local multipliers = player:FindFirstChild("Multipliers")
				if multipliers then
					local cashMultiplier = multipliers:FindFirstChild("CashMultiplier")
					if cashMultiplier then
						cashMultiplier.Value = 2
					end
				end
			elseif passName == "AUTO_COLLECT" then
				data.settings.autoCollect = true
				startAutoCollect(player)
			elseif passName == "VIP" then
				-- Grant VIP perks
				local tags = player:FindFirstChild("Tags") or Instance.new("Folder")
				tags.Name = "Tags"
				tags.Parent = player
				
				local vipTag = Instance.new("BoolValue")
				vipTag.Name = "VIP"
				vipTag.Value = true
				vipTag.Parent = tags
			end
			
			-- Notify client
			purchaseNotification:FireClient(player, {
				type = "gamepass",
				gamepassName = passName,
			})
			
			break
		end
	end
end

-- ========================================
-- PROCESS RECEIPT
-- ========================================

local function processReceipt(receiptInfo)
	-- Security checks
	if not receiptInfo.PlayerId or not receiptInfo.ProductId or not receiptInfo.PurchaseId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Find player
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Anti-exploit check
	local userId = receiptInfo.PlayerId
	local now = tick()
	local userPurchases = recentPurchases[userId] or {count = 0, lastTime = 0}
	
	if now - userPurchases.lastTime < CONFIG.MIN_PURCHASE_INTERVAL then
		warn("Purchase too frequent for", player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	if now - userPurchases.lastTime < 60 then
		userPurchases.count = userPurchases.count + 1
		if userPurchases.count > CONFIG.SUSPICIOUS_THRESHOLD then
			warn("Suspicious purchase activity for", player.Name)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	else
		userPurchases.count = 1
	end
	
	userPurchases.lastTime = now
	recentPurchases[userId] = userPurchases
	
	-- Check if already processed
	local purchaseKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	
	local success, alreadyProcessed = pcall(function()
		return purchaseHistory:GetAsync(purchaseKey)
	end)
	
	if alreadyProcessed then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Process the purchase
	local product = PRODUCTS[receiptInfo.ProductId]
	if product then
		-- Currency product
		local granted = grantCurrency(player, product)
		if not granted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		-- Record purchase
		pcall(function()
			purchaseHistory:SetAsync(purchaseKey, {
				timestamp = os.time(),
				productId = receiptInfo.ProductId,
				productName = product.name,
				amount = product.amount,
			})
		end)
		
		if CONFIG.DEBUG_MODE then
			print("Purchase granted:", player.Name, "bought", product.name)
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Unknown product
	warn("Unknown product ID:", receiptInfo.ProductId)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set ProcessReceipt callback
MarketplaceService.ProcessReceipt = processReceipt

-- ========================================
-- GAMEPASS HANDLING
-- ========================================

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased then return end
	
	-- Check if it's one of our gamepasses
	for _, id in pairs(GAMEPASSES) do
		if id == gamepassId then
			grantGamepass(player, gamepassId)
			break
		end
	end
end)

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================

Players.PlayerAdded:Connect(function(player)
	-- Load player data
	loadPlayerData(player)
	
	-- Check auto-collect on spawn
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Wait for character to load
		
		local data = playerData[player.UserId]
		if data and data.settings.autoCollect then
			startAutoCollect(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Stop auto-collect
	stopAutoCollect(player)
	
	-- Save player data
	savePlayerData(player)
	
	-- Clean up
	playerData[player.UserId] = nil
	recentPurchases[player.UserId] = nil
end)

-- ========================================
-- AUTO-SAVE
-- ========================================

spawn(function()
	while true do
		wait(60) -- Save every minute
		
		for _, player in pairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
	end
end)

print("✨ Enhanced Purchase Handler initialized!")
print("Products registered:", #PRODUCTS)
print("Gamepasses configured:", 4)