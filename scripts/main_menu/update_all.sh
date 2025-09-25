#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# update_all.sh - update Termux pkgs + common Python CLIs
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
command -v pkg >/dev/null 2>&1 && pkg update -y || true
command -v pkg >/dev/null 2>&1 && pkg upgrade -y || true
command -v pip >/dev/null 2>&1 && pip install --upgrade pip || true
command -v pip >/dev/null 2>&1 && pip install --upgrade 'huggingface_hub[cli]' || true
echo "[OK] Updates attempted."