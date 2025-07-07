# ©️ BLUX Sovereign Lite — Installation

## 1. Prerequisites (Termux)

```
pkg update && pkg upgrade -y
pkg install python git curl proot-distro termux-api nano -y
pip install --upgrade pip
termux-setup-storage
```

## 2. Clone & Install

```
git clone https://github.com/Justadudeinspace/blux-sovereign-lite.git
cd blux-sovereign-lite
chmod +x blux_lite.sh
./blux_lite.sh
```

## 3. Ubuntu + Ollama

```
proot-distro login ubuntu
apt update && apt install curl python3 nano -y
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3:instruct
apt install ddgr -y
pip3 install requests
```

## 4. Run BLUX

- `ollama serve &`
- `python3 ~/blux-lite/llama_chat.py`

---

## Voice Mode

- `python3 ~/blux-lite/blux_voice.py`
```
