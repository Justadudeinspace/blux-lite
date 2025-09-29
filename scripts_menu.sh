#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Try to load shared helpers; fall back if unavailable
COMMON="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/scripts/main_menu/common.sh"
[ -f "${COMMON}" ] && . "${COMMON}" || true
type warn >/dev/null 2>&1 || warn(){ printf "WARN: %s\n" "${*:-}" >&2; }
type say  >/dev/null 2>&1 || say(){  printf "%s\n" "${*:-}"; }
type BLG_BANNER >/dev/null 2>&1 || BLG_BANNER(){ printf "\n==== %s ====\n" "${*:-}"; }

# Resolve repo + scripts roots
REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPTS_ROOT="${REPO_ROOT}/scripts"

# Pick a python interpreter (venv > python3 > python)
PYBIN=""
if [ -x "${REPO_ROOT}/.venv/bin/python" ]; then
  PYBIN="${REPO_ROOT}/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYBIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
  PYBIN="$(command -v python)"
else
  warn "No python interpreter found (need python3)."
  exit 127
fi

BLG_BANNER "BLUX Lite GOLD — Legacy Menu"

# Cross-platform menu picker (fzf > gum > POSIX)
PICK(){ # fzf/gum/prompt
  local prompt="${1:-select>}"
  shift
  if command -v fzf >/dev/null 2>&1; then
    printf "%s\n" "$@" | fzf --prompt="${prompt} "
  elif command -v gum >/dev/null 2>&1; then
    gum choose "$@"
  else
    # POSIX-ish fallback
    echo "$@" | nl -w2 -s') '
    # Avoid exiting on Ctrl-D under set -e
    local n=""
    read -r -p "${prompt} " n || n=""
    [ -z "${n}" ] && return 1
    sed -n "${n}p" <(printf "%s\n" "$@")
  fi
}

EXCLUDE_PATTERNS=( "main_menu/" "tui/" "lib/" )
EXCLUDE_FILES=( "first_start.sh" "blux-lite.sh" "scripts_menu.sh" "auto-start.sh" "ish.sh" )

list_user_scripts(){
  local IFS=$'\n'
  [ -d "${SCRIPTS_ROOT}" ] || { warn "scripts/ not found"; return 0; }
  local all
  mapfile -t all < <(find "${SCRIPTS_ROOT}" -type f -name "*.sh" | sort)
  local out=()
  for p in "${all[@]:-}"; do
    local rel="${p#${SCRIPTS_ROOT}/}"
    local skip=0
    for pat in "${EXCLUDE_PATTERNS[@]}"; do [[ "$rel" == *"$pat"* ]] && skip=1 && break; done
    for f in "${EXCLUDE_FILES[@]}";   do [[ "$rel" == "$f"   ]] && skip=1 && break; done
    [[ $skip -eq 1 ]] && continue
    out+=("$rel")
  done
  ((${#out[@]})) && printf "%s\n" "${out[@]}"
}

run_user_scripts_menu(){
  BLG_BANNER "User Scripts"
  local entries; entries="$(list_user_scripts || true)"
  if [[ -z "${entries// }" ]]; then
    warn "No user scripts found under scripts/"
    return 0
  fi
  local -a choices=()
  while IFS= read -r line; do choices+=("$line"); done <<< "$entries"
  local chosen; chosen="$(PICK "script>" "${choices[@]}")" || true
  [[ -z "${chosen:-}" ]] && return 0
  say "Running scripts/${chosen}"
  bash "${SCRIPTS_ROOT}/${chosen}"
}

print_footer() {
  local signals=("Here we are." "For those who look, the light is already on." "Most will pass. A few will stay." "Not louder, only clearer." "The signal waits. The searching find.")
  local idx=$(( $(date +%s) / 60 % ${#signals[@]} ))
  printf "\n(( • ))  %s\n" "${signals[$idx]}"
}

if [[ "${1-}" == "user" ]]; then
  run_user_scripts_menu
  print_footer
  exit 0
fi

while true; do
  echo ""
  echo "  1) Install Dependencies"
  echo "  2) Catalogs — List Models"
  echo "  3) Catalogs — Install (prompt)"
  echo "  4) System Doctor"
  echo "  5) View Logs"
  echo "  6) Launch TUI"
  echo "  7) User Scripts"
  echo "  8) User Plugins"
  echo "  q) Quit"
  read -r -p "Select> " ans || ans=""
  case "${ans:-}" in
    1) bash "${REPO_ROOT}/scripts/main_menu/install_deps.sh" ;;
    2) "${PYBIN}" -m blux.catalog_install models ;;
    3) read -r -p "Model id: " mid || mid="" ; [ -n "${mid}" ] && "${PYBIN}" -m blux.catalog_install apply "$mid" ;;
    4) bash "${REPO_ROOT}/scripts/main_menu/doctor.sh" ;;
    5) bash "${REPO_ROOT}/scripts/main_menu/logs.sh" ;;
    6) "${PYBIN}" -m blux.tui_blg ;;
    7) run_user_scripts_menu ;;
    8) bash "${REPO_ROOT}/plugin_menu.sh" ;;
    q|Q) print_footer; exit 0 ;;
    *) warn "Unknown selection" ;;
  esac
done