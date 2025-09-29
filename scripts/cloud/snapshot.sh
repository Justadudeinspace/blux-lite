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
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
CLOUD="${CLOUD_MOUNT:-}"
[[ -n "$CLOUD" ]] || { echo "[!] Set CLOUD_MOUNT"; exit 1; }

CMD="${1:-}"; shift || true
case "$CMD" in
  save)
    name="${1:-models_$(date +%Y%m%d_%H%M%S)}"
    tar -C "$ROOT_DIR" -czf "$CLOUD/${name}.tar.gz" models 2>/dev/null || tar -czf "$CLOUD/${name}.tar.gz" models
    echo "[OK] Saved $CLOUD/${name}.tar.gz"
    ;;
  restore)
    echo "Available snapshots:"; ls -1 "$CLOUD"/*.tar.gz 2>/dev/null || { echo "none"; exit 1; }
    read -rp "Pick file path: " FP
    [[ -f "$FP" ]] || { echo "missing"; exit 1; }
    tar -C "$ROOT_DIR" -xzf "$FP"
    echo "[OK] Restored from $FP"
    ;;
  *)
    echo "Usage: snapshot.sh {save [name]|restore}"; exit 1
    ;;
esac