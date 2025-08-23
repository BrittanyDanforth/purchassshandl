--[[
	Hide Default Leaderboard
	Place in StarterPlayer > StarterPlayerScripts
	This hides the ugly default leaderboard since we have our modern cash UI
--]]

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- Hide the leaderboard
local success = false
while not success do
	success = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)
	if not success then
		wait(0.1)
	end
end

print("✅ Default leaderboard hidden - Using modern cash UI instead!")