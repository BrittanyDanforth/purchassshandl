-- Shop GUI Client Script
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local shopRemotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local purchaseRemote = shopRemotes:WaitForChild("PurchaseItem")
local equipRemote = shopRemotes:WaitForChild("EquipItem")
local getDataRemote = shopRemotes:WaitForChild("GetPlayerData")

-- Shop Items Configuration (must match server)
local SHOP_ITEMS = {
    {
        Name = "Red Coil",
        ItemId = "RedCoil",
        Price = 100,
        ImageId = "rbxassetid://9676503482",
        Description = "A powerful red speed coil!",
        Type = "Gear"
    },
    {
        Name = "Green Coil",
        ItemId = "GreenCoil",
        Price = 150,
        ImageId = "rbxassetid://9676542145",
        Description = "An enhanced green speed coil!",
        Type = "Gear"
    },
    {
        Name = "Red Balloon",
        ItemId = "RedBalloon",
        Price = 200,
        ImageId = "rbxassetid://9672579022",
        Description = "Float with this magical balloon!",
        Type = "Gear"
    },
    {
        Name = "Grappling Hook",
        ItemId = "GrapplingHook",
        Price = 500,
        ImageId = "rbxassetid://9677437680",
        Description = "Swing around with this grappling hook!",
        Type = "Tool"
    }
}

-- Create Shop GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Shop Toggle Button
local toggleButton = Instance.new("ImageButton")
toggleButton.Name = "ShopToggle"
toggleButton.Size = UDim2.new(0, 80, 0, 80)
toggleButton.Position = UDim2.new(0, 10, 0.5, -40)
toggleButton.Image = "rbxassetid://9672262249"
toggleButton.BackgroundTransparency = 1
toggleButton.Parent = screenGui

-- Add hover effect to toggle button
local toggleButtonHover = false
toggleButton.MouseEnter:Connect(function()
    toggleButtonHover = true
    TweenService:Create(toggleButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 90, 0, 90), Position = UDim2.new(0, 5, 0.5, -45)}):Play()
end)

toggleButton.MouseLeave:Connect(function()
    toggleButtonHover = false
    TweenService:Create(toggleButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 80, 0, 80), Position = UDim2.new(0, 10, 0.5, -40)}):Play()
end)

-- Main Shop Frame
local shopFrame = Instance.new("ImageLabel")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Image = "rbxassetid://9672485940"
shopFrame.ImageColor3 = Color3.new(1, 1, 1)
shopFrame.BackgroundTransparency = 1
shopFrame.Visible = false
shopFrame.Parent = screenGui

-- Add UIAspectRatioConstraint as specified
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
aspectRatio.Parent = shopFrame

-- Shop Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
titleLabel.Position = UDim2.new(0.1, 0, 0.05, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ITEM SHOP"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = shopFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Coins Display
local coinsFrame = Instance.new("Frame")
coinsFrame.Name = "CoinsDisplay"
coinsFrame.Size = UDim2.new(0.3, 0, 0.08, 0)
coinsFrame.Position = UDim2.new(0.35, 0, 0.15, 0)
coinsFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
coinsFrame.Parent = shopFrame

local coinsCorner = Instance.new("UICorner")
coinsCorner.CornerRadius = UDim.new(0, 8)
coinsCorner.Parent = coinsFrame

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(1, 0, 1, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "Coins: 0"
coinsLabel.TextColor3 = Color3.new(1, 0.843, 0)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.SourceSansBold
coinsLabel.Parent = coinsFrame

-- Items Container
local itemsContainer = Instance.new("ScrollingFrame")
itemsContainer.Name = "ItemsContainer"
itemsContainer.Size = UDim2.new(0.9, 0, 0.65, 0)
itemsContainer.Position = UDim2.new(0.05, 0, 0.25, 0)
itemsContainer.BackgroundTransparency = 1
itemsContainer.ScrollBarThickness = 8
itemsContainer.Parent = shopFrame

local itemsLayout = Instance.new("UIGridLayout")
itemsLayout.CellSize = UDim2.new(0.3, -10, 0.45, -10)
itemsLayout.CellPadding = UDim2.new(0, 15, 0, 15)
itemsLayout.Parent = itemsContainer

-- Create Item Frames
local itemFrames = {}

for i, item in ipairs(SHOP_ITEMS) do
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = item.ItemId
    itemFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    itemFrame.Parent = itemsContainer
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 12)
    itemCorner.Parent = itemFrame
    
    -- Item Image
    local itemImage = Instance.new("ImageLabel")
    itemImage.Name = "ItemImage"
    itemImage.Size = UDim2.new(0.8, 0, 0.5, 0)
    itemImage.Position = UDim2.new(0.1, 0, 0.05, 0)
    itemImage.BackgroundTransparency = 1
    itemImage.Image = item.ImageId
    itemImage.ScaleType = Enum.ScaleType.Fit
    itemImage.Parent = itemFrame
    
    -- Item Name
    local itemName = Instance.new("TextLabel")
    itemName.Name = "ItemName"
    itemName.Size = UDim2.new(0.9, 0, 0.15, 0)
    itemName.Position = UDim2.new(0.05, 0, 0.55, 0)
    itemName.BackgroundTransparency = 1
    itemName.Text = item.Name
    itemName.TextColor3 = Color3.new(1, 1, 1)
    itemName.TextScaled = true
    itemName.Font = Enum.Font.SourceSansBold
    itemName.Parent = itemFrame
    
    -- Price Label
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
    priceLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "💰 " .. item.Price
    priceLabel.TextColor3 = Color3.new(1, 0.843, 0)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.SourceSans
    priceLabel.Parent = itemFrame
    
    -- Buy/Equip Button
    local actionButton = Instance.new("TextButton")
    actionButton.Name = "ActionButton"
    actionButton.Size = UDim2.new(0.8, 0, 0.12, 0)
    actionButton.Position = UDim2.new(0.1, 0, 0.82, 0)
    actionButton.BackgroundColor3 = Color3.new(0.2, 0.7, 0.2)
    actionButton.Text = "Buy"
    actionButton.TextColor3 = Color3.new(1, 1, 1)
    actionButton.TextScaled = true
    actionButton.Font = Enum.Font.SourceSansBold
    actionButton.Parent = itemFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = actionButton
    
    -- Owned Indicator
    local ownedLabel = Instance.new("TextLabel")
    ownedLabel.Name = "OwnedLabel"
    ownedLabel.Size = UDim2.new(0.3, 0, 0.1, 0)
    ownedLabel.Position = UDim2.new(0.65, 0, 0.05, 0)
    ownedLabel.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    ownedLabel.Text = "OWNED"
    ownedLabel.TextColor3 = Color3.new(1, 1, 1)
    ownedLabel.TextScaled = true
    ownedLabel.Font = Enum.Font.SourceSansBold
    ownedLabel.Visible = false
    ownedLabel.Parent = itemFrame
    
    local ownedCorner = Instance.new("UICorner")
    ownedCorner.CornerRadius = UDim.new(0, 4)
    ownedCorner.Parent = ownedLabel
    
    itemFrames[item.ItemId] = {
        Frame = itemFrame,
        Button = actionButton,
        OwnedLabel = ownedLabel,
        Item = item
    }
    
    -- Button functionality
    actionButton.MouseButton1Click:Connect(function()
        local playerData = getDataRemote:InvokeServer()
        
        if playerData.OwnedItems[item.ItemId] then
            -- Equip item
            equipRemote:FireServer(item.ItemId)
        else
            -- Purchase item
            purchaseRemote:FireServer(item.ItemId)
        end
    end)
    
    -- Hover effects
    itemFrame.MouseEnter:Connect(function()
        TweenService:Create(itemFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)}):Play()
    end)
    
    itemFrame.MouseLeave:Connect(function()
        TweenService:Create(itemFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)}):Play()
    end)
end

-- Update Shop Display
local function updateShop()
    local playerData = getDataRemote:InvokeServer()
    if not playerData then return end
    
    -- Update coins
    coinsLabel.Text = "Coins: " .. tostring(playerData.Coins)
    
    -- Update items
    for itemId, itemData in pairs(itemFrames) do
        if playerData.OwnedItems[itemId] then
            itemData.OwnedLabel.Visible = true
            itemData.Button.Text = "Equip"
            itemData.Button.BackgroundColor3 = Color3.new(0.2, 0.5, 0.8)
            
            if playerData.EquippedItem == itemId then
                itemData.Button.Text = "Equipped"
                itemData.Button.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
            end
        else
            itemData.OwnedLabel.Visible = false
            itemData.Button.Text = "Buy"
            itemData.Button.BackgroundColor3 = Color3.new(0.2, 0.7, 0.2)
        end
    end
end

-- Shop visibility
local shopOpen = false

local function toggleShop()
    shopOpen = not shopOpen
    
    if shopOpen then
        shopFrame.Visible = true
        shopFrame.Size = UDim2.new(0, 0, 0, 0)
        
        local openTween = TweenService:Create(shopFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.8, 0, 0.8, 0)
        })
        openTween:Play()
        
        updateShop()
    else
        local closeTween = TweenService:Create(shopFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            shopFrame.Visible = false
        end)
    end
end

-- Connect buttons
toggleButton.MouseButton1Click:Connect(toggleShop)
closeButton.MouseButton1Click:Connect(function()
    if shopOpen then
        toggleShop()
    end
end)

-- Handle purchase/equip responses
purchaseRemote.OnClientEvent:Connect(function(success, message, newData)
    if success then
        updateShop()
        -- Show success notification
        local notification = Instance.new("TextLabel")
        notification.Size = UDim2.new(0.3, 0, 0.1, 0)
        notification.Position = UDim2.new(0.35, 0, 0.9, 0)
        notification.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
        notification.Text = message
        notification.TextColor3 = Color3.new(1, 1, 1)
        notification.TextScaled = true
        notification.Font = Enum.Font.SourceSansBold
        notification.Parent = screenGui
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notification
        
        wait(2)
        notification:Destroy()
    else
        -- Show error notification
        local notification = Instance.new("TextLabel")
        notification.Size = UDim2.new(0.3, 0, 0.1, 0)
        notification.Position = UDim2.new(0.35, 0, 0.9, 0)
        notification.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
        notification.Text = message
        notification.TextColor3 = Color3.new(1, 1, 1)
        notification.TextScaled = true
        notification.Font = Enum.Font.SourceSansBold
        notification.Parent = screenGui
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notification
        
        wait(2)
        notification:Destroy()
    end
end)

equipRemote.OnClientEvent:Connect(function(success, message)
    if success then
        updateShop()
    end
end)

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        toggleShop()
    end
end)

-- Update shop periodically
spawn(function()
    while true do
        wait(1)
        if shopOpen then
            updateShop()
        end
    end
end)

print("Shop GUI loaded! Press F or click the shop button to open.")