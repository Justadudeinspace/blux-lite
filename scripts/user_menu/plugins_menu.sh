#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
COMMON="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/main_menu/common.sh"
. "${COMMON}" || true

BLG_BANNER "User Plugins (.libf)"

PLUG_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)/plugins/liberation_framework"
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

# System plugins to hide
HIDE=(
  "libf_hub.py"
  "libf_save.py"
  "libf_note.py"
  "libf_export.py"
  "project.py"
)

list_user_plugins(){
  local IFS=$'\n'
  local all
  mapfile -t all < <(find "${PLUG_ROOT}" -maxdepth 1 -type f -name "*.py" | sort)
  local out=()
  for p in "${all[@]}"; do
    local base="$(basename "$p")"
    local hide=0
    for h in "${HIDE[@]}"; do [[ "$base" == "$h" ]] && hide=1 && break; done
    [[ $hide -eq 1 ]] && continue
    out+=("$base")
  done
  printf "%s\n" "${out[@]}"
}

run_plugin(){
  local fname="$1"
  local slug="${fname%.py}"
  say "Running plugin command: ${slug}"
  read -rp "Args (optional): " args || true
  # Dispatch via Typer CLI (blux/cli.py must register .libf plugins)
  python -m blux.cli "${slug}" ${args:-}
}

list_and_run(){
  local entries; entries="$(list_user_plugins)"
  if [[ -z "${entries// }" ]]; then
    warn "No user plugins found in plugins/liberation_framework"
    return 0
  fi
  local chosen; chosen="$(PICK "plugin>" ${entries})" || true
  [[ -z "${chosen:-}" ]] && return 0
  run_plugin "$chosen"
}

case "${1-}" in
  list) list_user_plugins ;;
  run|"") list_and_run ;;
esac
