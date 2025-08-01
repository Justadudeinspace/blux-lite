#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🧠 Pulling best open-source coding models..."

# Models in order of coding performance
MODELS=("codegemma" "phi3" "llama3" "mistral")

for model in "${MODELS[@]}"; do
  echo "⬇️ Pulling: $model"
  if ollama pull "$model"; then
    echo "✅ Pulled $model"
  else
    echo "⚠️ Failed to pull $model — skipping"
  fi
done
