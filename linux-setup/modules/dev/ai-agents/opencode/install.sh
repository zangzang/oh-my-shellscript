#!/bin/bash
set -e

# Load Library
if ! command -v ui_log_info &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

if ! command -v opencode &> /dev/null; then
    npm_install_g "opencode-agent"
else
    ui_log_info "OpenCode Agent is already installed."
fi