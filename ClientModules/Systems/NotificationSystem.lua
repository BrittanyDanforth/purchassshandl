--[[
    Module: NotificationSystem
    Description: Advanced notification system with queue management, stacking, and animations.
    Supports multiple notification types with customizable actions.
    
    -- FINAL VERSION 5.0 --
    - FIX: Removed a conflicting "pulse" animation that was firing at the same time as the
           re-positioning animation, which caused a visual glitch where notifications would
           bounce or grow in size unexpectedly. The animation is now smooth.
    - Retained all previous fixes for layering and positioning.
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
local STACK_THRESHOLD = 2 -- Start stacking after 2 identical notifications
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

	-- Settings
	self._enabled = true
	self._position = "top-right" -- "top-right", "right" (bottom-right), "left", "top" (center)
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
	-- Create the self-contained UI container
	self:CreateContainer()

	-- Listen for events
	if self._eventBus then
		self._eventBus:On("CurrencyChanged", function(data)
			if data.difference > 0 then
				self:ShowReward(string.format("+%s %s",
					self._utilities.FormatNumber(data.difference),
					data.type
					))
			end
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

	-- Safety check for message type
	if type(message) ~= "string" then
		if type(message) == "table" then
			local extracted = message.message or message.text or message.error or "Notification received (invalid format)"
			warn("[NotificationSystem] Show() was called with a table. Extracted message:", extracted)
			message = tostring(extracted)
		else
			warn("[NotificationSystem] Show() was called with non-string message:", type(message))
			message = tostring(message)
		end
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

	-- Handle stacking or queuing
	if self._enableStacking and self:ShouldStack(notification) then
		self:StackNotification(notification)
	else
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
	local frame = self:CreateNotificationFrame(notification)
	notification.frame = frame

	local startPos, endPos = self:GetPositions(#self._notifications + 1)
	frame.Position = startPos
	frame.BackgroundTransparency = 1
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("GuiObject") then
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child.TextTransparency = 1
			elseif child:IsA("ImageLabel") then
				child.ImageTransparency = 1
			end
		end
	end

	table.insert(self._notifications, notification)

	if self._enableSounds then
		local soundToPlay = notification.sound or (notification.type == "reward" and "Success")
		if soundToPlay and self._soundSystem then
			self._soundSystem:PlayUISound(soundToPlay)
		end
	end

	local tweenIn = Services.TweenService:Create(
		frame,
		TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = endPos, BackgroundTransparency = 0}
	)
	tweenIn:Play()

	task.delay(SLIDE_TIME * 0.5, function()
		if not frame or not frame.Parent then return end
		for _, child in ipairs(frame:GetDescendants()) do
			if child:IsA("GuiObject") then
				local targetTransparency = (child.Name == "Dismiss") and 0.5 or 0
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					self._utilities.Tween(child, { TextTransparency = targetTransparency }, self._config.TWEEN_INFO.Fast)
				elseif child:IsA("ImageLabel") then
					self._utilities.Tween(child, { ImageTransparency = targetTransparency }, self._config.TWEEN_INFO.Fast)
				end
			end
		end
	end)

	if notification.duration > 0 then
		task.delay(notification.duration, function()
			self:AutoDismiss(notification.id)
		end)
	end

	self:UpdateNotificationPositions()
end

function NotificationSystem:CreateNotificationFrame(notification: NotificationData): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Notification_" .. notification.id
	frame.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, NOTIFICATION_HEIGHT)
	frame.BackgroundColor3 = self._config.COLORS.Surface
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = self._container
	frame:SetAttribute("IsHovering", false)
	frame.ZIndex = 501

	-- Add size constraint to prevent any resizing
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(NOTIFICATION_WIDTH, NOTIFICATION_HEIGHT)
	sizeConstraint.MinSize = Vector2.new(NOTIFICATION_WIDTH, NOTIFICATION_HEIGHT)
	sizeConstraint.Parent = frame

	self._utilities.CreateCorner(frame, 12)
	self._utilities.CreateStroke(frame, notification.color, 2, 0.8)

	local iconBg = Instance.new("Frame")
	iconBg.Name = "IconBackground"
	iconBg.Size = UDim2.new(0, 60, 1, 0)
	iconBg.BackgroundColor3 = notification.color
	iconBg.Parent = frame

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = notification.icon
	icon.TextColor3 = self._config.COLORS.White
	icon.TextScaled = true
	icon.Font = self._config.FONTS.Display
	icon.Parent = iconBg

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -70, 1, -10)
	content.Position = UDim2.new(0, 65, 0, 5)
	content.BackgroundTransparency = 1
	content.Parent = frame

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 2)
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.Parent = content

	if notification.title then
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0, 20)
		title.BackgroundTransparency = 1
		title.Text = tostring(notification.title)
		title.TextColor3 = self._config.COLORS.Text
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextScaled = true
		title.Font = self._config.FONTS.Secondary
		title.LayoutOrder = 1
		title.Parent = content
	end

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Size = UDim2.new(1, 0, 1, 0)
	message.AutomaticSize = Enum.AutomaticSize.Y
	message.BackgroundTransparency = 1
	message.Text = tostring(notification.message or "")
	message.TextColor3 = self._config.COLORS.TextSecondary
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.TextWrapped = true
	message.TextSize = 14
	message.Font = self._config.FONTS.Primary
	message.LayoutOrder = 2
	message.Parent = content

	if notification.dismissible then
		local dismiss = Instance.new("TextButton")
		dismiss.Name = "Dismiss"
		dismiss.Size = UDim2.new(0, 20, 0, 20)
		dismiss.Position = UDim2.new(1, -25, 0, 5)
		dismiss.BackgroundTransparency = 1
		dismiss.Text = "✕"
		dismiss.TextColor3 = self._config.COLORS.TextSecondary
		dismiss.TextTransparency = 0.5
		dismiss.TextScaled = true
		dismiss.Font = self._config.FONTS.Primary
		dismiss.Parent = frame
		dismiss.MouseButton1Click:Connect(function() self:Dismiss(notification.id) end)
		dismiss.MouseEnter:Connect(function() dismiss.TextTransparency = 0 end)
		dismiss.MouseLeave:Connect(function() dismiss.TextTransparency = 0.5 end)
	end

	frame.MouseEnter:Connect(function()
		frame:SetAttribute("IsHovering", true)
		Services.TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = self._utilities.LightenColor(self._config.COLORS.Surface, 0.1)}):Play()
	end)
	frame.MouseLeave:Connect(function()
		frame:SetAttribute("IsHovering", false)
		Services.TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = self._config.COLORS.Surface}):Play()
	end)

	return frame
end

-- ========================================
-- STACKING AND POSITIONING
-- ========================================

function NotificationSystem:ShouldStack(notification: NotificationData): boolean
	if not self._enableStacking then return false end
	local similarCount = 0
	local recentTime = tick() - 3
	for _, n in ipairs(self._notifications) do
		if self:AreSimilar(n, notification) and n.timestamp > recentTime then similarCount += 1 end
	end
	for _, n in ipairs(self._queue) do
		if self:AreSimilar(n, notification) and n.timestamp > recentTime then similarCount += 1 end
	end
	local groupId = notification.type .. "_" .. tostring(notification.message or "")
	if self._groups[groupId] then return true end
	return similarCount >= STACK_THRESHOLD - 1
end

function NotificationSystem:AreSimilar(a: NotificationData, b: NotificationData): boolean
	return a.type == b.type and tostring(a.message or "") == tostring(b.message or "")
end

function NotificationSystem:StackNotification(notification: NotificationData)
	local groupId = notification.type .. "_" .. tostring(notification.message or "")
	local group = self._groups[groupId]
	if not group then
		group = { id = groupId, notifications = {}, count = 0, frame = nil }
		self._groups[groupId] = group
		local toRemove = {}
		for i, active in ipairs(self._notifications) do
			if self:AreSimilar(active, notification) then
				table.insert(group.notifications, active)
				group.count += 1
				table.insert(toRemove, i)
			end
		end
		for i = #toRemove, 1, -1 do
			local removed = table.remove(self._notifications, toRemove[i])
			if removed.frame then removed.frame:Destroy() end
		end
	end
	table.insert(group.notifications, notification)
	group.count += 1
	if group.frame and group.frame.Parent then
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
	stacked.duration = first.duration or 3
	self:DisplayNotification(stacked)
	if stacked.frame then group.frame = stacked.frame end
end

function NotificationSystem:UpdateStackedNotification(group: NotificationGroup)
	if not group.frame then return end
	local message = group.frame:FindFirstChild("Content", true):FindFirstChild("Message")
	if message then
		message.Text = string.format("%s (x%d)", group.notifications[1].message, group.count)
	end
	-- NO PULSE ANIMATION - this causes the growth issue
end

function NotificationSystem:GetPositions(index: number): (UDim2, UDim2)
	local yOffset = (index - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)
	local positionType = self._position

	if positionType == "top-right" then
		return UDim2.new(1, 10, 0, 20 + yOffset), UDim2.new(1, -NOTIFICATION_WIDTH - 10, 0, 20 + yOffset)
	elseif positionType == "right" then -- bottom-right
		return UDim2.new(1, 10, 1, -100 - yOffset), UDim2.new(1, -NOTIFICATION_WIDTH - 10, 1, -100 - yOffset)
	elseif positionType == "left" then -- bottom-left
		return UDim2.new(0, -NOTIFICATION_WIDTH - 10, 1, -100 - yOffset), UDim2.new(0, 10, 1, -100 - yOffset)
	else -- top-center
		return UDim2.new(0.5, -NOTIFICATION_WIDTH / 2, 0, -NOTIFICATION_HEIGHT), UDim2.new(0.5, -NOTIFICATION_WIDTH / 2, 0, 20 + yOffset)
	end
end

function NotificationSystem:UpdateNotificationPositions()
	for i, notification in ipairs(self._notifications) do
		if notification.frame and notification.frame.Parent then
			task.spawn(function()
				task.wait((i - 1) * 0.03) -- Stagger animation for a smoother cascade effect
				local _, targetPos = self:GetPositions(i)
				local tween = Services.TweenService:Create(
					notification.frame,
					TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{Position = targetPos}
				)
				tween:Play()
			end)
		end
	end
end

-- ========================================
-- REMOVAL & CLEANUP
-- ========================================

function NotificationSystem:AutoDismiss(id: string)
	for i, notification in ipairs(self._notifications) do
		if notification.id == id then
			if notification.frame and notification.frame:GetAttribute("IsHovering") then
				task.delay(1, function() self:AutoDismiss(id) end)
			else
				self:RemoveNotification(i)
			end
			break
		end
	end
end

function NotificationSystem:RemoveNotification(index: number)
	local notification = table.remove(self._notifications, index)
	if not notification then return end

	if self._groups[notification.id] then
		self._groups[notification.id] = nil
	end

	if notification.frame and notification.frame.Parent then
		local _, currentPos = self:GetPositions(index)
		local outPos = UDim2.new(self._position == "left" and -1 or 2, 0, currentPos.Y.Scale, currentPos.Y.Offset)

		for _, child in ipairs(notification.frame:GetDescendants()) do
			if child:IsA("GuiObject") and child.Transparency < 1 then
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					self._utilities.Tween(child, { TextTransparency = 1 }, self._config.TWEEN_INFO.Fast)
				elseif child:IsA("ImageLabel") then
					self._utilities.Tween(child, { ImageTransparency = 1 }, self._config.TWEEN_INFO.Fast)
				end
			end
		end

		local tweenOut = Services.TweenService:Create(notification.frame, TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = outPos, BackgroundTransparency = 1})
		tweenOut.Completed:Connect(function() if notification.frame then notification.frame:Destroy() end end)
		tweenOut:Play()
	end

	self:UpdateNotificationPositions()

	if #self._notifications < self._maxVisible and #self._queue > 0 then
		self:DisplayNotification(table.remove(self._queue, 1))
	end
end

-- ========================================
-- CONTAINER CREATION
-- ========================================

function NotificationSystem:CreateContainer()
	local screenGui = Services.PlayerGui:FindFirstChild("NotificationGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "NotificationGui"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.DisplayOrder = 2147483647
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = Services.PlayerGui
	end

	self._container = Instance.new("Frame")
	self._container.Name = "NotificationContainer"
	self._container.Size = UDim2.new(1, 0, 1, 0)
	self._container.BackgroundTransparency = 1
	self._container.ZIndex = 500
	self._container.Parent = screenGui
end

-- ========================================
-- SETTINGS & CLEANUP
-- ========================================

function NotificationSystem:SetPosition(position: "top-right" | "right" | "left" | "top")
	self._position = position
	local temp = {}
	for _, n in ipairs(self._notifications) do table.insert(temp, n) end
	self:DismissAll()
	for _, n in ipairs(temp) do n.frame = nil; self:DisplayNotification(n) end
end

function NotificationSystem:SetMaxVisible(max: number) self._maxVisible = math.max(1, max) end
function NotificationSystem:EnableStacking(enabled: boolean) self._enableStacking = enabled end
function NotificationSystem:EnableSounds(enabled: boolean) self._enableSounds = enabled end
function NotificationSystem:ClearHistory() self._history = {} end

function NotificationSystem:Destroy()
	self:DismissAll()
	self._groups = {}
	if self._container and self._container.Parent then
		self._container.Parent:Destroy()
	end
end

return NotificationSystem