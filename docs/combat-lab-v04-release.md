# Combat Lab v0.4 — Expanded battlefield, touch camera and enemy gallery

**Scope:** Standalone Combat Lab only — no narrative modules or campaign progression.
**Reference design:** [Owner-agreed iPad-first art direction v0.2](combat-lab-ipad-art-direction-v02.md).
**Development branch:** `feature/combat-lab-v04-ipad-camera-cards` (published to the Pages branch only after green CI).

## Gameplay and graphics changes

- **Wide forest training ground:** 17×10 board, expanding from 12 columns. Older 12-column fixtures are retained. The default lab scenario uses the wide arena, and four original locations remain selectable.
- **Camera:** Touch release activates a square; one-finger drag pans, two-finger pinch zooms, mouse drag/wheel provide equivalents, keyboard cursor uses engine grid width and can reveal off-screen cells, and the screen exposes Zoom+/Zoom−/Reset View. Drawing and hit testing share a camera transform. Clamp zoom to 0.65–1.6; limit panning to the authored grid.
- **New monster gallery:** original hand-authored 64×64 SVG sprites and independent low-level combat stat blocks for Skeleton Guard, Giant Spider, Kobold Slingmaster and Bandit Crossbowman. Existing Goblin and Wolf art remain available. No borrowed copyrighted monster images.
- **Mixed encounter preset:** deterministic rotating roster of skeleton, goblin archer, spider, kobold and bandit. One to eight enemies; no plot, story identity or campaign rewards. Existing individual archetypes remain selectable.
- **Touch command dock:** built-in icon + text on Move, Attack, Spell, Dash, Dodge, Disengage and Second Wind; prominent right-aligned End Turn. Weapons are buttons; spells are direct buttons in a horizontal swipeable ScrollContainer with visible left/right navigation.
- **Projectile travel:** resolved ranged weapon and supported projectile-spell hit/miss events now carry actual source and target cell snapshots; the presentation layer animates arrows/bolts and fire/cold/force projectiles over ~450ms and displays impact only after flight. These visuals are queued and reset when starting a new fight. Combat state and rewards are unchanged.
- **Informational sidebar** remains Debug / Party / Details / Log; action bar remains docked to the bottom.

## Important limitations

- The new SVG artwork is **original prototype sprite art** designed for legibility, not final production animation sheets. Real iPad pixel clarity and contrast still require review.
- The new enemies are mechanically distinct in HP, AC, speed, weapons and ranged/melee AI role, but **advanced behaviours** (spider poison/web, skeleton resistances, bandit morale, etc.) are NOT implemented. Their names do not imply additional rules.
- Ranged attacks and projectile spells animate visibly; some instantaneous spells (e.g. Sacred Flame) use existing impact effects instead.
- The simulation resolves before presentation plays projectile travel; final actor HP/death state is already authoritative. The next polish cycle should review visual staging, especially finishing blows.
- The swipeable spell ScrollContainer is implemented with fallback arrow buttons. Headless tests check card selection and structure; physical swipe, scale/pan behaviour and actual touch hitboxes are **NOT YET ACCEPTED**.
- No minimap yet; zoom controls and camera panning provide the first tactical overview. Map boundaries, viewport size and icon sizing may need tuning after owner playtest.
- The Hunter's fixture and levels 2–5 remain partial test scaffolding, not full class progression.

## Acceptance checklist for the iPad Safari playtest

1. Load the Combat Lab from GitHub Pages. Select **Wide forest (17 columns)**, **Mixed** opponents and 5–8 enemies.
2. Begin battle and tap a hero; ensure a tap selects while a drag pans, without accidental movement.
3. One-finger drag right/left to inspect extra columns; zoom with two fingers and with +/− buttons; confirm a targeted cell stays precisely under your finger.
4. Select an attack/weapon through direct icon cards; confirm the right-hand End Turn remains accessible.
5. Open a caster; horizontally swipe the spell strip to select Fire Bolt or Magic Missile; verify tapping a card does **not** cast it.
6. Attack with a bow and offensive spells; confirm an arrow/magic bolt flies **from the source** toward the target and a hit/miss effect follows arrival.
7. Try different creature types; check silhouettes, textures, health bars, hit/damage feedback, camera clipping and landscape readability.
8. Return to title, Retry, inspect Last Battle Log, and confirm the campaign state is not touched.
9. Record iPad model, iPadOS and Safari version and which controls felt cramped, jittery or obscured.

## Automated checks

- Existing Godot 4.5.2 headless rules/UI/touch checks.
- New `tests/test_v04_wide_camera_projectiles.gd` validates 17 columns, mixed enemies, sprite resources, card selectors, End Turn prominence and projectile lifetime/impact.
- `tests/test_web_touch_input.gd` validates release-to-select, drag suppression, pinch zoom, camera mapping and keyboard navigation.
- Official Web export remains single-threaded with verified Godot templates; the GitHub Pages publish job is not a physical-device test.

No game logic rewrites, new dependencies or narrative assets were introduced.

## v0.4.1 correction — 12 November 2026

The owner reported a downed character demanding End Turn and disappearing before the projectile landed. This feature branch now automatically resolves death saves at downed initiative positions, skips non-combatant turns, retains natural-20 recovery, and keeps ordinary AI focused on active threats. A new movement presentation interpolates each resolved tile instead of teleporting sprites. Fatal arrow/spell targets keep their standing battlefield graphic until impact; impact/collapse and death sound are synchronised. HP, death state, dice and combat event results remain authoritative immediately.

Testing details: [FEAT-016](../specifications/features/FEAT-016-downed-turns-impact-and-movement.md). Owner must inspect actual iPad Safari before final acceptance.
