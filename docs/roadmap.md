# Combat Lab roadmap — 2026-11-12

This branch is intentionally **not** the Azure Mines narrative game.

| Stage | Deliverable | Current status |
| --- | --- | --- |
| LAB-0 | New isolated branch; eliminate narrative runtime, assets and story-specific tests | Implemented |
| LAB-1 | Title screen, party levels 1–5, optional Hunter slot, configure enemy/archetype/count/arena/seed | Prototype implemented |
| LAB-2 | Deploy/fight/replay, debug input and last battle result/log persisted to user:// | Prototype implemented; automated CI passing |
| LAB-3 | FEAT-009 hardened setup/result/events with reusable entity/state contracts | Structured event v1 implemented; further result/identity hardening planned |
| LAB-4 | FEAT-011 improve graphics and introduce slashes, hit/miss, spells, healing/reactions VFX | v0.3 procedural effects implemented; sprite/effects polish planned |
| LAB-5 | FEAT-012 level-two class features/resources and several distinct monster archetypes | Planned |

**Not implemented:** Complete character progression for levels 2–5, full spell catalogue, mixed enemy types, morale/surrender, advanced conditions, polished new animations, physical controller/touch, canonical Hunter sprite. These must not be claimed from the UI's test-level selector.

**Future narrative branch:** The retained narrative code remains in the original game-development branches; integration later uses a reviewed CombatSetup/CombatResult contract and independent NPC registry.

## Latest — Combat Lab v0.3

- Release target: `feature/combat-lab-web-touch` deployed via verified Godot 4.5.2 Web export to [GitHub Pages](https://jonty303.github.io/Project-AzureMines/).
- Feature development: `feature/combat-lab-v03-tactical-feedback`. Event contract and initial procedural VFX are complete in code and headless tests; real iPad action/feedback inspection remains pending.
- Next: iPad tap/animation playtest, more precise sprite animation/VFX timing, broaden combat result schemas and eventually mixed enemies/AI morale.
