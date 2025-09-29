#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

: "${CONFIG_DIR:=${ROOT}/.config/blux-lite-gold}"
RUNTIME_ENV="${CONFIG_DIR}/runtime.env"
ENV_FILES=(".env" "${RUNTIME_ENV}")

for f in "${ENV_FILES[@]}"; do
  [ -f "$f" ] && { set -a; . "$f"; set +a; }
done

[ -n "${OPENAI_API_KEY-}" ] && echo "OPENAI_API_KEY loaded"