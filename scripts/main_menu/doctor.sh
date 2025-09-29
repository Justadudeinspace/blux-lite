#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
. "$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"

BLG_BANNER "System Doctor"
say "Repo: ${REPO_ROOT}"
say "Config: ${CONFIG_DIR}"
say "Logs: ${LOG_DIR}"

for cmd in git curl python3 fzf; do
  if command -v "$cmd" >/dev/null 2>&1; then
    say "OK: $cmd -> $(command -v $cmd)"
  else
    warn "MISSING: $cmd"
  fi
done

python3 - <<'PY'
import sys, platform
print("Python:", sys.version.split()[0])
print("Platform:", platform.platform())
PY
