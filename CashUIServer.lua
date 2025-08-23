--[[
	Cash UI Server Script
	Handles communication between UnifiedLeaderboard and Client UI
	Place in ServerScriptService
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Create RemoteEvents folder
local remotes = ReplicatedStorage:FindFirstChild("CashUIRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "CashUIRemotes"
	remotes.Parent = ReplicatedStorage
end

-- Create RemoteFunction for getting cash
local getCashRemote = Instance.new("RemoteFunction")
getCashRemote.Name = "GetPlayerCash"
getCashRemote.Parent = remotes

-- Create RemoteEvent for cash updates
local cashUpdateRemote = Instance.new("RemoteEvent")
cashUpdateRemote.Name = "CashUpdated"
cashUpdateRemote.Parent = remotes

-- Handle cash requests
getCashRemote.OnServerInvoke = function(player)
	-- Try UnifiedLeaderboard API first
	if _G.GetPlayerMoney then
		return _G.GetPlayerMoney(player.Name) or 0
	end
	
	-- Fallback to ServerStorage PlayerMoney
	local playerMoneyFolder = ServerStorage:FindFirstChild("PlayerMoney")
	if playerMoneyFolder then
		local playerMoney = playerMoneyFolder:FindFirstChild(player.Name)
		if playerMoney then
			return playerMoney.Value
		end
	end
	
	return 0
end

-- Monitor cash changes and notify clients
local playerConnections = {}

local function setupPlayerMonitoring(player)
	-- Clean up any existing connections
	if playerConnections[player] then
		for _, conn in pairs(playerConnections[player]) do
			conn:Disconnect()
		end
	end
	
	playerConnections[player] = {}
	
	-- Monitor ServerStorage PlayerMoney
	local playerMoneyFolder = ServerStorage:FindFirstChild("PlayerMoney")
	if playerMoneyFolder then
		local playerMoney = playerMoneyFolder:FindFirstChild(player.Name)
		if not playerMoney then
			-- Wait for it to be created
			local conn = playerMoneyFolder.ChildAdded:Connect(function(child)
				if child.Name == player.Name then
					setupPlayerMonitoring(player) -- Re-setup with the new value
				end
			end)
			table.insert(playerConnections[player], conn)
		else
			-- Monitor changes
			local conn = playerMoney.Changed:Connect(function(newValue)
				cashUpdateRemote:FireClient(player, newValue)
			end)
			table.insert(playerConnections[player], conn)
		end
	end
end

-- Handle players
Players.PlayerAdded:Connect(function(player)
	-- Wait a bit for UnifiedLeaderboard to set up
	task.wait(1)
	setupPlayerMonitoring(player)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up connections
	if playerConnections[player] then
		for _, conn in pairs(playerConnections[player]) do
			conn:Disconnect()
		end
		playerConnections[player] = nil
	end
end)

print("💰 Cash UI Server initialized - Monitoring cash changes")