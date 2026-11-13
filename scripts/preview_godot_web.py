#!/usr/bin/env python3
"""Build and serve a real Godot Web export, refusing empty or partial builds."""
from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--build-only", action="store_true")
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    settings = json.loads((ROOT / "development/toolchain.json").read_text(encoding="utf-8"))
    if settings.get("engine") != "godot4":
        print("FAIL: Web preview requires an explicitly selected Godot 4 project", file=sys.stderr)
        return 1
    project = (ROOT / settings["project_path"]).resolve()
    if not project.is_relative_to(ROOT) or not (project / "project.godot").is_file():
        print("FAIL: project.godot not found at declared project_path", file=sys.stderr)
        return 1
    binary = Path.home() / ".local/bin/godot"
    if not binary.is_file():
        print("FAIL: Godot not installed; run python3 scripts/bootstrap_codespaces.py", file=sys.stderr)
        return 1
    folder = project / "build/web"
    folder.mkdir(parents=True, exist_ok=True)
    # Clean old output so a stale index cannot masquerade as a new successful export.
    for suffix in (".html", ".wasm", ".pck", ".js"):
        for file in folder.glob("*" + suffix):
            file.unlink()
    subprocess.run([str(binary), "--headless", "--path", str(project), "--import"], check=True)
    subprocess.run([str(binary), "--headless", "--path", str(project),
                    "--export-release", "Web", str(folder / "index.html")], check=True)
    for extension in ("html", "wasm", "pck", "js"):
        files = [f for f in folder.glob("*." + extension) if f.stat().st_size > 0]
        if not files or (extension == "html" and not (folder / "index.html").stat().st_size):
            raise ValueError(f"Web export incomplete: no nonempty {extension} artifact")
    print(f"PASS: Web export generated in {folder}", flush=True)
    if args.build_only:
        return 0
    print(f"Open Codespaces Ports -> {args.port} -> Open in Browser (keep port private)", flush=True)
    handler = partial(SimpleHTTPRequestHandler, directory=str(folder))
    with ThreadingHTTPServer(("0.0.0.0", args.port), handler) as server:
        server.serve_forever()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print(f"FAIL: Web preview: {exc}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nPreview stopped")
        sys.exit(0)
