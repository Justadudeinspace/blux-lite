#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# run_shellcheck.sh - Lint all .sh files with shellcheck
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[WARN] shellcheck not installed. pkg install shellcheck"; exit 0; fi
mapfile -t files < <(find "$ROOT" -type f -name "*.sh" -print | sort)
[ "${#files[@]}" -eq 0 ] && echo "[WARN] no .sh files" && exit 0
shellcheck -S style "${files[@]}" | tee "$ROOT/.config/blux-lite/shellcheck_report.txt" || true
echo "[OK] Report saved."