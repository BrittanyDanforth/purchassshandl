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
-- RARITY TIERS (FOMO-INDUCING)
-- ========================================
local RARITY = Configuration.RARITY or {
	COMMON = 1,      -- 35% drop rate
	RARE = 2,        -- 25% drop rate  
	EPIC = 3,        -- 20% drop rate
	LEGENDARY = 4,   -- 10% drop rate
	MYTHICAL = 5,    -- 5% drop rate
	DIVINE = 6,      -- 3% drop rate
	CELESTIAL = 7,   -- 1.5% drop rate
	IMMORTAL = 8,    -- 0.5% drop rate
}

-- Rarity visual data
local RARITY_DATA = {
	[RARITY.COMMON] = {
		name = "Common",
		color = Color3.fromRGB(200, 200, 200),
		particleEffect = "CommonSparkle",
		glowIntensity = 0.1,
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
	
	-- More pets would continue here...
	-- This is a sample structure showing complete evolution chains
	-- The full 200 pets would follow this pattern
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