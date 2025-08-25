# 🛍️ Roblox Shop System - Complete Setup Guide

## 📋 Overview
A fully functional shop system with Red Coil, Green Coil, Red Balloon, and Grappling Hook items.

## 🎨 Asset IDs Used
- **Shop Frame Background**: `rbxassetid://9672485940`
- **Shop Toggle Button**: `rbxassetid://9672262249`
- **Red Coil**: `rbxassetid://9676503482`
- **Green Coil**: `rbxassetid://9676542145`
- **Red Balloon**: `rbxassetid://9672579022`
- **Grappling Hook**: `rbxassetid://9677437680`

## 📦 Files Included
1. **ShopSystem.lua** - Server-side shop logic
2. **ItemSpawner.lua** - Module for creating and managing tools
3. **ShopGUI.lua** - Client-side GUI and interactions
4. **ShopSetup.lua** - Setup helper script

## 🚀 Installation Steps

### Step 1: Server Scripts
1. Open your game in Roblox Studio
2. In Explorer, find **ServerScriptService**
3. Right-click → Insert Object → Script
4. Name it "ShopSystem" and paste the contents of `ShopSystem.lua`

### Step 2: Module Script
1. In **ServerScriptService**, right-click → Insert Object → ModuleScript
2. Name it "ItemSpawner" and paste the contents of `ItemSpawner.lua`

### Step 3: Client Script
1. In Explorer, navigate to **StarterPlayer** → **StarterPlayerScripts**
2. Right-click → Insert Object → LocalScript
3. Name it "ShopGUI" and paste the contents of `ShopGUI.lua`

### Step 4: (Optional) Setup Script
1. In **ServerScriptService**, create another Script
2. Name it "ShopSetup" and paste the contents of `ShopSetup.lua`

## 🎮 How to Use

### For Players:
- **Open Shop**: Click the shop button on the left side OR press **F**
- **Buy Items**: Click the "Buy" button (requires coins)
- **Equip Items**: Click "Equip" on owned items
- **Starting Coins**: 1000

### Item Effects:
- **Red Coil**: Speed 32 (normal is 16)
- **Green Coil**: Speed 40
- **Red Balloon**: Jump Power 100 (normal is 50)
- **Grappling Hook**: 50 stud range grappling tool

## 💡 Features
- ✅ Persistent data saving
- ✅ Smooth animations
- ✅ Purchase validation
- ✅ Equip system
- ✅ Modern UI with proper scaling
- ✅ Coin display in leaderstats
- ✅ Auto-save every minute
- ✅ Mobile-friendly

## 🛠️ Customization

### Adding More Items:
Edit the `SHOP_ITEMS` table in both `ShopSystem.lua` and `ShopGUI.lua`:

```lua
{
    Name = "Item Name",
    ItemId = "UniqueId",
    Price = 100,
    ImageId = "rbxassetid://YOUR_IMAGE_ID",
    Description = "Item description",
    Type = "Gear",
    Stats = {Speed = 50} -- or {JumpPower = 150}
}
```

### Changing Starting Coins:
In `ShopSystem.lua`, find:
```lua
Coins = 1000, -- Starting coins
```

### Admin Commands (Creator Only):
Type in chat: `!givecoins 5000` to give yourself coins

## 🐛 Troubleshooting
1. **Shop won't open**: Check if ShopGUI is in StarterPlayerScripts
2. **Items not saving**: Ensure game has API Services enabled
3. **Tools not appearing**: Check ItemSpawner is a ModuleScript
4. **Can't purchase**: Check if you have enough coins

## 📝 Notes
- Data saves automatically every 60 seconds and on player leave
- Only one tool can be equipped at a time
- Shop scales properly on all screen sizes
- All images use the exact Asset IDs you provided

Enjoy your fully functional shop system! 🎉