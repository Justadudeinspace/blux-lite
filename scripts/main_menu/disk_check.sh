#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
ROOT="${BLUX_ROOT:-$HOME/blux-lite}"
echo "== Disk Space Check =="
echo "Root: $ROOT"
if ! df -h "$ROOT" >/dev/null 2>&1; then
  mkdir -p "$ROOT"
  df -h "$ROOT"
else
  df -h "$ROOT"
fi
echo ""
echo "Installed models:"
ls -lh "$ROOT/models"/*.gguf 2>/dev/null || echo "(none)"