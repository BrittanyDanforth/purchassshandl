--[[
	┌─────────────────────────────────────────────────────────────────────┐
	│                    CLIENT-ONLY TYCOON PATH GUIDE                    │
	├─────────────────────────────────────────────────────────────────────┤
	│ A visual path guide system that helps players find unclaimed        │
	│ tycoons. Features smooth animations, intelligent fading, and        │
	│ performance optimizations.                                          │
	│                                                                     │
	│ Installation:                                                       │
	│ - Place in StarterPlayer > StarterPlayerScripts as a LocalScript   │
	│ - Path is only visible to the local player                         │
	│                                                                     │
	│ Features:                                                           │
	│ - Dynamic path generation to nearest unclaimed tycoon              │
	│ - Smooth ground-following segments                                 │
	│ - Intelligent segment spacing with anti-bunching                   │
	│ - Flowing light animations                                         │
	│ - Performance-optimized with caching and throttling                │
	└─────────────────────────────────────────────────────────────────────┘
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Wait for player
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════════
--                           CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════

local CONFIG = {
	-- Visual Settings
	Colors = {
		PATH = Color3.fromRGB(255, 179, 212),      -- Light Pink
		GLOW = Color3.fromRGB(255, 204, 229),      -- Lighter Pink Glow
		PULSE = Color3.fromRGB(255, 230, 240),     -- Ultra Light Pink for pulses
	},
	
	-- Path Geometry
	Path = {
		SEGMENT_SIZE = Vector3.new(2, 0.1, 1),     -- Flat rectangular segments
		SEGMENT_SPACING = 3,                        -- Distance between segments
		MAX_SEGMENTS = 25,                          -- Maximum path segments
		GROUND_OFFSET = 0.05,                       -- Lift above ground to prevent z-fighting
		SCALE_REDUCTION = 0.3,                      -- Scale reduction factor along path
	},
	
	-- Distance Settings
	Distance = {
		MIN = 15,                                   -- Hide path when closer than this
		MAX = 200,                                  -- Maximum draw distance
		FADE_START = 180,                           -- Start fading at this distance
	},
	
	-- Animation Parameters
	Animation = {
		PULSE_SPEED = 2,                            -- Pulsing light speed
		FLOW_SPEED = 3,                             -- Light flow speed along path
		WAVE_AMPLITUDE = 0.05,                      -- Transparency wave amplitude
		FADE_TIME = 0.3,                            -- Fade in/out duration
	},
	
	-- Performance Settings
	Performance = {
		POSITION_SMOOTHING = 0.15,                  -- Lower = smoother movement
		PATH_UPDATE_RATE = 1/30,                    -- Path update frequency (Hz)
		GATE_CACHE_TIME = 2,                        -- Gate cache duration (seconds)
		BUNCHING_THRESHOLD = 0.6,                   -- Segment spacing threshold for fading
		MAX_FADE = 0.8,                             -- Maximum fade for bunched segments
	},
	
	-- Light Settings
	Light = {
		BASE_BRIGHTNESS = 0.3,                      -- Minimum light brightness
		PULSE_BRIGHTNESS = 0.7,                     -- Additional brightness from pulse
		BASE_RANGE = 8,                             -- Base light range
		GLOW_TRANSPARENCY = 0.1,                    -- Selection box base transparency
		GLOW_PULSE = 0.1,                           -- Selection box pulse amount
	},
}

-- ═══════════════════════════════════════════════════════════════════════
--                            STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════

local State = {
	pathModel = nil,
	segments = {},
	cachedGates = {},
	lastGateUpdate = 0,
	lastPathUpdate = 0,
	animTime = 0,
	isUpdating = false,
}

-- ═══════════════════════════════════════════════════════════════════════
--                           UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

-- Raycast parameters for ground detection
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

-- Calculate ground position at a given point
local function getGroundPosition(position, ignoreList)
	raycastParams.FilterDescendantsInstances = ignoreList
	
	local rayOrigin = position + Vector3.new(0, 10, 0)
	local rayDirection = Vector3.new(0, -50, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if rayResult then
		return rayResult.Position + Vector3.new(0, CONFIG.Path.GROUND_OFFSET, 0), rayResult.Normal
	end
	
	return position, Vector3.new(0, 1, 0)
end

-- Smooth lerp with frame-rate independence
local function smoothLerp(current, target, alpha, deltaTime)
	local adjustedAlpha = 1 - math.pow(1 - alpha, deltaTime * 60)
	return current:Lerp(target, adjustedAlpha)
end

-- ═══════════════════════════════════════════════════════════════════════
--                          SEGMENT CREATION
-- ═══════════════════════════════════════════════════════════════════════

local function createSegment(index)
	local segment = Instance.new("Part")
	segment.Name = "PathSegment" .. index
	segment.Size = CONFIG.Path.SEGMENT_SIZE
	segment.Material = Enum.Material.Neon
	segment.Color = CONFIG.Colors.PATH
	segment.Anchored = true
	segment.CanCollide = false
	segment.CanQuery = false
	segment.CanTouch = false
	segment.CastShadow = false
	segment.Transparency = 1
	segment.LocalTransparencyModifier = -1
	
	-- Point light for glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = CONFIG.Light.BASE_BRIGHTNESS
	pointLight.Color = CONFIG.Colors.GLOW
	pointLight.Range = CONFIG.Light.BASE_RANGE
	pointLight.Enabled = false
	pointLight.Parent = segment
	
	-- Selection box for enhanced visibility
	local selection = Instance.new("SelectionBox")
	selection.Adornee = segment
	selection.Color3 = CONFIG.Colors.GLOW
	selection.LineThickness = 0.05
	selection.Transparency = CONFIG.Light.GLOW_TRANSPARENCY
	selection.Parent = segment
	
	-- Store reference
	State.segments[index] = {
		part = segment,
		light = pointLight,
		selection = selection,
		targetCFrame = nil,
		currentScale = 1,
		fadeFactor = 0,
	}
	
	return segment
end

-- ═══════════════════════════════════════════════════════════════════════
--                          TYCOON GATE DETECTION
-- ═══════════════════════════════════════════════════════════════════════

local function findTycoonGates()
	local now = tick()
	
	-- Use cached gates if still valid
	if now - State.lastGateUpdate < CONFIG.Performance.GATE_CACHE_TIME and #State.cachedGates > 0 then
		return State.cachedGates
	end
	
	State.lastGateUpdate = now
	State.cachedGates = {}
	
	-- Search for tycoon gates
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local name = obj.Name:lower()
			if name == "touch to claim!" or name:find("gate") or name:find("claim") then
				local touchPart = obj:FindFirstChild("Head") or obj:FindFirstChild("TouchPart") or obj:FindFirstChildWhichIsA("BasePart")
				
				if touchPart then
					-- Navigate up to find the tycoon
					local parent = obj.Parent
					while parent and parent ~= workspace do
						local owner = parent:FindFirstChild("Owner")
						if owner and owner:IsA("ObjectValue") then
							table.insert(State.cachedGates, {
								owner = owner,
								position = touchPart.Position,
								model = obj,
							})
							break
						end
						parent = parent.Parent
					end
				end
			end
		end
	end
	
	return State.cachedGates
end

-- ═══════════════════════════════════════════════════════════════════════
--                           PATH MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════

local function cleanupPath()
	if State.pathModel then
		-- Fade out all segments
		for _, segmentData in pairs(State.segments) do
			if segmentData.part and segmentData.part.Parent then
				TweenService:Create(segmentData.part, 
					TweenInfo.new(CONFIG.Animation.FADE_TIME), 
					{Transparency = 1}
				):Play()
				
				if segmentData.light then
					segmentData.light.Enabled = false
				end
			end
		end
		
		-- Destroy after fade
		Debris:AddItem(State.pathModel, CONFIG.Animation.FADE_TIME)
		State.pathModel = nil
		State.segments = {}
	end
end

local function hideAllSegments()
	for _, segmentData in pairs(State.segments) do
		if segmentData.part then
			segmentData.part.Transparency = 1
			segmentData.part.LocalTransparencyModifier = 0
			if segmentData.light then
				segmentData.light.Enabled = false
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════
--                          PATH UPDATE LOGIC
-- ═══════════════════════════════════════════════════════════════════════

local function updatePath(deltaTime)
	-- Prevent concurrent updates
	if State.isUpdating then return end
	State.isUpdating = true
	
	-- Get character and validate
	local character = player.Character
	if not character then
		cleanupPath()
		State.isUpdating = false
		return
	end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then
		State.isUpdating = false
		return
	end
	
	-- Find gates and check ownership
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
	
	-- Clean up if player owns a tycoon or no gates available
	if ownsATycoon or not nearestGate then
		cleanupPath()
		State.isUpdating = false
		return
	end
	
	-- Check distance constraints
	if nearestDistance < CONFIG.Distance.MIN or nearestDistance > CONFIG.Distance.MAX then
		hideAllSegments()
		State.isUpdating = false
		return
	end
	
	-- Create path model if needed
	if not State.pathModel or not State.pathModel.Parent then
		State.pathModel = Instance.new("Model")
		State.pathModel.Name = "LocalTycoonPath"
		State.pathModel.Parent = workspace
	end
	
	-- Calculate path parameters
	local startPos = humanoidRoot.Position
	local endPos = nearestGate.position
	local direction = (endPos - startPos).Unit
	local distance = math.min(nearestDistance, CONFIG.Distance.MAX)
	local segmentCount = math.min(math.floor(distance / CONFIG.Path.SEGMENT_SPACING), CONFIG.Path.MAX_SEGMENTS)
	local ignoreList = {character, State.pathModel}
	
	-- Distance-based fade
	local distanceFade = 1
	if nearestDistance > CONFIG.Distance.FADE_START then
		distanceFade = 1 - ((nearestDistance - CONFIG.Distance.FADE_START) / (CONFIG.Distance.MAX - CONFIG.Distance.FADE_START))
	end
	
	-- Update segments
	local segmentPositions = {}
	
	for i = 1, segmentCount do
		-- Get or create segment
		local segmentData = State.segments[i]
		if not segmentData or not segmentData.part.Parent then
			local segment = createSegment(i)
			segment.Parent = State.pathModel
			segmentData = State.segments[i]
		end
		
		local segment = segmentData.part
		
		-- Calculate position along path
		local t = i / (segmentCount + 1)
		local pathPos = startPos + direction * (distance * t)
		
		-- Get ground position
		local groundPos, groundNormal = getGroundPosition(pathPos, ignoreList)
		
		-- Calculate orientation
		local lookDirection = direction
		local rightVector = lookDirection:Cross(groundNormal)
		
		if rightVector.Magnitude > 0.01 then
			rightVector = rightVector.Unit
			local upVector = rightVector:Cross(lookDirection).Unit
			local targetCFrame = CFrame.fromMatrix(groundPos, rightVector, upVector, -lookDirection)
			
			-- Smooth movement
			if segment.CFrame then
				segment.CFrame = smoothLerp(segment.CFrame, targetCFrame, CONFIG.Performance.POSITION_SMOOTHING, deltaTime)
			else
				segment.CFrame = targetCFrame
			end
		else
			segment.CFrame = CFrame.lookAt(groundPos, groundPos + direction)
		end
		
		-- Store position for anti-bunching
		segmentPositions[i] = segment.Position
		
		-- Calculate scale
		local scale = 1 - (t * CONFIG.Path.SCALE_REDUCTION)
		segment.Size = CONFIG.Path.SEGMENT_SIZE * scale
		segmentData.currentScale = scale
		
		-- Anti-bunching fade calculation
		local fadeFactor = 0
		if i > 1 then
			local prevPos = segmentPositions[i-1]
			local currentPos = segmentPositions[i]
			local spacing = (currentPos - prevPos).Magnitude
			
			if spacing < CONFIG.Path.SEGMENT_SPACING * CONFIG.Performance.BUNCHING_THRESHOLD then
				fadeFactor = 1 - (spacing / (CONFIG.Path.SEGMENT_SPACING * CONFIG.Performance.BUNCHING_THRESHOLD))
				fadeFactor = math.clamp(fadeFactor, 0, CONFIG.Performance.MAX_FADE)
			end
		end
		
		segmentData.fadeFactor = fadeFactor
		
		-- Apply visibility based on bunching and distance
		local shouldHide = fadeFactor > 0.5
		if shouldHide then
			segment.LocalTransparencyModifier = 0
			segmentData.light.Enabled = false
		else
			segment.LocalTransparencyModifier = -1 + (1 - distanceFade) * 0.5
			segmentData.light.Enabled = true
			segmentData.light.Range = CONFIG.Light.BASE_RANGE * scale * distanceFade
		end
		
		segment:SetAttribute("SegmentIndex", i)
		segment:SetAttribute("FadeFactor", fadeFactor)
		segment:SetAttribute("DistanceFade", distanceFade)
	end
	
	-- Hide unused segments
	for i = segmentCount + 1, CONFIG.Path.MAX_SEGMENTS do
		local segmentData = State.segments[i]
		if segmentData and segmentData.part then
			segmentData.part.Transparency = 1
			segmentData.part.LocalTransparencyModifier = 0
			if segmentData.light then
				segmentData.light.Enabled = false
			end
		end
	end
	
	State.isUpdating = false
end

-- ═══════════════════════════════════════════════════════════════════════
--                           ANIMATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local function animateSegments(deltaTime)
	if not State.pathModel or not State.pathModel.Parent then return end
	
	State.animTime = State.animTime + deltaTime
	
	for index, segmentData in pairs(State.segments) do
		if segmentData.part and segmentData.part.Parent then
			local segment = segmentData.part
			local segmentIndex = segment:GetAttribute("SegmentIndex") or index
			local fadeFactor = segment:GetAttribute("FadeFactor") or 0
			local distanceFade = segment:GetAttribute("DistanceFade") or 1
			
			-- Skip if hidden
			if segment.LocalTransparencyModifier == 0 then
				continue
			end
			
			-- Pulse animation
			local pulse = math.sin(State.animTime * CONFIG.Animation.PULSE_SPEED + segmentIndex * 0.2) * 0.5 + 0.5
			
			-- Light animation
			if segmentData.light and segmentData.light.Enabled then
				local brightness = CONFIG.Light.BASE_BRIGHTNESS + (pulse * CONFIG.Light.PULSE_BRIGHTNESS)
				segmentData.light.Brightness = brightness * (1 - fadeFactor) * distanceFade
			end
			
			-- Selection box animation
			if segmentData.selection then
				local transparency = CONFIG.Light.GLOW_TRANSPARENCY + (pulse * CONFIG.Light.GLOW_PULSE)
				segmentData.selection.Transparency = transparency + (fadeFactor * 0.7)
			end
			
			-- Flow animation
			local flow = (State.animTime * CONFIG.Animation.FLOW_SPEED + segmentIndex) % 10
			if flow < 1 then
				segment.Color = CONFIG.Colors.GLOW:Lerp(CONFIG.Colors.PULSE, flow * flow) -- Quadratic easing
			else
				segment.Color = CONFIG.Colors.PATH
			end
			
			-- Transparency wave
			if segment.LocalTransparencyModifier == -1 then
				local wave = math.sin(State.animTime * CONFIG.Animation.FLOW_SPEED - segmentIndex * 0.5) * CONFIG.Animation.WAVE_AMPLITUDE
				segment.LocalTransparencyModifier = -1 + wave
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════
--                             MAIN LOOP
-- ═══════════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function(deltaTime)
	local now = tick()
	
	-- Update path at configured rate
	if now - State.lastPathUpdate >= CONFIG.Performance.PATH_UPDATE_RATE then
		State.lastPathUpdate = now
		updatePath(deltaTime)
	end
	
	-- Always animate
	animateSegments(deltaTime)
end)

-- ═══════════════════════════════════════════════════════════════════════
--                           EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	cleanupPath()
end)

-- Clean up if camera is destroyed
if camera then
	camera:GetPropertyChangedSignal("Parent"):Connect(function()
		if camera.Parent == nil then
			cleanupPath()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
--                          INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════

print("✅ Tycoon Path Guide System Initialized!")
print("📍 Features: Anti-bunching, Smooth animations, Performance optimized")
print("🎨 Version: 2.0 - Polished Edition")