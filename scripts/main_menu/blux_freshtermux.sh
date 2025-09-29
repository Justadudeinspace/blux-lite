#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# blux_freshtermux.sh - one-click Termux bootstrap for dev friendly env
# Generated: 2025-08-19 07:25:18

pkg update -y || true
pkg upgrade -y || true
pkg install -y git curl --silent --location --fail wget tar unzip jq fzf dialog whiptail bat eza duf htop btop ripgrep fd procs openssh python python-pip || true
echo "[OK] Fresh Termux setup attempted."
