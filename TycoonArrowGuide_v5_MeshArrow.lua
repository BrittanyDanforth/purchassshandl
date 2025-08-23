--[[
	Professional Tycoon Arrow Guide v5 - MESH ARROW
	- Uses actual arrow mesh (rbxassetid://3684866704)
	- Clean, single-part design
	- Properly tracks ownership
	- Smooth animations
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local ARROW_MESH_ID = "rbxassetid://3684866704" -- Your arrow mesh
local ARROW_COLOR = Color3.fromRGB(100, 255, 170) -- Mint green
local ARROW_SIZE = Vector3.new(3, 3, 3) -- Adjust based on mesh scale
local COMPASS_DISTANCE = 20 -- Distance from player
local COMPASS_HEIGHT = 8 -- Height above ground
local MIN_DISTANCE = 25 -- Don't show if closer than this
local PULSE_SPEED = 2.5
local FLOAT_SPEED = 2
local FLOAT_AMOUNT = 1

-- Track player arrows and ownership
local playerArrows = {}
local playerOwnsTycoon = {}

-- Create arrow using mesh
local function createArrowModel()
	local model = Instance.new("Model")
	model.Name = "TycoonGuideArrow"
	
	-- Single MeshPart arrow
	local arrow = Instance.new("MeshPart")
	arrow.Name = "Arrow"
	arrow.MeshId = ARROW_MESH_ID
	arrow.Size = ARROW_SIZE
	arrow.Material = Enum.Material.Neon
	arrow.Color = ARROW_COLOR
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CastShadow = false
	arrow.Parent = model
	
	-- Glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 2
	pointLight.Color = ARROW_COLOR
	pointLight.Range = 12
	pointLight.Shadows = false
	pointLight.Parent = arrow
	
	-- Surface light for extra glow
	local surfaceLight = Instance.new("SurfaceLight")
	surfaceLight.Brightness = 1
	surfaceLight.Color = ARROW_COLOR
	surfaceLight.Face = Enum.NormalId.Front
	surfaceLight.Range = 8
	surfaceLight.Parent = arrow
	
	-- Distance display
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, -3, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = arrow
	
	-- Background frame
	local bgFrame = Instance.new("Frame")
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.5
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboard
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = bgFrame
	
	-- Distance text
	local distText = Instance.new("TextLabel")
	distText.Name = "DistanceText"
	distText.Size = UDim2.new(1, -10, 1, 0)
	distText.Position = UDim2.new(0, 5, 0, 0)
	distText.BackgroundTransparency = 1
	distText.Text = "0m"
	distText.TextColor3 = Color3.new(1, 1, 1)
	distText.TextStrokeTransparency = 0.5
	distText.TextStrokeColor3 = Color3.new(0, 0, 0)
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
				
				-- Find gate position
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

-- Check if player owns any tycoon
local function playerOwnsTycoon(player)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Owner" and obj:IsA("ObjectValue") and obj.Value == player then
			return true
		end
	end
	return false
end

-- Animate arrow
local function animateArrow(arrow, startTime)
	local arrowPart = arrow.PrimaryPart
	if not arrowPart then return end
	
	local elapsed = tick() - startTime
	
	-- Pulse glow
	local pulse = math.sin(elapsed * PULSE_SPEED) * 0.3 + 0.7
	local light = arrowPart:FindFirstChildOfClass("PointLight")
	if light then
		light.Brightness = 2 * pulse
		light.Range = 12 + (3 * pulse)
	end
	
	-- Subtle transparency pulse
	arrowPart.Transparency = 0.1 * (1 - pulse)
	
	-- Floating motion
	local floatY = math.sin(elapsed * FLOAT_SPEED) * FLOAT_AMOUNT
	return floatY
end

-- Update arrow for specific player
local function updatePlayerArrow(player)
	local character = player.Character
	if not character then return end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return end
	
	-- Check ownership
	if playerOwnsTycoon(player) then
		if playerArrows[player] then
			playerArrows[player].model:Destroy()
			playerArrows[player] = nil
		end
		return
	end
	
	-- Get unclaimed tycoons
	local unclaimed = getUnclaimedTycoons()
	if #unclaimed == 0 then
		if playerArrows[player] then
			playerArrows[player].model:Destroy()
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
			-- Fade out when close
			local arrow = playerArrows[player].model.PrimaryPart
			TweenService:Create(arrow, TweenInfo.new(0.3), {
				Transparency = 1
			}):Play()
		end
		return
	end
	
	-- Create or get arrow
	local arrowData = playerArrows[player]
	if not arrowData then
		local model = createArrowModel()
		model.Parent = workspace
		arrowData = {
			model = model,
			startTime = tick()
		}
		playerArrows[player] = arrowData
	else
		-- Fade back in if was hidden
		local arrow = arrowData.model.PrimaryPart
		if arrow.Transparency > 0.5 then
			TweenService:Create(arrow, TweenInfo.new(0.3), {
				Transparency = 0
			}):Play()
		end
	end
	
	-- Position arrow
	local playerPos = humanoidRoot.Position
	local direction = (closest.position - Vector3.new(playerPos.X, closest.position.Y, playerPos.Z)).Unit
	local basePos = playerPos + direction * COMPASS_DISTANCE + Vector3.new(0, COMPASS_HEIGHT, 0)
	
	-- Add floating animation
	local floatOffset = animateArrow(arrowData.model, arrowData.startTime)
	local arrowPos = basePos + Vector3.new(0, floatOffset, 0)
	
	-- Point arrow toward tycoon
	local lookDirection = (closest.position - arrowPos).Unit
	arrowData.model:SetPrimaryPartCFrame(
		CFrame.lookAt(arrowPos, arrowPos + lookDirection) * CFrame.Angles(0, math.rad(90), 0)
	)
	
	-- Update distance display
	local distText = arrowData.model:FindFirstDescendant("DistanceText")
	if distText then
		local displayDist = math.floor(closestDist)
		distText.Text = displayDist .. "m to Tycoon"
		
		-- Color coding
		if closestDist < 50 then
			distText.TextColor3 = Color3.fromRGB(150, 255, 150) -- Light green
		elseif closestDist < 100 then
			distText.TextColor3 = Color3.fromRGB(255, 255, 150) -- Light yellow  
		else
			distText.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
		end
	end
end

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	if playerArrows[player] then
		playerArrows[player].model:Destroy()
		playerArrows[player] = nil
	end
end)

-- Subtle tycoon markers
local tycoonMarkers = {}

local function createTycoonMarker(position)
	-- Simple glowing circle on ground
	local marker = Instance.new("Part")
	marker.Name = "TycoonLocationMarker"
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(0.5, 10, 10)
	marker.Material = Enum.Material.ForceField
	marker.Color = ARROW_COLOR
	marker.Transparency = 0.8
	marker.Anchored = true
	marker.CanCollide = false
	marker.CFrame = CFrame.new(position - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	
	-- Spinning animation
	local spin = Instance.new("BodyAngularVelocity")
	spin.AngularVelocity = Vector3.new(0, 2, 0)
	spin.MaxTorque = Vector3.new(0, math.huge, 0)
	spin.Parent = marker
	
	return marker
end

local function updateTycoonMarkers()
	-- Remove claimed tycoon markers
	for tycoon, marker in pairs(tycoonMarkers) do
		local owner = tycoon:FindFirstChild("Owner")
		if not owner or owner.Value ~= nil then
			marker:Destroy()
			tycoonMarkers[tycoon] = nil
		end
	end
	
	-- Add markers for unclaimed
	local unclaimed = getUnclaimedTycoons()
	for _, data in ipairs(unclaimed) do
		if not tycoonMarkers[data.tycoon] then
			local marker = createTycoonMarker(data.position)
			marker.Parent = workspace
			tycoonMarkers[data.tycoon] = marker
		end
	end
end

-- Main update loop
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerArrow(player)
	end
end)

-- Tycoon marker updates
task.spawn(function()
	while true do
		updateTycoonMarkers()
		task.wait(3)
	end
end)

print("✅ Tycoon Arrow Guide v5 - MESH ARROW loaded!")
print("🏹 Using proper arrow mesh: " .. ARROW_MESH_ID)
print("📍 Smart directional guidance")
print("✨ Clean, professional design")