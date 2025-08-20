-- Auto Collect Addon for PurchaseHandler
-- This code should be added to your existing PurchaseHandler script

-- Add this at the top with other services
local MarketplaceService = game:GetService("MarketplaceService")

-- Add this to your CONFIG table
-- AUTO_COLLECT_GAMEPASS_ID = 1412171840,
-- AUTO_COLLECT_RANGE = 50, -- Studs to collect cash from
-- AUTO_COLLECT_INTERVAL = 0.1, -- How often to check for cash

-- Add this with other tracking variables
local autoCollectConnections = {}
local playersWithAutoCollect = {}

-- Function to check if player owns auto-collect gamepass
local function checkAutoCollectOwnership(player)
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1412171840)
	end)
	
	if success and hasPass then
		return true
	end
	return false
end

-- Function to setup auto-collect for a player
local function setupAutoCollect(player)
	-- Clean up any existing connection
	if autoCollectConnections[player] then
		autoCollectConnections[player]:Disconnect()
		autoCollectConnections[player] = nil
	end
	
	-- Check if this is the tycoon owner
	if script.Parent.Owner.Value ~= player then
		return
	end
	
	print("🤖 Setting up auto-collect for", player.Name)
	
	-- Create the auto-collect loop
	autoCollectConnections[player] = RunService.Heartbeat:Connect(function()
		-- Verify player still owns the tycoon
		if script.Parent.Owner.Value ~= player then
			if autoCollectConnections[player] then
				autoCollectConnections[player]:Disconnect()
				autoCollectConnections[player] = nil
			end
			return
		end
		
		-- Get player character
		local character = player.Character
		if not character then return end
		
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end
		
		-- Check for cash parts near the player
		local collectorPosition = humanoidRootPart.Position
		local collectRange = 50 -- Auto-collect range in studs
		
		-- Look for cash in the dedicated folder
		for _, part in ipairs(cashPartsFolder:GetChildren()) do
			if part:FindFirstChild("Cash") and part:IsA("BasePart") then
				local distance = (part.Position - collectorPosition).Magnitude
				
				if distance <= collectRange and not collectedParts[part] then
					-- Mark as collected
					collectedParts[part] = true
					
					-- Add cash value
					local cashValue = part:FindFirstChild("Cash")
					if cashValue then
						Money.Value = Money.Value + cashValue.Value
						
						-- Create collection effect
						part.Anchored = true
						part.CanCollide = false
						part.CanTouch = false
						part.CanQuery = false
						
						-- Move part to player with tween
						local collectTween = TweenService:Create(
							part,
							TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
							{
								Position = collectorPosition,
								Size = part.Size * 0.5,
								Transparency = 1
							}
						)
						
						collectTween:Play()
						
						-- Fade out any visual effects
						for _, child in ipairs(part:GetDescendants()) do
							if child:IsA("Decal") or child:IsA("Texture") then
								TweenService:Create(child, TweenInfo.new(0.3), {Transparency = 1}):Play()
							elseif child:IsA("ParticleEmitter") then
								child.Enabled = false
							elseif child:IsA("PointLight") or child:IsA("SpotLight") then
								TweenService:Create(child, TweenInfo.new(0.3), {Brightness = 0}):Play()
							end
						end
						
						-- Destroy after animation
						collectTween.Completed:Connect(function()
							part:Destroy()
						end)
						
						-- Play collect sound (quieter for auto-collect)
						playSound(humanoidRootPart, "collect", 0.05)
					end
				end
			end
		end
		
		-- Also check workspace for any stray cash parts (fallback)
		local nearbyParts = workspace:GetPartBoundsInRadius(collectorPosition, collectRange)
		for _, part in ipairs(nearbyParts) do
			if part:FindFirstChild("Cash") and not collectedParts[part] then
				-- Same collection logic as above
				collectedParts[part] = true
				
				local cashValue = part:FindFirstChild("Cash")
				if cashValue then
					Money.Value = Money.Value + cashValue.Value
					
					part.Anchored = true
					part.CanCollide = false
					part.CanTouch = false
					part.CanQuery = false
					
					local collectTween = TweenService:Create(
						part,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{
							Position = collectorPosition,
							Size = part.Size * 0.5,
							Transparency = 1
						}
					)
					
					collectTween:Play()
					
					for _, child in ipairs(part:GetDescendants()) do
						if child:IsA("Decal") or child:IsA("Texture") then
							TweenService:Create(child, TweenInfo.new(0.3), {Transparency = 1}):Play()
						elseif child:IsA("ParticleEmitter") then
							child.Enabled = false
						elseif child:IsA("PointLight") or child:IsA("SpotLight") then
							TweenService:Create(child, TweenInfo.new(0.3), {Brightness = 0}):Play()
						end
					end
					
					collectTween.Completed:Connect(function()
						part:Destroy()
					end)
					
					playSound(humanoidRootPart, "collect", 0.05)
				end
			end
		end
	end)
	
	-- Add visual indicator
	local character = player.Character
	if character then
		-- Create auto-collect aura effect
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			-- Clean up old effect
			local oldEffect = humanoidRootPart:FindFirstChild("AutoCollectEffect")
			if oldEffect then
				oldEffect:Destroy()
			end
			
			-- Create new effect
			local attachment = Instance.new("Attachment")
			attachment.Name = "AutoCollectEffect"
			attachment.Parent = humanoidRootPart
			
			-- Create particle emitter for visual feedback
			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Rate = 20
			particles.Lifetime = NumberRange.new(1, 2)
			particles.VelocityInheritance = 0
			particles.EmissionDirection = Enum.NormalId.Top
			particles.Speed = NumberRange.new(1, 2)
			particles.SpreadAngle = Vector2.new(360, 360)
			particles.Color = ColorSequence.new(Color3.new(0, 1, 0))
			particles.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.5, 0.3),
				NumberSequenceKeypoint.new(1, 0)
			}
			particles.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(1, 1)
			}
			particles.Parent = attachment
			
			-- Create selection box for range indicator
			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Name = "AutoCollectRange"
			selectionBox.Adornee = humanoidRootPart
			selectionBox.Color3 = Color3.new(0, 1, 0)
			selectionBox.Transparency = 0.9
			selectionBox.LineThickness = 0.1
			selectionBox.Parent = humanoidRootPart
		end
	end
	
	playersWithAutoCollect[player] = true
end

-- Add this to your existing owner changed connection
-- Modify your existing owner connection to include auto-collect check
local originalOwnerConnection = connections.owner
connections.owner = tycoonOwner.Changed:Connect(function()
	local newOwner = tycoonOwner.Value
	
	-- Call original functionality first
	if originalOwnerConnection then
		-- Your existing owner change code here
	end
	
	-- Handle auto-collect
	if newOwner then
		-- Check if new owner has auto-collect
		if checkAutoCollectOwnership(newOwner) then
			setupAutoCollect(newOwner)
		end
	else
		-- Clean up auto-collect when owner leaves
		if currentOwner and autoCollectConnections[currentOwner] then
			autoCollectConnections[currentOwner]:Disconnect()
			autoCollectConnections[currentOwner] = nil
			playersWithAutoCollect[currentOwner] = nil
		end
	end
end)

-- Listen for gamepass purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if gamePassId == 1412171840 and wasPurchased then
		-- Check if this player owns this tycoon
		if script.Parent.Owner.Value == player then
			setupAutoCollect(player)
			
			-- Notify player
			local character = player.Character
			if character then
				local head = character:FindFirstChild("Head")
				if head then
					-- Success notification
					local billboard = Instance.new("BillboardGui")
					billboard.Size = UDim2.new(0, 200, 0, 50)
					billboard.StudsOffset = Vector3.new(0, 3, 0)
					billboard.Parent = head
					
					local text = Instance.new("TextLabel")
					text.Size = UDim2.new(1, 0, 1, 0)
					text.BackgroundTransparency = 1
					text.Text = "✅ Auto-Collect Activated!"
					text.TextScaled = true
					text.TextColor3 = Color3.new(0, 1, 0)
					text.Font = Enum.Font.SourceSansBold
					text.Parent = billboard
					
					-- Fade out
					task.wait(2)
					TweenService:Create(text, TweenInfo.new(1), {TextTransparency = 1}):Play()
					task.wait(1)
					billboard:Destroy()
				end
			end
		end
	end
end)

-- Add cleanup to your reset function
-- Add this to your resetTycoonPurchases function
local function cleanupAutoCollect()
	for player, connection in pairs(autoCollectConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	autoCollectConnections = {}
	playersWithAutoCollect = {}
end

-- Character respawn handling
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1) -- Wait for character to load
		
		-- Re-setup auto-collect if they own it and this tycoon
		if script.Parent.Owner.Value == player and playersWithAutoCollect[player] then
			setupAutoCollect(player)
		end
	end)
end)

print("🤖 Auto-Collect addon loaded! Gamepass ID: 1412171840")