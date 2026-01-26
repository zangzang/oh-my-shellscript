#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/core.sh"

detect_os

if command -v dbeaver &>/dev/null; then
    echo "✅ DBeaver is already installed."
    exit 0
fi

echo "Installing DBeaver Universal Database Tool..."

if [ "$OS_ID" == "fedora" ]; then
    # Remove old broken DBeaver repo if exists
    if [ -f /etc/yum.repos.d/dbeaver.repo ]; then
        echo "Removing old DBeaver repo (no longer available)..."
        sudo rm -f /etc/yum.repos.d/dbeaver.repo
    fi
    
    # Fedora: Use Flatpak (official recommended method)
    if ! command -v flatpak &>/dev/null; then
        sudo dnf install -y flatpak
    fi
    
    # Try system-wide first, fall back to user install
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || \
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    if flatpak install -y flathub io.dbeaver.DBeaverCommunity 2>/dev/null || \
       flatpak install --user -y flathub io.dbeaver.DBeaverCommunity; then
        echo "✅ DBeaver installed via Flatpak"
        echo "   Run with: flatpak run io.dbeaver.DBeaverCommunity"
    else
        echo "❌ Failed to install DBeaver via Flatpak"
        exit 1
    fi
    exit 0
else
    # DBeaver Community Edition (Ubuntu/Debian)
    sudo mkdir -p /etc/apt/keyrings
    wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/dbeaver.gpg --batch --yes
    echo "deb [signed-by=/etc/apt/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
    sudo apt update
    sudo apt install -y dbeaver-ce
fi
echo "✅ DBeaver installation complete"
