#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# aliases_install.sh - BLUX helpful aliases
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
BRC="$HOME/.bashrc"
add(){ grep -qxF "$1" "$BRC" 2>/dev/null || printf "%s\n" "$1" >> "$BRC"; }
add '# === BLUX aliases ==='
add "alias ll='eza -la --icons 2>/dev/null || ls -la'"
add "alias cat='bat --paging=never 2>/dev/null || cat'"
add "alias gs="git status -sb""
add "alias rg='rg 2>/dev/null || grep'"
add "alias fd='fd 2>/dev/null || find'"
add "alias top='btop 2>/dev/null || htop 2>/dev/null || top'"
echo "[OK] Aliases added. 'source ~/.bashrc' to apply."