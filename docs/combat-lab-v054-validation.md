# Combat Lab v0.5.4 — assets, validation and device acceptance

Issue #32; branch `feature/combat-lab-v054-art-pass`; draft PR base `feature/combat-lab-v0532-combat-clarity`. Implementation checkpoint: `1d275ee`. No merge, deployment or main changes. The original local `work` checkout and its untracked UID files were preserved by using a separate worktree.

## Delivered assets

`assets/combat_v054/` contains 16 original RGBA PNGs, 249 nonempty frames, six native Godot SpriteFrames resources and a versioned manifest with SHA-256, dimensions, source pivots, footprint, facing, equipment and animation durations. `scripts/build_combat_art.py` is the original coordinate-authored pixel source; it reads no reference images. Pillow is an authoring/validation utility already present in the development environment, not a game or CI dependency. Godot CI validates the shipped assets directly.

| Asset | Delivery |
| --- | --- |
| Terrain | Eight seamless 32px floors: stone, moss, cracks, rubble, wet stone; eight transparent ground/transition overlays; sixteen 32×48 neighbor-mask wall/corner/edge/end variants |
| Props | 3×2 covered wagon with canvas/ribs/wheels, 1×2 boulder, low half-cover chest, crate, barrel, table, campfire base; alpha and source pivots |
| Monsters | Goblin, kobold, bugbear, giant spider, skeleton; separately authored left/right; two idle, three walk, two melee, hit, defeated frames |
| Ranged | Goblin shortbow and kobold sling equipment/attack rows; no unsupported skeleton/spider ranged loadout or new bugbear stat block |
| Environment | Four-frame flame, ember and smoke loops; restrained warm pulse, cosmetic clock only, no accumulating particle nodes |
| VFX | Web and burning Web; creature/prop Burning; Fire Bolt, Magic Missile, frost, Bless, healing/Second Wind, Shield/Mage Armor, radiant/Sacred Flame, concentration, impact/slash, arrow and sling stone |

The board retains its existing 68px pitch and nominal 64px actor presentation. Terrain source pixels scale to the same cells with nearest filtering. Actors and full-footprint props sort by ground contact, X, kind and stable ID. Source pivots land exactly on those anchors. Foreground occluders fade when they overlap actors; tactical outlines/HP/status/damage labels draw after smoke, projectiles and impacts. Existing fatal-projectile holds and impact audio ordering remain intact. All rule, party fixture, camera and input code is preserved; only presentation consumes resolved events.

See [render contract](combat-lab-v054-render-contract.md), [asset metadata](../assets/combat_v054/manifest.json), and [native rendering test](../tests/test_v054_art_rendering.gd).

## Executed validation

Environment: managed Linux workspace; official Godot `4.5.2.stable.official.6ce3de25a`. The default `godot` executable was 4.6.3 and was **not used**. Pinned editor archive SHA-256: `87f6e6be292929e363d15ed9052f277b2ba4e95ed994e1e099048097be2dfd03`. Official export-template archive SHA-256: `ea50e5183f057d42b22120d0d0340205b98f51f8ff13c33c70fd4ac9077d2019`. Both verified before use.

| Check | Result and evidence |
| --- | --- |
| `python3 scripts/validate_combat_art.py` | PASS: 16 RGBA assets, 249 frames, alpha gutters, unclipped weapons, pivots, animation states/durations, 64 horizontal/vertical floor pairings and PNG checksums |
| `python3 scripts/build_combat_art.py` twice | PASS: identical PNG, manifest and native-resource hashes |
| Six reference PNG checksums | PASS against `docs/art-direction/README.md`; references unchanged |
| `python3 scripts/self_test.py` | PASS (includes intentional negative-path failure messages) |
| `python3 scripts/validate_template.py --project` | PASS |
| `python3 scripts/validate_toolchain.py` | PASS |
| Pinned `--headless --path . --editor --quit` | PASS: clean import/parse; sandbox-only local editor socket errors resolved by running with local socket access |
| All `tests/test_*.gd` via pinned `--headless --path . --script` | PASS: 37/37 script assertions and exit codes; see [raw summary](validation/v054/regressions.json) |
| New asset/render contract | PASS: native SpriteFrames, all frame bounds and floor seams, wagon front/back, 1×2 boulder, chest height, stable ties, exact prop pivot, wall mask, zoom mapping, real Web/burning Web, presentation/RNG invariance, projectile identity and impact-delayed defeat |
| Pinned `--headless --path . --export-release Web build/web/index.html` | PASS: clean export, nonempty HTML/JS/WASM/PCK. Reference/docs images excluded from shipping PCK; no publishing |
| Chromium software WebGL 2 | PASS launch/render and real Begin Battle/camera-button clicks, landscape/portrait captures, cosmetic frame changes; no console/page/Godot errors. [Browser evidence](validation/v054/browser-smoke.json) |
| iPad Safari / physical touch / gamepad / audio acceptance | NOT RUN |

Some pre-existing test scripts emit audio-resource shutdown diagnostics or the modal-window exclusivity diagnostic while returning PASS. The identical diagnostics were reproduced on untouched target commit `7eceecf` using the same pinned engine; [baseline comparison](validation/v054/baseline-diagnostics.json). These are disclosed, not relabeled as clean logs. The new rendering test, final import/export and browser run have no such errors.

The software-WebGL rAF sampling is diagnostic only (120 samples, raw median/p95 in browser evidence). It is slow on this host and is **not** evidence of acceptable device performance. No iPad performance gate is claimed.

## Review captures

- [Before: target branch](validation/v054/baseline-landscape.png)
- [After: camp](validation/v054/camp-landscape.png)
- [After: active battle at zoom out](validation/v054/battle-zoom-out.png)
- [Portrait fallback](validation/v054/camp-portrait.png)
- [Test-only wagon occlusion, wall foreground, Web, Burning and Bless](validation/v054/occlusion-web-fire.png)

The last capture uses `tests/v054_visual_review.tscn`, with explicit test-only actor placement (including an intentional wagon overlap), masked Web and existing Burning/Bless snapshots. It is not a new encounter or production main scene. A separate temporary Web review export was built, then `project.godot` was restored; the normal export still starts the Combat Lab title. Run the scene directly in Godot for repeatable visual review. These captures demonstrate rendering, not owner art-direction acceptance.

## Remaining placeholders and exclusions

Party front/downed textures are unchanged; no party animation frames or baked modular equipment layers were produced. Wolf, midden grub and bandit keep their previous placeholder art; legacy SVG/PNG files remain for compatibility with existing tests and fixtures. Crate/barrel assets are available without inventing new blockers in authored arenas. Bugbear is an asset-only delivery; skeleton has no ranged fixture and therefore no advertised ranged animation. UI chrome/icon redesign, new spells, rules, animation-speed controls and deployment are outside this slice. Owner visual acceptance is pending.

## Required physical iPad acceptance

Record the PR head SHA, iPad model, iPadOS/Safari version, orientation, tester and result for each item:

1. Title → level 3 → mixed wide encounter → deployment → Begin Battle → restart → last battle log. Verify action/bonus/slot controls and End Turn remain correct.
2. Landscape and portrait: action labels, spell cards, sidebar/log scrolling, safe areas and target text remain readable. Use one-finger pan and two-finger pinch at minimum/default/maximum zoom; pinch/drag must not submit a tile action.
3. Wagon front/back and the test-only overlap fixture: source contact stays aligned, foreground fades expose actors, selection/target outlines remain visible. Check 1×2 east_stone, low chest cover and wall corners/overhangs at zoom limits.
4. Cast Web, ignite a cell with Fire Bolt, inspect actors on Web and Burning. Confirm floor webs remain below feet; smoke remains behind status/damage labels; no decoration implies a different collision/cover rule.
5. Observe left/right monsters, three walking frames, two melee frames, goblin bow and kobold sling. Lethal missiles must hit before the defeated sprite and death sound appear. Party sprite artwork must remain static during its existing movement interpolation.
6. Review Fire Bolt, frost, Magic Missile, Bless, healing, Shield/Mage Armor and Sacred Flame for distinct shapes, restrained glow and touch-scale legibility.
7. Play for several minutes with Web/fire, pan/zoom and repeated retries; record frame pacing, memory/heat, animation clarity and responsiveness on actual hardware. Software-WebGL measurements cannot satisfy this item.
