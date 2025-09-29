#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# docs-cli.sh — generate CLI docs (Markdown + manpages) for BLUX

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
OUT_MD="${ROOT}/docs/cli"
OUT_MAN="${ROOT}/docs/man"

mkdir -p "$OUT_MD" "$OUT_MAN"

if [ -x "$ROOT/.venv/bin/python" ]; then
    PYBIN="$ROOT/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYBIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
    PYBIN="$(command -v python)"
else
    PYBIN=""
fi

if ! command -v md-click >/dev/null 2>&1; then
  echo "[warn] md-click not found. Install with: $PYBIN -m pip install md-click"
else
  "$PYBIN" -m md_click --module blux.cli --entry cli --docsPath "$OUT_MD"
fi

if ! command -v click-man >/dev/null 2>&1; then
  echo "[warn] click-man not found. Install with: $PYBIN -m pip install click-man"
else
  "$PYBIN" -m click_man --project blux-lite-gold --target "$OUT_MAN"
fi

echo "[docs-cli] Done -> $OUT_MD and $OUT_MAN"
