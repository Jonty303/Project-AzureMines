# Roadmap — v0.1

Milestones are deliverable-driven, **not dates or promises**.

| Stage | Target | Acceptance criterion |
| --- | --- | --- |
| 0 | Godot/bootstrap | Project opens; example adventure and ruleset load; simple smoke test |
| 1 | Combat foundations | Seedable dice, actor state, turn schedule, command/event contracts and headless tests |
| 2 | Tactical battle | Four party members vs four goblin-like test enemies, movement, attacks, HP and victory |
| 3 | Distinct classes | Champion, Priest, Thief, Evoker and Hunter meaningful through level 3 |
| 4 | Levels 4–5 / magic | Full first-pass class abilities, spell catalogue, effects and AI |
| 5 | RPG/adventure | First-person grid exploration, quests, dialogue, shops, equipment, rest and persistence |
| 6 | Small complete adventure | Original standalone adventure package validates engine/data separation |
| 7 | Bard expansion | Bard + College of Lore after RPG features exist; additional races/backgrounds later |

## First issues to tackle

- [ ] Confirm Godot 4.5.2 imports/runs the bootstrap on a local machine.
- [ ] Set up a repeatable headless test environment.
- [ ] Define `CombatantState`, `CombatState`, `ActionCommand`, `RuleEvent`.
- [ ] Build a movement validation model independent of TileMap presentation.
- [ ] Add encounter definitions to the adventure schema.
- [ ] Add combat rules tests before implementing the tactical UI.

## Scope controls

Do not build a universal RPG editor or full level 1–20 SRD content library before a playable battle exists. Keep all content original or appropriately licensed. Leave compatibility hooks but implement only one ruleset initially.
