#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

PORT="${1:-4000}"
MODEL="${MODEL:-ollama/codegemma}"   # override with MODEL=ollama/llama3 etc.
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"  # default Ollama endpoint
LOGDIR="${LOGDIR:-$HOME/blux-lite}"
mkdir -p "$LOGDIR"

say(){ printf '%s\n' "$*"; }
warn(){ printf 'WARN: %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

# Basic platform guard (POSIX shells; native Windows PowerShell/CMD not supported)
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) warn "This script requires a POSIX shell (Git-Bash may work, PowerShell/CMD won't).";;
esac

# 1) Dependencies
have litellm || { warn "Missing 'litellm'. Install:  pip install 'litellm[proxy]'"; exit 127; }
have curl || { warn "Missing 'curl'."; exit 127; }
have nohup || { warn "Missing 'nohup'."; exit 127; }
have ollama || warn "Ollama CLI not found; if using a remote Ollama set OLLAMA_URL and ensure it's reachable."

# 2) Ensure Ollama is reachable; try to start locally if missing
if ! curl -fsS "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
  if have ollama; then
    say "Starting local Ollama..."
    nohup ollama serve >/dev/null 2>&1 &
    # wait until responsive (max ~10s)
    for _ in {1..20}; do
      sleep 0.5
      curl -fsS "${OLLAMA_URL}/api/tags" >/dev/null 2>&1 && break || true
    done
  fi
fi

if ! curl -fsS "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
  warn "Ollama endpoint not reachable at ${OLLAMA_URL}. Start Ollama or set OLLAMA_URL."
  exit 1
fi

# 3) Ensure model exists (only for ollama/* targets)
if [[ "$MODEL" == ollama/* ]] && have ollama; then
  O_MODEL="${MODEL#ollama/}"
  if ! ollama list 2>/dev/null | awk '{print $1}' | grep -qx "$O_MODEL"; then
    say "Pulling Ollama model: $O_MODEL"
    ollama pull "$O_MODEL" || { warn "Failed to pull $O_MODEL"; exit 1; }
  fi
fi

# 4) Launch LiteLLM proxy
say "🚀 Starting LiteLLM proxy on port ${PORT} with model '${MODEL}'"
nohup litellm proxy \
  --model "${MODEL}" \
  --port "${PORT}" \
  --debug > "${LOGDIR}/.litellm.log" 2>&1 &

say "✅ LiteLLM running at http://127.0.0.1:${PORT}"
say "📜 Logs: ${LOGDIR}/.litellm.log"