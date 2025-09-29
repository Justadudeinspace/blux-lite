#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

say(){  printf '[BLUX] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

is_termux(){ case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }
is_macos(){ [ "$(uname -s)" = "Darwin" ] && return 0 || return 1; }
is_arch(){ have pacman && return 0 || return 1; }
is_debian(){ ( have apt-get || have apt ) && return 0 || return 1; }
is_fedora(){ ( have dnf || have yum ) && return 0 || return 1; }
is_suse(){ have zypper && return 0 || return 1; }
is_alpine(){ have apk && return 0 || return 1; }

say "== System package updates =="
if is_termux; then
  pkg update -y || true
  pkg upgrade -y || true
elif is_macos; then
  if have brew; then brew update || true; brew upgrade || true; else warn "brew not found"; fi
elif is_arch; then
  sudo pacman -Syu --noconfirm || true
elif is_debian; then
  sudo apt-get update -y || true
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y || true
elif is_fedora; then
  if have dnf; then sudo dnf upgrade -y || true; else sudo yum update -y || true; fi
elif is_suse; then
  sudo zypper refresh || true
  sudo zypper update -y || true
elif is_alpine; then
  sudo apk update || true
  sudo apk upgrade || true
else
  warn "Unknown platform; skipping system updates."
fi

say "== Python tool updates =="
detect_python() {
  local root; root="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  if [ -x "$root/.venv/bin/python" ]; then
    printf '%s\n' "$root/.venv/bin/python"
  elif have python3; then
    command -v python3
  elif have python; then
    command -v python
  else
    printf '%s\n' ""
  fi
}
PYBIN="$(detect_python)"
if [ -n "${PYBIN}" ]; then
  "$PYBIN" -m pip install --upgrade pip setuptools wheel || true
  "$PYBIN" -m pip install --upgrade 'huggingface_hub[cli]' || true
else
  warn "No Python interpreter found; skipping pip upgrades."
fi

if have pipx; then pipx upgrade-all || true; fi
say "[OK] Updates attempted."
