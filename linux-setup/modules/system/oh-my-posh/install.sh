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

echo "Oh My Posh installation complete"
