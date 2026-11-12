# SPEC-001 — Game loop and tactical states

**Status:** Existing behavior documented; extensions require approval · **Reviewed:** 2026-11-12

## Purpose
Describe game/battle states and invariants without recreating the Godot engine loop.

## Human instructions
Approve changes to restart, defeat, save and campaign transitions. Determine whether the combat sandbox is production-accessible or development-only.

## AI agent instructions
Use existing CombatEngine, OpeningSession and campaign transition methods; verify invalid and repeated transitions.

## Existing state contract
- Startup currently opens illustrated narrative approach in scenes/combat.tscn.
- Continue -> party deployment -> battle. Tactical turns and initiative start only after deployment.
- Combat victory -> documented story aftermath/exploration with once-only rewards, or independent cave battle conclusion.
- Defeat uses the existing game-over path; battle save and deployment save are unavailable.
- Persistent party resources and story outcomes belong to CampaignState; restart must not mutate stored saves inadvertently.

## Combat sandbox proposal (not yet implemented)
Start a deterministic fixture from an explicit development-only entry, choose reset/replay, and exit without changing campaign state or production rewards. Do not change the main startup until reviewed. Prefer separate scene/launcher using existing engine.

## Acceptance
- Startup, deployment, turns and victory/defeat behave unchanged in campaign regression tests.
- Sandbox tests demonstrate repeated fixture reload without leaked actors, duplicate listeners or extra awards.
- Visual effect playback cannot change initiative, hit/damage calculations or state transitions.
<!-- [EXAMPLE ONLY] Restart does not leave duplicate actors; confirm by a separate headless test. -->
