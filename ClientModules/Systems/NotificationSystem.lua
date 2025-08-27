--[[
    Module: NotificationSystem
    Description: Advanced notification system with queue management, stacking, and animations
    Supports multiple notification types with customizable actions
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

-- ========================================
-- TYPES
-- ========================================

type NotificationData = {
    id: string,
    type: "success" | "error" | "warning" | "info" | "reward" | "default",
    title: string?,
    message: string,
    icon: string?,
    duration: number,
    timestamp: number,
    actions: {[string]: () -> ()}?,
    dismissible: boolean,
    priority: number,
    sound: string?,
    color: Color3?,
    position: UDim2?,
    frame: Frame?,
    tweens: {Tween}?,
}

type NotificationGroup = {
    id: string,
    notifications: {NotificationData},
    count: number,
    frame: Frame?,
}

-- ========================================
-- CONSTANTS
-- ========================================

local DEFAULT_DURATION = 5
local SLIDE_TIME = 0.3
local FADE_TIME = 0.2
local NOTIFICATION_HEIGHT = 80
local NOTIFICATION_SPACING = 10
local MAX_VISIBLE = 5
local STACK_THRESHOLD = 3
local POSITION_RIGHT = UDim2.new(1, -320, 1, -100)
local POSITION_TOP = UDim2.new(0.5, -160, 0, 100)
local NOTIFICATION_WIDTH = 300

-- Notification colors
local TYPE_COLORS = {
    success = Color3.fromRGB(50, 255, 50),
    error = Color3.fromRGB(255, 50, 50),
    warning = Color3.fromRGB(255, 255, 50),
    info = Color3.fromRGB(100, 200, 255),
    reward = Color3.fromRGB(255, 215, 0),
    default = Color3.fromRGB(255, 255, 255),
}

-- Notification icons
local TYPE_ICONS = {
    success = "✓",
    error = "✗",
    warning = "⚠",
    info = "ℹ",
    reward = "★",
    default = "📢",
}

-- ========================================
-- INITIALIZATION
-- ========================================

function NotificationSystem.new(dependencies)
    local self = setmetatable({}, NotificationSystem)
    
    -- Dependencies
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    self._eventBus = dependencies.EventBus
    self._soundSystem = dependencies.SoundSystem
    self._animationSystem = dependencies.AnimationSystem
    
    -- Notification storage
    self._notifications = {} -- Active notifications
    self._queue = {} -- Queued notifications
    self._groups = {} -- Grouped notifications by type
    self._history = {} -- Notification history
    
    -- UI elements
    self._container = nil
    self._topContainer = nil
    
    -- Settings
    self._enabled = true
    self._position = "right" -- "right", "top", "left", "center"
    self._maxVisible = MAX_VISIBLE
    self._enableStacking = true
    self._enableSounds = true
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Animation tracking
    self._isAnimating = false
    self._activeTweens = {}
    
    self:Initialize()
    
    return self
end

function NotificationSystem:Initialize()
    -- Create containers
    self:CreateContainers()
    
    -- Listen for events
    if self._eventBus then
        -- Game events
        self._eventBus:On("CurrencyChanged", function(data)
            if data.difference > 0 then
                self:ShowReward(string.format("+%s %s", 
                    self._utilities.FormatNumber(data.difference),
                    data.type
                ))
            end
        end)
        
        self._eventBus:On("PetAdded", function(pet)
            self:ShowSuccess("New pet obtained: " .. (pet.petId or "Unknown"))
        end)
        
        self._eventBus:On("QuestCompleted", function(quest)
            self:ShowReward("Quest completed: " .. (quest.name or "Unknown"))
        end)
        
        self._eventBus:On("AchievementUnlocked", function(achievement)
            self:ShowReward("Achievement unlocked: " .. (achievement.name or "Unknown"), {
                duration = 10,
                icon = "🏆",
            })
        end)
        
        -- System events
        self._eventBus:On("Error", function(message)
            self:ShowError(message)
        end)
    end
    
    if self._debugMode then
        print("[NotificationSystem] Initialized")
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function NotificationSystem:Show(message: string, options: Types.NotificationConfig?): string
    if not self._enabled then
        return ""
    end
    
    options = options or {}
    
    -- Create notification data
    local id = self._utilities.CreateUUID()
    local notification: NotificationData = {
        id = id,
        type = options.type or "default",
        title = options.title,
        message = message,
        icon = options.icon or TYPE_ICONS[options.type or "default"],
        duration = options.duration or DEFAULT_DURATION,
        timestamp = tick(),
        actions = options.actions,
        dismissible = options.canDismiss ~= false,
        priority = options.priority or 5,
        sound = options.sound,
        color = options.color or TYPE_COLORS[options.type or "default"],
        position = options.position,
    }
    
    -- Check if should stack
    if self._enableStacking and self:ShouldStack(notification) then
        self:StackNotification(notification)
    else
        -- Add to queue or show immediately
        if #self._notifications >= self._maxVisible then
            table.insert(self._queue, notification)
        else
            self:DisplayNotification(notification)
        end
    end
    
    -- Add to history
    table.insert(self._history, notification)
    if #self._history > 100 then
        table.remove(self._history, 1)
    end
    
    return id
end

function NotificationSystem:ShowSuccess(message: string, options: table?): string
    options = options or {}
    options.type = "success"
    return self:Show(message, options)
end

function NotificationSystem:ShowError(message: string, options: table?): string
    options = options or {}
    options.type = "error"
    options.duration = options.duration or 8 -- Errors show longer
    return self:Show(message, options)
end

function NotificationSystem:ShowWarning(message: string, options: table?): string
    options = options or {}
    options.type = "warning"
    return self:Show(message, options)
end

function NotificationSystem:ShowInfo(message: string, options: table?): string
    options = options or {}
    options.type = "info"
    return self:Show(message, options)
end

function NotificationSystem:ShowReward(message: string, options: table?): string
    options = options or {}
    options.type = "reward"
    options.sound = options.sound or self._config.SOUNDS.Success
    return self:Show(message, options)
end

function NotificationSystem:Dismiss(id: string)
    -- Find notification
    for i, notification in ipairs(self._notifications) do
        if notification.id == id then
            self:RemoveNotification(i)
            return
        end
    end
end

function NotificationSystem:DismissAll()
    while #self._notifications > 0 do
        self:RemoveNotification(1)
    end
    
    self._queue = {}
end

-- ========================================
-- NOTIFICATION DISPLAY
-- ========================================

function NotificationSystem:DisplayNotification(notification: NotificationData)
    -- Create notification frame
    local frame = self:CreateNotificationFrame(notification)
    notification.frame = frame
    
    -- Position off-screen
    local startPos, endPos = self:GetPositions(#self._notifications + 1)
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + 400, startPos.Y.Scale, startPos.Y.Offset)
    
    -- Add to active notifications
    table.insert(self._notifications, notification)
    
    -- Play sound
    if self._enableSounds and notification.sound then
        if self._soundSystem then
            self._soundSystem:PlayUISound(notification.sound)
        end
    elseif self._enableSounds and notification.type == "reward" then
        if self._soundSystem then
            self._soundSystem:PlayUISound("Success")
        end
    end
    
    -- Animate in
    local tweenIn = Services.TweenService:Create(
        frame,
        TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = endPos}
    )
    
    tweenIn:Play()
    
    -- Auto dismiss after duration
    if notification.duration > 0 then
        task.delay(notification.duration, function()
            self:AutoDismiss(notification.id)
        end)
    end
    
    -- Update positions of other notifications
    self:UpdateNotificationPositions()
end

function NotificationSystem:CreateNotificationFrame(notification: NotificationData): Frame
    local container = self:GetContainer()
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "Notification_" .. notification.id
    frame.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, NOTIFICATION_HEIGHT)
    frame.BackgroundColor3 = self._config.COLORS.Surface
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = container
    
    -- Add corner radius
    self._utilities.CreateCorner(frame, 12)
    
    -- Add stroke
    local stroke = self._utilities.CreateStroke(frame, notification.color, 2, 0.8)
    
    -- Icon background
    local iconBg = Instance.new("Frame")
    iconBg.Name = "IconBackground"
    iconBg.Size = UDim2.new(0, 60, 1, 0)
    iconBg.Position = UDim2.new(0, 0, 0, 0)
    iconBg.BackgroundColor3 = notification.color
    iconBg.BorderSizePixel = 0
    iconBg.Parent = frame
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = notification.icon
    icon.TextColor3 = self._config.COLORS.White
    icon.TextScaled = true
    icon.Font = self._config.FONTS.Display
    icon.Parent = iconBg
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -70, 1, -10)
    content.Position = UDim2.new(0, 65, 0, 5)
    content.BackgroundTransparency = 1
    content.Parent = frame
    
    -- Title (if provided)
    local messageY = 0
    if notification.title then
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -10, 0, 20)
        title.Position = UDim2.new(0, 0, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = notification.title
        title.TextColor3 = self._config.COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextScaled = true
        title.Font = self._config.FONTS.Secondary
        title.Parent = content
        
        messageY = 25
    end
    
    -- Message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -10, 1, -messageY - 10)
    message.Position = UDim2.new(0, 0, 0, messageY)
    message.BackgroundTransparency = 1
    message.Text = notification.message
    message.TextColor3 = self._config.COLORS.TextSecondary
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.TextScaled = false
    message.TextSize = 14
    message.Font = self._config.FONTS.Primary
    message.Parent = content
    
    -- Dismiss button (if dismissible)
    if notification.dismissible then
        local dismiss = Instance.new("TextButton")
        dismiss.Name = "Dismiss"
        dismiss.Size = UDim2.new(0, 20, 0, 20)
        dismiss.Position = UDim2.new(1, -25, 0, 5)
        dismiss.BackgroundTransparency = 1
        dismiss.Text = "✕"
        dismiss.TextColor3 = self._config.COLORS.TextSecondary
        dismiss.TextScaled = true
        dismiss.Font = self._config.FONTS.Primary
        dismiss.Parent = frame
        
        dismiss.MouseButton1Click:Connect(function()
            self:Dismiss(notification.id)
        end)
        
        -- Hover effect
        dismiss.MouseEnter:Connect(function()
            dismiss.TextColor3 = self._config.COLORS.Text
        end)
        
        dismiss.MouseLeave:Connect(function()
            dismiss.TextColor3 = self._config.COLORS.TextSecondary
        end)
    end
    
    -- Action buttons
    if notification.actions and next(notification.actions) then
        local actionContainer = Instance.new("Frame")
        actionContainer.Name = "Actions"
        actionContainer.Size = UDim2.new(1, 0, 0, 30)
        actionContainer.Position = UDim2.new(0, 0, 1, -35)
        actionContainer.BackgroundTransparency = 1
        actionContainer.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 5)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Parent = actionContainer
        
        for actionName, callback in pairs(notification.actions) do
            local button = Instance.new("TextButton")
            button.Name = actionName
            button.Size = UDim2.new(0, 60, 1, 0)
            button.BackgroundColor3 = notification.color
            button.BorderSizePixel = 0
            button.Text = actionName
            button.TextColor3 = self._config.COLORS.White
            button.TextScaled = true
            button.Font = self._config.FONTS.Secondary
            button.Parent = actionContainer
            
            self._utilities.CreateCorner(button, 4)
            
            button.MouseButton1Click:Connect(function()
                callback()
                self:Dismiss(notification.id)
            end)
        end
        
        -- Adjust frame height for actions
        frame.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, NOTIFICATION_HEIGHT + 40)
    end
    
    -- Add hover effect
    local hovering = false
    frame.MouseEnter:Connect(function()
        hovering = true
        Services.TweenService:Create(
            frame,
            TweenInfo.new(0.2),
            {BackgroundColor3 = self._utilities.LightenColor(self._config.COLORS.Surface, 0.1)}
        ):Play()
    end)
    
    frame.MouseLeave:Connect(function()
        hovering = false
        Services.TweenService:Create(
            frame,
            TweenInfo.new(0.2),
            {BackgroundColor3 = self._config.COLORS.Surface}
        ):Play()
    end)
    
    return frame
end

-- ========================================
-- STACKING SYSTEM
-- ========================================

function NotificationSystem:ShouldStack(notification: NotificationData): boolean
    if not self._enableStacking then
        return false
    end
    
    -- Check for similar recent notifications
    local similarCount = 0
    local recentTime = tick() - 2 -- Within last 2 seconds
    
    for _, active in ipairs(self._notifications) do
        if active.type == notification.type and 
           active.timestamp > recentTime and
           self:AreSimilar(active, notification) then
            similarCount = similarCount + 1
        end
    end
    
    return similarCount >= STACK_THRESHOLD - 1
end

function NotificationSystem:AreSimilar(a: NotificationData, b: NotificationData): boolean
    -- Simple similarity check - can be enhanced
    return a.type == b.type and 
           string.sub(a.message, 1, 20) == string.sub(b.message, 1, 20)
end

function NotificationSystem:StackNotification(notification: NotificationData)
    -- Find or create group
    local groupId = notification.type .. "_" .. string.sub(notification.message, 1, 20)
    local group = self._groups[groupId]
    
    if not group then
        group = {
            id = groupId,
            notifications = {},
            count = 0,
            frame = nil,
        }
        self._groups[groupId] = group
    end
    
    -- Add to group
    table.insert(group.notifications, notification)
    group.count = group.count + 1
    
    -- Update or create stacked notification
    if group.frame then
        self:UpdateStackedNotification(group)
    else
        self:CreateStackedNotification(group)
    end
end

function NotificationSystem:CreateStackedNotification(group: NotificationGroup)
    local first = group.notifications[1]
    local stacked = self._utilities.ShallowCopy(first)
    
    stacked.id = group.id
    stacked.message = string.format("%s (x%d)", first.message, group.count)
    stacked.duration = 0 -- Don't auto-dismiss stacked
    
    self:DisplayNotification(stacked)
    group.frame = stacked.frame
end

function NotificationSystem:UpdateStackedNotification(group: NotificationGroup)
    if not group.frame then
        return
    end
    
    local message = group.frame:FindFirstChild("Content"):FindFirstChild("Message")
    if message then
        local first = group.notifications[1]
        message.Text = string.format("%s (x%d)", first.message, group.count)
    end
    
    -- Pulse animation
    if self._animationSystem then
        self._animationSystem:Pulse(group.frame, 1.05, 0.2)
    end
end

-- ========================================
-- POSITION MANAGEMENT
-- ========================================

function NotificationSystem:GetContainer(): Frame
    if self._position == "top" then
        return self._topContainer
    else
        return self._container
    end
end

function NotificationSystem:GetPositions(index: number): (UDim2, UDim2)
    local yOffset = (index - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)
    
    if self._position == "right" then
        local startPos = UDim2.new(1, 400, 1, -100 - yOffset)
        local endPos = UDim2.new(1, -320, 1, -100 - yOffset)
        return startPos, endPos
    elseif self._position == "left" then
        local startPos = UDim2.new(0, -400, 1, -100 - yOffset)
        local endPos = UDim2.new(0, 20, 1, -100 - yOffset)
        return startPos, endPos
    elseif self._position == "top" then
        local startPos = UDim2.new(0.5, -150, 0, -100)
        local endPos = UDim2.new(0.5, -150, 0, 20 + yOffset)
        return startPos, endPos
    else -- center
        local startPos = UDim2.new(0.5, -150, 0.5, -40 - yOffset)
        local endPos = UDim2.new(0.5, -150, 0.5, -40 - yOffset)
        return startPos, endPos
    end
end

function NotificationSystem:UpdateNotificationPositions()
    for i, notification in ipairs(self._notifications) do
        if notification.frame then
            local _, endPos = self:GetPositions(i)
            
            Services.TweenService:Create(
                notification.frame,
                TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Quad),
                {Position = endPos}
            ):Play()
        end
    end
end

-- ========================================
-- REMOVAL & CLEANUP
-- ========================================

function NotificationSystem:AutoDismiss(id: string)
    for i, notification in ipairs(self._notifications) do
        if notification.id == id then
            -- Check if hovering
            if notification.frame then
                local hovering = false
                -- Simple hover check - in production use proper hover tracking
                
                if not hovering then
                    self:RemoveNotification(i)
                else
                    -- Retry later
                    task.delay(1, function()
                        self:AutoDismiss(id)
                    end)
                end
            else
                self:RemoveNotification(i)
            end
            break
        end
    end
end

function NotificationSystem:RemoveNotification(index: number)
    local notification = self._notifications[index]
    if not notification then
        return
    end
    
    -- Remove from active list
    table.remove(self._notifications, index)
    
    -- Animate out
    if notification.frame then
        local startPos, _ = self:GetPositions(index)
        local outPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + 400, startPos.Y.Scale, startPos.Y.Offset)
        
        local tweenOut = Services.TweenService:Create(
            notification.frame,
            TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = outPos, BackgroundTransparency = 1}
        )
        
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notification.frame:Destroy()
        end)
    end
    
    -- Update positions
    self:UpdateNotificationPositions()
    
    -- Process queue
    if #self._queue > 0 then
        local queued = table.remove(self._queue, 1)
        self:DisplayNotification(queued)
    end
end

-- ========================================
-- CONTAINER CREATION
-- ========================================

function NotificationSystem:CreateContainers()
    -- Right/Left container
    local screenGui = Services.PlayerGui:FindFirstChild("NotificationGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "NotificationGui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 10
        screenGui.Parent = Services.PlayerGui
    end
    
    self._container = Instance.new("Frame")
    self._container.Name = "NotificationContainer"
    self._container.Size = UDim2.new(1, 0, 1, 0)
    self._container.BackgroundTransparency = 1
    self._container.Parent = screenGui
    
    -- Top container (separate for different positioning)
    self._topContainer = Instance.new("Frame")
    self._topContainer.Name = "TopNotificationContainer"
    self._topContainer.Size = UDim2.new(1, 0, 1, 0)
    self._topContainer.BackgroundTransparency = 1
    self._topContainer.Parent = screenGui
end

-- ========================================
-- SETTINGS
-- ========================================

function NotificationSystem:SetPosition(position: "right" | "left" | "top" | "center")
    self._position = position
    
    -- Clear and redisplay all notifications
    local temp = {}
    for _, notification in ipairs(self._notifications) do
        table.insert(temp, notification)
    end
    
    self:DismissAll()
    
    for _, notification in ipairs(temp) do
        notification.frame = nil
        self:DisplayNotification(notification)
    end
end

function NotificationSystem:SetMaxVisible(max: number)
    self._maxVisible = math.max(1, max)
end

function NotificationSystem:EnableStacking(enabled: boolean)
    self._enableStacking = enabled
end

function NotificationSystem:EnableSounds(enabled: boolean)
    self._enableSounds = enabled
end

-- ========================================
-- HISTORY & DEBUGGING
-- ========================================

function NotificationSystem:GetHistory(limit: number?): {NotificationData}
    limit = limit or #self._history
    
    local history = {}
    local start = math.max(1, #self._history - limit + 1)
    
    for i = start, #self._history do
        table.insert(history, self._history[i])
    end
    
    return history
end

function NotificationSystem:ClearHistory()
    self._history = {}
end

if Config.DEBUG.ENABLED then
    function NotificationSystem:DebugPrint()
        print("\n=== NotificationSystem Debug Info ===")
        print("Active Notifications:", #self._notifications)
        print("Queued Notifications:", #self._queue)
        print("History Size:", #self._history)
        print("Position:", self._position)
        print("Max Visible:", self._maxVisible)
        print("Stacking Enabled:", self._enableStacking)
        
        print("\nActive Types:")
        local typeCounts = {}
        for _, notification in ipairs(self._notifications) do
            typeCounts[notification.type] = (typeCounts[notification.type] or 0) + 1
        end
        
        for type, count in pairs(typeCounts) do
            print("  " .. type .. ":", count)
        end
        
        print("===================================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function NotificationSystem:Destroy()
    -- Dismiss all notifications
    self:DismissAll()
    
    -- Clear groups
    self._groups = {}
    
    -- Destroy containers
    if self._container and self._container.Parent then
        self._container.Parent:Destroy()
    end
end

return NotificationSystem