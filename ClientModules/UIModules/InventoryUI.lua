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
        local aName = a.nickname or aData.name or aData.displayName or "Unknown"
        local bName = b.nickname or bData.name or bData.displayName or "Unknown"
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
    
    -- Pet name mapping - we'll populate this from server data
    self._petNameCache = {}
    
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
    
    -- Listen for remote inventory updates from server
    if self._remoteManager then
        self._remoteManager:On("InventoryUpdated", function(data)
            print("[InventoryUI] Received inventory update from server:", data)
            if data and data.pets then
                -- Update data cache with new pets
                if self._dataCache then
                    self._dataCache:Set("pets", data.pets)
                    self._dataCache:Set("petCount", data.petCount or 0)
                    
                    -- Also update playerData pets
                    local playerData = self._dataCache:Get("playerData") or {}
                    playerData.pets = data.pets
                    playerData.petCount = data.petCount or 0
                    self._dataCache:Set("playerData", playerData)
                end
                -- Refresh UI
                if self.Frame and self.Frame.Visible then
                    self:RefreshInventory()
                end
            end
        end)
        
        self._remoteManager:On("PetUpdated", function(data)
            print("[InventoryUI] Received pet update from server:", data)
            print("[InventoryUI] Pet update action:", data and data.action)
            print("[InventoryUI] Pet data:", data and data.pet)
            
            if data and data.action == "added" and data.pet then
                -- Update data cache with new pet
                if self._dataCache then
                    local pets = self._dataCache:Get("pets") or {}
                    local petId = data.petId or (data.pet and data.pet.uniqueId)
                    
                    if petId then
                        pets[petId] = data.pet
                        self._dataCache:Set("pets", pets)
                        
                        local petCount = self._dataCache:Get("petCount") or 0
                        petCount = petCount + 1
                        self._dataCache:Set("petCount", petCount)
                        
                        -- Also update playerData
                        local playerData = self._dataCache:Get("playerData") or {}
                        playerData.pets = pets
                        playerData.petCount = petCount
                        self._dataCache:Set("playerData", playerData)
                        
                        print("[InventoryUI] Updated pet cache. Total pets:", petCount)
                        print("[InventoryUI] Pet IDs in cache:", petId)
                    else
                        warn("[InventoryUI] No petId found in update data")
                    end
                else
                    warn("[InventoryUI] No dataCache available")
                end
                -- Refresh UI
                if self.Frame and self.Frame.Visible then
                    print("[InventoryUI] Refreshing inventory display")
                    self:RefreshInventory()
                else
                    print("[InventoryUI] Frame not visible, skipping refresh")
                end
            end
        end)
    end
    
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
        -- Smooth fade in animation
        self.Frame.Visible = true
        self.Frame.BackgroundTransparency = 1
        
        -- Fade in background
        self._utilities.Tween(self.Frame, {
            BackgroundTransparency = 0
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Animate content with slide effect
        local originalPosition = self.Frame.Position
        self.Frame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 100)
        
        self._utilities.Tween(self.Frame, {
            Position = originalPosition
        }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        
        -- Always ensure we're on Pets tab first to create PetGrid
        self:ShowTab("Pets")
        -- Small delay to ensure UI is ready
        task.wait()
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
    
    -- Show default tab (Pets) to ensure PetGrid exists
    self:ShowTab("Pets")
    
    -- Delay initial load to ensure UI is ready
    task.defer(function()
        self:RefreshInventory()
    end)
end

function InventoryUI:Close()
    if self.Frame then
        -- Smooth fade out animation
        self._utilities.Tween(self.Frame, {
            BackgroundTransparency = 1,
            Position = UDim2.new(self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, 1, 100)
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        
        task.wait(0.3)
        self.Frame.Visible = false
    end
    
    -- Clear cached references to prevent stale state
    self.PetGrid = nil
    self.TabFrames = {}
    self.CurrentTab = "Pets"
    
    -- Cancel any ongoing refreshes
    self.IsRefreshing = false
end

-- ========================================
-- UI CREATION
-- ========================================

function InventoryUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                   self._windowManager and self._windowManager:GetMainPanel() or 
                   Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[InventoryUI] No parent container found")
        return
    end
    
    -- Create main frame
    self.Frame = self._uiFactory:CreateFrame(parent, {
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
    
    -- Store update function in module's storage bars table
    if not self.StorageBars then
        self.StorageBars = {}
    end
    
    local updateFunc = function(current: number)
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
    
    self.StorageBars[frame] = {
        barFill = barFill,
        updateFunc = updateFunc
    }
    
    -- Initial update
    if self.StorageBars[frame] then
        self.StorageBars[frame].updateFunc(0)
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
    
    -- Enhanced search box with icon and clear button
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0, 200, 0, 35)
    searchContainer.Position = UDim2.new(0, 10, 0.5, -17.5)
    searchContainer.BackgroundColor3 = self._config.COLORS.White
    searchContainer.Parent = controlsBar
    
    self._utilities.CreateCorner(searchContainer, 8)
    
    -- Search icon
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 20, 0, 20)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -10)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://7072707859" -- Magnifying glass icon
    searchIcon.ImageColor3 = self._config.COLORS.TextSecondary
    searchIcon.Parent = searchContainer
    
    -- Search box with animated placeholder
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -65, 1, 0)
    searchBox.Position = UDim2.new(0, 35, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = self._config.FONTS.Primary
    searchBox.Text = ""
    searchBox.TextColor3 = self._config.COLORS.Dark
    searchBox.TextSize = 14
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer
    
    -- Animated placeholder
    local placeholderText = Instance.new("TextLabel")
    placeholderText.Name = "Placeholder"
    placeholderText.Size = UDim2.new(1, 0, 1, 0)
    placeholderText.BackgroundTransparency = 1
    placeholderText.Font = self._config.FONTS.Primary
    placeholderText.Text = "Search pets..."
    placeholderText.TextColor3 = self._config.COLORS.TextSecondary
    placeholderText.TextSize = 14
    placeholderText.TextXAlignment = Enum.TextXAlignment.Left
    placeholderText.Parent = searchBox
    
    -- Clear button (initially hidden)
    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearButton"
    clearButton.Size = UDim2.new(0, 25, 0, 25)
    clearButton.Position = UDim2.new(1, -30, 0.5, -12.5)
    clearButton.BackgroundColor3 = self._config.COLORS.Surface
    clearButton.Text = "×"
    clearButton.TextColor3 = self._config.COLORS.Dark
    clearButton.TextSize = 20
    clearButton.Font = Enum.Font.SourceSans
    clearButton.Visible = false
    clearButton.Parent = searchContainer
    
    self._utilities.CreateCorner(clearButton, 12)
    
    -- Search functionality
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = searchBox.Text
        
        -- Hide/show placeholder
        placeholderText.Visible = text == ""
        
        -- Show/hide clear button
        clearButton.Visible = text ~= ""
        
        -- Animate search icon
        if text ~= "" then
            self._utilities.Tween(searchIcon, {
                ImageColor3 = self._config.COLORS.Primary
            }, TweenInfo.new(0.2))
        else
            self._utilities.Tween(searchIcon, {
                ImageColor3 = self._config.COLORS.TextSecondary
            }, TweenInfo.new(0.2))
        end
        
        -- Perform search
        self:OnSearchChanged(text)
    end)
    
    -- Focus animations
    searchBox.Focused:Connect(function()
        self._utilities.Tween(searchContainer, {
            BackgroundColor3 = self._utilities.LightenColor(self._config.COLORS.White, 0.05)
        }, TweenInfo.new(0.2))
        
        -- Add glow effect
        local stroke = Instance.new("UIStroke")
        stroke.Name = "FocusStroke"
        stroke.Color = self._config.COLORS.Primary
        stroke.Thickness = 2
        stroke.Transparency = 0.5
        stroke.Parent = searchContainer
        
        self._utilities.Tween(stroke, {
            Transparency = 0
        }, TweenInfo.new(0.2))
    end)
    
    searchBox.FocusLost:Connect(function()
        self._utilities.Tween(searchContainer, {
            BackgroundColor3 = self._config.COLORS.White
        }, TweenInfo.new(0.2))
        
        local stroke = searchContainer:FindFirstChild("FocusStroke")
        if stroke then
            self._utilities.Tween(stroke, {
                Transparency = 1
            }, TweenInfo.new(0.2))
            task.wait(0.2)
            stroke:Destroy()
        end
    end)
    
    -- Clear button functionality
    clearButton.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        searchBox:CaptureFocus()
        
        -- Animation
        clearButton:TweenSize(
            UDim2.new(0, 20, 0, 20),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Back,
            0.1,
            true,
            function()
                clearButton:TweenSize(
                    UDim2.new(0, 25, 0, 25),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Back,
                    0.1,
                    true
                )
            end
        )
    end)
    
    -- Store reference
    self.SearchBox = searchBox
    
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
            optionsFrame.ZIndex = self._config.ZINDEX.Dropdown
            optionsFrame.Parent = dropdown
            
            self._utilities.CreateCorner(optionsFrame, 8)
            self._utilities.CreateStroke(optionsFrame, self._config.COLORS.Primary, 2)
            if self._utilities.CreateShadow then
                self._utilities.CreateShadow(optionsFrame, 0.3)
            end
            
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
                -- Smooth tab switching animation
                self:SwitchTab(tab.name, tabButtonsFrame, tabFrames, i)
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
    self.CurrentTab = "Pets"
end

function InventoryUI:ShowTab(tabName: string)
    if not self.TabFrames or not self.TabFrames[tabName] then
        warn("[InventoryUI] Tab not found:", tabName)
        return
    end
    
    -- Hide all tabs
    for name, frame in pairs(self.TabFrames) do
        frame.Visible = false
    end
    
    -- Show selected tab
    self.TabFrames[tabName].Visible = true
    self.CurrentTab = tabName
    
    -- Update PetGrid reference for Pets tab
    if tabName == "Pets" then
        local petsTab = self.TabFrames["Pets"]
        if petsTab then
            self.PetGrid = petsTab:FindFirstChild("PetGridScrollFrame")
        end
    end
end

function InventoryUI:SwitchTab(targetTab: string, tabButtonsFrame: Frame, tabFrames: table, buttonIndex: number)
    -- Prevent switching to same tab
    if self.CurrentTab == targetTab then return end
    
    -- Animate button states
    for j, btn in ipairs(tabButtonsFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            local isActive = j == buttonIndex
            
            -- Smooth color transition for buttons
            self._utilities.Tween(btn, {
                BackgroundColor3 = isActive and self._config.COLORS.Primary or self._config.COLORS.Surface,
                TextColor3 = isActive and self._config.COLORS.White or self._config.COLORS.Dark
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            -- Scale effect for active button
            if isActive then
                btn:TweenSize(
                    UDim2.new(0, 125, 1, 2),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Back,
                    0.2,
                    true
                )
            else
                btn:TweenSize(
                    UDim2.new(0, 120, 1, 0),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quad,
                    0.2,
                    true
                )
            end
        end
    end
    
    -- Smooth tab content transition
    local currentFrame = tabFrames[self.CurrentTab]
    local targetFrame = tabFrames[targetTab]
    
    if currentFrame and targetFrame then
        -- Fade out current tab
        self._utilities.Tween(currentFrame, {
            BackgroundTransparency = 1
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        
        -- Slide out animation
        local originalPos = currentFrame.Position
        self._utilities.Tween(currentFrame, {
            Position = UDim2.new(-0.5, 0, currentFrame.Position.Y.Scale, currentFrame.Position.Y.Offset)
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        
        task.wait(0.2)
        currentFrame.Visible = false
        currentFrame.Position = originalPos
        currentFrame.BackgroundTransparency = 0
        
        -- Prepare new tab
        targetFrame.Visible = true
        targetFrame.BackgroundTransparency = 1
        targetFrame.Position = UDim2.new(1.5, 0, targetFrame.Position.Y.Scale, targetFrame.Position.Y.Offset)
        
        -- Slide in animation
        self._utilities.Tween(targetFrame, {
            Position = UDim2.new(0, 0, targetFrame.Position.Y.Scale, targetFrame.Position.Y.Offset),
            BackgroundTransparency = 0
        }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        
        -- Play sound
        if self._soundSystem then
            self._soundSystem:PlayUISound("TabSwitch")
        end
    end
    
    self.CurrentTab = targetTab
    self.TabFrames = tabFrames
    
    -- Update PetGrid reference for Pets tab
    if targetTab == "Pets" then
        local petsTab = self.TabFrames["Pets"]
        if petsTab then
            self.PetGrid = petsTab:FindFirstChild("PetGridScrollFrame")
        end
        
        task.defer(function()
            self:RefreshInventory()
        end)
    end
end

-- ========================================
-- PET GRID
-- ========================================

function InventoryUI:CreatePetGrid(parent: Frame)
    -- Create scrolling frame with smooth scrolling
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PetGridScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -10)
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = self._config.COLORS.Primary
    scrollFrame.ScrollBarImageTransparency = 0.6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
    scrollFrame.Parent = parent
    
    self.PetGrid = scrollFrame
    
    -- Add momentum scrolling
    local lastScrollPosition = scrollFrame.CanvasPosition
    local velocity = Vector2.new(0, 0)
    local scrollConnection = nil
    local isScrolling = false
    
    -- Smooth momentum scrolling
    scrollConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if velocity.Magnitude > 0.1 and not isScrolling then
            -- Apply momentum
            local newPosition = scrollFrame.CanvasPosition + velocity * dt * 60
            
            -- Clamp to bounds with elastic effect
            local maxY = math.max(0, scrollFrame.AbsoluteCanvasSize.Y - scrollFrame.AbsoluteSize.Y)
            
            if newPosition.Y < -50 then
                newPosition = Vector2.new(newPosition.X, -50 + (newPosition.Y + 50) * 0.3)
                velocity = velocity * 0.7
            elseif newPosition.Y > maxY + 50 then
                newPosition = Vector2.new(newPosition.X, maxY + 50 - (newPosition.Y - maxY - 50) * 0.3)
                velocity = velocity * 0.7
            end
            
            scrollFrame.CanvasPosition = newPosition
            
            -- Apply damping
            velocity = velocity * 0.94
            
            -- Snap back if overscrolled
            if newPosition.Y < 0 then
                scrollFrame.CanvasPosition = Vector2.new(newPosition.X, math.max(0, newPosition.Y + 2))
            elseif newPosition.Y > maxY then
                scrollFrame.CanvasPosition = Vector2.new(newPosition.X, math.min(maxY, newPosition.Y - 2))
            end
        end
    end)
    
    -- Track scrolling for momentum
    local lastTime = tick()
    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local currentTime = tick()
        local dt = currentTime - lastTime
        
        if dt > 0 and isScrolling then
            local delta = scrollFrame.CanvasPosition - lastScrollPosition
            velocity = delta / dt * 0.5 -- Smooth velocity calculation
            lastScrollPosition = scrollFrame.CanvasPosition
        end
        
        lastTime = currentTime
    end)
    
    -- Detect when user starts/stops scrolling
    scrollFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel or 
           input.UserInputType == Enum.UserInputType.Touch then
            isScrolling = true
            velocity = Vector2.new(0, 0)
        end
    end)
    
    scrollFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel or 
           input.UserInputType == Enum.UserInputType.Touch then
            isScrolling = false
        end
    end)
    
    -- Mouse wheel scrolling with acceleration
    scrollFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local scrollSpeed = 50 * input.Position.Z
            velocity = Vector2.new(0, -scrollSpeed * 2)
        end
    end)
    
    -- Fade scrollbar on hover
    scrollFrame.MouseEnter:Connect(function()
        self._utilities.Tween(scrollFrame, {
            ScrollBarImageTransparency = 0.2
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end)
    
    scrollFrame.MouseLeave:Connect(function()
        self._utilities.Tween(scrollFrame, {
            ScrollBarImageTransparency = 0.6
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end)
    
    -- Store connection for cleanup
    self._scrollConnection = scrollConnection
    
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
    card:SetAttribute("PetName", petData.name or petData.displayName or "Unknown")
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
    
    -- Add rarity effects for high-tier pets
    local rarity = petData.rarity or 1
    
    -- Legendary (rarity 5) - Shimmer effect
    if rarity >= 5 then
        -- Create shimmer overlay
        local shimmer = Instance.new("ImageLabel")
        shimmer.Name = "ShimmerEffect"
        shimmer.Size = UDim2.new(1.5, 0, 1.5, 0)
        shimmer.Position = UDim2.new(-0.25, 0, -0.25, 0)
        shimmer.BackgroundTransparency = 1
        shimmer.Image = "rbxasset://textures/ui/LuaApp/graphic/shimmer_wide.png"
        shimmer.ImageTransparency = 0.7
        shimmer.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Gold shimmer
        shimmer.ZIndex = petImage.ZIndex + 1
        shimmer.Parent = imageContainer
        
        -- Animate shimmer
        local shimmerTween = self._utilities.Tween(shimmer, {
            Position = UDim2.new(0.75, 0, -0.25, 0)
        }, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
    end
    
    -- Mythical (rarity 6) - Particle aura
    if rarity >= 6 then
        -- Create particle container
        local particleContainer = Instance.new("Frame")
        particleContainer.Name = "ParticleAura"
        particleContainer.Size = UDim2.new(1, 20, 1, 20)
        particleContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
        particleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        particleContainer.BackgroundTransparency = 1
        particleContainer.ZIndex = petImage.ZIndex - 1
        particleContainer.Parent = imageContainer
        
        -- Spawn particles
        task.spawn(function()
            while card.Parent do
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
                particle.Position = UDim2.new(math.random(), 0, 1, 0)
                particle.BackgroundColor3 = Color3.fromRGB(200, 100, 255) -- Purple particles
                particle.BorderSizePixel = 0
                particle.Parent = particleContainer
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0.5, 0)
                corner.Parent = particle
                
                -- Float up animation
                self._utilities.Tween(particle, {
                    Position = UDim2.new(particle.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, -0.2, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 0, 0)
                }, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                
                game:GetService("Debris"):AddItem(particle, 2)
                task.wait(0.3)
            end
        end)
    end
    
    -- Secret (rarity 7+) - Rainbow gradient
    if rarity >= 7 then
        -- Create rainbow gradient overlay
        local rainbowFrame = Instance.new("Frame")
        rainbowFrame.Name = "RainbowEffect"
        rainbowFrame.Size = UDim2.new(1, 4, 1, 4)
        rainbowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        rainbowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        rainbowFrame.BackgroundTransparency = 0.8
        rainbowFrame.ZIndex = petImage.ZIndex + 2
        rainbowFrame.Parent = imageContainer
        
        local rainbowGradient = Instance.new("UIGradient")
        rainbowGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238))
        })
        rainbowGradient.Parent = rainbowFrame
        
        self._utilities.CreateCorner(rainbowFrame, 8)
        
        -- Animate rainbow rotation
        task.spawn(function()
            while card.Parent do
                self._utilities.Tween(rainbowGradient, {
                    Rotation = rainbowGradient.Rotation + 360
                }, TweenInfo.new(3, Enum.EasingStyle.Linear))
                task.wait(3)
            end
        end)
    end
    
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
        text = petInstance.nickname or petData.name or petData.displayName or "Unknown",
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
    
    -- Premium hover effects
    local originalZIndex = card.ZIndex or 1
    local glowFrame = nil
    local shadowFrame = nil
    
    -- Create shadow that will grow on hover (as child of card)
    shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.Size = UDim2.new(1, 6, 1, 6)
    shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 3)
    shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.8
    shadowFrame.ZIndex = -1  -- Behind everything in the card
    shadowFrame.Parent = card  -- Parent to card, not card.Parent!
    self._utilities.CreateCorner(shadowFrame, 10)
    
    -- Move card above shadow
    card.ZIndex = originalZIndex + 2
    
    button.MouseEnter:Connect(function()
        -- Bring to front
        card.ZIndex = originalZIndex + 10
        -- Shadow stays at ZIndex -1 relative to card
        
        -- Create glow effect
        if not glowFrame then
            glowFrame = Instance.new("Frame")
            glowFrame.Name = "GlowEffect"
            glowFrame.Size = UDim2.new(1, 12, 1, 12)
            glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            glowFrame.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
            glowFrame.BackgroundTransparency = 0.7
            glowFrame.ZIndex = card.ZIndex - 1
            glowFrame.Parent = card.Parent
            self._utilities.CreateCorner(glowFrame, 12)
        end
        
        -- Animate background color
        self._utilities.Tween(card, {
            BackgroundColor3 = self._utilities.LightenColor(self._config.COLORS.Surface, 0.15)
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Scale up with bounce
        card:TweenSize(
            UDim2.new(0, CARD_SIZE.X * 1.08, 0, CARD_SIZE.Y * 1.08),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Back,
            0.25,
            true
        )
        
        -- Animate shadow growth
        self._utilities.Tween(shadowFrame, {
            Size = UDim2.new(1, 16, 1, 16),
            Position = UDim2.new(0.5, 0, 0.5, 8),
            BackgroundTransparency = 0.6
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Animate glow
        self._utilities.Tween(glowFrame, {
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 16, 1, 16)
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Slight rotation for 3D effect
        self._utilities.Tween(card, {
            Rotation = 1
        }, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
        
        -- Sound effect
        if self._soundSystem then
            self._soundSystem:PlayUISound("Hover")
        end
    end)
    
    button.MouseLeave:Connect(function()
        -- Reset Z-index
        card.ZIndex = originalZIndex + 2
        -- Shadow stays at ZIndex -1 relative to card
        
        -- Animate background color
        self._utilities.Tween(card, {
            BackgroundColor3 = self._config.COLORS.Surface,
            Rotation = 0
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Scale back smoothly
        card:TweenSize(
            UDim2.new(0, CARD_SIZE.X, 0, CARD_SIZE.Y),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        
        -- Animate shadow shrink
        self._utilities.Tween(shadowFrame, {
            Size = UDim2.new(1, 6, 1, 6),
            Position = UDim2.new(0.5, 0, 0.5, 3),
            BackgroundTransparency = 0.8
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Fade out glow
        if glowFrame then
            self._utilities.Tween(glowFrame, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 12, 1, 12)
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end
    end)
    
    return card
end

function InventoryUI:UpdatePetCard(card: Frame, petInstance: PetInstance, petData: table)
    -- Update name
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.petId)
    
    -- Update attributes
    card:SetAttribute("PetName", petData.name or petData.displayName or "Unknown")
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
        nameLabel.Text = petInstance.nickname or petData.name or petData.displayName or "Unknown"
    end
    
    -- Update rarity border
    local border = card:FindFirstChild("RarityBorder")
    if border then
        border.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    end
    
    -- Update equipped indicator with smooth animation
    local equippedIndicator = card:FindFirstChild("EquippedIndicator")
    if petInstance.equipped and not equippedIndicator then
        -- Add equipped indicator with animation
        if self._equipAnimations then
            self._equipAnimations:UpdateEquippedIndicator(card, true, false)
        else
            -- Fallback to instant
            equippedIndicator = Instance.new("ImageLabel")
            equippedIndicator.Name = "EquippedIndicator"
            equippedIndicator.Size = UDim2.new(0, 24, 0, 24)
            equippedIndicator.Position = UDim2.new(1, -26, 0, 2)
            equippedIndicator.BackgroundTransparency = 1
            equippedIndicator.Image = "rbxassetid://7072717697"
            equippedIndicator.ImageColor3 = self._config.COLORS.Success
            equippedIndicator.Parent = card
        end
    elseif not petInstance.equipped and equippedIndicator then
        if self._equipAnimations then
            self._equipAnimations:UpdateEquippedIndicator(card, false, false)
        else
            equippedIndicator:Destroy()
        end
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
    
    -- Find PetGrid in current tab
    if not self.PetGrid or not self.PetGrid.Parent then
        -- Try to find it in the Pets tab
        local petsTab = self.TabFrames and self.TabFrames["Pets"]
        if petsTab then
            self.PetGrid = petsTab:FindFirstChild("PetGridScrollFrame")
        end
        
        if not self.PetGrid then
            warn("[InventoryUI] PetGrid not found, cannot refresh")
            self.IsRefreshing = false
            return
        end
    end
    
    -- Get grid layout
    local gridLayout = self.PetGrid:FindFirstChildOfClass("UIGridLayout")
    
    -- Clear all children from PetGrid except UIGridLayout
    for _, child in ipairs(self.PetGrid:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^PetCard_") then
            -- Remove from cache if it exists
            local cacheIndex = table.find(self.PetCardCache, child)
            if cacheIndex then
                table.remove(self.PetCardCache, cacheIndex)
            end
            child:Destroy()
        elseif child.Name == "LoadingLabel" or child.Name == "EmptyStateFrame" then
            child:Destroy()
        end
    end
    
    -- Clear the card cache since we destroyed all cards
    self.PetCardCache = {}
    
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
    -- Try multiple sources for pet data
    local pets = nil
    
    -- 1. Try data cache directly
    if self._dataCache then
        pets = self._dataCache:Get("pets")
        print("[InventoryUI] Got pets from cache:", pets)
        if not pets then
            -- Try under playerData
            local playerData = self._dataCache:Get("playerData")
            print("[InventoryUI] Got playerData from cache:", playerData)
            if playerData then
                pets = playerData.pets
                print("[InventoryUI] Got pets from playerData:", pets)
            end
        end
    end
    
    -- 2. Try state manager
    if not pets and self._stateManager then
        local playerData = self._stateManager:Get("playerData")
        if playerData then
            pets = playerData.pets
        end
    end
    
    -- Debug logging
    print("[InventoryUI] Getting pets - found:", pets and "yes" or "no", "count:", pets and table.maxn(pets) or 0)
    
    if not pets then
        return {}
    end
    
    local petsArray = {}
    
    -- Convert to array format
    if type(pets) == "table" then
        for uniqueId, petData in pairs(pets) do
            if type(petData) == "table" then
                petData.uniqueId = uniqueId
                
                -- Use pet's own data as template (server already sends complete data)
                local templateData = {
                    name = petData.name or "Unknown",
                    displayName = petData.displayName or petData.name or "Unknown",
                    rarity = petData.rarity or 1
                }
                
                -- Apply filters
                local filterFunc = FILTER_DEFINITIONS[self.CurrentFilter]
                if filterFunc and filterFunc(petData, templateData) then
                    -- Apply search filter
                    if self.SearchText == "" or self:MatchesSearch(petData, templateData) then
                        table.insert(petsArray, {pet = petData, data = templateData})
                    end
                end
            end
        end
    end
    
    -- Sort pets
    local sortFunc = SORT_FUNCTIONS[self.CurrentSort]
    if sortFunc then
        table.sort(petsArray, function(a, b)
            return sortFunc(a.pet, b.pet, a.data, b.data)
        end)
    end
    
    return petsArray
end

function InventoryUI:MatchesSearch(petInstance: PetInstance, petData: table): boolean
    local searchLower = self.SearchText:lower()
    local petName = (petInstance.nickname or petData.name or petData.displayName or ""):lower()
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
    
    if self.StatsLabels.Storage and self.StorageBars and self.StorageBars[self.StatsLabels.Storage] then
        self.StorageBars[self.StatsLabels.Storage].updateFunc(#pets)
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
    -- Create all pet cards fresh (we cleared the grid in RefreshInventory)
    for i, petInfo in ipairs(pets) do
        local card = self:CreatePetCard(self.PetGrid, petInfo.pet, petInfo.data)
        if card then
            card.LayoutOrder = i
            -- Add to cache for potential future use
            table.insert(self.PetCardCache, card)
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
    overlay.ZIndex = self._config.ZINDEX.Overlay
    overlay.Parent = self.Frame.Parent
    
    self.DeleteOverlay = overlay
    
    -- Create window
    local deleteWindow = Instance.new("Frame")
    deleteWindow.Name = "DeleteWindow"
    deleteWindow.Size = UDim2.new(0, MASS_DELETE_WINDOW_SIZE.X, 0, MASS_DELETE_WINDOW_SIZE.Y)
    deleteWindow.Position = UDim2.new(0.5, -MASS_DELETE_WINDOW_SIZE.X/2, 0.5, -MASS_DELETE_WINDOW_SIZE.Y/2)
    deleteWindow.BackgroundColor3 = self._config.COLORS.Background
    deleteWindow.ZIndex = self._config.ZINDEX.Modal
    deleteWindow.Parent = overlay
    
    self._utilities.CreateCorner(deleteWindow, 20)
    -- CreateShadow is optional, skip if not available
    if self._utilities.CreateShadow then
        self._utilities.CreateShadow(deleteWindow, 0.5)
    end
    
    -- Header
    local header = self._uiFactory:CreateFrame(deleteWindow, {
        name = "Header",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Error,
        zIndex = self._config.ZINDEX.ModalContent
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "⚠️ Mass Delete Pets",
        size = UDim2.new(1, -50, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 20,
        zIndex = self._config.ZINDEX.ModalContent
    })
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(header, {
        text = "✖",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -45, 0.5, -20),
        backgroundColor = Color3.new(1, 1, 1),
        backgroundTransparency = 0.9,
        textColor = self._config.COLORS.White,
        zIndex = self._config.ZINDEX.ModalContent,
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
    content.ZIndex = self._config.ZINDEX.ModalContent
    content.Parent = window
    
    -- Instructions
    local infoLabel = self._uiFactory:CreateLabel(content, {
        text = "Select pets to delete. This action cannot be undone!",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0),
        textColor = self._config.COLORS.Error,
        textWrapped = true,
        zIndex = self._config.ZINDEX.ModalContent
    })
    
    -- Quick select buttons
    local quickSelectFrame = Instance.new("Frame")
    quickSelectFrame.Size = UDim2.new(1, 0, 0, 40)
    quickSelectFrame.Position = UDim2.new(0, 0, 0, 50)
    quickSelectFrame.BackgroundTransparency = 1
    quickSelectFrame.ZIndex = self._config.ZINDEX.ModalContent
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
    bottomBar.ZIndex = self._config.ZINDEX.ModalContent
    bottomBar.Parent = window
    
    self._utilities.CreateCorner(bottomBar, 20)
    
    -- Selected count
    local selectedLabel = self._uiFactory:CreateLabel(bottomBar, {
        text = "Selected: 0 pets",
        size = UDim2.new(0, 200, 1, 0),
        position = UDim2.new(0, 20, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        zIndex = self._config.ZINDEX.ModalContent
    })
    self.DeleteSelectedLabel = selectedLabel
    
    -- Delete button
    local deleteButton = self._uiFactory:CreateButton(bottomBar, {
        text = "Delete Selected",
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(1, -170, 0.5, -20),
        backgroundColor = self._config.COLORS.Error,
        zIndex = self._config.ZINDEX.ModalContent,
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
        -- Use pet's own data
        local aData = {
            name = a.name or "Unknown",
            rarity = a.rarity or 1
        }
        local bData = {
            name = b.name or "Unknown",
            rarity = b.rarity or 1
        }
        return (aData.rarity or 1) < (bData.rarity or 1)
    end)
    
    -- Create selection cards
    for _, pet in ipairs(pets) do
        -- Use pet's own data
        local petData = {
            name = pet.name or "Unknown",
            displayName = pet.displayName or pet.name or "Unknown",
            rarity = pet.rarity or 1
        }
        
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
        text = petInstance.nickname or petData.name or petData.displayName or "Unknown",
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
                -- Use pet's own data
                local petData = {
                    name = pet.name or "Unknown",
                    rarity = pet.rarity or 1
                }
                
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
    
    -- Create simple confirmation dialog
    local overlay = Instance.new("Frame")
    overlay.Name = "ConfirmOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = self._config.ZINDEX.Overlay
    overlay.Parent = self.ScreenGui
    
    local dialog = Instance.new("Frame")
    dialog.Name = "ConfirmDialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = self._config.COLORS.Background
    dialog.ZIndex = self._config.ZINDEX.Modal
    dialog.Parent = overlay
    
    self._utilities.CreateCorner(dialog, 12)
    
    -- Title
    local title = self._uiFactory:CreateLabel(dialog, {
        text = "Confirm Mass Delete",
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0, 10),
        font = self._config.FONTS.Bold,
        textSize = 20
    })
    
    -- Message
    local message = self._uiFactory:CreateLabel(dialog, {
        text = confirmText,
        size = UDim2.new(1, -20, 0, 60),
        position = UDim2.new(0, 10, 0, 50),
        font = self._config.FONTS.Primary,
        textSize = 16,
        textWrapped = true
    })
    
    -- Buttons
    local confirmButton = self._uiFactory:CreateButton(dialog, {
        text = "Delete " .. count .. " Pets",
        size = UDim2.new(0.5, -15, 0, 40),
        position = UDim2.new(0, 10, 1, -50),
        backgroundColor = self._config.COLORS.Error,
        callback = function()
            overlay:Destroy()
            self:ExecuteMassDelete(petIds)
        end
    })
    
    local cancelButton = self._uiFactory:CreateButton(dialog, {
        text = "Cancel",
        size = UDim2.new(0.5, -15, 0, 40),
        position = UDim2.new(0.5, 5, 1, -50),
        callback = function()
            overlay:Destroy()
        end
    })
end

function InventoryUI:AnimateCardDeletion(card: Frame, callback: () -> ())
    -- Create particle burst effect
    local particleContainer = Instance.new("Frame")
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.Position = UDim2.new(0, 0, 0, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ZIndex = card.ZIndex + 10
    particleContainer.Parent = card.Parent
    
    -- Get card center position
    local centerX = card.AbsolutePosition.X + card.AbsoluteSize.X / 2
    local centerY = card.AbsolutePosition.Y + card.AbsoluteSize.Y / 2
    
    -- Create particles
    for i = 1, 15 do
        task.spawn(function()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
            particle.Position = UDim2.new(0, centerX - particleContainer.AbsolutePosition.X, 
                                         0, centerY - particleContainer.AbsolutePosition.Y)
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.BackgroundColor3 = self._config.COLORS.Error
            particle.BorderSizePixel = 0
            particle.Parent = particleContainer
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
            
            -- Random direction and speed
            local angle = math.random() * math.pi * 2
            local speed = math.random(50, 100)
            local targetX = particle.Position.X.Offset + math.cos(angle) * speed
            local targetY = particle.Position.Y.Offset + math.sin(angle) * speed
            
            -- Animate particle
            self._utilities.Tween(particle, {
                Position = UDim2.new(0, targetX, 0, targetY),
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Rotation = math.random(180, 360)
            }, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end)
    end
    
    -- Cleanup particles after animation
    game:GetService("Debris"):AddItem(particleContainer, 1)
    
    -- Animate card shrinking and fading
    self._utilities.Tween(card, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Rotation = math.random(-15, 15)
    }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In))
    
    -- Fade out all children
    for _, child in ipairs(card:GetDescendants()) do
        if child:IsA("GuiObject") then
            if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                self._utilities.Tween(child, {
                    ImageTransparency = 1
                }, TweenInfo.new(0.3))
            elseif child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                self._utilities.Tween(child, {
                    TextTransparency = 1
                }, TweenInfo.new(0.3))
            end
            if child.BackgroundTransparency < 1 then
                self._utilities.Tween(child, {
                    BackgroundTransparency = 1
                }, TweenInfo.new(0.3))
            end
        end
    end
    
    -- Sound effect
    if self._soundSystem then
        self._soundSystem:PlayUISound("Delete")
    end
    
    -- Wait for animation then callback
    task.wait(0.4)
    if callback then
        callback()
    end
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
            zIndex = self._config.ZINDEX.ModalContent
        })
        
        self._utilities.CreateCorner(loadingLabel, 8)
    end
    
    -- Send delete request
    if self._remoteManager then
        local result = self._remoteManager:InvokeServer("MassDeletePets", petIds)
        
        if result and result.success then
            -- Animate deletion of cards
            local cardsToDelete = {}
            
            -- Find all cards to delete
            if self.PetGrid then
                for _, card in ipairs(self.PetGrid:GetChildren()) do
                    if card:IsA("Frame") and card.Name:match("PetCard_") then
                        local petId = card.Name:gsub("PetCard_", "")
                        if table.find(petIds, petId) then
                            table.insert(cardsToDelete, card)
                        end
                    end
                end
            end
            
            -- Animate each card deletion with staggered timing
            for i, card in ipairs(cardsToDelete) do
                task.spawn(function()
                    task.wait((i - 1) * 0.05) -- Stagger animations
                    self:AnimateCardDeletion(card, function()
                        card:Destroy()
                    end)
                end)
            end
            
            -- Wait for animations to complete
            task.wait(0.5 + #cardsToDelete * 0.05)
            
            if self._notificationSystem then
                self._notificationSystem:Show({
                    title = "Success",
                    message = string.format("Successfully deleted %d pets!", #petIds),
                    type = "success",
                    duration = 3
                })
            end
            
            -- Play sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("Success")
            end
            
            -- Close mass delete window
            self:CloseMassDelete()
            
            -- Refresh inventory with remaining pets
            self:RefreshInventory()
        else
            if self._notificationSystem then
                self._notificationSystem:Show({
                    title = "Error",
                    message = result or "Failed to delete pets",
                    type = "error",
                    duration = 3
                })
            end
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