#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

: "${CONFIG_DIR:=${ROOT}/.config/blux-lite-gold}"
: "${LOG_DIR:=${CONFIG_DIR}/logs}"
mkdir -p "${LOG_DIR}"

log_file_for(){
  local tag="${1:-run}"
  local d="$(date +%Y-%m-%d)"
  echo "${LOG_DIR}/${tag}-${d}.log"
}

log(){ printf "%s %s\n" "$(date +%H:%M:%S)" "$*" | tee -a "$(log_file_for app)"; }