-- NotificationUI.lua
-- Handles admin notifications separately from the main client

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for RemoteEvents folder
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
    warn("[NotificationUI] RemoteEvents folder not found")
    return
end

-- Create ShowAdminNotification if it doesn't exist
local ShowAdminNotification = RemoteEvents:FindFirstChild("ShowAdminNotification")
if not ShowAdminNotification then
    -- Client can't create RemoteEvents, just exit gracefully
    return
end

-- Simple notification display
ShowAdminNotification.OnClientEvent:Connect(function(message)
    local ScreenGui = Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("NotificationGui")
    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "NotificationGui"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = Players.LocalPlayer.PlayerGui
    end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 400, 0, 100)
    notification.Position = UDim2.new(0.5, -200, 0, -110)
    notification.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    notification.BorderSizePixel = 0
    notification.Parent = ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, -20)
    text.Position = UDim2.new(0, 10, 0, 10)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextScaled = true
    text.Font = Enum.Font.SourceSans
    text.Parent = notification
    
    -- Animate in
    notification:TweenPosition(UDim2.new(0.5, -200, 0, 10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3)
    
    -- Auto dismiss after 5 seconds
    wait(5)
    notification:TweenPosition(UDim2.new(0.5, -200, 0, -110), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3)
    wait(0.3)
    notification:Destroy()
end)