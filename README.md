# Project Azure Mines

## Goblin Hideout v0.9.1 — The branching cave and three tactical battles

The goblin hideout has grown into a **playable, revisitable limestone cave**. Follow the ravine into the wooded valley, **hail the hidden two-goblin watchpost and try Persuasion or Deception for guarded entry**, sneak past, or confront the lookouts in tactical combat, then enter the branching main passage and fight **a goblin and large wolf** in the guardroom. The rubbish tip includes a small original **Midden Grub**, an optional third fight, and a **hole in the floor** where goblins discard waste. Its destination deliberately remains a mystery.

Explore the **six-goblin communal cave**, speak with the displaced former chief and discuss possibly helping him depose the abusive overlord. Scout a **three-goblin-guarded underground waterfall** and discover the separate tunnel towards the bugbear's chamber. A dangerous **bugbear with two goblin guards and a wolf** still holds a chained mage; the player may discover him, but **the boss encounter and actual prisoner rescue have not yet been implemented**.

The cave has its own **discovery-based local map**, original scene illustrations and creature sprites, a battle-to-narrative transition, and once-only XP (watchpost 100 XP, guardroom 100 XP, Midden Grub 20 XP shared between four heroes). Your party's HP, spell slots, story clues, visited places, NPC decisions and cleared encounters persist through save/load. Outflanking unwarned watchpost goblins imposes the 2024-style **Surprised initiative Disadvantage**.

Read [v0.9.1 build, playtest and scope notes](docs/goblin-hideout-v091-implementation.md) and the [author-only full cave plan](docs/goblin-hideout-limestone-valley.md). **Not yet supported:** saving mid-combat, a full goblin uprising, the waterfall guards' tactical fight, bugbear confrontation, freeing the mage and travelling down the rubbish shaft. Desktop art/layout testing remains necessary.


## Goblin Hideout v0.9.0 — playable cave approach

The first cave milestone is now playable after the wagon encounter. Follow the discovered ravine into a **wooded limestone valley**, scout for **two concealed goblin lookouts in a tree watchpost**, outflank them for **Advantage** when sneaking past, or approach openly and risk raising their alarm. Visit the **cave entrance** and **first underground corridor**, record a clue, backtrack and save/reload. A new **local cave map** only reveals locations, lookouts and annotations after discovery. Hesk's existing warning remains separate from the sentries' alarm and from the goblins' opinion of you.

**Scope:** This v0.9.0 slice implements narrative scouting, passage, alarms and maps; it does **not yet simulate the watchpost fight**. The guardroom, rubbish tip/Midden Grub, underground waterfall, displaced chief, bugbear confrontation and mage rescue remain upcoming v0.9.1–v0.9.4 work. See [v0.9.0 implementation and test notes](docs/goblin-hideout-v090-implementation.md) and [author-only full cave design](docs/goblin-hideout-limestone-valley.md).


## Debug shortcut — skip the opening goblin battle

In the **Godot editor/debug build only**, a **DEBUG: Skip Goblins (Spare Hesk)** button appears at the top of the opening story, deployment and battle screens. It immediately resolves the wagon encounter as a party victory. **Hesk, Roadwatch**, the named sword-and-shield raider, survives at **1 HP, unconscious (nonlethal knockout)**; the other three goblins are defeated. The usual once-only 200 XP/12 gp rewards and return to exploration still work. **Hesk's care, conversation and fate choices appear after Continue to Wagon Clearing, not on the victory summary.** Hesk's alive state persists when you save/reload. The shortcut is removed from release builds and disappears after victory. It is a testing shortcut, not a player story decision. **Hesk is not the separate goblin lord in the future hideout.**


## Narrative exploration v0.8 — playable choice-driven adventure

**New:** After the illustrated Old Trade Road ambush, continue into an authored **Wagon Clearing → Northern Road → Harrowford Guild / Stoneweight Market** adventure. Search for clues (Investigation), track the goblins (Survival), travel back to the clearing, and consult **Mara Venn** for a guaranteed alternative lead to the overgrown ravine. Reporting at the guild and accepting the raider investigation update real quest state.

One **global campaign state** now stores party XP, gold, HP and resources, unique encounter rewards, discovered places, clue certainty, chronological events, once-only dice rolls, quest status, and named character survival, whereabouts, attitude, trust and promises. Use **Map** for an ink-and-grid-paper discovery map, **Journal** for clues/events/quests/people, and **Save / Load** for a versioned single-slot save (`user://azure_mines_slot1.json`). You may save after victory or while exploring, but **not during battle or deployment**.

Read the [v0.8 campaign-state and exploration notes](docs/campaign-state-v08.md). The ravine is an **approach to a future hideout**; the cave dungeon, mage rescue, moor tower and Harrowford's complete services are not yet playable. The map is a functional vector prototype, not final hand-drawn art.


## The deeper campaign mystery — story direction

The first adventure now hints that **dwarven ore deliveries are sporadic**, even as the miners' representatives insist there is no trouble. **Missing escorted caravans** remain the party's immediate commission. These are separate investigative threads whose eventual connection is not yet known to the adventurers. The setting author has established deeper dangers and covert interference in separate **author-only design files**; these revelations are intentionally absent from player-facing story content. These deeper events and the narrative exploration engine are **not yet implemented**.


## The Dales — Old Trade Road and vanishing caravans

Seabrook sits **west** of the Dales and is the coastal outlet for dwarven ore, precious metals and gemstones. The **Old Trade Road** connects the mines and inland markets with the western port; Harrowford is a northern market town. Wild moor, mountains, wooded valleys, limestone caves and waterfalls frame a resource-rich frontier where farmers, miners, timberworkers and woodland elves maintain an uneasy truce. Caravan raids are common, but **whole escorted convoys disappearing without survivors** are not. This mystery motivates the opening commission. See [the Dales gazetteer](docs/dales-settlement-gazetteer.md).

## Illustrated opening and Dales settlements — v0.7.2

The opening now displays a **static illustration of the four adventurers around a nighttime campfire** in the main display area while the narrative is read; the combat grid appears again for party deployment and battle. **Tavian Marr**, a merchant in the small coastal city of **Seabrook**, sends the party to investigate caravan losses in the Dales and report to the Adventurers' Guild in **Harrowford**, a northern market town.

Seabrook's old keep **Old Rookhold is in severe disrepair**, no longer an effective fortification, and its possible monster inhabitants remain an unverified rumour. Harrowford's lord lives instead at Vale Manor. The town plan includes an inn, store, rival farms, blacksmith, carpenter, life shrine and an ore-trading market held twice a week. See [Dales settlement gazetteer](docs/dales-settlement-gazetteer.md). The settlement locations are setting design data, **not yet playable town screens**.


## Named survivor combat rules — v0.7.1

Hesk, Roadwatch is now a shield-bearing swordsman with a distinct sprite and the special-NPC death saving throw rule. The player can choose nonlethal melee attacks using **Subdue**. If Hesk survives, the victory screen only reports the battle; **Continue to Wagon Clearing** opens narrative decisions to administer Medicine (DC 10) or spend a Cure Wounds spell slot, question him when conscious, promise to protect goblin families, release him, take him prisoner, leave him or kill him. Resolved choices, NPC relationships, discovered clues and separately tracked cave alert state persist in the campaign save. Regular goblins die at 0 HP unless deliberately subdued. The deeper hideout reactions are not yet implemented. See [Named Survivor v0.7.1](docs/named-survivor-v071.md).


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
