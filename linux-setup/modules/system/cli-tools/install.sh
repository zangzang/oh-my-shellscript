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

if [ -z "${OS_ID:-}" ]; then
    detect_os
fi

ui_log_info "Installing essential CLI tools..."

# Package mapping and preparation
PACKAGES=(jq tree htop btop ncdu mc ripgrep fd-find fzf vim nano)

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    PACKAGES+=(bat eza)
    
    # Eza repository for Ubuntu
    if ! command -v eza &>/dev/null; then
        ui_log_info "Adding eza repository..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --batch --yes
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo apt update
    fi
elif [[ "$OS_ID" == "fedora" ]]; then
    PACKAGES+=(bat eza)
fi

install_packages "${PACKAGES[@]}"

ui_log_success "CLI tools installation complete."