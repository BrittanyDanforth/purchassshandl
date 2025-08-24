-- Quick fix to ensure shop button is visible
-- Add this at the beginning of your CreateMoneyShop script or run it separately

local function fixShopButton()
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Wait a bit for GUI to load
	task.wait(1)
	
	-- Find the shop button
	local buttonScreen = playerGui:FindFirstChild("SANRIO_SHOP_BUTTON")
	if not buttonScreen then
		warn("Shop button ScreenGui not found!")
		return
	end
	
	-- Make sure it's on top
	buttonScreen.DisplayOrder = 10000
	buttonScreen.Enabled = true
	
	-- Find the actual button
	local shopButton = buttonScreen:FindFirstChild("ShopToggle")
	if not shopButton then
		warn("ShopToggle button not found!")
		return
	end
	
	-- Make button more visible and move it to a better position
	shopButton.Position = UDim2.new(0.1, 0, 0.1, 0) -- Top left corner
	shopButton.Size = UDim2.new(0, 200, 0, 60) -- Bigger size
	shopButton.ZIndex = 1000
	shopButton.Visible = true
	shopButton.Active = true
	
	-- Make sure all children are visible
	for _, child in ipairs(shopButton:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.Visible = true
			child.ZIndex = child.ZIndex + 1000
		end
	end
	
	-- Add a bright outline to make it stand out
	local existingStroke = shopButton:FindFirstChildOfClass("UIStroke")
	if existingStroke then
		existingStroke.Thickness = 5
		existingStroke.Color = Color3.new(1, 1, 0) -- Yellow outline
	end
	
	print("✅ Shop button fixed! Look in the top-left corner.")
end

-- Run the fix
fixShopButton()

-- Also fix on respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(2)
	fixShopButton()
end)