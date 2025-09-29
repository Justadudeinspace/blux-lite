#!/usr/bin/env bash
IFS=$'\n\t'
set -euo pipefail
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*)
    printf 'This tool requires a POSIX shell. Use WSL or Git-Bash. Native Windows support lands in v1.1.0.\n' >&2
    exit 2
  ;;
esac

# --- root resolver + logging hook (non-fatal if logging.sh missing) ---
BLG_SELF_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)"
BLG_ROOT="$BLG_SELF_DIR"
while [ "$BLG_ROOT" != "/" ] && [ ! -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; do
  BLG_ROOT="$(dirname "$BLG_ROOT")"
done
PROJECT_ROOT="$BLG_ROOT"; REPO_ROOT="$BLG_ROOT"
if [ -f "$BLG_ROOT/scripts/main_menu/logging.sh" ]; then
  # shellcheck disable=SC1091
  . "$BLG_ROOT/scripts/main_menu/logging.sh"
else
  say(){ printf '[BLUX] %s\n' "$*"; }
  warn(){ printf '[WARN] %s\n' "$*" >&2; }
fi

# -----------------------------
# Resolve paths / config
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$SCRIPT_DIR"

# NOTE: adapted to current repo
CONFIG_DIR="${REPO_ROOT}/.config/blux-lite-gold"
ROUTER_FILE="${CONFIG_DIR}/router.yaml"
CONF_FILE="${CONFIG_DIR}/config.yaml"
LOG_DIR="${CONFIG_DIR}"
TODAY="$(date +%m_%d_%Y)"
LOG_FILE="${LOG_DIR}/blux_lite.log"
DAILY_LOG="${LOG_DIR}/blux-lite-gold-${TODAY}.log"
SECRETS_FILE="${REPO_ROOT}/.secrets/secrets.env"

# fzf defaults (non-fatal)
[ -f "${REPO_ROOT}/scripts/main_menu/fzf_env.sh" ] && . "${REPO_ROOT}/scripts/main_menu/fzf_env.sh" || true

# -----------------------------
# Python resolver (venv > python3 > python)
# -----------------------------
detect_python() {
  if [ -x "${REPO_ROOT}/.venv/bin/python" ]; then
    printf '%s\n' "${REPO_ROOT}/.venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    printf '%s\n' ""
  fi
}
PYBIN="$(detect_python)"
if [ -z "${PYBIN}" ]; then
  warn "No Python interpreter found (need python3). Install deps via first_start.sh."
fi

# -----------------------------
# Theme (space-age neon)
# -----------------------------
have(){ command -v "$1" >/dev/null 2>&1; }
say(){ printf "%b\n" "$*"; }
C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_BOLD=$'\033[1m'
C_NEON_CYAN=$'\033[96m'
C_NEON_MAG=$'\033[95m'
C_NEON_GRN=$'\033[92m'
C_NEON_YEL=$'\033[93m'
C_RED=$'\033[31m'
C_BG_DARK=$'\033[48;2;10;12;16m'
C_FG_FAINT=$'\033[38;2;160;170;190m'

info(){ say "${C_NEON_CYAN}[INFO]${C_RESET} $*"; }
ok(){ say   "${C_NEON_GRN}[OK]${C_RESET} $*"; }
warn(){ say "${C_NEON_YEL}[WARN]${C_RESET} $*"; }
err(){ say  "${C_RED}[ERR]${C_RESET} $*"; }
step(){ say "${C_BG_DARK}${C_NEON_CYAN}==${C_RESET} ${C_NEON_MAG}$*${C_RESET}"; }

ensure_dirs(){ mkdir -p "${LOG_DIR}" "${REPO_ROOT}/engines" "${REPO_ROOT}/models"; }

# -----------------------------
# Logging (tee to current + daily)
# -----------------------------
start_logging(){
  ensure_dirs
  touch "${LOG_FILE}" "${DAILY_LOG}"
  if [ -z "${__BLUX_TEE_STARTED:-}" ]; then
    exec > >(tee -a "${LOG_FILE}" "${DAILY_LOG}") 2>&1
    __BLUX_TEE_STARTED=1
  fi
  info "Logging to ${LOG_FILE} and ${DAILY_LOG}"
}

# ... [unchanged orchestrator and submenu logic omitted for brevity] ...

log_menu(){
  step "Log Menu"
  local files=("blux_lite.log")
  local more=()
  if [ -d "${LOG_DIR}" ]; then
    while IFS= read -r -d '' file; do
      more+=("$(basename "$file")")
    done < <(find "${LOG_DIR}" -name "blux-lite-gold-*.log" -print0 2>/dev/null || true)
  fi
  files+=("${more[@]}")
  [ "${#files[@]}" -gt 0 ] || { warn "No log files yet."; read -r -p "Press Enter to return..." _ || true; return; }
  local pick; pick="$(choose_one "Pick a log to view" "${files[@]}" || true)"
  [ -n "${pick:-}" ] || return
  local target="${LOG_DIR}/${pick}"
  if have less; then less +G "$target"; else tail -n 400 "$target"; fi
}

blg_menu() {
  local HERE="${REPO_ROOT}"
  if [ -n "${PYBIN:-}" ]; then
    if [ -x "$HERE/scripts/blg_tui.sh" ]; then
      "$HERE/scripts/blg_tui.sh"
    else
      ( cd "$HERE" && "$PYBIN" -m blux.tui_blg )
    fi
  else
    echo "python3 not found; cannot start BLG TUI"
    read -rp "Press enter to continue..." || true
  fi
}

choose_one_basic(){
  local prompt="$1"; shift
  local items=("$@")
  [ "${#items[@]}" -gt 0 ] || { warn "No options for ${prompt}"; return 1; }
  # ... unchanged whiptail/dialog/fzf blocks ...
  else
    say "${C_BOLD}${prompt}${C_RESET}"
    local i=1; for it in "${items[@]}"; do printf " %2d) %s\n" "$i" "$it"; i=$((i+1)); done
    printf "Select [1-%d]: " "${#items[@]}"; read -r sel || return 1
    [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#items[@]}" ] && echo "${items[$((sel-1))]}"
  fi
}

# -----------------------------
# Main Menu
# -----------------------------
main_menu(){
  local choices=(
    "0) Install Dependencies"
    "1) HuggingFace Login"
    "2) GitHub HTTPS Token Login"
    "3) GitHub SSH Login (Gens Key)"
    "4) Verify Logins"
    "5) Install Engines"
    "6) Install Models"
    "7) Install blux Shiv"
    "8) Open Plugin Menu"
    "9) Open Scripts Menu"
    "10) Open BLG Textual TUI"
    "11) Log Menu"
    "12) Cloud / Heart System"
    "13) Admin"
    "14) blux --help cmd tree"
    "Q) Quit"
  )
  while true; do
    step "BLUX Lite GOLD — Main Menu"
    say "${C_DIM}${C_FG_FAINT}Active route → provider='${ACTIVE_PROVIDER}' model='${ACTIVE_MODEL}' engine='${ACTIVE_ENGINE}' (task='${DEFAULT_TASK:-general}')${C_RESET}"
    local sel; sel="$(choose_one "Select an option" "${choices[@]}" || true)"
    [ -n "${sel:-}" ] || exit 0
    case "$sel" in
      "2) GitHub HTTPS Token Login") [ -x "${REPO_ROOT}/scripts/main_menu/env.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/env.sh" || { have gh && gh auth login || warn "gh not found"; } ;;
      "3) GitHub SSH Login (Gens Key)") [ -x "${REPO_ROOT}/scripts/main_menu/aliases_install.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/aliases_install.sh" || { ssh-keygen -t ed25519 -f "${HOME}/.ssh/id_ed25519" -N "" || true; } ;;
      "14) blux --help cmd tree") { [ -n "${PYBIN:-}" ] && "$PYBIN" -m blux.cli --help; } || warn "cli help unavailable" ;;
      # ... other unchanged cases ...
    esac
  done
}

blg_catalogs(){
  if [ -f "${REPO_ROOT}/scripts/tui/menu.sh" ]; then
    bash "${REPO_ROOT}/scripts/tui/menu.sh" catalogs_install_picker || true
  else
    [ -n "${PYBIN:-}" ] && "$PYBIN" -m blux.catalog_install models || warn "Python not found for catalogs"
  fi
}

# --- Footer ---
print_footer() {
  local signals=(
    "Here we are."
    "For those who look, the light is already on."
    "Most will pass. A few will stay."
    "Not louder, only clearer."
    "The signal waits. The searching find."
    "The journey is the reward."
    "What you seek is seeking you."
    "The curious find their own way."
  )
  local idx=$(( $(date +%s) / 60 % ${#signals[@]} ))
  
  # ANSI color codes
  local gold='\033[0;33m'
  local nc='\033[0m' # No Color

  printf "\n${gold}(( • ))${nc}  %s\n" "${signals[$idx]}"
}

print_footer