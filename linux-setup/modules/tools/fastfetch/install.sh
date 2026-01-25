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

if command -v fastfetch &>/dev/null; then
    ui_log_info "Fastfetch is already installed."
    exit 0
fi

ui_log_info "Installing Fastfetch..."

detect_os

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # For older Ubuntu versions, we might need a PPA, but 22.04+ has it or we can use the GitHub release
    if ! sudo apt-get install -y fastfetch 2>/dev/null; then
        ui_log_info "Apt install failed, trying to install from GitHub releases..."
        TEMP_DEB="/tmp/fastfetch.deb"
        # Get latest version for Linux x86_64 deb
        URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url.*linux-amd64.deb" | cut -d '"' -f 4)
        if [ -n "$URL" ]; then
            curl -L -o "$TEMP_DEB" "$URL"
            sudo apt-get install -y "$TEMP_DEB"
            rm "$TEMP_DEB"
        else
            ui_log_error "Could not find Fastfetch deb package in GitHub releases."
            exit 1
        fi
    fi
elif [[ "$OS_ID" == "fedora" ]]; then
    sudo dnf install -y fastfetch
else
    ui_log_error "Unsupported OS for automatic Fastfetch installation: $OS_ID"
    exit 1
fi

ui_log_success "Fastfetch installation complete."