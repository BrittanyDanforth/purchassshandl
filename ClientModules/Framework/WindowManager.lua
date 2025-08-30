--[[
    Module: WindowManager
    Description: Manages overlay windows, draggable panels, window stacking, focus management,
                 and proper cleanup for all UI windows
    Features: Draggable windows, z-index management, minimize/maximize, window animations
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local WindowManager = {}
WindowManager.__index = WindowManager

-- ========================================
-- TYPES
-- ========================================

type WindowOptions = {
    title: string?,
    size: Vector2?,
    position: UDim2?,
    canClose: boolean?,
    canMinimize: boolean?,
    canResize: boolean?,
    draggable: boolean?,
    modal: boolean?,
    zIndex: number?,
    backgroundColor: Color3?,
    headerColor: Color3?,
    onClose: (() -> ())?,
    onMinimize: (() -> ())?,
    onFocus: (() -> ())?,
}

type Window = {
    id: string,
    frame: Frame,
    overlay: Frame?,
    header: Frame?,
    content: Frame,
    options: WindowOptions,
    state: "normal" | "minimized" | "maximized" | "closed",
    zIndex: number,
    isDragging: boolean,
    dragConnection: RBXScriptConnection?,
    minimizedPosition: UDim2?,
    normalSize: UDim2,
    normalPosition: UDim2,
}

type DragState = {
    isDragging: boolean,
    dragStart: Vector3?,
    startPos: UDim2?,
    connections: {RBXScriptConnection},
}

-- ========================================
-- CONSTANTS
-- ========================================

local DEFAULT_WINDOW_SIZE = Vector2.new(600, 400)
local DEFAULT_HEADER_HEIGHT = 50
local MINIMIZE_SIZE = Vector2.new(300, 50)
local WINDOW_PADDING = 20
local HEADER_BUTTON_SIZE = 30
local RESIZE_HANDLE_SIZE = 20
local MIN_WINDOW_SIZE = Vector2.new(300, 200)
local MAX_WINDOWS = 20
local MINIMIZE_SPACING = 10
local ANIMATION_TIME = 0.3

-- ========================================
-- INITIALIZATION
-- ========================================

function WindowManager.new(dependencies)
    local self = setmetatable({}, WindowManager)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._animationSystem = dependencies.AnimationSystem
    self._soundSystem = dependencies.SoundSystem
    self._uiFactory = dependencies.UIFactory
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- Window tracking
    self._windows = {} -- Active windows by ID
    self._windowStack = {} -- Stack for z-index management
    self._minimizedWindows = {} -- Minimized window positions
    self._activeOverlays = {} -- Modal overlays
    
    -- Main window module tracking
    self._currentWindow = nil -- The module of the currently open window (e.g., InventoryUI)
    self._isTransitioning = false -- Flag to prevent clicks during animation
    
    -- State
    self._nextWindowId = 0
    self._baseZIndex = self._config.ZINDEX.Window or 50
    self._currentZIndex = self._baseZIndex
    self._focusedWindow = nil
    self._dragStates = {} -- Drag states by window ID
    
    -- Settings
    self._enableAnimations = true
    self._enableSounds = true
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Container reference
    self._container = nil
    
    self:Initialize()
    
    return self
end

function WindowManager:Initialize(screenGui: ScreenGui?)
    -- Store container reference
    self._container = screenGui
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    -- Create minimize dock
    if self._container then
        self:CreateMinimizeDock()
    end
    
    if self._debugMode then
        print("[WindowManager] Initialized" .. (screenGui and " with ScreenGui" or " without ScreenGui"))
    end
end

function WindowManager:GetMainPanel(): Instance?
    -- If we have a container (ScreenGui), look for the actual MainPanel inside it
    if self._container then
        -- First check for MainUIPanel (created by MainUI)
        local mainPanel = self._container:FindFirstChild("MainContainer") and 
                         self._container.MainContainer:FindFirstChild("MainUIPanel")
        if mainPanel then
            return mainPanel
        end
        
        -- Fallback to MainContainer if MainUIPanel not found
        local mainContainer = self._container:FindFirstChild("MainContainer")
        if mainContainer then
            return mainContainer
        end
    end
    
    -- Last resort, return the container itself
    return self._container
end

-- ========================================
-- WINDOW CREATION
-- ========================================

function WindowManager:CreateWindow(options: WindowOptions?): string
    options = options or {}
    
    -- Generate window ID
    local windowId = self:GenerateId()
    
    -- Get container (usually MainUI.ScreenGui)
    local container = self._container or Services.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("SanrioTycoonUI")
    if not container then
        warn("[WindowManager] No container found")
        return windowId
    end
    
    -- Create overlay if modal
    local overlay
    if options.modal then
        overlay = self:CreateModalOverlay(windowId)
    end
    
    -- Create window frame
    local windowFrame = Instance.new("Frame")
    windowFrame.Name = (options.title or "Window") .. "_" .. windowId
    windowFrame.Size = options.size and UDim2.new(0, options.size.X, 0, options.size.Y) or 
                       UDim2.new(0, DEFAULT_WINDOW_SIZE.X, 0, DEFAULT_WINDOW_SIZE.Y)
    windowFrame.Position = options.position or self:GetCenteredPosition(windowFrame.Size)
    windowFrame.BackgroundColor3 = options.backgroundColor or self._config.COLORS.Background
    windowFrame.BorderSizePixel = 0
    windowFrame.ClipsDescendants = true
    windowFrame.ZIndex = options.zIndex or self:GetNextZIndex()
    windowFrame.Parent = container
    
    self._utilities.CreateCorner(windowFrame, 12)
    
    -- Create shadow (disabled per user feedback)
    -- self._utilities.CreateShadow(windowFrame)
    
    -- Create header if window has title or controls
    local header
    if options.title or options.canClose ~= false or options.canMinimize then
        header = self:CreateWindowHeader(windowFrame, options, windowId)
    end
    
    -- Create content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -WINDOW_PADDING * 2, 1, -(header and DEFAULT_HEADER_HEIGHT or 0) - WINDOW_PADDING * 2)
    content.Position = UDim2.new(0, WINDOW_PADDING, 0, (header and DEFAULT_HEADER_HEIGHT or 0) + WINDOW_PADDING)
    content.BackgroundTransparency = 1
    content.ZIndex = windowFrame.ZIndex + 1
    content.Parent = windowFrame
    
    -- Create resize handle if enabled
    if options.canResize then
        self:CreateResizeHandle(windowFrame, windowId)
    end
    
    -- Make draggable if enabled
    if options.draggable ~= false and header then
        self:MakeWindowDraggable(windowFrame, header, windowId)
    end
    
    -- Create window object
    local window: Window = {
        id = windowId,
        frame = windowFrame,
        overlay = overlay,
        header = header,
        content = content,
        options = options,
        state = "normal",
        zIndex = windowFrame.ZIndex,
        isDragging = false,
        dragConnection = nil,
        minimizedPosition = nil,
        normalSize = windowFrame.Size,
        normalPosition = windowFrame.Position,
    }
    
    -- Track window
    self._windows[windowId] = window
    table.insert(self._windowStack, windowId)
    
    -- Focus window
    self:FocusWindow(windowId)
    
    -- Animate in
    if self._enableAnimations then
        windowFrame.Size = UDim2.new(0, 0, 0, 0)
        windowFrame.Position = windowFrame.Position + UDim2.new(0, DEFAULT_WINDOW_SIZE.X / 2, 0, DEFAULT_WINDOW_SIZE.Y / 2)
        
        if self._animationSystem then
            self._animationSystem:Animate(windowFrame, {
                Size = window.normalSize,
                Position = window.normalPosition,
            }, {
                duration = ANIMATION_TIME,
                easingStyle = Enum.EasingStyle.Back,
                easingDirection = Enum.EasingDirection.Out,
            })
        else
            self._utilities.Tween(windowFrame, {
                Size = window.normalSize,
                Position = window.normalPosition,
            }, TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        end
    end
    
    -- Play sound
    if self._enableSounds and self._soundSystem then
        self._soundSystem:PlayUISound("Open")
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("WindowCreated", {
            id = windowId,
            title = options.title,
        })
    end
    
    return windowId
end

-- ========================================
-- WINDOW HEADER
-- ========================================

function WindowManager:CreateWindowHeader(windowFrame: Frame, options: WindowOptions, windowId: string): Frame
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, DEFAULT_HEADER_HEIGHT)
    header.BackgroundColor3 = options.headerColor or self._config.COLORS.Primary
    header.BorderSizePixel = 0
    header.ZIndex = windowFrame.ZIndex + 2
    header.Parent = windowFrame
    
    self._utilities.CreateCorner(header, 12)
    
    -- Title
    if options.title then
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -100, 1, 0)
        title.Position = UDim2.new(0, 20, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = options.title
        title.TextColor3 = self._config.COLORS.White
        title.Font = self._config.FONTS.Display
        title.TextScaled = true
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.ZIndex = header.ZIndex + 1
        title.Parent = header
        
        local textConstraint = Instance.new("UITextSizeConstraint")
        textConstraint.MaxTextSize = 20
        textConstraint.MinTextSize = 14
        textConstraint.Parent = title
    end
    
    -- Control buttons container
    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(0, 100, 1, 0)
    controls.Position = UDim2.new(1, -100, 0, 0)
    controls.BackgroundTransparency = 1
    controls.ZIndex = header.ZIndex + 1
    controls.Parent = header
    
    local controlLayout = Instance.new("UIListLayout")
    controlLayout.FillDirection = Enum.FillDirection.Horizontal
    controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlLayout.Padding = UDim.new(0, 5)
    controlLayout.Parent = controls
    
    self._utilities.CreatePadding(controls, {Right = 10})
    
    -- Minimize button
    if options.canMinimize then
        local minimizeBtn = self:CreateHeaderButton("−", function()
            self:MinimizeWindow(windowId)
        end)
        minimizeBtn.Parent = controls
    end
    
    -- Close button
    if options.canClose ~= false then
        local closeBtn = self:CreateHeaderButton("×", function()
            self:CloseWindow(windowId)
        end)
        closeBtn.TextColor3 = self._config.COLORS.Error
        closeBtn.Parent = controls
    end
    
    return header
end

function WindowManager:CreateHeaderButton(text: string, callback: () -> ()): TextButton
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = UDim2.new(0, HEADER_BUTTON_SIZE, 0, HEADER_BUTTON_SIZE)
    button.BackgroundColor3 = self._config.COLORS.White
    button.BackgroundTransparency = 0.8
    button.Text = text
    button.TextColor3 = self._config.COLORS.Dark
    button.Font = self._config.FONTS.Display
    button.TextScaled = true
    button.BorderSizePixel = 0
    
    self._utilities.CreateCorner(button, 6)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        self._utilities.Tween(button, {
            BackgroundTransparency = 0.6
        }, self._config.TWEEN_INFO.Fast)
    end)
    
    button.MouseLeave:Connect(function()
        self._utilities.Tween(button, {
            BackgroundTransparency = 0.8
        }, self._config.TWEEN_INFO.Fast)
    end)
    
    button.MouseButton1Click:Connect(function()
        if self._soundSystem then
            self._soundSystem:PlayUISound("Click")
        end
        callback()
    end)
    
    return button
end

-- ========================================
-- DRAGGABLE FUNCTIONALITY
-- ========================================

function WindowManager:MakeWindowDraggable(windowFrame: Frame, dragHandle: Frame, windowId: string)
    local dragState: DragState = {
        isDragging = false,
        dragStart = nil,
        startPos = nil,
        connections = {},
    }
    
    self._dragStates[windowId] = dragState
    
    -- Start dragging
    table.insert(dragState.connections, dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragState.isDragging = true
            dragState.dragStart = input.Position
            dragState.startPos = windowFrame.Position
            
            -- Focus window when dragging starts
            self:FocusWindow(windowId)
            
            -- Change cursor
            if dragHandle:IsA("ImageButton") then
                dragHandle.MouseIcon = "rbxasset://SystemCursors/ClosedHand"
            end
        end
    end))
    
    -- Update drag
    table.insert(dragState.connections, Services.UserInputService.InputChanged:Connect(function(input)
        if dragState.isDragging and 
           (input.UserInputType == Enum.UserInputType.MouseMovement or 
            input.UserInputType == Enum.UserInputType.Touch) then
            
            local delta = input.Position - dragState.dragStart
            local newPosition = UDim2.new(
                dragState.startPos.X.Scale,
                dragState.startPos.X.Offset + delta.X,
                dragState.startPos.Y.Scale,
                dragState.startPos.Y.Offset + delta.Y
            )
            
            -- Constrain to screen bounds
            local screenSize = workspace.CurrentCamera.ViewportSize
            local frameSize = windowFrame.AbsoluteSize
            
            local minX = -frameSize.X / 2
            local maxX = screenSize.X - frameSize.X / 2
            local minY = 0
            local maxY = screenSize.Y - frameSize.Y / 2
            
            newPosition = UDim2.new(
                0,
                math.clamp(newPosition.X.Offset, minX, maxX),
                0,
                math.clamp(newPosition.Y.Offset, minY, maxY)
            )
            
            windowFrame.Position = newPosition
        end
    end))
    
    -- End dragging
    table.insert(dragState.connections, Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragState.isDragging = false
            
            -- Reset cursor
            if dragHandle:IsA("ImageButton") then
                dragHandle.MouseIcon = "rbxasset://SystemCursors/Arrow"
            end
            
            -- Update window position
            local window = self._windows[windowId]
            if window then
                window.normalPosition = windowFrame.Position
            end
        end
    end))
end

-- ========================================
-- RESIZE FUNCTIONALITY
-- ========================================

function WindowManager:CreateResizeHandle(windowFrame: Frame, windowId: string)
    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, RESIZE_HANDLE_SIZE, 0, RESIZE_HANDLE_SIZE)
    resizeHandle.Position = UDim2.new(1, -RESIZE_HANDLE_SIZE, 1, -RESIZE_HANDLE_SIZE)
    resizeHandle.BackgroundColor3 = self._config.COLORS.Primary
    resizeHandle.BackgroundTransparency = 0.5
    resizeHandle.BorderSizePixel = 0
    resizeHandle.ZIndex = windowFrame.ZIndex + 10
    resizeHandle.Parent = windowFrame
    
    self._utilities.CreateCorner(resizeHandle, 4)
    
    -- Resize cursor
    resizeHandle.MouseEnter:Connect(function()
        resizeHandle.MouseIcon = "rbxasset://SystemCursors/SizeNWSE"
    end)
    
    resizeHandle.MouseLeave:Connect(function()
        resizeHandle.MouseIcon = ""
    end)
    
    -- Resize logic
    local resizing = false
    local startSize
    local startPos
    
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            startSize = windowFrame.AbsoluteSize
            startPos = input.Position
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startPos
            local newWidth = math.max(MIN_WINDOW_SIZE.X, startSize.X + delta.X)
            local newHeight = math.max(MIN_WINDOW_SIZE.Y, startSize.Y + delta.Y)
            
            windowFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
            
            -- Update window size
            local window = self._windows[windowId]
            if window then
                window.normalSize = windowFrame.Size
            end
        end
    end)
    
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
end

-- ========================================
-- WINDOW OPERATIONS
-- ========================================

function WindowManager:CloseWindow(windowId: string)
    local window = self._windows[windowId]
    if not window then return end
    
    window.state = "closed"
    
    -- Call close callback
    if window.options.onClose then
        window.options.onClose()
    end
    
    -- Animate out
    if self._enableAnimations then
        if self._animationSystem then
            self._animationSystem:Animate(window.frame, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = window.frame.Position + UDim2.new(0, window.frame.AbsoluteSize.X / 2, 0, window.frame.AbsoluteSize.Y / 2),
            }, {
                duration = ANIMATION_TIME,
                easingStyle = Enum.EasingStyle.Back,
                easingDirection = Enum.EasingDirection.In,
                onComplete = function()
                    self:DestroyWindow(windowId)
                end,
            })
        else
            self._utilities.Tween(window.frame, {
                Size = UDim2.new(0, 0, 0, 0),
            }, TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In))
            
            task.wait(ANIMATION_TIME)
            self:DestroyWindow(windowId)
        end
    else
        self:DestroyWindow(windowId)
    end
    
    -- Play sound
    if self._enableSounds and self._soundSystem then
        self._soundSystem:PlayUISound("Close")
    end
end

function WindowManager:DestroyWindow(windowId: string)
    local window = self._windows[windowId]
    if not window then return end
    
    -- Clean up drag state
    local dragState = self._dragStates[windowId]
    if dragState then
        for _, connection in ipairs(dragState.connections) do
            connection:Disconnect()
        end
        self._dragStates[windowId] = nil
    end
    
    -- Destroy overlay
    if window.overlay then
        window.overlay:Destroy()
    end
    
    -- Destroy frame
    window.frame:Destroy()
    
    -- Remove from tracking
    self._windows[windowId] = nil
    
    -- Remove from stack
    for i, id in ipairs(self._windowStack) do
        if id == windowId then
            table.remove(self._windowStack, i)
            break
        end
    end
    
    -- Remove from minimized
    self._minimizedWindows[windowId] = nil
    
    -- Focus next window
    if self._focusedWindow == windowId and #self._windowStack > 0 then
        self:FocusWindow(self._windowStack[#self._windowStack])
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("WindowClosed", {
            id = windowId,
        })
    end
end

function WindowManager:MinimizeWindow(windowId: string)
    local window = self._windows[windowId]
    if not window or window.state == "minimized" then return end
    
    window.state = "minimized"
    
    -- Store current position
    window.minimizedPosition = self:GetNextMinimizedPosition()
    
    -- Animate to minimized state
    if self._animationSystem then
        self._animationSystem:Animate(window.frame, {
            Size = UDim2.new(0, MINIMIZE_SIZE.X, 0, MINIMIZE_SIZE.Y),
            Position = window.minimizedPosition,
        }, {
            duration = ANIMATION_TIME,
            easingStyle = Enum.EasingStyle.Quad,
        })
    else
        self._utilities.Tween(window.frame, {
            Size = UDim2.new(0, MINIMIZE_SIZE.X, 0, MINIMIZE_SIZE.Y),
            Position = window.minimizedPosition,
        }, self._config.TWEEN_INFO.Normal)
    end
    
    -- Hide content
    if window.content then
        window.content.Visible = false
    end
    
    -- Track minimized window
    self._minimizedWindows[windowId] = true
    
    -- Call minimize callback
    if window.options.onMinimize then
        window.options.onMinimize()
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("WindowMinimized", {
            id = windowId,
        })
    end
end

function WindowManager:RestoreWindow(windowId: string)
    local window = self._windows[windowId]
    if not window or window.state ~= "minimized" then return end
    
    window.state = "normal"
    
    -- Show content
    if window.content then
        window.content.Visible = true
    end
    
    -- Animate to normal state
    if self._animationSystem then
        self._animationSystem:Animate(window.frame, {
            Size = window.normalSize,
            Position = window.normalPosition,
        }, {
            duration = ANIMATION_TIME,
            easingStyle = Enum.EasingStyle.Quad,
        })
    else
        self._utilities.Tween(window.frame, {
            Size = window.normalSize,
            Position = window.normalPosition,
        }, self._config.TWEEN_INFO.Normal)
    end
    
    -- Remove from minimized tracking
    self._minimizedWindows[windowId] = nil
    
    -- Focus window
    self:FocusWindow(windowId)
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("WindowRestored", {
            id = windowId,
        })
    end
end

function WindowManager:FocusWindow(windowId: string)
    local window = self._windows[windowId]
    if not window then return end
    
    -- Update z-index
    self._currentZIndex = self._currentZIndex + 1
    window.frame.ZIndex = self._currentZIndex
    window.zIndex = self._currentZIndex
    
    -- Update all child z-indices
    self:UpdateWindowZIndex(window.frame, self._currentZIndex)
    
    -- Move to top of stack
    for i, id in ipairs(self._windowStack) do
        if id == windowId then
            table.remove(self._windowStack, i)
            break
        end
    end
    table.insert(self._windowStack, windowId)
    
    -- Update focused window
    self._focusedWindow = windowId
    
    -- Call focus callback
    if window.options.onFocus then
        window.options.onFocus()
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("WindowFocused", {
            id = windowId,
        })
    end
end

-- ========================================
-- MODAL OVERLAYS
-- ========================================

function WindowManager:CreateModalOverlay(windowId: string): Frame
    local container = self._container or Services.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("SanrioTycoonUI")
    
    local overlay = Instance.new("Frame")
    overlay.Name = "ModalOverlay_" .. windowId
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = self:GetNextZIndex() - 1
    overlay.Parent = container
    
    -- Animate in
    if self._enableAnimations then
        overlay.BackgroundTransparency = 1
        self._utilities.Tween(overlay, {
            BackgroundTransparency = 0.5
        }, self._config.TWEEN_INFO.Fast)
    end
    
    self._activeOverlays[windowId] = overlay
    
    return overlay
end

-- ========================================
-- MINIMIZE DOCK
-- ========================================

function WindowManager:CreateMinimizeDock()
    -- This would create a dock area for minimized windows
    -- For now, we'll use bottom-left positioning
end

function WindowManager:GetNextMinimizedPosition(): UDim2
    local count = 0
    for _ in pairs(self._minimizedWindows) do
        count = count + 1
    end
    
    local x = MINIMIZE_SPACING + (count * (MINIMIZE_SIZE.X + MINIMIZE_SPACING))
    local y = workspace.CurrentCamera.ViewportSize.Y - MINIMIZE_SIZE.Y - MINIMIZE_SPACING
    
    return UDim2.new(0, x, 0, y)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function WindowManager:GetWindow(windowId: string): Window?
    return self._windows[windowId]
end

function WindowManager:GetWindowContent(windowId: string): Frame?
    local window = self._windows[windowId]
    return window and window.content
end

function WindowManager:SetContainer(container: Instance)
    self._container = container
end

function WindowManager:GetNextZIndex(): number
    self._currentZIndex = self._currentZIndex + 10
    return self._currentZIndex
end

function WindowManager:GetCenteredPosition(size: UDim2): UDim2
    local screenSize = workspace.CurrentCamera.ViewportSize
    local windowWidth = size.X.Offset
    local windowHeight = size.Y.Offset
    
    return UDim2.new(0, (screenSize.X - windowWidth) / 2, 0, (screenSize.Y - windowHeight) / 2)
end

function WindowManager:UpdateWindowZIndex(frame: Instance, baseZIndex: number)
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            child.ZIndex = baseZIndex + (child.ZIndex - frame.ZIndex)
        end
    end
end

function WindowManager:GenerateId(): string
    self._nextWindowId = self._nextWindowId + 1
    return "window_" .. tostring(self._nextWindowId)
end

function WindowManager:GetActiveWindowCount(): number
    local count = 0
    for _ in pairs(self._windows) do
        count = count + 1
    end
    return count
end

function WindowManager:CloseAllWindows()
    for windowId in pairs(self._windows) do
        self:CloseWindow(windowId)
    end
end

-- ========================================
-- EVENT LISTENERS
-- ========================================

function WindowManager:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Listen for window requests
    self._eventBus:On("CreateWindow", function(data)
        return self:CreateWindow(data.options)
    end)
    
    self._eventBus:On("CloseWindow", function(data)
        self:CloseWindow(data.id)
    end)
    
    self._eventBus:On("MinimizeWindow", function(data)
        self:MinimizeWindow(data.id)
    end)
    
    self._eventBus:On("RestoreWindow", function(data)
        self:RestoreWindow(data.id)
    end)
    
    self._eventBus:On("FocusWindow", function(data)
        self:FocusWindow(data.id)
    end)
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function WindowManager:DebugPrint()
        print("\n=== WindowManager Debug Info ===")
        print("Active Windows:", self:GetActiveWindowCount())
        print("Current Z-Index:", self._currentZIndex)
        print("Focused Window:", self._focusedWindow or "None")
        
        print("\nWindow Stack:")
        for i, windowId in ipairs(self._windowStack) do
            local window = self._windows[windowId]
            if window then
                print("  " .. i .. ":", windowId, "-", window.options.title or "Untitled", 
                      "(" .. window.state .. ")")
            end
        end
        
        print("\nMinimized Windows:")
        for windowId in pairs(self._minimizedWindows) do
            print("  " .. windowId)
        end
        
        print("===========================\n")
    end
end

-- ========================================
-- MAIN WINDOW TRANSITIONS
-- ========================================

function WindowManager:OpenWindow(windowModule)
    -- If we're already animating, ignore the click
    if self._isTransitioning then
        if self._debugMode then
            print("[WindowManager] Transition in progress, ignoring request")
        end
        return
    end
    
    -- If the requested window is already open, do nothing
    if self._currentWindow == windowModule then
        if self._debugMode then
            print("[WindowManager] Window already open:", windowModule)
        end
        return
    end
    
    -- Start the transition!
    self._isTransitioning = true
    
    if self._debugMode then
        print("[WindowManager] Starting transition to:", windowModule)
    end
    
    -- Create a coroutine for the transition
    task.spawn(function()
        -- If a different window is already open, close it first
        if self._currentWindow then
            if self._debugMode then
                print("[WindowManager] Closing current window")
            end
            
            -- Tell the old window to play its close animation
            if self._currentWindow.AnimateClose then
                self._currentWindow:AnimateClose()
            elseif self._currentWindow.Close then
                self._currentWindow:Close()
            end
            
            -- Don't wait, just continue immediately
        end
        
        -- Now, open the new window
        self._currentWindow = windowModule
        
        if self._currentWindow then
            if self._debugMode then
                print("[WindowManager] Opening new window")
            end
            
            -- Initialize if needed
            if self._currentWindow.Initialize then
                self._currentWindow:Initialize()
            end
            
            -- Tell the new window to play its open animation
            if self._currentWindow.AnimateOpen then
                self._currentWindow:AnimateOpen()
            elseif self._currentWindow.Open then
                self._currentWindow:Open()
            end
            
            -- Don't wait, call OnReady immediately
            
            -- IMPORTANT: Tell the module it's ready for data loading
            if self._currentWindow.OnReady then
                if self._debugMode then
                    print("[WindowManager] Calling OnReady")
                end
                self._currentWindow:OnReady()
            end
        end
        
        -- Transition is complete, we can accept clicks again
        self._isTransitioning = false
        
        if self._debugMode then
            print("[WindowManager] Transition complete")
        end
    end)
end

function WindowManager:CloseCurrentWindow()
    if self._isTransitioning or not self._currentWindow then
        return
    end
    
    self._isTransitioning = true
    
    task.spawn(function()
        if self._currentWindow then
            -- Tell window to animate close
            if self._currentWindow.AnimateClose then
                self._currentWindow:AnimateClose()
            elseif self._currentWindow.Close then
                self._currentWindow:Close()
            end
            
            task.wait(0.3)
            
            -- Call OnClosed if available
            if self._currentWindow.OnClosed then
                self._currentWindow:OnClosed()
            end
            
            self._currentWindow = nil
        end
        
        self._isTransitioning = false
    end)
end

function WindowManager:GetCurrentWindow()
    return self._currentWindow
end

function WindowManager:IsTransitioning(): boolean
    return self._isTransitioning
end

-- ========================================
-- CLEANUP
-- ========================================

function WindowManager:Destroy()
    -- Close current main window
    if self._currentWindow then
        self:CloseCurrentWindow()
    end
    
    -- Close all windows
    self:CloseAllWindows()
    
    -- Clean up drag states
    for _, dragState in pairs(self._dragStates) do
        for _, connection in ipairs(dragState.connections) do
            connection:Disconnect()
        end
    end
    
    -- Clear references
    self._windows = {}
    self._windowStack = {}
    self._minimizedWindows = {}
    self._activeOverlays = {}
    self._dragStates = {}
    self._currentWindow = nil
end

return WindowManager