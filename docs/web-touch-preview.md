# Combat Lab — web preview and tablet verification

**Branch:** `feature/combat-lab-web-touch` · **Status:** Automated build and deployment configured. Physical-device sign-off remains pending.

## Build and publication
The `.github/workflows/combat-lab-web.yml` workflow builds the isolated lab using exactly Godot 4.5.2 standard and official release templates, with reviewed SHA256 checks. A single-threaded HTML5 export is used for iPad Safari/GitHub Pages compatibility. Build outputs appear in Actions as `combat-lab-web-build`, even if Pages deployment has not yet been enabled.

To permit public preview: GitHub repository **Settings → Pages → Build and deployment → Source: GitHub Actions**. GitHub Pages deployment may require the `github-pages` environment to allow deployments from this **feature branch**. If the deploy job fails due to branch protection, adjust environment allowed branches or promote the workflow to an approved Pages publishing branch; do not silently merge the gameplay branch into `main`.

Once GitHub Pages deploys successfully the normal project URL format is `https://jonty303.github.io/Project-AzureMines/`, but do **not** share it as live until deployment is confirmed.

## Local preview
In a Codespace with Godot 4.5.2 and the official templates installed:
```sh
mkdir -p build/web
godot --headless --path . --import
godot --headless --path . --export-release "Web" build/web/index.html
cd build/web
python3 -m http.server 8765
```
Use the Codespaces **Ports** tab to open port **8765**. Never open the generated `index.html` directly as a local file; Godot web export needs an HTTP server.

## Input support
- **Mouse:** existing board clicks retained.
- **Touch:** native `InputEventScreenTouch` with synthetic-mouse duplicate suppression. Existing Godot Buttons use their normal pointer/touch input behavior.
- **Keyboard:** focus board with Tab, arrow keys to choose a tile, Enter/Space to confirm. Other buttons retain normal GUI focus navigation.
- **Layout:** board scales within tablet viewport, menus wrap, current log opens as a separate dialogue when the sidebar is hidden.
- **Gamepad:** not yet an approved/verified profile.
- **Physical iPad touch:** NOT RUN. Input injection in CI is not proof of real touchscreen operation.

## Real-device test
1. Open deployed site in iPad Safari in landscape.
2. Confirm title, level selector and encounter dialogue are fully visible and scroll if necessary.
3. Configure a small wolf encounter in the stone chamber; start deployment.
4. Tap a hero, tap a legal deployment tile; press Begin Battle.
5. Tap Move and a reachable tile; then Attack and a valid enemy; repeat with an implemented spell.
6. Trigger and resolve a reaction, review HP and battle log, finish/retry the encounter and open Last Battle Log from the title.
7. Rotate to portrait and back; confirm controls remain usable, that tapping does not activate twice and that scrolling doesn't cause an accidental combat action.
8. Reload the site, verify last-battle storage persistence and confirm no crash or graphics corruption.
9. Record device/iPadOS/Safari versions and the exact deployed commit, with screenshots if something fails.

Known web risks: WebGL 2 support in Safari, reduced WebAssembly performance, browser audio restrictions, and browser-local storage longevity. The lab remains a **test application**, not a publicly released game.

## Verified workflow results (12 November 2026)

- Godot 4.5.2 native-touch/keyboard and existing combat tests: **PASS** — https://github.com/Jonty303/Project-AzureMines/actions/runs/43226257801
- HTML5 export, pinned official editor/templates, downloadable Web artifact: **PASS** — https://github.com/Jonty303/Project-AzureMines/actions/runs/43226257758
- Pages publish: **BLOCKED** with GitHub 404 until the owner enables Pages at https://github.com/Jonty303/Project-AzureMines/settings/pages and permits the feature branch if an environment rule blocks it.
- Physical iPad Safari testing: **NOT RUN**.

## Test immediately through Codespaces (without GitHub Pages)

From an authenticated Codespaces terminal with GitHub CLI available, even if its checked-out branch is still `feature/standalone-combat-lab`:

```bash
mkdir -p /tmp/azure-mines-combat-web
gh run download 43226257758 --repo Jonty303/Project-AzureMines \
  --name combat-lab-web-build --dir /tmp/azure-mines-combat-web
python3 -m http.server 8765 --bind 0.0.0.0 --directory /tmp/azure-mines-combat-web
```

Open Codespaces **Ports → 8765 → Open in Browser** on your iPad; keep the port private. Close with Ctrl+C in the terminal. The optional reusable script `scripts/serve_codespaces_web_preview.sh` on the web-touch branch does this with a selected Actions run ID.

The build artifact is not a public Pages website. The forwarded port URL is tied to your Codespace session and authorization.

## iPad-first battle layout

Following the first Safari landscape playtest, the combat interface was revised to keep a **persistent right-hand battle console** in landscape. The battle console has four tabs:

- **Actions** — deployment, formations, combat commands, spell/weapon selection and reactions;
- **Party** — current party HP and combat states;
- **Details** — a selected creature's HP, AC, attacks and status, or the selected tile's hazards/cover;
- **Log** — the combat event record and full log dialogue.

When no action mode is selected, tapping a creature/tile opens Details. During a selected action, tapping still submits the action normally and quietly updates Details; it does not steal focus from combat controls. Reactions return focus to Actions.

**Portrait fallback:** The battle console becomes the second row beneath the grid, rather than being hidden. Menu and control layouts wrap and remain scrollable. The browser title/menu and testing functions remain available on smaller viewports.

The forest edge is now rendered as reduced-opacity decor with visible cell boundaries; it is not a wall and must not conceal target selection. Future biome art should distinguish the playable tile layer from decor outside the arena.

The associated headless layout test checks a 1024×768 landscape, 768×1024 portrait, 1550×1000 desktop layout, default Actions tab and updated selection details. This is a *structural* test, **not** a visual or physical touch pass. The next iPad acceptance run should record actual accessibility of all four tabs, comfortable button sizes, map legibility and orientation behaviour.


## Combat Lab v0.3 review

The iPad battle-console arrangement remains permanent in landscape (Actions / Party / Details / Log). The battle header now has status, Retry and Return to Title only. A developer Debug Input/Output control lives within Actions, while the full battle log remains in Log. Tooling should not duplicate these controls.

Before v0.3 acceptance on iPad, inspect a melee hit, ranged miss, spell damage and healing effect; verify target overlays and resource status; test that tapping the board never accidentally fires the same action twice. Initial non-blocking VFX use procedurally drawn overlays, not sprite animation. Test against a real browser and record device and Safari version.
