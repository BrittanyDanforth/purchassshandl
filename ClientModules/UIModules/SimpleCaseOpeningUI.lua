-- Simple Case Opening UI that actually works
local SimpleCaseOpeningUI = {}
SimpleCaseOpeningUI.__index = SimpleCaseOpeningUI

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function SimpleCaseOpeningUI.new(deps)
    local self = setmetatable({}, SimpleCaseOpeningUI)
    
    self._player = Players.LocalPlayer
    self._gui = nil
    self._isOpen = false
    self._currentResults = nil
    self._currentIndex = 1
    
    -- Dependencies
    self._eventBus = deps.EventBus
    self._remoteManager = deps.RemoteManager
    self._soundSystem = deps.SoundSystem
    
    return self
end

function SimpleCaseOpeningUI:CreateGUI()
    -- Clean up old GUI
    if self._gui then
        self._gui:Destroy()
    end
    
    -- Create new GUI
    self._gui = Instance.new("ScreenGui")
    self._gui.Name = "SimpleCaseOpeningUI"
    self._gui.ResetOnSpawn = false
    self._gui.DisplayOrder = 100
    self._gui.Parent = self._player.PlayerGui
    
    -- Background overlay
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.3
    background.Parent = self._gui
    
    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 600, 0, 500)
    container.Position = UDim2.new(0.5, -300, 0.5, -250)
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BorderSizePixel = 0
    container.Parent = background
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = "Case Opening!"
    title.TextScaled = true
    title.TextColor3 = Color3.new(0, 0, 0)
    title.Font = Enum.Font.SourceSansBold
    title.Parent = container
    
    -- Pet display area
    local petDisplay = Instance.new("Frame")
    petDisplay.Name = "PetDisplay"
    petDisplay.Size = UDim2.new(1, -40, 1, -180)
    petDisplay.Position = UDim2.new(0, 20, 0, 80)
    petDisplay.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    petDisplay.BorderSizePixel = 0
    petDisplay.Parent = container
    
    local displayCorner = Instance.new("UICorner")
    displayCorner.CornerRadius = UDim.new(0, 8)
    displayCorner.Parent = petDisplay
    
    -- Collect button
    local collectButton = Instance.new("TextButton")
    collectButton.Name = "CollectButton"
    collectButton.Size = UDim2.new(0, 200, 0, 50)
    collectButton.Position = UDim2.new(0.5, -100, 1, -70)
    collectButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    collectButton.BorderSizePixel = 0
    collectButton.Text = "COLLECT!"
    collectButton.TextColor3 = Color3.new(1, 1, 1)
    collectButton.TextScaled = true
    collectButton.Font = Enum.Font.SourceSansBold
    collectButton.Parent = container
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = collectButton
    
    -- Connect button
    collectButton.MouseButton1Click:Connect(function()
        self:OnCollectClicked()
    end)
    
    self._container = container
    self._petDisplay = petDisplay
    
    return self._gui
end

function SimpleCaseOpeningUI:ShowPet(result)
    -- Clear previous display
    for _, child in ipairs(self._petDisplay:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Get pet info
    local petName = "Unknown Pet"
    local petImage = "rbxassetid://0"
    local rarity = 1
    
    if result.pet then
        petName = result.pet.displayName or result.pet.name or petName
        petImage = result.pet.imageId or petImage
        rarity = result.pet.rarity or rarity
    elseif result.petName then
        petName = result.petName
    end
    
    -- Pet name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 0, 40)
    nameLabel.Position = UDim2.new(0, 10, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = petName
    nameLabel.TextScaled = true
    nameLabel.TextColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = self._petDisplay
    
    -- Pet image
    local petImageLabel = Instance.new("ImageLabel")
    petImageLabel.Size = UDim2.new(0, 200, 0, 200)
    petImageLabel.Position = UDim2.new(0.5, -100, 0.5, -100)
    petImageLabel.BackgroundTransparency = 1
    petImageLabel.Image = petImage
    petImageLabel.ScaleType = Enum.ScaleType.Fit
    petImageLabel.Parent = self._petDisplay
    
    -- Rarity label
    local rarityNames = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret"}
    local rarityColors = {
        Color3.fromRGB(158, 158, 158),
        Color3.fromRGB(46, 204, 113),
        Color3.fromRGB(52, 152, 219),
        Color3.fromRGB(155, 89, 182),
        Color3.fromRGB(241, 196, 15),
        Color3.fromRGB(231, 76, 60),
        Color3.fromRGB(255, 0, 255)
    }
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, -20, 0, 30)
    rarityLabel.Position = UDim2.new(0, 10, 1, -40)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = rarityNames[math.min(rarity, #rarityNames)]
    rarityLabel.TextScaled = true
    rarityLabel.TextColor3 = rarityColors[math.min(rarity, #rarityColors)]
    rarityLabel.Font = Enum.Font.SourceSansBold
    rarityLabel.Parent = self._petDisplay
    
    -- Add NEW indicator if new
    if result.isNew then
        local newLabel = Instance.new("TextLabel")
        newLabel.Size = UDim2.new(0, 60, 0, 30)
        newLabel.Position = UDim2.new(1, -70, 0, 10)
        newLabel.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
        newLabel.BorderSizePixel = 0
        newLabel.Text = "NEW!"
        newLabel.TextScaled = true
        newLabel.TextColor3 = Color3.new(1, 1, 1)
        newLabel.Font = Enum.Font.SourceSansBold
        newLabel.Parent = self._petDisplay
        
        local newCorner = Instance.new("UICorner")
        newCorner.CornerRadius = UDim.new(0, 4)
        newCorner.Parent = newLabel
    end
end

function SimpleCaseOpeningUI:Open(results)
    if not results or #results == 0 then
        warn("[SimpleCaseOpeningUI] No results to show")
        return
    end
    
    self._currentResults = results
    self._currentIndex = 1
    self._isOpen = true
    
    -- Create GUI
    self:CreateGUI()
    
    -- Show first result
    self:ShowPet(results[1])
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Success")
    end
end

function SimpleCaseOpeningUI:OnCollectClicked()
    if not self._currentResults then
        self:Close()
        return
    end
    
    self._currentIndex = self._currentIndex + 1
    
    if self._currentIndex <= #self._currentResults then
        -- Show next pet
        self:ShowPet(self._currentResults[self._currentIndex])
    else
        -- All pets shown, close UI
        self:Close()
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("CaseResultsCollected", self._currentResults)
        end
    end
end

function SimpleCaseOpeningUI:Close()
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
    end
    
    self._isOpen = false
    self._currentResults = nil
    self._currentIndex = 1
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("CaseOpeningClosed")
    end
end

return SimpleCaseOpeningUI