#!/bin/bash
#
# Linux Setup Assistant - Bootstrap Script
# Prepares launch environment for Go setup
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
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. Check Python3
# 1. Check terminal environment
log_info "Checking terminal environment..."
if [[ -z "$TERM" ]]; then
    export TERM=xterm-256color
    log_warn "Setting TERM: xterm-256color"
fi

# 2. Ensure execution permissions for launchers
log_info "Setting execution permissions for launcher..."
if [[ -f "$ROOT_DIR/omss.sh" ]]; then
    chmod +x "$ROOT_DIR/omss.sh"
fi

# Create symbolic link to ~/.local/bin/omss for global access
if [[ -f "$ROOT_DIR/omss.sh" ]]; then
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"

    rm -f "$BIN_DIR/omss"
    ln -s "$ROOT_DIR/omss.sh" "$BIN_DIR/omss"
    log_info "Global command 'omss' registered at $BIN_DIR/omss"
fi

echo ""
echo "=================================="
log_info "Bootstrap complete!"
log_info "You can now run './omss.sh' here or simply 'omss' from anywhere."
echo ""

# Execute setup assistant directly
cd "$SCRIPT_DIR"
cd .. && exec ./omss.sh "$@"
