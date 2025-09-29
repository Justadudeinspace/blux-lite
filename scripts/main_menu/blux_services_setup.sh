#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# blux_services_setup.sh - setup/enable a termux-services runit service for BLUX
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
if ! command -v sv-enable >/dev/null 2>&1; then
  echo "[*] Installing termux-services..."
  pkg install -y termux-services || true
fi
SVD="$PREFIX/var/service/blux"
mkdir -p "$SVD"
cat > "$SVD/run" <<'RUN'
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
cd "$HOME/blux-lite-gold" || exit 0
exec ./blux-lite.sh
RUN
chmod +x "$SVD/run"
sv-enable blux || true
sv up blux || true
echo "[OK] termux-service 'blux' installed. Use: sv status blux"