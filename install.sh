#!/bin/bash
#
# Oh My Shell Script - One-line Installer
# https://github.com/zangzang/oh-my-shellscript
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INSTALL]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

REPO_URL="https://github.com/zangzang/oh-my-shellscript.git"
INSTALL_DIR="$HOME/oh-my-shellscript"
BRANCH="main"

echo "========================================"
echo "   Oh My Shell Script Installer"
echo "========================================"

# 1. Check/Install Git
log_info "Checking for Git..."
if ! command -v git &> /dev/null; then
    log_warn "Git not found. Attempting to install..."
    
    if [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y git
    elif [ -f /etc/redhat-release ]; then
        if command -v dnf &> /dev/null; then
            sudo dnf install -y git
        else
            sudo yum install -y git
        fi
    elif [ -f /etc/arch-release ]; then
        sudo pacman -S --noconfirm git
    elif [ -f /etc/alpine-release ]; then
        sudo apk add git
    else
        log_error "Could not detect package manager. Please install Git manually."
        exit 1
    fi
else
    log_success "Git is already installed."
fi

# 2. Clone or Update Repository
if [ -d "$INSTALL_DIR" ]; then
    log_info "Directory '$INSTALL_DIR' already exists."
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        log_info "Cloning repository..."
        git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    else
        log_info "Updating existing repository..."
        cd "$INSTALL_DIR"
        git pull origin "$BRANCH"
    fi
else
    log_info "Cloning repository to '$INSTALL_DIR'..."
    git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

# 3. Handover to Bootstrap
TARGET_SCRIPT="$INSTALL_DIR/linux-setup/bootstrap.sh"

if [ -f "$TARGET_SCRIPT" ]; then
    log_info "Running bootstrap script..."
    chmod +x "$TARGET_SCRIPT"
    # Pass all arguments to bootstrap
    exec "$TARGET_SCRIPT" "$@"
else
    log_error "Bootstrap script not found at $TARGET_SCRIPT"
    exit 1
fi
