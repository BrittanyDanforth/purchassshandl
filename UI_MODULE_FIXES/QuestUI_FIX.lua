--[[
    Quest UI Fix
    Add this to ClientModules/UIModules/QuestUI.lua
]]

-- Fix the CreateQuestFilterBar function (around line 410)
-- Replace the dropdown creation with:

local filterDropdown = self._uiFactory:CreateDropdown and self._uiFactory:CreateDropdown(filterBar, {
    size = UDim2.new(0, 150, 0, 30),
    position = UDim2.new(0, 10, 0.5, -15),
    options = {"All", "Daily", "Weekly", "Story", "Event"},
    defaultValue = "All",
    callback = function(value)
        self:FilterQuests(value)
    end
}) or self:CreateBasicDropdown(filterBar, {
    options = {"All", "Daily", "Weekly", "Story", "Event"},
    defaultValue = "All"
})

-- Add this helper function if CreateDropdown doesn't exist:
function QuestUI:CreateBasicDropdown(parent, config)
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(0, 150, 0, 30)
    dropdown.Position = UDim2.new(0, 10, 0.5, -15)
    dropdown.BackgroundColor3 = self._config.COLORS.Surface
    dropdown.Parent = parent
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = config.defaultValue or "Select"
    button.BackgroundTransparency = 1
    button.Parent = dropdown
    
    dropdown.GetValue = function()
        return button.Text
    end
    
    return dropdown
end

-- Fix the Close function to ensure it works:
function QuestUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
    
    if self._windowManager then
        self._windowManager:CloseWindow("QuestUI")
    end
    
    -- Fire close event
    if self._eventBus then
        self._eventBus:Fire("QuestClosed")
    end
end