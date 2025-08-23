--[[
	Minimalist Tycoon Arrow Guide v3
	- Small, clean directional arrows that point TO tycoons
	- Automatically hides when tycoon is claimed
	- No huge ugly arrows above tycoons
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Configuration
local ARROW_COLOR = Color3.fromRGB(100, 255, 150) -- Soft green
local ARROW_SIZE = Vector3.new(3, 1, 5) -- Small arrow
local ARROW_HEIGHT = 8 -- Height above ground
local ARROW_DISTANCE = 15 -- Distance from player
local CHECK_RADIUS = 200 -- How far to look for tycoons

-- Find all tycoon gates
local function findUnclaimedTycoons()
	local unclaimed = {}
	
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and (obj.Name == "Touch to claim!" or obj.Name:lower():find("gate") or obj.Name:lower():find("claim")) then
			local touchPart = obj:FindFirstChild("Head")
			if touchPart and obj.Parent and obj.Parent.Parent then
				local tycoon = obj.Parent.Parent
				local owner = tycoon:FindFirstChild("Owner")
				
				-- Check if unclaimed and visible
				if owner and owner.Value == nil and touchPart.Transparency < 1 then
					table.insert(unclaimed, {
						tycoon = tycoon,
						position = touchPart.Position,
						gate = obj
					})
				end
			end
		end
	end
	
	return unclaimed
end

-- Create a small directional arrow
local function createDirectionalArrow()
	local arrow = Instance.new("Part")
	arrow.Name = "TycoonDirectionArrow"
	arrow.Size = ARROW_SIZE
	arrow.Material = Enum.Material.Neon
	arrow.Color = ARROW_COLOR
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Transparency = 0.2
	
	-- Arrow shape using wedge
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Wedge
	mesh.Scale = Vector3.new(1, 0.5, 1)
	mesh.Parent = arrow
	
	-- Subtle glow
	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Color = ARROW_COLOR
	light.Range = 8
	light.Parent = arrow
	
	-- Small text label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = arrow
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "Tycoon"
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.5
	text.Font = Enum.Font.Gotham
	text.Parent = billboard
	
	return arrow
end

-- Player arrow management
local playerArrows = {}

local function updatePlayerArrow(player)
	local character = player.Character
	if not character then return end
	
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then return end
	
	-- Get unclaimed tycoons
	local unclaimed = findUnclaimedTycoons()
	
	-- Find closest unclaimed tycoon
	local closest = nil
	local closestDist = math.huge
	
	for _, tycoonData in ipairs(unclaimed) do
		local dist = (tycoonData.position - humanoidRoot.Position).Magnitude
		if dist < closestDist and dist < CHECK_RADIUS then
			closest = tycoonData
			closestDist = dist
		end
	end
	
	-- Get or create arrow
	local arrow = playerArrows[player]
	
	if closest and closestDist > 20 then -- Only show if far enough away
		if not arrow then
			arrow = createDirectionalArrow()
			arrow.Parent = workspace
			playerArrows[player] = arrow
		end
		
		-- Position arrow around player pointing to tycoon
		local playerPos = humanoidRoot.Position
		local direction = (closest.position - playerPos).Unit
		
		-- Position arrow in front of player
		local arrowPos = playerPos + direction * ARROW_DISTANCE + Vector3.new(0, ARROW_HEIGHT, 0)
		
		-- Make arrow point toward tycoon
		arrow.CFrame = CFrame.lookAt(arrowPos, arrowPos + direction) * CFrame.Angles(0, math.rad(90), 0)
		
		-- Update distance text
		local billboard = arrow:FindFirstChildOfClass("BillboardGui")
		if billboard then
			local textLabel = billboard:FindFirstChildOfClass("TextLabel")
			if textLabel then
				textLabel.Text = string.format("Tycoon - %dm", math.floor(closestDist))
			end
		end
		
		-- Pulse effect based on distance
		local pulse = math.sin(tick() * 3) * 0.1 + 0.9
		arrow.Transparency = 0.3 - (0.2 * (1 - closestDist / CHECK_RADIUS))
		
		local light = arrow:FindFirstChildOfClass("PointLight")
		if light then
			light.Brightness = pulse * 2
		end
		
	else
		-- Remove arrow if no tycoons or too close
		if arrow then
			arrow:Destroy()
			playerArrows[player] = nil
		end
	end
end

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
	if playerArrows[player] then
		playerArrows[player]:Destroy()
		playerArrows[player] = nil
	end
end)

-- Main update loop
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerArrow(player)
	end
end)

-- Optional: Small indicator above unclaimed tycoons (MUCH smaller)
local tycoonIndicators = {}

local function createTycoonIndicator(tycoonData)
	local indicator = Instance.new("Part")
	indicator.Name = "TycoonIndicator"
	indicator.Shape = Enum.PartType.Ball
	indicator.Size = Vector3.new(2, 2, 2) -- Small orb
	indicator.Material = Enum.Material.ForceField
	indicator.Color = ARROW_COLOR
	indicator.Transparency = 0.5
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.Position = tycoonData.position + Vector3.new(0, 15, 0)
	
	-- Spinning ring
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Size = Vector3.new(4, 0.2, 4)
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = ARROW_COLOR
	ring.Transparency = 0.7
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = indicator.CFrame * CFrame.Angles(math.rad(90), 0, 0)
	ring.Parent = indicator
	
	return indicator
end

-- Update tycoon indicators
local function updateTycoonIndicators()
	-- Clear old indicators
	for tycoon, indicator in pairs(tycoonIndicators) do
		if tycoon.Owner.Value ~= nil then
			indicator:Destroy()
			tycoonIndicators[tycoon] = nil
		end
	end
	
	-- Add new indicators
	local unclaimed = findUnclaimedTycoons()
	for _, tycoonData in ipairs(unclaimed) do
		if not tycoonIndicators[tycoonData.tycoon] then
			local indicator = createTycoonIndicator(tycoonData)
			indicator.Parent = workspace
			tycoonIndicators[tycoonData.tycoon] = indicator
			
			-- Animate
			task.spawn(function()
				while indicator.Parent do
					indicator.CFrame = indicator.CFrame * CFrame.Angles(0, math.rad(2), 0)
					local ring = indicator:FindFirstChild("Ring")
					if ring then
						ring.CFrame = ring.CFrame * CFrame.Angles(0, 0, math.rad(3))
					end
					task.wait()
				end
			end)
		end
	end
end

-- Update indicators every few seconds
task.spawn(function()
	while true do
		updateTycoonIndicators()
		task.wait(3)
	end
end)

print("✅ Minimalist Tycoon Arrow Guide v3 loaded!")