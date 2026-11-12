# FEAT-017 — Multi-tile creatures and large-creature presentation

**Status:** Proposed design, based on the owner's 12 November 2026 direction; **NOT IMPLEMENTED**.
**Scope:** Generic combat-engine footprints for creatures from Small to Gargantuan, with art and interaction contracts. No new monster mechanics, playable dragon/giant encounter, or campaign rules are included in this document.
**Dependencies:** FEAT-009 combatant definitions/instances and event contracts; FEAT-015 camera/input and projectile rendering.
**Review gate:** Approve exact collision, downed-body, movement, reach, and schema compatibility policies before implementation.

## Goal and terminology

A large sprite is **not** a large combatant. Store **physical space** as a grid footprint in authoritative combat data, independent of how far wings, weapons, tails, shadows or spell effects extend visually.

Assume the existing square grid represents 5 feet per square. Proposed initial mapping:

| Size category | Tactical space | Illustrative creatures |
| --- | --- | --- |
| Tiny | 1×1 initially (shares a square under later rules, not implemented) | Familiar, tiny animal |
| Small / Medium | 1×1 | Goblin, adventurer |
| Large | 2×2 | Ogre, horse, some dragons |
| Huge | 3×3 | Some giants and dragons |
| Gargantuan | 4×4 **or larger**, definition-driven | Very large/ancient dragons |

These are **size categories**, not fixed creature-type rules: dragons and giants have more than one possible size. A creature's category must be declared by its definition, not inferred from its sprite dimensions or name.

The first generic implementation should support square footprints from 1×1 through 4×4, leaving room for authored larger square footprints and future non-square/special silhouettes without a rewrite. The exact upper bound and Tiny-sharing rules require separate approval.

## Proposed data shape (NOT CURRENT SCHEMA)

A backward-compatible additive proposal for a future versioned `CombatantDefinition`:

```json
{
  "id": "example_large_creature",
  "size_category": "large",
  "footprint": {"width": 2, "height": 2},
  "art": {
    "combat_sprite": "res://assets/creatures/example_large_creature.png",
    "visual_anchor": "feet_center"
  }
}
```

The `CombatantInstance.position` remains a stable, integer **top-left anchor cell**. A creature at (7, 3) with a 2×2 footprint occupies (7,3), (8,3), (7,4), (8,4). The footprint is authoritative for occupied cells; graphic bounds are separate. This example is **a proposal**, not a live fixture.

**Migration policy:** Current instances without a declared footprint must behave exactly as 1×1. No breaking changes to current version-one CombatSetup/CombatResult should be made silently; any persisted schema changes need an explicit version, validation and round-trip/migration tests. Reject dimensions outside policy, out-of-grid anchors, and initial overlapping occupied cells.

## Engine responsibilities

1. **Occupancy:** `occupied_cells(actor_id)` yields every grid square held by the creature. Queries for any occupied square return the same stable actor ID. A creature may not overlap another active body's space or impassable geometry; draw layers and world-space transparency are irrelevant to this rule.
2. **Movement/pathfinding:** A candidate anchor is legal only if **all cells** of the translated footprint are legal. Pathfinding uses legal placements of the whole body, not a path for its top-left cell alone. A Large creature cannot traverse a one-square gap; a Huge creature cannot fit through a two-square passage. For diagonal movement, apply the same no-corner-cutting policy to the **entire swept footprint**. Each anchor step consumes normal/difficult terrain costs according to an explicitly approved policy; do not multiply movement by the number of occupied squares without a rules decision.
3. **Range and reach:** Measure distance between the **nearest relevant occupied squares** of two creatures, not their anchors or sprite centres. Melee reach and 5-foot threatened squares surround the full footprint; weapon reach remains independently specified. Adjacent 1×1 heroes may attack the creature from multiple edges.
4. **Opportunity attacks:** Check whether movement leaves an opponent's threatened area across the **full footprint**, not only whether the anchor moves. Avoid triggering a fresh opportunity attack on every occupied cell of a single move; the engine resolves the event/decision once per rules-defined opportunity.
5. **Line of sight and cover:** Resolve visibility from/into occupied squares using a deterministic, testable selection policy; cover and obstacles must not be assessed solely against the top-left anchor. A large creature must not gain free line of sight through an otherwise blocked wall merely because its sprite overhangs the wall.
6. **Area effects:** A 2×2 or 3×3 creature caught by an area is **one target**, not four or nine separate damage applications. Determine intersection with any occupied cell once, subject to the future effect geometry rules.
7. **Movement interactions:** Doors, choke points, terrain hazards, forced movement, knockback and deployment must verify the entire footprint. Do not silently push surrounding actors when a large enemy spawns.
8. **Downed bodies:** Whether unconscious/dead large creatures block squares is an **explicit pending rules decision**. Current 1×1 rules should not be silently reinterpreted.
9. **AI:** Tactical candidate positions, scoring, attack range, approach lanes, flanking/reach and threat avoidance must query the same footprint-aware methods as the player, not a separate ad hoc giant pathfinder.
10. **Events:** Preserve stable actor/target IDs and deterministic events. Resolve projectile **launch/impact points on the actual occupied bodies**, not automatically at their anchor; include the relevant grid/world-space snapshots for visual interpolation without changing attack outcomes.

## Rendering and touch input

- Draw a selected creature's **base outline covering all occupied tiles**. Team colour, health/status effects and highlight should make the actual tactical footprint unambiguous, especially at iPad zoom-out scale.
- Anchor the sprite at the **feet/ground-contact position** of the occupied body (typically bottom-centre). Its silhouette, wings, weapon, mane or tail may extend beyond these cells **without blocking** nearby squares or automatically adding reach.
- Separate **combat footprint**, **sprite visual bounds**, **optional pointer hit area**, **ground shadow**, and **render layer**. Decide sprite click-through explicitly; tapping any occupied cell selects the same actor. Never let a transparent overhang steal an adjacent legal cell's combat tap.
- Depth-sort sprite bases using ground contact/foot row, not art texture height. Keep shadows and hit markers aligned while the board pans, pinches and zooms.
- Movement animation and eventual walking/wing cycles interpolate the whole base. A large creature's travel must neither clip at the camera edge nor visually teleport between anchored cells.
- Selection effects and projectile impact animations should remain tied to authoritative combat events. A huge creature's death pose may be visually much larger than its ground footprint, but death/impact timing still follows resolved events.

## Later, separate capabilities

- **Flight/altitude:** Preserve a ground footprint or projection and model airborne altitude, landing, overflight and collision independently. **Being a dragon does not automatically bypass walls, other creatures or opportunity attacks**. No flight mechanics are approved by this spec.
- **Breath weapons:** Cone/line templates, saving throws, area collision, damage and turn timing are a separate rules feature; do not infer them from creature size.
- **Facing/rotation:** Initial square footprints do not require a new facing system. Directional footprints, long creatures, mounts/riders, grappling, squeezing and Tiny creatures sharing cells are deferred for explicit specification.
- **Boss scale:** The existing 17-column camera/zoom view is a foundation, not proof that a 4×4 boss can navigate every current map. Author large arenas with multiple viable approach routes.

## Suggested delivery slices

1. **Foundation:** Versioned footprint data and validation, backward-compatible 1×1 defaults, occupancy tests.
2. **Movement/range:** Shared full-footprint collision, swept movement, reach, line-of-sight and AoO tests; keep current 1×1 behaviours unchanged.
3. **First art fixture:** One **Large 2×2 noncanonical test monster** with original sprite, ground shadow and selection tiles in a suitable wide arena. No new monster-specific attack features needed.
4. **AI and VFX:** Footprint-aware pathfinding and ranged projectile endpoint checks, plus iPad pan/zoom/touch acceptance.
5. **Huge 3×3 proof:** Add a 3×3 fixture on a suitably authored arena, run a navigation/attack/retreat/death presentation scenario.
6. **Gargantuan:** Definition-driven 4×4+ support after geometry/performance testing and owner approval; do not imply an ancient dragon is implemented.

## Acceptance checklist (planned, not yet run)

- [ ] Missing footprint fields continue to behave as 1×1 and save/load without regression.
- [ ] Invalid/out-of-bounds/overlapping 2×2 and 3×3 spawns are rejected with clear diagnostic errors.
- [ ] 2×2 blocked by a one-square opening; 3×3 blocked by a two-square opening.
- [ ] All occupied tiles return the same actor ID; taps and selection outlines work under camera pan and pinch.
- [ ] Enemy and allied approach/retreat paths do not clip walls or pass through other creatures.
- [ ] Melee, reach, cover, ranged, opportunity attacks and AoE resolve correctly from/to footprint perimeters.
- [ ] Hazards and area damage apply according to reviewed rules **once per target**, not once per occupied tile.
- [ ] Motion/projectiles/death visuals use appropriate anchors, while exact deterministic engine outcomes remain unchanged.
- [ ] Existing 1×1 combat tests, Godot 4.5.2 smoke checks and Web export remain green.
- [ ] Physical iPad acceptance records readability, touch precision and sprite clipping for the larger creature.

## Status and boundaries

This file captures a **design direction agreed in conversation**. No multi-tile creature is playable in the current Combat Lab and no combat rules were changed by writing this specification. The exact rules and data-schema decisions remain **proposed** until individually reviewed.
