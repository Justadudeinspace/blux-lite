#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

: "${REPO_ROOT:=$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
: "${CONFIG_DIR:=${REPO_ROOT}/.config/blux-lite-gold}"
RUNTIME_ENV="${CONFIG_DIR}/runtime.env"
ENV_FILES=(".env" "${RUNTIME_ENV}")

for f in "${ENV_FILES[@]}"; do
  [ -f "$f" ] && { set -a; . "$f"; set +a; }
done

[ -n "${OPENAI_API_KEY-}" ] && echo "OPENAI_API_KEY loaded"
