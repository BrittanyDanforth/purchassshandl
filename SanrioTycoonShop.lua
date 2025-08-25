-- 🎀 Sanrio Tycoon Shop System
-- Complete shop system with gamepasses, currencies, and items

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 💰 CURRENCY CONFIGURATION
local CURRENCIES = {
    Coins = {
        Name = "Coins",
        Symbol = "🪙",
        StartingAmount = 500,
        Color = Color3.fromRGB(255, 215, 0)
    },
    Gems = {
        Name = "Gems",
        Symbol = "💎",
        StartingAmount = 10,
        Color = Color3.fromRGB(147, 51, 234)
    },
    Hearts = {
        Name = "Hearts",
        Symbol = "💖",
        StartingAmount = 0,
        Color = Color3.fromRGB(255, 192, 203)
    }
}

-- 🎮 GAMEPASS CONFIGURATION
local GAMEPASSES = {
    -- Essential Passes
    {
        Name = "🌟 VIP Pass",
        GamepassId = 123456789, -- Replace with your gamepass ID
        Price = 399,
        Category = "Premium",
        Benefits = {
            "2x Coins from all sources",
            "1.5x Gems from daily rewards",
            "Exclusive VIP shop area",
            "VIP chat tag & title",
            "10% discount on all shop items",
            "Extra daily reward spins",
            "Unlock VIP-only Sanrio characters"
        },
        Icon = "rbxassetid://VIPICON"
    },
    
    -- Automation Passes
    {
        Name = "🤖 Auto Collect",
        GamepassId = 123456790,
        Price = 199,
        Category = "Automation",
        Benefits = {
            "Automatically collect customer payments",
            "Auto-clean tables",
            "No need to click on finished orders"
        },
        Icon = "rbxassetid://AUTOCOLLECTICON"
    },
    
    {
        Name = "⚡ Instant Restock",
        GamepassId = 123456791,
        Price = 299,
        Category = "Automation",
        Benefits = {
            "Instantly restock all machines",
            "Never run out of supplies",
            "One-click refill all stations"
        },
        Icon = "rbxassetid://RESTOCKICON"
    },
    
    -- Multiplier Passes
    {
        Name = "💰 2x Coins Forever",
        GamepassId = 123456792,
        Price = 499,
        Category = "Multipliers",
        Benefits = {
            "Permanent 2x coin multiplier",
            "Stacks with VIP and boosts"
        },
        Icon = "rbxassetid://2XCOINSICON"
    },
    
    {
        Name = "💎 2x Gems Forever",
        GamepassId = 123456793,
        Price = 699,
        Category = "Multipliers",
        Benefits = {
            "Permanent 2x gem multiplier",
            "Double gems from all sources"
        },
        Icon = "rbxassetid://2XGEMSICON"
    },
    
    -- Fun Passes
    {
        Name = "🎵 Jukebox Pass",
        GamepassId = 123456794,
        Price = 149,
        Category = "Fun",
        Benefits = {
            "Play custom music in your cafe",
            "Access to Sanrio soundtrack",
            "DJ booth decoration"
        },
        Icon = "rbxassetid://JUKEBOXICON"
    },
    
    {
        Name = "🌈 Rainbow Trail",
        GamepassId = 123456795,
        Price = 99,
        Category = "Fun",
        Benefits = {
            "Colorful rainbow trail effect",
            "Sparkle particles when walking"
        },
        Icon = "rbxassetid://RAINBOWICON"
    }
}

-- 🛍️ SHOP ITEMS CONFIGURATION
local SHOP_SECTIONS = {
    -- BOOSTS SECTION
    Boosts = {
        {
            Name = "2x Coins - 10 Minutes",
            ItemId = "boost_2x_coins_10m",
            Price = {Currency = "Gems", Amount = 10},
            Duration = 600, -- seconds
            Effect = {Type = "CoinMultiplier", Value = 2},
            Icon = "rbxassetid://COIN2XICON",
            Description = "Double your coin earnings!"
        },
        {
            Name = "2x Coins - 1 Hour",
            ItemId = "boost_2x_coins_1h",
            Price = {Currency = "Gems", Amount = 40},
            Duration = 3600,
            Effect = {Type = "CoinMultiplier", Value = 2},
            Icon = "rbxassetid://COIN2XICON",
            Description = "Double coins for a full hour!"
        },
        {
            Name = "3x Coins - 10 Minutes",
            ItemId = "boost_3x_coins_10m",
            Price = {Currency = "Gems", Amount = 25},
            Duration = 600,
            Effect = {Type = "CoinMultiplier", Value = 3},
            Icon = "rbxassetid://COIN3XICON",
            Description = "Triple your profits!"
        },
        {
            Name = "Speed Boost - 30 Minutes",
            ItemId = "boost_speed_30m",
            Price = {Currency = "Gems", Amount = 15},
            Duration = 1800,
            Effect = {Type = "Speed", Value = 2},
            Icon = "rbxassetid://SPEEDICON",
            Description = "Move 2x faster!"
        },
        {
            Name = "Lucky Boost - 20 Minutes",
            ItemId = "boost_lucky_20m",
            Price = {Currency = "Gems", Amount = 30},
            Duration = 1200,
            Effect = {Type = "Lucky", Value = 2},
            Icon = "rbxassetid://LUCKYICON",
            Description = "2x chance for rare items & tips!"
        }
    },
    
    -- INSTANT ACTIONS
    InstantActions = {
        {
            Name = "Quick Serve All",
            ItemId = "instant_serve",
            Price = {Currency = "Gems", Amount = 50},
            Type = "Instant",
            Icon = "rbxassetid://SERVEICON",
            Description = "Instantly serve all ready orders!"
        },
        {
            Name = "Quick Stock All",
            ItemId = "instant_stock",
            Price = {Currency = "Gems", Amount = 50},
            Type = "Instant",
            Icon = "rbxassetid://STOCKICON",
            Description = "Fill all machines to max capacity!"
        },
        {
            Name = "Skip Wait Time",
            ItemId = "skip_wait",
            Price = {Currency = "Gems", Amount = 20},
            Type = "Instant",
            Icon = "rbxassetid://SKIPICON",
            Description = "Skip all cooking timers!"
        },
        {
            Name = "Instant Clean",
            ItemId = "instant_clean",
            Price = {Currency = "Gems", Amount = 10},
            Type = "Instant",
            Icon = "rbxassetid://CLEANICON",
            Description = "Clean all dirty tables instantly!"
        }
    },
    
    -- WORKERS/HELPERS
    Workers = {
        {
            Name = "Hello Kitty Helper",
            ItemId = "helper_hellokitty",
            Price = {Currency = "Coins", Amount = 10000},
            Type = "Worker",
            Stats = {Speed = 1.2, Efficiency = 1.5},
            Icon = "rbxassetid://HELLOKITTYICON",
            Description = "Hello Kitty helps serve customers!"
        },
        {
            Name = "My Melody Chef",
            ItemId = "helper_mymelody",
            Price = {Currency = "Coins", Amount = 15000},
            Type = "Worker",
            Stats = {CookSpeed = 2, Quality = 1.3},
            Icon = "rbxassetid://MYMELODYICON",
            Description = "My Melody cooks food faster!"
        },
        {
            Name = "Kuromi Cleaner",
            ItemId = "helper_kuromi",
            Price = {Currency = "Coins", Amount = 8000},
            Type = "Worker",
            Stats = {CleanSpeed = 3},
            Icon = "rbxassetid://KUROMIICON",
            Description = "Kuromi keeps tables spotless!"
        },
        {
            Name = "Pompompurin Cashier",
            ItemId = "helper_pompompurin",
            Price = {Currency = "Coins", Amount = 20000},
            Type = "Worker",
            Stats = {TipBonus = 1.5, CustomerPatience = 1.2},
            Icon = "rbxassetid://POMPOMPURINICON",
            Description = "Pompompurin brings in bigger tips!"
        }
    },
    
    -- DECORATIONS
    Decorations = {
        -- Floors
        {
            Name = "Pink Checkered Floor",
            ItemId = "floor_pink_checker",
            Price = {Currency = "Coins", Amount = 5000},
            Type = "Floor",
            Category = "Floors",
            Icon = "rbxassetid://PINKFLOORICON"
        },
        {
            Name = "Rainbow Floor",
            ItemId = "floor_rainbow",
            Price = {Currency = "Coins", Amount = 8000},
            Type = "Floor",
            Category = "Floors",
            Icon = "rbxassetid://RAINBOWFLOORICON"
        },
        {
            Name = "Cloud Floor",
            ItemId = "floor_cloud",
            Price = {Currency = "Gems", Amount = 100},
            Type = "Floor",
            Category = "Floors",
            Icon = "rbxassetid://CLOUDFLOORICON"
        },
        
        -- Walls
        {
            Name = "Sanrio Wallpaper",
            ItemId = "wall_sanrio",
            Price = {Currency = "Coins", Amount = 6000},
            Type = "Wall",
            Category = "Walls",
            Icon = "rbxassetid://SANRIOWALLICON"
        },
        {
            Name = "Starry Night Wall",
            ItemId = "wall_starry",
            Price = {Currency = "Gems", Amount = 80},
            Type = "Wall",
            Category = "Walls",
            Icon = "rbxassetid://STARRYWALLICON"
        },
        
        -- Furniture
        {
            Name = "Hello Kitty Table Set",
            ItemId = "furniture_hk_table",
            Price = {Currency = "Coins", Amount = 3000},
            Type = "Furniture",
            Category = "Tables",
            Seats = 4,
            Icon = "rbxassetid://HKTABLEICON"
        },
        {
            Name = "Cinnamoroll Booth",
            ItemId = "furniture_cinna_booth",
            Price = {Currency = "Coins", Amount = 5000},
            Type = "Furniture",
            Category = "Booths",
            Seats = 6,
            Icon = "rbxassetid://CINNABOOTHICON"
        },
        {
            Name = "Giant Plushie Display",
            ItemId = "furniture_plushie_display",
            Price = {Currency = "Gems", Amount = 150},
            Type = "Furniture",
            Category = "Decorations",
            Icon = "rbxassetid://PLUSHIEICON"
        }
    },
    
    -- UPGRADES
    Upgrades = {
        {
            Name = "Expand Cafe Size",
            ItemId = "upgrade_expand",
            Price = {Currency = "Coins", Amount = 50000},
            Type = "Upgrade",
            Level = 1,
            MaxLevel = 5,
            Icon = "rbxassetid://EXPANDICON",
            Description = "Make your cafe 25% bigger!"
        },
        {
            Name = "Faster Cooking",
            ItemId = "upgrade_cookspeed",
            Price = {Currency = "Coins", Amount = 10000},
            Type = "Upgrade",
            Level = 1,
            MaxLevel = 10,
            Multiplier = 1.1,
            Icon = "rbxassetid://COOKSPEEDICON",
            Description = "Cook 10% faster per level"
        },
        {
            Name = "Customer Patience",
            ItemId = "upgrade_patience",
            Price = {Currency = "Coins", Amount = 8000},
            Type = "Upgrade",
            Level = 1,
            MaxLevel = 10,
            Multiplier = 1.15,
            Icon = "rbxassetid://PATIENCEICON",
            Description = "Customers wait 15% longer"
        },
        {
            Name = "Tip Multiplier",
            ItemId = "upgrade_tips",
            Price = {Currency = "Coins", Amount = 15000},
            Type = "Upgrade",
            Level = 1,
            MaxLevel = 8,
            Multiplier = 1.25,
            Icon = "rbxassetid://TIPICON",
            Description = "Get 25% more tips per level"
        }
    },
    
    -- GACHA/LOOTBOXES
    Gacha = {
        {
            Name = "Basic Character Box",
            ItemId = "gacha_basic",
            Price = {Currency = "Coins", Amount = 5000},
            Type = "Lootbox",
            Icon = "rbxassetid://BASICBOXICON",
            Rewards = {
                {Item = "character_common", Chance = 70},
                {Item = "character_rare", Chance = 25},
                {Item = "character_epic", Chance = 5}
            }
        },
        {
            Name = "Premium Character Box",
            ItemId = "gacha_premium",
            Price = {Currency = "Gems", Amount = 100},
            Type = "Lootbox",
            Icon = "rbxassetid://PREMIUMBOXICON",
            Rewards = {
                {Item = "character_rare", Chance = 50},
                {Item = "character_epic", Chance = 35},
                {Item = "character_legendary", Chance = 15}
            }
        },
        {
            Name = "Decoration Mystery Box",
            ItemId = "gacha_decor",
            Price = {Currency = "Coins", Amount = 3000},
            Type = "Lootbox",
            Icon = "rbxassetid://DECORBOXICON",
            Rewards = {
                {Item = "decor_common", Chance = 60},
                {Item = "decor_rare", Chance = 30},
                {Item = "decor_epic", Chance = 10}
            }
        }
    },
    
    -- REBIRTH/PRESTIGE SHOP
    Prestige = {
        {
            Name = "Golden Spatula",
            ItemId = "prestige_golden_spatula",
            Price = {Currency = "Hearts", Amount = 10},
            Type = "Prestige",
            Requirement = "Rebirth 1+",
            Effect = {CookSpeed = 2},
            Icon = "rbxassetid://GOLDENSPATULAICON",
            Description = "2x cooking speed forever!"
        },
        {
            Name = "Diamond Tables",
            ItemId = "prestige_diamond_tables",
            Price = {Currency = "Hearts", Amount = 25},
            Type = "Prestige",
            Requirement = "Rebirth 3+",
            Effect = {CustomerCapacity = 2},
            Icon = "rbxassetid://DIAMONDTABLEICON",
            Description = "Double customer capacity!"
        },
        {
            Name = "Eternal VIP",
            ItemId = "prestige_eternal_vip",
            Price = {Currency = "Hearts", Amount = 50},
            Type = "Prestige",
            Requirement = "Rebirth 5+",
            Effect = {PermanentVIP = true},
            Icon = "rbxassetid://ETERNALVIPICON",
            Description = "VIP benefits across all rebirths!"
        },
        {
            Name = "Mythic Multiplier",
            ItemId = "prestige_mythic_multi",
            Price = {Currency = "Hearts", Amount = 100},
            Type = "Prestige",
            Requirement = "Rebirth 10+",
            Effect = {GlobalMultiplier = 5},
            Icon = "rbxassetid://MYTHICICON",
            Description = "5x all earnings permanently!"
        }
    },
    
    -- LIMITED TIME OFFERS
    LimitedOffers = {
        {
            Name = "Starter Pack",
            ItemId = "pack_starter",
            Price = {Currency = "Robux", Amount = 99},
            Type = "Bundle",
            OneTimePurchase = true,
            Icon = "rbxassetid://STARTERPACKICON",
            Contents = {
                {Type = "Gems", Amount = 100},
                {Type = "Coins", Amount = 25000},
                {Type = "Worker", ItemId = "helper_hellokitty"},
                {Type = "Boost", ItemId = "boost_2x_coins_1h", Quantity = 3}
            },
            Description = "Best value for new players!"
        },
        {
            Name = "Mega Bundle",
            ItemId = "pack_mega",
            Price = {Currency = "Robux", Amount = 499},
            Type = "Bundle",
            OneTimePurchase = true,
            Icon = "rbxassetid://MEGABUNDLEICON",
            Contents = {
                {Type = "Gems", Amount = 1000},
                {Type = "Coins", Amount = 250000},
                {Type = "Hearts", Amount = 10},
                {Type = "Worker", ItemId = "helper_all", Quantity = 4},
                {Type = "Gamepass", ItemId = "vip_30days"}
            },
            Description = "Ultimate value pack!"
        }
    }
}

-- 💎 SPECIAL FEATURES
local SPECIAL_FEATURES = {
    -- Daily Rewards
    DailyRewards = {
        {Day = 1, Reward = {Coins = 1000}},
        {Day = 2, Reward = {Coins = 2000}},
        {Day = 3, Reward = {Gems = 10}},
        {Day = 4, Reward = {Coins = 5000}},
        {Day = 5, Reward = {Gems = 25}},
        {Day = 6, Reward = {Coins = 10000}},
        {Day = 7, Reward = {Gems = 50, Hearts = 1}},
        -- Reset to day 1 after day 7
    },
    
    -- Spin Wheel
    SpinWheel = {
        Cost = {Currency = "Gems", Amount = 10},
        VIPFreeSpins = 1, -- per day
        Rewards = {
            {Type = "Coins", Amount = 1000, Weight = 30},
            {Type = "Coins", Amount = 5000, Weight = 20},
            {Type = "Coins", Amount = 10000, Weight = 10},
            {Type = "Gems", Amount = 5, Weight = 15},
            {Type = "Gems", Amount = 10, Weight = 10},
            {Type = "Gems", Amount = 25, Weight = 5},
            {Type = "Boost", ItemId = "boost_2x_coins_10m", Weight = 8},
            {Type = "Worker", ItemId = "helper_random", Weight = 2}
        }
    },
    
    -- Quest/Achievement Rewards
    Achievements = {
        {
            Name = "First Customer",
            Id = "achievement_first_customer",
            Reward = {Coins = 500},
            Icon = "rbxassetid://FIRSTCUSTOMERICON"
        },
        {
            Name = "Serve 100 Customers",
            Id = "achievement_100_customers",
            Reward = {Coins = 5000, Gems = 10},
            Icon = "rbxassetid://100CUSTOMERICON"
        },
        {
            Name = "Earn 1 Million Coins",
            Id = "achievement_1m_coins",
            Reward = {Gems = 100, Hearts = 1},
            Icon = "rbxassetid://1MCOINSICON"
        }
    }
}

print("🎀 Sanrio Tycoon Shop System Loaded!")
print("Features: Gamepasses, Multi-currency, Boosts, Workers, Decorations, Gacha, Prestige!")

return {
    Currencies = CURRENCIES,
    Gamepasses = GAMEPASSES,
    ShopSections = SHOP_SECTIONS,
    SpecialFeatures = SPECIAL_FEATURES
}