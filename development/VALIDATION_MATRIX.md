# Combat Lab — validation matrix

**Updated:** 2026-11-12 · **Scope:** feature/standalone-combat-lab

## Purpose
Distinguish automated runs from actual visual/device testing.

## Human instructions
Verify title, setup dialog, board, input latency and readability on a desktop Godot 4.5.2 session. Record actual tester/date/platform and provide captured evidence if possible.

## AI agent instructions
Never represent simulated/headless input as physical touch/gamepad evidence. Mark absent tests NOT RUN. Update the CI links after commit results.

| Check | Status | Evidence |
| --- | --- | --- |
| Godot 4.5.2 title-screen import/start and combat regression suite | PASS, 2026-11-12 | https://github.com/Jonty303/Project-AzureMines/actions/runs/43217179001 |
| Project governance documentation/toolchain checks | PASS, 2026-11-12 | https://github.com/Jonty303/Project-AzureMines/actions/runs/43217179423 |
| Lab level/party/encounter construction tests | PASS within Godot suite | Same Godot Actions run |
| Lab result export and last battle log test | PASS within Godot suite | Same Godot Actions run |
| Desktop graphical/animation/layout test | NOT RUN | Manual owner review required |
| Keyboard-only navigation | NOT RUN | Manual check required |
| Physical touchscreen | NOT RUN | Target platform/access not yet confirmed |
| Physical gamepad | NOT RUN | Controller suitability/access not yet confirmed |
| Export and packaged build | NOT RUN | Only headless game import/start verified |
| Codespaces instance and readiness | NOT VERIFIED | A committed devcontainer is not an existing Codespace |

## Codespaces
When Codespaces is chosen as a runtime, verify actual Codespaces inventory, branch, worktree status, terminal readiness and engine install before claiming acceptance. Do not create or rebuild a billable environment without owner approval.
<!-- [EXAMPLE ONLY] A fake playtest record is not evidence. -->

## Web preview slice — 2026-11-12

| Check | Result | Evidence |
| --- | --- | --- |
| Standalone Godot regression + touch/keyboard injection | PASS (automated) | https://github.com/Jonty303/Project-AzureMines/actions/runs/43226257801 |
| Official Godot 4.5.2 HTML5 single-thread export | PASS; downloaded artifact exists | https://github.com/Jonty303/Project-AzureMines/actions/runs/43226257758 |
| GitHub Pages deployment | BLOCKED: Pages returned 404 (not enabled) | Same workflow deploy job; enable Settings → Pages → GitHub Actions |
| Real iPad Safari tapping/rotation | NOT RUN | Requires actual device test |
| Real keyboard navigation | NOT RUN | Automated synthetic test passed only |
| Safari local storage and audio | NOT RUN | Requires actual browser check |

