# v0.5.2 persistent effects — issue #18

Source: `f91589332371850a41cca29f537542deef669dcd`. Scope authorized by issues #18/#16; draft PR targets v0.5.1. No deployment or playable-build changes.

## Ownership and lifecycle design

CombatEngine owns version-one transient effect instances and source-indexed condition applications. Regions have deterministic encounter-local IDs, explicit floor cells, start and expiry round/initiative boundaries, concentration owner, and applied actor IDs. The UI reads snapshots only. Enter, start-turn and end-turn hooks run in simulation; enter is once per actor/effect/turn, independently of start-turn. Overlapping difficult terrain does not stack. Existing movement/reaction execution remains authoritative.

The test-only Web-shaped zone uses a top-left floor anchor and 4×4 cells. Duration is a fixture parameter in rounds, expiring before triggers at the same initiative boundary after that many rounds. This is deliberately not Web's one-hour duration or a castable spell. Creation does not trigger a save; first entry on a turn and start inside do, separately. Failed Dexterity save grants source-owned Restrained; leaving or a successful Action Strength (Athletics) check removes only that source. Restrained gives speed zero, disadvantage on attacks and Dexterity saves, advantage to incoming attacks; it does not prohibit actions, bonus actions or reactions. Check proficiency comes from explicit runtime skill data, not invented class progression. See SRD 5.2.1 attribution in repository licensing. Paralyzed is an extension point, not implemented.

Full Web, obscurement/visibility, fire, placement UI, slot spending and manual iPad acceptance remain v0.5.3 work. FEAT-017 was read from `docs/multi-tile-creature-footprints` (not present on this base); no multi-tile actor implementation.

## Validation

Pending implementation and actual execution. Physical iPad, graphical desktop, touch and gamepad: NOT RUN.
