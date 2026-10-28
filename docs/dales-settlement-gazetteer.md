# The Dales — Opening Settlements and the Old Keep

**Working names and NPCs** for the original Project Azure Mines setting. The region's broader history, geography, deities and politics remain open to the setting author's future additions. The details explicitly supplied by the author—an under-defended multicultural coastal city, an increasingly disreputable ruined keep, a northern Dales market town and its trades—are the governing constraints.

## Seabrook — the small coastal city

Seabrook is called a city because of its charter and the commerce in its harbour, not because of its size or military strength. Fishing boats, ore barges, foreign traders, sea captains, itinerant craftspeople, adventurers and people of many ancestries crowd its unplanned quays. It is a place where languages and customs mix freely, and so do legal commerce, smuggling, graft, theft and racketeering.

**Seabrook was never properly defended.** There is no effective continuous city wall. A handful of weather-beaten stone watchtowers and small posts watch the harbour approaches, some undermanned or poorly maintained. The old keep, tentatively called **Old Rookhold**, stands on a headland but is **in serious disrepair**. Much of the roof has collapsed, parts of the outer walls have fallen, and lower chambers flood with salt water. It cannot reliably house a garrison or defend the city.

Locals report lights in sealed windows, strange calls in the vaults and sailors vanishing near the broken stair. **There may be monsters occupying it**, but that is deliberately an unverified rumour for now. It could later support an optional dungeon, investigation or town-security quest; no monster species or reward is established yet. The town's local watch avoids entering without a convincing reason.

### Commissioning merchant

**Tavian Marr** (working name), a Seabrook merchant whose caravan interests extend into the Dales, hires Alden, Elyra, Brunna and Pip to investigate missing and plundered shipments. They are to reach **Harrowford**, report to the local Adventurers' Guild under the terms of their contract, and determine what has been happening to the caravans. The party should be able to investigate the raiders while remaining free to pursue related leads.

The party travels along the old timber road and camps under the trees before encountering the abandoned covered wagon and goblin ambush.

## Harrowford — northern Dales market town

Harrowford sits at the northern edge of the Dales where the roads from the mines, surrounding farms and coast converge. The settlement is modest, practical and slightly isolated. A twice-weekly market gathers around the **Stoneweight Trading Post** and ore weighhouse. Trade is largely in local ore, tools, leather, foodstuffs and practical services, rather than mountains of magical equipment.

| Location | Working name | Role and adventure potential |
| --- | --- | --- |
| Adventurers' Guild | Harrowford Adventurers' Guild | Mandatory contract reporting, local jobs, quest journal, reputation, mediation |
| Inn | The Golden Stag | Lodging, rest, gossip, caravan rumours and chance meetings |
| General store | Wren's Sundries | Rations, rope, tools, consumables and other useful supplies |
| Farm 1 | Bramwell Farm | Proud established farming family, locally influential |
| Farm 2 | Kestrel Farm | Rival family competing for land, market access and water rights |
| Blacksmith | The Red Anvil | Equipment maintenance and possible bespoke repairs, not unlimited enchanted gear |
| Carpenter | Hollis's Yard | Repairs to community structures, farm buildings, barriers and future town-upgrade projects |
| Life shrine | Shrine of Lethiel | Small sanctuary dedicated to **Lethiel**, working name for the goddess of life; refuge, tending injuries and services |
| Lord's residence | Vale Manor | An occupied modest manor of **Lord Osric Vale**, a self-interested, potentially corrupt local lord |
| Ore trading post | Stoneweight Trading Post | Ore exchange and weighing, contracts, twice-weekly market for farms and craftspeople |

**Town structure:** The guildhall is the first contractual destination. The Golden Stag lies near the road into town. The trading post and market anchor the central square. The shrine and workshops are accessible from the settlement, the two rival farms lie just beyond the houses, and Vale Manor overlooks the town. This is an *authored narrative location graph*, not a continuous walking simulation.

**Distinct buildings:** Vale Manor is inhabited by Harrowford's lord. The **ruined keep is in Seabrook**, not the lord's house in Harrowford. The concept art must distinguish those two places.

### Supporting characters

- **Mara Venn:** a wagoner who has already been preyed upon by goblin raiders. If tracking fails at the wagon site, she can provide a reliable lead to the hideout without requiring another mandatory success roll; she may offer a reward.
- **Lord Osric Vale:** entitled and troublesome but not automatically the main villain; uncover specific misconduct through evidence and quests.
- **Hesk, Roadwatch:** the named sword-and-shield goblin who may survive the first ambush. His feelings about his family, his raider chief and the party can affect future lair readiness and diplomacy.
- **Lethiel:** proposed local goddess of life. Do not invent an entire cosmology or dogma before the author establishes it.

## Future narrative consequences

The Old Rookhold keep could be a deliberately optional location on the **Seabrook urban map**: a ruined outline and an inked question mark near the headland, with its true inhabitants only revealed through investigation. A carpenter-led town-improvement system could also later involve repairing the watchtowers, securing the harbour or restoring a public building—but **rebuilding the old keep should be an expensive, substantial undertaking**, not a trivial early gold sink.

The farm rivalry should not be a simplistic good-family/bad-family binary. The town's prosperity depends on mines and agriculture, and rival interests can complicate quests without forcing combat.

## Current implementation vs plan

**Implemented:** updated opening narrative and named Seabrook-to-Harrowford merchant commission in `adventures/test_adventure/opening_sequence.json`; an authored static illustrated campfire image fills the main battle pane during narrative reading; the story continues to existing party deployment and tactical ambush.

**Data-design only:** setting anchors in `adventures/test_adventure/setting_anchors.json`. The towns, sites, people, shrine, manor, ruined keep, market days, quests and overland travel are **not yet playable**.

### Asset direction

The narrative interface should show a **large, static illustration in the main part of the screen**, with readable narrative prose and one or more choices to its side. The opening illustration is the four shadowed companions around a nighttime campfire beneath dark pines. It can later be replaced with animated artwork without modifying the story data contract.

The static painting may change on a scene-by-scene basis through each screen's `art` field. Tactical maps only appear in deployment and combat. The quest journal and graph-paper annotated maps remain future exploration work.
