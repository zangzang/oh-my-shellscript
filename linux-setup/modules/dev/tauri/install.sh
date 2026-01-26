#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/core.sh"

log_info "Installing Tauri system prerequisites..."

detect_os

# Tauri dependencies (https://tauri.app/start/prerequisites/#linux)
PACKAGES=(
  "libgtk-3-dev"           
  "libglib2.0-dev"         
  "libwebkit2gtk-4.1-dev"  
  "librsvg2-dev"           
  "libssl-dev"             
  "pkg-config"             
  "libjavascriptcoregtk-4.1-dev"
  "libsoup2.4-dev"
)

install_packages "${PACKAGES[@]}"

# Load Rust environment
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

if ! command -v cargo &> /dev/null; then
    # Manually try adding to PATH
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if ! command -v cargo &> /dev/null; then
    log_error "Cargo (Rust) not found. Please verify 'dev.rust' module is installed."
    exit 1
fi

# Install Tauri CLI
if ! command -v tauri &> /dev/null; then
    ui_log_info "📦 Installing Tauri CLI via npm (Fastest method)..."
    npm_install_g "@tauri-apps/cli"
else
    ui_log_info "✅ Tauri CLI is already installed."
fi

# Fallback/Additional check for cargo-tauri if specifically needed
if ! command -v cargo-tauri &> /dev/null; then
    ui_log_info "💡 Note: You can also install the Rust-native CLI later with 'cargo install tauri-cli' if desired."
fi

log_success "Tauri development environment setup complete"
