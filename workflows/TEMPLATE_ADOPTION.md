# Adoption of Game Development Template — Azure Mines

**Date:** 2026-11-12 · **Status:** Implemented on feature/development-governance, pending owner acceptance/merge.

## Purpose
Record what was integrated and why, without replacing the existing playable branch.

## Included
- AGENTS.md: project-specific agent contract and precedence.
- context/: approved game intent, current feature branches, immediate combat polish target.
- architecture/: retained engine/ruleset/adventure architecture, existing decisions and proposed ADRs.
- specifications/: foundations, feature spec template and per-slice acceptance workflow.
- standards/, agents/, workflows/: engineering policies, roles, reviews and decision rights.
- development/: pinned Godot toolchain, setup, Codespaces gate, validation matrix.
- scripts/: upstream template document/toolchain checks, self-test, optional verified Godot importer and local validator.
- .github/workflows/project-governance.yml: CI for documentation/toolchain checks; existing Godot smoke workflow retained with SHA-256 integrity step.
- .devcontainer/: Python/documentation baseline, explicitly **not** a provisioned Codespace or installed Godot.

## Explicitly excluded
- Starting a new repository from the template.
- Copying the template's sample shooter or creating unapproved gameplay.
- Replacing the existing Godot tests, game architecture or author-only world bible.
- Assuming a live Codespace, physical input tests, or deployment.
- Merging the older feature PRs #1–#4, their target branches, or this governance branch.

## Integration path
Parent at adoption: feature/downed-sprites-action-bar commit 4d8300af3e25b63a5c34fb37c02ec19562815a30. The authoring tools branch remains separate. The subsequent combat development branch will be based on this governance work, without creating a second combat rules engine.

## Verification
Run governance and Godot Actions jobs, review output and report limitations. The Godot workflow's tested runtime provides stronger evidence than the documentation validator; the two checks serve different roles.
