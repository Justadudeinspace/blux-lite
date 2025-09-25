#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
# blux_cloud_safety_addon.sh
# Cloud sync + snapshots + SAFE/RED modes + wrapper for unified install

# Upstream logging (must be before other output)
# --- begin BLG root resolver ---
BLG_SELF_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"
BLG_ROOT="$BLG_SELF_DIR"
while [ "$BLG_ROOT" != "/" ] && [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; do
  BLG_ROOT="$(dirname "$BLG_ROOT")"
done
if [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; then
  printf '[ERR] Could not locate BLG root (starting at %s)\n' "$BLG_SELF_DIR" >&2
  exit 1
fi
PROJECT_ROOT="$BLG_ROOT"; REPO_ROOT="$BLG_ROOT"
source "$BLG_ROOT/scripts/main_menu/logging.sh"
# --- end BLG root resolver ---

set -euo pipefail

INSTALLER="${INSTALLER:-$HOME/blux-lite/blux-lite_installer.sh}"   # path to your main installer
models_dir="${models_dir:-$HOME/blux-lite/models}"

CLOUD_MOUNT="${CLOUD_MOUNT:-$HOME/cloud}"          # set to your 3TB drive mount
SNAPSHOT_DIR="${SNAPSHOT_DIR:-$CLOUD_MOUNT/blux-snapshots}"
MODE_FILE="${MODE_FILE:-$HOME/blux-lite/.mode}"

ensure_dirs() { mkdir -p "$SNAPSHOT_DIR" "$models_dir"; }

current_mode() { [[ -f "$MODE_FILE" ]] && cat "$MODE_FILE" || echo "safe"; }

set_mode() {
  local m="${1:-safe}"
  echo "$m" > "$MODE_FILE"
  echo "[mode] set to: $m"
  if [[ "$m" == "safe" ]]; then
    export BLUX_MAX_TOKENS="${BLUX_MAX_TOKENS:-512}"
    export BLUX_TEMP="${BLUX_TEMP:-0.7}"
    export BLUX_THREADS="${BLUX_THREADS:-4}"
  else
    export BLUX_MAX_TOKENS="${BLUX_MAX_TOKENS:-1024}"
    export BLUX_TEMP="${BLUX_TEMP:-0.9}"
    export BLUX_THREADS="${BLUX_THREADS:-8}"
  fi
}

list_cloud_models() {
  ensure_dirs
  echo "Cloud: $CLOUD_MOUNT"
  [[ -d "$CLOUD_MOUNT" ]] || { echo "Cloud mount not found. Set CLOUD_MOUNT and mount your drive."; return 1; }
  find "$CLOUD_MOUNT" -maxdepth 3 -type f -iname "*.gguf" 2>/dev/null | sed "s|$CLOUD_MOUNT/||" | nl -w2 -s": "
}

pull_cloud_model() {
  ensure_dirs
  local rel="${1:-}"
  [[ -n "$rel" ]] || { echo "Usage: pull_cloud_model <relative_path_under_cloud>"; return 1; }
  local src="$CLOUD_MOUNT/$rel"
  [[ -f "$src" ]] || { echo "Not found: $src"; return 1; }
  echo "Copying: $src → $models_dir/"
  mkdir -p "$models_dir"; cp -v "$src" "$models_dir/"
  echo "Done."
}

snapshot_models() {
  ensure_dirs
  local ts="$(date +%Y%m%d-%H%M%S)"
  local base="models-${ts}.tar"
  echo "Snapshotting $models_dir → $SNAPSHOT_DIR/${base}.zst (or .gz)"
  if command -v zstd >/dev/null 2>&1; then
    tar -I 'zstd -19' -cf "$SNAPSHOT_DIR/${base}.zst" -C "$models_dir" . || true
    echo "Snapshot saved: $SNAPSHOT_DIR/${base}.zst"
  else
    tar -czf "$SNAPSHOT_DIR/${base}.tar.gz" -C "$models_dir" . || true
    echo "Snapshot saved: $SNAPSHOT_DIR/${base}.tar.gz"
  fi
}

run_unified_with_autosnapshot() {
  echo "Main installer: $INSTALLER"
  [[ -f "$INSTALLER" ]] || { echo "Installer not found. Set INSTALLER env to your blux-lite_installer.sh"; return 1; }
  read -r -p "Create snapshot before running unified installer? [Y/n] " ans
  if [[ -z "${ans:-}" || "$ans" =~ ^[Yy]$ ]]; then
    snapshot_models
  fi
  # delegate to installer; if it has option 28 for unified, call it, else just run it
  bash "$INSTALLER"
}

kill_switch() {
  echo "Killing runaway jobs (llama/ollama/python/node)..."
  pkill -f "llama" 2>/dev/null || true
  pkill -f "ollama" 2>/dev/null || true
  pkill -f "python .*blux" 2>/dev/null || true
  pkill -f "node .*blux" 2>/dev/null || true
  echo "Done."
}

menu() {
  while true; do
    echo ""
    echo "BLUX Cloud & Safety Add-on   [mode: $(current_mode)]"
    echo " models_dir: $models_dir"
    echo " cloud:      $CLOUD_MOUNT"
    echo ""
    echo " 1) Run unified installer (auto-snapshot prompt)"
    echo " 2) Cloud: list GGUF files"
    echo " 3) Cloud: pull GGUF from cloud"
    echo " 4) Snapshot models to cloud"
    echo " 5) Switch to SAFE mode"
    echo " 6) Switch to RED mode"
    echo " 7) Kill switch (stop runaway jobs)"
    echo " 0) Exit"
    read -r -p "> " c
    case "$c" in
      1) run_unified_with_autosnapshot ;;
      2) list_cloud_models ;;
      3) echo "Enter relative path (see 2):"; read -r rel; pull_cloud_model "$rel" ;;
      4) snapshot_models ;;
      5) set_mode safe ;;
      6) set_mode red ;;
      7) kill_switch ;;
      0) exit 0 ;;
      *) echo "?" ;;
    esac
  done
}

menu