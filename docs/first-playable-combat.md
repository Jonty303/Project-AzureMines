# First playable combat vertical slice — v0.1

## What this build implements

- The four immutable level-1 test characters from `tests/fixtures/party/level_01_v1.json`.
- Two **original tutorial goblins** from `adventures/test_adventure/encounters/training_battle.json`.
- A 12 × 10, five-foot-square battlefield with obstacles and rough terrain.
- Individual d20 initiative; one Action and up to 30 ft movement per turn; eight-way pathfinding with blocked corners.
- Player clicks valid empty tiles to move and enemy units to attack; no class-change or character-creation screen.
- Basic melee and ranged weapon attacks, range penalties on ranged weapon attacks, simple wall line-of-sight, AC, critical hits, damage, 0 HP defeat, battle restart and log.
- Simple enemy AI that attacks if able, otherwise moves closer.
- Elyra's **Fire Bolt** is temporarily resolved as an attack-roll damage option using her fixture; the general spell engine, spell preparation UI and slots are **not** yet implemented.
- Static 32-pixel sprites (separately cropped from the reference art) and fallback tokens.

## Deliberately not implemented yet

Spell slot casting, saving throw spells, reactions, opportunity attacks, concentration, Sneak Attack, Second Wind, weapon mastery, cover bonuses, death saving throws, inventory swapping, ammunition use and class advancement. Movement through allied creatures is also blocked for this prototype (a tactical simplification, to revisit).

The game ends when the opposing team reaches zero HP; PCs are not yet processed using the official death-save system. The first pass uses simplified wall visibility rather than full rules-accurate cover.

## Acceptance criteria

1. Open Godot 4.5.2 and press F5; a battlefield and party panel appear.
2. A character with the active turn can move onto a reachable unoccupied tile, spending its movement allowance.
3. Clicking an enemy in range (with no wall blocking the line) resolves one attack and logs its result.
4. End Turn advances initiative; enemy units use the same attack/movement engine.
5. Victory or defeat is displayed; Restart begins the deterministic test encounter again.
6. Run headless tests:
   ```sh
   godot --headless --path . --script res://tests/test_module_loader.gd
   godot --headless --path . --script res://tests/test_canonical_party.gd
   godot --headless --path . --script res://tests/test_combat_engine.gd
   ```

**Testing status:** Authoring-time logic review only. We must validate import and runtime under Godot 4.5.2 before merging.
