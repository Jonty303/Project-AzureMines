# Character reference artwork

Master reference: **Alden (blue), Elyra (red), Brunna (white/gold), Pip (green)**.

For the initial tactical prototype, keep **one front-facing static 32 x 32 PNG combat sprite** per character and a separate portrait PNG. Do not implement directional sprites yet. Use nearest-neighbour texture filtering for small sprites.

The baseline fixture references:

```text
assets/characters/
  reference_party.png
  portraits/alden.png
  portraits/elyra.png
  portraits/brunna.png
  portraits/pip.png
  sprites/alden_front_32.png
  sprites/elyra_front_32.png
  sprites/brunna_front_32.png
  sprites/pip_front_32.png
```

**Asset status:** The raster artwork is distributed as an export bundle separately from this GitHub commit until the binary assets are imported. This file specifies paths and identities only; it does not claim the PNG files are present in the repository. Source sheet / derivative sprites should be visually reviewed before final production use.
