-- =================================================================
-- Polished Model Dropper Script v3.1 FIXED
-- Fixed to match working dropper - Cash goes directly in touching part
-- =================================================================

-- Services
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- References
local PartStorage = workspace:WaitForChild("PartStorage")
local templateModel = ReplicatedStorage:WaitForChild("CinnamonRoll")
local dropPart = script.Parent:WaitForChild("Drop")

-- Configuration
local DROP_RATE = 1.5
local CASH_VALUE = 12
local LIFETIME = 20

-- =================================================================
-- COLLISION GROUPS (matching your working script)
-- =================================================================
local DROP_GROUP = "DropperModelDrops"
local PLAYER_GROUP = "Players"

pcall(function()
	PhysicsService:RegisterCollisionGroup(DROP_GROUP)
	PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
	PhysicsService:CollisionGroupSetCollidable(DROP_GROUP, PLAYER_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(DROP_GROUP, DROP_GROUP, false)
end)

local function setupPlayerCollision(character)
	task.wait(0.1)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function() part.CollisionGroup = PLAYER_GROUP end)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setupPlayerCollision)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then setupPlayerCollision(player.Character) end
end

-- Check PrimaryPart
if not templateModel.PrimaryPart then
	warn("ERROR: CinnamonRoll model needs PrimaryPart set!")
	return
end

-- Welding function
local function weldAllParts(model, primaryPart)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= primaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primaryPart
			weld.Part1 = descendant
			weld.Parent = primaryPart
		end
	end
end

-- =================================================================
-- MAIN DROPPER LOOP
-- =================================================================
local count = 0
while true do
	task.wait(DROP_RATE)
	count += 1

	-- 1. Create the Clone
	local newDrop = templateModel:Clone()
	newDrop.Name = "CinnamonRoll_" .. count

	-- 2. Weld all parts
	weldAllParts(newDrop, newDrop.PrimaryPart)

	-- 3. Set physical properties and collision for ALL parts
	-- CRITICAL: Add Cash value to EVERY BasePart so collector can find it
	for _, part in ipairs(newDrop:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true
			part.CanTouch = true  -- Important for touch detection
			part.CanQuery = true
			part.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.5, 0.1, 1, 1)
			pcall(function() part.CollisionGroup = DROP_GROUP end)
			
			-- ADD CASH TO EVERY PART (like your working dropper)
			local cash = Instance.new("IntValue")
			cash.Name = "Cash"
			cash.Value = CASH_VALUE
			cash.Parent = part
		end
	end

	-- 4. Position and scale the model
	local offsetX = (math.random(-2, 2) * 0.1)
	local offsetZ = (math.random(-2, 2) * 0.1)
	
	-- Scale up the model a bit (1.2x bigger)
	local scaleFactor = 1.2
	for _, part in ipairs(newDrop:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scaleFactor
			if part:FindFirstChild("Mesh") then
				part.Mesh.Scale = part.Mesh.Scale * scaleFactor
			end
		elseif part:IsA("SpecialMesh") then
			part.Scale = part.Scale * scaleFactor
		end
	end
	
	-- Position below dropper and flip right-side up
	-- Remove the 180 degree rotations that were making it upside down
	newDrop:SetPrimaryPartCFrame(
		dropPart.CFrame * CFrame.new(offsetX, -2, offsetZ)
	)

	-- Give downward velocity
	newDrop.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, -12, 0)

	-- 5. Set spawn time attribute (some collectors use this)
	newDrop.PrimaryPart:SetAttribute("SpawnTime", tick())

	-- 6. Fade-in effect (matching your working dropper)
	for _, part in ipairs(newDrop:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.7
			TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 0
			}):Play()
		elseif part:IsA("Decal") or part:IsA("Texture") then
			local originalTransparency = part.Transparency
			part.Transparency = 1
			TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = originalTransparency
			}):Play()
		end
	end

	-- 7. Effects (on PrimaryPart)
	local primaryPart = newDrop.PrimaryPart
	
	-- Light flash
	local light = Instance.new("PointLight")
	light.Brightness = 1.2
	light.Range = 6
	light.Color = Color3.new(1, 1, 1)
	light.Parent = primaryPart
	TweenService:Create(light, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0.4
	}):Play()

	-- Spawn ring
	local ring = Instance.new("ParticleEmitter")
	ring.Texture = "rbxassetid://262979222"
	ring.Rate = 0
	ring.Speed = NumberRange.new(0)
	ring.Lifetime = NumberRange.new(0.3)
	ring.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 2)
	})
	ring.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	ring.Color = ColorSequence.new(Color3.new(1, 1, 1))
	ring.Parent = primaryPart
	ring:Emit(1)
	Debris:AddItem(ring, 1)

	-- 8. Parent to workspace (matching your working dropper)
	newDrop.Parent = PartStorage
	
	-- 9. Cleanup after lifetime
	Debris:AddItem(newDrop, LIFETIME)
end