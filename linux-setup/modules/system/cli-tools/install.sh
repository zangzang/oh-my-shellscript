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

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Ubuntu/Debian specific packages
    PACKAGES=(jq tree htop btop ncdu mc ripgrep fd-find fzf vim nano bat)
    
    # Eza repository for Ubuntu
    if ! command -v eza &>/dev/null; then
        ui_log_info "Adding eza repository..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --batch --yes
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo apt update
    fi
    PACKAGES+=(eza)
    
    install_packages "${PACKAGES[@]}"

elif [[ "$OS_ID" == "fedora" ]]; then
    # Fedora uses different package names
    # eza is not in default Fedora repos, install via cargo or skip
    PACKAGES=(jq tree htop btop ncdu mc ripgrep fd-find fzf vim-enhanced nano bat)
    install_packages "${PACKAGES[@]}"
    
    # Try to install eza from cargo if available
    if command -v cargo &>/dev/null; then
        ui_log_info "Installing eza via cargo..."
        cargo install eza || ui_log_warn "Failed to install eza"
    else
        ui_log_info "eza not available in Fedora repos. Install rust first for eza."
    fi
else
    ui_log_warn "Unsupported OS: $OS_ID - trying default package names"
    install_packages jq tree htop fzf vim nano
fi

# Verification
if command -v jq &>/dev/null || command -v vim &>/dev/null; then
    ui_log_success "CLI tools installation complete."
else
    ui_log_error "Critical CLI tools (jq, vim) not found. Installation may have failed."
    exit 1
fi