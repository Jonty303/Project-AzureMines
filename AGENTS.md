# Azure Mines Combat Lab — development instructions

This branch is intentionally **combat-only**. It inherits the Azure Mines game development template, but is not the narrative campaign. Do not reintroduce `adventure/`, story assets, quest controllers, campaign saves, named NPC registry or story data on this branch. Those belong on a separate narrative-development branch.

## Read first
1. `README.md`, `context/PROJECT_CONTEXT.md`, relevant `specifications/features/FEAT-*.md`
2. `architecture/ARCHITECTURE.md`, `architecture/DECISIONS.md`
3. `standards/ENGINEERING.md`, `standards/godot-4/GDSCRIPT.md`
4. `development/ENVIRONMENT_CONTRACT.md` and `workflows/DELIVERY.md`
5. `combat/combat_engine.gd`, `combat_lab/setup_builder.gd`, battle assets and tests

## Authority and approvals
Explicit owner decisions > approved feature specs/ADRs > applicable engineering standards > template guidelines > examples. Do not interpret a Draft or a hidden example as approved mechanics. Human owner approves gameplay rules, substantial architecture, dependencies, merges and final acceptance.

## Architecture
- `CombatSetup` is a validated value dictionary produced by the lab setup builder. It is the only permitted source of encounter level, party, enemy set, terrain and seed for a sandbox session.
- `CombatEngine` is authoritative for active combat actions/initiative/state. `CombatBoard` and `CombatLab` are presentation/input and debug tools; do not copy the combat rules into UI.
- `CombatResult` records post-battle facts (survivors, deaths, HP, events, rounds) and deliberately has **no rewards** in this sandbox.
- Use stable IDs, deterministic seeds and versioned manifests. Use test-only fixture overrides; do not edit the canonical immutable level-one fixture.
- Add class mechanics only with licensed, reviewed rules and deterministic tests. All implemented class spells should be testable through the lab, but unimplemented features must not be faked.
- Future NPC registry integration requires a separate reviewed adapter, not combat-to-story calls.
- Keep graphics, effects, sound and debug displays non-authoritative.

## Engineering discipline
Discover → Specify → Design → Approve → Implement → Validate → Review → Record; small fixes may be lighter. Preserve branch history. Do not force-push, merge, delete or upgrade the engine without approval. Verify GitHub branch/commit and tests before claiming success. Report exact changed paths, headless and manual PASS/FAIL/NOT RUN separately. No secrets or unapproved dependencies.

## Combat Lab-specific verification
Open title screen; confirm level selection, class variant, encounter selection, actual battle, restart and last saved log. Run existing engine regression tests and the dedicated Combat Lab tests. Desktop graphical usability, physical touch and gamepad are NOT RUN until separately tested.
