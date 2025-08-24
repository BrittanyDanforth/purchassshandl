--[[
    TRUE CLIENT-ONLY Tycoon Path Guide System
    - Uses Beams which are truly client-only
    - Nobody else can see your path!
    - Place in StarterPlayer > StarterPlayerScripts as LocalScript
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Wait for local player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Configuration
local PATH_COLOR = Color3.fromRGB(100, 255, 170) -- Mint green
local GLOW_COLOR = Color3.fromRGB(150, 255, 200) -- Lighter mint
local SEGMENT_COUNT = 15 -- Number of beam segments
local MIN_DISTANCE = 15 -- Hide path when this close
local MAX_DISTANCE = 200 -- Maximum draw distance
local GROUND_OFFSET = 0.5 -- Height above ground

-- Animation settings
local PULSE_SPEED = 2
local FLOW_SPEED = 3

-- Raycast setup
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

-- Track our path parts (client-only container)
local pathContainer = nil
local pathBeams = {}
local pathAttachments = {}

-- Cache for tycoon gates
local cachedGates = {}
local lastGateUpdate = 0
local GATE_UPDATE_INTERVAL = 2

-- Create path container that's truly client-only
local function createPathContainer()
    -- Create a part that will hold our attachments (invisible)
    local container = Instance.new("Part")
    container.Name = "LocalPathContainer"
    container.Transparency = 1
    container.Anchored = true
    container.CanCollide = false
    container.CanQuery = false
    container.CanTouch = false
    container.Size = Vector3.new(1, 1, 1)
    container.CFrame = CFrame.new(0, -1000, 0) -- Hide it way below
    
    -- Parent to character for true client-only behavior
    container.Parent = character
    
    return container
end

-- Create a beam segment
local function createBeamSegment(startAttachment, endAttachment)
    local beam = Instance.new("Beam")
    beam.Attachment0 = startAttachment
    beam.Attachment1 = endAttachment
    beam.Width0 = 2
    beam.Width1 = 1.5
    beam.Color = ColorSequence.new(PATH_COLOR)
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Texture = "rbxasset://textures/ui/LuaChat/icons/ic-gift.png" -- Simple glow texture
    beam.TextureSpeed = 2
    beam.TextureLength = 1
    beam.FaceCamera = true
    beam.Parent = startAttachment.Parent
    
    return beam
end

-- Get ground position
local function getGroundPosition(position, ignoreList)
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local rayOrigin = position + Vector3.new(0, 10, 0)
    local rayDirection = Vector3.new(0, -50, 0)
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if rayResult then
        return rayResult.Position + Vector3.new(0, GROUND_OFFSET, 0)
    end
    
    return position
end

-- Find tycoon gates
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

-- Update path
local function updatePath()
    character = player.Character
    if not character then
        if pathContainer then
            pathContainer:Destroy()
            pathContainer = nil
        end
        return
    end
    
    local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRoot then return end
    
    -- Check gates
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
    
    -- Remove path if owns tycoon or too close/far
    if ownsATycoon or not nearestGate or nearestDistance < MIN_DISTANCE or nearestDistance > MAX_DISTANCE then
        if pathContainer then
            pathContainer:Destroy()
            pathContainer = nil
            pathBeams = {}
            pathAttachments = {}
        end
        return
    end
    
    -- Create container if needed
    if not pathContainer or not pathContainer.Parent then
        pathContainer = createPathContainer()
        
        -- Create attachments
        for i = 1, SEGMENT_COUNT + 1 do
            local attachment = Instance.new("Attachment")
            attachment.Name = "PathPoint" .. i
            attachment.Parent = pathContainer
            pathAttachments[i] = attachment
        end
        
        -- Create beams between attachments
        for i = 1, SEGMENT_COUNT do
            local beam = createBeamSegment(pathAttachments[i], pathAttachments[i + 1])
            pathBeams[i] = beam
        end
    end
    
    -- Update attachment positions
    local startPos = humanoidRoot.Position
    local endPos = nearestGate.position
    local direction = (endPos - startPos).Unit
    local distance = math.min(nearestDistance, MAX_DISTANCE)
    
    local ignoreList = {character, pathContainer}
    
    for i = 1, SEGMENT_COUNT + 1 do
        local t = (i - 1) / SEGMENT_COUNT
        local pathPos = startPos + direction * (distance * t)
        
        -- Get ground position
        local groundPos = getGroundPosition(pathPos, ignoreList)
        
        -- Update attachment world position
        pathAttachments[i].WorldPosition = groundPos
    end
end

-- Animation loop
local animTime = 0
local lastUpdate = 0
local UPDATE_RATE = 1/30

RunService.RenderStepped:Connect(function(deltaTime)
    animTime = animTime + deltaTime
    
    -- Update path
    local now = tick()
    if now - lastUpdate >= UPDATE_RATE then
        lastUpdate = now
        updatePath()
    end
    
    -- Animate beams
    if pathBeams then
        for i, beam in pairs(pathBeams) do
            if beam and beam.Parent then
                -- Pulsing effect
                local pulse = math.sin(animTime * PULSE_SPEED + i * 0.3) * 0.5 + 0.5
                
                -- Update transparency with pulse
                beam.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.3 - pulse * 0.2),
                    NumberSequenceKeypoint.new(0.5, 0.1 - pulse * 0.1),
                    NumberSequenceKeypoint.new(1, 0.3 - pulse * 0.2)
                })
                
                -- Color flow effect
                local flow = (animTime * FLOW_SPEED + i) % 5
                if flow < 1 then
                    beam.Color = ColorSequence.new(GLOW_COLOR:Lerp(PATH_COLOR, flow))
                else
                    beam.Color = ColorSequence.new(PATH_COLOR)
                end
                
                -- Width pulse
                beam.Width0 = 2 + pulse * 0.5
                beam.Width1 = 1.5 + pulse * 0.3
            end
        end
    end
end)

-- Cleanup
player.CharacterRemoving:Connect(function()
    if pathContainer then
        pathContainer:Destroy()
        pathContainer = nil
        pathBeams = {}
        pathAttachments = {}
    end
end)

print("✅ TRUE CLIENT-ONLY Path Guide loaded!")
print("🔒 Using Beams - 100% invisible to other players!")
print("✨ Smooth ground-following path with animations!")