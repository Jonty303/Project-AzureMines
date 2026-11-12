# Azure Mines — project context

**Status:** Existing decisions documented; further scope requires owner approval
**Owner:** Project owner (human) · **Reviewed:** 2026-11-12

## Purpose
Preserve a concise, authoritative overview of game intent and current scope for humans and AI agents.

## Human instructions
Approve material changes to scope, gameplay, technology and player-facing content; distinguish future ideas from committed requirements.

## AI agent instructions
Interpret canon and implementation separately. Read the latest approved feature specification and the existing docs/world-bible.md before substantial changes.

## Game vision
- **Pitch:** Gold Box-inspired, party-based fantasy role-playing in Erith, beginning in the Dales. Tactical, turn-based combat supports authored narrative choices and consequential exploration.
- **Genre/audience:** Single-party tactical fantasy RPG, intended for players who enjoy tactical positioning, character abilities, branching decisions, and dangerous journeys.
- **Pillars:** Meaningful turn-based decisions; characters with fixed but distinctive progression; persistent narrative consequences; exploration/inventory choices grounded in the setting; transparent, testable rules.
- **Technology:** Godot 4.5.2 standard GDScript. Three layers: reusable game engine, interchangeable ruleset, authored adventures.
- **Initial party:** Four characters; five fixed-progression classes (Champion, Priest, Thief, Evoker, Hunter); Human, Dwarf, Elf and Halfling; initial progression target levels 1–5; Bard/Lore later.
- **Exploration:** Authored choice-driven location graph and discovery map, NOT a first-person movement grid. World Bible is author-only.

## Current verified repository reality
- main: project bootstrap, core module loader, documentation and consolidated world bible.
- feature/downed-sprites-action-bar: most developed playable opening, tactical combat, persistent exploration, goblin cave v0.9.1 and extensive tests.
- feature/adventure-design-tools: separate browser-based overland and dungeon designers; authoring exports are not runtime packages.
- Do not equate a historical passing headless CI run with current manual playtest acceptance.

## Immediate next objective
Isolate the already implemented tactical experience as a repeatable combat sandbox. Polish sprite readability, action bar, hit feedback and restrained original melee/spell VFX. After stabilising the sandbox, specify character-level-two class features/spell resource changes and a small roster of distinct opponents; keep combat correctness separate from presentation.

## In scope for next slice
A combat-only entry path, representative repeatable fixtures, event-driven feedback, VFX acceptance and regression tests. See the next-cycle feature spec on the combat development branch.

## Explicitly deferred
Campaign rewrite, story progression, new dungeon politics, level-3 spells, asset pipeline overhaul, new character creation system, large universal editor, new engine/framework dependencies, and merges into main without approval.

## Open decisions
Target input/platform support (keyboard/mouse baseline; physical touch/gamepad requirements need confirmation), visual style/art sign-off, exact level-two feature choices, additional monster roster and progression balance.
<!-- [EXAMPLE ONLY — NOT AN APPROVED REQUIREMENT] An arcade shooter example from the upstream template is irrelevant to this project. -->
