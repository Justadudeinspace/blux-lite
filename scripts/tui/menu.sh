#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
COMMON="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/main_menu/common.sh"
. "${COMMON}"

MENU_TITLE="BLUX Lite GOLD — TUI"
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

action_install_deps(){ bash "$(dirname "${COMMON}")/install_deps.sh"; }
action_catalogs(){ python -m blux.catalog_install models || true; }
action_catalog_picker(){ 
  # Reuse earlier hook if present
  if declare -f catalogs_install_picker >/dev/null 2>&1; then catalogs_install_picker; return; fi
  local ids; ids="$(python -m blux.catalog_install models | awk '{print $1}')" || return 0
  local chosen; chosen="$(PICK model> ${ids})" || true
  [ -z "${chosen:-}" ] && return 0
  python -m blux.catalog_install plan "$chosen"
  read -rp "Apply? [y/N]: " yn; case "${yn:-n}" in y|Y) python -m blux.catalog_install apply "$chosen";; esac
}
action_doctor(){ bash "$(dirname "${COMMON}")/doctor.sh"; }
action_logs(){ bash "$(dirname "${COMMON}")/logs.sh"; }
action_exit(){ exit 0; }

main(){
  BLG_BANNER "${MENU_TITLE}"
  while true; do
    echo ""
    echo "  1) Install Dependencies"
    echo "  2) Catalogs — List Models"
    echo "  3) Catalogs — Install (picker)"
    echo "  4) System Doctor"
    echo "  5) View Logs"
    echo "  6) Integrated Shell"
    echo "  7) User Scripts"
    echo "  8) User Plugins"\n    echo "  6) Integrated Shell"
    echo "  q) Quit"
    read -rp "Select> " a || true
    case "${a:-}" in
      1) action_install_deps ;;
      2) action_catalogs ;;
      3) action_catalog_picker ;;
      4) action_doctor ;;
      5) action_logs ;;
      6) bash "$(dirname "${COMMON}")/../ish.sh" ;;
      7) bash "$(dirname "${COMMON}")/../..//scripts_menu.sh user" ;;
      8) bash "$(dirname "${COMMON}")/../..//plugin_menu.sh" ;;
      q|Q) action_exit ;;
      *) warn "Unknown selection" ;;
    esac
  done
}

if [ "${1-}" = "catalogs_install_picker" ]; then
  action_catalog_picker
else
  main "$@"
fi
