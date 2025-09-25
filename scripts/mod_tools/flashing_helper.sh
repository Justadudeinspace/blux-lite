#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# flashing_helper.sh - cautious fastboot helper
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
FASTBOOT="$(command -v fastboot || true)"
[ -z "$FASTBOOT" ] && echo "[ERR] fastboot not found (pkg install android-tools)" && exit 1
CONFIRM="${1:-}"
if [ "$CONFIRM" != "--i-understand" ]; then
  cat <<'E'
[SAFETY] This helper only runs fastboot after --i-understand
Examples:
  fastboot devices
  fastboot flash boot boot.img
  fastboot reboot
E
  exit 0
fi
shift || true
exec fastboot "$@"