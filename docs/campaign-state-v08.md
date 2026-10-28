# Narrative exploration and global campaign state — v0.8

**Implemented on** `feature/downed-sprites-action-bar`, pending visual desktop playtest. Godot 4.5.2. The narrative content is an authored vertical slice, not the full Harrowford or goblin-hideout adventure.

## Design principle

**One global state, multiple game modes.** Narrative choices, encounters, quest decisions, item ownership, NPC dispositions, clues, observed events and discovered routes must share a common state rather than disappear when the screen changes. The v0.8 runtime is:

- `adventure/campaign_state.gd` — single versioned campaign model; snapshots of character HP, status, spell slots and relevant resources; pooled XP/gold; encounter rewards; persistent flags, quests, per-NPC status, known locations, discovered clues, event history and resolved checks.
- `adventure/narrative_engine.gd` — validated, data-driven location/choice runtime. Supports conditional visibility, reversible travel, once-only checks and effects. Does **not** execute arbitrary code from adventure JSON.
- `adventures/test_adventure/exploration_v08.json` — authored scene descriptions, choices, DCs, result text and whitelisted consequences.
- `adventure/overland_map.gd` — grid-paper-inspired discovery map showing only visited or genuinely known nodes/routes, simple ink symbols, labels and annotated goblin trail. **Not yet final hand-drawn artwork.**
- `adventure/opening_session.gd` — opening/deployment/battle/victory/aftermath transitions and entry to the shared adventure state. The existing once-only 200 XP / 12 gp reward now lives in the campaign ledger.
- `scenes/combat_ui.gd` — after the original story, formation and ambush, **Continue** enters the playable wagon clearing. The main panel shows story art or a toggleable map; the right pane shows authored choices, a clue/event journal and Save/Load controls.

## Current playable narrative path

1. **The Watchfire:** Tavian Marr's Seabrook merchant commission and the Old Trade Road appear with the static night-camp artwork.
2. **Ambush:** Choose formation and fight four goblins, including named Hesk. Victory awards the fixed encounter reward just once.
3. **Wagon Clearing:** Choose *Search the wagon* (Intelligence/Investigation DC 12) and/or *Follow goblin tracks* (Wisdom/Survival DC 12). For the initial slice the engine automatically picks the **best conscious available party member** for each check using canonical ability/proficiency modifiers. It shows the die, modifier, total and DC. Each authored check has one saved result; clicking or loading again cannot reroll it.
4. **Harrowford Road:** Leave the clearing and enter Harrowford at any time. The wagon remains on the map, and the party can return.
5. **Guild:** File the report required under Marr's contract and ask about irregular mine shipments.
6. **Stoneweight Market:** Speak to **Mara Venn**. She supplies a **guaranteed backup route** to the goblin ravine even if the tracking check failed. She also offers a raider quest, which the party can accept.
7. **Overgrown Ravine:** Visit the newly discovered path, mark the suspected hideout approach and return to town or clearing. The **interior of the hideout is not yet built**.

Player-facing story descriptions and interactions do **not** disclose the goblin lord's funding, tower prisoners, spellbook or Lord Vale conspiracy.

## Global state structure

| State | Purpose |
| --- | --- |
| `gold_gp`, `xp_by_character`, `completed_encounters` | Shared party purse, per-hero earned XP and once-only combat rewards |
| `party_snapshots` | HP, combat condition, slots and selected class resources carried between screens and into saves |
| `flags` | Durable world facts and once-only choice effects |
| `visited`, `known_routes`, `current_location` | Where the party has been, what it has discovered and where it currently is |
| `clues` | Evidence or rumours with a stable ID, text and certainty (`confirmed`, `suspected`, `rumour`) |
| `events` | Idempotent, chronologically ordered record of what happened |
| `quests` | Named quest statuses, including reported merchant commission and accepted raider investigation |
| `checks` | Die, bonus, total, difficulty, selected party member and success for every resolved one-time skill check |
| `npc_registry` | Stable named NPC identity with alive/dead state, condition, whereabouts, attitude, trust, grievances and promises |
| `rng_state` | Persisted exploration RNG state to avoid reshuffling the future dice sequence on load |

**NPC example:** `hesk_roadwatch` stores whether he survived the ambush, his postcombat condition, HP and first-aid history; future narrative interactions can update his whereabouts, trust, grievances or promises. `mara_venn` changes to a helpful attitude after sharing her lead. Merely knowing an NPC exists does not mean every secret about them is visible to the player.

**Event example:** *The party reported the ambush to Harrowford's Adventurers' Guild.*
**Clue example:** *Mara Venn knows a route to the goblin ravine.*
**World state example:** `road_raiders_accepted = true` and quest `road_raiders = accepted`.

An adventure can depict a rumour as a rumour; evidence does not become confirmed merely because the player heard it.

## Save and load

Use **Save** / **Load** in the story pane. The default single-slot file is `user://azure_mines_slot1.json`, written with a `version` field and basic schema validation. The Godot user data directory is platform-specific. The state includes travel, knowledge, events, NPC statuses, gold, XP, selected party resources and resolved check outcomes.

**Save is intentionally disabled during deployment and active combat.** Safe stage support currently covers victory, aftermath and narrative exploration. Do not claim mid-combat save/resume is supported. Loading safely restores the party and survivor snapshot into a completed post-battle encounter model for presentation. This is a **single-slot prototype**, not production-hardened save migrations, atomic file replacement, cloud sync or import of arbitrary third-party saves.

## Map and journal

The **Map** button switches the main panel from static scene art (when available) to the old-school grid-paper chart. It draws a room/path only if that location is visited or its route was genuinely discovered; the overgrown trail is blank until tracking succeeds or Mara provides directions.

The **Journal** button shows separate **Discovered Clues**, **Events**, **Quests** and **People** sections. Some people are shown only once introduced. Returning to a location can display updated prose and previously unavailable choices.

## Boundaries and next improvements

- The map is mechanically discovery-aware but still uses simple vector geometry, not final parchment art or true handwritten typography. More local dungeon maps, personal scribbles and overland scale are later work.
- The skill-check runtime currently picks the best able character. v0.9 should permit deliberately selecting a party member and include Advantage/Disadvantage, tool proficiency, group checks and specific retry costs.
- Narrative interfaces for **questioning/releasing/capturing Hesk**, nuanced faction attitudes, NPC world-time schedules and the actual goblin hideout are **not** yet playable. Combat outcomes and NPC registry exist as their foundation.
- The mage, dwarf, moor tower, spellbook and Lord Vale resolutions are established **author-only story design**, not implemented content.
- Item inventory, character levels, full class resource persistence and economic services will need typed models and dedicated save migration tests.
- Important **rule boundary:** current 0HP condition, stabilization and healing are combat-derived. No offscreen death save or exhaustion-time simulation occurs while exploring; do not imply a dying character is indefinitely safe until those systems exist.
- Godot headless regression validates semantics and scene integration; it does **not** establish desktop readability, responsive layout or artistic quality.

## Tests

`tests/test_campaign_exploration.gd` checks story state, once-only checks, the town fallback lead, NPC attitude and promises, quest acceptance, returning travel, discovery map UI, chronology and clues, save/load, and non-repeatable encounter rewards. Existing combat and narrative regression tests remain in CI.

This implementation intentionally makes a small, **saveable** narrative adventure play loop first. The next iteration should polish the interface and expand the world graph, not replace the state system with isolated local flags.

## Developer-only skip-goblins shortcut

When running the Godot editor/debug build, the heading contains **DEBUG: Skip Goblins (Spare Hesk)** during the opening narrative, formation setup or an ongoing battle. It bypasses the fight and triggers **the existing normal encounter-victory transition**. Three routine raiders become dead; named **Hesk, Roadwatch** is left alive, knocked out nonlethally at **1 HP**, so he can be awakened through the existing postbattle First Aid or Cure Wounds controls. The usual 200 XP and 12 gp reward is still claimed once and his NPC state is written to the global campaign registry. The world event and `debug_wagon_battle_skipped` flag explicitly mark the simulated result.

The button is gated on `OS.has_feature("debug")`, never appears after victory, and its handler enforces the same guard. It is intentionally unavailable in release builds. It **does not** imply the distant goblin lord has been encountered; Hesk is the named sword-and-shield raider from this opening fight. Tests in `tests/test_debug_skip_battle.gd` cover the real button signal from story/setup/combat, victory once-only rewards, saved Hesk survival, and progression into exploration.
