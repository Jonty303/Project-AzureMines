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

## Azure Mines Codespaces: Godot 4.5.2 and iPad Web preview

The previous `.devcontainer` was a documentation/Python image with **no engine**; Codex's validated `/tmp` binary was not persisted into the running Codespace, and starting `python3 -m http.server` before Web export produced an empty directory listing. The new devcontainer now provisions the editor and single-threaded Web export templates from SHA-256-pinned official 4.5.2 archives. Installation is idempotent, uses `/home/vscode/.local/bin/godot`, and runs a headless import. The Godot Tools extension is configured for that path and headless LSP.

For an existing Codespace, preserve uncommitted changes and either invoke `python3 scripts/bootstrap_codespaces.py` after this branch is available, or explicitly rebuild the container to apply `.devcontainer/devcontainer.json`. A rebuild is not performed just by merging a PR. Rebuilding can reinstall binaries under `~/.local` and should be deliberate.

Run `python3 scripts/preview_godot_web.py` from the repository checkout. It removes stale generated Web files, imports the project, exports the `Web` preset, verifies that `index.html`, `*.js`, `*.wasm` and `*.pck` exist and are nonempty, and only then binds the HTTP preview to 0.0.0.0:8765. Use private Codespaces **Ports → Open in Browser** for Safari/iPad testing. Never share an empty directory listing as a successful preview. This workflow is not a public deployment or physical touch sign-off.

Evidence: offline fixture regression tests for bootstrap and preview guards were run outside Codespaces; actual new devcontainer rebuild, real Web export in Codespaces, Safari acceptance and audio/visual checks remain **NOT RUN** until observed.
