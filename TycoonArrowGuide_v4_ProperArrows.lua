--[[
	Professional Tycoon Arrow Guide v4
	- ACTUAL 3D arrows that look good
	- Compass-style directional guidance
	- Properly removes when YOU claim a tycoon
	- Small, clean, polished design
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Configuration
local ARROW_COLOR = Color3.fromRGB(100, 255, 170) -- Mint green
local ARROW_SCALE = 0.6 -- Smaller arrows
local COMPASS_DISTANCE = 25 -- Distance from player
local COMPASS_HEIGHT = 10 -- Height above ground
local MIN_DISTANCE = 30 -- Don't show arrow if closer than this

-- Track player arrows and owned tycoons
local playerArrows = {}
local playerOwnsTycoon = {}

-- Create a proper 3D arrow model
local function createArrowModel()
	local model = Instance.new("Model")
	model.Name = "DirectionalArrow"
	
	-- Arrow body (cylinder)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(4, 0.8, 0.8) * ARROW_SCALE
	body.Material = Enum.Material.Neon
	body.Color = ARROW_COLOR
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	body.Parent = model
	
	-- Arrow head (3 wedges to form pointed tip)
	local headParts = {}
	
	-- Main head wedge
	local head1 = Instance.new("WedgePart")
	head1.Name = "Head1"
	head1.Size = Vector3.new(1.5, 1, 2) * ARROW_SCALE
	head1.Material = Enum.Material.Neon
	head1.Color = ARROW_COLOR
	head1.Anchored = true
	head1.CanCollide = false
	head1.Parent = model
	table.insert(headParts, head1)
	
	-- Side wedges for wider arrow head
	local head2 = Instance.new("WedgePart")
	head2.Name = "Head2"
	head2.Size = Vector3.new(1.5, 0.8, 1.5) * ARROW_SCALE
	head2.Material = Enum.Material.Neon
	head2.Color = ARROW_COLOR
	head2.Anchored = true
	head2.CanCollide = false
	head2.Parent = model
	table.insert(headParts, head2)
	
	local head3 = head2:Clone()
	head3.Name = "Head3"
	head3.Parent = model
	table.insert(headParts, head3)
	
	-- Glowing core
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(1, 1, 1) * ARROW_SCALE
	core.Material = Enum.Material.Neon
	core.Color = ARROW_COLOR
	core.Anchored = true
	core.CanCollide = false
	core.Transparency = 0.3
	core.Parent = model
	
	-- Light source
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Color = ARROW_COLOR
	light.Range = 15
	light.Parent = core
	
	-- Distance text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 80, 0, 25)
	billboard.StudsOffset = Vector3.new(0, -2, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = body
	
	local distText = Instance.new("TextLabel")
	distText.Name = "DistanceText"
	distText.Size = UDim2.new(1, 0, 1, 0)
	distText.BackgroundTransparency = 1
	distText.Text = "0m"
	distText.TextColor3 = Color3.new(1, 1, 1)
	distText.TextStrokeTransparency = 0
	distText.TextStrokeColor3 = Color3.new(0, 0, 0)
	distText.Font = Enum.Font.Gotham
	distText.TextScaled = true
	distText.Parent = billboard
	
	model.PrimaryPart = body
	return model, headParts
end

-- Find unclaimed tycoons
local function getUnclaimedTycoons()
	local unclaimed = {}
	
	-- Look for tycoons with owners
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Owner" and obj:IsA("ObjectValue") then
			local tycoon = obj.Parent
			
			-- Skip if someone owns it
			if obj.Value == nil then
				-- Find the gate/claim part
				local claimPart = nil
				local claimPos = nil
				
				-- Look for gate
				for _, child in ipairs(tycoon:GetDescendants()) do
					if child:IsA("Model") and (child.Name == "Touch to claim!" or child.Name:lower():find("gate") or child.Name:lower():find("claim")) then
						local part = child:FindFirstChild("Head") or child:FindFirstChildWhichIsA("BasePart")
						if part and part.Transparency < 1 then
							claimPart = part
							claimPos = part.Position
							break
						end
					end
				end
				
				-- Fallback to tycoon center
				if not claimPos and tycoon:IsA("Model") then
					claimPos = tycoon:GetBoundingBox().Position
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
local function checkPlayerOwnsTycoon(player)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Owner" and obj:IsA("ObjectValue") and obj.Value == player then
			return true, obj.Parent
		end
	end
	return false, nil
end

-- Update arrow for player
local function updatePlayerArrow(player)
	local character = player.Character
	if not character then return end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return end
	
	-- Check if player already owns a tycoon
	local ownsTycoon = checkPlayerOwnsTycoon(player)
	
	-- Remove arrow if player owns a tycoon
	if ownsTycoon then
		if playerArrows[player] then
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		playerOwnsTycoon[player] = true
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
	
	-- Find closest tycoon
	local closest = nil
	local closestDist = math.huge
	
	for _, data in ipairs(unclaimed) do
		local dist = (data.position - humanoidRoot.Position).Magnitude
		if dist < closestDist then
			closest = data
			closestDist = dist
		end
	end
	
	-- Only show arrow if far enough away
	if closestDist < MIN_DISTANCE then
		if playerArrows[player] then
			playerArrows[player]:Destroy()
			playerArrows[player] = nil
		end
		return
	end
	
	-- Create or update arrow
	local arrow = playerArrows[player]
	if not arrow then
		arrow, headParts = createArrowModel()
		arrow.Parent = workspace
		playerArrows[player] = arrow
	end
	
	-- Position arrow around player like a compass
	local playerPos = humanoidRoot.Position
	local direction = (closest.position - Vector3.new(playerPos.X, closest.position.Y, playerPos.Z)).Unit
	local arrowPos = playerPos + direction * COMPASS_DISTANCE + Vector3.new(0, COMPASS_HEIGHT, 0)
	
	-- Make arrow point toward tycoon
	local lookDirection = (closest.position - arrowPos).Unit
	arrow:SetPrimaryPartCFrame(CFrame.lookAt(arrowPos, arrowPos + lookDirection))
	
	-- Position arrow head parts properly
	local body = arrow:FindFirstChild("Body")
	local head1 = arrow:FindFirstChild("Head1")
	local head2 = arrow:FindFirstChild("Head2") 
	local head3 = arrow:FindFirstChild("Head3")
	
	if body and head1 and head2 and head3 then
		local bodyCF = body.CFrame
		
		-- Position main head wedge at end of body
		head1.CFrame = bodyCF * CFrame.new(2 * ARROW_SCALE, 0, 0) * CFrame.Angles(0, math.rad(-90), 0)
		
		-- Position side wedges
		head2.CFrame = bodyCF * CFrame.new(2 * ARROW_SCALE, 0.5 * ARROW_SCALE, 0) * CFrame.Angles(0, math.rad(-90), math.rad(45))
		head3.CFrame = bodyCF * CFrame.new(2 * ARROW_SCALE, -0.5 * ARROW_SCALE, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-45))
		
		-- Update core position
		local core = arrow:FindFirstChild("Core")
		if core then
			core.CFrame = bodyCF
			
			-- Pulse effect
			local pulse = math.sin(tick() * 3) * 0.1 + 0.9
			core.Transparency = 0.3 + (0.2 * pulse)
			
			local light = core:FindFirstChildOfClass("PointLight")
			if light then
				light.Brightness = 2 * pulse
			end
		end
	end
	
	-- Update distance text
	local billboard = arrow:FindFirstDescendant("DistanceText")
	if billboard then
		billboard.Text = string.format("%dm", math.floor(closestDist))
		
		-- Color based on distance
		if closestDist < 50 then
			billboard.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green when close
		elseif closestDist < 100 then
			billboard.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow
		else
			billboard.TextColor3 = Color3.fromRGB(255, 255, 255) -- White when far
		end
	end
	
	-- Floating animation
	local floatOffset = math.sin(tick() * 2) * 0.5
	arrow:SetPrimaryPartCFrame(arrow.PrimaryPart.CFrame + Vector3.new(0, floatOffset * 0.1, 0))
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if playerArrows[player] then
		playerArrows[player]:Destroy()
		playerArrows[player] = nil
	end
	playerOwnsTycoon[player] = nil
end)

-- Small indicator at tycoon (very subtle)
local tycoonMarkers = {}

local function updateTycoonMarkers()
	-- Clean old markers
	for tycoon, marker in pairs(tycoonMarkers) do
		local owner = tycoon:FindFirstChild("Owner")
		if not owner or owner.Value ~= nil then
			marker:Destroy()
			tycoonMarkers[tycoon] = nil
		end
	end
	
	-- Add new markers
	local unclaimed = getUnclaimedTycoons()
	for _, data in ipairs(unclaimed) do
		if not tycoonMarkers[data.tycoon] then
			-- Just a small glowing ring
			local ring = Instance.new("Part")
			ring.Name = "TycoonMarker"
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.5, 8, 8)
			ring.Material = Enum.Material.ForceField
			ring.Color = ARROW_COLOR
			ring.Transparency = 0.7
			ring.Anchored = true
			ring.CanCollide = false
			ring.CFrame = CFrame.new(data.position) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent = workspace
			
			tycoonMarkers[data.tycoon] = ring
			
			-- Gentle spin
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
		if not playerOwnsTycoon[player] then
			updatePlayerArrow(player)
		end
	end
end)

-- Update tycoon markers periodically
task.spawn(function()
	while true do
		updateTycoonMarkers()
		task.wait(2)
	end
end)

print("✅ Professional Tycoon Arrow Guide v4 loaded!")
print("📍 Arrows point TO unclaimed tycoons")
print("🎯 Automatically removes when you claim a tycoon")
print("✨ Clean, small, professional design")