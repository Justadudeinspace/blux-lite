#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# diagnostics.sh - System diagnostics (Termux-friendly)
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
have(){ command -v "$1" >/dev/null 2>&1; }
echo "=== uname -a ==="; uname -a || true
echo "=== termux-info ==="; have termux-info && termux-info | head -n 40 || echo "termux-info not installed"
echo "=== Disk ==="; have duf && duf || df -h
echo "=== Procs ==="; have btop && btop || have htop && htop || true
echo "Top mem:"; ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
echo "=== Network ==="; ip addr || true; ip route || true