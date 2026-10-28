# Combat iteration v0.2 — Level 1 only

This stage extends the original tutorial battle using **only level-1 features available to our existing four canonical heroes**. The immutable reference fixture remains at `tests/fixtures/party/level_01_v1.json`; runtime resources and sprite remapping are separate from it.

## Playable features

| Character | Supported in this iteration |
|---|---|
| **Alden (Champion 1)** | Longsword, javelin, shield, Second Wind (Bonus Action: 1d10+1 healing; two uses) and Sap weapon mastery |
| **Elyra (Evoker 1)** | Fire Bolt, Ray of Frost (initial damage only), Magic Missile and Mage Armor. Two level-1 spell slots |
| **Brunna (Priest 1)** | Mace, Sacred Flame (Dex save), Cure Wounds (Action/touch), Healing Word (Bonus Action/60 feet); two level-1 spell slots |
| **Pip (Thief 1)** | Shortbow and dagger, conditional 1d6 Sneak Attack once on the character's turn, Halfling Luck reroll on natural 1, Vex mastery |
| **Goblin enemies** | Two tutorial goblins, including a knife wielder; basic AI only |

### Action interaction

1. Select **Weapon Attack** or a supported spell in the active-turn selector.
2. Click a valid enemy, ally or self target on the grid, or click an empty highlighted tile to move.
3. Use **Cast on Self** for Mage Armor. Use **Second Wind** for Alden when injured.
4. **End Turn** to advance initiative.

The grid was enlarged to display 64×64 front-facing transparent PNGs (four heroes + one goblin) on 68-pixel tiles, with a 1440×950 prototype window. The sprites are intentionally static and never mirrored.

## Explicit limits

This is **not** full level-1 D&D yet. Shield (reaction), Sleep, Bless (concentration), Guiding Bolt, rituals and non-combat utility cantrips remain deferred; prepared spell lists remain in the immutable party fixture but only implemented entries appear in the action selector. Ray of Frost currently deals damage but its slowing effect is not yet applied. The Nick mastery and the Human/Dwarf/Elf features without a supporting scenario remain deferred. There is no resting UI, full death-save model, Opportunity Attacks or all-condition engine.

- Spell slots are deducted only on successful legal slotted casts.
- Only one expended spell slot is permitted per turn, with cantrips allowed separately when action economy permits.
- Healing is capped by maximum HP.
- A goblin's knife now uses the dagger damage formula, matching its artwork.
- The rules engine remains headless; UI and sprite rendering stay separate.
- Some tactical adjudication, notably disadvantage/cover and scope of reaction abilities, requires a later correctness pass.

## Tests

GitHub Actions runs Godot 4.5.2 import/startup checks and all headless tests, including:

```sh
godot --headless --path . --script res://tests/test_level1_features.gd
godot --headless --path . --script res://tests/test_sprite_assets.gd
```

Do not merge until the GitHub checks pass **and** an interactive combat walkthrough has been tested locally.
