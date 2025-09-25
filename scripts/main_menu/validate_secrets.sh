#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
: "${BLG_ENABLE_CLOUD:=0}"
if [[ "${BLG_ENABLE_CLOUD}" != "1" ]]; then
  echo "[BLUX] Cloud helpers are disabled. Set BLG_ENABLE_CLOUD=1 to enable." >&2
  exit 0
fi

: "${BLG_ENABLE_CLOUD:=0}"
if [[ "$BLG_ENABLE_CLOUD" != "1" ]]; then
  echo "[BLUX] Cloud helpers are disabled. Set BLG_ENABLE_CLOUD=1 to enable." >&2
  exit 0
fi
#!/usr/bin/env bash

# Upstream logging (must be before other output)
# --- begin BLG root resolver ---
BLG_SELF_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"
BLG_ROOT="$BLG_SELF_DIR"
while [ "$BLG_ROOT" != "/" ] && [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; do
  BLG_ROOT="$(dirname "$BLG_ROOT")"
done
if [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; then
  printf '[ERR] Could not locate BLG root (starting at %s)\n' "$BLG_SELF_DIR" >&2
  exit 1
fi
PROJECT_ROOT="$BLG_ROOT"; REPO_ROOT="$BLG_ROOT"
source "$BLG_ROOT/scripts/main_menu/logging.sh"
# --- end BLG root resolver ---

set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# Auto-load (no arguments needed)
source "$HERE/load_secrets.sh"

ok=0; miss=0
_check() {
  local key="$1" pattern="${2:-}"
  local val="${!key-}"
  if [[ -n "${val}" ]]; then
    if [[ -n "$pattern" && ! "$val" =~ $pattern ]]; then
      printf "[WARN] %s present but doesn't match expected pattern\n" "$key"
    else
      printf "[OK]   %s present\n" "$key"
    fi
    ((ok++))
  else
    printf "[MISS] %s not set\n" "$key"
    ((miss++))
  fi
}

_check HF_TOKEN '^hf_[A-Za-z0-9]+'
_check OPENAI_API_KEY '^sk-'
_check GEMINI_API_KEY
_check ANTHROPIC_API_KEY
_check TOGETHER_API_KEY
_check DEEPSEEK_API_KEY
_check MISTRAL_API_KEY

echo "Summary: OK=$ok, Missing=$miss"
exit 0