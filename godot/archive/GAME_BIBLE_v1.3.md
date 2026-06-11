# 📋 Pocket Office — Game Bible v1.3
> Last updated: 2026-03-10
> This file is the single source of truth for all design decisions.
> Claude and Claude Code must read this before any design or implementation work.

---

## 🎯 Core Vision

**One-line pitch:**
> "The office simulation game that finally *gets* what it's actually like to work in an NGO — and lets you run one."

**Target player:** Working professionals aged 25–40 who want a relatable, satisfying management sim with real-world meaning behind every decision.

**Price:** Premium $4.99 — no ads, no pay-to-win.

**Hidden educational goal:** Teach players how an NGO operates — cross-team cooperation, procurement, operations, secretarial, and management roles each matter. Donors are not revenue — they are mission-enablers. The player learns this by playing, not by reading.

---

## 🌍 Mission & World

**Your NGO's mission:** "End World Hunger"

The game takes place across 5 geographic scales. Each scale represents a campaign chapter. As your NGO completes work in each area, the world visually transforms — land becomes greener, crops appear, and local people walk normally instead of slowly and weakly.

### 🗺️ Map Scale & Project Counts

| Scale | Projects Required | Visual Change | Office Tier |
|-------|------------------|---------------|-------------|
| 1. Local | 3 projects | Barren land → small crops, people walk normally | Small rented office |
| 2. Region | 7 projects | Scattered farms → organized fields | Bigger city office |
| 3. Country | 12 projects | Green countryside, markets appear | National HQ office |
| 4. Regional (multi-country) | 24 projects | Cross-border farmland, roads built | Regional HQ office |
| 5. World | 36 projects | Global impact map, thriving communities | World HQ office |

**Total projects across full campaign: 82**

### 🏢 Office Relocation
- When a map scale is completed (all projects ≥ 70%), the NGO upgrades its office to the next scale.
- All employees and facilities move with the office (no loss of progress).
- Relocation has a one-time cost in both Cash and CP — this is a meaningful milestone moment.
- New office tier unlocks higher recruitment tiers and new facility blueprints.

---

## 🔁 Core Game Loop

```
MICRO (each tick):
Employees work → Stats apply to projects → % progress increases

MESO (each month):
Pay salaries → New projects available → Facility combos grant stat boosts → Motivation ticks

MACRO (each year):
Annual Evaluation → Ranked vs Competitor NGOs → Win/Lose scale area → Office upgrades
```

### The Full Loop Visualized:
```
Hire staff → Assign to projects → Earn CP + Cash
     ↑                                    ↓
Upgrade office ←── Buy Blueprints ←── Spend CP ──→ Win Donors ──→ More Projects
                                                         ↓
                                              Field Map % increases
                                                         ↓
                                         Area completes → World gets greener
```

---

## 🗺️ Field Map System

### Project Implementation Mechanic
- Each project must be implemented **multiple times** to reach 100% completion.
- Each implementation cycle: one or more employees are assigned → their stats determine the % gained per cycle.
- **Stat Cap per cycle:** A single employee can contribute max 15% per implementation cycle (prevents spamming one person).
- **Decay mechanic:** If a project is abandoned for 3+ months, its % slowly declines at 2% per month (simulates real-world project maintenance needs).
- **Completion threshold:** Projects must reach **≥ 70%** to count as "won."
- If a project falls below 50% after completion, it resets to "at risk" status.

### Visual Progression
- 0–30%: Dry, cracked earth. Local people walk slowly and hunched.
- 31–60%: Small patches of greenery appear. People walk at normal pace.
- 61–89%: Crops growing. Animals visible. Children playing.
- 90–100%: Lush farmland. Markets active. Community celebrations visible.

### Project List — Local Area (Tier 1)
| Project Name | Primary Stat | Secondary Stat | Duration | Reward |
|-------------|-------------|---------------|----------|--------|
| Soil Quality Assessment | Technical | Focus | 2 months | CP + Reputation |
| Farmer Training Workshop | Charm | Communication | 1 month | CP + Morale |
| GIS Land Mapping | Technical | Precision | 3 months | CP + Cash |
| Seed Distribution Program | Procurement | Logistics | 2 months | Cash + Reputation |
| Water Irrigation Planning | Technical | Management | 4 months | CP + Cash |
| Basic Agricultural Equipment Audit | Procurement | Technical | 2 months | Cash |
| Community Nutrition Survey | Charm | Focus | 2 months | Reputation |
| Crop Rotation Planning | Technical | Communication | 3 months | CP |

### Project List — Region Area (Tier 2)
| Project Name | Primary Stat | Secondary Stat | Duration |
|-------------|-------------|---------------|----------|
| Regional Food Security Assessment | Management | Technical | 4 months |
| Supply Chain Mapping | Procurement | Logistics | 3 months |
| Livestock Health Program | Technical | Charm | 3 months |
| Irrigation Network Expansion | Technical | Procurement | 5 months |
| Agricultural Cooperative Formation | Management | Charm | 4 months |
| Market Access Development | Communication | Charm | 3 months |
| Rural Road Infrastructure Survey | Technical | Logistics | 4 months |
| Women Farmer Empowerment Program | Charm | Communication | 3 months |
| Seed Bank Establishment | Procurement | Technical | 4 months |
| Post-Harvest Loss Reduction Study | Technical | Focus | 3 months |
| Community Grain Storage Design | Technical | Management | 5 months |

*(Projects scale in complexity, duration, and stat requirements as the area scale increases.)*

---

## 💰 Economy System

### Starting Conditions
- **Starting Cash:** $10,000
- **Starting Employees:** 2–3 (Tier D/E)
- **Starting CP:** 0

### Salary Structure by Tier

| Tier | Label | Monthly Salary Range |
|------|-------|---------------------|
| F | Milk Carton | $150–200 |
| E | Street Recruit | $200–250 |
| D | Standard Hire | $250–300 |
| C | Skilled Staff | $300–450 |
| B | Senior Staff | $450–600 |
| A | Expert | $600–700 |
| S | Celebrity / Hero | $700–1,200 |

**Design rule:** Starting with 2x Tier D employees = $500–600/month burn. $10,000 gives ~16 months runway before bankruptcy if zero income. First project reward must clear $600 to validate the loop.

### Project Failure State
- **< 70% completion at deadline:** Donor loses confidence. Reputation −5. No reward.
- **< 50% completion at deadline:** Donor withdraws. Must re-win donor using CP.
- **≥ 70%:** Success. Full Cash + CP reward granted.

---

## 💎 Corporate Points (CP) Economy

CP is the strategic resource — harder to earn than cash, more powerful when spent wisely.

### CP Sources
| Action | CP Earned |
|--------|-----------|
| Complete a project | 10–40 CP (scales with difficulty) |
| Employee uses facility | 1–3 CP per use |
| Facility combo active during use | +50% CP bonus |
| Annual Evaluation — top ranking | 50–100 CP bonus |
| Fever Mode — all project completions | +100% CP during fever |

### CP Spending (3 Core Uses — Trade-off Required)

```
CP Pool
 ├── Win Donor          (High cost: 30–100 CP + Reputation requirement)
 ├── Facility Blueprint (Medium cost: 20–60 CP → then build with Cash)
 └── PR/Staff Upgrade   (Low cost: 10–30 CP → long-term stat investment)
```

**Design rule:** CP must always feel scarce enough that players agonize over spending. Never let CP pool sit idle — if player has 200+ CP unspent, prices need rebalancing.

### Donor Winning Requirements
- **CP cost** (varies by donor tier)
- **Reputation score** (must meet minimum threshold)
- **Project Manager stat** (PM's Charm + Management affects success chance)
- Winning a Donor unlocks a set of new field projects + new recruits available

---

## 👥 Employee System

### Stats
| Stat | Description | Key Projects |
|------|-------------|-------------|
| Technical | Field implementation quality | GIS, irrigation, soil work |
| Charm | Persuasion, donor relations | Farmer workshops, donor winning |
| Focus | Sustained deep work | Surveys, assessments |
| Communication | Cross-team efficiency | Training, cooperative programs |
| Procurement | Supply and logistics quality | Seed programs, equipment audits |
| Logistics | Delivery and distribution | Supply chains, storage |
| Management | Team coordination, planning | Multi-team projects, office relocation |
| Precision | Accuracy-critical tasks | Mapping, technical audits |

### Stat Cap by Tier
- F/E Tier: Max stat per category = 30
- D Tier: Max = 45
- C Tier: Max = 60
- B Tier: Max = 75
- A Tier: Max = 90
- S (Hero/Celebrity): Max = 100

**Design rule:** Facilities can raise stats temporarily above base but cannot exceed tier cap permanently. This prevents Tier F employees from becoming superheroes via facility spam.

### Employee Archetypes (Personality Types)
| Archetype | Behavior | Effect |
|-----------|----------|--------|
| Quiet Quitter | Low initiative, slow project progress | -10% speed unless supervised |
| Brown-noser | Performs well when manager is present | +15% during evaluation months |
| Workaholic | Works faster, burns out quicker | +20% speed, burnout risk 2x |
| Gossip | Lowers morale when idle | Spreads -5% morale to nearby employees |
| Team Player | Boosts morale of colleagues | +5% morale to nearby employees |
| Overachiever | Earns double CP on completions | +100% CP on project complete |

### Department Roles (Medium Priority — implement after core loop stable)
| Department | Role | Game Function |
|-----------|------|--------------|
| Management | Project Manager | Required to win donors; Charm + Management stats |
| Operations | Field Officer | Primary stat contributor to field projects |
| Procurement | Supply Officer | Required for supply-type projects; unlocks better equipment |
| Secretarial | Admin Officer | Reduces processing time for project paperwork |
| Finance | Budget Officer | Unlocks better salary negotiations and cost savings |

---

## 🏢 Facility System

### How Facilities Work
1. Employees randomly use facilities when idle between tasks.
2. Each use grants a **small stat boost** (0.5–2 stat points).
3. If a **combo is active** on that facility, stat boost is increased by 50%.
4. Stat gains from facilities accumulate but cannot exceed tier cap.

### Visual Feedback for Combos
- When a facility combo is active and an employee uses it:
  - 🔥 **Fire icon** appears above the employee's head
  - 💬 **"Active!" bubble** pops up briefly
  - ✨ **Particle sparkle effect** surrounds the facility itself
- This tells the player: this facility is combo-activated, this employee is benefiting.

### Example Facility Combos
| Combo Name | Facilities Required | Bonus |
|-----------|-------------------|-------|
| Coffee Circuit | Coffee Machine + Workstation | +Focus, +Technical |
| Gossip Zone | Lounge + Coffee Machine | +Communication, +Charm |
| Knowledge Corner | Bookshelf + Desk Lamp | +Focus, +Precision |
| Power Lunch | Cafeteria + Meeting Room | +Management, +Communication |

---

## 😤 Office Motivation & Fever Mode

**Office Motivation** is the collective energy of the entire office — aggregate of all individual employee morale.

- Displayed as 0–100% bar on HUD.
- Influences productivity, project speed, and CP generation.

### Fever Mode
- Triggers at **100% Motivation**
- Duration: **5 minutes** real time
- Effect: All stats doubled, CP earned doubled
- Visual: Screen brightens, music shifts to upbeat, fire effects everywhere
- After Fever ends: Motivation drops to **50%**

### Burnout Chain
```
Overwork → Burnout risk rises → Employee Burnout
→ Individual morale = 0 → Office Motivation drops
→ Harder to reach Fever Mode → CP generation slows
→ Projects fall behind → Reputation drops → Harder to win Donors
```
This chain must feel real and punishing enough to make morale management meaningful.

---

## 📰 CHAMP's Bulletin — World Events System

### Design Philosophy
There are no competitor NGOs. Instead, the world itself is the obstacle.

**CHAMP's Bulletin** is a news ticker / pop-up system that fires real-world-inspired events affecting field project progress. These events reflect genuine challenges NGO field staff face — weather, conflict, disease, infrastructure collapse.

CHAMP delivers each bulletin in character — cheerful, slightly absurd, but the news is always real and impactful.

> **Lore:** CHAMP is actually the easter egg biggest conglomerate on Earth — monopolizing every industry on the planet. CHAMP's Bulletin is CHAMP Corp's global news service. The fact that a monopoly megacorp delivers your NGO's crisis news is the joke — and the commentary.

### Event Categories

| Category | Example Events | Effect on Projects |
|----------|---------------|-------------------|
| 🌧️ Weather | "Rainfall 60% below seasonal average" | Dirt/soil projects −20% progress rate |
| 🌊 Flood | "Flash floods reported in target district" | All field projects paused 1 month |
| 🔥 Drought | "Severe drought — water table critical" | Irrigation projects −30% |
| ⚔️ Conflict | "Armed conflict reported near project zone — field access restricted" | Affected area projects −50%, staff safety risk |
| 🐛 Pest | "Locust swarm destroys crops in northern region" | Completed crop projects regress −10% |
| 🏚️ Infrastructure | "Bridge collapse cuts access to rural sites" | Logistics projects −25% |
| 🤒 Disease | "Illness spreading among farming communities" | Charm-based projects −15%, Morale drops |
| 📉 Funding Freeze | "HQ budget review — fund disbursement delayed 1 month" | No Cash income for 1 month |
| 🌱 Positive Event | "Unexpected rains bring early harvest" | All crop projects +10% this month |
| 🌍 Positive Event | "International media covers your NGO work" | Reputation +15 |

### How Bulletins Work
- 1–2 bulletins fire per month (randomly, weighted by season and map area)
- Pop-up appears as a CHAMP newspaper/TV broadcast visual
- Player cannot dismiss without reading — forces awareness
- Some events last 1 month, some persist for 2–3 months
- Player **cannot prevent** bulletins — only prepare for them (stronger teams, better-staffed projects)
- This is intentional: the world is unpredictable. That is the point.

### Player Response Options (for some events)
Certain bulletins give the player a choice — spending CP or Cash to mitigate:
- "Deploy emergency supply cache" → spend $500, reduce flood penalty to −10%
- "Reassign field team to safer route" → lose 2 weeks progress, avoid conflict penalty
- "Do nothing" → take the full hit

---

## 👥 Team-Based Project Implementation

### Core Rule
Projects are implemented by **teams**, not individuals. A full optimal team produces maximum % progress per cycle. Understaffed teams produce proportionally less.

### Team Composition by Project Type

| Project Type | Optimal Team | Min Viable | Roles Needed |
|-------------|-------------|-----------|-------------|
| Soil / Land | 3 staff | 1 | Technical + Procurement + Field Officer |
| Climate / Water | 3 staff | 1 | Technical + Technical + Management |
| Domestic Animals | 3 staff | 1 | Technical + Charm + Procurement |
| Agriculture Training | 4 staff | 2 | Charm + Communication + Technical + Secretarial |
| GIS / Mapping | 2 staff | 1 | Technical + Precision |
| Supply / Logistics | 3 staff | 1 | Procurement + Logistics + Management |

### Progress Rate by Team Size

| Team Size vs Optimal | Progress per Cycle |
|---------------------|-------------------|
| Full team (100%) | 100% progress rate |
| 2/3 of optimal | 65% progress rate |
| 1/2 of optimal | 40% progress rate |
| 1 person only | 20% progress rate |

### Design Intent
- Forces player to **hire diverse staff** — can't spam one type of employee
- Makes Department Structure meaningful — you literally need procurement, technical, and field roles
- Creates real tension: do you split a team to work two projects at half speed, or focus one project at full speed?
- CHAMP Bulletins hit harder when teams are understaffed — a flood with a 1-person team is devastating

---

## 🎪 CHAMP — Mascot & Shop Keeper

- **CHAMP** is the universe mascot — a friendly, enthusiastic character who runs a shop called **"CHAMP's Corner Store."**
- Unlocked **early in the game** (first or second month) — player meets CHAMP via tutorial.
- CHAMP narrates the 6-step tutorial and gifts the player their **first Donor** to complete as a tutorial reward.
- CHAMP's shop sells **one-time-use consumable items** purchasable with CP.

### Shop Items (Consumables)
| Item | Effect | CP Cost |
|------|--------|---------|
| Chocolate | +5 Energy to selected employee | 5 CP |
| Ergonomic Chair | +3 Technical (permanent, one use) | 15 CP |
| Company Manual | +8 Focus to selected employee | 10 CP |
| Motivational Poster | +5% Motivation to whole office | 20 CP |
| Premium Coffee | +10 Energy to all employees | 30 CP |
| Field Guidebook | +5 Precision to selected employee | 15 CP |

---

## 🦸 Hero Employees

Hero Employees are legendary characters with maxed or near-maxed stats and unique backstories. They are reward content for dedicated players — most players will not see them on a first playthrough.

| Name | Background | Unlock Condition |
|------|-----------|-----------------|
| Derek Anan Boonphun | All stats maxed. A tribute — the most dedicated person you will ever hire. | Hardest unlock in the game. Conditions TBD. |
| *(Thai-inspired heroes with fictionalized names — 6 more TBD)* | | |

**Implementation priority: LOW — do not implement until after Mid-game loop is stable.**

---

## 🏅 Achievement System

Short-term milestones that fire dopamine between Annual Evaluations.

| Achievement | Trigger | Reward |
|------------|---------|--------|
| First Steps | Complete first project | +20 CP |
| Welcome Aboard | Win first Donor | +1 free recruit (Tier D) |
| Fever Dream | Trigger Fever Mode for the first time | Unlock Premium Coffee in shop |
| Full Harvest | Complete all Local Area projects | New office unlock |
| Green Thumb | Reach 100% on any field area | Reputation +10 |
| Team Effort | Have 5 employees active simultaneously | +Morale boost |
| Combo Master | Activate 3 facility combos at once | CP bonus |
| No One Left Behind | 0 burnouts in a full year | Unlock Hero Employee hint |
| Top of the World | Win Annual Evaluation Year 5 | Campaign complete — Sandbox unlocks |

---

## 📅 Progression Structure

### Campaign: 5 Years
- Each year = 12 months of gameplay
- Annual Evaluation at end of each year — scored across:
  1. Project Completion Rate
  2. Field Map Progress %
  3. Office Motivation Average
  4. Reputation Score
  5. Budget Efficiency (Cash managed vs wasted)
- Compared against competitor NGOs
- Year 5 = Final Evaluation = Win condition

### Post-Campaign
- **Sandbox Mode** unlocks — no evaluation pressure, continue forever
- **Prestige System:** Reset company but keep:
  - One Hero Employee carry-over
  - +10% to all starting stats
  - Unlock new Donor types not available in run 1
  - Unlock alternate NGO themes (e.g., disaster relief, urban poverty)

---

## 🎵 Sound Design

### BGM Layers
| Situation | Style | BPM |
|-----------|-------|-----|
| Normal Office Day | Chill lo-fi + chiptune | ~90 |
| Fever Mode | Upbeat synth, energetic | ~140 |
| Annual Evaluation | Tense orchestral chiptune | ~110 |
| Bankruptcy / Crisis | Solo piano, quiet | ~60 |
| Main Menu | Catchy, memorable | ~100 |

### Key SFX (Must-Have)
- Hire employee: stamp/boing sound
- Complete project: small fanfare
- Fever Mode trigger: power-up SFX (loud, satisfying)
- Win Donor: level-up + fanfare
- Burnout: sad deflate sound
- Buy from shop: coin/cash register
- Facility combo active: sparkle chime
- Annual Eval — win: trumpet sting
- Annual Eval — lose: sad trombone

### Implementation (Godot 4)
```
AudioBus Layout:
├── Master
├── BGM (loop=true, AudioStreamInteractive for transitions)
├── SFX (AudioStreamPlayer, autoplay=false)
└── Ambient (office background noise, low volume)
```

**Priority:** Placeholder SFX from bfxr.net before first playtest. BGM from Suno.ai for prototype. Commissioned OST for launch only.

---

## 🚨 Open Design Questions (Must resolve before implementing)

1. **Project Manager Role:** Is PM a separate hire or a stat combination on any employee?
2. **Office Relocation Cost:** Exact Cash + CP cost for each scale upgrade?
3. **Competitor Count:** 1 competitor or 2? (Recommendation: start with 1)
4. **Stat Decay Rate:** How fast does facility stat gain decay when employee is inactive?
5. **Project Failure Recovery:** After donor withdraws, how long before they can be re-won?

---

## ⚙️ Technical Architecture

### Autoload Order
`SaveSystem → ClockManager → GameManager → EventManager → FacilityManager → DonorManager → CompetitorManager`

### Codebase Rules (Strictly Enforced)
- No `class_name` except in `Employee.gd` and `SaveSystem.gd`
- All variables explicitly typed; no `:=` with untyped values
- Pure ASCII in `.tscn` files
- `@onready` paths must exactly match scene tree
- Always use `proj.get("key", default)` — never `proj["key"]`

### Development Workflow
1. Claude prepares implementation prompt
2. Dos sends to Claude Code
3. Claude Code pushes feature branch
4. Dos creates + merges GitHub PR
5. `git checkout main && git pull origin main` in Git Bash
6. Test in Godot with F5

---

## 📊 Development Priority Queue

### 🔴 CRITICAL
1. Fix starting economy (salary tiers, project rewards validated)
2. First 5-minute experience — tutorial → CHAMP → first Donor → first project win

### 🟠 HIGH
3. CP trade-off balance (3 spending paths tested)
4. Burnout → Motivation → Fever chain (fully interconnected)
5. CHAMP's Bulletin — event weighting, mitigation choices, seasonal logic
6. Team composition UI — assign multiple staff to one project

### 🟡 MEDIUM
6. Achievement system
7. Department structure (PM role especially)
8. Facility combo visual feedback (fire + bubble + sparkle)
9. Field Map visual progression (greener as projects complete)
10. Project decay mechanic

### 🟢 LOW
11. Hero Employees
12. Isometric pixel art
13. "I AM CHAMP" company unlock
14. Prestige system
15. Ambient sound layer

---

## ⚠️ Known Design Risks

1. **Economy balance** — salary curve vs. project reward curve must be playtested before any other system is layered on top.
2. **CP scarcity** — if CP is too easy to earn, the 3-way trade-off collapses into no decision at all.
3. **Facility stat cap** — without tier ceiling, Tier F employees become overpowered via facility spam.
4. **CHAMP Bulletin frequency** — too many events = frustrating helplessness. Too few = no urgency. Target: 1–2 per month, max 1 severe event per quarter.
5. **Team size UI complexity** — assigning teams of 3–4 people per project must be simple and fast or it becomes micromanagement hell.
5. **Project decay** — if decay is too fast, late-game becomes maintenance hell. Too slow = no tension.
6. **Map scale jump** — Local (3 projects) to Region (7 projects) is a big complexity jump. May need a transitional difficulty curve.

---

*Pocket Office Game Bible v1.3 — Updated 2026-03-10*
*Next review: After core loop economy fix is validated in-engine.*
