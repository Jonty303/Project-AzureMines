# Project Azure Mines — World Bible

**Status:** Working canon, v0.1  
**Last reviewed:** 2026-10-29  
**Repository location:** `docs/world-bible.md` on `main`

## Purpose and editorial rules

This is the canonical reference for the **fictional world, characters, locations, factions, quests, and narrative consequences** of Project Azure Mines. It is distinct from the engine's technical documentation and from implementation status.

- **Established:** explicitly agreed in project discussions or implemented in adventure content.
- **Proposed:** discussed as a possibility, but not firmly settled.
- **To recover:** previously developed information that is not available in the source material used to prepare this revision. **Do not treat it as never having existed, and do not invent replacements.**
- **Open:** a genuinely unresolved design decision.

Narrative entries can be expanded without changing existing canon. When changing established canon, record the change in the revision history.

> **Recovery notice:** Earlier project conversations established named NPCs and setting details. Their names and full biographies were not recoverable from the material accessible during this initial compilation. They must be reconciled against those earlier conversations before new names or character biographies are approved.

## 1. Setting and overarching story

### Starting settlement

- **Established:** There is a town intended to serve as a starting or support hub for adventurers. It will have a shop with purchasable items and a wider set of NPC interactions.
- **To recover:** The settlement's established name (if named previously), town NPC names, personalities, businesses and individual quest hooks.
- **Open:** Final shop inventory and town-state progression.

### The cave and caravan raids

- **Established:** A goblin-occupied cave is a major early adventure location.
- **Established:** A bugbear holds authority over the cave's loyalist goblins and is connected to attacks on caravans.
- **Established:** The bugbear has orders to identify and capture **dwarves** encountered during caravan attacks and send them to **the tower**.
- **Open:** Who issued those orders, the tower's identity and exact location, and the broader reason dwarves are being targeted. These may have been detailed in earlier conversations and should be checked before new material is written.

### Moral and factional theme

- **Established:** The goblins are not all equally loyal to the bugbear. Some can be negotiated with and spared.
- **Established:** The party's treatment of non-combatants and ordinary goblins affects future trust, surrender and hostility.
- **Established:** The adventure should distinguish defeating oppressors from indiscriminately killing cave inhabitants.

## 2. Geography and location register

### Wooded valley / cave exterior

- **Established:** The cave entrance sits in a rocky wall on the side of a wooded valley.
- **Established:** This is the exterior approach to the early cave adventure.

### Entrance corridor and waterfall

- **Established:** A long internal passage leads inward to an underground waterfall.
- **Established:** Side passages connect the entrance route with other cave rooms.
- **To recover:** Exact connectivity, labels and proportions from the hand-drawn cave maps shared in project conversation on 2026-10-29. The original maps are source references; this text should not supersede their geometry.

### Patrolled corridor

- **Established:** A corridor contains a patrolling goblin **not loyal to the bugbear**.
- **Established:** The party may be able to talk its way past instead of fighting.

### Guard room

- **Established:** A goblin guards this room with a large wolf.
- **Open / to recover:** The goblin's name, loyalties and detailed encounter conditions.

### Kitchen / eating / sleeping area

- **Established:** A communal space used by a handful of goblins.
- **Open / to recover:** Named occupants and encounter and dialogue details.

### Family area (formerly the rubbish pit)

- **Established:** The room previously designed as the rubbish tip has been repurposed as the goblin **family area**.
- **Established:** Two bugbear-aligned goblins are present and are possible combatants.
- **Established:** Goblin women and children here **do not fight**.
- **Established:** Attacking or killing non-combatants is possible in the fiction but constitutes a severe moral choice with significant repercussions for trust and later reactions.
- **Established from the earlier rubbish-pit design:** The room included a hole in the floor where refuse was deposited, intended as a possible future story or dungeon connection.
- **Open:** Whether the refuse hole remains in the family-area redesign; do not assume it was removed or retained without confirmation.
- **Superseded / proposed:** A suitable low-danger rubbish-dwelling monster was considered for the old rubbish pit; its use in the new family area is **not confirmed**.

### Bugbear's location

- **Established:** The bugbear is the cave's principal opposing authority.
- **To recover:** Exact room assignment, name, appearance, background and any previously agreed dialogue.

### The tower

- **Established:** The tower is the destination designated for captured dwarves.
- **To recover / open:** Proper name, location, occupants, master, purpose and relationship to the larger plot.

## 3. Character and creature register

**Important:** Descriptive labels below are not new proper names. Previously established names must be recovered before characters are renamed or marked officially unnamed.

| Character / group | Known location | Established role or description | Name status |
| --- | --- | --- | --- |
| Bugbear leader | Cave complex; precise chamber to verify | Directs loyalists and caravan raids; ordered to send captured dwarves to tower | **To recover** |
| Corridor patrol goblin | Patrolled corridor | Not loyal to bugbear; potentially negotiable | **To recover** |
| Goblin guard | Guard room | Accompanied by a large wolf | **To recover** |
| Large wolf | Guard room | Companion to the guard | **To recover / may be unnamed** |
| Loyalist / elite goblins | Distributed through cave combat encounters | Enforce bugbear's control | **To recover** |
| Two family-area loyalists | Family area | Bugbear-aligned combatants amid non-combatants | **To recover** |
| Ordinary goblins | Communal rooms and cave encounters | Not necessarily loyal to bugbear; may surrender | **To recover** |
| Goblin women and children | Family area | Non-combatants; treatment drives narrative consequences | **To recover where individually characterised** |
| Captured dwarves | Being sought for transfer to tower; individuals' current positions unclear | Targets of bugbear's instructions | **To recover** |
| Starting-town NPCs | Town | Shopkeeping, quest and social functions planned | **To recover** |
| Adventuring party | Player-controlled | Initial four-character party | **Open / player-dependent** |

### NPC record template

For each named NPC, record: **canonical name**, species, faction, location, physical description, temperament, motivations, what they know, dialogue hooks, relationships, combat/surrender behaviour, quest involvement, and consequences of death or mercy. Cite the source conversation or source file when recovered.

## 4. Factions and relationships

### Bugbear loyalists

- **Established:** Elite or especially loyal goblins serve the bugbear and exert control over other goblins.
- **Established:** Each relevant cave goblin combat encounter includes **at least one** bugbear-aligned elite goblin.
- **Established:** The two loyalists in the family area are a particular manifestation of this group.

### Non-loyal / ordinary goblins

- **Established:** The population includes goblins whose allegiance to the bugbear is absent, reluctant or conditional.
- **Established:** The patrolling goblin is specifically non-loyal.
- **Established:** Some goblins may surrender when loyalist enforcers have been defeated, subject to trust and the player's treatment of families.

### Tower authority

- **Established:** Someone above or beyond the bugbear is interested in captured dwarves.
- **To recover:** Identity and organisational structure; do not supply a new villain name until the earlier story is checked.

## 5. Encounter and consequence rules

### Conditional surrender

- **Established design:** In cave goblin fights, defeating the bugbear-aligned elite goblin(s) can cause the remaining ordinary goblins to surrender.
- **Established design:** This outcome is **not automatic** when the party has murdered goblin families or failed to earn the ordinary goblins' trust.
- **Implementation note:** Model the outcome through encounter composition, faction loyalty and persistent trust / atrocity flags, rather than hardcoding a universal surrender event.

### Post-battle interactions

- **Established:** Choices such as **heal, kill, free or talk to a defeated goblin** should play out as narrative interactions **after** combat, not as buttons in the post-battle result summary.
- **Established:** These choices can contribute to downstream reactions and character outcomes.

### Protection of non-combatants

- **Established:** Goblin women and children in the family area do not attack.
- **Established:** Harm to these characters is intended to have substantial narrative and factional consequences.

## 6. Open story and content recovery queue

1. Recover the established **proper names and descriptions** of town and cave NPCs from previous Project Azure Mines conversations.
2. Recover town name, businesses, geography and earlier setting details.
3. Reconcile the hand-drawn cave maps with the location register; transcribe room labels and connections without inventing missing links.
4. Resolve the family-area refuse hole and any earlier rubbish-pit creature design.
5. Recover details of the tower, its authority and the motive for targeting dwarves.
6. Reconcile all recovered canon with in-game adventure data when it is implemented.

## 7. Source-of-truth and implementation boundaries

- This document is the editorial **story canon** source on the repository's `main` branch.
- Adventure data files are the **runtime implementation** of that canon; discrepancies should be tracked and resolved explicitly.
- The current `Project-AzureMines` repository was a bootstrap when this file was first created. Do not mistake unimplemented content for undecided story design.
- Previous project conversations and shared hand-drawn maps are valuable historical sources even where not yet transcribed here.

## Revision history

| Date | Version | Summary |
| --- | --- | --- |
| 2026-10-29 | 0.1 | Initial world bible compiled from accessible project discussion; known story canon recorded and inaccessible prior NPC names flagged for recovery. |
