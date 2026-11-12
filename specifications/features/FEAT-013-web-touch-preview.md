# FEAT-013 — Web preview, touchscreen and keyboard testability

**Status:** Implemented/tested by CI; physical acceptance pending, Pages activation blocked in GitHub settings.
**Branch:** feature/combat-lab-web-touch · **Reviewed:** 2026-11-12

## Purpose
Allow direct, browser-based Combat Lab testing on iPad Safari without needing to run the graphical editor in Codespaces.

## Human instructions
Enable GitHub Pages (Source: GitHub Actions) and approve feature-branch deployment in the github-pages environment if required. Carry out actual iPad playtest and record any gesture/layout failures before acceptance.

## AI agent instructions
Keep Web export deterministic and single-threaded. Retain mouse and keyboard support. Use verified official Godot editor/templates with SHA256 integrity checks, and never claim physical touch PASS from simulated test events.

## Scope
- Adapt CombatBoard to handle `InputEventScreenTouch` and ignore duplicate synthetic mouse activation.
- Provide board keyboard focus and arrow/Enter selection.
- Rescale battlefield and wrap menu/action controls on tablet; expose a popup battle log when the right-hand panel is hidden.
- Godot 4.5.2 Web preset, explicit `variant/thread_support=false` and Compatibility renderer.
- GitHub Actions verifies full official export archive, imports, runs tests, generates HTML/JS/WASM/PCK and uploads a downloadable build.
- Publish to GitHub Pages when the owner enables it. Codespaces forwarded-port testing is a supported fallback.

## Exclusions
New spell mechanics, new monster AI, changes to narrative systems, packaged native apps, full gamepad mapping, PWA offline support and claims of iPad compatibility before a real test.

## Acceptance criteria
- **FEAT-013-AC01:** Existing game combat rules and UI smoke regressions pass — **PASS, GitHub Actions**.
- **FEAT-013-AC02:** Synthetic touch activates the correct tile once; mouse and keyboard remain usable — **PASS, Godot headless tests**.
- **FEAT-013-AC03:** Compact viewport changes board scale and hides sidebar, still offers event log — **PASS for responsive state; visual review pending**.
- **FEAT-013-AC04:** Release web export generates nonempty index.html, WASM, JS and PCK — **PASS, GitHub Actions**.
- **FEAT-013-AC05:** Public GitHub Pages loads, displays graphics and responds to touch — **BLOCKED: Pages settings; physical Safari test NOT RUN**.
- **FEAT-013-AC06:** Landscape/portrait, dialogs, deployment, movement, spells, reactions and final log pass a real iPad test — **NOT RUN**.
- **FEAT-013-AC07:** No narrative/quest/campaign code introduced on this branch — **PASS by repository file inspection**.

## Evidence
https://github.com/Jonty303/Project-AzureMines/actions/runs/43226257801
https://github.com/Jonty303/Project-AzureMines/actions/runs/43226257758

## Future engine work
After real-device acceptance, resume FEAT-009 event/result hardening and FEAT-011 visual/audio effects without changing simulation rules.
<!-- [EXAMPLE ONLY] Browser mouse emulation does not certify physical touch. -->
