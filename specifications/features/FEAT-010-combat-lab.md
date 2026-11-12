# FEAT-010 — Isolated Combat Lab

**Status:** First implementation committed; automated tests PASS on branch, manual/visual acceptance pending.
**Owner:** Project owner · **Branch:** feature/standalone-combat-lab

## Purpose
Allow deterministic combats to be tested independently of adventure/campaign orchestration.

## Human instructions
Approve playable UI, art, accessibility, the level-test limitations, debug presentation and any eventual merge.

## AI agent instructions
Keep the battle engine authoritative and preserve original level-one fixtures. Use test data and a separate log path; no campaign state writes.

## Implemented scope
- Title screen; four-party roster display and test-level selector 1–5, plus optional Hunter fourth-slot fixture.
- Config dialog: known archetype, count 1–8, four sample arenas, deterministic seed.
- Start Combat -> deployment -> normal existing rules/AI; replay or return to title.
- Debug shows CombatSetup and latest CombatResult; last battle report written to `user://combat_lab_last_battle.json`, available on the title after restart.
- Explicit zero XP/gold/loot in all sandbox outputs.
- Uses currently implemented spells for matching classes; level-two+ gameplay features not implemented.

## Acceptance
- **FEAT-010-AC01:** Starts on title, not a narrative scene — automated headless test.
- **FEAT-010-AC02:** Chosen level/class/enemy/count/arena/seed flows to validated CombatSetup.
- **FEAT-010-AC03:** Deployment and battle use authoritative CombatEngine and existing rules.
- **FEAT-010-AC04:** Result records outcome, combatants, action log; rewards are zero and no campaign save is modified.
- **FEAT-010-AC05:** Last battle log survives application restart.
- **FEAT-010-AC06:** Existing headless combat rules and new UI/setup tests PASS.
- **FEAT-010-AC07:** Desktop UI/controls and actual visual presentation reviewed manually — **NOT RUN**.
- **FEAT-010-AC08:** Real touch/gamepad support or approved exceptions — **NOT RUN**.

## Known prototype limitations
Hunter's temporary test profile borrows Pip's slot/art, level 2–5 currently adjusts HP and first-level spell capacity only, homogeneous enemy selection, no extra morale/objective outcomes yet. No additional animations until FEAT-011.

## Evidence
Godot 4.5.2 and governance workflows on the dedicated branch; see `development/VALIDATION_MATRIX.md`. No merge approval recorded.
<!-- [EXAMPLE ONLY] Interactive screenshots and actual device checks must not be inferred from headless import. -->
