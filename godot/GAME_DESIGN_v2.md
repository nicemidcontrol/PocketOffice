# GAME_DESIGN_v2.md — Reward Loop & Economy Redesign

> **Status:** 🔒 **v2.0 LOCKED** — Design proposal frozen until Sharpen the Tools Plan completes
> **Created:** After PR #121 (CP signal consistency fix) — during "Sharpen the Tools Plan"
> **Prerequisite:** Complete Sharpen the Tools Plan before implementation
> **Related bibles:** GAME_BIBLE_v1.4.md, ECONOMY_BIBLE.md, HUMOR_NAMING_BIBLE.md, WORK_ROUND_SYSTEM.md
>
> **LOCK RULES:**
> - New design ideas → log in `NOTES.md`, NOT in this doc
> - Bug fixes / typos in this doc → allowed (minor updates)
> - Section-level additions → forbidden until v2.1 (post-Sharpen Tools)
> - Implementation PRs may reference this doc but must not rewrite sections

---

## 1. Problem Statement

Current state of the game:
- Work Round completion feels **flat** — grade + stat gain + money reward, but no "juice"
- **Default grade = C** because most tasks are started with 2 employees instead of 3
- Player doesn't feel **incremental satisfaction** from grinding (training, unlocks, etc.)
- Economy **goes negative** when player is idle — breaks Kairosoft-style session re-entry
- No **teaching/news/event system** to force interaction and pull player back into the game

---

## 2. Core Design Decisions (confirmed with Dos)

### 2.1 Play Style: **Hybrid (idle-tolerant + active reward)**

**Intent:** When player opens the main screen without pressing anything:
- Employees sit at their desks (visible idle state)
- Occasionally walk around, use facilities, or talk to each other
- Passive actions generate **small** amounts of CP, stat gains, or morale

**Design principles:**
- Idle rewards are **real but minimal** — must not replace active play
- Idle animations are **visible but subtle** — should not distract from core loop
- Animations trigger **occasionally** (~20–30% probability per `work_day_started` tick), not constantly
- Reward magnitudes: +1–3 CP, +0.5–1 stat, +1–2 MOT per idle event
- Multiple employees idle at once should NOT stack probabilistically into spam

### 2.2 Event Frequency: **Medium (~every 5–10 rounds)**

**Intent:** Events appear regularly but do not interrupt flow excessively.

**Emphasis on:**
- News prompts
- System updates (unlocks, milestones)
- Teaching/tutorial reminders
- Donor communications

**Design principles:**
- Events **pause gameplay** until dismissed — forces engagement
- Events have **categories** for weighted rotation (see §4)
- Repeated events blocked within a rolling window to avoid boredom

### 2.3 Economy Difficulty: **Forgiving with consequence**

**Intent:**
- Passive state should not drive money negative at baseline
- When money DOES go negative: **CHAMP emergency bailout** (one-time event)
- After bailout is used: player must manually recover (fire employees, restructure)
- No second bailout — creates real stakes without game-over

---

## 3. Reward Loop — 4-Layer Model

Inspired by Kairosoft's "Game Dev Story" layering.

### Layer 1 — Juice (immediate feedback, per action)

Currently missing. Highest ROI for "game feel."

| Element | Current | Proposed |
|---------|---------|----------|
| SFX on button press | None (placeholder) | Distinct sound per action (start work, train, donor pitch) |
| Grade reveal sound | Generic | Unique per grade (S = fanfare, F = sad trombone, etc.) |
| Reward display | Static number appears | **Counter tick-up animation** (`$0 → $15 → $30 → $45`) |
| Stat gain text | Plain line | Gold glow + small particle effect |
| S/A grade celebration | Static letter | Screen shake + confetti particles |

**Implementation notes:**
- SFX: use bfxr.net for placeholders, Suno.ai for final BGM
- Animations: Godot Tween for counters; CPUParticles2D for simple effects
- Avoid over-juicing — keep under 1.5s per feedback cycle

### Layer 2 — Skill Progression (already exists; needs emphasis)

Stats grow slowly (+1, +2 per round). Make growth **felt**.

| Element | Current | Proposed |
|---------|---------|----------|
| Stat value | Shown at 0–1000 scale | Add **tier titles**: Novice (0–249) → Adept (250–499) → Expert (500–749) → Master (750–1000) |
| Threshold crossing | Silent | Celebration popup: "George reached Adept in Charm!" |
| Round-over-round comparison | None | "+15% vs last round — Best yet!" text |
| Streak rewards | None | 3 × A+ rounds in a row → bonus CP/reputation |

### Layer 3 — Task/Project Completion

Currently: "+10 CP bonus!" text. Flat.

Proposed additions when a task completes:
- **News flash banner**: "NGO completes 'Village Needs Assessment' — local media coverage (+5 Reputation)"
- **Flavor email** from the client/donor: "The village chief sends a thank-you letter" (unlocks a lore snippet + small bonus)
- **Monthly/yearly milestones**: "5 tasks completed this month — team motivation boost!"
- **Donor reactions**: "The Ford Foundation noticed your work — unlocks Tier 2 donor options"

### Layer 4 — Long-term (every hour of play)

Kairosoft's secret: the "ah-ha" unlock every hour.

Proposed unlocks tied to play duration / milestones:
- **Office upgrade** every Y1, Y2 — expand room, more desks, new facility
- **New role unlock** at Year 2 → "Senior Manager" (higher stat caps)
- **Specialty training** after stat thresholds → advanced training options
- **Region/donor tiers**: Tier 1 (Local) → Tier 2 (National) → Tier 3 (International/UN)
- **Lore unlocks**: working with CHAMP uncovers backstory of the monopoly megacorp

---

## 4. Event System Design

### 4.1 Foundation

**Existing infrastructure to reuse:** `CHAMPBulletinManager.gd` already has event-like patterns (bulletins, mitigation options). Design should extend this rather than replace.

### 4.2 Event Categories

Tag each event with a category for weighted rotation:

| Category | Purpose | Example |
|----------|---------|---------|
| `teaching` | Explains a game mechanic | "Training explained: try training George to boost Communication" |
| `news` | Flavor + world-building | "Local newspaper features your NGO work" |
| `crisis` | Forces a hard decision | "Donor withdrew — $2,000 shortfall next month" |
| `opportunity` | Positive branching choice | "Government offers partnership — quarterly reports required" |
| `flavor` | Pure atmosphere | "Intern made coffee for everyone (+1 MOT)" |

### 4.3 Trigger Logic

```
Every N rounds (or N in-game days):
  if no event triggered in last M rounds:
    weight = category_weights[game_state]  // early/mid/late/crisis
    select random event from pool where:
      - category matches current weight bias
      - event.id not in recent_events[last 10]
      - event.prerequisites are met
    show blocking popup
    record event.id in recent_events
```

### 4.4 Weight Scaling by Game State

| Game State | Bias Toward |
|-----------|-------------|
| Early game (Year 1) | `teaching` (70%), `flavor` (20%), `news` (10%) |
| Mid game (Year 2+) | `opportunity` (40%), `news` (30%), `teaching` (15%), `flavor` (15%) |
| Late game | `opportunity` (35%), `crisis` (30%), `news` (25%), `flavor` (10%) |
| Low cash / low MOT | `crisis` (60%), `opportunity` (30%), `teaching` (10%) |

### 4.5 Example Events (not exhaustive)

**Teaching:**
- "Your first donor offers $1,000 — accept as unrestricted or restricted grant?"
  - Unrestricted: +$1,000 now
  - Restricted: +$2,000 (must spend on a specific program within N rounds)

**News:**
- "A local blog wrote about your work! (+3 Reputation)"
- "International NGO network invites you to a conference"

**Crisis:**
- "Employee George is burned out — motivation dropped 50%. Give time off or push through?"
- "Corruption scandal at nearby NGO — reputation at risk by association"

**Opportunity:**
- "Volunteer wants to join — free labor but all stats at 200"
- "Media wants to interview — +Reputation but 1 employee out of commission for this round"

**Flavor:**
- "The office printer broke. CHAMP refuses to fix it." (no mechanical effect, just humor)

---

## 5. Idle Activity System

### 5.1 Core Loop

```
On work_day_started tick:
  for each idle employee at desk:
    if random(0.0, 1.0) < 0.25:   // 25% chance, tunable
      trigger idle activity
```

### 5.2 Activity Types

| Activity | Animation | Reward |
|----------|-----------|--------|
| Use coffee machine | Walk to coffee → sip → walk back | +1 MOT |
| Read paperwork | Sit, shuffle papers | +0.5 stat (random stat) |
| Chat with coworker | Walk to coworker → talk bubble | +1 MOT for both, 5% chance +1 CP (idea spark) |
| Use facility (printer, whiteboard) | Walk to facility → use → return | +1–2 CP |
| Daydream | Sit still with thought bubble | No reward, pure flavor |

### 5.3 Constraints

- Animation duration: **2–4 seconds** each
- Only **1 idle activity per employee per tick** (no stacking)
- Activities **do not pause gameplay** — they run as background detail
- If work round starts while animation is playing, animation cancels gracefully
- Low CPU cost — sprite tween + simple state machine, not pathfinding

---

## 5.5 Weekly Cycle System

### 5.5.1 Core Concept

Every **5 work rounds = 1 week**. At the end of each week, a scripted animation plays showing employees leaving the office, followed by a light progress summary, then morning returns and play resumes.

**Inspired by:** Kairosoft's Boxing Academy (facility go-home rhythm), applied to Pocket Office's project-based structure (Game Dev Story core).

**This is decoupled from the monthly salary/calendar logic:**
- **Weekly** = visual rhythm + light progress recap (no salary, no events)
- **Monthly** = existing calendar system (salary deduction, events can trigger here)

### 5.5.2 Trigger

```
On work_round completion:
  increment weekly_round_counter
  if weekly_round_counter == 5:
    reset weekly_round_counter to 0
    trigger weekly_cycle_sequence()
```

**Auto-trigger only** — no manual "End Week" button.

### 5.5.3 Sequence (normal speed)

| Step | Duration | Visual |
|------|----------|--------|
| 1. Sunset tint begins | ~1.0s | Background gradient: normal → orange/pink |
| 2. Employees walk out | ~2.0s | Sprites move from desks → exit point |
| 3. Office dark + autosave | ~0.5s | Screen fades darker; silent autosave runs |
| 4. Weekly Summary modal | user-paced | See §5.5.5 for content |
| 5. Morning transition | ~1.0s | Gradient: dark → normal |
| 6. Employees walk in | ~2.0s | Sprites move from entry point → desks |
| 7. Resume gameplay | — | Round 6 ready |

**Total animation time:** ~6.5s + summary reading time.

### 5.5.4 Tap-to-speed Mechanic

- **Default speed:** 1.0x
- **Tap screen:** animation speed → 3.0x (reduces total animation to ~2s)
- **Hold:** skip to next step (e.g., skip animation to summary; skip summary to morning)
- **Cannot fully skip the weekly cycle** — player must at minimum see the summary

**No dedicated skip button.** Tap anywhere is the gesture.

### 5.5.5 Weekly Summary Modal (C4 decision)

Modal appears AFTER the go-home animation completes (during the "dark" phase).

**Content displayed:**

| Row | Example |
|-----|---------|
| 💰 Earnings this week | `+$450 (from 3 completed tasks)` |
| 📊 Stat changes per employee | `George: Charm +3, Management +2` |
| 📊 Stat changes per employee | `Erik: Charm +2, Finance +1` |
| 🎯 Tasks completed | `3` |
| 💡 MOT change | `+15% (now at 68%)` |

**Display rules:**
- **Show only stats that CHANGED** — do not list unchanged stats (C2 decision)
- **Order employees** by stat change magnitude (most improvement first) for visual reward
- **No salary line** — salary is monthly, not weekly
- **No event triggers** — events use their own system (§4)
- **No major milestones** — milestone celebrations stay monthly

**Controls:**
- Tap screen: speed up text rendering (3.0x)
- "CONTINUE" button: dismiss modal, proceed to morning transition
- Cannot skip modal entirely (player must acknowledge)

### 5.5.6 Autosave Timing

- Autosave triggers during the "dark" phase (step 3 in §5.5.3)
- **Silent** — no "Saving..." indicator shown
- If save fails: log to console, do not block gameplay
- One autosave per weekly cycle

### 5.5.7 Integration with Other Systems

| System | Interaction |
|--------|-------------|
| Work Round | Counter increments on round completion |
| Monthly Calendar | Unaffected — W/M/Y tracker ticks independently |
| Salary | Unaffected — deducts on month boundary, not week |
| Event System (§4) | Events do NOT trigger during weekly cycle |
| Idle Activities (§5) | Paused during go-home/morning animation |
| MOT System | Changes accumulated during week are summarized in modal |
| CHAMP Bailout (§6.3) | Triggered on cash < 0 detection, not tied to weekly cycle |

### 5.5.8 Constraints

- Animation CPU cost: low (sprite tweens, no particle overload)
- Summary modal must work on 390×844 portrait layout
- Go-home exit point and entry point are fixed scene positions (design in implementation phase)
- Tint transitions must not cause flicker on mobile refresh rates

### 5.5.9 Explicitly NOT in scope for Weekly Cycle

- ❌ Salary payment
- ❌ Event triggering
- ❌ Project/Area unlocks
- ❌ Donor activity
- ❌ CHAMP interactions
- ❌ "Game over" checks (handled monthly)

---

## 6. Economy Rebalance

### 6.1 Baseline Invariant

**Rule:** At any stable state (no player action), `monthly_net_cash >= 0`.

Formula:
```
monthly_net_cash = baseline_donor_income
                 - total_employee_salaries
                 - office_rent
                 - misc_fixed_costs

Must be >= 0 at the default game starting state.
```

### 6.2 Game State Tiers

| Tier | Definition | Behavior |
|------|-----------|----------|
| Healthy | Cash > 1 month of expenses | Normal gameplay |
| Warning | Cash < 1 month of expenses | HUD warning icon appears |
| Critical | Cash < 0 | Trigger CHAMP bailout (if unused) OR force action popup |
| Bankrupt | Cash < 0 after bailout used | Force player to fire employees / take drastic action |

### 6.3 CHAMP Emergency Bailout

**First-time trigger:**
- Player cash goes below $0 for the first time
- CHAMP popup appears with cinematic framing
  - Copy suggestion: "Hey. You look a bit troubled. Here's enough to keep the lights on. But I can only do this **once** — don't come back to me crying about it again."
- Player receives bailout amount (e.g., enough to cover 1 month baseline)
- Save flag `champ_bailout_used = true` is set permanently

**Subsequent cash < 0:**
- Popup: "You're broke again. CHAMP just laughs. You need to cut costs — fire employees, reduce overhead, or face bankruptcy."
- No auto-bailout
- Game continues but warns player of imminent bankruptcy after N months

**Display:**
- In the stats/menu screen, show: `CHAMP Bailout: Used (cannot use again)` or `Available`

### 6.4 Save/Load Considerations

- `champ_bailout_used` must be persisted in save file
- Reload should not reset the flag
- New game resets the flag

---

## 7. Implementation Phases

### Phase 0 — Complete Sharpen the Tools Plan (CURRENT, NOT DESIGN WORK)

- PR-3D: CP flow tests (integration)
- Fever Mode tests
- GitHub Actions CI
- (Optional) WorkRoundResult timing fix (already on branch `claude/fix-work-result-delay-lWfnK`)

### Phase 1 — Economy Diagnosis & Baseline Fix

1. Recon entire economy flow (income sources, expense sources)
2. Reproduce cash-negative bug deterministically
3. Establish baseline invariant (per §6.1)
4. Write unit tests for economy math (after refactor if needed)

### Phase 2 — Event System Foundation

1. Review existing `CHAMPBulletinManager.gd` patterns
2. Design event data format (dict → parseable, saveable)
3. Implement event trigger manager with category weighting
4. Implement blocking popup UI (reuse BaseModal pattern)
5. Write a small seed pool of events per category

### Phase 3 — CHAMP Emergency Bailout

1. Add `champ_bailout_used` flag to save system
2. Hook cash < 0 detection into event manager
3. Build cinematic CHAMP popup (reuse existing CHAMP assets)
4. Test first-time vs subsequent behavior

### Phase 4 — Idle Activity System

1. Define activity data (animation refs, reward amounts, probabilities)
2. Implement activity picker on `work_day_started`
3. Animate sprites using Godot Tween / AnimationPlayer
4. Hook rewards into existing `add_corp_points`, stat gain, MOT systems

### Phase 4.5 — Weekly Cycle System

1. Implement weekly round counter (resets every 5 rounds)
2. Sunset/morning tint gradient transitions (Godot ColorRect + Tween)
3. Employee go-home / walk-in sprite animations (position tweens to exit/entry points)
4. Autosave hook during "dark" phase
5. Weekly Summary modal UI (reuse BaseModal pattern)
6. Track per-employee stat diffs during week; show only changed stats in summary
7. Tap-to-speed gesture (tap anywhere → 3.0x animation; hold → skip to next step)
8. Integration testing: verify no interaction with monthly salary, events, or CHAMP bailout

### Phase 5 — Juice Pass

1. SFX pass (bfxr.net for placeholders)
2. Counter tick-up animations for all number displays
3. Particle effects on grade reveals, stat gains
4. Screen shake on S-grade, task completion
5. Grade-specific flourishes

### Phase 6 — Skill Tier Titles & Milestones

1. Tier title logic (Novice → Adept → Expert → Master)
2. Threshold crossing celebration popups
3. Round-over-round comparison text
4. Streak tracking and bonus reward

### Phase 7 — Long-term Unlocks

1. Office upgrade system (desks, facilities)
2. New role unlocks
3. Donor tier progression
4. CHAMP lore unlocks

---

## 8. Open Questions (to resolve before implementation)

1. **Idle activity visibility**: do we need new sprite animations per activity, or can we reuse existing employee sprites with simple position tweens?
2. **Event UI**: reuse BaseModal or build dedicated `EventPopup.tscn`?
3. **Save migration**: adding `champ_bailout_used` requires bumping save version — handle backward compat how?
4. **Balance numbers**: exact values for baseline_donor_income, salary costs, bailout amount — needs playtesting data
5. **Teaching events and existing tutorial system**: do we have one? If yes, integrate; if no, this IS the tutorial
6. **Streak bonus**: should it reset on ANY non-A+ grade, or allow 1 B grade before breaking?
7. **Office upgrades unlocking by year vs. by money spent**: which feels better?
8. **Weekly cycle vs. monthly calendar alignment**: 5 rounds = 1 week; does the existing M/Y calendar advance based on real-time ticks, work_rounds, or weekly cycles? Must not cause salary timing to misalign with player expectation.
9. **Weekly summary scope on long sessions**: if player completes 20+ rounds in one sitting, do 4 summary modals in a row become fatiguing? Consider condensing rule if weekly triggers back-to-back.
10. **Employee sprite exit/entry positions**: where in the scene do sprites walk to/from? Needs scene design pass during Phase 4.5.

---

## 9. Out-of-Scope (explicitly NOT in this design)

- Multiplayer / online features
- Mobile-specific UI adaptations (already in GAME_BIBLE; not changing)
- Art pipeline changes (ART_BIBLE governs that)
- Any change to the 8-stat / 5-role system
- Any change to the Area → Project → Task hierarchy
- Any change to Work Round core mechanic

---

## 10. Discipline Reminders

- **One scope per PR** — each phase is its own PR (or PR chain)
- **Test before refactor** — every phase adds tests before implementation
- **Bible updates** — when mechanics change, update GAME_BIBLE_v1.4 (or successor) in the same PR
- **No mid-task pivots** — if a new design idea appears mid-implementation, log it in a "future work" section of this doc, do not implement it

---

## Appendix A — Reference: Kairosoft Patterns Observed

### Pocket Office's Hybrid Identity

Pocket Office deliberately blends two Kairosoft archetypes:

- **Core loop:** "Game Dev Story" model — **project-based**, `Area → Project → Task` hierarchy, Work Round system, grade reveals that parallel game-review scores
- **Visual rhythm:** "Boxing Academy" model — **facility-based visual life**, employees visible at desks, go-home/return cycle, walking animations that give the office "life"

This hybrid is a deliberate differentiator. Most project-management games are "spreadsheet simulators" with no visible life; most facility games lack the ambitious project arc. Pocket Office aims to be "Game Dev Story with visible humans in a real office."

### Specific patterns referenced

- **"Game Dev Story" teaching popups** — new employee, new console, new genre events force reading + decision
- **"Game Dev Story" review score reveals** — full-screen overlay + sound effect + score counter tick-up
- **"Boxing Academy" go-home cycle** — employees visibly leaving at end-of-period; creates natural session pacing
- **Kairosoft idle animations** — coffee, talking, facility use happen constantly but at low volume — creates "life" without replacing core gameplay
- **Kairosoft money warnings** — escalate through tiers before game-over; player is never surprised
- **Kairosoft session re-entry** — leaving the game idle returns you to a viable state, not a broken one; Pocket Office's CHAMP bailout is our version of this safety net

## Appendix B — Implementation Risk Notes

- **Idle animations can tank performance** on mobile — must profile
- **Event popups interrupt flow** — placement of trigger must respect player agency (never during a round)
- **CHAMP bailout is emotional design** — copy must land right, playtest copy before committing
- **Save file format changes** are risky — always add migration path, never break existing saves
