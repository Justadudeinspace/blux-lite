#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
###########################
## BLUX Lite GOLD — Primary Orchestrator Main Menu (Dark + Neon Accents)
## - Restored from “gold” runner, adapted to current blux-lite repo
## - Uses .config/blux-lite-gold
## - Integrates plugin_menu.sh + scripts_menu.sh as submenus
## - Uses scripts/blg_tui.sh → python -m blux.tui_blg fallback
## - fzf/gum/dialog fallbacks for space-age menu UX
###########################

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

set -Eeuo pipefail
IFS=$'\n\t'

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

# -----------------------------
# Basic YAML (key: value) -> ENV
# -----------------------------
load_simple_yaml(){
  local file="$1"
  [ -f "$file" ] || return 0
  while IFS='' read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    if [[ "$line" =~ ^([A-Za-z0-9_-]+)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
      local k="${BASH_REMATCH[1]}" v="${BASH_REMATCH[2]}"
      k="${k//-/_}"; k="$(echo "$k" | tr '[:lower:]' '[:upper:]')"
      v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"
      v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
      export "$k"="$v"
    fi
  done < "$file"
}

# -----------------------------
# Secrets loader
# -----------------------------
load_secrets(){
  if [ -f "${REPO_ROOT}/scripts/main_menu/load_secrets.sh" ]; then
    bash "${REPO_ROOT}/scripts/main_menu/load_secrets.sh" || true
  elif [ -f "${SECRETS_FILE}" ]; then
    set -a; . "${SECRETS_FILE}"; set +a
  fi
}

# -----------------------------
# Router reload (graceful fallback)
# -----------------------------
ACTIVE_PROVIDER=""; ACTIVE_MODEL=""; ACTIVE_ENGINE=""
router_reload(){
  step "Reload Router / Config"
  load_simple_yaml "${CONF_FILE}"
  : "${DEFAULT_TASK:=}"; : "${DEFAULT_TASK:=${DEFAULT_TASK_NAME:-}}"
  : "${DEFAULT_TASK:=${DEFAULT_TASK:-general}}"

  if [ ! -f "${ROUTER_FILE}" ]; then
    warn "router.yaml not found at ${ROUTER_FILE}"
    ACTIVE_PROVIDER="local"; ACTIVE_ENGINE="llama.cpp"; ACTIVE_MODEL="llama-3.1-8b-instruct.Q4_K_M.gguf"
    return 0
  fi

  local lines=() in_section=0 found_task=0
  while IFS= read -r ln || [ -n "$ln" ]; do
    [[ "$ln" =~ ^[[:space:]]*# ]] && continue
    if [[ "$ln" =~ ^routing:[[:space:]]*$ ]]; then in_section=1; continue; fi
    [ $in_section -eq 0 ] && continue
    if [[ "$ln" =~ ^[[:space:]]*${DEFAULT_TASK}:[[:space:]]*$ ]]; then
      found_task=1; continue
    fi
    if [ $found_task -eq 1 ]; then
      [[ "$ln" =~ ^[[:space:]]*[a-zA-Z0-9_]+:[[:space:]]*$ ]] && break
      if [[ "$ln" =~ ^[[:space:]]*-[[:space:]]+([a-zA-Z0-9_]+):[[:space:]]*([A-Za-z0-9._\-]+)[[:space:]]*$ ]]; then
        lines+=("${BASH_REMATCH[1]}:${BASH_REMATCH[2]}")
      fi
    fi
  done < "${ROUTER_FILE}"

  if [ ${#lines[@]} -eq 0 ]; then
    ACTIVE_PROVIDER="local"; ACTIVE_ENGINE="llama.cpp"; ACTIVE_MODEL="llama-3.1-8b-instruct.Q4_K_M.gguf"
    info "Router had no priorities for task='${DEFAULT_TASK}', using fallback ${ACTIVE_PROVIDER}/${ACTIVE_MODEL}"
    return 0
  fi

  local prov mdl
  for ent in "${lines[@]}"; do
    prov="${ent%%:*}"; mdl="${ent#*:}"
    case "$prov" in
      local)       ACTIVE_PROVIDER="local"; ACTIVE_ENGINE="llama.cpp"; ACTIVE_MODEL="$mdl"; break ;;
      openai)      [ -n "${OPENAI_API_KEY:-}" ]       && ACTIVE_PROVIDER="$prov" && ACTIVE_MODEL="$mdl" && break ;;
      gemini)      [ -n "${GEMINI_API_KEY:-}" ]       && ACTIVE_PROVIDER="$prov" && ACTIVE_MODEL="$mdl" && break ;;
      deepseek)    [ -n "${DEEPSEEK_API_KEY:-}" ]     && ACTIVE_PROVIDER="$prov" && ACTIVE_MODEL="$mdl" && break ;;
      xai_grok)    [ -n "${XAI_API_KEY:-}" ]          && ACTIVE_PROVIDER="$prov" && ACTIVE_MODEL="$mdl" && break ;;
      perplexity)  [ -n "${PPLX_API_KEY:-}" ]         && ACTIVE_PROVIDER="$prov" && ACTIVE_MODEL="$mdl" && break ;;
      azure_openai)[ -n "${AZURE_OPENAI_API_KEY:-}" ] && ACTIVE_PROVIDER="$prov" && ACTIVE_MODEL="$mdl" && break ;;
      blackbox)    [ -n "${BLACKBOX_API_KEY:-}" ]     && ACTIVE_PROVIDER="$prov" && ACTIVE_MODEL="$mdl" && break ;;
    esac
  done

  [ -z "${ACTIVE_PROVIDER}" ] && { ACTIVE_PROVIDER="local"; ACTIVE_ENGINE="llama.cpp"; ACTIVE_MODEL="llama-3.1-8b-instruct.Q4_K_M.gguf"; }
  info "Route task='${DEFAULT_TASK}' → provider='${ACTIVE_PROVIDER}' model='${ACTIVE_MODEL}' engine='${ACTIVE_ENGINE}'"
}

# -----------------------------
# External Submenus / Actions
# -----------------------------
open_plugin_menu(){ bash "${REPO_ROOT}/plugin_menu.sh"; }
open_scripts_menu(){ bash "${REPO_ROOT}/scripts_menu.sh"; }

install_dependencies(){ [ -x "${REPO_ROOT}/scripts/main_menu/install_deps.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/install_deps.sh" || warn "install_deps.sh missing"; }
install_blux_shiv(){ [ -x "${REPO_ROOT}/scripts/main_menu/install_blux_shiv.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/install_blux_shiv.sh" || warn "install_blux_shiv.sh missing"; }

verify_logins_menu(){
  step "Verify Logins"
  local choices=(
    "1) Verify Hugging Face (hf whoami)"
    "2) Verify GitHub Token (gh auth status)"
    "3) Verify GitHub SSH (ssh -T git@github.com)"
    "4) Show Configured Identity (git config user.*)"
    "Back"
  )
  local sel
  while true; do
    sel="$(choose_one "Select verification" "${choices[@]}" || true)"
    [ -n "${sel:-}" ] || return
    case "$sel" in
      "1) Verify Hugging Face (hf whoami)")
        if have hf; then hf whoami || warn "hf whoami returned non-zero"
        else warn "'hf' not found"; fi ;;
      "2) Verify GitHub Token (gh auth status)")
        if have gh; then gh auth status || warn "gh auth status non-zero"
        else warn "'gh' not found"; fi ;;
      "3) Verify GitHub SSH (ssh -T git@github.com)")
        say "This may return code 1 even on success (GitHub banner)."
        set +e; ssh -o StrictHostKeyChecking=no -T git@github.com; code=$?; set -e
        [ $code -le 1 ] && ok "SSH reachable" || warn "ssh exit=$code" ;;
      "4) Show Configured Identity (git config user.*)")
        say "user.name:  $(git config --global user.name || echo "Not set")"
        say "user.email: $(git config --global user.email || echo "Not set")";;
      *) return ;;
    esac
  done
}

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
  [ "${#files[@]}" -gt 0 ] || { warn "No log files yet."; read -r -p "Press Enter to return..." _; return; }
  local pick; pick="$(choose_one "Pick a log to view" "${files[@]}" || true)"
  [ -n "${pick:-}" ] || return
  local target="${LOG_DIR}/${pick}"
  if have less; then less +G "$target"; else tail -n 400 "$target"; fi
}

catalog_install_engines(){ [ -x "${REPO_ROOT}/scripts/main_menu/catalog.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/catalog.sh" engines || warn "catalog.sh engines missing"; }
catalog_install_models(){  [ -x "${REPO_ROOT}/scripts/main_menu/catalog.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/catalog.sh" models  || warn "catalog.sh models missing"; }

# -----------------------------
# BLG Textual TUI (support)
# -----------------------------
blg_menu() {
  local HERE="${REPO_ROOT}"
  if have python3; then
    if [ -x "$HERE/scripts/blg_tui.sh" ]; then
      "$HERE/scripts/blg_tui.sh"
    else
      local PYX="${PYTHON:-python3}"
      ( cd "$HERE" && "$PYX" -m blux.tui_blg )
    fi
  else
    echo "python3 not found; cannot start BLG TUI"
    read -rp "Press enter to continue..."
  fi
}

# -----------------------------
# Chooser (fzf/gum/dialog/ansi)
# -----------------------------
choose_one_basic(){
  local prompt="$1"; shift
  local items=("$@")
  [ "${#items[@]}" -gt 0 ] || { warn "No options for ${prompt}"; return 1; }
  if have whiptail; then
    local menu_items=() i=1; for it in "${items[@]}"; do menu_items+=("$i" "$it"); i=$((i+1)); done
    local idx; idx=$(whiptail --backtitle "BLG by ~JADIS" --title "Main Menu" --notags --menu "$prompt" 20 78 12 "${menu_items[@]}" 3>&1 1>&2 2>&3) || return 1
    echo "${items[$((idx-1))]}"; return 0
  elif have dialog; then
    local menu_items=() i=1; for it in "${items[@]}"; do menu_items+=("$i" "$it"); i=$((i+1)); done
    local outfile; outfile=$(mktemp)
    dialog --backtitle "BLG by ~JADIS" --title "Main Menu" --no-tags --menu "$prompt" 0 0 0 "${menu_items[@]}" 2>"$outfile" || { rm -f "$outfile"; return 1; }
    local idx; idx=$(<"$outfile"); rm -f "$outfile"; [ -n "$idx" ] && echo "${items[$((idx-1))]}"; return 0
  elif have fzf; then
    printf "%s\n" "${items[@]}" | fzf --prompt="${prompt}> " --height=80% --reverse
  else
    say "${C_BOLD}${prompt}${C_RESET}"
    local i=1; for it in "${items[@]}"; do printf " %2d) %s\n" "$i" "$it"; i=$((i+1)); done
    printf "Select [1-%d]: " "${#items[@]}"; read -r sel
    [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#items[@]}" ] && echo "${items[$((sel-1))]}"
  fi
}

choose_one(){
  local prompt="$1"; shift
  local items=("$@")
  [ "${#items[@]}" -gt 0 ] || { warn "No options for ${prompt}"; return 1; }

  if have fzf; then
    local fzf_colors="fg:#C8D0E0,bg:#0A0C10,hl:#00FFFF,fg+:#FFFFFF,bg+:#10131A,hl+:#00FFFF,header:#FF00FF,info:#A0AABB,pointer:#00FFFF,marker:#00FF7F,spinner:#00FFFF,prompt:#FF00FF"
    local header=" BLG by ~JADIS — Main Menu (F1 Help • F2 Refresh • F3 BLG • F10 Back)"
    printf "%s\n" "${items[@]}" | fzf \
      --ansi \
      --color="${fzf_colors}" \
      --layout=reverse --height=90% --border=rounded --margin=1 \
      --header="${header}" --header-first \
      --bind='F1:toggle-help' \
      --bind='F2:reload:echo -n' \
      --bind="F3:execute-silent(bash -c '${0} blg')" \
      --bind='F10:abort'
  elif have gum; then
    GUM_BORDER_FOREGROUND="99" GUM_BORDER="rounded" GUM_ALIGN="left" GUM_HEIGHT="20" GUM_WIDTH="80" \
    gum choose --cursor.foreground="cyan" --item.foreground="240" --header="${prompt}" --header.foreground="magenta" "${items[@]}"
  else
    choose_one_basic "$prompt" "${items[@]}"
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
      "0) Install Dependencies") install_dependencies ;;
      "1) HuggingFace Login")     [ -x "${REPO_ROOT}/scripts/main_menu/preinstall_hf.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/preinstall_hf.sh" || { have hf && hf auth login || warn "hf not found"; } ;;
      "2) GitHub HTTPS Token Login") [ -x "${REPO_ROOT}/scripts/main_menu/env.sh" ] && bash "${REPO_ROOT}/scripts/main_menu/env.sh" || { have gh && gh auth login || warn "gh not found"; } ;;
      "3) GitHub SSH Login (Gens Key)") [ -x "${REPO_ROOT}/scripts/aliases_install.sh" ] && bash "${REPO_ROOT}/scripts/aliases_install.sh" || { ssh-keygen -t ed25519 -f "${HOME}/.ssh/id_ed25519" -N "" || true; } ;;
      "4) Verify Logins")         verify_logins_menu ;;
      "5) Install Engines")       catalog_install_engines ;;
      "6) Install Models")        catalog_install_models ;;
      "7) Install blux Shiv")     install_blux_shiv ;;
      "8) Open Plugin Menu")      open_plugin_menu ;;
      "9) Open Scripts Menu")     open_scripts_menu ;;
      "10) Open BLG Textual TUI") blg_menu ;;
      "11) Log Menu")             log_menu ;;
      "12) Cloud / Heart System") [ -x "${REPO_ROOT}/scripts/cloud/admin.sh" ] && bash "${REPO_ROOT}/scripts/cloud/admin.sh" || warn "scripts/cloud/admin.sh missing" ;;
      "13) Admin")                [ -x "${REPO_ROOT}/scripts/diagnostics.sh" ] && bash "${REPO_ROOT}/scripts/diagnostics.sh" || warn "scripts/diagnostics.sh missing" ;;
      "14) blux --help cmd tree") { have python3 && python3 -m blux.cli --help; } || warn "cli help unavailable" ;;
      "Q) Quit")                  exit 0 ;;
      *)                          exit 0 ;;
    esac
  done
}

# -----------------------------
# CLI routing
# -----------------------------
if [ $# -gt 0 ]; then
  case "$1" in
    blg|--blg|-j)       shift; blg_menu "$@"; exit $? ;;
    plugins|--plugins)  shift; open_plugin_menu "$@"; exit $? ;;
    scripts|--scripts)  shift; open_scripts_menu "$@"; exit $? ;;
  esac
fi

# -----------------------------
# Boot sequence
# -----------------------------
ensure_dirs
start_logging
load_secrets
router_reload
main_menu

# Optional: auto-launch BLG TUI after main menu (disable with BLG_NO_AUTO_TUI=1)
if [ -z "${BLG_NO_AUTO_TUI:-}" ]; then
  blg_menu || true
fi

# BLUX catalogs quick entry (calls TUI shell's picker if available)
blg_catalogs(){
  if [ -f "${REPO_ROOT}/scripts/tui/menu.sh" ]; then
    bash "${REPO_ROOT}/scripts/tui/menu.sh" catalogs_install_picker || true
  else
    python -m blux.catalog_install models
  fi
}

# --- BLUX system scripts (common/logging) ---
if [ -f "${REPO_ROOT}/scripts/main_menu/common.sh" ]; then
  . "${REPO_ROOT}/scripts/main_menu/common.sh"
fi
if [ -f "${REPO_ROOT}/scripts/main_menu/logging.sh" ]; then
  . "${REPO_ROOT}/scripts/main_menu/logging.sh"
fi
