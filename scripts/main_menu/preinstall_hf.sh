#!/usr/bin/env bash
[ "${BLG_DEBUG:-0}" = "1" ] && set -x
set -euo pipefail
IFS=$'\n\t'

: "${BLG_ENABLE_CLOUD:=0}"
if [[ "${BLG_ENABLE_CLOUD}" != "1" ]]; then
  echo "[BLUX] Cloud helpers are disabled. Set BLG_ENABLE_CLOUD=1 to enable." >&2
  exit 0
fi

# preinstall_hf.sh — prepare git/hf + optional SSH for BLUX Lite
# Style: minimal, readable, loud errors.

have(){ command -v "$1" >/dev/null 2>&1; }

# --- packages ---
if have pkg;
  then
  pkg update -y && pkg install -y git git-lfs openssh python python-pip
elif have apt || have apt-get;
  then
  sudo apt update -y && sudo apt install -y git git-lfs openssh-client python3 python3-pip
elif have pacman;
    then
    sudo pacman -Syu --noconfirm git git-lfs openssh python python-pip
fi
git lfs install --system >/dev/null 2>&1 || git lfs install || true

# Ensure pip user bin is on PATH (Termux/Debian user installs)
if [[ -d "$HOME/.local/bin" && ":$PATH:" != ".*:"$HOME"/.local/bin:" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -x "$ROOT/.venv/bin/python" ]; then
    PYBIN="$ROOT/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYBIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
    PYBIN="$(command -v python)"
else
    PYBIN=""
fi

# --- hf-transfer (optional speed) ---
"$PYBIN" -m pip install --upgrade --user "huggingface_hub[hf]" hf-transfer || true
export HF_HUB_ENABLE_HF_TRANSFER=1

# Prefer 'hf' if present, fallback to huggingface-cli
HF=
if have hf; then HF="hf"
elif have huggingface-cli; then HF="huggingface-cli"
fi

# --- SSH (optional) ---
mkdir -p ~/.ssh && chmod 700 ~/.ssh
[[ -f ~/.ssh/id_hf_ed25519 ]] || ssh-keygen -t ed25519 -N "" -C "hf" -f ~/.ssh/id_hf_ed25519
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_hf_ed25519 || true
ssh-keyscan hf.co >> ~/.ssh/known_hosts 2>/dev/null || true

# --- Token (optional, non-interactive if provided) ---
if [[ -n "${HF_TOKEN:-}" && -n "${HF:-}" ]]; then
  # Works for either 'hf' or 'huggingface-cli'
  $HF login --token "$HF_TOKEN" || true
fi

echo "[OK] Preinstall complete. Use HTTPS by default; set HF_PROTOCOL=ssh to clone via SSH."
