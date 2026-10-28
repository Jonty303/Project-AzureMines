# Roadmap — v0.2

Milestones are deliverable-driven, not scheduled deadlines.

| Stage | Target | Status |
| --- | --- | --- |
| 0 | Godot/bootstrap and example module loader | Implemented; local validation needed |
| 0.5 | Canonical immutable level-1 party and reference artwork | Character fixtures drafted, sprite tokens supplied |
| 1 | First playable tutorial battle | **Current prototype branch:** grid, four vs two, attacks, log, AI |
| 2 | Combat correctness | Opportunity attacks, cover, reactions, weapon mastery, death saves |
| 3 | Four starting classes' spells and signature abilities | Core spell engine, Sneak Attack, Second Wind and Channel Divinity |
| 4 | Level 1–5 progression for all five classes | Hunter added, class levels, new enemies and extensive tests |
| 5 | Gold Box exploration and RPG | First-person grid, quests, dialogue, shops, equipment and saves |
| 6 | Original small complete adventure | One content pack validates adventure / ruleset separation |
| 7 | Bard expansion | Bard + College of Lore once RPG interactions exist |

## Next validation

- [ ] Run headless module, party and combat tests using Godot 4.5.2.
- [ ] Verify mouse positions, path highlights, and scaled sprites on a desktop.
- [ ] Play a full battle from victory to restart, checking all player and goblin turns.
- [ ] Test blocked corners and turn action/movement limits.
- [ ] Review first iteration against SRD combat rules before broadening scope.

## Scope guardrails

No permanent character creation, levels beyond one, dungeon mode, full spell catalogue or generic adventure editor in this first playable. Implement only features demonstrated by the fixed party and encounter.
