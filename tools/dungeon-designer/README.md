# Dungeon Designer v1

An offline, author-only layout editor. Open `index.html` in desktop Edge or Chrome.
No installation or server is needed. Keep this folder beside `adventure-designer`:
the optional overland-reference importer uses that tool's existing validator.

## Start drawing

1. Click **Practice map** for a small, non-canonical example, or **Goblin starter**
   for established area names and author notes on a blank grid. No file picker is needed.
2. Use **+ Add** under Named areas. Enter an ID, name, description and author notes,
   then **Apply details**. A new area is automatically selected as the paint area.
3. Choose **Room rectangle** and drag between opposite corners. Use **Floor brush**
   for irregular caves. Empty cells represent solid or undrawn space; walls are the
   boundaries between floor and empty space, not separate wall objects.
4. Choose **Corridor brush** and paint passages between rooms. Pointer samples are
   joined with four-way steps so even fast diagonal strokes remain connected.
   Set **Paint area** to Unassigned for corridors that do not belong to a room.
5. Choose **Door** to place a door cell. A door is walkable for validation; locks,
   secret doors and opening conditions are not simulated.
6. **Assign area** changes ownership of existing cells without changing their tile
   type. **Erase** removes cells and any markers on them. Undo restores the entire stroke.
7. Choose **Place marker**, select its type, then click a floor cell. Edit its name,
   notes, content reference or destination in the inspector. Select markers from the
   left list when several share a cell; their grid badge shows the count.
8. Click **Save JSON** and check your downloads folder. Load that file next session.
   This downloads a new file; it does not overwrite files or commit to GitHub.

Click **Select** to inspect an area or marker through the grid. Named areas can cover
multiple rooms; each cell belongs to at most one area. Painting replaces a cell's
tile and area assignment. Existing markers remain unless the cell is erased.
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
External dungeon targets and NPC/encounter/Ink references are not verified in v1.

## Data and validation

`dungeon.schema.json` defines the version 1 authoring format. It shares lower-case
ASCII IDs and separate descriptions/author notes with the overland format, but it is
a distinct document (`document_type: "dungeon"`) and is not a runtime adventure file.

| Record | Fields |
| --- | --- |
| Dungeon | `schema_version`, `document_type`, `id`, `name`, `author_notes`, `width`, `height`, `areas`, `cells`, `markers` |
| Area | `id`, `name`, `description`, `author_notes` |
| Cell | zero-based `x`, `y`, `tile` (`floor`, `corridor`, `door`), `area_id` (empty means unassigned) |
| Marker | `id`, `name`, `type`, `x`, `y`, `description`, `author_notes`, `reference`, `target_document`, `target_location` |

Cells are sparse: omitted positions are solid/undrawn. There is no metres/feet scale
or canonical world distance. All fields are required; unknown fields, unsupported
versions, duplicate IDs/cells, missing area references, out-of-bounds positions,
off-floor markers, and broken local destinations are rejected. Destination fields
are only permitted for entrance/exit/stairs/passage markers. Invalid imports and
invalid edits leave the current document intact. File input is limited to 5 MB.

Warnings report empty/undrawn areas, disconnected floor groups, missing entrances,
unset link/content references and unverified external destinations. They do not block
saving. Four-way flood fill considers every floor/corridor/door cell traversable;
it ignores locks, secrets and transition markers. Thus intentionally disconnected
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
`app.js` implements the UI. `.gdignore` excludes this folder from Godot asset scanning.
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

Initial verification: 13 dungeon model tests, two desktop Edge browser workflows,
and nine existing overland model tests passed. Godot is unavailable in the coding
environment; its runtime smoke test was not run. The changed paths are tools and
documentation only, and the existing overland sample is unchanged.

## Limits

- One grid per document; other floors are separate documents linked by markers.
- No background-image tracing, arbitrary wall edges, elevation, lighting or 3D view.
- No player-safe export, fog of war, tactical simulation, Godot importer or Ink runtime.
- No persistent autosave, collaboration or merging; undo history is session-only.
- Marker and area content are design notes, not complete NPC/encounter definitions.
- Desktop Edge is the tested browser; other browsers and touch input are unverified.
