# Azure Mines — architecture decision records

## Purpose
Keep material architectural choices and their reconsideration triggers explicit. Existing entries describe established project direction; new entries require owner review.

## Human instructions
Review consequences of changes to engine, ruleset contracts, persistence, authoring integration and developer tooling.

## AI agent instructions
Draft a Proposed ADR before material changes. Never mark an unreviewed change Accepted. Preserve rationale and tests.

## Recorded existing decisions
### ADR-AM-001 — Godot 4.5.2 standard + GDScript
**Status:** Existing project decision (documented 2026-11-12)
**Reason:** The existing application, headless tests and toolchain are built around Godot 4.5.2. Avoid silent version changes.
**Revisit:** Compatibility/security concerns or demonstrated platform requirements.

### ADR-AM-002 — Engine / ruleset / adventure separation
**Status:** Existing project decision
**Reason:** Test combat rules independently and keep authored adventure content data-driven. Do not execute scripts from JSON.
**Revisit:** Proven runtime limitations or versioned contract design.

### ADR-AM-003 — Choice-based narrative exploration
**Status:** Existing project decision
**Reason:** Persistent authored location graph and story choices supersede the initial proposal for first-person corridor exploration.
**Revisit:** Explicit new owner decision.

### ADR-AM-004 — Deterministic combat events for visual feedback
**Status:** Proposed for combat polish
**Proposal:** Consume existing resolved combat events in a visual/audio-only effects layer, without introducing new rules-side timing.
**Alternatives:** Inject presentation into combat resolution (tighter coupling) vs separate event consumer (preferred). 
**Validation:** Headless invariance tests plus manual side-by-side playtests; owner acceptance required.

### ADR-AM-005 — Separate combat sandbox launch
**Status:** Proposed for next cycle
**Proposal:** Provide a non-campaign standalone entry fixture using existing CombatEngine and CombatBoard, not a fork of combat algorithms.
**Revisit:** After a working launcher and tests.


### ADR-AM-006 — Isolated Combat Lab branch
**Status:** Implemented prototype, pending owner acceptance (2026-11-12).
**Decision:** Run a standalone title/configuration/CombatEngine session with a version-one setup/result dictionary and saved debug report. Do not call narrative, quests, NPC registry or campaign state in this branch.
**Consequences:** Existing narrative modules remain in their original branches; later integration must use a reviewed external adapter. See FEAT-009.

### ADR-AM-007 — iPad-first battlefield interaction and touch command surfaces
**Status:** Owner-agreed provisional presentation direction (2026-11-12); implementation pending.
**Decision:** Use a wider, pannable/zoomable tactical board; retain an informational right sidebar; place character commands in the bottom icon+label deck with large right-aligned End Turn; use direct weapon cards and a horizontal swipeable spell strip; animate ranged/spell projectiles from resolved event data.
**Consequences:** UI needs a shared camera input/coordinate transform, gesture arbitration, portable artwork and additive visual events. Existing CombatEngine remains rules authority. Maintain keyboard/mouse alternatives.
**Scope:** Presentation only. The generated reference's class labels, MP and damage/hit percentages are noncanonical illustrative content.
**Detail:** docs/combat-lab-ipad-art-direction-v02.md and FEAT-015.

### ADR-AM-009 — Downed initiative and presentation-only impact staging
**Status:** Owner-agreed, implemented in Combat Lab on 2026-11-12; physical iPad acceptance pending.
**Decision:** An unconscious hero resolves an automatic death save at initiative but never receives an input turn or End Turn command. Stable, dead and knocked-out creatures are skipped. Natural-20 recovery restores a playable turn. Ordinary AI does not deliberately select downed foes unless an explicit future policy enables it. Smooth per-tile actor motion and delayed fatal projectile collapse are presentation queues sourced from resolved events and snapshots; the combat engine never waits for VFX.
**Consequences:** Maintain reproducible death-save sequencing, do not duplicate rules state in the board, and keep visual/audio state cancellable on retry. See FEAT-016.

### ADR-AM-010 — Persistent combat regions
**Status:** Proposed implementation for owner review under issue #18.
**Proposal:** Add versioned transient region instances and source-owned conditions to CombatEngine, using existing movement/reaction/initiative paths. Keep Bless's public concentration contract compatible. Board reads active-region and condition snapshots; presentation never advances lifecycle. See docs/combat-lab-v052-persistent-effects.md for timing, exclusions and validation.
**Alternative:** Scene-owned or Web-specific state duplicates rules and cannot provide deterministic replay.
