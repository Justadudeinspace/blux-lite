#!/usr/bin/env bash
# BLUX Lite — TUI wrapper for: scripts/install_power_tools.sh
# Generated: 2025-09-17T20:01:07Z
set -euo pipefail
IFS=$'\n\t'

uname_s="$(uname -s || echo unknown)"
is_macos=0; is_linux=0; is_termux=0
case "${uname_s}" in
  Darwin) is_macos=1 ;;
  Linux)  is_linux=1 ;;
esac
if command -v termux-info >/dev/null 2>&1; then is_termux=1; fi

need() { command -v "$1" >/dev/null 2>&1 || echo "[!] Missing dependency: $1" >&2; }
need bash; need awk; need sed; need grep; need printf

ORIG="scripts/install_power_tools.sh"
ORIG_ABS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/install_power_tools.sh"
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(basename "scripts/install_power_tools.sh").log"

run_script() {
  local mode="$1"
  local verbose="$2"
  local assume="$3"
  local args=()
  if [[ "$mode" == "dry" ]]; then args+=("--dry-run"); export DRY_RUN=1; fi
  if [[ "$verbose" == "1" ]]; then args+=("--verbose"); fi
  if [[ "$assume" == "1" ]]; then args+=("--yes"); fi
  echo "[i] Running $ORIG with: ${args[*]}" | tee -a "$LOG_FILE"
  if [[ ! -x "$ORIG_ABS" ]]; then chmod +x "$ORIG_ABS" || true; fi
  bash "$ORIG_ABS" "${args[@]}" 2>&1 | tee -a "$LOG_FILE" || true
}

# Non-interactive CI mode
if [[ "${BLUX_TUI_AUTO:-}" == "1" ]]; then
  mode="${BLUX_TUI_MODE:-dry-verbose}"
  if [[ "$mode" == "dry-verbose" ]]; then run_script dry 1 1; exit 0; fi
  if [[ "$mode" == "dry-quiet" ]]; then run_script dry 0 1; exit 0; fi
fi

menu() {
  while true; do
    clear
    echo "=== BLUX TUI: $(basename "scripts/install_power_tools.sh") ==="
    echo "1) Dry run (verbose)"
    echo "2) Dry run (quiet)"
    echo "3) Execute live (requires confirm)"
    echo "4) View log"
    echo "5) Print original --help (if supported)"
    echo "q) Quit"
    read -r -p "Select: " ans || true
    case "$ans" in
      1) run_script dry 1 1; read -r -p "Press Enter..." _ ;;
      2) run_script dry 0 1; read -r -p "Press Enter..." _ ;;
      3) read -r -p "Type 'RUN' to confirm: " c && [[ "$c" == "RUN" ]] && run_script live 1 0 || echo "Cancelled"; read -r -p "Press Enter..." _ ;;
      4) less "$LOG_FILE" || cat "$LOG_FILE"; read -r -p "Press Enter..." _ ;;
      5) bash "$ORIG_ABS" --help || true; read -r -p "Press Enter..." _ ;;
      q|Q) break ;;
      *) : ;;
    esac
  done
}
menu