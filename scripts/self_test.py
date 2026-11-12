#!/usr/bin/env python3
"""Verify the engine-neutral template and test failure paths."""
import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from validate_toolchain import validate

def main():
    for script in ("validate_template.py", "validate_toolchain.py"):
        process = subprocess.run([sys.executable, str(ROOT / "scripts" / script)], cwd=ROOT, check=False)
        if process.returncode:
            return process.returncode
    with TemporaryDirectory() as dirname:
        root = Path(dirname)
        (root / "development").mkdir()
        settings = root / "development/toolchain.json"
        manifest = {"schema_version": 1, "engine": "none", "project_path": "game"}
        settings.write_text(json.dumps(manifest), encoding="utf-8")
        if validate(root):
            print("FAIL: valid template manifest rejected")
            return 1
        (root / "game").mkdir()
        (root / "game/project.godot").write_text("", encoding="utf-8")
        if not validate(root):
            print("FAIL: undeclared Godot project accepted")
            return 1
        manifest["engine"] = "godot4"
        manifest["godot"] = {"version": "4.5.2", "linux_download_url": "", "linux_sha256": ""}
        settings.write_text(json.dumps(manifest), encoding="utf-8")
        if not validate(root):
            print("FAIL: incomplete pinned engine accepted")
            return 1
    print("PASS: positive and negative toolchain tests")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
