# Project Azure Mines

A modular, Gold Box-inspired tactical RPG built with **Godot 4.5.2**, using a custom **Classic 5E** rules package based on SRD 5.2.1.

## Play the level-1 combat prototype

1. Clone this repository and import `project.godot` into Godot 4.5.2.
2. Press **F5** to load the tutorial arena.
3. Play the four fixed test characters: **Alden, Elyra, Brunna and Pip**, against two goblins.
4. Click a highlighted tile to move. Select **Weapon Attack** or a spell and click its target. Use **Cast on Self** for Elyra's Mage Armor, **Second Wind** for Alden, and **End Turn** to advance initiative.
5. Use **Restart** to reset the deterministic encounter.

The 12×10 grid includes five-foot squares, difficult terrain and walls. The static **64×64 front-facing sprites** include all four heroes and a knife-wielding goblin.

## What is implemented

- Individual initiative and turn order; simple goblin AI.
- Movement, melee/ranged attack resolution, damage, critical hits, HP and victory/defeat.
- Alden: Second Wind and Sap mastery.
- Pip: conditional Sneak Attack, Halfling Luck and Vex mastery.
- Elyra: Fire Bolt, Ray of Frost (damage only), Magic Missile and Mage Armor.
- Brunna: Sacred Flame, Cure Wounds and Healing Word.
- Action/Bonus Action and first-level spell-slot tracking.

These mechanics are **only a subset** of what level-1 SRD characters can do. Reaction spells, many prepared spells, concentration, death saves, numerous racial abilities and advanced tactical rules are deliberately deferred.

See [Combat v0.2 specification](docs/level1-combat-v02.md) for explicit coverage, limitations and test commands.

## Project structure and decisions

- Five fixed classes: Champion, Priest, Thief, Evoker, Hunter. Hunter will join later test encounters.
- Four races: Human, Dwarf, Elf (High Elf initially), Halfling.
- Level 1–5 planned, but this vertical slice is **level 1 only**.
- No backgrounds, multiclassing or selectable subclasses.
- Rules engine, adventure content and Godot UI are distinct layers.
- Character statistics live in the immutable fixture `tests/fixtures/party/level_01_v1.json`.

See [architecture](docs/architecture.md), [combat rules](docs/combat-rules.md), [test party](docs/canonical-test-party.md), [data contracts](docs/data-contracts.md), [roadmap](docs/roadmap.md) and [licensing](docs/licensing.md).

## Automated validation

GitHub Actions imports the Godot 4.5.2 project, launches the combat scene, verifies PNG imports and executes headless tests. Run the complete set via the commands in `.github/workflows/godot-smoke.yml`.

This is a **prototype**, not a finished or fully rules-accurate RPG. The repository uses Git attributes that disable line-ending conversion.
