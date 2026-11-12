# Next development cycle — Combat Lab, visual polish and level-two expansion

**Recorded:** 2026-11-12
**Current isolated branch:** feature/standalone-combat-lab
**State:** FEAT-010 prototype implemented on the isolated branch; later graphics and progression features remain planned.
**Baseline:** feature/combat-lab-polish-level2, which inherits the template and earlier combat development.

## Purpose
Make the already playable tactical encounter flow independently repeatable and visually appealing before expanding its rules. Preserve the narrative campaign and avoid copying the combat engine.

## Ordered delivery
1. **FEAT-010 — Combat Lab launcher (prototype implemented)**: a separate development/test entry point for loading a selectable encounter fixture, deployment/turns, defeat/victory and restart. Reuse CombatEngine and CombatBoard. No campaign persistence or rewards.
2. **FEAT-011 — Combat visual polish (planned)**: improve 64px sprite readability, board/action feedback, layering and restrained event-driven melee/spell effects. Add an optional reduced-effects setting or equivalent accessibility accommodation. Do not gate resolution on animation.
3. **FEAT-012 — Level-two and enemy variety (planned)**: after the sandbox is stable and the VFX pass is reviewed, add a separate level-two fixture, approved class features/spell resources and a small number of tactically distinct enemies with tests.

## Design constraints
- Preserve `scenes/combat.tscn` and the opening adventure as production startup until reviewed; a combat test launcher must be optional.
- Keep the existing immutable level-one party fixture unchanged. Provide versioned alternative(s) for level two.
- Neither VFX nor UI changes may change damage, accuracy, initiative, resources, saved campaign state, XP or reward flags.
- Never expose campaign spoiler-only content through fixture menus.
- Maintain deterministic seeds for headless comparisons.
- New attack types, conditions and spell effects require rules specifications and tests; do not add mechanics to make animations appear more dramatic.
- Character level 2 is not spell level 2. In the adapted 5E class progression, new second-level spells are not the level-two character milestone.

## Milestone exit checks
**A — Lab:** run a fixture with four heroes, complete a battle, reset and run again; no story dependencies, duplicate event consumers or permanent rewards. Automated tests plus desktop input review.
**B — Feedback:** original-looking combat sprites/tiles remain readable at intended viewport; event-driven slashes, missiles, elemental/healing visuals demonstrate hit, miss and cast with no change to resolved mechanics; manual screenshots/video and audio review.
**C — Progression:** new level-two fixture and explicitly approved class feature behavior, slot/resource progression, two or three new enemy archetypes with different behaviours, rule tests, encounter balance playtests.

## Scope excluded from this cycle
Changing world canon, goblin-cave story branches, authoring editor integration, multiplayer, mobile export commitment, rewriting CombatEngine, real-time combat, full spell catalogue, fourth/fifth character levels, and merging pending PRs without owner permission.

## Verification and branch strategy
Treat each FEAT as a small reviewable PR/commit series on this branch or children of it. The governance base has historical passing CI but each new commit needs its own current CI check. Physical rendering/input and game balance need manual evidence; headless CI is not a substitute.
