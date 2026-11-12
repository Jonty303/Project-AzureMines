# Combat Lab — iPad-first art and interaction direction v0.2

**Status: OWNER AGREED — PROVISIONAL PRESENTATION DIRECTION**
**Agreement date:** 12 November 2026 (discussion following the 14:49–14:54 iPad tactical-battle mockup)
**Scope:** Combat Lab presentation/interaction only. Supersedes the earlier v0.1 combat art contract where the iPad layout differs; retains the original pixel-art identity and colour conventions.
**Reference:** The generated **Combat Lab tactical battle UI mockup**, 1448 × 1086 PNG, shared in the project conversation on 2026-11-12. Original reference SHA-256: `687e8f8940a18c48c54b8a66ccb350644e9b046dafb0d496871ceafa38c88db3`. The image master remains in that conversation artifact; its bytes are not yet committed to this repository. Do not treat the prose below as permission to fabricate a replacement or claim the image is a production asset.

## Decisions agreed with the owner

1. **Primary display:** iPad Safari in **landscape**, with graceful portrait fallback; desktop mouse/keyboard remains supported. Keep legible, touch-sized controls and responsive safe-area-aware positioning.
2. **Battlefield first:** Widen the playable encounter area by **at least four or five columns** from the prototype's 12-column baseline, initially target **16–17 columns**, with no change to the physical size/scale of individual tiles as a rule. Larger maps can extend beyond the viewport.
3. **Camera interaction:** **One-finger drag to pan** the larger grid. **Two-finger pinch to zoom** continuously, with a readable zoomed-out tactical view and optional minimap/zoom buttons. Preserve selection precision, movement highlights and tile coordinate mapping at every zoom level.
4. **Right information panel:** Permanent in landscape, context-sensitive **Party / Details / Log / Debug** tabs, using clear compact status cards. Debug controls live in Debug, not duplicated in the header or mixed with player commands. Portrait can stack the panel below the battlefield.
5. **Player command bar:** Dock character actions **across the bottom** of the display; make each command an icon **and** readable text. Current actions include Move, Attack, Spell, Dash, Dodge, Disengage, Second Wind, plus situational commands/reactions and deployment.
6. **End Turn:** Make this a clearly distinguished, **large button at the far right** of the command bar. Especially emphasise it when no useful character actions remain, without falsely implying that the player must end the turn or silently auto-ending it. Never allow use during an unresolved reaction, deployment or another creature's turn.
7. **Weapon and spell choice:** Replace dropdowns with clear, selectable **buttons/cards**, with placeholder icons and names. **Spell selection is a horizontally swipeable strip**: tap to select a visible spell, swipe to reveal additional choices, show a partial next card and/or arrows/page indicator; never make swiping the sole discovery mechanism.
8. **Projectile feedback:** Ranged attacks visibly launch arrows/bolts, and offensive spells launch the appropriate **projectile from caster/attacker to target**, travelling across the battlefield. Spell type and hit/miss are visibly distinguishable. Visual timing follows resolved, structured combat events; no extra rolls, damage application or turn delays in the visual layer.
9. **Aesthetic:** Premium, readable **pixel-art fantasy tactics**: dark slate/stone panels, warm ivory and restrained gold borders, crisp character silhouettes, obvious blue friendly/selection cues, red hostile targets, green healing and distinct fire/cold/arcane effects. Icons should be consistent in stroke, scale and contrast; visual richness must not obscure the actual board.

## How to interpret the illustration

**The mockup is a visual proposal, not a screenshot of implemented functionality or canonical rules data.** Specifically:
- Text such as `Alden — Lv 5 Ranger`, invented MP values, hit percentages, enemy challenge levels, and illustrative spell choices are **not** authoritative; Alden remains the existing Champion fixture unless separately changed through character design. Do not infer a mana system or implement invented stats because they appear in the image.
- The depicted top-bar **Battle Log** button is an illustration artefact; the owner previously removed that redundant button. The Log tab owns the log. Debug belongs to Debug, Retry/Return to Title can remain in the header.
- The image depicts simultaneous arrows and magic projectiles to communicate the intended style; actual turn-based actions and outcomes must remain sequential according to CombatEngine.
- Projectiles, swipes, wider maps and minimap are **approved direction but not yet implemented** on this design-only branch.
- Use the reference as a composition/interaction guide, not as a drop-in texture atlas. Derive production icons/tiles/sprites separately with proper asset licensing and pixel-scale verification.

## Interaction zones (landscape, not a rigid pixel blueprint)

```text
┌────── Combat Lab / current turn ─────────────── Retry / Return ──────┐
│                                                                      │
│  WIDE PANNABLE / ZOOMABLE BATTLEFIELD   │ Party / Details / Log / Debug│
│  16–17+ columns; active selection      │ contextual information      │
│  projectiles, move/attack targets       │ and developer tools         │
│  optional tactical overview            │                             │
├────────────────────────────────────────┴─────────────────────────────┤
│  MOVE  ATTACK  SPELL  DASH  DODGE  DISENGAGE  2ND WIND  | END TURN  │
│  Weapon [sword] [bow] ...  Spell [card] [card] [next →]              │
└──────────────────────────────────────────────────────────────────────┘
```

For small landscape viewports, prioritise the map and End Turn; use a compact two-row control deck with horizontal card scrolling rather than reducing tap targets below accessibility guidance. Portrait uses map → information → docked controls, with scroll/pan that does not trigger unintended combat commands.

## Design and QA gates

- Keep actual navigation **independent of animation and combat RNG**; UI must never mutate CombatEngine rules to reproduce the picture.
- Tap vs drag discrimination; pointer movement within a gesture threshold must not unintentionally select/move/attack. A two-finger pinch must not fire a cell action.
- Touch selection remains pixel-accurate at minimum, default and maximum zoom and at scrolled camera offsets; never permit camera movement into a region with invalid tactical cells.
- Keyboard and mouse fallbacks for camera, weapon/spell selection and End Turn; visible focus and labels. Touch drag on the spell strip scrolls spells, never the battlefield.
- Scope and acceptance tracked in [FEAT-015](../specifications/features/FEAT-015-ipad-camera-projectiles-and-card-actions.md). Feature implementation is a **later build**, not part of recording this design direction.
