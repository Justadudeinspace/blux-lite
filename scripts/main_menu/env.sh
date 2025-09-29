#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# Upstream logging (must be before other output)
# --- begin BLG root resolver ---
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROJECT_ROOT="$ROOT"; REPO_ROOT="$ROOT"
source "$ROOT/scripts/main_menu/logging.sh"
# --- end BLG root resolver ---

# Colors
BOLD="\033[1m"; DIM="\033[2m"; RESET="\033[0m"; CYAN="\033[36m"; MAG="\033[35m"; YEL="\033[33m"

ROOT_DIR="$ROOT"
STATE="$HOME/.blux-lite"
MODE_FILE="$STATE/mode"
mkdir -p "$STATE"

: "${BLUX_EDITION:=PERSONAL}" # PERSONAL (Gold) or PUBLIC

banner() {
  clear || true
  local edition_name
  if [[ "${BLUX_EDITION}" == "PERSONAL" ]]; then
    edition_name="BLUX‑Lite Gold Edition"
  else
    edition_name="BLUX‑Lite Public Edition"
  fi
  echo -e "${BOLD}${CYAN}█▀▀ ▄█  █ █ █ ▀█▀     ▄     █   █ ▄▀▀  ${MAG}BLUX‑Lite${RESET}"
  echo -e "${BOLD}${CYAN}█▀  ▀█  █▀█ █  █     ▀▄█ ▄  █   █ ▀▄█  ${YEL}${edition_name}${RESET}"
  echo
}
