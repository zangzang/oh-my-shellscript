#!/bin/bash
set -e
VERSION="${1:-3.12}"

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "📦 Attempting to install Python $VERSION via system package..."

# Determine package name
MAIN_PKG=""
if [[ "$VERSION" =~ ^3\.[0-9]+$ ]]; then
    MAIN_PKG="python$VERSION"
elif [[ "$VERSION" == "3" ]]; then
    MAIN_PKG="python3"
else
    # Try shortening 3.12.1 to 3.12
    SHORT_VER=$(echo "$VERSION" | cut -d. -f1,2)
    MAIN_PKG="python$SHORT_VER"
fi

INSTALLED_NATIVE=false

# 1. Install System Package
if install_packages "$MAIN_PKG"; then
    echo "✅ Python base package ($MAIN_PKG) installed successfully"
    INSTALLED_NATIVE=true
    
    # Install additional packages (venv, dev, pip)
    EXTRAS=()
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
        EXTRAS+=("$MAIN_PKG-venv" "$MAIN_PKG-dev" "python3-pip")
    elif [[ "$OS_ID" == "fedora" ]]; then
        EXTRAS+=("$MAIN_PKG-devel" "python3-pip")
    fi
    
    if [ ${#EXTRAS[@]} -gt 0 ]; then
        install_packages "${EXTRAS[@]}" || echo "⚠️  Some additional Python packages failed to install (non-critical)"
    fi
else
    echo "⚠️  System package ($MAIN_PKG) failed to install or not found."
fi

if [[ "$INSTALLED_NATIVE" == "true" ]]; then
    exit 0
fi

# 2. Fallback: Pyenv
echo "🔄 Trying Fallback (Pyenv)..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [ ! -d "$PYENV_ROOT" ]; then
    echo "Installing Pyenv..."
    if curl https://pyenv.run | bash; then
        echo "Pyenv installed"
    else
        echo "Pyenv installation failed"
        exit 1
    fi
fi

eval "$(pyenv init -)" 2>/dev/null || true

LATEST_VERSION=$(pyenv install --list 2>/dev/null | grep -E "^\s*${VERSION//./\.}\.[0-9]+$" | tail -1 | xargs)
if [ -z "$LATEST_VERSION" ]; then
    LATEST_VERSION="$VERSION"
fi

echo "Installing Python $LATEST_VERSION via Pyenv..."
pyenv install "$LATEST_VERSION" --skip-existing
pyenv global "$LATEST_VERSION"
