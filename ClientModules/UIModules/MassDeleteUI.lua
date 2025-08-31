--[[
    Module: MassDeleteUI
    Description: Advanced mass pet deletion system with three-stage workflow
    Features:
        - Selection stage with advanced filtering and smart selection
        - Review stage showing selected pets with warnings
        - Confirmation stage with type-to-confirm for safety
        - Virtual scrolling for performance
        - Batch deletion with atomic server transactions
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)

local MassDeleteUI = {}
MassDeleteUI.__index = MassDeleteUI

-- ========================================
-- CONSTANTS
-- ========================================

local STAGES = {
    SELECTION = "Selection",
    REVIEW = "Review",
    CONFIRMATION = "Confirmation"
}

local RARITIES = {
    "Common",
    "Uncommon", 
    "Rare",
    "Epic",
    "Legendary",
    "Mythic"
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(200, 200, 200),
    Uncommon = Color3.fromRGB(100, 200, 100),
    Rare = Color3.fromRGB(100, 150, 255),
    Epic = Color3.fromRGB(200, 100, 255),
    Legendary = Color3.fromRGB(255, 200, 50),
    Mythic = Color3.fromRGB(255, 100, 100)
}

local CARDS_PER_ROW = 5
local CARD_SIZE = UDim2.new(0, 120, 0, 150)
local CARD_PADDING = UDim.new(0, 10)
local VIRTUAL_SCROLL_BUFFER = 2 -- Extra rows to render off-screen

-- ========================================
-- INITIALIZATION
-- ========================================

function MassDeleteUI.new(client)
    local self = setmetatable({}, MassDeleteUI)
    
    -- Core references
    self._client = client
    self._player = Services.Players.LocalPlayer
    self._replicatedStorage = Services.ReplicatedStorage
    self._playerGui = self._player:WaitForChild("PlayerGui")
    self._runService = Services.RunService
    self._tweenService = Services.TweenService
    
    -- Dependencies
    self._remoteManager = client.RemoteManager
    self._eventBus = client.EventBus
    self._dataCache = client.DataCache
    self._soundSystem = client.SoundSystem
    self._notificationSystem = client.NotificationSystem
    self._animationSystem = client.AnimationSystem
    self._utilities = client.Utilities
    self._petDatabase = client.PetDatabase
    self._uiFactory = client.UIFactory
    self._windowManager = client.WindowManager
    
    -- State
    self._currentStage = STAGES.SELECTION
    self._selectedPets = {} -- [uniqueId] = petData
    self._filters = {
        rarities = {},
        levelMin = 1,
        levelMax = 999,
        duplicatesOnly = false
    }
    self._virtualScrollData = {
        visiblePets = {},
        cardPool = {},
        scrollPosition = 0,
        totalHeight = 0
    }
    
    -- UI References
    self._window = nil
    self._stageFrames = {}
    self._selectionGrid = nil
    self._reviewGrid = nil
    self._resourceDisplay = nil
    
    -- Janitor for cleanup
    self._janitor = client.Janitor.new()
    
    self:Initialize()
    
    return self
end

function MassDeleteUI:Initialize()
    -- Create the main window
    self:CreateWindow()
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    -- Hide window initially
    if self._window then
        self._window.Visible = false
    end
end

-- ========================================
-- WINDOW CREATION
-- ========================================

function MassDeleteUI:CreateWindow()
    -- Create main window using UIFactory
    self._window = self._uiFactory:CreateWindow({
        Name = "MassDeleteWindow",
        Title = "Mass Delete Pets",
        Size = UDim2.new(0, 900, 0, 700),
        MinSize = Vector2.new(800, 600),
        Resizable = true,
        ShowCloseButton = true,
        OnClose = function()
            self:Close()
        end
    })
    
    if not self._window then
        warn("[MassDeleteUI] Failed to create window")
        return
    end
    
    -- Create stage frames
    self:CreateSelectionStage()
    self:CreateReviewStage()
    self:CreateConfirmationStage()
    
    -- Show initial stage
    self:ShowStage(STAGES.SELECTION)
end

function MassDeleteUI:CreateSelectionStage()
    local frame = self._uiFactory:CreateFrame({
        Name = "SelectionStage",
        Parent = self._window.Content,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    })
    
    self._stageFrames[STAGES.SELECTION] = frame
    
    -- Top section: Filters
    local filterSection = self:CreateFilterSection(frame)
    
    -- Middle section: Smart selection buttons
    local smartButtons = self:CreateSmartSelectionButtons(frame)
    
    -- Main section: Pet grid with virtual scrolling
    local gridContainer = self:CreateVirtualScrollGrid(frame)
    
    -- Bottom section: Selected count and next button
    local bottomBar = self:CreateSelectionBottomBar(frame)
end

function MassDeleteUI:CreateFilterSection(parent)
    local filterFrame = self._uiFactory:CreateFrame({
        Name = "FilterSection",
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 120),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Config.COLORS.Surface,
        BorderSizePixel = 0
    })
    
    -- Title
    local title = self._uiFactory:CreateText({
        Name = "FilterTitle",
        Parent = filterFrame,
        Text = "Filters",
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0, 10, 0, 5),
        Font = Config.FONTS.Display,
        TextSize = 18,
        TextColor3 = Config.COLORS.Text
    })
    
    -- Rarity checkboxes
    local rarityLabel = self._uiFactory:CreateText({
        Name = "RarityLabel",
        Parent = filterFrame,
        Text = "Rarity:",
        Size = UDim2.new(0, 60, 0, 30),
        Position = UDim2.new(0, 10, 0, 35),
        TextSize = 14,
        TextColor3 = Config.COLORS.TextSecondary
    })
    
    for i, rarity in ipairs(RARITIES) do
        local checkbox = self._uiFactory:CreateCheckbox({
            Name = rarity .. "Checkbox",
            Parent = filterFrame,
            Position = UDim2.new(0, 70 + (i-1) * 100, 0, 35),
            Size = UDim2.new(0, 90, 0, 30),
            Text = rarity,
            TextColor3 = RARITY_COLORS[rarity],
            OnToggle = function(checked)
                self._filters.rarities[rarity] = checked
                self:RefreshGrid()
            end
        })
    end
    
    -- Level range
    local levelLabel = self._uiFactory:CreateText({
        Name = "LevelLabel",
        Parent = filterFrame,
        Text = "Level Range:",
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0, 10, 0, 70),
        TextSize = 14,
        TextColor3 = Config.COLORS.TextSecondary
    })
    
    local minLevelInput = self._uiFactory:CreateTextInput({
        Name = "MinLevelInput",
        Parent = filterFrame,
        Position = UDim2.new(0, 110, 0, 70),
        Size = UDim2.new(0, 60, 0, 30),
        PlaceholderText = "Min",
        Text = "1",
        OnTextChanged = function(text)
            local num = tonumber(text) or 1
            self._filters.levelMin = math.max(1, num)
            self:RefreshGrid()
        end
    })
    
    local levelDash = self._uiFactory:CreateText({
        Name = "LevelDash",
        Parent = filterFrame,
        Text = "-",
        Size = UDim2.new(0, 20, 0, 30),
        Position = UDim2.new(0, 175, 0, 70),
        TextSize = 14,
        TextColor3 = Config.COLORS.TextSecondary
    })
    
    local maxLevelInput = self._uiFactory:CreateTextInput({
        Name = "MaxLevelInput",
        Parent = filterFrame,
        Position = UDim2.new(0, 200, 0, 70),
        Size = UDim2.new(0, 60, 0, 30),
        PlaceholderText = "Max",
        Text = "999",
        OnTextChanged = function(text)
            local num = tonumber(text) or 999
            self._filters.levelMax = math.max(1, num)
            self:RefreshGrid()
        end
    })
    
    -- Duplicates toggle
    local duplicatesToggle = self._uiFactory:CreateCheckbox({
        Name = "DuplicatesToggle",
        Parent = filterFrame,
        Position = UDim2.new(0, 300, 0, 70),
        Size = UDim2.new(0, 150, 0, 30),
        Text = "Duplicates Only",
        OnToggle = function(checked)
            self._filters.duplicatesOnly = checked
            self:RefreshGrid()
        end
    })
    
    return filterFrame
end

function MassDeleteUI:CreateSmartSelectionButtons(parent)
    local buttonFrame = self._uiFactory:CreateFrame({
        Name = "SmartButtons",
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 125),
        BackgroundTransparency = 1
    })
    
    -- Select Duplicates (Keep Best)
    local selectDuplicatesBtn = self._uiFactory:CreateButton({
        Name = "SelectDuplicates",
        Parent = buttonFrame,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(0, 200, 0, 40),
        Text = "Select Duplicates (Keep Best)",
        BackgroundColor3 = Config.COLORS.Primary,
        OnClick = function()
            self:SelectDuplicatesKeepBest()
        end
    })
    
    -- Select All Below Rarity
    local rarityDropdown = self._uiFactory:CreateDropdown({
        Name = "RarityDropdown",
        Parent = buttonFrame,
        Position = UDim2.new(0, 220, 0, 5),
        Size = UDim2.new(0, 180, 0, 40),
        PlaceholderText = "Select Below Rarity",
        Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary"},
        OnSelect = function(rarity)
            self:SelectAllBelowRarity(rarity)
        end
    })
    
    -- Invert Selection
    local invertBtn = self._uiFactory:CreateButton({
        Name = "InvertSelection",
        Parent = buttonFrame,
        Position = UDim2.new(0, 410, 0, 5),
        Size = UDim2.new(0, 140, 0, 40),
        Text = "Invert Selection",
        BackgroundColor3 = Config.COLORS.Secondary,
        OnClick = function()
            self:InvertSelection()
        end
    })
    
    -- Clear Selection
    local clearBtn = self._uiFactory:CreateButton({
        Name = "ClearSelection",
        Parent = buttonFrame,
        Position = UDim2.new(0, 560, 0, 5),
        Size = UDim2.new(0, 140, 0, 40),
        Text = "Clear Selection",
        BackgroundColor3 = Config.COLORS.Error,
        OnClick = function()
            self:ClearSelection()
        end
    })
    
    return buttonFrame
end

function MassDeleteUI:CreateVirtualScrollGrid(parent)
    local scrollFrame = self._uiFactory:CreateScrollingFrame({
        Name = "PetGrid",
        Parent = parent,
        Position = UDim2.new(0, 10, 0, 180),
        Size = UDim2.new(1, -20, 1, -240),
        ScrollBarThickness = 8,
        CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
    })
    
    self._selectionGrid = scrollFrame
    
    -- Set up virtual scrolling
    self:SetupVirtualScrolling(scrollFrame)
    
    return scrollFrame
end

function MassDeleteUI:CreateSelectionBottomBar(parent)
    local bottomBar = self._uiFactory:CreateFrame({
        Name = "BottomBar",
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 1, -50),
        BackgroundColor3 = Config.COLORS.Surface,
        BorderSizePixel = 0
    })
    
    -- Selected count
    self._selectedCountLabel = self._uiFactory:CreateText({
        Name = "SelectedCount",
        Parent = bottomBar,
        Text = "0 pets selected",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        TextSize = 16,
        TextColor3 = Config.COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Next button
    local nextBtn = self._uiFactory:CreateButton({
        Name = "NextButton",
        Parent = bottomBar,
        Position = UDim2.new(1, -170, 0.5, -20),
        Size = UDim2.new(0, 150, 0, 40),
        Text = "Review Selection",
        BackgroundColor3 = Config.COLORS.Success,
        OnClick = function()
            if next(self._selectedPets) then
                self:ShowStage(STAGES.REVIEW)
            else
                self._notificationSystem:Show({
                    title = "No Selection",
                    message = "Please select at least one pet to delete.",
                    type = "warning"
                })
            end
        end
    })
    
    return bottomBar
end

-- ========================================
-- REVIEW STAGE
-- ========================================

function MassDeleteUI:CreateReviewStage()
    local frame = self._uiFactory:CreateFrame({
        Name = "ReviewStage",
        Parent = self._window.Content,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false
    })
    
    self._stageFrames[STAGES.REVIEW] = frame
    
    -- Top section: Summary and warnings
    local summarySection = self:CreateSummarySection(frame)
    
    -- Main section: Grid of selected pets
    local reviewGrid = self:CreateReviewGrid(frame)
    
    -- Bottom section: Back and Delete buttons
    local bottomBar = self:CreateReviewBottomBar(frame)
end

function MassDeleteUI:CreateSummarySection(parent)
    local summaryFrame = self._uiFactory:CreateFrame({
        Name = "SummarySection",
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 150),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Config.COLORS.Surface,
        BorderSizePixel = 0
    })
    
    -- Main summary text
    self._summaryText = self._uiFactory:CreateText({
        Name = "SummaryText",
        Parent = summaryFrame,
        Text = "You are about to permanently delete 0 pets.",
        Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 20, 0, 10),
        Font = Config.FONTS.Display,
        TextSize = 24,
        TextColor3 = Config.COLORS.Text
    })
    
    -- Resource display
    self._resourceDisplay = self._uiFactory:CreateFrame({
        Name = "ResourceDisplay",
        Parent = summaryFrame,
        Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 20, 0, 50),
        BackgroundTransparency = 1
    })
    
    self._coinsLabel = self._uiFactory:CreateText({
        Name = "CoinsLabel",
        Parent = self._resourceDisplay,
        Text = "You will receive: 0 Coins",
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        TextSize = 18,
        TextColor3 = Config.COLORS.Success,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    self._dustLabel = self._uiFactory:CreateText({
        Name = "DustLabel",
        Parent = self._resourceDisplay,
        Text = "0 Pet Dust",
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        TextSize = 18,
        TextColor3 = Config.COLORS.Secondary,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- High value warning
    self._warningLabel = self._uiFactory:CreateText({
        Name = "WarningLabel",
        Parent = summaryFrame,
        Text = "⚠️ WARNING! Your selection includes high-value pets!",
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.new(0, 20, 0, 100),
        TextSize = 16,
        TextColor3 = Config.COLORS.Error,
        Visible = false
    })
    
    return summaryFrame
end

function MassDeleteUI:CreateReviewGrid(parent)
    local scrollFrame = self._uiFactory:CreateScrollingFrame({
        Name = "ReviewGrid",
        Parent = parent,
        Position = UDim2.new(0, 10, 0, 160),
        Size = UDim2.new(1, -20, 1, -220),
        ScrollBarThickness = 8,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    
    self._reviewGrid = scrollFrame
    
    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = CARD_SIZE
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    return scrollFrame
end

function MassDeleteUI:CreateReviewBottomBar(parent)
    local bottomBar = self._uiFactory:CreateFrame({
        Name = "BottomBar",
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 1, -50),
        BackgroundColor3 = Config.COLORS.Surface,
        BorderSizePixel = 0
    })
    
    -- Back button
    local backBtn = self._uiFactory:CreateButton({
        Name = "BackButton",
        Parent = bottomBar,
        Position = UDim2.new(0, 20, 0.5, -20),
        Size = UDim2.new(0, 120, 0, 40),
        Text = "Back",
        BackgroundColor3 = Config.COLORS.Secondary,
        OnClick = function()
            self:ShowStage(STAGES.SELECTION)
        end
    })
    
    -- Delete button
    local deleteBtn = self._uiFactory:CreateButton({
        Name = "DeleteButton",
        Parent = bottomBar,
        Position = UDim2.new(1, -170, 0.5, -20),
        Size = UDim2.new(0, 150, 0, 40),
        Text = "Confirm Delete",
        BackgroundColor3 = Config.COLORS.Error,
        OnClick = function()
            self:ShowStage(STAGES.CONFIRMATION)
        end
    })
    
    return bottomBar
end

-- ========================================
-- CONFIRMATION STAGE
-- ========================================

function MassDeleteUI:CreateConfirmationStage()
    local frame = self._uiFactory:CreateFrame({
        Name = "ConfirmationStage",
        Parent = self._window.Content,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false
    })
    
    self._stageFrames[STAGES.CONFIRMATION] = frame
    
    -- Center content
    local centerFrame = self._uiFactory:CreateFrame({
        Name = "CenterContent",
        Parent = frame,
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundColor3 = Config.COLORS.Surface
    })
    
    -- Final warning
    local warningText = self._uiFactory:CreateText({
        Name = "FinalWarning",
        Parent = centerFrame,
        Text = "FINAL CONFIRMATION",
        Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 20, 0, 20),
        Font = Config.FONTS.Display,
        TextSize = 28,
        TextColor3 = Config.COLORS.Error
    })
    
    self._confirmSummaryText = self._uiFactory:CreateText({
        Name = "ConfirmSummary",
        Parent = centerFrame,
        Text = "This action cannot be undone!",
        Size = UDim2.new(1, -40, 0, 60),
        Position = UDim2.new(0, 20, 0, 70),
        TextSize = 16,
        TextColor3 = Config.COLORS.Text,
        TextWrapped = true
    })
    
    -- Type to confirm (conditional)
    self._typeToConfirmFrame = self._uiFactory:CreateFrame({
        Name = "TypeToConfirm",
        Parent = centerFrame,
        Size = UDim2.new(1, -40, 0, 80),
        Position = UDim2.new(0, 20, 0, 140),
        BackgroundTransparency = 1,
        Visible = false
    })
    
    local typeLabel = self._uiFactory:CreateText({
        Name = "TypeLabel",
        Parent = self._typeToConfirmFrame,
        Text = "Type 'DELETE' to confirm:",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        TextSize = 14,
        TextColor3 = Config.COLORS.TextSecondary
    })
    
    self._confirmInput = self._uiFactory:CreateTextInput({
        Name = "ConfirmInput",
        Parent = self._typeToConfirmFrame,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 0, 35),
        PlaceholderText = "Type DELETE here",
        OnTextChanged = function(text)
            self:UpdateConfirmButton()
        end
    })
    
    -- Buttons
    local cancelBtn = self._uiFactory:CreateButton({
        Name = "CancelButton",
        Parent = centerFrame,
        Position = UDim2.new(0, 20, 1, -60),
        Size = UDim2.new(0.5, -30, 0, 40),
        Text = "Cancel",
        BackgroundColor3 = Config.COLORS.Secondary,
        OnClick = function()
            self:ShowStage(STAGES.REVIEW)
        end
    })
    
    self._finalDeleteBtn = self._uiFactory:CreateButton({
        Name = "FinalDeleteButton",
        Parent = centerFrame,
        Position = UDim2.new(0.5, 10, 1, -60),
        Size = UDim2.new(0.5, -30, 0, 40),
        Text = "DELETE",
        BackgroundColor3 = Config.COLORS.Error,
        Enabled = false,
        OnClick = function()
            self:ExecuteDeletion()
        end
    })
    
    return frame
end

-- ========================================
-- STAGE MANAGEMENT
-- ========================================

function MassDeleteUI:ShowStage(stage)
    -- Hide all stages
    for _, frame in pairs(self._stageFrames) do
        frame.Visible = false
    end
    
    -- Show selected stage
    if self._stageFrames[stage] then
        self._stageFrames[stage].Visible = true
        self._currentStage = stage
        
        -- Stage-specific setup
        if stage == STAGES.SELECTION then
            self:RefreshGrid()
        elseif stage == STAGES.REVIEW then
            self:PopulateReviewStage()
        elseif stage == STAGES.CONFIRMATION then
            self:PrepareConfirmationStage()
        end
    end
end

-- ========================================
-- SELECTION LOGIC
-- ========================================

function MassDeleteUI:SelectDuplicatesKeepBest()
    local pets = self:GetFilteredPets()
    local petsByType = {}
    
    -- Group pets by type
    for _, pet in pairs(pets) do
        local petType = pet.petId
        if not petsByType[petType] then
            petsByType[petType] = {}
        end
        table.insert(petsByType[petType], pet)
    end
    
    -- Select duplicates, keeping the best (highest level) of each type
    for petType, typePets in pairs(petsByType) do
        if #typePets > 1 then
            -- Sort by level (descending)
            table.sort(typePets, function(a, b)
                return (a.level or 1) > (b.level or 1)
            end)
            
            -- Select all except the first (best)
            for i = 2, #typePets do
                self._selectedPets[typePets[i].uniqueId] = typePets[i]
            end
        end
    end
    
    self:RefreshGrid()
    self:UpdateSelectedCount()
end

function MassDeleteUI:SelectAllBelowRarity(targetRarity)
    local rarityOrder = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Epic = 4,
        Legendary = 5,
        Mythic = 6
    }
    
    local targetOrder = rarityOrder[targetRarity] or 0
    local pets = self:GetFilteredPets()
    
    for _, pet in pairs(pets) do
        local petRarity = pet.rarity or "Common"
        local petOrder = rarityOrder[petRarity] or 1
        
        if petOrder <= targetOrder then
            self._selectedPets[pet.uniqueId] = pet
        end
    end
    
    self:RefreshGrid()
    self:UpdateSelectedCount()
end

function MassDeleteUI:InvertSelection()
    local pets = self:GetFilteredPets()
    local newSelection = {}
    
    for _, pet in pairs(pets) do
        if not self._selectedPets[pet.uniqueId] then
            newSelection[pet.uniqueId] = pet
        end
    end
    
    self._selectedPets = newSelection
    self:RefreshGrid()
    self:UpdateSelectedCount()
end

function MassDeleteUI:ClearSelection()
    self._selectedPets = {}
    self:RefreshGrid()
    self:UpdateSelectedCount()
end

-- ========================================
-- VIRTUAL SCROLLING
-- ========================================

function MassDeleteUI:SetupVirtualScrolling(scrollFrame)
    local viewportSize = scrollFrame.AbsoluteSize
    local cardsPerRow = math.floor((viewportSize.X - 20) / (CARD_SIZE.X.Offset + CARD_PADDING.Offset))
    local visibleRows = math.ceil(viewportSize.Y / (CARD_SIZE.Y.Offset + CARD_PADDING.Offset)) + VIRTUAL_SCROLL_BUFFER
    
    -- Create card pool
    for i = 1, cardsPerRow * visibleRows do
        local card = self:CreatePetCard()
        card.Parent = scrollFrame
        card.Visible = false
        table.insert(self._virtualScrollData.cardPool, card)
    end
    
    -- Update on scroll
    self._janitor:Add(scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self:UpdateVirtualScroll()
    end))
    
    -- Update on resize
    self._janitor:Add(scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:RefreshGrid()
    end))
end

function MassDeleteUI:UpdateVirtualScroll()
    if not self._selectionGrid then return end
    
    local scrollY = self._selectionGrid.CanvasPosition.Y
    local viewportHeight = self._selectionGrid.AbsoluteSize.Y
    local cardHeight = CARD_SIZE.Y.Offset + CARD_PADDING.Offset
    local cardsPerRow = math.floor((self._selectionGrid.AbsoluteSize.X - 20) / (CARD_SIZE.X.Offset + CARD_PADDING.Offset))
    
    local startRow = math.floor(scrollY / cardHeight)
    local endRow = math.ceil((scrollY + viewportHeight) / cardHeight) + VIRTUAL_SCROLL_BUFFER
    
    local visiblePets = self._virtualScrollData.visiblePets
    local cardIndex = 1
    
    -- Hide all cards first
    for _, card in ipairs(self._virtualScrollData.cardPool) do
        card.Visible = false
    end
    
    -- Show and update visible cards
    for row = startRow, endRow do
        for col = 1, cardsPerRow do
            local petIndex = row * cardsPerRow + col
            if petIndex <= #visiblePets then
                local pet = visiblePets[petIndex]
                local card = self._virtualScrollData.cardPool[cardIndex]
                
                if card then
                    self:UpdatePetCard(card, pet)
                    card.Position = UDim2.new(
                        0, 10 + (col - 1) * (CARD_SIZE.X.Offset + CARD_PADDING.Offset),
                        0, 10 + row * cardHeight
                    )
                    card.Visible = true
                    cardIndex = cardIndex + 1
                end
            end
        end
    end
end

-- ========================================
-- PET CARD CREATION
-- ========================================

function MassDeleteUI:CreatePetCard()
    local card = self._uiFactory:CreateFrame({
        Name = "PetCard",
        Size = CARD_SIZE,
        BackgroundColor3 = Config.COLORS.Card,
        BorderSizePixel = 0
    })
    
    -- Selection overlay
    local selectionOverlay = self._uiFactory:CreateFrame({
        Name = "SelectionOverlay",
        Parent = card,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Config.COLORS.Error,
        BackgroundTransparency = 0.7,
        Visible = false,
        ZIndex = 2
    })
    
    -- Trash icon
    local trashIcon = self._uiFactory:CreateImage({
        Name = "TrashIcon",
        Parent = selectionOverlay,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0.5, -25, 0.5, -25),
        Image = "rbxassetid://3926305904", -- Trash icon
        ImageRectOffset = Vector2.new(364, 364),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Config.COLORS.White,
        BackgroundTransparency = 1,
        ZIndex = 3
    })
    
    -- Pet image
    local petImage = self._uiFactory:CreateImage({
        Name = "PetImage",
        Parent = card,
        Size = UDim2.new(1, -20, 1, -40),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Config.COLORS.Surface,
        BackgroundTransparency = 0.9
    })
    
    -- Info bar
    local infoBar = self._uiFactory:CreateFrame({
        Name = "InfoBar",
        Parent = card,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundColor3 = Config.COLORS.Surface,
        BackgroundTransparency = 0.3
    })
    
    -- Pet name
    local nameLabel = self._uiFactory:CreateText({
        Name = "NameLabel",
        Parent = infoBar,
        Size = UDim2.new(0.7, -5, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        TextSize = 12,
        TextColor3 = Config.COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    -- Level
    local levelLabel = self._uiFactory:CreateText({
        Name = "LevelLabel",
        Parent = infoBar,
        Size = UDim2.new(0.3, -5, 1, 0),
        Position = UDim2.new(0.7, 0, 0, 0),
        TextSize = 12,
        TextColor3 = Config.COLORS.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Parent = card
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 4
    
    return card
end

function MassDeleteUI:UpdatePetCard(card, pet)
    local petData = self._petDatabase:GetPetData(pet.petId)
    if not petData then return end
    
    -- Update image
    local petImage = card:FindFirstChild("PetImage")
    if petImage then
        petImage.Image = petData.image or ""
        
        -- Apply greyscale if selected
        if self._selectedPets[pet.uniqueId] then
            petImage.ImageColor3 = Color3.new(0.5, 0.5, 0.5)
        else
            petImage.ImageColor3 = Color3.new(1, 1, 1)
        end
    end
    
    -- Update selection overlay
    local selectionOverlay = card:FindFirstChild("SelectionOverlay")
    if selectionOverlay then
        selectionOverlay.Visible = self._selectedPets[pet.uniqueId] ~= nil
    end
    
    -- Update name
    local nameLabel = card:FindFirstChild("InfoBar"):FindFirstChild("NameLabel")
    if nameLabel then
        nameLabel.Text = petData.name or "Unknown"
        nameLabel.TextColor3 = RARITY_COLORS[pet.rarity] or Config.COLORS.Text
    end
    
    -- Update level
    local levelLabel = card:FindFirstChild("InfoBar"):FindFirstChild("LevelLabel")
    if levelLabel then
        levelLabel.Text = "Lv. " .. (pet.level or 1)
    end
    
    -- Update click handler
    local button = card:FindFirstChildOfClass("TextButton")
    if button then
        if button.MouseButton1Click then
            self._janitor:Remove(button.MouseButton1Click)
        end
        
        self._janitor:Add(button.MouseButton1Click:Connect(function()
            self:TogglePetSelection(pet)
        end))
    end
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function MassDeleteUI:GetFilteredPets()
    local playerData = self._dataCache:Get("playerData")
    if not playerData or not playerData.pets then
        return {}
    end
    
    local filtered = {}
    local petsByType = {}
    
    -- First pass: collect all pets and group by type
    for _, pet in pairs(playerData.pets) do
        -- Skip equipped pets
        if not pet.equipped then
            local petType = pet.petId
            if not petsByType[petType] then
                petsByType[petType] = {}
            end
            table.insert(petsByType[petType], pet)
        end
    end
    
    -- Second pass: apply filters
    for _, pet in pairs(playerData.pets) do
        if not pet.equipped then
            local include = true
            
            -- Rarity filter
            if next(self._filters.rarities) then
                local petRarity = pet.rarity or "Common"
                if not self._filters.rarities[petRarity] then
                    include = false
                end
            end
            
            -- Level filter
            local level = pet.level or 1
            if level < self._filters.levelMin or level > self._filters.levelMax then
                include = false
            end
            
            -- Duplicates filter
            if self._filters.duplicatesOnly then
                local petType = pet.petId
                if not petsByType[petType] or #petsByType[petType] <= 1 then
                    include = false
                end
            end
            
            if include then
                table.insert(filtered, pet)
            end
        end
    end
    
    return filtered
end

function MassDeleteUI:RefreshGrid()
    local pets = self:GetFilteredPets()
    self._virtualScrollData.visiblePets = pets
    
    -- Update canvas size
    local cardsPerRow = math.floor((self._selectionGrid.AbsoluteSize.X - 20) / (CARD_SIZE.X.Offset + CARD_PADDING.Offset))
    local totalRows = math.ceil(#pets / cardsPerRow)
    local canvasHeight = totalRows * (CARD_SIZE.Y.Offset + CARD_PADDING.Offset) + 20
    
    self._selectionGrid.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
    self._virtualScrollData.totalHeight = canvasHeight
    
    -- Update visible cards
    self:UpdateVirtualScroll()
end

function MassDeleteUI:TogglePetSelection(pet)
    if self._selectedPets[pet.uniqueId] then
        self._selectedPets[pet.uniqueId] = nil
    else
        self._selectedPets[pet.uniqueId] = pet
    end
    
    self:UpdateVirtualScroll()
    self:UpdateSelectedCount()
    
    -- Play sound
    self._soundSystem:PlayUISound("Click")
end

function MassDeleteUI:UpdateSelectedCount()
    local count = 0
    for _ in pairs(self._selectedPets) do
        count = count + 1
    end
    
    if self._selectedCountLabel then
        self._selectedCountLabel.Text = count .. " pets selected"
    end
end

-- ========================================
-- REVIEW STAGE POPULATION
-- ========================================

function MassDeleteUI:PopulateReviewStage()
    -- Clear existing cards
    for _, child in ipairs(self._reviewGrid:GetChildren()) do
        if child:IsA("Frame") and child.Name == "PetCard" then
            child:Destroy()
        end
    end
    
    -- Calculate resources
    local totalCoins = 0
    local totalDust = 0
    local hasHighValue = false
    local highValueCount = {
        Epic = 0,
        Legendary = 0,
        Mythic = 0
    }
    
    -- Create cards for selected pets
    local index = 0
    for uniqueId, pet in pairs(self._selectedPets) do
        local card = self:CreateReviewCard(pet)
        card.Parent = self._reviewGrid
        card.LayoutOrder = index
        index = index + 1
        
        -- Calculate resources (example values)
        local petData = self._petDatabase:GetPetData(pet.petId)
        if petData then
            local baseValue = {
                Common = 10,
                Uncommon = 25,
                Rare = 100,
                Epic = 500,
                Legendary = 2000,
                Mythic = 10000
            }
            
            local rarityValue = baseValue[pet.rarity] or 10
            local levelMultiplier = 1 + (pet.level - 1) * 0.1
            
            totalCoins = totalCoins + math.floor(rarityValue * levelMultiplier)
            totalDust = totalDust + math.floor(rarityValue / 10)
            
            -- Check for high value
            if pet.rarity == "Epic" or pet.rarity == "Legendary" or pet.rarity == "Mythic" then
                hasHighValue = true
                highValueCount[pet.rarity] = (highValueCount[pet.rarity] or 0) + 1
            end
        end
    end
    
    -- Update summary
    local count = index
    self._summaryText.Text = "You are about to permanently delete " .. count .. " pets."
    self._coinsLabel.Text = "You will receive: " .. self._utilities:FormatNumber(totalCoins) .. " Coins"
    self._dustLabel.Text = self._utilities:FormatNumber(totalDust) .. " Pet Dust"
    
    -- Show warning if high value
    if hasHighValue then
        local warningParts = {}
        if highValueCount.Epic > 0 then
            table.insert(warningParts, highValueCount.Epic .. " Epic")
        end
        if highValueCount.Legendary > 0 then
            table.insert(warningParts, highValueCount.Legendary .. " Legendary")
        end
        if highValueCount.Mythic > 0 then
            table.insert(warningParts, highValueCount.Mythic .. " Mythic")
        end
        
        self._warningLabel.Text = "⚠️ WARNING! Your selection includes " .. table.concat(warningParts, ", ") .. " pets!"
        self._warningLabel.Visible = true
    else
        self._warningLabel.Visible = false
    end
end

function MassDeleteUI:CreateReviewCard(pet)
    local card = self:CreatePetCard()
    
    -- Always show as selected in review
    local selectionOverlay = card:FindFirstChild("SelectionOverlay")
    if selectionOverlay then
        selectionOverlay.Visible = true
    end
    
    -- Update with pet data
    self:UpdatePetCard(card, pet)
    
    -- Change click behavior - clicking removes from selection
    local button = card:FindFirstChildOfClass("TextButton")
    if button then
        if button.MouseButton1Click then
            self._janitor:Remove(button.MouseButton1Click)
        end
        
        self._janitor:Add(button.MouseButton1Click:Connect(function()
            self._selectedPets[pet.uniqueId] = nil
            card:Destroy()
            self:PopulateReviewStage() -- Refresh the review
            
            -- If no pets left, go back to selection
            if not next(self._selectedPets) then
                self:ShowStage(STAGES.SELECTION)
                self._notificationSystem:Show({
                    title = "No Pets Selected",
                    message = "All pets have been removed from deletion.",
                    type = "info"
                })
            end
        end))
    end
    
    return card
end

-- ========================================
-- CONFIRMATION STAGE
-- ========================================

function MassDeleteUI:PrepareConfirmationStage()
    local count = 0
    local hasLegendaryOrHigher = false
    
    for _, pet in pairs(self._selectedPets) do
        count = count + 1
        if pet.rarity == "Legendary" or pet.rarity == "Mythic" then
            hasLegendaryOrHigher = true
        end
    end
    
    -- Update summary
    self._confirmSummaryText.Text = string.format(
        "You are about to permanently delete %d pets.\n\nThis action cannot be undone!",
        count
    )
    
    -- Show type-to-confirm if needed
    local requiresTyping = count > 50 or hasLegendaryOrHigher
    self._typeToConfirmFrame.Visible = requiresTyping
    
    if requiresTyping then
        self._confirmInput.Text = ""
        self._finalDeleteBtn.Enabled = false
    else
        self._finalDeleteBtn.Enabled = true
    end
    
    -- Update button state
    self:UpdateConfirmButton()
end

function MassDeleteUI:UpdateConfirmButton()
    if self._typeToConfirmFrame.Visible then
        local inputText = self._confirmInput.Text:upper()
        self._finalDeleteBtn.Enabled = inputText == "DELETE"
    end
end

-- ========================================
-- DELETION EXECUTION
-- ========================================

function MassDeleteUI:ExecuteDeletion()
    -- Collect pet IDs
    local petIds = {}
    for uniqueId, _ in pairs(self._selectedPets) do
        table.insert(petIds, uniqueId)
    end
    
    -- Show loading
    self._finalDeleteBtn.Enabled = false
    self._finalDeleteBtn.Text = "Deleting..."
    
    -- Send batch delete request
    self._remoteManager:FireServer("BatchDeletePets", {
        petIds = petIds
    }):Then(function(result)
        if result.success then
            -- Play deletion animation
            self:PlayDeletionAnimation()
            
            -- Show success notification
            self._notificationSystem:Show({
                title = "Pets Deleted",
                message = string.format(
                    "Successfully deleted %d pets. Received %s coins and %s pet dust.",
                    result.deletedCount,
                    self._utilities:FormatNumber(result.coinsReceived),
                    self._utilities:FormatNumber(result.dustReceived)
                ),
                type = "success",
                duration = 5
            })
            
            -- Clear selection and close
            self._selectedPets = {}
            task.wait(1.5) -- Let animation play
            self:Close()
            
            -- Fire event for other systems to update
            self._eventBus:Fire("PetsDeleted", {
                count = result.deletedCount,
                coins = result.coinsReceived,
                dust = result.dustReceived
            })
            
        else
            -- Show error
            self._notificationSystem:Show({
                title = "Deletion Failed",
                message = result.error or "Failed to delete pets. Please try again.",
                type = "error"
            })
            
            -- Reset button
            self._finalDeleteBtn.Enabled = true
            self._finalDeleteBtn.Text = "DELETE"
        end
    end):Catch(function(err)
        warn("[MassDeleteUI] Deletion error:", err)
        
        self._notificationSystem:Show({
            title = "Network Error",
            message = "Failed to communicate with server. Please try again.",
            type = "error"
        })
        
        -- Reset button
        self._finalDeleteBtn.Enabled = true
        self._finalDeleteBtn.Text = "DELETE"
    end)
end

function MassDeleteUI:PlayDeletionAnimation()
    -- This would animate the pet cards flying to the resource icons
    -- For now, just play a sound
    self._soundSystem:PlayUISound("Disenchant")
    task.wait(0.5)
    self._soundSystem:PlayUISound("CoinCollect")
end

-- ========================================
-- LIFECYCLE
-- ========================================

function MassDeleteUI:Open()
    if self._window then
        self._window.Visible = true
        self._windowManager:RegisterWindow("MassDelete", self._window)
        
        -- Reset to selection stage
        self:ShowStage(STAGES.SELECTION)
        self:RefreshGrid()
        
        -- Play sound
        self._soundSystem:PlayUISound("WindowOpen")
    end
end

function MassDeleteUI:Close()
    if self._window then
        self._window.Visible = false
        self._windowManager:UnregisterWindow("MassDelete")
        
        -- Play sound
        self._soundSystem:PlayUISound("WindowClose")
    end
end

function MassDeleteUI:SetupEventListeners()
    -- Listen for inventory updates
    self._janitor:Add(self._eventBus:On("PlayerDataUpdated", function()
        if self._window and self._window.Visible then
            self:RefreshGrid()
        end
    end))
    
    -- Listen for window toggle
    self._janitor:Add(self._eventBus:On("ToggleMassDelete", function()
        if self._window.Visible then
            self:Close()
        else
            self:Open()
        end
    end))
end

function MassDeleteUI:Destroy()
    self._janitor:Destroy()
    
    if self._window then
        self._window:Destroy()
    end
end

return MassDeleteUI