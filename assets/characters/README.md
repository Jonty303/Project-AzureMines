# Character and goblin sprites

The first playable level-1 combat iteration includes **five transparent 64×64 PNGs**, all individually authored in a front-facing stance:

- `sprites/alden_front_64.png` — blue/silver Human Champion with sword/shield
- `sprites/elyra_front_64.png` — red/gold High Elf Evoker with fire staff
- `sprites/brunna_front_64.png` — white/gold Dwarf Priest with mace/shield
- `sprites/pip_front_64.png` — green Halfling Thief with blades/quiver
- `sprites/goblin_front_64.png` — green goblin holding a knife

All sprites are placeholders. They are drawn in front view **only**, without directional mirroring or animations. Godot uses nearest-neighbour filtering at runtime. The engine maps the immutable test fixture's older `_front_32.png` path to the new `_front_64.png` assets, preserving the v1 fixture.

The originally generated full-resolution portraits and reference composition remain in the separately supplied reference-art bundle. Static sprites are committed here; full paintings are not yet in this GitHub branch.

The `tests/test_sprite_assets.gd` check verifies all five new PNG files decode as 64×64 images.
