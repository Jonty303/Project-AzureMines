# Codex handoff — Combat Lab v0.5.3.1 targeting and combustion

**Ready to implement, not implemented.** [Issue #24 is the full execution brief](https://github.com/Jonty303/Project-AzureMines/issues/24). [FEAT-019 is the supporting spec](../specifications/features/FEAT-019-area-targeting-combustion.md).

## Git contract

- Repo: `Jonty303/Project-AzureMines`.
- Work **only** on prepared `feature/combat-lab-v0531-targeting-combustion` (created from v0.5.3 head `195c1877517ef8243948de993c55f280e8ebfac9`).
- Existing v0.5.3 Web draft PR #23 targets `feature/combat-lab-ipad-action-ux-fixes`. Open **new draft PR targeting `feature/combat-lab-v053-web`**, not `main`.
- Do not merge, deploy, force-push, change canonical fixtures or edit template; protect uncommitted changes.
- Read `AGENTS.md`, `workflows/DELIVERY.md`, `FEAT-018`, `FEAT-019`, issue #24 and `docs/combat-lab-v053-web-implementation.md` before changes.

## Existing foundations

`combat/combat_engine.gd` has `area_spell_reason()`, `cast_area_spell()`, `create_area_effect()`, `ignite_web_cell()`, `_expire_burning_cells()`, `_web_fire_start_turn()`, source-owned Restrained and concentration. They currently treat area selection as top-left, reject blocked cells in the whole footprint, and do **not** spread fire. `scenes/combat_lab.gd` and `combat/combat_board.gd` have an existing preview/confirm UI with iPad gesture arbitration. `tests/test_v053_web_ui.gd` currently asserts second tap **does not** confirm: migrate this expectation deliberately.

## Checkpoint sequence

1. **Shape/legality:** Pure engine preview of selected point, nominal 4×4, real reachable Web cells and excluded/blocking cells. Deterministic centre tie-break, LOS and range to selected point. Generalise active effects for explicit masked cell sets without breaking existing rectangular fixtures or historical tests.
2. **Controls:** On a second *distinct* same-square tap (or Enter twice) invoke the authoritative revalidated cast exactly once. A new square retargets. Keep explicit Confirm Web/Cancel and all gesture/synthetic mouse protections. Render blocked/affected cells from engine snapshots.
3. **Web combustion:** One-round per-cell burning remains. Add one-wave-per-expiry-boundary, orthogonal-only connected propagation via snapshot-before-mutate. No duplicate ignition/damage/stacking on overlaps. Existing 2d4 at creature start remains unchanged.
4. **Generic Burning:** Expose typed snapshots/events for actors, Web cells and one authored flammable prop fixture. Explicit actor ignition only, proposed house-rule 1d4 at start for up to three ticks, Action Extinguish, nonstacking, automatic downed processing. No global destructible/weather implementation.
5. **Verify and deliver:** New `tests/test_v0531_*.gd` and CI registration, all old suites, pinned Godot 4.5.2 import/start, Web export, Codespaces smoke test and documented physical iPad playtest steps. Push recoverable checkpoints and open a *draft* PR against the v0.5.3 branch. Do not claim physical acceptance from headless tests.

## Owner acceptance checklist

Test in iPad Safari on private forwarded port 8765. At level 3+ select Elyra/Web, tap centre to preview then same square to cast; test moving preview and explicit Confirm/Cancel, partial effect beside a wall and low scenery, Fire Bolt ignition and burn wave across successive turns, wall firebreak, a separately ignited creature with Burning status/Extinguish Action, and portrait/pinch/pan/retry. Confirm resources, statuses, reactions, AI paths, and downed turns are unchanged. Capture game version, iPadOS/Safari and screenshots of any issues. Physical test is **NOT RUN** until owner does it.
