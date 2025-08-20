# Auto-Collect Integration Guide

## Overview
This guide explains how to integrate the Auto-Collect gamepass (ID: 1412171840) with your existing tycoon system.

## Files Created

### 1. **CreateMoneyShop_Polished.lua**
- Enhanced version of your money shop with gamepasses
- Auto-Collect gamepass is the first item in the gamepass tab
- Fetches real-time prices from Roblox
- Includes all visual polish and fixes you requested

### 2. **AutoCollectAddon.lua**
- Contains the auto-collect functionality
- Should be integrated into your existing PurchaseHandler

## Integration Steps

### Step 1: Replace Shop Script
1. Delete or disable your current `CreateMoneyShop` script
2. Copy `CreateMoneyShop_Polished.lua` to `StarterPlayer > StarterPlayerScripts`
3. Rename it to `CreateMoneyShop` (or keep the new name)

### Step 2: Integrate Auto-Collect into PurchaseHandler

Since you have 4 separate PurchaseHandler scripts (one in each tycoon), you need to add the auto-collect code to each one. Here's how:

1. Open one of your PurchaseHandler scripts
2. Add this at the top with other services:
```lua
local MarketplaceService = game:GetService("MarketplaceService")
```

3. Add to your CONFIG table:
```lua
AUTO_COLLECT_GAMEPASS_ID = 1412171840,
AUTO_COLLECT_RANGE = 50, -- Studs to collect cash from
AUTO_COLLECT_INTERVAL = 0.1, -- How often to check for cash
```

4. Copy the entire contents of `AutoCollectAddon.lua` and paste it into your PurchaseHandler script (after your existing code)

5. Find where your script handles owner changes and add the auto-collect check:
```lua
-- In your owner change handler, add:
if newOwner and checkAutoCollectOwnership(newOwner) then
    setupAutoCollect(newOwner)
end
```

6. In your reset function, add:
```lua
cleanupAutoCollect()
```

### Step 3: Test the System

1. **Test Purchase Flow:**
   - Open the shop
   - Go to Gamepasses tab
   - Click on Auto Collect
   - Complete the purchase

2. **Test Auto-Collect:**
   - After purchasing, cash parts should automatically fly to you
   - You should see a green particle effect around your character
   - Cash within 50 studs should be collected automatically

3. **Test Persistence:**
   - Leave and rejoin the game
   - Auto-collect should still work if you own the gamepass

## Key Features

### Auto-Collect Behavior:
- **Range:** 50 studs around the player
- **Visual Effect:** Green sparkle particles around the player
- **Collection Animation:** Cash parts fly to the player before disappearing
- **Sound:** Quiet collection sound (5% volume)
- **Performance:** Uses Heartbeat for smooth collection

### Shop Features:
- **Real-time Pricing:** Fetches actual gamepass price from Roblox
- **Tabbed Interface:** Separate tabs for Cash and Gamepasses
- **Visual Polish:** Smooth animations, hover effects, sound feedback
- **Responsive Design:** Works on all screen sizes

## Troubleshooting

### If Auto-Collect Doesn't Work:
1. Check the gamepass ID is correct (1412171840)
2. Ensure the PurchaseHandler modifications were added correctly
3. Check the output for any error messages
4. Verify the player owns the gamepass with:
   ```lua
   print(MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1412171840))
   ```

### If Shop Doesn't Show Gamepass:
1. Ensure you're using the new shop script
2. Check that the gamepass is published and active
3. Look for errors in the output related to MarketplaceService

## Customization

### Change Auto-Collect Range:
In the CONFIG table, modify:
```lua
AUTO_COLLECT_RANGE = 50, -- Change to desired range in studs
```

### Change Visual Effects:
Find the particle emitter creation in `setupAutoCollect` and modify:
- `particles.Color` - Change particle color
- `particles.Rate` - Change particle density
- `particles.Size` - Change particle size

### Add More Gamepasses:
In the shop script, add to the `gamepasses` table:
```lua
{id = YOUR_GAMEPASS_ID, name = "Pass Name", icon = "🎁", description = "Description here", price = nil},
```

## Important Notes

1. **The auto-collect only works for the tycoon owner**
2. **Players must be in the game for auto-collect to work** (it's not passive income while offline)
3. **The effect persists through respawns** but not server shutdowns
4. **Cash must have a "Cash" IntValue/NumberValue child** to be collected

## Support

If you encounter issues:
1. Check the Roblox Developer Console (F9) for errors
2. Ensure all scripts are in the correct locations
3. Verify the gamepass ID matches your actual gamepass
4. Test in Studio first before publishing

Good luck with your tycoon! 🎮✨