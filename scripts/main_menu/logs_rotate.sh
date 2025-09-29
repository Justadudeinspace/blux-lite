#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# logs_rotate.sh - Rotate BLUX logs older than N days from config.yaml (default 14)
# Generated: 2025-08-19 07:25:18

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
CONF="$ROOT/.config/blux-lite-gold/config.yaml"
LOG_DIR="$ROOT/.config/blux-lite-gold/logs"; KEEP=14
if [ -f "$CONF" ] && grep -q '^logs-keep-days:' "$CONF"; then
  KEEP="$(grep '^logs-keep-days:' "$CONF" | awk -F':' '{print $2}' | xargs)"
fi
find "$LOG_DIR" -type f -name 'blux-lite-*.log' -mtime "+$KEEP" -print -delete 2>/dev/null || true
echo "[OK] Rotated logs (> $KEEP days)."
