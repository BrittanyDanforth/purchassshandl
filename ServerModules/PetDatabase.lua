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
    }
}

-- More pets continue in additional parts...

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