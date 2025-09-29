#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# termux_boot_enable_blux.sh - Use Termux:Boot to start BLUX on boot
# Generated: 2025-08-19 07:25:18

BOOT="$HOME/.termux/boot"; mkdir -p "$BOOT"
cat > "$BOOT/99-blux.sh" <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
sleep 15
termux-wake-lock || true
cd "$HOME/blux-lite-gold" || exit 0
[ -x ./blux-lite.sh ] && ./blux-lite.sh
EOS
chmod +x "$BOOT/99-blux.sh"
echo "[OK] Boot hook created at $BOOT/99-blux.sh (install/open Termux:Boot app once)."
