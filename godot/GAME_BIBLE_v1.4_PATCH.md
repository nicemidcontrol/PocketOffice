# Pocket Office — Game Bible v1.4 UPDATE PATCH
# This file contains the NEW sections to INSERT into Game Bible
# Replace the old "Field Map System" and "Project List" sections with this content
# Last updated: 2026-03-18

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

*Game Bible v1.4 Update Patch — Created 2026-03-18*
*This content replaces the old "Field Map System" and flat project list sections in Game Bible v1.3*
