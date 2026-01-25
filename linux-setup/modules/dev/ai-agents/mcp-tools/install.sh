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

ui_log_info "Installing MCP Tools..."

# Install uv (fast python package installer, recommended for MCP)
if ! command -v uv &> /dev/null; then
    ui_log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env 2>/dev/null || true
fi

# Python MCP SDK
pip_install "mcp"

# Node MCP SDK (if relevant/available)
npm_install_g "@modelcontextprotocol/sdk"

ui_log_success "MCP Tools setup complete."
