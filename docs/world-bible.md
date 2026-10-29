# Project Azure Mines — World Bible

> **AUTHOR / DEVELOPMENT REFERENCE — CONTAINS MAJOR CAMPAIGN SPOILERS.**  
> **Version:** 0.2 | **Reconciled:** 2026-10-29 | **Canonical location:** `main:docs/world-bible.md`  
> This document is **not** player-facing text. Do not automatically expose its secrets through maps, journals, dialogue, tooltips or game data visible to players.

## 0. Authority, provenance and editorial conventions

This is the consolidated **world and narrative canon** for Project Azure Mines, not a claim that all described content is implemented. The engine and playable content may lag behind the narrative specification.

**Sources reviewed for v0.2:**
- Accessible excerpts and summaries of Project Azure Mines discussions dated **28–29 October 2026**, including the hand-drawn cave-layout discussion and the latest family-area, non-loyal patrol and elite-goblin surrender rules (29 October). The entire archive of previous chats is **not directly searchable** through the available conversation tools. Do not claim every historic message was reviewed.
- The repository's `feature/downed-sprites-action-bar` branch: its [campaign story bible](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/campaign-story-bible-spoilers.md), [Dales gazetteer](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/dales-settlement-gazetteer.md), [campaign arc](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/campaign-arc-goblins-tower-manor-spoilers.md), [cave design](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/goblin-hideout-limestone-valley.md), [goblin survivor quest](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/goblin-trail-and-survivor-quest.md), [canonical test party](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/canonical-test-party.md), [setting anchors](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/adventures/test_adventure/setting_anchors.json), [opening sequence](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/adventures/test_adventure/opening_sequence.json), [exploration locations](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/adventures/test_adventure/exploration_v08.json), [Hesk interaction](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/adventure/hesk_interaction.gd), [NPC registry](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/adventure/campaign_state.gd), [cave implementation report](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/goblin-hideout-v091-implementation.md), and encounter fixtures.
- The bootstrap contents of `main` as of the prior World Bible revision.

**Status vocabulary:**
- **Established / canon:** Explicitly agreed author direction or definitive named content. **Working name** means used in existing documents but not necessarily author-final.
- **Implemented on feature:** Present in the specified branch's narrative or combat data (not a claim it has been merged into `main` or visually playtested).
- **Planned:** Agreed story or design that does not yet have a playable implementation.
- **Optional / proposed:** Possible branch, suggested behaviour, not an inevitable canon outcome.
- **Open / recover:** Unresolved or potentially detailed in earlier conversations beyond the accessible records. **Never silently invent or overwrite these details.**

**Conflict policy:** A more recent explicit author decision supersedes an older description. Existing feature-branch content should be treated as a snapshot to reconcile, **not automatically as the latest story direction**. Record both the replacement and resulting migration work. When information appears only in author-only notes, it is **true within the setting but not automatically known to player characters**.

## 1. World overview — the Dales

**The Dales** are a richly mineralised, sparsely settled frontier of fertile valleys, lowland woodland, rugged hills, high moors, mountains and much **limestone / karst** terrain. Underground water forms caves, sinkholes, gorges and waterfalls. Modern settlements and their negotiated arrangements developed over the past few hundred years; earlier histories of these peoples and sites are **not yet fixed**.

The region's wealth comes primarily from dwarven mines producing **ore, precious metals and gemstones**. Timberwork, farming, ore weighing, crafting and transport are important supporting economies. Ore and minerals travel toward the **western coast**, while food, tools, supplies and manufactured goods flow inland.

**Social tension:** Dwarven mining and demand for timber supports, new farms and pasture, carpentry, and woodland elves' protection of the forest create genuine competing interests. A fragile truce among communities is already under pressure. No ancestry or faction is uniformly virtuous, culpable or informed.

**Public unease:** Shipments from dwarven mines have become erratic, even though dwarven representatives insist the mines are sound. This disruption is not simply ordinary goblin raiding. Whole guarded caravans have also begun to vanish with **no witnesses returning**, an escalation over the familiar risks of the Old Trade Road. Even lesser merchants tend to hire a swordsman and a modest mage; the wealthier might hire a priest.

### Geography fixed for any future map

- **Seabrook**: coastal city **west of the Dales**.
- **Old Trade Road**: the trade artery linking Seabrook to the Dales and the northern market.
- **Harrowford**: small market town on the **northern edge of the Dales**.
- **Goblin hideout**: limestone cliff in a wooded valley reached by an overgrown ravine off the road.
- **High-moor tower**: an old tower in the uplands, a **different structure** from Seabrook's ruined keep.
- Exact distances, compass bearings, names of ranges/rivers and precise political boundaries remain open.

## 2. Settlements and places

### Seabrook — western coastal city

A **small, multicultural harbour city**, chartered as a city but never adequately defended. It is a busy mixture of trade, fishing, captains, craftspeople, adventurers, smuggling, rackets and petty corruption. There is **no sound continuous city wall**; its few weather-worn watchtowers are poorly maintained or undermanned.

**Old Rookhold** (working name) is the **ruined coastal keep on a headland near Seabrook**, with collapsed roofs, breached walls and salt-flooded lower chambers. Lights, voices and disappearances are rumoured; **monsters have not been confirmed or specified**. It could be an optional dungeon/security/restoration story. **Never confuse Old Rookhold with the high-moor tower or Vale Manor.**

**Tavian Marr** is based in Seabrook and commissions the party to investigate the missing caravans, with reporting obligations in Harrowford.

### Harrowford — northern Dales market town

Modest, practical, somewhat isolated; the area's ore trading and **twice-weekly market** centre on the weighhouse. The party's first contractual destination is its Adventurers' Guild. Sites and current working names:

| Place | Function | Important notes |
| --- | --- | --- |
| **Harrowford Adventurers' Guild** | Commission reports, contracts, jobs and local mediation | Marr's contract requires a report here; report interaction exists in feature-branch exploration |
| **The Golden Stag** | Inn and lodgings | Roadside rest, gossip, travellers |
| **Wren's Sundries** | General store | Tools, rope, rations, practical supplies; an eventual real shop |
| **Bramwell Farm** | Farm outside town | Locally established family, rival to the Kestrels |
| **Kestrel Farm** | Farm outside town | Competes with Bramwells over land, market access and water; neither automatically villainous |
| **The Red Anvil** | Blacksmith | Repairs and equipment, not inexhaustible magic stock |
| **Hollis's Yard** | Carpenter | Buildings, repairs and possible paid town/tower improvements |
| **Shrine of Lethiel** | Shrine and healing refuge | **Lethiel**, working name of the local life goddess; wider pantheon not established |
| **Vale Manor** | Occupied lord's residence | The home of **Lord Osric Vale**; **not** the ruined keep |
| **Stoneweight Trading Post** | Market, ore weighing and trade records | Twice-weekly market; missing or inconsistent consignments are a key mystery |

**Layout direction:** Golden Stag near approach road, market/weighhouse in the centre, guild accessible as contract destination, workshops and shrine within town, farms beyond homes, Vale Manor overlooking the settlement. A **narrative location graph**, not a requirement for a walkable simulation. Most of these sites currently exist as design anchors, not playable shops or quests.

### The Old Trade Road, wagon clearing and overgrown ravine

The opening travels **from Seabrook eastward** along the road toward Harrowford. The four companions camp under dark pines (**The Watchfire**); at dawn they encounter a stranded **covered wagon**, scattered cargo, recent fire and four goblin raiders.

After combat the wagon clearing can be searched, tracking attempted, and the route to town followed. The party may revisit. The narrow **overgrown ravine** gives access to a wooded limestone valley and the cave approach. Mara Venn and Hesk provide alternate ways to locate the trail.

### The high-moor tower

An old tower in the **high moors of the Dales**, currently used by the conspirators as a place for prisoner interrogation and storage of seized items. **A dwarven trader is alive and being tortured for information about the mines there.** The kidnapped mage's **unique spellbook** was transported there with the trader.

Credible evidence at the tower **implicates Lord Osric Vale**. The precise artefact, tower builders, guardians and ownership arrangements are not yet fixed. Discovery must be earned through clues; the map should not prematurely reveal this secret site. An optional later outcome is a **restored tower inhabited by the rescued mage**, if he wishes it and the party addresses security, book recovery and property issues.

### Deeper mines

The dwarven mine system is a major later adventure destination. Workings include as-yet-undetailed lower areas. Important story truth is held in the **author-spoiler** section below; its nature and precise location must not be pre-emptively defined.

## 3. Named character register

### Canonical level-one test adventuring party

These are named **reference characters**, presently a deterministic four-character test party; player customisation and final biographies are not established. Stats below are from the versioned baseline fixture, not permanent fiction-defining limits.

| Name | Species / class | Combat identity | Visual direction |
| --- | --- | --- | --- |
| **Alden** | Human **Champion** | Frontline longsword + shield, defensive style; **12 HP, AC 19** | Blue clothing / armour; sword and shield |
| **Elyra** | High Elf **Evoker** | Arcane spellcaster, spellbook, **7 HP, AC 12** (15 with Mage Armor) | Red-and-gold robes, fiery staff |
| **Brunna** | Dwarf **Priest** | Mace, shield, healing/support, **11 HP, AC 15** | White/gold with mace and shield |
| **Pip** | Halfling **Thief** | Stealth, ranged shortbow and daggers, **10 HP, AC 14** | Green/brown, dagger and bow |

Their class-specific spell and equipment choices are fixed in [`docs/canonical-test-party.md` on the feature branch](https://github.com/Jonty303/Project-AzureMines/blob/feature/downed-sprites-action-bar/docs/canonical-test-party.md); initial level 1 stats are test reference data, **not** a reason to erase narrative consequences or prevent future advancement.

### Named supporting characters and divinity

| Name | Location / association | Description, knowledge and story function | Status |
| --- | --- | --- | --- |
| **Tavian Marr** | **Seabrook**, Old Trade Road | Merchant dealing in dwarven ore, metal and gems. Hires party because fully escorted caravans disappear; directs them to report at Harrowford's guild. Knows disruptions and suspicions, **not** entire conspiracy. | Working name; referenced in opening and adventure data |
| **Mara Venn** | **Harrowford**, Stoneweight market | Wagoner who has suffered goblin raids; credible witness and **guaranteed alternate ravine lead** if tracking fails; offers optional **Road Raiders** quest/reward. | Named, partially implemented with persistent attitude |
| **Hesk, Roadwatch** | Opening **wagon ambush**; possible later hideout | Named **shortsword-and-shield goblin scout**; worries about his **mate and younger sibling** among goblin families. Can be downed, treated, questioned, spared, restrained, released, left or killed. Knows cave route and that bugbear commander displaced old chief, but not sponsor's identity. | Named, combat + post-battle interactions implemented |
| **Lord Osric Vale** | **Vale Manor, Harrowford** | Entitled/self-interested local lord. **Actually implicated** by high-moor tower evidence, but the degree of his complicity, knowledge, motivation and formal society membership is still open. Should be susceptible to political as well as violent resolutions. | Working name and established conspiracy connection; later quest design |
| **Lethiel** | **Shrine of Lethiel, Harrowford** | Proposed **goddess of life**; associated with healing and refuge. No wider dogma/pantheon fixed. | Working divine name, not a mortal NPC |

**Important distinctions:** `Goblin Lookout`, `Goblin Sentry`, `Goblin Cave Guard`, `Goblin Cutpurse`, `Goblin Archer` and `Goblin Bowshot` are **combatant labels**, not established personal names. Do not treat a role label as the proper name of a newly authored NPC.

### Important unnamed individual NPCs — do **not** invent names

| Individual | Location | Established identity and function | Next authoring need |
| --- | --- | --- | --- |
| **Bugbear overlord** | Private cave chamber | Cruel outsider imposed and funded by society, commands raids, orders dwarf captures for the moor tower. **Will not bargain or release mage willingly**. | Personal name, appearance, history, exact defeat outcomes |
| **Displaced former goblin chief** | Shared kitchen / sleeping cave | Older goblin now among ordinary inhabitants after bugbear's takeover. May help an uprising if trust/security justify it. | Name, history, relationship to Hesk and cave factions |
| **Non-loyal corridor patroller** | **Newly added corridor** in latest hand-drawn cave discussion | Not a bugbear loyalist; party may talk its way past. | Name, appearance, precise corridor node, dialogue and state |
| **Guardroom goblin** | Guardroom, with wolf | Armed keeper of side chamber; current combat fixture is one goblin plus wolf. | Name, loyalty (new elite rule may require redesign) |
| **Two family-area loyalists** | **New family area** | Bugbear-aligned armed enforcers among women and children; these two can fight, families do not. | Names, combat tactics, placement and surrender conditions |
| **Captured human mage** | Chained in bugbear's chamber | Malnourished, frightened, missing spellbook. Needs freeing, care and recovery before later service choices. | Name, background and book's identifying name/details |
| **Captured dwarven trader** | High-moor tower | Alive and tortured for mine information. What he knows is **not assumed**. | Name, trade history, credible knowledge, possible rescue outcomes |
| **Other local people** | Harrowford and Seabrook | Guild clerk, shopkeepers, farmers, smith, carpenter, shrine keeper, retainers and traders may be developed later. | Personal names and personalities beyond business names |
| **Secret society agents** | Road raids, tower, wider region | Pay the bugbear and destabilise regional relationships. | Society name, agents, symbol, goals, leadership |
| **Wolves** | Guardroom and bugbear chamber | Two large cave wolves in earlier cave roster; only guardroom wolf currently fightable. | Whether named or simply creatures; no invented names |
| **Midden Grub** | **Former** rubbish tip (see new change below) | Original small pale plated scavenger, defensive rather than malicious; mandibles, low-level optional fight. | Fate/relocation due to family-area redesign |

**Names must not be assumed missing from history merely because no personal name is visible in the inspected files.** This register distinguishes known names from unresolved identity.

## 4. Factions, loyalties and social stakes

### The secret society — author-only truth

Agents from a deliberately **unnamed and unidentified organisation** financially support and **installed the bugbear** to disrupt the Old Trade Road. He is specifically ordered to **identify dwarves during caravan attacks, seize them alive where possible, and transfer them to the high-moor tower** for questioning. The society is manipulating existing disputes to fray trust across the Dales. Its actual endgame, identity and relationship with the threat beneath the mines remain open.

### The goblins are **not** a single hostile faction

- **Bugbear and loyalist / elite goblins:** Armed enforcers exerting control and carrying out raids.
- **Ordinary / non-loyal goblins:** Might be pressured into service, frightened, angry or persuadable, rather than willing diehards.
- **The former chief:** Potential leadership alternative to the bugbear; not guaranteed to regain rule.
- **Hesk:** His trust, mate, younger sibling and promises are personally consequential. Even if released with goodwill, he may still warn defenders.
- **Women and children:** Explicit **non-combatants**; harming them is a grave moral choice with repercussions for wider goblin attitudes and potential surrender.

### New cave combat and surrender direction — **29 October, latest author decision**

1. In each applicable cave **goblin combat encounter**, at least one **elite aligned with the bugbear** should be present (some groups may have more).
2. If the party defeats/kills the loyalist enforcers, remaining **ordinary goblins may surrender** and be resolved through a **narrative post-battle** scene.
3. Surrender is **conditional**, not automatic: attacking goblin families, broken trust or failing to earn enough confidence can prevent surrender and produce long-term hostility.
4. **Two** loyalist combatants are placed in the newly designated **family area**; its women and children **do not fight**.
5. The new **corridor patrol** is specifically **non-loyal** and can potentially be talked past.
6. Do not conflate **combat result**, **goblin trust**, **lair alert** and **control of the cave**. Model these independently. The Midden Grub and wolves are non-goblin creatures; this faction-driven surrender rule should not nonsensically make animals surrender.

**Reconciliation required:** The existing watchpost has two generic goblins, while the old guardroom battle contains only one goblin and a wolf. Neither fixture currently specifies an elite-loyalty role or conditional ordinary-goblin surrender. New encounter composition and persistence are needed. The latest instructions do **not** imply that any defeated goblin automatically survives or surrenders; the conditions must be authored for each scene.

### Security is not the same as attitude

Hesk released alive may warn the cave and make it **alert or fortified**. If treated well, he may simultaneously recommend parley. The tree-watchpost alarm is another separate signal. A well-defended cave can be receptive to conversation; an unalerted cave may still be hostile. Trust, promises and family casualties must persist between rooms and revisits.

## 5. Goblin hideout — room register and evolving plan

The **latest hand-drawn map shared on 29 October 2026** is a higher-priority layout reference for changes to room functions and the added patrol corridor. The descriptions below distinguish that discussion from the older implemented feature branch.

| Area | Physical description / inhabitants | Design and implementation state |
| --- | --- | --- |
| **Wooded valley approach** | Cave mouth in rocky limestone wall in wooded valley; **two concealed tree sentries** watching trail | **Implemented on feature**: perception, stealth, counter-ambush, fight and guarded verbal entry |
| **Entrance and first passage** | Damp limestone entrance; long interior route | **Implemented on feature** |
| **Main corridor** | Long passage with branches; sound of underground falls in distance | **Implemented on feature**, but branch path choices must be checked against latest drawing |
| **New patrolled corridor** | One **non-loyal** goblin patrol; potential dialogue passage | **Latest agreed change, not implemented on inspected feature** |
| **Guardroom** | **One goblin and large wolf** | **Implemented battle**; goblin's elite/loyalty role needs reconciliation |
| **Common kitchen / eating / sleeping chamber** | **Six goblins in older documented roster, including displaced older former chief** | **Implemented conversation/observation**; ex-chief alliance/uprising not resolved or playable |
| **Family area (formerly rubbish tip)** | **Goblin women and children**, **two bugbear-aligned armed goblins**; women and children are non-combatants | **Latest agreed replacement** of old rubbish-tip room; **not yet reflected in feature** |
| **Former rubbish tip / Midden Grub** | Original refuse dump, low-threat scavenger and open rubbish shaft | **Implemented older optional encounter**; **superseded as a room purpose** by family area; grub's new home and hole's continued presence are **open** |
| **Underground waterfall** | Water falling into dark chamber with wet ledges and **three guards** near another passage | **Implemented scouting only**; tactical confrontation not yet playable |
| **Bugbear's chamber** | Bugbear, **two goblin guards**, **second wolf**, malnourished **human mage chained in corner** | **Implemented scouting from outside**, but boss battle, mage rescue, prison outcomes not playable |
| **Private waterfall tunnel** | Secondary route between waterfall and bugbear chamber | Older documented physical connection; guarded/partially glimpsed; not a fully accessible gameplay shortcut yet |

**Older population baseline (not a current final tally):** 2 tree sentries + 1 guardroom goblin + 6 common goblins + 3 waterfall guards + 2 in boss chamber = **14 goblins**, **2 wolves**, **1 bugbear**, optional **Midden Grub**, plus imprisoned mage. **Do not perpetuate 14 as the new canonical population**: the added corridor patroller and two family-room enforcers, and the refit of the former tip, require a revised roster. Likewise do not silently subtract existing families or invent their number.

### The former rubbish shaft and scavenger — design conflict to resolve

Previously, goblins threw most rubbish into **a hole in the floor**, descending to **undefined depths**. It was intentionally left for a future dungeon connection. The **Midden Grub** was an original, modest, mostly avoidable scavenger of that space (initial proposed stats AC 11, HP 9, mandibles +3 / 1d4+1). That fight **currently exists on the feature branch**.

On **29 October**, the author converted the rubbish-tip **room** into a **family area**, without explicitly settling whether the hole remains, where refuse is now discarded or whether the Grub relocates. **Preserve these as open continuity questions**, not automatically delete the potentially useful shaft or place a monster among children. The latest family-area purpose and non-combatants take precedence over older location descriptions.

### Story approach and consequences

- **Tree watchers** may attack, be ambushed, be avoided, or be asked for guarded passage. Current implemented dialogue: **Persuasion DC 13** (family-protection promise and Hesk's release can give Advantage) or **Deception DC 15** (unverified claim of an important message).
- The **non-loyal corridor patrol** is a new social bypass opportunity, not a default enemy.
- The **former chief** could help end bugbear control if party trust and safety make rebellion credible. An uprising is not automatic, and the bugbear himself does not negotiate.
- Ordinary goblins may **surrender after elites fall**, conditional on how the party has behaved. Defeat is followed by **narrative choices**, not an action menu attached to the victory results screen.
- The **mage** needs care and time when rescued; removing restraints does not make him a fresh combat character.
- The **rubbish shaft**, should it remain, is an unknown feature; do not author an invented lower map/exit until decided.
- Players can explore out of order, withdraw, return and cause different cave reactions.

## 6. Opening and early quests

### Commission: missing caravans

**Patron:** Tavian Marr of Seabrook. **Contract:** investigate the unusual disappearance of entire escorted caravans carrying dwarven mineral wealth, and **report to Harrowford Adventurers' Guild**. The party does not yet know the true cause.

**Opening battle:** Four goblins against Alden, Elyra, Brunna and Pip at a covered wagon. **Hesk, Roadwatch** is the named sword/shield raider; other enemy labels are Cutpurse, Archer and Bowshot. The prototype awards **200 XP total (50 per hero)** and **12 gp**, once. These are balance/implementation figures, not an economic law.

**After battle:** The victory screen reports the encounter, then gameplay moves to the **wagon clearing** for the narrative investigation, Hesk treatment/conversation, and returnable travel. The player may search the wagon (**Investigation DC 12**), follow tracks (**Survival DC 12**), or go to town. Skill outcomes are saved and cannot be endlessly rerolled.

### Hesk's conditional fate

- **Survival:** May be unconscious/dying at zero HP, stabilised with Medicine, or knocked out nonlethally; a truly dead Hesk **cannot be revived by ordinary healing**. Brunna may spend a Cure Wounds slot, and first aid is mechanically resolved.
- **Conversation:** Knows about the displaced chief and outsider commander and may supply the route. Hesk's mate and younger sibling make family protection a meaningful promise.
- **Resolution:** Release, bind as prisoner, leave or kill, each with different later repercussions. **Release can raise lair alert independently of a more receptive attitude.**
- **Scope:** The first conversation and resolution choices are implemented on the feature branch. His actual later appearance, family reunion, and wider cave reaction remain to be authored.

### Quest: Road Raiders

**Mara Venn**, encountered at Harrowford's **Stoneweight market**, can disclose the northern ravine as an alternate route even when tracking failed. She offers a quest to deal with the road raiders. Potential success routes include ending raids, a negotiated settlement or rescuing prisoners. Avoid reducing it to mandatory extermination. Once-only rewards and completion conditions need completion; basic acceptance exists in the feature implementation.

### Secondary threads / investigations

- **Mining supply:** Sporadic deliveries, inconsistent ledgers, dwarven public reassurances, clues to sealed workings.
- **Caravan absence:** Whole convoys unaccounted for; raids are one possible part, **not automatically all** of the answer.
- **Local tensions:** Timber, logging, farms, miner needs, elves, trade and manufactured grievances.
- **Goblin power struggle:** Hesk, former chief, enforcers, family safety, possible uprising and differing surrender.
- **Mage and dwarf:** Rescue two separate people from two separate sites; recover a **unique spellbook** from the tower.
- **Vale:** Collect credible evidence and decide on a proportionate political or more confrontational resolution.

## 7. Author-only major campaign spoilers — truth not initially known by the party

### The five related but distinct mysteries

1. **The mining crisis:** Ore, metals and gems are arriving sporadically from dwarven mines, **independently** of road attacks.
2. **The containment secret:** Deep dwarf excavation uncovered **something in darkness**. Some dwarves tried to contain it; that containment is in danger. **The nature of the discovery is intentionally UNDEFINED.** Do **not** replace this unknown with a demon, portal, disease, ancient machine or conventional monster without author approval.
3. **Unreliable public claims:** Dwarven representatives insist all is well, but only some individuals may know the truth, and their motives for silence vary.
4. **Manipulation:** An unnamed **secret society** is covertly exploiting real social friction and paying the bugbear to disrupt the road and specifically capture dwarves.
5. **Unusual disappearances:** Ordinary goblin banditry cannot yet be assumed to explain all missing protected caravans.

These mysteries overlap but must remain **separate investigative threads** until evidence supports stronger connections.

### The early conspiracy trail

`Wagon ambush / road clues` ↔ `Harrowford / guild / traders` → `Goblin hideout / bugbear / captive mage` → `High-moor tower / captive dwarf / stolen spellbook / Vale evidence` → `Harrowford political response and further mine leads`.

This is a **network of leads, not a forced quest sequence**. The party may reach Harrowford before following the trail, revisit old areas, reach the tower through independent evidence, or postpone portions.

**Confirmed author truth:**
- Society agents **paid and installed** the abusive bugbear.
- His standing orders call for **seizing dwarven travellers alive** during attacks and transferring them to the tower.
- The previously captured **dwarven trader** was taken to the tower and tortured for information on the mines.
- A **mage** from the same attacked caravan remains alive, chained and malnourished in the bugbear's lair. His **spellbook** went to the tower **with the dwarf**; it is not random cave loot.
- **Lord Osric Vale is implicated** by credible tower evidence; he is **not established as the society's leader**, nor is his exact involvement settled.
- A rescued mage may eventually provide paid **magical services** if his safety, healing, consent and recovered spellbook justify it. He might instead choose to inhabit the **restored high-moor tower**, remain in town or leave; no route is automatic.

**Later author choices intentionally left open:** What lies below the mines; what the society wants; its name, symbol and leadership; why the mage's book was taken; what each captive knows; the specific evidence against Vale; which dwarves know the containment story; and the final political and moral resolutions.

### Lord Vale — possible resolutions, not a fixed villain battle

After credible evidence is found, the party may **confront**, **expose**, **constrain**, **unseat**, **bargain/collude**, or **defer**. Each route should affect relationships, local power and possible access to mine-related information. Do not force an assassination because a single persuasion check fails. An occupied **Vale Manor in Harrowford** is not the ruin at Seabrook and not the high-moor interrogation tower.

## 8. Economic and interactive-world direction

- **Narrative exploration rather than first-person grid movement:** authored scenes/choices, conditional descriptions, NPC conversation, checks, revisits, discovery-based map and journal, tactical combat launched from narrative.
- **Town matters:** supply shopping, healing, lodging, blacksmithing, trade, quests, optional restoration and later magical services should make gold worthwhile.
- **Sparse loot:** standard battered goblin weapons, torn armour and corpse-vendor trash are not routinely collected. Rewards normally favour **XP and modest gold**, with occasional useful consumables.
- **Rare magic:** named, distinguishable, mechanically inspectable items; occasionally sold or deliberately placed, never guaranteed from every fight. Merchant stock, time-based restocking and inventory need persistent state when implemented.
- **Journal truthfulness:** identify rumours vs suspicion vs confirmed evidence. Map only locations honestly discovered; do not leak concealed watchposts, tower, underwater passages or secret mine levels.
- **Persistent consequences:** HP, spells, NPC fate, trust, grievances, promises, quest state, once-only rewards and observed choices survive revisits/save-load.

## 9. Implementation snapshot and backlog reconciliation

**Inspected branch:** `feature/downed-sprites-action-bar` at commit `4d8300af3e25b63a5c34fb37c02ec19562815a30` on 2026-10-29. **The contents are not assumed merged to `main`.**

### Implemented in that branch

- Four level-one party members, tactical combat and opening wagon battle.
- Hesk's survivability, postbattle narrative first aid/Healing/Cure Wounds, dialogue, family promise and distinct fate choices.
- Pooled gold/XP, individual encounter rewards, persistent campaign state, map, journal, checks and one-slot save/load **outside combat**.
- Wagon clearing, northern road, Harrowford guild, Stoneweight market, ravine, wooded cave approach, watchpost, entrance, branching cave corridor and several room visits.
- Tree watchpost stealth/parley/combat; guardroom goblin-and-wolf combat; optional original Midden Grub fight; scouting the common goblins, waterfall and bugbear's chamber.
- **Not implemented:** actual loyalist surrender system, latest family-area conversion, new corridor patrol, full ex-chief uprising, waterfall fight, bugbear boss defeat, mage rescue, high-moor tower, dwarf rescue, spellbook recovery, Vale resolution, functional Harrowford shop/inventory.

### Priority migration from the latest chat decisions

1. **Replace** the rubbish-tip narrative scene with the **goblin family area** and **two loyalist fighters**, with noncombatant protections and consequences.
2. Add the **patrolled corridor** containing one **non-loyal, negotiable** goblin and reconcile the hand-drawn map's precise connections.
3. Classify goblin combatants by **loyalty/elite role**; restructure fights and implement **conditional surrender** and post-battle narrative.
4. Persist **family harm, promises, trust, elite death/survival, ordinary surrender and leadership change** without conflating them with cave alert.
5. Decide where the **Midden Grub** belongs now and whether/how the old **refuse shaft** remains; retain both as continuity issues until decided.
6. Extend ex-chief, waterfall and boss story, followed by genuinely playable **mage rescue** and later high-moor tower arcs.
7. Complete town economy, inventory, shops with items, and appropriate future character progression.

### Canon-versus-build discrepancy register

| Topic | Older feature-branch state | Latest / authoritative direction | Action |
| --- | --- | --- | --- |
| Rubbish room | Refuse tip, Midden Grub, shaft | Goblin **family area**, two loyalist goblins and noncombatants | Re-author scene and encounter; decide grub/shaft |
| Interior corridor | No standing patrol specified | **Non-loyal patrolling goblin**, possible talk-through | Add authored location and actor |
| Goblin combat | Watchpost/guardroom kill-all victories | **Elite loyalists** can trigger **ordinary goblin surrender**, conditional on trust | Rework composition and encounter ending |
| NPC outcomes | Hesk personally persists; others mostly static | Faction-wide reactions to family harm and treatment | Extend campaign state and narrative |
| Named setting | Present in feature docs and opening JSON | Consolidated here on **main** | Keep names consistent; do not invent |
| Hidden plot | Extensive author-only sources on feature | Spoiler canon carried over; player disclosure gated | Continue to prevent leaks |

## 10. Open questions and recovery index

### Decisions not resolved by inspected material

- Proper names and deeper biographies of the **bugbear**, **former chief**, **corridor patroller**, **family-area loyalists**, **captive mage** and **dwarven trader**.
- The precise geometry/room labels of the **29 October hand-drawn cave maps**. They were visible in project discussion but have not been committed as a machine-readable diagram in the inspected repository.
- Whether the old rubbish shaft remains below the family room and where the **Midden Grub** / relocated refuse go.
- Revised **goblin headcount** and which encounters should contain loyalist officers, especially existing watchpost/guardroom fixtures.
- Named town residents beyond existing named patron, wagoner, lord, sites and working deity.
- Identity of the unknown underground discovery and secret society; its plans; Vale's culpability; identity of the mage's unique book.

### Authoring and archival practice

1. Put new approved narrative decisions **here first**, then adapt adventure files. Keep links to source specifications, not competing, silently diverging canons.
2. Place final NPC biographies under a future `docs/world/characters/` directory only when this document would otherwise become unwieldy; maintain a link/index here.
3. Mark every author secret clearly; public-facing scene text must be written separately.
4. Preserve **working-name** labels until confirmed. An unverified guess must not be promoted to canon.
5. When older chats become directly available, compare them against this version and add recovered names/details with a dated change note. Do not claim unseen conversations have been exhaustively searched.

## Revision history

| Date | Version | Notes |
| --- | --- | --- |
| 2026-10-29 | 0.1 | Initial World Bible scaffold on main; limited story context available |
| 2026-10-29 | **0.2** | Recovered named party, NPCs, Dales setting, Harrowford/Seabrook sites, major campaign spoilers, working quest arcs and actual feature-branch implementation. Reconciled **latest** family-area, corridor patrol and surrender decisions; recorded superseded content and open questions explicitly. |
