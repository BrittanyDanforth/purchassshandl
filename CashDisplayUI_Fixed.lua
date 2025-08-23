--[[
    Cute Pastel Cash Display UI - FIXED VERSION
    - Uses your custom icon: 82206213521307
    - More transparent background
    - Fixed text visibility issues
    - Better contrast for numbers
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config
local ANIMATE_CHANGES = true
local CURRENCY_SYMBOL = "$"
local POLL_RATE = 0.5
local MIN_ANIMATE_DIFF = 10
local ICON_IMAGE_ID = "rbxassetid://82206213521307"  -- Your custom icon!

-- Pastel palette with MORE TRANSPARENCY
local COLORS = {
	background = Color3.fromRGB(255, 245, 250),
	panel      = Color3.fromRGB(245, 235, 255),
	accent     = Color3.fromRGB(255, 200, 221),
	secondary  = Color3.fromRGB(200, 230, 255),
	textDark   = Color3.fromRGB(60, 50, 70),      -- Darker for better contrast
	textLight  = Color3.fromRGB(255, 255, 255),
	positive   = Color3.fromRGB(120, 255, 150),   -- Brighter green
	negative   = Color3.fromRGB(255, 120, 120),   -- Brighter red
	shadow     = Color3.fromRGB(220, 210, 230),
	border     = Color3.fromRGB(230, 220, 240),
}

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CuteCashDisplay"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 50
screenGui.Parent = playerGui

-- Shadow container
local shadowFrame = Instance.new("Frame")
shadowFrame.Name = "Shadow"
shadowFrame.AnchorPoint = Vector2.new(1, 1)
shadowFrame.Position = UDim2.new(1, -25, 1, -140)
shadowFrame.Size = UDim2.new(0, 310, 0, 95)
shadowFrame.BackgroundColor3 = COLORS.shadow
shadowFrame.BackgroundTransparency = 0.7  -- More transparent shadow
shadowFrame.BorderSizePixel = 0
shadowFrame.ZIndex = 1
shadowFrame.Parent = screenGui

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 24)
shadowCorner.Parent = shadowFrame

-- Main panel (MORE TRANSPARENT)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "CashPanel"
mainPanel.Size = UDim2.new(1, -5, 1, -5)
mainPanel.Position = UDim2.new(0, 0, 0, 0)
mainPanel.BackgroundColor3 = COLORS.panel
mainPanel.BackgroundTransparency = 0.4  -- MORE SEE-THROUGH!
mainPanel.BorderSizePixel = 0
mainPanel.ZIndex = 2
mainPanel.Parent = shadowFrame

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = mainPanel

-- Gradient overlay (more subtle)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(245,240,255))
})
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new(0.3)  -- More transparent gradient
gradient.Parent = mainPanel

-- Stroke border (more visible)
local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.border
stroke.Transparency = 0.3  -- Less transparent border
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainPanel

-- Icon container (NOT TRANSPARENT)
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.Size = UDim2.new(0, 65, 0, 65)
iconContainer.Position = UDim2.new(0, 15, 0.5, 0)
iconContainer.AnchorPoint = Vector2.new(0, 0.5)
iconContainer.BackgroundColor3 = COLORS.accent
iconContainer.BackgroundTransparency = 0.15  -- Slightly transparent
iconContainer.BorderSizePixel = 0
iconContainer.ZIndex = 3
iconContainer.Parent = mainPanel

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = iconContainer

-- Use your custom icon
local iconLabel = Instance.new("ImageLabel")
iconLabel.Size = UDim2.new(0.8, 0, 0.8, 0)  -- Slightly smaller to fit nicely
iconLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Image = ICON_IMAGE_ID
iconLabel.ImageTransparency = 0  -- Fully visible icon
iconLabel.ScaleType = Enum.ScaleType.Fit
iconLabel.Parent = iconContainer

-- Text container
local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Size = UDim2.new(1, -95, 1, -20)
textContainer.Position = UDim2.new(0, 90, 0, 10)
textContainer.BackgroundTransparency = 1
textContainer.ZIndex = 3
textContainer.Parent = mainPanel

-- Small label "Cash" (darker for visibility)
local cashTitleLabel = Instance.new("TextLabel")
cashTitleLabel.Name = "CashTitle"
cashTitleLabel.Size = UDim2.new(1, 0, 0, 20)
cashTitleLabel.Position = UDim2.new(0, 0, 0, 5)
cashTitleLabel.BackgroundTransparency = 1
cashTitleLabel.Text = "Cash"
cashTitleLabel.TextColor3 = COLORS.textDark
cashTitleLabel.TextTransparency = 0  -- Fully visible
cashTitleLabel.Font = Enum.Font.Gotham
cashTitleLabel.TextScaled = true
cashTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
cashTitleLabel.Parent = textContainer

-- Add text stroke for better visibility
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(255, 255, 255)
titleStroke.Transparency = 0.7
titleStroke.Thickness = 1
titleStroke.Parent = cashTitleLabel

-- Large cash amount (FULLY VISIBLE)
local cashAmount = Instance.new("TextLabel")
cashAmount.Name = "Amount"
cashAmount.Size = UDim2.new(1, 0, 0, 36)
cashAmount.Position = UDim2.new(0, 0, 0, 26)
cashAmount.BackgroundTransparency = 1
cashAmount.Text = CURRENCY_SYMBOL .. "0"
cashAmount.TextColor3 = COLORS.textDark
cashAmount.TextTransparency = 0  -- FULLY VISIBLE!
cashAmount.Font = Enum.Font.GothamBold
cashAmount.TextScaled = true
cashAmount.TextXAlignment = Enum.TextXAlignment.Left
cashAmount.Parent = textContainer

-- Add stroke to cash amount for visibility
local amountStroke = Instance.new("UIStroke")
amountStroke.Color = Color3.fromRGB(255, 255, 255)
amountStroke.Transparency = 0.6
amountStroke.Thickness = 1.5
amountStroke.Parent = cashAmount

-- Change indicator
local changeIndicator = Instance.new("TextLabel")
changeIndicator.Name = "ChangeIndicator"
changeIndicator.Size = UDim2.new(0.6, 0, 0, 18)
changeIndicator.Position = UDim2.new(1, -5, 0.5, 0)
changeIndicator.AnchorPoint = Vector2.new(1, 0.5)
changeIndicator.BackgroundTransparency = 1
changeIndicator.Text = ""
changeIndicator.Font = Enum.Font.Gotham
changeIndicator.TextScaled = true
changeIndicator.TextXAlignment = Enum.TextXAlignment.Right
changeIndicator.TextTransparency = 1
changeIndicator.Parent = textContainer

-- variables
local currentCash = 0
local displayedCash = 0
local animating = false

-- formatting
local function formatNumber(num)
    if num >= 1e12 then
        return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        local formatted = tostring(math.floor(num))
        return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end
end

-- subtle animations when cash changes
local function animateCashChange(oldValue, newValue)
    local diff = newValue - oldValue
    if diff == 0 then return end

    local positive = diff > 0
    changeIndicator.Text = (positive and "+" or "") .. CURRENCY_SYMBOL .. formatNumber(math.abs(diff))
    changeIndicator.TextColor3 = positive and COLORS.positive or COLORS.negative
    changeIndicator.TextTransparency = 0
    changeIndicator.Position = UDim2.new(1, -5, 0.5, -6)

    -- Add stroke to change indicator
    local changeStroke = changeIndicator:FindFirstChild("UIStroke") or Instance.new("UIStroke")
    changeStroke.Color = Color3.fromRGB(255, 255, 255)
    changeStroke.Transparency = 0.5
    changeStroke.Thickness = 1
    changeStroke.Parent = changeIndicator

    -- float & fade
    local floatTween = TweenService:Create(changeIndicator, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -5, 0.5, -26),
        TextTransparency = 1
    })
    floatTween:Play()
    floatTween.Completed:Connect(function()
        changeIndicator.Position = UDim2.new(1, -5, 0.5, 0)
    end)

    -- icon bounce
    local bounce = TweenService:Create(iconContainer, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 72, 0, 72)
    })
    bounce:Play()
    bounce.Completed:Connect(function()
        TweenService:Create(iconContainer, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 65, 0, 65)
        }):Play()
    end)

    -- glow stroke
    local glow = TweenService:Create(stroke, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
        Color = positive and COLORS.positive or COLORS.negative,
        Thickness = 3,
        Transparency = 0.1
    })
    glow:Play()
    glow.Completed:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {
            Color = COLORS.border,
            Thickness = 2,
            Transparency = 0.3
        }):Play()
    end)

    -- number counting
    if ANIMATE_CHANGES and math.abs(diff) >= MIN_ANIMATE_DIFF then
        animating = true
        local start = tick()
        local duration = 0.55
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local t = math.min((tick() - start)/duration, 1)
            t = 1 - (1 - t) * (1 - t)
            displayedCash = math.floor(oldValue + diff * t)
            cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
            if t >= 1 then
                connection:Disconnect()
                displayedCash = newValue
                cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
                animating = false
            end
        end)
    else
        displayedCash = newValue
        cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(displayedCash)
    end
end

-- Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("CashUIRemotes")
local getCashRemote = remotesFolder and remotesFolder:FindFirstChild("GetPlayerCash")
local cashUpdateRemote = remotesFolder and remotesFolder:FindFirstChild("CashUpdated")

-- Update function
local function queryServerCash()
    if getCashRemote and getCashRemote:IsA("RemoteFunction") then
        local ok, value = pcall(function() return getCashRemote:InvokeServer() end)
        if ok and tonumber(value) then
            return tonumber(value)
        end
    end

    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local cashObj = stats:FindFirstChildWhichIsA("NumberValue") or stats:FindFirstChild("Cash") or stats:FindFirstChild("Money")
        if cashObj and tonumber(cashObj.Value) then
            return tonumber(cashObj.Value)
        end
    end

    return nil
end

local function applyCashUpdate(newCash)
    if not newCash then return end
    if newCash ~= currentCash then
        animateCashChange(currentCash, newCash)
        currentCash = newCash
    end
end

-- Event listener
if cashUpdateRemote and cashUpdateRemote:IsA("RemoteEvent") then
    cashUpdateRemote.OnClientEvent:Connect(function(newCash)
        applyCashUpdate(tonumber(newCash) or newCash)
    end)
end

-- Polling fallback
task.spawn(function()
    while true do
        if not animating then
            local value = queryServerCash()
            if value then applyCashUpdate(value) end
        end
        task.wait(POLL_RATE)
    end
end)

-- Responsive sizing
local function optimizeForDevice()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local isMobile = vp.X < 800 or vp.Y < 600

    if isMobile then
        shadowFrame.Size = UDim2.new(0, 280, 0, 85)
        shadowFrame.Position = UDim2.new(1, -18, 1, -150)
        iconContainer.Size = UDim2.new(0, 60, 0, 60)
        iconContainer.Position = UDim2.new(0, 12, 0.5, 0)
    else
        shadowFrame.Size = UDim2.new(0, 310, 0, 95)
        shadowFrame.Position = UDim2.new(1, -25, 1, -140)
        iconContainer.Size = UDim2.new(0, 65, 0, 65)
        iconContainer.Position = UDim2.new(0, 15, 0.5, 0)
    end
end

if workspace.CurrentCamera then
    optimizeForDevice()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(optimizeForDevice)
end

-- NO FADE-IN - Start visible immediately
mainPanel.BackgroundTransparency = 0.4  -- Already at target transparency
cashTitleLabel.TextTransparency = 0
cashAmount.TextTransparency = 0
changeIndicator.TextTransparency = 1

-- Initial query
task.defer(function()
    local initial = queryServerCash()
    if initial then
        currentCash = initial
        displayedCash = initial
        cashAmount.Text = CURRENCY_SYMBOL .. formatNumber(initial)
    end
end)

print("💰 Cash Display UI loaded with custom icon!")