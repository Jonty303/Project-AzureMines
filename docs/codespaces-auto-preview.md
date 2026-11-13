# Codespaces: persistent iPad web preview

The project opts into the reusable preview service in `development/codespaces_web_preview.json`.
The devcontainer `postStartCommand` launches it automatically after a Codespace resumes.
A detached process binds port **8765** immediately, reports build status at
`/__preview/status`, and serves the latest successful Godot export. It checks
the active Git branch/commit every 15 seconds, staging a complete new export
before replacing the last successful one. Build failures keep the previous
working export available and are recorded in the service log.

On an **existing Codespace** after pulling this change, start it immediately
without keyboard shortcuts:

```bash
python3 scripts/codespaces_web_preview.py start
python3 scripts/codespaces_web_preview.py status
```

Open **Ports → 8765 → Open in Browser**, keeping its visibility **Private**.
To make the new `postStartCommand` active for **future Codespace starts**,
perform a one-time **Dev Containers: Rebuild Container** after saving any
uncommitted work. A terminal need not remain open.

Logs: `~/.cache/codespaces-web-preview/Project-AzureMines/service.log`.
The status endpoint tells whether the preview is building, ready, or in error.
A Codespace in the **Stopped** state does not host a live preview; resuming it
restarts the service. A running Codespace keeps serving when the iPad disconnects.
The preview rebuilds on committed branch/head changes; uncommitted changes may
require a new commit or a service restart. Godot editor/LSP port 6008 is separate
from the HTTP preview on 8765.

This preview does **not** publish GitHub Pages, change the feature branch,
or substitute for physical iPad Safari acceptance.
