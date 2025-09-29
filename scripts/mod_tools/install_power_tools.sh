#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
: "${BLG_ENABLE_CLOUD:=0}"
if [[ "${BLG_ENABLE_CLOUD}" != "1" ]]; then
  echo "[BLUX] Cloud helpers are disabled. Set BLG_ENABLE_CLOUD=1 to enable." >&2
  exit 0
fi

# install_power_tools.sh - Install power CLI & TUI tools for Termux
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
: "${BLG_ENABLE_CLOUD:=0}"
if [[ "$BLG_ENABLE_CLOUD" != "1" ]]; then
  echo "[BLUX] Cloud helpers are disabled. Set BLG_ENABLE_CLOUD=1 to enable." >&2
  exit 0
fi
IFS=$'\n\t'
have(){ command -v "$1" >/dev/null 2>&1; }
say(){ printf "%b\n" "$*"; }
warn(){ printf "\033[33m[WARN]\033[0m %s\n" "$*"; }

if ! have pkg; then warn "This script targets Termux ('pkg')."; exit 0; fi
say "[*] Updating package lists..."
pkg update -y || true
pkg upgrade -y || true

TOOLS=(jq fzf dialog whiptail bat eza duf htop btop ripgrep fd procs shellcheck starship gh rclone termux-tools termux-api android-tools)
for t in "${TOOLS[@]}"; do
  if pkg show "$t" >/dev/null 2>&1; then
    say "[*] Installing: $t"
    pkg install -y "$t" || warn "Could not install $t"
  fi
done

# python/pip compat
if command -v python >/dev/null 2>&1 && [ ! -e "$PREFIX/bin/python3" ]; then ln -sf "$(command -v python)" "$PREFIX/bin/python3" || true; fi
if command -v pip >/dev/null 2>&1 && [ ! -e "$PREFIX/bin/pip3" ]; then ln -sf "$(command -v pip)" "$PREFIX/bin/pip3" || true; fi

say "[OK] Power tools installation attempted."