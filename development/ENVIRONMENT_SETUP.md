# Azure Mines — environment setup

**Status:** Documented baseline; local machine and Codespaces installations require evidence.
**Reviewed:** 2026-11-12

## Purpose
Describe reproducible setup on a local machine, GitHub Actions and optional Codespaces.

## Human instructions
Install Godot 4.5.2 standard on the chosen desktop OS; record version, platform, IDE, graphical/audio access, supported controllers and results. Authorise Codespaces resources or a non-Codespaces workflow explicitly.

## AI agent instructions
Check installed tool versions before any changes. Do not claim a configured Codespace, Godot editor or physical controller without seeing evidence.

## Desktop bootstrap
1. Clone/checkout an approved Azure Mines branch without altering the stacked PR chain.
2. Launch the repository-root `project.godot` with Godot 4.5.2 stable (standard, non-.NET).
3. From a terminal with a verified Godot binary run: `GODOT_BIN=/absolute/path/to/godot bash scripts/validate_godot.sh`.
4. Run relevant unit scenarios using `godot --headless --path . --script res://tests/test_combat_engine.gd` and the project CI matrix.
5. Perform a full **desktop** combat encounter, verifying art, fonts, sound, selection and responsive action feedback.
6. Run `python3 scripts/self_test.py` and `python3 scripts/validate_template.py --project`.

## CI
The Godot smoke workflow pins the exact standard Linux archive and verifies it with SHA-256 before import, boot and tests. The governance workflow validates documents and the toolchain manifest independently.

## Optional Codespaces
The repository devcontainer provides Python documentation tooling and Godot editor extension but no engine installation. Before using it check actual Codespaces inventory, branch, git status, readiness and owner approval as specified in ENVIRONMENT_CONTRACT.md. To apply a changed active devcontainer, save work and deliberately rebuild the container; do not assume it auto-rebuilt. If inventory is inaccessible: NOT VERIFIED.

## Art and tooling
The adventure and dungeon browser editors exist on feature/adventure-design-tools, not this branch. The editors use plain JS/HTML and optional Node/browser tests; do not claim they are part of the production Godot runtime.

## Input and exports
Current mouse-based combat UI exists; keyboard, real touchscreen and gamepad support must be reviewed with explicit target devices. No export/platform launch validation was performed by creating this file.

## Troubleshooting
Version mismatch -> use the pinned 4.5.2 standard build. Import/script parse errors -> run the existing CI smoke commands and inspect logs. 'No Godot installed' -> NOT RUN; provisioning is a separate task.
<!-- [EXAMPLE ONLY] A possible Windows laptop and gamepad combination is not evidence of a tested setup. -->
