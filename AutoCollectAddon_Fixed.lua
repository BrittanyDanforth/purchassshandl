-- Auto Collect Addon for PurchaseHandler (FIXED VERSION)
-- This automatically claims money from the collector without walking to it

-- Add this at the top with other services
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

-- Add this with other tracking variables
local autoCollectConnections = {}
local AUTO_COLLECT_GAMEPASS_ID = 1412171840

-- Function to check if player owns auto-collect gamepass
local function checkAutoCollectOwnership(player)
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_COLLECT_GAMEPASS_ID)
	end)
	
	if success and hasPass then
		return true
	end
	return false
end

-- Function to setup auto-collect for the tycoon owner
local function setupAutoCollect(player)
	-- Clean up any existing connection
	if autoCollectConnections[player] then
		autoCollectConnections[player]:Disconnect()
		autoCollectConnections[player] = nil
	end
	
	-- Verify this is the tycoon owner
	if script.Parent.Owner.Value ~= player then
		return
	end
	
	print("🤖 Auto-Collect activated for", player.Name)
	
	-- Create auto-collect loop that simulates standing on the collector
	autoCollectConnections[player] = RunService.Heartbeat:Connect(function()
		-- Verify player still owns the tycoon
		if script.Parent.Owner.Value ~= player then
			if autoCollectConnections[player] then
				autoCollectConnections[player]:Disconnect()
				autoCollectConnections[player] = nil
			end
			return
		end
		
		-- Check if there's money to collect
		if Money.Value <= 0 then
			return
		end
		
		-- Get player stats
		local playerStats = ServerStorage.PlayerMoney:FindFirstChild(player.Name)
		if not playerStats then return end
		
		-- Simulate the collection process from the Giver
		local moneyToCollect = Money.Value
		
		-- Add money to player
		playerStats.Value = playerStats.Value + moneyToCollect
		Money.Value = 0
		
		-- Visual feedback on the collector
		local giver = essentials:FindFirstChild("Giver")
		if giver then
			-- Quick color flash
			local originalColor = giver.BrickColor
			giver.BrickColor = CONFIG.COLLECTOR_ACTIVE_COLOR
			
			-- Play quiet collect sound
			playSound(giver, "success", 0.1)
			
			-- Create floating text effect
			local attachment = Instance.new("Attachment")
			attachment.Parent = giver
			
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(0, 100, 0, 40)
			billboard.StudsOffset = Vector3.new(0, 2, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = attachment
			
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Text = "+$" .. formatNumber(moneyToCollect)
			textLabel.TextScaled = true
			textLabel.TextColor3 = Color3.new(0, 1, 0)
			textLabel.Font = Enum.Font.SourceSansBold
			textLabel.Parent = billboard
			
			-- Animate the text floating up
			local floatTween = TweenService:Create(
				attachment,
				TweenInfo.new(1, Enum.EasingStyle.Linear),
				{WorldPosition = giver.Position + Vector3.new(0, 5, 0)}
			)
			
			local fadeTween = TweenService:Create(
				textLabel,
				TweenInfo.new(1, Enum.EasingStyle.Linear),
				{TextTransparency = 1}
			)
			
			floatTween:Play()
			fadeTween:Play()
			
			-- Cleanup
			floatTween.Completed:Connect(function()
				billboard:Destroy()
				attachment:Destroy()
			end)
			
			-- Reset color after a moment
			task.wait(0.1)
			giver.BrickColor = originalColor
		end
	end)
	
	-- Add visual indicator to player
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			-- Clean up old effect
			local oldEffect = humanoidRootPart:FindFirstChild("AutoCollectEffect")
			if oldEffect then
				oldEffect:Destroy()
			end
			
			-- Create auto-collect aura
			local attachment = Instance.new("Attachment")
			attachment.Name = "AutoCollectEffect"
			attachment.Parent = humanoidRootPart
			
			-- Sparkle effect
			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Rate = 10
			particles.Lifetime = NumberRange.new(2, 3)
			particles.VelocityInheritance = 0
			particles.EmissionDirection = Enum.NormalId.Top
			particles.Speed = NumberRange.new(0.5, 1)
			particles.SpreadAngle = Vector2.new(45, 45)
			particles.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.new(1, 0.8, 0)),
				ColorSequenceKeypoint.new(1, Color3.new(0, 1, 0))
			}
			particles.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 0)
			}
			particles.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(1, 1)
			}
			particles.LightEmission = 0.5
			particles.Parent = attachment
		end
	end
	
	-- Add indicator to the collector
	local giver = essentials:FindFirstChild("Giver")
	if giver then
		local autoIndicator = Instance.new("BillboardGui")
		autoIndicator.Name = "AutoCollectIndicator"
		autoIndicator.Size = UDim2.new(0, 80, 0, 30)
		autoIndicator.StudsOffset = Vector3.new(0, 4, 0)
		autoIndicator.AlwaysOnTop = true
		autoIndicator.Parent = giver
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "AUTO ✓"
		label.TextScaled = true
		label.TextColor3 = Color3.new(0, 1, 0)
		label.Font = Enum.Font.SourceSansBold
		label.TextStrokeTransparency = 0.5
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.Parent = autoIndicator
		
		-- Pulse animation
		spawn(function()
			while autoIndicator.Parent do
				TweenService:Create(
					label,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{TextTransparency = 0.3}
				):Play()
				wait(1)
				TweenService:Create(
					label,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{TextTransparency = 0}
				):Play()
				wait(1)
			end
		end)
	end
end

-- Function to cleanup auto-collect
local function cleanupAutoCollect(player)
	-- Disconnect the collection loop
	if autoCollectConnections[player] then
		autoCollectConnections[player]:Disconnect()
		autoCollectConnections[player] = nil
	end
	
	-- Remove visual effects from player
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local effect = humanoidRootPart:FindFirstChild("AutoCollectEffect")
			if effect then
				effect:Destroy()
			end
		end
	end
	
	-- Remove indicator from collector
	local giver = essentials:FindFirstChild("Giver")
	if giver then
		local indicator = giver:FindFirstChild("AutoCollectIndicator")
		if indicator then
			indicator:Destroy()
		end
	end
	
	print("🤖 Auto-Collect deactivated for", player.Name)
end

-- Modify your existing owner connection to include auto-collect
local originalOwnerChanged = connections.owner
connections.owner = tycoonOwner.Changed:Connect(function()
	local newOwner = tycoonOwner.Value
	
	-- Handle owner leaving
	if newOwner == nil and currentOwner ~= nil then
		-- Clean up auto-collect for leaving owner
		cleanupAutoCollect(currentOwner)
		
		-- Your existing reset code...
		print("👋 Owner left, resetting purchases...")
		resetTycoonPurchases()
		currentOwner = nil
		
	elseif newOwner ~= nil and currentOwner == nil then
		-- New owner joined
		currentOwner = newOwner
		print("👤 New owner:", currentOwner.Name)
		
		-- Your existing setup code...
		local playerStats = ServerStorage.PlayerMoney:FindFirstChild(newOwner.Name)
		if playerStats then
			updateButtonColorsTiered(playerStats)
			
			if connections.money then
				connections.money:Disconnect()
			end
			
			connections.money = playerStats.Changed:Connect(function()
				if canPerformAction(newOwner, "colorUpdate", CONFIG.BUTTON_UPDATE_THROTTLE) then
					updateButtonColorsTiered(playerStats)
				end
			end)
		end
		
		-- Check if new owner has auto-collect
		if checkAutoCollectOwnership(newOwner) then
			setupAutoCollect(newOwner)
		end
	end
end)

-- Listen for gamepass purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if gamePassId == AUTO_COLLECT_GAMEPASS_ID and wasPurchased then
		-- Check if this player owns this tycoon
		if script.Parent.Owner.Value == player then
			setupAutoCollect(player)
			
			-- Success notification
			local character = player.Character
			if character then
				local head = character:FindFirstChild("Head")
				if head then
					local billboard = Instance.new("BillboardGui")
					billboard.Size = UDim2.new(0, 200, 0, 50)
					billboard.StudsOffset = Vector3.new(0, 3, 0)
					billboard.AlwaysOnTop = true
					billboard.Parent = head
					
					local text = Instance.new("TextLabel")
					text.Size = UDim2.new(1, 0, 1, 0)
					text.BackgroundTransparency = 1
					text.Text = "✅ Auto-Collect Activated!"
					text.TextScaled = true
					text.TextColor3 = Color3.new(0, 1, 0)
					text.Font = Enum.Font.SourceSansBold
					text.TextStrokeTransparency = 0.5
					text.TextStrokeColor3 = Color3.new(0, 0, 0)
					text.Parent = billboard
					
					-- Fade out
					task.wait(2)
					TweenService:Create(text, TweenInfo.new(1), {
						TextTransparency = 1,
						TextStrokeTransparency = 1
					}):Play()
					task.wait(1)
					billboard:Destroy()
				end
			end
		end
	end
end)

-- Handle character respawning
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1) -- Wait for character to load
		
		-- Re-setup auto-collect effects if they own it and this tycoon
		if script.Parent.Owner.Value == player and checkAutoCollectOwnership(player) then
			-- Just re-add the visual effect, the collection loop continues
			local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			if humanoidRootPart then
				local attachment = Instance.new("Attachment")
				attachment.Name = "AutoCollectEffect"
				attachment.Parent = humanoidRootPart
				
				local particles = Instance.new("ParticleEmitter")
				particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				particles.Rate = 10
				particles.Lifetime = NumberRange.new(2, 3)
				particles.VelocityInheritance = 0
				particles.EmissionDirection = Enum.NormalId.Top
				particles.Speed = NumberRange.new(0.5, 1)
				particles.SpreadAngle = Vector2.new(45, 45)
				particles.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.new(1, 0.8, 0)),
					ColorSequenceKeypoint.new(1, Color3.new(0, 1, 0))
				}
				particles.Size = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 0.3),
					NumberSequenceKeypoint.new(0.5, 0.5),
					NumberSequenceKeypoint.new(1, 0)
				}
				particles.Transparency = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 0.8),
					NumberSequenceKeypoint.new(1, 1)
				}
				particles.LightEmission = 0.5
				particles.Parent = attachment
			end
		end
	end)
end)

-- Add to your reset function
local originalReset = resetTycoonPurchases
function resetTycoonPurchases()
	-- Clean up all auto-collect connections
	for player, connection in pairs(autoCollectConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	autoCollectConnections = {}
	
	-- Remove any auto-collect indicators
	local giver = essentials:FindFirstChild("Giver")
	if giver then
		local indicator = giver:FindFirstChild("AutoCollectIndicator")
		if indicator then
			indicator:Destroy()
		end
	end
	
	-- Call original reset
	originalReset()
end

print("🤖 Auto-Collect addon loaded! Gamepass ID:", AUTO_COLLECT_GAMEPASS_ID)
print("   - Automatically claims money from collector")
print("   - No need to walk to the collector!")
print("   - Visual effects on player and collector")