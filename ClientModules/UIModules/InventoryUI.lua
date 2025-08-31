--[[
    Module: InventoryUI
    Description: Comprehensive pet inventory management UI with grid display, filtering,
                 sorting, mass actions, virtual scrolling, and card recycling
    Features: Pet grid, filters by rarity/equipped/locked, sorting, search, mass delete,
              pet details integration, real-time updates, card recycling for performance
]]

local Types = require(script.Parent.Parent.Core.ClientTypes)
local Config = require(script.Parent.Parent.Core.ClientConfig)
local Services = require(script.Parent.Parent.Core.ClientServices)
local Utilities = require(script.Parent.Parent.Core.ClientUtilities)
local Janitor = require(game.ReplicatedStorage.Modules.Shared.Janitor)
local EffectPool = require(script.Parent.Parent.Systems.EffectPool)

local InventoryUI = {}
InventoryUI.__index = InventoryUI

-- ========================================
-- TYPES
-- ========================================

type PetInstance = {
    uniqueId: string,
    petId: string,
    level: number,
    experience: number,
    power: number,
    speed: number,
    luck: number,
    equipped: boolean,
    locked: boolean,
    nickname: string?,
    variant: string?,
    obtained: number,
    source: string?,
}

type FilterType = "All" | "Equipped" | "Locked" | "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythical" | "Shiny" | "Golden" | "Rainbow"
type SortType = "Rarity" | "Level" | "Power" | "Recent" | "Name"

-- ========================================
-- CONSTANTS
-- ========================================

local GRID_PADDING = 10
local CARD_SIZE = Vector2.new(120, 140) -- Reduced height - no stats display
local CARDS_PER_ROW = 5
local SCROLL_THRESHOLD = 5 -- Cards to preload above/below viewport
local SEARCH_DEBOUNCE = 0.3

-- Sort and Filter type constants to prevent typos
local SORT_TYPE = {
    RARITY = "Rarity",
    LEVEL = "Level",
    POWER = "Power",
    RECENT = "Recent",
    NAME = "Name",
}

local FILTER_TYPE = {
    ALL = "All",
    EQUIPPED = "Equipped",
    LOCKED = "Locked",
    COMMON = "Common",
    UNCOMMON = "Uncommon",
    RARE = "Rare",
    EPIC = "Epic",
    LEGENDARY = "Legendary",
    MYTHICAL = "Mythical",
    SHINY = "Shiny",
    GOLDEN = "Golden",
    RAINBOW = "Rainbow",
}

local PET_ATTRIBUTE = {
    PET_NAME = "PetName",
    NICKNAME = "PetNickname",
    RARITY = "Rarity",
    EQUIPPED = "Equipped",
    LOCKED = "Locked",
}
local MAX_CARD_CACHE = 100
local MASS_DELETE_WINDOW_SIZE = Vector2.new(600, 500)
local STATS_UPDATE_RATE = 0.5

-- Filter definitions
local FILTER_DEFINITIONS = {
    All = function() return true end,
    Equipped = function(pet) return pet.equipped == true end,
    Locked = function(pet) return pet.locked == true end,
    Common = function(pet, petData) return petData.rarity == 1 end,
    Uncommon = function(pet, petData) return petData.rarity == 2 end,
    Rare = function(pet, petData) return petData.rarity == 3 end,
    Epic = function(pet, petData) return petData.rarity == 4 end,
    Legendary = function(pet, petData) return petData.rarity == 5 end,
    Mythical = function(pet, petData) return petData.rarity == 6 end,
    Shiny = function(pet) return pet.variant == "shiny" end,
    Golden = function(pet) return pet.variant == "golden" end,
    Rainbow = function(pet) return pet.variant == "rainbow" end,
}

-- Sort functions
local SORT_FUNCTIONS = {
    Rarity = function(a, b, aData, bData)
        return (aData.rarity or 1) > (bData.rarity or 1)
    end,
    Level = function(a, b)
        return (a.level or 1) > (b.level or 1)
    end,
    Power = function(a, b, aData, bData)
        -- Calculate power based on multiple factors
        local function calculatePower(pet, petData)
            -- Direct power value if exists
            if pet.calculatedPower then
                return pet.calculatedPower
            end
            
            local power = 0
            
            -- Try direct power value
            if pet.power and type(pet.power) == "number" and pet.power > 0 then
                power = pet.power
            -- Calculate from stats if available
            elseif pet.stats then
                -- Common stat names for power calculation
                local attack = pet.stats.attack or pet.stats.damage or pet.stats.atk or 0
                local defense = pet.stats.defense or pet.stats.def or 0
                local health = pet.stats.health or pet.stats.hp or 0
                local speed = pet.stats.speed or pet.stats.spd or 0
                
                -- Calculate combined power
                power = (attack * 2) + defense + (health / 10) + speed
            -- Try baseStats from template data
            elseif petData and petData.baseStats then
                local basePower = petData.baseStats.power or petData.baseStats.attack or 100
                power = basePower * (pet.level or 1)
            else
                -- Fallback: use rarity and level
                local rarityMultiplier = 1
                if petData and petData.rarity then
                    rarityMultiplier = petData.rarity
                elseif pet.rarity then
                    rarityMultiplier = pet.rarity
                end
                
                power = (pet.level or 1) * 100 * rarityMultiplier
            end
            
            -- Cache the calculated power
            pet.calculatedPower = power
            return power
        end
        
        local aPower = calculatePower(a, aData)
        local bPower = calculatePower(b, bData)
        
        -- Debug logging for first comparison only
        if _G._powerSortDebug ~= false then
            print(string.format("[Power Sort] Pet A: %s (Power: %d) vs Pet B: %s (Power: %d)", 
                a.nickname or (aData and aData.name) or "Unknown", aPower,
                b.nickname or (bData and bData.name) or "Unknown", bPower))
            _G._powerSortDebug = false -- Only log once
        end
        
        return aPower > bPower
    end,
    Recent = function(a, b)
        return (a.obtained or 0) > (b.obtained or 0)
    end,
    Name = function(a, b, aData, bData)
        local aName = a.nickname or aData.name or aData.displayName or "Unknown"
        local bName = b.nickname or bData.name or bData.displayName or "Unknown"
        return aName < bName
    end,
}

-- ========================================
-- INITIALIZATION
-- ========================================

function InventoryUI.new(dependencies)
    local self = setmetatable({}, InventoryUI)
    
    -- Initialize Janitor for memory management
    self._janitor = Janitor.new()
    
    -- Dependencies
    self._eventBus = dependencies.EventBus
    self._stateManager = dependencies.StateManager
    self._dataCache = dependencies.DataCache
    self._remoteManager = dependencies.RemoteManager
    self._soundSystem = dependencies.SoundSystem
    self._particleSystem = dependencies.ParticleSystem
    self._animationSystem = dependencies.AnimationSystem
    self._notificationSystem = dependencies.NotificationSystem
    self._uiFactory = dependencies.UIFactory
    self._windowManager = dependencies.WindowManager
    self._config = dependencies.Config or Config
    self._utilities = dependencies.Utilities or Utilities
    
    -- Pet name mapping - we'll populate this from server data
    self._petNameCache = {}
    
    -- UI References
    self.Frame = nil
    self.PetGrid = nil
    self.TabFrames = {}
    self.StatsLabels = {}
    self.PetCardCache = {}
    self.DeleteSelectionGrid = nil
    self.SelectedForDeletion = {}
    self.DeleteSelectedLabel = nil
    self.DeleteOverlay = nil
    
    -- Real-time Stats Tracking System
    self._realtimeStats = {
        -- Current values
        totalPets = 0,
        equippedPets = 0,
        displayedPets = 0,
        maxStorage = 500,
        
        -- Animation states
        animatingValues = {},
        targetValues = {},
        
        -- Update tracking
        lastUpdate = 0,
        pendingUpdates = {},
        updateThread = nil
    }
    
    -- Stats update queue for batching
    self._statsUpdateQueue = {}
    self._statsUpdateTimer = nil
    
    -- Pagination
    self.CurrentPage = 1
    self.PetsPerPage = 40
    self.TotalPages = 1
    self.PaginationControls = {}
    
    -- State
    self.IsRefreshing = false
    self.CurrentFilter = FILTER_TYPE.ALL
    self.CurrentSort = SORT_TYPE.LEVEL
    self.SearchText = ""
    self.VisiblePets = {}
    self.PetWatcher = nil
    self.CurrentRefreshThread = nil
    self.SearchDebounce = nil
    
    -- Performance
    self.LastRefreshTime = 0
    self.RefreshCooldown = 0.5
    
    -- Virtual Scrolling
    self.VirtualScrollEnabled = true
    self.VisibleCardPool = {}  -- Pool of reusable card frames
    self.ActiveCards = {}  -- Currently visible cards mapped to data
    self.CardHeight = 140  -- Height of each card (reduced - no stats)
    self.CardPadding = 10  -- Padding between cards
    self.ColumnsPerRow = 5  -- Number of columns
    self.VisibleRows = 4  -- Number of visible rows
    self.ScrollConnection = nil
    self.LastScrollPosition = 0
    
    -- Effect Pools
    self.GlowEffectPool = EffectPool.new({
        effectType = "GlowEffect",
        initialSize = 20,
        maxSize = 100,
        createFunction = function()
            local glow = Instance.new("ImageLabel")
            glow.Name = "PooledGlowEffect"
            glow.BackgroundTransparency = 1
            glow.Image = "rbxassetid://5028857084"
            glow.ImageTransparency = 0.7
            glow.ScaleType = Enum.ScaleType.Slice
            glow.SliceCenter = Rect.new(24, 24, 24, 24)
            glow.Size = UDim2.new(1, 20, 1, 20)
            glow.Position = UDim2.new(0.5, 0, 0.5, 0)
            glow.AnchorPoint = Vector2.new(0.5, 0.5)
            return glow
        end
    })
    
    self.ShineEffectPool = EffectPool.new({
        effectType = "ShineEffect",
        initialSize = 20,
        maxSize = 100,
        createFunction = function()
            local shine = Instance.new("Frame")
            shine.Name = "PooledShineEffect"
            shine.Size = UDim2.new(0, 5, 2, 0)
            shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
            shine.BackgroundColor3 = Color3.new(1, 1, 1)
            shine.BackgroundTransparency = 0.8
            shine.BorderSizePixel = 0
            shine.Rotation = 45
            
            local gradient = Instance.new("UIGradient")
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
            gradient.Parent = shine
            
            return shine
        end
    })
    
    -- Set up event listeners
    self:SetupEventListeners()
    
    -- Initialize VFX system
    self:InitializeVFXSystem()
    
    return self
end

function InventoryUI:SetupEventListeners()
    if not self._eventBus then return end
    
    -- Listen for data updates
    self._janitor:Add(self._eventBus:On("PetsUpdated", function()
        if self.Frame and self.Frame.Visible then
            self:RefreshInventory()
        end
    end))
    
    -- Listen for case results
    self._janitor:Add(self._eventBus:On("CaseResultsCollected", function()
        task.wait(0.5) -- Wait for server to update
        if self.Frame and self.Frame.Visible then
            self:RefreshInventory()
        end
    end))
    
    -- Listen for pet equip/unequip events
    self._janitor:Add(self._eventBus:On("PetEquipped", function(data)
        local success, err = pcall(function()
            -- FIX: Check if data is a table and has the uniqueId
            local uniqueId = type(data) == "table" and data.uniqueId or data
            if not uniqueId then return end
            
            print("[InventoryUI] PetEquipped event received for:", uniqueId)
            if self.Frame and self.Frame.Visible then
                -- Update just the card and stats without full refresh
                self:UpdatePetCardEquipStatus(uniqueId, true)
                -- No need to call RefreshStats() here, UpdatePetCardEquipStatus already handles it
            end
        end)
        if not success then
            warn("[InventoryUI] Error in PetEquipped handler:", err)
        end
    end))
    
    self._janitor:Add(self._eventBus:On("PetUnequipped", function(data)
        local success, err = pcall(function()
            -- FIX: Check if data is a table and has the uniqueId
            local uniqueId = type(data) == "table" and data.uniqueId or data
            if not uniqueId then return end
            
            print("[InventoryUI] PetUnequipped event received for:", uniqueId)
            if self.Frame and self.Frame.Visible then
                -- Update just the card and stats without full refresh
                self:UpdatePetCardEquipStatus(uniqueId, false)
                -- No need to call RefreshStats() here, UpdatePetCardEquipStatus already handles it
            end
        end)
        if not success then
            warn("[InventoryUI] Error in PetUnequipped handler:", err)
        end
    end))
    
    -- Listen for remote inventory updates from server
    if self._remoteManager then
        self._remoteManager:On("InventoryUpdated", function(data)
            print("[InventoryUI] Received inventory update from server:", data)
            if data and data.pets then
                -- Update data cache with new pets
                if self._dataCache then
                    self._dataCache:Set("pets", data.pets)
                    self._dataCache:Set("petCount", data.petCount or 0)
                    
                    -- Also update playerData pets
                    local playerData = self._dataCache:Get("playerData") or {}
                    playerData.pets = data.pets
                    playerData.petCount = data.petCount or 0
                    self._dataCache:Set("playerData", playerData)
                end
                -- Refresh UI
                if self.Frame and self.Frame.Visible then
                    self:RefreshInventory()
                end
            end
        end)
        
        self._remoteManager:On("PetUpdated", function(data)
            print("[InventoryUI] Received pet update from server:", data)
            print("[InventoryUI] Pet update action:", data and data.action)
            print("[InventoryUI] Pet data:", data and data.pet)
            
            if data and data.action == "added" and data.pet then
                -- Update data cache with new pet
                if self._dataCache then
                    local pets = self._dataCache:Get("pets") or {}
                    local petId = data.petId or (data.pet and data.pet.uniqueId)
                    
                    if petId then
                        pets[petId] = data.pet
                        self._dataCache:Set("pets", pets)
                        
                        local petCount = self._dataCache:Get("petCount") or 0
                        petCount = petCount + 1
                        self._dataCache:Set("petCount", petCount)
                        
                        -- Also update playerData
                        local playerData = self._dataCache:Get("playerData") or {}
                        playerData.pets = pets
                        playerData.petCount = petCount
                        self._dataCache:Set("playerData", playerData)
                        
                        print("[InventoryUI] Updated pet cache. Total pets:", petCount)
                        print("[InventoryUI] Pet IDs in cache:", petId)
                    else
                        warn("[InventoryUI] No petId found in update data")
                    end
                else
                    warn("[InventoryUI] No dataCache available")
                end
                -- Refresh UI
                if self.Frame and self.Frame.Visible then
                    print("[InventoryUI] Refreshing inventory display")
                    self:RefreshInventory()
                else
                    print("[InventoryUI] Frame not visible, skipping refresh")
                end
            end
        end)
    end
    
    -- Listen for pet actions
    self._janitor:Add(self._eventBus:On("PetEquipped", function(data)
        self:UpdatePetCardEquipStatus(data.uniqueId, true)
    end))
    
    self._janitor:Add(self._eventBus:On("PetUnequipped", function(data)
        self:UpdatePetCardEquipStatus(data.uniqueId, false)
    end))
    
    self._janitor:Add(self._eventBus:On("RefreshEquippedCount", function()
        self:RefreshEquippedCount()
    end))
    
    self._janitor:Add(self._eventBus:On("PetLocked", function(data)
        self:UpdatePetCardLockStatus(data.uniqueId, true)
    end))
    
    self._janitor:Add(self._eventBus:On("PetUnlocked", function(data)
        self:UpdatePetCardLockStatus(data.uniqueId, false)
    end))
    
    -- Listen for pet deletion
    self._janitor:Add(self._eventBus:On("PetDeleted", function(data)
        -- Fetch fresh data from server to ensure sync
        task.spawn(function()
            self:FetchPlayerData()
            task.wait(0.1) -- Small delay to ensure data is propagated
            self:RefreshInventory()
        end)
    end))
    
    -- Listen for pet level changes
    self._janitor:Add(self._eventBus:On("PetLevelUp", function(data)
        self:UpdatePetCardLevel(data.uniqueId, data.newLevel)
    end))
    
    -- Listen for pet nickname changes
    self._janitor:Add(self._eventBus:On("PetRenamed", function(data)
        self:UpdatePetCardName(data.uniqueId, data.newName)
    end))
end

-- ========================================
-- DATA FETCHING
-- ========================================

function InventoryUI:FetchPlayerData()
    if not self._remoteManager then
        warn("[InventoryUI] No RemoteManager available to fetch data")
        return
    end
    
    print("[InventoryUI] Fetching fresh player data...")
    
    local success, result = pcall(function()
        return self._remoteManager:InvokeServer("GetPlayerData")
    end)
    
    if success and result then
        print("[InventoryUI] Successfully fetched player data")
        print("[InventoryUI] Player data structure:", result)
        
        -- Check for pets in various possible locations
        local pets = nil
        if result.data and result.data.pets then
            pets = result.data.pets
        elseif result.pets then
            pets = result.pets
        elseif result.playerData and result.playerData.pets then
            pets = result.playerData.pets
        end
        
        if pets then
            local petCount = 0
            local equippedCount = 0
            for _, pet in pairs(pets) do
                petCount = petCount + 1
                if pet.equipped then
                    equippedCount = equippedCount + 1
                end
            end
            print("[InventoryUI] Fetched pets count:", petCount, "Equipped:", equippedCount)
            
            -- Update stats (if first time, set directly; otherwise use UpdateSingleStat for animation)
            if self._realtimeStats.totalPets == 0 and self._realtimeStats.equippedPets == 0 then
                -- First time initialization - set values directly
                self._realtimeStats.totalPets = petCount
                self._realtimeStats.equippedPets = equippedCount
                self._realtimeStats.animatingValues.totalPets = petCount
                self._realtimeStats.animatingValues.equippedPets = equippedCount
                
                -- Render initial values immediately
                if self.StatsLabels.Equipped then
                    self.StatsLabels.Equipped.Text = equippedCount .. "/6"
                end
                if self.StatsLabels.PetCount then
                    self.StatsLabels.PetCount.Text = petCount .. "/" .. self._realtimeStats.maxStorage
                end
                
                -- Force render the total pets update
                if self.RenderStatUpdate then
                    self:RenderStatUpdate("totalPets", petCount)
                end
            else
                -- Subsequent updates - use animated update
                local petDelta = petCount - self._realtimeStats.totalPets
                local equippedDelta = equippedCount - self._realtimeStats.equippedPets
                
                if petDelta ~= 0 then
                    self:UpdateSingleStat("totalPets", petDelta)
                end
                if equippedDelta ~= 0 then
                    self:UpdateSingleStat("equippedPets", equippedDelta)
                end
            end
        else
            warn("[InventoryUI] No pets field in player data!")
            if result and type(result) == "table" then
                local keys = {}
                for k, v in pairs(result) do
                    table.insert(keys, tostring(k) .. " (" .. type(v) .. ")")
                end
                print("[InventoryUI] Data structure keys:", table.concat(keys, ", "))
                
                -- Also check if there's a data field
                if result.data and type(result.data) == "table" then
                    local dataKeys = {}
                    for k, v in pairs(result.data) do
                        table.insert(dataKeys, tostring(k) .. " (" .. type(v) .. ")")
                    end
                    print("[InventoryUI] Data.* structure keys:", table.concat(dataKeys, ", "))
                end
            end
        end
        
        -- Update various caches
        if self._dataCache then
            if self._dataCache.Set then
                self._dataCache:Set("playerData", result)
            elseif self._dataCache.Update then
                self._dataCache:Update(function(current)
                    return {playerData = result}
                end)
            end
        end
        
        -- Update state manager
        if self._stateManager then
            if self._stateManager.SetState then
                self._stateManager:SetState({playerData = result})
            elseif self._stateManager.Set then
                -- StateManager.Set expects (path: string, value: any)
                self._stateManager:Set("playerData", result)
            elseif self._stateManager.Update then
                self._stateManager:Update({playerData = result})
            end
        end
        
        -- Fire event
        if self._eventBus then
            self._eventBus:Fire("PlayerDataLoaded", result)
            if result.pets then
                self._eventBus:Fire("PetsUpdated", result.pets)
            end
        end
        
        return result
    else
        warn("[InventoryUI] Failed to fetch player data:", result)
        return nil
    end
end

-- ========================================
-- OPEN/CLOSE
-- ========================================

function InventoryUI:Open()
    -- 1. If the UI doesn't exist, build it completely.
    if not self.Frame or not self.Frame.Parent then
        self:CreateUI()
    end
    
    -- This check is crucial in case CreateUI failed for some reason
    if not self.Frame then 
        warn("[InventoryUI] Failed to create UI frame")
        return 
    end
    
    -- 2. Make the UI visible with animations.
    self.Frame.Visible = true
    self.Frame.BackgroundTransparency = 1
    
    -- Fade in background
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 0
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Animate content with slide effect
    local originalPosition = self.Frame.Position or UDim2.new(0.5, 0, 0.5, 0)
    self.Frame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 100)
    
    self._utilities.Tween(self.Frame, {
        Position = originalPosition
    }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    
    -- 3. Ensure we show the Pets tab first (this creates PetGrid)
    self:ShowTab("Pets")
    
    -- 4. Set up reactive updates if not already done
    if self._dataCache and not self.PetWatcher then
        if self._dataCache.Watch then
            self.PetWatcher = self._dataCache:Watch("pets", function()
                if self.Frame and self.Frame.Visible then
                    self:RefreshInventory()
                end
            end)
        end
    end
    
    -- 5. NOW that the UI is fully built and visible, refresh the content.
    -- This completely prevents the race condition.
    -- Refresh immediately without blocking
    task.spawn(function()
        self:FetchPlayerData()
        self:RefreshInventory()
    end)
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Open")
    end
end

function InventoryUI:Close()
    if not self.Frame or not self.Frame.Visible then return end
    
    -- Cancel any refresh thread that might be running
    if self.CurrentRefreshThread then
        task.cancel(self.CurrentRefreshThread)
        self.CurrentRefreshThread = nil
    end
    
    -- Animate the frame out
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 1,
        Position = UDim2.new(self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, 1, 100)
    }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
    
    -- Don't wait, hide immediately
    self.Frame.Visible = false
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Close")
    end
    
    -- CRITICAL FIX: DO NOT clear these references!
    -- self.PetGrid = nil -- REMOVED
    -- self.TabFrames = {} -- REMOVED
    -- self.CurrentTab = "Pets" -- Keep state
end

-- ========================================
-- WINDOW MANAGER INTEGRATION
-- ========================================

function InventoryUI:Initialize()
    -- This function just builds the UI but doesn't show it
    if not self.Frame then
        self:CreateUI()
    end
end

function InventoryUI:AnimateOpen()
    -- Called by WindowManager to play the open animation
    if not self.Frame then self:Initialize() end
    
    self.Frame.Visible = true
    self.Frame.BackgroundTransparency = 1
    
    -- Quick fade in (reduced from 0.3 to 0.15)
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 0
    }, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Subtle slide effect (reduced distance and time)
    local originalPosition = self.Frame.Position or UDim2.new(0.5, 0, 0.5, 0)
    self.Frame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 0, 20)
    
    self._utilities.Tween(self.Frame, {
        Position = originalPosition
    }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    
    -- Ensure we show the Pets tab first
    self:ShowTab("Pets")
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Open")
    end
end

function InventoryUI:AnimateClose()
    -- Called by WindowManager to play the close animation
    if not self.Frame then return end
    
    -- Cancel any refresh thread
    if self.CurrentRefreshThread then
        task.cancel(self.CurrentRefreshThread)
        self.CurrentRefreshThread = nil
    end
    
    -- Quick fade out (reduced from 0.3 to 0.15)
    self._utilities.Tween(self.Frame, {
        BackgroundTransparency = 1,
        Position = UDim2.new(self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, 0, 20)
    }, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
    
    -- Note: We don't wait here, WindowManager handles the timing
    
    -- Play sound
    if self._soundSystem then
        self._soundSystem:PlayUISound("Close")
    end
end

function InventoryUI:OnReady()
    -- Called by WindowManager AFTER the open animation is finished
    -- This is the safe place to load data!
    
    -- Set up reactive updates if needed
    if self._dataCache and not self.PetWatcher then
        if self._dataCache.Watch then
            self.PetWatcher = self._dataCache:Watch("pets", function()
                if self.Frame and self.Frame.Visible then
                    self:RefreshInventory()
                end
            end)
        end
    end
    
    -- Fetch fresh data and refresh WITHOUT blocking
    task.spawn(function()
        self:FetchPlayerData()
        self:RefreshInventory()
    end)
end

function InventoryUI:OnClosed()
    -- Called by WindowManager after close animation completes
    if self.Frame then
        self.Frame.Visible = false
    end
    
    -- CRITICAL FIX: DO NOT clear these references!
    -- Keeping them allows the UI to work properly when reopened
    -- self.PetGrid = nil -- REMOVED: This was causing the nil error
    -- self.TabFrames = {} -- REMOVED: Preserve tab references
    -- self.CurrentTab = "Pets" -- Keep current tab state
end

-- ========================================
-- UI CREATION
-- ========================================

function InventoryUI:CreateUI()
    local parent = self._mainUI and self._mainUI.MainPanel or 
                   self._windowManager and self._windowManager:GetMainPanel() or 
                   Services.Players.LocalPlayer.PlayerGui:FindFirstChild("SanrioTycoonUI")
    
    if not parent then
        warn("[InventoryUI] No parent container found")
        return
    end
    
    -- Create main frame
    self.Frame = self._uiFactory:CreateFrame(parent, {
        name = "InventoryFrame",
        size = UDim2.new(1, -20, 1, -90),
        position = UDim2.new(0, 10, 0, 80),
        backgroundColor = self._config.COLORS.White,
        visible = true
    })
    
    -- Create header
    self:CreateHeader()
    
    -- Create stats bar
    self:CreateStatsBar()
    
    -- Create controls
    self:CreateControls()
    
    -- Create tabs
    self:CreateTabs()
end

function InventoryUI:CreateHeader()
    local header = self._uiFactory:CreateFrame(self.Frame, {
        name = "Header",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Primary
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "🎀 My Pet Collection 🎀",
        size = UDim2.new(1, -150, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 24
    })
    
    -- Mass Delete button
    local massDeleteBtn = self._uiFactory:CreateButton(header, {
        text = "Mass Delete",
        size = UDim2.new(0, 120, 0, 40),
        position = UDim2.new(1, -130, 0.5, -20),
        backgroundColor = self._config.COLORS.Error,
        callback = function()
            self:OpenMassDelete()
            self._soundSystem:PlayUISound("Click")
        end
    })
end

function InventoryUI:CreateStatsBar()
    local statsBar = Instance.new("Frame")
    statsBar.Name = "StatsBar"
    statsBar.Size = UDim2.new(1, 0, 0, 40)
    statsBar.Position = UDim2.new(0, 0, 0, 60)
    statsBar.BackgroundColor3 = self._config.COLORS.White
    statsBar.Parent = self.Frame
    
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    statsLayout.Padding = UDim.new(0, 20)
    statsLayout.Parent = statsBar
    
    -- Pet count
    local petCountFrame = self:CreateStatDisplay(statsBar, "Pets", "0/500", self._config.COLORS.Primary)
    self.StatsLabels.PetCount = petCountFrame:FindFirstChild("ValueLabel")
    
    -- Equipped count
    local equippedFrame = self:CreateStatDisplay(statsBar, "Equipped", "0/6", self._config.COLORS.Success)
    self.StatsLabels.Equipped = equippedFrame:FindFirstChild("ValueLabel")
    
    -- Storage bar
    local storageFrame = self:CreateStorageBar(statsBar)
    self.StatsLabels.Storage = storageFrame
end

function InventoryUI:CreateStatDisplay(parent: Frame, label: string, value: string, color: Color3): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 1, -10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelText = self._uiFactory:CreateLabel(frame, {
        text = label .. ":",
        size = UDim2.new(0, 60, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = self._config.COLORS.TextSecondary
    })
    
    local valueLabel = self._uiFactory:CreateLabel(frame, {
        name = "ValueLabel",
        text = value,
        size = UDim2.new(1, -70, 1, 0),
        position = UDim2.new(0, 70, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        textColor = color,
        font = self._config.FONTS.Secondary
    })
    
    return frame
end

function InventoryUI:CreateStorageBar(parent: Frame): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 1, -10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -60, 0, 8)
    barBg.Position = UDim2.new(0, 50, 0.5, -4)
    barBg.BackgroundColor3 = self._config.COLORS.Surface
    barBg.Parent = frame
    
    self._utilities.CreateCorner(barBg, 4)
    
    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = self._config.COLORS.Primary
    barFill.Parent = barBg
    
    self._utilities.CreateCorner(barFill, 4)
    
    local label = self._uiFactory:CreateLabel(frame, {
        text = "Storage:",
        size = UDim2.new(0, 50, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        textXAlignment = Enum.TextXAlignment.Right,
        textColor = self._config.COLORS.TextSecondary
    })
    
    -- Store update function in module's storage bars table
    if not self.StorageBars then
        self.StorageBars = {}
    end
    
    local updateFunc = function(current: number)
        local max = self._dataCache and self._dataCache:Get("maxPetStorage") or 500
        local percentage = math.clamp(current / max, 0, 1)
        
        self._utilities.Tween(barFill, {
            Size = UDim2.new(percentage, 0, 1, 0)
        }, self._config.TWEEN_INFO.Fast)
        
        -- Change color based on percentage
        if percentage > 0.9 then
            barFill.BackgroundColor3 = self._config.COLORS.Error
        elseif percentage > 0.7 then
            barFill.BackgroundColor3 = self._config.COLORS.Warning
        else
            barFill.BackgroundColor3 = self._config.COLORS.Primary
        end
    end
    
    self.StorageBars[frame] = {
        barFill = barFill,
        updateFunc = updateFunc
    }
    
    -- Initial update
    if self.StorageBars[frame] then
        self.StorageBars[frame].updateFunc(0)
    end
    
    return frame
end

function InventoryUI:CreateControls()
    local controlsBar = Instance.new("Frame")
    controlsBar.Name = "ControlsBar"
    controlsBar.Size = UDim2.new(1, 0, 0, 50)
    controlsBar.Position = UDim2.new(0, 0, 0, 100)
    controlsBar.BackgroundColor3 = self._config.COLORS.Surface
    controlsBar.Parent = self.Frame
    
    -- Enhanced search box with icon and clear button
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0, 200, 0, 35)
    searchContainer.Position = UDim2.new(0, 10, 0.5, -17.5)
    searchContainer.BackgroundColor3 = self._config.COLORS.White
    searchContainer.Parent = controlsBar
    
    self._utilities.CreateCorner(searchContainer, 8)
    
    -- Search icon
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 20, 0, 20)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -10)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://7072707859" -- Magnifying glass icon
    searchIcon.ImageColor3 = self._config.COLORS.TextSecondary
    searchIcon.Parent = searchContainer
    
    -- Search box with animated placeholder
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -65, 1, 0)
    searchBox.Position = UDim2.new(0, 35, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = self._config.FONTS.Primary
    searchBox.Text = ""
    searchBox.TextColor3 = self._config.COLORS.Dark
    searchBox.TextSize = 14
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer
    
    -- Animated placeholder
    local placeholderText = Instance.new("TextLabel")
    placeholderText.Name = "Placeholder"
    placeholderText.Size = UDim2.new(1, 0, 1, 0)
    placeholderText.BackgroundTransparency = 1
    placeholderText.Font = self._config.FONTS.Primary
    placeholderText.Text = "Search pets..."
    placeholderText.TextColor3 = self._config.COLORS.TextSecondary
    placeholderText.TextSize = 14
    placeholderText.TextXAlignment = Enum.TextXAlignment.Left
    placeholderText.Parent = searchBox
    
    -- Clear button (initially hidden)
    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearButton"
    clearButton.Size = UDim2.new(0, 25, 0, 25)
    clearButton.Position = UDim2.new(1, -30, 0.5, -12.5)
    clearButton.BackgroundColor3 = self._config.COLORS.Surface
    clearButton.Text = "×"
    clearButton.TextColor3 = self._config.COLORS.Dark
    clearButton.TextSize = 20
    clearButton.Font = Enum.Font.SourceSans
    clearButton.Visible = false
    clearButton.Parent = searchContainer
    
    self._utilities.CreateCorner(clearButton, 12)
    
    -- Search functionality
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = searchBox.Text
        
        -- Hide/show placeholder
        placeholderText.Visible = text == ""
        
        -- Show/hide clear button
        clearButton.Visible = text ~= ""
        
        -- Animate search icon
        if text ~= "" then
            self._utilities.Tween(searchIcon, {
                ImageColor3 = self._config.COLORS.Primary
            }, TweenInfo.new(0.2))
        else
            self._utilities.Tween(searchIcon, {
                ImageColor3 = self._config.COLORS.TextSecondary
            }, TweenInfo.new(0.2))
        end
        
        -- Perform search
        self:OnSearchChanged(text)
    end)
    
    -- Focus animations
    self._janitor:Add(searchBox.Focused:Connect(function()
        self._utilities.Tween(searchContainer, {
            BackgroundColor3 = self._utilities.LightenColor(self._config.COLORS.White, 0.05)
        }, TweenInfo.new(0.2))
        
        -- Add glow effect
        local stroke = Instance.new("UIStroke")
        stroke.Name = "FocusStroke"
        stroke.Color = self._config.COLORS.Primary
        stroke.Thickness = 2
        stroke.Transparency = 0.5
        stroke.Parent = searchContainer
        
        self._utilities.Tween(stroke, {
            Transparency = 0
        }, TweenInfo.new(0.2))
    end))
    
    self._janitor:Add(searchBox.FocusLost:Connect(function()
        self._utilities.Tween(searchContainer, {
            BackgroundColor3 = self._config.COLORS.White
        }, TweenInfo.new(0.2))
        
        local stroke = searchContainer:FindFirstChild("FocusStroke")
        if stroke then
            self._utilities.Tween(stroke, {
                Transparency = 1
            }, TweenInfo.new(0.2))
            task.wait(0.2)
            stroke:Destroy()
        end
    end))
    
    -- Clear button functionality
    self._janitor:Add(clearButton.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        searchBox:CaptureFocus()
        
        -- Animation
        clearButton:TweenSize(
            UDim2.new(0, 20, 0, 20),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Back,
            0.1,
            true,
            function()
                clearButton:TweenSize(
                    UDim2.new(0, 25, 0, 25),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Back,
                    0.1,
                    true
                )
            end
        )
    end))
    
    -- Store reference
    self.SearchBox = searchBox
    
    -- Sort dropdown
    local sortOptions = {"Rarity", "Level", "Power", "Recent", "Name"}
    self.SortDropdown = self:CreateDropdown(controlsBar, "Sort by", sortOptions, 
        UDim2.new(0, 150, 0, 35), UDim2.new(0, 220, 0.5, -17.5),
        function(option)
            print("[InventoryUI] Sort dropdown selected:", option)
            self.CurrentSort = option
            self.CurrentPage = 1  -- Reset to first page
            
            -- Reset power sort debug flag
            if option == "Power" then
                _G._powerSortDebug = true
            end
            
            self:RefreshInventory()
        end
    )
    
    -- Filter dropdown
    local filterOptions = {"All", "Equipped", "Locked", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Shiny", "Golden", "Rainbow"}
    self.FilterDropdown = self:CreateDropdown(controlsBar, "Filter", filterOptions,
        UDim2.new(0, 150, 0, 35), UDim2.new(0, 380, 0.5, -17.5),
        function(option)
            self.CurrentFilter = option
            self.CurrentPage = 1  -- Reset to first page
            self:RefreshInventory()
        end
    )
    

end

function InventoryUI:CreateDropdown(parent: Frame, placeholder: string, options: {string}, 
                                   size: UDim2, position: UDim2, callback: (string) -> ())
    -- Create main dropdown frame
    local dropdown = Instance.new("Frame")
    dropdown.Name = placeholder .. "Dropdown"
    dropdown.Size = size
    dropdown.Position = position
    dropdown.BackgroundColor3 = self._config.COLORS.White
    dropdown.ZIndex = 10
    dropdown.Parent = parent
    
    self._utilities.CreateCorner(dropdown, 8)
    self._utilities.CreateStroke(dropdown, self._config.COLORS.Primary, 2)
    
    -- Create the main button
    local button = Instance.new("TextButton")
    button.Name = "DropdownButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = placeholder
    button.Font = self._config.FONTS.Primary
    button.TextColor3 = self._config.COLORS.Dark
    button.TextScaled = true
    button.Parent = dropdown
    
    -- Add text size constraint
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 18
    textConstraint.MinTextSize = 12
    textConstraint.Parent = button
    
    -- Arrow label
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = self._config.COLORS.TextSecondary
    arrow.TextScaled = true
    arrow.Font = Enum.Font.SourceSans
    arrow.Parent = dropdown
    
    -- Options frame (hidden by default)
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "OptionsFrame"
    optionsFrame.Size = UDim2.new(1, 0, 0, #options * 30 + 10)
    optionsFrame.Position = UDim2.new(0, 0, 1, 5)
    optionsFrame.BackgroundColor3 = self._config.COLORS.White
    optionsFrame.ZIndex = 999  -- Very high to ensure it's on top
    optionsFrame.Visible = false
    optionsFrame.Parent = dropdown
    
    self._utilities.CreateCorner(optionsFrame, 8)
    self._utilities.CreateStroke(optionsFrame, self._config.COLORS.Primary, 2)
    
    -- Create option buttons
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option" .. i
        optionButton.Size = UDim2.new(1, -10, 0, 30)
        optionButton.Position = UDim2.new(0, 5, 0, (i-1) * 30 + 5)
        optionButton.BackgroundColor3 = self._config.COLORS.White
        optionButton.Text = option
        optionButton.TextColor3 = self._config.COLORS.Dark
        optionButton.Font = self._config.FONTS.Primary
        optionButton.TextScaled = true
        optionButton.ZIndex = 999  -- Match parent ZIndex
        optionButton.Parent = optionsFrame
        
        -- Add text size constraint
        local optionConstraint = Instance.new("UITextSizeConstraint")
        optionConstraint.MaxTextSize = 16
        optionConstraint.MinTextSize = 10
        optionConstraint.Parent = optionButton
        
        -- Option button click
        optionButton.MouseButton1Click:Connect(function()
            print("[InventoryUI] Selected option:", option)
            button.Text = option
            optionsFrame.Visible = false
            dropdown.ZIndex = 10
            if callback then
                callback(option)
            end
        end)
        
        -- Hover effects
        optionButton.MouseEnter:Connect(function()
            optionButton.BackgroundColor3 = self._config.COLORS.Surface
        end)
        
        optionButton.MouseLeave:Connect(function()
            optionButton.BackgroundColor3 = self._config.COLORS.White
        end)
    end
    
    -- Main button click
    local isOpen = false
    local isAnimating = false
    local screenGui = self.Frame:FindFirstAncestorOfClass("ScreenGui") -- Find the top-level GUI
    
    button.MouseButton1Click:Connect(function()
        if isAnimating then return end
        
        print("[InventoryUI] Dropdown clicked, isOpen:", isOpen)
        isAnimating = true
        isOpen = not isOpen
        
        if isOpen then
            -- Parent the options to the main ScreenGui to ensure it's on top
            optionsFrame.Parent = screenGui
            
            -- Wait a frame for absolute position to update
            task.wait()
            
            local dropdownPos = dropdown.AbsolutePosition
            local dropdownSize = dropdown.AbsoluteSize
            optionsFrame.Position = UDim2.new(0, dropdownPos.X, 0, dropdownPos.Y + dropdownSize.Y + 5)
            print("[InventoryUI] Dropdown position:", dropdownPos, "Size:", dropdownSize)
            
            -- Opening animation
            dropdown.ZIndex = 998
            optionsFrame.Visible = true
            optionsFrame.Size = UDim2.new(0, dropdown.AbsoluteSize.X, 0, 0) -- Use absolute size
            self._utilities.Tween(optionsFrame, {
                Size = UDim2.new(0, dropdown.AbsoluteSize.X, 0, #options * 30 + 10)
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            arrow.Text = "▲"
            task.wait(0.2)
            isAnimating = false
        else
            -- Closing animation
            self._utilities.Tween(optionsFrame, {
                Size = UDim2.new(0, dropdown.AbsoluteSize.X, 0, 0)
            }, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
            arrow.Text = "▼"
            task.wait(0.15)
            optionsFrame.Visible = false
            optionsFrame.Parent = dropdown -- Parent it back for proper positioning next time
            optionsFrame.Position = UDim2.new(0, 0, 1, 5) -- Reset position
            optionsFrame.Size = UDim2.new(1, 0, 0, #options * 30 + 10) -- Reset size
            dropdown.ZIndex = 10
            isAnimating = false
        end
    end)
    
    -- Click outside to close
    local clickConnection
    clickConnection = Services.UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen and not isAnimating then
            task.wait() -- Wait a frame to not close immediately
            if isOpen and not isAnimating then
                isAnimating = true
                isOpen = false
                -- Closing animation
                self._utilities.Tween(optionsFrame, {
                    Size = UDim2.new(0, dropdown.AbsoluteSize.X, 0, 0)
                }, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
                arrow.Text = "▼"
                task.spawn(function()
                    task.wait(0.15)
                    optionsFrame.Visible = false
                    optionsFrame.Parent = dropdown -- Parent it back
                    optionsFrame.Position = UDim2.new(0, 0, 1, 5) -- Reset position
                    optionsFrame.Size = UDim2.new(1, 0, 0, #options * 30 + 10) -- Reset size
                    dropdown.ZIndex = 10
                    isAnimating = false
                end)
            end
        end
    end)
    
    -- Clean up on destroy
    self._janitor:Add(clickConnection)
    
    return dropdown
end

function InventoryUI:CreateTabs()
    -- Initialize TabFrames early to prevent nil errors
    self.TabFrames = {}
    
    local tabs = {
        {name = "Pets", callback = function(frame) self:CreatePetGrid(frame) end},
        {name = "Storage", callback = function(frame) self:CreateStorageTab(frame) end},
        {name = "Statistics", callback = function(frame) self:CreateStatsTab(frame) end}
    }
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 1, -170)
    tabContainer.Position = UDim2.new(0, 10, 0, 160)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.Frame
    
    -- Tab buttons
    local tabButtonsFrame = Instance.new("Frame")
    tabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
    tabButtonsFrame.BackgroundTransparency = 1
    tabButtonsFrame.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabButtonsFrame
    
    -- Tab content
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -45)
    tabContent.Position = UDim2.new(0, 0, 0, 45)
    tabContent.BackgroundColor3 = self._config.COLORS.White
    tabContent.Parent = tabContainer
    
    self._utilities.CreateCorner(tabContent, 12)
    
    -- TabFrames already initialized at function start
    
    for i, tab in ipairs(tabs) do
        -- Create tab button
        local tabButton = self._uiFactory:CreateButton(tabButtonsFrame, {
            text = tab.name,
            size = UDim2.new(0, 120, 1, 0),
            backgroundColor = i == 1 and self._config.COLORS.Primary or self._config.COLORS.Surface,
            textColor = i == 1 and self._config.COLORS.White or self._config.COLORS.Dark,
            callback = function()
                -- Smooth tab switching animation
                self:SwitchTab(tab.name, tabButtonsFrame, self.TabFrames, i)
            end
        })
        
        -- Create tab frame
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = tab.name .. "Tab"
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = tabContent
        
        tab.callback(tabFrame)
        self.TabFrames[tab.name] = tabFrame
    end
    
    -- TabFrames already initialized at the start of the function
    self.CurrentTab = "Pets"
    
    -- If there was a pending tab to show, show it now
    if self._pendingTabName then
        self:ShowTab(self._pendingTabName)
        self._pendingTabName = nil
    end
end

function InventoryUI:ShowTab(tabName: string)
    if not self.TabFrames then
        -- Tabs not created yet, store for later
        self._pendingTabName = tabName
        return
    end
    
    if not self.TabFrames[tabName] then
        warn("[InventoryUI] Tab not found:", tabName)
        return
    end
    
    -- Hide all tabs
    for name, frame in pairs(self.TabFrames) do
        frame.Visible = false
    end
    
    -- Show selected tab
    self.TabFrames[tabName].Visible = true
    self.CurrentTab = tabName
    
    -- Update PetGrid reference for Pets tab
    if tabName == "Pets" then
        local petsTab = self.TabFrames["Pets"]
        if petsTab then
            -- Look for PetGrid in container first, then directly
            local container = petsTab:FindFirstChild("PetGridContainer")
            if container then
                self.PetGrid = container:FindFirstChild("PetGridScrollFrame")
            else
                self.PetGrid = petsTab:FindFirstChild("PetGridScrollFrame")
            end
            
            -- Ensure the PetGrid is properly initialized
            if self.PetGrid then
                -- Refresh inventory after switching to pets tab
                task.defer(function()
                    self:RefreshInventory()
                end)
            else
                warn("[InventoryUI] PetGridScrollFrame not found in Pets tab")
            end
        end
    end
end

function InventoryUI:SwitchTab(targetTab: string, tabButtonsFrame: Frame, tabFrames: table, buttonIndex: number)
    -- Prevent switching to same tab
    if self.CurrentTab == targetTab then return end
    
    -- Animate button states
    for j, btn in ipairs(tabButtonsFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            local isActive = j == buttonIndex
            
            -- Smooth color transition for buttons
            self._utilities.Tween(btn, {
                BackgroundColor3 = isActive and self._config.COLORS.Primary or self._config.COLORS.Surface,
                TextColor3 = isActive and self._config.COLORS.White or self._config.COLORS.Dark
            }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            -- Scale effect for active button
            if isActive then
                btn:TweenSize(
                    UDim2.new(0, 125, 1, 2),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Back,
                    0.2,
                    true
                )
            else
                btn:TweenSize(
                    UDim2.new(0, 120, 1, 0),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quad,
                    0.2,
                    true
                )
            end
        end
    end
    
    -- Smooth tab content transition
    local currentFrame = tabFrames[self.CurrentTab]
    local targetFrame = tabFrames[targetTab]
    
    if currentFrame and targetFrame then
        -- Fade out current tab
        self._utilities.Tween(currentFrame, {
            BackgroundTransparency = 1
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        
        -- Slide out animation
        local originalPos = currentFrame.Position
        self._utilities.Tween(currentFrame, {
            Position = UDim2.new(-0.5, 0, currentFrame.Position.Y.Scale, currentFrame.Position.Y.Offset)
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        
        task.wait(0.2)
        currentFrame.Visible = false
        currentFrame.Position = originalPos
        currentFrame.BackgroundTransparency = 0
        
        -- Prepare new tab
        targetFrame.Visible = true
        targetFrame.BackgroundTransparency = 1
        targetFrame.Position = UDim2.new(1.5, 0, targetFrame.Position.Y.Scale, targetFrame.Position.Y.Offset)
        
        -- Slide in animation
        self._utilities.Tween(targetFrame, {
            Position = UDim2.new(0, 0, targetFrame.Position.Y.Scale, targetFrame.Position.Y.Offset),
            BackgroundTransparency = 0
        }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        
        -- Play sound
        if self._soundSystem then
            self._soundSystem:PlayUISound("TabSwitch")
        end
    end
    
    self.CurrentTab = targetTab
    self.TabFrames = tabFrames
    
    -- Update PetGrid reference for Pets tab
    if targetTab == "Pets" then
        local petsTab = self.TabFrames["Pets"]
        if petsTab then
            -- Look for PetGrid in container first, then directly
            local container = petsTab:FindFirstChild("PetGridContainer")
            if container then
                self.PetGrid = container:FindFirstChild("PetGridScrollFrame")
            else
                self.PetGrid = petsTab:FindFirstChild("PetGridScrollFrame")
            end
        end
        
        task.defer(function()
            self:RefreshInventory()
        end)
    end
end

-- ========================================
-- PET GRID
-- ========================================

function InventoryUI:CreatePetGrid(parent: Frame)
    -- Create container for grid and pagination
    local container = Instance.new("Frame")
    container.Name = "PetGridContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Create scrolling frame with reduced height for pagination
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PetGridScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -50) -- Leave space for pagination
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = self._config.COLORS.Primary
    scrollFrame.ScrollBarImageTransparency = 0.6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
    scrollFrame.Parent = container
    
    self.PetGrid = scrollFrame
    
    -- Create pagination controls
    local paginationFrame = Instance.new("Frame")
    paginationFrame.Name = "PaginationFrame"
    paginationFrame.Size = UDim2.new(1, -20, 0, 40)
    paginationFrame.Position = UDim2.new(0, 10, 1, -45)
    paginationFrame.BackgroundColor3 = self._config.COLORS.Surface
    paginationFrame.Parent = container
    
    self._utilities.CreateCorner(paginationFrame, 8)
    
    -- Previous button
    local prevButton = self._uiFactory:CreateButton(paginationFrame, {
        text = "◀",
        size = UDim2.new(0, 40, 0, 30),
        position = UDim2.new(0, 10, 0.5, -15),
        backgroundColor = self._config.COLORS.Primary,
        callback = function()
            self:ChangePage(self.CurrentPage - 1)
        end
    })
    self.PaginationControls.PrevButton = prevButton
    
    -- Page display
    local pageLabel = self._uiFactory:CreateLabel(paginationFrame, {
        text = "Page 1 / 1",
        size = UDim2.new(1, -120, 1, 0),
        position = UDim2.new(0.5, -60, 0, 0),
        font = self._config.FONTS.Primary,
        textColor = self._config.COLORS.Text
    })
    self.PaginationControls.PageLabel = pageLabel
    
    -- Next button
    local nextButton = self._uiFactory:CreateButton(paginationFrame, {
        text = "▶",
        size = UDim2.new(0, 40, 0, 30),
        position = UDim2.new(1, -50, 0.5, -15),
        backgroundColor = self._config.COLORS.Primary,
        callback = function()
            self:ChangePage(self.CurrentPage + 1)
        end
    })
    self.PaginationControls.NextButton = nextButton
    
    -- Add scroll detection for non-virtual scrolling
    self._janitor:Add(scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self.IsScrolling = true
        
        -- Clear scrolling flag after a delay
        if self.ScrollDebounce then
            task.cancel(self.ScrollDebounce)
        end
        self.ScrollDebounce = task.delay(0.2, function()
            self.IsScrolling = false
            -- Refresh VFX after scrolling stops
            self:RefreshVisibleVFX()
        end)
    end))
    
    -- Add responsive grid layout
    local function updateGridLayout()
        if not self.PetGrid then return end -- Safety check
        
        local frameWidth = self.PetGrid.AbsoluteSize.X
        if frameWidth == 0 then return end -- Avoid dividing by zero
        
        local cardWidth = CARD_SIZE.X + GRID_PADDING
        local columns = math.max(2, math.floor(frameWidth / cardWidth)) -- At least 2 columns
        
        if columns ~= self.ColumnsPerRow then
            self.ColumnsPerRow = columns
            -- Recalculate canvas and refresh display if we have pets
            if self.VisiblePets and #self.VisiblePets > 0 then
                self:RefreshInventory()
            end
        end
    end
    
    -- Update on size change
    self._janitor:Add(self.PetGrid:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateGridLayout))
    task.defer(updateGridLayout) -- Initial update
    
    -- Add momentum scrolling
    local lastScrollPosition = scrollFrame.CanvasPosition
    local velocity = Vector2.new(0, 0)
    local scrollConnection = nil
    local isScrolling = false
    
    -- Smooth momentum scrolling
    scrollConnection = self._janitor:Add(game:GetService("RunService").Heartbeat:Connect(function(dt)
        if velocity.Magnitude > 0.1 and not isScrolling then
            -- Apply momentum
            local newPosition = scrollFrame.CanvasPosition + velocity * dt * 60
            
            -- Clamp to bounds with elastic effect
            local maxY = math.max(0, scrollFrame.AbsoluteCanvasSize.Y - scrollFrame.AbsoluteSize.Y)
            
            if newPosition.Y < -50 then
                newPosition = Vector2.new(newPosition.X, -50 + (newPosition.Y + 50) * 0.3)
                velocity = velocity * 0.7
            elseif newPosition.Y > maxY + 50 then
                newPosition = Vector2.new(newPosition.X, maxY + 50 - (newPosition.Y - maxY - 50) * 0.3)
                velocity = velocity * 0.7
            end
            
            scrollFrame.CanvasPosition = newPosition
            
            -- Apply damping
            velocity = velocity * 0.94
            
            -- Snap back if overscrolled
            if newPosition.Y < 0 then
                scrollFrame.CanvasPosition = Vector2.new(newPosition.X, math.max(0, newPosition.Y + 2))
            elseif newPosition.Y > maxY then
                scrollFrame.CanvasPosition = Vector2.new(newPosition.X, math.min(maxY, newPosition.Y - 2))
            end
        end
    end))
    
    -- Track scrolling for momentum
    local lastTime = tick()
    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local currentTime = tick()
        local dt = currentTime - lastTime
        
        if dt > 0 and isScrolling then
            local delta = scrollFrame.CanvasPosition - lastScrollPosition
            velocity = delta / dt * 0.5 -- Smooth velocity calculation
            lastScrollPosition = scrollFrame.CanvasPosition
        end
        
        lastTime = currentTime
    end)
    
    -- Detect when user starts/stops scrolling
    scrollFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel or 
           input.UserInputType == Enum.UserInputType.Touch then
            isScrolling = true
            velocity = Vector2.new(0, 0)
        end
    end)
    
    scrollFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel or 
           input.UserInputType == Enum.UserInputType.Touch then
            isScrolling = false
        end
    end)
    
    -- Mouse wheel scrolling with acceleration
    scrollFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local scrollSpeed = 50 * input.Position.Z
            velocity = Vector2.new(0, -scrollSpeed * 2)
        end
    end)
    
    -- Fade scrollbar on hover
    self._janitor:Add(scrollFrame.MouseEnter:Connect(function()
        self._utilities.Tween(scrollFrame, {
            ScrollBarImageTransparency = 0.2
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end))
    
    self._janitor:Add(scrollFrame.MouseLeave:Connect(function()
        self._utilities.Tween(scrollFrame, {
            ScrollBarImageTransparency = 0.6
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end))
    
    -- Store connection for cleanup
    self._scrollConnection = scrollConnection
    
    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "PetGridLayout"
    gridLayout.CellSize = UDim2.new(0, CARD_SIZE.X, 0, CARD_SIZE.Y)
    gridLayout.CellPadding = UDim2.new(0, GRID_PADDING, 0, GRID_PADDING)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Auto-size canvas
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

function InventoryUI:ClearGrid()
    if not self.PetGrid then return end
    
    -- This loop is now the single source of truth for cleaning the grid.
    -- It destroys ALL children: pet cards, loading labels, and empty state messages.
    for _, child in ipairs(self.PetGrid:GetChildren()) do
        if child:IsA("GuiObject") then
            -- Don't destroy the UIGridLayout itself
            if not child:IsA("UIGridLayout") then
                child:Destroy()
            end
        end
    end
    
    -- Also clear the active card cache if using virtual scrolling
    self.ActiveCards = {}
    
    -- Clear the card pool references
    if self.VirtualScrollEnabled then
        for _, card in pairs(self.VisibleCardPool) do
            if card.Parent then
                card.Parent = nil
            end
        end
    end
end

-- ========================================
-- PET CARD CREATION
-- ========================================

function InventoryUI:CreatePetCard(parent: ScrollingFrame, petInstance: PetInstance, templateData: table): Frame?
    if not petInstance or not templateData then
        return nil
    end
    
    -- For clarity, rename templateData to petData internally
    local petData = templateData
    
    -- Create card container
    local card = Instance.new("Frame")
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.petId or "unknown")
    card.BackgroundColor3 = self._config.COLORS.White or Color3.new(1, 1, 1)
    card.BorderSizePixel = 0
    card.Parent = parent
    
    -- Store pet data as attributes for filtering
    card:SetAttribute("PetName", petData.name or petData.displayName or "Unknown")
    card:SetAttribute("PetNickname", petInstance.nickname or "")
    card:SetAttribute("Rarity", petData.rarity or 1)
    card:SetAttribute("Equipped", petInstance.equipped or false)
    card:SetAttribute("Locked", petInstance.locked or false)
    
    self._utilities.CreateCorner(card, 8)
    
    -- Rarity border
    local border = Instance.new("Frame")
    border.Name = "RarityBorder"
    border.Size = UDim2.new(1, 0, 0, 4)
    border.Position = UDim2.new(0, 0, 1, -4)
    border.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    border.BorderSizePixel = 0
    border.Parent = card
    
    -- Pet image container
    local imageContainer = Instance.new("Frame")
    imageContainer.Name = "ImageContainer"
    imageContainer.Size = UDim2.new(1, -10, 1, -40)
    imageContainer.Position = UDim2.new(0, 5, 0, 5)
    imageContainer.BackgroundTransparency = 1
    imageContainer.ZIndex = 2  -- Above effects container
    imageContainer.Parent = card
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Name = "PetImage"
    petImage.Size = UDim2.new(1, 0, 1, 0)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = imageContainer
    

    
    -- Level badge
    local levelBadge = Instance.new("Frame")
    levelBadge.Name = "LevelBadge"
    levelBadge.Size = UDim2.new(0, 30, 0, 20)
    levelBadge.Position = UDim2.new(0, 2, 0, 2)
    levelBadge.BackgroundColor3 = self._config.COLORS.Dark
    levelBadge.Parent = card
    
    self._utilities.CreateCorner(levelBadge, 4)
    
    local levelLabel = self._uiFactory:CreateLabel(levelBadge, {
        text = "Lv." .. tostring(petInstance.level or 1),
        size = UDim2.new(1, 0, 1, 0),
        textColor = self._config.COLORS.White,
        textSize = 12
    })
    
    -- Equipped indicator
    if petInstance.equipped then
        local equippedIndicator = Instance.new("ImageLabel")
        equippedIndicator.Name = "EquippedIndicator"
        equippedIndicator.Size = UDim2.new(0, 24, 0, 24)
        equippedIndicator.Position = UDim2.new(1, -26, 0, 2)
        equippedIndicator.BackgroundTransparency = 1
        equippedIndicator.Image = "rbxassetid://7072717697" -- Checkmark icon
        equippedIndicator.ImageColor3 = self._config.COLORS.Success
        equippedIndicator.Parent = card
    end
    
    -- Lock indicator
    if petInstance.locked then
        local lockIndicator = Instance.new("ImageLabel")
        lockIndicator.Name = "LockIndicator"
        lockIndicator.Size = UDim2.new(0, 20, 0, 20)
        lockIndicator.Position = UDim2.new(1, -24, 1, -24)
        lockIndicator.BackgroundTransparency = 1
        lockIndicator.Image = "rbxassetid://7072718266" -- Lock icon
        lockIndicator.ImageColor3 = self._config.COLORS.Warning
        lockIndicator.Parent = card
    end
    
    -- Pet name (centered at bottom)
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = petInstance.nickname or petData.name or petData.displayName or "Unknown",
        size = UDim2.new(1, -10, 0, 25),
        position = UDim2.new(0, 5, 1, -30),
        textScaled = true,
        font = self._config.FONTS.Primary,
        textXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Store data as attributes for later VFX refresh
    card:SetAttribute("PetInstance", petInstance)
    card:SetAttribute("PetData", petData)
    
    -- DISABLED VFX TO FIX LAG
    -- self:ApplyPremiumVFX(card, petInstance, petData)
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 10  -- Ensure button is always on top
    button.Parent = card
    
    self._janitor:Add(button.MouseButton1Click:Connect(function()
        if self._config.DEBUG.ENABLED then
            print("[InventoryUI] Pet card clicked:", petInstance.uniqueId)
        end
        -- Fire event to show pet details
        if self._eventBus then
            self._eventBus:Fire("ShowPetDetails", {
                petInstance = petInstance,
                petData = petData
            })
        else
            warn("[InventoryUI] EventBus not available for ShowPetDetails")
        end
    end))
    
    -- Premium hover effects
    local originalZIndex = card.ZIndex or 1
    local glowFrame = nil
    local shadowFrame = nil
    
    -- Create background container for effects
    local bgContainer = Instance.new("Frame")
    bgContainer.Name = "EffectsContainer"
    bgContainer.Size = UDim2.new(1, 0, 1, 0)
    bgContainer.BackgroundTransparency = 1
    bgContainer.ZIndex = 0  -- Lowest in the card
    bgContainer.Parent = card
    
    -- Create shadow that will grow on hover (as child of effects container)
    shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.Size = UDim2.new(1, 6, 1, 6)
    shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 3)
    shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.8
    shadowFrame.ZIndex = 0
    shadowFrame.Parent = bgContainer
    self._utilities.CreateCorner(shadowFrame, 10)
    
    -- Move card above shadow
    card.ZIndex = originalZIndex + 2
    
    self._janitor:Add(button.MouseEnter:Connect(function()
        -- Bring to front
        card.ZIndex = originalZIndex + 10
        button.ZIndex = 20  -- Keep button on top when hovering
        -- Shadow stays at ZIndex -1 relative to card
        
        -- Create glow effect (destroy old one first if it exists)
        if glowFrame and glowFrame.Parent then
            glowFrame:Destroy()
        end
        
        -- Find or create a background container for effects
        local bgContainer = card:FindFirstChild("EffectsContainer")
        if not bgContainer then
            bgContainer = Instance.new("Frame")
            bgContainer.Name = "EffectsContainer"
            bgContainer.Size = UDim2.new(1, 0, 1, 0)
            bgContainer.BackgroundTransparency = 1
            bgContainer.ZIndex = 0  -- Lowest in the card
            bgContainer.Parent = card
        end
        
        -- Get glow effect from pool
        glowFrame = self.GlowEffectPool:GetEffect()
        glowFrame.Name = "GlowEffect"
        glowFrame.Size = UDim2.new(1, 16, 1, 16)
        glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        glowFrame.ImageColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
        glowFrame.ImageTransparency = 0.7
        glowFrame.ZIndex = 1
        glowFrame.Parent = bgContainer
        
        -- Store reference for cleanup
        card:SetAttribute("ActiveGlowEffect", glowFrame)
        
        -- Animate background color
        self._utilities.Tween(card, {
            BackgroundColor3 = self._utilities.LightenColor(self._config.COLORS.Surface, 0.15)
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Scale up with bounce
        card:TweenSize(
            UDim2.new(0, CARD_SIZE.X * 1.08, 0, CARD_SIZE.Y * 1.08),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Back,
            0.25,
            true
        )
        
        -- Animate shadow growth
        self._utilities.Tween(shadowFrame, {
            Size = UDim2.new(1, 16, 1, 16),
            Position = UDim2.new(0.5, 0, 0.5, 8),
            BackgroundTransparency = 0.6
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Animate glow
        self._utilities.Tween(glowFrame, {
            ImageTransparency = 0.5,
            Size = UDim2.new(1, 16, 1, 16)
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Slight rotation for 3D effect
        self._utilities.Tween(card, {
            Rotation = 1
        }, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
        
        -- Sound effect
        if self._soundSystem then
            self._soundSystem:PlayUISound("Hover")
        end
    end))
    
    self._janitor:Add(button.MouseLeave:Connect(function()
        -- Reset Z-index
        card.ZIndex = originalZIndex + 2
        button.ZIndex = 10  -- Reset button ZIndex
        -- Shadow stays at ZIndex -1 relative to card
        
        -- Animate background color
        self._utilities.Tween(card, {
            BackgroundColor3 = self._config.COLORS.White or Color3.new(1, 1, 1),
            Rotation = 0
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Scale back smoothly
        card:TweenSize(
            UDim2.new(0, CARD_SIZE.X, 0, CARD_SIZE.Y),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        
        -- Animate shadow shrink
        self._utilities.Tween(shadowFrame, {
            Size = UDim2.new(1, 6, 1, 6),
            Position = UDim2.new(0.5, 0, 0.5, 3),
            BackgroundTransparency = 0.8
        }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        
        -- Fade out and return glow to pool
        if glowFrame and glowFrame.Parent then
            self._utilities.Tween(glowFrame, {
                ImageTransparency = 1,
                Size = UDim2.new(1, 12, 1, 12)
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            
            -- Return to pool after animation
            task.delay(0.2, function()
                if glowFrame and glowFrame.Parent then
                    self.GlowEffectPool:ReturnEffect(glowFrame)
                    glowFrame = nil
                    card:SetAttribute("ActiveGlowEffect", nil)
                end
            end)
        end
    end))
    
    return card
end

function InventoryUI:UpdatePetCard(card: Frame, petInstance: PetInstance, petData: table)
    -- Update name
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.petId)
    
    -- Update attributes
    card:SetAttribute("PetName", petData.name or petData.displayName or "Unknown")
    card:SetAttribute("PetNickname", petInstance.nickname or "")
    card:SetAttribute("Rarity", petData.rarity or 1)
    card:SetAttribute("Equipped", petInstance.equipped or false)
    card:SetAttribute("Locked", petInstance.locked or false)
    
    -- Update image
    local petImage = card:FindFirstChild("PetImage", true)
    if petImage then
        petImage.Image = petData.imageId or ""
    end
    
    -- Update level
    local levelLabel = card:FindFirstChild("LevelBadge"):FindFirstChildOfClass("TextLabel")
    if levelLabel then
        levelLabel.Text = "Lv." .. tostring(petInstance.level or 1)
    end
    
    -- Update name
    local nameLabel = card:FindFirstChildOfClass("TextLabel")
    if nameLabel and nameLabel.Parent == card then
        nameLabel.Text = petInstance.nickname or petData.name or petData.displayName or "Unknown"
    end
    
    -- Update rarity border
    local border = card:FindFirstChild("RarityBorder")
    if border then
        border.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    end
    
    -- Update equipped indicator with smooth animation
    local equippedIndicator = card:FindFirstChild("EquippedIndicator")
    if petInstance.equipped and not equippedIndicator then
        -- Add equipped indicator with animation
        if self._equipAnimations then
            self._equipAnimations:UpdateEquippedIndicator(card, true, false)
        else
            -- Fallback to instant
            equippedIndicator = Instance.new("ImageLabel")
            equippedIndicator.Name = "EquippedIndicator"
            equippedIndicator.Size = UDim2.new(0, 24, 0, 24)
            equippedIndicator.Position = UDim2.new(1, -26, 0, 2)
            equippedIndicator.BackgroundTransparency = 1
            equippedIndicator.Image = "rbxassetid://7072717697"
            equippedIndicator.ImageColor3 = self._config.COLORS.Success
            equippedIndicator.Parent = card
        end
    elseif not petInstance.equipped and equippedIndicator then
        if self._equipAnimations then
            self._equipAnimations:UpdateEquippedIndicator(card, false, false)
        else
            equippedIndicator:Destroy()
        end
    end
    
    -- Update lock indicator
    local lockIndicator = card:FindFirstChild("LockIndicator")
    if petInstance.locked and not lockIndicator then
        -- Add lock indicator
        lockIndicator = Instance.new("ImageLabel")
        lockIndicator.Name = "LockIndicator"
        lockIndicator.Size = UDim2.new(0, 20, 0, 20)
        lockIndicator.Position = UDim2.new(1, -24, 1, -24)
        lockIndicator.BackgroundTransparency = 1
        lockIndicator.Image = "rbxassetid://7072718266"
        lockIndicator.ImageColor3 = self._config.COLORS.Warning
        lockIndicator.Parent = card
    elseif not petInstance.locked and lockIndicator then
        lockIndicator:Destroy()
    end
end

-- ========================================
-- PREMIUM VFX SYSTEM
-- ========================================

-- VFX Performance settings
local VFX_SETTINGS = {
    MAX_PARTICLES_PER_CARD = 10,
    MAX_VFX_PER_SCREEN = 20,
    VFX_UPDATE_RATE = 1/60, -- 60 FPS
    VFX_DISTANCE_CULLING = true,
    VFX_QUALITY_LEVELS = {
        LOW = {particles = 5, updateRate = 1/30},
        MEDIUM = {particles = 10, updateRate = 1/45},
        HIGH = {particles = 15, updateRate = 1/60}
    }
}

function InventoryUI:InitializeVFXSystem()
    -- Track active VFX for performance management
    self.ActiveVFX = self.ActiveVFX or {}
    self.VFXCount = 0
    self.VFXQuality = "HIGH"
    
    -- Monitor performance and adjust quality
    task.spawn(function()
        while self.Frame and self.Frame.Parent do
            local fps = 1 / game:GetService("RunService").Heartbeat:Wait()
            
            -- Auto-adjust quality based on FPS
            if fps < 30 and self.VFXQuality ~= "LOW" then
                self.VFXQuality = "LOW"
                self:UpdateAllVFXQuality()
            elseif fps > 45 and fps < 55 and self.VFXQuality ~= "MEDIUM" then
                self.VFXQuality = "MEDIUM"
                self:UpdateAllVFXQuality()
            elseif fps > 55 and self.VFXQuality ~= "HIGH" then
                self.VFXQuality = "HIGH"
                self:UpdateAllVFXQuality()
            end
            
            task.wait(1) -- Check every second
        end
    end)
end

function InventoryUI:ApplyPremiumVFX(card: Frame, petInstance: PetInstance, petData: table)
    local imageContainer = card:FindFirstChild("ImageContainer")
    if not imageContainer then return end
    
    -- Safety check for nil petData
    if not petData then return end
    
    -- Skip VFX during scrolling to prevent lag
    if self.IsScrolling then return end
    
    -- Clean up existing VFX
    self:CleanupVFX(card)
    
    -- Apply variant-based VFX
    if petInstance and petInstance.variant then
        self:ApplyVariantVFX(card, petInstance.variant)
    end
    
    -- Apply rarity-based VFX
    local rarity = petData.rarity or 1
    if rarity >= 4 then -- Epic and above
        self:ApplyRarityVFX(card, rarity)
    end
end

function InventoryUI:RefreshVisibleVFX()
    -- Apply VFX to all visible cards after scrolling stops
    if not self.PetGrid then
        warn("[InventoryUI] RefreshVisibleVFX: PetGrid is nil")
        return
    end
    
    for _, child in ipairs(self.PetGrid:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^PetCard_") then
            local petInstance = child:GetAttribute("PetInstance")
            local petData = child:GetAttribute("PetData")
            if petInstance and petData then
                self:ApplyPremiumVFX(child, petInstance, petData)
            end
        end
    end
end

function InventoryUI:CleanupVFX(card: Frame)
    -- Clean up any existing VFX to prevent memory leaks
    local vfxToClean = {"RainbowShimmer", "ParticleEmitter", "GoldenAura", "ShinySparkles", "NebulaEffect"}
    
    for _, vfxName in ipairs(vfxToClean) do
        local vfx = card:FindFirstChild(vfxName, true)
        if vfx then
            vfx:Destroy()
        end
    end
end

function InventoryUI:ApplyVariantVFX(card: Frame, variant: string)
    local imageContainer = card:FindFirstChild("ImageContainer")
    if not imageContainer then return end
    
    if variant == "rainbow" then
        self:CreateRainbowShimmerVFX(imageContainer)
    elseif variant == "shiny" then
        self:CreateShinySparkleVFX(imageContainer)
    elseif variant == "golden" then
        self:CreateGoldenAuraVFX(imageContainer)
    end
end

function InventoryUI:CreateRainbowShimmerVFX(container: Frame)
    -- PREMIUM Rainbow Shimmer Effect
    local shimmerContainer = Instance.new("Frame")
    shimmerContainer.Name = "RainbowShimmer"
    shimmerContainer.Size = UDim2.new(1.1, 0, 1.1, 0)
    shimmerContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    shimmerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    shimmerContainer.BackgroundTransparency = 1
    shimmerContainer.ZIndex = 10
    shimmerContainer.Parent = container
    
    -- Create multiple shimmer layers for depth
    for i = 1, 3 do
        local shimmer = Instance.new("ImageLabel")
        shimmer.Name = "ShimmerLayer" .. i
        shimmer.Size = UDim2.new(2, 0, 2, 0)
        shimmer.Position = UDim2.new(-0.5 + (i-1) * 0.1, 0, -0.5, 0)
        shimmer.BackgroundTransparency = 1
        shimmer.Image = "rbxasset://textures/ui/LuaApp/graphic/shimmer_wide.png"
        shimmer.ImageTransparency = 0.9 - (i * 0.1)
        shimmer.ScaleType = Enum.ScaleType.Tile
        shimmer.TileSize = UDim2.new(0.3, 0, 0.3, 0)
        shimmer.Parent = shimmerContainer
        
        -- Animated rainbow gradient
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
        })
        gradient.Rotation = i * 30
        gradient.Parent = shimmer
        
        -- Animate the shimmer movement and rotation
        task.spawn(function()
            while shimmer.Parent do
                -- Move shimmer across
                self._utilities.Tween(shimmer, {
                    Position = UDim2.new(0.5 + (i-1) * 0.1, 0, -0.5, 0)
                }, TweenInfo.new(3 + i * 0.5, Enum.EasingStyle.Linear))
                
                -- Rotate gradient
                self._utilities.Tween(gradient, {
                    Rotation = gradient.Rotation + 360
                }, TweenInfo.new(4 + i * 0.5, Enum.EasingStyle.Linear))
                
                task.wait(3 + i * 0.5)
                shimmer.Position = UDim2.new(-0.5 + (i-1) * 0.1, 0, -0.5, 0)
            end
        end)
    end
    
    -- Add sparkle particles
    self:AddSparkleParticles(shimmerContainer, {
        color = ColorSequence.new(Color3.new(1, 1, 1)),
        rate = 3,
        lifetime = 1.5,
        speed = 20,
        spread = 45
    })
end

function InventoryUI:CreateShinySparkleVFX(container: Frame)
    -- Diamond Sparkle Burst Effect
    local sparkleContainer = Instance.new("Frame")
    sparkleContainer.Name = "ShinySparkles"
    sparkleContainer.Size = UDim2.new(1, 0, 1, 0)
    sparkleContainer.BackgroundTransparency = 1
    sparkleContainer.Parent = container
    
    -- Create sparkle burst pattern
    task.spawn(function()
        while sparkleContainer.Parent do
            for i = 1, 5 do
                task.wait(0.1)
                local sparkle = Instance.new("ImageLabel")
                sparkle.Size = UDim2.new(0, 0, 0, 0)
                sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
                sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
                sparkle.BackgroundTransparency = 1
                sparkle.Image = "rbxasset://textures/particles/sparkles_main.dds"
                sparkle.ImageColor3 = Color3.fromHSV(0, 0, 1) -- Pure white
                sparkle.ZIndex = 15
                sparkle.Parent = sparkleContainer
                
                -- Random rotation
                sparkle.Rotation = math.random(0, 360)
                
                -- Burst animation
                local size = math.random(15, 25)
                self._utilities.Tween(sparkle, {
                    Size = UDim2.new(0, size, 0, size),
                    ImageTransparency = 0
                }, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
                
                task.wait(0.2)
                
                -- Fade out with rotation
                self._utilities.Tween(sparkle, {
                    Size = UDim2.new(0, size * 1.5, 0, size * 1.5),
                    ImageTransparency = 1,
                    Rotation = sparkle.Rotation + math.random(90, 180)
                }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
                
                game:GetService("Debris"):AddItem(sparkle, 0.7)
            end
            task.wait(math.random() * 0.5 + 0.5)
        end
    end)
end

function InventoryUI:CreateGoldenAuraVFX(container: Frame)
    -- Golden Pulsing Aura
    local auraContainer = Instance.new("Frame")
    auraContainer.Name = "GoldenAura"
    auraContainer.Size = UDim2.new(1, 0, 1, 0)
    auraContainer.BackgroundTransparency = 1
    auraContainer.Parent = container
    
    -- Create multiple aura layers
    for i = 1, 2 do
        local aura = Instance.new("ImageLabel")
        aura.Name = "AuraLayer" .. i
        aura.Size = UDim2.new(1.3 + i * 0.1, 0, 1.3 + i * 0.1, 0)
        aura.Position = UDim2.new(0.5, 0, 0.5, 0)
        aura.AnchorPoint = Vector2.new(0.5, 0.5)
        aura.BackgroundTransparency = 1
        aura.Image = "rbxassetid://5028857084" -- Glow image
        aura.ImageColor3 = Color3.fromRGB(255, 215, 0)
        aura.ImageTransparency = 0.7 + i * 0.1
        aura.ZIndex = -i
        aura.Parent = auraContainer
        
        -- Pulse animation
        task.spawn(function()
            while aura.Parent do
                self._utilities.Tween(aura, {
                    Size = UDim2.new(1.4 + i * 0.1, 0, 1.4 + i * 0.1, 0),
                    ImageTransparency = 0.5 + i * 0.1
                }, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                
                task.wait(1.5)
                
                self._utilities.Tween(aura, {
                    Size = UDim2.new(1.3 + i * 0.1, 0, 1.3 + i * 0.1, 0),
                    ImageTransparency = 0.7 + i * 0.1
                }, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                
                task.wait(1.5)
            end
        end)
    end
end

function InventoryUI:ApplyRarityVFX(card: Frame, rarity: number)
    local imageContainer = card:FindFirstChild("ImageContainer")
    if not imageContainer then return end
    
    if rarity >= 4 and rarity < 5 then
        -- Epic: Rising particles
        self:CreateRisingParticlesVFX(imageContainer, {
            color = Color3.fromRGB(148, 0, 211), -- Purple
            rate = 2,
            size = 4
        })
    elseif rarity >= 5 and rarity < 6 then
        -- Legendary: Golden light rays
        self:CreateLightRaysVFX(imageContainer, Color3.fromRGB(255, 215, 0))
    elseif rarity >= 6 then
        -- Mythic: Cosmic nebula
        self:CreateCosmicNebulaVFX(imageContainer)
    end
end

function InventoryUI:CreateRisingParticlesVFX(container: Frame, config: table)
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleEmitter"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ClipsDescendants = true
    particleContainer.Parent = container
    
    task.spawn(function()
        while particleContainer.Parent do
            for i = 1, config.rate or 2 do
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, config.size or 4, 0, config.size or 4)
                particle.Position = UDim2.new(math.random(), 0, 1.1, 0)
                particle.BackgroundColor3 = config.color or Color3.new(1, 1, 1)
                particle.BorderSizePixel = 0
                particle.Parent = particleContainer
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0.5, 0)
                corner.Parent = particle
                
                -- Add glow
                local glow = Instance.new("ImageLabel")
                glow.Size = UDim2.new(3, 0, 3, 0)
                glow.Position = UDim2.new(0.5, 0, 0.5, 0)
                glow.AnchorPoint = Vector2.new(0.5, 0.5)
                glow.BackgroundTransparency = 1
                glow.Image = "rbxassetid://5028857084"
                glow.ImageColor3 = config.color or Color3.new(1, 1, 1)
                glow.ImageTransparency = 0.7
                glow.Parent = particle
                
                -- Float up with wobble
                local wobbleAmount = math.random() * 0.2 - 0.1
                self._utilities.Tween(particle, {
                    Position = UDim2.new(particle.Position.X.Scale + wobbleAmount, 0, -0.1, 0),
                    Size = UDim2.new(0, 0, 0, 0)
                }, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                
                self._utilities.Tween(glow, {
                    ImageTransparency = 1
                }, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                
                game:GetService("Debris"):AddItem(particle, 3)
            end
            task.wait(0.5)
        end
    end)
end

function InventoryUI:CreateLightRaysVFX(container: Frame, color: Color3)
    -- Legendary Light Rays Effect
    local raysContainer = Instance.new("Frame")
    raysContainer.Name = "LightRays"
    raysContainer.Size = UDim2.new(1, 0, 1, 0)
    raysContainer.BackgroundTransparency = 1
    raysContainer.ClipsDescendants = false
    raysContainer.Parent = container
    
    -- Create rotating light rays
    for i = 1, 6 do
        local ray = Instance.new("Frame")
        ray.Name = "Ray" .. i
        ray.Size = UDim2.new(0, 2, 1, 0)
        ray.Position = UDim2.new(0.5, 0, 0.5, 0)
        ray.AnchorPoint = Vector2.new(0.5, 0.5)
        ray.BackgroundColor3 = color
        ray.BorderSizePixel = 0
        ray.Rotation = i * 60
        ray.Parent = raysContainer
        
        -- Add gradient for fade effect
        local gradient = Instance.new("UIGradient")
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.7),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(0.7, 0.7),
            NumberSequenceKeypoint.new(1, 1)
        })
        gradient.Rotation = 90
        gradient.Parent = ray
        
        -- Animate the ray
        task.spawn(function()
            while ray.Parent do
                -- Pulse animation
                self._utilities.Tween(ray, {
                    Size = UDim2.new(0, 3, 1.2, 0),
                    BackgroundTransparency = 0.3
                }, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                
                task.wait(2)
                
                self._utilities.Tween(ray, {
                    Size = UDim2.new(0, 2, 1, 0),
                    BackgroundTransparency = 0.5
                }, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                
                task.wait(2)
            end
        end)
    end
    
    -- Rotate the entire container slowly
    task.spawn(function()
        while raysContainer.Parent do
            self._utilities.Tween(raysContainer, {
                Rotation = raysContainer.Rotation + 360
            }, TweenInfo.new(20, Enum.EasingStyle.Linear))
            task.wait(20)
        end
    end)
end

function InventoryUI:CreateCosmicNebulaVFX(container: Frame)
    -- Mythic Cosmic Nebula Effect
    local nebulaContainer = Instance.new("Frame")
    nebulaContainer.Name = "NebulaEffect"
    nebulaContainer.Size = UDim2.new(1.5, 0, 1.5, 0)
    nebulaContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    nebulaContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    nebulaContainer.BackgroundTransparency = 1
    nebulaContainer.ZIndex = -1
    nebulaContainer.Parent = container
    
    -- Create swirling nebula layers
    for i = 1, 3 do
        local nebula = Instance.new("ImageLabel")
        nebula.Name = "NebulaLayer" .. i
        nebula.Size = UDim2.new(1.2 + i * 0.1, 0, 1.2 + i * 0.1, 0)
        nebula.Position = UDim2.new(0.5, 0, 0.5, 0)
        nebula.AnchorPoint = Vector2.new(0.5, 0.5)
        nebula.BackgroundTransparency = 1
        nebula.Image = "rbxasset://textures/particles/smoke_main.dds"
        nebula.ImageTransparency = 0.7 + i * 0.05
        nebula.Parent = nebulaContainer
        
        -- Create cosmic gradient
        local colors = {
            Color3.fromRGB(138, 43, 226), -- Blue violet
            Color3.fromRGB(75, 0, 130),   -- Indigo
            Color3.fromRGB(238, 130, 238), -- Violet
            Color3.fromRGB(147, 112, 219), -- Medium purple
        }
        
        nebula.ImageColor3 = colors[math.random(1, #colors)]
        
        -- Swirl animation
        task.spawn(function()
            local rotationSpeed = 30 + i * 10
            local scaleVariation = 0.1 + i * 0.05
            
            while nebula.Parent do
                -- Rotate
                self._utilities.Tween(nebula, {
                    Rotation = nebula.Rotation + (i % 2 == 0 and 360 or -360)
                }, TweenInfo.new(rotationSpeed, Enum.EasingStyle.Linear))
                
                -- Scale breathing
                self._utilities.Tween(nebula, {
                    Size = UDim2.new(1.2 + i * 0.1 + scaleVariation, 0, 1.2 + i * 0.1 + scaleVariation, 0)
                }, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                
                task.wait(3)
                
                self._utilities.Tween(nebula, {
                    Size = UDim2.new(1.2 + i * 0.1, 0, 1.2 + i * 0.1, 0)
                }, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                
                task.wait(rotationSpeed - 3)
            end
        end)
    end
    
    -- Add cosmic particles
    self:AddSparkleParticles(nebulaContainer, {
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
        }),
        rate = 1,
        lifetime = 4,
        speed = 10,
        spread = 360
    })
end

function InventoryUI:AddSparkleParticles(container: Frame, config: table)
    -- Helper function to add sparkle particles
    task.spawn(function()
        while container.Parent do
            for i = 1, config.rate or 1 do
                local sparkle = Instance.new("ImageLabel")
                sparkle.Size = UDim2.new(0, 0, 0, 0)
                sparkle.Position = UDim2.new(0.5, 0, 0.5, 0)
                sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
                sparkle.BackgroundTransparency = 1
                sparkle.Image = "rbxasset://textures/particles/sparkles_main.dds"
                sparkle.ZIndex = 20
                sparkle.Parent = container
                
                -- Apply color
                if type(config.color) == "userdata" and config.color:IsA("ColorSequence") then
                    sparkle.ImageColor3 = config.color.Keypoints[1].Value
                else
                    sparkle.ImageColor3 = config.color or Color3.new(1, 1, 1)
                end
                
                -- Random spawn position within container
                local angle = math.rad(math.random(0, 360))
                local distance = math.random(0, 30)
                sparkle.Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance)
                
                -- Animate
                local endSize = math.random(8, 12)
                self._utilities.Tween(sparkle, {
                    Size = UDim2.new(0, endSize, 0, endSize),
                    ImageTransparency = 0,
                    Rotation = math.random(0, 360)
                }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
                
                task.wait(0.3)
                
                -- Fade out
                self._utilities.Tween(sparkle, {
                    ImageTransparency = 1,
                    Size = UDim2.new(0, endSize * 0.5, 0, endSize * 0.5),
                    Position = UDim2.new(
                        sparkle.Position.X.Scale,
                        sparkle.Position.X.Offset + math.random(-20, 20),
                        sparkle.Position.Y.Scale,
                        sparkle.Position.Y.Offset - math.random(10, 30)
                    )
                }, TweenInfo.new(config.lifetime or 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                
                game:GetService("Debris"):AddItem(sparkle, config.lifetime or 1 + 0.3)
            end
            task.wait(1 / (config.rate or 1))
        end
    end)
end

function InventoryUI:ApplyVariantEffect(card: Frame, variant: string)
    -- Redirect to new VFX system
    self:ApplyVariantVFX(card, variant)
end

-- ========================================
-- VIRTUAL SCROLLING
-- ========================================

function InventoryUI:GetPooledCard()
    -- Try to get a card from the pool
    if #self.VisibleCardPool > 0 then
        local card = table.remove(self.VisibleCardPool)
        card.Visible = true
        return card
    end
    
    -- No cards in pool, create a new one (without data)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 120, 0, self.CardHeight)
    card.BackgroundColor3 = self._config.COLORS.White or Color3.new(1, 1, 1)
    card.BorderSizePixel = 0
    
    self._utilities.CreateCorner(card, 8)
    
    -- Basic structure that will be reused
    local border = Instance.new("Frame")
    border.Name = "RarityBorder"
    border.Size = UDim2.new(1, 0, 0, 4)
    border.Position = UDim2.new(0, 0, 1, -4)
    border.BorderSizePixel = 0
    border.Parent = card
    
    local imageContainer = Instance.new("Frame")
    imageContainer.Name = "ImageContainer"
    imageContainer.Size = UDim2.new(1, -10, 1, -40)
    imageContainer.Position = UDim2.new(0, 5, 0, 5)
    imageContainer.BackgroundTransparency = 1
    imageContainer.Parent = card
    
    local petImage = Instance.new("ImageLabel")
    petImage.Name = "PetImage"
    petImage.Size = UDim2.new(1, 0, 1, 0)
    petImage.BackgroundTransparency = 1
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = imageContainer
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 1, -30)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = self._config.FONTS.Primary
    nameLabel.TextScaled = true
    nameLabel.TextColor3 = self._config.COLORS.Text
    nameLabel.Parent = card
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0, 40, 0, 20)
    levelLabel.Position = UDim2.new(0, 5, 0, 5)
    levelLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    levelLabel.BackgroundTransparency = 0.3
    levelLabel.Font = self._config.FONTS.Primary
    levelLabel.TextScaled = true
    levelLabel.TextColor3 = Color3.new(1, 1, 1)
    levelLabel.Parent = card
    
    -- No stats display on cards - keeping them simple and clean
    self._utilities.CreateCorner(levelLabel, 4)
    
    local button = Instance.new("TextButton")
    button.Name = "ClickButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 10
    button.Parent = card
    
    return card
end

function InventoryUI:ReturnCardToPool(card: Frame)
    -- Clear the card data
    card.Visible = false
    card.Parent = nil
    
    -- Reset attributes
    card:SetAttribute("PetName", nil)
    card:SetAttribute("PetNickname", nil)
    card:SetAttribute("Rarity", nil)
    card:SetAttribute("Equipped", nil)
    card:SetAttribute("Locked", nil)
    
    -- Clean up janitor from our table
    if self.CardJanitors then
        local cardId = tostring(card)
        if self.CardJanitors[cardId] then
            self.CardJanitors[cardId]:Destroy()
            self.CardJanitors[cardId] = nil
        end
    end
    
    -- Add to pool for reuse
    table.insert(self.VisibleCardPool, card)
end

function InventoryUI:UpdateCardWithData(card: Frame, petInstance: PetInstance, petData: table)
    -- Update the card with new pet data
    card.Name = "PetCard_" .. tostring(petInstance.uniqueId or petInstance.petId or "unknown")
    
    -- Update attributes
    card:SetAttribute("PetName", petData.name or petData.displayName or "Unknown")
    card:SetAttribute("PetNickname", petInstance.nickname or "")
    card:SetAttribute("Rarity", petData.rarity or 1)
    card:SetAttribute("Equipped", petInstance.equipped or false)
    card:SetAttribute("Locked", petInstance.locked or false)
    
    -- Update visuals
    local border = card:FindFirstChild("RarityBorder")
    if border then
        border.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    end
    
    local petImage = card:FindFirstChild("ImageContainer"):FindFirstChild("PetImage")
    if petImage then
        petImage.Image = petData.imageId or ""
    end
    
    local nameLabel = card:FindFirstChild("NameLabel")
    if nameLabel then
        nameLabel.Text = petInstance.nickname or petData.displayName or petData.name or "Unknown"
    end
    
    local levelLabel = card:FindFirstChild("LevelLabel")
    if levelLabel then
        levelLabel.Text = "Lv." .. tostring(petInstance.level or 1)
    end
    
    -- No stats update needed - cards don't display stats anymore
    
    -- Update click handler
    local button = card:FindFirstChild("ClickButton")
    if button then
        -- Store janitor in a table to avoid direct property access
        if not self.CardJanitors then
            self.CardJanitors = {}
        end
        
        -- Clean up old janitor if it exists
        local cardId = tostring(card)
        if self.CardJanitors[cardId] then
            self.CardJanitors[cardId]:Destroy()
        end
        
        -- Create a fresh janitor for this card
        self.CardJanitors[cardId] = Janitor.new()
        
        -- Add the click connection
        self.CardJanitors[cardId]:Add(button.MouseButton1Click:Connect(function()
            if self._eventBus then
                self._eventBus:Fire("ShowPetDetails", {
                    petInstance = petInstance,
                    petData = petData
                })
            end
        end))
    end
    
    -- Add equipped/locked indicators
    self:UpdateCardIndicators(card, petInstance)
end

function InventoryUI:UpdateCardIndicators(card: Frame, petInstance: PetInstance)
    -- Remove old indicators
    local oldEquipped = card:FindFirstChild("EquippedIndicator")
    if oldEquipped then oldEquipped:Destroy() end
    
    local oldLocked = card:FindFirstChild("LockedIndicator")
    if oldLocked then oldLocked:Destroy() end
    
    local oldVariant = card:FindFirstChild("VariantBadge")
    if oldVariant then oldVariant:Destroy() end
    
    -- Add equipped indicator
    if petInstance.equipped then
        local equipped = Instance.new("ImageLabel")
        equipped.Name = "EquippedIndicator"
        equipped.Size = UDim2.new(0, 30, 0, 30)
        equipped.Position = UDim2.new(1, -35, 0, 5)
        equipped.BackgroundTransparency = 1
        equipped.Image = "rbxassetid://7734053426" -- Checkmark icon
        equipped.ImageColor3 = self._config.COLORS.Success
        equipped.Parent = card
    end
    
    -- Add locked indicator
    if petInstance.locked then
        local locked = Instance.new("ImageLabel")
        locked.Name = "LockedIndicator"
        locked.Size = UDim2.new(0, 25, 0, 25)
        locked.Position = UDim2.new(1, -30, 1, -30)
        locked.BackgroundTransparency = 1
        locked.Image = "rbxassetid://7734021047" -- Lock icon
        locked.ImageColor3 = self._config.COLORS.Warning
        locked.Parent = card
    end
    
    -- Add variant badge
    if petInstance.variant and petInstance.variant ~= "normal" then
        local variantBadge = Instance.new("Frame")
        variantBadge.Name = "VariantBadge"
        variantBadge.Size = UDim2.new(0, 30, 0, 30)
        variantBadge.Position = UDim2.new(1, -35, 1, -35)
        variantBadge.BackgroundColor3 = self:GetVariantColor(petInstance.variant)
        variantBadge.ZIndex = card.ZIndex + 3
        variantBadge.Parent = card
        
        self._utilities.CreateCorner(variantBadge, 15)
        
        local variantIcon = Instance.new("ImageLabel")
        variantIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
        variantIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        variantIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        variantIcon.BackgroundTransparency = 1
        variantIcon.Image = self:GetVariantIcon(petInstance.variant)
        variantIcon.ImageColor3 = self._config.COLORS.White
        variantIcon.ScaleType = Enum.ScaleType.Fit
        variantIcon.Parent = variantBadge
    end
    
    -- DISABLED VFX TO FIX LAG
    -- self:ApplyPremiumVFX(card, petInstance, petData)
end

function InventoryUI:GetVariantColor(variant: string): Color3
    if not variant then return self._config.COLORS.Dark end
    
    local variantColors = {
        normal = self._config.COLORS.Dark,
        shiny = Color3.fromRGB(255, 255, 150),  -- Light yellow
        golden = Color3.fromRGB(255, 215, 0),    -- Gold
        rainbow = Color3.fromRGB(255, 100, 255), -- Pink/Purple
        dark = Color3.fromRGB(50, 0, 50),        -- Dark purple
        neon = Color3.fromRGB(0, 255, 255),      -- Cyan
        crystal = Color3.fromRGB(150, 200, 255), -- Light blue
        shadow = Color3.fromRGB(30, 30, 30),     -- Very dark
    }
    
    return variantColors[variant:lower()] or self._config.COLORS.Warning
end

function InventoryUI:GetVariantIcon(variant: string): string
    if not variant then return "" end
    
    -- Use specific Roblox asset icons for each variant type (no emojis!)
    local variantIcons = {
        shiny = "rbxassetid://7734021494",     -- Star icon
        golden = "rbxassetid://7734053495",    -- Crown icon  
        rainbow = "rbxassetid://7734053039",   -- Rainbow icon
        dark = "rbxassetid://7734021827",      -- Moon icon
        neon = "rbxassetid://7734022107",      -- Lightning icon
        crystal = "rbxassetid://7734010405",   -- Diamond icon
        shadow = "rbxassetid://7734021769",    -- Ghost icon
    }
    
    return variantIcons[variant:lower()] or "rbxassetid://7733960981" -- Default special icon
end

function InventoryUI:SetupVirtualScrolling()
    if not self.PetGrid then return end
    
    -- Disconnect old scroll connection
    if self.ScrollConnection then
        self.ScrollConnection:Disconnect()
        self.ScrollConnection = nil
    end
    
    -- Calculate visible area
    local visibleCards = self.ColumnsPerRow * self.VisibleRows
    
    -- Pre-create card pool
    for i = 1, visibleCards + self.ColumnsPerRow do  -- Extra row for smooth scrolling
        local card = self:GetPooledCard()
        table.insert(self.VisibleCardPool, card)
    end
    
    -- Set up scroll listener
    self.ScrollConnection = self._janitor:Add(self.PetGrid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self.IsScrolling = true
        self:OnVirtualScroll()
        
        -- Clear scrolling flag after a delay
        if self.ScrollDebounce then
            task.cancel(self.ScrollDebounce)
        end
        self.ScrollDebounce = task.delay(0.2, function()
            self.IsScrolling = false
            -- Refresh VFX after scrolling stops
            self:RefreshVisibleVFX()
        end)
    end))
end

function InventoryUI:OnVirtualScroll()
    if not self.VirtualScrollEnabled or not self.PetGrid then return end
    
    local scrollY = self.PetGrid.CanvasPosition.Y
    local rowHeight = self.CardHeight + self.CardPadding
    
    -- Calculate which row is at the top of the visible area
    local topRow = math.floor(scrollY / rowHeight)
    local bottomRow = topRow + self.VisibleRows + 1  -- Extra row for buffer
    
    -- Calculate which pets should be visible
    local startIndex = topRow * self.ColumnsPerRow + 1
    local endIndex = bottomRow * self.ColumnsPerRow
    
    -- Use the stored visible pets
    local pets = self.VisiblePets or {}
    
    -- Remove cards that are no longer visible
    for index, card in pairs(self.ActiveCards) do
        if index < startIndex or index > endIndex then
            self:ReturnCardToPool(card)
            self.ActiveCards[index] = nil
        end
    end
    
    -- Add cards for newly visible pets
    for i = startIndex, math.min(endIndex, #pets) do
        if not self.ActiveCards[i] then
            local petInfo = pets[i]
            if petInfo then
                local card = self:GetPooledCard()
                if card then
                    -- Calculate position
                    local row = math.floor((i - 1) / self.ColumnsPerRow)
                    local col = (i - 1) % self.ColumnsPerRow
                    
                    card.Position = UDim2.new(0, col * (self.CardHeight + self.CardPadding), 
                                            0, row * (self.CardHeight + self.CardPadding))
                    card.Parent = self.PetGrid
                    
                    -- Update with pet data
                    self:UpdateCardWithData(card, petInfo.pet, petInfo.data)
                    
                    self.ActiveCards[i] = card
                end
            end
        end
    end
end

-- ========================================
-- INVENTORY REFRESH
-- ========================================

function InventoryUI:RefreshInventory()
    -- 1. CANCEL THE PREVIOUS ATTEMPT
    -- If a refresh is already in progress, cancel it immediately.
    -- Only the newest request should survive.
    if self.CurrentRefreshThread then
        task.cancel(self.CurrentRefreshThread)
        self.CurrentRefreshThread = nil
    end
    
    -- 2. CREATE A NEW, ISOLATED THREAD FOR THIS REFRESH
    self.CurrentRefreshThread = task.spawn(function()
        -- Prevent this new thread from being cancelled immediately
        task.wait()
        
        if not self.Frame or not self.Frame.Visible then return end
        
        -- Find PetGrid if needed
        if not self.PetGrid or not self.PetGrid.Parent then
            -- Try to find it in the Pets tab
            local petsTab = self.TabFrames and self.TabFrames["Pets"]
            if petsTab then
                -- Look for PetGrid in container first, then directly
                local container = petsTab:FindFirstChild("PetGridContainer")
                if container then
                    self.PetGrid = container:FindFirstChild("PetGridScrollFrame")
                else
                    self.PetGrid = petsTab:FindFirstChild("PetGridScrollFrame")
                end
            end
            
            if not self.PetGrid then
                warn("[InventoryUI] PetGrid not found, cannot refresh")
                return
            end
        end
        
        -- 3. CLEAN THE UI AND SHOW LOADING STATE
        -- This now happens safely inside the new thread.
        self:ClearGrid()
        
        local loadingLabel = self._uiFactory:CreateLabel(self.PetGrid, {
            name = "LoadingLabel",
            text = "Loading pets...",
            size = UDim2.new(1, 0, 0, 50),
            position = UDim2.new(0, 0, 0.5, -25),
            textScaled = true,
            backgroundColor = Color3.new(0, 0, 0),
            backgroundTransparency = 1,
            textColor = self._config.COLORS.TextSecondary,
            font = self._config.FONTS.Primary
        })
        
        -- Give the "Loading..." message a moment to appear
        task.wait(0.1)
        
        -- 4. GET DATA AND POPULATE
        local pets = self:GetFilteredAndSortedPets()
        
        -- The grid is guaranteed to be clean, so we just remove the loading label
        if loadingLabel and loadingLabel.Parent then
            loadingLabel:Destroy()
        end
        
        -- Update the stats display (like equipped count)
        self:UpdateStats(pets)
        
        -- Display the results
        if #pets == 0 then
            self:ShowEmptyState() -- This will now only be called once if needed
        else
            self:DisplayPets(pets)
        end
        
        -- Update refresh tracking
        self.LastRefreshTime = tick()
    end)
end

function InventoryUI:GetFilteredAndSortedPets(): {{pet: PetInstance, data: table}}
    -- Single source of truth: playerData.pets
    local pets = nil
    
    if self._dataCache then
        local playerData = self._dataCache:Get("playerData")
        
        -- Check for nested data structure (result.data.pets)
        if playerData and playerData.data and playerData.data.pets then
            pets = playerData.data.pets
        -- Fallback to direct pets field
        elseif playerData and playerData.pets then
            pets = playerData.pets
        end
    end
    
    -- Fallback to state manager if needed
    if not pets and self._stateManager then
        -- StateManager might use Get instead of GetState
        local state = nil
        if self._stateManager.GetState then
            state = self._stateManager:GetState()
        elseif self._stateManager.Get then
            state = self._stateManager:Get()
        elseif self._stateManager.GetData then
            state = self._stateManager:GetData()
        end
        
        -- Check nested structures in state
        if state and state.playerData and state.playerData.data and state.playerData.data.pets then
            pets = state.playerData.data.pets
        elseif state and state.playerData and state.playerData.pets then
            pets = state.playerData.pets
        elseif state and state.data and state.data.pets then
            pets = state.data.pets
        elseif state and state.pets then
            pets = state.pets
        end
    end
    
    -- Last resort: Check if we have the full data structure
    if not pets and self._dataCache then
        local fullData = self._dataCache:Get()
        if fullData and type(fullData) == "table" then
            -- Check various possible paths
            if fullData.data and fullData.data.pets then
                pets = fullData.data.pets
            elseif fullData.pets then
                pets = fullData.pets
            elseif fullData.playerData and fullData.playerData.pets then
                pets = fullData.playerData.pets
            elseif fullData.playerData and fullData.playerData.data and fullData.playerData.data.pets then
                pets = fullData.playerData.data.pets
            end
        end
    end
    
    -- Debug logging
    if not pets then
        warn("[InventoryUI] No pet data found! Checking data sources:")
        warn("  - DataCache exists:", self._dataCache ~= nil)
        if self._dataCache then
            local playerData = self._dataCache:Get("playerData")
            warn("  - PlayerData exists:", playerData ~= nil)
            if playerData then
                warn("  - PlayerData.pets exists:", playerData.pets ~= nil)
                warn("  - PlayerData structure:", playerData)
            end
        end
        warn("  - StateManager exists:", self._stateManager ~= nil)
    else
        -- Count pets in dictionary
        local petCount = 0
        for _ in pairs(pets) do
            petCount = petCount + 1
        end
        print("[InventoryUI] Found pets! Count:", petCount)
        
        -- CRITICAL FIX: Validate equipped count to prevent 7/6 issue
        local playerData = self._dataCache and self._dataCache:Get("playerData")
        if playerData then
            local equippedByFlag = 0
            local correctEquippedPets = {}
            
            for id, pet in pairs(pets) do
                if pet.equipped then
                    equippedByFlag = equippedByFlag + 1
                    -- Enforce the 6 pet limit on client side
                    if equippedByFlag <= 6 then
                        table.insert(correctEquippedPets, id)
                    else
                        -- Force unequip pets beyond limit on client side
                        pet.equipped = false
                        print("[InventoryUI] WARNING: Unequipping excess pet (client-side):", id)
                    end
                end
            end
            
            -- Update the equippedPets array if needed
            if playerData.equippedPets and #playerData.equippedPets ~= #correctEquippedPets then
                print("[InventoryUI] Fixing equipped pets array. Was:", #playerData.equippedPets, "Now:", #correctEquippedPets)
                playerData.equippedPets = correctEquippedPets
            end
        end
    end
    
    if not pets then
        -- Create mock data for testing if no pets exist
        if self._config and self._config.DEBUG_MODE then
            print("[InventoryUI] DEBUG: Creating mock pet data")
            pets = {
                ["debug_pet_1"] = {
                    uniqueId = "debug_pet_1",
                    petId = "001_hello_kitty",
                    name = "Hello Kitty",
                    displayName = "Hello Kitty",
                    level = 1,
                    experience = 0,
                    power = 100,
                    speed = 50,
                    luck = 25,
                    equipped = false,
                    locked = false,
                    rarity = 3,
                    obtained = os.time()
                }
            }
        else
            return {}
        end
    end
    
    local petsArray = {}
    
    -- Convert to array format
    if type(pets) == "table" then
        for uniqueId, petData in pairs(pets) do
            if type(petData) == "table" then
                petData.uniqueId = uniqueId
                
                -- Use pet's own data as template (server already sends complete data)
                local templateData = {
                    name = petData.name or "Unknown",
                    displayName = petData.displayName or petData.name or "Unknown",
                    rarity = petData.rarity or 1
                }
                
                -- Apply filters
                local filterFunc = FILTER_DEFINITIONS[self.CurrentFilter]
                local passesFilter = true
                
                -- Debug: Log filter lookup
                if not filterFunc and self.CurrentFilter ~= "All" then
                    warn("[InventoryUI] No filter function found for:", self.CurrentFilter)
                end
                
                -- If filter function exists, use it; otherwise default to showing all
                if filterFunc then
                    passesFilter = filterFunc(petData, templateData)
                end
                
                if passesFilter then
                    -- Apply search filter
                    if self.SearchText == "" or self:MatchesSearch(petData, templateData) then
                        table.insert(petsArray, {pet = petData, data = templateData})
                    end
                end
            end
        end
    end
    
    -- Sort pets
    local sortFunc = SORT_FUNCTIONS[self.CurrentSort]
    if sortFunc then
        print("[InventoryUI] Sorting pets by:", self.CurrentSort, "Function exists:", sortFunc ~= nil)
        
        -- Debug pets before and after sorting
        if #petsArray > 0 and self.CurrentSort == "Power" then
            print("[InventoryUI] Before Power sort - First 3 pets:")
            for i = 1, math.min(3, #petsArray) do
                local pet = petsArray[i]
                print(string.format("  %d. %s (power: %s, level: %d)", 
                    i, 
                    pet.data and pet.data.name or "Unknown",
                    tostring(pet.pet.power),
                    pet.pet.level or 1))
            end
        end
        
        table.sort(petsArray, function(a, b)
            return sortFunc(a.pet, b.pet, a.data, b.data)
        end)
        
        -- Debug pets after sorting
        if #petsArray > 0 and self.CurrentSort == "Power" then
            print("[InventoryUI] After Power sort - First 3 pets:")
            for i = 1, math.min(3, #petsArray) do
                local pet = petsArray[i]
                print(string.format("  %d. %s (power: %s, level: %d)", 
                    i, 
                    pet.data and pet.data.name or "Unknown",
                    tostring(pet.pet.power),
                    pet.pet.level or 1))
            end
        end
    end
    
    return petsArray
end

function InventoryUI:MatchesSearch(petInstance: PetInstance, petData: table): boolean
    local searchLower = self.SearchText:lower()
    local petName = (petInstance.nickname or petData.name or petData.displayName or ""):lower()
    return petName:find(searchLower, 1, true) ~= nil
end

function InventoryUI:RefreshStats()
    -- Fetch fresh player data to get accurate equipped count
    print("[InventoryUI] Refreshing stats...")
    
    local playerData = self._dataCache and self._dataCache:Get("playerData")
    if not playerData or not playerData.pets then
        print("[InventoryUI] No player data available for stats refresh")
        return
    end
    
    -- Convert pets object to array
    local pets = {}
    for _, pet in pairs(playerData.pets) do
        table.insert(pets, {pet = pet})
    end
    
    self:UpdateStats(pets)
end

-- ========================================
-- REAL-TIME STATS SYSTEM
-- ========================================

function InventoryUI:QueueStatsUpdate(statType: string, value: number)
    -- Queue the update
    self._statsUpdateQueue[statType] = value
    
    -- Process queue if not already processing
    if not self._statsUpdateTimer then
        self._statsUpdateTimer = task.defer(function()
            self:ProcessStatsQueue()
            self._statsUpdateTimer = nil
        end)
    end
end

function InventoryUI:ProcessStatsQueue()
    for statType, targetValue in pairs(self._statsUpdateQueue) do
        self:AnimateStatChange(statType, targetValue)
    end
    self._statsUpdateQueue = {}
end

function InventoryUI:AnimateStatChange(statType: string, targetValue: number)
    local stats = self._realtimeStats
    
    -- Store target value
    stats.targetValues[statType] = targetValue
    
    -- Get current displayed value
    local currentValue = stats.animatingValues[statType] or stats[statType] or 0
    
    -- Skip if already at target
    if math.abs(currentValue - targetValue) < 0.01 then
        return
    end
    
    -- Cancel existing animation
    if stats.updateThread and stats.updateThread[statType] then
        task.cancel(stats.updateThread[statType])
    end
    
    -- Initialize animation tracking
    stats.updateThread = stats.updateThread or {}
    stats.animatingValues[statType] = currentValue
    
    -- Smooth animation
    local startTime = tick()
    local duration = 0.3
    local startValue = currentValue
    
    stats.updateThread[statType] = task.spawn(function()
        while true do
            local elapsed = tick() - startTime
            local progress = math.min(elapsed / duration, 1)
            
            -- Smooth easing
            local easedProgress = 1 - (1 - progress) ^ 3
            local newValue = startValue + (targetValue - startValue) * easedProgress
            
            -- Update animated value
            stats.animatingValues[statType] = newValue
            
            -- Update UI
            self:RenderStatValue(statType, newValue)
            
            if progress >= 1 then
                stats[statType] = targetValue
                stats.animatingValues[statType] = targetValue
                break
            end
            
            task.wait()
        end
        
        stats.updateThread[statType] = nil
    end)
end

function InventoryUI:RenderStatValue(statType: string, value: number)
    if statType == "equippedPets" and self.StatsLabels.Equipped then
        local displayValue = math.floor(value + 0.5)
        self.StatsLabels.Equipped.Text = displayValue .. "/6"
        
        -- Pulse effect on change
        if self._lastEquippedValue ~= displayValue then
            self._lastEquippedValue = displayValue
            
            -- Create glow effect
            local parent = self.StatsLabels.Equipped.Parent
            local glow = Instance.new("Frame")
            glow.Name = "StatGlow"
            glow.Size = UDim2.new(1, 10, 1, 10)
            glow.Position = UDim2.new(0.5, 0, 0.5, 0)
            glow.AnchorPoint = Vector2.new(0.5, 0.5)
            glow.BackgroundColor3 = self._config.COLORS.Success
            glow.BackgroundTransparency = 0.7
            glow.ZIndex = parent.ZIndex - 1
            glow.Parent = parent
            
            self._utilities.CreateCorner(glow, 8)
            
            -- Animate glow
            self._utilities.Tween(glow, {
                Size = UDim2.new(1, 20, 1, 20),
                BackgroundTransparency = 1
            }, TweenInfo.new(0.4, Enum.EasingStyle.Quad))
            
            game:GetService("Debris"):AddItem(glow, 0.5)
        end
        
    elseif statType == "totalPets" and self.StatsLabels.PetCount then
        local displayValue = math.floor(value + 0.5)
        self.StatsLabels.PetCount.Text = displayValue .. "/" .. self._realtimeStats.maxStorage
    end
end

function InventoryUI:UpdateStats(pets: table)
    print("[InventoryUI] UpdateStats called with", #pets, "pets")
    
    -- Count equipped pets from displayed list
    local equippedCount = 0
    for _, petInfo in ipairs(pets) do
        if petInfo.pet.equipped then
            equippedCount = equippedCount + 1
        end
    end
    
    -- Get total pet count from data cache
    local totalPets = 0
    if self._dataCache then
        local playerData = self._dataCache:Get("playerData")
        if playerData and playerData.pets then
            for _ in pairs(playerData.pets) do
                totalPets = totalPets + 1
            end
        end
    end
    
    -- Queue smooth updates
    self:QueueStatsUpdate("equippedPets", equippedCount)
    self:QueueStatsUpdate("totalPets", totalPets)
    self:QueueStatsUpdate("displayedPets", #pets)
    
    -- Update storage bar if exists
    if self.StatsLabels.Storage and self.StorageBars and self.StorageBars[self.StatsLabels.Storage] then
        self.StorageBars[self.StatsLabels.Storage].updateFunc(totalPets)
    end
end

-- Direct stat update for immediate changes
function InventoryUI:UpdateSingleStat(statType: string, delta: number)
    -- Simplified - just update the value
    local currentValue = self._realtimeStats[statType] or 0
    local newValue = math.max(0, currentValue + delta)
    self:QueueStatsUpdate(statType, newValue)
end

-- ========================================
-- PAGINATION
-- ========================================

function InventoryUI:ChangePage(newPage: number)
    if newPage < 1 or newPage > self.TotalPages then
        return
    end
    
    self.CurrentPage = newPage
    self:UpdatePaginationDisplay()
    self:RefreshInventory()
    
    -- Animate page change
    if self.PetGrid then
        self.PetGrid.CanvasPosition = Vector2.new(0, 0)
    end
    
    -- Sound feedback
    if self._soundSystem then
        self._soundSystem:PlayUISound("Click")
    end
end

function InventoryUI:UpdatePaginationDisplay()
    if self.PaginationControls.PageLabel then
        self.PaginationControls.PageLabel.Text = string.format("Page %d / %d", self.CurrentPage, self.TotalPages)
    end
    
    -- Update button states
    if self.PaginationControls.PrevButton then
        self.PaginationControls.PrevButton.BackgroundColor3 = self.CurrentPage <= 1 
            and self._config.COLORS.Dark 
            or self._config.COLORS.Primary
        self.PaginationControls.PrevButton.Active = self.CurrentPage > 1
    end
    
    if self.PaginationControls.NextButton then
        self.PaginationControls.NextButton.BackgroundColor3 = self.CurrentPage >= self.TotalPages 
            and self._config.COLORS.Dark 
            or self._config.COLORS.Primary
        self.PaginationControls.NextButton.Active = self.CurrentPage < self.TotalPages
    end
end

function InventoryUI:ShowEmptyState()
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Size = UDim2.new(1, 0, 0, 100)
    emptyLabel.Position = UDim2.new(0, 0, 0.5, -50)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "No pets found!\nTry adjusting your filters or open some eggs!"
    emptyLabel.TextScaled = true
    emptyLabel.TextColor3 = self._config.COLORS.TextSecondary
    emptyLabel.Font = self._config.FONTS.Primary
    emptyLabel.Parent = self.PetGrid
end

function InventoryUI:DisplayPets(pets: table)
    -- Calculate pagination
    self.TotalPages = math.max(1, math.ceil(#pets / self.PetsPerPage))
    
    -- Ensure current page is valid
    if self.CurrentPage > self.TotalPages then
        self.CurrentPage = self.TotalPages
    end
    if self.CurrentPage < 1 then
        self.CurrentPage = 1
    end
    
    -- Update pagination display
    self:UpdatePaginationDisplay()
    
    -- Calculate which pets to show on current page
    local startIndex = (self.CurrentPage - 1) * self.PetsPerPage + 1
    local endIndex = math.min(startIndex + self.PetsPerPage - 1, #pets)
    
    -- Create paginated subset
    local petsToDisplay = {}
    for i = startIndex, endIndex do
        if pets[i] then
            table.insert(petsToDisplay, pets[i])
        end
    end
    
    if self.VirtualScrollEnabled then
        -- Virtual scrolling mode with pagination
        self.VisiblePets = petsToDisplay  -- Store paginated pets for virtual scrolling
        
        -- Calculate total canvas size for current page
        local totalRows = math.ceil(#petsToDisplay / self.ColumnsPerRow)
        local canvasHeight = totalRows * (self.CardHeight + self.CardPadding)
        self.PetGrid.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
        
        -- Set up virtual scrolling if not already set up
        if not self.ScrollConnection then
            self:SetupVirtualScrolling()
        end
        
        -- Initial render
        self:OnVirtualScroll()
    else
        -- Traditional mode with pagination
        for i, petInfo in ipairs(petsToDisplay) do
            local card = self:CreatePetCard(self.PetGrid, petInfo.pet, petInfo.data)
            if card then
                card.LayoutOrder = i
                -- Add to cache for potential future use
                table.insert(self.PetCardCache, card)
            end
        end
    end
    
    -- Update stats to show total (not just current page)
    self:UpdateStats(pets)
end

-- ========================================
-- PET DETAILS
-- ========================================

function InventoryUI:ShowPetDetails(petInstance: PetInstance, petData: table)
    -- Fire event for PetDetailsUI to handle
    if self._eventBus then
        self._eventBus:Fire("ShowPetDetails", {
            petInstance = petInstance,
            petData = petData
        })
    end
end

-- ========================================
-- OTHER TABS
-- ========================================

-- Mass delete functionality moved to MassDeleteUI module

-- Stub function to prevent errors from old references
function InventoryUI:OpenMassDelete()
    -- Close any existing delete window
    if self.DeleteOverlay then
        self.DeleteOverlay:Destroy()
    end
    
    -- Get the highest parent (ScreenGui)
    local screenGui = self.Frame.Parent
    while screenGui.Parent and not screenGui:IsA("ScreenGui") do
        screenGui = screenGui.Parent
    end
    
    -- Create overlay at ScreenGui level
    local overlay = Instance.new("Frame")
    overlay.Name = "MassDeleteOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 900  -- Very high to ensure it's on top
    overlay.Parent = screenGui
    
    self.DeleteOverlay = overlay
    
    -- Create window
    local deleteWindow = Instance.new("Frame")
    deleteWindow.Name = "DeleteWindow"
    deleteWindow.Size = UDim2.new(0, MASS_DELETE_WINDOW_SIZE.X, 0, MASS_DELETE_WINDOW_SIZE.Y)
    deleteWindow.Position = UDim2.new(0.5, -MASS_DELETE_WINDOW_SIZE.X/2, 0.5, -MASS_DELETE_WINDOW_SIZE.Y/2)
    deleteWindow.BackgroundColor3 = self._config.COLORS.Background
    deleteWindow.ZIndex = 901  -- Above overlay
    deleteWindow.Parent = overlay
    
    self._utilities.CreateCorner(deleteWindow, 20)
    -- CreateShadow is optional, skip if not available
    if self._utilities.CreateShadow then
        self._utilities.CreateShadow(deleteWindow, 0.5)
    end
    
    -- Header
    local header = self._uiFactory:CreateFrame(deleteWindow, {
        name = "Header",
        size = UDim2.new(1, 0, 0, 60),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Error,
        zIndex = 902
    })
    
    local headerLabel = self._uiFactory:CreateLabel(header, {
        text = "Mass Delete Pets",
        size = UDim2.new(1, -50, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        font = self._config.FONTS.Display,
        textColor = self._config.COLORS.White,
        textSize = 20,
        zIndex = 903
    })
    
    -- Close button
    local closeButton = self._uiFactory:CreateButton(header, {
        text = "✖",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -45, 0.5, -20),
        backgroundColor = Color3.new(1, 1, 1),
        backgroundTransparency = 0.9,
        textColor = self._config.COLORS.White,
        zIndex = 903,
        callback = function()
            self:CloseMassDelete()
        end
    })
    
    -- Content
    self:CreateMassDeleteContent(deleteWindow)
    
    -- Animate in
    deleteWindow.Size = UDim2.new(0, 0, 0, 0)
    self._utilities.Tween(deleteWindow, {
        Size = UDim2.new(0, MASS_DELETE_WINDOW_SIZE.X, 0, MASS_DELETE_WINDOW_SIZE.Y)
    }, self._config.TWEEN_INFO.Elastic)
end

function InventoryUI:CreateMassDeleteContent(window: Frame)
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -140)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundTransparency = 1
    content.ZIndex = 902
    content.Parent = window
    
    -- Instructions
    local infoLabel = self._uiFactory:CreateLabel(content, {
        text = "Select pets to delete. This action cannot be undone!",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0),
        textColor = self._config.COLORS.Error,
        textWrapped = true,
        zIndex = 903
    })
    
    -- Quick select buttons
    local quickSelectFrame = Instance.new("Frame")
    quickSelectFrame.Size = UDim2.new(1, 0, 0, 40)
    quickSelectFrame.Position = UDim2.new(0, 0, 0, 50)
    quickSelectFrame.BackgroundTransparency = 1
    quickSelectFrame.ZIndex = 902
    quickSelectFrame.Parent = content
    
    local selectAllCommon = self._uiFactory:CreateButton(quickSelectFrame, {
        text = "All Common",
        size = UDim2.new(0, 120, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        callback = function()
            self:SelectPetsByRarity(1)
        end
    })
    
    local selectAllUncommon = self._uiFactory:CreateButton(quickSelectFrame, {
        text = "All Uncommon",
        size = UDim2.new(0, 120, 1, 0),
        position = UDim2.new(0, 130, 0, 0),
        callback = function()
            self:SelectPetsByRarity(2)
        end
    })
    
    local deselectAll = self._uiFactory:CreateButton(quickSelectFrame, {
        text = "Deselect All",
        size = UDim2.new(0, 120, 1, 0),
        position = UDim2.new(0, 260, 0, 0),
        backgroundColor = self._config.COLORS.Secondary,
        callback = function()
            self:DeselectAllPets()
        end
    })
    
    -- Advanced select options (second row)
    local advancedSelectFrame = self._uiFactory:CreateFrame(content, {
        size = UDim2.new(1, -40, 0, 40),
        position = UDim2.new(0, 20, 0, 50),
        backgroundColor = self._config.COLORS.Background
    })
    
    local selectExceptLegend = self._uiFactory:CreateButton(advancedSelectFrame, {
        text = "All Except Legendary+",
        size = UDim2.new(0, 150, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Warning,
        callback = function()
            self:SelectAllExceptRarity(4) -- Exclude Legendary and above
        end
    })
    
    local selectExceptMythic = self._uiFactory:CreateButton(advancedSelectFrame, {
        text = "All Except Mythic",
        size = UDim2.new(0, 140, 1, 0),
        position = UDim2.new(0, 160, 0, 0),
        backgroundColor = self._config.COLORS.Warning,
        callback = function()
            self:SelectAllExceptRarity(5) -- Exclude Mythic
        end
    })
    
    local lockAllButton = self._uiFactory:CreateButton(advancedSelectFrame, {
        text = "Lock Selected",
        size = UDim2.new(0, 120, 1, 0),
        position = UDim2.new(0, 310, 0, 0),
        backgroundColor = self._config.COLORS.Info,
        callback = function()
            self:LockSelectedPets()
        end
    })
    
    -- Pet selection grid
    local scrollFrame = self._uiFactory:CreateScrollingFrame(content, {
        size = UDim2.new(1, 0, 1, -200),  -- Adjusted for extra row
        position = UDim2.new(0, 0, 0, 150)  -- Moved down for extra row
    })
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 110, 0, 130)  -- Slightly bigger cells
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)  -- More spacing
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    self.DeleteSelectionGrid = scrollFrame
    self.SelectedForDeletion = {}
    
    -- Load pets for selection
    self:LoadPetsForDeletion(scrollFrame)
    
    -- Update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Bottom bar
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 60)
    bottomBar.Position = UDim2.new(0, 0, 1, -60)
    bottomBar.BackgroundColor3 = self._config.COLORS.Dark
    bottomBar.ZIndex = 902
    bottomBar.Parent = window
    
    self._utilities.CreateCorner(bottomBar, 20)
    
    -- Selected count
    local selectedLabel = self._uiFactory:CreateLabel(bottomBar, {
        text = "Selected: 0 pets",
        size = UDim2.new(0, 200, 1, 0),
        position = UDim2.new(0, 20, 0, 0),
        textXAlignment = Enum.TextXAlignment.Left,
        zIndex = 903
    })
    self.DeleteSelectedLabel = selectedLabel
    
    -- Delete button
    local deleteButton = self._uiFactory:CreateButton(bottomBar, {
        text = "Delete Selected",
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(1, -170, 0.5, -20),
        backgroundColor = self._config.COLORS.Error,
        zIndex = 903,
        callback = function()
            self:ConfirmMassDelete()
        end
    })
end

function InventoryUI:LoadPetsForDeletion(parent: ScrollingFrame)
    local playerData = self._dataCache and self._dataCache:Get() or {}
    if not playerData.pets then return end
    
    local pets = {}
    
    -- Convert to array if needed
    for uniqueId, pet in pairs(playerData.pets) do
        if type(pet) == "table" and not pet.equipped and not pet.locked then
            pet.uniqueId = uniqueId
            table.insert(pets, pet)
        end
    end
    
    -- Sort by rarity (lowest first for easier mass deletion)
    table.sort(pets, function(a, b)
        -- Use pet's own data
        local aData = {
            name = a.name or "Unknown",
            rarity = a.rarity or 1
        }
        local bData = {
            name = b.name or "Unknown",
            rarity = b.rarity or 1
        }
        return (aData.rarity or 1) < (bData.rarity or 1)
    end)
    
    -- Create selection cards
    for _, pet in ipairs(pets) do
        -- Use pet's own data
        local petData = {
            name = pet.name or "Unknown",
            displayName = pet.displayName or pet.name or "Unknown",
            rarity = pet.rarity or 1
        }
        
        local card = self:CreateDeleteSelectionCard(parent, pet, petData)
    end
end

function InventoryUI:CreateDeleteSelectionCard(parent: ScrollingFrame, petInstance: PetInstance, petData: table): Frame
    local card = Instance.new("Frame")
    card.Name = petInstance.uniqueId
    card.BackgroundColor3 = self._config.COLORS.Surface
    card.BorderSizePixel = 0
    card:SetAttribute("Rarity", petData.rarity or 1)  -- Store rarity for filtering
    card.ZIndex = 1  -- Ensure proper layering
    card.Parent = parent
    
    self._utilities.CreateCorner(card, 8)
    
    -- Selection indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "SelectIndicator"
    indicator.Size = UDim2.new(1, 0, 1, 0)
    indicator.BackgroundColor3 = self._config.COLORS.Success
    indicator.BackgroundTransparency = 1
    indicator.Parent = card
    
    self._utilities.CreateCorner(indicator, 8)
    
    -- Pet image
    local petImage = Instance.new("ImageLabel")
    petImage.Size = UDim2.new(1, -10, 1, -30)
    petImage.Position = UDim2.new(0, 5, 0, 5)
    petImage.BackgroundTransparency = 1
    petImage.Image = petData.imageId or ""
    petImage.ScaleType = Enum.ScaleType.Fit
    petImage.Parent = card
    
    -- Name label
    local nameLabel = self._uiFactory:CreateLabel(card, {
        text = petInstance.nickname or petData.name or petData.displayName or "Unknown",
        size = UDim2.new(1, -4, 0, 20),
        position = UDim2.new(0, 2, 1, -22),
        textScaled = true,
        textSize = 12
    })
    
    -- Rarity indicator
    local rarityBar = Instance.new("Frame")
    rarityBar.Size = UDim2.new(1, 0, 0, 3)
    rarityBar.Position = UDim2.new(0, 0, 1, -3)
    rarityBar.BackgroundColor3 = self._utilities.GetRarityColor(petData.rarity or 1)
    rarityBar.BorderSizePixel = 0
    rarityBar.Parent = card
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    self._janitor:Add(button.MouseButton1Click:Connect(function()
        if self.SelectedForDeletion[petInstance.uniqueId] then
            self.SelectedForDeletion[petInstance.uniqueId] = nil
            indicator.BackgroundTransparency = 1
        else
            self.SelectedForDeletion[petInstance.uniqueId] = true
            indicator.BackgroundTransparency = 0.3
        end
        
        self:UpdateDeleteCount()
    end))
    
    return card
end

function InventoryUI:SelectPetsByRarity(rarity: number)
    if not self.DeleteSelectionGrid then return end
    
    for _, card in ipairs(self.DeleteSelectionGrid:GetChildren()) do
        if card:IsA("Frame") then
            local petId = card.Name
            local playerData = self._dataCache and self._dataCache:Get() or {}
            
            if playerData.pets and playerData.pets[petId] then
                local pet = playerData.pets[petId]
                -- Use pet's own data
                local petData = {
                    name = pet.name or "Unknown",
                    rarity = pet.rarity or 1
                }
                
                if petData.rarity == rarity and not pet.equipped and not pet.locked then
                    self.SelectedForDeletion[petId] = true
                    local indicator = card:FindFirstChild("SelectIndicator")
                    if indicator then
                        indicator.BackgroundTransparency = 0.3
                    end
                end
            end
        end
    end
    
    self:UpdateDeleteCount()
end

function InventoryUI:DeselectAllPets()
    self.SelectedForDeletion = {}
    
    if self.DeleteSelectionGrid then
        for _, card in ipairs(self.DeleteSelectionGrid:GetChildren()) do
            if card:IsA("Frame") then
                local indicator = card:FindFirstChild("SelectIndicator")
                if indicator then
                    indicator.BackgroundTransparency = 1
                end
            end
        end
    end
    
    self:UpdateDeleteCount()
end

function InventoryUI:SelectAllExceptRarity(minRarity: number)
    self.SelectedForDeletion = {}
    
    if self.DeleteSelectionGrid then
        -- Get all pet cards
        for _, card in ipairs(self.DeleteSelectionGrid:GetChildren()) do
            if card:IsA("Frame") then
                local petRarity = card:GetAttribute("Rarity") or 1
                
                if petRarity < minRarity then
                    -- Select pets below the specified rarity
                    self.SelectedForDeletion[card.Name] = true
                    local indicator = card:FindFirstChild("SelectIndicator")
                    if indicator then
                        indicator.BackgroundTransparency = 0.7
                    end
                else
                    -- Deselect pets at or above the specified rarity
                    local indicator = card:FindFirstChild("SelectIndicator")
                    if indicator then
                        indicator.BackgroundTransparency = 1
                    end
                end
            end
        end
    end
    
    self:UpdateDeleteCount()
end

function InventoryUI:LockSelectedPets()
    if not next(self.SelectedForDeletion) then
        self._notificationSystem:Show({
            message = "No pets selected to lock!",
            type = "warning",
            duration = 2
        })
        return
    end
    
    local count = 0
    for uniqueId in pairs(self.SelectedForDeletion) do
        -- Send lock request to server
        if self._remoteManager then
            self._remoteManager:Fire("TogglePetLock", {uniqueId = uniqueId, locked = true})
            count = count + 1
        end
    end
    
    self._notificationSystem:Show({
        message = string.format("Locked %d pets!", count),
        type = "success",
        duration = 2
    })
    
    -- Close the mass delete window since locked pets can't be deleted
    if self.DeleteOverlay then
        self.DeleteOverlay:Destroy()
        self.DeleteOverlay = nil
    end
end

function InventoryUI:UpdateDeleteCount()
    local count = 0
    for _ in pairs(self.SelectedForDeletion) do
        count = count + 1
    end
    
    if self.DeleteSelectedLabel then
        self.DeleteSelectedLabel.Text = "Selected: " .. count .. " pets"
    end
end

function InventoryUI:ConfirmMassDelete()
    local count = 0
    local petIds = {}
    
    for petId in pairs(self.SelectedForDeletion) do
        count = count + 1
        table.insert(petIds, petId)
    end
    
    if count == 0 then
        self._notificationSystem:SendNotification("Error", "No pets selected for deletion", "error")
        return
    end
    
    -- Create confirmation dialog
    local confirmText = string.format("Are you sure you want to delete %d pets?\n\nThis action cannot be undone!", count)
    
    -- Create simple confirmation dialog
    local overlay = Instance.new("Frame")
    overlay.Name = "ConfirmOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = self._config.ZINDEX.Overlay
    overlay.Parent = self.ScreenGui
    
    local dialog = Instance.new("Frame")
    dialog.Name = "ConfirmDialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = self._config.COLORS.Background
    dialog.ZIndex = self._config.ZINDEX.Modal
    dialog.Parent = overlay
    
    self._utilities.CreateCorner(dialog, 12)
    
    -- Title
    local title = self._uiFactory:CreateLabel(dialog, {
        text = "Confirm Mass Delete",
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0, 10),
        font = self._config.FONTS.Bold,
        textSize = 20
    })
    
    -- Message
    local message = self._uiFactory:CreateLabel(dialog, {
        text = confirmText,
        size = UDim2.new(1, -20, 0, 60),
        position = UDim2.new(0, 10, 0, 50),
        font = self._config.FONTS.Primary,
        textSize = 16,
        textWrapped = true
    })
    
    -- Buttons
    local confirmButton = self._uiFactory:CreateButton(dialog, {
        text = "Delete " .. count .. " Pets",
        size = UDim2.new(0.5, -15, 0, 40),
        position = UDim2.new(0, 10, 1, -50),
        backgroundColor = self._config.COLORS.Error,
        callback = function()
            overlay:Destroy()
            self:ExecuteMassDelete(petIds)
        end
    })
    
    local cancelButton = self._uiFactory:CreateButton(dialog, {
        text = "Cancel",
        size = UDim2.new(0.5, -15, 0, 40),
        position = UDim2.new(0.5, 5, 1, -50),
        callback = function()
            overlay:Destroy()
        end
    })
end

function InventoryUI:AnimateCardDeletion(card: Frame, callback: () -> ())
    -- Create particle burst effect
    local particleContainer = Instance.new("Frame")
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.Position = UDim2.new(0, 0, 0, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ZIndex = card.ZIndex + 10
    particleContainer.Parent = card.Parent
    
    -- Get card center position
    local centerX = card.AbsolutePosition.X + card.AbsoluteSize.X / 2
    local centerY = card.AbsolutePosition.Y + card.AbsoluteSize.Y / 2
    
    -- Create particles
    for i = 1, 15 do
        task.spawn(function()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
            particle.Position = UDim2.new(0, centerX - particleContainer.AbsolutePosition.X, 
                                         0, centerY - particleContainer.AbsolutePosition.Y)
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.BackgroundColor3 = self._config.COLORS.Error
            particle.BorderSizePixel = 0
            particle.Parent = particleContainer
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = particle
            
            -- Random direction and speed
            local angle = math.random() * math.pi * 2
            local speed = math.random(50, 100)
            local targetX = particle.Position.X.Offset + math.cos(angle) * speed
            local targetY = particle.Position.Y.Offset + math.sin(angle) * speed
            
            -- Animate particle
            self._utilities.Tween(particle, {
                Position = UDim2.new(0, targetX, 0, targetY),
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Rotation = math.random(180, 360)
            }, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end)
    end
    
    -- Cleanup particles after animation
    game:GetService("Debris"):AddItem(particleContainer, 1)
    
    -- Animate card shrinking and fading
    self._utilities.Tween(card, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Rotation = math.random(-15, 15)
    }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In))
    
    -- Fade out all children
    for _, child in ipairs(card:GetDescendants()) do
        if child:IsA("GuiObject") then
            if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                self._utilities.Tween(child, {
                    ImageTransparency = 1
                }, TweenInfo.new(0.3))
            elseif child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                self._utilities.Tween(child, {
                    TextTransparency = 1
                }, TweenInfo.new(0.3))
            end
            if child.BackgroundTransparency < 1 then
                self._utilities.Tween(child, {
                    BackgroundTransparency = 1
                }, TweenInfo.new(0.3))
            end
        end
    end
    
    -- Sound effect
    if self._soundSystem then
        self._soundSystem:PlayUISound("Delete")
    end
    
    -- Wait for animation then callback
    task.wait(0.4)
    if callback then
        callback()
    end
end

function InventoryUI:ExecuteMassDelete(petIds: {string})
    -- Show loading state
    if self.DeleteOverlay then
        local loadingLabel = self._uiFactory:CreateLabel(self.DeleteOverlay, {
            text = "Deleting pets...",
            size = UDim2.new(0, 200, 0, 50),
            position = UDim2.new(0.5, -100, 0.5, -25),
            backgroundColor = self._config.COLORS.Dark,
            textColor = self._config.COLORS.White,
            zIndex = self._config.ZINDEX.ModalContent
        })
        
        self._utilities.CreateCorner(loadingLabel, 8)
    end
    
    -- Send batch delete request
    if self._remoteManager then
        -- Try batch delete first
        local result = self._remoteManager:InvokeServer("BatchDeletePets", {petIds = petIds})
        
        local successCount = 0
        local failCount = 0
        
        if result and result.success then
            successCount = result.deletedCount or 0
            failCount = #petIds - successCount
            
            -- Show resource notification if available
            if result.coinsReceived or result.dustReceived then
                self._notificationSystem:Show({
                    title = "Resources Received",
                    message = string.format("You received %s coins and %s pet dust!", 
                        self._utilities:FormatNumber(result.coinsReceived or 0),
                        self._utilities:FormatNumber(result.dustReceived or 0)
                    ),
                    type = "success",
                    duration = 4
                })
            end
        elseif result and result.error then
            -- Handle error
            self._notificationSystem:Show({
                title = "Delete Failed", 
                message = result.error,
                type = "error"
            })
            
            -- Close mass delete window
            self:CloseMassDelete()
            return
        end
        
        if successCount > 0 then
            -- Animate deletion of cards
            local cardsToDelete = {}
            
            -- Find all cards to delete
            if self.PetGrid then
                for _, card in ipairs(self.PetGrid:GetChildren()) do
                    if card:IsA("Frame") and card.Name:match("PetCard_") then
                        local petId = card.Name:gsub("PetCard_", "")
                        if table.find(petIds, petId) then
                            table.insert(cardsToDelete, card)
                        end
                    end
                end
            end
            
            -- Animate each card deletion with staggered timing
            for i, card in ipairs(cardsToDelete) do
                task.spawn(function()
                    task.wait((i - 1) * 0.05) -- Stagger animations
                    self:AnimateCardDeletion(card, function()
                        card:Destroy()
                    end)
                end)
            end
            
            -- Wait for animations to complete
            task.wait(0.5 + #cardsToDelete * 0.05)
            
            if self._notificationSystem then
                local message = string.format("Successfully deleted %d pets!", successCount)
                if failCount > 0 then
                    message = message .. string.format(" (%d failed)", failCount)
                end
                
                self._notificationSystem:Show({
                    title = "Mass Delete Complete",
                    message = message,
                    type = successCount > 0 and "success" or "error",
                    duration = 3
                })
            end
            
            -- Play sound
            if self._soundSystem then
                self._soundSystem:PlayUISound("Success")
            end
            
            -- Close mass delete window
            self:CloseMassDelete()
            
            -- Refresh inventory with remaining pets
            self:RefreshInventory()
        else
            if self._notificationSystem then
                self._notificationSystem:Show({
                    title = "Error",
                    message = result or "Failed to delete pets",
                    type = "error",
                    duration = 3
                })
            end
        end
    end
end

function InventoryUI:CloseMassDelete()
    if self.DeleteOverlay then
        local deleteWindow = self.DeleteOverlay:FindFirstChild("DeleteWindow")
        if deleteWindow then
            self._utilities.Tween(deleteWindow, {
                Size = UDim2.new(0, 0, 0, 0)
            }, self._config.TWEEN_INFO.Normal)
        end
        
        self._utilities.Tween(self.DeleteOverlay, {
            BackgroundTransparency = 1
        }, self._config.TWEEN_INFO.Normal)
        
        task.wait(0.3)
        self.DeleteOverlay:Destroy()
        self.DeleteOverlay = nil
    end
    
    -- Clear selection
    self.SelectedForDeletion = {}
    self.DeleteSelectionGrid = nil
    self.DeleteSelectedLabel = nil
end

function InventoryUI:CreateStorageTab(parent: Frame)
    -- Storage statistics and upgrades
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -40)
    content.Position = UDim2.new(0, 20, 0, 20)
    content.BackgroundTransparency = 1
    content.Parent = parent
    
    -- Current storage info
    local storageInfo = self._uiFactory:CreateFrame(content, {
        size = UDim2.new(1, 0, 0, 200),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = self._config.COLORS.Surface
    })
    
    local titleLabel = self._uiFactory:CreateLabel(storageInfo, {
        text = "Pet Storage",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 10),
        font = self._config.FONTS.Display,
        textSize = 20
    })
    
    -- Storage progress bar
    local progressFrame = Instance.new("Frame")
    progressFrame.Size = UDim2.new(1, -40, 0, 30)
    progressFrame.Position = UDim2.new(0, 20, 0, 60)
    progressFrame.BackgroundColor3 = self._config.COLORS.Dark
    progressFrame.Parent = storageInfo
    
    self._utilities.CreateCorner(progressFrame, 15)
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "StorageFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = self._config.COLORS.Primary
    progressFill.Parent = progressFrame
    
    self._utilities.CreateCorner(progressFill, 15)
    
    -- Storage text
    local storageText = self._uiFactory:CreateLabel(storageInfo, {
        text = "0 / 500 Pets",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 100),
        font = self._config.FONTS.Secondary,
        textSize = 18
    })
    
    -- Upgrade button
    local upgradeButton = self._uiFactory:CreateButton(storageInfo, {
        text = "Upgrade Storage",
        size = UDim2.new(0, 200, 0, 40),
        position = UDim2.new(0.5, -100, 0, 140),
        backgroundColor = self._config.COLORS.Success,
        callback = function()
            -- Open storage upgrade shop
            if self._eventBus then
                self._eventBus:Fire("OpenStorageUpgrade", {})
            end
        end
    })
end

function InventoryUI:CreateStatsTab(parent: Frame)
    -- Pet collection statistics
    local scrollFrame = self._uiFactory:CreateScrollingFrame(parent, {
        size = UDim2.new(1, -20, 1, -20),
        position = UDim2.new(0, 10, 0, 10)
    })
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 0, 800)
    content.BackgroundTransparency = 1
    content.Parent = scrollFrame
    
    local yOffset = 0
    
    -- Collection stats
    local collectionStats = {
        {label = "Total Pets Collected", getValue = function() return "0" end},
        {label = "Unique Pets", getValue = function() return "0" end},
        {label = "Rarest Pet", getValue = function() return "None" end},
        {label = "Total Pet Power", getValue = function() return "0" end},
        {label = "Average Pet Level", getValue = function() return "0" end},
        {label = "Pets Traded", getValue = function() return "0" end},
        {label = "Eggs Opened", getValue = function() return "0" end},
    }
    
    for _, stat in ipairs(collectionStats) do
        local statFrame = self._uiFactory:CreateFrame(content, {
            size = UDim2.new(1, 0, 0, 60),
            position = UDim2.new(0, 0, 0, yOffset),
            backgroundColor = self._config.COLORS.Surface
        })
        
        local labelText = self._uiFactory:CreateLabel(statFrame, {
            text = stat.label,
            size = UDim2.new(0.6, -10, 1, 0),
            position = UDim2.new(0, 10, 0, 0),
            textXAlignment = Enum.TextXAlignment.Left,
            font = self._config.FONTS.Primary
        })
        
        local valueText = self._uiFactory:CreateLabel(statFrame, {
            text = stat.getValue(),
            size = UDim2.new(0.4, -10, 1, 0),
            position = UDim2.new(0.6, 0, 0, 0),
            textXAlignment = Enum.TextXAlignment.Right,
            font = self._config.FONTS.Secondary,
            textColor = self._config.COLORS.Primary
        })
        
        yOffset = yOffset + 70
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function InventoryUI:OnSearchChanged(text: string)
    -- Debounce search
    if self.SearchDebounce then
        task.cancel(self.SearchDebounce)
    end
    
    self.SearchDebounce = task.spawn(function()
        task.wait(SEARCH_DEBOUNCE)
        self.SearchText = text
        self:RefreshInventory()
        self.SearchDebounce = nil
    end)
end

function InventoryUI:UpdatePetCardEquipStatus(uniqueId: string, equipped: boolean)
    -- This function now ONLY updates the visual card itself.
    
    -- Find the card in the grid
    local card = nil
    if self.VirtualScrollEnabled then
        for _, activeCard in pairs(self.ActiveCards) do
            if activeCard.Name == "PetCard_" .. uniqueId then
                card = activeCard
                break
            end
        end
    else
        for _, cachedCard in ipairs(self.PetCardCache) do
            if cachedCard.Name == "PetCard_" .. uniqueId then
                card = cachedCard
                break
            end
        end
    end

    if card then
        card:SetAttribute("Equipped", equipped)
        local indicator = card:FindFirstChild("EquippedIndicator")
        if equipped and not indicator then
            -- Create and fade in the checkmark
            indicator = Instance.new("ImageLabel")
            indicator.Name = "EquippedIndicator"
            indicator.Size = UDim2.new(0, 30, 0, 30)
            indicator.Position = UDim2.new(1, -35, 0, 5)
            indicator.BackgroundTransparency = 1
            indicator.Image = "rbxassetid://7734053426"
            indicator.ImageColor3 = self._config.COLORS.Success
            indicator.ImageTransparency = 1
            indicator.Parent = card
            
            self._utilities.Tween(indicator, {
                ImageTransparency = 0
            }, TweenInfo.new(0.2, Enum.EasingStyle.Back))
        elseif not equipped and indicator then
            -- Fade out and destroy the checkmark
            self._utilities.Tween(indicator, {
                ImageTransparency = 1
            }, TweenInfo.new(0.2, Enum.EasingStyle.Quad))
            game:GetService("Debris"):AddItem(indicator, 0.2)
        end
        
        -- Play sound
        if self._soundSystem then
            self._soundSystem:PlayUISound(equipped and "Equip" or "Unequip")
        end
    end

    -- After updating the card, we tell our Real-Time Stats System to update the count.
    -- This is the key to a smooth, animated update.
    local equippedDelta = equipped and 1 or -1
    self:UpdateSingleStat("equippedPets", equippedDelta)
end

function InventoryUI:RefreshEquippedCount()
    -- Count equipped pets from the data
    local equippedCount = 0
    local playerData = self._dataCache and self._dataCache:Get("playerData")
    if playerData and playerData.pets then
        for _, pet in pairs(playerData.pets) do
            if pet.equipped then
                equippedCount = equippedCount + 1
            end
        end
    end
    
    -- Update the display
    if self.StatsLabels.Equipped then
        self.StatsLabels.Equipped.Text = equippedCount .. "/6"
    end
    
    -- Update real-time stats
    self._realtimeStats.equippedPets = equippedCount
    self._realtimeStats.animatingValues.equippedPets = equippedCount
end

function InventoryUI:GetEquippedCount()
    -- Returns the live equipped count from real-time stats
    return self._realtimeStats and self._realtimeStats.equippedPets or 0
end

function InventoryUI:UpdatePetCardLockStatus(uniqueId: string, locked: boolean)
    if self.VirtualScrollEnabled then
        -- Virtual scrolling mode - update the data and visible cards
        if self.VisiblePets then
            for _, petInfo in ipairs(self.VisiblePets) do
                if petInfo.pet.uniqueId == uniqueId then
                    petInfo.pet.locked = locked
                    break
                end
            end
        end
        
        -- Update any visible cards
        for index, card in pairs(self.ActiveCards) do
            if card.Name == "PetCard_" .. uniqueId then
                card:SetAttribute("Locked", locked)
                
                local indicator = card:FindFirstChild("LockedIndicator")
                if locked and not indicator then
                    -- Add lock indicator
                    indicator = Instance.new("ImageLabel")
                    indicator.Name = "LockedIndicator"
                    indicator.Size = UDim2.new(0, 25, 0, 25)
                    indicator.Position = UDim2.new(1, -30, 1, -30)
                    indicator.BackgroundTransparency = 1
                    indicator.Image = "rbxassetid://7734021047" -- Lock icon
                    indicator.ImageColor3 = self._config.COLORS.Warning
                    indicator.Parent = card
                elseif not locked and indicator then
                    indicator:Destroy()
                end
                break
            end
        end
    else
        -- Traditional mode - use cache
        for _, card in ipairs(self.PetCardCache) do
            if card.Name == "PetCard_" .. uniqueId then
                card:SetAttribute("Locked", locked)
                
                local indicator = card:FindFirstChild("LockIndicator")
                if locked and not indicator then
                    -- Add lock indicator
                    indicator = Instance.new("ImageLabel")
                    indicator.Name = "LockIndicator"
                    indicator.Size = UDim2.new(0, 20, 0, 20)
                    indicator.Position = UDim2.new(1, -24, 1, -24)
                    indicator.BackgroundTransparency = 1
                    indicator.Image = "rbxassetid://7072718266"
                    indicator.ImageColor3 = self._config.COLORS.Warning
                    indicator.Parent = card
                elseif not locked and indicator then
                    indicator:Destroy()
                end
                
                break
            end
        end
    end
end

function InventoryUI:RemovePetCard(uniqueId: string)
    print("[InventoryUI] Removing pet card:", uniqueId)
    
    -- Remove from data cache first
    if self._dataCache and self._dataCache.Get then
        local playerData = self._dataCache:Get("playerData") or {}
        if playerData.pets and playerData.pets[uniqueId] then
            playerData.pets[uniqueId] = nil
            if self._dataCache.Set then
                self._dataCache:Set("playerData", playerData)
            end
        end
    end
    
    if self.VirtualScrollEnabled then
        -- Virtual scrolling mode - remove from data and refresh if visible
        if self.VisiblePets then
            for i, petInfo in ipairs(self.VisiblePets) do
                if petInfo.pet.uniqueId == uniqueId then
                    table.remove(self.VisiblePets, i)
                    
                    -- Also remove from active cards if visible
                    if self.ActiveCards[uniqueId] then
                        local card = self.ActiveCards[uniqueId]
                        self.ActiveCards[uniqueId] = nil
                        self:ReturnCardToPool(card)
                    end
                    
                    -- Recalculate canvas size
                    local totalRows = math.ceil(#self.VisiblePets / self.ColumnsPerRow)
                    local canvasHeight = totalRows * (self.CardHeight + self.CardPadding)
                    self.PetGrid.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
                    
                    -- Refresh visible area
                    self:OnVirtualScroll()
                    break
                end
            end
        end
    else
        -- Traditional mode - find and remove card
        for i, card in ipairs(self.PetCardCache) do
            if card.Name == "PetCard_" .. uniqueId then
                table.remove(self.PetCardCache, i)
                card:Destroy()
                break
            end
        end
    end
    
    -- Also trigger a full refresh after a short delay to ensure consistency
    task.wait(0.1)
    self:RefreshInventory()
end

function InventoryUI:UpdatePetCardLevel(uniqueId: string, newLevel: number)
    if self.VirtualScrollEnabled then
        -- Update data
        if self.VisiblePets then
            for _, petInfo in ipairs(self.VisiblePets) do
                if petInfo.pet.uniqueId == uniqueId then
                    petInfo.pet.level = newLevel
                    break
                end
            end
        end
        
        -- Update visible card
        for index, card in pairs(self.ActiveCards) do
            if card.Name == "PetCard_" .. uniqueId then
                local levelLabel = card:FindFirstChild("LevelLabel")
                if levelLabel then
                    levelLabel.Text = "Lv." .. tostring(newLevel)
                end
                break
            end
        end
    else
        -- Traditional mode
        for _, card in ipairs(self.PetCardCache) do
            if card.Name == "PetCard_" .. uniqueId then
                local levelLabel = card:FindFirstChild("LevelLabel")
                if levelLabel then
                    levelLabel.Text = "Lv." .. tostring(newLevel)
                end
                break
            end
        end
    end
end

function InventoryUI:UpdatePetCardName(uniqueId: string, newName: string)
    if self.VirtualScrollEnabled then
        -- Update data
        if self.VisiblePets then
            for _, petInfo in ipairs(self.VisiblePets) do
                if petInfo.pet.uniqueId == uniqueId then
                    petInfo.pet.nickname = newName
                    break
                end
            end
        end
        
        -- Update visible card
        for index, card in pairs(self.ActiveCards) do
            if card.Name == "PetCard_" .. uniqueId then
                local nameLabel = card:FindFirstChild("NameLabel")
                if nameLabel then
                    nameLabel.Text = newName or "Unknown"
                end
                card:SetAttribute("PetNickname", newName or "")
                break
            end
        end
    else
        -- Traditional mode
        for _, card in ipairs(self.PetCardCache) do
            if card.Name == "PetCard_" .. uniqueId then
                local nameLabel = card:FindFirstChild("NameLabel")
                if nameLabel then
                    -- Find pet data to get display name
                    local petData = nil
                    if self._dataCache then
                        local pets = self._dataCache:GetPets()
                        for _, pet in ipairs(pets) do
                            if pet.uniqueId == uniqueId then
                                petData = self._dataCache:GetPetData(pet.petId)
                                break
                            end
                        end
                    end
                    nameLabel.Text = newName or (petData and (petData.displayName or petData.name)) or "Unknown"
                end
                card:SetAttribute("PetNickname", newName or "")
                break
            end
        end
    end
end

-- ========================================
-- CLEANUP
-- ========================================

function InventoryUI:Destroy()
    -- Cancel any pending operations
    if self.SearchDebounce then
        task.cancel(self.SearchDebounce)
        self.SearchDebounce = nil
    end
    
    if self.CurrentRefreshThread then
        task.cancel(self.CurrentRefreshThread)
        self.CurrentRefreshThread = nil
    end
    
    -- Clean up all connections and objects via Janitor
    if self._janitor then
        self._janitor:Cleanup()
        self._janitor = nil
    end
    
    -- Clean up card janitors
    if self.CardJanitors then
        for _, janitor in pairs(self.CardJanitors) do
            janitor:Destroy()
        end
        self.CardJanitors = nil
    end
    
    -- Clean up virtual scrolling
    if self.ScrollConnection then
        self.ScrollConnection:Disconnect()
        self.ScrollConnection = nil
    end
    
    -- Return all active cards to pool
    for _, card in pairs(self.ActiveCards) do
        card:Destroy()  -- Destroy instead of pooling since we're shutting down
    end
    self.ActiveCards = {}
    
    -- Destroy pooled cards
    for _, card in ipairs(self.VisibleCardPool) do
        card:Destroy()
    end
    self.VisibleCardPool = {}
    
    -- Clean up effect pools
    if self.GlowEffectPool then
        self.GlowEffectPool:Destroy()
        self.GlowEffectPool = nil
    end
    
    if self.ShineEffectPool then
        self.ShineEffectPool:Destroy()
        self.ShineEffectPool = nil
    end
    
    -- Clean up watchers
    if self.PetWatcher then
        self.PetWatcher:Disconnect()
        self.PetWatcher = nil
    end
    
    -- Destroy UI
    if self.Frame then
        self.Frame:Destroy()
        self.Frame = nil
    end
    
    if self.DeleteOverlay then
        self.DeleteOverlay:Destroy()
        self.DeleteOverlay = nil
    end
    
    -- Clear cache
    self.PetCardCache = {}
    self.SelectedForDeletion = {}
end

return InventoryUI