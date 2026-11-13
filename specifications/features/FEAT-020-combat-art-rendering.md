# FEAT-020 — Combat Lab v0.5.4 art and rendering

**Scope authority:** Owner request and GitHub Issue #32, 13 November 2026; approved visual direction v1. Implementation is delivered for draft review; human visual/device acceptance is pending. Extends FEAT-011 presentation and preserves FEAT-016 impact staging.

**Branch:** `feature/combat-lab-v054-art-pass`; PR base `feature/combat-lab-v0532-combat-clarity`.

## Player-visible behavior

The same combat outcomes render with original stone/moss terrain, recognizable props, monster locomotion/combat states and distinct implemented spell effects. Ground-contact depth and faded occluders keep actors legible behind multi-cell scenery. Tactical outlines and status/damage labels remain above smoke and transient effects. Existing input, camera, resource costs and rule timing remain authoritative and unchanged.

## Exclusions

No party sprite animations or modular appearance system, new rules/spells/enemies, canonical party fixture edits, UI redesign, engine upgrade, deployment or merging. Bugbear is an asset delivery without a new stat block; ranged art is limited to actual goblin/kobold loadouts.

## Acceptance and evidence

| ID | Contract | Evidence |
| --- | --- | --- |
| AC01 | Separate original alpha atlases, dimensions, pivots, frames, provenance and seamless floor edges | `assets/combat_v054/manifest.json`, original authoring source, Python pixel validation and Godot native-resource checks |
| AC02 | Stable ground-Y / X / kind / ID order, exact prop source pivots, full footprints and faded occlusion | `tests/test_v054_art_rendering.gd`; visual QA scene and capture |
| AC03 | Web below feet; projectiles/impacts above scenery; tactical/status/labels above decorative VFX | Explicit board pass functions, render contract, native regression and browser capture |
| AC04 | Projectiles hit before defeated state; no rule/RNG mutation from rendering; reset clears cosmetic state | Existing movement/impact tests and new rendering contract |
| AC05 | Existing mechanics, controls/camera, party fixtures and all regression assertions preserved | 37 Godot scripts; protected paths unchanged |
| AC06 | Pinned Godot import, nonempty Web export and real browser launch | Recorded validation and non-publishing CI export job |
| AC07 | Physical iPad portrait/landscape, touch, occlusion, animation clarity and performance accepted | NOT RUN; owner checklist in validation report |

Design: [render contract](../../docs/combat-lab-v054-render-contract.md). Results, screenshots, placeholders and device requirements: [validation](../../docs/combat-lab-v054-validation.md). Headless and browser smoke are not human visual acceptance.
