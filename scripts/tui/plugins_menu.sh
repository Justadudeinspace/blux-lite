#!/usr/bin/env bash
# BLUX Lite GOLD — TUI Plugins Master (Cosmic Dark Theme)
# Sections: Plugins / Scripts / CLI / Setup / Engines / Models / Diagnostics / Logging/Debug / About / Quit

set -euo pipefail
IFS=$'\n\t'

# ---------- cosmic theme ----------
ESC=$'\033'; RESET="${ESC}[0m"
FG1="${ESC}[38;2;185;156;255m"   # lilac
FG2="${ESC}[38;2;124;205;255m"   # icy-blue
FG3="${ESC}[38;2;255;128;255m"   # magenta
FGD="${ESC}[38;2;180;190;200m"   # gray-blue
DIM="${ESC}[2m"; BOLD="${ESC}[1m"

line(){ printf "${FG3}${BOLD}────────────────────────────────────────────────────────────────────${RESET}\n"; }

banner() {
  printf "${FG3}${BOLD}┌──────────────────────────────────────────────┐${RESET}\n"
  printf "${FG3}${BOLD}│${RESET} ${FG1}BLUX Lite GOLD${RESET}\n"
  printf "${FG3}${BOLD}│${RESET} ${DIM}${FGD}(Plugins)${RESET}\n"
  printf "${FG3}${BOLD}└──────────────────────────────────────────────┘${RESET}\n"
}

# ---------- load common runners ----------
ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]-$0}")" && pwd -P)/.."
# shellcheck disable=SC1091
source "${ROOT}/lib/menu_common.sh"

# ---------- runtime flags & quick stats ----------
CONFIG_DIR="$(cd -- "${ROOT}/../.config/blux-lite" 2>/dev/null || true; pwd -P || true)"
RUNTIME_ENV="${CONFIG_DIR}/runtime.env"
[ -f "$RUNTIME_ENV" ] && set -a && . "$RUNTIME_ENV" && set +a

count_scripts(){ discover_scripts | wc -l | tr -d '[:space:]'; }
count_plugins(){ discover_plugins | wc -l | tr -d '[:space:]'; }
dashboard(){
  printf "${FGD}${DIM}UI:${RESET} ${FG1}TUI${RESET}   "
  printf "${FGD}${DIM}Plugins:${RESET} ${FG2}%s${RESET}   " "$(count_plugins)"
  printf "${FGD}${DIM}Scripts:${RESET} ${FG2}%s${RESET}   " "$(count_scripts)"
  printf "${FGD}${DIM}Debug:${RESET} ${FG2}%s${RESET}   " "${BLG_DEBUG:-0}"
  printf "${FGD}${DIM}Log:${RESET} ${FG2}%s${RESET}   " "${BLG_LOG:-1}"
  printf "${FGD}${DIM}PyLog:${RESET} ${FG2}%s${RESET}\n" "${BLUX_LOG_LEVEL:-INFO}"
}
pause(){ read -r -p "Press Enter..." _ || true; }

# ---------- toggle helpers (persist in runtime.env) ----------
set_flag(){ local k="$1" v="$2"; mkdir -p "${CONFIG_DIR}"; touch "$RUNTIME_ENV"
  if grep -qE "^[[:space:]]*${k}=" "$RUNTIME_ENV"; then sed -i.bak -E "s#^[[:space:]]*${k}=.*#${k}=${v}#g" "$RUNTIME_ENV"
  else printf '%s=%s\n' "$k" "$v" >> "$RUNTIME_ENV"; fi; }
toggle_debug(){ [ "${BLG_DEBUG:-0}" = "1" ] && set_flag BLG_DEBUG 0 && say "Debug OFF" || { set_flag BLG_DEBUG 1; say "Debug ON"; }; }
toggle_logging(){ [ "${BLG_LOG:-1}" = "1" ] && set_flag BLG_LOG 0 && say "Logging OFF" || { set_flag BLG_LOG 1; say "Logging ON"; }; }
set_log_level(){ local lvls=("DEBUG" "INFO" "WARNING" "ERROR") lvl; lvl="$(pick_one 'Set Python log level' "${lvls[@]}")" || return 0; set_flag BLUX_LOG_LEVEL "$lvl"; say "Python log level → $lvl"; }

# ---------- fzf picker (local override: header + right preview) ----------
choose_one() {
  local prompt="$1"; shift
  local items=("$@")
  if ! command -v fzf >/dev/null 2>&1; then pick_one "$prompt" "${items[@]}"; return; fi

  local fzf_colors="fg:#C8D0E0,bg:#0A0C10,hl:#00FFFF,fg+:#FFFFFF,bg+:#10131A,hl+:#00FFFF,header:#FF00FF,info:#A0AABB,pointer:#00FFFF,marker:#00FF7F,spinner:#00FFFF,prompt:#FF00FF"
  local header=" BLG by ~JADIS — ${prompt}  (F1 Preview • F2 Refresh • F3 BLG • F10 Back)"
  local BASE_DIR="${ROOT}/../plugins"

  local preview_cmd='bash -c '\''
ITEM="$1"; BASE="$2"; TARGET="$ITEM"; [ -f "$TARGET" ] || TARGET="$BASE/$ITEM";
if [ -f "$TARGET" ]; then
  if command -v bat >/dev/null 2>&1; then
    BAT_THEME="${BAT_THEME:-OneHalfDark}" BAT_STYLE="plain" bat --style="plain" --theme="${BAT_THEME}" --paging=never --color=always "$TARGET" 2>/dev/null || head -n 80 "$TARGET"
  else
    head -n 80 "$TARGET"
  fi
else echo "No preview"; fi'\'' _ {} '"$BASE_DIR"

  printf "%s\n" "${items[@]}" | fzf \
    --ansi \
    --color="${fzf_colors}" \
    --layout=reverse --height=90% --border=rounded --margin=1 \
    --header="${header}" --header-first \
    --preview="${preview_cmd}" --preview-window="right,60%,border-rounded" \
    --bind='F1:toggle-preview' \
    --bind='F2:reload:echo -n' \
    --bind="F3:execute-silent( ROOT_PATH='${ROOT}' bash -c ' \
      [ -f \"${ROOT}/../scripts/main_menu/logging.sh\" ] && . \"${ROOT}/../scripts/main_menu/logging.sh\" || true; \
      if [ -x \"${ROOT}/../scripts/blg_tui.sh\" ]; then \
        \"${ROOT}/../scripts/blg_tui.sh\"; \
      else \
        python3 -m blux.tui_blg; \
      fi' )+abort" \
    --bind='F10:abort' \
    --prompt="${prompt}> "
}

# ---------- submenus ----------
menu_setup(){ while true; do local items=("HuggingFace login" "Validate secrets" "Back")
  local sel; sel="$(pick_one 'Setup / Integrations' "${items[@]}")" || return 0
  case "$sel" in "HuggingFace login")  run_cli "hf-login" ;;
                 "Validate secrets")   run_cli "secrets-validate" ;;
                 "Back") return 0 ;; esac; pause; done; }
menu_engines(){ run_cli "install-engines"; pause; }
menu_models(){  run_cli "install-models";  pause; }
menu_diag(){    run_cli "doctor";          pause; }
menu_logdbg(){ while true; do local items=("Toggle Debug (shell)" "Toggle Logging (shell)" "Set Python log level" "Back")
  local sel; sel="$(pick_one 'Logging & Debug' "${items[@]}")" || return 0
  case "$sel" in "Toggle Debug (shell)") toggle_debug ;;
               "Toggle Logging (shell)") toggle_logging ;;
               "Set Python log level")   set_log_level ;;
               "Back") return 0 ;; esac; pause; done; }
menu_about(){ clear; banner; dashboard; line; printf "${FGD}${DIM}This is the ${RESET}${FG1}TUI / Plugins${RESET}${FGD}${DIM} lens of BLUX.\n${RESET}"; pause; }

# ---------- main ----------
while true; do
  clear
  banner
  dashboard
  line

  sections=( ... )
  sel="$(choose_one 'BLUX Lite GOLD — TUI (Plugins)' "${sections[@]}")" || exit 0
  ...
done