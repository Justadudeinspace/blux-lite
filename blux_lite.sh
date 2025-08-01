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

# Move to proper install path
INSTALL_DIR=~/blux-lite
if [ ! -f "$INSTALL_DIR/README.md" ]; then
    echo "✅ Cloning fresh blux-lite from GitHub..."
    rm -rf "$INSTALL_DIR"
    git clone https://github.com/Justadudeinspace/blux-lite.git "$INSTALL_DIR"
else
    echo "✅ blux-lite already installed in $INSTALL_DIR"
fi

# Copy setup script
cp "$INSTALL_DIR/.blux_ubuntu_setup.sh" ~/

echo "📦 Installing Ubuntu and Ollama..."
proot-distro install ubuntu || true

echo "✅ Setup complete!"
echo "➡ To continue:"
echo "   proot-distro login ubuntu"
echo "   bash ~/blux_ubuntu_setup.sh"
