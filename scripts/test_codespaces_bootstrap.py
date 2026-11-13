#!/usr/bin/env python3
"""Offline bootstrap regression checks: no implicit engine, verified install, preview guard."""
from __future__ import annotations

import hashlib
from io import BytesIO
import json
from pathlib import Path
import sys
import tempfile
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bootstrap_codespaces as boot
import preview_godot_web as preview


def zip_bytes(entries: dict[str, bytes]) -> bytes:
    data = BytesIO()
    with zipfile.ZipFile(data, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, content in entries.items():
            archive.writestr(name, content)
    return data.getvalue()


def main() -> int:
    with tempfile.TemporaryDirectory() as dirname:
        root = Path(dirname) / "repo"
        home = Path(dirname) / "home"
        (root / "development").mkdir(parents=True)
        (root / "game").mkdir()
        home.mkdir()
        manifest = root / "development/toolchain.json"
        manifest.write_text(json.dumps({"engine": "none"}))
        with patch.object(boot, "MANIFEST", manifest):
            assert boot.main() == 0
        assert not (home / ".local/bin/godot").exists()

        (root / "game/project.godot").write_text("config_version=5\n")
        executable = b"#!/bin/sh\necho 4.5.2.stable.official.test\n"
        editor = zip_bytes({"Godot_v4.5.2-stable_linux.x86_64": executable})
        templates = zip_bytes({
            "templates/web_nothreads_release.zip": b"x" * 100_001,
            "templates/web_nothreads_debug.zip": b"y" * 100_001,
        })
        urls = {"https://example.com/editor.zip": editor, "https://example.com/templates.tpz": templates}
        settings = {
            "engine": "godot4", "project_path": "game",
            "godot": {
                "version": "4.5.2",
                "linux_download_url": "https://example.com/editor.zip",
                "linux_sha256": hashlib.sha256(editor).hexdigest(),
                "web_export_templates_url": "https://example.com/templates.tpz",
                "web_export_templates_sha256": hashlib.sha256(templates).hexdigest(),
            },
        }
        manifest.write_text(json.dumps(settings))
        def urlopen(url: str, timeout: int = 0):
            return BytesIO(urls[url])
        with patch.object(boot, "ROOT", root), patch.object(boot, "MANIFEST", manifest), \
             patch.object(boot.Path, "home", return_value=home), patch.object(boot, "urlopen", urlopen):
            assert boot.main() == 0
            assert boot.main() == 0
        assert (home / ".local/bin/godot").is_file()
        assert (home / ".local/share/godot/export_templates/4.5.2.stable/web_nothreads_release.zip").is_file()
        # A different executable reporting the same version must not bypass SHA checks.
        binary = home / ".local/bin/godot"
        binary.write_bytes(b"#!/bin/sh\\necho 4.5.2.stable.official.impostor\\n".replace(b"\\n", b"\n"))
        binary.chmod(0o755)
        with patch.object(boot, "ROOT", root), patch.object(boot, "MANIFEST", manifest), \
             patch.object(boot.Path, "home", return_value=home), patch.object(boot, "urlopen", urlopen):
            assert boot.main() == 0
        assert binary.read_bytes() == executable
        with patch.object(preview, "ROOT", root), patch.object(preview.Path, "home", return_value=Path(dirname) / "missing"), \
             patch.object(sys, "argv", ["preview_godot_web.py", "--build-only"]):
            assert preview.main() == 1
        with patch.object(boot, "urlopen", urlopen):
            try:
                boot.verified_download("https://example.com/editor.zip", "0" * 64, home / "bad.zip")
            except ValueError:
                pass
            else:
                raise AssertionError("unchecked download accepted")
    print("PASS: Codespaces bootstrap offline regression tests")
    return 0


if __name__ == "__main__":
    sys.exit(main())
