#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

say(){ printf "[BLUX] %s\n" "$*"; }
warn(){ printf "[WARN] %s\n" "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }
is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }

usage(){
  cat <<'EOF'
wifi_battery_info.sh — quick Termux:API status

Prints:
- Battery status (termux-battery-status)
- Telephony device info (termux-telephony-deviceinfo) if available
- Wi-Fi connection info (termux-wifi-connectioninfo) if available
- Location (termux-location) if available

Notes: Requires Termux + Termux:API app. On non-Termux systems, this exits gracefully.
EOF
}

case "${1-}" in -h|--help|help) usage; exit 0;; esac

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
cleanup(){
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if ! is_termux; then
  warn "Not running under Termux; Termux:API commands are unavailable."
  exit 0
fi

say "== Battery =="
if have termux-battery-status; then
  termux-battery-status || warn "battery-status failed"
else
  warn "Missing termux-battery-status (install Termux:API)."
fi

say ""
say "== Telephony =="
if have termux-telephony-deviceinfo; then
  termux-telephony-deviceinfo || warn "telephony-deviceinfo failed"
else
  say "(telephony info not available)"
fi

say ""
say "== Wi-Fi =="
if have termux-wifi-connectioninfo; then
  termux-wifi-connectioninfo || warn "wifi-connectioninfo failed"
else
  say "(wifi info not available)"
fi

say ""
say "== Location =="
if have termux-location; then
  termux-location || warn "location failed"
else
  say "(location not available)"
fi
