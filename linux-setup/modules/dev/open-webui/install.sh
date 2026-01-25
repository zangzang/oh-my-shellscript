#!/bin/bash
set -e

echo "🌐 Installing Open WebUI (Docker)..."

# Check GPU support
GPU_FLAG=""
if command -v nvidia-smi &>/dev/null; then
    echo "✨ Running in GPU acceleration mode."
    GPU_FLAG="--gpus all"
fi

# Run container
# Ollama runs on host, so use host networking or host.docker.internal
docker run -d \
  -p 3000:8080 \
  $GPU_FLAG \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "✅ Open WebUI installation complete!"
echo "🌐 Access via browser: http://localhost:3000"