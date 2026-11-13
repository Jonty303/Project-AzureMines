#!/usr/bin/env python3
"""Validate the toolchain manifest without downloading or running an engine."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def validate(root=ROOT):
    errors = []
    path = root / "development/toolchain.json"
    try:
        cfg = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        return [f"invalid toolchain manifest: {exc}"]
    if cfg.get("schema_version") != 1:
        errors.append("schema_version must be 1")
    engine = cfg.get("engine")
    if engine not in ("none", "godot4", "other"):
        errors.append("engine must be none, godot4 or other")
    project_path = cfg.get("project_path")
    if not isinstance(project_path, str) or not project_path or project_path.startswith("/") or ".." in Path(project_path).parts:
        errors.append("project_path must be a relative directory within repository")
    if engine == "godot4":
        settings = cfg.get("godot", {})
        version = settings.get("version", "")
        if not isinstance(version, str) or not re.fullmatch(r"4\.[0-9]+(?:\.[0-9]+)?(?:-[A-Za-z0-9._-]+)?", version):
            errors.append("godot.version must be an explicit Godot 4 version")
        url = settings.get("linux_download_url", "")
        sha = settings.get("linux_sha256", "")
        if not isinstance(url, str) or not url.startswith("https://"):
            errors.append("godot.linux_download_url must be HTTPS")
        if not isinstance(sha, str) or not re.fullmatch(r"[0-9a-fA-F]{64}", sha):
            errors.append("godot.linux_sha256 must be 64 hex characters")
        web_url = settings.get("web_export_templates_url", "")
        web_sha = settings.get("web_export_templates_sha256", "")
        if bool(web_url) != bool(web_sha):
            errors.append("godot web export URL and SHA256 must be supplied together")
        if web_url and (not isinstance(web_url, str) or not web_url.startswith("https://")):
            errors.append("godot.web_export_templates_url must be HTTPS")
        if web_sha and (not isinstance(web_sha, str) or not re.fullmatch(r"[0-9a-fA-F]{64}", web_sha)):
            errors.append("godot.web_export_templates_sha256 must be 64 hex characters")
        if isinstance(project_path, str) and project_path and not (root / project_path / "project.godot").is_file():
            errors.append("Godot profile selected, but project.godot is absent")
    if engine == "none" and ((root / "project.godot").is_file() or (root / "game/project.godot").is_file()):
        errors.append("Godot project exists but engine profile is none")
    return errors

def main():
    errors = validate()
    for error in errors:
        print("FAIL:", error)
    if errors:
        return 1
    print("PASS: toolchain contract")
    print("NOT RUN: engine installation and runtime tests")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
