#!/usr/bin/env bash
# Download a previously generated CI Web build and serve via Codespaces port 8765.
# Requires authenticated GitHub CLI. No repository checkout or Godot install required.
set -euo pipefail

run_id="${1:-43226257758}"
dir="${HOME}/.cache/azure-mines-web-preview/${run_id}"
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required to download the Actions artifact." >&2
  exit 2
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI authentication is required. Run: gh auth login" >&2
  exit 2
fi
mkdir -p "$dir"
gh run download "$run_id" --repo Jonty303/Project-AzureMines --name combat-lab-web-build --dir "$dir"
if [[ ! -s "$dir/index.html" ]]; then
  echo "Missing index.html in downloaded artifact: $dir" >&2
  exit 1
fi
echo "Serving Combat Lab from $dir"
echo "In Codespaces, open the Ports tab and select port 8765 (keep it private)."
python3 -m http.server 8765 --bind 0.0.0.0 --directory "$dir"
