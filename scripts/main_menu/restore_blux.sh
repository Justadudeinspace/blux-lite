#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# restore_blux.sh - Restore archives created by backup_blux.sh
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
IN="${1:-}"; DEST="${2:-$HOME}"
[ -z "$IN" ] && echo "Usage: $0 <archive.tar.gz> [dest]" && exit 1
mkdir -p "$DEST"; tar -xzf "$IN" -C "$DEST"; echo "[OK] Restored → $DEST"