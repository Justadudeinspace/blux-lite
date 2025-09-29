#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# --- early guard: native Windows shells ---
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*)
    printf 'This tool requires a POSIX shell. Use WSL or Git-Bash. Native Windows support arrives in v1.1.0.\n' >&2
    exit 2
  ;;
esac

# --- helpers ---
say(){ printf "%s\n" "${*:-}"; }
warn(){ printf "WARN: %s\n" "${*:-}" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

usage(){
  cat <<'EOF'
BLUX API shim (Ollama)

Usage:
  blux_api.sh [-m MODEL] [--url OLLAMA_URL] [--raw] [PROMPT]
  echo "multi line" | blux_api.sh -m llama3

Options:
  -m, --model   Model id (default: codegemma)
  --url         Ollama base URL (default: http://127.0.0.1:11434)
  --raw         Print raw JSON from HTTP path (no pretty)
  -h, --help    Show this help

Notes:
- Uses 'ollama run' if present; otherwise falls back to HTTP POST /api/generate.
- Works on Termux/Linux/macOS/WSL2. Native Windows requires WSL or Git-Bash.
EOF
}

MODEL="codegemma"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
RAW=0

# --- args ---
PROMPT_FROM_ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -m|--model) shift; MODEL="${1:-$MODEL}" ;;
    --url)      shift; OLLAMA_URL="${1:-$OLLAMA_URL}" ;;
    --raw)      RAW=1 ;;
    -h|--help)  usage; exit 0 ;;
    --)         shift; PROMPT_FROM_ARGS="${*:-}"; break ;;
    *)          [ -z "${PROMPT_FROM_ARGS}" ] && PROMPT_FROM_ARGS="$1" || PROMPT_FROM_ARGS="$PROMPT_FROM_ARGS $1" ;;
  esac
  shift || true
done

# Accept stdin as prompt if piped
if [ -t 0 ]; then
  PROMPT="${PROMPT_FROM_ARGS:-}"
else
  PROMPT="$(cat -)"
fi

if [ -z "${PROMPT:-}" ]; then
  usage
  exit 1
fi

say "Sending to ${MODEL}…"
say ""

# --- prefer CLI, else HTTP ---
if have ollama; then
  RESPONSE="$(ollama run "${MODEL}" -p "${PROMPT}")" || {
    warn "ollama run failed for model '${MODEL}'."
    exit 1
  }
  say "BLUX-API Response:"
  printf "%s\n" "${RESPONSE}"
  exit 0
fi

# --- HTTP path (no ollama CLI) ---
have curl || { warn "Neither 'ollama' nor 'curl' found. Install one (curl recommended)."; exit 127; }

# Build JSON safely: python3 > python > jq -Rs . (last resort)
json_escape() {
  if have python3; then
    python3 - <<'PY'
import json,sys
print(json.dumps(sys.stdin.read()))
PY
  elif have python; then
    python - <<'PY'
import json,sys
print(json.dumps(sys.stdin.read()))
PY
  elif have jq; then
    jq -Rs .
  else
    exit 3
  fi
}

ESCAPED_PROMPT="$(printf '%s' "${PROMPT}" | json_escape || true)"
if [ -z "${ESCAPED_PROMPT:-}" ]; then
  warn "No JSON encoder available (need python3/python or jq). Install one and retry."
  exit 3
fi

REQ_PAYLOAD=$(printf '{"model":"%s","prompt":%s,"stream":false}' "${MODEL}" "${ESCAPED_PROMPT}")

HTTP_RESP="$(curl -fsS -X POST "${OLLAMA_URL%/}/api/generate" \
  -H 'Content-Type: application/json' \
  -d "${REQ_PAYLOAD}")" || {
    warn "HTTP request to ${OLLAMA_URL}/api/generate failed."
    exit 1
  }

if [ "${RAW}" -eq 1 ]; then
  printf "%s\n" "${HTTP_RESP}"
  exit 0
fi

if have jq; then
  TEXT="$(printf '%s' "${HTTP_RESP}" | jq -r '.response // .message // .output // .[]? // empty')"
  if [ -n "${TEXT}" ] && [ "${TEXT}" != "null" ]; then
    say "BLUX-API Response:"
    printf "%s\n" "${TEXT}"
  else
    say "BLUX-API Raw:"
    printf "%s\n" "${HTTP_RESP}"
  fi
else
  say "BLUX-API Raw:"
  printf "%s\n" "${HTTP_RESP}"
fi