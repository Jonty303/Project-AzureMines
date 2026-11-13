# FEAT-018 — Combat Lab v0.5 Magic & Tactical Effects

**Status:** Approved direction; staged development, not yet feature-complete.
**Branch:** `feature/combat-lab-v051-magic-controls-slots`, rooted at validated PR #15 head `f41eba85eaabf9c81dbf38899c8b41b690b13c07`.
**Scope:** Standalone Combat Lab only; `main`, narrative development, and live iPad builds remain unchanged.

## Owner-approved design
- Primary **Attack** and **Spell** buttons activate targeting modes; secondary current **Weapon** and current **Spell** chips sit immediately below them and open a **roll-up selector above that chip**.
- Roll-up spell list groups spells by **cantrip / spell level**, with redundant level numerals and colours; known/prepared spells with no legal cast remain **visible but disabled**, with a reason on touch/help. Unknown/unprepared spells are absent.
- Per-character spell-slot resources are visible near the Spell chip. Each tier has lit/unlit gems and a numerical fraction; cantrips do not spend slots.
- Avoid coupling UI to specific spell effects: engine legality and typed data drive selector states.
- Full-caster level progression: at levels 1–5, total slots are L1: 2/3/4/4/4, L2: 0/0/2/3/3, L3: 0/0/0/0/2. These slots are **resource scaffolding**, not implied level-three spells or other unimplemented class features.
- **First full battlefield-control showcase: Web**, using persistent area regions, terrain modification, concentration, restrained + escape actions and fire interaction. Use general-purpose mechanisms shared by future spells and enemies.
- Six level-two spells approved for later slices: Web, Misty Step, Mirror Image (Elyra), Aid, Hold Person, Lesser Restoration (Brunna); only available at appropriate character level, with complete SRD 5.2.1 rules and tests.
- Complete and correct first-level toolkit as discussed: Guiding Bolt, Spare the Dying, Hunter's Mark, Ray of Frost slowing; then Sleep/Burning Hands, with effects and area templates validated.

## Slices and deliverables
1. **v0.5.1:** UI redesign and separate slot-tier resource model, including tests for availability, level grouping, disabled actions, slot expenditure and no level-two spells at character level two. Preserve the current casts and v0.4.3 tests. Higher-level casts/upcasting must not silently behave as lower-level effects.
2. **v0.5.2:** reusable persistent-zone and condition foundation with deterministic event schemas, movement/AI integration, line-of-sight/cover and concentration lifecycle.
3. **v0.5.3:** Web end-to-end, then remaining level-two spells in small reviewable PRs; add VFX and touch area preview.
4. **v0.5.4:** first-level spell completeness, monster effects/AI responses, visual/audio polish and manual balance acceptance.

## Acceptance and limitations
- Godot 4.5.2 smoke + every existing Combat Lab test green; new tests for selector interactions and slot progression.
- Manual iPad Safari test for upward picker, accessibility, visible remaining slots and target highlighting. Headless tests do not establish touch acceptance.
- Do not make an incomplete Web spell selectable, and do not represent level-two or third-level spells as available until their effects are implemented.
- No automatic merges, Web deployment or campaign integration.

See [Issue #16](https://github.com/Jonty303/Project-AzureMines/issues/16) and [PR #15](https://github.com/Jonty303/Project-AzureMines/pull/15).


## v0.5.2 implementation candidate — issue #18 / draft PR #19

The engine owns schema-one transient regions and source-indexed Restrained applications. Explicit enter/start/end hooks and round/initiative expiry drive shared terrain, movement, AI and concentration cleanup; board/UI only read snapshots and submit commands. A non-selectable 4×4 test fixture proves the shared API. Bless/slot contracts remain compatible. Full Web, visibility/obscurement, fire and manual placement remain v0.5.3 work, not implemented spells. See [ownership, exact timing, modified paths and executed validation](../../docs/combat-lab-v052-persistent-effects.md). Owner/physical iPad acceptance is pending.
