# 📋 Pocket Office — Game Bible v1.4
> Last updated: 2026-03-18
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

## 🗺️ Field Map System — Area → Project → Task

### Structure Overview

The game world is organized in three layers:

```
AREA (geographic scale)
 └── PROJECT (a funded initiative within that area)
      └── TASK (a specific job employees are assigned to)
```

- **Area:** A geographic region (Local, Region, Country, Regional, World)
- **Project:** A multi-task initiative unlocked via Donors + REP. Each area has multiple projects.
- **Task:** The atomic unit of work. Employees are assigned to tasks, not projects. Each task has its own stat requirements, duration, and small reward.

### Key Mechanics

| Mechanic | Rule |
|----------|------|
| Task assignment | 1-3 employees per task |
| Stat contribution | Based on employee's primary/secondary stat match to task |
| Max contribution cap | 15% progress per employee per cycle (1 cycle = 1 month) |
| Task dependencies | Some tasks require other tasks to be completed first |
| Project completion | ≥70% of tasks completed = project "done" |
| Project reward | Bonus cash + CP + REP paid when project reaches ≥70% |
| Task reward | Small cash + CP paid per individual task completion |
| Decay | If no employees assigned to ANY task in a project for 3+ months, project progress decays at 2%/month |
| Shared tasks | Same task type may appear in multiple projects — must be completed separately each time |

### Passive Gains (While Working)

Employees gain stats and CP passively through daily activity:

| Activity | Gain | Example |
|----------|------|---------|
| Working on a task | +stat matching task's primary/secondary | "Soil Sample Collection" → Technical +1, Precision +0.5 |
| Using facility (idle) | +stat matching facility type + small CP | Library → Focus +1, +2 CP |
| Facility combo active | +50% stat bonus, +50% CP bonus | Library + Meeting Room → Focus +1.5, +3 CP |
| Task completion | One-time stat bump to assigned employees | Completing technical task → Technical +2 to all assigned |

**Design insight:** Players who strategically assign employees to stat-building tasks (not just highest-paying ones) will progress faster in later projects. This is the hidden depth.

### Area Completion & Progression

| Scale | Projects | Unlock |
|-------|----------|--------|
| 1. Local | 3 projects | Game start |
| 2. Region | 7 projects | Complete Local Area |
| 3. Country | 12 projects | Complete Region Area |
| 4. Regional | 24 projects | Complete Country Area |
| 5. World | 36 projects | Complete Regional Area |

When ALL projects in an area reach ≥70%:
- Office relocates to next scale (one-time Cash + CP cost)
- New Donors become available in Research screen
- Higher recruitment tiers unlock
- New facility blueprints unlock
- Visual: map becomes greener, people walk normally

---

## 🏘️ LOCAL AREA — "Ban Nong Khao"

> "A forgotten rice village where the soil is tired, the water is far,
> and the last NGO that visited left behind nothing but a faded banner."

### Projects

| # | Project Name | Tasks | Unlock | Reward (≥70%) |
|---|-------------|-------|--------|---------------|
| 1 | Who Needs What? | 4 | FREE — game start | $2,000 + 25 CP + 10 REP |
| 2 | Dirt Don't Lie | 5 | Donor: Local NGO Partner | $4,500 + 40 CP + 15 REP |
| 3 | Water Finds a Way | 7 | Donor: Government Agency | $8,000 + 60 CP + 25 REP |

### Local Donors

| Donor | CP Cost | REP Req | Monthly Funding | Unlocks |
|-------|---------|---------|-----------------|---------|
| Local NGO Partner | 50 CP | REP 20+ | $500/mo | Project 2 |
| Government Agency | 150 CP | REP 50+ | $1,500/mo | Project 3 |

---

### PROJECT 1: "Who Needs What?" (FREE)

*"Your first real assignment. Walk into a village you've never been to,
ask 200 strangers what they need, and pretend you're not terrified. Welcome to NGO life."*

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Door-to-Door Survey | "Knock on 200 doors. 50 will open. 10 will offer you water. 3 will try to sell you chickens." | Charm | Communication | 2 | $400 + 5 CP |
| 2 | Village Leader Interview | "Meet the village chief. He's been chief for 40 years and remembers when the last road was built. It wasn't." | Charm | Management | 1 | $300 + 5 CP |
| 3 | Data Entry & Analysis | "Turn 200 handwritten surveys into a spreadsheet. Half are in pencil. Some are in crayon." | Focus | Technical | 2 | $400 + 5 CP |
| 4 | Needs Assessment Report | "Summarize everything into a 20-page report that your donor will skim in 3 minutes." | Communication | Focus | 2 | $500 + 8 CP |

**Dependencies:**
```
[1: Door-to-Door Survey] ──→ [3: Data Entry] ──→ [4: Report]
[2: Village Leader Interview] (parallel with 1)
```

---

### PROJECT 2: "Dirt Don't Lie"

*"The soil here hasn't been tested since... ever, actually. Farmers have been
planting the same rice for three generations and wondering why yields drop every year.
Time to play dirt detective."*

**Unlock:** Donor "Local NGO Partner" (50 CP, REP 20+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Soil Sample Collection | "Dig 50 holes across the village. Bag the dirt. Label each one. Try not to dig up anyone's ancestor." | Technical | Precision | 2 | $500 + 5 CP |
| 2 | Lab Analysis Coordination | "Send soil to the city lab. The lab says results take 2 weeks. It's been 2 months. Follow up. Again." | Procurement | Communication | 3 | $600 + 8 CP |
| 3 | Farmer Training Workshop | "Teach crop rotation to farmers who've been farming since before you were born. Bring humility." | Charm | Communication | 2 | $500 + 8 CP |
| 4 | Seed Selection & Distribution | "Source quality seeds. Distribute to 80 families. Explain that these are for planting, not eating. Twice." | Procurement | Logistics | 3 | $700 + 10 CP |
| 5 | Crop Monitoring Setup | "Install monitoring points across 30 hectares. The goats will eat 4 of them. Budget for 5." | Technical | Management | 2 | $600 + 8 CP |

**Dependencies:**
```
[1: Soil Samples] ──→ [2: Lab Analysis] ──→ [3: Farmer Training]
                                         ──→ [4: Seed Distribution]
                                         ──→ [5: Crop Monitoring]
```

---

### PROJECT 3: "Water Finds a Way"

*"Three villages, one river, zero infrastructure.
The water is technically there — it's the 'getting it to the rice fields'
part that requires an engineering degree and a miracle."*

**Unlock:** Donor "Government Agency" (150 CP, REP 50+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Water Source Survey | "Find every water source within 20km. Map them. Discover that 3 are seasonal and 1 is a myth." | Technical | Precision | 2 | $600 + 8 CP |
| 2 | GIS Land Mapping | "Map every hectare with satellite data. The satellite is accurate. Your intern's labeling is not." | Technical | Focus | 3 | $800 + 10 CP |
| 3 | Community Consultation | "Hold 5 village meetings to discuss water rights. Meeting 1: productive. Meeting 5: someone brought a lawyer." | Charm | Management | 2 | $500 + 8 CP |
| 4 | Irrigation Design Blueprint | "Design canals that serve 3 villages equally. Village 3 will still complain they got less." | Technical | Management | 3 | $900 + 12 CP |
| 5 | Procurement & Materials | "Order 2km of PVC pipe, 500 cement bags, and 1 excavator rental. The excavator arrives 3 weeks late. Classic." | Procurement | Logistics | 3 | $800 + 8 CP |
| 6 | Construction Supervision | "Supervise 40 workers building canals in 38-degree heat. Motivation tool: cold water and loud music." | Management | Technical | 4 | $1,200 + 12 CP |
| 7 | System Testing & Handover | "Turn on the water. Pray. Fix the 3 leaks. Turn it on again. Celebrate when rice fields actually flood." | Technical | Communication | 2 | $800 + 10 CP |

**Dependencies:**
```
[1: Water Survey]      ──→ [4: Irrigation Design] ──→ [5: Procurement] ──→ [6: Construction] ──→ [7: Testing]
[2: GIS Mapping]       ──↗
[3: Community Consult] (parallel, no dependency)
```

---

## 🌾 REGION AREA — "Isan Lowlands"

> "Four provinces, twelve districts, and a thousand rice paddies that
> flood every year. The government says help is coming. It's been coming
> for 20 years. That's where you come in."

### Projects

| # | Project Name | Tasks | Unlock | Reward (≥70%) |
|---|-------------|-------|--------|---------------|
| 1 | How Hungry Are We, Really? | 5 | FREE — auto on Local complete | $5,000 + 40 CP + 15 REP |
| 2 | Where Does the Rice Go? | 5 | Donor: Provincial Agriculture Office | $6,000 + 45 CP + 15 REP |
| 3 | The Vet Has Never Been Here | 4 | Donor: Provincial Agriculture Office | $5,500 + 40 CP + 20 REP |
| 4 | Water For Everyone (In Theory) | 6 | Donor: Regional Development Bank | $8,000 + 55 CP + 20 REP |
| 5 | Cut The Middleman | 5 | Donor: Regional Development Bank | $7,000 + 50 CP + 20 REP |
| 6 | The Unsung Farmers | 6 | Donor: International Aid Consortium | $9,000 + 60 CP + 30 REP |
| 7 | Same Flood, Every Year | 7 | Donor: International Aid Consortium | $10,000 + 70 CP + 30 REP |

### Region Donors

| Donor | CP Cost | REP Req | Monthly Funding | Unlocks |
|-------|---------|---------|-----------------|---------|
| Provincial Agriculture Office | 80 CP | REP 30+ | $800/mo | Projects 2, 3 |
| Regional Development Bank | 120 CP | REP 45+ | $1,200/mo | Projects 4, 5 |
| International Aid Consortium | 200 CP | REP 65+ | $2,000/mo | Projects 6, 7 |

---

### PROJECT 1: "How Hungry Are We, Really?" (FREE)

*"Your NGO just got promoted to regional scale. First order of business:
figure out how bad things actually are across four provinces.
Spoiler: worse than the last report said."*

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Multi-District Survey Design | "Design a survey that works across 12 districts. Each district insists their problems are unique. They're not." | Management | Communication | 2 | $600 + 8 CP |
| 2 | Field Team Deployment | "Send 4 teams to 4 provinces simultaneously. Team 3 will get lost. Budget for a rescue call." | Management | Logistics | 3 | $800 + 10 CP |
| 3 | Provincial Data Collection | "Collect harvest data from 200 sub-districts. Half report in metric. Half report in 'bags of rice.'" | Technical | Precision | 3 | $700 + 8 CP |
| 4 | Cross-District Analysis | "Compare food security across all districts. Discover that the 'best' district is still below national average." | Technical | Focus | 2 | $600 + 8 CP |
| 5 | Regional Strategy Report | "Write THE report. The one that gets presented to the governor. Use graphs. Governors love graphs." | Communication | Management | 3 | $900 + 12 CP |

**Dependencies:**
```
[1: Survey Design] ──→ [2: Field Deployment] ──→ [3: Data Collection] ──→ [4: Analysis] ──→ [5: Report]
```

---

### PROJECT 2: "Where Does the Rice Go?"

*"Rice goes from field to market through 7 middlemen, 3 trucks of questionable reliability,
and one bridge that closes every monsoon. Let's fix that."*

**Unlock:** Donor "Provincial Agriculture Office" (80 CP, REP 30+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Middleman Network Mapping | "Interview every buyer, broker, and 'uncle who knows a guy.' The supply chain has more branches than a banyan tree." | Charm | Communication | 2 | $700 + 8 CP |
| 2 | Transport Route Assessment | "Drive every route farmers use. Document potholes. Run out of paper." | Technical | Logistics | 3 | $800 + 10 CP |
| 3 | Price Disparity Study | "Track rice prices from farm gate to city market. The markup will make you angry." | Technical | Focus | 2 | $600 + 8 CP |
| 4 | Cooperative Logistics Hub Design | "Design a central collection point. Convince 5 villages to share it. Village politics: harder than engineering." | Management | Charm | 3 | $900 + 10 CP |
| 5 | Pilot Route Implementation | "Test the new route for 3 months. It saves 40% on transport. The old middlemen are not pleased." | Procurement | Management | 3 | $800 + 10 CP |

**Dependencies:**
```
[1: Middleman Mapping] ──→ [4: Hub Design] ──→ [5: Pilot Route]
[2: Route Assessment]  ──↗
[3: Price Study] (parallel)
```

---

### PROJECT 3: "The Vet Has Never Been Here"

*"Every family owns at least 2 buffalo and 10 chickens. Nobody has
vaccinated any of them. Ever. The vet clinic is 80km away and closed on Thursdays."*

**Unlock:** Donor "Provincial Agriculture Office" (80 CP, REP 30+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Livestock Census | "Count every animal in 8 districts. The chickens will not cooperate with the census." | Technical | Precision | 3 | $700 + 8 CP |
| 2 | Vaccine Procurement & Cold Chain | "Order 5,000 doses. Keep them cold. The refrigerator truck breaks down twice. Classic procurement." | Procurement | Logistics | 3 | $900 + 10 CP |
| 3 | Mobile Vet Clinic Deployment | "Bring the vet to the village. First time in history. Children will stare. Buffalo will flee." | Charm | Technical | 3 | $800 + 10 CP |
| 4 | Farmer Animal Health Training | "Teach farmers basic animal care. Explain that 'traditional medicine' is not peer-reviewed." | Charm | Communication | 2 | $600 + 8 CP |

**Dependencies:**
```
[1: Livestock Census] ──→ [2: Vaccine Procurement] ──→ [3: Mobile Vet Clinic]
                                                    ──→ [4: Farmer Training] (parallel with 3)
```

---

### PROJECT 4: "Water For Everyone (In Theory)"

*"The canals you built in Local Area? Imagine that times ten,
across two provinces, with three river systems that don't agree
on which direction to flow during monsoon."*

**Unlock:** Donor "Regional Development Bank" (120 CP, REP 45+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | River Basin Survey | "Map 3 river systems. Discover that the 'seasonal stream' on the old map is now a permanent swamp." | Technical | Precision | 3 | $800 + 10 CP |
| 2 | Cross-Province Water Rights Negotiation | "Two provinces share one river. Both want priority. Bring snacks to the meeting. It'll be long." | Charm | Management | 3 | $700 + 8 CP |
| 3 | Canal Network Blueprint | "Design 40km of canals on paper. Budget says 25km. Compromise at 32km and pray." | Technical | Management | 4 | $1,200 + 12 CP |
| 4 | Heavy Equipment Procurement | "Rent 3 excavators, 2 bulldozers, and a crane. The crane was supposed to arrive last Tuesday." | Procurement | Logistics | 3 | $1,000 + 10 CP |
| 5 | Multi-Site Construction | "Build canals in 4 locations simultaneously. Supervise from a motorcycle. Eat lunch at the noodle stand between sites." | Management | Technical | 5 | $1,500 + 15 CP |
| 6 | Flow Testing & Community Training | "Open the gates. Water flows. Farmers cheer. One canal leaks. Fix it before anyone notices." | Technical | Communication | 2 | $800 + 10 CP |

**Dependencies:**
```
[1: River Survey]  ──→ [3: Canal Blueprint] ──→ [4: Procurement] ──→ [5: Construction] ──→ [6: Testing]
[2: Water Rights]  ──↗
```

---

### PROJECT 5: "Cut The Middleman"

*"Farmers grow great rice but sell it for nothing because
the nearest market is 60km away and controlled by two families
who've been setting prices since 1987."*

**Unlock:** Donor "Regional Development Bank" (120 CP, REP 45+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Market Price Intelligence | "Track prices at 15 markets for 3 months. Discover the price difference between buying and selling is criminal." | Technical | Focus | 3 | $700 + 10 CP |
| 2 | Cooperative Legal Registration | "Register a farmer cooperative. Navigate 14 forms, 3 offices, and 1 clerk who only works mornings." | Management | Communication | 2 | $600 + 8 CP |
| 3 | Cooperative Leadership Training | "Train elected farmer leaders. Teach accounting. Watch them discover that their old buyer was cheating them." | Charm | Management | 3 | $800 + 10 CP |
| 4 | Direct Market Channel Setup | "Connect the cooperative directly to city buyers. Cut out 4 middlemen. Receive 4 angry phone calls." | Communication | Charm | 3 | $900 + 10 CP |
| 5 | First Harvest Collective Sale | "The cooperative's first group sale. Everyone watches the price. It's 35% higher than last year. Tears of joy." | Procurement | Communication | 2 | $800 + 10 CP |

**Dependencies:**
```
[1: Price Intelligence] ──→ [4: Direct Market] ──→ [5: First Sale]
[2: Legal Registration] ──→ [3: Leadership Training] ──↗
```

---

### PROJECT 6: "The Unsung Farmers"

*"They do most of the work, know the soil better than any textbook,
and haven't gotten proper credit since... well, ever. Time to change that."*

**Unlock:** Donor "International Aid Consortium" (200 CP, REP 65+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Community Livelihood Survey | "Survey 500 households about who does what on the farm. The data will surprise everyone except the farmers themselves." | Charm | Focus | 3 | $700 + 10 CP |
| 2 | Savings Group Formation | "Help form savings circles in 10 villages. First meeting: nervous silence. Third meeting: business plans." | Charm | Communication | 3 | $800 + 10 CP |
| 3 | Nutrition Education Program | "Teach families about balanced diets using local ingredients. Main obstacle: 'We've always eaten this way.'" | Communication | Charm | 2 | $600 + 8 CP |
| 4 | Kitchen Garden Initiative | "Set up home vegetable gardens for 200 families. Provide seeds, tools, and the hope that the chickens won't eat everything." | Procurement | Technical | 3 | $900 + 10 CP |
| 5 | Land Rights Awareness Workshop | "Explain land title processes. Half the room takes notes. The other half goes straight to the land office." | Communication | Management | 2 | $700 + 10 CP |
| 6 | Community Market Day Launch | "Organize a monthly market run by local farmers. Opening day: 3x expected attendance. The noodle stall sells out first." | Management | Charm | 2 | $800 + 12 CP |

**Dependencies:**
```
[1: Livelihood Survey] ──→ [2: Savings Groups] ──→ [6: Market Day Launch]
                       ──→ [3: Nutrition Education] ──→ [4: Kitchen Gardens]
                       ──→ [5: Land Rights] (parallel)
```

---

### PROJECT 7: "Same Flood, Every Year"

*"Every monsoon, the same 30 villages flood. Every year, everyone acts surprised.
This project aims to make next year's flood the first one anyone is actually prepared for."*

**Unlock:** Donor "International Aid Consortium" (200 CP, REP 65+)

**Tasks:**

| # | Task | Description | Primary | Secondary | Duration | Reward |
|---|------|-------------|---------|-----------|----------|--------|
| 1 | Historical Flood Pattern Analysis | "Study 20 years of flood data. Pattern: it floods. Every. Single. Year. Same. Places." | Technical | Focus | 3 | $800 + 10 CP |
| 2 | Community Risk Mapping | "Walk every village with GPS and elders. Elders know exactly where the water goes. GPS confirms they're right." | Technical | Charm | 3 | $800 + 10 CP |
| 3 | Early Warning System Design | "Install river gauges and SMS alerts. Test the system. 3 villages respond. 7 thought it was spam." | Technical | Communication | 3 | $900 + 12 CP |
| 4 | Evacuation Route Planning | "Plan routes for 30 villages. Discover that the 'official' evacuation route floods first." | Management | Logistics | 2 | $700 + 8 CP |
| 5 | Emergency Supply Pre-Positioning | "Store rice, water, and medicine in high-ground warehouses. The warehouse roof leaks. Fix that first." | Procurement | Logistics | 3 | $900 + 10 CP |
| 6 | Community Drill & Training | "Run a flood drill with 500 people. Objective: everyone reaches high ground in 30 minutes. Result: 45 minutes. Better than last year's 'never.'" | Charm | Management | 2 | $700 + 10 CP |
| 7 | Climate-Adapted Crop Introduction | "Introduce flood-resistant rice varieties. Farmers are skeptical. Promise them it tastes the same. Cross your fingers." | Technical | Charm | 3 | $900 + 12 CP |

**Dependencies:**
```
[1: Flood Analysis]  ──→ [3: Early Warning] ──→ [6: Community Drill]
[2: Risk Mapping]    ──→ [4: Evacuation Routes] ──↗
                     ──→ [5: Emergency Supplies] (parallel)
[7: Climate Crops] (independent, can start anytime)
```

---

## 💰 Economy Summary — Local + Region

### Local Area Total

| Source | Cash | CP | REP |
|--------|------|----|-----|
| All tasks (16) | $10,100 | 130 CP | — |
| All project bonuses (3) | $14,500 | 125 CP | +50 |
| **Local Total** | **$24,600** | **255 CP** | **+50** |

### Region Area Total

| Source | Cash | CP | REP |
|--------|------|----|-----|
| All tasks (38) | $30,400 | 370 CP | — |
| All project bonuses (7) | $50,500 | 360 CP | +150 |
| **Region Total** | **$80,900** | **730 CP** | **+150** |

### Combined Donor Monthly Income (if all won)

| Donor | Monthly |
|-------|---------|
| Local NGO Partner | $500 |
| Government Agency | $1,500 |
| Provincial Agriculture Office | $800 |
| Regional Development Bank | $1,200 |
| International Aid Consortium | $2,000 |
| **Total** | **$6,000/mo** |

---

## 📋 Remaining Areas (Tier 3-5)

Country, Regional, and World areas follow the same Area → Project → Task structure.
Exact project/task content will be designed after Local + Region are validated in playtesting.

| Area | Projects | Estimated Total Cash | Estimated Total CP |
|------|----------|---------------------|--------------------|
| Country | 12 | ~$180,000 | ~1,500 CP |
| Regional | 24 | ~$500,000 | ~4,000 CP |
| World | 36 | ~$1,200,000 | ~10,000 CP |

*Numbers are provisional — finalize after Tier 1-2 balance validated.*

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

## 😄 Humor Naming Convention

All player-facing names use a dual-name format:
- **Large text:** Humor Title (what player sees first)
- **Small text:** Official Name (subtitle, grey)

Example in UI:
```
┌──────────────────────────┐
│  "Knock Knock, Anyone    │
│       Home?"             │  ← Large, white
│   Door-to-Door Survey    │  ← Small, grey
│                          │
│  Charm | Communication   │
│  2 ticks | $400 + 5 CP   │
└──────────────────────────┘
```

This applies to: all tasks in Project Board, all employees in Hire Screen and Employee List, all items in Shop, all facilities in Build Screen, and all project names on the Field Map.

See **godot/Humor naming bible.md** for the complete reference — every task, employee, shop item, and facility has both names defined there.

---

*Pocket Office Game Bible v1.4 — Updated 2026-03-18*
*Next review: After Local Area task structure is validated in-engine.*
