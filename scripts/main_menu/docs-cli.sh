#!/usr/bin/env bash
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t blux)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT
# docs-cli.sh — generate CLI docs (Markdown + manpages) for BLUX
set -euo pipefail
IFS=$'\n\t'
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_MD="${ROOT_DIR}/docs/cli"
OUT_MAN="${ROOT_DIR}/docs/man"

mkdir -p "$OUT_MD" "$OUT_MAN"

if ! command -v md-click >/dev/null 2>&1; then
  echo "[warn] md-click not found. Install with: python -m pip install md-click"
else
  md-click --module blux.cli --entry cli --docsPath "$OUT_MD"
fi

if ! command -v click-man >/dev/null 2>&1; then
  echo "[warn] click-man not found. Install with: python -m pip install click-man"
else
  click-man --project blux-lite-gold --target "$OUT_MAN"
fi

echo "[docs-cli] Done -> $OUT_MD and $OUT_MAN"