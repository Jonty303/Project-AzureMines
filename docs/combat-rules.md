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
