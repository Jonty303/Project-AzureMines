# SPEC-003 — Game state, authored definitions and persistence

**Status:** Existing behavior documented; schema changes require review

## Purpose
Keep authored definitions, transient combat state and persistent campaign records separate.

## Human instructions
Approve data-model changes, schema/version policy, reward/progression math and save compatibility.

## AI agent instructions
Validate input IDs and schema versions; avoid running authored scripts. Never introduce breaking saves without a migration plan.

## Current contracts
- Authored adventure content: adventures/test_adventure/ JSON manifests, encounter fixtures and location choices.
- Ruleset definitions: rulesets/classic_5e/. A definition identifies a class, ancestry, spell or creature archetype.
- Battle instances: CombatEngine holds actor IDs, current HP, turn state, actions, reactions, effects, initiative, positions and events.
- Campaign instances: CampaignState tracks persistent HP/resources, flags, NPC choices, clues, journal, party XP/gold and once-only rewards.
- Saves: versioned user://azure_mines_slot1.json after victory or during exploration, NOT during active battle/deployment.
- Overland/dungeon editor JSON exports are authoring contracts, not directly loadable runtime adventures.

## Next-cycle constraints
A combat sandbox must not write the campaign save, award permanent XP or expose spoiler-only authored encounters. A new monster definition must have stable IDs and validated attacks. Level-two character advancement should be tested independently of spell presentation and visual effects.

## Acceptance
Round-trip persistence tests must preserve established state and reject invalid/unsupported records. Repeat battle runs must not duplicate rewards or alter narrative flags.
<!-- [EXAMPLE ONLY] EnemyInstance and EnemyDefinition separation illustrates concepts, not a new mandatory format. -->

## Proposed combatant space and sprite separation

Future typed `CombatantDefinition` records should contain a size category and a validated grid footprint. `CombatantInstance.position` should remain a stable grid anchor; occupied cells are derived from the footprint. Sprite size, visual hit region and ground-contact anchor are **presentation metadata**, never the source of collision or reach. Existing definitions without footprint metadata must continue to occupy 1×1; any schema version change needs migration and deterministic serialization tests. See [FEAT-017](../features/FEAT-017-multi-tile-creatures.md). **Not yet implemented.**
