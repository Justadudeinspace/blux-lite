#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"


echo "== Disk Space Check =="
echo "Root: $ROOT"
if ! df -h "$ROOT" >/dev/null 2>&1; then
  mkdir -p "$ROOT"
  df -h "$ROOT"
else
  df -h "$ROOT"
fi
echo ""
echo "Installed models:"
ls -lh "$ROOT/models"/*.gguf 2>/dev/null || echo "(none)"
