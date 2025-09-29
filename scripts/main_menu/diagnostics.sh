#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# diagnostics.sh - System diagnostics (Termux-friendly)
# Generated: 2025-08-19 07:25:18

have(){ command -v "$1" >/dev/null 2>&1; }
is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }

echo "=== uname -a ==="; uname -a || true

if is_termux && have termux-info; then
  echo "=== termux-info ==="
  termux-info | head -n 40
else
  echo "=== termux-info === (skipped: not on termux or termux-info not found)"
fi

echo "=== Disk ==="; have duf && duf || df -h
echo "=== Procs ==="; have btop && btop || have htop && htop || true
echo "Top mem:"; ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
echo "=== Network ==="; ip addr || true; ip route || true
