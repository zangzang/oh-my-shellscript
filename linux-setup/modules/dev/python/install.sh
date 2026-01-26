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

# Validate version format (should be like 3, 3.12, 3.12.1)
if [[ ! "$VERSION" =~ ^3(\.[0-9]+){0,2}$ ]]; then
    ui_log_error "Invalid Python version format: $VERSION"
    ui_log_info "Valid formats: 3, 3.12, 3.12.1"
    exit 1
fi

# ============================================
# Check if Python is already installed
# ============================================
check_python_installed() {
    local required_ver="$1"
    
    # Extract major.minor from required version
    local req_short
    req_short=$(echo "$required_ver" | grep -oE '^3\.[0-9]+')
    [[ -z "$req_short" ]] && req_short="3"
    
    # Check python3 or python$VERSION
    local py_cmd=""
    if command -v "python$req_short" &>/dev/null; then
        py_cmd="python$req_short"
    elif command -v python3 &>/dev/null; then
        py_cmd="python3"
    else
        return 1
    fi
    
    local installed_ver
    installed_ver=$($py_cmd --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    
    echo "🔍 Detected Python version: $installed_ver (requested: $required_ver)"
    
    if [[ "$installed_ver" == "$req_short" ]]; then
        return 0
    fi
    
    return 1
}

if check_python_installed "$VERSION"; then
    echo "✅ Python $VERSION is already installed."
    python3 --version
    exit 0
fi

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
    ui_log_success "Python $VERSION (Native) installation complete"
    exit 0
fi

# 2. Fallback: Pyenv
ui_log_info "🔄 Trying Fallback (Pyenv)..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [ ! -d "$PYENV_ROOT" ]; then
    ui_log_info "Installing Pyenv..."
    
    # Pyenv requires build dependencies (including gawk for pyenv scripts)
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
        install_packages build-essential libssl-dev zlib1g-dev libbz2-dev \
            libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev \
            xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev gawk
    elif [[ "$OS_ID" == "fedora" ]]; then
        install_packages gcc zlib-devel bzip2 bzip2-devel readline-devel \
            sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel gawk
    fi
    
    if curl https://pyenv.run | bash; then
        ui_log_success "Pyenv installed"
    else
        ui_log_error "Pyenv installation failed"
        exit 1
    fi
fi

# Load pyenv
eval "$(pyenv init -)" 2>/dev/null || true

LATEST_VERSION=$(pyenv install --list 2>/dev/null | grep -E "^\s*${VERSION//./\.}\.[0-9]+$" | tail -1 | xargs)
if [ -z "$LATEST_VERSION" ]; then
    LATEST_VERSION="$VERSION"
fi

ui_log_info "Installing Python $LATEST_VERSION via Pyenv..."
pyenv install "$LATEST_VERSION" --skip-existing
pyenv global "$LATEST_VERSION"

# Final Verification
if command -v python3 &>/dev/null || command -v python &>/dev/null; then
    ui_log_success "Python $LATEST_VERSION (Pyenv) installation complete"
    exit 0
else
    ui_log_error "Python installation failed via both Native and Pyenv."
    exit 1
fi
