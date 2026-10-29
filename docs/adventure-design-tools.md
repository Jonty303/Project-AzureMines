# Adventure authoring tools

The first overland authoring tool is in [`tools/adventure-designer`](../tools/adventure-designer/README.md).
Open its `index.html` locally, then load `samples/dales_road.json` to begin.

It supports location/route editing, a draggable graph, JSON save/load and lightweight
validation. See the tool README for the versioned authoring contract, sample provenance,
tests and limitations. Exports contain author-only material and are not runtime-ready.

The [Dungeon Designer](../tools/dungeon-designer/README.md) adds a separate grid-based
layout editor. Open `tools/dungeon-designer/index.html`, then choose **Practice map**
or **Goblin starter**. It supports rooms, corridors, doors, named areas, design markers,
destination links, undo/redo, JSON save/load and layout validation. The goblin starter
supplies area notes on a blank grid; it does not invent the unresolved cave geometry.

Both tools are isolated from the Godot game. No existing runtime scene, loader,
adventure, ruleset or project setting is changed. Narrative authoring/Ink integration
and a reviewed authoring-to-runtime importer remain future work.
