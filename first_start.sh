#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# --- helpers ---
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT
say()  { printf '[BLG] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---- environment detection ----
is_termux() { case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac; }
is_macos()  { [ "$(uname -s)" = "Darwin" ] && return 0 || return 1; }
is_arch()   { have pacman   && return 0 || return 1; }
is_debian() { ( have apt-get || have apt ) && return 0 || return 1; }
is_fedora() { ( have dnf || have yum ) && return 0 || return 1; }
is_suse()   { have zypper   && return 0 || return 1; }
is_alpine() { have apk      && return 0 || return 1; }

need_sudo() { ! is_termux && ! is_macos && [ "$(id -u)" -ne 0 ]; }

# ---- args ----
WITH_ML=1; FORCE_CPU=0; MINIMAL=0; DO_LAUNCH=0
while [ $# -gt 0 ]; do
  case "$1" in
    --no-ml)     WITH_ML=0 ;;
    --force-cpu) FORCE_CPU=1 ;;
    --minimal)   MINIMAL=1 ;;
    --launch)    DO_LAUNCH=1 ;;
    --debug)     export BLG_DEBUG=1; set -x ;;
    *) warn "Unknown arg $1" ;;
  esac
  shift
done

say "Phase 1/5: Environment check"
PROJECT_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"

# ---- deps ----
say "Phase 2/5: Install dependencies"
if is_termux; then
  pkg update -y
  pkg install -y git python python-pip wget curl proot tar unzip jq || true
elif is_macos; then
  have brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git python3 wget curl || true
elif is_arch; then
  sudo pacman -Sy --noconfirm git python python-pip wget curl || true
elif is_debian; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-pip python3-venv wget curl jq || true
elif is_fedora; then
  if have dnf; then
    sudo dnf install -y git python3 python3-pip wget curl || true
  else
    sudo yum install -y git python3 python3-pip wget curl || true
  fi
elif is_suse; then
  sudo zypper install -y git python3 python3-pip wget curl || true
elif is_alpine; then
  sudo apk add --no-cache git python3 py3-pip wget curl || true
else
  warn "Unknown distro; install git python3 pip wget curl manually."
fi

# ---- python resolver ----
detect_python() {
  if [ -x "${PROJECT_ROOT}/.venv/bin/python" ]; then
    printf '%s\n' "${PROJECT_ROOT}/.venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    printf '%s\n' ""
  fi
}
PYBIN="$(detect_python)"
if [ -z "${PYBIN}" ]; then
  warn "No Python interpreter found (need python3)."
  exit 127
fi

# ---- venv ----
say "Phase 3/5: Python venv"
VENV_DIR="${PROJECT_ROOT}/.venv"
if [ ! -d "$VENV_DIR" ]; then
  # Try with python3, then fallback to python if needed
  if command -v python3 >/dev/null 2>&1; then
    python3 -m venv "$VENV_DIR" || true
  fi
  if [ ! -d "$VENV_DIR" ] && command -v python >/dev/null 2>&1; then
    python -m venv "$VENV_DIR" || true
  fi
fi

# shellcheck disable=SC1091
if [ -x "$VENV_DIR/bin/activate" ]; then
  # Activate venv and re-detect python to prefer venv python
  . "$VENV_DIR/bin/activate"
  PYBIN="${PROJECT_ROOT}/.venv/bin/python"
fi

"$PYBIN" -m pip install --upgrade pip wheel setuptools

REQ="${PROJECT_ROOT}/requirements.txt"
[ -f "$REQ" ] && "$PYBIN" -m pip install -r "$REQ"

# ensure tui deps unless minimal
UI_DEFAULT="legacy"
if [ "$MINIMAL" -eq 0 ]; then
  if ! "$PYBIN" -c "import textual" >/dev/null 2>&1; then
    say "Installing TUI deps (textual, rich)"
    "$PYBIN" -m pip install "textual==0.79.1" "rich==13.7.1" || warn "TUI deps failed; legacy will be used."
  fi
fi
"$PYBIN" -c "import textual" >/dev/null 2>&1 && UI_DEFAULT="tui" || UI_DEFAULT="legacy"

# ---- perms ----
say "Phase 4/5: Permissions"
make_x(){ [ -f "$1" ] && chmod +x "$1" && echo "[OK] $1" || true; }

# Core launchers
for f in \
  "${PROJECT_ROOT}/scripts_menu.sh" \
  "${PROJECT_ROOT}/plugin_menu.sh" \
  "${PROJECT_ROOT}/blux-lite.sh" \
  "${PROJECT_ROOT}/blux.py" \
  "${PROJECT_ROOT}/first_start.sh"
do make_x "$f"; done

# Executable bits for scripts tree
find "$PROJECT_ROOT/scripts" -type f -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
# TUI wrappers (*.tui.sh)
[ -d "$PROJECT_ROOT/scripts/tui" ] && find "$PROJECT_ROOT/scripts/tui" -type f -name '*.tui.sh' -exec chmod +x {} \; 2>/dev/null || true
# Make selected python helpers executable
for d in scripts plugins examples shim; do
  [ -d "$PROJECT_ROOT/$d" ] && find "$PROJECT_ROOT/$d" -type f -name '*.py' -exec chmod +x {} \; 2>/dev/null || true
done

# Directory perms (skip venv/.git/__pycache__)
find "$PROJECT_ROOT" \( -path "$PROJECT_ROOT/.venv" -o -path "$PROJECT_ROOT/.git" -o -name __pycache__ \) -prune -o -type d -exec chmod 755 {} \; 2>/dev/null || true

# ---- post-setup ----
say "Phase 5/5: Post-setup"
# fzf env lives under scripts/main_menu in this repo
[ -f "$PROJECT_ROOT/scripts/main_menu/fzf_env.sh" ] && . "$PROJECT_ROOT/scripts/main_menu/fzf_env.sh" || true
command -v fzf >/dev/null || warn "fzf not installed; shell menus will still work but without fuzzy picker."

emit_auto_start() {
  local auto="$PROJECT_ROOT/auto-start.sh"
  local config_dir="$PROJECT_ROOT/.config/blux-lite-gold"
  local profile="$config_dir/auto-start.json"

  mkdir -p "$config_dir"

  # Ask the user explicitly for UI choice
  CH="legacy"
  if command -v whiptail >/dev/null 2>&1; then
    CH=$(whiptail --title "BLUX Lite GOLD" --menu "Choose interface" 15 60 2 \
      "tui" "Textual/Terminal UI" \
      "legacy" "Classic shell menus" 3>&1 1>&2 2>&3) || CH="$UI_DEFAULT"
  else
    printf "Choose interface [tui/legacy] (default %s): " "$UI_DEFAULT"
    read -r CH || CH="$UI_DEFAULT"
  fi
  UI_DEFAULT="${CH:-$UI_DEFAULT}"

  # Logging + debugging always on
  LOGGING_ON=1
  DEBUG_ON=1

  # Write JSON profile (repo-local per current tree)
  printf '%s\n' '{' \
    '  "platform": "auto",' \
    '  "with_ml": '"$WITH_ML"',' \
    '  "force_cpu": '"$FORCE_CPU"',' \
    '  "minimal": '"$MINIMAL"',' \
    '  "venv": ".venv",' \
    '  "ml_mode": "auto",' \
    '  "ui": "'"$UI_DEFAULT"'",' \
    '  "logging": '"$LOGGING_ON"', ' \
    '  "debug": '"$DEBUG_ON"', ' \
    '  "generated_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' \
    '}' > "$profile"

  # Write runtime.env for shell + python
  cat > "$config_dir/runtime.env" <<'ENV'
# BLUX runtime toggles
BLG_DEBUG=1
BLG_LOG=1
BLUX_LOG_LEVEL=DEBUG
PYTHONUNBUFFERED=1
ENV

  # Generate auto-start.sh launcher (self-resolving Python)
  cat > "$auto" <<'BASH'
#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'
BLG_SELF_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"
PROJECT_ROOT="$BLG_SELF_DIR"
VENV_DIR="$PROJECT_ROOT/.venv"
[ -d "$VENV_DIR" ] && [ -x "$VENV_DIR/bin/activate" ] && . "$VENV_DIR/bin/activate"

# Load runtime env
RUNTIME_ENV="$PROJECT_ROOT/.config/blux-lite-gold/runtime.env"
[ -f "$RUNTIME_ENV" ] && set -a && . "$RUNTIME_ENV" && set +a

# Pick python (venv > python3 > python)
if [ -x "$PROJECT_ROOT/.venv/bin/python" ]; then
  PYBIN="$PROJECT_ROOT/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYBIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
  PYBIN="$(command -v python)"
else
  printf 'WARN: %s\n' "No Python interpreter found (need python3)." >&2
  exit 127
fi

# Normalize args, allow --debug to enable xtrace
ARGS=(); for arg in "$@"; do case "$arg" in --debug) export BLG_DEBUG=1; set -x ;; *) ARGS+=("$arg");; esac; done
set -- "${ARGS[@]}"

PROFILE_JSON="$PROJECT_ROOT/.config/blux-lite-gold/auto-start.json"
UI_DEFAULT="tui"
if command -v jq >/dev/null 2>&1 && [ -f "$PROFILE_JSON" ]; then
  UI_DEFAULT="$(jq -r '.ui // "tui"' "$PROFILE_JSON" 2>/dev/null || echo tui)"
fi

MODE="${1:-${BLG_UI:-$UI_DEFAULT}}"; [ $# -gt 0 ] && shift || true
"$PYBIN" -m blux.cli --help >/dev/null 2>&1 || "$PYBIN" -c "import textual" >/dev/null 2>&1 || MODE="legacy"

case "$MODE" in
  tui|menu|tui_blg|"") exec "$PYBIN" -m blux.tui_blg "$@";;
  start) if "$PYBIN" -m blux.cli --help >/dev/null 2>&1; then exec "$PYBIN" -m blux.cli "$@"; else exec "$PYBIN" -m blux.tui_blg "$@"; fi;;
  legacy|legacy-menu) exec "$PROJECT_ROOT/blux-lite.sh" "$@";;
  *) if "$PYBIN" -m blux.cli --help >/dev/null 2>&1; then exec "$PYBIN" -m blux.cli start --mode "$MODE" "$@"; else exec "$PYBIN" -m blux.tui_blg "$@"; fi;;
esac
BASH

  chmod +x "$auto"
  say "[OK] profile + launcher emitted"
}

emit_auto_start

say "Done ✅ — launching now..."
exec "$PROJECT_ROOT/auto-start.sh" "$UI_DEFAULT" --debug