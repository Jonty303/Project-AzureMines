# Canonical Test Party — snapshot level_01_v1

These four characters are the deterministic reference party for all early combat tests. Their level-1 snapshot is **immutable**. To change a baseline, publish `level_01_v2.json`; to advance them, create **new** `level_03_v1.json` and `level_05_v1.json` fixtures with documented level-up decisions. Never overwrite this snapshot after tests rely on it.

## Initial party

| Character | Race | Class | STR | DEX | CON | INT | WIS | CHA | HP | AC | Primary attack |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Alden | Human | Champion | 17 | 13 | 15 | 8 | 12 | 10 | 12 | **19** | Longsword +5, 1d8+3 |
| Elyra | High Elf | Evoker | 8 | 15 | 13 | 17 | 12 | 10 | 7 | 12 (15 with Mage Armor) | Dagger +4, 1d4+2; Fire Bolt +5, 1d10 (later) |
| Brunna | Dwarf | Priest | 14 | 10 | 14 | 12 | 17 | 8 | 11 | 15 | Mace +4, 1d6+2 |
| Pip | Halfling | Thief | 8 | 17 | 15 | 12 | 13 | 10 | 10 | 14 | Shortbow +5, 1d6+3 (+1d6 conditional Sneak Attack later) |

All characters are **level 1**, +2 proficiency, Speed 30 feet and use the standard array with our flexible +2/+1 increase.

### Loadouts

- **Alden:** Chain Mail (AC 16), shield (+2), Defense Fighting Style (+1), Longsword (Sap); eight Javelins (alternate ranged attack). The previous Greatsword setup is a **future alternate loadout** and is not the canonical baseline.
- **Elyra:** Robes, arcane focus quarterstaff and daggers; Wizard cantrips Fire Bolt, Ray of Frost and Mage Hand; High Elf Prestidigitation. Spellbook: Magic Missile, Mage Armor, Shield, Sleep, Detect Magic and Burning Hands. Prepared: Magic Missile, Mage Armor, Shield, Sleep.
- **Brunna:** Chain Shirt, shield, mace, holy symbol; Dwarf +1 maximum HP per level; cantrips Sacred Flame, Guidance and Spare the Dying; prepared level-1 spells Cure Wounds, Healing Word, Bless and Guiding Bolt.
- **Pip:** Leather Armour, shortbow, daggers, thieves' tools; Expertise in Sleight of Hand and Stealth, Sneak Attack +1d6; weapon masteries Vex/ Nick.

### Art direction

Reference artwork version **red-evoker**: Alden wears blue and carries sword/shield; Elyra wears **red/gold robes** and has a fiery staff; Brunna wears white/gold with mace/shield; Pip wears green/brown with dagger/bow. One **front-facing** combat sprite per character, 32 × 32 as placeholder. Portraits are independent static assets.

The GitHub repository fixture references planned asset paths in `assets/characters/`. A matching art export bundle must be copied into those paths; they are not an input to the headless character/statistics tests. Do not infer that images are currently checked into the GitHub repository from fixture paths alone.

### Implementation priority

**v0.1 playable vertical slice:** spawn the four characters and two goblins in a 2D square arena; show portraits/static sprites; select units; walk up to Speed with 8-direction grid movement; individual initiative; one basic melee/ranged weapon attack per action; track AC/HP, enemy simple turn, combat log, win/lose/reset. The damage model and d20 roller must use deterministic test seeds.

**v0.2+:** Spellcasting/cantrips, Second Wind, Sneak Attack, weapon masteries, reactions, opportunity attacks, cover, advanced enemy behaviours and progression. These remain present in fixture metadata but are not prerequisites for the first playable test.

## Fixture contract

- `tests/fixtures/party/level_01_v1.json`: source-of-truth immutable snapshot.
- `tests/test_canonical_party.gd`: basic headless validation of identity, hit points, armour and initial attack bonuses.
- Future level-ups should refer to the same IDs (`alden`, `elyra`, `brunna`, `pip`) but store their own level-dependent values.
- Ruleset classes remain general definitions; test fixtures are **instances** of characters, not authoritative class progression data.
