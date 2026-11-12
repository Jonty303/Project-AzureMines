# FEAT-016 — Downed turns, death-save autonomy, movement and impact staging

**Status:** Implemented on the isolated Combat Lab branch; automated Godot checks, manual iPad acceptance pending.
**Branch:** `feature/combat-lab-v041-downed-turn-impact`.
**Owner decisions:** 12 November 2026 after v0.4 playtest.

## Requirements and exact semantics

### Downed party members
- **Unconscious (0 HP):** Retain an initiative position only for an automatic death saving throw; do not present any player commands or require End Turn. The game proceeds immediately to the next combat-capable creature after the roll.
- **Natural 20 on death save:** Restore 1 HP and the active state; the recovered hero may act on that initiative turn. Natural 1 counts two failed saves. Three successes stabilise; three failures cause death, per existing limited mechanics.
- **Stable:** No automatic death saves; skip initiative without input. **Dead / nonlethally knocked out:** skip.
- **Party tab:** Display death-save success and failure counts for unconscious characters; show stabilised status.
- **Healing:** A downed ally remains selectable as a *target of healing*. This is distinct from being the active, controllable character.

### Enemy targeting
- Regular tactical AI selects only combat-capable opponents; it does **not** intentionally finish off unconscious or stable characters. The selection tests enforce this.
- Deliberate finishing blows might later be introduced as an explicit, reviewed AI profile/morale policy, not a hidden default or named-NPC-specific rule. This has **not** been implemented.
- The current tactical engine already allows damaging downed targets through its shared damage rule if another external effect resolves; preventing intentional AI targeting does not grant invulnerability against hazards or future scripted effects.

### Movement presentation
- Emit no new movement rules: existing authoritative `move` events already contain the actor, source and destination cells.
- The board queues and interpolates each tile segment (initial duration ~115 ms) instead of teleporting directly to the engine's final position.
- Multiple steps for the same actor animate sequentially; different actors remain separately tracked. An attacker completing a move before firing waits until the movement presentation finishes before launching their projectile.
- The animation is additive: pathfinding, movement cost, opportunity attacks and the resulting combat state do **not** wait or roll again. A new combat/retry clears pending visual movements.

### Fatal projectile staging
- The engine's outcome, resource spending, RNG, casualty state and event log remain **authoritative immediately** on resolution.
- Weapon/spell hit events now carry `hp_before`, `hp_after` and `state_after` for visual staging. The existing typed events retain source and target cell snapshots.
- If a projectile kills or downs a previously standing target, its *battlefield sprite* and displayed health bar temporarily show the pre-impact state until the projectile lands. On arrival, hit and death/collapse feedback begin together. A death sound linked to that projectile is likewise delayed until impact.
- Instantaneous melee/area effects and automatic death saves do not wait for unrelated missiles. A target already downed is not made to stand up for a later projectile.
- This is a **visual hold**, not a mutation or second copy of the simulation. Sidebar/debug results and structured event logs may show final authoritative state before the effect plays.

## Acceptance checklist
1. Down a hero and continue combat without a forced player action/End Turn; see death-save result in Log and counters in Party.
2. Verify stable/unconscious/dead skip rules; a natural 20 must restore the hero's playable initiative turn.
3. Ordinary enemies must still attack living threats and not purposefully select helpless characters.
4. Walk a multi-tile path; watch the sprite cross tiles in sequence and not teleport. Attack following movement must launch after travel finishes.
5. Kill a goblin with a ranged arrow or Fire Bolt; its standing pose remains until impact, then the impact/collapse and death sound occur.
6. Healing, retaliation/opportunity attacks, hit/miss feedback, camera pan/zoom and the docked bottom controls continue working.
7. Confirm the iPad Safari experience on actual hardware; record build SHA, iPad model and iPadOS/Safari versions.

## Automated evidence
- `tests/test_v041_downed_auto_turn.gd`: reproducible natural-1 and natural-20 outcomes, stable skip, no downed UI actions, AI active-threat selection and Party status.
- `tests/test_v041_movement_impact.gd`: interpolation order, projectile death visual hold, delayed hit/collapse sound contract and reset.
- Existing Combat Lab regression suite unchanged except adding these tests.
- Only GitHub Actions headless tests count as automated evidence; they are not proof of visually smooth physical Safari animation.

## Deliberate exclusions
No narrative NPC registry, new enemy classes, advanced AI execution policies, game balance changes, new spell/HP rules or complete multi-actor choreography director.
