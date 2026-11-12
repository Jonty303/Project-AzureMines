# FEAT-011 — Combat artwork and visual feedback polish

**Status:** Proposed detailed spec; visual polish objective approved 2026-11-12
**Depends on:** FEAT-010 Combat Lab
**Branch:** feature/standalone-combat-lab

## Purpose
Improve the tactical board's appearance and legibility, introducing restrained melee and spell animations without changing the outcome of actions.

## Human instructions
Approve a consistent visual direction (retaining the current 64px pixel/sprite look), review before/after captures, motion clarity, colour contrast, effect intensity and any licensed assets.

## AI agent instructions
Work from existing sprite/board/UI assets. Never make animation timing authoritative; test gameplay outcomes with effects enabled and disabled. Do not claim headless parse proves visual quality.

## Specification
- **Art:** Improve silhouette consistency, edge/colour contrast and ground contact for the four party sprites and representative enemies; preserve nearest-neighbour pixel readability where relevant. Review terrain/props against sprite scale.
- **UI:** Clarify selected actor, reachable tiles, chosen weapon/spell, valid targets, HP, damage and active reaction. Avoid visually noisy highlights and screen-covering effects.
- **Melee:** Short directional slash/impact streak around target, distinct miss treatment, restrained hit flash; do not add a fake extra attack.
- **Spell:** Simple readable authored effects for representative current spells: Fire Bolt (projectile/impact), Ray of Frost (cold trail), Sacred Flame (radiant burst), Magic Missile (multi-hit cue), Cure Wounds/Healing Word (healing pulse), Shield (brief shimmer), Bless (support mark). Start with two representative spells and expand only after reviewing readability.
- **Presentation contract:** Consume committed combat outcomes from engine.events or a reviewed structured extension. If source/target IDs are missing, add presentation metadata without changing resolution or public mechanics.
- **Timing:** Small non-blocking effect window, no action-economy delay, no obstruction of target selection; queue/bound concurrent effects and clear them on reset.
- **Accessibility:** Provide reduced-motion/effect-intensity option or minimally invasive equivalent, preserve legibility without colour alone and avoid excessive flashes.
- **Constraints:** Use original assets or verified licences; keep animations in scenes/presentation, not rulesets or authored encounter data.

## Acceptance and evidence
- **FEAT-011-AC01:** Existing battle renders with consistent sprite scaling, target highlights and readable action states at intended desktop resolution.
- **FEAT-011-AC02:** Melee hit and miss are visibly distinguishable; slashes align with source/target positions and do not persist after reset.
- **FEAT-011-AC03:** At least two different spell effects visibly resolve from the same combat results; expand catalogue incrementally.
- **FEAT-011-AC04:** Damage/healing, resources, turn order and event log are identical with effects on vs off for a fixed seed.
- **FEAT-011-AC05:** Concurrent/reaction effects do not leak scene nodes or duplicate sounds after repeated reset.
- **FEAT-011-AC06:** Evidence includes real desktop screenshots or video of action states and effects; headless visual sign-off alone is not allowed.
- **Automated checks:** Presentation-event mapping unit tests; existing combat/UI regression suite.
- **Manual checks:** Positive/miss cases, spell variations, readability and motion preferences at normal resolution.
- **Human sign-off:** Pending.
<!-- [EXAMPLE ONLY] An elaborate particle engine is unnecessary for a simple slash visual. -->
