--[[
	Tycoon Arrow Guide Debug Version
	This will help us see what's happening
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

print("🔍 ARROW GUIDE DEBUG: Starting scan...")

-- Debug: Find all potential tycoons
local function debugFindTycoons()
	print("\n📊 SEARCHING FOR TYCOONS...")
	
	local tycoonCount = 0
	local gateCount = 0
	
	-- Search workspace for tycoons
	for _, obj in ipairs(workspace:GetDescendants()) do
		-- Look for Owner values (sign of a tycoon)
		if obj.Name == "Owner" and obj:IsA("ObjectValue") then
			local tycoon = obj.Parent
			tycoonCount = tycoonCount + 1
			
			print("  ✅ Found tycoon:", tycoon:GetFullName())
			print("     Owner:", obj.Value and obj.Value.Name or "UNCLAIMED")
			
			-- Look for gates in this tycoon
			for _, child in ipairs(tycoon:GetDescendants()) do
				if child:IsA("Model") and (child.Name:lower():find("gate") or child.Name:lower():find("claim")) then
					gateCount = gateCount + 1
					print("     🚪 Found gate:", child.Name)
					
					-- Check for touch part
					local touchPart = child:FindFirstChild("Head") or child:FindFirstChild("TouchPart") or child:FindFirstChildWhichIsA("BasePart")
					if touchPart then
						print("        Touch part:", touchPart.Name, "Transparency:", touchPart.Transparency)
					else
						print("        ⚠️ No touch part found!")
					end
				end
			end
		end
	end
	
	print("\n📈 SUMMARY:")
	print("  Total tycoons found:", tycoonCount)
	print("  Total gates found:", gateCount)
	
	-- Also check specific locations
	print("\n🔍 CHECKING COMMON LOCATIONS:")
	
	local locations = {
		workspace:FindFirstChild("Tycoons"),
		workspace:FindFirstChild("TycoonModel"),
		workspace:FindFirstChild("New Hellokitty tycoon"),
		workspace:FindFirstChild("Cinnamoroll tycoon"),
		workspace:FindFirstChild("Kuromi tycoon"),
		workspace:FindFirstChild("Zednov's Tycoon Kit")
	}
	
	for _, location in ipairs(locations) do
		if location then
			print("  📁 Found location:", location.Name)
			
			-- Look for tycoons inside
			for _, child in ipairs(location:GetChildren()) do
				if child:FindFirstChild("Owner") then
					print("    - Tycoon:", child.Name)
					local owner = child.Owner.Value
					print("      Owner:", owner and owner.Name or "UNCLAIMED")
				end
			end
		end
	end
end

-- Run debug immediately
debugFindTycoons()

-- Simple arrow for testing
local function createSimpleArrow(position, tycoonName)
	print("🎯 Creating arrow for:", tycoonName, "at", tostring(position))
	
	local arrow = Instance.new("Part")
	arrow.Name = "DebugArrow_" .. tycoonName
	arrow.Size = Vector3.new(4, 8, 4)
	arrow.Material = Enum.Material.Neon
	arrow.BrickColor = BrickColor.new("Lime green")
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Position = position + Vector3.new(0, 15, 0)
	arrow.Parent = workspace
	
	-- Add spinning
	local spin = RunService.Heartbeat:Connect(function()
		if arrow.Parent then
			arrow.CFrame = arrow.CFrame * CFrame.Angles(0, math.rad(2), 0)
		else
			spin:Disconnect()
		end
	end)
	
	-- Add text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = arrow
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = "CLAIM: " .. tycoonName
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Parent = billboard
	
	return arrow
end

-- Test: Create arrows for any unclaimed tycoons
wait(2)
print("\n🎯 CREATING TEST ARROWS...")

for _, obj in ipairs(workspace:GetDescendants()) do
	if obj.Name == "Owner" and obj:IsA("ObjectValue") and obj.Value == nil then
		local tycoon = obj.Parent
		print("  Creating arrow for unclaimed tycoon:", tycoon.Name)
		
		-- Find a position (gate or center of tycoon)
		local gate = tycoon:FindFirstChild("Gate", true) or tycoon:FindFirstChild("TouchToClaimPart", true)
		local position
		
		if gate and gate:IsA("BasePart") then
			position = gate.Position
		elseif gate and gate:FindFirstChildWhichIsA("BasePart") then
			position = gate:FindFirstChildWhichIsA("BasePart").Position
		else
			-- Use tycoon pivot
			position = tycoon:GetPivot().Position
		end
		
		createSimpleArrow(position, tycoon.Name)
	end
end

print("\n✅ ARROW GUIDE DEBUG COMPLETE!")