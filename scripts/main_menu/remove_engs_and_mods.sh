#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

echo "== Uninstall / Cleanup =="
echo "This will remove engines/ and models/ under: $ROOT"
echo "Apps, projects, and configs will remain."
echo ""
read -r -p "Type REMOVE to proceed: " ans
if [[ "$ans" == "REMOVE" ]]; then
  rm -rf "$ROOT/engines" "$ROOT/models"
  # Attempt to remove local symlinks (optional, non-fatal)
  rm -f "$ROOT/bin/llama" "$ROOT/bin/whisper" "$ROOT/bin/alpaca" || true
  echo "Removed engines/ and models/."
else
  echo "Aborted."
fi
