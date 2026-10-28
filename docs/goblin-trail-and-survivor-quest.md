# Goblin Trail, Survivor and Hideout — Narrative Quest Design

**Status: design only; not yet playable.** This expands the choice-driven exploration contract. The v0.7.1 combat build now gives **Hesk, Roadwatch** Death Saving Throws, permits melee Subdue and supports first aid and Cure Wounds after the battle. Full story choices to interrogate, bargain, release, take prisoner or respond to the lair are still not implemented.

## Meaningful choice after the wagon ambush

After victory, the party may investigate the goblin hideout **or leave for town**. Neither choice forecloses the other. The wagon clearing is marked visited on the overland map and can be travelled back to after visiting town. All clues, attempts, loot and NPC fates persist and affect the description on a later visit.

The hideout can be found through several independent paths:

1. **Tracking:** Wisdom (Survival), reading footprints, dragged cargo and signs of passage. Failed attempts are remembered; no infinite free rerolls. A failure is not a permanent quest blocker.
2. **Investigation:** the wagon, its scattered cargo or forest edge may reveal an alternative clue, using Perception or Investigation as appropriate.
3. **Survivor conversation:** a living goblin may reveal partial or reliable directions, depending on negotiations and trust.
4. **Town witness:** Mara Venn, a wagoner previously robbed on this road, can tell the party where the northern ravine track goes and offer an optional quest and reward. **Her usable lead is not gated behind another mandatory skill check**, even if the party failed tracking or killed the survivor.

An undiscovered hideout is not marked as a freely accessible map destination. A suspected lead may be scribbled on the map; acquiring reliable directions unlocks a route, and entering the cave marks it explored.

## The wounded scout

A provisional goblin survivor, **Hesk**, knows the route but fears for his mate and younger sibling at the lair. Not everyone in the caves is a raider. He has a believable reason to withhold information from adventurers who might harm his family.

A goblin at zero HP cannot be healed if the combat engine has already marked him **dead**. Hesk now has a special survival/dying state, with playable First Aid and Cure Wounds after battle. Full prisoner dialogue, release and quest outcomes are still to be built. Stabilisation alone does not make a 0-HP creature conscious. Stabilising a dying creature does not automatically make it conscious; actual healing must use the requisite item or spell resources.

Possible actions when Hesk is genuinely alive include stabilise, heal, provide water, question him, promise protection, bargain, threaten, take prisoner, release, leave, or kill. He may provide a clue if capable of speaking, but healing does not purchase automatic loyalty.

## Release produces TWO separate consequences

**Security/readiness and diplomatic attitude must be independent.**

- **Lair readiness:** unalerted, suspicious, alerted, fortified. If Hesk reaches home and warns others, goblins may occupy cover, barricade the entrance, relocate children, post sentries, call help and prepare to fight. The party cannot surprise defenders as though they were unaware of its approach. The precise Surprise and initiative resolution must follow our 2024 Classic 5E rules implementation.
- **Lair attitude:** hostile, wary, receptive, cooperative. If the party treated Hesk well, kept credible promises, and offered protection for his family, he might argue that the guards should take them to the leader rather than attack. An unfriendly leader may still refuse.

**These are not mutually exclusive.** Alert sentries may hold bows ready **and** escort the party to a meeting. Releasing him can create both a tougher possible battle and a new diplomatic opportunity.

| Party treatment and release | Likely readiness | Possible attitude | Consequence |
| --- | --- | --- | --- |
| Threatened or deceived Hesk | Alerted/fortified | Hostile | Prepared defenders; surprise advantage lost |
| Healed him, listened and kept a promise | Suspicious/alerted | Receptive | Guards are watchful but may grant an audience |
| Released him without terms | Suspicious | Wary | His report may be incomplete; other events shape the leader's response |
| Threatened his family | Fortified | Hostile | Hesk warns and may move his family to safety |
| Protected his family or demonstrated a shared cause | Alerted | Cooperative | Hesk may help negotiate a ceasefire or lead the party through a safe approach |

These outcomes are authored possibilities, **not** fixed moral rewards. He may be frightened, unreliable or mistaken. A party can face armed guards and still be permitted to talk.

### Representative scene variants

**Prepared for war:** The cave approach has fresh barricades. Goblin archers watch from narrow openings; someone has warned them about armed travellers.

**Cautious parley:** Spears point towards the party, but the sentries do not advance. One says, “Hesk claims you kept your word. The chief will hear you—without drawn weapons.”

**Both:** The lair is fully alert. Behind the armed sentries stands Hesk, urging them to let the party explain its intentions.

These scene states must be determined by world flags and prior decisions, not random flavour text.

## Other prisoner outcomes

**Captive:** Hesk has not run ahead to alert the hideout. Keeping him prisoner creates consequences involving custody, provisions, town authority and possible rescue.

**Killed:** His death is remembered. His family may learn about it, affecting future dialogues. Tracking and the town witness still make the hideout reachable.

**Released:** Hesk's whereabouts, promises, family and warning behaviour update. He is not automatically a companion.

**Left dying:** Later survival depends on actual stabilisation, time and possible intervention; the story must not pretend he was deliberately released.

**Promise broken:** A false offer of family protection can close a diplomatic path, even if it once helped acquire a lead.

## The goblin lord's employer and the two lost prisoners — author spoilers

The goblin lord is **taking payments from the secret society to disrupt Old Trade Road traffic**. Not all raiders know why, and Hesk's family and the lair's noncombatants retain independent motivations. Parley, capture or combat can expose part of the payment arrangement. The goblin lord's name and individual history remain unassigned.

A previous convoy's **malnourished mage is chained alive in the goblin hideout**. Another captive, a **dwarf trader**, has already been transferred to an old **high-moor tower** by agents of the society, who are torturing him for information about the mines. The mage's missing **spellbook went with the dwarf to the tower** and is not in the goblin hideout. These characters and the unique book each need their own state and ownership history. Two captives survived the raid, but **no survivors returned to civilisation**, consistent with the merchant's alarm.

Rescue and treatment of the mage should be a narrative interaction, not an instant recruited party member. The spellbook can later be recovered as a **quest object** and returned to its owner. This may lead him to offer magical services in Harrowford after recovery, on appropriate terms.

A distinct clue at the tower must implicate **Lord Osric Vale**, unlocking political choices to expose, constrain or unseat him. The tower is a **high-moor location**, not Seabrook's ruined coastal keep. These further adventures should be discoverable from multiple leads, with the route back to Harrowford and the wagon still available.

See the full **author-only** design: [Paid Raiders, Moor Tower and Manor](campaign-arc-goblins-tower-manor-spoilers.md). This section, and all its objectives, are **not yet implemented** in the choice-driven exploration engine.

## Quest: Road Raiders

Mara Venn in town can offer an optional reward for stopping the caravan attacks. Potential resolutions include defeating the raider chief, rescuing caravan captives and disrupting raids, or reaching a credible ceasefire. A nonviolent resolution should be possible without making all goblins good or all adventurers evil. Quest completion and reward collection are once-only, whichever route is taken.

The clearing remains a returnable location. Visiting town first may unlock new dialogue or a clue at the clearing: “The wagoner's description makes sense of the gouges beside the track.” If the hideout is already known, Mara offers context rather than revealing it a second time.

Rewards follow the established low-magic policy: mainly XP and gold, some usable consumables, and no ordinary equipment rubbish.

## Discovery map

Suggested overland links:

- Old Trade Road → Wagon Clearing → Town Road → Frontier Town (accessible after the battle).
- Wagon Clearing → Northern Ravine Track → Goblin Hideout (unlocked by tracking, investigation, Hesk or the town lead).
- Frontier Town → Wagon Clearing (return travel; remains available).
- Suspected hideout locations are map notes, **not** automatic fast-travel targets.

Use parchment graph paper, ink routes, handwritten notes and discovery-based reveal. Suggested notes include “wagon ambush”, “small tracks towards ravine”, “Hesk: follow the dry stream bed” and “Mara Venn: cave beyond split rock”. Secret locations are not leaked by map geometry.

## Persistent state proposal

- wagon_clearing_visited, wagon_clearing_searched, tracking_attempt_outcome
- trail_clue_state: unknown / suspected / route_known; hideout_visited
- hesk_state: absent / dying / stable / conscious / captive / released / dead
- hesk_trust: hostile / wary / negotiating / trusting
- hesk_family_known, hesk_family_status, hesk_promised_safety, hesk_promise_broken
- hesk_warning_sent, lair_readiness, lair_attitude
- town_witness_lead_received, road_raiders_quest, visited map locations and handwritten notes

All important transitions must be persistent and applied exactly once. A choice can update readiness and attitude in the same transaction.

## Acceptance criteria for a future playable implementation

1. The party can leave for town without finding the hideout, then return to the clearing from the map.
2. Failed tracking neither reveals the route nor irreversibly loses the quest.
3. The town witness provides a reliable alternative lead without a mandatory successful roll.
4. A dead goblin cannot be healed or questioned; a living Hesk can be stabilised or healed using actual rules and resources.
5. Release can lead to **alerted defenders with no surprise opportunity**, **receptive defenders who permit dialogue**, or **both simultaneously**.
6. Conversation, rescue, threat, captivity, release and killing persist and change later scenes.
7. The party can attempt to resolve the raids via combat or an appropriate negotiated outcome.
8. The map only shows explored and genuinely discovered information; revisits and save/reload preserve it.
9. No repeat check exploit, duplicated quest reward or arbitrary equipment loot.

## Implementation order

First build the narrative node/choice graph, visited overland map, return travel and town witness lead. Add checks and persistent save/load. The Hesk survivor engine rules now exist; introduce the actual survivor conversation/release branch next. Build separate mage captivity, transferred dwarf, unique spellbook and tower evidence quests, followed by lord-related political resolutions.

Do **not** present this as working gameplay in v0.7.
## Trade-road context

The optional goblin hideout is one possible lead in the broader mystery of ore and gemstone caravans vanishing from the Old Trade Road. Even affordable merchant escorts normally include a minor mage and hired sword; wealthier convoys may hire a priest. Conventional raiding does not explain why complete parties of teamsters, guards and cargo fail to return. Track the distinction in clues and town dialogue without prematurely assuming Hesk's raiders are responsible for every disappearance. Seabrook is to the west; Harrowford is on the Dales' northern edge.
