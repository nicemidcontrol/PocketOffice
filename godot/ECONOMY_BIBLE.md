# Pocket Office — Economy Bible v1.0
> This file is the single source of truth for all economy numbers.
> Separate from GAME_BIBLE to reduce token cost when Claude Code needs balance data.
> Last updated: 2026-03-17

---

## Starting Conditions

| Parameter | Value |
|-----------|-------|
| Starting Cash | $10,000 |
| Starting Employees | 2 (Tier D) |
| Starting CP | 0 |
| Starting Reputation | 10 |

---

## Monthly Costs

### Salary by Tier

| Tier | Label | Monthly Salary |
|------|-------|---------------|
| F | Milk Carton | $175 |
| E | Street Recruit | $225 |
| D | Standard Hire | $275 |
| C | Skilled Staff | $375 |
| B | Senior Staff | $525 |
| A | Expert | $650 |
| S | Celebrity / Hero | $950 |

### Office Rent by Scale

| Scale | Monthly Rent |
|-------|-------------|
| Local | $100 |
| Region | $300 |
| Country | $600 |
| Regional | $1,200 |
| World | $2,500 |

### Early Game Burn Rate

- 2× Tier D ($275 each) + Local rent ($100) = **$650/month**
- $10,000 starting cash ÷ $650 = **~15 months runway** with zero income

---

## Project Rewards — Local Area (Tier 1)

Design rule: Player runs 2 projects in parallel with 1 employee each.
Each employee (Tier D, stats 25-40) contributes ~8-12% per cycle (1 cycle = 1 month).
Reaching 70% with 1 employee takes ~6-8 months.
Reaching 70% with 2 employees on same project takes ~3-4 months.
Strategy: split employees across 2 projects = slower per project but more total income.

| Project | Duration (to 70%) | Cash Reward | CP Reward | Rep Reward |
|---------|-------------------|-------------|-----------|------------|
| Farmer Training Workshop | ~3 months | $1,200 | 15 | +5 |
| Soil Quality Assessment | ~4 months | $1,800 | 20 | +5 |
| Community Nutrition Survey | ~4 months | $1,500 | 15 | +10 |
| Seed Distribution Program | ~5 months | $2,200 | 20 | +5 |
| GIS Land Mapping | ~5 months | $2,500 | 25 | +5 |
| Basic Agricultural Equipment Audit | ~4 months | $2,000 | 15 | +3 |
| Crop Rotation Planning | ~5 months | $2,000 | 30 | +3 |
| Water Irrigation Planning | ~6 months | $3,000 | 25 | +8 |

### Early Game Cash Flow Scenario (months 1-6)

Assume: 2 Tier D employees, each on separate project (1 employee per project).
Each contributes ~10% per month → 70% reached at ~month 7.
But player should STACK both employees on the easiest project first:
- Month 1-3: Both on Farmer Training Workshop → 20%/month → 60% at month 3, 70%+ at month 4
- Month 4: Collect $1,200 reward
- Month 4+: Assign to next project

**Revised flow with smart play:**

| Month | Expenses | Income | Balance |
|-------|----------|--------|---------|
| 0 | — | — | $10,000 |
| 1 | $650 | $0 | $9,350 |
| 2 | $650 | $0 | $8,700 |
| 3 | $650 | $0 | $8,050 |
| 4 | $650 | $1,200 (Farmer Training) | $8,600 |
| 5 | $650 | $0 | $7,950 |
| 6 | $650 | $0 | $7,300 |
| 7 | $650 | $1,800 (Soil Assessment) | $8,450 |
| 8 | $650 | $0 | $7,800 |
| 9 | $650 | $0 | $7,150 |
| 10 | $650 | $2,200 (Seed Distribution) | $8,700 |
| 11 | $650 | $0 | $8,050 |
| 12 | $650 | $10,000 (HQ Annual) | $17,400 |

**Result: Player never dips below $7,000 and gets a big boost at year end.**
**Cash-positive trajectory confirmed — player can hire 3rd employee around month 8-10.**

---

## Project Rewards — Region Area (Tier 2)

Unlocked after completing Local Area (3 projects at ≥70%).
Player should have 3-4 employees (mix of Tier D/C) by this point.
Monthly burn: ~$1,400-1,700/month

| Project | Duration (to 70%) | Cash Reward | CP Reward | Rep Reward |
|---------|-------------------|-------------|-----------|------------|
| Regional Food Security Assessment | ~5 months | $3,500 | 30 | +8 |
| Supply Chain Mapping | ~4 months | $2,800 | 25 | +5 |
| Livestock Health Program | ~4 months | $2,500 | 25 | +8 |
| Irrigation Network Expansion | ~6 months | $4,500 | 35 | +10 |
| Agricultural Cooperative Formation | ~5 months | $3,200 | 30 | +10 |
| Market Access Development | ~4 months | $3,000 | 25 | +8 |
| Rural Road Infrastructure Survey | ~5 months | $3,800 | 30 | +5 |
| Women Farmer Empowerment Program | ~4 months | $2,800 | 25 | +12 |
| Seed Bank Establishment | ~5 months | $3,500 | 30 | +5 |
| Post-Harvest Loss Reduction Study | ~4 months | $3,000 | 30 | +5 |
| Community Grain Storage Design | ~6 months | $4,200 | 35 | +8 |

---

## Project Rewards — Country Area (Tier 3)

Player should have 5-6 employees (mix of Tier C/B).
Monthly burn: ~$2,500-3,500/month

| Project | Cash Reward Range | CP Reward | Rep Reward |
|---------|------------------|-----------|------------|
| Country-tier projects (12 total) | $4,000 — $7,000 | 30-50 | +8-15 |

*Individual project names and exact numbers to be defined after Tier 1-2 balance is validated in playtesting.*

---

## Project Rewards — Regional Area (Tier 4)

Monthly burn: ~$5,000-8,000/month

| Project | Cash Reward Range | CP Reward | Rep Reward |
|---------|------------------|-----------|------------|
| Regional-tier projects (24 total) | $6,000 — $12,000 | 40-70 | +10-20 |

---

## Project Rewards — World Area (Tier 5)

Monthly burn: ~$10,000-18,000/month

| Project | Cash Reward Range | CP Reward | Rep Reward |
|---------|------------------|-----------|------------|
| World-tier projects (36 total) | $10,000 — $25,000 | 60-100 | +15-30 |

---

## HQ Annual Funding

Arrives at month 12 of each year automatically.

| Company Scale | Annual HQ Funding |
|--------------|-------------------|
| Local (Startup) | $10,000 |
| Region (SME) | $25,000 |
| Country (Enterprise) | $50,000 |
| Regional (Global Corp) | $100,000 |
| World (World HQ) | $200,000 |

---

## Donor Monthly Funding

Won via Research screen. Provides recurring passive income.

| Donor | CP Cost | Rep Requirement | Monthly Funding |
|-------|---------|----------------|-----------------|
| Local NGO Partner | 50 | 20+ | $500/month |
| Government Agency | 150 | 50+ | $1,500/month |
| Entertainment Corp | 200 | 60+ | $1,200/month |
| International Foundation | 300 | 80+ | $2,500/month |
| UN Partner | 500 | 100+ | $5,000/month |

---

## Recruitment Costs

| Ad Method | Cost | Tier |
|-----------|------|------|
| Milk Carton | $300 | E |
| Newspaper | $600 | D |
| Radio | $1,000 | C |
| Television | $1,800 | B |
| Online Ad | $2,200 | A |
| CHAMP's Agency | $3,500 | S |

---

## Shop Item Costs (Reference)

| Item | Cost | Effect |
|------|------|--------|
| Chocolate | $50 | +5 Energy |
| Coffee | $80 | +3 Focus |
| Company Manual | $200 | +5 Focus (permanent, small) |
| Chair | $150 | +3 Comfort stat |
| Stress Ball | $100 | -10 Stress |

---

## Facility Build Costs

| Facility | CP Cost (Blueprint) | Cash Cost (Build) |
|----------|--------------------|--------------------|
| Coffee Machine | 10 CP | $500 |
| Break Room | 15 CP | $800 |
| Meeting Room | 20 CP | $1,200 |
| Library | 25 CP | $1,500 |
| Gym | 30 CP | $2,000 |
| Lounge | 20 CP | $1,000 |
| Garden | 35 CP | $2,500 |
| Training Room | 40 CP | $3,000 |
| Meditation Room | 25 CP | $1,800 |
| Cafeteria | 30 CP | $2,200 |

---

## Balance Design Rules

1. **First project reward > 1 month salary burn** — validates the core loop
2. **Player should never feel "stuck"** — if all projects are too hard, there should always be one achievable project available
3. **Cash should feel tight but not hopeless** — player hovers between $5,000-$10,000 for most of Year 1
4. **Year 1 ending balance target: $15,000-$20,000** — enough to hire 3rd-4th employee and start Region
5. **Donor income is the scaling mechanism** — once first donor is won ($500/month), burn rate pressure eases significantly
6. **CP must always feel scarce** — if player has 200+ CP unspent, prices need rebalancing
7. **Training employees is cheaper than hiring new ones** — reward stat investment over constant recruiting
8. **Tier 3+ numbers are provisional** — finalize after Tier 1-2 is validated in playtesting

---

*Economy Bible v1.0 — Created 2026-03-17*
*Review after: First full Year 1 playtest in Godot*
