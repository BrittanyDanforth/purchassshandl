# Sanrio Tycoon Client - Shared State Analysis

## Global Variables & Shared State

### 1. Top-Level Variables

#### Service References (Global)
```lua
local Services = {
    Players, ReplicatedStorage, UserInputService, TweenService,
    RunService, HttpService, SoundService, GuiService, Lighting,
    StarterGui, ContentProvider, MarketplaceService, TeleportService,
    BadgeService, Chat, LocalizationService, ContextActionService,
    HapticService, VRService, TextService
}
```
- **Scope**: Read-only, global access needed
- **Solution**: Singleton service module

#### Player References (Global)
```lua
local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Mouse = LocalPlayer:GetMouse()
```
- **Scope**: Read-only after init
- **Solution**: Player service module

#### Remote References (Global)
```lua
local RemoteEvents = {}      -- Populated from RemoteEvents folder
local RemoteFunctions = {}   -- Populated from RemoteFunctions folder
```
- **Scope**: Read-only after init
- **Solution**: RemoteManager module

### 2. Configuration State

#### CLIENT_CONFIG (Global Constants)
```lua
local CLIENT_CONFIG = {
    UI_SCALE = 1,
    ANIMATION_SPEED = 0.3,
    ZINDEX = { ... },
    COLORS = { ... },
    RARITY_COLORS = { ... },
    FONTS = { ... },
    SOUNDS = { ... },
    ICONS = { ... }
}
```
- **Scope**: Read-only constants
- **Solution**: ClientConfig module

### 3. Mutable Shared State

#### LocalData (Primary Data Store)
```lua
local LocalData = {
    PlayerData = {
        currencies = { coins = 0, gems = 0, tickets = 0 },
        pets = {},
        inventory = {},
        equipped = {},
        settings = {
            musicVolume = 0.5,
            sfxVolume = 0.5,
            particlesEnabled = true,
            autoDelete = { enabled = false, rarities = {} }
        },
        quests = { daily = {}, weekly = {} },
        achievements = {},
        stats = {},
        dailyReward = { streak = 0, lastClaim = 0, nextReward = 0 }
    },
    CachedAssets = {},
    UIStates = {}
}
```
- **Mutated By**: Remote events, UI actions
- **Read By**: All UI modules
- **Solution**: StateManager with subscriptions

#### UI Module Instances
```lua
local UIModules = {
    MainUI = {},
    ShopUI = {},
    InventoryUI = {},
    CaseOpeningUI = {},
    TradingUI = {},
    BattleUI = {},
    QuestUI = {},
    SettingsUI = {},
    DailyRewardUI = {},
    LeaderboardUI = {},
    ProfileUI = {},
    ClanUI = {},
    BattlePassUI = {},
    MinigameUI = {}
}
```
- **Scope**: Module containers
- **Solution**: ModuleLoader manages these

### 4. UI State Variables

#### MainUI State
```lua
-- Inside MainUI
self.ScreenGui = nil          -- Main ScreenGui instance
self.MainPanel = nil          -- Main panel container
self.NavigationBar = nil      -- Navigation instance
self.CurrencyDisplay = nil    -- Currency display
self.CurrentModule = nil      -- Currently open module
self.ActiveOverlays = {}      -- Active overlay tracking
```
- **Scope**: MainUI internal
- **Solution**: Encapsulated in MainUI module

#### Navigation State
```lua
-- Navigation hover states
self.NavHoverStates = {}      -- Track hover state per button
self.OriginalColors = {}      -- Store original colors
self.OriginalSizes = {}       -- Store original sizes
```
- **Scope**: Navigation internal
- **Solution**: Part of NavigationBar module

#### Inventory State
```lua
-- Inside InventoryUI
self.CurrentFilter = "All"
self.CurrentSort = "Recent"
self.SelectedPets = {}        -- For mass actions
self.PetCardCache = {}        -- Card recycling pool
self.PetCardMap = {}          -- PetId -> Card mapping
self.IsRefreshing = false     -- Refresh mutex
self.MassDeleteMode = false   -- Mass delete state
```
- **Scope**: InventoryUI internal
- **Solution**: Encapsulated in module

### 5. System State

#### Sound System State
```lua
-- Inside Utilities
Utilities.SoundCache = {}     -- Cached sound instances
Utilities.FailedSounds = {}   -- Failed sound IDs
```
- **Scope**: Sound system internal
- **Solution**: SoundManager module

#### Particle System State
```lua
-- Particle tracking
local ActiveParticles = {}    -- Track active particles
local ParticlePool = {}       -- Particle instance pool
```
- **Scope**: ParticleSystem internal
- **Solution**: ParticleSystem module

#### Notification State
```lua
-- Notification tracking
local ActiveNotifications = {} -- Active notification frames
local NotificationQueue = {}   -- Queued notifications
```
- **Scope**: NotificationSystem internal
- **Solution**: NotificationSystem module

### 6. Event Connections

#### Remote Event Connections
```lua
-- Stored connections for cleanup
local Connections = {
    DataLoaded = RemoteEvents.DataLoaded.OnClientEvent:Connect(...),
    DataUpdated = RemoteEvents.DataUpdated.OnClientEvent:Connect(...),
    CurrencyUpdated = RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(...),
    -- ... many more
}
```
- **Scope**: Global for cleanup
- **Solution**: ConnectionManager in RemoteManager

#### UI Event Connections
```lua
-- Various UI connections stored in modules
self.Connections = {
    ButtonClick = button.MouseButton1Click:Connect(...),
    MouseEnter = frame.MouseEnter:Connect(...),
    -- Per module connections
}
```
- **Scope**: Module internal
- **Solution**: Each module manages own connections

### 7. Temporary State

#### Animation State
```lua
-- Active tweens
local ActiveTweens = {}       -- Track active animations
local TweenCache = {}         -- Reusable tween instances
```
- **Scope**: Animation system
- **Solution**: AnimationManager module

#### Loading State
```lua
-- Module loading flags
local ModulesLoaded = {
    Shop = false,
    Inventory = false,
    -- ... etc
}
```
- **Scope**: Initialization tracking
- **Solution**: ModuleLoader tracks this

### 8. Cross-Module References

#### Direct Module References
```lua
-- Example from ShopUI
UIModules.CaseOpeningUI:Open(results)  -- Direct call

-- Example from InventoryUI  
UIModules.TradingUI:Open(selectedPets)  -- Direct call
```
- **Problem**: Creates tight coupling
- **Solution**: Event-based communication

#### Shared UI Elements
```lua
-- MainUI elements accessed by modules
MainUI.ScreenGui              -- Parent for all UI
MainUI.MainPanel              -- Container for modules
MainUI.NotificationContainer  -- Shared notifications
```
- **Solution**: Dependency injection

### 9. Global Functions

#### Global SpecialEffects
```lua
_G.SpecialEffects = SpecialEffects  -- Made global for access
```
- **Problem**: Global pollution
- **Solution**: Proper module system

## State Management Strategy

### 1. Immutable State
- Configuration
- Constants
- Service references
- Remote references

### 2. Managed Mutable State
- Player data (StateManager)
- UI preferences (StateManager)
- Cache data (CacheManager)

### 3. Module-Local State
- UI element references
- Animation states
- Temporary data
- Event connections

### 4. Communication Patterns

#### Direct Access (Current)
```lua
-- Module A directly calls Module B
UIModules.ShopUI:Open()
```

#### Event-Based (Proposed)
```lua
-- Module A fires event
EventBus:Fire("OpenModule", "Shop", data)

-- Module B listens
EventBus:On("OpenModule", function(module, data)
    if module == "Shop" then
        self:Open(data)
    end
end)
```

#### Dependency Injection (Proposed)
```lua
-- Module receives dependencies
function ShopUI.new(mainUI, eventBus, stateManager)
    self.mainUI = mainUI
    self.eventBus = eventBus
    self.stateManager = stateManager
end
```

### 5. State Update Flow

#### Current Flow
1. Remote event received
2. LocalData updated directly
3. UI manually refreshed
4. Multiple modules may update

#### Proposed Flow
1. Remote event received
2. StateManager updates data
3. StateManager fires change event
4. Subscribed modules auto-update

### 6. Memory Management

#### Current Issues
- No cleanup of unused data
- Connections may leak
- UI elements not destroyed
- Particle effects accumulate

#### Proposed Solutions
- Automatic cleanup in modules
- Connection tracking
- Resource pooling
- Garbage collection hints

## Migration Risks

### High Risk Areas
1. **LocalData Access** - Used everywhere
2. **Direct Module Calls** - Tight coupling
3. **Global State** - _G usage
4. **Event Connections** - Cleanup critical

### Mitigation Strategies
1. **Gradual Migration** - One module at a time
2. **Compatibility Layer** - Support old patterns
3. **State Synchronization** - Keep data consistent
4. **Extensive Testing** - Each migration step

## State Architecture

### Layer 1: Immutable Configuration
- ClientConfig
- GameConstants
- ServiceReferences

### Layer 2: Managed State
- StateManager (player data)
- CacheManager (assets)
- SettingsManager (preferences)

### Layer 3: Module State
- Per-module internal state
- UI element references
- Local connections

### Layer 4: Communication
- EventBus (decoupled events)
- StateSubscriptions (data changes)
- RemoteManager (server comm)

## Benefits of New Architecture

1. **Predictable State** - Clear ownership
2. **Easier Debugging** - State inspection
3. **Better Performance** - Efficient updates
4. **Maintainability** - Clear boundaries
5. **Testability** - Mockable state
6. **Scalability** - Easy to extend