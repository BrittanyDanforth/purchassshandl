--[[
    Module: ClientUtilities
    Description: Comprehensive utility functions for the Sanrio Tycoon client
    Includes formatting, UI helpers, validation, and common operations
]]

local Services = require(script.Parent.ClientServices)
local Config = require(script.Parent.ClientConfig)
local Types = require(script.Parent.ClientTypes)

local ClientUtilities = {}
ClientUtilities.__index = ClientUtilities

-- ========================================
-- NUMBER FORMATTING
-- ========================================

function ClientUtilities.FormatNumber(num: number?, decimals: number?): string
    -- Handle nil or invalid values
    if not num or type(num) ~= "number" then
        return "0"
    end
    
    -- Handle special numbers
    if num ~= num then -- NaN check
        return "0"
    end
    if num == math.huge then
        return "∞"
    end
    if num == -math.huge then
        return "-∞"
    end
    
    decimals = decimals or 2
    
    -- Format based on magnitude
    if num >= 1e15 then
        return string.format("%."..decimals.."fQ", num / 1e15) -- Quadrillion
    elseif num >= 1e12 then
        return string.format("%."..decimals.."fT", num / 1e12) -- Trillion
    elseif num >= 1e9 then
        return string.format("%."..decimals.."fB", num / 1e9)  -- Billion
    elseif num >= 1e6 then
        return string.format("%."..decimals.."fM", num / 1e6)  -- Million
    elseif num >= 1e3 then
        return string.format("%."..decimals.."fK", num / 1e3)  -- Thousand
    else
        -- For small numbers, show as integer or with decimals
        if num == math.floor(num) then
            return tostring(math.floor(num))
        else
            return string.format("%."..decimals.."f", num)
        end
    end
end

function ClientUtilities.FormatNumberCommas(num: number): string
    -- Add commas to large numbers (e.g., 1,234,567)
    if not num or type(num) ~= "number" then
        return "0"
    end
    
    local formatted = tostring(math.floor(num))
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then
            break
        end
    end
    
    return formatted
end

function ClientUtilities.FormatPercent(value: number, total: number): string
    if not value or not total or total == 0 then
        return "0%"
    end
    
    local percent = (value / total) * 100
    return string.format("%.1f%%", percent)
end

-- ========================================
-- TIME FORMATTING
-- ========================================

function ClientUtilities.FormatTime(seconds: number, format: string?): string
    if not seconds or type(seconds) ~= "number" or seconds < 0 then
        return "0s"
    end
    
    format = format or "auto"
    
    if format == "auto" then
        if seconds < 60 then
            return string.format("%ds", math.floor(seconds))
        elseif seconds < 3600 then
            return string.format("%dm %ds", math.floor(seconds / 60), math.floor(seconds % 60))
        elseif seconds < 86400 then
            return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
        else
            return string.format("%dd %dh", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
        end
    elseif format == "short" then
        if seconds < 60 then
            return string.format("%ds", math.floor(seconds))
        elseif seconds < 3600 then
            return string.format("%dm", math.floor(seconds / 60))
        elseif seconds < 86400 then
            return string.format("%dh", math.floor(seconds / 3600))
        else
            return string.format("%dd", math.floor(seconds / 86400))
        end
    elseif format == "clock" then
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%ds", math.floor(seconds))
    end
end

function ClientUtilities.FormatDate(timestamp: number): string
    if not timestamp or type(timestamp) ~= "number" then
        return "Unknown"
    end
    
    local date = os.date("*t", timestamp)
    return string.format("%02d/%02d/%04d %02d:%02d", 
        date.month, date.day, date.year, date.hour, date.min)
end

function ClientUtilities.GetTimeAgo(timestamp: number): string
    if not timestamp then
        return "Unknown"
    end
    
    local now = os.time()
    local diff = now - timestamp
    
    if diff < 60 then
        return "Just now"
    elseif diff < 3600 then
        local mins = math.floor(diff / 60)
        return mins == 1 and "1 minute ago" or mins .. " minutes ago"
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return hours == 1 and "1 hour ago" or hours .. " hours ago"
    elseif diff < 604800 then
        local days = math.floor(diff / 86400)
        return days == 1 and "1 day ago" or days .. " days ago"
    else
        return ClientUtilities.FormatDate(timestamp)
    end
end

-- ========================================
-- COLOR UTILITIES
-- ========================================

function ClientUtilities.GetRarityColor(rarity: number): Color3
    return Config.RARITY_COLORS[rarity] or Config.COLORS.White
end

function ClientUtilities.GetRarityName(rarity: number): string
    return Config.RARITY_NAMES[rarity] or "Unknown"
end

function ClientUtilities.LerpColor(color1: Color3, color2: Color3, alpha: number): Color3
    alpha = math.clamp(alpha, 0, 1)
    return Color3.new(
        color1.R + (color2.R - color1.R) * alpha,
        color1.G + (color2.G - color1.G) * alpha,
        color1.B + (color2.B - color1.B) * alpha
    )
end

function ClientUtilities.DarkenColor(color: Color3, amount: number): Color3
    amount = math.clamp(amount, 0, 1)
    return Color3.new(
        color.R * (1 - amount),
        color.G * (1 - amount),
        color.B * (1 - amount)
    )
end

function ClientUtilities.LightenColor(color: Color3, amount: number): Color3
    amount = math.clamp(amount, 0, 1)
    return Color3.new(
        color.R + (1 - color.R) * amount,
        color.G + (1 - color.G) * amount,
        color.B + (1 - color.B) * amount
    )
end

-- ========================================
-- UI CREATION HELPERS
-- ========================================

function ClientUtilities.CreateGradient(parent: Instance, colors: {Color3}, rotation: number?): UIGradient
    local gradient = Instance.new("UIGradient")
    
    if #colors == 1 then
        gradient.Color = ColorSequence.new(colors[1])
    elseif #colors == 2 then
        gradient.Color = ColorSequence.new(colors[1], colors[2])
    else
        local keypoints = {}
        for i, color in ipairs(colors) do
            local time = (i - 1) / (#colors - 1)
            table.insert(keypoints, ColorSequenceKeypoint.new(time, color))
        end
        gradient.Color = ColorSequence.new(keypoints)
    end
    
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

function ClientUtilities.CreateCorner(parent: Instance, radius: number?): UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Config.UI.CORNER_RADIUS)
    corner.Parent = parent
    return corner
end

function ClientUtilities.CreateStroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.COLORS.Dark
    stroke.Thickness = thickness or Config.UI.STROKE_THICKNESS
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function ClientUtilities.CreatePadding(parent: Instance, padding: number | {Top: number?, Bottom: number?, Left: number?, Right: number?}): UIPadding
    local uiPadding = Instance.new("UIPadding")
    
    if type(padding) == "number" then
        uiPadding.PaddingTop = UDim.new(0, padding)
        uiPadding.PaddingBottom = UDim.new(0, padding)
        uiPadding.PaddingLeft = UDim.new(0, padding)
        uiPadding.PaddingRight = UDim.new(0, padding)
    else
        uiPadding.PaddingTop = UDim.new(0, padding.Top or 0)
        uiPadding.PaddingBottom = UDim.new(0, padding.Bottom or 0)
        uiPadding.PaddingLeft = UDim.new(0, padding.Left or 0)
        uiPadding.PaddingRight = UDim.new(0, padding.Right or 0)
    end
    
    uiPadding.Parent = parent
    return uiPadding
end

function ClientUtilities.CreateListLayout(parent: Instance, fillDirection: Enum.FillDirection?, padding: number?): UIListLayout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = fillDirection or Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, padding or Config.UI.PADDING)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

function ClientUtilities.CreateGridLayout(parent: Instance, cellSize: UDim2, cellPadding: UDim2?): UIGridLayout
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = cellSize
    layout.CellPadding = cellPadding or UDim2.new(0, Config.UI.PADDING, 0, Config.UI.PADDING)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

function ClientUtilities.CreateScale(parent: Instance, scale: number?): UIScale
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = scale or 1
    uiScale.Parent = parent
    return uiScale
end

function ClientUtilities.CreateAspectRatio(parent: Instance, ratio: number): UIAspectRatioConstraint
    local constraint = Instance.new("UIAspectRatioConstraint")
    constraint.AspectRatio = ratio
    constraint.Parent = parent
    return constraint
end

-- ========================================
-- TWEEN UTILITIES
-- ========================================

function ClientUtilities.Tween(object: Instance, properties: {[string]: any}, tweenInfo: TweenInfo?): Tween
    tweenInfo = tweenInfo or Config.TWEEN_INFO.Normal
    local tween = Services.TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function ClientUtilities.TweenSequence(object: Instance, sequence: {{properties: {[string]: any}, info: TweenInfo?}}): ()
    local function runSequence(index)
        if index > #sequence then
            return
        end
        
        local step = sequence[index]
        local tween = ClientUtilities.Tween(object, step.properties, step.info)
        
        tween.Completed:Connect(function()
            runSequence(index + 1)
        end)
    end
    
    runSequence(1)
end

function ClientUtilities.Spring(object: Instance, property: string, target: number, damping: number?, frequency: number?)
    -- Simple spring animation (simplified version)
    damping = damping or 1
    frequency = frequency or 4
    
    local current = object[property]
    local velocity = 0
    local connection
    
    connection = Services.RunService.Heartbeat:Connect(function(dt)
        local displacement = target - current
        local springForce = displacement * frequency * frequency
        local dampingForce = velocity * 2 * damping * frequency
        
        local acceleration = springForce - dampingForce
        velocity = velocity + acceleration * dt
        current = current + velocity * dt
        
        object[property] = current
        
        -- Stop when close enough
        if math.abs(displacement) < 0.01 and math.abs(velocity) < 0.01 then
            object[property] = target
            connection:Disconnect()
        end
    end)
    
    return connection
end

-- ========================================
-- STRING UTILITIES
-- ========================================

function ClientUtilities.TruncateString(str: string, maxLength: number, suffix: string?): string
    if not str then
        return ""
    end
    
    suffix = suffix or "..."
    
    if #str <= maxLength then
        return str
    end
    
    return string.sub(str, 1, maxLength - #suffix) .. suffix
end

function ClientUtilities.SanitizeString(str: string): string
    if not str then
        return ""
    end
    
    -- Remove special characters that could cause issues
    str = string.gsub(str, "[<>\"'&]", "")
    
    -- Trim whitespace
    str = string.match(str, "^%s*(.-)%s*$")
    
    return str
end

function ClientUtilities.CapitalizeFirst(str: string): string
    if not str or #str == 0 then
        return ""
    end
    
    return string.upper(string.sub(str, 1, 1)) .. string.lower(string.sub(str, 2))
end

function ClientUtilities.CamelCaseToSpaced(str: string): string
    -- Convert "CamelCase" to "Camel Case"
    return string.gsub(str, "(%u)(%l)", " %1%2"):gsub("^%s+", "")
end

-- ========================================
-- TABLE UTILITIES
-- ========================================

function ClientUtilities.DeepCopy(original: any): any
    local copy
    
    if type(original) == "table" then
        copy = {}
        for key, value in pairs(original) do
            copy[ClientUtilities.DeepCopy(key)] = ClientUtilities.DeepCopy(value)
        end
        setmetatable(copy, ClientUtilities.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    
    return copy
end

function ClientUtilities.ShallowCopy(original: table): table
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

function ClientUtilities.TableContains(tbl: table, value: any): boolean
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function ClientUtilities.TableFind(tbl: table, predicate: (value: any, key: any) -> boolean): (any, any)
    for key, value in pairs(tbl) do
        if predicate(value, key) then
            return value, key
        end
    end
    return nil, nil
end

function ClientUtilities.TableFilter(tbl: table, predicate: (value: any, key: any) -> boolean): table
    local filtered = {}
    for key, value in pairs(tbl) do
        if predicate(value, key) then
            filtered[key] = value
        end
    end
    return filtered
end

function ClientUtilities.TableMap(tbl: table, mapper: (value: any, key: any) -> any): table
    local mapped = {}
    for key, value in pairs(tbl) do
        mapped[key] = mapper(value, key)
    end
    return mapped
end

-- ========================================
-- MATH UTILITIES
-- ========================================

function ClientUtilities.Clamp(value: number, min: number, max: number): number
    return math.max(min, math.min(max, value))
end

function ClientUtilities.Lerp(a: number, b: number, t: number): number
    return a + (b - a) * math.clamp(t, 0, 1)
end

function ClientUtilities.Round(value: number, decimals: number?): number
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

function ClientUtilities.RandomFloat(min: number, max: number): number
    return min + (max - min) * math.random()
end

function ClientUtilities.CalculateChance(percentage: number): boolean
    return math.random() * 100 <= percentage
end

-- ========================================
-- VALIDATION UTILITIES
-- ========================================

function ClientUtilities.ValidateType(value: any, expectedType: string): boolean
    return type(value) == expectedType
end

function ClientUtilities.ValidateEnum(value: any, enumType: Enum): boolean
    if type(value) ~= "userdata" then
        return false
    end
    
    -- Check if value is part of the enum
    for _, enumValue in pairs(enumType:GetEnumItems()) do
        if value == enumValue then
            return true
        end
    end
    
    return false
end

function ClientUtilities.ValidateBounds(value: number, min: number, max: number): boolean
    return value >= min and value <= max
end

function ClientUtilities.ValidateInstance(instance: any, className: string?): boolean
    if typeof(instance) ~= "Instance" then
        return false
    end
    
    if className then
        return instance:IsA(className)
    end
    
    return true
end

-- ========================================
-- MISC UTILITIES
-- ========================================

function ClientUtilities.GetDeviceType(): string
    if Services.UserInputService.TouchEnabled then
        return "Mobile"
    elseif Services.UserInputService.GamepadEnabled then
        return "Console"
    else
        return "PC"
    end
end

function ClientUtilities.WaitForPath(parent: Instance, path: string, timeout: number?): Instance?
    timeout = timeout or 10
    local segments = string.split(path, ".")
    local current = parent
    local startTime = tick()
    
    for _, segment in ipairs(segments) do
        local child = current:WaitForChild(segment, timeout - (tick() - startTime))
        if not child then
            warn("[ClientUtilities] Failed to find:", segment, "in", current:GetFullName())
            return nil
        end
        current = child
    end
    
    return current
end

function ClientUtilities.Debounce(func: (...any) -> any, delay: number): (...any) -> any
    local lastCall = 0
    
    return function(...)
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

function ClientUtilities.Throttle(func: (...any) -> any, delay: number): (...any) -> any
    local lastCall = 0
    local pending = false
    local pendingArgs = nil
    
    return function(...)
        local now = tick()
        local args = {...}
        
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        else
            pending = true
            pendingArgs = args
            
            task.wait(delay - (now - lastCall))
            
            if pending then
                pending = false
                lastCall = tick()
                return func(table.unpack(pendingArgs))
            end
        end
    end
end

function ClientUtilities.CreateUUID(): string
    -- Simple UUID v4 generator
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

-- Return the module
return ClientUtilities