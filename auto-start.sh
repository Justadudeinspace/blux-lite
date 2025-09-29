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
