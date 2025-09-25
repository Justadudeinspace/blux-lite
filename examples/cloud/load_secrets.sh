#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
IFS=$'\n\t'
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
set -euo pipefail
# scripts/main_menu/load_secrets.sh
# sources secrets; masks echo; non-overriding load; normalizes common vars

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

set -Eeuo pipefail

# ---------- helpers ----------
mask(){ 
  # Print KEY=**** for known sensitive variables (if set)
  local k="$1" v="${!1:-}"
  [ -n "$v" ] && printf "%s=%s\n" "$k" "****"
}

# Load a .env file into the current env without clobbering pre-set vars.
apply_non_overriding(){
  local f="$1"
  [ -f "$f" ] || return 0
  # Read file line-by-line and export only missing keys
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^([^=[:space:]]+)[[:space:]]*=(.*)$ ]]; then
      local k="${BASH_REMATCH[1]}" v="${BASH_REMATCH[2]}"
      # strip surrounding quotes
      v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"
      if [ -z "${!k+x}" ]; then
        export "$k"="$v"
      fi
    fi
  done < "$f"
}

# ---------- locations ----------
PROJECT_LOCAL="./.secrets/secrets.env"
SYSTEM_LEVEL="/.secrets/secrets.env"

# Prefer project-local first, then system-level (without overriding existing)
apply_non_overriding "$PROJECT_LOCAL"
apply_non_overriding "$SYSTEM_LEVEL"

# Optional legacy auto-load (kept for backward compatibility)
if [ -f "$SYSTEM_LEVEL" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$SYSTEM_LEVEL"
  set +a
fi

# ---------- normalize / defaults ----------
: "${OPENAI_API_KEY:=}"
: "${AZURE_OPENAI_API_KEY:=}"
: "${AZURE_OPENAI_ENDPOINT:=}"
: "${GEMINI_API_KEY:=}"
: "${DEEPSEEK_API_KEY:=}"
: "${XAI_API_KEY:=}"
: "${PPLX_API_KEY:=}"
: "${BLACKBOX_API_KEY:=}"
: "${HF_TOKEN:=}"
: "${HF_USERNAME:=}"
: "${GITHUB_TOKEN:=}"
: "${GITHUB_USERNAME:=}"
: "${GITHUB_EMAIL:=}"
# Ollama (optional remote host config)
: "${OLLAMA_HOST:=http://127.0.0.1:11434}"
: "${OLLAMA_PORT:=11434}"
: "${OLLAMA_KEEP_ALIVE:=5m}"

export OPENAI_API_KEY AZURE_OPENAI_API_KEY AZURE_OPENAI_ENDPOINT GEMINI_API_KEY \
       DEEPSEEK_API_KEY XAI_API_KEY PPLX_API_KEY BLACKBOX_API_KEY HF_TOKEN HF_USERNAME \
       GITHUB_TOKEN GITHUB_USERNAME GITHUB_EMAIL OLLAMA_HOST OLLAMA_PORT OLLAMA_KEEP_ALIVE

# ---------- masked echo (extend as needed) ----------
for key in OPENAI_API_KEY HF_TOKEN GEMINI_API_KEY PPLX_API_KEY AZURE_OPENAI_API_KEY GITHUB_TOKEN; do
  mask "$key" || true
done