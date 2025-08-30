--[[
    ButtonStateManager
    Professional button state management for Triple-A UI experience
    
    Features:
    - Individual button state tracking
    - Loading animations and feedback
    - Error recovery
    - Cooldown management
    - Visual state transitions
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local HapticService = game:GetService("HapticService")

local ButtonStateManager = {}
ButtonStateManager.__index = ButtonStateManager

-- Button states
local ButtonState = {
    IDLE = "idle",
    HOVER = "hover",
    PRESSED = "pressed",
    LOADING = "loading",
    SUCCESS = "success",
    ERROR = "error",
    DISABLED = "disabled",
    COOLDOWN = "cooldown"
}

-- Default configuration
local DEFAULT_CONFIG = {
    cooldownTime = 0.5,
    loadingTimeout = 10,
    animationSpeed = 0.2,
    hapticEnabled = true,
    soundEnabled = true,
    visualFeedback = true,
    successDuration = 1,
    errorDuration = 2
}

-- Visual states configuration
local VISUAL_STATES = {
    [ButtonState.IDLE] = {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0
    },
    [ButtonState.HOVER] = {
        BackgroundColor3 = Color3.fromRGB(240, 240, 240),
        BackgroundTransparency = 0,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 2
    },
    [ButtonState.PRESSED] = {
        BackgroundColor3 = Color3.fromRGB(220, 220, 220),
        BackgroundTransparency = 0,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 2
    },
    [ButtonState.LOADING] = {
        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
        BackgroundTransparency = 0.3,
        TextColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0
    },
    [ButtonState.SUCCESS] = {
        BackgroundColor3 = Color3.fromRGB(100, 255, 100),
        BackgroundTransparency = 0,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    },
    [ButtonState.ERROR] = {
        BackgroundColor3 = Color3.fromRGB(255, 100, 100),
        BackgroundTransparency = 0,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    },
    [ButtonState.DISABLED] = {
        BackgroundColor3 = Color3.fromRGB(150, 150, 150),
        BackgroundTransparency = 0.5,
        TextColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0
    },
    [ButtonState.COOLDOWN] = {
        BackgroundColor3 = Color3.fromRGB(180, 180, 180),
        BackgroundTransparency = 0.2,
        TextColor3 = Color3.fromRGB(120, 120, 120),
        BorderSizePixel = 0
    }
}

function ButtonStateManager.new(config)
    local self = setmetatable({}, ButtonStateManager)
    
    self._config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self._config[key] = (config and config[key]) or value
    end
    
    self._buttons = {}
    self._activeAnimations = {}
    self._cooldowns = {}
    self._loadingIndicators = {}
    
    return self
end

function ButtonStateManager:RegisterButton(button: TextButton, options: table?)
    if not button or not button:IsA("TextButton") then
        warn("[ButtonStateManager] Invalid button provided")
        return
    end
    
    local buttonData = {
        button = button,
        state = ButtonState.IDLE,
        originalText = button.Text,
        originalProps = {},
        options = options or {},
        connections = {},
        actionQueue = {},
        isProcessing = false
    }
    
    -- Store original properties
    for prop, _ in pairs(VISUAL_STATES[ButtonState.IDLE]) do
        buttonData.originalProps[prop] = button[prop]
    end
    
    -- Set up hover effects
    buttonData.connections.mouseEnter = button.MouseEnter:Connect(function()
        if buttonData.state == ButtonState.IDLE then
            self:SetButtonState(button, ButtonState.HOVER)
        end
    end)
    
    buttonData.connections.mouseLeave = button.MouseLeave:Connect(function()
        if buttonData.state == ButtonState.HOVER then
            self:SetButtonState(button, ButtonState.IDLE)
        end
    end)
    
    -- Set up click handling
    buttonData.connections.mouseDown = button.MouseButton1Down:Connect(function()
        if buttonData.state == ButtonState.HOVER then
            self:SetButtonState(button, ButtonState.PRESSED)
            
            -- Haptic feedback
            if self._config.hapticEnabled and HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) then
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.2)
                task.wait(0.1)
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
            end
        end
    end)
    
    buttonData.connections.mouseUp = button.MouseButton1Up:Connect(function()
        if buttonData.state == ButtonState.PRESSED then
            self:SetButtonState(button, ButtonState.HOVER)
        end
    end)
    
    self._buttons[button] = buttonData
    
    -- Create loading indicator
    self:CreateLoadingIndicator(button)
    
    return buttonData
end

function ButtonStateManager:UnregisterButton(button: TextButton)
    local buttonData = self._buttons[button]
    if not buttonData then return end
    
    -- Clean up connections
    for _, connection in pairs(buttonData.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Clean up animations
    if self._activeAnimations[button] then
        self._activeAnimations[button]:Cancel()
        self._activeAnimations[button] = nil
    end
    
    -- Clean up loading indicator
    if self._loadingIndicators[button] then
        self._loadingIndicators[button]:Destroy()
        self._loadingIndicators[button] = nil
    end
    
    -- Restore original state
    self:RestoreButtonState(button)
    
    self._buttons[button] = nil
end

function ButtonStateManager:SetButtonState(button: TextButton, state: string)
    local buttonData = self._buttons[button]
    if not buttonData then return end
    
    buttonData.state = state
    
    -- Apply visual state
    if self._config.visualFeedback then
        self:ApplyVisualState(button, state)
    end
    
    -- Handle state-specific logic
    if state == ButtonState.LOADING then
        self:ShowLoadingIndicator(button)
        button.Active = false
    elseif state == ButtonState.DISABLED or state == ButtonState.COOLDOWN then
        button.Active = false
    else
        self:HideLoadingIndicator(button)
        button.Active = true
    end
end

function ButtonStateManager:ApplyVisualState(button: TextButton, state: string)
    local visualState = VISUAL_STATES[state]
    if not visualState then return end
    
    -- Cancel existing animation
    if self._activeAnimations[button] then
        self._activeAnimations[button]:Cancel()
    end
    
    -- Create tween
    local tweenInfo = TweenInfo.new(
        self._config.animationSpeed,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(button, tweenInfo, visualState)
    self._activeAnimations[button] = tween
    tween:Play()
end

function ButtonStateManager:RestoreButtonState(button: TextButton)
    local buttonData = self._buttons[button]
    if not buttonData then return end
    
    -- Restore original properties
    for prop, value in pairs(buttonData.originalProps) do
        button[prop] = value
    end
    
    button.Text = buttonData.originalText
    button.Active = true
end

function ButtonStateManager:CreateLoadingIndicator(button: TextButton)
    local indicator = Instance.new("Frame")
    indicator.Name = "LoadingIndicator"
    indicator.Size = UDim2.new(1, 0, 1, 0)
    indicator.BackgroundTransparency = 1
    indicator.Visible = false
    indicator.Parent = button
    
    -- Create spinner
    local spinner = Instance.new("ImageLabel")
    spinner.Name = "Spinner"
    spinner.Size = UDim2.new(0, 20, 0, 20)
    spinner.Position = UDim2.new(0.5, -10, 0.5, -10)
    spinner.BackgroundTransparency = 1
    spinner.Image = "rbxassetid://4458901886" -- Spinner icon
    spinner.ImageColor3 = Color3.fromRGB(255, 255, 255)
    spinner.Parent = indicator
    
    self._loadingIndicators[button] = indicator
end

function ButtonStateManager:ShowLoadingIndicator(button: TextButton)
    local indicator = self._loadingIndicators[button]
    if not indicator then return end
    
    indicator.Visible = true
    
    -- Animate spinner
    local spinner = indicator:FindFirstChild("Spinner")
    if spinner then
        local rotation = 0
        local connection
        connection = RunService.Heartbeat:Connect(function(dt)
            if not indicator.Parent or not indicator.Visible then
                connection:Disconnect()
                return
            end
            rotation = rotation + (360 * dt)
            spinner.Rotation = rotation % 360
        end)
    end
end

function ButtonStateManager:HideLoadingIndicator(button: TextButton)
    local indicator = self._loadingIndicators[button]
    if indicator then
        indicator.Visible = false
    end
end

function ButtonStateManager:ExecuteAction(button: TextButton, action: () -> any, options: table?)
    local buttonData = self._buttons[button]
    if not buttonData then
        warn("[ButtonStateManager] Button not registered")
        return Promise.reject("Button not registered")
    end
    
    options = options or {}
    
    -- Check if button is in a valid state
    if buttonData.state == ButtonState.LOADING or 
       buttonData.state == ButtonState.DISABLED or
       buttonData.state == ButtonState.COOLDOWN then
        return Promise.reject("Button is busy")
    end
    
    -- Check cooldown
    if self._cooldowns[button] and tick() < self._cooldowns[button] then
        return Promise.reject("Button is on cooldown")
    end
    
    return Promise.new(function(resolve, reject)
        -- Set loading state
        self:SetButtonState(button, ButtonState.LOADING)
        
        -- Update button text if provided
        if options.loadingText then
            button.Text = options.loadingText
        end
        
        -- Create timeout
        local timeout = task.delay(self._config.loadingTimeout, function()
            self:SetButtonState(button, ButtonState.ERROR)
            button.Text = options.errorText or "Timeout!"
            
            task.wait(self._config.errorDuration)
            self:RestoreButtonState(button)
            
            reject("Action timed out")
        end)
        
        -- Execute action
        local success, result = pcall(action)
        
        -- Cancel timeout
        task.cancel(timeout)
        
        if success then
            -- Success state
            self:SetButtonState(button, ButtonState.SUCCESS)
            if options.successText then
                button.Text = options.successText
            end
            
            -- Play success sound
            if self._config.soundEnabled and options.successSound then
                -- Play sound
            end
            
            -- Wait for success duration
            task.wait(self._config.successDuration)
            
            -- Set cooldown
            self._cooldowns[button] = tick() + self._config.cooldownTime
            
            -- Restore state
            self:RestoreButtonState(button)
            
            -- Start cooldown timer
            self:StartCooldownTimer(button)
            
            resolve(result)
        else
            -- Error state
            self:SetButtonState(button, ButtonState.ERROR)
            button.Text = options.errorText or "Error!"
            
            -- Play error sound
            if self._config.soundEnabled and options.errorSound then
                -- Play sound
            end
            
            -- Wait for error duration
            task.wait(self._config.errorDuration)
            
            -- Restore state
            self:RestoreButtonState(button)
            
            reject(result)
        end
    end)
end

function ButtonStateManager:StartCooldownTimer(button: TextButton)
    local buttonData = self._buttons[button]
    if not buttonData then return end
    
    self:SetButtonState(button, ButtonState.COOLDOWN)
    
    local cooldownEnd = self._cooldowns[button]
    local originalText = buttonData.originalText
    
    -- Update button text with cooldown
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local remaining = cooldownEnd - tick()
        if remaining <= 0 then
            connection:Disconnect()
            self:SetButtonState(button, ButtonState.IDLE)
            button.Text = originalText
        else
            button.Text = string.format("%s (%.1fs)", originalText, remaining)
        end
    end)
end

function ButtonStateManager:SetButtonEnabled(button: TextButton, enabled: boolean)
    local buttonData = self._buttons[button]
    if not buttonData then return end
    
    if enabled then
        if buttonData.state == ButtonState.DISABLED then
            self:SetButtonState(button, ButtonState.IDLE)
        end
    else
        self:SetButtonState(button, ButtonState.DISABLED)
    end
end

function ButtonStateManager:Destroy()
    -- Clean up all buttons
    for button, _ in pairs(self._buttons) do
        self:UnregisterButton(button)
    end
    
    self._buttons = {}
    self._activeAnimations = {}
    self._cooldowns = {}
    self._loadingIndicators = {}
end

-- Promise implementation (simplified)
local Promise = {}
Promise.__index = Promise

function Promise.new(executor)
    local self = setmetatable({
        _state = "pending",
        _value = nil,
        _reason = nil,
        _thenCallbacks = {},
        _catchCallbacks = {}
    }, Promise)
    
    local function resolve(value)
        if self._state ~= "pending" then return end
        self._state = "fulfilled"
        self._value = value
        
        for _, callback in ipairs(self._thenCallbacks) do
            task.spawn(callback, value)
        end
    end
    
    local function reject(reason)
        if self._state ~= "pending" then return end
        self._state = "rejected"
        self._reason = reason
        
        for _, callback in ipairs(self._catchCallbacks) do
            task.spawn(callback, reason)
        end
    end
    
    task.spawn(executor, resolve, reject)
    
    return self
end

function Promise:Then(onFulfilled)
    if self._state == "fulfilled" then
        task.spawn(onFulfilled, self._value)
    elseif self._state == "pending" then
        table.insert(self._thenCallbacks, onFulfilled)
    end
    return self
end

function Promise:Catch(onRejected)
    if self._state == "rejected" then
        task.spawn(onRejected, self._reason)
    elseif self._state == "pending" then
        table.insert(self._catchCallbacks, onRejected)
    end
    return self
end

function Promise.reject(reason)
    return Promise.new(function(_, reject)
        reject(reason)
    end)
end

-- Export Promise for use
ButtonStateManager.Promise = Promise

return ButtonStateManager