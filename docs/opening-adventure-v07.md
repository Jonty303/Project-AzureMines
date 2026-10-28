# Opening adventure v0.7 — The Old Timber Road

**Status:** Implemented first playable sequence on the existing `feature/downed-sprites-action-bar` branch. This is the beginning of a proposed original Project Azure Mines adventure, not an adaptation of the published Lost Mine of Phandelver encounter. Existing characters remain **level 1**.

## Playable sequence

1. **Approach:** The scene starts on a framed narrative panel, `A Wagon in the Trees`. The original text describes the old timber road, the abandoned covered wagon, a small campfire and signs of an imminent goblin ambush. A static night-camp illustration now fills the main area while the authored narrative appears beside it; the tactical grid replaces the illustration in setup and battle.
2. **Party setup:** Choose **Arrange the Party** to enter the existing safe Line / Square / Diamond / manual deployment phase. Initiative has not yet been rolled.
3. **Battle:** **Begin Battle** locks the party's positions, rolls initiative and plays the existing two melee (including Hesk's shortsword and shield) / two shortbow goblin encounter, including campfire fire damage and physical wagon/chest obstacles.
4. **Victory:** Defeat all four goblins to display an authored **After the Ambush** story panel and a concise reward summary.
5. **Aftermath:** Choose **Continue Along the Road** to get a brief original story continuation. The next travel/exploration area is not yet built. A replay button returns to the opening sequence.
6. **Defeat:** No rewards. The player may choose **Try Again** and take a different formation.

All UI controls are hidden when in a narrative screen, while the combat log and action bar return during normal combat. The narrative panel reuses the game's dark fantasy palette.

## Opening encounter rewards

The four goblins are standard level-1 foes. For the prototype, the encounter grants a **fixed 200 XP total**, shared equally among our four current party characters: **50 XP each**. The party recovers **12 gp**, held in a pooled purse.

This is authored economic test data and **can be rebalanced**. It is not an indication that every four-goblin fight must produce these exact rewards. No tattered leather armour, swords, other vendor trash, or routine magical equipment appears on the victory screen. Consumables and named magic items are absent from this opening reward.

### Reward guard / lifetime

`adventure/opening_session.gd` maintains:
- A pooled `gold_gp` total.
- XP totals keyed by canonical hero ID.
- An in-memory set of encounter IDs that have already awarded rewards.

Only a **party victory** during the active battle stage can issue this reward, and only once per encounter ID in a single play session. UI refreshes and retries cannot duplicate it. A defeat awards neither gold nor experience.

**The ledger is session-only for now.** Closing Godot and relaunching creates a fresh game session, because save/load persistence and a permanent party inventory have not been implemented. It would be misleading to describe the guard as an anti-save-scumming system. Save persistence should be introduced alongside the first exploration and town scene.

The reward controller validates that XP can be shared equally among the four heroes and refuses unimplemented inventory rewards rather than pretending they were awarded. Future adventures will have distinct encounter identifiers and separately configured rewards.

## Content / code ownership

| Path | Purpose |
| --- | --- |
| `adventures/test_adventure/opening_sequence.json` | Original narrative screens, victory/defeat/aftermath text, fixed reward values |
| `adventure/opening_session.gd` | Narrative state machine and session-only once-per-encounter reward bookkeeping |
| `scenes/combat_ui.gd` | Story panel, Continue/Retry controls, reward summary, state transitions |
| `adventures/test_adventure/encounters/training_battle.json` | Existing four-goblin campsite and deployment data |
| `tests/test_opening_adventure.gd` | Story-to-battle-to-rewards, party XP split, no defeat rewards, no duplicate replay or UI refresh |

The rules engine remains responsible for determining **victory or defeat**. It does not directly issue monetary loot; adventure state handles that consequence.

## Remaining steps towards a real adventure

- Authored narrative travel and a hand-annotated overland map, including a returnable wagon clearing and optional goblin hideout discovery.
- Persistent save/load for party XP, money, inventory, story flags and completed encounters.
- A town with useful services and occasional named magical items.
- Exploration interactions with the wagon and chests, plus quests/dialogue.
- True stealth/surprise mechanics; the current deployment phase represents an allowed setup, not surprise adjudication.
- A richer victory panel when significant treasure is legitimately awarded.

This iteration does **not** grant level-2 abilities, implement shops or inflate goblin loot. See [the sparse treasure and town economy contract](loot-and-economy.md).

## Proposed follow-on: optional goblin hideout

See [Goblin Trail, Survivor and Hideout](goblin-trail-and-survivor-quest.md). This is planned content: the party can choose town or investigate the lair, revisit the wagon, follow tracks or ask a town witness for directions. The v0.7.1 combat expansion gives the named raider Hesk Death Saving Throws, nonlethal knockouts, First Aid and Cure Wounds if he survives; none of these revive a truly dead goblin. Bargaining, taking him prisoner, releasing him and tracking later consequences are **not yet playable**. If eventually released, he may warn and fortify the hideout, open a diplomatic audience, or both.

## v0.7.2 — Commission and illustrated story presentation

The opening now begins with **Tavian Marr's commission in Seabrook**: investigate caravan losses entering the Dales, and report to the Adventurers' Guild in **Harrowford** on the northern edge of the region. The party rests around a fire under pines before finding the sabotaged wagon at dawn. A static authored illustration fills the central screen during narrative reading and hides during party setup and tactical battle; the original art can later be replaced with animation. Art and prose are selected by each story screen's `art` and `paragraphs` fields. The illustrated concept image is a visual reference; the current in-game asset is a separate original SVG scene. Seabrook's old keep is **derelict and possibly inhabited by monsters**, not a functioning defence. See [the Dales settlement gazetteer](dales-settlement-gazetteer.md).
