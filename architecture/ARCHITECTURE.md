# Azure Mines — architecture

**Status:** Recorded existing approach; future deviations require an ADR
**Reviewed:** 2026-11-12

## Purpose
Document chosen runtime boundaries, rationale, and risks without imposing an engine-neutral template's example architecture.

## Human instructions
Approve material changes to state ownership, persistence, runtime architecture or external dependencies after comparing alternatives.

## AI agent instructions
Inspect live code and tests; this records design intent, not proof that every boundary has been implemented perfectly. Prefer additions that preserve established interfaces.

## Drivers and alternatives
- **Requirements:** Deterministic tactical turns, four-character party, rulesets and adventure data, persistent consequences, rapid playtesting.
- **Chosen:** Godot-native scenes and GDScript, with rules/command logic testable headlessly and authored JSON definitions.
- **Considered:** A new ECS/framework or engine-level rewrite. No measured bottleneck or gameplay need justifies that disruption now.
- **Considered:** Adventure-authored scripts executed at runtime. Rejected in the original design in favour of validated data and explicit commands.

## Module boundaries
- core/: dice utilities, module loading and shared services.
- combat/: CombatEngine and game rules/state; CombatBoard renders presentation.
- scenes/: application entry and combat UI, input-to-command translation.
- adventure/: campaign persistence, story stages, narrative state and locations.
- rulesets/: class, ancestry and rules definitions; adventures/: manifests, encounters, locations and quests.
- tools/: offline authoring editors (separate branch); exports are **not** trusted runtime documents until an importer and disclosure review exists.

## State ownership
CombatEngine owns transient battle actor/action/initiative/event state. CampaignState owns persistent party resources, rewards, flags, NPC outcomes and discovery. Combat UI is a view/command adapter, not an alternative rules resolver. Do not save arbitrary Godot nodes or have animations mutate authoritative combat state.

## Testing
Headless Godot scripts cover rules, battle transitions, UI smoke and campaign roundtrips. CI does not certify visuals, readability, physical devices or balance. New VFX should consume committed events and be safely skippable; effect timing must not change rules.

## Outstanding risks
Combat scene currently also hosts story UI; a future combat-only sandbox must avoid duplicating or breaking the campaign flow. Branch ancestry is staged through PRs #1–#4; no full integration into main is assumed. The adventure authoring exports need an explicit versioned runtime transform.
<!-- [EXAMPLE ONLY — NOT APPROVED] Introduce a new ECS library for every entity. -->
