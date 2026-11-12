# Combat Lab roadmap — 2026-11-12

This branch is intentionally **not** the Azure Mines narrative game.

| Stage | Deliverable | Current status |
| --- | --- | --- |
| LAB-0 | New isolated branch; eliminate narrative runtime, assets and story-specific tests | Implemented |
| LAB-1 | Title screen, party levels 1–5, optional Hunter slot, configure enemy/archetype/count/arena/seed | Prototype implemented |
| LAB-2 | Deploy/fight/replay, debug input and last battle result/log persisted to user:// | Prototype implemented; automated CI passing |
| LAB-3 | FEAT-009 hardened setup/result/events with reusable entity/state contracts | Structured event v1 implemented; further result/identity hardening planned |
| LAB-4 | FEAT-011 improve graphics and introduce slashes, hit/miss, spells, healing/reactions VFX | v0.3 procedural effects implemented; sprite/effects polish planned |
| LAB-5 | FEAT-012 level-two class features/resources and several distinct monster archetypes | Planned |

**Not implemented:** Complete character progression for levels 2–5, full spell catalogue, advanced enemy traits, morale/surrender, advanced conditions, polished new animations, physical controller/touch, canonical Hunter sprite. These must not be claimed from the UI's test-level selector.

**Future narrative branch:** The retained narrative code remains in the original game-development branches; integration later uses a reviewed CombatSetup/CombatResult contract and independent NPC registry.

## Latest — Combat Lab v0.3

- Release target: `feature/combat-lab-web-touch` deployed via verified Godot 4.5.2 Web export to [GitHub Pages](https://jonty303.github.io/Project-AzureMines/).
- Feature development: `feature/combat-lab-v03-tactical-feedback`. Event contract and initial procedural VFX are complete in code and headless tests; real iPad action/feedback inspection remains pending.
- Next: iPad tap/animation playtest, more precise sprite animation/VFX timing, broaden combat result schemas and eventually mixed enemies/AI morale.

## Agreed next presentation build — iPad-first v0.4

- **OWNER-AGREED PROVISIONAL art direction:** [Combat Lab iPad v0.2](combat-lab-ipad-art-direction-v02.md), following the generated mockup from the 12 November 2026 conversation.
- **Next implementation specification:** [FEAT-015](../specifications/features/FEAT-015-ipad-camera-projectiles-and-card-actions.md).
- Slice A: widen one encounter to 16–17 columns; implement reliable drag-pan/pinch tactical zoom and coordinate invariants.
- Slice B: icon+text bottom action buttons, End Turn emphasis on the far right, direct weapon cards and **swipeable horizontal spell cards** with visible next-page affordance.
- Slice C: projectile-based arrows and offensive spell VFX sourced from structured resolved events.
- Slice D: real iPad Safari verification and Web build iteration.
- **Status:** direction recorded and scope planned, **not implemented** by these design documents. The published Web Combat Lab remains on `feature/combat-lab-web-touch`.

## Combat Lab v0.4 implementation (2026-11-12)

- Added a 17-column wide forest arena and camera panning/pinch zoom with inverse-mapped hit-testing.
- Added four original SVG monster sprites and authored stat blocks: skeleton, giant spider, kobold and bandit; mixed groups of 1–8 now available.
- Replaced player-facing weapon/spell dropdowns with direct weapon buttons and swipeable spell cards; icon-based player actions and a prominent right-aligned End Turn remain in the bottom bar.
- Added ranged arrow/bolt and elemental spell projectile travel from resolved `source_cell`/`target_cell` snapshots, independent of deterministic combat outcomes.
- Read [v0.4 release/acceptance](combat-lab-v04-release.md). Real iPad visual and swipe/gesture acceptance remains pending.

## Combat Lab v0.4.1 — Downed turns and animation staging

- Unconscious heroes no longer require an End Turn press; automatic death saves occur within initiative and do not expose player commands. Natural 20 recovery still allows immediate action.
- Stable/dead/incapacitated combatants are skipped, while downed allies remain available to healing.
- Ordinary monster AI deliberately targets only combat-capable opponents. Finishing moves are deferred to explicit AI-profile work.
- Resolved movement animates per tile (~115ms) and projectile launching follows queued attacker movement.
- A fatal ranged projectile keeps the target's battlefield sprite upright until impact, then plays collapse and death sound, while the engine state remains authoritative throughout.
- Formal acceptance/tests: [FEAT-016](../specifications/features/FEAT-016-downed-turns-impact-and-movement.md). Physical iPad animation review remains outstanding.

## Proposed engine foundation — multi-tile creature footprints (FEAT-017)

The owner requested real tactical sizes for giants, dragons and other oversized creatures. Design intent: Small/Medium 1×1; Large 2×2; Huge 3×3; Gargantuan 4×4 or more, while allowing individual creatures of a family to differ in size. First add backward-compatible footprint definitions, occupied-cell geometry and validation; next implement collision/pathfinding, reach/AoO, line of sight, area effects, AI and camera-aligned sprites; finally prove 2×2 and 3×3 test creatures before a 4×4 boss. Flying/altitude, breath templates and advanced monster features are separate milestones.

**Status:** Proposed/documented, **NOT IMPLEMENTED**. See [FEAT-017](../specifications/features/FEAT-017-multi-tile-creatures.md) and ADR-AM-010. Preserve the current 1×1 Combat Lab behaviour until tests and owner review are complete.
