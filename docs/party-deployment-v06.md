# Combat v0.6 — Party Deployment Before the Wagon Ambush

**Status:** Implemented on the existing `feature/downed-sprites-action-bar` branch, Godot 4.5.2. The fixed level-1 party fixture is unchanged.

## Intended adventure role

The original **Wagon Camp — The First Ambush** is a strong candidate for the first real encounter in Project Azure Mines. Like some well-loved classic RPG openings, it introduces combat immediately while giving each member of the party a role. The story, wording, location and characters are original; we do not reproduce an existing adventure's copyrighted dialogue or encounter text.

When the party approaches a broken covered wagon, there is a sign of trouble in the trees. The player receives a **deployment phase before combat**. The goblins remain at their encounter coordinates until **Begin Battle** is selected. This is an encounter setup mechanic, **not** an implementation of D&D Surprise, stealth checks or a free tactical turn.

## How to play

1. Open the combat scene. The battle begins in **PREPARE FOR AMBUSH** mode with four heroes in **Square** formation.
2. Click **Line**, **Square** or **Diamond** to instantly redeploy all four heroes.
3. Optionally, click a specific party sprite, then click one of the **blue deployment squares** to give them a custom starting position. You may reposition characters repeatedly.
4. Press **Begin Battle** to lock the placements, roll initiative and hand control to combat, including any initial enemy AI turns.

The combat buttons and ranges are hidden during deployment. The blue squares show **legal placement positions only when a hero is selected**; they are not movement ranges or extra movement allowance. After battle begins, the established rule remains: **Move** highlights only movement, **Attack** only selected-weapon targets, and **Spells** only the selected spell's legal targets.

## Formation design and orientation

The goblins approach from the **right/east**; the party starts on the west side.

| Formation | First-line concept | Intended use |
| --- | --- | --- |
| **Line** | Alden at (3,5), Brunna (2,5), Pip (1,5), Elyra (0,5) | Single-file advancement across the road |
| **Square (default)** | Alden (3,4), Brunna (3,5), Elyra (2,4), Pip (2,5) | Protected casters behind frontliners |
| **Diamond** | Alden (3,5), Brunna (2,4), Elyra (2,6), Pip (1,5) | A flexible point-and-flanks arrangement |

The **deployment zone** is rectangular: x = 0–3, y = 3–8 on the existing 12×10 grid. These values are encounter data (`deployment_zone`), not the global rules for all future battles. Before allowing placement, the engine validates map bounds, deployment area, blocking walls/props, hazardous terrain, enemy positions and other party members. Preset application is atomic: an invalid formation does not leave characters half-repositioned.

**Manual adjustment is click-to-select, then click-to-place.** Drag-and-drop and rotating formations to face a different approach are candidates for later polish, not implemented here. Switching presets overwrites previous manual placements; the party is marked **Custom** after a manual move.

## Engine / UI separation

- `adventures/test_adventure/encounters/training_battle.json`: adventure text, default formation, deployment zone.
- `combat/combat_engine.gd`: authoritative placements, validation, preset coordinates, and gating initiative until `begin_battle()`. Existing headless combat tests can still call `start(seed)` for immediate battle, while the playable UI calls `start(seed, true)`.
- `combat/combat_board.gd`: highlights a selected hero and only legally available setup squares.
- `scenes/combat_ui.gd`: three preset buttons, manual click-to-place workflow, and **Begin Battle** button. Combat controls remain invisible during deployment.

## Automated checks

`tests/test_party_deployment.gd` checks all three presets, default Square, manual placement, uniqueness/no overlap, rejection of wagon/chest/fire/out-of-zone squares, absence of premature initiative, no combat movement before setup completes, preservation of positions after `begin_battle()`, and the actual UI's setup-to-combat transition.

The pre-existing scene and contextual targeting tests now explicitly begin combat before checking active-turn mechanics. All tests run under GitHub Actions with Godot 4.5.2.

## Known limitations and next milestones

This initial feature assumes the party is allowed to arrange itself before the fight. Future story encounters can instead skip deployment or constrain it differently; true surprise and stealth adjudication must be implemented separately in the Classic 5E rules engine. We also still need exploration scenes to lead into this encounter, narrative decisions, victory XP/gold and subsequent quest progression. The wagon/chests/fire and four goblins are already implemented in [Combat v0.5](wagon-camp-v05.md).
