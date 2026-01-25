#!/bin/bash
set -e

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "🟢 Setting up NVIDIA GPU environment..."

# 1. Driver Check
if ! command -v nvidia-smi &>/dev/null; then
    echo "⚠️  NVIDIA driver not detected."
    echo "   To install, run the following command separately:"
    if [[ "$OS_ID" == "fedora" ]]; then
        echo "   sudo dnf install akmod-nvidia"
    else
        echo "   sudo ubuntu-drivers autoinstall"
    fi
    echo "------------------------------------------"
fi

# 2. Install NVIDIA Container Toolkit (for Docker)
echo "📦 Installing NVIDIA Container Toolkit..."
if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt update && sudo apt install -y nvidia-container-toolkit
elif [[ "$OS_ID" == "fedora" ]]; then
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
        sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    sudo dnf install -y nvidia-container-toolkit
fi

# 3. Restart Docker
echo "🔄 Restarting Docker to enable GPU support..."
sudo systemctl restart docker

echo "✅ NVIDIA environment setup complete"