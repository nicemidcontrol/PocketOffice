# ART_BIBLE.md — Pocket Office Visual Style Guide

> **Version:** 1.0  
> **Game:** Pocket Office (Kairosoft-style NGO simulation)  
> **Engine:** Godot 4.5 (GDScript)  
> **Target:** Mobile portrait — 390 × 844 logical pixels  
> **Art Style:** 8-bit / lo-bit pixel art, top-down office view  

---

## 1. GAME CANVAS & RESOLUTION

### Base (Logical) Resolution
- **195 × 422 px** (exactly half of 390 × 844)
- Rendered at native resolution, then scaled **×2** (integer scaling) to fill the screen
- Godot project setting: `display/window/size/viewport_width = 195`, `viewport_height = 422`
- Stretch mode: `canvas_items` | Aspect: `keep_height`
- **Why this resolution?** At ×2 scaling on 390-wide screens, every pixel is a clean 2×2 block — no sub-pixel blurring. The low resolution also forces the charming "chunky pixel" Kairosoft aesthetic naturally.

### Alternative (if 195 feels too cramped after testing)
- **260 × 563 px** (scales ×1.5 — less ideal but more screen real estate)
- **Decision rule:** Build the HQ office mockup at 195×422 first. If furniture/characters are unreadable, move to 260×563.

### Texture Import Settings (Godot)
- Filter: **Nearest** (CRITICAL — linear filtering will blur pixel art)
- Mipmaps: **OFF**
- Repeat: **Disabled** (unless tiling backgrounds)

---

## 2. GRID & TILE SIZE

| Element | Size | Notes |
|---|---|---|
| Base tile | **16 × 16 px** | Floor, walls, outdoor ground |
| Character sprite | **16 × 24 px** | 1 tile wide, 1.5 tiles tall (Kairosoft proportion) |
| Furniture / desk | **16 × 16 px** or **32 × 16 px** | Single or double-tile objects |
| Large furniture | **32 × 32 px** | Conference table, server rack |
| Item / icon | **8 × 8 px** | Inventory icons, stat icons, shop items |
| UI icon | **12 × 12 px** | HUD buttons, donor icons |
| Portrait (modal) | **32 × 32 px** | Employee detail screen, CHAMP shop |

### Spacing Rules
- Characters occupy exactly 1 tile (16×16) on the floor grid; the extra 8px height is the head/hair floating above
- Furniture snaps to 16px grid
- 1px gap between adjacent furniture (visual breathing room)

---

## 3. COLOR PALETTE

### Master Palette: 32 Colors Max (Entire Game)

Use a curated 32-color palette across ALL sprites, UI, and backgrounds. This is the single most important consistency rule.

**Recommended base:** Start from the **PICO-8 palette** (16 colors) and extend with 16 additional colors for skin tones, NGO-specific greens/blues, and UI elements.

#### Palette Categories

| Category | Colors | Purpose |
|---|---|---|
| Skin tones | 4 shades | Light, medium, tan, dark |
| Hair | 4 shades | Black, brown, blonde, red/ginger |
| Office clothes | 6 shades | Navy, grey, white, khaki, blue, green |
| NGO / nature | 4 shades | Field green, earth brown, water blue, harvest gold |
| UI elements | 6 shades | Panel navy, border blue, button highlight, text white, warning red, success green |
| Environment | 6 shades | Floor beige, wall cream, desk brown, shadow dark, window sky, outdoor grass |
| Accent / FX | 2 shades | Highlight yellow, magic/event sparkle |

#### Color Rules
- **NO pure black (#000000)** — use dark navy (#1a1a2e) instead for outlines and shadows
- **NO pure white (#FFFFFF)** — use off-white (#f0f0e8) for highlights
- **Hue-shift shadows** — shadows on red → darker red-purple, not just "add black"
- **Hue-shift highlights** — highlights on blue → lighter cyan, not just "add white"
- **Reserve full saturation** for: notification dots, event alerts, CHAMP's logo accent
- **Keep most sprites slightly desaturated** — warm, friendly, professional NGO vibe

#### Palette File
- Save as `palette_pocket_office.pal` (Aseprite) and `palette_pocket_office.png` (1px-per-color swatch strip)
- Store in `godot/assets/art/palette/`
- **Every artist (including AI tools) must sample ONLY from this palette**

---

## 4. OUTLINE & SHADING RULES

### Outlines
- **1px dark outline on ALL sprites** (characters, furniture, items)
- Outline color: NOT black — use a **darker shade of the sprite's dominant color** (colored outlines)
  - Example: Blue-shirt employee → outline in dark navy, not black
  - Example: Wooden desk → outline in dark brown, not black
- **No outlines on floor tiles or backgrounds** — outlines are for "objects that exist in the world"

### Shading
- **2-tone cel shading** (base color + one shadow tone)
- Shadow direction: **top-left light source** (shadows fall bottom-right) — consistent across ALL sprites
- NO dithering (keep it clean and simple, matches Kairosoft style)
- NO anti-aliasing on sprite edges (nearest-neighbor scaling handles this)

### Readability Rule
- Every sprite must be recognizable at **1× zoom** (the tiny native resolution)
- If a character or object is unreadable at 16px wide, simplify the design — don't add detail

---

## 5. CHARACTER SPRITES

### Proportions
- **2-heads-tall** (chibi style, Kairosoft standard)
- Head: ~8×8 px area within the 16×24 sprite
- Body: ~8×16 px area
- No visible hands at this scale — arms are 1-2px stubs
- Feet are 2px blocks

### Required Character Sprites

#### Employee (Generic Template)
Each employee needs:
| Animation | Frames | Frame Size | Notes |
|---|---|---|---|
| Idle (front) | 2 | 16×24 | Subtle breathing/blink |
| Walk (4 directions) | 4 each | 16×24 | Down, Up, Left, Right |
| Work (at desk) | 2 | 16×24 | Typing motion |
| Work (field) | 2 | 16×24 | Digging/planting motion |
| Celebrate | 3 | 16×24 | Arms up, confetti (project complete) |
| Tired / stressed | 2 | 16×24 | Slumped posture |

**Total per employee variant: ~24 frames**

#### Visual Differentiation (by role)
Since employees have Skills (Admin, Research, Fieldwork, Comms, Finance), differentiate by **clothing color**:
| Role | Outfit Color |
|---|---|
| Admin | Navy blazer |
| Research | White lab-style coat |
| Fieldwork | Green vest / khaki |
| Comms | Light blue shirt |
| Finance | Grey suit |

Hair color + skin tone create individual identity within each role.

#### CHAMP (Mascot)
- Sprite size: **24×32 px** (slightly larger than employees — he's important!)
- Distinct silhouette: top hat or bowler hat, briefcase, big grin
- Needs: Idle (2f), Talk (3f), Sell (2f), Surprise (2f)
- Color: Signature accent color (suggest: gold/yellow vest) that stands out from all employees

#### Donor Representatives (appear in donor events)
- Same 16×24 size as employees
- Distinguished by unique accessory: UN-style beret, government tie, local farmer hat, etc.

---

## 6. ENVIRONMENT / OFFICE SPRITES

### HQ Office (Main Play Area)
Top-down ¾ view (classic Kairosoft perspective — looking slightly down at ~30° angle)

#### Required Tiles & Objects
| Asset | Size | Variants |
|---|---|---|
| Floor tile | 16×16 | Office carpet, outdoor grass, path |
| Wall tile | 16×16 | Top wall (shows thickness), side walls |
| Desk | 32×16 | Employee workstation |
| Chair | 16×16 | At desk, in meeting room |
| Meeting table | 32×32 | Large, seats 4-6 |
| Bookshelf | 16×32 | Tall, against wall |
| Computer | 16×16 | On desk accessory |
| Plant pot | 16×16 | Office decoration |
| Water cooler | 16×16 | Break area |
| Whiteboard | 32×16 | Wall-mounted |
| Door | 16×16 | Entry/exit |
| Window | 16×16 | Wall segment with glass |

### Field Map Tiles (for project areas)
| Asset | Size | Variants |
|---|---|---|
| Farmland (dry) | 16×16 | Brown, cracked |
| Farmland (growing) | 16×16 | Green sprouts |
| Farmland (harvest) | 16×16 | Golden crops |
| Village hut | 32×32 | Local housing |
| Water source | 16×16 | Well, river segment |
| Road / path | 16×16 | Dirt, paved |
| Trees | 16×32 | Sparse, dense |

**Field progression:** Land tiles transition from dry → growing → harvest as project tasks complete. This is the core visual reward loop.

---

## 7. UI ELEMENTS

### HUD (Always Visible)
- Rendered at **screen resolution** (390×844), NOT at pixel-art resolution
- This means HUD is drawn at higher resolution on a separate CanvasLayer
- **Reasoning:** HUD text must be readable; 195px-wide pixel font would be too cramped for Thai/English text

### Modal Screens (BaseModal pattern)
All modals follow the established `BaseModal.tscn` standard:
- Background: Navy (#1a1a2e → matches palette dark color)
- Border: Blue (from palette)
- Buttons: Pixel-art styled but rendered at screen resolution
- Employee portraits in modals: 32×32 pixel art, scaled ×2 for display

### Icons
| Icon Type | Native Size | Display Size | Examples |
|---|---|---|---|
| Stat icon | 8×8 | 16×16 (×2) | Morale heart, skill star, money coin |
| Donor icon | 12×12 | 24×24 (×2) | FAO logo, gov building, local partner |
| Button icon | 12×12 | 24×24 (×2) | Hire, assign, shop, menu |
| Notification | 6×6 | 12×12 (×2) | Red dot, event alert |

---

## 8. ANIMATION TIMING

### Global Rules
- **Base frame duration: 150ms** (approx. 6.67 FPS for animations)
- All characters use the **same timing** for equivalent actions
- Walk cycle: 4 frames × 150ms = 600ms per cycle
- Idle blink: hold 2000ms → blink 100ms → hold 2000ms

### Timing Table
| Action | Frames | Duration/Frame | Total |
|---|---|---|---|
| Walk cycle | 4 | 150ms | 600ms |
| Idle breathe | 2 | 500ms | 1000ms |
| Work (typing) | 2 | 300ms | 600ms |
| Celebrate | 3 | 200ms | 600ms |
| Tired slump | 2 | 400ms | 800ms |
| CHAMP talk | 3 | 200ms | 600ms |

### Squash & Stretch
- Even at 16px, apply **1px compression** before a jump/celebrate and **1px stretch** at peak
- Walk cycle: slight 1px vertical bob on frames 1 and 3

---

## 9. FILE ORGANIZATION

```
godot/assets/art/
├── palette/
│   ├── palette_pocket_office.pal      # Aseprite palette
│   └── palette_pocket_office.png      # Visual swatch reference
├── sprites/
│   ├── employees/
│   │   ├── employee_admin.png         # Sprite sheet (all animations)
│   │   ├── employee_research.png
│   │   ├── employee_fieldwork.png
│   │   ├── employee_comms.png
│   │   └── employee_finance.png
│   ├── champ/
│   │   └── champ.png                  # CHAMP sprite sheet
│   ├── donors/
│   │   └── donor_rep_generic.png
│   └── furniture/
│       ├── desk.png
│       ├── chair.png
│       └── ...
├── tiles/
│   ├── office_tileset.png             # All office tiles in one atlas
│   └── field_tileset.png              # All field tiles in one atlas
├── icons/
│   ├── stats/                         # 8×8 stat icons
│   ├── donors/                        # 12×12 donor icons
│   └── buttons/                       # 12×12 UI button icons
└── ui/
    ├── modal_frame.png                # 9-slice panel border
    └── hud_elements.png               # HUD-specific graphics
```

### Naming Convention
- Lowercase, underscores: `employee_admin_walk_down.png`
- Sprite sheets preferred over individual frame files
- Format: `{category}_{variant}_{action}_{direction}.png`

---

## 10. SPRITE SHEET FORMAT

### Layout Standard
- Each sprite sheet is a **horizontal strip** of frames
- All frames in a sheet have **identical dimensions** (padded if needed)
- 0px padding between frames (Godot's AtlasTexture/AnimatedSprite2D handles frame extraction)
- Background: **transparent** (PNG with alpha)

### Example: Employee Walk Down
```
[Frame1][Frame2][Frame3][Frame4]  ← each 16×24 px
Total sheet: 64×24 px
```

---

## 11. PRODUCTION TOOLS

### Recommended
| Tool | Purpose | Cost |
|---|---|---|
| **Aseprite** | Primary sprite editor, animation, palette management | ~$20 (Steam) |
| **Libresprite** | Free Aseprite alternative | Free |
| **Piskel** | Quick browser-based prototyping | Free (web) |
| **Lospec** | Palette browser & creation | Free (web) |
| **Godot** | Preview sprites in-engine at target resolution | Free |

### Workflow
1. **Design** palette in Lospec → export `.pal`
2. **Draw** sprites in Aseprite with locked palette
3. **Export** as `.png` sprite sheets (indexed color, transparent BG)
4. **Import** into Godot → set filter to Nearest, mipmaps OFF
5. **Preview** at 195×422 viewport → verify readability
6. **Commit** to `godot/assets/art/` directory

---

## 12. QUALITY CHECKLIST (Before Committing Any Sprite)

- [ ] Uses ONLY colors from `palette_pocket_office.pal`?
- [ ] Outline uses darker hue of dominant color (not pure black)?
- [ ] Shadow falls bottom-right (top-left light source)?
- [ ] Readable at 1× native resolution (195×422 viewport)?
- [ ] Sprite dimensions match the size table in Section 2?
- [ ] Animation timing matches the timing table in Section 8?
- [ ] File named per convention: `{category}_{variant}_{action}_{direction}.png`?
- [ ] Saved as PNG with transparent background?
- [ ] Placed in correct `godot/assets/art/` subdirectory?
- [ ] Godot import: filter=Nearest, mipmaps=OFF?

---

## 13. THINGS TO DECIDE LATER (Parking Lot)

These are decisions we don't need to make now, but should revisit:

- **Exact 32-color hex values** — finalize after first prototype sprites are tested in-engine
- **Employee face variations** — how many unique faces per skin/hair combo? (suggest: 4-6 base faces)
- **Season visual changes** — do office/field tiles change per season? (placeholder system exists in HUD)
- **Weather effects** — rain overlay, sun glare (related to random events system)
- **CHAMP's exact design** — needs a dedicated concept session
- **Donor logo icons** — FAO-style vs generic symbols (copyright consideration)
- **Field map zoom level** — same pixel density as office, or separate scale?
- **Day/night lighting** — tint overlay or separate tile variants?

---

## APPENDIX A: KAIROSOFT STYLE REFERENCE NOTES

Key visual characteristics observed across Kairosoft games (Game Dev Story, Dungeon Village, Hot Springs Story, etc.):

- Characters are ~16×20 px, 2-heads-tall chibi proportion
- Top-down ¾ perspective (not pure top-down, not full isometric)
- Warm, friendly color palettes with slightly desaturated tones
- Same character bases reused across games with outfit/color swaps
- Minimal animation frames (2-4 per action) — charm comes from timing, not frame count
- Environment tiles are simple and clean — focus is on character readability
- UI overlays are rendered separately from the game world at higher resolution
- Lots of visual feedback: hearts, stars, sparkles, exclamation marks floating above characters

---

*Last updated: 2026-03-26*  
*Maintained alongside: GAME_BIBLE_v1.4.md, ECONOMY_BIBLE.md, HUMOR_NAMING_BIBLE.md*
