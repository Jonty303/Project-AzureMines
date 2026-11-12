#!/usr/bin/env python3
"""Extract only verified Godot web templates from the full official .tpz archive.

The caller must verify the archive SHA256 before running this script.
Do not claim the .tpz was verified merely because it could be opened.
"""
import pathlib
import sys
import zipfile


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: install_web_templates.py <verified-export_templates.tpz>", file=sys.stderr)
        return 2
    archive = pathlib.Path(sys.argv[1])
    destination = pathlib.Path.home() / ".local/share/godot/export_templates/4.5.2.stable"
    expected = {"web_nothreads_release.zip", "web_nothreads_debug.zip"}
    with zipfile.ZipFile(archive) as zipped:
        selected = {}
        for info in zipped.infolist():
            name = pathlib.PurePosixPath(info.filename).name
            if name in expected and info.file_size > 100_000:
                selected[name] = info
        if set(selected) != expected:
            print(f"FAIL: missing web templates (found {sorted(selected)})", file=sys.stderr)
            return 1
        destination.mkdir(parents=True, exist_ok=True)
        for name, member in selected.items():
            with zipped.open(member) as src, (destination / name).open("wb") as out:
                while chunk := src.read(1024 * 1024):
                    out.write(chunk)
            print(f"Installed {name}: {destination / name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
