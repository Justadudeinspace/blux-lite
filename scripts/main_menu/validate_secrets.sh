#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# -------- helpers --------
say(){\n  printf '[BLUX] %s\n' "$*";
}
warn(){
  printf '[WARN] %s\n' "$*" >&2;
}
have(){
  command -v "$1" >/dev/null 2>&1;
}
is_termux(){
  case "${PREFIX-}" in */com.termux/*) return 0;; *) return 1;; esac;
}

usage(){
  cat <<'EOF'
validate_secrets.sh — check presence/format of API keys used by BLUX

Usage:
  scripts/main_menu/validate_secrets.sh [--json] [--quiet] [--keys KEY1,KEY2,...]

Options:
  --json      Output machine-readable JSON (requires jq for pretty-print; falls back to raw).
  --quiet     Suppress per-key lines; summary + exit code only.
  --keys      Comma-separated list of env vars to validate (default: common BLUX keys).

Behavior:
- Loads scripts/main_menu/load_secrets.sh if present (env-file friendly).
- Returns exit code 0 if all requested keys are present; 1 if any are missing.

Examples:
  scripts/main_menu/validate_secrets.sh
  scripts/main_menu/validate_secrets.sh --json
  scripts/main_menu/validate_secrets.sh --keys OPENAI_API_KEY,GEMINI_API_KEY --quiet
EOF
}

# -------- args --------
JSON=0
QUIET=0
KCSV=""
while [ $# -gt 0 ]; do
  case "${1-}" in
    --json)  JSON=1 ;;
    --quiet) QUIET=1 ;;
    --keys)  shift; KCSV="${1-}" ;;
    -h|--help|help) usage; exit 0 ;;
    *) warn "Unknown arg: $1"; usage; exit 2 ;;
  esac
  shift || true
done

# -------- locate repo + load secrets (optional) --------
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
HERE="$ROOT/scripts/main_menu"
if [ -f "$HERE/load_secrets.sh" ]; then
  # shellcheck disable=SC1090
  . "$HERE/load_secrets.sh" || warn "load_secrets.sh returned non-zero"
fi

# -------- default keys if not provided --------
if [ -z "${KCSV:-}" ]; then
  KCSV="HF_TOKEN,OPENAI_API_KEY,GEMINI_API_KEY,ANTHROPIC_API_KEY,TOGETHER_API_KEY,DEEPSEEK_API_KEY,MISTRAL_API_KEY,AZURE_OPENAI_API_KEY,PPLX_API_KEY,XAI_API_KEY"
fi

# turn into array (trim spaces)
IFS=',' read -r -a KEYS <<<"$(printf '%s' "$KCSV" | tr -d '[:space:]')"

# -------- simple pattern guards --------
pattern_for(){
  case "$1" in
    HF_TOKEN)             echo '^hf_[A-Za-z0-9]+' ;;
    OPENAI_API_KEY)       echo '^(sk-|oa-).+' ;;
    AZURE_OPENAI_API_KEY) echo '^.+$' ;;  # tenant setups vary; just presence
    GEMINI_API_KEY)       echo '^.+$' ;; 
    ANTHROPIC_API_KEY)    echo '^.+$' ;; 
    TOGETHER_API_KEY)     echo '^.+$' ;; 
    DEEPSEEK_API_KEY)     echo '^.+$' ;; 
    MISTRAL_API_KEY)      echo '^.+$' ;; 
    PPLX_API_KEY)         echo '^.+$' ;; 
    XAI_API_KEY)          echo '^.+$' ;; 
    *)                    echo '' ;;
  esac
}

# -------- validate --------
ok=0; miss=0
JSON_ITEMS="[" ; first=1

for key in "${KEYS[@]}"; do
  val="${!key-}"
  pat="$(pattern_for "$key")"
  present=0
  valid=0
  if [ -n "${val:-}" ]; then
    present=1
    if [ -n "$pat" ]; then
      if [[ "$val" =~ $pat ]]; then valid=1; fi
    else
      valid=1
    fi
  fi

  # human output
  if [ "$QUIET" -eq 0 ]; then
    if [ "$present" -eq 1 ] && [ "$valid" -eq 1 ]; then
      say "[OK]   $key present"
    elif [ "$present" -eq 1 ] && [ "$valid" -eq 0 ]; then
      warn "[FMT]  $key present but does not match expected pattern"
    else
      warn "[MISS] $key not set"
    fi
  fi

  # json item
  [ $first -eq 0 ] && JSON_ITEMS+=,
  first=0
  esc_val="$(printf '%s' "${val:-}" | sed 's/\\/\\\\/g; s/"/\"/g')"
  JSON_ITEMS+="{\"key\":\"$key\",\"present\":$([ $present -eq 1 ] && echo true || echo false), \"valid\":$([ $valid -eq 1 ] && echo true || echo false), \"value\":\"$esc_val\"}"

  # counters (missing or invalid counts as miss)
  if [ "$present" -eq 1 ] && [ "$valid" -eq 1 ]; then
    ok=$((ok+1))
  else
    miss=$((miss+1))
  fi
done

JSON_ITEMS+= \"]"
summary="Summary: OK=$ok, Missing_or_invalid=$miss"
[ "$QUIET" -eq 0 ] && say "$summary"

if [ "$JSON" -eq 1 ]; then
  raw_json="{\"ok\":$ok,\"missing_or_invalid\":$miss,\"items\":$JSON_ITEMS}"
  if have jq;
    then
    printf '%s\n' "$raw_json" | jq .
  else
    printf '%s\n' "$raw_json"
  fi
fi

# exit status: fail if any missing/invalid
[ $miss -eq 0 ]
