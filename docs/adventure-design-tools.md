# Adventure authoring tools

The first overland authoring tool is in [`tools/adventure-designer`](../tools/adventure-designer/README.md).
Open its `index.html` locally, then load `samples/dales_road.json` to begin.

It supports location/route editing, a draggable graph, JSON save/load and lightweight
validation. See the tool README for the versioned authoring contract, sample provenance,
tests and limitations. Exports contain author-only material and are not runtime-ready.

This tool is isolated from the Godot game. No existing runtime scene, loader, adventure,
ruleset or project setting is changed. Dungeon-grid and narrative-tree editors, and a
reviewed authoring-to-runtime importer, remain future work.
