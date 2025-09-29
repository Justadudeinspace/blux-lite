#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# blux_proot_arch.sh - bootstrap a PRooted Arch Linux (via proot-distro) if available
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
if ! command -v proot-distro >/dev/null 2>&1; then
  pkg install -y proot-distro || true
fi
if command -v proot-distro >/dev/null 2>&1; then
  proot-distro install archlinux || true
  echo "[OK] Use: proot-distro login archlinux"
else
  echo "[WARN] proot-distro not available."
fi