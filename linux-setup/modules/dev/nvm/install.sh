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

export NVM_DIR="$HOME/.nvm"

if [ -d "$NVM_DIR" ]; then
    ui_log_info "NVM is already installed at $NVM_DIR."
    
    # Load NVM to check
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v nvm &>/dev/null; then
        ui_log_success "NVM version $(nvm --version) is active."
        exit 0
    else
        ui_log_warn "NVM directory exists but 'nvm' command not found. Re-installing..."
    fi
fi

ui_log_info "Installing NVM (Node Version Manager)..."

# Ensure curl is available
if ! command -v curl &>/dev/null; then
    ui_log_info "curl is required for NVM installation. Installing..."
    if ! install_packages "curl"; then
        ui_log_error "Failed to install curl. Cannot proceed with NVM installation."
        exit 1
    fi
fi

# Install NVM
# Using v0.39.7 as a stable version
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM for the current session
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvm &>/dev/null; then
    ui_log_success "NVM installation complete. Version: $(nvm --version)"
else
    ui_log_error "NVM installation failed or could not be loaded."
    exit 1
fi

ui_log_info "Note: You may need to restart your shell or run 'source ~/.bashrc' (or equivalent) to use nvm."