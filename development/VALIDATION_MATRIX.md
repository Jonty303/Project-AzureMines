# Azure Mines — validation matrix

**Status:** Baseline evidence and outstanding verification; updated 2026-11-12

## Purpose
Track actual executed tests and environment readiness independently; avoid claiming that documentation checks prove playable graphics.

## Human instructions
Record manual visual/audio, balancing and physical-device observations with environment, build, date, tester and screenshots or video when available.

## AI agent instructions
Only mark PASS after actual execution with evidence. Keep NOT RUN and NOT VERIFIED distinct from FAIL. Note when historical evidence predates this branch.

## Historical CI baseline
| Surface | Result | Evidence |
| --- | --- | --- |
| Godot 4.5.2 headless suite on feature/downed-sprites-action-bar | PASS **historically**, 2026-10-29 | https://github.com/Jonty303/Project-AzureMines/actions/runs/40862763511 |
| Governance docs validation on feature/development-governance | **PASS 2026-11-12** | https://github.com/Jonty303/Project-AzureMines/actions/runs/43209745016 |
| Godot 4.5.2 headless suite with SHA-256 integrity gate on feature/development-governance | **PASS 2026-11-12** | https://github.com/Jonty303/Project-AzureMines/actions/runs/43209744933 |
| Godot release archive digest | Recorded from official GitHub release 4.5.2-stable asset metadata | SHA-256 in development/toolchain.json |
| Combat sandbox isolation | NOT IMPLEMENTED / NOT RUN | To be specified on next branch |
| Desktop art/layout/animation inspection | NOT RUN for next cycle | Human review needed |
| Physical touchscreen | NOT RUN | Target/device not yet approved |
| Physical gamepad | NOT RUN | Target/device not yet approved |
| Keyboard-only navigation | NOT RUN | Input mapping to be specified |
| Desktop export and installed build launch | NOT RUN | Platform target remains open |
| Codespaces inventory, instance and Godot readiness | NOT VERIFIED | GitHub Code → Codespaces or authenticated CLI needed |

## Record template for future results
Date, repository/branch/commit, platform/OS, exact Godot version, test command, expected behavior, observed PASS/FAIL/NOT RUN/NOT APPLICABLE, artifact/link, reviewer. Record each input device separately; mouse emulation is not actual touch verification.

## Codespaces precondition
A devcontainer configuration exists only as Git-tracked source; it cannot prove an instance exists. Do not begin Codespaces-dependent install claims until inventory, branch and terminal readiness are verified and any paid resource action is approved.
<!-- [EXAMPLE ONLY] Fake example test results must never be recorded as PASS. -->
