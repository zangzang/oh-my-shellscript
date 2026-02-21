#!/bin/bash
set -e

if command -v oh-my-posh &>/dev/null; then
    echo "Oh My Posh is already installed ($(oh-my-posh version))"
    exit 0
fi

echo "Installing Oh My Posh..."
sudo wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

# Create theme directory and download Catppuccin Mocha theme
OMP_THEME_DIR="$HOME/.config/oh-my-posh"
mkdir -p "$OMP_THEME_DIR"

if [ ! -f "$OMP_THEME_DIR/catppuccin_mocha.omp.json" ]; then
    echo "Downloading Catppuccin Mocha theme..."
    wget -q https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json \
        -O "$OMP_THEME_DIR/catppuccin_mocha.omp.json"
fi

# Configure .bashrc
echo "Configuring .bashrc..."
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "oh-my-posh init bash" "$HOME/.bashrc"; then
        cat <<'BASHRC_OMP' >> ~/.bashrc

# =============================================================================
# Oh My Posh
# =============================================================================

if command -v oh-my-posh &> /dev/null; then
    if [ -f "$HOME/.config/oh-my-posh/catppuccin_mocha.omp.json" ]; then
        eval "$(oh-my-posh init bash --config $HOME/.config/oh-my-posh/catppuccin_mocha.omp.json)"
    fi
fi
BASHRC_OMP
        echo ".bashrc configuration added"
    fi
fi

# Configure .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    echo "Configuring .zshrc..."
    if ! grep -q "oh-my-posh init zsh" "$HOME/.zshrc"; then
        cat <<'ZSHRC_OMP' >> ~/.zshrc

# =============================================================================
# Oh My Posh
# =============================================================================

if command -v oh-my-posh &> /dev/null; then
    if [ -f "$HOME/.config/oh-my-posh/catppuccin_mocha.omp.json" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/catppuccin_mocha.omp.json)"
    fi
fi
ZSHRC_OMP
        echo ".zshrc configuration added"
    fi
fi

echo "Oh My Posh installation complete"
