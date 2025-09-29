#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# blux_autostart_boot.sh - create/update Termux Boot hook to autostart BLUX
# Generated: 2025-08-19 07:25:18

BOOT="$HOME/.termux/boot"; mkdir -p "$BOOT"
TARGET="$BOOT/10-blux-autostart.sh"
cat > "$TARGET" <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock || true
sleep 10
cd "$HOME/blux-lite-gold" || exit 0
[ -x ./blux-lite.sh ] && ./blux-lite.sh
EOS
chmod +x "$TARGET"
echo "[OK] Boot hook at $TARGET"
