# Adventure Designer v1

An offline, author-only overland location graph editor for Project Azure Mines.
Open **index.html** directly in a modern desktop browser (Edge or Chrome recommended).
No server, installation, network connection or Godot project changes are needed.
Keep index.html, style.css, model.js and app.js together.

## First session

1. Choose **Load JSON** and select `samples/dales_road.json` from this directory.
2. Select a location in the left list or click its node. Edit its name, ID, location type,
   description, discovery state or author notes in the inspector; choose **Apply item**.
3. Drag nodes to arrange the graph. X/Y fields provide a keyboard alternative.
4. Choose **+ Add** to create a location. Select a source location, then **+ Connect**
   to add a route to the first unused destination. Change From/To in the inspector
   and apply. A checked **Travel both ways** means bidirectional; otherwise From → To.
5. Edit region details and starting location with **Apply region**.
6. Choose **Save JSON**. The browser downloads the complete region. Check that the
   download completed, and move the file into your working content folder as needed.
   Save does not overwrite the original file or commit to GitHub.
7. Reopen with **Load JSON** in a future session. There is no autosave or local-storage backup.

Changes in either form must be applied before saving. Selection changes and replacement
of the document ask before discarding edits. Most browsers also warn before leaving an
unsaved document; a browser crash or blocked/cancelled download is not recoverable here.
Invalid loads preserve the current document. Imports larger than 5 MB are rejected.
Deletion asks for confirmation: deleting a location also deletes incident routes and
clears the starting location if necessary. There is no undo yet.

## Data contract

`region.schema.json` is the common **authoring** location/route contract, JSON Schema
2020-12. It is intentionally separate from the bootstrap runtime location format in
`adventures/test_adventure/locations/`. Do not drop these exports into that directory
or claim they are playable adventures. A future reviewed importer must map authored
definitions into runtime data, apply disclosure rules, and validate runtime references.

All fields are required; unknown fields and unsupported versions are rejected rather
than silently discarded. IDs use lower-case ASCII letters, digits and underscores,
matching the repository convention. IDs are unique within each collection. Renaming
a location updates its route endpoints and starting-location reference atomically.

| Record | Fields and meaning |
| --- | --- |
| Region | `schema_version: 1`, `id`, `name`, `author_notes`, `starting_location` (location ID or null), `locations`, `routes` |
| Location | `id`, `name`, `kind` (`settlement`, `wilderness`, `dungeon`, `interior`), `description`, `author_notes`, `discovery` (`known` or `hidden`), `position` (`x`, `y`) |
| Route | `id`, `name`, `from`, `to` (location IDs), `bidirectional` (boolean), `description`, `author_notes`, `discovery` |

Positions are editor layout coordinates in a 1200 × 800 view, with X 80–1120 and
Y 50–750 to keep node cards inside the view. They are **not world coordinates,
distances or travel time**. Location types allow reuse for interior graphs later;
there is no dungeon tile/grid schema in v1. Descriptions are separate from author
notes, but exports include **all** fields and secrets. Discovery is design metadata,
not implemented game logic, and the editor deliberately shows every location.

**Location type** is stored as `kind` in JSON for compatibility with existing files.
Its values are descriptive categories only: `settlement` for towns and inhabited
places, `wilderness` for outdoor areas, `dungeon` for adventure sites such as caves
or ruins, and `interior` for rooms or indoor areas. These are authoring conventions,
not enforced gameplay meanings. The editor validates and saves the chosen value;
it does not change travel, encounters, rendering or game behaviour based on it.
New locations default to `wilderness`.

Structural errors, duplicate IDs, dangling references, self routes and duplicate
directed connections block import/apply/save. Bidirectional routes occupy both
directions. Two opposite one-way routes are legal (their lines overlap in this first
renderer; select each through the route list). Empty regions, missing start,
unreachable locations and known routes touching hidden locations generate warnings.
Reachability respects route direction but ignores discovery. Warnings do not block save.
This is lightweight validation, not a narrative, lore or game-balance checker.

## Sample provenance

`samples/dales_road.json` has five locations and four routes: Seabrook → wagon clearing
→ Harrowford, with the discoverable ravine → wooded cave approach branch. All four
routes allow return travel. Based on `docs/world-bible.md` v0.2, sections 1, 2 and 6.
The sample retains Seabrook west of the Dales and Harrowford at the northern edge,
without fixing exact bearings or distances. Route segmentation and positions are
schematic. Hesk, Mara Venn and tracking are recorded only as alternate discovery
design notes. No new NPC names, secret-society identity, mine threat, tower evidence,
or unresolved cave geometry is invented. This is an author reference, not player content.

## Implementation and checks

This standalone HTML/CSS/JavaScript utility is a deliberate exception to the game's
Godot-native UI preference: it makes authoring immediately accessible without adding
runtime scenes, addons or dependencies. `.gdignore` excludes the entire tool subtree
from Godot's asset scan. No existing game files are modified. No scripts in input JSON
are executed; authored strings are rendered as text.

`model.js` holds schema definitions, immutable edit operations, validation and JSON
serialization, shared by the browser and Node tests. `app.js` owns the UI. The schema
artifact is generated from `model.js`; its consistency is tested. After schema edits:

```sh
node -e "require('fs').writeFileSync('tools/adventure-designer/region.schema.json', JSON.stringify(require('./tools/adventure-designer/model.js').schema,null,2)+'\n')"
node --test tools/adventure-designer/tests/model.test.cjs
node --check tools/adventure-designer/app.js
```

The optional browser test uses Playwright installed separately, with a supported browser.
Set `PLAYWRIGHT_MODULE` to its module directory if it is not on Node's resolution path;
set `BROWSER_CHANNEL=msedge` to use installed Edge, or omit for Playwright Chromium.
Set `EDITOR_SCREENSHOT` to an output path for a screenshot after the workflow.

```sh
node --test tools/adventure-designer/tests/browser.test.cjs
```

Tests cover schema consistency, malformed data, atomic edits, reference updates,
directional connectivity, disclosure warnings, deletion and lossless round trips.
The browser test exercises file import, forms, connect, dragging, save download,
reload, invalid import preservation and safe rendering of markup-like text.

## Current limits / next steps

- No Godot/runtime importer, game save integration, or changes to the gameplay branch.
- No narrative decision-tree/check editor, executable conditions, encounters or quests.
- Dungeon layouts are authored in the separate [Dungeon Designer](../dungeon-designer/README.md).
  This overland tool has no background map image, pan/zoom, undo/redo or collaboration.
- Fixed-size schematic canvas; suitable for small regions, not thousands of locations.
- No player-safe export or discovery simulation. Author files must remain author-only.
- No automatic migration from other versions or feature-branch exploration formats.
- Tested in desktop Edge. Other browsers and touch devices have not been verified.

First implementation verified with nine Node model tests and one Edge workflow test.
Godot was unavailable in the coding environment; the game's loader smoke test was not
run. Runtime isolation was checked by comparing changed paths against the base commit.
