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
