# Combat v0.5 — Goblin Wagon Camp

**Status:** Implemented on `feature/downed-sprites-action-bar`. This encounter expands the existing level-1 tactical test to **four heroes versus four goblins**, using authored environmental hazards and cover. The canonical party fixture is unchanged.

## Battlefield

A 12×10, 5-foot-square clearing with a tree-lined **northern edge**, a large canvas-covered supply wagon in the middle and a small smouldering campfire to the southeast.

```
      0 1 2 3 4 5 6 7 8 9 A B  (x)
  0   T T T T T T T T T T T T   <- trees are backdrop only
  1   T T T T T T T T T T T T
  2   . . . . . . . . . . . .
  3   . . A . . W W W . . M .
  4   . . . . . W W W . . . .
  5   . E . . C . . . . M . .
  6   . . B . . . . . C . . .
  7   . P . . . . . F . . R .
  8   . . . ~ ~ . ~ . ~ R . .
  9   . . . . . . . . . . . .

  A Alden   E Elyra   B Brunna   P Pip
  M knife goblins    R shortbow goblins
  W covered wagon (3x2 tiles)
  C wooden chest     F campfire
  ~ difficult ground
```

The illustrative ASCII map is approximate; the encounter JSON is authoritative for all object and creature coordinates.

### Goblins

- **Goblin Knifehand** (`goblin_blade`): knife, melee combat, x10/y3.
- **Goblin Cutpurse** (`goblin_blade_two`): knife, melee combat, x9/y5.
- **Goblin Archer** (`goblin_bow`): shortbow preferred, dagger if engaged, x10/y7.
- **Goblin Bowshot** (`goblin_bow_two`): shortbow preferred, dagger if engaged, x9/y8.

All four enemies use existing level-1 goblin combat statistics; this is a tactical test encounter, not a new monster progression level. Ranged goblin AI prefers a legal shortbow shot when there is clear line of sight and otherwise repositions to a shooting lane.

### Covered wagon

- Occupies **(5,3)–(7,4)**: six impassable tiles.
- Solid line-of-sight blocker. A straight shot cannot pass through the wagon.
- Artwork is one **192×128 SVG**, drawn over the six-tile footprint with nearest-neighbour filtering.

### Chests

- Chest 1: **(4,5)**. Chest 2: **(8,6)**.
- Impassable to actors, but **do not wholly block lines of sight**.
- A weapon or spell attack that crosses an intervening chest grants the target **half cover (+2 AC)**. Merely standing near a chest does not grant a bonus: its tile must intersect the shot's line.
- No chest contents, looting or interactions are implied yet; these are obstacles/cover only.

### Campfire

- Occupies **(7,7)**, and is **passable**.
- Triggers **1d4 Fire damage** each time a living creature steps onto the tile, including while traversing it as part of a longer path.
- Triggers another **1d4 Fire damage at the start of a living creature's turn** if it is still standing on the fire.
- Does not automatically apply damage when a turn **ends** on the tile (the start-of-turn trigger follows instead).
- Uses the existing damage/downed/concentration/event/sound systems, including handling a creature reduced to zero HP by the hazard.
- Designed as a tactical environmental hazard, not an area spell or burning condition. No persistent 'On Fire' effect is applied.

### Northern trees

- The northern edge has a **768×128 SVG pixel-style forest backdrop** across the top two rows.
- Trees are **decorative background** in this prototype; they do not create new trees-as-obstacles or block projectiles.
- Forest, wagon, chests and campfire are separate assets, not baked into the floor atlas.

## Assets

- `assets/environment/covered_wagon_192x128.svg`
- `assets/environment/supply_chest_64.svg`
- `assets/environment/campfire_64.svg`
- `assets/environment/forest_treeline_768x128.svg`

Each is authored for this project and uses a compact dark fantasy, intentionally pixelated colour palette. Art uses SVG to keep scene geometry transparent and import-safe in Godot; the visual treatment is a first playable pass, not a final painted background.

## Source / separation of responsibilities

The encounter **JSON** defines enemy roles, deployment coordinates, obstacles, cover and hazard triggers. The headless combat engine handles pathfinding, visibility, cover and fire damage. The Godot board draws the corresponding artwork from the same encounter metadata. No texture has authoritative collision data.

## Automated acceptance

`tests/test_wagon_camp.gd` verifies:
1. Exactly two melee and two shortbow-first goblins.
2. Wagon/chests are impassable; wagon blocks line of sight.
3. A chest grants +2 half cover, without blocking sight.
4. Campfire remains passable, burns on entry and again at turn start (each 1d4).
5. Forest exists on the northern edge.
6. All four new SVG assets import, and the combat scene renders headlessly.

It runs with all previous Godot tests in `.github/workflows/godot-smoke.yml`.

## Next desktop review

Check sprite scale/ordering, whether the forest feels like a convincing horizon, whether the wagon appears visually substantial, fire visibility beneath an actor, ranged goblin positioning, reaction overlays, accessibility at 1440×950, and the combat difficulty of four enemies.

**Known limits:** cover uses a grid-ray approximation, not full three-dimensional perspective; trees are backdrop-only; fire has no flicker animation yet; chest treasure is not implemented. The current UI and loot systems remain separate from these encounter props.
