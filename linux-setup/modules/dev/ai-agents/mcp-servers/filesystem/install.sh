#!/bin/bash
set -e

# Load Library
if ! command -v ui_log_info &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

ui_log_info "Installing MCP Filesystem Server..."
npm install -g @modelcontextprotocol/server-filesystem || ui_log_warn "Package not available"
ui_log_success "MCP Filesystem Server installation complete"