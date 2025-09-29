#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# adb_helper.sh - ADB wrapper
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
ADB="$(command -v adb || true)"
if [ -z "$ADB" ]; then
  if command -v pkg >/dev/null 2>&1 && pkg show android-tools >/dev/null 2>&1; then
    pkg install -y android-tools || true
    ADB="$(command -v adb || true)"
  fi
fi
if [ -z "$ADB" ]; then echo "[ERR] adb not found"; exit 1; fi
case "${1:-}" in
  devices) exec "$ADB" devices -l ;;
  logcat) exec "$ADB" logcat ;;
  shell) exec "$ADB" shell ;;
  pull) shift; exec "$ADB" pull "$@" ;;
  push) shift; exec "$ADB" push "$@" ;;
  reboot) exec "$ADB" reboot ;;
  bootloader) exec "$ADB" reboot bootloader ;;
  *) cat <<'H'
Usage: adb_helper.sh [devices|logcat|shell|pull|push|reboot|bootloader]
H
  ;;
esac