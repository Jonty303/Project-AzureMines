# Opening adventure v0.7 — The Old Timber Road

**Status:** Implemented first playable sequence on the existing `feature/downed-sprites-action-bar` branch. This is the beginning of a proposed original Project Azure Mines adventure, not an adaptation of the published Lost Mine of Phandelver encounter. Existing characters remain **level 1**.

## Playable sequence

1. **Approach:** The scene starts on a framed narrative panel, `A Wagon in the Trees`. The original text describes the old timber road, the abandoned covered wagon, a small campfire and signs of an imminent goblin ambush. The tactical battlefield is already visible behind the story interface.
2. **Party setup:** Choose **Arrange the Party** to enter the existing safe Line / Square / Diamond / manual deployment phase. Initiative has not yet been rolled.
3. **Battle:** **Begin Battle** locks the party's positions, rolls initiative and plays the existing two knife / two shortbow goblin encounter, including campfire fire damage and physical wagon/chest obstacles.
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

- First-person or top-down travel/exploration leading into the forest road.
- Persistent save/load for party XP, money, inventory, story flags and completed encounters.
- A town with useful services and occasional named magical items.
- Exploration interactions with the wagon and chests, plus quests/dialogue.
- True stealth/surprise mechanics; the current deployment phase represents an allowed setup, not surprise adjudication.
- A richer victory panel when significant treasure is legitimately awarded.

This iteration does **not** grant level-2 abilities, implement shops or inflate goblin loot. See [the sparse treasure and town economy contract](loot-and-economy.md).
