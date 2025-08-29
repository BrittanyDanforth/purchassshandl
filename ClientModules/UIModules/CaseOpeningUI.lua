--[[
    Module: CaseOpeningUI
    Description: Case opening animation UI with spinning reel, multi-egg support, 
                 skip functionality, particles, sounds, auto-delete, and shine effects
    Features: Animated spinning, rarity effects, particle bursts, skip button, multi-result handling
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local CaseOpeningUI = {}
CaseOpeningUI.__index = CaseOpeningUI

-- ========================================
-- TYPES
-- ========================================

type CaseResult = {
    petId: string,
    petData: Types.PetData?,
    isNew: boolean?,
    variant: string?,
    caseItems: {string}?, -- Items shown in spinner
}

type CaseOpeningOptions = {
    skipDelay: number?,
    autoDelete: boolean?,
    particleEffects: boolean?,
    soundEffects: boolean?,
}

-- ========================================
-- CONSTANTS
-- ========================================

local OVERLAY_FADE_TIME = 0.3
local CONTAINER_SIZE = Vector2.new(800, 600)
local SPINNER_HEIGHT = 200
local CASE_ITEM_WIDTH = 150
local CASE_ITEMS_VISIBLE = 5
local CASE_SPIN_TIME = 5
local CASE_DECELERATION = 0.98
local RESULT_DISPLAY_TIME = 3
local SKIP_BUTTON_DELAY = 1
local COLLECT_BUTTON_SIZE = Vector2.new(200, 50)
local PET_DISPLAY_SIZE = 200
local GLOW_EFFECT_SIZE = 300
local PARTICLE_BURST_COUNT = 20
local SHINE_EFFECT_DELAY = 0.1

-- Rarity names
local RARITY_NAMES = {
    "Common",
    "Uncommon", 
    "Rare",
    "Epic",
    "Legendary",
    "Mythical",
    "SECRET"
}

-- ========================================
-- INITIALIZATION
-- ========================================

function CaseOpeningUI.new(dependencies)
    local self = setmetatable({}, CaseOpeningUI)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._dataCache = dependencies.DataCache
    self._soundSystem = dependencies.SoundSystem
    self._particleSystem = dependencies.ParticleSystem
    self._effectsLibrary = dependencies.EffectsLibrary
    self._animationSystem = dependencies.AnimationSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._uiFactory = dependencies.UIFactory
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self._overlay = nil
    self._container = nil
    self._currentResults = nil
    self._currentIndex = 1
    self._skipButton = nil
    self._collectButton = nil
    self._animationInProgress = false
    self._skipAnimation = false
    
    -- Settings
    self._options = {
        skipDelay = SKIP_BUTTON_DELAY,
        autoDelete = true,
        particleEffects = true,
        soundEffects = true,
    }
    
    -- State
    self._isOpen = false
    self._debugMode = self._config.DEBUG.ENABLED
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function CaseOpeningUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Listen for case opening requests
    self._eventBus:On("OpenCaseAnimation", function(data)
        if data.results then
            self:Open(data.results, data.eggData)
        end
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function CaseOpeningUI:Open(results: {CaseResult}, eggData: table?)
    if self._isOpen then
        self:Close()
    end
    
    -- Clean up any existing UI
    self:Cleanup()
    
    self._currentResults = results
    self._currentIndex = 1
    self._isOpen = true
    self._skipAnimation = false
    
    -- Create UI
    self:CreateOverlay()
    self:CreateContainer()
    
    -- Start animations
    self:StartCaseOpeningSequence()
    
    -- Play opening sound
    if self._soundSystem and self._options.soundEffects then
        self._soundSystem:PlayUISound("CaseOpen")
    end
end

function CaseOpeningUI:Close()
    if not self._isOpen then return end
    
    self._isOpen = false
    self._animationInProgress = false
    self._skipAnimation = true
    
    -- Fade out and destroy
    if self._overlay then
        self._utilities.Tween(self._overlay, {
            BackgroundTransparency = 1
        }, TweenInfo.new(OVERLAY_FADE_TIME))
        
        task.wait(OVERLAY_FADE_TIME)
        self:Cleanup()
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("CaseOpeningClosed", {})
    end
end

function CaseOpeningUI:Cleanup()
    -- Destroy any existing overlay
    local existingOverlay = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("CaseOpeningOverlay")
    if existingOverlay then
        existingOverlay:Destroy()
    end
    
    self._overlay = nil
    self._container = nil
    self._skipButton = nil
    self._collectButton = nil
end

-- ========================================
-- UI CREATION
-- ========================================

function CaseOpeningUI:CreateOverlay()
    local screenGui = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    if not screenGui then
        warn("[CaseOpeningUI] No ScreenGui found")
        return
    end
    
    -- Create fullscreen overlay
    self._overlay = Instance.new("Frame")
    self._overlay.Name = "CaseOpeningOverlay"
    self._overlay.Size = UDim2.new(1, 0, 1, 0)
    self._overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    self._overlay.BackgroundTransparency = 1
    self._overlay.ZIndex = 100
    self._overlay.Parent = screenGui
    
    -- Fade in
    self._utilities.Tween(self._overlay, {
        BackgroundTransparency = 0.8
    }, TweenInfo.new(OVERLAY_FADE_TIME))
end

function CaseOpeningUI:CreateContainer()
    -- Main container
    self._container = Instance.new("Frame")
    self._container.Name = "CaseContainer"
    self._container.Size = UDim2.new(0, CONTAINER_SIZE.X, 0, CONTAINER_SIZE.Y)
    self._container.Position = UDim2.new(0.5, -CONTAINER_SIZE.X/2, 0.5, -CONTAINER_SIZE.Y/2)
    self._container.BackgroundColor3 = self._config.COLORS.Background
    self._container.BorderSizePixel = 0
    self._container.ZIndex = 101
    self._container.Parent = self._overlay
    
    self._utilities.CreateCorner(self._container, 20)
    
    -- Gradient background
    local gradient = self._utilities.CreateGradient(self._container, {
        self._config.COLORS.Primary,
        self._utilities.DarkenColor(self._config.COLORS.Primary, 0.2)
    }, 90)
    
    -- Create skip button (initially hidden)
    self:CreateSkipButton()
end

function CaseOpeningUI:CreateSkipButton()
    self._skipButton = self._uiFactory:CreateButton(self._container, {
        text = "Skip Animation",
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(1, -160, 0, 10),
        backgroundColor = self._config.COLORS.Secondary,
        visible = false,
        zIndex = 105,
        callback = function()
            self._skipAnimation = true
            if self._skipButton then
                self._skipButton.Visible = false
            end
        end
    })
    
    -- Show skip button after delay
    task.delay(self._options.skipDelay, function()
        if self._skipButton and self._animationInProgress then
            self._skipButton.Visible = true
            
            -- Fade in animation
            self._skipButton.BackgroundTransparency = 1
            self._utilities.Tween(self._skipButton, {
                BackgroundTransparency = 0
            }, self._config.TWEEN_INFO.Fast)
        end
    end)
end

-- ========================================
-- CASE OPENING SEQUENCE
-- ========================================

function CaseOpeningUI:StartCaseOpeningSequence()
    spawn(function()
        for i, result in ipairs(self._currentResults) do
            if not self._isOpen then break end
            
            self._currentIndex = i
            
            -- Delay between multiple opens
            if i > 1 then
                task.wait(0.5)
            end
            
            -- Show animation for this result
            self:ShowCaseAnimation(result, i, #self._currentResults)
            
            -- Wait if not skipping
            if not self._skipAnimation then
                task.wait(RESULT_DISPLAY_TIME)
            end
        end
        
        -- All animations complete, show collect button
        if self._isOpen then
            task.wait(1)
            self:CreateCollectButton()
        end
    end)
end

function CaseOpeningUI:ShowCaseAnimation(result: CaseResult, index: number, total: number)
    self._animationInProgress = true
    
    -- Clear previous content
    for _, child in ipairs(self._container:GetChildren()) do
        if child.Name == "CaseContent" then
            child:Destroy()
        end
    end
    
    local content = Instance.new("Frame")
    content.Name = "CaseContent"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.ZIndex = 102
    content.Parent = self._container
    
    -- Title
    local titleText = total > 1 and 
        string.format("Opening Case %d of %d...", index, total) or 
        "Opening Case..."
    
    local titleLabel = self._uiFactory:CreateLabel(content, {
        text = titleText,
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 20),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        zIndex = 103
    })
    
    -- Skip animation for now and show result directly
    -- TODO: Add spinning animation later
    self:ShowResult(content, result)
    
    self._animationInProgress = false
end

-- ========================================
-- SPINNER ANIMATION
-- ========================================

function CaseOpeningUI:CreateSpinnerAnimation(container: Frame, result: CaseResult)
    -- Create spinner frame
    local spinnerFrame = Instance.new("Frame")
    spinnerFrame.Name = "SpinnerFrame"
    spinnerFrame.Size = UDim2.new(1, -100, 0, SPINNER_HEIGHT)
    spinnerFrame.Position = UDim2.new(0, 50, 0.5, -SPINNER_HEIGHT/2)
    spinnerFrame.BackgroundColor3 = self._config.COLORS.Surface
    spinnerFrame.BorderSizePixel = 0
    spinnerFrame.ClipsDescendants = true
    spinnerFrame.ZIndex = 103
    spinnerFrame.Parent = container
    
    self._utilities.CreateCorner(spinnerFrame, 12)
    
    -- Create item container
    local itemContainer = Instance.new("Frame")
    itemContainer.Name = "ItemContainer"
    local caseItems = result.caseItems or self:GenerateCaseItems(result)
    itemContainer.Size = UDim2.new(0, #caseItems * CASE_ITEM_WIDTH, 1, 0)
    itemContainer.BackgroundTransparency = 1
    itemContainer.ZIndex = 103
    itemContainer.Parent = spinnerFrame
    
    -- Create indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 4, 1, 20)
    indicator.Position = UDim2.new(0.5, -2, 0, -10)
    indicator.BackgroundColor3 = self._config.COLORS.Error
    indicator.ZIndex = 104
    indicator.Parent = spinnerFrame
    
    -- Generate case items
    local winnerPosition = math.floor(#caseItems / 2)
    for i, petId in ipairs(caseItems) do
        local itemFrame = self:CreateCaseItem(petId, i == winnerPosition)
        itemFrame.Position = UDim2.new(0, (i - 1) * CASE_ITEM_WIDTH, 0, 0)
        itemFrame.Parent = itemContainer
    end
    
    -- Play spin sound
    if self._soundSystem and self._options.soundEffects then
        self._soundSystem:PlayUISound("CaseOpen")
    end
    
    -- Calculate target position
    local targetPosition = -((winnerPosition - 1) * CASE_ITEM_WIDTH) + 
                          (spinnerFrame.AbsoluteSize.X / 2) - (CASE_ITEM_WIDTH / 2)
    targetPosition = targetPosition + math.random(-20, 20) -- Add randomness
    
    -- Spin animation
    local spinDuration = self._skipAnimation and 0.5 or CASE_SPIN_TIME
    local spinTween = self._utilities.Tween(itemContainer, {
        Position = UDim2.new(0, targetPosition, 0, 0)
    }, TweenInfo.new(spinDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Wait for spin
    spinTween.Completed:Wait()
    
    if not self._skipAnimation then
        -- Flash winner
        task.wait(0.5)
        local winnerItem = itemContainer:GetChildren()[winnerPosition]
        if winnerItem then
            for i = 1, 3 do
                self._utilities.Tween(winnerItem, {
                    BackgroundColor3 = self._config.COLORS.Warning
                }, TweenInfo.new(0.2))
                task.wait(0.2)
                self._utilities.Tween(winnerItem, {
                    BackgroundColor3 = self._config.COLORS.White
                }, TweenInfo.new(0.2))
                task.wait(0.2)
            end
        end
    end
    
    -- Show result
    self:ShowResult(container, result)
end

function CaseOpeningUI:CreateCaseItem(petId: string, isWinner: boolean): Frame
    -- Get pet data with multiple fallbacks
    local petData
    
    -- First check if petId is actually a pet data table (from server)
    if type(petId) == "table" and petId.name then
        petData = petId
        petId = petData.id or petData.name
    else
        -- Try multiple sources for pet data
        -- 1. Try data cache
        if self._dataCache then
            petData = self._dataCache:Get("petDatabase." .. petId)
        end
        
        -- 2. Try ReplicatedStorage paths
        if not petData then
            local locations = {
                game:GetService("ReplicatedStorage"):FindFirstChild("SharedModules"),
                game:GetService("ReplicatedStorage"):FindFirstChild("Modules"):FindFirstChild("Shared"),
                game:GetService("ReplicatedStorage"):FindFirstChild("ServerModules")
            }
            
            for _, location in ipairs(locations) do
                if location then
                    local petDatabase = location:FindFirstChild("PetDatabase")
                    if petDatabase then
                        local success, PetDatabase = pcall(require, petDatabase)
                        if success then
                            if type(PetDatabase) == "table" then
                                if PetDatabase.GetPet then
                                    petData = PetDatabase:GetPet(petId)
                                else
                                    petData = PetDatabase[petId]
                                end
                                if petData then break end
                            end
                        end
                    end
                end
            end
        end
        
        -- 3. Ultimate fallback
        if not petData then
            petData = {
                displayName = petId or "Unknown",
                name = petId or "Unknown",
                rarity = 1,
                imageId = "rbxassetid://0"
            }
        end
    end
    
    local item = Instance.new("Frame")
    item.Name = petId
    item.Size = UDim2.new(0, CASE_ITEM_WIDTH - 10, 1, -20)
    item.BackgroundColor3 = self._config.COLORS.White
    item.BorderSizePixel = 0
    item.ZIndex = 103
    item.Parent = parent
    
    self._utilities.CreateCorner(item, 8)
    
    -- Rarity border
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 0, 4)
    border.Position = UDim2.new(0, 0, 1, -4)
    border.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity)
    border.BorderSizePixel = 0
    border.ZIndex = 104
    border.Parent = item
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, -20, 1, -30)
    petImage.Position = UDim2.new(0, 10, 0, 10)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.ZIndex = 104
    petImage.Parent = item
    
    -- Name label
    local nameLabel = self._uiFactory:CreateLabel(item, {
        text = petData.displayName or petData.name or "???",
        size = UDim2.new(1, -10, 0, 20),
        position = UDim2.new(0, 5, 1, -25),
        textScaled = true,
        font = self._config.FONTS.Primary,
        zIndex = 104
    })
    
    if isWinner then
        -- Add glow effect for winner
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1, 20, 1, 20)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = self._utilities.GetRarityColor(petData.rarity)
        glow.ImageTransparency = 0.5
        glow.ZIndex = 102
        glow.Parent = item
    end
    
    return item
end

-- ========================================
-- RESULT DISPLAY
-- ========================================

function CaseOpeningUI:ShowResult(container: Frame, result: CaseResult)
    -- Clear any existing content
    for _, child in ipairs(container:GetChildren()) do
        if child.Name ~= "Title" then
            child:Destroy()
        end
    end
    
    -- Create result frame
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(1, -100, 1, -200)
    resultFrame.Position = UDim2.new(0, 50, 0, 100)
    resultFrame.BackgroundTransparency = 1
    resultFrame.ZIndex = 103
    resultFrame.Parent = container
    
    -- Get pet data - handle both old and new formats
    local petData
    if result.pet then
        -- New format from server
        petData = result.pet
    elseif result.petData then
        petData = result.petData
    elseif result.petId or result.petName then
        local petId = result.petId or result.petName
        -- Try multiple sources
        local locations = {
            game:GetService("ReplicatedStorage"):FindFirstChild("SharedModules"),
            game:GetService("ReplicatedStorage"):FindFirstChild("Modules"):FindFirstChild("Shared"),
            game:GetService("ReplicatedStorage"):FindFirstChild("ServerModules")
        }
        
        for _, location in ipairs(locations) do
            if location then
                local petDatabase = location:FindFirstChild("PetDatabase")
                if petDatabase then
                    local success, PetDatabase = pcall(require, petDatabase)
                    if success and type(PetDatabase) == "table" then
                        if PetDatabase.GetPet then
                            petData = PetDatabase:GetPet(petId)
                        else
                            petData = PetDatabase[petId]
                        end
                        if petData then break end
                    end
                end
            end
        end
    end
    
    -- Fallback with better defaults
    petData = petData or {
        displayName = result.petName or result.petId or "Unknown Pet",
        name = result.petName or result.petId or "Unknown Pet",
        rarity = result.rarity or 1,
        imageId = "rbxassetid://11410884298" -- Default pet image
    }
    
    -- Handle variants
    local finalPetData = petData
    if result.variant and petData.variants and petData.variants[result.variant] then
        finalPetData = table.clone(petData)
        for k, v in pairs(petData.variants[result.variant]) do
            finalPetData[k] = v
        end
    end
    
    -- Pet name with new indicator
    local petName = tostring(finalPetData.displayName or finalPetData.name or "Unknown Pet")
    if result.isNew then
        petName = "✨ " .. petName .. " ✨"
    end
    
    local nameLabel = self._uiFactory:CreateLabel(resultFrame, {
        text = petName,
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        zIndex = 104
    })
    
    -- Pet display
    local petDisplay = Instance.new("Frame")
    petDisplay.Size = UDim2.new(0, PET_DISPLAY_SIZE, 0, PET_DISPLAY_SIZE)
    petDisplay.Position = UDim2.new(0.5, -PET_DISPLAY_SIZE/2, 0.5, -PET_DISPLAY_SIZE/2)
    petDisplay.BackgroundTransparency = 1
    petDisplay.ZIndex = 104
    petDisplay.Parent = resultFrame
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, 0, 1, 0)
    petImage.BackgroundTransparency = 1
    petImage.Image = finalPetData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.ZIndex = 105
    petImage.Parent = petDisplay
    
    -- Add shine effect for rare pets
    if finalPetData.rarity >= 4 then
        petImage.ClipsDescendants = true
        
        -- Use effects library for shine
        if self._effectsLibrary then
            task.delay(SHINE_EFFECT_DELAY, function()
                self._effectsLibrary:CreateShineEffect(petImage)
            end)
        end
    end
    
    -- Rarity effects
    local rarityColor = self._utilities.GetRarityColor(finalPetData.rarity)
    
    -- Background glow
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(0, GLOW_EFFECT_SIZE, 0, GLOW_EFFECT_SIZE)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = rarityColor
    glow.ImageTransparency = 0.5
    glow.ZIndex = 103
    glow.Parent = petDisplay
    
    -- Animate glow
    self._utilities.Tween(glow, {
        Size = UDim2.new(0, GLOW_EFFECT_SIZE + 50, 0, GLOW_EFFECT_SIZE + 50),
        ImageTransparency = 0.3
    }, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true))
    
    -- Variant indicator
    if result.variant then
        local variantText = tostring(result.variant or ""):upper()
        if variantText ~= "" then
            local variantLabel = self._uiFactory:CreateLabel(resultFrame, {
                text = variantText .. " VARIANT!",
                size = UDim2.new(1, 0, 0, 25),
                position = UDim2.new(0, 0, 0, 410),
                textColor = self._config.COLORS.Warning,
                font = self._config.FONTS.Secondary,
                zIndex = 104
            })
        end
        
        -- Extra particles for variants
        if self._particleSystem and self._options.particleEffects then
            self._particleSystem:CreateBurst(resultFrame, "star", UDim2.new(0.5, 0, 0.5, 0), PARTICLE_BURST_COUNT)
        end
    end
    
    -- Rarity label
    local rarity = finalPetData.rarity or 1
    local rarityName = RARITY_NAMES[rarity] or "Unknown"
    
    local rarityLabel = self._uiFactory:CreateLabel(resultFrame, {
        text = rarityName,
        size = UDim2.new(1, 0, 0, 25),
        position = UDim2.new(0, 0, 0, 440),
        textColor = rarityColor,
        font = self._config.FONTS.Secondary,
        zIndex = 104
    })
    
    -- Play sounds based on rarity
    if self._soundSystem and self._options.soundEffects then
        if finalPetData.rarity >= 5 then
            self._soundSystem:PlayUISound("Legendary")
        else
            self._soundSystem:PlayUISound("Success")
        end
    end
    
    -- Particles based on rarity
    if self._particleSystem and self._options.particleEffects and finalPetData.rarity >= 4 then
        for i = 1, 50 do
            spawn(function()
                task.wait(i * 0.05)
                self._particleSystem:CreateParticle(resultFrame, "star", 
                    UDim2.new(math.random(), 0, 1, 0))
            end)
        end
    end
    
    -- Fade in animation
    self:FadeInResult(resultFrame)
    
    -- Auto-delete handling
    if self._options.autoDelete and result.isNew == false then
        -- Add auto-delete indicator
        local autoDeleteLabel = self._uiFactory:CreateLabel(resultFrame, {
            text = "(Auto-Delete Duplicate)",
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 1, -30),
            textColor = self._config.COLORS.TextSecondary,
            font = self._config.FONTS.Primary,
            textSize = 14,
            zIndex = 104
        })
    end
end

function CaseOpeningUI:FadeInResult(resultFrame: Frame)
    -- Fade in all elements
    for _, obj in ipairs(resultFrame:GetDescendants()) do
        if obj:IsA("GuiObject") then
            local transparency = obj.BackgroundTransparency
            obj.BackgroundTransparency = 1
            self._utilities.Tween(obj, {
                BackgroundTransparency = transparency
            }, self._config.TWEEN_INFO.Slow)
        end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local transparency = obj.TextTransparency or 0
            obj.TextTransparency = 1
            self._utilities.Tween(obj, {
                TextTransparency = transparency
            }, self._config.TWEEN_INFO.Slow)
        end
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            local transparency = obj.ImageTransparency or 0
            obj.ImageTransparency = 1
            self._utilities.Tween(obj, {
                ImageTransparency = transparency
            }, self._config.TWEEN_INFO.Slow)
        end
    end
end

-- ========================================
-- COLLECT BUTTON
-- ========================================

function CaseOpeningUI:CreateCollectButton()
    -- Make sure we don't create duplicate buttons
    if self._collectButton then return end
    
    self._collectButton = self._uiFactory:CreateButton(self._container, {
        text = "Collect & Continue",
        size = UDim2.new(0, COLLECT_BUTTON_SIZE.X, 0, COLLECT_BUTTON_SIZE.Y),
        position = UDim2.new(0.5, -COLLECT_BUTTON_SIZE.X/2, 1, -70),
        backgroundColor = self._config.COLORS.Success,
        zIndex = 105,
        callback = function()
            self:OnCollectClicked()
        end
    })
    
    -- Animate in
    self._collectButton.Position = UDim2.new(0.5, -COLLECT_BUTTON_SIZE.X/2, 1, 20)
    self._utilities.Tween(self._collectButton, {
        Position = UDim2.new(0.5, -COLLECT_BUTTON_SIZE.X/2, 1, -70)
    }, self._config.TWEEN_INFO.Bounce)
    
    -- Add glow effect
    if self._effectsLibrary then
        self._effectsLibrary:CreateGlowEffect(self._collectButton, {
            color = self._config.COLORS.Success,
            size = 30
        })
    end
end

function CaseOpeningUI:OnCollectClicked()
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
    
    -- Update inventory if needed
    if self._eventBus then
        self._eventBus:Fire("CaseResultsCollected", {
            results = self._currentResults
        })
    end
    
    -- Close UI
    self:Close()
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function CaseOpeningUI:GenerateCaseItems(result: CaseResult): {string}
    -- Generate random items for the spinner if not provided
    local items = {}
    local itemCount = 100
    
    -- Get all possible pets from database
    local allPets = {}
    
    -- Try to get pet list from various sources
    if self._dataCache then
        local petDatabase = self._dataCache:Get("petDatabase") or {}
        for petId, _ in pairs(petDatabase) do
            table.insert(allPets, petId)
        end
    end
    
    -- If still no pets, try to get from modules
    if #allPets == 0 then
        local locations = {
            game:GetService("ReplicatedStorage"):FindFirstChild("SharedModules"),
            game:GetService("ReplicatedStorage"):FindFirstChild("Modules"):FindFirstChild("Shared")
        }
        
        for _, location in ipairs(locations) do
            if location then
                local petDatabase = location:FindFirstChild("PetDatabase")
                if petDatabase then
                    local success, PetDatabase = pcall(require, petDatabase)
                    if success and type(PetDatabase) == "table" then
                        for petId, _ in pairs(PetDatabase) do
                            if type(petId) == "string" then
                                table.insert(allPets, petId)
                            end
                        end
                        if #allPets > 0 then break end
                    end
                end
            end
        end
    end
    
    -- If still no pets found, use placeholder pets
    if #allPets == 0 then
        allPets = {"Common_Pet_1", "Common_Pet_2", "Rare_Pet_1", "Epic_Pet_1", "Legendary_Pet_1"}
    end
    
    -- Generate random items
    local winnerPetId = result.petId or result.petName or allPets[1]
    
    for i = 1, itemCount do
        if i == math.floor(itemCount / 2) then
            -- Winner position
            table.insert(items, winnerPetId)
        else
            -- Random pet
            table.insert(items, allPets[math.random(1, #allPets)])
        end
    end
    
    return items
end

-- ========================================
-- SETTINGS
-- ========================================

function CaseOpeningUI:SetAutoDelete(enabled: boolean)
    self._options.autoDelete = enabled
end

function CaseOpeningUI:SetParticleEffects(enabled: boolean)
    self._options.particleEffects = enabled
end

function CaseOpeningUI:SetSoundEffects(enabled: boolean)
    self._options.soundEffects = enabled
end

-- ========================================
-- DEBUGGING
-- ========================================

if Config.DEBUG.ENABLED then
    function CaseOpeningUI:DebugPrint()
        print("\n=== CaseOpeningUI Debug Info ===")
        print("Is Open:", self._isOpen)
        print("Animation In Progress:", self._animationInProgress)
        print("Skip Animation:", self._skipAnimation)
        print("Current Results:", self._currentResults and #self._currentResults or 0)
        print("Current Index:", self._currentIndex)
        
        print("\nOptions:")
        for key, value in pairs(self._options) do
            print("  " .. key .. ":", tostring(value))
        end
        
        print("===========================\n")
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function CaseOpeningUI:Destroy()
    self:Cleanup()
    
    -- Clear references
    self._currentResults = nil
    self._isOpen = false
    self._animationInProgress = false
    self._skipAnimation = false
end

return CaseOpeningUI