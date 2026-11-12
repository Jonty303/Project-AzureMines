# FEAT-015 — iPad battlefield navigation, projectiles and card-based controls

**Status:** READY FOR IMPLEMENTATION PLANNING — owner agreed to provisional visual direction; no gameplay code changed by this spec.
**Branch for agreed design:** `feature/combat-lab-ipad-art-direction`.
**Reference:** [iPad-first art direction v0.2](../../docs/combat-lab-ipad-art-direction-v02.md). The rendered mockup is retained in the 12 November 2026 project conversation; it is a reference, not a canonical game-state screenshot.
**Build objective:** Combat Lab v0.4 presentation & touch interaction; **no narrative engine or combat-rule rewrite**.

## Work breakdown / implementation checklist

### P0 — viewport and battlefield foundation
- [ ] **Camera transform** in presentation layer: camera centre/offset and zoom are authoritative for drawing and hit-testing, not for combat rules. Mouse drag, one-finger drag, keyboard pan and optional +/- controls share one transform.
- [ ] **Tap versus pan**: movement threshold (initial proposal ~8 display pixels, subject to device test); capture touch ID; on drag consume the gesture without executing a cell action. Use two touches for pinch; calculate scale around pinch focal point, clamp proposed range (e.g. 0.65× to 1.6×) until real iPad testing selects bounds. Handle browser touch-to-mouse synthesis exactly once.
- [ ] **Expand arena data** from 12 to **16–17 columns** in at least one new Combat Lab fixture without overwriting the old 12-column tests. Ensure obstacles, party deployment, enemies, AI pathfinding, line of sight, hazards and cover work across the enlarged grid.
- [ ] **No fixed 12×10 UI assumptions**: CombatBoard minimum size, mouse hit test, keyboard cell cursor and layout respond to `engine.grid_size`. Test panning and zoom with actors on edge columns. Do not force larger maps to fit the screen.
- [ ] Optional **zoomed-out tactical overview/minimap** with actual locations and the visible viewport rectangle; any minimap taps must pan without issuing an attack/move.

### P0 — icon + text command bar and End Turn
- [ ] Dock a bottom action bar spanning the screen; reserve the **far-right** position for a larger, higher-contrast **End Turn** tile. Keep this affordance visible on iPad landscape while the battlefield pans/zooms.
- [ ] Make a reusable **action button/icon component**: placeholder icon + text label, pressed/selected/disabled/focus states and minimum touch targets, preserving current action economy and reaction constraints.
- [ ] Supply explicit initial icon mapping: boot/footsteps→Move; crossed swords→Attack; wand/spark→Spell; runner→Dash; shield→Dodge; retreat/back arrow→Disengage; heart/spiral→Second Wind; forward/hourglass→End Turn.
- [ ] End Turn prominence increases when action/bonus action/movement are exhausted or no legal player actions remain. **Do not auto-end** or pretend spells/bonus actions are unavailable when they are not. Ensure screen-reader-visible label and keyboard shortcut/focus state.
- [ ] Prevent selection mode from becoming stuck after action use, actor change, AI turn or a pending reaction.

### P1 — weapon buttons and swipeable spell strip
- [ ] Replace weapon dropdown with direct **weapon cards/buttons**, showing icon + name and a clear selected state. Disable options that are invalid without concealing why.
- [ ] Replace spell dropdown with **horizontally swipeable spell cards/buttons** in a dedicated `ScrollContainer` or equivalent. Show **3–5 visible cards** depending on width, reveal more with swipe, leave part of next card visible, and provide arrows/page indicator for discoverability and non-touch input.
- [ ] Spell cards show **icon + spell name**, and when practical level/resource cost, availability and target type. Do not show unimplemented spells as active or change spell slots.
- [ ] Card tap selects spell, while card-strip swipe scrolls only the strip (no tile action, board pan, or unintended cast). Selection persists across scroll but resets appropriately for a changed actor. Valid targets still use authoritative `can_cast_spell`.
- [ ] Sidebar Details can preview selected spell range/effect/target using **implemented** definitions, with no invented mana/MP scheme.

### P1 — ranged weapon and spell projectiles
- [ ] Extend resolved combat events with **source and target cell snapshots** (at resolution time) and projectile category/visual ID for ranged weapons and supported projectile spells. Event schema version and deterministic ordering remain explicit.
- [ ] Presentation-only **arrow/bolt** with visible flight; magic variants (e.g. arcane/force, fire, cold) launch from caster toward target. Projectiles should not be spawned at the target as an instant effect.
- [ ] Queue animations sequentially: launch → travel → hit/miss response, using the resolved event's outcome. Visual cue duration may be tuned (~250–500ms proposal), but may not change damage, initiative, death saves, RNG, or successful action state.
- [ ] Ensure projectiles remain correctly anchored as the camera pans/zooms; manage targets near map edge, miss indication and animation cancellation on Retry/Return.
- [ ] Preserve existing event log/audio and no-reward sandbox result. Avoid playing duplicate SFX for the same attack.

### P1 — visual fit and acceptance
- [ ] Maintain right-hand **Party / Details / Log / Debug** information panel; Debug stays there, no extra top-bar log. Character actions stay in the bottom bar.
- [ ] Use existing charcoal/gold/ivory pixel-art design, restrained highlights, crisp source assets, icon readability. Do not use image-embedded fictional character stats or fake MP values.
- [ ] Record actual iPadOS/Safari version, device, orientation and browser build SHA for the touch acceptance pass. Test the larger grid, camera movement, spell strip, button placement, attack/projectile behaviour and last battle log.
- [ ] Run Godot 4.5.2 headless regressions and Web export before publishing. Test with real touch **separately** from injected Godot input events.

## Acceptance criteria (precise pass/fail)

| ID | Expected observable behaviour |
| --- | --- |
| AC-01 | A 16–17-column authored battlefield loads; 12-column fixtures and all existing engine tests still pass. |
| AC-02 | A single tap selects/executes exactly once. A one-finger drag pans without selecting or acting. |
| AC-03 | Pinch zooms around fingers without issuing an action; target cell hit-test remains exact at 3 zoom settings and nonzero camera offsets. |
| AC-04 | Camera shows a meaningful zoomed-out tactical view, never reveals invalid cells as actionable, and retains target/cover overlays. |
| AC-05 | Bottom bar remains visible; every command has label + icon; End Turn is visibly distinguished at the far right and only enabled when legal. |
| AC-06 | Weapon cards select equipment; swipe scrolls spell cards while tap selects; cards have visible offscreen cues and keyboard/mouse fallbacks. |
| AC-07 | Ranged attacks and relevant spells display a distinct moving projectile between actor and target; impact follows actual resolved hit/miss, including enemy actions. |
| AC-08 | Simulation runs the same with presentation disabled (identical combat HP, action economy, seeded outcomes and event order). |
| AC-09 | Responsive iPad landscape passes real-device interaction checks and legibility review; portrait remains usable. |
| AC-10 | Existing GitHub Pages build and release workflows remain reproducible with pinned Godot 4.5.2. |

## Release slices and dependencies

1. **Slice A — camera/grid/touch:** `CombatBoard` camera state, pan, pinch, larger fixture, direct test harness; ensure existing actions remain correct.
2. **Slice B — action dock/cards:** placeholder icons, End Turn emphasis, weapon cards and swipeable spell row; keyboard and pointer fallback.
3. **Slice C — projectiles:** event source/target coordinates, visual queue, per-weapon/spell variants, impact timing, test and Web release.
4. **Slice D — iPad acceptance:** physical Safari playtest, corrective UI pass, no narrative merges, then release to the current Pages preview branch.

**Not included:** story code, NPC registry/morale, mixed monster AI, progression level-two mechanics, model-generated stats from the mockup, full gamepad profile, image slicing into production sprites. Those are separate features.

## Risks and mitigations

- **Swipe ambiguity:** gesture state machine, threshold, distinct input surfaces and dedicated regression tests.
- **Scaled target coordinates:** one shared camera transform for drawing, pointer and overlays; edge tests at all zoom limits.
- **Long actions hidden by animation:** playback must be interruptible and never block simulation authority.
- **Unavailable spells:** only render executable class spells as active; resources come from the engine.
- **Safari limitations:** single-threaded Web export, actual iPad testing, log warnings and fallback controls.

## Owner decisions

The **visual direction and basic gestures are agreed** as of 12 November 2026. Proposed numeric zoom limits, touch thresholds, animation durations, exact icon artwork and card counts are **implementation defaults pending iPad testing**, not permanently approved balance or accessibility rules.
