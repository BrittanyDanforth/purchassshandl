--[[
    Module: SettingsUI
    Description: Comprehensive settings interface with audio, visual, gameplay,
                 keybinds, and account management
    Features: Toggle switches, sliders, dropdown menus, keybind editor,
              proper ZIndex handling, save/load persistence
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)

local SettingsUI = {}
SettingsUI.__index = SettingsUI

-- ========================================
-- TYPES
-- ========================================

type SettingCategory = {
    name: string,
    icon: string,
    color: Color3,
    settings: {Setting}
}

type Setting = {
    id: string,
    name: string,
    description: string?,
    type: "toggle" | "slider" | "dropdown" | "keybind" | "color",
    value: any,
    default: any,
    options: {any}?,
    min: number?,
    max: number?,
    step: number?,
    callback: (any) -> ()?
}

type Keybind = {
    action: string,
    key: Enum.KeyCode,
    modifiers: {Enum.KeyCode}?
}

-- ========================================
-- CONSTANTS
-- ========================================

local WINDOW_SIZE = Vector2.new(700, 600)
local HEADER_HEIGHT = 60
local SECTION_HEIGHT = 40
local SETTING_HEIGHT = 50
local KEYBIND_HEIGHT = 60
local SAVE_DEBOUNCE = 0.5

-- Default keybinds
local DEFAULT_KEYBINDS = {
    openInventory = Enum.KeyCode.I,
    openShop = Enum.KeyCode.P,
    openTrade = Enum.KeyCode.T,
    openBattle = Enum.KeyCode.B,
    openQuests = Enum.KeyCode.Q,
    openSettings = Enum.KeyCode.Escape,
    toggleUI = Enum.KeyCode.H,
    screenshot = Enum.KeyCode.F12
}

-- Setting categories
local SETTING_CATEGORIES = {
    {
        id = "audio",
        name = "🔊 Audio Settings",
        icon = "🔊",
        color = Config.COLORS.Primary
    },
    {
        id = "visual",
        name = "👁️ Visual Settings",
        icon = "👁️",
        color = Config.COLORS.Secondary
    },
    {
        id = "gameplay",
        name = "🎮 Gameplay Settings",
        icon = "🎮",
        color = Config.COLORS.Success
    },
    {
        id = "notifications",
        name = "🔔 Notification Settings",
        icon = "🔔",
        color = Config.COLORS.Warning
    },
    {
        id = "keybinds",
        name = "⌨️ Keybinds",
        icon = "⌨️",
        color = Config.COLORS.Info
    },
    {
        id = "advanced",
        name = "⚙️ Advanced Settings",
        icon = "⚙️",
        color = Config.COLORS.Error
    }
}

-- ========================================
-- INITIALIZATION
-- ========================================

function SettingsUI.new(dependencies)
    local self = setmetatable({}, SettingsUI)
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    self._dataCache = dependencies.DataCache
    self._remoteManager = dependencies.RemoteManager
    self._soundSystem = dependencies.SoundSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._uiFactory = dependencies.UIFactory
    self._windowManager = dependencies.WindowManager
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- UI References
    self.Frame = nil
    self.ScrollFrame = nil
    self.SettingsContainer = nil
    self.CategoryButtons = {}
    self.SettingElements = {}
    self.KeybindElements = {}
    
    -- State
    self.Settings = {}
    self.Keybinds = {}
    self.ActiveCategory = nil
    self.EditingKeybind = nil
    self.SaveDebounce = nil
    self.UnsavedChanges = false
    
    -- Initialize settings (deferred to Open)
    -- self:LoadSettings() -- Moved to Open
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    return self
end

function SettingsUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Settings updates
    self._eventBus:On("SettingsLoaded", function(settings)
        self:OnSettingsLoaded(settings)
    end)
    
    self._eventBus:On("SettingChanged", function(data)
        self:OnSettingChanged(data.id, data.value)
    end)
    
    -- Keybind handling
    Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self.EditingKeybind and not gameProcessed then
            self:OnKeybindInput(input)
        end
    end)
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function SettingsUI:Open()
    -- Load settings on first open
    if not self.Settings or not next(self.Settings) then
        self:LoadSettings()
    end
    
    if self.Frame then
        self.Frame.Visible = true
        return
    end
    
    -- Create UI
    self:CreateUI()
    
    -- Show first category
    self:ShowCategory("audio")
end

function SettingsUI:Close()
    if self.Frame then
        self.Frame.Visible = false
        
        -- Save any unsaved changes
        if self.UnsavedChanges then
            self:SaveSettings()
        end
        
        -- Notify window manager
        if self._windowManager then
            self._windowManager:CloseWindow("SettingsUI")
        end
        
        -- Fire close event
        if self._eventBus then
            self._eventBus:Fire("SettingsUIClosed")
        end
        
        -- Clear any active tweens/animations
        if self._activeTweens then
            for _, tween in pairs(self._activeTweens) do
                if tween and tween.Cancel then
                    tween:Cancel()
                end
            end
            self._activeTweens = {}
        end
    end
end

-- ========================================
-- UI CREATION
-- ========================================

function SettingsUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                   self._windowManager and self._windowManager:GetMainPanel() or 
                   Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[SettingsUI] No parent container found")
        return
    end
    
    -- Create main frame with exact same sizing as ShopUI
    self.Frame = self._uiFactory:CreateFrame(parent, {
        name = "SettingsFrame",
        size = UDim2.new(1, -20, 1, -90),  -- Same as ShopUI
        position = UDim2.new(0, 10, 0, 80), -- Same as ShopUI
        backgroundColor = self._config.COLORS.White,
        clipsDescendants = true,
        zIndex = 100, -- High ZIndex to ensure visibility
        visible = false  -- Start hidden
    })
    
    self._utilities.CreateCorner(self.Frame, 12)
    
    -- Create header
    self:CreateHeader()
    
    -- Create category sidebar
    self:CreateCategorySidebar()
    
    -- Create settings content area
    self:CreateSettingsContent()
    
    -- Create footer with save/reset buttons
    self:CreateFooter()
end

function SettingsUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary,
        zIndex = self.Frame.ZIndex + 1
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "⚙️ Settings ⚙️",
        size = UDim2.new(1, -60, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24,
        zIndex = header.ZIndex + 1
    })
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(header, {
        text = "✕",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0.5, -20),
        backgroundColor = self._config.COLORS.Secondary,
        textSize = 20,
        zIndex = header.ZIndex + 1,
        callback = function()
            self:Close()
        end
    })
end

function SettingsUI:CreateCategorySidebar()
    local sidebar = self._uiFactory:CreateFrame(self.Frame, {
        name = "Sidebar",
        size = UDim2.new(0, 200, 1, -HEADER_HEIGHT),
        position = UDim2.new(0, 0, 0, HEADER_HEIGHT),
        backgroundColor = self._config.COLORS.Surface,
        zIndex = self.Frame.ZIndex + 1
    })
    
    local categoryList = Instance.new("Frame")
    categoryList.Size = UDim2.new(1, -20, 1, -20)
    categoryList.Position = UDim2.new(0, 10, 0, 10)
    categoryList.BackgroundTransparency = 1
    categoryList.Parent = sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 5)
    layout.Parent = categoryList
    
    -- Create category buttons
    for _, category in ipairs(SETTING_CATEGORIES) do
        local button = self:CreateCategoryButton(categoryList, category)
        self.CategoryButtons[category.id] = button
    end
end

function SettingsUI:CreateCategoryButton(parent: Frame, category: table): TextButton
    local button = self._uiFactory:CreateButton(parent, {
        text = "",
        size = UDim2.new(1, 0, 0, 45),
        backgroundColor = self._config.COLORS.White,
        callback = function()
            self:ShowCategory(category.id)
        end
    })
    
    -- Icon
    local icon = self._uiFactory:CreateLabel(button, {
        text = category.icon,
        size = UDim2.new(0, 40, 1, 0),
        position = UDim2.new(0, 5, 0, 0),
        textSize = 20
    })
    
    -- Name
    local nameLabel = self._uiFactory:CreateLabel(button, {
        text = category.name,
        size = UDim2.new(1, -50, 1, 0),
        position = UDim2.new(0, 45, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textSize = 14
    })
    
    -- Selection indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "SelectionIndicator"
    indicator.Size = UDim2.new(0, 4, 1, -10)
    indicator.Position = UDim2.new(0, 0, 0, 5)
    indicator.BackgroundColor3 = category.color
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = button
    
    self._utilities.CreateCorner(indicator, 2)
    
    return button
end

function SettingsUI:CreateSettingsContent()
    local contentFrame = self._uiFactory:CreateFrame(self.Frame, {
        name = "ContentFrame",
        size = UDim2.new(1, -210, 1, -HEADER_HEIGHT - 60),
        position = UDim2.new(0, 205, 0, HEADER_HEIGHT),
        backgroundColor = self._config.COLORS.Background,
        zIndex = self.Frame.ZIndex + 1
    })
    
    self._utilities.CreateCorner(contentFrame, 12)
    
    -- Scroll frame
    self.ScrollFrame = self._uiFactory:CreateScrollingFrame(contentFrame, {
        size = UDim2.new(1, -10, 1, -10),
        position = UDim2.new(0, 5, 0, 5)
    })
    
    self.SettingsContainer = Instance.new("Frame")
    self.SettingsContainer.Size = UDim2.new(1, -20, 0, 100)
    self.SettingsContainer.BackgroundTransparency = 1
    self.SettingsContainer.Parent = self.ScrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = self.SettingsContainer
    
    self._utilities.CreatePadding(self.SettingsContainer, 10)
    
    -- Update canvas size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

function SettingsUI:CreateFooter()
    local footer = self._uiFactory:CreateFrame(self.Frame, {
        name = "Footer",
        size = UDim2.new(1, -210, 0, 50),
        position = UDim2.new(0, 205, 1, -55),
        backgroundColor = self._config.COLORS.Surface,
        zIndex = self.Frame.ZIndex + 1
    })
    
    self._utilities.CreateCorner(footer, 12)
    
    -- Save indicator
    local saveIndicator = self._uiFactory:CreateLabel(footer, {
        text = "",
        size = UDim2.new(0.5, -10, 1, 0),
        position = UDim2.new(0, 10, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.Success,
        font = self._config.FONTS.Secondary,
        textSize = 14
    })
    
    self.SaveIndicator = saveIndicator
    
    -- Button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0.5, -10, 1, -10)
    buttonContainer.Position = UDim2.new(0.5, 5, 0, 5)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = footer
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonContainer
    
    -- Reset button
    local resetButton = self._uiFactory:CreateButton(buttonContainer, {
        text = "Reset to Default",
        size = UDim2.new(0, 120, 1, 0),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:ResetToDefaults()
        end
    })
    
    -- Save button
    local saveButton = self._uiFactory:CreateButton(buttonContainer, {
        text = "Save Changes",
        size = UDim2.new(0, 120, 1, 0),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            self:SaveSettings(true)
        end
    })
end

-- ========================================
-- CATEGORY CONTENT
-- ========================================

function SettingsUI:ShowCategory(categoryId: string)
    -- Update active category
    self.ActiveCategory = categoryId
    
    -- Update button states
    for id, button in pairs(self.CategoryButtons) do
        local indicator = button:FindFirstChild("SelectionIndicator")
        if indicator then
            indicator.Visible = id == categoryId
        end
        
        button.BackgroundColor3 = id == categoryId and self._config.COLORS.Surface or self._config.COLORS.White
    end
    
    -- Clear current content
    for _, child in ipairs(self.SettingsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create new content
    if categoryId == "audio" then
        self:CreateAudioSettings()
    elseif categoryId == "visual" then
        self:CreateVisualSettings()
    elseif categoryId == "gameplay" then
        self:CreateGameplaySettings()
    elseif categoryId == "notifications" then
        self:CreateNotificationSettings()
    elseif categoryId == "keybinds" then
        self:CreateKeybindSettings()
    elseif categoryId == "advanced" then
        self:CreateAdvancedSettings()
    end
end

-- ========================================
-- AUDIO SETTINGS
-- ========================================

function SettingsUI:CreateAudioSettings()
    -- Master Volume
    self:CreateSettingSection("Master Volume")
    
    local masterVolume = self:CreateSliderSetting({
        name = "Master Volume",
        description = "Controls overall game volume",
        id = "masterVolume",
        min = 0,
        max = 100,
        step = 5,
        value = self.Settings.masterVolume or 100,
        callback = function(value)
            self:UpdateSetting("masterVolume", value)
            if self._soundSystem then
                self._soundSystem:SetMasterVolume(value / 100)
            end
        end
    })
    
    -- Music
    self:CreateSettingSection("Music")
    
    local musicEnabled = self:CreateToggleSetting({
        name = "Enable Music",
        description = "Toggle background music",
        id = "musicEnabled",
        value = self.Settings.musicEnabled ~= false,
        callback = function(value)
            self:UpdateSetting("musicEnabled", value)
            if self._soundSystem then
                if value then
                    self._soundSystem:PlayMusic("MainTheme")
                else
                    self._soundSystem:StopMusic()
                end
            end
        end
    })
    
    local musicVolume = self:CreateSliderSetting({
        name = "Music Volume",
        description = "Adjust music volume",
        id = "musicVolume",
        min = 0,
        max = 100,
        step = 5,
        value = self.Settings.musicVolume or 80,
        callback = function(value)
            self:UpdateSetting("musicVolume", value)
            if self._soundSystem then
                self._soundSystem:SetMusicVolume(value / 100)
            end
        end
    })
    
    -- Sound Effects
    self:CreateSettingSection("Sound Effects")
    
    local sfxEnabled = self:CreateToggleSetting({
        name = "Enable Sound Effects",
        description = "Toggle UI and gameplay sounds",
        id = "sfxEnabled",
        value = self.Settings.sfxEnabled ~= false,
        callback = function(value)
            self:UpdateSetting("sfxEnabled", value)
            if self._soundSystem and self._soundSystem.SetSFXEnabled then
                self._soundSystem:SetSFXEnabled(value)
            elseif self._soundSystem then
                warn("[SettingsUI] SoundSystem exists but SetSFXEnabled method not found")
            end
        end
    })
    
    local sfxVolume = self:CreateSliderSetting({
        name = "Effects Volume",
        description = "Adjust sound effects volume",
        id = "sfxVolume",
        min = 0,
        max = 100,
        step = 5,
        value = self.Settings.sfxVolume or 100,
        callback = function(value)
            self:UpdateSetting("sfxVolume", value)
            if self._soundSystem and self._soundSystem.SetSFXVolume then
                self._soundSystem:SetSFXVolume(value / 100)
            elseif self._soundSystem then
                warn("[SettingsUI] SoundSystem exists but SetSFXVolume method not found")
            end
        end
    })
    
    -- 3D Audio
    self:CreateSettingSection("3D Audio")
    
    local spatial3D = self:CreateToggleSetting({
        name = "Enable 3D Audio",
        description = "Spatial audio for in-world sounds",
        id = "spatial3D",
        value = self.Settings.spatial3D ~= false,
        callback = function(value)
            self:UpdateSetting("spatial3D", value)
        end
    })
end

-- ========================================
-- VISUAL SETTINGS
-- ========================================

function SettingsUI:CreateVisualSettings()
    -- Graphics Quality
    self:CreateSettingSection("Graphics Quality")
    
    local graphicsQuality = self:CreateDropdownSetting({
        name = "Graphics Quality",
        description = "Overall graphics preset",
        id = "graphicsQuality",
        options = {"Low", "Medium", "High", "Ultra"},
        value = self.Settings.graphicsQuality or "High",
        callback = function(value)
            self:UpdateSetting("graphicsQuality", value)
            self:ApplyGraphicsQuality(value)
        end
    })
    
    -- Particles
    self:CreateSettingSection("Particles & Effects")
    
    local particlesEnabled = self:CreateToggleSetting({
        name = "Enable Particles",
        description = "Toggle particle effects",
        id = "particlesEnabled",
        value = self.Settings.particlesEnabled ~= false,
        callback = function(value)
            self:UpdateSetting("particlesEnabled", value)
        end
    })
    
    local particleDensity = self:CreateSliderSetting({
        name = "Particle Density",
        description = "Amount of particles displayed",
        id = "particleDensity",
        min = 25,
        max = 100,
        step = 25,
        value = self.Settings.particleDensity or 100,
        callback = function(value)
            self:UpdateSetting("particleDensity", value)
        end
    })
    
    -- UI Settings
    self:CreateSettingSection("User Interface")
    
    local uiScale = self:CreateSliderSetting({
        name = "UI Scale",
        description = "Adjust interface size",
        id = "uiScale",
        min = 0.5,
        max = 1.5,
        step = 0.1,
        value = self.Settings.uiScale or 1.0,
        callback = function(value)
            self:UpdateSetting("uiScale", value)
            self:ApplyUIScale(value)
        end
    })
    
    local uiAnimations = self:CreateToggleSetting({
        name = "UI Animations",
        description = "Enable smooth UI transitions",
        id = "uiAnimations",
        value = self.Settings.uiAnimations ~= false,
        callback = function(value)
            self:UpdateSetting("uiAnimations", value)
        end
    })
    
    -- Theme
    self:CreateSettingSection("Theme")
    
    local darkMode = self:CreateToggleSetting({
        name = "Dark Mode",
        description = "Use dark theme for UI",
        id = "darkMode",
        value = self.Settings.darkMode == true,
        callback = function(value)
            self:UpdateSetting("darkMode", value)
            self:ApplyTheme(value and "dark" or "light")
        end
    })
    
    -- Performance
    self:CreateSettingSection("Performance")
    
    local lowQualityMode = self:CreateToggleSetting({
        name = "Low Quality Mode",
        description = "Optimize for performance",
        id = "lowQualityMode",
        value = self.Settings.lowQualityMode == true,
        callback = function(value)
            self:UpdateSetting("lowQualityMode", value)
        end
    })
    
    local showFPS = self:CreateToggleSetting({
        name = "Show FPS Counter",
        description = "Display frames per second",
        id = "showFPS",
        value = self.Settings.showFPS == true,
        callback = function(value)
            self:UpdateSetting("showFPS", value)
        end
    })
end

-- ========================================
-- GAMEPLAY SETTINGS
-- ========================================

function SettingsUI:CreateGameplaySettings()
    -- Auto Features
    self:CreateSettingSection("Automation")
    
    local autoDelete = self:CreateToggleSetting({
        name = "Auto-Delete Commons",
        description = "Automatically delete common pets when inventory is full",
        id = "autoDelete",
        value = self.Settings.autoDelete == true,
        callback = function(value)
            self:UpdateSetting("autoDelete", value)
        end
    })
    
    local autoEquipBest = self:CreateToggleSetting({
        name = "Auto-Equip Best Pets",
        description = "Automatically equip highest power pets",
        id = "autoEquipBest",
        value = self.Settings.autoEquipBest == true,
        callback = function(value)
            self:UpdateSetting("autoEquipBest", value)
        end
    })
    
    local skipCaseAnimation = self:CreateToggleSetting({
        name = "Skip Case Animations",
        description = "Skip egg/case opening animations",
        id = "skipCaseAnimation",
        value = self.Settings.skipCaseAnimation == true,
        callback = function(value)
            self:UpdateSetting("skipCaseAnimation", value)
        end
    })
    
    -- Trading
    self:CreateSettingSection("Trading")
    
    local acceptFriendTrades = self:CreateToggleSetting({
        name = "Accept Friend Trades Only",
        description = "Only accept trade requests from friends",
        id = "acceptFriendTrades",
        value = self.Settings.acceptFriendTrades == true,
        callback = function(value)
            self:UpdateSetting("acceptFriendTrades", value)
        end
    })
    
    local tradeConfirmation = self:CreateToggleSetting({
        name = "Trade Confirmation",
        description = "Require confirmation for all trades",
        id = "tradeConfirmation",
        value = self.Settings.tradeConfirmation ~= false,
        callback = function(value)
            self:UpdateSetting("tradeConfirmation", value)
        end
    })
    
    -- Battle
    self:CreateSettingSection("Battle")
    
    local autoBattleSpeed = self:CreateDropdownSetting({
        name = "Auto-Battle Speed",
        description = "Speed of automatic battles",
        id = "autoBattleSpeed",
        options = {"Slow", "Normal", "Fast", "Ultra Fast"},
        value = self.Settings.autoBattleSpeed or "Normal",
        callback = function(value)
            self:UpdateSetting("autoBattleSpeed", value)
        end
    })
    
    local showDamageNumbers = self:CreateToggleSetting({
        name = "Show Damage Numbers",
        description = "Display damage dealt in battles",
        id = "showDamageNumbers",
        value = self.Settings.showDamageNumbers ~= false,
        callback = function(value)
            self:UpdateSetting("showDamageNumbers", value)
        end
    })
end

-- ========================================
-- NOTIFICATION SETTINGS
-- ========================================

function SettingsUI:CreateNotificationSettings()
    -- General
    self:CreateSettingSection("General Notifications")
    
    local notificationsEnabled = self:CreateToggleSetting({
        name = "Enable Notifications",
        description = "Show in-game notifications",
        id = "notificationsEnabled",
        value = self.Settings.notificationsEnabled ~= false,
        callback = function(value)
            self:UpdateSetting("notificationsEnabled", value)
        end
    })
    
    local notificationPosition = self:CreateDropdownSetting({
        name = "Notification Position",
        description = "Where notifications appear",
        id = "notificationPosition",
        options = {"Top Right", "Top Left", "Bottom Right", "Bottom Left", "Center"},
        value = self.Settings.notificationPosition or "Top Right",
        callback = function(value)
            self:UpdateSetting("notificationPosition", value)
        end
    })
    
    -- Specific Notifications
    self:CreateSettingSection("Notification Types")
    
    local questNotifications = self:CreateToggleSetting({
        name = "Quest Notifications",
        description = "Notify when quests are completed",
        id = "questNotifications",
        value = self.Settings.questNotifications ~= false,
        callback = function(value)
            self:UpdateSetting("questNotifications", value)
        end
    })
    
    local tradeNotifications = self:CreateToggleSetting({
        name = "Trade Notifications",
        description = "Notify for trade requests",
        id = "tradeNotifications",
        value = self.Settings.tradeNotifications ~= false,
        callback = function(value)
            self:UpdateSetting("tradeNotifications", value)
        end
    })
    
    local battleNotifications = self:CreateToggleSetting({
        name = "Battle Notifications",
        description = "Notify for battle invites",
        id = "battleNotifications",
        value = self.Settings.battleNotifications ~= false,
        callback = function(value)
            self:UpdateSetting("battleNotifications", value)
        end
    })
    
    local achievementNotifications = self:CreateToggleSetting({
        name = "Achievement Notifications",
        description = "Notify when achievements unlock",
        id = "achievementNotifications",
        value = self.Settings.achievementNotifications ~= false,
        callback = function(value)
            self:UpdateSetting("achievementNotifications", value)
        end
    })
    
    -- Sound
    self:CreateSettingSection("Notification Sounds")
    
    local notificationSound = self:CreateToggleSetting({
        name = "Notification Sounds",
        description = "Play sounds with notifications",
        id = "notificationSound",
        value = self.Settings.notificationSound ~= false,
        callback = function(value)
            self:UpdateSetting("notificationSound", value)
        end
    })
    
    local notificationVolume = self:CreateSliderSetting({
        name = "Notification Volume",
        description = "Volume of notification sounds",
        id = "notificationVolume",
        min = 0,
        max = 100,
        step = 10,
        value = self.Settings.notificationVolume or 80,
        callback = function(value)
            self:UpdateSetting("notificationVolume", value)
        end
    })
end

-- ========================================
-- KEYBIND SETTINGS
-- ========================================

function SettingsUI:CreateKeybindSettings()
    self:CreateSettingSection("UI Keybinds")
    
    -- UI keybinds
    local uiKeybinds = {
        {id = "openInventory", name = "Open Inventory", default = DEFAULT_KEYBINDS.openInventory},
        {id = "openShop", name = "Open Shop", default = DEFAULT_KEYBINDS.openShop},
        {id = "openTrade", name = "Open Trading", default = DEFAULT_KEYBINDS.openTrade},
        {id = "openBattle", name = "Open Battle", default = DEFAULT_KEYBINDS.openBattle},
        {id = "openQuests", name = "Open Quests", default = DEFAULT_KEYBINDS.openQuests},
        {id = "openSettings", name = "Open Settings", default = DEFAULT_KEYBINDS.openSettings},
        {id = "toggleUI", name = "Toggle UI", default = DEFAULT_KEYBINDS.toggleUI}
    }
    
    for _, keybind in ipairs(uiKeybinds) do
        self:CreateKeybindSetting(keybind)
    end
    
    self:CreateSettingSection("Other Keybinds")
    
    -- Other keybinds
    local otherKeybinds = {
        {id = "screenshot", name = "Take Screenshot", default = DEFAULT_KEYBINDS.screenshot}
    }
    
    for _, keybind in ipairs(otherKeybinds) do
        self:CreateKeybindSetting(keybind)
    end
    
    -- Reset keybinds button
    local resetButton = self._uiFactory:CreateButton(self.SettingsContainer, {
        text = "Reset All Keybinds",
        size = UDim2.new(1, 0, 0, 40),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:ResetKeybinds()
        end
    })
end

function SettingsUI:CreateKeybindSetting(keybindData: table)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, KEYBIND_HEIGHT)
    frame.BackgroundColor3 = self._config.COLORS.White
    frame.Parent = self.SettingsContainer
    
    self._utilities.CreateCorner(frame, 8)
    self._utilities.CreatePadding(frame, 15)
    
    -- Name
    local nameLabel = self._uiFactory:CreateLabel(frame, {
        text = keybindData.name,
        size = UDim2.new(0.5, -10, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary
    })
    
    -- Current keybind
    local currentKey = self.Keybinds[keybindData.id] or keybindData.default
    local keyButton = self._uiFactory:CreateButton(frame, {
        text = currentKey.Name,
        size = UDim2.new(0, 120, 0, 35),
        position = UDim2.new(1, -180, 0.5, -17.5),
        backgroundColor = self._config.COLORS.Surface,
        callback = function()
            self:StartKeybindEdit(keybindData.id, keyButton)
        end
    })
    
    -- Reset button
    local resetButton = self._uiFactory:CreateButton(frame, {
        text = "Reset",
        size = UDim2.new(0, 50, 0, 35),
        position = UDim2.new(1, -55, 0.5, -17.5),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:ResetKeybind(keybindData.id, keybindData.default, keyButton)
        end
    })
    
    -- Store reference
    self.KeybindElements[keybindData.id] = {
        frame = frame,
        button = keyButton,
        default = keybindData.default
    }
end

function SettingsUI:StartKeybindEdit(keybindId: string, button: TextButton)
    -- Cancel any existing edit
    if self.EditingKeybind then
        local oldButton = self.KeybindElements[self.EditingKeybind].button
        oldButton.Text = (self.Keybinds[self.EditingKeybind] or DEFAULT_KEYBINDS[self.EditingKeybind]).Name
        oldButton.BackgroundColor3 = self._config.COLORS.Surface
    end
    
    -- Start new edit
    self.EditingKeybind = keybindId
    button.Text = "Press any key..."
    button.BackgroundColor3 = self._config.COLORS.Warning
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
end

function SettingsUI:OnKeybindInput(input: InputObject)
    if not self.EditingKeybind then return end
    
    -- Ignore certain keys
    local ignoredKeys = {
        [Enum.KeyCode.Unknown] = true,
        [Enum.KeyCode.ButtonX] = true,
        [Enum.KeyCode.ButtonY] = true,
        [Enum.KeyCode.ButtonA] = true,
        [Enum.KeyCode.ButtonB] = true
    }
    
    if input.KeyCode and not ignoredKeys[input.KeyCode] then
        -- Update keybind
        self.Keybinds[self.EditingKeybind] = input.KeyCode
        
        -- Update button
        local element = self.KeybindElements[self.EditingKeybind]
        if element then
            element.button.Text = input.KeyCode.Name
            element.button.BackgroundColor3 = self._config.COLORS.Surface
        end
        
        -- Mark as changed
        self:UpdateSetting("keybind_" .. self.EditingKeybind, input.KeyCode.Name)
        
        -- Stop editing
        self.EditingKeybind = nil
        
        -- Play sound
        if self._soundSystem then
            self._soundSystem:PlayUISound("Success")
        end
    end
end

function SettingsUI:ResetKeybind(keybindId: string, defaultKey: Enum.KeyCode, button: TextButton)
    self.Keybinds[keybindId] = defaultKey
    button.Text = defaultKey.Name
    
    self:UpdateSetting("keybind_" .. keybindId, defaultKey.Name)
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Reset")
    end
end

function SettingsUI:ResetKeybinds()
    for id, element in pairs(self.KeybindElements) do
        self.Keybinds[id] = element.default
        element.button.Text = element.default.Name
        self:UpdateSetting("keybind_" .. id, element.default.Name)
    end
    
    self._notificationSystem:SendNotification("Keybinds Reset", 
        "All keybinds have been reset to defaults", "info")
end

-- ========================================
-- ADVANCED SETTINGS
-- ========================================

function SettingsUI:CreateAdvancedSettings()
    -- Developer Options
    self:CreateSettingSection("Developer Options")
    
    local debugMode = self:CreateToggleSetting({
        name = "Debug Mode",
        description = "Show debug information",
        id = "debugMode",
        value = self.Settings.debugMode == true,
        callback = function(value)
            self:UpdateSetting("debugMode", value)
        end
    })
    
    local consoleOutput = self:CreateToggleSetting({
        name = "Console Output",
        description = "Log events to console",
        id = "consoleOutput",
        value = self.Settings.consoleOutput == true,
        callback = function(value)
            self:UpdateSetting("consoleOutput", value)
        end
    })
    
    -- Network
    self:CreateSettingSection("Network")
    
    local streamingEnabled = self:CreateToggleSetting({
        name = "Content Streaming",
        description = "Stream game content as needed",
        id = "streamingEnabled",
        value = self.Settings.streamingEnabled ~= false,
        callback = function(value)
            self:UpdateSetting("streamingEnabled", value)
        end
    })
    
    -- Data
    self:CreateSettingSection("Data Management")
    
    local cacheSize = self:CreateSliderSetting({
        name = "Cache Size (MB)",
        description = "Maximum cache size",
        id = "cacheSize",
        min = 50,
        max = 500,
        step = 50,
        value = self.Settings.cacheSize or 200,
        callback = function(value)
            self:UpdateSetting("cacheSize", value)
        end
    })
    
    -- Clear cache button
    local clearCacheButton = self._uiFactory:CreateButton(self.SettingsContainer, {
        text = "Clear Cache",
        size = UDim2.new(1, 0, 0, 40),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:ClearCache()
        end
    })
    
    -- Export/Import settings
    self:CreateSettingSection("Settings Backup")
    
    local exportButton = self._uiFactory:CreateButton(self.SettingsContainer, {
        text = "Export Settings",
        size = UDim2.new(0.48, 0, 0, 40),
        backgroundColor = self._config.COLORS.Primary,
        callback = function()
            self:ExportSettings()
        end
    })
    
    local importButton = self._uiFactory:CreateButton(self.SettingsContainer, {
        text = "Import Settings",
        size = UDim2.new(0.48, 0, 0, 40),
        position = UDim2.new(0.52, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary,
        callback = function()
            self:ImportSettings()
        end
    })
    
    -- Account info
    self:CreateSettingSection("Account Information")
    
    local accountInfo = Instance.new("Frame")
    accountInfo.Size = UDim2.new(1, 0, 0, 100)
    accountInfo.BackgroundColor3 = self._config.COLORS.White
    accountInfo.Parent = self.SettingsContainer
    
    self._utilities.CreateCorner(accountInfo, 12)
    self._utilities.CreatePadding(accountInfo, 15)
    
    local player = Services.Players.LocalPlayer
    
    local usernameLabel = self._uiFactory:CreateLabel(accountInfo, {
        text = "Username: " .. player.Name,
        size = UDim2.new(1, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left
    })
    
    local userIdLabel = self._uiFactory:CreateLabel(accountInfo, {
        text = "User ID: " .. player.UserId,
        size = UDim2.new(1, 0, 0, 25),
        position = UDim2.new(0, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary
    })
    
    local accountAgeLabel = self._uiFactory:CreateLabel(accountInfo, {
        text = "Account Age: " .. player.AccountAge .. " days",
        size = UDim2.new(1, 0, 0, 25),
        position = UDim2.new(0, 0, 0, 50),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = self._config.COLORS.TextSecondary
    })
end

-- ========================================
-- SETTING ELEMENTS
-- ========================================

function SettingsUI:CreateSettingSection(title: string)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, SECTION_HEIGHT)
    section.BackgroundColor3 = self._config.COLORS.Primary
    section.BackgroundTransparency = 0.9
    section.Parent = self.SettingsContainer
    
    self._utilities.CreateCorner(section, 8)
    
    local titleLabel = self._uiFactory:CreateLabel(section, {
        text = title,
        size = UDim2.new(1, -20, 1, 0),
        position = UDim2.new(0, 10, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary,
        textColor = self._config.COLORS.Primary,
        textSize = 18
    })
    
    return section
end

function SettingsUI:CreateToggleSetting(data: table): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, SETTING_HEIGHT)
    frame.BackgroundColor3 = self._config.COLORS.White
    frame.Parent = self.SettingsContainer
    
    self._utilities.CreateCorner(frame, 8)
    self._utilities.CreatePadding(frame, 15)
    
    -- Name and description
    local textFrame = Instance.new("Frame")
    textFrame.Size = UDim2.new(1, -80, 1, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.Parent = frame
    
    local nameLabel = self._uiFactory:CreateLabel(textFrame, {
        text = data.name,
        size = UDim2.new(1, 0, 0.5, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary
    })
    
    if data.description then
        local descLabel = self._uiFactory:CreateLabel(textFrame, {
            text = data.description,
            size = UDim2.new(1, 0, 0.5, 0),
            position = UDim2.new(0, 0, 0.5, 0),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.TextSecondary,
            textSize = 12
        })
    end
    
    -- Toggle
    local toggle = self._uiFactory:CreateToggleSwitch(frame, {
        size = UDim2.new(0, 60, 0, 30),
        position = UDim2.new(1, -60, 0.5, -15),
        value = data.value,
        callback = data.callback
    })
    
    -- Store reference
    self.SettingElements[data.id] = {
        frame = frame,
        control = toggle,
        type = "toggle"
    }
    
    return frame
end

function SettingsUI:CreateSliderSetting(data: table): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, SETTING_HEIGHT + 20)
    frame.BackgroundColor3 = self._config.COLORS.White
    frame.Parent = self.SettingsContainer
    
    self._utilities.CreateCorner(frame, 8)
    self._utilities.CreatePadding(frame, 15)
    
    -- Name and value
    local nameLabel = self._uiFactory:CreateLabel(frame, {
        text = data.name .. ": " .. tostring(data.value),
        size = UDim2.new(1, 0, 0, 25),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary
    })
    
    if data.description then
        local descLabel = self._uiFactory:CreateLabel(frame, {
            text = data.description,
            size = UDim2.new(1, 0, 0, 20),
            position = UDim2.new(0, 0, 0, 20),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.TextSecondary,
            textSize = 12
        })
    end
    
    -- Slider
    local slider = self._uiFactory:CreateSlider(frame, {
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 1, -25),
        min = data.min,
        max = data.max,
        value = data.value,
        step = data.step,
        callback = function(value)
            nameLabel.Text = data.name .. ": " .. tostring(value)
            data.callback(value)
        end
    })
    
    -- Store reference
    self.SettingElements[data.id] = {
        frame = frame,
        control = slider,
        label = nameLabel,
        type = "slider"
    }
    
    return frame
end

function SettingsUI:CreateDropdownSetting(data: table): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, SETTING_HEIGHT)
    frame.BackgroundColor3 = self._config.COLORS.White
    frame.Parent = self.SettingsContainer
    
    self._utilities.CreateCorner(frame, 8)
    self._utilities.CreatePadding(frame, 15)
    
    -- Name and description
    local textFrame = Instance.new("Frame")
    textFrame.Size = UDim2.new(0.6, -10, 1, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.Parent = frame
    
    local nameLabel = self._uiFactory:CreateLabel(textFrame, {
        text = data.name,
        size = UDim2.new(1, 0, 0.5, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        font = self._config.FONTS.Secondary
    })
    
    if data.description then
        local descLabel = self._uiFactory:CreateLabel(textFrame, {
            text = data.description,
            size = UDim2.new(1, 0, 0.5, 0),
            position = UDim2.new(0, 0, 0.5, 0),
            textXAlignment = Enum.TextXAlignment.Left,
            textColor = self._config.COLORS.TextSecondary,
            textSize = 12
        })
    end
    
    -- Dropdown
    local dropdown = self._uiFactory:CreateDropdown(frame, {
        options = data.options,
        default = data.value,
        size = UDim2.new(0.35, 0, 0, 35),
        position = UDim2.new(0.65, 0, 0.5, -17.5),
        callback = data.callback
    })
    
    -- Store reference
    self.SettingElements[data.id] = {
        frame = frame,
        control = dropdown,
        type = "dropdown"
    }
    
    return frame
end

-- ========================================
-- SETTINGS MANAGEMENT
-- ========================================

function SettingsUI:UpdateSetting(id: string, value: any)
    self.Settings[id] = value
    self.UnsavedChanges = true
    
    -- Update save indicator
    if self.SaveIndicator then
        self.SaveIndicator.Text = "• Unsaved changes"
        self.SaveIndicator.TextColor3 = self._config.COLORS.Warning
    end
    
    -- Fire event
    if self._eventBus then
        self._eventBus:Fire("SettingChanged", {id = id, value = value})
    end
    
    -- Auto-save after delay
    self:DebounceSave()
end

function SettingsUI:DebounceSave()
    if self.SaveDebounce then
        task.cancel(self.SaveDebounce)
    end
    
    self.SaveDebounce = task.delay(SAVE_DEBOUNCE, function()
        self.SaveDebounce = nil
        self:SaveSettings()
    end)
end

function SettingsUI:SaveSettings(manual: boolean?)
    if not self.UnsavedChanges and not manual then
        return
    end
    
    -- Send to server
    if self._remoteManager then
        local success = self._remoteManager:InvokeServer("SaveSettings", self.Settings)
        
        if success then
            self.UnsavedChanges = false
            
            -- Update indicator
            if self.SaveIndicator then
                self.SaveIndicator.Text = "✓ Settings saved"
                self.SaveIndicator.TextColor3 = self._config.COLORS.Success
                
                -- Clear after delay
                task.delay(3, function()
                    if self.SaveIndicator then
                        self.SaveIndicator.Text = ""
                    end
                end)
            end
            
            if manual then
                self._notificationSystem:SendNotification("Settings Saved", 
                    "Your settings have been saved", "success")
            end
        else
            self._notificationSystem:SendNotification("Save Failed", 
                "Failed to save settings", "error")
        end
    end
    
    -- Save locally as backup
    self:SaveLocalSettings()
end

function SettingsUI:LoadSettings()
    -- Skip server load for now since LoadSettings remote is not implemented
    -- Use default settings
    if self._debugMode then
        print("[SettingsUI] Using default settings - server settings not available")
    end
    
    -- Initialize default settings if not present
    self.Settings = self.Settings or {}
    if not self.Settings.masterVolume then self.Settings.masterVolume = 100 end
    if not self.Settings.musicVolume then self.Settings.musicVolume = 80 end
    if not self.Settings.sfxVolume then self.Settings.sfxVolume = 100 end
    if not self.Settings.graphics then self.Settings.graphics = "high" end
    if not self.Settings.showParticles then self.Settings.showParticles = true end
    if not self.Settings.showNotifications then self.Settings.showNotifications = true end
    
    -- Load keybinds
    for id, defaultKey in pairs(DEFAULT_KEYBINDS) do
        local savedKey = self.Settings["keybind_" .. id]
        if savedKey then
            -- Convert string to KeyCode
            for _, keyCode in pairs(Enum.KeyCode:GetEnumItems()) do
                if keyCode.Name == savedKey then
                    self.Keybinds[id] = keyCode
                    break
                end
            end
        else
            self.Keybinds[id] = defaultKey
        end
    end
    
    -- Apply settings
    self:ApplySettings()
end

function SettingsUI:SaveLocalSettings()
    -- Save to DataStore or local storage
    local data = Services.HttpService:JSONEncode(self.Settings)
    -- Implementation depends on platform
end

function SettingsUI:ApplySettings()
    -- Apply all settings with proper checks
    if self._soundSystem then
        local masterVolume = (self.Settings.masterVolume or 100) / 100
        local musicVolume = (self.Settings.musicVolume or 80) / 100
        local sfxVolume = (self.Settings.sfxVolume or 100) / 100
        
        -- Set master volume
        if self._soundSystem.SetMasterVolume then
            self._soundSystem:SetMasterVolume(masterVolume)
        elseif self._soundSystem._masterVolume ~= nil then
            self._soundSystem._masterVolume = masterVolume
        end
        
        -- Set music volume
        if self._soundSystem.SetMusicVolume then
            self._soundSystem:SetMusicVolume(musicVolume)
        elseif self._soundSystem._musicVolume ~= nil then
            self._soundSystem._musicVolume = musicVolume
        end
        
        -- Set SFX volume
        if self._soundSystem.SetSFXVolume then
            self._soundSystem:SetSFXVolume(sfxVolume)
        elseif self._soundSystem._sfxVolume ~= nil then
            self._soundSystem._sfxVolume = sfxVolume
        end
        
        -- Handle music enable/disable
        if self.Settings.musicEnabled then
            if self._soundSystem.PlayMusic then
                self._soundSystem:PlayMusic("MainTheme")
            end
        else
            if self._soundSystem.StopMusic then
                self._soundSystem:StopMusic()
            end
        end
    end
    
    -- Apply UI scale
    if self.Settings.uiScale then
        self:ApplyUIScale(self.Settings.uiScale)
    end
    
    -- Apply theme
    if self.Settings.darkMode then
        self:ApplyTheme("dark")
    end
    
    -- Apply graphics
    if self.Settings.graphicsQuality then
        self:ApplyGraphicsQuality(self.Settings.graphicsQuality)
    end
end

function SettingsUI:ResetToDefaults()
    -- Confirm dialog
    local confirmDialog = self._uiFactory:CreateConfirmDialog({
        title = "Reset Settings",
        message = "Are you sure you want to reset all settings to defaults?",
        confirmText = "Reset",
        confirmColor = self._config.COLORS.Error,
        onConfirm = function()
            self:DoReset()
        end
    })
end

function SettingsUI:DoReset()
    -- Reset all settings
    self.Settings = {}
    self.Keybinds = table.clone(DEFAULT_KEYBINDS)
    
    -- Update UI
    self:ShowCategory(self.ActiveCategory)
    
    -- Save
    self:SaveSettings(true)
    
    -- Notification
    self._notificationSystem:SendNotification("Settings Reset", 
        "All settings have been reset to defaults", "info")
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function SettingsUI:ApplyUIScale(scale: number)
    local mainUI = Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    if mainUI then
        local uiScale = mainUI:FindFirstChildOfClass("UIScale")
        if not uiScale then
            uiScale = Instance.new("UIScale")
            uiScale.Parent = mainUI
        end
        
        self._utilities.Tween(uiScale, {
            Scale = scale
        }, self._config.TWEEN_INFO.Normal)
    end
end

function SettingsUI:ApplyTheme(theme: string)
    -- Apply theme changes
    if self._eventBus then
        self._eventBus:Fire("ThemeChanged", theme)
    end
end

function SettingsUI:ApplyGraphicsQuality(quality: string)
    local qualityLevels = {
        Low = {lighting = 0, particles = 0.25, shadows = false},
        Medium = {lighting = 1, particles = 0.5, shadows = true},
        High = {lighting = 2, particles = 0.75, shadows = true},
        Ultra = {lighting = 3, particles = 1, shadows = true}
    }
    
    local settings = qualityLevels[quality]
    if settings and self._eventBus then
        self._eventBus:Fire("GraphicsQualityChanged", settings)
    end
end

function SettingsUI:ClearCache()
    -- Clear local cache
    if self._dataCache then
        self._dataCache:Clear()
    end
    
    self._notificationSystem:SendNotification("Cache Cleared", 
        "Local cache has been cleared", "success")
end

function SettingsUI:ExportSettings()
    -- Export settings to clipboard
    local data = Services.HttpService:JSONEncode(self.Settings)
    setclipboard(data)
    
    self._notificationSystem:SendNotification("Settings Exported", 
        "Settings copied to clipboard", "success")
end

function SettingsUI:ImportSettings()
    -- Import settings from clipboard
    local success, data = pcall(function()
        return Services.HttpService:JSONDecode(getclipboard())
    end)
    
    if success and type(data) == "table" then
        self.Settings = data
        self:ApplySettings()
        self:ShowCategory(self.ActiveCategory)
        self:SaveSettings(true)
        
        self._notificationSystem:SendNotification("Settings Imported", 
            "Settings imported successfully", "success")
    else
        self._notificationSystem:SendNotification("Import Failed", 
            "Invalid settings data in clipboard", "error")
    end
end

function SettingsUI:OnSettingsLoaded(settings: table)
    self.Settings = settings
    self:ApplySettings()
    
    -- Update UI if open
    if self.Frame and self.Frame.Visible then
        self:ShowCategory(self.ActiveCategory)
    end
end

function SettingsUI:OnSettingChanged(id: string, value: any)
    -- External setting change
    self.Settings[id] = value
    
    -- Update UI element
    local element = self.SettingElements[id]
    if element then
        if element.type == "toggle" then
            -- Use UIFactory helper method
            if self._uiFactory.SetToggleValue then
                self._uiFactory:SetToggleValue(element.control, value)
            end
        elseif element.type == "slider" then
            -- Use UIFactory helper method
            if self._uiFactory.SetSliderValue then
                self._uiFactory:SetSliderValue(element.control, value)
            end
            if element.label then
                element.label.Text = element.label.Text:gsub(": .+", ": " .. tostring(value))
            end
        elseif element.type == "dropdown" then
            -- Use UIFactory helper method
            if self._uiFactory.SetDropdownValue then
                self._uiFactory:SetDropdownValue(element.control, value)
            end
        end
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function SettingsUI:Destroy()
    -- Cancel debounce
    if self.SaveDebounce then
        task.cancel(self.SaveDebounce)
    end
    
    -- Save any unsaved changes
    if self.UnsavedChanges then
        self:SaveSettings()
    end
    
    -- Close UI
    self:Close()
    
    -- Clear references
    self.Frame = nil
    self.ScrollFrame = nil
    self.SettingsContainer = nil
    self.CategoryButtons = {}
    self.SettingElements = {}
    self.KeybindElements = {}
end

return SettingsUI