# Engineering standards — Azure Mines

**Status:** Existing project baseline; newly proposed standards require review

## Purpose
Keep combat correctness, maintainability, source control and test evidence consistent.

## Human instructions
Approve platform targets, input-device exceptions, engine upgrades, asset sources, licensing and substantial dependencies.

## AI agent instructions
Prefer typed GDScript, explicit state ownership, deterministic tests and small PRs. Report exact tested and untested surfaces.

## Baseline
- **Runtime:** Godot 4.5.2 standard/GDScript, Godot project at repository root.
- **Architecture:** Headless-testable combat engine, separate Godot presentation, authored JSON adventure/ruleset contracts.
- **Dependency policy:** No new addon, framework, runtime downloader or build dependency without approval.
- **Testing:** Existing Godot smoke tests must remain intact; new features get focused headless regressions plus manual playtest instructions.
- **Assets:** Use original or documented licensed art/audio; review third-party asset provenance; preserve existing attribution.
- **Safety:** No secrets in code/logs, no runtime execution from authored JSON, no undisclosed story spoilers.
- **Git:** Feature branches/PRs, no unapproved merges, force-pushes or deletion; maintain reproducible fixtures.
- **VFX:** Non-authoritative, triggered by resolved events, bounded duration, no silent rule-side delays.

## Input support
Keyboard and touchscreen are the upstream template's default planning baseline wherever feasible; gamepad is first-class for suitable games. Azure Mines' actual target devices and any exceptions require owner review. Current pointer-driven UI is not evidence of physical touch or controller support. Record distinct PASS/FAIL/NOT RUN/NOT APPLICABLE with device/OS/build/tester evidence.

## Quality gate
Headless parse/import and rule tests are necessary, not sufficient: additionally assess board legibility, targeting cues, effects visibility and responsiveness on an actual desktop.
<!-- [EXAMPLE ONLY] Project performance and device budgets must come from measured needs, not a sample shooter. -->
