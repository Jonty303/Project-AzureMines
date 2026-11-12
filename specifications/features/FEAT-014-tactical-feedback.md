# FEAT-014 — Combat Lab v0.3 tactical feedback

**Branch:** feature/combat-lab-v03-tactical-feedback
**Status:** Implemented prototype, awaiting physical iPad acceptance
**Rules engine:** Godot 4.5.2 standard/GDScript; canonical combat rules are unchanged.

## Goal
Give players clear touch-first tactical feedback and a clean event contract for future audiovisual polish.

## Implementation
- The Combat Lab top bar contains battle status, Retry and Return to Title only.
- Debug Input/Output is in the Actions tab, while the Log tab owns the full-log action. The title-screen debug inspector remains available before initiating combat.
- Actions, Party, Details and Log remain permanent sidebar tabs in iPad landscape, stacked in portrait.
- In the Actions tab, Move, Attack and Spell visibly indicate which targeting mode is active. Hints describe movement, valid targets, reactions and deployment.
- Party lists current HP, AC and implemented resources (spell slots, Second Wind), with applicable buffs such as Bless/Mage Armor.
- The authoritative combat engine emits versioned, ordered `hit`, `miss`, `cast`, `heal`, `move`, `death`, `log` and `audio` events. Identity fields, action ID and resolved damage/healing quantities accompany relevant facts.
- The battlefield consumes only structured events to draw short non-blocking slash lines, spell rings, healing numbers, misses and incapacitation labels. Effects are **presentation only** and cannot alter HP, RNG or turn order.
- VFX is reset between fixtures/retries. Event text and sound remain available as before; reports still store the complete event sequence.

## Acceptance matrix
1. Godot imports and runs; all prior combat and touch tests remain PASS.
2. Deterministic weapon damage emits an actual `hit` event with attacker, target, amount and type; heal and spell cast events carry actual resolved amounts.
3. Every event has `schema_version: 1`, deterministic `event_id`, `kind` and `round`; prose is optional.
4. UI routes new resolved events into an additive transient VFX layer, without introducing game-state changes.
5. No redundant Log/Debug buttons in top bar; Debug is reachable within Actions.
6. Physical iPad Safari: confirm action selection, hit/miss visibility, healing/spell visual cues, layout and performance (**NOT RUN until owner playtest**).

## Deferred to v0.4
- Mixed creature rosters, independent AI/morale/surrender.
- Additional canonical level-two class abilities/spell slots.
- Art-authored sprite animation sets and projectile sequences; this prototype uses lightweight procedural effects.
- Complete engine-origin damage attribution for hazards/death saves (the event schema permits further enrichment).

## Excluded
No new narrative, NPC registry, campaign saves, reward grants or game-engine rewrite.


## v0.3.1 — iPad command-bar correction

The owner found character actions in the right-hand sidebar unintuitive. The design now makes the **bottom action bar** the single location for deployment, formations, combat actions, weapon/spell selection, reactions and contextual hints. The right-hand sidebar provides **Debug, Party, Details and Log** tabs; the initial tab is Party. Debug Input/Output remains in Debug. This is purely presentation reparenting and does not change CombatEngine action rules or event payloads.

Acceptance: board occupies the upper play area, bottom action bar remains available on iPad landscape, contextual effects and highlighting work, and sidebar tabs stay informational. Automated tests verify the hierarchy; physical Safari acceptance remains pending.
