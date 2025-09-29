#!/usr/bin/env bash
IFS=$'\n\t'
set -euo pipefail
## .blux_ubuntu_setup.sh

```bash
#!/bin/bash

set -e

echo "─────────────────────────────"
echo "BLUX Ubuntu AI Bootstrap"
echo "─────────────────────────────"

apt update && apt install curl python3-pip nano -y

# Ollama install
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3:instruct

# Python deps
pip3 install requests

# ddgr for web search
apt install ddgr -y

# Setup BLUX directory
mkdir -p ~/blux-lite/plugins
cp -r /data/data/com.termux/files/home/blux-lite/* ~/blux-lite/ 2>/dev/null || true

echo "BLUX Ubuntu setup complete."
```