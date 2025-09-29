
# ©️ BLUX Lite GOLD — Installation

## 1. Prerequisites (Termux)

```bash
pkg update && pkg upgrade -y
pkg install python git curl proot-distro termux-api nano -y
pip install --upgrade pip
termux-setup-storage
```

1. Clone & Bootstrap

```bash
git clone https://github.com/Justadudeinspace/blux-lite.git
cd blux-lite
chmod +x first_start.sh
./first_start.sh
```

This will:

Create `.venv/` Python environment

Install dependencies from `requirements.txt`

Prepare `.config/blux-lite-gold/` runtime folders

Generate `auto-start.sh`


1. Run BLUX

```bash
./auto-start.sh
```

This activates the environment and launches `blux-lite.sh` (Legacy/TUI selector).

1. Voice & CLI Modes

```bash
Voice Mode (Termux microphone):

python -m blux.blux_voice

CLI Orchestrator:

python -m blux.cli --help
```

1. (Optional) Ubuntu + Ollama (proot-distro)

```bash
proot-distro login ubuntu
apt update && apt install curl python3 nano -y
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3:instruct
apt install ddgr -y
pip3 install requests

Then run:

ollama serve &
python -m blux.cli
```

---

