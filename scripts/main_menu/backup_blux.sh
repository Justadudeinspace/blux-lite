#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# backup_blux.sh - Backup BLUX repo + (optional) Termux home
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
OUT_DIR="${1:-$REPO_ROOT/backups}"; mkdir -p "$OUT_DIR"
DATE="$(date +%Y%m%d_%H%M%S)"; NAME="$(basename "$REPO_ROOT")"
tar -czf "$OUT_DIR/${NAME}_repo_${DATE}.tar.gz" -C "$(dirname "$REPO_ROOT")" "$NAME" \
  --exclude='*/__pycache__/*' --exclude='*.pyc' --exclude='.git/*' || true
if [ -d "$HOME" ]; then
  tar -czf "$OUT_DIR/termux_home_${DATE}.tar.gz" -C "$HOME" . --exclude='*/.cache/*' --exclude='*/.npm/*' --exclude='*/.cargo/*' || true
fi
echo "[OK] Backups written to $OUT_DIR"