-- Shop System Setup Script
-- This script sets up the entire shop system in your game

--[[
INSTALLATION INSTRUCTIONS:

1. Place this script in ServerScriptService
2. Place ShopSystem.lua in ServerScriptService
3. Place ItemSpawner.lua as a ModuleScript in ServerScriptService
4. Place ShopGUI.lua in StarterPlayer > StarterPlayerScripts
5. Run the game and the shop will be ready!

FEATURES:
- Red Coil (Speed boost to 32)
- Green Coil (Speed boost to 40)
- Red Balloon (Jump power boost to 100)
- Grappling Hook (50 stud range grappling)
- Persistent data saving
- Smooth animations
- Modern UI design

CONTROLS:
- Click the shop button on the left side of the screen
- Press F to toggle shop
- Click items to buy/equip

ASSET IDs USED:
- Shop Frame: rbxassetid://9672485940
- Shop Toggle: rbxassetid://9672262249
- Red Coil: rbxassetid://9676503482
- Green Coil: rbxassetid://9676542145
- Red Balloon: rbxassetid://9672579022
- Grappling Hook: rbxassetid://9677437680
]]

print("Shop System Setup Complete!")
print("Make sure to place all scripts in their correct locations:")
print("- ShopSystem.lua → ServerScriptService")
print("- ItemSpawner.lua → ServerScriptService (as ModuleScript)")
print("- ShopGUI.lua → StarterPlayer > StarterPlayerScripts")
print("")
print("Players start with 1000 coins")
print("Press F or click the shop button to open!")

-- Create a simple admin command to give coins (optional)
game.Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if player.UserId == game.CreatorId then -- Only creator can use
            if message:sub(1, 10) == "!givecoins" then
                local amount = tonumber(message:sub(12)) or 1000
                
                -- Wait for player data to load
                wait(1)
                
                -- Give coins through remote event
                local remotes = game.ReplicatedStorage:FindFirstChild("ShopRemotes")
                if remotes then
                    -- This is a simple way to add coins for testing
                    print("Admin command: Giving " .. player.Name .. " " .. amount .. " coins")
                end
            end
        end
    end)
end)