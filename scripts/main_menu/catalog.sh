#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
set -Eeuo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/env.sh"

CATALOG="$ROOT_DIR/docs/catalog.json"

_need_jq() { command -v jq >/dev/null 2>&1 || { echo "[!] 'jq' required"; return 1; }; }
_catalog_ok() { [[ -f "$CATALOG" ]] || { echo "[!] Missing $CATALOG"; return 1; }; }

_list_by_tag() {
  local tag="${1:-general}" engine="${2:-gguf}"
  _need_jq || return 1; _catalog_ok || return 1
  jq -r --arg tag "$tag" --arg engine "$engine" '
    .[$engine] // [] | map(select(.tags and (.tags | index($tag)))) |
    to_entries | .[] | "\(.key+1). \(.value.label)  [" + (.value.id // "no-id") + "]"
  ' "$CATALOG"
}

_json_by_index() {
  local tag="$1" engine="$2" idx="$3"
  jq -r --arg tag "$tag" --arg engine "$engine" --argjson i "$((idx-1))" '
    .[$engine] // [] | map(select(.tags and (.tags | index($tag)))) | .[$i]
  ' "$CATALOG"
}

select_model_by_tag() {
  local tag="${1:-general}" engine="${2:-gguf}" choice json id label path
  echo; echo "== ${engine^^} — ${tag^} models =="; _list_by_tag "$tag" "$engine" || return 1
  echo; read -rp "Pick a number (Enter to cancel): " choice
  [[ -z "$choice" ]] && { echo "Canceled."; return 1; }
  json="$(_json_by_index "$tag" "$engine" "$choice")"
  [[ -z "$json" || "$json" = "null" ]] && { echo "[!] Invalid selection"; return 1; }
  id=$(echo "$json" | jq -r '.id // empty'); label=$(echo "$json" | jq -r '.label // empty')
  if [[ "$engine" = "gguf" ]]; then
    path=$(echo "$json" | jq -r '.path // empty')
    [[ -f "$ROOT_DIR/$path" ]] || { echo "[!] GGUF missing: $ROOT_DIR/$path"; return 1; }
    export BLUX_SELECTED_ENGINE="gguf"
    export BLUX_SELECTED_MODEL_PATH="$ROOT_DIR/$path"
    export BLUX_SELECTED_MODEL_ID="$id"
    echo "[OK] GGUF selected: $label"
  else
    local tagstr
    tagstr=$(echo "$json" | jq -r '.tag // empty')
    command -v ollama >/dev/null 2>&1 || { echo "[!] ollama not installed"; return 1; }
    if ! ollama list | awk 'NR>1{print $1}' | grep -qx "$tagstr"; then
      echo "[~] Pulling $tagstr ..."; ollama pull "$tagstr" || return 1
    fi
    export BLUX_SELECTED_ENGINE="ollama"
    export BLUX_SELECTED_OLLAMA_TAG="$tagstr"
    export BLUX_SELECTED_MODEL_ID="$id"
    echo "[OK] Ollama selected: $label"
  fi
}

catalog_menu() {
  banner
  echo "-- Catalog --"
  echo "  1) GGUF — General"
  echo "  2) GGUF — Coding"
  echo "  3) Ollama — General"
  echo "  4) Ollama — Coding"
  echo "  B) Back"
  read -rp "Select: " c
  case "$c" in
    1) select_model_by_tag general gguf ;;
    2) select_model_by_tag coding  gguf ;;
    3) select_model_by_tag general ollama ;;
    4) select_model_by_tag coding  ollama ;;
    B|b|'') ;;
  esac
}