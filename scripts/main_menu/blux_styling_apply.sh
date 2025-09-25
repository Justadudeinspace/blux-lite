#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# blux_styling_apply.sh - apply Termux:Styling presets if available
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
TERMUX_PROPS="$HOME/.termux/termux.properties"
mkdir -p "$HOME/.termux"
grep -q '^use-black-ui' "$TERMUX_PROPS" 2>/dev/null || echo "use-black-ui = true" >> "$TERMUX_PROPS"
grep -q '^bell-character' "$TERMUX_PROPS" 2>/dev/null || echo "bell-character = ignore" >> "$TERMUX_PROPS"
termux-reload-settings 2>/dev/null || true
echo "[OK] Styling hints applied. For full themes/fonts use Termux:Styling app."