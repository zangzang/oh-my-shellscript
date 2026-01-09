#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/core.sh"

log_info "Installing Tauri dependencies..."

# Tauri on Linux requires these dependencies
# https://tauri.app/start/prerequisites/#linux

PACKAGES=(
  "libgtk-3-dev"           # GTK 3 development files
  "libglib2.0-dev"         # GLib development files
  "libwebkit2gtk-4.1-dev"  # WebKit2 development files (for newer systems)
  "librsvg2-dev"           # SVG rendering
  "libssl-dev"             # OpenSSL (usually already installed)
  "pkg-config"             # Package configuration utility (usually already installed)
)

log_info "Installing required packages: ${PACKAGES[*]}"
sudo apt update -qq
sudo apt install -y "${PACKAGES[@]}" 2>&1 | grep -E "(^Setting|^Processing|upgraded|installed|^$)" || true

log_success "Tauri dependencies installed successfully"
