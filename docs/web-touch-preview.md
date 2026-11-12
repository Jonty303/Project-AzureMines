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
