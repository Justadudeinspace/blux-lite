#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# run_shellcheck.sh - Lint all .sh files with shellcheck
# Generated: 2025-08-19 07:25:18

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[WARN] shellcheck not installed. pkg install shellcheck"; exit 0; fi
mapfile -t files < <(find "$ROOT" -type f -name "*.sh" -print | sort)
[ "${#files[@]}" -eq 0 ] && echo "[WARN] no .sh files" && exit 0
shellcheck -S style "${files[@]}" | tee "$ROOT/.config/blux-lite-gold/shellcheck_report.txt" || true
echo "[OK] Report saved."
