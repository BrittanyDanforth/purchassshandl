# Sanrio Tycoon Client - Module Interface Specifications

## Core Module Interfaces

### 1. ClientCore
```lua
--[[
    Module: ClientCore
    Purpose: Main entry point and orchestrator for all client modules
    Dependencies: All core modules
]]

interface ClientCore {
    -- Initialization
    Initialize(): void
    
    -- Module Management
    GetModule(moduleName: string): Module?
    LoadModule(moduleName: string): Module?
    UnloadModule(moduleName: string): boolean
    ReloadModule(moduleName: string): boolean
    
    -- Lifecycle
    Shutdown(): void
    Reset(): void
    
    -- Events
    OnModuleLoaded: Event<(moduleName: string) -> void>
    OnModuleError: Event<(moduleName: string, error: string) -> void>
    OnShutdown: Event<() -> void>
}
```

### 2. ClientConfig
```lua
--[[
    Module: ClientConfig
    Purpose: Centralized configuration and constants
    Dependencies: None
]]

interface ClientConfig {
    -- UI Configuration
    UI_SCALE: number
    ANIMATION_SPEED: number
    PARTICLE_LIFETIME: number
    MAX_PARTICLES: number
    NOTIFICATION_DURATION: number
    
    -- Z-Index Layers
    ZINDEX: {
        Background: number,
        Default: number,
        Card: number,
        Window: number,
        Modal: number,
        Overlay: number,
        Tooltip: number,
        Debug: number
    }
    
    -- Colors
    COLORS: { [string]: Color3 }
    RARITY_COLORS: { [number]: Color3 }
    
    -- Fonts
    FONTS: { [string]: Enum.Font }
    
    -- Sounds
    SOUNDS: { [string]: string }
    
    -- Icons
    ICONS: { [string]: string }
    
    -- Methods
    Get(path: string): any
    Validate(): boolean
}
```

### 3. ClientServices
```lua
--[[
    Module: ClientServices
    Purpose: Roblox service references
    Dependencies: None
]]

interface ClientServices {
    -- Core Services
    Players: Players
    ReplicatedStorage: ReplicatedStorage
    UserInputService: UserInputService
    TweenService: TweenService
    RunService: RunService
    
    -- Additional Services
    HttpService: HttpService
    SoundService: SoundService
    GuiService: GuiService
    ContentProvider: ContentProvider
    MarketplaceService: MarketplaceService
    
    -- Player References
    LocalPlayer: Player
    PlayerGui: PlayerGui
    Character: Model?
    Humanoid: Humanoid?
    Mouse: Mouse
    
    -- Methods
    Get(serviceName: string): Instance?
    WaitForCharacter(): Model
}
```

## Infrastructure Module Interfaces

### 4. RemoteManager
```lua
--[[
    Module: RemoteManager
    Purpose: Centralized remote communication management
    Dependencies: ClientServices
]]

interface RemoteManager {
    -- Remote Access
    GetRemoteEvent(name: string): RemoteEvent?
    GetRemoteFunction(name: string): RemoteFunction?
    
    -- Event Handling
    On(eventName: string, handler: (...any) -> void): Connection
    Once(eventName: string, handler: (...any) -> void): Connection
    Fire(eventName: string, ...any): void
    
    -- Function Handling
    Invoke(functionName: string, ...any): any
    SetInvokeHandler(functionName: string, handler: (...any) -> any): void
    
    -- Monitoring
    GetTraffic(): { sent: number, received: number }
    EnableDebug(enabled: boolean): void
    
    -- Cleanup
    DisconnectAll(): void
}
```

### 5. StateManager
```lua
--[[
    Module: StateManager
    Purpose: Centralized state management with subscriptions
    Dependencies: None
]]

interface StateManager {
    -- State Access
    Get(path: string): any
    Set(path: string, value: any): void
    Update(path: string, updater: (current: any) -> any): void
    
    -- Subscriptions
    Subscribe(path: string, callback: (newValue: any, oldValue: any) -> void): Subscription
    SubscribeMany(paths: {string}, callback: (changes: {[string]: any}) -> void): Subscription
    
    -- Transactions
    Transaction(updater: () -> void): void
    
    -- State Management
    Reset(path?: string): void
    GetSnapshot(): table
    LoadSnapshot(snapshot: table): void
    
    -- Events
    OnStateChange: Event<(path: string, newValue: any, oldValue: any) -> void>
}

interface Subscription {
    Unsubscribe(): void
    IsActive(): boolean
}
```

### 6. EventBus
```lua
--[[
    Module: EventBus
    Purpose: Decoupled inter-module communication
    Dependencies: None
]]

interface EventBus {
    -- Event Management
    Fire(eventName: string, ...any): void
    On(eventName: string, handler: (...any) -> void): Connection
    Once(eventName: string, handler: (...any) -> void): Connection
    Off(eventName: string, handler?: (...any) -> void): void
    
    -- Wildcard Events
    OnAny(handler: (eventName: string, ...any) -> void): Connection
    
    -- Event Inspection
    GetListeners(eventName: string): number
    GetEvents(): {string}
    
    -- Debugging
    EnableLogging(enabled: boolean): void
    GetEventHistory(limit?: number): {EventRecord}
}

interface EventRecord {
    timestamp: number
    eventName: string
    args: {any}
}
```

### 7. DataCache
```lua
--[[
    Module: DataCache
    Purpose: Local data caching with change detection
    Dependencies: StateManager
]]

interface DataCache {
    -- Player Data
    GetPlayerData(): PlayerData
    GetCurrency(currencyType: string): number
    GetPets(): {[string]: PetData}
    GetPet(petId: string): PetData?
    GetSettings(): SettingsData
    
    -- Cache Management
    UpdatePlayerData(data: PlayerData): void
    UpdateCurrency(currencyType: string, amount: number): void
    UpdatePets(pets: {[string]: PetData}): void
    
    -- Asset Caching
    CacheAsset(assetId: string, asset: any): void
    GetCachedAsset(assetId: string): any?
    ClearAssetCache(): void
    
    -- Events
    OnDataChanged: Event<(dataType: string, data: any) -> void>
}
```

## System Module Interfaces

### 8. SoundManager
```lua
--[[
    Module: SoundManager
    Purpose: Sound playback with caching and pooling
    Dependencies: ClientServices, ClientConfig
]]

interface SoundManager {
    -- Playback
    PlaySound(soundId: string, volume?: number, pitch?: number): Sound?
    PlaySoundAtPosition(soundId: string, position: Vector3): Sound?
    StopSound(soundId: string): void
    StopAllSounds(): void
    
    -- Volume Control
    SetMasterVolume(volume: number): void
    SetMusicVolume(volume: number): void
    SetSFXVolume(volume: number): void
    GetVolumes(): { master: number, music: number, sfx: number }
    
    -- Preloading
    PreloadSounds(soundIds: {string}): void
    
    -- Cleanup
    ClearCache(): void
}
```

### 9. ParticleSystem
```lua
--[[
    Module: ParticleSystem
    Purpose: Particle effect management
    Dependencies: ClientServices, ClientConfig
]]

interface ParticleSystem {
    -- Particle Creation
    CreateParticle(config: ParticleConfig): Particle
    CreateBurst(config: BurstConfig): void
    CreateTrail(config: TrailConfig): Trail
    
    -- Management
    GetActiveParticles(): number
    SetMaxParticles(max: number): void
    ClearAllParticles(): void
    
    -- Presets
    PlayPreset(presetName: string, position: Vector3): void
}

interface ParticleConfig {
    parent: Instance
    particleType: string
    position: Vector3
    velocity?: Vector3
    lifetime?: number
    size?: number
    color?: Color3
}
```

### 10. NotificationSystem
```lua
--[[
    Module: NotificationSystem
    Purpose: In-game notification display
    Dependencies: UIComponents, EventBus
]]

interface NotificationSystem {
    -- Notifications
    ShowNotification(config: NotificationConfig): NotificationHandle
    ShowSuccess(message: string, duration?: number): NotificationHandle
    ShowError(message: string, duration?: number): NotificationHandle
    ShowWarning(message: string, duration?: number): NotificationHandle
    ShowInfo(message: string, duration?: number): NotificationHandle
    
    -- Management
    ClearAll(): void
    GetActiveCount(): number
}

interface NotificationConfig {
    message: string
    type?: "success" | "error" | "warning" | "info"
    duration?: number
    icon?: string
    sound?: boolean
    actions?: {[string]: () -> void}
}

interface NotificationHandle {
    Dismiss(): void
    Update(message: string): void
}
```

## UI Framework Interfaces

### 11. MainUI
```lua
--[[
    Module: MainUI
    Purpose: Main UI framework and container
    Dependencies: ClientServices, UIComponents
]]

interface MainUI {
    -- UI Elements
    ScreenGui: ScreenGui
    MainPanel: Frame
    NavigationBar: Frame
    CurrencyDisplay: Frame
    
    -- Module Management
    OpenModule(moduleName: string, data?: any): void
    CloseModule(moduleName: string): void
    GetCurrentModule(): string?
    IsModuleOpen(moduleName: string): boolean
    
    -- Overlay Management
    RegisterOverlay(name: string, overlay: Instance): void
    UnregisterOverlay(name: string): void
    GetOverlays(): {[string]: Instance}
    
    -- Events
    OnModuleOpened: Event<(moduleName: string) -> void>
    OnModuleClosed: Event<(moduleName: string) -> void>
}
```

### 12. UIComponents
```lua
--[[
    Module: UIComponents
    Purpose: Reusable UI component factory
    Dependencies: ClientServices, ClientConfig
]]

interface UIComponents {
    -- Basic Components
    CreateButton(config: ButtonConfig): TextButton
    CreateFrame(config: FrameConfig): Frame
    CreateLabel(config: LabelConfig): TextLabel
    CreateImageLabel(config: ImageConfig): ImageLabel
    CreateTextBox(config: TextBoxConfig): TextBox
    
    -- Advanced Components
    CreateScrollingFrame(config: ScrollConfig): ScrollingFrame
    CreateProgressBar(config: ProgressConfig): Frame & { Update: (value: number) -> void }
    CreateToggle(config: ToggleConfig): Frame & { SetValue: (value: boolean) -> void }
    CreateTab(config: TabConfig): Frame & { SelectTab: (tabName: string) -> void }
    
    -- Component Pools
    GetFromPool(componentType: string): Instance?
    ReturnToPool(component: Instance): void
}
```

## UI Module Interfaces

### 13. ShopUI
```lua
--[[
    Module: ShopUI
    Purpose: Shop interface for eggs, gamepasses, and currency
    Dependencies: MainUI, UIComponents, RemoteManager
]]

interface ShopUI {
    -- Lifecycle
    Open(tab?: string): void
    Close(): void
    IsOpen(): boolean
    
    -- Shop Tabs
    ShowEggShop(): void
    ShowGamepassShop(): void
    ShowCurrencyShop(): void
    
    -- Actions
    PurchaseEgg(eggId: string, count: number): void
    PurchaseGamepass(passId: number): void
    PurchaseCurrency(packageId: string): void
    
    -- Events
    OnPurchase: Event<(itemType: string, itemId: string) -> void>
    OnEggOpened: Event<(results: {PetData}) -> void>
}
```

### 14. InventoryUI
```lua
--[[
    Module: InventoryUI
    Purpose: Pet inventory management
    Dependencies: MainUI, UIComponents, DataCache
]]

interface InventoryUI {
    -- Lifecycle
    Open(): void
    Close(): void
    IsOpen(): boolean
    
    -- Display
    RefreshInventory(): void
    SetFilter(filter: string): void
    SetSort(sortType: string): void
    SearchPets(query: string): void
    
    -- Pet Actions
    ShowPetDetails(petId: string): void
    EquipPet(petId: string): void
    UnequipPet(petId: string): void
    DeletePet(petId: string): void
    
    -- Mass Actions
    OpenMassDelete(): void
    SelectAllPets(rarity?: number): void
    DeselectAllPets(): void
    
    -- Events
    OnPetSelected: Event<(petId: string) -> void>
    OnPetAction: Event<(action: string, petId: string) -> void>
}
```

### 15. TradingUI
```lua
--[[
    Module: TradingUI
    Purpose: Player-to-player trading interface
    Dependencies: MainUI, UIComponents, RemoteManager
]]

interface TradingUI {
    -- Lifecycle
    Open(targetPlayer?: Player): void
    Close(): void
    IsOpen(): boolean
    
    -- Trading
    SendTradeRequest(player: Player): void
    AcceptTrade(): void
    DeclineTrade(): void
    CancelTrade(): void
    
    -- Items
    AddPet(petId: string): void
    RemovePet(petId: string): void
    SetReady(ready: boolean): void
    
    -- History
    ShowTradeHistory(): void
    
    -- Events
    OnTradeStateChanged: Event<(state: string) -> void>
    OnTradeCompleted: Event<(tradeData: TradeData) -> void>
}
```

### 16. BattleUI
```lua
--[[
    Module: BattleUI
    Purpose: Pet battle interface
    Dependencies: MainUI, UIComponents, RemoteManager
]]

interface BattleUI {
    -- Lifecycle
    Open(): void
    Close(): void
    IsOpen(): boolean
    
    -- Battle Management
    StartQuickMatch(): void
    CancelMatchmaking(): void
    JoinBattle(battleId: string): void
    LeaveBattle(): void
    
    -- In-Battle
    SelectMove(moveIndex: number): void
    SwitchPet(petIndex: number): void
    Forfeit(): void
    
    -- Display
    UpdateBattleState(state: BattleState): void
    ShowBattleLog(message: string): void
    
    -- Events
    OnBattleStart: Event<(battleData: BattleData) -> void>
    OnBattleEnd: Event<(result: BattleResult) -> void>
}
```

### 17. QuestUI
```lua
--[[
    Module: QuestUI
    Purpose: Quest tracking and management
    Dependencies: MainUI, UIComponents, DataCache
]]

interface QuestUI {
    -- Lifecycle
    Open(tab?: string): void
    Close(): void
    IsOpen(): boolean
    
    -- Quest Display
    ShowDailyQuests(): void
    ShowWeeklyQuests(): void
    ShowSpecialQuests(): void
    
    -- Quest Actions
    ClaimReward(questId: string): void
    TrackQuest(questId: string): void
    UntrackQuest(questId: string): void
    
    -- Events
    OnQuestCompleted: Event<(questId: string) -> void>
    OnRewardClaimed: Event<(questId: string, rewards: QuestRewards) -> void>
}
```

### 18. SettingsUI
```lua
--[[
    Module: SettingsUI
    Purpose: Game settings interface
    Dependencies: MainUI, UIComponents, StateManager
]]

interface SettingsUI {
    -- Lifecycle
    Open(tab?: string): void
    Close(): void
    IsOpen(): boolean
    
    -- Settings Categories
    ShowAudioSettings(): void
    ShowGraphicsSettings(): void
    ShowGameplaySettings(): void
    ShowAccountSettings(): void
    
    -- Setting Actions
    SetVolume(volumeType: string, value: number): void
    SetGraphicsQuality(quality: string): void
    SetAutoDelete(enabled: boolean, rarities: {number}): void
    
    -- Events
    OnSettingChanged: Event<(setting: string, value: any) -> void>
}
```

## Type Definitions

### Common Types
```lua
type PlayerData = {
    currencies: { [string]: number },
    pets: { [string]: PetData },
    inventory: { [string]: number },
    equipped: { string },
    settings: SettingsData,
    quests: QuestData,
    stats: { [string]: number }
}

type PetData = {
    id: string,
    petId: string,
    level: number,
    experience: number,
    stars: number,
    locked: boolean,
    equipped: boolean,
    nickname?: string,
    variant?: string,
    timestamp: number
}

type SettingsData = {
    musicVolume: number,
    sfxVolume: number,
    particlesEnabled: boolean,
    autoDelete: {
        enabled: boolean,
        rarities: { number }
    }
}

type Connection = {
    Disconnect(): void,
    Connected: boolean
}
```

## Module Communication Patterns

### Event-Based Communication
```lua
-- Module A fires event
EventBus:Fire("OpenTrading", { targetPlayer = player })

-- Module B listens
EventBus:On("OpenTrading", function(data)
    TradingUI:Open(data.targetPlayer)
end)
```

### State-Based Updates
```lua
-- Module updates state
StateManager:Set("player.currencies.coins", 1000)

-- Subscribed modules react
StateManager:Subscribe("player.currencies", function(currencies)
    CurrencyDisplay:Update(currencies)
end)
```

### Direct Module Access (Limited)
```lua
-- Only through dependency injection
function ShopUI.new(dependencies)
    self.notificationSystem = dependencies.notificationSystem
    -- Later...
    self.notificationSystem:ShowSuccess("Purchase complete!")
end
```

## Error Handling Contract

All modules must:
1. Never throw unhandled errors
2. Return success/failure tuples
3. Log errors appropriately
4. Provide user-friendly messages
5. Gracefully degrade functionality

```lua
-- Example error handling
function Module:RiskyOperation()
    local success, result = pcall(function()
        -- Risky code
    end)
    
    if not success then
        self:LogError("Operation failed", result)
        return false, "Operation failed. Please try again."
    end
    
    return true, result
end
```

## Performance Contract

All modules must:
1. Lazy load when possible
2. Clean up resources on close
3. Use object pooling for frequent allocations
4. Batch UI updates
5. Profile performance in development

## Memory Management Contract

All modules must:
1. Disconnect all connections on cleanup
2. Clear references to large objects
3. Return pooled objects when done
4. Avoid circular references
5. Implement Destroy() method