#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

say(){ printf '[BLG] %s\n' "${*:-}"; }
warn(){ printf '[WARN] %s\n' "${*:-}" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }
is_macos(){ [ "$(uname -s)" = "Darwin" ]; }
is_arch(){ have pacman; }
is_debian(){ have apt-get || have apt; }
is_fedora(){ have dnf || have yum; }
is_suse(){ have zypper; }
is_alpine(){ have apk; }

PROJECT_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")/.." && pwd -P)"

say "Phase 1/2: Install base dependencies"
if is_termux; then
  pkg update -y && pkg upgrade -y
  pkg install -y git python python-pip curl nano jq proot-distro termux-api
  termux-setup-storage || true
elif is_macos; then
  have brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git python3 curl jq || true
elif is_arch; then
  sudo pacman -Sy --noconfirm git python python-pip curl jq || true
elif is_debian; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-venv python3-pip curl jq || true
elif is_fedora; then
  sudo dnf install -y git python3 python3-pip curl jq || true
elif is_suse; then
  sudo zypper install -y git python3 python3-pip curl jq || true
elif is_alpine; then
  sudo apk add --no-cache git python3 py3-pip curl jq || true
else
  warn "Unknown platform. Please install git, python3(+venv/pip), curl, jq manually."
fi

say "Phase 2/2: Run project bootstrap"
cd "$PROJECT_ROOT"
chmod +x first_start.sh
./first_start.sh