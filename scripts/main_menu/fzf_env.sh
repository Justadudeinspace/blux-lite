#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

# Resolve paths
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROJECT_ROOT="${PROJECT_ROOT:-$ROOT}"
REPO_ROOT="${REPO_ROOT:-$ROOT}"

# Source logging exactly once
set +u
[ -n "${BLG_LOGGING_SOURCED:-}" ] || source "${PROJECT_ROOT}/scripts/main_menu/logging.sh"
set -u

# Non-blocking defaults for fzf/gum could go here if you want
# export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --height=80% --reverse"