# Goblin Hideout — Wooded Valley and Limestone Cave

**AUTHOR-ONLY ADVENTURE DESIGN • NOT YET PLAYABLE.** This is the canonical room-and-encounter specification provided by the setting author for the next dungeon iteration. The existing v0.8 playable overland journey currently stops at an **overgrown ravine**, rather than entering this cave. Narrative exploration, not first-person tile-by-tile movement, is the intended presentation.

## Ground plan and connections

The hideout entrance is cut into a **rocky limestone wall in a wooded valley**. A narrow trail passes a concealed **watchpost in the trees**. Inside the cave a **long principal corridor** runs towards an **indoor waterfall**. Side passages lead to the goblins' refuse dump, a guardroom, their shared kitchen/eating/sleeping area, and the overlord's chamber. The lord's chamber also connects to the waterfall by a **separate tunnel**.

```text
                          WOODED VALLEY
              [Tree watchpost: 2 goblin sentries]
                              |
                  [1. Outside cave / approach]
                              |
                      [2. Cave entrance]
                              |
                 +------ MAIN CORRIDOR ---------+
                 |            |          |       \
         [3. Rubbish tip] [4. Guard] [5. Common] [6. Lord's cave]
           1 Midden Grub    1 goblin    6 goblins    1 BUGBEAR lord
           refuse shaft    + 1 wolf    (incl.        2 goblin guards
           ↓ UNKNOWN                  ex-chief)      1 wolf
           BELOW                                    prisoner: mage
                                                      |
                                [7. Underground waterfall]
                                   3 goblin guards  <-+
                                   (end of main corridor)
```

**Schematic only**: no compass bearings, route distances, combat-grid sizes, or other side tunnels have been established. For data integrity, these are the confirmed connections:

- The **outside** connects to the **cave entrance** and the **tree watchpost**.
- The **entrance** enters the **main corridor**.
- The **main corridor** has accessible branches to **rubbish tip**, **guardroom**, **common area**, and **bugbear lair**, and continues to the **waterfall**.
- The **waterfall** has another connection to the **bugbear lair** via the lord's private connecting tunnel.
- The **rubbish tip** contains a **hole through the floor** into an uncharted space below. Goblins routinely throw most waste down it. **What lies below and whether the shaft becomes a route are deliberately undecided.** It is not a currently confirmed exit, shortcut to the boss, or connected lower level.

On a discovered dungeon map, draw the upper floor as linked annotated places. Record the hole as `? shaft below rubbish tip` or another uncertain annotation once the party notices it, but **do not reveal an unexplored lower map**.

## Area register

| Scene | Occupants | Player-facing possibilities |
| --- | --- | --- |
| **1. Outside the cave — wooded valley** | **Two goblin sentries**, concealed in a small elevated tree watchpost | Sneak, examine the terrain, detect the sentries before they detect the party, avoid or ambush the ambushers; if they sound an alarm the cave becomes alert |
| **2. Cave entrance** | No additional standing guards established | Inspect tracks and signs of activity, listen for cries or footsteps, enter or retreat; atmosphere varies with alarm state |
| **Main corridor** | No specified permanent patrol | Explore the long limestone passage; choose passages by sound, cooking smoke, guard noise, refuse smell and roaring water |
| **3. Rubbish tip** | **One Midden Grub** (original low-threat scavenger) | Search refuse, distract the grub with scraps, fight only if provoked, examine the rubbish shaft, mark its existence for later exploration |
| **4. Guardroom** | **One goblin and one large wolf** | Sneak past, parley if plausible, confront, or stop reinforcement from reaching the rest of the lair |
| **5. Kitchen / eating / sleeping common room** | **Six goblins in total, one the displaced former goblin chief** | Hear their grievances and determine whether enough of them can be enlisted against the bugbear; choosing to fight everyone is not mandatory |
| **6. Bugbear lord's chamber** | **One bugbear overlord, two goblin guards and another wolf**; one prisoner, the **captured mage**, chained in a corner | Resolve the bugbear threat by confrontation, uprising, stealth or another credible plan; rescue, feed and tend the mage |
| **7. Underground waterfall** | **Three goblin guards** stationed here because of proximity to the bugbear's lair | Navigate wet rocks, avoid watchful guards, divert attention, or use the connecting tunnel towards the lord's chamber |

### Watchpost and independent alarm state

The **two goblins in the trees** are watching the cave approach and intend to **ambush intruders or alert the others**.

- If the party **spots the watchpost first**, they can plan a counter-ambush, bypass it, **hail the sentries and try to talk their way in**, bluff them, or attempt a quiet capture. They can also call out peacefully without spotting the platform first; the watchpost becomes visible when the guards answer.
- If the watchers **spot the party first**, the goblins may spring an ambush or raise the alarm. The party should receive believable observational clues, not a retroactive unseen script.
- Hesk's earlier **release** might already have put the cave on alert before the party arrives. A friendly reception from some goblins and an increased security posture **must be separate flags**.
- The alarm changes interior behaviour, guard readiness, available dialogue and possible reinforcements. It should **not** magically teleport all fourteen goblins into one level-one fight.

Proposed state: `hideout_alarm`: `unaware | suspicious | raised`; `tree_watchpost_state`: `undetected | detected | bypassed | neutralised | alerted`. The approach's check results are recorded once with character identity, die and modifiers.

## Rubbish tip — monster and hole in the floor

The goblins discard most of their rubbish through **a hole in the floor** of the tip, among broken crockery, gnawed bones, rotten food, wrapping and scrap. Its **depth, destination and age are not known**. It might eventually open a way to deeper limestone caves or something else, but we should not decide now. For a first visit, a player can inspect the lip, drop a pebble, listen, measure the shaft or mark it on the map; no automatic descent option is offered until we author the lower space.

A dangerous-looking but manageable resident is the original **Midden Grub**: a short, pale, plated cave scavenger that lies beneath food waste, with blunt chitinous mandibles and whisker-like feelers. It mainly wants to feed undisturbed and may shuffle towards the shaft when threatened. A moving mound of refuse, a sour smell and bits of rubbish shifting provide discoverable warning. This is **a living scavenger, not the secret mine threat** and not an intelligent society agent.

**Provisional balance target for four level-one heroes — to be playtested:**

| Stat | First-pass proposal |
| --- | --- |
| Armour Class | **11** |
| Hit Points | **9** |
| Speed | **20 ft** |
| Attack | **Mandibles +3 to hit**, one adjacent target |
| Damage | **1d4+1 piercing** |
| Behaviour | Defensive; attacks when cornered, hurt or when food is grabbed from directly beneath it |
| Special attacks | **None**; no poison, paralysis, grapple, swallow, instant-death fall or unavoidable area damage |

The party should have **three genuine options**: avoid it, distract it with food/throwing refuse, or defeat it. The creature's escape towards the hole is a narrative possibility, **not proof that the hole is navigable**. It does not drop a magical item. These are proposed original creature statistics, **not an implemented combat fixture or a claim of SRD monster equivalence**.

**Safety and fairness:** The hole is apparent with reasonable observation; ordinary exploration should not produce an unavoidable fatal fall. If future content introduces climbing, pushing, collapse or descent, it must provide visible risk, relevant checks and a defined lower location. Its unknown future use is precisely why it should remain unconnected on the current map.

## Who really commands the cave

The supposed **goblin lord is a bugbear** imposed by the shadowy society to disrupt traffic on the **Old Trade Road**. His cruel treatment of his goblin subordinates has alienated some of them. He is **not interested in surrendering the mage**, **not interested in trade**, and **not receptive to deals or an alliance with the adventurers**. This is an established personality constraint. The party can still use tactics, stealth, the waterfall route or goblin assistance, but should not get a fake high-DC Persuasion button whose success forces him to contradict his character.

### Standing orders — seize dwarves alive

**Author-established fact:** The shadowy organisation has instructed its installed bugbear overlord that, **whenever the raiders attack caravans, they must watch for dwarves, capture any they encounter if possible, and send the captives to the old high-moor tower**. This is a deliberate, ongoing order alongside disrupting mineral trade. Dwarven passengers are targets even if their apparent role is merchant, driver, escort or traveller; **the order does not depend on whether an individual dwarf actually knows the mines' secret**.

The previously captured **dwarven trader** is a concrete example: he was taken alive and transferred to the tower for interrogation about the mines. The **mage** from that caravan was instead left chained in the bugbear's chamber; his **spellbook** travelled with the trader. Neither their separation nor the book's transfer proves why the organisation wants the mage's book.

**Consequences for future adventure authoring:**

- Raiders may try to **subdue and bind** a dwarf rather than kill one. Their behaviour should reflect a capture objective instead of blindly attacking every target to the death; the bugbear must still be dangerous to the party.
- A guard, Hesk or the displaced chief **may know fragments** of the orders, their wording, repeated searches for dwarf travellers, or the route taken by escorted captives. Do not assume every goblin knows who ultimately gave the command.
- A discovered **instruction, cargo/prisoner tally, escort testimony or transfer record** could provide a clue that dwarven prisoners are treated differently. Keep each clue discoverable through credible observations or social interaction, with certainty recorded correctly.
- A captured dwarf is **not automatically a mine insider**, and prisoner transfer to the tower is **not proof that every missing caravan has been accounted for**. The organisation's wider aim remains an author-only mystery.
- Record separate state for each named prisoner, capture attempt, transfer and rescue; do not abstract living captives into missing cargo. No free all-purpose “rescue dwarves” event should resolve unseen prisoners.

The bugbear will not willingly release the **mage** in his lair or bargain with the adventurers, even if the party knows about the dwarf-capture orders.

The **displaced goblin ex-chief** lives with **five other goblins** in the common area (six total). If the circumstances are right, he may offer or accept a plan for the party to help the goblins overthrow the bugbear. He could be bitter, frightened or cautious about retaliation, so his support is earned and contingent rather than a guaranteed virtue reward.

The eventual power arrangement after the bugbear falls is **not preordained**. The former chief might regain authority, someone else might rise, or the goblins might split. Consequences should reflect whom the party trusted, harmed or protected.

### Prisoner — the missing mage

The malnourished but living mage is **chained in the corner of the bugbear's chamber**. His spellbook is **not anywhere in this hideout**: the society transferred it with a captured **dwarven trader** to the **old high-moor tower**, where the dwarf is being tortured for information about the mines. Rescuing the mage and reclaiming his spellbook remain separate quests.

The mage is a person in weakened condition, not instant loot or a fresh level-one combat recruit. Freeing his restraints, helping him move, providing food/water and restoring him to safety affect his relationship with the party. Later he may settle in Harrowford or perhaps take over the high-moor tower once it is safe and his book is recovered.

## Encounter count and early-level pacing

**Baseline roster:** watchpost **2 goblins**; guardroom **1 goblin + 1 wolf**; common area **6 goblins** (including the ex-chief); waterfall **3 goblins**; lord's chamber **2 goblin guards + 1 wolf + 1 bugbear**; rubbish tip **1 Midden Grub**. That is **14 goblins, 2 wolves, 1 bugbear and 1 optional low-threat scavenger**, plus the captive mage.

These are **area populations, not a single combat encounter**. A straight fight through every room without a chance to withdraw, talk, rest, split forces or undermine the bugbear would likely overwhelm a level-one party. Actual combat initiative groups, map cover, escape routes and monster statistics require balancing before implementation.

Hesk, the previously encountered named road scout, is **not one of these fourteen by default**; his location, survival and possible return should depend on prior player decisions. The former chief is not Hesk. If Hesk's family is housed here, their individual identities and room locations are still open for design.

## State and discovery requirements (future implementation)

| State | Use |
| --- | --- |
| `hideout_entrance_known`, `hideout_visited` | Party discovers and enters the cave from the overland graph |
| `hideout_alarm`, `tree_watchpost_state` | Independently remember security posture and watchpost outcome |
| `hesk_fate`, `hesk_goblin_trust` | Named scout's persistent condition and impact on goblin reception |
| `former_chief_contact`, `former_chief_support` | Earned diplomacy and possible goblin uprising |
| `bugbear_lord_fate` | Alive, defeated, fled, captured, killed or otherwise displaced |
| `waterfall_guard_state`, `guardroom_state` | Defenders do not respawn just because the party leaves and returns |
| `bugbear_dwarf_capture_orders_known` | Whether the party has actually discovered the standing orders to seize dwarves from caravans |
| `dwarf_prisoner_transfer_evidence` | Credible evidence of transfers from the hideout to the high-moor tower; independent of merely knowing a dwarf is missing |
| `named_dwarf_captive_states` | Individual captive identities, conditions, whereabouts and rescue/transfer history; a proposed structured registry, not an implemented flag |
| `mage_captive_state`, `mage_recovery` | Distinct captivity, release, recuperation and whereabouts |
| `rubbish_tip_discovered`, `midden_grub_state` | Original scavenger's fate independent of main enemies |
| `rubbish_shaft_noticed`, `rubbish_shaft_examined` | Record the hole and what was learned, without revealing an unauthored destination |
| `hideout_local_map_nodes` | Which connected chambers and the lord-to-waterfall tunnel have actually been discovered |

Flags are a **proposed schema**, not assertions that these events work today. Record the chronological event history, clue certainty, NPC attitudes and promises in the existing `CampaignState`. Discovery on the **local dungeon map** must be gated by actual knowledge, so unreached rooms, the hidden watchpost, the private connecting tunnel and the bottom of the refuse shaft are never pre-revealed.

## Story art and presentation direction

Every main narrative location should eventually have a large static image in the central screen, later replaceable with animation. Particularly important compositions:

- **Cave exterior:** a jagged opening in a pale limestone cliff with dark woodland and hanging roots; the tree watchpost remains subtly hidden if the party has not spotted it.
- **Long corridor:** rough limestone walls, deep perspective and a distant misty blue-white glow from water.
- **Rubbish tip:** heaps of torn sacks, bones and broken pots around a **black hole in the limestone floor**; a seemingly inert mound conceals the scavenger.
- **Underground waterfall:** white water plunging through a dark vaulted chamber, wet rock ledges and sentries barely visible through mist.
- **Common area:** dirty cooking fire, bedding and downtrodden goblins; ex-chief identifiable in dialogue rather than by omniscient visual cue.
- **Bugbear chamber:** intimidating bugbear overlord in a torchlit limestone lair, two guarded approaches, a wolf and the thin chained mage in a corner.

This dungeon is designed for **gamebook-style narrative exploration between tactical combat encounters**. Do not build a first-person corridor crawler. The art should never reveal a secret the party has not discovered (such as the otherwise hidden watchpost).

**Relationship to current build:** The overgrown ravine is a playable v0.8 location. The tree watchpost, cavern complex, original Midden Grub, goblin ex-chief, bugbear lord, prisoner rescue, waterfall tunnel and refuse shaft are **design-only** as of this document.
