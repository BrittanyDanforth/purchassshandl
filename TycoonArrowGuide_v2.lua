--[[
	Smart Tycoon Arrow Guide System v2
	- Shows 3D arrows pointing to available tycoons at spawn
	- Works with your touch gate system
	- Handles 3 main spawn tycoons + underground one
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local ARROW_COLOR = Color3.fromRGB(0, 255, 127) -- Bright green
local ARROW_GLOW_COLOR = Color3.fromRGB(150, 255, 200) -- Light green glow
local ARROW_HEIGHT_OFFSET = 12 -- Height above gate
local SHOW_DURATION = 90 -- Show for 90 seconds or until claimed
local PULSE_SPEED = 2 -- Speed of pulsing animation

-- Find all tycoons with gates
local function findAllTycoonGates()
	local gates = {}
	
	-- Search common tycoon locations
	for _, obj in ipairs(workspace:GetDescendants()) do
		-- Look for gate models - your gates are named "Touch to claim!"
		if obj:IsA("Model") and (obj.Name == "Touch to claim!" or obj.Name:lower():find("gate") or obj.Name:lower():find("claim")) then
			-- Check if it has the touch part setup
			local touchPart = obj:FindFirstChild("Head")
			if touchPart and obj.Parent and obj.Parent.Parent then
				local tycoon = obj.Parent.Parent
				-- Verify it's a tycoon by checking for Owner value
				if tycoon:FindFirstChild("Owner") then
					table.insert(gates, {
						gate = obj,
						touchPart = touchPart,
						tycoon = tycoon,
						position = touchPart.Position
					})
				end
			end
		end
	end
	
	return gates
end

-- Create 3D arrow above gate
local function createGateArrow(gateData)
	local model = Instance.new("Model")
	model.Name = "TycoonArrow_" .. gateData.tycoon.Name
	
	-- Base platform (circle)
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Shape = Enum.PartType.Cylinder
	platform.Size = Vector3.new(0.5, 8, 8)
	platform.Material = Enum.Material.ForceField
	platform.Color = ARROW_COLOR
	platform.Transparency = 0.3
	platform.Anchored = true
	platform.CanCollide = false
	platform.CFrame = CFrame.new(gateData.position) * CFrame.Angles(0, 0, math.rad(90))
	platform.Parent = model
	
	-- Arrow pointing down (3 parts for better visibility)
	local arrow = Instance.new("Model")
	arrow.Name = "Arrow"
	arrow.Parent = model
	
	-- Arrow shaft
	local shaft = Instance.new("Part")
	shaft.Name = "Shaft"
	shaft.Size = Vector3.new(2, 6, 2)
	shaft.Material = Enum.Material.Neon
	shaft.Color = ARROW_COLOR
	shaft.Anchored = true
	shaft.CanCollide = false
	shaft.CFrame = CFrame.new(gateData.position + Vector3.new(0, ARROW_HEIGHT_OFFSET, 0))
	shaft.Parent = arrow
	
	-- Arrow head (cone)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(4, 3, 4)
	head.Material = Enum.Material.Neon
	head.Color = ARROW_COLOR
	head.Anchored = true
	head.CanCollide = false
	
	-- Create cone mesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://1033714"
	mesh.Scale = Vector3.new(4, 4, 4)
	mesh.Parent = head
	
	head.CFrame = CFrame.new(gateData.position + Vector3.new(0, ARROW_HEIGHT_OFFSET - 4.5, 0)) * CFrame.Angles(math.rad(180), 0, 0)
	head.Parent = arrow
	
	-- Glow effects
	local shaftGlow = Instance.new("PointLight")
	shaftGlow.Brightness = 3
	shaftGlow.Color = ARROW_GLOW_COLOR
	shaftGlow.Range = 15
	shaftGlow.Parent = shaft
	
	local headGlow = Instance.new("PointLight")
	headGlow.Brightness = 4
	headGlow.Color = ARROW_GLOW_COLOR
	headGlow.Range = 20
	headGlow.Parent = head
	
	-- Rotating ring around arrow
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Size = Vector3.new(6, 0.5, 6)
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.ForceField
	ring.Color = ARROW_COLOR
	ring.Transparency = 0.5
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = CFrame.new(gateData.position + Vector3.new(0, ARROW_HEIGHT_OFFSET, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	ring.Parent = model
	
	-- Floating text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 300, 0, 100)
	billboard.StudsOffset = Vector3.new(0, ARROW_HEIGHT_OFFSET + 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = shaft
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = billboard
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -10, 0.5, 0)
	text.Position = UDim2.new(0, 5, 0, 0)
	text.BackgroundTransparency = 1
	text.Text = "CLAIM THIS TYCOON!"
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextStrokeTransparency = 0
	text.Font = Enum.Font.SourceSansBold
	text.Parent = billboard
	
	local tycoonName = Instance.new("TextLabel")
	tycoonName.Size = UDim2.new(1, -10, 0.5, 0)
	tycoonName.Position = UDim2.new(0, 5, 0.5, 0)
	tycoonName.BackgroundTransparency = 1
	tycoonName.Text = gateData.tycoon.Name
	tycoonName.TextScaled = true
	tycoonName.TextColor3 = ARROW_COLOR
	tycoonName.TextStrokeColor3 = Color3.new(0, 0, 0)
	tycoonName.TextStrokeTransparency = 0
	tycoonName.Font = Enum.Font.SourceSansBold
	tycoonName.Parent = billboard
	
	return model
end

-- Animate arrows
local function animateArrows(arrows)
	local startTime = tick()
	
	return RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		
		for _, arrowData in ipairs(arrows) do
			if arrowData.model and arrowData.model.Parent then
				-- Rotate ring
				local ring = arrowData.model:FindFirstChild("Ring")
				if ring then
					ring.CFrame = ring.CFrame * CFrame.Angles(0, math.rad(2), 0)
				end
				
				-- Pulse arrow
				local arrow = arrowData.model:FindFirstChild("Arrow")
				if arrow then
					local scale = 1 + math.sin(elapsed * PULSE_SPEED) * 0.1
					for _, part in ipairs(arrow:GetChildren()) do
						if part:IsA("Part") then
							-- Pulse transparency
							if part.Name == "Shaft" then
								part.Transparency = 0.1 + math.sin(elapsed * PULSE_SPEED) * 0.2
							elseif part.Name == "Head" then
								part.Transparency = 0.2 + math.sin(elapsed * PULSE_SPEED) * 0.2
							end
							
							-- Pulse glow
							local light = part:FindFirstChildOfClass("PointLight")
							if light then
								light.Brightness = light.Name == "Shaft" and 3 or 4
								light.Brightness = light.Brightness + math.sin(elapsed * PULSE_SPEED * 2) * 1
							end
						end
					end
				end
				
				-- Bob up and down
				local platform = arrowData.model:FindFirstChild("Platform")
				if platform then
					local baseY = arrowData.gate.position.Y
					platform.CFrame = CFrame.new(
						arrowData.gate.position.X,
						baseY + math.sin(elapsed * 1.5) * 0.5,
						arrowData.gate.position.Z
					) * CFrame.Angles(0, 0, math.rad(90))
				end
			end
		end
	end)
end

-- Main system
local activeArrows = {}
local animationConnection = nil

-- Update arrows based on available tycoons
local function updateArrows()
	-- Clean up old arrows
	for _, arrowData in ipairs(activeArrows) do
		if arrowData.model then
			arrowData.model:Destroy()
		end
	end
	activeArrows = {}
	
	-- Find all gates
	local gates = findAllTycoonGates()
	
	-- Create arrows only for unclaimed tycoons
	for _, gateData in ipairs(gates) do
		if gateData.tycoon.Owner.Value == nil then
			-- Check if gate is visible (not claimed)
			if gateData.touchPart.Transparency < 1 then
				local arrow = createGateArrow(gateData)
				arrow.Parent = workspace
				
				table.insert(activeArrows, {
					model = arrow,
					gate = gateData,
					tycoon = gateData.tycoon
				})
			end
		end
	end
	
	-- Start animation if we have arrows
	if #activeArrows > 0 and not animationConnection then
		animationConnection = animateArrows(activeArrows)
	elseif #activeArrows == 0 and animationConnection then
		animationConnection:Disconnect()
		animationConnection = nil
	end
end

-- Monitor for changes
local function setupMonitoring()
	-- Initial update
	updateArrows()
	
	-- Update every few seconds
	local updateLoop = RunService.Heartbeat:Connect(function()
		-- Check if any arrows need to be removed (tycoon was claimed)
		local needsUpdate = false
		
		for i = #activeArrows, 1, -1 do
			local arrowData = activeArrows[i]
			if arrowData.tycoon.Owner.Value ~= nil or arrowData.gate.touchPart.Transparency >= 1 then
				-- Tycoon was claimed, remove arrow
				if arrowData.model then
					-- Fade out effect
					local arrow = arrowData.model:FindFirstChild("Arrow")
					if arrow then
						for _, part in ipairs(arrow:GetChildren()) do
							if part:IsA("Part") then
								TweenService:Create(part, TweenInfo.new(0.5), {
									Transparency = 1
								}):Play()
							end
						end
					end
					
					Debris:AddItem(arrowData.model, 0.5)
				end
				
				table.remove(activeArrows, i)
				needsUpdate = true
			end
		end
		
		-- Also check for new unclaimed tycoons
		if tick() % 5 < 0.1 then -- Check every 5 seconds
			updateArrows()
		end
	end)
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
	-- Show welcome message
	player.CharacterAdded:Connect(function(character)
		wait(2) -- Let them load in
		
		-- Check if they own a tycoon
		local playerStats = ServerStorage.PlayerMoney:FindFirstChild(player.Name)
		if playerStats and playerStats:FindFirstChild("OwnsTycoon") then
			if playerStats.OwnsTycoon.Value == nil then
				-- Show helper message
				local head = character:FindFirstChild("Head")
				if head then
					local billboard = Instance.new("BillboardGui")
					billboard.Size = UDim2.new(0, 400, 0, 60)
					billboard.StudsOffset = Vector3.new(0, 3, 0)
					billboard.AlwaysOnTop = true
					billboard.Parent = head
					
					local text = Instance.new("TextLabel")
					text.Size = UDim2.new(1, 0, 1, 0)
					text.BackgroundColor3 = Color3.new(0, 0, 0)
					text.BackgroundTransparency = 0.3
					text.Text = "👇 Look for the GREEN ARROWS to claim a tycoon! 👇"
					text.TextScaled = true
					text.TextColor3 = ARROW_COLOR
					text.TextStrokeColor3 = Color3.new(0, 0, 0)
					text.TextStrokeTransparency = 0
					text.Font = Enum.Font.SourceSansBold
					text.Parent = billboard
					
					-- Fade out after 8 seconds
					wait(6)
					TweenService:Create(text, TweenInfo.new(2), {
						TextTransparency = 1,
						BackgroundTransparency = 1
					}):Play()
					
					Debris:AddItem(billboard, 2)
				end
			end
		end
	end)
end)

-- Start the system
setupMonitoring()
print("✅ Tycoon Arrow Guide v2 loaded - Arrows will appear above unclaimed tycoons!")