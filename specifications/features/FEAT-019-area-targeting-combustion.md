# FEAT-019 — Area Targeting and Combustion

**Iteration:** Combat Lab v0.5.3.1  
**Status:** Prepared for Codex; not yet implemented or accepted.  
**Authoritative implementation task:** [Issue #24](https://github.com/Jonty303/Project-AzureMines/issues/24)  
**Base:** Existing v0.5.3 Web candidate / draft PR #23  
**Working branch:** `feature/combat-lab-v0531-targeting-combustion`

## Player-visible goals

- Web is selected by tapping a **central floor square**. The nominal 20-foot / 4×4 footprint is placed using the deterministic tie-break `top_left = selected - Vector2i(1,1)` (selected square occupies the upper-left cell of the central 2×2).
- One tap previews; a **second deliberate tap on the same square** confirms and casts; a tap elsewhere relocates the preview. Keep Confirm Web/Cancel for accessible alternatives. Synthetic mouse events from a single touch, dragging, panning, zooming and pinch do not cast.
- Keep line of sight and range to the **selected point**. A solid wall inside the footprint masks affected Web tiles and stops propagation behind it instead of invalidating every viable tile. Restrict coverage to cells connected orthogonally to the chosen target within the nominal 4×4. Cover-only scenery and creatures should not veto an entire cast. No silent clipping at map boundaries or automatic repositioning.
- Web exposed to fire **Burns** for one round, deals the pre-existing 2d4 start-of-turn fire damage per exposed creature, and disappears per cell. An **Azure Mines house rule** spreads the flame one orthogonal step through still-connected Web at each burning cell's one-round expiry boundary, excluding walls and absent cells. Newly ignited cells cannot recursively spread in the same boundary.
- Anything **actually ignited** has a typed Burning state with owner/source, onset, fuel/duration and public immutable snapshot. Working status must cover Web cells and creatures; extend the existing obstacle registry with at least one flammable object test fixture where feasible, without promising a general object-destruction framework.
- **Explicitly ignited creatures** (not simply struck by Fire Bolt or damaged by burning Web) gain Burning and take a proposed **1d4 start-of-turn fire damage, at most three start-turn ticks**. One Action **Extinguish** removes it; explicit water/dousing can use a typed future adapter. Repeated ignition doesn't stack/reset; creature Burning persists after exiting the fire or the caster ending concentration. Stable/downed actors are resolved automatically without prompts.
- Present a clear distinction between nominal area, actual Web, blocked cells, active fire and Burning actors without relying on colour alone.

## Ownership and rule separation

The spell's established SRD mechanics remain: L2 slot, Action, 60-foot point, 4×4 nominal area, concentration up to 600 rounds, difficult terrain, Lightly Obscured, restrained/escape, **2d4 fire on start within burning Web**, one-round *per-cell* burn-away. **Spread, creature Burning and numerical duration are Azure Mines house-rule defaults for playtesting, not claims about the SRD.** The next previously planned first-level spell expansion is not part of this iteration.

`CombatEngine` is authoritative over pure preview/legality results, explicit masked cells in active effects, action/slot/concentration validation, source-owned statuses, initiative timing, deterministic damage/spread and events. The board and UI only issue commands and render read-only snapshots. No RNG/events/resources/conditions change on previews or rejected casts. Maintain older rectangular area test APIs and all existing combat/action/movement/AI functionality.

## Deterministic test gates

1. Central-footprint mapping, range/LOS at selected square, partial wall masks, separated pockets, cover-only props, off-board rejection and no accidental full-area rejection.
2. Two distinct same-square taps = one committed cast; different cell retargets; explicit Confirm/Cancel; keyboard equivalent; touch synthetic-mouse and gesture suppression; stale-target cleanup.
3. Four-neighbour, one-step-per-round Web spread, walls as firebreaks, per-cell burnout, 2d4 start-only exposure, overlap deduplication, condition/path/concentration cleanup and deterministic replay.
4. Explicit actor ignition, 1d4/three ticks, extinguish action economy, no auto-ignition on simple fire damage, downed/stable/death and concentration handling; flammable/non-flammable prop boundary.
5. All existing Godot 4.5.2 test suites, new v0.5.3.1 suites registered in runtime CI, headless import/start, genuine Web export, Codespaces port 8765 browser smoke, correct final-SHA governance/runtime CI. Physical iPad Safari tests require owner action and remain NOT RUN until completed.

**Exclusions:** New spells, general weather and smoke, global destructible objects, campaign/narrative, engine upgrades, Pages deployment, merges and template changes.

Read [the full Codex issue](https://github.com/Jonty303/Project-AzureMines/issues/24) for exact event, overlap, expiry and regression acceptance conditions.
