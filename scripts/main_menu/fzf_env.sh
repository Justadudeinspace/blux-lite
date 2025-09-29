#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Resolve paths
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"
BLG_ROOT="$SCRIPT_DIR"
__ascents=0
while [ "$BLG_ROOT" != "/" ] && [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ] && [ $__ascents -lt 8 ]; do
  BLG_ROOT="$(dirname "$BLG_ROOT")"; __ascents=$((__ascents+1))
done

PROJECT_ROOT="${PROJECT_ROOT:-$BLG_ROOT}"
REPO_ROOT="${REPO_ROOT:-$BLG_ROOT}"

# Source logging exactly once
set +u
[ -n "${BLG_LOGGING_SOURCED:-}" ] || source "${PROJECT_ROOT}/scripts/main_menu/logging.sh"
set -u

# Non-blocking defaults for fzf/gum could go here if you want
# export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --height=80% --reverse"
