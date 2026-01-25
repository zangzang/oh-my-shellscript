#!/bin/bash
set -e

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if [ -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]; then
echo "Meslo Nerd Font is already installed"
# ...
echo "Downloading Meslo Nerd Font..."
# ...
echo "Updating font cache..."
# ...
echo "Meslo Nerd Font installation complete"
