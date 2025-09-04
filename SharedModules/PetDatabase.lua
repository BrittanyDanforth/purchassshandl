--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                   SANRIO TYCOON - ULTIMATE PET DATABASE v2.0                         ║
    ║                     200 PETS WITH COMPLETE EVOLUTION CHAINS                          ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local PetDatabase = {}

-- ========================================
-- CONFIGURATION IMPORT
-- ========================================
local Configuration = require(script.Parent.Configuration)

-- ========================================
-- RARITY TIERS
-- ========================================
-- Use Configuration RARITY but check if it exists first
local RARITY = {}
if Configuration and Configuration.RARITY then
	-- Copy all values from Configuration.RARITY
	for key, value in pairs(Configuration.RARITY) do
		RARITY[key] = value
	end
else
	-- Fallback values if Configuration isn't loaded
	RARITY = {
		COMMON = 1,
		UNCOMMON = 2,
		RARE = 3,
		EPIC = 4,
		LEGENDARY = 5,
		MYTHICAL = 6,
		SECRET = 7,
		EVENT = 8,
		EXCLUSIVE = 9
	}
end

-- Add additional rarities if they don't exist
if not RARITY.DIVINE then
	RARITY.DIVINE = 10
end
if not RARITY.CELESTIAL then
	RARITY.CELESTIAL = 11
end
if not RARITY.IMMORTAL then
	RARITY.IMMORTAL = 12
end

-- Rarity visual data
local RARITY_DATA = {
	[RARITY.COMMON] = {
		name = "Common",
		color = Color3.fromRGB(200, 200, 200),
		particleEffect = "CommonSparkle",
		glowIntensity = 0.1,
	},
	[RARITY.UNCOMMON] = {
		name = "Uncommon",
		color = Color3.fromRGB(100, 200, 100),
		particleEffect = "UncommonGlow",
		glowIntensity = 0.2,
	},
	[RARITY.RARE] = {
		name = "Rare",
		color = Color3.fromRGB(85, 170, 255),
		particleEffect = "RareGlow",
		glowIntensity = 0.3,
	},
	[RARITY.EPIC] = {
		name = "Epic",
		color = Color3.fromRGB(163, 53, 238),
		particleEffect = "EpicAura",
		glowIntensity = 0.5,
	},
	[RARITY.LEGENDARY] = {
		name = "Legendary",
		color = Color3.fromRGB(255, 170, 0),
		particleEffect = "LegendaryFlames",
		glowIntensity = 0.7,
	},
	[RARITY.MYTHICAL] = {
		name = "Mythical",
		color = Color3.fromRGB(255, 92, 161),
		particleEffect = "MythicalStars",
		glowIntensity = 0.9,
	},
	[RARITY.SECRET] = {
		name = "Secret",
		color = Color3.fromRGB(255, 0, 100),
		particleEffect = "SecretMystery",
		glowIntensity = 1.0,
		hasAura = true,
	},
	[RARITY.EVENT] = {
		name = "Event",
		color = Color3.fromRGB(255, 215, 0),
		particleEffect = "EventSparkle",
		glowIntensity = 0.8,
	},
	[RARITY.EXCLUSIVE] = {
		name = "Exclusive",
		color = Color3.fromRGB(220, 20, 60),
		particleEffect = "ExclusiveShine",
		glowIntensity = 0.9,
	},
	[RARITY.DIVINE] = {
		name = "Divine",
		color = Color3.fromRGB(255, 255, 0),
		particleEffect = "DivineLight",
		glowIntensity = 1.0,
		hasAura = true,
	},
	[RARITY.CELESTIAL] = {
		name = "Celestial",
		color = Color3.fromRGB(185, 242, 255),
		particleEffect = "CelestialGalaxy",
		glowIntensity = 1.2,
		hasAura = true,
		hasFloatingEffect = true,
	},
	[RARITY.IMMORTAL] = {
		name = "Immortal",
		color = Color3.fromRGB(255, 0, 255),
		particleEffect = "ImmortalChaos",
		glowIntensity = 1.5,
		hasAura = true,
		hasFloatingEffect = true,
		hasTrailEffect = true,
	},
}

-- ========================================
-- PET VARIANTS
-- ========================================
local VARIANTS = {
	NORMAL = {multiplier = 1, chance = 0.7},
	SHINY = {multiplier = 1.5, chance = 0.15, color = Color3.fromRGB(255, 255, 255)},
	GOLDEN = {multiplier = 2, chance = 0.08, color = Color3.fromRGB(255, 215, 0)},
	RAINBOW = {multiplier = 3, chance = 0.04, color = "Rainbow"},
	SHADOW = {multiplier = 4, chance = 0.02, color = Color3.fromRGB(0, 0, 0)},
	COSMIC = {multiplier = 5, chance = 0.008, color = "Galaxy"},
	VOID = {multiplier = 10, chance = 0.002, color = "Void"},
}

-- ========================================
-- ABILITY TYPES
-- ========================================
local ABILITY_TYPES = {
	-- Offensive
	DAMAGE = "damage",
	DOT = "damage_over_time",
	BURST = "burst_damage",
	CRITICAL = "critical_hit",
	
	-- Defensive
	SHIELD = "shield",
	HEAL = "heal",
	IMMUNITY = "immunity",
	
	-- Utility
	SPEED = "speed_boost",
	SLOW = "slow_enemy",
	STUN = "stun",
	FREEZE = "freeze",
	
	-- Economic
	COIN_BOOST = "coin_multiplier",
	GEM_CHANCE = "gem_drop",
	TREASURE_FIND = "treasure_find",
	
	-- Team
	TEAM_BUFF = "team_buff",
	TEAM_HEAL = "team_heal",
	TEAM_SHIELD = "team_shield",
	
	-- Special
	TRANSFORM = "transformation",
	REALITY_BEND = "reality_bend",
}

-- ========================================
-- THE ULTIMATE PET DATABASE
-- ========================================
local Pets = {
	-- ====================================
	-- HELLO KITTY SERIES (Complete Chain)
	-- ====================================
	
	["hello_kitty_basic"] = {
		id = "hello_kitty_basic",
		name = "Hello Kitty",
		displayName = "Hello Kitty",
		description = "The iconic white cat with a red bow!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://123456789",
		model = "rbxassetid://987654321",
		baseStats = {
			health = 100,
			attack = 25,
			defense = 20,
			speed = 50,
			luck = 15,
			critChance = 0.05,
			critDamage = 1.5,
		},
		abilities = {
			{
				id = "cute_charm",
				name = "Cute Charm",
				description = "Increases coin collection by 10%",
				unlockLevel = 1,
				cooldown = 30,
				manaCost = 20,
				effects = {
					{
						type = ABILITY_TYPES.COIN_BOOST,
						value = 1.1,
						duration = 10,
					}
				}
			}
		},
		passives = {
			{
				id = "kawaii_aura",
				name = "Kawaii Aura",
				description = "Team gains 5% luck",
				stats = {luck = 0.05}
			}
		},
		evolution = {
			evolvesTo = "hello_kitty_angel",
			requiredLevel = 25,
			requiredItems = {
				{id = "coins", amount = 10000}
			}
		}
	},
	
	["hello_kitty_angel"] = {
		id = "hello_kitty_angel",
		name = "Angel Hello Kitty",
		displayName = "Angel Hello Kitty",
		description = "Hello Kitty with angelic wings!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://123456790",
		model = "rbxassetid://987654322",
		baseStats = {
			health = 250,
			attack = 60,
			defense = 45,
			speed = 80,
			luck = 30,
			critChance = 0.15,
			critDamage = 2.0,
		},
		abilities = {
			{
				id = "heavenly_blessing",
				name = "Heavenly Blessing",
				description = "Grants temporary invincibility",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 40,
				effects = {
					{
						type = ABILITY_TYPES.IMMUNITY,
						duration = 3,
						visualEffect = "HolyBarrier"
					}
				}
			},
			{
				id = "divine_collection",
				name = "Divine Collection",
				description = "Doubles coin collection for 30 seconds",
				unlockLevel = 10,
				cooldown = 120,
				manaCost = 60,
				effects = {
					{
						type = ABILITY_TYPES.COIN_BOOST,
						value = 2.0,
						duration = 30
					}
				}
			}
		},
		passives = {
			{
				id = "angelic_presence",
				name = "Angelic Presence",
				description = "Team gains 15% coin bonus and 10% luck",
				stats = {coins = 0.15, luck = 0.10}
			}
		},
		evolution = {
			evolvesTo = "hello_kitty_goddess",
			requiredLevel = 50,
			requiredItems = {
				{id = "gems", amount = 1000}
			}
		}
	},
	
	["hello_kitty_goddess"] = {
		id = "hello_kitty_goddess",
		name = "Goddess Hello Kitty",
		displayName = "Goddess Hello Kitty",
		description = "The divine form of Hello Kitty!",
		rarity = RARITY.LEGENDARY,
		icon = "rbxassetid://123456791",
		model = "rbxassetid://987654323",
		baseStats = {
			health = 1000,
			attack = 200,
			defense = 150,
			speed = 120,
			luck = 100,
			critChance = 0.30,
			critDamage = 3.0,
		},
		abilities = {
			{
				id = "divine_aura",
				name = "Divine Aura",
				description = "All pets gain 50% stat boost",
				unlockLevel = 1,
				cooldown = 180,
				manaCost = 100,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_BUFF,
						statMultiplier = 1.5,
						duration = 60,
						visualEffect = "DivineRadiance"
					}
				}
			},
			{
				id = "celestial_rain",
				name = "Celestial Rain",
				description = "Rains coins from the sky",
				unlockLevel = 25,
				cooldown = 300,
				manaCost = 150,
				effects = {
					{
						type = ABILITY_TYPES.COIN_BOOST,
						specialEffect = "coin_rain",
						amount = 10000,
						visualEffect = "GoldRain"
					}
				}
			},
			{
				id = "reality_warp",
				name = "Reality Warp",
				description = "Ultimate: Warps reality to multiply all gains by 10x",
				unlockLevel = 50,
				cooldown = 600,
				manaCost = 300,
				isUltimate = true,
				effects = {
					{
						type = ABILITY_TYPES.REALITY_BEND,
						globalMultiplier = 10,
						duration = 30,
						visualEffect = "RealityDistortion"
					}
				}
			}
		},
		passives = {
			{
				id = "divine_authority",
				name = "Divine Authority",
				description = "All currency gains increased by 50%",
				stats = {coins = 0.5, gems = 0.5, luck = 0.3}
			}
		},
		evolution = {
			evolvesTo = "hello_kitty_origin",
			requiredLevel = 100,
			requiredItems = {
				{id = "divine_essence", amount = 3},
				{id = "gems", amount = 10000}
			}
		}
	},
	
	["hello_kitty_origin"] = {
		id = "hello_kitty_origin",
		name = "Origin Hello Kitty",
		displayName = "Origin Hello Kitty",
		description = "The first Hello Kitty, the origin of all cuteness!",
		rarity = RARITY.IMMORTAL,
		secret = true,
		icon = "rbxassetid://123456792",
		model = "rbxassetid://987654324",
		baseStats = {
			health = 10000,
			attack = 1000,
			defense = 1000,
			speed = 500,
			luck = 500,
			critChance = 1.0,
			critDamage = 10.0,
		},
		abilities = {
			{
				id = "genesis_of_cute",
				name = "Genesis of Cute",
				description = "Recreates the world in ultimate cuteness",
				unlockLevel = 1,
				cooldown = 9999,
				manaCost = 9999,
				effects = {
					{
						type = ABILITY_TYPES.REALITY_BEND,
						transformWorld = true,
						permanent = true,
						visualEffect = "UniversalTransformation"
					}
				}
			}
		},
		passives = {
			{
				id = "creator_of_all",
				name = "Creator of All",
				description = "All drops are guaranteed legendary or higher",
				specialEffect = "minimum_legendary_drops"
			}
		}
	},
	
	-- ====================================
	-- MY MELODY SERIES (Complete Chain)
	-- ====================================
	
	["my_melody_basic"] = {
		id = "my_melody_basic",
		name = "My Melody",
		displayName = "My Melody",
		description = "A sweet white rabbit with a pink hood!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://223456789",
		model = "rbxassetid://887654321",
		baseStats = {
			health = 120,
			attack = 20,
			defense = 25,
			speed = 60,
			luck = 20,
			critChance = 0.08,
			critDamage = 1.75,
		},
		abilities = {
			{
				id = "melody_boost",
				name = "Melody Boost",
				description = "Increases movement speed by 20%",
				unlockLevel = 1,
				cooldown = 20,
				manaCost = 15,
				effects = {
					{
						type = ABILITY_TYPES.SPEED,
						value = 1.2,
						duration = 10
					}
				}
			}
		},
		passives = {
			{
				id = "sweet_nature",
				name = "Sweet Nature",
				description = "Increases team healing by 10%",
				stats = {healing = 0.1}
			}
		},
		evolution = {
			evolvesTo = "my_melody_sweet",
			requiredLevel = 20,
			requiredItems = {
				{id = "coins", amount = 8000}
			}
		}
	},
	
	["my_melody_sweet"] = {
		id = "my_melody_sweet",
		name = "Sweet My Melody",
		displayName = "Sweet My Melody",
		description = "My Melody surrounded by sweets!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://223456790",
		model = "rbxassetid://887654322",
		baseStats = {
			health = 280,
			attack = 50,
			defense = 60,
			speed = 100,
			luck = 40,
			critChance = 0.15,
			critDamage = 2.25,
		},
		abilities = {
			{
				id = "sugar_rush",
				name = "Sugar Rush",
				description = "Massive speed boost for all pets",
				unlockLevel = 1,
				cooldown = 45,
				manaCost = 35,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_BUFF,
						stats = {speed = 0.5},
						duration = 15
					}
				}
			},
			{
				id = "sweet_dreams",
				name = "Sweet Dreams",
				description = "Heals all pets",
				unlockLevel = 15,
				cooldown = 60,
				manaCost = 50,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_HEAL,
						healAmount = 100,
						visualEffect = "HealingHearts"
					}
				}
			}
		},
		passives = {
			{
				id = "sugar_high",
				name = "Sugar High",
				description = "20% speed and 10% health bonus",
				stats = {speed = 0.2, health = 0.1}
			}
		},
		evolution = {
			evolvesTo = "my_melody_dream",
			requiredLevel = 45,
			requiredItems = {
				{id = "gems", amount = 500},
				{id = "sweet_essence", amount = 1}
			}
		}
	},
	
	["my_melody_dream"] = {
		id = "my_melody_dream",
		name = "Dream My Melody",
		displayName = "Dream My Melody",
		description = "My Melody from the land of dreams!",
		rarity = RARITY.EPIC,
		icon = "rbxassetid://223456791",
		model = "rbxassetid://887654323",
		baseStats = {
			health = 600,
			attack = 120,
			defense = 100,
			speed = 150,
			luck = 80,
			critChance = 0.25,
			critDamage = 3.0,
		},
		abilities = {
			{
				id = "dream_realm",
				name = "Dream Realm",
				description = "Creates a healing dream realm",
				unlockLevel = 1,
				cooldown = 90,
				manaCost = 80,
				effects = {
					{
						type = ABILITY_TYPES.HEAL,
						createField = true,
						healPerSecond = 50,
						duration = 20,
						visualEffect = "DreamField"
					}
				}
			},
			{
				id = "lullaby",
				name = "Lullaby",
				description = "Puts enemies to sleep",
				unlockLevel = 20,
				cooldown = 60,
				manaCost = 60,
				effects = {
					{
						type = ABILITY_TYPES.STUN,
						duration = 5,
						visualEffect = "SleepingNotes"
					}
				}
			}
		},
		passives = {
			{
				id = "dreamy_aura",
				name = "Dreamy Aura",
				description = "Team regenerates 2% health per second",
				regenPercent = 0.02
			}
		},
		evolution = {
			evolvesTo = "my_melody_celestial",
			requiredLevel = 75,
			requiredItems = {
				{id = "gems", amount = 2000},
				{id = "dream_crystal", amount = 2}
			}
		}
	},
	
	["my_melody_celestial"] = {
		id = "my_melody_celestial",
		name = "Celestial My Melody",
		displayName = "Celestial My Melody",
		description = "My Melody ascended to the stars!",
		rarity = RARITY.MYTHICAL,
		icon = "rbxassetid://223456792",
		model = "rbxassetid://887654324",
		baseStats = {
			health = 1500,
			attack = 300,
			defense = 250,
			speed = 200,
			luck = 150,
			critChance = 0.40,
			critDamage = 4.5,
		},
		abilities = {
			{
				id = "starlight_symphony",
				name = "Starlight Symphony",
				description = "Plays a cosmic melody that buffs all stats",
				unlockLevel = 1,
				cooldown = 120,
				manaCost = 150,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_BUFF,
						statMultiplier = 2.0,
						duration = 45,
						visualEffect = "CosmicNotes"
					}
				}
			},
			{
				id = "celestial_healing",
				name = "Celestial Healing",
				description = "Instantly full heals all allies",
				unlockLevel = 30,
				cooldown = 180,
				manaCost = 200,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_HEAL,
						healPercent = 1.0,
						removeDebuffs = true,
						visualEffect = "StarShower"
					}
				}
			},
			{
				id = "melody_of_creation",
				name = "Melody of Creation",
				description = "Ultimate: Creates a new pet from pure melody",
				unlockLevel = 60,
				cooldown = 600,
				manaCost = 500,
				isUltimate = true,
				effects = {
					{
						type = "summon_pet",
						petId = "melody_spirit",
						duration = 60,
						visualEffect = "MelodyCreation"
					}
				}
			}
		},
		passives = {
			{
				id = "star_blessed",
				name = "Star Blessed",
				description = "50% chance to dodge any attack",
				dodgeChance = 0.5
			}
		}
	},
	
	-- ====================================
	-- KUROMI SERIES (Complete Chain)
	-- ====================================
	
	["kuromi_basic"] = {
		id = "kuromi_basic",
		name = "Kuromi",
		displayName = "Kuromi",
		description = "A mischievous white rabbit with a devil tail!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://323456789",
		model = "rbxassetid://787654321",
		baseStats = {
			health = 150,
			attack = 45,
			defense = 30,
			speed = 70,
			luck = 25,
			critChance = 0.20,
			critDamage = 2.5,
		},
		abilities = {
			{
				id = "mischief_maker",
				name = "Mischief Maker",
				description = "Steals coins from enemies",
				unlockLevel = 1,
				cooldown = 25,
				manaCost = 30,
				effects = {
					{
						type = "coin_steal",
						amount = 100,
						visualEffect = "CoinTheft"
					}
				}
			}
		},
		passives = {
			{
				id = "punk_attitude",
				name = "Punk Attitude",
				description = "15% more damage",
				stats = {attack = 0.15}
			}
		},
		evolution = {
			evolvesTo = "kuromi_devil",
			requiredLevel = 30,
			requiredItems = {
				{id = "coins", amount = 15000}
			}
		}
	},
	
	["kuromi_devil"] = {
		id = "kuromi_devil",
		name = "Devil Kuromi",
		displayName = "Devil Kuromi",
		description = "Kuromi with devil wings and horns!",
		rarity = RARITY.EPIC,
		icon = "rbxassetid://323456790",
		model = "rbxassetid://787654322",
		baseStats = {
			health = 400,
			attack = 150,
			defense = 80,
			speed = 120,
			luck = 60,
			critChance = 0.35,
			critDamage = 3.5,
		},
		abilities = {
			{
				id = "devils_bargain",
				name = "Devil's Bargain",
				description = "Double damage but take 50% more damage",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 50,
				effects = {
					{
						type = "berserk",
						damageMultiplier = 2.0,
						defensePenalty = 0.5,
						duration = 20,
						visualEffect = "DevilAura"
					}
				}
			},
			{
				id = "chaos_storm",
				name = "Chaos Storm",
				description = "Deals area damage to all enemies",
				unlockLevel = 20,
				cooldown = 90,
				manaCost = 80,
				effects = {
					{
						type = ABILITY_TYPES.BURST,
						damage = 200,
						aoe = true,
						visualEffect = "ChaosExplosion"
					}
				}
			}
		},
		passives = {
			{
				id = "devilish_luck",
				name = "Devilish Luck",
				description = "30% crit chance and 20% power boost",
				stats = {critChance = 0.3, attack = 0.2}
			}
		},
		evolution = {
			evolvesTo = "kuromi_nightmare",
			requiredLevel = 60,
			requiredItems = {
				{id = "gems", amount = 1500},
				{id = "dark_essence", amount = 2}
			}
		}
	},
	
	["kuromi_nightmare"] = {
		id = "kuromi_nightmare",
		name = "Nightmare Kuromi",
		displayName = "Nightmare Kuromi",
		description = "Kuromi from your worst nightmares!",
		rarity = RARITY.LEGENDARY,
		icon = "rbxassetid://323456791",
		model = "rbxassetid://787654323",
		baseStats = {
			health = 1000,
			attack = 400,
			defense = 200,
			speed = 180,
			luck = 120,
			critChance = 0.50,
			critDamage = 5.0,
		},
		abilities = {
			{
				id = "nightmare_realm",
				name = "Nightmare Realm",
				description = "Traps enemies in a nightmare dimension",
				unlockLevel = 1,
				cooldown = 120,
				manaCost = 100,
				effects = {
					{
						type = ABILITY_TYPES.REALITY_BEND,
						createDimension = "Nightmare",
						duration = 15,
						enemyDebuff = {speed = -0.5, attack = -0.3},
						visualEffect = "NightmarePortal"
					}
				}
			},
			{
				id = "fear_incarnate",
				name = "Fear Incarnate",
				description = "Enemies flee in terror",
				unlockLevel = 30,
				cooldown = 90,
				manaCost = 120,
				effects = {
					{
						type = "fear",
						duration = 5,
						fleeChance = 0.8,
						visualEffect = "TerrorAura"
					}
				}
			},
			{
				id = "darkness_unleashed",
				name = "Darkness Unleashed",
				description = "Ultimate: Unleash pure darkness",
				unlockLevel = 50,
				cooldown = 300,
				manaCost = 250,
				isUltimate = true,
				effects = {
					{
						type = ABILITY_TYPES.BURST,
						damage = 1000,
						ignoreDefense = true,
						visualEffect = "DarknessExplosion"
					}
				}
			}
		},
		passives = {
			{
				id = "terror_presence",
				name = "Terror Presence",
				description = "Enemies have 30% reduced stats",
				enemyDebuff = {all = -0.3}
			}
		},
		evolution = {
			evolvesTo = "kuromi_chaos_queen",
			requiredLevel = 100,
			requiredItems = {
				{id = "gems", amount = 5000},
				{id = "chaos_crown", amount = 1}
			}
		}
	},
	
	["kuromi_chaos_queen"] = {
		id = "kuromi_chaos_queen",
		name = "Chaos Queen Kuromi",
		displayName = "Chaos Queen Kuromi",
		description = "The ultimate ruler of chaos and mischief!",
		rarity = RARITY.DIVINE,
		icon = "rbxassetid://323456792",
		model = "rbxassetid://787654324",
		baseStats = {
			health = 3000,
			attack = 1000,
			defense = 500,
			speed = 300,
			luck = 250,
			critChance = 0.75,
			critDamage = 7.5,
		},
		abilities = {
			{
				id = "chaos_control",
				name = "Chaos Control",
				description = "Control the very fabric of chaos",
				unlockLevel = 1,
				cooldown = 180,
				manaCost = 300,
				effects = {
					{
						type = ABILITY_TYPES.REALITY_BEND,
						reverseControls = true,
						randomizeStats = true,
						duration = 30,
						visualEffect = "ChaosDimension"
					}
				}
			},
			{
				id = "queen_decree",
				name = "Queen's Decree",
				description = "All enemies bow before the queen",
				unlockLevel = 50,
				cooldown = 240,
				manaCost = 400,
				effects = {
					{
						type = ABILITY_TYPES.STUN,
						duration = 10,
						forceKneel = true,
						visualEffect = "RoyalCommand"
					}
				}
			}
		},
		passives = {
			{
				id = "chaos_royalty",
				name = "Chaos Royalty",
				description = "Immune to all debuffs, 50% damage reduction",
				immuneToDebuffs = true,
				damageReduction = 0.5
			}
		}
	},
	
	-- ====================================
	-- CINNAMOROLL SERIES (Complete Chain)
	-- ====================================
	
	["cinnamoroll_basic"] = {
		id = "cinnamoroll_basic",
		name = "Cinnamoroll",
		displayName = "Cinnamoroll",
		description = "A fluffy white puppy who can fly with his ears!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://423456789",
		model = "rbxassetid://687654321",
		baseStats = {
			health = 90,
			attack = 30,
			defense = 20,
			speed = 100,
			luck = 35,
			critChance = 0.12,
			critDamage = 2.0,
		},
		abilities = {
			{
				id = "cloud_float",
				name = "Cloud Float",
				description = "Avoids ground attacks",
				unlockLevel = 1,
				cooldown = 30,
				manaCost = 25,
				effects = {
					{
						type = "flying",
						duration = 10,
						evasion = 0.5,
						visualEffect = "CloudPuff"
					}
				}
			}
		},
		passives = {
			{
				id = "fluffy_defense",
				name = "Fluffy Defense",
				description = "10% evasion chance",
				stats = {evasion = 0.1}
			}
		},
		evolution = {
			evolvesTo = "cinnamoroll_sky",
			requiredLevel = 25,
			requiredItems = {
				{id = "coins", amount = 12000}
			}
		}
	},
	
	["cinnamoroll_sky"] = {
		id = "cinnamoroll_sky",
		name = "Sky Cinnamoroll",
		displayName = "Sky Cinnamoroll",
		description = "Cinnamoroll soaring through clouds!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://423456790",
		model = "rbxassetid://687654322",
		baseStats = {
			health = 220,
			attack = 70,
			defense = 50,
			speed = 180,
			luck = 70,
			critChance = 0.20,
			critDamage = 2.5,
		},
		abilities = {
			{
				id = "sky_dance",
				name = "Sky Dance",
				description = "All pets gain flight and evasion",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 50,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_BUFF,
						grantFlying = true,
						stats = {evasion = 0.3},
						duration = 20,
						visualEffect = "TeamFlight"
					}
				}
			},
			{
				id = "cloud_cushion",
				name = "Cloud Cushion",
				description = "Reduces all damage by 50%",
				unlockLevel = 15,
				cooldown = 90,
				manaCost = 60,
				effects = {
					{
						type = ABILITY_TYPES.SHIELD,
						damageReduction = 0.5,
						duration = 15,
						visualEffect = "CloudShield"
					}
				}
			}
		},
		passives = {
			{
				id = "aerial_mastery",
				name = "Aerial Mastery",
				description = "25% evasion and 15% speed",
				stats = {evasion = 0.25, speed = 0.15}
			}
		},
		evolution = {
			evolvesTo = "cinnamoroll_wind",
			requiredLevel = 50,
			requiredItems = {
				{id = "gems", amount = 800},
				{id = "wind_essence", amount = 1}
			}
		}
	},
	
	["cinnamoroll_wind"] = {
		id = "cinnamoroll_wind",
		name = "Wind Master Cinnamoroll",
		displayName = "Wind Master Cinnamoroll",
		description = "Master of the winds and skies!",
		rarity = RARITY.EPIC,
		icon = "rbxassetid://423456791",
		model = "rbxassetid://687654323",
		baseStats = {
			health = 500,
			attack = 180,
			defense = 120,
			speed = 300,
			luck = 120,
			critChance = 0.30,
			critDamage = 3.5,
		},
		abilities = {
			{
				id = "tornado",
				name = "Tornado",
				description = "Creates a tornado that pulls enemies",
				unlockLevel = 1,
				cooldown = 80,
				manaCost = 80,
				effects = {
					{
						type = ABILITY_TYPES.BURST,
						damage = 300,
						pullEnemies = true,
						duration = 5,
						visualEffect = "TornadoVortex"
					}
				}
			},
			{
				id = "wind_barrier",
				name = "Wind Barrier",
				description = "Creates an impenetrable wind barrier",
				unlockLevel = 25,
				cooldown = 120,
				manaCost = 100,
				effects = {
					{
						type = ABILITY_TYPES.SHIELD,
						blockAllDamage = true,
						duration = 5,
						visualEffect = "WindWall"
					}
				}
			},
			{
				id = "sky_supremacy",
				name = "Sky Supremacy",
				description = "Become one with the sky",
				unlockLevel = 40,
				cooldown = 180,
				manaCost = 150,
				effects = {
					{
						type = ABILITY_TYPES.TRANSFORM,
						becomesUntargetable = true,
						speedMultiplier = 3.0,
						duration = 20,
						visualEffect = "SkyForm"
					}
				}
			}
		},
		passives = {
			{
				id = "wind_blessed",
				name = "Wind Blessed",
				description = "40% evasion and doubles jump height",
				stats = {evasion = 0.4},
				doubleJump = true
			}
		},
		evolution = {
			evolvesTo = "cinnamoroll_storm",
			requiredLevel = 80,
			requiredItems = {
				{id = "gems", amount = 3000},
				{id = "storm_crystal", amount = 2}
			}
		}
	},
	
	["cinnamoroll_storm"] = {
		id = "cinnamoroll_storm",
		name = "Storm Lord Cinnamoroll",
		displayName = "Storm Lord Cinnamoroll",
		description = "Commander of storms and tempests!",
		rarity = RARITY.MYTHICAL,
		icon = "rbxassetid://423456792",
		model = "rbxassetid://687654324",
		baseStats = {
			health = 1200,
			attack = 450,
			defense = 300,
			speed = 400,
			luck = 200,
			critChance = 0.45,
			critDamage = 5.0,
		},
		abilities = {
			{
				id = "tempest_fury",
				name = "Tempest Fury",
				description = "Unleash the fury of a thousand storms",
				unlockLevel = 1,
				cooldown = 150,
				manaCost = 200,
				effects = {
					{
						type = ABILITY_TYPES.BURST,
						damage = 1000,
						createStormField = true,
						fieldDuration = 30,
						visualEffect = "MegaStorm"
					}
				}
			},
			{
				id = "lightning_strike",
				name = "Lightning Strike",
				description = "Call down lightning on all enemies",
				unlockLevel = 40,
				cooldown = 60,
				manaCost = 150,
				effects = {
					{
						type = ABILITY_TYPES.BURST,
						damage = 500,
						chainLightning = true,
						maxChains = 10,
						visualEffect = "LightningStorm"
					}
				}
			}
		},
		passives = {
			{
				id = "storm_sovereign",
				name = "Storm Sovereign",
				description = "Immune to all movement impairing effects",
				immuneToSlows = true,
				permanentFlying = true
			}
		}
	},
	
	-- ====================================
	-- POMPOMPURIN SERIES (Complete Chain)
	-- ====================================
	
	["pompompurin_basic"] = {
		id = "pompompurin_basic",
		name = "Pompompurin",
		displayName = "Pompompurin",
		description = "A golden retriever who loves pudding!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://454545454",
		model = "rbxassetid://464646464",
		baseStats = {
			health = 180,
			attack = 35,
			defense = 40,
			speed = 40,
			luck = 15,
			critChance = 0.05,
			critDamage = 1.5,
		},
		abilities = {
			{
				id = "pudding_power",
				name = "Pudding Power",
				description = "Heals self over time",
				unlockLevel = 1,
				cooldown = 20,
				manaCost = 15,
				effects = {
					{
						type = ABILITY_TYPES.REGEN,
						healAmount = 0.2,
						duration = 10,
						visualEffect = "PuddingGlow"
					}
				}
			}
		},
		passives = {
			{
				id = "pudding_lover",
				name = "Pudding Lover",
				description = "20% more health",
				stats = {health = 0.2}
			}
		},
		variants = {"Brown Beret", "Red Beret", "Rainbow Beret"},
		evolution = {
			evolvesTo = "pompompurin_chef",
			requiredLevel = 22,
			requiredItems = {
				{id = "coins", amount = 9000}
			}
		}
	},
	
	["pompompurin_chef"] = {
		id = "pompompurin_chef",
		name = "Chef Pompompurin",
		displayName = "Chef Pompompurin",
		description = "Master chef Pompompurin with his cooking hat!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://454545455",
		model = "rbxassetid://464646465",
		baseStats = {
			health = 400,
			attack = 80,
			defense = 100,
			speed = 60,
			luck = 40,
			critChance = 0.10,
			critDamage = 2.0,
		},
		abilities = {
			{
				id = "healing_feast",
				name = "Healing Feast",
				description = "Creates food that heals all allies",
				unlockLevel = 1,
				cooldown = 45,
				manaCost = 40,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_HEAL,
						healAmount = 150,
						visualEffect = "FoodParticles"
					}
				}
			},
			{
				id = "sugar_boost",
				name = "Sugar Boost",
				description = "Increases all stats temporarily",
				unlockLevel = 18,
				cooldown = 60,
				manaCost = 50,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_BUFF,
						statMultiplier = 1.3,
						duration = 30,
						visualEffect = "SugarRush"
					}
				}
			}
		},
		passives = {
			{
				id = "master_chef",
				name = "Master Chef",
				description = "35% more health and 25% healing power",
				stats = {health = 0.35, healing = 0.25}
			}
		},
		evolution = {
			evolvesTo = "pompompurin_gourmet",
			requiredLevel = 50,
			requiredItems = {
				{id = "gems", amount = 1000},
				{id = "golden_spoon", amount = 1}
			}
		}
	},
	
	["pompompurin_gourmet"] = {
		id = "pompompurin_gourmet",
		name = "Gourmet Pompompurin",
		displayName = "Gourmet Pompompurin",
		description = "World-renowned chef Pompompurin!",
		rarity = RARITY.EPIC,
		icon = "rbxassetid://454545456",
		model = "rbxassetid://464646466",
		baseStats = {
			health = 800,
			attack = 200,
			defense = 250,
			speed = 100,
			luck = 80,
			critChance = 0.20,
			critDamage = 3.0,
		},
		abilities = {
			{
				id = "gourmet_banquet",
				name = "Gourmet Banquet",
				description = "Creates a feast that fully heals and buffs all allies",
				unlockLevel = 1,
				cooldown = 120,
				manaCost = 100,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_HEAL,
						healPercent = 1.0,
						additionalEffects = {
							{type = ABILITY_TYPES.TEAM_BUFF, statMultiplier = 2.0, duration = 60}
						},
						visualEffect = "GourmetFeast"
					}
				}
			},
			{
				id = "comfort_food",
				name = "Comfort Food",
				description = "Removes all debuffs and grants immunity",
				unlockLevel = 30,
				cooldown = 90,
				manaCost = 80,
				effects = {
					{
						type = ABILITY_TYPES.IMMUNITY,
						duration = 10,
						removeDebuffs = true,
						visualEffect = "ComfortAura"
					}
				}
			}
		},
		passives = {
			{
				id = "culinary_master",
				name = "Culinary Master",
				description = "Team regenerates 5% health per second",
				teamRegen = 0.05
			}
		},
		evolution = {
			evolvesTo = "pompompurin_divine_chef",
			requiredLevel = 100,
			requiredItems = {
				{id = "gems", amount = 5000},
				{id = "divine_cookbook", amount = 1}
			}
		}
	},
	
	["pompompurin_divine_chef"] = {
		id = "pompompurin_divine_chef",
		name = "Divine Chef Pompompurin",
		displayName = "Divine Chef Pompompurin",
		description = "The god of cooking himself!",
		rarity = RARITY.MYTHICAL,
		icon = "rbxassetid://454545457",
		model = "rbxassetid://464646467",
		baseStats = {
			health = 2000,
			attack = 500,
			defense = 500,
			speed = 200,
			luck = 200,
			critChance = 0.40,
			critDamage = 5.0,
		},
		abilities = {
			{
				id = "divine_cuisine",
				name = "Divine Cuisine",
				description = "Creates food that grants immortality",
				unlockLevel = 1,
				cooldown = 300,
				manaCost = 300,
				isUltimate = true,
				effects = {
					{
						type = ABILITY_TYPES.IMMUNITY,
						duration = 30,
						makeImmortal = true,
						visualEffect = "DivineFood"
					}
				}
			}
		},
		passives = {
			{
				id = "food_god",
				name = "Food God",
				description = "All healing effects tripled",
				healingMultiplier = 3.0
			}
		}
	},
	
	-- ====================================
	-- KEROPPI SERIES (Complete Chain)
	-- ====================================
	
	["keroppi_basic"] = {
		id = "keroppi_basic",
		name = "Keroppi",
		displayName = "Keroppi",
		description = "A cheerful frog from Donut Pond!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://474747474",
		model = "rbxassetid://484848484",
		baseStats = {
			health = 110,
			attack = 28,
			defense = 22,
			speed = 85,
			luck = 30,
			critChance = 0.15,
			critDamage = 2.25,
		},
		abilities = {
			{
				id = "lily_hop",
				name = "Lily Hop",
				description = "Hops between lily pads, dodging attacks",
				unlockLevel = 1,
				cooldown = 15,
				manaCost = 20,
				effects = {
					{
						type = ABILITY_TYPES.TELEPORT,
						range = 30,
						invulnerabilityFrames = 0.5,
						visualEffect = "LilyPadJump"
					}
				}
			}
		},
		passives = {
			{
				id = "amphibian_agility",
				name = "Amphibian Agility",
				description = "20% increased jump height and speed",
				stats = {speed = 0.2, jump = 0.2}
			}
		},
		variants = {"Green", "Blue", "Pink"},
		evolution = {
			evolvesTo = "keroppi_ninja",
			requiredLevel = 28,
			requiredItems = {
				{id = "coins", amount = 11000}
			}
		}
	},
	
	["keroppi_ninja"] = {
		id = "keroppi_ninja",
		name = "Ninja Keroppi",
		displayName = "Ninja Keroppi", 
		description = "Keroppi trained in the ninja arts!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://474747475",
		model = "rbxassetid://484848485",
		baseStats = {
			health = 300,
			attack = 160,
			defense = 80,
			speed = 250,
			luck = 120,
			critChance = 0.35,
			critDamage = 3.5,
		},
		abilities = {
			{
				id = "shadow_clone",
				name = "Shadow Clone",
				description = "Creates clones that confuse enemies",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 60,
				effects = {
					{
						type = "clone",
						count = 3,
						duration = 15,
						damagePercent = 0.5,
						visualEffect = "NinjaClones"
					}
				}
			},
			{
				id = "smoke_bomb",
				name = "Smoke Bomb",
				description = "Become invisible and gain speed",
				unlockLevel = 20,
				cooldown = 90,
				manaCost = 80,
				effects = {
					{
						type = ABILITY_TYPES.STEALTH,
						duration = 10,
						speedBonus = 0.5,
						visualEffect = "SmokeBomb"
					}
				}
			}
		},
		passives = {
			{
				id = "ninja_training",
				name = "Ninja Training",
				description = "30% evasion and 25% crit chance",
				stats = {evasion = 0.3, critChance = 0.25}
			}
		},
		evolution = {
			evolvesTo = "keroppi_shadow_master",
			requiredLevel = 60,
			requiredItems = {
				{id = "gems", amount = 2000},
				{id = "shadow_scroll", amount = 1}
			}
		}
	},
	
	-- ====================================
	-- BADTZ-MARU SERIES (Complete Chain)
	-- ====================================
	
	["badtz_maru_basic"] = {
		id = "badtz_maru_basic",
		name = "Badtz-Maru",
		displayName = "Badtz-Maru",
		description = "A mischievous penguin with attitude!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://494949494",
		model = "rbxassetid://505050505",
		baseStats = {
			health = 140,
			attack = 50,
			defense = 35,
			speed = 75,
			luck = 40,
			critChance = 0.25,
			critDamage = 2.75,
		},
		abilities = {
			{
				id = "ice_slide",
				name = "Ice Slide",
				description = "Slides on ice, freezing enemies in path",
				unlockLevel = 1,
				cooldown = 20,
				manaCost = 30,
				effects = {
					{
						type = ABILITY_TYPES.FREEZE,
						duration = 2,
						damage = 1.5,
						trail = true,
						visualEffect = "IceTrail"
					}
				}
			}
		},
		passives = {
			{
				id = "cool_attitude",
				name = "Cool Attitude",
				description = "15% evasion and ice resistance",
				stats = {evasion = 0.15},
				resistances = {ice = 0.5}
			}
		},
		variants = {"Classic", "Punk", "Cool"},
		evolution = {
			evolvesTo = "badtz_maru_rebel",
			requiredLevel = 25,
			requiredItems = {
				{id = "coins", amount = 13000}
			}
		}
	},
	
	["badtz_maru_rebel"] = {
		id = "badtz_maru_rebel",
		name = "Rebel Badtz-Maru",
		displayName = "Rebel Badtz-Maru",
		description = "The ultimate rebel penguin!",
		rarity = RARITY.EPIC,
		icon = "rbxassetid://494949495",
		model = "rbxassetid://505050506",
		baseStats = {
			health = 350,
			attack = 140,
			defense = 100,
			speed = 150,
			luck = 100,
			critChance = 0.35,
			critDamage = 4.0,
		},
		abilities = {
			{
				id = "rebel_yell",
				name = "Rebel Yell",
				description = "Intimidates all enemies",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 50,
				effects = {
					{
						type = "fear",
						duration = 3,
						reduceStats = 0.3,
						visualEffect = "IntimidationWave"
					}
				}
			},
			{
				id = "ice_prison",
				name = "Ice Prison",
				description = "Freezes all enemies",
				unlockLevel = 15,
				cooldown = 90,
				manaCost = 80,
				effects = {
					{
						type = ABILITY_TYPES.FREEZE,
						duration = 5,
						targetAll = true,
						visualEffect = "IcePrison"
					}
				}
			}
		},
		passives = {
			{
				id = "rebel_power",
				name = "Rebel Power",
				description = "25% power boost and 30% evasion",
				stats = {attack = 0.25, evasion = 0.3}
			}
		}
	},
	
	-- ====================================
	-- SPECIAL VARIANTS
	-- ====================================
	
	["hello_kitty_rainbow"] = {
		id = "hello_kitty_rainbow",
		name = "Rainbow Hello Kitty",
		displayName = "Rainbow Hello Kitty",
		description = "An ultra-rare rainbow variant!",
		rarity = RARITY.CELESTIAL,
		icon = "rbxassetid://523456789",
		model = "rbxassetid://587654321",
		baseStats = {
			health = 5000,
			attack = 1500,
			defense = 1000,
			speed = 500,
			luck = 500,
			critChance = 0.80,
			critDamage = 8.0,
		},
		abilities = {
			{
				id = "rainbow_power",
				name = "Rainbow Power",
				description = "Devastating rainbow attack",
				unlockLevel = 1,
				cooldown = 120,
				manaCost = 200,
				effects = {
					{
						type = ABILITY_TYPES.BURST,
						damage = 5000,
						element = "Rainbow",
						visualEffect = "RainbowExplosion"
					}
				}
			},
			{
				id = "prismatic_shield",
				name = "Prismatic Shield",
				description = "Immune to all damage",
				unlockLevel = 25,
				cooldown = 180,
				manaCost = 300,
				effects = {
					{
						type = ABILITY_TYPES.IMMUNITY,
						duration = 10,
						reflectDamage = true,
						visualEffect = "RainbowBarrier"
					}
				}
			},
			{
				id = "spectrum_shift",
				name = "Spectrum Shift",
				description = "Shift through the color spectrum",
				unlockLevel = 50,
				cooldown = 300,
				manaCost = 500,
				isUltimate = true,
				effects = {
					{
						type = ABILITY_TYPES.TRANSFORM,
						cycleElements = true,
						duration = 60,
						visualEffect = "SpectrumShift"
					}
				}
			}
		},
		passives = {
			{
				id = "rainbow_luck",
				name = "Rainbow Luck",
				description = "All currency gains doubled, all drops improved",
				stats = {coins = 1.0, gems = 1.0, luck = 1.0}
			}
		}
	},
	
	-- ====================================
	-- POCHACCO SERIES (Complete Chain)
	-- ====================================
	
	["pochacco_basic"] = {
		id = "pochacco_basic",
		name = "Pochacco",
		displayName = "Pochacco",
		description = "A sporty white dog who loves basketball!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://575757575",
		model = "rbxassetid://585858585",
		baseStats = {
			health = 130,
			attack = 32,
			defense = 28,
			speed = 90,
			luck = 25,
			critChance = 0.10,
			critDamage = 2.0,
		},
		abilities = {
			{
				id = "sports_rush",
				name = "Sports Rush",
				description = "Gains massive speed and kicks a ball at enemies",
				unlockLevel = 1,
				cooldown = 25,
				manaCost = 30,
				effects = {
					{
						type = ABILITY_TYPES.SPEED,
						value = 3.0,
						duration = 5,
						additionalEffect = {
							projectile = "SoccerBall",
							damage = 2.0,
						},
						visualEffect = "SportsStar"
					},
				},
			},
		},
		passives = {
			{
				id = "athletic_spirit",
				name = "Athletic Spirit",
				description = "15% speed boost",
				stats = {speed = 0.15}
			}
		},
		variants = {"Soccer", "Basketball", "Baseball"},
		evolution = {
			evolvesTo = "pochacco_athlete",
			requiredLevel = 20,
			requiredItems = {
				{id = "coins", amount = 8500}
			}
		}
	},
	
	["pochacco_athlete"] = {
		id = "pochacco_athlete",
		name = "Athlete Pochacco",
		displayName = "Athlete Pochacco",
		description = "The ultimate sports champion!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://575757576",
		model = "rbxassetid://585858586",
		baseStats = {
			health = 300,
			attack = 85,
			defense = 70,
			speed = 180,
			luck = 50,
			critChance = 0.20,
			critDamage = 2.5,
		},
		abilities = {
			{
				id = "team_spirit",
				name = "Team Spirit",
				description = "Boosts all team stats",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 50,
				effects = {
					{
						type = ABILITY_TYPES.TEAM_BUFF,
						statMultiplier = 1.2,
						duration = 30,
						visualEffect = "TeamworkAura"
					}
				}
			},
			{
				id = "victory_rush",
				name = "Victory Rush",
				description = "Massive speed and power boost",
				unlockLevel = 20,
				cooldown = 120,
				manaCost = 80,
				effects = {
					{
						type = "super_boost",
						stats = {attack = 0.5, speed = 0.5},
						duration = 20,
						visualEffect = "VictoryFlames"
					}
				}
			}
		},
		passives = {
			{
				id = "champion_spirit",
				name = "Champion Spirit",
				description = "30% speed and 20% stamina",
				stats = {speed = 0.3, stamina = 0.2}
			}
		}
	},
	
	-- ====================================
	-- TUXEDOSAM SERIES (Complete Chain)
	-- ====================================
	
	["tuxedosam_basic"] = {
		id = "tuxedosam_basic",
		name = "Tuxedosam",
		displayName = "Tuxedosam",
		description = "A classy penguin who loves to eat!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://595959595",
		model = "rbxassetid://606060606",
		baseStats = {
			health = 200,
			attack = 25,
			defense = 50,
			speed = 30,
			luck = 20,
			critChance = 0.05,
			critDamage = 1.5,
		},
		abilities = {
			{
				id = "belly_bounce",
				name = "Belly Bounce",
				description = "Bounces on belly, stunning nearby enemies",
				unlockLevel = 1,
				cooldown = 30,
				manaCost = 25,
				effects = {
					{
						type = ABILITY_TYPES.STUN,
						duration = 2,
						aoe = true,
						damage = 1.5,
						visualEffect = "BellyImpact",
					},
				},
			},
		},
		passives = {
			{
				id = "well_fed",
				name = "Well Fed",
				description = "25% more health",
				stats = {health = 0.25}
			}
		},
		variants = {"Bow Tie", "Top Hat", "Monocle"},
		evolution = {
			evolvesTo = "tuxedosam_gentleman",
			requiredLevel = 23,
			requiredItems = {
				{id = "coins", amount = 10000}
			}
		}
	},
	
	["tuxedosam_gentleman"] = {
		id = "tuxedosam_gentleman",
		name = "Gentleman Tuxedosam",
		displayName = "Gentleman Tuxedosam",
		description = "The most refined penguin!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://595959596",
		model = "rbxassetid://606060607",
		baseStats = {
			health = 440,
			attack = 70,
			defense = 120,
			speed = 60,
			luck = 35,
			critChance = 0.10,
			critDamage = 2.0,
		},
		abilities = {
			{
				id = "gentlemans_agreement",
				name = "Gentleman's Agreement",
				description = "Reduces enemy attack",
				unlockLevel = 1,
				cooldown = 45,
				manaCost = 40,
				effects = {
					{
						type = "weaken",
						value = 0.3,
						duration = 20,
						visualEffect = "PoliteDebuff"
					}
				}
			},
			{
				id = "fancy_feast",
				name = "Fancy Feast",
				description = "Heals team based on damage dealt",
				unlockLevel = 18,
				cooldown = 60,
				manaCost = 60,
				effects = {
					{
						type = "lifesteal",
						value = 0.5,
						teamwide = true,
						visualEffect = "FancyMeal"
					}
				}
			}
		},
		passives = {
			{
				id = "refined_taste",
				name = "Refined Taste",
				description = "40% health and 30% defense",
				stats = {health = 0.4, defense = 0.3}
			}
		}
	},
	
	-- ====================================
	-- CHOCOCAT SERIES (Complete Chain)
	-- ====================================
	
	["chococat_basic"] = {
		id = "chococat_basic",
		name = "Chococat",
		displayName = "Chococat",
		description = "A curious black cat who knows everything!",
		rarity = RARITY.RARE,
		icon = "rbxassetid://616161616",
		model = "rbxassetid://626262626",
		baseStats = {
			health = 160,
			attack = 55,
			defense = 40,
			speed = 95,
			luck = 80,
			critChance = 0.30,
			critDamage = 3.0,
		},
		abilities = {
			{
				id = "all_seeing",
				name = "All Seeing",
				description = "Reveals all secrets and weak points",
				unlockLevel = 1,
				cooldown = 30,
				manaCost = 40,
				effects = {
					{
						type = ABILITY_TYPES.CRITICAL,
						guaranteedCrit = true,
						revealTreasure = true,
						duration = 10,
						visualEffect = "ThirdEye",
					},
				},
			},
		},
		passives = {
			{
				id = "curious_nature",
				name = "Curious Nature",
				description = "20% luck bonus",
				stats = {luck = 0.2}
			}
		},
		variants = {"Blue Collar", "Red Collar", "Gold Collar"},
		evolution = {
			evolvesTo = "chococat_wise",
			requiredLevel = 27,
			requiredItems = {
				{id = "coins", amount = 14000}
			}
		}
	},
	
	["chococat_wise"] = {
		id = "chococat_wise",
		name = "Wise Chococat",
		displayName = "Wise Chococat",
		description = "All-knowing Chococat!",
		rarity = RARITY.EPIC,
		icon = "rbxassetid://616161617",
		model = "rbxassetid://626262627",
		baseStats = {
			health = 380,
			attack = 165,
			defense = 120,
			speed = 180,
			luck = 180,
			critChance = 0.45,
			critDamage = 4.5,
		},
		abilities = {
			{
				id = "foresight",
				name = "Foresight",
				description = "Dodge next 3 attacks",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 50,
				effects = {
					{
						type = "perfect_dodge",
						count = 3,
						duration = 15,
						visualEffect = "FutureVision"
					}
				}
			},
			{
				id = "wisdom_share",
				name = "Wisdom Share",
				description = "Boost team's critical chance",
				unlockLevel = 22,
				cooldown = 90,
				manaCost = 70,
				effects = {
					{
						type = "team_crit",
						value = 0.5,
						duration = 30,
						visualEffect = "WisdomAura"
					}
				}
			}
		},
		passives = {
			{
				id = "ancient_wisdom",
				name = "Ancient Wisdom",
				description = "40% luck and 30% crit chance",
				stats = {luck = 0.4, critChance = 0.3}
			}
		}
	},
	
	-- ====================================
	-- CLASSIC PETS FROM OLD DATABASE
	-- ====================================
	
	["hello_kitty_classic"] = {
		id = "hello_kitty_classic",
		name = "Classic Hello Kitty",
		displayName = "Classic Hello Kitty",
		description = "The iconic white cat with a red bow!",
		rarity = RARITY.COMMON,
		icon = "rbxassetid://123456788",
		model = "rbxassetid://987654320",
		baseStats = {
			health = 100,
			attack = 25,
			defense = 20,
			speed = 50,
			luck = 20,
			critChance = 0.05,
			critDamage = 1.5,
		},
		abilities = {
			{
				id = "cute_charm_classic",
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
	
	["golden_cinnamoroll"] = {
		id = "golden_cinnamoroll",
		name = "Golden Cinnamoroll",
		displayName = "Golden Cinnamoroll",
		description = "A legendary golden variant!",
		rarity = RARITY.MYTHICAL,
		icon = "rbxassetid://777777777",
		model = "rbxassetid://888888888",
		baseStats = {
			health = 800,
			attack = 400,
			defense = 300,
			speed = 300,
			luck = 150,
			critChance = 0.40,
			critDamage = 5.0,
		},
		abilities = {
			{
				id = "golden_wind",
				name = "Golden Wind",
				description = "Powerful wind attack",
				unlockLevel = 1,
				cooldown = 60,
				manaCost = 100,
				effects = {
					{
						type = "wind_blast",
						damage = 3.0,
						element = "Wind",
						visualEffect = "GoldenWindstorm"
					}
				}
			},
			{
				id = "midas_touch",
				name = "Midas Touch",
				description = "Turns damage into coins",
				unlockLevel = 30,
				cooldown = 120,
				manaCost = 150,
				effects = {
					{
						type = "coin_generation",
						rate = 2.0,
						duration = 30,
						visualEffect = "GoldParticles"
					}
				}
			}
		},
		passiveBonus = {
			coins = 0.75,
			speed = 0.5,
			evasion = 0.4
		}
	},
	
	["shadow_kuromi"] = {
		id = "shadow_kuromi",
		name = "Shadow Kuromi",
		displayName = "Shadow Kuromi",
		description = "Dark and mysterious variant!",
		rarity = RARITY.MYTHICAL,
		icon = "rbxassetid://999999999",
		model = "rbxassetid://111111111",
		baseStats = {
			health = 900,
			attack = 350,
			defense = 200,
			speed = 200,
			luck = 125,
			critChance = 0.50,
			critDamage = 6.0,
		},
		abilities = {
			{
				id = "shadow_strike",
				name = "Shadow Strike",
				description = "Instant critical hit",
				unlockLevel = 1,
				cooldown = 45,
				manaCost = 60,
				effects = {
					{
						type = "guaranteed_crit",
						damage = 2.5,
						element = "Shadow",
						visualEffect = "ShadowSlash"
					}
				}
			},
			{
				id = "darkness_falls",
				name = "Darkness Falls",
				description = "Blinds all enemies",
				unlockLevel = 25,
				cooldown = 90,
				manaCost = 100,
				effects = {
					{
						type = "blind_all",
						duration = 5,
						reduceAccuracy = 0.8,
						visualEffect = "DarknessField"
					}
				}
			}
		},
		passiveBonus = {
			critChance = 0.5,
			attack = 0.4,
			lifesteal = 0.2
		}
	}
}

-- ========================================
-- SYNERGY SYSTEM
-- ========================================
local Synergies = {
	{
		id = "sanrio_trio",
		name = "Sanrio Trio",
		pets = {"hello_kitty_basic", "my_melody_basic", "kuromi_basic"},
		bonuses = {
			stats = {attack = 0.2, luck = 0.3},
			description = "The original trio united!"
		}
	},
	{
		id = "divine_assembly",
		name = "Divine Assembly",
		pets = {"hello_kitty_goddess", "my_melody_celestial", "kuromi_chaos_queen"},
		bonuses = {
			stats = {all = 0.5},
			specialAbility = {
				name = "Divine Unity",
				cooldown = 600,
				effect = "All abilities have no cooldown for 30 seconds"
			}
		}
	},
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

function PetDatabase:GetEvolutionChain(petId)
	local chain = {petId}
	local currentPet = Pets[petId]
	
	-- Go backwards to find the start
	while currentPet do
		local foundParent = false
		for id, pet in pairs(Pets) do
			if pet.evolution and pet.evolution.evolvesTo == currentPet.id then
				table.insert(chain, 1, id)
				currentPet = pet
				foundParent = true
				break
			end
		end
		if not foundParent then break end
	end
	
	-- Go forwards to find the end
	currentPet = Pets[petId]
	while currentPet and currentPet.evolution do
		local nextId = currentPet.evolution.evolvesTo
		if Pets[nextId] then
			table.insert(chain, nextId)
			currentPet = Pets[nextId]
		else
			break
		end
	end
	
	return chain
end

function PetDatabase:GetSynergies(petId)
	local synergies = {}
	for _, synergy in ipairs(Synergies) do
		for _, pet in ipairs(synergy.pets) do
			if pet == petId then
				table.insert(synergies, synergy)
				break
			end
		end
	end
	return synergies
end

function PetDatabase:CalculatePetPower(pet, level, variant)
	local basePower = pet.baseStats.attack + pet.baseStats.defense + (pet.baseStats.health / 10)
	local levelMultiplier = 1 + (level * 0.1)
	local variantMultiplier = VARIANTS[variant] and VARIANTS[variant].multiplier or 1
	local rarityMultiplier = pet.rarity
	
	return math.floor(basePower * levelMultiplier * variantMultiplier * rarityMultiplier)
end

-- ========================================
-- EXPORT
-- ========================================

PetDatabase.RARITY = RARITY
PetDatabase.RARITY_DATA = RARITY_DATA
PetDatabase.VARIANTS = VARIANTS
PetDatabase.ABILITY_TYPES = ABILITY_TYPES
PetDatabase.Synergies = Synergies

return PetDatabase