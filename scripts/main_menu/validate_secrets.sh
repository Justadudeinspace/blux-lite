#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

say(){ printf '[BLUX] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

usage(){
  cat <<'EOF'
validate_secrets.sh — check presence/format of API keys used by BLUX

Usage:
  scripts/main_menu/validate_secrets.sh [--json] [--quiet] [--keys KEY1,KEY2,...]
EOF
}

JSON=0; QUIET=0; KCSV=""
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

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -f "$HERE/load_secrets.sh" ]; then . "$HERE/load_secrets.sh" || warn "load_secrets.sh non-zero"; fi

[ -n "${KCSV:-}" ] || KCSV="HF_TOKEN,OPENAI_API_KEY,GEMINI_API_KEY,ANTHROPIC_API_KEY,TOGETHER_API_KEY,DEEPSEEK_API_KEY,MISTRAL_API_KEY,AZURE_OPENAI_API_KEY,PPLX_API_KEY,XAI_API_KEY"
IFS=',' read -r -a KEYS <<<"$(printf '%s' "$KCSV" | tr -d '[:space:]')"

pattern_for(){
  case "$1" in
    HF_TOKEN)             echo '^hf_[A-Za-z0-9]+' ;;
    OPENAI_API_KEY)       echo '^(sk-|oa-).+' ;;
    *)                    echo '' ;;
  esac
}

ok=0; miss=0
JSON_ITEMS="["
first=1
for key in "${KEYS[@]}"; do
  val="${!key-}"
  pat="$(pattern_for "$key")"
  present=0; valid=0
  if [ -n "${val:-}" ]; then
    present=1
    if [ -n "$pat" ]; then [[ "$val" =~ $pat ]] && valid=1; else valid=1; fi
  fi

  if [ "$QUIET" -eq 0 ]; then
    if [ $present -eq 1 ] && [ $valid -eq 1 ]; then say "[OK]   $key present"
    elif [ $present -eq 1 ]; then                 warn "[FMT]  $key present but unexpected pattern"
    else                                          warn "[MISS] $key not set"
    fi
  fi

  [ $first -eq 0 ] && JSON_ITEMS+=","
  first=0
  esc_val="$(printf '%s' "${val:-}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  JSON_ITEMS+="{\"key\":\"$key\",\"present\":$([ $present -eq 1 ] && echo true || echo false),\"valid\":$([ $valid -eq 1 ] && echo true || echo false),\"value\":\"$esc_val\"}"

  if [ $present -eq 1 ] && [ $valid -eq 1 ]; then ok=$((ok+1)); else miss=$((miss+1)); fi
done
JSON_ITEMS+="]"
summary="Summary: OK=$ok, Missing_or_invalid=$miss"
[ "$QUIET" -eq 0 ] && say "$summary"

if [ "$JSON" -eq 1 ]; then
  raw_json="{\"ok\":$ok,\"missing_or_invalid\":$miss,\"items\":$JSON_ITEMS}"
  if have jq; then printf '%s\n' "$raw_json" | jq .; else printf '%s\n' "$raw_json"; fi
fi

[ $miss -eq 0 ]
