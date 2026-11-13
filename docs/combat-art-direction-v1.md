# Azure Mines — approved combat art direction v1

**Approved:** 13 November 2026, project owner.  
**Implementation:** [Combat Lab v0.5.4 issue #32](https://github.com/Jonty303/Project-AzureMines/issues/32).  
**Status:** Approved **visual direction** and integration requirements; the six approved reference PNG binaries **are committed to GitHub** under `docs/art-direction/references/`. The checksum manifest is in `docs/art-direction/README.md`.

## Reference images (approved visual direction)

Verified repository destination: [`docs/art-direction/references/`](art-direction/references/).

| Filename in approved reference package | Purpose |
| --- | --- |
| `01_approved_combat_ui_mockup.png` | Main battlefield composition, wagon, rocks, fire, action bar and readable UI |
| `02_approved_combat_asset_overview.png` | Cross-asset visual cohesion, terrain, props, monster frames and spell families |
| `03_approved_cave_dungeon_tileset.png` | **Explicitly approved** floor/wall/corner/edge/transition material, moss and palette |
| `04_approved_monster_animation_direction.png` | **Explicitly approved** monster silhouettes, idle/walk/melee/hit/defeated treatment |
| `05_approved_monsters_and_spell_effects.png` | **Explicitly approved** left/right-facing melee/ranged variants and magic/VFX |
| `06_approved_combat_screen_composite.png` | Integrated direction for tactical readability, occlusion and atmosphere |

**Important:** These are generated reference compositions with captions and irregular frames. They are not seamless tilemaps, alpha-separated spritesheets, or tested animation atlases. Do not claim they are final game assets or crop the labels into production. Production assets must be authored as clean separate textures and verified in Godot.

## Art bible

- **Mood:** dark, atmospheric high-fantasy pixel art with rugged stone, earth and moss, restrained warm firelight, crisp silhouettes, limited glow and selective colour accents.
- **Perspective:** consistent overhead/three-quarter tactical view, matching the current Combat Lab. No inconsistent isometric props.
- **Terrain:** readable rocky floors and unmistakable raised rock walls; subtle variation to avoid repetition; edges/corners and transitions assembled cleanly. A 64-pixel board cell remains the game-facing reference; source tile resolution can be lower if it scales by integer nearest-neighbour.
- **Props:** covered wagon visibly has wheels and canvas roof; boulders are recognisable stone rather than brown wooden cabinets; chest is low cover, not a wall; campfire has a 3–4 frame flame loop, small rising smoke and ember particles.
- **Monsters:** Goblin, Kobold, Bugbear, Giant Spider and Skeleton; distinct silhouettes, left and right facing, 2–3 walk frames, 2 attack frames, simple idle/hit/defeated. Include ranged attack sprites **where supported by actual monster equipment**. Keep frame bounds/pivots stable and projectiles separate.
- **Spell effects:** clear layered magic effects with short 2–4 frame sequences, distinct colours/shapes and a consistent glow budget; Web/fire/burning, Fire Bolt, Magic Missile, healing/Second Wind, Bless, Ray of Frost and only other implemented mechanics. Separate projectile/impact from caster.
- **Grid:** low-contrast during ordinary play, stronger tactical highlights when targeting; readable and not hidden behind overlays.
- **Playable characters:** **explicitly deferred**. Future party animations must use a modular race/body/head/face/hair/armour/clothing/weapon layer system. Do not replace this with baked single-piece character sprites in this pass.

## Rendering and placement order — mandatory

The combat scene must use an explicit compositing/depth contract, not rely on incidental draw-call order.

1. Base terrain and variation tiles, including repeatable floors.
2. Ground decals, cracks, moss, shadows and shallow water.
3. Floor-attached tactical effects such as Web and persistent terrain (visible under creature feet).
4. Ground-contact shadows and low obstacle bases.
5. Actors, monsters, and multi-cell props Y-sorted by **ground-contact anchor** (not texture top edge), with deterministic tie-breakers; wagon and tall boulders may require separate base/foreground parts.
6. Tall wall faces, canopy/overhangs and upper prop sections occlude appropriately. Where they cover a selected creature, show an accessible outline/silhouette.
7. Environmental flames, embers and smoke with bounded lifetime; flame base belongs to the ground, flame tip/smoke to a foreground VFX layer. Keep smoke behind labels and key target indicators.
8. Projectile flight and impact VFX; **death/downed presentation waits for impact**.
9. Target outlines, tactical highlights, floating damage/status labels and action feedback remain readable.
10. UI, log and controls above all battlefield layers.

The same board-to-screen transform applies to all layers at every pan/zoom; use nearest-neighbour filtering and avoid texture bleeding. Validate with a wagon-front/behind actor test, 1×2 boulder, chest cover, burning Web under a monster, fire smoke, moving projectile and zoom extremes.

## Production files and metadata

Use engine-ready atlases/individual transparent PNGs, documented dimensions, fixed pivots, source IDs, frame sequence, frame duration, facing, weapon variant and tile collision/cover metadata. Include asset provenance and licensing. Prefer source-separated effects (flame, smoke, embers) rather than pre-rendered composites. Run automated seam/pivot/frame checks and Godot smoke tests. See Issue #32 for complete acceptance and exclusions.

## Archive verification

All six approved PNG binaries were uploaded and verified as present in GitHub on `feature/combat-lab-v054-art-pass` on 13 November 2026. Their SHA-256 values were checked by the Codespaces import script against the committed manifest before staging. The images remain **art-direction references**, not production-ready spritesheets or seamless atlases.
