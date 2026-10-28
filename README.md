# Project Azure Mines

## The Dales — Old Trade Road and vanishing caravans

Seabrook sits **west** of the Dales and is the coastal outlet for dwarven ore, precious metals and gemstones. The **Old Trade Road** connects the mines and inland markets with the western port; Harrowford is a northern market town. Wild moor, mountains, wooded valleys, limestone caves and waterfalls frame a resource-rich frontier where farmers, miners, timberworkers and woodland elves maintain an uneasy truce. Caravan raids are common, but **whole escorted convoys disappearing without survivors** are not. This mystery motivates the opening commission. See [the Dales gazetteer](docs/dales-settlement-gazetteer.md).

## Illustrated opening and Dales settlements — v0.7.2

The opening now displays a **static illustration of the four adventurers around a nighttime campfire** in the main display area while the narrative is read; the combat grid appears again for party deployment and battle. **Tavian Marr**, a merchant in the small coastal city of **Seabrook**, sends the party to investigate caravan losses in the Dales and report to the Adventurers' Guild in **Harrowford**, a northern market town.

Seabrook's old keep **Old Rookhold is in severe disrepair**, no longer an effective fortification, and its possible monster inhabitants remain an unverified rumour. Harrowford's lord lives instead at Vale Manor. The town plan includes an inn, store, rival farms, blacksmith, carpenter, life shrine and an ore-trading market held twice a week. See [Dales settlement gazetteer](docs/dales-settlement-gazetteer.md). The settlement locations are setting design data, **not yet playable town screens**.


## Named survivor combat rules — v0.7.1

Hesk, Roadwatch is now a shield-bearing swordsman with a distinct sprite and the special-NPC death saving throw rule. The player can choose nonlethal melee attacks using **Subdue** and can offer **First Aid** or **Cure Wounds** after a victory if Hesk survives. Regular goblins die at 0 HP unless deliberately subdued. Battles end when one side is incapacitated. Longer-term decisions and relationships are part of the upcoming narrative exploration system, not yet playable. See [Named Survivor v0.7.1](docs/named-survivor-v071.md).


## Exploration design direction — narrative adventure, not first-person movement

Exploration will use authored **choice-driven narrative locations** with revisitable scenes, skill/ability checks, branching dialogue, quest decisions, persistent effects and a discovered **hand-annotated graph-paper dungeon map**. The same scene engine will drive towns and NPC interactions. Tactical combat remains its own mode. See [Narrative Exploration and Cartography Contract v0.1](docs/narrative-exploration-contract.md). The design is committed; gameplay implementation is the next major milestone.


## First playable opening — The Old Trade Road

The wagon ambush is now connected to a short original narrative: **A Wagon in the Trees → Party Deployment → Four-Goblin Battle → Victory / Defeat → Road Aftermath**. A victory displays **200 XP total (50 per adventurer)** and **12 gp** recovered for the shared party purse; there are **no mundane equipment drops**. Rewards can be claimed only once per encounter in a running game session. Persistent save/load is not yet implemented.

See [Opening adventure v0.7](docs/opening-adventure-v07.md) and [the loot/economy contract](docs/loot-and-economy.md). Press **F5** to start with the introductory story screen, then select **Arrange the Party**.


## Combat v0.6 — Pre-battle party setup

The playable wagon ambush now begins with a **deployment phase** before initiative. Choose **Line**, **Square** or **Diamond**, or click an adventurer and move them to a valid free square within the western deployment zone. **Begin Battle** locks the starting positions and starts the actual encounter. Blue placement indicators appear only when a hero is selected for repositioning; combat targeting highlights still appear only for their specific chosen action.

See [Party Deployment v0.6](docs/party-deployment-v06.md) and [the Wagon Camp encounter](docs/wagon-camp-v05.md). This is an original early-adventure encounter candidate; exploration and story transitions are not yet implemented.


## Current encounter — Goblin Wagon Camp

The level-1 battle now features **two melee goblins (including Hesk, with sword and shield) and two shortbow goblins**, a six-square **covered wagon** blocking movement and line of sight, **two blocking chests** that grant half cover (+2 AC) across firing lanes, a **campfire** dealing 1d4 Fire damage on entry and at turn start, and a northern **forest backdrop**. Assets are separate original SVGs. See [the v0.5 campsite specification](docs/wagon-camp-v05.md).


## Current development update: Combat v0.4

The current feature branch adds **context-only targeting**, visibly crossed-out exhausted actions, interruptible Opportunity Attacks, Disengage, Shield reactions, Bless concentration and **eight original combat sound effects**. Select Move, Attack or Spells to see only that action's valid destinations/targets. The game remains limited to the fixed level-1 party.

See [v0.4 controls, sounds and known limitations](docs/combat-v04-actions-audio.md). This is draft code pending an interactive desktop playtest.


## Latest iteration: downed poses and bottom action bar

On `feature/downed-sprites-action-bar`, the tutorial battle now has a mock-up-inspired dark-stone floor/wall visual, crates/barrels/torches, downed character and goblin poses, a compact bottom **Move / Attack / Spells / Second Wind / Dash / Dodge / End Turn** action bar and weapon/spell selection. Unconscious adventurers can be healed, and the combat engine now tracks basic Death Saving Throws. All characters remain level 1.

See [Combat v0.3 — Action Bar and Downed Poses](docs/action-bar-and-downed-v03.md) for controls, assets, tests and known limitations.


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
