#!/bin/bash
set -e
VERSION="${1:-lts}"

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

if [ -z "${OS_ID:-}" ]; then
    detect_os
fi

# Attempt System Package Installation
echo "📦 Attempting to install Node.js via system package..."

TRY_NATIVE=false
if [[ "$OS_ID" == "fedora" ]]; then
    # Fedora includes npm in nodejs
    if install_packages "nodejs"; then
        TRY_NATIVE=true
    fi
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Ubuntu often separates nodejs and npm
    # Using OS-provided version without NodeSource
    if install_packages "nodejs" "npm"; then
        TRY_NATIVE=true
    fi
fi

if [[ "$TRY_NATIVE" == "true" ]]; then
    echo "✅ Node.js (System) installation complete"
    node -v
    npm -v
    exit 0
fi

echo "⚠️  System package installation failed or unsupported OS. Trying Fallback (NVM)..."

# Fallback: NVM
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v nvm &>/dev/null; then
    echo "❌ Failed to load NVM"
    exit 1
fi

case "$VERSION" in
    lts) TARGET="--lts" ;;
    current|latest) TARGET="node" ;;
    *) TARGET="$VERSION" ;;
esac

echo "Installing Node.js via NVM: $TARGET"
nvm install "$TARGET"
nvm use "$TARGET"
nvm alias default "$TARGET"
