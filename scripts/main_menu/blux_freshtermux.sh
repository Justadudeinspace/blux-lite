#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# blux_freshtermux.sh - one-click Termux bootstrap for dev friendly env
# Generated: 2025-08-19 07:25:18
set -Eeuo pipefail
IFS=$'\n\t'
pkg update -y || true
pkg upgrade -y || true
pkg install -y git curl --silent --location --fail wget tar unzip jq fzf dialog whiptail bat eza duf htop btop ripgrep fd procs openssh python python-pip || true
echo "[OK] Fresh Termux setup attempted."