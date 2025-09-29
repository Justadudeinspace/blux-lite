#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# blux_styling_apply.sh - apply Termux:Styling presets if available
# Generated: 2025-08-19 07:25:18

is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }
have(){ command -v "$1" >/dev/null 2>&1; }

TERMUX_PROPS="$HOME/.termux/termux.properties"
mkdir -p "$HOME/.termux"
grep -q '^use-black-ui' "$TERMUX_PROPS" 2>/dev/null || echo "use-black-ui = true" >> "$TERMUX_PROPS"
grep -q '^bell-character' "$TERMUX_PROPS" 2>/dev/null || echo "bell-character = ignore" >> "$TERMUX_PROPS"

if is_termux && have termux-reload-settings; then
  termux-reload-settings
fi

echo "[OK] Styling hints applied. For full themes/fonts use Termux:Styling app."

