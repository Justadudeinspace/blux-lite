#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# logs_rotate.sh - Rotate BLUX logs older than N days from config.yaml (default 14)
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
CONF="$ROOT/.config/blux-lite/config.yaml"; LOG_DIR="$ROOT/.config/blux-lite"; KEEP=14
if [ -f "$CONF" ] && grep -q '^logs-keep-days:' "$CONF"; then
  KEEP="$(grep '^logs-keep-days:' "$CONF" | awk -F':' '{print $2}' | xargs)"
fi
find "$LOG_DIR" -type f -name 'blux-lite-*.log' -mtime "+$KEEP" -print -delete 2>/dev/null || true
echo "[OK] Rotated logs (> $KEEP days)."