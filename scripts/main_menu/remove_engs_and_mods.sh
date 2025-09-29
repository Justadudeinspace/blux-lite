#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
ROOT="${BLUX_ROOT:-$HOME/blux-lite}"
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