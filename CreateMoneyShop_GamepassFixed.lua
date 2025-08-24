--[[
	🎀 SANRIO SHOP — GAMEPASS PURCHASE FIX
	Fixes the stuck "Processing" issue and adds gamepass thumbnails
--]]

-- Changes made:
-- 1. Fixed the stuck "Processing" issue after gamepass purchase
-- 2. Added proper gamepass thumbnail loading
-- 3. Improved ownership checking and UI refresh
-- 4. Added retry logic for ownership verification

-- Find the original file and make these changes:

-- 1. Replace the MarketplaceService.PromptGamePassPurchaseFinished handler (around line 776):
--[[
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(userId, gamePassId, wasPurchased)
	if userId ~= localPlayer.UserId then return end
	local cta = Pending.pass[gamePassId]
	
	-- Update button state
	if cta and cta.Parent then
		if wasPurchased then
			cta.Text = "Updating..."
			cta.Active = false
			cta.AutoButtonColor = false
		else
			cta.Text = "Purchase"
			cta.Active = true
			cta.AutoButtonColor = true
		end
	end
	
	Pending.pass[gamePassId] = nil
	
	-- Refresh the shop to update owned state
	if wasPurchased then
		-- Wait a bit for Roblox to update ownership
		task.wait(1)
		
		-- Force refresh ownership check with retry
		local retries = 0
		local owns = false
		
		repeat
			local success, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, gamePassId)
			end)
			
			if success then
				owns = result
			end
			
			if not owns and retries < 3 then
				retries = retries + 1
				task.wait(0.5)
			end
		until owns or retries >= 3
		
		-- Clear and rebuild the gamepass page
		if passPage then
			for _, child in ipairs(passPage:GetChildren()) do
				child:Destroy()
			end
			buildPasses()
		end
		
		-- Also rebuild home page if it has featured gamepasses
		if homePage then
			for _, child in ipairs(homePage:GetChildren()) do
				child:Destroy()
			end
			buildHome()
		end
	end
end)
--]]

-- 2. Update the icon loading in makeItemCard function (around line 563-568):
--[[
	-- Icon plate
	local plate = UI.frame({Name = "IconPlate", Size = UDim2.fromOffset(80,80), Position = UDim2.new(0,20,0,24), BackgroundColor3 = Utils.blend(accent, Color3.new(1,1,1), 0.9), CornerRadius = UDim.new(1,0), ZIndex = 14})
	plate.Parent = inner
	
	-- Use proper gamepass thumbnail for gamepasses
	local iconId
	if kind == "pass" and item.id then
		-- Use Roblox gamepass thumbnail API
		iconId = "rbxthumb://type=GamePass&id=" .. tostring(item.id) .. "&w=150&h=150"
	else
		iconId = (item.icon and Asset.valid(item.icon)) and item.icon or ((kind == "pass") and Asset.list.iconPass or Asset.list.iconCash)
	end
	
	-- Don't apply color tint to gamepass thumbnails
	local iconColor = (kind == "pass" and item.id) and Color3.new(1,1,1) or ((kind == "pass") and Color3.fromRGB(240,240,255) or Theme.c("text"))
	local icon = UI.image({Name = "Icon", Image = iconId, ImageColor3 = iconColor, Size = UDim2.fromOffset(48,48), Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), ZIndex = 15})
	icon.Parent = plate
--]]

-- 3. Update the purchase button handler (around line 653-662):
--[[
	else
		-- Purchase button logic
		cta.MouseButton1Click:Connect(function()
			-- Double-check ownership before prompting
			if kind == "pass" then
				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, item.id)
				end)
				
				if success and owns then
					-- Already owns, just refresh
					cta.Text = "Owned"
					cta.Active = false
					cta.AutoButtonColor = false
					
					-- Refresh the shop
					task.wait(0.5)
					if passPage then
						for _, child in ipairs(passPage:GetChildren()) do
							child:Destroy()
						end
						buildPasses()
					end
					return
				end
			end
			
			cta.Text = "Processing…"
			cta.Active = false
			cta.AutoButtonColor = false
			
			if kind == "pass" then
				Pending.pass[item.id] = cta
				Utils.safe(function() MarketplaceService:PromptGamePassPurchase(localPlayer, item.id) end)
			else
				Pending.product[item.id] = cta
				Utils.safe(function() MarketplaceService:PromptProductPurchase(localPlayer, item.id) end)
			end
		end)
	end
--]]

-- 4. Add this helper function near the top of the script (after local functions):
--[[
local function refreshShopPages()
	-- Refresh all pages to update ownership states
	if passPage then
		for _, child in ipairs(passPage:GetChildren()) do
			child:Destroy()
		end
		buildPasses()
	end
	
	if homePage then
		for _, child in ipairs(homePage:GetChildren()) do
			child:Destroy()
		end
		buildHome()
	end
end
--]]

-- 5. Also update the ShopData.userOwnsPass function to add caching:
--[[
local ownedPassesCache = {}

ShopData.userOwnsPass = function(userId, passId)
	-- Check cache first
	local cacheKey = userId .. "_" .. passId
	if ownedPassesCache[cacheKey] ~= nil then
		return ownedPassesCache[cacheKey]
	end
	
	-- Check ownership
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
	end)
	
	if success then
		ownedPassesCache[cacheKey] = owns
		return owns
	end
	
	return false
end

-- Clear cache when shop opens
function Shop:open()
	-- Clear ownership cache
	ownedPassesCache = {}
	
	-- ... rest of the open function
end
--]]