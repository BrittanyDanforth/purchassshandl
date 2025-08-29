--[[
    Module: RemoteManager
    Description: Centralized remote communication with queue management, retry logic, and traffic monitoring
    Handles all RemoteEvents and RemoteFunctions with proper error handling
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local RemoteManager = {}
RemoteManager.__index = RemoteManager

-- ========================================
-- CONSTANTS
-- ========================================

local REMOTE_EVENTS = {
	-- Data Events
	"DataLoaded",
	"DataUpdated", 
	"CurrencyUpdated",
	"PetDeleted",

	-- Game Events
	"CaseOpened",
	"TradeUpdated",
	"TradeCompleted",
	"QuestsUpdated",
	"QuestCompleted",
	"AchievementUnlocked",
	"NotificationSent",
	"MatchmakingFound",
	"BattleStarted",
	"BattleEnded",
	"DailyRewardAvailable",

	-- Social Events
	"TradeRequest",
	"FriendRequest",
	"ClanInvite",
	"ChatMessage",
}

local REMOTE_FUNCTIONS = {
	-- Data Functions
	"GetPlayerData",
	"GetShopData",
	"SyncDataChanges",

	-- Pet Functions
	"OpenCase",
	"EquipPet",
	"UnequipPet",
	"LockPet",
	"UnlockPet",
	"RenamePet",
	"DeletePet",
	"MassDeletePets",
	"EvolvePet",
	"FusePets",

	-- Trading Functions
	"GetRecentTradePartners",
	"RequestTrade",
	"UpdateTrade",
	"ConfirmTrade",
	"CancelTrade",

	-- Battle Functions
	"JoinBattleMatchmaking",
	"CancelMatchmaking",
	"JoinBattle",
	"SelectBattleMove",
	"ForfeitBattle",

	-- Quest Functions
	"ClaimQuest",
	"AbandonQuest",

	-- Shop Functions
	"PurchaseItem",
	"PurchaseGamepass",
	"PurchaseCurrency",

	-- Daily Reward
	"ClaimDailyReward",

	-- Settings
	"UpdateSettings",

	-- Social Functions
	"SendClanInvite",
	"AcceptClanInvite",
	"LeaveClan",
	"PromoteMember",
	"KickMember",
}

-- ========================================
-- INITIALIZATION
-- ========================================

function RemoteManager.new(dependencies)
	local self = setmetatable({}, RemoteManager)

	-- Dependencies
	self._config = dependencies.Config or Config
	self._utilities = dependencies.Utilities or Utilities
	self._eventBus = dependencies.EventBus

	-- Remote storage
	self._remoteEvents = {}
	self._remoteFunctions = {}
	self._connections = {}

	-- Request queue
	self._requestQueue = {}
	self._processing = false
	self._maxQueueSize = 100
	self._processInterval = 0.1

	-- Rate limiting
	self._rateLimiter = {
		requests = {},
		maxRequests = self._config.NETWORK.RATE_LIMIT,
		window = 1, -- 1 second window
	}

	-- Retry configuration
	self._retryConfig = {
		maxRetries = self._config.NETWORK.MAX_RETRIES,
		baseDelay = self._config.NETWORK.RETRY_DELAY,
		maxDelay = 10,
		backoffMultiplier = 2,
	}

	-- Traffic monitoring
	self._traffic = {
		sent = 0,
		received = 0,
		byEvent = {},
		byFunction = {},
		errors = 0,
	}

	-- Settings
	self._debugMode = self._config.DEBUG.ENABLED
	self._timeout = self._config.NETWORK.REQUEST_TIMEOUT

	self:Initialize()

	return self
end

function RemoteManager:Initialize()
	-- Get remote folders
	local remoteEventsFolder = Services.ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	local remoteFunctionsFolder = Services.ReplicatedStorage:WaitForChild("RemoteFunctions", 10)

	if not remoteEventsFolder or not remoteFunctionsFolder then
		error("[RemoteManager] Remote folders not found in ReplicatedStorage")
	end

	-- Load RemoteEvents
	for _, eventName in ipairs(REMOTE_EVENTS) do
		local remote = remoteEventsFolder:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			self._remoteEvents[eventName] = remote
			self._traffic.byEvent[eventName] = {sent = 0, received = 0}
		else
			warn("[RemoteManager] RemoteEvent not found:", eventName)
		end
	end

	-- Load RemoteFunctions
	for _, functionName in ipairs(REMOTE_FUNCTIONS) do
		local remote = remoteFunctionsFolder:FindFirstChild(functionName)
		if remote and remote:IsA("RemoteFunction") then
			self._remoteFunctions[functionName] = remote
			self._traffic.byFunction[functionName] = {sent = 0, received = 0}
		else
			warn("[RemoteManager] RemoteFunction not found:", functionName)
		end
	end

	-- Start queue processor
	self:StartQueueProcessor()

	if self._debugMode then
		print(string.format("[RemoteManager] Initialized with %d events and %d functions", 
			self:CountTable(self._remoteEvents), 
			self:CountTable(self._remoteFunctions)))
	end
end

-- ========================================
-- REGISTRATION METHODS
-- ========================================

function RemoteManager:RegisterRemoteEvent(remote: RemoteEvent)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[RemoteManager] Invalid RemoteEvent provided")
		return
	end

	local eventName = remote.Name
	self._remoteEvents[eventName] = remote
	self._traffic.byEvent[eventName] = {sent = 0, received = 0}

	if self._debugMode then
		print("[RemoteManager] Registered RemoteEvent:", eventName)
	end
end

function RemoteManager:RegisterRemoteFunction(remote: RemoteFunction)
	if not remote or not remote:IsA("RemoteFunction") then
		warn("[RemoteManager] Invalid RemoteFunction provided")
		return
	end

	local functionName = remote.Name
	self._remoteFunctions[functionName] = remote
	self._traffic.byFunction[functionName] = {sent = 0, received = 0}

	if self._debugMode then
		print("[RemoteManager] Registered RemoteFunction:", functionName)
	end
end

-- ========================================
-- REMOTE EVENT HANDLING
-- ========================================

function RemoteManager:GetRemoteEvent(name: string): RemoteEvent?
	return self._remoteEvents[name]
end

function RemoteManager:On(eventName: string, handler: (...any) -> ()): Types.Connection
	local remote = self._remoteEvents[eventName]
	if not remote then
		-- Don't warn for every missing remote, just return a disconnected connection
		-- This allows the client to set up handlers that will work when remotes are added
		return {
			Disconnect = function() end,
			Connected = false
		}
	end

	-- Create connection
	local connection = remote.OnClientEvent:Connect(function(...)
		-- Update traffic stats
		self._traffic.received = self._traffic.received + 1
		self._traffic.byEvent[eventName].received = self._traffic.byEvent[eventName].received + 1

		-- Call handler with error protection
		local success, err = pcall(handler, ...)

		if not success then
			self._traffic.errors = self._traffic.errors + 1
			warn(string.format("[RemoteManager] Handler error for '%s': %s", eventName, err))
		end

		-- Fire event bus if available
		if self._eventBus then
			self._eventBus:Fire("Remote" .. eventName, ...)
		end
	end)

	-- Store connection for cleanup
	if not self._connections[eventName] then
		self._connections[eventName] = {}
	end
	table.insert(self._connections[eventName], connection)

	return connection
end

function RemoteManager:Once(eventName: string, handler: (...any) -> ()): Types.Connection
	local connection
	connection = self:On(eventName, function(...)
		connection:Disconnect()
		handler(...)
	end)
	return connection
end

function RemoteManager:Fire(eventName: string, ...: any)
	local remote = self._remoteEvents[eventName]
	if not remote then
		warn("[RemoteManager] RemoteEvent not found:", eventName)
		return
	end

	-- Check rate limit
	if not self:CheckRateLimit() then
		warn("[RemoteManager] Rate limit exceeded")
		return
	end

	-- Update traffic stats
	self._traffic.sent = self._traffic.sent + 1
	self._traffic.byEvent[eventName].sent = self._traffic.byEvent[eventName].sent + 1

	-- Fire to server
	remote:FireServer(...)

	if self._debugMode then
		print(string.format("[RemoteManager] Fired '%s'", eventName))
	end
end

-- ========================================
-- REMOTE FUNCTION HANDLING
-- ========================================

function RemoteManager:GetRemoteFunction(name: string): RemoteFunction?
	return self._remoteFunctions[name]
end

function RemoteManager:Invoke(functionName: string, ...: any): any
	local remote = self._remoteFunctions[functionName]
	if not remote then
		warn("[RemoteManager] RemoteFunction not found:", functionName)
		return nil
	end

	-- Create request
	local request = {
		functionName = functionName,
		args = {...},
		timestamp = tick(),
		retryCount = 0,
	}

	-- Try immediate execution if not rate limited
	if self:CheckRateLimit() then
		return self:ExecuteRequest(request)
	else
		-- Queue the request
		return self:QueueRequest(request)
	end
end

-- Alias for compatibility
function RemoteManager:InvokeFunction(functionName: string, ...: any): any
	return self:Invoke(functionName, ...)
end

function RemoteManager:InvokeServer(functionName: string, ...: any): Types.RemoteResult<any>
	local result = self:Invoke(functionName, ...)

	-- Standardize result format
	if type(result) == "table" and result.success ~= nil then
		return result
	else
		return {
			success = result ~= nil,
			data = result,
			error = result == nil and "No response" or nil,
		}
	end
end

function RemoteManager:ExecuteRequest(request)
	local remote = self._remoteFunctions[request.functionName]
	if not remote then
		return nil
	end

	-- Update traffic stats
	self._traffic.sent = self._traffic.sent + 1
	self._traffic.byFunction[request.functionName].sent = 
		self._traffic.byFunction[request.functionName].sent + 1

	-- Create timeout
	local completed = false
	local result = nil

	task.spawn(function()
		task.wait(self._timeout)
		if not completed then
			completed = true
			result = {
				success = false,
				error = "Request timeout",
				code = "TIMEOUT"
			}
		end
	end)

	-- Invoke with error handling
	local success, response = pcall(function()
		return remote:InvokeServer(table.unpack(request.args))
	end)

	if completed then
		-- Already timed out
		return result
	end

	completed = true

	if success then
		-- Update received stats
		self._traffic.received = self._traffic.received + 1
		self._traffic.byFunction[request.functionName].received = 
			self._traffic.byFunction[request.functionName].received + 1

		return response
	else
		-- Handle error
		self._traffic.errors = self._traffic.errors + 1

		-- Check if we should retry
		if request.retryCount < self._retryConfig.maxRetries then
			request.retryCount = request.retryCount + 1

			local delay = math.min(
				self._retryConfig.baseDelay * (self._retryConfig.backoffMultiplier ^ (request.retryCount - 1)),
				self._retryConfig.maxDelay
			)

			if self._debugMode then
				print(string.format("[RemoteManager] Retrying '%s' (attempt %d) after %.1fs", 
					request.functionName, request.retryCount + 1, delay))
			end

			task.wait(delay)
			return self:ExecuteRequest(request)
		else
			return {
				success = false,
				error = tostring(response),
				code = "INVOKE_ERROR"
			}
		end
	end
end

-- ========================================
-- QUEUE MANAGEMENT
-- ========================================

function RemoteManager:QueueRequest(request)
	if #self._requestQueue >= self._maxQueueSize then
		warn("[RemoteManager] Request queue full, dropping request")
		return {
			success = false,
			error = "Queue full",
			code = "QUEUE_FULL"
		}
	end

	-- Create promise for async result
	local promise = {}
	promise._resolved = false
	promise._result = nil

	request.promise = promise

	table.insert(self._requestQueue, request)

	-- Wait for result
	while not promise._resolved do
		task.wait()
	end

	return promise._result
end

function RemoteManager:StartQueueProcessor()
	task.spawn(function()
		while true do
			if #self._requestQueue > 0 and not self._processing then
				self:ProcessQueue()
			end
			task.wait(self._processInterval)
		end
	end)
end

function RemoteManager:ProcessQueue()
	self._processing = true

	while #self._requestQueue > 0 do
		-- Check rate limit
		if not self:CheckRateLimit() then
			task.wait(0.1)
			continue
		end

		local request = table.remove(self._requestQueue, 1)
		if request then
			local result = self:ExecuteRequest(request)

			-- Resolve promise
			if request.promise then
				request.promise._result = result
				request.promise._resolved = true
			end
		end
	end

	self._processing = false
end

-- ========================================
-- RATE LIMITING
-- ========================================

function RemoteManager:CheckRateLimit(): boolean
	local now = tick()
	local cutoff = now - self._rateLimiter.window

	-- Clean old requests
	local validRequests = {}
	for _, timestamp in ipairs(self._rateLimiter.requests) do
		if timestamp > cutoff then
			table.insert(validRequests, timestamp)
		end
	end

	self._rateLimiter.requests = validRequests

	-- Check if under limit
	if #self._rateLimiter.requests < self._rateLimiter.maxRequests then
		table.insert(self._rateLimiter.requests, now)
		return true
	end

	return false
end

-- ========================================
-- DEFAULT HANDLERS
-- ========================================

function RemoteManager:SetupDefaultHandlers()
	-- Data handlers
	self:On("DataLoaded", function(playerData)
		if self._debugMode then
			print("[RemoteManager] Data loaded")
		end
		
		-- Update data cache
		if self._dataCache then
			self._dataCache:Set("playerData", playerData)
			
			-- Store pet database separately for easy access
			if playerData.petDatabase then
				self._dataCache:Set("petDatabase", playerData.petDatabase)
			end
			
			-- Update currencies specifically
			if playerData.currencies then
				self._dataCache:Set("currencies", playerData.currencies)
			end
			
			-- Update pets
			if playerData.pets then
				self._dataCache:Set("pets", playerData.pets)
			end
		end
		
		-- Fire state change for UI updates
		if self._stateManager then
			self._stateManager:SetState("playerData", playerData)
		end
		
		-- Fire event for other systems
		if self._eventBus then
			self._eventBus:Fire("PlayerDataLoaded", playerData)
		end
	end)

	self:On("DataUpdated", function(data)
		if self._debugMode then
			print("[RemoteManager] Data updated:", data)
		end
		
		-- Forward to event bus for other systems
		if self._eventBus then
			-- If it's raw player data (from server), wrap it
			if data and data.currencies and data.pets then
				self._eventBus:Fire("DataUpdated", {
					type = "full",
					playerData = data
				})
			else
				-- Already formatted, forward as-is
				self._eventBus:Fire("DataUpdated", data)
			end
		end
	end)

	self:On("CurrencyUpdated", function(currencies)
		if self._debugMode then
			print("[RemoteManager] Currencies updated")
		end
	end)

	-- Error handler
	self:On("NotificationSent", function(data)
		if data.type == "error" then
			warn("[RemoteManager] Server error:", data.message)
		end
	end)
end

-- ========================================
-- TRAFFIC MONITORING
-- ========================================

function RemoteManager:GetTraffic(): {sent: number, received: number}
	return {
		sent = self._traffic.sent,
		received = self._traffic.received,
	}
end

function RemoteManager:GetDetailedTraffic(): table
	return self._utilities.DeepCopy(self._traffic)
end

function RemoteManager:ResetTrafficStats()
	self._traffic.sent = 0
	self._traffic.received = 0
	self._traffic.errors = 0

	for _, stats in pairs(self._traffic.byEvent) do
		stats.sent = 0
		stats.received = 0
	end

	for _, stats in pairs(self._traffic.byFunction) do
		stats.sent = 0
		stats.received = 0
	end
end

function RemoteManager:EnableDebug(enabled: boolean)
	self._debugMode = enabled
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function RemoteManager:CountTable(tbl: table): number
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function RemoteManager:DisconnectAll()
	for eventName, connections in pairs(self._connections) do
		for _, connection in ipairs(connections) do
			if connection.Connected then
				connection:Disconnect()
			end
		end
	end
	self._connections = {}
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
	function RemoteManager:DebugPrint()
		print("\n=== RemoteManager Debug Info ===")
		print("Total Sent:", self._traffic.sent)
		print("Total Received:", self._traffic.received)
		print("Total Errors:", self._traffic.errors)
		print("Queue Size:", #self._requestQueue)

		print("\nTop Events (by traffic):")
		local eventStats = {}
		for name, stats in pairs(self._traffic.byEvent) do
			table.insert(eventStats, {
				name = name,
				total = stats.sent + stats.received
			})
		end
		table.sort(eventStats, function(a, b) return a.total > b.total end)

		for i = 1, math.min(5, #eventStats) do
			local stat = eventStats[i]
			print(string.format("  %s: %d", stat.name, stat.total))
		end

		print("\nTop Functions (by traffic):")
		local functionStats = {}
		for name, stats in pairs(self._traffic.byFunction) do
			table.insert(functionStats, {
				name = name,
				total = stats.sent + stats.received
			})
		end
		table.sort(functionStats, function(a, b) return a.total > b.total end)

		for i = 1, math.min(5, #functionStats) do
			local stat = functionStats[i]
			print(string.format("  %s: %d", stat.name, stat.total))
		end

		print("===============================\n")
	end
end

-- ========================================
-- CLEANUP
-- ========================================

function RemoteManager:Destroy()
	-- Disconnect all connections
	self:DisconnectAll()

	-- Clear queue
	self._requestQueue = {}

	-- Clear remotes
	self._remoteEvents = {}
	self._remoteFunctions = {}
end

return RemoteManager