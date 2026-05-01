# 📋 Pocket Office — Game Bible v1.5.2

> Last updated: 2026-05-01
> **MAJOR REVISION** — supersedes v1.4. Pivots the core loop from Work Round + Grade to Phase Animation + Parameter Accumulation.
> v1.5.2 update (from v1.5.1): Added Character Customization, Starter Setup, 1-person-per-phase rule, Tutorial System, Tier Promotion System, and Item System. UI implementation details split into companion file `UI_SYSTEMS_BIBLE.md`.
> This file is the single source of truth for **design**. UI specifics live in `UI_SYSTEMS_BIBLE.md`.

---

## 🚨 What Changed from v1.4 (TL;DR)

| System | v1.4 | v1.5 |
|--------|------|------|
| Core mechanic | Work Round (press START → grade reveal) | Phase Animation (select task → pick employee per phase → 3 subrounds → params accumulate) |
| Player flow | Assign staff → start work | **Select task FIRST → then pick employee per phase** |
| Grade system | S / A / B / C / D / F | **REMOVED** — uncapped parameter numbers |
| Task structure | Single stat-based attempt | 3-4 Phases per task, each with own parameter |
| Reward shape | One-time payout | Recurring revenue (6 in-game months) + Final donor lump sum |
| Stamina | Energy stat (loose) | **NEW** — explicit SP system, employees recover over weekly cycle |
| Failure | Project < 70% = failed | **REMOVED** explicit fail; soft-fail through economy (low totals = breakeven = no growth) |
| Parameters | None | **NEW** — 4 parameters: PLANNING / EXECUTION / LOGISTICS / COMMUNITY |
| Picker UI | Stat number list | Portrait + relevant stat bars + SP pips, no recommendation hints |
| Active player time per task | ~10 sec (one button press) | ~1.8–2.6 minutes (multi-phase decisions) |

**Why this pivot:** First playthrough revealed the v1.4 loop is mechanically working but emotionally flat. v1.5 borrows Game Dev Story's hybrid identity: project-based active loop (pick contributors per phase, watch contribution icons fly) + facility-based ambient life (idle activities during gaps).

---

## 🎯 Core Vision (unchanged)

**One-line pitch:**
> "The office simulation game that finally *gets* what it's actually like to work in an NGO — and lets you run one."

**Target player:** Working professionals 25–40 who want a relatable, satisfying management sim with real-world meaning behind every decision.

**Price:** Premium $4.99 — no ads, no pay-to-win.

**Hidden educational goal:** Teach players how an NGO operates — cross-team cooperation, procurement, operations, secretarial, and management roles each matter. Donors are not revenue — they are mission-enablers. Player learns this by playing, not by reading.

**Motto:** *Simple but Deep.* Small ruleset, large decision space.

---

## 🌍 Mission & World (unchanged)

**Your NGO's mission:** "End World Hunger"

5 geographic scales = 5 campaign chapters. As your NGO completes work, the world visually transforms.

| Scale | Projects Required | Visual Change | Office Tier |
|-------|------------------|---------------|-------------|
| 1. Local | 3 projects | Barren land → small crops | Small rented office |
| 2. Region | 7 projects | Scattered farms → organized fields | Bigger city office |
| 3. Country | 12 projects | Green countryside, markets appear | National HQ |
| 4. Regional | 24 projects | Cross-border farmland, roads built | Regional HQ |
| 5. World | 36 projects | Global impact map | World HQ |

Total projects across full campaign: 82.

**Office Relocation:** When all projects in a scale reach completion, NGO upgrades office to next scale. One-time Cash + CP cost. All employees and facilities move with the office.

---

## 🔁 Core Game Loop

### Macro view (one task lifecycle)

```
Active play (1.8–2.6 min real time)
  Run Phases (pick employees, watch animations) → Task Complete (totals locked)

Passive (6 in-game months)
  Recurring Revenue (monthly cash) → Final Evaluation (lump sum + unlocks)

Project archived (permanent state on map; affects future projects in area)
```

### Layered view (the full loop)

```
MICRO (per phase animation, ~16 sec real):
  Pick employee → 3 subrounds with growing contributions → params accumulate

MESO (per task, ~2 min real):
  Multiple phases → all params filled → task complete reveal

MACRO (per project, days/weeks real):
  All tasks done → 6 in-game months recurring → final donor evaluation

CAMPAIGN (per year of play):
  Annual review → office relocates → new donors / projects / recruits unlock
```

---

## 🗺️ Field Map: Area → Project → Task → Phase → Subround

### The 5-layer hierarchy

```
AREA (geographic scale, e.g. "Ban Nong Khao")
 └── PROJECT (e.g. "Water Finds a Way" — funded by donor)
      └── TASK (e.g. "Irrigation Design Blueprint")
           └── PHASE (e.g. "PLANNING phase" — 1 of 3-4 per task)
                └── SUBROUND (3 per phase — small, medium, big contribution)
```

**v1.4 reminder:** v1.4 had 3 layers (Area → Project → Task) with a single Work Round per task. v1.5 inserts **Phase** and **Subround** under Task to create the multi-pick playthrough.

### Per-layer rules

| Layer | Player action | Time |
|-------|--------------|------|
| Area | Auto-progress when all projects ≥ Tier 1 reward | Whole campaign |
| Project | Unlocked by Donor (CP + REP cost) | Days/weeks real |
| Task | Selected from project task list | ~2 min real per task |
| Phase | Pick eligible employee, consume 3 SP | ~16s anim + 30s gap |
| Subround | Animation only — no input | 2s each, x3 per phase |

### Task content (overrides v1.4 task spec)

In v1.4, a task had a single `primary_stat` and `secondary_stat`. **In v1.5, a task has 3-4 Phases**, each tied to one of the 4 parameters (see §Parameters). The task's "stat profile" is replaced by which parameters its phases cover and what role each phase requires.

Example — v1.4 task:
```
Task: "Soil Sample Collection"
Primary: Technical, Secondary: Precision
Duration: 2 months, Reward: $500 + 5 CP
```

Example — v1.5 task:
```
Task: "Soil Sample Collection"
Phases:
  1. PLANNING — PM-only (any PM)
  2. EXECUTION — Field Officer (Technical + Precision)
  3. LOGISTICS — Supply Officer (Procurement + Logistics)
Cycle: 3 phases × ~16s anim + 2 gaps × 30s = ~108s real time
```

---

## ⚙️ The Phase Animation System (replaces Work Round)

### Player flow sequence (top-level)

The full flow from idle office to task complete. Player commits to a task FIRST, then assigns people per phase.

```
[1] OFFICE SCREEN (idle, ambient)
     ↓ player taps "Projects" button
[2] PROJECT LIST → pick project
     ↓
[3] TASK LIST → pick task (preview shows phase parameters)
     ↓
[4] PHASE INTRO modal — pick employee for current phase
     ↓ "Start Work" pressed
[5] PHASE ANIMATION OVERLAY drops over office
     ↓ tableau (1.5s) → 3 subrounds → phase complete
[6] 30s GAP — overlay dimmed but visible; office life continues
     ↓
[7] If more phases left → loop back to [4] for next phase
     If all phases done → TASK COMPLETE reveal
```

### Step-by-step detail

**[1] OFFICE SCREEN (idle ambient)**
- Idle game vibe: employees walk between desks, use facilities, chat in pairs, sit working
- HUD shows cash, CP, motivation, current projects in progress
- SP pip widgets on each employee card update visibly when SP recovers
- Player notices recovery happen ("George SP: 4 → 5") creating natural "they're ready" cue
- No time pressure — player chooses when to act

**[2] SELECT PROJECT**
- Player taps "Projects" button in HUD or directly clicks a project marker
- Modal lists active projects with their progress bars and remaining tasks
- Pick one → opens project detail screen

**[3] SELECT TASK**
- Project detail shows ordered task list
- Each task card displays:
    - Humor title + official name (per HUMOR_NAMING_BIBLE)
    - Phases preview line: e.g. `PLANNING → EXECUTION → LOGISTICS`
    - Estimated time: e.g. `~108s`
    - "BEGIN" button if no phases yet started; "RESUME" if mid-task
- Pick task → opens Phase Intro for the first incomplete phase

**[4] PHASE INTRO modal (Employee Picker)**
- Modal title: e.g. "PLANNING phase — pick your Project Manager"
- Modal body: grid of eligible employees as **picker cards** (see UI spec below)
- For PLANNING phase: only PMs shown (eligible)
- For other phases: full team shown, role mismatches greyed but still selectable (with 70% efficiency note inline)
- Player taps an employee card → highlight selected
- "Start Work" button at bottom enables once a selection is made

**[5] PHASE ANIMATION OVERLAY (the work moment)**
This is the peak active moment of the loop. The overlay drops on top of the office screen, with the office still visible underneath.

```
A. Tableau moment (1.5s)
   - Office screen behind overlay: visible blur + 60% dim
   - All on-screen employees turn from idle → "ready" pose at desks
   - Selected employee gets highlight: glow ring + nameplate floating above
   - "+3 SP consumed" pip animation on selected employee's stat bar
   - Animation cue: subtle whoosh sound, slight zoom-in

B. Subround 1 (2s)
   - Selected employee animates: typing, gesturing, drawing
   - Icon emoji (📋 for PLANNING, 🔧 for EXECUTION, 📦 for LOGISTICS, 🤝 for COMMUNITY)
     floats from employee → parameter bar at top of overlay
   - Number on parameter bar ticks up live
   - Office life still visible behind: other employees idle and ambient

C. Gap 5s
   - Selected employee continues working but no contribution this beat
   - Background office life more prominent (others walking, chatting)
   - Brief flavor text option: "George studies the data..."

D. Subround 2 (2s) — bigger contribution

E. Gap 5s

F. Subround 3 (2s) — biggest contribution

G. Phase Complete reveal (~2s)
   - Drum roll mini sound
   - Parameter total counter ticks up to final number with emphasis
   - "PLANNING complete: 42" banner
   - Cannot fully skip (peak moment)
```

**[6] 30s GAP between phases (real time)**
- Overlay stays but heavily dimmed and minimized to top bar
- Office screen fully visible — players see post-phase office life
- Idle activity rich during this window: employees who just finished walk to facilities, chat with colleagues, take coffee
- Tap = 3x speed; Hold = skip to next picker
- Bottom CTA: "Continue to next phase →" tap to advance immediately

**[7] Loop or finish**
- More phases left: jump back to [4] with the next phase pre-selected (e.g. EXECUTION after PLANNING)
- All phases done: TASK COMPLETE reveal — totals summed, per-task cash/CP awarded, "Return to Office"

### Tap-to-fast-forward (Game Dev Story pattern)

| Moment | Default | Tap | Hold |
|--------|---------|-----|------|
| Tableau (1.5s) | 1.0x | 3.0x | skip to subround 1 |
| Subround animation (2s each) | 1.0x | 3.0x | jump to Phase Complete |
| Gap between subrounds (5s) | 1.0x | 3.0x | skip to next subround |
| 30s gap between phases | 1.0x | 3.0x | skip to next phase picker |
| Phase Complete reveal (~2s) | 1.0x | 3.0x | **cannot fully skip** (peak moment) |
| Final Evaluation reveal | 1.0x | 1.0x | **cannot skip** (biggest peak) |

### Subround contribution numbers

Contribution scales with the assigned employee's **relevant stat sum**, not with any hidden grade table.

```
relevant_stat_sum = primary_stat + secondary_stat
                    (e.g. PLANNING phase = Management + Focus)

base_contribution_per_subround = relevant_stat_sum × subround_multiplier
subround multipliers: { sub1: 0.10, sub2: 0.30, sub3: 0.60 }
random variance: ±15% per subround (jitter for life)
```

**Example — Tier D PM (Management 30, Focus 25, sum 55):**
- Subround 1: 55 × 0.10 ± 15% = ~5
- Subround 2: 55 × 0.30 ± 15% = ~12-18
- Subround 3: 55 × 0.60 ± 15% = ~25-35
- Phase total PLANNING: ~42-58

**Example — Tier C PM (Management 60, Focus 55, sum 115):**
- Phase total PLANNING: ~115 (range 95-140)

**Example — Tier A PM (Management 90, Focus 85, sum 175):**
- Phase total PLANNING: ~175 (range 145-210)

**Example — S Tier new game+ (sum 200+):**
- Phase total PLANNING: 200+, can exceed 500 if specialty bonus stacks

There is **no cap** on parameter accumulation. Late-game players will see four-digit phase totals. Big numbers are part of the reward.

---

## 🖼️ Employee Picker Card UI Spec

The picker card is the single most-used UI element in v1.5 — it appears every time a phase starts. It must communicate fitness for the role at a glance, without using stars or recommendations (player must read and decide).

### Card layout (single card, ~280px wide × 120px tall)

```
┌─────────────────────────────────────────────────┐
│  ┌──────┐   George Anan                          │
│  │      │   Project Manager · Tier C             │
│  │ Por- │                                        │
│  │ trait│   SP: ●●●●● 5/5                        │
│  │      │   Management ████████░░░ 60            │
│  └──────┘   Focus      ███████░░░░ 55            │
│                                                  │
│  Expected PLANNING contribution: ~115            │
└─────────────────────────────────────────────────┘
```

### Element specs

| Element | Spec |
|---------|------|
| Portrait | 64×64px pixel art sprite, employee head/shoulders |
| Name | Humor name (large) + Official name (small grey, optional) |
| Role + Tier | Single line, e.g. "Project Manager · Tier C" |
| SP bar | 5 pips for visible 5-SP pool. Filled = available, empty = consumed. Cap can grow to 8. |
| Stat bar (relevant) | Show ONLY the 2 stats that matter for this phase (e.g. Management + Focus for PLANNING). Numeric value to the right of bar. Max bar fill = tier cap. |
| Expected contribution | Single line at bottom: "Expected PLANNING contribution: ~115" — this is `relevant_stat_sum` (no multiplier shown). Player must mentally extrapolate to phase total. |

### Eligibility states

- **Eligible (default)**: card has full opacity, normal border
- **Ineligible by role (e.g. Field Officer for PLANNING phase)**: card hidden entirely from picker
- **Ineligible by SP (< 3 SP available)**: card visible but greyed (40% opacity), tap shows tooltip "Needs 3 SP — currently has 2/5"
- **Mismatched role (e.g. Admin Officer attempting EXECUTION at 70% efficiency)**: card visible with yellow accent border, label "70% efficiency — not specialized" inline

### Sort order (within picker)

Default sort: by **relevant stat sum** descending. Strongest match at top, but no star or "recommended" indicator. Player reads the bars and decides.

### What the picker DOES NOT show

- No expected contribution range with multipliers (subround math hidden)
- No grade prediction
- No "best choice" star or hint
- No stat history or trend

The deliberate omission of recommendations preserves Simple but Deep — the rule is simple (see stats, pick), the depth comes from learning over time which combos win.



## 💪 Stamina System

### Core spec

- Every employee has a **Stamina (SP)** pool, separate from morale.
- **Beginner SP cap:** 5 SP per employee.
- **Phase cost:** 3 SP per phase (consumed at the moment employee is selected, not over the animation).
- **Recovery:** 1 SP per **in-game week**.
- **Selection rule:** if employee has < 3 SP, the UI greys them out for the current phase.

### Recovery & weekly cycle

The **Weekly Cycle** from `GAME_DESIGN_v2.md` is preserved but its trigger changes:

- v2.0 trigger: every 5 work rounds. **Removed** (work rounds no longer exist).
- v1.5 trigger: every 5 **phases** completed (across any project) = 1 in-game week.

At end of week:
- Sunset / employees go home / morning animation (per v2 §5.5.3)
- Weekly Summary modal (per v2 §5.5.5)
- **Each employee gains +1 SP** (capped at their max)
- Autosave runs (per v2 §5.5.6)

### Increasing max SP

- **Money:** $200 to train an employee +1 max SP (cap +3 over base = total max 8)
- **CP:** alternate path — 30 CP for +1 max SP
- **Trade-off:** more SP = can run more phases per week, but high-SP employees demand higher salary tier (TBD scaling)

### Why this matters (Simple but Deep)

- Forces hire diversity: one PM cannot do every PLANNING phase if you have 3 projects running
- Trains player to plan stamina across in-game time
- Reason to use idle GAP — employees are recovering during it

---

## 🎭 Character Customization (Starter Protagonist)

The first PM the player ever sees is **themselves** — character customization happens before the first office screen even loads.

### Scope: cosmetic-only (MVP)

| Choice | Options | Effect |
|--------|---------|--------|
| Portrait | 4-8 pixel art portraits (gender-neutral mix) | Visual only |
| Name | Free text input (max 20 chars) | Display name everywhere |
| NGO Name | Free text input (max 30 chars) | Studio/company name in HUD |

### What is NOT in MVP customization

- ❌ Stat allocation — PM starts with fixed Tier D stat profile
- ❌ Background lore — saved for prestige/new game+ unlocks
- ❌ Archetype choice — protagonist is always neutral archetype

This keeps the entry barrier low and avoids overwhelming new players with min-max decisions before they understand the systems.

### Starter PM stat profile (D Tier)

Fixed values for everyone's first PM:

| Stat | Value | Note |
|------|-------|------|
| Management | 30 | Main (PLANNING) |
| Focus | 25 | Main (PLANNING) |
| Charm | 20 | Secondary |
| Communication | 20 | Secondary |
| Technical | 15 | Low |
| Procurement | 15 | Low |
| Logistics | 15 | Low |
| Precision | 15 | Low |
| **SP max** | 5 | Beginner cap |

### Future expansion (post-MVP)

- Background lore unlock via Prestige (Year 5 complete)
- Archetype choice unlock at Year 2
- Stat point allocation as New Game+ feature

---

## 👶 Starter Setup & Tutorial Onboarding

The first hour of play follows a guided arc that introduces every major system. Player is **never** dumped into systems blind.

### Hour 1 onboarding sequence

```
[0-2 min] Character Customization
   ↓ Portrait, name, NGO name → "Welcome to your NGO"

[2-5 min] Office Empty + CHAMP Tutorial 1
   ↓ Tutorial popup: "This is your office. Right now, only you."
   ↓ CHAMP introduces idle game vibe + HUD basics

[5-8 min] CHAMP Tutorial 2: Recruit Mechanic
   ↓ Forced action: "You need a team. Click Recruit."
   ↓ Player MUST recruit Field Officer (gift cash $600 if needed)
   ↓ Player MUST recruit Supply Officer (gift cash $600 if needed)
   ↓ Now have 3-person team

[8-12 min] CHAMP Tutorial 3: First Project + Task
   ↓ CHAMP gifts first donor "Local NGO Partner"
   ↓ Project "Who Needs What?" auto-unlocked
   ↓ Tutorial walks through: pick project → pick task

[12-25 min] First Task Playthrough (3 phases)
   ↓ Tutorial 4: Picker explanation (PM-only PLANNING)
   ↓ Tutorial 5: Phase animation + tap-to-skip
   ↓ Tutorial 6: Stamina system (after PM consumes 3 SP)
   ↓ Player runs PLANNING → EXECUTION → LOGISTICS phases
   ↓ Task complete reveal

[25-35 min] First Project Recurring + Final Eval
   ↓ Tutorial 7: Recurring revenue (6 months)
   ↓ Time-skip to project end (CHAMP fast-forwards)
   ↓ Tutorial 8: Final Evaluation
   ↓ Tutorial 9: Item Drop (first guaranteed drop)
   ↓ Tutorial 10: Inventory + Tier Promotion preview

[35-60 min] Open play
   ↓ Player picks 2nd project
   ↓ CHAMP Bulletin fires (Tutorial: world events)
   ↓ Weekly cycle hits (Tutorial: SP recovery + summary)
```

### Starter rules

- ✅ Player begins with **PM only** (the customized protagonist)
- ✅ Tutorial **forces** recruit of Field Officer + Supply Officer in first 8 minutes
- ✅ First task = **3 phases** (PLANNING + EXECUTION + LOGISTICS) — fits the 3-person team
- ✅ CHAMP gifts $5,000 + first donor — protects against early bankruptcy
- ✅ All tutorial popups fire **once only** per game save

### Designer note: emotional buy-in

Customization upfront = the protagonist is **the player**, not a generic "PM #1". When the protagonist is later promoted, gets an item, or is shown contributing in tableau, the emotional weight is much higher than for a randomly-named NPC.

---

## 🚫 The 1-Person-Per-Phase Rule

A core design constraint that drives team diversity.

### The rule

> **Within a single task, no employee may work more than one phase.**

If a task has 3 phases (PLANNING + EXECUTION + LOGISTICS), the player MUST select 3 different employees — one per phase.

### Why

- Forces team diversity: cannot solo-clear a 4-phase task with one PM
- Creates a **real reason to recruit** beyond cosmetic team-size
- Pairs with stamina: even within a single task, distributed labor matters
- Creates implicit specialization pressure: the second-best Field Officer matters when the first is unavailable

### Consequences

| Task phases | Min team needed |
|-------------|----------------|
| 2 phases | 2 employees |
| 3 phases | 3 employees |
| 4 phases | 4 employees |

This is why the tutorial **forces** recruitment of Field Officer + Supply Officer before the first 3-phase task.

### Cross-task: same employee CAN work multiple tasks

The rule applies WITHIN a task, not ACROSS tasks.

- George (PM) can do PLANNING in Task A this morning
- Same George can do PLANNING in Task B this afternoon
- (Stamina permitting — 6 SP used in one day for 2 phases)

### Why this granularity

- Within-task: drives diversity (above)
- Across-task: lets specialists actually specialize (PM does PLANNING all day)
- Stamina is the natural throttle that keeps cross-task abuse in check

---

## 📊 Parameters & Roles

### The 4 parameters

| Parameter | Real-world meaning | Stat sum | Eligible role |
|-----------|-------------------|----------|---------------|
| **PLANNING** | Strategy, blueprint, ROI thinking | Management + Focus | **PM only** (Project Manager role) |
| **EXECUTION** | Field implementation, build quality | Technical + Precision | Field Officer |
| **LOGISTICS** | Sourcing, transport, timing | Procurement + Logistics | Supply Officer |
| **COMMUNITY** | Local trust, training, communication | Charm + Communication | Charm specialist (any role with high Charm) |

### Role assignment rules

- **PLANNING phase:** can ONLY be done by an employee with the **Project Manager** role. Early game = 1 PM only. Mid game (Year 2+) unlocks slot for 2nd PM.
- **EXECUTION / LOGISTICS phases:** require their primary role for full contribution. Other employees can fill in but contribute at **70% efficiency** (dampens but doesn't block — Game Dev Story style).
- **COMMUNITY phase:** any employee can attempt, but anyone without high Charm contributes at 70%.

### Specialty bonus (Open question — see §Open Questions)

Working assumption: specialty employees get **+20% contribution** when their role matches the phase. To be playtested.

### Per-task parameter mix

Not every task uses all 4 parameters. Examples:

| Task type | Parameters used | Phase count |
|-----------|----------------|-------------|
| Survey-style | PLANNING + COMMUNITY | 2 |
| Construction-style | PLANNING + EXECUTION + LOGISTICS | 3 |
| Training/workshop | PLANNING + COMMUNITY + EXECUTION | 3 |
| Major infrastructure | All 4 (PLANNING/EXECUTION/LOGISTICS/COMMUNITY) | 4 |

The task data structure declares which phases it has and in what order. Task definitions live in `task_data.gd` (or equivalent) — see §Migration.

### Task completion

A task completes when **all its phases have been run**. There is no explicit success/fail threshold per phase. Final task score = **sum of all parameter totals from all phases**:

```
task_total = sum_of(phase_totals_across_all_4_parameters)
```

`task_total` feeds into the project total, which determines reward tier.

---

## 💰 Economy: Recurring Revenue + Final Evaluation

### Project total score

```
project_total = sum_of(task_total for all tasks in this project)
```

### Donor reward tiers

| Tier | Project total range | Monthly recurring | Final lump sum | Total over 6 months |
|------|-------------------|-------------------|----------------|---------------------|
| 1 (breakeven) | < 200 | $300 | $1,500 | $3,300 |
| 2 (small win) | 200 – 500 | $700 | $4,000 | $8,200 |
| 3 (solid) | 500 – 1,200 | $1,500 | $10,000 | $19,000 |
| 4 (great) | 1,200 – 2,500 | $3,000 | $20,000 | $38,000 |
| 5 (legendary) | > 2,500 | $5,000 | $40,000 | $70,000 |

**Numbers are starting points** — must be tuned in playtesting alongside `ECONOMY_BIBLE.md`.

### Implicit failure design (replaces v1.4 explicit fail)

There is **no** "project failed" popup. The economy itself communicates failure:

- Tier 1 reward = $3,300 over 6 months
- 2 employees × $275 salary × 6 months = $3,300
- → Tier 1 = **breakeven** = no growth, no progress
- → Player notices the cash flat-line, retraces the project, infers "I should have trained more / picked better"

This mirrors Game Dev Story's flop-game pattern: the game doesn't tell you the game was bad, the sales chart does.

### Recurring revenue mechanics

- Pays monthly on the **calendar month** boundary (existing salary tick)
- During the 6-month window the project is in "live" state — events (CHAMP Bulletin) can buff or debuff a specific month's payout
- Optional flavor variance: ±10% per month based on random village-satisfaction events ("Drought reduces yield this month: -10%")
- After 6 months → Final Evaluation triggers automatically → project enters "archived" state

### Project archived state (NEW — replaces v1.4 maintenance loop)

Once a project is archived:
- No more recurring revenue from it
- BUT it leaves a **permanent buff/debuff** on its village/area:
  - Tier 4-5 finish: +10% contribution buff for any future project in same area
  - Tier 1-2 finish: -10% contribution debuff (village skeptical)
- Visual: village on map gets greener (tier 3+) or stays drab (tier 1-2)

This makes "did I do this well?" matter long after the project ends.

---

## 👥 Employee System

### Stats (unchanged from v1.4 — 8 stats)

| Stat | Used in parameter |
|------|-------------------|
| Technical | EXECUTION |
| Charm | COMMUNITY |
| Focus | PLANNING |
| Communication | COMMUNITY |
| Procurement | LOGISTICS |
| Logistics | LOGISTICS |
| Management | PLANNING |
| Precision | EXECUTION |

Each parameter sums two stats. All 8 stats are used. Players who specialize an employee in one parameter pair (e.g. Management + Focus = PLANNING specialist) make them a top performer in that phase type.

### Stat caps by tier (unchanged)

- F/E Tier: max 30 per stat
- D Tier: max 45
- C Tier: max 60
- B Tier: max 75
- A Tier: max 90
- S (Hero/Celebrity): max 100

### Department roles (NEW — promoted to required)

In v1.4 these were "medium priority". In v1.5 they are **required** because phases gate by role.

| Department | Role | Phase eligibility |
|-----------|------|-------------------|
| Management | **Project Manager** | PLANNING (only role allowed) |
| Operations | Field Officer | EXECUTION (full efficiency) |
| Procurement | Supply Officer | LOGISTICS (full efficiency) |
| Secretarial | Admin Officer | COMMUNITY at full; reduces task setup time |
| Finance | Budget Officer | LOGISTICS at 70%; unlocks salary discounts |

A non-role-matched employee can still fill a phase at **70% contribution efficiency** (except PLANNING — PM-only, hard gate).

### Archetypes (unchanged from v1.4)

| Archetype | Behavior |
|-----------|----------|
| Quiet Quitter | -10% contribution unless supervised |
| Brown-noser | +15% during evaluation months |
| Workaholic | +20% contribution, 2× burnout risk |
| Gossip | Spreads -5% morale to nearby employees |
| Team Player | Spreads +5% morale to nearby employees |
| Overachiever | +100% CP on task complete |

---

## ⬆️ Tier Promotion System (NEW)

In v1.4, employee tier was static — recruit a Tier D, you have a Tier D forever. v1.5.2 introduces **promotable tiers**: invest in an employee long enough and they can grow.

### Tier ladder

```
F → E → D → C → B → A → S
```

Player's PM starts at **D**. Recruited employees from advertisements typically come at E or D, with rare C+ from premium recruitment channels.

### Promotion = Ceiling + Resources

Three things must align before an employee can be promoted to the next tier:

1. **All ceiling stats reached** for current tier (per role profile)
2. **Money paid** (scaled to target tier)
3. **Promotion Item used** (specific to character — see Item System)

### Stat ceilings per role profile

Each role has a "stat profile" — main stats with high ceilings, side stats with low ceilings. The player must train all of them to the ceiling before promotion unlocks.

**Project Manager (PM) profile — Tier D ceilings:**

| Stat | Tier D ceiling | Tier C | Tier B | Tier A | Tier S |
|------|----------------|--------|--------|--------|--------|
| Management (main) | 200 | 400 | 600 | 800 | 1000 |
| Focus (main) | 150 | 300 | 450 | 600 | 750 |
| Charm (secondary) | 100 | 200 | 300 | 400 | 500 |
| Communication (sec) | 100 | 200 | 300 | 400 | 500 |
| Technical (low) | 50 | 100 | 150 | 200 | 250 |
| Procurement (low) | 50 | 100 | 150 | 200 | 250 |
| Logistics (low) | 50 | 100 | 150 | 200 | 250 |
| Precision (low) | 50 | 100 | 150 | 200 | 250 |

**Field Officer profile — Tier D ceilings:**

| Stat | Tier D | Tier C | Tier B | Tier A | Tier S |
|------|--------|--------|--------|--------|--------|
| Technical (main) | 200 | 400 | 600 | 800 | 1000 |
| Precision (main) | 150 | 300 | 450 | 600 | 750 |
| Management (sec) | 100 | 200 | 300 | 400 | 500 |
| Charm (sec) | 100 | 200 | 300 | 400 | 500 |
| Focus (low) | 50 | 100 | 150 | 200 | 250 |
| Communication (low) | 50 | 100 | 150 | 200 | 250 |
| Procurement (low) | 50 | 100 | 150 | 200 | 250 |
| Logistics (low) | 50 | 100 | 150 | 200 | 250 |

**Other role profiles** (Supply Officer, Admin Officer, Budget Officer): TBD, follow same pattern with appropriate main/secondary/low designation.

### Replacement of v1.4 stat caps

These ceiling tables **replace** the v1.4 stat cap table (D=45, C=60, B=75, etc.). The 0-1000 stat scale is preserved; the v1.4 caps are deleted.

### Promotion costs

| Promotion | Money | CP | Promotion Item | Salary increase |
|-----------|-------|----|----|------------------|
| F → E | $500 | 30 CP | F-tier promo token | +$50/mo |
| E → D | $1,000 | 60 CP | E-tier promo token | +$100/mo |
| D → C | $2,500 | 100 CP | D-tier promo token | +$200/mo |
| C → B | $5,000 | 200 CP | C-tier promo token | +$300/mo |
| B → A | $10,000 | 400 CP | B-tier promo token | +$400/mo |
| A → S | $25,000 | 800 CP | A-tier promo token | +$500/mo |

**Numbers are starting points** — must be playtested.

### Promotion item rules

- **3 generic promo tokens per tier** (Token Type A / B / C)
- **Each character has a specific token type they need** — a player must collect the right token for their specific PM/Field Officer/etc.
- **Sharing rule:** some characters can share the same token type. E.g. George (PM) and Sarah (Admin) might both need Token Type A.
- **Theme matching to project:** specific tokens drop from specific project archetypes (Token A = Planning-heavy projects, B = Execution-heavy, C = Charm-heavy)
- **Drop conditions:** guaranteed drop only when project completes at **Tier 3+** (project_total ≥ 500)
- **MVP scope:** build only D→C tokens; higher tiers TBD post-MVP

### When promotion unlocks

When all ceilings are reached, a popup fires:

```
[POPUP: "Promotion Available!"]
Banner: George Anan ready to promote
Body:
  ✓ Management 200/200
  ✓ Focus 150/150
  ✓ Charm 100/100
  (... all stats at ceiling)

  Required to promote:
  • Money: $2,500
  • Item: D-tier Promo Token Type A (have: 1)

  After promotion:
  • Tier: D → C
  • New ceiling: Management 400, Focus 300, ...
  • Salary: $275 → $475/month

[Promote] [Not now]
```

### Side-stat pain mitigation (MVP)

Setting low-stat ceilings to **50** in Tier D means even a focused PM only needs ~10-15 training sessions on side stats to clear them. This is intentional — the depth comes from multi-tier ladders, not from grinding side stats.

If playtest reveals side-stat training feels punishing, the lever is to **lower the side ceiling** (e.g. 30 instead of 50), not to add an alternate path.

---

## 🎁 Item System (NEW)

Items create the long-tail reward arc — every project finished gives the player something tangible to take home, separate from cash.

### Two main categories

| Category | Source | Use |
|----------|--------|-----|
| **Stat Earning Item** | Project drop (always), CHAMP shop | Consume to boost stat instantly (replaces or supplements CP training) |
| **Promotion Item** | Specific project drop (guaranteed at Tier 3+) | Consumed during tier promotion |

### Equipment category (post-MVP, NOT in v1.5.2)

Equipment items will exist in future versions but are deferred to avoid confusion with the Facility system. Planned spec:

- Only **Tier C and above** employees can equip items
- Tier C-B: 1 equipment slot each
- Tier A-S: 3 equipment slots each
- Equipment provides permanent stat or contribution buffs while equipped

This is documented here for future reference; no implementation in v1.5.2.

### Stat Earning Item — 3-tier scheme

Every stat earning item has 3 tiers, indicated through humorous naming. Higher tier = bigger stat boost.

**Example: PLANNING-boosting items (Books)**
- Tier 1: "A Bad Book" — +5 to one PLANNING stat
- Tier 2: "A Good Book" — +15 to one PLANNING stat
- Tier 3: "The Ultimate Guide for PMs" — +30 to one PLANNING stat

**Example: EXECUTION-boosting items (Tools)**
- Tier 1: "Rusty Toolbox" — +5 Technical or Precision
- Tier 2: "Decent Toolbox" — +15
- Tier 3: "Master Craftsman's Set" — +30

**Example: SP-recovery items (Drinks)**
- Tier 1: "Watery Coffee" — +1 SP
- Tier 2: "Energy Drink" — +3 SP
- Tier 3: "Liquid Hyperfocus" — +5 SP (full restore)

### Drop logic

| Project outcome | Stat earning item | Promotion item |
|-----------------|---------------|----------------|
| Tier 1 (< 200 total) | Guaranteed Tier 1 drop | None |
| Tier 2 (200-500) | Guaranteed Tier 1, 30% Tier 2 | None |
| Tier 3 (500-1,200) | Guaranteed Tier 2, 30% Tier 3 | **Guaranteed promo token if specific project** |
| Tier 4 (1,200-2,500) | Guaranteed Tier 2, 50% Tier 3 | **Guaranteed promo token (always)** |
| Tier 5 (> 2,500) | Guaranteed Tier 3 | **Guaranteed promo token + 30% rare bonus** |

### Two paths to stat boost

Players can train stats two ways, and both are valid strategies:

| Path | Speed | Resource | Source |
|------|-------|----------|--------|
| **CP Training** | Fast (immediate) | CP | Earned actively from work |
| **Item Use** | Variable | Item drop | Earned passively from project completion |

Optimal play uses both. CP-rich players spend on training; item-rich players save CP for donors and items for stat fill.

### Inventory UI

Inventory accessible from the office screen. Lists all owned items grouped by category:
- Stat Earning Items (with tier indicator and parameter)
- Promotion Items (with tier and type)
- Consumables (SP recovery, morale boosters)

Tapping an item → "Use on..." picker → select employee.

Detailed UI spec lives in `UI_SYSTEMS_BIBLE.md`.

---

## 🏢 Facility System (unchanged)

- Idle employees use facilities → +0.5–2 stat
- Combos give +50% bonus
- Visual feedback: fire icon, "Active!" bubble, particle sparkle

Facility combo examples remain as v1.4. Combos now also benefit during **30-second phase gaps** (idle employees use facilities during this window).

---

## 😤 Office Motivation & Fever Mode (unchanged from v1.4)

- 0–100% bar on HUD
- 100% triggers Fever Mode (5 min real time)
- Fever Mode: all contributions doubled, CP doubled
- Drops to 50% after Fever ends

Burnout chain:
```
Overwork → Burnout → Morale 0 → Office Motivation drops →
Harder to reach Fever → CP slows → Reputation drops → Donors harder to win
```

---

## 📰 CHAMP's Bulletin (unchanged in design, hooks change)

CHAMP's Bulletin events still fire 1–2 per month and impact projects. v1.5 hooks differ:

| v1.4 effect | v1.5 effect |
|-------------|-------------|
| "Soil projects -20% progress rate" | "Soil tasks: PLANNING phase totals -20% this month" |
| "All field projects paused 1 month" | "All currently-running phases halt for 1 in-game month" |
| "Funding Freeze - no Cash income for 1 month" | "All recurring revenues paused for 1 month; final evaluations delayed" |

CHAMP lore (megacorp running global news service while delivering NGO crisis updates) is preserved.

---

## 🎪 CHAMP's Corner Store (unchanged)

CHAMP shop still sells consumables. Reference items (CP costs unchanged, see ECONOMY_BIBLE):
- Chocolate (+5 Energy / now +1 SP)
- Ergonomic Chair (+3 Technical permanent)
- Premium Coffee (+10 Energy / now +2 SP all employees)
- etc.

**Note:** "Energy" items in v1.4 now act on the new SP pool. Mapping: 5 Energy = 1 SP for spec purposes.

---

## 🦸 Hero Employees (unchanged, still LOW priority)

Derek Anan Boonphun + 6 others. Late-game unlock.

---

## 🏅 Achievement System (NEEDS RESPEC for v1.5)

Existing v1.4 achievements that still work:
- First Steps (complete first task)
- Welcome Aboard (win first donor)
- Fever Dream (trigger Fever Mode)
- Combo Master (3 facility combos at once)

**New v1.5 achievements (suggestions, design later):**
- "Big Numbers" — first phase total > 200
- "Triple Digit Dreamer" — first phase total > 500
- "Four-Digit Legend" — first phase total > 1,000
- "Donor Darling" — first Tier 5 final evaluation
- "Village Hero" — area gets +10% buff from 3 high-tier finishes
- "Stamina Demon" — train an employee to 8 SP
- "Promotion Day" — first tier promotion
- "Climbing the Ladder" — promote any employee to Tier A
- "Hero of the People" — first Tier 5 final eval

---

## 📚 Tutorial System (NEW)

Tutorial popups are the primary way new mechanics are introduced. They follow a unified template (see `UI_SYSTEMS_BIBLE.md`) and fire **once each** per save file.

### Design rules

- ✅ Each popup explains **one mechanic** only
- ✅ Maximum **3 pages** per popup
- ✅ Banner at top with title + artwork (CHAMP avatar or relevant art)
- ✅ Page indicators (◄ ● ○ ○ ►)
- ✅ Close button **hidden until last page** (forces read)
- ✅ Tap anywhere on the popup body = **skip to last page** (then user can close)
- ✅ Each tutorial fires **once only** — never re-shown unless save reset

### 10 tutorial trigger points

| # | Trigger | Topic | When |
|---|---------|-------|------|
| 1 | Game start (after customization) | Welcome / HUD / idle office | Auto-fire on first load |
| 2 | Player opens Recruit screen first time | Recruit mechanic | Click Recruit button |
| 3 | Player opens Project list first time | Project → Task hierarchy | Click Projects button |
| 4 | First time EmployeePickerModal opens | PM-only PLANNING + parameter→stat mapping | Click "Begin task" on first task |
| 5 | First subround animation completes | Phase Animation flow + tap-to-skip | Auto-fire after sub-1 of first phase |
| 6 | First time SP drops | Stamina system | After first phase ends |
| 7 | First task complete | Recurring revenue | Task complete reveal closes |
| 8 | First Final Evaluation | Donor evaluation + project archive | Auto-fire on first 6-month tick |
| 9 | First item drop | Item System + Inventory | After first item drops |
| 10 | First weekly cycle | Weekly cycle + SP recovery | End of first 5-phase week |

**Stretch — additional tutorial firings (not in main 10):**

| # | Trigger | Topic |
|---|---------|-------|
| 11 | First CHAMP Bulletin | World events + mitigation |
| 12 | First Fever Mode | Motivation + 2× boost |
| 13 | First time promotion ceiling reached | Tier Promotion |
| 14 | First time low cash threshold | CHAMP Bailout (existing v2 system) |

### Tutorial content tone

Per `HUMOR_NAMING_BIBLE`, tutorial copy is friendly, slightly self-aware, and never preachy. CHAMP delivers most of them in their corporate-cheerful-but-suspicious voice.

Example — Tutorial #4 (Picker explanation):

```
[BANNER: "Picking Your Team" + CHAMP artwork]

Page 1:
"Different phases need different specialists.
PLANNING is PM-only. Other phases prefer their
matched role, but anyone can fill in."

Page 2:
"Look at the stat bars. Higher bars in the
relevant stats = bigger contribution. There's
no 'right answer' — pick who you trust."

Page 3:
"Selected? Press Start Work. Stamina drops 3.
Then watch the magic happen."

[CLOSE button appears here]
```

---

## 📅 Progression Structure (unchanged at high level)

5-year campaign, annual evaluation, sandbox + prestige unlock at end.

Per-year activity profile (estimated):
- ~30 phases run per in-game month (player active)
- 360 phases per in-game year
- 5 in-game years = ~1,800 phases = ~23 hours real time at default speed
- With tap-fast-forward: 8–12 hours

Numbers are estimates pending playtest.

---

## 🎵 Sound Design (unchanged)

BGM layers, key SFX as v1.4. Add specifically for v1.5:
- **Phase Complete** drum roll + final number stamp (peak moment audio)
- **Subround tick** chime per icon contribution
- **Final Evaluation** trumpet + reveal sting

---

## ⚙️ Technical Architecture

### Autoload order (unchanged)

`SaveSystem → ClockManager → GameManager → EventManager → FacilityManager → DonorManager → CompetitorManager`

### Codebase rules (unchanged, strictly enforced)

- No `class_name` except in `Employee.gd` and `SaveSystem.gd`
- All variables explicitly typed; no `:=` with untyped values
- Pure ASCII in `.tscn` files
- `@onready` paths must match scene tree
- Always `proj.get("key", default)`, never `proj["key"]`

### New autoloads needed for v1.5 (proposed)

| Autoload | Responsibility |
|----------|----------------|
| `PhaseManager` | Drives phase animation, subround timing, contribution math |
| `StaminaManager` | Tracks SP per employee, weekly recovery |
| `ParameterTracker` | Holds parameter totals per task and per project |
| `RecurringManager` | Calendar-based monthly payouts during 6-month window |
| `TutorialManager` | Tracks which tutorials have fired, manages trigger points |
| `ItemManager` | Inventory CRUD, drop logic, item use effects |
| `PromotionManager` | Ceiling checks, promotion costs, salary updates |

Order proposal: insert `StaminaManager`, `ParameterTracker`, `TutorialManager` after `GameManager`; `ItemManager` and `PromotionManager` after `FacilityManager`; `PhaseManager` after `EventManager`; `RecurringManager` last (depends on calendar).

### New scenes / scripts needed

- `ProjectListModal.tscn` — list active projects with progress
- `TaskListModal.tscn` — list tasks within a project, show phases preview
- `EmployeePickerModal.tscn` — pick eligible employee per phase, with portrait + stat bars
- `PhaseAnimationOverlay.tscn` — drops over office, holds blur and animation
- `PhaseCompleteReveal.tscn` — drum roll + totals
- `FinalEvaluationModal.tscn` — peak moment reveal at project end
- `StaminaWidget.tscn` — small SP pip display, reusable on cards
- `EmployeePickerCard.tscn` — single card subcomponent (portrait + stats + SP)

### Data structure changes

Task data structure shifts from v1.4's `{primary_stat, secondary_stat, duration, reward}` to v1.5's:
```gdscript
{
    "id": "soil_sample_collection",
    "humor_title": "Dirt Detective Begins",
    "phases": [
        {"parameter": "PLANNING", "role_required": "ProjectManager"},
        {"parameter": "EXECUTION", "role_preferred": "FieldOfficer"},
        {"parameter": "LOGISTICS", "role_preferred": "SupplyOfficer"}
    ]
    # No duration; task time emerges from phase count × phase duration
    # No reward; reward is computed at project total time
}
```

---

## 📊 Development Priority Queue (UPDATED for v1.5)

### 🔴 CRITICAL (do these first)

1. **Migration plan execution** — see `MIGRATION_PLAN.md` (separate doc)
2. **Character Customization screen** — first thing player ever sees
3. **Project + Task picker UI** — entry point of new loop
4. **EmployeePickerModal** with portrait + stat bars + SP pips
5. **PhaseAnimationOverlay** — tableau, subrounds, phase complete reveal
6. **Stamina system + UI** — must exist before phase eligibility check
7. **One end-to-end task playthrough** — customize → recruit → pick project → pick task → pick PM → 3 phases → task complete reveal

### 🟠 HIGH

8. Recurring revenue payout (calendar hook)
9. Final Evaluation modal + reward computation
10. Project archived buff/debuff state on map
11. Tap-to-fast-forward gesture across all animations
12. Idle activity animations during 30s gap (reuse v2 §5 design)
13. Item drop logic + Inventory UI
14. Tier Promotion system (D→C only for MVP)
15. Tutorial system (10 trigger points + unified popup)

### 🟡 MEDIUM

16. Achievement respec (new v1.5 milestones)
17. CHAMP Bulletin event hooks updated for parameter system
18. Weekly Cycle trigger updated to "5 phases = 1 week"
19. Soft-fail UX cues (cash flat-line indicator after low Tier 1 finish)
20. CHAMP shop item integration (sell Stat Earning Items + SP recovery items)

### 🟢 LOW

21. Hero Employees
22. Pixel art polish (per ART_BIBLE)
23. "I AM CHAMP" company unlock
24. Prestige system
25. Equipment slots for C+ tier (post-MVP)
26. Higher-tier promotion items (C→B, B→A, A→S)

---

## ⚠️ Known Design Risks (v1.5)

1. **30s gap between phases may bore mobile players.** Mitigated by tap-fast-forward + rich idle activity animation. **Must playtest** — if 60% of players skip every gap, gap design is broken.
2. **Uncapped parameter numbers may break economy balance.** Tier 5 reward is currently $70K total over 6 months. If S-tier squad consistently produces Tier 5, late game becomes cash-trivial. Counter: scale Tier 5 threshold higher per area (Local: 2,500; World: 10,000+).
3. **PM as single point of failure.** One PM with 5 SP can do ~1.5 PLANNING phases per week. Three concurrent projects need 3 PLANNING phases per task = scarcity. **Safety valve TBD** — see Open Questions.
4. **Implicit failure can confuse players.** "Why is my cash not growing?" If players don't connect low project totals to low recurring tier, they may quit. Counter: clear post-project Final Eval UI showing "Tier 1 = $3,300 / breakeven".
5. **Tutorial complexity explodes.** v1.5 has 5 layers (Area/Project/Task/Phase/Subround) + Stamina + 4 parameters + role gating. CHAMP tutorial must layer-introduce, not dump.
6. **Save migration risk.** All v1.4 task data is now invalid shape. Either: (a) wipe saves on v1.5 launch (small player base = acceptable), or (b) write migration code (cost vs benefit TBD).
7. **Specialty bonus number (+20%) is a guess.** Needs playtest. Too low = irrelevant; too high = dominant strategy.

---

## 🚨 Open Design Questions (v1.5)

1. **PM safety valve:** What if all PMs are at 0 SP and there are pending PLANNING phases?
   - Option A: "Acting PM" — temporarily slot non-PM into PLANNING at 50% efficiency
   - Option B: Force player to wait until SP recovery; teaches resource management
   - Option C: Buy "Emergency Coffee" from CHAMP shop — restore 3 SP for 80 CP
   - Recommendation: B for early game (teaches scarcity), unlock A or C in mid game

2. **Specialty bonus exact value:** +20% feels right but unverified. Playtest target: with full role-matched team, average phase total should be 30-40% higher than mixed team. If +20% gives only 10% practical lift, raise it.

3. **Recurring monthly variance:** Do we add ±10% random per month for flavor? Pros: every month feels different, drives player to check in. Cons: noisy economy, harder to reason about.

4. **Project total threshold scaling:** Should Tier 5 threshold scale with area? Local Tier 5 = 2,500. World Tier 5 = 10,000? Or keep flat? Flat = simpler; scaled = forces player progression.

5. **Tutorial pacing:** 5 layers + new systems = a lot. CHAMP should introduce 1 layer at a time:
   - Tutorial 1: First task, only PLANNING phase visible (1 phase to keep simple)
   - Tutorial 2: Second task adds EXECUTION
   - Tutorial 3: First full 4-phase task
   - Open: when does Stamina get introduced? (probably tutorial 2 or 3)

6. **Save format migration:** Wipe vs migrate. With pre-launch player base, recommend wipe + version bump.

7. **What happens to existing 29 GUT tests?** Most test grade calculation (now removed) and Work Round (also removed). Most will fail / be deleted. New tests needed for: phase contribution math, stamina depletion, recurring payout, final evaluation. **Estimate: 70% of existing tests deleted, 100% rewrite needed for new systems.**

---

## 🗂️ Migration: Keep / Refactor / Delete

A separate `MIGRATION_PLAN.md` will detail file-by-file actions. Summary here:

### Keep as-is
- `Employee.gd`, `SaveSystem.gd` (class_name files)
- `BaseModal.gd` and `BaseModal.tscn` (UI standard)
- Facility system files
- CHAMP bulletin manager (data structure unchanged, hooks need re-target)
- Mission/Area/Project data structure (top 3 layers unchanged)

### Refactor (significant changes)
- `ProjectManager.gd` — remove grade math, add phase orchestration
- `Task.gd` / task data — restructure to phase-based
- `EvaluationScreen.gd` — repurpose for project-end Final Evaluation
- Calendar/clock manager — emit phase-completed signal driving weekly cycle

### Delete
- All grade calculation code (helpers extracted in PR #118)
- `WorkRoundManager.gd` and any Work Round UI
- 29 existing GUT tests (most are grade-related; rewrite from scratch for new systems)
- Open ArtworkPanel PR (`refactor/work-round-ui-artworkpanel-lWfnK`) — discard, no longer relevant
- `claude/fix-work-result-delay-lWfnK` — discard

### Rewrite
- All unit tests under `tests/unit/`
- `GAME_DESIGN_v2.md` — keep weekly cycle and CHAMP bailout sections; mark grade/work-round sections obsolete

---

## 📐 Discipline & Workflow (unchanged)

1. Claude prepares implementation prompt
2. Dos sends to Claude Code
3. Claude Code creates **fresh branch from main** (no `claude/` prefix)
4. Branch pattern: `{type}/{feature}-{suffix}`
5. PR review → merge → `git checkout main && git pull`
6. F5 test in Godot

**One scope per prompt. One file per PR.** No exceptions.

---

## 🤖 Test the Fun First

Before scaling implementation, build a **5-minute prototype** with:
- 1 task, 2 phases (PLANNING + COMMUNITY)
- 1 PM, 1 Charm specialist
- Phase animation working with placeholder art
- Final Evaluation reveal

If this 5-minute prototype doesn't make Dos lean forward, the design is wrong. We don't go bigger until the prototype is fun.

---

*Pocket Office Game Bible v1.5.2 — Created 2026-04-30, revised 2026-05-01*
*Supersedes v1.4. Companion file: `UI_SYSTEMS_BIBLE.md`. Next review: after 5-minute prototype playtest.*
