# Azure Mines — specification-driven delivery

**Status:** Project-specific adoption of Game Development Template workflow

## Purpose
Move from a bounded design decision to reviewed, testable game changes without turning small fixes into paperwork.

## Human instructions
Approve the slice and any changed rules, scope, material architecture or merge. Accept visual/physical-device checks only with evidence or explicit deferral.

## AI agent instructions
Discover -> Specify -> Design -> Approve -> Implement -> Validate -> Review -> Record.

1. Inspect current branch, repository state, canon, existing code, dependencies and tests.
2. For substantial work, define feature ID, player-visible behaviour, exclusions and acceptance criteria; distinguish proposed from approved.
3. Compare architectural alternatives only as needed; document major changes in architecture/DECISIONS.md.
4. Implement a small testable vertical slice with rollback and deterministic fixtures.
5. Execute applicable checks; report exact commands, outcomes, environment and NOT RUN items.
6. Request human verification for graphics, feedback/readability, physical touch/gamepad and balance.
7. Present branch/commit/changed paths/tests/issues. Do not merge without explicit approval.

## Required evidence
PASS needs actual execution. Do not relabel skipped tests as success. A green doc-contract workflow does not prove Godot gameplay, and a headless Godot workflow does not prove visual polish.

## Input gate
Each interactive slice must state keyboard/pointer, touch and gamepad coverage or an approved exception. Testing a mouse click is not physical touch testing.
<!-- [EXAMPLE ONLY] A PR ready for review does not imply that it is already accepted or merged. -->
