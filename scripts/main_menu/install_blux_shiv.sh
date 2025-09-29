#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
# scripts/install_blux_shiv.sh — build & install a shiv binary so users can run `blux`
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
APP_NAME="blux"

say(){ printf "%b\n" "$*"; }
err(){ say "\033[31m[ERR]\033[0m $*"; }
ok(){ say "\033[32m[OK]\033[0m $*"; }
warn(){ say "\033[33m[WARN]\033[0m $*"; }

have(){ command -v "$1" >/dev/null 2>&1; }

# Ensure python and pip
if ! have python3; then
  err "python3 is required"; exit 1
fi
if ! have pip3 && ! python3 -m pip --version >/dev/null 2>&1; then
  err "pip is required for python3"; exit 1
fi

# Install shiv tool
if ! python3 -m shiv --help >/dev/null 2>&1 && ! command -v shiv >/dev/null 2>&1; then
  say "[INFO] Installing 'shiv' (zipapp packager) for current user..."
  python3 -m pip install --user --upgrade shiv || { err "Failed to install shiv"; exit 1; }
fi

# Ensure console entry exists: pyproject.toml should define [project.scripts] blux = "shiv.cli:main"
if ! grep -qE '^\s*blux\s*=\s*"shiv\.cli:main"' "${REPO_ROOT}/pyproject.toml" 2>/dev/null; then
  warn "pyproject.toml missing console_scripts 'blux = \"shiv.cli:main\"'. The build may fail."
fi

mkdir -p "${BIN_DIR}"

# Build a single-file executable directly to ~/.local/bin/blux
# -p '/usr/bin/env python3' writes an env shebang so it's runnable
say "[INFO] Building shiv app → ${BIN_DIR}/${APP_NAME}"
python3 -m shiv -p '/usr/bin/env python3' -c blux -o "${BIN_DIR}/${APP_NAME}" "${REPO_ROOT}" || {
  # Fallback: build a .pyz then move it
  warn "Direct build failed; trying fallback to blux.pyz then moving"
  python3 -m shiv -p '/usr/bin/env python3' -c blux -o "${REPO_ROOT}/blux.pyz" "${REPO_ROOT}" || { err "Shiv build failed"; exit 1; }
  mv -f "${REPO_ROOT}/blux.pyz" "${BIN_DIR}/${APP_NAME}"
}

chmod +x "${BIN_DIR}/${APP_NAME}"

# PATH hint
if ! echo ":$PATH:" | grep -q ":${BIN_DIR}:"; then
  warn "${BIN_DIR} is not in your PATH. Add the following to your shell rc:"
  say '  export PATH="$HOME/.local/bin:$PATH"'
fi

ok "Installed '${APP_NAME}' to ${BIN_DIR}/${APP_NAME}"
say "Try: blux --help"