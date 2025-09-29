#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail

# Upstream logging (must be before other output)
# --- begin BLG root resolver ---
BLG_SELF_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"
BLG_ROOT="$BLG_SELF_DIR"
while [ "$BLG_ROOT" != "/" ] && [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; do
  BLG_ROOT="$(dirname "$BLG_ROOT")"
done
if [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; then
  printf '[ERR] Could not locate BLG root (starting at %s)\n' "$BLG_SELF_DIR" >&2
  exit 1
fi
PROJECT_ROOT="$BLG_ROOT"; REPO_ROOT="$BLG_ROOT"
source "$BLG_ROOT/scripts/main_menu/logging.sh"
# --- end BLG root resolver ---

set -Eeuo pipefail

# Colors
BOLD="\033[1m"; DIM="\033[2m"; RESET="\033[0m"; CYAN="\033[36m"; MAG="\033[35m"; YEL="\033[33m"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$ROOT_DIR/.." && pwd)"
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