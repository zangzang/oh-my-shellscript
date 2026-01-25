#!/bin/bash
set -e
if command -v docker &>/dev/null; then
echo "Docker is already installed."
echo "Installing Docker..."
# ...
echo "Docker installation complete."
echo "✅ Docker service started"
echo "⚠️  Re-login required to use 'docker' command without sudo."
echo "Docker installation failed"
    exit 1
fi
