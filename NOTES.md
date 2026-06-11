

## PR-0 Prototype Playtest Findings (2026-06-11)

Gate decision: PASS. Proceed with v1.5.2 migration per MIGRATION_PLAN.md.

Validated (lock these values):
- Subround multipliers 0.10/0.30/0.60, 2s each — feels right
- 5s subround gap, 30s inter-phase gap — confirmed good
- Tap = 3x speed, Hold = skip — responsive

Bugs found in prototype (do NOT fix — enforce in real implementation):
- Prototype showed "S Tier" for a fresh Tier D team (~138 points).
  Correct behavior: project total vs thresholds 200/500/1200/2500.
  Fresh Tier D team MUST land Tier 1 (breakeven).
- Reward tiers are Tier 1-5 labels. Letter grades (S/A/B/C) are
  deleted in v1.5.2 and must never appear in UI or code.
- Required GUT test for the reward-tier PR:
  fresh Tier D team total ~138 -> Tier 1, never higher.
- Prototype shipped with `var phase := PHASES[_phase_idx]` which
  violates the CLAUDE.md rule "no := with untyped values" and broke
  at runtime. Every future implementation prompt must restate this
  rule explicitly.

New design note (post-task result screen):
- Result screen should highlight the weakest parameter and suggest
  which employee stat to train, e.g. "PLANNING lowest — George's
  Management needs training." Turns a low tier into a training plan.

Commit message: "docs: record PR-0 playtest findings and tier mapping bug"
Push branch. Do not modify any other file.
## Migration Plan Open Questions — Answers (2026-06-11)

1. Per-task cash rewards: REMOVED entirely. Recurring revenue replaces them.
2. ECONOMY_BIBLE v2: parallel docs PR. Does not block PR-1.
3. Grade helpers: never extracted to a file. Delete _grade_from_progress()
   inside ProjectManager directly (PR-1b).
4. Region Area data: DEFERRED until Local Area is validated in v1.5.2.
5. Same employee on phases of two different tasks: ALLOWED. Block
   within-task only. SP is the throttle.
6. Save wipe -> Character Customization reappears: YES.
7. InternalProblemManager: DELETE. Not in v1.5.2 MVP.
8. TaskDetailView.gd: DELETE in PR-1b (caller is ProjectBoard).
9. ART_BIBLE: PICO-8 palette DROPPED. New warm pastel palette from the
   Claude Design mockup + LimeZu assets. ART_BIBLE rewrite required
   before PR-6 (first UI PR).
10. SP item mappings: re-spec together with ECONOMY_BIBLE v2, before PR-15.

PR-1 is split: PR-1a = reference-free deletions + rename.
PR-1b = ProjectManager/ProjectBoard surgery + dependent deletions
(WorkRoundResult.gd, TaskDetailView.gd).
