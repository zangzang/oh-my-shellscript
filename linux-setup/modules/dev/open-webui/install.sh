#!/bin/bash
set -e

# Load Library
if ! command -v ui_log_info &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

echo "🌐 Installing Open WebUI (Docker)..."

# Check GPU support
GPU_FLAG=""
if command -v nvidia-smi &>/dev/null; then
    echo "✨ Running in GPU acceleration mode."
    GPU_FLAG="--gpus all"
fi

# Helper to run docker with or without sudo
run_docker() {
    if docker ps &>/dev/null; then
        docker "$@"
    else
        sudo docker "$@"
    fi
}

# Remove existing container if it exists
if run_docker ps -a --format '{{.Names}}' | grep -q "^open-webui$"; then
    echo "Removing existing open-webui container..."
    run_docker rm -f open-webui
fi

# Run container
# Ollama runs on host, so use host networking or host.docker.internal
echo "Starting Open WebUI container..."
run_docker run -d \
  -p 3000:8080 \
  $GPU_FLAG \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "✅ Open WebUI installation complete!"
echo "🌐 Access via browser: http://localhost:3000"