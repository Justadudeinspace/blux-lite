#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
. "$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"

BLG_BANNER "Logs"
find "${LOG_DIR}" -maxdepth 1 -type f -printf "%f\n" 2>/dev/null || ls -1 "${LOG_DIR}" || true
latest="$(ls -1t "${LOG_DIR}" 2>/dev/null | head -n1 || echo "")"
[ -n "${latest}" ] && { echo ""; say "Latest -> ${latest}"; tail -n 200 "${LOG_DIR}/${latest}" || true; }
