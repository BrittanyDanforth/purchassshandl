-- Manual shop opener - use this if button is not visible
-- You can bind this to a key or run it in console

local function openShopManually()
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Find the shop GUI
	local shopGui = playerGui:FindFirstChild("SANRIO_SHOP_REBUILT")
	if not shopGui then
		warn("Shop GUI not found!")
		return
	end
	
	-- Find the dim and panel
	local dim = shopGui:FindFirstChild("Dim")
	local panel = shopGui:FindFirstChild("Panel")
	
	if not dim or not panel then
		warn("Shop elements not found!")
		return
	end
	
	-- Make them visible
	dim.Visible = true
	panel.Visible = true
	dim.BackgroundTransparency = 0.3
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.new(0, 1140, 0, 860)
	panel.BackgroundTransparency = 0
	
	-- Try to find and trigger blur
	local Lighting = game:GetService("Lighting")
	local blur = Lighting:FindFirstChild("SanrioShopBlur")
	if blur then
		blur.Size = 10
	end
	
	print("✅ Shop opened manually!")
end

-- Create a temporary button in a different location
local function createTempShopButton()
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Create temporary screen GUI
	local tempScreen = Instance.new("ScreenGui")
	tempScreen.Name = "TEMP_SHOP_BUTTON"
	tempScreen.ResetOnSpawn = false
	tempScreen.DisplayOrder = 20000
	tempScreen.IgnoreGuiInset = true
	tempScreen.Parent = playerGui
	
	-- Create a big, visible button
	local bigButton = Instance.new("TextButton")
	bigButton.Name = "BigShopButton"
	bigButton.Size = UDim2.new(0, 300, 0, 100)
	bigButton.Position = UDim2.new(0.5, -150, 0.9, -100) -- Bottom center
	bigButton.BackgroundColor3 = Color3.new(1, 0, 1) -- Magenta - very visible
	bigButton.Text = "CLICK TO OPEN SHOP"
	bigButton.TextScaled = true
	bigButton.TextColor3 = Color3.new(1, 1, 1)
	bigButton.Font = Enum.Font.SourceSansBold
	bigButton.Parent = tempScreen
	
	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = bigButton
	
	-- Add thick stroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = Color3.new(1, 1, 0)
	stroke.Parent = bigButton
	
	-- Connect click
	bigButton.MouseButton1Click:Connect(openShopManually)
	
	print("✅ Temporary shop button created at bottom of screen!")
end

-- Run both
openShopManually() -- Try to open shop immediately
createTempShopButton() -- Create backup button