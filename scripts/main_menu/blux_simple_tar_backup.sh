#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# blux_simple_tar_backup.sh - simple tar.gz of BLUX folder (fallback backup)
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
OUT="${1:-$ROOT/backups}"; mkdir -p "$OUT"
DATE="$(date +%Y%m%d_%H%M%S)"; NAME="$(basename "$ROOT")"
tar -czf "$OUT/${NAME}_simple_${DATE}.tar.gz" -C "$(dirname "$ROOT")" "$NAME"
echo "[OK] Wrote $OUT/${NAME}_simple_${DATE}.tar.gz"