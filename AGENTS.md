# Azure Mines — agent and human development contract

## Entry point
Project Azure Mines is a Godot 4.5.2, party-based tactical fantasy RPG with authored narrative exploration. This document adapts the Game Development Template to an **existing** project; the template is not a replacement game design.

Before substantial work, read:
1. context/PROJECT_CONTEXT.md and the task's approved feature specification.
2. docs/world-bible.md (author-only canon) and the relevant existing docs/ design or combat contracts.
3. architecture/ARCHITECTURE.md and architecture/DECISIONS.md.
4. standards/ENGINEERING.md, standards/godot-4/GDSCRIPT.md, workflows/DELIVERY.md, and development/ENVIRONMENT_CONTRACT.md.
5. The actual current branch, game code, fixtures and tests.

## Authority and scope
Current explicit owner decision > approved project specification and recorded canon > accepted architecture decisions > applicable engineering standards > reusable template guidance > illustrative examples.

- **Do not** promote a proposed story event, hidden example, author-only note, or unmerged prototype into approved gameplay.
- Maintain the three boundaries: game engine/presentation, ruleset, authored adventure. Preserve the narrative choice-based exploration decision.
- Keep author-only revelations out of player-facing map, log, UI, export and data disclosures.
- Verify repository, branch, file state, task authority and dependency impact before editing. Preserve outstanding branches and PRs.
- Prefer the smallest testable vertical slice; define observable acceptance criteria. For small fixes, keep process proportional to risk.
- Code changes require regression tests and exact evidence. Report PASS, FAIL, NOT RUN and limitations separately; headless tests are **not** desktop visual, real touch or gamepad tests.
- Do not claim approval, test execution, installed tools, runtime readiness or merge completion without evidence.
- Do not force-push, merge, delete branches, silently upgrade engine, add external dependencies, change secrets or initiate paid cloud resources without owner approval.

## Current integration state
The default main branch is a bootstrap plus canonical docs. The more complete tactical combat, narrative campaign and cave are on feature/downed-sprites-action-bar. The distinct browser-based adventure and dungeon editors are on feature/adventure-design-tools. Four staged combat PRs remain open. Do not assume any is merged.

## Project-specific delivery
Use specification IDs FEAT-* and AC* for substantial playable changes. Keep deterministic combat simulation and explicit command/event boundaries independent of presentation. Do not invent new class rules, enemies or plot revelations while implementing graphics effects. Preserve the Godot 4.5.2 standard (non-.NET) baseline and license provenance.

Use development/VALIDATION_MATRIX.md to record commands, results, date, branch, platform and manual gaps. The project has an existing headless Godot CI suite; do not replace it with template-only documentation validation.

## Combat polish cycle
The combat-only development work must remain additive and isolated: reusable combat sandbox/launcher, non-authoritative VFX, UI clarity and visual verification first; character-level-two rules and new monster definitions only under separately approved specifications. A character at level 2 does **not** automatically gain level-2 spell slots.

## Review and merge
Agents may propose or implement scoped work on a development branch, but the owner approves feature acceptance and merges. Provide changed paths, behaviour, test commands/results, screenshots/manual tests when available, and outstanding decisions.
