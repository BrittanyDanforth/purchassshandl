--[[
    Inventory UI Fix
    Fix for ClientModules/UIModules/InventoryUI.lua
]]

-- Fix the CreateStorageBar function (around line 340-350):
function InventoryUI:CreateStorageBar(parent)
    local barContainer = Instance.new("Frame")
    barContainer.Name = "StorageBar"
    barContainer.Size = UDim2.new(1, -20, 0, 30)
    barContainer.Position = UDim2.new(0, 10, 0, 10)
    barContainer.BackgroundTransparency = 1
    barContainer.Parent = parent
    
    -- Create the actual bar frame
    local barFrame = Instance.new("Frame")
    barFrame.Name = "Frame"
    barFrame.Size = UDim2.new(1, 0, 1, 0)
    barFrame.BackgroundColor3 = self._config.COLORS.Surface
    barFrame.BorderSizePixel = 0
    barFrame.Parent = barContainer
    
    self._utilities.CreateCorner(barFrame, 15)
    
    -- Create fill bar
    local fillBar = Instance.new("Frame")
    fillBar.Name = "Fill"
    fillBar.Size = UDim2.new(0.5, 0, 1, 0)
    fillBar.BackgroundColor3 = self._config.COLORS.Primary
    fillBar.BorderSizePixel = 0
    fillBar.Parent = barFrame
    
    self._utilities.CreateCorner(fillBar, 15)
    
    -- Create label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "0/0 Pets"
    label.TextColor3 = self._config.COLORS.Text
    label.Font = self._config.FONTS.Primary
    label.TextScaled = true
    label.Parent = barFrame
    
    -- Add the UpdateValue function to the barFrame
    barFrame.UpdateValue = function(current, max)
        if fillBar then
            fillBar.Size = UDim2.new(math.min(current / max, 1), 0, 1, 0)
        end
        if label then
            label.Text = current .. "/" .. max .. " Pets"
        end
    end
    
    -- Also add to container for compatibility
    barContainer.UpdateValue = barFrame.UpdateValue
    
    return barContainer
end

-- Fix the refresh function to handle missing PetGrid:
function InventoryUI:RefreshPetGrid()
    if not self.PetGrid then
        -- Try to find it
        if self.Frame then
            self.PetGrid = self.Frame:FindFirstChild("PetGrid", true)
        end
        
        if not self.PetGrid then
            warn("[InventoryUI] PetGrid not found, cannot refresh")
            return
        end
    end
    
    -- Continue with refresh...
end