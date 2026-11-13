# Combat Lab v0.5.4 production/render contract

Feature: [FEAT-020](../specifications/features/FEAT-020-combat-art-rendering.md), extending FEAT-011 and preserving FEAT-016.

Owner-authorized scope: issue #32 and approved art direction v1. Production PNGs are original, source-authored pixel drawings; references are never sampled or cropped. Source resolution is 32 pixels per 64-pixel artwork box, displayed in the existing 68-pixel board pitch (camera/input unchanged). Nearest filtering, lossless imports, fixed alpha gutters and uniform monster pivots are mandatory.

## Audit

Current fixtures use stone floor, walls, difficult ground; 3x2 wagon, 1x2 east_stone, low half-cover chests, 2x2 flammable table; walkable hazardous fire. Current monsters: goblin sword/knife/bow, kobold dagger/sling, skeleton sword, giant spider bite; wolf, grub and bandit retain their existing art. Bugbear is an asset-only delivery: no new enemy rules. Skeleton ranged equipment is not currently implemented. Party front/downed images remain unchanged.

Current effects: Web, burning Web, creature/prop Burning, Fire Bolt, Magic Missile, Ray of Frost, healing/Second Wind, Bless, Sacred Flame, Shield, Mage Armor and concentration. No Sleep/Hold Person effects are advertised.

## Compositing

All passes share the existing board camera transform. Ordered passes: floor/variation; ground overlays (moss/rubble/wet/Web); contact shadows and hazard bases; stable ground-Y sorted props/actors; wall foreground/overhangs; flames/embers/smoke; projectiles; impacts; tactical outlines and status/HP/damage labels. Application UI is outside the board and above it.

Ground Y is actor interpolated cell Y + 0.90, prop origin Y + footprint height - 0.10. Ties sort by ground X, then kind and stable ID. Multi-cell props draw once using their full footprint, never independently per occupied cell. Upper art extends above the footprint using a documented height offset. A foreground overlap fades its occluder and the final tactical pass restores the actor cell/team outline. Props retain fixture collision, cover and line-of-sight flags; art metadata cannot change rules.

Cosmetic time is a local clock, never CombatEngine RNG. Animation lifetime and sprite selection do not advance combat. Projectile death holds remain until impact; ranged attacks and impacts use the existing queued start times. Reset clears cosmetic queues. Environmental loops are bounded frame selections, not accumulating particle nodes.

## Acceptance

Automate dimensions, alpha gutters, nonempty frames, floor boundary compatibility, pivots, state/facing sequences, deterministic source rebuild, Godot import/regressions and nonempty Web output. Capture integrated camp and chamber views; exercise both wagon sides, boulder, wall overhang, Web/fire and zoom limits. Physical iPad portrait/landscape, touch, clarity and performance require owner acceptance. Gamepad is unchanged and NOT RUN.
