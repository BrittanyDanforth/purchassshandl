# Copyright-Safe Pet Replacement Plan

## Character Replacements (VERY SIMILAR BUT LEGALLY DISTINCT)

### 1. Hello Kitty → Kawaii Kitty
- **Original**: Hello Kitty (white cat with no mouth, red bow)
- **Replacement**: Kawaii Kitty (white cat with tiny mouth, pink ribbon)
- **Key Differences**: Has a small visible mouth, pink ribbon instead of red bow, slightly different ear shape
- **Pet IDs**: 
  - `hello_kitty_classic` → `kawaii_kitty_classic`
  - `hello_kitty_angel` → `kawaii_kitty_angel`
  - `hello_kitty_goddess` → `kawaii_kitty_goddess`

### 2. My Melody → Melody Bunny
- **Original**: My Melody (pink bunny with pink hood)
- **Replacement**: Melody Bunny (pink bunny with pink bonnet/cap)
- **Key Differences**: Bonnet instead of hood, slightly longer ears, small flower detail
- **Pet IDs**:
  - `my_melody_basic` → `melody_bunny_basic`
  - `my_melody_sweet` → `melody_bunny_sweet`

### 3. Kuromi → Kuro Bunny
- **Original**: Kuromi (white bunny with black hood, devil tail, pink skull)
- **Replacement**: Kuro Bunny (white bunny with black cap, spade tail, pink star)
- **Key Differences**: Star instead of skull, spade tail instead of devil tail, cap instead of hood
- **Pet IDs**:
  - `kuromi_basic` → `kuro_bunny_basic`
  - `kuromi_devil` → `kuro_bunny_devil`

### 4. Cinnamoroll → Cinna Puppy
- **Original**: Cinnamoroll (white puppy with long ears, cinnamon roll tail)
- **Replacement**: Cinna Puppy (white puppy with long ears, swirl tail)
- **Key Differences**: Swirl tail instead of cinnamon roll, slightly different ear proportions
- **Pet IDs**:
  - `cinnamoroll_basic` → `cinna_puppy_basic`

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