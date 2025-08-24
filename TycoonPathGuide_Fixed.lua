--[[
	CLIENT-ONLY TYCOON PATH GUIDE [v3.1 - RESPONSIVE]
	- Fixed: Path now updates instantly with player movement
	- Fixed: Path extends much closer to the gate
	- Place in StarterPlayer > StarterPlayerScripts as a LocalScript
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local camera = workspace.CurrentCamera

--============================================================================--
--                              CONFIGURATION
--============================================================================--
local Config = {
	-- Visual Appearance
	Colors = {
		PATH = Color3.fromRGB(255, 179, 212),      -- Light Pink
		GLOW = Color3.fromRGB(255, 204, 229),      -- Lighter Pink Glow
		PULSE = Color3.fromRGB(255, 230, 240),     -- Ultra Light Pink for flow
	},
	
	-- Path Geometry
	SEGMENT_SIZE = Vector3.new(2, 0.1, 1),         -- Base size of segments
	SEGMENT_SPACING = 2.5,                         -- Reduced for better coverage
	MAX_SEGMENTS = 40,                             -- Increased for longer paths
	GROUND_OFFSET = 0.05,                          -- Height above ground
	SCALE_REDUCTION = 0.2,                         -- Less taper for visibility
	PATH_ARC_HEIGHT = 0.08,                        -- Slightly lower arc
	
	-- Distance Settings (FIXED)
	MIN_DISTANCE = 5,                              -- Much closer before hiding
	MAX_DISTANCE = 300,                            -- Increased max distance
	PATH_END_OFFSET = 3,                           -- Stop path this far from gate
	
	-- Animation Parameters
	PULSE_SPEED = 2,                               -- Glow pulse frequency
	FLOW_SPEED = 3,                                -- Color flow speed
	FADE_IN_TIME = 0.2,                            -- Faster fade in
	FADE_OUT_TIME = 0.2,                           -- Faster fade out
	
	-- Smoothing & Performance (FIXED)
	POSITION_SMOOTHING = 0.3,                      -- Faster segment updates
	TARGET_SMOOTHING = 0.25,                       -- Much more responsive
	TRANSPARENCY_SMOOTHING = 0.15,                 -- Faster transparency
	GATE_UPDATE_INTERVAL = 1,                      -- More frequent scans
	PATH_UPDATE_RATE = 1/30,                       -- 30Hz updates
	
	-- Anti-bunching
	BUNCHING_THRESHOLD = 0.6,                      -- Min spacing ratio
	MAX_BUNCH_FADE = 0.7,                          -- Less aggressive fade
	
	-- Light Settings
	LIGHT_BASE_BRIGHTNESS = 0.4,                   -- Brighter base
	LIGHT_PULSE_BRIGHTNESS = 0.6,                  -- Less pulse variation
	LIGHT_BASE_RANGE = 10,                         -- Larger range
	GLOW_BASE_TRANSPARENCY = 0.2,                  -- More visible glow
	GLOW_PULSE_AMOUNT = 0.15,                      -- Subtle pulse
}

--============================================================================--
--                              STATE MANAGEMENT
--============================================================================--
local PathState = {
	active = false,
	currentTargetGate = nil,
	smoothedStartPos = nil,
	smoothedEndPos = nil,
	pathModel = nil,
	segments = {},
	cachedGates = {},
	lastGateUpdate = 0,
	lastPathUpdate = 0,
	animationTime = 0,
}

-- Raycast parameters
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

--============================================================================--
--                            UTILITY FUNCTIONS
--============================================================================--

-- Quadratic Bezier curve interpolation
local function quadraticBezier(t, p0, p1, p2)
	local u = 1 - t
	return u * u * p0 + 2 * u * t * p1 + t * t * p2
end

-- Get ground position with raycast
local function getGroundPosition(position, ignoreList)
	raycastParams.FilterDescendantsInstances = ignoreList
	local rayOrigin = position + Vector3.new(0, 20, 0)
	local rayDirection = Vector3.new(0, -100, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if rayResult then
		return rayResult.Position + Vector3.new(0, Config.GROUND_OFFSET, 0), rayResult.Normal
	end
	return position, Vector3.new(0, 1, 0)
end

--============================================================================--
--                            SEGMENT CREATION
--============================================================================--

local function createSegment(index)
	local segment = Instance.new("Part")
	segment.Name = "PathSegment" .. index
	segment.Size = Config.SEGMENT_SIZE
	segment.Material = Enum.Material.Neon
	segment.Color = Config.Colors.PATH
	segment.Anchored = true
	segment.CanCollide = false
	segment.CanQuery = false
	segment.CanTouch = false
	segment.CastShadow = false
	segment.Transparency = 1
	
	-- Point light for glow
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 0
	pointLight.Color = Config.Colors.GLOW
	pointLight.Range = Config.LIGHT_BASE_RANGE
	pointLight.Parent = segment
	
	-- Selection box for outline glow
	local selection = Instance.new("SelectionBox")
	selection.Adornee = segment
	selection.Color3 = Config.Colors.GLOW
	selection.LineThickness = 0.05
	selection.Transparency = 1
	selection.Parent = segment
	
	-- Attributes for smooth animation
	segment:SetAttribute("TargetTransparency", 1)
	segment:SetAttribute("FadeFactor", 0)
	segment:SetAttribute("SegmentIndex", index)
	
	-- Store in state
	PathState.segments[index] = {
		part = segment,
		light = pointLight,
		selection = selection,
		currentTransparency = 1,
		targetTransparency = 1,
	}
	
	return segment
end

--============================================================================--
--                          TYCOON GATE DETECTION
--============================================================================--

local function findTycoonGates()
	local now = tick()
	
	-- Use cache if recent
	if now - PathState.lastGateUpdate < Config.GATE_UPDATE_INTERVAL * 0.5 and #PathState.cachedGates > 0 then
		return PathState.cachedGates
	end
	
	PathState.lastGateUpdate = now
	PathState.cachedGates = {}
	
	-- Search for tycoon gates
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local name = obj.Name:lower()
			if name == "touch to claim!" or name:find("gate") or name:find("claim") then
				local touchPart = obj:FindFirstChild("Head") or obj:FindFirstChildWhichIsA("BasePart")
				
				if touchPart then
					-- Find the tycoon owner value
					local parent = obj.Parent
					while parent and parent ~= workspace do
						local owner = parent:FindFirstChild("Owner")
						if owner and owner:IsA("ObjectValue") then
							table.insert(PathState.cachedGates, {
								owner = owner,
								position = touchPart.Position,
								part = touchPart,
							})
							break
						end
						parent = parent.Parent
					end
				end
			end
		end
	end
	
	return PathState.cachedGates
end

local function findNearestUnclaimedGate()
	local character = player.Character
	if not character then return nil, false end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return nil, false end
	
	local gates = findTycoonGates()
	local nearestGate = nil
	local nearestDistance = math.huge
	
	for _, gateData in pairs(gates) do
		if gateData.owner.Value == player then
			return nil, true -- Player owns a tycoon
		elseif not gateData.owner.Value then
			local distance = (gateData.position - humanoidRoot.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestGate = gateData
			end
		end
	end
	
	return nearestGate, false
end

--============================================================================--
--                            PATH MANAGEMENT
--============================================================================--

local function hidePath()
	if not PathState.active then return end
	PathState.active = false
	
	-- Fade out all segments
	for _, segmentData in pairs(PathState.segments) do
		if segmentData.part then
			segmentData.targetTransparency = 1
			segmentData.part:SetAttribute("TargetTransparency", 1)
		end
	end
	
	-- Schedule cleanup after fade
	if PathState.pathModel then
		task.wait(Config.FADE_OUT_TIME)
		if PathState.pathModel then
			PathState.pathModel:Destroy()
			PathState.pathModel = nil
		end
	end
end

local function updatePath()
	local character = player.Character
	if not character then
		hidePath()
		return
	end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot or not PathState.currentTargetGate then
		hidePath()
		return
	end
	
	-- Use actual positions for more responsive feel
	local startPos = humanoidRoot.Position
	local endPos = PathState.currentTargetGate.position
	
	-- Calculate adjusted end position (stop before the gate)
	local direction = (endPos - startPos).Unit
	local distance = (endPos - startPos).Magnitude
	
	-- Adjust end position to stop PATH_END_OFFSET studs before the gate
	if distance > Config.PATH_END_OFFSET then
		endPos = endPos - (direction * Config.PATH_END_OFFSET)
		distance = distance - Config.PATH_END_OFFSET
	end
	
	-- Check distance constraints
	if distance < Config.MIN_DISTANCE or distance > Config.MAX_DISTANCE then
		hidePath()
		return
	end
	
	-- Initialize smoothed positions if needed
	if not PathState.smoothedStartPos then
		PathState.smoothedStartPos = startPos
	end
	if not PathState.smoothedEndPos then
		PathState.smoothedEndPos = endPos
	end
	
	-- Update smoothed positions (more responsive)
	PathState.smoothedStartPos = PathState.smoothedStartPos:Lerp(startPos, Config.TARGET_SMOOTHING)
	PathState.smoothedEndPos = PathState.smoothedEndPos:Lerp(endPos, Config.TARGET_SMOOTHING)
	
	-- Use smoothed positions for path
	local smoothStart = PathState.smoothedStartPos
	local smoothEnd = PathState.smoothedEndPos
	local smoothDistance = (smoothEnd - smoothStart).Magnitude
	
	-- Create path model if needed
	if not PathState.pathModel or not PathState.pathModel.Parent then
		PathState.pathModel = Instance.new("Model")
		PathState.pathModel.Name = "LocalTycoonPath"
		PathState.pathModel.Parent = workspace
		PathState.segments = {} -- Reset segments table
	end
	
	-- Calculate bezier curve control point for arc
	local controlPoint = (smoothStart + smoothEnd) / 2 + Vector3.new(0, smoothDistance * Config.PATH_ARC_HEIGHT, 0)
	
	local segmentCount = math.min(math.floor(smoothDistance / Config.SEGMENT_SPACING), Config.MAX_SEGMENTS)
	local ignoreList = {character, PathState.pathModel}
	local segmentPositions = {}
	
	-- Update each segment
	for i = 1, segmentCount do
		local segmentData = PathState.segments[i]
		local segment
		
		-- Get or create segment
		if not segmentData or not segmentData.part or not segmentData.part.Parent then
			segment = createSegment(i)
			segment.Parent = PathState.pathModel
			segmentData = PathState.segments[i]
		else
			segment = segmentData.part
		end
		
		-- Calculate position on bezier curve
		local t = i / (segmentCount + 1)
		local pathPos = quadraticBezier(t, smoothStart, controlPoint, smoothEnd)
		
		-- Get ground position
		local groundPos, groundNormal = getGroundPosition(pathPos, ignoreList)
		segmentPositions[i] = groundPos
		
		-- Calculate direction
		local nextT = math.min(t + 0.01, 1)
		local nextPathPos = quadraticBezier(nextT, smoothStart, controlPoint, smoothEnd)
		local lookDirection = (nextPathPos - pathPos).Unit
		
		-- Orient segment
		local rightVector = lookDirection:Cross(groundNormal)
		if rightVector.Magnitude > 0.01 then
			rightVector = rightVector.Unit
			local upVector = rightVector:Cross(lookDirection).Unit
			local targetCFrame = CFrame.fromMatrix(groundPos, rightVector, upVector, -lookDirection)
			
			-- Faster position update for responsiveness
			segment.CFrame = segment.CFrame:Lerp(targetCFrame, Config.POSITION_SMOOTHING)
		end
		
		-- Scale taper
		local scale = 1 - (t * Config.SCALE_REDUCTION)
		segment.Size = Config.SEGMENT_SIZE * scale
		
		-- Anti-bunching calculation
		local fadeFactor = 0
		if i > 1 and segmentPositions[i-1] then
			local spacing = (segmentPositions[i] - segmentPositions[i-1]).Magnitude
			local minSpacing = Config.SEGMENT_SPACING * Config.BUNCHING_THRESHOLD
			if spacing < minSpacing then
				fadeFactor = math.clamp(1 - (spacing / minSpacing), 0, Config.MAX_BUNCH_FADE)
			end
		end
		
		-- Set attributes
		segment:SetAttribute("FadeFactor", fadeFactor)
		segment:SetAttribute("TargetTransparency", 0) -- Always visible unless bunched heavily
		segment:SetAttribute("Scale", scale)
		
		-- Update segment data
		segmentData.targetTransparency = fadeFactor > 0.7 and 1 or 0
	end
	
	-- Hide unused segments
	for i = segmentCount + 1, Config.MAX_SEGMENTS do
		local segmentData = PathState.segments[i]
		if segmentData and segmentData.part then
			segmentData.targetTransparency = 1
			segmentData.part:SetAttribute("TargetTransparency", 1)
		end
	end
end

--============================================================================--
--                          ANIMATION SYSTEM
--============================================================================--

local function animateSegments(deltaTime)
	if not PathState.pathModel or not PathState.pathModel.Parent then return end
	
	PathState.animationTime = PathState.animationTime + deltaTime
	
	for index, segmentData in pairs(PathState.segments) do
		if segmentData and segmentData.part and segmentData.part.Parent then
			local segment = segmentData.part
			local segmentIndex = segment:GetAttribute("SegmentIndex") or index
			
			-- Get animation parameters
			local targetTrans = segment:GetAttribute("TargetTransparency") or 1
			local fadeFactor = segment:GetAttribute("FadeFactor") or 0
			local scale = segment:GetAttribute("Scale") or 1
			
			-- Calculate final target transparency
			local finalTargetTrans = math.max(targetTrans, fadeFactor * 0.8) -- Less aggressive fade
			
			-- Smooth transparency update
			segmentData.currentTransparency = segmentData.currentTransparency + 
				(finalTargetTrans - segmentData.currentTransparency) * Config.TRANSPARENCY_SMOOTHING
			
			segment.Transparency = segmentData.currentTransparency
			
			-- Determine visibility
			local isVisible = segmentData.currentTransparency < 0.9
			
			if isVisible then
				-- Pulse animation
				local pulse = math.sin(PathState.animationTime * Config.PULSE_SPEED + segmentIndex * 0.2) * 0.5 + 0.5
				
				-- Light animation
				if segmentData.light then
					local brightness = Config.LIGHT_BASE_BRIGHTNESS + (pulse * Config.LIGHT_PULSE_BRIGHTNESS)
					segmentData.light.Brightness = brightness * (1 - segmentData.currentTransparency)
					segmentData.light.Range = Config.LIGHT_BASE_RANGE * scale
				end
				
				-- Selection box animation
				if segmentData.selection then
					local glowTrans = Config.GLOW_BASE_TRANSPARENCY + (pulse * Config.GLOW_PULSE_AMOUNT)
					segmentData.selection.Transparency = glowTrans + (segmentData.currentTransparency * 0.5)
				end
				
				-- Color flow effect
				local flow = (PathState.animationTime * Config.FLOW_SPEED + segmentIndex) % 10
				if flow < 1 then
					segment.Color = Config.Colors.GLOW:Lerp(Config.Colors.PULSE, flow)
				else
					segment.Color = Config.Colors.PATH
				end
			else
				-- Hide effects when invisible
				if segmentData.light then
					segmentData.light.Brightness = 0
				end
				if segmentData.selection then
					segmentData.selection.Transparency = 1
				end
			end
		end
	end
end

--============================================================================--
--                            MAIN UPDATE LOOP
--============================================================================--

RunService.RenderStepped:Connect(function(deltaTime)
	-- Always update path every frame for responsiveness
	updatePath()
	
	-- Always animate
	animateSegments(deltaTime)
end)

-- Gate scanning loop (separate)
task.spawn(function()
	while true do
		task.wait(Config.GATE_UPDATE_INTERVAL)
		
		local targetGate, ownsTycoon = findNearestUnclaimedGate()
		
		if ownsTycoon or not targetGate then
			PathState.currentTargetGate = nil
			hidePath()
		else
			if not PathState.active then
				-- Reset smoothed positions for instant response
				PathState.smoothedStartPos = nil
				PathState.smoothedEndPos = nil
			end
			PathState.active = true
			PathState.currentTargetGate = targetGate
		end
	end
end)

--============================================================================--
--                            CLEANUP HANDLERS
--============================================================================--

player.CharacterRemoving:Connect(function()
	if PathState.pathModel then
		PathState.pathModel:Destroy()
		PathState.pathModel = nil
	end
	PathState = {
		active = false,
		currentTargetGate = nil,
		smoothedStartPos = nil,
		smoothedEndPos = nil,
		pathModel = nil,
		segments = {},
		cachedGates = {},
		lastGateUpdate = 0,
		lastPathUpdate = 0,
		animationTime = 0,
	}
end)

--============================================================================--
--                            INITIALIZATION
--============================================================================--

print("✅ Tycoon Path Guide v3.1 - Fast & Responsive!")
print("⚡ Updates every frame for instant response")
print("🎯 Path extends closer to gates")