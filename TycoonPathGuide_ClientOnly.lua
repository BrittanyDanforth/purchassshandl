--[[
	CLIENT-ONLY Tycoon Path Guide System
	- Place in StarterPlayer > StarterPlayerScripts as a LocalScript
	- Path only visible to the local player
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
if not player then
	player = Players.PlayerAdded:Wait()
end

-- Configuration
local PATH_COLOR = Color3.fromRGB(255, 179, 212) -- Using the Light Pink from before
local GLOW_COLOR = Color3.fromRGB(255, 204, 229) -- Using the Lighter Pink Glow
local SEGMENT_SIZE = Vector3.new(2, 0.1, 1) -- Flat rectangular segments
local SEGMENT_SPACING = 3 -- Distance between segments
local MAX_SEGMENTS = 25 -- Maximum path segments
local MIN_DISTANCE = 15 -- Hide path when this close
local MAX_DISTANCE = 200 -- Maximum draw distance
local GROUND_OFFSET = 0.05 -- Slight lift above ground to prevent z-fighting

-- Animation settings
local PULSE_SPEED = 2
local FLOW_SPEED = 3 -- Speed of light flowing along path
local FADE_TIME = 0.3

-- Smooth movement
local POSITION_SMOOTHING = 0.15 -- Lower = smoother

-- Raycast setup
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

-- Track path model
local pathModel = nil
local camera = workspace.CurrentCamera

-- Create a single path segment
local function createSegment()
	local segment = Instance.new("Part")
	segment.Name = "PathSegment"
	segment.Size = SEGMENT_SIZE
	segment.Material = Enum.Material.Neon
	segment.Color = PATH_COLOR
	segment.Anchored = true
	segment.CanCollide = false
	segment.CanQuery = false
	segment.CanTouch = false
	segment.CastShadow = false

	segment.Transparency = 1
	segment.LocalTransparencyModifier = -1

	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 0.5
	pointLight.Color = GLOW_COLOR
	pointLight.Range = 8
	pointLight.Enabled = false
	pointLight.Parent = segment

	local selection = Instance.new("SelectionBox")
	selection.Adornee = segment
	selection.Color3 = GLOW_COLOR
	selection.LineThickness = 0.05
	selection.Transparency = 0.4
	selection.Parent = segment

	return segment
end

-- Get ground position at a point
local function getGroundPosition(position, ignoreList)
	raycastParams.FilterDescendantsInstances = ignoreList
	local rayOrigin = position + Vector3.new(0, 10, 0)
	local rayDirection = Vector3.new(0, -50, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if rayResult then
		return rayResult.Position + Vector3.new(0, GROUND_OFFSET, 0), rayResult.Normal
	end
	return position, Vector3.new(0, 1, 0)
end

-- Cache for tycoon gates
local cachedGates = {}
local lastGateUpdate = 0
local GATE_UPDATE_INTERVAL = 2

-- Find all tycoon gates with caching
local function findTycoonGates()
	local now = tick()
	if now - lastGateUpdate < GATE_UPDATE_INTERVAL and #cachedGates > 0 then
		return cachedGates
	end

	lastGateUpdate = now
	cachedGates = {}

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and (obj.Name == "Touch to claim!" or obj.Name:lower():find("gate")) then
			local touchPart = obj:FindFirstChild("Head")
			if touchPart and obj.Parent and obj.Parent.Parent then
				local tycoon = obj.Parent.Parent
				local owner = tycoon:FindFirstChild("Owner")
				if owner and owner:IsA("ObjectValue") then
					table.insert(cachedGates, {
						owner = owner,
						position = touchPart.Position
					})
				end
			end
		end
	end
	return cachedGates
end

-- Update path for local player only
local function updatePath()
	local character = player.Character
	if not character then
		if pathModel then
			pathModel:Destroy()
			pathModel = nil
		end
		return
	end

	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return end

	local gates = findTycoonGates()
	local ownsATycoon = false
	local nearestGate = nil
	local nearestDistance = math.huge

	for _, gateData in pairs(gates) do
		if gateData.owner.Value == player then
			ownsATycoon = true
			break
		elseif not gateData.owner.Value then
			local distance = (gateData.position - humanoidRoot.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestGate = gateData
			end
		end
	end

	if ownsATycoon or not nearestGate then
		if pathModel then
			for _, segment in pairs(pathModel:GetChildren()) do
				if segment:IsA("Part") then
					TweenService:Create(segment, TweenInfo.new(FADE_TIME), {
						Transparency = 1
					}):Play()
				end
			end
			Debris:AddItem(pathModel, FADE_TIME)
			pathModel = nil
		end
		return
	end

	if nearestDistance < MIN_DISTANCE or nearestDistance > MAX_DISTANCE then
		if pathModel then
			for _, segment in pairs(pathModel:GetChildren()) do
				if segment:IsA("Part") then
					segment.Transparency = 1
					local light = segment:FindFirstChild("PointLight")
					if light then light.Enabled = false end
				end
			end
		end
		return
	end

	if not pathModel or not pathModel.Parent then
		pathModel = Instance.new("Model")
		pathModel.Name = "LocalTycoonPath"
		pathModel.Parent = workspace
	end

	local startPos = humanoidRoot.Position
	local endPos = nearestGate.position
	local direction = (endPos - startPos).Unit
	local distance = math.min(nearestDistance, MAX_DISTANCE)
	local segmentCount = math.min(math.floor(distance / SEGMENT_SPACING), MAX_SEGMENTS)
	local ignoreList = {character, pathModel}

	-- Store segment positions to check for bunching
	local segmentPositions = {}

	for i = 1, segmentCount do
		local segment = pathModel:FindFirstChild("Segment" .. i)
		if not segment then
			segment = createSegment()
			segment.Name = "Segment" .. i
			segment.Parent = pathModel
		end

		local t = i / (segmentCount + 1)
		local pathPos = startPos + direction * (distance * t)

		local groundPos, groundNormal = getGroundPosition(pathPos, ignoreList)

		local lookDirection = direction
		local rightVector = lookDirection:Cross(groundNormal)
		if rightVector.Magnitude > 0.01 then
			rightVector = rightVector.Unit
			local upVector = rightVector:Cross(lookDirection).Unit
			local targetCFrame = CFrame.fromMatrix(groundPos, rightVector, upVector, -lookDirection)

			if segment.CFrame then
				segment.CFrame = segment.CFrame:Lerp(targetCFrame, POSITION_SMOOTHING)
			else
				segment.CFrame = targetCFrame
			end
		else
			segment.CFrame = CFrame.lookAt(groundPos, groundPos + direction)
		end

		-- Store the actual position after lerping
		segmentPositions[i] = segment.Position

		local scale = 1 - (t * 0.3)
		segment.Size = SEGMENT_SIZE * scale
		segment.Transparency = 1
		segment.LocalTransparencyModifier = -1
		
		-- FADE SEGMENTS THAT ARE TOO CLOSE TOGETHER
		local fadeFactor = 0
		if i > 1 then
			local prevPos = segmentPositions[i-1]
			local currentPos = segmentPositions[i]
			local spacing = (currentPos - prevPos).Magnitude
			
			-- If segments are closer than 60% of normal spacing, start fading
			if spacing < SEGMENT_SPACING * 0.6 then
				fadeFactor = 1 - (spacing / (SEGMENT_SPACING * 0.6))
				fadeFactor = math.clamp(fadeFactor, 0, 0.8) -- Max 80% fade
			end
		end
		
		-- Apply fade to LocalTransparencyModifier
		segment:SetAttribute("FadeFactor", fadeFactor)
		
		-- ACTUALLY HIDE SEGMENTS THAT ARE TOO BUNCHED
		if fadeFactor > 0.5 then
			segment.LocalTransparencyModifier = 0 -- Make invisible when too bunched
			local light = segment:FindFirstChild("PointLight")
			if light then
				light.Enabled = false
			end
		else
			segment.LocalTransparencyModifier = -1 -- Visible when properly spaced
			local light = segment:FindFirstChild("PointLight")
			if light then
				light.Enabled = true
				light.Range = 8 * scale
			end
		end
	end

	for i = segmentCount + 1, MAX_SEGMENTS do
		local segment = pathModel:FindFirstChild("Segment" .. i)
		if segment then
			segment.Transparency = 1
			local light = segment:FindFirstChild("PointLight")
			if light then light.Enabled = false end
		end
	end
end

local animTime = 0
local lastPathUpdate = 0
local PATH_UPDATE_RATE = 1/30

RunService.RenderStepped:Connect(function(deltaTime)
	animTime = animTime + deltaTime
	local now = tick()
	if now - lastPathUpdate >= PATH_UPDATE_RATE then
		lastPathUpdate = now
		updatePath()
	end

	if pathModel and pathModel.Parent then
		for i, segment in pairs(pathModel:GetChildren()) do
			if segment:IsA("Part") then
				local segNum = tonumber(segment.Name:match("Segment(%d+)")) or 1
				local pulse = math.sin(animTime * PULSE_SPEED + segNum * 0.2) * 0.5 + 0.5

				-- Get fade factor for bunched segments
				local fadeFactor = segment:GetAttribute("FadeFactor") or 0

				local light = segment:FindFirstChild("PointLight")
				if light then
					light.Brightness = (0.3 + pulse * 0.7) * (1 - fadeFactor)
				end

				-- Makes the glowing outline much more solid and visible, but fade when bunched
				local selection = segment:FindFirstChild("SelectionBox")
				if selection then
					selection.Transparency = (0.1 + pulse * 0.1) + (fadeFactor * 0.7)
				end

				local flow = (animTime * FLOW_SPEED + segNum) % 10
				if flow < 1 then
					segment.Color = GLOW_COLOR:Lerp(PATH_COLOR, flow)
				else
					segment.Color = PATH_COLOR
				end

				-- This is the transparency wave for the main part, which we can keep subtle
				local wave = math.sin(animTime * FLOW_SPEED - segNum * 0.5) * 0.05
				
				-- Don't try to fade LocalTransparencyModifier - it's already handled in updatePath
				-- Just apply the wave effect if segment is visible
				if segment.LocalTransparencyModifier == -1 then
					segment.LocalTransparencyModifier = -1 + wave
				end
			end
		end
	end
end)

player.CharacterRemoving:Connect(function()
	if pathModel then
		pathModel:Destroy()
		pathModel = nil
	end
end)

if camera then
	camera:GetPropertyChangedSignal("Parent"):Connect(function()
		if camera.Parent == nil and pathModel then
			pathModel:Destroy()
			pathModel = nil
		end
	end)
end

print("✅ CLIENT-ONLY Tycoon Path Guide loaded (Anti-Bunching Fade Applied)!")