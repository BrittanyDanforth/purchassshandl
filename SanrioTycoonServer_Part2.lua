-- TIER 3: RARE PETS (15% drop rate)
PetDatabase["gudetama_classic"] = CreatePet({
    id = "gudetama_classic",
    name = "Classic Gudetama",
    displayName = "Gudetama",
    tier = "Rare",
    rarity = 3,
    baseValue = 1200,
    baseStats = {
        coins = 600,
        gems = 10,
        luck = 30,
        speed = 5,
        power = 100,
        health = 400,
        defense = 50,
        critRate = 0.05,
        critDamage = 3.0,
        energy = 50,
        stamina = 200
    },
    description = "Lazy egg who just wants to be left alone",
    imageId = "rbxassetid://10000000211",
    modelId = "rbxassetid://10000000212",
    animations = {
        idle = "rbxassetid://10000000213",
        walk = "rbxassetid://10000000214",
        attack = "rbxassetid://10000000215",
        special = "rbxassetid://10000000216",
        lazy = "rbxassetid://10000000217",
        yawn = "rbxassetid://10000000218",
        flop = "rbxassetid://10000000219"
    },
    sounds = {
        spawn = "rbxassetid://10000000220",
        attack = "rbxassetid://10000000221",
        special = "rbxassetid://10000000222",
        yawn = "rbxassetid://10000000223",
        sigh = "rbxassetid://10000000224"
    },
    abilities = {
        {
            id = "lazy_shield",
            name = "Lazy Shield",
            description = "Too lazy to take damage - blocks 50% damage",
            passive = true,
            effect = "damage_reduction",
            value = 0.5,
            level = 1
        },
        {
            id = "egg_sistential_crisis",
            name = "Egg-sistential Crisis",
            description = "Confuses all enemies for 5 seconds",
            cooldown = 60,
            effect = "confuse_all",
            value = 5,
            targetType = "all_enemies",
            energyCost = 20,
            level = 10
        },
        {
            id = "cant_be_bothered",
            name = "Can't Be Bothered",
            description = "Immune to all debuffs",
            passive = true,
            effect = "debuff_immunity",
            value = 1,
            level = 20
        },
        {
            id = "lazy_luck",
            name = "Lazy Luck",
            description = "30% chance to dodge any attack",
            passive = true,
            effect = "dodge_chance",
            value = 0.3,
            level = 25
        },
        {
            id = "ultimate_laziness",
            name = "Ultimate Laziness",
            description = "Sleeps for 10 seconds, then deals massive damage",
            cooldown = 180,
            effect = "sleep_burst",
            sleepDuration = 10,
            damage = 1000,
            radius = 50,
            targetType = "self",
            energyCost = 10,
            level = 40
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 6000,
        items = {"egg_shell", "bacon_strip", "lazy_essence"},
        napsToken = 500
    },
    evolvesTo = "gudetama_supreme",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "egg_sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        scrambled = {multiplier = 35, colorShift = Color3.fromRGB(255, 255, 150), particleEffect = "yolk_drip"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["aggretsuko_classic"] = CreatePet({
    id = "aggretsuko_classic",
    name = "Classic Aggretsuko",
    displayName = "Aggretsuko",
    tier = "Rare",
    rarity = 3,
    baseValue = 1050,
    baseStats = {
        coins = 520,
        gems = 8,
        luck = 22,
        speed = 28,
        power = 180,
        health = 200,
        defense = 25,
        critRate = 0.25,
        critDamage = 2.8,
        energy = 100,
        stamina = 100
    },
    description = "Red panda office worker with rage issues",
    imageId = "rbxassetid://10000000225",
    modelId = "rbxassetid://10000000226",
    animations = {
        idle = "rbxassetid://10000000227",
        walk = "rbxassetid://10000000228",
        attack = "rbxassetid://10000000229",
        special = "rbxassetid://10000000230",
        rage = "rbxassetid://10000000231",
        scream = "rbxassetid://10000000232",
        office_work = "rbxassetid://10000000233"
    },
    sounds = {
        spawn = "rbxassetid://10000000234",
        attack = "rbxassetid://10000000235",
        special = "rbxassetid://10000000236",
        rage = "rbxassetid://10000000237",
        metal_scream = "rbxassetid://10000000238"
    },
    abilities = {
        {
            id = "rage_mode",
            name = "Rage Mode",
            description = "Doubles all stats when below 50% health",
            passive = true,
            effect = "rage_trigger",
            value = 2,
            threshold = 0.5,
            level = 1
        },
        {
            id = "death_metal_scream",
            name = "Death Metal Scream",
            description = "Stuns all enemies and deals massive damage",
            cooldown = 180,
            effect = "scream_stun",
            value = 500,
            stun_duration = 3,
            radius = 40,
            targetType = "all_enemies",
            energyCost = 60,
            level = 15
        },
        {
            id = "office_fury",
            name = "Office Fury",
            description = "Gains power from stress (time-based)",
            passive = true,
            effect = "time_scaling",
            value = 0.02,
            level = 20
        },
        {
            id = "microphone_drop",
            name = "Microphone Drop",
            description = "Creates shockwave dealing area damage",
            cooldown = 90,
            effect = "shockwave",
            value = 300,
            radius = 40,
            targetType = "location",
            energyCost = 40,
            level = 30
        },
        {
            id = "karaoke_night",
            name = "Karaoke Night",
            description = "Switches between calm and rage, gaining different buffs",
            cooldown = 120,
            effect = "mode_switch",
            calmBonus = {defense = 2, health = 2},
            rageBonus = {power = 2, critRate = 0.5},
            duration = 60,
            targetType = "self",
            energyCost = 50,
            level = 45
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 6500,
        items = {"microphone", "office_badge", "rage_essence"},
        rageOuts = 100
    },
    evolvesTo = "aggretsuko_metalhead",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 100, 100), particleEffect = "rage_sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        metal = {multiplier = 45, colorShift = Color3.fromRGB(50, 50, 50), particleEffect = "metal_sparks"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["kiki_and_lala_classic"] = CreatePet({
    id = "kiki_and_lala_classic",
    name = "Classic Kiki & Lala",
    displayName = "Little Twin Stars",
    tier = "Rare",
    rarity = 3,
    baseValue = 1100,
    baseStats = {
        coins = 550,
        gems = 9,
        luck = 25,
        speed = 20,
        power = 120,
        health = 220,
        defense = 30,
        critRate = 0.18,
        critDamage = 2.2,
        energy = 110,
        stamina = 110
    },
    description = "The Little Twin Stars from the starry sky",
    imageId = "rbxassetid://10000000239",
    modelId = "rbxassetid://10000000240",
    animations = {
        idle = "rbxassetid://10000000241",
        walk = "rbxassetid://10000000242",
        attack = "rbxassetid://10000000243",
        special = "rbxassetid://10000000244",
        float = "rbxassetid://10000000245",
        star_dance = "rbxassetid://10000000246"
    },
    sounds = {
        spawn = "rbxassetid://10000000247",
        attack = "rbxassetid://10000000248",
        special = "rbxassetid://10000000249",
        twinkle = "rbxassetid://10000000250"
    },
    abilities = {
        {
            id = "twin_bond",
            name = "Twin Bond",
            description = "Shares damage and healing between twins",
            passive = true,
            effect = "damage_share",
            value = 0.5,
            level = 1
        },
        {
            id = "starlight_blessing",
            name = "Starlight Blessing",
            description = "Heals and buffs all allies",
            cooldown = 80,
            effect = "bless_all",
            healValue = 0.3,
            buffValue = 0.2,
            duration = 30,
            targetType = "all_allies",
            energyCost = 50,
            level = 12
        },
        {
            id = "celestial_dance",
            name = "Celestial Dance",
            description = "Creates a starfield that damages enemies",
            cooldown = 100,
            effect = "starfield",
            value = 50,
            tickRate = 0.5,
            duration = 20,
            radius = 40,
            targetType = "area",
            energyCost = 60,
            level = 25
        },
        {
            id = "wish_upon_a_star",
            name = "Wish Upon a Star",
            description = "Grants a random powerful buff to team",
            cooldown = 200,
            effect = "random_wish",
            possibleBuffs = ["invincibility", "double_damage", "instant_heal", "time_stop"],
            duration = 15,
            targetType = "team",
            energyCost = 80,
            level = 40
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 5500,
        items = {"star_fragment", "moon_dust", "celestial_crown"},
        wishes = 77
    },
    evolvesTo = "kiki_and_lala_celestial",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "star_sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"},
        cosmic = {multiplier = 40, colorShift = "cosmic", particleEffect = "galaxy_swirl"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["dear_daniel_classic"] = CreatePet({
    id = "dear_daniel_classic",
    name = "Classic Dear Daniel",
    displayName = "Dear Daniel",
    tier = "Rare",
    rarity = 3,
    baseValue = 1000,
    baseStats = {
        coins = 500,
        gems = 8,
        luck = 20,
        speed = 18,
        power = 140,
        health = 240,
        defense = 35,
        critRate = 0.16,
        critDamage = 2.4,
        energy = 100,
        stamina = 105
    },
    description = "Hello Kitty's childhood friend and boyfriend",
    imageId = "rbxassetid://10000000251",
    modelId = "rbxassetid://10000000252",
    animations = {
        idle = "rbxassetid://10000000253",
        walk = "rbxassetid://10000000254",
        attack = "rbxassetid://10000000255",
        special = "rbxassetid://10000000256",
        dance = "rbxassetid://10000000257",
        photo = "rbxassetid://10000000258"
    },
    sounds = {
        spawn = "rbxassetid://10000000259",
        attack = "rbxassetid://10000000260",
        special = "rbxassetid://10000000261",
        camera = "rbxassetid://10000000262"
    },
    abilities = {
        {
            id = "photography",
            name = "Photography",
            description = "Captures moment, stunning enemies briefly",
            cooldown = 45,
            effect = "camera_flash",
            value = 100,
            stunDuration = 2,
            radius = 25,
            targetType = "cone",
            energyCost = 30,
            level = 1
        },
        {
            id = "gentleman_charm",
            name = "Gentleman's Charm",
            description = "Increases team's luck and happiness",
            passive = true,
            effect = "charm_aura",
            luckBonus = 0.15,
            happinessBonus = 0.1,
            radius = 30,
            level = 10
        },
        {
            id = "dance_partner",
            name = "Dance Partner",
            description = "Boosts stats when near Hello Kitty",
            passive = true,
            effect = "partner_boost",
            value = 0.5,
            partner = "hello_kitty",
            level = 20
        },
        {
            id = "travel_memories",
            name = "Travel Memories",
            description = "Shares experiences, boosting team XP",
            cooldown = 120,
            effect = "xp_share",
            value = 0.5,
            duration = 60,
            targetType = "team",
            energyCost = 50,
            level = 35
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 5000,
        items = {"camera", "travel_journal", "gentleman_suit"},
        photosToken = 200
    },
    evolvesTo = "dear_daniel_world",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

PetDatabase["mimmy_classic"] = CreatePet({
    id = "mimmy_classic",
    name = "Classic Mimmy",
    displayName = "Mimmy",
    tier = "Rare",
    rarity = 3,
    baseValue = 1050,
    baseStats = {
        coins = 525,
        gems = 8,
        luck = 22,
        speed = 16,
        power = 130,
        health = 230,
        defense = 32,
        critRate = 0.15,
        critDamage = 2.3,
        energy = 105,
        stamina = 100
    },
    description = "Hello Kitty's twin sister with a yellow bow",
    imageId = "rbxassetid://10000000263",
    modelId = "rbxassetid://10000000264",
    animations = {
        idle = "rbxassetid://10000000265",
        walk = "rbxassetid://10000000266",
        attack = "rbxassetid://10000000267",
        special = "rbxassetid://10000000268",
        shy = "rbxassetid://10000000269",
        sister_hug = "rbxassetid://10000000270"
    },
    sounds = {
        spawn = "rbxassetid://10000000271",
        attack = "rbxassetid://10000000272",
        special = "rbxassetid://10000000273",
        giggle = "rbxassetid://10000000274"
    },
    abilities = {
        {
            id = "sisterly_love",
            name = "Sisterly Love",
            description = "Heals and protects Hello Kitty",
            cooldown = 60,
            effect = "protect_sister",
            healValue = 0.5,
            shieldValue = 300,
            targetType = "specific_ally",
            targetId = "hello_kitty",
            energyCost = 40,
            level = 1
        },
        {
            id = "shy_power",
            name = "Shy Power",
            description = "Becomes stronger when taking damage",
            passive = true,
            effect = "damage_stack",
            value = 0.05,
            maxStacks = 10,
            level = 12
        },
        {
            id = "twin_telepathy",
            name = "Twin Telepathy",
            description = "Copies Hello Kitty's buffs",
            passive = true,
            effect = "copy_buffs",
            targetId = "hello_kitty",
            level = 22
        },
        {
            id = "yellow_bow_magic",
            name = "Yellow Bow Magic",
            description = "Creates protective barriers for all allies",
            cooldown = 100,
            effect = "barrier_all",
            value = 200,
            duration = 20,
            targetType = "all_allies",
            energyCost = 60,
            level = 38
        }
    },
    evolutionRequirements = {
        level = 50,
        gems = 5250,
        items = {"yellow_bow", "twin_pendant", "sister_bond"},
        sistersHelped = 100
    },
    evolvesTo = "mimmy_guardian",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 2, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "sparkle"},
        golden = {multiplier = 5, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_aura"},
        rainbow = {multiplier = 10, colorShift = "rainbow", particleEffect = "rainbow_trail"},
        dark_matter = {multiplier = 20, colorShift = Color3.fromRGB(50, 0, 100), particleEffect = "void_aura"}
    },
    maxLevel = 100,
    breedable = true,
    tradeable = true,
    giftable = true
})

-- TIER 4: EPIC PETS (4% drop rate)
PetDatabase["hello_kitty_angel"] = CreatePet({
    id = "hello_kitty_angel",
    name = "Angel Hello Kitty",
    displayName = "Angel Hello Kitty",
    tier = "Epic",
    rarity = 4,
    baseValue = 5000,
    baseStats = {
        coins = 1200,
        gems = 20,
        luck = 40,
        speed = 35,
        power = 300,
        health = 500,
        defense = 60,
        critRate = 0.20,
        critDamage = 3.0,
        energy = 150,
        stamina = 150
    },
    description = "Divine Hello Kitty with angelic wings",
    imageId = "rbxassetid://10000000275",
    modelId = "rbxassetid://10000000276",
    animations = {
        idle = "rbxassetid://10000000277",
        walk = "rbxassetid://10000000278",
        attack = "rbxassetid://10000000279",
        special = "rbxassetid://10000000280",
        fly = "rbxassetid://10000000281",
        bless = "rbxassetid://10000000282",
        ascend = "rbxassetid://10000000283"
    },
    sounds = {
        spawn = "rbxassetid://10000000284",
        attack = "rbxassetid://10000000285",
        special = "rbxassetid://10000000286",
        bless = "rbxassetid://10000000287",
        choir = "rbxassetid://10000000288"
    },
    abilities = {
        {
            id = "divine_blessing",
            name = "Divine Blessing",
            description = "Blesses all pets, doubling their stats for 60 seconds",
            cooldown = 300,
            effect = "blessing_aoe",
            value = 2,
            duration = 60,
            targetType = "all_allies",
            energyCost = 80,
            level = 1
        },
        {
            id = "heavenly_shield",
            name = "Heavenly Shield",
            description = "Creates an impenetrable shield for all allies",
            cooldown = 240,
            effect = "team_shield",
            value = 10,
            duration = 10,
            targetType = "team",
            energyCost = 60,
            level = 15
        },
        {
            id = "angels_grace",
            name = "Angel's Grace",
            description = "Revives fallen pets with 50% health",
            cooldown = 600,
            effect = "revive_all",
            value = 0.5,
            targetType = "fallen_allies",
            energyCost = 100,
            level = 25
        },
        {
            id = "celestial_aura",
            name = "Celestial Aura",
            description = "All pets gain 30% stats",
            passive = true,
            effect = "aura_boost",
            value = 0.3,
            level = 30
        },
        {
            id = "holy_light",
            name = "Holy Light",
            description = "Damages all enemies and heals all allies",
            cooldown = 180,
            effect = "holy_burst",
            damage = 500,
            heal = 0.3,
            targetType = "all",
            energyCost = 90,
            level = 40
        },
        {
            id = "miracle",
            name = "Miracle",
            description = "Instantly wins battle if health below 10%",
            passive = true,
            effect = "miracle_win",
            threshold = 0.1,
            cooldown = 86400,
            level = 50
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 15000,
        items = {"angel_halo", "divine_wings", "celestial_orb", "blessed_ribbon"},
        blessings = 100
    },
    evolvesTo = "hello_kitty_goddess",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "holy_sparkle"},
        crystal = {multiplier = 10, colorShift = Color3.fromRGB(200, 255, 255), particleEffect = "crystal_aura"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_wings"},
        cosmic = {multiplier = 50, colorShift = "cosmic", particleEffect = "cosmic_halo"},
        divine = {multiplier = 100, colorShift = Color3.fromRGB(255, 255, 255), particleEffect = "divine_light"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["kuromi_demon"] = CreatePet({
    id = "kuromi_demon",
    name = "Demon Kuromi",
    displayName = "Demon Kuromi",
    tier = "Epic",
    rarity = 4,
    baseValue = 4500,
    baseStats = {
        coins = 1000,
        gems = 18,
        luck = 35,
        speed = 40,
        power = 350,
        health = 450,
        defense = 50,
        critRate = 0.30,
        critDamage = 3.5,
        energy = 140,
        stamina = 140
    },
    description = "Kuromi embracing her demonic powers",
    imageId = "rbxassetid://10000000289",
    modelId = "rbxassetid://10000000290",
    animations = {
        idle = "rbxassetid://10000000291",
        walk = "rbxassetid://10000000292",
        attack = "rbxassetid://10000000293",
        special = "rbxassetid://10000000294",
        transform = "rbxassetid://10000000295",
        rage = "rbxassetid://10000000296",
        summon = "rbxassetid://10000000297"
    },
    sounds = {
        spawn = "rbxassetid://10000000298",
        attack = "rbxassetid://10000000299",
        special = "rbxassetid://10000000300",
        transform = "rbxassetid://10000000301",
        evil_laugh = "rbxassetid://10000000302"
    },
    abilities = {
        {
            id = "demonic_transformation",
            name = "Demonic Transformation",
            description = "Transform into demon form, tripling all stats",
            cooldown = 300,
            effect = "transform",
            value = 3,
            duration = 45,
            targetType = "self",
            energyCost = 100,
            level = 1
        },
        {
            id = "hells_fury",
            name = "Hell's Fury",
            description = "Unleashes demonic rage, dealing massive damage",
            cooldown = 180,
            effect = "fury_attack",
            value = 1000,
            radius = 40,
            targetType = "area",
            energyCost = 80,
            level = 12
        },
        {
            id = "soul_steal",
            name = "Soul Steal",
            description = "Steals 20% of enemy's max health",
            cooldown = 120,
            effect = "life_steal",
            value = 0.2,
            targetType = "enemy",
            energyCost = 60,
            level = 20
        },
        {
            id = "infernal_presence",
            name = "Infernal Presence",
            description = "Enemies take damage over time",
            passive = true,
            effect = "damage_aura",
            value = 50,
            radius = 30,
            level = 28
        },
        {
            id = "dark_pact",
            name = "Dark Pact",
            description = "Sacrifice 20% HP for 100% damage boost",
            cooldown = 90,
            effect = "blood_pact",
            cost = 0.2,
            boost = 1,
            duration = 30,
            targetType = "self",
            energyCost = 40,
            level = 35
        },
        {
            id = "summon_demons",
            name = "Summon Demons",
            description = "Summons demon minions to fight",
            cooldown = 240,
            effect = "summon_minions",
            count = 5,
            minionStats = {power = 100, health = 200},
            duration = 60,
            targetType = "self",
            energyCost = 120,
            level = 45
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 20000,
        items = {"demon_horn", "hell_essence", "dark_crystal", "cursed_skull"},
        soulsCollected = 666
    },
    evolvesTo = "kuromi_demon_lord",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        infernal = {multiplier = 5, colorShift = Color3.fromRGB(255, 0, 0), particleEffect = "hellfire"},
        void = {multiplier = 15, colorShift = Color3.fromRGB(0, 0, 0), particleEffect = "void_smoke"},
        chaos = {multiplier = 30, colorShift = "chaos", particleEffect = "chaos_storm"},
        eternal = {multiplier = 60, colorShift = "eternal", particleEffect = "eternal_flames"},
        apocalypse = {multiplier = 120, colorShift = Color3.fromRGB(150, 0, 0), particleEffect = "doomsday"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["cinnamoroll_celestial"] = CreatePet({
    id = "cinnamoroll_celestial",
    name = "Celestial Cinnamoroll",
    displayName = "Celestial Cinnamoroll",
    tier = "Epic",
    rarity = 4,
    baseValue = 4800,
    baseStats = {
        coins = 1100,
        gems = 22,
        luck = 45,
        speed = 50,
        power = 280,
        health = 420,
        defense = 55,
        critRate = 0.22,
        critDamage = 2.8,
        energy = 160,
        stamina = 150
    },
    description = "Cinnamoroll with celestial cloud powers",
    imageId = "rbxassetid://10000000303",
    modelId = "rbxassetid://10000000304",
    animations = {
        idle = "rbxassetid://10000000305",
        walk = "rbxassetid://10000000306",
        attack = "rbxassetid://10000000307",
        special = "rbxassetid://10000000308",
        fly = "rbxassetid://10000000309",
        cloud_surf = "rbxassetid://10000000310",
        sky_dance = "rbxassetid://10000000311"
    },
    sounds = {
        spawn = "rbxassetid://10000000312",
        attack = "rbxassetid://10000000313",
        special = "rbxassetid://10000000314",
        fly = "rbxassetid://10000000315",
        wind = "rbxassetid://10000000316"
    },
    abilities = {
        {
            id = "cloud_nine",
            name = "Cloud Nine",
            description = "Creates healing clouds that restore HP over time",
            cooldown = 60,
            effect = "healing_field",
            value = 100,
            duration = 20,
            radius = 35,
            targetType = "area",
            energyCost = 50,
            level = 1
        },
        {
            id = "sky_high",
            name = "Sky High",
            description = "Grants flight to all pets for 30 seconds",
            cooldown = 180,
            effect = "team_flight",
            value = 1,
            duration = 30,
            targetType = "team",
            energyCost = 70,
            level = 10
        },
        {
            id = "celestial_storm",
            name = "Celestial Storm",
            description = "Summons a storm that strikes random enemies",
            cooldown = 120,
            effect = "lightning_storm",
            value = 300,
            strikes = 10,
            targetType = "random_enemies",
            energyCost = 80,
            level = 18
        },
        {
            id = "fluffy_clouds",
            name = "Fluffy Clouds",
            description = "30% chance to negate any attack",
            passive = true,
            effect = "dodge_chance",
            value = 0.3,
            level = 25
        },
        {
            id = "rainbow_bridge",
            name = "Rainbow Bridge",
            description = "Teleports team to safety when below 20% HP",
            passive = true,
            effect = "emergency_teleport",
            value = 0.2,
            cooldown = 300,
            level = 32
        },
        {
            id = "heavenly_cafe",
            name = "Heavenly Cafe",
            description = "Creates a cafe that buffs all allies",
            cooldown = 240,
            effect = "buff_zone",
            statsBoost = 0.5,
            duration = 60,
            radius = 50,
            targetType = "location",
            energyCost = 100,
            level = 42
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 18000,
        items = ["cloud_essence", "celestial_wings", "rainbow_crystal", "sky_orb"],
        cloudsRidden = 500
    },
    evolvesTo = "cinnamoroll_archangel",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(200, 200, 255), particleEffect = "cloud_sparkle"},
        aurora = {multiplier = 12, colorShift = "aurora", particleEffect = "aurora_trail"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_clouds"},
        stellar = {multiplier = 50, colorShift = "stellar", particleEffect = "star_shower"},
        nebula = {multiplier = 100, colorShift = "nebula", particleEffect = "nebula_swirl"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["my_melody_angel"] = CreatePet({
    id = "my_melody_angel",
    name = "Angel My Melody",
    displayName = "Angel My Melody",
    tier = "Epic",
    rarity = 4,
    baseValue = 4600,
    baseStats = {
        coins = 1150,
        gems = 21,
        luck = 42,
        speed = 38,
        power = 290,
        health = 480,
        defense = 58,
        critRate = 0.18,
        critDamage = 2.6,
        energy = 155,
        stamina = 145
    },
    description = "My Melody blessed with angelic powers",
    imageId = "rbxassetid://10000000317",
    modelId = "rbxassetid://10000000318",
    animations = {
        idle = "rbxassetid://10000000319",
        walk = "rbxassetid://10000000320",
        attack = "rbxassetid://10000000321",
        special = "rbxassetid://10000000322",
        fly = "rbxassetid://10000000323",
        heal = "rbxassetid://10000000324",
        sing = "rbxassetid://10000000325"
    },
    sounds = {
        spawn = "rbxassetid://10000000326",
        attack = "rbxassetid://10000000327",
        special = "rbxassetid://10000000328",
        heal = "rbxassetid://10000000329",
        angelic_voice = "rbxassetid://10000000330"
    },
    abilities = {
        {
            id = "melody_of_life",
            name = "Melody of Life",
            description = "Fully heals all allies and removes debuffs",
            cooldown = 240,
            effect = "full_heal_cleanse",
            value = 1,
            targetType = "all_allies",
            energyCost = 90,
            level = 1
        },
        {
            id = "angelic_voice",
            name = "Angelic Voice",
            description = "Charms enemies, making them fight for you",
            cooldown = 180,
            effect = "charm_enemies",
            value = 3,
            duration = 15,
            targetType = "enemies",
            energyCost = 70,
            level = 14
        },
        {
            id = "pink_paradise",
            name = "Pink Paradise",
            description = "Creates a safe zone where allies can't die",
            cooldown = 600,
            effect = "immortality_zone",
            radius = 50,
            duration = 10,
            targetType = "area",
            energyCost = 120,
            level = 22
        },
        {
            id = "love_aura",
            name = "Love Aura",
            description = "Converts 30% of damage to healing",
            passive = true,
            effect = "damage_to_heal",
            value = 0.3,
            level = 28
        },
        {
            id = "guardian_angel",
            name = "Guardian Angel",
            description = "Automatically revives once per battle",
            passive = true,
            effect = "auto_revive",
            value = 1,
            cooldown = 999999,
            level = 36
        },
        {
            id = "symphony_of_hope",
            name = "Symphony of Hope",
            description = "Plays a song that gradually heals and buffs team",
            cooldown = 300,
            effect = "healing_song",
            healPerSecond = 50,
            buffPerSecond = 0.02,
            duration = 30,
            targetType = "all_allies",
            energyCost = 100,
            level = 44
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 16000,
        items = {"angel_wings", "melody_harp", "pink_halo", "love_essence"],
        healingDone = 100000
    },
    evolvesTo = "my_melody_seraph",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 200, 220), particleEffect = "heart_sparkle"},
        crystal = {multiplier = 10, colorShift = Color3.fromRGB(255, 200, 255), particleEffect = "crystal_hearts"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_notes"},
        cosmic = {multiplier = 50, colorShift = "cosmic", particleEffect = "cosmic_melody"},
        divine = {multiplier = 100, colorShift = Color3.fromRGB(255, 220, 240), particleEffect = "divine_song"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

PetDatabase["pompompurin_chef"] = CreatePet({
    id = "pompompurin_chef",
    name = "Chef Pompompurin",
    displayName = "Chef Pompompurin",
    tier = "Epic",
    rarity = 4,
    baseValue = 4400,
    baseStats = {
        coins = 1050,
        gems = 19,
        luck = 38,
        speed = 22,
        power = 320,
        health = 550,
        defense = 65,
        critRate = 0.15,
        critDamage = 3.0,
        energy = 130,
        stamina = 160
    },
    description = "Master chef Pompompurin with magical cooking skills",
    imageId = "rbxassetid://10000000331",
    modelId = "rbxassetid://10000000332",
    animations = {
        idle = "rbxassetid://10000000333",
        walk = "rbxassetid://10000000334",
        attack = "rbxassetid://10000000335",
        special = "rbxassetid://10000000336",
        cook = "rbxassetid://10000000337",
        serve = "rbxassetid://10000000338",
        taste = "rbxassetid://10000000339"
    },
    sounds = {
        spawn = "rbxassetid://10000000340",
        attack = "rbxassetid://10000000341",
        special = "rbxassetid://10000000342",
        cooking = "rbxassetid://10000000343",
        bell = "rbxassetid://10000000344"
    },
    abilities = {
        {
            id = "master_chef",
            name = "Master Chef",
            description = "Creates magical food that grants random buffs",
            cooldown = 80,
            effect = "create_food",
            foodTypes = ["attack_boost", "defense_boost", "speed_boost", "heal", "energy"],
            foodCount = 5,
            duration = 40,
            targetType = "area",
            energyCost = 60,
            level = 1
        },
        {
            id = "pudding_mastery",
            name = "Pudding Mastery",
            description = "Pudding heals 100% more",
            passive = true,
            effect = "pudding_boost",
            value = 1,
            level = 10
        },
        {
            id = "kitchen_fury",
            name = "Kitchen Fury",
            description = "Throws kitchen utensils at enemies",
            cooldown = 45,
            effect = "projectile_barrage",
            value = 100,
            projectileCount = 10,
            targetType = "spread",
            energyCost = 40,
            level = 18
        },
        {
            id = "five_star_meal",
            name = "Five Star Meal",
            description = "Creates ultimate meal that fully restores team",
            cooldown = 300,
            effect = "ultimate_meal",
            healValue = 1,
            buffValue = 0.5,
            duration = 60,
            targetType = "all_allies",
            energyCost = 100,
            level = 28
        },
        {
            id = "golden_spoon",
            name = "Golden Spoon",
            description = "Attacks have 20% chance to drop food",
            passive = true,
            effect = "food_drop",
            value = 0.2,
            level = 35
        },
        {
            id = "restaurant_empire",
            name = "Restaurant Empire",
            description = "Opens restaurant that generates coins over time",
            cooldown = 600,
            effect = "coin_generator",
            coinsPerSecond = 100,
            duration = 300,
            targetType = "location",
            energyCost = 120,
            level = 45
        }
    },
    evolutionRequirements = {
        level = 75,
        gems = 17000,
        items = {"chef_hat", "golden_spoon", "recipe_book", "five_star_badge"],
        mealsCooked = 1000
    },
    evolvesTo = "pompompurin_gourmet",
    variants = {
        normal = {multiplier = 1, colorShift = nil, particleEffect = nil},
        shiny = {multiplier = 3, colorShift = Color3.fromRGB(255, 255, 200), particleEffect = "steam"},
        golden = {multiplier = 10, colorShift = Color3.fromRGB(255, 215, 0), particleEffect = "golden_steam"},
        rainbow = {multiplier = 25, colorShift = "rainbow", particleEffect = "rainbow_aroma"},
        masterchef = {multiplier = 50, colorShift = Color3.fromRGB(255, 255, 255), particleEffect = "michelin_stars"},
        legendary = {multiplier = 100, colorShift = Color3.fromRGB(255, 200, 0), particleEffect = "legendary_feast"}
    },
    maxLevel = 100,
    breedable = false,
    tradeable = true,
    giftable = true
})

-- Continue in Part 3...