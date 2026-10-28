# v0.9.0 — Goblin Hideout Exterior, Concealed Watchpost and Local Cave Map

**Status: implemented on** `feature/downed-sprites-action-bar` in Godot 4.5.2. Automated headless tests pass; a desktop visual playtest is still required.

This is **the first of the planned v0.9 Goblin Hideout milestones**, not the complete dungeon. Continue the existing opening adventure normally or use the developer-only Skip Goblins button. The postbattle **Continue to Wagon Clearing** enters exploration, after which a clue from **Mara Venn** (guaranteed fallback), a successful tracking check or a cooperative Hesk can reveal the overgrown ravine.

## New playable narrative locations

1. **Overgrown Ravine:** Now contains the route to the cave approach. The ravine can still be revisited from the wagon clearing or Harrowford.
2. **Wooded Valley — Cave Approach:** A rock wall with a limestone cave mouth, trees and cover. Two goblin sentries occupy a concealed tree watchpost. The player **does not know where the post is** merely by arriving.
3. **Tree Watchpost:** A **map-only discovered feature** until the player spots the sentries. Not yet an attackable encounter; no goblins are silently killed, subdued or removed by travelling there.
4. **Cave Entrance:** Beyond the sentries, the opening in the cliff. The party can listen for activity and walk inside or back out.
5. **First Passage:** The initial stretch of limestone corridor, with a recordable map note. The deeper interior is authored in the design documents but **not yet accessible**.

## Watchpost actions and exact mechanical consequences

| Action | Requirement | Result |
| --- | --- | --- |
| **Scan the trees** | At cave approach; once only | Wisdom (Perception) DC 12. On success: discover two goblins in the tree watchpost, mark them on local map, record a clue. On failure: record the attempt without revealing the post. |
| **Circle behind the sentries** | Discovered watchpost, before crossing, no alarm; once only | Dexterity (Stealth) DC 12. On success: mark `watchpost_outflanked`; this grants **Advantage on the subsequent bypass Stealth check**. On failure: the sentries spot the party and sound the alarm. **Does not defeat the goblins or begin combat.** |
| **Slip past the watchpost** | At cave approach, before crossing; once only | Dexterity (Stealth) DC 13, with two d20s if successfully outflanked. Success reaches cover at the cave mouth unnoticed by these sentries; failure reaches cover but raises an alarm. Both preserve the sentries' existence. |
| **Approach openly** | At cave approach, before crossing; once only | Reaches cover by the cave mouth, with the sentries shouting a warning. This is not a resolved combat encounter. |
| **Continue to cave mouth** | A watchpost-crossing decision resolved | Enter the cave entrance; the alarm and discovered state stay unchanged. |
| **Retreat** | At cave approach, cave entrance or first passage | Return to already visited places without resetting checks, rewards or security. |

The check system records the character, die(s), modifier, DC, outcome and conditional Advantage in the shared `CampaignState`, preventing free retries after save/load. For this vertical slice, the **best conscious available hero is selected automatically**. Direct character selection and more complex group checks are later work.

**Independent security axes:** `watchpost_alarm_raised` records an immediate warning from the tree post. `goblin_lair_readiness = alerted` may already be set by releasing Hesk; it alters cave-area descriptions, but does **not** automatically claim the party spotted the hidden watchpost. A quiet bypass cannot undo an earlier alert from Hesk or the sentries. Attitude/trust remain in the NPC registry, independent of readiness.

**Important milestone boundary:** v0.9.0 offers *outflanking and stealth* but not yet a tactical **counter-ambush battle** against the two sentries. Full narrative-to-combat transitions, sentry kills/captures and reinforcement mechanics belong to **v0.9.1**. Neither the successful outflank nor the open approach awards XP, applies combat damage, removes enemies or fabricates a completed fight.

## Local cave discovery map

`adventure/local_cave_map.gd` is a new graph-paper-inspired drawing layer used automatically for exterior and cave-entrance scenes. It marks only justified discoveries:

- Wooded approach when the party arrives
- **Tree watchpost only after successful Perception**
- Cave entrance once visited
- First passage once entered
- Tree alert, earlier Hesk warning or unobserved bypass as separate annotations

The deeper guardroom, former chief's quarters, rubbish tip, mysterious refuse shaft, waterfall and bugbear's chamber **do not appear** as discovered rooms in v0.9.0. Their future design is retained in [Goblin Hideout — Wooded Valley and Limestone Cave](goblin-hideout-limestone-valley.md). The new local map is a functional schematic, **not yet a final illustrated dungeon map**.

The overland ink map also records the route between the ravine and cave approach. As before, the game's Save/Load controls preserve location, clues, check outcomes, relationships and rewards using versioned JSON. Saving during active combat remains unavailable.

## How to playtest

1. Start the adventure in Godot 4.5.2, optionally use **DEBUG: Skip Goblins (Spare Hesk)** and continue to the wagon.
2. Travel to **Harrowford's Stoneweight market**, talk to **Mara Venn** for the guaranteed goblin-trail directions, return to the wagon and follow the ravine. Alternatively find the track by a successful Survival check or Hesk's help.
3. Select **Follow the ravine to the wooded cave approach**.
4. Scan the trees, prepare a position behind the sentries if spotted, choose stealth or an open approach, and observe the resulting alarm.
5. Enter the cave mouth and first corridor, save, reload and retreat. Verify that the watchpost, alarm, known routes and clues remain consistent.

## Tests

`tests/test_cave_approach_v09.gd` covers:
- Success/failure of secret-watchpost Perception without premature discovery
- Outflank availability only when the post has been found and no alarm raised
- Conditional Advantage, both stored d20s and correct higher-roll selection
- Open approach triggering a persistent alarm once
- Walking from the wagon through Mara's backup lead to the ravine and cave
- Switching to local-map presentation, no unseen room reveals
- Exploration of the first passage, journal clue, Save/Load, return travel
- Prior Hesk warning influencing the approach **without** turning into watchpost discovery or a second alarm

Existing opening, named-survivor, Hesk narrative, reward, save/load and combat regression tests remain active.

## Next milestones

**v0.9.1:** a reusable narrative-to-combat transition to tactical encounters and back, with persistent party resources and individual defender outcomes; activate the **two-goblin tree-watchpost encounter**, the one-goblin-and-wolf guardroom, and the small avoidable Midden Grub in the rubbish tip. Build playable local branching passages; reveal the rubbish shaft as an **unknown** map feature, without inventing its depth or destination.

**v0.9.2:** six-goblin common area, displaced former chief and uprising diplomacy. **v0.9.3:** defended waterfall, bugbear overlord with guards and wolf, restrained mage rescue and different credible endings. **v0.9.4:** balancing, persistent dungeon revisits and narrative/art polish.

The bugbear's orders to **capture dwarven caravan travellers and send them to the high-moor tower** are author-only spoilers; no v0.9.0 player-facing scene discloses them.
