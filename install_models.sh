#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

say(){ printf "%s\n" "${*:-}"; }
warn(){ printf "WARN: %s\n" "${*:-}" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) warn "Native Windows shells not supported. Use WSL or Git-Bash."; ;;
esac

have ollama || { warn "ollama not found on PATH. Install from https://ollama.com/ and re-run."; exit 127; }
have curl   || { warn "curl not found; needed to probe Ollama."; exit 127; }

say "🧠 Pulling open-source coding models (aligned with README catalog examples)…"
say "   (Hosted APIs like GPT-4o / Claude / Gemini are NOT pulled by this script.)"

MODELS=( codegemma phi3 llama3 mistral mixtral qwen2.5 starcoder2 deepseek-r1 )

# Wait for local ollama (if serving) to be responsive; skip if remote/managed
if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  :
else
  warn "Ollama service not responding at http://127.0.0.1:11434 (continuing; pulls may still work)."
fi

pull_with_retry() {
  local name="$1" attempts=0 max=3
  while (( attempts < max )); do
    if ollama pull "$name"; then
      return 0
    fi
    attempts=$((attempts+1))
    warn "pull failed for ${name} (attempt ${attempts}/${max}); retrying…"
    sleep 2
  done
  return 1
}

for model in "${MODELS[@]}"; do
  say "⬇️ Pulling: ${model}"
  if pull_with_retry "${model}"; then
    say "✅ Pulled ${model}"
  else
    warn "⚠️ Failed to pull ${model} — skipping"
  fi
done

say "✅ Model install pass complete."