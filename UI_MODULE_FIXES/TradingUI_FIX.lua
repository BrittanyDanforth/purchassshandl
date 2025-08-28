--[[
    Trading UI Fix
    Add to ClientModules/UIModules/TradingUI.lua
]]

-- In the CreateUI function (around line 194), check if CreateFrame exists:
function TradingUI:CreateUI()
    local mainPanel = self._mainUI and self._mainUI.MainPanel or 
                     game.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not mainPanel then
        warn("[TradingUI] No main panel found")
        return
    end
    
    -- Create main frame - check if method exists
    if self._uiFactory.CreateFrame then
        self.Frame = self._uiFactory:CreateFrame(mainPanel, {
            name = "TradingFrame",
            size = UDim2.new(1, -20, 1, -90),
            position = UDim2.new(0, 10, 0, 80),
            backgroundColor = self._config.COLORS.White
        })
    else
        -- Fallback frame creation
        self.Frame = Instance.new("Frame")
        self.Frame.Name = "TradingFrame"
        self.Frame.Size = UDim2.new(1, -20, 1, -90)
        self.Frame.Position = UDim2.new(0, 10, 0, 80)
        self.Frame.BackgroundColor3 = self._config.COLORS.White
        self.Frame.BorderSizePixel = 0
        self.Frame.Parent = mainPanel
        
        self._utilities.CreateCorner(self.Frame, 12)
    end
    
    -- Continue with UI creation...
end

-- Also fix any TextBox placeholder issues:
-- When creating text inputs, ensure placeholderText is a string:
local searchBox = self._uiFactory:CreateTextBox(searchBar, {
    placeholderText = type(config.placeholderText) == "table" and config.placeholderText[1] or tostring(config.placeholderText or "Search..."),
    -- other properties...
})