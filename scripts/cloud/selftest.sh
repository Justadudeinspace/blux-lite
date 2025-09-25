#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail

# Upstream logging (must be before other output)
# --- begin BLG root resolver ---
BLG_SELF_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"
BLG_ROOT="$BLG_SELF_DIR"
while [ "$BLG_ROOT" != "/" ] && [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; do
  BLG_ROOT="$(dirname "$BLG_ROOT")"
done
if [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; then
  printf '[ERR] Could not locate BLG root (starting at %s)\n' "$BLG_SELF_DIR" >&2
  exit 1
fi
PROJECT_ROOT="$BLG_ROOT"; REPO_ROOT="$BLG_ROOT"
source "$BLG_ROOT/scripts/main_menu/logging.sh"
# --- end BLG root resolver ---

set -Eeuo pipefail
echo "[SELFTEST] Mode file:"; cat "$HOME/.blux-lite/mode" 2>/dev/null || echo "<none>"
echo "[SELFTEST] Catalog present:"; test -f "./docs/catalog.json" && echo "ok" || echo "missing"
echo "[SELFTEST] Models dir:"; ls -lah "./models" || true
echo "[SELFTEST] Cloud mount:"; [[ -n "${CLOUD_MOUNT:-}" ]] && ls -lah "$CLOUD_MOUNT" | head || echo "CLOUD_MOUNT not set"
echo "[SELFTEST] Done."