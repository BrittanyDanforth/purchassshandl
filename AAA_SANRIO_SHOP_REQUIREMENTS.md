# AAA SANRIO TYCOON SHOP REQUIREMENTS - NO EMOJI SPAM

## CORE REQUIREMENTS FOR PROFESSIONAL SHOP SYSTEM

### 1. VISUAL DESIGN STANDARDS
- **NO EMOJI SPAM** - Use professional icons and UI elements
- Clean, minimalist interface with subtle Sanrio theming
- High-quality asset IDs for all visual elements
- Smooth 60 FPS animations with proper easing curves
- Professional color palette: Soft pink (#FFB6C1), White (#FFFFFF), Light gray (#F5F5F5)
- Depth and shadow effects for UI elements
- Particle effects for purchases and rewards

### 2. CSGO-STYLE CASE OPENING SYSTEM

**The Rectangle Scroll Mechanism:**
```
[ITEM] [ITEM] [ITEM] [ITEM] |WINNER| [ITEM] [ITEM] [ITEM]
<----- Scrolls horizontally with deceleration ----->
```

**Technical Implementation:**
- Horizontal scrolling viewport showing 5-7 items at once
- Items scroll from right to left with physics-based deceleration
- Speed curve: Fast start (2000 units/sec) -> Medium (500 units/sec) -> Slow crawl (50 units/sec)
- Sound effects: Tick sound for each item pass, increasing pitch near end
- Visual effects: 
  - Blur on fast-moving items
  - Glow effect on rare items as they pass
  - Screen shake on legendary items
  - Particle explosion on final item

**Item Display During Scroll:**
- 3D model preview or high-quality image
- Rarity border glow (Common: gray, Rare: blue, Epic: purple, Legendary: gold)
- Item name and rarity text
- Estimated value display
- NO STATIC IMAGES - Use ViewportFrames for 3D previews

### 3. SHOP ARCHITECTURE

**Professional Category System:**
```lua
SHOP_CATEGORIES = {
    PREMIUM = {
        name = "Premium Store",
        icon = "rbxassetid://ACTUAL_ICON_ID",
        color = Color3.fromRGB(212, 175, 55)
    },
    BOOSTS = {
        name = "Power Ups",
        icon = "rbxassetid://ACTUAL_ICON_ID", 
        color = Color3.fromRGB(46, 204, 113)
    },
    GACHA = {
        name = "Mystery Boxes",
        icon = "rbxassetid://ACTUAL_ICON_ID",
        color = Color3.fromRGB(155, 89, 182)
    }
}
```

### 4. CURRENCY SYSTEM

**Three-Tier Economy:**
1. **Cash** - Basic currency from tycoon operations
2. **Gems** - Premium currency from purchases/achievements
3. **Tokens** - Prestige currency from rebirths

**Display Format:**
```
Cash: 1,234,567 (with thousand separators)
Gems: 12,345
Tokens: 123
```

### 5. ITEM CATEGORIZATION

**Gamepass Tiers:**
- **Essential Tier** (199-399 Robux): Auto-collect, 2x Money
- **Premium Tier** (499-999 Robux): VIP benefits, Exclusive areas
- **Ultimate Tier** (1499+ Robux): All benefits combined

**Boost System:**
- Time-based multipliers (5min, 15min, 1hr, 24hr)
- Stackable effects with visual indicators
- Countdown timer UI element
- Queue system for multiple boosts

### 6. GACHA/CASE SYSTEM

**Case Types:**
1. **Basic Case** - 1,000 Cash
   - 70% Common, 25% Rare, 5% Epic
   
2. **Premium Case** - 100 Gems
   - 45% Rare, 40% Epic, 15% Legendary

3. **Ultimate Case** - 500 Gems
   - 60% Epic, 35% Legendary, 5% Mythic

**Pity System:**
- Guaranteed Epic after 10 opens without Epic+
- Guaranteed Legendary after 25 opens without Legendary+
- Bad luck protection increases rates by 2% per failed attempt

### 7. UI/UX REQUIREMENTS

**Shop Layout:**
```
+--------------------------------+
|    SANRIO TYCOON SHOP          |
|  Cash: 1,234,567  Gems: 1,234  |
+--------+-----------------------+
|        |                       |
| [TABS] |    ITEM GRID VIEW    |
|        |                       |
|  Store |  [ITEM] [ITEM] [ITEM] |
|  Boost |  [ITEM] [ITEM] [ITEM] |
|  Cases |  [ITEM] [ITEM] [ITEM] |
|  VIP   |                       |
|        |    < Page 1 of 5 >    |
+--------+-----------------------+
```

**Item Card Design:**
- 200x250 pixel cards
- 3D preview or high-res image
- Price clearly displayed
- "OWNED" overlay for purchased items
- Hover effect: Scale 1.05x with shadow
- Click effect: Scale 0.95x then back

### 8. ANIMATION REQUIREMENTS

**Purchase Flow:**
1. Click item -> Card scales down
2. Confirmation popup slides in from bottom
3. On confirm -> Currency deduction animation
4. Success -> Particle burst + sound effect
5. Item flies to inventory

**Case Opening Flow:**
1. Case appears center screen
2. Click to open -> Case shakes
3. Items start scrolling (CSGO style)
4. Deceleration over 3-5 seconds
5. Winner highlighted with effects
6. Item showcase screen

### 9. SOUND DESIGN

**Required Sounds:**
- UI hover (subtle click)
- Purchase success (cash register)
- Purchase fail (error buzz)
- Case opening (dramatic buildup)
- Item scroll tick (mechanical click)
- Rare item win (achievement sound)
- Background shop ambience

### 10. DATA STRUCTURE

```lua
PlayerData = {
    currencies = {
        cash = 0,
        gems = 0,
        tokens = 0
    },
    inventory = {
        items = {},
        equipped = {}
    },
    statistics = {
        total_spent = 0,
        cases_opened = 0,
        pity_counter = 0
    },
    boosts = {
        active = {},
        queue = {}
    }
}
```

### 11. PERFORMANCE OPTIMIZATION

- Lazy load item images
- Object pooling for UI elements
- Throttle scroll events to 60 FPS
- Batch remote calls
- Cache frequently accessed data
- Use StreamingEnabled for large shops

### 12. ANTI-PATTERN WARNINGS

**AVOID:**
- Emoji in variable names or core UI
- Blocking UI animations
- Synchronous data loading
- Hard-coded values
- Single-point-of-failure systems
- Pay-to-win mechanics

**REQUIRED:**
- Professional asset management
- Smooth transitions
- Responsive design
- Error handling
- Fair monetization
- Player-first design

This is what AAA Sanrio tycoon shops need. No shortcuts, no emoji spam, just clean professional implementation with CSGO-style case openings and proper game feel.