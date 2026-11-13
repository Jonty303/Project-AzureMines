# Combat Lab v0.5.3 — Codex handoff: complete Web spell

**Status:** Prepared for implementation, **not implemented**, **not acceptance-tested**. Prepared 13 November 2026.

**Canonical implementation task:** [#22 — Codex handoff](https://github.com/Jonty303/Project-AzureMines/issues/22). **Approved programme:** [#16 — second-level magic](https://github.com/Jonty303/Project-AzureMines/issues/16), [FEAT-018](../specifications/features/FEAT-018-magic-and-tactical-effects.md). **Prerequisite engine foundation:** [#18](https://github.com/Jonty303/Project-AzureMines/issues/18) and [v0.5.2 technical notes](combat-lab-v052-persistent-effects.md).

## Branch and safety contract

- Repository: `Jonty303/Project-AzureMines`.
- Codex **existing** task branch: `feature/combat-lab-v053-web`.
- Created from `feature/combat-lab-ipad-action-ux-fixes`, PR #21 head `9a506a52a663651f5051982b3c3fcef96ee81e13` (at preparation). Read any newer parent commits before implementing.
- Future **draft PR base must be** `feature/combat-lab-ipad-action-ux-fixes`, never `main`. Historical stack: PR #19 v0.5.2 foundation; PR #20 Codespaces/Web tooling; PR #21 current iPad UI; v0.5.3 branches from all three.
- No merges, force-push, Pages deploy, engine upgrades, unrelated branch edits or narrative integration. Keep `combat_lab/fixtures/party/level_01_v1.json` immutable. Commit/push recoverable checkpoints.
- Read `AGENTS.md`, `workflows/DELIVERY.md`, `architecture/DECISIONS.md`, `specifications/features/FEAT-018-magic-and-tactical-effects.md`, and #22. Use the same Godot 4.5.2 version as the current CodeSpace and CI.

## Outcome expected in the Combat Lab

Elyra, at level **3 or above**, has **Web** in her spell chip's upward-opening, touch-friendly level-two list. The big Spell button activates targeting, but **Web targets a point/area, not a creature**. The player selects a 4×4 (20-foot cube on the 2D floor) region within 60 feet, sees valid/invalid placement, then confirms the cast deliberately. A valid cast spends **one level-two slot** and **one Action** and begins concentration, making all 16 eligible cells difficult terrain and Lightly Obscured. The effect has real DEX saves, Restrained, escape, movement/AI, flammable cells and expiry. One hour concentration maximum = **600 combat rounds**. The same engine rules apply to allies and enemies. Lower-level Elyra, Brunna and noncasters do not know Web.

Owner-tested November 13 iPad baseline (informal): v0.5.2 + PRs #20/#21 rendered/played in Safari and the previous broken glyphs, spell paging and stale used-button state were reported resolved. This is **not** evidence that any v0.5.3 feature works. Retain the action bar's icon-plus-text language, clear End Turn button and bonus-spell affordance; cosmetic action-bar polish is low priority.

## Design constraints and decision points

### 1. Keep engine authority

Extend `combat/level1_spells.gd` (or introduce a small data-driven spell registry with backward compatibility), `combat/combat_engine.gd`, `combat/combat_board.gd`, `combat_lab/setup_builder.gd`, and `scenes/combat_lab.gd` rather than copying rules into UI. The existing `create_area_effect()`, `effect_hook()`, source-owned conditions, `movement_cost()`, concentration, and versioned event API are authoritative. Preserve test-only `create_test_web_area()` for old regressions. `can_cast_spell()` and `cast_spell()` currently accept **creature IDs**; a separate typed area/point query and command should avoid false enemy-target validation or silently treating a chosen tile as an actor.

**Transactional cast order:** validate the full area, caster, slot, action, any pending reaction/movement, line to the target point and range **before** expending a spell slot, setting action_used or replacing concentration. If the effect cannot be created, return a named failure with no side effects. Do not mutate the RNG or produce a `cast` event from preview operations. Make the resulting effect ID and covered cells stable/deterministic.

### 2. Area interaction and anchored geometry

- Explicit 4×4 **top-left** anchor on 5-foot cells; do not auto-shift or clip at arena boundaries. Preserve currently implemented walls, terrain and obstacle policy; surface any rejected footprint visibly with a reason. Players can see all 16 cells before committing. The flat arena floor is suitable anchorage for this implementation, so do not implement arbitrary vertical anchorage.
- Two-step touch: tap cell to establish preview, then tap a clearly labelled **Confirm Web** (or an equivalent explicit confirmation) to cast; **Cancel** escapes without expenditure. Scroll, pan, pinch and accidental double mouse events never confirm. Keyboard arrows/Enter and mouse are usable equivalents. On actor switch, spell change, Retry or Return to Title, remove transient preview.
- A Web preview under zoom/pan uses the board's existing camera transform. The preview must not block underlying actor silhouettes/target outlines. Avoid a permanent extra row in the bottom command bar.

### 3. Exact spell / condition semantics

- Web: Level 2 Conjuration; Action; 60-foot point; Concentration up to 1 hour; 20-foot Cube; Difficult Terrain; **Lightly Obscured**, not opaque.
- First entry on a turn **or** start of turn within the region: DEX save against **caster spell save DC**, once per defined occasion/trigger (not each crossed cell). Failed save applies this effect's Restrained. While restrained: speed zero, Disadvantage on the actor's attacks and DEX saves, Advantage to attacks targeting the actor; preserve existing action/reaction semantics. A restrained actor may use its Action for a **Strength (Athletics)** escape against that DC. Preserve source isolation on overlaps.
- Do not invent a perception/stealth subsystem. The relevant SRD rule for Lightly Obscured is Disadvantage on **sight-based Wisdom (Perception)** checks. Provide a correctly typed query/snapshot; apply it if a sight-based Perception resolver already exists. It does **not** automatically break line of sight or impose ranged attack Disadvantage. Expose Lightly Obscured clearly in tile Details.
- Damage, replacement (including Bless), downing/death, duration and encounter reset break the correct concentration and remove that source's web and its conditions. The player's target choice cannot break the previous concentration until a **legal confirmed cast**. Other active regions survive cleanup of unrelated effects.
- `slotted_cast_this_turn` and Action/Bonus Action remain independent, with only one spell-slot expenditure per turn under the project's existing SRD 5.2.1 rule. An attack followed by Brunna's Healing Word remains legal where its other requirements are met; no general allowance for Web plus another level-one slot cast in the same turn.

### 4. Fire lifecycle (required for completion)

- Cells of Web exposed to actual fire can ignite individually. A burning 5-foot cell burns away in **one round** and deals **2d4 fire** to any creature **starting its turn in the fire**. Resolve with deterministic rolls and source events. Keep burning, intact web and removed web distinguishable in board overlays and engine snapshots.
- Provide an actual playable ignition path with existing fire effects. `Fire Bolt` is presently creature-targeted, so narrowly enable targeting an eligible Web tile when in range/line of sight if needed, without introducing a universal object-target system. Also consider whether existing campfire/fire hazard intersections expose Web cells to fire. Player must be able to demonstrate ignition in the Lab.
- Burning/removing one cell updates terrain, obscurement and effect-owned conditions for **that cell**, without destroying other 15 cells or independent overlapping zones. Prevent repeated fire damage, missing-cell ignition or stale path costs. Rules text does **not** mandate automatically igniting adjacent Web squares. Only propagate if a separately modeled fire source exposes them.
- Clarify and test event timing when fire starts, creatures start turns during the one-round burn, concentration breaks during that time, and the last affected cell disappears. Do not accidentally advance fire on scene refresh.

## Deterministic acceptance and test files

Codex should introduce focused new Godot suites, proposed names:

| Suite | Required acceptance |
| --- | --- |
| `tests/test_v053_web_casting.gd` | Elyra L3+ availability, missing/insufficient L2 slots, area/point legality, blocked/out-of-bounds placement, failed casts without side effects, exact L2 slot/Action cost, one-slotted-spell guard, concentration replacement |
| `tests/test_v053_web_lifecycle.gd` | Region geometry, trigger deduplication, allies/enemies, caster save DC, Restrained/escape, overlap ownership, 600-round expiry, deterministic replay, Bless and downing interactions |
| `tests/test_v053_web_fire.gd` | Legal fire ignition, per-cell burn-out after one round, start-turn 2d4, fire-source overlap, no chain spread unless separately fueled, cleanup and replay |
| `tests/test_v053_web_ui.gd` | No caster at L1/2, level-three entry in picker, legal/illegal target overlays, explicit preview/confirm/cancel, scroll/pan/zoom mapping, no double cast on touch, action state and slot display remain accurate |

Run every existing suite including `test_v052_persistent_effects.gd`, `test_v052_effect_presentation.gd`, `test_v051_magic_menus.gd`, `test_v043_spell_ui.gd`, `test_web_touch_input.gd`, and `test_ipad_action_ux_regression.gd`, plus the full GitHub `godot-smoke.yml` and governance workflow. Preserve older known diagnostic categories but clearly report them.

Example checks (from repository root, with the configured pinned binary):

```sh
python3 scripts/self_test.py
python3 scripts/validate_template.py --project
"$HOME/.local/bin/godot" --headless --path . --import
"$HOME/.local/bin/godot" --headless --path . --quit-after 30
"$HOME/.local/bin/godot" --headless --path . --script res://tests/test_v053_web_casting.gd
python3 scripts/preview_godot_web.py --build-only
```

**Manual iPad acceptance:** On a level-three Elyra, inspect Web in the spell list, preview a 4×4 legal/illegal area under zoom/pan, cancel (no spent slot), confirm (one L2 slot), walk a goblin through the area and watch its DEX save/Restrained, try AI escape, ignite one square and verify burn/2d4/start-turn timing, replace concentration and watch effect/conditions vanish, Retry and verify no stale UI or effect. Check both landscape and portrait; capture browser/device and build commit. Physical touch, visuals, audio and accessibility are **NOT RUN** for v0.5.3 until actually tested. No public preview deployment.

## Exclusions and release gate

Do **not** implement other Level 2 spells (Misty Step, Mirror Image, Aid, Hold Person, Lesser Restoration), full third-level progression, general upcasting, multi-tile actors, campaign narrative/adventure integration, new asset dependencies, or speculative control redesign. Keep the existing real-time and deterministic combat core intact. If Web requires further stages, commit a working incomplete slice but do **not** expose an incomplete castable Web as fully available or claim acceptance.

**Codex final output:** Draft PR targeting `feature/combat-lab-ipad-action-ux-fixes`, explicit dependency on #19–#21, source SHA, modified paths, new/old suite outputs, CI links, rules/targeting decisions, and `docs/combat-lab-v053-web-implementation.md` with status and known gaps. Do not merge or deploy automatically.

## Authoritative references

- [2024 Web rules](https://www.dndbeyond.com/spells/2619208-web)
- [2024 obscured-area rules](https://www.dndbeyond.com/sources/dnd/br-2024/playing-the-game)
- [Azure Mines licensing and SRD attribution](licensing.md)
- [v0.5.3 GitHub task](https://github.com/Jonty303/Project-AzureMines/issues/22)
