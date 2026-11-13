# Combat Lab v0.5.4 original production pixels

These PNGs are new coordinate-authored art, not extractions from the approved reference compositions. Authoring source: `scripts/build_combat_art.py` (Pillow, already available in the task environment; not a game runtime dependency). The JSON manifest records source boxes, pivots, equipment/facing, animation duration, footprint and provenance. Native `.tres` SpriteFrames are included for all five monster sheets and the VFX sheet. No general outbound license has been selected: see `docs/licensing.md`.

Source floor cells are 32x32; wall cells 32x48 include 16px upper headroom. Monster frames are 48x48, pivot (24,41), with 2px minimum alpha gutters. Monster rows are separately authored left/right melee and, only for existing goblin shortbow/kobold sling equipment, left/right ranged. Walk has three frames; melee and ranged attacks two; idle two; hit and defeated one. Bugbear is delivered as an asset only, with no new combat stat block. Party characters have no added sheets or animations.

The existing board uses a 68px pitch with nominal 64px actor art. It retains that geometry and all camera/input transforms. Terrain uses nearest filtering. AtlasTextures set filter_clip; PNG import is lossless, without mipmaps. Obstacle drawing uses the fixture footprint exactly once, with upper headroom. JSON cover/collision descriptions are informational; CombatEngine fixtures remain authoritative. Crate/barrel assets are available without inventing new fixture blockers.

VFX rows: flame, smoke, embers, Web, burning Web, Fire Bolt, Magic Missile, frost, Bless, healing, Shield/Mage Armor, radiant/Sacred Flame, impact, concentration arcane, slash, arrow and sling stone. Four frames each. No Sleep/Hold Person assets or mechanics. All particles are bounded texture loops; no simulation changes or particle-node accumulation.

Regenerate with `python3 scripts/build_combat_art.py`; validate with `python3 scripts/validate_combat_art.py`. Art direction and final iPad visual acceptance remain human decisions; these files do not imply owner acceptance.
