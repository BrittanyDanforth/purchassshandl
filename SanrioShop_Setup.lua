--[[
    SANRIO SHOP - MAIN LOCALSCRIPT
    Place this as a LocalScript in StarterPlayer > StarterPlayerScripts
    Name it: SanrioShop
    
    Then create two ModuleScripts as children of this LocalScript:
    - SanrioShop_Core (ModuleScript)
    - SanrioShop_UI (ModuleScript)
--]]

-- This is the main LocalScript that loads the modules
local script = script -- Reference to this LocalScript

-- Wait for modules
local Core = require(script:WaitForChild("SanrioShop_Core"))
local UI = require(script:WaitForChild("SanrioShop_UI"))

-- Load and initialize the main shop system
local MainModule = script:WaitForChild("SanrioShop_Main")

-- Since the Main module needs Core and UI, we'll include it directly here
-- (Copy the entire SanrioShop_Main.lua content below)

-- [INSERT SANRIO SHOP MAIN CODE HERE]

-- The Main module code will initialize automatically when this script runs