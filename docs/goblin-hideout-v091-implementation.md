# Goblin Hideout v0.9.1 — Branching Cave and Three Tactical Encounters

**Status:** implemented in Godot 4.5.2 on `feature/downed-sprites-action-bar`; desktop usability and encounter balance still need manual playtesting. This is a substantial follow-on to v0.9.0, not a declaration that the entire dungeon arc or captive rescue is complete.

## Playable cave environment

From the existing overgrown ravine and wooded watchpost, the party can enter a long limestone corridor and choose among these locations:

| Location | Implemented interaction |
| --- | --- |
| Wooded cave approach | Locate two hidden sentries, slip past, approach openly or **attack the two goblin lookouts in tactical combat**. A successful outflank can impose the 2024 SRD Surprise initiative penalty on the unwarned enemies. |
| Cave entrance and first passage | Investigate and travel into the branching corridor; retreat at any time. |
| Main corridor | Branches toward the rubbish tip, guardroom, shared common room, waterfall and commander's outer passage. Unvisited rooms are not displayed on the local map. |
| Rubbish tip | Meet an optional **Midden Grub**; distract it with scraps or choose a low-threat fight. Inspect the **hole through the floor** where rubbish is thrown, and record an unknown shaft on the map. **Its depth and destination are not authored.** |
| Guardroom | **One goblin guard and one large wolf**, implemented as a distinct tactical encounter with an original wolf sprite and bite action. Defeating them permanently clears the room and unlocks a searchable caravan clue. |
| Goblin common room | Meet six wary goblins, including the **displaced former chief**. Learn about his harsh overlord, discuss possible assistance against him, and record an **unresolved proposal**, not an automatic uprising. No compulsory fight with the six goblins. |
| Underground waterfall | Discover three guards, the water-filled chamber and an alternative passage towards the overlord. **The sentries are not yet attackable** and the passage remains guarded. |
| Outside the bugbear's chamber | Scout the **bugbear overlord, two goblin guards, second wolf and malnourished chained mage**. Record the prisoners' plight and defender count; the party **cannot yet fight the boss, enter freely or rescue the mage**. |

The bugbear's standing **author-only orders to capture dwarven caravan travellers and transfer them to the high-moor tower** remain unrevealed by ordinary scouting; the deeper conspiracy and mage's spellbook are not placed as loose loot here.

The cave-room layout and progression are authored in `adventures/test_adventure/exploration_v08.json`; this file now covers the larger 0.9.1 world graph despite its original filename. Any one-time clues, dialogue outcomes, discovered routes, encounter states and visited-room marks persist through the common `CampaignState`.

## Actual new tactical battles

Three authored fixtures share the existing engine and UI:

| Encounter | Enemies | XP for party | XP each (four heroes) | Rewards |
| --- | --- | ---: | ---: | --- |
| `cave_watchpost` | Two goblin lookouts | 100 XP | 25 XP | No extra money |
| `cave_guardroom` | One goblin guard + one large wolf | 100 XP | 25 XP | No extra money |
| `cave_midden_grub` | One original low-threat scavenger | 20 XP | 5 XP | No extra money |

The original 200 XP / 12 gp wagon battle is unchanged. The additional encounters use combat grid fixtures in `adventures/test_adventure/encounters/` with cover, rough ground, individually named enemies and distinct art for the large wolf and Midden Grub. Encounter outcome and reward tracking are **independent and once-only**; returning to an already-cleared chamber does not respawn enemies or repeat XP.

To support the new opponents the combat AI now selects weapons from each creature's authored attack list, rather than assuming all opponents use `knife`/`shortbow`. This enables the wolf's **bite** and the grub's **mandibles** during actual enemy turns.

When a player selects a battle choice, exploration hands control to the same tactical engine and UI, using a registered encounter fixture. After victory, the outcome is written to global state, party HP and spell slots are carried back, XP is awarded once and the UI returns to **the same narrative location**. Starting a second cave fight restores those resources and relevant class abilities rather than creating a fresh party. The normal Godot battle commands remain available: movement, attacks, spells, action economy and initiative.

**2024 Surprise rule:** an undiscovered or unalerted tree watchpost successfully outflanked by the party rolls initiative **with Disadvantage**, not a free attack round. Scouting or outflanking alone does not award XP or silently remove goblins. An earlier warning from Hesk or the lookouts' own raised alarm prevents this Surprise benefit.

**Limitations:** defeat still uses the existing game-over screen rather than a prison/retreat outcome. Save is unavailable during tactical combat. New monsters are first-pass balance designs, not fully audited SRD stat-block reproductions. The wolf does not yet have a special knockdown rider, and the original grub is deliberately simple and nonpoisonous. The current combat board uses existing dungeon tiles plus new creature sprites; its final terrain art and custom tactical maps need playtesting.

## Cartography, story art and information boundaries

The local graph-paper map now shows the long corridor and branches **only once visited**. It does not expose hidden watchposts, the waterfall-side connecting tunnel before inspection or the unknown destination of the rubbish shaft. The overland map shows the cave **approach** but not the subterranean rooms.

New original vector illustrations:
- `assets/story/cave_wooded_valley.svg`: limestone cliff, wooded valley and shadowed cave mouth
- `assets/story/cave_rubbish_shaft.svg`: broken refuse, small scavenger and dark hole
- `assets/story/cave_underground_waterfall.svg`: falling underground water with guarded ledges

New creature sprites: `assets/characters/sprites/cave_wolf_64.svg`, `assets/characters/sprites/midden_grub_64.svg`. Scenes with art show a **Map** toggle to the discovered local chart. Other chambers use the map until bespoke illustrations are commissioned or created.

## How to play through the new content

1. In the Godot editor, start the opening and optionally use **DEBUG: Skip Goblins (Spare Hesk)**.
2. Continue to the wagon clearing; resolve or postpone Hesk's narrative care/fate. Ask Mara Venn in Harrowford for the guaranteed ravine clue, or find the trail by Survival or Hesk.
3. Follow the ravine to the wooded cave approach. Discover the hidden tree watchpost and choose to **attack** it, or avoid the guards. Winning this **two-goblin fight** opens the route into the cave.
4. Advance from the cave mouth to the **branching main corridor**. Choose the **guardroom** for a second tactical fight against a goblin and wolf; retreat or return to the room to find defeated enemies gone.
5. Visit the **rubbish tip**, inspect the mysterious shaft and optionally fight or distract the grub.
6. Talk with the older goblin in the **communal chamber**, scout the guarded waterfall and observe the bugbear and prisoner from the outside approach.
7. Save, reload, revisit rooms and confirm that encounters, spell slots, injuries, dungeon map, clues and NPC decisions remain.

## Automated testing

- `tests/test_cave_multibattle_v091.gd` checks actual start/end transitions for **all three combats**, distinct enemies, once-only rewards, preserved injury/slots between fights, wolf bite and grub mandibles AI, rubbish shaft clue, chief conversation, waterfall clue, mage sighting, Save/Load and return travel.
- `tests/test_cave_approach_v09.gd` validates watchpost stealth, secrecy, alerts and map; adjusted to cover illustrated art and Map toggle.
- The existing complete Godot 4.5.2 regression workflow still covers the opening ambush, Hesk survival, first-aid narrative, campaign state, the action bar and spell rules.

## Next substantive milestone

**v0.9.2 — Goblin politics and the guarded waterfall:** negotiate an actual conditional alliance with the ex-chief, introduce the three waterfall guards as a tactical encounter, add side-tunnel movement and boss-area approach variants. **v0.9.3:** boss confrontation with bugbear, two goblin guards and wolf; genuine mage rescue, recovery, quest state and tower leads. **v0.9.4:** balance for four level-one adventurers, world-time/retreat consequences, dedicated dungeon art, adaptive NPC responses and desktop usability.

Do not merge draft PR #4 until expressly approved. Do not confuse a discovered captive with a completed rescue, or a proposed uprising with the bugbear's defeat.
