# FEAT-010 — Isolated Combat Lab

**Status:** Proposed detailed spec; parent objective approved 2026-11-12
**Owner:** Project owner · **Branch:** feature/combat-lab-polish-level2

## Purpose
Make tactical combat accessible directly for iteration on visuals, usability and future class/monster test fixtures, without playing the opening story.

## Human instructions
Review the sandbox entry mechanism, fixture scope, debug visibility and what constitutes a finished independent battle.

## AI agent instructions
Preserve the existing adventure and combat entry point; reuse authoritative CombatEngine and CombatBoard, not copied rules. Add tests before replacing any existing scene transitions.

## Specification
- **Goal:** A developer can launch a dedicated combat-only scene and repeatedly play deterministic encounters.
- **In scope:** Dedicated test launcher/scene, fixture selection from an explicit allowlist, deployment, play, victory/defeat, restart/new seed, entry feedback, no story/reward writes.
- **Excluded:** Campaign map, quest progression, persistence, level-two rules, automatic production main-scene changes and arbitrary file-path input.
- **Inputs:** Approved encounter ID/fixture, seed, standard pointer actions, formation, available spells/weapons.
- **Outputs:** Reusable combat event log, rendered board, outcome, reset, and optional lightweight developer diagnostics.
- **State invariant:** A sandbox run owns transient CombatEngine state. No saved game slots, campaign flags, money, XP, NPC attitudes or quest journal are mutated. Restart discards all transient combat, UI and VFX state.
- **Architecture:** Prefer a separate launcher and UI entry adapter. If the current scenes/combat_ui.gd mixes story and combat, split through the smallest testable seam rather than duplicating a thousand-line controller.
- **Regression:** The current adventure startup must still open the Old Trade Road story and continue into deployment.

## Acceptance and evidence
- **FEAT-010-AC01:** Developer-only launch opens a deployed-ready four-person combat fixture without stepping through narrative.
- **FEAT-010-AC02:** Battle initiative, actions, reactions, victory and defeat use the same authoritative engine as existing tests.
- **FEAT-010-AC03:** Reset twice yields the same actor/turn baseline with fixed seed; changing fixture changes only the chosen battle.
- **FEAT-010-AC04:** No permanent campaign saves or rewards are written; tests prove unchanged save/flag paths.
- **FEAT-010-AC05:** Existing opening story/combat/cave tests continue to pass.
- **FEAT-010-AC06:** Desktop input, restart, targeting and legibility manually checked; real touch/gamepad status explicitly recorded.
- **Automated checks:** Add focused tests/test_combat_lab.gd; run current Godot smoke suite.
- **Manual checks:** Full battle, loss/reset, repeat, no visual artifacts, no duplicate SFX or listeners.
- **Human sign-off:** Pending.
<!-- [EXAMPLE ONLY] A new detached combat scene is a design option; its exact class name is not preapproved. -->
