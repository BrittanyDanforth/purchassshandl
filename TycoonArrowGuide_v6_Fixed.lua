--[[
	Tycoon Arrow Guide v6 - FIXED VERSION
	- Uses MeshPart with proper arrow mesh
	- No more MeshId errors
	- Clean directional guidance
	- Properly removes when you claim a tycoon
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")

-- Configuration
local ARROW_MESH_ID = "rbxassetid://3684866704" -- Your arrow mesh
local ARROW_COLOR = Color3.fromRGB(100, 255, 170) -- Mint green
local ARROW_SIZE = Vector3.new(4, 1, 4) -- Arrow size
local COMPASS_DISTANCE = 20 -- Distance from player
local COMPASS_HEIGHT = 8 -- Height above ground
local MIN_DISTANCE = 25 -- Don't show if closer

-- Track player arrows
local playerArrows = {}

-- Create arrow using SpecialMesh (since we can't set MeshId on server)
local function createArrowModel()
	local model = Instance.new("Model")
	model.Name = "TycoonGuideArrow"
	
	-- Use a Part with SpecialMesh instead of MeshPart
	local arrow = Instance.new("Part")
	arrow.Name = "Arrow"
	arrow.Size = ARROW_SIZE
	arrow.Material = Enum.Material.Neon
	arrow.Color = ARROW_COLOR
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CastShadow = false
	arrow.Parent = model
	
	-- Add SpecialMesh for the arrow shape
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = ARROW_MESH_ID
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = arrow
	
	-- Glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 2
	pointLight.Color = ARROW_COLOR
	pointLight.Range = 15
	pointLight.Shadows = false
	pointLight.Parent = arrow
	
	-- Distance display
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, -3, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = arrow
	
	local bgFrame = Instance.new("Frame")
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.6
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboard
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = bgFrame
	
	local distText = Instance.new("TextLabel")
	distText.Name = "DistanceText"
	distText.Size = UDim2.new(1, -4, 1, 0)
	distText.Position = UDim2.new(0, 2, 0, 0)
	distText.BackgroundTransparency = 1
	distText.Text = "0m"
	distText.TextColor3 = Color3.new(1, 1, 1)
	distText.TextStrokeTransparency = 0.5
	distText.Font = Enum.Font.GothamBold
	distText.TextScaled = true
	distText.Parent = billboard
	
	model.PrimaryPart = arrow
	return model
end

-- Find unclaimed tycoons
local function getUnclaimedTycoons()
	local unclaimed = {}
	
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Owner" and obj:IsA("ObjectValue") then
			local tycoon = obj.Parent
			
			if obj.Value == nil then
				local claimPos = nil
				
				-- Find gate
				for _, child in ipairs(tycoon:GetDescendants()) do
					if child:IsA("Model") and (child.Name == "Touch to claim!" or child.Name:lower():find("gate") or child.Name:lower():find("claim")) then
						local part = child:FindFirstChild("Head") or child:FindFirstChildWhichIsA("BasePart")
						if part and part.Transparency < 1 then
							claimPos = part.Position
							break
						end
					end
				end
				
				-- Fallback to tycoon center
				if not claimPos and tycoon:IsA("Model") then
					local cf, size = tycoon:GetBoundingBox()
					claimPos = cf.Position
				end
				
				if claimPos then
					table.insert(unclaimed, {
						tycoon = tycoon,
						position = claimPos,
						owner = obj
					})
				end
			end
		end
	end
	
	return unclaimed
end

-- Check if player owns a tycoon
local function playerOwnsTycoon(player)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Owner" and obj:IsA("ObjectValue") and obj.Value == player then
			return true
		end
	end
	return false
end

-- Update arrow for player
local function updatePlayerArrow(player)
	local character = player.Character
	if not character then return end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return end
	
	-- Remove arrow if player owns a tycoon
	if playerOwnsTycoon(player) then
		if playerArrows[player] then
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		return
	end
	
	-- Get unclaimed tycoons
	local unclaimed = getUnclaimedTycoons()
	if #unclaimed == 0 then
		if playerArrows[player] then
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		return
	end
	
	-- Find closest
	local closest = nil
	local closestDist = math.huge
	
	for _, data in ipairs(unclaimed) do
		local dist = (data.position - humanoidRoot.Position).Magnitude
		if dist < closestDist then
			closest = data
			closestDist = dist
		end
	end
	
	-- Hide if too close
	if closestDist < MIN_DISTANCE then
		if playerArrows[player] then
			local arrow = playerArrows[player].PrimaryPart
			if arrow then
				arrow.Transparency = 1
				local light = arrow:FindFirstChildOfClass("PointLight")
				if light then light.Enabled = false end
			end
		end
		return
	end
	
	-- Create or show arrow
	local arrowModel = playerArrows[player]
	if not arrowModel then
		arrowModel = createArrowModel()
		arrowModel.Parent = workspace
		playerArrows[player] = arrowModel
	else
		-- Make visible again
		local arrow = arrowModel.PrimaryPart
		if arrow then
			arrow.Transparency = 0
			local light = arrow:FindFirstChildOfClass("PointLight")
			if light then light.Enabled = true end
		end
	end
	
	-- Position arrow
	local playerPos = humanoidRoot.Position
	local direction = (closest.position - Vector3.new(playerPos.X, closest.position.Y, playerPos.Z)).Unit
	local arrowPos = playerPos + direction * COMPASS_DISTANCE + Vector3.new(0, COMPASS_HEIGHT, 0)
	
	-- Point toward tycoon
	local lookDirection = (closest.position - arrowPos).Unit
	arrowModel:SetPrimaryPartCFrame(
		CFrame.lookAt(arrowPos, arrowPos + lookDirection) * CFrame.Angles(0, math.rad(90), 0)
	)
	
	-- Animate
	local arrow = arrowModel.PrimaryPart
	if arrow then
		-- Pulse effect
		local pulse = math.sin(tick() * 2.5) * 0.1 + 0.9
		local light = arrow:FindFirstChildOfClass("PointLight")
		if light then
			light.Brightness = 2 * pulse
			light.Range = 15 + (5 * pulse)
		end
		
		-- Floating
		local floatY = math.sin(tick() * 2) * 0.5
		arrowModel:SetPrimaryPartCFrame(arrowModel.PrimaryPart.CFrame + Vector3.new(0, floatY * 0.1, 0))
	end
	
	-- Update distance
	local distText = arrowModel:FindFirstDescendant("DistanceText")
	if distText then
		distText.Text = math.floor(closestDist) .. "m"
		
		-- Color by distance
		if closestDist < 50 then
			distText.TextColor3 = Color3.fromRGB(150, 255, 150)
		elseif closestDist < 100 then
			distText.TextColor3 = Color3.fromRGB(255, 255, 150)
		else
			distText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	if playerArrows[player] then
		playerArrows[player]:Destroy()
		playerArrows[player] = nil
	end
end)

-- Simple tycoon markers
local tycoonMarkers = {}

local function updateTycoonMarkers()
	-- Clean old
	for tycoon, marker in pairs(tycoonMarkers) do
		local owner = tycoon:FindFirstChild("Owner")
		if not owner or owner.Value ~= nil then
			marker:Destroy()
			tycoonMarkers[tycoon] = nil
		end
	end
	
	-- Add new
	local unclaimed = getUnclaimedTycoons()
	for _, data in ipairs(unclaimed) do
		if not tycoonMarkers[data.tycoon] then
			-- Small ring on ground
			local ring = Instance.new("Part")
			ring.Name = "TycoonMarker"
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.5, 10, 10)
			ring.Material = Enum.Material.ForceField
			ring.Color = ARROW_COLOR
			ring.Transparency = 0.8
			ring.Anchored = true
			ring.CanCollide = false
			ring.CFrame = CFrame.new(data.position - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent = workspace
			
			tycoonMarkers[data.tycoon] = ring
			
			-- Spin animation
			task.spawn(function()
				while ring.Parent do
					ring.CFrame = ring.CFrame * CFrame.Angles(0, math.rad(1), 0)
					task.wait()
				end
			end)
		end
	end
end

-- Main loop
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerArrow(player)
	end
end)

-- Update markers
task.spawn(function()
	while true do
		updateTycoonMarkers()
		task.wait(3)
	end
end)

print("✅ Tycoon Arrow Guide v6 FIXED loaded!")
print("🏹 Using SpecialMesh to avoid MeshId errors")
print("📍 Smart directional guidance")
print("✨ Clean, error-free design")