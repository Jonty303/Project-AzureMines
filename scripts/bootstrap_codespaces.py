#!/usr/bin/env python3
"""Provision an explicitly selected, checksum-pinned Godot 4 toolchain.

Run from the repository's devcontainer postCreateCommand or manually. No engine
is installed when development/toolchain.json selects 'none' or 'other'.
Installed files live in the user's home, never in the Git working tree.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import tempfile
from urllib.request import urlopen
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "development/toolchain.json"


def verified_download(url: str, digest: str, target: Path) -> None:
    if not isinstance(url, str) or not url.startswith("https://"):
        raise ValueError("toolchain archive must have an HTTPS URL")
    if not isinstance(digest, str) or len(digest) != 64 or any(c not in "0123456789abcdefABCDEF" for c in digest):
        raise ValueError("toolchain archive requires a 64-character SHA-256")
    target.parent.mkdir(parents=True, exist_ok=True)
    def matches(path: Path) -> bool:
        if not path.is_file():
            return False
        sha = hashlib.sha256()
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                sha.update(chunk)
        return sha.hexdigest() == digest.lower()
    if matches(target):
        print(f"Verified cached download: {target}")
        return
    with tempfile.NamedTemporaryFile(dir=target.parent, prefix=".download-", delete=False) as tmp:
        temp = Path(tmp.name)
        try:
            with urlopen(url, timeout=120) as source:
                shutil.copyfileobj(source, tmp, length=1024 * 1024)
            tmp.flush()
            if not matches(temp):
                raise ValueError(f"SHA-256 mismatch for {url}")
            temp.replace(target)
        finally:
            temp.unlink(missing_ok=True)
    print(f"Verified download: {target}")


def version_ok(binary: Path, expected: str) -> bool:
    if not binary.is_file() or not os.access(binary, os.X_OK):
        return False
    try:
        actual = subprocess.check_output([str(binary), "--version"], text=True, timeout=30).strip()
    except (OSError, subprocess.SubprocessError):
        return False
    return actual == expected or actual.startswith(expected + ".")


def install_editor(cfg: dict, cache: Path, home: Path) -> Path:
    version = cfg["version"]
    if not isinstance(version, str) or not version.startswith("4."):
        raise ValueError("Godot 4 requires a pinned version")
    binary = home / ".local/bin/godot"
    archive = cache / "editor.zip"
    verified_download(cfg["linux_download_url"], cfg["linux_sha256"], archive)
    with zipfile.ZipFile(archive) as zipped:
        entries = [item for item in zipped.infolist() if not item.is_dir()]
        if len(entries) != 1 or PurePosixPath(entries[0].filename).name != entries[0].filename or entries[0].file_size > 500_000_000:
            raise ValueError("unexpected Godot editor ZIP structure")
        if version_ok(binary, version):
            sha_archive = hashlib.sha256()
            sha_installed = hashlib.sha256()
            with zipped.open(entries[0]) as source, binary.open("rb") as installed:
                for chunk in iter(lambda: source.read(1024 * 1024), b""):
                    sha_archive.update(chunk)
                for chunk in iter(lambda: installed.read(1024 * 1024), b""):
                    sha_installed.update(chunk)
            if sha_archive.digest() == sha_installed.digest():
                print(f"Existing checksum-verified editor: {binary}")
                return binary
        binary.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=binary.parent, prefix=".godot-", delete=False) as tmp:
            temp = Path(tmp.name)
            with zipped.open(entries[0]) as src:
                shutil.copyfileobj(src, tmp)
        try:
            temp.chmod(0o755)
            if not version_ok(temp, version):
                raise ValueError("downloaded Godot binary reports the wrong version")
            temp.replace(binary)
        finally:
            temp.unlink(missing_ok=True)
    print(f"Installed Godot {version}: {binary}")
    return binary


def install_web_templates(cfg: dict, cache: Path, home: Path) -> None:
    url = cfg.get("web_export_templates_url", "")
    digest = cfg.get("web_export_templates_sha256", "")
    if not url and not digest:
        print("NOT RUN: Web templates not configured; preview export unavailable")
        return
    if not url or not digest:
        raise ValueError("Web export templates URL and SHA-256 must both be pinned")
    archive = cache / "web-templates.tpz"
    verified_download(url, digest, archive)
    version = cfg["version"]
    directory = home / ".local/share/godot/export_templates" / f"{version}.stable"
    required = {"web_nothreads_release.zip", "web_nothreads_debug.zip"}
    with zipfile.ZipFile(archive) as zipped:
        matches = {}
        for item in zipped.infolist():
            name = PurePosixPath(item.filename).name
            if name in required and not item.is_dir():
                if name in matches or item.file_size < 100_000 or item.file_size > 500_000_000:
                    raise ValueError("invalid Godot Web template archive")
                matches[name] = item
        if set(matches) != required:
            raise ValueError("missing Godot Web templates")
        directory.mkdir(parents=True, exist_ok=True)
        for name, item in matches.items():
            destination = directory / name
            if destination.is_file() and destination.stat().st_size == item.file_size:
                continue
            with tempfile.NamedTemporaryFile(dir=directory, prefix=".template-", delete=False) as tmp:
                temp = Path(tmp.name)
                try:
                    with zipped.open(item) as src:
                        shutil.copyfileobj(src, tmp)
                    tmp.flush()
                    temp.replace(destination)
                finally:
                    temp.unlink(missing_ok=True)
    print(f"Installed Godot Web templates: {directory}")


def main() -> int:
    settings = json.loads(MANIFEST.read_text(encoding="utf-8"))
    engine = settings.get("engine")
    if engine == "none":
        print("NOT APPLICABLE: neutral template, no game engine selected")
        return 0
    if engine != "godot4":
        print("NOT RUN: selected engine needs a separate provisioning profile")
        return 0
    project = (ROOT / settings["project_path"]).resolve()
    if not project.is_relative_to(ROOT) or not (project / "project.godot").is_file():
        raise ValueError("Godot profile selected but project.godot missing")
    cfg = settings["godot"]
    home = Path.home()
    cache = home / ".cache/game-development-toolchain/godot" / cfg["version"]
    binary = install_editor(cfg, cache, home)
    install_web_templates(cfg, cache, home)
    print("Godot executable:", binary)
    print("Godot version:", subprocess.check_output([str(binary), "--version"], text=True, timeout=30).strip())
    # Import assets for the language server and headless export. A non-zero exit blocks setup.
    subprocess.run([str(binary), "--headless", "--path", str(project), "--import"], check=True, timeout=300)
    print("PASS: Codespaces Godot bootstrap and headless import")
    print("NOT RUN: browser launch, physical touch, visual and audio acceptance")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, subprocess.SubprocessError) as exc:
        print(f"FAIL: Codespaces Godot bootstrap: {exc}", file=sys.stderr)
        sys.exit(1)
