-- MINIMAL Auto-Collect Addon - ADD THIS TO YOUR EXISTING PURCHASEHANDLER
-- Just paste this code at the bottom of your PurchaseHandler script

-- ========================================
-- AUTO-COLLECT ADDON (Minimal, no breaking changes)
-- ========================================

-- Auto-collect gamepass ID
local AUTO_COLLECT_GAMEPASS_ID = 1412171840
local autoCollectConnection = nil
local hasAutoCollect = false

-- Format numbers (if you don't already have this function)
local function formatNumber(n)
	local formatted = tostring(n)
	while true do
		local newFormatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		formatted = newFormatted
		if k == 0 then break end
	end
	return formatted
end

-- Check if player owns auto-collect
local function checkAutoCollectOwnership(player)
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_COLLECT_GAMEPASS_ID)
	end)
	return success and hasPass
end

-- Perform auto collection (simulates touching the giver)
local function performAutoCollect()
	if not currentOwner then return end
	if Money.Value <= 0 then return end
	
	local playerStats = ServerStorage.PlayerMoney:FindFirstChild(currentOwner.Name)
	if not playerStats then return end
	
	-- Transfer money
	local moneyToCollect = Money.Value
	playerStats.Value = playerStats.Value + moneyToCollect
	Money.Value = 0
	
	-- Visual feedback on giver
	local giver = essentials:FindFirstChild("Giver")
	if giver then
		-- Play quiet sound
		playSound(giver, "success", 0.1)
		
		-- Show collected amount
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 100, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.Parent = giver
		
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = "+$" .. formatNumber(moneyToCollect)
		text.TextScaled = true
		text.TextColor3 = Color3.new(0, 1, 0)
		text.Font = Enum.Font.SourceSansBold
		text.Parent = billboard
		
		-- Animate up and fade
		TweenService:Create(billboard, TweenInfo.new(0.8), {StudsOffset = Vector3.new(0, 6, 0)}):Play()
		TweenService:Create(text, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
		
		Debris:AddItem(billboard, 0.8)
	end
end

-- Setup auto-collect
local function setupAutoCollect()
	-- Clean up old connection
	if autoCollectConnection then
		autoCollectConnection:Disconnect()
		autoCollectConnection = nil
	end
	
	-- Only works for owner
	if not currentOwner or script.Parent.Owner.Value ~= currentOwner then
		return
	end
	
	-- Connect to money changes
	autoCollectConnection = Money.Changed:Connect(function(newValue)
		if newValue > 0 and currentOwner and script.Parent.Owner.Value == currentOwner then
			-- Small delay to batch multiple cash parts
			task.wait(0.1)
			performAutoCollect()
		end
	end)
	
	-- Collect any existing money
	if Money.Value > 0 then
		performAutoCollect()
	end
	
	print("🤖 Auto-Collect activated for", currentOwner.Name)
end

-- Modify your existing owner changed connection
local originalOwnerConnection = connections.owner
connections.owner.Disconnect()

connections.owner = tycoonOwner.Changed:Connect(function()
	local newOwner = tycoonOwner.Value
	
	-- Clean up auto-collect when owner leaves
	if newOwner == nil and currentOwner ~= nil then
		if autoCollectConnection then
			autoCollectConnection:Disconnect()
			autoCollectConnection = nil
		end
		hasAutoCollect = false
		
		-- Your existing code
		print("👋 Owner left, resetting purchases...")
		resetTycoonPurchases()
		currentOwner = nil
		
	elseif newOwner ~= nil and currentOwner == nil then
		-- New owner
		currentOwner = newOwner
		print("👤 New owner:", currentOwner.Name)
		
		-- Your existing code
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
		
		-- Check for auto-collect
		if checkAutoCollectOwnership(newOwner) then
			hasAutoCollect = true
			setupAutoCollect()
		end
	end
end)

-- Handle gamepass purchase
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if gamePassId == AUTO_COLLECT_GAMEPASS_ID and wasPurchased and player == currentOwner then
		hasAutoCollect = true
		setupAutoCollect()
	end
end)

-- Add to your reset function
local originalReset = resetTycoonPurchases
function resetTycoonPurchases()
	-- Clean up auto-collect
	if autoCollectConnection then
		autoCollectConnection:Disconnect()
		autoCollectConnection = nil
	end
	hasAutoCollect = false
	
	-- Call original reset
	originalReset()
end

print("🤖 Auto-Collect addon loaded! Gamepass ID:", AUTO_COLLECT_GAMEPASS_ID)