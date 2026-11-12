#!/usr/bin/env bash
# Run with a verified, pinned Godot editor binary; never imply engine provisioning.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-}"
if [[ -z "$godot_bin" ]]; then
  echo "NOT RUN: set GODOT_BIN to a verified Godot editor executable." >&2
  exit 2
fi
if [[ ! -x "$godot_bin" ]]; then
  echo "FAIL: GODOT_BIN is not executable: $godot_bin" >&2
  exit 2
fi
if [[ -f "$repo_root/game/project.godot" ]]; then
  project="$repo_root/game"
elif [[ -f "$repo_root/project.godot" ]]; then
  project="$repo_root"
else
  echo "NOT RUN: no project.godot (template has no engine project)." >&2
  exit 2
fi
echo "Godot executable: $godot_bin"
"$godot_bin" --version
echo "Importing and parsing project: $project"
"$godot_bin" --headless --path "$project" --import
echo "PASS: Godot headless import exited successfully."
echo "NOT RUN: interactive rendering, controller feel, or export; run separately."
