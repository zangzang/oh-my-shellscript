#!/bin/bash
set -e

# Get the script directory (where themes folder is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$SCRIPT_DIR/themes"
OMP_THEME_DIR="$HOME/.config/oh-my-posh"

# Create theme directory first
mkdir -p "$OMP_THEME_DIR"

# Copy themes from local themes folder (always do this)
echo "Copying themes from $THEMES_DIR to $OMP_THEME_DIR..."
if [ -d "$THEMES_DIR" ]; then
    if [ -z "$(ls -A "$THEMES_DIR")" ]; then
        echo "Error: Themes directory is empty at $THEMES_DIR"
        exit 1
    fi
    cp -v "$THEMES_DIR"/* "$OMP_THEME_DIR/" || {
        echo "Error: Failed to copy themes"
        exit 1
    }
    echo "Themes copied successfully"
else
    echo "Error: Themes directory not found at $THEMES_DIR"
    exit 1
fi

# Check if oh-my-posh is already installed
if command -v oh-my-posh &>/dev/null; then
    echo "Oh My Posh is already installed ($(oh-my-posh version))"
    echo "Oh My Posh installation complete"
    exit 0
fi

echo "Installing Oh My Posh..."
sudo wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

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
