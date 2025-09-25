#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# wifi_battery_info.sh - quick Termux:API status
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
have(){ command -v "$1" >/dev/null 2>&1; }
have termux-battery-status && termux-battery-status || echo "Install termux-api"
have termux-telephony-deviceinfo && termux-telephony-deviceinfo || true
have termux-wifi-connectioninfo && termux-wifi-connectioninfo || true
have termux-location && termux-location || true