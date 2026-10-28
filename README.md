# Project Azure Mines

A modular, Gold Box-inspired tactical fantasy RPG built with **Godot 4.5.2**.

> Status: project bootstrap. This repository provides a runnable project shell and a validated sample adventure loader, **not yet a playable combat system**.

## Getting started

1. Clone this repository.
2. Import `project.godot` into Godot **4.5.2**.
3. Run the project (F6/F5 depending on editor context). The main scene displays the sample adventure and its ruleset.
4. To run the loader smoke test from a terminal with Godot installed:
   ```sh
   godot --headless --path . --script res://tests/test_module_loader.gd
   ```

The launch screen also has a demonstration d20 roller. It is an example of an isolated rules utility, **not** the combat implementation.

## Game design (current decisions)

- **Five fixed-progression classes:** Champion (Fighter + Champion), Priest (Cleric + Life Domain), Thief (Rogue + Thief), Evoker (Wizard + Evoker), Hunter (Ranger + Hunter).
- **Four races:** Human, Dwarf, Elf (initially High Elf lineage), Halfling.
- **Level target:** 1–5, four-character party initially; design for future growth.
- No backgrounds, multiclassing, general feat selection or selectable subclasses in the first build.
- **Classic 5E:** an explicitly adapted rules package inspired by SRD 5.2.1, distinct from the official rules.
- A distinct engine layer, a ruleset layer and interchangeable adventure packages.
- **Bard + College of Lore** is the first additional class on the roadmap, after the core RPG systems.

See [architecture](docs/architecture.md), [character rules](docs/ruleset-design.md), [combat rules](docs/combat-rules.md), [data formats](docs/data-contracts.md) and [roadmap](docs/roadmap.md).

## Repository layout

```text
core/          Game-agnostic services (loading, dice, eventually events/state)
combat/        Future tactical rules and presentation
characters/    Future character construction and progression
exploration/   Future exploration / role-playing systems
rulesets/      Replaceable rules packages and definitions
adventures/    Content packages: maps, locations, encounters, quests
scenes/        Godot presentation and entry scenes
tests/         Headless test scripts
docs/          Architecture and design decisions
```

## Licensing and content

The repository's original code and project documentation do **not** currently have a general public licence selected. See [licensing](docs/licensing.md). SRD 5.2.1 is available under CC BY 4.0, but its licence does not automatically license unrelated project code or third-party adventures. The starter adventure here is original placeholder content. No Forgotten Realms or Lost Mine of Phandelver adventure text or maps are included.
