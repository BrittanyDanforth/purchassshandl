-- TIER 5: LEGENDARY PETS (0.9% drop rate)
PetDatabase["hello_kitty_goddess"] = CreatePet({
    id = "hello_kitty_goddess",
    name = "Goddess Hello Kitty",
    displayName = "Goddess Hello Kitty",
    tier = "Legendary",
    rarity = 5,
    baseValue = 50000,
    baseStats = {
        coins = 5000,
        gems = 50,
        luck = 80,
        speed = 60,
        power = 1000,
        health = 2000,
        defense = 200,
        critRate = 0.40,
        critDamage = 5.0,
        energy = 300,
        stamina = 300
    },
    description = "The divine goddess form of Hello Kitty",
    imageId = "rbxassetid://10000000345",
    modelId = "rbxassetid://10000000346",
    animations = {
        idle = "rbxassetid://10000000347",
        walk = "rbxassetid://10000000348",
        attack = "rbxassetid://10000000349",
        special = "rbxassetid://10000000350",
        ascend = "rbxassetid://10000000351",
        divine_wrath = "rbxassetid://10000000352",
        creation = "rbxassetid://10000000353"
    },
    sounds = {
        spawn = "rbxassetid://10000000354",
        attack = "rbxassetid://10000000355",
        special = "rbxassetid://10000000356",
        divine = "rbxassetid://10000000357",
        universe = "rbxassetid://10000000358"
    },
    abilities = {
        {
            id = "divine_creation",
            name = "Divine Creation",
            description = "Creates a blessed zone that triples all rewards",
            cooldown = 600,
            effect = "blessed_zone",
            value = 3,
            duration = 120,
            radius = 100,
            targetType = "area",
            energyCost = 150,
            level = 1
        },
        {
            id = "goddess_wrath",
            name = "Goddess's Wrath",
            description = "Instantly defeats all enemies below 50% health",
            cooldown = 480,
            effect = "execute_all",
            value = 0.5,
            targetType = "all_enemies",
            energyCost = 120,
            level = 10
        },
        {
            id = "eternal_life",
            name = "Eternal Life",
            description = "Grants immortality to all pets for 20 seconds",
            cooldown = 900,
            effect = "team_immortal",
            value = 1,
            duration = 20,
            targetType = "team",
            energyCost = 200,
            level = 20
        },
        {
            id = "divine_presence",
            name = "Divine Presence",
            description = "All pets gain 100% stats and cannot be debuffed",
            passive = true,
            effect = "divine_aura",
            value = 1,
            level = 25
        },
        {
            id = "miracle",
            name = "Miracle",
            description = "Fully heals and removes all debuffs from team",
            cooldown = 300,
            effect = "miracle",
            value = 1,
            targetType = "team",
            energyCost = 100,
            level = 30
        },
        {
            id = "heavens_gate",
            name = "Heaven's Gate",
            description = "Opens portal that doubles all rewards for 5 minutes",
            cooldown = 1800,
            effect = "heaven_portal",
            value = 2,
            duration = 300,
            targetType = "global",
            energyCost = 250,
            level = 40
        },
        {
            id = "universal_love",
            name = "Universal Love",
            description = "Converts all enemies to allies",
            cooldown = 3600,
            effect = "convert_all",
            value = 1,
            targetType = "all_enemies",
            energyCost = 300,
            level = 50
        }
    },
    evolutionRequirements = nil, -- Max evolution
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = "divine_glow"},
        shiny = {multiplier = 5, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "holy_light"},
        diamond = {multiplier = 20, colorShift = Color3.fromRGB(200, 255, 255), particleEffect = "diamond_shine"},
        rainbow = {multiplier = 50, colorShift = "rainbow", particleEffect = "rainbow_goddess"},
        cosmic = {multiplier = 100, colorShift = "cosmic", particleEffect = "cosmic_deity"},
        omnipotent = {multiplier = 500, colorShift = "omnipotent", particleEffect = "reality_warp"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

PetDatabase["kuromi_demon_lord"] = CreatePet({
    id = "kuromi_demon_lord",
    name = "Demon Lord Kuromi",
    displayName = "Demon Lord Kuromi",
    tier = "Legendary",
    rarity = 5,
    baseValue = 45000,
    baseStats = {
        coins = 4500,
        gems = 45,
        luck = 75,
        speed = 70,
        power = 1200,
        health = 1800,
        defense = 180,
        critRate = 0.45,
        critDamage = 6.0,
        energy = 280,
        stamina = 280
    },
    description = "Ultimate demon lord form of Kuromi",
    imageId = "rbxassetid://10000000359",
    modelId = "rbxassetid://10000000360",
    animations = {
        idle = "rbxassetid://10000000361",
        walk = "rbxassetid://10000000362",
        attack = "rbxassetid://10000000363",
        special = "rbxassetid://10000000364",
        demon_form = "rbxassetid://10000000365",
        apocalypse = "rbxassetid://10000000366",
        throne = "rbxassetid://10000000367"
    },
    sounds = {
        spawn = "rbxassetid://10000000368",
        attack = "rbxassetid://10000000369",
        special = "rbxassetid://10000000370",
        apocalypse = "rbxassetid://10000000371",
        demon_roar = "rbxassetid://10000000372"
    },
    abilities = {
        {
            id = "hells_dominion",
            name = "Hell's Dominion",
            description = "Controls all enemies for 30 seconds",
            cooldown = 600,
            effect = "mind_control",
            value = 1,
            duration = 30,
            targetType = "all_enemies",
            energyCost = 180,
            level = 1
        },
        {
            id = "apocalypse",
            name = "Apocalypse",
            description = "Unleashes devastating attack on all enemies",
            cooldown = 900,
            effect = "apocalypse",
            damage = 5000,
            targetType = "all_enemies",
            energyCost = 250,
            level = 12
        },
        {
            id = "soul_harvest",
            name = "Soul Harvest",
            description = "Instantly defeats enemies and steals their power",
            cooldown = 480,
            effect = "soul_harvest",
            value = 1,
            targetType = "all_enemies",
            energyCost = 200,
            level = 20
        },
        {
            id = "infernal_rage",
            name = "Infernal Rage",
            description = "Each kill permanently increases power by 5%",
            passive = true,
            effect = "kill_stack",
            value = 0.05,
            level = 25
        },
        {
            id = "dark_resurrection",
            name = "Dark Resurrection",
            description = "Revives with 200% stats when defeated",
            passive = true,
            effect = "phoenix",
            value = 2,
            cooldown = 1800,
            level = 32
        },
        {
            id = "demon_kings_throne",
            name = "Demon King's Throne",
            description = "Creates throne that generates massive rewards",
            cooldown = 1200,
            effect = "demon_throne",
            value = 10,
            duration = 180,
            targetType = "location",
            energyCost = 300,
            level = 40
        },
        {
            id = "eternal_darkness",
            name = "Eternal Darkness",
            description = "Plunges world into darkness, weakening all enemies",
            cooldown = 2400,
            effect = "darkness_world",
            enemyDebuff = 0.5,
            allyBuff = 0.5,
            duration = 300,
            targetType = "global",
            energyCost = 400,
            level = 50
        }
    },
    evolutionRequirements = nil, -- Max evolution
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = "demon_aura"},
        infernal = {multiplier = 5, colorShift = Color3.fromRGB(255, 0, 0), particleEffect = "hellfire_crown"},
        void = {multiplier = 20, colorShift = Color3.fromRGB(0, 0, 0), particleEffect = "void_lord"},
        chaos = {multiplier = 50, colorShift = "chaos", particleEffect = "chaos_realm"},
        eternal = {multiplier = 100, colorShift = "eternal", particleEffect = "eternal_torment"},
        omega = {multiplier = 500, colorShift = "omega", particleEffect = "end_times"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

-- TIER 6: MYTHICAL PETS (0.1% drop rate)
PetDatabase["sanrio_universe_guardian"] = CreatePet({
    id = "sanrio_universe_guardian",
    name = "Universe Guardian",
    displayName = "Sanrio Universe Guardian",
    tier = "Mythical",
    rarity = 6,
    baseValue = 500000,
    baseStats = {
        coins = 50000,
        gems = 500,
        luck = 200,
        speed = 100,
        power = 10000,
        health = 20000,
        defense = 1000,
        critRate = 0.80,
        critDamage = 10.0,
        energy = 1000,
        stamina = 1000
    },
    description = "The ultimate protector of the Sanrio Universe",
    imageId = "rbxassetid://10000000373",
    modelId = "rbxassetid://10000000374",
    animations = {
        idle = "rbxassetid://10000000375",
        walk = "rbxassetid://10000000376",
        attack = "rbxassetid://10000000377",
        special = "rbxassetid://10000000378",
        universe = "rbxassetid://10000000379",
        creation = "rbxassetid://10000000380",
        big_bang = "rbxassetid://10000000381"
    },
    sounds = {
        spawn = "rbxassetid://10000000382",
        attack = "rbxassetid://10000000383",
        special = "rbxassetid://10000000384",
        universe = "rbxassetid://10000000385",
        cosmic = "rbxassetid://10000000386"
    },
    abilities = {
        {
            id = "universe_creation",
            name = "Universe Creation",
            description = "Creates a new dimension with 100x rewards",
            cooldown = 3600,
            effect = "dimension_create",
            value = 100,
            duration = 300,
            targetType = "global",
            energyCost = 500,
            level = 1
        },
        {
            id = "time_manipulation",
            name = "Time Manipulation",
            description = "Rewinds time to undo all damage taken",
            cooldown = 1800,
            effect = "time_rewind",
            value = 1,
            targetType = "global",
            energyCost = 300,
            level = 10
        },
        {
            id = "reality_warp",
            name = "Reality Warp",
            description = "Changes the rules of reality temporarily",
            cooldown = 2400,
            effect = "reality_warp",
            value = 1,
            targetType = "global",
            energyCost = 400,
            level = 20
        },
        {
            id = "infinite_power",
            name = "Infinite Power",
            description = "All stats scale infinitely with time",
            passive = true,
            effect = "infinite_scaling",
            value = 0.01,
            level = 25
        },
        {
            id = "guardians_protection",
            name = "Guardian's Protection",
            description = "All pets become invincible",
            passive = true,
            effect = "team_invincible",
            value = 1,
            level = 30
        },
        {
            id = "universal_love",
            name = "Universal Love",
            description = "Converts all enemies to allies permanently",
            cooldown = 7200,
            effect = "convert_all",
            value = 1,
            targetType = "all_enemies",
            energyCost = 600,
            level = 40
        },
        {
            id = "big_bang",
            name = "Big Bang",
            description = "Resets universe and multiplies all resources by 1000",
            cooldown = 86400, -- Once per day
            effect = "big_bang",
            value = 1000,
            targetType = "universe",
            energyCost = 1000,
            level = 50
        },
        {
            id = "omnipresence",
            name = "Omnipresence",
            description = "Exists in all locations simultaneously",
            passive = true,
            effect = "omnipresent",
            value = 1,
            level = 60
        }
    ],
    evolutionRequirements = nil,
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = "universe", particleEffect = "universe_energy"},
        quantum = {multiplier = 10, colorShift = "quantum", particleEffect = "quantum_field"},
        infinity = {multiplier = 100, colorShift = "infinity", particleEffect = "infinite_loop"},
        omnipotent = {multiplier = 1000, colorShift = "omnipotent", particleEffect = "god_rays"},
        absolute = {multiplier = 10000, colorShift = "absolute", particleEffect = "existence_itself"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

-- TIER 7: SECRET PETS (0.01% drop rate)
PetDatabase["sanrio_creator"] = CreatePet({
    id = "sanrio_creator",
    name = "The Creator",
    displayName = "Sanrio Creator",
    tier = "Secret",
    rarity = 7,
    baseValue = 9999999,
    baseStats = {
        coins = 999999,
        gems = 9999,
        luck = 999,
        speed = 999,
        power = 99999,
        health = 99999,
        defense = 9999,
        critRate = 1.0,
        critDamage = 99.9,
        energy = 9999,
        stamina = 9999
    },
    description = "The one who created all Sanrio characters",
    imageId = "rbxassetid://10000000387",
    modelId = "rbxassetid://10000000388",
    animations = {
        idle = "rbxassetid://10000000389",
        walk = "rbxassetid://10000000390",
        attack = "rbxassetid://10000000391",
        special = "rbxassetid://10000000392",
        create = "rbxassetid://10000000393",
        erase = "rbxassetid://10000000394",
        rewrite = "rbxassetid://10000000395"
    },
    sounds = {
        spawn = "rbxassetid://10000000396",
        attack = "rbxassetid://10000000397",
        special = "rbxassetid://10000000398",
        create = "rbxassetid://10000000399",
        omnipotent = "rbxassetid://10000000400"
    },
    abilities = {
        {
            id = "creation",
            name = "Creation",
            description = "Creates any pet at will",
            cooldown = 60,
            effect = "create_pet",
            value = 1,
            targetType = "select",
            energyCost = 0,
            level = 1
        },
        {
            id = "erasure",
            name = "Erasure",
            description = "Erases anything from existence",
            cooldown = 120,
            effect = "erase",
            value = 1,
            targetType = "select",
            energyCost = 0,
            level = 1
        },
        {
            id = "rewrite_reality",
            name = "Rewrite Reality",
            description = "Rewrites the laws of the game",
            cooldown = 3600,
            effect = "rewrite",
            value = 1,
            targetType = "universe",
            energyCost = 0,
            level = 1
        },
        {
            id = "author_authority",
            name = "Author Authority",
            description = "Cannot be affected by any abilities",
            passive = true,
            effect = "absolute_immunity",
            value = 1,
            level = 1
        },
        {
            id = "plot_armor",
            name = "Plot Armor",
            description = "Cannot be defeated",
            passive = true,
            effect = "immortal",
            value = 1,
            level = 1
        },
        {
            id = "deus_ex_machina",
            name = "Deus Ex Machina",
            description = "Solves any problem instantly",
            cooldown = 86400,
            effect = "instant_win",
            value = 1,
            targetType = "situation",
            energyCost = 0,
            level = 1
        },
        {
            id = "the_end",
            name = "The End",
            description = "Ends the current game session with maximum rewards",
            cooldown = 604800, -- Once per week
            effect = "game_end",
            value = 999999,
            targetType = "game",
            energyCost = 0,
            level = 1
        },
        {
            id = "new_beginning",
            name = "New Beginning",
            description = "Starts a new game+ with all progress carried over",
            cooldown = 2592000, -- Once per month
            effect = "new_game_plus",
            value = 1,
            targetType = "game",
            energyCost = 0,
            level = 1
        },
        {
            id = "fourth_wall_break",
            name = "Fourth Wall Break",
            description = "Speaks directly to the player",
            passive = true,
            effect = "fourth_wall",
            value = 1,
            level = 1
        }
    ],
    evolutionRequirements = nil,
    evolvesTo = nil,
    variants = {
        normal = {multiplier = 1, colorShift = "creator", particleEffect = "reality_pencil"},
        true_form = {multiplier = 999999, colorShift = "true_form", particleEffect = "existence_author"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = false,
    giftable = false
})

-- ========================================
-- EGG/CASE SYSTEM
-- ========================================
local EggCases = {
    ["basic"] = {
        id = "basic",
        name = "Basic Egg",
        description = "Common characters with good drop rates",
        price = 100,
        currency = "Coins",
        imageId = "rbxassetid://10000001001",
        modelId = "rbxassetid://10000001002",
        openAnimation = "crack",
        openTime = 3,
        particles = {"basic_sparkles"},
        pets = {
            "hello_kitty_classic",
            "my_melody_classic",
            "keroppi_classic",
            "pochacco_classic",
            "tuxedosam_classic",
            "badtz_maru_classic",
            "hangyodon_classic",
            "pekkle_classic",
            "ahiru_no_pekkle_classic"
        },
        dropRates = {
            ["hello_kitty_classic"] = 15,
            ["my_melody_classic"] = 15,
            ["keroppi_classic"] = 12,
            ["pochacco_classic"] = 12,
            ["tuxedosam_classic"] = 12,
            ["badtz_maru_classic"] = 12,
            ["hangyodon_classic"] = 10,
            ["pekkle_classic"] = 8,
            ["ahiru_no_pekkle_classic"] = 4
        },
        guaranteedRarity = nil,
        pitySystem = {
            enabled = false
        }
    },
    
    ["premium"] = {
        id = "premium",
        name = "Premium Egg",
        description = "Rare characters with better rewards",
        price = 250,
        currency = "Gems",
        imageId = "rbxassetid://10000001003",
        modelId = "rbxassetid://10000001004",
        openAnimation = "golden_crack",
        openTime = 5,
        particles = {"golden_sparkles", "star_burst"},
        pets = {
            "kuromi_classic",
            "cinnamoroll_classic",
            "pompompurin_classic",
            "chococat_classic",
            "monkichi_classic",
            "rururugakuen_classic",
            "u_sa_ha_na_classic",
            "hello_kitty_classic",
            "my_melody_classic"
        },
        dropRates = {
            ["kuromi_classic"] = 20,
            ["cinnamoroll_classic"] = 20,
            ["pompompurin_classic"] = 18,
            ["chococat_classic"] = 15,
            ["monkichi_classic"] = 12,
            ["rururugakuen_classic"] = 8,
            ["u_sa_ha_na_classic"] = 5,
            ["hello_kitty_classic"] = 1,
            ["my_melody_classic"] = 1
        },
        guaranteedRarity = 1,
        pitySystem = {
            enabled = true,
            threshold = 10,
            guaranteedRarity = 2
        }
    },
    
    ["rare"] = {
        id = "rare",
        name = "Rare Egg",
        description = "Rare and epic pets await",
        price = 500,
        currency = "Gems",
        imageId = "rbxassetid://10000001005",
        modelId = "rbxassetid://10000001006",
        openAnimation = "magical_crack",
        openTime = 7,
        particles = {"magic_sparkles", "rare_burst", "star_shower"},
        pets = {
            "gudetama_classic",
            "aggretsuko_classic",
            "kiki_and_lala_classic",
            "dear_daniel_classic",
            "mimmy_classic",
            "kuromi_classic",
            "cinnamoroll_classic"
        },
        dropRates = {
            ["gudetama_classic"] = 25,
            ["aggretsuko_classic"] = 25,
            ["kiki_and_lala_classic"] = 20,
            ["dear_daniel_classic"] = 15,
            ["mimmy_classic"] = 10,
            ["kuromi_classic"] = 3,
            ["cinnamoroll_classic"] = 2
        },
        guaranteedRarity = 2,
        pitySystem = {
            enabled = true,
            threshold = 8,
            guaranteedRarity = 3
        }
    },
    
    ["epic"] = {
        id = "epic",
        name = "Epic Egg",
        description = "Epic pets with amazing powers",
        price = 1000,
        currency = "Gems",
        imageId = "rbxassetid://10000001007",
        modelId = "rbxassetid://10000001008",
        openAnimation = "epic_explosion",
        openTime = 10,
        particles = {"epic_burst", "purple_flames", "magic_circle"},
        pets = {
            "hello_kitty_angel",
            "kuromi_demon",
            "cinnamoroll_celestial",
            "my_melody_angel",
            "pompompurin_chef",
            "gudetama_classic",
            "aggretsuko_classic"
        },
        dropRates = {
            ["hello_kitty_angel"] = 18,
            ["kuromi_demon"] = 18,
            ["cinnamoroll_celestial"] = 18,
            ["my_melody_angel"] = 18,
            ["pompompurin_chef"] = 18,
            ["gudetama_classic"] = 7,
            ["aggretsuko_classic"] = 3
        },
        guaranteedRarity = 3,
        pitySystem = {
            enabled = true,
            threshold = 5,
            guaranteedRarity = 4
        }
    },
    
    ["legendary"] = {
        id = "legendary",
        name = "Legendary Egg",
        description = "Ultra-rare characters with amazing bonuses",
        price = 2500,
        currency = "Gems",
        imageId = "rbxassetid://10000001009",
        modelId = "rbxassetid://10000001010",
        openAnimation = "legendary_explosion",
        openTime = 15,
        particles = {"legendary_explosion", "rainbow_burst", "golden_shower", "divine_light"},
        pets = {
            "hello_kitty_goddess",
            "kuromi_demon_lord",
            "hello_kitty_angel",
            "kuromi_demon",
            "cinnamoroll_celestial"
        },
        dropRates = {
            ["hello_kitty_goddess"] = 15,
            ["kuromi_demon_lord"] = 15,
            ["hello_kitty_angel"] = 30,
            ["kuromi_demon"] = 25,
            ["cinnamoroll_celestial"] = 15
        },
        guaranteedRarity = 4,
        pitySystem = {
            enabled = true,
            threshold = 3,
            guaranteedRarity = 5
        }
    },
    
    ["mythical"] = {
        id = "mythical",
        name = "Mythical Egg",
        description = "The rarest pets in existence",
        price = 10000,
        currency = "Gems",
        imageId = "rbxassetid://10000001011",
        modelId = "rbxassetid://10000001012",
        openAnimation = "mythical_transformation",
        openTime = 20,
        particles = {"void_particles", "cosmic_burst", "reality_shatter", "universe_birth"},
        pets = {
            "sanrio_universe_guardian",
            "hello_kitty_goddess",
            "kuromi_demon_lord"
        },
        dropRates = {
            ["sanrio_universe_guardian"] = 10,
            ["hello_kitty_goddess"] = 45,
            ["kuromi_demon_lord"] = 45
        },
        guaranteedRarity = 5,
        pitySystem = {
            enabled = true,
            threshold = 2,
            guaranteedRarity = 6
        }
    },
    
    ["secret"] = {
        id = "secret",
        name = "??? Egg",
        description = "???",
        price = 999999,
        currency = "Gems",
        imageId = "rbxassetid://10000001013",
        modelId = "rbxassetid://10000001014",
        openAnimation = "secret_reveal",
        openTime = 30,
        particles = {"glitch_particles", "void_tear", "reality_break", "fourth_wall_shatter"},
        pets = {
            "sanrio_creator"
        },
        dropRates = {
            ["sanrio_creator"] = 100
        },
        guaranteedRarity = 7,
        hidden = true,
        requirements = {
            minLevel = 999,
            mustOwn = {"sanrio_universe_guardian"},
            specialCode = true
        }
    },
    
    -- Special Event Eggs
    ["valentine"] = {
        id = "valentine",
        name = "Valentine's Special Egg",
        description = "Limited Valentine's Day exclusive pets",
        price = 5000,
        currency = "Gems",
        imageId = "rbxassetid://10000001015",
        modelId = "rbxassetid://10000001016",
        openAnimation = "heart_explosion",
        openTime = 8,
        particles = {"heart_particles", "pink_sparkles", "love_burst", "cupid_arrows"},
        limitedTime = true,
        availableFrom = "2024-02-01",
        availableUntil = "2024-02-28",
        pets = {
            "hello_kitty_valentine",
            "my_melody_cupid",
            "kuromi_heartbreaker",
            "cinnamoroll_love"
        },
        dropRates = {
            ["hello_kitty_valentine"] = 30,
            ["my_melody_cupid"] = 30,
            ["kuromi_heartbreaker"] = 25,
            ["cinnamoroll_love"] = 15
        },
        guaranteedRarity = 4,
        pitySystem = {
            enabled = true,
            threshold = 5,
            guaranteedRarity = 5
        }
    }
}

-- ========================================
-- GAMEPASS DEFINITIONS
-- ========================================
local GamepassData = {
    [123456] = {
        id = 123456,
        name = "2x Cash Multiplier",
        description = "Double all cash earned from your tycoon!",
        price = 199,
        currency = "Robux",
        icon = "rbxassetid://10000002001",
        benefits = {
            {type = "cash_multiplier", value = 2},
            {type = "vip_badge", value = true}
        },
        permanent = true,
        category = "Multipliers"
    },
    
    [123457] = {
        id = 123457,
        name = "Auto Cash Claimer",
        description = "Automatically collect cash from your tycoon!",
        price = 299,
        currency = "Robux",
        icon = "rbxassetid://10000002002",
        benefits = {
            {type = "auto_collect", value = true},
            {type = "collection_range", value = 100}
        },
        permanent = true,
        category = "Automation"
    },
    
    [123458] = {
        id = 123458,
        name = "VIP Status",
        description = "Exclusive VIP perks and special access!",
        price = 999,
        currency = "Robux",
        icon = "rbxassetid://10000002003",
        benefits = {
            {type = "vip_access", value = true},
            {type = "gem_multiplier", value = 2},
            {type = "coin_multiplier", value = 2},
            {type = "exclusive_area", value = "vip_lounge"},
            {type = "chat_tag", value = "[VIP]"},
            {type = "trade_slots", value = 10},
            {type = "pet_slots", value = 100}
        },
        permanent = true,
        category = "VIP"
    },
    
    [123459] = {
        id = 123459,
        name = "Pet Storage +100",
        description = "Increase your pet inventory by 100 slots!",
        price = 149,
        currency = "Robux",
        icon = "rbxassetid://10000002004",
        benefits = {
            {type = "storage_increase", value = 100}
        },
        permanent = true,
        stackable = true,
        maxStack = 10,
        category = "Storage"
    },
    
    [123460] = {
        id = 123460,
        name = "Lucky Boost",
        description = "Increase rare pet drop rates by 25%!",
        price = 399,
        currency = "Robux",
        icon = "rbxassetid://10000002005",
        benefits = {
            {type = "luck_multiplier", value = 1.25},
            {type = "shiny_chance", value = 1.5},
            {type = "variant_luck", value = 2}
        },
        permanent = true,
        category = "Luck"
    },
    
    [123461] = {
        id = 123461,
        name = "Speed Coil",
        description = "Move 50% faster in your tycoon!",
        price = 99,
        currency = "Robux",
        icon = "rbxassetid://10000002006",
        benefits = {
            {type = "speed_boost", value = 1.5}
        },
        permanent = true,
        category = "Movement"
    },
    
    [123462] = {
        id = 123462,
        name = "Triple Hatch",
        description = "Open 3 eggs at once!",
        price = 599,
        currency = "Robux",
        icon = "rbxassetid://10000002007",
        benefits = {
            {type = "multi_hatch", value = 3}
        },
        permanent = true,
        category = "Hatching"
    }
}

-- ========================================
-- PLAYER DATA MANAGEMENT SYSTEM
-- ========================================
local function GetDefaultPlayerData()
    return {
        -- Basic Info
        userId = 0,
        username = "",
        displayName = "",
        joinDate = os.time(),
        lastSeen = os.time(),
        totalPlayTime = 0,
        
        -- Currencies
        currencies = {
            coins = CONFIG.STARTING_COINS,
            gems = CONFIG.STARTING_GEMS,
            tickets = CONFIG.STARTING_TICKETS,
            candies = 0,
            stars = 0,
            tokens = 0,
            rebirth_tokens = 0
        },
        
        -- Pet Inventory
        pets = {},
        maxPetStorage = CONFIG.MAX_INVENTORY_SIZE,
        equippedPets = {},
        
        -- Statistics
        statistics = {
            totalEggsOpened = 0,
            totalPetsHatched = 0,
            legendaryPetsFound = 0,
            mythicalPetsFound = 0,
            secretPetsFound = 0,
            totalCoinsEarned = 0,
            totalGemsEarned = 0,
            totalGemsSpent = 0,
            highestPetRarity = 0,
            totalPetsSold = 0,
            totalPetsEvolved = 0,
            totalPetsFused = 0,
            
            eggStatistics = {},
            
            tradingStats = {
                tradesCompleted = 0,
                tradesDeclined = 0,
                totalTradeValue = 0,
                scamReports = 0,
                tradePartners = {}
            },
            
            battleStats = {
                wins = 0,
                losses = 0,
                draws = 0,
                damageDealt = 0,
                damageTaken = 0,
                petsDefeated = 0,
                winStreak = 0,
                highestWinStreak = 0
            }
        },
        
        -- Gamepasses
        ownedGamepasses = {},
        
        -- Inventory
        inventory = {
            evolutionItems = {},
            potions = {},
            accessories = {},
            toys = {},
            food = {},
            special = {}
        },
        
        -- Settings
        settings = {
            musicEnabled = true,
            sfxEnabled = true,
            particlesEnabled = true,
            lowQualityMode = false,
            autoSave = true,
            tradeRequests = true,
            friendRequests = true,
            clanInvites = true,
            dmEnabled = true,
            showPetNames = true,
            showDamageNumbers = true,
            uiScale = 1,
            cameraShake = true,
            notifications = true
        },
        
        -- Achievements
        achievements = {},
        titles = {
            equipped = "Newbie",
            owned = {"Newbie"}
        },
        
        -- Daily Rewards
        dailyRewards = {
            lastClaim = 0,
            streak = 0,
            multiplier = 1,
            history = {}
        },
        
        -- Battle Pass
        battlePass = {
            season = 1,
            level = 1,
            experience = 0,
            premiumOwned = false,
            claimedRewards = {},
            questsCompleted = {}
        },
        
        -- Clan/Guild
        clan = {
            id = nil,
            name = nil,
            role = nil,
            contribution = 0,
            joinDate = nil,
            permissions = {}
        },
        
        -- Friends System
        friends = {
            list = {},
            requests = {},
            blocked = {},
            favorites = {}
        },
        
        -- Trading
        trading = {
            history = {},
            favorites = {},
            wishlist = {},
            blacklist = {},
            reputation = 0
        },
        
        -- Quests
        quests = {
            daily = {},
            weekly = {},
            special = {},
            completed = {},
            progress = {}
        },
        
        -- Boosts
        activeBoosts = {},
        
        -- Redeem Codes
        redeemedCodes = {},
        
        -- Warnings & Moderation
        moderation = {
            warnings = 0,
            mutes = {},
            bans = {},
            reports = 0,
            reputation = 100
        },
        
        -- Rebirth System
        rebirth = {
            level = 0,
            totalRebirths = 0,
            bonusMultiplier = 1,
            perks = {}
        },
        
        -- Pet Collection
        petCollection = {},
        
        -- Limited Time
        limitedTimeRewards = {},
        eventProgress = {}
    }
end

local function LoadPlayerData(player)
    local success, data = pcall(function()
        return DataStores.PlayerData:GetAsync(player.UserId)
    end)
    
    if success and data then
        PlayerData[player.UserId] = data
        
        -- Update data structure for any new fields
        local defaultData = GetDefaultPlayerData()
        for key, value in pairs(defaultData) do
            if PlayerData[player.UserId][key] == nil then
                PlayerData[player.UserId][key] = value
            end
        end
        
        -- Deep merge for nested tables
        for key, value in pairs(defaultData) do
            if type(value) == "table" and type(PlayerData[player.UserId][key]) == "table" then
                for subKey, subValue in pairs(value) do
                    if PlayerData[player.UserId][key][subKey] == nil then
                        PlayerData[player.UserId][key][subKey] = subValue
                    end
                end
            end
        end
    else
        PlayerData[player.UserId] = GetDefaultPlayerData()
        PlayerData[player.UserId].userId = player.UserId
        PlayerData[player.UserId].username = player.Name
        PlayerData[player.UserId].displayName = player.DisplayName
    end
    
    -- Load gamepass ownership
    for gamepassId, _ in pairs(GamepassData) do
        spawn(function()
            local hasGamepass = false
            local success, result = pcall(function()
                return Services.MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
            end)
            if success then
                hasGamepass = result
            end
            PlayerData[player.UserId].ownedGamepasses[gamepassId] = hasGamepass
        end)
    end
    
    -- Check group membership
    spawn(function()
        local success, isInGroup = pcall(function()
            return player:IsInGroup(CONFIG.GROUP_ID)
        end)
        if success and isInGroup then
            PlayerData[player.UserId].inGroup = true
            
            -- Get group rank
            local success2, rank = pcall(function()
                return player:GetRankInGroup(CONFIG.GROUP_ID)
            end)
            if success2 then
                PlayerData[player.UserId].groupRank = rank
            end
        end
    end)
    
    -- Track session
    PlayerData[player.UserId].sessionStart = tick()
    
    -- Fire data loaded event
    if RemoteEvents.DataLoaded then
        RemoteEvents.DataLoaded:FireClient(player, PlayerData[player.UserId])
    end
end

local function SavePlayerData(player)
    if PlayerData[player.UserId] then
        -- Update last seen
        PlayerData[player.UserId].lastSeen = os.time()
        
        -- Update play time
        if PlayerData[player.UserId].sessionStart then
            local sessionTime = tick() - PlayerData[player.UserId].sessionStart
            PlayerData[player.UserId].totalPlayTime = PlayerData[player.UserId].totalPlayTime + sessionTime
        end
        
        local success, error = pcall(function()
            DataStores.PlayerData:SetAsync(player.UserId, PlayerData[player.UserId])
        end)
        
        if not success then
            warn("Failed to save data for " .. player.Name .. ": " .. tostring(error))
            
            -- Try backup datastore
            pcall(function()
                DataStores.BackupData:SetAsync(player.UserId .. "_" .. os.time(), PlayerData[player.UserId])
            end)
        end
    end
end

-- ========================================
-- WEIGHTED RANDOM & CASE OPENING SYSTEM
-- ========================================
local function GetWeightedRandomPet(eggType, player)
    local egg = EggCases[eggType]
    if not egg then return nil end
    
    local playerData = PlayerData[player.UserId]
    local luckMultiplier = 1
    
    -- Apply luck multipliers
    if playerData then
        if playerData.ownedGamepasses[123460] then -- Lucky Boost
            luckMultiplier = luckMultiplier * 1.25
        end
        if playerData.inGroup then
            luckMultiplier = luckMultiplier * CONFIG.GROUP_BONUS_MULTIPLIER
        end
        -- Apply pet luck bonuses
        for _, petId in ipairs(playerData.equippedPets or {}) do
            for _, pet in ipairs(playerData.pets) do
                if pet.id == petId then
                    local petData = PetDatabase[pet.petId]
                    if petData and petData.baseStats.luck then
                        luckMultiplier = luckMultiplier * (1 + petData.baseStats.luck / 1000)
                    end
                end
            end
        end
    end
    
    local totalWeight = 0
    for _, weight in pairs(egg.dropRates) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random() * totalWeight / luckMultiplier
    local currentWeight = 0
    
    for petName, weight in pairs(egg.dropRates) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return petName
        end
    end
    
    -- Fallback to first pet
    for petName, _ in pairs(egg.dropRates) do
        return petName
    end
end

local function GenerateCaseItems(eggType, winnerPet)
    local items = {}
    local egg = EggCases[eggType]
    
    -- Generate 100 items for the visual spinner
    for i = 1, 100 do
        if i == 50 then
            -- Place the actual winner at position 50 (center)
            items[i] = winnerPet
        elseif i >= 47 and i <= 53 and i ~= 50 then
            -- Place legendary items near center for psychological effect
            local legendaryPets = {}
            for petName, petData in pairs(PetDatabase) do
                if petData.rarity >= 5 then
                    table.insert(legendaryPets, petData.id)
                end
            end
            if #legendaryPets > 0 then
                items[i] = legendaryPets[math.random(1, #legendaryPets)]
            else
                items[i] = GetWeightedRandomPet(eggType, nil)
            end
        else
            -- Random pets for other positions
            items[i] = GetWeightedRandomPet(eggType, nil)
        end
    end
    
    return items
end

local function OpenCase(player, eggType)
    -- Rate limit check
    local canProceed, errorMsg = RateLimiter:Check(player, "OpenCase")
    if not canProceed then
        return {success = false, error = errorMsg}
    end
    
    local playerData = PlayerData[player.UserId]
    if not playerData then return {success = false, error = "No player data"} end
    
    local egg = EggCases[eggType]
    if not egg then return {success = false, error = "Invalid egg type"} end
    
    -- Check if egg is available (for limited time eggs)
    if egg.limitedTime then
        local currentDate = os.date("*t")
        local currentDateString = string.format("%04d-%02d-%02d", currentDate.year, currentDate.month, currentDate.day)
        if currentDateString < egg.availableFrom or currentDateString > egg.availableUntil then
            return {success = false, error = "This egg is not available right now"}
        end
    end
    
    -- Check requirements
    if egg.requirements then
        if egg.requirements.minLevel and playerData.rebirth.level < egg.requirements.minLevel then
            return {success = false, error = "You need to be rebirth level " .. egg.requirements.minLevel}
        end
        if egg.requirements.mustOwn then
            for _, requiredPet in ipairs(egg.requirements.mustOwn) do
                local hasPet = false
                for _, pet in ipairs(playerData.pets) do
                    if pet.petId == requiredPet then
                        hasPet = true
                        break
                    end
                end
                if not hasPet then
                    return {success = false, error = "You need to own " .. requiredPet .. " first"}
                end
            end
        end
    end
    
    -- Check currency
    local currencyType = string.lower(egg.currency)
    if not playerData.currencies[currencyType] or playerData.currencies[currencyType] < egg.price then
        return {success = false, error = "Not enough " .. egg.currency}
    end
    
    -- Multi-hatch check
    local hatchCount = 1
    if playerData.ownedGamepasses[123462] then -- Triple Hatch
        hatchCount = 3
    end
    
    -- Deduct currency
    local totalCost = egg.price * hatchCount
    if playerData.currencies[currencyType] < totalCost then
        hatchCount = math.floor(playerData.currencies[currencyType] / egg.price)
        totalCost = egg.price * hatchCount
    end
    
    -- Wealth check
    local wealthCheck, wealthError = RateLimiter:CheckWealth(player, currencyType, totalCost)
    if not wealthCheck then
        return {success = false, error = wealthError}
    end
    
    playerData.currencies[currencyType] = playerData.currencies[currencyType] - totalCost
    
    local results = {}
    
    for h = 1, hatchCount do
        -- Check pity system
        if egg.pitySystem and egg.pitySystem.enabled then
            if not playerData.statistics.eggStatistics[eggType] then
                playerData.statistics.eggStatistics[eggType] = {
                    opened = 0,
                    sinceLastRare = 0
                }
            end
            
            playerData.statistics.eggStatistics[eggType].sinceLastRare = 
                playerData.statistics.eggStatistics[eggType].sinceLastRare + 1
        end
        
        -- Determine winner
        local winnerPet = GetWeightedRandomPet(eggType, player)
        
        -- Apply pity system
        if egg.pitySystem and egg.pitySystem.enabled then
            if playerData.statistics.eggStatistics[eggType].sinceLastRare >= egg.pitySystem.threshold then
                -- Force a rare pet
                local rarePets = {}
                for petId, _ in pairs(egg.dropRates) do
                    local petData = PetDatabase[petId]
                    if petData and petData.rarity >= egg.pitySystem.guaranteedRarity then
                        table.insert(rarePets, petId)
                    end
                end
                if #rarePets > 0 then
                    winnerPet = rarePets[math.random(1, #rarePets)]
                    playerData.statistics.eggStatistics[eggType].sinceLastRare = 0
                end
            end
        end
        
        local petData = PetDatabase[winnerPet]
        if not petData then
            return {success = false, error = "Invalid pet data"}
        end
        
        -- Reset pity counter if rare pet
        if egg.pitySystem and egg.pitySystem.enabled and petData.rarity >= egg.pitySystem.guaranteedRarity then
            playerData.statistics.eggStatistics[eggType].sinceLastRare = 0
        end
        
        -- Generate case items with winner at center
        local caseItems = GenerateCaseItems(eggType, winnerPet)
        
        -- Determine variant
        local variant = "normal"
        local variantRoll = math.random()
        
        -- Apply variant chances
        local shinyChance = CONFIG.SHINY_CHANCE
        local goldenChance = CONFIG.GOLDEN_CHANCE
        local rainbowChance = CONFIG.RAINBOW_CHANCE
        local darkMatterChance = CONFIG.DARK_MATTER_CHANCE
        
        -- Apply multipliers
        if playerData.ownedGamepasses[123460] then -- Lucky Boost
            shinyChance = shinyChance * 1.5
            goldenChance = goldenChance * 1.5
            rainbowChance = rainbowChance * 1.5
            darkMatterChance = darkMatterChance * 1.5
        end
        
        if variantRoll < darkMatterChance then
            variant = "dark_matter"
        elseif variantRoll < rainbowChance then
            variant = "rainbow"
        elseif variantRoll < goldenChance then
            variant = "golden"
        elseif variantRoll < shinyChance then
            variant = "shiny"
        end
        
        -- Special variants for specific pets
        if petData.variants[variant] == nil then
            variant = "normal"
        end
        
        -- Create pet instance
        local petInstance = {
            id = Services.HttpService:GenerateGUID(false),
            petId = petData.id,
            name = petData.name,
            displayName = petData.displayName,
            level = 1,
            experience = 0,
            variant = variant,
            owner = player.UserId,
            obtained = os.time(),
            source = "egg_" .. eggType,
            equipped = false,
            locked = false,
            nickname = nil,
            stats = {}
        }
        
        -- Copy base stats and apply variant multiplier
        for stat, value in pairs(petData.baseStats) do
            petInstance.stats[stat] = value
            if petData.variants[variant] then
                local multiplier = petData.variants[variant].multiplier
                petInstance.stats[stat] = math.floor(value * multiplier)
            end
        end
        
        -- Apply rebirth bonuses
        if playerData.rebirth.level > 0 then
            local rebirthMultiplier = 1 + (playerData.rebirth.level * CONFIG.REBIRTH_BONUS_PER_LEVEL)
            for stat, value in pairs(petInstance.stats) do
                petInstance.stats[stat] = math.floor(value * rebirthMultiplier)
            end
        end
        
        -- Add to inventory
        table.insert(playerData.pets, petInstance)
        
        -- Update pet collection
        if not playerData.petCollection[petData.id] then
            playerData.petCollection[petData.id] = {
                discovered = true,
                firstObtained = os.time(),
                totalObtained = 0,
                variants = {}
            }
        end
        playerData.petCollection[petData.id].totalObtained = 
            playerData.petCollection[petData.id].totalObtained + 1
        playerData.petCollection[petData.id].variants[variant] = true
        
        -- Update statistics
        playerData.statistics.totalEggsOpened = playerData.statistics.totalEggsOpened + 1
        playerData.statistics.totalPetsHatched = playerData.statistics.totalPetsHatched + 1
        
        if egg.currency == "Gems" then
            playerData.statistics.totalGemsSpent = playerData.statistics.totalGemsSpent + egg.price
        end
        
        if petData.rarity >= 5 then
            playerData.statistics.legendaryPetsFound = playerData.statistics.legendaryPetsFound + 1
        end
        if petData.rarity >= 6 then
            playerData.statistics.mythicalPetsFound = playerData.statistics.mythicalPetsFound + 1
        end
        if petData.rarity >= 7 then
            playerData.statistics.secretPetsFound = playerData.statistics.secretPetsFound + 1
        end
        
        if petData.rarity > playerData.statistics.highestPetRarity then
            playerData.statistics.highestPetRarity = petData.rarity
        end
        
        table.insert(results, {
            pet = petInstance,
            petData = petData,
            variant = variant,
            caseItems = caseItems
        })
        
        -- Log analytics
        ServerAnalytics:LogEvent("PetHatched", player, {
            egg = eggType,
            pet = petData.id,
            variant = variant,
            rarity = petData.rarity
        })
    end
    
    -- Save data
    SavePlayerData(player)
    
    -- Fire client event
    if RemoteEvents.CaseOpened then
        RemoteEvents.CaseOpened:FireClient(player, {
            success = true,
            results = results,
            newBalance = playerData.currencies[currencyType]
        })
    end
    
    return {
        success = true,
        results = results,
        newBalance = playerData.currencies[currencyType]
    }
end

-- Continue in Part 4...