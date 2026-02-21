#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

VARIANT="${1:-engine}"

wait_for_ollama() {
    local attempt=0
    while ! ollama list &>/dev/null; do
        ((attempt++))
        if [ "$attempt" -gt 10 ]; then
            echo "❌ Cannot connect to Ollama service."
            exit 1
        fi
        echo "⏳ Waiting for service response... ($attempt/10)"
        sleep 2
    done
}

install_engine() {
    echo "🦙 Installing Ollama..."

    if command -v ollama &>/dev/null; then
        echo "✅ Ollama is already installed."
    else
        curl -fsSL https://ollama.com/install.sh | sh
    fi

    if systemctl is-active --quiet ollama; then
        echo "✅ Ollama service is running."
    else
        echo "⚙️  Starting Ollama service..."
        sudo systemctl enable --now ollama || true
    fi

    echo "🎉 Ollama Engine installation complete"
}

pull_model() {
    local model="$1"
    echo "📥 Downloading Ollama model: $model"
    install_engine
    wait_for_ollama
    ollama pull "$model"
    echo "✅ Model ready: $model"
}

case "$VARIANT" in
    engine)
        install_engine
        ;;
    llama3.3|deepseek-r1:32b|qwen2.5-coder:32b|phi4|llama3.2:3b|gemma2:2b|phi3:mini)
        pull_model "$VARIANT"
        ;;
    *)
        echo "❌ Unknown Ollama variant: $VARIANT"
        exit 1
        ;;
esac