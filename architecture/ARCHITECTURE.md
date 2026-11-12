# Combat Lab architecture

**Status:** Existing prototype and explicit extension boundaries · **Reviewed:** 2026-11-12

## Purpose
Keep the test harness independent of campaign/narrative code while preparing reusable combat setup/result interfaces for later integration.

## Human instructions
Review any changes to simulation state ownership, session lifecycle, effect processing and external dependencies before approval.

## AI agent instructions
Do not introduce a new ECS/game engine or copy combat calculations into UI. Preserve Godot 4.5.2 and validate outputs.

## Main architectural choice
Use Godot-native composition with headless-testable GDScript simulation. Alternatives (new ECS, scene-owned damage calculation, narrative-first battle setup) have no demonstrated benefit at this prototype scale.

## Runtime boundaries
```
Combat Lab title & encounter dialog
    → CombatSetup builder (schema 1, party, encounter, seed)
    → CombatEngine.start_from_setup() (authoritative state/turns/actions)
    → CombatBoard (visualisation) + Lab UI (player intents/audio)
    → Completed CombatResult (initial setup + final actor snapshots + events)
    → user://combat_lab_last_battle.json (debug only, never campaign state)
```

## Current state
- `combat_lab/setup_builder.gd`: copies the immutable base party, applies deterministic test-level changes and implementation-limited spell lists; composes selectable fixture archetypes and arenas.
- `combat/combat_engine.gd`: authoritative encounter session, movement, attacks, spell resolution, conditions, AI, turn scheduling and outcome.
- `combat/combat_board.gd`: grid visualisation, targeting highlighting, image resources; has no damage/HP authority.
- `scenes/combat_lab.gd`: menu, dialog, active battle UI, audio presentation, input adapter, output persistence.
- `combat/level1_spells.gd`: defined subset of executable spell behaviour; level-two features are not implemented.

## Planned seams before expansion
- Promote `CombatSetup`/`CombatResult` to explicit versioned validation and event contracts, with generic entity IDs.
- Structure combat events as action/movement/hit/heal/death facts to support animations without parsing prose.
- Separate class/spell effect resolvers and AI policy before implementing many new abilities/monsters.
- Preserve an eventual adapter for a separate NPC register, but do not implement an NPC registry or narrative integration here.

## Invariants
No campaign mutations, gold/XP/loot, story loads or named NPC fate decisions in the combat lab. UI cannot directly change engine outcomes except by submitting test commands. Fixed seed should produce reproducible action results. Manual visual/physical input tests are separate from headless tests.

## Risks
Temporary Hunter fixture reuses the 'pip' slot and sprite; no complete higher-level features. Enemy type is homogeneous per encounter and current outcome is victory/defeat, not surrender or escape.
<!-- [EXAMPLE ONLY — NOT APPROVED] Do not import cross-project secrets or campaign fixtures. -->
