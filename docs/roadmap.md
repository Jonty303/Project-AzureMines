# Roadmap — updated after the first playable adventure opening

Milestones are deliverable-driven, not scheduled deadlines.

| Stage | Target | Status |
| --- | --- | --- |
| 0 | Godot/bootstrap and example module loader | Implemented; local validation needed |
| 0.5 | Canonical immutable level-1 party and reference artwork | Character fixtures drafted, sprite tokens supplied |
| 1 | First playable tactical battle | Implemented on feature branch: four heroes vs four goblins, ranged/melee AI, cover, hazards and deployment |
| 2 | Combat correctness | Opportunity attacks, cover, reactions, weapon mastery, death saves |
| 3 | Four starting classes' spells and signature abilities | Core spell engine, Sneak Attack, Second Wind and Channel Divinity |
| 4 | Level 1–5 progression for all five classes | Hunter added, class levels, new enemies and extensive tests |
| 5 | Narrative adventure engine | Authored choice-driven scenes, graph navigation, checks, conversations, revisits, quest flags, persistent save/load and hand-annotated map |
| 6 | Original opening adventure and town economy | Extend Old Trade Road into revisitable locations and one town; quest dialogue, scarce named magic items, services and gold sinks |
| 7 | Bard expansion | Bard + College of Lore once RPG interactions exist |

## Next validation

- [ ] Run headless module, party and combat tests using Godot 4.5.2.
- [ ] Verify mouse positions, path highlights, and scaled sprites on a desktop.
- [ ] Play a full battle from victory to restart, checking all player and goblin turns.
- [ ] Test blocked corners and turn action/movement limits.
- [ ] Review first iteration against SRD combat rules before broadening scope.

## Scope guardrails

No permanent character creation or levels beyond one until the current slice is stable. Exploration means authored narrative location nodes and choices, **not** a first-person movement grid. Build one small revisitable area, check, map and conversation before a generic editor or broad content.

## Loot and town economy

See [Loot, Treasure and Town Economy v0.1](loot-and-economy.md). Routine victories primarily grant XP and coin, sometimes consumables. Ordinary discarded equipment is not collected as loot. Named magical items are scarce, from authored enemies, rare constrained generation or occasional persistent merchant stock. Gold sinks include town services and selected purchases. **Documentation only** until inventory/rewards/services are implemented.

## Exploration direction — supersedes older first-person proposals

Azure Mines uses a **narrative choice-based exploration engine**, with persistent scene variants, actor conversations, skill/attribute checks, quests, interactive objects, story-triggered combat and consequences, plus a graph-paper-style, hand-annotated discovery map. See [Narrative Exploration and Cartography Contract v0.1](narrative-exploration-contract.md). This is the next major system after the v0.7 opening; it is **not yet implemented**.

The first integration slice connects the existing wagon ambush to several revisitable narrative locations, one check, one branching conversation/quest, discovered map annotations and a real save/load record for persistent rewards/flags.

## Regional story anchor — Old Trade Road

Seabrook is the western coastal outlet for the Dales' dwarven mining economy. Harrowford lies on the northern edge. Much of the country remains wild limestone moor, mountain, wood and fertile valley, with new settlement, mine expansion, farmland and timbercraft held in an uneasy truce with local woodland communities. Ordinary guarded caravan raids are known; **the disappearance of entire escorted convoys without survivors is not**. All future overland maps, narrative checks, trade and quest content should uphold those constraints. See [Dales settlement gazetteer](dales-settlement-gazetteer.md).

## v0.8 implemented — global state and first narrative exploration slice

The current feature branch now advances from the opening goblin battle into five authored narrative locations: Wagon Clearing, Northern Road, Harrowford Guild, Stoneweight Market and Overgrown Ravine. Players can conduct once-only skill checks, discover clues, revisit locations, report the merchant commission, accept a raider investigation and obtain Mara Venn's reliable hideout lead. The main story UI has dynamic choices, a state-aware parchment discovery map and separate clue/event/quest/people journal.

All of these use one persistent `CampaignState` with versioned JSON Save/Load: XP, gold, party resources, resolved checks, NPC survival/attitude/promises, visited places, known routes and quest progress. Save/load is intentionally limited to victory, aftermath and exploration, **not mid-combat**. See [v0.8 campaign-state notes](campaign-state-v08.md).

**Next:** Manual 4.5.2 desktop review of UI sizing/map readability; the first **Hesk narrative survivor conversation and fate decisions are now playable** after battle, not on the victory summary. Further work should add chosen character for checks, Advantage/Disadvantage, typed quest objects, world-time consequences and the actual goblin hideout. The five-location slice is playable; the hideout, full Harrowford services, tower, mage rescue and Lord Vale arc are still design-only.

## Author-defined goblin hideout — layout for future dungeon milestone

The next authored cave is laid out in [Goblin Hideout — Wooded Valley and Limestone Cave](goblin-hideout-limestone-valley.md): concealed **two-goblin watchpost** outside a rocky wooded-valley cave; long limestone corridor with side passages to **rubbish tip**, **guardroom (goblin and wolf)**, **communal area (six goblins, including an ex-chief)**, and the **bugbear overlord's chamber** containing the chained mage. The corridor ends at a guarded **underground waterfall**; a second tunnel connects the waterfall and bugbear chamber. The bugbear was imposed by the society, mistreats the goblins and will **not** negotiate, while the ex-chief may be recruited for a coup. The rubbish tip contains a low-threat original **Midden Grub** and a **hole in the floor** into an undefined future lower space, used by goblins to discard waste. Record that hole as a discovered map note without inventing its destination. **Design only; no hideout gameplay shipped yet.**
