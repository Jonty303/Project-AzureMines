# Azure Mines — canonical reference art v1

The primary visual reference is the **red-robed Elyra party lineup** previously approved for Alden, Elyra, Brunna and Pip. Full-resolution reference illustrations and extracted portraits remain in the separately provided project art ZIP.

## Shipped placeholder sprites

Four front-facing 32 × 32 indexed-colour PNGs are stored at:

- `assets/characters/sprites/alden_front_32.png`: blue/silver human Champion
- `assets/characters/sprites/elyra_front_32.png`: red/gold High Elf Evoker
- `assets/characters/sprites/brunna_front_32.png`: white/gold Dwarf Priest
- `assets/characters/sprites/pip_front_32.png`: green Halfling Thief

Godot renders these using nearest-neighbour filtering. The full-resolution portrait paintings and master sheet are **not** included in this initial code PR because those are large source assets; import them separately before portrait polish. Do not infer from the fixture's `portrait` paths that those PNGs are present in this branch.

There is only **one front-facing combat sprite per character**. No directional frames or mirroring are used in the prototype. Future equipment-dependent sprites must be separately authored.
