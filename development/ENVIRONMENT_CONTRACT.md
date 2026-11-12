# Azure Mines — reproducible development environment contract

**Status:** Godot version and official release digest pinned; cloud and manual environments not universally verified.
**Adopted:** 2026-11-12

## Purpose
Define exactly what may be called a verified development/test environment, following the Game Development Template.

## Human instructions
Review supported desktop OS and physical-device targets, approve any cloud resource/costs, and provide manual graphical input/render checks. Do not infer a live Codespace from a committed configuration.

## AI agent instructions
Inspect current repository, branch, existing installed binaries and tools. Do not silently install/upgrade dependencies. Distinguish source validation from actual Godot execution and physical playtesting.

## Pinned toolchain
- Engine: Godot **4.5.2 standard, GDScript**, non-.NET.
- Project root: repository root (project.godot).
- Linux release archive: official Godot 4.5.2 stable linux x86_64 zip as recorded in development/toolchain.json.
- SHA-256: 87f6e6be292929e363d15ed9052f277b2ba4e95ed994e1e099048097be2dfd03; confirmed from official GitHub release asset digest at adoption.
- Runtime CI: existing .github/workflows/godot-smoke.yml downloads archive, checks SHA-256, imports/launches headlessly and runs dedicated game tests.
- Contract CI: .github/workflows/project-governance.yml checks documentation, toolchain schema and negative-path self-tests. A green contract run is **not** a game test.

## Validation stages
| Stage | Evidence |
| --- | --- |
| Source structure | python3 scripts/validate_template.py --project |
| Toolchain manifest | python3 scripts/validate_toolchain.py |
| Negative contract tests | python3 scripts/self_test.py |
| Godot import | GODOT_BIN=/absolute/path/to/godot bash scripts/validate_godot.sh |
| Optional download + import verification | python3 scripts/verify_engine.py (downloads official pinned Linux binary after SHA check) |
| Gameplay tests | Individual Godot --headless --path . --script res://tests/... commands as recorded in CI |
| Desktop visual/audio and controls | Human/manual test evidence, not certified by headless jobs |
| Export | Target platform export and launch evidence; presently NOT RUN |

## Codespaces gate
When Codespaces is the approved development environment, check GitHub Code → Codespaces (or authenticated `gh codespace list --repo Jonty303/Project-AzureMines --json name,state`) before assuming an environment exists. Presence of .devcontainer proves configuration **only**. If there is no accessible inventory, record **NOT VERIFIED**, not 'none'. Do not create, resume with changes, rebuild or incur paid use without owner approval. If a devcontainer change is later pulled, warn that a rebuild may be needed; confirm uncommitted work and user-installed tools before rebuilding.

The supplied baseline devcontainer is documentation/Python-only and does **not** install Godot. This is deliberate: successful creation or postCreate validation does not validate the game engine. Godot setup can be added after the Codespace and approved provisioning workflow have been verified.

## Rule
Headless PASS ≠ visual/gamepad/touch PASS. Missing engine bin is NOT RUN, not success. Unverified archives are blocked, not silently accepted.
<!-- [EXAMPLE ONLY — NOT APPROVED] An illustrative GPU-enabled container is not actually provisioned. -->
