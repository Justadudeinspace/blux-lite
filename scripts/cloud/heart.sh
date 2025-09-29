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
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/env.sh"

[[ -n "${BLUX_DISABLE_HEART:-}" ]] && { echo "Heart is disabled in this build."; exit 0; }

init_admin_secret() {
  local sec="$STATE/admin.secret"
  [[ -f "$sec" ]] || head -c 32 /dev/urandom | base64 > "$sec"
}

launch_heart() {
  init_admin_secret
  if ! pgrep -f "heart_server.py" >/dev/null 2>&1; then
    if command -v python3 >/dev/null 2>&1; then
      (cd "$ROOT_DIR" && nohup python3 heart_server.py >/dev/null 2>&1 & echo $! > "$STATE/heart.pid")
      sleep 0.5
    else
      echo "[!] python3 not found; Heart cannot start."; return 1
    fi
  fi
  if command -v xdg-open >/dev/null 2>&1; then xdg-open http://127.0.0.1:8142/ >/dev/null 2>&1 &
  elif command -v termux-open-url >/dev/null 2>&1; then termux-open-url http://127.0.0.1:8142/ >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then open http://127.0.0.1:8142/ >/dev/null 2>&1 &
  else echo "Visit http://127.0.0.1:8142/ in your browser."; fi
}

launch_heart