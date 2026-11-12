#!/usr/bin/env python3
"""Package/verify a pinned PR 15 preview without replacing stable game files."""
import hashlib
import json
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

BASE = "https://jonty303.github.io/Project-AzureMines/"
HEAD = "f41eba85eaabf9c81dbf38899c8b41b690b13c07"
STABLE = "950b41ee1203f7dcb607c38eb1ae0c70a57a7b9b"
PREFIX = "previews/pr-15/"


def hashes(root: Path) -> dict[str, str]:
    result = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"Symlinks are not allowed: {path}")
        if path.is_file():
            result[path.relative_to(root).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def fetch(relative: str) -> bytes:
    if relative.startswith("/") or ".." in Path(relative).parts:
        raise ValueError(f"Unsafe site path: {relative}")
    url = BASE + urllib.parse.quote(relative, safe="/") + "?verify=" + str(time.time_ns())
    request = urllib.request.Request(url, headers={"User-Agent": "AzureMines-Preview-Verification", "Cache-Control": "no-cache"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def verify_files(expected: dict[str, str]) -> None:
    for relative, digest in expected.items():
        last_error = None
        for attempt in range(6):
            try:
                actual = hashlib.sha256(fetch(relative)).hexdigest()
                if actual != digest:
                    raise ValueError(f"Content mismatch: {relative}")
                print(f"PASS remote SHA-256: {relative}", flush=True)
                break
            except (urllib.error.URLError, TimeoutError, ValueError) as error:
                last_error = error
                if attempt == 5:
                    raise RuntimeError(f"Cannot verify {relative}: {last_error}") from error
                time.sleep(3)


def stage(stable: Path, preview: Path, site: Path) -> None:
    if site.exists():
        raise ValueError("Output site already exists; refusing to overwrite it")
    original = hashes(stable)
    if not original.get("index.html") or not any(p.endswith(".wasm") for p in original):
        raise ValueError("Stable artifact is not a complete web export")
    if any(p.startswith("previews/") for p in original):
        raise ValueError("Expected original stable artifact without previews")
    verify_files(original)
    shutil.copytree(stable, site)
    (site / ".nojekyll").touch(exist_ok=True)
    target = site / PREFIX
    target.mkdir(parents=True, exist_ok=False)
    shutil.copytree(preview, target / "game")
    for extension in (".html", ".js", ".wasm", ".pck"):
        if not any(p.suffix == extension and p.stat().st_size for p in (target / "game").iterdir()):
            raise ValueError(f"Preview export missing {extension}")
    (target / "index.html").write_text('''<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="robots" content="noindex,nofollow">
<title>Azure Mines — PR 15 iPad Preview — f41eba85eaab</title>
<style>
*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#0e141b;color:#f0e7d7;font-family:system-ui,sans-serif}
body{display:flex;flex-direction:column;height:100dvh}header{flex:0 0 auto;display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap;padding:7px 12px;padding-left:max(12px,env(safe-area-inset-left));padding-right:max(12px,env(safe-area-inset-right));font-size:13px;border-bottom:1px solid #635137}
strong{color:#e4bd76}a{color:#dce9ff;text-decoration:underline}nav{display:flex;gap:16px}iframe{flex:1 1 auto;min-height:0;width:100%;border:0;display:block}
</style></head><body>
<header><span><strong>PR #15 · v0.4.3 TEST PREVIEW</strong> · f41eba85eaab · iPad acceptance pending</span><nav><a href="../../">Existing build</a><a href="build.json" target="_blank" rel="noopener">Build details</a></nav></header>
<iframe src="game/index.html" title="Azure Mines Combat Lab PR 15" allow="autoplay; fullscreen" allowfullscreen></iframe>
</body></html>''', encoding="utf-8")
    current = hashes(site)
    for name, digest in original.items():
        if current[name] != digest:
            raise ValueError(f"Stable file was changed: {name}")
    metadata = {
        "schema_version": 1, "pull_request": 15, "label": "v0.4.3 playtest candidate",
        "source_commit": HEAD, "stable_commit": STABLE, "stable_artifact_run": 43255328775,
        "preview_url": BASE + PREFIX,
        "packaging_changes": ["HTML preview header and iframe", "LAST_REPORT_PATH isolated to user://combat_lab_pr15_last_battle.json"],
        "physical_ipad_acceptance": "NOT RUN",
        "stable_file_sha256": original,
        "preview_file_sha256": {PREFIX + name: digest for name, digest in hashes(target).items()},
    }
    (target / "build.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: preserved {len(original)} original files; staged {BASE + PREFIX}")


def verify(manifest: Path) -> None:
    expected = json.loads(manifest.read_text(encoding="utf-8"))
    published = None
    for attempt in range(12):
        try:
            published = json.loads(fetch(PREFIX + "build.json"))
            if published != expected:
                raise ValueError("Published preview metadata does not match this build")
            break
        except (urllib.error.URLError, TimeoutError, ValueError):
            if attempt == 11:
                raise
            time.sleep(5)
    if published["source_commit"] != HEAD:
        raise ValueError("Unexpected preview commit")
    verify_files(published["stable_file_sha256"])
    verify_files(published["preview_file_sha256"])
    print("PASS: preview is served at the expected URL and every stable file is unchanged")


if __name__ == "__main__":
    if len(sys.argv) == 5 and sys.argv[1] == "stage":
        stage(*(Path(arg) for arg in sys.argv[2:]))
    elif len(sys.argv) == 3 and sys.argv[1] == "verify":
        verify(Path(sys.argv[2]))
    else:
        sys.exit("Usage: preview_site.py stage STABLE PREVIEW SITE | verify BUILD_JSON")
