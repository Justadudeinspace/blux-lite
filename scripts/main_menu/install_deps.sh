#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
. "$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"

BLG_BANNER "Install Dependencies"

packages_common=(git curl python3 pip fzf shellcheck)
packages_optional=(gum shellcheck)

if is_termux; then
  say "Detected Termux"
  pkg update -y
  pkg install -y "${packages_common[@]}"
  pkg install -y "${packages_optional[@]}"
elif is_macos; then
  say "Detected macOS"
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew update
  brew install git curl python fzf
  brew install gum
elif is_linux; then
  say "Detected Linux"
  if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y git curl python3 python3-pip fzf
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y git curl python3 python3-pip fzf
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu --noconfirm git curl python python-pip fzf
  fi
  # gum (optional)
  if ! command -v gum >/dev/null 2>&1; then
    curl -fsSL https://github.com/charmbracelet/gum/releases/latest/download/gum_$(uname -s | tr '[:upper:]' '[:lower:]')_amd64.tar.gz | tar -xz
    sudo mv gum /usr/local/bin/ 2>/dev/null
  fi
else
  warn "Unknown OS; install dependencies manually."
fi

say "Python venv"
python3 -m venv "${REPO_ROOT}/.venv"
. "${REPO_ROOT}/.venv/bin/activate"
python -m pip install --upgrade pip

say "Done."
