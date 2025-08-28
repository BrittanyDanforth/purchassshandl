--[[
    UIFactory Additions
    Add these methods to ClientModules/Systems/UIFactory.lua if they're missing
]]

-- Add after the existing methods:

-- CreateToggleSwitch method
function UIFactory:CreateToggleSwitch(parent: Instance, options: table?): Frame
    options = options or {}
    
    -- Container
    local container = Instance.new("Frame")
    container.Name = options.name or "ToggleSwitch"
    container.Size = options.size or UDim2.new(0, 50, 0, 25)
    container.Position = options.position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = options.isOn and self._config.COLORS.Success or self._config.COLORS.ButtonDisabled
    container.BorderSizePixel = 0
    container.Parent = parent
    
    self._utilities.CreateCorner(container, 12)
    
    -- Toggle circle
    local toggle = Instance.new("Frame")
    toggle.Name = "Toggle"
    toggle.Size = UDim2.new(0, 20, 0, 20)
    toggle.Position = options.isOn and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    toggle.BackgroundColor3 = self._config.COLORS.White
    toggle.BorderSizePixel = 0
    toggle.Parent = container
    
    self._utilities.CreateCorner(toggle, 10)
    
    -- Button
    local button = Instance.new("TextButton")
    button.Text = ""
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Parent = container
    
    local isOn = options.isOn or false
    
    button.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        -- Animate
        local targetPos = isOn and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        local targetColor = isOn and self._config.COLORS.Success or self._config.COLORS.ButtonDisabled
        
        self._utilities.Tween(toggle, {Position = targetPos}, TweenInfo.new(0.2))
        self._utilities.Tween(container, {BackgroundColor3 = targetColor}, TweenInfo.new(0.2))
        
        if options.callback then
            options.callback(isOn)
        end
    end)
    
    -- Methods
    container.GetValue = function()
        return isOn
    end
    
    container.SetValue = function(value)
        isOn = value
        toggle.Position = isOn and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        container.BackgroundColor3 = isOn and self._config.COLORS.Success or self._config.COLORS.ButtonDisabled
    end
    
    return container
end

-- Fix CreateSlider to handle table values
local originalCreateSlider = UIFactory.CreateSlider
if originalCreateSlider then
    UIFactory.CreateSlider = function(self, parent, config)
        config = config or {}
        
        -- Ensure numeric values
        if type(config.min) ~= "number" then
            config.min = tonumber(config.min) or 0
        end
        if type(config.max) ~= "number" then
            config.max = tonumber(config.max) or 100
        end
        if type(config.value) ~= "number" then
            config.value = tonumber(config.value) or config.min
        end
        
        return originalCreateSlider(self, parent, config)
    end
end

-- Add CreateFrame if missing
if not UIFactory.CreateFrame then
    function UIFactory:CreateFrame(parent: Instance, options: table?): Frame
        options = options or {}
        
        local frame = Instance.new("Frame")
        frame.Name = options.name or "Frame"
        frame.Size = options.size or UDim2.new(1, 0, 1, 0)
        frame.Position = options.position or UDim2.new(0, 0, 0, 0)
        frame.BackgroundColor3 = options.backgroundColor or self._config.COLORS.Background
        frame.BackgroundTransparency = options.backgroundTransparency or 0
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = options.clipDescendants ~= false
        frame.Visible = options.visible ~= false
        frame.ZIndex = options.zIndex or 1
        frame.Parent = parent
        
        if options.cornerRadius then
            self._utilities.CreateCorner(frame, options.cornerRadius)
        end
        
        return frame
    end
end