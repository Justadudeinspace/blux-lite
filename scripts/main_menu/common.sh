#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Theme (consistent across Legacy/TUI)
BLG_COLOR_PRIMARY=${BLG_COLOR_PRIMARY:-"\033[38;5;220m"}   # gold
BLG_COLOR_ACCENT=${BLG_COLOR_ACCENT:-"\033[38;5;45m"}     # teal-blue
BLG_COLOR_DIM=${BLG_COLOR_DIM:-"\033[2m"}
BLG_RESET="\033[0m"

BLG_BANNER(){
  local t="${1:-BLUX Lite GOLD}"
  printf "${BLG_COLOR_PRIMARY}== ${t} ==${BLG_RESET}\n"
}

say(){ printf "${BLG_COLOR_ACCENT}[BLG]${BLG_RESET} %s\n" "$*"; }
warn(){ printf "\033[33m[WARN]\033[0m %s\n" "$*" >&2; }
err(){ printf "\033[31m[ERR]\033[0m %s\n" "$*" >&2; }
step(){ printf "${BLG_COLOR_DIM}-- %s --${BLG_RESET}\n" "$*"; }
pause(){ read -rp "Continue? [Enter] " _ || true; }

require(){ command -v "$1" >/dev/null 2>&1 || { err "Missing: $1"; return 1; }; }

is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }
is_macos(){ [ "$(uname -s)" = "Darwin" ]; }
is_linux(){ [ "$(uname -s)" = "Linux" ]; }

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
CONFIG_DIR="${CONFIG_DIR:-${REPO_ROOT}/.config/blux-lite-gold}"
LOG_DIR="${LOG_DIR:-${CONFIG_DIR}/logs}"
mkdir -p "${LOG_DIR}"
