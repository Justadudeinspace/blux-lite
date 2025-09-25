#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
echo "(( • )) BLUX Lite — Jawdrop Demo (2025-09-17T19:36:04Z)"
echo "1) Opening global TUI..." && sleep 1
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/tui/menu.sh" || true
echo "2) Running cloud selftest dry-run..."
if [[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/../scripts/cloud/selftest.sh" ]]; then
  bash "$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/../scripts/cloud/selftest.sh" --dry-run --verbose || true
fi
echo "3) Tail recent logs (10 lines each):"
for f in "$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)/logs"/*.log; do
  echo "--- $f ---"; tail -n 10 "$f" || true; echo
done
echo "Done. (( • ))"