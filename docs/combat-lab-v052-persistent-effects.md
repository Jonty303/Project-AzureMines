# v0.5.2 persistent effects — issue #18

Source: `f91589332371850a41cca29f537542deef669dcd`. Scope authorized by issues #18/#16; draft PR targets v0.5.1. No deployment or playable-build changes.

## Ownership and lifecycle design

CombatEngine owns version-one transient effect instances and source-indexed condition applications. Regions have deterministic encounter-local IDs, explicit floor cells, start and expiry round/initiative boundaries, concentration owner, and applications containing actor ID plus condition name. The UI reads snapshots only. Enter, start-turn and end-turn hooks run in simulation; enter is once per actor/effect/turn, independently of start-turn. Overlapping difficult terrain does not stack. Existing movement/reaction execution remains authoritative.

The test-only Web-shaped zone uses a top-left floor anchor and 4×4 cells. Duration is a fixture parameter in rounds, expiring before triggers at the same initiative boundary after that many rounds. This is deliberately not Web's one-hour duration or a castable spell. Creation does not trigger a save; first entry on a turn and start inside do, separately. Failed Dexterity save grants source-owned Restrained; leaving or a successful Action Strength (Athletics) check removes only that source. Restrained gives speed zero, disadvantage on attacks and Dexterity saves, advantage to incoming attacks; it does not prohibit actions, bonus actions or reactions. Athletics adds declared proficiency or double proficiency for expertise, never an invented class benefit. Dodge loses its defensive benefit at speed zero. Damage concentration DC is half damage rounded down, bounded to 10–30. See [SRD 5.2.1 attribution](licensing.md). Paralyzed is an extension point, not implemented.

Full Web, obscurement/visibility, fire, placement UI, slot spending and manual iPad acceptance remain v0.5.3 work. FEAT-017 was read from `docs/multi-tile-creature-footprints` (not present on this base); no multi-tile actor implementation.

## API and compatibility

`create_area_effect(source_id, definition)` validates a schema-one rectangular floor region with explicit trigger list and optional Restrained resolver. `create_test_web_area()` supplies its 4×4 test definition; production setup and spell lists never call it. `movement_cost()`, `has_area_effect_at()` and copied `area_effects_at()`/`condition_snapshot()` are query seams. `can_escape_effect()`/`escapable_effects()`/`escape_effect()` are the shared command interface. The initial player button escapes the earliest stable source ID; explicit source choice remains available in the engine API. Effect IDs order overlap resolution deterministically. Conditions are indexed by actor, condition name and effect ID; applications retain actor plus condition so expiry can remove only owned applications. Unsupported conditions are rejected until their semantics are implemented.

Existing CombatSetup and slot-tier contracts remain unchanged. CombatResult adds optional `effect_condition_sources` to each actor; the legacy `conditions` array remains compatible. Bless retains its legacy targets/turn counter and uses the same concentration replacement/damage/ending path. Start/end/save concentration facts are structured; regions additionally emit effect/condition/area facts. Non-concentrating regions survive source downing until their own expiry. Active regions and source maps are transient and cleared on restart.

## Validation — 13 November 2026

Runtime source tested: `37bc45a05363d837969752eb216c6e52978f7664`; subsequent delivery-note changes are documentation only. Godot **4.5.2.stable.official.6ce3de25a**, Linux x86_64, official archive SHA-256 **87f6e6be292929e363d15ed9052f277b2ba4e95ed994e1e099048097be2dfd03** verified using `sha256sum -c` before extraction. No engine upgrade or new dependency.

Commands used `/tmp/azure-godot-452/Godot_v4.5.2-stable_linux.x86_64` (`$GODOT_BIN` below) from repository root, with `XDG_DATA_HOME=/tmp/azure-xdg/data`, `XDG_CONFIG_HOME=/tmp/azure-xdg/config`, `XDG_CACHE_HOME=/tmp/azure-xdg/cache`. Initial sandbox import failed to create home directories/IPC sockets; redirected user directories plus an approved execution outside sandbox produced a clean import. No home or application settings were changed.

| Executed command | Result |
| --- | --- |
| `$GODOT_BIN --headless --path . --editor --quit` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --quit-after 30` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_canonical_party.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_combat_engine.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_combat_playthrough.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_level1_features.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_sprite_assets.gd` | PASS (exit 0); diagnostics disclosed below |
| `$GODOT_BIN --headless --path . --script res://tests/test_reactions_and_disengage.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_shield_and_bless.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_wagon_camp.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_action_bar_and_downed.gd` | PASS (exit 0); diagnostics disclosed below |
| `$GODOT_BIN --headless --path . --script res://tests/test_audio_and_contextual_ui.gd` | PASS (exit 0); diagnostics disclosed below |
| `$GODOT_BIN --headless --path . --script res://tests/test_party_deployment.gd` | PASS (exit 0); diagnostics disclosed below |
| `$GODOT_BIN --headless --path . --script res://tests/test_combat_lab_setup.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_combat_lab_ui.gd` | PASS (exit 0); diagnostics disclosed below |
| `$GODOT_BIN --headless --path . --script res://tests/test_web_touch_input.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_combat_lab_v03_feedback.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_v04_wide_camera_projectiles.gd` | PASS (exit 0); diagnostics disclosed below |
| `$GODOT_BIN --headless --path . --script res://tests/test_v041_downed_auto_turn.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_v041_movement_impact.gd` | PASS (exit 0); diagnostics disclosed below |
| `$GODOT_BIN --headless --path . --script res://tests/test_v043_tactical_ai.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_v043_spell_ui.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_v051_spell_slots.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_v051_magic_menus.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_v052_persistent_effects.gd` | PASS (exit 0) |
| `$GODOT_BIN --headless --path . --script res://tests/test_v052_effect_presentation.gd` | PASS (exit 0) |
| `python3 scripts/self_test.py` | PASS (exit 0) |
| `python3 scripts/validate_template.py --project` | PASS (exit 0) |
| `python3 scripts/validate_toolchain.py` | PASS (exit 0) |

All 24 test suites executed and printed PASS; this includes all 22 existing suites, v0.4.3 tactical AI/spell controls, v0.5.1 slots/menus and both new v0.5.2 suites. New suites cover creation/expiry/reset, arbitrary end-turn hooks, trigger deduplication, overlap/ownership, terrain/path/AI, escape proficiency and action economy, concentration/Bless, downed/dead actors, accepted/declined opportunity reactions, camera/query invariance, player status/escape controls and fixed-seed replay. New suites, import and startup have no logged errors/warnings. Headless rendering exercises the seam; it does not establish physical readability.

### Existing diagnostics — reproduced on exact base

An isolated `git archive f91589332371850a41cca29f537542deef669dcd` under `/tmp/azure-v051-baseline` was imported with the same binary; the seven affected suites were rerun there. Each reproduced the same diagnostic category and exited 0:

- `test_audio_and_contextual_ui`, `test_party_deployment`, `test_v04_wide_camera_projectiles`, `test_v041_movement_impact`: `ObjectDB instances leaked at exit` and `1 resources still in use at exit`.
- `test_combat_lab_ui`: exclusive AcceptDialog requested while ConfirmationDialog already has exclusivity (node-number suffix differs after the additional Escape button).
- `test_sprite_assets`: five direct PNG-as-image loading warnings; `test_action_bar_and_downed`: two equivalent warnings for the downed atlas/props.

These remain unresolved baseline diagnostics, not clean logs or new-suite failures. Complete local logs: `/tmp/azure-v052-validation/`; base comparison: `/tmp/azure-v051-diagnostics/`. GitHub runtime CI is separately linked in PR #19; governance alone is not runtime evidence.

### Unfinished / NOT RUN

Full castable Web, spell slot spending, manual placement/preview, light obscurement/visibility rules, ignition/burning/flame propagation and Web's full duration remain intentionally unimplemented for v0.5.3. The floor anchor is the fixture anchorage rule, not a general vertical anchorage model. Paralyzed and other conditions require a later resolver; multi-tile actors remain design-only. No full Web completion claim.

Physical iPad Safari touch/visual, graphical desktop readability/audio, gamepad, Web export and preview/deployment: **NOT RUN**. The existing iPad camera/touch tests passed, but are not physical acceptance. Manual follow-up: create the fixture via the test API, inspect its 16 cells/status at min/max zoom and pan, verify Escape versus other Actions, expire/break concentration, then restart. No preview was published.

## Exact modified paths

- `.github/workflows/godot-smoke.yml`
- `architecture/DECISIONS.md`
- `combat/combat_board.gd`
- `combat/combat_engine.gd`
- `docs/combat-lab-v052-persistent-effects.md`
- `scenes/combat_lab.gd`
- `specifications/features/FEAT-018-magic-and-tactical-effects.md`
- `tests/test_v052_effect_presentation.gd`
- `tests/test_v052_effect_presentation.gd.uid`
- `tests/test_v052_persistent_effects.gd`
- `tests/test_v052_persistent_effects.gd.uid`
