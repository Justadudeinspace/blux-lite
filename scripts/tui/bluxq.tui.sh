#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOGS="$ROOT/logs"; mkdir -p "$LOGS"
PY="python3"

start_http() {
  nohup "$PY" -m blux.bluxq --mode http --host 127.0.0.1 --port 8765 >>"$LOGS/bluxq.log" 2>&1 & echo $! > "$LOGS/bluxq.pid"
  echo "Started bluxq (HTTP) pid=$(cat "$LOGS/bluxq.pid")"
}

start_uds() {
  nohup "$PY" -m blux.bluxq --mode uds --socket /tmp/bluxq.sock >>"$LOGS/bluxq.log" 2>&1 & echo $! > "$LOGS/bluxq.pid"
  echo "Started bluxq (UDS) pid=$(cat "$LOGS/bluxq.pid")"
}

stopd() {
  if [[ -f "$LOGS/bluxq.pid" ]]; then
    kill "$(cat "$LOGS/bluxq.pid")" || true
    rm -f "$LOGS/bluxq.pid"
    echo "Stopped bluxq."
  else
    echo "No PID file found."
  fi
}

menu() {
  while true; do
    clear
    echo "=== BLUXQ — model-access API ==="
    echo "1) Start (UDS default)"
    echo "2) Start (HTTP 127.0.0.1:8765)"
    echo "3) Stop"
    echo "4) Tail logs"
    echo "q) Quit"
    read -r -p "Select: " a || true
    case "$a" in
      1) start_uds; read -r -p "Enter..." _ ;;
      2) start_http; read -r -p "Enter..." _ ;;
      3) stopd; read -r -p "Enter..." _ ;;
      4) tail -n 50 -f "$LOGS/bluxq.log" || true ;;
      q|Q) break ;;
    esac
  done
}
menu
