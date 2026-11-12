# Godot 4 GDScript profile — Azure Mines

**Status:** Applicable conventions, 2026-11-12

## Purpose
Provide engine-specific coding guidance without replacing Azure Mines' current style by fiat.

## Human instructions
Approve engine patch upgrades, addons and strict-warning changes after a passing baseline.

## AI agent instructions
- Target Godot 4.5.2 standard (non-Mono); use modern @ annotations and typed parameters/returns/properties for newly touched code when clear.
- Prefer signal-up/call-down as a heuristic; avoid hardwired dependencies between combat resolution and UI art.
- Keep authoring data declarative and validated; avoid eval or dynamic script execution.
- Keep command outcomes and combat state independent of Tween/AnimationPlayer timing.
- Avoid per-frame allocation spikes; do not create persistent duplicate effects listeners during replay/reset.
- Run headless parse/import, focused tests and existing regression suite; disclose visual checks as NOT RUN unless performed.

## Review
Style changes should be incremental, not an unrelated refactor. Test combat values before and after VFX changes.
<!-- [EXAMPLE ONLY] A new exported property is not a substitute for reviewing its effect on gameplay. -->
