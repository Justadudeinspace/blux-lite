#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "📦 Updating packages..."
pkg update -y && pkg upgrade -y
pkg install python git curl termux-api nano -y
termux-setup-storage

echo "🔌 Installing Python dependencies..."
pip install --no-cache-dir ollama-python

echo "📂 Cloning BLUX repo (if missing)..."
[ ! -d "$HOME/blux-lite" ] && git clone https://github.com/Justadudeinspace/blux-lite.git ~/blux-lite
cd ~/blux-lite

echo "🧹 Cleaning bad pip install lines (if exist)..."
sed -i '/pip install pip/d' blux_lite.sh || true

echo "🧠 Installing Ollama..."
pkg install ollama -y

echo "⚙️ Starting Ollama..."
termux-wake-lock
ollama serve &

sleep 3

echo "⬇️ Running model installer..."
bash install_models.sh


echo "🔊 Checking Termux API voice plugin..."
if ! command -v termux-tts-speak >/dev/null; then
  echo "⚠️ Voice plugin not installed. Install Termux:API from F-Droid."
else
  termux-tts-speak "BLUX-Lite voice is ready"
fi

echo "🎤 Say your command if ready:"
if command -v termux-speech-to-text >/dev/null; then
  USER_INPUT=$(termux-speech-to-text)
  echo "🎧 Heard: $USER_INPUT"
fi

echo "🧠 Launching LLM chat..."
python3 llama_chat.py
