# Combat Lab roadmap — 2026-11-12

This branch is intentionally **not** the Azure Mines narrative game.

| Stage | Deliverable | Current status |
| --- | --- | --- |
| LAB-0 | New isolated branch; eliminate narrative runtime, assets and story-specific tests | Implemented |
| LAB-1 | Title screen, party levels 1–5, optional Hunter slot, configure enemy/archetype/count/arena/seed | Prototype implemented |
| LAB-2 | Deploy/fight/replay, debug input and last battle result/log persisted to user:// | Prototype implemented; automated CI passing |
| LAB-3 | FEAT-009 hardened setup/result/events with reusable entity/state contracts | Planned |
| LAB-4 | FEAT-011 improve graphics and introduce slashes, hit/miss, spells, healing/reactions VFX | Planned |
| LAB-5 | FEAT-012 level-two class features/resources and several distinct monster archetypes | Planned |

**Not implemented:** Complete character progression for levels 2–5, full spell catalogue, mixed enemy types, morale/surrender, advanced conditions, polished new animations, physical controller/touch, canonical Hunter sprite. These must not be claimed from the UI's test-level selector.

**Future narrative branch:** The retained narrative code remains in the original game-development branches; integration later uses a reviewed CombatSetup/CombatResult contract and independent NPC registry.
