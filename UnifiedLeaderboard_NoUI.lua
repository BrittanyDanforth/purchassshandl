-- COMPLETE UNIFIED LEADERBOARD FINAL FIXED (NO OLD UI VERSION)
-- This is the MASTER script that coordinates everything
-- Place this ONE script in ServerScriptService

print("⭐ UNIFIED LEADERBOARD FINAL FIXED STARTING...")

-- Services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Variables
local processedPlayers = {}
local Settings = nil
local CTF_mode = false
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

-- Clean up old scripts
local function cleanupOldScripts()
	local removedCount = 0

	for _, child in pairs(workspace:GetChildren()) do
		if child:IsA("Model") then
			local innerModel = child:FindFirstChild(child.Name:gsub("Tycoon", " tycoon")) or 
				child:FindFirstChild("Zednov's Tycoon Kit [OPEN!]") or
				child:FindFirstChild("Spiderman tycoon")

			if innerModel then
				local linkedScript = innerModel:FindFirstChild("LinkedLeaderboard")
				if linkedScript and linkedScript:IsA("Script") then
					linkedScript:Destroy()
					removedCount = removedCount + 1
				end
			end
		end
	end

	for _, child in pairs(game.ServerScriptService:GetChildren()) do
		if child:IsA("Script") and child.Name == "LinkedLeaderboard" and child ~= script then
			child:Destroy()
			removedCount = removedCount + 1
		end
	end

	if removedCount > 0 then
		print("Removed", removedCount, "old LinkedLeaderboard scripts")
	end
end

task.wait(0.1)
cleanupOldScripts()

-- Load Settings
local function loadSettings()
	local locations = {
		game.ServerScriptService:FindFirstChild("Settings"),
		workspace:FindFirstChild("SpidermanTycoon"),
		workspace:FindFirstChild("Venom Tycoon"),
		workspace:FindFirstChild("Zednov's Tycoon Kit"),
		workspace:FindFirstChild("Cinnamoroll tycoon"),
	}

	for _, location in ipairs(locations) do
		if location then
			local settingsModule = location:FindFirstChild("Settings", true)
			if settingsModule and settingsModule:IsA("ModuleScript") then
				local success, module = pcall(require, settingsModule)
				if success then
					Settings = module
					print("Loaded Settings from:", location.Name)
					return true
				end
			end
		end
	end

	-- Default settings
	warn("No Settings module found! Using defaults.")
	Settings = {
		LeaderboardSettings = {
			KOs = true,
			WOs = true,
			ShowCurrency = true,
			ShowShortCurrency = true,
			KillsName = "KOs",
			DeathsName = "Wipeouts"
		},
		CurrencyName = "Cash",
		ConvertShort = function(self, value)
			value = tonumber(value) or 0
			if value >= 1000000000 then
				return string.format("%.1fB", value / 1000000000)
			elseif value >= 1000000 then
				return string.format("%.1fM", value / 1000000)
			elseif value >= 1000 then
				return string.format("%.1fK", value / 1000)
			else
				return tostring(value)
			end
		end,
		ConvertComma = function(self, value)
			local formatted = tostring(value)
			while true do
				local newFormatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
				if k == 0 then break end
				formatted = newFormatted
			end
			return formatted
		end
	}
	return false
end

loadSettings()

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

-- Death handling (removed since we don't have leaderstats)
function onHumanoidDied(humanoid, player)
	-- No longer tracking deaths/kills in leaderboard
end

function getKillerOfHumanoidIfStillInGame(humanoid)
	local tag = humanoid:FindFirstChild("creator")
	if tag then
		local killer = tag.Value
		if killer and killer.Parent then
			return killer
		end
	end
	return nil
end

function handleKillCount(humanoid, player)
	-- No longer tracking kills in leaderboard
end

-- CTF support (removed)
local stands = {}
local function findAllFlagStands(root)
	-- No longer needed
end

local function onCaptureScored(player)
	-- No longer needed
end

-- Player setup - NO LEADERSTATS VERSION
function onPlayerEntered(newPlayer)
	if processedPlayers[newPlayer.Name] then
		print("Player already has stats:", newPlayer.Name)
		return
	end
	processedPlayers[newPlayer.Name] = true

	print("Creating money tracking for player:", newPlayer.Name)

	local playerMoney = getOrCreatePlayerMoney(newPlayer.Name)

	-- NO LEADERSTATS FOLDER = NO UGLY LEADERBOARD!
	-- Money is tracked internally and shown via the modern Cash UI
	
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

print("⭐ UNIFIED LEADERBOARD (NO UI VERSION) READY")
print("💰 Money API: Active")
print("🚪 Gate System: Integrated")
print("🔄 Tycoon Reset: Coordinated with purchase handler")
print("🏠 Tycoon Tracking: Active")
print("🎨 Old Leaderboard: DISABLED - Using modern Cash UI!")
print("\n📋 How it works:")
print("  1. When player leaves, we clear the Owner value")
print("  2. Purchase handler detects owner change and resets everything")
print("  3. Gate script detects owner=nil and resets gate")
print("  4. NO LEADERSTATS = NO UGLY LEADERBOARD!")
print("  5. Money shown via beautiful Cash UI only!")