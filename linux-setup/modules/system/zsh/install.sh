#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os
echo "Installing Zsh..."
install_packages zsh

# Change default shell to Zsh (only if not already zsh)
CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    ZSH_PATH=$(command -v zsh)
    if [[ -n "$ZSH_PATH" ]]; then
        echo "Changing default shell to Zsh..."
        # Ensure zsh is in /etc/shells
        if ! grep -q "^$ZSH_PATH$" /etc/shells 2>/dev/null; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
        fi
        # Use usermod instead of chsh (chsh requires password input)
        if sudo usermod -s "$ZSH_PATH" "$USER" 2>/dev/null; then
            echo "⚠️  Default shell changed to Zsh (Requires re-login to take effect)"
        else
            echo "⚠️  Could not change default shell automatically."
            echo "   Run manually: chsh -s $ZSH_PATH"
        fi
    fi
else
    echo "✅ Zsh is already the default shell"
fi

echo "✅ Zsh installation complete"
