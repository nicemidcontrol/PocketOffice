# 🎨 Pocket Office — UI Systems Bible v1.0

> Created: 2026-05-01
> Companion to `GAME_BIBLE_v1.5.2.md`
> This file is the single source of truth for **UI implementation details**: popup template, picker card, tutorial UI, inventory UI.
> Read this when implementing any visible UI element.

---

## 🎯 Purpose

`GAME_BIBLE_v1.5.2.md` defines what systems do.
This file defines what systems **look like** and how they behave at the pixel level.

---

## 📐 Global UI Constants

| Token | Value | Notes |
|-------|-------|-------|
| Viewport | 390 × 844 px | Mobile portrait, fixed |
| Modal width | 360 px | 15px margin each side |
| Modal max height | 700 px | Leaves room for top/bottom HUD |
| Card border radius | 8 px | Standard rounded corners |
| Pip radius | 4 px | SP pips, page indicators |
| Standard padding | 12 px | Inside cards, modals |
| Color: navy bg | `#1a2332` | Modal/card background |
| Color: blue border | `#3d5a80` | Standard border |
| Color: accent gold | `#ffc857` | Highlight, important number |
| Color: SP filled | `#5dcaa5` | Teal — SP available |
| Color: SP empty | `#444444` | Dark grey — SP consumed |
| Color: text primary | `#ffffff` | White on navy |
| Color: text secondary | `#9aa6b8` | Grey on navy |
| Font: standard | Pixel font (ART_BIBLE) | All UI text |
| Animation duration: standard | 200ms | Card hover, button press |
| Animation duration: pop | 400ms | Modal open/close |

---

## 🪟 Unified Popup Template

The single most reused UI element. Used for tutorials, item drops, achievements, evaluation reveals, and event notifications.

### Layout (360 × variable height)

```
┌──────────────────────────────────────────┐
│ ┌────────────────────────────────────┐   │  ← Banner (80px tall)
│ │   [TITLE TEXT — large]             │   │     navy bg, gold border
│ │   [Optional artwork — pixel sprite]│   │
│ └────────────────────────────────────┘   │
│                                          │  ← Body (variable, max 400px)
│   Body text page content                 │
│   (max 6 lines per page)                 │
│                                          │
│   Optional: icon, reward badge, value    │
│                                          │
│                                          │
│         ◄    ● ● ○    ►                  │  ← Page indicator
│                                          │     (only if multi-page)
│                                          │
│                                          │  ← Close button area
│            [ CLOSE ]                     │     (hidden until last page)
└──────────────────────────────────────────┘
```

### Component specs

| Element | Size | Notes |
|---------|------|-------|
| Banner | 360 × 80 px | Title text 20px bold gold; optional 32×32 sprite right-aligned |
| Body | 360 × ~400 px | Padding 16px each side; centered text |
| Page text | ~16 lines max per page | Word-wraps; 14px white text |
| Page dots | 8px each, 16px gap | Filled (current) / outline (others); centered horizontally |
| Arrow (◄ ►) | 16×16 sprite | Only visible if multiple pages and at first/last |
| Close button | 120 × 40 px | Centered; gold bg, navy text; **only appears on last page** |

### Behavior rules

| Action | Result |
|--------|--------|
| Tap left arrow ◄ | Previous page (if not first) |
| Tap right arrow ► | Next page (if not last) |
| Tap **anywhere on body** | Skip to **last page** |
| Tap CLOSE | Close popup, fire `popup_closed` signal |
| Tap outside popup | Close (only if all pages have been viewed at least once) |
| Tap dimmed background | Same as tap outside |

### Skip rule

The "tap-anywhere = jump to last page" gesture means players who don't want to read can immediately reveal the close button. This respects player time without removing the requirement to acknowledge the popup exists.

### Use cases

| Use case | Pages | Banner artwork |
|----------|-------|----------------|
| Tutorial popup | 1-3 | CHAMP avatar or relevant mechanic icon |
| Item drop dialogue | 2 | Field Officer portrait + funny text |
| Item obtained confirmation | 1 | Item icon centered |
| Achievement unlock | 1 | Achievement badge sprite |
| Tier promotion success | 1 | Promoted employee portrait |
| CHAMP Bulletin event | 1-2 | CHAMP newspaper graphic |
| Project complete reveal | 1 | Project area artwork |
| Final Evaluation reveal | 2 | Donor logo + village art |

---

## 🎴 Employee Picker Card

The card shown in EmployeePickerModal. Player taps a card to select an employee for the current phase.

### Layout (340 × 120)

```
┌────────────────────────────────────────────┐
│  ┌──────┐   George Anan                    │
│  │      │   PROJECT MANAGER · TIER D       │
│  │ 64×64│                                   │
│  │ Por- │   SP: ●●●●● 5/5                   │
│  │ trait│   Management ████████░░ 30/200   │
│  │      │   Focus      ███░░░░░░░ 25/150   │
│  └──────┘                                   │
│                                            │
│  Expected PLANNING contribution: ~55       │
└────────────────────────────────────────────┘
```

### Card states

| State | Visual |
|-------|--------|
| Eligible (default) | Full opacity, navy bg, blue border |
| Selected | Gold border (3px), slight scale 1.05 |
| Ineligible (low SP) | 40% opacity, red SP pips, "Needs 3 SP" tooltip on tap |
| Mismatched role (70% efficiency) | Yellow border, "70% efficiency" subtitle in body |
| Hidden | Not shown — e.g. Field Officer in PLANNING phase picker |

### Element specs

| Element | Size | Notes |
|---------|------|-------|
| Portrait | 64 × 64 px | Pixel art sprite, employee head/shoulders |
| Name | 16px bold | Humor name (large) |
| Role + Tier line | 12px secondary | "PROJECT MANAGER · TIER D" |
| SP bar | 5 pips, 12px each, 4px gap | Filled = green, empty = grey |
| Stat bar | 200 × 8 px | Bar fill = stat / ceiling; numeric label right-aligned |
| Expected contribution | 12px gold | `relevant_stat_sum` value (no multiplier shown) |

### Sort order in picker

Default: by `relevant_stat_sum` descending. Strongest match at top.

No "recommended" star, no hint indicator. Player reads the bars and decides.

### Two-stat display rule

Show **only the two stats relevant to the current phase**. Hide the other six.

- PLANNING phase → show Management + Focus
- EXECUTION phase → show Technical + Precision
- LOGISTICS phase → show Procurement + Logistics
- COMMUNITY phase → show Charm + Communication

This prevents cognitive overload and forces the player to think about phase-stat mapping (which is also taught in Tutorial #4).

---

## 🎬 Phase Animation Overlay

### Layout structure

```
┌──────────────────────────────────────────┐
│   ┌──────────────────────────────────┐   │  ← Top bar (60px)
│   │  Soil Sampling — PLANNING phase  │   │     Title + back button
│   └──────────────────────────────────┘   │
│                                          │
│                                          │  ← Office screen visible
│   [OFFICE SCREEN, BLURRED + DIMMED 60%]  │     behind, blurred
│                                          │
│   - Selected employee highlighted        │
│   - Other employees idle background      │
│                                          │
│   ┌──────────────────────────────────┐   │  ← Parameter bar (60px)
│   │  PLANNING: 27 ▌▌▌▌▌▌▌░░░         │   │     Live counter ticking up
│   └──────────────────────────────────┘   │
│                                          │
│   ┌──────────────────────────────────┐   │  ← Bottom HUD (40px)
│   │  Tap = 3x · Hold = skip          │   │     Hint, can hide
│   └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

### Tableau (1.5s opening sequence)

When the overlay drops in:

1. (0.0s) Office screen continues normally
2. (0.2s) Overlay drops down from top, dim layer fades in over 0.3s
3. (0.5s) Office screen blurs (3px gaussian) and dims to 60%
4. (0.7s) All on-screen employees turn from idle → "ready at desk" pose
5. (1.0s) Selected employee gets glow ring + nameplate floating above
6. (1.3s) "+3 SP consumed" pip animation on selected employee's card mini-icon (top of overlay)
7. (1.5s) Subtle whoosh sound + slight zoom-in on selected employee
8. (1.5s) Subround 1 begins

### Subround animation (per subround, 2s)

- Selected employee animates: typing/gesturing/drawing
- Icon emoji per parameter floats from employee → parameter bar at top
- Icons by parameter:
  - PLANNING: 📋 (clipboard)
  - EXECUTION: 🔧 (wrench)
  - LOGISTICS: 📦 (box)
  - COMMUNITY: 🤝 (handshake)
- Number on parameter bar ticks up live as icons land

### Phase Complete reveal (2s)

- Drum roll mini sound
- Final number on parameter bar emphasized: brief scale 1.2 → 1.0, gold flash
- Banner appears: "PLANNING complete: 42"
- Banner fades after 1.5s
- Cannot fully skip — peak moment

### 30s gap behavior

After phase complete:

- Overlay header bar shrinks to top 30% of screen height
- Office screen fully visible (un-blurred)
- Idle employees animate (walk, chat, use facilities)
- Selected employee returns to idle pose
- Bottom CTA: "Continue to next phase →" tap to advance immediately
- Tap = 3x speed; Hold = skip to next picker

---

## 📦 Inventory UI

Accessible from office HUD button.

### Layout (360 × 600)

```
┌────────────────────────────────────────┐
│  Inventory                       [X]   │  ← Top bar
├────────────────────────────────────────┤
│  [STAT EARNING] [PROMOTION] [USABLE]   │  ← Tab selector
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ [Icon] A Bad Book        ×3     │  │  ← Item row
│  │   +5 to one PLANNING stat       │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ [Icon] A Good Book       ×1     │  │
│  │   +15 to one PLANNING stat      │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ [Icon] Watery Coffee     ×7     │  │
│  │   +1 SP to one employee         │  │
│  └──────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### Tab categories

1. **STAT EARNING** — Books, Tools, etc. (per parameter and tier)
2. **PROMOTION** — Promo Tokens (Type A/B/C × tier)
3. **USABLE** — SP recovery, morale boost, special consumables

### Item row interaction

- Tap row → open "Use on..." modal
- Modal shows employee picker (similar to phase picker but simpler)
- Confirm → item consumed, effect applied, success popup fires

### Empty inventory

When no items in a category:
```
[Sad cardboard box icon]
"No items yet."
"Complete projects to earn rewards."
```

---

## 🎓 Tutorial Popup Behavior

Tutorial popups use the Unified Popup Template with extra rules:

### Trigger detection

Each tutorial has a **fire condition** checked by `TutorialManager`:

```gdscript
{
    "id": "tutorial_picker_first_time",
    "fire_condition": "EmployeePickerModal_first_open",
    "pages": [
        {"text": "Different phases need different specialists..."},
        {"text": "Look at the stat bars..."},
        {"text": "Selected? Press Start Work..."}
    ],
    "banner_title": "Picking Your Team",
    "banner_artwork": "champ_thumbsup.png",
    "fired": false  // becomes true after first close
}
```

### Once-only rule

- `TutorialManager` tracks `fired` flag in save file
- Each tutorial fires exactly once per save
- New game = all flags reset
- No "view again" option in MVP (post-MVP could add help menu)

### Tutorial pause

When a tutorial fires:

- Game logic pauses (no idle animations, no recurring revenue ticks)
- Resume immediately when CLOSE pressed
- Cannot be dismissed by tap-outside (must press CLOSE)

---

## 🎭 Character Customization Screen

First screen player ever sees. Pre-game state.

### Layout (390 × 844 full screen)

```
┌──────────────────────────────────────────┐
│   Welcome to your NGO                    │  ← Top title (40px)
├──────────────────────────────────────────┤
│                                          │
│   ┌────────────────────────────────┐     │
│   │      [Selected portrait]       │     │  ← Big preview (200×200)
│   │         (96 × 96 px)           │     │
│   └────────────────────────────────┘     │
│                                          │
│   ◄ [P1] [P2] [P3] [P4] [P5] [P6] ►      │  ← Portrait gallery
│                                          │     (8 portraits, 3 visible)
│                                          │
│   YOUR NAME                              │
│   ┌────────────────────────────────┐     │
│   │ George Anan_                   │     │  ← Name input (text)
│   └────────────────────────────────┘     │
│                                          │
│   YOUR NGO NAME                          │
│   ┌────────────────────────────────┐     │
│   │ Hands Across Borders_          │     │  ← NGO name input
│   └────────────────────────────────┘     │
│                                          │
│                                          │
│       [   START YOUR JOURNEY   ]         │  ← CTA button (gold)
│                                          │
└──────────────────────────────────────────┘
```

### Element specs

| Element | Size | Notes |
|---------|------|-------|
| Portrait preview | 200 × 200 | Centered, currently selected |
| Portrait gallery | 320 × 60 | 6 visible at once, scroll left/right with arrows |
| Name input | 320 × 40 | Max 20 chars |
| NGO name input | 320 × 40 | Max 30 chars |
| CTA button | 240 × 50 | Gold bg, navy bold text |

### Validation

- Empty name → CTA disabled, hint "Please enter your name"
- Empty NGO → CTA disabled, hint "Please enter your NGO name"
- Both filled → CTA enabled, glow effect

### After CTA pressed

1. Save customization to player profile
2. Fade to black (0.5s)
3. Load office screen with auto-fire Tutorial #1 ("Welcome to your NGO")

---

## 🎨 Color Palette Note

All hex values above are placeholders — final palette must come from `ART_BIBLE.md` (PICO-8 32-color palette). When implementing, replace with the closest PICO-8 mapped color:

| UI use | Placeholder | PICO-8 equiv |
|--------|-------------|--------------|
| Modal navy bg | #1a2332 | (closest dark blue) |
| Border blue | #3d5a80 | (closest mid blue) |
| Accent gold | #ffc857 | (closest yellow) |
| SP teal | #5dcaa5 | (closest teal) |

This mapping should be done as a one-time pass when the art system is integrated, not iteratively.

---

## 🔧 Implementation Notes

### Reuse principles

- **One template, many uses:** Unified Popup is built once, instantiated 7+ times across the codebase
- **One picker pattern:** EmployeePickerCard works in PhaseIntro, ItemUseTarget, RecruitConfirm
- **One overlay pattern:** PhaseAnimationOverlay's blur+dim+content stack is reused for any "modal that needs to see the office behind"

### File organization

```
godot/
  scenes/
    ui/
      BaseModal.tscn          (existing — extend for unified popup)
      UnifiedPopup.tscn       (new — extends BaseModal)
      EmployeePickerCard.tscn (new — used in modals)
      EmployeePickerModal.tscn (new — uses Cards)
      PhaseAnimationOverlay.tscn (new)
      PhaseCompleteReveal.tscn (new)
      InventoryModal.tscn     (new)
      CharacterCustomization.tscn (new)
      TutorialPopup.tscn      (extends UnifiedPopup)
  scripts/
    ui/
      BaseModal.gd            (existing)
      UnifiedPopup.gd         (new)
      ... etc
```

### Animation system

All animations use Godot's `Tween` (4.x API) for transforms and modulate. Avoid AnimationPlayer for simple effects — Tween is more flexible for state-driven UI.

### Sound hooks

Each UI interaction should have a sound effect. See `GAME_BIBLE_v1.5.2.md` §Sound Design for the full list. Key UI sounds:

- Modal open: soft whoosh
- Modal close: quick whoosh
- Page change: paper flip
- Card select: click/tap
- Phase Complete reveal: drum roll
- Tutorial complete: gentle chime

---

*UI Systems Bible v1.0 — Created 2026-05-01*
*Companion to GAME_BIBLE_v1.5.2.md. Updates to UI elements should be reflected in both files.*
