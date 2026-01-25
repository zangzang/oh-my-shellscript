#!/bin/bash
set -e

# Load Library
if ! command -v ui_log_info &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Check if Meslo Nerd Font is already installed
if ls "$FONT_DIR"/MesloLGS*NF*.ttf &>/dev/null; then
    ui_log_info "Meslo Nerd Font is already installed."
    exit 0
fi

ui_log_info "Downloading Meslo Nerd Font..."

# Use MesloLGS NF (commonly used for Oh My Posh/Powerlevel10k)
URLS=(
    "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/MesloLGS%20NF%20Bold%20Italic.ttf"
)

for url in "${URLS[@]}"; do
    filename=$(basename "$url" | sed 's/%20/ /g')
    ui_log_info "  ➜ $filename"
    curl -L -s -o "$FONT_DIR/$filename" "$url"
done

ui_log_info "Updating font cache..."
if command -v fc-cache &>/dev/null; then
    fc-cache -f "$FONT_DIR"
fi

ui_log_success "Meslo Nerd Font installation complete"