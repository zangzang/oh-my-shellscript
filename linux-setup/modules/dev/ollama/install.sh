#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

echo "🦙 Installing Ollama..."

# Check essential dependencies (awk, curl, zstd)
echo "📦 Checking essential dependencies..."
install_packages curl gawk zstd

if command -v ollama &>/dev/null; then
    echo "✅ Ollama is already installed."
else
    # Run official installation script
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Check service status
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama service is running."
else
    echo "⚙️  Starting Ollama service..."
    sudo systemctl enable --now ollama || true
fi

echo "🎉 Ollama Engine installation complete"