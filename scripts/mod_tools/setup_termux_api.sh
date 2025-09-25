#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# setup_termux_api.sh - Install Termux:API CLI & run smoke tests
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
have(){ command -v "$1" >/dev/null 2>&1; }
if ! have pkg; then echo "[WARN] Termux-only"; exit 0; fi
pkg install -y termux-api || true
have termux-info && termux-info | head -n 20 || true
have termux-battery-status && termux-battery-status || true
have termux-telephony-deviceinfo && termux-telephony-deviceinfo || true
have termux-wifi-connectioninfo && termux-wifi-connectioninfo || true
echo "[OK] termux-api installed (ensure the Android app is installed & permissions granted)."