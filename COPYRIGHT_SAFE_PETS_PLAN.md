# Copyright-Safe Pet Replacement Plan

## Character Replacements

### 1. Hello Kitty → Kawaii Cat
- **Original**: Hello Kitty (white cat with red bow)
- **Replacement**: Kawaii Cat (cute white cat with pink flower accessory)
- **Pet IDs**: 
  - `hello_kitty_classic` → `kawaii_cat_classic`
  - `hello_kitty_angel` → `kawaii_cat_angel`
  - `hello_kitty_goddess` → `kawaii_cat_goddess`

### 2. My Melody → Sweet Bunny
- **Original**: My Melody (pink bunny with hood)
- **Replacement**: Sweet Bunny (pink bunny with flower crown)
- **Pet IDs**:
  - `my_melody_basic` → `sweet_bunny_basic`
  - `my_melody_sweet` → `sweet_bunny_magical`

### 3. Kuromi → Punk Bunny
- **Original**: Kuromi (white bunny with devil theme)
- **Replacement**: Punk Bunny (white bunny with punk rock theme)
- **Pet IDs**:
  - `kuromi_basic` → `punk_bunny_basic`
  - `kuromi_devil` → `punk_bunny_rockstar`

### 4. Cinnamoroll → Cloud Puppy
- **Original**: Cinnamoroll (white puppy with long ears)
- **Replacement**: Cloud Puppy (fluffy white puppy with wings)
- **Pet IDs**:
  - `cinnamoroll_basic` → `cloud_puppy_basic`

## UI Text Changes

### Remove all "Sanrio" references:
- "SanrioTycoonUI" → "KawaiiPetTycoonUI"
- "Sanrio Tycoon" → "Kawaii Pet Tycoon"
- "SanrioTycoonClient" → "KawaiiPetClient"
- "SanrioTycoonServer" → "KawaiiPetServer"

## Asset Changes Required

1. Replace all character images with original artwork
2. Change color schemes slightly to differentiate
3. Remove any trademarked symbols (red bow, pink hood, etc.)
4. Create new logo without Sanrio branding

## Code Changes

1. Update PetDatabase.lua with new names and IDs
2. Update all UI references
3. Update server/client module names
4. Update configuration files
5. Update any hardcoded pet references