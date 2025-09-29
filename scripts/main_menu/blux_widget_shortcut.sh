#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# blux_widget_shortcut.sh - create a Termux:Widget shortcut script
# Generated: 2025-08-19 07:25:18

W="$HOME/.shortcuts"; mkdir -p "$W"
cat > "$W/BLUX Main Menu.sh" <<'S'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/blux-lite-gold" || exit 0
exec ./blux-lite.sh
S
chmod +x "$W/BLUX Main Menu.sh"
echo "[OK] Widget shortcut created (add via Termux:Widget)."
