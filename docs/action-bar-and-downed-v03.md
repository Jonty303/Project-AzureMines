# Combat Iteration v0.3 — Downed Poses and Action Bar

The third combat UI iteration turns the approved dark-stone mock-up into a playable, **simplified** Godot interface without introducing level-2+ features. This is an incremental visual / level-1 rules milestone, not a full reproduction of the concept artwork.

## What changed

- Persistent **downed sprites** for Alden, Elyra, Brunna, Pip and the goblin. A single 320×64 PNG atlas contains five 64×64 poses in that order.
- The map no longer hides every combatant at zero HP. Party members become **unconscious**, while tutorial goblins become **dead**. Downed/stable heroes show a blue Z; dead creatures show a red X. The same downed artwork is used for both.
- An unconscious party member remains a valid target for healing, and recovering positive HP returns them to the active state.
- Basic Death Saving Throws are now rolled on a downed hero's turn (three successes stabilise, three failures kill, natural 20 restores 1 HP, natural 1 counts twice). This is not yet the complete damage-at-zero system.
- A **bottom action bar** offers functional Move, Attack, Spells, Second Wind, Dash, Dodge, End Turn; weapon and spell selectors are directly below.
- Every button has a real gameplay handler and disables when it is not legal. Downed heroes can advance their turn but cannot move or attack.
- The HUD keeps the charcoal/ivory/gold aesthetic, blue ally and red enemy outlines, and a right-hand combat log.
- Stone floor and wall atlas is an original SVG imported by Godot; a separate transparent PNG atlas contains a crate, barrel and torch from the approved concept's visual vocabulary. Encounter collision still comes from its JSON, not images.
- We preserve the level-1 canonical fixture; no character advancement or new classes are introduced.

## Controls

**Move**: click a highlighted empty square. Movement remains permitted before/after an attack when available.

**Attack**: choose a weapon from the bar, then click a living enemy in range.

**Spells**: choose a supported spell from the bar, then click an appropriate target. Use **Cast on Self** for self-targeted spells.

**Second Wind**: Alden's Bonus Action healing when injured and uses remain.

**Dash**: use the Action to add movement equal to current Speed for that turn.

**Dodge**: use the Action to impose Disadvantage on attacks against the character until the start of their next turn.

**End Turn**: proceed through individual initiative and AI turns.

## Source atlas contracts

| File | Dimensions | Frames |
| --- | --- | --- |
| `assets/characters/sprites/downed_party_atlas_64.png` | 320×64 | Alden, Elyra, Brunna, Pip, Goblin |
| `assets/environment/dungeon_tiles_64.svg` | 256×64 | Three floor tiles and one wall tile |
| `assets/environment/dungeon_props_64.png` | 192×64 | Crate, barrel, torch |

The image assets are intentionally limited palettes and placeholders. More varied walls, corners, shadows, effects and all other art-reference categories are future production tasks, not silently claimed as complete.

## Validation

Run the existing GitHub Actions smoke suite, now including:

```sh
godot --headless --path . --script res://tests/test_action_bar_and_downed.gd
```

The test checks legal/illegal Dash and Dodge, healing an unconscious hero, dead target handling, atlas dimensions and real scene/action-bar construction.

## Known gaps

- The current party/monster **zero-HP model is partial**. Excess damage, attacks against downed targets, stable-hero recovery timing and advanced encounter outcomes need later rules tests.
- Disengage, Ready, Help and Hide have no action-bar commands yet; they should not be shown as decorative disabled buttons.
- Spellcasting is limited to the v0.2 subset. Shield reactions, Bless/concentration and other level-1 spells are not complete.
- The art has no movement, attack or directional animations.
- The UI uses styled text controls rather than the fully icon-illustrated toolbar from the mock-up. That is a subsequent polish pass.
- The floor atlas is a repeatable stylistic approximation; it does not yet implement the full terrain variations illustrated in the concept sheet.
- Manual desktop testing is still needed for input hitboxes, layout scaling and readability.

See [Combat Art & UI Style Contract](combat-art-ui-style.md).
