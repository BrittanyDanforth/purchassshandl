-- Modified shop button creation function that ensures visibility
-- Replace the createShopButton function in your script with this one:

local function createShopButton()
	-- Remove any existing shop button
	local existingButton = playerGui:FindFirstChild("SANRIO_SHOP_BUTTON")
	if existingButton then
		existingButton:Destroy()
	end
	
	local buttonScreen = Instance.new("ScreenGui")
	buttonScreen.Name = "SANRIO_SHOP_BUTTON"
	buttonScreen.ResetOnSpawn = false
	buttonScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonScreen.DisplayOrder = 10000 -- Very high display order
	buttonScreen.IgnoreGuiInset = true -- Ignore topbar
	buttonScreen.Enabled = true
	buttonScreen.Parent = playerGui

	local toggle = UI.textButton({
		Name = "ShopToggle",
		Size = UDim2.fromOffset(180, 60), -- Bigger size
		Position = UDim2.new(0.02, 0, 0.1, 0), -- Top left, more visible
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = Theme.c("kitty"),
		CornerRadius = UDim.new(0, 30),
		ZIndex = 10000, -- Very high Z-index
		Visible = true,
		Active = true
	})
	toggle.Parent = buttonScreen

	-- Bright stroke to make it stand out
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 4
	stroke.ZIndex = 10001
	stroke.Parent = toggle

	-- Add glow effect
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(255, 200, 200)
	glow.Thickness = 8
	glow.Transparency = 0.5
	glow.ZIndex = 9999
	glow.Parent = toggle

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 245, 255))
	}
	gradient.Rotation = 90
	gradient.Parent = toggle

	local icon = UI.image({
		Name = "Icon",
		Image = "rbxassetid://" .. Asset.list.badgeHello,
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.new(0, 15, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 10001,
		Visible = true
	})
	icon.Parent = toggle

	local label = UI.textLabel({
		Name = "Label",
		Text = "SHOP",
		TextSize = 24, -- Bigger text
		FontWeight = Enum.FontWeight.Bold,
		TextColor3 = Color3.new(1, 1, 1),
		Position = UDim2.new(0, 60, 0, 0),
		Size = UDim2.new(1, -75, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 10001,
		Visible = true
	})
	label.Parent = toggle

	-- Add shadow for better visibility
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.4
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -15)
	shadow.ZIndex = 9998
	shadow.Parent = toggle

	-- More visible pulse animation
	task.spawn(function()
		while toggle.Parent do
			Utils.tween(toggle, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(190, 65)
			})
			task.wait(1)
			Utils.tween(toggle, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromOffset(180, 60)
			})
			task.wait(1)
		end
	end)
	
	-- Debug print
	print("✅ Shop button created at position:", toggle.Position)
	print("   Size:", toggle.Size)
	print("   Parent:", buttonScreen.Parent)
	print("   Visible:", toggle.Visible)
	print("   Active:", toggle.Active)

	return toggle
end