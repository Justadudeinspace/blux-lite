#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
COMMON="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/main_menu/common.sh"
. "${COMMON}" || true

BLG_BANNER "User Scripts"

SCRIPTS_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
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

# Patterns to exclude (system scripts)
EXCLUDE_PATTERNS=(
  "/main_menu/"
  "/tui/"
  "/lib/"
)
EXCLUDE_FILES=(
  "first_start.sh"
  "blux-lite.sh"
  "scripts_menu.sh"
  "auto-start.sh"
  "ish.sh"
)

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

list_and_run(){
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

case "${1-}" in
  list) list_user_scripts ;;
  run|"") list_and_run ;;
esac
