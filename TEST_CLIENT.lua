-- Super simple test to see what's going on

print("TEST CLIENT STARTING...")

-- Just try to find and click the Shop button directly
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Wait a bit for UI to load
wait(5)

print("Looking for UI elements...")

-- Function to find shop button
local function findShopButton()
    for _, screenGui in ipairs(gui:GetChildren()) do
        if screenGui:IsA("ScreenGui") then
            print("Found ScreenGui: " .. screenGui.Name)
            
            -- Look for shop button
            for _, desc in ipairs(screenGui:GetDescendants()) do
                if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    local name = desc.Name:lower()
                    local text = ""
                    if desc:IsA("TextButton") then
                        text = desc.Text:lower()
                    end
                    
                    if name:find("shop") or text:find("shop") then
                        print("FOUND SHOP BUTTON: " .. desc:GetFullName())
                        return desc
                    end
                end
            end
        end
    end
    return nil
end

-- Try to find and click shop
local shopButton = findShopButton()
if shopButton then
    print("Clicking shop button...")
    
    -- Try different click methods
    if shopButton.MouseButton1Click then
        shopButton.MouseButton1Click:Fire()
        print("Fired MouseButton1Click")
    end
    
    if shopButton.Activated then
        shopButton.Activated:Fire()
        print("Fired Activated")
    end
else
    print("Shop button not found!")
end

-- List all ScreenGuis
print("\nAll ScreenGuis in PlayerGui:")
for _, child in ipairs(gui:GetChildren()) do
    if child:IsA("ScreenGui") then
        print("  - " .. child.Name .. " (Enabled: " .. tostring(child.Enabled) .. ")")
    end
end

print("\nTEST CLIENT DONE")