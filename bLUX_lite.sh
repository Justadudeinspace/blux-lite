## blux_lite.sh

```bash
#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "─────────────────────────────"
echo "BLUX Sovereign Lite Installer"
echo "─────────────────────────────"

# Termux prerequisites
pkg update && pkg upgrade -y
pkg install python git curl proot-distro termux-api nano -y
pip install --upgrade pip
termux-setup-storage

# Clone repo if not already present
if [ ! -d ~/blux-lite ]; then
    mkdir -p ~/blux-lite
    cp -r blux-lite/* ~/blux-lite/
fi

# Ubuntu setup script
cp .blux_ubuntu_setup.sh ~/

echo "Installing Ubuntu and Ollama..."
proot-distro install ubuntu || true

echo "Setup complete!"
echo "To continue:"
echo "  proot-distro login ubuntu"
echo "  bash ~/blux_ubuntu_setup.sh"
```
