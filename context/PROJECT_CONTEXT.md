# Azure Mines Combat Lab — project context

**Status:** Owner-approved combat-only development direction · **Reviewed:** 2026-11-12

## Purpose
Define the active scope for the standalone combat test harness, distinct from narrative and campaign work.

## Human instructions
Approve mechanical progression, class abilities, combat architecture, platform/input support and visual acceptance. Narrative features are outside this branch.

## AI agent instructions
Preserve independent combat simulation and use test fixtures rather than campaign state. Do not invent unavailable level features or any narrative content.

## Vision and scope
- **Pitch:** A standalone, repeatable tactical battle lab for the Azure Mines party-based RPG.
- **Technology:** Godot 4.5.2 standard GDScript; retain deterministic CombatEngine and CombatBoard.
- **Design pillars:** A quick test loop, explicit setup, reliable events/results, meaningful positioning, original readable presentation.
- **Current baseline:** Four character slots (Alden, Elyra, Brunna, Pip; optional Hunter test in fourth slot); levels 1–5 selectable for test scaffolding; first-level implemented abilities and spells.
- **Battle inputs:** Party level/variant, fixed fixtures, enemy type/count, battlefield, deterministic seed.
- **Battle outputs:** Full initial setup, combatant final HP/conditions, victory/defeat, events, rounds and explicit zero sandbox rewards.
- **Testing:** Rules/engine CI + Combat Lab UI smoke; graphical desktop review pending.

## Exclusions
No narrative engine, dialogue, quests, lore/spoilers, NPC registry, world map, campaign save/XP/gold/loot, AI-driven story branches or production character progression. Future integration uses reviewed setup/result boundaries.

## Next work
FEAT-009 structural input/result/event hardening; FEAT-011 sprite/UI/VFX polish; FEAT-012 level-two mechanics, support for broader spell resources and monster variety. FEAT-010 initial lab exists but requires desktop/manual review.

## Open decisions
Real desktop visual signoff, touch/gamepad support and exceptions, canonical Hunter test fixture, mixed monster encounters, detailed level-two class feature rules.
<!-- [EXAMPLE ONLY — NOT APPROVED] Do not import example arcade-game controllers or narrative systems. -->
