# Codex handoff — Combat Lab v0.5.4 art and rendering

**Task:** [Issue #32](https://github.com/Jonty303/Project-AzureMines/issues/32)  
**Prepared branch:** `feature/combat-lab-v054-art-pass`  
**Base:** `feature/combat-lab-v0532-combat-clarity`  
**Status:** Prepared, not implemented.

## Required reading

Read `AGENTS.md`, `workflows/DELIVERY.md`, `docs/combat-art-direction-v1.md`, `docs/combat-art-ui-style.md`, `docs/combat-lab-ipad-art-direction-v02.md`, `combat/combat_board.gd`, relevant fixtures, and Issue #32. The owner-approved visual reference images are packaged in `azure_mines_approved_art_direction_v1.zip` from the conversation. They are **not yet uploaded as binary files to GitHub**; obtain/import them and verify checksums before claiming the reference images are in-repo.

## Phased production

**A. Asset audit and render order.** Enumerate all terrain, obstacle, hazard, monster and existing spell VFX. Write an explicit stable draw-order specification with ground anchors, tall-prop foreground occlusion, area Web under feet, fire/smoke split, projectile impact/death order and targeting outlines above decorations. Add tests for 1×2 boulder, 3×2 wagon, chest, Web and fire.

**B. Environment.** Create actual separate seamless floor, wall, corner, edge and transition tiles; verify no seams or nearest-neighbour bleeding. Create recognizable stone boulder, wagon, chests, barrels and campfire sprites at consistent scale and with transparent backgrounds. Ground collision and LOS properties must agree with fixtures. Do not use concept posters as game atlases.

**C. Monster atlases.** Produce Goblin, Kobold, Bugbear, Giant Spider and Skeleton left/right sprites, idle, 2–3 frame walk, two-frame melee, hit and defeated; ranged variants only for real supported ranged weapons. Document per-frame pivot, dimensions and animation timing. Leave playable-party characters unchanged; their future customisable modular layering is separate.

**D. Spell VFX.** Upgrade only existing implemented spells and statuses: Web, burning Web, Burning, Fire Bolt, Magic Missile, Bless, healing/Second Wind, Ray of Frost and other currently playable effects. Use independent projectile, impact, smoke/embers and overlay assets, not baked screenshots. Ensure no early death sprite before impact and no gameplay timing tied to animations.

**E. Integrate and validate.** Godot 4.5.2 pinned, all old and new tests, asset seam/pivot/alpha checks, browser Web export and performance smoke. Provide before/after screenshots and iPad portrait/landscape acceptance instructions. Commit recoverable checkpoints and open a DRAFT PR targeting `feature/combat-lab-v0532-combat-clarity`. No merge/deploy or unrelated game rules changes.

## Explicit exclusions

No playable character animations, no baked gear/head/hair characters, no new spell rules, no new enemy rules, no battle-speed changes and no full UI redesign. Prioritise readability, compositing correctness and game-ready source assets.
