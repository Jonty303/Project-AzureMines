# Azure Mines — specification index

## Purpose
Use small, verifiable feature contracts while retaining the original docs/ and campaign bible. A specification is not accepted simply because it exists.

## Hierarchy
- context/PROJECT_CONTEXT.md: product scope.
- docs/world-bible.md: author-only world canon; do not leak spoilers.
- architecture/: decisions and module boundaries.
- specifications/foundation/: stable combat/input/state contracts.
- specifications/features/: bounded new changes and acceptance tests.

## Workflow
Draft -> owner review/approval -> implementation -> automated/manual evidence -> owner acceptance -> approved merge. Small fixes can use a concise PR description and test evidence rather than an elaborate document. Proposed content must not silently become canon or implemented rules.

## Current feature planning
The combat isolation/polish plan is prepared for the dedicated combat development branch. Further class-level-two mechanics and monster roster will be separately specified before implementation.
