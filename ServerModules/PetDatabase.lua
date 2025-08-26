--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                        SANRIO TYCOON - PET DATABASE MODULE                           ║
    ║                           Complete pet definitions and data                          ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local PetDatabase = {}

-- Dependencies
local Configuration = require(script.Parent.Configuration)

-- ========================================
-- PET DATABASE
-- ========================================
local Pets = {
    -- ====== HELLO KITTY SERIES ======
    ["hello_kitty_classic"] = {
        name = "Classic Hello Kitty",
        description = "The iconic white cat with a red bow!",
        rarity = Configuration.RARITY.COMMON,
        baseStats = {
            power = 10,
            health = 100,
            speed = 5,
            luck = 2
        },
        abilities = {
            {
                name = "Cute Charm",
                description = "Increases coin collection by 10%",
                unlockLevel = 1,
                cooldown = 30,
                effect = {type = "coin_boost", value = 0.1}
            }
        },
        passiveBonus = {
            coins = 0.05
        },
        variants = {"Pink Bow", "Blue Bow", "Rainbow Bow"},
        evolution = {
            evolvesTo = "hello_kitty_angel",
            requiredLevel = 25,
            requiredItems = {coins = 10000}
        }
    },
    
    ["hello_kitty_angel"] = {
        name = "Angel Hello Kitty",
        description = "Hello Kitty with angelic wings!",
        rarity = Configuration.RARITY.RARE,
        baseStats = {
            power = 25,
            health = 200,
            speed = 10,
            luck = 5
        },
        abilities = {
            {
                name = "Heavenly Blessing",
                description = "Grants temporary invincibility",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "invincibility", duration = 5}
            },
            {
                name = "Divine Collection",
                description = "Doubles coin collection for 30 seconds",
                unlockLevel = 10,
                cooldown = 120,
                effect = {type = "coin_multiplier", value = 2, duration = 30}
            }
        },
        passiveBonus = {
            coins = 0.15,
            luck = 0.1
        },
        evolution = {
            evolvesTo = "hello_kitty_goddess",
            requiredLevel = 50,
            requiredItems = {gems = 1000}
        }
    },
    
    ["hello_kitty_goddess"] = {
        name = "Goddess Hello Kitty",
        description = "The divine form of Hello Kitty!",
        rarity = Configuration.RARITY.LEGENDARY,
        baseStats = {
            power = 100,
            health = 500,
            speed = 25,
            luck = 20
        },
        abilities = {
            {
                name = "Divine Aura",
                description = "All pets gain 50% stat boost",
                unlockLevel = 1,
                cooldown = 180,
                effect = {type = "team_buff", value = 0.5, duration = 60}
            },
            {
                name = "Celestial Rain",
                description = "Rains coins from the sky",
                unlockLevel = 25,
                cooldown = 300,
                effect = {type = "coin_rain", amount = 10000}
            }
        },
        passiveBonus = {
            coins = 0.5,
            gems = 0.2,
            luck = 0.3
        }
    },
    
    -- ====== MY MELODY SERIES ======
    ["my_melody_basic"] = {
        name = "My Melody",
        description = "A sweet white rabbit with a pink hood!",
        rarity = Configuration.RARITY.COMMON,
        baseStats = {
            power = 8,
            health = 120,
            speed = 7,
            luck = 3
        },
        abilities = {
            {
                name = "Melody Boost",
                description = "Increases movement speed by 20%",
                unlockLevel = 1,
                cooldown = 20,
                effect = {type = "speed_boost", value = 0.2, duration = 10}
            }
        },
        passiveBonus = {
            speed = 0.1
        },
        variants = {"Pink Hood", "Blue Hood", "Floral Hood"},
        evolution = {
            evolvesTo = "my_melody_sweet",
            requiredLevel = 20,
            requiredItems = {coins = 8000}
        }
    },
    
    ["my_melody_sweet"] = {
        name = "Sweet My Melody",
        description = "My Melody surrounded by sweets!",
        rarity = Configuration.RARITY.UNCOMMON,
        baseStats = {
            power = 20,
            health = 180,
            speed = 12,
            luck = 6
        },
        abilities = {
            {
                name = "Sugar Rush",
                description = "Massive speed boost for all pets",
                unlockLevel = 1,
                cooldown = 45,
                effect = {type = "team_speed", value = 0.5, duration = 15}
            },
            {
                name = "Sweet Dreams",
                description = "Heals all pets",
                unlockLevel = 15,
                cooldown = 60,
                effect = {type = "team_heal", value = 100}
            }
        },
        passiveBonus = {
            speed = 0.2,
            health = 0.1
        }
    },
    
    -- ====== KUROMI SERIES ======
    ["kuromi_basic"] = {
        name = "Kuromi",
        description = "A mischievous white rabbit with a devil tail!",
        rarity = Configuration.RARITY.UNCOMMON,
        baseStats = {
            power = 15,
            health = 90,
            speed = 8,
            luck = 4
        },
        abilities = {
            {
                name = "Mischief Maker",
                description = "Steals coins from enemies",
                unlockLevel = 1,
                cooldown = 25,
                effect = {type = "coin_steal", value = 100}
            }
        },
        passiveBonus = {
            power = 0.15
        },
        variants = {"Pink Skull", "Purple Skull", "Rainbow Skull"},
        evolution = {
            evolvesTo = "kuromi_devil",
            requiredLevel = 30,
            requiredItems = {coins = 15000}
        }
    },
    
    ["kuromi_devil"] = {
        name = "Devil Kuromi",
        description = "Kuromi with devil wings and horns!",
        rarity = Configuration.RARITY.EPIC,
        baseStats = {
            power = 40,
            health = 150,
            speed = 15,
            luck = 8
        },
        abilities = {
            {
                name = "Devil's Bargain",
                description = "Double damage but take 50% more damage",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "berserk", damage = 2, defense = 0.5, duration = 20}
            },
            {
                name = "Chaos Storm",
                description = "Deals area damage to all enemies",
                unlockLevel = 20,
                cooldown = 90,
                effect = {type = "aoe_damage", value = 200}
            }
        },
        passiveBonus = {
            power = 0.3,
            critical = 0.2
        }
    },
    
    -- ====== CINNAMOROLL SERIES ======
    ["cinnamoroll_basic"] = {
        name = "Cinnamoroll",
        description = "A fluffy white puppy who can fly with his ears!",
        rarity = Configuration.RARITY.COMMON,
        baseStats = {
            power = 7,
            health = 110,
            speed = 10,
            luck = 5
        },
        abilities = {
            {
                name = "Cloud Float",
                description = "Avoids ground attacks",
                unlockLevel = 1,
                cooldown = 30,
                effect = {type = "flying", duration = 10}
            }
        },
        passiveBonus = {
            evasion = 0.1
        },
        variants = {"Blue Ears", "Pink Ears", "Rainbow Ears"},
        evolution = {
            evolvesTo = "cinnamoroll_sky",
            requiredLevel = 25,
            requiredItems = {coins = 12000}
        }
    },
    
    ["cinnamoroll_sky"] = {
        name = "Sky Cinnamoroll",
        description = "Cinnamoroll soaring through clouds!",
        rarity = Configuration.RARITY.RARE,
        baseStats = {
            power = 22,
            health = 170,
            speed = 20,
            luck = 10
        },
        abilities = {
            {
                name = "Sky Dance",
                description = "All pets gain flight and evasion",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "team_flying", evasion = 0.3, duration = 20}
            },
            {
                name = "Cloud Cushion",
                description = "Reduces all damage by 50%",
                unlockLevel = 15,
                cooldown = 90,
                effect = {type = "damage_reduction", value = 0.5, duration = 15}
            }
        },
        passiveBonus = {
            evasion = 0.25,
            speed = 0.15
        }
    },
    
    -- ====== POMPOMPURIN SERIES ======
    ["pompompurin_basic"] = {
        name = "Pompompurin",
        description = "A golden retriever who loves pudding!",
        rarity = Configuration.RARITY.COMMON,
        baseStats = {
            power = 12,
            health = 130,
            speed = 4,
            luck = 3
        },
        abilities = {
            {
                name = "Pudding Power",
                description = "Heals self over time",
                unlockLevel = 1,
                cooldown = 20,
                effect = {type = "regen", value = 20, duration = 10}
            }
        },
        passiveBonus = {
            health = 0.2
        },
        variants = {"Brown Beret", "Red Beret", "Rainbow Beret"},
        evolution = {
            evolvesTo = "pompompurin_chef",
            requiredLevel = 22,
            requiredItems = {coins = 9000}
        }
    },
    
    ["pompompurin_chef"] = {
        name = "Chef Pompompurin",
        description = "Master chef Pompompurin with his cooking hat!",
        rarity = Configuration.RARITY.UNCOMMON,
        baseStats = {
            power = 25,
            health = 200,
            speed = 8,
            luck = 6
        },
        abilities = {
            {
                name = "Healing Feast",
                description = "Creates food that heals all allies",
                unlockLevel = 1,
                cooldown = 45,
                effect = {type = "team_heal", value = 150}
            },
            {
                name = "Sugar Boost",
                description = "Increases all stats temporarily",
                unlockLevel = 18,
                cooldown = 60,
                effect = {type = "all_stats", value = 0.3, duration = 30}
            }
        },
        passiveBonus = {
            health = 0.35,
            healing = 0.25
        }
    },
    
    -- ====== KEROPPI SERIES ======
    ["keroppi_basic"] = {
        name = "Keroppi",
        description = "A cheerful frog from Donut Pond!",
        rarity = Configuration.RARITY.COMMON,
        baseStats = {
            power = 9,
            health = 105,
            speed = 9,
            luck = 4
        },
        abilities = {
            {
                name = "Lily Pad Jump",
                description = "Quick dash forward",
                unlockLevel = 1,
                cooldown = 15,
                effect = {type = "dash", distance = 10}
            }
        },
        passiveBonus = {
            jump = 0.2
        },
        variants = {"Green", "Blue", "Pink"},
        evolution = {
            evolvesTo = "keroppi_ninja",
            requiredLevel = 28,
            requiredItems = {coins = 11000}
        }
    },
    
    ["keroppi_ninja"] = {
        name = "Ninja Keroppi",
        description = "Keroppi trained in the ninja arts!",
        rarity = Configuration.RARITY.RARE,
        baseStats = {
            power = 30,
            health = 160,
            speed = 25,
            luck = 12
        },
        abilities = {
            {
                name = "Shadow Clone",
                description = "Creates clones that confuse enemies",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "clone", count = 3, duration = 15}
            },
            {
                name = "Smoke Bomb",
                description = "Become invisible and gain speed",
                unlockLevel = 20,
                cooldown = 90,
                effect = {type = "stealth", speed = 0.5, duration = 10}
            }
        },
        passiveBonus = {
            evasion = 0.3,
            critical = 0.25
        }
    },
    
    -- ====== BADTZ-MARU SERIES ======
    ["badtz_maru_basic"] = {
        name = "Badtz-Maru",
        description = "A mischievous penguin with attitude!",
        rarity = Configuration.RARITY.UNCOMMON,
        baseStats = {
            power = 14,
            health = 95,
            speed = 11,
            luck = 5
        },
        abilities = {
            {
                name = "Penguin Slide",
                description = "Fast sliding attack",
                unlockLevel = 1,
                cooldown = 20,
                effect = {type = "dash_damage", value = 50}
            }
        },
        passiveBonus = {
            evasion = 0.15
        },
        variants = {"Classic", "Punk", "Cool"},
        evolution = {
            evolvesTo = "badtz_maru_rebel",
            requiredLevel = 25,
            requiredItems = {coins = 13000}
        }
    },
    
    ["badtz_maru_rebel"] = {
        name = "Rebel Badtz-Maru",
        description = "The ultimate rebel penguin!",
        rarity = Configuration.RARITY.EPIC,
        baseStats = {
            power = 35,
            health = 140,
            speed = 22,
            luck = 10
        },
        abilities = {
            {
                name = "Rebel Yell",
                description = "Intimidates all enemies",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "fear", duration = 3}
            },
            {
                name = "Ice Prison",
                description = "Freezes all enemies",
                unlockLevel = 15,
                cooldown = 90,
                effect = {type = "freeze_all", duration = 2}
            }
        },
        passiveBonus = {
            power = 0.25,
            evasion = 0.3
        }
    },
    
    -- ====== POCHACCO SERIES ======
    ["pochacco_basic"] = {
        name = "Pochacco",
        description = "A sporty white dog who loves basketball!",
        rarity = Configuration.RARITY.COMMON,
        baseStats = {
            power = 11,
            health = 115,
            speed = 12,
            luck = 4
        },
        abilities = {
            {
                name = "Sport Boost",
                description = "Increases team speed",
                unlockLevel = 1,
                cooldown = 25,
                effect = {type = "team_speed", value = 0.25, duration = 15}
            }
        },
        passiveBonus = {
            speed = 0.15
        },
        variants = {"Soccer", "Basketball", "Baseball"},
        evolution = {
            evolvesTo = "pochacco_athlete",
            requiredLevel = 20,
            requiredItems = {coins = 8500}
        }
    },
    
    ["pochacco_athlete"] = {
        name = "Athlete Pochacco",
        description = "The ultimate sports champion!",
        rarity = Configuration.RARITY.RARE,
        baseStats = {
            power = 24,
            health = 185,
            speed = 28,
            luck = 8
        },
        abilities = {
            {
                name = "Team Spirit",
                description = "Boosts all team stats",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "team_boost", value = 0.2, duration = 30}
            },
            {
                name = "Victory Rush",
                description = "Massive speed and power boost",
                unlockLevel = 20,
                cooldown = 120,
                effect = {type = "super_boost", power = 0.5, speed = 0.5, duration = 20}
            }
        },
        passiveBonus = {
            speed = 0.3,
            stamina = 0.2
        }
    },
    
    -- ====== TUXEDOSAM SERIES ======
    ["tuxedosam_basic"] = {
        name = "Tuxedosam",
        description = "A classy penguin who loves to eat!",
        rarity = Configuration.RARITY.COMMON,
        baseStats = {
            power = 13,
            health = 140,
            speed = 6,
            luck = 3
        },
        abilities = {
            {
                name = "Belly Flop",
                description = "Heavy damage attack",
                unlockLevel = 1,
                cooldown = 30,
                effect = {type = "heavy_damage", value = 80}
            }
        },
        passiveBonus = {
            health = 0.25
        },
        variants = {"Bow Tie", "Top Hat", "Monocle"},
        evolution = {
            evolvesTo = "tuxedosam_gentleman",
            requiredLevel = 23,
            requiredItems = {coins = 10000}
        }
    },
    
    ["tuxedosam_gentleman"] = {
        name = "Gentleman Tuxedosam",
        description = "The most refined penguin!",
        rarity = Configuration.RARITY.RARE,
        baseStats = {
            power = 28,
            health = 220,
            speed = 12,
            luck = 7
        },
        abilities = {
            {
                name = "Gentleman's Agreement",
                description = "Reduces enemy attack",
                unlockLevel = 1,
                cooldown = 45,
                effect = {type = "weaken", value = 0.3, duration = 20}
            },
            {
                name = "Fancy Feast",
                description = "Heals team based on damage dealt",
                unlockLevel = 18,
                cooldown = 60,
                effect = {type = "lifesteal", value = 0.5}
            }
        },
        passiveBonus = {
            health = 0.4,
            defense = 0.3
        }
    },
    
    -- ====== CHOCOCAT SERIES ======
    ["chococat_basic"] = {
        name = "Chococat",
        description = "A curious black cat with big eyes!",
        rarity = Configuration.RARITY.UNCOMMON,
        baseStats = {
            power = 16,
            health = 100,
            speed = 14,
            luck = 8
        },
        abilities = {
            {
                name = "Curiosity",
                description = "Reveals enemy weaknesses",
                unlockLevel = 1,
                cooldown = 30,
                effect = {type = "analyze", duration = 10}
            }
        },
        passiveBonus = {
            luck = 0.2
        },
        variants = {"Blue Collar", "Red Collar", "Gold Collar"},
        evolution = {
            evolvesTo = "chococat_wise",
            requiredLevel = 27,
            requiredItems = {coins = 14000}
        }
    },
    
    ["chococat_wise"] = {
        name = "Wise Chococat",
        description = "All-knowing Chococat!",
        rarity = Configuration.RARITY.EPIC,
        baseStats = {
            power = 38,
            health = 165,
            speed = 24,
            luck = 18
        },
        abilities = {
            {
                name = "Foresight",
                description = "Dodge next 3 attacks",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "perfect_dodge", count = 3}
            },
            {
                name = "Wisdom Share",
                description = "Boost team's critical chance",
                unlockLevel = 22,
                cooldown = 90,
                effect = {type = "team_crit", value = 0.5, duration = 30}
            }
        },
        passiveBonus = {
            luck = 0.4,
            critical = 0.3
        }
    },
    
    -- ====== SPECIAL/SECRET PETS ======
    ["hello_kitty_rainbow"] = {
        name = "Rainbow Hello Kitty",
        description = "An ultra-rare rainbow variant!",
        rarity = Configuration.RARITY.SECRET,
        baseStats = {
            power = 150,
            health = 750,
            speed = 50,
            luck = 50
        },
        abilities = {
            {
                name = "Rainbow Power",
                description = "Devastating rainbow attack",
                unlockLevel = 1,
                cooldown = 120,
                effect = {type = "ultimate", damage = 500}
            },
            {
                name = "Prismatic Shield",
                description = "Immune to all damage",
                unlockLevel = 25,
                cooldown = 180,
                effect = {type = "invincibility", duration = 10}
            },
            {
                name = "Rainbow Blessing",
                description = "Fully heals and buffs team",
                unlockLevel = 50,
                cooldown = 300,
                effect = {type = "full_restore", buff = 0.5}
            }
        },
        passiveBonus = {
            coins = 1.0,
            gems = 0.5,
            luck = 0.5,
            all_stats = 0.5
        }
    },
    
    ["golden_cinnamoroll"] = {
        name = "Golden Cinnamoroll",
        description = "A legendary golden variant!",
        rarity = Configuration.RARITY.MYTHICAL,
        baseStats = {
            power = 80,
            health = 400,
            speed = 60,
            luck = 30
        },
        abilities = {
            {
                name = "Golden Wind",
                description = "Powerful wind attack",
                unlockLevel = 1,
                cooldown = 60,
                effect = {type = "wind_blast", damage = 200}
            },
            {
                name = "Midas Touch",
                description = "Turns damage into coins",
                unlockLevel = 30,
                cooldown = 120,
                effect = {type = "coin_generation", rate = 2.0}
            }
        },
        passiveBonus = {
            coins = 0.75,
            speed = 0.5,
            evasion = 0.4
        }
    },
    
    ["shadow_kuromi"] = {
        name = "Shadow Kuromi",
        description = "Dark and mysterious variant!",
        rarity = Configuration.RARITY.MYTHICAL,
        baseStats = {
            power = 90,
            health = 350,
            speed = 40,
            luck = 25
        },
        abilities = {
            {
                name = "Shadow Strike",
                description = "Instant critical hit",
                unlockLevel = 1,
                cooldown = 45,
                effect = {type = "guaranteed_crit", damage = 150}
            },
            {
                name = "Darkness Falls",
                description = "Blinds all enemies",
                unlockLevel = 25,
                cooldown = 90,
                effect = {type = "blind_all", duration = 5}
            }
        },
        passiveBonus = {
            critical = 0.5,
            power = 0.4,
            lifesteal = 0.2
        }
    }
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function PetDatabase:GetPet(petId)
    return Pets[petId]
end

function PetDatabase:GetAllPets()
    return Pets
end

function PetDatabase:GetPetsByRarity(rarity)
    local result = {}
    for id, pet in pairs(Pets) do
        if pet.rarity == rarity then
            result[id] = pet
        end
    end
    return result
end

function PetDatabase:GetEvolvablePets()
    local result = {}
    for id, pet in pairs(Pets) do
        if pet.evolution then
            result[id] = pet
        end
    end
    return result
end

return PetDatabase