# PetDatabase Fix Instructions

## Issue
The PetDatabase module was failing to load with "table index is nil" error because:
1. It was trying to access Configuration.RARITY before it was fully loaded
2. Client modules were trying to access it from the wrong location

## Fixes Applied

### 1. Fixed PetDatabase Loading
- Added proper checks for Configuration.RARITY existence
- Added fallback values if Configuration isn't loaded yet
- Made the module more robust against loading order issues

### 2. Fixed Client References
- Updated InventoryUI.lua to use pcall when requiring PetDatabase
- Updated PetDetailsUI.lua to use pcall when requiring PetDatabase
- Both now properly handle loading failures

### 3. Created SharedModules Structure
- Created SharedModules/ directory for modules that need to be accessed by both client and server
- Copied PetDatabase.lua to SharedModules/

## Installation Steps

1. **In Roblox Studio:**
   - Create a folder called "Modules" in ReplicatedStorage
   - Inside Modules, create a folder called "Shared"
   
2. **Copy the SharedModules:**
   - Copy `SharedModules/PetDatabase.lua` to `ReplicatedStorage.Modules.Shared.PetDatabase`
   - Also copy `Janitor.lua` to `ReplicatedStorage.Modules.Shared.Janitor` (if not already there)

3. **The modules should now be accessible to both client and server**

## Testing
- The PetDatabase error should no longer appear
- InventoryUI should load without errors
- PetDetailsUI should display pet information correctly
- Synergy system should work when pets are equipped

## Structure
```
ReplicatedStorage
└── Modules
    └── Shared
        ├── PetDatabase
        └── Janitor
```