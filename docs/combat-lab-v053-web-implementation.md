# Combat Lab v0.5.3 — Web implementation candidate

Issue [#22](https://github.com/Jonty303/Project-AzureMines/issues/22), approved scope #16 / FEAT-018; foundation #18. Draft [PR #23](https://github.com/Jonty303/Project-AzureMines/pull/23) targets `feature/combat-lab-ipad-action-ux-fixes` and depends on the open, unmerged PRs #19–#21. No merge, deployment, narrative work or canonical fixture edits.

Implementation recovery commits: `0568375` (engine and controls), `825c554cab9fc3e977f503967c58bc8cd7598aec` (acceptance suites and final gameplay implementation). Subsequent delivery changes update title help and this evidence record. The final pushed delivery SHA and its runtime/governance CI links are recorded in PR #23. Status: implemented candidate; physical acceptance pending.

## Rules and lifecycle contracts

- The existing spell registry declares Web: Level 2 Conjuration, Action, point within 60 feet, 20-foot Cube, concentration up to one hour. Only Elyra's level-3–5 Lab loadout gains it. Canonical L1 party JSON is unchanged. Spend the defined L2 tier only; no upcasting. The existing L1 resource mirror, Bonus Action rules and one-slotted-spell-per-turn guard remain intact.
- `spell_resource_reason()` is the shared resource/turn gate. `area_spell_reason()` is a pure legality query: validate the complete top-left-anchored 4×4 footprint, map bounds, walls/movement-blocking props, caster, preparation, pending reaction/move, Action/slot, range and point LOS. No clipping, relocation, RNG, saves, events or concentration replacement on preview/failure. Distance uses the Lab's existing Chebyshev five-foot grid metric and inclusive 60-foot limit. Floor anchorage is the explicit 2D interpretation; no vertical model.
- `cast_area_spell()` revalidates before creating the existing schema-one region and spending exactly one L2 slot and Action. Valid confirmation replaces concentration; Bless and Web replace each other through the existing concentration authority. Damage saves, downing/death, encounter ending, duration and restart clean the correct source. Duration expires before triggers at the original initiative boundary 600 rounds later.
- Existing `effect_hook()`, `movement_cost()`, source-owned Restrained, escape and AI APIs remain authoritative. Creation does not save. First entry per turn and start within are independent, deduplicated occasions. Actual caster DC is captured in the region. A failed DEX save grants this source's Restrained; leaving, burning away the occupied cell, expiry or concentration termination removes only that source. Escape costs an Action and uses Strength (Athletics). Existing speed-zero, Dodge, reaction and attack/save rules are reused.
- Regions add `lightly_obscured`, `flammable` and `burning_cells` fields. `area_effects_at()` returns copied snapshots. `is_lightly_obscured()` / `sight_perception_disadvantage()` report the SRD sight-based Wisdom (Perception) disadvantage. **The Lab has no Perception-check resolver**, so this query is the integration seam; no new stealth system. Web never becomes opaque or automatically imposes attack disadvantage. Tile Details explains the distinction.
- `ignite_web_cell()` exposes all eligible overlapping Web regions at one cell to a named fire source, without spreading to adjacent cells. Fire Bolt has a narrow visible-Web-cell command (`cast_fire_bolt_cell()`), spending an Action and no slot; creature targeting remains the ordinary path. Existing fire damage ignites a target's cell; authored fire hazards ignite intersecting Web at creation. Repeated ignition cannot replace an existing cell's source or extend its timer.
- Each cell burns away **before start triggers at the same initiative boundary one round after ignition**. It remains web terrain/obscurement until then. `_expire_burning_cells()` removes only that cell and its owned conditions, emits `web_cell_removed` / `area_updated`, and ends an empty region. Concentration ending removes burning cells with their region; fire does not persist independently after Web vanishes. Overlapping burning Web is one 2d4 exposure per creature/start occasion, with stable first-source attribution; no entry fire damage or duplicate damage per overlapping region. Damage uses normal concentration/downing/death handling and structured `hit` facts. Unconscious/stable creatures receive fire at initiative without an input prompt; stable initiative slots remain automatic.

## Input and presentation

Spell chip retains its upward list and current paging; Spell activates targeting. Web taps establish a 4×4 green/red outlined preview and show temporary finger-size **Confirm Web / Cancel** buttons. A second tile tap only updates the preview. Invalid placements show the engine reason and disable confirmation. Mouse and arrows/Enter select the anchor; Tab/Enter operates the confirmation button; Escape cancels. Pan, pinch and wheel zoom invalidate the pending anchor. Existing gesture-release arbitration suppresses synthetic mouse clicks after touch. Actor/spell changes, Retry and Return to Title clear targeting. Creature spells remain one-tap.

Board overlays read snapshots: pale crossed web, orange **FIRE**, and green/red selection underneath actors/target outlines. Removed cells disappear on refresh; UI never advances effects or fire. This is automated presentation-seam evidence, not physical readability acceptance.

## Changed paths

- `combat/level1_spells.gd`: data-driven definition.
- `combat_lab/setup_builder.gd`: bounded Lab loadout and truthful progression description.
- `combat/combat_engine.gd`: typed area/fire commands and queries, shared resource gate, partial burning lifecycle, encounter cleanup and downed fire timing.
- `combat/combat_board.gd`: preview/burning rendering, camera-cancellation and keyboard cancellation signals.
- `scenes/combat_lab.gd`: confirmation adapter, stale-state cleanup, area/fire help and tile Details.
- `tests/web_fixture.gd`, four `tests/test_v053_web_*.gd` suites and their UIDs.
- `.github/workflows/godot-smoke.yml`: all four new suites in runtime CI.
- This implementation record and the FEAT-018 status cross-reference. The handoff/spec preparation commits were already on the task branch.

## Executed validation — 13 November 2026

Pinned official **Godot 4.5.2.stable.official.6ce3de25a**, Linux x86_64. Editor archive SHA-256 verified: `87f6e6be292929e363d15ed9052f277b2ba4e95ed994e1e099048097be2dfd03`. Existing bootstrap separately verified editor and Web template digest `ea50e5183f057d42b22120d0d0340205b98f51f8ff13c33c70fd4ac9077d2019`. The preinstalled 4.6.3 binary was not used for acceptance. No dependency or engine-version change.

`GODOT_BIN=/tmp/azure-godot-452/Godot_v4.5.2-stable_linux.x86_64`; headless checks used `XDG_DATA_HOME=/tmp/azure-xdg/data`, `XDG_CONFIG_HOME=/tmp/azure-xdg/config`, `XDG_CACHE_HOME=/tmp/azure-xdg/cache`. The final import/start ran outside the socket-restricted sandbox. An initial sandbox import exited 0 but logged socket creation errors; that attempt is **not** clean import evidence. Export uses the existing install at `~/.local/bin/godot` and its verified templates with default user data paths.

| Command/check | Result |
| --- | --- |
| `python3 scripts/self_test.py` | PASS, including negative contract/installer checks |
| `python3 scripts/validate_template.py --project` | PASS |
| `python3 scripts/validate_toolchain.py` | PASS |
| `$GODOT_BIN --headless --path . --editor --quit` | PASS; final run without sandbox socket errors |
| `$GODOT_BIN --headless --path . --quit-after 30` | PASS |
| `$GODOT_BIN --headless --path . --script res://tests/<suite>.gd` for all 29 suites below | PASS, all exit 0 and print PASS; baseline diagnostics below |
| `python3 scripts/bootstrap_codespaces.py` | PASS, official pinned downloads verified; no actual Codespace created/rebuilt |
| `python3 scripts/preview_godot_web.py --build-only` | PASS; nonempty HTML/JS/WASM/PCK in ignored `build/web/` |
| Local Playwright + installed Chromium, 1366×1024 | PASS: real exported title and battle deployment render; no JS/console errors. This is a browser smoke, not Web casting or iPad acceptance |
| `git diff --check` | PASS |

All existing suites executed: `test_canonical_party`, `test_combat_engine`, `test_combat_playthrough`, `test_level1_features`, `test_sprite_assets`, `test_reactions_and_disengage`, `test_shield_and_bless`, `test_wagon_camp`, `test_action_bar_and_downed`, `test_audio_and_contextual_ui`, `test_party_deployment`, `test_combat_lab_setup`, `test_combat_lab_ui`, `test_web_touch_input`, `test_combat_lab_v03_feedback`, `test_v04_wide_camera_projectiles`, `test_v041_downed_auto_turn`, `test_v041_movement_impact`, `test_v043_tactical_ai`, `test_v043_spell_ui`, `test_v051_spell_slots`, `test_v051_magic_menus`, `test_v052_persistent_effects`, `test_v052_effect_presentation`, `test_ipad_action_ux_regression`.

New suites: `test_v053_web_casting` (levels, exact resources, invalid atomic casts, geometry/LOS, Bless replacement); `test_v053_web_lifecycle` (caster DC, triggers, allies/enemies, ownership, 600-round boundary, concentration, player/AI escape, paths and replay); `test_v053_web_fire` (playable ignition, 2d4 start-only damage, per-cell boundary, independent sources, all-cell burnout, downed/stable, hazards and reset); `test_v053_web_ui` (menu, actual preview/confirm/cancel adapters, invalid reasons, transform, synthetic touch drag/pinch, keyboard and stale-state cleanup). Existing suites additionally cover restraint attacks/saves/Dodge/reactions, path corners, downed initiative, projectile/impact timing, action economy and accepted/declined opportunity attacks.

Local logs/results and browser screenshots: `/tmp/azure-v053-validation/`. These are execution artifacts, not committed game assets. Final pushed-SHA GitHub runtime and governance results are linked in PR #23; governance alone is not gameplay evidence.

### Diagnostic disclosure

The existing baseline categories remain: four older audio/presentation suites log `ObjectDB instances leaked` / `1 resources still in use`; `test_combat_lab_ui` logs an exclusive AcceptDialog/ConfirmationDialog error; `test_sprite_assets` logs five PNG-as-image warnings and `test_action_bar_and_downed` two. All assertions still pass; do not describe these logs as clean. These categories were previously reproduced against the exact v0.5.1 base in the v0.5.2 evidence record. New Web suites are clean in the final run; the new UI suite disables audio playback, which is exercised by the existing audio suite. An earlier Web UI run played magic.wav and reproduced the same audio cleanup diagnostic; it was not a clean run.

### NOT RUN / acceptance limits

Physical **iPad Safari** (portrait/landscape, touch, legibility, actual confirm/burn/escape, accessibility and audio), real desktop gameplay/readability/audio signoff, gamepad and balance acceptance: **NOT RUN**. Browser title/deployment smoke and synthetic touches do not establish these checks. No owner-run v0.5.3 evidence has been supplied. Actual hosted/private Codespaces preview and Codespace inventory: **NOT VERIFIED**; only the same build command ran locally. Nothing was publicly served or deployed; the browser smoke used loopback only.

No Perception subsystem exists to exercise end-to-end; only the API/Details/LOS contract is tested. Other level-two spells, general upcasting, third-level spells, arbitrary 3D anchoring and large creature bases remain outside this slice.
