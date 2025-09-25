#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
COMMON="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/scripts/main_menu/common.sh"
[ -f "${COMMON}" ] && . "${COMMON}"

BLG_BANNER "Plugins — User & .libf"

REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PLUG_ROOT="${REPO_ROOT}/plugins"
LIBF_DIR="${PLUG_ROOT}/liberation_framework"

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

# Core system .libf files to hide from user lists
HIDE_LIBF=( "libf_hub.py" "libf_save.py" "libf_note.py" "libf_export.py" "project.py" )

list_libf_plugins(){
  local IFS=$'\n'
  local all
  mapfile -t all < <(find "${LIBF_DIR}" -maxdepth 1 -type f -name "*.py" 2>/dev/null | sort || true)
  local out=()
  for p in "${all[@]}"; do
    local base="$(basename "$p")"
    local hide=0
    for h in "${HIDE_LIBF[@]}"; do [[ "$base" == "$h" ]] && hide=1 && break; done
    [[ $hide -eq 1 ]] && continue
    out+=("$base")
  done
  printf "%s\n" "${out[@]}"
}

run_libf_plugin(){
  local fname="$1"
  local slug="${fname%.py}"
  say "Running .libf plugin: ${slug}"
  read -rp "Args (optional): " args || true
  python -m blux.cli "${slug}" ${args:-}
}

list_all_plugins(){
  local IFS=$'\n'
  local all
  mapfile -t all < <(find "${PLUG_ROOT}" -type f -name "*.py" 2>/dev/null | sort || true)
  local out=()
  for p in "${all[@]}"; do
    # Skip system .libf entries
    if [[ "$p" == "${LIBF_DIR}/"* ]]; then
      local base="$(basename "$p")"
      local hide=0
      for h in "${HIDE_LIBF[@]}"; do [[ "$base" == "$h" ]] && hide=1 && break; done
      [[ $hide -eq 1 ]] && continue
    fi
    out+=("${p#${REPO_ROOT}/}")
  done
  printf "%s\n" "${out[@]}"
}

run_generic_plugin(){
  local rel="$1"
  local full="${REPO_ROOT}/${rel}"
  say "Running plugin by path: ${rel}"
  read -rp "Python args (optional): " args || true
  python "${full}" ${args:-}
}

libf_memory_menu(){
  BLG_BANNER ".libf — Memory"
  local cfg="${REPO_ROOT}/.config/blux-lite-gold/settings.json"
  local project="default"
  if [[ -f "$cfg" ]]; then
    project="$(python - <<'PY'\nimport json,sys\np=json.load(open(sys.argv[1]))\nprint(p.get('project','default'))\nPY\n"$cfg")"
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
  read -rp "Select> " a || true
  case "${a:-}" in
    1) bash "${REPO_ROOT}/scripts/ish.sh" ;;
    q|Q) : ;;
    *) : ;;
  esac
}

main_menu(){
  while true; do
    echo ""
    echo "  1) All Plugins (discover under plugins/*)"
    echo "  2) .libf Plugins (CLI-registered)"
    echo "  3) .libf Memory"
    echo "  q) Quit"
    read -rp "Select> " a || true
    case "${a:-}" in
      1)
        local entries; entries="$(list_all_plugins)"
        if [[ -z "${entries// }" ]]; then
          warn "No plugins found under plugins/"
        else
          local chosen; chosen="$(PICK "plugin>" ${entries})" || true
          [[ -z "${chosen:-}" ]] || run_generic_plugin "$chosen"
        fi
        ;;
      2)
        local entries; entries="$(list_libf_plugins)"
        if [[ -z "${entries// }" ]]; then
          warn "No .libf plugins found under plugins/liberation_framework"
        else
          local chosen; chosen="$(PICK "libf>" ${entries})" || true
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
