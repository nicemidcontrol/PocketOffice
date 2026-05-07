# Throwaway Prototype — v1.5.2 Phase Animation Loop

**Branch:** `prototype/v152-phase-loop-throwaway`  
**Purpose:** Fun-test the core phase animation loop before committing to full v1.5.2 migration.  
**Not for integration.** Delete this directory after the fun-test is done.

---

## How to run

1. Open the project in Godot 4.5: `File → Open Project → godot/`
2. In the FileSystem panel: navigate to `prototype/PrototypeMain.tscn`
3. Press **F6** (Run Current Scene)

That's it. No autoloads. No save file. No existing managers touched.

---

## Controls

| Input | Effect |
|-------|--------|
| **SELECT button** | Pick an employee to work the current phase |
| **Tap / Left-click** | 3x speed during animations |
| **Continue button** | Advance from phase gap to next phase |
| **R** | Restart the whole task from scratch |

---

## What you're playing through

One fake task: **"Soil Sampling Survey"**  
Three phases in sequence: **PLANNING → EXECUTION → LOGISTICS**

Each phase:
1. **Picker** — choose one of the 3 fake employees (George PM / Sarah Field / Tom Supply)
2. **Tableau** (1.5s) — selected employee gets highlighted, glow ring appears
3. **3 Subrounds** (2s each, 5s gap between) — floating icon animates from employee → parameter bar; score ticks up
4. **Phase Complete reveal** (2.5s) — cannot skip this moment
5. **Phase Gap** (30s, or tap Continue) — office "rests"

After all 3 phases: **Task Complete** screen with scores and a grade (F → S).

---

## Fake employees

| Name | Role | Tier | Best at |
|------|------|------|---------|
| George Anan | Project Manager | D | PLANNING (management+focus) |
| Sarah Oduya | Field Officer | D | EXECUTION (technical+precision) |
| Tom Supasit | Supply Officer | D | LOGISTICS (procurement+logistics) |

Each employee has 5 SP. Each phase costs 3 SP.  
Same employee **cannot work two phases** of the same task.

---

## What to evaluate (Dos's checklist)

- [ ] Does the picker-to-tableau transition feel snappy enough?
- [ ] Is 1.5s tableau too long, too short, or just right?
- [ ] Do the 5s subround gaps feel restful or boring?
- [ ] Does the 30s phase gap feel like a natural breath, or does it drag?
- [ ] Is "tap = 3x / hold = skip" discoverable from the hint text alone?
- [ ] Does the Phase Complete reveal feel like a satisfying payoff?
- [ ] Is the 3-SP-per-phase cost legible without explanation?
- [ ] Does the final grade screen feel rewarding?
- [ ] Would you naturally want to play a second task immediately after?
- [ ] Any moment that felt confusing without tutorial text?

---

## What is NOT prototyped here

- Art (all placeholder color blocks)
- Sound
- Blur/dim overlay on office area
- Animated employee sprites
- Real stat values from save data
- Tutorial popups
- Item use
- SP recovery mechanic

These are all confirmed design features — this prototype only tests timing and flow.

---

## Cleanup

After Dos has playtested and given feedback, this entire `prototype/` directory can be deleted.  
Nothing in it is wired to the main game.
