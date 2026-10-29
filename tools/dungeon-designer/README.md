# Dungeon Designer v3

An offline, author-only layout editor. Open `index.html` in desktop Edge or Chrome.
No installation or server is needed. Keep this folder beside `adventure-designer`:
the optional overland-reference importer uses that tool's existing validator.

## Start drawing

1. Click **Practice map** for a small, non-canonical example, or **Goblin starter**
   for established area names and author notes on a blank grid. No file picker is needed.
2. Use **+ Add** under Named areas. Enter an ID, name, description and author notes,
   then **Apply details**. A new area is automatically selected as the paint area.
3. Choose **Room rectangle** and drag between opposite corners. Use **Floor brush**
   for irregular caves. Floors are teal and corridors are sand-coloured. Choose
   **Wall block** to paint solid slate-coloured cells; dark cells remain undrawn.
4. Choose **Corridor brush** and paint passages between rooms. Pointer samples are
   joined with four-way steps so even fast diagonal strokes remain connected.
   Set **Paint area** to Unassigned for corridors that do not belong to a room.
5. Choose **Door** for a gold door or **Secret door** for a purple S block. Both
   count as potential passages during validation; discovery, locks and opening
   conditions are not simulated. Walls block connectivity.
6. **Assign area** changes ownership of existing cells without changing their tile
   type. **Erase** removes cells and any markers/features on them. Undo restores the entire stroke.
7. Use **Place entrance** (green E) or **Place exit** (red X), then click a walkable
   cell. For other markers, choose **Place marker**, select its type, and click a cell. Edit its name,
   notes, content reference or destination in the inspector. Select markers from the
   left list when several share a cell; their grid badge shows the count.
8. Click **Save JSON** and check your downloads folder. Load that file next session.
   This downloads a new file; it does not overwrite files or commit to GitHub.

Click **Select** to inspect an area or marker through the grid. Named areas can cover
multiple rooms; each cell belongs to at most one area. Painting replaces a cell's
tile and area assignment. Existing markers and features remain unless the cell is erased or replaced by a wall. Painting
a wall removes those items on that cell, and Undo restores them with the previous tile.
Deleting an area preserves the floor, removes area assignments, and clears local
links targeting that area. These changes can be undone.

**Undo / Redo** holds up to 100 document edits in the current session. Ctrl/Cmd+Z and
Ctrl/Cmd+Shift+Z work outside form fields; inside fields, the browser edits the text.
Unapplied inspector changes must be applied or explicitly discarded before drawing,
selecting another item, saving, or undoing. New/load/starter actions ask before
discarding unsaved work. There is no persistent autosave; closing or crashing the
browser can lose unsaved work. A download request is not confirmation of a saved file.

## Keyboard and view

Tab to the grid. Arrow keys move the highlighted cell; Enter or Space uses the
selected tool. For a room rectangle, Enter marks the first corner and another Enter
marks the opposite corner. Escape cancels a pending rectangle or pointer stroke.
The inspector can edit marker X/Y directly. Zoom changes display scale only; scroll
the canvas viewport to reach the rest of the map. Grid dimensions are 8–64 cells per
axis, default 32 × 24. Shrinking a map is rejected if it would put existing cells
outside its bounds. Erase those cells first, or leave the map larger.

## Symbols and natural features (new in version 3)

Open **Map symbols & natural features**, choose a group, then click a symbol:

| Group | Available symbols |
| --- | --- |
| Doors & barriers | Door, open doorway, locked door, secret door, bars/portcullis, window, railing |
| Travel | Stairs up, stairs down, ladder, trapdoor |
| Room objects | Chest, bed, table, cage, altar, pillar, trap, boulder, stalagmite |
| Natural features | Water/pool, stream, waterfall, rubble, chasm, ledge |

There are 26 original SVG line symbols, drawn for this tool rather than copied from
the reference charts. **Map appearance → Monochrome** removes reliance on tile colour.
Appearance, zoom and palette selection are session settings, not exported map data.
No parchment or image/PDF export is included in this version.

**Edge symbols:** choose **Wall edge** (north/east/south/west), then click the floor
cell adjoining that edge. The symbol snaps to that cell boundary, including outer
map edges. An opposite edge of the neighbouring cell represents the same boundary;
placing a second symbol there is rejected. Use the inspector's Placement selector
to move an existing edge symbol. Edge orientation is derived from its side; its
Rotation must remain 0. This layer does not cut through solid wall cells: draw the
walkable opening first. The earlier Door and Secret door cell brushes remain for
compatibility; new boundary doors use the palette.

**Room objects:** choose **Object rotation** (0/90/180/270 degrees), then click a
walkable cell. Select the object to change its name, position, rotation, notes or
properties. Symbols use one cell; multi-cell furniture is not supported yet.

**Natural features:** drag over existing floor to paint multiple cells. The ground
and area assignment remain intact. One terrain feature and one room object can
share a cell; edge symbols occupy separate boundary slots. Painting another terrain
replaces that terrain's details; repainting the same kind preserves its notes.
The whole stroke is rejected if it crosses undrawn ground or walls. Select individual
terrain cells through the map or the coordinate-labelled Map features list to edit
properties or rotate a stream/waterfall/ledge. **Clear features only** removes features
anchored at painted cells while preserving ground and design markers. Undo restores
all affected features. Deleting an individual feature also leaves its ground intact.

**Properties:** appearance and behaviour are separate. Locked and Initially concealed
are design metadata; the author view always shows concealed content. Provides cover
is a design note, not a combat rule. Blocks movement participates in the editor's
connectivity check: center features block their cell, while edge features block
crossing that boundary. Bars, windows, railings, pillars, boulders, stalagmites and
chasms default to blocking; other symbols default to non-blocking. Doors count as
potentially open even when marked locked, unless Blocks movement is explicitly set.
Water, rubble and ledges do not yet model swimming, difficult terrain or elevation.
These are editable authoring defaults, not settled game rules. A warning identifies
markers placed on movement-blocking content.

Travel symbols have destination document/location fields and support the same
read-only overland reference picker as travel markers. Local area/document renames
update feature destinations too. Every feature is retained by JSON save/load and
undo/redo; none is consumed by the Godot runtime yet.

## Markers and links

| Marker | Intended use |
| --- | --- |
| Entrance (E), Exit (X) | Entry/return points, optionally linked to an overland location |
| Stairs (S), Passage (P) | Transitions to another area or another dungeon document |
| NPC (N) | Character placement and an authored NPC reference |
| Encounter (!) | Encounter placement and an authored encounter reference |
| Secret (?) | Hidden-feature design notes |
| Conversation (C) | An Ink file/entry reference, for example `hesk.ink#introduction` |

Markers are design annotations, not implemented game objects. References are plain
text: no Ink compilation, story execution, combat generation or NPC lookup happens.
An Ink reference is a suggested authoring convention, not a tested runtime contract.

For links, set **Destination document ID** plus **Destination location / area ID**.
Both must be provided together. For an overland region, these are the region ID and
location ID, e.g. `dales_road` / `cave_approach`. For a dungeon, they are the dungeon
ID and named area ID. Local links use this dungeon's own ID. Renaming the dungeon or
an area updates local links. External documents are never modified, so inbound links
in other files need manual updating after a rename. Links are annotations and do not
create reciprocal routes automatically.

To avoid mistyped overland destinations, choose **Load region JSON**, load an export
from the overland editor, select a destination, and click **Use for selected link**.
Then apply the marker details. This read-only reference is held for the session,
is not included in the dungeon export, and does not modify the region sample or your
downloaded test file. The current loaded reference remains available across map changes.
External dungeon targets and NPC/encounter/Ink references are not verified.

## Data and validation

`dungeon.schema.json` defines the version 3 authoring format. Version 1 and 2 files
load automatically with their cells, markers, IDs and notes preserved, adding an
empty feature layer. Saves use version 3. Older editor copies cannot load version 3
exports; use this updated editor. It shares lower-case
ASCII IDs and separate descriptions/author notes with the overland format, but it is
a distinct document (`document_type: "dungeon"`) and is not a runtime adventure file.

| Record | Fields |
| --- | --- |
| Dungeon | `schema_version`, `document_type`, `id`, `name`, `author_notes`, `width`, `height`, `areas`, `cells`, `markers`, `features` |
| Area | `id`, `name`, `description`, `author_notes` |
| Cell | zero-based `x`, `y`, `tile` (`floor`, `corridor`, `door`, `secret_door`, `wall`), `area_id` (empty means unassigned) |
| Marker | `id`, `name`, `type`, `x`, `y`, `description`, `author_notes`, `reference`, `target_document`, `target_location` |

| Feature | `id`, `name`, `kind`, `x`, `y`, `edge`, `rotation`, `locked`, `concealed`, `blocks_movement`, `provides_cover`, `description`, `author_notes`, `target_document`, `target_location` |

Cells are sparse: omitted positions are undrawn and non-traversable; explicit walls
are also non-traversable. There is no metres/feet scale
or canonical world distance. All fields are required; unknown fields, unsupported
versions, duplicate IDs/cells, missing area references, out-of-bounds positions,
off-floor markers, and broken local destinations are rejected. Destination fields
are only permitted for entrance/exit/stairs/passage markers and travel symbols. Invalid imports and
invalid edits leave the current document intact. File input is limited to 5 MB.

Warnings report empty/undrawn areas, disconnected floor groups, missing entrances,
unset link/content references and unverified external destinations. They do not block
saving. Four-way flood fill considers every floor/corridor/door/secret-door cell traversable;
it excludes walls, feature cells marked `blocks_movement`, and boundaries blocked
by edge features. It ignores locks, discovery state and transition destinations. Thus intentionally disconnected
levels linked by stairs still produce a warning. Loaded overland references can
verify their location IDs; this is not a complete multi-document dependency checker.

## Lore boundaries

The practice map is explicitly a drawing exercise, not campaign canon. The goblin
starter has no geometry or placed actors. Its area notes come from
`docs/world-bible.md` v0.2: cave entrance, non-loyal patrol corridor, family area
(two loyalists plus non-combatant families), common cave, and bugbear chamber.
It is an incomplete authoring scaffold, not a recovered cave map. The old rubbish
shaft and Midden Grub placement remain unresolved. No new NPC names or fixed
connections are invented. All exports are author-only and include secrets.

## Development and tests

`model.js` owns schema, immutable edits, validation and serialization. `samples.js`
provides offline starter buttons; generated JSON is also supplied under `samples/`.
`symbols.js` contains the original linework; `app.js` implements the UI. `.gdignore` excludes this folder from Godot asset scanning.
No game scenes, rulesets, loaders or adventure runtime data are modified.

From the repository root:

```sh
node tools/dungeon-designer/generate-samples.cjs
node --test tools/dungeon-designer/tests/model.test.cjs
node --check tools/dungeon-designer/app.js
```

The optional integration test needs a separately installed Playwright and browser:
set `PLAYWRIGHT_MODULE` to the module directory if needed, and `BROWSER_CHANNEL=msedge`
to use installed Edge. Optionally set `EDITOR_SCREENSHOT` to an output image path.

```sh
node --test tools/dungeon-designer/tests/browser.test.cjs
```

The model tests cover schema/sample consistency, geometry, connectivity, reference
maintenance, deletion, malformed imports and atomic failures. The browser workflow
covers drawing, doors, markers, undo/redo, external linking, pending edit protection,
invalid imports, resizing, download/reload and both starter buttons.

Version 3 verification: 21 dungeon model tests and three desktop Edge browser workflows
passed, including symbol placement, rotation, properties, terrain layering and legacy
imports. Nine existing overland model tests also passed in the initial release. Godot is unavailable in the coding
environment; its runtime smoke test was not run. The changed paths are tools and
documentation only, and the existing overland sample is unchanged.

## Limits

- One grid per document; other floors are separate documents linked by markers.
- No background-image tracing, arbitrary wall edges, elevation, lighting or 3D view.
- No player-safe export, fog of war, tactical simulation, Godot importer or Ink runtime.
- No persistent autosave, collaboration or merging; undo history is session-only.
- Marker and area content are design notes, not complete NPC/encounter definitions.
- Desktop Edge is the tested browser; other browsers and touch input are unverified.
