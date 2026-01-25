#!/bin/bash
set -e

MODEL="${1:-llama3.1}"

echo "📥 Downloading Medium/Large Ollama model: $MODEL"

# Wait for Ollama service to respond
attempt=0
while ! ollama list &>/dev/null; do
    ((attempt++))
    if [ $attempt -gt 10 ]; then
        echo "❌ Cannot connect to Ollama service."
        exit 1
    fi
    echo "⏳ Waiting for service response... ($attempt/10)"
    sleep 2
done

# Download model
ollama pull "$MODEL"

echo "✅ Model ready: $MODEL"
