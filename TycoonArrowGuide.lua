--[[
	Tycoon Arrow Guide System
	Shows animated 3D arrows pointing to unclaimed tycoons for new players
	Arrows disappear once player claims a tycoon
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Configuration
local ARROW_COLOR = Color3.fromRGB(255, 215, 0) -- Gold
local ARROW_GLOW_COLOR = Color3.fromRGB(255, 255, 100) -- Bright yellow glow
local ARROW_HEIGHT = 15 -- How high above player the arrow floats
local SHOW_FOR_SECONDS = 60 -- Show arrows for first 60 seconds or until they claim

-- Find all tycoons
local function findAllTycoons()
	local tycoons = {}
	
	-- Common tycoon locations
	local searchLocations = {
		workspace:FindFirstChild("Tycoons"),
		workspace:FindFirstChild("TycoonModel"),
		workspace
	}
	
	for _, location in ipairs(searchLocations) do
		if location then
			for _, child in ipairs(location:GetDescendants()) do
				if child:FindFirstChild("Owner") and child:FindFirstChild("Gate") then
					table.insert(tycoons, child)
				end
			end
		end
	end
	
	-- Remove duplicates
	local uniqueTycoons = {}
	local seen = {}
	for _, tycoon in ipairs(tycoons) do
		if not seen[tycoon] then
			seen[tycoon] = true
			table.insert(uniqueTycoons, tycoon)
		end
	end
	
	return uniqueTycoons
end

-- Create a 3D arrow model
local function createArrow()
	local arrow = Instance.new("Model")
	arrow.Name = "TycoonArrow"
	
	-- Arrow shaft (cylinder)
	local shaft = Instance.new("Part")
	shaft.Name = "Shaft"
	shaft.Size = Vector3.new(2, 8, 2)
	shaft.Shape = Enum.PartType.Cylinder
	shaft.Material = Enum.Material.Neon
	shaft.Color = ARROW_COLOR
	shaft.Anchored = true
	shaft.CanCollide = false
	shaft.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	shaft.Parent = arrow
	
	-- Arrow head (wedge)
	local head = Instance.new("WedgePart")
	head.Name = "Head"
	head.Size = Vector3.new(4, 4, 4)
	head.Material = Enum.Material.Neon
	head.Color = ARROW_COLOR
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = CFrame.new(0, -6, 0) * CFrame.Angles(math.rad(180), 0, 0)
	head.Parent = arrow
	
	-- Glow effect
	local glow = Instance.new("PointLight")
	glow.Brightness = 2
	glow.Color = ARROW_GLOW_COLOR
	glow.Range = 20
	glow.Parent = shaft
	
	-- Selection box for outline
	local selection = Instance.new("SelectionBox")
	selection.Adornee = arrow
	selection.Color3 = ARROW_GLOW_COLOR
	selection.LineThickness = 0.1
	selection.Transparency = 0.5
	selection.Parent = arrow
	
	return arrow
end

-- Create floating text
local function createFloatingText(text)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 300, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 12, 0)
	billboard.AlwaysOnTop = true
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Parent = billboard
	
	return billboard
end

-- Animate arrow
local function animateArrow(arrow, targetPosition, player)
	local startTime = tick()
	local connection
	
	connection = RunService.Heartbeat:Connect(function()
		if not arrow.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		local playerPos = player.Character.HumanoidRootPart.Position
		
		-- Position arrow above player
		local arrowPos = playerPos + Vector3.new(0, ARROW_HEIGHT + math.sin(elapsed * 2) * 2, 0)
		
		-- Make arrow point toward tycoon
		local direction = (targetPosition - playerPos).Unit
		local lookAt = CFrame.lookAt(arrowPos, arrowPos + direction)
		
		-- Rotate to point downward
		arrow:SetPrimaryPartCFrame(lookAt * CFrame.Angles(math.rad(90), 0, 0))
		
		-- Pulse glow effect
		local glow = arrow:FindFirstDescendant("PointLight")
		if glow then
			glow.Brightness = 2 + math.sin(elapsed * 3) * 0.5
		end
		
		-- Spin slightly
		arrow:SetPrimaryPartCFrame(arrow:GetPrimaryPartCFrame() * CFrame.Angles(0, math.rad(elapsed * 50), 0))
	end)
	
	return connection
end

-- Show arrows for new player
local function showArrowsForPlayer(player)
	local arrows = {}
	local connections = {}
	local claimed = false
	
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	wait(2) -- Give them a moment to load in
	
	-- Find available tycoons
	local tycoons = findAllTycoons()
	local availableTycoons = {}
	
	for _, tycoon in ipairs(tycoons) do
		if tycoon:FindFirstChild("Owner") and tycoon.Owner.Value == nil then
			table.insert(availableTycoons, tycoon)
		end
	end
	
	if #availableTycoons == 0 then
		return -- No tycoons available
	end
	
	-- Find nearest unclaimed tycoon
	local nearestTycoon = nil
	local nearestDistance = math.huge
	
	if character:FindFirstChild("HumanoidRootPart") then
		local playerPos = character.HumanoidRootPart.Position
		
		for _, tycoon in ipairs(availableTycoons) do
			local gate = tycoon:FindFirstChild("Gate") or tycoon:FindFirstChildWhichIsA("BasePart", true)
			if gate then
				local distance = (gate.Position - playerPos).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestTycoon = tycoon
				end
			end
		end
	end
	
	if not nearestTycoon then
		nearestTycoon = availableTycoons[1]
	end
	
	-- Create arrow pointing to nearest tycoon
	local arrow = createArrow()
	arrow.PrimaryPart = arrow:FindFirstChild("Shaft")
	arrow.Parent = workspace
	table.insert(arrows, arrow)
	
	-- Add floating text
	local text = createFloatingText("CLAIM THIS TYCOON!")
	text.Parent = arrow.PrimaryPart
	
	-- Get target position
	local gate = nearestTycoon:FindFirstChild("Gate") or nearestTycoon:FindFirstChildWhichIsA("BasePart", true)
	local targetPos = gate and gate.Position or nearestTycoon:GetPivot().Position
	
	-- Animate arrow
	local animConnection = animateArrow(arrow, targetPos, player)
	table.insert(connections, animConnection)
	
	-- Also create a beam from player to tycoon
	local beam = Instance.new("Beam")
	beam.FaceCamera = true
	beam.Width0 = 2
	beam.Width1 = 2
	beam.Color = ColorSequence.new(ARROW_COLOR)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Texture = "rbxasset://textures/ui/LuaChat/icons/ic-double-angle-left-16x16.png"
	beam.TextureSpeed = 2
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	
	-- Create attachments for beam
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = character:FindFirstChild("HumanoidRootPart")
	
	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = gate or nearestTycoon:FindFirstChildWhichIsA("BasePart", true)
	
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Parent = workspace
	
	-- Clean up function
	local function cleanup()
		for _, arrow in ipairs(arrows) do
			if arrow.Parent then
				arrow:Destroy()
			end
		end
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		if beam.Parent then
			beam:Destroy()
		end
		if attachment0.Parent then
			attachment0:Destroy()
		end
		if attachment1.Parent then
			attachment1:Destroy()
		end
	end
	
	-- Check if player claims a tycoon
	local checkConnection
	checkConnection = RunService.Heartbeat:Connect(function()
		-- Check all tycoons to see if player owns one
		for _, tycoon in ipairs(tycoons) do
			if tycoon:FindFirstChild("Owner") and tycoon.Owner.Value == player then
				claimed = true
				checkConnection:Disconnect()
				cleanup()
				
				-- Show success message
				if player.Character and player.Character:FindFirstChild("Head") then
					local successBillboard = Instance.new("BillboardGui")
					successBillboard.Size = UDim2.new(0, 300, 0, 50)
					successBillboard.StudsOffset = Vector3.new(0, 3, 0)
					successBillboard.AlwaysOnTop = true
					successBillboard.Parent = player.Character.Head
					
					local successText = Instance.new("TextLabel")
					successText.Size = UDim2.new(1, 0, 1, 0)
					successText.BackgroundTransparency = 1
					successText.Text = "✅ TYCOON CLAIMED!"
					successText.TextScaled = true
					successText.TextColor3 = Color3.fromRGB(0, 255, 0)
					successText.TextStrokeColor3 = Color3.new(0, 0, 0)
					successText.TextStrokeTransparency = 0
					successText.Font = Enum.Font.SourceSansBold
					successText.Parent = successBillboard
					
					-- Fade out
					TweenService:Create(successText, TweenInfo.new(2, Enum.EasingStyle.Quad), {
						TextTransparency = 1,
						TextStrokeTransparency = 1
					}):Play()
					
					Debris:AddItem(successBillboard, 2)
				end
				
				return
			end
		end
	end)
	
	-- Auto cleanup after time limit
	task.delay(SHOW_FOR_SECONDS, function()
		if not claimed then
			checkConnection:Disconnect()
			cleanup()
		end
	end)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
	-- Only show for truly new players (low playtime, first join, etc)
	player.CharacterAdded:Connect(function(character)
		-- Check if they already own a tycoon
		local tycoons = findAllTycoons()
		local ownsATycoon = false
		
		for _, tycoon in ipairs(tycoons) do
			if tycoon:FindFirstChild("Owner") and tycoon.Owner.Value == player then
				ownsATycoon = true
				break
			end
		end
		
		-- Only show arrows if they don't own a tycoon
		if not ownsATycoon then
			task.spawn(function()
				showArrowsForPlayer(player)
			end)
		end
	end)
end)