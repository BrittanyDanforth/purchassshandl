# Sanrio Tycoon Client - Complete Function Mapping

## Function Count Summary
- **Total Functions**: ~250+
- **Utility Functions**: 13
- **UI Component Functions**: 10
- **UI Module Methods**: ~150+
- **System Functions**: ~50+
- **Event Handlers**: ~30+

## Detailed Function Mapping

### 1. Utilities Module Functions

#### Utilities:PlaySound(soundId)
- **Purpose**: Plays sounds with caching and error handling
- **Dependencies**: ContentProvider, SoundService
- **Target Module**: `SoundManager.lua`
- **Used By**: All UI modules

#### Utilities:FormatNumber(num)
- **Purpose**: Formats numbers with K/M/B suffixes
- **Dependencies**: None (pure function)
- **Target Module**: `MathUtils.lua`
- **Used By**: All UI displaying numbers

#### Utilities:FormatTime(seconds)
- **Purpose**: Converts seconds to readable time format
- **Dependencies**: None (pure function)
- **Target Module**: `MathUtils.lua`
- **Used By**: Quest UI, Daily Rewards

#### Utilities:GetRarityColor(rarity)
- **Purpose**: Returns color for pet rarity
- **Dependencies**: CLIENT_CONFIG
- **Target Module**: `GameConstants.lua`
- **Used By**: Inventory, Shop, Case Opening

#### Utilities:CreateGradient(parent, colors, rotation)
- **Purpose**: Creates UIGradient effect
- **Dependencies**: Instance.new
- **Target Module**: `UIEffects.lua`
- **Used By**: Premium UI elements

#### Utilities:CreateCorner(parent, radius)
- **Purpose**: Adds rounded corners to UI
- **Dependencies**: Instance.new
- **Target Module**: `UIFactory.lua`
- **Used By**: All UI frames

#### Utilities:CreateStroke(parent, color, thickness, transparency)
- **Purpose**: Creates border stroke effect
- **Dependencies**: Instance.new
- **Target Module**: `UIFactory.lua`
- **Used By**: Buttons, cards

#### Utilities:CreatePadding(parent, padding)
- **Purpose**: Adds internal padding to frames
- **Dependencies**: Instance.new
- **Target Module**: `UIFactory.lua`
- **Used By**: All container frames

#### Utilities:CreateShadow(parent, transparency, size)
- **Purpose**: Creates shadow effect (currently disabled)
- **Dependencies**: Instance.new
- **Target Module**: `UIEffects.lua`
- **Used By**: Previously all UI elements

#### Utilities:Tween(object, properties, tweenInfo)
- **Purpose**: Creates and plays tweens
- **Dependencies**: TweenService
- **Target Module**: `AnimationUtils.lua`
- **Used By**: All animations

#### Utilities:LoadImage(imageId)
- **Purpose**: Loads and validates image assets
- **Dependencies**: ContentProvider
- **Target Module**: `AssetLoader.lua`
- **Used By**: Pet cards, icons

### 2. UIComponents Functions

#### UIComponents:CreateButton(parent, text, size, position, callback)
- **Purpose**: Creates interactive button with animations
- **Dependencies**: Utilities, TweenService
- **Target Module**: `Components/Button.lua`
- **Features**: Hover state, click animation, sound

#### UIComponents:CreateFrame(parent, name, size, position, color)
- **Purpose**: Creates basic UI frame
- **Dependencies**: Utilities
- **Target Module**: `UIFactory.lua`

#### UIComponents:CreateLabel(parent, text, size, position, textSize)
- **Purpose**: Creates text label
- **Dependencies**: Utilities
- **Target Module**: `UIFactory.lua`

#### UIComponents:CreateImageLabel(parent, imageId, size, position)
- **Purpose**: Creates image display
- **Dependencies**: Utilities
- **Target Module**: `UIFactory.lua`

#### UIComponents:CreateTextBox(parent, placeholderText, size, position)
- **Purpose**: Creates text input field
- **Dependencies**: Utilities
- **Target Module**: `Components/TextInput.lua`

#### UIComponents:CreateScrollingFrame(parent, size, position, canvasSize)
- **Purpose**: Creates scrollable container
- **Dependencies**: Utilities
- **Target Module**: `Components/ScrollFrame.lua`

#### UIComponents:CreateProgressBar(parent, size, position, value, maxValue)
- **Purpose**: Creates animated progress bar
- **Dependencies**: Utilities, TweenService
- **Target Module**: `Components/ProgressBar.lua`

#### UIComponents:CreateToggle(parent, text, size, position, defaultValue, callback)
- **Purpose**: Creates toggle switch
- **Dependencies**: Utilities, TweenService
- **Target Module**: `Components/Toggle.lua`

#### UIComponents:CreateTab(parent, tabs, size, position)
- **Purpose**: Creates tabbed interface
- **Dependencies**: Utilities
- **Target Module**: `Components/TabSystem.lua`

### 3. ParticleSystem Functions

#### ParticleSystem:CreateParticle(parent, particleType, position)
- **Purpose**: Creates single particle effect
- **Target Module**: `Systems/ParticleSystem.lua`

#### ParticleSystem:CreateBurst(parent, particleType, position, count)
- **Purpose**: Creates particle burst effect
- **Target Module**: `Systems/ParticleSystem.lua`

#### ParticleSystem:CreateTrail(parent, particleType, startPos, endPos, count)
- **Purpose**: Creates particle trail effect
- **Target Module**: `Systems/ParticleSystem.lua`

### 4. MainUI Functions

#### MainUI:Initialize()
- **Purpose**: Sets up main UI framework
- **Creates**: ScreenGui, MainPanel, Navigation
- **Target Module**: `UI/Framework/MainUI.lua`

#### MainUI:RegisterOverlay(overlayName, overlay)
- **Purpose**: Tracks active overlays
- **Target Module**: `UI/Framework/WindowManager.lua`

#### MainUI:UnregisterOverlay(overlayName)
- **Purpose**: Removes overlay tracking
- **Target Module**: `UI/Framework/WindowManager.lua`

#### MainUI:CreateCurrencyDisplay()
- **Purpose**: Creates currency UI at top
- **Target Module**: `UI/Framework/CurrencyDisplay.lua`

#### MainUI:CreateNavigationBar()
- **Purpose**: Creates left navigation menu
- **Target Module**: `UI/Framework/NavigationBar.lua`

### 5. NotificationSystem Functions

#### NotificationSystem:ShowNotification(config)
- **Purpose**: Displays notification messages
- **Target Module**: `Systems/NotificationSystem.lua`

#### NotificationSystem:CreateNotificationFrame(config)
- **Purpose**: Creates notification UI element
- **Target Module**: `Systems/NotificationSystem.lua`

### 6. ShopUI Module Methods

#### UIModules.ShopUI:Open()
- **Purpose**: Opens shop interface
- **Dependencies**: MainUI, UIComponents
- **Target Module**: `UI/Modules/ShopUI/ShopUI.lua`

#### UIModules.ShopUI:Close()
- **Purpose**: Closes shop interface
- **Target Module**: `UI/Modules/ShopUI/ShopUI.lua`

#### UIModules.ShopUI:CreateEggShop(parent)
- **Purpose**: Creates egg/case shop tab
- **Target Module**: `UI/Modules/ShopUI/EggShop.lua`

#### UIModules.ShopUI:CreateEggCard(parent, eggData)
- **Purpose**: Creates individual egg card
- **Target Module**: `UI/Modules/ShopUI/EggCard.lua`

#### UIModules.ShopUI:OpenEgg(eggData, count)
- **Purpose**: Handles egg purchase/opening
- **Calls**: CaseOpeningUI
- **Target Module**: `UI/Modules/ShopUI/ShopUI.lua`

#### UIModules.ShopUI:CreateGamepassShop(parent)
- **Purpose**: Creates gamepass shop tab
- **Target Module**: `UI/Modules/ShopUI/GamepassShop.lua`

#### UIModules.ShopUI:CreateCurrencyShop(parent)
- **Purpose**: Creates currency shop tab
- **Target Module**: `UI/Modules/ShopUI/CurrencyShop.lua`

### 7. CaseOpeningUI Module Methods

#### UIModules.CaseOpeningUI:Open(results)
- **Purpose**: Shows case opening animation
- **Target Module**: `UI/Modules/CaseOpeningUI/CaseOpeningUI.lua`

#### UIModules.CaseOpeningUI:ShowCaseAnimation(container, result, index, total)
- **Purpose**: Animates individual case opening
- **Target Module**: `UI/Modules/CaseOpeningUI/OpenAnimation.lua`

#### UIModules.CaseOpeningUI:CreateCaseItem(petId, isWinner)
- **Purpose**: Creates pet display for animation
- **Target Module**: `UI/Modules/CaseOpeningUI/CaseItem.lua`

#### UIModules.CaseOpeningUI:ShowResult(container, result)
- **Purpose**: Shows final pet result
- **Target Module**: `UI/Modules/CaseOpeningUI/ResultDisplay.lua`

### 8. InventoryUI Module Methods

#### UIModules.InventoryUI:Open()
- **Purpose**: Opens inventory interface
- **Complex**: Manages pet grid, filters, actions
- **Target Module**: `UI/Modules/InventoryUI/InventoryUI.lua`

#### UIModules.InventoryUI:Close()
- **Purpose**: Closes inventory
- **Target Module**: `UI/Modules/InventoryUI/InventoryUI.lua`

#### UIModules.InventoryUI:CreatePetGrid(parent)
- **Purpose**: Creates scrollable pet grid
- **Target Module**: `UI/Modules/InventoryUI/PetGrid.lua`

#### UIModules.InventoryUI:CreateFilterBar(parent)
- **Purpose**: Creates filter/sort options
- **Target Module**: `UI/Modules/InventoryUI/FilterSort.lua`

#### UIModules.InventoryUI:RefreshInventory()
- **Purpose**: Updates pet display
- **Performance Critical**: Uses card recycling
- **Target Module**: `UI/Modules/InventoryUI/InventoryUI.lua`

#### UIModules.InventoryUI:CreatePetCard(petData, container)
- **Purpose**: Creates individual pet card
- **Target Module**: `UI/Modules/InventoryUI/PetCard.lua`

#### UIModules.InventoryUI:UpdatePetCard(card, petData)
- **Purpose**: Updates existing pet card
- **Target Module**: `UI/Modules/InventoryUI/PetCard.lua`

#### UIModules.InventoryUI:ShowPetInfo(petData)
- **Purpose**: Shows detailed pet information
- **Target Module**: `UI/Modules/InventoryUI/PetDetails.lua`

#### UIModules.InventoryUI:OpenMassDelete()
- **Purpose**: Opens mass delete interface
- **Target Module**: `UI/Modules/InventoryUI/MassDelete.lua`

#### UIModules.InventoryUI:RefreshMassDeleteGrid()
- **Purpose**: Updates mass delete selection
- **Target Module**: `UI/Modules/InventoryUI/MassDelete.lua`

### 9. TradingUI Module Methods

#### UIModules.TradingUI:Open(targetPlayer)
- **Purpose**: Opens trading interface
- **Target Module**: `UI/Modules/TradingUI/TradingUI.lua`

#### UIModules.TradingUI:Close()
- **Purpose**: Closes trading interface
- **Target Module**: `UI/Modules/TradingUI/TradingUI.lua`

#### UIModules.TradingUI:CreateTradeWindow()
- **Purpose**: Creates main trade UI
- **Target Module**: `UI/Modules/TradingUI/TradeWindow.lua`

#### UIModules.TradingUI:UpdateTradeDisplay(tradeData)
- **Purpose**: Updates trade contents
- **Target Module**: `UI/Modules/TradingUI/TradeWindow.lua`

#### UIModules.TradingUI:ShowTradeHistory()
- **Purpose**: Shows past trades
- **Target Module**: `UI/Modules/TradingUI/TradeHistory.lua`

### 10. BattleUI Module Methods

#### UIModules.BattleUI:Open()
- **Purpose**: Opens battle menu
- **Target Module**: `UI/Modules/BattleUI/BattleUI.lua`

#### UIModules.BattleUI:OpenBattleArena(battleData)
- **Purpose**: Shows active battle
- **Target Module**: `UI/Modules/BattleUI/BattleArena.lua`

#### UIModules.BattleUI:CreateBattlerInfo(parent, side, playerData)
- **Purpose**: Creates player battle info
- **Target Module**: `UI/Modules/BattleUI/BattlerInfo.lua`

#### UIModules.BattleUI:UpdateBattleLog(message)
- **Purpose**: Updates battle log
- **Target Module**: `UI/Modules/BattleUI/BattleLog.lua`

#### UIModules.BattleUI:StartQuickMatch()
- **Purpose**: Initiates matchmaking
- **Target Module**: `UI/Modules/BattleUI/Matchmaking.lua`

### 11. QuestUI Module Methods

#### UIModules.QuestUI:Open()
- **Purpose**: Opens quest interface
- **Target Module**: `UI/Modules/QuestUI/QuestUI.lua`

#### UIModules.QuestUI:CreateQuestCard(parent, questData)
- **Purpose**: Creates quest display card
- **Target Module**: `UI/Modules/QuestUI/QuestCard.lua`

#### UIModules.QuestUI:UpdateProgress(questId, progress)
- **Purpose**: Updates quest progress
- **Target Module**: `UI/Modules/QuestUI/QuestProgress.lua`

### 12. SettingsUI Module Methods

#### UIModules.SettingsUI:Open()
- **Purpose**: Opens settings interface
- **Target Module**: `UI/Modules/SettingsUI/SettingsUI.lua`

#### UIModules.SettingsUI:CreateVolumeSlider(parent, settingType)
- **Purpose**: Creates volume control
- **Target Module**: `UI/Modules/SettingsUI/AudioSettings.lua`

#### UIModules.SettingsUI:CreateGraphicsSettings(parent)
- **Purpose**: Creates graphics options
- **Target Module**: `UI/Modules/SettingsUI/GraphicsSettings.lua`

### 13. Event Handlers

#### Remote Event Handlers
- **DataLoaded**: Initial data sync
- **DataUpdated**: Incremental updates
- **CurrencyUpdated**: Currency changes
- **PetDeleted**: Pet removal
- **QuestCompleted**: Quest completion
- **CaseOpened**: Case results
- **TradeRequest**: Incoming trades
- **DailyRewardAvailable**: Daily reward

#### UI Event Handlers
- **Button clicks**: All interactive elements
- **Mouse enter/leave**: Hover effects
- **Input changes**: Text boxes, sliders
- **Window close**: Cleanup handlers

### 14. Initialization Functions

#### Initialize()
- **Purpose**: Main initialization sequence
- **Target Module**: `ClientCore.lua`

#### SetupRemoteHandlers()
- **Purpose**: Connects all remote events
- **Target Module**: `Infrastructure/RemoteManager.lua`

#### LoadPlayerData()
- **Purpose**: Initial data loading
- **Target Module**: `Infrastructure/DataCache.lua`

### 15. Helper Functions

#### Various helper functions for:
- Input validation
- Data transformation
- UI calculations
- Animation timing
- Error handling

## Module Assignment Summary

### Core Modules (25 files)
1. ClientCore.lua - Main initialization
2. ClientConfig.lua - Configuration
3. ClientServices.lua - Service references
4. ClientConstants.lua - Game constants
5. ClientTypes.lua - Type definitions

### Infrastructure (10 files)
6. RemoteManager.lua - Remote handling
7. DataCache.lua - Data management
8. EventBus.lua - Event system
9. StateManager.lua - State management
10. ModuleLoader.lua - Dynamic loading

### Utilities (8 files)
11. MathUtils.lua - Math functions
12. UIUtils.lua - UI helpers
13. ValidationUtils.lua - Validation
14. AnimationUtils.lua - Animation helpers
15. AssetLoader.lua - Asset loading
16. DebugUtils.lua - Debug helpers
17. PerformanceUtils.lua - Performance
18. GameConstants.lua - Game-specific

### Systems (6 files)
19. SoundManager.lua - Sound system
20. ParticleSystem.lua - Particles
21. NotificationSystem.lua - Notifications
22. EffectsSystem.lua - Visual effects
23. InputSystem.lua - Input handling
24. LocalizationSystem.lua - Localization

### Components (10 files)
25. UIFactory.lua - UI creation
26. Button.lua - Button component
27. Card.lua - Card component
28. Modal.lua - Modal windows
29. Tooltip.lua - Tooltips
30. ScrollFrame.lua - Scrolling
31. TabSystem.lua - Tabs
32. GridLayout.lua - Grid layout
33. ProgressBar.lua - Progress bars
34. Toggle.lua - Toggle switches

### UI Framework (5 files)
35. MainUI.lua - Main framework
36. NavigationBar.lua - Navigation
37. WindowManager.lua - Window management
38. CurrencyDisplay.lua - Currency UI
39. OverlayManager.lua - Overlay handling

### UI Modules (50+ files)
40+ files for all UI modules and their subcomponents

Total: ~100 module files from 8150 lines of code