# Client Script Dependency Analysis

## Module Cross-References

### 1. UIModules Dependencies
Based on analysis, the UI modules have these interdependencies:

#### ShopUI
- **Calls**: `UIModules.CaseOpeningUI:Open()` when opening eggs
- **Uses**: UIComponents, Utilities, RemoteFunctions
- **Events**: Fires purchase events

#### CaseOpeningUI  
- **Called by**: ShopUI
- **Uses**: UIComponents, Utilities, ParticleSystem, SpecialEffects
- **Events**: CaseOpened remote event

#### InventoryUI
- **Uses**: UIComponents, Utilities, NotificationSystem
- **Cross-refs**: Opens PetDetails, connects to Trading, Battle
- **Events**: DataUpdated, PetDeleted

#### TradingUI
- **Called by**: InventoryUI (via trade button)
- **Uses**: UIComponents, Utilities, NotificationSystem
- **Events**: Multiple trading remotes

#### BattleUI
- **Called by**: NavigationBar, InventoryUI
- **Uses**: UIComponents, Utilities
- **Events**: Battle-related remotes

#### QuestUI
- **Standalone**: No direct UI dependencies
- **Uses**: UIComponents, Utilities
- **Events**: Quest remotes

#### SettingsUI
- **Standalone**: No UI dependencies
- **Uses**: UIComponents, Utilities
- **Events**: Settings changed

#### DailyRewardUI
- **Standalone**: Called by remote event
- **Uses**: UIComponents, Utilities
- **Events**: ClaimDailyReward

#### LeaderboardUI
- **Standalone**: No UI dependencies
- **Uses**: UIComponents, Utilities
- **Events**: Leaderboard data

#### ProfileUI
- **May reference**: InventoryUI for pet count
- **Uses**: UIComponents, Utilities
- **Events**: Profile data

#### ClanUI
- **Standalone**: Complex internal state
- **Uses**: UIComponents, Utilities
- **Events**: Clan remotes

#### BattlePassUI
- **Standalone**: No UI dependencies
- **Uses**: UIComponents, Utilities
- **Events**: BattlePass remotes

#### MinigameUI
- **Standalone**: Self-contained games
- **Uses**: UIComponents, Utilities
- **Events**: Minigame remotes

### 2. Shared Systems Dependencies

#### MainUI (Core Framework)
- **Manages**: All UI modules
- **Provides**: ScreenGui, MainPanel, Navigation
- **Dependencies**: All UI modules register here

#### NotificationSystem
- **Used by**: Almost all modules
- **Standalone**: No dependencies on UI modules
- **Provides**: ShowNotification, error/success messages

#### ParticleSystem
- **Used by**: CaseOpeningUI, SpecialEffects
- **Standalone**: No UI dependencies
- **Provides**: Particle effects

#### SpecialEffects
- **Used by**: CaseOpeningUI, InventoryUI
- **Global**: Made available via _G
- **Provides**: Shine effects, animations

#### Utilities
- **Used by**: Everything
- **Provides**: FormatNumber, CreateShadow, PlaySound
- **No dependencies**: Pure functions

#### UIComponents
- **Used by**: All UI modules
- **Provides**: CreateButton, CreateFrame, etc.
- **Dependencies**: Utilities

### 3. Data Flow Dependencies

#### LocalData
- **Structure**:
  ```lua
  LocalData = {
      PlayerData = {
          currencies = {},
          pets = {},
          inventory = {},
          settings = {},
          quests = {},
          -- etc
      },
      CachedAssets = {},
      UIStates = {}
  }
  ```
- **Updated by**: RemoteEvents
- **Read by**: All UI modules

#### RemoteEvents Flow
1. Server sends data via RemoteEvents
2. Client handlers update LocalData
3. UI modules react to LocalData changes
4. Some modules listen directly to events

#### RemoteFunctions Flow
1. UI triggers action (button click)
2. RemoteFunction called with validation
3. Server processes and returns result
4. UI updates based on result

### 4. Critical Shared State

#### Navigation State
- Current open module
- Previous module stack
- Module initialization flags

#### Hover States
- NavHoverStates
- Button hover tracking
- Tooltip management

#### Animation States
- Active tweens
- Particle instances
- Effect timers

#### UI Element Pools
- PetCardCache
- NotificationPool
- ParticlePool

### 5. Event Dependencies

#### Internal Events (via BindableEvents)
- ModuleOpened
- ModuleClosed
- DataChanged
- SettingsUpdated

#### Remote Events (from server)
- DataLoaded
- DataUpdated
- CurrencyUpdated
- PetDeleted
- QuestCompleted
- CaseOpened
- TradeRequest
- BattleInvite
- ClanInvite
- DailyRewardAvailable

### 6. Initialization Order Requirements

1. **Services & Config** - Must be first
2. **Utilities** - No dependencies
3. **UIComponents** - Depends on Utilities
4. **MainUI** - Creates ScreenGui
5. **NotificationSystem** - Can initialize early
6. **ParticleSystem** - Can initialize early
7. **SpecialEffects** - Can initialize early
8. **RemoteEvents Setup** - Before UI modules
9. **UI Modules** - Can lazy load
10. **Debug Panel** - Last (if studio)

### 7. Circular Dependency Risks

#### Potential Circles
1. InventoryUI ↔ TradingUI (via pet selection)
2. InventoryUI ↔ BattleUI (via team selection)
3. MainUI ↔ UI Modules (registration)

#### Resolution Strategy
- Use event bus for indirect communication
- Lazy loading for UI modules
- Dependency injection pattern
- Clear module interfaces

### 8. Memory & Performance Considerations

#### Heavy Modules
- **InventoryUI**: Manages potentially 1000s of pet cards
- **CaseOpeningUI**: Particle effects and animations
- **BattleUI**: Real-time updates and animations
- **ClanUI**: Complex member lists and chat

#### Optimization Opportunities
1. Lazy load UI modules
2. Pool and recycle UI elements
3. Virtualize long lists
4. Defer non-critical initialization
5. Batch UI updates

### 9. Module Boundaries

#### Clear Boundaries
- Settings doesn't know about other modules
- Quest UI is self-contained
- Daily Rewards is event-driven

#### Fuzzy Boundaries
- Inventory interacts with Trading/Battle
- Shop triggers Case Opening
- Main UI knows about all modules

#### Proposed Solutions
1. Use events for cross-module actions
2. Define clear interfaces
3. Avoid direct module references
4. Use dependency injection

### 10. State Management Strategy

#### Local State (per module)
- UI element references
- Animation states
- Temporary data

#### Shared State (via StateManager)
- Player data
- Settings
- UI preferences

#### Global State (minimal)
- Services
- Configuration
- Debug flags

### 11. Error Propagation Paths

#### Current Issues
- Errors in one module can crash others
- No error boundaries
- Limited error recovery

#### Proposed Solution
- Try-catch in module methods
- Error event bus
- Graceful degradation
- User-friendly messages

### 12. Testing Isolation Requirements

#### Unit Testable
- Utilities (pure functions)
- Data transformations
- Validation logic

#### Integration Testing
- Module interactions
- Event flows
- Remote communications

#### UI Testing
- Component rendering
- User interactions
- Animation completion

## Modularization Priority

### Phase 1 - Core (No dependencies)
1. ClientConfig
2. ClientServices  
3. ClientUtilities
4. ClientTypes

### Phase 2 - Infrastructure
1. EventBus
2. StateManager
3. RemoteManager
4. DataCache

### Phase 3 - Systems
1. NotificationSystem
2. ParticleSystem
3. SpecialEffects
4. SoundManager

### Phase 4 - Components
1. UIComponents
2. UIFactory
3. Common components

### Phase 5 - Framework
1. MainUI
2. NavigationBar
3. WindowManager

### Phase 6 - Simple Modules
1. SettingsUI
2. DailyRewardUI
3. QuestUI

### Phase 7 - Complex Modules
1. ShopUI + CaseOpeningUI
2. InventoryUI
3. TradingUI
4. BattleUI

### Phase 8 - Remaining
1. ProfileUI
2. LeaderboardUI
3. ClanUI
4. BattlePassUI
5. MinigameUI

## Risk Assessment

### High Risk
- Breaking InventoryUI (core feature)
- Remote communication failures
- State synchronization issues

### Medium Risk
- Performance degradation
- Memory leaks
- Animation glitches

### Low Risk
- Minor UI inconsistencies
- Debug panel issues
- Studio-only features