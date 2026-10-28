# Campaign Story Bible — The Silence Beneath the Dales

**AUTHOR-ONLY / SPOILERS — DESIGN MATERIAL, NOT PLAYER-FACING TEXT AND NOT IMPLEMENTED GAMEPLAY**

This document records the setting author's central campaign premise and how it should be revealed through the narrative-adventure engine. It must not be automatically loaded into exploration descriptions, overland maps, item tooltips, NPC dialogue, or other player-visible content.

## Established truths (from the setting author)

1. **The ore supply is faltering.** Deliveries of ore, precious metals and gems from the Dales' substantial dwarven mines have become sporadic. This is more than ordinary caravan losses: the pattern begins at, or is tied to, the mines themselves.
2. **The dwarves deny a problem.** The mining communities insist that all is well, even though the irregular shipments and conflicting accounts suggest otherwise. Their motives may include protecting their people, avoiding panic or preserving a difficult containment effort; the specific policies and individuals involved remain to be authored.
3. **Something was uncovered underground.** Deep excavation breached or discovered *something in the darkness*. Those who encountered it have attempted to contain it. Their containment is failing or endangered, and its escape could threaten the wider Dales. **What it is remains deliberately undefined.** Do not silently turn it into a known demon, undead god, magical disease, ancient machine, portal or conventional monster.
4. **A separate secret society is operating in the background.** Its agents intentionally undermine the region's fragile trust and truce, pursuing an undisclosed agenda which eventually draws the story into the mines. Its identity, symbolism, leadership, methods, true objective and relationship to the thing underground remain open for later authorship.
5. **These are distinct mysteries.** Banditry and goblin raids are real; guarded caravans disappearing altogether is abnormal; output from the mines is increasingly irregular; underground containment is endangered; and agents are fomenting social conflict. They may overlap, but the story must not presume one explanation accounts for all five.

## Who knows what

| Perspective | Initial believable knowledge | Secrets or uncertainty |
| --- | --- | --- |
| Merchant Tavian Marr | Shipment schedules have become erratic; escorted convoys are missing without survivors | He cannot prove whether the trouble begins at the mines, on the road, or both |
| Harrowford guild and traders | Trade deliveries have grown unreliable; jobs and prices are changing | They may blame bandits, goblins, striking miners or political rivalries prematurely |
| Dwarven mine representatives | Publicly maintain that nothing is wrong and the work continues | Some dwarves know parts of the discovery and the attempted containment; do not make all dwarves complicit or omniscient |
| Woodland elves and local farmers | See forest and land-use disputes, pressure for timber and disrupted trade | Someone may exploit genuine grievances without creating them from nothing |
| Lord Osric Vale and local power brokers | Want influence over security, ore rights, tolls and public opinion | Whether any particular official knowingly helps the secret society is not decided |
| Goblin raiders and Hesk | Know their immediate lair, raids and personal loyalties | They need not understand the deeper mine mystery or society |
| Secret-society agents | Have an agenda to destabilise the Dales, with actions tending toward the mines | Their origin, final objective and knowledge of the underground threat are deliberately undefined |
| Player party | Initially knows Marr's commission and the exceptional caravan disappearances | Should discover each deeper connection through play, never from an omniscient narrator |

## Reveal ladder — avoid premature exposition

**I. A routine danger that isn't routine:** The four-goblin wagon ambush initially looks like common road crime. Observant players notice incomplete cargo records, unusual absence of teamsters, or signs that some disappearances are more systematic than normal raids. Hesk may be a consequential survivor, not an all-knowing exposition device.

**II. Economic symptoms:** At Harrowford's twice-weekly ore market, wagoners complain of missing consignments and miners' brokers speak evasively of delayed shifts. The Stoneweight Trading Post's recorded weights may disagree with what merchants received. An honest trader might insist the mines are producing plenty while someone else's ledger shows otherwise. The players should be free to investigate ore supply as a separate thread from goblin tracks.

**III. A wall of silence:** The party meets dwarven representatives who minimise the shortages. A dwarf might privately seek assistance or reveal evidence of sealed lower workings. Opposition or secrecy should feel like hard decisions made by individuals under pressure, not a claim about every dwarf's morality.

**IV. The fragile peace frays:** Land disputes intensify, woods are felled or sabotaged, miners accuse traders of theft, farmers blame woodland guardians, and credible evidence suggests some incidents were staged or deliberately exacerbated. Let players solve smaller local problems before learning that unseen agents were involved. The actual grievances must remain real.

**V. Following the trail:** Recovered records, testimony, unusual ore, absent miners, damaged cave entrances, or an agent's misstep point towards deeper workings. The campaign can approach the mines by different alliances, permissions, smuggling routes or discoveries, not exclusively by a boss fight.

**VI. The truth in the darkness:** The later campaign reveals what was uncovered, why containment has become unstable, and what the society seeks. Preserve the author's freedom to define the entity, ancient history, faction and ending. Earlier scenes should not accidentally contradict that reveal.

These are pacing guidelines, not prescribed chapter numbers or a linear quest chain. Discovery may come in a different order. The adventure engine must support revisits and variable quest states.

## Sample player-facing hints (safe to use, not proofs)

- **Merchant's ledger:** "Marr turns a page and taps the gaps between deliveries. ‘A missing wagon I can understand. A mine that sends three loads one month and none the next? They tell me the seams are sound.’"
- **Harrowford market:** "The weighhouse's scales stand idle beside carts that ought to be filled. A trader shrugs. ‘They say the workings are sound. The ore doesn't arrive the same way anymore.’"
- **Dwarven representative:** "‘There has been no collapse,’ the foreman says. ‘No sickness, no invasion. Our mines are our concern.’ He will not meet your eyes when you ask about the sealed lower road."
- **Forest dispute:** "A felled oak lies across the path, its cutting too neat for a storm. The woodsmen blame the elves. The elves blame the new survey. Neither explains the unfamiliar tool marks."
- **Unsettling evidence:** "Behind a copied manifest, someone has added a second list of cargo and destinations in a different hand." (Does not confirm society involvement.)

These are possible lines. Do not treat the exact wording or characters as final canon without author approval.

## Core design principles

- **Do not spoil the mystery** in the starting illustration, map, journal, hidden-choice controls, hover states, loading tips, item names or a leaked adventure flag.
- **Multiple leads; no mandatory single check.** Track goblin trail, caravan paperwork, ore deliveries and local politics as separate investigation routes. A failed roll may change cost/time/relationships without ending the campaign.
- **Player agency and faction nuance.** Helping elves limit destructive logging may cost timber supply; aiding miners may gain access but risk social suspicion; questioning the mine's official narrative need not mean treating every dwarf as an enemy.
- **Do not imply all bandits are society agents, all goblins responsible for the disappearances, or all dwarves knowingly lying.** The degree of connection is a late-campaign choice for the author.
- **Separate knowledge and truth.** A witnessed rumour is recorded as rumour; a confirmed fact is marked as confirmed. An overland map shows known access, not secret lower tunnels because their coordinates exist in content files.
- **Consequences can recur.** Hesk may help or hinder; a merchant or rival farm might appear later; rescued dwarves may provide access to lower levels. Record stable NPC identities, dialogue choices and reputations.
- **Use same rules runtime.** Appropriate Survival/Investigation/Insight/Persuasion and tool checks can reveal leads; failure need not be binary. Combat damage, healing and conditions persist across narrative scenes.

## State/quest hooks for future implementation (not active schema)

- `marr_commission_accepted`, `caravan_disappearances_investigated`
- `ore_delivery_irregularities_noticed`, `mine_foreman_denial_heard`
- `ore_ledger_clue_found`, `mine_lower_workings_rumour`
- `woods_land_dispute_status`, `dwarven_trade_trust`, `elven_woodland_trust`
- `staged_conflict_evidence`, `society_involvement_suspected`
- `containment_evidence_discovered`, `mine_lower_access_known`
- Hidden author truth: `mine_discovery_secret`, `containment_status`, `society_true_agenda`

These are labels for future planning. Do not use author-truth values as player-visible flags or map notes. Persistence, branching checks and faction reputation are not yet implemented.

## Questions intentionally reserved for the setting author

- What did the miners discover and where, and what is threatening containment?
- Who knows the truth among the dwarves, and what has happened to those who tried to speak?
- Is the society attempting to exploit, open, control or prevent the underground threat—or pursuing a different goal?
- Which disruptions to the fragile peace are manipulated, and which are genuine?
- How do the caravan disappearances relate to the slowdown of ore deliveries?
- What are the society's name, signs, methods and senior agents?
- What moral compromises and alternative endings will be possible once the truth is known?

**Implementation boundary:** This is a story bible, not executable adventure content. The existing v0.7 encounter remains a goblin wagon ambush with a merchant commission. The mines' true secret and secret society are not currently simulated, and a complete open-world quest or map has not yet been built.
