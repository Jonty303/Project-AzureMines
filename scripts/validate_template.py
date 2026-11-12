#!/usr/bin/env python3
"""Validate source documentation contract without external dependencies.

Template mode checks files, guidance, and hidden examples.
Project mode requires completed project context and explicit review of environment.
No test claims a Godot build or interactive playtest.
"""
from pathlib import Path
import argparse
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = (
    "README.md", "AGENTS.md",
    "context/PROJECT_CONTEXT.md", "architecture/ARCHITECTURE.md",
    "specifications/README.md",
    "specifications/foundation/SPEC-001-game-loop.md",
    "specifications/foundation/SPEC-002-player-controller.md",
    "specifications/foundation/SPEC-003-data-model.md",
    "agents/ROLES.md", "standards/ENGINEERING.md",
    "workflows/DELIVERY.md", "development/ENVIRONMENT_SETUP.md",
    "development/ENVIRONMENT_CONTRACT.md",
    "development/VALIDATION_MATRIX.md",
)
GUIDED = (
    "context/PROJECT_CONTEXT.md", "architecture/ARCHITECTURE.md",
    "specifications/foundation/SPEC-001-game-loop.md",
    "specifications/foundation/SPEC-002-player-controller.md",
    "specifications/foundation/SPEC-003-data-model.md",
    "agents/ROLES.md", "standards/ENGINEERING.md",
    "workflows/DELIVERY.md", "development/ENVIRONMENT_SETUP.md",
    "development/VALIDATION_MATRIX.md",
)
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--project", action="store_true", help="Require completed project context (engine-agnostic)")
    args = p.parse_args()
    errors = []
    for name in REQUIRED:
        if not (ROOT / name).is_file():
            errors.append(f"missing: {name}")
    for name in GUIDED:
        path = ROOT / name
        if not path.is_file():
            continue
        content = path.read_text(encoding="utf-8")
        for heading in ("## Purpose", "## Human instructions", "## AI agent instructions"):
            if heading not in content:
                errors.append(f"{name}: missing {heading}")
        if "<!--" not in content or "-->" not in content or "[EXAMPLE" not in content:
            errors.append(f"{name}: missing commented worked example")
        if content.count("<!--") != content.count("-->"):
            errors.append(f"{name}: unbalanced HTML comment markers")
    if args.project:
        context = ROOT / "context/PROJECT_CONTEXT.md"
        if context.is_file() and "[TODO]" in context.read_text(encoding="utf-8"):
            errors.append("project context still has [TODO] fields")
    for error in errors:
        print("FAIL:", error)
    if errors:
        return 1
    print("PASS: documentation structure and source examples")
    print("NOT RUN: Godot import, gameplay tests, visual review and controller tests")
    if args.project:
        print("NOTE: project mode checks only minimal readiness, not acceptance or runtime correctness")
    return 0
if __name__ == "__main__":
    sys.exit(main())
