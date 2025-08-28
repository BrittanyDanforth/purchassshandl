# 📁 SANRIO TYCOON - COMPLETE FILE PLACEMENT GUIDE

## 🚨 IMPORTANT: Your Issue
The error `Infinite yield possible on 'ServerScriptService.ServerModules:WaitForChild("DailyRewardSystem")'` means the modules aren't in the right place!

## 📋 Quick Fix Steps:

### 1️⃣ **Run the Installation Script**
Copy the contents of `INSTALLATION_SCRIPT.lua` and paste it in the Roblox Studio command bar. This will create all necessary folders.

### 2️⃣ **Exact File Placement**

```
game
├── ServerScriptService
│   ├── SANRIO_TYCOON_SERVER_MODULAR (Script) ← Main server script
│   └── ServerModules (Folder)
│       ├── Configuration (ModuleScript)
│       ├── DataStoreModule (ModuleScript)
│       ├── PetSystem (ModuleScript)
│       ├── PetDatabase (ModuleScript)
│       ├── CaseSystem (ModuleScript)
│       ├── TradingSystem (ModuleScript)
│       ├── DailyRewardSystem (ModuleScript)
│       ├── QuestSystem (ModuleScript)
│       ├── BattleSystem (ModuleScript)
│       └── AchievementSystem (ModuleScript)
│
├── ReplicatedStorage
│   ├── RemoteEvents (Folder) ← Will be auto-created
│   ├── RemoteFunctions (Folder) ← Will be auto-created
│   └── Modules (Folder)
│       ├── Shared (Folder)
│       │   ├── Janitor (ModuleScript)
│       │   ├── DeltaNetworking (ModuleScript)
│       │   └── ClientDataManager (ModuleScript)
│       └── Client (Folder)
│           └── WindowManager (ModuleScript)
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── SANRIO_TYCOON_CLIENT_COMPLETE_5000PLUS (LocalScript) ← Main client script
```

### 3️⃣ **File Contents to Paste**

After running the installation script, paste these files into their respective ModuleScripts:

1. **ServerScriptService > ServerModules > Configuration** ← Paste `/workspace/ServerModules/Configuration.lua`
2. **ServerScriptService > ServerModules > DataStoreModule** ← Paste `/workspace/ServerModules/DataStoreModule.lua`
3. **ServerScriptService > ServerModules > PetSystem** ← Paste `/workspace/ServerModules/PetSystem.lua`
4. **ServerScriptService > ServerModules > PetDatabase** ← Paste `/workspace/ServerModules/PetDatabase.lua`
5. **ServerScriptService > ServerModules > CaseSystem** ← Paste `/workspace/ServerModules/CaseSystem.lua`
6. **ServerScriptService > ServerModules > TradingSystem** ← Paste `/workspace/ServerModules/TradingSystem.lua`
7. **ServerScriptService > ServerModules > DailyRewardSystem** ← Paste `/workspace/ServerModules/DailyRewardSystem.lua`
8. **ServerScriptService > ServerModules > QuestSystem** ← Paste `/workspace/ServerModules/QuestSystem.lua`
9. **ServerScriptService > ServerModules > BattleSystem** ← Paste `/workspace/ServerModules/BattleSystem.lua`
10. **ServerScriptService > ServerModules > AchievementSystem** ← Paste `/workspace/ServerModules/AchievementSystem.lua`

11. **ReplicatedStorage > Modules > Shared > Janitor** ← Paste `/workspace/Janitor.lua`
12. **ReplicatedStorage > Modules > Shared > DeltaNetworking** ← Paste `/workspace/DeltaNetworking.lua`
13. **ReplicatedStorage > Modules > Shared > ClientDataManager** ← Paste `/workspace/ClientDataManager.lua`
14. **ReplicatedStorage > Modules > Client > WindowManager** ← Paste `/workspace/WindowManager.lua`

15. **ServerScriptService > SANRIO_TYCOON_SERVER_MODULAR** ← Paste `/workspace/SANRIO_TYCOON_SERVER_MODULAR.lua`
16. **StarterPlayer > StarterPlayerScripts > SANRIO_TYCOON_CLIENT_COMPLETE_5000PLUS** ← Paste `/workspace/SANRIO_TYCOON_CLIENT_COMPLETE_5000PLUS.lua`

### 4️⃣ **Disable Old Scripts**
- Find your old `SanrioTycoonServer` script and either:
  - Delete it
  - OR disable it (uncheck Enabled property)

### 5️⃣ **Test**
1. Save your place
2. Run the game
3. Check that there are no more "Infinite yield" errors
4. Open the egg shop - you should see eggs with proper data
5. Check gamepasses - they should show with proper info

## 🔧 Troubleshooting

### Still getting errors?
1. Make sure ALL folders are created exactly as shown
2. Make sure ALL ModuleScripts have the EXACT names (case-sensitive!)
3. Make sure you pasted the code into the ModuleScript's Source, not as a child
4. Check the Output window for any other errors

### Modules showing as empty `{}`?
This means you haven't pasted the actual code yet. Each ModuleScript needs its corresponding code from the workspace files.

### RemoteEvents/RemoteFunctions errors?
These are created automatically when the server starts. If you're getting errors:
1. Stop the game
2. Clear any existing RemoteEvents/RemoteFunctions
3. Start the game again - they'll be recreated

## ✅ Success Checklist
- [ ] All folders created in correct locations
- [ ] All ModuleScripts created with correct names
- [ ] All code pasted into ModuleScripts
- [ ] Main server script pasted
- [ ] Main client script pasted
- [ ] Old scripts disabled/removed
- [ ] No more "Infinite yield" errors
- [ ] Egg shop shows eggs
- [ ] Gamepass shop shows gamepasses

## 💡 Pro Tips
1. Use the installation script - it's much faster!
2. Keep the old scripts as backup until everything works
3. The modular system is easier to maintain and debug
4. Each module can be edited independently