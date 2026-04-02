## 7. ART PRODUCTION WORKPLAN

### 7.1 Tool Stack

| Tool | Role | Status |
|------|------|--------|
| **Aseprite** | Primary pixel editor — palette swap, outline, polish, export | ⬜ To install |
| **PixelLab** (Aseprite plugin) | AI-assisted sprite/tile generation — first drafts | ⬜ To install |
| **itch.io asset packs** | Foundation assets — office tiles, basic furniture | ⬜ To source |

**Setup checklist:**
- [ ] Purchase/build Aseprite
- [ ] Create PixelLab account at pixellab.ai
- [ ] Install PixelLab Aseprite plugin
- [ ] Create PICO-8 palette file (.pal) in Aseprite for quick palette lock
- [ ] Test pipeline: PixelLab generate → Aseprite polish → export PNG

### 7.2 Three-Tier Production Pipeline

Every asset goes through this pipeline:
Tier 1: SOURCE          Tier 2: GENERATE         Tier 3: POLISH
itch.io asset pack      PixelLab AI gen          Aseprite final pass
(office basics)         (NGO-specific assets)    (ALL assets)
Buy pack             →  Prompt in PixelLab    →  Lock to PICO-8 palette
Extract relevant      →  Generate 10+ variants →  Add 1px dark outline
sprites               →  Pick best candidate   →  Verify pixel grid
Buy pack             ->  Prompt in PixelLab    ->  Lock to PICO-8 palette
Extract relevant      ->  Generate 10+ variants ->  Add 1px dark outline
sprites               ->  Pick best candidate   ->  Verify pixel grid
alignment (16x16 or
16x24)
Export to godot/assets/

**Rule: NO asset enters godot/assets/ without passing Tier 3 (Aseprite polish).**

### 7.3 Asset Priority Order

#### Phase 1: UI Elements (CURRENT PRIORITY)
| Asset | Size | Count | Source |
|-------|------|-------|--------|
| Button frames (normal/pressed/disabled) | 80x24 px | 3 | PixelLab |
| Icon: Cash/Money | 16x16 px | 1 | PixelLab |
| Icon: Corporate Points | 16x16 px | 1 | PixelLab |
| Icon: Motivation | 16x16 px | 1 | PixelLab |
| Icon: Skill | 16x16 px | 1 | PixelLab |
| Icon: Clock/Time | 16x16 px | 1 | PixelLab |
| Icon: Employee roles (x5) | 16x16 px | 5 | PixelLab |
| Modal frame / card BG | 9-slice | 1 | PixelLab |
| Tab / category selector | 48x16 px | 1 | PixelLab |
| Progress bar (frame + fill) | 64x8 px | 2 | PixelLab |
| CHAMP shop portrait | 32x32 px | 1 | PixelLab + Aseprite |
| **Phase 1 Total** | | **~18** | |

#### Phase 2: Office Tiles & Furniture
| Asset | Size | Count | Source |
|-------|------|-------|--------|
| Floor tiles (x3 variants) | 16x16 px | 3 | itch.io pack |
| Wall tiles (x2 variants) | 16x16 px | 2 | itch.io pack |
| Desk, Chair, Computer, Filing cabinet | 16x16 px | 4 | itch.io pack |
| Water cooler, Whiteboard, Photocopier | 16x16 px | 3 | PixelLab |
| **Phase 2 Total** | | **~12** | |

#### Phase 3: Characters (Employee Sprites)
| Asset | Size | Count | Source |
|-------|------|-------|--------|
| Base body (x2 genders) idle | 16x24 px | 2 | PixelLab |
| Walk animation (4f x2 dir x2 genders) | 16x24 px | 8 | PixelLab |
| Role uniform variants (x5 roles x2) | 16x24 px | 10 | PixelLab |
| Burnout overlay + Fever Mode glow | 16x24 px | 2 | Aseprite |
| Derek Anan Boonphun (hero) | 16x24 px | 1 | PixelLab + Aseprite |
| **Phase 3 Total** | | **~23** | |

#### Phase 4: Facilities & Buildings
| Asset | Size | Count | Source |
|-------|------|-------|--------|
| Training Room, Meeting Room, Break Room | 32x32 px | 3 | PixelLab |
| Server Room, Research Lab, Reception | 32x32 px | 3 | PixelLab |
| CHAMP Shop exterior | 32x32 px | 1 | PixelLab + Aseprite |
| **Phase 4 Total** | | **~7** | |

#### Phase 5: Effects & Misc
| Asset | Size | Count | Source |
|-------|------|-------|--------|
| Floating text (+Cash, +CP) | spritesheet | 1 | Aseprite |
| Sparkle/completion effect (4f) | 16x16 px | 1 | Aseprite |
| Fever Mode fire aura (4f) | 32x32 px | 1 | Aseprite |
| Event notification icon | 16x16 px | 1 | PixelLab |
| CHAMP logo | 32x32 px | 1 | PixelLab + Aseprite |
| **Phase 5 Total** | | **~5** | |

### 7.4 PixelLab Prompt Guidelines

Always include in prompts:
- "pixel art, 16x16" (or 16x24 for characters)
- "office theme, warm lighting"
- "clean pixel grid, no anti-aliasing"
- "limited color palette, 32 colors max"

**Post-generation Aseprite checklist:**
- [ ] Resize canvas to exact target size
- [ ] Apply PICO-8 palette remap
- [ ] Add/fix 1px dark outline (darkest adjacent color)
- [ ] Verify no sub-pixel artifacts or anti-aliasing
- [ ] Export as PNG with transparency
- [ ] Save .aseprite source to godot/art_source/
- [ ] Export final PNG to godot/assets/sprites/

### 7.5 File Organization
godot/
assets/
sprites/
ui/           <- buttons, icons, frames, progress bars
tiles/         <- floor, wall, decorative tiles
characters/    <- employee sprites + animations
facilities/    <- room/building sprites
effects/       <- particles, overlays, floating text
art_source/        <- .aseprite source files (NOT exported PNGs)
ui/
tiles/
characters/
facilities/
effects/
