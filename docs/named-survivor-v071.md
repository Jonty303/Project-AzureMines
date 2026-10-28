# Combat v0.7.1 — Hesk, Roadwatch and Surviving Enemies

**Implemented on the existing feature branch.** The four canonical level-1 heroes are unchanged.

## Named goblin

Hesk, Roadwatch is the northern melee goblin (actor ID goblin_blade; persistent NPC ID hesk_roadwatch). He has a shortsword (1d6+2 slashing), shield, AC 16, 9 HP, and a distinct original 64px SVG combat sprite. The other melee goblin keeps a knife; two goblins wield shortbows.

## Combat outcome rules

- Hesk has death_saves=true. He falls unconscious at 0 HP unless killed by massive excess damage, and may make Death Saving Throws while initiative continues. Adventurers still make their usual Death Saving Throws.
- Ordinary goblins use the normal monster convention: they die when reduced to 0 HP, unless subdued deliberately.
- The Subdue toggle is only available for melee weapon attacks. An attack that would reduce a creature to 0 HP instead leaves it unconscious at 1 HP and starts a Short Rest (2024 nonlethal rule). Ranged attacks cannot use Subdue.
- Damage at 0 HP adds Death Saving Throw failures; Critical Hits add two. Massive excess damage can kill instantly.
- Battle ends when one side has no one capable of fighting, even if named enemies remain unconscious or stable. A knocked-out 1-HP opponent is not combat-capable.
- Stabilisation at 0 HP is not a revival; the creature remains unconscious until healed or otherwise recovered.

## Postbattle options currently playable

If Hesk survives, the victory narrative identifies his condition and allows Brunna to attempt DC 10 Medicine first aid or cast prepared Cure Wounds, actually spending a level-1 spell slot. A successful Medicine check stabilises a 0-HP victim; a nonlethal 1-HP knockout can awaken through successful first aid. Actual healing can restore consciousness. Dead creatures cannot be revived with these actions. The UI prevents repeated free first-aid clicks in the same aftermath.

The board renders a downed pose for an unconscious or knocked-out creature even when the latter has 1 HP. The engine exposes named survivors with stable NPC IDs for future narrative interactions.

## Still planned, not claimed as playable

- Release, capture, bargain, execute and leave-behind outcomes; consequences for Hesk's family, the goblin leader and town quests.
- A released Hesk can separately raise **lair readiness** and improve **diplomatic attitude**; armed guards can still grant a parley.
- Persistent save/load for NPC identities and decisions, overland return travel and the narrative choice runtime.
- Out-of-combat world time, Short Rest expiry, continuing fate of a 0-HP survivor, and broader death/condition edge cases.

## Test coverage

tests/test_named_survivors.gd checks combat states, ordinary-vs-named deaths, massive damage, knockouts, victory on incapacitation and actual healing slots. tests/test_named_survivor_ui.gd exercises the story scene's postcombat First Aid and Cure Wounds controls. Godot 4.5.2 runs both in CI alongside the existing suite.

Rules reference: 2024 SRD 5.2.1 pages 17–18; Falling Unconscious, Knocking Out a Creature, Death Saving Throws, and Stabilizing a Character.
