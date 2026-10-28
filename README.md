# Project Azure Mines

A modular, Gold Box-inspired tactical fantasy RPG using **Godot 4.5.2** and a streamlined house-ruled version of **SRD 5.2.1**.

> **Development status:** First playable combat prototype on a feature branch. The game is a work in progress and not yet a complete implementation of Classic 5E.

## Run the prototype

1. Clone this repository and open `project.godot` in **Godot 4.5.2**.
2. Press **F5** to open the 12 × 10 tutorial battlefield.
3. Play as the four predefined characters: **Alden (Champion), Elyra (Evoker), Brunna (Priest), Pip (Thief)**.
4. On a player turn, click a highlighted free tile to move or click an enemy to attack. Use **End Turn** to advance the initiative queue and let the two goblins respond.
5. Use **Restart Battle** to repeat the seeded reference encounter.

The separate original module-loader preview remains at `scenes/main.tscn`.

### Headless tests

```sh
godot --headless --path . --script res://tests/test_module_loader.gd
godot --headless --path . --script res://tests/test_canonical_party.gd
godot --headless --path . --script res://tests/test_combat_engine.gd
```

These tests are supplied for Godot **4.5.2**; local runtime verification is needed before calling the first playable build fully validated.

## Intended combat scope

Included: individual initiative, 5-foot square grid, eight-direction movement, rough terrain, blocked corners, turn action economy, melee/ranged attacks, simplistic cantrip attack, attack bonuses, AC, HP, basic line-of-sight, critical dice, goblin AI, combat log, win/loss and restart.

**Not yet implemented:** spell slots and general spellcasting, Second Wind, Sneak Attack, Weapon Mastery effects, reactions, Opportunity Attacks, full cover and death saves. Consult [First playable combat](docs/first-playable-combat.md) for explicit limitations.

## Characters and architecture

- Four races: Human, Dwarf, Elf (High Elf for v0.1), Halfling.
- Five fixed classes: Champion, Priest, Thief, Evoker and Hunter; Hunter is not in the initial four-member test party.
- Fixed level-1 test party in `tests/fixtures/party/level_01_v1.json`. Never silently change that snapshot; make new versions for level-up milestones.
- Code is separated into engine systems, `rulesets/classic_5e/` and `adventures/test_adventure/`.
- The first post-core class on the roadmap is Bard (College of Lore).

See [architecture](docs/architecture.md), [character rules](docs/ruleset-design.md), [combat rules](docs/combat-rules.md), [test party](docs/canonical-test-party.md), [data contracts](docs/data-contracts.md) and [roadmap](docs/roadmap.md).

## Licensing

Original code has no general public licence selected. SRD 5.2.1 rules content is CC BY 4.0 with attribution obligations; separate adventures/settings/artwork have independent rights. The example adventure is original placeholder content. See [licensing](docs/licensing.md).
