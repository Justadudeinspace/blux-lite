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

admin_gate() {
  local grant="$STATE/admin.grant"
  [[ -f "$grant" ]] || { echo "Admin locked. Use Heart of JADIS."; return 1; }
  local line exp sig now secret calc
  line=$(cat "$grant"); exp=${line%%|*}; sig=${line#*|}
  now=$(date +%s)
  if [[ "$now" -ge "$exp" ]]; then echo "Admin grant expired."; rm -f "$grant"; return 1; fi
  command -v openssl >/dev/null 2>&1 || { echo "[!] openssl missing"; return 1; }
  secret=$(cat "$STATE/admin.secret")
  calc=$(printf "%s" "$exp" | openssl dgst -sha256 -hmac "$secret" -binary | base64 | tr -d '\n')
  [[ "$calc" == "$sig" ]] || { echo "Admin grant invalid."; return 1; }
  return 0
}

if admin_gate; then
  echo "-- Admin menu --"
  echo "(add privileged actions here)"
else
  echo "Locked."
fi