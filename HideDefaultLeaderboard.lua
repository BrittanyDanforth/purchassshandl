--[[
	Hide Default Leaderboard
	Place this LocalScript in StarterPlayer > StarterPlayerScripts
	Hides the default Roblox leaderboard UI
--]]

local StarterGui = game:GetService("StarterGui")

-- Keep trying until successful
local success = false
while not success do
	success = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)
	if not success then
		wait(0.1)
	end
end

print("✅ Default leaderboard hidden!")