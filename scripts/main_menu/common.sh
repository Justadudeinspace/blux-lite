#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
CONFIG_DIR="${CONFIG_DIR:-${ROOT}/.config/blux-lite-gold}"
LOG_DIR="${LOG_DIR:-${CONFIG_DIR}}"
say(){ printf '[BLUX] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }
is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }
if [ -x "${ROOT}/.venv/bin/python" ]; then PYBIN="${ROOT}/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then PYBIN="$(command -v python3)"
elif command -v python  >/dev/null 2>&1; then PYBIN="$(command -v python)"; else PYBIN=""; fi
export ROOT CONFIG_DIR LOG_DIR PYBIN
BLG_COLOR_PRIMARY=$'\033[38;5;220m'; BLG_COLOR_ACCENT=$'\033[38;5;45m'; BLG_COLOR_DIM=$'\033[2m'; BLG_RESET=$'\033[0m'
mkdir -p "${LOG_DIR}"
