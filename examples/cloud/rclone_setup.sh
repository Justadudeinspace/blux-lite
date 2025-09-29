#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# rclone_setup.sh - Configure rclone + test a logs backup
if command -v pkg >/dev/null 2>&1; then pkg install -y rclone || true; fi
if ! command -v rclone >/dev/null 2>&1; then echo "[WARN] rclone unavailable"; exit 0; fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
rclone config || true
REMOTE="${1:-blux-remote}"
DEST="${2:-$REMOTE:blux-backups}"
rclone copy -v "$ROOT/.config/blux-lite-gold" "$DEST" --include "*.log" || true
echo "[OK] rclone test complete → $DEST"
