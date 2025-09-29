#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# starship_setup.sh - Install Starship prompt and enable in bash
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
if command -v pkg >/dev/null 2>&1; then pkg install -y starship || true; fi
CFG="$HOME/.config/starship.toml"; mkdir -p "$(dirname "$CFG")"
if [ ! -f "$CFG" ]; then cat > "$CFG" <<'EOF'
add_newline = false
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"
[git_branch]
symbol = " "
truncation_length = 24
EOF
fi
grep -q 'starship init bash' "$HOME/.bashrc" 2>/dev/null || printf '\n# Starship\neval "$(starship init bash)"\n' >> "$HOME/.bashrc"
echo "[OK] Starship configured. 'source ~/.bashrc' to apply."