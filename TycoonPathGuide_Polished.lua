--[[
	┌─────────────────────────────────────────────────────────────────────┐
	│              CLIENT-ONLY TYCOON PATH GUIDE [v3.0 POLISHED]          │
	├─────────────────────────────────────────────────────────────────────┤
	│ A smooth, curved path guide that helps players find unclaimed       │
	│ tycoons with beautiful animations and proper fading.                │
	│                                                                     │
	│ Installation:                                                       │
	│ - Place in StarterPlayer > StarterPlayerScripts as a LocalScript   │
	│ - Path is only visible to the local player                         │
	└─────────────────────────────────────────────────────────────────────┘
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Player references
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
	SEGMENT_SPACING = 3,                           -- Distance between segments
	MAX_SEGMENTS = 30,                             -- Maximum segments for smooth curves
	GROUND_OFFSET = 0.05,                          -- Height above ground
	SCALE_REDUCTION = 0.3,                         -- Taper factor along path
	PATH_ARC_HEIGHT = 0.1,                         -- Arc height as % of distance
	
	-- Distance Settings
	MIN_DISTANCE = 15,                             -- Hide when closer
	MAX_DISTANCE = 200,                            -- Max draw distance
	
	-- Animation Parameters
	PULSE_SPEED = 2,                               -- Glow pulse frequency
	FLOW_SPEED = 3,                                -- Color flow speed
	FADE_IN_TIME = 0.4,                            -- Segment fade in duration
	FADE_OUT_TIME = 0.3,                           -- Path fade out duration
	
	-- Smoothing & Performance
	POSITION_SMOOTHING = 0.1,                      -- Segment position lerp (lower = smoother)
	TARGET_SMOOTHING = 0.08,                       -- Path retargeting smoothness
	TRANSPARENCY_SMOOTHING = 0.1,                  -- Transparency transition speed
	GATE_UPDATE_INTERVAL = 2,                      -- Gate scan frequency
	PATH_UPDATE_RATE = 1/20,                       -- Path recalculation rate
	
	-- Anti-bunching
	BUNCHING_THRESHOLD = 0.7,                      -- Min spacing ratio before fade
	MAX_BUNCH_FADE = 0.8,                          -- Maximum fade for bunched segments
	
	-- Light Settings
	LIGHT_BASE_BRIGHTNESS = 0.3,                   -- Minimum brightness
	LIGHT_PULSE_BRIGHTNESS = 0.7,                  -- Additional pulse brightness
	LIGHT_BASE_RANGE = 8,                          -- Base light range
	GLOW_BASE_TRANSPARENCY = 0.3,                  -- Selection box base transparency
	GLOW_PULSE_AMOUNT = 0.2,                       -- Selection box pulse variation
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

local function findNearestTycoonGate()
	local character = player.Character
	if not character then return nil, false end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return nil, false end
	
	local nearestGate = nil
	local nearestDistance = math.huge
	local ownsTycoon = false
	
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
							if owner.Value == player then
								ownsTycoon = true
								return nil, true -- Player owns a tycoon
							elseif not owner.Value then
								local distance = (touchPart.Position - humanoidRoot.Position).Magnitude
								if distance < nearestDistance then
									nearestDistance = distance
									nearestGate = touchPart
								end
							end
							break
						end
						parent = parent.Parent
					end
				end
			end
		end
	end
	
	return nearestGate, ownsTycoon
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
		Debris:AddItem(PathState.pathModel, Config.FADE_OUT_TIME + 0.5)
		PathState.pathModel = nil
	end
end

local function updateSegmentPositions()
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
	
	-- Smooth position updates
	if not PathState.smoothedStartPos then
		PathState.smoothedStartPos = humanoidRoot.Position
	end
	if not PathState.smoothedEndPos then
		PathState.smoothedEndPos = PathState.currentTargetGate.Position
	end
	
	PathState.smoothedStartPos = PathState.smoothedStartPos:Lerp(humanoidRoot.Position, Config.TARGET_SMOOTHING)
	PathState.smoothedEndPos = PathState.smoothedEndPos:Lerp(PathState.currentTargetGate.Position, Config.TARGET_SMOOTHING)
	
	local startPos = PathState.smoothedStartPos
	local endPos = PathState.smoothedEndPos
	local distance = (endPos - startPos).Magnitude
	
	-- Check distance constraints
	if distance < Config.MIN_DISTANCE or distance > Config.MAX_DISTANCE then
		hidePath()
		return
	end
	
	-- Create path model if needed
	if not PathState.pathModel or not PathState.pathModel.Parent then
		PathState.pathModel = Instance.new("Model")
		PathState.pathModel.Name = "LocalTycoonPath"
		PathState.pathModel.Parent = workspace
		PathState.segments = {} -- Reset segments table
	end
	
	-- Calculate bezier curve control point for arc
	local controlPoint = (startPos + endPos) / 2 + Vector3.new(0, distance * Config.PATH_ARC_HEIGHT, 0)
	
	local segmentCount = math.min(math.floor(distance / Config.SEGMENT_SPACING), Config.MAX_SEGMENTS)
	local ignoreList = {character, PathState.pathModel}
	local segmentPositions = {}
	
	-- Update each segment
	for i = 1, segmentCount do
		local segmentData = PathState.segments[i]
		local segment
		
		-- Get or create segment
		if not segmentData or not segmentData.part or not segmentData.part.Parent then
			segment = PathState.pathModel:FindFirstChild("PathSegment" .. i)
			if not segment then
				segment = createSegment(i)
				segment.Parent = PathState.pathModel
			else
				-- Re-register existing segment
				PathState.segments[i] = {
					part = segment,
					light = segment:FindFirstChild("PointLight"),
					selection = segment:FindFirstChild("SelectionBox"),
					currentTransparency = segment.Transparency,
					targetTransparency = segment:GetAttribute("TargetTransparency") or 1,
				}
			end
			segmentData = PathState.segments[i]
		else
			segment = segmentData.part
		end
		
		-- Calculate position on bezier curve
		local t = i / (segmentCount + 1)
		local pathPos = quadraticBezier(t, startPos, controlPoint, endPos)
		
		-- Get ground position
		local groundPos, groundNormal = getGroundPosition(pathPos, ignoreList)
		segmentPositions[i] = groundPos
		
		-- Calculate direction
		local nextT = math.min(t + 0.01, 1)
		local nextPathPos = quadraticBezier(nextT, startPos, controlPoint, endPos)
		local lookDirection = (nextPathPos - pathPos).Unit
		
		-- Orient segment
		local rightVector = lookDirection:Cross(groundNormal)
		if rightVector.Magnitude > 0.01 then
			rightVector = rightVector.Unit
			local upVector = rightVector:Cross(lookDirection).Unit
			local targetCFrame = CFrame.fromMatrix(groundPos, rightVector, upVector, -lookDirection)
			
			-- Smooth position update
			if segment.CFrame then
				segment.CFrame = segment.CFrame:Lerp(targetCFrame, Config.POSITION_SMOOTHING)
			else
				segment.CFrame = targetCFrame
			end
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
		segment:SetAttribute("TargetTransparency", fadeFactor > 0.5 and 1 or 0)
		segment:SetAttribute("Scale", scale)
		
		-- Update segment data
		segmentData.targetTransparency = segment:GetAttribute("TargetTransparency")
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
			local finalTargetTrans = math.max(targetTrans, fadeFactor)
			
			-- Smooth transparency update
			segmentData.currentTransparency = segmentData.currentTransparency + 
				(finalTargetTrans - segmentData.currentTransparency) * Config.TRANSPARENCY_SMOOTHING
			
			segment.Transparency = segmentData.currentTransparency
			
			-- Determine visibility
			local isVisible = segmentData.currentTransparency < 0.8
			
			if isVisible then
				-- Pulse animation
				local pulse = math.sin(PathState.animationTime * Config.PULSE_SPEED + segmentIndex * 0.2) * 0.5 + 0.5
				
				-- Light animation
				if segmentData.light then
					local brightness = Config.LIGHT_BASE_BRIGHTNESS + (pulse * Config.LIGHT_PULSE_BRIGHTNESS)
					segmentData.light.Brightness = brightness * (1 - fadeFactor) * (1 - segmentData.currentTransparency)
					segmentData.light.Range = Config.LIGHT_BASE_RANGE * scale
				end
				
				-- Selection box animation
				if segmentData.selection then
					local glowTrans = Config.GLOW_BASE_TRANSPARENCY + (pulse * Config.GLOW_PULSE_AMOUNT)
					segmentData.selection.Transparency = glowTrans + fadeFactor * 0.7
				end
				
				-- Color flow effect
				local flow = (PathState.animationTime * Config.FLOW_SPEED + segmentIndex) % 10
				if flow < 1 then
					-- Smooth color transition
					local flowT = flow * flow -- Quadratic easing
					segment.Color = Config.Colors.GLOW:Lerp(Config.Colors.PULSE, flowT)
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
--                            UPDATE LOOPS
--============================================================================--

-- Gate scanning loop
task.spawn(function()
	while true do
		task.wait(Config.GATE_UPDATE_INTERVAL)
		
		local targetGate, ownsTycoon = findNearestTycoonGate()
		
		if ownsTycoon or not targetGate then
			PathState.currentTargetGate = nil
			hidePath()
		else
			if not PathState.active then
				-- Initialize smooth positions
				local character = player.Character
				local humanoidRoot = character and character:FindFirstChild("HumanoidRootPart")
				if humanoidRoot then
					PathState.smoothedStartPos = humanoidRoot.Position
					PathState.smoothedEndPos = targetGate.Position
				end
			end
			PathState.active = true
			PathState.currentTargetGate = targetGate
		end
	end
end)

-- Main render loop
RunService.RenderStepped:Connect(function(deltaTime)
	local now = tick()
	
	-- Update path positions at throttled rate
	if now - PathState.lastPathUpdate >= Config.PATH_UPDATE_RATE then
		PathState.lastPathUpdate = now
		updateSegmentPositions()
	end
	
	-- Always animate
	animateSegments(deltaTime)
end)

--============================================================================--
--                            CLEANUP HANDLERS
--============================================================================--

player.CharacterRemoving:Connect(function()
	hidePath()
	PathState = {
		active = false,
		currentTargetGate = nil,
		smoothedStartPos = nil,
		smoothedEndPos = nil,
		pathModel = nil,
		segments = {},
		lastGateUpdate = 0,
		lastPathUpdate = 0,
		animationTime = 0,
	}
end)

if camera then
	camera:GetPropertyChangedSignal("Parent"):Connect(function()
		if camera.Parent == nil then
			hidePath()
		end
	end)
end

--============================================================================--
--                            INITIALIZATION
--============================================================================--

print("✅ Tycoon Path Guide v3.0 Initialized!")
print("🎨 Features: Smooth curves, proper fading, anti-bunching")
print("⚡ Performance optimized with throttled updates")