--[[
	Clean Tycoon Arrow Guide System
	- Uses your arrow mesh: rbxassetid://3684866704
	- No FindFirstDescendant errors
	- Properly tracks ownership
	- Small, clean arrows that guide to tycoons
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local ARROW_MESH_ID = "rbxassetid://3684866704"
local ARROW_COLOR = Color3.fromRGB(100, 255, 170)
local ARROW_SIZE = Vector3.new(3, 1, 3) -- Made wider for better arrow shape
local ARROW_HEIGHT = 6 -- Height above player
local MIN_DISTANCE = 20 -- Hide arrow when close
local TWEEN_TIME = 0.5 -- Slower for buttery smoothness
local MESH_SCALE = Vector3.new(1.5, 1.5, 2) -- Make arrow longer in Z direction

-- Tween settings - ULTRA SMOOTH
local tweenInfo = TweenInfo.new(
	TWEEN_TIME,
	Enum.EasingStyle.Linear, -- Linear for consistent smooth movement
	Enum.EasingDirection.InOut,
	0, -- No repeat
	false, -- No reverse
	0 -- No delay
)

-- Track player arrows and ownership
local playerArrows = {}
local playerOwnership = {}
local activeTweens = {}
local lastPositions = {} -- Track last position for smooth interpolation

-- Find all tycoon gates
local function findTycoonGates()
	local gates = {}
	
	-- Search for tycoon gates
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and (obj.Name == "Touch to claim!" or obj.Name:lower():find("gate")) then
			local touchPart = obj:FindFirstChild("Head")
			if touchPart and obj.Parent and obj.Parent.Parent then
				local tycoon = obj.Parent.Parent
				-- Check for Owner value
				local owner = tycoon:FindFirstChild("Owner")
				if owner and owner:IsA("ObjectValue") then
					table.insert(gates, {
						gate = obj,
						tycoon = tycoon,
						owner = owner,
						position = touchPart.Position
					})
				end
			end
		end
	end
	
	return gates
end

-- Create arrow model
local function createArrow()
	local model = Instance.new("Model")
	model.Name = "TycoonGuideArrow"
	
	-- Create arrow part with mesh
	local arrow = Instance.new("Part")
	arrow.Name = "Arrow"
	arrow.Size = ARROW_SIZE
	arrow.Material = Enum.Material.Neon
	arrow.Color = ARROW_COLOR
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Parent = model
	
	-- Add the arrow mesh with custom scale
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = ARROW_MESH_ID
	mesh.Scale = MESH_SCALE -- Make it longer!
	mesh.Parent = arrow
	
	-- Add glow
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 2
	pointLight.Color = ARROW_COLOR
	pointLight.Range = 10
	pointLight.Parent = arrow
	
	-- Distance text
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DistanceDisplay"
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, -3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = arrow
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "DistanceText"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "0m"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Parent = billboard
	
	-- Set primary part
	model.PrimaryPart = arrow
	
	return model
end

-- Ultra smooth arrow movement with interpolation
local function smoothMoveArrow(arrow, targetCFrame, player)
	local arrowPart = arrow.PrimaryPart
	if not arrowPart then return end
	
	-- Get current position
	local currentCFrame = arrowPart.CFrame
	
	-- Calculate distance to move
	local distance = (targetCFrame.Position - currentCFrame.Position).Magnitude
	
	-- Adjust tween time based on distance for consistent speed
	local speed = 15 -- studs per second
	local adjustedTime = math.max(0.1, math.min(1, distance / speed))
	
	-- Create dynamic tween info
	local dynamicTweenInfo = TweenInfo.new(
		adjustedTime,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	-- Cancel existing tween
	if activeTweens[arrow] then
		activeTweens[arrow]:Cancel()
	end
	
	-- Create smooth tween
	local tween = TweenService:Create(
		arrowPart,
		dynamicTweenInfo,
		{CFrame = targetCFrame}
	)
	
	activeTweens[arrow] = tween
	tween:Play()
	
	-- Store last position
	lastPositions[player] = targetCFrame
end

-- Update arrow for player with interpolation
local function updatePlayerArrow(player, deltaTime)
	local character = player.Character
	if not character then
		-- Remove arrow if no character
		if playerArrows[player] then
			if activeTweens[playerArrows[player]] then
				activeTweens[playerArrows[player]]:Cancel()
			end
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		lastPositions[player] = nil
		return
	end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return end
	
	-- Check if player owns a tycoon
	local gates = findTycoonGates()
	local ownsATycoon = false
	
	for _, gateData in pairs(gates) do
		if gateData.owner.Value == player then
			ownsATycoon = true
			break
		end
	end
	
	-- Remove arrow if player owns a tycoon
	if ownsATycoon then
		if playerArrows[player] then
			if activeTweens[playerArrows[player]] then
				activeTweens[playerArrows[player]]:Cancel()
			end
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		playerOwnership[player] = true
		lastPositions[player] = nil
		return
	end
	
	-- Find nearest unclaimed tycoon
	local nearestGate = nil
	local nearestDistance = math.huge
	
	for _, gateData in pairs(gates) do
		if not gateData.owner.Value then -- Unclaimed
			local distance = (gateData.position - humanoidRoot.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestGate = gateData
			end
		end
	end
	
	-- No unclaimed tycoons
	if not nearestGate then
		if playerArrows[player] then
			if activeTweens[playerArrows[player]] then
				activeTweens[playerArrows[player]]:Cancel()
			end
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		lastPositions[player] = nil
		return
	end
	
	-- Hide arrow if too close
	if nearestDistance < MIN_DISTANCE then
		if playerArrows[player] then
			-- Fade out smoothly
			local arrowPart = playerArrows[player].PrimaryPart
			if arrowPart then
				TweenService:Create(arrowPart, TweenInfo.new(0.2), {Transparency = 1}):Play()
			end
		end
		return
	end
	
	-- Create or show arrow
	if not playerArrows[player] then
		playerArrows[player] = createArrow()
		playerArrows[player].Parent = workspace
		
		-- Start with initial position
		local arrowPos = humanoidRoot.Position + Vector3.new(0, ARROW_HEIGHT, 0)
		local direction = (nearestGate.position - humanoidRoot.Position).Unit
		local lookAt = CFrame.lookAt(arrowPos, arrowPos + direction)
		local initialCFrame = lookAt * CFrame.Angles(0, math.rad(90), 0)
		playerArrows[player]:SetPrimaryPartCFrame(initialCFrame)
		lastPositions[player] = initialCFrame
	else
		-- Fade in if hidden
		local arrowPart = playerArrows[player].PrimaryPart
		if arrowPart and arrowPart.Transparency > 0 then
			TweenService:Create(arrowPart, TweenInfo.new(0.2), {Transparency = 0}):Play()
		end
		playerArrows[player].Parent = workspace
	end
	
	local arrow = playerArrows[player]
	
	-- Calculate target position with smooth interpolation
	local basePos = humanoidRoot.Position + Vector3.new(0, ARROW_HEIGHT, 0)
	
	-- Add gentle float animation
	local time = tick()
	local floatOffset = math.sin(time * 1.5) * 0.3 -- Slower, smaller float
	basePos = basePos + Vector3.new(0, floatOffset, 0)
	
	-- Smooth direction calculation with prediction
	local playerVelocity = humanoidRoot.AssemblyLinearVelocity
	local predictedPos = humanoidRoot.Position + (playerVelocity * 0.1) -- Predict 0.1 seconds ahead
	local direction = (nearestGate.position - predictedPos).Unit
	
	-- Calculate target CFrame
	local targetCFrame = CFrame.lookAt(basePos, basePos + direction) * CFrame.Angles(0, math.rad(90), 0)
	
	-- Only update if moved significantly (prevents micro-jumps)
	if lastPositions[player] then
		local lastPos = lastPositions[player].Position
		local targetPos = targetCFrame.Position
		local moveDist = (targetPos - lastPos).Magnitude
		
		-- Only update if moved more than 0.1 studs
		if moveDist > 0.1 then
			smoothMoveArrow(arrow, targetCFrame, player)
		end
	else
		smoothMoveArrow(arrow, targetCFrame, player)
	end
	
	-- Update distance text
	local distanceDisplay = arrow:FindFirstChild("Arrow"):FindFirstChild("DistanceDisplay")
	if distanceDisplay then
		local distanceText = distanceDisplay:FindFirstChild("DistanceText")
		if distanceText then
			distanceText.Text = math.floor(nearestDistance) .. "m"
			
			-- Smooth color transition
			local targetColor
			if nearestDistance < 50 then
				targetColor = Color3.fromRGB(100, 255, 100)
			elseif nearestDistance < 100 then
				targetColor = Color3.fromRGB(255, 255, 100)
			else
				targetColor = Color3.fromRGB(255, 255, 255)
			end
			
			-- Tween text color smoothly
			TweenService:Create(distanceText, TweenInfo.new(0.3), {TextColor3 = targetColor}):Play()
		end
	end
	
	-- Pulse the glow smoothly
	local pointLight = arrow:FindFirstChild("Arrow"):FindFirstChild("PointLight")
	if pointLight then
		pointLight.Brightness = 2 + math.sin(time * 2) * 0.3
	end
end

-- Main update loop with delta time
local lastTime = tick()
RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	local deltaTime = currentTime - lastTime
	lastTime = currentTime
	
	for _, player in pairs(Players:GetPlayers()) do
		updatePlayerArrow(player, deltaTime)
	end
end)

-- Clean up on player leaving
Players.PlayerRemoving:Connect(function(player)
	if playerArrows[player] then
		if activeTweens[playerArrows[player]] then
			activeTweens[playerArrows[player]]:Cancel()
		end
		playerArrows[player]:Destroy()
		playerArrows[player] = nil
	end
	playerOwnership[player] = nil
	activeTweens[player] = nil
	lastPositions[player] = nil
end)

-- Handle player spawning
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Reset ownership tracking when respawning
		playerOwnership[player] = nil
		lastPositions[player] = nil
	end)
end)

print("✅ Clean Tycoon Arrow Guide loaded!")
print("🏹 Using arrow mesh:", ARROW_MESH_ID)
print("📍 BUTTERY SMOOTH movement - no jumps!")
print("📏 Arrow scaled to:", MESH_SCALE)
print("✨ Tracks ownership properly")