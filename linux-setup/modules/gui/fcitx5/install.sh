#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Installing Fcitx5 and Korean configuration..."

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    install_packages fcitx5 fcitx5-hangul fcitx5-config-qt
elif [[ "$OS_ID" == "fedora" ]]; then
    install_packages fcitx5 fcitx5-hangul fcitx5-qt
fi

echo "Fcitx5 installation complete. Please re-login to apply changes."

# Configure .bashrc
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "GTK_IM_MODULE.*fcitx" "$HOME/.bashrc"; then
        cat <<'BASHRC_FCITX5' >> ~/.bashrc

# Input Method (Fcitx5)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
export MOZ_ENABLE_WAYLAND=1
BASHRC_FCITX5
        echo "✓ .bashrc configured"
    fi
fi

# Configure .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "GTK_IM_MODULE.*fcitx" "$HOME/.zshrc"; then
        cat <<'ZSHRC_FCITX5' >> ~/.zshrc

# Input Method (Fcitx5)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
export MOZ_ENABLE_WAYLAND=1
ZSHRC_FCITX5
        echo "✓ .zshrc configured"
    fi
fi
