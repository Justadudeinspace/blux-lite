#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# blux_proot_arch.sh - bootstrap a PRooted Arch Linux (via proot-distro) if available
# Generated: 2025-08-19 07:25:18

if ! command -v proot-distro >/dev/null 2>&1; then
  pkg install -y proot-distro || true
fi
if command -v proot-distro >/dev/null 2>&1; then
  proot-distro install archlinux || true
  echo "[OK] Use: proot-distro login archlinux"
else
  echo "[WARN] proot-distro not available."
fi
