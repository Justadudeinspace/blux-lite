#!/data/data/com.termux/files/usr/bin/bash

MODEL="codegemma"

if [ -z "$1" ]; then
  echo "Usage: ./blux_api.sh 'your prompt here'"
  exit 1
fi

PROMPT="$1"
echo "Sending to $MODEL..."
echo

RESPONSE=$(ollama run "$MODEL" "$PROMPT")
echo "BLUX-API Response:"
echo "$RESPONSE"
