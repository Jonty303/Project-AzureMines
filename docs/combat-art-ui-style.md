# Project Azure Mines — Combat Art & UI Style Contract v0.1

**Status:** Approved visual direction from the 28 October 2026 Gold Box-inspired battle mock-up. This document is binding on upcoming **presentation** work; it does not change the Classic 5E mechanics.

## Visual identity

- High-detail, deliberately retro **pixel art**, consistent scale and lighting; dark, weathered stone and warm torch/fire illumination.
- A readable fantasy HUD with charcoal slate backgrounds, restrained bevelled metal/stone borders, warm ivory text, compact glowing icons, gold highlights.
- Strong but limited team cues: blue/cyan for **party selection and movement**, muted red for **enemies and hostile target zones**, gold for **selected actions**, green for **restoration**.
- No luminous neon everywhere; state colours are used sparingly, with obvious contrast at normal display sizes.
- Characters should remain instantly recognisable by outfit: **Alden blue/gold sword/shield**, **Elyra crimson/gold staff**, **Brunna ivory/gold mace/shield**, **Pip forest green leather and knives**, **Goblin olive/earth leathers with short knife**.
- Source mock-up is a visual illustration. Treat the illustrated sheet as an **art-direction atlas**, not yet as a ready-to-import uniform texture atlas; verify export bounds, alpha transparency, tile seams and frame spacing before using an element in-game.

## Layout

Target a scalable arrangement based on the mock-up:

```
┌───────────────────────── Battle Map ──────────────────────┬──── Combat Log ────┐
│                                                         │                    │
│     dark stone floor / walls / props / 64px actors      │ turn events        │
│     blue selected cell, amber movement, red enemies     │ dice + damage      │
│                                                         │                    │
├──── Party portrait & status ──┬──── Action bar ───────────┴──── Active weapon ──┤
│ portrait, name/class, HP/AC  │ Attack, class ability, spells, movement, End     │
└───────────────────────────────┴─────────────────────────────────────────────────┘
```

- Bottom-left: current character portrait, identity, HP bar, AC and resources.
- Bottom-centre: **contextual icon-based action bar**. Provide text labels and tooltips; do not rely on colour/icon alone.
- Bottom-right: equipped weapon/attack; make weapon-switch affordance discoverable.
- Right sidebar: structured combat log with different treatment for allied and enemy actions.
- Keep terrain visible behind all combatants, with grounded shadows and soft torch lighting, and preserve crisp pixel art (nearest-neighbour for pixel assets).
- Full-screen or fluid layout: UI should not cover tactical squares at typical window sizes. Preserve pointer hit targets independently of sprite transparency.

## Reference palette (provisional)

| Token | Hex | Usage |
| --- | --- | --- |
| background | `#0E141B` | outer screen |
| panel | `#121B23` | cards, bottom bar, combat log |
| panel-border | `#4A5662` | bevelled interface edges |
| text-main | `#E8DDC9` | readable ivory labels |
| text-muted | `#B4B2AD` | secondary stats |
| gold-focus | `#D7AA58` | action selection |
| ally-blue | `#399BD5` | allies, current cell |
| enemy-red | `#CB4C43` | hostile indicators |
| heal-green | `#65BD7C` | healing, positive HP |
| stone-floor | `#51453D` | floor variation |
| stone-wall | `#25242A` | rocks / shadows |

Colours should be checked against actual rendered pixel assets before locking.

## Source art inventory

The requested **reference atlas** covers:

- **Floors:** varied worn stone, cracked floor, loose stones, darker and lighter variants.
- **Walls:** north/south-facing rocky edges, corners, columns, doorway gaps and obstacles.
- **Props:** crates, barrels, torches, lanterns, fences, rubble, stairs.
- **Characters:** Alden, Elyra, Brunna and Pip, front-facing standing and downed poses.
- **Enemies:** knife goblins, standing and downed poses.
- **Combat overlays:** ally selection, enemy selection, movement range, target zones and line/path cues.
- **UI:** attack, javelin, Second Wind, movement, Disengage, Dodge, Help, Hide, End Turn and magic-action icons, portrait frame, resource bars, log frame and hit/condition markers.

The newly generated comprehensive sheet additionally illustrates directional poses. **Do not enable directional character sprites yet**: the agreed initial game uses one front-facing pose and one downed pose per character. Those other views are future reference only.

## Asset production criteria

1. Separate **reference layout** from **production textures**. Avoid screenshot-cropping labels, background gradients or hard-baked interface text into individual sprite files.
2. Export a consistent grid, with actual transparent alpha where needed; no black rectangles around sprites.
3. Static floor tiles should be exactly tile-sized and should not have baked selection highlights; highlight is a separate overlay rendered by the engine.
4. Repeating floors/walls need seam checks; tiles are not assumed seamless merely because an image labels them 64×64.
5. Characters, enemies, props, selection overlays and downed states should be individually loadable textures with stable IDs.
6. Keep source/master art and pixel-precise exports versioned separately. No arbitrary runtime sprite mirroring.
7. Any 'dead' and 'unconscious' image can share a downed pose initially, but combat state and overlays must distinguish the two.
8. Before claiming a **production-ready atlas**, review every extraction in Godot and automate a dimensional/decode test.

## Implementation roadmap

1. **Current prototype:** keep existing front-facing 64px sprites, downed poses and a functional simple bottom action bar.
2. **Visual integration:** replace temporary solid-colour grid rendering with floor/wall tile assets and a small set of torches/crates/barrels; add separate selection overlays.
3. **HUD polish:** move active portrait/status to bottom-left, icon actions to bottom-centre, weapon panel bottom-right; frame the combat log on the right.
4. **QA:** contrast, scale at window resizing, 64px hitboxes, correct click/hover states, legible combat log and visual consistency.

Do not compromise combat rules and accessibility simply to reproduce the picture literally.
