#!/bin/bash
set -e

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

# ============================================
# Check if Rust is already installed
# ============================================
if command -v rustc &>/dev/null && command -v cargo &>/dev/null; then
    echo "🔍 Detected Rust version: $(rustc --version)"
    echo "✅ Rust is already installed."
    rustc --version
    cargo --version
    exit 0
fi

echo "📦 Attempting to install Rust via system package..."

PKGS=()
if [[ "$OS_ID" == "fedora" ]]; then
    PKGS=("rust" "cargo")
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    PKGS=("rustc" "cargo")
else
    PKGS=("rustc" "cargo") # Default try
fi

INSTALLED_NATIVE=false
if install_packages "${PKGS[@]}"; then
    echo "✅ Rust system package installed"
    INSTALLED_NATIVE=true
else
    echo "⚠️  System package installation failed. Switching to fallback mode."
fi

if [[ "$INSTALLED_NATIVE" == "true" ]]; then
    exit 0
fi

# Fallback: Rustup
echo "🔄 Attempting installation via Rustup..."
export CARGO_HOME="$HOME/.cargo"

if command -v cargo &>/dev/null; then
    echo "Rust is already installed."
    exit 0
fi

if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    echo "Rust installation complete (Rustup)"
else
    echo "❌ Rust installation failed"
    exit 1
fi
# Configure .bashrc
echo "🔧 Configuring .bashrc for Rust..."
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "cargo/env" "$HOME/.bashrc"; then
        cat <<'BASHRC_RUST' >> ~/.bashrc

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
BASHRC_RUST
        echo "✓ .bashrc configured"
    fi
fi

# Configure .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    echo "🔧 Configuring .zshrc for Rust..."
    if ! grep -q "cargo/env" "$HOME/.zshrc"; then
        cat <<'ZSHRC_RUST' >> ~/.zshrc

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
ZSHRC_RUST
        echo "✓ .zshrc configured"
    fi
fi