# Pocket Office -- v1.4 to v1.5.2 Migration Plan

> Created: 2026-05-01
> Branch: recon/migration-plan-v152
> Author: Claude Code recon pass

---

## 1. Executive Summary

The codebase is a working v1.4 game (~8,870 lines of GDScript) built around Work Round
mechanics, a grade system (S/A/B/C/D/F), and a single-stat task structure. v1.5.2
replaces the entire core loop: Work Rounds become Phase Animations, grades are removed,
tasks gain a 3-4 phase structure, and seven new autoload managers are required. The
migration is a medium-large scope rewrite -- roughly 40% of existing logic is deleted,
40% is refactored, and 20% carries over unchanged. The project has zero art assets (all
.gitkeep), so the v1.5.2 build will run with placeholder sprites throughout. Biggest
risks: the task data structure is fundamentally incompatible with saved v1.4 games
(recommend a clean wipe), and the Phase Animation system is a net-new UI component with
no existing analog in the codebase. Two referenced open branches are already merged and
should be deleted.

---

## 2. Codebase Inventory

### 2.1 Autoloads (registered in project.godot)

| Name | Path | Lines |
|------|------|-------|
| SaveSystem | res://SaveSystem.gd | 58 |
| ClockManager | res://ClockManager.gd | 75 |
| GameManager | res://GameManager.gd | 428 |
| EventManager | res://scripts/EventManager.gd | 474 |
| FacilityManager | res://scripts/FacilityManager.gd | 229 |
| DonorManager | res://scripts/DonorManager.gd | 214 |
| CompetitorManager | res://scripts/CompetitorManager.gd | 54 |
| CHAMPBulletinManager | res://scripts/CHAMPBulletinManager.gd | 334 |
| InternalProblemManager | res://scripts/InternalProblemManager.gd | 231 |

NOTE: GameManager dynamically instantiates five sub-managers at runtime via load():
EmployeeManager (379 lines), EconomyManager (122), ProjectManager (1016),
EventManager-root (154, see §3.2), and OfficeManager (146). These are NOT autoloads;
they live at GameManager.employees / .economy / .projects / .events / .office.

### 2.2 Scenes (.tscn)

| Scene | Script | Notes |
|-------|--------|-------|
| scenes/Main.tscn | scripts/ui/Main.gd (306) | Main scene, entry point |
| scenes/OfficeView.tscn | scripts/ui/OfficeView.gd (187) | Idle office display |
| scenes/HUD.tscn | scripts/ui/HUD.gd (100) | Cash/CP/Motivation bar |
| scenes/BottomBar.tscn | scripts/ui/BottomBar.gd (48) | Nav buttons |
| scenes/ProjectBoard.tscn | scripts/ui/ProjectBoard.gd (345) | Project/task display |
| scenes/HireScreen.tscn | scripts/ui/HireScreen.gd (270) | Recruit screen |
| scenes/TrainingScreen.tscn | scripts/ui/TrainingScreen.gd (491) | Train stats |
| scenes/EvaluationScreen.tscn | scripts/ui/EvaluationScreen.gd (347) | Work Round results |
| scenes/BuildScreen.tscn | scripts/ui/BuildScreen.gd (182) | Facility building |
| scenes/ShopScreen.tscn | scripts/ui/ShopScreen.gd (155) | CHAMP shop |
| scenes/ResearchScreen.tscn | scripts/ui/ResearchScreen.gd (196) | Donor research |
| scenes/EmployeeListScreen.tscn | scripts/ui/EmployeeListScreen.gd (118) | Staff list |
| scenes/EventPopup.tscn | scripts/ui/EventPopup.gd (123) | Event notification |
| scenes/TutorialOverlay.tscn | scripts/ui/TutorialOverlay.gd (136) | v1.4 tutorial (old) |
| scenes/PauseMenu.tscn | scripts/ui/PauseMenu.gd (141) | Pause/settings |
| scenes/DebugMenu.tscn | scripts/ui/DebugMenu.gd (108) | Dev tools |
| scenes/ui/BaseModal.tscn | scripts/ui/BaseModal.gd (59) | Modal standard |
| scenes/ui/CHAMPBulletinPopup.tscn | scripts/ui/CHAMPBulletinPopup.gd (100) | CHAMP news |
| scenes/ui/InternalAlertPanel.tscn | scripts/ui/InternalAlertPanel.gd (118) | HR/internal alerts |

NOTE: scripts/ui/TaskDetailView.gd (343 lines) and scripts/ui/WorkRoundResult.gd (290)
exist as scripts but have no corresponding .tscn -- they are instantiated programmatically
by ProjectBoard.

NOTE: scenes/main.tscn at godot root (separate from scenes/Main.tscn) is the actual
run/main_scene per project.godot.

### 2.3 Scripts (non-UI, non-autoload)

| File | Lines | Role |
|------|-------|------|
| Employee.gd | 289 | class_name Employee -- serialization / stat model |
| EmployeeManager.gd | 379 | Sub-manager -- employee roster, hire/fire |
| ProjectManager.gd | 1016 | Sub-manager -- project data, Work Round logic |
| EconomyManager.gd | 122 | Sub-manager -- cash, CP, salary |
| OfficeManager.gd | 146 | Sub-manager -- facility combos |
| EventManager.gd (root) | 154 | Sub-manager -- event pool, random trigger |
| scripts/TrainingManager.gd | 230 | Standalone -- CP training calculations |
| scripts/ui/UnlockPopup.gd | 133 | UI helper -- unlock notifications |

### 2.4 Tests

| File | Test functions | What it tests |
|------|---------------|---------------|
| tests/unit/test_grade_calculator.gd | 19 | _grade_from_progress() in ProjectManager |
| tests/unit/test_training_cp_cost.gd | 8 | get_total_cp_cost() in TrainingManager |
| tests/unit/test_sanity.gd | 2 | Platform invariants (1+1=2, true=true) |
| **Total** | **29** | |

### 2.5 Data

All task/project data is inline inside ProjectManager.gd starting at line ~70.
Local Area only (3 projects, 16 tasks) is implemented. Region+ areas exist in the
game bibles but not in code. No separate data files; all data embedded in GDScript.

### 2.6 Assets

| Location | Contents |
|----------|----------|
| assets/sprites/ui/ | .gitkeep only |
| assets/sprites/tiles/ | .gitkeep only |
| assets/sprites/characters/ | .gitkeep only |
| assets/sprites/facilities/ | .gitkeep only |
| assets/sprites/effects/ | .gitkeep only |

Zero actual art assets exist. All v1.5.2 UI must be built with placeholder art.

---

## 3. System Classifications

### Keep (green)

| System | File(s) | Lines | Reason |
|--------|---------|-------|--------|
| SaveSystem | SaveSystem.gd | 58 | class_name, static save/load -- extend with new keys only |
| ClockManager | ClockManager.gd | 75 | Unchanged; needs one new signal: phase_completed |
| BaseModal | scenes/ui/BaseModal.tscn + scripts/ui/BaseModal.gd | 59 | UI standard per CLAUDE.md -- do not change |
| FacilityManager | scripts/FacilityManager.gd | 229 | Facility system unchanged in v1.5.2 |
| DonorManager | scripts/DonorManager.gd | 214 | Donor-win flow unchanged; recurring revenue is new (RecurringManager) |
| CompetitorManager | scripts/CompetitorManager.gd | 54 | Unchanged |
| CHAMPBulletinManager | scripts/CHAMPBulletinManager.gd | 334 | Keep structure; update event effect hooks (see §3.2) |
| CHAMPBulletinPopup | scenes/ui/CHAMPBulletinPopup.tscn + .gd | 100 | Visual unchanged; hooks update |
| PauseMenu | scenes/PauseMenu.tscn + .gd | 141 | No changes needed |
| DebugMenu | scenes/DebugMenu.tscn + .gd | 108 | Keep; add phase/stamina debug controls later |
| BuildScreen | scenes/BuildScreen.tscn + .gd | 182 | Facility build unchanged |
| ShopScreen | scenes/ShopScreen.tscn + .gd | 155 | Extend later for stat items; no changes in early PRs |
| ResearchScreen | scenes/ResearchScreen.tscn + .gd | 196 | Donor research unchanged |
| OfficeManager | OfficeManager.gd | 146 | Facility combos unchanged |
| OfficeView | scenes/OfficeView.tscn + .gd | 187 | Idle office display -- extend for phase overlay layering |
| test_sanity.gd | tests/unit/test_sanity.gd | 7 | Platform invariants; always keep |

### Refactor (yellow)

| System | File(s) | Lines | Changes Required |
|--------|---------|-------|-----------------|
| Employee.gd | Employee.gd | 289 | Add: sp_current, sp_max (int), promotion_ceilings (Dictionary), portrait_id (int). Remove: no field deletions -- keep all 8 stats. to_dict()/from_dict() extended. |
| EmployeeManager.gd | EmployeeManager.gd | 379 | Add SP recovery method (called by StaminaManager), add methods to query by role (for phase eligibility), add ceiling-check helper for PromotionManager. |
| ProjectManager.gd | ProjectManager.gd | 1016 | Major: (1) Delete all grade math (_grade_from_progress, run_work_round, _build_contribution_list). (2) Replace task data structure from {primary_stat, secondary_stat, progress, assigned_employee_ids} to {phases[], phase_results[], status, used_employee_ids_this_task}. (3) Add phase_complete(task_id, phase_idx, emp_id, contribution) method. (4) Add task_total() and project_total() helpers. (5) Add save format bump from _v:2 to _v:3 with migration path. |
| GameManager.gd | GameManager.gd | 428 | Add instantiation of new sub-managers (if not autoloads). Update save_game/load_game to persist new keys: company_data["protagonist"], tutorial_flags. Add phase_counter for weekly cycle trigger. |
| EconomyManager.gd | EconomyManager.gd | 122 | Add: recurring_revenue_tick(project_id, tier) -- called monthly by RecurringManager. Extend to_save_dict/from_save_dict. |
| EventManager (scripts/) | scripts/EventManager.gd | 474 | Update weekly cycle trigger: replace "5 work rounds" with "5 phases completed" counter. |
| EventManager (root) | EventManager.gd | 154 | See §3.3 -- this is a separate file from scripts/EventManager.gd. Rename or consolidate to avoid confusion. |
| EvaluationScreen | scenes/EvaluationScreen.tscn + scripts/ui/EvaluationScreen.gd | 347 | Repurpose as FinalEvaluationModal. Current scene shows Work Round grade result -- replace content with project-end donor evaluation reveal (Tier 1-5, total score, recurring summary). Keep BaseModal structure. |
| HUD | scenes/HUD.tscn + scripts/ui/HUD.gd | 100 | Add SP pip indicators per employee card in HUD. Add phase counter (N/5 phases this week). |
| ProjectBoard | scenes/ProjectBoard.tscn + scripts/ui/ProjectBoard.gd | 345 | Rewire: remove direct task-start logic. "Projects" button now opens ProjectListModal. ProjectBoard becomes a thin coordinator. |
| HireScreen | scenes/HireScreen.tscn + scripts/ui/HireScreen.gd | 270 | Add role display (PM / Field Officer / Supply Officer etc.). Minor updates only. |
| EmployeeListScreen | scenes/EmployeeListScreen.tscn + .gd | 118 | Add SP pips, tier display. Minor updates. |
| TutorialOverlay | scenes/TutorialOverlay.tscn + scripts/ui/TutorialOverlay.gd | 136 | Replace with UnifiedPopup + TutorialPopup pattern from UI_SYSTEMS_BIBLE. Old overlay is v1.4 simple text; new system needs pages, banner, artwork, once-only tracking. |
| TrainingScreen | scenes/TrainingScreen.tscn + scripts/ui/TrainingScreen.gd | 491 | Update ceiling display: training now shows progress toward promotion ceiling per stat, not just raw stat value. |
| TrainingManager | scripts/TrainingManager.gd | 230 | Add: ceiling-aware training cap (train stops at current tier ceiling). test_training_cp_cost tests may survive this refactor. |

### Delete (red)

| System | File(s) | Lines | Reason |
|--------|---------|-------|--------|
| Work Round Result | scripts/ui/WorkRoundResult.gd | 290 | Work Round mechanic removed entirely. This helper animated in-place grade reveals. No analog in v1.5.2. |
| TaskDetailView | scripts/ui/TaskDetailView.gd | 343 | Replaced by TaskListModal (new) with phase preview. |
| Grade calculation | ProjectManager.gd lines 660-700 + _grade_from_progress() at line 786 | ~60 loc | S/A/B/C/D/F grade system removed. Delete run_work_round(), _build_contribution_list(), _grade_from_progress(), grade match blocks. |
| test_grade_calculator | tests/unit/test_grade_calculator.gd | 76 | Tests a deleted system. Delete after removing grade calc from ProjectManager. |
| InternalProblemManager | scripts/InternalProblemManager.gd + scenes/ui/InternalAlertPanel.tscn + .gd | 349 | HR problem system not in v1.5.2 scope. Confirm no callers before deletion. |
| Root EventManager duplicate | EventManager.gd (root) | 154 | See §3.2. After consolidation, this file should be removed. |
| Old game bibles | GAME_BIBLE_v1.2, GAME_BIBLE_v1.3.md | -- | No longer source of truth. Move to godot/archive/ or delete. |

### Create (new)

See §4 for full specs.

---

## 3.2 Architectural Note: Two EventManagers

There are currently TWO files named EventManager:

- `godot/EventManager.gd` (154 lines) -- internal event POOL used by GameManager.events.
  This manages the "try_trigger_random_event" random event pool. GameManager instantiates
  it via `load("res://EventManager.gd").new()`.

- `godot/scripts/EventManager.gd` (474 lines) -- the registered AUTOLOAD that manages
  the event trigger/popup display pipeline. This is the one in project.godot.

These serve different purposes and should be renamed to avoid confusion. Recommendation:
- Rename root `EventManager.gd` to `EventPoolManager.gd` (or merge into GameManager)
- Keep `scripts/EventManager.gd` as the autoload under its current name

This rename should happen in PR-1 (cleanup pass).

---

## 4. New Systems Required

### 4.1 New Autoloads

All new autoloads insert AFTER the existing chain. Proposed order:
`SaveSystem -> ClockManager -> GameManager -> StaminaManager -> ParameterTracker ->
TutorialManager -> EventManager -> FacilityManager -> DonorManager -> CompetitorManager
-> ItemManager -> PromotionManager -> CHAMPBulletinManager -> RecurringManager`

| Autoload | Proposed Path | Purpose | Dependencies |
|----------|--------------|---------|--------------|
| PhaseManager | scripts/managers/PhaseManager.gd | Drives phase animation timing, subround contribution math, SP consumption, phase_completed signal emission | GameManager, StaminaManager, ParameterTracker |
| StaminaManager | scripts/managers/StaminaManager.gd | Tracks sp_current per employee, SP recovery on weekly cycle, eligibility check (>=3 SP) | GameManager.employees |
| ParameterTracker | scripts/managers/ParameterTracker.gd | Accumulates parameter totals (PLANNING/EXECUTION/LOGISTICS/COMMUNITY) per task and per project; computes task_total and project_total for reward tier | GameManager.projects |
| RecurringManager | scripts/managers/RecurringManager.gd | Registers projects in 6-month payout window; on monthly clock tick, pays recurring revenue per donor tier table | EconomyManager, ClockManager |
| TutorialManager | scripts/managers/TutorialManager.gd | Tracks fired[] flags per tutorial ID in save file; exposes check_and_fire(id) called by UI; all 10 tutorial trigger points | GameManager, UnifiedPopup |
| ItemManager | scripts/managers/ItemManager.gd | Inventory CRUD (add/remove/use items); drop logic on project completion; stat/SP effect application | GameManager.employees, EconomyManager |
| PromotionManager | scripts/managers/PromotionManager.gd | Ceiling table lookup per role+tier; promotion availability check; deducts cost, bumps tier, updates salary | Employee.gd, EconomyManager |

### 4.2 New Scene/Script Pairs

| Scene | Script | Purpose | Dependencies |
|-------|--------|---------|--------------|
| scenes/CharacterCustomization.tscn | scripts/ui/CharacterCustomization.gd | First screen -- portrait selector, name input, NGO name input; validates before START | SaveSystem, GameManager |
| scenes/ui/UnifiedPopup.tscn | scripts/ui/UnifiedPopup.gd | Multi-page popup template; banner + body + page dots + close (last page only); used by tutorials, item drops, achievements, evaluations | BaseModal (extends) |
| scenes/ui/TutorialPopup.tscn | scripts/ui/TutorialPopup.gd | Extends UnifiedPopup; adds fire_condition check; once-only guard via TutorialManager | UnifiedPopup, TutorialManager |
| scenes/ui/EmployeePickerCard.tscn | scripts/ui/EmployeePickerCard.gd | Single card: 64x64 portrait, name, role+tier, SP pips (5), 2 stat bars, expected contribution line; states: eligible/selected/low-SP/mismatched | Employee.gd, StaminaWidget |
| scenes/ui/EmployeePickerModal.tscn | scripts/ui/EmployeePickerModal.gd | Phase picker: shows eligible employees as EmployeePickerCards; hides ineligible by role; greys low-SP; Start Work button; emits employee_selected(emp_id) | BaseModal (extends), EmployeePickerCard, PhaseManager |
| scenes/ui/PhaseAnimationOverlay.tscn | scripts/ui/PhaseAnimationOverlay.gd | Full-screen overlay (CanvasLayer layer=9); blurs+dims office; tableau sequence; 3 subrounds with contribution icon animation; parameter bar tick-up; Phase Complete reveal; 30s gap; tap-to-fast-forward | PhaseManager, ParameterTracker |
| scenes/ui/PhaseCompleteReveal.tscn | scripts/ui/PhaseCompleteReveal.gd | Drum roll + final number counter reveal; "PLANNING complete: 42" banner; cannot fully skip | PhaseManager |
| scenes/ui/ProjectListModal.tscn | scripts/ui/ProjectListModal.gd | Lists active projects with progress bars and remaining task count; tap project -> TaskListModal | BaseModal (extends), GameManager.projects |
| scenes/ui/TaskListModal.tscn | scripts/ui/TaskListModal.gd | Lists tasks for a project; each task card shows humor name, phases preview (PLANNING->EXECUTION->LOGISTICS), estimated time, BEGIN/RESUME button | BaseModal (extends), GameManager.projects |
| scenes/ui/StaminaWidget.tscn | scripts/ui/StaminaWidget.gd | Reusable SP pip row: N filled/empty circles (default 5, max 8); updates on StaminaManager signal | StaminaManager |
| scenes/ui/FinalEvaluationModal.tscn | scripts/ui/FinalEvaluationModal.gd | 2-page popup: page 1 = project total + tier reveal with drum roll; page 2 = donor reaction + 6-month recurring preview + item drop notification | UnifiedPopup (extends), RecurringManager, ItemManager |
| scenes/ui/InventoryModal.tscn | scripts/ui/InventoryModal.gd | 3-tab inventory (STAT EARNING / PROMOTION / USABLE); item rows with count; tap -> Use On picker | BaseModal (extends), ItemManager |
| scenes/ui/TierPromotionModal.tscn | scripts/ui/TierPromotionModal.gd | Shows ceiling checklist, promotion cost, after-promotion preview; [Promote] / [Not now] | UnifiedPopup (extends), PromotionManager |

### 4.3 New Data Files

| File | Purpose |
|------|---------|
| scripts/data/item_data.gd | Item definitions: id, humor_title, official_name, category, tier, effect_type, effect_value |
| scripts/data/promotion_ceiling_data.gd | Ceiling tables per role profile and tier (PM/Field/Supply/Admin/Budget x D/C/B/A/S) |

---

## 5. Branch Cleanup

### 5.1 refactor/work-round-ui-artworkpanel-lWfnK

**Status:** MERGED. Commit cb5c030 ("refactor: replace WorkRound overlay with in-place
ArtworkPanel animation") is on main. The branch still exists on remote as a stale
pointer to that same commit.

**Recommendation: DELETE.** The ArtworkPanel refactor it introduced (WorkRoundResult.gd)
is itself slated for deletion in v1.5.2 -- the Work Round mechanic is gone. Nothing in
this branch needs to be preserved.

Action: `git push origin --delete refactor/work-round-ui-artworkpanel-lWfnK`

### 5.2 claude/fix-work-result-delay-lWfnK

**Status:** MERGED. PR #122 merged commit 09ae595 ("fix: defer run_work_round() to
after thinking animation") to main. The branch still exists on remote.

**Recommendation: DELETE.** The fix targeted WorkRoundResult timing, which is being
deleted in v1.5.2 anyway.

Action: `git push origin --delete claude/fix-work-result-delay-lWfnK`

### 5.3 Other stale remote branches

`git ls-remote --heads origin` shows 65 remote branches (full list includes many
historic claude/ branches). These are outside the scope of this recon but represent
technical debt. Recommend Dos audit and bulk-delete merged branches after v1.5.2 ships.

---

## 6. Test Strategy

### 6.1 Existing Test Files

| File | Functions | What it tests | v1.5.2 fate |
|------|-----------|--------------|-------------|
| test_grade_calculator.gd | 19 | _grade_from_progress() thresholds in ProjectManager | DELETE -- grade system removed entirely |
| test_training_cp_cost.gd | 8 | get_total_cp_cost() in TrainingManager | PARTIAL REWRITE -- CP training survives but ceilings change; at least 3-4 tests will need new expected values; keep test_cost_zero_employees (still valid) |
| test_sanity.gd | 2 | 1+1=2, true=true | KEEP -- platform invariants |

### 6.2 New Test Files Required

| Proposed File | Tests to write | Priority |
|---------------|---------------|----------|
| tests/unit/test_phase_contribution.gd | Subround math (relevant_stat_sum x multipliers), variance bounds, role mismatch 70% penalty, specialty bonus (when spec'd) | CRITICAL |
| tests/unit/test_stamina.gd | SP deduction on phase select, SP recovery (+1/week), eligibility gate (<3 SP = not eligible), SP cap enforcement (max 8) | CRITICAL |
| tests/unit/test_parameter_accumulation.gd | task_total() = sum of phase results, project_total() = sum of task totals, reward tier lookup by total range | CRITICAL |
| tests/unit/test_recurring_payout.gd | Monthly payout per tier (1-5 reward table), 6-month window expiry, final evaluation trigger after month 6 | HIGH |
| tests/unit/test_item_drop.gd | Drop table: Tier 1 guarantees stat item tier 1, Tier 3+ guarantees promo token, Tier 5 guarantees stat tier 3 | HIGH |
| tests/unit/test_promotion_ceiling.gd | All ceiling stats must be at cap before promotion unlocks, cost deduction, tier bump, salary increase | HIGH |
| tests/unit/test_one_person_per_phase.gd | Employee used in phase 1 cannot be selected for phase 2 of same task | MEDIUM |
| tests/unit/test_weekly_cycle.gd | 5 phases completed = 1 week trigger, SP +1 per employee on week end, autosave fires | MEDIUM |
| tests/unit/test_save_format_v3.gd | Round-trip save/load preserves SP fields, tutorial flags, protagonist, parameter totals | MEDIUM |

### 6.3 Summary

- **Delete:** 19 tests (test_grade_calculator entirely)
- **Rewrite:** 8 tests (test_training_cp_cost -- new ceiling expectations)
- **Keep:** 2 tests (test_sanity)
- **Create:** ~50-70 new test functions across 8 new files

---

## 7. Save Format Migration

### 7.1 Current Save Format

GameManager.save_game() writes these keys:

```
{
  "company_data":        { company_name, reputation, current_tick, current_month,
                           current_year },
  "employees":           [ Employee.to_dict() array ],
  "economy":             { cash, cp, ... },
  "active_projects":     [ { "_v": 2, "unlocked_donors": [], "projects": [
                               { "id", "status", "idle_months", "completion_percent",
                                 "tasks": [ { "id", "status", "progress",
                                              "assigned_employee_ids" } ] }
                             ] } ],
  "office":              { ... },
  "is_fever_mode":       bool,
  "fever_cooldown_month": int,
  "total_rounds_played": int,
}
```

Employee.to_dict() keys (no SP, no ceiling fields):
```
id, first_name, last_name, personality, role, tier, charm, technical, procurement,
focus, communication, management, logistics, precision, morale, level,
experience_points, monthly_salary, is_hired, is_burned_out, is_assigned_to_project,
current_project_id, ot_level, stress, ot_months_consecutive, low_morale_months,
idle_months
```

### 7.2 What v1.5.2 Needs Different

| Key | v1.4 | v1.5.2 | Change |
|-----|------|--------|--------|
| tasks[].primary_stat | "charm" | REMOVED | Delete |
| tasks[].secondary_stat | "communication" | REMOVED | Delete |
| tasks[].progress | 0.0-1.0 float | REMOVED | Delete |
| tasks[].assigned_employee_ids | ["emp1"] | REMOVED | Delete |
| tasks[].phases | -- | Array of {parameter, role_required/preferred, phase_result} | Add |
| tasks[].used_employee_ids_this_task | -- | Array (1-person-per-phase enforcement) | Add |
| employees[].sp_current | -- | int (default 5) | Add |
| employees[].sp_max | -- | int (default 5) | Add |
| employees[].promotion_ceilings | -- | Dictionary per stat | Add |
| company_data.protagonist | -- | {portrait_id, name, ngo_name} | Add |
| tutorial_flags | -- | Dictionary {tutorial_id: bool} | Add (top-level key) |
| recurring_projects | -- | Array of active 6-month windows | Add (top-level key) |
| inventory | -- | {stat_items: [], promo_items: [], usables: []} | Add (top-level key) |
| active_projects[]._v | 2 | 3 | Bump |

### 7.3 Migration Recommendation

**WIPE saves on v1.5.2 launch.**

Rationale:
- Pre-launch player base is effectively zero (confirmed by v1.5.2 bible §Known Design
  Risks note 6: "small player base = acceptable")
- Task data structure is fundamentally incompatible -- every saved task has
  primary_stat/secondary_stat that would need to be mapped to phases[]; this mapping
  is not deterministic (one stat pair does not cleanly resolve to one phase type)
- Writing a migration is non-trivial and high-risk for zero real users

Implementation: In load_projects(), bump _v check from 2 to 3. Saves with _v != 3
get discarded and start fresh. Add one-time "New version -- save data reset" notice.

---

## 8. Recommended PR Order

Based on the v1.5.2 Development Priority Queue (§Development Priority Queue in GAME_BIBLE_v1.5.2.md).
Each PR = one scope. Dependencies listed; never start a PR before its deps are merged.

---

### PR-1: Cleanup and Dead Code Deletion
**Branch:** `chore/v152-cleanup`
**Files affected:**
- DELETE: scripts/ui/WorkRoundResult.gd
- DELETE: scripts/ui/TaskDetailView.gd
- DELETE: scripts/InternalProblemManager.gd
- DELETE: scenes/ui/InternalAlertPanel.tscn + scripts/ui/InternalAlertPanel.gd
- DELETE: tests/unit/test_grade_calculator.gd
- RENAME: EventManager.gd (root) -> EventPoolManager.gd; update GameManager.gd load() call
- UPDATE: ProjectManager.gd -- delete run_work_round(), _build_contribution_list(), _grade_from_progress(), all grade match blocks (~200 lines removed)
- UPDATE: tests/unit/test_training_cp_cost.gd -- rewrite expected values for ceiling-aware training (keep 3-4 tests, delete 4 that assume old behavior)
- MOVE: GAME_BIBLE_v1.2 + GAME_BIBLE_v1.3.md -> godot/archive/ (or delete)
**Complexity:** Medium (deletions + renames; no new behavior)
**Dependencies:** None
**Test plan:** Run GUT headlessly; test_sanity must pass; test_grade_calculator must be gone; remaining tests must pass

---

### PR-2: Employee Stamina Fields + StaminaManager
**Branch:** `feat/stamina-system`
**Files affected:**
- MODIFY: Employee.gd -- add sp_current: int, sp_max: int (default 5); extend to_dict/from_dict
- CREATE: scripts/managers/StaminaManager.gd -- SP deduction, recovery, eligibility check
- UPDATE: project.godot -- register StaminaManager as autoload after GameManager
- CREATE: tests/unit/test_stamina.gd
**Complexity:** Small
**Dependencies:** PR-1 merged
**Test plan:** test_stamina.gd all pass; test_sanity still passes

---

### PR-3: Task Data Structure Migration (Phase Schema)
**Branch:** `refactor/task-phase-schema`
**Files affected:**
- MODIFY: ProjectManager.gd -- replace task dict fields (primary_stat/secondary_stat/progress/assigned_employee_ids) with phases[], used_employee_ids_this_task[], phase_results[]; bump save _v to 3; add task_total() and project_total() helpers; rewrite to_save_array/load_projects for new schema
- MODIFY: GameManager.gd -- save format _v:3, load_game wipes _v:2 saves cleanly
**Complexity:** Large (ProjectManager is 1016 lines; careful surgery needed)
**Dependencies:** PR-2 merged
**Test plan:** New test_phase_data_schema.gd -- verify to_save/load round-trips; verify wipe logic fires on _v:2 load; no existing ProjectBoard functionality broken

---

### PR-4: ParameterTracker Autoload
**Branch:** `feat/parameter-tracker`
**Files affected:**
- CREATE: scripts/managers/ParameterTracker.gd
- UPDATE: project.godot -- register after StaminaManager
- CREATE: tests/unit/test_parameter_accumulation.gd
**Complexity:** Small
**Dependencies:** PR-3 merged
**Test plan:** test_parameter_accumulation.gd all pass

---

### PR-5: Character Customization Screen
**Branch:** `feat/character-customization-screen`
**Files affected:**
- CREATE: scenes/CharacterCustomization.tscn + scripts/ui/CharacterCustomization.gd
- MODIFY: GameManager.gd -- add protagonist dict to company_data; check on load whether customization was completed
- MODIFY: scenes/Main.tscn -- add CharacterCustomization as first scene if save has no protagonist
**Complexity:** Medium (new full-screen scene; input validation; portrait selector gallery)
**Dependencies:** PR-3 merged (needs updated save format)
**Test plan:** Launch game with no save -> CharacterCustomization loads; fill name+NGO name -> START enabled; blank name -> START disabled; confirm protagonist saved to company_data after START

---

### PR-6: UnifiedPopup Template
**Branch:** `feat/unified-popup`
**Files affected:**
- CREATE: scenes/ui/UnifiedPopup.tscn + scripts/ui/UnifiedPopup.gd (extends BaseModal)
- MODIFY: scenes/TutorialOverlay.tscn + scripts/ui/TutorialOverlay.gd -- rewrite to use UnifiedPopup; keep .tscn but hollow out old logic
**Complexity:** Medium (multi-page template; banner/body/close-on-last-page behavior; tap-anywhere-skip)
**Dependencies:** PR-1 merged
**Test plan:** Instantiate popup with 1 page; close visible immediately. Instantiate with 3 pages; close hidden on page 1+2, visible on page 3; tap body skips to page 3; tap outside blocked until all viewed.

---

### PR-7: StaminaWidget + EmployeePickerCard
**Branch:** `feat/employee-picker-card`
**Files affected:**
- CREATE: scenes/ui/StaminaWidget.tscn + scripts/ui/StaminaWidget.gd
- CREATE: scenes/ui/EmployeePickerCard.tscn + scripts/ui/EmployeePickerCard.gd
**Complexity:** Small-Medium
**Dependencies:** PR-2 (StaminaManager), PR-6 (UnifiedPopup style tokens)
**Test plan:** Instantiate card with Employee at 5/5 SP: all pips filled; with 2/5 SP: 3 empty pips, card greyed; mismatched role: yellow border; PLANNING phase with non-PM: hidden

---

### PR-8: EmployeePickerModal
**Branch:** `feat/employee-picker-modal`
**Files affected:**
- CREATE: scenes/ui/EmployeePickerModal.tscn + scripts/ui/EmployeePickerModal.gd
- UPDATE: project.godot -- note EmployeePickerModal is NOT an autoload; instantiated by PhaseManager
**Complexity:** Medium
**Dependencies:** PR-7 merged
**Test plan:** Open modal for PLANNING phase: only PMs visible (Field Officers hidden); select employee; Start Work button enables; emit employee_selected signal

---

### PR-9: ProjectListModal + TaskListModal
**Branch:** `feat/project-task-picker-ui`
**Files affected:**
- CREATE: scenes/ui/ProjectListModal.tscn + scripts/ui/ProjectListModal.gd
- CREATE: scenes/ui/TaskListModal.tscn + scripts/ui/TaskListModal.gd
- MODIFY: scenes/ProjectBoard.tscn + scripts/ui/ProjectBoard.gd -- "Projects" button opens ProjectListModal instead of inline board
**Complexity:** Medium
**Dependencies:** PR-3 (phase schema in task data), PR-6 (BaseModal extension)
**Test plan:** Open ProjectListModal; see active projects with progress bars; tap project; TaskListModal opens; see task cards with phase preview (e.g. "PLANNING -> EXECUTION -> LOGISTICS"); BEGIN button visible on first uncompleted task

---

### PR-10: PhaseManager Autoload (Math Only)
**Branch:** `feat/phase-manager-math`
**Files affected:**
- CREATE: scripts/managers/PhaseManager.gd -- contribution formula (relevant_stat_sum x subround_multiplier +/- 15% variance), SP deduction, 1-person-per-phase enforcement, phase_completed signal
- UPDATE: project.godot -- register PhaseManager autoload
- CREATE: tests/unit/test_phase_contribution.gd
**Complexity:** Medium (contribution math + constraints; no animation yet)
**Dependencies:** PR-4 (ParameterTracker), PR-2 (StaminaManager), PR-3 (phase schema)
**Test plan:** test_phase_contribution.gd: correct base numbers for Tier D/C/A PMs; variance stays within +/-15%; role mismatch gives 0.70x; same employee in 2 phases of same task rejected

---

### PR-11: PhaseAnimationOverlay
**Branch:** `feat/phase-animation-overlay`
**Files affected:**
- CREATE: scenes/ui/PhaseAnimationOverlay.tscn + scripts/ui/PhaseAnimationOverlay.gd (CanvasLayer layer=9)
- CREATE: scenes/ui/PhaseCompleteReveal.tscn + scripts/ui/PhaseCompleteReveal.gd
- MODIFY: scenes/OfficeView.tscn -- ensure blur layer can be applied from overlay
**Complexity:** Large (tableau timing, subround animations, contribution icon float, parameter bar tick-up, gap behavior, tap-to-fast-forward)
**Dependencies:** PR-10 (PhaseManager), PR-8 (EmployeePickerModal)
**Test plan:** Can only test visually (Godot F5). Checklist: overlay drops over office; office visible but blurred 60%; selected employee highlighted; icon floats to parameter bar; bar ticks up; gap shows office unblurred; Phase Complete banner appears; cannot fully skip Phase Complete reveal

---

### PR-12: End-to-End Prototype (5-minute slice)
**Branch:** `feat/e2e-prototype-slice`
**Files affected:**
- MODIFY: scenes/Main.tscn -- wire full flow: CharacterCustomization -> Tutorial #1 -> Office -> Projects button -> ProjectListModal -> TaskListModal -> EmployeePickerModal -> PhaseAnimationOverlay -> Task Complete reveal
- Wire up TutorialManager stubs for tutorials 1 and 4 (welcome + picker explanation)
- Add placeholder Task Complete reveal (can be simple popup)
**Complexity:** Medium (wiring; no new systems)
**Dependencies:** PR-5 (customization), PR-9 (project/task pickers), PR-11 (phase animation)
**Test plan:** Full manual playthrough: start game -> customize -> see office -> tap Projects -> pick project -> pick task -> pick PM -> watch 3 phases -> see task complete. This is the "does the loop feel fun?" gating test from GAME_BIBLE_v1.5.2 §Test the Fun First. Do not proceed to PR-13+ until this passes.

---

### PR-13: RecurringManager + FinalEvaluationModal
**Branch:** `feat/recurring-revenue`
**Files affected:**
- CREATE: scripts/managers/RecurringManager.gd
- UPDATE: project.godot -- register RecurringManager last in autoload order
- CREATE/MODIFY: scenes/ui/FinalEvaluationModal.tscn -- repurpose EvaluationScreen
- MODIFY: scripts/ui/EvaluationScreen.gd -- rename and rewrite for Final Eval
- CREATE: tests/unit/test_recurring_payout.gd
**Complexity:** Medium
**Dependencies:** PR-12 merged and fun (gating condition)
**Test plan:** Register project at Tier 3 (project_total 600); verify $1,500/month paid for 6 months; month 7 triggers Final Evaluation; FinalEvaluationModal fires and shows Tier 3 reveal

---

### PR-14: TutorialManager + All 10 Tutorials
**Branch:** `feat/tutorial-system`
**Files affected:**
- CREATE: scripts/managers/TutorialManager.gd
- UPDATE: project.godot -- register after GameManager
- CREATE: scenes/ui/TutorialPopup.tscn + scripts/ui/TutorialPopup.gd (extends UnifiedPopup)
- MODIFY: GameManager.gd -- add tutorial_flags to save/load
- Wire 10 trigger points across their respective scenes
**Complexity:** Large (10 trigger points across many scenes; once-only logic; content)
**Dependencies:** PR-6 (UnifiedPopup), PR-12 (end-to-end wired)
**Test plan:** Each of 10 tutorials fires exactly once; re-firing check_and_fire after fired=true does nothing; tutorial_flags persisted across save/load; new game resets all flags

---

### PR-15: Item System + InventoryModal
**Branch:** `feat/item-system`
**Files affected:**
- CREATE: scripts/managers/ItemManager.gd
- CREATE: scripts/data/item_data.gd
- UPDATE: project.godot -- register ItemManager after FacilityManager
- CREATE: scenes/ui/InventoryModal.tscn + scripts/ui/InventoryModal.gd
- MODIFY: GameManager.gd -- add inventory to save/load
- MODIFY: RecurringManager.gd -- call ItemManager.try_drop_item() on final evaluation
- CREATE: tests/unit/test_item_drop.gd
**Complexity:** Medium
**Dependencies:** PR-13 (FinalEvaluationModal fires on project end)
**Test plan:** Complete project at Tier 1: stat item Tier 1 in inventory. Complete at Tier 3: promo token also drops. Use "A Bad Book" on employee: stat +5 applied; item removed from inventory.

---

### PR-16: Tier Promotion System
**Branch:** `feat/tier-promotion`
**Files affected:**
- CREATE: scripts/managers/PromotionManager.gd
- CREATE: scripts/data/promotion_ceiling_data.gd
- UPDATE: project.godot -- register PromotionManager after ItemManager
- CREATE: scenes/ui/TierPromotionModal.tscn + scripts/ui/TierPromotionModal.gd
- MODIFY: TrainingScreen -- show ceiling progress per stat
- CREATE: tests/unit/test_promotion_ceiling.gd
**Complexity:** Medium (ceiling tables are large but mechanical)
**Dependencies:** PR-15 (promo tokens exist), PR-2 (Employee has SP/ceiling fields)
**Test plan:** Train PM all stats to Tier D ceiling; PromotionManager.is_ready_to_promote() returns true; open TierPromotionModal; confirm shows all ceiling checkmarks; press Promote with $2,500 + token: tier becomes C, salary +$200/mo, ceilings update to Tier C values

---

### PR-17: Weekly Cycle Update
**Branch:** `feat/weekly-cycle-phases`
**Files affected:**
- MODIFY: scripts/EventManager.gd -- change trigger from "5 work rounds" to "5 phases completed" (listen to PhaseManager.phase_completed signal)
- MODIFY: GameManager.gd -- replace total_rounds_played with total_phases_completed
**Complexity:** Small
**Dependencies:** PR-10 (PhaseManager emits phase_completed)
**Test plan:** Complete 5 phases across any tasks; weekly cycle animation triggers; SP +1 per employee; autosave runs during dark phase

---

### PR-18: CHAMP Bulletin Event Hook Update
**Branch:** `feat/champ-bulletin-phase-hooks`
**Files affected:**
- MODIFY: scripts/CHAMPBulletinManager.gd -- update effect targets: "PLANNING phase totals -20%" replaces old "progress rate -20%"; "phases halt" replaces "projects paused"
- MODIFY: scripts/managers/PhaseManager.gd -- read active bulletin modifiers before contribution calc
**Complexity:** Small
**Dependencies:** PR-10 (PhaseManager contribution formula)
**Test plan:** Trigger a "-20% PLANNING" bulletin; verify next PLANNING phase contribution is 0.80x of normal

---

### PR-19: Test Suite Completion
**Branch:** `test/v152-test-suite`
**Files affected:**
- CREATE: tests/unit/test_weekly_cycle.gd
- CREATE: tests/unit/test_one_person_per_phase.gd
- CREATE: tests/unit/test_save_format_v3.gd
- Any remaining test files from §6.2 not yet written in earlier PRs
**Complexity:** Medium
**Dependencies:** All feature PRs merged
**Test plan:** Full headless GUT run; all tests pass; CI green

---

## 9. Risks and Blockers

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | PhaseAnimationOverlay complexity -- tableau timing + blur + icons is the largest single new component | HIGH | Build PR-12 prototype before full polish; evaluate fun before adding juice |
| 2 | Zero art assets -- Character Customization, picker cards, and phase overlay all need portraits and icons that don't exist | HIGH | Build all UI with placeholder color blocks; do not block progress on art |
| 3 | ProjectManager.gd is 1016 lines and intertwines task data, work round logic, and project management -- surgical deletion risk | HIGH | PR-1 deletes grade calc first; PR-3 replaces task schema; keep ProjectManager tests green at each step |
| 4 | Two EventManagers with similar names will cause confusion if not renamed before PR-3 | MEDIUM | PR-1 renames root EventManager.gd to EventPoolManager.gd |
| 5 | 65 stale remote branches create merge-confusion noise | LOW | Dos to audit and bulk-delete after v1.5.2 ships |
| 6 | InternalProblemManager.gd is 231 lines -- verify no callers before deletion | MEDIUM | grep all .gd and .tscn files for "InternalProblemManager" before PR-1 |
| 7 | PM safety valve (Open Question #1 in GAME_BIBLE_v1.5.2) is unresolved -- if all PMs are at 0 SP, PLANNING phases are blocked | MEDIUM | In early PRs, implement Option B (hard block with tooltip). Log as design debt. |
| 8 | 30-second gap pacing may not be fun | MEDIUM | Prototype gating in PR-12: if gap feels wrong, reduce to 15s before any later polish |
| 9 | ECONOMY_BIBLE numbers are v1.4 (project-based one-time rewards) and are largely superseded by v1.5.2 recurring revenue table -- two reward systems now exist | MEDIUM | Clarify with Dos whether v1.4 task cash rewards ($400-$1,200 per task) are REMOVED entirely or supplemented by recurring |

---

## 10. Open Questions for Dos

1. **Two reward streams coexist?** v1.4 tasks paid cash+CP on completion ($400-$1,200
   per task). v1.5.2 introduces recurring revenue INSTEAD of this. Confirm: are per-task
   cash rewards completely removed, or do they exist alongside recurring? If removed,
   ECONOMY_BIBLE needs a v1.5 companion update.

2. **ECONOMY_BIBLE update needed?** The recurring revenue tier table (Tier 1: $3,300
   over 6 months; Tier 5: $70,000) is in GAME_BIBLE_v1.5.2 but ECONOMY_BIBLE still
   reflects v1.4 one-time project rewards ($1,200-$3,500). These will be used for
   balance reference -- should ECONOMY_BIBLE be updated before implementation PRs start?

3. **Grade helpers (PR #118):** The prompt references "grade calculation helpers
   extracted in PR #118." No separate grade_helpers file was found in the current
   codebase. The _grade_from_progress() function is at ProjectManager.gd line 786.
   Confirm: were grade helpers ever extracted to a separate file, or does PR-1 just
   delete the function from ProjectManager?

4. **Region Area task data:** ProjectManager.gd only has Local Area (3 projects,
   16 tasks) hardcoded. Region Area (7 projects, 38 tasks) and above are designed in
   GAME_BIBLE_v1.4 and HUMOR_NAMING_BIBLE but not implemented. Should Region data be
   converted to v1.5.2 phase format as part of PR-3, or deferred until after the
   Local Area prototype is validated?

5. **1-person-per-phase enforcement:** The rule is clear within a task. Clarify one
   edge case: if Task A (PLANNING phase) and Task B (PLANNING phase) are running
   concurrently, can the same PM do both? v1.5.2 bible says yes (cross-task allowed;
   stamina is the throttle). Confirm this is correct -- PhaseManager must allow
   cross-task but block within-task.

6. **CharacterCustomization first launch check:** If player deletes their save mid-game,
   should Character Customization re-appear on next launch? Or only for a truly fresh
   install? Recommend: yes (wipe = fresh start = customization appears), but confirm.

7. **InternalProblemManager scope:** This 231-line autoload handles internal HR
   problems (burnout chains, morale events). Is it in scope for v1.5.2 or is the entire
   internal problems system deferred? If deferred, confirm it is safe to delete in PR-1.

8. **TaskDetailView.gd:** This 343-line script is instantiated by ProjectBoard but has
   no .tscn. It contains assign-employee logic that is being replaced by
   EmployeePickerModal. Confirm it is safe to delete in PR-1 with no other callers.

9. **ART_BIBLE section gap:** The ART_BIBLE.md file starts at section 7 (Art Production
   Workplan). Sections 1-6 appear missing or not yet written. The UI_SYSTEMS_BIBLE
   references final palette values from ART_BIBLE -- specifically the PICO-8 color
   mapping for UI colors. Is there a full ART_BIBLE document elsewhere, or should the
   color mapping section be added before UI implementation begins?

10. **SP recovery items in CHAMP shop:** v1.5.2 bible maps "5 Energy = 1 SP" for
    existing shop items (Chocolate = +1 SP, Premium Coffee = +2 SP all employees). Are
    these mappings locked, or should CHAMP shop items be re-priced/re-specced for v1.5.2
    before implementing ItemManager? ECONOMY_BIBLE and GAME_BIBLE_v1.4 shop tables still
    show Energy values, not SP.

---

*Pocket Office -- v1.4 to v1.5.2 Migration Plan*
*Recon complete: 2026-05-01*
*Next action: Dos reviews this plan, answers Open Questions, then implementation begins at PR-1.*
