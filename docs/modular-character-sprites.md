# Modular character sprites and minimal animation — design direction v0.1

**Status:** Owner-agreed direction, 13 November 2026. Design contract only; not yet implemented.

## Goals

Give playable characters customisable Gold Box-inspired appearances while keeping art production and animation intentionally small. Make it visually obvious when a creature walks, attacks, casts, is hit, falls, or suffers a condition. Favour excellent silhouettes, a small number of clear poses, motion effects, and sound over highly animated sprite sheets.

The current Combat Lab uses 64×64 front-facing whole-character placeholder sprites plus a downed-character atlas. Retain these during migration. The production system should not require a separately illustrated complete sprite for every character/equipment/colour combination.

## Character appearance

Compose sprites from interchangeable art layers, with saved appearance distinct from rules and equipment:

- Playable ancestry/body proportions, initially Human, Elf, Dwarf and Halfling; expand as the ruleset supports additional ancestries.
- Male/female body options, body and head matched to the correct proportion family.
- Selectable head/face, hairstyle, hair colour, skin tone, and optional facial hair as art allows.
- Equipped body armour/clothing, footwear, cloak/headwear, held weapon, off-hand/shield.
- Player-selected clothing/armour colour palette. A blue tunic/surcoat can be green without recolouring skin, hair, steel or unrelated components. Use colour masks or indexed colour ramps that retain light/shadow information; at minimum primary fabric, optional secondary fabric and trim.
- Equipment visuals derive from equipped inventory; cosmetic dyes/appearance are separate saved data. Do not permit appearance data to silently change rules.
- Portrait and character card presentation should reflect appearance choices where technically feasible, without claiming that combat-sized sprites must be enlarged for portraits.

Art layers have stable identifiers and compatible body/pose templates. Use attachment points and direction/pose-dependent draw order for hair, helmets, cloaks, shields, weapons, and front/back components.

## Minimal animation contract

**Primary facing:** left and right. Prefer shared right-facing art mirrored for left when it reads correctly; permit asymmetric bespoke art when required. Moving north or south across a grid can retain last horizontal facing; facing is *presentation*, not an additional combat mechanic.

**Target poses / frames, per compatible template:**

| Action | Frames | Requirement |
| --- | --- | --- |
| Standing | 1 | Clear, readable side-facing pose |
| Walking | 2–3 | Repeat cycle while actor position interpolates smoothly between tactical cells |
| Melee attack | 2 | Start/wind-up pose then end/follow-through pose; separate arc/slash trail gives sense of swing |
| Ranged attack | 2 | Ready and release; projectile originates at weapon/hand attachment and travels to target |
| Spellcasting | 2 | Prepare and release; independent magical effect/projectile |
| Taking damage | 1 | Recoil, flash or small offset, after attack impact |
| Downed | 1 | Persistent incapacitated pose; distinguish unconscious vs dead by state/UI |
| Death | 1–2 | Brief collapse then persistent downed/dead visual, only after causal impact resolves |
| Conditions | independent effects | e.g. burning, poison, restrained; do not bake unique status variants into all character poses |

Animation timing is presentation-only; the engine resolves all rule events, including reactions, hit/miss, concentration, conditions and death saves. Visual events follow that resolved, causal order. Do not visually kill or collapse a character before the incoming projectile/impact. Simple animation may use small offsets, particles/slash arcs, flashes and sound to improve legibility without introducing more sprite frames.

## Architecture

1. Headless combat engine remains authoritative for movement, AI decisions, RNG, state transitions and event order.
2. Sprite composition is handled by a dedicated presentation component (proposed `SpriteComposer`) and immutable/versioned art definitions, not embedded in combat rule code.
3. A single animation state/frame index drives all attached layers. Offsets, frame alignment and directional draw order are specified by template.
4. Cache completed sprite frames/palettes for common appearance+equipment+pose combinations, invalidating only on changes. Keep pixel-art rendering crisp and profile for web/iPad.
5. Retain stable `combat_sprite` fallback for legacy fixture compatibility during migration.
6. Non-humanoid monsters can use dedicated simple sprite sets; humanoid enemies may reuse compatible composition and animation assets. Large creatures must preserve their separate multi-tile footprint/collision model.

## Suggested phased implementation

- **Proof of composition:** Human and Dwarf male/female bodies, several heads and hairstyles, visible skin/hair options; one standing pose, two outfit palettes and a weapon.
- **Equipment/colour:** interchangeable garments, armour, shield, bow, staff, melee weapon and selective recolouring.
- **Motion:** 2–3 frame walk; 2-frame attack/cast; hit/downed; effect timing, attachment alignment and projectile impact.
- **Broaden:** Elf and Halfling templates, more equipment, character-creation UI, persistence and portrait integration.

## Acceptance / QA

- Changing hair/skin/cloth colour cannot tint unrelated regions; all choices retain shadows/highlights.
- Hair/head/armour/held items remain aligned through every pose and direction.
- Equipment changes update appearance while leaving rules unchanged except from actual equipped items.
- Movement is visually continuous even though walking has 2–3 frames; grid state stays authoritative.
- Attack/cast effects communicate the action clearly at normal and fast playback.
- No premature downed/death animation; animation completion does not block or alter combat outcomes.
- Existing Combat Lab fixtures and legacy sprites still load.
- Verify appearance serialization, missing-art fallbacks, 64×64 dimensions, nearest-neighbour scaling and touch/web performance.

## Related material

- `docs/architecture.md` — engine/ruleset/adventure separation.
- `docs/combat-rules.md` — combat event contract and speed/presentation separation.
- Later Combat Lab feature branches contain a provisional iPad art direction; preserve the agreed visual identity while simplifying animation frames.
