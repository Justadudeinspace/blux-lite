#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

say(){ printf '[BLUX] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }
is_macos(){ [ "$(uname -s)" = "Darwin" ] && return 0 || return 1; }
is_arch(){ have pacman && return 0 || return 1; }
is_debian(){ ( have apt-get || have apt ) && return 0 || return 1; }
is_fedora(){ ( have dnf || have yum ) && return 0 || return 1; }
is_suse(){ have zypper && return 0 || return 1; }
is_alpine(){ have apk && return 0 || return 1; }

say "== Install Dependencies =="

if is_termux; then
  say "Detected Termux"
  pkg update -y
  pkg install -y git python python-pip wget curl proot tar unzip jq

elif is_macos; then
  say "Detected macOS"
  have brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git python3 wget curl jq

elif is_arch; then
  say "Detected Arch Linux"
  sudo pacman -Sy --noconfirm git python python-pip wget curl jq

elif is_debian; then
  say "Detected Debian/Ubuntu"
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-pip python3-venv wget curl jq

elif is_fedora; then
  say "Detected Fedora"
  if have dnf;
    sudo dnf install -y git python3 python3-pip wget curl jq
  else
    sudo yum install -y git python3 python3-pip wget curl jq
  fi

elif is_suse; then
  say "Detected openSUSE"
  sudo zypper install -y git python3 python3-pip wget curl jq

elif is_alpine; then
  say "Detected Alpine"
  sudo apk add --no-cache git python3 py3-pip wget curl jq

else
  warn "Unknown distro; please install git, python3(+pip/venv), wget, curl, jq manually."
fi

say "== Dependencies installed =="
