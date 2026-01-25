#!/bin/bash
#
# Linux Setup Assistant - Bootstrap Script
# Prepares the environment for running Python TUI
#
set -e

echo "🚀 Linux Setup Assistant Bootstrap"
echo "=================================="

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Check Python3
log_info "Checking for Python3..."
if ! command -v python3 &>/dev/null; then
    log_warn "Python3 is not installed. Attempting to install..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y python3 python3-pip
    elif command -v yum &>/dev/null; then
        sudo yum install -y python3 python3-pip
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm python python-pip
    else
        log_error "Could not find a supported package manager. Please install Python3 manually."
        exit 1
    fi
fi

PYTHON_VERSION=$(python3 --version 2>&1)
log_info "Python version: $PYTHON_VERSION"

# 2. Check pip and upgrade
log_info "Checking for pip..."
if ! python3 -m pip --version &>/dev/null; then
    log_warn "pip not found. Installing..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y python3-pip
    else
        curl -sS https://bootstrap.pypa.io/get-pip.py | python3
    fi
fi

# 3. Install textual
log_info "Checking for 'textual' library..."
if ! python3 -c "import textual" 2>/dev/null; then
    log_info "Installing textual..."
    python3 -m pip install --user textual
fi

TEXTUAL_VERSION=$(python3 -c "import textual; print(textual.__version__)" 2>/dev/null || echo "unknown")
log_info "Textual version: $TEXTUAL_VERSION"

# 4. Check terminal environment
log_info "Checking terminal environment..."
if [[ -z "$TERM" ]]; then
    export TERM=xterm-256color
    log_warn "Setting TERM: xterm-256color"
fi

# 5. Verify config directory
if [[ ! -d "$SCRIPT_DIR/config" ]]; then
    log_warn "Config directory missing. Creating default config..."
    mkdir -p "$SCRIPT_DIR/config"
    
    # 기본 categories.json 생성
    cat > "$SCRIPT_DIR/config/categories.json" << 'EOF'
{
  "system": {
    "name": "🔧 System",
    "order": 1,
    "modules": ["update", "build-tools", "essentials", "dev-libs", "cli-tools", "nerd-fonts", "oh-my-posh", "zsh", "shell-config", "ssh-server"]
  },
  "tools": {
    "name": "🛠️ Tools",
    "order": 2,
    "modules": ["fastfetch"]
  },
  "dev": {
    "name": "💻 Development",
    "order": 3,
    "subcategories": {
      "runtime": {
        "name": "Runtime & SDK",
        "modules": ["nvm", "node", "python", "java", "sdkman", "dotnet", "rust"]
      },
      "build": {
        "name": "Build Tools",
        "modules": ["maven", "gradle"]
      },
      "container": {
        "name": "Container & Infra",
        "modules": ["docker", "docker-stack"]
      },
      "mobile": {
        "name": "Mobile & Desktop",
        "modules": ["flutter", "android", "tauri"]
      },
      "ai": {
        "name": "AI & ML",
        "modules": ["cuda", "ollama", "ollama-models", "open-webui"]
      }
    },
    "modules": []
  },
  "gui": {
    "name": "🖥️ GUI Apps",
    "order": 4,
    "modules": ["vscode", "chrome", "dbeaver", "sts", "fcitx5"]
  }
}
EOF
fi

echo ""
echo "=================================="
log_info "Bootstrap complete!"
echo ""

# Execute setup assistant directly
cd "$SCRIPT_DIR"
exec python3 setup.py "$@"
