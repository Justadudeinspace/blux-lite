#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# termux_boot_enable_blux.sh - Use Termux:Boot to start BLUX on boot
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
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