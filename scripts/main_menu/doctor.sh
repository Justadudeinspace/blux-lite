#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'
. "$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"

BLG_BANNER "System Doctor"
say "Repo: ${ROOT}"
say "Config: ${CONFIG_DIR}"
say "Logs: ${LOG_DIR}"

for cmd in git curl python3 fzf; do
  if command -v "$cmd" >/dev/null 2>&1; then
    say "OK: $cmd -> $(command -v $cmd)"
  else
    warn "MISSING: $cmd"
  fi
done

if [ -x "$ROOT/.venv/bin/python" ]; then
    PYBIN="$ROOT/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYBIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
    PYBIN="$(command -v python)"
else
    PYBIN=""
fi

"$PYBIN" - <<'PY'
import sys, platform
print("Python:", sys.version.split()[0])
print("Platform:", platform.platform())
PY