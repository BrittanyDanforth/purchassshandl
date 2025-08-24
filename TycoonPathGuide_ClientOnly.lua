--[[
    CLIENT-ONLY Tycoon Path Guide System
    - Place in StarterPlayer > StarterPlayerScripts as a LocalScript
    - Path only visible to the local player
    - Uses CurrentCamera for true client-side rendering
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Wait for local player
local player = Players.LocalPlayer

-- Configuration
local PATH_COLOR = Color3.fromRGB(100, 255, 170) -- Mint green
local GLOW_COLOR = Color3.fromRGB(150, 255, 200) -- Lighter mint
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

-- Create a single path segment (CLIENT-ONLY using LocalTransparencyModifier)
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
    
    -- MAKE IT CLIENT-ONLY: Set transparency to 1 for everyone
    segment.Transparency = 1
    -- Then use LocalTransparencyModifier to make it visible ONLY to us
    segment.LocalTransparencyModifier = -1 -- This makes it fully visible to local player only!

    -- Add subtle glow
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 0.5
    pointLight.Color = GLOW_COLOR
    pointLight.Range = 8
    pointLight.Enabled = false -- Disable for others
    pointLight.Parent = segment

    -- Selection box for outer glow effect
    local selection = Instance.new("SelectionBox")
    selection.Adornee = segment
    selection.Color3 = GLOW_COLOR
    selection.LineThickness = 0.05
    selection.Transparency = 0.7
    selection.Parent = segment

    return segment
end

-- Get ground position at a point
local function getGroundPosition(position, ignoreList)
    raycastParams.FilterDescendantsInstances = ignoreList

    -- Cast ray from above position
    local rayOrigin = position + Vector3.new(0, 10, 0)
    local rayDirection = Vector3.new(0, -50, 0)

    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if rayResult then
        return rayResult.Position + Vector3.new(0, GROUND_OFFSET, 0), rayResult.Normal
    end

    -- Fallback to original height
    return position, Vector3.new(0, 1, 0)
end

-- Cache for tycoon gates (update less frequently)
local cachedGates = {}
local lastGateUpdate = 0
local GATE_UPDATE_INTERVAL = 2 -- Only update gates every 2 seconds

-- Find all tycoon gates with caching
local function findTycoonGates()
    local now = tick()
    if now - lastGateUpdate < GATE_UPDATE_INTERVAL and #cachedGates > 0 then
        return cachedGates -- Return cached gates
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
                        gate = obj,
                        tycoon = tycoon,
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

    -- Check if player owns a tycoon
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

    -- Remove path if owns tycoon or no unclaimed tycoons
    if ownsATycoon or not nearestGate then
        if pathModel then
            -- Fade out smoothly
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

    -- Hide path if too close or too far
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

    -- Create or get path model - Now truly client-only!
    if not pathModel or not pathModel.Parent then
        pathModel = Instance.new("Model")
        pathModel.Name = "LocalTycoonPath"
        pathModel.Parent = workspace -- Parts render in workspace but are invisible to others
    end

    -- Calculate path
    local startPos = humanoidRoot.Position
    local endPos = nearestGate.position
    local direction = (endPos - startPos).Unit
    local distance = math.min(nearestDistance, MAX_DISTANCE)

    -- Calculate number of segments
    local segmentCount = math.min(math.floor(distance / SEGMENT_SPACING), MAX_SEGMENTS)

    -- Update or create segments
    local ignoreList = {character, pathModel}

    for i = 1, segmentCount do
        local segment = pathModel:FindFirstChild("Segment" .. i)
        if not segment then
            segment = createSegment()
            segment.Name = "Segment" .. i
            segment.Parent = pathModel
        end

        -- Calculate position along path
        local t = i / (segmentCount + 1)
        local pathPos = startPos + direction * (distance * t)

        -- Get ground position (skip every other segment for performance)
        local groundPos, groundNormal
        if i % 2 == 1 then
            groundPos, groundNormal = getGroundPosition(pathPos, ignoreList)
        else
            -- Interpolate from previous segment for even segments
            groundPos = pathPos
            groundNormal = Vector3.new(0, 1, 0)
        end

        -- Calculate rotation to align with ground
        local lookDirection = direction
        local rightVector = lookDirection:Cross(groundNormal)
        if rightVector.Magnitude > 0 then
            rightVector = rightVector.Unit
            local upVector = rightVector:Cross(lookDirection).Unit

            -- Create CFrame aligned with ground
            local targetCFrame = CFrame.fromMatrix(groundPos, rightVector, upVector, -lookDirection)

            -- Smooth movement
            if segment.CFrame then
                segment.CFrame = segment.CFrame:Lerp(targetCFrame, POSITION_SMOOTHING)
            else
                segment.CFrame = targetCFrame
            end
        else
            -- Fallback for vertical surfaces
            segment.CFrame = CFrame.lookAt(groundPos, groundPos + direction)
        end

        -- Scale segments (smaller as they get further)
        local scale = 1 - (t * 0.3)
        segment.Size = SEGMENT_SIZE * scale

        -- Make visible to local player only
        segment.Transparency = 1 -- Keep it invisible to others
        segment.LocalTransparencyModifier = -1 -- But visible to us!
        local light = segment:FindFirstChild("PointLight")
        if light then 
            light.Enabled = true
            light.Range = 8 * scale
        end
    end

    -- Hide unused segments
    for i = segmentCount + 1, MAX_SEGMENTS do
        local segment = pathModel:FindFirstChild("Segment" .. i)
        if segment then
            segment.Transparency = 1
            local light = segment:FindFirstChild("PointLight")
            if light then light.Enabled = false end
        end
    end
end

-- Animation loop with frame limiting
local animTime = 0
local lastPathUpdate = 0
local PATH_UPDATE_RATE = 1/30 -- 30 FPS for path updates (smooth enough)

RunService.RenderStepped:Connect(function(deltaTime)
    animTime = animTime + deltaTime
    
    -- Limit path updates to 30 FPS to reduce CPU usage
    local now = tick()
    if now - lastPathUpdate >= PATH_UPDATE_RATE then
        lastPathUpdate = now
        updatePath()
    end

    -- Animate segments if path exists
    if pathModel and pathModel.Parent then
        for i, segment in pairs(pathModel:GetChildren()) do
            if segment:IsA("Part") and segment.Transparency < 1 then
                -- Extract segment number
                local segNum = tonumber(segment.Name:match("Segment(%d+)")) or 1

                -- Pulsing glow
                local pulse = math.sin(animTime * PULSE_SPEED + segNum * 0.2) * 0.5 + 0.5
                segment.Material = Enum.Material.Neon

                local light = segment:FindFirstChild("PointLight")
                if light then
                    light.Brightness = 0.3 + pulse * 0.7
                end

                local selection = segment:FindFirstChild("SelectionBox")
                if selection then
                    selection.Transparency = 0.5 + pulse * 0.3
                end

                -- Flow effect
                local flow = (animTime * FLOW_SPEED + segNum) % 10
                if flow < 1 then
                    segment.Color = GLOW_COLOR:Lerp(PATH_COLOR, flow)
                else
                    segment.Color = PATH_COLOR
                end

                -- Subtle transparency wave (using LocalTransparencyModifier)
                local wave = math.sin(animTime * FLOW_SPEED - segNum * 0.5) * 0.1
                segment.LocalTransparencyModifier = -1 + wave -- Animates visibility for local player only
            end
        end
    end
end)

-- Cleanup on character removing
player.CharacterRemoving:Connect(function()
    if pathModel then
        pathModel:Destroy()
        pathModel = nil
    end
end)

-- Clean up if camera changes
camera:GetPropertyChangedSignal("Parent"):Connect(function()
    if camera.Parent == nil and pathModel then
        pathModel:Destroy()
        pathModel = nil
    end
end)

print("✅ CLIENT-ONLY Tycoon Path Guide loaded!")
print("🔒 Path uses LocalTransparencyModifier - INVISIBLE to other players!")
print("✨ Beautiful glowing segments that only YOU can see!")