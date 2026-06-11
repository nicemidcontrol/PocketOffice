Read godot/CLAUDE.md first.

Create FRESH branch from main: docs/pr0-playtest-findings

Edit ONE file only: godot/NOTES.md
Append a new section at the end:

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
