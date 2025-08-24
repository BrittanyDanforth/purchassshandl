-- SANRIO SHOP PROFESSIONAL - Part 1: Core Setup
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    -- UI Colors
    PRIMARY_COLOR = Color3.fromRGB(255, 192, 203),
    SECONDARY_COLOR = Color3.fromRGB(255, 230, 240),
    ACCENT_COLOR = Color3.fromRGB(255, 105, 180),
    CASH_COLOR = Color3.fromRGB(85, 255, 127),
    PASS_COLOR = Color3.fromRGB(255, 215, 0),
    BACKGROUND_COLOR = Color3.fromRGB(255, 250, 252),
    TEXT_COLOR = Color3.fromRGB(50, 50, 50),
    SHADOW_COLOR = Color3.fromRGB(0, 0, 0),
    
    -- UI Sizes
    SHOP_WIDTH = 0.65,
    SHOP_HEIGHT = 0.75,
    CORNER_RADIUS = 12,
    PADDING = 12,
    CARD_SIZE = UDim2.new(0.3, -8, 0.45, -8),
    
    -- Animations
    TWEEN_TIME = 0.3,
    HOVER_SCALE = 1.05,
    CLICK_SCALE = 0.95,
    
    -- DevProduct IDs
    CASH_PRODUCTS = {
        {id = 3366419712, amount = 1000, name = "Starter Pack", icon = "rbxassetid://13471778013"},
        {id = 3366420478, amount = 10000, name = "Value Bundle", icon = "rbxassetid://13471778013", popular = true},
        {id = 3366420800, amount = 25000, name = "Mega Deal", icon = "rbxassetid://13471778013", bestValue = true}
    },
    
    -- Gamepass IDs
    GAMEPASSES = {
        {id = 123456, name = "VIP", icon = "rbxassetid://13471761758", color = Color3.fromRGB(255, 215, 0)},
        {id = 234567, name = "2x Money", icon = "rbxassetid://18910521455", color = Color3.fromRGB(85, 255, 127)},
        {id = 345678, name = "Auto Collect", icon = "rbxassetid://13471768529", color = Color3.fromRGB(135, 206, 250)},
        {id = 456789, name = "Lucky Charm", icon = "rbxassetid://2614987630", color = Color3.fromRGB(255, 105, 180)}
    }
}

-- Asset IDs
local ASSETS = {
    OPEN_SOUND = "rbxassetid://9114221327",
    CLOSE_SOUND = "rbxassetid://9114221646",
    HOVER_SOUND = "rbxassetid://10066936758",
    CLICK_SOUND = "rbxassetid://9113651332",
    PURCHASE_SUCCESS = "rbxassetid://9113654060",
    PURCHASE_FAIL = "rbxassetid://9113653721",
    TAB_SWITCH = "rbxassetid://9113652400",
    
    CLOSE_ICON = "rbxassetid://7072725342",
    CASH_ICON = "rbxassetid://13471778013",
    SHOP_ICON = "rbxassetid://13471761758",
    STAR_ICON = "rbxassetid://2614987630",
    CHECK_ICON = "rbxassetid://10709790704",
    LOCK_ICON = "rbxassetid://10709791437"
}

return {CONFIG = CONFIG, ASSETS = ASSETS}