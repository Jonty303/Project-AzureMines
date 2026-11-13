# Azure Mines — Standalone Combat Lab

**v0.4.1 gameplay and animation correction:** [FEAT-016](specifications/features/FEAT-016-downed-turns-impact-and-movement.md) documents automatic death saves without downed player turns, deliberate AI policy for active threats, smooth tile movement and impact-synchronised death sprites/audio. The feature is implemented on `feature/combat-lab-v041-downed-turn-impact`; manual iPad acceptance remains pending.


**v0.4 playable implementation:** [Expanded battlefield and iPad controls](docs/combat-lab-v04-release.md), aligned to the [owner-agreed art direction](docs/combat-lab-ipad-art-direction-v02.md) and [FEAT-015](specifications/features/FEAT-015-ipad-camera-projectiles-and-card-actions.md). Built on `feature/combat-lab-v04-ipad-camera-cards`; deployment only follows passing Godot CI.

## Web / iPad preview (feature branch)

The web/touch development slice is on `feature/combat-lab-web-touch`, based on this standalone lab. It contains native board touch handling, keyboard tile navigation, tablet-sized controls, and a pinned single-threaded Godot 4.5.2 HTML5 export. See [Web preview and iPad testing](docs/web-touch-preview.md).

**Status (12 November 2026):** [GitHub Pages is live](https://jonty303.github.io/Project-AzureMines/) and the iPad Safari battlefield has been visually reviewed. Development uses a reviewed feature branch plus the configured `feature/combat-lab-web-touch` publishing branch; headless tests do not replace physical touch acceptance.

**v0.3 tactical feedback:** [FEAT-014](specifications/features/FEAT-014-tactical-feedback.md) adds versioned resolved combat events, initial slash/hit/spell/healing VFX, iPad tactical hints/party resources, and moves in-combat Debug I/O into the Actions tab. The top bar no longer duplicates Log/Debug controls.


**Prototype branch:** `feature/standalone-combat-lab` · **Engine:** Godot **4.5.2** standard GDScript

This is a combat-only developer test harness. It deliberately contains **no narrative engine**, campaign progression, persistent NPC register, quest system or campaign rewards. All of the original narrative work remains on other branches; nothing is merged or deleted from those branches.

## Launch

Open repository-root `project.godot` in Godot 4.5.2 and press F5, or run:

```sh
godot --path .
```

The game now opens at **Combat Lab**, not the Old Trade Road narrative scene.

## Combat Lab workflow

1. Read the party list and current test level on the title screen. Select a level **1–5** and press **Set Party Level**.
2. Select the fourth slot: original **Pip (Thief)**, or **Rowan (Hunter test)**. The Hunter temporarily borrows Pip's sprite and battlefield slot; it is not the canonical character definition.
3. Press **Configure Encounter...** and select enemy archetype, count **1–8**, arena and deterministic seed.
4. Press **Start Combat** to enter the same `CombatEngine` and `CombatBoard` used by the rules tests.
5. Choose a formation or click a hero then a deployment cell; press **Begin Battle**. Use Move, Attack, Spell, Second Wind, Dash, Dodge, Disengage, reactions and End Turn as applicable. Invalid options are disabled.
6. Press **Debug I/O** to inspect the exact `CombatSetup` dictionary. When the fight ends, the test result is written to `user://combat_lab_last_battle.json`.
7. Return to the title to open **Last Battle Log**, showing remaining HP, death/incapacitation states, action events and outcome. Restart Godot to confirm it persists.

The result deliberately records `xp: 0`, `gold: 0`, `loot: []` with `reward_policy: sandbox_no_rewards`. It never mutates `user://azure_mines_slot1.json`.

## Current rule coverage and limitations

- The immutable original **level-one fixture is preserved** under `combat_lab/fixtures/party/`.
- Levels 2–5 are **test scaffolding**, with fixed HP increments and tiered spell slots. They are **not** full class progression. Elyra's level-3+ Lab loadout includes Web; other second-level spells and third-level spells remain unavailable.
- Only actual `combat/level1_spells.gd` spell implementations are offered; future class spells and unimplemented abilities are not falsely advertised as playable. Current examples include Fire Bolt, Ray of Frost, Magic Missile, Bless, Cure Wounds, Healing Word, Mage Armor, Sacred Flame and Shield (reaction only).
- Four active party slots remain available, with the optional Hunter test variant in slot four. A future canonical Hunter fixture will replace this temporary slot identity.
- The enemy library currently reuses known functioning goblin, wolf and grub stat blocks. The same archetype may appear multiple times; mixed armies, reinforcement triggers and NPC morale are later features.
- Battle outcome presently represents a win/loss based on incapacitation. A future `CombatResult` will extend this for surrender, escape, objectives and registry updates.
- Sound uses existing original WAV assets. Art/motion polish is scheduled separately; no new spell/slash animations are claimed here.
- Desktop layout, accessibility, physical touch/gamepad, and game balance still require manual acceptance.

## Code ownership

```
combat/                     Authoritative deterministic battle rules and board rendering
combat_lab/setup_builder.gd  CombatSetup builder (party, arena, enemies, seed)
combat_lab/fixtures/         Test-only data; no story content
scenes/combat_lab.gd         Title, configuration dialog, combat controls, debug and log
scenes/combat.tscn           Application entry scene
tests/                      Pure rule tests plus Combat Lab UI/setup integration
specifications/              FEAT-009 architecture boundary, FEAT-010..012 delivery plan
```

## Validation

```sh
python3 scripts/self_test.py
python3 scripts/validate_template.py --project
GODOT_BIN=/absolute/path/to/godot bash scripts/validate_godot.sh
```

The GitHub Actions Godot workflow verifies the pinned release SHA-256, parses/imports the game, runs the title screen headlessly and tests combat rules and the lab UI. Passing headless tests is **not** proof of visual quality or physical-device support.

## Branch isolation

`feature/standalone-combat-lab` was created from `feature/combat-lab-polish-level2`, which itself inherits the adopted development template. The earlier narrative/combat feature branches and their unmerged PRs remain intact. This branch is intended for combat iteration, not for reintroducing campaign orchestration.

## Codespaces Godot setup and current-branch iPad preview

For this Godot **4.5.2** project, Codespaces creation/rebuild now uses `scripts/bootstrap_codespaces.py` to download the checksum-pinned official Linux editor and Web templates from `development/toolchain.json`, install `~/.local/bin/godot` and perform a headless import. Godot Tools points at `/home/vscode/.local/bin/godot` and uses headless language-server mode. This replaces the old documentation-only Codespace, but an **existing Codespace must rebuild or run the installer manually** after pulling the change.

On the intended development branch, use:

```sh
python3 scripts/bootstrap_codespaces.py
python3 scripts/preview_godot_web.py
```

Then open **Ports → 8765 → Open in Browser** from the iPad Codespaces editor. The second command builds the **currently checked-out commit**, verifies nonempty HTML/JS/WASM/PCK output and only then serves the site; it cannot silently display an empty directory. Keep the forwarded port private. The server runs until Ctrl+C, and it does not publish Pages or merge any branch.

Check `git branch --show-current` before playtesting. On `feature/combat-lab-v053-web`, Elyra at level 3+ can select Web, tap a top-left floor anchor to preview all 16 cells, then use **Confirm Web** or **Cancel**. Fire Bolt can ignite an intact Web cell. See [Web implementation and validation limits](docs/combat-lab-v053-web-implementation.md); physical iPad acceptance remains pending. If a persisted local VS Code setting still points to `/workspaces/Project-AzureMines/godot`, remove that override in favour of `/home/vscode/.local/bin/godot`.
