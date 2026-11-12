# SPEC-002 — Input-to-action contract

**Status:** Existing mouse UI recorded; broader device support not yet approved/tested

## Purpose
Separate hardware events, selected actions and validated game commands.

## Human instructions
Approve keyboard, pointer, touchscreen and gamepad targets for the selected export platforms. Review usability on real devices.

## AI agent instructions
Never equate headless input injection or pointer emulation with physical touch testing. Keep actions independent from device adapters.

## Current evidence
- Gameplay UI uses clickable Godot controls, board-cell interactions, deployment selection and contextual action bar.
- The keyboard navigation scheme, physical touchscreen implementation and gamepad scheme have NOT been verified for this branch.
- Current engine logic validates movement, targets, action economy and reactions independently of the UI.

## Next-cycle mapping to approve
- Pointer: select Move/Attack/Spell/End Turn, click board cell/target; choose weapon/spell from dropdown.
- Keyboard: propose keyboard/focus navigation for action buttons, target cells, confirm/cancel, reaction and restart; not implemented by this document.
- Touchscreen: design hit areas, orientation, selection and secondary actions for a supported target; physical verification required, or approve a deferred/NA exception.
- Gamepad: assess suitability and approve mapping/deadzone/focus tests or a documented exception.

## Acceptance
- Disabled actions remain disabled across all supported adapters.
- Input does not bypass CombatEngine command validation; reaction choices cannot fire twice.
- Report input evidence separately for mouse, keyboard, real touch and physical gamepad, including NOT RUN.
<!-- [EXAMPLE ONLY] A speculative shooter movement/fire input scheme is not an Azure Mines requirement. -->
