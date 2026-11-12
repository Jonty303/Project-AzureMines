# FEAT-012 — Character-level-two combat and monster variety

**Status:** Planned follow-on — explicit mechanical details **not yet approved**
**Depends on:** FEAT-010 and satisfactory FEAT-011 review
**Branch:** feature/standalone-combat-lab

## Purpose
Extend the stable sandbox with differentiated level-two class play and several new opponents, while retaining the level-one fixtures as regression baselines.

## Human instructions
Review class mechanics against the adopted Classic 5E SRD 5.2.1 adaptation, exact resource/slot tables, creature design and relative encounter difficulty before implementation.

## AI agent instructions
Do not treat listed class-feature names as already implemented. Keep combat effects and UI mapping separate, and do not invent game-canon encounters or permanent progression.

## Proposed class-level-two feature coverage
| Existing class | Features named in docs/ruleset-design.md for character level 2 |
| --- | --- |
| Champion | Action Surge and Tactical Mind |
| Priest | Channel Divinity and Turn Undead |
| Thief | Cunning Action |
| Evoker | Scholar |
| Hunter | Deft Explorer and Fighting Style |

Confirm resource limits, action costs, saving throws, targets, durations and spellcasting slot changes from the licensed rules and project adaptations before creating acceptance fixtures. The already implemented level-one features must continue to work.

**Important distinction:** This milestone means **characters reaching level 2**, not spells of spell level 2. Full casters at character level 2 still use first-level spell slots and cantrips; second-level spell slots/spells arrive later in the class progression. Expand first-level spell options only with separately approved definitions.

## Proposed monster shortlist (to be approved)
- **Skeleton:** durable-feeling undead with different vulnerabilities/equipment and a clear ranged/melee threat; useful for Turn Undead testing.
- **Giant spider:** movement/poison or control behaviour **only if** those rules are explicitly specified and balanced; otherwise a simplified playtest fixture.
- **Bandit or kobold skirmisher:** a mobile humanoid opponent whose tactics differ from goblin ranged/knife AI.

Aim for two or three newly tested archetypes before adding a wider bestiary. All artwork/stat definitions must be original or used under verified licences. Avoid tying these test creatures to unrevealed campaign plot.

## Data model
- New versioned level-two party fixture rather than changing tests/fixtures/party/level_01_v1.json.
- Mechanically explicit features and spell/resource definitions in ruleset/combat code with deterministic tests.
- New enemy encounter JSON with stable IDs, attacks, art references and a named tactical behavior to exercise.
- Combat Lab selects representative level-one and level-two fixtures, without altering production campaign saves.

## Acceptance (subject to mechanical approval)
- **FEAT-012-AC01:** Four-character level-two fixture loads with correct HP, feature/resource budgets and spell slots.
- **FEAT-012-AC02:** Each approved feature is legal only at the proper level, uses the correct action/bonus/reaction cost and produces deterministic events.
- **FEAT-012-AC03:** At least two distinct new monster archetypes load and act legally; unique mechanics have targeted tests.
- **FEAT-012-AC04:** Mixed encounters can be replayed and balanced in Combat Lab without campaign rewards or spoilers.
- **FEAT-012-AC05:** Level-one fixture and all existing battle/campaign tests remain unchanged and pass.
- **FEAT-012-AC06:** Human playtest documents ease, lethality, tactical variety and UI comprehension at level two.
- **Human approval of exact rules and roster:** Pending.
<!-- [EXAMPLE ONLY] A spell's numeric damage is not approved just because its name appears in a draft. -->

## Larger creatures (planned, independent of level-two work)

A later monster/encounter milestone must not implement a giant or dragon by drawing a large sprite over a 1×1 tile. The owner has requested real size-category footprints: Large 2×2, Huge 3×3, Gargantuan 4×4+ (with individual dragon/giant sizes explicitly authored). First prove a Large 2×2 fixture using the [generic footprint specification](FEAT-017-multi-tile-creatures.md), then a Huge 3×3 fixture and collision/attack/AI tests. Flying, breath effects, squeezing and advanced boss behaviour are separate reviewed rules features. **No giant, dragon, or multi-tile collision is implemented by this document.**
