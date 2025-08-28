--[[
    Module: ClientConfig
    Description: Centralized configuration for the Sanrio Tycoon client
    All game constants, colors, sounds, and settings in one place
]]

local Types = require(script.Parent.ClientTypes)

local ClientConfig = {}
ClientConfig.__index = ClientConfig

-- ========================================
-- UI CONFIGURATION
-- ========================================

ClientConfig.UI = {
	-- Scaling and sizing
	SCALE = 1,
	MIN_SCALE = 0.8,
	MAX_SCALE = 1.2,

	-- Animation speeds
	ANIMATION_SPEED = 0.3,
	FAST_ANIMATION = 0.2,
	SLOW_ANIMATION = 0.5,

	-- Performance settings
	PARTICLE_LIFETIME = 5,
	MAX_PARTICLES = 100,
	MAX_PET_CARDS = 500,
	VIRTUAL_SCROLL_BUFFER = 50,

	-- Timing
	NOTIFICATION_DURATION = 5,
	TOOLTIP_DELAY = 0.5,
	DOUBLE_CLICK_TIME = 0.5,

	-- Layout
	PADDING = 10,
	CORNER_RADIUS = 8,
	STROKE_THICKNESS = 2,
	BUTTON_HEIGHT = 40,
	CARD_SIZE = 100,

	-- Navigation
	NAV_BAR_WIDTH = 80,
	CURRENCY_HEIGHT = 60,
}

-- ========================================
-- Z-INDEX LAYERS
-- ========================================

ClientConfig.ZINDEX = {
	Background = 1,
	Default = 10,
	Card = 20,
	Window = 50,
	Modal = 100,
	Overlay = 200,
	Dropdown = 300,
	Tooltip = 999,
	Debug = 1000,
	Notification = 500,
	Loading = 900,
}

-- ========================================
-- COLOR PALETTE
-- ========================================

ClientConfig.COLORS = {
	-- Primary colors (Sanrio theme)
	Primary = Color3.fromRGB(255, 182, 193),      -- Light Pink (Hello Kitty)
	Secondary = Color3.fromRGB(255, 105, 180),    -- Hot Pink
	Accent = Color3.fromRGB(255, 20, 147),        -- Deep Pink

	-- UI States
	Success = Color3.fromRGB(50, 255, 50),        -- Green
	Error = Color3.fromRGB(255, 50, 50),          -- Red
	Warning = Color3.fromRGB(255, 255, 50),       -- Yellow
	Info = Color3.fromRGB(100, 200, 255),         -- Blue

	-- Backgrounds
	Background = Color3.fromRGB(255, 240, 245),   -- Lavender Blush
	Surface = Color3.fromRGB(255, 250, 250),      -- Slightly off-white
	Dark = Color3.fromRGB(50, 50, 50),            -- Dark

	-- Text
	Text = Color3.fromRGB(50, 50, 50),            -- Dark text
	TextSecondary = Color3.fromRGB(150, 150, 150), -- Gray text
	TextLight = Color3.fromRGB(255, 255, 255),    -- White text

	-- Special
	White = Color3.fromRGB(255, 255, 255),        -- Pure white
	Black = Color3.fromRGB(0, 0, 0),              -- Pure black
	Transparent = Color3.fromRGB(0, 0, 0),        -- For transparency

	-- Button states
	ButtonNormal = Color3.fromRGB(255, 182, 193),
	ButtonHover = Color3.fromRGB(255, 150, 170),
	ButtonPressed = Color3.fromRGB(230, 130, 150),
	ButtonDisabled = Color3.fromRGB(200, 200, 200),
}

-- ========================================
-- RARITY COLORS
-- ========================================

ClientConfig.RARITY_COLORS = {
	[1] = Color3.fromRGB(200, 200, 200),  -- Common (Gray)
	[2] = Color3.fromRGB(50, 255, 50),    -- Uncommon (Green)
	[3] = Color3.fromRGB(50, 150, 255),   -- Rare (Blue)
	[4] = Color3.fromRGB(200, 50, 255),   -- Epic (Purple)
	[5] = Color3.fromRGB(255, 200, 50),   -- Legendary (Gold)
	[6] = Color3.fromRGB(255, 50, 200),   -- Mythical (Pink)
	[7] = Color3.fromRGB(255, 0, 0),      -- Secret (Red)
	[8] = Color3.fromRGB(0, 255, 255),    -- Divine (Cyan)
	[9] = Color3.fromRGB(255, 150, 0),    -- Cosmic (Orange)
	[10] = Color3.fromRGB(150, 0, 255),   -- Ultimate (Deep Purple)
}

ClientConfig.RARITY_NAMES = {
	[1] = "Common",
	[2] = "Uncommon",
	[3] = "Rare",
	[4] = "Epic",
	[5] = "Legendary",
	[6] = "Mythical",
	[7] = "Secret",
	[8] = "Divine",
	[9] = "Cosmic",
	[10] = "Ultimate",
}

-- ========================================
-- TYPOGRAPHY
-- ========================================

ClientConfig.FONTS = {
	Primary = Enum.Font.Gotham,
	Secondary = Enum.Font.GothamBold,
	Display = Enum.Font.GothamBlack,
	Cute = Enum.Font.Cartoon,
	Numbers = Enum.Font.SourceSansBold,
	Mono = Enum.Font.Code,
}

ClientConfig.TEXT_SIZES = {
	Tiny = 12,
	Small = 14,
	Normal = 16,
	Medium = 18,
	Large = 24,
	Huge = 32,
	Display = 48,
}

-- ========================================
-- SOUND EFFECTS
-- ========================================

ClientConfig.SOUNDS = {
	-- UI Sounds
	Click = "rbxassetid://421058925",    -- UI Click sound
	Open = "rbxassetid://1369158",      -- Swoosh/Open sound
	Close = "rbxassetid://3228377781",  -- Close/Switch sound (working)
	Hover = "rbxassetid://12221967",    -- UI Hover sound

	-- Feedback Sounds
	Success = "rbxassetid://3175899",      -- Success/Victory sound (working)
	Error = "rbxassetid://2767090",        -- Error sound
	Notification = "rbxassetid://179235828", -- Notification sound (working)
	Warning = "rbxassetid://2767090",       -- Warning sound

	-- Game Sounds
	CaseOpen = "rbxassetid://511340819",  -- Case open/snap sound (working)
	Legendary = "rbxassetid://3175899",   -- Legendary/Victory sound (working)
	Purchase = "rbxassetid://203691837",  -- Purchase/Buy sound
	LevelUp = "rbxassetid://3175899",     -- Level up/Victory sound (working)
	Equip = "rbxassetid://3228377781",    -- Equip/Switch sound (working)
	Trade = "rbxassetid://179235828",     -- Trade/Impact sound (working)

	-- Currency Sounds
	CoinCollect = "rbxassetid://203691837",  -- Coin collect sound
	GemCollect = "rbxassetid://158715404",   -- Gem collect sound (working)
}

-- ========================================
-- ICONS & ASSETS
-- ========================================

ClientConfig.ICONS = {
	-- Currency Icons
	Coin = "rbxassetid://10000000001",
	Gem = "rbxassetid://10000000002",
	Ticket = "rbxassetid://10000000003",
	Candy = "rbxassetid://10000000011",
	Star = "rbxassetid://10000000004",

	-- Game Icons
	Pet = "rbxassetid://10000000005",
	Egg = "rbxassetid://10000000006",
	Trade = "rbxassetid://10000000007",
	Battle = "rbxassetid://10000000008",
	Quest = "rbxassetid://10000000009",
	Settings = "rbxassetid://10000000010",

	-- UI Icons
	Close = "rbxassetid://10000000012",
	Check = "rbxassetid://10000000013",
	Cross = "rbxassetid://10000000014",
	Lock = "rbxassetid://10000000015",
	Unlock = "rbxassetid://10000000016",
	Search = "rbxassetid://10000000017",
	Filter = "rbxassetid://10000000018",
	Sort = "rbxassetid://10000000019",

	-- Social Icons
	Profile = "rbxassetid://10000000020",
	Leaderboard = "rbxassetid://10000000021",
	Clan = "rbxassetid://10000000022",
	Friends = "rbxassetid://10000000023",
}

-- ========================================
-- CASE OPENING CONFIGURATION
-- ========================================

ClientConfig.CASE_OPENING = {
	SPIN_TIME = 5,
	ITEMS_VISIBLE = 5,
	ITEM_WIDTH = 150,
	ITEM_HEIGHT = 150,
	DECELERATION = 0.98,
	MIN_SPEED = 0.5,
	MAX_SPEED = 50,
	SKIP_DELAY = 1,
	AUTO_CLOSE_DELAY = 5,
}

-- ========================================
-- ANIMATION PRESETS
-- ========================================

ClientConfig.TWEEN_INFO = {
	Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Normal = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Elastic = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
	Linear = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

-- ========================================
-- GAMEPLAY CONFIGURATION
-- ========================================

ClientConfig.GAMEPLAY = {
	-- Inventory
	MAX_PETS = 1000,
	MAX_EQUIPPED = 6,
	DEFAULT_SORT = "Recent",
	DEFAULT_FILTER = "All",

	-- Trading
	MAX_TRADE_ITEMS = 20,
	TRADE_TIMEOUT = 300, -- 5 minutes
	TRADE_COOLDOWN = 10,

	-- Battle
	BATTLE_TEAM_SIZE = 3,
	TURN_TIME = 30,
	MATCHMAKING_TIMEOUT = 60,

	-- Quests
	DAILY_QUEST_COUNT = 3,
	WEEKLY_QUEST_COUNT = 3,
	QUEST_REFRESH_HOUR = 0, -- Midnight UTC

	-- Currency
	MAX_COINS = 1e15,  -- 1 quadrillion
	MAX_GEMS = 1e12,   -- 1 trillion
	MAX_TICKETS = 1e9, -- 1 billion
}

-- ========================================
-- NETWORK CONFIGURATION
-- ========================================

ClientConfig.NETWORK = {
	REQUEST_TIMEOUT = 10,
	MAX_RETRIES = 3,
	RETRY_DELAY = 1,
	RATE_LIMIT = 10, -- Requests per second
	QUEUE_SIZE = 100,
}

-- ========================================
-- DEBUG CONFIGURATION
-- ========================================

ClientConfig.DEBUG = {
	ENABLED = game:GetService("RunService"):IsStudio(),
	SHOW_FPS = true,
	SHOW_MEMORY = true,
	SHOW_NETWORK = true,
	LOG_EVENTS = true,
	LOG_ERRORS = true,
}

-- ========================================
-- VALIDATION METHODS
-- ========================================

function ClientConfig:ValidateColor(color: any): boolean
	return typeof(color) == "Color3"
end

function ClientConfig:ValidateSound(soundId: any): boolean
	return typeof(soundId) == "string" and (soundId:match("^rbxasset://") or soundId:match("^rbxassetid://"))
end

function ClientConfig:ValidateIcon(iconId: any): boolean
	return typeof(iconId) == "string" and iconId:match("^rbxassetid://")
end

function ClientConfig:ValidateConfig(): boolean
	-- Validate all colors
	for name, color in pairs(self.COLORS) do
		if not self:ValidateColor(color) then
			warn("[ClientConfig] Invalid color:", name)
			return false
		end
	end

	-- Validate all sounds
	for name, sound in pairs(self.SOUNDS) do
		if not self:ValidateSound(sound) then
			warn("[ClientConfig] Invalid sound:", name)
			return false
		end
	end

	-- Validate all icons
	for name, icon in pairs(self.ICONS) do
		if not self:ValidateIcon(icon) then
			warn("[ClientConfig] Invalid icon:", name)
			return false
		end
	end

	return true
end

-- ========================================
-- GETTER METHODS
-- ========================================

function ClientConfig:Get(path: string): any
	local segments = string.split(path, ".")
	local current = self

	for _, segment in ipairs(segments) do
		if type(current) ~= "table" then
			return nil
		end
		current = current[segment]
	end

	return current
end

function ClientConfig:GetColor(name: string): Color3?
	return self.COLORS[name]
end

function ClientConfig:GetRarityColor(rarity: number): Color3
	return self.RARITY_COLORS[rarity] or self.COLORS.White
end

function ClientConfig:GetRarityName(rarity: number): string
	return self.RARITY_NAMES[rarity] or "Unknown"
end

function ClientConfig:GetSound(name: string): string?
	return self.SOUNDS[name]
end

function ClientConfig:GetIcon(name: string): string?
	return self.ICONS[name]
end

function ClientConfig:GetFont(name: string): Enum.Font
	return self.FONTS[name] or self.FONTS.Primary
end

function ClientConfig:GetTextSize(name: string): number
	return self.TEXT_SIZES[name] or self.TEXT_SIZES.Normal
end

function ClientConfig:GetTweenInfo(name: string): TweenInfo
	return self.TWEEN_INFO[name] or self.TWEEN_INFO.Normal
end

-- ========================================
-- THEME SUPPORT
-- ========================================

ClientConfig.THEMES = {
	Default = {
		Primary = Color3.fromRGB(255, 182, 193),
		Secondary = Color3.fromRGB(255, 105, 180),
		Background = Color3.fromRGB(255, 240, 245),
	},
	Dark = {
		Primary = Color3.fromRGB(100, 50, 60),
		Secondary = Color3.fromRGB(150, 50, 100),
		Background = Color3.fromRGB(30, 30, 30),
	},
	Ocean = {
		Primary = Color3.fromRGB(100, 150, 255),
		Secondary = Color3.fromRGB(50, 100, 200),
		Background = Color3.fromRGB(220, 240, 255),
	},
}

function ClientConfig:ApplyTheme(themeName: string)
	local theme = self.THEMES[themeName]
	if not theme then
		warn("[ClientConfig] Unknown theme:", themeName)
		return
	end

	for key, color in pairs(theme) do
		self.COLORS[key] = color
	end
end

-- ========================================
-- INITIALIZATION
-- ========================================

function ClientConfig:Initialize()
	-- Validate configuration on startup
	if not self:ValidateConfig() then
		error("[ClientConfig] Configuration validation failed!")
	end

	-- Apply debug settings
	if self.DEBUG.ENABLED then
		print("[ClientConfig] Debug mode enabled")
	end

	return self
end

-- Create and return singleton instance
local instance = ClientConfig:Initialize()
return instance