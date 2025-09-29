#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# backup_blux.sh - Backup BLUX repo + (optional) Termux home
# Generated: 2025-08-19 07:25:18

usage() {
  cat <<'EOF'
backup_blux.sh - Backup BLUX repo + (optional) Termux home.

Usage:
  scripts/main_menu/backup_blux.sh [OUTPUT_DIR] [-h|--help]
EOF
}

if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
  usage
  exit 0
fi

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
OUT_DIR="${1:-$ROOT/backups}"; mkdir -p "$OUT_DIR"
DATE="$(date +%Y%m%d_%H%M%S)"; NAME="$(basename "$ROOT")"
tar -czf "$OUT_DIR/${NAME}_repo_${DATE}.tar.gz" -C "$(dirname "$ROOT")" "$NAME" \
  --exclude='*/__pycache__/*' --exclude='*.pyc' --exclude='.git/*' || true
if [ -d "$HOME" ]; then
  tar -czf "$OUT_DIR/termux_home_${DATE}.tar.gz" -C "$HOME" . --exclude='*/.cache/*' --exclude='*/.npm/*' --exclude='*/.cargo/*' || true
fi
echo "[OK] Backups written to $OUT_DIR"
