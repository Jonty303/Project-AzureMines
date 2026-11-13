# Combat rules — v0.1

**Target:** separate overhead 2D grid-based combat, with modern SRD 5.2.1 adjudication and Gold Box presentation.

## Baseline

| Area | Design |
| --- | --- |
| Squares | 5 ft, 8-direction movement; cost normally 1 square per step, including diagonal |
| Turn order | Individual initiative; ties broken deterministically |
| Surprise | Disadvantage on initiative per 2024 rules |
| Turn economy | Movement + Action + optional Bonus Action; Reaction tracked per combatant |
| Rolls | d20 + modifiers against AC / DC; Advantage / Disadvantage |
| Terrain | Difficult terrain, cover, LOS, blocked corners, reach |
| Damage | Typed damage, resistance, immunity, vulnerability, temporary HP |
| Conditions | Standard SRD conditions and explicitly timed effects |
| Magic | Spell slots, concentration, saves, area shapes, duration, friendly fire |
| Mastery | Weapon Mastery properties, checked against character training |
| Defeat | Death saves for PCs, ordinary monster death, nonlethal outcomes as required |
| Presentation | No facing, no universal flanking bonus initially |

## Action resolution contract

1. Intent is a command with actor ID, kind, declared targets and parameters.
2. Validate action economy, legal tiles/targets, resource costs and rules constraints.
3. Determine relevant pre-resolution triggers and potential reactions.
4. Roll through injectable RNG and resolve individual effects.
5. Commit updated state and emit an ordered log of structured events.
6. UI reads the events; AI submits commands through the same validator.

Movement is segmented into tile transitions so that reactions can interrupt it. Effects need lifecycle hooks (on apply, start/end turn, on damage, on save, on expire) and causal IDs for debugging.

## Combat playback speed — presentation contract (agreed 13 November 2026)

Support selectable combat playback rates so large encounters with many enemy turns remain comfortable to play. Proposed initial options: **Normal 1×**, **Fast 2×**, **Very Fast 4×**, with a possible later **Instant/minimal-animations** option. A persistent, accessible control should be available in Combat Lab and eventually normal combat, particularly for touch/iPad.

This is a **visual scheduling / event playback** requirement, not a change to turn order, AI decision-making, action economy, random-number generation, hit/miss, conditions, durations, reactions or rules processing.

- CombatEngine emits an ordered, causally linked record of resolved events at normal deterministic rules speed. The presentation timeline consumes the same events at different visual durations; changing playback speed cannot re-resolve a command, skip rule events, mutate combat state or change RNG draws.
- Scale only presentation durations: interpolated movement, 2–3-frame walk cycling, 2-frame attack/cast poses, projectile travel, effect holds and brief recovery pauses. Keep essential action identity, hit/miss, damage, impacts, kills, status indicators and the combat log understandable at higher rates.
- Preserve attack-to-impact causality. A projectile must reach the target before displaying the associated hit/death animation; death and incapacitation cannot be shown early at any playback rate.
- Reactions, interrupts and any required player input must pause playback at a clear stable point, regardless of speed. Do not auto-dismiss decisions or skip information the player must act upon.
- Allow user control of speed between actions, and define safe handling of mid-animation speed changes (e.g. apply to the next presentation segment or rescale its remaining visual time without changing the event order).
- Persist the player's preferred speed separately from saved combat rules state. Consider an **enemy-turn fast playback** preference later, but do not silently speed up player-facing decisions.

Tests should run an identical seeded encounter with each speed and compare the authoritative event log/final combat state; test that a player reaction is never skipped and that visual impact ordering is preserved.

See [Modular character sprites and minimal animation](modular-character-sprites.md) for the small-frame asset plan whose animation timeline this feature controls.

## First milestones

1. Four vs four battle: grid, initiative, movement, melee/ranged hits, HP, victory.
2. Tactical depth: cover, terrain, reactions, Sneak Attack, mastery, Hunter's Mark.
3. Magic: slots, healing, saves, concentration, areas, timed conditions.
4. Classes to level 5, enemy AI, larger combatants, rewards and encounter tests.

## Testing

Test dice, modifiers, initiative, ties, movement legality, attack math, Advantage and Disadvantage, cover, reactions, concentration saves, duration expiry, damage types, death saves and per-turn class triggers **without running the combat scene**.

## Deferred mechanics

Mounted, underwater, flying and highly vertical battles, sophisticated environmental destruction and elaborate NPC AI are out of the first prototype, but should not require a rewrite to introduce.

No battle engine is implemented in this bootstrap.
