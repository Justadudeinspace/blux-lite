#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

COMMON="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/scripts/main_menu/common.sh"
[ -f "${COMMON}" ] && . "${COMMON}" || true

# Fallbacks if common helpers aren’t available
type warn       >/dev/null 2>&1 || warn(){ printf "WARN: %s\n" "${*:-}" >&2; }
type say        >/dev/null 2>&1 || say(){  printf "%s\n" "${*:-}"; }
type BLG_BANNER >/dev/null 2>&1 || BLG_BANNER(){ printf "\n==== %s ====\n" "${*:-}"; }

REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PLUG_ROOT="${REPO_ROOT}/plugins"
LIBF_DIR="${PLUG_ROOT}/liberation_framework"

# Resolve python (prefer venv)
PYBIN=""
if [ -x "${REPO_ROOT}/.venv/bin/python" ]; then
  PYBIN="${REPO_ROOT}/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYBIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
  PYBIN="$(command -v python)"
else
  warn "No Python interpreter found (need python3)."
  exit 127
fi

BLG_BANNER "Plugins — User & .libf"

PICK(){ # fzf/gum/prompt
  local prompt="${1:-select>}"
  shift
  if command -v fzf >/dev/null 2>&1; then
    printf "%s\n" "$@" | fzf --prompt="${prompt} "
  elif command -v gum >/dev/null 2>&1; then
    gum choose "$@"
  else
    echo "$@" | nl -w2 -s') '
    local n=""
    read -rp "${prompt} " n || return 1
    sed -n "${n}p" <(printf "%s\n" "$@")
  fi
}

# Core system .libf files to hide from user lists
HIDE_LIBF=( "libf_hub.py" "libf_save.py" "libf_note.py" "libf_export.py" "project.py" )

list_libf_plugins(){
  local IFS=$'\n'
  local all=()
  [ -d "${LIBF_DIR}" ] && mapfile -t all < <(find "${LIBF_DIR}" -maxdepth 1 -type f -name "*.py" 2>/dev/null | sort) || true
  local out=()
  for p in "${all[@]:-}"; do
    local base="$(basename "$p")"
    local hide=0
    for h in "${HIDE_LIBF[@]}"; do [[ "$base" == "$h" ]] && hide=1 && break; done
    (( hide )) && continue
    out+=("$base")
  done
  ((${#out[@]})) && printf "%s\n" "${out[@]}"
}

run_libf_plugin(){
  local fname="$1"
  local slug="${fname%.py}"
  say "Running .libf plugin: ${slug}"
  local args=""; read -rp "Args (optional): " args || true
  "${PYBIN}" -m blux.cli "${slug}" ${args:-}
}

list_all_plugins(){
  local IFS=$'\n'
  local all=()
  [ -d "${PLUG_ROOT}" ] && mapfile -t all < <(find "${PLUG_ROOT}" -type f -name "*.py" 2>/dev/null | sort) || true
  local out=()
  for p in "${all[@]:-}"; do
    if [[ "$p" == "${LIBF_DIR}/"* ]]; then
      local base="$(basename "$p")"
      local hide=0
      for h in "${HIDE_LIBF[@]}"; do [[ "$base" == "$h" ]] && hide=1 && break; done
      (( hide )) && continue
    fi
    out+=("${p#${REPO_ROOT}/}")
  done
  ((${#out[@]})) && printf "%s\n" "${out[@]}"
}

run_generic_plugin(){
  local rel="$1"
  local full="${REPO_ROOT}/${rel}"
  [ -f "$full" ] || { warn "Missing: $rel"; return 1; }
  say "Running plugin by path: ${rel}"
  local args=""; read -rp "Python args (optional): " args || true
  "${PYBIN}" "${full}" ${args:-}
}

libf_memory_menu(){
  BLG_BANNER ".libf — Memory"
  local cfg="${HOME}/.config/blux-lite-gold/settings.json"
  local project="default"
  if [[ -f "$cfg" ]]; then
    project="$("${PYBIN}" - "$cfg" <<'PY'
import json, sys
with open(sys.argv[1], 'r') as f:
    p = json.load(f)
print(p.get('project', 'default'))
PY
)"
  fi
  local hist="${REPO_ROOT}/libf/projects/${project}/history/history.jsonl"
  echo "Project: ${project}"
  if [[ -f "$hist" ]]; then
    echo "--- tail: ${hist} ---"
    tail -n 40 "$hist" || true
  else
    echo "(no history found yet)"
  fi
  echo ""
  echo "  1) Open Integrated Shell"
  echo "  q) Back"
  local a=""; read -rp "Select> " a || true
  case "${a:-}" in
    1) [ -x "${REPO_ROOT}/scripts/ish.sh" ] && bash "${REPO_ROOT}/scripts/ish.sh" || warn "scripts/ish.sh not found" ;;
    q|Q) : ;;
    *) : ;;
  esac
}

print_footer() {
  local signals=(
    "Here we are."
    "For those who look, the light is already on."
    "Most will pass. A few will stay."
    "Not louder, only clearer."
    "The signal waits. The searching find."
    "The journey is the reward."
    "What you seek is seeking you."
    "The curious find their own way."
  )
  local idx=$(( $(date +%s) / 60 % ${#signals[@]} ))
  
  # ANSI color codes
  local gold='\033[0;33m'
  local nc='\033[0m' # No Color

  printf "\n${gold}(( • ))${nc}  %s\n" "${signals[$idx]}"
}
trap 'print_footer' EXIT

main_menu(){
  while true; do
    echo ""
    echo "  1) All Plugins (discover under plugins/*)"
    echo "  2) .libf Plugins (CLI-registered)"
    echo "  3) .libf Memory"
    echo "  q) Quit"
    local a=""; read -rp "Select> " a || true
    case "${a:-}" in
      1)
        local entries; entries="$(list_all_plugins || true)"
        if [[ -z "${entries// }" ]]; then
          warn "No plugins found under plugins/"
        else
          local -a choices=(); while IFS= read -r line; do choices+=("$line"); done <<< "$entries"
          local chosen; chosen="$(PICK "plugin>" "${choices[@]}")" || true
          [[ -z "${chosen:-}" ]] || run_generic_plugin "$chosen"
        fi
        ;;
      2)
        local entries; entries="$(list_libf_plugins || true)"
        if [[ -z "${entries// }" ]]; then
          warn "No .libf plugins found under plugins/liberation_framework"
        else
          local -a choices=(); while IFS= read -r line; do choices+=("$line"); done <<< "$entries"
          local chosen; chosen="$(PICK "libf>" "${choices[@]}")" || true
          [[ -z "${chosen:-}" ]] || run_libf_plugin "$chosen"
        fi
        ;;
      3) libf_memory_menu ;;
      q|Q) exit 0 ;;
      *) warn "Unknown selection" ;;
    esac
  done
}

main_menu "$@"