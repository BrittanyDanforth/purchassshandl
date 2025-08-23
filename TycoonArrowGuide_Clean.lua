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
local ARROW_SIZE = Vector3.new(2, 2, 2) -- Small arrow
local ARROW_HEIGHT = 6 -- Height above player
local MIN_DISTANCE = 20 -- Hide arrow when close
local CHECK_INTERVAL = 0.5 -- How often to update

-- Track player arrows and ownership
local playerArrows = {}
local playerOwnership = {}

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
	
	-- Add the arrow mesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = ARROW_MESH_ID
	mesh.Scale = Vector3.new(1, 1, 1)
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

-- Update arrow for player
local function updatePlayerArrow(player)
	local character = player.Character
	if not character then
		-- Remove arrow if no character
		if playerArrows[player] then
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
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
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		playerOwnership[player] = true
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
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		return
	end
	
	-- Hide arrow if too close
	if nearestDistance < MIN_DISTANCE then
		if playerArrows[player] then
			playerArrows[player].Parent = nil
		end
		return
	end
	
	-- Create or show arrow
	if not playerArrows[player] then
		playerArrows[player] = createArrow()
		playerArrows[player].Parent = workspace
	else
		playerArrows[player].Parent = workspace
	end
	
	local arrow = playerArrows[player]
	
	-- Position arrow above player
	local arrowPos = humanoidRoot.Position + Vector3.new(0, ARROW_HEIGHT, 0)
	
	-- Point arrow toward tycoon
	local direction = (nearestGate.position - humanoidRoot.Position).Unit
	local lookAt = CFrame.lookAt(arrowPos, arrowPos + direction)
	
	-- Rotate to point forward
	arrow:SetPrimaryPartCFrame(lookAt * CFrame.Angles(0, math.rad(90), 0))
	
	-- Update distance text
	local distanceDisplay = arrow:FindFirstChild("Arrow"):FindFirstChild("DistanceDisplay")
	if distanceDisplay then
		local distanceText = distanceDisplay:FindFirstChild("DistanceText")
		if distanceText then
			distanceText.Text = math.floor(nearestDistance) .. "m"
			
			-- Color based on distance
			if nearestDistance < 50 then
				distanceText.TextColor3 = Color3.fromRGB(100, 255, 100)
			elseif nearestDistance < 100 then
				distanceText.TextColor3 = Color3.fromRGB(255, 255, 100)
			else
				distanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
end

-- Main update loop
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastUpdate < CHECK_INTERVAL then return end
	lastUpdate = now
	
	for _, player in pairs(Players:GetPlayers()) do
		updatePlayerArrow(player)
	end
end)

-- Clean up on player leaving
Players.PlayerRemoving:Connect(function(player)
	if playerArrows[player] then
		playerArrows[player]:Destroy()
		playerArrows[player] = nil
	end
	playerOwnership[player] = nil
end)

-- Handle player spawning
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Reset ownership tracking when respawning
		playerOwnership[player] = nil
	end)
end)

print("✅ Clean Tycoon Arrow Guide loaded!")
print("🏹 Using arrow mesh:", ARROW_MESH_ID)
print("📍 No FindFirstDescendant errors!")
print("✨ Tracks ownership properly")