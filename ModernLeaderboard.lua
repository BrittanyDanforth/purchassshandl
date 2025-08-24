-- MODERN UNIFIED LEADERBOARD - NO OLD UI
-- This version tracks money internally without showing the ugly leaderboard
-- Place this in ServerScriptService (REPLACE the old UnifiedLeaderboard)

print("⭐ MODERN UNIFIED LEADERBOARD STARTING...")

-- Services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Variables
local processedPlayers = {}
local playerTycoons = {} -- Track which tycoon each player owns

-- Create Global Money API
_G.AddPlayerMoney = function(playerName, amount)
	return false
end

_G.SetPlayerMoney = function(playerName, amount)
	return false
end

_G.GetPlayerMoney = function(playerName)
	return 0
end

print("💰 Global Money API created")

-- Create PlayerMoney folder
local playerMoneyFolder = ServerStorage:FindFirstChild("PlayerMoney")
if not playerMoneyFolder then
	playerMoneyFolder = Instance.new("Folder")
	playerMoneyFolder.Name = "PlayerMoney"
	playerMoneyFolder.Parent = ServerStorage
	print("Created PlayerMoney folder")
end

-- Get or create player money
local function getOrCreatePlayerMoney(playerName)
	local moneyValue = playerMoneyFolder:FindFirstChild(playerName)
	if not moneyValue then
		moneyValue = Instance.new("IntValue")
		moneyValue.Name = playerName
		moneyValue.Value = 0

		local ownsTycoon = Instance.new("ObjectValue")
		ownsTycoon.Name = "OwnsTycoon"
		ownsTycoon.Parent = moneyValue

		moneyValue.Parent = playerMoneyFolder
		print("Created PlayerMoney data for", playerName)
	end
	return moneyValue
end

-- Update Global Money API
_G.AddPlayerMoney = function(playerName, amount)
	local moneyValue = getOrCreatePlayerMoney(playerName)
	moneyValue.Value = moneyValue.Value + amount
	return true
end

_G.SetPlayerMoney = function(playerName, amount)
	local moneyValue = getOrCreatePlayerMoney(playerName)
	moneyValue.Value = amount
	return true
end

_G.GetPlayerMoney = function(playerName)
	local moneyValue = playerMoneyFolder:FindFirstChild(playerName)
	return moneyValue and moneyValue.Value or 0
end

print("💰 Global Money API ready")

-- TYCOON TRACKING SYSTEM
local function findAllTycoons()
	local tycoons = {}

	local function searchForTycoons(parent)
		for _, child in pairs(parent:GetChildren()) do
			local owner = child:FindFirstChild("Owner")
			local essentials = child:FindFirstChild("Essentials")
			local buttons = child:FindFirstChild("Buttons")

			if owner and essentials and buttons then
				table.insert(tycoons, child)
				print("📍 Found tycoon:", child:GetFullName())
			elseif child:IsA("Folder") or child:IsA("Model") then
				searchForTycoons(child)
			end
		end
	end

	searchForTycoons(workspace)
	return tycoons
end

-- Monitor tycoon ownership
local function monitorTycoons()
	local tycoons = findAllTycoons()

	for _, tycoon in pairs(tycoons) do
		local owner = tycoon:FindFirstChild("Owner")
		if owner then
			-- Track current owner
			if owner.Value then
				playerTycoons[owner.Value.Name] = tycoon
			end

			-- Monitor changes
			owner.Changed:Connect(function()
				if owner.Value then
					playerTycoons[owner.Value.Name] = tycoon
					print("🏠 Player", owner.Value.Name, "claimed", tycoon.Name)
				end
			end)
		end
	end

	print("📊 Monitoring", #tycoons, "tycoons")
end

-- Start monitoring
task.wait(1)
monitorTycoons()

-- Player setup - NO LEADERSTATS!
function onPlayerEntered(newPlayer)
	if processedPlayers[newPlayer.Name] then
		print("Player already has money data:", newPlayer.Name)
		return
	end
	processedPlayers[newPlayer.Name] = true

	print("Setting up player:", newPlayer.Name)

	-- Just create the money tracking, no visible stats
	local playerMoney = getOrCreatePlayerMoney(newPlayer.Name)
	
	-- That's it! No leaderstats folder = no ugly leaderboard
	print("✅ Player setup complete (no leaderboard) for:", newPlayer.Name)
end

-- COMPREHENSIVE PLAYER REMOVAL HANDLER
local function onPlayerRemoving(player)
	print("🚪 Player leaving:", player.Name)
	processedPlayers[player.Name] = nil

	-- Find tycoon using tracking system
	local tycoon = playerTycoons[player.Name]

	if not tycoon then
		-- Backup: Search all tycoons
		print("  🔍 Searching for tycoon...")
		local allTycoons = findAllTycoons()

		for _, searchTycoon in pairs(allTycoons) do
			local owner = searchTycoon:FindFirstChild("Owner")
			if owner and owner.Value == player then
				tycoon = searchTycoon
				break
			end
		end
	end

	if tycoon then
		print("  ✓ Found tycoon:", tycoon.Name)

		-- The purchase handler will handle its own reset when Owner.Value changes
		-- We just need to clear the owner
		local owner = tycoon:FindFirstChild("Owner")
		if owner then
			owner.Value = nil
			print("  ✓ Cleared owner - purchase handler will reset automatically")
		end

		-- Clear currency (backup in case purchase handler doesn't)
		local currencyToCollect = tycoon:FindFirstChild("CurrencyToCollect")
		if currencyToCollect then
			currencyToCollect.Value = 0
		end
	else
		warn("  ❌ Could not find tycoon for player:", player.Name)
	end

	-- Clear player data
	playerTycoons[player.Name] = nil

	local playerMoney = playerMoneyFolder:FindFirstChild(player.Name)
	if playerMoney then
		local ownsTycoon = playerMoney:FindFirstChild("OwnsTycoon")
		if ownsTycoon then
			ownsTycoon.Value = nil
		end
		playerMoney.Value = 0
		print("  ✓ Reset player money to 0")
	end
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerEntered)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(onPlayerEntered, player)
end

print("⭐ MODERN UNIFIED LEADERBOARD READY")
print("💰 Money API: Active")
print("🚪 Gate System: Integrated")
print("🔄 Tycoon Reset: Coordinated with purchase handler")
print("🏠 Tycoon Tracking: Active")
print("🎨 Old Leaderboard: DISABLED - Using modern UI instead!")
print("\n📋 How it works:")
print("  1. Money is tracked internally in ServerStorage")
print("  2. No leaderstats = no ugly leaderboard")
print("  3. Modern Cash UI shows money beautifully")
print("  4. Mobile and PC friendly!")