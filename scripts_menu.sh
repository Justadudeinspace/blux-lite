#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
COMMON="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/scripts/main_menu/common.sh"
[ -f "${COMMON}" ] && . "${COMMON}"

BLG_BANNER "BLUX Lite GOLD — Legacy Menu"

REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPTS_ROOT="${REPO_ROOT}/scripts"

PICK(){ # fzf/gum/prompt
  local prompt="${1:-select>}"
  shift
  if command -v fzf >/dev/null 2>&1; then
    printf "%s\n" "$@" | fzf --prompt="${prompt} "
  elif command -v gum >/dev/null 2>&1; then
    gum choose "$@"
  else
    echo "$@" | nl -w2 -s') '
    read -rp "${prompt} " n
    sed -n "${n}p" <(printf "%s\n" "$@")
  fi
}

EXCLUDE_PATTERNS=( "/main_menu/" "/tui/" "/lib/" )
EXCLUDE_FILES=( "first_start.sh" "blux-lite.sh" "scripts_menu.sh" "auto-start.sh" "ish.sh" )

list_user_scripts(){
  local IFS=$'\n'
  local all
  mapfile -t all < <(find "${SCRIPTS_ROOT}" -type f -name "*.sh" | sort)
  local out=()
  for p in "${all[@]}"; do
    local rel="${p#${SCRIPTS_ROOT}/}"
    local skip=0
    for pat in "${EXCLUDE_PATTERNS[@]}"; do [[ "$rel" == *"$pat"* ]] && skip=1 && break; done
    for f in "${EXCLUDE_FILES[@]}"; do [[ "$rel" == "$f" ]] && skip=1 && break; done
    [[ $skip -eq 1 ]] && continue
    out+=("$rel")
  done
  printf "%s\n" "${out[@]}"
}

run_user_scripts_menu(){
  BLG_BANNER "User Scripts"
  local entries; entries="$(list_user_scripts)"
  if [[ -z "${entries// }" ]]; then
    warn "No user scripts found under scripts/"
    return 0
  fi
  local chosen; chosen="$(PICK "script>" ${entries})" || true
  [[ -z "${chosen:-}" ]] && return 0
  say "Running scripts/${chosen}"
  bash "${SCRIPTS_ROOT}/${chosen}"
}

if [[ "${1-}" == "user" ]]; then
  run_user_scripts_menu; exit 0
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
  read -rp "Select> " ans || true
  case "${ans:-}" in
    1) bash "${REPO_ROOT}/scripts/main_menu/install_deps.sh" ;;
    2) python -m blux.catalog_install models ;;
    3) read -rp "Model id: " mid ; python -m blux.catalog_install apply "$mid" ;;
    4) bash "${REPO_ROOT}/scripts/main_menu/doctor.sh" ;;
    5) bash "${REPO_ROOT}/scripts/main_menu/logs.sh" ;;
    6) bash "${REPO_ROOT}/scripts/tui/menu.sh" ;;
    7) run_user_scripts_menu ;;
    8) bash "${REPO_ROOT}/plugin_menu.sh" ;;
    q|Q) exit 0 ;;
    *) warn "Unknown selection" ;;
  esac
done
