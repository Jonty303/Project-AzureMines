#!/usr/bin/env python3
"""Verify pinned Linux Godot release and perform a headless import.
Only runs when engine=godot4. No game code or graphics are generated.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.request import urlopen
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    cfg = json.loads((ROOT / "development/toolchain.json").read_text(encoding="utf-8"))
    engine = cfg.get("engine")
    if engine == "none":
        print("NOT RUN: no game engine selected")
        return 0
    if engine != "godot4":
        print("FAIL: selected engine needs a project-specific verifier")
        return 1
    project = (ROOT / cfg["project_path"]).resolve()
    if not project.is_relative_to(ROOT) or not (project / "project.godot").is_file():
        print("FAIL: invalid or missing project.godot")
        return 1
    options = cfg["godot"]
    checksum = options["linux_sha256"].lower()
    if len(checksum) != 64 or not options["linux_download_url"].startswith("https://"):
        print("FAIL: pin an official HTTPS release and verified SHA256")
        return 1
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp) / "editor.zip"
        h = hashlib.sha256()
        with urlopen(options["linux_download_url"], timeout=60) as source, archive.open("wb") as target:
            while (chunk := source.read(1024 * 1024)):
                h.update(chunk)
                target.write(chunk)
        if h.hexdigest() != checksum:
            print("FAIL: SHA256 mismatch")
            return 1
        with zipfile.ZipFile(archive) as zipped:
            members = [m for m in zipped.infolist() if not m.is_dir()]
            if len(members) != 1 or "/" in members[0].filename or "\\" in members[0].filename or members[0].file_size > 500_000_000:
                print("FAIL: unexpected Godot ZIP structure")
                return 1
            binary = Path(tmp) / "godot"
            with zipped.open(members[0]) as src, binary.open("wb") as dst:
                shutil.copyfileobj(src, dst)
            binary.chmod(0o755)
        version = subprocess.check_output([str(binary), "--version"], text=True, timeout=30).strip()
        expected = options["version"]
        print("Godot:", version)
        if version != expected and not version.startswith(expected + "."):
            print("FAIL: version does not match", expected)
            return 1
        subprocess.run([str(binary), "--headless", "--path", str(project), "--import"], check=True, timeout=180)
        print("PASS: verified Godot import")
        print("NOT RUN: visual, audio, controller, gameplay or export tests")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, subprocess.SubprocessError) as exc:
        print("FAIL:", exc)
        sys.exit(1)
