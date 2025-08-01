#!/data/data/com.termux/files/usr/bin/bash
echo "🚀 Starting LiteLLM local proxy on port 4000"
nohup litellm proxy --model ollama/codegemma --port 4000 --debug > ~/blux-lite/.litellm.log 2>&1 &
