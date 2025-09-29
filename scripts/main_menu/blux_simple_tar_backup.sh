#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# blux_simple_tar_backup.sh - simple tar.gz of BLUX folder (fallback backup)
# Generated: 2025-08-19 07:25:18

usage() {
  cat <<'EOF'
blux_simple_tar_backup.sh - simple tar.gz of BLUX folder (fallback backup).

Usage:
  scripts/main_menu/blux_simple_tar_backup.sh [OUTPUT_DIR] [-h|--help]
EOF
}

if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
  usage
  exit 0
fi

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
OUT="${1:-$ROOT/backups}"; mkdir -p "$OUT"
DATE="$(date +%Y%m%d_%H%M%S)"; NAME="$(basename "$ROOT")"
tar -czf "$OUT/${NAME}_simple_${DATE}.tar.gz" -C "$(dirname "$ROOT")" "$NAME"
echo "[OK] Wrote $OUT/${NAME}_simple_${DATE}.tar.gz"
