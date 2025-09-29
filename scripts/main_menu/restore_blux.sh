#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# restore_blux.sh - Restore archives created by backup_blux.sh
# Generated: 2025-08-19 07:25:18

usage() {
    cat <<'EOF'
restore_blux.sh - Restore archives created by backup_blux.sh

Usage:
  scripts/main_menu/restore_blux.sh <archive.tar.gz> [destination_path] [-h|--help]
EOF
}

if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
    usage
    exit 0
fi

IN="${1:-}"; DEST="${2:-$HOME}"
[ -z "$IN" ] && echo "Usage: $0 <archive.tar.gz> [dest]" && exit 1
mkdir -p "$DEST"; tar -xzf "$IN" -C "$DEST"; echo "[OK] Restored → $DEST"
