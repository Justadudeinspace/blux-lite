#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# aliases_install.sh - BLUX helpful aliases
# Generated: 2025-08-19 07:25:18

usage() {
  cat <<'EOF'
alias_install.sh - Install helpful shell aliases.

Usage:
  scripts/main_menu/aliases_install.sh [-h|--help]
EOF
}

if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
  usage
  exit 0
fi

BRC="$HOME/.bashrc"
add() { grep -qxF "$1" "$BRC" 2>/dev/null || printf "%s\n" "$1" >> "$BRC"; }
add '# === BLUX aliases ==='
add "alias ll='eza -la --icons 2>/dev/null || ls -la'"
add "alias cat='bat --paging=never 2>/dev/null || cat'"
add "alias gs="git status -sb""
add "alias rg='rg 2>/dev/null || grep'"
add "alias fd='fd 2>/dev/null || find'"
add "alias top='btop 2>/dev/null || htop 2>/dev/null || top'"
echo "[OK] Aliases added. 'source ~/.bashrc' to apply."
