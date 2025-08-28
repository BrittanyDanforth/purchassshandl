--[[
    Module: InventoryUI
    Description: Comprehensive pet inventory management UI with grid display, filtering,
                 sorting, mass actions, virtual scrolling, and card recycling
    Features: Pet grid, filters by rarity/equipped/locked, sorting, search, mass delete,
              pet details integration, real-time updates, card recycling for performance
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local InventoryUI = {}
InventoryUI.__index = InventoryUI

-- ========================================
-- TYPES
-- ========================================

type PetInstance = {
    uniqueId: string,
    petId: string,
    level: number,
    experience: number,
    power: number,
    speed: number,
    luck: number,
    equipped: boolean,
    locked: boolean,
    nickname: string?,
    variant: string?,
    obtained: number,
    source: string?,
}

type FilterType = "All" | "Equipped" | "Locked" | "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythical" | "Shiny" | "Golden" | "Rainbow"
type SortType = "Rarity" | "Level" | "Power" | "Recent" | "Name"

-- ========================================
-- CONSTANTS
-- ========================================

local GRID_PADDING = 10
local CARD_SIZE = Vector2.new(120, 140)
local CARDS_PER_ROW = 5
local SCROLL_THRESHOLD = 5 -- Cards to preload above/below viewport
local SEARCH_DEBOUNCE = 0.3
local MAX_CARD_CACHE = 100
local MASS_DELETE_WINDOW_SIZE = Vector2.new(600, 500)
local STATS_UPDATE_RATE = 0.5

-- Filter definitions
local FILTER_DEFINITIONS = {
    All = function() return true end,
    Equipped = function(pet) return pet.equipped == true end,
    Locked = function(pet) return pet.locked == true end,
    Common = function(pet, petData) return petData.rarity == 1 end,
    Uncommon = function(pet, petData) return petData.rarity == 2 end,
    Rare = function(pet, petData) return petData.rarity == 3 end,
    Epic = function(pet, petData) return petData.rarity == 4 end,
    Legendary = function(pet, petData) return petData.rarity == 5 end,
    Mythical = function(pet, petData) return petData.rarity == 6 end,
    Shiny = function(pet) return pet.variant == "shiny" end,
    Golden = function(pet) return pet.variant == "golden" end,
    Rainbow = function(pet) return pet.variant == "rainbow" end,
}

-- Sort functions
local SORT_FUNCTIONS = {
    Rarity = function(a, b, aData, bData)
        return (aData.rarity or 1) > (bData.rarity or 1)
    end,
    Level = function(a, b)
        return (a.level or 1) > (b.level or 1)
    end,
    Power = function(a, b)
        return (a.power or 0) > (b.power or 0)
    end,
    Recent = function(a, b)
        return (a.obtained or 0) > (b.obtained or 0)
    end,
    Name = function(a, b, aData, bData)
        local aName = a.nickname or aData.displayName or "Unknown"
        local bName = b.nickname or bData.displayName or "Unknown"
        return aName < bName
    end,
}

-- ========================================
-- INITIALIZATION
-- ========================================

function InventoryUI.new(dependencies)
    local self = setmetatable({}, InventoryUI)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    self._dataCache = dependencies.DataCache
    self._remoteManager = dependencies.RemoteManager
    self._soundSystem = dependencies.SoundSystem
    self._particleSystem = dependencies.ParticleSystem
    self._animationSystem = dependencies.AnimationSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._uiFactory = dependencies.UIFactory
    self._windowManager = dependencies.WindowManager
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self.PetGrid = nil
    self.TabFrames = {}
    self.StatsLabels = {}
    self.PetCardCache = {}
    self.DeleteSelectionGrid = nil
    self.SelectedForDeletion = {}
    self.DeleteSelectedLabel = nil
    self.DeleteOverlay = nil
    
    -- State
    self.IsRefreshing = false
    self.CurrentFilter = "All"
    self.CurrentSort = "Level"
    self.SearchText = ""
    self.VisiblePets = {}
    self.PetWatcher = nil
    self.SearchDebounce = nil
    
    -- Performance
    self.LastRefreshTime = 0
    self.RefreshCooldown = 0.5
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function InventoryUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Listen for data updates
    self._eventBus:On("PetsUpdated", function()
        if self.Frame and self.Frame.Visible then
            self:RefreshInventory()
        end
    end)
    
    -- Listen for case results
    self._eventBus:On("CaseResultsCollected", function()
        task.wait(0.5) -- Wait for server to update
        if self.Frame and self.Frame.Visible then
            self:RefreshInventory()
        end
    end)
    
    -- Listen for pet actions
    self._eventBus:On("PetEquipped", function(data)
        self:UpdatePetCardEquipStatus(data.uniqueId, true)
    end)
    
    self._eventBus:On("PetUnequipped", function(data)
        self:UpdatePetCardEquipStatus(data.uniqueId, false)
    end)
    
    self._eventBus:On("PetLocked", function(data)
        self:UpdatePetCardLockStatus(data.uniqueId, true)
    end)
    
    self._eventBus:On("PetUnlocked", function(data)
        self:UpdatePetCardLockStatus(data.uniqueId, false)
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function InventoryUI:Open()
    if self.Frame then
        self.Frame.Visible = true
        self:RefreshInventory()
        return
    end
    
    -- Set up reactive updates
    if self._dataCache and not self.PetWatcher then
        -- Check if Watch method exists
        if self._dataCache.Watch then
            self.PetWatcher = self._dataCache:Watch("pets", function()
                if self.Frame and self.Frame.Visible then
                    self:RefreshInventory()
                end
            end)
        else
            warn("[InventoryUI] DataCache.Watch method not found - reactive updates disabled")
        end
    end
    
    -- Create UI
    self:CreateUI()
    
    -- Initial load
    self:RefreshInventory()
end

function InventoryUI:Close()
    if self.Frame then
        self.Frame.Visible = false
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function InventoryUI:CreateUI()
    local mainPanel = self._windowManager and self._windowManager:GetMainPanel() or 
                     Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not mainPanel then
        warn("[InventoryUI] No main panel found")
        return
    end
    
    -- Create main frame
    self.Frame = self._uiFactory:CreateFrame(mainPanel, {
        name = "InventoryFrame",
        size = UDim2.new(1, -20, 1, -90),
        position = UDim2.new(0, 10, 0, 80),
        backgroundColor = self._config.COLORS.White,
        visible = true
    })
    
    -- Create header
    self:CreateHeader()
    
    -- Create stats bar
    self:CreateStatsBar()
    
    -- Create controls
    self:CreateControls()
    
    -- Create tabs
    self:CreateTabs()
end

function InventoryUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "🎀 My Pet Collection 🎀",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24
    })
end

function InventoryUI:CreateStatsBar()
    local statsBar = Instance.new("Frame")
    statsBar.Name = "StatsBar"
    statsBar.Size = UDim2.new(1, 0, 0, 40)
    statsBar.Position = UDim2.new(0, 0, 0, 60)
    statsBar.BackgroundColor3 = self._config.COLORS.White
    statsBar.Parent = self.Frame
    
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    statsLayout.Padding = UDim.new(0, 20)
    statsLayout.Parent = statsBar
    
    -- Pet count
    local petCountFrame = self:CreateStatDisplay(statsBar, "Pets", "0/500", self._config.COLORS.Primary)
    self.StatsLabels.PetCount = petCountFrame:FindFirstChild("ValueLabel")
    
    -- Equipped count
    local equippedFrame = self:CreateStatDisplay(statsBar, "Equipped", "0/6", self._config.COLORS.Success)
    self.StatsLabels.Equipped = equippedFrame:FindFirstChild("ValueLabel")
    
    -- Storage bar
    local storageFrame = self:CreateStorageBar(statsBar)
    self.StatsLabels.Storage = storageFrame
end

function InventoryUI:CreateStatDisplay(parent: Frame, label: string, value: string, color: Color3): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 1, -10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelText = self._uiFactory:CreateLabel(frame, {
        text = label .. ":",
        size = UDim2.new(0, 60, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = self._config.COLORS.TextSecondary
    })
    
    local valueLabel = self._uiFactory:CreateLabel(frame, {
        name = "ValueLabel",
        text = value,
        size = UDim2.new(1, -70, 1, 0),
        position = UDim2.new(0, 70, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = color,
        font = self._config.FONTS.Secondary
    })
    
    return frame
end

function InventoryUI:CreateStorageBar(parent: Frame): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 1, -10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -60, 0, 8)
    barBg.Position = UDim2.new(0, 50, 0.5, -4)
    barBg.BackgroundColor3 = self._config.COLORS.Surface
    barBg.Parent = frame
    
    self._utilities.CreateCorner(barBg, 4)
    
    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = self._config.COLORS.Primary
    barFill.Parent = barBg
    
    self._utilities.CreateCorner(barFill, 4)
    
    local label = self._uiFactory:CreateLabel(frame, {
        text = "Storage:",
        size = UDim2.new(0, 50, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = self._config.COLORS.TextSecondary
    })
    
    -- Add update function
    frame.UpdateValue = function(current: number)
        local max = self._dataCache and self._dataCache:Get("maxPetStorage") or 500
        local percentage = math.clamp(current / max, 0, 1)
        
        self._utilities.Tween(barFill, {
            Size = UDim2.new(percentage, 0, 1, 0)
        }, self._config.TWEEN_INFO.Fast)
        
        -- Change color based on percentage
        if percentage > 0.9 then
            barFill.BackgroundColor3 = self._config.COLORS.Error
        elseif percentage > 0.7 then
            barFill.BackgroundColor3 = self._config.COLORS.Warning
        else
            barFill.BackgroundColor3 = self._config.COLORS.Primary
        end
    end
    
    return frame
end

function InventoryUI:CreateControls()
    local controlsBar = Instance.new("Frame")
    controlsBar.Name = "ControlsBar"
    controlsBar.Size = UDim2.new(1, 0, 0, 50)
    controlsBar.Position = UDim2.new(0, 0, 0, 100)
    controlsBar.BackgroundColor3 = self._config.COLORS.Surface
    controlsBar.Parent = self.Frame
    
    -- Search box
    local searchBox = self._uiFactory:CreateTextBox(controlsBar, {
        placeholder = "Search pets...",
        size = UDim2.new(0, 200, 0, 35),
        position = UDim2.new(0, 10, 0.5, -17.5),
        callback = function(text)
            self:OnSearchChanged(text)
        end
    })
    
    -- Sort dropdown
    local sortOptions = {"Rarity", "Level", "Power", "Recent", "Name"}
    self:CreateDropdown(controlsBar, "Sort by", sortOptions, 
        UDim2.new(0, 150, 0, 35), UDim2.new(0, 220, 0.5, -17.5),
        function(option)
            self.CurrentSort = option
            self:RefreshInventory()
        end
    )
    
    -- Filter dropdown
    local filterOptions = {"All", "Equipped", "Locked", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Shiny", "Golden", "Rainbow"}
    self:CreateDropdown(controlsBar, "Filter", filterOptions,
        UDim2.new(0, 150, 0, 35), UDim2.new(0, 380, 0.5, -17.5),
        function(option)
            self.CurrentFilter = option
            self:RefreshInventory()
        end
    )
    
    -- Mass delete button
    local massDeleteButton = self._uiFactory:CreateButton(controlsBar, {
        text = "Mass Delete",
        size = UDim2.new(0, 120, 0, 35),
        position = UDim2.new(1, -130, 0.5, -17.5),
        backgroundColor = self._config.COLORS.Error,
        callback = function()
            self:OpenMassDelete()
        end
    })
end

function InventoryUI:CreateDropdown(parent: Frame, placeholder: string, options: {string}, 
                                   size: UDim2, position: UDim2, callback: (string) -> ())
    local dropdown = Instance.new("Frame")
    dropdown.Size = size
    dropdown.Position = position
    dropdown.BackgroundColor3 = self._config.COLORS.White
    dropdown.Parent = parent
    
    self._utilities.CreateCorner(dropdown, 8)
    self._utilities.CreateStroke(dropdown, self._config.COLORS.Primary, 2)
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = placeholder
    button.TextColor3 = self._config.COLORS.Dark
    button.Font = self._config.FONTS.Primary
    button.TextScaled = true
    button.Parent = dropdown
    
    local arrow = self._uiFactory:CreateLabel(dropdown, {
        text = "▼",
        size = UDim2.new(0, 20, 1, 0),
        position = UDim2.new(1, -25, 0, 0),
        textColor = self._config.COLORS.TextSecondary
    })
    
    local isOpen = false
    local optionsFrame = nil
    
    button.MouseButton1Click:Connect(function()
        if isOpen then
            -- Close dropdown
            if optionsFrame then
                optionsFrame:Destroy()
            end
            isOpen = false
        else
            -- Open dropdown
            optionsFrame = Instance.new("Frame")
            optionsFrame.Size = UDim2.new(1, 0, 0, #options * 30 + 10)
            optionsFrame.Position = UDim2.new(0, 0, 1, 5)
            optionsFrame.BackgroundColor3 = self._config.COLORS.White
            optionsFrame.ZIndex = dropdown.ZIndex + 10
            optionsFrame.Parent = dropdown
            
            self._utilities.CreateCorner(optionsFrame, 8)
            self._utilities.CreateStroke(optionsFrame, self._config.COLORS.Primary, 2)
            self._utilities.CreateShadow(optionsFrame, 0.3)
            
            for i, option in ipairs(options) do
                local optionButton = self._uiFactory:CreateButton(optionsFrame, {
                    text = option,
                    size = UDim2.new(1, -10, 0, 30),
                    position = UDim2.new(0, 5, 0, (i-1) * 30 + 5),
                    backgroundColor = self._config.COLORS.White,
                    textColor = self._config.COLORS.Dark,
                    callback = function()
                        button.Text = option
                        if optionsFrame then
                            optionsFrame:Destroy()
                        end
                        isOpen = false
                        
                        if callback then
                            callback(option)
                        end
                    end
                })
                
                -- Hover effect
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundColor3 = self._config.COLORS.Surface
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundColor3 = self._config.COLORS.White
                end)
            end
            
            isOpen = true
        end
    end)
    
    return dropdown
end

function InventoryUI:CreateTabs()
    local tabs = {
        {name = "Pets", callback = function(frame) self:CreatePetGrid(frame) end},
        {name = "Storage", callback = function(frame) self:CreateStorageTab(frame) end},
        {name = "Statistics", callback = function(frame) self:CreateStatsTab(frame) end}
    }
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 1, -170)
    tabContainer.Position = UDim2.new(0, 10, 0, 160)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.Frame
    
    -- Tab buttons
    local tabButtonsFrame = Instance.new("Frame")
    tabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
    tabButtonsFrame.BackgroundTransparency = 1
    tabButtonsFrame.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabButtonsFrame
    
    -- Tab content
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -45)
    tabContent.Position = UDim2.new(0, 0, 0, 45)
    tabContent.BackgroundColor3 = self._config.COLORS.White
    tabContent.Parent = tabContainer
    
    self._utilities.CreateCorner(tabContent, 12)
    
    local tabFrames = {}
    
    for i, tab in ipairs(tabs) do
        -- Create tab button
        local tabButton = self._uiFactory:CreateButton(tabButtonsFrame, {
            text = tab.name,
            size = UDim2.new(0, 120, 1, 0),
            backgroundColor = i == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
            textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
            callback = function()
                -- Update button states
                for j, btn in ipairs(tabButtonsFrame:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = j == i and self._config.COLORS.Primary or self._config.COLORS.Surface
                        btn.TextColor3 = j == i and self._config.COLORS.White or self._config.COLORS.Dark
                    end
                end
                
                -- Show tab content
                for name, frame in pairs(tabFrames) do
                    frame.Visible = name == tab.name
                end
            end
        })
        
        -- Create tab frame
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = tab.name .. "Tab"
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = tabContent
        
        tab.callback(tabFrame)
        tabFrames[tab.name] = tabFrame
    end
    
    self.TabFrames = tabFrames
end

-- ========================================
-- PET GRID
-- ========================================

function InventoryUI:CreatePetGrid(parent: Frame)
    -- Create scrolling frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PetGridScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -10)
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = self._config.COLORS.Primary
    scrollFrame.ScrollBarImageTransparency = 0.5
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = parent
    
    self.PetGrid = scrollFrame
    
    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "PetGridLayout"
    gridLayout.CellSize = UDim2.new(0, CARD_SIZE.X, 0, CARD_SIZE.Y)
    gridLayout.CellPadding = UDim2.new(0, GRID_PADDING, 0, GRID_PADDING)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Auto-size canvas
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

-- ========================================
-- PET CARD CREATION
-- ========================================

function InventoryUI:CreatePetCard(parent: ScrollingFrame, petInstance: PetInstance, petData: table): Frame?
    if not petInstance or not petData then
        return nil
    end
    
    -- Create card container
    local card = Instance.new("Frame")
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.petId or "unknown")
    card.BackgroundColor3 = self._config.COLORS.Surface
    card.BorderSizePixel = 0
    card.Parent = parent
    
    -- Store pet data as attributes for filtering
    card:SetAttribute("PetName", petData.displayName or "Unknown")
    card:SetAttribute("PetNickname", petInstance.nickname or "")
    card:SetAttribute("Rarity", petData.rarity or 1)
    card:SetAttribute("Equipped", petInstance.equipped or false)
    card:SetAttribute("Locked", petInstance.locked or false)
    
    self._utilities.CreateCorner(card, 8)
    
    -- Rarity border
    local border = Instance.new("Frame")
    border.Name = "RarityBorder"
    border.Size = UDim2.new(1, 0, 0, 4)
    border.Position = UDim2.new(0, 0, 1, -4)
    border.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    border.BorderSizePixel = 0
    border.Parent = card
    
    -- Pet image container
    local imageContainer = Instance.new("Frame")
    imageContainer.Name = "ImageContainer"
    imageContainer.Size = UDim2.new(1, -10, 1, -40)
    imageContainer.Position = UDim2.new(0, 5, 0, 5)
    imageContainer.BackgroundTransparency = 1
    imageContainer.Parent = card
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Name = "PetImage"
    petImage.Size = UDim2.new(1, 0, 1, 0)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = imageContainer
    
    -- Level badge
    local levelBadge = Instance.new("Frame")
    levelBadge.Name = "LevelBadge"
    levelBadge.Size = UDim2.new(0, 30, 0, 20)
    levelBadge.Position = UDim2.new(0, 2, 0, 2)
    levelBadge.BackgroundColor3 = self._config.COLORS.Dark
    levelBadge.Parent = card
    
    self._utilities.CreateCorner(levelBadge, 4)
    
    local levelLabel = self._uiFactory:CreateLabel(levelBadge, {
        text = "Lv." .. tostring(petInstance.level or 1),
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        textSize = 12
    })
    
    -- Equipped indicator
    if petInstance.equipped then
        local equippedIndicator = Instance.new("ImageLabel")
        equippedIndicator.Name = "EquippedIndicator"
        equippedIndicator.Size = UDim2.new(0, 24, 0, 24)
        equippedIndicator.Position = UDim2.new(1, -26, 0, 2)
        equippedIndicator.BackgroundTransparency = 1
        equippedIndicator.Image = "rbxassetid://7072717697" -- Checkmark icon
        equippedIndicator.ImageColor3 = self._config.COLORS.Success
        equippedIndicator.Parent = card
    end
    
    -- Lock indicator
    if petInstance.locked then
        local lockIndicator = Instance.new("ImageLabel")
        lockIndicator.Name = "LockIndicator"
        lockIndicator.Size = UDim2.new(0, 20, 0, 20)
        lockIndicator.Position = UDim2.new(1, -24, 1, -24)
        lockIndicator.BackgroundTransparency = 1
        lockIndicator.Image = "rbxassetid://7072718266" -- Lock icon
        lockIndicator.ImageColor3 = self._config.COLORS.Warning
        lockIndicator.Parent = card
    end
    
    -- Pet name
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = petInstance.nickname or petData.displayName or "Unknown",
        size = UDim2.new(1, -10, 0, 25),
        position = UDim2.new(0, 5, 1, -30),
        textScaled = true,
        font = self._config.FONTS.Primary
    })
    
    -- Variant effect
    if petInstance.variant then
        self:ApplyVariantEffect(card, petInstance.variant)
    end
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        self:ShowPetDetails(petInstance, petData)
    end)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        self._utilities.Tween(card, {
            BackgroundColor3 = self._utilities.LightenColor(self._config.COLORS.Surface, 0.1)
        }, self._config.TWEEN_INFO.Fast)
        
        -- Scale up slightly
        card:TweenSize(
            UDim2.new(0, CARD_SIZE.X + 5, 0, CARD_SIZE.Y + 5),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.1,
            true
        )
    end)
    
    button.MouseLeave:Connect(function()
        self._utilities.Tween(card, {
            BackgroundColor3 = self._config.COLORS.Surface
        }, self._config.TWEEN_INFO.Fast)
        
        -- Scale back
        card:TweenSize(
            UDim2.new(0, CARD_SIZE.X, 0, CARD_SIZE.Y),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.1,
            true
        )
    end)
    
    return card
end

function InventoryUI:UpdatePetCard(card: Frame, petInstance: PetInstance, petData: table)
    -- Update name
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.petId)
    
    -- Update attributes
    card:SetAttribute("PetName", petData.displayName or "Unknown")
    card:SetAttribute("PetNickname", petInstance.nickname or "")
    card:SetAttribute("Rarity", petData.rarity or 1)
    card:SetAttribute("Equipped", petInstance.equipped or false)
    card:SetAttribute("Locked", petInstance.locked or false)
    
    -- Update image
    local petImage = card:FindFirstChild("PetImage", true)
    if petImage then
        petImage.Image = petData.imageId or ""
    end
    
    -- Update level
    local levelLabel = card:FindFirstChild("LevelBadge"):FindFirstChildOfClass("TextLabel")
    if levelLabel then
        levelLabel.Text = "Lv." .. tostring(petInstance.level or 1)
    end
    
    -- Update name
    local nameLabel = card:FindFirstChildOfClass("TextLabel")
    if nameLabel and nameLabel.Parent == card then
        nameLabel.Text = petInstance.nickname or petData.displayName or "Unknown"
    end
    
    -- Update rarity border
    local border = card:FindFirstChild("RarityBorder")
    if border then
        border.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    end
    
    -- Update equipped indicator
    local equippedIndicator = card:FindFirstChild("EquippedIndicator")
    if petInstance.equipped and not equippedIndicator then
        -- Add equipped indicator
        equippedIndicator = Instance.new("ImageLabel")
        equippedIndicator.Name = "EquippedIndicator"
        equippedIndicator.Size = UDim2.new(0, 24, 0, 24)
        equippedIndicator.Position = UDim2.new(1, -26, 0, 2)
        equippedIndicator.BackgroundTransparency = 1
        equippedIndicator.Image = "rbxassetid://7072717697"
        equippedIndicator.ImageColor3 = self._config.COLORS.Success
        equippedIndicator.Parent = card
    elseif not petInstance.equipped and equippedIndicator then
        equippedIndicator:Destroy()
    end
    
    -- Update lock indicator
    local lockIndicator = card:FindFirstChild("LockIndicator")
    if petInstance.locked and not lockIndicator then
        -- Add lock indicator
        lockIndicator = Instance.new("ImageLabel")
        lockIndicator.Name = "LockIndicator"
        lockIndicator.Size = UDim2.new(0, 20, 0, 20)
        lockIndicator.Position = UDim2.new(1, -24, 1, -24)
        lockIndicator.BackgroundTransparency = 1
        lockIndicator.Image = "rbxassetid://7072718266"
        lockIndicator.ImageColor3 = self._config.COLORS.Warning
        lockIndicator.Parent = card
    elseif not petInstance.locked and lockIndicator then
        lockIndicator:Destroy()
    end
end

function InventoryUI:ApplyVariantEffect(card: Frame, variant: string)
    local imageContainer = card:FindFirstChild("ImageContainer")
    if not imageContainer then return end
    
    if variant == "shiny" then
        -- Add sparkle effect
        if self._particleSystem then
            self._particleSystem:CreateSparkleLoop(imageContainer, {
                rate = 0.5,
                lifetime = 2,
                size = NumberSequence.new(0.2)
            })
        end
    elseif variant == "golden" then
        -- Add golden glow
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1.2, 0, 1.2, 0)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = Color3.fromRGB(255, 215, 0)
        glow.ImageTransparency = 0.5
        glow.ZIndex = -1
        glow.Parent = imageContainer
    elseif variant == "rainbow" then
        -- Add rainbow effect
        if self._effectsLibrary then
            self._effectsLibrary:CreateRainbowEffect(imageContainer)
        end
    end
end

-- ========================================
-- INVENTORY REFRESH
-- ========================================

function InventoryUI:RefreshInventory()
    -- Prevent rapid refreshes
    local currentTime = tick()
    if currentTime - self.LastRefreshTime < self.RefreshCooldown then
        return
    end
    self.LastRefreshTime = currentTime
    
    -- Prevent multiple refreshes
    if self.IsRefreshing then
        if self._config.DEBUG.ENABLED then
            print("[InventoryUI] Already refreshing, skipping")
        end
        return
    end
    self.IsRefreshing = true
    
    -- Ensure PetGrid exists
    if not self.PetGrid or not self.PetGrid.Parent then
        warn("[InventoryUI] PetGrid not found, cannot refresh")
        self.IsRefreshing = false
        return
    end
    
    -- Get grid layout
    local gridLayout = self.PetGrid:FindFirstChildOfClass("UIGridLayout")
    
    -- Hide all existing cards for recycling
    for _, card in ipairs(self.PetCardCache) do
        card.Visible = false
        card.Parent = nil
    end
    
    -- Show loading state
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Name = "LoadingLabel"
    loadingLabel.Size = UDim2.new(1, 0, 0, 50)
    loadingLabel.Position = UDim2.new(0, 0, 0.5, -25)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "Loading pets..."
    loadingLabel.TextScaled = true
    loadingLabel.TextColor3 = self._config.COLORS.TextSecondary
    loadingLabel.Font = self._config.FONTS.Primary
    loadingLabel.Parent = self.PetGrid
    
    -- Process pets data
    task.spawn(function()
        task.wait(0.1) -- Small delay for loading state
        
        -- Get pet data
        local pets = self:GetFilteredAndSortedPets()
        
        -- Remove loading label
        if loadingLabel and loadingLabel.Parent then
            loadingLabel:Destroy()
        end
        
        -- Update stats
        self:UpdateStats(pets)
        
        -- Create/update pet cards
        if #pets == 0 then
            self:ShowEmptyState()
        else
            self:DisplayPets(pets)
        end
        
        -- Reset refresh flag
        self.IsRefreshing = false
    end)
end

function InventoryUI:GetFilteredAndSortedPets(): {{pet: PetInstance, data: table}}
    local playerData = self._dataCache and self._dataCache:Get() or 
                      self._stateManager and self._stateManager:Get("playerData") or
                      {}
    
    if not playerData.pets then
        return {}
    end
    
    local pets = {}
    
    -- Convert to array format
    if type(playerData.pets) == "table" then
        for uniqueId, petData in pairs(playerData.pets) do
            if type(petData) == "table" then
                petData.uniqueId = uniqueId
                
                -- Get pet template data
                local templateData = self._dataCache and self._dataCache:Get("petDatabase." .. petData.petId) or
                                   {displayName = "Unknown", rarity = 1}
                
                -- Apply filters
                local filterFunc = FILTER_DEFINITIONS[self.CurrentFilter]
                if filterFunc and filterFunc(petData, templateData) then
                    -- Apply search filter
                    if self.SearchText == "" or self:MatchesSearch(petData, templateData) then
                        table.insert(pets, {pet = petData, data = templateData})
                    end
                end
            end
        end
    end
    
    -- Sort pets
    local sortFunc = SORT_FUNCTIONS[self.CurrentSort]
    if sortFunc then
        table.sort(pets, function(a, b)
            return sortFunc(a.pet, b.pet, a.data, b.data)
        end)
    end
    
    return pets
end

function InventoryUI:MatchesSearch(petInstance: PetInstance, petData: table): boolean
    local searchLower = self.SearchText:lower()
    local petName = (petInstance.nickname or petData.displayName or ""):lower()
    return petName:find(searchLower, 1, true) ~= nil
end

function InventoryUI:UpdateStats(pets: table)
    local equippedCount = 0
    for _, petInfo in ipairs(pets) do
        if petInfo.pet.equipped then
            equippedCount = equippedCount + 1
        end
    end
    
    local maxStorage = self._dataCache and self._dataCache:Get("maxPetStorage") or 500
    
    if self.StatsLabels.PetCount then
        self.StatsLabels.PetCount.Text = "Pets: " .. #pets .. "/" .. maxStorage
    end
    
    if self.StatsLabels.Equipped then
        self.StatsLabels.Equipped.Text = "Equipped: " .. equippedCount .. "/6"
    end
    
    if self.StatsLabels.Storage then
        if type(self.StatsLabels.Storage.UpdateValue) == "function" then
            self.StatsLabels.Storage.UpdateValue(#pets)
        elseif self.StatsLabels.Storage:FindFirstChild("Frame") and 
               type(self.StatsLabels.Storage.Frame.UpdateValue) == "function" then
            self.StatsLabels.Storage.Frame.UpdateValue(#pets)
        end
    end
end

function InventoryUI:ShowEmptyState()
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Size = UDim2.new(1, 0, 0, 100)
    emptyLabel.Position = UDim2.new(0, 0, 0.5, -50)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "No pets found!\nTry adjusting your filters or open some eggs!"
    emptyLabel.TextScaled = true
    emptyLabel.TextColor3 = self._config.COLORS.TextSecondary
    emptyLabel.Font = self._config.FONTS.Primary
    emptyLabel.Parent = self.PetGrid
end

function InventoryUI:DisplayPets(pets: table)
    for i, petInfo in ipairs(pets) do
        -- Try to reuse existing card
        local card = self.PetCardCache[i]
        if card then
            -- Update existing card
            self:UpdatePetCard(card, petInfo.pet, petInfo.data)
            card.Parent = self.PetGrid
            card.Visible = true
        else
            -- Create new card if not enough in cache
            card = self:CreatePetCard(self.PetGrid, petInfo.pet, petInfo.data)
            if card then
                table.insert(self.PetCardCache, card)
            end
        end
        
        if card then
            card.LayoutOrder = i
        end
        
        -- Limit cache size
        if #self.PetCardCache > MAX_CARD_CACHE then
            local oldCard = table.remove(self.PetCardCache, 1)
            if oldCard then
                oldCard:Destroy()
            end
        end
    end
end

-- ========================================
-- PET DETAILS
-- ========================================

function InventoryUI:ShowPetDetails(petInstance: PetInstance, petData: table)
    -- Fire event for PetDetailsUI to handle
    if self._eventBus then
        self._eventBus:Fire("ShowPetDetails", {
            petInstance = petInstance,
            petData = petData
        })
    end
end

-- ========================================
-- MASS DELETE
-- ========================================

function InventoryUI:OpenMassDelete()
    -- Close any existing delete window
    if self.DeleteOverlay then
        self.DeleteOverlay:Destroy()
    end
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "MassDeleteOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 300
    overlay.Parent = self.Frame.Parent
    
    self.DeleteOverlay = overlay
    
    -- Create window
    local deleteWindow = Instance.new("Frame")
    deleteWindow.Name = "DeleteWindow"
    deleteWindow.Size = UDim2.new(0, MASS_DELETE_WINDOW_SIZE.X, 0, MASS_DELETE_WINDOW_SIZE.Y)
    deleteWindow.Position = UDim2.new(0.5, -MASS_DELETE_WINDOW_SIZE.X/2, 0.5, -MASS_DELETE_WINDOW_SIZE.Y/2)
    deleteWindow.BackgroundColor3 = self._config.COLORS.Background
    deleteWindow.ZIndex = 301
    deleteWindow.Parent = overlay
    
    self._utilities.CreateCorner(deleteWindow, 20)
    self._utilities.CreateShadow(deleteWindow, 0.5)
    
    -- Header
    local header = self._uiFactory:CreateFrame(deleteWindow, {
        name = "Header",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Error,
        zIndex = 302
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "⚠️ Mass Delete Pets",
        size = UDim2.new(1, -50, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 20,
        zIndex = 303
    })
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(header, {
        text = "✖",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -45, 0.5, -20),
        backgroundColor = Color3.new(1, 1, 1),
        backgroundTransparency = 0.9,
        textColor = self._config.COLORS.White,
        zIndex = 303,
        callback = function()
            self:CloseMassDelete()
        end
    })
    
    -- Content
    self:CreateMassDeleteContent(deleteWindow)
    
    -- Animate in
    deleteWindow.Size = UDim2.new(0, 0, 0, 0)
    self._utilities.Tween(deleteWindow, {
        Size = UDim2.new(0, MASS_DELETE_WINDOW_SIZE.X, 0, MASS_DELETE_WINDOW_SIZE.Y)
    }, self._config.TWEEN_INFO.Elastic)
end

function InventoryUI:CreateMassDeleteContent(window: Frame)
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -140)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundTransparency = 1
    content.ZIndex = 302
    content.Parent = window
    
    -- Instructions
    local infoLabel = self._uiFactory:CreateLabel(content, {
        text = "Select pets to delete. This action cannot be undone!",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0),
        textColor = self._config.COLORS.Error,
        textWrapped = true,
        zIndex = 303
    })
    
    -- Quick select buttons
    local quickSelectFrame = Instance.new("Frame")
    quickSelectFrame.Size = UDim2.new(1, 0, 0, 40)
    quickSelectFrame.Position = UDim2.new(0, 0, 0, 50)
    quickSelectFrame.BackgroundTransparency = 1
    quickSelectFrame.ZIndex = 303
    quickSelectFrame.Parent = content
    
    local selectAllCommon = self._uiFactory:CreateButton(quickSelectFrame, {
        text = "All Common",
        size = UDim2.new(0, 120, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        callback = function()
            self:SelectPetsByRarity(1)
        end
    })
    
    local selectAllUncommon = self._uiFactory:CreateButton(quickSelectFrame, {
        text = "All Uncommon",
        size = UDim2.new(0, 120, 1, 0),
        position = UDim2.new(0, 130, 0, 0),
        callback = function()
            self:SelectPetsByRarity(2)
        end
    })
    
    local deselectAll = self._uiFactory:CreateButton(quickSelectFrame, {
        text = "Deselect All",
        size = UDim2.new(0, 120, 1, 0),
        position = UDim2.new(0, 260, 0, 0),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:DeselectAllPets()
        end
    })
    
    -- Pet selection grid
    local scrollFrame = self._uiFactory:CreateScrollingFrame(content, {
        size = UDim2.new(1, 0, 1, -150),
        position = UDim2.new(0, 0, 0, 100)
    })
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    self.DeleteSelectionGrid = scrollFrame
    self.SelectedForDeletion = {}
    
    -- Load pets for selection
    self:LoadPetsForDeletion(scrollFrame)
    
    -- Update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Bottom bar
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 60)
    bottomBar.Position = UDim2.new(0, 0, 1, -60)
    bottomBar.BackgroundColor3 = self._config.COLORS.Dark
    bottomBar.ZIndex = 302
    bottomBar.Parent = window
    
    self._utilities.CreateCorner(bottomBar, 20)
    
    -- Selected count
    local selectedLabel = self._uiFactory:CreateLabel(bottomBar, {
        text = "Selected: 0 pets",
        size = UDim2.new(0, 200, 1, 0),
        position = UDim2.new(0, 20, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        zIndex = 303
    })
    self.DeleteSelectedLabel = selectedLabel
    
    -- Delete button
    local deleteButton = self._uiFactory:CreateButton(bottomBar, {
        text = "Delete Selected",
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(1, -170, 0.5, -20),
        backgroundColor = self._config.COLORS.Error,
        zIndex = 303,
        callback = function()
            self:ConfirmMassDelete()
        end
    })
end

function InventoryUI:LoadPetsForDeletion(parent: ScrollingFrame)
    local playerData = self._dataCache and self._dataCache:Get() or {}
    if not playerData.pets then return end
    
    local pets = {}
    
    -- Convert to array if needed
    for uniqueId, pet in pairs(playerData.pets) do
        if type(pet) == "table" and not pet.equipped and not pet.locked then
            pet.uniqueId = uniqueId
            table.insert(pets, pet)
        end
    end
    
    -- Sort by rarity (lowest first for easier mass deletion)
    table.sort(pets, function(a, b)
        local aData = self._dataCache and self._dataCache:Get("petDatabase." .. a.petId) or {}
        local bData = self._dataCache and self._dataCache:Get("petDatabase." .. b.petId) or {}
        return (aData.rarity or 1) < (bData.rarity or 1)
    end)
    
    -- Create selection cards
    for _, pet in ipairs(pets) do
        local petData = self._dataCache and self._dataCache:Get("petDatabase." .. pet.petId) or
                       {displayName = "Unknown", rarity = 1}
        
        local card = self:CreateDeleteSelectionCard(parent, pet, petData)
    end
end

function InventoryUI:CreateDeleteSelectionCard(parent: ScrollingFrame, petInstance: PetInstance, petData: table): Frame
    local card = Instance.new("Frame")
    card.Name = petInstance.uniqueId
    card.BackgroundColor3 = self._config.COLORS.Surface
    card.BorderSizePixel = 0
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 8)
    
    -- Selection indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "SelectIndicator"
    indicator.Size = UDim2.new(1, 0, 1, 0)
    indicator.BackgroundColor3 = self._config.COLORS.Success
    indicator.BackgroundTransparency = 1
    indicator.Parent = card
    
    self._utilities.CreateCorner(indicator, 8)
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, -10, 1, -30)
    petImage.Position = UDim2.new(0, 5, 0, 5)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = card
    
    -- Name label
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = petInstance.nickname or petData.displayName or "Unknown",
        size = UDim2.new(1, -4, 0, 20),
        position = UDim2.new(0, 2, 1, -22),
        textScaled = true,
        textSize = 12
    })
    
    -- Rarity indicator
    local rarityBar = Instance.new("Frame")
    rarityBar.Size = UDim2.new(1, 0, 0, 3)
    rarityBar.Position = UDim2.new(0, 0, 1, -3)
    rarityBar.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    rarityBar.BorderSizePixel = 0
    rarityBar.Parent = card
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        if self.SelectedForDeletion[petInstance.uniqueId] then
            self.SelectedForDeletion[petInstance.uniqueId] = nil
            indicator.BackgroundTransparency = 1
        else
            self.SelectedForDeletion[petInstance.uniqueId] = true
            indicator.BackgroundTransparency = 0.3
        end
        
        self:UpdateDeleteCount()
    end)
    
    return card
end

function InventoryUI:SelectPetsByRarity(rarity: number)
    if not self.DeleteSelectionGrid then return end
    
    for _, card in ipairs(self.DeleteSelectionGrid:GetChildren()) do
        if card:IsA("Frame") then
            local petId = card.Name
            local playerData = self._dataCache and self._dataCache:Get() or {}
            
            if playerData.pets and playerData.pets[petId] then
                local pet = playerData.pets[petId]
                local petData = self._dataCache and self._dataCache:Get("petDatabase." .. pet.petId) or {}
                
                if petData.rarity == rarity and not pet.equipped and not pet.locked then
                    self.SelectedForDeletion[petId] = true
                    local indicator = card:FindFirstChild("SelectIndicator")
                    if indicator then
                        indicator.BackgroundTransparency = 0.3
                    end
                end
            end
        end
    end
    
    self:UpdateDeleteCount()
end

function InventoryUI:DeselectAllPets()
    self.SelectedForDeletion = {}
    
    if self.DeleteSelectionGrid then
        for _, card in ipairs(self.DeleteSelectionGrid:GetChildren()) do
            if card:IsA("Frame") then
                local indicator = card:FindFirstChild("SelectIndicator")
                if indicator then
                    indicator.BackgroundTransparency = 1
                end
            end
        end
    end
    
    self:UpdateDeleteCount()
end

function InventoryUI:UpdateDeleteCount()
    local count = 0
    for _ in pairs(self.SelectedForDeletion) do
        count = count + 1
    end
    
    if self.DeleteSelectedLabel then
        self.DeleteSelectedLabel.Text = "Selected: " .. count .. " pets"
    end
end

function InventoryUI:ConfirmMassDelete()
    local count = 0
    local petIds = {}
    
    for petId in pairs(self.SelectedForDeletion) do
        count = count + 1
        table.insert(petIds, petId)
    end
    
    if count == 0 then
        self._notificationSystem:SendNotification("Error", "No pets selected for deletion", "error")
        return
    end
    
    -- Create confirmation dialog
    local confirmText = string.format("Are you sure you want to delete %d pets?\n\nThis action cannot be undone!", count)
    
    -- Show confirmation
    local confirmDialog = self._uiFactory:CreateConfirmDialog({
        title = "Confirm Mass Delete",
        message = confirmText,
        confirmText = "Delete " .. count .. " Pets",
        confirmColor = self._config.COLORS.Error,
        onConfirm = function()
            self:ExecuteMassDelete(petIds)
        end
    })
end

function InventoryUI:ExecuteMassDelete(petIds: {string})
    -- Show loading state
    if self.DeleteOverlay then
        local loadingLabel = self._uiFactory:CreateLabel(self.DeleteOverlay, {
            text = "Deleting pets...",
            size = UDim2.new(0, 200, 0, 50),
            position = UDim2.new(0.5, -100, 0.5, -25),
            backgroundColor = self._config.COLORS.Dark,
            textColor = self._config.COLORS.White,
            zIndex = 400
        })
        
        self._utilities.CreateCorner(loadingLabel, 8)
    end
    
    -- Send delete request
    if self._remoteManager then
        local success, result = self._remoteManager:InvokeServer("MassDeletePets", petIds)
        
        if success then
            self._notificationSystem:SendNotification("Success", 
                string.format("Successfully deleted %d pets!", #petIds), "success")
            
            -- Play sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("Success")
            end
            
            -- Close mass delete window
            self:CloseMassDelete()
            
            -- Refresh inventory
            self:RefreshInventory()
        else
            self._notificationSystem:SendNotification("Error", 
                result or "Failed to delete pets", "error")
        end
    end
end

function InventoryUI:CloseMassDelete()
    if self.DeleteOverlay then
        local deleteWindow = self.DeleteOverlay:FindFirstChild("DeleteWindow")
        if deleteWindow then
            self._utilities.Tween(deleteWindow, {
                Size = UDim2.new(0, 0, 0, 0)
            }, self._config.TWEEN_INFO.Normal)
        end
        
        self._utilities.Tween(self.DeleteOverlay, {
            BackgroundTransparency = 1
        }, self._config.TWEEN_INFO.Normal)
        
        task.wait(0.3)
        self.DeleteOverlay:Destroy()
        self.DeleteOverlay = nil
    end
    
    -- Clear selection
    self.SelectedForDeletion = {}
    self.DeleteSelectionGrid = nil
    self.DeleteSelectedLabel = nil
end

-- ========================================
-- OTHER TABS
-- ========================================

function InventoryUI:CreateStorageTab(parent: Frame)
    -- Storage statistics and upgrades
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -40)
    content.Position = UDim2.new(0, 20, 0, 20)
    content.BackgroundTransparency = 1
    content.Parent = parent
    
    -- Current storage info
    local storageInfo = self._uiFactory:CreateFrame(content, {
        size = UDim2.new(1, 0, 0, 200),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Surface
    })
    
    local titleLabel = self._uiFactory:CreateLabel(storageInfo, {
        text = "Pet Storage",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 10),
        font = self._config.FONTS.Display,
        textSize = 20
    })
    
    -- Storage progress bar
    local progressFrame = Instance.new("Frame")
    progressFrame.Size = UDim2.new(1, -40, 0, 30)
    progressFrame.Position = UDim2.new(0, 20, 0, 60)
    progressFrame.BackgroundColor3 = self._config.COLORS.Dark
    progressFrame.Parent = storageInfo
    
    self._utilities.CreateCorner(progressFrame, 15)
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "StorageFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = self._config.COLORS.Primary
    progressFill.Parent = progressFrame
    
    self._utilities.CreateCorner(progressFill, 15)
    
    -- Storage text
    local storageText = self._uiFactory:CreateLabel(storageInfo, {
        text = "0 / 500 Pets",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 100),
        font = self._config.FONTS.Secondary,
        textSize = 18
    })
    
    -- Upgrade button
    local upgradeButton = self._uiFactory:CreateButton(storageInfo, {
        text = "Upgrade Storage",
        size = UDim2.new(0, 200, 0, 40),
        position = UDim2.new(0.5, -100, 0, 140),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            -- Open storage upgrade shop
            if self._eventBus then
                self._eventBus:Fire("OpenStorageUpgrade", {})
            end
        end
    })
end

function InventoryUI:CreateStatsTab(parent: Frame)
    -- Pet collection statistics
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, -20, 1, -20),
        position = UDim2.new(0, 10, 0, 10)
    })
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 0, 800)
    content.BackgroundTransparency = 1
    content.Parent = scrollFrame
    
    local yOffset = 0
    
    -- Collection stats
    local collectionStats = {
        {label = "Total Pets Collected", getValue = function() return "0" end},
        {label = "Unique Pets", getValue = function() return "0" end},
        {label = "Rarest Pet", getValue = function() return "None" end},
        {label = "Total Pet Power", getValue = function() return "0" end},
        {label = "Average Pet Level", getValue = function() return "0" end},
        {label = "Pets Traded", getValue = function() return "0" end},
        {label = "Eggs Opened", getValue = function() return "0" end},
    }
    
    for _, stat in ipairs(collectionStats) do
        local statFrame = self._uiFactory:CreateFrame(content, {
            size = UDim2.new(1, 0, 0, 60),
            position = UDim2.new(0, 0, 0, yOffset),
            backgroundColor = self._config.COLORS.Surface
        })
        
        local labelText = self._uiFactory:CreateLabel(statFrame, {
            text = stat.label,
            size = UDim2.new(0.6, -10, 1, 0),
            position = UDim2.new(0, 10, 0, 0),
            textXAlignment = Enum.TextXAlignment.Left,
            font = self._config.FONTS.Primary
        })
        
        local valueText = self._uiFactory:CreateLabel(statFrame, {
            text = stat.getValue(),
            size = UDim2.new(0.4, -10, 1, 0),
            position = UDim2.new(0.6, 0, 0, 0),
            textXAlignment = Enum.TextXAlignment.Right,
            font = self._config.FONTS.Secondary,
            textColor = self._config.COLORS.Primary
        })
        
        yOffset = yOffset + 70
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function InventoryUI:OnSearchChanged(text: string)
    -- Debounce search
    if self.SearchDebounce then
        task.cancel(self.SearchDebounce)
    end
    
    self.SearchDebounce = task.spawn(function()
        task.wait(SEARCH_DEBOUNCE)
        self.SearchText = text
        self:RefreshInventory()
        self.SearchDebounce = nil
    end)
end

function InventoryUI:UpdatePetCardEquipStatus(uniqueId: string, equipped: boolean)
    -- Find and update the specific pet card
    for _, card in ipairs(self.PetCardCache) do
        if card.Name == "PetCard_" .. uniqueId then
            card:SetAttribute("Equipped", equipped)
            
            local indicator = card:FindFirstChild("EquippedIndicator")
            if equipped and not indicator then
                -- Add equipped indicator
                indicator = Instance.new("ImageLabel")
                indicator.Name = "EquippedIndicator"
                indicator.Size = UDim2.new(0, 24, 0, 24)
                indicator.Position = UDim2.new(1, -26, 0, 2)
                indicator.BackgroundTransparency = 1
                indicator.Image = "rbxassetid://7072717697"
                indicator.ImageColor3 = self._config.COLORS.Success
                indicator.Parent = card
            elseif not equipped and indicator then
                indicator:Destroy()
            end
            
            break
        end
    end
end

function InventoryUI:UpdatePetCardLockStatus(uniqueId: string, locked: boolean)
    -- Find and update the specific pet card
    for _, card in ipairs(self.PetCardCache) do
        if card.Name == "PetCard_" .. uniqueId then
            card:SetAttribute("Locked", locked)
            
            local indicator = card:FindFirstChild("LockIndicator")
            if locked and not indicator then
                -- Add lock indicator
                indicator = Instance.new("ImageLabel")
                indicator.Name = "LockIndicator"
                indicator.Size = UDim2.new(0, 20, 0, 20)
                indicator.Position = UDim2.new(1, -24, 1, -24)
                indicator.BackgroundTransparency = 1
                indicator.Image = "rbxassetid://7072718266"
                indicator.ImageColor3 = self._config.COLORS.Warning
                indicator.Parent = card
            elseif not locked and indicator then
                indicator:Destroy()
            end
            
            break
        end
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function InventoryUI:Destroy()
    -- Cancel any pending operations
    if self.SearchDebounce then
        task.cancel(self.SearchDebounce)
    end
    
    -- Clean up watchers
    if self.PetWatcher then
        self.PetWatcher:Disconnect()
        self.PetWatcher = nil
    end
    
    -- Destroy UI
    if self.Frame then
        self.Frame:Destroy()
        self.Frame = nil
    end
    
    if self.DeleteOverlay then
        self.DeleteOverlay:Destroy()
        self.DeleteOverlay = nil
    end
    
    -- Clear cache
    self.PetCardCache = {}
    self.SelectedForDeletion = {}
end

return InventoryUI